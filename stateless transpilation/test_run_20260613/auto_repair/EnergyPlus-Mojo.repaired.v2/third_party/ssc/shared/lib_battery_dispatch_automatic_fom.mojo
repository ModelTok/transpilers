from lib_battery_dispatch import dispatch_automatic_t, dispatch_t
from lib_battery_powerflow import BatteryPower
from lib_utility_rate import UtilityRate, UtilityRateCalculator
from lib_util import lifetimeIndex
from math import ceil
from builtins import sum, max, min

@value
class dispatch_automatic_front_of_meter_t(dispatch_automatic_t):
    """
     Class takes forecast information about the PV production and Load Profile, plus PPA sell rate and electricity buy-rate signals
     and programs battery to strategically dispatch to maximize economic benefit by:
     1. Discharging during times of high PPA sell rates
     2. Charging from the grid during times of low electricity buy-rates (if grid charging allowed)
     3. Charging from the PV array during times of low PPA sell rates
     4. Charging from the PV array during times where the PV power would be clipped due to inverter limits (if DC-connected)
    """
    def __init__(
        self,
        Battery: battery_t,
        dt_hour: Float64,
        SOC_min: Float64,
        SOC_max: Float64,
        current_choice: Int,
        Ic_max: Float64,
        Id_max: Float64,
        Pc_max_kwdc: Float64,
        Pd_max_kwdc: Float64,
        Pc_max_kwac: Float64,
        Pd_max_kwac: Float64,
        t_min: Float64,
        dispatch_mode: Int,
        pv_dispatch: Int,
        nyears: Int,
        look_ahead_hours: Int,
        dispatch_update_frequency_hours: Float64,
        can_charge: Bool,
        can_clip_charge: Bool,
        can_grid_charge: Bool,
        can_fuelcell_charge: Bool,
        inverter_paco: Float64,
        battReplacementCostPerkWh: List[Float64],
        battCycleCostChoice: Int,
        battCycleCost: List[Float64],
        forecast_price_series_dollar_per_kwh: List[Float64],
        utilityRate: UtilityRate?,
        etaPVCharge: Float64,
        etaGridCharge: Float64,
        etaDischarge: Float64
    ):
        super().__init__(
            Battery, dt_hour, SOC_min, SOC_max, current_choice, Ic_max, Id_max,
            Pc_max_kwdc, Pd_max_kwdc, Pc_max_kwac, Pd_max_kwac,
            t_min, dispatch_mode, pv_dispatch, nyears, look_ahead_hours,
            dispatch_update_frequency_hours, can_charge, can_clip_charge,
            can_grid_charge, can_fuelcell_charge,
            battReplacementCostPerkWh, battCycleCostChoice, battCycleCost
        )
        if _mode == dispatch_t.FOM_LOOK_BEHIND:
            _forecast_hours = 24
        _inverter_paco = inverter_paco
        _forecast_price_rt_series = forecast_price_series_dollar_per_kwh
        if utilityRate:
            tmp = UtilityRateCalculator(utilityRate, _steps_per_hour)
            m_utilityRateCalculator = tmp  # assign directly, not move
        else:
            m_utilityRateCalculator = None
        m_etaPVCharge = etaPVCharge * 0.01
        m_etaGridCharge = etaGridCharge * 0.01
        m_etaDischarge = etaDischarge * 0.01
        revenueToClipCharge = 0.0
        revenueToDischarge = 0.0
        revenueToGridCharge = 0.0
        revenueToPVCharge = 0.0
        costToCycle()
        setup_cost_forecast_vector()

    def __del__(self):

    def init_with_pointer(self, tmp: dispatch_automatic_front_of_meter_t):
        _forecast_hours = tmp._forecast_hours
        _inverter_paco = tmp._inverter_paco
        _forecast_price_rt_series = tmp._forecast_price_rt_series
        m_etaPVCharge = tmp.m_etaPVCharge
        m_etaGridCharge = tmp.m_etaGridCharge
        m_etaDischarge = tmp.m_etaDischarge

    def setup_cost_forecast_vector(self):
        ppa_price_series: List[Float64] = []
        # reserve capacity: not strictly necessary in Mojo
        if _mode == dispatch_t.FOM_LOOK_BEHIND:
            for i in range(_forecast_hours * _steps_per_hour):
                ppa_price_series.append(0.0)
        for i in range(len(_forecast_price_rt_series)):
            ppa_price_series.append(_forecast_price_rt_series[i])
        for i in range(_forecast_hours * _steps_per_hour):
            ppa_price_series.append(_forecast_price_rt_series[i])
        _forecast_price_rt_series = ppa_price_series

    # Deep copy constructor: note Mojo doesn't have copy constructors, so we add a classmethod or use __init__ with dispatch_t
    @staticmethod
    def from_dispatch(dispatch: dispatch_t) -> dispatch_automatic_front_of_meter_t:
        if type(dispatch) is dispatch_automatic_front_of_meter_t:
            tmp = dispatch as dispatch_automatic_front_of_meter_t
            result = dispatch_automatic_front_of_meter_t.__new__(dispatch_automatic_front_of_meter_t)
            dispatch_automatic_t.__init__(result, dispatch)  # base copy
            result.init_with_pointer(tmp)
            return result
        else:
            raise ValueError("Cannot copy from non-FOM dispatch")

    def copy(self, dispatch: dispatch_t):
        dispatch_automatic_t.copy(self, dispatch)
        if type(dispatch) is dispatch_automatic_front_of_meter_t:
            tmp = dispatch as dispatch_automatic_front_of_meter_t
            self.init_with_pointer(tmp)
        else:
            raise ValueError("Cannot copy from non-FOM dispatch")

    def dispatch(self, year: Int, hour_of_year: Int, step: Int):
        curr_year = year
        step_per_hour = Int(1.0 / _dt_hour)
        lifetimeIndex = util.lifetimeIndex(year, hour_of_year, step, step_per_hour)
        update_dispatch(year, hour_of_year, step, lifetimeIndex)
        dispatch_automatic_t.dispatch(self, year, hour_of_year, step)

    def update_dispatch(self, year: Int, hour_of_year: Int, step: Int, lifetimeIndex: Int):
        m_batteryPower.powerBatteryDC = 0.0
        m_batteryPower.powerBatteryAC = 0.0
        m_batteryPower.powerBatteryTarget = 0.0
        if _mode != dispatch_t.FOM_CUSTOM_DISPATCH:
            powerBattery = 0.0
            #! Cost to cycle the battery at all, using maximum DOD or user input
            costToCycle()
            idx_year1 = hour_of_year * _steps_per_hour
            idx_lookahead = _forecast_hours * _steps_per_hour
            # max_element, min_element on slice
            sublist = _forecast_price_rt_series[idx_year1 : idx_year1 + idx_lookahead]
            max_ppa_cost = max(sublist)
            min_ppa_cost = min(sublist)
            ppa_cost = _forecast_price_rt_series[idx_year1]
            #! Cost to purchase electricity from the utility
            usage_cost = ppa_cost
            usage_cost_forecast: List[Float64] = []
            if m_utilityRateCalculator:
                usage_cost = m_utilityRateCalculator.getEnergyRate(hour_of_year)
                for i in range(hour_of_year, hour_of_year + _forecast_hours):
                    for s in range(_steps_per_hour):
                        usage_cost_forecast.append(m_utilityRateCalculator.getEnergyRate(i % 8760))
            energyToStoreClipped = 0.0
            if len(_P_cliploss_dc) > lifetimeIndex + _forecast_hours:
                energyToStoreClipped = sum(_P_cliploss_dc[lifetimeIndex : lifetimeIndex + _forecast_hours * _steps_per_hour]) * _dt_hour
            #! Economic benefit of charging from the grid in current time step to discharge sometime in next X hours ($/kWh)
            revenueToGridCharge = max_ppa_cost * m_etaDischarge - usage_cost / m_etaGridCharge - m_cycleCost
            #! Computed revenue to charge from Grid in each of next X hours ($/kWh)
            revenueToGridChargeMax = 0.0
            if m_batteryPower.canGridCharge:
                revenueToGridChargeForecast: List[Float64] = []
                j = 0
                for i in range(idx_year1, idx_year1 + idx_lookahead):
                    if m_utilityRateCalculator:
                        revenueToGridChargeForecast.append(max_ppa_cost * m_etaDischarge - usage_cost_forecast[j] / m_etaGridCharge - m_cycleCost)
                    else:
                        revenueToGridChargeForecast.append(max_ppa_cost * m_etaDischarge - _forecast_price_rt_series[i] / m_etaGridCharge - m_cycleCost)
                    j += 1
                revenueToGridChargeMax = max(revenueToGridChargeForecast)
            #! Economic benefit of charging from regular PV in current time step to discharge sometime in next X hours ($/kWh)
            revenueToPVCharge = max_ppa_cost * m_etaDischarge - ppa_cost / m_etaPVCharge - m_cycleCost if _P_pv_ac[idx_year1] > 0 else 0.0
            #! Computed revenue to charge from PV in each of next X hours ($/kWh)
            t_duration = Int(ceil(_Battery.energy_nominal() / m_batteryPower.powerBatteryChargeMaxDC))
            pv_hours_on: Int = 0
            revenueToPVChargeMax = 0.0
            if m_batteryPower.canSystemCharge:
                revenueToPVChargeForecast: List[Float64] = []
                for i in range(idx_year1, idx_year1 + idx_lookahead):
                    system_on = 1.0 if _P_pv_ac[i] >= m_batteryPower.powerBatteryChargeMaxDC else 0.0
                    if system_on:
                        revenueToPVChargeForecast.append(system_on * (max_ppa_cost * m_etaDischarge - _forecast_price_rt_series[i] / m_etaPVCharge - m_cycleCost))
                pv_hours_on = len(revenueToPVChargeForecast) // _steps_per_hour
                revenueToPVChargeMax = max(revenueToPVChargeForecast) if pv_hours_on >= t_duration else 0.0
            #! Economic benefit of charging from clipped PV in current time step to discharge sometime in the next X hours (clipped PV is free) ($/kWh)
            revenueToClipCharge = max_ppa_cost * m_etaDischarge - m_cycleCost
            #! Economic benefit of discharging in current time step ($/kWh)
            revenueToDischarge = ppa_cost * m_etaDischarge - m_cycleCost
            #! Energy need to charge the battery (kWh)
            energyNeededToFillBattery = _Battery.energy_to_fill(m_batteryPower.stateOfChargeMax)
            # Booleans to assist decisions
            highDischargeValuePeriod = ppa_cost == max_ppa_cost
            highChargeValuePeriod = ppa_cost == min_ppa_cost
            excessAcCapacity = _inverter_paco > m_batteryPower.powerSystemThroughSharedInverter
            batteryHasDischargeCapacity = _Battery.SOC() >= m_batteryPower.stateOfChargeMin + 1.0
            if m_batteryPower.canClipCharge and m_batteryPower.powerSystemClipped > 0 and revenueToClipCharge > 0:
                powerBattery = -m_batteryPower.powerSystemClipped
            if m_batteryPower.canSystemCharge and revenueToPVCharge > 0 and highChargeValuePeriod and m_batteryPower.powerSystem > 0:
                if m_batteryPower.canClipCharge:
                    if energyToStoreClipped < energyNeededToFillBattery:
                        energyCanCharge = energyNeededToFillBattery - energyToStoreClipped
                        if energyCanCharge <= m_batteryPower.powerSystem * _dt_hour:
                            powerBattery = -max(energyCanCharge / _dt_hour, m_batteryPower.powerSystemClipped)
                        else:
                            powerBattery = -max(m_batteryPower.powerSystem, m_batteryPower.powerSystemClipped)
                        energyNeededToFillBattery = max(0.0, energyNeededToFillBattery + powerBattery * _dt_hour)
                else:
                    powerBattery = -m_batteryPower.powerSystem
            if m_batteryPower.canGridCharge and revenueToGridCharge >= revenueToPVChargeMax and revenueToGridCharge > 0 and highChargeValuePeriod and energyNeededToFillBattery > 0:
                if m_batteryPower.canClipCharge:
                    if energyToStoreClipped < energyNeededToFillBattery:
                        energyCanCharge = energyNeededToFillBattery - energyToStoreClipped
                        powerBattery -= energyCanCharge / _dt_hour
                else:
                    powerBattery = -energyNeededToFillBattery / _dt_hour
            if highDischargeValuePeriod and revenueToDischarge > 0 and excessAcCapacity and batteryHasDischargeCapacity:
                loss_kw = _Battery.calculate_loss(m_batteryPower.powerBatteryTarget, lifetimeIndex)
                if m_batteryPower.connectionMode == BatteryPower.DC_CONNECTED:
                    powerBattery = _inverter_paco + loss_kw - m_batteryPower.powerSystem
                else:
                    powerBattery = _inverter_paco
            m_batteryPower.powerBatteryTarget = powerBattery
        else:
            m_batteryPower.powerBatteryTarget = _P_battery_use[lifetimeIndex % (8760 * _steps_per_hour)]
            loss_kw = _Battery.calculate_loss(m_batteryPower.powerBatteryTarget, lifetimeIndex)
            if m_batteryPower.connectionMode == BatteryPower.AC_CONNECTED:
                m_batteryPower.powerBatteryTarget = m_batteryPower.adjustForACEfficiencies(m_batteryPower.powerBatteryTarget, loss_kw)
            elif m_batteryPower.powerBatteryTarget > 0:
                m_batteryPower.powerBatteryTarget += loss_kw
        m_batteryPower.powerBatteryDC = m_batteryPower.powerBatteryTarget

    def update_pv_data(self, P_pv_ac: List[Float64]):
        _P_pv_ac = P_pv_ac
        for i in range(_forecast_hours * _steps_per_hour):
            _P_pv_ac.append(P_pv_ac[i])

    def costToCycle(self):
        if m_battCycleCostChoice == dispatch_t.MODEL_CYCLE_COST:
            capacityPercentDamagePerCycle = _Battery.estimateCycleDamage()
            m_cycleCost = 0.01 * capacityPercentDamagePerCycle * m_battReplacementCostPerKWH[curr_year]
        elif m_battCycleCostChoice == dispatch_t.INPUT_CYCLE_COST:
            m_cycleCost = cycle_costs_by_year[curr_year]

    # Benefit functions
    def benefit_charge(self) -> Float64:
        return revenueToPVCharge

    def benefit_gridcharge(self) -> Float64:
        return revenueToGridCharge

    def benefit_clipcharge(self) -> Float64:
        return revenueToClipCharge

    def benefit_discharge(self) -> Float64:
        return revenueToDischarge
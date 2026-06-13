# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - state container struct with nested data objects
# DataHeatBalance - zone and heat balance data structures
# DataContaminantBalance - contaminant simulation state
# DataHeatBalFanSys - predictor-corrector control enums
# Psychrometrics - PsyRhoAirFnPbTdbW, PsyCpAirFnW
# ScheduleManager - Sched.GetSchedule, Sched.GetScheduleAlwaysOn
# InputProcessing - getNumObjectsFound, getObjectItem, getObjectDefMaxArgs
# ZoneTempPredictorCorrector - DownInterpolate4HistoryValues
# HeatBalanceInternalHeatGains - SumAllInternalCO2Gains, etc.
# OutputProcessor - SetupOutputVariable, SetupZoneInternalGain
# AirflowNetwork - MultizoneSurfaceData, exchangeData access
# Utilities - FindItemInList, ShowSevereError, etc.

from math import exp, pow, floor, min, max

alias Real64 = Float64

struct PredictorCorrectorCtrl:
    alias GetZoneSetPoints = 0
    alias PredictStep = 1
    alias CorrectStep = 2
    alias RevertZoneTimestepHistories = 3
    alias PushZoneTimestepHistories = 4
    alias PushSystemTimestepHistories = 5


struct SolutionAlgo:
    alias ThirdOrder = 0
    alias AnalyticalSolution = 1
    alias EulerMethod = 2


struct ZoneContaminantPredictorCorrectorData:
    var GetZoneAirContamInputFlag: Bool
    var MyOneTimeFlag: Bool
    var MyEnvrnFlag: Bool
    var MyConfigOneTimeFlag: Bool

    fn __init__(
        inout self,
        get_zone_air_contam_input_flag: Bool = True,
        my_one_time_flag: Bool = True,
        my_envrnflag: Bool = True,
        my_config_one_time_flag: Bool = True,
    ):
        self.GetZoneAirContamInputFlag = get_zone_air_contam_input_flag
        self.MyOneTimeFlag = my_one_time_flag
        self.MyEnvrnFlag = my_envrnflag
        self.MyConfigOneTimeFlag = my_config_one_time_flag


trait EnergyPlusDataTrait:
    fn get_data_zone_contaminant_predictor_corrector(self) -> ZoneContaminantPredictorCorrectorData:
        ...

    fn get_num_of_zones(self) -> Int:
        ...


@export
fn manage_zone_contaminan_updates(
    state: EnergyPlusData,
    update_type: Int,
    shorten_time_step_sys: Bool,
    use_zone_time_step_history: Bool,
    prior_time_step: Real64,
) -> None:
    if state.dataZoneContaminantPredictorCorrector.GetZoneAirContamInputFlag:
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            get_zone_contaminan_inputs(state)
        get_zone_contaminan_set_points(state)
        state.dataZoneContaminantPredictorCorrector.GetZoneAirContamInputFlag = False

    if not state.dataContaminantBalance.Contaminant.SimulateContaminants:
        return

    if update_type == PredictorCorrectorCtrl.GetZoneSetPoints:
        init_zone_cont_set_points(state)
    elif update_type == PredictorCorrectorCtrl.PredictStep:
        predict_zone_contaminants(state, shorten_time_step_sys, use_zone_time_step_history, prior_time_step)
    elif update_type == PredictorCorrectorCtrl.CorrectStep:
        correct_zone_contaminants(state, use_zone_time_step_history)
    elif update_type == PredictorCorrectorCtrl.RevertZoneTimestepHistories:
        revert_zone_timestep_histories(state)
    elif update_type == PredictorCorrectorCtrl.PushZoneTimestepHistories:
        push_zone_timestep_histories(state)
    elif update_type == PredictorCorrectorCtrl.PushSystemTimestepHistories:
        push_system_timestep_histories(state)


@export
fn get_zone_contaminan_inputs(state: EnergyPlusData) -> None:
    pass


@export
fn get_zone_contaminan_set_points(state: EnergyPlusData) -> None:
    pass


@export
fn init_zone_cont_set_points(state: EnergyPlusData) -> None:
    var gc_gain: Real64 = 0.0
    var pi: Real64 = 0.0
    var pj: Real64 = 0.0
    var sch: Real64 = 0.0

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataContaminantBalance.OutdoorCO2 = state.dataContaminantBalance.Contaminant.CO2OutdoorSched.getCurrentVal()

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataContaminantBalance.OutdoorGC = state.dataContaminantBalance.Contaminant.genericOutdoorSched.getCurrentVal()

    if state.dataZoneContaminantPredictorCorrector.MyOneTimeFlag:
        state.dataZoneContaminantPredictorCorrector.MyOneTimeFlag = False

    if state.dataZoneContaminantPredictorCorrector.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        state.dataZoneContaminantPredictorCorrector.MyEnvrnFlag = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataZoneContaminantPredictorCorrector.MyEnvrnFlag = True

    if state.dataZoneEquip.ZoneEquipConfig and state.dataZoneContaminantPredictorCorrector.MyConfigOneTimeFlag:
        state.dataZoneContaminantPredictorCorrector.MyConfigOneTimeFlag = False

    for loop in range(state.dataGlobal.NumOfZones):
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataContaminantBalance.ZoneCO2Gain[loop] = state.internalHeatGains.SumAllInternalCO2Gains(state, loop + 1)
            if state.dataHybridModel.FlagHybridModel_PC:
                state.dataContaminantBalance.ZoneCO2GainExceptPeople[loop] = state.internalHeatGains.SumAllInternalCO2GainsExceptPeople(state, loop + 1)
            state.dataContaminantBalance.ZoneCO2GainFromPeople[loop] = state.internalHeatGains.SumInternalCO2GainsByTypes(state, loop + 1, 1)

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        for i in range(state.dataGlobal.NumOfZones):
            state.dataContaminantBalance.ZoneGCGain[i] = 0.0

        for con in state.dataContaminantBalance.ZoneContamGenericConstant:
            zone_num: Int = con.ActualZoneNum - 1
            gc_gain = (con.GenerateRate * con.generateRateSched.getCurrentVal() -
                      con.RemovalCoef * con.removalCoefSched.getCurrentVal() * state.dataContaminantBalance.ZoneAirGC[zone_num] * 1.0e-6)
            con.GenRate = gc_gain

        if state.afn.simulation_control.type != 0:
            for con in state.dataContaminantBalance.ZoneContamGenericPDriven:
                surf_num: Int = con.SurfNum
                pi = state.afn.AirflowNetworkNodeSimu[state.afn.MultizoneSurfaceData[surf_num].NodeNums[0]].PZ
                pj = state.afn.AirflowNetworkNodeSimu[state.afn.MultizoneSurfaceData[surf_num].NodeNums[1]].PZ
                if pj >= pi:
                    gc_gain = con.GenRateCoef * con.generateRateCoefSched.getCurrentVal() * pow(pj - pi, con.Expo)
                else:
                    gc_gain = 0.0
                con.GenRate = gc_gain

        for con in state.dataContaminantBalance.ZoneContamGenericCutoff:
            zone_num: Int = con.ActualZoneNum - 1
            if state.dataContaminantBalance.ZoneAirGC[zone_num] < con.CutoffValue:
                gc_gain = (con.GenerateRate * con.generateRateSched.getCurrentVal() *
                          (1.0 - state.dataContaminantBalance.ZoneAirGC[zone_num] / con.CutoffValue))
            else:
                gc_gain = 0.0
            con.GenRate = gc_gain

        for con in state.dataContaminantBalance.ZoneContamGenericDecay:
            var sch_val: Real64 = con.emitRateSched.getCurrentVal()
            if sch_val == 0 or state.dataGlobal.BeginEnvrnFlag or state.dataGlobal.WarmupFlag:
                con.Time = 0.0
            else:
                con.Time += state.dataGlobal.TimeStepZoneSec

            gc_gain = con.InitEmitRate * sch_val * exp(-con.Time / con.DelayTime)
            con.GenRate = gc_gain

        for con in state.dataContaminantBalance.ZoneContamGenericBLDiff:
            surf_num: Int = con.SurfNum
            zone_num: Int = state.dataSurface.Surface[surf_num].Zone - 1
            var cs: Real64 = state.dataSurface.SurfGenericContam[surf_num]
            sch = con.transCoefSched.getCurrentVal()
            gc_gain = (con.TransCoef * sch * state.dataSurface.Surface[surf_num].Area * state.dataSurface.Surface[surf_num].Multiplier *
                      (cs / con.HenryCoef - state.dataContaminantBalance.ZoneAirGC[zone_num]) * 1.0e-6)
            con.GenRate = gc_gain
            state.dataSurface.SurfGenericContam[surf_num] = (cs - gc_gain * 1.0e6 /
                                                            state.dataSurface.Surface[surf_num].Multiplier /
                                                            state.dataSurface.Surface[surf_num].Area)

        for con in state.dataContaminantBalance.ZoneContamGenericDVS:
            surf_num: Int = con.SurfNum
            zone_num: Int = state.dataSurface.Surface[surf_num].Zone - 1
            sch = con.depoVeloSched.getCurrentVal()
            gc_gain = (-con.DepoVelo * state.dataSurface.Surface[surf_num].Area * sch *
                      state.dataContaminantBalance.ZoneAirGC[zone_num] *
                      state.dataSurface.Surface[surf_num].Multiplier * 1.0e-6)
            con.GenRate = gc_gain

        for con in state.dataContaminantBalance.ZoneContamGenericDRS:
            zone_num: Int = con.ActualZoneNum - 1
            sch = con.depoRateSched.getCurrentVal()
            gc_gain = (-con.DepoRate * state.dataHeatBal.Zone[zone_num].Volume * sch *
                      state.dataContaminantBalance.ZoneAirGC[zone_num] * 1.0e-6)
            con.GenRate = gc_gain


@export
fn predict_zone_contaminants(
    state: EnergyPlusData,
    shorten_time_step_sys: Bool,
    use_zone_time_step_history: Bool,
    prior_time_step: Real64,
) -> None:
    var routine_name: StringLiteral = "PredictZoneContaminants"
    var time_step_sys_sec: Real64 = state.dataHVACGlobal.TimeStepSysSec

    for zone_num in range(state.dataGlobal.NumOfZones):
        var zone_num_1: Int = zone_num + 1
        var this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num]

        if shorten_time_step_sys:
            if state.dataHeatBal.Zone[zone_num].SystemZoneNodeNumber > 0:
                if state.dataContaminantBalance.Contaminant.CO2Simulation:
                    state.dataLoopNodes.Node[state.dataHeatBal.Zone[zone_num].SystemZoneNodeNumber].CO2 = state.dataContaminantBalance.CO2ZoneTimeMinus1[zone_num]

                if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                    state.dataLoopNodes.Node[state.dataHeatBal.Zone[zone_num].SystemZoneNodeNumber].GenContam = state.dataContaminantBalance.GCZoneTimeMinus1[zone_num]

        if use_zone_time_step_history:
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus3[zone_num]

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                state.dataContaminantBalance.GCZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus3[zone_num]
        else:
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus3[zone_num]

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                state.dataContaminantBalance.GCZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus3[zone_num]

        if state.dataHeatBal.ZoneAirSolutionAlgo != SolutionAlgo.ThirdOrder:
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                if shorten_time_step_sys and state.dataHVACGlobal.TimeStepSys < state.dataGlobal.TimeStepZone:
                    if state.dataHVACGlobal.PreviousTimeStep < state.dataGlobal.TimeStepZone:
                        state.dataContaminantBalance.ZoneCO21[zone_num] = state.dataContaminantBalance.ZoneCO2M2[zone_num]
                    else:
                        state.dataContaminantBalance.ZoneCO21[zone_num] = state.dataContaminantBalance.ZoneCO2MX[zone_num]
                    state.dataHVACGlobal.ShortenTimeStepSysRoomAir = True
                else:
                    state.dataContaminantBalance.ZoneCO21[zone_num] = state.dataContaminantBalance.ZoneAirCO2[zone_num]

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                if shorten_time_step_sys and state.dataHVACGlobal.TimeStepSys < state.dataGlobal.TimeStepZone:
                    if state.dataHVACGlobal.PreviousTimeStep < state.dataGlobal.TimeStepZone:
                        state.dataContaminantBalance.ZoneGC1[zone_num] = state.dataContaminantBalance.ZoneGCM2[zone_num]
                    else:
                        state.dataContaminantBalance.ZoneGC1[zone_num] = state.dataContaminantBalance.ZoneGCMX[zone_num]
                    state.dataHVACGlobal.ShortenTimeStepSysRoomAir = True
                else:
                    state.dataContaminantBalance.ZoneGC1[zone_num] = state.dataContaminantBalance.ZoneAirGC[zone_num]

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataContaminantBalance.CO2PredictedRate[zone_num] = 0.0
            var load_to_co2_set_point: Real64 = 0.0
            state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToCO2SP = 0.0

            var controlled_co2_zone_flag: Bool = False
            var zone_air_co2_set_point: Real64 = 0.0

            for contaminant_controlled_zone in state.dataContaminantBalance.ContaminantControlledZone:
                if contaminant_controlled_zone.ActualZoneNum == zone_num_1:
                    if contaminant_controlled_zone.availSched.getCurrentVal() > 0.0:
                        zone_air_co2_set_point = state.dataContaminantBalance.ZoneCO2SetPoint[zone_num]
                        if contaminant_controlled_zone.EMSOverrideCO2SetPointOn:
                            zone_air_co2_set_point = contaminant_controlled_zone.EMSOverrideCO2SetPointValue
                        controlled_co2_zone_flag = True
                        break

            if not controlled_co2_zone_flag:
                for contaminant_controlled_zone in state.dataContaminantBalance.ContaminantControlledZone:
                    if contaminant_controlled_zone.availSched.getCurrentVal() > 0.0:
                        zone_air_co2_set_point = state.dataContaminantBalance.ZoneCO2SetPoint[contaminant_controlled_zone.ActualZoneNum - 1]
                        if contaminant_controlled_zone.EMSOverrideCO2SetPointOn:
                            zone_air_co2_set_point = contaminant_controlled_zone.EMSOverrideCO2SetPointValue
                        if contaminant_controlled_zone.NumOfZones >= 1:
                            if contaminant_controlled_zone.ActualZoneNum != zone_num_1:
                                for i in range(contaminant_controlled_zone.NumOfZones):
                                    if contaminant_controlled_zone.ControlZoneNum[i] == zone_num_1:
                                        controlled_co2_zone_flag = True
                                        break
                                if controlled_co2_zone_flag:
                                    break
                            else:
                                controlled_co2_zone_flag = True
                                break

            if controlled_co2_zone_flag:
                var rho_air: Real64 = state.psych.PsyRhoAirFnPbTdbW(
                    state,
                    state.dataEnvrn.OutBaroPress,
                    this_zone_hb.ZT,
                    this_zone_hb.airHumRat,
                    routine_name,
                )

                var co2_gain: Real64 = state.dataContaminantBalance.ZoneCO2Gain[zone_num] * rho_air * 1.0e6

                var a: Real64
                var b: Real64
                var c: Real64

                if state.afn.multizone_always_simulated or (
                    state.afn.simulation_control.type == 1 and state.afn.AirflowNetworkFanActivated
                ):
                    b = co2_gain + state.afn.exchangeData[zone_num].SumMHrCO + state.afn.exchangeData[zone_num].SumMMHrCO
                    a = state.afn.exchangeData[zone_num].SumMHr + state.afn.exchangeData[zone_num].SumMMHr
                else:
                    b = (co2_gain +
                         ((this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorCO2) +
                         state.dataContaminantBalance.MixingMassFlowCO2[zone_num] +
                         this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorCO2)
                    a = (this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL +
                         this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA)

                c = rho_air * state.dataHeatBal.Zone[zone_num].Volume * state.dataHeatBal.Zone[zone_num].ZoneVolCapMultpCO2 / time_step_sys_sec

                if state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.ThirdOrder:
                    load_to_co2_set_point = ((11.0 / 6.0) * c + a) * zone_air_co2_set_point - (
                        b + c * (3.0 * state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num] -
                                (3.0 / 2.0) * state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num] +
                                (1.0 / 3.0) * state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num])
                    )
                elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.AnalyticalSolution:
                    if a == 0.0:
                        load_to_co2_set_point = c * (zone_air_co2_set_point - state.dataContaminantBalance.ZoneCO21[zone_num]) - b
                    else:
                        load_to_co2_set_point = (
                            a * (zone_air_co2_set_point - state.dataContaminantBalance.ZoneCO21[zone_num] * exp(min(700.0, -a / c))) /
                            (1.0 - exp(min(700.0, -a / c))) - b
                        )
                elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.EulerMethod:
                    load_to_co2_set_point = c * (zone_air_co2_set_point - state.dataContaminantBalance.ZoneCO21[zone_num]) + a * zone_air_co2_set_point - b

                if zone_air_co2_set_point > state.dataContaminantBalance.OutdoorCO2 and load_to_co2_set_point < 0.0:
                    state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToCO2SP = (
                        load_to_co2_set_point / (state.dataContaminantBalance.OutdoorCO2 - zone_air_co2_set_point)
                    )

            state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToCO2SP *= (
                state.dataHeatBal.Zone[zone_num].Multiplier * state.dataHeatBal.Zone[zone_num].ListMultiplier
            )
            state.dataContaminantBalance.CO2PredictedRate[zone_num] = state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToCO2SP

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            state.dataContaminantBalance.GCPredictedRate[zone_num] = 0.0
            var load_to_gc_set_point: Real64 = 0.0
            state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToGCSP = 0.0

            var controlled_gc_zone_flag: Bool = False
            var zone_air_gc_set_point: Real64 = 0.0

            for contaminant_controlled_zone in state.dataContaminantBalance.ContaminantControlledZone:
                if contaminant_controlled_zone.ActualZoneNum == zone_num_1:
                    if contaminant_controlled_zone.genericContamAvailSched.getCurrentVal() > 0.0:
                        zone_air_gc_set_point = state.dataContaminantBalance.ZoneGCSetPoint[zone_num]
                        if contaminant_controlled_zone.EMSOverrideCO2SetPointOn:
                            zone_air_gc_set_point = contaminant_controlled_zone.EMSOverrideGCSetPointValue
                        controlled_gc_zone_flag = True
                        break

            if not controlled_gc_zone_flag:
                for contaminant_controlled_zone in state.dataContaminantBalance.ContaminantControlledZone:
                    if contaminant_controlled_zone.genericContamAvailSched.getCurrentVal() > 0.0:
                        zone_air_gc_set_point = state.dataContaminantBalance.ZoneGCSetPoint[contaminant_controlled_zone.ActualZoneNum - 1]
                        if contaminant_controlled_zone.EMSOverrideCO2SetPointOn:
                            zone_air_gc_set_point = contaminant_controlled_zone.EMSOverrideGCSetPointValue
                        if contaminant_controlled_zone.NumOfZones >= 1:
                            if contaminant_controlled_zone.ActualZoneNum != zone_num_1:
                                for i in range(contaminant_controlled_zone.NumOfZones):
                                    if contaminant_controlled_zone.ControlZoneNum[i] == zone_num_1:
                                        controlled_gc_zone_flag = True
                                        break
                                if controlled_gc_zone_flag:
                                    break
                            else:
                                controlled_gc_zone_flag = True
                                break

            if controlled_gc_zone_flag:
                var rho_air: Real64 = state.psych.PsyRhoAirFnPbTdbW(
                    state,
                    state.dataEnvrn.OutBaroPress,
                    this_zone_hb.ZT,
                    this_zone_hb.airHumRat,
                    routine_name,
                )

                var gc_gain: Real64 = state.dataContaminantBalance.ZoneGCGain[zone_num] * rho_air * 1.0e6

                var a: Real64
                var b: Real64
                var c: Real64

                if state.afn.multizone_always_simulated or (
                    state.afn.simulation_control.type == 1 and state.afn.AirflowNetworkFanActivated
                ):
                    b = gc_gain + state.afn.exchangeData[zone_num].SumMHrGC + state.afn.exchangeData[zone_num].SumMMHrGC
                    a = state.afn.exchangeData[zone_num].SumMHr + state.afn.exchangeData[zone_num].SumMMHr
                else:
                    b = (gc_gain +
                         ((this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorGC) +
                         state.dataContaminantBalance.MixingMassFlowGC[zone_num] +
                         this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorGC)
                    a = (this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL +
                         this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA)

                c = rho_air * state.dataHeatBal.Zone[zone_num].Volume * state.dataHeatBal.Zone[zone_num].ZoneVolCapMultpGenContam / time_step_sys_sec

                if state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.ThirdOrder:
                    load_to_gc_set_point = ((11.0 / 6.0) * c + a) * zone_air_gc_set_point - (
                        b + c * (3.0 * state.dataContaminantBalance.GCZoneTimeMinus1Temp[zone_num] -
                                (3.0 / 2.0) * state.dataContaminantBalance.GCZoneTimeMinus2Temp[zone_num] +
                                (1.0 / 3.0) * state.dataContaminantBalance.GCZoneTimeMinus3Temp[zone_num])
                    )
                elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.AnalyticalSolution:
                    if a == 0.0:
                        load_to_gc_set_point = c * (zone_air_gc_set_point - state.dataContaminantBalance.ZoneGC1[zone_num]) - b
                    else:
                        load_to_gc_set_point = (
                            a * (zone_air_gc_set_point - state.dataContaminantBalance.ZoneGC1[zone_num] * exp(min(700.0, -a / c))) /
                            (1.0 - exp(min(700.0, -a / c))) - b
                        )
                elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.EulerMethod:
                    load_to_gc_set_point = c * (zone_air_gc_set_point - state.dataContaminantBalance.ZoneGC1[zone_num]) + a * zone_air_gc_set_point - b

                if zone_air_gc_set_point > state.dataContaminantBalance.OutdoorGC and load_to_gc_set_point < 0.0:
                    state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToGCSP = (
                        load_to_gc_set_point / (state.dataContaminantBalance.OutdoorGC - zone_air_gc_set_point)
                    )

            state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToGCSP *= (
                state.dataHeatBal.Zone[zone_num].Multiplier * state.dataHeatBal.Zone[zone_num].ListMultiplier
            )
            state.dataContaminantBalance.GCPredictedRate[zone_num] = state.dataContaminantBalance.ZoneSysContDemand[zone_num].OutputRequiredToGCSP


@export
fn push_zone_timestep_histories(state: EnergyPlusData) -> None:
    for zone_num in range(state.dataGlobal.NumOfZones):
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataContaminantBalance.CO2ZoneTimeMinus4[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus3[zone_num]
            state.dataContaminantBalance.CO2ZoneTimeMinus3[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus2[zone_num]
            state.dataContaminantBalance.CO2ZoneTimeMinus2[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus1[zone_num]
            state.dataContaminantBalance.CO2ZoneTimeMinus1[zone_num] = state.dataContaminantBalance.ZoneAirCO2Avg[zone_num]
            state.dataContaminantBalance.ZoneAirCO2[zone_num] = state.dataContaminantBalance.ZoneAirCO2Temp[zone_num]

            if state.dataHeatBal.ZoneAirSolutionAlgo != SolutionAlgo.ThirdOrder:
                state.dataContaminantBalance.ZoneCO2M2[zone_num] = state.dataContaminantBalance.ZoneCO2MX[zone_num]
                state.dataContaminantBalance.ZoneCO2MX[zone_num] = state.dataContaminantBalance.ZoneAirCO2Avg[zone_num]

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            state.dataContaminantBalance.GCZoneTimeMinus4[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus3[zone_num]
            state.dataContaminantBalance.GCZoneTimeMinus3[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus2[zone_num]
            state.dataContaminantBalance.GCZoneTimeMinus2[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus1[zone_num]
            state.dataContaminantBalance.GCZoneTimeMinus1[zone_num] = state.dataContaminantBalance.ZoneAirGCAvg[zone_num]
            state.dataContaminantBalance.ZoneAirGC[zone_num] = state.dataContaminantBalance.ZoneAirGCTemp[zone_num]

            if state.dataHeatBal.ZoneAirSolutionAlgo != SolutionAlgo.ThirdOrder:
                state.dataContaminantBalance.ZoneGCM2[zone_num] = state.dataContaminantBalance.ZoneGCMX[zone_num]
                state.dataContaminantBalance.ZoneGCMX[zone_num] = state.dataContaminantBalance.ZoneAirGCAvg[zone_num]


@export
fn push_system_timestep_histories(state: EnergyPlusData) -> None:
    for zone_num in range(state.dataGlobal.NumOfZones):
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataContaminantBalance.DSCO2ZoneTimeMinus4[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus3[zone_num]
            state.dataContaminantBalance.DSCO2ZoneTimeMinus3[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus2[zone_num]
            state.dataContaminantBalance.DSCO2ZoneTimeMinus2[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus1[zone_num]
            state.dataContaminantBalance.DSCO2ZoneTimeMinus1[zone_num] = state.dataContaminantBalance.ZoneAirCO2[zone_num]

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            state.dataContaminantBalance.DSGCZoneTimeMinus4[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus3[zone_num]
            state.dataContaminantBalance.DSGCZoneTimeMinus3[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus2[zone_num]
            state.dataContaminantBalance.DSGCZoneTimeMinus2[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus1[zone_num]
            state.dataContaminantBalance.DSGCZoneTimeMinus1[zone_num] = state.dataContaminantBalance.ZoneAirGC[zone_num]

    if state.dataHeatBal.ZoneAirSolutionAlgo != SolutionAlgo.ThirdOrder:
        for zone_num in range(state.dataGlobal.NumOfZones):
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                state.dataContaminantBalance.ZoneCO2M2[zone_num] = state.dataContaminantBalance.ZoneCO2MX[zone_num]
                state.dataContaminantBalance.ZoneCO2MX[zone_num] = state.dataContaminantBalance.ZoneAirCO2Temp[zone_num]

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                state.dataContaminantBalance.ZoneGCM2[zone_num] = state.dataContaminantBalance.ZoneGCMX[zone_num]
                state.dataContaminantBalance.ZoneGCMX[zone_num] = state.dataContaminantBalance.ZoneAirGCTemp[zone_num]


@export
fn revert_zone_timestep_histories(state: EnergyPlusData) -> None:
    for zone_num in range(state.dataGlobal.NumOfZones):
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataContaminantBalance.CO2ZoneTimeMinus1[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus2[zone_num]
            state.dataContaminantBalance.CO2ZoneTimeMinus2[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus3[zone_num]
            state.dataContaminantBalance.CO2ZoneTimeMinus3[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus4[zone_num]

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            state.dataContaminantBalance.GCZoneTimeMinus1[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus2[zone_num]
            state.dataContaminantBalance.GCZoneTimeMinus2[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus3[zone_num]
            state.dataContaminantBalance.GCZoneTimeMinus3[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus4[zone_num]


@export
fn inverse_model_co2(
    state: EnergyPlusData,
    zone_num: Int,
    co2_gain: Real64,
    co2_gain_except_people: Real64,
    zone_mass_flow_rate: Real64,
    co2_mass_flow_rate: Real64,
    rho_air: Real64,
) -> None:
    var routine_name_infiltration: StringLiteral = "CalcAirFlowSimple:Infiltration"

    var aa: Real64 = 0.0
    var bb: Real64 = 0.0
    var m_inf: Real64 = 0.0

    var time_step_sys_sec: Real64 = state.dataHVACGlobal.TimeStepSysSec

    var hm_zone = state.dataHybridModel.hybridModelZones[zone_num - 1]

    state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredCO2Concentration = hm_zone.measuredCO2ConcSched.getCurrentVal()

    if state.dataEnvrn.DayOfYear >= hm_zone.HybridStartDayOfYear and state.dataEnvrn.DayOfYear <= hm_zone.HybridEndDayOfYear:
        state.dataContaminantBalance.ZoneAirCO2[zone_num - 1] = state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredCO2Concentration

        var this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1]

        if hm_zone.InfiltrationCalc_C and state.dataHVACGlobal.UseZoneTimeStepHistory:
            if hm_zone.IncludeSystemSupplyParameters:
                state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirFlowRate = hm_zone.supplyAirMassFlowRateSched.getCurrentVal()
                state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirCO2Concentration = hm_zone.supplyAirCO2ConcSched.getCurrentVal()

                var sum_sys_m_hm: Real64 = state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirFlowRate
                var sum_sys_mx_co2_hm: Real64 = (state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirFlowRate *
                                    state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirCO2Concentration)

                aa = (sum_sys_m_hm + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL +
                     this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA)
                bb = (sum_sys_mx_co2_hm + co2_gain +
                     ((this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorCO2) +
                     state.dataContaminantBalance.MixingMassFlowCO2[zone_num - 1] +
                     this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorCO2)
            else:
                aa = this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL + this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA
                bb = (co2_gain +
                     ((this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorCO2) +
                     state.dataContaminantBalance.MixingMassFlowCO2[zone_num - 1] +
                     this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorCO2)

            var cc: Real64 = rho_air * state.dataHeatBal.Zone[zone_num - 1].Volume * state.dataHeatBal.Zone[zone_num - 1].ZoneVolCapMultpCO2 / time_step_sys_sec
            var dd: Real64 = (3.0 * state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num - 1] -
                 (3.0 / 2.0) * state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num - 1] +
                 (1.0 / 3.0) * state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num - 1])

            var delta_co2: Real64 = (state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredCO2Concentration - state.dataContaminantBalance.OutdoorCO2) / 1000.0
            var cp_air: Real64 = state.psych.PsyCpAirFnW(state.dataEnvrn.OutHumRat)
            var air_density: Real64 = state.psych.PsyRhoAirFnPbTdbW(
                state,
                state.dataEnvrn.OutBaroPress,
                state.dataHeatBal.Zone[zone_num - 1].OutDryBulbTemp,
                state.dataEnvrn.OutHumRat,
                routine_name_infiltration,
            )

            if state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredCO2Concentration == state.dataContaminantBalance.OutdoorCO2:
                m_inf = 0.0
            else:
                m_inf = (cc * dd + bb - ((11.0 / 6.0) * cc + aa) * state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredCO2Concentration) / delta_co2

            var ach_inf: Real64 = max(0.0, min(10.0, m_inf / (cp_air * air_density / 3600.0 * state.dataHeatBal.Zone[zone_num - 1].Volume)))
            m_inf = ach_inf * state.dataHeatBal.Zone[zone_num - 1].Volume * air_density / 3600.0
            state.dataHeatBal.Zone[zone_num - 1].MCPIHM = m_inf
            state.dataHeatBal.Zone[zone_num - 1].InfilOAAirChangeRateHM = ach_inf

        if hm_zone.PeopleCountCalc_C and state.dataHVACGlobal.UseZoneTimeStepHistory:
            state.dataHeatBal.Zone[zone_num - 1].ZonePeopleActivityLevel = (
                hm_zone.peopleActivityLevelSched.getCurrentVal() if hm_zone.peopleActivityLevelSched else 0.0
            )
            var activity_level: Real64 = (
                hm_zone.peopleActivityLevelSched.getCurrentVal() if hm_zone.peopleActivityLevelSched else 0.0
            )
            var co2_gen_rate: Real64 = hm_zone.peopleCO2GenRateSched.getCurrentVal() if hm_zone.peopleCO2GenRateSched else 0.0

            if activity_level <= 0.0:
                activity_level = 130.0
            if co2_gen_rate <= 0.0:
                co2_gen_rate = 0.0000000382

            if hm_zone.IncludeSystemSupplyParameters:
                state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirFlowRate = hm_zone.supplyAirMassFlowRateSched.getCurrentVal()
                state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirCO2Concentration = hm_zone.supplyAirCO2ConcSched.getCurrentVal()

                var sum_sys_m_hm: Real64 = state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirFlowRate
                var sum_sys_mx_co2_hm: Real64 = (state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirFlowRate *
                                    state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredSupplyAirCO2Concentration)

                aa = (sum_sys_m_hm + this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL +
                     this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA)
                bb = (co2_gain_except_people +
                     ((this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorCO2) +
                     sum_sys_mx_co2_hm + state.dataContaminantBalance.MixingMassFlowCO2[zone_num - 1] +
                     this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorCO2)
            else:
                aa = (zone_mass_flow_rate + this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL +
                     this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA)
                bb = (co2_gain_except_people +
                     ((this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorCO2) +
                     co2_mass_flow_rate + state.dataContaminantBalance.MixingMassFlowCO2[zone_num - 1] +
                     this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorCO2)

            var cc: Real64 = rho_air * state.dataHeatBal.Zone[zone_num - 1].Volume * state.dataHeatBal.Zone[zone_num - 1].ZoneVolCapMultpCO2 / time_step_sys_sec
            var dd: Real64 = (3.0 * state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num - 1] -
                 (3.0 / 2.0) * state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num - 1] +
                 (1.0 / 3.0) * state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num - 1])

            var co2_gain_people: Real64 = (((11.0 / 6.0) * cc + aa) * state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredCO2Concentration - bb - cc * dd) / (1000000.0 * rho_air)

            var upper_bound: Real64 = co2_gain / (1000000.0 * rho_air * co2_gen_rate * activity_level)
            var num_people: Real64 = min(upper_bound, co2_gain_people / (co2_gen_rate * activity_level))

            num_people = floor(num_people * 100.0 + 0.5) / 100.0
            if num_people < 0.05:
                num_people = 0
            state.dataHeatBal.Zone[zone_num - 1].NumOccHM = num_people

    state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num - 1] = state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num - 1]
    state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num - 1] = state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num - 1]
    state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num - 1] = state.dataHeatBal.Zone[zone_num - 1].ZoneMeasuredCO2Concentration


@export
fn correct_zone_contaminants(state: EnergyPlusData, use_zone_time_step_history: Bool) -> None:
    var routine_name: StringLiteral = "CorrectZoneContaminants"

    var co2_gain: Real64 = 0.0
    var co2_gain_except_people: Real64 = 0.0
    var gc_gain: Real64 = 0.0
    var a: Real64 = 0.0
    var b: Real64 = 0.0
    var c: Real64 = 0.0

    for zone_num in range(state.dataGlobal.NumOfZones):
        var zone_num_1: Int = zone_num + 1

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataContaminantBalance.AZ[zone_num] = 0.0
            state.dataContaminantBalance.BZ[zone_num] = 0.0
            state.dataContaminantBalance.CZ[zone_num] = 0.0

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            state.dataContaminantBalance.AZGC[zone_num] = 0.0
            state.dataContaminantBalance.BZGC[zone_num] = 0.0
            state.dataContaminantBalance.CZGC[zone_num] = 0.0

        if not use_zone_time_step_history:
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.DSCO2ZoneTimeMinus3[zone_num]

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                state.dataContaminantBalance.GCZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.DSGCZoneTimeMinus3[zone_num]
        else:
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.CO2ZoneTimeMinus3[zone_num]

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                state.dataContaminantBalance.GCZoneTimeMinus1Temp[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus1[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus2Temp[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus2[zone_num]
                state.dataContaminantBalance.GCZoneTimeMinus3Temp[zone_num] = state.dataContaminantBalance.GCZoneTimeMinus3[zone_num]

        var co2_mass_flow_rate: Real64 = 0.0
        var gc_mass_flow_rate: Real64 = 0.0
        var zone_mass_flow_rate: Real64 = 0.0
        var zone_mult: Int = state.dataHeatBal.Zone[zone_num].Multiplier * state.dataHeatBal.Zone[zone_num].ListMultiplier

        var controlled_zone_air_flag: Bool = state.dataHeatBal.Zone[zone_num].IsControlled

        var zone_ret_plenum_air_flag: Bool = False
        var zone_ret_plenum_num: Int = -1
        for zrp_num in range(state.dataZonePlenum.NumZoneReturnPlenums):
            if state.dataZonePlenum.ZoneRetPlenCond[zrp_num].ActualZoneNum == zone_num_1:
                zone_ret_plenum_air_flag = True
                zone_ret_plenum_num = zrp_num
                break

        var zone_sup_plenum_air_flag: Bool = False
        var zone_sup_plenum_num: Int = -1
        for zsp_num in range(state.dataZonePlenum.NumZoneSupplyPlenums):
            if state.dataZonePlenum.ZoneSupPlenCond[zsp_num].ActualZoneNum == zone_num_1:
                zone_sup_plenum_air_flag = True
                zone_sup_plenum_num = zsp_num
                break

        if controlled_zone_air_flag:
            for node_num in range(state.dataZoneEquip.ZoneEquipConfig[zone_num].NumInletNodes):
                var inlet_node_num: Int = state.dataZoneEquip.ZoneEquipConfig[zone_num].InletNode[node_num]
                var node = state.dataLoopNodes.Node[inlet_node_num]

                if state.dataContaminantBalance.Contaminant.CO2Simulation:
                    co2_mass_flow_rate += (node.MassFlowRate * node.CO2) / zone_mult

                if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                    gc_mass_flow_rate += (node.MassFlowRate * node.GenContam) / zone_mult

                zone_mass_flow_rate += node.MassFlowRate / zone_mult

        elif zone_ret_plenum_air_flag:
            for node_num in range(state.dataZonePlenum.ZoneRetPlenCond[zone_ret_plenum_num].NumInletNodes):
                var inlet_node_num: Int = state.dataZonePlenum.ZoneRetPlenCond[zone_ret_plenum_num].InletNode[node_num]
                var node = state.dataLoopNodes.Node[inlet_node_num]

                if state.dataContaminantBalance.Contaminant.CO2Simulation:
                    co2_mass_flow_rate += (node.MassFlowRate * node.CO2) / zone_mult

                if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                    gc_mass_flow_rate += (node.MassFlowRate * node.GenContam) / zone_mult

                zone_mass_flow_rate += node.MassFlowRate / zone_mult

            for adu_list_index in range(state.dataZonePlenum.ZoneRetPlenCond[zone_ret_plenum_num].NumADUs):
                var adu_num: Int = state.dataZonePlenum.ZoneRetPlenCond[zone_ret_plenum_num].ADUIndex[adu_list_index]
                if state.dataDefineEquipment.AirDistUnit[adu_num].UpStreamLeak:
                    var air_dist_unit = state.dataDefineEquipment.AirDistUnit[adu_num]
                    var node = state.dataLoopNodes.Node[air_dist_unit.InletNodeNum]

                    if state.dataContaminantBalance.Contaminant.CO2Simulation:
                        co2_mass_flow_rate += (air_dist_unit.MassFlowRateUpStrLk * node.CO2) / zone_mult

                    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                        gc_mass_flow_rate += (air_dist_unit.MassFlowRateUpStrLk * node.GenContam) / zone_mult

                    zone_mass_flow_rate += air_dist_unit.MassFlowRateUpStrLk / zone_mult

                if state.dataDefineEquipment.AirDistUnit[adu_num].DownStreamLeak:
                    var air_dist_unit = state.dataDefineEquipment.AirDistUnit[adu_num]
                    var node = state.dataLoopNodes.Node[air_dist_unit.OutletNodeNum]

                    if state.dataContaminantBalance.Contaminant.CO2Simulation:
                        co2_mass_flow_rate += (air_dist_unit.MassFlowRateDnStrLk * node.CO2) / zone_mult

                    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                        gc_mass_flow_rate += (air_dist_unit.MassFlowRateDnStrLk * node.GenContam) / zone_mult

                    zone_mass_flow_rate += air_dist_unit.MassFlowRateDnStrLk / zone_mult

        elif zone_sup_plenum_air_flag:
            var inlet_node_num: Int = state.dataZonePlenum.ZoneSupPlenCond[zone_sup_plenum_num].InletNode
            var node = state.dataLoopNodes.Node[inlet_node_num]

            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                co2_mass_flow_rate += (node.MassFlowRate * node.CO2) / zone_mult

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                gc_mass_flow_rate += (node.MassFlowRate * node.GenContam) / zone_mult

            zone_mass_flow_rate += node.MassFlowRate / zone_mult

        if state.dataHeatBal.Zone[zone_num].leakageParallelPIUNums:
            for piu_num in state.dataHeatBal.Zone[zone_num].leakageParallelPIUNums:
                var piu_num_idx: Int = piu_num - 1
                var this_piu = state.dataPowerInductionUnits.PIU[piu_num_idx]
                if this_piu.leakFlow > 0:
                    if state.dataContaminantBalance.Contaminant.CO2Simulation:
                        co2_mass_flow_rate += (this_piu.leakFlow * state.dataLoopNodes.Node[this_piu.PriAirInNode].CO2) / zone_mult

                    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                        gc_mass_flow_rate += (this_piu.leakFlow * state.dataLoopNodes.Node[this_piu.PriAirInNode].GenContam) / zone_mult

                    zone_mass_flow_rate += this_piu.leakFlow / zone_mult

        var time_step_sys_sec: Real64 = state.dataHVACGlobal.TimeStepSysSec
        var this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num]

        var rho_air: Real64 = state.psych.PsyRhoAirFnPbTdbW(
            state,
            state.dataEnvrn.OutBaroPress,
            this_zone_hb.ZT,
            this_zone_hb.airHumRat,
            routine_name,
        )

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataContaminantBalance.ZoneAirDensityCO[zone_num] = rho_air

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            co2_gain = state.dataContaminantBalance.ZoneCO2Gain[zone_num] * rho_air * 1.0e6

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            co2_gain_except_people = state.dataContaminantBalance.ZoneCO2GainExceptPeople[zone_num] * rho_air * 1.0e6

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            gc_gain = state.dataContaminantBalance.ZoneGCGain[zone_num] * rho_air * 1.0e6

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            b = (co2_gain +
                 ((this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorCO2) +
                 co2_mass_flow_rate + state.dataContaminantBalance.MixingMassFlowCO2[zone_num] +
                 this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorCO2)
            a = (zone_mass_flow_rate + this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL +
                 this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA)

            if state.afn.multizone_always_simulated or (
                state.afn.simulation_control.type == 1 and state.afn.AirflowNetworkFanActivated
            ):
                b = co2_gain + (state.afn.exchangeData[zone_num].SumMHrCO + state.afn.exchangeData[zone_num].SumMMHrCO) + co2_mass_flow_rate
                a = zone_mass_flow_rate + state.afn.exchangeData[zone_num].SumMHr + state.afn.exchangeData[zone_num].SumMMHr

            c = rho_air * state.dataHeatBal.Zone[zone_num].Volume * state.dataHeatBal.Zone[zone_num].ZoneVolCapMultpCO2 / time_step_sys_sec

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            var zone_air_co2_temp: Real64 = state.dataContaminantBalance.ZoneAirCO2Temp[zone_num]

            if state.afn.distribution_simulated:
                b += state.afn.exchangeData[zone_num].TotalCO2

            state.dataContaminantBalance.AZ[zone_num] = a
            state.dataContaminantBalance.BZ[zone_num] = b
            state.dataContaminantBalance.CZ[zone_num] = c

            if state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.ThirdOrder:
                zone_air_co2_temp = (
                    (b + c * (3.0 * state.dataContaminantBalance.CO2ZoneTimeMinus1Temp[zone_num] -
                             (3.0 / 2.0) * state.dataContaminantBalance.CO2ZoneTimeMinus2Temp[zone_num] +
                             (1.0 / 3.0) * state.dataContaminantBalance.CO2ZoneTimeMinus3Temp[zone_num])) /
                    ((11.0 / 6.0) * c + a)
                )
            elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.AnalyticalSolution:
                if a == 0.0:
                    zone_air_co2_temp = state.dataContaminantBalance.ZoneCO21[zone_num] + b / c
                else:
                    zone_air_co2_temp = ((state.dataContaminantBalance.ZoneCO21[zone_num] - b / a) *
                                        exp(min(700.0, -a / c)) + b / a)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.EulerMethod:
                zone_air_co2_temp = (c * state.dataContaminantBalance.ZoneCO21[zone_num] + b) / (c + a)

            if zone_air_co2_temp < 0.0:
                zone_air_co2_temp = 0.0

            state.dataContaminantBalance.ZoneAirCO2Temp[zone_num] = zone_air_co2_temp
            state.dataContaminantBalance.ZoneAirCO2[zone_num] = zone_air_co2_temp

            if state.dataHybridModel.FlagHybridModel:
                var hm_zone = state.dataHybridModel.hybridModelZones[zone_num]
                if ((hm_zone.InfiltrationCalc_C or hm_zone.PeopleCountCalc_C) and
                    (not state.dataGlobal.WarmupFlag) and (not state.dataGlobal.DoingSizing)):
                    inverse_model_co2(state, zone_num_1, co2_gain, co2_gain_except_people, zone_mass_flow_rate, co2_mass_flow_rate, rho_air)

            var zone_node_num: Int = state.dataHeatBal.Zone[zone_num].SystemZoneNodeNumber
            if zone_node_num > 0:
                state.dataLoopNodes.Node[zone_node_num - 1].CO2 = zone_air_co2_temp

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            b = (gc_gain +
                 ((this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL) * state.dataContaminantBalance.OutdoorGC) +
                 gc_mass_flow_rate + state.dataContaminantBalance.MixingMassFlowGC[zone_num] +
                 this_zone_hb.MDotOA * state.dataContaminantBalance.OutdoorGC)
            a = (zone_mass_flow_rate + this_zone_hb.OAMFL + this_zone_hb.VAMFL + this_zone_hb.EAMFL + this_zone_hb.CTMFL +
                 this_zone_hb.MixingMassFlowZone + this_zone_hb.MDotOA)

            if state.afn.multizone_always_simulated or (
                state.afn.simulation_control.type == 1 and state.afn.AirflowNetworkFanActivated
            ):
                b = gc_gain + (state.afn.exchangeData[zone_num].SumMHrGC + state.afn.exchangeData[zone_num].SumMMHrGC) + gc_mass_flow_rate
                a = zone_mass_flow_rate + state.afn.exchangeData[zone_num].SumMHr + state.afn.exchangeData[zone_num].SumMMHr

            c = rho_air * state.dataHeatBal.Zone[zone_num].Volume * state.dataHeatBal.Zone[zone_num].ZoneVolCapMultpGenContam / time_step_sys_sec

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            var zone_air_gc_temp: Real64 = state.dataContaminantBalance.ZoneAirGCTemp[zone_num]

            if state.afn.distribution_simulated:
                b += state.afn.exchangeData[zone_num].TotalGC

            state.dataContaminantBalance.AZGC[zone_num] = a
            state.dataContaminantBalance.BZGC[zone_num] = b
            state.dataContaminantBalance.CZGC[zone_num] = c

            if state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.ThirdOrder:
                zone_air_gc_temp = (
                    (b + c * (3.0 * state.dataContaminantBalance.GCZoneTimeMinus1Temp[zone_num] -
                             (3.0 / 2.0) * state.dataContaminantBalance.GCZoneTimeMinus2Temp[zone_num] +
                             (1.0 / 3.0) * state.dataContaminantBalance.GCZoneTimeMinus3Temp[zone_num])) /
                    ((11.0 / 6.0) * c + a)
                )
            elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.AnalyticalSolution:
                if a == 0.0:
                    zone_air_gc_temp = state.dataContaminantBalance.ZoneGC1[zone_num] + b / c
                else:
                    zone_air_gc_temp = ((state.dataContaminantBalance.ZoneGC1[zone_num] - b / a) *
                                       exp(min(700.0, -a / c)) + b / a)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo.EulerMethod:
                zone_air_gc_temp = (c * state.dataContaminantBalance.ZoneGC1[zone_num] + b) / (c + a)

            if zone_air_gc_temp < 0.0:
                zone_air_gc_temp = 0.0

            state.dataContaminantBalance.ZoneAirGCTemp[zone_num] = zone_air_gc_temp
            state.dataContaminantBalance.ZoneAirGC[zone_num] = zone_air_gc_temp

            var zone_node_num: Int = state.dataHeatBal.Zone[zone_num].SystemZoneNodeNumber
            if zone_node_num > 0:
                state.dataLoopNodes.Node[zone_node_num - 1].GenContam = zone_air_gc_temp

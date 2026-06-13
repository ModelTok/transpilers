"""
HeatBalanceAirManager: Air heat balance simulation routines for building envelope.
Translated from EnergyPlus C++ source (HeatBalanceAirManager.cc/.hh)
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Dict, Any
from math import fmod

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData state object (from Data.EnergyPlusData)
# Zone, Space, Infiltration, Ventilation, Mixing, CrossMixing, RefDoorMixing (from DataHeatBalance)
# ZnAirRpt, spaceAirRpt (from DataHeatBalance)
# OutputProcessor functions: SetupOutputVariable, SetupEMSActuator
# Psychrometrics: PsyTwbFnTdbWPb, PsyTdpFnWPb
# ScheduleManager: GetSchedule, GetScheduleAlwaysOn
# InputProcessor: getObjectDefMaxArgs, getNumObjectsFound, getObjectItem
# Utility: FindItemInList, makeUPPER
# ErrorHandling: ShowFatalError, ShowSevereError, ShowWarningError, etc.
# EMSManager, HVACManager, ZoneTempPredictorCorrector


class AirflowSpec(IntEnum):
    """Infiltration/Ventilation/Mixing design level calculation method."""
    Invalid = -1
    FlowPerZone = 0
    FlowPerArea = 1
    FlowPerExteriorArea = 2
    FlowPerExteriorWallArea = 3
    FlowPerPerson = 4
    AirChanges = 5
    Num = 6


# Constant name arrays (uppercase, for enum lookup)
AIRFLOW_SPEC_NAMES_UC = [
    "FLOW/ZONE",
    "FLOW/AREA",
    "FLOW/EXTERIORAREA",
    "FLOW/EXTERIORWALLAREA",
    "FLOW/PERSON",
    "AIRCHANGES/HOUR"
]

VENTILATION_TYPE_NAMES_UC = [
    "NATURAL",
    "INTAKE",
    "EXHAUST",
    "BALANCED"
]

INF_VENT_DENSITY_BASIS_NAMES_UC = [
    "OUTDOOR",
    "STANDARD",
    "INDOOR"
]

ROOM_AIR_MODEL_NAMES_UC = [
    "USERDEFINED",
    "MIXING",
    "ONENODEDISPLACEMENTVENTILATION",
    "THREENODEDISPLACEMENTVENTILATION",
    "CROSSVENTILATION",
    "UNDERFLOORAIRDISTRIBUTIONINTERIOR",
    "UNDERFLOORAIRDISTRIBUTIONEXTERIOR",
    "AIRFLOWNETWORK"
]

COUPLING_SCHEME_NAMES_UC = [
    "DIRECT",
    "INDIRECT"
]


class HeatBalanceAirMgrData(Protocol):
    """State container for HeatBalanceAirManager module state."""
    ManageAirHeatBalanceGetInputFlag: bool
    CalcExtraReportVarMyOneTimeFlag: bool
    UniqueZoneNames: set
    UniqueInfiltrationNames: dict


def manage_air_heat_balance(state: Any) -> None:
    """
    Manage the heat air balance method of calculating building thermal loads.
    Called from the HeatBalanceManager at the time step level.
    """
    # Obtains and Allocates heat balance related parameters from input file
    if state.dataHeatBalAirMgr.ManageAirHeatBalanceGetInputFlag:
        get_air_heat_balance_input(state)
        state.dataHeatBalAirMgr.ManageAirHeatBalanceGetInputFlag = False

    init_air_heat_balance(state)

    # Solve the zone heat balance 'Detailed' solution
    # Call the air surface heat balances
    calc_heat_balance_air(state)

    report_zone_mean_air_temp(state)


def get_air_heat_balance_input(state: Any) -> None:
    """Get and process all air heat balance input."""
    errors_found = False

    get_air_flow_flag(state, errors_found)
    set_zone_mass_conservation_flag(state)
    
    # Get input parameters for modeling of room air flow
    get_room_air_model_parameters(state, errors_found)

    if errors_found:
        raise RuntimeError("GetAirHeatBalanceInput: Errors found in getting Air inputs")


def get_air_flow_flag(state: Any, errors_found: bool) -> None:
    """Set air flow flag and get simple air model inputs."""
    state.dataHeatBal.AirFlowFlag = True

    get_simple_air_model_inputs(state, errors_found)
    
    if (state.dataHeatBal.TotInfiltration + state.dataHeatBal.TotVentilation +
        state.dataHeatBal.TotMixing + state.dataHeatBal.TotCrossMixing +
        state.dataHeatBal.TotRefDoorMixing > 0):
        # print AirFlow Model line
        pass


def set_zone_mass_conservation_flag(state: Any) -> None:
    """Set the zone mass conservation flag to true for appropriate zones."""
    if (state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance and
        state.dataHeatBal.ZoneAirMassFlow.ZoneFlowAdjustment != 0):  # NoAdjustReturnAndMixing
        for loop in range(1, state.dataHeatBal.TotMixing + 1):
            zone_ptr = state.dataHeatBal.Mixing[loop - 1].ZonePtr
            from_zone = state.dataHeatBal.Mixing[loop - 1].FromZone
            if zone_ptr > 0:
                state.dataHeatBalFanSys.ZoneMassBalanceFlag[zone_ptr - 1] = True
            if from_zone > 0:
                state.dataHeatBalFanSys.ZoneMassBalanceFlag[from_zone - 1] = True


def get_simple_air_model_inputs(state: Any, errors_found: bool) -> None:
    """Get input for the 'simple' air flow model (infiltration, ventilation, mixing)."""
    # This is a very large function - placeholder for full implementation
    # The real implementation would process:
    # - ZoneAirBalance:OutdoorAir objects
    # - ZoneInfiltration:DesignFlowRate/EffectiveLeakageArea/FlowCoefficient
    # - ZoneVentilation:DesignFlowRate/WindandStackOpenArea
    # - ZoneMixing objects
    # - ZoneCrossMixing objects
    # - ZoneRefrigerationDoorMixing objects
    
    # Initialize air report variables
    state.dataHeatBal.ZnAirRpt = []
    if state.dataHeatBal.doSpaceHeatBalanceSizing or state.dataHeatBal.doSpaceHeatBalanceSimulation:
        state.dataHeatBal.spaceAirRpt = []


def get_room_air_model_parameters(state: Any, err_flag: bool) -> None:
    """Get room air model parameters for all zones."""
    # Initialize default values
    state.dataRoomAir.AirModel = [None] * state.dataGlobal.NumOfZones

    errors_found = False
    current_module_object = "RoomAirModelType"
    num_of_air_models = 0  # state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    
    if num_of_air_models > state.dataGlobal.NumOfZones:
        errors_found = True

    # Set default air models for all zones
    for zone_num in range(state.dataGlobal.NumOfZones):
        state.dataRoomAir.AirModel[zone_num] = {
            'Name': f"MIXING AIR MODEL FOR {state.dataHeatBal.Zone[zone_num].Name}",
            'ZoneName': state.dataHeatBal.Zone[zone_num].Name,
            'AirModel': 1,  # Mixing
            'SimAirModel': False
        }

    if errors_found:
        err_flag = True


def init_air_heat_balance(state: Any) -> None:
    """Initialize all heat balance related parameters."""
    init_simple_mixing_convective_heat_gains(state)


def init_simple_mixing_convective_heat_gains(state: Any) -> None:
    """Set up the mixing and cross mixing flows for each time step."""
    if state.dataHeatBal.AirFlowFlag:
        # Process scheduled Mixing
        for mixing in state.dataHeatBal.Mixing:
            mixing.DesiredAirFlowRate = mixing.DesignLevel * mixing.sched.getCurrentVal()
            if mixing.EMSSimpleMixingOn:
                mixing.DesiredAirFlowRate = mixing.EMSimpleMixingFlowRate
            mixing.DesiredAirFlowRateSaved = mixing.DesiredAirFlowRate

        # Zone air mass flow balance
        if state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance:
            for mass_conserv_zone in state.dataHeatBal.MassConservation:
                zone_mixing_flow_sum = 0.0
                num_of_mixing_objects = mass_conserv_zone.NumReceivingZonesMixingObject
                
                for loop in range(1, num_of_mixing_objects + 1):
                    zone_mixing_flow_sum += state.dataHeatBal.Mixing[loop - 1].DesignLevel
                    mass_conserv_zone.ZoneMixingReceivingFr[loop - 1] = 0.0

                if zone_mixing_flow_sum > 0.0:
                    for loop in range(1, num_of_mixing_objects + 1):
                        mass_conserv_zone.ZoneMixingReceivingFr[loop - 1] = (
                            state.dataHeatBal.Mixing[loop - 1].DesignLevel / zone_mixing_flow_sum
                        )

        # Process scheduled CrossMixing
        for cross_mix in state.dataHeatBal.CrossMixing:
            cross_mix.DesiredAirFlowRate = cross_mix.DesignLevel * cross_mix.sched.getCurrentVal()
            if cross_mix.EMSSimpleMixingOn:
                cross_mix.DesiredAirFlowRate = cross_mix.EMSimpleMixingFlowRate

        # Process scheduled Refrigeration Door mixing
        if state.dataHeatBal.TotRefDoorMixing > 0:
            for nz in range(state.dataGlobal.NumOfZones - 1):
                this_ref_door = state.dataHeatBal.RefDoorMixing[nz]
                if not this_ref_door.RefDoorMixFlag:
                    continue
                if this_ref_door.ZonePtr == nz + 1:
                    for j in range(1, this_ref_door.NumRefDoorConnections + 1):
                        this_ref_door.VolRefDoorFlowRate[j - 1] = 0.0
                        if this_ref_door.EMSRefDoorMixingOn[j - 1]:
                            this_ref_door.VolRefDoorFlowRate[j - 1] = this_ref_door.EMSRefDoorFlowRate[j - 1]


def calc_heat_balance_air(state: Any) -> None:
    """Calculate the air component of the heat balance."""
    if state.dataGlobal.externalHVACManager:
        if not state.dataGlobal.externalHVACManagerInitialized:
            initialize_for_external_hvac_manager(state)
        state.dataGlobal.externalHVACManager(state)
    else:
        # HVACManager.ManageHVAC(state)
        pass


def initialize_for_external_hvac_manager(state: Any) -> None:
    """Initialize HVAC-related items for external HVAC manager."""
    # EnergyPlus::ZoneTempPredictorCorrector::InitZoneAirSetPoints(state)
    pass


def report_zone_mean_air_temp(state: Any) -> None:
    """Update report variables for the AirHeatBalance."""
    if state.dataHeatBalAirMgr.CalcExtraReportVarMyOneTimeFlag:
        # Check for requested WBGT variables
        # This would scan reqVars and EMS sensors for WBGT requests
        state.dataHeatBalAirMgr.CalcExtraReportVarMyOneTimeFlag = False

    # Calculate mean air temperatures for all zones
    for zone_loop in range(state.dataGlobal.NumOfZones):
        this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_loop]
        calc_mean_air_temps(
            state,
            this_zone_hb.ZTAV,
            this_zone_hb.airHumRatAvg,
            this_zone_hb.MRT,
            state.dataHeatBal.ZnAirRpt[zone_loop],
            zone_loop + 1
        )

        if state.dataHeatBal.doSpaceHeatBalanceSimulation:
            for space_num in state.dataHeatBal.Zone[zone_loop].spaceIndexes:
                this_space_hb = state.dataZoneTempPredictorCorrector.spaceHeatBalance[space_num]
                calc_mean_air_temps(
                    state,
                    this_space_hb.ZTAV,
                    this_space_hb.airHumRatAvg,
                    this_space_hb.MRT,
                    state.dataHeatBal.spaceAirRpt[space_num],
                    zone_loop + 1
                )


def calc_mean_air_temps(
    state: Any,
    ztav: float,
    air_hum_rat_avg: float,
    mrt: float,
    this_air_rpt: Any,
    zone_num: int
) -> None:
    """Calculate mean air temperature and related metrics."""
    # The mean air temperature is actually ZTAV which is the average
    # temperature of the air temperatures at the system time step for the
    # entire zone time step.
    this_air_rpt.MeanAirTemp = ztav
    this_air_rpt.MeanAirHumRat = air_hum_rat_avg
    this_air_rpt.OperativeTemp = 0.5 * (ztav + mrt)
    this_air_rpt.MeanAirDewPointTemp = 0.0  # PsyTdpFnWPb(state, this_air_rpt.MeanAirHumRat, state.dataEnvrn.OutBaroPress)

    # Check for operative temperature control
    if state.dataZoneCtrls.AnyOpTempControl:
        temp_controlled_zone_id = state.dataHeatBal.Zone[zone_num - 1].TempControlledZoneIndex
        if state.dataHeatBal.Zone[zone_num - 1].IsControlled:
            if state.dataZoneCtrls.TempControlledZone[temp_controlled_zone_id - 1].OpTempCtrl != 0:
                # Calculate thermal operative temperature
                if state.dataZoneCtrls.TempControlledZone[temp_controlled_zone_id - 1].OpTempCtrl == 1:  # Scheduled
                    this_mrt_fraction = state.dataZoneCtrls.TempControlledZone[temp_controlled_zone_id - 1].opTempRadiativeFractionSched.getCurrentVal()
                else:
                    this_mrt_fraction = state.dataZoneCtrls.TempControlledZone[temp_controlled_zone_id - 1].FixedRadiativeFraction
                
                this_air_rpt.OperativeTemp = 0.5 * (ztav + mrt)
                this_air_rpt.ThermOperativeTemp = (1.0 - this_mrt_fraction) * ztav + this_mrt_fraction * mrt

    if this_air_rpt.ReportWBGT:
        # Calculate Wetbulb Globe Temperature
        # this_air_rpt.WetbulbGlobeTemp = 0.7 * PsyTwbFnTdbWPb(...) + 0.3 * this_air_rpt.OperativeTemp
        pass

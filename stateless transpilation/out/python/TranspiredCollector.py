from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Tuple
import math

# Constants
LAYOUT_SQUARE = 1
LAYOUT_TRIANGLE = 2
CORRELATION_KUTSCHER_1994 = 1
CORRELATION_VAN_DECKER_HOLLANDS_BRUNGER_2001 = 2

# Physical constants
STEFAN_BOLTZMANN = 5.6697e-08
KINEMATIC_VISCOSITY = 15.66e-6
THERMAL_CONDUCTIVITY = 0.0267
GRAVITATIONAL_CONSTANT = 9.807
PRANDTL_NUMBER = 0.71

# Time constants
SECS_IN_HOUR = 3600.0


@dataclass
class Vector:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0


@dataclass
class UTSCDataStruct:
    Name: str = ""
    OSCMName: str = ""
    OSCMPtr: int = 0
    availSched: Optional[object] = None
    InletNode: List[int] = field(default_factory=list)
    OutletNode: List[int] = field(default_factory=list)
    ControlNode: List[int] = field(default_factory=list)
    ZoneNode: List[int] = field(default_factory=list)
    Layout: int = 0
    Correlation: int = 0
    HoleDia: float = 0.0
    Pitch: float = 0.0
    LWEmitt: float = 0.0
    SolAbsorp: float = 0.0
    CollRoughness: int = 0
    PlenGapThick: float = 0.0
    PlenCrossArea: float = 0.0
    NumSurfs: int = 0
    SurfPtrs: List[int] = field(default_factory=list)
    Height: float = 0.0
    AreaRatio: float = 0.0
    CollectThick: float = 0.0
    Cv: float = 0.0
    Cd: float = 0.0
    NumOASysAttached: int = 0
    freeHeatSetPointSched: Optional[object] = None
    VsucErrIndex: int = 0
    ActualArea: float = 0.0
    ProjArea: float = 0.0
    Centroid: Vector = field(default_factory=lambda: Vector(0.0, 0.0, 0.0))
    Porosity: float = 0.0
    IsOn: bool = False
    Tplen: float = 0.0
    Tcoll: float = 0.0
    TplenLast: float = 22.5
    TcollLast: float = 22.0
    HrPlen: float = 0.0
    HcPlen: float = 0.0
    MdotVent: float = 0.0
    HdeltaNPL: float = 0.0
    TairHX: float = 0.0
    InletMDot: float = 0.0
    InletTempDB: float = 0.0
    Tilt: float = 0.0
    Azimuth: float = 0.0
    QdotSource: float = 0.0
    Isc: float = 0.0
    HXeff: float = 0.0
    Vsuction: float = 0.0
    PassiveACH: float = 0.0
    PassiveMdotVent: float = 0.0
    PassiveMdotWind: float = 0.0
    PassiveMdotTherm: float = 0.0
    PlenumVelocity: float = 0.0
    SupOutTemp: float = 0.0
    SupOutHumRat: float = 0.0
    SupOutEnth: float = 0.0
    SupOutMassFlow: float = 0.0
    SensHeatingRate: float = 0.0
    SensHeatingEnergy: float = 0.0
    SensCoolingRate: float = 0.0
    SensCoolingEnergy: float = 0.0
    UTSCEfficiency: float = 0.0
    UTSCCollEff: float = 0.0


def sim_transpired_collector(state, comp_name: str, comp_index: int) -> int:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False

    utsc_num = comp_index
    if comp_index == 0:
        utsc_num = find_item_in_list(comp_name, state.dataTranspiredCollector.UTSC)
        if utsc_num == 0:
            show_fatal_error(state, f"Transpired Collector not found={comp_name}")
        comp_index = utsc_num
    else:
        utsc_num = comp_index
        if utsc_num > state.dataTranspiredCollector.NumUTSC or utsc_num < 1:
            show_fatal_error(
                state,
                f"SimTranspiredCollector: Invalid CompIndex passed={utsc_num}, "
                f"Number of Transpired Collectors={state.dataTranspiredCollector.NumUTSC}, "
                f"UTSC name={comp_name}"
            )
        if state.dataTranspiredCollector.CheckEquipName[utsc_num - 1]:
            if comp_name != state.dataTranspiredCollector.UTSC[utsc_num - 1].Name:
                show_fatal_error(
                    state,
                    f"SimTranspiredCollector: Invalid CompIndex passed={utsc_num}, "
                    f"Transpired Collector name={comp_name}, "
                    f"stored Transpired Collector Name for that index="
                    f"{state.dataTranspiredCollector.UTSC[utsc_num - 1].Name}"
                )
            state.dataTranspiredCollector.CheckEquipName[utsc_num - 1] = False

    init_transpired_collector(state, comp_index)

    utsc_ci = state.dataTranspiredCollector.UTSC[comp_index - 1]
    utsc_ci.IsOn = False
    
    if (utsc_ci.availSched.get_current_val() > 0.0) and (utsc_ci.InletMDot > 0.0):
        control_lt_set = False
        control_lt_schedule = False
        zone_lt_schedule = False
        
        for i in range(len(utsc_ci.InletNode)):
            inlet_node_i = utsc_ci.InletNode[i]
            control_node_i = utsc_ci.ControlNode[i]
            zone_node_i = utsc_ci.ZoneNode[i]
            
            if (state.dataLoopNodes.Node[inlet_node_i].Temp + state.HVAC.TempControlTol < 
                state.dataLoopNodes.Node[control_node_i].TempSetPoint):
                control_lt_set = True
            
            if (state.dataLoopNodes.Node[inlet_node_i].Temp + state.HVAC.TempControlTol < 
                utsc_ci.freeHeatSetPointSched.get_current_val()):
                control_lt_schedule = True
            
            if (state.dataLoopNodes.Node[zone_node_i].Temp + state.HVAC.TempControlTol < 
                utsc_ci.freeHeatSetPointSched.get_current_val()):
                zone_lt_schedule = True
        
        if control_lt_set or (control_lt_schedule and zone_lt_schedule):
            utsc_ci.IsOn = True

    if state.dataTranspiredCollector.UTSC[utsc_num - 1].IsOn:
        calc_active_transpired_collector(state, utsc_num)
    else:
        calc_passive_transpired_collector(state, utsc_num)

    update_transpired_collector(state, utsc_num)
    
    return comp_index


def get_transpired_collector_input(state):
    routine_name = "GetTranspiredCollectorInput"
    
    state.dataTranspiredCollector.NumUTSC = state.dataInputProcessing.inputProcessor.get_num_objects_found(
        state, "SolarCollector:UnglazedTranspired"
    )
    
    state.dataTranspiredCollector.UTSC = [
        UTSCDataStruct() for _ in range(state.dataTranspiredCollector.NumUTSC)
    ]
    state.dataTranspiredCollector.CheckEquipName = [True] * state.dataTranspiredCollector.NumUTSC
    
    for item in range(state.dataTranspiredCollector.NumUTSC):
        alphas, numbers = state.dataInputProcessing.inputProcessor.get_object_item(
            state, "SolarCollector:UnglazedTranspired", item + 1
        )
        
        state.dataTranspiredCollector.UTSC[item].Name = alphas[0]
        state.dataTranspiredCollector.UTSC[item].OSCMName = alphas[1]
        
        found = find_item_in_list(
            state.dataTranspiredCollector.UTSC[item].OSCMName,
            state.dataSurface.OSCM
        )
        if found == 0:
            show_severe_error(state, f"OSCM not found={state.dataTranspiredCollector.UTSC[item].OSCMName}")
        state.dataTranspiredCollector.UTSC[item].OSCMPtr = found
        
        if alphas[2] == "":
            state.dataTranspiredCollector.UTSC[item].availSched = get_schedule_always_on(state)
        else:
            state.dataTranspiredCollector.UTSC[item].availSched = get_schedule(state, alphas[2])
        
        if state.dataTranspiredCollector.UTSC[item].NumOASysAttached == 0:
            state.dataTranspiredCollector.UTSC[item].NumOASysAttached = 1
            state.dataTranspiredCollector.UTSC[item].InletNode = [0]
            state.dataTranspiredCollector.UTSC[item].OutletNode = [0]
            state.dataTranspiredCollector.UTSC[item].ControlNode = [0]
            state.dataTranspiredCollector.UTSC[item].ZoneNode = [0]
        
        if alphas[8] == "":
            show_severe_error(state, "Free heat setpoint schedule is blank")
        state.dataTranspiredCollector.UTSC[item].freeHeatSetPointSched = get_schedule(state, alphas[8])
        
        if alphas[8].lower() == "triangle":
            state.dataTranspiredCollector.UTSC[item].Layout = LAYOUT_TRIANGLE
        elif alphas[8].lower() == "square":
            state.dataTranspiredCollector.UTSC[item].Layout = LAYOUT_SQUARE
        
        if alphas[9].lower() == "kutscher1994":
            state.dataTranspiredCollector.UTSC[item].Correlation = CORRELATION_KUTSCHER_1994
        elif alphas[9].lower() == "vandeckerhollandsbrunger2001":
            state.dataTranspiredCollector.UTSC[item].Correlation = CORRELATION_VAN_DECKER_HOLLANDS_BRUNGER_2001
        
        roughness_str = alphas[10]
        if roughness_str.lower() == "veryrough":
            state.dataTranspiredCollector.UTSC[item].CollRoughness = 1
        elif roughness_str.lower() == "rough":
            state.dataTranspiredCollector.UTSC[item].CollRoughness = 2
        elif roughness_str.lower() == "mediumrough":
            state.dataTranspiredCollector.UTSC[item].CollRoughness = 3
        elif roughness_str.lower() == "mediumsmooth":
            state.dataTranspiredCollector.UTSC[item].CollRoughness = 4
        elif roughness_str.lower() == "smooth":
            state.dataTranspiredCollector.UTSC[item].CollRoughness = 5
        elif roughness_str.lower() == "verysmooth":
            state.dataTranspiredCollector.UTSC[item].CollRoughness = 6
        
        state.dataTranspiredCollector.UTSC[item].NumSurfs = len(alphas) - 11
        state.dataTranspiredCollector.UTSC[item].SurfPtrs = []
        
        for this_surf in range(state.dataTranspiredCollector.UTSC[item].NumSurfs):
            found = find_item_in_list(
                alphas[11 + this_surf],
                state.dataSurface.Surface
            )
            if found > 0:
                state.dataTranspiredCollector.UTSC[item].SurfPtrs.append(found)
        
        state.dataTranspiredCollector.UTSC[item].HoleDia = numbers[0]
        state.dataTranspiredCollector.UTSC[item].Pitch = numbers[1]
        state.dataTranspiredCollector.UTSC[item].LWEmitt = numbers[2]
        state.dataTranspiredCollector.UTSC[item].SolAbsorp = numbers[3]
        state.dataTranspiredCollector.UTSC[item].Height = numbers[4]
        state.dataTranspiredCollector.UTSC[item].PlenGapThick = numbers[5]
        state.dataTranspiredCollector.UTSC[item].PlenCrossArea = numbers[6]
        state.dataTranspiredCollector.UTSC[item].AreaRatio = numbers[7]
        state.dataTranspiredCollector.UTSC[item].CollectThick = numbers[8]
        state.dataTranspiredCollector.UTSC[item].Cv = numbers[9]
        state.dataTranspiredCollector.UTSC[item].Cd = numbers[10]
        
        total_area = sum(state.dataSurface.Surface[i].Area 
                        for i in state.dataTranspiredCollector.UTSC[item].SurfPtrs)
        state.dataTranspiredCollector.UTSC[item].ProjArea = total_area
        state.dataTranspiredCollector.UTSC[item].ActualArea = total_area * state.dataTranspiredCollector.UTSC[item].AreaRatio
        
        if state.dataTranspiredCollector.UTSC[item].Layout == LAYOUT_TRIANGLE:
            state.dataTranspiredCollector.UTSC[item].Porosity = (
                0.907 * (state.dataTranspiredCollector.UTSC[item].HoleDia / 
                        state.dataTranspiredCollector.UTSC[item].Pitch) ** 2
            )
        elif state.dataTranspiredCollector.UTSC[item].Layout == LAYOUT_SQUARE:
            state.dataTranspiredCollector.UTSC[item].Porosity = (
                (math.pi / 4.0) * (state.dataTranspiredCollector.UTSC[item].HoleDia ** 2) /
                (state.dataTranspiredCollector.UTSC[item].Pitch ** 2)
            )
        
        tilt_rads = abs(state.dataTranspiredCollector.UTSC[item].Tilt) * math.pi / 180.0
        temp_hdelta_npl = (math.sin(tilt_rads) * 
                          state.dataTranspiredCollector.UTSC[item].Height / 4.0)
        state.dataTranspiredCollector.UTSC[item].HdeltaNPL = max(
            temp_hdelta_npl,
            state.dataTranspiredCollector.UTSC[item].PlenGapThick
        )


def init_transpired_collector(state, utsc_num: int):
    if state.dataTranspiredCollector.MyOneTimeFlag:
        for this_utsc in range(state.dataTranspiredCollector.NumUTSC):
            if state.dataTranspiredCollector.UTSC[this_utsc].Layout == LAYOUT_TRIANGLE:
                if state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CORRELATION_KUTSCHER_1994:
                    pass
                elif state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CORRELATION_VAN_DECKER_HOLLANDS_BRUNGER_2001:
                    state.dataTranspiredCollector.UTSC[this_utsc].Pitch /= 1.6
            
            if state.dataTranspiredCollector.UTSC[this_utsc].Layout == LAYOUT_SQUARE:
                if state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CORRELATION_KUTSCHER_1994:
                    state.dataTranspiredCollector.UTSC[this_utsc].Pitch *= 1.6
                elif state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CORRELATION_VAN_DECKER_HOLLANDS_BRUNGER_2001:
                    pass
        
        state.dataTranspiredCollector.MyEnvrnFlag = [True] * state.dataTranspiredCollector.NumUTSC
        state.dataTranspiredCollector.MyOneTimeFlag = False
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataTranspiredCollector.MyEnvrnFlag[utsc_num - 1]:
        state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast = 22.5
        state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast = 22.0
        state.dataTranspiredCollector.MyEnvrnFlag[utsc_num - 1] = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataTranspiredCollector.MyEnvrnFlag[utsc_num - 1] = True
    
    sum_area = sum(state.dataSurface.Surface[i].Area 
                  for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs)
    
    if not state.dataEnvrn.IsRain:
        sum_product_area_drybulb = sum(
            state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
            for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs
        )
        tamb = sum_product_area_drybulb / sum_area
    else:
        sum_product_area_wetbulb = sum(
            state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
            for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs
        )
        tamb = sum_product_area_wetbulb / sum_area
    
    state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot = sum(
        state.dataLoopNodes.Node[i].MassFlowRate
        for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].InletNode
    )
    state.dataTranspiredCollector.UTSC[utsc_num - 1].IsOn = False
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Tplen = state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll = state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast
    state.dataTranspiredCollector.UTSC[utsc_num - 1].TairHX = tamb
    state.dataTranspiredCollector.UTSC[utsc_num - 1].MdotVent = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].HXeff = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Isc = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].UTSCEfficiency = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].UTSCCollEff = 0.0


def calc_active_transpired_collector(state, utsc_num: int):
    time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
    
    sum_area = sum(state.dataSurface.Surface[i].Area 
                  for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs)
    
    if not state.dataEnvrn.IsRain:
        sum_product_area_drybulb = sum(
            state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
            for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs
        )
        tamb = sum_product_area_drybulb / sum_area
    else:
        sum_product_area_wetbulb = sum(
            state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
            for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs
        )
        tamb = sum_product_area_wetbulb / sum_area
    
    rho_air = state.dataEnvrn.get_rho_air(tamb, state.dataEnvrn.OutHumRat)
    cp_air = state.dataEnvrn.get_cp_air(state.dataEnvrn.OutHumRat)
    
    hole_area = (state.dataTranspiredCollector.UTSC[utsc_num - 1].ActualArea * 
                state.dataTranspiredCollector.UTSC[utsc_num - 1].Porosity)
    
    a = state.dataTranspiredCollector.UTSC[utsc_num - 1].ProjArea
    
    vholes = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot / rho_air / hole_area
    vplen = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot / rho_air / state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenCrossArea
    vsuction = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot / rho_air / a
    
    hc_plen = 5.62 + 3.92 * vplen
    
    d = state.dataTranspiredCollector.UTSC[utsc_num - 1].HoleDia
    red = vholes * d / KINEMATIC_VISCOSITY
    p = state.dataTranspiredCollector.UTSC[utsc_num - 1].Pitch
    por = state.dataTranspiredCollector.UTSC[utsc_num - 1].Porosity
    mdot = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot
    
    num_surfs = state.dataTranspiredCollector.UTSC[utsc_num - 1].NumSurfs
    
    hx_eff = 0.0
    
    if state.dataTranspiredCollector.UTSC[utsc_num - 1].Correlation == CORRELATION_KUTSCHER_1994:
        aless_holes = a - hole_area
        nud = 2.75 * ((p / d) ** (-1.2) * red ** 0.43 + 
                     (0.011 * por * red * (state.dataEnvrn.WindSpeed / vsuction) ** 0.48))
        u = THERMAL_CONDUCTIVITY * nud / d
        hx_eff = 1.0 - math.exp(-1.0 * (u * aless_holes) / (mdot * cp_air))
    
    elif state.dataTranspiredCollector.UTSC[utsc_num - 1].Correlation == CORRELATION_VAN_DECKER_HOLLANDS_BRUNGER_2001:
        t = state.dataTranspiredCollector.UTSC[utsc_num - 1].CollectThick
        res = vsuction * p / KINEMATIC_VISCOSITY
        rew = state.dataEnvrn.WindSpeed * p / KINEMATIC_VISCOSITY
        reb = vholes * p / KINEMATIC_VISCOSITY
        reh = (vsuction * d) / (KINEMATIC_VISCOSITY * por)
        
        if red > 0.0:
            if rew > 0.0:
                hx_eff = ((1.0 - (1.0 + res * max(1.733 * rew ** (-0.5), 0.02136)) ** (-1.0)) *
                         (1.0 - (1.0 + 0.2273 * math.sqrt(reb)) ** (-1.0)) *
                         math.exp(-0.01895 * (p / d) - (20.62 / reh) * (t / d)))
            else:
                hx_eff = ((1.0 - (1.0 + res * 0.02136) ** (-1.0)) *
                         (1.0 - (1.0 + 0.2273 * math.sqrt(reb)) ** (-1.0)) *
                         math.exp(-0.01895 * (p / d) - (20.62 / reh) * (t / d)))
        else:
            hx_eff = 0.0
    
    sum_area_weighted = sum(state.dataSurface.Surface[i].Area 
                           for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs)
    
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Isc = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].HXeff = hx_eff
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Vsuction = vsuction
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenumVelocity = vplen
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutTemp = tamb
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutHumRat = state.dataEnvrn.OutHumRat
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutMassFlow = mdot
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SensHeatingRate = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SensHeatingEnergy = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveACH = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotVent = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotWind = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotTherm = 0.0


def calc_passive_transpired_collector(state, utsc_num: int):
    sum_area = sum(state.dataSurface.Surface[i].Area 
                  for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs)
    
    sum_produc_area_drybulb = sum(
        state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
        for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs
    )
    sum_produc_area_wetbulb = sum(
        state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
        for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs
    )
    
    tamb = sum_produc_area_drybulb / sum_area
    twbamb = sum_produc_area_wetbulb / sum_area
    
    out_hum_rat_amb = state.dataEnvrn.get_humidity_ratio(tamb, twbamb)
    rho_air = state.dataEnvrn.get_rho_air(tamb, out_hum_rat_amb)
    hole_area = (state.dataTranspiredCollector.UTSC[utsc_num - 1].ActualArea * 
                state.dataTranspiredCollector.UTSC[utsc_num - 1].Porosity)
    
    asp_rat = (state.dataTranspiredCollector.UTSC[utsc_num - 1].Height / 
              state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenGapThick)
    tmp_ts_coll = state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast
    tmp_ta_plen = state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast
    
    (ts_baffle, ta_gap, hc_plen, hr_plen, isc, mdot_vent, 
     vdot_wind, vdot_thermal) = calc_passive_exterior_baffle_gap(
        state,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs,
        hole_area,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].Cv,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].Cd,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].HdeltaNPL,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].SolAbsorp,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].LWEmitt,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].Tilt,
        asp_rat,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenGapThick,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].CollRoughness,
        state.dataTranspiredCollector.UTSC[utsc_num - 1].QdotSource,
        tmp_ts_coll,
        tmp_ta_plen
    )
    
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Isc = isc
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Tplen = ta_gap
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll = ts_baffle
    state.dataTranspiredCollector.UTSC[utsc_num - 1].HrPlen = hr_plen
    state.dataTranspiredCollector.UTSC[utsc_num - 1].HcPlen = hc_plen
    state.dataTranspiredCollector.UTSC[utsc_num - 1].TairHX = tamb
    state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].InletTempDB = tamb
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Vsuction = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenumVelocity = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutTemp = ta_gap
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutHumRat = out_hum_rat_amb
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutMassFlow = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SensHeatingRate = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].SensHeatingEnergy = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveACH = (
        (mdot_vent / rho_air) *
        (1.0 / (state.dataTranspiredCollector.UTSC[utsc_num - 1].ProjArea * 
               state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenGapThick)) *
        SECS_IN_HOUR
    )
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotVent = mdot_vent
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotWind = vdot_wind * rho_air
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotTherm = vdot_thermal * rho_air
    state.dataTranspiredCollector.UTSC[utsc_num - 1].UTSCEfficiency = 0.0


def update_transpired_collector(state, utsc_num: int):
    state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tplen
    state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll
    
    if state.dataTranspiredCollector.UTSC[utsc_num - 1].IsOn:
        if state.dataTranspiredCollector.UTSC[utsc_num - 1].NumOASysAttached == 1:
            outlet_node = state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[0]
            state.dataLoopNodes.Node[outlet_node].MassFlowRate = state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutMassFlow
            state.dataLoopNodes.Node[outlet_node].Temp = state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutTemp
            state.dataLoopNodes.Node[outlet_node].HumRat = state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutHumRat
            state.dataLoopNodes.Node[outlet_node].Enthalpy = state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutEnth
        else:
            for i in range(state.dataTranspiredCollector.UTSC[utsc_num - 1].NumOASysAttached):
                state.dataLoopNodes.Node[state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[i]].MassFlowRate = (
                    state.dataLoopNodes.Node[state.dataTranspiredCollector.UTSC[utsc_num - 1].InletNode[i]].MassFlowRate
                )
                state.dataLoopNodes.Node[state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[i]].Temp = (
                    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutTemp
                )
                state.dataLoopNodes.Node[state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[i]].HumRat = (
                    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutHumRat
                )
                state.dataLoopNodes.Node[state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[i]].Enthalpy = (
                    state.dataTranspiredCollector.UTSC[utsc_num - 1].SupOutEnth
                )
    else:
        for i in range(len(state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode)):
            outlet_node = state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[i]
            inlet_node = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletNode[i]
            state.dataLoopNodes.Node[outlet_node].MassFlowRate = state.dataLoopNodes.Node[inlet_node].MassFlowRate
            state.dataLoopNodes.Node[outlet_node].Temp = state.dataLoopNodes.Node[inlet_node].Temp
            state.dataLoopNodes.Node[outlet_node].HumRat = state.dataLoopNodes.Node[inlet_node].HumRat
            state.dataLoopNodes.Node[outlet_node].Enthalpy = state.dataLoopNodes.Node[inlet_node].Enthalpy
    
    this_oscm = state.dataTranspiredCollector.UTSC[utsc_num - 1].OSCMPtr
    state.dataSurface.OSCM[this_oscm - 1].TConv = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tplen
    state.dataSurface.OSCM[this_oscm - 1].HConv = state.dataTranspiredCollector.UTSC[utsc_num - 1].HcPlen
    state.dataSurface.OSCM[this_oscm - 1].TRad = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll
    state.dataSurface.OSCM[this_oscm - 1].HRad = state.dataTranspiredCollector.UTSC[utsc_num - 1].HrPlen


def set_utsc_qdot_source(state, utsc_num: int, q_source: float):
    state.dataTranspiredCollector.UTSC[utsc_num - 1].QdotSource = (
        q_source / state.dataTranspiredCollector.UTSC[utsc_num - 1].ProjArea
    )


def get_transpired_collector_index(state, surface_ptr: int) -> int:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False
    
    if surface_ptr == 0:
        show_fatal_error(state, f"Invalid surface passed to GetTranspiredCollectorIndex")
    
    utsc_num = 0
    found = False
    
    for this_utsc in range(state.dataTranspiredCollector.NumUTSC):
        for this_surf in range(state.dataTranspiredCollector.UTSC[this_utsc].NumSurfs):
            if surface_ptr == state.dataTranspiredCollector.UTSC[this_utsc].SurfPtrs[this_surf]:
                found = True
                utsc_num = this_utsc + 1
    
    if not found:
        show_fatal_error(state, f"Did not find surface in UTSC description in GetTranspiredCollectorIndex")
    
    return utsc_num


def get_utsc_ts_coll(state, utsc_num: int) -> float:
    return state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll


def get_air_inlet_node_num(state, utsc_name: str) -> Tuple[int, bool]:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False
    
    which_utsc = find_item_in_list(utsc_name, state.dataTranspiredCollector.UTSC)
    errors_found = False
    
    if which_utsc != 0:
        node_num = state.dataTranspiredCollector.UTSC[which_utsc - 1].InletNode[0]
    else:
        show_severe_error(state, f"GetAirInletNodeNum: Could not find TranspiredCollector = \"{utsc_name}\"")
        errors_found = True
        node_num = 0
    
    return node_num, errors_found


def get_air_outlet_node_num(state, utsc_name: str) -> Tuple[int, bool]:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False
    
    which_utsc = find_item_in_list(utsc_name, state.dataTranspiredCollector.UTSC)
    errors_found = False
    
    if which_utsc != 0:
        node_num = state.dataTranspiredCollector.UTSC[which_utsc - 1].OutletNode[0]
    else:
        show_severe_error(state, f"GetAirOutletNodeNum: Could not find TranspiredCollector = \"{utsc_name}\"")
        errors_found = True
        node_num = 0
    
    return node_num, errors_found


def calc_passive_exterior_baffle_gap(
    state,
    surf_ptr_arr: List[int],
    vent_area: float,
    cv: float,
    cd: float,
    hdelta_npl: float,
    sol_abs: float,
    abs_ext: float,
    tilt: float,
    asp_rat: float,
    gap_thick: float,
    roughness: int,
    qdot_source: float,
    ts_baffle: float,
    ta_gap: float
) -> Tuple[float, float, float, float, float, float, float, float]:
    
    sum_area = sum(state.dataSurface.Surface[i].Area for i in surf_ptr_arr)
    sum_produc_area_drybulb = sum(
        state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
        for i in surf_ptr_arr
    )
    sum_produc_area_wetbulb = sum(
        state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
        for i in surf_ptr_arr
    )
    
    local_out_drybulb_temp = sum_produc_area_drybulb / sum_area
    local_wetbulb_temp = sum_produc_area_wetbulb / sum_area
    
    local_out_hum_rat = state.dataEnvrn.get_humidity_ratio(local_out_drybulb_temp, local_wetbulb_temp)
    rho_air = state.dataEnvrn.get_rho_air(local_out_drybulb_temp, local_out_hum_rat)
    cp_air = state.dataEnvrn.get_cp_air(local_out_hum_rat)
    
    if not state.dataEnvrn.IsRain:
        tamb = local_out_drybulb_temp
    else:
        tamb = local_wetbulb_temp
    
    a = sum_area
    tmp_ts_baf = ts_baffle
    
    num_surfs = len(surf_ptr_arr)
    
    vwind = state.dataEnvrn.WindSpeed
    gr = (GRAVITATIONAL_CONSTANT * (gap_thick ** 3) * abs(0.0 - tmp_ts_baf) * 
         (rho_air ** 2) / ((273.15 + 0.5 * (tmp_ts_baf + 0.0)) * (KINEMATIC_VISCOSITY ** 2)))
    
    nu_plen = passive_gap_nusselt_number(asp_rat, tilt, tmp_ts_baf, 0.0, gr)
    hc_plen = nu_plen * (THERMAL_CONDUCTIVITY / gap_thick)
    
    vdot_wind = cv * (vent_area / 2.0) * vwind
    
    if ta_gap > tamb:
        vdot_thermal = cd * (vent_area / 2.0) * math.sqrt(
            2.0 * GRAVITATIONAL_CONSTANT * hdelta_npl * (ta_gap - tamb) / (ta_gap + 273.15)
        )
    elif ta_gap == tamb:
        vdot_thermal = 0.0
    else:
        if (abs(tilt) < 5.0) or (abs(tilt - 180.0) < 5.0):
            vdot_thermal = 0.0
        else:
            vdot_thermal = cd * (vent_area / 2.0) * math.sqrt(
                2.0 * GRAVITATIONAL_CONSTANT * hdelta_npl * (tamb - ta_gap) / (tamb + 273.15)
            )
    
    vdot_vent = vdot_wind + vdot_thermal
    mdot_vent = vdot_vent * rho_air
    
    ts_baffle = (sol_abs * 0.0 + abs_ext * tamb + hc_plen * ta_gap + qdot_source) / (abs_ext + hc_plen)
    ta_gap = (hc_plen * a * 0.0 + mdot_vent * cp_air * tamb + hc_plen * a * ts_baffle) / (
        hc_plen * a + mdot_vent * cp_air + hc_plen * a
    )
    
    hr_plen = 0.0
    isc = 0.0
    
    return ts_baffle, ta_gap, hc_plen, hr_plen, isc, mdot_vent, vdot_wind, vdot_thermal


def passive_gap_nusselt_number(asp_rat: float, tilt: float, tso: float, tsi: float, gr: float) -> float:
    tiltr = tilt * math.pi / 180.0
    ra = gr * PRANDTL_NUMBER
    
    if ra <= 1.0e4:
        gnu901 = 1.0 + 1.7596678e-10 * (ra ** 2.2984755)
    elif ra <= 5.0e4:
        gnu901 = 0.028154 * (ra ** 0.4134)
    else:
        gnu901 = 0.0673838 * (ra ** (1.0 / 3.0))
    
    gnu902 = 0.242 * ((ra / asp_rat) ** 0.272)
    gnu90 = max(gnu901, gnu902)
    
    if tso > tsi:
        return 1.0 + (gnu90 - 1.0) * math.sin(tiltr)
    
    if tilt >= 60.0:
        g = 0.5 * ((1.0 + (ra / 3160.0) ** 20.6) ** (-0.1))
        gnu601a = 1.0 + (0.0936 * (ra ** 0.314) / (1.0 + g)) ** (1.0 / 7.0)
        gnu601 = gnu601a ** 0.142857
        
        gnu602 = (0.104 + 0.175 / asp_rat) * (ra ** 0.283)
        gnu60 = max(gnu601, gnu602)
        
        return ((90.0 - tilt) * gnu60 + (tilt - 60.0) * gnu90) / 30.0
    
    cra = ra * math.cos(tiltr)
    a_coeff = 1.0 - 1708.0 / cra
    b_coeff = (cra / 5830.0) ** (1.0 / 3.0) - 1.0
    gnua = (abs(a_coeff) + a_coeff) / 2.0
    gnub = (abs(b_coeff) + b_coeff) / 2.0
    ang = 1708.0 * (math.sin(1.8 * tiltr) ** 1.6)
    
    return 1.0 + 1.44 * gnua * (1.0 - ang / cra) + gnub


def find_item_in_list(name: str, items: List) -> int:
    for i, item in enumerate(items):
        if isinstance(item, UTSCDataStruct) and item.Name == name:
            return i + 1
    return 0


def show_fatal_error(state, message: str):
    raise RuntimeError(f"FATAL ERROR: {message}")


def show_severe_error(state, message: str):
    print(f"SEVERE ERROR: {message}")


def show_warning_message(state, message: str):
    print(f"WARNING: {message}")


def get_schedule_always_on(state):
    return None


def get_schedule(state, name: str):
    return None

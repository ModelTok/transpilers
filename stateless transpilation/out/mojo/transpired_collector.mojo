from math import pi, sin, cos, sqrt, abs, exp, pow, floor, ceil
from collections import InlineArray

alias LayoutSquare = 1
alias LayoutTriangle = 2
alias CorrelationKutscher1994 = 1
alias CorrelationVanDeckerHollandsBrunger2001 = 2

alias StefanBoltzmann = 5.6697e-08
alias KinematicViscosity = 15.66e-6
alias ThermalConductivity = 0.0267
alias GravitationalConstant = 9.807
alias PrandtlNumber = 0.71

alias SecsInHour = 3600.0


@dataclass
struct Vector:
    x: Float64
    y: Float64
    z: Float64
    
    fn __init__(inout self, x: Float64 = 0.0, y: Float64 = 0.0, z: Float64 = 0.0):
        self.x = x
        self.y = y
        self.z = z


@dataclass
struct UTSCDataStruct:
    var Name: String
    var OSCMName: String
    var OSCMPtr: Int32
    var availSched: Pointer[Object]
    var InletNode: List[Int32]
    var OutletNode: List[Int32]
    var ControlNode: List[Int32]
    var ZoneNode: List[Int32]
    var Layout: Int32
    var Correlation: Int32
    var HoleDia: Float64
    var Pitch: Float64
    var LWEmitt: Float64
    var SolAbsorp: Float64
    var CollRoughness: Int32
    var PlenGapThick: Float64
    var PlenCrossArea: Float64
    var NumSurfs: Int32
    var SurfPtrs: List[Int32]
    var Height: Float64
    var AreaRatio: Float64
    var CollectThick: Float64
    var Cv: Float64
    var Cd: Float64
    var NumOASysAttached: Int32
    var freeHeatSetPointSched: Pointer[Object]
    var VsucErrIndex: Int32
    var ActualArea: Float64
    var ProjArea: Float64
    var Centroid: Vector
    var Porosity: Float64
    var IsOn: Bool
    var Tplen: Float64
    var Tcoll: Float64
    var TplenLast: Float64
    var TcollLast: Float64
    var HrPlen: Float64
    var HcPlen: Float64
    var MdotVent: Float64
    var HdeltaNPL: Float64
    var TairHX: Float64
    var InletMDot: Float64
    var InletTempDB: Float64
    var Tilt: Float64
    var Azimuth: Float64
    var QdotSource: Float64
    var Isc: Float64
    var HXeff: Float64
    var Vsuction: Float64
    var PassiveACH: Float64
    var PassiveMdotVent: Float64
    var PassiveMdotWind: Float64
    var PassiveMdotTherm: Float64
    var PlenumVelocity: Float64
    var SupOutTemp: Float64
    var SupOutHumRat: Float64
    var SupOutEnth: Float64
    var SupOutMassFlow: Float64
    var SensHeatingRate: Float64
    var SensHeatingEnergy: Float64
    var SensCoolingRate: Float64
    var SensCoolingEnergy: Float64
    var UTSCEfficiency: Float64
    var UTSCCollEff: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.OSCMName = ""
        self.OSCMPtr = 0
        self.availSched = Pointer[Object]()
        self.InletNode = List[Int32]()
        self.OutletNode = List[Int32]()
        self.ControlNode = List[Int32]()
        self.ZoneNode = List[Int32]()
        self.Layout = 0
        self.Correlation = 0
        self.HoleDia = 0.0
        self.Pitch = 0.0
        self.LWEmitt = 0.0
        self.SolAbsorp = 0.0
        self.CollRoughness = 0
        self.PlenGapThick = 0.0
        self.PlenCrossArea = 0.0
        self.NumSurfs = 0
        self.SurfPtrs = List[Int32]()
        self.Height = 0.0
        self.AreaRatio = 0.0
        self.CollectThick = 0.0
        self.Cv = 0.0
        self.Cd = 0.0
        self.NumOASysAttached = 0
        self.freeHeatSetPointSched = Pointer[Object]()
        self.VsucErrIndex = 0
        self.ActualArea = 0.0
        self.ProjArea = 0.0
        self.Centroid = Vector(0.0, 0.0, 0.0)
        self.Porosity = 0.0
        self.IsOn = False
        self.Tplen = 0.0
        self.Tcoll = 0.0
        self.TplenLast = 22.5
        self.TcollLast = 22.0
        self.HrPlen = 0.0
        self.HcPlen = 0.0
        self.MdotVent = 0.0
        self.HdeltaNPL = 0.0
        self.TairHX = 0.0
        self.InletMDot = 0.0
        self.InletTempDB = 0.0
        self.Tilt = 0.0
        self.Azimuth = 0.0
        self.QdotSource = 0.0
        self.Isc = 0.0
        self.HXeff = 0.0
        self.Vsuction = 0.0
        self.PassiveACH = 0.0
        self.PassiveMdotVent = 0.0
        self.PassiveMdotWind = 0.0
        self.PassiveMdotTherm = 0.0
        self.PlenumVelocity = 0.0
        self.SupOutTemp = 0.0
        self.SupOutHumRat = 0.0
        self.SupOutEnth = 0.0
        self.SupOutMassFlow = 0.0
        self.SensHeatingRate = 0.0
        self.SensHeatingEnergy = 0.0
        self.SensCoolingRate = 0.0
        self.SensCoolingEnergy = 0.0
        self.UTSCEfficiency = 0.0
        self.UTSCCollEff = 0.0


fn sim_transpired_collector(state: EnergyPlusData, comp_name: String, inout comp_index: Int32) -> Int32:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False
    
    var utsc_num = comp_index
    if comp_index == 0:
        utsc_num = find_item_in_list(comp_name, state.dataTranspiredCollector.UTSC)
        if utsc_num == 0:
            show_fatal_error(state, "Transpired Collector not found=" + comp_name)
        comp_index = utsc_num
    else:
        utsc_num = comp_index
        if utsc_num > state.dataTranspiredCollector.NumUTSC or utsc_num < 1:
            show_fatal_error(
                state,
                "SimTranspiredCollector: Invalid CompIndex passed=" + String(utsc_num) +
                ", Number of Transpired Collectors=" + String(state.dataTranspiredCollector.NumUTSC) +
                ", UTSC name=" + comp_name
            )
        if state.dataTranspiredCollector.CheckEquipName[utsc_num - 1]:
            if comp_name != state.dataTranspiredCollector.UTSC[utsc_num - 1].Name:
                show_fatal_error(
                    state,
                    "SimTranspiredCollector: Invalid CompIndex passed=" + String(utsc_num) +
                    ", Transpired Collector name=" + comp_name +
                    ", stored Transpired Collector Name for that index=" +
                    state.dataTranspiredCollector.UTSC[utsc_num - 1].Name
                )
            state.dataTranspiredCollector.CheckEquipName[utsc_num - 1] = False
    
    init_transpired_collector(state, comp_index)
    
    var utsc_ci = state.dataTranspiredCollector.UTSC[comp_index - 1]
    utsc_ci.IsOn = False
    
    if (utsc_ci.availSched.get_current_val() > 0.0) and (utsc_ci.InletMDot > 0.0):
        var control_lt_set: Bool = False
        var control_lt_schedule: Bool = False
        var zone_lt_schedule: Bool = False
        
        for i in range(len(utsc_ci.InletNode)):
            var inlet_node_i = utsc_ci.InletNode[i]
            var control_node_i = utsc_ci.ControlNode[i]
            var zone_node_i = utsc_ci.ZoneNode[i]
            
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


fn get_transpired_collector_input(state: EnergyPlusData):
    state.dataTranspiredCollector.NumUTSC = state.dataInputProcessing.inputProcessor.get_num_objects_found(
        state, "SolarCollector:UnglazedTranspired"
    )
    
    state.dataTranspiredCollector.UTSC = List[UTSCDataStruct]()
    for i in range(state.dataTranspiredCollector.NumUTSC):
        state.dataTranspiredCollector.UTSC.append(UTSCDataStruct())
    
    state.dataTranspiredCollector.CheckEquipName = List[Bool]()
    for i in range(state.dataTranspiredCollector.NumUTSC):
        state.dataTranspiredCollector.CheckEquipName.append(True)
    
    for item in range(state.dataTranspiredCollector.NumUTSC):
        var alphas: List[String]
        var numbers: List[Float64]
        state.dataInputProcessing.inputProcessor.get_object_item(
            state, "SolarCollector:UnglazedTranspired", item + 1, alphas, numbers
        )
        
        state.dataTranspiredCollector.UTSC[item].Name = alphas[0]
        state.dataTranspiredCollector.UTSC[item].OSCMName = alphas[1]
        
        var found = find_item_in_list(
            state.dataTranspiredCollector.UTSC[item].OSCMName,
            state.dataSurface.OSCM
        )
        if found == 0:
            show_severe_error(state, "OSCM not found=" + state.dataTranspiredCollector.UTSC[item].OSCMName)
        state.dataTranspiredCollector.UTSC[item].OSCMPtr = found
        
        if alphas[2] == "":
            state.dataTranspiredCollector.UTSC[item].availSched = get_schedule_always_on(state)
        else:
            state.dataTranspiredCollector.UTSC[item].availSched = get_schedule(state, alphas[2])
        
        if state.dataTranspiredCollector.UTSC[item].NumOASysAttached == 0:
            state.dataTranspiredCollector.UTSC[item].NumOASysAttached = 1
            state.dataTranspiredCollector.UTSC[item].InletNode.append(0)
            state.dataTranspiredCollector.UTSC[item].OutletNode.append(0)
            state.dataTranspiredCollector.UTSC[item].ControlNode.append(0)
            state.dataTranspiredCollector.UTSC[item].ZoneNode.append(0)
        
        if alphas[8] == "":
            show_severe_error(state, "Free heat setpoint schedule is blank")
        state.dataTranspiredCollector.UTSC[item].freeHeatSetPointSched = get_schedule(state, alphas[8])
        
        if alphas[8].lower() == "triangle":
            state.dataTranspiredCollector.UTSC[item].Layout = LayoutTriangle
        elif alphas[8].lower() == "square":
            state.dataTranspiredCollector.UTSC[item].Layout = LayoutSquare
        
        if alphas[9].lower() == "kutscher1994":
            state.dataTranspiredCollector.UTSC[item].Correlation = CorrelationKutscher1994
        elif alphas[9].lower() == "vandeckerhollandsbrunger2001":
            state.dataTranspiredCollector.UTSC[item].Correlation = CorrelationVanDeckerHollandsBrunger2001
        
        var roughness_str = alphas[10]
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
        
        state.dataTranspiredCollector.UTSC[item].NumSurfs = Int32(len(alphas) - 11)
        state.dataTranspiredCollector.UTSC[item].SurfPtrs.clear()
        
        for this_surf in range(state.dataTranspiredCollector.UTSC[item].NumSurfs):
            var found_surf = find_item_in_list(
                alphas[11 + this_surf],
                state.dataSurface.Surface
            )
            if found_surf > 0:
                state.dataTranspiredCollector.UTSC[item].SurfPtrs.append(Int32(found_surf))
        
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
        
        var total_area: Float64 = 0.0
        for i in state.dataTranspiredCollector.UTSC[item].SurfPtrs:
            total_area += state.dataSurface.Surface[i].Area
        
        state.dataTranspiredCollector.UTSC[item].ProjArea = total_area
        state.dataTranspiredCollector.UTSC[item].ActualArea = (
            total_area * state.dataTranspiredCollector.UTSC[item].AreaRatio
        )
        
        if state.dataTranspiredCollector.UTSC[item].Layout == LayoutTriangle:
            var hole_pitch_ratio = state.dataTranspiredCollector.UTSC[item].HoleDia / state.dataTranspiredCollector.UTSC[item].Pitch
            state.dataTranspiredCollector.UTSC[item].Porosity = 0.907 * hole_pitch_ratio * hole_pitch_ratio
        elif state.dataTranspiredCollector.UTSC[item].Layout == LayoutSquare:
            var hole_ratio = state.dataTranspiredCollector.UTSC[item].HoleDia / state.dataTranspiredCollector.UTSC[item].Pitch
            state.dataTranspiredCollector.UTSC[item].Porosity = (pi / 4.0) * hole_ratio * hole_ratio
        
        var tilt_rads = abs(state.dataTranspiredCollector.UTSC[item].Tilt) * pi / 180.0
        var temp_hdelta_npl = sin(tilt_rads) * state.dataTranspiredCollector.UTSC[item].Height / 4.0
        state.dataTranspiredCollector.UTSC[item].HdeltaNPL = max(
            temp_hdelta_npl,
            state.dataTranspiredCollector.UTSC[item].PlenGapThick
        )


fn init_transpired_collector(state: EnergyPlusData, utsc_num: Int32):
    if state.dataTranspiredCollector.MyOneTimeFlag:
        for this_utsc in range(state.dataTranspiredCollector.NumUTSC):
            if state.dataTranspiredCollector.UTSC[this_utsc].Layout == LayoutTriangle:
                if state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CorrelationKutscher1994:
                    pass
                elif state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CorrelationVanDeckerHollandsBrunger2001:
                    state.dataTranspiredCollector.UTSC[this_utsc].Pitch /= 1.6
            
            if state.dataTranspiredCollector.UTSC[this_utsc].Layout == LayoutSquare:
                if state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CorrelationKutscher1994:
                    state.dataTranspiredCollector.UTSC[this_utsc].Pitch *= 1.6
                elif state.dataTranspiredCollector.UTSC[this_utsc].Correlation == CorrelationVanDeckerHollandsBrunger2001:
                    pass
        
        state.dataTranspiredCollector.MyEnvrnFlag = List[Bool]()
        for i in range(state.dataTranspiredCollector.NumUTSC):
            state.dataTranspiredCollector.MyEnvrnFlag.append(True)
        state.dataTranspiredCollector.MyOneTimeFlag = False
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataTranspiredCollector.MyEnvrnFlag[utsc_num - 1]:
        state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast = 22.5
        state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast = 22.0
        state.dataTranspiredCollector.MyEnvrnFlag[utsc_num - 1] = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataTranspiredCollector.MyEnvrnFlag[utsc_num - 1] = True
    
    var sum_area: Float64 = 0.0
    for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs:
        sum_area += state.dataSurface.Surface[i].Area
    
    var tamb: Float64
    if not state.dataEnvrn.IsRain:
        var sum_product_area_drybulb: Float64 = 0.0
        for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs:
            sum_product_area_drybulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
        tamb = sum_product_area_drybulb / sum_area
    else:
        var sum_product_area_wetbulb: Float64 = 0.0
        for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs:
            sum_product_area_wetbulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
        tamb = sum_product_area_wetbulb / sum_area
    
    var inlet_mdot: Float64 = 0.0
    for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].InletNode:
        inlet_mdot += state.dataLoopNodes.Node[i].MassFlowRate
    
    state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot = inlet_mdot
    state.dataTranspiredCollector.UTSC[utsc_num - 1].IsOn = False
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Tplen = state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll = state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast
    state.dataTranspiredCollector.UTSC[utsc_num - 1].TairHX = tamb
    state.dataTranspiredCollector.UTSC[utsc_num - 1].MdotVent = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].HXeff = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].Isc = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].UTSCEfficiency = 0.0
    state.dataTranspiredCollector.UTSC[utsc_num - 1].UTSCCollEff = 0.0


fn calc_active_transpired_collector(state: EnergyPlusData, utsc_num: Int32):
    var time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
    
    var sum_area: Float64 = 0.0
    for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs:
        sum_area += state.dataSurface.Surface[i].Area
    
    var tamb: Float64
    if not state.dataEnvrn.IsRain:
        var sum_product_area_drybulb: Float64 = 0.0
        for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs:
            sum_product_area_drybulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
        tamb = sum_product_area_drybulb / sum_area
    else:
        var sum_product_area_wetbulb: Float64 = 0.0
        for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs:
            sum_product_area_wetbulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
        tamb = sum_product_area_wetbulb / sum_area
    
    var rho_air = state.dataEnvrn.get_rho_air(tamb, state.dataEnvrn.OutHumRat)
    var cp_air = state.dataEnvrn.get_cp_air(state.dataEnvrn.OutHumRat)
    
    var hole_area = (state.dataTranspiredCollector.UTSC[utsc_num - 1].ActualArea * 
                    state.dataTranspiredCollector.UTSC[utsc_num - 1].Porosity)
    
    var a = state.dataTranspiredCollector.UTSC[utsc_num - 1].ProjArea
    
    var vholes = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot / rho_air / hole_area
    var vplen = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot / rho_air / state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenCrossArea
    var vsuction = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot / rho_air / a
    
    var hc_plen = 5.62 + 3.92 * vplen
    
    var d = state.dataTranspiredCollector.UTSC[utsc_num - 1].HoleDia
    var red = vholes * d / KinematicViscosity
    var p = state.dataTranspiredCollector.UTSC[utsc_num - 1].Pitch
    var por = state.dataTranspiredCollector.UTSC[utsc_num - 1].Porosity
    var mdot = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletMDot
    
    var num_surfs = state.dataTranspiredCollector.UTSC[utsc_num - 1].NumSurfs
    
    var hx_eff: Float64 = 0.0
    
    if state.dataTranspiredCollector.UTSC[utsc_num - 1].Correlation == CorrelationKutscher1994:
        var aless_holes = a - hole_area
        var nud = 2.75 * (pow(p / d, -1.2) * pow(red, 0.43) + 
                         (0.011 * por * red * pow(state.dataEnvrn.WindSpeed / vsuction, 0.48)))
        var u = ThermalConductivity * nud / d
        hx_eff = 1.0 - exp(-1.0 * (u * aless_holes) / (mdot * cp_air))
    
    elif state.dataTranspiredCollector.UTSC[utsc_num - 1].Correlation == CorrelationVanDeckerHollandsBrunger2001:
        var t = state.dataTranspiredCollector.UTSC[utsc_num - 1].CollectThick
        var res = vsuction * p / KinematicViscosity
        var rew = state.dataEnvrn.WindSpeed * p / KinematicViscosity
        var reb = vholes * p / KinematicViscosity
        var reh = (vsuction * d) / (KinematicViscosity * por)
        
        if red > 0.0:
            if rew > 0.0:
                var term1 = pow(1.0 + res * max(1.733 * pow(rew, -0.5), 0.02136), -1.0)
                var term2 = pow(1.0 + 0.2273 * sqrt(reb), -1.0)
                var term3 = exp(-0.01895 * (p / d) - (20.62 / reh) * (t / d))
                hx_eff = (1.0 - term1) * (1.0 - term2) * term3
            else:
                var term1 = pow(1.0 + res * 0.02136, -1.0)
                var term2 = pow(1.0 + 0.2273 * sqrt(reb), -1.0)
                var term3 = exp(-0.01895 * (p / d) - (20.62 / reh) * (t / d))
                hx_eff = (1.0 - term1) * (1.0 - term2) * term3
        else:
            hx_eff = 0.0
    
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


fn calc_passive_transpired_collector(state: EnergyPlusData, utsc_num: Int32):
    var sum_area: Float64 = 0.0
    var sum_produc_area_drybulb: Float64 = 0.0
    var sum_produc_area_wetbulb: Float64 = 0.0
    
    for i in state.dataTranspiredCollector.UTSC[utsc_num - 1].SurfPtrs:
        sum_area += state.dataSurface.Surface[i].Area
        sum_produc_area_drybulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
        sum_produc_area_wetbulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
    
    var tamb = sum_produc_area_drybulb / sum_area
    var twbamb = sum_produc_area_wetbulb / sum_area
    
    var out_hum_rat_amb = state.dataEnvrn.get_humidity_ratio(tamb, twbamb)
    var rho_air = state.dataEnvrn.get_rho_air(tamb, out_hum_rat_amb)
    var hole_area = (state.dataTranspiredCollector.UTSC[utsc_num - 1].ActualArea * 
                    state.dataTranspiredCollector.UTSC[utsc_num - 1].Porosity)
    
    var asp_rat = (state.dataTranspiredCollector.UTSC[utsc_num - 1].Height / 
                  state.dataTranspiredCollector.UTSC[utsc_num - 1].PlenGapThick)
    var tmp_ts_coll = state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast
    var tmp_ta_plen = state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast
    
    var ts_baffle: Float64
    var ta_gap: Float64
    var hc_plen: Float64
    var hr_plen: Float64
    var isc: Float64
    var mdot_vent: Float64
    var vdot_wind: Float64
    var vdot_thermal: Float64
    
    calc_passive_exterior_baffle_gap(
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
        inout tmp_ts_coll,
        inout tmp_ta_plen,
        inout hc_plen,
        inout hr_plen,
        inout isc,
        inout mdot_vent,
        inout vdot_wind,
        inout vdot_thermal
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
        SecsInHour
    )
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotVent = mdot_vent
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotWind = vdot_wind * rho_air
    state.dataTranspiredCollector.UTSC[utsc_num - 1].PassiveMdotTherm = vdot_thermal * rho_air
    state.dataTranspiredCollector.UTSC[utsc_num - 1].UTSCEfficiency = 0.0


fn update_transpired_collector(state: EnergyPlusData, utsc_num: Int32):
    state.dataTranspiredCollector.UTSC[utsc_num - 1].TplenLast = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tplen
    state.dataTranspiredCollector.UTSC[utsc_num - 1].TcollLast = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll
    
    if state.dataTranspiredCollector.UTSC[utsc_num - 1].IsOn:
        if state.dataTranspiredCollector.UTSC[utsc_num - 1].NumOASysAttached == 1:
            var outlet_node = state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[0]
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
            var outlet_node = state.dataTranspiredCollector.UTSC[utsc_num - 1].OutletNode[i]
            var inlet_node = state.dataTranspiredCollector.UTSC[utsc_num - 1].InletNode[i]
            state.dataLoopNodes.Node[outlet_node].MassFlowRate = state.dataLoopNodes.Node[inlet_node].MassFlowRate
            state.dataLoopNodes.Node[outlet_node].Temp = state.dataLoopNodes.Node[inlet_node].Temp
            state.dataLoopNodes.Node[outlet_node].HumRat = state.dataLoopNodes.Node[inlet_node].HumRat
            state.dataLoopNodes.Node[outlet_node].Enthalpy = state.dataLoopNodes.Node[inlet_node].Enthalpy
    
    var this_oscm = state.dataTranspiredCollector.UTSC[utsc_num - 1].OSCMPtr
    state.dataSurface.OSCM[this_oscm - 1].TConv = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tplen
    state.dataSurface.OSCM[this_oscm - 1].HConv = state.dataTranspiredCollector.UTSC[utsc_num - 1].HcPlen
    state.dataSurface.OSCM[this_oscm - 1].TRad = state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll
    state.dataSurface.OSCM[this_oscm - 1].HRad = state.dataTranspiredCollector.UTSC[utsc_num - 1].HrPlen


fn set_utsc_qdot_source(state: EnergyPlusData, utsc_num: Int32, q_source: Float64):
    state.dataTranspiredCollector.UTSC[utsc_num - 1].QdotSource = (
        q_source / state.dataTranspiredCollector.UTSC[utsc_num - 1].ProjArea
    )


fn get_transpired_collector_index(state: EnergyPlusData, surface_ptr: Int32) -> Int32:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False
    
    if surface_ptr == 0:
        show_fatal_error(state, "Invalid surface passed to GetTranspiredCollectorIndex")
    
    var utsc_num: Int32 = 0
    var found: Bool = False
    
    for this_utsc in range(state.dataTranspiredCollector.NumUTSC):
        for this_surf in range(state.dataTranspiredCollector.UTSC[this_utsc].NumSurfs):
            if surface_ptr == state.dataTranspiredCollector.UTSC[this_utsc].SurfPtrs[this_surf]:
                found = True
                utsc_num = Int32(this_utsc + 1)
    
    if not found:
        show_fatal_error(state, "Did not find surface in UTSC description in GetTranspiredCollectorIndex")
    
    return utsc_num


fn get_utsc_ts_coll(state: EnergyPlusData, utsc_num: Int32) -> Float64:
    return state.dataTranspiredCollector.UTSC[utsc_num - 1].Tcoll


fn get_air_inlet_node_num(state: EnergyPlusData, utsc_name: String, inout errors_found: Bool) -> Int32:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False
    
    var which_utsc = find_item_in_list(utsc_name, state.dataTranspiredCollector.UTSC)
    var node_num: Int32
    
    if which_utsc != 0:
        node_num = state.dataTranspiredCollector.UTSC[which_utsc - 1].InletNode[0]
    else:
        show_severe_error(state, "GetAirInletNodeNum: Could not find TranspiredCollector = \"" + utsc_name + "\"")
        errors_found = True
        node_num = 0
    
    return node_num


fn get_air_outlet_node_num(state: EnergyPlusData, utsc_name: String, inout errors_found: Bool) -> Int32:
    if state.dataTranspiredCollector.GetInputFlag:
        get_transpired_collector_input(state)
        state.dataTranspiredCollector.GetInputFlag = False
    
    var which_utsc = find_item_in_list(utsc_name, state.dataTranspiredCollector.UTSC)
    var node_num: Int32
    
    if which_utsc != 0:
        node_num = state.dataTranspiredCollector.UTSC[which_utsc - 1].OutletNode[0]
    else:
        show_severe_error(state, "GetAirOutletNodeNum: Could not find TranspiredCollector = \"" + utsc_name + "\"")
        errors_found = True
        node_num = 0
    
    return node_num


fn calc_passive_exterior_baffle_gap(
    state: EnergyPlusData,
    surf_ptr_arr: List[Int32],
    vent_area: Float64,
    cv: Float64,
    cd: Float64,
    hdelta_npl: Float64,
    sol_abs: Float64,
    abs_ext: Float64,
    tilt: Float64,
    asp_rat: Float64,
    gap_thick: Float64,
    roughness: Int32,
    qdot_source: Float64,
    inout ts_baffle: Float64,
    inout ta_gap: Float64,
    inout hc_gap_rpt: Float64,
    inout hr_gap_rpt: Float64,
    inout isc_rpt: Float64,
    inout mdot_vent_rpt: Float64,
    inout vdot_wind_rpt: Float64,
    inout vdot_buoy_rpt: Float64
):
    var sum_area: Float64 = 0.0
    var sum_produc_area_drybulb: Float64 = 0.0
    var sum_produc_area_wetbulb: Float64 = 0.0
    
    for i in surf_ptr_arr:
        sum_area += state.dataSurface.Surface[i].Area
        sum_produc_area_drybulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutDryBulbTemp[i]
        sum_produc_area_wetbulb += state.dataSurface.Surface[i].Area * state.dataSurface.SurfOutWetBulbTemp[i]
    
    var local_out_drybulb_temp = sum_produc_area_drybulb / sum_area
    var local_wetbulb_temp = sum_produc_area_wetbulb / sum_area
    
    var local_out_hum_rat = state.dataEnvrn.get_humidity_ratio(local_out_drybulb_temp, local_wetbulb_temp)
    var rho_air = state.dataEnvrn.get_rho_air(local_out_drybulb_temp, local_out_hum_rat)
    var cp_air = state.dataEnvrn.get_cp_air(local_out_hum_rat)
    
    var tamb: Float64
    if not state.dataEnvrn.IsRain:
        tamb = local_out_drybulb_temp
    else:
        tamb = local_wetbulb_temp
    
    var a = sum_area
    var tmp_ts_baf = ts_baffle
    
    var num_surfs = Int32(len(surf_ptr_arr))
    
    var vwind = state.dataEnvrn.WindSpeed
    var gr = (GravitationalConstant * pow(gap_thick, 3.0) * abs(0.0 - tmp_ts_baf) * 
             pow(rho_air, 2.0) / ((273.15 + 0.5 * (tmp_ts_baf + 0.0)) * pow(KinematicViscosity, 2.0)))
    
    var nu_plen = passive_gap_nusselt_number(asp_rat, tilt, tmp_ts_baf, 0.0, gr)
    var hc_plen = nu_plen * (ThermalConductivity / gap_thick)
    
    var vdot_wind = cv * (vent_area / 2.0) * vwind
    
    var vdot_thermal: Float64
    if ta_gap > tamb:
        vdot_thermal = cd * (vent_area / 2.0) * sqrt(
            2.0 * GravitationalConstant * hdelta_npl * (ta_gap - tamb) / (ta_gap + 273.15)
        )
    elif ta_gap == tamb:
        vdot_thermal = 0.0
    else:
        if (abs(tilt) < 5.0) or (abs(tilt - 180.0) < 5.0):
            vdot_thermal = 0.0
        else:
            vdot_thermal = cd * (vent_area / 2.0) * sqrt(
                2.0 * GravitationalConstant * hdelta_npl * (tamb - ta_gap) / (tamb + 273.15)
            )
    
    var vdot_vent = vdot_wind + vdot_thermal
    var mdot_vent = vdot_vent * rho_air
    
    ts_baffle = (sol_abs * 0.0 + abs_ext * tamb + hc_plen * ta_gap + qdot_source) / (abs_ext + hc_plen)
    ta_gap = (hc_plen * a * 0.0 + mdot_vent * cp_air * tamb + hc_plen * a * ts_baffle) / (
        hc_plen * a + mdot_vent * cp_air + hc_plen * a
    )
    
    hc_gap_rpt = hc_plen
    hr_gap_rpt = 0.0
    isc_rpt = 0.0
    mdot_vent_rpt = mdot_vent
    vdot_wind_rpt = vdot_wind
    vdot_buoy_rpt = vdot_thermal


fn passive_gap_nusselt_number(asp_rat: Float64, tilt: Float64, tso: Float64, tsi: Float64, gr: Float64) -> Float64:
    var tiltr = tilt * pi / 180.0
    var ra = gr * PrandtlNumber
    
    var gnu901: Float64
    if ra <= 1.0e4:
        gnu901 = 1.0 + 1.7596678e-10 * pow(ra, 2.2984755)
    elif ra <= 5.0e4:
        gnu901 = 0.028154 * pow(ra, 0.4134)
    else:
        gnu901 = 0.0673838 * pow(ra, 1.0 / 3.0)
    
    var gnu902 = 0.242 * pow(ra / asp_rat, 0.272)
    var gnu90 = max(gnu901, gnu902)
    
    if tso > tsi:
        return 1.0 + (gnu90 - 1.0) * sin(tiltr)
    
    if tilt >= 60.0:
        var g = 0.5 * pow(1.0 + pow(ra / 3160.0, 20.6), -0.1)
        var gnu601a = 1.0 + pow(0.0936 * pow(ra, 0.314) / (1.0 + g), 1.0 / 7.0)
        var gnu601 = pow(gnu601a, 0.142857)
        
        var gnu602 = (0.104 + 0.175 / asp_rat) * pow(ra, 0.283)
        var gnu60 = max(gnu601, gnu602)
        
        return ((90.0 - tilt) * gnu60 + (tilt - 60.0) * gnu90) / 30.0
    
    var cra = ra * cos(tiltr)
    var a_coeff = 1.0 - 1708.0 / cra
    var b_coeff = pow(cra / 5830.0, 1.0 / 3.0) - 1.0
    var gnua = (abs(a_coeff) + a_coeff) / 2.0
    var gnub = (abs(b_coeff) + b_coeff) / 2.0
    var ang = 1708.0 * pow(sin(1.8 * tiltr), 1.6)
    
    return 1.0 + 1.44 * gnua * (1.0 - ang / cra) + gnub


fn find_item_in_list(name: String, items: List[UTSCDataStruct]) -> Int32:
    for i in range(len(items)):
        if items[i].Name == name:
            return Int32(i + 1)
    return 0


fn show_fatal_error(state: EnergyPlusData, message: String):
    print("FATAL ERROR: " + message)


fn show_severe_error(state: EnergyPlusData, message: String):
    print("SEVERE ERROR: " + message)


fn get_schedule_always_on(state: EnergyPlusData) -> Pointer[Object]:
    return Pointer[Object]()


fn get_schedule(state: EnergyPlusData, name: String) -> Pointer[Object]:
    return Pointer[Object]()

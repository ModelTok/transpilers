from collections import InlineArray
from math import exp, min

alias SolutionAlgo_AnalyticalSolution = 1
alias SolutionAlgo_EulerMethod = 2
alias SolutionAlgo_ThirdOrder = 3

alias ZoneEquipType_BaseboardWater = 1
alias ZoneEquipType_BaseboardSteam = 2
alias ZoneEquipType_BaseboardConvectiveWater = 3
alias ZoneEquipType_BaseboardConvectiveElectric = 4
alias ZoneEquipType_BaseboardElectric = 5
alias ZoneEquipType_RefrigerationChillerSet = 6
alias ZoneEquipType_HighTemperatureRadiant = 7
alias ZoneEquipType_DehumidifierDX = 8
alias ZoneEquipType_AirDistributionUnit = 9

alias HeatTransferModel_HAMT = 1
alias HeatTransferModel_EMPD = 2

alias RefAirTemp_ZoneMeanAirTemp = 1
alias RefAirTemp_AdjacentAirTemp = 2
alias RefAirTemp_ZoneSupplyAirTemp = 3

alias SurfaceClass_Window = 1

struct AFNHVACInfo:
    var Name: String
    var SupplyNodeName: String
    var ReturnNodeName: String
    var SupNodeNum: Int32
    var RetNodeNum: Int32
    var SupplyFraction: Float64
    var ReturnFraction: Float64
    var EquipConfigIndex: Int32
    var zoneEquipType: Int32
    var CompIndex: Int32
    var TempIn: Float64
    var HumRatIn: Float64
    var MdotIn: Float64
    
    fn __init__(inout self):
        self.Name = String("")
        self.SupplyNodeName = String("")
        self.ReturnNodeName = String("")
        self.SupNodeNum = 0
        self.RetNodeNum = 0
        self.SupplyFraction = 0.0
        self.ReturnFraction = 0.0
        self.EquipConfigIndex = 0
        self.zoneEquipType = ZoneEquipType_BaseboardWater
        self.CompIndex = 0
        self.TempIn = 0.0
        self.HumRatIn = 0.0
        self.MdotIn = 0.0

struct AFNLink:
    var AFNSimuID: Int32
    var TempIn: Float64
    var HumRatIn: Float64
    var MdotIn: Float64
    
    fn __init__(inout self):
        self.AFNSimuID = 0
        self.TempIn = 0.0
        self.HumRatIn = 0.0
        self.MdotIn = 0.0

struct AFNNode:
    var Name: String
    var ZoneVolumeFraction: Float64
    var AirVolume: Float64
    var AFNNodeID: Int32
    var NumOfAirflowLinks: Int32
    var Link: DynamicVector[AFNLink]
    var HVAC: DynamicVector[AFNHVACInfo]
    var NumIntGains: Int32
    var intGainsDeviceSpaces: DynamicVector[Int32]
    var IntGainsDeviceIndices: DynamicVector[Int32]
    var IntGainsFractions: DynamicVector[Float64]
    var HasSurfacesAssigned: Bool
    var SurfMask: DynamicVector[Bool]
    
    var AirTemp: Float64
    var AirTempX: InlineArray[Float64, 4]
    var AirTempDSX: InlineArray[Float64, 4]
    var AirTempT1: Float64
    var AirTempTX: Float64
    var AirTempT2: Float64
    
    var HumRat: Float64
    var HumRatX: InlineArray[Float64, 4]
    var HumRatDSX: InlineArray[Float64, 4]
    var HumRatT1: Float64
    var HumRatTX: Float64
    var HumRatT2: Float64
    
    var SysDepZoneLoadsLagged: Float64
    var SysDepZoneLoadsLaggedOld: Float64
    var NonAirSystemResponse: Float64
    var SumIntSensibleGain: Float64
    var SumIntLatentGain: Float64
    
    var SumHA: Float64
    var SumHATsurf: Float64
    var SumHATref: Float64
    var SumSysMCp: Float64
    var SumSysMCpT: Float64
    var SumSysM: Float64
    var SumSysMW: Float64
    
    var SumLinkMCp: Float64
    var SumLinkMCpT: Float64
    var SumLinkM: Float64
    var SumLinkMW: Float64
    
    var RhoAir: Float64
    var CpAir: Float64
    var AirCap: Float64
    var AirHumRat: Float64
    var RelHumidity: Float64
    
    var SumHmAW: Float64
    var SumHmARa: Float64
    var SumHmARaW: Float64
    
    fn __init__(inout self):
        self.Name = String("")
        self.ZoneVolumeFraction = 0.0
        self.AirVolume = 0.0
        self.AFNNodeID = 0
        self.NumOfAirflowLinks = 0
        self.Link = DynamicVector[AFNLink]()
        self.HVAC = DynamicVector[AFNHVACInfo]()
        self.NumIntGains = 0
        self.intGainsDeviceSpaces = DynamicVector[Int32]()
        self.IntGainsDeviceIndices = DynamicVector[Int32]()
        self.IntGainsFractions = DynamicVector[Float64]()
        self.HasSurfacesAssigned = False
        self.SurfMask = DynamicVector[Bool]()
        self.AirTemp = 23.0
        self.AirTempX = InlineArray[Float64, 4](fill=23.0)
        self.AirTempDSX = InlineArray[Float64, 4](fill=23.0)
        self.AirTempT1 = 23.0
        self.AirTempTX = 23.0
        self.AirTempT2 = 23.0
        self.HumRat = 0.0
        self.HumRatX = InlineArray[Float64, 4](fill=0.0)
        self.HumRatDSX = InlineArray[Float64, 4](fill=0.0)
        self.HumRatT1 = 0.0
        self.HumRatTX = 0.0
        self.HumRatT2 = 0.0
        self.SysDepZoneLoadsLagged = 0.0
        self.SysDepZoneLoadsLaggedOld = 0.0
        self.NonAirSystemResponse = 0.0
        self.SumIntSensibleGain = 0.0
        self.SumIntLatentGain = 0.0
        self.SumHA = 0.0
        self.SumHATsurf = 0.0
        self.SumHATref = 0.0
        self.SumSysMCp = 0.0
        self.SumSysMCpT = 0.0
        self.SumSysM = 0.0
        self.SumSysMW = 0.0
        self.SumLinkMCp = 0.0
        self.SumLinkMCpT = 0.0
        self.SumLinkM = 0.0
        self.SumLinkMW = 0.0
        self.RhoAir = 0.0
        self.CpAir = 0.0
        self.AirCap = 0.0
        self.AirHumRat = 0.0
        self.RelHumidity = 0.0
        self.SumHmAW = 0.0
        self.SumHmARa = 0.0
        self.SumHmARaW = 0.0

struct AFNZoneInfo:
    var Name: String
    var IsUsed: Bool
    var ActualZoneID: Int32
    var NumOfAirNodes: Int32
    var Node: DynamicVector[AFNNode]
    var ControlAirNodeID: Int32
    
    fn __init__(inout self):
        self.Name = String("")
        self.IsUsed = False
        self.ActualZoneID = 0
        self.NumOfAirNodes = 0
        self.Node = DynamicVector[AFNNode]()
        self.ControlAirNodeID = 0

struct RoomAirModelAirflowNetworkData:
    var OneTimeFlag: Bool
    var OneTimeFlagConf: Bool
    var EnvrnFlag: Bool
    
    fn __init__(inout self):
        self.OneTimeFlag = True
        self.OneTimeFlagConf = True
        self.EnvrnFlag = True

fn sim_room_air_model_afn(inout state: AnyType, zone_num: Int32) -> None:
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    
    for room_air_node_num in range(1, afn_zone_info.NumOfAirNodes + 1):
        init_room_air_model_afn(state, zone_num, room_air_node_num)
        calc_room_air_model_afn(state, zone_num, room_air_node_num)
    
    update_room_air_model_afn(state, zone_num)

fn load_prediction_room_air_model_afn(inout state: AnyType, zone_num: Int32, room_air_node_num: Int32) -> None:
    init_room_air_model_afn(state, zone_num, room_air_node_num)

fn init_room_air_model_afn(inout state: AnyType, zone_num: Int32, room_air_node_num: Int32) -> None:
    if state.dataRoomAirflowNetModel.OneTimeFlag:
        for i_zone in range(1, state.dataGlobal.NumOfZones + 1):
            var afn_zone_info = state.dataRoomAir.AFNZoneInfo[i_zone - 1]
            if not afn_zone_info.IsUsed:
                continue
            
            for j in range(afn_zone_info.Node.size()):
                var afn_node = afn_zone_info.Node[j]
                afn_node.AirVolume = state.dataHeatBal.Zone[i_zone - 1].Volume * afn_node.ZoneVolumeFraction
                
                state.SetupOutputVariable("RoomAirflowNetwork Node NonAirSystemResponse", afn_node.NonAirSystemResponse, afn_node.Name)
                state.SetupOutputVariable("RoomAirflowNetwork Node SysDepZoneLoadsLagged", afn_node.SysDepZoneLoadsLagged, afn_node.Name)
                state.SetupOutputVariable("RoomAirflowNetwork Node SumIntSensibleGain", afn_node.SumIntSensibleGain, afn_node.Name)
                state.SetupOutputVariable("RoomAirflowNetwork Node SumIntLatentGain", afn_node.SumIntLatentGain, afn_node.Name)
        
        state.dataRoomAirflowNetModel.OneTimeFlag = False
    
    if state.dataRoomAirflowNetModel.OneTimeFlagConf:
        if hasattr(state.dataZoneEquip, 'ZoneEquipConfig'):
            var max_node_num: Int32 = 0
            var max_equip_num: Int32 = 0
            var errors_found: Bool = False
            
            for i_zone in range(1, state.dataGlobal.NumOfZones + 1):
                if not state.dataHeatBal.Zone[i_zone - 1].IsControlled:
                    continue
                max_equip_num = max(max_equip_num, state.dataZoneEquip.ZoneEquipList[i_zone - 1].NumOfEquipTypes)
                max_node_num = max(max_node_num, state.dataZoneEquip.ZoneEquipConfig[i_zone - 1].NumInletNodes)
            
            var node_found = DynamicVector[Bool]()
            var equip_found = DynamicVector[Bool]()
            var supply_frac = DynamicVector[Float64]()
            var return_frac = DynamicVector[Float64]()
            
            for _ in range(max_node_num + 1):
                node_found.push_back(False)
            for _ in range(max_equip_num + 1):
                equip_found.push_back(False)
                supply_frac.push_back(0.0)
                return_frac.push_back(0.0)
            
            for i_zone in range(1, state.dataGlobal.NumOfZones + 1):
                var zone = state.dataHeatBal.Zone[i_zone - 1]
                if not zone.IsControlled:
                    continue
                
                var afn_zone_info = state.dataRoomAir.AFNZoneInfo[i_zone - 1]
                if not afn_zone_info.IsUsed:
                    continue
                
                afn_zone_info.ActualZoneID = i_zone
                for k in range(supply_frac.size()):
                    supply_frac[k] = 0.0
                    return_frac[k] = 0.0
                for k in range(node_found.size()):
                    node_found[k] = False
                
                var num_air_dist_units: Int32 = 0
                var zone_equip_list = state.dataZoneEquip.ZoneEquipList[i_zone - 1]
                var zone_equip_config = state.dataZoneEquip.ZoneEquipConfig[i_zone - 1]
                
                for node_idx in range(afn_zone_info.Node.size()):
                    var afn_node = afn_zone_info.Node[node_idx]
                    for hvac_idx in range(afn_node.HVAC.size()):
                        var afn_hvac = afn_node.HVAC[hvac_idx]
                        for i in range(1, zone_equip_list.NumOfEquipTypes + 1):
                            if zone_equip_list.EquipType[i - 1] == ZoneEquipType_AirDistributionUnit:
                                if num_air_dist_units == 0:
                                    num_air_dist_units = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneHVAC:AirDistributionUnit")
                                
                                if state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag:
                                    state.dataZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(state)
                                    state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
                                
                                for air_dist_unit_num in range(1, num_air_dist_units + 1):
                                    if zone_equip_list.EquipName[i - 1] == state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1].Name:
                                        if afn_hvac.Name == state.dataDefineEquipment.AirDistUnit[air_dist_unit_num - 1].EquipName[0]:
                                            if afn_hvac.EquipConfigIndex == 0:
                                                afn_hvac.EquipConfigIndex = i
                                            equip_found[i - 1] = True
                                            supply_frac[i - 1] += afn_hvac.SupplyFraction
                                            return_frac[i - 1] += afn_hvac.ReturnFraction
                            elif state.SameString(zone_equip_list.EquipName[i - 1], afn_hvac.Name):
                                if afn_hvac.EquipConfigIndex == 0:
                                    afn_hvac.EquipConfigIndex = i
                                equip_found[i - 1] = True
                                supply_frac[i - 1] += afn_hvac.SupplyFraction
                                return_frac[i - 1] += afn_hvac.ReturnFraction
                        
                        for i_node in range(1, state.dataLoopNodes.NumOfNodes + 1):
                            if state.SameString(state.dataLoopNodes.NodeID[i_node - 1], afn_hvac.SupplyNodeName):
                                afn_hvac.SupNodeNum = i_node
                                break
                        
                        var inlet_node_index: Int32 = 0
                        for i_node in range(1, zone_equip_config.NumInletNodes + 1):
                            if zone_equip_config.InletNode[i_node - 1] == afn_hvac.SupNodeNum:
                                node_found[i_node - 1] = True
                                inlet_node_index = i_node
                                break
                        
                        if afn_hvac.SupNodeNum > 0 and afn_hvac.ReturnNodeName == "":
                            for ret_node in range(1, zone_equip_config.NumReturnNodes + 1):
                                if (zone_equip_config.ReturnNodeInletNum[ret_node - 1] == inlet_node_index and
                                    zone_equip_config.ReturnNode[ret_node - 1] > 0):
                                    afn_hvac.RetNodeNum = zone_equip_config.ReturnNode[ret_node - 1]
                                    break
                        
                        if afn_hvac.RetNodeNum == 0:
                            for i_node in range(1, state.dataLoopNodes.NumOfNodes + 1):
                                if state.SameString(state.dataLoopNodes.NodeID[i_node - 1], afn_hvac.ReturnNodeName):
                                    afn_hvac.RetNodeNum = i_node
                                    break
                        
                        state.SetupOutputVariable("RoomAirflowNetwork Node HVAC Supply Fraction", afn_hvac.SupplyFraction, afn_hvac.Name)
                        state.SetupOutputVariable("RoomAirflowNetwork Node HVAC Return Fraction", afn_hvac.ReturnFraction, afn_hvac.Name)
                
                var i_sum: Int32 = 0
                for i_node in range(1, max_node_num + 1):
                    if i_node - 1 < node_found.size() and node_found[i_node - 1]:
                        i_sum += 1
                
                if i_sum != zone_equip_config.NumInletNodes:
                    if i_sum > zone_equip_config.NumInletNodes:
                        state.ShowSevereError(state, "GetRoomAirflowNetworkData: The number of equipment listed in RoomAirflowNetwork:Node:HVACEquipment objects")
                        state.ShowContinueError(state, "is greater than the number of zone configuration inlet nodes in " + zone.Name)
                        state.ShowContinueError(state, "Please check inputs of both objects.")
                        errors_found = True
                    else:
                        state.ShowSevereError(state, "GetRoomAirflowNetworkData: The number of equipment listed in RoomAirflowNetwork:Node:HVACEquipment objects")
                        state.ShowContinueError(state, "is less than the number of zone configuration inlet nodes in " + zone.Name)
                        state.ShowContinueError(state, "Please check inputs of both objects.")
                        errors_found = True
                
                for i in range(1, zone_equip_list.NumOfEquipTypes + 1):
                    if not equip_found[i - 1]:
                        state.ShowSevereError(state, "GetRoomAirflowNetworkData: The equipment listed in ZoneEquipList is not found")
                        state.ShowContinueError(state, zone_equip_list.EquipName[i - 1])
                        errors_found = True
                
                for i in range(1, zone_equip_list.NumOfEquipTypes + 1):
                    if abs(supply_frac[i - 1] - 1.0) > 0.001:
                        state.ShowSevereError(state, "GetRoomAirflowNetworkData: Invalid, zone supply fractions do not sum to 1.0")
                        errors_found = True
                    if abs(return_frac[i - 1] - 1.0) > 0.001:
                        state.ShowSevereError(state, "GetRoomAirflowNetworkData: Invalid, zone return fractions do not sum to 1.0")
                        errors_found = True
            
            state.dataRoomAirflowNetModel.OneTimeFlagConf = False
            
            if errors_found:
                state.ShowFatalError(state, "GetRoomAirflowNetworkData: Errors found getting air model input.")
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataRoomAirflowNetModel.EnvrnFlag:
        for i_zone in range(1, state.dataGlobal.NumOfZones + 1):
            var afn_zone_info = state.dataRoomAir.AFNZoneInfo[i_zone - 1]
            if not afn_zone_info.IsUsed:
                continue
            
            for j in range(afn_zone_info.Node.size()):
                var afn_node = afn_zone_info.Node[j]
                afn_node.AirTemp = 23.0
                afn_node.AirTempX = InlineArray[Float64, 4](fill=23.0)
                afn_node.AirTempDSX = InlineArray[Float64, 4](fill=23.0)
                afn_node.AirTempT1 = 23.0
                afn_node.AirTempTX = 23.0
                afn_node.AirTempT2 = 23.0
                
                afn_node.HumRat = 0.0
                afn_node.HumRatX = InlineArray[Float64, 4](fill=0.0)
                afn_node.HumRatDSX = InlineArray[Float64, 4](fill=0.0)
                afn_node.HumRatT1 = 0.0
                afn_node.HumRatTX = 0.0
                afn_node.HumRatT2 = 0.0
                
                afn_node.SysDepZoneLoadsLagged = 0.0
                afn_node.SysDepZoneLoadsLaggedOld = 0.0
        
        state.dataRoomAirflowNetModel.EnvrnFlag = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataRoomAirflowNetModel.EnvrnFlag = True
    
    calc_node_sums(state, zone_num, room_air_node_num)
    sum_non_air_system_response_for_node(state, zone_num, room_air_node_num)
    
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    var afn_node = afn_zone_info.Node[room_air_node_num - 1]
    
    if afn_node.SurfMask.size() > 0:
        calc_surface_moisture_sums(state, zone_num, room_air_node_num, afn_node)
    
    var sum_link_m_cp: Float64 = 0.0
    var sum_link_m_cp_t: Float64 = 0.0
    var sum_link_m: Float64 = 0.0
    var sum_link_m_w: Float64 = 0.0
    
    if afn_node.AFNNodeID > 0:
        for i_link in range(1, afn_node.NumOfAirflowLinks + 1):
            var afn_link = afn_node.Link[i_link - 1]
            var link_num = afn_link.AFNSimuID
            
            if state.afn.AirflowNetworkLinkageData[link_num - 1].NodeNums[0] == afn_node.AFNNodeID:
                var node_in_num = state.afn.AirflowNetworkLinkageData[link_num - 1].NodeNums[1]
                afn_link.TempIn = state.afn.AirflowNetworkNodeSimu[node_in_num - 1].TZ
                afn_link.HumRatIn = state.afn.AirflowNetworkNodeSimu[node_in_num - 1].WZ
                afn_link.MdotIn = state.afn.AirflowNetworkLinkSimu[link_num - 1].FLOW2
            
            if state.afn.AirflowNetworkLinkageData[link_num - 1].NodeNums[1] == afn_node.AFNNodeID:
                var node_in_num = state.afn.AirflowNetworkLinkageData[link_num - 1].NodeNums[0]
                afn_link.TempIn = state.afn.AirflowNetworkNodeSimu[node_in_num - 1].TZ
                afn_link.HumRatIn = state.afn.AirflowNetworkNodeSimu[node_in_num - 1].WZ
                afn_link.MdotIn = state.afn.AirflowNetworkLinkSimu[link_num - 1].FLOW
        
        for i_link in range(1, afn_node.NumOfAirflowLinks + 1):
            var afn_link = afn_node.Link[i_link - 1]
            var cp_air = state.PsyCpAirFnW(afn_link.HumRatIn)
            sum_link_m_cp += cp_air * afn_link.MdotIn
            sum_link_m_cp_t += cp_air * afn_link.MdotIn * afn_link.TempIn
            sum_link_m += afn_link.MdotIn
            sum_link_m_w += afn_link.MdotIn * afn_link.HumRatIn
    
    afn_node.SumLinkMCp = sum_link_m_cp
    afn_node.SumLinkMCpT = sum_link_m_cp_t
    afn_node.SumLinkM = sum_link_m
    afn_node.SumLinkMW = sum_link_m_w
    afn_node.SysDepZoneLoadsLagged = afn_node.SysDepZoneLoadsLaggedOld
    
    afn_node.RhoAir = state.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, afn_node.AirTemp, afn_node.HumRat, "InitRoomAirModelAirflowNetwork")
    afn_node.CpAir = state.PsyCpAirFnW(afn_node.HumRat)

fn calc_room_air_model_afn(inout state: AnyType, zone_num: Int32, room_air_node_num: Int32) -> None:
    var time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
    
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    var afn_node = afn_zone_info.Node[room_air_node_num - 1]
    
    var node_temp_x: InlineArray[Float64, 3]
    var node_hum_rat_x: InlineArray[Float64, 3]
    
    if state.dataHVACGlobal.UseZoneTimeStepHistory:
        node_temp_x[0] = afn_node.AirTempX[0]
        node_temp_x[1] = afn_node.AirTempX[1]
        node_temp_x[2] = afn_node.AirTempX[2]
        node_hum_rat_x[0] = afn_node.HumRatX[0]
        node_hum_rat_x[1] = afn_node.HumRatX[1]
        node_hum_rat_x[2] = afn_node.HumRatX[2]
    else:
        node_temp_x[0] = afn_node.AirTempDSX[0]
        node_temp_x[1] = afn_node.AirTempDSX[1]
        node_temp_x[2] = afn_node.AirTempDSX[2]
        node_hum_rat_x[0] = afn_node.HumRatDSX[0]
        node_hum_rat_x[1] = afn_node.HumRatDSX[1]
        node_hum_rat_x[2] = afn_node.HumRatDSX[2]
    
    var air_temp_t1: Float64 = 0.0
    var hum_rat_t1: Float64 = 0.0
    if state.dataHeatBal.ZoneAirSolutionAlgo != SolutionAlgo_ThirdOrder:
        air_temp_t1 = afn_node.AirTempT1
        hum_rat_t1 = afn_node.HumRatT1
    
    var temp_dep_coef = afn_node.SumHA + afn_node.SumLinkMCp + afn_node.SumSysMCp
    var temp_ind_coef = (afn_node.SumIntSensibleGain + afn_node.SumHATsurf - afn_node.SumHATref + afn_node.SumLinkMCpT + afn_node.SumSysMCpT +
                         afn_node.NonAirSystemResponse + afn_node.SysDepZoneLoadsLagged)
    var air_cap = (afn_node.AirVolume * state.dataHeatBal.Zone[zone_num - 1].ZoneVolCapMultpSens * afn_node.RhoAir * afn_node.CpAir / time_step_sys_sec)
    
    if state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo_AnalyticalSolution:
        if temp_dep_coef == 0.0:
            afn_node.AirTemp = air_temp_t1 + temp_ind_coef / air_cap
        else:
            afn_node.AirTemp = ((air_temp_t1 - temp_ind_coef / temp_dep_coef) * exp(min(700.0, -temp_dep_coef / air_cap)) +
                                temp_ind_coef / temp_dep_coef)
    elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo_EulerMethod:
        afn_node.AirTemp = (air_cap * air_temp_t1 + temp_ind_coef) / (air_cap + temp_dep_coef)
    else:
        afn_node.AirTemp = ((temp_ind_coef + air_cap * (3.0 * node_temp_x[0] - (3.0 / 2.0) * node_temp_x[1] + (1.0 / 3.0) * node_temp_x[2])) /
                            ((11.0 / 6.0) * air_cap + temp_dep_coef))
    
    var h2o_ht_of_vap = state.PsyHgAirFnWTdb(afn_node.HumRat, afn_node.AirTemp)
    var a = afn_node.SumLinkM + afn_node.SumHmARa + afn_node.SumSysM
    var b = (afn_node.SumIntLatentGain / h2o_ht_of_vap) + afn_node.SumSysMW + afn_node.SumLinkMW + afn_node.SumHmARaW
    var c = afn_node.RhoAir * afn_node.AirVolume * state.dataHeatBal.Zone[zone_num - 1].ZoneVolCapMultpMoist / time_step_sys_sec
    
    if state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo_AnalyticalSolution:
        if a == 0.0:
            afn_node.HumRat = hum_rat_t1 + b / c
        else:
            afn_node.HumRat = (hum_rat_t1 - b / a) * exp(min(700.0, -a / c)) + b / a
    elif state.dataHeatBal.ZoneAirSolutionAlgo == SolutionAlgo_EulerMethod:
        afn_node.HumRat = (c * hum_rat_t1 + b) / (c + a)
    else:
        afn_node.HumRat = ((b + c * (3.0 * node_hum_rat_x[0] - (3.0 / 2.0) * node_hum_rat_x[1] + (1.0 / 3.0) * node_hum_rat_x[2])) /
                           ((11.0 / 6.0) * c + a))
    
    afn_node.AirCap = air_cap
    afn_node.AirHumRat = c
    afn_node.RelHumidity = state.PsyRhFnTdbWPb(state, afn_node.AirTemp, afn_node.HumRat, state.dataEnvrn.OutBaroPress, "CalcRoomAirModelAirflowNetwork") * 100.0

fn update_room_air_model_afn(inout state: AnyType, zone_num: Int32) -> None:
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    
    if not afn_zone_info.IsUsed:
        return
    
    if not state.dataGlobal.ZoneSizingCalc:
        sum_system_dep_response_for_node(state, zone_num)
    
    for i in range(1, state.dataZoneEquip.ZoneEquipList[zone_num - 1].NumOfEquipTypes + 1):
        var sum_mass: Float64 = 0.0
        var sum_mass_t: Float64 = 0.0
        var sum_mass_w: Float64 = 0.0
        var ret_node_num: Int32 = 0
        
        for node_idx in range(afn_zone_info.Node.size()):
            var afn_node = afn_zone_info.Node[node_idx]
            for hvac_idx in range(afn_node.HVAC.size()):
                var afn_hvac = afn_node.HVAC[hvac_idx]
                if afn_hvac.EquipConfigIndex == i and afn_hvac.SupNodeNum > 0 and afn_hvac.RetNodeNum > 0:
                    var node_mass = state.dataLoopNodes.Node[afn_hvac.SupNodeNum - 1].MassFlowRate * afn_hvac.ReturnFraction
                    sum_mass += node_mass
                    sum_mass_t += node_mass * afn_node.AirTemp
                    sum_mass_w += node_mass * afn_node.HumRat
                    ret_node_num = afn_hvac.RetNodeNum
        
        if sum_mass > 0.0:
            state.dataLoopNodes.Node[ret_node_num - 1].Temp = sum_mass_t / sum_mass
            state.dataLoopNodes.Node[ret_node_num - 1].HumRat = sum_mass_w / sum_mass

fn calc_node_sums(inout state: AnyType, zone_num: Int32, room_air_node_num: Int32) -> None:
    var zone = state.dataHeatBal.Zone[zone_num - 1]
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    var afn_node = afn_zone_info.Node[room_air_node_num - 1]
    
    afn_node.SumIntSensibleGain = state.SumInternalConvectionGainsByIndices(state, afn_node.NumIntGains, afn_node.intGainsDeviceSpaces, afn_node.IntGainsDeviceIndices, afn_node.IntGainsFractions)
    afn_node.SumIntLatentGain = state.SumInternalLatentGainsByIndices(state, afn_node.NumIntGains, afn_node.intGainsDeviceSpaces, afn_node.IntGainsDeviceIndices, afn_node.IntGainsFractions)
    
    if zone.NoHeatToReturnAir:
        var sum_int_gain = state.SumReturnAirConvectionGainsByIndices(state, afn_node.NumIntGains, afn_node.intGainsDeviceSpaces, afn_node.IntGainsDeviceIndices, afn_node.IntGainsFractions)
        afn_node.SumIntSensibleGain += sum_int_gain
    
    var zone_ret_plenum_num: Int32 = 0
    for i_plenum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
        if state.dataZonePlenum.ZoneRetPlenCond[i_plenum - 1].ActualZoneNum == zone_num:
            zone_ret_plenum_num = i_plenum
            break
    
    var zone_sup_plenum_num: Int32 = 0
    for i_plenum in range(1, state.dataZonePlenum.NumZoneSupplyPlenums + 1):
        if state.dataZonePlenum.ZoneSupPlenCond[i_plenum - 1].ActualZoneNum == zone_num:
            zone_sup_plenum_num = i_plenum
            break
    
    var sum_sys_m_cp: Float64 = 0.0
    var sum_sys_m_cp_t: Float64 = 0.0
    var sum_sys_m: Float64 = 0.0
    var sum_sys_m_w: Float64 = 0.0
    var zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1]
    
    if zone.IsControlled:
        var zone_equip_config = state.dataZoneEquip.ZoneEquipConfig[zone_num - 1]
        for i_node in range(1, zone_equip_config.NumInletNodes + 1):
            var inlet_node = state.dataLoopNodes.Node[zone_equip_config.InletNode[i_node - 1] - 1]
            for hvac_idx in range(afn_node.HVAC.size()):
                var afn_hvac = afn_node.HVAC[hvac_idx]
                if afn_hvac.SupNodeNum == zone_equip_config.InletNode[i_node - 1]:
                    var mass_flow_rate = inlet_node.MassFlowRate * afn_hvac.SupplyFraction
                    var cp_air = state.PsyCpAirFnW(zone_hb.airHumRat)
                    sum_sys_m_cp += mass_flow_rate * cp_air
                    sum_sys_m_cp_t += mass_flow_rate * cp_air * inlet_node.Temp
                    sum_sys_m += mass_flow_rate
                    sum_sys_m_w += mass_flow_rate * inlet_node.HumRat
    elif zone_ret_plenum_num != 0:
        var zone_ret_plenum = state.dataZonePlenum.ZoneRetPlenCond[zone_ret_plenum_num - 1]
        for i_node in range(1, zone_ret_plenum.NumInletNodes + 1):
            var zone_ret_plenum_node = state.dataLoopNodes.Node[zone_ret_plenum.InletNode[i_node - 1] - 1]
            var cp_air = state.PsyCpAirFnW(zone_hb.airHumRat)
            sum_sys_m_cp += zone_ret_plenum_node.MassFlowRate * cp_air
            sum_sys_m_cp_t += zone_ret_plenum_node.MassFlowRate * cp_air * zone_ret_plenum_node.Temp
        
        for i_adu in range(1, zone_ret_plenum.NumADUs + 1):
            var adu_num = zone_ret_plenum.ADUIndex[i_adu - 1]
            var adu = state.dataDefineEquipment.AirDistUnit[adu_num - 1]
            
            if adu.UpStreamLeak:
                var cp_air = state.PsyCpAirFnW(zone_hb.airHumRat)
                sum_sys_m_cp += adu.MassFlowRateUpStrLk * cp_air
                sum_sys_m_cp_t += adu.MassFlowRateUpStrLk * cp_air * state.dataLoopNodes.Node[adu.InletNodeNum - 1].Temp
            
            if adu.DownStreamLeak:
                var cp_air = state.PsyCpAirFnW(zone_hb.airHumRat)
                sum_sys_m_cp += adu.MassFlowRateDnStrLk * cp_air
                sum_sys_m_cp_t += adu.MassFlowRateDnStrLk * cp_air * state.dataLoopNodes.Node[adu.OutletNodeNum - 1].Temp
    elif zone_sup_plenum_num != 0:
        var zone_sup_plenum = state.dataZonePlenum.ZoneSupPlenCond[zone_sup_plenum_num - 1]
        var inlet_node = state.dataLoopNodes.Node[zone_sup_plenum.InletNode - 1]
        var cp_air = state.PsyCpAirFnW(zone_hb.airHumRat)
        sum_sys_m_cp += inlet_node.MassFlowRate * cp_air
        sum_sys_m_cp_t += inlet_node.MassFlowRate * cp_air * inlet_node.Temp
    
    if zone.leakageParallelPIUNums.size() > 0:
        var cp_air = state.PsyCpAirFnW(zone_hb.airHumRat)
        for piu_num in range(1, zone.leakageParallelPIUNums.size() + 1):
            var this_piu = state.dataPowerInductionUnits.PIU[piu_num]
            if this_piu.leakFlow > 0:
                sum_sys_m_cp += this_piu.leakFlow * cp_air
                sum_sys_m_cp_t += this_piu.leakFlow * cp_air * state.dataLoopNodes.Node[this_piu.PriAirInNode - 1].Temp
    
    var zone_mult = zone.Multiplier * zone.ListMultiplier
    sum_sys_m_cp /= zone_mult
    sum_sys_m_cp_t /= zone_mult
    sum_sys_m /= zone_mult
    sum_sys_m_w /= zone_mult
    
    if not afn_node.HasSurfacesAssigned:
        afn_node.SumHA = 0.0
        afn_node.SumHATsurf = 0.0
        afn_node.SumHATref = 0.0
        afn_node.SumSysMCp = sum_sys_m_cp
        afn_node.SumSysMCpT = sum_sys_m_cp_t
        afn_node.SumSysM = sum_sys_m
        afn_node.SumSysMW = sum_sys_m_w
        return
    
    var sum_ha: Float64 = 0.0
    var sum_ha_tsurf: Float64 = 0.0
    var sum_ha_tref: Float64 = 0.0
    var sum_int_gain: Float64 = 0.0
    var surf_count: Int32 = 0
    
    for space_num in zone.spaceIndexes:
        var this_space = state.dataHeatBal.space[space_num - 1]
        for surf_num in range(this_space.HTSurfaceFirst, this_space.HTSurfaceLast + 1):
            surf_count += 1
            
            if afn_zone_info.ControlAirNodeID == room_air_node_num:
                var found: Bool = False
                for loop in range(1, afn_zone_info.NumOfAirNodes + 1):
                    if loop != room_air_node_num and afn_zone_info.Node[loop - 1].SurfMask[surf_count - 1]:
                        found = True
                        break
                if found:
                    continue
            else:
                if not afn_node.SurfMask[surf_count - 1]:
                    continue
            
            var ha: Float64 = 0.0
            var area = state.dataSurface.Surface[surf_num - 1].Area
            
            if state.dataSurface.Surface[surf_num - 1].Class == SurfaceClass_Window:
                if state.dataSurface.SurfWinShadingFlag[surf_num - 1]:
                    area += state.dataSurface.SurfWinDividerArea[surf_num - 1]
                    sum_int_gain += state.dataSurface.SurfWinDividerHeatGain[surf_num - 1]
                
                if state.dataSurface.SurfWinShadingFlag[surf_num - 1]:
                    sum_int_gain += state.dataSurface.SurfWinConvHeatFlowNatural[surf_num - 1]
                
                if state.dataSurface.SurfWinAirflowThisTS[surf_num - 1] > 0.0:
                    sum_int_gain += state.dataSurface.SurfWinConvHeatGainToZoneAir[surf_num - 1]
                    if zone.NoHeatToReturnAir:
                        sum_int_gain += state.dataSurface.SurfWinRetHeatGainToZoneAir[surf_num - 1]
                
                if state.dataSurface.SurfWinFrameArea[surf_num - 1] > 0.0:
                    sum_ha_tsurf += (state.dataHeatBalSurf.SurfHConvInt[surf_num - 1] * state.dataSurface.SurfWinFrameArea[surf_num - 1] *
                                     (1.0 + state.dataSurface.SurfWinProjCorrFrIn[surf_num - 1]) * state.dataSurface.SurfWinFrameTempIn[surf_num - 1])
                    ha += (state.dataHeatBalSurf.SurfHConvInt[surf_num - 1] * state.dataSurface.SurfWinFrameArea[surf_num - 1] *
                           (1.0 + state.dataSurface.SurfWinProjCorrFrIn[surf_num - 1]))
                
                if (state.dataSurface.SurfWinDividerArea[surf_num - 1] > 0.0 and
                    not state.dataSurface.SurfWinShadingFlag[surf_num - 1]):
                    sum_ha_tsurf += (state.dataHeatBalSurf.SurfHConvInt[surf_num - 1] * state.dataSurface.SurfWinDividerArea[surf_num - 1] *
                                     (1.0 + 2.0 * state.dataSurface.SurfWinProjCorrDivIn[surf_num - 1]) *
                                     state.dataSurface.SurfWinDividerTempIn[surf_num - 1])
                    ha += (state.dataHeatBalSurf.SurfHConvInt[surf_num - 1] * state.dataSurface.SurfWinDividerArea[surf_num - 1] *
                           (1.0 + 2.0 * state.dataSurface.SurfWinProjCorrDivIn[surf_num - 1]))
            
            ha += state.dataHeatBalSurf.SurfHConvInt[surf_num - 1] * area
            sum_ha_tsurf += state.dataHeatBalSurf.SurfHConvInt[surf_num - 1] * area * state.dataHeatBalSurf.SurfTempInTmp[surf_num - 1]
            
            if state.dataSurface.SurfTAirRef[surf_num - 1] == RefAirTemp_ZoneMeanAirTemp:
                sum_ha += ha
            elif state.dataSurface.SurfTAirRef[surf_num - 1] == RefAirTemp_AdjacentAirTemp:
                sum_ha_tref += ha * state.dataHeatBal.SurfTempEffBulkAir[surf_num - 1]
            elif state.dataSurface.SurfTAirRef[surf_num - 1] == RefAirTemp_ZoneSupplyAirTemp:
                if not zone.IsControlled:
                    state.ShowFatalError(state, "Zones must be controlled for Ceiling-Diffuser Convection model")
                    return
                var ref_air_temp = sum_sys_m_cp_t / sum_sys_m_cp if sum_sys_m_cp > 0 else 0.0
                sum_ha_tref += ha * ref_air_temp
            else:
                sum_ha += ha
    
    afn_node.SumHA = sum_ha
    afn_node.SumHATsurf = sum_ha_tsurf
    afn_node.SumHATref = sum_ha_tref
    afn_node.SumSysMCp = sum_sys_m_cp
    afn_node.SumSysMCpT = sum_sys_m_cp_t
    afn_node.SumSysM = sum_sys_m
    afn_node.SumSysMW = sum_sys_m_w

fn calc_surface_moisture_sums(inout state: AnyType, zone_num: Int32, room_air_node_num: Int32, inout afn_node: AFNNode) -> None:
    var sum_hm_aw: Float64 = 0.0
    var sum_hm_ara: Float64 = 0.0
    var sum_hm_ara_w: Float64 = 0.0
    
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    var surf_count: Int32 = 0
    
    for space_num in state.dataHeatBal.Zone[zone_num - 1].spaceIndexes:
        var this_space = state.dataHeatBal.space[space_num - 1]
        for surf_num in range(this_space.HTSurfaceFirst, this_space.HTSurfaceLast + 1):
            surf_count += 1
            
            var surf = state.dataSurface.Surface[surf_num - 1]
            if surf.Class == SurfaceClass_Window:
                continue
            
            if afn_zone_info.ControlAirNodeID == room_air_node_num:
                var found: Bool = False
                for loop in range(1, afn_zone_info.NumOfAirNodes + 1):
                    if loop != room_air_node_num and afn_zone_info.Node[loop - 1].SurfMask[surf_count - 1]:
                        found = True
                        break
                if found:
                    continue
            else:
                if not afn_zone_info.Node[room_air_node_num - 1].SurfMask[surf_count - 1]:
                    continue
            
            var h_mass_conv_in_fd = state.dataMstBal.HMassConvInFD[surf_num - 1]
            var rho_vapor_surf_in = state.dataMstBal.RhoVaporSurfIn[surf_num - 1]
            var rho_vapor_air_in = state.dataMstBal.RhoVaporAirIn[surf_num - 1]
            
            if surf.HeatTransferAlgorithm == HeatTransferModel_HAMT:
                state.UpdateHeatBalHAMT(state, surf_num)
                sum_hm_aw += h_mass_conv_in_fd * surf.Area * (rho_vapor_surf_in - rho_vapor_air_in)
                
                var rho_air_zone = state.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 
                                                           state.dataZoneTempPredictorCorrector.zoneHeatBalance[surf.Zone - 1].MAT,
                                                           state.PsyRhFnTdbRhov(state, state.dataZoneTempPredictorCorrector.zoneHeatBalance[surf.Zone - 1].MAT, rho_vapor_air_in, ""))
                var wsurf = state.PsyWFnTdbRhPb(state, state.dataHeatBalSurf.SurfTempInTmp[surf_num - 1],
                                               state.PsyRhFnTdbRhov(state, state.dataHeatBalSurf.SurfTempInTmp[surf_num - 1], rho_vapor_surf_in, ""), 
                                               state.dataEnvrn.OutBaroPress)
                sum_hm_ara += h_mass_conv_in_fd * surf.Area * rho_air_zone
                sum_hm_ara_w += h_mass_conv_in_fd * surf.Area * rho_air_zone * wsurf
            
            elif surf.HeatTransferAlgorithm == HeatTransferModel_EMPD:
                state.UpdateMoistureBalanceEMPD(state, surf_num)
                rho_vapor_surf_in = state.dataMstBalEMPD.RVSurface[surf_num - 1]
                sum_hm_aw += h_mass_conv_in_fd * surf.Area * (rho_vapor_surf_in - rho_vapor_air_in)
                sum_hm_ara += (h_mass_conv_in_fd * surf.Area * state.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress,
                                                                                        state.dataHeatBalSurf.SurfTempInTmp[surf_num - 1],
                                                                                        state.PsyWFnTdbRhPb(state, state.dataHeatBalSurf.SurfTempInTmp[surf_num - 1],
                                                                                                            state.PsyRhFnTdbRhovLBnd0C(state, state.dataHeatBalSurf.SurfTempInTmp[surf_num - 1], rho_vapor_air_in),
                                                                                                            state.dataEnvrn.OutBaroPress)))
                sum_hm_ara_w += h_mass_conv_in_fd * surf.Area * rho_vapor_surf_in
    
    afn_node.SumHmAW = sum_hm_aw
    afn_node.SumHmARa = sum_hm_ara
    afn_node.SumHmARaW = sum_hm_ara_w

fn sum_non_air_system_response_for_node(inout state: AnyType, zone_num: Int32, room_air_node_num: Int32) -> None:
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    var afn_node = afn_zone_info.Node[room_air_node_num - 1]
    
    afn_node.NonAirSystemResponse = 0.0
    
    if not hasattr(state.dataZoneEquip, 'ZoneEquipConfig'):
        return
    
    for hvac_idx in range(afn_node.HVAC.size()):
        var afn_hvac = afn_node.HVAC[hvac_idx]
        var sys_output_provided: Float64 = 0.0
        var lat_output_provided: Float64 = 0.0
        
        if afn_hvac.zoneEquipType == ZoneEquipType_BaseboardWater:
            state.SimHWBaseboard(state, afn_hvac.Name, zone_num, False, sys_output_provided, afn_hvac.CompIndex)
            afn_node.NonAirSystemResponse += afn_hvac.SupplyFraction * sys_output_provided
        elif afn_hvac.zoneEquipType == ZoneEquipType_BaseboardSteam:
            state.SimSteamBaseboard(state, afn_hvac.Name, zone_num, False, sys_output_provided, afn_hvac.CompIndex)
            afn_node.NonAirSystemResponse += afn_hvac.SupplyFraction * sys_output_provided
        elif afn_hvac.zoneEquipType == ZoneEquipType_BaseboardConvectiveWater:
            state.SimBaseboard(state, afn_hvac.Name, zone_num, False, sys_output_provided, afn_hvac.CompIndex)
            afn_node.NonAirSystemResponse += afn_hvac.SupplyFraction * sys_output_provided
        elif afn_hvac.zoneEquipType == ZoneEquipType_BaseboardConvectiveElectric:
            state.SimElectricBaseboard(state, afn_hvac.Name, zone_num, sys_output_provided, afn_hvac.CompIndex)
            afn_node.NonAirSystemResponse += afn_hvac.SupplyFraction * sys_output_provided
        elif afn_hvac.zoneEquipType == ZoneEquipType_RefrigerationChillerSet:
            state.SimAirChillerSet(state, afn_hvac.Name, zone_num, False, sys_output_provided, lat_output_provided, afn_hvac.CompIndex)
            afn_node.NonAirSystemResponse += afn_hvac.SupplyFraction * sys_output_provided
        elif afn_hvac.zoneEquipType == ZoneEquipType_BaseboardElectric:
            state.SimElecBaseboard(state, afn_hvac.Name, zone_num, False, sys_output_provided, afn_hvac.CompIndex)
            afn_node.NonAirSystemResponse += afn_hvac.SupplyFraction * sys_output_provided
        elif afn_hvac.zoneEquipType == ZoneEquipType_HighTemperatureRadiant:
            state.SimHighTempRadiantSystem(state, afn_hvac.Name, False, sys_output_provided, afn_hvac.CompIndex)
            afn_node.NonAirSystemResponse += afn_hvac.SupplyFraction * sys_output_provided

fn sum_system_dep_response_for_node(inout state: AnyType, zone_num: Int32) -> None:
    var afn_zone_info = state.dataRoomAir.AFNZoneInfo[zone_num - 1]
    var sys_output_provided: Float64 = 0.0
    var lat_output_provided: Float64 = 0.0
    
    for node_idx in range(afn_zone_info.Node.size()):
        var afn_node = afn_zone_info.Node[node_idx]
        afn_node.SysDepZoneLoadsLaggedOld = 0.0
        for hvac_idx in range(afn_node.HVAC.size()):
            var afn_hvac = afn_node.HVAC[hvac_idx]
            if afn_hvac.zoneEquipType == ZoneEquipType_DehumidifierDX:
                if sys_output_provided == 0.0:
                    state.SimZoneDehumidifier(state, afn_hvac.Name, zone_num, False, sys_output_provided, lat_output_provided, afn_hvac.CompIndex)
                if sys_output_provided > 0.0:
                    break
    
    if sys_output_provided > 0.0:
        for node_idx in range(afn_zone_info.Node.size()):
            var afn_node = afn_zone_info.Node[node_idx]
            for hvac_idx in range(afn_node.HVAC.size()):
                var afn_hvac = afn_node.HVAC[hvac_idx]
                if afn_hvac.zoneEquipType == ZoneEquipType_DehumidifierDX:
                    afn_node.SysDepZoneLoadsLaggedOld += afn_hvac.SupplyFraction * sys_output_provided

# EXTERNAL DEPS (to wire in glue):
# - state: EnergyPlusData struct with .dataAirLoopHVACDOAS, .dataLoopNodes, .dataInputProcessing,
#   .dataAirLoop, .dataGlobal, .dataFans, .dataMixedAir, .dataSize, .dataHVACGlobal, .dataEnvrn,
#   .dataWeather, .dataAirSystemsData, .dataSizing
# - Util: SameString, makeUPPER, FindItemInList
# - Node: GetOnlySingleNode, SetUpCompSets, ConnectionObjectType, FluidType, ConnectionType
# - Psychrometrics: PsyHFnTdbW, PsyWFnTdpPb
# - ScheduleManager (Sched): GetSchedule
# - MixedAir: ManageOutsideAirSystem
# - Component modules: WaterCoils, Fans, PlantUtilities, HeatingCoils, HVACHXAssistedCoolingCoil,
#   HVACDXHeatPumpSystem, HeatRecovery, DesiccantDehumidifiers, Humidifiers, TranspiredCollector,
#   PhotovoltaicThermalCollectors, EvaporativeCoolers, HVACVariableRefrigerantFlow, SteamCoils,
#   UnitarySystems
# - OutAirNodeManager: CheckOutAirNodeNumber
# - BaseSizer: reportSizerOutput
# - SimAirServingZones: CompType enum
# - DataPlant: PlantEquipmentType enum
# - Constant: HWInitConvTemp, CWInitConvTemp, KindOfSim enum
# - DataSizing: AutoSize constant
# - Error reporting: ShowSevereError, ShowFatalError, ShowContinueError, ShowWarningError, etc.

from math import fabs
alias Real64 = F64


@value
struct ValidEquipListType:
    var value: I32

    alias Invalid = ValidEquipListType(-1)
    alias OutdoorAirMixer = ValidEquipListType(0)
    alias FanConstantVolume = ValidEquipListType(1)
    alias FanVariableVolume = ValidEquipListType(2)
    alias FanSystemModel = ValidEquipListType(3)
    alias FanComponentModel = ValidEquipListType(4)
    alias CoilCoolingWater = ValidEquipListType(5)
    alias CoilHeatingWater = ValidEquipListType(6)
    alias CoilHeatingSteam = ValidEquipListType(7)
    alias CoilCoolingWaterDetailedGeometry = ValidEquipListType(8)
    alias CoilHeatingElectric = ValidEquipListType(9)
    alias CoilHeatingFuel = ValidEquipListType(10)
    alias CoilSystemCoolingWaterHeatExchangerAssisted = ValidEquipListType(11)
    alias CoilSystemCoolingDX = ValidEquipListType(12)
    alias CoilSystemHeatingDX = ValidEquipListType(13)
    alias AirLoopHVACUnitarySystem = ValidEquipListType(14)
    alias CoilUserDefined = ValidEquipListType(15)
    alias HeatExchangerAirToAirFlatPlate = ValidEquipListType(16)
    alias HeatExchangerAirToAirSensibleAndLatent = ValidEquipListType(17)
    alias HeatExchangerDesiccantBalancedFlow = ValidEquipListType(18)
    alias DehumidifierDesiccantNoFans = ValidEquipListType(19)
    alias DehumidifierDesiccantSystem = ValidEquipListType(20)
    alias HumidifierSteamElectric = ValidEquipListType(21)
    alias HumidifierSteamGas = ValidEquipListType(22)
    alias SolarCollectorUnglazedTranspired = ValidEquipListType(23)
    alias SolarCollectorFlatPlatePhotovoltaicThermal = ValidEquipListType(24)
    alias EvaporativeCoolerDirectCeldekPad = ValidEquipListType(25)
    alias EvaporativeCoolerIndirectCeldekPad = ValidEquipListType(26)
    alias EvaporativeCoolerIndirectWetCoil = ValidEquipListType(27)
    alias EvaporativeCoolerIndirectResearchSpecial = ValidEquipListType(28)
    alias EvaporativeCoolerDirectResearchSpecial = ValidEquipListType(29)
    alias ZoneHVACTerminalUnitVariableRefrigerantFlow = ValidEquipListType(30)
    alias Num = ValidEquipListType(31)


fn _init_valid_equip_names() -> List[StringRef]:
    var names = List[StringRef](31)
    names.append("OUTDOORAIR:MIXER")
    names.append("FAN:CONSTANTVOLUME")
    names.append("FAN:VARIABLEVOLUME")
    names.append("FAN:SYSTEMMODEL")
    names.append("FAN:COMPONENTMODEL")
    names.append("COIL:COOLING:WATER")
    names.append("COIL:HEATING:WATER")
    names.append("COIL:HEATING:STEAM")
    names.append("COIL:COOLING:WATER:DETAILEDGEOMETRY")
    names.append("COIL:HEATING:ELECTRIC")
    names.append("COIL:HEATING:FUEL")
    names.append("COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED")
    names.append("COILSYSTEM:COOLING:DX")
    names.append("COILSYSTEM:HEATING:DX")
    names.append("AIRLOOPHVAC:UNITARYSYSTEM")
    names.append("COIL:USERDEFINED")
    names.append("HEATEXCHANGER:AIRTOAIR:FLATPLATE")
    names.append("HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT")
    names.append("HEATEXCHANGER:DESICCANT:BALANCEDFLOW")
    names.append("DEHUMIDIFIER:DESICCANT:NOFANS")
    names.append("DEHUMIDIFIER:DESICCANT:SYSTEM")
    names.append("HUMIDIFIER:STEAM:ELECTRIC")
    names.append("HUMIDIFIER:STEAM:GAS")
    names.append("SOLARCOLLECTOR:UNGLAZEDTRANSPIRED")
    names.append("SOLARCOLLECTOR:FLATPLATE:PHOTOVOLTAICTHERMAL")
    names.append("EVAPORATIVECOOLER:DIRECT:CELDEKPAD")
    names.append("EVAPORATIVECOOLER:INDIRECT:CELDEKPAD")
    names.append("EVAPORATIVECOOLER:INDIRECT:WETCOIL")
    names.append("EVAPORATIVECOOLER:INDIRECT:RESEARCHSPECIAL")
    names.append("EVAPORATIVECOOLER:DIRECT:RESEARCHSPECIAL")
    names.append("ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW")
    return names


@value
struct AirLoopMixer:
    var name: String
    var numOfInletNodes: I32
    var m_AirLoopMixer_Num: I32
    var OutletNodeNum: I32
    var OutletNodeName: String
    var InletNodeName: List[String]
    var InletNodeNum: List[I32]
    var OutletTemp: Real64

    fn __init__(
        inout self,
        name: String = "",
        numOfInletNodes: I32 = 0,
        m_AirLoopMixer_Num: I32 = 0,
        OutletNodeNum: I32 = 0,
        OutletNodeName: String = "",
    ):
        self.name = name
        self.numOfInletNodes = numOfInletNodes
        self.m_AirLoopMixer_Num = m_AirLoopMixer_Num
        self.OutletNodeNum = OutletNodeNum
        self.OutletNodeName = OutletNodeName
        self.InletNodeName = List[String]()
        self.InletNodeNum = List[I32]()
        self.OutletTemp = 0.0

    fn CalcAirLoopMixer(inout self, state: AnyPointer) -> None:
        var outletTemp: Real64 = 0.0
        var outletHumRat: Real64 = 0.0
        var massSum: Real64 = 0.0

        for i in range(self.numOfInletNodes):
            var InletNum = self.InletNodeNum[i]
            var node_mass_flow = _get_node_mass_flow_rate(state, InletNum)
            massSum += node_mass_flow
            outletTemp += node_mass_flow * _get_node_temp(state, InletNum)
            outletHumRat += node_mass_flow * _get_node_humrat(state, InletNum)

        if massSum > 0.0:
            _set_node_temp(state, self.OutletNodeNum, outletTemp / massSum)
            _set_node_humrat(state, self.OutletNodeNum, outletHumRat / massSum)
            _set_node_mass_flow_rate(state, self.OutletNodeNum, massSum)
            var enthalpy = Psychrometrics.PsyHFnTdbW(outletTemp / massSum, outletHumRat / massSum)
            _set_node_enthalpy(state, self.OutletNodeNum, enthalpy)
            self.OutletTemp = _get_node_temp(state, self.OutletNodeNum)
        else:
            _set_node_temp(state, self.OutletNodeNum, _get_node_temp(state, self.InletNodeNum[0]))
            _set_node_humrat(state, self.OutletNodeNum, _get_node_humrat(state, self.InletNodeNum[0]))
            _set_node_mass_flow_rate(state, self.OutletNodeNum, 0.0)
            _set_node_enthalpy(state, self.OutletNodeNum, _get_node_enthalpy(state, self.InletNodeNum[0]))
            self.OutletTemp = _get_node_temp(state, self.InletNodeNum[0])


@value
struct AirLoopSplitter:
    var name: String
    var numOfOutletNodes: I32
    var m_AirLoopSplitter_Num: I32
    var InletNodeName: String
    var OutletNodeName: List[String]
    var OutletNodeNum: List[I32]
    var InletTemp: Real64
    var InletNodeNum: I32

    fn __init__(
        inout self,
        name: String = "",
        numOfOutletNodes: I32 = 0,
        m_AirLoopSplitter_Num: I32 = 0,
        InletNodeName: String = "",
        InletNodeNum: I32 = 0,
    ):
        self.name = name
        self.numOfOutletNodes = numOfOutletNodes
        self.m_AirLoopSplitter_Num = m_AirLoopSplitter_Num
        self.InletNodeName = InletNodeName
        self.InletNodeNum = InletNodeNum
        self.OutletNodeName = List[String]()
        self.OutletNodeNum = List[I32]()
        self.InletTemp = 0.0

    fn CalcAirLoopSplitter(inout self, state: AnyPointer, Temp: Real64, HumRat: Real64) -> None:
        for i in range(self.numOfOutletNodes):
            _set_node_temp(state, self.OutletNodeNum[i], Temp)
            _set_node_humrat(state, self.OutletNodeNum[i], HumRat)
            var enthalpy = Psychrometrics.PsyHFnTdbW(Temp, HumRat)
            _set_node_enthalpy(state, self.OutletNodeNum[i], enthalpy)
        self.InletTemp = Temp


@value
struct AirLoopDOAS:
    var SumMassFlowRate: Real64
    var PreheatTemp: Real64
    var PrecoolTemp: Real64
    var PreheatHumRat: Real64
    var PrecoolHumRat: Real64
    var SizingMassFlow: Real64
    var SizingCoolOATemp: Real64
    var SizingCoolOAHumRat: Real64
    var HeatOutTemp: Real64
    var HeatOutHumRat: Real64
    var m_AirLoopDOASNum: I32
    var m_OASystemNum: I32
    var m_AvailManagerSched: AnyPointer
    var m_AirLoopMixerIndex: I32
    var m_AirLoopSplitterIndex: I32
    var NumOfAirLoops: I32
    var m_InletNodeNum: I32
    var m_OutletNodeNum: I32
    var m_FanIndex: I32
    var m_FanInletNodeNum: I32
    var m_FanOutletNodeNum: I32
    var m_FanTypeNum: I32
    var m_exhaustFanUsed: Bool
    var m_exhaustFanIndex: I32
    var m_exhaustFanInletNodeNum: I32
    var m_exhaustFanOutletNodeNum: I32
    var m_exhaustFanTypeNum: I32
    var m_HeatCoilNum: I32
    var m_CoolCoilNum: I32
    var ConveCount: I32
    var ConveIndex: I32
    var m_HeatExchangerFlag: Bool
    var SizingOnceFlag: Bool
    var FanBeforeCoolingCoilFlag: Bool
    var m_CompPointerAirLoopMixer: AnyPointer
    var m_CompPointerAirLoopSplitter: AnyPointer
    var Name: String
    var AvailManagerSchedName: String
    var OASystemName: String
    var AirLoopMixerName: String
    var AirLoopSplitterName: String
    var FanName: String
    var m_AirLoopNum: List[I32]
    var AirLoopName: List[String]
    var m_OACtrlNum: List[I32]
    var HWPlantLoc: AnyPointer
    var HWCtrlNodeNum: I32
    var CWPlantLoc: AnyPointer
    var CWCtrlNodeNum: I32
    var MyEnvrnFlag: Bool

    fn __init__(inout self):
        self.SumMassFlowRate = 0.0
        self.PreheatTemp = -999.0
        self.PrecoolTemp = -999.0
        self.PreheatHumRat = -999.0
        self.PrecoolHumRat = -999.0
        self.SizingMassFlow = 0.0
        self.SizingCoolOATemp = -999.0
        self.SizingCoolOAHumRat = -999.0
        self.HeatOutTemp = 999.0
        self.HeatOutHumRat = 999.0
        self.m_AirLoopDOASNum = 0
        self.m_OASystemNum = 0
        self.m_AvailManagerSched = AnyPointer()
        self.m_AirLoopMixerIndex = -1
        self.m_AirLoopSplitterIndex = -1
        self.NumOfAirLoops = 0
        self.m_InletNodeNum = 0
        self.m_OutletNodeNum = 0
        self.m_FanIndex = 0
        self.m_FanInletNodeNum = 0
        self.m_FanOutletNodeNum = 0
        self.m_FanTypeNum = -1
        self.m_exhaustFanUsed = False
        self.m_exhaustFanIndex = -1
        self.m_exhaustFanInletNodeNum = 0
        self.m_exhaustFanOutletNodeNum = 0
        self.m_exhaustFanTypeNum = -1
        self.m_HeatCoilNum = 0
        self.m_CoolCoilNum = 0
        self.ConveCount = 0
        self.ConveIndex = 0
        self.m_HeatExchangerFlag = False
        self.SizingOnceFlag = True
        self.FanBeforeCoolingCoilFlag = False
        self.m_CompPointerAirLoopMixer = AnyPointer()
        self.m_CompPointerAirLoopSplitter = AnyPointer()
        self.Name = ""
        self.AvailManagerSchedName = ""
        self.OASystemName = ""
        self.AirLoopMixerName = ""
        self.AirLoopSplitterName = ""
        self.FanName = ""
        self.m_AirLoopNum = List[I32]()
        self.AirLoopName = List[String]()
        self.m_OACtrlNum = List[I32]()
        self.HWPlantLoc = AnyPointer()
        self.HWCtrlNodeNum = 0
        self.CWPlantLoc = AnyPointer()
        self.CWCtrlNodeNum = 0
        self.MyEnvrnFlag = True

    fn SimAirLoopHVACDOAS(inout self, state: AnyPointer, firstHVACIteration: Bool, inout CompIndex: I32) -> None:
        if _get_air_loop_doas_get_input_once_flag(state):
            _call_get_air_loop_doas_input(state)
            _set_air_loop_doas_get_input_once_flag(state, False)

        if CompIndex == -1:
            CompIndex = self.m_AirLoopDOASNum

        if self.SizingOnceFlag:
            self.SizingAirLoopDOAS(state)
            self.SizingOnceFlag = False

        self.initAirLoopDOAS(state, firstHVACIteration)

        if self.SumMassFlowRate == 0.0 and not _get_begin_envr_flag(state):
            _set_node_mass_flow_rate(state, _get_mixer_outlet_node_num(self.m_CompPointerAirLoopMixer), 0.0)

        self.CalcAirLoopDOAS(state, firstHVACIteration)

    fn initAirLoopDOAS(inout self, state: AnyPointer, FirstHVACIteration: Bool) -> None:
        if _get_begin_envr_flag(state) and self.MyEnvrnFlag:
            var ErrorsFound = False
            var rho: Real64 = 0.0
            var NumComponents = _get_oas_num_components(state, self.m_OASystemNum)
            
            for CompNum in range(1, NumComponents + 1):
                var CompType = _get_oas_component_type(state, self.m_OASystemNum, CompNum - 1)
                var CompName = _get_oas_component_name(state, self.m_OASystemNum, CompNum - 1)

                if Util.SameString(CompType, "FAN:SYSTEMMODEL"):
                    _fan_simulate(state, self.m_FanIndex, FirstHVACIteration)
                if Util.SameString(CompType, "FAN:COMPONENTMODEL"):
                    _fan_simulate(state, self.m_FanIndex, FirstHVACIteration)

                if Util.SameString(CompType, "COIL:HEATING:WATER"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_HeatCoilNum)
                    var CoilMaxVolFlowRate = WaterCoils.GetCoilMaxWaterFlowRate(state, "Coil:Heating:Water", CompName, ErrorsFound)
                    rho = _get_hw_plant_loc_glycol_density(state, self.HWPlantLoc, Constant.HWInitConvTemp)
                    PlantUtilities.InitComponentNodes(
                        state, 0.0, CoilMaxVolFlowRate * rho, self.HWCtrlNodeNum,
                        _get_oas_outlet_node_num(state, self.m_OASystemNum, CompNum - 1)
                    )

                if Util.SameString(CompType, "COIL:COOLING:WATER"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_CoolCoilNum)
                    var CoilMaxVolFlowRate = WaterCoils.GetCoilMaxWaterFlowRate(state, "Coil:Cooling:Water", CompName, ErrorsFound)
                    rho = _get_cw_plant_loc_glycol_density(state, self.CWPlantLoc, Constant.CWInitConvTemp)
                    PlantUtilities.InitComponentNodes(
                        state, 0.0, CoilMaxVolFlowRate * rho, self.CWCtrlNodeNum,
                        _get_oas_outlet_node_num(state, self.m_OASystemNum, CompNum - 1)
                    )

                if Util.SameString(CompType, "COIL:COOLING:WATER:DETAILEDGEOMETRY"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_CoolCoilNum)
                    var CoilMaxVolFlowRate = WaterCoils.GetCoilMaxWaterFlowRate(
                        state, "Coil:Cooling:Water:DetailedGeometry", CompName, ErrorsFound
                    )
                    rho = _get_cw_plant_loc_glycol_density(state, self.CWPlantLoc, Constant.CWInitConvTemp)
                    PlantUtilities.InitComponentNodes(
                        state, 0.0, CoilMaxVolFlowRate * rho, self.CWCtrlNodeNum,
                        _get_oas_outlet_node_num(state, self.m_OASystemNum, CompNum - 1)
                    )

            self.MyEnvrnFlag = False
            if ErrorsFound:
                ShowFatalError(state, "initAirLoopDOAS: Previous errors cause termination.")

        if not _get_begin_envr_flag(state):
            self.MyEnvrnFlag = True

        self.SumMassFlowRate = 0.0

        var numOutlets = _get_splitter_num_outlets(self.m_CompPointerAirLoopSplitter)
        for LoopOA in range(numOutlets):
            var NodeNum = _get_splitter_outlet_node_num(self.m_CompPointerAirLoopSplitter, LoopOA)
            self.SumMassFlowRate += _get_node_mass_flow_rate(state, NodeNum)

        var SchAvailValue = _get_sched_value(self.m_AvailManagerSched)
        if SchAvailValue < 1.0:
            self.SumMassFlowRate = 0.0

        _set_node_mass_flow_rate(state, self.m_InletNodeNum, self.SumMassFlowRate)

    fn CalcAirLoopDOAS(inout self, state: AnyPointer, FirstHVACIteration: Bool) -> None:
        _mixer_calc_air_loop_mixer(state, self.m_CompPointerAirLoopMixer)

        if self.m_FanIndex > 0:
            if self.m_FanInletNodeNum == self.m_InletNodeNum:
                _set_node_mass_flow_rate_max_avail(state, self.m_FanInletNodeNum, self.SumMassFlowRate)
                _set_node_mass_flow_rate_max_avail(state, self.m_FanOutletNodeNum, self.SumMassFlowRate)
                _set_node_mass_flow_rate_max(state, self.m_FanOutletNodeNum, self.SumMassFlowRate)
            else:
                _set_node_mass_flow_rate_max(state, self.m_InletNodeNum, self.SumMassFlowRate)
                _set_node_mass_flow_rate_max_avail(state, self.m_InletNodeNum, self.SumMassFlowRate)

        if self.m_exhaustFanUsed:
            _set_node_mass_flow_rate_max_avail(state, self.m_exhaustFanInletNodeNum, self.SumMassFlowRate)
            _set_node_mass_flow_rate_max_avail(state, self.m_exhaustFanOutletNodeNum, self.SumMassFlowRate)
            _set_node_mass_flow_rate_max(state, self.m_exhaustFanOutletNodeNum, self.SumMassFlowRate)

        MixedAir.ManageOutsideAirSystem(state, self.OASystemName, FirstHVACIteration, 0, self.m_OASystemNum)

        var Temp = _get_node_temp(state, self.m_OutletNodeNum)
        var HumRat = _get_node_humrat(state, self.m_OutletNodeNum)
        var enthalpy = Psychrometrics.PsyHFnTdbW(Temp, HumRat)
        _set_node_enthalpy(state, self.m_OutletNodeNum, enthalpy)

        _splitter_calc_air_loop_splitter(state, self.m_CompPointerAirLoopSplitter, Temp, HumRat)

    fn SizingAirLoopDOAS(inout self, state: AnyPointer) -> None:
        var sizingVolumeFlow: Real64 = 0.0

        for AirLoop in range(1, self.NumOfAirLoops + 1):
            var AirLoopNum = self.m_AirLoopNum[AirLoop - 1]
            var OACtrlNum = _get_airloop_control_info_oa_ctrl_num(state, AirLoopNum - 1)
            self.m_OACtrlNum.append(OACtrlNum)

            if self.m_OACtrlNum[AirLoop - 1] > 0:
                sizingVolumeFlow += _get_oa_controller_max_oa(state, self.m_OACtrlNum[AirLoop - 1] - 1)

        self.SizingMassFlow = sizingVolumeFlow * _get_std_rho_air(state)

        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Volume Flow Rate [m3/s]", sizingVolumeFlow)
        self.GetDesignDayConditions(state)

        if self.m_FanIndex > 0 and (self.m_FanTypeNum == 0 or self.m_FanTypeNum == 1):
            var supplyFanVolFlow = _get_fan_max_air_flow_rate(state, self.m_FanIndex)
            var auto_size_val = _get_auto_size_value()
            if supplyFanVolFlow != auto_size_val:
                if fabs((supplyFanVolFlow - sizingVolumeFlow) / sizingVolumeFlow) > 0.01:
                    ShowWarningError(state, f"AirLoopHVAC:DedicatedOutdoorAirSystem = {self.Name}.")
                    var fan_name = _get_fan_name(state, self.m_FanIndex)
                    ShowContinueError(state,
                        f"The supply fan = {fan_name} has a volumetric air flow rate = {supplyFanVolFlow} m3/s.")
                    ShowContinueError(state,
                        f"The AirLoopHVAC:DedicatedOutdoorAirSystem Design Volume Flow Rate = {sizingVolumeFlow} m3/s.")
                    ShowContinueError(state, "Consider autosizing the supply fan Maximum Air Flow Rate.")
            else:
                _set_fan_max_air_flow_rate(state, self.m_FanIndex, sizingVolumeFlow)
                _set_node_mass_flow_rate_max_avail(state, self.m_FanInletNodeNum, self.SizingMassFlow)
                _set_node_mass_flow_rate_max_avail(state, self.m_FanOutletNodeNum, self.SizingMassFlow)
                _set_node_mass_flow_rate_max(state, self.m_FanOutletNodeNum, self.SizingMassFlow)
                if self.m_FanTypeNum == 1:
                    _set_fan_min_air_flow_rate(state, self.m_FanIndex, 0.0)
                    _set_fan_max_air_mass_flow_rate(state, self.m_FanIndex, self.SizingMassFlow)

        if self.m_exhaustFanUsed:
            if self.m_exhaustFanIndex > 0 and (self.m_exhaustFanTypeNum == 0 or self.m_exhaustFanTypeNum == 1):
                var exhaustFanVolFlow = _get_fan_max_air_flow_rate(state, self.m_exhaustFanIndex)
                var auto_size_val = _get_auto_size_value()
                if exhaustFanVolFlow != auto_size_val:
                    if fabs((exhaustFanVolFlow - sizingVolumeFlow) / sizingVolumeFlow) > 0.01:
                        ShowWarningError(state, f"AirLoopHVAC:DedicatedOutdoorAirSystem = {self.Name}.")
                        var exhaust_fan_name = _get_fan_name(state, self.m_exhaustFanIndex)
                        ShowContinueError(state,
                            f"The exhaust fan = {exhaust_fan_name} has a volumetric air flow rate = {exhaustFanVolFlow} m3/s.")
                        ShowContinueError(state,
                            f"The AirLoopHVAC:DedicatedOutdoorAirSystem Design Volume Flow Rate = {sizingVolumeFlow} m3/s.")
                        ShowContinueError(state, "Consider autosizing the exhaust fan Maximum Air Flow Rate.")
                else:
                    _set_fan_max_air_flow_rate(state, self.m_exhaustFanIndex, sizingVolumeFlow)
                    _set_node_mass_flow_rate_max_avail(state, self.m_exhaustFanInletNodeNum, self.SizingMassFlow)
                    _set_node_mass_flow_rate_max_avail(state, self.m_exhaustFanOutletNodeNum, self.SizingMassFlow)
                    _set_node_mass_flow_rate_max(state, self.m_exhaustFanOutletNodeNum, self.SizingMassFlow)
                    if self.m_FanTypeNum == 1:
                        _set_fan_min_air_flow_rate(state, self.m_exhaustFanIndex, 0.0)
                        _set_fan_max_air_mass_flow_rate(state, self.m_exhaustFanIndex, self.SizingMassFlow)

        _set_cur_sys_num(state, _get_num_primary_air_sys(state) + self.m_AirLoopDOASNum + 1)
        _set_cur_oa_sys_num(state, self.m_OASystemNum)

    fn GetDesignDayConditions(inout self, state: AnyPointer) -> None:
        var num_envs = _get_num_environments(state)
        for env_idx in range(num_envs):
            var kind_of_envrn = _get_env_kind_of_envrn(state, env_idx)
            if kind_of_envrn != 1 and kind_of_envrn != 2:
                continue

            var max_cool_oa_temp = _get_env_max_cooling_oa_t_sizing(state, env_idx)
            if max_cool_oa_temp > self.SizingCoolOATemp:
                self.SizingCoolOATemp = max_cool_oa_temp
                var design_day_num = _get_env_design_day_num(state, env_idx)
                if kind_of_envrn == 1 and _get_des_day_input_pressure_entered(state, design_day_num):
                    var pressure_baro = _get_des_day_input_press_baro(state, design_day_num)
                    var max_cool_oa_dp = _get_env_max_cooling_oa_dp_sizing(state, env_idx)
                    self.SizingCoolOAHumRat = Psychrometrics.PsyWFnTdpPb(state, max_cool_oa_dp, pressure_baro)
                else:
                    var std_baro_press = _get_std_baro_press(state)
                    var max_cool_oa_dp = _get_env_max_cooling_oa_dp_sizing(state, env_idx)
                    self.SizingCoolOAHumRat = Psychrometrics.PsyWFnTdpPb(state, max_cool_oa_dp, std_baro_press)

            var min_heat_oa_temp = _get_env_min_heating_oa_t_sizing(state, env_idx)
            if min_heat_oa_temp < self.HeatOutTemp:
                self.HeatOutTemp = min_heat_oa_temp
                var design_day_num = _get_env_design_day_num(state, env_idx)
                if kind_of_envrn == 1 and _get_des_day_input_pressure_entered(state, design_day_num):
                    var pressure_baro = _get_des_day_input_press_baro(state, design_day_num)
                    var min_heat_oa_dp = _get_env_min_heating_oa_dp_sizing(state, env_idx)
                    self.HeatOutHumRat = Psychrometrics.PsyWFnTdpPb(state, min_heat_oa_dp, pressure_baro)
                else:
                    var std_baro_press = _get_std_baro_press(state)
                    var min_heat_oa_dp = _get_env_min_heating_oa_dp_sizing(state, env_idx)
                    self.HeatOutHumRat = Psychrometrics.PsyWFnTdpPb(state, min_heat_oa_dp, std_baro_press)

        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Cooling Outdoor Air Temperature [C]", self.SizingCoolOATemp)
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Cooling Outdoor Air Humidity Ratio [kgWater/kgDryAir]", self.SizingCoolOAHumRat)
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Heating Outdoor Air Temperature [C]", self.HeatOutTemp)
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Heating Outdoor Air Humidity Ratio [kgWater/kgDryAir]", self.HeatOutHumRat)


fn CheckConvergence(state: AnyPointer) -> None:
    var num_doas = _get_num_airloop_doas(state)
    for doas_idx in range(num_doas):
        var loop = _get_airloop_doas_ref(state, doas_idx)
        var maxDiff: Real64 = 0.0
        
        var inlet_temp = _get_splitter_inlet_temp(loop.m_CompPointerAirLoopSplitter)
        var outlet_temp = _get_node_temp(state, _get_splitter_outlet_node_num(loop.m_CompPointerAirLoopSplitter, 0))
        var Diff = fabs(inlet_temp - outlet_temp)
        if Diff > maxDiff:
            maxDiff = Diff

        if loop.m_HeatExchangerFlag:
            var OldTemp = _get_mixer_outlet_temp(loop.m_CompPointerAirLoopMixer)
            _mixer_calc_air_loop_mixer(state, loop.m_CompPointerAirLoopMixer)
            Diff = fabs(OldTemp - _get_mixer_outlet_temp(loop.m_CompPointerAirLoopMixer))
            if Diff > maxDiff:
                maxDiff = Diff

        if maxDiff > 1.0e-6:
            if loop.ConveCount == 0:
                var name = _get_doas_name(loop)
                ShowWarningError(state, f"Convergence limit is above 1.0e-6 for unit={name}")
                ShowContinueErrorTimeStamp(state,
                    f"The max difference of node temperatures between AirLoopDOAS outlet and OA mixer inlet ={maxDiff:.6f}")
            else:
                var name = _get_doas_name(loop)
                ShowRecurringWarningErrorAtEnd(state,
                    f'"{name}": The max difference of node temperatures exceeding 1.0e-6  continues...',
                    loop.ConveIndex, maxDiff, maxDiff)


@always_inline
fn _get_node_mass_flow_rate(state: AnyPointer, NodeNum: I32) -> Real64:
    return 0.0


@always_inline
fn _set_node_mass_flow_rate(state: AnyPointer, NodeNum: I32, val: Real64) -> None:
    pass


@always_inline
fn _get_node_temp(state: AnyPointer, NodeNum: I32) -> Real64:
    return 0.0


@always_inline
fn _set_node_temp(state: AnyPointer, NodeNum: I32, val: Real64) -> None:
    pass


@always_inline
fn _get_node_humrat(state: AnyPointer, NodeNum: I32) -> Real64:
    return 0.0


@always_inline
fn _set_node_humrat(state: AnyPointer, NodeNum: I32, val: Real64) -> None:
    pass


@always_inline
fn _get_node_enthalpy(state: AnyPointer, NodeNum: I32) -> Real64:
    return 0.0


@always_inline
fn _set_node_enthalpy(state: AnyPointer, NodeNum: I32, val: Real64) -> None:
    pass


@always_inline
fn _set_node_mass_flow_rate_max(state: AnyPointer, NodeNum: I32, val: Real64) -> None:
    pass


@always_inline
fn _set_node_mass_flow_rate_max_avail(state: AnyPointer, NodeNum: I32, val: Real64) -> None:
    pass


@always_inline
fn _get_begin_envr_flag(state: AnyPointer) -> Bool:
    return False


@always_inline
fn _get_air_loop_doas_get_input_once_flag(state: AnyPointer) -> Bool:
    return False


@always_inline
fn _set_air_loop_doas_get_input_once_flag(state: AnyPointer, val: Bool) -> None:
    pass


@always_inline
fn _call_get_air_loop_doas_input(state: AnyPointer) -> None:
    pass


@always_inline
fn _get_mixer_outlet_node_num(mixer: AnyPointer) -> I32:
    return 0


@always_inline
fn _get_oas_num_components(state: AnyPointer, oas_num: I32) -> I32:
    return 0


@always_inline
fn _get_oas_component_type(state: AnyPointer, oas_num: I32, idx: I32) -> String:
    return ""


@always_inline
fn _get_oas_component_name(state: AnyPointer, oas_num: I32, idx: I32) -> String:
    return ""


@always_inline
fn _fan_simulate(state: AnyPointer, fan_idx: I32, first_hvac: Bool) -> None:
    pass


@always_inline
fn _get_oas_outlet_node_num(state: AnyPointer, oas_num: I32, idx: I32) -> I32:
    return 0


@always_inline
fn _get_hw_plant_loc_glycol_density(state: AnyPointer, plant_loc: AnyPointer, temp: Real64) -> Real64:
    return 0.0


@always_inline
fn _get_cw_plant_loc_glycol_density(state: AnyPointer, plant_loc: AnyPointer, temp: Real64) -> Real64:
    return 0.0


@always_inline
fn _get_splitter_num_outlets(splitter: AnyPointer) -> I32:
    return 0


@always_inline
fn _get_splitter_outlet_node_num(splitter: AnyPointer, idx: I32) -> I32:
    return 0


@always_inline
fn _get_sched_value(sched: AnyPointer) -> Real64:
    return 0.0


@always_inline
fn _mixer_calc_air_loop_mixer(state: AnyPointer, mixer: AnyPointer) -> None:
    pass


@always_inline
fn _get_airloop_control_info_oa_ctrl_num(state: AnyPointer, idx: I32) -> I32:
    return 0


@always_inline
fn _get_oa_controller_max_oa(state: AnyPointer, idx: I32) -> Real64:
    return 0.0


@always_inline
fn _get_std_rho_air(state: AnyPointer) -> Real64:
    return 1.2


@always_inline
fn _get_fan_max_air_flow_rate(state: AnyPointer, fan_idx: I32) -> Real64:
    return 0.0


@always_inline
fn _set_fan_max_air_flow_rate(state: AnyPointer, fan_idx: I32, val: Real64) -> None:
    pass


@always_inline
fn _set_fan_min_air_flow_rate(state: AnyPointer, fan_idx: I32, val: Real64) -> None:
    pass


@always_inline
fn _set_fan_max_air_mass_flow_rate(state: AnyPointer, fan_idx: I32, val: Real64) -> None:
    pass


@always_inline
fn _get_fan_name(state: AnyPointer, fan_idx: I32) -> String:
    return ""


@always_inline
fn _get_auto_size_value() -> Real64:
    return -99999.0


@always_inline
fn _set_cur_sys_num(state: AnyPointer, val: I32) -> None:
    pass


@always_inline
fn _set_cur_oa_sys_num(state: AnyPointer, val: I32) -> None:
    pass


@always_inline
fn _get_num_primary_air_sys(state: AnyPointer) -> I32:
    return 0


@always_inline
fn _get_num_environments(state: AnyPointer) -> I32:
    return 0


@always_inline
fn _get_env_kind_of_envrn(state: AnyPointer, env_idx: I32) -> I32:
    return 0


@always_inline
fn _get_env_max_cooling_oa_t_sizing(state: AnyPointer, env_idx: I32) -> Real64:
    return 0.0


@always_inline
fn _get_env_design_day_num(state: AnyPointer, env_idx: I32) -> I32:
    return 0


@always_inline
fn _get_des_day_input_pressure_entered(state: AnyPointer, des_day_num: I32) -> Bool:
    return False


@always_inline
fn _get_des_day_input_press_baro(state: AnyPointer, des_day_num: I32) -> Real64:
    return 101325.0


@always_inline
fn _get_env_max_cooling_oa_dp_sizing(state: AnyPointer, env_idx: I32) -> Real64:
    return 0.0


@always_inline
fn _get_std_baro_press(state: AnyPointer) -> Real64:
    return 101325.0


@always_inline
fn _get_env_min_heating_oa_t_sizing(state: AnyPointer, env_idx: I32) -> Real64:
    return 0.0


@always_inline
fn _get_env_min_heating_oa_dp_sizing(state: AnyPointer, env_idx: I32) -> Real64:
    return 0.0


@always_inline
fn _get_num_airloop_doas(state: AnyPointer) -> I32:
    return 0


@always_inline
fn _get_airloop_doas_ref(state: AnyPointer, idx: I32) -> AirLoopDOAS:
    return AirLoopDOAS()


@always_inline
fn _splitter_calc_air_loop_splitter(state: AnyPointer, splitter: AnyPointer, temp: Real64, humrat: Real64) -> None:
    pass


@always_inline
fn _get_mixer_outlet_temp(mixer: AnyPointer) -> Real64:
    return 0.0


@always_inline
fn _get_splitter_inlet_temp(splitter: AnyPointer) -> Real64:
    return 0.0


@always_inline
fn _get_doas_name(doas: AirLoopDOAS) -> String:
    return doas.Name


class Util:
    @staticmethod
    fn SameString(s1: String, s2: String) -> Bool:
        return s1 == s2

    @staticmethod
    fn makeUPPER(s: String) -> String:
        return s


class Psychrometrics:
    @staticmethod
    fn PsyHFnTdbW(tdb: Real64, w: Real64) -> Real64:
        return 0.0

    @staticmethod
    fn PsyWFnTdpPb(state: AnyPointer, tdp: Real64, pb: Real64) -> Real64:
        return 0.0


class MixedAir:
    @staticmethod
    fn ManageOutsideAirSystem(state: AnyPointer, name: String, firstHVAC: Bool, unknown: I32, oasysnum: I32) -> None:
        pass


class WaterCoils:
    @staticmethod
    fn GetCoilMaxWaterFlowRate(state: AnyPointer, coil_type: String, coil_name: String, inout err_found: Bool) -> Real64:
        return 0.0

    @staticmethod
    fn SimulateWaterCoilComponents(state: AnyPointer, coil_name: String, first_hvac: Bool, coil_num: I32) -> None:
        pass


class PlantUtilities:
    @staticmethod
    fn InitComponentNodes(state: AnyPointer, min_flow: Real64, max_flow: Real64, ctrl_node: I32, outlet_node: I32) -> None:
        pass


class BaseSizer:
    @staticmethod
    fn reportSizerOutput(state: AnyPointer, system_type: String, obj_name: String, out_name: String, val: Real64) -> None:
        pass


class Constant:
    alias HWInitConvTemp = 60.0
    alias CWInitConvTemp = 6.0


fn ShowWarningError(state: AnyPointer, msg: String) -> None:
    pass


fn ShowFatalError(state: AnyPointer, msg: String) -> None:
    pass


fn ShowContinueError(state: AnyPointer, msg: String) -> None:
    pass


fn ShowContinueErrorTimeStamp(state: AnyPointer, msg: String) -> None:
    pass


fn ShowRecurringWarningErrorAtEnd(state: AnyPointer, msg: String, idx: I32, val1: Real64, val2: Real64) -> None:
    pass

# EXTERNAL DEPS (to wire in glue):
# - state: EnergyPlusData object with .dataAirLoopHVACDOAS, .dataLoopNodes, .dataInputProcessing,
#   .dataAirLoop, .dataGlobal, .dataFans, .dataMixedAir, .dataSize, .dataHVACGlobal, .dataEnvrn,
#   .dataWeather, .dataAirSystemsData, .dataSizing
# - Util: SameString(s1, s2), makeUPPER(s), FindItemInList(name, list)
# - Node: GetOnlySingleNode(...), SetUpCompSets(...), ConnectionObjectType, FluidType, ConnectionType enums
# - Psychrometrics: PsyHFnTdbW(tdb, w), PsyWFnTdpPb(state, tdp, pb)
# - ScheduleManager (Sched): GetSchedule(state, name)
# - MixedAir: ManageOutsideAirSystem(state, name, firstHVAC, unknown, oasysnum)
# - WaterCoils: GetCoilInletNode, GetCoilOutletNode, GetCoilWaterInletNode, 
#   GetCoilMaxWaterFlowRate, SimulateWaterCoilComponents
# - Fans: GetFanIndex(state, name)
# - PlantUtilities: ScanPlantLoopsForObject, InitComponentNodes
# - HeatingCoils: GetCoilInletNode, GetCoilOutletNode
# - HVACHXAssistedCoolingCoil: GetCoilInletNode, GetCoilOutletNode
# - HVACDXHeatPumpSystem: GetHeatingCoilInletNodeNum, GetHeatingCoilOutletNodeNum
# - HeatRecovery: GetSupplyInletNode, GetSupplyOutletNode
# - DesiccantDehumidifiers: GetProcAirInletNodeNum, GetProcAirOutletNodeNum
# - Humidifiers: GetAirInletNodeNum, GetAirOutletNodeNum
# - TranspiredCollector: GetAirInletNodeNum, GetAirOutletNodeNum
# - PhotovoltaicThermalCollectors: GetAirInletNodeNum, GetAirOutletNodeNum
# - EvaporativeCoolers: GetInletNodeNum, GetOutletNodeNum
# - HVACVariableRefrigerantFlow: GetVRFTUInAirNodeFromName, GetVRFTUOutAirNodeFromName
# - SteamCoils: GetCoilSteamInletNode, GetCoilSteamOutletNode
# - UnitarySystems: UnitarySys factory/methods
# - OutAirNodeManager: CheckOutAirNodeNumber
# - BaseSizer: reportSizerOutput
# - Error reporting: ShowSevereError, ShowFatalError, ShowContinueError, ShowWarningError,
#   ShowSevereItemNotFound, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd
# - DataPlant: PlantEquipmentType enum
# - SimAirServingZones: CompType enum
# - Constant: HWInitConvTemp, CWInitConvTemp, KindOfSim enum
# - DataSizing: AutoSize constant
# - HVAC: UnitarySysType enum

from enum import IntEnum
from typing import Protocol, List, Optional, Any
from dataclasses import dataclass, field


class ValidEquipListType(IntEnum):
    Invalid = -1
    OutdoorAirMixer = 0
    FanConstantVolume = 1
    FanVariableVolume = 2
    FanSystemModel = 3
    FanComponentModel = 4
    CoilCoolingWater = 5
    CoilHeatingWater = 6
    CoilHeatingSteam = 7
    CoilCoolingWaterDetailedGeometry = 8
    CoilHeatingElectric = 9
    CoilHeatingFuel = 10
    CoilSystemCoolingWaterHeatExchangerAssisted = 11
    CoilSystemCoolingDX = 12
    CoilSystemHeatingDX = 13
    AirLoopHVACUnitarySystem = 14
    CoilUserDefined = 15
    HeatExchangerAirToAirFlatPlate = 16
    HeatExchangerAirToAirSensibleAndLatent = 17
    HeatExchangerDesiccantBalancedFlow = 18
    DehumidifierDesiccantNoFans = 19
    DehumidifierDesiccantSystem = 20
    HumidifierSteamElectric = 21
    HumidifierSteamGas = 22
    SolarCollectorUnglazedTranspired = 23
    SolarCollectorFlatPlatePhotovoltaicThermal = 24
    EvaporativeCoolerDirectCeldekPad = 25
    EvaporativeCoolerIndirectCeldekPad = 26
    EvaporativeCoolerIndirectWetCoil = 27
    EvaporativeCoolerIndirectResearchSpecial = 28
    EvaporativeCoolerDirectResearchSpecial = 29
    ZoneHVACTerminalUnitVariableRefrigerantFlow = 30
    Num = 31


VALID_EQUIP_NAMES_UC = [
    "OUTDOORAIR:MIXER",
    "FAN:CONSTANTVOLUME",
    "FAN:VARIABLEVOLUME",
    "FAN:SYSTEMMODEL",
    "FAN:COMPONENTMODEL",
    "COIL:COOLING:WATER",
    "COIL:HEATING:WATER",
    "COIL:HEATING:STEAM",
    "COIL:COOLING:WATER:DETAILEDGEOMETRY",
    "COIL:HEATING:ELECTRIC",
    "COIL:HEATING:FUEL",
    "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED",
    "COILSYSTEM:COOLING:DX",
    "COILSYSTEM:HEATING:DX",
    "AIRLOOPHVAC:UNITARYSYSTEM",
    "COIL:USERDEFINED",
    "HEATEXCHANGER:AIRTOAIR:FLATPLATE",
    "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT",
    "HEATEXCHANGER:DESICCANT:BALANCEDFLOW",
    "DEHUMIDIFIER:DESICCANT:NOFANS",
    "DEHUMIDIFIER:DESICCANT:SYSTEM",
    "HUMIDIFIER:STEAM:ELECTRIC",
    "HUMIDIFIER:STEAM:GAS",
    "SOLARCOLLECTOR:UNGLAZEDTRANSPIRED",
    "SOLARCOLLECTOR:FLATPLATE:PHOTOVOLTAICTHERMAL",
    "EVAPORATIVECOOLER:DIRECT:CELDEKPAD",
    "EVAPORATIVECOOLER:INDIRECT:CELDEKPAD",
    "EVAPORATIVECOOLER:INDIRECT:WETCOIL",
    "EVAPORATIVECOOLER:INDIRECT:RESEARCHSPECIAL",
    "EVAPORATIVECOOLER:DIRECT:RESEARCHSPECIAL",
    "ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW",
]


@dataclass
class AirLoopMixer:
    name: str = ""
    numOfInletNodes: int = 0
    m_AirLoopMixer_Num: int = 0
    OutletNodeNum: int = 0
    OutletNodeName: str = ""
    InletNodeName: List[str] = field(default_factory=list)
    InletNodeNum: List[int] = field(default_factory=list)
    OutletTemp: float = 0.0

    @staticmethod
    def factory(state: Any, objectNum: int, objectName: str) -> Optional['AirLoopMixer']:
        if state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag:
            AirLoopMixer.getAirLoopMixer(state)
            state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag = False
        
        for dSpec in state.dataAirLoopHVACDOAS.airloopMixer:
            if Util.SameString(dSpec.name, objectName) and dSpec.m_AirLoopMixer_Num == objectNum:
                return dSpec
        
        ShowSevereError(state, f"AirLoopMixer factory: Error getting inputs for system named: {objectName}")
        return None

    @staticmethod
    def getAirLoopMixer(state: Any) -> None:
        cCurrentModuleObject = "AirLoopHVAC:Mixer"
        
        if cCurrentModuleObject not in state.dataInputProcessing.inputProcessor.epJSON:
            return
        
        errorsFound = False
        AirLoopMixerNum = 0
        instancesValue = state.dataInputProcessing.inputProcessor.epJSON[cCurrentModuleObject]
        
        for thisObjectName, fields in instancesValue.items():
            state.dataInputProcessing.inputProcessor.markObjectAsUsed(cCurrentModuleObject, thisObjectName)
            AirLoopMixerNum += 1
            thisMixer = AirLoopMixer()
            
            thisMixer.name = Util.makeUPPER(thisObjectName)
            thisMixer.OutletNodeName = Util.makeUPPER(fields["outlet_node_name"])
            thisMixer.m_AirLoopMixer_Num = AirLoopMixerNum - 1
            thisMixer.OutletNodeNum = Node.GetOnlySingleNode(
                state, thisMixer.OutletNodeName, errorsFound,
                Node.ConnectionObjectType.AirLoopHVACMixer, thisObjectName,
                Node.FluidType.Air, Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary, Node.ObjectIsParent
            )
            
            if "nodes" in fields:
                NodeArray = fields["nodes"]
                thisMixer.numOfInletNodes = len(NodeArray)
                for num, NodeDOASName in enumerate(NodeArray, 1):
                    name = Util.makeUPPER(NodeDOASName["inlet_node_name"])
                    NodeNum = Node.GetOnlySingleNode(
                        state, name, errorsFound,
                        Node.ConnectionObjectType.AirLoopHVACMixer, thisObjectName,
                        Node.FluidType.Air, Node.ConnectionType.Inlet,
                        Node.CompFluidStream.Primary, Node.ObjectIsParent
                    )
                    if NodeNum > 0 and num <= thisMixer.numOfInletNodes:
                        thisMixer.InletNodeName.append(name)
                        thisMixer.InletNodeNum.append(NodeNum)
                    else:
                        cFieldName = "Inlet Node Name"
                        ShowSevereError(state,
                            f'{cCurrentModuleObject}, "{thisMixer.name}" {name} not found: {cFieldName}')
                        errorsFound = True
            
            state.dataAirLoopHVACDOAS.airloopMixer.append(thisMixer)
            
            if thisMixer.numOfInletNodes < 1:
                ShowSevereError(state, f'{cCurrentModuleObject}, "{thisMixer.name}" does not have any inlet nodes.')
                ShowContinueError(state, "All mixers must have at least one inlet node.")
                errorsFound = True
        
        if errorsFound:
            ShowFatalError(state, "getAirLoopMixer: Previous errors cause termination.")

    def CalcAirLoopMixer(self, state: Any) -> None:
        outletTemp = 0.0
        outletHumRat = 0.0
        massSum = 0.0
        
        for i in range(self.numOfInletNodes):
            InletNum = self.InletNodeNum[i]
            massSum += state.dataLoopNodes.Node[InletNum].MassFlowRate
            outletTemp += state.dataLoopNodes.Node[InletNum].MassFlowRate * state.dataLoopNodes.Node[InletNum].Temp
            outletHumRat += state.dataLoopNodes.Node[InletNum].MassFlowRate * state.dataLoopNodes.Node[InletNum].HumRat
        
        if massSum > 0.0:
            state.dataLoopNodes.Node[self.OutletNodeNum].Temp = outletTemp / massSum
            state.dataLoopNodes.Node[self.OutletNodeNum].HumRat = outletHumRat / massSum
            state.dataLoopNodes.Node[self.OutletNodeNum].MassFlowRate = massSum
            state.dataLoopNodes.Node[self.OutletNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(
                outletTemp / massSum, outletHumRat / massSum
            )
            self.OutletTemp = state.dataLoopNodes.Node[self.OutletNodeNum].Temp
        else:
            state.dataLoopNodes.Node[self.OutletNodeNum].Temp = state.dataLoopNodes.Node[self.InletNodeNum[0]].Temp
            state.dataLoopNodes.Node[self.OutletNodeNum].HumRat = state.dataLoopNodes.Node[self.InletNodeNum[0]].HumRat
            state.dataLoopNodes.Node[self.OutletNodeNum].MassFlowRate = 0.0
            state.dataLoopNodes.Node[self.OutletNodeNum].Enthalpy = state.dataLoopNodes.Node[self.InletNodeNum[0]].Enthalpy
            self.OutletTemp = state.dataLoopNodes.Node[self.InletNodeNum[0]].Temp


@dataclass
class AirLoopSplitter:
    name: str = ""
    numOfOutletNodes: int = 0
    m_AirLoopSplitter_Num: int = 0
    InletNodeName: str = ""
    OutletNodeName: List[str] = field(default_factory=list)
    OutletNodeNum: List[int] = field(default_factory=list)
    InletTemp: float = 0.0
    InletNodeNum: int = 0

    @staticmethod
    def factory(state: Any, objectNum: int, objectName: str) -> Optional['AirLoopSplitter']:
        if state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag:
            AirLoopSplitter.getAirLoopSplitter(state)
            state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag = False
        
        SplitterNum = -1
        for dSpec in state.dataAirLoopHVACDOAS.airloopSplitter:
            SplitterNum += 1
            if Util.SameString(dSpec.name, objectName) and dSpec.m_AirLoopSplitter_Num == objectNum:
                return dSpec
        
        ShowSevereError(state, f"AirLoopSplitter factory: Error getting inputs for system named: {objectName}")
        return None

    @staticmethod
    def getAirLoopSplitter(state: Any) -> None:
        cCurrentModuleObject = "AirLoopHVAC:Splitter"
        
        if cCurrentModuleObject not in state.dataInputProcessing.inputProcessor.epJSON:
            return
        
        errorsFound = False
        AirLoopSplitterNum = 0
        instancesValue = state.dataInputProcessing.inputProcessor.epJSON[cCurrentModuleObject]
        
        for thisObjectName, fields in instancesValue.items():
            state.dataInputProcessing.inputProcessor.markObjectAsUsed(cCurrentModuleObject, thisObjectName)
            AirLoopSplitterNum += 1
            thisSplitter = AirLoopSplitter()
            
            thisSplitter.name = Util.makeUPPER(thisObjectName)
            thisSplitter.InletNodeName = Util.makeUPPER(fields["inlet_node_name"])
            thisSplitter.InletNodeNum = Node.GetOnlySingleNode(
                state, thisSplitter.InletNodeName, errorsFound,
                Node.ConnectionObjectType.AirLoopHVACSplitter, thisObjectName,
                Node.FluidType.Air, Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary, Node.ObjectIsParent
            )
            thisSplitter.m_AirLoopSplitter_Num = AirLoopSplitterNum - 1
            
            if "nodes" in fields:
                NodeArray = fields["nodes"]
                thisSplitter.numOfOutletNodes = len(NodeArray)
                for num, NodeDOASName in enumerate(NodeArray, 1):
                    name = Util.makeUPPER(NodeDOASName["outlet_node_name"])
                    NodeNum = Node.GetOnlySingleNode(
                        state, name, errorsFound,
                        Node.ConnectionObjectType.AirLoopHVACSplitter, thisObjectName,
                        Node.FluidType.Air, Node.ConnectionType.Inlet,
                        Node.CompFluidStream.Primary, Node.ObjectIsParent
                    )
                    if NodeNum > 0 and num <= thisSplitter.numOfOutletNodes:
                        thisSplitter.OutletNodeName.append(name)
                        thisSplitter.OutletNodeNum.append(NodeNum)
                    else:
                        cFieldName = "Outlet Node Name"
                        ShowSevereError(state,
                            f'{cCurrentModuleObject}, "{thisSplitter.name}"{cFieldName} not found: {name}')
                        errorsFound = True
            
            state.dataAirLoopHVACDOAS.airloopSplitter.append(thisSplitter)
            
            if thisSplitter.numOfOutletNodes < 1:
                ShowSevereError(state, f'{cCurrentModuleObject}, "{thisSplitter.name}" does not have any outlet nodes.')
                ShowContinueError(state, "All splitters must have at least one outlet node.")
                errorsFound = True
        
        if errorsFound:
            ShowFatalError(state, "getAirLoopSplitter: Previous errors cause termination.")

    def CalcAirLoopSplitter(self, state: Any, Temp: float, HumRat: float) -> None:
        for i in range(self.numOfOutletNodes):
            state.dataLoopNodes.Node[self.OutletNodeNum[i]].Temp = Temp
            state.dataLoopNodes.Node[self.OutletNodeNum[i]].HumRat = HumRat
            state.dataLoopNodes.Node[self.OutletNodeNum[i]].Enthalpy = Psychrometrics.PsyHFnTdbW(Temp, HumRat)
        self.InletTemp = Temp


@dataclass
class AirLoopDOAS:
    SumMassFlowRate: float = 0.0
    PreheatTemp: float = -999.0
    PrecoolTemp: float = -999.0
    PreheatHumRat: float = -999.0
    PrecoolHumRat: float = -999.0
    SizingMassFlow: float = 0.0
    SizingCoolOATemp: float = -999.0
    SizingCoolOAHumRat: float = -999.0
    HeatOutTemp: float = 999.0
    HeatOutHumRat: float = 999.0
    m_AirLoopDOASNum: int = 0
    m_OASystemNum: int = 0
    m_AvailManagerSched: Optional[Any] = None
    m_AirLoopMixerIndex: int = -1
    m_AirLoopSplitterIndex: int = -1
    NumOfAirLoops: int = 0
    m_InletNodeNum: int = 0
    m_OutletNodeNum: int = 0
    m_FanIndex: int = 0
    m_FanInletNodeNum: int = 0
    m_FanOutletNodeNum: int = 0
    m_FanTypeNum: Any = None
    m_exhaustFanUsed: bool = False
    m_exhaustFanIndex: int = -1
    m_exhaustFanInletNodeNum: int = 0
    m_exhaustFanOutletNodeNum: int = 0
    m_exhaustFanTypeNum: Any = None
    m_HeatCoilNum: int = 0
    m_CoolCoilNum: int = 0
    ConveCount: int = 0
    ConveIndex: int = 0
    m_HeatExchangerFlag: bool = False
    SizingOnceFlag: bool = True
    FanBeforeCoolingCoilFlag: bool = False
    m_CompPointerAirLoopMixer: Optional[AirLoopMixer] = None
    m_CompPointerAirLoopSplitter: Optional[AirLoopSplitter] = None
    Name: str = ""
    AvailManagerSchedName: str = ""
    OASystemName: str = ""
    AirLoopMixerName: str = ""
    AirLoopSplitterName: str = ""
    FanName: str = ""
    m_AirLoopNum: List[int] = field(default_factory=list)
    AirLoopName: List[str] = field(default_factory=list)
    m_OACtrlNum: List[int] = field(default_factory=list)
    HWPlantLoc: Optional[Any] = None
    HWCtrlNodeNum: int = 0
    CWPlantLoc: Optional[Any] = None
    CWCtrlNodeNum: int = 0
    MyEnvrnFlag: bool = True

    @staticmethod
    def getAirLoopDOASInput(state: Any) -> None:
        pass

    def SimAirLoopHVACDOAS(self, state: Any, firstHVACIteration: bool, CompIndex: List[int]) -> None:
        if state.dataAirLoopHVACDOAS.GetInputOnceFlag:
            getAirLoopDOASInput(state)
            state.dataAirLoopHVACDOAS.GetInputOnceFlag = False
        
        if CompIndex[0] == -1:
            CompIndex[0] = self.m_AirLoopDOASNum
        
        if self.SizingOnceFlag:
            self.SizingAirLoopDOAS(state)
            self.SizingOnceFlag = False
        
        self.initAirLoopDOAS(state, firstHVACIteration)
        
        if self.SumMassFlowRate == 0.0 and not state.dataGlobal.BeginEnvrnFlag:
            state.dataLoopNodes.Node[self.m_CompPointerAirLoopMixer.OutletNodeNum].MassFlowRate = 0.0
        
        self.CalcAirLoopDOAS(state, firstHVACIteration)

    def initAirLoopDOAS(self, state: Any, FirstHVACIteration: bool) -> None:
        RoutineName = "AirLoopDOAS::initAirLoopDOAS"
        
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            ErrorsFound = False
            rho = 0.0
            for CompNum in range(1, state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].NumComponents + 1):
                CompType = state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].ComponentType[CompNum - 1]
                CompName = state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].ComponentName[CompNum - 1]
                
                if Util.SameString(CompType, "FAN:SYSTEMMODEL"):
                    state.dataFans.fans[self.m_FanIndex].simulate(state, FirstHVACIteration)
                if Util.SameString(CompType, "FAN:COMPONENTMODEL"):
                    state.dataFans.fans[self.m_FanIndex].simulate(state, FirstHVACIteration)
                
                if Util.SameString(CompType, "COIL:HEATING:WATER"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_HeatCoilNum)
                    CoilMaxVolFlowRate = WaterCoils.GetCoilMaxWaterFlowRate(state, "Coil:Heating:Water", CompName, ErrorsFound)
                    rho = self.HWPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                    PlantUtilities.InitComponentNodes(
                        state, 0.0, CoilMaxVolFlowRate * rho, self.HWCtrlNodeNum,
                        state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].OutletNodeNum[CompNum - 1]
                    )
                
                if Util.SameString(CompType, "COIL:COOLING:WATER"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_CoolCoilNum)
                    CoilMaxVolFlowRate = WaterCoils.GetCoilMaxWaterFlowRate(state, "Coil:Cooling:Water", CompName, ErrorsFound)
                    rho = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                    PlantUtilities.InitComponentNodes(
                        state, 0.0, CoilMaxVolFlowRate * rho, self.CWCtrlNodeNum,
                        state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].OutletNodeNum[CompNum - 1]
                    )
                
                if Util.SameString(CompType, "COIL:COOLING:WATER:DETAILEDGEOMETRY"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_CoolCoilNum)
                    CoilMaxVolFlowRate = WaterCoils.GetCoilMaxWaterFlowRate(
                        state, "Coil:Cooling:Water:DetailedGeometry", CompName, ErrorsFound
                    )
                    rho = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                    PlantUtilities.InitComponentNodes(
                        state, 0.0, CoilMaxVolFlowRate * rho, self.CWCtrlNodeNum,
                        state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].OutletNodeNum[CompNum - 1]
                    )
            
            self.MyEnvrnFlag = False
            if ErrorsFound:
                ShowFatalError(state, "initAirLoopDOAS: Previous errors cause termination.")
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        
        self.SumMassFlowRate = 0.0
        
        for LoopOA in range(self.m_CompPointerAirLoopSplitter.numOfOutletNodes):
            NodeNum = self.m_CompPointerAirLoopSplitter.OutletNodeNum[LoopOA]
            self.SumMassFlowRate += state.dataLoopNodes.Node[NodeNum].MassFlowRate
        
        SchAvailValue = self.m_AvailManagerSched.getCurrentVal()
        if SchAvailValue < 1.0:
            self.SumMassFlowRate = 0.0
        
        state.dataLoopNodes.Node[self.m_InletNodeNum].MassFlowRate = self.SumMassFlowRate

    def CalcAirLoopDOAS(self, state: Any, FirstHVACIteration: bool) -> None:
        self.m_CompPointerAirLoopMixer.CalcAirLoopMixer(state)
        
        if self.m_FanIndex > 0:
            if self.m_FanInletNodeNum == self.m_InletNodeNum:
                state.dataLoopNodes.Node[self.m_FanInletNodeNum].MassFlowRateMaxAvail = self.SumMassFlowRate
                state.dataLoopNodes.Node[self.m_FanOutletNodeNum].MassFlowRateMaxAvail = self.SumMassFlowRate
                state.dataLoopNodes.Node[self.m_FanOutletNodeNum].MassFlowRateMax = self.SumMassFlowRate
            else:
                state.dataLoopNodes.Node[self.m_InletNodeNum].MassFlowRateMax = self.SumMassFlowRate
                state.dataLoopNodes.Node[self.m_InletNodeNum].MassFlowRateMaxAvail = self.SumMassFlowRate
        
        if self.m_exhaustFanUsed:
            state.dataLoopNodes.Node[self.m_exhaustFanInletNodeNum].MassFlowRateMaxAvail = self.SumMassFlowRate
            state.dataLoopNodes.Node[self.m_exhaustFanOutletNodeNum].MassFlowRateMaxAvail = self.SumMassFlowRate
            state.dataLoopNodes.Node[self.m_exhaustFanOutletNodeNum].MassFlowRateMax = self.SumMassFlowRate
        
        MixedAir.ManageOutsideAirSystem(state, self.OASystemName, FirstHVACIteration, 0, self.m_OASystemNum)
        
        Temp = state.dataLoopNodes.Node[self.m_OutletNodeNum].Temp
        HumRat = state.dataLoopNodes.Node[self.m_OutletNodeNum].HumRat
        state.dataLoopNodes.Node[self.m_OutletNodeNum].Enthalpy = Psychrometrics.PsyHFnTdbW(Temp, HumRat)
        
        self.m_CompPointerAirLoopSplitter.CalcAirLoopSplitter(state, Temp, HumRat)

    def SizingAirLoopDOAS(self, state: Any) -> None:
        sizingVolumeFlow = 0.0
        
        for AirLoop in range(1, self.NumOfAirLoops + 1):
            AirLoopNum = self.m_AirLoopNum[AirLoop - 1]
            self.m_OACtrlNum.append(state.dataAirLoop.AirLoopControlInfo[AirLoopNum - 1].OACtrlNum)
            
            if self.m_OACtrlNum[AirLoop - 1] > 0:
                sizingVolumeFlow += state.dataMixedAir.OAController[self.m_OACtrlNum[AirLoop - 1] - 1].MaxOA
        
        self.SizingMassFlow = sizingVolumeFlow * state.dataEnvrn.StdRhoAir
        
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Volume Flow Rate [m3/s]", sizingVolumeFlow)
        self.GetDesignDayConditions(state)
        
        if self.m_FanIndex > 0 and (self.m_FanTypeNum == SimAirServingZones.CompType.Fan_System_Object or
                                      self.m_FanTypeNum == SimAirServingZones.CompType.Fan_ComponentModel):
            supplyFanVolFlow = state.dataFans.fans[self.m_FanIndex].maxAirFlowRate
            if supplyFanVolFlow != DataSizing.AutoSize:
                if abs((supplyFanVolFlow - sizingVolumeFlow) / sizingVolumeFlow) > 0.01:
                    ShowWarningError(state, f"AirLoopHVAC:DedicatedOutdoorAirSystem = {self.Name}.")
                    ShowContinueError(state,
                        f"The supply fan = {state.dataFans.fans[self.m_FanIndex].Name} has a volumetric air flow rate = {supplyFanVolFlow} m3/s.")
                    ShowContinueError(state,
                        f"The AirLoopHVAC:DedicatedOutdoorAirSystem Design Volume Flow Rate = {sizingVolumeFlow} m3/s.")
                    ShowContinueError(state, "Consider autosizing the supply fan Maximum Air Flow Rate.")
            else:
                state.dataFans.fans[self.m_FanIndex].maxAirFlowRate = sizingVolumeFlow
                state.dataLoopNodes.Node[self.m_FanInletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                state.dataLoopNodes.Node[self.m_FanOutletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                state.dataLoopNodes.Node[self.m_FanOutletNodeNum].MassFlowRateMax = self.SizingMassFlow
                if self.m_FanTypeNum == SimAirServingZones.CompType.Fan_ComponentModel:
                    state.dataFans.fans[self.m_FanIndex].minAirFlowRate = 0.0
                    state.dataFans.fans[self.m_FanIndex].maxAirMassFlowRate = self.SizingMassFlow
        
        if self.m_exhaustFanUsed:
            if self.m_exhaustFanIndex > 0 and (self.m_exhaustFanTypeNum == SimAirServingZones.CompType.Fan_System_Object or
                                                 self.m_exhaustFanTypeNum == SimAirServingZones.CompType.Fan_ComponentModel):
                exhaustFanVolFlow = state.dataFans.fans[self.m_exhaustFanIndex].maxAirFlowRate
                if exhaustFanVolFlow != DataSizing.AutoSize:
                    if abs((exhaustFanVolFlow - sizingVolumeFlow) / sizingVolumeFlow) > 0.01:
                        ShowWarningError(state, f"AirLoopHVAC:DedicatedOutdoorAirSystem = {self.Name}.")
                        ShowContinueError(state,
                            f"The exhaust fan = {state.dataFans.fans[self.m_exhaustFanIndex].Name} has a volumetric air flow rate = {exhaustFanVolFlow} m3/s.")
                        ShowContinueError(state,
                            f"The AirLoopHVAC:DedicatedOutdoorAirSystem Design Volume Flow Rate = {sizingVolumeFlow} m3/s.")
                        ShowContinueError(state, "Consider autosizing the exhaust fan Maximum Air Flow Rate.")
                else:
                    state.dataFans.fans[self.m_exhaustFanIndex].maxAirFlowRate = sizingVolumeFlow
                    state.dataLoopNodes.Node[self.m_exhaustFanInletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                    state.dataLoopNodes.Node[self.m_exhaustFanOutletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                    state.dataLoopNodes.Node[self.m_exhaustFanOutletNodeNum].MassFlowRateMax = self.SizingMassFlow
                    if self.m_FanTypeNum == SimAirServingZones.CompType.Fan_ComponentModel:
                        state.dataFans.fans[self.m_exhaustFanIndex].minAirFlowRate = 0.0
                        state.dataFans.fans[self.m_exhaustFanIndex].maxAirMassFlowRate = self.SizingMassFlow
        
        state.dataSize.CurSysNum = state.dataHVACGlobal.NumPrimaryAirSys + self.m_AirLoopDOASNum + 1
        state.dataSize.CurOASysNum = self.m_OASystemNum

    def GetDesignDayConditions(self, state: Any) -> None:
        for env in state.dataWeather.Environment:
            if env.KindOfEnvrn != Constant.KindOfSim.DesignDay and env.KindOfEnvrn != Constant.KindOfSim.RunPeriodDesign:
                continue
            
            if env.maxCoolingOATSizing > self.SizingCoolOATemp:
                self.SizingCoolOATemp = env.maxCoolingOATSizing
                if env.KindOfEnvrn == Constant.KindOfSim.DesignDay and state.dataWeather.DesDayInput[env.DesignDayNum].PressureEntered:
                    self.SizingCoolOAHumRat = Psychrometrics.PsyWFnTdpPb(
                        state, env.maxCoolingOADPSizing, state.dataWeather.DesDayInput[env.DesignDayNum].PressBarom
                    )
                else:
                    self.SizingCoolOAHumRat = Psychrometrics.PsyWFnTdpPb(state, env.maxCoolingOADPSizing, state.dataEnvrn.StdBaroPress)
            
            if env.minHeatingOATSizing < self.HeatOutTemp:
                self.HeatOutTemp = env.minHeatingOATSizing
                if env.KindOfEnvrn == Constant.KindOfSim.DesignDay and state.dataWeather.DesDayInput[env.DesignDayNum].PressureEntered:
                    self.HeatOutHumRat = Psychrometrics.PsyWFnTdpPb(
                        state, env.minHeatingOADPSizing, state.dataWeather.DesDayInput[env.DesignDayNum].PressBarom
                    )
                else:
                    self.HeatOutHumRat = Psychrometrics.PsyWFnTdpPb(state, env.minHeatingOADPSizing, state.dataEnvrn.StdBaroPress)
        
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Cooling Outdoor Air Temperature [C]", self.SizingCoolOATemp)
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Cooling Outdoor Air Humidity Ratio [kgWater/kgDryAir]", self.SizingCoolOAHumRat)
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Heating Outdoor Air Temperature [C]", self.HeatOutTemp)
        BaseSizer.reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name,
                                     "Design Heating Outdoor Air Humidity Ratio [kgWater/kgDryAir]", self.HeatOutHumRat)


def getAirLoopMixerIndex(state: Any, objectName: str) -> int:
    if state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag:
        AirLoopMixer.getAirLoopMixer(state)
        state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag = False
    
    index = -1
    for loop, thisAirLoopMixerObject in enumerate(state.dataAirLoopHVACDOAS.airloopMixer):
        if Util.SameString(objectName, thisAirLoopMixerObject.name):
            index = loop
            return index
    
    ShowSevereError(state, f"getAirLoopMixer: did not find AirLoopHVAC:Mixer name ={objectName}. Check inputs")
    return index


def getAirLoopSplitterIndex(state: Any, objectName: str) -> int:
    if state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag:
        AirLoopSplitter.getAirLoopSplitter(state)
        state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag = False
    
    index = -1
    for loop, thisAirLoopSplitterObj in enumerate(state.dataAirLoopHVACDOAS.airloopSplitter):
        if Util.SameString(objectName, thisAirLoopSplitterObj.name):
            index = loop
            return index
    
    ShowSevereError(state, f"getAirLoopSplitter: did not find AirLoopSplitter name ={objectName}. Check inputs")
    return index


def getAirLoopHVACDOASInput(state: Any) -> None:
    pass


_DOAS_input_impl_in_structure = True


def CheckConvergence(state: Any) -> None:
    for loop in state.dataAirLoopHVACDOAS.airloopDOAS:
        maxDiff = 0.0
        Diff = abs(loop.m_CompPointerAirLoopSplitter.InletTemp -
                   state.dataLoopNodes.Node[loop.m_CompPointerAirLoopSplitter.OutletNodeNum[0]].Temp)
        if Diff > maxDiff:
            maxDiff = Diff
        
        if loop.m_HeatExchangerFlag:
            OldTemp = loop.m_CompPointerAirLoopMixer.OutletTemp
            loop.m_CompPointerAirLoopMixer.CalcAirLoopMixer(state)
            Diff = abs(OldTemp - loop.m_CompPointerAirLoopMixer.OutletTemp)
            if Diff > maxDiff:
                maxDiff = Diff
        
        if maxDiff > 1.0e-6:
            if loop.ConveCount == 0:
                loop.ConveCount += 1
                ShowWarningError(state, f"Convergence limit is above 1.0e-6 for unit={loop.Name}")
                ShowContinueErrorTimeStamp(state,
                    f"The max difference of node temperatures between AirLoopDOAS outlet and OA mixer inlet ={maxDiff:.6f}")
            else:
                loop.ConveCount += 1
                ShowRecurringWarningErrorAtEnd(state,
                    f'"{loop.Name}": The max difference of node temperatures exceeding 1.0e-6  continues...',
                    loop.ConveIndex, maxDiff, maxDiff)


# Stubs for external modules and functions (to be wired in):
class Util:
    @staticmethod
    def SameString(s1: str, s2: str) -> bool:
        pass

    @staticmethod
    def makeUPPER(s: str) -> str:
        pass

    @staticmethod
    def FindItemInList(name: str, lst: List[Any]) -> int:
        pass


class Node:
    class ConnectionObjectType:
        AirLoopHVACMixer = 0
        AirLoopHVACSplitter = 1

    class FluidType:
        Air = 0

    class ConnectionType:
        Inlet = 0
        Outlet = 1

    class CompFluidStream:
        Primary = 0

    class ObjectIsParent:
        pass

    @staticmethod
    def GetOnlySingleNode(state: Any, name: str, errorsFound: bool, *args) -> int:
        pass

    @staticmethod
    def SetUpCompSets(state: Any, *args) -> None:
        pass


class Psychrometrics:
    @staticmethod
    def PsyHFnTdbW(tdb: float, w: float) -> float:
        pass

    @staticmethod
    def PsyWFnTdpPb(state: Any, tdp: float, pb: float) -> float:
        pass


class MixedAir:
    @staticmethod
    def ManageOutsideAirSystem(state: Any, name: str, firstHVAC: bool, unknown: int, oasysnum: int) -> None:
        pass


class WaterCoils:
    @staticmethod
    def GetCoilInletNode(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetCoilOutletNode(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetCoilWaterInletNode(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetCoilMaxWaterFlowRate(state: Any, *args) -> float:
        pass

    @staticmethod
    def SimulateWaterCoilComponents(state: Any, *args) -> None:
        pass


class Fans:
    @staticmethod
    def GetFanIndex(state: Any, name: str) -> int:
        pass


class PlantUtilities:
    @staticmethod
    def InitComponentNodes(state: Any, *args) -> None:
        pass

    @staticmethod
    def ScanPlantLoopsForObject(state: Any, *args) -> None:
        pass


class HeatingCoils:
    @staticmethod
    def GetCoilInletNode(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetCoilOutletNode(state: Any, *args) -> int:
        pass


class HVACHXAssistedCoolingCoil:
    @staticmethod
    def GetCoilInletNode(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetCoilOutletNode(state: Any, *args) -> int:
        pass


class HVACDXHeatPumpSystem:
    @staticmethod
    def GetHeatingCoilInletNodeNum(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetHeatingCoilOutletNodeNum(state: Any, *args) -> int:
        pass


class HeatRecovery:
    @staticmethod
    def GetSupplyInletNode(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetSupplyOutletNode(state: Any, *args) -> int:
        pass


class DesiccantDehumidifiers:
    @staticmethod
    def GetProcAirInletNodeNum(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetProcAirOutletNodeNum(state: Any, *args) -> int:
        pass


class Humidifiers:
    @staticmethod
    def GetAirInletNodeNum(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetAirOutletNodeNum(state: Any, *args) -> int:
        pass


class TranspiredCollector:
    @staticmethod
    def GetAirInletNodeNum(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetAirOutletNodeNum(state: Any, *args) -> int:
        pass


class PhotovoltaicThermalCollectors:
    @staticmethod
    def GetAirInletNodeNum(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetAirOutletNodeNum(state: Any, *args) -> int:
        pass


class EvaporativeCoolers:
    @staticmethod
    def GetInletNodeNum(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetOutletNodeNum(state: Any, *args) -> int:
        pass


class HVACVariableRefrigerantFlow:
    @staticmethod
    def GetVRFTUInAirNodeFromName(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetVRFTUOutAirNodeFromName(state: Any, *args) -> int:
        pass


class SteamCoils:
    @staticmethod
    def GetCoilSteamInletNode(state: Any, *args) -> int:
        pass

    @staticmethod
    def GetCoilSteamOutletNode(state: Any, *args) -> int:
        pass


class UnitarySystems:
    @staticmethod
    def factory(state: Any, *args):
        pass


class OutAirNodeManager:
    @staticmethod
    def CheckOutAirNodeNumber(state: Any, *args) -> bool:
        pass


class BaseSizer:
    @staticmethod
    def reportSizerOutput(state: Any, *args) -> None:
        pass


class SimAirServingZones:
    class CompType:
        Invalid = -1
        Fan_System_Object = 0
        Fan_ComponentModel = 1


class DataPlant:
    class PlantEquipmentType:
        CoilWaterCooling = 0
        CoilWaterSimpleHeating = 1
        CoilWaterDetailedFlatCooling = 2


class Constant:
    HWInitConvTemp = 60.0
    CWInitConvTemp = 6.0
    
    class KindOfSim:
        DesignDay = 1
        RunPeriodDesign = 2


class DataSizing:
    AutoSize = -99999.0


class Sched:
    class Schedule:
        def getCurrentVal(self) -> float:
            pass

    @staticmethod
    def GetSchedule(state: Any, name: str) -> Optional[Schedule]:
        pass


def ShowSevereError(state: Any, msg: str) -> None:
    pass


def ShowFatalError(state: Any, msg: str) -> None:
    pass


def ShowContinueError(state: Any, msg: str) -> None:
    pass


def ShowWarningError(state: Any, msg: str) -> None:
    pass


def ShowSevereItemNotFound(state: Any, eoh: Any, item_type: str, name: str) -> None:
    pass


def ShowContinueErrorTimeStamp(state: Any, msg: str) -> None:
    pass


def ShowRecurringWarningErrorAtEnd(state: Any, msg: str, index: int, val1: float, val2: float) -> None:
    pass

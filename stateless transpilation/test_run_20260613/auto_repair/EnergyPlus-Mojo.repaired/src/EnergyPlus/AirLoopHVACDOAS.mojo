from UtilityRoutines import SameString, makeUPPER, FindItemInList, ShowSevereError, ShowContinueError, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, ShowFatalError, ShowWarningError
from Data.EnergyPlusData import EnergyPlusData
from DataAirLoop import OutsideAirSys, AirLoopControlInfo, NumOASystems
from DataAirSystems import PrimaryAirSystems
from DataEnvironment import StdRhoAir, StdBaroPress
from DataLoopNode import Node, NodeID, GetOnlySingleNode, SetUpCompSets
from DataSizing import AutoSize, CurSysNum, CurOASysNum, NumPrimaryAirSys
from DataGlobal import BeginEnvrnFlag, KindOfSim
from DataPlant import PlantEquipmentType
from Plant.PlantLocation import PlantLocation
from Psychrometrics import PsyHFnTdbW, PsyWFnTdpPb
from Fans import GetFanIndex
from WaterCoils import SimulateWaterCoilComponents, GetCoilInletNode, GetCoilOutletNode, GetCoilWaterInletNode, GetCoilMaxWaterFlowRate
from HeatingCoils import GetCoilInletNode as HeatingCoilsInlet, GetCoilOutletNode as HeatingCoilsOutlet
from SteamCoils import GetCoilSteamInletNode, GetCoilSteamOutletNode
from MixedAir import ManageOutsideAirSystem, OAController
from SimAirServingZones import CompType
from PlantUtilities import ScanPlantLoopsForObject, InitComponentNodes
from NodeInputManager import (nothing? assume already imported)
from OutAirNodeManager import CheckOutAirNodeNumber
from ScheduleManager import GetSchedule as SchedGetSchedule, Schedule
from InputProcessing.InputProcessor import (nothing? assume already imported)
from HeatRecovery import GetSupplyInletNode, GetSupplyOutletNode
from DesiccantDehumidifiers import GetProcAirInletNodeNum, GetProcAirOutletNodeNum
from EvaporativeCoolers import GetInletNodeNum, GetOutletNodeNum
from Humidifiers import GetAirInletNodeNum, GetAirOutletNodeNum
from TranspiredCollector import GetAirInletNodeNum as TranspiredInlet, GetAirOutletNodeNum as TranspiredOutlet
from PhotovoltaicThermalCollectors import GetAirInletNodeNum as PVTInlet, GetAirOutletNodeNum as PVTOutlet
from HVACHXAssistedCoolingCoil import GetCoilInletNode as HXAssistedInlet, GetCoilOutletNode as HXAssistedOutlet
from HVACDXHeatPumpSystem import GetHeatingCoilInletNodeNum, GetHeatingCoilOutletNodeNum
from HVACVariableRefrigerantFlow import GetVRFTUInAirNodeFromName, GetVRFTUOutAirNodeFromName
from UnitarySystem import UnitarySys, UnitarySysType
from Autosizing.Base import reportSizerOutput
from Constant import HWInitConvTemp, CWInitConvTemp, KindOfSim, StdRhoAir, StdBaroPress
from WeatherManager import DesDayInput, Environment
from Fans import fans
from BranchNodeConnections import (nothing specific used)
from FluidProperties import (nothing specific used)
import "DataGlobal" as DataGlobal
enum ValidEquipListType:
    Invalid = -1
    OutdoorAirMixer
    FanConstantVolume
    FanVariableVolume
    FanSystemModel
    FanComponentModel
    CoilCoolingWater
    CoilHeatingWater
    CoilHeatingSteam
    CoilCoolingWaterDetailedGeometry
    CoilHeatingElectric
    CoilHeatingFuel
    CoilSystemCoolingWaterHeatExchangerAssisted
    CoilSystemCoolingDX
    CoilSystemHeatingDX
    AirLoopHVACUnitarySystem
    CoilUserDefined
    HeatExchangerAirToAirFlatPlate
    HeatExchangerAirToAirSensibleAndLatent
    HeatExchangerDesiccantBalancedFlow
    DehumidifierDesiccantNoFans
    DehumidifierDesiccantSystem
    HumidifierSteamElectric
    HumidifierSteamGas
    SolarCollectorUnglazedTranspired
    SolarCollectorFlatPlatePhotovoltaicThermal
    EvaporativeCoolerDirectCeldekPad
    EvaporativeCoolerIndirectCeldekPad
    EvaporativeCoolerIndirectWetCoil
    EvaporativeCoolerIndirectResearchSpecial
    EvaporativeCoolerDirectResearchSpecial
    ZoneHVACTerminalUnitVariableRefrigerantFlow
    Num
validEquipNamesUC: List[String] = [
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
def getEnumValue(names: List[String], name: String) -> Int:
    for i in range(len(names)):
        if names[i] == name:
            return i
    return -1
struct AirLoopMixer:
    var name: String = ""
    var numOfInletNodes: Int = 0
    var m_AirLoopMixer_Num: Int = 0
    var OutletNodeNum: Int = 0
    var OutletNodeName: String = ""
    var InletNodeName: List[String] = List[String]()
    var InletNodeNum: List[Int] = List[Int]()
    var OutletTemp: Float64 = 0.0
    @staticmethod
    def factory(inout state: EnergyPlusData, objectNum: Int, objectName: String) -> Self:
        if state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag:
            AirLoopMixer.getAirLoopMixer(state)
            state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag = False
        var MixerNum: Int = 0
        for dSpec in state.dataAirLoopHVACDOAS.airloopMixer:
            if SameString(dSpec.name, objectName) and dSpec.m_AirLoopMixer_Num == objectNum:
                return dSpec
            MixerNum += 1
        ShowSevereError(state, f"AirLoopMixer factory: Error getting inputs for system named: {objectName}")
        return Self{}
    @staticmethod
    def getAirLoopMixer(inout state: EnergyPlusData):
        let cCurrentModuleObject: String = "AirLoopHVAC:Mixer"
        let instances = state.dataInputProcessing.inputProcessor.epJSON.find(cCurrentModuleObject)
        if instances != state.dataInputProcessing.inputProcessor.epJSON.end():
            var errorsFound: Bool = False
            var AirLoopMixerNum: Int = 0
            let instancesValue = instances.value()
            for instance in instancesValue:
                let fields = instance.value()
                let thisObjectName: String = instance.key()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(cCurrentModuleObject, thisObjectName)
                AirLoopMixerNum += 1
                var thisMixer: AirLoopMixer = AirLoopMixer{}
                thisMixer.name = makeUPPER(thisObjectName)
                thisMixer.OutletNodeName = makeUPPER(fields["outlet_node_name"].get(String))
                thisMixer.m_AirLoopMixer_Num = AirLoopMixerNum - 1
                thisMixer.OutletNodeNum = Node.GetOnlySingleNode(
                    state, thisMixer.OutletNodeName, errorsFound,
                    Node.ConnectionObjectType.AirLoopHVACMixer, thisObjectName,
                    Node.FluidType.Air, Node.ConnectionType.Outlet,
                    Node.CompFluidStream.Primary, Node.ObjectIsParent)
                let NodeNames = fields.find("nodes")
                if NodeNames != fields.end():
                    let NodeArray = NodeNames.value()
                    thisMixer.numOfInletNodes = len(NodeArray)
                    var num: Int = 0
                    for NodeDOASName in NodeArray:
                        num += 1
                        let name: String = makeUPPER(NodeDOASName["inlet_node_name"].get(String))
                        let NodeNum: Int = Node.GetOnlySingleNode(
                            state, name, errorsFound,
                            Node.ConnectionObjectType.AirLoopHVACMixer, thisObjectName,
                            Node.FluidType.Air, Node.ConnectionType.Inlet,
                            Node.CompFluidStream.Primary, Node.ObjectIsParent)
                        if NodeNum > 0 and num <= thisMixer.numOfInletNodes:
                            thisMixer.InletNodeName.append(name)
                            thisMixer.InletNodeNum.append(NodeNum)
                        else:
                            var cFieldName: String = "Inlet Node Name"
                            ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisMixer.name}\" {name} not found: {cFieldName}")
                            errorsFound = True
                state.dataAirLoopHVACDOAS.airloopMixer.append(thisMixer)
                if thisMixer.numOfInletNodes < 1:
                    ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisMixer.name}\" does not have any inlet nodes.")
                    ShowContinueError(state, "All mixers must have at least one inlet node.")
                    errorsFound = True
            if errorsFound:
                ShowFatalError(state, "getAirLoopMixer: Previous errors cause termination.")
    def CalcAirLoopMixer(inout self, inout state: EnergyPlusData):
        var outletTemp: Float64 = 0.0
        var outletHumRat: Float64 = 0.0
        var massSum: Float64 = 0.0
        for i in range(self.numOfInletNodes):
            let InletNum: Int = self.InletNodeNum[i]
            massSum += state.dataLoopNodes.Node[InletNum].MassFlowRate
            outletTemp += state.dataLoopNodes.Node[InletNum].MassFlowRate * state.dataLoopNodes.Node[InletNum].Temp
            outletHumRat += state.dataLoopNodes.Node[InletNum].MassFlowRate * state.dataLoopNodes.Node[InletNum].HumRat
        if massSum > 0.0:
            state.dataLoopNodes.Node[self.OutletNodeNum].Temp = outletTemp / massSum
            state.dataLoopNodes.Node[self.OutletNodeNum].HumRat = outletHumRat / massSum
            state.dataLoopNodes.Node[self.OutletNodeNum].MassFlowRate = massSum
            state.dataLoopNodes.Node[self.OutletNodeNum].Enthalpy = PsyHFnTdbW(outletTemp / massSum, outletHumRat / massSum)
            self.OutletTemp = state.dataLoopNodes.Node[self.OutletNodeNum].Temp
        else:
            state.dataLoopNodes.Node[self.OutletNodeNum].Temp = state.dataLoopNodes.Node[self.InletNodeNum[0]].Temp
            state.dataLoopNodes.Node[self.OutletNodeNum].HumRat = state.dataLoopNodes.Node[self.InletNodeNum[0]].HumRat
            state.dataLoopNodes.Node[self.OutletNodeNum].MassFlowRate = 0.0
            state.dataLoopNodes.Node[self.OutletNodeNum].Enthalpy = state.dataLoopNodes.Node[self.InletNodeNum[0]].Enthalpy
            self.OutletTemp = state.dataLoopNodes.Node[self.InletNodeNum[0]].Temp
struct AirLoopSplitter:
    var name: String = ""
    var numOfOutletNodes: Int = 0
    var m_AirLoopSplitter_Num: Int = 0
    var InletNodeName: String = ""
    var OutletNodeName: List[String] = List[String]()
    var OutletNodeNum: List[Int] = List[Int]()
    var InletTemp: Float64 = 0.0
    var InletNodeNum: Int = 0
    @staticmethod
    def factory(inout state: EnergyPlusData, objectNum: Int, objectName: String) -> Self:
        if state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag:
            AirLoopSplitter.getAirLoopSplitter(state)
            state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag = False
        var SplitterNum: Int = 0
        for dSpec in state.dataAirLoopHVACDOAS.airloopSplitter:
            if SameString(dSpec.name, objectName) and dSpec.m_AirLoopSplitter_Num == objectNum:
                return dSpec
            SplitterNum += 1
        ShowSevereError(state, f"AirLoopSplitter factory: Error getting inputs for system named: {objectName}")
        return Self{}
    @staticmethod
    def getAirLoopSplitter(inout state: EnergyPlusData):
        let cCurrentModuleObject: String = "AirLoopHVAC:Splitter"
        let instances = state.dataInputProcessing.inputProcessor.epJSON.find(cCurrentModuleObject)
        if instances != state.dataInputProcessing.inputProcessor.epJSON.end():
            var errorsFound: Bool = False
            var AirLoopSplitterNum: Int = 0
            let instancesValue = instances.value()
            for instance in instancesValue:
                let fields = instance.value()
                let thisObjectName: String = instance.key()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(cCurrentModuleObject, thisObjectName)
                AirLoopSplitterNum += 1
                var thisSplitter: AirLoopSplitter = AirLoopSplitter{}
                thisSplitter.name = makeUPPER(thisObjectName)
                thisSplitter.InletNodeName = makeUPPER(fields["inlet_node_name"].get(String))
                thisSplitter.InletNodeNum = Node.GetOnlySingleNode(
                    state, thisSplitter.InletNodeName, errorsFound,
                    Node.ConnectionObjectType.AirLoopHVACSplitter, thisObjectName,
                    Node.FluidType.Air, Node.ConnectionType.Inlet,
                    Node.CompFluidStream.Primary, Node.ObjectIsParent)
                thisSplitter.m_AirLoopSplitter_Num = AirLoopSplitterNum - 1
                let NodeNames = fields.find("nodes")
                if NodeNames != fields.end():
                    let NodeArray = NodeNames.value()
                    thisSplitter.numOfOutletNodes = len(NodeArray)
                    var num: Int = 0
                    for NodeDOASName in NodeArray:
                        num += 1
                        let name: String = makeUPPER(NodeDOASName["outlet_node_name"].get(String))
                        let NodeNum: Int = Node.GetOnlySingleNode(
                            state, name, errorsFound,
                            Node.ConnectionObjectType.AirLoopHVACSplitter, thisObjectName,
                            Node.FluidType.Air, Node.ConnectionType.Inlet,
                            Node.CompFluidStream.Primary, Node.ObjectIsParent)
                        if NodeNum > 0 and num <= thisSplitter.numOfOutletNodes:
                            thisSplitter.OutletNodeName.append(name)
                            thisSplitter.OutletNodeNum.append(NodeNum)
                        else:
                            var cFieldName: String = "Outlet Node Name"
                            ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisSplitter.name}\"{cFieldName} not found: {name}")
                            errorsFound = True
                state.dataAirLoopHVACDOAS.airloopSplitter.append(thisSplitter)
                if thisSplitter.numOfOutletNodes < 1:
                    ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisSplitter.name}\" does not have any outlet nodes.")
                    ShowContinueError(state, "All splitters must have at least one outlet node.")
                    errorsFound = True
            if errorsFound:
                ShowFatalError(state, "getAirLoopSplitter: Previous errors cause termination.")
    def CalcAirLoopSplitter(borrowed self, state: EnergyPlusData, Temp: Float64, HumRat: Float64):
        for i in range(self.numOfOutletNodes):
            state.dataLoopNodes.Node[self.OutletNodeNum[i]].Temp = Temp
            state.dataLoopNodes.Node[self.OutletNodeNum[i]].HumRat = HumRat
            state.dataLoopNodes.Node[self.OutletNodeNum[i]].Enthalpy = PsyHFnTdbW(Temp, HumRat)
        self.InletTemp = Temp
struct AirLoopDOAS:
    var SumMassFlowRate: Float64 = 0.0
    var PreheatTemp: Float64 = -999.0
    var PrecoolTemp: Float64 = -999.0
    var PreheatHumRat: Float64 = -999.0
    var PrecoolHumRat: Float64 = -999.0
    var SizingMassFlow: Float64 = 0.0
    var SizingCoolOATemp: Float64 = -999.0
    var SizingCoolOAHumRat: Float64 = -999.0
    var HeatOutTemp: Float64 = 999.0
    var HeatOutHumRat: Float64 = 999.0
    var m_AirLoopDOASNum: Int = 0
    var m_OASystemNum: Int = 0
    var m_AvailManagerSched: Schedule = None
    var m_AirLoopMixerIndex: Int = -1
    var m_AirLoopSplitterIndex: Int = -1
    var NumOfAirLoops: Int = 0
    var m_InletNodeNum: Int = 0
    var m_OutletNodeNum: Int = 0
    var m_FanIndex: Int = 0
    var m_FanInletNodeNum: Int = 0
    var m_FanOutletNodeNum: Int = 0
    var m_FanTypeNum: CompType = CompType.Invalid
    var m_exhaustFanUsed: Bool = False
    var m_exhaustFanIndex: Int = -1
    var m_exhaustFanInletNodeNum: Int = 0
    var m_exhaustFanOutletNodeNum: Int = 0
    var m_exhaustFanTypeNum: CompType = CompType.Invalid
    var m_HeatCoilNum: Int = 0
    var m_CoolCoilNum: Int = 0
    var ConveCount: Int = 0
    var ConveIndex: Int = 0
    var m_HeatExchangerFlag: Bool = False
    var SizingOnceFlag: Bool = True
    var FanBeforeCoolingCoilFlag: Bool = False
    var m_CompPointerAirLoopMixer: AirLoopMixer = None
    var m_CompPointerAirLoopSplitter: AirLoopSplitter = None
    var Name: String = ""
    var AvailManagerSchedName: String = ""
    var OASystemName: String = ""
    var AirLoopMixerName: String = ""
    var AirLoopSplitterName: String = ""
    var FanName: String = ""
    var m_AirLoopNum: List[Int] = List[Int]()
    var AirLoopName: List[String] = List[String]()
    var m_OACtrlNum: List[Int] = List[Int]()
    var HWPlantLoc: PlantLocation
    var HWCtrlNodeNum: Int = 0
    var CWPlantLoc: PlantLocation
    var CWCtrlNodeNum: Int = 0
    var MyEnvrnFlag: Bool = True
    @staticmethod
    def getAirLoopDOASInput(inout state: EnergyPlusData):
        let routineName: String = "AirLoopDOAS::getAirLoopDOASInput"
        let cCurrentModuleObject: String = "AirLoopHVAC:DedicatedOutdoorAirSystem"
        let instances = state.dataInputProcessing.inputProcessor.epJSON.find(cCurrentModuleObject)
        if instances != state.dataInputProcessing.inputProcessor.epJSON.end():
            var errorsFound: Bool = False
            var AirLoopDOASNum: Int = 0
            let instancesValue = instances.value()
            for instance in instancesValue:
                let fields = instance.value()
                let thisObjectName: String = instance.key()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(cCurrentModuleObject, thisObjectName)
                AirLoopDOASNum += 1
                var thisDOAS: AirLoopDOAS = AirLoopDOAS{}
                var eoh: ErrorObjectHeader = ErrorObjectHeader{routineName, cCurrentModuleObject, thisObjectName}
                thisDOAS.Name = makeUPPER(thisObjectName)
                thisDOAS.OASystemName = makeUPPER(fields["airloophvac_outdoorairsystem_name"].get(String))
                thisDOAS.m_OASystemNum = FindItemInList(thisDOAS.OASystemName, state.dataAirLoop.OutsideAirSys)
                if thisDOAS.m_OASystemNum == 0:
                    var cFieldName: String = "AirLoopHVAC:OutdoorAirSystem Name"
                    ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisDOAS.Name}\", {cFieldName} not found: {thisDOAS.OASystemName}")
                    errorsFound = True
                var CurrentModuleObject: String = "AirLoopHVAC:OutdoorAirSystem"
                let thisOutsideAirSys = state.dataAirLoop.OutsideAirSys[thisDOAS.m_OASystemNum]
                for InListNum in range(1, thisOutsideAirSys.NumControllers + 1):
                    if SameString(thisOutsideAirSys.ControllerType[InListNum], "Controller:OutdoorAir"):
                        ShowSevereError(state, f"When {CurrentModuleObject} = {thisOutsideAirSys.ControllerName[InListNum]} is used in AirLoopHVAC:DedicatedOutdoorAirSystem,")
                        ShowContinueError(state, "The Controller:OutdoorAir can not be used as a controller. Please remove it")
                        errorsFound = True
                thisDOAS.AirLoopMixerName = makeUPPER(fields["airloophvac_mixer_name"].get(String))
                thisDOAS.m_AirLoopMixerIndex = getAirLoopMixerIndex(state, thisDOAS.AirLoopMixerName)
                if thisDOAS.m_AirLoopMixerIndex < 0:
                    cFieldName = "AirLoopHVAC:Mixer Name"
                    ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisDOAS.Name}\" {cFieldName} not found: {thisDOAS.AirLoopMixerName}")
                    errorsFound = True
                thisDOAS.m_CompPointerAirLoopMixer = AirLoopMixer.factory(state, thisDOAS.m_AirLoopMixerIndex, thisDOAS.AirLoopMixerName)
                CurrentModuleObject = "AirLoopHVAC:OutdoorAirSystem:EquipmentList"
                var CoolingCoilOrder: Int = 0
                var FanOrder: Int = 0
                var fanNum: Int = 0
                for CompNum in range(1, thisOutsideAirSys.NumComponents + 1):
                    let CompType: String = thisOutsideAirSys.ComponentType[CompNum]
                    let CompName: String = thisOutsideAirSys.ComponentName[CompNum]
                    var InletNodeErrFlag: Bool = False
                    var OutletNodeErrFlag: Bool = False
                    var isFan: Bool = False
                    let typeNameUC: String = makeUPPER(thisOutsideAirSys.ComponentType[CompNum])
                    let enumVal = getEnumValue(validEquipNamesUC, typeNameUC)
                    if enumVal == -1:
                        ShowSevereError(state, f"{CurrentModuleObject} = \"{CompName}\" invalid Outside Air Component=\"{CompType}\".")
                        errorsFound = True
                        continue
                    match enumVal:
                        case ValidEquipListType.OutdoorAirMixer:
                            pass # will be handled in default
                        case ValidEquipListType.FanConstantVolume:

                        case ValidEquipListType.FanVariableVolume:

                        case ValidEquipListType.CoilUserDefined:
                            ShowSevereError(state, f"When {CurrentModuleObject} = {CompName} is used in AirLoopHVAC:DedicatedOutdoorAirSystem,")
                            ShowContinueError(state, f" the {typeNameUC} can not be used as a component. Please remove it")
                            errorsFound = True
                        case ValidEquipListType.FanSystemModel:
                            isFan = True
                            fanNum = GetFanIndex(state, CompName)
                            thisOutsideAirSys.InletNodeNum[CompNum] = fans[fanNum].inletNodeNum
                            if thisOutsideAirSys.InletNodeNum[CompNum] == 0:
                                InletNodeErrFlag = True
                            thisOutsideAirSys.OutletNodeNum[CompNum] = fans[fanNum].outletNodeNum
                            if thisOutsideAirSys.OutletNodeNum[CompNum] == 0:
                                OutletNodeErrFlag = True
                            if thisDOAS.m_FanInletNodeNum == 0:
                                thisDOAS.m_FanInletNodeNum = thisOutsideAirSys.InletNodeNum[CompNum]
                                thisDOAS.m_FanOutletNodeNum = thisOutsideAirSys.OutletNodeNum[CompNum]
                                FanOrder = CompNum
                                thisDOAS.FanName = CompName
                                thisDOAS.m_FanTypeNum = CompType.Fan_System_Object
                                thisDOAS.m_FanIndex = fanNum
                            if CompNum == 1:
                                thisDOAS.FanBeforeCoolingCoilFlag = True
                        case ValidEquipListType.FanComponentModel:
                            isFan = True
                            fanNum = GetFanIndex(state, CompName)
                            thisOutsideAirSys.InletNodeNum[CompNum] = fans[thisDOAS.m_FanIndex].inletNodeNum
                            if thisOutsideAirSys.InletNodeNum[CompNum] == 0:
                                InletNodeErrFlag = True
                            thisOutsideAirSys.OutletNodeNum[CompNum] = fans[thisDOAS.m_FanIndex].outletNodeNum
                            if thisOutsideAirSys.OutletNodeNum[CompNum] == 0:
                                OutletNodeErrFlag = True
                            if thisDOAS.m_FanInletNodeNum == 0:
                                thisDOAS.m_FanInletNodeNum = thisOutsideAirSys.InletNodeNum[CompNum]
                                thisDOAS.m_FanOutletNodeNum = thisOutsideAirSys.OutletNodeNum[CompNum]
                                FanOrder = CompNum
                                thisDOAS.FanName = CompName
                                thisDOAS.m_FanTypeNum = CompType.Fan_ComponentModel
                                thisDOAS.m_FanIndex = fanNum
                            if CompNum == 1:
                                thisDOAS.FanBeforeCoolingCoilFlag = True
                        case ValidEquipListType.CoilCoolingWater:
                            thisOutsideAirSys.InletNodeNum[CompNum] = WaterCoils.GetCoilInletNode(state, typeNameUC, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = WaterCoils.GetCoilOutletNode(state, typeNameUC, CompName, OutletNodeErrFlag)
                            thisDOAS.CWCtrlNodeNum = WaterCoils.GetCoilWaterInletNode(state, "COIL:COOLING:WATER", CompName, errorsFound)
                            if errorsFound:
                                ShowContinueError(state, f"The control node number is not found in {CurrentModuleObject} = {CompName}")
                            PlantUtilities.ScanPlantLoopsForObject(
                                state, CompName, DataPlant.PlantEquipmentType.CoilWaterCooling, thisDOAS.CWPlantLoc, errorsFound)
                            if errorsFound:
                                ShowFatalError(state, "GetAirLoopDOASInput: Program terminated for previous conditions.")
                            CoolingCoilOrder = CompNum
                        case ValidEquipListType.CoilHeatingWater:
                            thisOutsideAirSys.InletNodeNum[CompNum] = WaterCoils.GetCoilInletNode(state, typeNameUC, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = WaterCoils.GetCoilOutletNode(state, typeNameUC, CompName, OutletNodeErrFlag)
                            thisDOAS.HWCtrlNodeNum = WaterCoils.GetCoilWaterInletNode(state, "Coil:Heating:Water", CompName, errorsFound)
                            if errorsFound:
                                ShowContinueError(state, f"The control node number is not found in {CurrentModuleObject} = {CompName}")
                            PlantUtilities.ScanPlantLoopsForObject(
                                state, CompName, DataPlant.PlantEquipmentType.CoilWaterSimpleHeating, thisDOAS.HWPlantLoc, errorsFound)
                            if errorsFound:
                                ShowFatalError(state, "GetAirLoopDOASInput: Program terminated for previous conditions.")
                        case ValidEquipListType.CoilHeatingSteam:
                            thisOutsideAirSys.InletNodeNum[CompNum] = SteamCoils.GetCoilSteamInletNode(state, CompType, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = SteamCoils.GetCoilSteamOutletNode(state, CompType, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.CoilCoolingWaterDetailedGeometry:
                            thisOutsideAirSys.InletNodeNum[CompNum] = WaterCoils.GetCoilInletNode(state, typeNameUC, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = WaterCoils.GetCoilOutletNode(state, typeNameUC, CompName, OutletNodeErrFlag)
                            thisDOAS.CWCtrlNodeNum = WaterCoils.GetCoilWaterInletNode(state, "Coil:Cooling:Water:DetailedGeometry", CompName, errorsFound)
                            if errorsFound:
                                ShowContinueError(state, f"The control node number is not found in {CurrentModuleObject} = {CompName}")
                            PlantUtilities.ScanPlantLoopsForObject(
                                state, CompName, DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling, thisDOAS.CWPlantLoc, errorsFound)
                            if errorsFound:
                                ShowFatalError(state, "GetAirLoopDOASInput: Program terminated for previous conditions.")
                            CoolingCoilOrder = CompNum
                        case ValidEquipListType.CoilHeatingElectric:
                            thisOutsideAirSys.InletNodeNum[CompNum] = HeatingCoils.Inlet(state, typeNameUC, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = HeatingCoils.Outlet(state, typeNameUC, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.CoilHeatingFuel:
                            thisOutsideAirSys.InletNodeNum[CompNum] = HeatingCoils.Inlet(state, typeNameUC, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = HeatingCoils.Outlet(state, typeNameUC, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.CoilSystemCoolingWaterHeatExchangerAssisted:
                            thisOutsideAirSys.InletNodeNum[CompNum] = HXAssistedInlet(state, CompType, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = HXAssistedOutlet(state, CompType, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.CoilSystemCoolingDX:
                            if thisOutsideAirSys.compPointer[CompNum] is None:
                                thisOutsideAirSys.compPointer[CompNum] = UnitarySys.factory(state, UnitarySysType.Unitary_AnyCoilType, CompName, False, 0)
                            thisOutsideAirSys.InletNodeNum[CompNum] = thisOutsideAirSys.compPointer[CompNum].getAirInNode(state, CompName, 0, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = thisOutsideAirSys.compPointer[CompNum].getAirOutNode(state, CompName, 0, OutletNodeErrFlag)
                            CoolingCoilOrder = CompNum
                        case ValidEquipListType.AirLoopHVACUnitarySystem:
                            if thisOutsideAirSys.compPointer[CompNum] is None:
                                thisOutsideAirSys.compPointer[CompNum] = UnitarySys.factory(state, UnitarySysType.Unitary_AnyCoilType, CompName, False, 0)
                            thisOutsideAirSys.InletNodeNum[CompNum] = thisOutsideAirSys.compPointer[CompNum].getAirInNode(state, CompName, 0, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = thisOutsideAirSys.compPointer[CompNum].getAirOutNode(state, CompName, 0, OutletNodeErrFlag)
                            CoolingCoilOrder = CompNum
                        case ValidEquipListType.CoilSystemHeatingDX:
                            thisOutsideAirSys.InletNodeNum[CompNum] = GetHeatingCoilInletNodeNum(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = GetHeatingCoilOutletNodeNum(state, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.HeatExchangerAirToAirFlatPlate:
                        case ValidEquipListType.HeatExchangerAirToAirSensibleAndLatent:
                        case ValidEquipListType.HeatExchangerDesiccantBalancedFlow:
                            thisOutsideAirSys.HeatExchangerFlag = True
                            thisOutsideAirSys.InletNodeNum[CompNum] = GetSupplyInletNode(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = GetSupplyOutletNode(state, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.DehumidifierDesiccantNoFans:
                        case ValidEquipListType.DehumidifierDesiccantSystem:
                            thisOutsideAirSys.InletNodeNum[CompNum] = GetProcAirInletNodeNum(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = GetProcAirOutletNodeNum(state, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.HumidifierSteamElectric:
                        case ValidEquipListType.HumidifierSteamGas:
                            thisOutsideAirSys.InletNodeNum[CompNum] = GetAirInletNodeNum(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = GetAirOutletNodeNum(state, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.SolarCollectorUnglazedTranspired:
                            thisOutsideAirSys.InletNodeNum[CompNum] = TranspiredInlet(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = TranspiredOutlet(state, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.SolarCollectorFlatPlatePhotovoltaicThermal:
                            thisOutsideAirSys.InletNodeNum[CompNum] = PVTInlet(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = PVTOutlet(state, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.EvaporativeCoolerDirectCeldekPad:
                        case ValidEquipListType.EvaporativeCoolerIndirectCeldekPad:
                        case ValidEquipListType.EvaporativeCoolerIndirectWetCoil:
                        case ValidEquipListType.EvaporativeCoolerIndirectResearchSpecial:
                        case ValidEquipListType.EvaporativeCoolerDirectResearchSpecial:
                            thisOutsideAirSys.InletNodeNum[CompNum] = GetInletNodeNum(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = GetOutletNodeNum(state, CompName, OutletNodeErrFlag)
                        case ValidEquipListType.ZoneHVACTerminalUnitVariableRefrigerantFlow:
                            thisOutsideAirSys.InletNodeNum[CompNum] = GetVRFTUInAirNodeFromName(state, CompName, InletNodeErrFlag)
                            thisOutsideAirSys.OutletNodeNum[CompNum] = GetVRFTUOutAirNodeFromName(state, CompName, OutletNodeErrFlag)
                        case _:
                            ShowSevereError(state, f"{CurrentModuleObject} = \"{CompName}\" invalid Outside Air Component=\"{thisOutsideAirSys.ComponentType[CompNum]}\".")
                            errorsFound = True
                    if CoolingCoilOrder > FanOrder and not thisDOAS.FanBeforeCoolingCoilFlag:
                        thisDOAS.FanBeforeCoolingCoilFlag = True
                    if InletNodeErrFlag:
                        ShowSevereError(state, f"Inlet node number is not found in {CurrentModuleObject} = {CompName}")
                        errorsFound = True
                    if OutletNodeErrFlag:
                        ShowSevereError(state, f"Outlet node number is not found in {CurrentModuleObject} = {CompName}")
                        errorsFound = True
                    if CompNum > 1:
                        if thisOutsideAirSys.InletNodeNum[CompNum] != thisOutsideAirSys.OutletNodeNum[CompNum - 1]:
                            if isFan and thisOutsideAirSys.InletNodeNum[CompNum] == thisDOAS.m_CompPointerAirLoopMixer.OutletNodeNum:
                                thisDOAS.m_exhaustFanUsed = True
                                thisDOAS.m_exhaustFanIndex = GetFanIndex(state, CompName)
                                thisDOAS.m_exhaustFanInletNodeNum = thisOutsideAirSys.InletNodeNum[CompNum]
                                thisDOAS.m_exhaustFanOutletNodeNum = thisOutsideAirSys.OutletNodeNum[CompNum]
                                if getEnumValue(validEquipNamesUC, typeNameUC) == ValidEquipListType.FanSystemModel:
                                    thisDOAS.m_exhaustFanTypeNum = CompType.Fan_System_Object
                                elif getEnumValue(validEquipNamesUC, typeNameUC) == ValidEquipListType.FanComponentModel:
                                    thisDOAS.m_exhaustFanTypeNum = CompType.Fan_ComponentModel
                            else:
                                ShowSevereError(state, f"getAirLoopMixer: Node Connection Error in AirLoopHVAC:DedicatedOutdoorAirSystem = {thisDOAS.Name}. Inlet node of {thisOutsideAirSys.ComponentName[CompNum]} as current component is not same as the outlet node of {thisOutsideAirSys.ComponentName[CompNum - 1]} as previous component")
                                ShowContinueError(state, f"The inlet node name = {state.dataLoopNodes.NodeID[thisOutsideAirSys.InletNodeNum[CompNum]]}, and the outlet node name = {state.dataLoopNodes.NodeID[thisOutsideAirSys.OutletNodeNum[CompNum - 1]]}.")
                                errorsFound = True
                var DOASOutletNodeNumAdjustment: Int = 0
                if thisDOAS.m_exhaustFanUsed:
                    DOASOutletNodeNumAdjustment = -1
                thisDOAS.m_InletNodeNum = thisOutsideAirSys.InletNodeNum[1]
                thisDOAS.m_OutletNodeNum = thisOutsideAirSys.OutletNodeNum[thisOutsideAirSys.NumComponents + DOASOutletNodeNumAdjustment]
                thisOutsideAirSys.AirLoopDOASNum = AirLoopDOASNum - 1
                Node.SetUpCompSets(state, cCurrentModuleObject, thisDOAS.Name, "AIRLOOPHVAC:OUTDOORAIRSYSTEM", thisDOAS.OASystemName,
                                   state.dataLoopNodes.NodeID[thisDOAS.m_InletNodeNum], state.dataLoopNodes.NodeID[thisDOAS.m_OutletNodeNum])
                if thisOutsideAirSys.HeatExchangerFlag:
                    thisDOAS.m_HeatExchangerFlag = True
                thisDOAS.AvailManagerSchedName = makeUPPER(fields["availability_schedule_name"].get(String))
                thisDOAS.m_AvailManagerSched = SchedGetSchedule(state, thisDOAS.AvailManagerSchedName)
                if thisDOAS.m_AvailManagerSched is None:
                    ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", thisDOAS.AvailManagerSchedName)
                    errorsFound = True
                thisDOAS.AirLoopSplitterName = makeUPPER(fields["airloophvac_splitter_name"].get(String))
                thisDOAS.m_AirLoopSplitterIndex = getAirLoopSplitterIndex(state, thisDOAS.AirLoopSplitterName)
                if thisDOAS.m_AirLoopSplitterIndex < 0:
                    cFieldName = "AirLoopHVAC:Splitter Name"
                    ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisDOAS.Name}\" {cFieldName} not found: {thisDOAS.AirLoopSplitterName}")
                    errorsFound = True
                thisDOAS.m_CompPointerAirLoopSplitter = AirLoopSplitter.factory(state, thisDOAS.m_AirLoopSplitterIndex, thisDOAS.AirLoopSplitterName)
                thisDOAS.PreheatTemp = fields["preheat_design_temperature"].get(Float64)
                thisDOAS.PreheatHumRat = fields["preheat_design_humidity_ratio"].get(Float64)
                thisDOAS.PrecoolTemp = fields["precool_design_temperature"].get(Float64)
                thisDOAS.PrecoolHumRat = fields["precool_design_humidity_ratio"].get(Float64)
                thisDOAS.NumOfAirLoops = fields["number_of_airloophvac"].get(Int)
                if thisDOAS.NumOfAirLoops < 1:
                    cFieldName = "Number of AirLoopHVAC"
                    ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisDOAS.Name}\" {cFieldName} = {thisDOAS.NumOfAirLoops}")
                    ShowContinueError(state, " The minimum value should be 1.")
                    errorsFound = True
                let AirLoopNames = fields.find("airloophvacs")
                if AirLoopNames != fields.end():
                    let AirLoopArray = AirLoopNames.value()
                    var num: Int = 0
                    for AirLoopHVACName in AirLoopArray:
                        let name: String = makeUPPER(AirLoopHVACName["airloophvac_name"].get(String))
                        let LoopNum: Int = FindItemInList(name, state.dataAirSystemsData.PrimaryAirSystems)
                        num += 1
                        if LoopNum > 0 and num <= thisDOAS.NumOfAirLoops:
                            thisDOAS.AirLoopName.append(name)
                            thisDOAS.m_AirLoopNum.append(LoopNum)
                        else:
                            cFieldName = "AirLoopHVAC Name"
                            ShowSevereError(state, f"{cCurrentModuleObject}, \"{thisDOAS.Name}\" {cFieldName} not found: {name}")
                            errorsFound = True
                thisDOAS.m_AirLoopDOASNum = AirLoopDOASNum - 1
                state.dataAirLoopHVACDOAS.airloopDOAS.append(thisDOAS)
                if not CheckOutAirNodeNumber(state, thisDOAS.m_InletNodeNum):
                    ShowSevereError(state, f"Inlet node ({state.dataLoopNodes.NodeID[thisDOAS.m_InletNodeNum]}) is not one of OutdoorAir:Node in {CurrentModuleObject} = {thisDOAS.Name}")
                    errorsFound = True
                if thisDOAS.m_OutletNodeNum != thisDOAS.m_CompPointerAirLoopSplitter.InletNodeNum:
                    ShowSevereError(state, f"The outlet node is not the inlet node of AirLoopHVAC:Splitter in {CurrentModuleObject} = {thisDOAS.Name}")
                    ShowContinueError(state, f"The outlet node name is {state.dataLoopNodes.NodeID[thisDOAS.m_OutletNodeNum]}, and the inlet node name of AirLoopHVAC:Splitter is {state.dataLoopNodes.NodeID[thisDOAS.m_CompPointerAirLoopSplitter.InletNodeNum]}")
                    errorsFound = True
            for OASysNum in range(1, state.dataAirLoop.NumOASystems + 1):
                if SameString(state.dataAirLoop.OutsideAirSys[OASysNum].ControllerListName, ""):
                    if state.dataAirLoop.OutsideAirSys[OASysNum].AirLoopDOASNum == -1:
                        ShowSevereError(state, f"AirLoopHVAC:OutdoorAirSystem = \"{state.dataAirLoop.OutsideAirSys[OASysNum].Name}\" invalid Controller List Name = \" not found.")
                        errorsFound = True
            if errorsFound:
                ShowFatalError(state, "getAirLoopHVACDOAS: Previous errors cause termination.")
    def SimAirLoopHVACDOAS(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool, inout CompIndex: Int):
        if state.dataAirLoopHVACDOAS.GetInputOnceFlag:
            AirLoopDOAS.getAirLoopDOASInput(state)
            state.dataAirLoopHVACDOAS.GetInputOnceFlag = False
        if CompIndex == -1:
            CompIndex = self.m_AirLoopDOASNum
        if self.SizingOnceFlag:
            self.SizingAirLoopDOAS(state)
            self.SizingOnceFlag = False
        self.initAirLoopDOAS(state, FirstHVACIteration)
        if self.SumMassFlowRate == 0.0 and not state.dataGlobal.BeginEnvrnFlag:
            state.dataLoopNodes.Node[self.m_CompPointerAirLoopMixer.OutletNodeNum].MassFlowRate = 0.0
        self.CalcAirLoopDOAS(state, FirstHVACIteration)
    def initAirLoopDOAS(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool):
        let RoutineName: String = "AirLoopDOAS::initAirLoopDOAS"
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            var ErrorsFound: Bool = False
            for CompNum in range(1, state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].NumComponents + 1):
                let CompType: String = state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].ComponentType[CompNum]
                let CompName: String = state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].ComponentName[CompNum]
                if SameString(CompType, "FAN:SYSTEMMODEL"):
                    fans[self.m_FanIndex].simulate(state, FirstHVACIteration)
                if SameString(CompType, "FAN:COMPONENTMODEL"):
                    fans[self.m_FanIndex].simulate(state, FirstHVACIteration)
                if SameString(CompType, "COIL:HEATING:WATER"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_HeatCoilNum)
                    let CoilMaxVolFlowRate: Float64 = WaterCoils.GetCoilMaxWaterFlowRate(state, "Coil:Heating:Water", CompName, ErrorsFound)
                    let rho: Float64 = self.HWPlantLoc.loop.glycol.getDensity(state, HWInitConvTemp, RoutineName)
                    PlantUtilities.InitComponentNodes(state, 0.0, CoilMaxVolFlowRate * rho, self.HWCtrlNodeNum,
                                                       state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].OutletNodeNum[CompNum])
                if SameString(CompType, "COIL:COOLING:WATER"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_CoolCoilNum)
                    let CoilMaxVolFlowRate: Float64 = WaterCoils.GetCoilMaxWaterFlowRate(state, "Coil:Cooling:Water", CompName, ErrorsFound)
                    let rho: Float64 = self.CWPlantLoc.loop.glycol.getDensity(state, CWInitConvTemp, RoutineName)
                    PlantUtilities.InitComponentNodes(state, 0.0, CoilMaxVolFlowRate * rho, self.CWCtrlNodeNum,
                                                       state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].OutletNodeNum[CompNum])
                if SameString(CompType, "COIL:COOLING:WATER:DETAILEDGEOMETRY"):
                    WaterCoils.SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, self.m_CoolCoilNum)
                    let CoilMaxVolFlowRate: Float64 = WaterCoils.GetCoilMaxWaterFlowRate(state, "Coil:Cooling:Water:DetailedGeometry", CompName, ErrorsFound)
                    let rho: Float64 = self.CWPlantLoc.loop.glycol.getDensity(state, CWInitConvTemp, RoutineName)
                    PlantUtilities.InitComponentNodes(state, 0.0, CoilMaxVolFlowRate * rho, self.CWCtrlNodeNum,
                                                       state.dataAirLoop.OutsideAirSys[self.m_OASystemNum].OutletNodeNum[CompNum])
            self.MyEnvrnFlag = False
            if ErrorsFound:
                ShowFatalError(state, "initAirLoopDOAS: Previous errors cause termination.")
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        self.SumMassFlowRate = 0.0
        for LoopOA in range(self.m_CompPointerAirLoopSplitter.numOfOutletNodes):
            let NodeNum: Int = self.m_CompPointerAirLoopSplitter.OutletNodeNum[LoopOA]
            self.SumMassFlowRate += state.dataLoopNodes.Node[NodeNum].MassFlowRate
        let SchAvailValue: Float64 = self.m_AvailManagerSched.getCurrentVal()
        if SchAvailValue < 1.0:
            self.SumMassFlowRate = 0.0
        state.dataLoopNodes.Node[self.m_InletNodeNum].MassFlowRate = self.SumMassFlowRate
    def CalcAirLoopDOAS(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool):
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
        ManageOutsideAirSystem(state, self.OASystemName, FirstHVACIteration, 0, self.m_OASystemNum)
        let Temp: Float64 = state.dataLoopNodes.Node[self.m_OutletNodeNum].Temp
        let HumRat: Float64 = state.dataLoopNodes.Node[self.m_OutletNodeNum].HumRat
        state.dataLoopNodes.Node[self.m_OutletNodeNum].Enthalpy = PsyHFnTdbW(Temp, HumRat)
        self.m_CompPointerAirLoopSplitter.CalcAirLoopSplitter(state, Temp, HumRat)
    def SizingAirLoopDOAS(inout self, inout state: EnergyPlusData):
        var sizingVolumeFlow: Float64 = 0.0
        for AirLoop in range(1, self.NumOfAirLoops + 1):
            let AirLoopNum: Int = self.m_AirLoopNum[AirLoop - 1]
            self.m_OACtrlNum.append(state.dataAirLoop.AirLoopControlInfo[AirLoopNum].OACtrlNum)
            if self.m_OACtrlNum[AirLoop - 1] > 0:
                sizingVolumeFlow += state.dataMixedAir.OAController[self.m_OACtrlNum[AirLoop - 1]].MaxOA
        self.SizingMassFlow = sizingVolumeFlow * state.dataEnvrn.StdRhoAir
        reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name, "Design Volume Flow Rate [m3/s]", sizingVolumeFlow)
        self.GetDesignDayConditions(state)
        if self.m_FanIndex > 0 and (self.m_FanTypeNum == CompType.Fan_System_Object or self.m_FanTypeNum == CompType.Fan_ComponentModel):
            let supplyFanVolFlow: Float64 = fans[self.m_FanIndex].maxAirFlowRate
            if supplyFanVolFlow != AutoSize:
                if (abs((supplyFanVolFlow - sizingVolumeFlow) / sizingVolumeFlow) > 0.01):
                    ShowWarningError(state, f"AirLoopHVAC:DedicatedOutdoorAirSystem = {self.Name}.")
                    ShowContinueError(state, f"The supply fan = {fans[self.m_FanIndex].Name} has a volumetric air flow rate = {supplyFanVolFlow} m3/s.")
                    ShowContinueError(state, f"The AirLoopHVAC:DedicatedOutdoorAirSystem Design Volume Flow Rate = {sizingVolumeFlow} m3/s.")
                    ShowContinueError(state, "Consider autosizing the supply fan Maximum Air Flow Rate.")
            else:
                fans[self.m_FanIndex].maxAirFlowRate = sizingVolumeFlow
                state.dataLoopNodes.Node[self.m_FanInletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                state.dataLoopNodes.Node[self.m_FanOutletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                state.dataLoopNodes.Node[self.m_FanOutletNodeNum].MassFlowRateMax = self.SizingMassFlow
                if self.m_FanTypeNum == CompType.Fan_ComponentModel:
                    fans[self.m_FanIndex].minAirFlowRate = 0.0
                    fans[self.m_FanIndex].maxAirMassFlowRate = self.SizingMassFlow
        if self.m_exhaustFanUsed:
            if self.m_exhaustFanIndex > 0 and (self.m_exhaustFanTypeNum == CompType.Fan_System_Object or self.m_exhaustFanTypeNum == CompType.Fan_ComponentModel):
                let exhaustFanVolFlow: Float64 = fans[self.m_exhaustFanIndex].maxAirFlowRate
                if exhaustFanVolFlow != AutoSize:
                    if (abs((exhaustFanVolFlow - sizingVolumeFlow) / sizingVolumeFlow) > 0.01):
                        ShowWarningError(state, f"AirLoopHVAC:DedicatedOutdoorAirSystem = {self.Name}.")
                        ShowContinueError(state, f"The exhaust fan = {fans[self.m_exhaustFanIndex].Name} has a volumetric air flow rate = {exhaustFanVolFlow} m3/s.")
                        ShowContinueError(state, f"The AirLoopHVAC:DedicatedOutdoorAirSystem Design Volume Flow Rate = {sizingVolumeFlow} m3/s.")
                        ShowContinueError(state, "Consider autosizing the exhaust fan Maximum Air Flow Rate.")
                else:
                    fans[self.m_exhaustFanIndex].maxAirFlowRate = sizingVolumeFlow
                    state.dataLoopNodes.Node[self.m_exhaustFanInletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                    state.dataLoopNodes.Node[self.m_exhaustFanOutletNodeNum].MassFlowRateMaxAvail = self.SizingMassFlow
                    state.dataLoopNodes.Node[self.m_exhaustFanOutletNodeNum].MassFlowRateMax = self.SizingMassFlow
                    if self.m_FanTypeNum == CompType.Fan_ComponentModel:
                        fans[self.m_exhaustFanIndex].minAirFlowRate = 0.0
                        fans[self.m_exhaustFanIndex].maxAirMassFlowRate = self.SizingMassFlow
        state.dataSize.CurSysNum = state.dataHVACGlobal.NumPrimaryAirSys + self.m_AirLoopDOASNum + 1
        state.dataSize.CurOASysNum = self.m_OASystemNum
    def GetDesignDayConditions(borrowed self, inout state: EnergyPlusData):
        for env in state.dataWeather.Environment:
            if env.KindOfEnvrn != KindOfSim.DesignDay and env.KindOfEnvrn != KindOfSim.RunPeriodDesign:
                continue
            if env.maxCoolingOATSizing > self.SizingCoolOATemp:
                self.SizingCoolOATemp = env.maxCoolingOATSizing
                if env.KindOfEnvrn == KindOfSim.DesignDay and state.dataWeather.DesDayInput[env.DesignDayNum].PressureEntered:
                    self.SizingCoolOAHumRat = PsyWFnTdpPb(state, env.maxCoolingOADPSizing, state.dataWeather.DesDayInput[env.DesignDayNum].PressBarom)
                else:
                    self.SizingCoolOAHumRat = PsyWFnTdpPb(state, env.maxCoolingOADPSizing, state.dataEnvrn.StdBaroPress)
            if env.minHeatingOATSizing < self.HeatOutTemp:
                self.HeatOutTemp = env.minHeatingOATSizing
                if env.KindOfEnvrn == KindOfSim.DesignDay and state.dataWeather.DesDayInput[env.DesignDayNum].PressureEntered:
                    self.HeatOutHumRat = PsyWFnTdpPb(state, env.minHeatingOADPSizing, state.dataWeather.DesDayInput[env.DesignDayNum].PressBarom)
                else:
                    self.HeatOutHumRat = PsyWFnTdpPb(state, env.minHeatingOADPSizing, state.dataEnvrn.StdBaroPress)
        reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name, "Design Cooling Outdoor Air Temperature [C]", self.SizingCoolOATemp)
        reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name, "Design Cooling Outdoor Air Humidity Ratio [kgWater/kgDryAir]", self.SizingCoolOAHumRat)
        reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name, "Design Heating Outdoor Air Temperature [C]", self.HeatOutTemp)
        reportSizerOutput(state, "AirLoopHVAC:DedicatedOutdoorAirSystem", self.Name, "Design Heating Outdoor Air Humidity Ratio [kgWater/kgDryAir]", self.HeatOutHumRat)
def getAirLoopMixerIndex(inout state: EnergyPlusData, objectName: String) -> Int:
    if state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag:
        AirLoopMixer.getAirLoopMixer(state)
        state.dataAirLoopHVACDOAS.getAirLoopMixerInputOnceFlag = False
    var index: Int = -1
    var loopIdx: Int = 0
    for thisAirLoopMixerObject in state.dataAirLoopHVACDOAS.airloopMixer:
        if SameString(objectName, thisAirLoopMixerObject.name):
            index = loopIdx
            return index
        loopIdx += 1
    ShowSevereError(state, f"getAirLoopMixer: did not find AirLoopHVAC:Mixer name ={objectName}. Check inputs")
    return index
def getAirLoopSplitterIndex(inout state: EnergyPlusData, objectName: String) -> Int:
    if state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag:
        AirLoopSplitter.getAirLoopSplitter(state)
        state.dataAirLoopHVACDOAS.getAirLoopSplitterInputOnceFlag = False
    var index: Int = -1
    var loopIdx: Int = 0
    for thisAirLoopSplitterObj in state.dataAirLoopHVACDOAS.airloopSplitter:
        if SameString(objectName, thisAirLoopSplitterObj.name):
            index = loopIdx
            return index
        loopIdx += 1
    ShowSevereError(state, f"getAirLoopSplitter: did not find AirLoopSplitter name ={objectName}. Check inputs")
    return index
def getAirLoopHVACDOASInput(inout state: EnergyPlusData):
    if state.dataAirLoopHVACDOAS.GetInputOnceFlag:
        AirLoopDOAS.getAirLoopDOASInput(state)
        state.dataAirLoopHVACDOAS.GetInputOnceFlag = False
def CheckConvergence(inout state: EnergyPlusData):
    for loop in state.dataAirLoopHVACDOAS.airloopDOAS:
        var maxDiff: Float64 = 0.0
        var Diff: Float64 = abs(loop.m_CompPointerAirLoopSplitter.InletTemp -
                                state.dataLoopNodes.Node[loop.m_CompPointerAirLoopSplitter.OutletNodeNum[0]].Temp)
        if Diff > maxDiff:
            maxDiff = Diff
        if loop.m_HeatExchangerFlag:
            let OldTemp: Float64 = loop.m_CompPointerAirLoopMixer.OutletTemp
            loop.m_CompPointerAirLoopMixer.CalcAirLoopMixer(state)
            Diff = abs(OldTemp - loop.m_CompPointerAirLoopMixer.OutletTemp)
            if Diff > maxDiff:
                maxDiff = Diff
        if maxDiff > 1.0e-6:
            if loop.ConveCount == 0:
                loop.ConveCount += 1
                ShowWarningError(state, f"Convergence limit is above 1.0e-6 for unit={loop.Name}")
                ShowContinueErrorTimeStamp(state, f"The max difference of node temperatures between AirLoopDOAS outlet and OA mixer inlet ={maxDiff:.6f}")
            else:
                loop.ConveCount += 1
                ShowRecurringWarningErrorAtEnd(state, f"\"{loop.Name}\": The max difference of node temperatures exceeding 1.0e-6 continues...", loop.ConveIndex, maxDiff, maxDiff)
struct AirLoopHVACDOASData:
    var GetInputOnceFlag: Bool = True
    var getAirLoopMixerInputOnceFlag: Bool = True
    var getAirLoopSplitterInputOnceFlag: Bool = True
    var airloopDOAS: List[AirLoopDOAS] = List[AirLoopDOAS]()
    var airloopMixer: List[AirLoopMixer] = List[AirLoopMixer]()
    var airloopSplitter: List[AirLoopSplitter] = List[AirLoopSplitter]()
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.GetInputOnceFlag = True
        self.getAirLoopMixerInputOnceFlag = True
        self.getAirLoopSplitterInputOnceFlag = True
        self.airloopDOAS = List[AirLoopDOAS]()
        self.airloopMixer = List[AirLoopMixer]()
        self.airloopSplitter = List[AirLoopSplitter]()
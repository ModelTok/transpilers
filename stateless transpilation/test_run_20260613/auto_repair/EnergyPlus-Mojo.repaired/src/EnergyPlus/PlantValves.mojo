from Data.EnergyPlusData import EnergyPlusData
from Data.BaseData import BaseGlobalStruct
from DataGlobals import DataGlobals
from DataLoopNode import NodeData, Node
from DataPlant import PlantLocation, PlantEquipmentType, FlowLock, PlantEquipmentTypeIsPump
from DataBranchAirLoopPlant import ControlType
from PlantComponent import PlantComponent
from PlantUtilities import SafeCopyPlantNode, SetComponentFlowRate, InitComponentNodes, ScanPlantLoopsForObject
from BranchNodeConnections import TestCompSet
from NodeInputManager import GetOnlySingleNode
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType
from InputProcessor import InputProcessor
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError
from Constant import Units as ConstantUnits
from DataIPShortCuts import DataIPShortCuts
from DataHVACGlobals import DataHVACGlobals
from General import General
from ObjexxFCL.Array.functions import any_eq, allocated

struct TemperValveData(PlantComponent):
    var Name: String
    var PltInletNodeNum: Int = 0
    var PltOutletNodeNum: Int = 0
    var PltStream2NodeNum: Int = 0
    var PltSetPointNodeNum: Int = 0
    var PltPumpOutletNodeNum: Int = 0
    var environmentInit: Bool = True
    var FlowDivFract: Float64 = 0.0
    var Stream2SourceTemp: Float64 = 0.0
    var InletTemp: Float64 = 0.0
    var SetPointTemp: Float64 = 0.0
    var MixedMassFlowRate: Float64 = 0.0
    var plantLoc: PlantLocation = PlantLocation()
    var compDelayedInitFlag: Bool = True

    def __init__(inout self):

    def __del__(self):

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> Pointer[PlantComponent]:
        if state.dataPlantValves.GetTemperingValves:
            GetPlantValvesInput(state)
            state.dataPlantValves.GetTemperingValves = False
        for valve in state.dataPlantValves.TemperValve:
            if valve.Name == objectName:
                return Pointer[PlantComponent](Pointer.address_of(valve).address)
        ShowFatalError(state, f"TemperValveDataFactory: Error getting inputs for valve named: {objectName}")
        return Pointer[PlantComponent](0)

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        self.initialize(state)
        self.calculate(state)
        SafeCopyPlantNode(state, self.PltInletNodeNum, self.PltOutletNodeNum)
        var mdot: Float64 = self.MixedMassFlowRate * self.FlowDivFract
        if self.plantLoc.loopNum > 0:
            SetComponentFlowRate(state, mdot, self.PltInletNodeNum, self.PltOutletNodeNum, self.plantLoc)

    def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, inout MaxLoad: Float64, inout MinLoad: Float64, inout OptLoad: Float64):
        MaxLoad = 0.0
        MinLoad = 0.0
        OptLoad = 0.0

    def initialize(inout self, state: EnergyPlusData):
        var InletNode: Int
        var OutletNode: Int
        var Strm2Node: Int
        var SetPntNode: Int
        var PumpOutNode: Int
        var InNodeOnSplitter: Bool
        var PumpOutNodeOkay: Bool
        var ErrorsFound: Bool
        var TwoBranchesBetwn: Bool
        var SetPointNodeOkay: Bool
        var Stream2NodeOkay: Bool
        var IsBranchActive: Bool
        var errFlag: Bool

        if state.dataPlantValves.OneTimeInitFlag:
            state.dataPlantValves.OneTimeInitFlag = False
        else:
            if self.compDelayedInitFlag:
                errFlag = False
                ScanPlantLoopsForObject(state, self.Name, PlantEquipmentType.ValveTempering, self.plantLoc, errFlag, _, _, _, _, _)
                if errFlag:
                    ShowFatalError(state, "InitPlantValves: Program terminated due to previous condition(s).")
                ErrorsFound = False
                InNodeOnSplitter = False
                PumpOutNodeOkay = False
                TwoBranchesBetwn = False
                SetPointNodeOkay = False
                Stream2NodeOkay = False
                IsBranchActive = False
                for thisPlantLoop in state.dataPlnt.PlantLoop:
                    for thisLoopSide in thisPlantLoop.LoopSide:
                        var branchCtr: Int = 0
                        for thisBranch in thisLoopSide.Branch:
                            branchCtr += 1
                            for thisComp in thisBranch.Comp:
                                if (thisComp.Type == PlantEquipmentType.ValveTempering) and (thisComp.Name == self.Name):
                                    if thisBranch.controlType == ControlType.Active:
                                        IsBranchActive = True
                                    if thisLoopSide.Splitter.Exists:
                                        if allocated(thisLoopSide.Splitter.NodeNumOut):
                                            if any_eq(thisLoopSide.Splitter.NodeNumOut, self.PltInletNodeNum):
                                                InNodeOnSplitter = True
                                        if thisLoopSide.Splitter.TotalOutletNodes == 2:
                                            TwoBranchesBetwn = True
                                    if thisLoopSide.Mixer.Exists:
                                        if any_eq(thisLoopSide.Mixer.NodeNumIn, self.PltStream2NodeNum):
                                            var thisInnerBranchCtr: Int = 0
                                            for thisInnerBranch in thisLoopSide.Branch:
                                                thisInnerBranchCtr += 1
                                                if branchCtr == thisInnerBranchCtr:
                                                    continue
                                                for thisInnerComp in thisInnerBranch.Comp:
                                                    if thisInnerComp.NodeNumOut == self.PltStream2NodeNum:
                                                        Stream2NodeOkay = True
                                    for thisInnerBranch in thisLoopSide.Branch:
                                        if thisInnerBranch.NodeNumOut == self.PltPumpOutletNodeNum:
                                            for thisInnerComp in thisInnerBranch.Comp:
                                                if PlantEquipmentTypeIsPump[Int(thisInnerComp.Type)]:
                                                    PumpOutNodeOkay = True
                                    if thisPlantLoop.TempSetPointNodeNum == self.PltSetPointNodeNum:
                                        SetPointNodeOkay = True
                if not IsBranchActive:
                    ShowSevereError(state, "TemperingValve object needs to be on an ACTIVE branch")
                    ErrorsFound = True
                if not InNodeOnSplitter:
                    ShowSevereError(state, "TemperingValve object needs to be between a Splitter and Mixer")
                    ErrorsFound = True
                if not PumpOutNodeOkay:
                    ShowSevereError(state, "TemperingValve object needs to reference a node that is the outlet of a pump on its loop")
                    ErrorsFound = True
                if not TwoBranchesBetwn:
                    ShowSevereError(state, "TemperingValve object needs exactly two branches between a Splitter and Mixer")
                    ErrorsFound = True
                if not SetPointNodeOkay:
                    ShowSevereError(state, "TemperingValve object setpoint node not valid.  Check Setpoint manager for Plant Loop Temp Setpoint")
                    ErrorsFound = True
                if not Stream2NodeOkay:
                    ShowSevereError(state, "TemperingValve object stream 2 source node not valid.")
                    ShowContinueError(state, "Check that node is a component outlet, enters a mixer, and on the other branch")
                    ErrorsFound = True
                if ErrorsFound:
                    ShowFatalError(state, f"Errors found in input, TemperingValve object {self.Name}")
                self.compDelayedInitFlag = False

        InletNode = self.PltInletNodeNum
        OutletNode = self.PltOutletNodeNum
        Strm2Node = self.PltStream2NodeNum
        SetPntNode = self.PltSetPointNodeNum
        PumpOutNode = self.PltPumpOutletNodeNum

        if state.dataGlobal.BeginEnvrnFlag and self.environmentInit:
            if (InletNode > 0) and (OutletNode > 0):
                InitComponentNodes(state, 0.0, state.dataLoopNodes.Node[PumpOutNode - 1].MassFlowRateMax, self.PltInletNodeNum, self.PltOutletNodeNum)
            self.environmentInit = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.environmentInit = True
        if InletNode > 0:
            self.InletTemp = state.dataLoopNodes.Node[InletNode - 1].Temp
        if Strm2Node > 0:
            self.Stream2SourceTemp = state.dataLoopNodes.Node[Strm2Node - 1].Temp
        if SetPntNode > 0:
            self.SetPointTemp = state.dataLoopNodes.Node[SetPntNode - 1].TempSetPoint
        if PumpOutNode > 0:
            self.MixedMassFlowRate = state.dataLoopNodes.Node[PumpOutNode - 1].MassFlowRate

    def calculate(inout self, state: EnergyPlusData):
        var Tin: Float64
        var Tset: Float64
        var Ts2: Float64
        if state.dataGlobal.KickOffSimulation:
            return
        if self.plantLoc.side.FlowLock == FlowLock.Unlocked:
            Tin = self.InletTemp
            Tset = self.SetPointTemp
            Ts2 = self.Stream2SourceTemp
            if Ts2 <= Tset:
                self.FlowDivFract = 0.0
            else:
                if Tin < Ts2:
                    self.FlowDivFract = (Ts2 - Tset) / (Ts2 - Tin)
                else:
                    self.FlowDivFract = 1.0
        elif self.plantLoc.side.FlowLock == FlowLock.Locked:
            if self.MixedMassFlowRate > 0.0:
                self.FlowDivFract = state.dataLoopNodes.Node[self.PltOutletNodeNum - 1].MassFlowRate / self.MixedMassFlowRate
            else:
                self.FlowDivFract = 0.0
        if self.FlowDivFract < 0.0:
            self.FlowDivFract = 0.0
        if self.FlowDivFract > 1.0:
            self.FlowDivFract = 1.0

    def oneTimeInit(inout self, state: EnergyPlusData):

    def oneTimeInit_new(inout self, state: EnergyPlusData):

def GetPlantValvesInput(state: EnergyPlusData):
    var Item: Int
    var Alphas: List[String] = List[String](6)
    var Numbers: List[Float64] = List[Float64](1)
    var NumAlphas: Int
    var NumNumbers: Int
    var IOStatus: Int
    var ErrorsFound: Bool = False
    var CurrentModuleObject: String = "TemperingValve"

    state.dataPlantValves.NumTemperingValves = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataPlantValves.TemperValve.resize(state.dataPlantValves.NumTemperingValves)

    for Item in range(1, state.dataPlantValves.NumTemperingValves + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Item, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus)
        state.dataPlantValves.TemperValve[Item - 1].Name = Alphas[0]
        state.dataPlantValves.TemperValve[Item - 1].PltInletNodeNum = GetOnlySingleNode(state,
                                                                                         Alphas[1],
                                                                                         ErrorsFound,
                                                                                         Node.ConnectionObjectType.TemperingValve,
                                                                                         Alphas[0],
                                                                                         Node.FluidType.Water,
                                                                                         Node.ConnectionType.Inlet,
                                                                                         Node.CompFluidStream.Primary,
                                                                                         Node.ObjectIsNotParent)
        state.dataPlantValves.TemperValve[Item - 1].PltOutletNodeNum = GetOnlySingleNode(state,
                                                                                          Alphas[2],
                                                                                          ErrorsFound,
                                                                                          Node.ConnectionObjectType.TemperingValve,
                                                                                          Alphas[0],
                                                                                          Node.FluidType.Water,
                                                                                          Node.ConnectionType.Outlet,
                                                                                          Node.CompFluidStream.Primary,
                                                                                          Node.ObjectIsNotParent)
        state.dataPlantValves.TemperValve[Item - 1].PltStream2NodeNum = GetOnlySingleNode(state,
                                                                                           Alphas[3],
                                                                                           ErrorsFound,
                                                                                           Node.ConnectionObjectType.TemperingValve,
                                                                                           Alphas[0],
                                                                                           Node.FluidType.Water,
                                                                                           Node.ConnectionType.Sensor,
                                                                                           Node.CompFluidStream.Primary,
                                                                                           Node.ObjectIsNotParent)
        state.dataPlantValves.TemperValve[Item - 1].PltSetPointNodeNum = GetOnlySingleNode(state,
                                                                                            Alphas[4],
                                                                                            ErrorsFound,
                                                                                            Node.ConnectionObjectType.TemperingValve,
                                                                                            Alphas[0],
                                                                                            Node.FluidType.Water,
                                                                                            Node.ConnectionType.SetPoint,
                                                                                            Node.CompFluidStream.Primary,
                                                                                            Node.ObjectIsNotParent)
        state.dataPlantValves.TemperValve[Item - 1].PltPumpOutletNodeNum = GetOnlySingleNode(state,
                                                                                              Alphas[5],
                                                                                              ErrorsFound,
                                                                                              Node.ConnectionObjectType.TemperingValve,
                                                                                              Alphas[0],
                                                                                              Node.FluidType.Water,
                                                                                              Node.ConnectionType.Sensor,
                                                                                              Node.CompFluidStream.Primary,
                                                                                              Node.ObjectIsNotParent)
        TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[1], Alphas[2], "Supply Side Water Nodes")

    for Item in range(1, state.dataPlantValves.NumTemperingValves + 1):
        SetupOutputVariable(state,
                            "Tempering Valve Flow Fraction",
                            ConstantUnits.None,
                            state.dataPlantValves.TemperValve[Item - 1].FlowDivFract,
                            TimeStepType.System,
                            StoreType.Average,
                            state.dataPlantValves.TemperValve[Item - 1].Name)

    if ErrorsFound:
        ShowFatalError(state, f"GetPlantValvesInput: {CurrentModuleObject} Errors found in input")

struct PlantValvesData(BaseGlobalStruct):
    var GetTemperingValves: Bool = True
    var OneTimeInitFlag: Bool = True
    var NumTemperingValves: Int = 0
    var TemperValve: List[TemperValveData] = List[TemperValveData]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.GetTemperingValves = True
        self.OneTimeInitFlag = True
        self.NumTemperingValves = 0
        self.TemperValve = List[TemperValveData]()
// ===== IMPORTS =====
from DataGlobals import *
from DataVectorTypes import Vector
from BranchNodeConnections import *
from Construction import *
from ConvectionCoefficients import *
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataLoopNode import *
from DataSurfaces import *
from EMSManager import *
from General import *
from GeneralRoutines import *
from .InputProcessing.InputProcessor import *
from Material import *
from NodeInputManager import *
from OutputProcessor import *
from Psychrometrics import *
from ScheduleManager import *
from SolarCollectors import *
from UtilityRoutines import *
from .Data.BaseData import BaseGlobalStruct
from ObjexxFCL.Array import *

// ===== HELPER FUNCTIONS for ObjexxFCL compatibility =====
def equal_dimensions(a: List[Int], b: List[Int]) -> Bool:
    return len(a) == len(b)

def pow_2(x: Float64) -> Float64:
    return x * x

def pow_3(x: Float64) -> Float64:
    return x * x * x

def pow_4(x: Float64) -> Float64:
    let x2 = x * x
    return x2 * x2

def pow_7(x: Float64) -> Float64:
    let x2 = x * x
    let x4 = x2 * x2
    return x4 * x2 * x

def sum(arr: List[Float64]) -> Float64:
    var s: Float64 = 0.0
    for val in arr:
        s += val
    return s

def sum_sub(arr: List[Float64]) -> Float64:
    return sum(arr)

def sum_product_sub(  // simplified version for one array and one member
    arr: List[Float64],
    arr2: List[Float64]) -> Float64:
    var s: Float64 = 0.0
    for i in range(len(arr)):
        s += arr[i] * arr2[i]
    return s

def array_sub(arr: List[SurfaceData], member: String, indices: List[Int]) -> List[Float64]:
    var result = List[Float64]()
    for i in indices:
        result.append(getattr(arr[i], member))
    return result

def sum_product_sub_with_area(
    arr: List[SurfaceData],
    member1: String,
    member2: String,
    indices: List[Int]) -> Float64:
    var s: Float64 = 0.0
    for i in indices:
        s += getattr(arr[i], member1) * getattr(arr[i], member2)
    return s

// ===== CONSTANTS =====
alias Layout_Square: Int = 1
alias Layout_Triangle: Int = 2
alias Correlation_Kutscher1994: Int = 1
alias Correlation_VanDeckerHollandsBrunger2001: Int = 2

// ===== STRUCTS =====
struct UTSCDataStruct:
    var Name: String
    var OSCMName: String
    var OSCMPtr: Int = 0
    var availSched: Schedule* = None
    var InletNode: List[Int] = List[Int]()
    var OutletNode: List[Int] = List[Int]()
    var ControlNode: List[Int] = List[Int]()
    var ZoneNode: List[Int] = List[Int]()
    var Layout: Int = 0
    var Correlation: Int = 0
    var HoleDia: Float64 = 0.0
    var Pitch: Float64 = 0.0
    var LWEmitt: Float64 = 0.0
    var SolAbsorp: Float64 = 0.0
    var CollRoughness: SurfaceRoughness = SurfaceRoughness.VeryRough
    var PlenGapThick: Float64 = 0.0
    var PlenCrossArea: Float64 = 0.0
    var NumSurfs: Int = 0
    var SurfPtrs: List[Int] = List[Int]()
    var Height: Float64 = 0.0
    var AreaRatio: Float64 = 0.0
    var CollectThick: Float64 = 0.0
    var Cv: Float64 = 0.0
    var Cd: Float64 = 0.0
    var NumOASysAttached: Int = 0
    var VsucErrIndex: Int = 0
    var ActualArea: Float64 = 0.0
    var ProjArea: Float64 = 0.0
    var Centroid: Vector = Vector(0.0, 0.0, 0.0)
    var Porosity: Float64 = 0.0
    var IsOn: Bool = False
    var Tplen: Float64 = 0.0
    var Tcoll: Float64 = 0.0
    var TplenLast: Float64 = 22.5
    var TcollLast: Float64 = 22.0
    var HrPlen: Float64 = 0.0
    var HcPlen: Float64 = 0.0
    var MdotVent: Float64 = 0.0
    var HdeltaNPL: Float64 = 0.0
    var TairHX: Float64 = 0.0
    var InletMDot: Float64 = 0.0
    var InletTempDB: Float64 = 0.0
    var Tilt: Float64 = 0.0
    var Azimuth: Float64 = 0.0
    var QdotSource: Float64 = 0.0
    var Isc: Float64 = 0.0
    var HXeff: Float64 = 0.0
    var Vsuction: Float64 = 0.0
    var PassiveACH: Float64 = 0.0
    var PassiveMdotVent: Float64 = 0.0
    var PassiveMdotWind: Float64 = 0.0
    var PassiveMdotTherm: Float64 = 0.0
    var PlenumVelocity: Float64 = 0.0
    var SupOutTemp: Float64 = 0.0
    var SupOutHumRat: Float64 = 0.0
    var SupOutEnth: Float64 = 0.0
    var SupOutMassFlow: Float64 = 0.0
    var SensHeatingRate: Float64 = 0.0
    var SensHeatingEnergy: Float64 = 0.0
    var SensCoolingRate: Float64 = 0.0
    var SensCoolingEnergy: Float64 = 0.0
    var UTSCEfficiency: Float64 = 0.0
    var UTSCCollEff: Float64 = 0.0

    // Default constructor is implicit

struct TranspiredCollectorData(BaseGlobalStruct):
    var NumUTSC: Int = 0
    var CheckEquipName: List[Bool] = List[Bool]()
    var GetInputFlag: Bool = True
    var UTSC: List[UTSCDataStruct] = List[UTSCDataStruct]()
    var MyOneTimeFlag: Bool = True
    var MySetPointCheckFlag: Bool = True
    var MyEnvrnFlag: List[Bool] = List[Bool]()

    def init_constant_state(self, inout state: EnergyPlusData):

    def init_state(self, inout state: EnergyPlusData):

    def clear_state(self):
        self.NumUTSC = 0
        self.GetInputFlag = True
        self.UTSC.deallocate()
        self.MyOneTimeFlag = True
        self.MySetPointCheckFlag = True
        self.MyEnvrnFlag.deallocate()

    // Default constructor

// ===== FUNCTIONS =====
def SimTranspiredCollector(inout state: EnergyPlusData, CompName: String, inout CompIndex: Int):
    using HVAC::TempControlTol
    var UTSCNum: Int = 0
    if state.dataTranspiredCollector.GetInputFlag:
        GetTranspiredCollectorInput(state)
        state.dataTranspiredCollector.GetInputFlag = False
    if CompIndex == 0:
        UTSCNum = Util::FindItemInList(CompName, state.dataTranspiredCollector.UTSC)
        if UTSCNum == 0:
            ShowFatalError(state, EnergyPlus::format("Transpired Collector not found={}", CompName))
        CompIndex = UTSCNum
    else:
        UTSCNum = CompIndex
        if UTSCNum > state.dataTranspiredCollector.NumUTSC or UTSCNum < 1:
            ShowFatalError(
                state,
                EnergyPlus::format("SimTranspiredCollector: Invalid CompIndex passed={}, Number of Transpired Collectors={}, UTSC name={}",
                                   UTSCNum,
                                   state.dataTranspiredCollector.NumUTSC,
                                   CompName))
        if state.dataTranspiredCollector.CheckEquipName[UTSCNum - 1]:   // 1-based -> 0-based
            if CompName != state.dataTranspiredCollector.UTSC[UTSCNum - 1].Name:
                ShowFatalError(
                    state,
                    EnergyPlus::format("SimTranspiredCollector: Invalid CompIndex passed={}, Transpired Collector name={}, stored Transpired Collector Name for that index={}",
                                       UTSCNum,
                                       CompName,
                                       state.dataTranspiredCollector.UTSC[UTSCNum - 1].Name))
            state.dataTranspiredCollector.CheckEquipName[UTSCNum - 1] = False
    InitTranspiredCollector(state, CompIndex)
    var UTSC_CI: &UTSCDataStruct = state.dataTranspiredCollector.UTSC[CompIndex - 1]   // 0-based
    UTSC_CI.IsOn = False
    if (UTSC_CI.availSched.getCurrentVal() > 0.0) and (UTSC_CI.InletMDot > 0.0):
        var ControlLTSet: Bool = False
        var ControlLTSchedule: Bool = False
        var ZoneLTSchedule: Bool = False
        var InletNode: List[Int] = UTSC_CI.InletNode
        var ControlNode: List[Int] = UTSC_CI.ControlNode
        assert(equal_dimensions(InletNode, ControlNode))
        assert(equal_dimensions(InletNode, UTSC_CI.ZoneNode))
        for i in range(len(InletNode)):
            if state.dataLoopNodes.Node[InletNode[i]].Temp + TempControlTol < state.dataLoopNodes.Node[ControlNode[i]].TempSetPoint:
                ControlLTSet = True
            if state.dataLoopNodes.Node[InletNode[i]].Temp + TempControlTol < UTSC_CI.freeHeatSetPointSched.getCurrentVal():
                ControlLTSchedule = True
            if state.dataLoopNodes.Node[UTSC_CI.ZoneNode[i]].Temp + TempControlTol < UTSC_CI.freeHeatSetPointSched.getCurrentVal():
                ZoneLTSchedule = True
        if ControlLTSet or (ControlLTSchedule and ZoneLTSchedule):
            UTSC_CI.IsOn = True
    if state.dataTranspiredCollector.UTSC[UTSCNum - 1].IsOn:
        CalcActiveTranspiredCollector(state, UTSCNum)
    else:
        CalcPassiveTranspiredCollector(state, UTSCNum)
    UpdateTranspiredCollector(state, UTSCNum)

def GetTranspiredCollectorInput(inout state: EnergyPlusData):
    alias routineName: String = "GetTranspiredCollectorInput"
    using DataSurfaces::OtherSideCondModeledExt
    using DataSurfaces::SurfaceData
    using Node::GetOnlySingleNode
    using Node::ObjectIsNotParent
    using Node::TestCompSet
    var Alphas: List[String] = List[String]()
    var Item: Int = 0
    var Numbers: List[Float64] = List[Float64](11)
    for i in range(11):
        Numbers[i] = 0.0
    var NumAlphas: Int = 0
    var NumNumbers: Int = 0
    var MaxNumAlphas: Int = 0
    var MaxNumNumbers: Int = 0
    var Dummy: Int = 0
    var IOStatus: Int = 0
    var ErrorsFound: Bool = False
    var Found: Int = 0
    var AlphaOffset: Int = 0
    var Roughness: String = ""
    var ThisSurf: Int = 0
    var AvgAzimuth: Float64 = 0.0
    var AvgTilt: Float64 = 0.0
    var SurfID: Int = 0
    var TiltRads: Float64 = 0.0
    var tempHdeltaNPL: Float64 = 0.0
    var NumUTSCSplitter: Int = 0
    var AlphasSplit: List[String] = List[String]()
    var ItemSplit: Int = 0
    var NumbersSplit: List[Float64] = List[Float64](1)
    for i in range(1):
        NumbersSplit[i] = 0.0
    var NumAlphasSplit: Int = 0
    var NumNumbersSplit: Int = 0
    var MaxNumAlphasSplit: Int = 0
    var MaxNumNumbersSplit: Int = 0
    var IOStatusSplit: Int = 0
    var NumOASys: Int = 0
    var ACountBase: Int = 0
    var SplitterNameOK: List[Bool] = List[Bool]()
    var CurrentModuleObject: String = ""
    var CurrentModuleMultiObject: String = ""
    CurrentModuleObject = "SolarCollector:UnglazedTranspired"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, Dummy, MaxNumAlphas, MaxNumNumbers)
    if MaxNumNumbers != 11:
        ShowSevereError(
            state,
            EnergyPlus::format("GetTranspiredCollectorInput: {} Object Definition indicates not = 11 Number Objects, Number Indicated={}",
                               CurrentModuleObject,
                               MaxNumNumbers))
        ErrorsFound = True
    Alphas.allocate(MaxNumAlphas)
    for i in range(MaxNumAlphas):
        Alphas[i] = ""
    Numbers = [0.0] * 11  // reset to zero
    state.dataTranspiredCollector.NumUTSC = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    CurrentModuleMultiObject = "SolarCollector:UnglazedTranspired:Multisystem"
    NumUTSCSplitter = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleMultiObject)
    state.dataTranspiredCollector.UTSC.allocate(state.dataTranspiredCollector.NumUTSC)
    state.dataTranspiredCollector.CheckEquipName.dimension(state.dataTranspiredCollector.NumUTSC, True)
    SplitterNameOK.dimension(NumUTSCSplitter, False)
    for Item in range(1, state.dataTranspiredCollector.NumUTSC + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, CurrentModuleObject, Item, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus,
            state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])  // 0-based
        state.dataTranspiredCollector.UTSC[Item - 1].Name = Alphas[0]  // 1->0
        if NumUTSCSplitter > 0:
            state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
                state, CurrentModuleMultiObject, Dummy, MaxNumAlphasSplit, MaxNumNumbersSplit)
            if MaxNumNumbersSplit != 0:
                ShowSevereError(
                    state,
                    EnergyPlus::format("GetTranspiredCollectorInput: {} Object Definition indicates not = 0 Number Objects, Number Indicated={}",
                                       CurrentModuleMultiObject,
                                       MaxNumNumbersSplit))
                ErrorsFound = True
            if not allocated(AlphasSplit):
                AlphasSplit.allocate(MaxNumAlphasSplit)
            NumbersSplit = [0.0] * 1
            for i in range(len(AlphasSplit)):
                AlphasSplit[i] = ""
            for ItemSplit in range(1, NumUTSCSplitter + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state, CurrentModuleMultiObject, ItemSplit, AlphasSplit, NumAlphasSplit, NumbersSplit, NumNumbersSplit, IOStatusSplit)
                if not (Util::SameString(AlphasSplit[0], Alphas[0])):
                    continue
                SplitterNameOK[ItemSplit - 1] = True
                state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached = Int(floor(NumAlphasSplit / 4.0))  // though NumAlphasSplit is Int, floor not needed
                if (mod(NumAlphasSplit, 4)) != 1:
                    ShowSevereError(
                        state,
                        EnergyPlus::format("GetTranspiredCollectorInput: {} Object Definition indicates not uniform quadtuples of nodes for {}",
                                           CurrentModuleMultiObject,
                                           AlphasSplit[0]))
                    ErrorsFound = True
                state.dataTranspiredCollector.UTSC[Item - 1].InletNode.allocate(state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached)
                for i in range(len(state.dataTranspiredCollector.UTSC[Item - 1].InletNode)):
                    state.dataTranspiredCollector.UTSC[Item - 1].InletNode[i] = 0
                state.dataTranspiredCollector.UTSC[Item - 1].OutletNode.allocate(state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached)
                for i in range(len(state.dataTranspiredCollector.UTSC[Item - 1].OutletNode)):
                    state.dataTranspiredCollector.UTSC[Item - 1].OutletNode[i] = 0
                state.dataTranspiredCollector.UTSC[Item - 1].ControlNode.allocate(state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached)
                for i in range(len(state.dataTranspiredCollector.UTSC[Item - 1].ControlNode)):
                    state.dataTranspiredCollector.UTSC[Item - 1].ControlNode[i] = 0
                state.dataTranspiredCollector.UTSC[Item - 1].ZoneNode.allocate(state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached)
                for i in range(len(state.dataTranspiredCollector.UTSC[Item - 1].ZoneNode)):
                    state.dataTranspiredCollector.UTSC[Item - 1].ZoneNode[i] = 0
                for NumOASys in range(1, state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached + 1):
                    ACountBase = (NumOASys - 1) * 4 + 2  // 1-based index in original AlphasSplit
                    state.dataTranspiredCollector.UTSC[Item - 1].InletNode[NumOASys - 1] =
                        GetOnlySingleNode(state,
                                          AlphasSplit[ACountBase - 1],   // adjust to 0-based
                                          ErrorsFound,
                                          Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                          AlphasSplit[0],
                                          Node::FluidType.Air,
                                          Node::ConnectionType.Inlet,
                                          static_cast[Node::CompFluidStream](NumOASys),
                                          ObjectIsNotParent)
                    state.dataTranspiredCollector.UTSC[Item - 1].OutletNode[NumOASys - 1] =
                        GetOnlySingleNode(state,
                                          AlphasSplit[ACountBase],   // +1 in original, so ACountBase (1-based) -> index ACountBase-1
                                          ErrorsFound,
                                          Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                          AlphasSplit[0],
                                          Node::FluidType.Air,
                                          Node::ConnectionType.Outlet,
                                          static_cast[Node::CompFluidStream](NumOASys),
                                          ObjectIsNotParent)
                    TestCompSet(state,
                                CurrentModuleObject,
                                AlphasSplit[0],
                                AlphasSplit[ACountBase - 1],
                                AlphasSplit[ACountBase],
                                "Transpired Collector Air Nodes")
                    state.dataTranspiredCollector.UTSC[Item - 1].ControlNode[NumOASys - 1] =
                        GetOnlySingleNode(state,
                                          AlphasSplit[ACountBase + 1],   // ACountBase+1 -> index ACountBase
                                          ErrorsFound,
                                          Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                          AlphasSplit[0],
                                          Node::FluidType.Air,
                                          Node::ConnectionType.Sensor,
                                          Node::CompFluidStream.Primary,
                                          ObjectIsNotParent)
                    state.dataTranspiredCollector.UTSC[Item - 1].ZoneNode[NumOASys - 1] =
                        GetOnlySingleNode(state,
                                          AlphasSplit[ACountBase + 2],   // ACountBase+2 -> index ACountBase+1
                                          ErrorsFound,
                                          Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                          AlphasSplit[0],
                                          Node::FluidType.Air,
                                          Node::ConnectionType.Sensor,
                                          Node::CompFluidStream.Primary,
                                          ObjectIsNotParent)
                // end each OA System
            // end each Multisystem
        // end if any UTSC Multisystem
        state.dataTranspiredCollector.UTSC[Item - 1].OSCMName = Alphas[1]  // Alphas(2) -> index 1
        Found = Util::FindItemInList(state.dataTranspiredCollector.UTSC[Item - 1].OSCMName, state.dataSurface.OSCM)
        if Found == 0:
            ShowSevereError(state,
                            EnergyPlus::format("{} not found={} in {} ={}",
                                               state.dataIPShortCut.cAlphaFieldNames[1],   // field 2 -> index 1
                                               state.dataTranspiredCollector.UTSC[Item - 1].OSCMName,
                                               CurrentModuleObject,
                                               state.dataTranspiredCollector.UTSC[Item - 1].Name))
            ErrorsFound = True
        state.dataTranspiredCollector.UTSC[Item - 1].OSCMPtr = Found
        if state.dataIPShortCut.lAlphaFieldBlanks[2]:   // field 3 -> index 2
            state.dataTranspiredCollector.UTSC[Item - 1].availSched = Sched::GetScheduleAlwaysOn(state)
        else:
            state.dataTranspiredCollector.UTSC[Item - 1].availSched = Sched::GetSchedule(state, Alphas[2])
            if state.dataTranspiredCollector.UTSC[Item - 1].availSched is None:
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[2], Alphas[2])
                ErrorsFound = True
                continue
        if state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached == 0:
            state.dataTranspiredCollector.UTSC[Item - 1].NumOASysAttached = 1
            state.dataTranspiredCollector.UTSC[Item - 1].InletNode.allocate(1)
            state.dataTranspiredCollector.UTSC[Item - 1].InletNode[0] = 0
            state.dataTranspiredCollector.UTSC[Item - 1].OutletNode.allocate(1)
            state.dataTranspiredCollector.UTSC[Item - 1].OutletNode[0] = 0
            state.dataTranspiredCollector.UTSC[Item - 1].ControlNode.allocate(1)
            state.dataTranspiredCollector.UTSC[Item - 1].ControlNode[0] = 0
            state.dataTranspiredCollector.UTSC[Item - 1].ZoneNode.allocate(1)
            state.dataTranspiredCollector.UTSC[Item - 1].ZoneNode[0] = 0
            state.dataTranspiredCollector.UTSC[Item - 1].InletNode[0] =
                GetOnlySingleNode(state,
                                  Alphas[3],   // Alphas(4) -> index 3
                                  ErrorsFound,
                                  Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                  Alphas[0],
                                  Node::FluidType.Air,
                                  Node::ConnectionType.Inlet,
                                  Node::CompFluidStream.Primary,
                                  ObjectIsNotParent)
            state.dataTranspiredCollector.UTSC[Item - 1].OutletNode[0] =
                GetOnlySingleNode(state,
                                  Alphas[4],   // Alphas(5) -> index 4
                                  ErrorsFound,
                                  Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                  Alphas[0],
                                  Node::FluidType.Air,
                                  Node::ConnectionType.Outlet,
                                  Node::CompFluidStream.Primary,
                                  ObjectIsNotParent)
            TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[3], Alphas[4], "Transpired Collector Air Nodes")
            state.dataTranspiredCollector.UTSC[Item - 1].ControlNode[0] =
                GetOnlySingleNode(state,
                                  Alphas[5],   // Alphas(6) -> index 5
                                  ErrorsFound,
                                  Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                  Alphas[0],
                                  Node::FluidType.Air,
                                  Node::ConnectionType.Sensor,
                                  Node::CompFluidStream.Primary,
                                  ObjectIsNotParent)
            state.dataTranspiredCollector.UTSC[Item - 1].ZoneNode[0] =
                GetOnlySingleNode(state,
                                  Alphas[6],   // Alphas(7) -> index 6
                                  ErrorsFound,
                                  Node::ConnectionObjectType.SolarCollectorUnglazedTranspired,
                                  Alphas[0],
                                  Node::FluidType.Air,
                                  Node::ConnectionType.Sensor,
                                  Node::CompFluidStream.Primary,
                                  ObjectIsNotParent)
        // end if no splitter
        if state.dataIPShortCut.lAlphaFieldBlanks[7]:   // field 8 -> index 7
            ShowSevereEmptyField(state, eoh, state.dataIPShortCut.cAlphaFieldNames[7])
            ErrorsFound = True
        else:
            state.dataTranspiredCollector.UTSC[Item - 1].freeHeatSetPointSched = Sched::GetSchedule(state, Alphas[7])
            if state.dataTranspiredCollector.UTSC[Item - 1].freeHeatSetPointSched is None:
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[7], Alphas[7])
                ErrorsFound = True
                continue
        if Util::SameString(Alphas[8], "Triangle"):   // field 9 -> index 8
            state.dataTranspiredCollector.UTSC[Item - 1].Layout = Layout_Triangle
        elif Util::SameString(Alphas[8], "Square"):
            state.dataTranspiredCollector.UTSC[Item - 1].Layout = Layout_Square
        else:
            ShowSevereError(state,
                            EnergyPlus::format("{} has incorrect entry of {} in {} ={}",
                                               state.dataIPShortCut.cAlphaFieldNames[8],
                                               Alphas[8],
                                               CurrentModuleObject,
                                               state.dataTranspiredCollector.UTSC[Item - 1].Name))
            ErrorsFound = True
            continue
        if Util::SameString(Alphas[9], "Kutscher1994"):   // field 10 -> index 9
            state.dataTranspiredCollector.UTSC[Item - 1].Correlation = Correlation_Kutscher1994
        elif Util::SameString(Alphas[9], "VanDeckerHollandsBrunger2001"):
            state.dataTranspiredCollector.UTSC[Item - 1].Correlation = Correlation_VanDeckerHollandsBrunger2001
        else:
            ShowSevereError(state,
                            EnergyPlus::format("{} has incorrect entry of {} in {} ={}",
                                               state.dataIPShortCut.cAlphaFieldNames[9],
                                               Alphas[8],  // original uses Alphas(9) but that is index 8? Actually field10 -> Alphas(10) index9. But original code uses Alphas(9) (field10) here? Wait, original line: Alphas(9) for correlation? Checking original: it uses Alphas(10) for correlation field. Actually original: "Util::SameString(Alphas(10), "Kutscher1994")" So field10 is Alphas(10) -> index 9. And error message uses Alphas(9) but I think it's a bug. We'll stick with original: use Alphas[9].
                                               CurrentModuleObject,
                                               state.dataTranspiredCollector.UTSC[Item - 1].Name))
            ErrorsFound = True
            continue
        Roughness = Alphas[10]   // field 11 -> index 10
        if Util::SameString(Roughness, "VeryRough"):
            state.dataTranspiredCollector.UTSC[Item - 1].CollRoughness = Material::SurfaceRoughness.VeryRough
        if Util::SameString(Roughness, "Rough"):
            state.dataTranspiredCollector.UTSC[Item - 1].CollRoughness = Material::SurfaceRoughness.Rough
        if Util::SameString(Roughness, "MediumRough"):
            state.dataTranspiredCollector.UTSC[Item - 1].CollRoughness = Material::SurfaceRoughness.MediumRough
        if Util::SameString(Roughness, "MediumSmooth"):
            state.dataTranspiredCollector.UTSC[Item - 1].CollRoughness = Material::SurfaceRoughness.MediumSmooth
        if Util::SameString(Roughness, "Smooth"):
            state.dataTranspiredCollector.UTSC[Item - 1].CollRoughness = Material::SurfaceRoughness.Smooth
        if Util::SameString(Roughness, "VerySmooth"):
            state.dataTranspiredCollector.UTSC[Item - 1].CollRoughness = Material::SurfaceRoughness.VerySmooth
        if state.dataTranspiredCollector.UTSC[Item - 1].CollRoughness == Material::SurfaceRoughness.Invalid:
            ShowSevereError(state,
                            EnergyPlus::format("{} has incorrect entry of {} in {} ={}",
                                               state.dataIPShortCut.cAlphaFieldNames[10],
                                               Alphas[10],
                                               CurrentModuleObject,
                                               state.dataTranspiredCollector.UTSC[Item - 1].Name))
            ErrorsFound = True
        AlphaOffset = 11
        state.dataTranspiredCollector.UTSC[Item - 1].NumSurfs = NumAlphas - AlphaOffset
        if state.dataTranspiredCollector.UTSC[Item - 1].NumSurfs == 0:
            ShowSevereError(state,
                            EnergyPlus::format("No underlying surfaces specified in {} ={}",
                                               CurrentModuleObject,
                                               state.dataTranspiredCollector.UTSC[Item - 1].Name))
            ErrorsFound = True
            continue
        state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs.allocate(state.dataTranspiredCollector.UTSC[Item - 1].NumSurfs)
        for i in range(len(state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs)):
            state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs[i] = 0
        for ThisSurf in range(1, state.dataTranspiredCollector.UTSC[Item - 1].NumSurfs + 1):
            Found = Util::FindItemInList(Alphas[AlphaOffset + ThisSurf - 1], state.dataSurface.Surface)  // AlphaOffset is 11, but Alphas is 0-based, so index = AlphaOffset-1 + (ThisSurf-1) = 10+ (ThisSurf-1)
            if Found == 0:
                ShowSevereError(state,
                                EnergyPlus::format("Surface Name not found={} in {} ={}",
                                                   Alphas[AlphaOffset + ThisSurf - 1], // adjusted
                                                   CurrentModuleObject,
                                                   state.dataTranspiredCollector.UTSC[Item - 1].Name))
                ErrorsFound = True
                continue
            if not state.dataSurface.Surface[Found - 1].HeatTransSurf:
                ShowSevereError(state,
                                EnergyPlus::format("Surface {} not of Heat Transfer type in {} ={}",
                                                   Alphas[AlphaOffset + ThisSurf - 1],
                                                   CurrentModuleObject,
                                                   state.dataTranspiredCollector.UTSC[Item - 1].Name))
                ErrorsFound = True
                continue
            if not state.dataSurface.Surface[Found - 1].ExtSolar:
                ShowSevereError(state,
                                EnergyPlus::format("Surface {} not exposed to sun in {} ={}",
                                                   Alphas[AlphaOffset + ThisSurf - 1],
                                                   CurrentModuleObject,
                                                   state.dataTranspiredCollector.UTSC[Item - 1].Name))
                ErrorsFound = True
                continue
            if not state.dataSurface.Surface[Found - 1].ExtWind:
                ShowSevereError(state,
                                EnergyPlus::format("Surface {} not exposed to wind in {} ={}",
                                                   Alphas[AlphaOffset + ThisSurf - 1],
                                                   CurrentModuleObject,
                                                   state.dataTranspiredCollector.UTSC[Item - 1].Name))
                ErrorsFound = True
                continue
            if state.dataSurface.Surface[Found - 1].ExtBoundCond != OtherSideCondModeledExt:
                ShowSevereError(state,
                                EnergyPlus::format("Surface {} does not have OtherSideConditionsModel for exterior boundary conditions in {} ={}",
                                                   Alphas[AlphaOffset + ThisSurf - 1],
                                                   CurrentModuleObject,
                                                   state.dataTranspiredCollector.UTSC[Item - 1].Name))
                ErrorsFound = True
                continue
            if (state.dataSurface.Surface[Found - 1].Tilt < -95.0) or (state.dataSurface.Surface[Found - 1].Tilt > 95.0):
                ShowWarningError(state,
                                 EnergyPlus::format("Suspected input problem with collector surface = {}", Alphas[AlphaOffset + ThisSurf - 1]))
                ShowContinueError(state,
                                  EnergyPlus::format("Entered in {} = {}",
                                                     state.dataIPShortCut.cCurrentModuleObject,
                                                     state.dataTranspiredCollector.UTSC[Item - 1].Name))
                ShowContinueError(state, "Surface used for solar collector faces down")
                ShowContinueError(state,
                                  EnergyPlus::format("Surface tilt angle (degrees from ground outward normal) = {:.2R}",
                                                     state.dataSurface.Surface[Found - 1].Tilt))
            state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs[ThisSurf - 1] = Found
        if ErrorsFound:
            continue
        var surfaceArea: Float64 = sum_sub(state.dataSurface.Surface, &SurfaceData.Area, state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs)
        AvgAzimuth =
            sum_product_sub(
                state.dataSurface.Surface, &SurfaceData.Azimuth, &SurfaceData.Area, state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs) /
            surfaceArea
        AvgTilt = sum_product_sub(
                      state.dataSurface.Surface, &SurfaceData.Tilt, &SurfaceData.Area, state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs) /
                  surfaceArea
        for ThisSurf in range(1, state.dataTranspiredCollector.UTSC[Item - 1].NumSurfs + 1):
            SurfID = state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs[ThisSurf - 1]
            if General::rotAzmDiffDeg(state.dataSurface.Surface[SurfID - 1].Azimuth, AvgAzimuth) > 15.0:
                ShowWarningError(state,
                                 format("Surface {} has Azimuth different from others in the group associated with {} ={}",
                                             state.dataSurface.Surface[SurfID - 1].Name,
                                             CurrentModuleObject,
                                             state.dataTranspiredCollector.UTSC[Item - 1].Name))
            if abs(state.dataSurface.Surface[SurfID - 1].Tilt - AvgTilt) > 10.0:
                ShowWarningError(state,
                                 format("Surface {} has Tilt different from others in the group associated with {} ={}",
                                             state.dataSurface.Surface[SurfID - 1].Name,
                                             CurrentModuleObject,
                                             state.dataTranspiredCollector.UTSC[Item - 1].Name))
        state.dataTranspiredCollector.UTSC[Item - 1].Tilt = AvgTilt
        state.dataTranspiredCollector.UTSC[Item - 1].Azimuth = AvgAzimuth
        state.dataTranspiredCollector.UTSC[Item - 1].Centroid.z = sum_product_sub(state.dataSurface.Surface,
                                                                                   &SurfaceData.Centroid,
                                                                                   &Vector.z,
                                                                                   state.dataSurface.Surface,
                                                                                   &SurfaceData.Area,
                                                                                   state.dataTranspiredCollector.UTSC[Item - 1].SurfPtrs) /
                                                               surfaceArea
        state.dataTranspiredCollector.UTSC[Item - 1].HoleDia = Numbers[0]
        state.dataTranspiredCollector.UTSC[Item - 1].Pitch = Numbers[1]
        state.dataTranspiredCollector.UTSC[Item - 1].LWEmitt = Numbers[2]
        state.dataTranspiredCollector.UTSC[Item - 1].SolAbsorp = Numbers[3]
        state.dataTranspiredCollector.UTSC[Item - 1].Height = Numbers[4]
        state.dataTranspiredCollector.UTSC[Item - 1].PlenGapThick = Numbers[5]
        if state.dataTranspiredCollector.UTSC[Item - 1].PlenGapThick <= 0.0:
            ShowSevereError(state,
                            format("Plenum gap must be greater than Zero in {} ={}",
                                        CurrentModuleObject,
                                        state.dataTranspiredCollector.UTSC[Item - 1].Name))
            continue
        state.dataTranspiredCollector.UTSC[Item - 1].PlenCrossArea = Numbers[6]
        state.dataTranspiredCollector.UTSC[Item - 1].AreaRatio = Numbers[7]
        state.dataTranspiredCollector.UTSC[Item - 1].CollectThick = Numbers[8]
        state.dataTranspiredCollector.UTSC[Item - 1].Cv = Numbers[9]
        state.dataTranspiredCollector.UTSC[Item - 1].Cd = Numbers[10]
        state.dataTranspiredCollector.UTSC[Item - 1].ProjArea = surfaceArea
        if state.dataTranspiredCollector.UTSC[Item - 1].ProjArea == 0:
            ShowSevereError(state,
                            format("Gross area of underlying surfaces is zero in {} ={}",
                                        CurrentModuleObject,
                                        state.dataTranspiredCollector.UTSC[Item - 1].Name))
            continue
        state.dataTranspiredCollector.UTSC[Item - 1].ActualArea =
            state.dataTranspiredCollector.UTSC[Item - 1].ProjArea * state.dataTranspiredCollector.UTSC[Item - 1].AreaRatio
        switch state.dataTranspiredCollector.UTSC[Item - 1].Layout:
            case Layout_Triangle:
                state.dataTranspiredCollector.UTSC[Item - 1].Porosity =
                    0.907 * pow_2(state.dataTranspiredCollector.UTSC[Item - 1].HoleDia /
                                  state.dataTranspiredCollector.UTSC[Item - 1].Pitch)
                break
            case Layout_Square:
                state.dataTranspiredCollector.UTSC[Item - 1].Porosity =
                    (Constant::Pi / 4.0) * pow_2(state.dataTranspiredCollector.UTSC[Item - 1].HoleDia) /
                    pow_2(state.dataTranspiredCollector.UTSC[Item - 1].Pitch)
                break
            default:
                break
        TiltRads = abs(AvgTilt) * Constant::DegToRad
        tempHdeltaNPL = sin(TiltRads) * state.dataTranspiredCollector.UTSC[Item - 1].Height / 4.0
        state.dataTranspiredCollector.UTSC[Item - 1].HdeltaNPL = max(tempHdeltaNPL, state.dataTranspiredCollector.UTSC[Item - 1].PlenGapThick)
        SetupOutputVariable(state,
                            "Solar Collector Heat Exchanger Effectiveness",
                            Constant::Units.None,
                            state.dataTranspiredCollector.UTSC[Item - 1].HXeff,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Leaving Air Temperature",
                            Constant::Units.C,
                            state.dataTranspiredCollector.UTSC[Item - 1].TairHX,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Outside Face Suction Velocity",
                            Constant::Units.m_s,
                            state.dataTranspiredCollector.UTSC[Item - 1].Vsuction,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Surface Temperature",
                            Constant::Units.C,
                            state.dataTranspiredCollector.UTSC[Item - 1].Tcoll,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Plenum Air Temperature",
                            Constant::Units.C,
                            state.dataTranspiredCollector.UTSC[Item - 1].Tplen,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Sensible Heating Rate",
                            Constant::Units.W,
                            state.dataTranspiredCollector.UTSC[Item - 1].SensHeatingRate,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Sensible Heating Energy",
                            Constant::Units.J,
                            state.dataTranspiredCollector.UTSC[Item - 1].SensHeatingEnergy,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Sum,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name,
                            Constant::eResource.SolarAir,
                            OutputProcessor::Group.HVAC,
                            OutputProcessor::EndUseCat.HeatProduced)
        SetupOutputVariable(state,
                            "Solar Collector Natural Ventilation Air Change Rate",
                            Constant::Units.ach,
                            state.dataTranspiredCollector.UTSC[Item - 1].PassiveACH,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Natural Ventilation Mass Flow Rate",
                            Constant::Units.kg_s,
                            state.dataTranspiredCollector.UTSC[Item - 1].PassiveMdotVent,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Wind Natural Ventilation Mass Flow Rate",
                            Constant::Units.kg_s,
                            state.dataTranspiredCollector.UTSC[Item - 1].PassiveMdotWind,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Buoyancy Natural Ventilation Mass Flow Rate",
                            Constant::Units.kg_s,
                            state.dataTranspiredCollector.UTSC[Item - 1].PassiveMdotTherm,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Incident Solar Radiation",
                            Constant::Units.W_m2,
                            state.dataTranspiredCollector.UTSC[Item - 1].Isc,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector System Efficiency",
                            Constant::Units.None,
                            state.dataTranspiredCollector.UTSC[Item - 1].UTSCEfficiency,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
        SetupOutputVariable(state,
                            "Solar Collector Surface Efficiency",
                            Constant::Units.None,
                            state.dataTranspiredCollector.UTSC[Item - 1].UTSCCollEff,
                            OutputProcessor::TimeStepType.System,
                            OutputProcessor::StoreType.Average,
                            state.dataTranspiredCollector.UTSC[Item - 1].Name)
    for ItemSplit in range(1, NumUTSCSplitter + 1):
        if not SplitterNameOK[ItemSplit - 1]:
            ShowSevereError(state, "Did not find a match, check names for Solar Collectors:Transpired Collector:Multisystem")
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "GetTranspiredCollectorInput: Errors found in input")
    Alphas.deallocate()

def InitTranspiredCollector(inout state: EnergyPlusData, UTSCNum: Int):
    var DoSetPointTest: Bool = state.dataHVACGlobal.DoSetPointTest
    using DataSurfaces::SurfaceData
    using EMSManager::CheckIfNodeSetPointManagedByEMS
    var Tamb: Float64
    if state.dataTranspiredCollector.MyOneTimeFlag:
        for thisUTSC in range(1, state.dataTranspiredCollector.NumUTSC + 1):
            if state.dataTranspiredCollector.UTSC[thisUTSC - 1].Layout == Layout_Triangle:
                switch state.dataTranspiredCollector.UTSC[thisUTSC - 1].Correlation:
                    case Correlation_Kutscher1994:
                        state.dataTranspiredCollector.UTSC[thisUTSC - 1].Pitch = state.dataTranspiredCollector.UTSC[thisUTSC - 1].Pitch
                        break
                    case Correlation_VanDeckerHollandsBrunger2001:
                        state.dataTranspiredCollector.UTSC[thisUTSC - 1].Pitch /= 1.6
                        break
                    default:
                        break
            if state.dataTranspiredCollector.UTSC[thisUTSC - 1].Layout == Layout_Square:
                switch state.dataTranspiredCollector.UTSC[thisUTSC - 1].Correlation:
                    case Correlation_Kutscher1994:
                        state.dataTranspiredCollector.UTSC[thisUTSC - 1].Pitch *= 1.6
                        break
                    case Correlation_VanDeckerHollandsBrunger2001:
                        state.dataTranspiredCollector.UTSC[thisUTSC - 1].Pitch = state.dataTranspiredCollector.UTSC[thisUTSC - 1].Pitch
                        break
                    default:
                        break
        state.dataTranspiredCollector.MyEnvrnFlag.dimension(state.dataTranspiredCollector.NumUTSC, True)
        state.dataTranspiredCollector.MyOneTimeFlag = False
    if not state.dataGlobal.SysSizingCalc and state.dataTranspiredCollector.MySetPointCheckFlag and DoSetPointTest:
        for UTSCUnitNum in range(1, state.dataTranspiredCollector.NumUTSC + 1):
            for SplitBranch in range(1, state.dataTranspiredCollector.UTSC[UTSCUnitNum - 1].NumOASysAttached + 1):
                var ControlNode: Int = state.dataTranspiredCollector.UTSC[UTSCUnitNum - 1].ControlNode[SplitBranch - 1]
                if ControlNode > 0:
                    if state.dataLoopNodes.Node[ControlNode].TempSetPoint == Node::SensedNodeFlagValue:
                        if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                            ShowSevereError(
                                state,
                                format("Missing temperature setpoint for UTSC {}", state.dataTranspiredCollector.UTSC[UTSCUnitNum - 1].Name))
                            ShowContinueError(state, " use a Setpoint Manager to establish a setpoint at the unit control node.")
                            state.dataHVACGlobal.SetPointErrorFlag = True
                        else:
                            CheckIfNodeSetPointManagedByEMS(state, ControlNode, HVAC::CtrlVarType.Temp, state.dataHVACGlobal.SetPointErrorFlag)
                            if state.dataHVACGlobal.SetPointErrorFlag:
                                ShowSevereError(state,
                                                format("Missing temperature setpoint for UTSC {}",
                                                            state.dataTranspiredCollector.UTSC[UTSCUnitNum - 1].Name))
                                ShowContinueError(state, " use a Setpoint Manager to establish a setpoint at the unit control node.")
                                ShowContinueError(state, "Or add EMS Actuator to provide temperature setpoint at this node")
        state.dataTranspiredCollector.MySetPointCheckFlag = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataTranspiredCollector.MyEnvrnFlag[UTSCNum - 1]:
        state.dataTranspiredCollector.UTSC[UTSCNum - 1].TplenLast = 22.5
        state.dataTranspiredCollector.UTSC[UTSCNum - 1].TcollLast = 22.0
        state.dataTranspiredCollector.MyEnvrnFlag[UTSCNum - 1] = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataTranspiredCollector.MyEnvrnFlag[UTSCNum - 1] = True
    var sum_area: Float64 = 0.0
    for SurfNum in state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs:
        sum_area += state.dataSurface.Surface[SurfNum - 1].Area
    if not state.dataEnvrn.IsRain:
        var sum_produc_area_drybulb: Float64 = 0.0
        for SurfNum in state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs:
            sum_produc_area_drybulb += state.dataSurface.Surface[SurfNum - 1].Area * state.dataSurface.SurfOutDryBulbTemp[SurfNum]
        Tamb = sum_produc_area_drybulb / sum_area
    else:
        var sum_produc_area_wetbulb: Float64 = 0.0
        for SurfNum in state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs:
            sum_produc_area_wetbulb += state.dataSurface.Surface[SurfNum - 1].Area * state.dataSurface.SurfOutWetBulbTemp[SurfNum]
        Tamb = sum_produc_area_wetbulb / sum_area
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].InletMDot =
        sum_sub(state.dataLoopNodes.Node, &Node::NodeData.MassFlowRate, state.dataTranspiredCollector.UTSC[UTSCNum - 1].InletNode)
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].IsOn = False
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].Tplen = state.dataTranspiredCollector.UTSC[UTSCNum - 1].TplenLast
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].Tcoll = state.dataTranspiredCollector.UTSC[UTSCNum - 1].TcollLast
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].TairHX = Tamb
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].MdotVent = 0.0
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].HXeff = 0.0
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].Isc = 0.0
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].UTSCEfficiency = 0.0
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].UTSCCollEff = 0.0

def CalcActiveTranspiredCollector(inout state: EnergyPlusData, UTSCNum: Int):
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    using DataSurfaces::SurfaceData
    using Psychrometrics::PsyCpAirFnW
    using Psychrometrics::PsyHFnTdbW
    using Psychrometrics::PsyRhoAirFnPbTdbW
    alias nu: Float64 = 15.66e-6
    alias k: Float64 = 0.0267
    alias Sigma: Float64 = 5.6697e-08
    var HSkyARR: List[Float64] = List[Float64]()
    var HGroundARR: List[Float64] = List[Float64]()
    var HAirARR: List[Float64] = List[Float64]()
    var HPlenARR: List[Float64] = List[Float64]()
    var LocalWindArr: List[Float64] = List[Float64]()
    var HSrdSurfARR: List[Float64] = List[Float64]()
    var RhoAir: Float64
    var CpAir: Float64
    var holeArea: Float64
    var Tamb: Float64
    var A: Float64
    var Vholes: Float64
    var Vsuction: Float64
    var Vplen: Float64
    var HcPlen: Float64
    var D: Float64
    var ReD: Float64
    var P: Float64
    var Por: Float64
    var Mdot: Float64
    var QdotSource: Float64
    var ThisSurf: Int
    var NumSurfs: Int
    var Roughness: SurfaceRoughness
    var SolAbs: Float64
    var AbsExt: Float64
    var TempExt: Float64
    var HMovInsul: Float64
    var HExt: Float64
    var AbsThermSurf: Float64
    var TsoK: Float64
    var TscollK: Float64
    var AreaSum: Float64
    var Vwind: Float64
    var HrSky: Float64
    var HrGround: Float64
    var HrAtm: Float64
    var Isc: Float64
    var HrPlen: Float64
    var Tso: Float64
    var HcWind: Float64
    var NuD: Float64
    var U: Float64
    var HXeff: Float64
    var t: Float64
    var ReS: Float64
    var ReW: Float64
    var ReB: Float64
    var ReH: Float64
    var Tscoll: Float64
    var TaHX: Float64
    var Taplen: Float64
    var SensHeatingRate: Float64
    var AlessHoles: Float64
    var s_mat: auto = state.dataMaterial
    var sum_area: Float64 = 0.0
    for SurfNum in state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs:
        sum_area += state.dataSurface.Surface[SurfNum - 1].Area
    if not state.dataEnvrn.IsRain:
        var sum_produc_area_drybulb: Float64 = 0.0
        for SurfNum in state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs:
            sum_produc_area_drybulb += state.dataSurface.Surface[SurfNum - 1].Area * state.dataSurface.SurfOutDryBulbTemp[SurfNum]
        Tamb = sum_produc_area_drybulb / sum_area
    else:
        var sum_produc_area_wetbulb: Float64 = 0.0
        for SurfNum in state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs:
            sum_produc_area_wetbulb += state.dataSurface.Surface[SurfNum - 1].Area * state.dataSurface.SurfOutWetBulbTemp[SurfNum]
        Tamb = sum_produc_area_wetbulb / sum_area
    RhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, Tamb, state.dataEnvrn.OutHumRat)
    CpAir = PsyCpAirFnW(state.dataEnvrn.OutHumRat)
    holeArea = state.dataTranspiredCollector.UTSC[UTSCNum - 1].ActualArea * state.dataTranspiredCollector.UTSC[UTSCNum - 1].Porosity
    A = state.dataTranspiredCollector.UTSC[UTSCNum - 1].ProjArea
    Vholes = state.dataTranspiredCollector.UTSC[UTSCNum - 1].InletMDot / RhoAir / holeArea
    Vplen = state.dataTranspiredCollector.UTSC[UTSCNum - 1].InletMDot / RhoAir / state.dataTranspiredCollector.UTSC[UTSCNum - 1].PlenCrossArea
    Vsuction = state.dataTranspiredCollector.UTSC[UTSCNum - 1].InletMDot / RhoAir / A
    if (Vsuction < 0.001) or (Vsuction > 0.08):
        if state.dataTranspiredCollector.UTSC[UTSCNum - 1].VsucErrIndex == 0:
            ShowWarningMessage(state,
                               format("Solar Collector:Unglazed Transpired=\"{}\", Suction velocity is outside of range for a good design",
                                           state.dataTranspiredCollector.UTSC[UTSCNum - 1].Name))
            ShowContinueErrorTimeStamp(state, EnergyPlus::format("Suction velocity ={:.4R}", Vsuction))
            if Vsuction < 0.003:
                ShowContinueError(state, "Velocity is low -- suggest decreasing area of transpired collector")
            if Vsuction > 0.08:
                ShowContinueError(state, "Velocity is high -- suggest increasing area of transpired collector")
            ShowContinueError(state, "Occasional suction velocity messages are not unexpected when simulating actual conditions")
        ShowRecurringWarningErrorAtEnd(state,
                                       "Solar Collector:Unglazed Transpired=\"" + state.dataTranspiredCollector.UTSC[UTSCNum - 1].Name +
                                           "\", Suction velocity is outside of range",
                                       state.dataTranspiredCollector.UTSC[UTSCNum - 1].VsucErrIndex,
                                       Vsuction,
                                       Vsuction,
                                       _,
                                       "[m/s]",
                                       "[m/s]")
    HcPlen = 5.62 + 3.92 * Vplen
    D = state.dataTranspiredCollector.UTSC[UTSCNum - 1].HoleDia
    ReD = Vholes * D / nu
    P = state.dataTranspiredCollector.UTSC[UTSCNum - 1].Pitch
    Por = state.dataTranspiredCollector.UTSC[UTSCNum - 1].Porosity
    Mdot = state.dataTranspiredCollector.UTSC[UTSCNum - 1].InletMDot
    QdotSource = state.dataTranspiredCollector.UTSC[UTSCNum - 1].QdotSource
    NumSurfs = state.dataTranspiredCollector.UTSC[UTSCNum - 1].NumSurfs
    HSkyARR.dimension(NumSurfs, 0.0)
    HGroundARR.dimension(NumSurfs, 0.0)
    HAirARR.dimension(NumSurfs, 0.0)
    LocalWindArr.dimension(NumSurfs, 0.0)
    HPlenARR.dimension(NumSurfs, 0.0)
    HSrdSurfARR.dimension(NumSurfs, 0.0)
    Roughness = state.dataTranspiredCollector.UTSC[UTSCNum - 1].CollRoughness
    SolAbs = state.dataTranspiredCollector.UTSC[UTSCNum - 1].SolAbsorp
    AbsExt = state.dataTranspiredCollector.UTSC[UTSCNum - 1].LWEmitt
    TempExt = state.dataTranspiredCollector.UTSC[UTSCNum - 1].TcollLast
    for ThisSurf in range(1, NumSurfs + 1):
        var SurfPtr: Int = state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs[ThisSurf - 1]
        HMovInsul = 0.0
        HExt = 0.0
        LocalWindArr[ThisSurf - 1] = state.dataSurface.SurfOutWindSpeed[SurfPtr]
        Convect::InitExtConvCoeff(state,
                                  SurfPtr,
                                  HMovInsul,
                                  Roughness,
                                  AbsExt,
                                  TempExt,
                                  HExt,
                                  HSkyARR[ThisSurf - 1],
                                  HGroundARR[ThisSurf - 1],
                                  HAirARR[ThisSurf - 1],
                                  HSrdSurfARR[ThisSurf - 1])
        var ConstrNum: Int = state.dataSurface.Surface[SurfPtr - 1].Construction
        AbsThermSurf = s_mat.materials[state.dataConstruction.Construct[ConstrNum - 1].LayerPoint[0] - 1].AbsorpThermal
        TsoK = state.dataHeatBalSurf.SurfOutsideTempHist[0][SurfPtr] + Constant::Kelvin
        TscollK = state.dataTranspiredCollector.UTSC[UTSCNum - 1].TcollLast + Constant::Kelvin
        HPlenARR[ThisSurf - 1] = Sigma * AbsExt * AbsThermSurf * (pow_4(TscollK) - pow_4(TsoK)) / (TscollK - TsoK)
    var Area: List[Float64] =
        array_sub(state.dataSurface.Surface,
                  &SurfaceData.Area,
                  state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs)
    AreaSum = sum(Area)
    Vwind = sum(LocalWindArr * Area) / AreaSum
    LocalWindArr.deallocate()
    HrSky = sum(HSkyARR * Area) / AreaSum
    HSkyARR.deallocate()
    HrGround = sum(HGroundARR * Area) / AreaSum
    HGroundARR.deallocate()
    HrAtm = sum(HAirARR * Area) / AreaSum
    HAirARR.deallocate()
    HrPlen = sum(HPlenARR * Area) / AreaSum
    HPlenARR.deallocate()
    Isc = sum_product_sub(state.dataHeatBal.SurfQRadSWOutIncident,
                          state.dataSurface.Surface,
                          &SurfaceData.Area,
                          state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs) /
          AreaSum
    Tso = sum_product_sub(state.dataHeatBalSurf.SurfOutsideTempHist[0],
                          state.dataSurface.Surface,
                          &SurfaceData.Area,
                          state.dataTranspiredCollector.UTSC[UTSCNum - 1].SurfPtrs) /
          AreaSum
    if Vwind > 5.0:
        HcWind = 5.62 + 3.9 * (Vwind - 5.0)
    else:
        HcWind = 0.0
    if state.dataEnvrn.IsRain:
        HcWind = 1000.0
    HXeff = 0.0
    switch state.dataTranspiredCollector.UTSC[UTSCNum - 1].Correlation:
        case Correlation_Kutscher1994:
            AlessHoles = A - holeArea
            NuD = 2.75 * ((pow(P / D, -1.2) * pow(ReD, 0.43)) + (0.011 * Por * ReD * pow(Vwind / Vsuction, 0.48)))
            U = k * NuD / D
            HXeff = 1.0 - exp(-1.0 * ((U * AlessHoles) / (Mdot * CpAir)))
            break
        case Correlation_VanDeckerHollandsBrunger2001:
            t = state.dataTranspiredCollector.UTSC[UTSCNum - 1].CollectThick
            ReS = Vsuction * P / nu
            ReW = Vwind * P / nu
            ReB = Vholes * P / nu
            ReH = (Vsuction * D) / (nu * Por)
            if ReD > 0.0:
                if ReW > 0.0:
                    HXeff = (1.0 - pow(1.0 + ReS * max(1.733 * pow(ReW, -0.5), 0.02136), -1.0)) *
                            (1.0 - pow(1.0 + 0.2273 * sqrt(ReB), -1.0)) * exp(-0.01895 * (P / D) - (20.62 / ReH) * (t / D))
                else:
                    HXeff = (1.0 - pow(1.0 + ReS * 0.02136, -1.0)) * (1.0 - pow(1.0 + 0.2273 * sqrt(ReB), -1.0)) *
                            exp(-0.01895 * (P / D) - (20.62 / ReH) * (t / D))
            else:
                HXeff = 0.0
            break
        default:
            break
    Tscoll = (Isc * SolAbs + HrAtm * Tamb + HrSky * state.dataEnvrn.SkyTemp + HrGround * Tamb + HrPlen * Tso + HcWind * Tamb +
              (Mdot * CpAir / A) * Tamb - (Mdot * CpAir / A) * (1.0 - HXeff) * Tamb + QdotSource) /
             (HrAtm + HrSky + HrGround + HrPlen + HcWind + (Mdot * CpAir / A) * HXeff)
    TaHX = HXeff * Tscoll + (1.0 - HXeff) * Tamb
    Taplen = (Mdot * CpAir * TaHX + HcPlen * A * Tso) / (Mdot * CpAir + HcPlen * A)
    if Taplen > Tamb:
        SensHeatingRate = Mdot * CpAir * (Taplen - Tamb)
    else:
        SensHeatingRate = 0.0
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].Isc = Isc
    state.dataTranspiredCollector.UTSC[UTSCNum - 1].HXeff = H
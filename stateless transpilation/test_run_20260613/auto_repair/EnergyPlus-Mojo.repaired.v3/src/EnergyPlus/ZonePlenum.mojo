# Extra references from .hh
import "string"  # for String
import "utils/list"  # for List
from std.vector import DynamicVector

# Imports from other EnergyPlus modules (relative paths as per line convention)
from ......DataGlobals import EnergyPlusData, BaseGlobalStruct
from ......DataZoneEquipment import EquipConfiguration, AirLoopHVACZone
from ......DataHeatBalance import Zone
from ......DataLoopNode import NodeData
from ......DataContaminantBalance import ContaminantData
from ......DataEnvironment import EnvironmentData
from ......DataDefineEquipment import AirDistUnit
from ......Psychrometrics import PsyHFnTdbW, PsyTdbFnHW
from ......PoweredInductionUnits import PIUInducesPlenumAir
from ......PurchasedAirManager import CheckPurchasedAirForReturnPlenum
from ......NodeInputManager import GetOnlySingleNode, GetNodeNums, InitUniqueNodeCheck, EndUniqueNodeCheck, CheckUniqueNodeNumbers
from ......InputProcessor import InputProcessor, ErrorObjectHeader
from ......UtilityRoutines import FindItemInList, ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowSevereItemNotFound

# from "ObjexxFCL" (we handle arrays directly)
# Not needed

# Mojo does not have format; we use f-strings

# Define the structures (from ZonePlenum.hh)
struct ZoneReturnPlenumConditions:
    var ZonePlenumName: String
    var ZoneName: String
    var ZoneNodeName: String
    var ZoneTemp: Float64 = 0.0
    var ZoneHumRat: Float64 = 0.0
    var ZoneEnthalpy: Float64 = 0.0
    var OutletTemp: Float64 = 0.0
    var OutletHumRat: Float64 = 0.0
    var OutletEnthalpy: Float64 = 0.0
    var OutletPressure: Float64 = 0.0
    var ZoneNodeNum: Int = 0
    var ActualZoneNum: Int = 0
    var OutletNode: Int = 0
    var OutletMassFlowRate: Float64 = 0.0
    var OutletMassFlowRateMaxAvail: Float64 = 0.0
    var OutletMassFlowRateMinAvail: Float64 = 0.0
    var NumInducedNodes: Int = 0
    var InducedNode: List[Int] = List[Int]()
    var InducedMassFlowRate: List[Float64] = List[Float64]()
    var InducedMassFlowRateMaxAvail: List[Float64] = List[Float64]()
    var InducedMassFlowRateMinAvail: List[Float64] = List[Float64]()
    var InducedTemp: List[Float64] = List[Float64]()
    var InducedHumRat: List[Float64] = List[Float64]()
    var InducedEnthalpy: List[Float64] = List[Float64]()
    var InducedPressure: List[Float64] = List[Float64]()
    var InducedCO2: List[Float64] = List[Float64]()
    var InducedGenContam: List[Float64] = List[Float64]()
    var InitFlag: Bool = False
    var NumInletNodes: Int = 0
    var InletNode: List[Int] = List[Int]()
    var InletMassFlowRate: List[Float64] = List[Float64]()
    var InletMassFlowRateMaxAvail: List[Float64] = List[Float64]()
    var InletMassFlowRateMinAvail: List[Float64] = List[Float64]()
    var InletTemp: List[Float64] = List[Float64]()
    var InletHumRat: List[Float64] = List[Float64]()
    var InletEnthalpy: List[Float64] = List[Float64]()
    var InletPressure: List[Float64] = List[Float64]()
    var ADUIndex: List[Int] = List[Int]()  # index to AirDistUnit leaking to this plenum
    var NumADUs: Int = 0           # number of ADU's that can leak to this plenum
    var ZoneEqNum: List[Int] = List[Int]() # list of zone equip config indices for this plenum
    var checkEquipName: Bool = True

struct ZoneSupplyPlenumConditions:
    var ZonePlenumName: String
    var ZoneName: String
    var ZoneNodeName: String
    var ZoneTemp: Float64 = 0.0
    var ZoneHumRat: Float64 = 0.0
    var ZoneEnthalpy: Float64 = 0.0
    var InletTemp: Float64 = 0.0
    var InletHumRat: Float64 = 0.0
    var InletEnthalpy: Float64 = 0.0
    var InletPressure: Float64 = 0.0
    var ZoneNodeNum: Int = 0
    var ActualZoneNum: Int = 0
    var InletNode: Int = 0
    var InletMassFlowRate: Float64 = 0.0
    var InletMassFlowRateMaxAvail: Float64 = 0.0
    var InletMassFlowRateMinAvail: Float64 = 0.0
    var InitFlag: Bool = False
    var NumOutletNodes: Int = 0
    var OutletNode: List[Int] = List[Int]()
    var OutletMassFlowRate: List[Float64] = List[Float64]()
    var OutletMassFlowRateMaxAvail: List[Float64] = List[Float64]()
    var OutletMassFlowRateMinAvail: List[Float64] = List[Float64]()
    var OutletTemp: List[Float64] = List[Float64]()
    var OutletHumRat: List[Float64] = List[Float64]()
    var OutletEnthalpy: List[Float64] = List[Float64]()
    var OutletPressure: List[Float64] = List[Float64]()
    var checkEquipName: Bool = True

# Global data struct from header
@value
struct ZonePlenumData(BaseGlobalStruct):
    var GetInputFlag: Bool = True
    var NumZoneReturnPlenums: Int = 0
    var NumZoneSupplyPlenums: Int = 0
    var InitAirZoneReturnPlenumEnvrnFlag: Bool = True
    var InitAirZoneReturnPlenumOneTimeFlag: Bool = True
    var MyEnvrnFlag: Bool = True
    var ZoneRetPlenCond: List[ZoneReturnPlenumConditions] = List[ZoneReturnPlenumConditions]()
    var ZoneSupPlenCond: List[ZoneSupplyPlenumConditions] = List[ZoneSupplyPlenumConditions]()
    def init_constant_state(inout self, state: EnergyPlusData): pass
    def init_state(inout self, state: EnergyPlusData): pass
    def clear_state(inout self):
        self.__init__()

# Following functions from ZonePlenum.cc, converted to Mojo

def SimAirZonePlenum(inout state: EnergyPlusData,
                     CompName: String,
                     iCompType: AirLoopHVACZone,
                     inout CompIndex: Int,
                     FirstHVACIteration: Bool = False,
                     FirstCall: Bool = False,
                     inout PlenumInletChanged: Bool = False):
    if state.dataZonePlenum.GetInputFlag:
        GetZonePlenumInput(state)
        state.dataZonePlenum.GetInputFlag = False
    if iCompType == AirLoopHVACZone.ReturnPlenum:
        if CompIndex == 0:
            ZonePlenumNum = FindItemInList(CompName, state.dataZonePlenum.ZoneRetPlenCond, &ZoneReturnPlenumConditions.ZonePlenumName)
            if ZonePlenumNum == 0:
                ShowFatalError(state, f"SimAirZonePlenum: AirLoopHVAC:ReturnPlenum not found={CompName}")
            CompIndex = ZonePlenumNum
        else:
            ZonePlenumNum = CompIndex
            if ZonePlenumNum > state.dataZonePlenum.NumZoneReturnPlenums or ZonePlenumNum < 1:
                ShowFatalError(state, f"SimAirZonePlenum: Invalid CompIndex passed={ZonePlenumNum}, Number of AirLoopHVAC:ReturnPlenum={state.dataZonePlenum.NumZoneReturnPlenums}, AirLoopHVAC:ReturnPlenum name={CompName}")
            if state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].checkEquipName:
                if CompName != state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZonePlenumName:
                    ShowFatalError(state, f"SimAirZonePlenum: Invalid CompIndex passed={ZonePlenumNum}, AirLoopHVAC:ReturnPlenum name={CompName}, stored AirLoopHVAC:ReturnPlenum Name for that index={state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZonePlenumName}")
                state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].checkEquipName = False
        InitAirZoneReturnPlenum(state, ZonePlenumNum)
        CalcAirZoneReturnPlenum(state, ZonePlenumNum)
        UpdateAirZoneReturnPlenum(state, ZonePlenumNum)
    elif iCompType == AirLoopHVACZone.SupplyPlenum:
        if CompIndex == 0:
            ZonePlenumNum = FindItemInList(CompName, state.dataZonePlenum.ZoneSupPlenCond, &ZoneSupplyPlenumConditions.ZonePlenumName)
            if ZonePlenumNum == 0:
                ShowFatalError(state, f"SimAirZonePlenum: AirLoopHVAC:SupplyPlenum not found={CompName}")
            CompIndex = ZonePlenumNum
        else:
            ZonePlenumNum = CompIndex
            if ZonePlenumNum > state.dataZonePlenum.NumZoneSupplyPlenums or ZonePlenumNum < 1:
                ShowFatalError(state, f"SimAirZonePlenum: Invalid CompIndex passed={ZonePlenumNum}, Number of AirLoopHVAC:SupplyPlenum={state.dataZonePlenum.NumZoneReturnPlenums}, AirLoopHVAC:SupplyPlenum name={CompName}")
            if state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].checkEquipName:
                if CompName != state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZonePlenumName:
                    ShowFatalError(state, f"SimAirZonePlenum: Invalid CompIndex passed={ZonePlenumNum}, AirLoopHVAC:SupplyPlenum name={CompName}, stored AirLoopHVAC:SupplyPlenum Name for that index={state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZonePlenumName}")
                state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].checkEquipName = False
        InitAirZoneSupplyPlenum(state, ZonePlenumNum, FirstHVACIteration, FirstCall)
        CalcAirZoneSupplyPlenum(state, ZonePlenumNum, FirstCall)
        UpdateAirZoneSupplyPlenum(state, ZonePlenumNum, PlenumInletChanged, FirstCall)
    else:
        ShowSevereError(state, f"SimAirZonePlenum: Errors in Plenum={CompName}")
        ShowContinueError(state, f"ZonePlenum: Unhandled plenum type found:{iCompType}")
        ShowFatalError(state, "Preceding conditions cause termination.")

def GetZonePlenumInput(inout state: EnergyPlusData):
    # local aliases
    ZoneEquipConfigLoop: Int
    NumAlphas: Int
    NumNums: Int
    NumArgs: Int
    NumNodes: Int
    NodeNums: List[Int] = List[Int]()
    MaxNums: Int
    MaxAlphas: Int
    NodeNum: Int
    IOStat: Int
    NumArray: List[Float64] = List[Float64]()
    CurrentModuleObject: String
    AlphArray: List[String] = List[String]()
    cAlphaFields: List[String] = List[String]()
    cNumericFields: List[String] = List[String]()
    lAlphaBlanks: List[Bool] = List[Bool]()
    lNumericBlanks: List[Bool] = List[Bool]()
    var ErrorsFound: Bool = False
    var NodeListError: Bool
    var UniqueNodeError: Bool
    static var RoutineName: String = "GetZonePlenumInput: "
    static var routineName: String = "GetZonePlenumInput"
    InducedNodeListName: String

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "AirLoopHVAC:ReturnPlenum", NumArgs, NumAlphas, NumNums)
    MaxNums = NumNums
    MaxAlphas = NumAlphas
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "AirLoopHVAC:SupplyPlenum", NumArgs, NumAlphas, NumNums)
    MaxNums = max(NumNums, MaxNums)
    MaxAlphas = max(NumAlphas, MaxAlphas)

    AlphArray = List[String](MaxAlphas, " ")
    cAlphaFields = List[String](MaxAlphas, " ")
    cNumericFields = List[String](MaxNums, " ")
    NumArray = List[Float64](MaxNums, 0.0)
    lAlphaBlanks = List[Bool](MaxAlphas, True)
    lNumericBlanks = List[Bool](MaxNums, True)

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "NodeList", NumArgs, NumAlphas, NumNums)
    NodeNums = List[Int](NumArgs, 0)

    InducedNodeListName = ""

    state.dataZonePlenum.NumZoneReturnPlenums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "AirLoopHVAC:ReturnPlenum")
    state.dataZonePlenum.NumZoneSupplyPlenums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "AirLoopHVAC:SupplyPlenum")

    if state.dataZonePlenum.NumZoneReturnPlenums > 0:
        state.dataZonePlenum.ZoneRetPlenCond = List[ZoneReturnPlenumConditions](state.dataZonePlenum.NumZoneReturnPlenums)
    if state.dataZonePlenum.NumZoneSupplyPlenums > 0:
        state.dataZonePlenum.ZoneSupPlenCond = List[ZoneSupplyPlenumConditions](state.dataZonePlenum.NumZoneSupplyPlenums)

    InitUniqueNodeCheck(state, "AirLoopHVAC:ReturnPlenum")
    CurrentModuleObject = "AirLoopHVAC:ReturnPlenum"
    for ZonePlenumNum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, ZonePlenumNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var retPlenum = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1]
        retPlenum.ZonePlenumName = AlphArray[0]  # C++ AlphArray(1) -> index 0
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[0])
        IOStat = FindItemInList(AlphArray[1], state.dataZonePlenum.ZoneRetPlenCond, &ZoneReturnPlenumConditions.ZoneName, ZonePlenumNum - 1)
        if IOStat != 0:
            ShowSevereError(state, f"{RoutineName}{cAlphaFields[1]} \"{AlphArray[1]}\" is used more than once as a {CurrentModuleObject}.")
            ShowContinueError(state, f"..Only one {CurrentModuleObject} object may be connected to a given zone.")
            ShowContinueError(state, f"..occurs in {CurrentModuleObject} = {AlphArray[0]}")
            ErrorsFound = True
        retPlenum.ZoneName = AlphArray[1]
        retPlenum.ActualZoneNum = FindItemInList(AlphArray[1], state.dataHeatBal.Zone)
        if retPlenum.ActualZoneNum == 0:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[1], AlphArray[1])
            ErrorsFound = True
            continue
        state.dataHeatBal.Zone[retPlenum.ActualZoneNum - 1].IsReturnPlenum = True
        state.dataHeatBal.Zone[retPlenum.ActualZoneNum - 1].PlenumCondNum = ZonePlenumNum
        ZoneEquipConfigLoop = FindItemInList(AlphArray[1], state.dataZoneEquip.ZoneEquipConfig, &EquipConfiguration.ZoneName)
        if ZoneEquipConfigLoop != 0:
            ShowSevereError(state, f"{RoutineName}{cAlphaFields[1]} \"{AlphArray[1]}\" is a controlled zone. It cannot be used as a {CurrentModuleObject}")
            ShowContinueError(state, f"..occurs in {CurrentModuleObject} = {AlphArray[0]}")
            ErrorsFound = True
        retPlenum.ZoneNodeName = AlphArray[2]
        retPlenum.ZoneNodeNum = GetOnlySingleNode(state, AlphArray[2], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACReturnPlenum, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.ZoneNode, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatBal.Zone[retPlenum.ActualZoneNum - 1].SystemZoneNodeNumber = retPlenum.ZoneNodeNum
        for spaceNum in state.dataHeatBal.Zone[retPlenum.ActualZoneNum - 1].spaceIndexes:
            state.dataHeatBal.space[spaceNum - 1].SystemZoneNodeNumber = retPlenum.ZoneNodeNum
        retPlenum.OutletNode = GetOnlySingleNode(state, AlphArray[3], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACReturnPlenum, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        InducedNodeListName = AlphArray[4]
        NodeListError = False
        GetNodeNums(state, InducedNodeListName, NumNodes, NodeNums, NodeListError, Node.FluidType.Air, Node.ConnectionObjectType.AirLoopHVACReturnPlenum, retPlenum.ZonePlenumName, Node.ConnectionType.InducedAir, Node.CompFluidStream.Primary, Node.ObjectIsNotParent, False, cAlphaFields[4])
        if not NodeListError:
            retPlenum.NumInducedNodes = NumNodes
            retPlenum.InducedNode = List[Int](retPlenum.NumInducedNodes, 0)
            retPlenum.InducedMassFlowRate = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedMassFlowRateMaxAvail = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedMassFlowRateMinAvail = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedTemp = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedHumRat = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedEnthalpy = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedPressure = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedCO2 = List[Float64](retPlenum.NumInducedNodes, 0.0)
            retPlenum.InducedGenContam = List[Float64](retPlenum.NumInducedNodes, 0.0)
            for NodeNum in range(1, NumNodes + 1):
                retPlenum.InducedNode[NodeNum - 1] = NodeNums[NodeNum - 1]
                UniqueNodeError = False
                if not CheckPurchasedAirForReturnPlenum(state, ZonePlenumNum):
                    CheckUniqueNodeNumbers(state, "Return Plenum Induced Air Nodes", UniqueNodeError, NodeNums[NodeNum - 1], CurrentModuleObject)
                    if UniqueNodeError:
                        ShowContinueError(state, f"Occurs for ReturnPlenum = {AlphArray[0]}")
                        ErrorsFound = True
                    PIUInducesPlenumAir(state, retPlenum.InducedNode[NodeNum - 1], ZonePlenumNum)
        else:
            ShowContinueError(state, f"Invalid Induced Air Outlet Node or NodeList name in AirLoopHVAC:ReturnPlenum object = {retPlenum.ZonePlenumName}")
            ErrorsFound = True

        retPlenum.NumInletNodes = NumAlphas - 5
        for e in state.dataZonePlenum.ZoneRetPlenCond:
            e.InitFlag = True
        retPlenum.InletNode = List[Int](retPlenum.NumInletNodes, 0)
        retPlenum.InletMassFlowRate = List[Float64](retPlenum.NumInletNodes, 0.0)
        retPlenum.InletMassFlowRateMaxAvail = List[Float64](retPlenum.NumInletNodes, 0.0)
        retPlenum.InletMassFlowRateMinAvail = List[Float64](retPlenum.NumInletNodes, 0.0)
        retPlenum.InletTemp = List[Float64](retPlenum.NumInletNodes, 0.0)
        retPlenum.InletHumRat = List[Float64](retPlenum.NumInletNodes, 0.0)
        retPlenum.InletEnthalpy = List[Float64](retPlenum.NumInletNodes, 0.0)
        retPlenum.InletPressure = List[Float64](retPlenum.NumInletNodes, 0.0)
        retPlenum.ZoneEqNum = List[Int](retPlenum.NumInletNodes, 0)
        for NodeNum in range(1, retPlenum.NumInletNodes + 1):
            retPlenum.InletNode[NodeNum - 1] = GetOnlySingleNode(state, AlphArray[4 + NodeNum], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACReturnPlenum, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        # Initialize remaining fields to 0.0 (already set above)
        retPlenum.OutletMassFlowRate = 0.0
        retPlenum.OutletMassFlowRateMaxAvail = 0.0
        retPlenum.OutletMassFlowRateMinAvail = 0.0
        retPlenum.OutletTemp = 0.0
        retPlenum.OutletHumRat = 0.0
        retPlenum.OutletEnthalpy = 0.0
        retPlenum.OutletPressure = 0.0
        retPlenum.ZoneTemp = 0.0
        retPlenum.ZoneHumRat = 0.0
        retPlenum.ZoneEnthalpy = 0.0
    # end AirLoopHVAC:ReturnPlenum Loop
    EndUniqueNodeCheck(state, "AirLoopHVAC:ReturnPlenum")

    CurrentModuleObject = "AirLoopHVAC:SupplyPlenum"
    for ZonePlenumNum in range(1, state.dataZonePlenum.NumZoneSupplyPlenums + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, ZonePlenumNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[0])
        var supPlenum = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum - 1]
        supPlenum.ZonePlenumName = AlphArray[0]
        IOStat = FindItemInList(AlphArray[1], state.dataZonePlenum.ZoneSupPlenCond, &ZoneSupplyPlenumConditions.ZoneName, ZonePlenumNum - 1)
        if IOStat != 0:
            ShowSevereError(state, f"{RoutineName}{cAlphaFields[1]} \"{AlphArray[1]}\" is used more than once as a {CurrentModuleObject}.")
            ShowContinueError(state, f"..Only one {CurrentModuleObject} object may be connected to a given zone.")
            ShowContinueError(state, f"..occurs in {CurrentModuleObject} = {AlphArray[0]}")
            ErrorsFound = True
        if state.dataZonePlenum.NumZoneReturnPlenums > 0:
            IOStat = FindItemInList(AlphArray[1], state.dataZonePlenum.ZoneRetPlenCond, &ZoneReturnPlenumConditions.ZoneName)
            if IOStat != 0:
                ShowSevereError(state, f"{RoutineName}{cAlphaFields[1]} \"{AlphArray[1]}\" is used more than once as a {CurrentModuleObject} or AirLoopHVAC:ReturnPlenum.")
                ShowContinueError(state, f"..Only one {CurrentModuleObject} or AirLoopHVAC:ReturnPlenum object may be connected to a given zone.")
                ShowContinueError(state, f"..occurs in {CurrentModuleObject} = {AlphArray[0]}")
                ErrorsFound = True
        supPlenum.ZoneName = AlphArray[1]
        supPlenum.ActualZoneNum = FindItemInList(AlphArray[1], state.dataHeatBal.Zone)
        if supPlenum.ActualZoneNum == 0:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[1], AlphArray[1])
            ErrorsFound = True
            continue
        state.dataHeatBal.Zone[supPlenum.ActualZoneNum - 1].IsSupplyPlenum = True
        state.dataHeatBal.Zone[supPlenum.ActualZoneNum - 1].PlenumCondNum = ZonePlenumNum
        if any(state.dataZoneEquip.ZoneEquipConfig, lambda e: e.IsControlled):
            ZoneEquipConfigLoop = FindItemInList(AlphArray[1], state.dataZoneEquip.ZoneEquipConfig, &EquipConfiguration.ZoneName)
            if ZoneEquipConfigLoop != 0:
                ShowSevereError(state, f"{RoutineName}{cAlphaFields[1]} \"{AlphArray[1]}\" is a controlled zone. It cannot be used as a {CurrentModuleObject} or AirLoopHVAC:ReturnPlenum.")
                ShowContinueError(state, f"..occurs in {CurrentModuleObject} = {AlphArray[0]}")
                ErrorsFound = True
        supPlenum.ZoneNodeName = AlphArray[2]
        supPlenum.ZoneNodeNum = GetOnlySingleNode(state, AlphArray[2], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACSupplyPlenum, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.ZoneNode, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataHeatBal.Zone[supPlenum.ActualZoneNum - 1].SystemZoneNodeNumber = supPlenum.ZoneNodeNum
        for spaceNum in state.dataHeatBal.Zone[supPlenum.ActualZoneNum - 1].spaceIndexes:
            state.dataHeatBal.space[spaceNum - 1].SystemZoneNodeNumber = supPlenum.ZoneNodeNum
        supPlenum.InletNode = GetOnlySingleNode(state, AlphArray[3], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACSupplyPlenum, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        supPlenum.NumOutletNodes = NumAlphas - 4
        for e in state.dataZonePlenum.ZoneSupPlenCond:
            e.InitFlag = True
        supPlenum.OutletNode = List[Int](supPlenum.NumOutletNodes, 0)
        supPlenum.OutletMassFlowRate = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletMassFlowRateMaxAvail = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletMassFlowRateMinAvail = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletTemp = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletHumRat = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletEnthalpy = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletPressure = List[Float64](supPlenum.NumOutletNodes, 0.0)
        for NodeNum in range(1, supPlenum.NumOutletNodes + 1):
            supPlenum.OutletNode[NodeNum - 1] = GetOnlySingleNode(state, AlphArray[3 + NodeNum], ErrorsFound, Node.ConnectionObjectType.AirLoopHVACSupplyPlenum, AlphArray[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        # Initialize remaining fields
        supPlenum.OutletNode = List[Int](supPlenum.NumOutletNodes, 0)  # already done
        supPlenum.OutletMassFlowRate = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletMassFlowRateMaxAvail = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletMassFlowRateMinAvail = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletTemp = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletHumRat = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletEnthalpy = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.OutletPressure = List[Float64](supPlenum.NumOutletNodes, 0.0)
        supPlenum.InletMassFlowRate = 0.0
        supPlenum.InletMassFlowRateMaxAvail = 0.0
        supPlenum.InletMassFlowRateMinAvail = 0.0
        supPlenum.InletTemp = 0.0
        supPlenum.InletHumRat = 0.0
        supPlenum.InletEnthalpy = 0.0
        supPlenum.InletPressure = 0.0
        supPlenum.ZoneTemp = 0.0
        supPlenum.ZoneHumRat = 0.0
        supPlenum.ZoneEnthalpy = 0.0
    # end AirLoopHVAC:SupplyPlenum Loop

    # Deallocate (not needed in Mojo; lists go out of scope)
    if ErrorsFound:
        ShowFatalError(state, f"{RoutineName}Errors found in input.  Preceding condition(s) cause termination.")

def InitAirZoneReturnPlenum(inout state: EnergyPlusData, ZonePlenumNum: Int):
    var InletNode: Int
    var ZoneNodeNum: Int
    var NodeNum: Int
    if state.dataZonePlenum.InitAirZoneReturnPlenumOneTimeFlag:
        for ZonePlenumLoop in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
            var NumADUsToPlen: Int = 0
            if state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].NumInletNodes > 0:
                for InletNodeLoop in range(1, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].NumInletNodes + 1):
                    InletNode = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].InletNode[InletNodeLoop-1]
                    for ZoneEquipConfigLoop in range(1, state.dataGlobal.NumOfZones + 1):
                        if not state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigLoop-1].IsControlled:
                            continue
                        for retNode in range(1, state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigLoop-1].NumReturnNodes + 1):
                            if state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigLoop-1].ReturnNode[retNode-1] == InletNode:
                                state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigLoop-1].ReturnNodePlenumNum = ZonePlenumLoop
                                state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].ZoneEqNum[InletNodeLoop-1] = ZoneEquipConfigLoop
                    for ADUNum in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
                        if state.dataDefineEquipment.AirDistUnit[ADUNum-1].ZoneEqNum == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].ZoneEqNum[InletNodeLoop-1]:
                            state.dataDefineEquipment.AirDistUnit[ADUNum-1].RetPlenumNum = ZonePlenumLoop
                            NumADUsToPlen += 1
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].ADUIndex = List[Int](NumADUsToPlen, 0)
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].NumADUs = NumADUsToPlen
            if NumADUsToPlen > 0:
                var ADUsToPlenIndex: Int = 0
                for ADUNum in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
                    if state.dataDefineEquipment.AirDistUnit[ADUNum-1].RetPlenumNum == ZonePlenumLoop:
                        ADUsToPlenIndex += 1
                        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumLoop-1].ADUIndex[ADUsToPlenIndex-1] = ADUNum
        for ADUNum in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
            var thisADU = state.dataDefineEquipment.AirDistUnit[ADUNum-1]
            if thisADU.DownStreamLeak and (thisADU.RetPlenumNum == 0):
                ShowWarningError(state, f"No return plenum found for simple duct leakage for ZoneHVAC:AirDistributionUnit={thisADU.Name} in Zone={state.dataZoneEquip.ZoneEquipConfig[thisADU.ZoneEqNum-1].ZoneName}")
                ShowContinueError(state, "Leakage will be ignored for this ADU.")
                thisADU.UpStreamLeak = False
                thisADU.DownStreamLeak = False
                thisADU.UpStreamLeakFrac = 0.0
                thisADU.DownStreamLeakFrac = 0.0
        state.dataZonePlenum.InitAirZoneReturnPlenumOneTimeFlag = False

    if state.dataZonePlenum.InitAirZoneReturnPlenumEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        for PlenumZoneNum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
            ZoneNodeNum = state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].ZoneNodeNum
            state.dataLoopNodes.Node[ZoneNodeNum-1].Temp = 20.0
            state.dataLoopNodes.Node[ZoneNodeNum-1].MassFlowRate = 0.0
            state.dataLoopNodes.Node[ZoneNodeNum-1].Quality = 1.0
            state.dataLoopNodes.Node[ZoneNodeNum-1].Press = state.dataEnvrn.OutBaroPress
            state.dataLoopNodes.Node[ZoneNodeNum-1].HumRat = state.dataEnvrn.OutHumRat
            state.dataLoopNodes.Node[ZoneNodeNum-1].Enthalpy = PsyHFnTdbW(state.dataLoopNodes.Node[ZoneNodeNum-1].Temp, state.dataLoopNodes.Node[ZoneNodeNum-1].HumRat)
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].ZoneTemp = 20.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].ZoneHumRat = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].ZoneEnthalpy = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].InletTemp = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].InletHumRat = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].InletEnthalpy = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].InletPressure = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].InletMassFlowRate = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].InletMassFlowRateMaxAvail = 0.0
            state.dataZonePlenum.ZoneRetPlenCond[PlenumZoneNum-1].InletMassFlowRateMinAvail = 0.0
        state.dataZonePlenum.InitAirZoneReturnPlenumEnvrnFlag = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataZonePlenum.InitAirZoneReturnPlenumEnvrnFlag = True

    for NodeNum in range(1, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].NumInletNodes + 1):
        InletNode = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletNode[NodeNum-1]
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletMassFlowRate[NodeNum-1] = state.dataLoopNodes.Node[InletNode-1].MassFlowRate
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletMassFlowRateMaxAvail[NodeNum-1] = state.dataLoopNodes.Node[InletNode-1].MassFlowRateMaxAvail
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletMassFlowRateMinAvail[NodeNum-1] = state.dataLoopNodes.Node[InletNode-1].MassFlowRateMinAvail
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletPressure[NodeNum-1] = state.dataLoopNodes.Node[InletNode-1].Press

    ZoneNodeNum = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZoneNodeNum
    for NodeNum in range(1, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].NumInducedNodes + 1):
        var InducedNode: Int = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedNode[NodeNum-1]
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedMassFlowRate[NodeNum-1] = state.dataLoopNodes.Node[InducedNode-1].MassFlowRate
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedMassFlowRateMaxAvail[NodeNum-1] = state.dataLoopNodes.Node[InducedNode-1].MassFlowRateMaxAvail
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedMassFlowRateMinAvail[NodeNum-1] = state.dataLoopNodes.Node[InducedNode-1].MassFlowRateMinAvail
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedTemp[NodeNum-1] = state.dataLoopNodes.Node[ZoneNodeNum-1].Temp
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedHumRat[NodeNum-1] = state.dataLoopNodes.Node[ZoneNodeNum-1].HumRat
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedEnthalpy[NodeNum-1] = state.dataLoopNodes.Node[ZoneNodeNum-1].Enthalpy
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedPressure[NodeNum-1] = state.dataLoopNodes.Node[ZoneNodeNum-1].Press
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedCO2[NodeNum-1] = state.dataLoopNodes.Node[ZoneNodeNum-1].CO2
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedGenContam[NodeNum-1] = state.dataLoopNodes.Node[ZoneNodeNum-1].GenContam

    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZoneTemp = state.dataLoopNodes.Node[ZoneNodeNum-1].Temp
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZoneHumRat = state.dataLoopNodes.Node[ZoneNodeNum-1].HumRat
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZoneEnthalpy = state.dataLoopNodes.Node[ZoneNodeNum-1].Enthalpy

def InitAirZoneSupplyPlenum(inout state: EnergyPlusData, ZonePlenumNum: Int, FirstHVACIteration: Bool, FirstCall: Bool):
    var InletNode: Int
    var OutletNode: Int
    var ZoneNodeNum: Int
    var NodeIndex: Int
    if state.dataZonePlenum.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        for PlenumZoneNum in range(1, state.dataZonePlenum.NumZoneSupplyPlenums + 1):
            ZoneNodeNum = state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].ZoneNodeNum
            var node = state.dataLoopNodes.Node[ZoneNodeNum-1]
            node.Temp = 20.0
            node.MassFlowRate = 0.0
            node.Quality = 1.0
            node.Press = state.dataEnvrn.OutBaroPress
            node.HumRat = state.dataEnvrn.OutHumRat
            node.Enthalpy = PsyHFnTdbW(node.Temp, node.HumRat)
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].ZoneTemp = 20.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].ZoneHumRat = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].ZoneEnthalpy = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].InletTemp = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].InletHumRat = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].InletEnthalpy = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].InletPressure = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].InletMassFlowRate = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].InletMassFlowRateMaxAvail = 0.0
            state.dataZonePlenum.ZoneSupPlenCond[PlenumZoneNum-1].InletMassFlowRateMinAvail = 0.0
        state.dataZonePlenum.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataZonePlenum.MyEnvrnFlag = True

    InletNode = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].InletNode
    var inletNode = state.dataLoopNodes.Node[InletNode-1]
    ZoneNodeNum = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZoneNodeNum
    var zoneNode = state.dataLoopNodes.Node[ZoneNodeNum-1]
    if FirstHVACIteration and FirstCall:
        if inletNode.MassFlowRate > 0.0:
            zoneNode.MassFlowRate = inletNode.MassFlowRate
            for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
                OutletNode = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletNode[NodeIndex-1]
                state.dataLoopNodes.Node[OutletNode-1].MassFlowRate = inletNode.MassFlowRate / Float64(state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes)
        if inletNode.MassFlowRateMaxAvail > 0.0:
            zoneNode.MassFlowRateMaxAvail = inletNode.MassFlowRateMaxAvail
            for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
                OutletNode = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletNode[NodeIndex-1]
                state.dataLoopNodes.Node[OutletNode-1].MassFlowRateMaxAvail = inletNode.MassFlowRateMaxAvail / Float64(state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes)
    # For FirstHVACIteration and FirstCall
    if FirstCall:
        if inletNode.MassFlowRateMaxAvail == 0.0:
            for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
                OutletNode = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletNode[NodeIndex-1]
                var outletNode = state.dataLoopNodes.Node[OutletNode-1]
                outletNode.MassFlowRate = 0.0
                outletNode.MassFlowRateMaxAvail = 0.0
                outletNode.MassFlowRateMinAvail = 0.0
            zoneNode.MassFlowRate = 0.0
            zoneNode.MassFlowRateMaxAvail = 0.0
            zoneNode.MassFlowRateMinAvail = 0.0
        # For Node inlet Max Avail = 0.0
        state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZoneTemp = zoneNode.Temp
        state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZoneHumRat = zoneNode.HumRat
        state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZoneEnthalpy = zoneNode.Enthalpy
        for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
            OutletNode = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletNode[NodeIndex-1]
            var outletNode = state.dataLoopNodes.Node[OutletNode-1]
            outletNode.Press = inletNode.Press
            outletNode.Quality = inletNode.Quality
        zoneNode.Press = inletNode.Press
        zoneNode.Quality = inletNode.Quality
    else:
        for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
            OutletNode = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletNode[NodeIndex-1]
            var outletNode = state.dataLoopNodes.Node[OutletNode-1]
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletMassFlowRate[NodeIndex-1] = outletNode.MassFlowRate
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletMassFlowRateMaxAvail[NodeIndex-1] = outletNode.MassFlowRateMaxAvail
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletMassFlowRateMinAvail[NodeIndex-1] = outletNode.MassFlowRateMinAvail
    # For FirstCall

def CalcAirZoneReturnPlenum(inout state: EnergyPlusData, ZonePlenumNum: Int):
    var InletNodeNum: Int = 0
    var IndNum: Int = 0
    var ADUListIndex: Int = 0
    var TotIndMassFlowRate: Float64 = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRate = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMaxAvail = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMinAvail = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletTemp = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletHumRat = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletPressure = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletEnthalpy = 0.0
    TotIndMassFlowRate = 0.0
    for InletNodeNum in range(1, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].NumInletNodes + 1):
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRate += state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletMassFlowRate[InletNodeNum-1]
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMaxAvail += state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletMassFlowRateMaxAvail[InletNodeNum-1]
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMinAvail += state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletMassFlowRateMinAvail[InletNodeNum-1]
    if state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRate > 0.0:
        for InletNodeNum in range(1, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].NumInletNodes + 1):
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletPressure += state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletPressure[InletNodeNum-1] * state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletMassFlowRate[InletNodeNum-1] / state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRate
    else:
        state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletPressure = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InletPressure[0]  # InletPressure(1) -> index 0
    for ADUListIndex in range(1, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].NumADUs + 1):
        var ADUNum: Int = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ADUIndex[ADUListIndex-1]
        if state.dataDefineEquipment.AirDistUnit[ADUNum-1].UpStreamLeak or state.dataDefineEquipment.AirDistUnit[ADUNum-1].DownStreamLeak or state.dataDefineEquipment.AirDistUnit[ADUNum-1].massFlowRateParallelPIULk > 0:
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRate += state.dataDefineEquipment.AirDistUnit[ADUNum-1].MassFlowRateUpStrLk + state.dataDefineEquipment.AirDistUnit[ADUNum-1].MassFlowRateDnStrLk + state.dataDefineEquipment.AirDistUnit[ADUNum-1].massFlowRateParallelPIULk
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMaxAvail += state.dataDefineEquipment.AirDistUnit[ADUNum-1].MaxAvailDelta
            state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMinAvail += state.dataDefineEquipment.AirDistUnit[ADUNum-1].MinAvailDelta
    for IndNum in range(1, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].NumInducedNodes + 1):
        TotIndMassFlowRate += state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].InducedMassFlowRate[IndNum-1]
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRate -= TotIndMassFlowRate
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletHumRat = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZoneHumRat
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletEnthalpy = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZoneEnthalpy
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletTemp = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].ZoneTemp
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMaxAvail = max(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRateMaxAvail, state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1].OutletMassFlowRate)

def CalcAirZoneSupplyPlenum(inout state: EnergyPlusData, ZonePlenumNum: Int, FirstCall: Bool):
    var NodeIndex: Int
    if FirstCall:
        for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletHumRat[NodeIndex-1] = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZoneHumRat
        for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletEnthalpy[NodeIndex-1] = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZoneEnthalpy
        for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletTemp[NodeIndex-1] = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].ZoneTemp
    else:
        state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].InletMassFlowRate = 0.0
        state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].InletMassFlowRateMaxAvail = 0.0
        state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].InletMassFlowRateMinAvail = 0.0
        for NodeIndex in range(1, state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].NumOutletNodes + 1):
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].InletMassFlowRate += state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletMassFlowRate[NodeIndex-1]
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].InletMassFlowRateMaxAvail += state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletMassFlowRateMaxAvail[NodeIndex-1]
            state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].InletMassFlowRateMinAvail += state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1].OutletMassFlowRateMinAvail[NodeIndex-1]

def UpdateAirZoneReturnPlenum(inout state: EnergyPlusData, ZonePlenumNum: Int):
    var zoneRetPlenCond = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum-1]
    var outletNode = state.dataLoopNodes.Node[zoneRetPlenCond.OutletNode-1]
    var inletNode = state.dataLoopNodes.Node[zoneRetPlenCond.InletNode[0]-1]  # InletNode(1) -> index 0
    var zoneNode = state.dataLoopNodes.Node[zoneRetPlenCond.ZoneNodeNum-1]
    outletNode.MassFlowRate = zoneRetPlenCond.OutletMassFlowRate
    outletNode.MassFlowRateMaxAvail = zoneRetPlenCond.OutletMassFlowRateMaxAvail
    outletNode.MassFlowRateMinAvail = zoneRetPlenCond.OutletMassFlowRateMinAvail
    zoneNode.MassFlowRate = zoneRetPlenCond.OutletMassFlowRate
    zoneNode.MassFlowRateMaxAvail = zoneRetPlenCond.OutletMassFlowRateMaxAvail
    zoneNode.MassFlowRateMinAvail = zoneRetPlenCond.OutletMassFlowRateMinAvail
    zoneNode.Press = zoneRetPlenCond.OutletPressure
    outletNode.Temp = zoneRetPlenCond.OutletTemp
    outletNode.HumRat = zoneRetPlenCond.OutletHumRat
    outletNode.Enthalpy = zoneRetPlenCond.OutletEnthalpy
    outletNode.Press = zoneRetPlenCond.OutletPressure
    for IndNum in range(1, zoneRetPlenCond.NumInducedNodes + 1):
        var InducedNode: Int = zoneRetPlenCond.InducedNode[IndNum-1]
        var inducedNode = state.dataLoopNodes.Node[InducedNode-1]
        inducedNode.Temp = zoneRetPlenCond.InducedTemp[IndNum-1]
        inducedNode.HumRat = zoneRetPlenCond.InducedHumRat[IndNum-1]
        inducedNode.Enthalpy = zoneRetPlenCond.InducedEnthalpy[IndNum-1]
        inducedNode.Press = zoneRetPlenCond.InducedPressure[IndNum-1]
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            inducedNode.CO2 = zoneRetPlenCond.InducedCO2[IndNum-1]
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            inducedNode.GenContam = zoneRetPlenCond.InducedGenContam[IndNum-1]
        inducedNode.Quality = inletNode.Quality
    outletNode.Quality = inletNode.Quality
    zoneNode.Quality = inletNode.Quality
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        if zoneRetPlenCond.OutletMassFlowRate > 0.0:
            outletNode.CO2 = 0.0
            for InletNodeNum in range(1, zoneRetPlenCond.NumInletNodes + 1):
                outletNode.CO2 += state.dataLoopNodes.Node[zoneRetPlenCond.InletNode[InletNodeNum-1]-1].CO2 * zoneRetPlenCond.InletMassFlowRate[InletNodeNum-1] / zoneRetPlenCond.OutletMassFlowRate
            zoneNode.CO2 = outletNode.CO2
        else:
            outletNode.CO2 = zoneNode.CO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        if zoneRetPlenCond.OutletMassFlowRate > 0.0:
            outletNode.GenContam = 0.0
            for InletNodeNum in range(1, zoneRetPlenCond.NumInletNodes + 1):
                outletNode.GenContam += state.dataLoopNodes.Node[zoneRetPlenCond.InletNode[InletNodeNum-1]-1].GenContam * zoneRetPlenCond.InletMassFlowRate[InletNodeNum-1] / zoneRetPlenCond.OutletMassFlowRate
            zoneNode.GenContam = outletNode.GenContam
        else:
            outletNode.GenContam = zoneNode.GenContam

def UpdateAirZoneSupplyPlenum(inout state: EnergyPlusData, ZonePlenumNum: Int, inout PlenumInletChanged: Bool, FirstCall: Bool):
    var FlowRateToler: Float64 = 0.01  # Tolerance for mass flow rate convergence (in kg/s)
    var zoneSupPlenCon = state.dataZonePlenum.ZoneSupPlenCond[ZonePlenumNum-1]
    var inletNode = state.dataLoopNodes.Node[zoneSupPlenCon.InletNode-1]
    var zoneNode = state.dataLoopNodes.Node[zoneSupPlenCon.ZoneNodeNum-1]
    if FirstCall:
        for NodeIndex in range(1, zoneSupPlenCon.NumOutletNodes + 1):
            var OutletNode: Int = zoneSupPlenCon.OutletNode[NodeIndex-1]
            var outletNode = state.dataLoopNodes.Node[OutletNode-1]
            outletNode.Temp = zoneSupPlenCon.OutletTemp[NodeIndex-1]
            outletNode.HumRat = zoneSupPlenCon.OutletHumRat[NodeIndex-1]
            outletNode.Enthalpy = zoneSupPlenCon.OutletEnthalpy[NodeIndex-1]
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                outletNode.CO2 = inletNode.CO2
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                outletNode.GenContam = inletNode.GenContam
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            zoneNode.CO2 = inletNode.CO2
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            zoneNode.GenContam = inletNode.GenContam
    else:
        if abs(inletNode.MassFlowRate - zoneSupPlenCon.InletMassFlowRate) > FlowRateToler:
            PlenumInletChanged = True
        inletNode.MassFlowRate = zoneSupPlenCon.InletMassFlowRate
        inletNode.MassFlowRateMaxAvail = zoneSupPlenCon.InletMassFlowRateMaxAvail
        inletNode.MassFlowRateMinAvail = zoneSupPlenCon.InletMassFlowRateMinAvail
        zoneNode.MassFlowRate = zoneSupPlenCon.InletMassFlowRate
        zoneNode.MassFlowRateMaxAvail = zoneSupPlenCon.InletMassFlowRateMaxAvail
        zoneNode.MassFlowRateMinAvail = zoneSupPlenCon.InletMassFlowRateMinAvail
    # For FirstCall

def GetReturnPlenumIndex(inout state: EnergyPlusData, ExNodeNum: Int) -> Int:
    var WhichPlenum: Int
    if state.dataZonePlenum.GetInputFlag:
        GetZonePlenumInput(state)
        state.dataZonePlenum.GetInputFlag = False
    WhichPlenum = 0
    if state.dataZonePlenum.NumZoneReturnPlenums > 0:
        for PlenumNum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
            if ExNodeNum != state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].OutletNode:
                continue
            WhichPlenum = PlenumNum
            break
        if WhichPlenum == 0:
            for PlenumNum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
                for InducedNodeNum in range(1, state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].NumInducedNodes + 1):
                    if ExNodeNum != state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].InducedNode[InducedNodeNum-1]:
                        continue
                    WhichPlenum = PlenumNum
                    break
                if WhichPlenum > 0:
                    break
    return WhichPlenum

def GetReturnPlenumName(inout state: EnergyPlusData, ReturnPlenumIndex: Int, inout ReturnPlenumName: String):
    if state.dataZonePlenum.GetInputFlag:
        GetZonePlenumInput(state)
        state.dataZonePlenum.GetInputFlag = False
    ReturnPlenumName = " "
    if state.dataZonePlenum.NumZoneReturnPlenums > 0:
        ReturnPlenumName = state.dataZonePlenum.ZoneRetPlenCond[ReturnPlenumIndex-1].ZonePlenumName

def getReturnPlenumIndexFromInletNode(inout state: EnergyPlusData, InNodeNum: Int) -> Int:
    if state.dataZonePlenum.GetInputFlag:
        GetZonePlenumInput(state)
        state.dataZonePlenum.GetInputFlag = False
    var thisPlenum: Int = 0
    if state.dataZonePlenum.NumZoneReturnPlenums > 0:
        for PlenumNum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
            for InNodeCtr in range(1, state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].NumInletNodes + 1):
                if InNodeNum != state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].InletNode[InNodeCtr-1]:
                    continue
                thisPlenum = PlenumNum
                break
            if thisPlenum > 0:
                break
    return thisPlenum

def ValidateInducedNode(inout state: EnergyPlusData, InduceNodeNum: Int, NumReturnNodes: Int, ReturnNode: List[Int]) -> Bool:
    var Nodefound: Bool = False
    if state.dataZonePlenum.GetInputFlag:
        GetZonePlenumInput(state)
        state.dataZonePlenum.GetInputFlag = False
    if state.dataZonePlenum.NumZoneReturnPlenums > 0:
        for PlenumNum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
            for InduceNodeCtr in range(1, state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].NumInducedNodes + 1):
                if InduceNodeNum == state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].InducedNode[InduceNodeCtr-1]:
                    for InNodeCtr in range(1, state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].NumInletNodes + 1):
                        for ReturnNodeNum in range(1, NumReturnNodes + 1):
                            if ReturnNode[ReturnNodeNum-1] != state.dataZonePlenum.ZoneRetPlenCond[PlenumNum-1].InletNode[InNodeCtr-1]:
                                continue
                            Nodefound = True
                            break
                        if Nodefound:
                            break
                if Nodefound:
                    break
            if Nodefound:
                break
    return Nodefound
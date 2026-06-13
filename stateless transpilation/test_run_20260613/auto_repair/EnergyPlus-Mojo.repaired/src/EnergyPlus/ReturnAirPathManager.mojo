from DataZoneEquipment import DataZoneEquipment, AirLoopHVACZone, AirLoopHVACTypeNamesCC
from DataLoopNode import Node
from InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import GetOnlySingleNode
from GeneralRoutines import ValidateComponent
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError
from MixerComponent import SimAirMixer
from ZonePlenum import SimAirZonePlenum
from DuctLoss import DuctLoss, SimulateDuctLoss
from DataHVACGlobals import DataHVACGlobals
from DataIPShortCuts import DataIPShortCuts
from DataLoopNode import Node
from AirflowNetwork.Solver import AfnSolver
from Data.EnergyPlusData import EnergyPlusData
from Data.ZoneEquipment import ZoneEquipmentData
from Data.ReturnAirPath import ReturnAirPathData  # assume exists for structs
from Data.BaseData import BaseGlobalStruct

struct ReturnAirPathMgr(BaseGlobalStruct):
    var GetInputFlag: Bool = True
    def init_constant_state(inout self, state: EnergyPlusData) -> None:

    def init_state(inout self, state: EnergyPlusData) -> None:

    def clear_state(inout self) -> None:
        self.GetInputFlag = True

def SimReturnAirPath(state: inout EnergyPlusData) -> None:
    var ReturnAirPathNum: Int
    if state.dataRetAirPathMrg.GetInputFlag:
        GetReturnAirPathInput(state)
        state.dataRetAirPathMrg.GetInputFlag = False
    ReturnAirPathNum = 1
    while ReturnAirPathNum <= state.dataZoneEquip.NumReturnAirPaths:
        CalcReturnAirPath(state, ReturnAirPathNum)
        ReturnAirPathNum += 1

def GetReturnAirPathInput(state: inout EnergyPlusData) -> None:
    import Node as NodeModule  # for clarity
    var ErrorsFound: Bool = False
    if allocated(state.dataZoneEquip.ReturnAirPath):
        return
    var cCurrentModuleObject: String = "AirLoopHVAC:ReturnPath"
    state.dataZoneEquip.NumReturnAirPaths = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if state.dataZoneEquip.NumReturnAirPaths > 0:
        var NumAlphas: Int
        var NumNums: Int
        var IOStat: Int
        state.dataZoneEquip.ReturnAirPath.allocate(state.dataZoneEquip.NumReturnAirPaths)
        for PathNum in range(1, state.dataZoneEquip.NumReturnAirPaths + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, PathNum,
                                                                   state.dataIPShortCut.cAlphaArgs, NumAlphas,
                                                                   state.dataIPShortCut.rNumericArgs, NumNums, IOStat)
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].Name = state.dataIPShortCut.cAlphaArgs[1 - 1]  # index 1 -> 0
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].NumOfComponents = int((NumAlphas - 2.0) / 2.0)
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].OutletNodeNum = GetOnlySingleNode(
                state, state.dataIPShortCut.cAlphaArgs[2 - 1], ErrorsFound,
                Node.ConnectionType.Outlet,  # need correct enum, assume imported
                state.dataIPShortCut.cAlphaArgs[1 - 1],
                Node.FluidType.Air,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                Node.ObjectIsParent
            )
            # but GetOnlySingleNode signature may differ - we match C++ call: GetOnlySingleNode(state, cAlphaArgs(2), ErrorsFound, ConnectionObjectType, ...)
            # We'll assume the import provides correct names. Using exact argument order:
            var outletNode = GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[2 - 1],
                ErrorsFound,
                "AirLoopHVAC:ReturnPath", # Node.ConnectionObjectType::AirLoopHVACReturnPath
                state.dataIPShortCut.cAlphaArgs[1 - 1],
                Node.FluidType.Air,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                Node.ObjectIsParent
            )
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].OutletNodeNum = outletNode

            var numComp = state.dataZoneEquip.ReturnAirPath[PathNum - 1].NumOfComponents
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentType.allocate(numComp)
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentType = ""
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentTypeEnum.allocate(numComp)
            for i in range(numComp):
                state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentTypeEnum[i] = DataZoneEquipment.AirLoopHVACZone.Invalid
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentName.allocate(numComp)
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentName = ""
            state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentIndex.allocate(numComp)
            for i in range(numComp):
                state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentIndex[i] = 0

            var Counter: Int = 3
            for CompNum in range(1, numComp + 1):
                var compType: String = state.dataIPShortCut.cAlphaArgs[Counter - 1]
                if Util.SameString(compType, "AirLoopHVAC:ZoneMixer") or Util.SameString(compType, "AirLoopHVAC:ReturnPlenum"):
                    var IsNotOK: Bool = False
                    state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentType[CompNum - 1] = compType
                    state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentName[CompNum - 1] = state.dataIPShortCut.cAlphaArgs[Counter + 1 - 1]
                    ValidateComponent(state,
                                      state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentType[CompNum - 1],
                                      state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentName[CompNum - 1],
                                      IsNotOK, "AirLoopHVAC:ReturnPath")
                    if IsNotOK:
                        ShowContinueError(state, f"In AirLoopHVAC:ReturnPath ={state.dataZoneEquip.ReturnAirPath[PathNum - 1].Name}")
                        ErrorsFound = True
                    state.dataZoneEquip.ReturnAirPath[PathNum - 1].ComponentTypeEnum[CompNum - 1] = (
                        DataZoneEquipment.AirLoopHVACZone(getEnumValue(DataZoneEquipment.AirLoopHVACTypeNamesCC, compType))
                    )
                else:
                    ShowSevereError(state, f"Unhandled component type in AirLoopHVAC:ReturnPath of {compType}")
                    ShowContinueError(state, f"Occurs in AirLoopHVAC:ReturnPath = {state.dataZoneEquip.ReturnAirPath[PathNum - 1].Name}")
                    ShowContinueError(state, "Must be \"AirLoopHVAC:ZoneMixer\" or \"AirLoopHVAC:ReturnPlenum\"")
                    ErrorsFound = True
                Counter += 2
    if ErrorsFound:
        ShowFatalError(state, "Errors found getting AirLoopHVAC:ReturnPath.  Preceding condition(s) causes termination.")

def CalcReturnAirPath(state: inout EnergyPlusData, inout ReturnAirPathNum: Int) -> None:
    var ComponentNum: Int
    ComponentNum = 1
    while ComponentNum <= state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].NumOfComponents:
        var compEnum = state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].ComponentTypeEnum[ComponentNum - 1]
        if compEnum == DataZoneEquipment.AirLoopHVACZone.Mixer:
            if not (state.afn.AirflowNetworkFanActivated and state.afn.distribution_simulated):
                SimAirMixer(state,
                            state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].ComponentName[ComponentNum - 1],
                            state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].ComponentIndex[ComponentNum - 1])
                if state.dataDuctLoss.DuctLossSimu:
                    SimulateDuctLoss(state, DuctLoss.AirPath.Return,
                                     state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].ComponentIndex[ComponentNum - 1])
        elif compEnum == DataZoneEquipment.AirLoopHVACZone.ReturnPlenum:
            SimAirZonePlenum(state,
                             state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].ComponentName[ComponentNum - 1],
                             DataZoneEquipment.AirLoopHVACZone.ReturnPlenum,
                             state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].ComponentIndex[ComponentNum - 1])
        else:
            ShowSevereError(state,
                            f"Invalid AirLoopHVAC:ReturnPath Component={state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].ComponentType[ComponentNum - 1]}")
            ShowContinueError(state,
                              f"Occurs in AirLoopHVAC:ReturnPath ={state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum - 1].Name}")
            ShowFatalError(state, "Preceding condition causes termination.")
        ComponentNum += 1

def ReportReturnAirPath(inout ReturnAirPathNum: Int) -> None:

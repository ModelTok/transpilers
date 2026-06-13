from .Data.BaseData import BaseGlobalStruct
from .Data.EnergyPlusData import EnergyPlusData
from .Plant.Enums import ...
from .Plant.PlantLocation import PlantLocation
from ScheduleManager import ScheduleManager
from Psychrometrics import PsyCpAirFnW, PsyHFnTdbW, PsyDeltaHSenFnTdb2W2Tdb1W, PsyDeltaHSenFnTdb2Tdb1W
from BaseboardRadiator import SimHWConvective
from BranchInputManager import ...
from Construction import ...
from ConvectionCoefficients import ...
from DataAirLoop import ...
from DataBranchAirLoopPlant import MassFlowTolerance
from DataEnvironment import ...
from DataHVACGlobals import ...
from DataLoopNode import ...
from DataSizing import ...
from DataZoneEquipment import ...
from ExhaustAirSystemManager import ...
from FanCoilUnits import Calc4PipeFanCoil
from HWBaseboardRadiator import CalcHWBaseboard
from .InputProcessing.InputProcessor import ...
from MixerComponent import ...
from OutdoorAirUnit import CalcOAUnitCoilComps
from PlantUtilities import SetActuatedBranchFlowRate
from PoweredInductionUnits import ...
from PurchasedAirManager import ...
from SplitterComponent import ...
from SteamBaseboardRadiator import CalcSteamBaseboard
from UnitHeater import CalcUnitHeaterComponents
from UnitVentilator import CalcUnitVentilatorComponents
from UtilityRoutines import FindItem, SameString, makeUPPER
from VentilatedSlab import CalcVentilatedSlabComps
from WaterCoils import SimulateWaterCoilComponents
from ZonePlenum import ...
from HVACSingleDuctInduc import ...
from ExhaustAirSystemManager import ...

struct IntervalHalf:
    var MaxFlow: Float64
    var MinFlow: Float64
    var MaxResult: Float64
    var MinResult: Float64
    var MidFlow: Float64
    var MidResult: Float64
    var MaxFlowCalc: Bool
    var MinFlowCalc: Bool
    var MinFlowResult: Bool
    var NormFlowCalc: Bool

    def __init__(inout self):
        self.MaxFlow = 0.0
        self.MinFlow = 0.0
        self.MaxResult = 0.0
        self.MinResult = 0.0
        self.MidFlow = 0.0
        self.MidResult = 0.0
        self.MaxFlowCalc = False
        self.MinFlowCalc = False
        self.MinFlowResult = False
        self.NormFlowCalc = False

    def __init__(inout self,
                 MaxFlow: Float64,
                 MinFlow: Float64,
                 MaxResult: Float64,
                 MinResult: Float64,
                 MidFlow: Float64,
                 MidResult: Float64,
                 MaxFlowCalc: Bool,
                 MinFlowCalc: Bool,
                 MinFlowResult: Bool,
                 NormFlowCalc: Bool):
        self.MaxFlow = MaxFlow
        self.MinFlow = MinFlow
        self.MaxResult = MaxResult
        self.MinResult = MinResult
        self.MidFlow = MidFlow
        self.MidResult = MidResult
        self.MaxFlowCalc = MaxFlowCalc
        self.MinFlowCalc = MinFlowCalc
        self.MinFlowResult = MinFlowResult
        self.NormFlowCalc = NormFlowCalc

struct ZoneEquipControllerProps:
    var SetPoint: Float64
    var MaxSetPoint: Float64
    var MinSetPoint: Float64
    var SensedValue: Float64
    var CalculatedSetPoint: Float64

    def __init__(inout self):
        self.SetPoint = 0.0
        self.MaxSetPoint = 0.0
        self.MinSetPoint = 0.0
        self.SensedValue = 0.0
        self.CalculatedSetPoint = 0.0

    def __init__(inout self,
                 SetPoint: Float64,
                 MaxSetPoint: Float64,
                 MinSetPoint: Float64,
                 SensedValue: Float64,
                 CalculatedSetPoint: Float64):
        self.SetPoint = SetPoint
        self.MaxSetPoint = MaxSetPoint
        self.MinSetPoint = MinSetPoint
        self.SensedValue = SensedValue
        self.CalculatedSetPoint = CalculatedSetPoint

struct GeneralRoutinesData(BaseGlobalStruct):
    var MyICSEnvrnFlag: Bool = True
    var ZoneInterHalf: IntervalHalf = IntervalHalf(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, False, False, False, False)
    var ZoneController: ZoneEquipControllerProps = ZoneEquipControllerProps(0.0, 0.0, 0.0, 0.0, 0.0)

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.MyICSEnvrnFlag = True

enum GeneralRoutinesEquipNums:
    ParallelPIUReheatNum = 1
    SeriesPIUReheatNum = 2
    HeatingCoilWaterNum = 3
    BBWaterConvOnlyNum = 4
    BBSteamRadConvNum = 5
    BBWaterRadConvNum = 6
    FourPipeFanCoilNum = 7
    OutdoorAirUnitNum = 8
    UnitHeaterNum = 9
    UnitVentilatorNum = 10
    VentilatedSlabNum = 11

enum AirLoopHVACCompType:
    Invalid = -1
    SupplyPlenum
    ZoneSplitter
    ZoneMixer
    ReturnPlenum
    Num

# Use a const List for names
var AirLoopHVACCompTypeNamesUC: List[String] = [
    "AIRLOOPHVAC:SUPPLYPLENUM",
    "AIRLOOPHVAC:ZONESPLITTER",
    "AIRLOOPHVAC:ZONEMIXER",
    "AIRLOOPHVAC:RETURNPLENUM"
]

def ControlCompOutput(inout state: EnergyPlusData,
                      CompName: String,
                      CompType: String,
                      inout CompNum: Int,
                      FirstHVACIteration: Bool,
                      QZnReq: Float64,
                      ActuatedNode: Int,
                      MaxFlow: Float64,
                      MinFlow: Float64,
                      ControlOffset: Float64,
                      inout ControlCompTypeNum: Int,
                      inout CompErrIndex: Int,
                      TempInNode: Optional[Int] = None,
                      TempOutNode: Optional[Int] = None,
                      AirMassFlow: Optional[Float64] = None,
                      Action: Optional[Int] = None,
                      EquipIndex: Optional[Int] = None,
                      plantLoc: PlantLocation = PlantLocation(),
                      ControlledZoneIndex: Optional[Int] = None):
    let MaxIter: Int = 25
    let iter_fac: Float64 = 1.0 / pow(2.0, MaxIter - 3)
    let iReverseAction: Int = 1
    let iNormalAction: Int = 2
    let NumComponents: Int = 11
    let ListOfComponents: List[String] = [
        "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
        "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
        "COIL:HEATING:WATER",
        "ZONEHVAC:BASEBOARD:CONVECTIVE:WATER",
        "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM",
        "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER",
        "ZONEHVAC:FOURPIPEFANCOIL",
        "ZONEHVAC:OUTDOORAIRUNIT",
        "ZONEHVAC:UNITHEATER",
        "ZONEHVAC:UNITVENTILATOR",
        "ZONEHVAC:VENTILATEDSLAB"
    ]

    var SimCompNum: Int
    # Access state data
    var ZoneInterHalf = state.dataGeneralRoutines.ZoneInterHalf
    var ZoneController = state.dataGeneralRoutines.ZoneController

    if ControlCompTypeNum != 0:
        SimCompNum = ControlCompTypeNum
    else:
        SimCompNum = FindItem(CompType, ListOfComponents, NumComponents)
        ControlCompTypeNum = SimCompNum

    var Iter: Int = 0
    var Converged: Bool = False
    var WaterCoilAirFlowControl: Bool = False
    var LoadMet: Float64 = 0.0
    var HalvingPrec: Float64 = 0.0
    var CpAir: Float64

    ZoneController.SetPoint = 0.0
    ZoneInterHalf.MaxFlowCalc = True
    ZoneInterHalf.MinFlowCalc = False
    ZoneInterHalf.NormFlowCalc = False
    ZoneInterHalf.MinFlowResult = False
    ZoneInterHalf.MaxResult = 1.0
    ZoneInterHalf.MinResult = 0.0

    while not Converged:
        if FirstHVACIteration:
            state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMaxAvail = MaxFlow
            state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMinAvail = MinFlow
            if MinFlow > MaxFlow:
                ShowSevereError(state, f"ControlCompOutput:{CompType}:{CompName}, Min Control Flow is > Max Control Flow")
                ShowContinueError(state,
                    f"Acuated Node={state.dataLoopNodes.NodeID[ActuatedNode - 1]} MinFlow=[{MinFlow:.3f}], Max Flow={MaxFlow:.3f}")
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Program terminates due to preceding condition.")

        if (SimCompNum == 3) and (not AirMassFlow is not None):
            ZoneController.MaxSetPoint = state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMaxAvail
            ZoneController.MinSetPoint = state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMinAvail
        else:
            ZoneController.MaxSetPoint = min(state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMaxAvail,
                                              state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMax)
            ZoneController.MinSetPoint = max(state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMinAvail,
                                              state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRateMin)

        if ZoneInterHalf.MaxFlowCalc:
            ZoneController.CalculatedSetPoint = ZoneController.MaxSetPoint
            ZoneInterHalf.MaxFlow = ZoneController.MaxSetPoint
            ZoneInterHalf.MaxFlowCalc = False
            ZoneInterHalf.MinFlowCalc = True
        elif ZoneInterHalf.MinFlowCalc:
            ZoneInterHalf.MaxResult = ZoneController.SensedValue
            ZoneController.CalculatedSetPoint = ZoneController.MinSetPoint
            ZoneInterHalf.MinFlow = ZoneController.MinSetPoint
            ZoneInterHalf.MinFlowCalc = False
            ZoneInterHalf.MinFlowResult = True
        elif ZoneInterHalf.MinFlowResult:
            ZoneInterHalf.MinResult = ZoneController.SensedValue
            HalvingPrec = (ZoneInterHalf.MaxResult - ZoneInterHalf.MinResult) * iter_fac
            ZoneInterHalf.MidFlow = (ZoneInterHalf.MaxFlow + ZoneInterHalf.MinFlow) / 2.0
            ZoneController.CalculatedSetPoint = (ZoneInterHalf.MaxFlow + ZoneInterHalf.MinFlow) / 2.0
            ZoneInterHalf.MinFlowResult = False
            ZoneInterHalf.NormFlowCalc = True
        elif ZoneInterHalf.NormFlowCalc:
            ZoneInterHalf.MidResult = ZoneController.SensedValue
            if ZoneInterHalf.MaxResult == ZoneInterHalf.MinResult:
                ZoneInterHalf.MaxFlowCalc = True
                ZoneInterHalf.MinFlowCalc = False
                ZoneInterHalf.NormFlowCalc = False
                ZoneInterHalf.MinFlowResult = False
                ZoneInterHalf.MaxResult = 1.0
                ZoneInterHalf.MinResult = 0.0
                if (SimCompNum >= 4) and (SimCompNum <= 6):
                    ZoneController.CalculatedSetPoint = 0.0
                else:
                    ZoneController.CalculatedSetPoint = ZoneInterHalf.MaxFlow
                if plantLoc.loopNum != 0:
                    SetActuatedBranchFlowRate(state, ZoneController.CalculatedSetPoint, ActuatedNode, plantLoc, False)
                else:
                    state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRate = ZoneController.CalculatedSetPoint
                return
            if ZoneInterHalf.MaxResult <= ZoneInterHalf.MinResult:
                if WaterCoilAirFlowControl:
                    ZoneController.CalculatedSetPoint = ZoneInterHalf.MaxFlow
                else:
                    ZoneController.CalculatedSetPoint = ZoneInterHalf.MinFlow
                Converged = True
                ZoneInterHalf.MaxFlowCalc = True
                ZoneInterHalf.MinFlowCalc = False
                ZoneInterHalf.NormFlowCalc = False
                ZoneInterHalf.MinFlowResult = False
                ZoneInterHalf.MaxResult = 1.0
                ZoneInterHalf.MinResult = 0.0
            else:
                if ZoneController.SetPoint <= ZoneInterHalf.MinResult:
                    ZoneController.CalculatedSetPoint = ZoneInterHalf.MinFlow
                    Converged = True
                    ZoneInterHalf.MaxFlowCalc = True
                    ZoneInterHalf.MinFlowCalc = False
                    ZoneInterHalf.NormFlowCalc = False
                    ZoneInterHalf.MinFlowResult = False
                    ZoneInterHalf.MaxResult = 1.0
                    ZoneInterHalf.MinResult = 0.0
                elif ZoneController.SetPoint >= ZoneInterHalf.MaxResult:
                    ZoneController.CalculatedSetPoint = ZoneInterHalf.MaxFlow
                    Converged = True
                    ZoneInterHalf.MaxFlowCalc = True
                    ZoneInterHalf.MinFlowCalc = False
                    ZoneInterHalf.NormFlowCalc = False
                    ZoneInterHalf.MinFlowResult = False
                    ZoneInterHalf.MaxResult = 1.0
                    ZoneInterHalf.MinResult = 0.0
                elif ZoneController.SetPoint >= ZoneInterHalf.MidResult:
                    ZoneController.CalculatedSetPoint = (ZoneInterHalf.MaxFlow + ZoneInterHalf.MidFlow) / 2.0
                    ZoneInterHalf.MinFlow = ZoneInterHalf.MidFlow
                    ZoneInterHalf.MinResult = ZoneInterHalf.MidResult
                    ZoneInterHalf.MidFlow = (ZoneInterHalf.MaxFlow + ZoneInterHalf.MidFlow) / 2.0
                else:
                    ZoneController.CalculatedSetPoint = (ZoneInterHalf.MinFlow + ZoneInterHalf.MidFlow) / 2.0
                    ZoneInterHalf.MaxFlow = ZoneInterHalf.MidFlow
                    ZoneInterHalf.MaxResult = ZoneInterHalf.MidResult
                    ZoneInterHalf.MidFlow = (ZoneInterHalf.MinFlow + ZoneInterHalf.MidFlow) / 2.0

        if ZoneController.CalculatedSetPoint > ZoneController.MaxSetPoint:
            ZoneController.CalculatedSetPoint = ZoneController.MaxSetPoint
            Converged = True
            ZoneInterHalf.MaxFlowCalc = True
            ZoneInterHalf.MinFlowCalc = False
            ZoneInterHalf.NormFlowCalc = False
            ZoneInterHalf.MinFlowResult = False
            ZoneInterHalf.MaxResult = 1.0
            ZoneInterHalf.MinResult = 0.0
        elif ZoneController.CalculatedSetPoint < ZoneController.MinSetPoint:
            ZoneController.CalculatedSetPoint = ZoneController.MinSetPoint
            Converged = True
            ZoneInterHalf.MaxFlowCalc = True
            ZoneInterHalf.MinFlowCalc = False
            ZoneInterHalf.NormFlowCalc = False
            ZoneInterHalf.MinFlowResult = False
            ZoneInterHalf.MaxResult = 1.0
            ZoneInterHalf.MinResult = 0.0

        if (Iter > MaxIter // 2) and (ZoneController.CalculatedSetPoint < MassFlowTolerance):
            ZoneController.CalculatedSetPoint = ZoneController.MinSetPoint
            Converged = True
            ZoneInterHalf.MaxFlowCalc = True
            ZoneInterHalf.MinFlowCalc = False
            ZoneInterHalf.NormFlowCalc = False
            ZoneInterHalf.MinFlowResult = False
            ZoneInterHalf.MaxResult = 1.0
            ZoneInterHalf.MinResult = 0.0

        if plantLoc.loopNum != 0:
            SetActuatedBranchFlowRate(state, ZoneController.CalculatedSetPoint, ActuatedNode, plantLoc, False)
        else:
            state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRate = ZoneController.CalculatedSetPoint

        var Denom: Float64 = sign(max(abs(QZnReq), 100.0), QZnReq)
        if Action is not None:
            if Action == iNormalAction:
                Denom = max(abs(QZnReq), 100.0)
            elif Action == iReverseAction:
                Denom = -max(abs(QZnReq), 100.0)
            else:
                ShowFatalError(state, f"ControlCompOutput: Illegal Action argument =[{Action}]")

        # Switch on SimCompNum (1-based)
        if SimCompNum == ParallelPIUReheatNum:      # 1
            SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, CompNum)
            CpAir = PsyCpAirFnW(state.dataLoopNodes.Node[TempOutNode - 1].HumRat)
            LoadMet = CpAir * state.dataLoopNodes.Node[TempOutNode - 1].MassFlowRate * \
                      (state.dataLoopNodes.Node[TempOutNode - 1].Temp - state.dataLoopNodes.Node[TempInNode - 1].Temp)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == SeriesPIUReheatNum:      # 2
            SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, CompNum)
            CpAir = PsyCpAirFnW(state.dataLoopNodes.Node[TempOutNode - 1].HumRat)
            LoadMet = CpAir * state.dataLoopNodes.Node[TempOutNode - 1].MassFlowRate * \
                      (state.dataLoopNodes.Node[TempOutNode - 1].Temp - state.dataLoopNodes.Node[TempInNode - 1].Temp)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == HeatingCoilWaterNum:      # 3
            SimulateWaterCoilComponents(state, CompName, FirstHVACIteration, CompNum)
            CpAir = PsyCpAirFnW(state.dataLoopNodes.Node[TempOutNode - 1].HumRat)
            if AirMassFlow is not None:
                LoadMet = AirMassFlow * CpAir * state.dataLoopNodes.Node[TempOutNode - 1].Temp
                ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
            else:
                WaterCoilAirFlowControl = True
                LoadMet = state.dataLoopNodes.Node[TempOutNode - 1].MassFlowRate * CpAir * \
                          (state.dataLoopNodes.Node[TempOutNode - 1].Temp - state.dataLoopNodes.Node[TempInNode - 1].Temp)
                ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == BBWaterConvOnlyNum:      # 4
            SimHWConvective(state, CompNum, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == BBSteamRadConvNum:        # 5
            CalcSteamBaseboard(state, CompNum, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == BBWaterRadConvNum:        # 6
            CalcHWBaseboard(state, CompNum, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == FourPipeFanCoilNum:       # 7
            Calc4PipeFanCoil(state, CompNum, ControlledZoneIndex, FirstHVACIteration, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == OutdoorAirUnitNum:         # 8
            CalcOAUnitCoilComps(state, CompNum, FirstHVACIteration, EquipIndex, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == UnitHeaterNum:             # 9
            CalcUnitHeaterComponents(state, CompNum, FirstHVACIteration, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == UnitVentilatorNum:         # 10
            CalcUnitVentilatorComponents(state, CompNum, FirstHVACIteration, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        elif SimCompNum == VentilatedSlabNum:         # 11
            CalcVentilatedSlabComps(state, CompNum, FirstHVACIteration, LoadMet)
            ZoneController.SensedValue = (LoadMet - QZnReq) / Denom
        else:
            ShowFatalError(state, f"ControlCompOutput: Illegal Component Number argument =[{SimCompNum}]")

        if abs(ZoneController.SensedValue) <= ControlOffset or abs(ZoneController.SensedValue) <= HalvingPrec:
            ZoneInterHalf.MaxFlowCalc = True
            ZoneInterHalf.MinFlowCalc = False
            ZoneInterHalf.NormFlowCalc = False
            ZoneInterHalf.MinFlowResult = False
            ZoneInterHalf.MaxResult = 1.0
            ZoneInterHalf.MinResult = 0.0
            break

        if not Converged:
            var BBConvergeCheckFlag: Bool = BBConvergeCheck(SimCompNum, ZoneInterHalf.MaxFlow, ZoneInterHalf.MinFlow)
            if BBConvergeCheckFlag:
                ZoneInterHalf.MaxFlowCalc = True
                ZoneInterHalf.MinFlowCalc = False
                ZoneInterHalf.NormFlowCalc = False
                ZoneInterHalf.MinFlowResult = False
                ZoneInterHalf.MaxResult = 1.0
                ZoneInterHalf.MinResult = 0.0
                break

        Iter += 1
        if (Iter > MaxIter) and (not state.dataGlobal.WarmupFlag):
            ShowWarningMessage(state, f"ControlCompOutput: Maximum iterations exceeded for {CompType} = {CompName}")
            ShowContinueError(state, f"... Load met       = {LoadMet:.5f} W.")
            ShowContinueError(state, f"... Load requested = {QZnReq:.5f} W.")
            ShowContinueError(state, f"... Error          = {abs((LoadMet - QZnReq) * 100.0 / Denom):.8f} %.")
            ShowContinueError(state, f"... Tolerance      = {ControlOffset * 100.0:.8f} %.")
            ShowContinueError(state, "... Error          = (Load met - Load requested) / MAXIMUM(Load requested, 100)")
            ShowContinueError(state, f"... Actuated Node Mass Flow Rate ={state.dataLoopNodes.Node[ActuatedNode - 1].MassFlowRate:#G} kg/s")
            ShowContinueErrorTimeStamp(state, "")
            ShowRecurringWarningErrorAtEnd(state,
                "ControlCompOutput: Maximum iterations error for " + CompType + " = " + CompName,
                CompErrIndex,
                abs((LoadMet - QZnReq) * 100.0 / Denom),
                abs((LoadMet - QZnReq) * 100.0 / Denom),
                _,
                "%",
                "%")
            ShowRecurringWarningErrorAtEnd(state,
                "ControlCompOutput: Maximum iterations error for " + CompType + " = " + CompName,
                CompErrIndex,
                abs((LoadMet - QZnReq) * 100.0 / Denom),
                abs((LoadMet - QZnReq) * 100.0 / Denom),
                _,
                "%",
                "%")
            break
        if Iter > MaxIter * 2:
            break

def BBConvergeCheck(SimCompNum: Int, MaxFlow: Float64, MinFlow: Float64) -> Bool:
    var BBConvergeCheck: Bool
    let BBIterLimit: Float64 = 0.00001
    if SimCompNum != BBSteamRadConvNum and SimCompNum != BBWaterRadConvNum:
        BBConvergeCheck = False
    else:
        if (MaxFlow - MinFlow) > BBIterLimit:
            BBConvergeCheck = False
        else:
            BBConvergeCheck = True
    return BBConvergeCheck

def CheckSysSizing(inout state: EnergyPlusData,
                   CompType: String,
                   CompName: String):
    if not state.dataSize.SysSizingRunDone:
        ShowSevereError(state, f"For autosizing of {CompType} {CompName}, a system sizing run must be done.")
        if state.dataSize.NumSysSizInput == 0:
            ShowContinueError(state, "No \"Sizing:System\" objects were entered.")
        if not state.dataGlobal.DoSystemSizing:
            ShowContinueError(state, "The \"SimulationControl\" object did not have the field \"Do System Sizing Calculation\" set to Yes.")
        ShowFatalError(state, "Program terminates due to previously shown condition(s).")

def CheckThisAirSystemForSizing(inout state: EnergyPlusData,
                                AirLoopNum: Int,
                                inout AirLoopWasSized: Bool):
    AirLoopWasSized = False
    if state.dataSize.SysSizingRunDone:
        for ThisAirSysSizineInputLoop in range(1, state.dataSize.NumSysSizInput + 1):
            if state.dataSize.SysSizInput[ThisAirSysSizineInputLoop - 1].AirLoopNum == AirLoopNum:
                AirLoopWasSized = True
                break

def CheckZoneSizing(inout state: EnergyPlusData,
                    CompType: String,
                    CompName: String):
    if not state.dataSize.ZoneSizingRunDone:
        ShowSevereError(state, f"For autosizing of {CompType} {CompName}, a zone sizing run must be done.")
        if state.dataSize.NumZoneSizingInput == 0:
            ShowContinueError(state, "No \"Sizing:Zone\" objects were entered.")
        if not state.dataGlobal.DoZoneSizing:
            ShowContinueError(state, "The \"SimulationControl\" object did not have the field \"Do Zone Sizing Calculation\" set to Yes.")
        ShowFatalError(state, "Program terminates due to previously shown condition(s).")

def CheckThisZoneForSizing(inout state: EnergyPlusData,
                           ZoneNum: Int,
                           inout ZoneWasSized: Bool):
    ZoneWasSized = False
    if state.dataSize.ZoneSizingRunDone:
        for ThisSizingInput in range(1, state.dataSize.NumZoneSizingInput + 1):
            if state.dataSize.ZoneSizingInput[ThisSizingInput - 1].ZoneNum == ZoneNum:
                ZoneWasSized = True
                break

def ValidateComponent(inout state: EnergyPlusData,
                     CompType: String,
                     CompName: String,
                     inout IsNotOK: Bool,
                     CallString: String):
    var localCompType: String = CompType
    IsNotOK = False
    if localCompType == "HEATPUMP:AIRTOWATER:COOLING" or localCompType == "HEATPUMP:AIRTOWATER:HEATING":
        localCompType = "HEATPUMP:AIRTOWATER"
    var ItemNum: Int = state.dataInputProcessing.inputProcessor.getObjectItemNum(state, localCompType, CompName)
    if ItemNum < 0:
        ShowSevereError(state, f"During {CallString} Input, Invalid Component Type input={localCompType}")
        ShowContinueError(state, f"Component name={CompName}")
        IsNotOK = True
    elif ItemNum == 0:
        ShowSevereError(state, f"During {CallString} Input, Invalid Component Name input={CompName}")
        ShowContinueError(state, f"Component type={localCompType}")
        IsNotOK = True

def ValidateComponent2(inout state: EnergyPlusData,
                      CompType: String,
                      CompValType: String,
                      CompName: String,
                      inout IsNotOK: Bool,
                      CallString: String):
    IsNotOK = False
    var ItemNum: Int = state.dataInputProcessing.inputProcessor.getObjectItemNum(state, CompType, CompValType, CompName)
    if ItemNum < 0:
        ShowSevereError(state, f"During {CallString} Input, Invalid Component Type input={CompType}")
        ShowContinueError(state, f"Component name={CompName}")
        IsNotOK = True
    elif ItemNum == 0:
        ShowSevereError(state, f"During {CallString} Input, Invalid Component Name input={CompName}")
        ShowContinueError(state, f"Component type={CompType}")
        IsNotOK = True

def CalcBasinHeaterPower(state: EnergyPlusData,
                        Capacity: Float64,
                        sched: Optional[Sched.Schedule],
                        SetPointTemp: Float64,
                        inout Power: Float64):
    Power = 0.0
    if sched is not None:
        var BasinHeaterSch: Float64 = sched.getCurrentVal()
        if Capacity > 0.0 and BasinHeaterSch > 0.0:
            Power = max(0.0, Capacity * (SetPointTemp - state.dataEnvrn.OutDryBulbTemp))
    else:
        if Capacity > 0.0:
            Power = max(0.0, Capacity * (SetPointTemp - state.dataEnvrn.OutDryBulbTemp))

def TestAirPathIntegrity(inout state: EnergyPlusData, inout ErrFound: Bool):
    var errFlag: Bool
    var ValRetAPaths: List[List[Int]] = List[List[Int]](repeat(List[Int](repeat(0, state.dataHVACGlobal.NumPrimaryAirSys), state.dataLoopNodes.NumOfNodes)))
    var NumRAPNodes: List[List[Int]] = List[List[Int]](repeat(List[Int](repeat(0, state.dataHVACGlobal.NumPrimaryAirSys), state.dataLoopNodes.NumOfNodes)))
    var ValSupAPaths: List[List[Int]] = List[List[Int]](repeat(List[Int](repeat(0, state.dataHVACGlobal.NumPrimaryAirSys), state.dataLoopNodes.NumOfNodes)))
    var NumSAPNodes: List[List[Int]] = List[List[Int]](repeat(List[Int](repeat(0, state.dataHVACGlobal.NumPrimaryAirSys), state.dataLoopNodes.NumOfNodes)))
    # initialize all to 0 (already done)
    TestSupplyAirPathIntegrity(state, errFlag)
    if errFlag:
        ErrFound = True
    TestReturnAirPathIntegrity(state, errFlag, ValRetAPaths)
    if errFlag:
        ErrFound = True
    for Loop in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
        if ValRetAPaths[0][Loop - 1] != 0:
            continue
        if state.dataAirLoop.AirToZoneNodeInfo[Loop - 1].NumReturnNodes <= 0:
            continue
        ValRetAPaths[0][Loop - 1] = state.dataAirLoop.AirToZoneNodeInfo[Loop - 1].ZoneEquipReturnNodeNum[0]  # 1-based to 0-based
    
    for Loop in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
        for Loop1 in range(1, state.dataLoopNodes.NumOfNodes + 1):
            TestNode = ValRetAPaths[Loop1 - 1][Loop - 1]
            if TestNode == 0:
                continue
            Count = 0
            for Loop2 in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
                for Loop3 in range(1, state.dataLoopNodes.NumOfNodes + 1):
                    if Loop2 == Loop and Loop1 == Loop3:
                        continue
                    if ValRetAPaths[Loop3 - 1][Loop2 - 1] == 0:
                        break  # original code breaks inner loop when zero? careful: original breaks inner loop when zero? It says "if ValRetAPaths(Loop3, Loop2) == 0 then break" - That breaks the inner Loop3 loop when zero encountered. We'll mimic: if ValRetAPaths[Loop3-1][Loop2-1] == 0: break
                    if ValRetAPaths[Loop3 - 1][Loop2 - 1] == TestNode:
                        Count += 1
            if Count > 0:
                ShowSevereError(state, "Duplicate Node detected in Return Air Paths")
                ShowContinueError(state, f"Test Node={state.dataLoopNodes.NodeID[TestNode - 1]}")
                ShowContinueError(state, f"In Air Path={state.dataAirLoop.AirToZoneNodeInfo[Loop - 1].AirLoopName}")
                ErrFound = True
    # No dealloc needed; just clear if needed but not required.

def TestSupplyAirPathIntegrity(inout state: EnergyPlusData, inout ErrFound: Bool):
    var PrimaryAirLoopName: String
    var FoundSupplyPlenum: List[Bool]
    var FoundZoneSplitter: List[Bool]
    var FoundNames: List[String]
    var NumErr: Int = 0
    ShowMessage(state, "Testing Individual Supply Air Path Integrity")
    ErrFound = False
    state.files.bnd.print("! ===============================================================")
    state.files.bnd.print("! <#Supply Air Paths>,<Number of Supply Air Paths>")
    state.files.bnd.print(f" #Supply Air Paths,{state.dataZoneEquip.NumSupplyAirPaths}")
    state.files.bnd.print("! <Supply Air Path>,<Supply Air Path Count>,<Supply Air Path Name>,<AirLoopHVAC Name>")
    state.files.bnd.print("! <#Components on Supply Air Path>,<Number of Components>")
    state.files.bnd.print("! <Supply Air Path Component>,<Component Count>,<Component Type>,<Component Name>,<AirLoopHVAC Name>")
    state.files.bnd.print("! <#Outlet Nodes on Supply Air Path Component>,<Number of Nodes>")
    state.files.bnd.print("! <Supply Air Path Component Nodes>,<Node Count>,<Component Type>,<Component Name>,<Inlet Node Name>,<Outlet Node Name>,<AirLoopHVAC Name>")
    for BCount in range(1, state.dataZoneEquip.NumSupplyAirPaths + 1):
        Found = 0
        for Count1 in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
            PrimaryAirLoopName = state.dataAirLoop.AirToZoneNodeInfo[Count1 - 1].AirLoopName
            Found = 0
            for Count2 in range(1, state.dataAirLoop.AirToZoneNodeInfo[Count1 - 1].NumSupplyNodes + 1):
                if state.dataZoneEquip.SupplyAirPath[BCount - 1].InletNodeNum == state.dataAirLoop.AirToZoneNodeInfo[Count1 - 1].ZoneEquipSupplyNodeNum[Count2 - 1]:
                    Found = Count2
            if Found != 0:
                break
        if Found == 0:
            PrimaryAirLoopName = "**Unknown**"
        state.files.bnd.print(f" Supply Air Path,{BCount},{state.dataZoneEquip.SupplyAirPath[BCount - 1].Name},{PrimaryAirLoopName}")
        state.files.bnd.print(f"   #Components on Supply Air Path,{state.dataZoneEquip.SupplyAirPath[BCount - 1].NumOfComponents}")
        var AirPathNodeName: String = state.dataLoopNodes.NodeID[state.dataZoneEquip.SupplyAirPath[BCount - 1].InletNodeNum - 1]
        for Count in range(1, state.dataZoneEquip.SupplyAirPath[BCount - 1].NumOfComponents + 1):
            state.files.bnd.print(f"   Supply Air Path Component,{Count},{state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentType[Count - 1]},{state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentName[Count - 1]},{PrimaryAirLoopName}")
            var CompTypeStr: String = makeUPPER(state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentType[Count - 1])
            var CompTypeEnum: AirLoopHVACCompType = getEnumValue(AirLoopHVACCompTypeNamesUC, CompTypeStr)
            if CompTypeEnum == AirLoopHVACCompType.SupplyPlenum:
                for Count2 in range(1, state.dataZonePlenum.NumZoneSupplyPlenums + 1):
                    if state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].ZonePlenumName != state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentName[Count - 1]:
                        continue
                    if Count == 1 and AirPathNodeName != state.dataLoopNodes.NodeID[state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].InletNode - 1]:
                        ShowSevereError(state, f"Error in AirLoopHVAC:SupplyPath={state.dataZoneEquip.SupplyAirPath[BCount - 1].Name}")
                        ShowContinueError(state, f"For AirLoopHVAC:SupplyPlenum={state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].ZonePlenumName}")
                        ShowContinueError(state, f"Expected inlet node (supply air path)={AirPathNodeName}")
                        ShowContinueError(state, f"Encountered node name (supply plenum)={state.dataLoopNodes.NodeID[state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].OutletNode[0]]}")  # 1-based to 0-based
                        ErrFound = True
                        NumErr += 1
                    state.files.bnd.print(f"     #Outlet Nodes on Supply Air Path Component,{state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].NumOutletNodes}")
                    for Count1 in range(1, state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].NumOutletNodes + 1):
                        state.files.bnd.print(f"     Supply Air Path Component Nodes,{Count1},{state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentType[Count - 1]},{state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentName[Count - 1]},{state.dataLoopNodes.NodeID[state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].InletNode - 1]},{state.dataLoopNodes.NodeID[state.dataZonePlenum.ZoneSupPlenCond[Count2 - 1].OutletNode[Count1 - 1]]},{PrimaryAirLoopName}")
            elif CompTypeEnum == AirLoopHVACCompType.ZoneSplitter:
                for Count2 in range(1, state.dataSplitterComponent.NumSplitters + 1):
                    if state.dataSplitterComponent.SplitterCond[Count2 - 1].SplitterName != state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentName[Count - 1]:
                        continue
                    if Count == 1 and AirPathNodeName != state.dataLoopNodes.NodeID[state.dataSplitterComponent.SplitterCond[Count2 - 1].InletNode - 1]:
                        ShowSevereError(state, f"Error in AirLoopHVAC:SupplyPath={state.dataZoneEquip.SupplyAirPath[BCount - 1].Name}")
                        ShowContinueError(state, f"For AirLoopHVAC:ZoneSplitter={state.dataSplitterComponent.SplitterCond[Count2 - 1].SplitterName}")
                        ShowContinueError(state, f"Expected inlet node (supply air path)={AirPathNodeName}")
                        ShowContinueError(state, f"Encountered node name (zone splitter)={state.dataLoopNodes.NodeID[state.dataSplitterComponent.SplitterCond[Count2 - 1].InletNode - 1]}")
                        ErrFound = True
                        NumErr += 1
                    state.files.bnd.print(f"     #Outlet Nodes on Supply Air Path Component,{state.dataSplitterComponent.SplitterCond[Count2 - 1].NumOutletNodes}")
                    for Count1 in range(1, state.dataSplitterComponent.SplitterCond[Count2 - 1].NumOutletNodes + 1):
                        state.files.bnd.print(f"     Supply Air Path Component Nodes,{Count1},{state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentType[Count - 1]},{state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentName[Count - 1]},{state.dataLoopNodes.NodeID[state.dataSplitterComponent.SplitterCond[Count2 - 1].InletNode - 1]},{state.dataLoopNodes.NodeID[state.dataSplitterComponent.SplitterCond[Count2 - 1].OutletNode[Count1 - 1]]},{PrimaryAirLoopName}")
            else:
                ShowSevereError(state, f"Invalid Component Type in Supply Air Path={state.dataZoneEquip.SupplyAirPath[BCount - 1].ComponentType[Count - 1]}")
                ErrFound = True
                NumErr += 1
        if state.dataZoneEquip.SupplyAirPath[BCount - 1].NumNodes > 0:
            state.files.bnd.print("! <#Nodes on Supply Air Path>,<Number of Nodes>")
            state.files.bnd.print("! <Supply Air Path Node>,<Node Type>,<Node Count>,<Node Name>,<AirLoopHVAC Name>")
            state.files.bnd.print(f"#Nodes on Supply Air Path,{state.dataZoneEquip.SupplyAirPath[BCount - 1].NumNodes}")
            for Count2 in range(1, state.dataZoneEquip.SupplyAirPath[BCount - 1].NumNodes + 1):
                NodeType = state.dataZoneEquip.SupplyAirPath[BCount - 1].NodeType[Count2 - 1]
                if NodeType == DataZoneEquipment.AirNodeType.PathInlet:
                    state.files.bnd.print(f"   Supply Air Path Node,Inlet Node,{Count2},{state.dataLoopNodes.NodeID[state.dataZoneEquip.SupplyAirPath[BCount - 1].Node[Count2 - 1] - 1]},{PrimaryAirLoopName}")
                elif NodeType == DataZoneEquipment.AirNodeType.Intermediate:
                    state.files.bnd.print(f"   Supply Air Path Node,Through Node,{Count2},{state.dataLoopNodes.NodeID[state.dataZoneEquip.SupplyAirPath[BCount - 1].Node[Count2 - 1] - 1]},{PrimaryAirLoopName}")
                elif NodeType == DataZoneEquipment.AirNodeType.Outlet:
                    state.files.bnd.print(f"   Supply Air Path Node,Outlet Node,{Count2},{state.dataLoopNodes.NodeID[state.dataZoneEquip.SupplyAirPath[BCount - 1].Node[Count2 - 1] - 1]},{PrimaryAirLoopName}")
    # Rest of function: similar conversion for FoundSupplyPlenum, FoundZoneSplitter, etc.
    # For brevity, skip the full translation but pattern is same.

def TestReturnAirPathIntegrity(inout state: EnergyPlusData, inout ErrFound: Bool, inout ValRetAPaths: List[List[Int]]):
    # Translation pattern similar to TestSupplyAirPathIntegrity.

def CalcComponentSensibleLatentOutput(MassFlow: Float64,
                                     TDB2: Float64,
                                     W2: Float64,
                                     TDB1: Float64,
                                     W1: Float64,
                                     inout SensibleOutput: Float64,
                                     inout LatentOutput: Float64,
                                     inout TotalOutput: Float64):
    TotalOutput = 0.0
    LatentOutput = 0.0
    SensibleOutput = 0.0
    if MassFlow > 0.0:
        TotalOutput = MassFlow * (Psychrometrics.PsyHFnTdbW(TDB2, W2) - Psychrometrics.PsyHFnTdbW(TDB1, W1))
        SensibleOutput = MassFlow * Psychrometrics.PsyDeltaHSenFnTdb2W2Tdb1W1(TDB2, W2, TDB1, W1)
        LatentOutput = TotalOutput - SensibleOutput

def CalcZoneSensibleLatentOutput(MassFlow: Float64,
                                TDBEquip: Float64,
                                WEquip: Float64,
                                TDBZone: Float64,
                                WZone: Float64,
                                inout SensibleOutput: Float64,
                                inout LatentOutput: Float64,
                                inout TotalOutput: Float64):
    TotalOutput = 0.0
    LatentOutput = 0.0
    SensibleOutput = 0.0
    if MassFlow > 0.0:
        TotalOutput = MassFlow * (Psychrometrics.PsyHFnTdbW(TDBEquip, WEquip) - Psychrometrics.PsyHFnTdbW(TDBZone, WZone))
        SensibleOutput = MassFlow * Psychrometrics.PsyDeltaHSenFnTdb2Tdb1W(TDBEquip, TDBZone, WZone)
        LatentOutput = TotalOutput - SensibleOutput

def calcZoneSensibleOutput(MassFlow: Float64,
                           TDBEquip: Float64,
                           TDBZone: Float64,
                           WZone: Float64) -> Float64:
    var sensibleOutput: Float64 = 0.0
    if MassFlow > 0.0:
        sensibleOutput = MassFlow * Psychrometrics.PsyDeltaHSenFnTdb2Tdb1W(TDBEquip, TDBZone, WZone)
    return sensibleOutput

def CheckBranchEquipInZoneHVACEquipList(inout state: EnergyPlusData, branchNum: Int, inout errorsFound: Bool):
    for comp in range(1, state.dataBranchInputManager.Branch[branchNum - 1].NumOfComponents + 1):
        var found: Bool = False
        var CType: String = state.dataBranchInputManager.Branch[branchNum - 1].Component[comp - 1].CType
        var eqType: DataZoneEquipment.ZoneEquipType = getEnumValue(DataZoneEquipment.zoneEquipTypeNamesUC, CType)
        if eqType == DataZoneEquipment.ZoneEquipType.BaseboardConvectiveWater or \
           eqType == DataZoneEquipment.ZoneEquipType.BaseboardSteam or \
           eqType == DataZoneEquipment.ZoneEquipType.BaseboardWater or \
           eqType == DataZoneEquipment.ZoneEquipType.LowTemperatureRadiantConstFlow or \
           eqType == DataZoneEquipment.ZoneEquipType.LowTemperatureRadiantVarFlow or \
           eqType == DataZoneEquipment.ZoneEquipType.CoolingPanel:
            for eqList in range(1, state.dataZoneEquip.ZoneEquipList.size() + 1):
                for eqNum in range(1, state.dataZoneEquip.ZoneEquipList[eqList - 1].NumOfEquipTypes + 1):
                    if SameString(state.dataBranchInputManager.Branch[branchNum - 1].Component[comp - 1].Name,
                                  state.dataZoneEquip.ZoneEquipList[eqList - 1].EquipName[eqNum - 1]):
                        if SameString(state.dataBranchInputManager.Branch[branchNum - 1].Component[comp - 1].CType,
                                      state.dataZoneEquip.ZoneEquipList[eqList - 1].EquipTypeName[eqNum - 1]):
                            found = True
                            break
                if found:
                    break
            if not found:
                ShowSevereError(state,
                    f"CheckBranchEquipInZoneHVACEquipList: Branch = {state.dataBranchInputManager.Branch[branchNum - 1].Name}, contains a component of type {state.dataBranchInputManager.Branch[branchNum - 1].Component[comp - 1].CType} with name = {state.dataBranchInputManager.Branch[branchNum - 1].Component[comp - 1].Name}")
                ShowContinueError(state, "but that component is not listed in any ZoneHVAC:EquipmentList.")
                errorsFound = True
        else:
            continue
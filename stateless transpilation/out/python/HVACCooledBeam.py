from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, Protocol, List, Any
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state parameter) - from EnergyPlus/Data/EnergyPlusData.hh
# - Psychrometrics module (PsyCpAirFnW) - from EnergyPlus/Psychrometrics.hh
# - HVAC module constants (SmallAirVolFlow, SmallLoad, SmallMassFlow, SmallWaterVolFlow) - from EnergyPlus/DataHVACGlobals.hh
# - Node module (GetOnlySingleNode, TestCompSet) - from EnergyPlus/NodeInputManager.hh
# - Utilities (ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowSevereItemNotFound) - from EnergyPlus/UtilityRoutines.hh
# - DataSizing module (CheckZoneSizing, CheckZoneEquipmentList) - from EnergyPlus/DataSizing.hh
# - PlantUtilities (ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, RegisterPlantCompDesignFlow, MyPlantSizingIndex, SafeCopyPlantNode) - from EnergyPlus/PlantUtilities.hh
# - General::SolveRoot - from EnergyPlus/General.hh
# - OutputProcessor (SetupOutputVariable) - from EnergyPlus/OutputProcessor.hh
# - OutputReportPredefined (PreDefTableEntry) - from EnergyPlus/OutputReportPredefined.hh
# - BaseSizer (reportSizerOutput, calcCoilWaterFlowRates) - from EnergyPlus/Autosizing/Base.hh
# - Schedule functions (GetScheduleAlwaysOn, GetSchedule) - from EnergyPlus/ScheduleManager.hh
# - Util functions (SameString, FindItemInList) - from EnergyPlus/UtilityRoutines.hh
# - Constants (Pi, AutoSize, AutoCalculate, CWInitConvTemp) - from EnergyPlus/DataGlobals.hh
# - ErrorObjectHeader - from EnergyPlus/InputProcessing/InputProcessor.hh


class CooledBeamType(IntEnum):
    Invalid = -1
    Passive = 0
    Active = 1
    Num = 2


NOM_MASS_FLOW_PER_BEAM = 0.07
MIN_WATER_VEL = 0.2
COEFF2 = 10000.0


class Schedule(Protocol):
    def getCurrentVal(self) -> float: ...


@dataclass
class CoolBeamData:
    Name: str = ""
    UnitType: str = ""
    UnitType_Num: int = 0
    CBTypeString: str = ""
    CBType: CooledBeamType = CooledBeamType.Invalid
    availSched: Optional[Any] = None
    MaxAirVolFlow: float = 0.0
    MaxAirMassFlow: float = 0.0
    MaxCoolWaterVolFlow: float = 0.0
    MaxCoolWaterMassFlow: float = 0.0
    AirInNode: int = 0
    AirOutNode: int = 0
    CWInNode: int = 0
    CWOutNode: int = 0
    ADUNum: int = 0
    NumBeams: float = 0.0
    BeamLength: float = 0.0
    DesInletWaterTemp: float = 0.0
    DesOutletWaterTemp: float = 0.0
    CoilArea: float = 0.0
    a: float = 0.0
    n1: float = 0.0
    n2: float = 0.0
    n3: float = 0.0
    a0: float = 0.0
    K1: float = 0.0
    n: float = 0.0
    Kin: float = 0.0
    InDiam: float = 0.0
    TWIn: float = 0.0
    TWOut: float = 0.0
    EnthWaterOut: float = 0.0
    BeamFlow: float = 0.0
    CoolWaterMassFlow: float = 0.0
    BeamCoolingEnergy: float = 0.0
    BeamCoolingRate: float = 0.0
    SupAirCoolingEnergy: float = 0.0
    SupAirCoolingRate: float = 0.0
    SupAirHeatingEnergy: float = 0.0
    SupAirHeatingRate: float = 0.0
    CWPlantLoc: Any = field(default_factory=dict)
    CBLoadReSimIndex: int = 0
    CBMassFlowReSimIndex: int = 0
    CBWaterOutletTempReSimIndex: int = 0
    CtrlZoneNum: int = 0
    ctrlZoneInNodeIndex: int = 0
    AirLoopNum: int = 0
    OutdoorAirFlowRate: float = 0.0
    MyEnvrnFlag: bool = True
    MySizeFlag: bool = True
    PlantLoopScanFlag: bool = True

    def CalcOutdoorAirVolumeFlowRate(self, state: Any) -> None:
        if self.AirLoopNum > 0:
            self.OutdoorAirFlowRate = (state.dataLoopNodes.Node[self.AirOutNode - 1].MassFlowRate / state.dataEnvrn.StdRhoAir) * state.dataAirLoop.AirLoopFlow[self.AirLoopNum - 1].OAFrac
        else:
            self.OutdoorAirFlowRate = 0.0

    def reportTerminalUnit(self, state: Any) -> None:
        orp = state.dataOutRptPredefined
        adu = state.dataDefineEquipment.AirDistUnit[self.ADUNum - 1]
        if state.dataSize.TermUnitFinalZoneSizing:
            sizing = state.dataSize.TermUnitFinalZoneSizing[adu.TermUnitSizingNum - 1]
            state.outproc.PreDefTableEntry(orp.pdchAirTermMinFlow, adu.Name, sizing.DesCoolVolFlowMin)
            state.outproc.PreDefTableEntry(orp.pdchAirTermMinOutdoorFlow, adu.Name, sizing.MinOA)
            state.outproc.PreDefTableEntry(orp.pdchAirTermSupCoolingSP, adu.Name, sizing.CoolDesTemp)
            state.outproc.PreDefTableEntry(orp.pdchAirTermSupHeatingSP, adu.Name, sizing.HeatDesTemp)
            state.outproc.PreDefTableEntry(orp.pdchAirTermHeatingCap, adu.Name, sizing.DesHeatLoad)
            state.outproc.PreDefTableEntry(orp.pdchAirTermCoolingCap, adu.Name, sizing.DesCoolLoad)
        state.outproc.PreDefTableEntry(orp.pdchAirTermTypeInp, adu.Name, self.UnitType)
        state.outproc.PreDefTableEntry(orp.pdchAirTermPrimFlow, adu.Name, self.MaxAirVolFlow)
        state.outproc.PreDefTableEntry(orp.pdchAirTermSecdFlow, adu.Name, "n/a")
        state.outproc.PreDefTableEntry(orp.pdchAirTermMinFlowSch, adu.Name, "n/a")
        state.outproc.PreDefTableEntry(orp.pdchAirTermMaxFlowReh, adu.Name, "n/a")
        state.outproc.PreDefTableEntry(orp.pdchAirTermMinOAflowSch, adu.Name, "n/a")
        state.outproc.PreDefTableEntry(orp.pdchAirTermHeatCoilType, adu.Name, "n/a")
        state.outproc.PreDefTableEntry(orp.pdchAirTermCoolCoilType, adu.Name, self.CBTypeString)
        state.outproc.PreDefTableEntry(orp.pdchAirTermFanType, adu.Name, "n/a")
        state.outproc.PreDefTableEntry(orp.pdchAirTermFanName, adu.Name, "n/a")


@dataclass
class HVACCooledBeamData:
    CheckEquipName: List[bool] = field(default_factory=list)
    NumCB: int = 0
    CoolBeam: List[CoolBeamData] = field(default_factory=list)
    GetInputFlag: bool = True
    ZoneEquipmentListChecked: bool = False

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.CheckEquipName.clear()
        self.NumCB = 0
        self.CoolBeam.clear()
        self.GetInputFlag = True
        self.ZoneEquipmentListChecked = False


def SimCoolBeam(
    state: Any,
    CompName: str,
    FirstHVACIteration: bool,
    ZoneNum: int,
    ZoneNodeNum: int,
    CompIndex: int,
) -> tuple[int, float]:
    NonAirSysOutput = 0.0

    if state.dataHVACCooledBeam.GetInputFlag:
        GetCoolBeams(state)
        state.dataHVACCooledBeam.GetInputFlag = False

    if CompIndex == 0:
        CBNum = state.util.FindItemInList(CompName, state.dataHVACCooledBeam.CoolBeam)
        if CBNum == 0:
            state.util.ShowFatalError(f"SimCoolBeam: Cool Beam Unit not found={CompName}")
        CompIndex = CBNum
    else:
        CBNum = CompIndex
        if CBNum > state.dataHVACCooledBeam.NumCB or CBNum < 1:
            state.util.ShowFatalError(
                f"SimCoolBeam: Invalid CompIndex passed={CompIndex}, Number of Cool Beam Units={state.dataHVACCooledBeam.NumCB}, System name={CompName}"
            )
        if state.dataHVACCooledBeam.CheckEquipName[CBNum - 1]:
            if CompName != state.dataHVACCooledBeam.CoolBeam[CBNum - 1].Name:
                state.util.ShowFatalError(
                    f"SimCoolBeam: Invalid CompIndex passed={CompIndex}, Cool Beam Unit name={CompName}, stored Cool Beam Unit for that index={state.dataHVACCooledBeam.CoolBeam[CBNum - 1].Name}"
                )
            state.dataHVACCooledBeam.CheckEquipName[CBNum - 1] = False

    if CBNum == 0:
        state.util.ShowFatalError(f"Cool Beam Unit not found = {CompName}")

    state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[
        state.dataHVACCooledBeam.CoolBeam[CBNum - 1].ADUNum - 1
    ].TermUnitSizingNum

    InitCoolBeam(state, CBNum, FirstHVACIteration)
    NonAirSysOutput = ControlCoolBeam(state, CBNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    UpdateCoolBeam(state, CBNum)
    ReportCoolBeam(state, CBNum)

    return CompIndex, NonAirSysOutput


def GetCoolBeams(state: Any) -> None:
    RoutineName = "GetCoolBeams "
    routineName = "GetCoolBeams"

    CurrentModuleObject = "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
    NumCB = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACCooledBeam.NumCB = NumCB

    state.dataHVACCooledBeam.CoolBeam = [CoolBeamData() for _ in range(NumCB)]
    state.dataHVACCooledBeam.CheckEquipName = [True] * NumCB

    TotalArgs = 23
    NumAlphas = 7
    NumNumbers = 16

    ErrorsFound = False

    for CBIndex in range(NumCB):
        Alphas, Numbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields = (
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, CurrentModuleObject, CBIndex + 1
            )
        )

        eoh = (routineName, CurrentModuleObject, Alphas[0])
        CBNum = CBIndex + 1

        CoolBeam = state.dataHVACCooledBeam.CoolBeam[CBIndex]
        CoolBeam.Name = Alphas[0]
        CoolBeam.UnitType = CurrentModuleObject
        CoolBeam.UnitType_Num = 1
        CoolBeam.CBTypeString = Alphas[2]

        if state.util.SameString(CoolBeam.CBTypeString, "Passive"):
            CoolBeam.CBType = CooledBeamType.Passive
        elif state.util.SameString(CoolBeam.CBTypeString, "Active"):
            CoolBeam.CBType = CooledBeamType.Active
        else:
            state.util.ShowSevereError(state, f"Illegal {cAlphaFields[2]} = {CoolBeam.CBTypeString}.")
            state.util.ShowContinueError(state, f"Occurs in {CurrentModuleObject} = {CoolBeam.Name}")
            ErrorsFound = True

        if not lAlphaBlanks[1]:
            CoolBeam.availSched = state.schedul.GetSchedule(state, Alphas[1])
            if CoolBeam.availSched is None:
                state.util.ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                ErrorsFound = True
        else:
            CoolBeam.availSched = state.schedul.GetScheduleAlwaysOn(state)

        CoolBeam.AirInNode = state.node.GetOnlySingleNode(
            state, Alphas[3], ErrorsFound, "AirTerminalSingleDuctConstantVolumeCooledBeam", Alphas[0], cAlphaFields[3]
        )
        CoolBeam.AirOutNode = state.node.GetOnlySingleNode(
            state, Alphas[4], ErrorsFound, "AirTerminalSingleDuctConstantVolumeCooledBeam", Alphas[0], cAlphaFields[4]
        )
        CoolBeam.CWInNode = state.node.GetOnlySingleNode(
            state, Alphas[5], ErrorsFound, "AirTerminalSingleDuctConstantVolumeCooledBeam", Alphas[0], cAlphaFields[5]
        )
        CoolBeam.CWOutNode = state.node.GetOnlySingleNode(
            state, Alphas[6], ErrorsFound, "AirTerminalSingleDuctConstantVolumeCooledBeam", Alphas[0], cAlphaFields[6]
        )

        CoolBeam.MaxAirVolFlow = Numbers[0]
        CoolBeam.MaxCoolWaterVolFlow = Numbers[1]
        CoolBeam.NumBeams = Numbers[2]
        CoolBeam.BeamLength = Numbers[3]
        CoolBeam.DesInletWaterTemp = Numbers[4]
        CoolBeam.DesOutletWaterTemp = Numbers[5]
        CoolBeam.CoilArea = Numbers[6]
        CoolBeam.a = Numbers[7]
        CoolBeam.n1 = Numbers[8]
        CoolBeam.n2 = Numbers[9]
        CoolBeam.n3 = Numbers[10]
        CoolBeam.a0 = Numbers[11]
        CoolBeam.K1 = Numbers[12]
        CoolBeam.n = Numbers[13]
        CoolBeam.Kin = Numbers[14]
        CoolBeam.InDiam = Numbers[15]

        state.node.TestCompSet(
            state,
            CurrentModuleObject,
            CoolBeam.Name,
            state.dataLoopNodes.NodeID[CoolBeam.AirInNode - 1],
            state.dataLoopNodes.NodeID[CoolBeam.AirOutNode - 1],
            "Air Nodes",
        )
        state.node.TestCompSet(
            state,
            CurrentModuleObject,
            CoolBeam.Name,
            state.dataLoopNodes.NodeID[CoolBeam.CWInNode - 1],
            state.dataLoopNodes.NodeID[CoolBeam.CWOutNode - 1],
            "Water Nodes",
        )

        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Beam Sensible Cooling Energy",
            CoolBeam.BeamCoolingEnergy,
            CoolBeam.Name,
        )
        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Beam Chilled Water Energy",
            CoolBeam.BeamCoolingEnergy,
            CoolBeam.Name,
        )
        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Beam Sensible Cooling Rate",
            CoolBeam.BeamCoolingRate,
            CoolBeam.Name,
        )
        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Supply Air Sensible Cooling Energy",
            CoolBeam.SupAirCoolingEnergy,
            CoolBeam.Name,
        )
        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Supply Air Sensible Cooling Rate",
            CoolBeam.SupAirCoolingRate,
            CoolBeam.Name,
        )
        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Supply Air Sensible Heating Energy",
            CoolBeam.SupAirHeatingEnergy,
            CoolBeam.Name,
        )
        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Supply Air Sensible Heating Rate",
            CoolBeam.SupAirHeatingRate,
            CoolBeam.Name,
        )
        state.outproc.SetupOutputVariable(
            state,
            "Zone Air Terminal Outdoor Air Volume Flow Rate",
            CoolBeam.OutdoorAirFlowRate,
            CoolBeam.Name,
        )

        ADUNum = 0
        for i in range(len(state.dataDefineEquipment.AirDistUnit)):
            if CoolBeam.AirOutNode == state.dataDefineEquipment.AirDistUnit[i].OutletNodeNum:
                CoolBeam.ADUNum = i + 1
                state.dataDefineEquipment.AirDistUnit[i].InletNodeNum = CoolBeam.AirInNode
                break

        if CoolBeam.ADUNum == 0:
            state.util.ShowSevereError(
                state,
                f"{RoutineName}No matching Air Distribution Unit, for Unit = [{CurrentModuleObject},{CoolBeam.Name}].",
            )
            state.util.ShowContinueError(
                state, f"...should have outlet node={state.dataLoopNodes.NodeID[CoolBeam.AirOutNode - 1]}"
            )
            ErrorsFound = True
        else:
            AirNodeFound = False
            for CtrlZone in range(state.dataGlobal.NumOfZones):
                if not state.dataZoneEquip.ZoneEquipConfig[CtrlZone].IsControlled:
                    continue
                for SupAirIn in range(state.dataZoneEquip.ZoneEquipConfig[CtrlZone].NumInletNodes):
                    if CoolBeam.AirOutNode == state.dataZoneEquip.ZoneEquipConfig[CtrlZone].InletNode[SupAirIn]:
                        state.dataZoneEquip.ZoneEquipConfig[CtrlZone].AirDistUnitCool[SupAirIn].InNode = CoolBeam.AirInNode
                        state.dataZoneEquip.ZoneEquipConfig[CtrlZone].AirDistUnitCool[SupAirIn].OutNode = CoolBeam.AirOutNode
                        state.dataDefineEquipment.AirDistUnit[CoolBeam.ADUNum - 1].TermUnitSizingNum = (
                            state.dataZoneEquip.ZoneEquipConfig[CtrlZone].AirDistUnitCool[SupAirIn].TermUnitSizingIndex
                        )
                        state.dataDefineEquipment.AirDistUnit[CoolBeam.ADUNum - 1].ZoneEqNum = CtrlZone + 1
                        CoolBeam.CtrlZoneNum = CtrlZone + 1
                        CoolBeam.ctrlZoneInNodeIndex = SupAirIn + 1
                        AirNodeFound = True
                        break
                if AirNodeFound:
                    break

            if not AirNodeFound:
                state.util.ShowSevereError(state, f"The outlet air node from the {CurrentModuleObject} = {CoolBeam.Name}")
                state.util.ShowContinueError(state, f"did not have a matching Zone Equipment Inlet Node, Node ={Alphas[4]}")
                ErrorsFound = True

    if ErrorsFound:
        state.util.ShowFatalError(state, f"{RoutineName}Errors found in getting input. Preceding conditions cause termination.")


def InitCoolBeam(state: Any, CBNum: int, FirstHVACIteration: bool) -> None:
    RoutineName = "InitCoolBeam"

    coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum - 1]
    ZoneEquipmentListChecked = state.dataHVACCooledBeam.ZoneEquipmentListChecked
    NumCB = state.dataHVACCooledBeam.NumCB

    if coolBeam.PlantLoopScanFlag and state.dataPlnt.PlantLoop:
        errFlag = False
        state.plant.ScanPlantLoopsForObject(
            state,
            coolBeam.Name,
            "CooledBeamAirTerminal",
            coolBeam.CWPlantLoc,
            errFlag,
        )
        if errFlag:
            state.util.ShowFatalError(state, "InitCoolBeam: Program terminated for previous conditions.")
        coolBeam.PlantLoopScanFlag = False

    if not ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        CurrentModuleObject = "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
        state.dataHVACCooledBeam.ZoneEquipmentListChecked = True
        for Loop in range(NumCB):
            if state.dataHVACCooledBeam.CoolBeam[Loop].ADUNum == 0:
                continue
            if state.zoneequip.CheckZoneEquipmentList(
                state, "ZONEHVAC:AIRDISTRIBUTIONUNIT", state.dataDefineEquipment.AirDistUnit[state.dataHVACCooledBeam.CoolBeam[Loop].ADUNum - 1].Name
            ):
                continue
            state.util.ShowSevereError(
                state,
                f"InitCoolBeam: ADU=[Air Distribution Unit,{state.dataDefineEquipment.AirDistUnit[state.dataHVACCooledBeam.CoolBeam[Loop].ADUNum - 1].Name}] is not on any ZoneHVAC:EquipmentList.",
            )
            state.util.ShowContinueError(
                state, f"...Unit=[{CurrentModuleObject},{state.dataHVACCooledBeam.CoolBeam[Loop].Name}] will not be simulated."
            )

    if not state.dataGlobal.SysSizingCalc and coolBeam.MySizeFlag and not coolBeam.PlantLoopScanFlag:
        SizeCoolBeam(state, CBNum)

        InWaterNode = coolBeam.CWInNode
        OutWaterNode = coolBeam.CWOutNode
        rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, 10.0, RoutineName)
        coolBeam.MaxCoolWaterMassFlow = rho * coolBeam.MaxCoolWaterVolFlow
        state.plant.InitComponentNodes(state, 0.0, coolBeam.MaxCoolWaterMassFlow, InWaterNode, OutWaterNode)
        coolBeam.MySizeFlag = False

    if state.dataGlobal.BeginEnvrnFlag and coolBeam.MyEnvrnFlag:
        RhoAir = state.dataEnvrn.StdRhoAir
        InAirNode = coolBeam.AirInNode
        OutAirNode = coolBeam.AirOutNode
        coolBeam.MaxAirMassFlow = RhoAir * coolBeam.MaxAirVolFlow
        state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMax = coolBeam.MaxAirMassFlow
        state.dataLoopNodes.Node[OutAirNode - 1].MassFlowRateMax = coolBeam.MaxAirMassFlow
        state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMin = 0.0
        state.dataLoopNodes.Node[OutAirNode - 1].MassFlowRateMin = 0.0

        InWaterNode = coolBeam.CWInNode
        OutWaterNode = coolBeam.CWOutNode
        state.plant.InitComponentNodes(state, 0.0, coolBeam.MaxCoolWaterMassFlow, InWaterNode, OutWaterNode)

        if coolBeam.AirLoopNum == 0:
            if coolBeam.CtrlZoneNum > 0 and coolBeam.ctrlZoneInNodeIndex > 0:
                coolBeam.AirLoopNum = state.dataZoneEquip.ZoneEquipConfig[coolBeam.CtrlZoneNum - 1].InletNodeAirLoopNum[
                    coolBeam.ctrlZoneInNodeIndex - 1
                ]
                state.dataDefineEquipment.AirDistUnit[coolBeam.ADUNum - 1].AirLoopNum = coolBeam.AirLoopNum

        coolBeam.MyEnvrnFlag = False

    if not state.dataGlobal.BeginEnvrnFlag:
        coolBeam.MyEnvrnFlag = True

    InAirNode = coolBeam.AirInNode
    OutAirNode = coolBeam.AirOutNode

    if FirstHVACIteration:
        if coolBeam.availSched.getCurrentVal() > 0.0 and state.dataLoopNodes.Node[InAirNode - 1].MassFlowRate > 0.0:
            state.dataLoopNodes.Node[InAirNode - 1].MassFlowRate = coolBeam.MaxAirMassFlow
        else:
            state.dataLoopNodes.Node[InAirNode - 1].MassFlowRate = 0.0

        if coolBeam.availSched.getCurrentVal() > 0.0 and state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMaxAvail > 0.0:
            state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMaxAvail = coolBeam.MaxAirMassFlow
            state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMinAvail = coolBeam.MaxAirMassFlow
        else:
            state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMaxAvail = 0.0
            state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMinAvail = 0.0

    InWaterNode = coolBeam.CWInNode
    coolBeam.TWIn = state.dataLoopNodes.Node[InWaterNode - 1].Temp
    coolBeam.SupAirCoolingRate = 0.0
    coolBeam.SupAirHeatingRate = 0.0


def SizeCoolBeam(state: Any, CBNum: int) -> None:
    RoutineName = "SizeCoolBeam"

    PltSizCoolNum = 0
    DesAirVolFlow = 0.0
    CpAir = 0.0
    RhoAir = state.dataEnvrn.StdRhoAir
    ErrorsFound = False

    coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum - 1]

    if coolBeam.MaxAirVolFlow == -99999.0 or coolBeam.BeamLength == -99999.0:
        PltSizCoolNum = state.plant.MyPlantSizingIndex(state, "cooled beam unit", coolBeam.Name, coolBeam.CWInNode, coolBeam.CWOutNode, ErrorsFound)

    if coolBeam.Kin == -99999.0:
        if coolBeam.CBType == CooledBeamType.Passive:
            coolBeam.Kin = 0.0
        else:
            coolBeam.Kin = 2.0
        state.autosizing.BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Coefficient of Induction Kin", coolBeam.Kin)

    if coolBeam.MaxAirVolFlow == -99999.0:
        if state.dataSize.CurTermUnitSizingNum > 0:
            state.sizing.CheckZoneSizing(state, coolBeam.UnitType, coolBeam.Name)
            coolBeam.MaxAirVolFlow = max(
                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolVolFlow,
                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatVolFlow,
            )
            if coolBeam.MaxAirVolFlow < 0.01:
                coolBeam.MaxAirVolFlow = 0.0
            state.autosizing.BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Supply Air Flow Rate [m3/s]", coolBeam.MaxAirVolFlow)

    if coolBeam.MaxCoolWaterVolFlow == -99999.0:
        if (state.dataSize.CurZoneEqNum > 0) and (state.dataSize.CurTermUnitSizingNum > 0):
            state.sizing.CheckZoneSizing(state, coolBeam.UnitType, coolBeam.Name)

            if PltSizCoolNum > 0:
                if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolMassFlow >= 0.01:
                    DesAirVolFlow = coolBeam.MaxAirVolFlow
                    CpAir = state.psych.PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].CoolDesHumRat)

                    if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtCoolPeak > 0.0:
                        DesCoilLoad = (
                            state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].NonAirSysDesCoolLoad
                            - CpAir
                            * RhoAir
                            * DesAirVolFlow
                            * (
                                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtCoolPeak
                                - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolCoilInTempTU
                            )
                        )
                    else:
                        DesCoilLoad = (
                            CpAir
                            * RhoAir
                            * DesAirVolFlow
                            * (
                                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolCoilInTempTU
                                - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneSizThermSetPtHi
                            )
                        )

                    rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, 10.0, RoutineName)
                    Cp = coolBeam.CWPlantLoc.loop.glycol.getSpecificHeat(state, 10.0, RoutineName)

                    coolBeam.MaxCoolWaterVolFlow = DesCoilLoad / ((coolBeam.DesOutletWaterTemp - coolBeam.DesInletWaterTemp) * Cp * rho)
                    coolBeam.MaxCoolWaterVolFlow = max(coolBeam.MaxCoolWaterVolFlow, 0.0)
                    if coolBeam.MaxCoolWaterVolFlow < 0.0001:
                        coolBeam.MaxCoolWaterVolFlow = 0.0
                else:
                    coolBeam.MaxCoolWaterVolFlow = 0.0

                state.autosizing.BaseSizer.reportSizerOutput(
                    state, coolBeam.UnitType, coolBeam.Name, "Maximum Total Chilled Water Flow Rate [m3/s]", coolBeam.MaxCoolWaterVolFlow
                )
            else:
                state.util.ShowSevereError(state, "Autosizing of water flow requires a cooling loop Sizing:Plant object")
                state.util.ShowContinueError(state, f"Occurs in{coolBeam.UnitType} Object={coolBeam.Name}")
                ErrorsFound = True

    state.autosizing.BaseSizer.calcCoilWaterFlowRates(
        state,
        coolBeam.Name,
        coolBeam.UnitType,
        coolBeam.MaxCoolWaterVolFlow,
        coolBeam.CWPlantLoc.loopNum,
        state.dataSize.CurZoneEqNum,
        state.dataSize.CurSysNum,
        state.dataSize.CurOASysNum,
        state.dataSize.FinalZoneSizing,
        state.dataSize.FinalSysSizing,
    )

    if coolBeam.NumBeams == -99999.0:
        rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, 10.0, RoutineName)
        NumBeams = int(coolBeam.MaxCoolWaterVolFlow * rho / NOM_MASS_FLOW_PER_BEAM) + 1
        coolBeam.NumBeams = float(NumBeams)
        state.autosizing.BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Number of Beams", coolBeam.NumBeams)

    if coolBeam.BeamLength == -99999.0:
        if state.dataSize.CurTermUnitSizingNum > 0:
            state.sizing.CheckZoneSizing(state, coolBeam.UnitType, coolBeam.Name)

            if PltSizCoolNum > 0:
                rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, 10.0, RoutineName)
                Cp = coolBeam.CWPlantLoc.loop.glycol.getSpecificHeat(state, 10.0, RoutineName)
                DesCoilLoad = coolBeam.MaxCoolWaterVolFlow * (coolBeam.DesOutletWaterTemp - coolBeam.DesInletWaterTemp) * Cp * rho
                if DesCoilLoad > 0.0:
                    NumBeams = int(coolBeam.NumBeams)
                    DesLoadPerBeam = DesCoilLoad / NumBeams
                    DesAirFlowPerBeam = coolBeam.MaxAirVolFlow / NumBeams
                    WaterVolFlowPerBeam = coolBeam.MaxCoolWaterVolFlow / NumBeams
                    WaterVel = WaterVolFlowPerBeam / (3.14159265359 * (coolBeam.InDiam ** 2) / 4.0)
                    if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtCoolPeak > 0.0:
                        DT = (
                            state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtCoolPeak
                            - 0.5 * (coolBeam.DesInletWaterTemp + coolBeam.DesOutletWaterTemp)
                        )
                        if DT <= 0.0:
                            DT = 7.8
                    else:
                        DT = 7.8
                    LengthX = 1.0
                    for Iter in range(100):
                        IndAirFlowPerBeamL = coolBeam.K1 * (DT ** coolBeam.n) + coolBeam.Kin * DesAirFlowPerBeam / LengthX
                        ConvFlow = (IndAirFlowPerBeamL / coolBeam.a0) * RhoAir
                        if WaterVel > MIN_WATER_VEL:
                            K = (
                                coolBeam.a
                                * (DT ** coolBeam.n1)
                                * (ConvFlow ** coolBeam.n2)
                                * (WaterVel ** coolBeam.n3)
                            )
                        else:
                            K = (
                                coolBeam.a
                                * (DT ** coolBeam.n1)
                                * (ConvFlow ** coolBeam.n2)
                                * (MIN_WATER_VEL ** coolBeam.n3)
                                * (WaterVel / MIN_WATER_VEL)
                            )
                        Length = DesLoadPerBeam / (K * coolBeam.CoilArea * DT)
                        if coolBeam.Kin <= 0.0:
                            break
                        if abs(Length - LengthX) > 0.01:
                            LengthX += 0.5 * (Length - LengthX)
                        else:
                            break
                else:
                    Length = 0.0
                coolBeam.BeamLength = Length
                coolBeam.BeamLength = max(coolBeam.BeamLength, 1.0)
                state.autosizing.BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Beam Length [m]", coolBeam.BeamLength)
            else:
                state.util.ShowSevereError(state, "Autosizing of cooled beam length requires a cooling loop Sizing:Plant object")
                state.util.ShowContinueError(state, f"Occurs in{coolBeam.UnitType} Object={coolBeam.Name}")
                ErrorsFound = True

    if coolBeam.MaxCoolWaterVolFlow > 0.0:
        state.plant.RegisterPlantCompDesignFlow(state, coolBeam.CWInNode, coolBeam.MaxCoolWaterVolFlow)

    if ErrorsFound:
        state.util.ShowFatalError(state, "Preceding cooled beam sizing errors cause program termination")


def ControlCoolBeam(
    state: Any, CBNum: int, ZoneNum: int, ZoneNodeNum: int, FirstHVACIteration: bool
) -> float:
    SmallLoad = 0.01
    SmallMassFlow = 0.001

    NonAirSysOutput = 0.0
    QMin = 0.0
    QMax = 0.0
    QSup = 0.0
    PowerMet = 0.0
    CWFlow = 0.0
    AirMassFlow = 0.0
    MaxColdWaterFlow = 0.0
    MinColdWaterFlow = 0.0
    CpAirZn = 0.0
    CpAirSys = 0.0
    TWOut = 0.0

    coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum - 1]

    UnitOn = True
    PowerMet = 0.0
    InAirNode = coolBeam.AirInNode
    ControlNode = coolBeam.CWInNode
    AirMassFlow = state.dataLoopNodes.Node[InAirNode - 1].MassFlowRateMaxAvail
    QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputRequired
    QToHeatSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToHeatSP
    QToCoolSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToCoolSP
    CpAirZn = state.psych.PsyCpAirFnW(state.dataLoopNodes.Node[ZoneNodeNum - 1].HumRat)
    CpAirSys = state.psych.PsyCpAirFnW(state.dataLoopNodes.Node[InAirNode - 1].HumRat)
    MaxColdWaterFlow = coolBeam.MaxCoolWaterMassFlow
    state.plant.SetComponentFlowRate(state, MaxColdWaterFlow, coolBeam.CWInNode, coolBeam.CWOutNode, coolBeam.CWPlantLoc)
    MinColdWaterFlow = 0.0
    state.plant.SetComponentFlowRate(state, MinColdWaterFlow, coolBeam.CWInNode, coolBeam.CWOutNode, coolBeam.CWPlantLoc)

    if coolBeam.availSched.getCurrentVal() <= 0.0:
        UnitOn = False
    if MaxColdWaterFlow <= SmallMassFlow:
        UnitOn = False

    state.dataLoopNodes.Node[InAirNode - 1].MassFlowRate = AirMassFlow
    coolBeam.BeamFlow = state.dataLoopNodes.Node[InAirNode - 1].MassFlowRate / (state.dataEnvrn.StdRhoAir * coolBeam.NumBeams)

    LoadMet, TWOut = CalcCoolBeam(state, CBNum, ZoneNodeNum, MinColdWaterFlow)
    QMin = LoadMet

    QSup = AirMassFlow * (CpAirSys * state.dataLoopNodes.Node[InAirNode - 1].Temp - CpAirZn * state.dataLoopNodes.Node[ZoneNodeNum - 1].Temp)

    if UnitOn:
        if (QToCoolSetPt - QSup) < -SmallLoad:
            LoadMet, TWOut = CalcCoolBeam(state, CBNum, ZoneNodeNum, MaxColdWaterFlow)
            QMax = LoadMet
            if (QMax < QToCoolSetPt - QSup - SmallLoad) and (QMax != QMin):
                ErrTolerance = 0.01

                def f(CWFlowTest):
                    par3 = QToCoolSetPt - QSup
                    LoadMetTest, TWOutTest = CalcCoolBeam(state, CBNum, ZoneNodeNum, CWFlowTest)
                    return (par3 - LoadMetTest) / (QMax - QMin)

                SolFlag = state.general.SolveRoot(state, ErrTolerance, 50, f, MinColdWaterFlow, MaxColdWaterFlow)
                if SolFlag == -1:
                    state.util.ShowWarningError(state, f"Cold water control failed in cooled beam unit {coolBeam.Name}")
                    state.util.ShowContinueError(state, "  Iteration limit exceeded in calculating cold water mass flow rate")
                    CWFlow = MaxColdWaterFlow
                elif SolFlag == -2:
                    state.util.ShowWarningError(state, f"Cold water control failed in cooled beam unit {coolBeam.Name}")
                    state.util.ShowContinueError(state, "  Bad cold water flow limits")
                    CWFlow = MaxColdWaterFlow
                else:
                    CWFlow = SolFlag
            else:
                CWFlow = MaxColdWaterFlow
        else:
            CWFlow = MinColdWaterFlow
    else:
        CWFlow = MinColdWaterFlow

    LoadMet, TWOut = CalcCoolBeam(state, CBNum, ZoneNodeNum, CWFlow)
    PowerMet = LoadMet
    coolBeam.BeamCoolingRate = -PowerMet
    if QSup < 0.0:
        coolBeam.SupAirCoolingRate = abs(QSup)
    else:
        coolBeam.SupAirHeatingRate = QSup
    coolBeam.CoolWaterMassFlow = state.dataLoopNodes.Node[ControlNode - 1].MassFlowRate
    coolBeam.TWOut = TWOut
    coolBeam.EnthWaterOut = state.dataLoopNodes.Node[ControlNode - 1].Enthalpy + coolBeam.BeamCoolingRate
    NonAirSysOutput = PowerMet

    return NonAirSysOutput


def CalcCoolBeam(state: Any, CBNum: int, ZoneNode: int, CWFlow: float) -> tuple[float, float]:
    RoutineName = "CalcCoolBeam"

    Iter = 0
    TWIn = 0.0
    ZTemp = 0.0
    WaterCoolPower = 0.0
    DT = 0.0
    IndFlow = 0.0
    CoilFlow = 0.0
    WaterVel = 0.0
    K = 0.0
    AirCoolPower = 0.0
    Diff = 0.0
    CWFlowPerBeam = 0.0
    Coeff = 0.0
    Delta = 0.0
    mdot = 0.0

    mdot = CWFlow
    coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum - 1]

    state.plant.SetComponentFlowRate(state, mdot, coolBeam.CWInNode, coolBeam.CWOutNode, coolBeam.CWPlantLoc)

    CWFlowPerBeam = mdot / coolBeam.NumBeams
    TWIn = coolBeam.TWIn

    Cp = coolBeam.CWPlantLoc.loop.glycol.getSpecificHeat(state, TWIn, RoutineName)
    rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, TWIn, RoutineName)

    TWOut = TWIn + 2.0
    ZTemp = state.dataLoopNodes.Node[ZoneNode - 1].Temp
    if mdot <= 0.0 or TWIn <= 0.0:
        LoadMet = 0.0
        TWOut = TWIn
        return LoadMet, TWOut

    for Iter in range(200):
        if Iter > 49 and Iter < 99:
            Coeff = 0.1 * COEFF2
        elif Iter > 99:
            Coeff = 0.01 * COEFF2
        else:
            Coeff = COEFF2

        WaterCoolPower = CWFlowPerBeam * Cp * (TWOut - TWIn)
        DT = max(ZTemp - 0.5 * (TWIn + TWOut), 0.0)
        IndFlow = coolBeam.K1 * (DT ** coolBeam.n) + coolBeam.Kin * coolBeam.BeamFlow / coolBeam.BeamLength
        CoilFlow = (IndFlow / coolBeam.a0) * state.dataEnvrn.StdRhoAir
        WaterVel = CWFlowPerBeam / (rho * 3.14159265359 * ((coolBeam.InDiam ** 2) / 4.0))
        if WaterVel > MIN_WATER_VEL:
            K = coolBeam.a * (DT ** coolBeam.n1) * (CoilFlow ** coolBeam.n2) * (WaterVel ** coolBeam.n3)
        else:
            K = (
                coolBeam.a
                * (DT ** coolBeam.n1)
                * (CoilFlow ** coolBeam.n2)
                * (MIN_WATER_VEL ** coolBeam.n3)
                * (WaterVel / MIN_WATER_VEL)
            )
        AirCoolPower = K * coolBeam.CoilArea * DT * coolBeam.BeamLength
        Diff = WaterCoolPower - AirCoolPower
        Delta = TWOut * (abs(Diff) / Coeff)
        if abs(Diff) > 0.1:
            if Diff < 0.0:
                TWOut += Delta
                if TWOut > ZTemp:
                    WaterCoolPower = 0.0
                    TWOut = ZTemp
                    break
            else:
                TWOut -= Delta
                if TWOut < TWIn:
                    TWOut = TWIn
        else:
            break

    LoadMet = -WaterCoolPower * coolBeam.NumBeams
    return LoadMet, TWOut


def UpdateCoolBeam(state: Any, CBNum: int) -> None:
    coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum - 1]
    airInletNode = state.dataLoopNodes.Node[coolBeam.AirInNode - 1]
    airOutletNode = state.dataLoopNodes.Node[coolBeam.AirOutNode - 1]

    airOutletNode.MassFlowRate = airInletNode.MassFlowRate
    airOutletNode.Temp = airInletNode.Temp
    airOutletNode.HumRat = airInletNode.HumRat
    airOutletNode.Enthalpy = airInletNode.Enthalpy

    state.plant.SafeCopyPlantNode(state, coolBeam.CWInNode, coolBeam.CWOutNode)

    state.dataLoopNodes.Node[coolBeam.CWOutNode - 1].Temp = coolBeam.TWOut
    state.dataLoopNodes.Node[coolBeam.CWOutNode - 1].Enthalpy = coolBeam.EnthWaterOut

    airOutletNode.Quality = airInletNode.Quality
    airOutletNode.Press = airInletNode.Press
    airOutletNode.MassFlowRateMin = airInletNode.MassFlowRateMin
    airOutletNode.MassFlowRateMax = airInletNode.MassFlowRateMax
    airOutletNode.MassFlowRateMinAvail = airInletNode.MassFlowRateMinAvail
    airOutletNode.MassFlowRateMaxAvail = airInletNode.MassFlowRateMaxAvail

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        airOutletNode.CO2 = airInletNode.CO2

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        airOutletNode.GenContam = airInletNode.GenContam


def ReportCoolBeam(state: Any, CBNum: int) -> None:
    coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum - 1]

    ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
    coolBeam.BeamCoolingEnergy = coolBeam.BeamCoolingRate * ReportingConstant
    coolBeam.SupAirCoolingEnergy = coolBeam.SupAirCoolingRate * ReportingConstant
    coolBeam.SupAirHeatingEnergy = coolBeam.SupAirHeatingRate * ReportingConstant

    coolBeam.CalcOutdoorAirVolumeFlowRate(state)

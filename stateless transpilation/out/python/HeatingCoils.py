# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state.dataHeatingCoils, state.dataInputProcessing, state.dataHeatBal, state.dataDXCoils,
#   state.dataVariableSpeedCoils, state.dataCoilCoolingDX, state.dataLoopNodes, state.dataEnvrn,
#   state.dataFaultsMgr, state.dataHVACGlobal, state.dataGlobal, state.dataAirLoop, state.dataSize, state.dataOutRptPredefined,
#   state.dataContaminantBalance, state.dataRefrigCase
# - HVAC: CoilType enum, FanOp enum, TempControlTol, coilTypeNames, coilTypeNamesUC, CtrlVarType
# - Constant: eFuel enum, Units enum, eResource enum, eResourceNames, eFuelNames, eFuelNamesUC, eFuel2eResource
# - Sched: Schedule class, GetScheduleAlwaysOn, GetSchedule functions
# - Node: SensedLoadFlagValue, SensedNodeFlagValue, ConnectionObjectType, FluidType, ConnectionType, 
#   CompFluidStream, ObjectIsNotParent, TestCompSet, functions
# - Util: FindItem, FindItemInList, SameString, makeUPPER
# - Curve: GetCurveIndex, CurveValue
# - Psychrometrics: PsyCpAirFnW, PsyHFnTdbW, PsyTdbFnHW, PsyRhFnTdbWPb, PsyTsatFnHPb, PsyWFnTdbH
# - DXCoils: GetDXCoilIndex, DXCoil class
# - VariableSpeedCoils: GetCoilIndexVariableSpeed, VarSpeedCoil class
# - CoilCoolingDX: factory function
# - GlobalNames: VerifyUniqueCoilName
# - ReportCoilSelection: getReportIndex, setCoilFinalSizes
# - BranchNodeConnections, EMSManager, FaultsManager, OutputProcessor, OutputReportPredefined, etc.

from dataclasses import dataclass, field
from typing import Optional, Protocol, Any, List
from enum import IntEnum
import math


class HeatObjTypes(IntEnum):
    Invalid = -1
    COMPRESSORRACK_REFRIGERATEDCASE = 0
    COIL_DX_COOLING = 1
    COIL_DX_MULTISPEED = 2
    COIL_DX_MULTIMODE = 3
    CONDENSER_REFRIGERATION = 4
    COIL_DX_VARIABLE_COOLING = 5
    COIL_COOLING_DX_NEW = 6
    Num = 7


MIN_AIR_MASS_FLOW = 0.001


@dataclass
class HeatingCoilEquipConditions:
    Name: str = ""
    HeatingCoilType: str = ""
    HeatingCoilModel: str = ""
    coilType: Any = None
    coilReportNum: int = -1
    FuelType: Any = None
    availSched: Optional[Any] = None
    InsuffTemperatureWarn: int = 0
    InletAirMassFlowRate: float = 0.0
    OutletAirMassFlowRate: float = 0.0
    InletAirTemp: float = 0.0
    OutletAirTemp: float = 0.0
    InletAirHumRat: float = 0.0
    OutletAirHumRat: float = 0.0
    InletAirEnthalpy: float = 0.0
    OutletAirEnthalpy: float = 0.0
    HeatingCoilLoad: float = 0.0
    HeatingCoilRate: float = 0.0
    FuelUseLoad: float = 0.0
    ElecUseLoad: float = 0.0
    FuelUseRate: float = 0.0
    ElecUseRate: float = 0.0
    Efficiency: float = 0.0
    NominalCapacity: float = 0.0
    DesiredOutletTemp: float = 0.0
    DesiredOutletHumRat: float = 0.0
    AvailTemperature: float = 0.0
    AirInletNodeNum: int = 0
    AirOutletNodeNum: int = 0
    TempSetPointNodeNum: int = 0
    Control: int = 0
    PLFCurveIndex: int = 0
    ParasiticElecLoad: float = 0.0
    ParasiticFuelConsumption: float = 0.0
    ParasiticFuelRate: float = 0.0
    ParasiticFuelCapacity: float = 0.0
    RTF: float = 0.0
    RTFErrorIndex: int = 0
    RTFErrorCount: int = 0
    PLFErrorIndex: int = 0
    PLFErrorCount: int = 0
    ReclaimHeatingCoilName: str = ""
    ReclaimHeatingSourceIndexNum: int = 0
    ReclaimHeatingSource: HeatObjTypes = HeatObjTypes.Invalid
    NumOfStages: int = 0
    MSNominalCapacity: List[float] = field(default_factory=list)
    MSEfficiency: List[float] = field(default_factory=list)
    MSParasiticElecLoad: List[float] = field(default_factory=list)
    DesiccantRegenerationCoil: bool = False
    DesiccantDehumNum: int = 0
    FaultyCoilSATFlag: bool = False
    FaultyCoilSATIndex: int = 0
    FaultyCoilSATOffset: float = 0.0
    reportCoilFinalSizes: bool = True
    AirLoopNum: int = 0


@dataclass
class HeatingCoilNumericFieldData:
    FieldNames: List[str] = field(default_factory=list)


def SimulateHeatingCoilComponents(
    state: Any,
    CompName: str,
    FirstHVACIteration: bool,
    QCoilReq: Optional[float] = None,
    CompIndex: Optional[int] = None,
    QCoilActual: Optional[List[float]] = None,
    SuppHeat: Optional[bool] = None,
    fanOp: Optional[Any] = None,
    PartLoadRatio: Optional[float] = None,
    StageNum: Optional[int] = None,
    SpeedRatio: Optional[float] = None,
) -> None:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    CoilNum = 0
    QCoilActual2 = 0.0
    fanOp_val = fanOp if fanOp is not None else None
    PartLoadFrac = PartLoadRatio if PartLoadRatio is not None else 1.0
    QCoilRequired = QCoilReq if QCoilReq is not None else state.Node.SensedLoadFlagValue

    if CompIndex is not None:
        if CompIndex == 0:
            CoilNum = Util.FindItemInList(CompName, state.dataHeatingCoils.HeatingCoil)
            if CoilNum == 0:
                state.ShowFatalError(f"SimulateHeatingCoilComponents: Coil not found={CompName}")
        else:
            CoilNum = CompIndex
            if CoilNum > state.dataHeatingCoils.NumHeatingCoils or CoilNum < 1:
                state.ShowFatalError(
                    f"SimulateHeatingCoilComponents: Invalid CompIndex passed={CoilNum}, "
                    f"Number of Heating Coils={state.dataHeatingCoils.NumHeatingCoils}, Coil name={CompName}"
                )
            if state.dataHeatingCoils.CheckEquipName[CoilNum - 1]:
                if CompName and CompName != state.dataHeatingCoils.HeatingCoil[CoilNum - 1].Name:
                    state.ShowFatalError(
                        f"SimulateHeatingCoilComponents: Invalid CompIndex passed={CoilNum}, "
                        f"Coil name={CompName}, stored Coil Name for that index={state.dataHeatingCoils.HeatingCoil[CoilNum - 1].Name}"
                    )
                state.dataHeatingCoils.CheckEquipName[CoilNum - 1] = False
    else:
        state.ShowSevereError("SimulateHeatingCoilComponents: CompIndex argument not used.")
        state.ShowContinueError(f"..CompName = {CompName}")
        state.ShowFatalError("Preceding conditions cause termination.")

    if SuppHeat is not None:
        state.dataHeatingCoils.CoilIsSuppHeater = SuppHeat
    else:
        state.dataHeatingCoils.CoilIsSuppHeater = False

    if fanOp is not None:
        fanOp_val = fanOp
    else:
        fanOp_val = state.HVAC.FanOp.Continuous

    if PartLoadRatio is not None:
        PartLoadFrac = PartLoadRatio
    else:
        PartLoadFrac = 1.0

    if QCoilReq is not None:
        QCoilRequired = QCoilReq
    else:
        QCoilRequired = state.Node.SensedLoadFlagValue

    InitHeatingCoil(state, CoilNum, FirstHVACIteration, QCoilRequired)

    coil_type = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].coilType
    if coil_type == state.HVAC.CoilType.HeatingElectric:
        CalcElectricHeatingCoil(state, CoilNum, QCoilRequired, fanOp_val, PartLoadFrac)
        QCoilActual2 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad
    elif coil_type == state.HVAC.CoilType.HeatingElectricMultiStage:
        CalcMultiStageElectricHeatingCoil(
            state, CoilNum, SpeedRatio or 0.0, PartLoadRatio or 0.0, StageNum or 1, fanOp_val, state.dataHeatingCoils.CoilIsSuppHeater
        )
        QCoilActual2 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad
    elif coil_type == state.HVAC.CoilType.HeatingGasOrOtherFuel:
        CalcFuelHeatingCoil(state, CoilNum, QCoilRequired, fanOp_val, PartLoadFrac)
        QCoilActual2 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad
    elif coil_type == state.HVAC.CoilType.HeatingGasMultiStage:
        CalcMultiStageGasHeatingCoil(state, CoilNum, SpeedRatio or 0.0, PartLoadRatio or 0.0, StageNum or 1, fanOp_val)
        QCoilActual2 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad
    elif coil_type == state.HVAC.CoilType.HeatingDesuperheater:
        CalcDesuperheaterHeatingCoil(state, CoilNum, QCoilRequired)
        QCoilActual2 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad
    else:
        QCoilActual2 = 0.0

    UpdateHeatingCoil(state, CoilNum)
    ReportHeatingCoil(state, CoilNum, state.dataHeatingCoils.CoilIsSuppHeater)

    if QCoilActual is not None:
        QCoilActual.append(QCoilActual2)


def GetHeatingCoilInput(state: Any) -> None:
    RoutineName = "GetHeatingCoilInput: "
    routineName = "GetHeatingCoilInput"

    state.dataHeatingCoils.NumElecCoil = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Electric")
    state.dataHeatingCoils.NumElecCoilMultiStage = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Electric:MultiStage")
    state.dataHeatingCoils.NumFuelCoil = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Fuel")
    state.dataHeatingCoils.NumGasCoilMultiStage = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Gas:MultiStage")
    state.dataHeatingCoils.NumDesuperheaterCoil = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:Desuperheater")
    state.dataHeatingCoils.NumHeatingCoils = (
        state.dataHeatingCoils.NumElecCoil
        + state.dataHeatingCoils.NumElecCoilMultiStage
        + state.dataHeatingCoils.NumFuelCoil
        + state.dataHeatingCoils.NumGasCoilMultiStage
        + state.dataHeatingCoils.NumDesuperheaterCoil
    )

    if state.dataHeatingCoils.NumHeatingCoils > 0:
        state.dataHeatingCoils.HeatingCoil = [HeatingCoilEquipConditions() for _ in range(state.dataHeatingCoils.NumHeatingCoils)]
        state.dataHeatingCoils.HeatingCoilNumericFields = [HeatingCoilNumericFieldData() for _ in range(state.dataHeatingCoils.NumHeatingCoils)]
        state.dataHeatingCoils.ValidSourceType = [False] * state.dataHeatingCoils.NumHeatingCoils
        state.dataHeatingCoils.CheckEquipName = [True] * state.dataHeatingCoils.NumHeatingCoils

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Electric")
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Electric:MultiStage")
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Fuel")
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Gas:MultiStage")
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "Coil:Heating:Desuperheater")

    # Electric heating coils loop
    for ElecCoilNum in range(1, state.dataHeatingCoils.NumElecCoil + 1):
        CoilNum = ElecCoilNum - 1
        heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum]
        heatingCoil.Name = f"ElecCoil_{ElecCoilNum}"
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Electric"
        heatingCoil.FuelType = state.Constant.eFuel.Electricity

    # Electric multistage heating coils loop
    for ElecCoilNum in range(1, state.dataHeatingCoils.NumElecCoilMultiStage + 1):
        CoilNum = state.dataHeatingCoils.NumElecCoil + ElecCoilNum - 1
        heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum]
        heatingCoil.Name = f"ElecMultiStageCoil_{ElecCoilNum}"
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Electric:MultiStage"
        heatingCoil.FuelType = state.Constant.eFuel.Electricity

    # Fuel heating coils loop
    for FuelCoilNum in range(1, state.dataHeatingCoils.NumFuelCoil + 1):
        CoilNum = state.dataHeatingCoils.NumElecCoil + state.dataHeatingCoils.NumElecCoilMultiStage + FuelCoilNum - 1
        heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum]
        heatingCoil.Name = f"FuelCoil_{FuelCoilNum}"
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Fuel"

    # Gas multistage heating coils loop
    for GasCoilNum in range(1, state.dataHeatingCoils.NumGasCoilMultiStage + 1):
        CoilNum = (
            state.dataHeatingCoils.NumElecCoil
            + state.dataHeatingCoils.NumElecCoilMultiStage
            + state.dataHeatingCoils.NumFuelCoil
            + GasCoilNum
            - 1
        )
        heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum]
        heatingCoil.Name = f"GasMultiStageCoil_{GasCoilNum}"
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Gas:MultiStage"
        heatingCoil.FuelType = state.Constant.eFuel.NaturalGas

    # Desuperheater heating coils loop
    for DesupCoilNum in range(1, state.dataHeatingCoils.NumDesuperheaterCoil + 1):
        CoilNum = (
            state.dataHeatingCoils.NumElecCoil
            + state.dataHeatingCoils.NumElecCoilMultiStage
            + state.dataHeatingCoils.NumFuelCoil
            + state.dataHeatingCoils.NumGasCoilMultiStage
            + DesupCoilNum
            - 1
        )
        heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum]
        heatingCoil.Name = f"DesuperheaterCoil_{DesupCoilNum}"
        heatingCoil.HeatingCoilType = "Heating"
        heatingCoil.HeatingCoilModel = "Desuperheater"
        heatingCoil.FuelType = state.Constant.eFuel.Electricity


def InitHeatingCoil(state: Any, CoilNum: int, FirstHVACIteration: bool, QCoilRequired: float) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    if state.dataHeatingCoils.MyOneTimeFlag:
        num_heating_coils = state.dataHeatingCoils.NumHeatingCoils
        state.dataHeatingCoils.MyEnvrnFlag = [True] * num_heating_coils
        state.dataHeatingCoils.MySizeFlag = [True] * num_heating_coils
        state.dataHeatingCoils.ShowSingleWarning = [True] * num_heating_coils
        state.dataHeatingCoils.MySPTestFlag = [True] * num_heating_coils
        state.dataHeatingCoils.MyOneTimeFlag = False

    if not state.dataGlobal.SysSizingCalc and state.dataHeatingCoils.MySizeFlag[CoilNum - 1]:
        SizeHeatingCoil(state, CoilNum)
        state.dataHeatingCoils.MySizeFlag[CoilNum - 1] = False

    AirOutletNodeNum = heatingCoil.AirOutletNodeNum
    ControlNodeNum = heatingCoil.TempSetPointNodeNum
    airInletNode = state.dataLoopNodes.Node[heatingCoil.AirInletNodeNum]
    airOutletNode = state.dataLoopNodes.Node[AirOutletNodeNum]
    heatingCoil.InletAirMassFlowRate = airInletNode.MassFlowRate
    heatingCoil.InletAirTemp = airInletNode.Temp
    heatingCoil.InletAirHumRat = airInletNode.HumRat
    heatingCoil.InletAirEnthalpy = airInletNode.Enthalpy

    heatingCoil.HeatingCoilLoad = 0.0
    heatingCoil.FuelUseLoad = 0.0
    heatingCoil.ElecUseLoad = 0.0
    heatingCoil.RTF = 0.0

    if ControlNodeNum == 0:
        heatingCoil.DesiredOutletTemp = 0.0
    else:
        controlNode = state.dataLoopNodes.Node[ControlNodeNum]
        heatingCoil.DesiredOutletTemp = controlNode.TempSetPoint - (
            0 if ControlNodeNum == AirOutletNodeNum else (controlNode.Temp - airOutletNode.Temp)
        )


def SizeHeatingCoil(state: Any, CoilNum: int) -> None:
    RoutineName = "SizeHeatingCoil: "
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    if heatingCoil.coilType == state.HVAC.CoilType.HeatingElectricMultiStage:
        TempCap = heatingCoil.MSNominalCapacity[heatingCoil.NumOfStages - 1] if heatingCoil.MSNominalCapacity else 0.0
    elif heatingCoil.coilType == state.HVAC.CoilType.HeatingGasMultiStage:
        TempCap = heatingCoil.MSNominalCapacity[heatingCoil.NumOfStages - 1] if heatingCoil.MSNominalCapacity else 0.0
    elif heatingCoil.coilType == state.HVAC.CoilType.HeatingDesuperheater:
        return
    else:
        TempCap = heatingCoil.NominalCapacity

    state.dataSize.DataCoilIsSuppHeater = state.dataHeatingCoils.CoilIsSuppHeater
    state.dataSize.DataCoolCoilCap = 0.0

    if TempCap == state.DataSizing.AutoSize:
        if heatingCoil.DesiccantRegenerationCoil:
            state.dataSize.DataDesicRegCoil = True

    heatingCoil.NominalCapacity = TempCap
    state.dataSize.DataCoilIsSuppHeater = False
    state.dataSize.DataDesicRegCoil = False


def CalcElectricHeatingCoil(
    state: Any, CoilNum: int, QCoilReq: float, fanOp: Any, PartLoadRatio: float
) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    Effic = heatingCoil.Efficiency
    TempAirIn = heatingCoil.InletAirTemp
    Win = heatingCoil.InletAirHumRat
    TempSetPoint = heatingCoil.DesiredOutletTemp

    if fanOp == state.HVAC.FanOp.Cycling:
        if PartLoadRatio > 0.0:
            AirMassFlow = heatingCoil.InletAirMassFlowRate / PartLoadRatio
            QCoilReq /= PartLoadRatio
        else:
            AirMassFlow = 0.0
    else:
        AirMassFlow = heatingCoil.InletAirMassFlowRate

    CapacitanceAir = state.Psychrometrics.PsyCpAirFnW(Win) * AirMassFlow

    if (AirMassFlow > 0.0 and heatingCoil.NominalCapacity > 0.0) and (heatingCoil.availSched.getCurrentVal() > 0.0) and (QCoilReq > 0.0):
        if QCoilReq > heatingCoil.NominalCapacity:
            QCoilCap = heatingCoil.NominalCapacity
        else:
            QCoilCap = QCoilReq

        TempAirOut = TempAirIn + QCoilCap / CapacitanceAir
        HeatingCoilLoad = QCoilCap
        heatingCoil.ElecUseLoad = HeatingCoilLoad / Effic

    elif (
        (AirMassFlow > 0.0 and heatingCoil.NominalCapacity > 0.0)
        and (heatingCoil.availSched.getCurrentVal() > 0.0)
        and (QCoilReq == state.Node.SensedLoadFlagValue)
        and (abs(TempSetPoint - TempAirIn) > state.HVAC.TempControlTol)
    ):
        QCoilCap = CapacitanceAir * (TempSetPoint - TempAirIn)
        if QCoilCap <= 0.0:
            QCoilCap = 0.0
            TempAirOut = TempAirIn
        elif QCoilCap > heatingCoil.NominalCapacity:
            QCoilCap = heatingCoil.NominalCapacity
            TempAirOut = TempAirIn + QCoilCap / CapacitanceAir
        else:
            TempAirOut = TempSetPoint

        HeatingCoilLoad = QCoilCap
        heatingCoil.ElecUseLoad = HeatingCoilLoad / Effic

    else:
        TempAirOut = TempAirIn
        HeatingCoilLoad = 0.0
        heatingCoil.ElecUseLoad = 0.0

    if fanOp == state.HVAC.FanOp.Cycling:
        heatingCoil.ElecUseLoad *= PartLoadRatio
        HeatingCoilLoad *= PartLoadRatio

    heatingCoil.HeatingCoilLoad = HeatingCoilLoad
    heatingCoil.OutletAirTemp = TempAirOut
    heatingCoil.OutletAirHumRat = heatingCoil.InletAirHumRat
    heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate
    heatingCoil.OutletAirEnthalpy = state.Psychrometrics.PsyHFnTdbW(heatingCoil.OutletAirTemp, heatingCoil.OutletAirHumRat)

    state.dataLoopNodes.Node[heatingCoil.AirOutletNodeNum].Temp = heatingCoil.OutletAirTemp


def CalcMultiStageElectricHeatingCoil(
    state: Any, CoilNum: int, SpeedRatio: float, CycRatio: float, StageNum: int, fanOp: Any, SuppHeat: bool
) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    if StageNum > 1:
        StageNumLS = StageNum - 1
        StageNumHS = StageNum
        if StageNum > heatingCoil.NumOfStages:
            StageNumLS = heatingCoil.NumOfStages - 1
            StageNumHS = heatingCoil.NumOfStages
    else:
        StageNumLS = 1
        StageNumHS = 1

    AirMassFlow = heatingCoil.InletAirMassFlowRate
    InletAirDryBulbTemp = heatingCoil.InletAirTemp
    InletAirEnthalpy = heatingCoil.InletAirEnthalpy
    InletAirHumRat = heatingCoil.InletAirHumRat
    OutdoorPressure = state.dataEnvrn.OutBaroPress

    if (AirMassFlow > 0.0) and (heatingCoil.availSched.getCurrentVal() > 0.0) and ((CycRatio > 0.0) or (SpeedRatio > 0.0)):
        if StageNum > 1:
            TotCapLS = heatingCoil.MSNominalCapacity[StageNumLS - 1]
            TotCapHS = heatingCoil.MSNominalCapacity[StageNumHS - 1]
            EffLS = heatingCoil.MSEfficiency[StageNumLS - 1]
            EffHS = heatingCoil.MSEfficiency[StageNumHS - 1]

            LSElecHeatingPower = TotCapLS / EffLS
            HSElecHeatingPower = TotCapHS / EffHS
            OutletAirHumRat = InletAirHumRat

            heatingCoil.ElecUseLoad = SpeedRatio * HSElecHeatingPower + (1.0 - SpeedRatio) * LSElecHeatingPower
            heatingCoil.HeatingCoilLoad = TotCapHS * SpeedRatio + TotCapLS * (1.0 - SpeedRatio)

            OutletAirEnthalpy = InletAirEnthalpy + heatingCoil.HeatingCoilLoad / heatingCoil.InletAirMassFlowRate
            OutletAirTemp = state.Psychrometrics.PsyTdbFnHW(OutletAirEnthalpy, OutletAirHumRat)

            heatingCoil.OutletAirTemp = OutletAirTemp
            heatingCoil.OutletAirHumRat = OutletAirHumRat
            heatingCoil.OutletAirEnthalpy = OutletAirEnthalpy
            heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate

        elif CycRatio > 0.0:
            PartLoadRat = min(1.0, CycRatio)

            if fanOp == state.HVAC.FanOp.Cycling:
                AirMassFlow /= PartLoadRat
            elif fanOp == state.HVAC.FanOp.Continuous:
                if not SuppHeat:
                    AirMassFlow = state.dataHVACGlobal.MSHPMassFlowRateLow

            TotCap = heatingCoil.MSNominalCapacity[StageNumLS - 1]

            FullLoadOutAirEnth = InletAirEnthalpy + TotCap / AirMassFlow
            FullLoadOutAirHumRat = InletAirHumRat
            FullLoadOutAirTemp = state.Psychrometrics.PsyTdbFnHW(FullLoadOutAirEnth, FullLoadOutAirHumRat)

            if fanOp == state.HVAC.FanOp.Cycling:
                OutletAirEnthalpy = FullLoadOutAirEnth
                OutletAirHumRat = FullLoadOutAirHumRat
                OutletAirTemp = FullLoadOutAirTemp
            else:
                OutletAirEnthalpy = PartLoadRat * FullLoadOutAirEnth + (1.0 - PartLoadRat) * InletAirEnthalpy
                OutletAirHumRat = PartLoadRat * FullLoadOutAirHumRat + (1.0 - PartLoadRat) * InletAirHumRat
                OutletAirTemp = PartLoadRat * FullLoadOutAirTemp + (1.0 - PartLoadRat) * InletAirDryBulbTemp

            EffLS = heatingCoil.MSEfficiency[StageNumLS - 1]
            heatingCoil.HeatingCoilLoad = TotCap * PartLoadRat
            heatingCoil.ElecUseLoad = heatingCoil.HeatingCoilLoad / EffLS

            heatingCoil.OutletAirTemp = OutletAirTemp
            heatingCoil.OutletAirHumRat = OutletAirHumRat
            heatingCoil.OutletAirEnthalpy = OutletAirEnthalpy
            heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate

    else:
        heatingCoil.OutletAirEnthalpy = heatingCoil.InletAirEnthalpy
        heatingCoil.OutletAirHumRat = heatingCoil.InletAirHumRat
        heatingCoil.OutletAirTemp = heatingCoil.InletAirTemp
        heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate
        heatingCoil.ElecUseLoad = 0.0
        heatingCoil.HeatingCoilLoad = 0.0

    state.dataLoopNodes.Node[heatingCoil.AirOutletNodeNum].Temp = heatingCoil.OutletAirTemp


def CalcFuelHeatingCoil(state: Any, CoilNum: int, QCoilReq: float, fanOp: Any, PartLoadRatio: float) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    Effic = heatingCoil.Efficiency
    TempAirIn = heatingCoil.InletAirTemp
    Win = heatingCoil.InletAirHumRat
    TempSetPoint = heatingCoil.DesiredOutletTemp
    AirMassFlow = heatingCoil.InletAirMassFlowRate

    CapacitanceAir = state.Psychrometrics.PsyCpAirFnW(Win) * AirMassFlow

    if (AirMassFlow > 0.0 and heatingCoil.NominalCapacity > 0.0) and (heatingCoil.availSched.getCurrentVal() > 0.0) and (QCoilReq > 0.0):
        if QCoilReq > heatingCoil.NominalCapacity:
            QCoilCap = heatingCoil.NominalCapacity
        else:
            QCoilCap = QCoilReq

        TempAirOut = TempAirIn + QCoilCap / CapacitanceAir
        HeatingCoilLoad = QCoilCap
        PartLoadRat = HeatingCoilLoad / heatingCoil.NominalCapacity

        heatingCoil.FuelUseLoad = HeatingCoilLoad / Effic
        heatingCoil.ElecUseLoad = heatingCoil.ParasiticElecLoad * PartLoadRat
        heatingCoil.ParasiticFuelRate = heatingCoil.ParasiticFuelCapacity * (1.0 - PartLoadRat)

    elif (
        (AirMassFlow > 0.0 and heatingCoil.NominalCapacity > 0.0)
        and (heatingCoil.availSched.getCurrentVal() > 0.0)
        and (QCoilReq == state.Node.SensedLoadFlagValue)
        and (abs(TempSetPoint - TempAirIn) > state.HVAC.TempControlTol)
    ):
        QCoilCap = CapacitanceAir * (TempSetPoint - TempAirIn)
        if QCoilCap <= 0.0:
            QCoilCap = 0.0
            TempAirOut = TempAirIn
        elif QCoilCap > heatingCoil.NominalCapacity:
            QCoilCap = heatingCoil.NominalCapacity
            TempAirOut = TempAirIn + QCoilCap / CapacitanceAir
        else:
            TempAirOut = TempSetPoint

        HeatingCoilLoad = QCoilCap
        PartLoadRat = HeatingCoilLoad / heatingCoil.NominalCapacity

        heatingCoil.FuelUseLoad = HeatingCoilLoad / Effic
        heatingCoil.ElecUseLoad = heatingCoil.ParasiticElecLoad * PartLoadRat
        heatingCoil.ParasiticFuelRate = heatingCoil.ParasiticFuelCapacity * (1.0 - PartLoadRat)

    else:
        TempAirOut = TempAirIn
        HeatingCoilLoad = 0.0
        PartLoadRat = 0.0
        heatingCoil.FuelUseLoad = 0.0
        heatingCoil.ElecUseLoad = 0.0
        heatingCoil.ParasiticFuelRate = heatingCoil.ParasiticFuelCapacity

    heatingCoil.RTF = PartLoadRat

    if heatingCoil.PLFCurveIndex > 0:
        if PartLoadRat == 0:
            heatingCoil.FuelUseLoad = 0.0
        else:
            PLF = state.Curve.CurveValue(state, heatingCoil.PLFCurveIndex, PartLoadRat)
            if PLF < 0.7:
                PLF = 0.7

            heatingCoil.RTF = PartLoadRat / PLF
            if heatingCoil.RTF > 1.0:
                heatingCoil.RTF = 1.0

            heatingCoil.ElecUseLoad = heatingCoil.ParasiticElecLoad * heatingCoil.RTF
            heatingCoil.FuelUseLoad = heatingCoil.NominalCapacity / Effic * heatingCoil.RTF
            heatingCoil.ParasiticFuelRate = heatingCoil.ParasiticFuelCapacity * (1.0 - heatingCoil.RTF)

            if fanOp == state.HVAC.FanOp.Cycling:
                state.dataHVACGlobal.OnOffFanPartLoadFraction = PLF

    heatingCoil.HeatingCoilLoad = HeatingCoilLoad
    heatingCoil.OutletAirTemp = TempAirOut
    heatingCoil.OutletAirHumRat = heatingCoil.InletAirHumRat
    heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate
    heatingCoil.OutletAirEnthalpy = state.Psychrometrics.PsyHFnTdbW(heatingCoil.OutletAirTemp, heatingCoil.OutletAirHumRat)

    state.dataHVACGlobal.ElecHeatingCoilPower = heatingCoil.ElecUseLoad
    state.dataLoopNodes.Node[heatingCoil.AirOutletNodeNum].Temp = heatingCoil.OutletAirTemp


def CalcMultiStageGasHeatingCoil(
    state: Any, CoilNum: int, SpeedRatio: float, CycRatio: float, StageNum: int, fanOp: Any
) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    MSHPMassFlowRateHigh = state.dataHVACGlobal.MSHPMassFlowRateHigh
    MSHPMassFlowRateLow = state.dataHVACGlobal.MSHPMassFlowRateLow

    if StageNum > 1:
        StageNumLS = StageNum - 1
        StageNumHS = StageNum
        if StageNum > heatingCoil.NumOfStages:
            StageNumLS = heatingCoil.NumOfStages - 1
            StageNumHS = heatingCoil.NumOfStages
    else:
        StageNumLS = 1
        StageNumHS = 1

    AirMassFlow = heatingCoil.InletAirMassFlowRate
    InletAirEnthalpy = heatingCoil.InletAirEnthalpy
    InletAirHumRat = heatingCoil.InletAirHumRat
    OutdoorPressure = state.dataEnvrn.OutBaroPress

    if (AirMassFlow > 0.0) and (heatingCoil.availSched.getCurrentVal() > 0.0) and ((CycRatio > 0.0) or (SpeedRatio > 0.0)):
        if StageNum > 1:
            TotCapLS = heatingCoil.MSNominalCapacity[StageNumLS - 1]
            TotCapHS = heatingCoil.MSNominalCapacity[StageNumHS - 1]

            EffLS = heatingCoil.MSEfficiency[StageNumLS - 1]
            EffHS = heatingCoil.MSEfficiency[StageNumHS - 1]

            PartLoadRat = min(1.0, SpeedRatio)
            heatingCoil.RTF = 1.0

            LSFullLoadOutAirEnth = InletAirEnthalpy + TotCapLS / MSHPMassFlowRateLow
            HSFullLoadOutAirEnth = InletAirEnthalpy + TotCapHS / MSHPMassFlowRateHigh
            LSGasHeatingPower = TotCapLS / EffLS
            HSGasHeatingPower = TotCapHS / EffHS
            OutletAirHumRat = InletAirHumRat

            heatingCoil.ElecUseLoad = PartLoadRat * heatingCoil.MSParasiticElecLoad[
                StageNumHS - 1
            ] + (1.0 - PartLoadRat) * heatingCoil.MSParasiticElecLoad[StageNumLS - 1]

            state.dataHVACGlobal.ElecHeatingCoilPower = heatingCoil.ElecUseLoad
            heatingCoil.HeatingCoilLoad = (
                MSHPMassFlowRateHigh * (HSFullLoadOutAirEnth - InletAirEnthalpy) * PartLoadRat
                + MSHPMassFlowRateLow * (LSFullLoadOutAirEnth - InletAirEnthalpy) * (1.0 - PartLoadRat)
            )
            EffAvg = (EffHS * PartLoadRat) + (EffLS * (1.0 - PartLoadRat))
            heatingCoil.FuelUseLoad = heatingCoil.HeatingCoilLoad / EffAvg
            heatingCoil.ParasiticFuelRate = 0.0

            OutletAirEnthalpy = InletAirEnthalpy + heatingCoil.HeatingCoilLoad / heatingCoil.InletAirMassFlowRate
            OutletAirTemp = state.Psychrometrics.PsyTdbFnHW(OutletAirEnthalpy, OutletAirHumRat)

            heatingCoil.OutletAirTemp = OutletAirTemp
            heatingCoil.OutletAirHumRat = OutletAirHumRat
            heatingCoil.OutletAirEnthalpy = OutletAirEnthalpy
            heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate

        elif CycRatio > 0.0:
            if fanOp == state.HVAC.FanOp.Cycling:
                AirMassFlow /= CycRatio
            elif fanOp == state.HVAC.FanOp.Continuous:
                AirMassFlow = MSHPMassFlowRateLow

            TotCap = heatingCoil.MSNominalCapacity[StageNumLS - 1]
            PartLoadRat = min(1.0, CycRatio)
            heatingCoil.RTF = PartLoadRat

            FullLoadOutAirEnth = InletAirEnthalpy + TotCap / AirMassFlow
            FullLoadOutAirHumRat = InletAirHumRat
            FullLoadOutAirTemp = state.Psychrometrics.PsyTdbFnHW(FullLoadOutAirEnth, FullLoadOutAirHumRat)

            if fanOp == state.HVAC.FanOp.Cycling:
                OutletAirEnthalpy = FullLoadOutAirEnth
                OutletAirHumRat = FullLoadOutAirHumRat
                OutletAirTemp = FullLoadOutAirTemp
            else:
                OutletAirEnthalpy = (
                    PartLoadRat * AirMassFlow / heatingCoil.InletAirMassFlowRate * (FullLoadOutAirEnth - InletAirEnthalpy)
                    + InletAirEnthalpy
                )
                OutletAirHumRat = (
                    PartLoadRat * AirMassFlow / heatingCoil.InletAirMassFlowRate * (FullLoadOutAirHumRat - InletAirHumRat)
                    + InletAirHumRat
                )
                OutletAirTemp = state.Psychrometrics.PsyTdbFnHW(OutletAirEnthalpy, OutletAirHumRat)

            EffLS = heatingCoil.MSEfficiency[StageNumLS - 1]
            heatingCoil.HeatingCoilLoad = TotCap * PartLoadRat
            heatingCoil.FuelUseLoad = heatingCoil.HeatingCoilLoad / EffLS
            heatingCoil.ElecUseLoad = heatingCoil.MSParasiticElecLoad[StageNumLS - 1] * (1.0 - PartLoadRat)
            heatingCoil.ParasiticFuelRate = heatingCoil.ParasiticFuelCapacity * (1.0 - PartLoadRat)
            state.dataHVACGlobal.ElecHeatingCoilPower = heatingCoil.ElecUseLoad

            heatingCoil.OutletAirTemp = OutletAirTemp
            heatingCoil.OutletAirHumRat = OutletAirHumRat
            heatingCoil.OutletAirEnthalpy = OutletAirEnthalpy
            heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate

    else:
        heatingCoil.OutletAirEnthalpy = heatingCoil.InletAirEnthalpy
        heatingCoil.OutletAirHumRat = heatingCoil.InletAirHumRat
        heatingCoil.OutletAirTemp = heatingCoil.InletAirTemp
        heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate

        heatingCoil.ElecUseLoad = 0.0
        heatingCoil.HeatingCoilLoad = 0.0
        heatingCoil.FuelUseLoad = 0.0
        heatingCoil.ParasiticFuelRate = heatingCoil.ParasiticFuelCapacity
        state.dataHVACGlobal.ElecHeatingCoilPower = 0.0
        PartLoadRat = 0.0

    if heatingCoil.PLFCurveIndex > 0:
        if PartLoadRat > 0.0 and StageNum < 2:
            PLF = state.Curve.CurveValue(state, heatingCoil.PLFCurveIndex, PartLoadRat)
            if PLF < 0.7:
                PLF = 0.7

            heatingCoil.RTF = PartLoadRat / PLF
            if heatingCoil.RTF > 1.0:
                heatingCoil.RTF = 1.0

            heatingCoil.ElecUseLoad = heatingCoil.MSParasiticElecLoad[StageNum - 1] * heatingCoil.RTF
            heatingCoil.FuelUseLoad = (heatingCoil.MSNominalCapacity[StageNum - 1] / EffLS) * heatingCoil.RTF
            heatingCoil.ParasiticFuelRate = heatingCoil.ParasiticFuelCapacity * (1.0 - heatingCoil.RTF)

            if fanOp == state.HVAC.FanOp.Cycling:
                state.dataHVACGlobal.OnOffFanPartLoadFraction = PLF

    state.dataLoopNodes.Node[heatingCoil.AirOutletNodeNum].Temp = heatingCoil.OutletAirTemp


def CalcDesuperheaterHeatingCoil(state: Any, CoilNum: int, QCoilReq: float) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    Effic = heatingCoil.Efficiency
    AirMassFlow = heatingCoil.InletAirMassFlowRate
    TempAirIn = heatingCoil.InletAirTemp
    Win = heatingCoil.InletAirHumRat
    CapacitanceAir = state.Psychrometrics.PsyCpAirFnW(Win) * AirMassFlow
    TempSetPoint = heatingCoil.DesiredOutletTemp

    if state.dataHeatingCoils.ValidSourceType[CoilNum - 1]:
        SourceID = heatingCoil.ReclaimHeatingSourceIndexNum
        if heatingCoil.ReclaimHeatingSource == HeatObjTypes.COMPRESSORRACK_REFRIGERATEDCASE:
            heatingCoil.RTF = 1.0
            heatingCoil.NominalCapacity = (
                state.dataHeatBal.HeatReclaimRefrigeratedRack[SourceID].AvailCapacity * Effic
                - state.dataHeatBal.HeatReclaimRefrigeratedRack[SourceID].WaterHeatingDesuperheaterReclaimedHeatTotal
            )
        elif heatingCoil.ReclaimHeatingSource == HeatObjTypes.CONDENSER_REFRIGERATION:
            AvailTemp = state.dataHeatBal.HeatReclaimRefrigCondenser[SourceID].AvailTemperature
            heatingCoil.RTF = 1.0
            if AvailTemp <= TempAirIn:
                heatingCoil.NominalCapacity = 0.0
            else:
                heatingCoil.NominalCapacity = (
                    state.dataHeatBal.HeatReclaimRefrigCondenser[SourceID].AvailCapacity * Effic
                    - state.dataHeatBal.HeatReclaimRefrigCondenser[SourceID].WaterHeatingDesuperheaterReclaimedHeatTotal
                )
        elif heatingCoil.ReclaimHeatingSource in (
            HeatObjTypes.COIL_DX_COOLING,
            HeatObjTypes.COIL_DX_MULTISPEED,
            HeatObjTypes.COIL_DX_MULTIMODE,
        ):
            heatingCoil.RTF = state.dataDXCoils.DXCoil[SourceID].CoolingCoilRuntimeFraction
            heatingCoil.NominalCapacity = (
                state.dataHeatBal.HeatReclaimDXCoil[SourceID].AvailCapacity * Effic
                - state.dataHeatBal.HeatReclaimDXCoil[SourceID].WaterHeatingDesuperheaterReclaimedHeatTotal
            )
        elif heatingCoil.ReclaimHeatingSource == HeatObjTypes.COIL_DX_VARIABLE_COOLING:
            heatingCoil.RTF = state.dataVariableSpeedCoils.VarSpeedCoil[SourceID].RunFrac
            heatingCoil.NominalCapacity = (
                state.dataHeatBal.HeatReclaimVS_Coil[SourceID].AvailCapacity * Effic
                - state.dataHeatBal.HeatReclaimVS_Coil[SourceID].WaterHeatingDesuperheaterReclaimedHeatTotal
            )
        elif heatingCoil.ReclaimHeatingSource == HeatObjTypes.COIL_COOLING_DX_NEW:
            thisCoolingCoil = state.dataCoilCoolingDX.coilCoolingDXs[SourceID]
            heatingCoil.RTF = thisCoolingCoil.runTimeFraction
            heatingCoil.NominalCapacity = (
                thisCoolingCoil.reclaimHeat.AvailCapacity * Effic
                - thisCoolingCoil.reclaimHeat.WaterHeatingDesuperheaterReclaimedHeatTotal
            )
    else:
        heatingCoil.NominalCapacity = 0.0

    if (AirMassFlow > 0.0) and (heatingCoil.availSched.getCurrentVal() > 0.0) and (QCoilReq > 0.0):
        if QCoilReq > heatingCoil.NominalCapacity:
            QCoilCap = heatingCoil.NominalCapacity
        else:
            QCoilCap = QCoilReq

        if heatingCoil.NominalCapacity > 0.0:
            heatingCoil.RTF *= (QCoilCap / heatingCoil.NominalCapacity)
            TempAirOut = TempAirIn + QCoilCap / CapacitanceAir
            HeatingCoilLoad = QCoilCap
        else:
            heatingCoil.RTF = 0.0
            TempAirOut = TempAirIn
            HeatingCoilLoad = 0.0

    elif (
        (AirMassFlow > 0.0 and heatingCoil.NominalCapacity > 0.0)
        and (heatingCoil.availSched.getCurrentVal() > 0.0)
        and (QCoilReq == state.Node.SensedLoadFlagValue)
        and (abs(TempSetPoint - TempAirIn) > state.HVAC.TempControlTol)
    ):
        QCoilCap = CapacitanceAir * (TempSetPoint - TempAirIn)
        if QCoilCap <= 0.0:
            QCoilCap = 0.0
            TempAirOut = TempAirIn
        elif QCoilCap > heatingCoil.NominalCapacity:
            QCoilCap = heatingCoil.NominalCapacity
            TempAirOut = TempAirIn + QCoilCap / CapacitanceAir
        else:
            TempAirOut = TempSetPoint

        HeatingCoilLoad = QCoilCap
        heatingCoil.RTF *= (QCoilCap / heatingCoil.NominalCapacity)

    else:
        TempAirOut = TempAirIn
        HeatingCoilLoad = 0.0
        heatingCoil.ElecUseLoad = 0.0
        heatingCoil.RTF = 0.0

    heatingCoil.HeatingCoilLoad = HeatingCoilLoad
    heatingCoil.OutletAirTemp = TempAirOut
    heatingCoil.OutletAirHumRat = heatingCoil.InletAirHumRat
    heatingCoil.OutletAirMassFlowRate = heatingCoil.InletAirMassFlowRate
    heatingCoil.OutletAirEnthalpy = state.Psychrometrics.PsyHFnTdbW(heatingCoil.OutletAirTemp, heatingCoil.OutletAirHumRat)

    heatingCoil.ElecUseLoad = heatingCoil.ParasiticElecLoad * heatingCoil.RTF

    if state.dataHeatingCoils.ValidSourceType[CoilNum - 1]:
        SourceID = heatingCoil.ReclaimHeatingSourceIndexNum
        DesuperheaterNum = (
            CoilNum
            - state.dataHeatingCoils.NumElecCoil
            - state.dataHeatingCoils.NumElecCoilMultiStage
            - state.dataHeatingCoils.NumFuelCoil
            - state.dataHeatingCoils.NumGasCoilMultiStage
        )

        if heatingCoil.ReclaimHeatingSource == HeatObjTypes.COMPRESSORRACK_REFRIGERATEDCASE:
            state.dataHeatBal.HeatReclaimRefrigeratedRack[SourceID].HVACDesuperheaterReclaimedHeat[DesuperheaterNum - 1] = HeatingCoilLoad
            state.dataHeatBal.HeatReclaimRefrigeratedRack[SourceID].HVACDesuperheaterReclaimedHeatTotal = sum(
                state.dataHeatBal.HeatReclaimRefrigeratedRack[SourceID].HVACDesuperheaterReclaimedHeat
            )
        elif heatingCoil.ReclaimHeatingSource == HeatObjTypes.CONDENSER_REFRIGERATION:
            state.dataHeatBal.HeatReclaimRefrigCondenser[SourceID].HVACDesuperheaterReclaimedHeat[DesuperheaterNum - 1] = HeatingCoilLoad
            state.dataHeatBal.HeatReclaimRefrigCondenser[SourceID].HVACDesuperheaterReclaimedHeatTotal = sum(
                state.dataHeatBal.HeatReclaimRefrigCondenser[SourceID].HVACDesuperheaterReclaimedHeat
            )
        elif heatingCoil.ReclaimHeatingSource in (
            HeatObjTypes.COIL_DX_COOLING,
            HeatObjTypes.COIL_DX_MULTISPEED,
            HeatObjTypes.COIL_DX_MULTIMODE,
        ):
            state.dataHeatBal.HeatReclaimDXCoil[SourceID].HVACDesuperheaterReclaimedHeat[DesuperheaterNum - 1] = HeatingCoilLoad
            state.dataHeatBal.HeatReclaimDXCoil[SourceID].HVACDesuperheaterReclaimedHeatTotal = sum(
                state.dataHeatBal.HeatReclaimDXCoil[SourceID].HVACDesuperheaterReclaimedHeat
            )
        elif heatingCoil.ReclaimHeatingSource == HeatObjTypes.COIL_DX_VARIABLE_COOLING:
            state.dataHeatBal.HeatReclaimVS_Coil[SourceID].HVACDesuperheaterReclaimedHeat[DesuperheaterNum - 1] = HeatingCoilLoad
            state.dataHeatBal.HeatReclaimVS_Coil[SourceID].HVACDesuperheaterReclaimedHeatTotal = sum(
                state.dataHeatBal.HeatReclaimVS_Coil[SourceID].HVACDesuperheaterReclaimedHeat
            )


def UpdateHeatingCoil(state: Any, CoilNum: int) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]
    airInletNode = state.dataLoopNodes.Node[heatingCoil.AirInletNodeNum]
    airOutletNode = state.dataLoopNodes.Node[heatingCoil.AirOutletNodeNum]

    airOutletNode.MassFlowRate = heatingCoil.OutletAirMassFlowRate
    airOutletNode.Temp = heatingCoil.OutletAirTemp
    airOutletNode.HumRat = heatingCoil.OutletAirHumRat
    airOutletNode.Enthalpy = heatingCoil.OutletAirEnthalpy

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


def ReportHeatingCoil(state: Any, CoilNum: int, coilIsSuppHeater: bool) -> None:
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]

    heatingCoil.HeatingCoilRate = heatingCoil.HeatingCoilLoad
    heatingCoil.HeatingCoilLoad *= TimeStepSysSec

    heatingCoil.FuelUseRate = heatingCoil.FuelUseLoad
    heatingCoil.ElecUseRate = heatingCoil.ElecUseLoad
    if coilIsSuppHeater:
        state.dataHVACGlobal.SuppHeatingCoilPower = heatingCoil.ElecUseLoad
    else:
        state.dataHVACGlobal.ElecHeatingCoilPower = heatingCoil.ElecUseLoad
    heatingCoil.FuelUseLoad *= TimeStepSysSec
    heatingCoil.ElecUseLoad *= TimeStepSysSec

    heatingCoil.ParasiticFuelConsumption = heatingCoil.ParasiticFuelRate * TimeStepSysSec

    if heatingCoil.reportCoilFinalSizes:
        if not state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingHVACSizingSimulations and not state.dataGlobal.DoingSizing:
            state.ReportCoilSelection.setCoilFinalSizes(
                state, heatingCoil.coilReportNum, heatingCoil.NominalCapacity, heatingCoil.NominalCapacity, -999.0, -999.0
            )
            heatingCoil.reportCoilFinalSizes = False


def GetCoilIndex(state: Any, HeatingCoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    HeatingCoilIndex = Util.FindItem(HeatingCoilName, state.dataHeatingCoils.HeatingCoil)
    return HeatingCoilIndex if HeatingCoilIndex != 0 else 0


def CheckHeatingCoilSchedule(state: Any, CompType: str, CompName: str, CompIndex: int) -> float:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    if CompIndex == 0:
        CoilNum = Util.FindItem(CompName, state.dataHeatingCoils.HeatingCoil)
        if CoilNum == 0:
            return 0.0
        Value = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].availSched.getCurrentVal()
    else:
        CoilNum = CompIndex
        if CoilNum > state.dataHeatingCoils.NumHeatingCoils or CoilNum < 1:
            return 0.0
        Value = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].availSched.getCurrentVal()

    return Value


def GetCoilCapacity(state: Any, CoilType: str, CoilName: str) -> float:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return -1000.0

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].NominalCapacity


def GetCoilAvailSched(state: Any, CoilType: str, CoilName: str) -> Optional[Any]:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return None

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].availSched


def GetCoilInletNode(state: Any, CoilType: str, CoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return 0

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].AirInletNodeNum


def GetCoilOutletNode(state: Any, CoilType: str, CoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return 0

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].AirOutletNodeNum


def GetHeatReclaimSourceIndex(state: Any, CoilType: str, CoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    for NumCoil in range(1, state.dataHeatingCoils.NumHeatingCoils + 1):
        if state.dataHeatingCoils.HeatingCoil[NumCoil - 1].ReclaimHeatingCoilName == CoilName:
            return state.dataHeatingCoils.HeatingCoil[NumCoil - 1].ReclaimHeatingSourceIndexNum

    return 0


def GetCoilControlNodeNum(state: Any, CoilType: str, CoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return 0

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].TempSetPointNodeNum


def GetHeatingCoilTypeNum(state: Any, CoilType: str, CoilName: str) -> Optional[Any]:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return None

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].coilType


def GetHeatingCoilIndex(state: Any, CoilType: str, CoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    return WhichCoil if WhichCoil != 0 else 0


def GetHeatingCoilPLFCurveIndex(state: Any, CoilType: str, CoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItem(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return 0

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].PLFCurveIndex


def GetHeatingCoilNumberOfStages(state: Any, CoilType: str, CoilName: str) -> int:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    WhichCoil = Util.FindItemInList(CoilName, state.dataHeatingCoils.HeatingCoil)
    if WhichCoil == 0:
        return 0

    return state.dataHeatingCoils.HeatingCoil[WhichCoil - 1].NumOfStages


def SetHeatingCoilData(
    state: Any, CoilNum: int, DesiccantRegenerationCoil: Optional[bool] = None, DesiccantDehumIndex: Optional[int] = None
) -> None:
    heatingCoil = state.dataHeatingCoils.HeatingCoil[CoilNum - 1]
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    if CoilNum <= 0 or CoilNum > state.dataHeatingCoils.NumHeatingCoils:
        return

    if DesiccantRegenerationCoil is not None:
        heatingCoil.DesiccantRegenerationCoil = DesiccantRegenerationCoil

    if DesiccantDehumIndex is not None:
        heatingCoil.DesiccantDehumNum = DesiccantDehumIndex


def SetHeatingCoilAirLoopNumber(state: Any, HeatingCoilName: str, AirLoopNum: int) -> None:
    if state.dataHeatingCoils.GetCoilsInputFlag:
        GetHeatingCoilInput(state)
        state.dataHeatingCoils.GetCoilsInputFlag = False

    HeatingCoilIndex = Util.FindItem(HeatingCoilName, state.dataHeatingCoils.HeatingCoil)
    if HeatingCoilIndex != 0:
        state.dataHeatingCoils.HeatingCoil[HeatingCoilIndex - 1].AirLoopNum = AirLoopNum


class Util:
    @staticmethod
    def FindItem(Name: str, Items: List[Any]) -> int:
        for i, item in enumerate(Items):
            if hasattr(item, "Name") and item.Name == Name:
                return i + 1
        return 0

    @staticmethod
    def FindItemInList(Name: str, Items: List[Any]) -> int:
        return Util.FindItem(Name, Items)

    @staticmethod
    def SameString(Str1: str, Str2: str) -> bool:
        return Str1.upper() == Str2.upper()

    @staticmethod
    def makeUPPER(Str: str) -> str:
        return Str.upper()

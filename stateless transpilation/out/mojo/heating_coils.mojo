# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state management object (struct)
# - HVAC: CoilType enum, FanOp enum, TempControlTol constant
# - Constant: eFuel enum, Units, eResource enums
# - Sched: Schedule struct, GetScheduleAlwaysOn, GetSchedule functions
# - Node: SensedLoadFlagValue, SensedNodeFlagValue, CtrlVarType, functions
# - Util: FindItem, FindItemInList, SameString, makeUPPER
# - Curve, Psychrometrics, DXCoils, VariableSpeedCoils, etc. (all as parameters)

from memory import DTypePointer, memset_zero
from math import abs, min, max
from collections import Dict


@value
struct HeatObjTypes:
    Invalid: Int32 = -1
    COMPRESSORRACK_REFRIGERATEDCASE: Int32 = 0
    COIL_DX_COOLING: Int32 = 1
    COIL_DX_MULTISPEED: Int32 = 2
    COIL_DX_MULTIMODE: Int32 = 3
    CONDENSER_REFRIGERATION: Int32 = 4
    COIL_DX_VARIABLE_COOLING: Int32 = 5
    COIL_COOLING_DX_NEW: Int32 = 6
    Num: Int32 = 7


alias MIN_AIR_MASS_FLOW = 0.001


struct HeatingCoilEquipConditions:
    var Name: String
    var HeatingCoilType: String
    var HeatingCoilModel: String
    var coilType: Int32
    var coilReportNum: Int32
    var FuelType: Int32
    var availSched: Pointer[UInt8]
    var InsuffTemperatureWarn: Int32
    var InletAirMassFlowRate: Float64
    var OutletAirMassFlowRate: Float64
    var InletAirTemp: Float64
    var OutletAirTemp: Float64
    var InletAirHumRat: Float64
    var OutletAirHumRat: Float64
    var InletAirEnthalpy: Float64
    var OutletAirEnthalpy: Float64
    var HeatingCoilLoad: Float64
    var HeatingCoilRate: Float64
    var FuelUseLoad: Float64
    var ElecUseLoad: Float64
    var FuelUseRate: Float64
    var ElecUseRate: Float64
    var Efficiency: Float64
    var NominalCapacity: Float64
    var DesiredOutletTemp: Float64
    var DesiredOutletHumRat: Float64
    var AvailTemperature: Float64
    var AirInletNodeNum: Int32
    var AirOutletNodeNum: Int32
    var TempSetPointNodeNum: Int32
    var Control: Int32
    var PLFCurveIndex: Int32
    var ParasiticElecLoad: Float64
    var ParasiticFuelConsumption: Float64
    var ParasiticFuelRate: Float64
    var ParasiticFuelCapacity: Float64
    var RTF: Float64
    var RTFErrorIndex: Int32
    var RTFErrorCount: Int32
    var PLFErrorIndex: Int32
    var PLFErrorCount: Int32
    var ReclaimHeatingCoilName: String
    var ReclaimHeatingSourceIndexNum: Int32
    var ReclaimHeatingSource: Int32
    var NumOfStages: Int32
    var MSNominalCapacity: DynamicVector[Float64]
    var MSEfficiency: DynamicVector[Float64]
    var MSParasiticElecLoad: DynamicVector[Float64]
    var DesiccantRegenerationCoil: Bool
    var DesiccantDehumNum: Int32
    var FaultyCoilSATFlag: Bool
    var FaultyCoilSATIndex: Int32
    var FaultyCoilSATOffset: Float64
    var reportCoilFinalSizes: Bool
    var AirLoopNum: Int32

    fn __init__(inout self):
        self.Name = String()
        self.HeatingCoilType = String()
        self.HeatingCoilModel = String()
        self.coilType = 0
        self.coilReportNum = -1
        self.FuelType = 0
        self.availSched = Pointer[UInt8]()
        self.InsuffTemperatureWarn = 0
        self.InletAirMassFlowRate = 0.0
        self.OutletAirMassFlowRate = 0.0
        self.InletAirTemp = 0.0
        self.OutletAirTemp = 0.0
        self.InletAirHumRat = 0.0
        self.OutletAirHumRat = 0.0
        self.InletAirEnthalpy = 0.0
        self.OutletAirEnthalpy = 0.0
        self.HeatingCoilLoad = 0.0
        self.HeatingCoilRate = 0.0
        self.FuelUseLoad = 0.0
        self.ElecUseLoad = 0.0
        self.FuelUseRate = 0.0
        self.ElecUseRate = 0.0
        self.Efficiency = 0.0
        self.NominalCapacity = 0.0
        self.DesiredOutletTemp = 0.0
        self.DesiredOutletHumRat = 0.0
        self.AvailTemperature = 0.0
        self.AirInletNodeNum = 0
        self.AirOutletNodeNum = 0
        self.TempSetPointNodeNum = 0
        self.Control = 0
        self.PLFCurveIndex = 0
        self.ParasiticElecLoad = 0.0
        self.ParasiticFuelConsumption = 0.0
        self.ParasiticFuelRate = 0.0
        self.ParasiticFuelCapacity = 0.0
        self.RTF = 0.0
        self.RTFErrorIndex = 0
        self.RTFErrorCount = 0
        self.PLFErrorIndex = 0
        self.PLFErrorCount = 0
        self.ReclaimHeatingCoilName = String()
        self.ReclaimHeatingSourceIndexNum = 0
        self.ReclaimHeatingSource = -1
        self.NumOfStages = 0
        self.MSNominalCapacity = DynamicVector[Float64]()
        self.MSEfficiency = DynamicVector[Float64]()
        self.MSParasiticElecLoad = DynamicVector[Float64]()
        self.DesiccantRegenerationCoil = False
        self.DesiccantDehumNum = 0
        self.FaultyCoilSATFlag = False
        self.FaultyCoilSATIndex = 0
        self.FaultyCoilSATOffset = 0.0
        self.reportCoilFinalSizes = True
        self.AirLoopNum = 0


struct HeatingCoilNumericFieldData:
    var FieldNames: DynamicVector[String]

    fn __init__(inout self):
        self.FieldNames = DynamicVector[String]()


fn SimulateHeatingCoilComponents(
    state: Pointer[UInt8],
    CompName: String,
    FirstHVACIteration: Bool,
    QCoilReq: Optional[Float64] = None,
    CompIndex: Optional[Int32] = None,
    QCoilActual: Optional[Pointer[Float64]] = None,
    SuppHeat: Optional[Bool] = None,
    fanOp: Optional[Int32] = None,
    PartLoadRatio: Optional[Float64] = None,
    StageNum: Optional[Int32] = None,
    SpeedRatio: Optional[Float64] = None,
) -> None:
    pass


fn GetHeatingCoilInput(state: Pointer[UInt8]) -> None:
    pass


fn InitHeatingCoil(state: Pointer[UInt8], CoilNum: Int32, FirstHVACIteration: Bool, QCoilRequired: Float64) -> None:
    pass


fn SizeHeatingCoil(state: Pointer[UInt8], CoilNum: Int32) -> None:
    pass


fn CalcElectricHeatingCoil(
    state: Pointer[UInt8], CoilNum: Int32, QCoilReq: Float64, fanOp: Int32, PartLoadRatio: Float64
) -> None:
    pass


fn CalcMultiStageElectricHeatingCoil(
    state: Pointer[UInt8],
    CoilNum: Int32,
    SpeedRatio: Float64,
    CycRatio: Float64,
    StageNum: Int32,
    fanOp: Int32,
    SuppHeat: Bool,
) -> None:
    pass


fn CalcFuelHeatingCoil(
    state: Pointer[UInt8], CoilNum: Int32, QCoilReq: Float64, fanOp: Int32, PartLoadRatio: Float64
) -> None:
    pass


fn CalcMultiStageGasHeatingCoil(
    state: Pointer[UInt8], CoilNum: Int32, SpeedRatio: Float64, CycRatio: Float64, StageNum: Int32, fanOp: Int32
) -> None:
    pass


fn CalcDesuperheaterHeatingCoil(state: Pointer[UInt8], CoilNum: Int32, QCoilReq: Float64) -> None:
    pass


fn UpdateHeatingCoil(state: Pointer[UInt8], CoilNum: Int32) -> None:
    pass


fn ReportHeatingCoil(state: Pointer[UInt8], CoilNum: Int32, coilIsSuppHeater: Bool) -> None:
    pass


fn GetCoilIndex(state: Pointer[UInt8], HeatingCoilName: String) -> Int32:
    return 0


fn CheckHeatingCoilSchedule(state: Pointer[UInt8], CompType: String, CompName: String, CompIndex: Int32) -> Float64:
    return 0.0


fn GetCoilCapacity(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Float64:
    return -1000.0


fn GetCoilAvailSched(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Pointer[UInt8]:
    return Pointer[UInt8]()


fn GetCoilInletNode(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn GetCoilOutletNode(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn GetHeatReclaimSourceIndex(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn GetCoilControlNodeNum(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn GetHeatingCoilTypeNum(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn GetHeatingCoilIndex(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn GetHeatingCoilPLFCurveIndex(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn GetHeatingCoilNumberOfStages(state: Pointer[UInt8], CoilType: String, CoilName: String) -> Int32:
    return 0


fn SetHeatingCoilData(
    state: Pointer[UInt8],
    CoilNum: Int32,
    DesiccantRegenerationCoil: Optional[Bool] = None,
    DesiccantDehumIndex: Optional[Int32] = None,
) -> None:
    pass


fn SetHeatingCoilAirLoopNumber(state: Pointer[UInt8], HeatingCoilName: String, AirLoopNum: Int32) -> None:
    pass

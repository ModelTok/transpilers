from sys import exit
from math import log, fabs

# ===== ENUMS =====

@value
struct CurveVars:
    alias Invalid = -1
    alias FracChargedLMTD = 0
    alias FracDischargedLMTD = 1
    alias LMTDMassFlow = 2
    alias LMTDFracCharged = 3
    alias Num = 4

@value
struct DetIce:
    alias Invalid = -1
    alias InsideMelt = 0
    alias OutsideMelt = 1
    alias Num = 2

@value
struct ITSType:
    alias Invalid = -1
    alias IceOnCoilInternal = 0
    alias IceOnCoilExternal = 1
    alias Num = 2

# ===== PROTOCOL STUBS FOR EXTERNAL DEPENDENCIES =====

struct Schedule:
    pass

struct PlantLoop:
    pass

struct PlantLocation:
    pass

struct EnergyPlusData:
    pass

# ===== DATA STRUCTURES =====

struct ThermalStorageSizingData:
    var name: String
    var onPeakStart: Float64
    var onPeakEnd: Float64
    var sizingFactor: Float64

    fn __init__(
        inout self,
        name: String = "",
        onPeakStart: Float64 = 0.0,
        onPeakEnd: Float64 = 0.0,
        sizingFactor: Float64 = 1.0
    ):
        self.name = name
        self.onPeakStart = onPeakStart
        self.onPeakEnd = onPeakEnd
        self.sizingFactor = sizingFactor

struct SimpleIceStorageData:
    var Name: String
    var ITSType: String
    var ITSType_Num: Int
    var MapNum: Int
    var UratePtr: Int
    var ITSNomCap: Float64
    var NomCapacityWasAutoSized: Bool
    var PltInletNodeNum: Int
    var PltOutletNodeNum: Int
    var plantLoc: UnsafePointer[PlantLocation]
    var DesignMassFlowRate: Float64
    var FreezeTemp: Float64
    var ResetXForITSFlag: Bool
    var MyEnvrnFlag: Bool
    var UAIceCh: Float64
    var UAIceDisCh: Float64
    var HLoss: Float64
    var XCurIceFrac: Float64
    var ITSMassFlowRate: Float64
    var ITSInletTemp: Float64
    var ITSOutletTemp: Float64
    var ITSOutletSetPointTemp: Float64
    var ITSCoolingRate: Float64
    var ITSCoolingEnergy: Float64
    var CheckEquipName: Bool
    var MyLoad: Float64
    var Urate: Float64
    var IceFracRemain: Float64
    var ITSChargingRate: Float64
    var ITSChargingEnergy: Float64
    var ITSmdot: Float64
    var ITSCoolingRate_rep: Float64
    var ITSCoolingEnergy_rep: Float64
    var MyPlantScanFlag: Bool
    var MyEnvrnFlag2: Bool
    var TESSizingIndex: Int

    fn __init__(inout self):
        self.Name = ""
        self.ITSType = ""
        self.ITSType_Num = -1
        self.MapNum = 0
        self.UratePtr = 0
        self.ITSNomCap = 0.0
        self.NomCapacityWasAutoSized = False
        self.PltInletNodeNum = 0
        self.PltOutletNodeNum = 0
        self.plantLoc = UnsafePointer[PlantLocation]()
        self.DesignMassFlowRate = 0.0
        self.FreezeTemp = 0.0
        self.ResetXForITSFlag = False
        self.MyEnvrnFlag = True
        self.UAIceCh = 0.0
        self.UAIceDisCh = 0.0
        self.HLoss = 0.0
        self.XCurIceFrac = 0.0
        self.ITSMassFlowRate = 0.0
        self.ITSInletTemp = 0.0
        self.ITSOutletTemp = 0.0
        self.ITSOutletSetPointTemp = 0.0
        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        self.CheckEquipName = True
        self.MyLoad = 0.0
        self.Urate = 0.0
        self.IceFracRemain = 0.0
        self.ITSChargingRate = 0.0
        self.ITSChargingEnergy = 0.0
        self.ITSmdot = 0.0
        self.ITSCoolingRate_rep = 0.0
        self.ITSCoolingEnergy_rep = 0.0
        self.MyPlantScanFlag = True
        self.MyEnvrnFlag2 = True
        self.TESSizingIndex = 0

    fn simulate(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        calledFromLocation: UnsafePointer[PlantLocation],
        FirstHVACIteration: Bool,
        inout CurLoad: Float64,
        inout RunFlag: Bool
    ):
        pass

    fn onInitLoopEquip(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        calledFromLocation: UnsafePointer[PlantLocation]
    ):
        self.oneTimeInit(state)
        self.size(state)

    fn oneTimeInit(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn initialize(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn size(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn CalcIceStorageDormant(inout self, state: UnsafePointer[EnergyPlusData]):
        self.ITSMassFlowRate = 0.0
        self.ITSInletTemp = 0.0
        self.ITSOutletTemp = 0.0
        self.ITSOutletSetPointTemp = 0.0
        self.ITSCoolingRate = 0.0
        self.ITSCoolingEnergy = 0.0
        self.Urate = 0.0

    fn CalcIceStorageCapacity(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        inout MaxCap: Float64,
        inout MinCap: Float64,
        inout OptCap: Float64
    ):
        pass

    fn CalcIceStorageDischarge(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        myLoad: Float64,
        RunFlag: Bool,
        MaxCap: Float64
    ):
        pass

    fn CalcQiceDischageMax(inout self, state: UnsafePointer[EnergyPlusData], inout QiceMin: Float64):
        pass

    fn CalcIceStorageCharge(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn CalcQiceChargeMaxByChiller(inout self, state: UnsafePointer[EnergyPlusData], inout QiceMaxByChiller: Float64):
        pass

    fn CalcQiceChargeMaxByITS(inout self, chillerOutletTemp: Float64, inout QiceMaxByITS: Float64):
        pass

    fn CalcUAIce(
        inout self,
        XCurIceFrac_loc: Float64,
        inout UAIceCh_loc: Float64,
        inout UAIceDisCh_loc: Float64,
        inout HLoss_loc: Float64
    ):
        pass

    fn UpdateNode(inout self, state: UnsafePointer[EnergyPlusData], myLoad: Float64, RunFlag: Bool):
        pass

    fn RecordOutput(inout self, myLoad: Float64, RunFlag: Bool):
        pass

    fn setupOutputVars(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

struct DetailedIceStorageData:
    var Name: String
    var availSched: UnsafePointer[Schedule]
    var NomCapacity: Float64
    var NomCapacityWasAutoSized: Bool
    var PlantInNodeNum: Int
    var PlantOutNodeNum: Int
    var plantLoc: UnsafePointer[PlantLocation]
    var DesignMassFlowRate: Float64
    var MapNum: Int
    var DischargeCurveName: String
    var DischargeCurveNum: Int
    var DischargeCurveTypeNum: Int
    var ChargeCurveName: String
    var ChargeCurveNum: Int
    var ChargeCurveTypeNum: Int
    var CurveFitTimeStep: Float64
    var DischargeParaElecLoad: Float64
    var ChargeParaElecLoad: Float64
    var TankLossCoeff: Float64
    var FreezingTemp: Float64
    var CompLoad: Float64
    var IceFracChange: Float64
    var IceFracRemaining: Float64
    var ThawProcessIndicator: String
    var ThawProcessIndex: Int
    var IceFracOnCoil: Float64
    var DischargingRate: Float64
    var DischargingEnergy: Float64
    var ChargingRate: Float64
    var ChargingEnergy: Float64
    var MassFlowRate: Float64
    var BypassMassFlowRate: Float64
    var TankMassFlowRate: Float64
    var InletTemp: Float64
    var OutletTemp: Float64
    var TankOutletTemp: Float64
    var ParasiticElecRate: Float64
    var ParasiticElecEnergy: Float64
    var DischargeIterErrors: Int
    var DischargeErrorCount: Int
    var ChargeIterErrors: Int
    var ChargeErrorCount: Int
    var ResetXForITSFlag: Bool
    var MyEnvrnFlag: Bool
    var CheckEquipName: Bool
    var MyPlantScanFlag: Bool
    var MyEnvrnFlag2: Bool
    var TESSizingIndex: Int

    fn __init__(inout self):
        self.Name = ""
        self.availSched = UnsafePointer[Schedule]()
        self.NomCapacity = 0.0
        self.NomCapacityWasAutoSized = False
        self.PlantInNodeNum = 0
        self.PlantOutNodeNum = 0
        self.plantLoc = UnsafePointer[PlantLocation]()
        self.DesignMassFlowRate = 0.0
        self.MapNum = 0
        self.DischargeCurveName = ""
        self.DischargeCurveNum = 0
        self.DischargeCurveTypeNum = -1
        self.ChargeCurveName = ""
        self.ChargeCurveNum = 0
        self.ChargeCurveTypeNum = -1
        self.CurveFitTimeStep = 1.0
        self.DischargeParaElecLoad = 0.0
        self.ChargeParaElecLoad = 0.0
        self.TankLossCoeff = 0.0
        self.FreezingTemp = 0.0
        self.CompLoad = 0.0
        self.IceFracChange = 0.0
        self.IceFracRemaining = 1.0
        self.ThawProcessIndicator = ""
        self.ThawProcessIndex = -1
        self.IceFracOnCoil = 1.0
        self.DischargingRate = 0.0
        self.DischargingEnergy = 0.0
        self.ChargingRate = 0.0
        self.ChargingEnergy = 0.0
        self.MassFlowRate = 0.0
        self.BypassMassFlowRate = 0.0
        self.TankMassFlowRate = 0.0
        self.InletTemp = 0.0
        self.OutletTemp = 0.0
        self.TankOutletTemp = 0.0
        self.ParasiticElecRate = 0.0
        self.ParasiticElecEnergy = 0.0
        self.DischargeIterErrors = 0
        self.DischargeErrorCount = 0
        self.ChargeIterErrors = 0
        self.ChargeErrorCount = 0
        self.ResetXForITSFlag = False
        self.MyEnvrnFlag = True
        self.CheckEquipName = True
        self.MyPlantScanFlag = True
        self.MyEnvrnFlag2 = True
        self.TESSizingIndex = 0

    fn simulate(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        calledFromLocation: UnsafePointer[PlantLocation],
        FirstHVACIteration: Bool,
        inout CurLoad: Float64,
        inout RunFlag: Bool
    ):
        pass

    fn onInitLoopEquip(
        inout self,
        state: UnsafePointer[EnergyPlusData],
        calledFromLocation: UnsafePointer[PlantLocation]
    ):
        self.oneTimeInit(state)
        self.size(state)

    fn oneTimeInit(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn initialize(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn size(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn SimDetailedIceStorage(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn UpdateDetailedIceStorage(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn ReportDetailedIceStorage(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

    fn setupOutputVars(inout self, state: UnsafePointer[EnergyPlusData]):
        pass

struct IceThermalStorageData:
    var getITSInput: Bool
    var NumThermalStorageSizing: Int
    var NumSimpleIceStorage: Int
    var NumDetailedIceStorage: Int
    var TotalNumIceStorage: Int

    fn __init__(inout self):
        self.getITSInput = True
        self.NumThermalStorageSizing = 0
        self.NumSimpleIceStorage = 0
        self.NumDetailedIceStorage = 0
        self.TotalNumIceStorage = 0

# ===== MODULE-LEVEL FUNCTIONS =====

fn GetIceStorageInput(state: UnsafePointer[EnergyPlusData]):
    pass

fn CalcDetIceStorLMTDstar(Tin: Float64, Tout: Float64, Tfr: Float64) -> Float64:
    let Tnom: Float64 = 10.0
    let DeltaTofMin: Float64 = 0.5
    let DeltaTifMin: Float64 = 1.0

    var DeltaTio = fabs(Tin - Tout)
    var DeltaTif = fabs(Tin - Tfr)
    var DeltaTof = fabs(Tout - Tfr)

    if DeltaTif < DeltaTifMin:
        DeltaTif = DeltaTifMin
    if DeltaTof < DeltaTofMin:
        DeltaTof = DeltaTofMin

    return (DeltaTio / log(DeltaTif / DeltaTof)) / Tnom

fn CalcQstar(
    state: UnsafePointer[EnergyPlusData],
    CurveIndex: Int,
    CurveIndVarType: Int,
    FracCharged: Float64,
    LMTDstar: Float64,
    MassFlowstar: Float64
) -> Float64:
    if CurveIndVarType == CurveVars.FracChargedLMTD:
        return fabs(Curve_CurveValue(state, CurveIndex, FracCharged, LMTDstar))
    elif CurveIndVarType == CurveVars.FracDischargedLMTD:
        return fabs(Curve_CurveValue(state, CurveIndex, (1.0 - FracCharged), LMTDstar))
    elif CurveIndVarType == CurveVars.LMTDMassFlow:
        return fabs(Curve_CurveValue(state, CurveIndex, LMTDstar, MassFlowstar))
    elif CurveIndVarType == CurveVars.LMTDFracCharged:
        return fabs(Curve_CurveValue(state, CurveIndex, LMTDstar, FracCharged))
    else:
        return 0.0

fn TempSItoIP(Temp: Float64) -> Float64:
    return (Temp * 9.0 / 5.0) + 32.0

fn TempIPtoSI(Temp: Float64) -> Float64:
    return (Temp - 32.0) * 5.0 / 9.0

fn UpdateIceFractions(state: UnsafePointer[EnergyPlusData]):
    pass

# ===== STUB FUNCTIONS FOR EXTERNAL DEPENDENCIES =====

@always_inline
fn Psychrometrics_CPCW(temp: Float64) -> Float64:
    return 4180.0

@always_inline
fn Curve_GetCurveIndex(state: UnsafePointer[EnergyPlusData], name: String) -> Int:
    return 0

@always_inline
fn Curve_CurveValue(state: UnsafePointer[EnergyPlusData], index: Int, x: Float64, y: Float64) -> Float64:
    return 0.0

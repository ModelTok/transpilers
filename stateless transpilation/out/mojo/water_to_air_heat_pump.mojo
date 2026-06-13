# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData
# - CompressorType: enum (local)
# - DataPlant.PlantEquipmentType: from EnergyPlus.Plant.DataPlant
# - HVAC.FanOp, HVAC.CompressorOp: from EnergyPlus.DataHVACGlobals
# - Fluid.RefrigProps, Fluid.GlycolProps: from EnergyPlus.FluidProperties
# - Psychrometrics: module from EnergyPlus
# - Curve: module from EnergyPlus.CurveManager
# - PlantUtilities: module from EnergyPlus
# - Node: module from EnergyPlus.NodeInputManager
# - General.SolveRoot2: from EnergyPlus.General
# - Util functions: from EnergyPlus.UtilityRoutines
# - math operations: Mojo math library

from math import pow as math_pow, exp, expm1, fabs, min as math_min, max as math_max
from memory.unsafe import Pointer


enum CompressorType:
    Invalid
    Reciprocating
    Rotary
    Scroll
    Num


@value
struct WatertoAirHPEquipConditions:
    var Name: String
    var availSched: Pointer[NoneType]
    var WatertoAirHPType: String
    var WAHPType: Pointer[NoneType]
    var Refrigerant: String
    var refrig: Pointer[NoneType]
    var SimFlag: Bool
    var InletAirMassFlowRate: Float64
    var OutletAirMassFlowRate: Float64
    var InletAirDBTemp: Float64
    var InletAirHumRat: Float64
    var OutletAirDBTemp: Float64
    var OutletAirHumRat: Float64
    var InletAirEnthalpy: Float64
    var OutletAirEnthalpy: Float64
    var InletWaterTemp: Float64
    var OutletWaterTemp: Float64
    var InletWaterMassFlowRate: Float64
    var OutletWaterMassFlowRate: Float64
    var DesignWaterMassFlowRate: Float64
    var DesignWaterVolFlowRate: Float64
    var InletWaterEnthalpy: Float64
    var OutletWaterEnthalpy: Float64
    var Power: Float64
    var Energy: Float64
    var QSensible: Float64
    var QLatent: Float64
    var QSource: Float64
    var EnergySensible: Float64
    var EnergyLatent: Float64
    var EnergySource: Float64
    var RunFrac: Float64
    var PartLoadRatio: Float64
    var HeatingCapacity: Float64
    var CoolingCapacity: Float64
    var QLoadTotal: Float64
    var EnergyLoadTotal: Float64
    var Twet_Rated: Float64
    var Gamma_Rated: Float64
    var MaxONOFFCyclesperHour: Float64
    var LatentCapacityTimeConstant: Float64
    var FanDelayTime: Float64
    var SourceSideUACoeff: Float64
    var LoadSideTotalUACoeff: Float64
    var LoadSideOutsideUACoeff: Float64
    var CompPistonDisp: Float64
    var CompClearanceFactor: Float64
    var CompSucPressDrop: Float64
    var SuperheatTemp: Float64
    var PowerLosses: Float64
    var LossFactor: Float64
    var RefVolFlowRate: Float64
    var VolumeRatio: Float64
    var LeakRateCoeff: Float64
    var SourceSideHTR1: Float64
    var SourceSideHTR2: Float64
    var PLFCurveIndex: Int32
    var HighPressCutoff: Float64
    var LowPressCutoff: Float64
    var compressorType: CompressorType
    var AirInletNodeNum: Int32
    var AirOutletNodeNum: Int32
    var WaterInletNodeNum: Int32
    var WaterOutletNodeNum: Int32
    var LowPressClgError: Int32
    var HighPressClgError: Int32
    var LowPressHtgError: Int32
    var HighPressHtgError: Int32
    var plantLoc: Pointer[NoneType]
    var solveRootStats: Pointer[NoneType]

    fn __init__(inout self):
        self.Name = String()
        self.availSched = Pointer[NoneType]()
        self.WatertoAirHPType = String()
        self.WAHPType = Pointer[NoneType]()
        self.Refrigerant = String()
        self.refrig = Pointer[NoneType]()
        self.SimFlag = False
        self.InletAirMassFlowRate = 0.0
        self.OutletAirMassFlowRate = 0.0
        self.InletAirDBTemp = 0.0
        self.InletAirHumRat = 0.0
        self.OutletAirDBTemp = 0.0
        self.OutletAirHumRat = 0.0
        self.InletAirEnthalpy = 0.0
        self.OutletAirEnthalpy = 0.0
        self.InletWaterTemp = 0.0
        self.OutletWaterTemp = 0.0
        self.InletWaterMassFlowRate = 0.0
        self.OutletWaterMassFlowRate = 0.0
        self.DesignWaterMassFlowRate = 0.0
        self.DesignWaterVolFlowRate = 0.0
        self.InletWaterEnthalpy = 0.0
        self.OutletWaterEnthalpy = 0.0
        self.Power = 0.0
        self.Energy = 0.0
        self.QSensible = 0.0
        self.QLatent = 0.0
        self.QSource = 0.0
        self.EnergySensible = 0.0
        self.EnergyLatent = 0.0
        self.EnergySource = 0.0
        self.RunFrac = 0.0
        self.PartLoadRatio = 0.0
        self.HeatingCapacity = 0.0
        self.CoolingCapacity = 0.0
        self.QLoadTotal = 0.0
        self.EnergyLoadTotal = 0.0
        self.Twet_Rated = 0.0
        self.Gamma_Rated = 0.0
        self.MaxONOFFCyclesperHour = 0.0
        self.LatentCapacityTimeConstant = 0.0
        self.FanDelayTime = 0.0
        self.SourceSideUACoeff = 0.0
        self.LoadSideTotalUACoeff = 0.0
        self.LoadSideOutsideUACoeff = 0.0
        self.CompPistonDisp = 0.0
        self.CompClearanceFactor = 0.0
        self.CompSucPressDrop = 0.0
        self.SuperheatTemp = 0.0
        self.PowerLosses = 0.0
        self.LossFactor = 0.0
        self.RefVolFlowRate = 0.0
        self.VolumeRatio = 0.0
        self.LeakRateCoeff = 0.0
        self.SourceSideHTR1 = 0.0
        self.SourceSideHTR2 = 0.0
        self.PLFCurveIndex = 0
        self.HighPressCutoff = 0.0
        self.LowPressCutoff = 0.0
        self.compressorType = CompressorType.Invalid
        self.AirInletNodeNum = 0
        self.AirOutletNodeNum = 0
        self.WaterInletNodeNum = 0
        self.WaterOutletNodeNum = 0
        self.LowPressClgError = 0
        self.HighPressClgError = 0
        self.LowPressHtgError = 0
        self.HighPressHtgError = 0
        self.plantLoc = Pointer[NoneType]()
        self.solveRootStats = Pointer[NoneType]()


@value
struct WaterToAirHeatPumpData:
    var NumWatertoAirHPs: Int32
    var CheckEquipName: DynamicVector[Bool]
    var GetCoilsInputFlag: Bool
    var MyOneTimeFlag: Bool
    var firstTime: Bool
    var WatertoAirHP: DynamicVector[WatertoAirHPEquipConditions]
    var initialQSource: Float64
    var initialQLoad: Float64
    var MyPlantScanFlag: DynamicVector[Bool]
    var MyEnvrnFlag: DynamicVector[Bool]
    var initialQSource_calc: Float64
    var initialQLoadTotal_calc: Float64
    var CompSuctionTemp: Float64
    var LoadSideInletDBTemp_Init: Float64
    var LoadSideInletHumRat_Init: Float64
    var LoadSideAirInletEnth_Init: Float64

    fn __init__(inout self):
        self.NumWatertoAirHPs = 0
        self.CheckEquipName = DynamicVector[Bool]()
        self.GetCoilsInputFlag = True
        self.MyOneTimeFlag = True
        self.firstTime = True
        self.WatertoAirHP = DynamicVector[WatertoAirHPEquipConditions]()
        self.initialQSource = 0.0
        self.initialQLoad = 0.0
        self.MyPlantScanFlag = DynamicVector[Bool]()
        self.MyEnvrnFlag = DynamicVector[Bool]()
        self.initialQSource_calc = 0.0
        self.initialQLoadTotal_calc = 0.0
        self.CompSuctionTemp = 0.0
        self.LoadSideInletDBTemp_Init = 0.0
        self.LoadSideInletHumRat_Init = 0.0
        self.LoadSideAirInletEnth_Init = 0.0


fn SimWatertoAirHP(inout state: NoneType, CompName: String, inout CompIndex: Int32, DesignAirflow: Float64, fanOp: Int32, FirstHVACIteration: Bool, InitFlag: Bool, SensLoad: Float64, LatentLoad: Float64, compressorOp: Int32, PartLoadRatio: Float64):
    pass


fn GetWatertoAirHPInput(inout state: NoneType):
    pass


fn InitWatertoAirHP(inout state: NoneType, HPNum: Int32, InitFlag: Bool, SensLoad: Float64, LatentLoad: Float64, DesignAirFlow: Float64, PartLoadRatio: Float64):
    pass


fn CalcWatertoAirHPCooling(inout state: NoneType, HPNum: Int32, fanOp: Int32, FirstHVACIteration: Bool, InitFlag: Bool, SensDemand: Float64, compressorOp: Int32, PartLoadRatio: Float64):
    pass


fn CalcWatertoAirHPHeating(inout state: NoneType, HPNum: Int32, fanOp: Int32, FirstHVACIteration: Bool, InitFlag: Bool, SensDemand: Float64, compressorOp: Int32, PartLoadRatio: Float64):
    pass


fn UpdateWatertoAirHP(inout state: NoneType, HPNum: Int32):
    pass


fn CalcEffectiveSHR(inout state: NoneType, HPNum: Int32, SHRss: Float64, fanOp: Int32, RTF: Float64, QLatRated: Float64, QLatActual: Float64, EnteringDB: Float64, EnteringWB: Float64) -> Float64:
    return 0.0


fn DegradF(inout state: NoneType, glycol: Pointer[NoneType], Temp: Float64) -> Float64:
    return 0.0


fn GetCoilIndex(inout state: NoneType, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int32:
    return 0


fn GetCoilCapacity(inout state: NoneType, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Float64:
    return 0.0


fn GetCoilInletNode(inout state: NoneType, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int32:
    return 0


fn GetCoilOutletNode(inout state: NoneType, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int32:
    return 0

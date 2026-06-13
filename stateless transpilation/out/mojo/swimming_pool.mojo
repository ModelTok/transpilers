from memory import UnsafePointer
from math import pow, abs as math_abs
import math

alias Real64 = Float64

struct PlantLocation:
    pass

struct Schedule:
    name: String
    fn getCurrentVal(self) -> Float64:
        return 0.0
    fn checkMinMaxVals(self, state: EnergyPlusData, lo_clusive: String, lo_val: Float64, hi_clusive: String, hi_val: Float64) -> Bool:
        return True

struct GlycolProps:
    fn getDensity(self, state: EnergyPlusData, temp: Float64, routine_name: String) -> Float64:
        return 0.0
    fn getSpecificHeat(self, state: EnergyPlusData, temp: Float64, routine_name: String) -> Float64:
        return 0.0

trait PlantComponent:
    fn simulate(self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
        pass

struct EnergyPlusData:
    pass

struct SwimmingPoolData(PlantComponent):
    var Name: String
    var SurfaceName: String
    var SurfacePtr: Int32
    var ZoneName: String
    var ZonePtr: Int32
    var WaterInletNodeName: String
    var WaterInletNode: Int32
    var WaterOutletNodeName: String
    var WaterOutletNode: Int32
    var HWplantLoc: PlantLocation
    var WaterVolFlowMax: Float64
    var WaterMassFlowRateMax: Float64
    var AvgDepth: Float64
    var ActivityFactor: Float64
    var activityFactorSched: UnsafePointer[Schedule]
    var CurActivityFactor: Float64
    var makeupWaterSupplySched: UnsafePointer[Schedule]
    var CurMakeupWaterTemp: Float64
    var coverSched: UnsafePointer[Schedule]
    var CurCoverSchedVal: Float64
    var CoverEvapFactor: Float64
    var CoverConvFactor: Float64
    var CoverSWRadFactor: Float64
    var CoverLWRadFactor: Float64
    var CurCoverEvapFac: Float64
    var CurCoverConvFac: Float64
    var CurCoverSWRadFac: Float64
    var CurCoverLWRadFac: Float64
    var RadConvertToConvect: Float64
    var MiscPowerFactor: Float64
    var setPtTempSched: UnsafePointer[Schedule]
    var CurSetPtTemp: Float64
    var MaxNumOfPeople: Float64
    var peopleSched: UnsafePointer[Schedule]
    var peopleHeatGainSched: UnsafePointer[Schedule]
    var PeopleHeatGain: Float64
    var glycol: UnsafePointer[GlycolProps]
    var WaterMass: Float64
    var SatPressPoolWaterTemp: Float64
    var PartPressZoneAirTemp: Float64
    var PoolWaterTemp: Float64
    var WaterInletTemp: Float64
    var WaterOutletTemp: Float64
    var WaterMassFlowRate: Float64
    var MakeUpWaterMassFlowRate: Float64
    var MakeUpWaterMass: Float64
    var MakeUpWaterVolFlowRate: Float64
    var MakeUpWaterVol: Float64
    var HeatPower: Float64
    var HeatEnergy: Float64
    var MiscEquipPower: Float64
    var MiscEquipEnergy: Float64
    var RadConvertToConvectRep: Float64
    var EvapHeatLossRate: Float64
    var EvapEnergyLoss: Float64
    var MyOneTimeFlag: Bool
    var MyEnvrnFlagGeneral: Bool
    var MyPlantScanFlagPool: Bool
    var QPoolSrcAvg: Float64
    var HeatTransCoefsAvg: Float64
    var ZeroPoolSourceSumHATsurf: Float64
    var LastQPoolSrc: Float64
    var LastHeatTransCoefs: Float64
    var LastSysTimeElapsed: Float64
    var LastTimeStepSys: Float64
    
    fn __init__(inout self):
        self.Name = String()
        self.SurfaceName = String()
        self.SurfacePtr = 0
        self.ZoneName = String()
        self.ZonePtr = 0
        self.WaterInletNodeName = String()
        self.WaterInletNode = 0
        self.WaterOutletNodeName = String()
        self.WaterOutletNode = 0
        self.HWplantLoc = PlantLocation()
        self.WaterVolFlowMax = 0.0
        self.WaterMassFlowRateMax = 0.0
        self.AvgDepth = 0.0
        self.ActivityFactor = 0.0
        self.activityFactorSched = UnsafePointer[Schedule]()
        self.CurActivityFactor = 0.0
        self.makeupWaterSupplySched = UnsafePointer[Schedule]()
        self.CurMakeupWaterTemp = 0.0
        self.coverSched = UnsafePointer[Schedule]()
        self.CurCoverSchedVal = 0.0
        self.CoverEvapFactor = 0.0
        self.CoverConvFactor = 0.0
        self.CoverSWRadFactor = 0.0
        self.CoverLWRadFactor = 0.0
        self.CurCoverEvapFac = 0.0
        self.CurCoverConvFac = 0.0
        self.CurCoverSWRadFac = 0.0
        self.CurCoverLWRadFac = 0.0
        self.RadConvertToConvect = 0.0
        self.MiscPowerFactor = 0.0
        self.setPtTempSched = UnsafePointer[Schedule]()
        self.CurSetPtTemp = 23.0
        self.MaxNumOfPeople = 0.0
        self.peopleSched = UnsafePointer[Schedule]()
        self.peopleHeatGainSched = UnsafePointer[Schedule]()
        self.PeopleHeatGain = 0.0
        self.glycol = UnsafePointer[GlycolProps]()
        self.WaterMass = 0.0
        self.SatPressPoolWaterTemp = 0.0
        self.PartPressZoneAirTemp = 0.0
        self.PoolWaterTemp = 23.0
        self.WaterInletTemp = 0.0
        self.WaterOutletTemp = 0.0
        self.WaterMassFlowRate = 0.0
        self.MakeUpWaterMassFlowRate = 0.0
        self.MakeUpWaterMass = 0.0
        self.MakeUpWaterVolFlowRate = 0.0
        self.MakeUpWaterVol = 0.0
        self.HeatPower = 0.0
        self.HeatEnergy = 0.0
        self.MiscEquipPower = 0.0
        self.MiscEquipEnergy = 0.0
        self.RadConvertToConvectRep = 0.0
        self.EvapHeatLossRate = 0.0
        self.EvapEnergyLoss = 0.0
        self.MyOneTimeFlag = True
        self.MyEnvrnFlagGeneral = True
        self.MyPlantScanFlagPool = True
        self.QPoolSrcAvg = 0.0
        self.HeatTransCoefsAvg = 0.0
        self.ZeroPoolSourceSumHATsurf = 0.0
        self.LastQPoolSrc = 0.0
        self.LastHeatTransCoefs = 0.0
        self.LastSysTimeElapsed = 0.0
        self.LastTimeStepSys = 0.0

    @staticmethod
    fn factory(state: EnergyPlusData, object_name: String) -> UnsafePointer[SwimmingPoolData]:
        if state.dataSwimmingPools.getSwimmingPoolInput:
            GetSwimmingPool(state)
            state.dataSwimmingPools.getSwimmingPoolInput = False
        return UnsafePointer[SwimmingPoolData]()

    fn simulate(self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
        pass

    fn ErrorCheckSetupPoolSurface(self, state: EnergyPlusData, Alpha1: String, Alpha2: String, cAlphaField2: String, inout ErrorsFound: Bool):
        pass

    fn initialize(self, state: EnergyPlusData, FirstHVACIteration: Bool):
        pass

    fn setupOutputVars(self, state: EnergyPlusData):
        pass

    fn initSwimmingPoolPlantLoopIndex(self, state: EnergyPlusData):
        pass

    fn initSwimmingPoolPlantNodeFlow(self, state: EnergyPlusData):
        pass

    fn calculate(self, state: EnergyPlusData):
        pass

    fn calcMassFlowRate(self, state: EnergyPlusData, inout massFlowRate: Float64, TH22: Float64, TLoopInletTemp: Float64):
        pass

    fn calcSwimmingPoolEvap(self, state: EnergyPlusData, inout EvapRate: Float64, SurfNum: Int32, MAT: Float64, HumRat: Float64):
        pass

    fn update(self, state: EnergyPlusData):
        pass

    fn oneTimeInit_new(self, state: EnergyPlusData):
        pass

    fn oneTimeInit(self, state: EnergyPlusData):
        pass

    fn report(self, state: EnergyPlusData):
        pass

struct SwimmingPoolsData:
    var NumSwimmingPools: Int32
    var CheckEquipName: UnsafePointer[Bool]
    var getSwimmingPoolInput: Bool
    var Pool: UnsafePointer[SwimmingPoolData]
    
    fn __init__(inout self):
        self.NumSwimmingPools = 0
        self.CheckEquipName = UnsafePointer[Bool]()
        self.getSwimmingPoolInput = True
        self.Pool = UnsafePointer[SwimmingPoolData]()

@export
fn GetSwimmingPool(state: EnergyPlusData):
    pass

@export
fn UpdatePoolSourceValAvg(state: EnergyPlusData, inout SwimmingPoolOn: Bool):
    pass

fn MakeUpWaterVolFlowFunct(MakeUpWaterMassFlowRate: Float64, Density: Float64) -> Float64:
    return MakeUpWaterMassFlowRate / Density

fn MakeUpWaterVolFunct(MakeUpWaterMass: Float64, Density: Float64) -> Float64:
    return MakeUpWaterMass / Density

fn ShowSevereError(state: EnergyPlusData, msg: String):
    pass

fn ShowWarningError(state: EnergyPlusData, msg: String):
    pass

fn ShowContinueError(state: EnergyPlusData, msg: String):
    pass

fn ShowFatalError(state: EnergyPlusData, msg: String):
    pass

fn ShowSevereItemNotFound(state: EnergyPlusData, eoh: String, field: String, value: String):
    pass

fn ShowSevereEmptyField(state: EnergyPlusData, eoh: String, field: String):
    pass

fn SetupOutputVariable(state: EnergyPlusData, *args):
    pass

fn SameString(a: String, b: String) -> Bool:
    return a.lower() == b.lower()

fn HeatBalanceSurfaceManager_CalcHeatBalanceInsideSurf(state: EnergyPlusData):
    pass

fn PlantUtilities_SetComponentFlowRate(state: EnergyPlusData, mdot: Float64, inlet: Int32, outlet: Int32, loc: PlantLocation):
    pass

fn PlantUtilities_InitComponentNodes(state: EnergyPlusData, minflow: Float64, maxflow: Float64, inlet: Int32, outlet: Int32):
    pass

fn PlantUtilities_RegisterPlantCompDesignFlow(state: EnergyPlusData, inlet: Int32, flow: Float64):
    pass

fn PlantUtilities_SafeCopyPlantNode(state: EnergyPlusData, inlet: Int32, outlet: Int32):
    pass

fn PlantUtilities_ScanPlantLoopsForObject(state: EnergyPlusData, name: String, equip_type: Int32, loc: PlantLocation, inout errFlag: Bool):
    pass

fn Psychrometrics_PsyPsatFnTemp(state: EnergyPlusData, temp: Float64, routine: String) -> Float64:
    return 0.0

fn Psychrometrics_PsyRhFnTdbWPb(state: EnergyPlusData, tdb: Float64, w: Float64, pb: Float64) -> Float64:
    return 0.0

fn Psychrometrics_PsyHfgAirFnWTdb(w: Float64, tdb: Float64) -> Float64:
    return 0.0

fn Sched_GetSchedule(state: EnergyPlusData, name: String) -> UnsafePointer[Schedule]:
    return UnsafePointer[Schedule]()

fn Sched_ShowSevereBadMinMax(state: EnergyPlusData, eoh: String, field: String, name: String, lo_clusive: String, lo_val: Float64, hi_clusive: String, hi_val: Float64):
    pass

fn Fluid_GetWater(state: EnergyPlusData) -> UnsafePointer[GlycolProps]:
    return UnsafePointer[GlycolProps]()

fn Node_GetOnlySingleNode(state: EnergyPlusData, name: String, errfound: Bool, *args) -> Int32:
    return 0

fn Node_TestCompSet(state: EnergyPlusData, *args):
    pass

from memory import memset_pattern
from sys import info as sys_info
import math


struct ReportVars:
    var PumpingPower: Float64
    var QGenerator: Float64
    var QEvap: Float64
    var QCond: Float64
    var PumpingEnergy: Float64
    var GeneratorEnergy: Float64
    var EvapEnergy: Float64
    var CondEnergy: Float64
    var CondInletTemp: Float64
    var EvapInletTemp: Float64
    var CondOutletTemp: Float64
    var EvapOutletTemp: Float64
    var Evapmdot: Float64
    var Condmdot: Float64
    var Genmdot: Float64
    var SteamMdot: Float64
    var ActualCOP: Float64
    var ChillerPartLoadRatio: Float64
    var ChillerCyclingFrac: Float64
    var LoopLoss: Float64

    fn __init__(inout self):
        self.PumpingPower = 0.0
        self.QGenerator = 0.0
        self.QEvap = 0.0
        self.QCond = 0.0
        self.PumpingEnergy = 0.0
        self.GeneratorEnergy = 0.0
        self.EvapEnergy = 0.0
        self.CondEnergy = 0.0
        self.CondInletTemp = 0.0
        self.EvapInletTemp = 0.0
        self.CondOutletTemp = 0.0
        self.EvapOutletTemp = 0.0
        self.Evapmdot = 0.0
        self.Condmdot = 0.0
        self.Genmdot = 0.0
        self.SteamMdot = 0.0
        self.ActualCOP = 0.0
        self.ChillerPartLoadRatio = 0.0
        self.ChillerCyclingFrac = 0.0
        self.LoopLoss = 0.0


struct IndirectAbsorberSpecs:
    var Name: String
    var NomCap: Float64
    var NomCapWasAutoSized: Bool
    var NomPumpPower: Float64
    var NomPumpPowerWasAutoSized: Bool
    var EvapVolFlowRate: Float64
    var EvapVolFlowRateWasAutoSized: Bool
    var CondVolFlowRate: Float64
    var CondVolFlowRateWasAutoSized: Bool
    var EvapMassFlowRateMax: Float64
    var CondMassFlowRateMax: Float64
    var GenMassFlowRateMax: Float64
    var MinPartLoadRat: Float64
    var MaxPartLoadRat: Float64
    var OptPartLoadRat: Float64
    var TempDesCondIn: Float64
    var MinCondInletTemp: Float64
    var MinGeneratorInletTemp: Float64
    var TempLowLimitEvapOut: Float64
    var GeneratorVolFlowRate: Float64
    var GeneratorVolFlowRateWasAutoSized: Bool
    var GeneratorSubcool: Float64
    var LoopSubcool: Float64
    var GeneratorDeltaTemp: Float64
    var GeneratorDeltaTempWasAutoSized: Bool
    var SizFac: Float64
    var EvapInletNodeNum: Int32
    var EvapOutletNodeNum: Int32
    var CondInletNodeNum: Int32
    var CondOutletNodeNum: Int32
    var GeneratorInletNodeNum: Int32
    var GeneratorOutletNodeNum: Int32
    var GeneratorInputCurvePtr: Int32
    var PumpPowerCurvePtr: Int32
    var CapFCondenserTempPtr: Int32
    var CapFEvaporatorTempPtr: Int32
    var CapFGeneratorTempPtr: Int32
    var HeatInputFCondTempPtr: Int32
    var HeatInputFEvapTempPtr: Int32
    var ErrCount2: Int32
    var GenHeatSourceType: Int32
    var steam: NoneType
    var Available: Bool
    var ON: Bool
    var FlowMode: Int32
    var ModulatedFlowSetToLoop: Bool
    var ModulatedFlowErrDone: Bool
    var MinCondInletTempCtr: Int32
    var MinCondInletTempIndex: Int32
    var MinGenInletTempCtr: Int32
    var MinGenInletTempIndex: Int32
    var CWPlantLoc: NoneType
    var CDPlantLoc: NoneType
    var GenPlantLoc: NoneType
    var FaultyChillerSWTFlag: Bool
    var FaultyChillerSWTIndex: Int32
    var FaultyChillerSWTOffset: Float64
    var PossibleSubcooling: Bool
    var CondMassFlowRate: Float64
    var EvapMassFlowRate: Float64
    var GenMassFlowRate: Float64
    var CondOutletTemp: Float64
    var EvapOutletTemp: Float64
    var GenOutletTemp: Float64
    var SteamOutletEnthalpy: Float64
    var PumpingPower: Float64
    var PumpingEnergy: Float64
    var QGenerator: Float64
    var GeneratorEnergy: Float64
    var QEvaporator: Float64
    var EvaporatorEnergy: Float64
    var QCondenser: Float64
    var CondenserEnergy: Float64
    var ChillerONOFFCyclingFrac: Float64
    var EnergyLossToEnvironment: Float64
    var GenInputOutputNodesUsed: Bool
    var MyOneTimeFlag: Bool
    var MyEnvrnFlag: Bool
    var Report: ReportVars
    var EquipFlowCtrl: Int32
    var water: NoneType

    fn __init__(inout self):
        self.Name = String()
        self.NomCap = 0.0
        self.NomCapWasAutoSized = False
        self.NomPumpPower = 0.0
        self.NomPumpPowerWasAutoSized = False
        self.EvapVolFlowRate = 0.0
        self.EvapVolFlowRateWasAutoSized = False
        self.CondVolFlowRate = 0.0
        self.CondVolFlowRateWasAutoSized = False
        self.EvapMassFlowRateMax = 0.0
        self.CondMassFlowRateMax = 0.0
        self.GenMassFlowRateMax = 0.0
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.TempDesCondIn = 0.0
        self.MinCondInletTemp = 0.0
        self.MinGeneratorInletTemp = 0.0
        self.TempLowLimitEvapOut = 0.0
        self.GeneratorVolFlowRate = 0.0
        self.GeneratorVolFlowRateWasAutoSized = False
        self.GeneratorSubcool = 0.0
        self.LoopSubcool = 0.0
        self.GeneratorDeltaTemp = -99999.0
        self.GeneratorDeltaTempWasAutoSized = True
        self.SizFac = 0.0
        self.EvapInletNodeNum = 0
        self.EvapOutletNodeNum = 0
        self.CondInletNodeNum = 0
        self.CondOutletNodeNum = 0
        self.GeneratorInletNodeNum = 0
        self.GeneratorOutletNodeNum = 0
        self.GeneratorInputCurvePtr = 0
        self.PumpPowerCurvePtr = 0
        self.CapFCondenserTempPtr = 0
        self.CapFEvaporatorTempPtr = 0
        self.CapFGeneratorTempPtr = 0
        self.HeatInputFCondTempPtr = 0
        self.HeatInputFEvapTempPtr = 0
        self.ErrCount2 = 0
        self.GenHeatSourceType = 0
        self.steam = NoneType()
        self.Available = False
        self.ON = False
        self.FlowMode = 0
        self.ModulatedFlowSetToLoop = False
        self.ModulatedFlowErrDone = False
        self.MinCondInletTempCtr = 0
        self.MinCondInletTempIndex = 0
        self.MinGenInletTempCtr = 0
        self.MinGenInletTempIndex = 0
        self.CWPlantLoc = NoneType()
        self.CDPlantLoc = NoneType()
        self.GenPlantLoc = NoneType()
        self.FaultyChillerSWTFlag = False
        self.FaultyChillerSWTIndex = 0
        self.FaultyChillerSWTOffset = 0.0
        self.PossibleSubcooling = False
        self.CondMassFlowRate = 0.0
        self.EvapMassFlowRate = 0.0
        self.GenMassFlowRate = 0.0
        self.CondOutletTemp = 0.0
        self.EvapOutletTemp = 0.0
        self.GenOutletTemp = 0.0
        self.SteamOutletEnthalpy = 0.0
        self.PumpingPower = 0.0
        self.PumpingEnergy = 0.0
        self.QGenerator = 0.0
        self.GeneratorEnergy = 0.0
        self.QEvaporator = 0.0
        self.EvaporatorEnergy = 0.0
        self.QCondenser = 0.0
        self.CondenserEnergy = 0.0
        self.ChillerONOFFCyclingFrac = 0.0
        self.EnergyLossToEnvironment = 0.0
        self.GenInputOutputNodesUsed = False
        self.MyOneTimeFlag = True
        self.MyEnvrnFlag = True
        self.Report = ReportVars()
        self.EquipFlowCtrl = 0
        self.water = NoneType()

    @staticmethod
    fn factory(state: NoneType, object_name: String) -> Self:
        return Self()

    fn simulate(inout self, state: NoneType, calledFromLocation: NoneType, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool) -> None:
        pass

    fn getDesignCapacities(self, state: NoneType, calledFromLocation: NoneType) -> Tuple[Float64, Float64, Float64]:
        return (0.0, 0.0, 0.0)

    fn getSizingFactor(self) -> Float64:
        return self.SizFac

    fn onInitLoopEquip(inout self, state: NoneType, calledFromLocation: NoneType) -> None:
        pass

    fn oneTimeInit(inout self, state: NoneType) -> None:
        pass

    fn initialize(inout self, state: NoneType, RunFlag: Bool, MyLoad: Float64) -> None:
        pass

    fn setupOutputVars(inout self, state: NoneType) -> None:
        pass

    fn sizeChiller(inout self, state: NoneType) -> None:
        pass

    fn calculate(inout self, state: NoneType, MyLoad: Float64, RunFlag: Bool) -> None:
        pass

    fn updateRecords(inout self, state: NoneType, MyLoad: Float64, RunFlag: Bool) -> None:
        pass


fn GetIndirectAbsorberInput(state: NoneType) -> None:
    pass


fn ShowFatalError(state: NoneType, msg: String) -> None:
    pass


fn ShowSevereError(state: NoneType, msg: String) -> None:
    pass


fn ShowWarningError(state: NoneType, msg: String) -> None:
    pass


fn ShowContinueError(state: NoneType, msg: String) -> None:
    pass


fn ShowContinueErrorTimeStamp(state: NoneType, msg: String) -> None:
    pass


fn ShowRecurringWarningErrorAtEnd(state: NoneType, msg: String, idx: Int32, val1: Float64 = 0.0, val2: Float64 = 0.0) -> None:
    pass


fn ShowMessage(state: NoneType, msg: String) -> None:
    pass


fn SetupOutputVariable(state: NoneType) -> None:
    pass


fn SetupEMSInternalVariable(state: NoneType) -> None:
    pass


fn BaseSizer_reportSizerOutput(state: NoneType) -> None:
    pass


fn OutputReportPredefined_PreDefTableEntry(state: NoneType) -> None:
    pass


fn PlantUtilities_ScanPlantLoopsForObject(state: NoneType) -> None:
    pass


fn PlantUtilities_InterConnectTwoPlantLoopSides(state: NoneType) -> None:
    pass


fn PlantUtilities_InitComponentNodes(state: NoneType) -> None:
    pass


fn PlantUtilities_SetComponentFlowRate(state: NoneType) -> None:
    pass


fn PlantUtilities_UpdateChillerComponentCondenserSide(state: NoneType) -> None:
    pass


fn PlantUtilities_UpdateAbsorberChillerComponentGeneratorSide(state: NoneType) -> None:
    pass


fn PlantUtilities_RegisterPlantCompDesignFlow(state: NoneType) -> None:
    pass


fn PlantUtilities_SafeCopyPlantNode(state: NoneType) -> None:
    pass


fn PlantUtilities_MyPlantSizingIndex(state: NoneType) -> Int32:
    return 0


fn Curve_GetCurveIndex(state: NoneType, name: String) -> Int32:
    return 0


fn Curve_CurveValue(state: NoneType, idx: Int32, x: Float64) -> Float64:
    return 1.0


fn Curve_CheckCurveDims(state: NoneType) -> Bool:
    return False


fn Fluid_GetSteam(state: NoneType) -> NoneType:
    return NoneType()


fn Fluid_GetWater(state: NoneType) -> NoneType:
    return NoneType()


fn GlobalNames_VerifyUniqueChillerName(state: NoneType) -> None:
    pass


fn Node_GetOnlySingleNode(state: NoneType) -> Int32:
    return 0


fn Node_TestCompSet(state: NoneType) -> None:
    pass


fn Util_SameString(a: String, b: String) -> Bool:
    return False


fn EMSManager_CheckIfNodeSetPointManagedByEMS(state: NoneType) -> None:
    pass

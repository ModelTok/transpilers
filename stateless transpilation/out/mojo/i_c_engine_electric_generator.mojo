# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object holding module data (source: Data/EnergyPlusData)
# - Curve: curve object type (source: CurveManager)
# - PlantComponent: base class for plant components (source: PlantComponent)
# - PlantLocation: plant loop location (source: DataPlant)
# - GeneratorType: enum for generator types (source: DataGlobalConstants)
# - Constant.eFuel: enum for fuel types (source: DataGlobalConstants)
# - Node functions: GetOnlySingleNode, etc. (source: NodeInputManager)
# - Curve.GetCurve: get curve by name (source: CurveManager)
# - Show* functions: ShowFatalError, ShowSevereError, etc. (source: UtilityRoutines)
# - SetupOutputVariable: output variable setup (source: OutputProcessor)
# - PlantUtilities: component flow/heat recovery updates (source: PlantUtilities)
# - InputProcessor: getNumObjectsFound, getObjectItem (source: InputProcessing)
# - Array1D: dynamic array type (source: ObjexxFCL)

from math import exp, fabs, fmax, fmin, pow as math_pow

alias Real64 = Float64
alias Float = Float32

struct Curve:
    pass

struct PlantLocation:
    var loopNum: Int32
    var loopSideNum: Int32
    var branchNum: Int32
    var compNum: Int32
    var loop: UnsafePointer[UInt8]
    
    fn __init__(inout self):
        self.loopNum = 0
        self.loopSideNum = 0
        self.branchNum = 0
        self.compNum = 0
        self.loop = UnsafePointer[UInt8]()

struct Node:
    var Temp: Real64
    var MassFlowRate: Real64
    
    fn __init__(inout self):
        self.Temp = 0.0
        self.MassFlowRate = 0.0

struct DataLoopNodes:
    var Node: UnsafePointer[Node]
    var size: Int32
    
    fn __init__(inout self):
        self.Node = UnsafePointer[Node]()
        self.size = 0

struct DataHVACGlobals:
    var TimeStepSysSec: Real64
    
    fn __init__(inout self):
        self.TimeStepSysSec = 0.0

struct DataGlobal:
    var BeginEnvrnFlag: Bool
    
    fn __init__(inout self):
        self.BeginEnvrnFlag = False

struct DataIPShortCut:
    var cCurrentModuleObject: StringRef
    
    fn __init__(inout self):
        self.cCurrentModuleObject = StringRef("")

struct InputProcessorData:
    var inputProcessor: UnsafePointer[UInt8]
    
    fn __init__(inout self):
        self.inputProcessor = UnsafePointer[UInt8]()

struct ICEngElectGenData:
    var NumICEngineGenerators: Int32
    var getICEInput: Bool
    var ICEngineGenerator: UnsafePointer[ICEngineGeneratorSpecs]
    
    fn __init__(inout self):
        self.NumICEngineGenerators = 0
        self.getICEInput = True
        self.ICEngineGenerator = UnsafePointer[ICEngineGeneratorSpecs]()

struct PlntData:
    var PlantLoop: UnsafePointer[UInt8]
    
    fn __init__(inout self):
        self.PlantLoop = UnsafePointer[UInt8]()

struct EnergyPlusData:
    var dataLoopNodes: DataLoopNodes
    var dataHVACGlobal: DataHVACGlobals
    var dataGlobal: DataGlobal
    var dataIPShortCut: DataIPShortCut
    var dataInputProcessing: InputProcessorData
    var dataICEngElectGen: ICEngElectGenData
    var dataPlnt: PlntData
    
    fn __init__(inout self):
        self.dataLoopNodes = DataLoopNodes()
        self.dataHVACGlobal = DataHVACGlobals()
        self.dataGlobal = DataGlobal()
        self.dataIPShortCut = DataIPShortCut()
        self.dataInputProcessing = InputProcessorData()
        self.dataICEngElectGen = ICEngElectGenData()
        self.dataPlnt = PlntData()

alias REFERENCE_TEMP: Real64 = 25.0

struct ICEngineGeneratorSpecs:
    var Name: StringRef
    var TypeOf: StringRef
    var CompType_Num: Int32
    var FuelType: Int32
    var RatedPowerOutput: Real64
    var ElectricCircuitNode: Int32
    var MinPartLoadRat: Real64
    var MaxPartLoadRat: Real64
    var OptPartLoadRat: Real64
    var ElecOutputFuelRat: Real64
    var ElecOutputFuelCurve: UnsafePointer[Curve]
    var RecJacHeattoFuelRat: Real64
    var RecJacHeattoFuelCurve: UnsafePointer[Curve]
    var RecLubeHeattoFuelRat: Real64
    var RecLubeHeattoFuelCurve: UnsafePointer[Curve]
    var TotExhausttoFuelRat: Real64
    var TotExhausttoFuelCurve: UnsafePointer[Curve]
    var ExhaustTemp: Real64
    var ExhaustTempCurve: UnsafePointer[Curve]
    var ErrExhaustTempIndex: Int32
    var UA: Real64
    var UACoef: InlineArray[Real64, 2]
    var MaxExhaustperPowerOutput: Real64
    var DesignMinExitGasTemp: Real64
    var FuelHeatingValue: Real64
    var DesignHeatRecVolFlowRate: Real64
    var DesignHeatRecMassFlowRate: Real64
    var HeatRecActive: Bool
    var HeatRecInletNodeNum: Int32
    var HeatRecOutletNodeNum: Int32
    var HeatRecInletTemp: Real64
    var HeatRecOutletTemp: Real64
    var HeatRecMdotDesign: Real64
    var HeatRecMdotActual: Real64
    var QTotalHeatRecovered: Real64
    var QJacketRecovered: Real64
    var QLubeOilRecovered: Real64
    var QExhaustRecovered: Real64
    var FuelEnergyUseRate: Real64
    var TotalHeatEnergyRec: Real64
    var JacketEnergyRec: Real64
    var LubeOilEnergyRec: Real64
    var ExhaustEnergyRec: Real64
    var FuelEnergy: Real64
    var FuelMdot: Real64
    var ExhaustStackTemp: Real64
    var ElecPowerGenerated: Real64
    var ElecEnergyGenerated: Real64
    var HeatRecMaxTemp: Real64
    var HRPlantLoc: PlantLocation
    var MyEnvrnFlag: Bool
    var MyPlantScanFlag: Bool
    var MySizeAndNodeInitFlag: Bool
    var CheckEquipName: Bool
    var myFlag: Bool
    
    fn __init__(inout self):
        self.Name = StringRef("")
        self.TypeOf = StringRef("Generator:InternalCombustionEngine")
        self.CompType_Num = 0
        self.FuelType = 0
        self.RatedPowerOutput = 0.0
        self.ElectricCircuitNode = 0
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.ElecOutputFuelRat = 0.0
        self.ElecOutputFuelCurve = UnsafePointer[Curve]()
        self.RecJacHeattoFuelRat = 0.0
        self.RecJacHeattoFuelCurve = UnsafePointer[Curve]()
        self.RecLubeHeattoFuelRat = 0.0
        self.RecLubeHeattoFuelCurve = UnsafePointer[Curve]()
        self.TotExhausttoFuelRat = 0.0
        self.TotExhausttoFuelCurve = UnsafePointer[Curve]()
        self.ExhaustTemp = 0.0
        self.ExhaustTempCurve = UnsafePointer[Curve]()
        self.ErrExhaustTempIndex = 0
        self.UA = 0.0
        self.UACoef = InlineArray[Real64, 2](fill=0.0)
        self.MaxExhaustperPowerOutput = 0.0
        self.DesignMinExitGasTemp = 0.0
        self.FuelHeatingValue = 0.0
        self.DesignHeatRecVolFlowRate = 0.0
        self.DesignHeatRecMassFlowRate = 0.0
        self.HeatRecActive = False
        self.HeatRecInletNodeNum = 0
        self.HeatRecOutletNodeNum = 0
        self.HeatRecInletTemp = 0.0
        self.HeatRecOutletTemp = 0.0
        self.HeatRecMdotDesign = 0.0
        self.HeatRecMdotActual = 0.0
        self.QTotalHeatRecovered = 0.0
        self.QJacketRecovered = 0.0
        self.QLubeOilRecovered = 0.0
        self.QExhaustRecovered = 0.0
        self.FuelEnergyUseRate = 0.0
        self.TotalHeatEnergyRec = 0.0
        self.JacketEnergyRec = 0.0
        self.LubeOilEnergyRec = 0.0
        self.ExhaustEnergyRec = 0.0
        self.FuelEnergy = 0.0
        self.FuelMdot = 0.0
        self.ExhaustStackTemp = 0.0
        self.ElecPowerGenerated = 0.0
        self.ElecEnergyGenerated = 0.0
        self.HeatRecMaxTemp = 0.0
        self.HRPlantLoc = PlantLocation()
        self.MyEnvrnFlag = True
        self.MyPlantScanFlag = True
        self.MySizeAndNodeInitFlag = True
        self.CheckEquipName = True
        self.myFlag = True

    fn simulate(inout self, state: inout EnergyPlusData, calledFromLocation: PlantLocation,
                FirstHVACIteration: Bool, CurLoad: inout Real64, RunFlag: Bool):
        pass

    fn InitICEngineGenerators(inout self, state: inout EnergyPlusData, RunFlag: Bool, FirstHVACIteration: Bool):
        self.oneTimeInit(state)
        
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and self.HeatRecActive:
            let HeatRecInletNode = self.HeatRecInletNodeNum
            let HeatRecOutletNode = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[HeatRecInletNode].Temp = 20.0
            state.dataLoopNodes.Node[HeatRecOutletNode].Temp = 20.0
            self.MyEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        
        if self.HeatRecActive:
            if FirstHVACIteration:
                let mdot = self.DesignHeatRecMassFlowRate if RunFlag else 0.0
            else:
                let mdot = self.HeatRecMdotActual

    fn CalcICEngineGeneratorModel(inout self, state: inout EnergyPlusData, RunFlag: Bool, MyLoad: Real64):
        let EXHAUST_CP: Real64 = 1.047
        let KJ_TO_J: Real64 = 1000.0
        
        var HeatRecMdot: Real64 = 0.0
        var HeatRecInTemp: Real64 = 0.0
        
        if self.HeatRecActive:
            let HeatRecInNode = self.HeatRecInletNodeNum
            HeatRecInTemp = state.dataLoopNodes.Node[HeatRecInNode].Temp
            HeatRecMdot = state.dataLoopNodes.Node[HeatRecInNode].MassFlowRate
        
        if not RunFlag:
            self.ElecPowerGenerated = 0.0
            self.ElecEnergyGenerated = 0.0
            self.HeatRecInletTemp = HeatRecInTemp
            self.HeatRecOutletTemp = HeatRecInTemp
            self.HeatRecMdotActual = 0.0
            self.QJacketRecovered = 0.0
            self.QExhaustRecovered = 0.0
            self.QLubeOilRecovered = 0.0
            self.QTotalHeatRecovered = 0.0
            self.JacketEnergyRec = 0.0
            self.ExhaustEnergyRec = 0.0
            self.LubeOilEnergyRec = 0.0
            self.TotalHeatEnergyRec = 0.0
            self.FuelEnergyUseRate = 0.0
            self.FuelEnergy = 0.0
            self.FuelMdot = 0.0
            self.ExhaustStackTemp = 0.0
            return
        
        var elecPowerGenerated = fmin(MyLoad, self.RatedPowerOutput)
        elecPowerGenerated = fmax(elecPowerGenerated, 0.0)
        
        var PLR = fmin(elecPowerGenerated / self.RatedPowerOutput, self.MaxPartLoadRat)
        PLR = fmax(PLR, self.MinPartLoadRat)
        elecPowerGenerated = PLR * self.RatedPowerOutput
        
        var fuelEnergyUseRate: Real64 = 0.0
        if PLR > 0.0:
            let elecOutputFuelRat = self.ElecOutputFuelCurve.value(state, PLR)
            fuelEnergyUseRate = elecPowerGenerated / elecOutputFuelRat
        
        let recJacHeattoFuelRat = self.RecJacHeattoFuelCurve.value(state, PLR)
        let QJacketRec = fuelEnergyUseRate * recJacHeattoFuelRat
        
        let recLubeHeattoFuelRat = self.RecLubeHeattoFuelCurve.value(state, PLR)
        let QLubeOilRec = fuelEnergyUseRate * recLubeHeattoFuelRat
        
        let totExhausttoFuelRat = self.TotExhausttoFuelCurve.value(state, PLR)
        let QExhaustTotal = fuelEnergyUseRate * totExhausttoFuelRat
        
        var QExhaustRec: Real64 = 0.0
        var exhaustStackTemp: Real64 = 0.0
        
        if PLR > 0.0:
            let exhaustTemp = self.ExhaustTempCurve.value(state, PLR)
            
            if exhaustTemp > REFERENCE_TEMP:
                let ExhaustGasFlow = QExhaustTotal / (EXHAUST_CP * (exhaustTemp - REFERENCE_TEMP))
                let UA_loc = self.UACoef[0] * math_pow(self.RatedPowerOutput, self.UACoef[1])
                let designMinExitGasTemp = self.DesignMinExitGasTemp
                
                exhaustStackTemp = designMinExitGasTemp + \
                    (exhaustTemp - designMinExitGasTemp) / \
                    exp(UA_loc / (fmax(ExhaustGasFlow, self.MaxExhaustperPowerOutput * self.RatedPowerOutput) * EXHAUST_CP))
                
                QExhaustRec = fmax(ExhaustGasFlow * EXHAUST_CP * (exhaustTemp - exhaustStackTemp), 0.0)
            else:
                if self.ErrExhaustTempIndex == 0:
                    pass
                QExhaustRec = 0.0
                exhaustStackTemp = self.DesignMinExitGasTemp
        
        var qTotalHeatRecovered = QExhaustRec + QLubeOilRec + QJacketRec
        
        var QExhaustRecAdjusted = QExhaustRec
        var QLubeOilRecAdjusted = QLubeOilRec
        var QJacketRecAdjusted = QJacketRec
        
        if self.HeatRecActive:
            let HRecRatio = self.CalcICEngineGenHeatRecovery(state, qTotalHeatRecovered, HeatRecMdot)
            QExhaustRecAdjusted = QExhaustRec * HRecRatio
            QLubeOilRecAdjusted = QLubeOilRec * HRecRatio
            QJacketRecAdjusted = QJacketRec * HRecRatio
            qTotalHeatRecovered = qTotalHeatRecovered * HRecRatio
        else:
            self.HeatRecInletTemp = HeatRecInTemp
            self.HeatRecOutletTemp = HeatRecInTemp
            self.HeatRecMdotActual = HeatRecMdot
        
        let ElectricEnergyGen = elecPowerGenerated * state.dataHVACGlobal.TimeStepSysSec
        let FuelEnergyUsed = fuelEnergyUseRate * state.dataHVACGlobal.TimeStepSysSec
        let jacketEnergyRec = QJacketRecAdjusted * state.dataHVACGlobal.TimeStepSysSec
        let lubeOilEnergyRec = QLubeOilRecAdjusted * state.dataHVACGlobal.TimeStepSysSec
        let exhaustEnergyRec = QExhaustRecAdjusted * state.dataHVACGlobal.TimeStepSysSec
        
        self.ElecPowerGenerated = elecPowerGenerated
        self.ElecEnergyGenerated = ElectricEnergyGen
        self.QJacketRecovered = QJacketRecAdjusted
        self.QLubeOilRecovered = QLubeOilRecAdjusted
        self.QExhaustRecovered = QExhaustRecAdjusted
        self.QTotalHeatRecovered = qTotalHeatRecovered
        self.JacketEnergyRec = jacketEnergyRec
        self.LubeOilEnergyRec = lubeOilEnergyRec
        self.ExhaustEnergyRec = exhaustEnergyRec
        self.QTotalHeatRecovered = (QExhaustRecAdjusted + QLubeOilRecAdjusted + QJacketRecAdjusted)
        self.TotalHeatEnergyRec = (exhaustEnergyRec + lubeOilEnergyRec + jacketEnergyRec)
        self.FuelEnergyUseRate = fabs(fuelEnergyUseRate)
        self.FuelEnergy = fabs(FuelEnergyUsed)
        
        let fuelHeatingValue = self.FuelHeatingValue
        self.FuelMdot = fabs(fuelEnergyUseRate) / (fuelHeatingValue * KJ_TO_J)
        self.ExhaustStackTemp = exhaustStackTemp

    fn CalcICEngineGenHeatRecovery(inout self, state: inout EnergyPlusData, EnergyRecovered: Real64,
                                    HeatRecMdot: Real64) -> Real64:
        var HRecRatio: Real64 = 1.0
        
        let HeatRecInTemp = state.dataLoopNodes.Node[self.HeatRecInletNodeNum].Temp
        let HeatRecCp = self.HRPlantLoc.loop.glycol.getSpecificHeat(state, HeatRecInTemp, "CalcICEngineGeneratorModel")
        
        var HeatRecOutTemp: Real64
        if HeatRecMdot > 0 and HeatRecCp > 0:
            HeatRecOutTemp = EnergyRecovered / (HeatRecMdot * HeatRecCp) + HeatRecInTemp
        else:
            HeatRecOutTemp = HeatRecInTemp
        
        if HeatRecOutTemp > self.HeatRecMaxTemp:
            var MinHeatRecMdot: Real64
            if self.HeatRecMaxTemp != HeatRecInTemp:
                MinHeatRecMdot = EnergyRecovered / (HeatRecCp * (self.HeatRecMaxTemp - HeatRecInTemp))
                if MinHeatRecMdot < 0.0:
                    MinHeatRecMdot = 0.0
            else:
                MinHeatRecMdot = 0.0
            
            if MinHeatRecMdot > 0.0 and HeatRecCp > 0.0:
                HeatRecOutTemp = EnergyRecovered / (MinHeatRecMdot * HeatRecCp) + HeatRecInTemp
                HRecRatio = HeatRecMdot / MinHeatRecMdot
            else:
                HeatRecOutTemp = HeatRecInTemp
                HRecRatio = 0.0
        
        self.HeatRecInletTemp = HeatRecInTemp
        self.HeatRecOutletTemp = HeatRecOutTemp
        self.HeatRecMdotActual = HeatRecMdot
        
        return HRecRatio

    fn update(inout self, state: inout EnergyPlusData):
        if self.HeatRecActive:
            let HeatRecOutletNode = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[HeatRecOutletNode].Temp = self.HeatRecOutletTemp

    fn setupOutputVars(inout self, state: inout EnergyPlusData):
        pass

    fn getDesignCapacities(inout self, state: inout EnergyPlusData, calledFromLocation: PlantLocation,
                          inout MaxLoad: Real64, inout MinLoad: Real64, inout OptLoad: Real64):
        MaxLoad = 0.0
        MinLoad = 0.0
        OptLoad = 0.0

    @staticmethod
    fn factory(state: inout EnergyPlusData, objectName: StringRef) -> UnsafePointer[ICEngineGeneratorSpecs]:
        if state.dataICEngElectGen.getICEInput:
            GetICEngineGeneratorInput(state)
            state.dataICEngElectGen.getICEInput = False
        
        for i in range(state.dataICEngElectGen.NumICEngineGenerators):
            if state.dataICEngElectGen.ICEngineGenerator[i].Name == objectName:
                return UnsafePointer(state.dataICEngElectGen.ICEngineGenerator.__add__(i))
        
        return UnsafePointer[ICEngineGeneratorSpecs]()

    fn oneTimeInit(inout self, state: inout EnergyPlusData):
        if self.myFlag:
            self.setupOutputVars(state)
            self.myFlag = False
        
        if self.MyPlantScanFlag and self.HeatRecActive:
            self.MyPlantScanFlag = False
        
        if self.MySizeAndNodeInitFlag and not self.MyPlantScanFlag and self.HeatRecActive:
            let rho = self.HRPlantLoc.loop.glycol.getDensity(state, 20.0, "InitICEngineGenerators")
            self.DesignHeatRecMassFlowRate = rho * self.DesignHeatRecVolFlowRate
            self.HeatRecMdotDesign = self.DesignHeatRecMassFlowRate
            self.MySizeAndNodeInitFlag = False

struct ICEngineElectricGeneratorData:
    var NumICEngineGenerators: Int32
    var getICEInput: Bool
    var ICEngineGenerator: UnsafePointer[ICEngineGeneratorSpecs]
    
    fn __init__(inout self):
        self.NumICEngineGenerators = 0
        self.getICEInput = True
        self.ICEngineGenerator = UnsafePointer[ICEngineGeneratorSpecs]()

fn GetICEngineGeneratorInput(state: inout EnergyPlusData):
    let s_ipsc = state.dataIPShortCut
    s_ipsc.cCurrentModuleObject = StringRef("Generator:InternalCombustionEngine")
    
    state.dataICEngElectGen.NumICEngineGenerators = 0
    
    if state.dataICEngElectGen.NumICEngineGenerators <= 0:
        return
    
    for genNum in range(state.dataICEngElectGen.NumICEngineGenerators):
        var iceGen = state.dataICEngElectGen.ICEngineGenerator[genNum]
        iceGen.Name = StringRef("")
        iceGen.RatedPowerOutput = 0.0
        iceGen.MinPartLoadRat = 0.0
        iceGen.MaxPartLoadRat = 0.0
        iceGen.OptPartLoadRat = 0.0
        iceGen.UACoef[0] = 0.0
        iceGen.UACoef[1] = 0.0
        iceGen.MaxExhaustperPowerOutput = 0.0
        iceGen.DesignMinExitGasTemp = 0.0
        iceGen.FuelHeatingValue = 0.0
        iceGen.DesignHeatRecVolFlowRate = 0.0
        iceGen.HeatRecMaxTemp = 0.0

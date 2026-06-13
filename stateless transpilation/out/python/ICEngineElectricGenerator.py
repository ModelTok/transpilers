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

from dataclasses import dataclass, field
from typing import Optional, List, Protocol
import math

REFERENCE_TEMP = 25.0

@dataclass
class Curve:
    pass

@dataclass
class PlantLocation:
    loopNum: int = 0
    loopSideNum: int = 0
    branchNum: int = 0
    compNum: int = 0
    loop: Optional[object] = None

@dataclass
class Node:
    Temp: float = 0.0
    MassFlowRate: float = 0.0

@dataclass
class DataLoopNodes:
    Node: List[Node] = field(default_factory=list)

@dataclass
class DataHVACGlobals:
    TimeStepSysSec: float = 0.0

@dataclass
class DataGlobal:
    BeginEnvrnFlag: bool = False

@dataclass
class DataIPShortCut:
    cCurrentModuleObject: str = ""
    cAlphaFieldNames: List[str] = field(default_factory=list)
    cNumericFieldNames: List[str] = field(default_factory=list)
    lAlphaFieldBlanks: List[bool] = field(default_factory=list)

@dataclass
class InputProcessorData:
    inputProcessor: Optional[object] = None

@dataclass
class ICEngElectGenData:
    NumICEngineGenerators: int = 0
    getICEInput: bool = True
    ICEngineGenerator: List['ICEngineGeneratorSpecs'] = field(default_factory=list)

@dataclass
class PlntData:
    PlantLoop: List[object] = field(default_factory=list)

@dataclass
class EnergyPlusData:
    dataLoopNodes: DataLoopNodes = field(default_factory=DataLoopNodes)
    dataHVACGlobal: DataHVACGlobals = field(default_factory=DataHVACGlobals)
    dataGlobal: DataGlobal = field(default_factory=DataGlobal)
    dataIPShortCut: DataIPShortCut = field(default_factory=DataIPShortCut)
    dataInputProcessing: InputProcessorData = field(default_factory=InputProcessorData)
    dataICEngElectGen: ICEngElectGenData = field(default_factory=ICEngElectGenData)
    dataPlnt: PlntData = field(default_factory=PlntData)

@dataclass
class ICEngineGeneratorSpecs:
    Name: str = ""
    TypeOf: str = "Generator:InternalCombustionEngine"
    CompType_Num: int = 0
    FuelType: int = 0
    RatedPowerOutput: float = 0.0
    ElectricCircuitNode: int = 0
    MinPartLoadRat: float = 0.0
    MaxPartLoadRat: float = 0.0
    OptPartLoadRat: float = 0.0
    ElecOutputFuelRat: float = 0.0
    ElecOutputFuelCurve: Optional[Curve] = None
    RecJacHeattoFuelRat: float = 0.0
    RecJacHeattoFuelCurve: Optional[Curve] = None
    RecLubeHeattoFuelRat: float = 0.0
    RecLubeHeattoFuelCurve: Optional[Curve] = None
    TotExhausttoFuelRat: float = 0.0
    TotExhausttoFuelCurve: Optional[Curve] = None
    ExhaustTemp: float = 0.0
    ExhaustTempCurve: Optional[Curve] = None
    ErrExhaustTempIndex: int = 0
    UA: float = 0.0
    UACoef: List[float] = field(default_factory=lambda: [0.0, 0.0])
    MaxExhaustperPowerOutput: float = 0.0
    DesignMinExitGasTemp: float = 0.0
    FuelHeatingValue: float = 0.0
    DesignHeatRecVolFlowRate: float = 0.0
    DesignHeatRecMassFlowRate: float = 0.0
    HeatRecActive: bool = False
    HeatRecInletNodeNum: int = 0
    HeatRecOutletNodeNum: int = 0
    HeatRecInletTemp: float = 0.0
    HeatRecOutletTemp: float = 0.0
    HeatRecMdotDesign: float = 0.0
    HeatRecMdotActual: float = 0.0
    QTotalHeatRecovered: float = 0.0
    QJacketRecovered: float = 0.0
    QLubeOilRecovered: float = 0.0
    QExhaustRecovered: float = 0.0
    FuelEnergyUseRate: float = 0.0
    TotalHeatEnergyRec: float = 0.0
    JacketEnergyRec: float = 0.0
    LubeOilEnergyRec: float = 0.0
    ExhaustEnergyRec: float = 0.0
    FuelEnergy: float = 0.0
    FuelMdot: float = 0.0
    ExhaustStackTemp: float = 0.0
    ElecPowerGenerated: float = 0.0
    ElecEnergyGenerated: float = 0.0
    HeatRecMaxTemp: float = 0.0
    HRPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    MyEnvrnFlag: bool = True
    MyPlantScanFlag: bool = True
    MySizeAndNodeInitFlag: bool = True
    CheckEquipName: bool = True
    myFlag: bool = True

    def simulate(self, state: EnergyPlusData, calledFromLocation: PlantLocation, 
                 FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        pass

    def InitICEngineGenerators(self, state: EnergyPlusData, RunFlag: bool, FirstHVACIteration: bool) -> None:
        self.oneTimeInit(state)
        
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and self.HeatRecActive:
            HeatRecInletNode = self.HeatRecInletNodeNum
            HeatRecOutletNode = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[HeatRecInletNode].Temp = 20.0
            state.dataLoopNodes.Node[HeatRecOutletNode].Temp = 20.0
            self.MyEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        
        if self.HeatRecActive:
            if FirstHVACIteration:
                mdot = self.DesignHeatRecMassFlowRate if RunFlag else 0.0
            else:
                mdot = self.HeatRecMdotActual

    def CalcICEngineGeneratorModel(self, state: EnergyPlusData, RunFlag: bool, MyLoad: float) -> None:
        EXHAUST_CP = 1.047
        KJ_TO_J = 1000.0
        
        HeatRecMdot = 0.0
        HeatRecInTemp = 0.0
        
        if self.HeatRecActive:
            HeatRecInNode = self.HeatRecInletNodeNum
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
        
        elecPowerGenerated = min(MyLoad, self.RatedPowerOutput)
        elecPowerGenerated = max(elecPowerGenerated, 0.0)
        
        PLR = min(elecPowerGenerated / self.RatedPowerOutput, self.MaxPartLoadRat)
        PLR = max(PLR, self.MinPartLoadRat)
        elecPowerGenerated = PLR * self.RatedPowerOutput
        
        fuelEnergyUseRate = 0.0
        if PLR > 0.0:
            elecOutputFuelRat = self.ElecOutputFuelCurve.value(state, PLR)
            fuelEnergyUseRate = elecPowerGenerated / elecOutputFuelRat
        
        recJacHeattoFuelRat = self.RecJacHeattoFuelCurve.value(state, PLR)
        QJacketRec = fuelEnergyUseRate * recJacHeattoFuelRat
        
        recLubeHeattoFuelRat = self.RecLubeHeattoFuelCurve.value(state, PLR)
        QLubeOilRec = fuelEnergyUseRate * recLubeHeattoFuelRat
        
        totExhausttoFuelRat = self.TotExhausttoFuelCurve.value(state, PLR)
        QExhaustTotal = fuelEnergyUseRate * totExhausttoFuelRat
        
        QExhaustRec = 0.0
        exhaustStackTemp = 0.0
        
        if PLR > 0.0:
            exhaustTemp = self.ExhaustTempCurve.value(state, PLR)
            
            if exhaustTemp > REFERENCE_TEMP:
                ExhaustGasFlow = QExhaustTotal / (EXHAUST_CP * (exhaustTemp - REFERENCE_TEMP))
                UA_loc = self.UACoef[0] * (self.RatedPowerOutput ** self.UACoef[1])
                designMinExitGasTemp = self.DesignMinExitGasTemp
                
                exhaustStackTemp = designMinExitGasTemp + \
                    (exhaustTemp - designMinExitGasTemp) / \
                    math.exp(UA_loc / (max(ExhaustGasFlow, self.MaxExhaustperPowerOutput * self.RatedPowerOutput) * EXHAUST_CP))
                
                QExhaustRec = max(ExhaustGasFlow * EXHAUST_CP * (exhaustTemp - exhaustStackTemp), 0.0)
            else:
                if self.ErrExhaustTempIndex == 0:
                    pass
                QExhaustRec = 0.0
                exhaustStackTemp = self.DesignMinExitGasTemp
        
        qTotalHeatRecovered = QExhaustRec + QLubeOilRec + QJacketRec
        
        HRecRatio = 1.0
        if self.HeatRecActive:
            HRecRatio = self.CalcICEngineGenHeatRecovery(state, qTotalHeatRecovered, HeatRecMdot)
            QExhaustRec *= HRecRatio
            QLubeOilRec *= HRecRatio
            QJacketRec *= HRecRatio
            qTotalHeatRecovered *= HRecRatio
        else:
            self.HeatRecInletTemp = HeatRecInTemp
            self.HeatRecOutletTemp = HeatRecInTemp
            self.HeatRecMdotActual = HeatRecMdot
        
        ElectricEnergyGen = elecPowerGenerated * state.dataHVACGlobal.TimeStepSysSec
        FuelEnergyUsed = fuelEnergyUseRate * state.dataHVACGlobal.TimeStepSysSec
        jacketEnergyRec = QJacketRec * state.dataHVACGlobal.TimeStepSysSec
        lubeOilEnergyRec = QLubeOilRec * state.dataHVACGlobal.TimeStepSysSec
        exhaustEnergyRec = QExhaustRec * state.dataHVACGlobal.TimeStepSysSec
        
        self.ElecPowerGenerated = elecPowerGenerated
        self.ElecEnergyGenerated = ElectricEnergyGen
        self.QJacketRecovered = QJacketRec
        self.QLubeOilRecovered = QLubeOilRec
        self.QExhaustRecovered = QExhaustRec
        self.QTotalHeatRecovered = qTotalHeatRecovered
        self.JacketEnergyRec = jacketEnergyRec
        self.LubeOilEnergyRec = lubeOilEnergyRec
        self.ExhaustEnergyRec = exhaustEnergyRec
        self.QTotalHeatRecovered = (QExhaustRec + QLubeOilRec + QJacketRec)
        self.TotalHeatEnergyRec = (exhaustEnergyRec + lubeOilEnergyRec + jacketEnergyRec)
        self.FuelEnergyUseRate = abs(fuelEnergyUseRate)
        self.FuelEnergy = abs(FuelEnergyUsed)
        
        fuelHeatingValue = self.FuelHeatingValue
        self.FuelMdot = abs(fuelEnergyUseRate) / (fuelHeatingValue * KJ_TO_J)
        self.ExhaustStackTemp = exhaustStackTemp

    def CalcICEngineGenHeatRecovery(self, state: EnergyPlusData, EnergyRecovered: float, 
                                     HeatRecMdot: float) -> float:
        HRecRatio = 1.0
        
        HeatRecInTemp = state.dataLoopNodes.Node[self.HeatRecInletNodeNum].Temp
        HeatRecCp = self.HRPlantLoc.loop.glycol.getSpecificHeat(state, HeatRecInTemp, "CalcICEngineGeneratorModel")
        
        if HeatRecMdot > 0 and HeatRecCp > 0:
            HeatRecOutTemp = EnergyRecovered / (HeatRecMdot * HeatRecCp) + HeatRecInTemp
        else:
            HeatRecOutTemp = HeatRecInTemp
        
        if HeatRecOutTemp > self.HeatRecMaxTemp:
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

    def update(self, state: EnergyPlusData) -> None:
        if self.HeatRecActive:
            HeatRecOutletNode = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[HeatRecOutletNode].Temp = self.HeatRecOutletTemp

    def setupOutputVars(self, state: EnergyPlusData) -> None:
        pass

    def getDesignCapacities(self, state: EnergyPlusData, calledFromLocation: PlantLocation) -> tuple:
        return 0.0, 0.0, 0.0

    @staticmethod
    def factory(state: EnergyPlusData, objectName: str) -> Optional['ICEngineGeneratorSpecs']:
        if state.dataICEngElectGen.getICEInput:
            GetICEngineGeneratorInput(state)
            state.dataICEngElectGen.getICEInput = False
        
        for thisICE in state.dataICEngElectGen.ICEngineGenerator:
            if thisICE.Name == objectName:
                return thisICE
        
        return None

    def oneTimeInit(self, state: EnergyPlusData) -> None:
        if self.myFlag:
            self.setupOutputVars(state)
            self.myFlag = False
        
        if self.MyPlantScanFlag and len(state.dataPlnt.PlantLoop) > 0 and self.HeatRecActive:
            self.MyPlantScanFlag = False
        
        if self.MySizeAndNodeInitFlag and not self.MyPlantScanFlag and self.HeatRecActive:
            rho = self.HRPlantLoc.loop.glycol.getDensity(state, 20.0, "InitICEngineGenerators")
            self.DesignHeatRecMassFlowRate = rho * self.DesignHeatRecVolFlowRate
            self.HeatRecMdotDesign = self.DesignHeatRecMassFlowRate
            self.MySizeAndNodeInitFlag = False

@dataclass
class ICEngineElectricGeneratorData:
    NumICEngineGenerators: int = 0
    getICEInput: bool = True
    ICEngineGenerator: List[ICEngineGeneratorSpecs] = field(default_factory=list)

def GetICEngineGeneratorInput(state: EnergyPlusData) -> None:
    s_ipsc = state.dataIPShortCut
    s_ipsc.cCurrentModuleObject = "Generator:InternalCombustionEngine"
    
    state.dataICEngElectGen.NumICEngineGenerators = 0
    
    if state.dataICEngElectGen.NumICEngineGenerators <= 0:
        return
    
    state.dataICEngElectGen.ICEngineGenerator = [ICEngineGeneratorSpecs() for _ in range(state.dataICEngElectGen.NumICEngineGenerators)]
    
    for genNum in range(state.dataICEngElectGen.NumICEngineGenerators):
        iceGen = state.dataICEngElectGen.ICEngineGenerator[genNum]
        iceGen.Name = ""
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

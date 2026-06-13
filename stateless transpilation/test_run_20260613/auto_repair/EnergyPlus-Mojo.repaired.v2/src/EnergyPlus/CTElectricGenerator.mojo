# Mojo translation of CTElectricGenerator.cc
# Faithful 1:1 translation, no refactoring.

from BranchNodeConnections import TestCompSet
from CurveManager import Curve, GetCurve
from DataEnvironment import state.dataEnvrn
from DataGlobalConstants import Constant
from DataHVACGlobals import state.dataHVACGlobal
from DataIPShortCuts import state.dataIPShortCut
from DataLoopNode import state.dataLoopNodes, Node
from DataPlant import DataPlant, PlantLocation
from ElectricPowerServiceManager import GeneratorType
from FluidProperties import getSpecificHeat, getDensity
from General import allocated
from InputProcessing import inputProcessor, ErrorObjectHeader, ShowSevereItemNotFound
from NodeInputManager import GetOnlySingleNode
from OutAirNodeManager import CheckOutAirNodeNumber
from OutputProcessor import SetupOutputVariable, OutputProcessor, Constant
from PlantUtilities import PlantUtilities
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, Util

from math import exp, sqrt, pow, min, max, abs
from utils import allocate, list

# Forward reference to CTElectricGeneratorData
struct CTElectricGeneratorData:

struct CTGeneratorData:
    Name: String
    TypeOf: String = "Generator:CombustionTurbine"
    CompType_Num: GeneratorType = GeneratorType.CombTurbine
    FuelType: Constant.eFuel
    RatedPowerOutput: Float64 = 0.0
    ElectricCircuitNode: Int = 0
    MinPartLoadRat: Float64 = 0.0
    MaxPartLoadRat: Float64 = 0.0
    OptPartLoadRat: Float64 = 0.0
    FuelEnergyUseRate: Float64 = 0.0
    FuelEnergy: Float64 = 0.0
    PLBasedFuelInputCurve: Curve* = None
    TempBasedFuelInputCurve: Curve* = None
    ExhaustFlow: Float64 = 0.0
    ExhaustFlowCurve: Curve* = None
    ExhaustTemp: Float64 = 0.0
    PLBasedExhaustTempCurve: Curve* = None
    TempBasedExhaustTempCurve: Curve* = None
    QLubeOilRecovered: Float64 = 0.0
    QExhaustRecovered: Float64 = 0.0
    QTotalHeatRecovered: Float64 = 0.0
    LubeOilEnergyRec: Float64 = 0.0
    ExhaustEnergyRec: Float64 = 0.0
    TotalHeatEnergyRec: Float64 = 0.0
    QLubeOilRecoveredCurve: Curve* = None
    UA: Float64 = 0.0
    UACoef: (Float64, Float64) = (0.0, 0.0)
    MaxExhaustperCTPower: Float64 = 0.0
    DesignHeatRecVolFlowRate: Float64 = 0.0
    DesignHeatRecMassFlowRate: Float64 = 0.0
    DesignMinExitGasTemp: Float64 = 0.0
    DesignAirInletTemp: Float64 = 0.0
    ExhaustStackTemp: Float64 = 0.0
    HeatRecActive: Bool = False
    HeatRecInletNodeNum: Int = 0
    HeatRecOutletNodeNum: Int = 0
    HeatRecInletTemp: Float64 = 0.0
    HeatRecOutletTemp: Float64 = 0.0
    HeatRecMdot: Float64 = 0.0
    HRPlantLoc: PlantLocation
    FuelMdot: Float64 = 0.0
    FuelHeatingValue: Float64 = 0.0
    ElecPowerGenerated: Float64 = 0.0
    ElecEnergyGenerated: Float64 = 0.0
    HeatRecMaxTemp: Float64 = 0.0
    OAInletNode: Int = 0
    MyEnvrnFlag: Bool = True
    MyPlantScanFlag: Bool = True
    MySizeAndNodeInitFlag: Bool = True
    CheckEquipName: Bool = True
    MyFlag: Bool = True

    # Constructor
    def __init__(inout self):
        self.HRPlantLoc = PlantLocation()

    # simulate method (plant component)
    def simulate(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):

    # factory method
    @staticmethod
    def factory(inout state: EnergyPlusData, objectName: String) -> CTGeneratorData*:
        if state.dataCTElectricGenerator.getCTInputFlag:
            GetCTGeneratorInput(state)
            state.dataCTElectricGenerator.getCTInputFlag = False
        var myCTGen = __find_if(state.dataCTElectricGenerator.CTGenerator, lambda elecGen: elecGen.Name == objectName)
        if myCTGen >= 0:
            return &state.dataCTElectricGenerator.CTGenerator[myCTGen]
        ShowFatalError(state, String("LocalCombustionTurbineGeneratorFactory: Error getting inputs for combustion turbine generator named: ") + objectName)
        return None

    # oneTimeInit
    def oneTimeInit(inout self, inout state: EnergyPlusData):
        var RoutineName: StringLiteral = "InitICEngineGenerators"
        if self.MyPlantScanFlag:
            if allocated(state.dataPlnt.PlantLoop) and self.HeatRecActive:
                var errFlag: Bool = False
                PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Generator_CTurbine, self.HRPlantLoc, errFlag, _, _, _, _, _)
                if errFlag:
                    ShowFatalError(state, "InitCTGenerators: Program terminated due to previous condition(s).")
            self.MyPlantScanFlag = False
        if self.MyFlag:
            self.setupOutputVars(state)
            self.MyFlag = False
        if self.MySizeAndNodeInitFlag and (not self.MyPlantScanFlag) and self.HeatRecActive:
            var HeatRecInletNode: Int = self.HeatRecInletNodeNum
            var HeatRecOutletNode: Int = self.HeatRecOutletNodeNum
            var rho: Float64 = self.HRPlantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, RoutineName)
            self.DesignHeatRecMassFlowRate = rho * self.DesignHeatRecVolFlowRate
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesignHeatRecMassFlowRate, HeatRecInletNode, HeatRecOutletNode)
            self.MySizeAndNodeInitFlag = False

    # setupOutputVars
    def setupOutputVars(inout self, inout state: EnergyPlusData):
        var sFuelType: String = Constant.eFuelNames[Int(self.FuelType)]
        SetupOutputVariable(state,
            "Generator Produced AC Electricity Rate",
            Constant.Units.W,
            self.ElecPowerGenerated,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            "Generator Produced AC Electricity Energy",
            Constant.Units.J,
            self.ElecEnergyGenerated,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eResource.ElectricityProduced,
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Cogeneration)
        SetupOutputVariable(state,
            String("Generator ") + sFuelType + String(" Rate"),
            Constant.Units.W,
            self.FuelEnergyUseRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            String("Generator ") + sFuelType + String(" Energy"),
            Constant.Units.J,
            self.FuelEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eFuel2eResource[Int(self.FuelType)],
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Cogeneration)
        SetupOutputVariable(state,
            "Generator Fuel HHV Basis Rate",
            Constant.Units.W,
            self.FuelEnergyUseRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            "Generator Fuel HHV Basis Energy",
            Constant.Units.J,
            self.FuelEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name)
        SetupOutputVariable(state,
            String("Generator ") + sFuelType + String(" Mass Flow Rate"),
            Constant.Units.kg_s,
            self.FuelMdot,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            "Generator Exhaust Air Temperature",
            Constant.Units.C,
            self.ExhaustStackTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        if self.HeatRecActive:
            SetupOutputVariable(state,
                "Generator Exhaust Heat Recovery Rate",
                Constant.Units.W,
                self.QExhaustRecovered,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name)
            SetupOutputVariable(state,
                "Generator Exhaust Heat Recovery Energy",
                Constant.Units.J,
                self.ExhaustEnergyRec,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.Name,
                Constant.eResource.EnergyTransfer,
                OutputProcessor.Group.Plant,
                OutputProcessor.EndUseCat.HeatRecovery)
            SetupOutputVariable(state,
                "Generator Lube Heat Recovery Rate",
                Constant.Units.W,
                self.QLubeOilRecovered,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name)
            SetupOutputVariable(state,
                "Generator Lube Heat Recovery Energy",
                Constant.Units.J,
                self.LubeOilEnergyRec,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.Name,
                Constant.eResource.EnergyTransfer,
                OutputProcessor.Group.Plant,
                OutputProcessor.EndUseCat.HeatRecovery)
            SetupOutputVariable(state,
                "Generator Produced Thermal Rate",
                Constant.Units.W,
                self.QTotalHeatRecovered,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name)
            SetupOutputVariable(state,
                "Generator Produced Thermal Energy",
                Constant.Units.J,
                self.TotalHeatEnergyRec,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.Name)
            SetupOutputVariable(state,
                "Generator Heat Recovery Inlet Temperature",
                Constant.Units.C,
                self.HeatRecInletTemp,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name)
            SetupOutputVariable(state,
                "Generator Heat Recovery Outlet Temperature",
                Constant.Units.C,
                self.HeatRecOutletTemp,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name)
            SetupOutputVariable(state,
                "Generator Heat Recovery Mass Flow Rate",
                Constant.Units.kg_s,
                self.HeatRecMdot,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name)

    # CalcCTGeneratorModel
    def CalcCTGeneratorModel(inout self, inout state: EnergyPlusData, RunFlag: Bool, MyLoad: Float64, FirstHVACIteration: Bool):
        var exhaustCp: Float64 = 1.047
        var KJtoJ: Float64 = 1000.0
        var RoutineName: StringLiteral = "CalcCTGeneratorModel"
        var minPartLoadRat: Float64 = self.MinPartLoadRat
        var maxPartLoadRat: Float64 = self.MaxPartLoadRat
        var ratedPowerOutput: Float64 = self.RatedPowerOutput
        var maxExhaustperCTPower: Float64 = self.MaxExhaustperCTPower
        var designAirInletTemp: Float64 = self.DesignAirInletTemp
        var heatRecInTemp: Float64
        var heatRecMdot: Float64
        var heatRecCp: Float64
        if self.HeatRecActive:
            var heatRecInNode: Int = self.HeatRecInletNodeNum
            heatRecInTemp = state.dataLoopNodes.Node[heatRecInNode].Temp
            heatRecCp = self.HRPlantLoc.loop.glycol.getSpecificHeat(state, heatRecInTemp, RoutineName)
            if FirstHVACIteration and RunFlag:
                heatRecMdot = self.DesignHeatRecMassFlowRate
            else:
                heatRecMdot = state.dataLoopNodes.Node[heatRecInNode].MassFlowRate
        else:
            heatRecInTemp = 0.0
            heatRecCp = 0.0
            heatRecMdot = 0.0
        if not RunFlag:
            self.ElecPowerGenerated = 0.0
            self.ElecEnergyGenerated = 0.0
            self.HeatRecInletTemp = heatRecInTemp
            self.HeatRecOutletTemp = heatRecInTemp
            self.HeatRecMdot = 0.0
            self.QLubeOilRecovered = 0.0
            self.QExhaustRecovered = 0.0
            self.QTotalHeatRecovered = 0.0
            self.LubeOilEnergyRec = 0.0
            self.ExhaustEnergyRec = 0.0
            self.TotalHeatEnergyRec = 0.0
            self.FuelEnergyUseRate = 0.0
            self.FuelEnergy = 0.0
            self.FuelMdot = 0.0
            self.ExhaustStackTemp = 0.0
            return
        var elecPowerGenerated: Float64 = min(MyLoad, ratedPowerOutput)
        elecPowerGenerated = max(elecPowerGenerated, 0.0)
        var PLR: Float64 = min(elecPowerGenerated / ratedPowerOutput, maxPartLoadRat)
        PLR = max(PLR, minPartLoadRat)
        elecPowerGenerated = PLR * ratedPowerOutput
        var ambientDeltaT: Float64
        if self.OAInletNode == 0:
            ambientDeltaT = state.dataEnvrn.OutDryBulbTemp - designAirInletTemp
        else:
            ambientDeltaT = state.dataLoopNodes.Node[self.OAInletNode].Temp - designAirInletTemp
        var FuelUseRate: Float64 = elecPowerGenerated * self.PLBasedFuelInputCurve.value(state, PLR) * self.TempBasedFuelInputCurve.value(state, ambientDeltaT)
        var exhaustFlow: Float64 = ratedPowerOutput * self.ExhaustFlowCurve.value(state, ambientDeltaT)
        var QExhaustRec: Float64
        var exhaustStackTemp: Float64
        if (PLR > 0.0) and ((exhaustFlow > 0.0) or (maxExhaustperCTPower > 0.0)):
            var exhaustTemp: Float64 = self.PLBasedExhaustTempCurve.value(state, PLR) * self.TempBasedExhaustTempCurve.value(state, ambientDeltaT)
            var UA_loc: Float64 = self.UACoef[0] * pow(ratedPowerOutput, self.UACoef[1])
            var designMinExitGasTemp: Float64 = self.DesignMinExitGasTemp
            exhaustStackTemp = designMinExitGasTemp + (exhaustTemp - designMinExitGasTemp) / exp(UA_loc / (max(exhaustFlow, maxExhaustperCTPower * ratedPowerOutput) * exhaustCp))
            QExhaustRec = max(exhaustFlow * exhaustCp * (exhaustTemp - exhaustStackTemp), 0.0)
        else:
            exhaustStackTemp = self.DesignMinExitGasTemp
            QExhaustRec = 0.0
        var QLubeOilRec: Float64 = elecPowerGenerated * self.QLubeOilRecoveredCurve.value(state, PLR)
        var HeatRecOutTemp: Float64
        if (heatRecMdot > 0.0) and (heatRecCp > 0.0):
            HeatRecOutTemp = (QExhaustRec + QLubeOilRec) / (heatRecMdot * heatRecCp) + heatRecInTemp
        else:
            heatRecMdot = 0.0
            HeatRecOutTemp = heatRecInTemp
            QExhaustRec = 0.0
            QLubeOilRec = 0.0
        var MinHeatRecMdot: Float64 = 0.0
        var HRecRatio: Float64
        if HeatRecOutTemp > self.HeatRecMaxTemp:
            if self.HeatRecMaxTemp != heatRecInTemp:
                MinHeatRecMdot = (QExhaustRec + QLubeOilRec) / (heatRecCp * (self.HeatRecMaxTemp - heatRecInTemp))
                if MinHeatRecMdot < 0.0:
                    MinHeatRecMdot = 0.0
            if (MinHeatRecMdot > 0.0) and (heatRecCp > 0.0):
                HeatRecOutTemp = (QExhaustRec + QLubeOilRec) / (MinHeatRecMdot * heatRecCp) + heatRecInTemp
                HRecRatio = heatRecMdot / MinHeatRecMdot
            else:
                HeatRecOutTemp = heatRecInTemp
                HRecRatio = 0.0
            QLubeOilRec *= HRecRatio
            QExhaustRec *= HRecRatio
        var ElectricEnergyGen: Float64 = elecPowerGenerated * state.dataHVACGlobal.TimeStepSysSec
        var FuelEnergyUsed: Float64 = FuelUseRate * state.dataHVACGlobal.TimeStepSysSec
        var lubeOilEnergyRec: Float64 = QLubeOilRec * state.dataHVACGlobal.TimeStepSysSec
        var exhaustEnergyRec: Float64 = QExhaustRec * state.dataHVACGlobal.TimeStepSysSec
        self.ElecPowerGenerated = elecPowerGenerated
        self.ElecEnergyGenerated = ElectricEnergyGen
        self.HeatRecInletTemp = heatRecInTemp
        self.HeatRecOutletTemp = HeatRecOutTemp
        self.HeatRecMdot = heatRecMdot
        self.QExhaustRecovered = QExhaustRec
        self.QLubeOilRecovered = QLubeOilRec
        self.QTotalHeatRecovered = QExhaustRec + QLubeOilRec
        self.FuelEnergyUseRate = abs(FuelUseRate)
        self.ExhaustEnergyRec = exhaustEnergyRec
        self.LubeOilEnergyRec = lubeOilEnergyRec
        self.TotalHeatEnergyRec = exhaustEnergyRec + lubeOilEnergyRec
        self.FuelEnergy = abs(FuelEnergyUsed)
        var fuelHeatingValue: Float64 = self.FuelHeatingValue
        self.FuelMdot = abs(FuelUseRate) / (fuelHeatingValue * KJtoJ)
        self.ExhaustStackTemp = exhaustStackTemp
        if self.HeatRecActive:
            var HeatRecOutletNode: Int = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[HeatRecOutletNode].Temp = self.HeatRecOutletTemp

    # InitCTGenerators
    def InitCTGenerators(inout self, inout state: EnergyPlusData, RunFlag: Bool, FirstHVACIteration: Bool):
        self.oneTimeInit(state)
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and self.HeatRecActive:
            var HeatRecInletNode: Int = self.HeatRecInletNodeNum
            var HeatRecOutletNode: Int = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[HeatRecInletNode].Temp = 20.0
            state.dataLoopNodes.Node[HeatRecOutletNode].Temp = 20.0
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesignHeatRecMassFlowRate, HeatRecInletNode, HeatRecOutletNode)
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        if self.HeatRecActive:
            if FirstHVACIteration:
                var mdot: Float64
                if RunFlag:
                    mdot = self.DesignHeatRecMassFlowRate
                else:
                    mdot = 0.0
                PlantUtilities.SetComponentFlowRate(state, mdot, self.HeatRecInletNodeNum, self.HeatRecOutletNodeNum, self.HRPlantLoc)
            else:
                PlantUtilities.SetComponentFlowRate(state, self.HeatRecMdot, self.HeatRecInletNodeNum, self.HeatRecOutletNodeNum, self.HRPlantLoc)

# Free functions

def GetCTGeneratorInput(inout state: EnergyPlusData):
    var routineName: StringLiteral = "GetCTGeneratorInput"
    var ErrorsFound: Bool = False
    state.dataIPShortCut.cCurrentModuleObject = "Generator:CombustionTurbine"
    var inputProcessor = state.dataInputProcessing.inputProcessor.get()
    var NumCTGenerators: Int = inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    if NumCTGenerators <= 0:
        ShowSevereError(state, String("No ") + state.dataIPShortCut.cCurrentModuleObject + String(" equipment specified in input file"))
        ErrorsFound = True
    state.dataCTElectricGenerator.CTGenerator = List[CTGeneratorData]()
    state.dataCTElectricGenerator.CTGenerator.allocate(NumCTGenerators)
    var objectSchemaProps = inputProcessor.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
    var generatorObjects = inputProcessor.epJSON.find(state.dataIPShortCut.cCurrentModuleObject)
    if generatorObjects != inputProcessor.epJSON.end():
        var genNum: Int = 0  # 0-based indexing
        for generatorInstance in generatorObjects.value().items():
            var generatorFields = generatorInstance.value()
            var generatorName = Util.makeUPPER(generatorInstance.key())
            var electricCircuitNodeName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "electric_circuit_node_name")
            var partLoadBasedFuelInputCurveName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "part_load_based_fuel_input_curve_name")
            var temperatureBasedFuelInputCurveName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "temperature_based_fuel_input_curve_name")
            var exhaustFlowCurveName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "exhaust_flow_curve_name")
            var partLoadBasedExhaustTemperatureCurveName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "part_load_based_exhaust_temperature_curve_name")
            var temperatureBasedExhaustTemperatureCurveName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "temperature_based_exhaust_temperature_curve_name")
            var heatRecoveryLubeEnergyCurveName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "heat_recovery_lube_energy_curve_name")
            var heatRecoveryInletNodeName: String
            if generatorFields.contains("heat_recovery_inlet_node_name"):
                heatRecoveryInletNodeName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "heat_recovery_inlet_node_name")
            else:
                heatRecoveryInletNodeName = String()
            var heatRecoveryOutletNodeName: String
            if generatorFields.contains("heat_recovery_outlet_node_name"):
                heatRecoveryOutletNodeName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "heat_recovery_outlet_node_name")
            else:
                heatRecoveryOutletNodeName = String()
            var fuelType: String
            if generatorFields.contains("fuel_type"):
                fuelType = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "fuel_type")
            else:
                fuelType = String("NaturalGas")
            var outdoorAirInletNodeName: String
            if generatorFields.contains("outdoor_air_inlet_node_name"):
                outdoorAirInletNodeName = inputProcessor.getAlphaFieldValue(generatorFields, objectSchemaProps, "outdoor_air_inlet_node_name")
            else:
                outdoorAirInletNodeName = String()
            inputProcessor.markObjectAsUsed(state.dataIPShortCut.cCurrentModuleObject, generatorInstance.key())
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, state.dataIPShortCut.cCurrentModuleObject, generatorName)
            state.dataCTElectricGenerator.CTGenerator[genNum].Name = generatorName
            state.dataCTElectricGenerator.CTGenerator[genNum].RatedPowerOutput = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "rated_power_output")
            if state.dataCTElectricGenerator.CTGenerator[genNum].RatedPowerOutput == 0.0:
                ShowSevereError(state, String("Invalid ") + "rated_power_output" + String("=") + String(0.0))
                ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + generatorName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].ElectricCircuitNode = Node.GetOnlySingleNode(state,
                electricCircuitNodeName,
                ErrorsFound,
                Node.ConnectionObjectType.GeneratorCombustionTurbine,
                generatorName,
                Node.FluidType.Electric,
                Node.ConnectionType.Electric,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent)
            state.dataCTElectricGenerator.CTGenerator[genNum].MinPartLoadRat = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "minimum_part_load_ratio")
            state.dataCTElectricGenerator.CTGenerator[genNum].MaxPartLoadRat = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "maximum_part_load_ratio")
            state.dataCTElectricGenerator.CTGenerator[genNum].OptPartLoadRat = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "optimum_part_load_ratio")
            state.dataCTElectricGenerator.CTGenerator[genNum].PLBasedFuelInputCurve = Curve.GetCurve(state, partLoadBasedFuelInputCurveName)
            if state.dataCTElectricGenerator.CTGenerator[genNum].PLBasedFuelInputCurve == 0:
                ShowSevereItemNotFound(state, eoh, "part_load_based_fuel_input_curve_name", partLoadBasedFuelInputCurveName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].TempBasedFuelInputCurve = Curve.GetCurve(state, temperatureBasedFuelInputCurveName)
            if state.dataCTElectricGenerator.CTGenerator[genNum].TempBasedFuelInputCurve == None:
                ShowSevereItemNotFound(state, eoh, "temperature_based_fuel_input_curve_name", temperatureBasedFuelInputCurveName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].ExhaustFlowCurve = Curve.GetCurve(state, exhaustFlowCurveName)
            if state.dataCTElectricGenerator.CTGenerator[genNum].ExhaustFlowCurve == None:
                ShowSevereItemNotFound(state, eoh, "exhaust_flow_curve_name", exhaustFlowCurveName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].PLBasedExhaustTempCurve = Curve.GetCurve(state, partLoadBasedExhaustTemperatureCurveName)
            if state.dataCTElectricGenerator.CTGenerator[genNum].PLBasedExhaustTempCurve == None:
                ShowSevereItemNotFound(state, eoh, "part_load_based_exhaust_temperature_curve_name", partLoadBasedExhaustTemperatureCurveName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].TempBasedExhaustTempCurve = Curve.GetCurve(state, temperatureBasedExhaustTemperatureCurveName)
            if state.dataCTElectricGenerator.CTGenerator[genNum].TempBasedExhaustTempCurve == None:
                ShowSevereItemNotFound(state, eoh, "temperature_based_exhaust_temperature_curve_name", temperatureBasedExhaustTemperatureCurveName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].QLubeOilRecoveredCurve = Curve.GetCurve(state, heatRecoveryLubeEnergyCurveName)
            if state.dataCTElectricGenerator.CTGenerator[genNum].QLubeOilRecoveredCurve == None:
                ShowSevereItemNotFound(state, eoh, "heat_recovery_lube_energy_curve_name", heatRecoveryLubeEnergyCurveName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].UACoef[0] = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "coefficient_1_of_u_factor_times_area_curve")
            state.dataCTElectricGenerator.CTGenerator[genNum].UACoef[1] = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "coefficient_2_of_u_factor_times_area_curve")
            state.dataCTElectricGenerator.CTGenerator[genNum].MaxExhaustperCTPower = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "maximum_exhaust_flow_per_unit_of_power_output")
            state.dataCTElectricGenerator.CTGenerator[genNum].DesignMinExitGasTemp = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "design_minimum_exhaust_temperature")
            state.dataCTElectricGenerator.CTGenerator[genNum].DesignAirInletTemp = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "design_air_inlet_temperature")
            state.dataCTElectricGenerator.CTGenerator[genNum].FuelHeatingValue = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "fuel_higher_heating_value")
            state.dataCTElectricGenerator.CTGenerator[genNum].DesignHeatRecVolFlowRate = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "design_heat_recovery_water_flow_rate")
            if state.dataCTElectricGenerator.CTGenerator[genNum].DesignHeatRecVolFlowRate > 0.0:
                state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecActive = True
                state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecInletNodeNum = Node.GetOnlySingleNode(state,
                    heatRecoveryInletNodeName,
                    ErrorsFound,
                    Node.ConnectionObjectType.GeneratorCombustionTurbine,
                    generatorName,
                    Node.FluidType.Water,
                    Node.ConnectionType.Inlet,
                    Node.CompFluidStream.Primary,
                    Node.ObjectIsNotParent)
                if state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecInletNodeNum == 0:
                    ShowSevereError(state, String("Missing Node Name, Heat Recovery Inlet, for ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + generatorName)
                    ErrorsFound = True
                state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecOutletNodeNum = Node.GetOnlySingleNode(state,
                    heatRecoveryOutletNodeName,
                    ErrorsFound,
                    Node.ConnectionObjectType.GeneratorCombustionTurbine,
                    generatorName,
                    Node.FluidType.Water,
                    Node.ConnectionType.Outlet,
                    Node.CompFluidStream.Primary,
                    Node.ObjectIsNotParent)
                if state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecOutletNodeNum == 0:
                    ShowSevereError(state, String("Missing Node Name, Heat Recovery Outlet, for ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + generatorName)
                    ErrorsFound = True
                Node.TestCompSet(state,
                    state.dataIPShortCut.cCurrentModuleObject,
                    generatorName,
                    heatRecoveryInletNodeName,
                    heatRecoveryOutletNodeName,
                    "Heat Recovery Nodes")
                PlantUtilities.RegisterPlantCompDesignFlow(state,
                    state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecInletNodeNum,
                    state.dataCTElectricGenerator.CTGenerator[genNum].DesignHeatRecVolFlowRate)
            else:
                state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecActive = False
                state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecInletNodeNum = 0
                state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecOutletNodeNum = 0
                if (not heatRecoveryInletNodeName.empty()) or (not heatRecoveryOutletNodeName.empty()):
                    ShowWarningError(state,
                        String("Since Design Heat Flow Rate = 0.0, Heat Recovery inactive for ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + generatorName)
                    ShowContinueError(state, "However, Node names were specified for Heat Recovery inlet or outlet nodes")
            state.dataCTElectricGenerator.CTGenerator[genNum].FuelType = Constant.eFuel(getEnumValue(Constant.eFuelNamesUC, fuelType))
            if state.dataCTElectricGenerator.CTGenerator[genNum].FuelType == Constant.eFuel.Invalid:
                ShowSevereError(state, String("Invalid ") + "fuel_type" + String("=") + fuelType)
                ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + generatorName)
                ErrorsFound = True
            state.dataCTElectricGenerator.CTGenerator[genNum].HeatRecMaxTemp = inputProcessor.getRealFieldValue(generatorFields, objectSchemaProps, "heat_recovery_maximum_temperature")
            if outdoorAirInletNodeName.empty():
                state.dataCTElectricGenerator.CTGenerator[genNum].OAInletNode = 0
            else:
                state.dataCTElectricGenerator.CTGenerator[genNum].OAInletNode = Node.GetOnlySingleNode(state,
                    outdoorAirInletNodeName,
                    ErrorsFound,
                    Node.ConnectionObjectType.GeneratorCombustionTurbine,
                    generatorName,
                    Node.FluidType.Air,
                    Node.ConnectionType.OutsideAirReference,
                    Node.CompFluidStream.Primary,
                    Node.ObjectIsNotParent)
                if not OutAirNodeManager.CheckOutAirNodeNumber(state, state.dataCTElectricGenerator.CTGenerator[genNum].OAInletNode):
                    ShowSevereError(state,
                        state.dataIPShortCut.cCurrentModuleObject + String(", \"") + state.dataCTElectricGenerator.CTGenerator[genNum].Name + String("\" Outdoor Air Inlet Node Name not valid Outdoor Air Node= ") + outdoorAirInletNodeName)
                    ShowContinueError(state, "...does not appear in an OutdoorAir:NodeList or as an OutdoorAir:Node.")
                    ErrorsFound = True
            genNum += 1
    if ErrorsFound:
        ShowFatalError(state, String("Errors found in processing input for ") + state.dataIPShortCut.cCurrentModuleObject)

# Helper to find first matching index (since Mojo stdlib doesn't have find_if equivalent)
def __find_if(arr: List[CTGeneratorData], pred: fn(CTGeneratorData) -> Bool) -> Int:
    for i in range(len(arr)):
        if pred(arr[i]):
            return i
    return -1

# Data struct for state
struct CTElectricGeneratorData:
    getCTInputFlag: Bool = True
    CTGenerator: List[CTGeneratorData]

    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(self):
        # Reinitialize as new: Mojo doesn't have placement new, so we reset fields
        self.getCTInputFlag = True
        self.CTGenerator = List[CTGeneratorData]()
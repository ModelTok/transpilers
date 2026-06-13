from .Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataGenerators import DataGenerators
from EnergyPlus.DataLoopNode import Node
from CurveManager import Curve
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import NodeInputManager
from ScheduleManager import Sched
from UtilityRoutines import Util
from General import General
from GeneratorFuelSupply import GeneratorFuelSupplyData  # not used directly but for struct
from ObjexxFCL.Array import Array1D, allocated, sum

def GetGeneratorFuelSupplyInput(state: EnergyPlusData):
    const routineName: String = "GetGeneratorFuelSupplyInput"
    if state.dataGeneratorFuelSupply.MyOneTimeFlag:
        var ErrorsFound: Bool = False
        const cCurrentModuleObject: String = "Generator:FuelSupply"
        let inputProcessor = state.dataInputProcessing.inputProcessor
        let NumGeneratorFuelSups: Int = inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
        let fuelSupplySchemaProps = inputProcessor.getObjectSchemaProps(state, cCurrentModuleObject)
        const fuelTemperatureModelingModeFieldName: String = "Fuel Temperature Modeling Mode"
        const fuelTemperatureScheduleNameFieldName: String = "Fuel Temperature Schedule Name"
        const compressorPowerCurveFieldName: String = "Compressor Power Multiplier Function of Fuel Rate Curve Name"
        const fuelTypeFieldName: String = "Fuel Type"
        if NumGeneratorFuelSups <= 0:
            ShowSevereError(state, String.format("No {} equipment specified in input file", cCurrentModuleObject))
            ErrorsFound = True
        state.dataGenerator.FuelSupply.allocate(NumGeneratorFuelSups)
        let fuelSupplyObjects = inputProcessor.epJSON.find(cCurrentModuleObject)
        if fuelSupplyObjects != inputProcessor.epJSON.end():
            var FuelSupNum: Int = 0
            for fuelSupplyInstance in fuelSupplyObjects.value().items():
                let fuelSupplyFields = fuelSupplyInstance.value()
                let fuelSupplyName = Util.makeUPPER(fuelSupplyInstance.key())
                let fuelTemperatureModelingMode = inputProcessor.getAlphaFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "fuel_temperature_modeling_mode")
                let fuelTemperatureReferenceNodeName = Util.makeUPPER(inputProcessor.getAlphaFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "fuel_temperature_reference_node_name"))
                let fuelTemperatureScheduleName = Util.makeUPPER(inputProcessor.getAlphaFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "fuel_temperature_schedule_name"))
                let compressorPowerCurveName = Util.makeUPPER(inputProcessor.getAlphaFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "compressor_power_multiplier_function_of_fuel_rate_curve_name"))
                let fuelType = inputProcessor.getAlphaFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "fuel_type")
                inputProcessor.markObjectAsUsed(cCurrentModuleObject, fuelSupplyInstance.key())
                FuelSupNum += 1
                let eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, fuelSupplyName)
                var fuelSupply = state.dataGenerator.FuelSupply[FuelSupNum - 1]
                fuelSupply.Name = fuelSupplyName
                if Util.SameString("TemperatureFromAirNode", fuelTemperatureModelingMode):
                    fuelSupply.FuelTempMode = DataGenerators.FuelTemperatureMode.FuelInTempFromNode
                elif Util.SameString("Scheduled", fuelTemperatureModelingMode):
                    fuelSupply.FuelTempMode = DataGenerators.FuelTemperatureMode.FuelInTempSchedule
                else:
                    ShowSevereError(state, String.format("Invalid, {} = {}", fuelTemperatureModelingModeFieldName, fuelTemperatureModelingMode))
                    ShowContinueError(state, String.format("Entered in {}={}", cCurrentModuleObject, fuelSupplyName))
                    ErrorsFound = True
                fuelSupply.NodeName = fuelTemperatureReferenceNodeName
                fuelSupply.NodeNum = Node.GetOnlySingleNode(state,
                    fuelTemperatureReferenceNodeName,
                    ErrorsFound,
                    Node.ConnectionObjectType.GeneratorFuelSupply,
                    fuelSupplyName,
                    Node.FluidType.Air,
                    Node.ConnectionType.Sensor,
                    Node.CompFluidStream.Primary,
                    Node.ObjectIsNotParent)
                if fuelSupply.FuelTempMode == DataGenerators.FuelTemperatureMode.FuelInTempSchedule:
                    if (fuelSupply.sched = Sched.GetSchedule(state, fuelTemperatureScheduleName)) == None:
                        ShowSevereItemNotFound(state, eoh, fuelTemperatureScheduleNameFieldName, fuelTemperatureScheduleName)
                        ErrorsFound = True
                fuelSupply.CompPowerCurveID = Curve.GetCurveIndex(state, compressorPowerCurveName)
                if fuelSupply.CompPowerCurveID == 0:
                    ShowSevereError(state, String.format("Invalid, {} = {}", compressorPowerCurveFieldName, compressorPowerCurveName))
                    ShowContinueError(state, String.format("Entered in {}={}", cCurrentModuleObject, fuelSupplyName))
                    ShowContinueError(state, "Curve named was not found ")
                    ErrorsFound = True
                fuelSupply.CompPowerLossFactor = inputProcessor.getRealFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "compressor_heat_loss_factor")
                if Util.SameString(fuelType, "GaseousConstituents"):
                    fuelSupply.FuelTypeMode = DataGenerators.FuelMode.GaseousConstituents
                elif Util.SameString(fuelType, "LiquidGeneric"):
                    fuelSupply.FuelTypeMode = DataGenerators.FuelMode.GenericLiquid
                else:
                    ShowSevereError(state, String.format("Invalid, {} = {}", fuelTypeFieldName, fuelType))
                    ShowContinueError(state, String.format("Entered in {}={}", cCurrentModuleObject, fuelSupplyName))
                    ErrorsFound = True
                fuelSupply.LHVliquid = inputProcessor.getRealFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "liquid_generic_fuel_lower_heating_value") * 1000.0
                fuelSupply.HHV = inputProcessor.getRealFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "liquid_generic_fuel_higher_heating_value") * 1000.0
                fuelSupply.MW = inputProcessor.getRealFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "liquid_generic_fuel_molecular_weight")
                fuelSupply.eCO2 = inputProcessor.getRealFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "liquid_generic_fuel_co2_emission_factor")
                if fuelSupply.FuelTypeMode == DataGenerators.FuelMode.GaseousConstituents:
                    let NumFuelConstit: Int = inputProcessor.getIntFieldValue(fuelSupplyFields, fuelSupplySchemaProps, "number_of_constituents_in_gaseous_constituent_fuel_supply")
                    fuelSupply.NumConstituents = NumFuelConstit
                    if NumFuelConstit > 12:
                        ShowSevereError(state, String.format("{} model not set up for more than 12 fuel constituents", cCurrentModuleObject))
                        ErrorsFound = True
                    if NumFuelConstit < 1:
                        ShowSevereError(state, String.format("{} model needs at least one fuel constituent", cCurrentModuleObject))
                        ErrorsFound = True
                    for ConstitNum in range(1, NumFuelConstit + 1):
                        let constituentNameFieldName = String.format("constituent_{}_name", ConstitNum)
                        let constituentMolarFractionFieldName = String.format("constituent_{}_molar_fraction", ConstitNum)
                        fuelSupply.ConstitName[ConstitNum - 1] = inputProcessor.getAlphaFieldValue(fuelSupplyFields, fuelSupplySchemaProps, constituentNameFieldName)
                        fuelSupply.ConstitMolalFract[ConstitNum - 1] = inputProcessor.getRealFieldValue(fuelSupplyFields, fuelSupplySchemaProps, constituentMolarFractionFieldName)
                    if abs(sum(fuelSupply.ConstitMolalFract) - 1.0) > 0.0001:
                        ShowSevereError(state, String.format("{} molar fractions do not sum to 1.0", cCurrentModuleObject))
                        ShowContinueError(state, String.format("Sum was={:#G}", sum(fuelSupply.ConstitMolalFract)))
                        ShowContinueError(state, String.format("Entered in {} = {}", cCurrentModuleObject, fuelSupplyName))
                        ErrorsFound = True
        for FuelSupNum in range(1, NumGeneratorFuelSups + 1):
            SetupFuelConstituentData(state, FuelSupNum, ErrorsFound)
        if ErrorsFound:
            ShowFatalError(state, String.format("Problem found processing input for {}", cCurrentModuleObject))
        state.dataGeneratorFuelSupply.MyOneTimeFlag = False

def SetupFuelConstituentData(state: EnergyPlusData, FuelSupplyNum: Int, inout ErrorsFound: Bool):
    const NumHardCodedConstituents: Int = 14
    var first_time: Bool = False
    if not allocated(state.dataGenerator.GasPhaseThermoChemistryData):
        state.dataGenerator.GasPhaseThermoChemistryData.allocate(NumHardCodedConstituents)
        first_time = True
    state.dataGenerator.GasPhaseThermoChemistryData[0].ConstituentName = "CarbonDioxide"
    state.dataGenerator.GasPhaseThermoChemistryData[0].ConstituentFormula = "CO2"
    state.dataGenerator.GasPhaseThermoChemistryData[0].StdRefMolarEnthOfForm = -393.5224
    state.dataGenerator.GasPhaseThermoChemistryData[0].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateA = 24.99735
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateB = 55.18696
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateC = -33.69137
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateD = 7.948387
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateE = -0.136638
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateF = -403.6075
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateG = 228.2431
    state.dataGenerator.GasPhaseThermoChemistryData[0].ShomateH = -393.5224
    state.dataGenerator.GasPhaseThermoChemistryData[0].NumCarbons = 1.0
    state.dataGenerator.GasPhaseThermoChemistryData[0].NumHydrogens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[0].NumOxygens = 2.0
    state.dataGenerator.GasPhaseThermoChemistryData[0].MolecularWeight = 44.01
    state.dataGenerator.GasPhaseThermoChemistryData[1].ConstituentName = "Nitrogen"
    state.dataGenerator.GasPhaseThermoChemistryData[1].ConstituentFormula = "N2"
    state.dataGenerator.GasPhaseThermoChemistryData[1].StdRefMolarEnthOfForm = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[1].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateA = 26.092
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateB = 8.218801
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateC = -1.976141
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateD = 0.159274
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateE = 0.044434
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateF = -7.98923
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateG = 221.02
    state.dataGenerator.GasPhaseThermoChemistryData[1].ShomateH = 0.000
    state.dataGenerator.GasPhaseThermoChemistryData[1].NumCarbons = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[1].NumHydrogens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[1].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[1].MolecularWeight = 28.01
    state.dataGenerator.GasPhaseThermoChemistryData[2].ConstituentName = "Oxygen"
    state.dataGenerator.GasPhaseThermoChemistryData[2].ConstituentFormula = "O2"
    state.dataGenerator.GasPhaseThermoChemistryData[2].StdRefMolarEnthOfForm = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[2].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateA = 29.659
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateB = 6.137261
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateC = -1.186521
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateD = 0.095780
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateE = -0.219663
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateF = -9.861391
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateG = 237.948
    state.dataGenerator.GasPhaseThermoChemistryData[2].ShomateH = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[2].NumCarbons = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[2].NumHydrogens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[2].NumOxygens = 2.0
    state.dataGenerator.GasPhaseThermoChemistryData[2].MolecularWeight = 32.00
    state.dataGenerator.GasPhaseThermoChemistryData[3].ConstituentName = "Water"
    state.dataGenerator.GasPhaseThermoChemistryData[3].ConstituentFormula = "H2O"
    state.dataGenerator.GasPhaseThermoChemistryData[3].StdRefMolarEnthOfForm = -241.8264
    state.dataGenerator.GasPhaseThermoChemistryData[3].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateA = 29.0373
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateB = 10.2573
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateC = 2.81048
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateD = -0.95914
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateE = 0.11725
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateF = -250.569
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateG = 223.3967
    state.dataGenerator.GasPhaseThermoChemistryData[3].ShomateH = -241.8264
    state.dataGenerator.GasPhaseThermoChemistryData[3].NumCarbons = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[3].NumHydrogens = 2.0
    state.dataGenerator.GasPhaseThermoChemistryData[3].NumOxygens = 1.0
    state.dataGenerator.GasPhaseThermoChemistryData[3].MolecularWeight = 18.02
    state.dataGenerator.GasPhaseThermoChemistryData[4].ConstituentName = "Argon"
    state.dataGenerator.GasPhaseThermoChemistryData[4].ConstituentFormula = "Ar"
    state.dataGenerator.GasPhaseThermoChemistryData[4].StdRefMolarEnthOfForm = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[4].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateA = 20.786
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateB = 2.825911e-07
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateC = -1.464191e-07
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateD = 1.092131e-08
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateE = -3.661371e-08
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateF = -6.19735
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateG = 179.999
    state.dataGenerator.GasPhaseThermoChemistryData[4].ShomateH = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[4].NumCarbons = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[4].NumHydrogens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[4].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[4].MolecularWeight = 39.95
    state.dataGenerator.GasPhaseThermoChemistryData[5].ConstituentName = "Hydrogen"
    state.dataGenerator.GasPhaseThermoChemistryData[5].ConstituentFormula = "H2"
    state.dataGenerator.GasPhaseThermoChemistryData[5].StdRefMolarEnthOfForm = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[5].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateA = 33.066178
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateB = -11.363417
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateC = 11.432816
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateD = -2.772874
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateE = -0.158558
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateF = -9.980797
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateG = 172.707974
    state.dataGenerator.GasPhaseThermoChemistryData[5].ShomateH = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[5].NumCarbons = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[5].NumHydrogens = 2.0
    state.dataGenerator.GasPhaseThermoChemistryData[5].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[5].MolecularWeight = 2.02
    state.dataGenerator.GasPhaseThermoChemistryData[6].ConstituentName = "Methane"
    state.dataGenerator.GasPhaseThermoChemistryData[6].ConstituentFormula = "CH4"
    state.dataGenerator.GasPhaseThermoChemistryData[6].StdRefMolarEnthOfForm = -74.8731
    state.dataGenerator.GasPhaseThermoChemistryData[6].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateA = -0.703029
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateB = 108.4773
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateC = -42.52157
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateD = 5.862788
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateE = 0.678565
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateF = -76.84376
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateG = 158.7163
    state.dataGenerator.GasPhaseThermoChemistryData[6].ShomateH = -74.87310
    state.dataGenerator.GasPhaseThermoChemistryData[6].NumCarbons = 1.0
    state.dataGenerator.GasPhaseThermoChemistryData[6].NumHydrogens = 4.0
    state.dataGenerator.GasPhaseThermoChemistryData[6].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[6].MolecularWeight = 16.04
    state.dataGenerator.GasPhaseThermoChemistryData[7].ConstituentName = "Ethane"
    state.dataGenerator.GasPhaseThermoChemistryData[7].ConstituentFormula = "C2H6"
    state.dataGenerator.GasPhaseThermoChemistryData[7].StdRefMolarEnthOfForm = -83.8605
    state.dataGenerator.GasPhaseThermoChemistryData[7].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateA = -3.03849
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateB = 199.202
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateC = -84.9812
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateD = 11.0348
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateE = 0.30348
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateF = -90.0633
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateG = -999.0
    state.dataGenerator.GasPhaseThermoChemistryData[7].ShomateH = -83.8605
    state.dataGenerator.GasPhaseThermoChemistryData[7].NumCarbons = 2.0
    state.dataGenerator.GasPhaseThermoChemistryData[7].NumHydrogens = 6.0
    state.dataGenerator.GasPhaseThermoChemistryData[7].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[7].MolecularWeight = 30.07
    state.dataGenerator.GasPhaseThermoChemistryData[7].NASA_A1 = 0.14625388e+01
    state.dataGenerator.GasPhaseThermoChemistryData[7].NASA_A2 = 0.15494667e-01
    state.dataGenerator.GasPhaseThermoChemistryData[7].NASA_A3 = 0.05780507e-04
    state.dataGenerator.GasPhaseThermoChemistryData[7].NASA_A4 = -0.12578319e-07
    state.dataGenerator.GasPhaseThermoChemistryData[7].NASA_A5 = 0.04586267e-10
    state.dataGenerator.GasPhaseThermoChemistryData[7].NASA_A6 = -0.11239176e+05
    state.dataGenerator.GasPhaseThermoChemistryData[7].NASA_A7 = 0.14432295e+02
    state.dataGenerator.GasPhaseThermoChemistryData[8].ConstituentName = "Propane"
    state.dataGenerator.GasPhaseThermoChemistryData[8].ConstituentFormula = "C3H8"
    state.dataGenerator.GasPhaseThermoChemistryData[8].StdRefMolarEnthOfForm = -103.855
    state.dataGenerator.GasPhaseThermoChemistryData[8].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateA = -23.1747
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateB = 363.742
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateC = -222.981
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateD = 56.253
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateE = 0.61164
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateF = -109.206
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateG = -999.0
    state.dataGenerator.GasPhaseThermoChemistryData[8].ShomateH = -103.855
    state.dataGenerator.GasPhaseThermoChemistryData[8].NumCarbons = 3.0
    state.dataGenerator.GasPhaseThermoChemistryData[8].NumHydrogens = 8.0
    state.dataGenerator.GasPhaseThermoChemistryData[8].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[8].MolecularWeight = 44.10
    state.dataGenerator.GasPhaseThermoChemistryData[8].NASA_A1 = 0.08969208e+01
    state.dataGenerator.GasPhaseThermoChemistryData[8].NASA_A2 = 0.02668986e+00
    state.dataGenerator.GasPhaseThermoChemistryData[8].NASA_A3 = 0.05431425e-04
    state.dataGenerator.GasPhaseThermoChemistryData[8].NASA_A4 = -0.02126000e-06
    state.dataGenerator.GasPhaseThermoChemistryData[8].NASA_A5 = 0.09243330e-10
    state.dataGenerator.GasPhaseThermoChemistryData[8].NASA_A6 = -0.13954918e+05
    state.dataGenerator.GasPhaseThermoChemistryData[8].NASA_A7 = 0.01935533e+03
    state.dataGenerator.GasPhaseThermoChemistryData[9].ConstituentName = "Butane"
    state.dataGenerator.GasPhaseThermoChemistryData[9].ConstituentFormula = "C4H10"
    state.dataGenerator.GasPhaseThermoChemistryData[9].StdRefMolarEnthOfForm = -133.218
    state.dataGenerator.GasPhaseThermoChemistryData[9].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateA = -5.24343
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateB = 426.442
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateC = -257.955
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateD = 66.535
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateE = -0.26994
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateF = -149.365
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateG = -999.0
    state.dataGenerator.GasPhaseThermoChemistryData[9].ShomateH = -133.218
    state.dataGenerator.GasPhaseThermoChemistryData[9].NumCarbons = 4.0
    state.dataGenerator.GasPhaseThermoChemistryData[9].NumHydrogens = 10.0
    state.dataGenerator.GasPhaseThermoChemistryData[9].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[9].MolecularWeight = 58.12
    state.dataGenerator.GasPhaseThermoChemistryData[9].NASA_A1 = -0.02256618e+02
    state.dataGenerator.GasPhaseThermoChemistryData[9].NASA_A2 = 0.05881732e+00
    state.dataGenerator.GasPhaseThermoChemistryData[9].NASA_A3 = -0.04525782e-03
    state.dataGenerator.GasPhaseThermoChemistryData[9].NASA_A4 = 0.02037115e-06
    state.dataGenerator.GasPhaseThermoChemistryData[9].NASA_A5 = -0.04079458e-10
    state.dataGenerator.GasPhaseThermoChemistryData[9].NASA_A6 = -0.01760233e+06
    state.dataGenerator.GasPhaseThermoChemistryData[9].NASA_A7 = 0.03329595e+03
    state.dataGenerator.GasPhaseThermoChemistryData[10].ConstituentName = "Pentane"
    state.dataGenerator.GasPhaseThermoChemistryData[10].ConstituentFormula = "C5H12"
    state.dataGenerator.GasPhaseThermoChemistryData[10].StdRefMolarEnthOfForm = -146.348
    state.dataGenerator.GasPhaseThermoChemistryData[10].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateA = -34.9431
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateB = 576.777
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateC = -338.353
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateD = 76.8232
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateE = 1.00948
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateF = -155.348
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateG = -999.0
    state.dataGenerator.GasPhaseThermoChemistryData[10].ShomateH = -146.348
    state.dataGenerator.GasPhaseThermoChemistryData[10].NumCarbons = 5.0
    state.dataGenerator.GasPhaseThermoChemistryData[10].NumHydrogens = 12.0
    state.dataGenerator.GasPhaseThermoChemistryData[10].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[10].MolecularWeight = 72.15
    state.dataGenerator.GasPhaseThermoChemistryData[10].NASA_A1 = 0.01877907e+02
    state.dataGenerator.GasPhaseThermoChemistryData[10].NASA_A2 = 0.04121645e+00
    state.dataGenerator.GasPhaseThermoChemistryData[10].NASA_A3 = 0.12532337e-04
    state.dataGenerator.GasPhaseThermoChemistryData[10].NASA_A4 = -0.03701536e-06
    state.dataGenerator.GasPhaseThermoChemistryData[10].NASA_A5 = 0.15255685e-10
    state.dataGenerator.GasPhaseThermoChemistryData[10].NASA_A6 = -0.02003815e+06
    state.dataGenerator.GasPhaseThermoChemistryData[10].NASA_A7 = 0.01877256e+03
    state.dataGenerator.GasPhaseThermoChemistryData[11].ConstituentName = "Hexane"
    state.dataGenerator.GasPhaseThermoChemistryData[11].ConstituentFormula = "C6H14"
    state.dataGenerator.GasPhaseThermoChemistryData[11].StdRefMolarEnthOfForm = -166.966
    state.dataGenerator.GasPhaseThermoChemistryData[11].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateA = -46.7786
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateB = 711.187
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateC = -438.39
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateD = 103.784
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateE = 1.23887
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateF = -176.813
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateG = -999.0
    state.dataGenerator.GasPhaseThermoChemistryData[11].ShomateH = -166.966
    state.dataGenerator.GasPhaseThermoChemistryData[11].NumCarbons = 6.0
    state.dataGenerator.GasPhaseThermoChemistryData[11].NumHydrogens = 14.0
    state.dataGenerator.GasPhaseThermoChemistryData[11].NumOxygens = 0.0
    state.dataGenerator.GasPhaseThermoChemistryData[11].MolecularWeight = 86.18
    state.dataGenerator.GasPhaseThermoChemistryData[11].NASA_A1 = 0.01836174e+02
    state.dataGenerator.GasPhaseThermoChemistryData[11].NASA_A2 = 0.05098461e+00
    state.dataGenerator.GasPhaseThermoChemistryData[11].NASA_A3 = 0.12595857e-04
    state.dataGenerator.GasPhaseThermoChemistryData[11].NASA_A4 = -0.04428362e-06
    state.dataGenerator.GasPhaseThermoChemistryData[11].NASA_A5 = 0.01872237e-09
    state.dataGenerator.GasPhaseThermoChemistryData[11].NASA_A6 = -0.02292749e+06
    state.dataGenerator.GasPhaseThermoChemistryData[11].NASA_A7 = 0.02088145e+03
    state.dataGenerator.GasPhaseThermoChemistryData[12].ConstituentName = "Methanol"
    state.dataGenerator.GasPhaseThermoChemistryData[12].ConstituentFormula = "CH3OH"
    state.dataGenerator.GasPhaseThermoChemistryData[12].StdRefMolarEnthOfForm = -201.102
    state.dataGenerator.GasPhaseThermoChemistryData[12].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateA = 14.1952
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateB = 97.7218
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateC = -9.73279
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateD = -12.8461
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateE = 0.15819
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateF = -209.037
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateG = -999.0
    state.dataGenerator.GasPhaseThermoChemistryData[12].ShomateH = -201.102
    state.dataGenerator.GasPhaseThermoChemistryData[12].NumCarbons = 1.0
    state.dataGenerator.GasPhaseThermoChemistryData[12].NumHydrogens = 4.0
    state.dataGenerator.GasPhaseThermoChemistryData[12].NumOxygens = 1.0
    state.dataGenerator.GasPhaseThermoChemistryData[12].MolecularWeight = 32.04
    state.dataGenerator.GasPhaseThermoChemistryData[12].NASA_A1 = 0.02660115e+02
    state.dataGenerator.GasPhaseThermoChemistryData[12].NASA_A2 = 0.07341508e-01
    state.dataGenerator.GasPhaseThermoChemistryData[12].NASA_A3 = 0.07170050e-04
    state.dataGenerator.GasPhaseThermoChemistryData[12].NASA_A4 = -0.08793194e-07
    state.dataGenerator.GasPhaseThermoChemistryData[12].NASA_A5 = 0.02390570e-10
    state.dataGenerator.GasPhaseThermoChemistryData[12].NASA_A6 = -0.02535348e+06
    state.dataGenerator.GasPhaseThermoChemistryData[12].NASA_A7 = 0.11232631e+02
    state.dataGenerator.GasPhaseThermoChemistryData[13].ConstituentName = "Ethanol"
    state.dataGenerator.GasPhaseThermoChemistryData[13].ConstituentFormula = "C2H5OH"
    state.dataGenerator.GasPhaseThermoChemistryData[13].StdRefMolarEnthOfForm = -234.441
    state.dataGenerator.GasPhaseThermoChemistryData[13].ThermoMode = DataGenerators.ThermodynamicMode.NISTShomate
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateA = -8.87256
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateB = 282.389
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateC = -178.85
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateD = 46.3528
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateE = 0.48364
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateF = -241.239
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateG = -999.0
    state.dataGenerator.GasPhaseThermoChemistryData[13].ShomateH = -234.441
    state.dataGenerator.GasPhaseThermoChemistryData[13].NumCarbons = 2.0
    state.dataGenerator.GasPhaseThermoChemistryData[13].NumHydrogens = 6.0
    state.dataGenerator.GasPhaseThermoChemistryData[13].NumOxygens = 1.0
    state.dataGenerator.GasPhaseThermoChemistryData[13].MolecularWeight = 46.07
    state.dataGenerator.GasPhaseThermoChemistryData[13].NASA_A1 = 0.18461027e+01
    state.dataGenerator.GasPhaseThermoChemistryData[13].NASA_A2 = 0.20475008e-01
    state.dataGenerator.GasPhaseThermoChemistryData[13].NASA_A3 = 0.39904089e-05
    state.dataGenerator.GasPhaseThermoChemistryData[13].NASA_A4 = -0.16585986e-07
    state.dataGenerator.GasPhaseThermoChemistryData[13].NASA_A5 = 0.73090440e-11
    state.dataGenerator.GasPhaseThermoChemistryData[13].NASA_A6 = -0.29663086e+05
    state.dataGenerator.GasPhaseThermoChemistryData[13].NASA_A7 = 0.17289993e+02
    if state.dataGenerator.FuelSupply[FuelSupplyNum - 1].FuelTypeMode == DataGenerators.FuelMode.GaseousConstituents:
        var O2Stoic: Float64 = 0.0
        var CO2ProdStoic: Float64 = 0.0
        var H2OProdStoic: Float64 = 0.0
        let CO2dataID: Int = 1
        let WaterDataID: Int = 4
        for i in range(1, state.dataGenerator.FuelSupply[FuelSupplyNum - 1].NumConstituents + 1):
            let thisName: String = state.dataGenerator.FuelSupply[FuelSupplyNum - 1].ConstitName[i - 1]
            let thisGasID: Int = Util.FindItem(thisName, state.dataGenerator.GasPhaseThermoChemistryData, &DataGenerators.GasPropertyDataStruct.ConstituentName)
            state.dataGenerator.FuelSupply[FuelSupplyNum - 1].GasLibID[i - 1] = thisGasID
            if thisGasID == 0:
                ShowSevereError(state, String.format("Fuel constituent not found in thermochemistry data: {}", thisName))
                ErrorsFound = True
            O2Stoic += state.dataGenerator.FuelSupply[FuelSupplyNum - 1].ConstitMolalFract[i - 1] * (
                state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumCarbons +
                state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumHydrogens / 4.0 -
                state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumOxygens / 2.0)
            CO2ProdStoic += state.dataGenerator.FuelSupply[FuelSupplyNum - 1].ConstitMolalFract[i - 1] *
                state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumCarbons
            H2OProdStoic += state.dataGenerator.FuelSupply[FuelSupplyNum - 1].ConstitMolalFract[i - 1] *
                state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumHydrogens / 2.0
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].StoicOxygenRate = O2Stoic
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].CO2ProductGasCoef = CO2ProdStoic
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].H2OProductGasCoef = H2OProdStoic
        var LHVfuel: Float64 = 0.0
        var LHVi: Float64
        for i in range(1, state.dataGenerator.FuelSupply[FuelSupplyNum - 1].NumConstituents + 1):
            let thisGasID = state.dataGenerator.FuelSupply[FuelSupplyNum - 1].GasLibID[i - 1]
            if state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumHydrogens == 0.0:
                LHVi = 0.0
            else:
                LHVi = state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].StdRefMolarEnthOfForm -
                    state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumCarbons *
                    state.dataGenerator.GasPhaseThermoChemistryData[CO2dataID - 1].StdRefMolarEnthOfForm -
                    (state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumHydrogens / 2.0) *
                    state.dataGenerator.GasPhaseThermoChemistryData[WaterDataID - 1].StdRefMolarEnthOfForm
            LHVfuel += LHVi * state.dataGenerator.FuelSupply[FuelSupplyNum - 1].ConstitMolalFract[i - 1]
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].LHV = LHVfuel
        var HHVfuel: Float64 = 0.0
        var HHVi: Float64
        for i in range(1, state.dataGenerator.FuelSupply[FuelSupplyNum - 1].NumConstituents + 1):
            let thisGasID = state.dataGenerator.FuelSupply[FuelSupplyNum - 1].GasLibID[i - 1]
            if state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumHydrogens == 0.0:
                HHVi = 0.0
            else:
                HHVi = state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].StdRefMolarEnthOfForm -
                    state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumCarbons *
                    state.dataGenerator.GasPhaseThermoChemistryData[CO2dataID - 1].StdRefMolarEnthOfForm -
                    (state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumHydrogens / 2.0) *
                    state.dataGenerator.GasPhaseThermoChemistryData[WaterDataID - 1].StdRefMolarEnthOfForm +
                    (state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].NumHydrogens / 2.0) *
                    (state.dataGenerator.GasPhaseThermoChemistryData[WaterDataID - 1].StdRefMolarEnthOfForm + 285.8304)
            HHVfuel += HHVi * state.dataGenerator.FuelSupply[FuelSupplyNum - 1].ConstitMolalFract[i - 1]
        var MWfuel: Float64 = 0.0
        for i in range(1, state.dataGenerator.FuelSupply[FuelSupplyNum - 1].NumConstituents + 1):
            let thisGasID = state.dataGenerator.FuelSupply[FuelSupplyNum - 1].GasLibID[i - 1]
            MWfuel += state.dataGenerator.FuelSupply[FuelSupplyNum - 1].ConstitMolalFract[i - 1] *
                state.dataGenerator.GasPhaseThermoChemistryData[thisGasID - 1].MolecularWeight
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].MW = MWfuel
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].KmolPerSecToKgPerSec = MWfuel
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].HHV = 1000000.0 * HHVfuel / MWfuel
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].LHVJperkg = state.dataGenerator.FuelSupply[FuelSupplyNum - 1].LHV * 1000000.0 / state.dataGenerator.FuelSupply[FuelSupplyNum - 1].MW
    elif state.dataGenerator.FuelSupply[FuelSupplyNum - 1].FuelTypeMode == DataGenerators.FuelMode.GenericLiquid:
        state.dataGenerator.FuelSupply[FuelSupplyNum - 1].LHV = state.dataGenerator.FuelSupply[FuelSupplyNum - 1].LHVliquid *
            state.dataGenerator.FuelSupply[FuelSupplyNum - 1].MW / 1000000.0
    else:

    if first_time:
        print(state.files.eio, "! <Fuel Supply>, Fuel Supply Name, Lower Heating Value [J/kmol], Lower Heating Value [kJ/kg], Higher Heating Value [KJ/kg],  Molecular Weight [g/mol] \n")
    const Format_501: String = " Fuel Supply, {},{:13.6G},{:13.6G},{:13.6G},{:13.6G}\n"
    print(state.files.eio,
          Format_501,
          state.dataGenerator.FuelSupply[FuelSupplyNum - 1].Name,
          state.dataGenerator.FuelSupply[FuelSupplyNum - 1].LHV * 1000000.0,
          state.dataGenerator.FuelSupply[FuelSupplyNum - 1].LHVJperkg / 1000.0,
          state.dataGenerator.FuelSupply[FuelSupplyNum - 1].HHV / 1000.0,
          state.dataGenerator.FuelSupply[FuelSupplyNum - 1].MW)
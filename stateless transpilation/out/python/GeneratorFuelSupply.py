from typing import Protocol, Optional, List, Any
from dataclasses import dataclass, field
from enum import Enum
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusState: main simulation state object (EnergyPlusData)
# - Util.SameString, Util.makeUPPER, Util.FindItem: string utilities
# - ShowSevereError, ShowContinueError, ShowSevereItemNotFound, ShowFatalError: error reporting
# - Node.GetOnlySingleNode: node initialization
# - Sched.GetSchedule: schedule lookup
# - Curve.GetCurveIndex: curve lookup
# - print: output to files.eio
# - ErrorObjectHeader: error context object


class FuelTemperatureMode(Enum):
    FuelInTempFromNode = 1
    FuelInTempSchedule = 2


class FuelMode(Enum):
    GaseousConstituents = 1
    GenericLiquid = 2


class ThermodynamicMode(Enum):
    NISTShomate = 1


@dataclass
class GasPropertyDataStruct:
    ConstituentName: str = ""
    ConstituentFormula: str = ""
    StdRefMolarEnthOfForm: float = 0.0
    ThermoMode: ThermodynamicMode = ThermodynamicMode.NISTShomate
    ShomateA: float = 0.0
    ShomateB: float = 0.0
    ShomateC: float = 0.0
    ShomateD: float = 0.0
    ShomateE: float = 0.0
    ShomateF: float = 0.0
    ShomateG: float = 0.0
    ShomateH: float = 0.0
    NumCarbons: float = 0.0
    NumHydrogens: float = 0.0
    NumOxygens: float = 0.0
    MolecularWeight: float = 0.0
    NASA_A1: float = 0.0
    NASA_A2: float = 0.0
    NASA_A3: float = 0.0
    NASA_A4: float = 0.0
    NASA_A5: float = 0.0
    NASA_A6: float = 0.0
    NASA_A7: float = 0.0


@dataclass
class FuelSupplyData:
    Name: str = ""
    FuelTempMode: FuelTemperatureMode = FuelTemperatureMode.FuelInTempFromNode
    NodeName: str = ""
    NodeNum: int = 0
    sched: Optional[Any] = None
    CompPowerCurveID: int = 0
    CompPowerLossFactor: float = 0.0
    FuelTypeMode: FuelMode = FuelMode.GaseousConstituents
    LHVliquid: float = 0.0
    HHV: float = 0.0
    MW: float = 0.0
    eCO2: float = 0.0
    NumConstituents: int = 0
    ConstitName: List[str] = field(default_factory=lambda: [""] * 13)
    ConstitMolalFract: List[float] = field(default_factory=lambda: [0.0] * 13)
    GasLibID: List[int] = field(default_factory=lambda: [0] * 13)
    StoicOxygenRate: float = 0.0
    CO2ProductGasCoef: float = 0.0
    H2OProductGasCoef: float = 0.0
    LHV: float = 0.0
    KmolPerSecToKgPerSec: float = 0.0
    LHVJperkg: float = 0.0


class GeneratorFuelSupplyState(Protocol):
    MyOneTimeFlag: bool


class InputProcessorData(Protocol):
    epJSON: dict
    
    def getNumObjectsFound(self, state: Any, object_name: str) -> int: ...
    def getObjectSchemaProps(self, state: Any, object_name: str) -> dict: ...
    def getAlphaFieldValue(self, fields: dict, props: dict, field_name: str) -> str: ...
    def getRealFieldValue(self, fields: dict, props: dict, field_name: str) -> float: ...
    def getIntFieldValue(self, fields: dict, props: dict, field_name: str) -> int: ...
    def markObjectAsUsed(self, object_name: str, instance_key: str) -> None: ...


class GeneratorData(Protocol):
    FuelSupply: List[FuelSupplyData]
    GasPhaseThermoChemistryData: Optional[List[GasPropertyDataStruct]]


class EnergyPlusState(Protocol):
    dataGeneratorFuelSupply: GeneratorFuelSupplyState
    dataGenerator: GeneratorData
    dataInputProcessing: Any
    files: Any


def _safe_sum(arr: List[float], n: int) -> float:
    return sum(arr[i] for i in range(n))


def GetGeneratorFuelSupplyInput(state: EnergyPlusState) -> None:
    routine_name = "GetGeneratorFuelSupplyInput"
    
    if state.dataGeneratorFuelSupply.MyOneTimeFlag:
        errors_found = False
        c_current_module_object = "Generator:FuelSupply"
        input_processor = state.dataInputProcessing.inputProcessor
        
        num_generator_fuel_sups = input_processor.getNumObjectsFound(state, c_current_module_object)
        fuel_supply_schema_props = input_processor.getObjectSchemaProps(state, c_current_module_object)
        
        fuel_temperature_modeling_mode_field_name = "Fuel Temperature Modeling Mode"
        fuel_temperature_schedule_name_field_name = "Fuel Temperature Schedule Name"
        compressor_power_curve_field_name = "Compressor Power Multiplier Function of Fuel Rate Curve Name"
        fuel_type_field_name = "Fuel Type"
        
        if num_generator_fuel_sups <= 0:
            from_util import ShowSevereError
            ShowSevereError(state, f"No {c_current_module_object} equipment specified in input file")
            errors_found = True
        
        state.dataGenerator.FuelSupply = [FuelSupplyData() for _ in range(num_generator_fuel_sups)]
        
        fuel_supply_objects = state.dataInputProcessing.epJSON.get(c_current_module_object)
        
        if fuel_supply_objects is not None:
            fuel_sup_num = 0
            for fuel_supply_instance_key, fuel_supply_fields in fuel_supply_objects.items():
                fuel_supply_name = Util.makeUPPER(fuel_supply_instance_key)
                fuel_temperature_modeling_mode = input_processor.getAlphaFieldValue(
                    fuel_supply_fields, fuel_supply_schema_props, "fuel_temperature_modeling_mode"
                )
                fuel_temperature_reference_node_name = Util.makeUPPER(
                    input_processor.getAlphaFieldValue(
                        fuel_supply_fields, fuel_supply_schema_props, "fuel_temperature_reference_node_name"
                    )
                )
                fuel_temperature_schedule_name = Util.makeUPPER(
                    input_processor.getAlphaFieldValue(
                        fuel_supply_fields, fuel_supply_schema_props, "fuel_temperature_schedule_name"
                    )
                )
                compressor_power_curve_name = Util.makeUPPER(
                    input_processor.getAlphaFieldValue(
                        fuel_supply_fields,
                        fuel_supply_schema_props,
                        "compressor_power_multiplier_function_of_fuel_rate_curve_name",
                    )
                )
                fuel_type = input_processor.getAlphaFieldValue(
                    fuel_supply_fields, fuel_supply_schema_props, "fuel_type"
                )
                
                input_processor.markObjectAsUsed(c_current_module_object, fuel_supply_instance_key)
                
                fuel_sup_num += 1
                eoh = ErrorObjectHeader(routine_name, c_current_module_object, fuel_supply_name)
                fuel_supply = state.dataGenerator.FuelSupply[fuel_sup_num - 1]
                fuel_supply.Name = fuel_supply_name
                
                if Util.SameString("TemperatureFromAirNode", fuel_temperature_modeling_mode):
                    fuel_supply.FuelTempMode = FuelTemperatureMode.FuelInTempFromNode
                elif Util.SameString("Scheduled", fuel_temperature_modeling_mode):
                    fuel_supply.FuelTempMode = FuelTemperatureMode.FuelInTempSchedule
                else:
                    from_util import ShowSevereError, ShowContinueError
                    ShowSevereError(
                        state,
                        f"Invalid, {fuel_temperature_modeling_mode_field_name} = {fuel_temperature_modeling_mode}",
                    )
                    ShowContinueError(state, f"Entered in {c_current_module_object}={fuel_supply_name}")
                    errors_found = True
                
                fuel_supply.NodeName = fuel_temperature_reference_node_name
                fuel_supply.NodeNum = Node.GetOnlySingleNode(
                    state,
                    fuel_temperature_reference_node_name,
                    errors_found,
                    "GeneratorFuelSupply",
                    fuel_supply_name,
                    "Air",
                    "Sensor",
                    "Primary",
                    False,
                )
                
                if fuel_supply.FuelTempMode == FuelTemperatureMode.FuelInTempSchedule:
                    fuel_supply.sched = Sched.GetSchedule(state, fuel_temperature_schedule_name)
                    if fuel_supply.sched is None:
                        from_util import ShowSevereItemNotFound
                        ShowSevereItemNotFound(state, eoh, fuel_temperature_schedule_name_field_name, fuel_temperature_schedule_name)
                        errors_found = True
                
                fuel_supply.CompPowerCurveID = Curve.GetCurveIndex(state, compressor_power_curve_name)
                if fuel_supply.CompPowerCurveID == 0:
                    from_util import ShowSevereError, ShowContinueError
                    ShowSevereError(
                        state, f"Invalid, {compressor_power_curve_field_name} = {compressor_power_curve_name}"
                    )
                    ShowContinueError(state, f"Entered in {c_current_module_object}={fuel_supply_name}")
                    ShowContinueError(state, "Curve named was not found ")
                    errors_found = True
                
                fuel_supply.CompPowerLossFactor = input_processor.getRealFieldValue(
                    fuel_supply_fields, fuel_supply_schema_props, "compressor_heat_loss_factor"
                )
                
                if Util.SameString(fuel_type, "GaseousConstituents"):
                    fuel_supply.FuelTypeMode = FuelMode.GaseousConstituents
                elif Util.SameString(fuel_type, "LiquidGeneric"):
                    fuel_supply.FuelTypeMode = FuelMode.GenericLiquid
                else:
                    from_util import ShowSevereError, ShowContinueError
                    ShowSevereError(state, f"Invalid, {fuel_type_field_name} = {fuel_type}")
                    ShowContinueError(state, f"Entered in {c_current_module_object}={fuel_supply_name}")
                    errors_found = True
                
                fuel_supply.LHVliquid = (
                    input_processor.getRealFieldValue(
                        fuel_supply_fields, fuel_supply_schema_props, "liquid_generic_fuel_lower_heating_value"
                    )
                    * 1000.0
                )
                fuel_supply.HHV = (
                    input_processor.getRealFieldValue(
                        fuel_supply_fields, fuel_supply_schema_props, "liquid_generic_fuel_higher_heating_value"
                    )
                    * 1000.0
                )
                fuel_supply.MW = input_processor.getRealFieldValue(
                    fuel_supply_fields, fuel_supply_schema_props, "liquid_generic_fuel_molecular_weight"
                )
                fuel_supply.eCO2 = input_processor.getRealFieldValue(
                    fuel_supply_fields, fuel_supply_schema_props, "liquid_generic_fuel_co2_emission_factor"
                )
                
                if fuel_supply.FuelTypeMode == FuelMode.GaseousConstituents:
                    num_fuel_constit = input_processor.getIntFieldValue(
                        fuel_supply_fields,
                        fuel_supply_schema_props,
                        "number_of_constituents_in_gaseous_constituent_fuel_supply",
                    )
                    fuel_supply.NumConstituents = num_fuel_constit
                    
                    if num_fuel_constit > 12:
                        from_util import ShowSevereError
                        ShowSevereError(state, f"{c_current_module_object} model not set up for more than 12 fuel constituents")
                        errors_found = True
                    if num_fuel_constit < 1:
                        from_util import ShowSevereError
                        ShowSevereError(state, f"{c_current_module_object} model needs at least one fuel constituent")
                        errors_found = True
                    
                    for constit_num in range(1, num_fuel_constit + 1):
                        constituent_name_field_name = f"constituent_{constit_num}_name"
                        constituent_molar_fraction_field_name = f"constituent_{constit_num}_molar_fraction"
                        fuel_supply.ConstitName[constit_num - 1] = input_processor.getAlphaFieldValue(
                            fuel_supply_fields, fuel_supply_schema_props, constituent_name_field_name
                        )
                        fuel_supply.ConstitMolalFract[constit_num - 1] = input_processor.getRealFieldValue(
                            fuel_supply_fields, fuel_supply_schema_props, constituent_molar_fraction_field_name
                        )
                    
                    molar_fract_sum = _safe_sum(fuel_supply.ConstitMolalFract, num_fuel_constit)
                    if abs(molar_fract_sum - 1.0) > 0.0001:
                        from_util import ShowSevereError, ShowContinueError
                        ShowSevereError(state, f"{c_current_module_object} molar fractions do not sum to 1.0")
                        ShowContinueError(state, f"Sum was={molar_fract_sum:.6G}")
                        ShowContinueError(state, f"Entered in {c_current_module_object} = {fuel_supply_name}")
                        errors_found = True
        
        for fuel_sup_num in range(1, num_generator_fuel_sups + 1):
            SetupFuelConstituentData(state, fuel_sup_num, errors_found)
        
        if errors_found:
            from_util import ShowFatalError
            ShowFatalError(state, f"Problem found processing input for {c_current_module_object}")
        
        state.dataGeneratorFuelSupply.MyOneTimeFlag = False


def SetupFuelConstituentData(state: EnergyPlusState, fuel_supply_num: int, errors_found: bool) -> None:
    num_hard_coded_constituents = 14
    
    first_time = False
    if state.dataGenerator.GasPhaseThermoChemistryData is None:
        state.dataGenerator.GasPhaseThermoChemistryData = [
            GasPropertyDataStruct() for _ in range(num_hard_coded_constituents)
        ]
        first_time = True
    
    # Carbon Dioxide (CO2) Temp K 298-1200 (Chase 1998)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[0]
    gas_data.ConstituentName = "CarbonDioxide"
    gas_data.ConstituentFormula = "CO2"
    gas_data.StdRefMolarEnthOfForm = -393.5224
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = 24.99735
    gas_data.ShomateB = 55.18696
    gas_data.ShomateC = -33.69137
    gas_data.ShomateD = 7.948387
    gas_data.ShomateE = -0.136638
    gas_data.ShomateF = -403.6075
    gas_data.ShomateG = 228.2431
    gas_data.ShomateH = -393.5224
    gas_data.NumCarbons = 1.0
    gas_data.NumHydrogens = 0.0
    gas_data.NumOxygens = 2.0
    gas_data.MolecularWeight = 44.01
    
    # Nitrogen (N2) Temp (K) 298-6000
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[1]
    gas_data.ConstituentName = "Nitrogen"
    gas_data.ConstituentFormula = "N2"
    gas_data.StdRefMolarEnthOfForm = 0.0
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = 26.092
    gas_data.ShomateB = 8.218801
    gas_data.ShomateC = -1.976141
    gas_data.ShomateD = 0.159274
    gas_data.ShomateE = 0.044434
    gas_data.ShomateF = -7.98923
    gas_data.ShomateG = 221.02
    gas_data.ShomateH = 0.0
    gas_data.NumCarbons = 0.0
    gas_data.NumHydrogens = 0.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 28.01
    
    # Oxygen (O2) Temp (K) 298-6000
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[2]
    gas_data.ConstituentName = "Oxygen"
    gas_data.ConstituentFormula = "O2"
    gas_data.StdRefMolarEnthOfForm = 0.0
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = 29.659
    gas_data.ShomateB = 6.137261
    gas_data.ShomateC = -1.186521
    gas_data.ShomateD = 0.095780
    gas_data.ShomateE = -0.219663
    gas_data.ShomateF = -9.861391
    gas_data.ShomateG = 237.948
    gas_data.ShomateH = 0.0
    gas_data.NumCarbons = 0.0
    gas_data.NumHydrogens = 0.0
    gas_data.NumOxygens = 2.0
    gas_data.MolecularWeight = 32.00
    
    # Water (H2O) Temp K 300-1700
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[3]
    gas_data.ConstituentName = "Water"
    gas_data.ConstituentFormula = "H2O"
    gas_data.StdRefMolarEnthOfForm = -241.8264
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = 29.0373
    gas_data.ShomateB = 10.2573
    gas_data.ShomateC = 2.81048
    gas_data.ShomateD = -0.95914
    gas_data.ShomateE = 0.11725
    gas_data.ShomateF = -250.569
    gas_data.ShomateG = 223.3967
    gas_data.ShomateH = -241.8264
    gas_data.NumCarbons = 0.0
    gas_data.NumHydrogens = 2.0
    gas_data.NumOxygens = 1.0
    gas_data.MolecularWeight = 18.02
    
    # Argon (Ar) Temp K 298-600
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[4]
    gas_data.ConstituentName = "Argon"
    gas_data.ConstituentFormula = "Ar"
    gas_data.StdRefMolarEnthOfForm = 0.0
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = 20.786
    gas_data.ShomateB = 2.825911e-07
    gas_data.ShomateC = -1.464191e-07
    gas_data.ShomateD = 1.092131e-08
    gas_data.ShomateE = -3.661371e-08
    gas_data.ShomateF = -6.19735
    gas_data.ShomateG = 179.999
    gas_data.ShomateH = 0.0
    gas_data.NumCarbons = 0.0
    gas_data.NumHydrogens = 0.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 39.95
    
    # Hydrogen (H2) Temp K 298-1000
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[5]
    gas_data.ConstituentName = "Hydrogen"
    gas_data.ConstituentFormula = "H2"
    gas_data.StdRefMolarEnthOfForm = 0.0
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = 33.066178
    gas_data.ShomateB = -11.363417
    gas_data.ShomateC = 11.432816
    gas_data.ShomateD = -2.772874
    gas_data.ShomateE = -0.158558
    gas_data.ShomateF = -9.980797
    gas_data.ShomateG = 172.707974
    gas_data.ShomateH = 0.0
    gas_data.NumCarbons = 0.0
    gas_data.NumHydrogens = 2.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 2.02
    
    # Methane (CH4) Temp K 298-1300
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[6]
    gas_data.ConstituentName = "Methane"
    gas_data.ConstituentFormula = "CH4"
    gas_data.StdRefMolarEnthOfForm = -74.8731
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = -0.703029
    gas_data.ShomateB = 108.4773
    gas_data.ShomateC = -42.52157
    gas_data.ShomateD = 5.862788
    gas_data.ShomateE = 0.678565
    gas_data.ShomateF = -76.84376
    gas_data.ShomateG = 158.7163
    gas_data.ShomateH = -74.87310
    gas_data.NumCarbons = 1.0
    gas_data.NumHydrogens = 4.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 16.04
    
    # Ethane (C2H6)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[7]
    gas_data.ConstituentName = "Ethane"
    gas_data.ConstituentFormula = "C2H6"
    gas_data.StdRefMolarEnthOfForm = -83.8605
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = -3.03849
    gas_data.ShomateB = 199.202
    gas_data.ShomateC = -84.9812
    gas_data.ShomateD = 11.0348
    gas_data.ShomateE = 0.30348
    gas_data.ShomateF = -90.0633
    gas_data.ShomateG = -999.0
    gas_data.ShomateH = -83.8605
    gas_data.NumCarbons = 2.0
    gas_data.NumHydrogens = 6.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 30.07
    gas_data.NASA_A1 = 0.14625388e+01
    gas_data.NASA_A2 = 0.15494667e-01
    gas_data.NASA_A3 = 0.05780507e-04
    gas_data.NASA_A4 = -0.12578319e-07
    gas_data.NASA_A5 = 0.04586267e-10
    gas_data.NASA_A6 = -0.11239176e+05
    gas_data.NASA_A7 = 0.14432295e+02
    
    # Propane (C3H8)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[8]
    gas_data.ConstituentName = "Propane"
    gas_data.ConstituentFormula = "C3H8"
    gas_data.StdRefMolarEnthOfForm = -103.855
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = -23.1747
    gas_data.ShomateB = 363.742
    gas_data.ShomateC = -222.981
    gas_data.ShomateD = 56.253
    gas_data.ShomateE = 0.61164
    gas_data.ShomateF = -109.206
    gas_data.ShomateG = -999.0
    gas_data.ShomateH = -103.855
    gas_data.NumCarbons = 3.0
    gas_data.NumHydrogens = 8.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 44.10
    gas_data.NASA_A1 = 0.08969208e+01
    gas_data.NASA_A2 = 0.02668986e+00
    gas_data.NASA_A3 = 0.05431425e-04
    gas_data.NASA_A4 = -0.02126000e-06
    gas_data.NASA_A5 = 0.09243330e-10
    gas_data.NASA_A6 = -0.13954918e+05
    gas_data.NASA_A7 = 0.01935533e+03
    
    # Butane (C4H10)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[9]
    gas_data.ConstituentName = "Butane"
    gas_data.ConstituentFormula = "C4H10"
    gas_data.StdRefMolarEnthOfForm = -133.218
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = -5.24343
    gas_data.ShomateB = 426.442
    gas_data.ShomateC = -257.955
    gas_data.ShomateD = 66.535
    gas_data.ShomateE = -0.26994
    gas_data.ShomateF = -149.365
    gas_data.ShomateG = -999.0
    gas_data.ShomateH = -133.218
    gas_data.NumCarbons = 4.0
    gas_data.NumHydrogens = 10.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 58.12
    gas_data.NASA_A1 = -0.02256618e+02
    gas_data.NASA_A2 = 0.05881732e+00
    gas_data.NASA_A3 = -0.04525782e-03
    gas_data.NASA_A4 = 0.02037115e-06
    gas_data.NASA_A5 = -0.04079458e-10
    gas_data.NASA_A6 = -0.01760233e+06
    gas_data.NASA_A7 = 0.03329595e+03
    
    # Pentane (C5H12)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[10]
    gas_data.ConstituentName = "Pentane"
    gas_data.ConstituentFormula = "C5H12"
    gas_data.StdRefMolarEnthOfForm = -146.348
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = -34.9431
    gas_data.ShomateB = 576.777
    gas_data.ShomateC = -338.353
    gas_data.ShomateD = 76.8232
    gas_data.ShomateE = 1.00948
    gas_data.ShomateF = -155.348
    gas_data.ShomateG = -999.0
    gas_data.ShomateH = -146.348
    gas_data.NumCarbons = 5.0
    gas_data.NumHydrogens = 12.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 72.15
    gas_data.NASA_A1 = 0.01877907e+02
    gas_data.NASA_A2 = 0.04121645e+00
    gas_data.NASA_A3 = 0.12532337e-04
    gas_data.NASA_A4 = -0.03701536e-06
    gas_data.NASA_A5 = 0.15255685e-10
    gas_data.NASA_A6 = -0.02003815e+06
    gas_data.NASA_A7 = 0.01877256e+03
    
    # Hexane (C6H14)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[11]
    gas_data.ConstituentName = "Hexane"
    gas_data.ConstituentFormula = "C6H14"
    gas_data.StdRefMolarEnthOfForm = -166.966
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = -46.7786
    gas_data.ShomateB = 711.187
    gas_data.ShomateC = -438.39
    gas_data.ShomateD = 103.784
    gas_data.ShomateE = 1.23887
    gas_data.ShomateF = -176.813
    gas_data.ShomateG = -999.0
    gas_data.ShomateH = -166.966
    gas_data.NumCarbons = 6.0
    gas_data.NumHydrogens = 14.0
    gas_data.NumOxygens = 0.0
    gas_data.MolecularWeight = 86.18
    gas_data.NASA_A1 = 0.01836174e+02
    gas_data.NASA_A2 = 0.05098461e+00
    gas_data.NASA_A3 = 0.12595857e-04
    gas_data.NASA_A4 = -0.04428362e-06
    gas_data.NASA_A5 = 0.01872237e-09
    gas_data.NASA_A6 = -0.02292749e+06
    gas_data.NASA_A7 = 0.02088145e+03
    
    # Methanol (CH3OH)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[12]
    gas_data.ConstituentName = "Methanol"
    gas_data.ConstituentFormula = "CH3OH"
    gas_data.StdRefMolarEnthOfForm = -201.102
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = 14.1952
    gas_data.ShomateB = 97.7218
    gas_data.ShomateC = -9.73279
    gas_data.ShomateD = -12.8461
    gas_data.ShomateE = 0.15819
    gas_data.ShomateF = -209.037
    gas_data.ShomateG = -999.0
    gas_data.ShomateH = -201.102
    gas_data.NumCarbons = 1.0
    gas_data.NumHydrogens = 4.0
    gas_data.NumOxygens = 1.0
    gas_data.MolecularWeight = 32.04
    gas_data.NASA_A1 = 0.02660115e+02
    gas_data.NASA_A2 = 0.07341508e-01
    gas_data.NASA_A3 = 0.07170050e-04
    gas_data.NASA_A4 = -0.08793194e-07
    gas_data.NASA_A5 = 0.02390570e-10
    gas_data.NASA_A6 = -0.02535348e+06
    gas_data.NASA_A7 = 0.11232631e+02
    
    # Ethanol (C2H5OH)
    gas_data = state.dataGenerator.GasPhaseThermoChemistryData[13]
    gas_data.ConstituentName = "Ethanol"
    gas_data.ConstituentFormula = "C2H5OH"
    gas_data.StdRefMolarEnthOfForm = -234.441
    gas_data.ThermoMode = ThermodynamicMode.NISTShomate
    gas_data.ShomateA = -8.87256
    gas_data.ShomateB = 282.389
    gas_data.ShomateC = -178.85
    gas_data.ShomateD = 46.3528
    gas_data.ShomateE = 0.48364
    gas_data.ShomateF = -241.239
    gas_data.ShomateG = -999.0
    gas_data.ShomateH = -234.441
    gas_data.NumCarbons = 2.0
    gas_data.NumHydrogens = 6.0
    gas_data.NumOxygens = 1.0
    gas_data.MolecularWeight = 46.07
    gas_data.NASA_A1 = 0.18461027e+01
    gas_data.NASA_A2 = 0.20475008e-01
    gas_data.NASA_A3 = 0.39904089e-05
    gas_data.NASA_A4 = -0.16585986e-07
    gas_data.NASA_A5 = 0.73090440e-11
    gas_data.NASA_A6 = -0.29663086e+05
    gas_data.NASA_A7 = 0.17289993e+02
    
    if state.dataGenerator.FuelSupply[fuel_supply_num - 1].FuelTypeMode == FuelMode.GaseousConstituents:
        o2_stoic = 0.0
        co2_prod_stoic = 0.0
        h2o_prod_stoic = 0.0
        co2_data_id = 0
        water_data_id = 3
        
        fuel_supply = state.dataGenerator.FuelSupply[fuel_supply_num - 1]
        
        for i in range(1, fuel_supply.NumConstituents + 1):
            this_name = fuel_supply.ConstitName[i - 1]
            this_gas_id = Util.FindItem(this_name, state.dataGenerator.GasPhaseThermoChemistryData)
            fuel_supply.GasLibID[i - 1] = this_gas_id
            
            if this_gas_id == 0:
                from_util import ShowSevereError
                ShowSevereError(state, f"Fuel constituent not found in thermochemistry data: {this_name}")
                errors_found = True
            
            gas_prop = state.dataGenerator.GasPhaseThermoChemistryData[this_gas_id]
            o2_stoic += fuel_supply.ConstitMolalFract[i - 1] * (
                gas_prop.NumCarbons + gas_prop.NumHydrogens / 4.0 - gas_prop.NumOxygens / 2.0
            )
            co2_prod_stoic += fuel_supply.ConstitMolalFract[i - 1] * gas_prop.NumCarbons
            h2o_prod_stoic += fuel_supply.ConstitMolalFract[i - 1] * gas_prop.NumHydrogens / 2.0
        
        fuel_supply.StoicOxygenRate = o2_stoic
        fuel_supply.CO2ProductGasCoef = co2_prod_stoic
        fuel_supply.H2OProductGasCoef = h2o_prod_stoic
        
        lhv_fuel = 0.0
        for i in range(1, fuel_supply.NumConstituents + 1):
            this_gas_id = fuel_supply.GasLibID[i - 1]
            gas_prop = state.dataGenerator.GasPhaseThermoChemistryData[this_gas_id]
            
            if gas_prop.NumHydrogens == 0.0:
                lhv_i = 0.0
            else:
                lhv_i = (
                    gas_prop.StdRefMolarEnthOfForm
                    - gas_prop.NumCarbons * state.dataGenerator.GasPhaseThermoChemistryData[co2_data_id].StdRefMolarEnthOfForm
                    - (gas_prop.NumHydrogens / 2.0) * state.dataGenerator.GasPhaseThermoChemistryData[water_data_id].StdRefMolarEnthOfForm
                )
            
            lhv_fuel += lhv_i * fuel_supply.ConstitMolalFract[i - 1]
        
        fuel_supply.LHV = lhv_fuel
        
        hhv_fuel = 0.0
        for i in range(1, fuel_supply.NumConstituents + 1):
            this_gas_id = fuel_supply.GasLibID[i - 1]
            gas_prop = state.dataGenerator.GasPhaseThermoChemistryData[this_gas_id]
            
            if gas_prop.NumHydrogens == 0.0:
                hhv_i = 0.0
            else:
                hhv_i = (
                    gas_prop.StdRefMolarEnthOfForm
                    - gas_prop.NumCarbons * state.dataGenerator.GasPhaseThermoChemistryData[co2_data_id].StdRefMolarEnthOfForm
                    - (gas_prop.NumHydrogens / 2.0) * state.dataGenerator.GasPhaseThermoChemistryData[water_data_id].StdRefMolarEnthOfForm
                    + (gas_prop.NumHydrogens / 2.0)
                    * (state.dataGenerator.GasPhaseThermoChemistryData[water_data_id].StdRefMolarEnthOfForm + 285.8304)
                )
            
            hhv_fuel += hhv_i * fuel_supply.ConstitMolalFract[i - 1]
        
        mw_fuel = 0.0
        for i in range(1, fuel_supply.NumConstituents + 1):
            this_gas_id = fuel_supply.GasLibID[i - 1]
            gas_prop = state.dataGenerator.GasPhaseThermoChemistryData[this_gas_id]
            mw_fuel += fuel_supply.ConstitMolalFract[i - 1] * gas_prop.MolecularWeight
        
        fuel_supply.MW = mw_fuel
        fuel_supply.KmolPerSecToKgPerSec = mw_fuel
        fuel_supply.HHV = 1000000.0 * hhv_fuel / mw_fuel
        fuel_supply.LHVJperkg = fuel_supply.LHV * 1000000.0 / fuel_supply.MW
    
    elif state.dataGenerator.FuelSupply[fuel_supply_num - 1].FuelTypeMode == FuelMode.GenericLiquid:
        fuel_supply = state.dataGenerator.FuelSupply[fuel_supply_num - 1]
        fuel_supply.LHV = fuel_supply.LHVliquid * fuel_supply.MW / 1000000.0
    
    if first_time:
        print(
            "! <Fuel Supply>, Fuel Supply Name, Lower Heating Value [J/kmol], Lower Heating Value [kJ/kg], Higher "
            "Heating Value [KJ/kg],  Molecular Weight [g/mol] \n",
            file=state.files.eio,
        )
    
    fuel_supply = state.dataGenerator.FuelSupply[fuel_supply_num - 1]
    print(
        f" Fuel Supply, {fuel_supply.Name},{fuel_supply.LHV * 1000000.0:13.6G},"
        f"{fuel_supply.LHVJperkg / 1000.0:13.6G},{fuel_supply.HHV / 1000.0:13.6G},"
        f"{fuel_supply.MW:13.6G}\n",
        file=state.files.eio,
    )


class Util:
    @staticmethod
    def SameString(a: str, b: str) -> bool:
        return a.upper() == b.upper()
    
    @staticmethod
    def makeUPPER(s: str) -> str:
        return s.upper()
    
    @staticmethod
    def FindItem(name: str, gas_data: List[GasPropertyDataStruct]) -> int:
        for i, gas in enumerate(gas_data):
            if gas.ConstituentName.upper() == name.upper():
                return i
        return 0


class Node:
    @staticmethod
    def GetOnlySingleNode(
        state: EnergyPlusState,
        node_name: str,
        errors_found: bool,
        connection_type: str,
        obj_name: str,
        fluid_type: str,
        sensor_type: str,
        stream: str,
        is_parent: bool,
    ) -> int:
        return 0


class Sched:
    @staticmethod
    def GetSchedule(state: EnergyPlusState, sched_name: str) -> Optional[Any]:
        return None


class Curve:
    @staticmethod
    def GetCurveIndex(state: EnergyPlusState, curve_name: str) -> int:
        return 0


class ErrorObjectHeader:
    def __init__(self, routine: str, object_type: str, object_name: str):
        self.routine = routine
        self.object_type = object_type
        self.object_name = object_name

from math import abs
from collections import InlineArray


alias NUM_HARD_CODED_CONSTITUENTS = 14
alias NUM_CONSTITUENTS_MAX = 13
alias MAX_CONSTITUENTS = 12


struct FuelTemperatureMode:
    alias FuelInTempFromNode = 1
    alias FuelInTempSchedule = 2


struct FuelMode:
    alias GaseousConstituents = 1
    alias GenericLiquid = 2


struct ThermodynamicMode:
    alias NISTShomate = 1


struct GasPropertyDataStruct:
    var constituent_name: String
    var constituent_formula: String
    var std_ref_molar_enth_of_form: Float64
    var thermo_mode: Int32
    var shomate_a: Float64
    var shomate_b: Float64
    var shomate_c: Float64
    var shomate_d: Float64
    var shomate_e: Float64
    var shomate_f: Float64
    var shomate_g: Float64
    var shomate_h: Float64
    var num_carbons: Float64
    var num_hydrogens: Float64
    var num_oxygens: Float64
    var molecular_weight: Float64
    var nasa_a1: Float64
    var nasa_a2: Float64
    var nasa_a3: Float64
    var nasa_a4: Float64
    var nasa_a5: Float64
    var nasa_a6: Float64
    var nasa_a7: Float64
    
    fn __init__(inout self):
        self.constituent_name = ""
        self.constituent_formula = ""
        self.std_ref_molar_enth_of_form = 0.0
        self.thermo_mode = ThermodynamicMode.NISTShomate
        self.shomate_a = 0.0
        self.shomate_b = 0.0
        self.shomate_c = 0.0
        self.shomate_d = 0.0
        self.shomate_e = 0.0
        self.shomate_f = 0.0
        self.shomate_g = 0.0
        self.shomate_h = 0.0
        self.num_carbons = 0.0
        self.num_hydrogens = 0.0
        self.num_oxygens = 0.0
        self.molecular_weight = 0.0
        self.nasa_a1 = 0.0
        self.nasa_a2 = 0.0
        self.nasa_a3 = 0.0
        self.nasa_a4 = 0.0
        self.nasa_a5 = 0.0
        self.nasa_a6 = 0.0
        self.nasa_a7 = 0.0


struct FuelSupplyData:
    var name: String
    var fuel_temp_mode: Int32
    var node_name: String
    var node_num: Int32
    var sched: NoneType
    var comp_power_curve_id: Int32
    var comp_power_loss_factor: Float64
    var fuel_type_mode: Int32
    var lhv_liquid: Float64
    var hhv: Float64
    var mw: Float64
    var e_co2: Float64
    var num_constituents: Int32
    var constit_name: InlineArray[String, 13]
    var constit_molal_fract: InlineArray[Float64, 13]
    var gas_lib_id: InlineArray[Int32, 13]
    var stoic_oxygen_rate: Float64
    var co2_product_gas_coef: Float64
    var h2o_product_gas_coef: Float64
    var lhv: Float64
    var kmol_per_sec_to_kg_per_sec: Float64
    var lhv_j_perkg: Float64
    
    fn __init__(inout self):
        self.name = ""
        self.fuel_temp_mode = FuelTemperatureMode.FuelInTempFromNode
        self.node_name = ""
        self.node_num = 0
        self.sched = None
        self.comp_power_curve_id = 0
        self.comp_power_loss_factor = 0.0
        self.fuel_type_mode = FuelMode.GaseousConstituents
        self.lhv_liquid = 0.0
        self.hhv = 0.0
        self.mw = 0.0
        self.e_co2 = 0.0
        self.num_constituents = 0
        self.constit_name = InlineArray[String, 13](fill="")
        self.constit_molal_fract = InlineArray[Float64, 13](fill=0.0)
        self.gas_lib_id = InlineArray[Int32, 13](fill=0)
        self.stoic_oxygen_rate = 0.0
        self.co2_product_gas_coef = 0.0
        self.h2o_product_gas_coef = 0.0
        self.lhv = 0.0
        self.kmol_per_sec_to_kg_per_sec = 0.0
        self.lhv_j_perkg = 0.0


struct GeneratorFuelSupplyData:
    var my_one_time_flag: Bool
    
    fn __init__(inout self):
        self.my_one_time_flag = True


struct EnergyPlusState:
    pass


fn same_string(a: String, b: String) -> Bool:
    return a.upper() == b.upper()


fn make_upper(s: String) -> String:
    return s.upper()


fn find_item(name: String, gas_data: List[GasPropertyDataStruct]) -> Int32:
    for i in range(len(gas_data)):
        if gas_data[i].constituent_name.upper() == name.upper():
            return i
    return 0


fn get_only_single_node(
    state: EnergyPlusState,
    node_name: String,
    errors_found: Bool,
    connection_type: String,
    obj_name: String,
    fluid_type: String,
    sensor_type: String,
    stream: String,
    is_parent: Bool,
) -> Int32:
    return 0


fn get_schedule(state: EnergyPlusState, sched_name: String) -> NoneType:
    return None


fn get_curve_index(state: EnergyPlusState, curve_name: String) -> Int32:
    return 0


fn show_severe_error(state: EnergyPlusState, msg: String) -> None:
    pass


fn show_continue_error(state: EnergyPlusState, msg: String) -> None:
    pass


fn show_severe_item_not_found(state: EnergyPlusState, eoh: NoneType, field_name: String, item_name: String) -> None:
    pass


fn show_fatal_error(state: EnergyPlusState, msg: String) -> None:
    pass


fn safe_sum(arr: InlineArray[Float64, 13], n: Int32) -> Float64:
    var result: Float64 = 0.0
    for i in range(n):
        result += arr[i]
    return result


fn get_generator_fuel_supply_input(state: EnergyPlusState) -> None:
    var routine_name = "GetGeneratorFuelSupplyInput"


fn setup_fuel_constituent_data(state: EnergyPlusState, fuel_supply_num: Int32, inout errors_found: Bool) -> None:
    var first_time = False
    
    var gas_data: List[GasPropertyDataStruct] = List[GasPropertyDataStruct](capacity=NUM_HARD_CODED_CONSTITUENTS)
    for _ in range(NUM_HARD_CODED_CONSTITUENTS):
        gas_data.append(GasPropertyDataStruct())
    
    first_time = True
    
    var gas = gas_data[0]
    gas.constituent_name = "CarbonDioxide"
    gas.constituent_formula = "CO2"
    gas.std_ref_molar_enth_of_form = -393.5224
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = 24.99735
    gas.shomate_b = 55.18696
    gas.shomate_c = -33.69137
    gas.shomate_d = 7.948387
    gas.shomate_e = -0.136638
    gas.shomate_f = -403.6075
    gas.shomate_g = 228.2431
    gas.shomate_h = -393.5224
    gas.num_carbons = 1.0
    gas.num_hydrogens = 0.0
    gas.num_oxygens = 2.0
    gas.molecular_weight = 44.01
    
    gas = gas_data[1]
    gas.constituent_name = "Nitrogen"
    gas.constituent_formula = "N2"
    gas.std_ref_molar_enth_of_form = 0.0
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = 26.092
    gas.shomate_b = 8.218801
    gas.shomate_c = -1.976141
    gas.shomate_d = 0.159274
    gas.shomate_e = 0.044434
    gas.shomate_f = -7.98923
    gas.shomate_g = 221.02
    gas.shomate_h = 0.0
    gas.num_carbons = 0.0
    gas.num_hydrogens = 0.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 28.01
    
    gas = gas_data[2]
    gas.constituent_name = "Oxygen"
    gas.constituent_formula = "O2"
    gas.std_ref_molar_enth_of_form = 0.0
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = 29.659
    gas.shomate_b = 6.137261
    gas.shomate_c = -1.186521
    gas.shomate_d = 0.095780
    gas.shomate_e = -0.219663
    gas.shomate_f = -9.861391
    gas.shomate_g = 237.948
    gas.shomate_h = 0.0
    gas.num_carbons = 0.0
    gas.num_hydrogens = 0.0
    gas.num_oxygens = 2.0
    gas.molecular_weight = 32.00
    
    gas = gas_data[3]
    gas.constituent_name = "Water"
    gas.constituent_formula = "H2O"
    gas.std_ref_molar_enth_of_form = -241.8264
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = 29.0373
    gas.shomate_b = 10.2573
    gas.shomate_c = 2.81048
    gas.shomate_d = -0.95914
    gas.shomate_e = 0.11725
    gas.shomate_f = -250.569
    gas.shomate_g = 223.3967
    gas.shomate_h = -241.8264
    gas.num_carbons = 0.0
    gas.num_hydrogens = 2.0
    gas.num_oxygens = 1.0
    gas.molecular_weight = 18.02
    
    gas = gas_data[4]
    gas.constituent_name = "Argon"
    gas.constituent_formula = "Ar"
    gas.std_ref_molar_enth_of_form = 0.0
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = 20.786
    gas.shomate_b = 2.825911e-07
    gas.shomate_c = -1.464191e-07
    gas.shomate_d = 1.092131e-08
    gas.shomate_e = -3.661371e-08
    gas.shomate_f = -6.19735
    gas.shomate_g = 179.999
    gas.shomate_h = 0.0
    gas.num_carbons = 0.0
    gas.num_hydrogens = 0.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 39.95
    
    gas = gas_data[5]
    gas.constituent_name = "Hydrogen"
    gas.constituent_formula = "H2"
    gas.std_ref_molar_enth_of_form = 0.0
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = 33.066178
    gas.shomate_b = -11.363417
    gas.shomate_c = 11.432816
    gas.shomate_d = -2.772874
    gas.shomate_e = -0.158558
    gas.shomate_f = -9.980797
    gas.shomate_g = 172.707974
    gas.shomate_h = 0.0
    gas.num_carbons = 0.0
    gas.num_hydrogens = 2.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 2.02
    
    gas = gas_data[6]
    gas.constituent_name = "Methane"
    gas.constituent_formula = "CH4"
    gas.std_ref_molar_enth_of_form = -74.8731
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = -0.703029
    gas.shomate_b = 108.4773
    gas.shomate_c = -42.52157
    gas.shomate_d = 5.862788
    gas.shomate_e = 0.678565
    gas.shomate_f = -76.84376
    gas.shomate_g = 158.7163
    gas.shomate_h = -74.87310
    gas.num_carbons = 1.0
    gas.num_hydrogens = 4.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 16.04
    
    gas = gas_data[7]
    gas.constituent_name = "Ethane"
    gas.constituent_formula = "C2H6"
    gas.std_ref_molar_enth_of_form = -83.8605
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = -3.03849
    gas.shomate_b = 199.202
    gas.shomate_c = -84.9812
    gas.shomate_d = 11.0348
    gas.shomate_e = 0.30348
    gas.shomate_f = -90.0633
    gas.shomate_g = -999.0
    gas.shomate_h = -83.8605
    gas.num_carbons = 2.0
    gas.num_hydrogens = 6.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 30.07
    gas.nasa_a1 = 0.14625388e+01
    gas.nasa_a2 = 0.15494667e-01
    gas.nasa_a3 = 0.05780507e-04
    gas.nasa_a4 = -0.12578319e-07
    gas.nasa_a5 = 0.04586267e-10
    gas.nasa_a6 = -0.11239176e+05
    gas.nasa_a7 = 0.14432295e+02
    
    gas = gas_data[8]
    gas.constituent_name = "Propane"
    gas.constituent_formula = "C3H8"
    gas.std_ref_molar_enth_of_form = -103.855
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = -23.1747
    gas.shomate_b = 363.742
    gas.shomate_c = -222.981
    gas.shomate_d = 56.253
    gas.shomate_e = 0.61164
    gas.shomate_f = -109.206
    gas.shomate_g = -999.0
    gas.shomate_h = -103.855
    gas.num_carbons = 3.0
    gas.num_hydrogens = 8.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 44.10
    gas.nasa_a1 = 0.08969208e+01
    gas.nasa_a2 = 0.02668986e+00
    gas.nasa_a3 = 0.05431425e-04
    gas.nasa_a4 = -0.02126000e-06
    gas.nasa_a5 = 0.09243330e-10
    gas.nasa_a6 = -0.13954918e+05
    gas.nasa_a7 = 0.01935533e+03
    
    gas = gas_data[9]
    gas.constituent_name = "Butane"
    gas.constituent_formula = "C4H10"
    gas.std_ref_molar_enth_of_form = -133.218
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = -5.24343
    gas.shomate_b = 426.442
    gas.shomate_c = -257.955
    gas.shomate_d = 66.535
    gas.shomate_e = -0.26994
    gas.shomate_f = -149.365
    gas.shomate_g = -999.0
    gas.shomate_h = -133.218
    gas.num_carbons = 4.0
    gas.num_hydrogens = 10.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 58.12
    gas.nasa_a1 = -0.02256618e+02
    gas.nasa_a2 = 0.05881732e+00
    gas.nasa_a3 = -0.04525782e-03
    gas.nasa_a4 = 0.02037115e-06
    gas.nasa_a5 = -0.04079458e-10
    gas.nasa_a6 = -0.01760233e+06
    gas.nasa_a7 = 0.03329595e+03
    
    gas = gas_data[10]
    gas.constituent_name = "Pentane"
    gas.constituent_formula = "C5H12"
    gas.std_ref_molar_enth_of_form = -146.348
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = -34.9431
    gas.shomate_b = 576.777
    gas.shomate_c = -338.353
    gas.shomate_d = 76.8232
    gas.shomate_e = 1.00948
    gas.shomate_f = -155.348
    gas.shomate_g = -999.0
    gas.shomate_h = -146.348
    gas.num_carbons = 5.0
    gas.num_hydrogens = 12.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 72.15
    gas.nasa_a1 = 0.01877907e+02
    gas.nasa_a2 = 0.04121645e+00
    gas.nasa_a3 = 0.12532337e-04
    gas.nasa_a4 = -0.03701536e-06
    gas.nasa_a5 = 0.15255685e-10
    gas.nasa_a6 = -0.02003815e+06
    gas.nasa_a7 = 0.01877256e+03
    
    gas = gas_data[11]
    gas.constituent_name = "Hexane"
    gas.constituent_formula = "C6H14"
    gas.std_ref_molar_enth_of_form = -166.966
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = -46.7786
    gas.shomate_b = 711.187
    gas.shomate_c = -438.39
    gas.shomate_d = 103.784
    gas.shomate_e = 1.23887
    gas.shomate_f = -176.813
    gas.shomate_g = -999.0
    gas.shomate_h = -166.966
    gas.num_carbons = 6.0
    gas.num_hydrogens = 14.0
    gas.num_oxygens = 0.0
    gas.molecular_weight = 86.18
    gas.nasa_a1 = 0.01836174e+02
    gas.nasa_a2 = 0.05098461e+00
    gas.nasa_a3 = 0.12595857e-04
    gas.nasa_a4 = -0.04428362e-06
    gas.nasa_a5 = 0.01872237e-09
    gas.nasa_a6 = -0.02292749e+06
    gas.nasa_a7 = 0.02088145e+03
    
    gas = gas_data[12]
    gas.constituent_name = "Methanol"
    gas.constituent_formula = "CH3OH"
    gas.std_ref_molar_enth_of_form = -201.102
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = 14.1952
    gas.shomate_b = 97.7218
    gas.shomate_c = -9.73279
    gas.shomate_d = -12.8461
    gas.shomate_e = 0.15819
    gas.shomate_f = -209.037
    gas.shomate_g = -999.0
    gas.shomate_h = -201.102
    gas.num_carbons = 1.0
    gas.num_hydrogens = 4.0
    gas.num_oxygens = 1.0
    gas.molecular_weight = 32.04
    gas.nasa_a1 = 0.02660115e+02
    gas.nasa_a2 = 0.07341508e-01
    gas.nasa_a3 = 0.07170050e-04
    gas.nasa_a4 = -0.08793194e-07
    gas.nasa_a5 = 0.02390570e-10
    gas.nasa_a6 = -0.02535348e+06
    gas.nasa_a7 = 0.11232631e+02
    
    gas = gas_data[13]
    gas.constituent_name = "Ethanol"
    gas.constituent_formula = "C2H5OH"
    gas.std_ref_molar_enth_of_form = -234.441
    gas.thermo_mode = ThermodynamicMode.NISTShomate
    gas.shomate_a = -8.87256
    gas.shomate_b = 282.389
    gas.shomate_c = -178.85
    gas.shomate_d = 46.3528
    gas.shomate_e = 0.48364
    gas.shomate_f = -241.239
    gas.shomate_g = -999.0
    gas.shomate_h = -234.441
    gas.num_carbons = 2.0
    gas.num_hydrogens = 6.0
    gas.num_oxygens = 1.0
    gas.molecular_weight = 46.07
    gas.nasa_a1 = 0.18461027e+01
    gas.nasa_a2 = 0.20475008e-01
    gas.nasa_a3 = 0.39904089e-05
    gas.nasa_a4 = -0.16585986e-07
    gas.nasa_a5 = 0.73090440e-11
    gas.nasa_a6 = -0.29663086e+05
    gas.nasa_a7 = 0.17289993e+02

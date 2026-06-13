# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals.ProgNameConversion (String)
# - InputProcessor.SameString(a: String, b: String) -> Bool
# - InputProcessor.FindItemInList(item: String, list: List, size: Int) -> Int
# - InputProcessor.GetNewUnitNumber() -> Int
# - InputProcessor.ProcessInput(idd_old: String, idd_new: String, idf_file: String) -> None
# - InputProcessor.GetObjectDefInIDD(...) -> None
# - InputProcessor.GetNewObjectDefInIDD(...) -> None
# - General.MakeLowerCase(s: String) -> String
# - General.MakeUPPERCase(s: String) -> String
# - General.MakeUpperCase(s: String) -> String
# - VCompareGlobalRoutines.DisplayString(msg: String) -> None
# - VCompareGlobalRoutines.WriteOutIDFLines(...) -> None
# - VCompareGlobalRoutines.WriteOutIDFLinesAsComments(...) -> None
# - VCompareGlobalRoutines.CheckSpecialObjects(...) -> None
# - VCompareGlobalRoutines.ScanOutputVariablesForReplacement(...) -> None
# - VCompareGlobalRoutines.writePreprocessorObject(...) -> None
# - VCompareGlobalRoutines.CreateNewName(...) -> None
# - VCompareGlobalRoutines.ProcessRviMviFiles(filepath: String, ext: String) -> None
# - VCompareGlobalRoutines.CloseOut() -> None
# - VCompareGlobalRoutines.GetNumSectionsFound(section: String) -> Int
# - VCompareGlobalRoutines.copyfile(src: String, dst: String) -> Bool
# - DataGlobals.ShowWarningError(msg: String, unit: Optional[Int]) -> None
# - DataGlobals.ShowFatalError(msg: String, unit: Optional[Int]) -> None

from collections import List
import math

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: List[String]
    var numbers: List[Float64]
    var commt_s: Int
    var commt_e: Int

struct ObjectDefInfo:
    var name: String

struct ExternalState:
    var prog_name_conversion: String
    var ver_string: String
    var version_num: Float64
    var s_version_num: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var program_path: String
    var auditf: Int
    var full_file_name: String
    var file_name_path: String
    var idf_records: List[IDFRecord]
    var comments: List[String]
    var num_idf_records: Int
    var cur_comment: Int
    var processing_imf_file: Bool
    var fatal_error: Bool
    var object_def: List[ObjectDefInfo]
    var num_object_defs: Int
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    var new_rep_var_caution: List[String]
    var num_rep_var_names: Int
    var not_in_new: List[String]
    var blank: String
    var otm_var_caution: List[Bool]
    var cmtr_var_caution: List[Bool]
    var cmtr_d_var_caution: List[Bool]
    var dif_lfn_handle: Int

fn string_trim(s: String) -> String:
    return s.rstrip()

fn string_len_trim(s: String) -> Int:
    return len(s.rstrip())

fn string_adjustl(s: String) -> String:
    return s.lstrip()

fn set_this_version_variables(inout state: ExternalState) -> None:
    state.ver_string = 'Conversion 8.8 => 8.9'
    state.version_num = 8.9
    state.s_version_num = '8.9'
    state.idd_file_name_with_path = string_trim(state.program_path) + 'V8-8-0-Energy+.idd'
    state.new_idd_file_name_with_path = string_trim(state.program_path) + 'V8-9-0-Energy+.idd'
    state.rep_var_file_name_with_path = string_trim(state.program_path) + 'Report Variables 8-8-0 to 8-9-0.csv'

fn fix_fuel_types(inout in_out_arg: List[String], index: Int) -> None:
    if index < 0 or index >= len(in_out_arg):
        return
    var arg = in_out_arg[index]
    if arg == '':
        return
    var arg_upper = arg.upper()
    
    if arg_upper == 'ELECTRIC':
        in_out_arg[index] = 'Electricity'
    elif arg_upper == 'ELEC':
        in_out_arg[index] = 'Electricity'
    elif arg_upper == 'GAS':
        in_out_arg[index] = 'NaturalGas'
    elif arg_upper == 'NATURAL GAS':
        in_out_arg[index] = 'NaturalGas'
    elif arg_upper == 'PROPANE':
        in_out_arg[index] = 'PropaneGas'
    elif arg_upper == 'LPG':
        in_out_arg[index] = 'PropaneGas'
    elif arg_upper == 'PROPANE GAS':
        in_out_arg[index] = 'PropaneGas'
    elif arg_upper == 'FUEL OIL #1':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'FUEL OIL':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'DISTILLATE OIL':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'DISTILLATEOIL':
        in_out_arg[index] = 'FuelOil#1'
    elif arg_upper == 'FUEL OIL #2':
        in_out_arg[index] = 'FuelOil#2'
    elif arg_upper == 'RESIDUAL OIL':
        in_out_arg[index] = 'FuelOil#2'
    elif arg_upper == 'RESIDUALOIL':
        in_out_arg[index] = 'FuelOil#2'

fn create_new_idf_using_rules(
    inout state: ExternalState,
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> None:
    var first_time = True
    if first_time:
        first_time = False
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension
    end_of_file[0] = False
    var ios = 0
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file[0]:
            var full_file_name: String
            if ask_for_input:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        full_file_name = String()
                        ios = 0
                    except:
                        ios = 1
                        full_file_name = ''
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = state.blank
                    ios = 1
            
            if len(full_file_name) > 0 and full_file_name[0] == '!':
                full_file_name = state.blank
                continue
            
            var units_arg = state.blank
            if ios != 0:
                full_file_name = state.blank
            
            full_file_name = string_adjustl(full_file_name)
            
            if full_file_name != state.blank:
                var dot_pos = full_file_name.rfind('.')
                if dot_pos >= 0:
                    dot_pos += 1
                    state.file_name_path = full_file_name[:dot_pos-1]
                    local_file_extension = state.make_lower_case(full_file_name[dot_pos:])
                else:
                    dot_pos = 0
                    state.file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    full_file_name = string_trim(full_file_name) + '.idf'
                    local_file_extension = 'idf'
                
                var dif_lfn = 0
                
                var file_ok = False
                try:
                    with open(full_file_name, 'r') as f:
                        file_ok = True
                except:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + string_trim(full_file_name))
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ['idf', 'imf']:
                    var checkrvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    var dif_file_path: String
                    if diff_only:
                        dif_file_path = state.file_name_path + '.' + string_trim(local_file_extension) + 'dif'
                    else:
                        dif_file_path = state.file_name_path + '.' + string_trim(local_file_extension) + 'new'
                    
                    var dif_lfn_handle = open(dif_file_path, 'w')
                    
                    if local_file_extension == 'imf':
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    var num_alphas = 0
                    var num_numbers = 0
                    var cur_args = 0
                    
                    var alphas = List[String](capacity=state.max_alpha_args_found + 1)
                    var numbers = List[Float64](capacity=state.max_numeric_args_found + 1)
                    var in_args = List[String](capacity=state.max_total_args + 1)
                    var temp_args = List[String](capacity=state.max_total_args + 1)
                    var aorn = List[Bool](capacity=state.max_total_args + 1)
                    var req_fld = List[Bool](capacity=state.max_total_args + 1)
                    var fld_names = List[String](capacity=state.max_total_args + 1)
                    var fld_defaults = List[String](capacity=state.max_total_args + 1)
                    var fld_units = List[String](capacity=state.max_total_args + 1)
                    
                    var nw_aorn = List[Bool](capacity=state.max_total_args + 1)
                    var nw_req_fld = List[Bool](capacity=state.max_total_args + 1)
                    var nw_fld_names = List[String](capacity=state.max_total_args + 1)
                    var nw_fld_defaults = List[String](capacity=state.max_total_args + 1)
                    var nw_fld_units = List[String](capacity=state.max_total_args + 1)
                    
                    var out_args = List[String](capacity=state.max_total_args + 1)
                    var match_arg = List[String](capacity=state.max_total_args + 1)
                    var delete_this_record = List[Bool](capacity=state.num_idf_records + 1)
                    
                    no_version = True
                    for num in range(1, state.num_idf_records + 1):
                        if state.idf_records[num].name.upper() != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    var schedule_type_limits_any_number = False
                    for num in range(1, state.num_idf_records + 1):
                        if state.idf_records[num].name != 'ScheduleTypeLimits':
                            continue
                        if state.idf_records[num].alphas[1] != 'Any Number':
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num]:
                            dif_lfn_handle.write('! Deleting: ' + string_trim(state.idf_records[num].name) + '="' + string_trim(state.idf_records[num].alphas[1]) + '".\n')
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num]:
                            continue
                        
                        var object_name = state.idf_records[num].name
                        var object_name_upper = object_name.upper()
                        
                        if object_name_upper == 'PROGRAMCONTROL':
                            continue
                        if object_name_upper == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if object_name_upper == 'AIRFLOW MODEL':
                            continue
                        if object_name_upper == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if object_name_upper == 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS':
                            continue
                        if object_name_upper == 'WATER HEATER:SIMPLE':
                            dif_lfn_handle.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                            continue
                        
                        var nodiff = True
                        var written = False
                        
                        if object_name_upper == 'VERSION':
                            if in_args[1][:3] == state.s_version_num and arg_file:
                                latest_version = True
                                break
                            nodiff = False
                            out_args[1] = state.s_version_num
                        
                        elif object_name_upper == 'ZONEHVAC:EQUIPMENTLIST':
                            nodiff = False
                            out_args[1] = in_args[1]
                            out_args[2] = 'SequentialLoad'
                            out_args[3:cur_args+2] = in_args[2:cur_args+1]
                            cur_args = cur_args + 1
                        
                        elif object_name_upper == 'AIRCONDITIONER:VARIABLEREFRIGERANTFLOW':
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 67:
                                fix_fuel_types(out_args, 67)
                        
                        elif object_name_upper == 'BOILER:HOTWATER':
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 2:
                                fix_fuel_types(out_args, 2)
                            if cur_args >= 15 and in_args[15] == 'VariableFlow':
                                out_args[15] = 'LeavingSetpointModulated'
                        
                        elif object_name_upper == 'BOILER:STEAM':
                            nodiff = False
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            if cur_args >= 2:
                                fix_fuel_types(out_args, 2)
                        
                        elif object_name_upper == 'BRANCH':
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            nodiff = True
                            var i = 0
                            while True:
                                i += 1
                                var cur_field = 4 * (i - 1) + 3
                                if cur_field > cur_args:
                                    break
                                if in_args[cur_field] == "GroundHeatExchanger:Vertical":
                                    out_args[cur_field] = "GroundHeatExchanger:System"
                    
                    dif_lfn_handle.close()
            else:
                end_of_file[0] = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[0] = False
            else:
                end_of_file[0] = True
                still_working = False

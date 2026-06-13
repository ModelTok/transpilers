from memory import Span, UnsafePointer
from collections import InlineArray
from math import max as math_max

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: blank, MaxNameLength, ProgNameConversion, ProgramPath
# - DataVCompareGlobals: IDFRecords, Comments, NumIDFRecords, CurComment, ObjectDef, NumObjectDefs, NotInNew, FatalError, ProcessingIMFFile, OldRepVarName, NewRepVarName, NewRepVarCaution, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, Alphas, Numbers, InArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, MatchArg, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, NumAlphas, NumNumbers, NumRepVarNames, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, Auditf
# - VCompareGlobalRoutines: GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumSectionsFound, SameString, MakeUPPERCase, MakeLowerCase, FindItemInList, DisplayString, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, ScanOutputVariablesForReplacement, writePreprocessorObject, ProcessInput, CloseOut, CreateNewName, ProcessRviMviFiles, copyfile
# - General: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - External: GetNewUnitNumber, TrimTrailZeros, CalculateMuEMPD

struct GlobalState:
    var blank: String
    var max_name_length: Int
    var prog_name_conversion: String
    var program_path: String
    var idf_records: DynamicVector[IDFRecord]
    var comments: DynamicVector[String]
    var num_idf_records: Int
    var cur_comment: Int
    var object_def: DynamicVector[ObjectDef]
    var num_object_defs: Int
    var not_in_new: DynamicVector[String]
    var fatal_error: Bool
    var processing_imf_file: Bool
    var old_rep_var_name: DynamicVector[String]
    var new_rep_var_name: DynamicVector[String]
    var new_rep_var_caution: DynamicVector[String]
    var otm_var_caution: DynamicVector[Bool]
    var cmtr_var_caution: DynamicVector[Bool]
    var cmtr_d_var_caution: DynamicVector[Bool]
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[String]
    var in_args: DynamicVector[String]
    var aor_n: DynamicVector[Bool]
    var req_fld: DynamicVector[Bool]
    var fld_names: DynamicVector[String]
    var fld_defaults: DynamicVector[String]
    var fld_units: DynamicVector[String]
    var nw_aor_n: DynamicVector[Bool]
    var nw_req_fld: DynamicVector[Bool]
    var nw_fld_names: DynamicVector[String]
    var nw_fld_defaults: DynamicVector[String]
    var nw_fld_units: DynamicVector[String]
    var out_args: DynamicVector[String]
    var match_arg: DynamicVector[String]
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var num_alphas: Int
    var num_numbers: Int
    var num_rep_var_names: Int
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var full_file_name: String
    var file_name_path: String
    var auditf: FileHandle

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var commt_s: Int
    var commt_e: Int

struct ObjectDef:
    var name: String

struct DElightRefPtType:
    var ref_pt_name: String
    var control_name: String
    var x: String
    var y: String
    var z: String
    var frac_zone: String
    var illum_set_pt: String
    var zone_name: String
    
    fn __init__(inout self):
        self.ref_pt_name = ""
        self.control_name = ""
        self.x = ""
        self.y = ""
        self.z = ""
        self.frac_zone = ""
        self.illum_set_pt = ""
        self.zone_name = ""

fn set_this_version_variables(inout state: GlobalState) -> None:
    """SetThisVersionVariables subroutine"""
    state.blank = "Conversion 8.5 => 8.6"
    var ver_num: Float64 = 8.6
    state.prog_name_conversion = '8.6'
    var trim_path = state.program_path.rstrip()
    state.idd_file_name_with_path = trim_path + 'V8-5-0-Energy+.idd'
    state.new_idd_file_name_with_path = trim_path + 'V8-6-0-Energy+.idd'
    state.rep_var_file_name_with_path = trim_path + 'Report Variables 8-5-0 to 8-6-0.csv'

fn make_upper_case(s: String) -> String:
    return s.upper()

fn make_lower_case(s: String) -> String:
    return s.lower()

fn same_string(s1: String, s2: String) -> Bool:
    return make_upper_case(s1) == make_upper_case(s2)

fn find_item_in_list(item: String, list: DynamicVector[String], size: Int) -> Int:
    for i in range(size):
        if same_string(item, list[i]):
            return i + 1
    return 0

fn create_new_idf_using_rules(
    inout state: GlobalState,
    end_of_file_io: Span[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> None:
    """CreateNewIDFUsingRules subroutine"""
    
    var d_light_ref_pt = DynamicVector[DElightRefPtType]()
    var num_d_light_ref_pt = 0
    var i_ref_pt = 0
    
    var ios = 0
    var dot_pos = 0
    var na = 0
    var nn = 0
    var cur_args = 0
    var dif_lfn = 0
    var xcount = 0
    var num = 0
    var unitsarg = ""
    var object_name = ""
    var uc_rep_var_name = ""
    var uc_comp_rep_var_name = ""
    var del_this = False
    var pos = 0
    var pos2 = 0
    var exit_because_bad_file = False
    var still_working = True
    var nodiff = False
    var checkrvi = False
    var no_version = True
    var diff_min_fields = False
    var written = False
    
    var first_time = True
    var var_idx = 0
    var cur_var = 0
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = " "
    var wild_match = False
    var conn_comp = False
    var conn_comp_ctrl = False
    var file_exist = False
    var created_output_name = ""
    var delete_this_record = DynamicVector[Bool]()
    var c_out_args = 0
    var units_field = ""
    var schedule_type_limits_any_number = False
    var cycling = False
    var continuous = False
    var out_schedule_name = ""
    var is_d_light_out_var = False
    
    var material_density: Float64 = 0.0
    var empd_coeff_a: Float64 = 0.0
    var empd_coeff_b: Float64 = 0.0
    var empd_coeff_c: Float64 = 0.0
    var empd_coeff_d: Float64 = 0.0
    var empd_coeff_d_empd: Float64 = 0.0
    var mu_empd: Float64 = 0.0
    var matl_search_num = 0
    var found_material = False
    
    var err_flag = False
    
    var i = 0
    var cur_field = 0
    var new_field = 0
    var ka_index = 0
    var search_num = 0
    var alpha_num_i = 0
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file_io[0] = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file_io[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                var line = input()
                state.full_file_name = line
            else:
                if not arg_file:
                    try:
                        var line_input = input()
                        state.full_file_name = line_input
                        ios = 0
                    except:
                        state.full_file_name = ""
                        ios = 1
                elif not arg_file_being_done:
                    state.full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = ""
                    ios = 1
                
                if state.full_file_name.startswith("!"):
                    state.full_file_name = ""
                    continue
            
            unitsarg = ""
            if ios != 0:
                state.full_file_name = ""
            state.full_file_name = state.full_file_name.lstrip()
            
            if state.full_file_name != "":
                print("Processing IDF -- " + state.full_file_name)
                print("Processing IDF -- " + state.full_file_name, file=state.auditf)
                
                dot_pos = state.full_file_name.rfind(".")
                if dot_pos != -1:
                    state.file_name_path = state.full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(state.full_file_name[dot_pos+1:])
                else:
                    state.file_name_path = state.full_file_name
                    print("assuming file extension of .idf")
                    print("..assuming file extension of .idf", file=state.auditf)
                    state.full_file_name = state.full_file_name + ".idf"
                    local_file_extension = "idf"
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    var dif_file_name = ""
                    if diff_only:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_file_name = state.file_name_path + "." + local_file_extension + "new"
                    
                    var dif_file: FileHandle
                    if local_file_extension == "imf":
                        print("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", file=state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    for idx in range(state.num_idf_records):
                        delete_this_record.push_back(False)
                    
                    no_version = True
                    for n in range(state.num_idf_records):
                        if make_upper_case(state.idf_records[n].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    schedule_type_limits_any_number = False
                    for n in range(state.num_idf_records):
                        if not same_string(state.idf_records[n].name, "ScheduleTypeLimits"):
                            continue
                        if not same_string(state.idf_records[n].alphas[0], "Any Number"):
                            continue
                        schedule_type_limits_any_number = True
                        break
                    
                    for n in range(state.num_idf_records):
                        if delete_this_record[n]:
                            print("! Deleting: " + state.idf_records[n].name + "=\"" + state.idf_records[n].alphas[0] + "\".", file=dif_file)
                    
                    if not d_light_ref_pt:
                        num_d_light_ref_pt = 0
                        for n in range(state.num_idf_records):
                            if make_upper_case(state.idf_records[n].name) == "DAYLIGHTING:DELIGHT:REFERENCEPOINT":
                                num_d_light_ref_pt += 1
                        
                        for _ in range(num_d_light_ref_pt):
                            d_light_ref_pt.push_back(DElightRefPtType())
                        
                        i_ref_pt = 0
                        for n in range(state.num_idf_records):
                            if make_upper_case(state.idf_records[n].name) == "DAYLIGHTING:DELIGHT:REFERENCEPOINT":
                                d_light_ref_pt[i_ref_pt].ref_pt_name = state.idf_records[n].alphas[0]
                                d_light_ref_pt[i_ref_pt].control_name = state.idf_records[n].alphas[1]
                                d_light_ref_pt[i_ref_pt].x = str(state.idf_records[n].numbers[0])
                                d_light_ref_pt[i_ref_pt].y = str(state.idf_records[n].numbers[1])
                                d_light_ref_pt[i_ref_pt].z = str(state.idf_records[n].numbers[2])
                                d_light_ref_pt[i_ref_pt].frac_zone = str(state.idf_records[n].numbers[3])
                                d_light_ref_pt[i_ref_pt].illum_set_pt = str(state.idf_records[n].numbers[4])
                                i_ref_pt += 1
                        
                        for n in range(state.num_idf_records):
                            if make_upper_case(state.idf_records[n].name) == "DAYLIGHTING:DELIGHT:CONTROLS":
                                for irf in range(num_d_light_ref_pt):
                                    if make_upper_case(state.idf_records[n].alphas[0]) == make_upper_case(d_light_ref_pt[irf].control_name):
                                        d_light_ref_pt[irf].zone_name = state.idf_records[n].alphas[1]
                    
                    for num_rec in range(state.num_idf_records):
                        if delete_this_record[num_rec]:
                            continue
                        
                        if no_version and num_rec == 0:
                            state.out_args[0] = state.prog_name_conversion
                            cur_args = 1
                        
                        var obj_name = state.idf_records[num_rec].name
                        var obj_upper = make_upper_case(obj_name.rstrip())
                        
                        if obj_upper == "PROGRAMCONTROL":
                            continue
                        if obj_upper == "SKY RADIANCE DISTRIBUTION":
                            continue
                        if obj_upper == "AIRFLOW MODEL":
                            continue
                        if obj_upper == "GENERATOR:FC:BATTERY DATA":
                            continue
                        if obj_upper == "AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS":
                            continue
                        if obj_upper == "WATER HEATER:SIMPLE":
                            print("! ** The WATER HEATER:SIMPLE object has been deleted", file=dif_file)
                            continue
                        
                        object_name = state.idf_records[num_rec].name
                        
                        state.num_alphas = state.idf_records[num_rec].num_alphas
                        state.num_numbers = state.idf_records[num_rec].num_numbers
                        
                        for idx in range(state.num_alphas):
                            state.alphas[idx] = state.idf_records[num_rec].alphas[idx]
                        for idx in range(state.num_numbers):
                            state.numbers[idx] = state.idf_records[num_rec].numbers[idx]
                        
                        cur_args = state.num_alphas + state.num_numbers
                        
                        na = 0
                        nn = 0
                        for arg in range(cur_args):
                            if state.aor_n[arg]:
                                state.in_args[arg] = state.alphas[na]
                                na += 1
                            else:
                                state.in_args[arg] = str(state.numbers[nn])
                                nn += 1
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        for alpha_idx in range(cur_args):
                            if same_string("COIL:HEATING:GAS", state.in_args[alpha_idx]):
                                state.in_args[alpha_idx] = "Coil:Heating:Fuel"
                                nodiff = False
                        
                        if obj_upper == "VERSION":
                            if state.in_args[0][:3] == state.prog_name_conversion and arg_file:
                                latest_version = True
                                break
                            state.out_args[0] = state.prog_name_conversion
                            nodiff = False
                        
                        elif obj_upper == "EXTERIOR:FUELEQUIPMENT":
                            object_name = "Exterior:FuelEquipment"
                            nodiff = False
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            if same_string("Gas", state.in_args[1]):
                                state.out_args[1] = "NaturalGas"
                            if same_string("LPG", state.in_args[1]):
                                state.out_args[1] = "PropaneGas"
                        
                        elif obj_upper == "HVACTEMPLATE:SYSTEM:UNITARYSYSTEM":
                            object_name = "HVACTemplate:System:UnitarySystem"
                            nodiff = False
                            for i_arg in range(56):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            for i_arg in range(57, cur_args - 1):
                                state.out_args[i_arg] = state.in_args[i_arg + 1]
                            cur_args -= 1
                        
                        elif obj_upper == "HVACTEMPLATE:SYSTEM:UNITARY":
                            object_name = "HVACTemplate:System:Unitary"
                            nodiff = False
                            for i_arg in range(39):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            for i_arg in range(40, cur_args - 1):
                                state.out_args[i_arg] = state.in_args[i_arg + 1]
                            cur_args -= 1
                        
                        elif obj_upper == "CHILLERHEATER:ABSORPTION:DIRECTFIRED":
                            object_name = "ChillerHeater:Absorption:DirectFired"
                            nodiff = False
                            for i_arg in range(32):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            state.out_args[32] = state.in_args[33]
                            state.out_args[33] = state.in_args[34]
                            cur_args -= 1
                        
                        elif obj_upper == "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MINIMUM":
                            object_name = "SetpointManager:SingleZone:Humidity:Minimum"
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = state.in_args[3]
                            state.out_args[2] = state.in_args[4]
                            cur_args -= 2
                        
                        elif obj_upper == "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MAXIMUM":
                            object_name = "SetpointManager:SingleZone:Humidity:Maximum"
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = state.in_args[3]
                            state.out_args[2] = state.in_args[4]
                            cur_args -= 2
                        
                        elif obj_upper == "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT":
                            nodiff = False
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            if same_string(state.in_args[15], "REVERSE"):
                                if (not same_string(state.in_args[16], "")) or (not same_string(state.in_args[17], "")):
                                    state.out_args[15] = "ReverseWithLimits"
                        
                        elif obj_upper == "BRANCH":
                            object_name = "Branch"
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = state.in_args[2]
                            cur_args -= 1
                            nodiff = False
                            cur_field = 3
                            new_field = 2
                            while True:
                                state.out_args[new_field] = state.in_args[cur_field]
                                state.out_args[new_field + 1] = state.in_args[cur_field + 1]
                                state.out_args[new_field + 2] = state.in_args[cur_field + 2]
                                state.out_args[new_field + 3] = state.in_args[cur_field + 3]
                                cur_field += 5
                                new_field += 4
                                if new_field > cur_args:
                                    break
                                cur_args -= 1
                        
                        elif obj_upper == "AIRTERMINAL:SINGLEDUCT:INLETSIDEMIXER":
                            nodiff = False
                            object_name = "AirTerminal:SingleDuct:Mixer"
                            for i_arg in range(6):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            cur_args += 1
                            state.out_args[6] = "InletSide"
                        
                        elif obj_upper == "AIRTERMINAL:SINGLEDUCT:SUPPLYSIDEMIXER":
                            nodiff = False
                            object_name = "AirTerminal:SingleDuct:Mixer"
                            for i_arg in range(6):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            cur_args += 1
                            state.out_args[6] = "SupplySide"
                        
                        elif obj_upper == "ZONEHVAC:AIRDISTRIBUTIONUNIT":
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            if same_string("AirTerminal:SingleDuct:InletSideMixer", state.in_args[2]) or same_string("AirTerminal:SingleDuct:SupplySideMixer", state.in_args[2]):
                                state.out_args[2] = "AirTerminal:SingleDuct:Mixer"
                        
                        elif obj_upper == "OTHEREQUIPMENT":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = "None"
                            for i_arg in range(9):
                                state.out_args[i_arg + 2] = state.in_args[i_arg + 1]
                            cur_args += 1
                        
                        elif obj_upper == "COIL:HEATING:GAS":
                            nodiff = False
                            object_name = "Coil:Heating:Fuel"
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = state.in_args[1]
                            state.out_args[2] = "NaturalGas"
                            for i_arg in range(8):
                                state.out_args[i_arg + 3] = state.in_args[i_arg + 2]
                            cur_args += 1
                        
                        elif obj_upper == "DAYLIGHTING:CONTROLS":
                            nodiff = False
                            state.out_args[0] = state.in_args[0].rstrip() + "_DaylCtrl"
                            state.out_args[1] = state.in_args[0]
                            state.out_args[2] = "SplitFlux"
                            state.out_args[3] = state.in_args[19]
                            if state.in_args[12] == "1":
                                state.out_args[4] = "Continuous"
                            elif state.in_args[12] == "2":
                                state.out_args[4] = "Stepped"
                            elif state.in_args[12] == "3":
                                state.out_args[4] = "ContinuousOff"
                            else:
                                state.out_args[4] = "Continuous"
                            for i_arg in range(4):
                                state.out_args[i_arg + 5] = state.in_args[i_arg + 15]
                            if state.out_args[7] == "0":
                                state.out_args[7] = ""
                            state.out_args[9] = state.in_args[0].rstrip() + "_DaylRefPt1"
                            state.out_args[10] = state.in_args[13]
                            state.out_args[11] = state.in_args[14]
                            state.out_args[12] = ""
                            state.out_args[13] = state.in_args[0].rstrip() + "_DaylRefPt1"
                            state.out_args[14] = state.in_args[8]
                            state.out_args[15] = state.in_args[10]
                            if state.in_args[1] == "2":
                                state.out_args[16] = state.in_args[0].rstrip() + "_DaylRefPt2"
                                state.out_args[17] = state.in_args[9]
                                state.out_args[18] = state.in_args[11]
                                cur_args = 19
                            else:
                                cur_args = 16
                            written = True
                        
                        elif obj_upper == "DAYLIGHTING:DELIGHT:CONTROLS":
                            object_name = "Daylighting:Controls"
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = state.in_args[1]
                            state.out_args[2] = "DElight"
                            state.out_args[3] = ""
                            if state.in_args[4] == "1":
                                state.out_args[4] = "Continuous"
                            elif state.in_args[4] == "2":
                                state.out_args[4] = "Stepped"
                            elif state.in_args[4] == "3":
                                state.out_args[4] = "ContinuousOff"
                            else:
                                state.out_args[4] = "Continuous"
                            for i_arg in range(4):
                                state.out_args[i_arg + 5] = state.in_args[i_arg + 3]
                            if state.out_args[7] == "0":
                                state.out_args[7] = ""
                            state.out_args[9] = ""
                            state.out_args[10] = "0"
                            state.out_args[11] = ""
                            state.out_args[12] = state.in_args[7]
                            cur_args = 13
                            for irf in range(num_d_light_ref_pt):
                                if make_upper_case(state.in_args[0]) == make_upper_case(d_light_ref_pt[irf].control_name):
                                    state.out_args[cur_args] = d_light_ref_pt[irf].ref_pt_name
                                    state.out_args[cur_args + 1] = d_light_ref_pt[irf].frac_zone
                                    state.out_args[cur_args + 2] = d_light_ref_pt[irf].illum_set_pt
                                    cur_args += 3
                        
                        elif obj_upper == "DAYLIGHTING:DELIGHT:REFERENCEPOINT":
                            object_name = "Daylighting:ReferencePoint"
                            state.out_args[0] = state.in_args[0]
                            for irf in range(num_d_light_ref_pt):
                                if make_upper_case(state.in_args[1]) == make_upper_case(d_light_ref_pt[irf].control_name):
                                    state.out_args[1] = d_light_ref_pt[irf].zone_name
                            for i_arg in range(3):
                                state.out_args[i_arg + 2] = state.in_args[i_arg + 2]
                            cur_args = 5
                        
                        elif obj_upper == "MATERIALPROPERTY:MOISTUREPENETRATIONDEPTH:SETTINGS":
                            nodiff = False
                            state.out_args[0] = state.in_args[0]
                            state.out_args[1] = "Could not find Material Match for " + state.in_args[0]
                            state.out_args[2] = state.in_args[2]
                            state.out_args[3] = state.in_args[3]
                            state.out_args[4] = state.in_args[4]
                            state.out_args[5] = state.in_args[5]
                            state.out_args[6] = state.in_args[1]
                            state.out_args[7] = "0"
                            state.out_args[8] = "0"
                            state.out_args[9] = "0"
                            cur_args = 10
                            
                            found_material = False
                            for msn in range(state.num_idf_records):
                                if make_upper_case(state.idf_records[msn].name) != "MATERIAL":
                                    continue
                                if make_upper_case(state.idf_records[msn].alphas[0]) == make_upper_case(state.in_args[0]):
                                    found_material = True
                                    material_density = state.idf_records[msn].numbers[2]
                                    break
                            
                            if not found_material:
                                pass
                            
                            empd_coeff_a = Float64(state.in_args[2])
                            empd_coeff_b = Float64(state.in_args[3])
                            empd_coeff_c = Float64(state.in_args[4])
                            empd_coeff_d = Float64(state.in_args[5])
                            empd_coeff_d_empd = Float64(state.in_args[1])
                            mu_empd = 0.0
                            state.out_args[1] = String(mu_empd)
                        
                        elif obj_upper == "ENERGYMANAGEMENTSYSTEM:ACTUATOR":
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                            var actuator_upper = make_upper_case(state.in_args[3])
                            if actuator_upper == "OUTDOOR AIR DRYBLUB TEMPERATURE":
                                nodiff = True
                                for i_arg in range(cur_args):
                                    state.out_args[i_arg] = state.in_args[i_arg]
                                state.out_args[3] = "Outdoor Air Drybulb Temperature"
                            elif actuator_upper == "OUTDOOR AIR WETBLUB TEMPERATURE":
                                nodiff = True
                                for i_arg in range(cur_args):
                                    state.out_args[i_arg] = state.in_args[i_arg]
                                state.out_args[3] = "Outdoor Air Wetbulb Temperature"
                        
                        elif obj_upper == "OUTPUT:VARIABLE":
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                            if state.out_args[0] == "":
                                state.out_args[0] = "*"
                                nodiff = False
                            
                            if state.in_args[0] != "*":
                                is_d_light_out_var = False
                                if same_string(state.in_args[1][:27], "Daylighting Reference Point"):
                                    for irf in range(num_d_light_ref_pt):
                                        if make_upper_case(state.in_args[0]) == make_upper_case(d_light_ref_pt[irf].ref_pt_name):
                                            is_d_light_out_var = True
                                    if not is_d_light_out_var:
                                        state.out_args[0] = state.in_args[0].rstrip() + "_DaylCtrl"
                                
                                if same_string(state.in_args[1], "Daylighting Lighting Power Multiplier"):
                                    for irf in range(num_d_light_ref_pt):
                                        if make_upper_case(state.in_args[0]) == make_upper_case(d_light_ref_pt[irf].zone_name):
                                            is_d_light_out_var = True
                                            state.out_args[0] = d_light_ref_pt[irf].control_name
                                    if not is_d_light_out_var:
                                        state.out_args[0] = state.in_args[0].rstrip() + "_DaylCtrl"
                        
                        elif obj_upper in ("OUTPUT:METER", "OUTPUT:METER:METERFILEONLY", "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"):
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                        
                        elif obj_upper == "OUTPUT:TABLE:TIMEBINS":
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                            if state.out_args[0] == "":
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif obj_upper in ("EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE", "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"):
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                            if state.out_args[0] == "":
                                state.out_args[0] = "*"
                                nodiff = False
                        
                        elif obj_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                        
                        elif obj_upper == "OUTPUT:TABLE:MONTHLY":
                            nodiff = True
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            cur_var = 3
                            var_idx = 3
                            while var_idx < cur_args:
                                uc_rep_var_name = make_upper_case(state.in_args[var_idx])
                                state.out_args[cur_var] = state.in_args[var_idx]
                                state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                pos = uc_rep_var_name.find("[")
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.out_args[cur_var] = state.in_args[var_idx][:pos]
                                    state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                
                                del_this = False
                                var_idx += 2
                                if not del_this:
                                    cur_var += 2
                            cur_args = cur_var - 1
                        
                        elif obj_upper == "METER:CUSTOM":
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                            cur_var = 4
                            var_idx = 4
                            while var_idx < cur_args:
                                uc_rep_var_name = make_upper_case(state.in_args[var_idx])
                                state.out_args[cur_var] = state.in_args[var_idx]
                                state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                pos = uc_rep_var_name.find("[")
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.out_args[cur_var] = state.in_args[var_idx][:pos]
                                    state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                
                                del_this = False
                                var_idx += 2
                                if not del_this:
                                    cur_var += 2
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.out_args[arg] == "":
                                    cur_args -= 1
                                else:
                                    break
                        
                        elif obj_upper == "METER:CUSTOMDECREMENT":
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                            cur_var = 4
                            var_idx = 4
                            while var_idx < cur_args:
                                uc_rep_var_name = make_upper_case(state.in_args[var_idx])
                                state.out_args[cur_var] = state.in_args[var_idx]
                                state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                pos = uc_rep_var_name.find("[")
                                if pos >= 0:
                                    uc_rep_var_name = uc_rep_var_name[:pos]
                                    state.out_args[cur_var] = state.in_args[var_idx][:pos]
                                    state.out_args[cur_var + 1] = state.in_args[var_idx + 1]
                                
                                del_this = False
                                var_idx += 2
                                if not del_this:
                                    cur_var += 2
                            cur_args = cur_var
                            for arg in range(cur_var - 1, -1, -1):
                                if state.out_args[arg] == "":
                                    cur_args -= 1
                                else:
                                    break
                        
                        else:
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = True
                        
                        if diff_min_fields and nodiff:
                            for i_arg in range(cur_args):
                                state.out_args[i_arg] = state.in_args[i_arg]
                            nodiff = False
                            cur_args = math_max(state.num_idf_records, cur_args)
                        
                        if nodiff and diff_only:
                            continue
            else:
                end_of_file_io[0] = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file_io[0] = False
            else:
                end_of_file_io[0] = True
                still_working = False

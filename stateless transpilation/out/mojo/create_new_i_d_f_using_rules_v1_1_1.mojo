from math import floor
from collections import Dict, List


struct DataState:
    var VerString: String
    var VersionNum: Float64
    var IDDFileNameWithPath: String
    var NewIDDFileNameWithPath: String
    var RepVarFileNameWithPath: String
    var ProgramPath: String
    var FullFileName: String
    var FileNamePath: String
    var Auditf: String
    var ProcessingIMFFile: Bool
    var FatalError: Bool
    var IDFRecords: List[Dict[String, any]]
    var NumIDFRecords: Int
    var Comments: List[String]
    var CurComment: Int
    var ObjectDef: List[String]
    var NumObjectDefs: Int
    var OldRepVarName: List[String]
    var NewRepVarName: List[String]
    var NumRepVarNames: Int
    var NotInNew: List[String]
    var MaxAlphaArgsFound: Int
    var MaxNumericArgsFound: Int
    var MaxTotalArgs: Int
    var MakingPretty: Bool


fn set_this_version_variables(inout data_state: DataState) -> None:
    data_state.VerString = 'Conversion 1.1 => 1.1.1'
    data_state.VersionNum = 1.0
    data_state.IDDFileNameWithPath = data_state.ProgramPath.strip() + 'V1-1-0-Energy+.idd'
    data_state.NewIDDFileNameWithPath = data_state.ProgramPath.strip() + 'V1-1-1-Energy+.idd'
    data_state.RepVarFileNameWithPath = data_state.ProgramPath.strip() + 'Report Variables 1-1-0-020 to 1-1-1.csv'


fn make_upper_case(s: String) -> String:
    return s.upper()


fn make_lower_case(s: String) -> String:
    return s.lower()


fn same_string(s1: String, s2: String) -> Bool:
    return s1.lower() == s2.lower()


fn find_item_in_list(item: String, list_items: List[String], list_size: Int) -> Int:
    var item_upper = item.upper()
    for i in range(list_size):
        if list_items[i].upper() == item_upper:
            return i + 1
    return 0


@always_inline
fn write_string_to_file(file_handle: String, text: String) -> None:
    pass


fn create_new_idf_using_rules(
    inout data_state: DataState,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> None:
    var cond_eq_strings = InlineArray[String, 5](
        'COOLING TOWER:SINGLE SPEED    ',
        'COOLING TOWER:TWO SPEED       ',
        'GROUND HEAT EXCHANGER:VERTICAL',
        'GROUND HEAT EXCHANGER:SURFACE ',
        'GROUND HEAT EXCHANGER:POND    '
    )
    var num_cond_eq: Int = 5
    
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var local_file_extension: String = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        while not end_of_file:
            var full_file_name: String = ""
            
            if ask_for_input:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not arg_file:
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
            
            var units_arg: String = ""
            if ios != 0:
                full_file_name = ""
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                var dot_pos: Int = full_file_name.rfind(".")
                var file_name_path: String
                
                if dot_pos != -1:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name.strip() + ".idf"
                    local_file_extension = "idf"
                
                data_state.FileNamePath = file_name_path
                
                var file_ok: Bool = False
                try:
                    var f = open(full_file_name, "r")
                    file_ok = True
                    f.close()
                except:
                    file_ok = False
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ["idf", "imf"]:
                    var checkrvi: Bool = False
                    var dif_lfn: String
                    
                    if diff_only:
                        dif_lfn = file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_lfn = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        data_state.ProcessingIMFFile = True
                    else:
                        data_state.ProcessingIMFFile = False
                    
                    if data_state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    var alphas = InlineArray[String, 500]()
                    var numbers = InlineArray[Float64, 500]()
                    var in_args = InlineArray[String, 500]()
                    var aor_n = InlineArray[Bool, 500]()
                    var req_fld = InlineArray[Bool, 500]()
                    var fld_names = InlineArray[String, 500]()
                    var fld_defaults = InlineArray[String, 500]()
                    var fld_units = InlineArray[String, 500]()
                    var nw_aor_n = InlineArray[Bool, 500]()
                    var nw_req_fld = InlineArray[Bool, 500]()
                    var nw_fld_names = InlineArray[String, 500]()
                    var nw_fld_defaults = InlineArray[String, 500]()
                    var nw_fld_units = InlineArray[String, 500]()
                    var out_args = InlineArray[String, 500]()
                    var match_arg = InlineArray[Bool, 500]()
                    
                    var no_version: Bool = True
                    for num in range(data_state.NumIDFRecords):
                        if make_upper_case(data_state.IDFRecords[num]["Name"]) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    var lrbo: Int = 0
                    var clrbo: Int = 0
                    var hlrbo: Int = 0
                    var count: Int = lrbo + clrbo + hlrbo
                    
                    var lrbo_scheme = InlineArray[String, 1000]()
                    var lrbo_type = InlineArray[Int, 1000]()
                    lrbo = 0
                    
                    for num in range(data_state.NumIDFRecords):
                        var obj_name_upper = make_upper_case(data_state.IDFRecords[num]["Name"].strip())
                        
                        if obj_name_upper == "LOAD RANGE BASED OPERATION":
                            var object_name = data_state.IDFRecords[num]["Name"]
                            var num_alphas = data_state.IDFRecords[num]["NumAlphas"]
                            var num_numbers = data_state.IDFRecords[num]["NumNumbers"]
                            
                            var cur_args = num_alphas + num_numbers
                            var na: Int = 0
                            var nn: Int = 0
                            
                            for arg in range(cur_args):
                                if aor_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                            
                            var ffield: Bool = False
                            var mxfield: Bool = False
                            var minus: Bool = False
                            
                            for arg in range(1, cur_args, 3):
                                if ffield:
                                    ffield = False
                                else:
                                    var pos = out_args[arg].find("-")
                                    if pos > 0:
                                        minus = True
                                    elif minus:
                                        mxfield = True
                                
                                pos = out_args[arg+1].find("-")
                                if pos > 0:
                                    minus = True
                                elif minus:
                                    mxfield = True
                            
                            lrbo += 1
                            lrbo_scheme[lrbo-1] = make_upper_case(in_args[0])
                            
                            if mxfield:
                                lrbo_type[lrbo-1] = 0
                            elif not minus:
                                lrbo_type[lrbo-1] = 2
                            else:
                                lrbo_type[lrbo-1] = 1
                        
                        elif obj_name_upper == "HEATING LOAD RANGE BASED OPERATION":
                            lrbo += 1
                            lrbo_scheme[lrbo-1] = make_upper_case(data_state.IDFRecords[num]["Alphas"][0])
                            lrbo_type[lrbo-1] = 2
                        
                        elif obj_name_upper == "COOLING LOAD RANGE BASED OPERATION":
                            lrbo += 1
                            lrbo_scheme[lrbo-1] = make_upper_case(data_state.IDFRecords[num]["Alphas"][0])
                            lrbo_type[lrbo-1] = 1
                    
                    for num in range(data_state.NumIDFRecords):
                        if make_upper_case(data_state.IDFRecords[num]["Name"]) not in ["PLANT OPERATION SCHEMES", "CONDENSER OPERATION SCHEMES"]:
                            continue
                        
                        var num_alphas = data_state.IDFRecords[num]["NumAlphas"]
                        for arg in range(1, num_alphas, 3):
                            if make_upper_case(data_state.IDFRecords[num]["Alphas"][arg]) != "LOAD RANGE BASED OPERATION":
                                continue
                            var found = find_item_in_list(make_upper_case(data_state.IDFRecords[num]["Alphas"][arg+1]), lrbo_scheme, lrbo)
                            if found != 0:
                                if lrbo_type[found-1] == 1:
                                    data_state.IDFRecords[num]["Alphas"][arg] = "COOLING LOAD RANGE BASED OPERATION"
                                elif lrbo_type[found-1] == 2:
                                    data_state.IDFRecords[num]["Alphas"][arg] = "HEATING LOAD RANGE BASED OPERATION"
                    
                    for num in range(data_state.NumIDFRecords):
                        var object_name = data_state.IDFRecords[num]["Name"]
                        var num_alphas = data_state.IDFRecords[num]["NumAlphas"]
                        var num_numbers = data_state.IDFRecords[num]["NumNumbers"]
                        var cur_args = num_alphas + num_numbers
                        var nodiff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        if not data_state.MakingPretty:
                            var obj_upper = make_upper_case(data_state.IDFRecords[num]["Name"].strip())
                            
                            if obj_upper == "VERSION":
                                if in_args[0][0:5] == "1.1.1" and arg_file:
                                    latest_version = True
                                    break
                                out_args[0] = "1.1.1"
                            
                            elif obj_upper == "SKY RADIANCE DISTRIBUTION":
                                written = True
                            
                            elif obj_upper == "SURFACE:SHADING:DETACHED":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                            
                            elif obj_upper == "DAYLIGHTING":
                                if cur_args > 5:
                                    object_name = "Daylighting:Detailed"
                                    out_args[0] = in_args[0]
                                    for i in range(1, cur_args-3):
                                        out_args[i] = in_args[i+4]
                                    cur_args = cur_args - 3
                                else:
                                    object_name = "Daylighting:Simple"
                                    for i in range(4):
                                        out_args[i] = in_args[i]
                                    cur_args = 4
                            
                            elif obj_upper == "LOAD RANGE BASED OPERATION":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                ffield = True
                                mxfield = False
                                minus = False
                                
                                for arg in range(1, cur_args, 3):
                                    if ffield:
                                        ffield = False
                                    else:
                                        var pos = out_args[arg].find("-")
                                        if pos > 0:
                                            minus = True
                                        elif minus:
                                            mxfield = True
                                    
                                    pos = out_args[arg+1].find("-")
                                    if pos > 0:
                                        minus = True
                                    elif minus:
                                        mxfield = True
                                
                                if not minus:
                                    object_name = "Heating Load Range Based Operation"
                                else:
                                    object_name = "Cooling Load Range Based Operation"
                                    for arg in range(1, cur_args, 3):
                                        var pos = out_args[arg].find("-")
                                        if pos > 0:
                                            out_args[arg] = out_args[arg][0:pos] + " " + out_args[arg][pos+1:]
                                        pos = out_args[arg+1].find("-")
                                        if pos > 0:
                                            out_args[arg+1] = out_args[arg+1][0:pos] + " " + out_args[arg+1][pos+1:]
                            
                            elif obj_upper == "PLANT OPERATION SCHEMES":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                            
                            elif obj_upper == "CONDENSER OPERATION SCHEMES":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                            
                            elif obj_upper == "HEAT RECOVERY LOOP":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                            
                            elif obj_upper == "LOAD RANGE EQUIPMENT LIST":
                                nodiff = False
                                mxfield = False
                                var new_obj_name: String = ""
                                var match_eq: Int = 0
                                
                                for arg in range(1, cur_args, 2):
                                    var uc_line_name = make_upper_case(in_args[arg])
                                    for varg in range(num_cond_eq):
                                        if uc_line_name == cond_eq_strings[varg]:
                                            match_eq = 1
                                            new_obj_name = "CONDENSER EQUIPMENT LIST"
                                            break
                                    if match_eq == 1:
                                        break
                                
                                if match_eq != 1:
                                    new_obj_name = "PLANT EQUIPMENT LIST"
                                
                                for arg in range(1, cur_args, 2):
                                    uc_line_name = make_upper_case(in_args[arg])
                                    var found = find_item_in_list(uc_line_name, cond_eq_strings, num_cond_eq)
                                    if found != 0:
                                        if new_obj_name != "" and new_obj_name != "CONDENSER EQUIPMENT LIST":
                                            mxfield = True
                                        else:
                                            new_obj_name = "CONDENSER EQUIPMENT LIST"
                                    else:
                                        if new_obj_name != "" and new_obj_name != "PLANT EQUIPMENT LIST":
                                            mxfield = True
                                        else:
                                            new_obj_name = "PLANT EQUIPMENT LIST"
                                
                                if new_obj_name == "" or mxfield:
                                    new_obj_name = "LOAD RANGE EQUIPMENT LIST"
                                
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                object_name = new_obj_name
                            
                            elif obj_upper == "HEAT EXCHANGER:HYDRONIC:FREE COOLING":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                            
                            elif obj_upper in ["DESIGNDAY", "ELECTRIC EQUIPMENT", "BUILDING", "PURCHASED AIR", "CHILLER:COMBUSTION TURBINE", "CHILLER:ENGINEDRIVEN", "HEAT EXCHANGER:AIR TO AIR:GENERIC"]:
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                                for arg in range(cur_args, len(nw_fld_defaults)):
                                    out_args[arg] = nw_fld_defaults[arg]
                                cur_args = len(nw_fld_defaults)
                            
                            elif obj_upper == "WATERHEATER:SIMPLE":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                                for arg in range(cur_args, len(nw_fld_defaults)):
                                    out_args[arg] = nw_fld_defaults[arg]
                                cur_args = len(nw_fld_defaults)
                            
                            elif obj_upper == "WINDOWSHADINGCONTROL":
                                nodiff = False
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if same_string("InteriorNonInsulatingShade", in_args[1]):
                                    out_args[1] = "InteriorShade"
                                if same_string("ExteriorNonInsulatingShade", in_args[1]):
                                    out_args[1] = "ExteriorShade"
                                if same_string("InteriorInsulatingShade", in_args[1]):
                                    out_args[1] = "InteriorShade"
                                if same_string("ExteriorInsulatingShade", in_args[1]):
                                    out_args[1] = "ExteriorShade"
                                if same_string("Schedule", in_args[3]):
                                    out_args[3] = "OnIfScheduleAllows"
                                if same_string("SolarOnWindow", in_args[3]):
                                    out_args[3] = "OnIfHighSolarOnWindow"
                                if same_string("HorizontalSolar", in_args[3]):
                                    out_args[3] = "OnIfHighHorizontalSolar"
                                if same_string("OutsideAirTemp", in_args[3]):
                                    out_args[3] = "OnIfHighOutsideAirTemp"
                                if same_string("ZoneAirTemp", in_args[3]):
                                    out_args[3] = "OnIfHighZoneAirTemp"
                                if same_string("ZoneCooling", in_args[3]):
                                    out_args[3] = "OnIfHighZoneCooling"
                                if same_string("Glare", in_args[3]):
                                    out_args[3] = "OnIfHighGlare"
                                if same_string("DaylightIlluminance", in_args[3]):
                                    out_args[3] = "MeetDaylightIlluminanceSetpoint"
                            
                            elif obj_upper == "REPORT VARIABLE":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    nodiff = False
                            
                            elif obj_upper in ["REPORT METER", "REPORT METERFILEONLY", "REPORT CUMULATIVE METER", "REPORT CUMULATIVE METERFILEONLY"]:
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                            
                            elif obj_upper == "REPORT:TABLE:TIMEBINS":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    nodiff = False
                            
                            elif obj_upper == "REPORT:TABLE:MONTHLY":
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    nodiff = False
                            
                            else:
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False

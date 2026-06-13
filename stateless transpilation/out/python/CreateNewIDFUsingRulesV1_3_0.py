from dataclasses import dataclass, field
from typing import Protocol, List, Optional, Any
import os

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: MaxNameLength, Blank
# - DataVCompareGlobals: VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath,
#   RepVarFileNameWithPath, ProgramPath, FullFileName, Auditf, FileOK, MaxAlphaArgsFound,
#   MaxNumericArgsFound, MaxTotalArgs, NumIDFRecords, IDFRecords, Comments, CurComment,
#   ProcessingIMFFile, FatalError, NumObjectDefs, ObjectDef, NotInNew, ObjMinFlds,
#   NumRepVarNames, OldRepVarName, NewRepVarName, MakingPretty
# - VCompareGlobalRoutines: Various output/processing functions
# - InputProcessor: ProcessInput
# - General: MakeUPPERCase, MakeLowerCase, FindItemInList, ProcessNumber, RoundSigDigits,
#   SameString, TrimTrailZeros
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError


@dataclass
class IDFRecord:
    Name: str = ""
    NumAlphas: int = 0
    NumNumbers: int = 0
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[str] = field(default_factory=list)
    CommtS: int = 0
    CommtE: int = 0


@dataclass
class ObjectDefinition:
    Name: List[str] = field(default_factory=list)


class ExternalDeps(Protocol):
    MaxNameLength: int
    Blank: str
    VerString: str
    VersionNum: float
    IDDFileNameWithPath: str
    NewIDDFileNameWithPath: str
    RepVarFileNameWithPath: str
    ProgramPath: str
    FullFileName: str
    Auditf: int
    FileOK: bool
    MaxAlphaArgsFound: int
    MaxNumericArgsFound: int
    MaxTotalArgs: int
    NumIDFRecords: int
    IDFRecords: List[IDFRecord]
    Comments: List[str]
    CurComment: int
    ProcessingIMFFile: bool
    FatalError: bool
    NumObjectDefs: int
    ObjectDef: ObjectDefinition
    NotInNew: List[str]
    ObjMinFlds: int
    NumRepVarNames: int
    OldRepVarName: List[str]
    NewRepVarName: List[str]
    MakingPretty: bool


def set_this_version_variables(deps: ExternalDeps) -> None:
    deps.VerString = 'Conversion 1.2.3 => 1.3'
    deps.VersionNum = 1.0
    deps.IDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V1-2-3-Energy+.idd'
    deps.NewIDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V1-3-0-Energy+.idd'
    deps.RepVarFileNameWithPath = deps.ProgramPath.rstrip() + 'Report Variables 1-2-3-031 to 1-3-0.csv'


def create_new_idf_using_rules(
    deps: ExternalDeps,
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    # External function stubs
    display_string,
    get_new_unit_number,
    find_number,
    trim_trail_zeros,
    make_upper_case,
    make_lower_case,
    process_input,
    get_new_object_def_in_idd,
    get_object_def_in_idd,
    find_item_in_list,
    write_out_idf_lines_as_comments,
    same_string,
    show_warning_error,
    write_out_idf_lines,
    scan_output_variables_for_replacement,
    process_number,
    round_sig_digits,
    check_special_objects,
    process_rvi_mvi_files,
    close_out,
    create_new_name,
    copyfile,
) -> bool:
    
    max_name_length = deps.MaxNameLength
    blank = deps.Blank
    
    fmta = "(A)"
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    file_name_path = ""
    full_file_name = ""
    diff_lfn = 0
    
    err_flag = False
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                full_file_name = input()
            else:
                if not arg_file:
                    ios = 0
                    try:
                        full_file_name = input()
                    except:
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = blank
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = blank
                    continue
            
            local_file_extension = blank
            if ios != 0:
                full_file_name = blank
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != blank:
                display_string('Processing IDF -- ' + full_file_name)
                print(' Processing IDF -- ' + full_file_name, file=deps.Auditf)
                
                dot_pos = full_file_name.rfind('.')
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = make_lower_case(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    print(' ..assuming file extension of .idf', file=deps.Auditf)
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                diff_lfn = get_new_unit_number()
                file_ok = os.path.exists(full_file_name)
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    print('File not found=' + full_file_name, file=deps.Auditf)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    check_rvi = False
                    
                    if diff_only:
                        output_file = open(file_name_path + '.' + local_file_extension + 'dif', 'w')
                    else:
                        output_file = open(file_name_path + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', deps.Auditf)
                        deps.ProcessingIMFFile = True
                    else:
                        deps.ProcessingIMFFile = False
                    
                    process_input(deps.IDDFileNameWithPath, deps.NewIDDFileNameWithPath, full_file_name)
                    
                    if deps.FatalError:
                        exit_because_bad_file = True
                        output_file.close()
                        break
                    
                    alphas = [blank] * deps.MaxAlphaArgsFound
                    numbers = [blank] * deps.MaxNumericArgsFound
                    in_args = [blank] * deps.MaxTotalArgs
                    a_or_n = [False] * deps.MaxTotalArgs
                    req_fld = [False] * deps.MaxTotalArgs
                    fld_names = [blank] * deps.MaxTotalArgs
                    fld_defaults = [blank] * deps.MaxTotalArgs
                    fld_units = [blank] * deps.MaxTotalArgs
                    nw_a_or_n = [False] * deps.MaxTotalArgs
                    nw_req_fld = [False] * deps.MaxTotalArgs
                    nw_fld_names = [blank] * deps.MaxTotalArgs
                    nw_fld_defaults = [blank] * deps.MaxTotalArgs
                    nw_fld_units = [blank] * deps.MaxTotalArgs
                    out_args = [blank] * deps.MaxTotalArgs
                    match_arg = [blank] * deps.MaxTotalArgs
                    delete_this_record = [False] * deps.NumIDFRecords
                    
                    comis_sim = False
                    ads_sim = False
                    
                    for num in range(deps.NumIDFRecords):
                        if make_upper_case(deps.IDFRecords[num].Name) == 'COMIS SIMULATION':
                            comis_sim = True
                        if make_upper_case(deps.IDFRecords[num].Name) == 'ADS SIMULATION':
                            ads_sim = True
                    
                    if comis_sim and ads_sim:
                        print('File contains both COMIS and ADS Simulation objects=' + full_file_name)
                        print('Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file.')
                        print(' ..File contains both COMIS and ADS Simulation objects=' + full_file_name, file=deps.Auditf)
                        print(' ..Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file.', file=deps.Auditf)
                        exit_because_bad_file = True
                        output_file.close()
                        break
                    
                    no_version = True
                    for num in range(deps.NumIDFRecords):
                        if make_upper_case(deps.IDFRecords[num].Name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(deps.NumIDFRecords):
                        for xcount in range(deps.IDFRecords[num].CommtS, deps.IDFRecords[num].CommtE + 1):
                            output_file.write(deps.Comments[xcount].rstrip() + '\n')
                            if xcount == deps.IDFRecords[num].CommtE:
                                output_file.write(' \n')
                        
                        if no_version and num == 0:
                            nw_num_args = 0
                            get_new_object_def_in_idd('VERSION', nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = '1.3'
                            cur_args = 1
                            write_out_idf_lines_as_comments(output_file, 'VERSION', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        object_name = deps.IDFRecords[num].Name
                        
                        if make_upper_case(object_name.strip()) == 'SKY RADIANCE DISTRIBUTION':
                            continue
                        if make_upper_case(object_name.strip()) == 'AIRFLOW MODEL':
                            continue
                        if make_upper_case(object_name.strip()) == 'GENERATOR:FC:BATTERY DATA':
                            continue
                        if make_upper_case(object_name.strip()) == 'WATER HEATER:SIMPLE':
                            output_file.write('\n')
                            continue
                        
                        if find_item_in_list(object_name, deps.ObjectDef.Name, deps.NumObjectDefs) != -1:
                            num_args = 0
                            get_object_def_in_idd(object_name, num_args, a_or_n, req_fld, [], fld_names, fld_defaults, fld_units)
                            num_alphas = deps.IDFRecords[num].NumAlphas
                            num_numbers = deps.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = deps.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = deps.IDFRecords[num].Numbers[:num_numbers]
                            cur_args = num_alphas + num_numbers
                            in_args = [blank] * deps.MaxTotalArgs
                            out_args = [blank] * deps.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if a_or_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = numbers[nn]
                                    nn += 1
                        else:
                            print('Object="' + object_name.rstrip() + '" does not seem to be on the "old" IDD.', file=deps.Auditf)
                            print('... will be listed as comments (no field names) on the new output file.', file=deps.Auditf)
                            print('... Alpha fields will be listed first, then numerics.', file=deps.Auditf)
                            num_alphas = deps.IDFRecords[num].NumAlphas
                            num_numbers = deps.IDFRecords[num].NumNumbers
                            alphas[:num_alphas] = deps.IDFRecords[num].Alphas[:num_alphas]
                            numbers[:num_numbers] = deps.IDFRecords[num].Numbers[:num_numbers]
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = numbers[arg]
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [blank] * deps.MaxTotalArgs
                            nw_fld_units = [blank] * deps.MaxTotalArgs
                            write_out_idf_lines_as_comments(output_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        no_diff = True
                        diff_min_fields = False
                        written = False
                        
                        if find_item_in_list(make_upper_case(object_name), deps.NotInNew, len(deps.NotInNew)) == -1:
                            nw_num_args = 0
                            nw_obj_min_flds = 0
                            get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            if deps.ObjMinFlds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not deps.MakingPretty:
                            obj_upper = make_upper_case(object_name.strip())
                            
                            if obj_upper == 'VERSION':
                                if in_args[0][:3] == '1.3' and arg_file:
                                    show_warning_error('File is already at latest version.  No new diff file made.', deps.Auditf)
                                    output_file.close()
                                    latest_version = True
                                    break
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '1.3'
                                no_diff = False
                            
                            elif obj_upper == 'COIL:WATER:SIMPLECOOLING':
                                nw_num_args = 0
                                get_new_object_def_in_idd('COIL:WATER:COOLING', nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                object_name = 'COIL:Water:Cooling'
                                out_args[0:2] = in_args[0:2]
                                out_args[2:9] = ['autosize'] * 7
                                out_args[9:13] = in_args[5:9]
                                out_args[13] = 'SimpleAnalysis'
                                out_args[14] = 'CrossFlow'
                                cur_args = 15
                                no_diff = False
                            
                            elif obj_upper == 'UNITARYSYSTEM:HEATPUMP:WATERTOAIR':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:11] = in_args[0:11]
                                out_args[9] = 'Coil:WaterToAirHP:ParameterEstimation:Heating'
                                out_args[11] = '0.001'
                                out_args[12:14] = in_args[10:12]
                                out_args[12] = 'Coil:WaterToAirHP:ParameterEstimation:Cooling'
                                out_args[14] = '0.001'
                                out_args[15:21] = in_args[13:19]
                                out_args[21:25] = in_args[20:24]
                                cur_args = 25
                                no_diff = False
                            
                            elif obj_upper == 'COIL:WATERTOAIRHP:HEATING':
                                nw_num_args = 0
                                get_new_object_def_in_idd('COIL:WATERTOAIRHP:PARAMETERESTIMATION:HEATING', nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = False
                            
                            elif obj_upper == 'COIL:WATERTOAIRHP:COOLING':
                                nw_num_args = 0
                                get_new_object_def_in_idd('COIL:WATERTOAIRHP:PARAMETERESTIMATION:COOLING', nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = False
                            
                            elif obj_upper == 'LIGHTS':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                if make_upper_case(out_args[8]) == 'GENERALLIGHTS' or out_args[8] == blank:
                                    for xnum in range(deps.NumIDFRecords):
                                        if make_upper_case(deps.IDFRecords[xnum].Name.strip()) == 'DAYLIGHTING:DETAILED':
                                            if same_string(deps.IDFRecords[xnum].Alphas[0].rstrip(), out_args[1].rstrip()):
                                                out_args[7] = '1.0'
                                        if make_upper_case(deps.IDFRecords[xnum].Name.strip()) == 'DAYLIGHTING:DELIGHT':
                                            if same_string(deps.IDFRecords[xnum].Alphas[1].rstrip(), out_args[1].rstrip()):
                                                out_args[7] = '1.0'
                                no_diff = False
                            
                            elif obj_upper == 'ELECTRIC EQUIPMENT':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                if cur_args >= 8:
                                    if out_args[7] != blank:
                                        xnum = int(out_args[7])
                                        if xnum == 0:
                                            out_args[7] = 'General'
                                        else:
                                            out_args[7] = f'Category {xnum:02d}'
                                no_diff = False
                            
                            elif obj_upper == 'BRANCH':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                for arg in range(2, cur_args, 5):
                                    arg_upper = make_upper_case(out_args[arg])
                                    if arg_upper == 'COIL:WATERTOAIRHP:HEATING':
                                        out_args[arg] = 'Coil:WaterToAirHP:ParameterEstimation:Heating'
                                        no_diff = False
                                    elif arg_upper == 'COIL:WATERTOAIRHP:COOLING':
                                        out_args[arg] = 'Coil:WaterToAirHP:ParameterEstimation:Cooling'
                                        no_diff = False
                                    elif arg_upper == 'COIL:WATER:SIMPLECOOLING':
                                        out_args[arg] = 'COIL:Water:Cooling'
                                        no_diff = False
                            
                            elif obj_upper == 'COMIS SIMULATION':
                                object_name = 'AIRFLOWNETWORK SIMULATION'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = 'AirflowNetwork 1'
                                if make_upper_case(in_args[0]) == 'VENT':
                                    out_args[1] = 'MultiZone Without Distribution'
                                else:
                                    out_args[1] = 'No MultiZone or Distribution'
                                out_args[2] = in_args[15]
                                if out_args[2] == ' ':
                                    out_args[2] = 'Input'
                                out_args[3] = in_args[14]
                                out_args[4] = in_args[16]
                                out_args[5] = in_args[11]
                                out_args[6] = in_args[10]
                                out_args[7] = in_args[5]
                                out_args[8] = in_args[4]
                                out_args[9] = in_args[3]
                                if process_number(in_args[3], err_flag) == 1.0:
                                    out_args[9] = '-0.5'
                                out_args[10:12] = in_args[12:14]
                                out_args[12:14] = in_args[17:19]
                                if out_args[12] == ' ':
                                    out_args[12] = '0.0'
                                if out_args[13] == ' ':
                                    out_args[13] = '1.0'
                                no_diff = False
                                cur_args = 14
                            
                            elif obj_upper == 'COMIS ZONE DATA':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:ZONE'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[2] = in_args[1]
                                out_args[1] = in_args[2]
                                out_args[3:9] = in_args[3:9]
                                cur_args = 9
                                if out_args[8] == ' ':
                                    cur_args = 8
                                no_diff = False
                            
                            elif obj_upper == 'COMIS SURFACE DATA':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:SURFACE'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:4] = in_args[0:4]
                                if cur_args > 4:
                                    out_args[4] = in_args[5]
                                    out_args[5] = in_args[4]
                                    out_args[6] = in_args[6]
                                    if out_args[6] == ' ':
                                        out_args[6] = '1.0'
                                    for arg in range(7, cur_args):
                                        out_args[arg] = in_args[arg]
                                no_diff = False
                            
                            elif obj_upper == 'COMIS SITE WIND CONDITIONS':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:SITE WIND CONDITIONS'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                out_args[1] = in_args[2]
                                no_diff = False
                                cur_args = 2
                            
                            elif obj_upper == 'COMIS EXTERNAL NODE':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:EXTERNAL NODE'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                no_diff = False
                                cur_args = 1
                            
                            elif obj_upper == 'COMIS STANDARD CONDITIONS FOR CRACK DATA':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:REFERENCE CRACK CONDITIONS'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = 'ReferenceCrackConditions'
                                out_args[1] = in_args[0]
                                out_args[2] = round_sig_digits(process_number(in_args[1], err_flag) * 1000., 0)
                                out_args[3] = round_sig_digits(process_number(in_args[2], err_flag) / 1000., 3)
                                no_diff = False
                                cur_args = 4
                            
                            elif obj_upper == 'COMIS AIR FLOW:CRACK':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:SURFACE CRACK DATA'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:3] = in_args[0:3]
                                out_args[3] = 'ReferenceCrackConditions'
                                no_diff = False
                                cur_args = 4
                            
                            elif obj_upper == 'COMIS AIR FLOW:OPENING':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:COMPONENT DETAILED OPENING'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                cur_args = min(26, cur_args)
                                no_diff = False
                            
                            elif obj_upper == 'COMIS CP ARRAY':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:WIND PRESSURE COEFFICIENT ARRAY'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = False
                            
                            elif obj_upper == 'COMIS CP VALUES':
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:WIND PRESSURE COEFFICIENT VALUES'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = False
                            
                            elif obj_upper == 'ADS SIMULATION':
                                object_name = 'AIRFLOWNETWORK SIMULATION'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = in_args[0]
                                if make_upper_case(in_args[1]) == 'ADS':
                                    out_args[1] = 'MultiZone with Distribution only during Fan Operation'
                                else:
                                    out_args[1] = 'No MultiZone or Distribution'
                                out_args[2] = 'Surface-Average Calculation'
                                out_args[3] = ' '
                                out_args[4] = 'LowRise'
                                out_args[5:9] = in_args[2:6]
                                out_args[9] = in_args[7]
                                out_args[10] = '10'
                                out_args[11] = '0.14'
                                out_args[12] = '0.0'
                                out_args[13] = '1.0'
                                no_diff = False
                                cur_args = 14
                                write_out_idf_lines(output_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:REFERENCE CRACK CONDITIONS'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = 'ReferenceCrackConditions'
                                out_args[1] = '20.0'
                                out_args[2] = '101325'
                                out_args[3] = '0.0'
                                no_diff = False
                                cur_args = 4
                                write_out_idf_lines(output_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                object_name = 'AIRFLOWNETWORK:MULTIZONE:SITE WIND CONDITIONS'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = '0.0'
                                out_args[1] = '0.18'
                                no_diff = False
                                cur_args = 2
                            
                            elif obj_upper == 'ADS NODE DATA':
                                if make_upper_case(in_args[1]) == 'THERMAL ZONE':
                                    object_name = 'AIRFLOWNETWORK:MULTIZONE:ZONE'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = in_args[5]
                                    out_args[1] = 'NoVent'
                                    out_args[2] = ' '
                                    out_args[3] = '1.0'
                                    out_args[4] = '0.0'
                                    out_args[5] = '100.0'
                                    out_args[6] = '0.0'
                                    out_args[7] = '300000.0'
                                    no_diff = False
                                    cur_args = 8
                                elif make_upper_case(in_args[1]) == 'EXTERNAL' and make_upper_case(in_args[2]) == 'OTHER':
                                    continue
                                elif make_upper_case(in_args[1]) == 'OTHER' and (make_upper_case(in_args[2]) in ['MIXER', 'SPLITTER', 'OUTSIDE AIR SYSTEM']):
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:NODE'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = in_args[0]
                                    out_args[1] = ' '
                                    out_args[2] = in_args[2]
                                    out_args[3] = in_args[4]
                                    no_diff = False
                                    cur_args = 4
                                else:
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:NODE'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = in_args[0]
                                    out_args[2] = in_args[1]
                                    if make_upper_case(out_args[2]) == 'EXTERNAL':
                                        out_args[2] = 'OA Mixer Outside Air Stream Node'
                                    out_args[1] = in_args[2]
                                    out_args[3] = in_args[4]
                                    no_diff = False
                                    cur_args = 4
                            
                            elif obj_upper == 'ADS ELEMENT DATA':
                                if make_upper_case(in_args[1]) == 'DWC' and (make_upper_case(in_args[3]) in ['OTHER', 'SUPPLY CONNECTION', 'RETURN CONNECTION']):
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:COMPONENT DUCT'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    if num_numbers <= 9:
                                        out_args[0] = in_args[0]
                                        out_args[1:8] = in_args[4:11]
                                        cur_args = 8
                                        no_diff = False
                                    else:
                                        out_args[0] = in_args[0]
                                        out_args[1:6] = in_args[4:9]
                                        out_args[6:8] = in_args[12:14]
                                        cur_args = 8
                                        no_diff = False
                                elif make_upper_case(in_args[1]) == 'DWC' and make_upper_case(in_args[3]) == 'SINGLE DUCT:CONST VOLUME:REHEAT':
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:COMPONENT TERMINAL UNIT'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0:2] = in_args[2:4]
                                    out_args[2:4] = in_args[4:6]
                                    cur_args = 4
                                    no_diff = False
                                elif make_upper_case(in_args[1]) == 'CVF':
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:COMPONENT CONSTANT VOLUME FAN'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0] = in_args[2]
                                    cur_args = 1
                                    no_diff = False
                                elif make_upper_case(in_args[1]) == 'DWC' and make_upper_case(in_args[3]) == 'COIL:DX:COOLINGBYPASSFACTOREMPIRICAL':
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:COMPONENT COIL'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0:4] = in_args[2:6]
                                    cur_args = 4
                                    no_diff = False
                                elif make_upper_case(in_args[1]) == 'DWC' and make_upper_case(in_args[3]) == 'COIL:GAS:HEATING':
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:COMPONENT COIL'
                                    out_args[0:4] = in_args[2:6]
                                    cur_args = 4
                                    no_diff = False
                                elif make_upper_case(in_args[1]) == 'DWC' and make_upper_case(in_args[3]) == 'COIL:ELECTRIC:HEATING':
                                    object_name = 'AIRFLOWNETWORK:DISTRIBUTION:COMPONENT COIL'
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0:4] = in_args[2:6]
                                    cur_args = 4
                                    no_diff = False
                                else:
                                    print('Cannot convert ADS Element Data Object=' + in_args[0].rstrip(), file=deps.Auditf)
                                    continue
                            
                            elif obj_upper == 'ADS LINKAGE DATA':
                                object_name = 'AIRFLOWNETWORK:DISTRIBUTION:LINKAGE'
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:2] = in_args[0:2]
                                out_args[2] = in_args[3]
                                out_args[3] = in_args[5]
                                out_args[4] = in_args[6]
                                cur_args = 5
                                no_diff = False
                            
                            elif obj_upper == 'BUILDING':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                if cur_args == 8:
                                    no_diff = False
                                    if make_upper_case(out_args[7]) == 'YES':
                                        out_args[5] = out_args[5].rstrip() + 'WithReflections'
                                        out_args[7] = blank
                                        cur_args = 7
                                    elif make_upper_case(out_args[7]) == 'NO':
                                        out_args[7] = blank
                                        cur_args = 7
                            
                            elif obj_upper == 'WINDOWSHADINGCONTROL':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                no_diff = False
                                out_args[0:cur_args] = in_args[0:cur_args]
                                if same_string('InteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if same_string('ExteriorNonInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if same_string('InteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'InteriorShade'
                                if same_string('ExteriorInsulatingShade', in_args[1]):
                                    out_args[1] = 'ExteriorShade'
                                if same_string('Schedule', in_args[3]):
                                    out_args[3] = 'OnIfScheduleAllows'
                                if same_string('SolarOnWindow', in_args[3]):
                                    out_args[3] = 'OnIfHighSolarOnWindow'
                                if same_string('HorizontalSolar', in_args[3]):
                                    out_args[3] = 'OnIfHighHorizontalSolar'
                                if same_string('OutsideAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighOutsideAirTemp'
                                if same_string('ZoneAirTemp', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneAirTemp'
                                if same_string('ZoneCooling', in_args[3]):
                                    out_args[3] = 'OnIfHighZoneCooling'
                                if same_string('Glare', in_args[3]):
                                    out_args[3] = 'OnIfHighGlare'
                                if same_string('DaylightIlluminance', in_args[3]):
                                    out_args[3] = 'MeetDaylightIlluminanceSetpoint'
                            
                            elif obj_upper == 'REPORT VARIABLE':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                del_this = False
                                scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, output_file, True, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper in ['REPORT METER', 'REPORT METERFILEONLY', 'REPORT CUMULATIVE METER', 'REPORT CUMULATIVE METERFILEONLY']:
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                del_this = False
                                scan_output_variables_for_replacement(1, del_this, check_rvi, no_diff, object_name, output_file, False, True, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'REPORT:TABLE:TIMEBINS':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                del_this = False
                                scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, output_file, False, False, True, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == 'REPORT:TABLE:MONTHLY':
                                nw_num_args = 0
                                get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0:cur_args] = in_args[0:cur_args]
                                no_diff = True
                                if out_args[0] == blank:
                                    out_args[0] = '*'
                                    no_diff = False
                                cur_var = 2
                                for var in range(2, cur_args, 2):
                                    uc_rep_var_name = make_upper_case(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    pos = uc_rep_var_name.find('[')
                                    if pos >= 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var][:pos]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    del_this = False
                                    for arg in range(deps.NumRepVarNames):
                                        uc_comp_rep_var_name = make_upper_case(deps.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name and uc_comp_rep_var_name[-1] == '*':
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if deps.NewRepVarName[arg] != '<DELETE>':
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            else:
                                                del_this = True
                                            if arg < deps.NumRepVarNames - 1 and deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            if arg < deps.NumRepVarNames - 2 and deps.OldRepVarName[arg] == deps.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = deps.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                no_diff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                cur_args = cur_var - 1
                            
                            else:
                                if find_item_in_list(object_name, deps.NotInNew, len(deps.NotInNew)) != -1:
                                    print('Object="' + object_name.rstrip() + '" is not in the "new" IDD.', file=deps.Auditf)
                                    print('... will be listed as comments on the new output file.', file=deps.Auditf)
                                    write_out_idf_lines_as_comments(output_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    nw_num_args = 0
                                    get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    out_args[0:cur_args] = in_args[0:cur_args]
                                    no_diff = True
                        else:
                            nw_num_args = 0
                            get_new_object_def_in_idd(deps.IDFRecords[num].Name, nw_num_args, nw_a_or_n, nw_req_fld, [], nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0:cur_args] = in_args[0:cur_args]
                        
                        if diff_min_fields and no_diff:
                            nw_num_args = 0
                            nw_obj_min_flds = 0
                            get_new_object_def_in_idd(object_name, nw_num_args, nw_a_or_n, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0:cur_args] = in_args[0:cur_args]
                            no_diff = False
                            for arg in range(cur_args, nw_obj_min_flds):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects(output_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            write_out_idf_lines(output_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if deps.IDFRecords[deps.NumIDFRecords - 1].CommtE != deps.CurComment:
                        for xcount in range(deps.IDFRecords[deps.NumIDFRecords - 1].CommtE + 1, deps.CurComment + 1):
                            output_file.write(deps.Comments[xcount].rstrip() + '\n')
                            if xcount == deps.IDFRecords[deps.NumIDFRecords - 1].CommtE:
                                output_file.write(' \n')
                    
                    output_file.close()
                    if check_rvi:
                        process_rvi_mvi_files(file_name_path, 'rvi')
                        process_rvi_mvi_files(file_name_path, 'mvi')
                    close_out()
                else:
                    process_rvi_mvi_files(file_name_path, 'rvi')
                    process_rvi_mvi_files(file_name_path, 'mvi')
            else:
                end_of_file = True
            
            created_output_name = ""
            create_new_name('Reallocate', created_output_name, ' ')
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        copyfile(file_name_path + '.' + arg_idf_extension, file_name_path + '.' + arg_idf_extension + 'old', err_flag)
        copyfile(file_name_path + '.' + arg_idf_extension + 'new', file_name_path + '.' + arg_idf_extension, err_flag)
        if os.path.exists(file_name_path + '.rvi'):
            copyfile(file_name_path + '.rvi', file_name_path + '.rviold', err_flag)
        if os.path.exists(file_name_path + '.rvinew'):
            copyfile(file_name_path + '.rvinew', file_name_path + '.rvi', err_flag)
        if os.path.exists(file_name_path + '.mvi'):
            copyfile(file_name_path + '.mvi', file_name_path + '.mviold', err_flag)
        if os.path.exists(file_name_path + '.mvinew'):
            copyfile(file_name_path + '.mvinew', file_name_path + '.mvi', err_flag)
    
    return end_of_file

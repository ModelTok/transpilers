# EXTERNAL DEPS (to wire in glue):
# - IDFRecords: list[IDFRecord] from InputProcessor
# - Comments: list[str] from InputProcessor
# - ObjectDef: list[ObjectDefinition] from InputProcessor
# - NumObjectDefs: int from InputProcessor
# - NumIDFRecords: int from InputProcessor
# - CurComment: int from InputProcessor
# - MaxNameLength: int from InputProcessor
# - MaxAlphaArgsFound: int from InputProcessor
# - MaxNumericArgsFound: int from InputProcessor
# - MaxTotalArgs: int from InputProcessor
# - OldRepVarName: list[str] from DataVCompareGlobals
# - NewRepVarName: list[str] from DataVCompareGlobals
# - NewRepVarCaution: list[str] from DataVCompareGlobals
# - NumRepVarNames: int from DataVCompareGlobals
# - OTMVarCaution, CMtrVarCaution, CMtrDVarCaution: list[bool] from DataVCompareGlobals
# - NotInNew: list[str] from DataVCompareGlobals
# - ProcessingIMFFile: bool from DataVCompareGlobals
# - ProgNameConversion: str from DataStringGlobals
# - ProgramPath: str from DataStringGlobals
# - VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath: from SetVersion
# - FatalError: bool from InputProcessor
# - Blank: str constant
# - ProcessInput, GetNewObjectDefInIDD, FindItemInList, GetNewUnitNumber, MakeUPPERCase, SameString
# - DisplayString, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, WritePreProcessorObject
# - ProcessNumber, ScanOutputVariablesForReplacement, CloseOut, ProcessRviMviFiles, CreateNewName, CopyFile
# - GetNumSectionsFound, ShowWarningError, ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError
# - FullFileName, FileNamePath, Auditf, NumAlphas, NumNumbers: global state to manage
# - FindNumber (external function)
# - TrimTrailZeros (external function)

from dataclasses import dataclass, field
from typing import Protocol, Optional, List

@dataclass
class FanData:
    name: str = ""
    ftype: str = ""

@dataclass
class NodeListData:
    name: str = ""
    node_names: List[str] = field(default_factory=list)
    num_nodes: int = 0

@dataclass
class FluidLoop:
    loop_name: str = " "
    loop_fluid: str = " "
    setpoint_node: str = ""
    is_plant: bool = True
    has_fluid_coolers: bool = False
    num_total_fluids: int = 0
    fluid_component_type: List[str] = field(default_factory=list)
    fluid_component_name: List[str] = field(default_factory=list)
    fluid_change_name: List[str] = field(default_factory=list)
    inlet_node: List[str] = field(default_factory=list)
    outlet_node: List[str] = field(default_factory=list)

@dataclass
class Component:
    comp_type: str = " "
    name: str = " "
    fluid1: str = " "
    fluid2: str = " "
    inlet_node1: str = " "
    inlet_node2: str = " "
    outlet_node1: str = " "
    outlet_node2: str = " "

@dataclass
class SetpointTemperatureManagedNodes:
    comp_type: str = " "
    name: str = " "
    node_num_field: int = 0
    node_list_num: int = 0
    node_name: str = " "
    plant_loop_name: str = " "

@dataclass
class VariableFlowEquipment:
    comp_type: str = " "
    comp_name: str = " "
    outlet_node_name: str = " "
    plant_loop_name: str = " "
    sp_name_insert: str = " "

class ExternalDeps(Protocol):
    def get_idf_records(self) -> list: ...
    def get_comments(self) -> list: ...
    def get_object_def(self) -> list: ...
    def get_num_object_defs(self) -> int: ...
    def get_num_idf_records(self) -> int: ...
    def get_cur_comment(self) -> int: ...

def set_this_version_variables(deps: ExternalDeps) -> tuple:
    ver_string = "Conversion 6.0 => 7.0"
    version_num = 7.0
    program_path = deps.get_program_path()
    idd_file_name_with_path = program_path.rstrip("/") + "/V6-0-0-Energy+.idd"
    new_idd_file_name_with_path = program_path.rstrip("/") + "/V7-0-0-Energy+.idd"
    rep_var_file_name_with_path = program_path.rstrip("/") + "/Report Variables 6-0-0-023 to 7-0-0.csv"
    return ver_string, version_num, idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path

def create_new_idf_using_rules(
    end_of_file: bool,
    diff_only: bool,
    in_lfn: int,
    ask_for_input: bool,
    input_file_name: str,
    arg_file: bool,
    arg_idf_extension: str,
    deps: ExternalDeps
) -> bool:
    
    first_time = True
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file = False
    ios = 0
    
    blank = ""
    fmta = "(A)"
    making_pretty = False
    
    fans_in_idf = []
    fan_count = 0
    
    plant_cond_loops = []
    num_plant_cond_loops = 0
    fluid_component = []
    
    node_lists = []
    num_node_lists = 0
    
    setpoint_managed_nodes = []
    sp_man_count = 0
    sp_proc_count = 0
    
    vf_equipment = []
    num_vf_equipment = 0
    num_vf_count = 0
    
    idf_records = deps.get_idf_records()
    comments = deps.get_comments()
    num_idf_records = deps.get_num_idf_records()
    cur_comment = deps.get_cur_comment()
    
    alphas = [""] * (deps.get_max_alpha_args_found() + 1)
    numbers = [0.0] * (deps.get_max_numeric_args_found() + 1)
    in_args = [""] * (deps.get_max_total_args() + 1)
    out_args = [""] * (deps.get_max_total_args() + 1)
    match_arg = [False] * (deps.get_max_total_args() + 1)
    aorn = [False] * (deps.get_max_total_args() + 1)
    req_fld = [False] * (deps.get_max_total_args() + 1)
    fld_names = [""] * (deps.get_max_total_args() + 1)
    fld_defaults = [""] * (deps.get_max_total_args() + 1)
    fld_units = [""] * (deps.get_max_total_args() + 1)
    nw_aorn = [False] * (deps.get_max_total_args() + 1)
    nw_req_fld = [False] * (deps.get_max_total_args() + 1)
    nw_fld_names = [""] * (deps.get_max_total_args() + 1)
    nw_fld_defaults = [""] * (deps.get_max_total_args() + 1)
    nw_fld_units = [""] * (deps.get_max_total_args() + 1)
    
    delete_this_record = [False] * len(idf_records)
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="", flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    # Read from InLfn
                    try:
                        full_file_name = input()
                        ios = 0
                    except EOFError:
                        full_file_name = ""
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
            
            if full_file_name.startswith("!"):
                full_file_name = ""
                continue
            
            units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                deps.display_string("Processing IDF -- " + full_file_name)
                deps.write_audit_file(" Processing IDF -- " + full_file_name)
                
                dot_pos = full_file_name.rfind(".")
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:].lower()
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    deps.write_audit_file(" ..assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                dif_lfn = deps.get_new_unit_number()
                file_ok = deps.file_exists(full_file_name)
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    deps.write_audit_file("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    checkrvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    if diff_only:
                        deps.open_output_file(dif_lfn, file_name_path + "." + local_file_extension + "dif")
                    else:
                        deps.open_output_file(dif_lfn, file_name_path + "." + local_file_extension + "new")
                    
                    if local_file_extension == "imf":
                        deps.show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", dif_lfn)
                        deps.set_processing_imf_file(True)
                    else:
                        deps.set_processing_imf_file(False)
                    
                    deps.process_input(deps.get_idd_file_name_with_path(), deps.get_new_idd_file_name_with_path(), full_file_name)
                    
                    if deps.has_fatal_error():
                        exit_because_bad_file = True
                        break
                    
                    num_node_lists = 0
                    idf_records = deps.get_idf_records()
                    num_idf_records = deps.get_num_idf_records()
                    for num in range(num_idf_records):
                        if deps.make_upper_case(idf_records[num].name) != "NODELIST":
                            continue
                        num_node_lists += 1
                    
                    node_lists = [NodeListData() for _ in range(num_node_lists)]
                    
                    num_node_list_count = 0
                    for num in range(num_idf_records):
                        if deps.make_upper_case(idf_records[num].name) != "NODELIST":
                            continue
                        node_lists[num_node_list_count].name = idf_records[num].alphas[0]
                        node_lists[num_node_list_count].node_names = idf_records[num].alphas[1:idf_records[num].num_alphas]
                        node_lists[num_node_list_count].num_nodes = idf_records[num].num_alphas - 1
                        num_node_list_count += 1
                        if num_node_list_count == num_node_lists:
                            break
                    
                    sp_man_count = 0
                    for num in range(num_idf_records):
                        if deps.make_upper_case(idf_records[num].name[:16]) != "SETPOINTMANAGER:":
                            continue
                        if not (deps.same_string(idf_records[num].name, "SetpointManager:Scheduled") or
                                deps.same_string(idf_records[num].name, "SetpointManager:Scheduled:DualSetpoint") or
                                deps.same_string(idf_records[num].name, "SetpointManager:OutdoorAirReset") or
                                deps.same_string(idf_records[num].name, "SetpointManager:SingleZone:Reheat") or
                                deps.same_string(idf_records[num].name, "SetpointManager:SingleZone:Heating") or
                                deps.same_string(idf_records[num].name, "SetpointManager:SingleZone:Cooling") or
                                deps.same_string(idf_records[num].name, "SetpointManager:MixedAir") or
                                deps.same_string(idf_records[num].name, "SetpointManager:OutdoorAirPretreat") or
                                deps.same_string(idf_records[num].name, "SetpointManager:Warmest") or
                                deps.same_string(idf_records[num].name, "SetpointManager:Coldest") or
                                deps.same_string(idf_records[num].name, "SetpointManager:WarmestTemperatureFlow") or
                                deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Heating:Average") or
                                deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Cooling:Average")):
                            continue
                        
                        if not (deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Heating:Average") or
                                deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Cooling:Average")):
                            if deps.same_string(idf_records[num].alphas[1], "Temperature"):
                                sp_man_count += 1
                        else:
                            sp_man_count += 1
                    
                    setpoint_managed_nodes = [SetpointTemperatureManagedNodes() for _ in range(sp_man_count)]
                    
                    sp_proc_count = 0
                    if sp_man_count > 0:
                        for num in range(num_idf_records):
                            if deps.make_upper_case(idf_records[num].name[:16]) != "SETPOINTMANAGER:":
                                continue
                            if not (deps.same_string(idf_records[num].name, "SetpointManager:Scheduled") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:Scheduled:DualSetpoint") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:OutdoorAirReset") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:SingleZone:Reheat") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:SingleZone:Heating") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:SingleZone:Cooling") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:MixedAir") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:OutdoorAirPretreat") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:Warmest") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:Coldest") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:WarmestTemperatureFlow") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Heating:Average") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Cooling:Average")):
                                continue
                            
                            if not (deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Heating:Average") or
                                    deps.same_string(idf_records[num].name, "SetpointManager:MultiZone:Cooling:Average")):
                                if not deps.same_string(idf_records[num].alphas[1], "Temperature"):
                                    continue
                            
                            sp_proc_count += 1
                            
                            name_upper = deps.make_upper_case(idf_records[num].name)
                            setpoint_managed_nodes[sp_proc_count - 1].name = idf_records[num].alphas[0]
                            setpoint_managed_nodes[sp_proc_count - 1].comp_type = idf_records[num].name
                            
                            if name_upper == "SETPOINTMANAGER:SCHEDULED":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[3]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 4
                            elif name_upper == "SETPOINTMANAGER:SCHEDULED:DUALSETPOINT":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[4]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 5
                            elif name_upper == "SETPOINTMANAGER:OUTDOORAIRRESET":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[2]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 7
                            elif name_upper == "SETPOINTMANAGER:SINGLEZONE:REHEAT":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[5]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 8
                            elif name_upper == "SETPOINTMANAGER:SINGLEZONE:HEATING":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[5]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 8
                            elif name_upper == "SETPOINTMANAGER:SINGLEZONE:COOLING":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[5]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 8
                            elif name_upper == "SETPOINTMANAGER:MIXEDAIR":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[5]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 6
                            elif name_upper == "SETPOINTMANAGER:OUTDOORAIRPRETREAT":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[6]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 11
                            elif name_upper == "SETPOINTMANAGER:WARMEST":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[4]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 7
                            elif name_upper == "SETPOINTMANAGER:COLDEST":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[4]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 7
                            elif name_upper == "SETPOINTMANAGER:WARMESTTEMPERATUREFLOW":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[4]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 7
                            elif name_upper == "SETPOINTMANAGER:MULTIZONE:HEATING:AVERAGE":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[2]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 5
                            elif name_upper == "SETPOINTMANAGER:MULTIZONE:COOLING:AVERAGE":
                                setpoint_managed_nodes[sp_proc_count - 1].node_name = idf_records[num].alphas[2]
                                setpoint_managed_nodes[sp_proc_count - 1].node_num_field = 5
                            
                            if num_node_lists > 0:
                                pfound = deps.find_item_in_list(setpoint_managed_nodes[sp_proc_count - 1].node_name,
                                                                 [nl.name for nl in node_lists], num_node_lists)
                                if pfound > 0:
                                    setpoint_managed_nodes[sp_proc_count - 1].node_list_num = pfound
                            
                            if sp_proc_count == sp_man_count:
                                break
                    
                    for num in range(num_idf_records):
                        if deps.make_upper_case(idf_records[num].name) != "PLANTLOOP":
                            continue
                        pfound = deps.find_item_in_list(idf_records[num].alphas[3],
                                                       [sn.node_name for sn in setpoint_managed_nodes], sp_proc_count)
                        if pfound > 0:
                            setpoint_managed_nodes[pfound - 1].plant_loop_name = idf_records[num].alphas[0]
                        else:
                            for num2 in range(sp_proc_count):
                                if setpoint_managed_nodes[num2].node_list_num > 0:
                                    num3 = deps.find_item_in_list(idf_records[num].alphas[3],
                                                                  node_lists[setpoint_managed_nodes[num2].node_list_num - 1].node_names,
                                                                  node_lists[setpoint_managed_nodes[num2].node_list_num - 1].num_nodes)
                                    if num3 > 0:
                                        setpoint_managed_nodes[num2].plant_loop_name = idf_records[num].alphas[0]
                    
                    num_vf_equipment = 0
                    for num in range(num_idf_records):
                        name_upper = deps.make_upper_case(idf_records[num].name)
                        if not (deps.same_string(idf_records[num].name, "Boiler:HotWater") or
                                deps.same_string(idf_records[num].name, "Boiler:Steam") or
                                deps.same_string(idf_records[num].name, "Chiller:Electric:EIR") or
                                deps.same_string(idf_records[num].name, "Chiller:Electric:ReformulatedEIR") or
                                deps.same_string(idf_records[num].name, "Chiller:Electric") or
                                deps.same_string(idf_records[num].name, "Chiller:Absorption:Indirect") or
                                deps.same_string(idf_records[num].name, "Chiller:Absorption") or
                                deps.same_string(idf_records[num].name, "Chiller:ConstantCOP") or
                                deps.same_string(idf_records[num].name, "Chiller:EngineDriven") or
                                deps.same_string(idf_records[num].name, "Chiller:CombustionTurbine") or
                                deps.same_string(idf_records[num].name, "ChillerHeater:Absorption:DirectFired")):
                            continue
                        
                        if deps.same_string(idf_records[num].name, "Boiler:HotWater"):
                            if deps.same_string(idf_records[num].alphas[5], "VariableFlow") or idf_records[num].alphas[5] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Boiler:Steam"):
                            num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:Electric:EIR"):
                            if deps.same_string(idf_records[num].alphas[9], "VariableFlow") or idf_records[num].alphas[9] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:Electric:ReformulatedEIR"):
                            if deps.same_string(idf_records[num].alphas[8], "VariableFlow") or idf_records[num].alphas[8] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:Electric"):
                            if deps.same_string(idf_records[num].alphas[6], "VariableFlow") or idf_records[num].alphas[6] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:Absorption:Indirect"):
                            if deps.same_string(idf_records[num].alphas[5], "VariableFlow") or idf_records[num].alphas[5] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:Absorption"):
                            if deps.same_string(idf_records[num].alphas[7], "VariableFlow") or idf_records[num].alphas[7] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:ConstantCOP"):
                            if deps.same_string(idf_records[num].alphas[6], "VariableFlow") or idf_records[num].alphas[6] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:EngineDriven"):
                            if deps.same_string(idf_records[num].alphas[14], "VariableFlow") or idf_records[num].alphas[14] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "Chiller:CombustionTurbine"):
                            if deps.same_string(idf_records[num].alphas[8], "VariableFlow") or idf_records[num].alphas[8] == " ":
                                num_vf_equipment += 1
                        elif deps.same_string(idf_records[num].name, "ChillerHeater:Absorption:DirectFired"):
                            if deps.same_string(idf_records[num].alphas[16], "VariableFlow") or idf_records[num].alphas[16] == " ":
                                num_vf_equipment += 2
                    
                    vf_equipment = [VariableFlowEquipment() for _ in range(num_vf_equipment)]
                    num_vf_count = 0
                    if num_vf_equipment > 0:
                        for num in range(num_idf_records):
                            if not (deps.same_string(idf_records[num].name, "Boiler:HotWater") or
                                    deps.same_string(idf_records[num].name, "Boiler:Steam") or
                                    deps.same_string(idf_records[num].name, "Chiller:Electric:EIR") or
                                    deps.same_string(idf_records[num].name, "Chiller:Electric:ReformulatedEIR") or
                                    deps.same_string(idf_records[num].name, "Chiller:Electric") or
                                    deps.same_string(idf_records[num].name, "Chiller:Absorption:Indirect") or
                                    deps.same_string(idf_records[num].name, "Chiller:Absorption") or
                                    deps.same_string(idf_records[num].name, "Chiller:ConstantCOP") or
                                    deps.same_string(idf_records[num].name, "Chiller:EngineDriven") or
                                    deps.same_string(idf_records[num].name, "Chiller:CombustionTurbine") or
                                    deps.same_string(idf_records[num].name, "ChillerHeater:Absorption:DirectFired")):
                                continue
                            
                            if deps.same_string(idf_records[num].name, "Boiler:HotWater"):
                                if deps.same_string(idf_records[num].alphas[5], "VariableFlow") or idf_records[num].alphas[5] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[4]
                            elif deps.same_string(idf_records[num].name, "Boiler:Steam"):
                                num_vf_count += 1
                                vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[3]
                            elif deps.same_string(idf_records[num].name, "Chiller:Electric:EIR"):
                                if deps.same_string(idf_records[num].alphas[9], "VariableFlow") or idf_records[num].alphas[9] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[5]
                            elif deps.same_string(idf_records[num].name, "Chiller:Electric:ReformulatedEIR"):
                                if deps.same_string(idf_records[num].alphas[8], "VariableFlow") or idf_records[num].alphas[8] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[5]
                            elif deps.same_string(idf_records[num].name, "Chiller:Electric"):
                                if deps.same_string(idf_records[num].alphas[6], "VariableFlow") or idf_records[num].alphas[6] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[3]
                            elif deps.same_string(idf_records[num].name, "Chiller:Absorption:Indirect"):
                                if deps.same_string(idf_records[num].alphas[5], "VariableFlow") or idf_records[num].alphas[5] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[2]
                            elif deps.same_string(idf_records[num].name, "Chiller:Absorption"):
                                if deps.same_string(idf_records[num].alphas[7], "VariableFlow") or idf_records[num].alphas[7] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[2]
                            elif deps.same_string(idf_records[num].name, "Chiller:ConstantCOP"):
                                if deps.same_string(idf_records[num].alphas[6], "VariableFlow") or idf_records[num].alphas[6] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[2]
                            elif deps.same_string(idf_records[num].name, "Chiller:EngineDriven"):
                                if deps.same_string(idf_records[num].alphas[14], "VariableFlow") or idf_records[num].alphas[14] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[3]
                            elif deps.same_string(idf_records[num].name, "Chiller:CombustionTurbine"):
                                if deps.same_string(idf_records[num].alphas[8], "VariableFlow") or idf_records[num].alphas[8] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[3]
                            elif deps.same_string(idf_records[num].name, "ChillerHeater:Absorption:DirectFired"):
                                if deps.same_string(idf_records[num].alphas[16], "VariableFlow") or idf_records[num].alphas[16] == " ":
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[2]
                                    vf_equipment[num_vf_count - 1].sp_name_insert = "CW"
                                    num_vf_count += 1
                                    vf_equipment[num_vf_count - 1].comp_type = idf_records[num].name
                                    vf_equipment[num_vf_count - 1].comp_name = idf_records[num].alphas[0]
                                    vf_equipment[num_vf_count - 1].outlet_node_name = idf_records[num].alphas[6]
                                    vf_equipment[num_vf_count - 1].sp_name_insert = "HW"
                            
                            if num_vf_count == num_vf_equipment:
                                break
                    
                    num_plant_cond_loops = 0
                    for num in range(num_idf_records):
                        if deps.make_upper_case(idf_records[num].name) == "PLANTLOOP" or \
                           deps.make_upper_case(idf_records[num].name) == "CONDENSERLOOP":
                            num_plant_cond_loops += 1
                    
                    plant_cond_loops = [FluidLoop() for _ in range(num_plant_cond_loops)]
                    
                    plant_cond_num = 0
                    if num_plant_cond_loops > 0:
                        pass
                    
                    do_fluid_scan = False
                    num_fluids = 0
                    for num in range(num_idf_records):
                        name_upper = deps.make_upper_case(idf_records[num].name)
                        if name_upper == "COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION":
                            if not deps.same_string(idf_records[num].alphas[2], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION":
                            if not deps.same_string(idf_records[num].alphas[2], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "FLUIDCOOLER:SINGLESPEED":
                            if not deps.same_string(idf_records[num].alphas[12], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "FLUIDCOOLER:TWOSPEED":
                            if not deps.same_string(idf_records[num].alphas[16], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "GROUNDHEATEXCHANGER:POND":
                            if not deps.same_string(idf_records[num].alphas[3], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "GROUNDHEATEXCHANGER:SURFACE":
                            if not deps.same_string(idf_records[num].alphas[4], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "HEATEXCHANGER:HYDRONIC":
                            if not deps.same_string(idf_records[num].alphas[8], "Water"):
                                do_fluid_scan = True
                            if not deps.same_string(idf_records[num].alphas[9], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "HEATEXCHANGER:PLATE":
                            if not deps.same_string(idf_records[num].alphas[7], "Water"):
                                do_fluid_scan = True
                            if not deps.same_string(idf_records[num].alphas[8], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                        elif name_upper == "HEATEXCHANGER:WATERSIDEECONOMIZER":
                            if not deps.same_string(idf_records[num].alphas[7], "Water"):
                                do_fluid_scan = True
                            if not deps.same_string(idf_records[num].alphas[8], "Water"):
                                do_fluid_scan = True
                            num_fluids += 1
                    
                    no_version = True
                    for num in range(num_idf_records):
                        if deps.make_upper_case(idf_records[num].name) == "VERSION":
                            no_version = False
                            break
                    
                    fan_count = 0
                    for num in range(num_idf_records):
                        if deps.same_string(idf_records[num].name[:3], "Fan"):
                            fan_count += 1
                    
                    fans_in_idf = [FanData() for _ in range(fan_count)]
                    if fan_count > 0:
                        xcount = 0
                        for num in range(num_idf_records):
                            if deps.same_string(idf_records[num].name[:3], "Fan"):
                                fans_in_idf[xcount].ftype = idf_records[num].name
                                fans_in_idf[xcount].name = idf_records[num].alphas[0]
                                xcount += 1
                    
                    for num in range(num_idf_records):
                        if delete_this_record[num]:
                            deps.write_dif_file(dif_lfn, "! Deleting: " + idf_records[num].name + ":" + idf_records[num].alphas[0])
                    
                    for num in range(num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        if no_version and num == 0:
                            deps.get_new_object_def_in_idd("VERSION")
                            out_args[0] = "7.0"
                            cur_args = 1
                            deps.write_out_idf_lines(dif_lfn, "VERSION", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        name_upper = deps.make_upper_case(idf_records[num].name.strip())
                        if name_upper in ["SKY RADIANCE DISTRIBUTION", "AIRFLOW MODEL", "GENERATOR:FC:BATTERY DATA",
                                         "AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS"]:
                            continue
                        
                        if name_upper == "WATER HEATER:SIMPLE":
                            deps.write_dif_file(dif_lfn, "! ** The WATER HEATER:SIMPLE object has been deleted")
                            deps.write_preprocessor_object(dif_lfn, "Warning",
                                "The WATER HEATER:SIMPLE object has been deleted")
                            continue
                        
                        object_name = idf_records[num].name
                        if deps.find_item_in_list(object_name, deps.get_object_def_names(), deps.get_num_object_defs()) != 0:
                            deps.get_object_def_in_idd(object_name)
                            num_alphas = idf_records[num].num_alphas
                            num_numbers = idf_records[num].num_numbers
                            cur_args = num_alphas + num_numbers
                            
                            for arg in range(cur_args):
                                if arg < num_alphas:
                                    in_args[arg] = idf_records[num].alphas[arg]
                                else:
                                    in_args[arg] = str(idf_records[num].numbers[arg - num_alphas])
                        else:
                            deps.write_audit_file("Object=\"" + object_name + "\" does not seem to be on the \"old\" IDD.")
                            deps.write_audit_file("... will be listed as comments (no field names) on the new output file.")
                            deps.write_audit_file("... Alpha fields will be listed first, then numerics.")
                            num_alphas = idf_records[num].num_alphas
                            num_numbers = idf_records[num].num_numbers
                            cur_args = num_alphas + num_numbers
                            for arg in range(num_alphas):
                                out_args[arg] = idf_records[num].alphas[arg]
                            for arg in range(num_numbers):
                                out_args[num_alphas + arg] = str(idf_records[num].numbers[arg])
                            deps.write_out_idf_lines_as_comments(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if deps.find_item_in_list(deps.make_upper_case(object_name), deps.get_not_in_new(), len(deps.get_not_in_new())) == 0:
                            deps.get_new_object_def_in_idd(object_name)
                            diff_min_fields = False
                        
                        if not making_pretty:
                            name_upper = deps.make_upper_case(object_name.strip())
                            
                            if name_upper == "VERSION":
                                if in_args[0][:3] == "7.0" and arg_file:
                                    deps.show_warning_error("File is already at latest version.  No new diff file made.")
                                    deps.close_output_file(dif_lfn, delete=True)
                                    latest_version = True
                                    break
                                out_args[0] = "7.0"
                                nodiff = False
                            
                            elif name_upper == "ZONEHVAC:FOURPIPEFANCOIL":
                                nodiff = False
                                deps.get_new_object_def_in_idd(object_name)
                                out_args[0:10] = in_args[0:10]
                                out_args[10] = "OutdoorAir:Mixer"
                                out_args[11] = in_args[12]
                                if fan_count > 0:
                                    xcount = deps.find_item_in_list(in_args[13], [f.name for f in fans_in_idf], fan_count)
                                    if xcount > 0:
                                        out_args[12] = fans_in_idf[xcount - 1].ftype
                                    else:
                                        out_args[12] = "invalid fan type"
                                else:
                                    out_args[12] = "invalid fan type"
                                out_args[13] = in_args[13]
                                out_args[14] = in_args[22]
                                out_args[15:19] = in_args[14:18]
                                out_args[19] = "Coil:Heating:Water"
                                out_args[20:24] = in_args[18:22]
                                cur_args = 24
                            
                            elif name_upper == "ZONEHVAC:WINDOWAIRCONDITIONER":
                                nodiff = False
                                deps.get_new_object_def_in_idd(object_name)
                                out_args[0:6] = in_args[0:6]
                                out_args[6] = "OutdoorAir:Mixer"
                                out_args[7] = in_args[8]
                                if fan_count > 0:
                                    xcount = deps.find_item_in_list(in_args[9], [f.name for f in fans_in_idf], fan_count)
                                    if xcount > 0:
                                        out_args[8] = fans_in_idf[xcount - 1].ftype
                                    else:
                                        out_args[8] = "invalid fan type"
                                else:
                                    out_args[8] = "invalid fan type"
                                out_args[9] = in_args[9]
                                out_args[10] = in_args[14]
                                out_args[11:15] = in_args[10:14]
                                if cur_args > 14:
                                    out_args[15] = in_args[15]
                            
                            elif name_upper == "SIZING:ZONE":
                                nodiff = False
                                deps.get_new_object_def_in_idd(object_name)
                                out_args[0:5] = in_args[0:5]
                                out_args[5] = "SZ DSOA " + in_args[0].strip()
                                out_args[6:cur_args - 3] = in_args[9:cur_args]
                                cur_args = cur_args - 3
                                deps.write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                
                                object_name = "DesignSpecification:OutdoorAir"
                                deps.get_new_object_def_in_idd(object_name)
                                out_args[0] = out_args[5]
                                out_args[1] = in_args[5]
                                out_args[2:5] = in_args[6:9]
                                cur_args = 5
                                deps.write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                written = True
                        
                        if diff_min_fields and nodiff:
                            out_args[0:cur_args] = in_args[0:cur_args]
                            nodiff = False
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            deps.write_out_idf_lines(dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    deps.close_output_file(dif_lfn)
                    deps.process_rvi_mvi_files(file_name_path, "rvi")
                    deps.process_rvi_mvi_files(file_name_path, "mvi")
                    deps.close_out()
                else:
                    deps.process_rvi_mvi_files(file_name_path, "rvi")
                    deps.process_rvi_mvi_files(file_name_path, "mvi")
            else:
                end_of_file = True
            
            deps.create_new_name("Reallocate", " ")
        
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
        deps.copy_file(file_name_path + "." + arg_idf_extension,
                      file_name_path + "." + arg_idf_extension + "old", err_flag)
        deps.copy_file(file_name_path + "." + arg_idf_extension + "new",
                      file_name_path + "." + arg_idf_extension, err_flag)
        
        if deps.file_exists(file_name_path + ".rvi"):
            deps.copy_file(file_name_path + ".rvi", file_name_path + ".rviold", err_flag)
        if deps.file_exists(file_name_path + ".rvinew"):
            deps.copy_file(file_name_path + ".rvinew", file_name_path + ".rvi", err_flag)
        if deps.file_exists(file_name_path + ".mvi"):
            deps.copy_file(file_name_path + ".mvi", file_name_path + ".mviold", err_flag)
        if deps.file_exists(file_name_path + ".mvinew"):
            deps.copy_file(file_name_path + ".mvinew", file_name_path + ".mvi", err_flag)
    
    return end_of_file

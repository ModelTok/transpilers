# EXTERNAL DEPS (to wire in glue):
# - InputProcessor (module): GetNewUnitNumber, GetObjectItem, GetNumObjectsFound, GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumSectionsFound
# - DataVCompareGlobals (module): NumIDFRecords, IDFRecords, NotInNew, ObjectDef, NumObjectDefs, FatalError, ProcessingIMFFile, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, Comments, CurComment, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, FileOK, Auditf, ProgramPath, blank, MaxNameLength, MakingPretty, IDFRecords, VerString, VersionNum, sVersionNum, sVersionNumFourChars
# - VCompareGlobalRoutines (module): DisplayString, ProcessInput, FindItemInList, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, ScanOutputVariablesForReplacement, ProcessRviMviFiles, CloseOut, CreateNewName, copyfile, writePreprocessorObject, TrimTrailZeros, SameString, ProcessNumber, MakeUPPERCase, MakeLowerCase
# - DataStringGlobals (module): ProgNameConversion
# - General (module): utility functions
# - DataGlobals (module): ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

from math import floor

struct IDFRecord:
    var Name: String
    var NumAlphas: Int
    var NumNumbers: Int
    var Alphas: DynamicVector[String]
    var Numbers: DynamicVector[Float64]
    var CommtS: Int
    var CommtE: Int
    
    fn __init__(inout self):
        self.Name = ""
        self.NumAlphas = 0
        self.NumNumbers = 0
        self.Alphas = DynamicVector[String]()
        self.Numbers = DynamicVector[Float64]()
        self.CommtS = 0
        self.CommtE = 0

struct FanVOTransitionInfo:
    var oldFanName: String
    var availSchedule: String
    var fanTotalEff_str: String
    var pressureRise_str: String
    var maxAirFlow_str: String
    var minFlowInputMethod: String
    var minAirFlowFrac_str: String
    var fanPowerMinAirFlow_str: String
    var motorEfficiency: String
    var motorInAirStreamFrac: String
    var coeff1: String
    var coeff2: String
    var coeff3: String
    var coeff4: String
    var coeff5: String
    var inletAirNodeName: String
    var outletAirNodeName: String
    var endUseSubCat: String
    
    fn __init__(inout self):
        self.oldFanName = ""
        self.availSchedule = ""
        self.fanTotalEff_str = ""
        self.pressureRise_str = ""
        self.maxAirFlow_str = ""
        self.minFlowInputMethod = ""
        self.minAirFlowFrac_str = ""
        self.fanPowerMinAirFlow_str = ""
        self.motorEfficiency = ""
        self.motorInAirStreamFrac = ""
        self.coeff1 = ""
        self.coeff2 = ""
        self.coeff3 = ""
        self.coeff4 = ""
        self.coeff5 = ""
        self.inletAirNodeName = ""
        self.outletAirNodeName = ""
        self.endUseSubCat = ""

trait ExternalDeps:
    fn GetNewUnitNumber(self) -> Int: ...
    fn GetObjectItem(self, obj_type: String, obj_num: Int, inout alphas: DynamicVector[String], inout num_alphas: Int, inout numbers: DynamicVector[Float64], inout num_numbers: Int, inout status: Int) -> None: ...
    fn GetNumObjectsFound(self, obj_type: String) -> Int: ...
    fn GetObjectDefInIDD(self, name: String, inout num_args: Int, inout aorn: DynamicVector[Bool], inout req_fld: DynamicVector[Bool], inout obj_min_flds: Int, inout fld_names: DynamicVector[String], inout fld_defaults: DynamicVector[String], inout fld_units: DynamicVector[String]) -> None: ...
    fn GetNewObjectDefInIDD(self, name: String, inout nw_num_args: Int, inout nw_aorn: DynamicVector[Bool], inout nw_req_fld: DynamicVector[Bool], inout nw_obj_min_flds: Int, inout nw_fld_names: DynamicVector[String], inout nw_fld_defaults: DynamicVector[String], inout nw_fld_units: DynamicVector[String]) -> None: ...
    fn GetNumSectionsFound(self, section: String) -> Int: ...
    fn ProcessInput(self, idd_old: String, idd_new: String, idf_file: String) -> None: ...
    fn DisplayString(self, msg: String) -> None: ...
    fn FindItemInList(self, item: String, inout list_items: DynamicVector[String], count: Int) -> Int: ...
    fn WriteOutIDFLines(self, unit: Int, obj_name: String, cur_args: Int, inout out_args: DynamicVector[String], inout fld_names: DynamicVector[String], inout fld_units: DynamicVector[String]) -> None: ...
    fn WriteOutIDFLinesAsComments(self, unit: Int, obj_name: String, cur_args: Int, inout out_args: DynamicVector[String], inout fld_names: DynamicVector[String], inout fld_units: DynamicVector[String]) -> None: ...
    fn CheckSpecialObjects(self, unit: Int, obj_name: String, cur_args: Int, inout out_args: DynamicVector[String], inout fld_names: DynamicVector[String], inout fld_units: DynamicVector[String], inout written: Bool) -> None: ...
    fn ScanOutputVariablesForReplacement(self, field_num: Int, inout del_this: Bool, inout check_rvi: Bool, inout nodiff: Bool, obj_name: String, unit: Int, out_var: Bool, mtr_var: Bool, time_bin_var: Bool, inout cur_args: Int, inout written: Bool, is_meter: Bool) -> None: ...
    fn ProcessRviMviFiles(self, file_path: String, ext: String) -> None: ...
    fn CloseOut(self) -> None: ...
    fn CreateNewName(self, action: String, inout name_out: String, suffix: String) -> None: ...
    fn copyfile(self, src: String, dst: String, inout err_flag: Bool) -> None: ...
    fn writePreprocessorObject(self, unit: Int, prog_name: String, msg_type: String, msg: String) -> None: ...
    fn MakeUPPERCase(self, s: String) -> String: ...
    fn MakeLowerCase(self, s: String) -> String: ...
    fn SameString(self, s1: String, s2: String) -> Bool: ...
    fn ProcessNumber(self, s: String, inout err_flag: Bool) -> Float64: ...
    fn ShowFatalError(self, msg: String, unit: Int) -> None: ...
    fn ShowWarningError(self, msg: String, unit: Int) -> None: ...
    fn ShowSevereError(self, msg: String, unit: Int) -> None: ...
    fn TrimTrailZeros(self, s: String) -> String: ...
    fn ADJUSTL(self, s: String) -> String: ...

struct GlobalsState:
    var VerString: String
    var VersionNum: Float64
    var sVersionNum: String
    var sVersionNumFourChars: String
    var IDDFileNameWithPath: String
    var NewIDDFileNameWithPath: String
    var RepVarFileNameWithPath: String
    var ProgramPath: String
    var Auditf: Int
    var ProgNameConversion: String
    var NumIDFRecords: Int
    var IDFRecords: DynamicVector[IDFRecord]
    var NotInNew: DynamicVector[String]
    var ObjectDef: DynamicVector[String]
    var NumObjectDefs: Int
    var FatalError: Bool
    var ProcessingIMFFile: Bool
    var MaxAlphaArgsFound: Int
    var MaxNumericArgsFound: Int
    var MaxTotalArgs: Int
    var Alphas: DynamicVector[String]
    var Numbers: DynamicVector[Float64]
    var InArgs: DynamicVector[String]
    var TempArgs: DynamicVector[String]
    var AorN: DynamicVector[Bool]
    var ReqFld: DynamicVector[Bool]
    var FldNames: DynamicVector[String]
    var FldDefaults: DynamicVector[String]
    var FldUnits: DynamicVector[String]
    var NwAorN: DynamicVector[Bool]
    var NwReqFld: DynamicVector[Bool]
    var NwFldNames: DynamicVector[String]
    var NwFldDefaults: DynamicVector[String]
    var NwFldUnits: DynamicVector[String]
    var OutArgs: DynamicVector[String]
    var OldRepVarName: DynamicVector[String]
    var NewRepVarName: DynamicVector[String]
    var NewRepVarCaution: DynamicVector[String]
    var NumRepVarNames: Int
    var OTMVarCaution: DynamicVector[Bool]
    var CMtrVarCaution: DynamicVector[Bool]
    var CMtrDVarCaution: DynamicVector[Bool]
    var Comments: DynamicVector[String]
    var CurComment: Int
    var FullFileName: String
    var FileNamePath: String
    var FileOK: Bool
    var blank: String
    var MaxNameLength: Int
    var MakingPretty: Bool
    var DeleteThisRecord: DynamicVector[Bool]

fn set_this_version_variables(deps: UnsafePointer[ExternalDeps], inout globals_state: GlobalsState) -> None:
    globals_state.VerString = "Conversion 24.1 => 24.2"
    globals_state.VersionNum = 24.2
    globals_state.sVersionNum = "***"
    globals_state.sVersionNumFourChars = "24.2"
    globals_state.IDDFileNameWithPath = globals_state.ProgramPath + "V24-1-0-Energy+.idd"
    globals_state.NewIDDFileNameWithPath = globals_state.ProgramPath + "V24-2-0-Energy+.idd"
    globals_state.RepVarFileNameWithPath = globals_state.ProgramPath + "Report Variables 24-1-0 to 24-2-0.csv"

fn create_new_idf_using_rules(
    deps: UnsafePointer[ExternalDeps],
    inout globals_state: GlobalsState,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> Bool:
    
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            var full_file_name: String = ""
            var units_arg: String = ""
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
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
                
                if full_file_name.len() > 0 and full_file_name[0] == "!"[0]:
                    full_file_name = ""
                    continue
            
            if ios != 0:
                full_file_name = ""
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name.len() > 0:
                deps.pointee.DisplayString("Processing IDF -- " + full_file_name)
                
                var dot_pos: Int = full_file_name.rfind(".")
                var file_name_path: String = ""
                
                if dot_pos >= 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = deps.pointee.MakeLowerCase(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int = deps.pointee.GetNewUnitNumber()
                var file_ok: Bool = False
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var dif_file_name: String = ""
                    if diff_only:
                        dif_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        dif_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        deps.pointee.ShowWarningError("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", globals_state.Auditf)
                        globals_state.ProcessingIMFFile = True
                    else:
                        globals_state.ProcessingIMFFile = False
                    
                    deps.pointee.ProcessInput(globals_state.IDDFileNameWithPath, globals_state.NewIDDFileNameWithPath, full_file_name)
                    
                    if globals_state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    globals_state.DeleteThisRecord = DynamicVector[Bool](globals_state.NumIDFRecords)
                    for i in range(globals_state.NumIDFRecords):
                        globals_state.DeleteThisRecord[i] = False
                    
                    no_version = True
                    for num in range(globals_state.NumIDFRecords):
                        if deps.pointee.MakeUPPERCase(globals_state.IDFRecords[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    var spm_types = InlineArray[String, 29](
                        "SETPOINTMANAGER:SCHEDULED",
                        "SETPOINTMANAGER:SCHEDULED:DUALSETPOINT",
                        "SETPOINTMANAGER:OUTDOORAIRRESET",
                        "SETPOINTMANAGER:SINGLEZONE:REHEAT",
                        "SETPOINTMANAGER:SINGLEZONE:HEATING",
                        "SETPOINTMANAGER:SINGLEZONE:COOLING",
                        "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MINIMUM",
                        "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MAXIMUM",
                        "SETPOINTMANAGER:MIXEDAIR",
                        "SETPOINTMANAGER:OUTDOORAIRPRETREAT",
                        "SETPOINTMANAGER:WARMEST",
                        "SETPOINTMANAGER:COLDEST",
                        "SETPOINTMANAGER:RETURNAIRBYPASSFLOW",
                        "SETPOINTMANAGER:WARMESTTEMPERATUREFLOW",
                        "SETPOINTMANAGER:MULTIZONE:HEATING:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:COOLING:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:MINIMUMHUMIDITY:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:MAXIMUMHUMIDITY:AVERAGE",
                        "SETPOINTMANAGER:MULTIZONE:HUMIDITY:MINIMUM",
                        "SETPOINTMANAGER:MULTIZONE:HUMIDITY:MAXIMUM",
                        "SETPOINTMANAGER:FOLLOWOUTDOORAIRTEMPERATURE",
                        "SETPOINTMANAGER:FOLLOWSYSTEMNODETEMPERATURE",
                        "SETPOINTMANAGER:FOLLOWGROUNDTEMPERATURE",
                        "SETPOINTMANAGER:CONDENSERENTERINGRESET",
                        "SETPOINTMANAGER:CONDENSERENTERINGRESET:IDEAL",
                        "SETPOINTMANAGER:SINGLEZONE:ONESTAGECOOLING",
                        "SETPOINTMANAGER:SINGLEZONE:ONESTAGEHEATING",
                        "SETPOINTMANAGER:RETURNTEMPERATURE:CHILLEDWATER",
                        "SETPOINTMANAGER:RETURNTEMPERATURE:HOTWATER"
                    )
                    
                    var tot_spms: Int = 0
                    for i in range(29):
                        tot_spms += deps.pointee.GetNumObjectsFound(spm_types[i])
                    
                    print("Found", tot_spms, "SPMs")
                    
                    var spm_names = DynamicVector[String](tot_spms)
                    var spm_index: Int = 0
                    
                    for i in range(29):
                        var num_objects = deps.pointee.GetNumObjectsFound(spm_types[i])
                        for spm_num in range(1, num_objects + 1):
                            var alphas = DynamicVector[String](100)
                            var numbers = DynamicVector[Float64](100)
                            var num_alphas: Int = 0
                            var num_numbers: Int = 0
                            var status: Int = 0
                            
                            deps.pointee.GetObjectItem(spm_types[i], spm_num, alphas, num_alphas, numbers, num_numbers, status)
                            
                            if deps.pointee.FindItemInList(alphas[0], spm_names, spm_index) != 0:
                                deps.pointee.ShowFatalError("SetpointManager Unicity of Names: SPM of type " + spm_types[i] + " has a name already found=" + alphas[0], globals_state.Auditf)
                            
                            spm_index += 1
                            if spm_index - 1 < tot_spms:
                                spm_names[spm_index - 1] = alphas[0]
                    
                    var num_vrftu: Int = deps.pointee.GetNumObjectsFound("ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW")
                    var vav_fan_name_to_delete = DynamicVector[String](num_vrftu)
                    var vrftu_i: Int = 0
                    
                    for num in range(globals_state.NumIDFRecords):
                        var rec_name = deps.pointee.MakeUPPERCase(globals_state.IDFRecords[num].Name)
                        if rec_name == "ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW":
                            if vrftu_i < num_vrftu:
                                if deps.pointee.SameString(globals_state.IDFRecords[num].Alphas[6], "FAN:VARIABLEVOLUME"):
                                    vav_fan_name_to_delete[vrftu_i] = globals_state.IDFRecords[num].Alphas[7]
                                else:
                                    vav_fan_name_to_delete[vrftu_i] = ""
                                vrftu_i += 1
                    
                    var num_fan_variable_volume: Int = deps.pointee.GetNumObjectsFound("FAN:VARIABLEVOLUME")
                    var old_fan_vo = DynamicVector[FanVOTransitionInfo](num_fan_variable_volume)
                    var num_old_fan_vo: Int = 0
                    
                    for num in range(globals_state.NumIDFRecords):
                        var rec_name = deps.pointee.MakeUPPERCase(globals_state.IDFRecords[num].Name)
                        if rec_name == "FAN:VARIABLEVOLUME":
                            var record = globals_state.IDFRecords[num]
                            var fan_info = FanVOTransitionInfo()
                            
                            fan_info.oldFanName = record.Alphas[0]
                            fan_info.availSchedule = record.Alphas[1]
                            fan_info.fanTotalEff_str = String(record.Numbers[0])
                            fan_info.pressureRise_str = String(record.Numbers[1])
                            fan_info.maxAirFlow_str = String(record.Numbers[2])
                            fan_info.minFlowInputMethod = record.Alphas[2]
                            fan_info.minAirFlowFrac_str = String(record.Numbers[3])
                            fan_info.fanPowerMinAirFlow_str = String(record.Numbers[4])
                            fan_info.motorEfficiency = String(record.Numbers[5])
                            fan_info.motorInAirStreamFrac = String(record.Numbers[6])
                            fan_info.coeff1 = String(record.Numbers[7])
                            fan_info.coeff2 = String(record.Numbers[8])
                            fan_info.coeff3 = String(record.Numbers[9])
                            fan_info.coeff4 = String(record.Numbers[10])
                            fan_info.coeff5 = String(record.Numbers[11])
                            fan_info.inletAirNodeName = record.Alphas[3]
                            fan_info.outletAirNodeName = record.Alphas[4]
                            
                            if record.Alphas.capacity() == 6:
                                fan_info.endUseSubCat = record.Alphas[5]
                            else:
                                fan_info.endUseSubCat = ""
                            
                            if deps.pointee.FindItemInList(record.Alphas[0], vav_fan_name_to_delete, num_vrftu) != 0:
                                globals_state.DeleteThisRecord[num] = True
                            
                            old_fan_vo[num_old_fan_vo] = fan_info
                            num_old_fan_vo += 1
                    
                    deps.pointee.DisplayString("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(globals_state.NumIDFRecords):
                        if globals_state.DeleteThisRecord[num]:
                            continue
                        
                        for xcount in range(globals_state.IDFRecords[num].CommtS, globals_state.IDFRecords[num].CommtE + 1):
                            pass
                        
                        if no_version and num == 0:
                            var nw_num_args: Int = 0
                            var nw_aorn = DynamicVector[Bool]()
                            var nw_req_fld = DynamicVector[Bool]()
                            var nw_obj_min_flds: Int = 0
                            var nw_fld_names = DynamicVector[String]()
                            var nw_fld_defaults = DynamicVector[String]()
                            var nw_fld_units = DynamicVector[String]()
                            
                            deps.pointee.GetNewObjectDefInIDD("VERSION", nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            
                            var out_args = DynamicVector[String](1000)
                            out_args[0] = globals_state.sVersionNumFourChars
                            var cur_args: Int = 1
                            
                            deps.pointee.ShowWarningError("No version found in file, defaulting to " + globals_state.sVersionNumFourChars, globals_state.Auditf)
                            deps.pointee.WriteOutIDFLinesAsComments(dif_lfn, "Version", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        var object_name: String = globals_state.IDFRecords[num].Name
                        var in_args = DynamicVector[String](1000)
                        var out_args = DynamicVector[String](1000)
                        var cur_args: Int = 0
                        var num_alphas: Int = globals_state.IDFRecords[num].NumAlphas
                        var num_numbers: Int = globals_state.IDFRecords[num].NumNumbers
                        
                        for i in range(num_alphas):
                            in_args[i] = globals_state.IDFRecords[num].Alphas[i]
                        
                        for i in range(num_numbers):
                            in_args[num_alphas + i] = String(globals_state.IDFRecords[num].Numbers[i])
                        
                        cur_args = num_alphas + num_numbers
                        var no_diff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        if not globals_state.MakingPretty:
                            var rec_name_upper = deps.pointee.MakeUPPERCase(globals_state.IDFRecords[num].Name)
                            
                            if rec_name_upper == "VERSION":
                                if in_args[0].__str__()[0:4] == globals_state.sVersionNumFourChars and arg_file:
                                    deps.pointee.ShowWarningError("File is already at latest version.  No new diff file made.", globals_state.Auditf)
                                    latest_version = True
                                    break
                                
                                out_args[0] = globals_state.sVersionNumFourChars
                                no_diff = False
                            
                            elif rec_name_upper == "ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW":
                                var is_variable_volume: Bool = False
                                
                                for i in range(13):
                                    out_args[i] = in_args[i]
                                
                                if deps.pointee.SameString(in_args[13], "FAN:VARIABLEVOLUME"):
                                    no_diff = False
                                    is_variable_volume = True
                                    out_args[13] = "Fan:SystemModel"
                                    out_args[14] = in_args[14]
                                else:
                                    out_args[13] = in_args[13]
                                    out_args[14] = in_args[14]
                                
                                for i in range(cur_args - 15):
                                    out_args[15 + i] = in_args[15 + i]
                            
                            else:
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                        
                        else:
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            deps.pointee.CheckSpecialObjects(dif_lfn, object_name, cur_args, out_args, globals_state.NwFldNames, globals_state.NwFldUnits, written)
                        
                        if not written:
                            deps.pointee.WriteOutIDFLines(dif_lfn, object_name, cur_args, out_args, globals_state.NwFldNames, globals_state.NwFldUnits)
                    
                    deps.pointee.DisplayString("Processing IDF -- Processing idf objects complete.")
                    deps.pointee.ProcessRviMviFiles(file_name_path, "rvi")
                    deps.pointee.ProcessRviMviFiles(file_name_path, "mvi")
                    deps.pointee.CloseOut()
                else:
                    deps.pointee.ProcessRviMviFiles(file_name_path, "rvi")
                    deps.pointee.ProcessRviMviFiles(file_name_path, "mvi")
            else:
                end_of_file = True
            
            var created_output_name: String = ""
            deps.pointee.CreateNewName("Reallocate", created_output_name, " ")
        
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
        var err_flag: Bool = False
        var file_name_path: String = ""
        deps.pointee.copyfile(file_name_path + "." + arg_idf_extension, file_name_path + "." + arg_idf_extension + "old", err_flag)
        deps.pointee.copyfile(file_name_path + "." + arg_idf_extension + "new", file_name_path + "." + arg_idf_extension, err_flag)
    
    return end_of_file

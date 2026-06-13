# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals (source: EnergyPlus): ProgramPath
# - DataVCompareGlobals (source: EnergyPlus): VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, FullFileName, FileNamePath, Auditf, Comments, IDFRecords, NumIDFRecords, CurComment, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, NotInNew, MakingPretty, FatalError, ProcessingIMFFile, ObjectDef, NumObjectDefs, OldRepVarName, NewRepVarName, NumRepVarNames, MaxNameLength, blank
# - InputProcessor (source: EnergyPlus): ProcessInput
# - VCompareGlobalRoutines (source: EnergyPlus): GetNewObjectDefInIDD, GetObjectDefInIDD, FindItemInList, WriteOutIDFLinesAsComments, WriteOutIDFLines, ScanOutputVariablesForReplacement, CheckSpecialObjects, CreateNewName, ProcessRviMviFiles, CloseOut
# - General (source: EnergyPlus): MakeLowerCase, MakeUPPERCase, SameString, TrimTrailZeros
# - DataGlobals (source: EnergyPlus): ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - System (source: EnergyPlus): GetNewUnitNumber, copyfile, DisplayString

from typing import List, Dict, Any, Protocol
from dataclasses import dataclass, field

@dataclass
class CoilData:
    Name: str = ""
    cType: str = ""

def set_this_version_variables(state):
    state.VerString = "Conversion 1.1.1 => 1.2"
    state.VersionNum = 1.0
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + "V1-1-1-Energy+.idd"
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + "V1-2-0-Energy+.idd"
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + "Report Variables 1-1-1-012 to 1-2-0.csv"

def create_new_idf_using_rules(state, end_of_file, diff_only, in_lfn, ask_for_input, input_file_name, arg_file, arg_idf_extension):
    fmta = "(A)"
    
    ios = 0
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    
    alphas = None
    numbers = None
    in_args = None
    a_or_n = None
    req_fld = None
    fld_names = None
    fld_defaults = None
    fld_units = None
    nw_a_or_n = None
    nw_req_fld = None
    nw_fld_names = None
    nw_fld_defaults = None
    nw_fld_units = None
    out_args = None
    match_arg = None
    delete_this_record = None
    coils = []
    num_coils = 0
    
    while still_working:
        exit_because_bad_file = False
        
        while not end_of_file[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="", flush=True)
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = input().strip()
                        ios = 0
                    except:
                        full_file_name = ""
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if full_file_name and full_file_name[0] == "!":
                    full_file_name = ""
                    continue
            
            units_arg = ""
            if ios != 0:
                full_file_name = ""
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != "":
                DisplayString("Processing IDF -- " + full_file_name)
                print(" Processing IDF -- " + full_file_name, file=state.Auditf)
                
                dot_pos = full_file_name.rfind(".")
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = MakeLowerCase(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    print(" ..assuming file extension of .idf", file=state.Auditf)
                    full_file_name = full_file_name.rstrip() + ".idf"
                    local_file_extension = "idf"
                
                dif_lfn = GetNewUnitNumber()
                
                try:
                    with open(full_file_name, "r") as f:
                        file_ok = True
                except:
                    file_ok = False
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    print("File not found=" + full_file_name, file=state.Auditf)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    checkrvi = False
                    if diff_only:
                        out_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        out_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    dif_file = open(out_file_name, "w")
                    
                    if local_file_extension == "imf":
                        ShowWarningError("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, full_file_name)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    alphas = [""] * state.MaxAlphaArgsFound
                    numbers = [0.0] * state.MaxNumericArgsFound
                    in_args = [""] * state.MaxTotalArgs
                    a_or_n = [False] * state.MaxTotalArgs
                    req_fld = [False] * state.MaxTotalArgs
                    fld_names = [""] * state.MaxTotalArgs
                    fld_defaults = [""] * state.MaxTotalArgs
                    fld_units = [""] * state.MaxTotalArgs
                    nw_a_or_n = [False] * state.MaxTotalArgs
                    nw_req_fld = [False] * state.MaxTotalArgs
                    nw_fld_names = [""] * state.MaxTotalArgs
                    nw_fld_defaults = [""] * state.MaxTotalArgs
                    nw_fld_units = [""] * state.MaxTotalArgs
                    out_args = [""] * state.MaxTotalArgs
                    match_arg = [False] * state.MaxTotalArgs
                    delete_this_record = [False] * state.NumIDFRecords
                    
                    num_coils = 0
                    for num in range(state.NumIDFRecords):
                        if MakeUPPERCase(state.IDFRecords[num].Name[:5]) != "COIL:":
                            continue
                        num_coils += 1
                    
                    coils = [CoilData() for _ in range(num_coils)]
                    num_coils = 0
                    for num in range(state.NumIDFRecords):
                        if MakeUPPERCase(state.IDFRecords[num].Name[:5]) != "COIL:":
                            continue
                        coils[num_coils].cType = state.IDFRecords[num].Name
                        coils[num_coils].Name = state.IDFRecords[num].Alphas[0] if state.IDFRecords[num].Alphas else ""
                        num_coils += 1
                    
                    no_version = True
                    for num in range(state.NumIDFRecords):
                        if MakeUPPERCase(state.IDFRecords[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.NumIDFRecords):
                        for xcount in range(state.IDFRecords[num].CommtS, state.IDFRecords[num].CommtE):
                            dif_file.write(state.Comments[xcount].rstrip() + "\n")
                            if xcount == state.IDFRecords[num].CommtE - 1:
                                dif_file.write("\n")
                        
                        if no_version and num == 0:
                            GetNewObjectDefInIDD(state, "VERSION", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = "1.2.0"
                            cur_args = 1
                            WriteOutIDFLinesAsComments(state, dif_file, "VERSION", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if MakeUPPERCase(state.IDFRecords[num].Name.strip()) == "SKY RADIANCE DISTRIBUTION":
                            continue
                        
                        object_name = state.IDFRecords[num].Name
                        if FindItemInList(object_name, [od.Name for od in state.ObjectDef], state.NumObjectDefs) != -1:
                            GetObjectDefInIDD(state, object_name, a_or_n, req_fld, fld_names, fld_defaults, fld_units)
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            for i in range(num_alphas):
                                alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = state.IDFRecords[num].Numbers[i]
                            cur_args = num_alphas + num_numbers
                            in_args = [""] * state.MaxTotalArgs
                            out_args = [""] * state.MaxTotalArgs
                            na = 0
                            nn = 0
                            for arg in range(cur_args):
                                if a_or_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                        else:
                            print('Object="' + object_name.rstrip() + '" does not seem to be on the "old" IDD.', file=state.Auditf)
                            print("... will be listed as comments (no field names) on the new output file.", file=state.Auditf)
                            print("... Alpha fields will be listed first, then numerics.", file=state.Auditf)
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            for i in range(num_alphas):
                                alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = state.IDFRecords[num].Numbers[i]
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            nn = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn - 1] = str(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [""] * state.MaxTotalArgs
                            nw_fld_units = [""] * state.MaxTotalArgs
                            WriteOutIDFLinesAsComments(state, dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if FindItemInList(MakeUPPERCase(object_name), state.NotInNew, len(state.NotInNew)) == -1:
                            GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            if state.ObjMinFlds != state.NwObjMinFlds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.MakingPretty:
                            obj_upper = MakeUPPERCase(state.IDFRecords[num].Name.strip())
                            
                            if obj_upper == "VERSION":
                                if in_args[0][:3] == "1.2" and arg_file:
                                    ShowWarningError("File is already at latest version.  No new diff file made.", state.Auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = "1.2"
                            
                            elif obj_upper == "ELECTRIC LOAD CENTER:GENERATORS":
                                GetNewObjectDefInIDD(state, "ELECTRIC LOAD CENTER:GENERATORS", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                                for xcount in range(2, cur_args, 4):
                                    if MakeUPPERCase(out_args[xcount]) == "GENERATOR:PHOTOVOLTAICS":
                                        out_args[xcount] = "GENERATOR:PV:EQUIVALENT ONE-DIODE"
                            
                            elif obj_upper == "COIL:DX:COOLINGBYPASSFACTOREMPIRICAL":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if MakeUPPERCase(out_args[13]) == "VARFANVARCOMP" or MakeUPPERCase(out_args[13]) == "VARFANUNLOADCOMP":
                                    out_args[13] = "ContFanCycComp"
                                    nodiff = False
                                else:
                                    nodiff = True
                            
                            elif obj_upper == "AIR CONDITIONER:WINDOW:CYCLING":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                out_args[14] = "Unknown"
                                xcount = FindItemInList(out_args[10], [c.Name for c in coils], num_coils)
                                nodiff = False
                                cur_args = 15
                            
                            elif obj_upper == "GENERATOR:PHOTOVOLTAICS":
                                GetNewObjectDefInIDD(state, "GENERATOR:PV:EQUIVALENT ONE-DIODE", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                object_name = "GENERATOR:PV:EQUIVALENT ONE-DIODE"
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                            
                            elif obj_upper == "WATERHEATER:SIMPLE":
                                GetNewObjectDefInIDD(state, "WATER HEATER:SIMPLE", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                object_name = "WATER HEATER:SIMPLE"
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = False
                            
                            elif obj_upper == "DESICCANT DEHUMIDIFIER:SOLID":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(10):
                                    out_args[i] = in_args[i]
                                out_args[10] = in_args[15]
                                out_args[11] = " unknown "
                                out_args[12] = in_args[16]
                                out_args[13] = " unknown "
                                out_args[14] = in_args[17]
                                out_args[15] = in_args[18]
                                if MakeUPPERCase(in_args[18]) != "DEFAULT":
                                    var_gs = 16
                                    for xcount in range(19, cur_args):
                                        out_args[var_gs] = in_args[xcount]
                                        var_gs += 1
                                    cur_args = cur_args - 5 + 2
                                else:
                                    cur_args = 16
                                for xcount in range(state.NumIDFRecords):
                                    if MakeUPPERCase(state.IDFRecords[xcount].Name[:4]) != "COIL":
                                        continue
                                    if SameString(state.IDFRecords[xcount].Alphas[0], in_args[16]):
                                        out_args[11] = state.IDFRecords[xcount].Name
                                        break
                                for xcount in range(state.NumIDFRecords):
                                    if MakeUPPERCase(state.IDFRecords[xcount].Name[:3]) != "FAN":
                                        continue
                                    if SameString(state.IDFRecords[xcount].Alphas[0], in_args[17]):
                                        out_args[13] = state.IDFRecords[xcount].Name
                                        break
                                nodiff = False
                            
                            elif obj_upper == "PLANT LOOP":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                out_args[3] = in_args[10]
                                nodiff = False
                                WriteOutIDFLines(state, dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                
                                GetNewObjectDefInIDD(state, "SET POINT MANAGER:SCHEDULED", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                cur_args = 4
                                out_args[0] = in_args[0].rstrip() + " Setpoint Manager"
                                out_args[1] = "TEMP"
                                out_args[2] = in_args[3]
                                out_args[3] = in_args[10]
                                WriteOutIDFLines(state, dif_file, "SET POINT MANAGER:SCHEDULED", cur_args, out_args, nw_fld_names, nw_fld_units)
                                written = True
                            
                            elif obj_upper == "CONDENSER LOOP":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if in_args[3] == "AIR" or in_args[3] == "GROUND":
                                    nodiff = True
                                else:
                                    out_args[3] = in_args[10]
                                    nodiff = False
                                    WriteOutIDFLines(state, dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                    
                                    GetNewObjectDefInIDD(state, "SET POINT MANAGER:SCHEDULED", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    cur_args = 4
                                    out_args[0] = in_args[0].rstrip() + " Setpoint Manager"
                                    out_args[1] = "TEMP"
                                    out_args[2] = in_args[3]
                                    out_args[3] = in_args[10]
                                    WriteOutIDFLines(state, dif_file, "SET POINT MANAGER:SCHEDULED", cur_args, out_args, nw_fld_names, nw_fld_units)
                                    written = True
                            
                            elif obj_upper == "WINDOWSHADINGCONTROL":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                nodiff = False
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if SameString("InteriorNonInsulatingShade", in_args[1]):
                                    out_args[1] = "InteriorShade"
                                if SameString("ExteriorNonInsulatingShade", in_args[1]):
                                    out_args[1] = "ExteriorShade"
                                if SameString("InteriorInsulatingShade", in_args[1]):
                                    out_args[1] = "InteriorShade"
                                if SameString("ExteriorInsulatingShade", in_args[1]):
                                    out_args[1] = "ExteriorShade"
                                if SameString("Schedule", in_args[3]):
                                    out_args[3] = "OnIfScheduleAllows"
                                if SameString("SolarOnWindow", in_args[3]):
                                    out_args[3] = "OnIfHighSolarOnWindow"
                                if SameString("HorizontalSolar", in_args[3]):
                                    out_args[3] = "OnIfHighHorizontalSolar"
                                if SameString("OutsideAirTemp", in_args[3]):
                                    out_args[3] = "OnIfHighOutsideAirTemp"
                                if SameString("ZoneAirTemp", in_args[3]):
                                    out_args[3] = "OnIfHighZoneAirTemp"
                                if SameString("ZoneCooling", in_args[3]):
                                    out_args[3] = "OnIfHighZoneCooling"
                                if SameString("Glare", in_args[3]):
                                    out_args[3] = "OnIfHighGlare"
                                if SameString("DaylightIlluminance", in_args[3]):
                                    out_args[3] = "MeetDaylightIlluminanceSetpoint"
                            
                            elif obj_upper == "REPORT VARIABLE":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    nodiff = False
                                del_this = False
                                ScanOutputVariablesForReplacement(state, 1, del_this, checkrvi, nodiff, object_name, dif_file, True, False, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper in ["REPORT METER", "REPORT METERFILEONLY", "REPORT CUMULATIVE METER", "REPORT CUMULATIVE METERFILEONLY"]:
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                del_this = False
                                ScanOutputVariablesForReplacement(state, 0, del_this, checkrvi, nodiff, object_name, dif_file, False, True, False, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == "REPORT:TABLE:TIMEBINS":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    nodiff = False
                                del_this = False
                                ScanOutputVariablesForReplacement(state, 1, del_this, checkrvi, nodiff, object_name, dif_file, False, False, True, cur_args, written, False)
                                if del_this:
                                    continue
                            
                            elif obj_upper == "REPORT:TABLE:MONTHLY":
                                GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                nodiff = True
                                if out_args[0] == "":
                                    out_args[0] = "*"
                                    nodiff = False
                                cur_var = 2
                                var_idx = 2
                                while var_idx < cur_args:
                                    uc_rep_var_name = MakeUPPERCase(in_args[var_idx])
                                    out_args[cur_var] = in_args[var_idx]
                                    out_args[cur_var + 1] = in_args[var_idx + 1]
                                    pos = uc_rep_var_name.find("[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[:pos]
                                        out_args[cur_var] = in_args[var_idx][:pos]
                                        out_args[cur_var + 1] = in_args[var_idx + 1]
                                    del_this = False
                                    for arg in range(state.NumRepVarNames):
                                        uc_comp_rep_var_name = MakeUPPERCase(state.OldRepVarName[arg])
                                        wild_match = False
                                        if len(uc_comp_rep_var_name) > 0 and uc_comp_rep_var_name[-1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[:-1]
                                        pos = uc_rep_var_name.find(uc_comp_rep_var_name)
                                        if pos > 0:
                                            continue
                                        if pos >= 0:
                                            if state.NewRepVarName[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var_idx + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            if arg + 1 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var_idx + 1]
                                                nodiff = False
                                            if arg + 2 < state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 2] + out_args[cur_var][len(uc_comp_rep_var_name):]
                                                out_args[cur_var + 1] = in_args[var_idx + 1]
                                                nodiff = False
                                            break
                                    if not del_this:
                                        cur_var += 2
                                    var_idx += 2
                                cur_args = cur_var - 1
                            
                            else:
                                if FindItemInList(object_name, state.NotInNew, len(state.NotInNew)) != -1:
                                    print('Object="' + object_name.rstrip() + '" is not in the "new" IDD.', file=state.Auditf)
                                    print("... will be listed as comments on the new output file.", file=state.Auditf)
                                    WriteOutIDFLinesAsComments(state, dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    for i in range(cur_args):
                                        out_args[i] = in_args[i]
                                    nodiff = True
                        else:
                            GetNewObjectDefInIDD(state, state.IDFRecords[num].Name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                        
                        if diff_min_fields and nodiff:
                            GetNewObjectDefInIDD(state, object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                            nodiff = False
                            for arg in range(cur_args, state.NwObjMinFlds):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(state.NwObjMinFlds, cur_args)
                        
                        if nodiff and diff_only:
                            pass
                        else:
                            if not written:
                                CheckSpecialObjects(state, dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            
                            if not written:
                                WriteOutIDFLines(state, dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state.IDFRecords[state.NumIDFRecords - 1].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords - 1].CommtE, state.CurComment):
                            dif_file.write(state.Comments[xcount].rstrip() + "\n")
                    
                    dif_file.close()
                    
                    if checkrvi:
                        ProcessRviMviFiles(state, file_name_path, "rvi")
                        ProcessRviMviFiles(state, file_name_path, "mvi")
                    
                    CloseOut(state)
                else:
                    ProcessRviMviFiles(state, file_name_path, "rvi")
                    ProcessRviMviFiles(state, file_name_path, "mvi")
            else:
                end_of_file[0] = True
            
            created_output_name = ""
            CreateNewName(state, "Reallocate", created_output_name)
            
            if delete_this_record is not None:
                pass
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[0] = False
            else:
                end_of_file[0] = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        copyfile(file_name_path + "." + arg_idf_extension, file_name_path + "." + arg_idf_extension + "old")
        copyfile(file_name_path + "." + arg_idf_extension + "new", file_name_path + "." + arg_idf_extension)
        
        try:
            with open(file_name_path + ".rvi", "r") as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            copyfile(file_name_path + ".rvi", file_name_path + ".rviold")
        
        try:
            with open(file_name_path + ".rvinew", "r") as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            copyfile(file_name_path + ".rvinew", file_name_path + ".rvi")
        
        try:
            with open(file_name_path + ".mvi", "r") as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            copyfile(file_name_path + ".mvi", file_name_path + ".mviold")
        
        try:
            with open(file_name_path + ".mvinew", "r") as f:
                file_exist = True
        except:
            file_exist = False
        if file_exist:
            copyfile(file_name_path + ".mvinew", file_name_path + ".mvi")

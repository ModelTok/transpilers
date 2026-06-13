# EXTERNAL DEPS (to wire in glue):
# - ProcessInput: from InputProcessor, processes IDD and IDF files
# - GetNewUnitNumber: returns an available file unit number
# - FindNumber: searches for a numeric value
# - TrimTrailZeros: formats a number string
# - GetNewObjectDefInIDD: retrieves object definition from new IDD
# - GetObjectDefInIDD: retrieves object definition from old IDD
# - FindItemInList: searches for item in a string list
# - MakeUPPERCase: converts string to uppercase
# - MakeLowerCase: converts string to lowercase
# - samestring: case-insensitive string comparison
# - DisplayString: displays a message
# - ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError: error reporting
# - WriteOutIDFLines: writes IDF object to file
# - WriteOutIDFLinesAsComments: writes IDF object as comments
# - CheckSpecialObjects: handles special object formatting
# - ProcessRviMviFiles: processes RVI/MVI auxiliary files
# - CloseOut: closes output files
# - CreateNewName: generates new file names
# - copyfile: copies files

from dataclasses import dataclass, field
from typing import List, Optional, Protocol
import os


def feq(s1: str, s2: str) -> bool:
    """Fortran-style blank-padded string equality."""
    return s1.rstrip() == s2.rstrip()


def fortran_index(s: str, substr: str, backward: bool = False) -> int:
    """Fortran INDEX function: 1-based, returns 0 if not found."""
    if backward:
        pos = s.rfind(substr)
    else:
        pos = s.find(substr)
    return pos + 1 if pos >= 0 else 0


def fortran_scan(s: str, chars: str, backward: bool = False) -> int:
    """Fortran SCAN function: 1-based, returns 0 if not found."""
    if backward:
        for i in range(len(s) - 1, -1, -1):
            if s[i] in chars:
                return i + 1
    else:
        for i in range(len(s)):
            if s[i] in chars:
                return i + 1
    return 0


def trim(s: str) -> str:
    """Fortran TRIM: remove trailing blanks."""
    return s.rstrip()


def adjustl(s: str) -> str:
    """Fortran ADJUSTL: remove leading blanks."""
    return s.lstrip()


def slice_assign(arr: List, start: int, end: int, values: List):
    """Assign values to Fortran-style 1-based inclusive slice."""
    for i, v in enumerate(values):
        if start + i <= end and start + i < len(arr):
            arr[start + i] = v


@dataclass
class VersionState:
    """State from SetVersion module."""
    VerString: str = ""
    VersionNum: float = 0.0
    IDDFileNameWithPath: str = ""
    NewIDDFileNameWithPath: str = ""
    RepVarFileNameWithPath: str = ""


@dataclass
class ProcessingState:
    """Global state for IDF processing."""
    FullFileName: str = ""
    FileNamePath: str = ""
    Auditf: Optional[object] = None
    IDFRecords: List = field(default_factory=list)
    Comments: List[str] = field(default_factory=list)
    NumIDFRecords: int = 0
    CurComment: int = 0
    ObjectDef: Optional[object] = None
    NumObjectDefs: int = 0
    MaxAlphaArgsFound: int = 0
    MaxNumericArgsFound: int = 0
    MaxTotalArgs: int = 0
    NumAlphas: int = 0
    NumNumbers: int = 0
    ProcessingIMFFile: bool = False
    FatalError: bool = False
    OldRepVarName: List[str] = field(default_factory=list)
    NewRepVarName: List[str] = field(default_factory=list)
    NumRepVarNames: int = 0
    NotInNew: List[str] = field(default_factory=list)
    MakingPretty: bool = False
    ProgramPath: str = ""


@dataclass
class IDFRecord:
    Name: str = ""
    NumAlphas: int = 0
    NumNumbers: int = 0
    CommtS: int = 0
    CommtE: int = 0
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[str] = field(default_factory=list)


Blank = " " * 132


def set_version(state: VersionState):
    """SetThisVersionVariables subroutine."""
    state.VerString = "Conversion 1.2.1 => 1.2.2"
    state.VersionNum = 1.0
    state.IDDFileNameWithPath = trim(state.ProgramPath) + "V1-2-1-Energy+.idd"
    state.NewIDDFileNameWithPath = trim(state.ProgramPath) + "V1-2-2-Energy+.idd"
    state.RepVarFileNameWithPath = trim(state.ProgramPath) + "Report Variables 1-2-1-012 to 1-2-2.csv"


# External stub signatures (user to implement)
def ProcessInput(idd_file: str, new_idd_file: str, idf_file: str, state: ProcessingState):
    pass


def GetNewUnitNumber() -> int:
    pass


def FindNumber(name: str) -> int:
    pass


def TrimTrailZeros(value: str) -> str:
    pass


def GetNewObjectDefInIDD(name: str, state: ProcessingState) -> tuple:
    pass


def GetObjectDefInIDD(name: str, state: ProcessingState) -> tuple:
    pass


def FindItemInList(item: str, items: List[str], count: int) -> int:
    pass


def MakeUPPERCase(s: str) -> str:
    pass


def MakeLowerCase(s: str) -> str:
    pass


def samestring(s1: str, s2: str) -> bool:
    pass


def DisplayString(msg: str):
    pass


def ShowWarningError(msg: str, auditf: Optional[object] = None):
    pass


def WriteOutIDFLines(lfn: int, obj_name: str, cur_args: int, out_args: List[str], 
                     fld_names: List[str], fld_units: List[str]):
    pass


def WriteOutIDFLinesAsComments(lfn: int, obj_name: str, cur_args: int, out_args: List[str],
                               fld_names: List[str], fld_units: List[str]):
    pass


def CheckSpecialObjects(lfn: int, obj_name: str, cur_args: int, out_args: List[str],
                        fld_names: List[str], fld_units: List[str]) -> tuple:
    pass


def ProcessRviMviFiles(path: str, ext: str):
    pass


def CloseOut():
    pass


def CreateNewName(mode: str, name: str, default: str):
    pass


def copyfile(src: str, dst: str) -> bool:
    pass


def ScanOutputVariablesForReplacement(var_pos: int, del_this: List[bool], checkrvi: List[bool],
                                      nodiff: List[bool], obj_name: str, lfn: int,
                                      out_var: bool, mtr_var: bool, time_bin_var: bool,
                                      cur_args: int, written: List[bool], use_parent: bool,
                                      state: ProcessingState):
    pass


def create_new_idf_using_rules(end_of_file: List[bool], diff_only: bool, in_lfn: int,
                               ask_for_input: bool, input_file_name: str,
                               arg_file: bool, arg_idf_extension: str,
                               state: ProcessingState):
    """CreateNewIDFUsingRules subroutine."""
    
    Fmta = "(A)"
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                state.FullFileName = input("--> ")
            else:
                if not arg_file:
                    ios = 0
                    state.FullFileName = ""
                elif not arg_file_being_done:
                    state.FullFileName = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.FullFileName = Blank
                    ios = 1
                
                if state.FullFileName[0:1] == "!":
                    state.FullFileName = Blank
                    continue
            
            units_arg = Blank
            if ios != 0:
                state.FullFileName = Blank
            state.FullFileName = adjustl(state.FullFileName)
            
            if state.FullFileName != Blank:
                DisplayString("Processing IDF -- " + trim(state.FullFileName))
                if state.Auditf:
                    print(" Processing IDF -- " + trim(state.FullFileName), file=state.Auditf)
                
                dot_pos = fortran_scan(state.FullFileName, ".", backward=True)
                if dot_pos != 0:
                    state.FileNamePath = state.FullFileName[0:dot_pos - 1]
                    local_file_extension = MakeLowerCase(state.FullFileName[dot_pos:])
                else:
                    state.FileNamePath = state.FullFileName
                    print(" assuming file extension of .idf")
                    if state.Auditf:
                        print(" ..assuming file extension of .idf", file=state.Auditf)
                    state.FullFileName = trim(state.FullFileName) + ".idf"
                    local_file_extension = "idf"
                
                dif_lfn = GetNewUnitNumber()
                file_ok = os.path.exists(trim(state.FullFileName))
                
                if not file_ok:
                    print("File not found=" + trim(state.FullFileName))
                    if state.Auditf:
                        print("File not found=" + trim(state.FullFileName), file=state.Auditf)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    checkrvi = False
                    if diff_only:
                        out_file_name = trim(state.FileNamePath) + "." + trim(local_file_extension) + "dif"
                    else:
                        out_file_name = trim(state.FileNamePath) + "." + trim(local_file_extension) + "new"
                    
                    dif_file = open(out_file_name, "w")
                    
                    if local_file_extension == "imf":
                        ShowWarningError("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.Auditf)
                        state.ProcessingIMFFile = True
                    else:
                        state.ProcessingIMFFile = False
                    
                    ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath,
                                trim(state.FullFileName), state)
                    
                    if state.FatalError:
                        exit_because_bad_file = True
                        break
                    
                    # Allocate arrays
                    max_alpha = state.MaxAlphaArgsFound
                    max_numeric = state.MaxNumericArgsFound
                    max_total = state.MaxTotalArgs
                    
                    alphas = [""] * (max_alpha + 1)
                    numbers = [""] * (max_numeric + 1)
                    in_args = [""] * (max_total + 1)
                    out_args = [""] * (max_total + 1)
                    match_arg = [""] * (max_total + 1)
                    
                    aorn = [False] * (max_total + 1)
                    req_fld = [False] * (max_total + 1)
                    fld_names = [""] * (max_total + 1)
                    fld_defaults = [""] * (max_total + 1)
                    fld_units = [""] * (max_total + 1)
                    
                    nwaorn = [False] * (max_total + 1)
                    nw_req_fld = [False] * (max_total + 1)
                    nw_fld_names = [""] * (max_total + 1)
                    nw_fld_defaults = [""] * (max_total + 1)
                    nw_fld_units = [""] * (max_total + 1)
                    
                    delete_this_record = [False] * (state.NumIDFRecords + 1)
                    
                    # Check for VERSION record
                    no_version = True
                    for num in range(1, state.NumIDFRecords + 1):
                        if MakeUPPERCase(state.IDFRecords[num].Name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    # Process each IDF record
                    for num in range(1, state.NumIDFRecords + 1):
                        # Write comments
                        for xcount in range(state.IDFRecords[num].CommtS + 1, state.IDFRecords[num].CommtE + 1):
                            dif_file.write(trim(state.Comments[xcount]) + "\n")
                            if xcount == state.IDFRecords[num].CommtE:
                                dif_file.write("\n")
                        
                        # Add VERSION if needed
                        if no_version and num == 1:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                GetNewObjectDefInIDD("VERSION", state)
                            out_args[1] = "1.2.2"
                            cur_args = 1
                            WriteOutIDFLinesAsComments(dif_file, "VERSION", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        # Skip SKY RADIANCE DISTRIBUTION
                        if MakeUPPERCase(trim(state.IDFRecords[num].Name)) == "SKY RADIANCE DISTRIBUTION":
                            continue
                        
                        object_name = state.IDFRecords[num].Name
                        
                        # Get object definition
                        if FindItemInList(object_name, [od.Name for od in state.ObjectDef], state.NumObjectDefs) != 0:
                            num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = \
                                GetObjectDefInIDD(object_name, state)
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            
                            for i in range(1, num_alphas + 1):
                                alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(1, num_numbers + 1):
                                numbers[i] = state.IDFRecords[num].Numbers[i]
                            
                            cur_args = num_alphas + num_numbers
                            in_args = [""] * (max_total + 1)
                            out_args = [""] * (max_total + 1)
                            na = 0
                            nn = 0
                            
                            for arg in range(1, cur_args + 1):
                                if aorn[arg]:
                                    na += 1
                                    in_args[arg] = alphas[na]
                                else:
                                    nn += 1
                                    in_args[arg] = numbers[nn]
                        else:
                            if state.Auditf:
                                print("Object=\"" + trim(object_name) + "\" does not seem to be on the \"old\" IDD.", file=state.Auditf)
                                print("... will be listed as comments (no field names) on the new output file.", file=state.Auditf)
                                print("... Alpha fields will be listed first, then numerics.", file=state.Auditf)
                            
                            num_alphas = state.IDFRecords[num].NumAlphas
                            num_numbers = state.IDFRecords[num].NumNumbers
                            
                            for i in range(1, num_alphas + 1):
                                alphas[i] = state.IDFRecords[num].Alphas[i]
                            for i in range(1, num_numbers + 1):
                                numbers[i] = state.IDFRecords[num].Numbers[i]
                            
                            for arg in range(1, num_alphas + 1):
                                out_args[arg] = alphas[arg]
                            
                            nn = num_alphas + 1
                            for arg in range(1, num_numbers + 1):
                                out_args[nn] = numbers[arg]
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = [""] * (max_total + 1)
                            nw_fld_units = [""] * (max_total + 1)
                            
                            WriteOutIDFLinesAsComments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        nodiff = True
                        diff_min_fields = False
                        written = False
                        
                        if FindItemInList(MakeUPPERCase(object_name), state.NotInNew, len(state.NotInNew)) == 0:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                GetNewObjectDefInIDD(object_name, state)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.MakingPretty:
                            obj_upper = MakeUPPERCase(trim(state.IDFRecords[num].Name))
                            
                            if obj_upper == "VERSION":
                                if in_args[1][0:5] == "1.2.2" and arg_file:
                                    ShowWarningError("File is already at latest version.  No new diff file made.", state.Auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                out_args[1] = "1.2.2"
                                nodiff = False
                            
                            elif obj_upper == "DESICCANT DEHUMIDIFIER:SOLID":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                if out_args[7] == "LEAVING HUMRAT:BYPASS":
                                    nodiff = False
                                    out_args[7] = "FIXED LEAVING HUMRAT SETPOINT:BYPASS"
                            
                            elif obj_upper == "DOMESTIC HOT WATER":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                nodiff = False
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = in_args[3]
                                out_args[4] = "1.0"
                                out_args[5] = in_args[4]
                                out_args[5] = trim(in_args[1]) + ":FRF Sch"
                                cur_args = 6
                                WriteOutIDFLines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD("SCHEDULE:COMPACT", state)
                                out_args[1] = trim(in_args[1]) + ":FRF Sch"
                                out_args[2] = " "
                                out_args[3] = "Through: 12/31"
                                out_args[4] = "For: AllDays"
                                out_args[5] = "Until: 24:00"
                                out_args[6] = in_args[5]
                                cur_args = 6
                                WriteOutIDFLines(dif_file, "SCHEDULE:COMPACT", cur_args, out_args, nw_fld_names, nw_fld_units)
                                written = True
                            
                            elif obj_upper == "PLANT LOAD PROFILE":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = in_args[3]
                                out_args[4] = in_args[4]
                                out_args[5] = "1.0"
                                out_args[6] = in_args[5]
                                cur_args = 6
                                nodiff = False
                            
                            elif obj_upper == "UNITARYSYSTEM:HEATPUMP:WATERTOAIR":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                slice_assign(out_args, 1, 11, in_args[1:12])
                                slice_assign(out_args, 12, 13, in_args[13:15])
                                out_args[14] = "2.5"
                                out_args[15] = "60"
                                out_args[16] = "0.01"
                                out_args[17] = "60"
                                slice_assign(out_args, 18, 24, in_args[16:23])
                                cur_args = 24
                                nodiff = False
                            
                            elif obj_upper == "COIL:WATERTOAIRHP:COOLING":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = "Water"
                                out_args[4] = "R22"
                                out_args[5] = in_args[3]
                                out_args[6] = in_args[4]
                                out_args[7] = "0"
                                out_args[8] = "0"
                                slice_assign(out_args, 9, 14, in_args[5:11])
                                out_args[15] = in_args[13]
                                out_args[16] = in_args[12]
                                slice_assign(out_args, 17, 22, in_args[14:20])
                                out_args[23] = in_args[11]
                                out_args[24] = " "
                                cur_args = 24
                                nodiff = False
                            
                            elif obj_upper == "COIL:WATERTOAIRHP:HEATING":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = "Water"
                                out_args[4] = "R22"
                                slice_assign(out_args, 5, 12, in_args[3:11])
                                out_args[13] = in_args[12]
                                slice_assign(out_args, 14, 19, in_args[13:19])
                                out_args[20] = in_args[11]
                                out_args[21] = " "
                                cur_args = 21
                                nodiff = False
                            
                            elif obj_upper == "BUILDING":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                if cur_args == 8:
                                    nodiff = False
                                    if MakeUPPERCase(out_args[8]) == "YES":
                                        out_args[6] = trim(out_args[6]) + "WithReflections"
                                        out_args[8] = Blank
                                        cur_args = 7
                                    elif MakeUPPERCase(out_args[8]) == "NO":
                                        out_args[8] = Blank
                                        cur_args = 7
                            
                            elif obj_upper == "WINDOWSHADINGCONTROL":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                nodiff = False
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                if samestring("InteriorNonInsulatingShade", in_args[2]):
                                    out_args[2] = "InteriorShade"
                                if samestring("ExteriorNonInsulatingShade", in_args[2]):
                                    out_args[2] = "ExteriorShade"
                                if samestring("InteriorInsulatingShade", in_args[2]):
                                    out_args[2] = "InteriorShade"
                                if samestring("ExteriorInsulatingShade", in_args[2]):
                                    out_args[2] = "ExteriorShade"
                                if samestring("Schedule", in_args[4]):
                                    out_args[4] = "OnIfScheduleAllows"
                                if samestring("SolarOnWindow", in_args[4]):
                                    out_args[4] = "OnIfHighSolarOnWindow"
                                if samestring("HorizontalSolar", in_args[4]):
                                    out_args[4] = "OnIfHighHorizontalSolar"
                                if samestring("OutsideAirTemp", in_args[4]):
                                    out_args[4] = "OnIfHighOutsideAirTemp"
                                if samestring("ZoneAirTemp", in_args[4]):
                                    out_args[4] = "OnIfHighZoneAirTemp"
                                if samestring("ZoneCooling", in_args[4]):
                                    out_args[4] = "OnIfHighZoneCooling"
                                if samestring("Glare", in_args[4]):
                                    out_args[4] = "OnIfHighGlare"
                                if samestring("DaylightIlluminance", in_args[4]):
                                    out_args[4] = "MeetDaylightIlluminanceSetpoint"
                            
                            elif obj_upper == "REPORT VARIABLE":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                if out_args[1] == Blank:
                                    out_args[1] = "*"
                                    nodiff = False
                                del_this = [False]
                                ScanOutputVariablesForReplacement(2, del_this, [checkrvi], [nodiff], object_name, dif_file,
                                                                 True, False, False, cur_args, [written], False, state)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper in ["REPORT METER", "REPORT METERFILEONLY", "REPORT CUMULATIVE METER", "REPORT CUMULATIVE METERFILEONLY"]:
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                del_this = [False]
                                ScanOutputVariablesForReplacement(1, del_this, [checkrvi], [nodiff], object_name, dif_file,
                                                                 False, True, False, cur_args, [written], False, state)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper == "REPORT:TABLE:TIMEBINS":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                if out_args[1] == Blank:
                                    out_args[1] = "*"
                                    nodiff = False
                                del_this = [False]
                                ScanOutputVariablesForReplacement(2, del_this, [checkrvi], [nodiff], object_name, dif_file,
                                                                 False, False, True, cur_args, [written], False, state)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper == "REPORT:TABLE:MONTHLY":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    GetNewObjectDefInIDD(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                if out_args[1] == Blank:
                                    out_args[1] = "*"
                                    nodiff = False
                                
                                cur_var = 3
                                var = 3
                                while var <= cur_args:
                                    uc_rep_var_name = MakeUPPERCase(in_args[var])
                                    out_args[cur_var] = in_args[var]
                                    out_args[cur_var + 1] = in_args[var + 1]
                                    pos = fortran_index(uc_rep_var_name, "[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos - 1]
                                        out_args[cur_var] = in_args[var][0:pos - 1]
                                        out_args[cur_var + 1] = in_args[var + 1]
                                    
                                    del_this = False
                                    for arg in range(1, state.NumRepVarNames + 1):
                                        uc_comp_rep_var_name = MakeUPPERCase(state.OldRepVarName[arg])
                                        wild_match = False
                                        if uc_comp_rep_var_name[len(trim(uc_comp_rep_var_name)) - 1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[0:len(trim(uc_comp_rep_var_name)) - 1] + " "
                                        
                                        pos = fortran_index(trim(uc_rep_var_name), trim(uc_comp_rep_var_name))
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.NewRepVarName[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg]
                                                else:
                                                    out_args[cur_var] = trim(state.NewRepVarName[arg]) + out_args[cur_var][len(trim(uc_comp_rep_var_name)):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            else:
                                                del_this = True
                                            
                                            if state.OldRepVarName[arg] == state.OldRepVarName[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 1]
                                                else:
                                                    out_args[cur_var] = trim(state.NewRepVarName[arg + 1]) + out_args[cur_var][len(trim(uc_comp_rep_var_name)):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            
                                            if arg + 2 <= state.NumRepVarNames and state.OldRepVarName[arg] == state.OldRepVarName[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.NewRepVarName[arg + 2]
                                                else:
                                                    out_args[cur_var] = trim(state.NewRepVarName[arg + 2]) + out_args[cur_var][len(trim(uc_comp_rep_var_name)):]
                                                out_args[cur_var + 1] = in_args[var + 1]
                                                nodiff = False
                                            break
                                    
                                    if not del_this:
                                        cur_var += 2
                                    var += 2
                                
                                cur_args = cur_var - 1
                            
                            else:
                                if FindItemInList(object_name, state.NotInNew, len(state.NotInNew)) != 0:
                                    if state.Auditf:
                                        print("Object=\"" + trim(object_name) + "\" is not in the \"new\" IDD.", file=state.Auditf)
                                        print("... will be listed as comments on the new output file.", file=state.Auditf)
                                    WriteOutIDFLinesAsComments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        GetNewObjectDefInIDD(object_name, state)
                                    slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                    nodiff = True
                        
                        else:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                GetNewObjectDefInIDD(state.IDFRecords[num].Name, state)
                            slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                        
                        if diff_min_fields and nodiff:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                GetNewObjectDefInIDD(object_name, state)
                            slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                            nodiff = False
                            for arg in range(cur_args + 1, nw_obj_min_flds + 1):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            CheckSpecialObjects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if not written:
                            WriteOutIDFLines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    # Write trailing comments
                    if state.IDFRecords[state.NumIDFRecords].CommtE != state.CurComment:
                        for xcount in range(state.IDFRecords[state.NumIDFRecords].CommtE + 1, state.CurComment + 1):
                            dif_file.write(trim(state.Comments[xcount]) + "\n")
                            if xcount == state.IDFRecords[state.NumIDFRecords].CommtE:
                                dif_file.write("\n")
                    
                    dif_file.close()
                    
                    if checkrvi:
                        ProcessRviMviFiles(state.FileNamePath, "rvi")
                        ProcessRviMviFiles(state.FileNamePath, "mvi")
                    
                    CloseOut()
                
                else:
                    ProcessRviMviFiles(state.FileNamePath, "rvi")
                    ProcessRviMviFiles(state.FileNamePath, "mvi")
            
            else:
                end_of_file[0] = True
            
            CreateNewName("Reallocate", "", " ")
        
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
        copyfile(trim(state.FileNamePath) + "." + trim(arg_idf_extension),
                trim(state.FileNamePath) + "." + trim(arg_idf_extension) + "old")
        copyfile(trim(state.FileNamePath) + "." + trim(arg_idf_extension) + "new",
                trim(state.FileNamePath) + "." + trim(arg_idf_extension))
        
        if os.path.exists(trim(state.FileNamePath) + ".rvi"):
            copyfile(trim(state.FileNamePath) + ".rvi",
                    trim(state.FileNamePath) + ".rviold")
        
        if os.path.exists(trim(state.FileNamePath) + ".rvinew"):
            copyfile(trim(state.FileNamePath) + ".rvinew",
                    trim(state.FileNamePath) + ".rvi")
        
        if os.path.exists(trim(state.FileNamePath) + ".mvi"):
            copyfile(trim(state.FileNamePath) + ".mvi",
                    trim(state.FileNamePath) + ".mviold")
        
        if os.path.exists(trim(state.FileNamePath) + ".mvinew"):
            copyfile(trim(state.FileNamePath) + ".mvinew",
                    trim(state.FileNamePath) + ".mvi")

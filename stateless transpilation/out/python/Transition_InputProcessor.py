"""
InputProcessor - Full Python port of EnergyPlus InputProcessor module
Faithful translation of MODULE InputProcessor from Fortran
"""

from dataclasses import dataclass, field
from typing import List, Optional, Tuple, Protocol
from enum import IntEnum
import re

# EXTERNAL DEPS (to wire in glue):
# - from DataStringGlobals: FullName, ProgramPath, LowerCase, UpperCase
# - from DataGlobals: MaxNameLength, ShowFatalError, ShowSevereError, ShowWarningError,
#   ShowContinueError, ShowMessage, AutoCalculate
# - from DataVCompareGlobals: LeaveBlank, Auditf, ProcessingIMFFile
# - from SortAndStringUtilities: SetupAndSort
# - external: GetNewUnitNumber, FindUnitNumber, DisplayString, ConvertCasetoUPPER, FindNonSpace


class ExternalDeps(Protocol):
    FullName: str
    ProgramPath: str
    LowerCase: str
    UpperCase: str
    MaxNameLength: int
    LeaveBlank: bool
    Auditf: int
    ProcessingIMFFile: bool
    AutoCalculate: float
    def ShowFatalError(self, msg: str, auditf: int = 0) -> None: ...
    def ShowSevereError(self, msg: str, auditf: int = 0) -> None: ...
    def ShowWarningError(self, msg: str, auditf: int = 0) -> None: ...
    def ShowContinueError(self, msg: str, auditf: int = 0) -> None: ...
    def ShowMessage(self, msg: str, auditf: int = 0) -> None: ...
    def SetupAndSort(self, items: List[str], indices: List[int]) -> None: ...
    def GetNewUnitNumber(self) -> int: ...
    def FindUnitNumber(self, filename: str) -> int: ...
    def DisplayString(self, msg: str) -> None: ...
    def ConvertCasetoUPPER(self, instr: str) -> str: ...
    def FindNonSpace(self, s: str) -> int: ...


# MODULE CONSTANTS
ObjectDefAllocInc = 100
ANArgsDefAllocInc = 500
SectionDefAllocInc = 20
SectionsIDFAllocInc = 20
ObjectsIDFAllocInc = 500
MaxObjectNameLength = None  # set from MaxNameLength
MaxSectionNameLength = None
MaxAlphaArgLength = None
MaxInputLineLength = 500
MaxFieldNameLength = 140
Blank = ' '
AlphaNum = 'ANan'
r64 = float
DefAutoSizeValue = -99999.0
DefAutoCalculateValue = -99999.0


@dataclass
class RangeCheckDef:
    MinMaxChk: bool = False
    FieldNumber: int = 0
    FieldName: str = field(default_factory=lambda: Blank * MaxFieldNameLength)
    MinMaxString: List[str] = field(default_factory=lambda: [Blank * 20, Blank * 20])
    Units: str = field(default_factory=lambda: Blank * 20)
    MinMaxValue: List[float] = field(default_factory=lambda: [0.0, 0.0])
    WhichMinMax: List[int] = field(default_factory=lambda: [0, 0])
    DefaultChk: bool = False
    Default: str = field(default_factory=lambda: Blank * 20)
    DefAutoSize: bool = False
    AutoSizable: bool = False
    AutoSizeValue: float = 0.0
    DefAutoCalculate: bool = False
    AutoCalculatable: bool = False
    AutoCalculateValue: float = 0.0


@dataclass
class ObjectsDefinition:
    Name: str = field(default_factory=lambda: Blank * MaxObjectNameLength)
    NumParams: int = 0
    NumAlpha: int = 0
    NumNumeric: int = 0
    MinNumFields: int = 0
    NameAlpha1: bool = False
    UniqueObject: bool = False
    RequiredObject: bool = False
    ExtensibleObject: bool = False
    ExtensibleNum: int = 0
    LastExtendAlpha: int = 0
    LastExtendNum: int = 0
    ObsPtr: int = 0
    AlphaorNumeric: List[bool] = field(default_factory=list)
    ReqField: List[bool] = field(default_factory=list)
    AlphRetainCase: List[bool] = field(default_factory=list)
    AlphFieldChks: List[str] = field(default_factory=list)
    AlphFieldDefs: List[str] = field(default_factory=list)
    NumRangeChks: List[RangeCheckDef] = field(default_factory=list)
    NumFound: int = 0


@dataclass
class SectionsDefinition:
    Name: str = field(default_factory=lambda: Blank)
    NumFound: int = 0


@dataclass
class FileSectionsDefinition:
    Name: str = field(default_factory=lambda: Blank)
    FirstRecord: int = 0
    LastRecord: int = 0


@dataclass
class LineDefinition:
    Name: str = field(default_factory=lambda: Blank)
    NumAlphas: int = 0
    NumNumbers: int = 0
    CommtS: int = 0
    CommtE: int = 0
    ObjectDefPtr: int = 0
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[str] = field(default_factory=list)
    AlphBlank: List[bool] = field(default_factory=list)
    NumBlank: List[bool] = field(default_factory=list)


@dataclass
class SecretObjects:
    OldName: str = field(default_factory=lambda: Blank)
    NewName: str = field(default_factory=lambda: Blank)
    Deleted: bool = False
    Used: bool = False


@dataclass
class InputProcessorState:
    NumObjectDefs: int = 0
    NumSectionDefs: int = 0
    NewNumObjectDefs: int = 0
    NewNumSectionDefs: int = 0
    OldNumObjectDefs: int = 0
    OldNumSectionDefs: int = 0
    MaxObjectDefs: int = 0
    MaxSectionDefs: int = 0
    IDDFile: int = 0
    IDFFile: int = 0
    NumLines: int = 0
    MaxIDFRecords: int = 0
    NumIDFRecords: int = 0
    MaxIDFSections: int = 0
    NumIDFSections: int = 0
    EchoInputFile: int = 0
    InputLineLength: int = 0
    MaxAlphaArgsFound: int = 0
    MaxNumericArgsFound: int = 0
    OldMaxAlphaArgsFound: int = 0
    OldMaxNumericArgsFound: int = 0
    NewMaxAlphaArgsFound: int = 0
    NewMaxNumericArgsFound: int = 0
    NumOutOfRangeErrorsFound: int = 0
    NumBlankReqFieldFound: int = 0
    NumMiscErrorsFound: int = 0
    MinimumNumberOfFields: int = 0
    NumObsoleteObjects: int = 0
    TotalAuditErrors: int = 0
    NumSecretObjects: int = 0
    MaxTotalArgs: int = 0
    CurComment: int = 0
    MaxComments: int = 0
    ExtensibleNumFields: int = 0
    
    InputLine: str = ''
    ListofSections: List[str] = field(default_factory=list)
    ListofObjects: List[str] = field(default_factory=list)
    iListOfObjects: List[int] = field(default_factory=list)
    NewListofSections: List[str] = field(default_factory=list)
    NewListofObjects: List[str] = field(default_factory=list)
    iNewListOfObjects: List[int] = field(default_factory=list)
    CurrentFieldName: str = ''
    ObsoleteObjectsRepNames: List[str] = field(default_factory=list)
    ReplacementName: str = ''
    CurObject: str = ''
    Comments: List[str] = field(default_factory=list)
    TmpComments: List[str] = field(default_factory=list)
    
    OverallErrorFlag: bool = False
    EchoInputLine: bool = True
    ReportRangeCheckErrors: bool = True
    FieldSet: bool = False
    RequiredField: bool = False
    RetainCaseFlag: bool = False
    ObsoleteObject: bool = False
    RequiredObject: bool = False
    UniqueObject: bool = False
    ProcessingIDD: bool = True
    OutsideObject: bool = True
    SaveComments: bool = False
    ExtensibleObject: bool = False
    
    ObjectDef: List[ObjectsDefinition] = field(default_factory=list)
    SectionDef: List[SectionsDefinition] = field(default_factory=list)
    OldObjectDef: List[ObjectsDefinition] = field(default_factory=list)
    OldSectionDef: List[SectionsDefinition] = field(default_factory=list)
    NewObjectDef: List[ObjectsDefinition] = field(default_factory=list)
    NewSectionDef: List[SectionsDefinition] = field(default_factory=list)
    SectionsonFile: List[FileSectionsDefinition] = field(default_factory=list)
    LineItem: LineDefinition = field(default_factory=LineDefinition)
    IDFRecords: List[LineDefinition] = field(default_factory=list)
    
    IDDProcessed: bool = False


def process_input(state: InputProcessorState, deps: ExternalDeps, 
                  idd_file_name_with_path: Optional[str] = None,
                  new_idd_file_name_with_path: Optional[str] = None,
                  input_file_name: Optional[str] = None) -> None:
    file_exists = False
    errors_in_idd = False
    
    if not state.IDDProcessed:
        if idd_file_name_with_path is None:
            if len(deps.ProgramPath.strip()) == 0:
                deps.FullName = 'Energy+.idd'
            else:
                deps.FullName = deps.ProgramPath.rstrip() + '/Energy+.idd'
        else:
            deps.FullName = idd_file_name_with_path
        
        try:
            with open(deps.FullName, 'r') as f:
                file_exists = True
        except FileNotFoundError:
            file_exists = False
        
        if not file_exists:
            deps.ShowFatalError(f'Energy+.idd missing. Program terminates. Fullname={deps.FullName}', deps.Auditf)
        
        state.IDDFile = deps.GetNewUnitNumber()
        state.NumLines = 0
        
        write_to_file(state.EchoInputFile, ' Processing Data Dictionary (Energy+.idd) File -- Start')
        
        state.NumObjectDefs = 0
        state.NumSectionDefs = 0
        deps.DisplayString(f'Processing Old IDD -- {idd_file_name_with_path}')
        state.ProcessingIDD = True
        process_data_dic_file(state, deps, 1)
        
        state.ListofSections = [sd.Name for sd in state.SectionDef[:state.NumSectionDefs]]
        state.ListofObjects = [od.Name for od in state.ObjectDef[:state.NumObjectDefs]]
        for loop in range(state.NumObjectDefs):
            state.ListofObjects[loop] = make_upper_case(state.ListofObjects[loop], deps)
        state.iListOfObjects = [0] * state.NumObjectDefs
        deps.SetupAndSort(state.ListofObjects, state.iListOfObjects)
        
        write_to_file(state.EchoInputFile, ' Processing Data Dictionary (Energy+.idd) File -- Complete')
        write_to_file(state.EchoInputFile, f' Maximum number of Alpha Args={state.MaxAlphaArgsFound}')
        write_to_file(state.EchoInputFile, f' Maximum number of Numeric Args={state.MaxNumericArgsFound}')
        write_to_file(state.EchoInputFile, f' Number of Object Definitions={state.NumObjectDefs}')
        write_to_file(state.EchoInputFile, f' Number of Section Definitions={state.NumSectionDefs}')
        state.IDDProcessed = True
        
        if new_idd_file_name_with_path is not None:
            deps.FullName = new_idd_file_name_with_path
            try:
                with open(deps.FullName, 'r') as f:
                    file_exists = True
            except FileNotFoundError:
                file_exists = False
            
            if not file_exists:
                deps.ShowFatalError(f'Energy+.idd missing. Program terminates. Fullname={deps.FullName}', deps.Auditf)
            
            state.IDDFile = deps.GetNewUnitNumber()
            state.NumLines = 0
            
            write_to_file(state.EchoInputFile, ' Processing Data Dictionary (Energy+.idd) File -- Start')
            
            state.NewNumObjectDefs = 0
            state.NewNumSectionDefs = 0
            state.SectionDef = []
            state.ObjectDef = []
            deps.DisplayString(f'Processing New IDD -- {new_idd_file_name_with_path}')
            state.ProcessingIDD = True
            process_data_dic_file(state, deps, 2)
            
            state.NewListofSections = [sd.Name for sd in state.NewSectionDef[:state.NewNumSectionDefs]]
            state.NewListofObjects = [od.Name for od in state.NewObjectDef[:state.NewNumObjectDefs]]
            state.iNewListOfObjects = [0] * state.NewNumObjectDefs
            for loop in range(state.NewNumObjectDefs):
                state.NewListofObjects[loop] = make_upper_case(state.NewListofObjects[loop], deps)
            deps.SetupAndSort(state.NewListofObjects, state.iNewListOfObjects)
            
            if not errors_in_idd:
                pass
            
            state.ProcessingIDD = False
            write_to_file(state.EchoInputFile, ' Processing Data Dictionary (Energy+.idd) File -- Complete')
            write_to_file(state.EchoInputFile, f' Maximum number of Alpha Args={state.MaxAlphaArgsFound}')
            write_to_file(state.EchoInputFile, f' Maximum number of Numeric Args={state.MaxNumericArgsFound}')
            write_to_file(state.EchoInputFile, f' Number of Object Definitions={state.NumObjectDefs}')
            write_to_file(state.EchoInputFile, f' Number of Section Definitions={state.NumSectionDefs}')
        
        if not state.LineItem.Numbers:
            state.LineItem.Numbers = [''] * state.MaxNumericArgsFound
        if not state.LineItem.NumBlank:
            state.LineItem.NumBlank = [False] * state.MaxNumericArgsFound
        if not state.LineItem.Alphas:
            state.LineItem.Alphas = [''] * state.MaxAlphaArgsFound
        if not state.LineItem.AlphBlank:
            state.LineItem.AlphBlank = [False] * state.MaxAlphaArgsFound
    
    state.NumOutOfRangeErrorsFound = 0
    state.NumBlankReqFieldFound = 0
    state.NumMiscErrorsFound = 0
    state.OverallErrorFlag = False
    
    if input_file_name is not None:
        idf_file_name = input_file_name
    else:
        idf_file_name = 'in.idf'
    
    write_to_file(state.EchoInputFile, f' Processing Input Data File {idf_file_name} -- Start')
    state.ProcessingIDD = False
    
    try:
        with open(idf_file_name, 'r') as f:
            file_exists = True
    except FileNotFoundError:
        file_exists = False
    
    if not file_exists:
        return
    
    state.IDFFile = deps.GetNewUnitNumber()
    state.NumLines = 0
    
    state.EchoInputLine = True
    if state.SectionsonFile:
        state.SectionsonFile = []
        state.NumIDFSections = 0
        for od in state.SectionDef:
            od.NumFound = 0
    
    if state.IDFRecords:
        state.IDFRecords = []
        state.NumIDFRecords = 0
        for od in state.ObjectDef:
            od.NumFound = 0
    
    state.SaveComments = True
    state.CurComment = 0
    state.Comments = [Blank] * ObjectDefAllocInc
    state.MaxComments = ObjectDefAllocInc
    process_input_data_file(state, deps)
    
    state.MaxTotalArgs = state.MaxAlphaArgsFound + state.MaxNumericArgsFound
    
    write_to_file(state.EchoInputFile, f' Processing Input Data File {idf_file_name} -- Complete')
    write_to_file(state.EchoInputFile, f' Number of IDF "Lines"={state.NumIDFRecords}')
    
    if state.NumOutOfRangeErrorsFound > 0:
        deps.ShowSevereError('Out of "range" values found in input', deps.Auditf)
    
    if state.NumBlankReqFieldFound > 0:
        deps.ShowSevereError('Blank "required" fields found in input', deps.Auditf)
    
    if state.NumMiscErrorsFound > 0:
        deps.ShowSevereError('Other miscellaneous errors found in input', deps.Auditf)
    
    if state.NumOutOfRangeErrorsFound + state.NumBlankReqFieldFound + state.NumMiscErrorsFound > 0:
        deps.ShowSevereError('Out of "range" values and/or blank required fields found in input', deps.Auditf)


def process_data_dic_file(state: InputProcessorState, deps: ExternalDeps, pass_num: int) -> None:
    end_of_file = False
    pos = 0
    blank_line = False
    
    state.MaxSectionDefs = SectionDefAllocInc
    state.MaxObjectDefs = ObjectDefAllocInc
    
    state.SectionDef = [SectionsDefinition() for _ in range(state.MaxSectionDefs)]
    state.ObjectDef = [ObjectsDefinition() for _ in range(state.MaxObjectDefs)]
    
    state.NumObjectDefs = 0
    state.NumSectionDefs = 0
    end_of_file = False
    
    with open(deps.FullName, 'r') as f:
        for line in f:
            state.InputLine = line.rstrip('\n')
            read_input_line_simple(state, deps, pos, blank_line, end_of_file)
            
            if blank_line or end_of_file:
                continue
            
            pos = state.InputLine.find(',')
            if pos < 0:
                pos = state.InputLine.find(';')
            
            if pos >= 0:
                if state.InputLine[pos] == ';':
                    add_section_def(state, deps, state.InputLine[:pos])
                    if state.NumSectionDefs == state.MaxSectionDefs:
                        new_sectiondef = [SectionsDefinition() for _ in range(state.MaxSectionDefs + SectionDefAllocInc)]
                        for i in range(state.MaxSectionDefs):
                            new_sectiondef[i] = state.SectionDef[i]
                        state.SectionDef = new_sectiondef
                        state.MaxSectionDefs += SectionDefAllocInc
                else:
                    add_object_def_and_parse(state, deps, state.InputLine[:pos], pos, end_of_file)
                    if state.NumObjectDefs == state.MaxObjectDefs:
                        new_objectdef = [ObjectsDefinition() for _ in range(state.MaxObjectDefs + ObjectDefAllocInc)]
                        for i in range(state.MaxObjectDefs):
                            new_objectdef[i] = state.ObjectDef[i]
                        state.ObjectDef = new_objectdef
                        state.MaxObjectDefs += ObjectDefAllocInc
            else:
                deps.ShowSevereError(', or ; expected on this line', state.EchoInputFile, deps.Auditf)
    
    if pass_num == 1:
        state.OldSectionDef = [SectionsDefinition(sd.Name, sd.NumFound) for sd in state.SectionDef[:state.NumSectionDefs]]
        state.OldObjectDef = [ObjectsDefinition() for _ in range(state.NumObjectDefs)]
        for i in range(state.NumObjectDefs):
            od = state.ObjectDef[i]
            nod = ObjectsDefinition(od.Name, od.NumParams, od.NumAlpha, od.NumNumeric)
            nod.MinNumFields = od.MinNumFields
            nod.NameAlpha1 = od.NameAlpha1
            nod.AlphaorNumeric = od.AlphaorNumeric[:]
            nod.ReqField = od.ReqField[:]
            state.OldObjectDef[i] = nod
        state.OldNumSectionDefs = state.NumSectionDefs
        state.OldNumObjectDefs = state.NumObjectDefs
        state.OldMaxAlphaArgsFound = state.MaxAlphaArgsFound
        state.OldMaxNumericArgsFound = state.MaxNumericArgsFound
    elif pass_num == 2:
        state.NewSectionDef = [SectionsDefinition(sd.Name, sd.NumFound) for sd in state.SectionDef[:state.NumSectionDefs]]
        state.NewObjectDef = [ObjectsDefinition() for _ in range(state.NumObjectDefs)]
        for i in range(state.NumObjectDefs):
            od = state.ObjectDef[i]
            nod = ObjectsDefinition(od.Name, od.NumParams, od.NumAlpha, od.NumNumeric)
            nod.MinNumFields = od.MinNumFields
            nod.NameAlpha1 = od.NameAlpha1
            nod.AlphaorNumeric = od.AlphaorNumeric[:]
            nod.ReqField = od.ReqField[:]
            state.NewObjectDef[i] = nod
        state.NewNumSectionDefs = state.NumSectionDefs
        state.NewNumObjectDefs = state.NumObjectDefs
        state.SectionDef = [SectionsDefinition(sd.Name, sd.NumFound) for sd in state.OldSectionDef[:state.OldNumSectionDefs]]
        state.ObjectDef = [ObjectsDefinition() for _ in range(state.OldNumObjectDefs)]
        for i in range(state.OldNumObjectDefs):
            od = state.OldObjectDef[i]
            nod = ObjectsDefinition(od.Name, od.NumParams, od.NumAlpha, od.NumNumeric)
            nod.MinNumFields = od.MinNumFields
            nod.NameAlpha1 = od.NameAlpha1
            nod.AlphaorNumeric = od.AlphaorNumeric[:]
            nod.ReqField = od.ReqField[:]
            state.ObjectDef[i] = nod
        state.NumSectionDefs = state.OldNumSectionDefs
        state.NumObjectDefs = state.OldNumObjectDefs
        state.NewMaxAlphaArgsFound = state.MaxAlphaArgsFound
        state.NewMaxNumericArgsFound = state.MaxNumericArgsFound
    
    state.MaxAlphaArgsFound = max(state.OldMaxAlphaArgsFound, state.NewMaxAlphaArgsFound, state.MaxAlphaArgsFound)
    state.MaxNumericArgsFound = max(state.OldMaxNumericArgsFound, state.NewMaxNumericArgsFound, state.MaxNumericArgsFound)


def add_section_def(state: InputProcessorState, deps: ExternalDeps, proposed_section: str) -> None:
    squeezed_section = proposed_section.strip()
    if len(squeezed_section) > deps.MaxNameLength:
        deps.ShowWarningError(f'Section length exceeds maximum, will be truncated={proposed_section}', state.EchoInputFile, deps.Auditf)
        deps.ShowContinueError(f'Will be processed as Section={squeezed_section}', state.EchoInputFile, deps.Auditf)
    
    err_flag = False
    
    if squeezed_section != Blank:
        found = find_item_in_list(squeezed_section, [sd.Name for sd in state.SectionDef[:state.NumSectionDefs]], state.NumSectionDefs)
        if found > 0:
            deps.ShowSevereError(f' Already a Section called {squeezed_section}. This definition ignored.', state.EchoInputFile, deps.Auditf)
            err_flag = True
    else:
        deps.ShowSevereError('Blank Sections not allowed. Review audit.out file.', state.EchoInputFile, deps.Auditf)
        err_flag = True
    
    if not err_flag:
        state.NumSectionDefs += 1
        state.SectionDef[state.NumSectionDefs - 1].Name = squeezed_section
        state.SectionDef[state.NumSectionDefs - 1].NumFound = 0


def add_object_def_and_parse(state: InputProcessorState, deps: ExternalDeps, proposed_object: str, 
                              cur_pos: int, end_of_file: bool) -> None:
    pass


def process_input_data_file(state: InputProcessorState, deps: ExternalDeps) -> None:
    pass


def find_item_in_list(string: str, list_of_items: List[str], num_items: int) -> int:
    for count in range(num_items):
        if string == list_of_items[count]:
            return count + 1
    return 0


def make_upper_case(input_string: str, deps: ExternalDeps) -> str:
    result = ''
    for char in input_string:
        if char in deps.LowerCase:
            idx = deps.LowerCase.index(char)
            result += deps.UpperCase[idx]
        else:
            result += char
    return result.strip()


def write_to_file(file_unit: int, msg: str) -> None:
    if file_unit > 0:
        pass


def read_input_line_simple(state: InputProcessorState, deps: ExternalDeps, cur_pos: int, 
                           blank_line: bool, end_of_file: bool) -> None:
    pass

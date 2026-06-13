# EXTERNAL DEPS (to wire in glue):
# - MAX_NAME_LENGTH: from DataGlobals module

try:
    from data_globals import MAX_NAME_LENGTH
except ImportError:
    MAX_NAME_LENGTH = 32

from dataclasses import dataclass, field
from typing import Optional, List

SIZEOFAPPNAME = 100

MISMATCH_UNITS = 8
DIFF_NUM_PARAMS = 1
MISMATCH_FIELDS = 4
MISMATCH_ARGS = 2

DIFF_INDEX = [
    DIFF_NUM_PARAMS,
    MISMATCH_ARGS,
    MISMATCH_FIELDS,
    MISMATCH_UNITS,
    MISMATCH_FIELDS + MISMATCH_UNITS,
    DIFF_NUM_PARAMS + MISMATCH_FIELDS,
    DIFF_NUM_PARAMS + MISMATCH_UNITS,
    DIFF_NUM_PARAMS + MISMATCH_UNITS + MISMATCH_FIELDS
]

DIFF_DESCRIPTION = [
    "<unknown>                          ",
    "Diff # Fields                      ",
    "Arg Type (A-N) Mismatch            ",
    "Field Name Change                  ",
    "Units Change                       ",
    "Units Chg+Field Name Chg           ",
    "#Fields+Field Name Chg             ",
    "#Fields+Units Change               ",
    "#Fields+Field Name Chg+Units Change"
]

@dataclass
class ObjectStatus:
    Name: str = ' '
    Same: bool = True
    StatusFlag: int = 0
    OldIndex: int = 0
    NewIndex: int = 0
    UnitsMatched: bool = False
    FieldNameMatch: Optional[List[bool]] = field(default=None)
    UnitsMatch: Optional[List[str]] = field(default=None)

ghInstance: int = 0
ghModule: int = 0
ghwndMain: int = 0
ghMenu: int = 0

FullFileName: str = ""
FileNamePath: str = ""
FullFileNameLength: int = 0
FileNamePathLength: int = 0
FileErrorMessage: str = ""
FileOK: bool = False
CurWorkDir: str = ""
IDDFileNameWithPath: str = ""
NewIDDFileNameWithPath: str = ""
withUnits: bool = False
LeaveBlank: bool = False
auditf: int = 0
VersionNum: float = 0.0

ObjStatus: Optional[List[ObjectStatus]] = None
NumObjStats: int = 0
NotInNew: Optional[List[str]] = None
NotInOld: Optional[List[str]] = None
ObsObject: Optional[List[str]] = None
ObsObjRepName: Optional[List[str]] = None
NumObsObjs: int = 0
NNew: int = 0
NOld: int = 0
NumDif: int = 0
FldNames: Optional[List[str]] = None
FldDefaults: Optional[List[str]] = None
FldUnits: Optional[List[str]] = None
ObjMinFlds: int = 0
AOrN: Optional[List[bool]] = None
ReqFld: Optional[List[bool]] = None
NumArgs: int = 0
NwFldNames: Optional[List[str]] = None
NwFldDefaults: Optional[List[str]] = None
NwFldUnits: Optional[List[str]] = None
NwObjMinFlds: int = 0
NwAOrN: Optional[List[bool]] = None
NwReqFld: Optional[List[bool]] = None
NwNumArgs: int = 0
Alphas: Optional[List[str]] = None
Numbers: Optional[List[str]] = None
NumAlphas: int = 0
NumNumbers: int = 0
OutArgs: Optional[List[str]] = None
MatchArg: Optional[List[int]] = None
InArgs: Optional[List[str]] = None
TempArgs: Optional[List[str]] = None

OldRepVarName: Optional[List[str]] = None
NewRepVarName: Optional[List[str]] = None
NewRepVarCaution: Optional[List[str]] = None
OutVarCaution: Optional[List[bool]] = None
MtrVarCaution: Optional[List[bool]] = None
TimeBinVarCaution: Optional[List[bool]] = None
OTMVarCaution: Optional[List[bool]] = None
NumRepVarNames: int = 0

MakingPretty: bool = False
ObjectFoundCounts: Optional[List[int]] = None
ObjectFoundFile: Optional[List[str]] = None
ReportNames: Optional[List[str]] = None
ReportNamesCounts: Optional[List[int]] = None
ReportNameFile: Optional[List[str]] = None
TmpReportNames: Optional[List[str]] = None
TmpReportNamesCounts: Optional[List[int]] = None
NumReportNames: int = 0
MaxReportNames: int = 0

InputFilePath: str = ""
UseInputFilePath: bool = False
ProcessingIMFFile: bool = False

OldObjectNames: Optional[List[str]] = None
NewObjectNames: Optional[List[str]] = None
NumRenamedObjects: int = 0

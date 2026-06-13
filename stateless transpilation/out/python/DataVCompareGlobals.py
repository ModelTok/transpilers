# EXTERNAL DEPS (to wire in glue):
# MaxNameLength - from DataGlobals

from dataclasses import dataclass, field
from typing import List

MaxNameLength = 255

SIZEOFAPPNAME: int = 100

MisMatchUnits: int = 8
DiffNumParams: int = 1
MisMatchFields: int = 4
MisMatchArgs: int = 2

DiffIndex: List[int] = [
    DiffNumParams,
    MisMatchArgs,
    MisMatchFields,
    MisMatchUnits,
    MisMatchFields + MisMatchUnits,
    DiffNumParams + MisMatchFields,
    DiffNumParams + MisMatchUnits,
    DiffNumParams + MisMatchUnits + MisMatchFields
]

DiffDescription: List[str] = [
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
    FieldNameMatch: List[bool] = field(default_factory=list)
    UnitsMatch: List[str] = field(default_factory=list)


@dataclass
class DataVCompareGlobalsState:
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
    RepVarFileNameWithPath: str = ""
    
    withUnits: bool = False
    LeaveBlank: bool = False
    auditf: int = 0
    VersionNum: float = 0.0
    sVersionNum: str = ""
    sVersionNumFourChars: str = ""
    
    ObjStatus: List[ObjectStatus] = field(default_factory=list)
    NumObjStats: int = 0
    NotInNew: List[str] = field(default_factory=list)
    NotInOld: List[str] = field(default_factory=list)
    ObsObject: List[str] = field(default_factory=list)
    ObsObjRepName: List[str] = field(default_factory=list)
    NumObsObjs: int = 0
    NNew: int = 0
    NOld: int = 0
    NumDif: int = 0
    FldNames: List[str] = field(default_factory=list)
    FldDefaults: List[str] = field(default_factory=list)
    FldUnits: List[str] = field(default_factory=list)
    ObjMinFlds: int = 0
    AOrN: List[bool] = field(default_factory=list)
    ReqFld: List[bool] = field(default_factory=list)
    NumArgs: int = 0
    NwFldNames: List[str] = field(default_factory=list)
    NwFldDefaults: List[str] = field(default_factory=list)
    NwFldUnits: List[str] = field(default_factory=list)
    NwObjMinFlds: int = 0
    NwAOrN: List[bool] = field(default_factory=list)
    NwReqFld: List[bool] = field(default_factory=list)
    NwNumArgs: int = 0
    Alphas: List[str] = field(default_factory=list)
    Numbers: List[str] = field(default_factory=list)
    NumAlphas: int = 0
    NumNumbers: int = 0
    OutArgs: List[str] = field(default_factory=list)
    MatchArg: List[int] = field(default_factory=list)
    InArgs: List[str] = field(default_factory=list)
    TempArgs: List[str] = field(default_factory=list)
    
    OldRepVarName: List[str] = field(default_factory=list)
    NewRepVarName: List[str] = field(default_factory=list)
    NewRepVarCaution: List[str] = field(default_factory=list)
    OutVarCaution: List[bool] = field(default_factory=list)
    MtrVarCaution: List[bool] = field(default_factory=list)
    TimeBinVarCaution: List[bool] = field(default_factory=list)
    OTMVarCaution: List[bool] = field(default_factory=list)
    CMtrVarCaution: List[bool] = field(default_factory=list)
    CMtrDVarCaution: List[bool] = field(default_factory=list)
    NumRepVarNames: int = 0
    
    MakingPretty: bool = False
    ObjectFoundCounts: List[int] = field(default_factory=list)
    ObjectFoundFile: List[str] = field(default_factory=list)
    ReportNames: List[str] = field(default_factory=list)
    ReportNamesCounts: List[int] = field(default_factory=list)
    ReportNameFile: List[str] = field(default_factory=list)
    TmpReportNames: List[str] = field(default_factory=list)
    TmpReportNamesCounts: List[int] = field(default_factory=list)
    NumReportNames: int = 0
    MaxReportNames: int = 0
    
    InputFilePath: str = ""
    UseInputFilePath: bool = False
    ProcessingIMFFile: bool = False
    
    OldObjectNames: List[str] = field(default_factory=list)
    NewObjectNames: List[str] = field(default_factory=list)
    NumRenamedObjects: int = 0
    
    NumChillers: int = 0
    numChillerHeaters: int = 0
    CondFDVariables: bool = False

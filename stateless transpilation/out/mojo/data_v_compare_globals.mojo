# EXTERNAL DEPS (to wire in glue):
# MaxNameLength - from DataGlobals

alias SIZEOFAPPNAME = 100

alias MisMatchUnits = 8
alias DiffNumParams = 1
alias MisMatchFields = 4
alias MisMatchArgs = 2

alias MaxNameLength = 255


fn _make_diff_index() -> List[Int]:
    var result = List[Int]()
    result.append(DiffNumParams)
    result.append(MisMatchArgs)
    result.append(MisMatchFields)
    result.append(MisMatchUnits)
    result.append(MisMatchFields + MisMatchUnits)
    result.append(DiffNumParams + MisMatchFields)
    result.append(DiffNumParams + MisMatchUnits)
    result.append(DiffNumParams + MisMatchUnits + MisMatchFields)
    return result


fn _make_diff_description() -> List[String]:
    var result = List[String]()
    result.append("<unknown>                          ")
    result.append("Diff # Fields                      ")
    result.append("Arg Type (A-N) Mismatch            ")
    result.append("Field Name Change                  ")
    result.append("Units Change                       ")
    result.append("Units Chg+Field Name Chg           ")
    result.append("#Fields+Field Name Chg             ")
    result.append("#Fields+Units Change               ")
    result.append("#Fields+Field Name Chg+Units Change")
    return result


var DiffIndex = _make_diff_index()
var DiffDescription = _make_diff_description()


struct ObjectStatus:
    var Name: String
    var Same: Bool
    var StatusFlag: Int
    var OldIndex: Int
    var NewIndex: Int
    var UnitsMatched: Bool
    var FieldNameMatch: List[Bool]
    var UnitsMatch: List[String]
    
    fn __init__(inout self):
        self.Name = " "
        self.Same = True
        self.StatusFlag = 0
        self.OldIndex = 0
        self.NewIndex = 0
        self.UnitsMatched = False
        self.FieldNameMatch = List[Bool]()
        self.UnitsMatch = List[String]()


struct DataVCompareGlobalsState:
    var ghInstance: Int
    var ghModule: Int
    var ghwndMain: Int
    var ghMenu: Int
    
    var FullFileName: String
    var FileNamePath: String
    var FullFileNameLength: Int
    var FileNamePathLength: Int
    var FileErrorMessage: String
    var FileOK: Bool
    var CurWorkDir: String
    var IDDFileNameWithPath: String
    var NewIDDFileNameWithPath: String
    var RepVarFileNameWithPath: String
    
    var withUnits: Bool
    var LeaveBlank: Bool
    var auditf: Int
    var VersionNum: Float32
    var sVersionNum: String
    var sVersionNumFourChars: String
    
    var ObjStatus: List[ObjectStatus]
    var NumObjStats: Int
    var NotInNew: List[String]
    var NotInOld: List[String]
    var ObsObject: List[String]
    var ObsObjRepName: List[String]
    var NumObsObjs: Int
    var NNew: Int
    var NOld: Int
    var NumDif: Int
    var FldNames: List[String]
    var FldDefaults: List[String]
    var FldUnits: List[String]
    var ObjMinFlds: Int
    var AOrN: List[Bool]
    var ReqFld: List[Bool]
    var NumArgs: Int
    var NwFldNames: List[String]
    var NwFldDefaults: List[String]
    var NwFldUnits: List[String]
    var NwObjMinFlds: Int
    var NwAOrN: List[Bool]
    var NwReqFld: List[Bool]
    var NwNumArgs: Int
    var Alphas: List[String]
    var Numbers: List[String]
    var NumAlphas: Int
    var NumNumbers: Int
    var OutArgs: List[String]
    var MatchArg: List[Int]
    var InArgs: List[String]
    var TempArgs: List[String]
    
    var OldRepVarName: List[String]
    var NewRepVarName: List[String]
    var NewRepVarCaution: List[String]
    var OutVarCaution: List[Bool]
    var MtrVarCaution: List[Bool]
    var TimeBinVarCaution: List[Bool]
    var OTMVarCaution: List[Bool]
    var CMtrVarCaution: List[Bool]
    var CMtrDVarCaution: List[Bool]
    var NumRepVarNames: Int
    
    var MakingPretty: Bool
    var ObjectFoundCounts: List[Int]
    var ObjectFoundFile: List[String]
    var ReportNames: List[String]
    var ReportNamesCounts: List[Int]
    var ReportNameFile: List[String]
    var TmpReportNames: List[String]
    var TmpReportNamesCounts: List[Int]
    var NumReportNames: Int
    var MaxReportNames: Int
    
    var InputFilePath: String
    var UseInputFilePath: Bool
    var ProcessingIMFFile: Bool
    
    var OldObjectNames: List[String]
    var NewObjectNames: List[String]
    var NumRenamedObjects: Int
    
    var NumChillers: Int
    var numChillerHeaters: Int
    var CondFDVariables: Bool
    
    fn __init__(inout self):
        self.ghInstance = 0
        self.ghModule = 0
        self.ghwndMain = 0
        self.ghMenu = 0
        
        self.FullFileName = ""
        self.FileNamePath = ""
        self.FullFileNameLength = 0
        self.FileNamePathLength = 0
        self.FileErrorMessage = ""
        self.FileOK = False
        self.CurWorkDir = ""
        self.IDDFileNameWithPath = ""
        self.NewIDDFileNameWithPath = ""
        self.RepVarFileNameWithPath = ""
        
        self.withUnits = False
        self.LeaveBlank = False
        self.auditf = 0
        self.VersionNum = 0.0
        self.sVersionNum = ""
        self.sVersionNumFourChars = ""
        
        self.ObjStatus = List[ObjectStatus]()
        self.NumObjStats = 0
        self.NotInNew = List[String]()
        self.NotInOld = List[String]()
        self.ObsObject = List[String]()
        self.ObsObjRepName = List[String]()
        self.NumObsObjs = 0
        self.NNew = 0
        self.NOld = 0
        self.NumDif = 0
        self.FldNames = List[String]()
        self.FldDefaults = List[String]()
        self.FldUnits = List[String]()
        self.ObjMinFlds = 0
        self.AOrN = List[Bool]()
        self.ReqFld = List[Bool]()
        self.NumArgs = 0
        self.NwFldNames = List[String]()
        self.NwFldDefaults = List[String]()
        self.NwFldUnits = List[String]()
        self.NwObjMinFlds = 0
        self.NwAOrN = List[Bool]()
        self.NwReqFld = List[Bool]()
        self.NwNumArgs = 0
        self.Alphas = List[String]()
        self.Numbers = List[String]()
        self.NumAlphas = 0
        self.NumNumbers = 0
        self.OutArgs = List[String]()
        self.MatchArg = List[Int]()
        self.InArgs = List[String]()
        self.TempArgs = List[String]()
        
        self.OldRepVarName = List[String]()
        self.NewRepVarName = List[String]()
        self.NewRepVarCaution = List[String]()
        self.OutVarCaution = List[Bool]()
        self.MtrVarCaution = List[Bool]()
        self.TimeBinVarCaution = List[Bool]()
        self.OTMVarCaution = List[Bool]()
        self.CMtrVarCaution = List[Bool]()
        self.CMtrDVarCaution = List[Bool]()
        self.NumRepVarNames = 0
        
        self.MakingPretty = False
        self.ObjectFoundCounts = List[Int]()
        self.ObjectFoundFile = List[String]()
        self.ReportNames = List[String]()
        self.ReportNamesCounts = List[Int]()
        self.ReportNameFile = List[String]()
        self.TmpReportNames = List[String]()
        self.TmpReportNamesCounts = List[Int]()
        self.NumReportNames = 0
        self.MaxReportNames = 0
        
        self.InputFilePath = ""
        self.UseInputFilePath = False
        self.ProcessingIMFFile = False
        
        self.OldObjectNames = List[String]()
        self.NewObjectNames = List[String]()
        self.NumRenamedObjects = 0
        
        self.NumChillers = 0
        self.numChillerHeaters = 0
        self.CondFDVariables = False

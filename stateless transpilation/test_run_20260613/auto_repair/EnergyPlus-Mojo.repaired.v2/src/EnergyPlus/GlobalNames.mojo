from Data.BaseData import BaseGlobalStruct
from .Data.EnergyPlusData import EnergyPlusData
from UtilityRoutines import ShowSevereError, ShowContinueError, makeUPPER

struct ComponentNameData:
    var CompType: String
    var CompName: String

    def __init__(inout self):

struct GlobalNamesData(BaseGlobalStruct):
    var NumChillers: Int = 0
    var NumBoilers: Int = 0
    var NumBaseboards: Int = 0
    var NumCoils: Int = 0
    var CurMaxChillers: Int = 0
    var CurMaxCoils: Int = 0
    var numAirDistUnits: Int = 0
    var ChillerNames: Dict[String, String] = Dict[String, String]()
    var BoilerNames: Dict[String, String] = Dict[String, String]()
    var BaseboardNames: Dict[String, String] = Dict[String, String]()
    var CoilNames: Dict[String, String] = Dict[String, String]()
    var aDUNames: Dict[String, String] = Dict[String, String]()

    def init_constant_state(inout state: EnergyPlusData):

    def init_state(inout state: EnergyPlusData):

    def clear_state(inout self):
        self.NumChillers = 0
        self.NumBoilers = 0
        self.NumBaseboards = 0
        self.NumCoils = 0
        self.CurMaxChillers = 0
        self.CurMaxCoils = 0
        self.numAirDistUnits = 0
        self.ChillerNames.clear()
        self.BoilerNames.clear()
        self.BaseboardNames.clear()
        self.CoilNames.clear()
        self.aDUNames.clear()

def IntraObjUniquenessCheck(inout state: EnergyPlusData, NameToVerify: String, CurrentModuleObject: String, FieldName: String, inout UniqueStrings: Set[String], inout ErrorsFound: Bool):
    if NameToVerify == "":
        ShowSevereError(state, f"E+ object type {CurrentModuleObject} cannot have a blank {FieldName} field")
        ErrorsFound = True
        return
    if NameToVerify in UniqueStrings:
        ErrorsFound = True
        ShowSevereError(state, f"{CurrentModuleObject} has a duplicate field {NameToVerify}")
    else:
        UniqueStrings.add(NameToVerify)

def VerifyUniqueInterObjectName(inout state: EnergyPlusData, inout names: Dict[String, String], object_name: String, object_type: String, field_name: String, inout ErrorsFound: Bool) -> Bool:
    if object_name == "":
        ShowSevereError(state, f"E+ object type {object_name} cannot have blank {field_name} field")
        ErrorsFound = True
        return True
    if object_name in names:
        let names_iter = names[object_name]
        ErrorsFound = True
        ShowSevereError(state, f"{object_name} with object type {object_type} duplicates a name in object type {names_iter}")
        return True
    else:
        names[object_name] = object_type
    return False

def VerifyUniqueInterObjectName(inout state: EnergyPlusData, inout names: Dict[String, String], object_name: String, object_type: String, inout ErrorsFound: Bool) -> Bool:
    if object_name == "":
        ShowSevereError(state, f"E+ object type {object_name} has a blank field")
        ErrorsFound = True
        return True
    if object_name in names:
        let names_iter = names[object_name]
        ErrorsFound = True
        ShowSevereError(state, f"{object_name} with object type {object_type} duplicates a name in object type {names_iter}")
        return True
    else:
        names[object_name] = object_type
    return False

def VerifyUniqueChillerName(inout state: EnergyPlusData, TypeToVerify: String, NameToVerify: String, inout ErrorsFound: Bool, StringToDisplay: String):
    if NameToVerify in state.dataGlobalNames.ChillerNames:
        let iter = state.dataGlobalNames.ChillerNames[NameToVerify]
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Chiller Type=\"{iter}\".")
        ShowContinueError(state, f"...Current entry is Chiller Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.ChillerNames[NameToVerify] = makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumChillers = Int(state.dataGlobalNames.ChillerNames.size())

def VerifyUniqueBaseboardName(inout state: EnergyPlusData, TypeToVerify: String, NameToVerify: String, inout ErrorsFound: Bool, StringToDisplay: String):
    if NameToVerify in state.dataGlobalNames.BaseboardNames:
        let iter = state.dataGlobalNames.BaseboardNames[NameToVerify]
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Baseboard Type=\"{iter}\".")
        ShowContinueError(state, f"...Current entry is Baseboard Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.BaseboardNames[NameToVerify] = makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumBaseboards = Int(state.dataGlobalNames.BaseboardNames.size())

def VerifyUniqueBoilerName(inout state: EnergyPlusData, TypeToVerify: String, NameToVerify: String, inout ErrorsFound: Bool, StringToDisplay: String):
    if NameToVerify in state.dataGlobalNames.BoilerNames:
        let iter = state.dataGlobalNames.BoilerNames[NameToVerify]
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Boiler Type=\"{iter}\".")
        ShowContinueError(state, f"...Current entry is Boiler Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.BoilerNames[NameToVerify] = makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumBoilers = Int(state.dataGlobalNames.BoilerNames.size())

def VerifyUniqueCoilName(inout state: EnergyPlusData, TypeToVerify: String, inout NameToVerify: String, inout ErrorsFound: Bool, StringToDisplay: String):
    if NameToVerify == "":
        ShowSevereError(state, f"\"{TypeToVerify}\" cannot have a blank field")
        ErrorsFound = True
        NameToVerify = "xxxxx"
        return
    if NameToVerify in state.dataGlobalNames.CoilNames:
        let iter = state.dataGlobalNames.CoilNames[NameToVerify]
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Coil Type=\"{iter}\".")
        ShowContinueError(state, f"...Current entry is Coil Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.CoilNames[NameToVerify] = makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumCoils = Int(state.dataGlobalNames.CoilNames.size())

def VerifyUniqueADUName(inout state: EnergyPlusData, TypeToVerify: String, NameToVerify: String, inout ErrorsFound: Bool, StringToDisplay: String):
    if NameToVerify in state.dataGlobalNames.aDUNames:
        let iter = state.dataGlobalNames.aDUNames[NameToVerify]
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, ADU Type=\"{iter}\".")
        ShowContinueError(state, f"...Current entry is Air Distribution Unit Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.aDUNames[NameToVerify] = makeUPPER(TypeToVerify)
        state.dataGlobalNames.numAirDistUnits = Int(state.dataGlobalNames.aDUNames.size())
from collections import Optional
from sys import sizeof

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with methods init_constant_state, init_state
#                   and attributes dataInputProcessing.inputProcessor, dataGlobal.errorCallback
# - EnergyPlus.Fluid.GetGlycol(state: EnergyPlusData, name: String) -> GlycolProps*
# - EnergyPlus.Fluid.GetRefrig(state: EnergyPlusData, name: String) -> RefrigProps*
# - EnergyPlus.Util.makeUPPER(s: String) -> String
# - EnergyPlus.Psychrometrics: PsyRhoAirFnPbTdbW_fast, PsyHfgAirFnWTdb, PsyHgAirFnWTdb,
#   PsyHFnTdbW_fast, PsyCpAirFnW, PsyTdbFnHW, PsyRhovFnTdbWPb_fast, PsyTwbFnTdbWPb,
#   PsyVFnTdbWPb, PsyWFnTdbH, PsyPsatFnTemp, PsyTsatFnHPb, PsyRhovFnTdbRh,
#   PsyRhFnTdbRhov, PsyRhFnTdbWPb, PsyWFnTdpPb, PsyWFnTdbRhPb, PsyWFnTdbTwbPb,
#   PsyHFnTdbRhPb, PsyTdpFnWPb, PsyTdpFnTdbTwbPb
# - EnergyPlus.DataStringGlobals.PythonAPIVersion: String
# - EnergyPlus.DataStringGlobals.VerString: String
# - EnergyPlus.InputProcessor.factory() -> InputProcessor*
# - EnergyPlus.Error: enum type

alias EnergyPlusState = UnsafePointer[UInt8]
alias Glycol = UnsafePointer[UInt8]
alias Refrigerant = UnsafePointer[UInt8]

struct GlycolProps:
    def getSpecificHeat(self, state: EnergyPlusState, temperature: Float64, source: String) -> Float64: ...
    def getDensity(self, state: EnergyPlusState, temperature: Float64, source: String) -> Float64: ...
    def getConductivity(self, state: EnergyPlusState, temperature: Float64, source: String) -> Float64: ...
    def getViscosity(self, state: EnergyPlusState, temperature: Float64, source: String) -> Float64: ...

struct RefrigProps:
    def getSatPressure(self, state: EnergyPlusState, temperature: Float64, source: String) -> Float64: ...
    def getSatTemperature(self, state: EnergyPlusState, pressure: Float64, source: String) -> Float64: ...
    def getSatEnthalpy(self, state: EnergyPlusState, temperature: Float64, quality: Float64, source: String) -> Float64: ...
    def getSatDensity(self, state: EnergyPlusState, temperature: Float64, quality: Float64, source: String) -> Float64: ...
    def getSatSpecificHeat(self, state: EnergyPlusState, temperature: Float64, quality: Float64, source: String) -> Float64: ...

struct DataInputProcessing:
    var inputProcessor: UnsafePointer[UInt8]

struct DataGlobal:
    var errorCallback: UnsafePointer[UInt8]

struct EnergyPlusData:
    var dataInputProcessing: DataInputProcessing
    var dataGlobal: DataGlobal
    
    fn init_constant_state(inout self) -> None: ...
    fn init_state(inout self) -> None: ...

fn initializeFunctionalAPI(state: EnergyPlusState) -> None:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    if not thisState[].dataInputProcessing.inputProcessor:
        thisState[].dataInputProcessing.inputProcessor = external_InputProcessor_factory()
    thisState[].init_constant_state()
    thisState[].init_state()

fn apiVersionFromEPlus(state: EnergyPlusState) -> StringRef:
    return external_DataStringGlobals_PythonAPIVersion()

fn energyPlusVersion() -> StringRef:
    return external_DataStringGlobals_VerString()

fn registerErrorCallback(state: EnergyPlusState, f: UnsafePointer[UInt8]) -> None:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    thisState[].dataGlobal.errorCallback = f

fn glycolNew(state: EnergyPlusState, glycolName: UnsafePointer[UInt8]) -> Glycol:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var name_str = StringRef(glycolName)
    var upper_name = external_Util_makeUPPER(name_str)
    var glycol = external_Fluid_GetGlycol(thisState, upper_name)
    return glycol.bitcast[UInt8]()

fn glycolDelete(state: EnergyPlusState, glycol: Glycol) -> None:
    pass

fn glycolSpecificHeat(state: EnergyPlusState, glycol: Glycol, temperature: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var glycol_ptr = UnsafePointer[GlycolProps](glycol.bitcast[GlycolProps]())
    return glycol_ptr[].getSpecificHeat(state, temperature, "C-API")

fn glycolDensity(state: EnergyPlusState, glycol: Glycol, temperature: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var glycol_ptr = UnsafePointer[GlycolProps](glycol.bitcast[GlycolProps]())
    return glycol_ptr[].getDensity(state, temperature, "C-API")

fn glycolConductivity(state: EnergyPlusState, glycol: Glycol, temperature: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var glycol_ptr = UnsafePointer[GlycolProps](glycol.bitcast[GlycolProps]())
    return glycol_ptr[].getConductivity(state, temperature, "C-API")

fn glycolViscosity(state: EnergyPlusState, glycol: Glycol, temperature: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var glycol_ptr = UnsafePointer[GlycolProps](glycol.bitcast[GlycolProps]())
    return glycol_ptr[].getViscosity(state, temperature, "C-API")

fn refrigerantNew(state: EnergyPlusState, refrigerantName: UnsafePointer[UInt8]) -> Refrigerant:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var name_str = StringRef(refrigerantName)
    var upper_name = external_Util_makeUPPER(name_str)
    var refrigerant = external_Fluid_GetRefrig(thisState, upper_name)
    return refrigerant.bitcast[UInt8]()

fn refrigerantDelete(state: EnergyPlusState, refrigerant: Refrigerant) -> None:
    pass

fn refrigerantSaturationPressure(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var refrig_ptr = UnsafePointer[RefrigProps](refrigerant.bitcast[RefrigProps]())
    return refrig_ptr[].getSatPressure(state, temperature, "C-API")

fn refrigerantSaturationTemperature(state: EnergyPlusState, refrigerant: Refrigerant, pressure: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var refrig_ptr = UnsafePointer[RefrigProps](refrigerant.bitcast[RefrigProps]())
    return refrig_ptr[].getSatTemperature(state, pressure, "C-API")

fn refrigerantSaturatedEnthalpy(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Float64, quality: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var refrig_ptr = UnsafePointer[RefrigProps](refrigerant.bitcast[RefrigProps]())
    return refrig_ptr[].getSatEnthalpy(state, temperature, quality, "C-API")

fn refrigerantSaturatedDensity(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Float64, quality: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var refrig_ptr = UnsafePointer[RefrigProps](refrigerant.bitcast[RefrigProps]())
    return refrig_ptr[].getSatDensity(state, temperature, quality, "C-API")

fn refrigerantSaturatedSpecificHeat(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Float64, quality: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    var refrig_ptr = UnsafePointer[RefrigProps](refrigerant.bitcast[RefrigProps]())
    return refrig_ptr[].getSatSpecificHeat(state, temperature, quality, "C-API")

fn psyRhoFnPbTdbW(state: EnergyPlusState, pb: Float64, tdb: Float64, dw: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyRhoAirFnPbTdbW_fast(thisState, pb, tdb, dw)

fn psyHfgAirFnWTdb(state: EnergyPlusState, T: Float64) -> Float64:
    return external_Psychrometrics_PsyHfgAirFnWTdb(0.0, T)

fn psyHgAirFnWTdb(state: EnergyPlusState, T: Float64) -> Float64:
    return external_Psychrometrics_PsyHgAirFnWTdb(0.0, T)

fn psyHFnTdbW(state: EnergyPlusState, TDB: Float64, dW: Float64) -> Float64:
    return external_Psychrometrics_PsyHFnTdbW_fast(TDB, dW)

fn psyCpAirFnW(state: EnergyPlusState, dw: Float64) -> Float64:
    return external_Psychrometrics_PsyCpAirFnW(dw)

fn psyTdbFnHW(state: EnergyPlusState, H: Float64, dW: Float64) -> Float64:
    return external_Psychrometrics_PsyTdbFnHW(H, dW)

fn psyRhovFnTdbWPb(state: EnergyPlusState, Tdb: Float64, dW: Float64, PB: Float64) -> Float64:
    return external_Psychrometrics_PsyRhovFnTdbWPb_fast(Tdb, dW, PB)

fn psyTwbFnTdbWPb(state: EnergyPlusState, Tdb: Float64, W: Float64, Pb: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyTwbFnTdbWPb(thisState, Tdb, W, Pb)

fn psyVFnTdbWPb(state: EnergyPlusState, TDB: Float64, dW: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyVFnTdbWPb(thisState, TDB, dW, PB)

fn psyWFnTdbH(state: EnergyPlusState, TDB: Float64, H: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyWFnTdbH(thisState, TDB, H, "", True)

fn psyPsatFnTemp(state: EnergyPlusState, T: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyPsatFnTemp(thisState, T)

fn psyTsatFnHPb(state: EnergyPlusState, H: Float64, Pb: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyTsatFnHPb(thisState, H, Pb)

fn psyRhovFnTdbRh(state: EnergyPlusState, Tdb: Float64, RH: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyRhovFnTdbRh(thisState, Tdb, RH)

fn psyRhFnTdbRhov(state: EnergyPlusState, Tdb: Float64, Rhovapor: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyRhFnTdbRhov(thisState, Tdb, Rhovapor)

fn psyRhFnTdbWPb(state: EnergyPlusState, TDB: Float64, dW: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyRhFnTdbWPb(thisState, TDB, dW, PB)

fn psyWFnTdpPb(state: EnergyPlusState, TDP: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyWFnTdpPb(thisState, TDP, PB)

fn psyWFnTdbRhPb(state: EnergyPlusState, TDB: Float64, RH: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyWFnTdbRhPb(thisState, TDB, RH, PB)

fn psyWFnTdbTwbPb(state: EnergyPlusState, TDB: Float64, TWBin: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyWFnTdbTwbPb(thisState, TDB, TWBin, PB)

fn psyHFnTdbRhPb(state: EnergyPlusState, TDB: Float64, RH: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyHFnTdbRhPb(thisState, TDB, RH, PB)

fn psyTdpFnWPb(state: EnergyPlusState, W: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyTdpFnWPb(thisState, W, PB)

fn psyTdpFnTdbTwbPb(state: EnergyPlusState, TDB: Float64, TWB: Float64, PB: Float64) -> Float64:
    var thisState = UnsafePointer[EnergyPlusData](state.bitcast[UInt8]())
    return external_Psychrometrics_PsyTdpFnTdbTwbPb(thisState, TDB, TWB, PB)

external fn external_InputProcessor_factory() -> UnsafePointer[UInt8]
external fn external_DataStringGlobals_PythonAPIVersion() -> StringRef
external fn external_DataStringGlobals_VerString() -> StringRef
external fn external_Util_makeUPPER(s: StringRef) -> String
external fn external_Fluid_GetGlycol(state: UnsafePointer[EnergyPlusData], name: String) -> UnsafePointer[GlycolProps]
external fn external_Fluid_GetRefrig(state: UnsafePointer[EnergyPlusData], name: String) -> UnsafePointer[RefrigProps]
external fn external_Psychrometrics_PsyRhoAirFnPbTdbW_fast(state: UnsafePointer[EnergyPlusData], pb: Float64, tdb: Float64, dw: Float64) -> Float64
external fn external_Psychrometrics_PsyHfgAirFnWTdb(w: Float64, T: Float64) -> Float64
external fn external_Psychrometrics_PsyHgAirFnWTdb(w: Float64, T: Float64) -> Float64
external fn external_Psychrometrics_PsyHFnTdbW_fast(TDB: Float64, dW: Float64) -> Float64
external fn external_Psychrometrics_PsyCpAirFnW(dw: Float64) -> Float64
external fn external_Psychrometrics_PsyTdbFnHW(H: Float64, dW: Float64) -> Float64
external fn external_Psychrometrics_PsyRhovFnTdbWPb_fast(Tdb: Float64, dW: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyTwbFnTdbWPb(state: UnsafePointer[EnergyPlusData], Tdb: Float64, W: Float64, Pb: Float64) -> Float64
external fn external_Psychrometrics_PsyVFnTdbWPb(state: UnsafePointer[EnergyPlusData], TDB: Float64, dW: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyWFnTdbH(state: UnsafePointer[EnergyPlusData], TDB: Float64, H: Float64, dummy: StringRef, flag: Bool) -> Float64
external fn external_Psychrometrics_PsyPsatFnTemp(state: UnsafePointer[EnergyPlusData], T: Float64) -> Float64
external fn external_Psychrometrics_PsyTsatFnHPb(state: UnsafePointer[EnergyPlusData], H: Float64, Pb: Float64) -> Float64
external fn external_Psychrometrics_PsyRhovFnTdbRh(state: UnsafePointer[EnergyPlusData], Tdb: Float64, RH: Float64) -> Float64
external fn external_Psychrometrics_PsyRhFnTdbRhov(state: UnsafePointer[EnergyPlusData], Tdb: Float64, Rhovapor: Float64) -> Float64
external fn external_Psychrometrics_PsyRhFnTdbWPb(state: UnsafePointer[EnergyPlusData], TDB: Float64, dW: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyWFnTdpPb(state: UnsafePointer[EnergyPlusData], TDP: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyWFnTdbRhPb(state: UnsafePointer[EnergyPlusData], TDB: Float64, RH: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyWFnTdbTwbPb(state: UnsafePointer[EnergyPlusData], TDB: Float64, TWBin: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyHFnTdbRhPb(state: UnsafePointer[EnergyPlusData], TDB: Float64, RH: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyTdpFnWPb(state: UnsafePointer[EnergyPlusData], W: Float64, PB: Float64) -> Float64
external fn external_Psychrometrics_PsyTdpFnTdbTwbPb(state: UnsafePointer[EnergyPlusData], TDB: Float64, TWB: Float64, PB: Float64) -> Float64

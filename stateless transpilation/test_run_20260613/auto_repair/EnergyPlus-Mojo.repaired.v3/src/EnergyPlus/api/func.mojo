from ..api.EnergyPlusAPI import ENERGYPLUSLIB_API
from ..api.TypeDefs import EnergyPlusState, Real64, Glycol, Refrigerant
from state import *
from ..Data.EnergyPlusData import EnergyPlusData
from ..DataStringGlobals import PythonAPIVersion, VerString
from ..FluidProperties import Fluid
from ..InputProcessing.InputProcessor import InputProcessor
from ..Psychrometrics import Psychrometrics
from ..Util import Util

def initializeFunctionalAPI(state: EnergyPlusState):
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    if not thisState.dataInputProcessing.inputProcessor:
        thisState.dataInputProcessing.inputProcessor = InputProcessor.factory()
    thisState.init_constant_state(thisState)
    thisState.init_state(thisState)

def apiVersionFromEPlus(state: EnergyPlusState) -> Pointer[UInt8]:
    return PythonAPIVersion.c_str()

def energyPlusVersion() -> Pointer[UInt8]:
    return VerString.c_str()

def registerErrorCallback(state: EnergyPlusState, f: Pointer[Function[None, (Int, Pointer[UInt8])]]):
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    thisState.dataGlobal.errorCallback = f

def registerErrorCallback(state: EnergyPlusState, f: Function[None, (Int, Pointer[UInt8])]):
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    thisState.dataGlobal.errorCallback = f

def glycolNew(state: EnergyPlusState, glycolName: Pointer[UInt8]) -> Glycol:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    var glycol = Fluid.GetGlycol(thisState, Util.makeUPPER(glycolName))
    return __ref_to_ptr[Glycol](glycol)

def glycolDelete(state: EnergyPlusState, glycol: Glycol):

def glycolSpecificHeat(state: EnergyPlusState, glycol: Glycol, temperature: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.GlycolProps](glycol).getSpecificHeat(thisState, temperature, "C-API")

def glycolDensity(state: EnergyPlusState, glycol: Glycol, temperature: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.GlycolProps](glycol).getDensity(thisState, temperature, "C-API")

def glycolConductivity(state: EnergyPlusState, glycol: Glycol, temperature: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.GlycolProps](glycol).getConductivity(thisState, temperature, "C-API")

def glycolViscosity(state: EnergyPlusState, glycol: Glycol, temperature: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.GlycolProps](glycol).getViscosity(thisState, temperature, "C-API")

def refrigerantNew(state: EnergyPlusState, refrigerantName: Pointer[UInt8]) -> Refrigerant:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    var refrigerant = Fluid.GetRefrig(thisState, Util.makeUPPER(refrigerantName))
    return __ref_to_ptr[Refrigerant](refrigerant)

def refrigerantDelete(state: EnergyPlusState, refrigerant: Refrigerant):

def refrigerantSaturationPressure(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.RefrigProps](refrigerant).getSatPressure(thisState, temperature, "C-API")

def refrigerantSaturationTemperature(state: EnergyPlusState, refrigerant: Refrigerant, pressure: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.RefrigProps](refrigerant).getSatTemperature(thisState, pressure, "C-API")

def refrigerantSaturatedEnthalpy(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Real64, quality: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.RefrigProps](refrigerant).getSatEnthalpy(thisState, temperature, quality, "C-API")

def refrigerantSaturatedDensity(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Real64, quality: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.RefrigProps](refrigerant).getSatDensity(thisState, temperature, quality, "C-API")

def refrigerantSaturatedSpecificHeat(state: EnergyPlusState, refrigerant: Refrigerant, temperature: Real64, quality: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return __ptr_to_ref[Fluid.RefrigProps](refrigerant).getSatSpecificHeat(thisState, temperature, quality, "C-API")

def psyRhoFnPbTdbW(state: EnergyPlusState, pb: Real64, tdb: Real64, dw: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyRhoAirFnPbTdbW_fast(thisState, pb, tdb, dw)

def psyHfgAirFnWTdb(state: EnergyPlusState, T: Real64) -> Real64:
    return Psychrometrics.PsyHfgAirFnWTdb(0.0, T) # humidity ratio is not used

def psyHgAirFnWTdb(state: EnergyPlusState, T: Real64) -> Real64:
    return Psychrometrics.PsyHgAirFnWTdb(0.0, T) # humidity ratio is not used

def psyHFnTdbW(state: EnergyPlusState, TDB: Real64, dW: Real64) -> Real64:
    return Psychrometrics.PsyHFnTdbW_fast(TDB, dW)

def psyCpAirFnW(state: EnergyPlusState, dw: Real64) -> Real64:
    return Psychrometrics.PsyCpAirFnW(dw)

def psyTdbFnHW(state: EnergyPlusState, H: Real64, dW: Real64) -> Real64:
    return Psychrometrics.PsyTdbFnHW(H, dW)

def psyRhovFnTdbWPb(state: EnergyPlusState, Tdb: Real64, dW: Real64, PB: Real64) -> Real64:
    return Psychrometrics.PsyRhovFnTdbWPb_fast(Tdb, dW, PB)

def psyTwbFnTdbWPb(state: EnergyPlusState, Tdb: Real64, W: Real64, Pb: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyTwbFnTdbWPb(thisState, Tdb, W, Pb)

def psyVFnTdbWPb(state: EnergyPlusState, TDB: Real64, dW: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyVFnTdbWPb(thisState, TDB, dW, PB)

def psyWFnTdbH(state: EnergyPlusState, TDB: Real64, H: Real64) -> Real64:
    var dummyString: String
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyWFnTdbH(thisState, TDB, H, dummyString, True)

def psyPsatFnTemp(state: EnergyPlusState, T: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyPsatFnTemp(thisState, T)

def psyTsatFnHPb(state: EnergyPlusState, H: Real64, Pb: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyTsatFnHPb(thisState, H, Pb)

def psyRhovFnTdbRh(state: EnergyPlusState, Tdb: Real64, RH: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyRhovFnTdbRh(thisState, Tdb, RH)

def psyRhFnTdbRhov(state: EnergyPlusState, Tdb: Real64, Rhovapor: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyRhFnTdbRhov(thisState, Tdb, Rhovapor)

def psyRhFnTdbWPb(state: EnergyPlusState, TDB: Real64, dW: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyRhFnTdbWPb(thisState, TDB, dW, PB)

def psyWFnTdpPb(state: EnergyPlusState, TDP: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyWFnTdpPb(thisState, TDP, PB)

def psyWFnTdbRhPb(state: EnergyPlusState, TDB: Real64, RH: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyWFnTdbRhPb(thisState, TDB, RH, PB)

def psyWFnTdbTwbPb(state: EnergyPlusState, TDB: Real64, TWBin: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyWFnTdbTwbPb(thisState, TDB, TWBin, PB)

def psyHFnTdbRhPb(state: EnergyPlusState, TDB: Real64, RH: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyHFnTdbRhPb(thisState, TDB, RH, PB)

def psyTdpFnWPb(state: EnergyPlusState, W: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyTdpFnWPb(thisState, W, PB)

def psyTdpFnTdbTwbPb(state: EnergyPlusState, TDB: Real64, TWB: Real64, PB: Real64) -> Real64:
    var thisState = __ptr_to_ref[EnergyPlusData](state)
    return Psychrometrics.PsyTdpFnTdbTwbPb(thisState, TDB, TWB, PB)
from typing import Protocol, Any, Callable, Optional

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with methods init_constant_state, init_state
#                   and attributes dataInputProcessing.inputProcessor, dataGlobal.errorCallback
# - EnergyPlus.Fluid.GetGlycol(state: EnergyPlusData, name: str) -> GlycolProps
# - EnergyPlus.Fluid.GetRefrig(state: EnergyPlusData, name: str) -> RefrigProps
# - EnergyPlus.Util.makeUPPER(s: str) -> str
# - EnergyPlus.Psychrometrics: PsyRhoAirFnPbTdbW_fast, PsyHfgAirFnWTdb, PsyHgAirFnWTdb,
#   PsyHFnTdbW_fast, PsyCpAirFnW, PsyTdbFnHW, PsyRhovFnTdbWPb_fast, PsyTwbFnTdbWPb,
#   PsyVFnTdbWPb, PsyWFnTdbH, PsyPsatFnTemp, PsyTsatFnHPb, PsyRhovFnTdbRh,
#   PsyRhFnTdbRhov, PsyRhFnTdbWPb, PsyWFnTdpPb, PsyWFnTdbRhPb, PsyWFnTdbTwbPb,
#   PsyHFnTdbRhPb, PsyTdpFnWPb, PsyTdpFnTdbTwbPb
# - EnergyPlus.DataStringGlobals.PythonAPIVersion: str
# - EnergyPlus.DataStringGlobals.VerString: str
# - EnergyPlus.InputProcessor.factory() -> InputProcessor
# - EnergyPlus.Error: enum type

class EnergyPlusStateProtocol(Protocol):
    dataInputProcessing: Any
    dataGlobal: Any
    def init_constant_state(self, state: 'EnergyPlusStateProtocol') -> None: ...
    def init_state(self, state: 'EnergyPlusStateProtocol') -> None: ...

EnergyPlusState = Any
Glycol = Any
Refrigerant = Any

def initializeFunctionalAPI(state: EnergyPlusState) -> None:
    thisState = state
    if not thisState.dataInputProcessing.inputProcessor:
        from EnergyPlus import InputProcessor
        thisState.dataInputProcessing.inputProcessor = InputProcessor.factory()
    thisState.init_constant_state(thisState)
    thisState.init_state(thisState)

def apiVersionFromEPlus(state: EnergyPlusState) -> str:
    from EnergyPlus import DataStringGlobals
    return DataStringGlobals.PythonAPIVersion

def energyPlusVersion() -> str:
    from EnergyPlus import DataStringGlobals
    return DataStringGlobals.VerString

def registerErrorCallback(state: EnergyPlusState, f: Callable[[int, str], None]) -> None:
    thisState = state
    def wrapper(error_enum: Any, message: str) -> None:
        f(int(error_enum), message)
    thisState.dataGlobal.errorCallback = wrapper

def glycolNew(state: EnergyPlusState, glycolName: str) -> Glycol:
    from EnergyPlus import Fluid, Util
    thisState = state
    glycol = Fluid.GetGlycol(thisState, Util.makeUPPER(glycolName))
    return glycol

def glycolDelete(state: EnergyPlusState, glycol: Glycol) -> None:
    pass

def glycolSpecificHeat(state: EnergyPlusState, glycol: Glycol, temperature: float) -> float:
    thisState = state
    return glycol.getSpecificHeat(thisState, temperature, "C-API")

def glycolDensity(state: EnergyPlusState, glycol: Glycol, temperature: float) -> float:
    thisState = state
    return glycol.getDensity(thisState, temperature, "C-API")

def glycolConductivity(state: EnergyPlusState, glycol: Glycol, temperature: float) -> float:
    thisState = state
    return glycol.getConductivity(thisState, temperature, "C-API")

def glycolViscosity(state: EnergyPlusState, glycol: Glycol, temperature: float) -> float:
    thisState = state
    return glycol.getViscosity(thisState, temperature, "C-API")

def refrigerantNew(state: EnergyPlusState, refrigerantName: str) -> Refrigerant:
    from EnergyPlus import Fluid, Util
    thisState = state
    refrigerant = Fluid.GetRefrig(thisState, Util.makeUPPER(refrigerantName))
    return refrigerant

def refrigerantDelete(state: EnergyPlusState, refrigerant: Refrigerant) -> None:
    pass

def refrigerantSaturationPressure(state: EnergyPlusState, refrigerant: Refrigerant, temperature: float) -> float:
    thisState = state
    return refrigerant.getSatPressure(thisState, temperature, "C-API")

def refrigerantSaturationTemperature(state: EnergyPlusState, refrigerant: Refrigerant, pressure: float) -> float:
    thisState = state
    return refrigerant.getSatTemperature(thisState, pressure, "C-API")

def refrigerantSaturatedEnthalpy(state: EnergyPlusState, refrigerant: Refrigerant, temperature: float, quality: float) -> float:
    thisState = state
    return refrigerant.getSatEnthalpy(thisState, temperature, quality, "C-API")

def refrigerantSaturatedDensity(state: EnergyPlusState, refrigerant: Refrigerant, temperature: float, quality: float) -> float:
    thisState = state
    return refrigerant.getSatDensity(thisState, temperature, quality, "C-API")

def refrigerantSaturatedSpecificHeat(state: EnergyPlusState, refrigerant: Refrigerant, temperature: float, quality: float) -> float:
    thisState = state
    return refrigerant.getSatSpecificHeat(thisState, temperature, quality, "C-API")

def psyRhoFnPbTdbW(state: EnergyPlusState, pb: float, tdb: float, dw: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyRhoAirFnPbTdbW_fast(thisState, pb, tdb, dw)

def psyHfgAirFnWTdb(state: EnergyPlusState, T: float) -> float:
    from EnergyPlus import Psychrometrics
    return Psychrometrics.PsyHfgAirFnWTdb(0.0, T)

def psyHgAirFnWTdb(state: EnergyPlusState, T: float) -> float:
    from EnergyPlus import Psychrometrics
    return Psychrometrics.PsyHgAirFnWTdb(0.0, T)

def psyHFnTdbW(state: EnergyPlusState, TDB: float, dW: float) -> float:
    from EnergyPlus import Psychrometrics
    return Psychrometrics.PsyHFnTdbW_fast(TDB, dW)

def psyCpAirFnW(state: EnergyPlusState, dw: float) -> float:
    from EnergyPlus import Psychrometrics
    return Psychrometrics.PsyCpAirFnW(dw)

def psyTdbFnHW(state: EnergyPlusState, H: float, dW: float) -> float:
    from EnergyPlus import Psychrometrics
    return Psychrometrics.PsyTdbFnHW(H, dW)

def psyRhovFnTdbWPb(state: EnergyPlusState, Tdb: float, dW: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    return Psychrometrics.PsyRhovFnTdbWPb_fast(Tdb, dW, PB)

def psyTwbFnTdbWPb(state: EnergyPlusState, Tdb: float, W: float, Pb: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyTwbFnTdbWPb(thisState, Tdb, W, Pb)

def psyVFnTdbWPb(state: EnergyPlusState, TDB: float, dW: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyVFnTdbWPb(thisState, TDB, dW, PB)

def psyWFnTdbH(state: EnergyPlusState, TDB: float, H: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyWFnTdbH(thisState, TDB, H, "", True)

def psyPsatFnTemp(state: EnergyPlusState, T: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyPsatFnTemp(thisState, T)

def psyTsatFnHPb(state: EnergyPlusState, H: float, Pb: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyTsatFnHPb(thisState, H, Pb)

def psyRhovFnTdbRh(state: EnergyPlusState, Tdb: float, RH: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyRhovFnTdbRh(thisState, Tdb, RH)

def psyRhFnTdbRhov(state: EnergyPlusState, Tdb: float, Rhovapor: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyRhFnTdbRhov(thisState, Tdb, Rhovapor)

def psyRhFnTdbWPb(state: EnergyPlusState, TDB: float, dW: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyRhFnTdbWPb(thisState, TDB, dW, PB)

def psyWFnTdpPb(state: EnergyPlusState, TDP: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyWFnTdpPb(thisState, TDP, PB)

def psyWFnTdbRhPb(state: EnergyPlusState, TDB: float, RH: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyWFnTdbRhPb(thisState, TDB, RH, PB)

def psyWFnTdbTwbPb(state: EnergyPlusState, TDB: float, TWBin: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyWFnTdbTwbPb(thisState, TDB, TWBin, PB)

def psyHFnTdbRhPb(state: EnergyPlusState, TDB: float, RH: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyHFnTdbRhPb(thisState, TDB, RH, PB)

def psyTdpFnWPb(state: EnergyPlusState, W: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyTdpFnWPb(thisState, W, PB)

def psyTdpFnTdbTwbPb(state: EnergyPlusState, TDB: float, TWB: float, PB: float) -> float:
    from EnergyPlus import Psychrometrics
    thisState = state
    return Psychrometrics.PsyTdpFnTdbTwbPb(thisState, TDB, TWB, PB)

from ...Data.EnergyPlusData import EnergyPlusData
from ../Data/EnergyPlusData import EnergyPlusData as _EnergyPlusDataAlias
# Note: The import above is a workaround; actual Mojo may require different syntax.
# We assume EnergyPlusData struct is defined in ../Data/EnergyPlusData.mojo

alias EnergyPlusState = Pointer[None]

def stateNew() -> EnergyPlusState:
    var state = unsafe_new[EnergyPlusData]()
    return state.bitcast[None]()

def stateNewPython() -> EnergyPlusState:
    var state = unsafe_new[EnergyPlusData]()
    state[].dataPluginManager[].eplusRunningViaPythonAPI = True
    return state.bitcast[None]()

def stateReset(state: EnergyPlusState):
    var this_state: Pointer[EnergyPlusData] = state.bitcast[EnergyPlusData]()
    this_state[].clear_state()
    this_state[].init_constant_state(this_state[])

def stateDelete(state: EnergyPlusState):
    var this_state: Pointer[EnergyPlusData] = state.bitcast[EnergyPlusData]()
    unsafe_delete(this_state)
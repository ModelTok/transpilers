# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus.Data.EnergyPlusData

from typing import Any

EnergyPlusState = Any

def stateNew() -> EnergyPlusState:
    from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
    state = EnergyPlusData()
    return state

def stateNewPython() -> EnergyPlusState:
    from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
    state = EnergyPlusData()
    state.dataPluginManager.eplusRunningViaPythonAPI = True
    return state

def stateReset(state: EnergyPlusState) -> None:
    state.clear_state()
    state.init_constant_state(state)

def stateDelete(state: EnergyPlusState) -> None:
    del state

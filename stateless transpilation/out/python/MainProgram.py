# EXTERNAL DEPS (to wire in glue):
# - SimData.Elapsed_Time: float (REAL(r64))
# - EPlusSlab3D.Driver: Callable[[], None]
# - DataStringGlobals: module
# - EndEnergyPlus: Callable[[], None]

import time
from typing import Callable, Protocol


class SimDataState(Protocol):
    """State container for SimData module variables"""
    Elapsed_Time: float


def main_program(
    sim_data: SimDataState,
    driver: Callable[[], None],
    end_energy_plus: Callable[[], None]
) -> None:
    """Port of PROGRAM Slab3D from EnergyPlus"""
    time_start: float = time.perf_counter()
    driver()
    time_finish: float = time.perf_counter()
    sim_data.Elapsed_Time = time_finish - time_start
    end_energy_plus()

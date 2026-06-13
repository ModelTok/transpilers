# EXTERNAL DEPS (to wire in glue):
# - SimData.elapsed_time: Float64
# - EPlusSlab3D.Driver: fn() -> None
# - DataStringGlobals: module
# - EndEnergyPlus: fn() -> None

from time import perf_counter


struct SimDataState:
    """State container for SimData module variables"""
    var elapsed_time: Float64


fn main_program(
    inout sim_data: SimDataState,
    driver: fn() -> None,
    end_energy_plus: fn() -> None
) -> None:
    """Port of PROGRAM Slab3D from EnergyPlus"""
    let time_start = perf_counter()
    driver()
    let time_finish = perf_counter()
    sim_data.elapsed_time = time_finish - time_start
    end_energy_plus()

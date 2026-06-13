# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with:
#   - dataGlobal: object with CountNonZoneEquip (bool), NumOfWaterHeater (int), ZoneSizingCalc (bool)
#   - dataInputProcessing: object with:
#     - inputProcessor: object with getNumObjectsFound(state, str) -> int method
# - SimulateWaterHeaterStandAlone(state: EnergyPlusData, water_heater_num: int, first_hvac_iteration: bool) -> None
# - SimulateWaterUse(state: EnergyPlusData, first_hvac_iteration: bool) -> None

from typing import Protocol


class InputProcessor(Protocol):
    """Protocol for input processor."""

    def getNumObjectsFound(self, state: 'EnergyPlusData', object_type: str) -> int:
        """Get number of objects found for given type."""
        ...


class DataInputProcessing(Protocol):
    """Protocol for data input processing."""

    inputProcessor: InputProcessor


class DataGlobal(Protocol):
    """Protocol for global data."""

    CountNonZoneEquip: bool
    NumOfWaterHeater: int
    ZoneSizingCalc: bool


class EnergyPlusData(Protocol):
    """Protocol for EnergyPlus state data."""

    dataGlobal: DataGlobal
    dataInputProcessing: DataInputProcessing


def manage_non_zone_equipment(
    state: EnergyPlusData,
    first_hvac_iteration: bool
) -> bool:
    """
    Manage non-zone equipment.

    Args:
        state: EnergyPlus state object
        first_hvac_iteration: Whether this is the first HVAC iteration

    Returns:
        sim_non_zone_equipment: Simulation convergence flag (replaces by-reference parameter)
    """
    from WaterThermalTanks import SimulateWaterHeaterStandAlone
    from WaterUse import SimulateWaterUse

    count_non_zone_equip = state.dataGlobal.CountNonZoneEquip

    if count_non_zone_equip:
        state.dataGlobal.NumOfWaterHeater = (
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, "WaterHeater:Mixed"
            )
            + state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, "WaterHeater:Stratified"
            )
        )
        state.dataGlobal.CountNonZoneEquip = False

    SimulateWaterUse(state, first_hvac_iteration)

    if not state.dataGlobal.ZoneSizingCalc:
        for water_heater_num in range(1, state.dataGlobal.NumOfWaterHeater + 1):
            SimulateWaterHeaterStandAlone(
                state, water_heater_num, first_hvac_iteration
            )

    if first_hvac_iteration:
        sim_non_zone_equipment = True
    else:
        sim_non_zone_equipment = False

    return sim_non_zone_equipment

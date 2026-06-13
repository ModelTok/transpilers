# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with:
#   - dataGlobal: object with CountNonZoneEquip (Bool), NumOfWaterHeater (Int), ZoneSizingCalc (Bool)
#   - dataInputProcessing: object with:
#     - inputProcessor: object with getNumObjectsFound(state, str) -> Int method
# - SimulateWaterHeaterStandAlone(state: EnergyPlusData, water_heater_num: Int, first_hvac_iteration: Bool) -> None
# - SimulateWaterUse(state: EnergyPlusData, first_hvac_iteration: Bool) -> None

from sys.info import has_sse4


trait InputProcessor:
    fn getNumObjectsFound(self, state: EnergyPlusData, object_type: String) -> Int:
        ...


trait DataInputProcessing:
    var inputProcessor: InputProcessor


trait DataGlobal:
    var CountNonZoneEquip: Bool
    var NumOfWaterHeater: Int
    var ZoneSizingCalc: Bool


trait EnergyPlusData:
    var dataGlobal: DataGlobal
    var dataInputProcessing: DataInputProcessing


fn manage_non_zone_equipment(
    state: EnergyPlusData,
    first_hvac_iteration: Bool,
    inout sim_non_zone_equipment: Bool,
) -> None:
    """
    Manage non-zone equipment.

    Args:
        state: EnergyPlus state object
        first_hvac_iteration: Whether this is the first HVAC iteration
        sim_non_zone_equipment: Simulation convergence flag (modified in-place)
    """
    var count_non_zone_equip: Bool = state.dataGlobal.CountNonZoneEquip

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
        var water_heater_num: Int = 1
        while water_heater_num <= state.dataGlobal.NumOfWaterHeater:
            SimulateWaterHeaterStandAlone(
                state, water_heater_num, first_hvac_iteration
            )
            water_heater_num += 1

    if first_hvac_iteration:
        sim_non_zone_equipment = True
    else:
        sim_non_zone_equipment = False

# EXTERNAL DEPS (to wire in glue):
# - CIndoorEnvironment: from Tarcog.ISO15099.IndoorEnvironment (concrete class)
# - COutdoorEnvironment: from Tarcog.ISO15099.OutdoorEnvironment (concrete class)
# - SkyModel: from Tarcog.ISO15099.LayerInterfaces (enum)
# - AirHorizontalDirection: from Tarcog.ISO15099.LayerInterfaces (enum, Windward value)
# - TarcogConstants: from Tarcog.ISO15099.TarcogConstants (module with DEFAULT_FRACTION_OF_CLEAR_SKY)

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from Tarcog.ISO15099.IndoorEnvironment import CIndoorEnvironment
    from Tarcog.ISO15099.OutdoorEnvironment import COutdoorEnvironment


def indoor(
    room_air_temperature: float,
    room_pressure: float = 101325,
) -> "CIndoorEnvironment":
    """Factory function to create an indoor environment."""
    from Tarcog.ISO15099.IndoorEnvironment import CIndoorEnvironment
    return CIndoorEnvironment(room_air_temperature, room_pressure)


def outdoor(
    air_temperature: float,
    air_speed: float,
    solar_radiation: float,
    sky_temperature: float,
    sky_model: "SkyModel",
    pressure: float = 101325,
    air_direction: "AirHorizontalDirection" = None,
    fraction_of_clear_sky: float = None,
) -> "COutdoorEnvironment":
    """Factory function to create an outdoor environment."""
    from Tarcog.ISO15099.OutdoorEnvironment import COutdoorEnvironment
    from Tarcog.ISO15099.LayerInterfaces import AirHorizontalDirection
    from Tarcog.ISO15099.TarcogConstants import DEFAULT_FRACTION_OF_CLEAR_SKY

    if air_direction is None:
        air_direction = AirHorizontalDirection.Windward
    if fraction_of_clear_sky is None:
        fraction_of_clear_sky = DEFAULT_FRACTION_OF_CLEAR_SKY

    return COutdoorEnvironment(
        air_temperature,
        air_speed,
        solar_radiation,
        air_direction,
        sky_temperature,
        sky_model,
        pressure,
        fraction_of_clear_sky,
    )

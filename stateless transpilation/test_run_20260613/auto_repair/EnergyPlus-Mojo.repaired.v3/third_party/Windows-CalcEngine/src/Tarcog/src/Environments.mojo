from Environments import (
    CIndoorEnvironment,
    COutdoorEnvironment,
    SkyModel,
    AirHorizontalDirection,
    TarcogConstants,
)
from memory import shared_ptr, make_shared

@value
struct Environments:
    @staticmethod
    def indoor(roomAirTemperature: Float64, roomPressure: Float64 = 101325) -> shared_ptr[CIndoorEnvironment]:
        return make_shared[CIndoorEnvironment](roomAirTemperature, roomPressure)

    @staticmethod
    def outdoor(
        airTemperature: Float64,
        airSpeed: Float64,
        solarRadiation: Float64,
        skyTemperature: Float64,
        skyModel: SkyModel,
        pressure: Float64 = 101325,
        airDirection: AirHorizontalDirection = AirHorizontalDirection.Windward,
        fractionOfClearSky: Float64 = TarcogConstants.DEFAULT_FRACTION_OF_CLEAR_SKY,
    ) -> shared_ptr[COutdoorEnvironment]:
        return make_shared[COutdoorEnvironment](
            airTemperature,
            airSpeed,
            solarRadiation,
            airDirection,
            skyTemperature,
            skyModel,
            pressure,
            fractionOfClearSky,
        )
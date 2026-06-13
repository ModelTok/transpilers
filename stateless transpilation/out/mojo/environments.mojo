# EXTERNAL DEPS (to wire in glue):
# - CIndoorEnvironment: from Tarcog.ISO15099.IndoorEnvironment (concrete struct)
# - COutdoorEnvironment: from Tarcog.ISO15099.OutdoorEnvironment (concrete struct)
# - SkyModel: from Tarcog.ISO15099.LayerInterfaces (enum)
# - AirHorizontalDirection: from Tarcog.ISO15099.LayerInterfaces (enum, Windward value)
# - TarcogConstants: from Tarcog.ISO15099.TarcogConstants (module with DEFAULT_FRACTION_OF_CLEAR_SKY)


struct Environments:
    @staticmethod
    fn indoor(
        room_air_temperature: Float64,
        room_pressure: Float64 = 101325,
    ) -> CIndoorEnvironment:
        """Factory function to create an indoor environment."""
        return CIndoorEnvironment(room_air_temperature, room_pressure)

    @staticmethod
    fn outdoor(
        air_temperature: Float64,
        air_speed: Float64,
        solar_radiation: Float64,
        sky_temperature: Float64,
        sky_model: SkyModel,
        pressure: Float64 = 101325,
        air_direction: AirHorizontalDirection = AirHorizontalDirection.Windward,
        fraction_of_clear_sky: Float64 = TarcogConstants.DEFAULT_FRACTION_OF_CLEAR_SKY,
    ) -> COutdoorEnvironment:
        """Factory function to create an outdoor environment."""
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

from math import pow
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import (
    EarthRadius,
    AtmosphericTempGradient,
    SunIsUpValue,
    StdPressureSeaLevel,
    GroundTempType,
    OutDryBulbTempAt,
    OutWetBulbTempAt,
    WindSpeedAt,
    OutBaroPressAt,
    SetOutBulbTempAt_error,
    EnvironmentData,
)
from DataGlobals import *
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError
from Constant import Kelvin
def OutDryBulbTempAt(state: EnergyPlusData, Z: Float64) -> Float64:
    var LocalOutDryBulbTemp: Float64
    var BaseTemp: Float64
    BaseTemp = state.dataEnvrn.OutDryBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
    if state.dataEnvrn.SiteTempGradient == 0.0:
        LocalOutDryBulbTemp = state.dataEnvrn.OutDryBulbTemp
    elif Z <= 0.0:
        LocalOutDryBulbTemp = BaseTemp
    else:
        LocalOutDryBulbTemp = BaseTemp - state.dataEnvrn.SiteTempGradient * EarthRadius * Z / (EarthRadius + Z)
    if LocalOutDryBulbTemp < -100.0:
        ShowSevereError(state, "OutDryBulbTempAt: outdoor drybulb temperature < -100 C")
        ShowContinueError(state, "...check heights, this height=[{:.0f}].".format(Z))
        ShowFatalError(state, "Program terminates due to preceding condition(s).")
    return LocalOutDryBulbTemp
def OutWetBulbTempAt(state: EnergyPlusData, Z: Float64) -> Float64:
    var LocalOutWetBulbTemp: Float64
    var BaseTemp: Float64
    BaseTemp = state.dataEnvrn.OutWetBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
    if state.dataEnvrn.SiteTempGradient == 0.0:
        LocalOutWetBulbTemp = state.dataEnvrn.OutWetBulbTemp
    elif Z <= 0.0:
        LocalOutWetBulbTemp = BaseTemp
    else:
        LocalOutWetBulbTemp = BaseTemp - state.dataEnvrn.SiteTempGradient * EarthRadius * Z / (EarthRadius + Z)
    if LocalOutWetBulbTemp < -100.0:
        ShowSevereError(state, "OutWetBulbTempAt: outdoor wetbulb temperature < -100 C")
        ShowContinueError(state, "...check heights, this height=[{:.0f}].".format(Z))
        ShowFatalError(state, "Program terminates due to preceding condition(s).")
    return LocalOutWetBulbTemp
def WindSpeedAt(state: EnergyPlusData, Z: Float64) -> Float64:
    if Z <= 0.0:
        return 0.0
    if state.dataEnvrn.SiteWindExp == 0.0:
        return state.dataEnvrn.WindSpeed
    return state.dataEnvrn.WindSpeed * state.dataEnvrn.WeatherFileWindModCoeff * pow(Z / state.dataEnvrn.SiteWindBLHeight, state.dataEnvrn.SiteWindExp)
def OutBaroPressAt(state: EnergyPlusData, Z: Float64) -> Float64:
    var LocalAirPressure: Float64
    var StdGravity: Float64 = 9.80665   # // Standard gravity (m/s2)
    var AirMolarMass: Float64 = 0.028964 # // Molar mass of air (kg/mol)
    var GasConstant: Float64 = 8.31432   # // Universal gas constant (J/mol*K)
    var TempGradient: Float64 = -0.0065  # // Standard temperature gradient (K/m)
    var GeopotentialH: Float64 = 0.0     # // Geopotential height (m)
    var BaseTemp: Float64
    BaseTemp = OutDryBulbTempAt(state, Z) + Kelvin
    if Z <= 0.0:
        LocalAirPressure = 0.0
    elif state.dataEnvrn.SiteTempGradient == 0.0:
        LocalAirPressure = state.dataEnvrn.OutBaroPress
    else:
        LocalAirPressure = state.dataEnvrn.StdBaroPress * pow(BaseTemp / (BaseTemp + TempGradient * (Z - GeopotentialH)), (StdGravity * AirMolarMass) / (GasConstant * TempGradient))
    return LocalAirPressure
def SetOutBulbTempAt_error(state: EnergyPlusData, Settings: String, max_height: Float64, SettingsName: String):
    ShowSevereError(state, "SetOutBulbTempAt: {} Outdoor Temperatures < -100 C".format(Settings))
    ShowContinueError(state, "...check {} Heights - Maximum {} Height=[{:.0f}].".format(Settings, Settings, max_height))
    if max_height >= 20000.0:
        ShowContinueError(state, "...according to your maximum Z height, your building is somewhere in the Stratosphere.")
        ShowContinueError(state, "...look at {} Name= {}".format(Settings, SettingsName))
    ShowFatalError(state, "Program terminates due to preceding condition(s).")
def SetWindSpeedAt(state: EnergyPlusData, NumItems: Int, Heights: Array1D[Float64], LocalWindSpeed: Array1D[Float64], Settings: String):
    if state.dataEnvrn.SiteWindExp == 0.0:
        for i in range(NumItems):
            LocalWindSpeed[i] = state.dataEnvrn.WindSpeed
    else:
        var fac: Float64 = state.dataEnvrn.WindSpeed * state.dataEnvrn.WeatherFileWindModCoeff * pow(state.dataEnvrn.SiteWindBLHeight, -state.dataEnvrn.SiteWindExp)
        var Z: Float64
        for i in range(NumItems):
            Z = Heights[i]
            if Z <= 0.0:
                LocalWindSpeed[i] = 0.0
            else:
                LocalWindSpeed[i] = fac * pow(Z, state.dataEnvrn.SiteWindExp)
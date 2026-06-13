from lib_solar_thermal_test import (
    FpcFactory,
    DefaultFpcFactory,
    FlatPlateArray,
    FlatPlateCollector,
    CollectorLocation,
    CollectorOrientation,
    ArrayDimensions,
    Pipe,
    TimeAndPosition,
    CollectorTestSpecifications,
    ExternalConditions,
    tm,
    kErrorToleranceLo,
    kErrorToleranceHi,
)
from vs_google_test_explorer_namespace import NAMESPACE_TEST
from memory import Pointer
from math import isnan

# NAMESPACE_TEST(solar_thermal, FlatPlateCollectorTest, TestFlatPlateCollectorNominalOperation)
def TestFlatPlateCollectorNominalOperation():
    var default_fpc_factory = DefaultFpcFactory()
    var flat_plate_collector = default_fpc_factory.MakeCollector()
    var time_and_position = default_fpc_factory.MakeTimeAndPosition()
    var external_conditions = default_fpc_factory.MakeExternalConditions()
    var useful_power_gain = flat_plate_collector.UsefulPowerGain(time_and_position[], external_conditions[])  # [W]
    var T_out = flat_plate_collector.T_out(time_and_position[], external_conditions[])                        # [C]
    # EXPECT_NEAR(useful_power_gain, 1.659e3, 1.659e3 * kErrorToleranceHi)
    # EXPECT_NEAR(T_out, 50.26, 50.26 * kErrorToleranceHi)

# NAMESPACE_TEST(solar_thermal, FlatPlateArrayTest, TestFlatPlateArrayOfOneNominalOperation)
def TestFlatPlateArrayOfOneNominalOperation():
    var default_fpc_factory = DefaultFpcFactory()
    var flat_plate_array = default_fpc_factory.MakeFpcArray()
    var timestamp = default_fpc_factory.MakeTime()
    var external_conditions = default_fpc_factory.MakeExternalConditions()
    external_conditions[].inlet_fluid_flow.temp = 44.86
    var useful_power_gain = flat_plate_array.UsefulPowerGain(timestamp, external_conditions[])  # [W]
    var T_out = flat_plate_array.T_out(timestamp, external_conditions[])                        # [C]
    # EXPECT_NEAR(useful_power_gain, 1.587e3, 1.587e3 * kErrorToleranceHi)
    # EXPECT_NEAR(T_out, 49.03, 49.03 * kErrorToleranceHi)

def FpcFactory.MakeFpcArray(
    self: FpcFactory,
    flat_plate_collector: FlatPlateCollector,
    collector_location: CollectorLocation,
    collector_orientation: CollectorOrientation,
    array_dimensions: ArrayDimensions,
    inlet_pipe: Pipe,
    outlet_pipe: Pipe,
) -> FlatPlateArray:
    return FlatPlateArray(flat_plate_collector, collector_location, collector_orientation, array_dimensions, inlet_pipe, outlet_pipe)

def FpcFactory.MakeCollector(
    self: FpcFactory,
    collector_test_specifications: CollectorTestSpecifications,
) -> FlatPlateCollector:
    return FlatPlateCollector(collector_test_specifications)

def FpcFactory.MakeTimeAndPosition(self: FpcFactory) -> TimeAndPosition:
    var time_and_position = TimeAndPosition()
    time_and_position.timestamp = self.MakeTime()
    time_and_position.collector_location = self.MakeLocation()
    time_and_position.collector_orientation = self.MakeOrientation()
    return time_and_position

def DefaultFpcFactory.MakeFpcArray(self: DefaultFpcFactory) -> FlatPlateArray:
    var flat_plate_collector = self.MakeCollector()
    var collector_location = self.MakeLocation()
    var collector_orientation = self.MakeOrientation()
    var array_dimensions = self.MakeArrayDimensions()
    var inlet_pipe = self.MakePipe()
    var outlet_pipe = self.MakePipe()
    return FlatPlateArray(flat_plate_collector, collector_location, collector_orientation, array_dimensions, inlet_pipe, outlet_pipe)

def DefaultFpcFactory.MakeCollector(self: DefaultFpcFactory) -> FlatPlateCollector:
    var collector_test_specifications = self.MakeTestSpecifications()
    return FlatPlateCollector(collector_test_specifications)

def DefaultFpcFactory.MakeTestSpecifications(self: DefaultFpcFactory) -> CollectorTestSpecifications:
    var collector_test_specifications = CollectorTestSpecifications()
    collector_test_specifications.FRta = 0.689
    collector_test_specifications.FRUL = 3.85
    collector_test_specifications.iam = 0.2
    collector_test_specifications.area_coll = 2.98
    collector_test_specifications.m_dot = 0.045528         # kg/s   
    collector_test_specifications.heat_capacity = 4.182    # kJ/kg-K
    return collector_test_specifications

def DefaultFpcFactory.MakeLocation(self: DefaultFpcFactory) -> CollectorLocation:
    var collector_location = CollectorLocation()
    collector_location.latitude = 33.45000
    collector_location.longitude = -111.98000
    collector_location.timezone = -7
    return collector_location

def DefaultFpcFactory.MakeOrientation(self: DefaultFpcFactory) -> CollectorOrientation:
    var collector_orientation = CollectorOrientation()
    collector_orientation.tilt = 30.
    collector_orientation.azimuth = 180.
    return collector_orientation

def DefaultFpcFactory.MakePipe(self: DefaultFpcFactory) -> Pipe:
    var inner_diameter = 0.019
    var insulation_conductivity = 0.03
    var insulation_thickness = 0.006
    var length = 5
    return Pipe(inner_diameter, insulation_conductivity, insulation_thickness, length)

def DefaultFpcFactory.MakeExternalConditions(self: DefaultFpcFactory) -> ExternalConditions:
    var external_conditions = ExternalConditions()
    external_conditions.weather.ambient_temp = 25.
    external_conditions.weather.dni = 935.
    external_conditions.weather.dhi = 84.
    external_conditions.weather.ghi = float("nan")
    external_conditions.weather.wind_speed = float("nan")
    external_conditions.weather.wind_direction = float("nan")
    external_conditions.inlet_fluid_flow.m_dot = 0.091056          # kg/s
    external_conditions.inlet_fluid_flow.specific_heat = 4.182     # kJ/kg-K
    external_conditions.inlet_fluid_flow.temp = 45.9               # from previous timestep
    external_conditions.albedo = 0.2
    return external_conditions

def DefaultFpcFactory.MakeTime(self: DefaultFpcFactory) -> tm:
    var time = tm()
    time.tm_year = 2012 - 1900  # years since 1900
    time.tm_mon = 1 - 1         # months since Jan. (Jan. = 0)
    time.tm_mday = 1
    time.tm_hour = 12
    time.tm_min = 30
    time.tm_sec = 0
    return time

def DefaultFpcFactory.MakeArrayDimensions(self: DefaultFpcFactory) -> ArrayDimensions:
    var array_dimensions = ArrayDimensions()
    array_dimensions.num_in_parallel = 1
    array_dimensions.num_in_series = 1
    return array_dimensions
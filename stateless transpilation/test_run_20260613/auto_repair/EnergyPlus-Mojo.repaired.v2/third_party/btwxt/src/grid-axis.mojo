/* Copyright (c) 2018 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from btwxt import BtwxtException, InterpolationMethod, ExtrapolationMethod, vector_is_valid

from memory import SharedPtr

from Courierr import Courierr

from utils import StringRef

struct GridAxis:
    var name: String
    var values: List[Float64]
    var interpolation_method: InterpolationMethod
    var extrapolation_method: ExtrapolationMethod
    var extrapolation_limits: Tuple[Float64, Float64]
    var cubic_spacing_ratios: List[List[Float64]]
    var logger: SharedPtr[Courierr]

    def __init__(inout self, values_in: List[Float64], name: String, interpolation_method: InterpolationMethod, extrapolation_method: ExtrapolationMethod, extrapolation_limits: Tuple[Float64, Float64], logger_in: SharedPtr[Courierr]):
        self.name = name
        self.values = values_in
        self.interpolation_method = interpolation_method
        self.extrapolation_method = extrapolation_method
        self.extrapolation_limits = extrapolation_limits
        self.cubic_spacing_ratios = List[List[Float64]](2, List[Float64](Math.max(static_cast[Int](self.values.size) - 1, 0), 1.0))
        self.logger = logger_in
        
        if self.values.size == 0:
            raise BtwktException("Cannot create grid axis (name=\"" + self.name + "\") from a zero-length vector.", *self.logger)
        self.check_grid_sorted()
        self.check_extrapolation_limits()
        if self.interpolation_method == InterpolationMethod.cubic:
            self.calculate_cubic_spacing_ratios()

    def set_interpolation_method(inout self, interpolation_method_in: InterpolationMethod):
        self.interpolation_method = interpolation_method_in
        if interpolation_method_in == InterpolationMethod.cubic:
            self.calculate_cubic_spacing_ratios()

    def set_extrapolation_method(inout self, extrapolation_method_in: ExtrapolationMethod):
        var info_format: StringRef = "A {} extrapolation method is not valid for grid axis (name=\"{}\") with only {} value. Extrapolation method reset to {}."
        match extrapolation_method_in:
            case ExtrapolationMethod.linear:
                if self.get_length() == 1:
                    self.extrapolation_method = ExtrapolationMethod.constant
                    self.logger.info(fmt::format(info_format, "linear", self.name, "one", "constant"))
                    return
            case _:

        self.extrapolation_method = extrapolation_method_in

    def calculate_cubic_spacing_ratios(inout self):
        if self.get_length() == 1:
            self.interpolation_method = InterpolationMethod.linear
            self.logger.info(fmt::format("A cubic interpolation method is not valid for grid axis (name=\"{}\") with only one value. Interpolation method reset to linear.", self.name))
        if self.interpolation_method == InterpolationMethod.linear:
            return
        static var floor: Int = 0
        static var ceiling: Int = 1
        for i in range(self.values.size - 1):
            var center_spacing: Float64 = self.values[i + 1] - self.values[i]
            if i != 0:
                self.cubic_spacing_ratios[floor][i] = center_spacing / (self.values[i + 1] - self.values[i - 1])
            if i + 2 != self.values.size:
                self.cubic_spacing_ratios[ceiling][i] = center_spacing / (self.values[i + 2] - self.values[i])

    def get_cubic_spacing_ratios(self, floor_or_ceiling: Int) -> List[Float64]:
        return self.cubic_spacing_ratios[floor_or_ceiling]

    def check_grid_sorted(self):
        var grid_is_sorted: Bool = vector_is_valid(self.values)
        if not grid_is_sorted:
            raise BtwktException(fmt::format("Grid axis (name=\"{}\") values are not sorted, or have duplicates.", self.name), *self.logger)

    def check_extrapolation_limits(inout self):
        var info_format: StringRef = "Grid axis (name=\"{}\") {} extrapolation limit ({}) is within the set of grid axis values. Setting to {} axis value ({})."
        if self.extrapolation_limits.get[0]() > self.values[0]:
            self.logger.info(fmt::format(info_format, self.name, "lower", self.extrapolation_limits.get[0](), "smallest", self.values[0]))
            self.extrapolation_limits = (self.values[0], self.extrapolation_limits.get[1]())
        if self.extrapolation_limits.get[1]() < self.values.back():
            self.logger.info(fmt::format(info_format, self.name, "upper", self.extrapolation_limits.get[1](), "largest", self.values.back()))
            self.extrapolation_limits = (self.extrapolation_limits.get[0](), self.values.back())

    def get_length(self) -> Int:
        return self.values.size

def linspace(start: Float64, stop: Float64, number_of_points: Int) -> List[Float64]:
    var result: List[Float64] = List[Float64](number_of_points)
    var step: Float64 = (stop - start) / (static_cast[Float64](number_of_points) - 1.0)
    var value: Float64 = start
    for i in range(number_of_points):
        result[i] = value
        value += step
    return result
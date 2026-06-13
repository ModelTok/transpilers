/* Copyright (c) 2018 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from iostream import *
from numeric import *
from btwxt.btwxt import *
from regular-grid-interpolator-implementation import *
from memory import *
from vector import *
from string import *
from pair import *
from fmt import *

namespace Btwxt:

    def construct_grid_axes(grid_axis_vectors: List[List[Float64]], logger_in: SharedPtr[Courierr.Courierr]) -> List[GridAxis]:
        var grid_axes = List[GridAxis]()
        grid_axes.reserve(len(grid_axis_vectors))
        for axis in grid_axis_vectors:
            grid_axes.emplace_back(axis, fmt.format("Axis {}", len(grid_axes) + 1), InterpolationMethod.linear, ExtrapolationMethod.constant, Pair[Float64, Float64](-DBL_MAX, DBL_MAX), logger_in)
        return grid_axes

    def construct_grid_point_data_sets(grid_point_data_vectors: List[List[Float64]]) -> List[GridPointDataSet]:
        var grid_point_data_sets = List[GridPointDataSet]()
        grid_point_data_sets.reserve(len(grid_point_data_vectors))
        for grid_point_data_set in grid_point_data_vectors:
            grid_point_data_sets.emplace_back(grid_point_data_set, fmt.format("Data Set {}", len(grid_point_data_sets) + 1))
        return grid_point_data_sets

    @value
    struct RegularGridInterpolator:
        var implementation: UniquePtr[RegularGridInterpolatorImplementation]

        def __init__(inout self):

        def __init__(inout self, grid_axis_vectors: List[List[Float64]], logger: SharedPtr[Courierr.Courierr]):
            self = RegularGridInterpolator(construct_grid_axes(grid_axis_vectors, logger), List[GridPointDataSet](), logger)

        def __init__(inout self, grid_axis_vectors: List[List[Float64]], grid_point_data_vectors: List[List[Float64]], logger: SharedPtr[Courierr.Courierr]):
            self = RegularGridInterpolator(construct_grid_axes(grid_axis_vectors, logger), construct_grid_point_data_sets(grid_point_data_vectors), logger)

        def __init__(inout self, grid: List[GridAxis], logger: SharedPtr[Courierr.Courierr]):
            self.implementation = UniquePtr[RegularGridInterpolatorImplementation](RegularGridInterpolatorImplementation(grid, logger))

        def __init__(inout self, grid_axes: List[GridAxis], grid_point_data_vectors: List[List[Float64]], logger: SharedPtr[Courierr.Courierr]):
            self.implementation = UniquePtr[RegularGridInterpolatorImplementation](RegularGridInterpolatorImplementation(grid_axes, construct_grid_point_data_sets(grid_point_data_vectors), logger))

        def __init__(inout self, grid_axis_vectors: List[List[Float64]], grid_point_data_sets: List[GridPointDataSet], logger: SharedPtr[Courierr.Courierr]):
            self.implementation = UniquePtr[RegularGridInterpolatorImplementation](RegularGridInterpolatorImplementation(construct_grid_axes(grid_axis_vectors, logger), grid_point_data_sets, logger))

        def __init__(inout self, grid_axes: List[GridAxis], grid_point_data_sets: List[GridPointDataSet], logger: SharedPtr[Courierr.Courierr]):
            self.implementation = UniquePtr[RegularGridInterpolatorImplementation](RegularGridInterpolatorImplementation(grid_axes, grid_point_data_sets, logger))

        def __del__(owned self):

        def __copyinit__(inout self, source: RegularGridInterpolator):
            self = source
            if source.implementation:
                self.implementation = UniquePtr[RegularGridInterpolatorImplementation](RegularGridInterpolatorImplementation(*source.implementation))
            else:
                self.implementation = None

        def __init__(inout self, source: RegularGridInterpolator, logger: SharedPtr[Courierr.Courierr]):
            self = RegularGridInterpolator(source)
            self.implementation.set_logger(logger)

        def __copyassign__(inout self, source: RegularGridInterpolator) -> RegularGridInterpolator:
            if source.implementation:
                self.implementation = UniquePtr[RegularGridInterpolatorImplementation](RegularGridInterpolatorImplementation(*(source.implementation)))
            else:
                self.implementation = None
            return self

        def add_grid_point_data_set(inout self, grid_point_data_vector: List[Float64], name: String) -> Int:
            var resolved_name = name
            if len(resolved_name) == 0:
                resolved_name = fmt.format("Data Set {}", self.implementation.get_number_of_grid_point_data_sets())
            return self.add_grid_point_data_set(GridPointDataSet(grid_point_data_vector, resolved_name))

        def add_grid_point_data_set(inout self, grid_point_data_set: GridPointDataSet) -> Int:
            return self.implementation.add_grid_point_data_set(grid_point_data_set)

        def set_axis_extrapolation_method(inout self, axis_index: Int, method: ExtrapolationMethod):
            self.implementation.set_axis_extrapolation_method(axis_index, method)

        def set_axis_interpolation_method(inout self, axis_index: Int, method: InterpolationMethod):
            self.implementation.set_axis_interpolation_method(axis_index, method)

        def set_axis_extrapolation_limits(inout self, axis_index: Int, extrapolation_limits: Pair[Float64, Float64]):
            self.implementation.set_axis_extrapolation_limits(axis_index, extrapolation_limits)

        def get_number_of_dimensions(inout self) -> Int:
            return self.implementation.get_number_of_grid_axes()

        def normalize_grid_point_data_set_at_target(inout self, data_set_index: Int, target: List[Float64], scalar: Float64) -> Float64:
            self.set_target(target)
            return self.normalize_grid_point_data_set_at_target(data_set_index, scalar)

        def normalize_grid_point_data_set_at_target(inout self, data_set_index: Int, scalar: Float64) -> Float64:
            return self.implementation.normalize_grid_point_data_set_at_target(data_set_index, scalar)

        def normalize_grid_point_data_sets_at_target(inout self, target: List[Float64], scalar: Float64):
            self.set_target(target)
            self.normalize_grid_point_data_sets_at_target(scalar)

        def normalize_grid_point_data_sets_at_target(inout self, scalar: Float64):
            return self.implementation.normalize_grid_point_data_sets_at_target(scalar)

        def write_data(inout self) -> String:
            return self.implementation.write_data()

        def set_target(inout self, target: List[Float64]):
            self.implementation.set_target(target)

        def get_value_at_target(inout self, target: List[Float64], data_set_index: Int) -> Float64:
            self.set_target(target)
            return self.get_value_at_target(data_set_index)

        def get_value_at_target(inout self, data_set_index: Int) -> Float64:
            return self.implementation.get_results()[data_set_index]

        def get_values_at_target(inout self, target: List[Float64]) -> List[Float64]:
            return self.implementation.get_results(target)

        def get_values_at_target(inout self) -> List[Float64]:
            return self.implementation.get_results()

        def get_target(inout self) -> List[Float64]:
            return self.implementation.get_target()

        def get_target_bounds_status(self) -> List[TargetBoundsStatus]:
            return self.implementation.get_target_bounds_status()

        def clear_target(inout self):
            self.implementation.clear_target()

        def set_logger(inout self, logger: SharedPtr[Courierr.Courierr], set_grid_axes_loggers: Bool):
            self.implementation.set_logger(logger, set_grid_axes_loggers)

        def get_logger(inout self) -> SharedPtr[Courierr.Courierr]:
            return self.implementation.get_logger()
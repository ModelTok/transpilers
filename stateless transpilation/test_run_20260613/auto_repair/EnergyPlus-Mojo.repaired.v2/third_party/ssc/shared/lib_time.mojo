# include "lib_time.h"  // This is a Mojo translation of the C++ file.

# Import from the same directory as per the header context.
from lib_util import (
    matrix_t,
    hours_per_year,
    month_hour,
    weekday,
    month_of,
    week_of,
    day_of,
)

# ----------------------------------------------------------------------------
#  \function  single_year_to_lifetime_interpolated
#
#  Takes information about the desired lifetime vector, a single-year vector,
#  and returns the single-year vector as a lifetime length vector, interpolated
#  as needed.  As an example, consider that solar generation is passed in
#  as a 15-minute, 25 year vector, and the electric load is currently a single-year
#  and hourly.  The function will take the single-year hourly load, interpolate
#  it to 15-minutes, and scale to 25 years.
#
# \param[in] is_lifetime (true/false)
# \param[in] n_years (1 - 100)
# \param[in] n_lifetime (length of desired lifetime vector)
# \param[in] singleyear_vector (the single year vector to scale to lifetime and interpolate)
# \param[in] scale_factor (scaling factors for years 2 through n, must be length n prior to calling this function)
# \param[in] interpolation_factor (scaling as needed between single year records and the interpolated records. Given annual data, should be 1 for power, and 1/dt_hour for energy)
# \param[out] lifetime_from_singleyear_vector (the lifetime, interpolated vector)
# \param[out] n_rec_single_year (the length of a single year vector, interpolated at the lifetime vector timescale)
# \param[out] dt_hour (the time step in hours)
# ----------------------------------------------------------------------------
def single_year_to_lifetime_interpolated[T: AnyType](
    is_lifetime: Bool,
    n_years: Int,
    n_rec_lifetime: Int,
    singleyear_vector: List[T],
    scale_factor: List[T],
    interpolation_factor: Float64,
    inout lifetime_from_singleyear_vector: List[T],
    inout n_rec_single_year: Int,
    inout dt_hour: Float64,
):
    n_rec_single_year = n_rec_lifetime
    if is_lifetime:
        n_rec_single_year = n_rec_lifetime // n_years
    else:
        n_years = 1

    dt_hour = Float64(hours_per_year * n_years) / n_rec_lifetime
    lifetime_from_singleyear_vector.reserve(n_rec_lifetime)
    if singleyear_vector.size == 0:
        for i in range(n_rec_lifetime):
            lifetime_from_singleyear_vector.append(0)
        return

    var step_per_hour = Int(1 // dt_hour)
    if step_per_hour == 0:
        raise Error("single_year_to_lifetime_interpolated error: Calculated step_per_hour was 0.")
    var dt_hour_singleyear_input = Float64(hours_per_year) / Float64(singleyear_vector.size)
    var step_per_hour_singleyear_input = Int(1 // dt_hour_singleyear_input)
    var step_factor = T(step_per_hour) / T(step_per_hour_singleyear_input)

    if singleyear_vector.size > 1:
        var singleyear_sampled: List[T] = List[T]()
        if singleyear_vector.size <= n_rec_single_year:
            var sy_idx: Int = 0
            for h in range(hours_per_year):
                for sy in range(step_per_hour_singleyear_input):
                    for i in range(Int(step_factor)):
                        singleyear_sampled.append(singleyear_vector[sy_idx] / interpolation_factor)
                    sy_idx += 1
        else:
            var sy_idx: Int = 0
            for h in range(hours_per_year):
                for sy in range(step_per_hour):
                    singleyear_sampled.append(singleyear_vector[Int(sy_idx // step_factor)] / interpolation_factor)
                    sy_idx += 1

        for y in range(n_years):
            for i in range(n_rec_single_year):
                lifetime_from_singleyear_vector.append(singleyear_sampled[i] * scale_factor[y])
    elif singleyear_vector.size == 1:
        for y in range(n_years):
            for i in range(n_rec_single_year):
                lifetime_from_singleyear_vector.append(singleyear_vector[0] * scale_factor[y])


# Explicit instantiations for double and float (translated as comments)
# template void single_year_to_lifetime_interpolated<double>(bool, size_t, size_t,vector<double>, vector<double>, double, vector<double> &, size_t &, double &);
# template void single_year_to_lifetime_interpolated<float>(bool, size_t, size_t, vector<float>, vector<float>, double, vector<float> &, size_t &, double &);


# ----------------------------------------------------------------------------
#  \function  flatten_diurnal
#
#  Function takes in a weekday and weekend schedule, plus the period values and
#  an optional multiplier and returns a vector of the scaled hourly values
#  throughout the entire year
#
# \param[in] weekday_schedule - 12x24 scheduled of periods
# \param[in] weekday_schedule - 12x24 scheduled of periods
# \param[in] steps_per_hour - Number of time steps per hour
# \param[in] period_values - the value assigned to each period number
# \param[in] multiplier - a multiplier on the period value
# \param[out] flat_vector - The 8760*steps per hour values at each hour
# ----------------------------------------------------------------------------
def flatten_diurnal[T: AnyType](
    weekday_schedule: matrix_t[Int],
    weekend_schedule: matrix_t[Int],
    steps_per_hour: Int,
    period_values: List[T],
    multiplier: T = T(1),
) -> List[T]:
    var flat_vector: List[T] = List[T]()
    flat_vector.reserve(8760 * steps_per_hour)
    var month: Int
    var hour: Int
    var iprofile: Int
    var period_value: T
    for hour_of_year in range(8760):
        month_hour(hour_of_year % 8760, inout month, inout hour)
        if weekday(hour_of_year):
            iprofile = weekday_schedule[month - 1][hour - 1]  # ObjexxFCL 1-based -> 0-based
        else:
            iprofile = weekend_schedule[month - 1][hour - 1]
        period_value = period_values[iprofile - 1]
        for s in range(steps_per_hour):
            flat_vector.append(period_value * multiplier)
    return flat_vector


# Explicit instantiation for double (translated as comment)
# template vector<double> flatten_diurnal(util::matrix_t<size_t> weekday_schedule, util::matrix_t<size_t> weekend_schedule, size_t steps_per_hour, vector<double> period_values, double multiplier);


# ----------------------------------------------------------------------------
#  \function  extrapolate_timeseries
#
#  Function takes in a timeseries vector (daily, weekly, monthly, hourly or
#  subhourly), and the number of steps per hour desired, and an optional
#  multiplier and returns an output vector of the extrapolated values
#  throughout the entire year
#
# \param[in] steps_per_hour - Number of time steps per hour
# \param[in] input_values - the value assigned to each period number
# \param[in] multiplier - a multiplier on the period value
# \param[out] extrapolated_vector - The 8760*steps per hour values
# ----------------------------------------------------------------------------
def extrapolate_timeseries[T: AnyType](
    input_values: List[T],
    steps_per_hour: Int,
    multiplier: T = T(1),
) -> List[T]:
    var extrapolated_vector: List[T] = List[T]()
    extrapolated_vector.reserve(8760 * steps_per_hour)
    var month: Int
    var week: Int
    var day: Int
    var hour: Int
    var minute_step: Int
    var input_size = input_values.size
    var input_steps_per_hour = input_size // 8760
    var extrapolated_value: T
    for hour_of_year in range(8760):
        month = month_of(hour_of_year)
        if month > 0:
            month -= 1  # month_of is 1 based and all other time functions are 0 based.
        week = week_of(hour_of_year)
        day = day_of(hour_of_year)
        hour = hour_of_year
        for s in range(steps_per_hour):
            minute_step = Int(T(s) * T(input_steps_per_hour) / T(steps_per_hour))
            if input_size == 12:
                extrapolated_value = input_values[month]
            elif input_size == 52:
                extrapolated_value = input_values[week]
            elif input_size == 365:
                extrapolated_value = input_values[day]
            elif input_size == 8760:
                extrapolated_value = input_values[hour]
            elif input_size > 8760 and (hour * input_steps_per_hour + minute_step) < input_size:
                extrapolated_value = input_values[hour * input_steps_per_hour + minute_step]
            else:
                extrapolated_value = T(0)
            extrapolated_vector.append(extrapolated_value * multiplier)
    return extrapolated_vector


# Explicit instantiation for double (translated as comment)
# template vector<double> extrapolate_timeseries(vector<double> input_values, size_t steps_per_hour, double multiplier);
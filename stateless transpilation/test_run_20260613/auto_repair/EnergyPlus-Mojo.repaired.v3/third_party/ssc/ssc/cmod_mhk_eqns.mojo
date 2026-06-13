from vartab import var_table, var_data, vt_get_number
from math import fabs

def me_array_cable_length(data: ssc_data_t) raises:
    var vt = data as var_table
    if not vt:
        raise Error("ssc_data_t data invalid")
    var devices_per_row: Float64
    var device_spacing_in_row: Float64
    var number_rows: Float64
    var row_spacing: Float64
    var cable_system_overbuild: Float64
    var floating_array: Float64
    var export_cable_redundancy: Float64
    var water_depth: Float64
    var number_devices: Float64
    var distance_to_shore: Float64
    vt_get_number(vt, "devices_per_row", devices_per_row)
    vt_get_number(vt, "device_spacing_in_row", device_spacing_in_row)
    vt_get_number(vt, "number_rows", number_rows)
    vt_get_number(vt, "row_spacing", row_spacing)
    vt_get_number(vt, "cable_system_overbuild", cable_system_overbuild)
    vt_get_number(vt, "floating_array", floating_array)
    vt_get_number(vt, "export_cable_redundancy", export_cable_redundancy)
    vt_get_number(vt, "water_depth", water_depth)
    vt_get_number(vt, "number_devices", number_devices)
    vt_get_number(vt, "distance_to_shore", distance_to_shore)
    var length: Float64 = (devices_per_row - 1) * device_spacing_in_row * number_rows + row_spacing * (number_rows - 1)
    length *= (1.0 + cable_system_overbuild / 100.0)
    var cablelength: var_data = var_data(length)
    vt.assign("inter_array_cable_length", cablelength)
    if fabs(floating_array) > 0.1:
        length = 1.5 * water_depth * number_devices
        length *= (1.0 + cable_system_overbuild / 100.0)
    else:
        length = 0
    vt.assign("riser_cable_length", var_data(length))
    if fabs(export_cable_redundancy) > 0.1:
        length = (water_depth + distance_to_shore) * 2
        length *= (1.0 + cable_system_overbuild / 100.0)
    else:
        length = water_depth + distance_to_shore
        length *= (1.0 + cable_system_overbuild / 100.0)
    vt.assign("export_cable_length", var_data(length))
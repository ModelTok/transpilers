from vartab import var_table
from sscapi import ssc_data_t

def GenericSystem_conv_eff_eval(ptr: ssc_data_t) -> Float32:
    var vt = ptr  # static_cast<var_table*>(ptr)
    var vd = vt.lookup("heat_rate")
    if not vd:
        raise RuntimeError("Could not calculate conv_eff for GenericSystem: heat_rate not set")
    var heat_rate: Float64 = vd.num
    var conv_eff: Float64
    if heat_rate == 0.000000:
        conv_eff = 0.000000
    conv_eff = 100.000000 / heat_rate * 0.293100
    return Float32(conv_eff)
from core import compute_module, var_info, var_info_invalid, SSC_INPUT, SSC_OUTPUT, SSC_NUMBER, SSC_ARRAY, var_data, allocate, assign, as_number

# static var_info _cm_vtab_fossilgen[] = {
var _cm_vtab_fossilgen: List[var_info] = List[
    var_info(SSC_INPUT, SSC_NUMBER, "nameplate", "Nameplate generation capacity", "kW", "", "Fossil", "*", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "Fossil", "*", "MIN=0,MAX=100", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "derate", "System derate", "frac", "", "Fossil", "*", "MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "conv_eff", "Conversion efficiency", "%", "", "Fossil", "*", "MIN=0,MAX=100", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "e_net", "AC Generation", "kWh", "", "Fossil", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "fuel_usage", "Annual fuel usage", "kWht", "", "Fossil", "*", "", ""),
    var_info_invalid
]

class cm_fossilgen(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_fossilgen)

    def exec(inout self):
        var output: ssc_number_t = 8760 * self.as_number("nameplate") \
            * self.as_number("capacity_factor") / 100 \
            * (1 - self.as_number("derate") / 100)
        var e: Pointer[ssc_number_t] = self.allocate("e_net", 8760)
        for i in range(8760):
            e[i] = output / 8760
        self.assign("fuel_usage",
            var_data(output * 100 / self.as_number("conv_eff")))

# DEFINE_MODULE_ENTRY( fossilgen, "Generic fossil fuel generator - capacity factor based approach", 1 )
def fossilgen() -> compute_module:
    return cm_fossilgen()
from math import max

struct SystemAirFlowSizer:
    var sizing_type: String
    var sizing_string: String

    fn __init__(inout self):
        self.sizing_type = "SystemAirFlowSizing"
        self.sizing_string = "Maximum Flow Rate [m3/s]"

    fn size(inout self, state: object, original_value: Float64, inout errors_found: DynamicVector[Bool]) -> Float64:
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        var dd_name_fan_peak: String = ""
        var date_time_fan_peak: String = ""

        if self.data_ems_override_on:
            self.auto_sized_value = self.data_ems_override
        elif self.data_constant_used_for_sizing > 0.0 and self.data_fraction_used_for_sizing > 0.0:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        else:
            pass

        if self.data_scalable_sizing_on:
            pass

        if self.override_size_string:
            pass

        self.select_sizer_output(state, errors_found)
        if self.is_fan_report_object:
            pass

        return self.auto_sized_value

    fn clear_state(inout self):
        pass


struct SystemAirFlowSizerData:
    fn init_constant_state(inout self, state: object):
        pass

    fn init_state(inout self, state: object):
        pass

    fn clear_state(inout self):
        pass

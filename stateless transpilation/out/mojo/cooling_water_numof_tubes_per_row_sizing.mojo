from collections import List
from math import max

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container from EnergyPlus
# - AutoSizingType: enum from EnergyPlus/Autosizing/Base.hh
# - AutoSizingResultType: enum from EnergyPlus/Autosizing/Base.hh


struct CoolingWaterNumofTubesPerRowSizer:
    var sizing_type: String
    var sizing_string: String
    var was_auto_sized: Bool
    var data_plt_siz_cool_num: Int
    var plant_siz_data: List[Float64]
    var data_water_flow_used_for_sizing: Float64
    var auto_sized_value: Float64
    var override_size_string: Bool
    var error_type: String
    
    fn __init__(inout self):
        self.sizing_type = "CoolingWaterNumofTubesPerRowSizing"
        self.sizing_string = "Number of Tubes per Row"
        self.was_auto_sized = False
        self.data_plt_siz_cool_num = 0
        self.plant_siz_data = List[Float64]()
        self.data_water_flow_used_for_sizing = 0.0
        self.auto_sized_value = 0.0
        self.override_size_string = False
        self.error_type = ""
    
    fn check_initialized(self, state: Object, errors_found: Bool) -> Bool:
        return False
    
    fn pre_size(inout self, state: Object, original_value: Float64):
        pass
    
    fn select_sizer_output(inout self, state: Object, errors_found: Bool):
        pass
    
    fn size(inout self, state: Object, original_value: Float64, errors_found: Bool) -> Float64:
        if not self.check_initialized(state, errors_found):
            return 0.0
        self.pre_size(state, original_value)
        
        if (not self.was_auto_sized and 
            (self.data_plt_siz_cool_num == 0 or len(self.plant_siz_data) == 0)):
            self.auto_sized_value = original_value
        elif (not self.was_auto_sized and 
              self.data_plt_siz_cool_num <= len(self.plant_siz_data)):
            self.auto_sized_value = int(max(3.0, 13750.0 * self.data_water_flow_used_for_sizing + 1.0))
        elif (self.was_auto_sized and 
              self.data_plt_siz_cool_num > 0 and 
              self.data_plt_siz_cool_num <= len(self.plant_siz_data)):
            self.auto_sized_value = int(max(3.0, 13750.0 * self.data_water_flow_used_for_sizing + 1.0))
        else:
            self.error_type = "ErrorType1"
        
        if self.override_size_string:
            self.sizing_string = "Number of Tubes per Row"
        
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value

from typing import Any

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container from EnergyPlus
# - AutoSizingType: enum from EnergyPlus/Autosizing/Base.hh
# - AutoSizingResultType: enum from EnergyPlus/Autosizing/Base.hh


class BaseSizer:
    def __init__(self):
        self.sizing_type: Any = None
        self.sizing_string: str = ""
        self.was_auto_sized: bool = False
        self.data_plt_siz_cool_num: int = 0
        self.plant_siz_data: list[float] = []
        self.data_water_flow_used_for_sizing: float = 0.0
        self.auto_sized_value: float = 0.0
        self.override_size_string: bool = False
        self.error_type: Any = None
    
    def check_initialized(self, state: Any, errors_found: bool) -> bool:
        raise NotImplementedError()
    
    def pre_size(self, state: Any, original_value: float) -> None:
        raise NotImplementedError()
    
    def select_sizer_output(self, state: Any, errors_found: bool) -> None:
        raise NotImplementedError()


class CoolingWaterNumofTubesPerRowSizer(BaseSizer):
    def __init__(self):
        super().__init__()
        self.sizing_type = "CoolingWaterNumofTubesPerRowSizing"
        self.sizing_string = "Number of Tubes per Row"
    
    def size(self, state: Any, original_value: float, errors_found: bool) -> float:
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

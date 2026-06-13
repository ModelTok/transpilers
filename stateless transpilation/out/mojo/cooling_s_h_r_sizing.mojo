# EXTERNAL DEPS (to wire in glue):
# - BaseSizer (from EnergyPlus.Autosizing.Base): base struct/class with checkInitialized, preSize, selectSizerOutput, addErrorMessage methods
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData): state object containing dataHVACGlobal (with DXCT), dataSize (with DataDXSpeedNum)
# - HVAC namespace constants: SmallAirVolFlow (Float64), MaxRatedVolFlowPerRatedTotCap (List/Array by DXCoilType), MinRatedVolFlowPerRatedTotCap (List/Array by DXCoilType), DXCoilType enum (Regular value), CoilType enum (CoolingDXTwoSpeed, CoolingDXMultiSpeed, CoolingVRFFluidTCtrl, CoolingDXCurveFit)
# - DXCoils.ValidateADP (from EnergyPlus.DXCoils): function(state, compType, compName, RatedInletAirTemp, RatedInletAirHumRat, capacity, flow, shR, routine) -> Float64
# - AutoSizingType enum: CoolingSHRSizing
# - AutoSizingResultType enum: ErrorType1


struct CoolingSHRSizer:
    var sizing_type: String
    var sizing_string: String
    var data_fraction_used_for_sizing: Float64
    var data_constant_used_for_sizing: Float64
    var data_ems_override_on: Bool
    var data_ems_override: Float64
    var was_auto_sized: Bool
    var cur_zone_eq_num: Int32
    var sizing_des_run_this_zone: Bool
    var cur_sys_num: Int32
    var sizing_des_run_this_air_sys: Bool
    var data_flow_used_for_sizing: Float64
    var data_capacity_used_for_sizing: Float64
    var data_sizing_fraction: Float64
    var comp_type: String
    var comp_name: String
    var calling_routine: String
    var auto_sized_value: Float64
    var error_type: String
    var coil_type: String
    var data_dx_speed_num: Int32
    var override_size_string: Bool

    fn __init__(inout self):
        self.sizing_type = "CoolingSHRSizing"
        self.sizing_string = "Gross Rated Sensible Heat Ratio"
        self.data_fraction_used_for_sizing = 0.0
        self.data_constant_used_for_sizing = 0.0
        self.data_ems_override_on = False
        self.data_ems_override = 0.0
        self.was_auto_sized = False
        self.cur_zone_eq_num = 0
        self.sizing_des_run_this_zone = False
        self.cur_sys_num = 0
        self.sizing_des_run_this_air_sys = False
        self.data_flow_used_for_sizing = 0.0
        self.data_capacity_used_for_sizing = 0.0
        self.data_sizing_fraction = 1.0
        self.comp_type = ""
        self.comp_name = ""
        self.calling_routine = ""
        self.auto_sized_value = 0.0
        self.error_type = ""
        self.coil_type = ""
        self.data_dx_speed_num = 0
        self.override_size_string = False

    fn check_initialized(inout self, state: AnyType, errors_found: AnyType) -> Bool:
        return True

    fn pre_size(inout self, state: AnyType, original_value: Float64):
        pass

    fn select_sizer_output(inout self, state: AnyType, errors_found: AnyType):
        pass

    fn add_error_message(inout self, msg: String):
        pass

    fn size(inout self, state: AnyType, original_value: Float64, errors_found: AnyType) -> Float64:
        var rated_inlet_air_temp: Float64 = 26.6667
        var rated_inlet_air_hum_rat: Float64 = 0.0111847

        if not self.check_initialized(state, errors_found):
            return 0.0

        self.pre_size(state, original_value)

        if self.data_fraction_used_for_sizing > 0.0:
            self.auto_sized_value = self.data_constant_used_for_sizing * self.data_fraction_used_for_sizing
        else:
            if self.data_ems_override_on:
                self.auto_sized_value = self.data_ems_override
            else:
                if (not self.was_auto_sized and
                    ((self.cur_zone_eq_num > 0 and not self.sizing_des_run_this_zone) or
                     (self.cur_sys_num > 0 and not self.sizing_des_run_this_air_sys))):
                    self.auto_sized_value = original_value
                else:
                    if (self.data_flow_used_for_sizing >= 0.00005 and
                        self.data_capacity_used_for_sizing > 0.0):

                        var rated_vol_flow_per_rated_tot_cap: Float64 = (
                            self.data_flow_used_for_sizing / self.data_capacity_used_for_sizing
                        )
                        var dxct = state.dataHVACGlobal.DXCT
                        var dxct_index: Int32
                        if isinstance(dxct, Int32):
                            dxct_index = dxct
                        elif dxct == "Regular":
                            dxct_index = 1
                        else:
                            dxct_index = 2

                        var max_ratio: Float64 = state.HVAC.MaxRatedVolFlowPerRatedTotCap[dxct_index]
                        var min_ratio: Float64 = state.HVAC.MinRatedVolFlowPerRatedTotCap[dxct_index]

                        if dxct == "Regular" or dxct_index == 1:
                            if rated_vol_flow_per_rated_tot_cap > max_ratio:
                                self.auto_sized_value = 0.431 + 6086.0 * max_ratio
                            elif rated_vol_flow_per_rated_tot_cap < min_ratio:
                                self.auto_sized_value = 0.431 + 6086.0 * min_ratio
                            else:
                                self.auto_sized_value = 0.431 + 6086.0 * rated_vol_flow_per_rated_tot_cap
                        else:
                            if rated_vol_flow_per_rated_tot_cap > max_ratio:
                                self.auto_sized_value = 0.389 + 7684.0 * max_ratio
                            elif rated_vol_flow_per_rated_tot_cap < min_ratio:
                                self.auto_sized_value = 0.389 + 7684.0 * min_ratio
                            else:
                                self.auto_sized_value = 0.389 + 7684.0 * rated_vol_flow_per_rated_tot_cap

                        self.auto_sized_value = state.DXCoils.ValidateADP(
                            state,
                            self.comp_type,
                            self.comp_name,
                            rated_inlet_air_temp,
                            rated_inlet_air_hum_rat,
                            self.data_capacity_used_for_sizing,
                            self.data_flow_used_for_sizing,
                            self.auto_sized_value,
                            self.calling_routine
                        )

                        if self.data_sizing_fraction < 1.0:
                            self.auto_sized_value *= self.data_sizing_fraction
                    else:
                        if self.was_auto_sized:
                            self.auto_sized_value = 1.0
                            var msg: String = (
                                "Developer Error: For autosizing of " + self.comp_type + " " + self.comp_name +
                                ", DataFlowUsedForSizing and DataCapacityUsedForSizing " + self.sizing_string +
                                " must both be greater than 0."
                            )
                            self.error_type = "ErrorType1"
                            self.add_error_message(msg)

        self.update_sizing_string(state)
        self.select_sizer_output(state, errors_found)
        return self.auto_sized_value

    fn update_sizing_string(inout self, state: AnyType):
        if not self.override_size_string:
            return

        if self.coil_type == "CoolingDXTwoSpeed":
            if self.data_dx_speed_num == 1:
                self.sizing_string = "High Speed Rated Sensible Heat Ratio"
            elif self.data_dx_speed_num == 2:
                self.sizing_string = "Low Speed Gross Rated Sensible Heat Ratio"
        elif self.coil_type == "CoolingDXMultiSpeed":
            self.sizing_string = "Speed " + str(state.dataSize.DataDXSpeedNum) + " Rated Sensible Heat Ratio"
        elif self.coil_type == "CoolingVRFFluidTCtrl":
            self.sizing_string = "Rated Sensible Heat Ratio"
        elif self.coil_type == "CoolingDXCurveFit":
            self.sizing_string = "Gross Sensible Heat Ratio"
        else:
            self.sizing_string = "Gross Rated Sensible Heat Ratio"

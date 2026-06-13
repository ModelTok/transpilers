# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusState: opaque state parameter type
# - HeatingAirflowUASizer: sizer class with initialization and sizing methods, from HeatingAirflowUASizing.hh
# - BaseSizer: base class for sizers with getLastErrorMessages() method
# - EnergyPlusData: internal state data, passed by reference to size()
# - Real64: float64 type alias
# - DataSizing.AutoSize: constant for auto-sizing mode

from collections.vector import Vector


alias HeatingAirflowUAZoneTerminal = 0
alias HeatingAirflowUAZoneInductionUnit = 1
alias HeatingAirflowUAZoneFanCoil = 2

alias HeatingAirflowUASystemConfigTypeOutdoorAir = 0
alias HeatingAirflowUASystemConfigTypeMainDuct = 1
alias HeatingAirflowUASystemConfigTypeCoolingDuct = 2
alias HeatingAirflowUASystemConfigTypeHeatingDuct = 3
alias HeatingAirflowUASystemConfigTypeOtherDuct = 4


trait BaseSizer:
    fn getLastErrorMessages(self) -> String:
        ...


trait HeatingAirflowUASizerTrait:
    fn getLastErrorMessages(self) -> String:
        ...
    
    fn initializeForSingleDuctZoneTerminal(
        mut self, state: OpaquePointer, elevation: Float64, representativeFlowRate: Float64
    ) -> None:
        ...
    
    fn initializeForZoneInductionUnit(
        mut self, state: OpaquePointer, elevation: Float64, representativeFlowRate: Float64, reheatMultiplier: Float64
    ) -> None:
        ...
    
    fn initializeForZoneFanCoil(
        mut self, state: OpaquePointer, elevation: Float64, representativeFlowRate: Float64
    ) -> None:
        ...
    
    fn initializeForSystemOutdoorAir(
        mut self, state: OpaquePointer, elevation: Float64, representativeFlowRate: Float64, doas: Bool
    ) -> None:
        ...
    
    fn initializeForSystemMainDuct(
        mut self, state: OpaquePointer, elevation: Float64, representativeFlowRate: Float64, minFlowRateRatio: Float64
    ) -> None:
        ...
    
    fn initializeForSystemCoolingDuct(
        mut self, state: OpaquePointer, elevation: Float64
    ) -> None:
        ...
    
    fn initializeForSystemHeatingDuct(
        mut self, state: OpaquePointer, elevation: Float64
    ) -> None:
        ...
    
    fn initializeForSystemOtherDuct(
        mut self, state: OpaquePointer, elevation: Float64
    ) -> None:
        ...
    
    fn size(mut self, state: OpaquePointer, auto_size: Float64, errors_found: Reference[Bool]) -> None:
        ...
    
    fn getAutoSizedValue(self) -> Float64:
        ...


alias Sizer = OpaquePointer


fn sizer_get_last_error_messages(sizer: Sizer) -> String:
    """Gets warning and error messages from the autosizing process."""
    return OpaquePointer.to_reference[BaseSizer](sizer)[].getLastErrorMessages()


fn sizer_heating_airflow_ua_new() -> Sizer:
    """Returns a new reference to a HeatingAirflowUA Sizer class."""
    _ = OpaquePointer()
    return OpaquePointer()


fn sizer_heating_airflow_ua_delete(sizer: Sizer) -> None:
    """Deletes an instance of a HeatingAirflowUA Sizer class."""
    pass


fn sizer_heating_airflow_ua_initialize_for_zone(
    state: OpaquePointer,
    sizer: Sizer,
    zone_config: Int,
    elevation: Float64,
    representative_flow_rate: Float64,
    reheat_multiplier: Float64,
) -> None:
    """Initializes the HeatingAirflowUA sizer class for zone configurations."""
    var s = OpaquePointer.to_reference[HeatingAirflowUASizerTrait](sizer)
    if zone_config == HeatingAirflowUAZoneTerminal:
        s[].initializeForSingleDuctZoneTerminal(state, elevation, representative_flow_rate)
    elif zone_config == HeatingAirflowUAZoneInductionUnit:
        s[].initializeForZoneInductionUnit(state, elevation, representative_flow_rate, reheat_multiplier)
    elif zone_config == HeatingAirflowUAZoneFanCoil:
        s[].initializeForZoneFanCoil(state, elevation, representative_flow_rate)


fn sizer_heating_airflow_ua_initialize_for_system(
    state: OpaquePointer,
    sizer: Sizer,
    sys_config: Int,
    elevation: Float64,
    representative_flow_rate: Float64,
    min_flow_rate_ratio: Float64,
    doas: Int,
) -> None:
    """Initializes the HeatingAirflowUA sizer class for system configurations."""
    var s = OpaquePointer.to_reference[HeatingAirflowUASizerTrait](sizer)
    if sys_config == HeatingAirflowUASystemConfigTypeOutdoorAir:
        s[].initializeForSystemOutdoorAir(state, elevation, representative_flow_rate, doas == 1)
    elif sys_config == HeatingAirflowUASystemConfigTypeMainDuct:
        s[].initializeForSystemMainDuct(state, elevation, representative_flow_rate, min_flow_rate_ratio)
    elif sys_config == HeatingAirflowUASystemConfigTypeCoolingDuct:
        s[].initializeForSystemCoolingDuct(state, elevation)
    elif sys_config == HeatingAirflowUASystemConfigTypeHeatingDuct:
        s[].initializeForSystemHeatingDuct(state, elevation)
    elif sys_config == HeatingAirflowUASystemConfigTypeOtherDuct:
        s[].initializeForSystemOtherDuct(state, elevation)


fn sizer_heating_airflow_ua_size(state: OpaquePointer, sizer: Sizer) -> Int:
    """Does calculation of the HeatingAirflowUA sizer."""
    var s = OpaquePointer.to_reference[HeatingAirflowUASizerTrait](sizer)
    var errors_found: Bool = False
    s[].size(state, -1.0, Reference(errors_found))
    if errors_found:
        return 1
    return 0


fn sizer_heating_airflow_ua_value(sizer: Sizer) -> Float64:
    """Returns the resulting autosized value after sizerHeatingAirflowUASize() is called."""
    var s = OpaquePointer.to_reference[HeatingAirflowUASizerTrait](sizer)
    return s[].getAutoSizedValue()

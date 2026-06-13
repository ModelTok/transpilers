"""Wavelength range definitions and utilities."""

# EXTERNAL DEPS (to wire in glue):
# - WavelengthRange: enum from WCECommon.hpp


struct WavelengthRange:
    """Wavelength range enumeration."""
    alias IR = 0
    alias Solar = 1
    alias Visible = 2


struct WavelengthRangeData:
    """Holds start and end wavelength value. Used to return values for range wavelengths."""
    var start_lambda: Float64
    var end_lambda: Float64
    
    fn __init__(inout self, start_lambda: Float64, end_lambda: Float64):
        self.start_lambda = start_lambda
        self.end_lambda = end_lambda


struct CWavelengthRange:
    """Creates wavelength range for certain pre-defined ranges given by enumerator."""
    
    var _min_lambda: Float64
    var _max_lambda: Float64
    
    fn __init__(inout self, t_range: Int):
        self._min_lambda = 0.0
        self._max_lambda = 0.0
        self._set_wavelength_range(t_range)
    
    fn min_lambda(self) -> Float64:
        return self._min_lambda
    
    fn max_lambda(self) -> Float64:
        return self._max_lambda
    
    fn _set_wavelength_range(inout self, t_range: Int):
        if t_range == WavelengthRange.IR:
            self._min_lambda = 5.0
            self._max_lambda = 100.0
        elif t_range == WavelengthRange.Solar:
            self._min_lambda = 0.3
            self._max_lambda = 2.5
        elif t_range == WavelengthRange.Visible:
            self._min_lambda = 0.38
            self._max_lambda = 0.78

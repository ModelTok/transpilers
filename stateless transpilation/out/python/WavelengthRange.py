"""Wavelength range definitions and utilities."""

from dataclasses import dataclass
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# - WavelengthRange: enum from WCECommon.hpp


class WavelengthRange(Enum):
    """Wavelength range enumeration."""
    IR = "IR"
    Solar = "Solar"
    Visible = "Visible"


@dataclass
class WavelengthRangeData:
    """Holds start and end wavelength value. Used to return values for range wavelengths."""
    start_lambda: float
    end_lambda: float


class CWavelengthRange:
    """Creates wavelength range for certain pre-defined ranges given by enumerator."""
    
    _wavelength_range_map = {
        WavelengthRange.IR: WavelengthRangeData(5.0, 100.0),
        WavelengthRange.Solar: WavelengthRangeData(0.3, 2.5),
        WavelengthRange.Visible: WavelengthRangeData(0.38, 0.78),
    }
    
    def __init__(self, t_range: WavelengthRange) -> None:
        self._min_lambda: float = 0.0
        self._max_lambda: float = 0.0
        self._set_wavelength_range(t_range)
    
    def min_lambda(self) -> float:
        return self._min_lambda
    
    def max_lambda(self) -> float:
        return self._max_lambda
    
    def _set_wavelength_range(self, t_range: WavelengthRange) -> None:
        w_range = self._wavelength_range_map[t_range]
        self._min_lambda = w_range.start_lambda
        self._max_lambda = w_range.end_lambda

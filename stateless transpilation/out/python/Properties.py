# EXTERNAL DEPS (to wire in glue):
# - state: EnergyPlusData-like object
# - psychrometrics_psy_rho_air_fn_pb_tdb_w(state, P: float, T: float, W: float) -> float
#   Source: EnergyPlus/Psychrometrics
# - air_dynamic_viscosity_constexpr(T: float) -> float
#   Source: EnergyPlus/AirflowNetwork
# - air_density_constexpr(P: float, T: float, W: float) -> float
#   Source: EnergyPlus/AirflowNetwork
# - aircp(W: float) -> float
#   Source: EnergyPlus/Psychrometrics
# - show_warning_message(state, message: str) -> None
#   Source: EnergyPlus/UtilityRoutines
# - show_recurring_warning_error_at_end(state, message: str, err_idx: int) -> None
#   Source: EnergyPlus/UtilityRoutines

import math
from typing import Any


def psychrometrics_psy_rho_air_fn_pb_tdb_w(state: Any, P: float, T: float, W: float) -> float:
    raise NotImplementedError("Psychrometrics.PsyRhoAirFnPbTdbW not wired in")


def air_dynamic_viscosity_constexpr(T: float) -> float:
    raise NotImplementedError("air_dynamic_viscosity_constexpr not wired in")


def air_density_constexpr(P: float, T: float, W: float) -> float:
    raise NotImplementedError("air_density_constexpr not wired in")


def aircp(W: float) -> float:
    raise NotImplementedError("aircp not wired in")


def show_warning_message(state: Any, message: str) -> None:
    raise NotImplementedError("show_warning_message not wired in")


def show_recurring_warning_error_at_end(state: Any, message: str, err_idx: int) -> None:
    raise NotImplementedError("show_recurring_warning_error_at_end not wired in")


class AirState:
    def __init__(self, density: float = None):
        self.temperature = 20.0
        self.humidity_ratio = 0.0
        
        if density is not None:
            self.density = density
            self.sqrt_density = math.sqrt(density)
        else:
            default_density = air_density_constexpr(101325.0, 20.0, 0.0)
            self.density = default_density
            self.sqrt_density = math.sqrt(default_density)
        
        self.viscosity = air_dynamic_viscosity_constexpr(20.0)


class AirProperties:
    def __init__(self, state: Any):
        self.m_state = state
        self.lower_limit_err_idx = 0
        self.upper_limit_err_idx = 0
    
    def density(self, P: float, T: float, W: float) -> float:
        return psychrometrics_psy_rho_air_fn_pb_tdb_w(self.m_state, P, T, W)
    
    def thermal_conductivity(self, T: float) -> float:
        LOWER_LIMIT = -20
        UPPER_LIMIT = 70
        
        a = 0.02364
        b = 0.0000754772569209165
        c = -2.40977632412045e-8
        
        if T < LOWER_LIMIT:
            if self.lower_limit_err_idx == 0:
                show_warning_message(self.m_state, "Air temperature below lower limit of -20C for conductivity calculation")
            show_recurring_warning_error_at_end(
                self.m_state,
                f"Air temperature below lower limit of -20C for conductivity calculation. Air temperature of {LOWER_LIMIT:.1f} used for conductivity calculation.",
                self.lower_limit_err_idx
            )
            T = LOWER_LIMIT
        elif T > UPPER_LIMIT:
            if self.upper_limit_err_idx == 0:
                show_warning_message(self.m_state, "Air temperature above upper limit of 70C for conductivity calculation")
            show_recurring_warning_error_at_end(
                self.m_state,
                f"Air temperature above upper limit of 70C for conductivity calculation. Air temperature of {UPPER_LIMIT:.1f} used for conductivity calculation.",
                self.upper_limit_err_idx
            )
            T = UPPER_LIMIT
        
        return a + b * T + c * (T * T)
    
    def dynamic_viscosity(self, T: float) -> float:
        return 1.71432e-5 + 4.828e-8 * T
    
    def kinematic_viscosity(self, P: float, T: float, W: float) -> float:
        LOWER_LIMIT = -20
        UPPER_LIMIT = 70
        
        if T < LOWER_LIMIT:
            T = LOWER_LIMIT
        elif T > UPPER_LIMIT:
            T = UPPER_LIMIT
        
        return self.dynamic_viscosity(T) / psychrometrics_psy_rho_air_fn_pb_tdb_w(self.m_state, P, T, W)
    
    def thermal_diffusivity(self, P: float, T: float, W: float) -> float:
        LOWER_LIMIT = -20
        UPPER_LIMIT = 70
        
        if T < LOWER_LIMIT:
            T = LOWER_LIMIT
        elif T > UPPER_LIMIT:
            T = UPPER_LIMIT
        
        return self.thermal_conductivity(T) / (aircp(W) * psychrometrics_psy_rho_air_fn_pb_tdb_w(self.m_state, P, T, W))
    
    def prandtl_number(self, P: float, T: float, W: float) -> float:
        LOWER_LIMIT = -20
        UPPER_LIMIT = 70
        
        if T < LOWER_LIMIT:
            T = LOWER_LIMIT
        elif T > UPPER_LIMIT:
            T = UPPER_LIMIT
        
        return self.kinematic_viscosity(P, T, W) / self.thermal_diffusivity(P, T, W)

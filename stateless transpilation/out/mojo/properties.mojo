# EXTERNAL DEPS (to wire in glue):
# - state: EnergyPlusData-like object
# - psychrometrics_psy_rho_air_fn_pb_tdb_w(state, P: Float64, T: Float64, W: Float64) -> Float64
#   Source: EnergyPlus/Psychrometrics
# - air_dynamic_viscosity_constexpr(T: Float64) -> Float64
#   Source: EnergyPlus/AirflowNetwork
# - air_density_constexpr(P: Float64, T: Float64, W: Float64) -> Float64
#   Source: EnergyPlus/AirflowNetwork
# - aircp(W: Float64) -> Float64
#   Source: EnergyPlus/Psychrometrics
# - show_warning_message(state, message: String) -> None
#   Source: EnergyPlus/UtilityRoutines
# - show_recurring_warning_error_at_end(state, message: String, err_idx: Int) -> None
#   Source: EnergyPlus/UtilityRoutines

from math import sqrt


fn air_dynamic_viscosity_constexpr(T: Float64) -> Float64:
    return 0.0


fn air_density_constexpr(P: Float64, T: Float64, W: Float64) -> Float64:
    return 0.0


fn aircp(W: Float64) -> Float64:
    return 0.0


fn show_warning_message(state: AnyType, message: String) -> None:
    pass


fn show_recurring_warning_error_at_end(state: AnyType, message: String, err_idx: Int) -> None:
    pass


fn psychrometrics_psy_rho_air_fn_pb_tdb_w(state: AnyType, P: Float64, T: Float64, W: Float64) -> Float64:
    return 0.0


struct AirState:
    var temperature: Float64
    var humidity_ratio: Float64
    var density: Float64
    var sqrt_density: Float64
    var viscosity: Float64
    
    fn __init__(inout self, density: Float64):
        self.temperature = 20.0
        self.humidity_ratio = 0.0
        self.density = density
        self.sqrt_density = sqrt(density)
        self.viscosity = air_dynamic_viscosity_constexpr(20.0)
    
    fn __init__(inout self):
        let default_density = air_density_constexpr(101325.0, 20.0, 0.0)
        self.temperature = 20.0
        self.humidity_ratio = 0.0
        self.density = default_density
        self.sqrt_density = sqrt(default_density)
        self.viscosity = air_dynamic_viscosity_constexpr(20.0)


struct AirProperties:
    var m_state: AnyType
    var lower_limit_err_idx: Int
    var upper_limit_err_idx: Int
    
    fn __init__(inout self, state: AnyType):
        self.m_state = state
        self.lower_limit_err_idx = 0
        self.upper_limit_err_idx = 0
    
    fn density(self, P: Float64, T: Float64, W: Float64) -> Float64:
        return psychrometrics_psy_rho_air_fn_pb_tdb_w(self.m_state, P, T, W)
    
    fn thermal_conductivity(inout self, T: Float64) -> Float64:
        let LOWER_LIMIT: Float64 = -20.0
        let UPPER_LIMIT: Float64 = 70.0
        
        let a: Float64 = 0.02364
        let b: Float64 = 0.0000754772569209165
        let c: Float64 = -2.40977632412045e-8
        
        var T_var = T
        
        if T_var < LOWER_LIMIT:
            if self.lower_limit_err_idx == 0:
                show_warning_message(self.m_state, "Air temperature below lower limit of -20C for conductivity calculation")
            show_recurring_warning_error_at_end(
                self.m_state,
                "Air temperature below lower limit of -20C for conductivity calculation. Air temperature of " + String(LOWER_LIMIT) + " used for conductivity calculation.",
                self.lower_limit_err_idx
            )
            T_var = LOWER_LIMIT
        elif T_var > UPPER_LIMIT:
            if self.upper_limit_err_idx == 0:
                show_warning_message(self.m_state, "Air temperature above upper limit of 70C for conductivity calculation")
            show_recurring_warning_error_at_end(
                self.m_state,
                "Air temperature above upper limit of 70C for conductivity calculation. Air temperature of " + String(UPPER_LIMIT) + " used for conductivity calculation.",
                self.upper_limit_err_idx
            )
            T_var = UPPER_LIMIT
        
        return a + b * T_var + c * (T_var * T_var)
    
    fn dynamic_viscosity(self, T: Float64) -> Float64:
        return 1.71432e-5 + 4.828e-8 * T
    
    fn kinematic_viscosity(self, P: Float64, T: Float64, W: Float64) -> Float64:
        let LOWER_LIMIT: Float64 = -20.0
        let UPPER_LIMIT: Float64 = 70.0
        
        var T_var = T
        if T_var < LOWER_LIMIT:
            T_var = LOWER_LIMIT
        elif T_var > UPPER_LIMIT:
            T_var = UPPER_LIMIT
        
        return self.dynamic_viscosity(T_var) / psychrometrics_psy_rho_air_fn_pb_tdb_w(self.m_state, P, T_var, W)
    
    fn thermal_diffusivity(inout self, P: Float64, T: Float64, W: Float64) -> Float64:
        let LOWER_LIMIT: Float64 = -20.0
        let UPPER_LIMIT: Float64 = 70.0
        
        var T_var = T
        if T_var < LOWER_LIMIT:
            T_var = LOWER_LIMIT
        elif T_var > UPPER_LIMIT:
            T_var = UPPER_LIMIT
        
        return self.thermal_conductivity(T_var) / (aircp(W) * psychrometrics_psy_rho_air_fn_pb_tdb_w(self.m_state, P, T_var, W))
    
    fn prandtl_number(inout self, P: Float64, T: Float64, W: Float64) -> Float64:
        let LOWER_LIMIT: Float64 = -20.0
        let UPPER_LIMIT: Float64 = 70.0
        
        var T_var = T
        if T_var < LOWER_LIMIT:
            T_var = LOWER_LIMIT
        elif T_var > UPPER_LIMIT:
            T_var = UPPER_LIMIT
        
        return self.kinematic_viscosity(P, T_var, W) / self.thermal_diffusivity(P, T_var, W)

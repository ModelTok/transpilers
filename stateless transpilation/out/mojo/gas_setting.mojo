# EXTERNAL DEPS (to wire in glue):
# - VACUUM_PRESSURE: Float64 from WCECommon.ConstantsData

struct CGasSettings:
    var m_vacuum_pressure: Float64
    
    fn __init__(inout self):
        self.m_vacuum_pressure = VACUUM_PRESSURE
    
    fn getVacuumPressure(self) -> Float64:
        return self.m_vacuum_pressure
    
    fn setVacuumPressure(inout self, t_Value: Float64):
        self.m_vacuum_pressure = t_Value

var _cgas_settings_instance: CGasSettings | None = None

fn cgas_settings_instance() -> Reference[CGasSettings]:
    global _cgas_settings_instance
    if _cgas_settings_instance is None:
        _cgas_settings_instance = CGasSettings()
    return Reference[CGasSettings](_cgas_settings_instance.unsafe_value())

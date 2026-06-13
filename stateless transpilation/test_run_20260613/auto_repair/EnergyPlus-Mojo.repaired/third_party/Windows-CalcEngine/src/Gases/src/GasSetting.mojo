from WCECommon import ConstantsData

struct CGasSettings:
    var m_VacuumPressure: Float64

    def __init__(inout self):
        self.m_VacuumPressure = ConstantsData.VACUUMPRESSURE

    @staticmethod
    def instance() -> ref Self:
        return _g_instance

    def getVacuumPressure(self) -> Float64:
        return self.m_VacuumPressure

    def setVacuumPressure(inout self, t_Value: Float64):
        self.m_VacuumPressure = t_Value

var _g_instance = CGasSettings()
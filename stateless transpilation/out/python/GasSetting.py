# EXTERNAL DEPS (to wire in glue):
# - VACUUM_PRESSURE: float from WCECommon.ConstantsData

class CGasSettings:
    _instance = None
    
    def __init__(self):
        self.m_vacuum_pressure = VACUUM_PRESSURE
    
    @staticmethod
    def instance():
        if CGasSettings._instance is None:
            CGasSettings._instance = CGasSettings()
        return CGasSettings._instance
    
    def getVacuumPressure(self):
        return self.m_vacuum_pressure
    
    def setVacuumPressure(self, t_Value):
        self.m_vacuum_pressure = t_Value

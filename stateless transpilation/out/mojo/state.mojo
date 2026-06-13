# EXTERNAL DEPS (to wire in glue):
# None

# class CState is used to keep validity of object state. In some cases calculations do not need
# to be performed before results is requested.


struct CState:
    var m_StateCalculated: Bool
    
    fn __init__(inout self):
        self.m_StateCalculated = False
    
    fn __init__(inout self, t_State: CState):
        self.m_StateCalculated = t_State.m_StateCalculated
    
    fn resetCalculated(inout self):
        self.m_StateCalculated = False
        self.initializeStateVariables()
    
    fn setCalculated(inout self):
        self.m_StateCalculated = True
    
    fn isCalculated(self) -> Bool:
        return self.m_StateCalculated
    
    fn initializeStateVariables(inout self):
        pass

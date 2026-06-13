from State import CState

@value
struct CState:
    var m_StateCalculated: Bool

    def __init__(inout self):
        self.m_StateCalculated = False

    def __init__(inout self, t_State: CState):
        self.m_StateCalculated = t_State.m_StateCalculated

    def __copyinit__(inout self, other: CState):
        self.m_StateCalculated = other.m_StateCalculated

    def __moveinit__(inout self, owned other: CState):
        self.m_StateCalculated = other.m_StateCalculated

    def __del__(owned self):

    def resetCalculated(inout self):
        self.m_StateCalculated = False
        self.initializeStateVariables()

    def setCalculated(inout self):
        self.m_StateCalculated = True

    def isCalculated(self) -> Bool:
        return self.m_StateCalculated

    def initializeStateVariables(inout self):

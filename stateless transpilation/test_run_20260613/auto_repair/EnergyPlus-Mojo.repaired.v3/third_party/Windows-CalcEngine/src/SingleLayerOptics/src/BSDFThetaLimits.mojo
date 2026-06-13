from builtin import Error
from memory import Pointer
from builtin import List

@value
struct CThetaLimits:
    var m_ThetaLimits: Pointer[List[Float64]]

    def __init__(inout self, t_ThetaAngles: List[Float64]) raises:
        if len(t_ThetaAngles) == 0:
            raise Error("Error in definition of theta angles. Cannot form theta definitions.")
        self.m_ThetaLimits = Pointer[List[Float64]].alloc()
        self.createLimits(t_ThetaAngles)

    def getThetaLimits(self) -> Pointer[List[Float64]]:
        return self.m_ThetaLimits

    def __del__(owned self):
        self.m_ThetaLimits.free()

    def createLimits(inout self, t_ThetaAngles: List[Float64]) raises:
        var previousAngle: Float64 = 90.0
        self.m_ThetaLimits[].append(previousAngle)
        for val in reversed(t_ThetaAngles):
            var currentAngle: Float64 = val
            var delta: Float64 = 2.0 * (previousAngle - currentAngle)
            var limit: Float64 = previousAngle - delta
            if limit < 0.0:
                limit = 0.0
            self.m_ThetaLimits[].insert(0, limit)
            previousAngle = limit
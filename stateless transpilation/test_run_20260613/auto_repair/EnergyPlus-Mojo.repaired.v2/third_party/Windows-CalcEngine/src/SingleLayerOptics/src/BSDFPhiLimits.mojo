from BSDFPhiAngles import CBSDFPhiAngles
from memory import Pointer
from utils import Vector
from utils import Error

struct CPhiLimits:
    var m_PhiLimits: Vector[Float64]

    def __init__(inout self, t_NumOfPhis: size_t):
        if t_NumOfPhis == 0:
            raise Error("Number of phi angles for BSDF definition must be greater than zero.")
        var aPhiAngles = CBSDFPhiAngles(t_NumOfPhis)
        self.createLimits(aPhiAngles.phiAngles()[])

    def getPhiLimits(self) -> Pointer[Vector[Float64]]:
        return Pointer[Vector[Float64]](addressof(self.m_PhiLimits))

    def createLimits(inout self, t_PhiAngles: Vector[Float64]):
        var deltaPhi = 360.0 / t_PhiAngles.size
        var currentLimit = -deltaPhi / 2
        if t_PhiAngles.size == 1:
            currentLimit = 0
        for i in range(0, t_PhiAngles.size + 1):
            self.m_PhiLimits.push_back(currentLimit)
            currentLimit = currentLimit + deltaPhi
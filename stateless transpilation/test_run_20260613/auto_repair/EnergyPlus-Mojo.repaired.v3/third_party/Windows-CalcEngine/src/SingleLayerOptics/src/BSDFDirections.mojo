from BSDFPatch import CBSDFPatch
from BSDFThetaLimits import CThetaLimits, CCentralAngleLimits, CAngleLimits
from BSDFPhiLimits import CPhiLimits
from WCECommon import SquareMatrix, FenestrationCommon

from memory import Pointer
from utils import String
from vector import DynamicVector
from dict import Dict
from math import pi
from algorithms import find_if, distance
from range import range

@value
struct CBSDFDefinition:
    var m_Theta: Float64
    var m_NumOfPhis: UInt

    def __init__(out self, t_Theta: Float64, t_NumOfPhis: UInt):
        self.m_Theta = t_Theta
        self.m_NumOfPhis = t_NumOfPhis

    def theta(self) -> Float64:
        return self.m_Theta

    def numOfPhis(self) -> UInt:
        return self.m_NumOfPhis


@value
enum BSDFDirection:
    Incoming = 0
    Outgoing = 1


@value
struct CBSDFDirections:
    var m_Patches: DynamicVector[CBSDFPatch]
    var m_LambdaVector: DynamicVector[Float64]
    var m_LambdaMatrix: SquareMatrix

    def __init__(
        out self,
        t_Definitions: DynamicVector[CBSDFDefinition],
        t_Side: BSDFDirection,
    ):
        var thetaAngles = DynamicVector[Float64]()
        var numPhiAngles = DynamicVector[UInt]()
        for it in range(len(t_Definitions)):
            thetaAngles.push_back(t_Definitions[it].theta())
            numPhiAngles.push_back(t_Definitions[it].numOfPhis())

        var ThetaLimits = CThetaLimits(thetaAngles)
        var thetaLimits = *ThetaLimits.getThetaLimits()
        var lowerTheta = thetaLimits[0]
        for i in range(1, len(thetaLimits)):
            var upperTheta = thetaLimits[i]
            var currentTheta: Pointer[CAngleLimits] = Pointer[CAngleLimits].address_of(CAngleLimits(0.0, 0.0))
            if i == 1:
                currentTheta = Pointer[CAngleLimits].address_of(CCentralAngleLimits(upperTheta))
            else:
                currentTheta = Pointer[CAngleLimits].address_of(CAngleLimits(lowerTheta, upperTheta))

            var nPhis = numPhiAngles[i - 1]
            var phiAngles = CPhiLimits(nPhis)
            var phiLimits = phiAngles.getPhiLimits()
            var lowerPhi = phiLimits[0]
            if t_Side == BSDFDirection.Outgoing and nPhis != 1:
                lowerPhi += 180.0

            for j in range(1, len(phiLimits)):
                var upperPhi = phiLimits[j]
                if t_Side == BSDFDirection.Outgoing and nPhis != 1:
                    upperPhi += 180.0

                var currentPhi = CAngleLimits(lowerPhi, upperPhi)
                var currentPatch = CBSDFPatch(currentTheta, currentPhi)
                self.m_Patches.push_back(currentPatch)
                lowerPhi = upperPhi

            lowerTheta = upperTheta

        var size = len(self.m_Patches)
        self.m_LambdaMatrix = SquareMatrix(size)
        for i in range(size):
            self.m_LambdaVector.push_back(self.m_Patches[i].lambda())
            self.m_LambdaMatrix.set(i, i, self.m_Patches[i].lambda())

    def size(self) -> UInt:
        return len(self.m_Patches)

    def __getitem__(self, Index: UInt) -> CBSDFPatch:
        return self.m_Patches[Index]

    def begin(self) -> Pointer[CBSDFPatch]:
        return self.m_Patches.data

    def end(self) -> Pointer[CBSDFPatch]:
        return self.m_Patches.data + len(self.m_Patches)

    def lambdaVector(self) -> DynamicVector[Float64]:
        return self.m_LambdaVector

    def lambdaMatrix(self) -> SquareMatrix:
        return self.m_LambdaMatrix

    def getNearestBeamIndex(self, t_Theta: Float64, t_Phi: Float64) -> UInt:
        # Linear search equivalent to find_if
        var it: UInt = 0
        var found = False
        for idx in range(len(self.m_Patches)):
            if self.m_Patches[idx].isInPatch(t_Theta, t_Phi):
                it = idx
                found = True
                break

        if not found:
            raise Error("Could not find nearest beam index")

        var index = UInt(it)
        return index


@value
enum BSDFBasis:
    Small = 0
    Quarter = 1
    Half = 2
    Full = 3


@value
struct CBSDFHemisphere:
    var m_Directions: Dict[BSDFDirection, CBSDFDirections]

    def __init__(out self, t_Basis: BSDFBasis):
        var aDefinitions = DynamicVector[CBSDFDefinition]()
        if t_Basis == BSDFBasis.Small:
            aDefinitions = DynamicVector[CBSDFDefinition](
                CBSDFDefinition(0.0, 1),
                CBSDFDefinition(13.0, 1),
                CBSDFDefinition(26.0, 1),
                CBSDFDefinition(39.0, 1),
                CBSDFDefinition(52.0, 1),
                CBSDFDefinition(65.0, 1),
                CBSDFDefinition(80.75, 1)
            )
        elif t_Basis == BSDFBasis.Quarter:
            aDefinitions = DynamicVector[CBSDFDefinition](
                CBSDFDefinition(0.0, 1),
                CBSDFDefinition(18.0, 8),
                CBSDFDefinition(36.0, 12),
                CBSDFDefinition(54.0, 12),
                CBSDFDefinition(76.5, 8)
            )
        elif t_Basis == BSDFBasis.Half:
            aDefinitions = DynamicVector[CBSDFDefinition](
                CBSDFDefinition(0.0, 1),
                CBSDFDefinition(13.0, 8),
                CBSDFDefinition(26.0, 12),
                CBSDFDefinition(39.0, 16),
                CBSDFDefinition(52.0, 20),
                CBSDFDefinition(65.0, 12),
                CBSDFDefinition(80.75, 8)
            )
        elif t_Basis == BSDFBasis.Full:
            aDefinitions = DynamicVector[CBSDFDefinition](
                CBSDFDefinition(0.0, 1),
                CBSDFDefinition(10.0, 8),
                CBSDFDefinition(20.0, 16),
                CBSDFDefinition(30.0, 20),
                CBSDFDefinition(40.0, 24),
                CBSDFDefinition(50.0, 24),
                CBSDFDefinition(60.0, 24),
                CBSDFDefinition(70.0, 16),
                CBSDFDefinition(82.5, 12)
            )
        else:
            raise Error("Incorrect definition of the basis.")

        self.m_Directions = Dict[BSDFDirection, CBSDFDirections]()
        self.m_Directions[BSDFDirection.Incoming] = CBSDFDirections(aDefinitions, BSDFDirection.Incoming)
        self.m_Directions[BSDFDirection.Outgoing] = CBSDFDirections(aDefinitions, BSDFDirection.Outgoing)

    def __init__(
        out self,
        t_Definitions: DynamicVector[CBSDFDefinition],
    ):
        self.m_Directions = Dict[BSDFDirection, CBSDFDirections]()
        self.m_Directions[BSDFDirection.Incoming] = CBSDFDirections(t_Definitions, BSDFDirection.Incoming)
        self.m_Directions[BSDFDirection.Outgoing] = CBSDFDirections(t_Definitions, BSDFDirection.Outgoing)

    def getDirections(self, tDirection: BSDFDirection) -> CBSDFDirections:
        return self.m_Directions[tDirection]

    @staticmethod
    def create(t_Basis: BSDFBasis) -> CBSDFHemisphere:
        return CBSDFHemisphere(t_Basis)

    @staticmethod
    def create(t_Definitions: DynamicVector[CBSDFDefinition]) -> CBSDFHemisphere:
        return CBSDFHemisphere(t_Definitions)
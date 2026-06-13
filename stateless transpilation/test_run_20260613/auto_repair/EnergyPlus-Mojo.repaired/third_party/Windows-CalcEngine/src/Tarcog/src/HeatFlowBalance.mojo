from WCECommon import SquareMatrix, CLinearSolver, Side
from IGU import CIGU
from BaseLayer import CBaseLayer
from BaseIGULayer import CBaseIGULayer
from IGUSolidLayer import CIGUSolidLayer
from Environment import CEnvironment
from Surface import ISurface
from WCEGases import WCEGases
from memory import Pointer
from utils import StringRef

@value
struct CHeatFlowBalance:
    var m_MatrixA: SquareMatrix
    var m_VectorB: List[Float64]
    var m_IGU: Pointer[CIGU]

    def __init__(inout self, t_IGU: Pointer[CIGU]):
        self.m_MatrixA = SquareMatrix(4 * t_IGU[].getNumOfLayers())
        self.m_VectorB = List[Float64](4 * t_IGU[].getNumOfLayers())
        self.m_IGU = t_IGU

    def calcBalanceMatrix(self) -> List[Float64]:
        var aSolidLayers = self.m_IGU[].getSolidLayers()
        self.m_MatrixA.setZeros()
        for i in range(len(self.m_VectorB)):
            self.m_VectorB[i] = 0.0
        for i in range(len(aSolidLayers)):
            self.buildCell(aSolidLayers[i][], i)
        return CLinearSolver.solveSystem(self.m_MatrixA, self.m_VectorB)

    def buildCell(self, t_Current: Pointer[CBaseLayer], t_Index: Int):
        var sP = 4 * t_Index
        var next = t_Current[].getNextLayer()
        var previous = t_Current[].getPreviousLayer()
        var hgl = t_Current[].getConductionConvectionCoefficient()
        var hgap_prev = previous[].getConductionConvectionCoefficient()
        var hgap_next = next[].getConductionConvectionCoefficient()
        var frontSurface = t_Current[].getSurface(Side.Front)
        assert(frontSurface.is_some(), "frontSurface is null")
        var emissPowerFront = frontSurface.value[].emissivePowerTerm()
        var backSurface = t_Current[].getSurface(Side.Back)
        assert(backSurface.is_some(), "backSurface is null")
        var emissPowerBack = backSurface.value[].emissivePowerTerm()
        var qv_prev = previous[].getGainFlow()
        var qv_next = next[].getGainFlow()
        var solarRadiation = t_Current[].getGainFlow()
        self.m_MatrixA[sP, sP] = hgap_prev + hgl
        self.m_MatrixA[sP, sP + 1] = 1.0
        self.m_MatrixA[sP, sP + 3] = -hgl
        self.m_VectorB[sP] += solarRadiation / 2.0 + qv_prev / 2.0
        self.m_MatrixA[sP + 1, sP] = emissPowerFront
        self.m_MatrixA[sP + 1, sP + 1] = -1.0
        self.m_MatrixA[sP + 2, sP + 2] = -1.0
        self.m_MatrixA[sP + 2, sP + 3] = emissPowerBack
        self.m_MatrixA[sP + 3, sP] = hgl
        self.m_MatrixA[sP + 3, sP + 2] = -1.0
        self.m_MatrixA[sP + 3, sP + 3] = -hgap_next - hgl
        self.m_VectorB[sP + 3] += -solarRadiation / 2.0 - qv_next / 2.0
        if not (previous[].isa[CEnvironment]()):
            self.m_MatrixA[sP, sP - 1] = -hgap_prev
            self.m_MatrixA[sP, sP - 2] = frontSurface.value[].getTransmittance() - 1.0
            self.m_MatrixA[sP + 1, sP - 2] = frontSurface.value[].getReflectance()
            self.m_MatrixA[sP + 2, sP - 2] = frontSurface.value[].getTransmittance()
            self.m_MatrixA[sP + 3, sP - 2] = frontSurface.value[].getTransmittance()
        else:
            var environmentRadiosity = previous[].as[CEnvironment]().getEnvironmentIR()
            var airTemperature = previous[].as[CEnvironment]().getGasTemperature()
            self.m_VectorB[sP] += environmentRadiosity + hgap_prev * airTemperature - environmentRadiosity * frontSurface.value[].getTransmittance()
            self.m_VectorB[sP + 1] += -frontSurface.value[].getReflectance() * environmentRadiosity
            self.m_VectorB[sP + 2] += -frontSurface.value[].getTransmittance() * environmentRadiosity
            self.m_VectorB[sP + 3] += -frontSurface.value[].getTransmittance() * environmentRadiosity
        if not (next[].isa[CEnvironment]()):
            self.m_MatrixA[sP, sP + 5] = -backSurface.value[].getTransmittance()
            self.m_MatrixA[sP + 1, sP + 5] = backSurface.value[].getTransmittance()
            self.m_MatrixA[sP + 2, sP + 5] = backSurface.value[].getReflectance()
            self.m_MatrixA[sP + 3, sP + 4] = hgap_next
            self.m_MatrixA[sP + 3, sP + 5] = 1.0 - backSurface.value[].getTransmittance()
        else:
            var environmentRadiosity = next[].as[CEnvironment]().getEnvironmentIR()
            var airTemperature = next[].as[CEnvironment]().getGasTemperature()
            self.m_VectorB[sP] += backSurface.value[].getTransmittance() * environmentRadiosity
            self.m_VectorB[sP + 1] += -backSurface.value[].getTransmittance() * environmentRadiosity
            self.m_VectorB[sP + 2] += -backSurface.value[].getReflectance() * environmentRadiosity
            self.m_VectorB[sP + 3] += -environmentRadiosity - hgap_next * airTemperature + backSurface.value[].getTransmittance() * environmentRadiosity
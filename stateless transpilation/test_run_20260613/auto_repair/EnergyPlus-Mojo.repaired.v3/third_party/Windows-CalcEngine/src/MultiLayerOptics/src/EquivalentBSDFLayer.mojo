from memory import Arc
from stdlib import List, Dict, Tuple
from WCECommon import (
    SquareMatrix,
    CMatrixSeries,
    CSeries,
    Side,
    PropertySimple,
    EnumSide,
    EnumPropertySimple,
)
from WCESingleLayerOptics import (
    CBSDFLayer,
    CBSDFIntegrator,
    BSDFDirection,
    CBSDFDirections,
)
from EquivalentBSDFLayerSingleBand import CEquivalentBSDFLayerSingleBand

struct CEquivalentBSDFLayer:
    var m_LayersWL: List[CEquivalentBSDFLayerSingleBand]
    var m_Layer: List[Arc[CBSDFLayer]]
    var m_TotA: Dict[Side, Arc[CMatrixSeries]]
    var m_Tot: Dict[Tuple[Side, PropertySimple], Arc[CMatrixSeries]]
    var m_Lambda: SquareMatrix
    var m_CombinedLayerWavelengths: List[Float64]
    var m_Calculated: Bool

    def __init__(inout self, t_CommonWavelengths: List[Float64], t_Layer: Arc[CBSDFLayer]):
        self.m_Lambda = t_Layer.getResults().lambdaMatrix()
        self.m_CombinedLayerWavelengths = t_CommonWavelengths
        self.m_Calculated = False
        self.m_LayersWL = List[CEquivalentBSDFLayerSingleBand]()
        self.m_Layer = List[Arc[CBSDFLayer]]()
        self.m_TotA = Dict[Side, Arc[CMatrixSeries]]()
        self.m_Tot = Dict[Tuple[Side, PropertySimple], Arc[CMatrixSeries]]()
        if t_Layer is None:
            raise RuntimeError("Equivalent BSDF Layer must contain valid layer.")
        self.addLayer(t_Layer)

    def addLayer(inout self, t_Layer: Arc[CBSDFLayer]):
        self.updateWavelengthLayers(*t_Layer)
        self.m_Layer.append(t_Layer)

    def getDirections(self, t_Side: BSDFDirection) -> borrowed CBSDFDirections:
        return self.m_Layer[0].getDirections(t_Side)

    def getCommonWavelengths(self) -> List[Float64]:
        return self.m_CombinedLayerWavelengths

    def getMinLambda(self) -> Float64:
        return self.m_CombinedLayerWavelengths.front()

    def getMaxLambda(self) -> Float64:
        return self.m_CombinedLayerWavelengths.back()

    def getTotalA(inout self, t_Side: Side) -> Arc[CMatrixSeries]:
        if not self.m_Calculated:
            self.calculate()
        return self.m_TotA.at(t_Side)

    def getTotal(inout self, t_Side: Side, t_Property: PropertySimple) -> Arc[CMatrixSeries]:
        if not self.m_Calculated:
            self.calculate()
        return self.m_Tot.at(Tuple(t_Side, t_Property))

    def setSolarRadiation(inout self, t_SolarRadiation: CSeries):
        self.m_LayersWL.clear()
        for aLayer in self.m_Layer:
            aLayer.setSourceData(t_SolarRadiation)
            self.updateWavelengthLayers(*aLayer)
        self.m_Calculated = False

    def calculate(inout self):
        let matrixSize = self.m_Lambda.size()
        let numberOfLayers = self.m_LayersWL[0].getNumberOfLayers()
        for aSide in EnumSide():
            self.m_TotA[aSide] = Arc(CMatrixSeries(numberOfLayers, matrixSize))
            for aProperty in EnumPropertySimple():
                self.m_Tot[Tuple(aSide, aProperty)] = Arc(CMatrixSeries(matrixSize, matrixSize))
        let WLsize = self.m_CombinedLayerWavelengths.size()
        self.calculateWavelengthProperties(numberOfLayers, 0, WLsize)
        self.m_Calculated = True

    def calculateWavelengthProperties(inout self, t_NumOfLayers: size_t, t_Start: size_t, t_End: size_t):
        for i in range(t_Start, t_End):
            let curWL = self.m_CombinedLayerWavelengths[i]
            for aSide in EnumSide():
                for k in range(t_NumOfLayers):
                    self.m_TotA.at(aSide).addProperties(k, curWL, self.m_LayersWL[i].getLayerAbsorptances(k + 1, aSide))
                for aProperty in EnumPropertySimple():
                    let curPropertyMatrix = self.m_LayersWL[i].getProperty(aSide, aProperty)
                    self.m_Tot.at(Tuple(aSide, aProperty)).addProperties(curWL, curPropertyMatrix)

    def updateWavelengthLayers(inout self, t_Layer: CBSDFLayer):
        let aResults = t_Layer.getWavelengthResults()
        let size = self.m_CombinedLayerWavelengths.size()
        for i in range(size):
            let curWL = self.m_CombinedLayerWavelengths[i]
            let index = t_Layer.getBandIndex(curWL)
            assert(index > -1)
            let currentLayer = Arc[CBSDFIntegrator]((*aResults)[size_t(index)])
            if self.m_LayersWL.size() <= i:
                let aEquivalentLayer = CEquivalentBSDFLayerSingleBand(currentLayer)
                self.m_LayersWL.append(aEquivalentLayer)
            else:
                self.m_LayersWL[i].addLayer(currentLayer)
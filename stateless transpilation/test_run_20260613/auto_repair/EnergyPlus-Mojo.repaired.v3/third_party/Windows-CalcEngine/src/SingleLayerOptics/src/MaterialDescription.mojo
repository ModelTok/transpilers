from MaterialDescription.hpp import (
    RMaterialProperties, CMaterial, CMaterialSingleBand, CMaterialSingleBandBSDF,
    IMaterialDualBand, CMaterialDualBand, CMaterialDualBandBSDF, CMaterialSample,
    CMaterialPhotovoltaic, CMaterialMeasured, NIRRatio
)
from WCECommon import (
    FenestrationCommon, CSeries, CWavelengthRange, CNIRRatio, ConstantsData
)
from WCESpectralAveraging import (
    SpectralAveraging, CSpectralSample, CSpectralSampleData, CAngularSpectralSample,
    CPhotovoltaicSample, CSingleAngularMeasurement, CAngularMeasurements
)
from OpticalSurface import CSurface
from BeamDirection import CBeamDirection
from BSDFDirections import CBSDFHemisphere, BSDFDirection

from memory import Pointer
from utils import List, Dict, Tuple
from math import min, max

def modifyProperty(t_Range: Float64, t_Solar: Float64, t_Fraction: Float64) -> Float64:
    if t_Fraction == 1:
        return t_Range
    else:
        var ratio: Float64 = (t_Solar - t_Fraction * t_Range) / (1 - t_Fraction)
        if ratio > 1:
            ratio = 1
        if ratio < 0:
            ratio = 0
        return ratio

def modifyProperties(
    t_PartialRange: List[List[Float64]],
    t_FullRange: List[List[Float64]],
    t_Fraction: Float64
) -> List[List[Float64]]:
    var outgoing: List[Float64] = List[Float64]()
    let outgoingSize: Int = t_PartialRange[0].size
    outgoing.resize(outgoingSize)
    let incomingSize: Int = t_PartialRange.size
    var modifiedValues: List[List[Float64]] = List[List[Float64]](incomingSize, outgoing)
    for i in range(incomingSize):
        let partialOutgoing: List[Float64] = t_PartialRange[i]
        let fullOutgoing: List[Float64] = t_FullRange[i]
        var modifiedOutgoing: List[Float64] = modifiedValues[i]
        for j in range(outgoingSize):
            modifiedOutgoing[j] = modifyProperty(partialOutgoing[j], fullOutgoing[j], t_Fraction)
    return modifiedValues

def createNIRRange(
    t_PartialRange: Pointer[CMaterial],
    t_FullRange: Pointer[CMaterial],
    t_Fraction: Float64
) -> List[Pointer[CMaterial]]:
    var materials: List[Pointer[CMaterial]] = List[Pointer[CMaterial]]()
    let Tf_nir: Float64 = modifyProperty(
        t_PartialRange[].getProperty(FenestrationCommon.Property.T, FenestrationCommon.Side.Front),
        t_FullRange[].getProperty(FenestrationCommon.Property.T, FenestrationCommon.Side.Front),
        t_Fraction
    )
    let Tb_nir: Float64 = modifyProperty(
        t_PartialRange[].getProperty(FenestrationCommon.Property.T, FenestrationCommon.Side.Back),
        t_FullRange[].getProperty(FenestrationCommon.Property.T, FenestrationCommon.Side.Back),
        t_Fraction
    )
    let Rf_nir: Float64 = modifyProperty(
        t_PartialRange[].getProperty(FenestrationCommon.Property.R, FenestrationCommon.Side.Front),
        t_FullRange[].getProperty(FenestrationCommon.Property.R, FenestrationCommon.Side.Front),
        t_Fraction
    )
    let Rb_nir: Float64 = modifyProperty(
        t_PartialRange[].getProperty(FenestrationCommon.Property.R, FenestrationCommon.Side.Back),
        t_FullRange[].getProperty(FenestrationCommon.Property.R, FenestrationCommon.Side.Back),
        t_Fraction
    )
    let minRangeLambda: Float64 = t_PartialRange[].getMinLambda()
    if minRangeLambda > 0.32:
        var aMaterial: Pointer[CMaterialSingleBand] = Pointer[CMaterialSingleBand](
            CMaterialSingleBand(Tf_nir, Tb_nir, Rf_nir, Rb_nir, 0.32, minRangeLambda)
        )
        materials.append(aMaterial)
    materials.append(t_PartialRange)
    let maxRangeLambda: Float64 = t_PartialRange[].getMaxLambda()
    var aMaterial: Pointer[CMaterialSingleBand] = Pointer[CMaterialSingleBand](
        CMaterialSingleBand(Tf_nir, Tb_nir, Rf_nir, Rb_nir, maxRangeLambda, 2.5)
    )
    materials.append(aMaterial)
    return materials

def createNIRRange(
    t_PartialRange: Pointer[CMaterialSingleBandBSDF],
    t_FullRange: Pointer[CMaterialSingleBandBSDF],
    t_Fraction: Float64
) -> List[Pointer[CMaterial]]:
    var materials: List[Pointer[CMaterial]] = List[Pointer[CMaterial]]()
    let Tf_nir: List[List[Float64]] = modifyProperties(
        t_PartialRange[].getBSDFMatrix(FenestrationCommon.Property.T, FenestrationCommon.Side.Front),
        t_FullRange[].getBSDFMatrix(FenestrationCommon.Property.T, FenestrationCommon.Side.Front),
        t_Fraction
    )
    let Tb_nir: List[List[Float64]] = modifyProperties(
        t_PartialRange[].getBSDFMatrix(FenestrationCommon.Property.T, FenestrationCommon.Side.Back),
        t_FullRange[].getBSDFMatrix(FenestrationCommon.Property.T, FenestrationCommon.Side.Back),
        t_Fraction
    )
    let Rf_nir: List[List[Float64]] = modifyProperties(
        t_PartialRange[].getBSDFMatrix(FenestrationCommon.Property.R, FenestrationCommon.Side.Front),
        t_FullRange[].getBSDFMatrix(FenestrationCommon.Property.R, FenestrationCommon.Side.Front),
        t_Fraction
    )
    let Rb_nir: List[List[Float64]] = modifyProperties(
        t_PartialRange[].getBSDFMatrix(FenestrationCommon.Property.R, FenestrationCommon.Side.Back),
        t_FullRange[].getBSDFMatrix(FenestrationCommon.Property.R, FenestrationCommon.Side.Back),
        t_Fraction
    )
    let minRangeLambda: Float64 = t_PartialRange[].getMinLambda()
    if minRangeLambda > 0.32:
        var aMaterial: Pointer[CMaterialSingleBandBSDF] = Pointer[CMaterialSingleBandBSDF](
            CMaterialSingleBandBSDF(Tf_nir, Tb_nir, Rf_nir, Rb_nir, t_PartialRange[].getHemisphere(), 0.32, minRangeLambda)
        )
        materials.append(aMaterial)
    materials.append(t_PartialRange)
    let maxRangeLambda: Float64 = t_PartialRange[].getMaxLambda()
    var aMaterial: Pointer[CMaterialSingleBandBSDF] = Pointer[CMaterialSingleBandBSDF](
        CMaterialSingleBandBSDF(Tf_nir, Tb_nir, Rf_nir, Rb_nir, t_PartialRange[].getHemisphere(), maxRangeLambda, 2.5)
    )
    materials.append(aMaterial)
    return materials

struct RMaterialProperties:
    var m_Surface: Dict[FenestrationCommon.Side, Pointer[CSurface]]

    def __init__(inout self, aTf: Float64, aTb: Float64, aRf: Float64, aRb: Float64):
        self.m_Surface = Dict[FenestrationCommon.Side, Pointer[CSurface]]()
        self.m_Surface[FenestrationCommon.Side.Front] = Pointer[CSurface](CSurface(aTf, aRf))
        self.m_Surface[FenestrationCommon.Side.Back] = Pointer[CSurface](CSurface(aTb, aRb))

    def getProperty(self, t_Property: FenestrationCommon.Property, t_Side: FenestrationCommon.Side) -> Float64:
        return self.m_Surface[t_Side][].getProperty(t_Property)

class CMaterial:
    var m_MinLambda: Float64
    var m_MaxLambda: Float64
    var m_WavelengthsCalculated: Bool
    var m_Wavelengths: List[Float64]

    def __init__(inout self, minLambda: Float64, maxLambda: Float64):
        self.m_MinLambda = minLambda
        self.m_MaxLambda = maxLambda
        self.m_WavelengthsCalculated = False
        self.m_Wavelengths = List[Float64]()

    def __init__(inout self, t_Range: FenestrationCommon.WavelengthRange):
        self.m_WavelengthsCalculated = False
        self.m_Wavelengths = List[Float64]()
        let aRange: CWavelengthRange = CWavelengthRange(t_Range)
        self.m_MinLambda = aRange.minLambda()
        self.m_MaxLambda = aRange.maxLambda()

    def setSourceData(inout self, t_SourceData: Pointer[CSeries]):

    def setDetectorData(inout self, t_DetectorData: Pointer[CSeries]):

    def getProperty(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> Float64:
        ...

    def getBandProperties(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> List[Float64]:
        ...

    def getBandProperties(self) -> List[RMaterialProperties]:
        var aProperties: List[RMaterialProperties] = List[RMaterialProperties]()
        let Tf: List[Float64] = self.getBandProperties(FenestrationCommon.Property.T, FenestrationCommon.Side.Front)
        let Tb: List[Float64] = self.getBandProperties(FenestrationCommon.Property.T, FenestrationCommon.Side.Back)
        let Rf: List[Float64] = self.getBandProperties(FenestrationCommon.Property.R, FenestrationCommon.Side.Front)
        let Rb: List[Float64] = self.getBandProperties(FenestrationCommon.Property.R, FenestrationCommon.Side.Back)
        let size: Int = self.getBandSize()
        for i in range(size):
            let aMaterial: RMaterialProperties = RMaterialProperties(Tf[i], Tb[i], Rf[i], Rb[i])
            aProperties.append(aMaterial)
        return aProperties

    def getSpectralSample(self) -> Pointer[CSpectralSample]:
        let Tf: List[Float64] = self.getBandProperties(FenestrationCommon.Property.T, FenestrationCommon.Side.Front)
        let Rf: List[Float64] = self.getBandProperties(FenestrationCommon.Property.R, FenestrationCommon.Side.Front)
        let Rb: List[Float64] = self.getBandProperties(FenestrationCommon.Property.R, FenestrationCommon.Side.Back)
        var aSampleData: Pointer[CSpectralSampleData] = Pointer[CSpectralSampleData](CSpectralSampleData())
        let size: Int = self.getBandSize()
        for i in range(size):
            aSampleData[].addRecord(self.m_Wavelengths[i], Tf[i], Rf[i], Rb[i])
        return Pointer[CSpectralSample](CSpectralSample(aSampleData))

    def getBandWavelengths(self) -> List[Float64]:
        if not self.m_WavelengthsCalculated:
            self.m_Wavelengths = self.calculateBandWavelengths()
        return self.m_Wavelengths

    def isWavelengthInRange(self, wavelength: Float64) -> Bool:
        return ((self.m_MinLambda - ConstantsData.wavelengthErrorTolerance) <= wavelength) and ((self.m_MaxLambda + ConstantsData.wavelengthErrorTolerance) >= wavelength)

    def trimWavelengthToRange(self, wavelengths: List[Float64]) -> List[Float64]:
        var wl: List[Float64] = List[Float64]()
        for w in wavelengths:
            if w > (self.m_MinLambda - ConstantsData.floatErrorTolerance) and (w < (self.m_MaxLambda + ConstantsData.floatErrorTolerance)):
                wl.append(w)
        return wl

    def setBandWavelengths(inout self, wavelengths: List[Float64]):
        self.m_Wavelengths = self.trimWavelengthToRange(wavelengths)
        self.m_WavelengthsCalculated = True

    def getBandSize(self) -> Int:
        return self.getBandWavelengths().size

    def getBandIndex(self, t_Wavelength: Float64) -> Int:
        var aIndex: Int = -1
        let size: Int = self.getBandSize()
        for i in range(size):
            if self.m_Wavelengths[i] < (t_Wavelength + 1e-6):
                aIndex += 1
        return aIndex

    def getMinLambda(self) -> Float64:
        return self.m_MinLambda

    def getMaxLambda(self) -> Float64:
        return self.m_MaxLambda

    def Flipped(inout self, flipped: Bool):

    def calculateBandWavelengths(self) -> List[Float64]:
        ...

class CMaterialSingleBand(CMaterial):
    var m_Property: Dict[FenestrationCommon.Side, Pointer[CSurface]]

    def __init__(
        inout self,
        t_Tf: Float64,
        t_Tb: Float64,
        t_Rf: Float64,
        t_Rb: Float64,
        minLambda: Float64,
        maxLambda: Float64
    ):
        CMaterial.__init__(self, minLambda, maxLambda)
        self.m_Property = Dict[FenestrationCommon.Side, Pointer[CSurface]]()
        self.m_Property[FenestrationCommon.Side.Front] = Pointer[CSurface](CSurface(t_Tf, t_Rf))
        self.m_Property[FenestrationCommon.Side.Back] = Pointer[CSurface](CSurface(t_Tb, t_Rb))

    def __init__(
        inout self,
        t_Tf: Float64,
        t_Tb: Float64,
        t_Rf: Float64,
        t_Rb: Float64,
        t_Range: FenestrationCommon.WavelengthRange
    ):
        CMaterial.__init__(self, t_Range)
        self.m_Property = Dict[FenestrationCommon.Side, Pointer[CSurface]]()
        self.m_Property[FenestrationCommon.Side.Front] = Pointer[CSurface](CSurface(t_Tf, t_Rf))
        self.m_Property[FenestrationCommon.Side.Back] = Pointer[CSurface](CSurface(t_Tb, t_Rb))

    def getProperty(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> Float64:
        return self.m_Property[t_Side][].getProperty(t_Property)

    def getBandProperties(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> List[Float64]:
        var aResult: List[Float64] = List[Float64]()
        let prop: Float64 = self.getProperty(t_Property, t_Side)
        aResult.append(prop)
        aResult.append(prop)
        return aResult

    def calculateBandWavelengths(self) -> List[Float64]:
        var aWavelengths: List[Float64] = List[Float64]()
        aWavelengths.append(self.m_MinLambda)
        aWavelengths.append(self.m_MaxLambda)
        return aWavelengths

class CMaterialSingleBandBSDF(CMaterial):
    var m_Property: Dict[Tuple[FenestrationCommon.Property, FenestrationCommon.Side], List[List[Float64]]]
    var m_Hemisphere: CBSDFHemisphere

    def __init__(
        inout self,
        t_Tf: List[List[Float64]],
        t_Tb: List[List[Float64]],
        t_Rf: List[List[Float64]],
        t_Rb: List[List[Float64]],
        t_Hemisphere: CBSDFHemisphere,
        minLambda: Float64,
        maxLambda: Float64
    ):
        CMaterial.__init__(self, minLambda, maxLambda)
        self.m_Hemisphere = t_Hemisphere
        self.m_Property = Dict[Tuple[FenestrationCommon.Property, FenestrationCommon.Side], List[List[Float64]]]()
        self.validateMatrix(t_Tf, self.m_Hemisphere)
        self.validateMatrix(t_Tb, self.m_Hemisphere)
        self.validateMatrix(t_Rf, self.m_Hemisphere)
        self.validateMatrix(t_Rb, self.m_Hemisphere)
        self.m_Property[(FenestrationCommon.Property.T, FenestrationCommon.Side.Front)] = t_Tf
        self.m_Property[(FenestrationCommon.Property.T, FenestrationCommon.Side.Back)] = t_Tb
        self.m_Property[(FenestrationCommon.Property.R, FenestrationCommon.Side.Front)] = t_Rf
        self.m_Property[(FenestrationCommon.Property.R, FenestrationCommon.Side.Back)] = t_Rb

    def __init__(
        inout self,
        t_Tf: List[List[Float64]],
        t_Tb: List[List[Float64]],
        t_Rf: List[List[Float64]],
        t_Rb: List[List[Float64]],
        t_Hemisphere: CBSDFHemisphere,
        t_Range: FenestrationCommon.WavelengthRange
    ):
        CMaterial.__init__(self, t_Range)
        self.m_Hemisphere = t_Hemisphere
        self.m_Property = Dict[Tuple[FenestrationCommon.Property, FenestrationCommon.Side], List[List[Float64]]]()
        self.validateMatrix(t_Tf, self.m_Hemisphere)
        self.validateMatrix(t_Tb, self.m_Hemisphere)
        self.validateMatrix(t_Rf, self.m_Hemisphere)
        self.validateMatrix(t_Rb, self.m_Hemisphere)
        self.m_Property[(FenestrationCommon.Property.T, FenestrationCommon.Side.Front)] = t_Tf
        self.m_Property[(FenestrationCommon.Property.T, FenestrationCommon.Side.Back)] = t_Tb
        self.m_Property[(FenestrationCommon.Property.R, FenestrationCommon.Side.Front)] = t_Rf
        self.m_Property[(FenestrationCommon.Property.R, FenestrationCommon.Side.Back)] = t_Rb

    def calcDirectHemispheric(
        m: List[List[Float64]],
        hemisphere: CBSDFHemisphere,
        incomingIdx: Int
    ) -> Float64:
        let outgoingLambdas: List[Float64] = hemisphere.getDirections(BSDFDirection.Outgoing).lambdaVector()
        var result: Float64 = 0
        for outgoingIdx in range(outgoingLambdas.size):
            result += m[outgoingIdx][incomingIdx] * outgoingLambdas[outgoingIdx]
        return result

    def getProperty(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> Float64:
        let incomingIdx: Int = self.m_Hemisphere.getDirections(BSDFDirection.Incoming).getNearestBeamIndex(
            t_IncomingDirection.theta(), t_IncomingDirection.phi()
        )
        if t_Property == FenestrationCommon.Property.Abs:
            let tHem: Float64 = self.calcDirectHemispheric(
                self.m_Property[(FenestrationCommon.Property.T, t_Side)], self.m_Hemisphere, incomingIdx
            )
            let rHem: Float64 = self.calcDirectHemispheric(
                self.m_Property[(FenestrationCommon.Property.R, t_Side)], self.m_Hemisphere, incomingIdx
            )
            return 1 - tHem - rHem
        else:
            let outgoingIdx: Int = self.m_Hemisphere.getDirections(BSDFDirection.Outgoing).getNearestBeamIndex(
                t_OutgoingDirection.theta(), t_OutgoingDirection.phi()
            )
            let lambda: List[Float64] = self.m_Hemisphere.getDirections(BSDFDirection.Outgoing).lambdaVector()
            let val: Float64 = self.m_Property[(t_Property, t_Side)][outgoingIdx][incomingIdx]
            return val * lambda[outgoingIdx]

    def getBandProperties(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> List[Float64]:
        let value: Float64 = self.getProperty(t_Property, t_Side, t_IncomingDirection, t_OutgoingDirection)
        var bandProperties: List[Float64] = List[Float64](value, value)
        return bandProperties

    def getBSDFMatrix(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side
    ) -> List[List[Float64]]:
        return self.m_Property[(t_Property, t_Side)]

    def getHemisphere(self) -> CBSDFHemisphere:
        return self.m_Hemisphere

    def calculateBandWavelengths(self) -> List[Float64]:
        var aWavelengths: List[Float64] = List[Float64]()
        aWavelengths.append(self.m_MinLambda)
        aWavelengths.append(self.m_MaxLambda)
        return aWavelengths

    def validateMatrix(
        self,
        matrix: List[List[Float64]],
        hemisphere: CBSDFHemisphere
    ):
        let rowCt: Int = matrix.size
        let colCt: Int = matrix[0].size
        let hemisphereIncomingCt: Int = hemisphere.getDirections(BSDFDirection.Incoming).size
        let hemisphereOutgoingCt: Int = hemisphere.getDirections(BSDFDirection.Outgoing).size
        if rowCt != hemisphereIncomingCt:
            var msg: String = "Incompatible number of incoming directions.  BSDF matrix: << " + str(rowCt) + " BSDF Hemispere: " + str(hemisphereIncomingCt)
            raise Error(msg)
        if colCt != hemisphereOutgoingCt:
            var msg: String = "Incompatible number of incoming directions.  BSDF matrix: << " + str(colCt) + " BSDF Hemispere: " + str(hemisphereOutgoingCt)
            raise Error(msg)

class IMaterialDualBand(CMaterial):
    var m_MaterialFullRange: Pointer[CMaterial]
    var m_MaterialPartialRange: Pointer[CMaterial]
    var m_RangeCreator: fn() -> None
    var m_Materials: List[Pointer[CMaterial]]

    def __init__(
        inout self,
        t_PartialRange: Pointer[CMaterial],
        t_FullRange: Pointer[CMaterial],
        t_Ratio: Float64 = NIRRatio
    ):
        CMaterial.__init__(self, t_FullRange[].getMinLambda(), t_FullRange[].getMaxLambda())
        self.m_MaterialFullRange = t_FullRange
        self.m_MaterialPartialRange = t_PartialRange
        self.m_Materials = List[Pointer[CMaterial]]()
        self.m_RangeCreator = lambda: self.createRangesFromRatio(t_Ratio)

    def __init__(
        inout self,
        t_PartialRange: Pointer[CMaterial],
        t_FullRange: Pointer[CMaterial],
        t_SolarRadiation: Pointer[CSeries]
    ):
        CMaterial.__init__(self, t_FullRange[].getMinLambda(), t_FullRange[].getMaxLambda())
        self.m_MaterialFullRange = t_FullRange
        self.m_MaterialPartialRange = t_PartialRange
        self.m_Materials = List[Pointer[CMaterial]]()
        self.m_RangeCreator = lambda: self.createRangesFromSolarRadiation(t_SolarRadiation)

    def setSourceData(inout self, t_SourceData: Pointer[CSeries]):
        self.m_Materials.clear()
        self.m_MaterialFullRange[].setSourceData(t_SourceData)
        self.m_MaterialPartialRange[].setSourceData(t_SourceData)
        self.checkIfMaterialWithingSolarRange(self.m_MaterialPartialRange[])
        self.createUVRange()
        let lowLambda: Float64 = self.m_MaterialPartialRange[].getMinLambda()
        let highLambda: Float64 = self.m_MaterialPartialRange[].getMaxLambda()
        let nirRatio: CNIRRatio = CNIRRatio(t_SourceData, lowLambda, highLambda)
        self.createNIRRange(self.m_MaterialPartialRange, self.m_MaterialFullRange, NIRRatio)

    def setDetectorData(inout self, t_DetectorData: Pointer[CSeries]):
        self.m_MaterialFullRange[].setDetectorData(t_DetectorData)
        self.m_MaterialPartialRange[].setDetectorData(t_DetectorData)

    def getProperty(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> Float64:
        return self.m_MaterialFullRange[].getProperty(t_Property, t_Side, t_IncomingDirection, t_OutgoingDirection)

    def getBandProperties(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> List[Float64]:
        self.m_RangeCreator()
        var aResults: List[Float64] = List[Float64]()
        for wl in self.m_Wavelengths:
            aResults.append(self.getMaterialFromWavelegth(wl)[].getProperty(t_Property, t_Side, t_IncomingDirection, t_OutgoingDirection))
        return aResults

    def calculateBandWavelengths(self) -> List[Float64]:
        self.m_RangeCreator()
        var aWavelengths: List[Float64] = List[Float64]()
        let size: Int = self.m_Materials.size
        for i in range(size):
            aWavelengths.append(self.m_Materials[i][].getMinLambda())
        return aWavelengths

    def checkIfMaterialWithingSolarRange(self, t_Material: CMaterial):
        let lowLambda: Float64 = t_Material.getMinLambda()
        let highLambda: Float64 = t_Material.getMaxLambda()
        if lowLambda < 0.32 or highLambda < 0.32 or lowLambda > 2.5 or highLambda > 2.5:
            raise Error("Material properties out of range. Wavelength range must be between 0.32 and 2.5 microns.")

    def createUVRange(inout self):
        let T: Float64 = 0
        let R: Float64 = 0
        let minLambda: Float64 = 0.3
        let maxLambda: Float64 = 0.32
        var aUVMaterial: Pointer[CMaterial] = Pointer[CMaterialSingleBand](CMaterialSingleBand(T, T, R, R, minLambda, maxLambda))
        self.m_Materials.append(aUVMaterial)

    def createNIRRange(
        inout self,
        t_PartialRange: Pointer[CMaterial],
        t_SolarRange: Pointer[CMaterial],
        t_Fraction: Float64
    ):
        ...

    def createRangesFromRatio(inout self, t_Ratio: Float64):
        if not self.m_Materials.empty():
            return
        self.checkIfMaterialWithingSolarRange(self.m_MaterialPartialRange[])
        self.createUVRange()
        self.createNIRRange(self.m_MaterialPartialRange, self.m_MaterialFullRange, t_Ratio)
        if not self.m_WavelengthsCalculated:
            self.m_Wavelengths = self.getWavelengthsFromMaterials()
            self.m_WavelengthsCalculated = True

    def createRangesFromSolarRadiation(inout self, t_SolarRadiation: Pointer[CSeries]):
        if not self.m_Materials.empty():
            return
        self.checkIfMaterialWithingSolarRange(self.m_MaterialPartialRange[])
        self.createUVRange()
        let lowLambda: Float64 = self.m_MaterialPartialRange[].getMinLambda()
        let highLambda: Float64 = self.m_MaterialPartialRange[].getMaxLambda()
        let nirRatio: CNIRRatio = CNIRRatio(t_SolarRadiation, lowLambda, highLambda)
        self.createNIRRange(self.m_MaterialPartialRange, self.m_MaterialFullRange, NIRRatio)
        if not self.m_WavelengthsCalculated:
            self.m_Wavelengths = self.getWavelengthsFromMaterials()
            self.m_WavelengthsCalculated = True

    def getWavelengthsFromMaterials(self) -> List[Float64]:
        var result: List[Float64] = List[Float64]()
        if self.m_MaterialFullRange is not None and self.m_MaterialPartialRange is not None:
            result.append(self.m_MaterialFullRange[].getMinLambda())
            result.append(0.32)
            result.append(self.m_MaterialPartialRange[].getMinLambda())
            result.append(self.m_MaterialPartialRange[].getMaxLambda())
            result.append(self.m_MaterialFullRange[].getMaxLambda())
        return result

    def getMaterialFromWavelegth(self, wavelength: Float64) -> Pointer[CMaterial]:
        var result: Pointer[CMaterial] = Pointer[CMaterial]()
        for material in self.m_Materials:
            if material[].isWavelengthInRange(wavelength):
                result = material
        return result

class CMaterialDualBand(IMaterialDualBand):
    def __init__(
        inout self,
        t_PartialRange: Pointer[CMaterial],
        t_FullRange: Pointer[CMaterial],
        t_Ratio: Float64 = NIRRatio
    ):
        IMaterialDualBand.__init__(self, t_PartialRange, t_FullRange, t_Ratio)

    def __init__(
        inout self,
        t_PartialRange: Pointer[CMaterial],
        t_FullRange: Pointer[CMaterial],
        t_SolarRadiation: Pointer[CSeries]
    ):
        IMaterialDualBand.__init__(self, t_PartialRange, t_FullRange, t_SolarRadiation)

    def createNIRRange(
        inout self,
        t_PartialRange: Pointer[CMaterial],
        t_FullRange: Pointer[CMaterial],
        t_Fraction: Float64
    ):
        let materials: List[Pointer[CMaterial]] = SingleLayerOptics.createNIRRange(t_PartialRange, t_FullRange, t_Fraction)
        for material in materials:
            self.m_Materials.append(material)

class CMaterialDualBandBSDF(IMaterialDualBand):
    def __init__(
        inout self,
        t_PartialRange: Pointer[CMaterialSingleBandBSDF],
        t_FullRange: Pointer[CMaterialSingleBandBSDF],
        t_Ratio: Float64 = NIRRatio
    ):
        IMaterialDualBand.__init__(self, t_PartialRange, t_FullRange, t_Ratio)

    def __init__(
        inout self,
        t_PartialRange: Pointer[CMaterialSingleBandBSDF],
        t_FullRange: Pointer[CMaterialSingleBandBSDF],
        t_SolarRadiation: Pointer[CSeries]
    ):
        IMaterialDualBand.__init__(self, t_PartialRange, t_FullRange, t_SolarRadiation)

    def createNIRRange(
        inout self,
        t_PartialRange: Pointer[CMaterial],
        t_SolarRange: Pointer[CMaterial],
        t_Fraction: Float64
    ):
        let materials: List[Pointer[CMaterial]] = SingleLayerOptics.createNIRRange(
            Pointer[CMaterialSingleBandBSDF](t_PartialRange),
            Pointer[CMaterialSingleBandBSDF](t_SolarRange),
            t_Fraction
        )
        for material in materials:
            self.m_Materials.append(material)

class CMaterialSample(CMaterial):
    var m_AngularSample: Pointer[CAngularSpectralSample]

    def __init__(
        inout self,
        t_SpectralSample: Pointer[CSpectralSample],
        t_Thickness: Float64,
        t_Type: FenestrationCommon.MaterialType,
        minLambda: Float64,
        maxLambda: Float64
    ):
        CMaterial.__init__(self, minLambda, maxLambda)
        if t_SpectralSample is None:
            raise Error("Cannot create specular material from non-existing sample.")
        self.m_AngularSample = Pointer[CAngularSpectralSample](CAngularSpectralSample(t_SpectralSample, t_Thickness, t_Type))

    def __init__(
        inout self,
        t_SpectralSample: Pointer[CSpectralSample],
        t_Thickness: Float64,
        t_Type: FenestrationCommon.MaterialType,
        t_Range: FenestrationCommon.WavelengthRange
    ):
        CMaterial.__init__(self, t_Range)
        if t_SpectralSample is None:
            raise Error("Cannot create specular material from non-existing sample.")
        self.m_AngularSample = Pointer[CAngularSpectralSample](CAngularSpectralSample(t_SpectralSample, t_Thickness, t_Type))

    def setSourceData(inout self, t_SourceData: Pointer[CSeries]):
        self.m_AngularSample[].setSourceData(t_SourceData)

    def setDetectorData(inout self, t_DetectorData: Pointer[CSeries]):
        self.m_AngularSample[].setDetectorData(t_DetectorData)

    def getProperty(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> Float64:
        assert self.m_AngularSample is not None
        return self.m_AngularSample[].getProperty(
            self.m_MinLambda, self.m_MaxLambda, t_Property, t_Side, t_IncomingDirection.theta()
        )

    def getBandProperties(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> List[Float64]:
        assert self.m_AngularSample is not None
        return self.m_AngularSample[].getWavelengthsProperty(
            self.m_MinLambda, self.m_MaxLambda, t_Property, t_Side, t_IncomingDirection.theta()
        )

    def calculateBandWavelengths(self) -> List[Float64]:
        return self.m_AngularSample[].getBandWavelengths()

    def setBandWavelengths(inout self, wavelengths: List[Float64]):
        CMaterial.setBandWavelengths(self, wavelengths)
        self.m_AngularSample[].setBandWavelengths(self.m_Wavelengths)
        self.m_WavelengthsCalculated = True

    def Flipped(inout self, flipped: Bool):
        self.m_AngularSample[].Flipped(flipped)

class CMaterialPhotovoltaic(CMaterialSample):
    var m_PVSample: Pointer[CPhotovoltaicSample]

    def __init__(
        inout self,
        t_SpectralSample: Pointer[CPhotovoltaicSample],
        t_Thickness: Float64,
        t_Type: FenestrationCommon.MaterialType,
        minLambda: Float64,
        maxLambda: Float64
    ):
        CMaterialSample.__init__(self, t_SpectralSample, t_Thickness, t_Type, minLambda, maxLambda)
        self.m_PVSample = t_SpectralSample

    def __init__(
        inout self,
        t_SpectralSample: Pointer[CPhotovoltaicSample],
        t_Thickness: Float64,
        t_Type: FenestrationCommon.MaterialType,
        t_Range: FenestrationCommon.WavelengthRange
    ):
        CMaterialSample.__init__(self, t_SpectralSample, t_Thickness, t_Type, t_Range)
        self.m_PVSample = t_SpectralSample

    def jscPrime(self, t_Side: FenestrationCommon.Side) -> Pointer[CSeries]:
        return self.m_PVSample[].jscPrime(t_Side)

class CMaterialMeasured(CMaterial):
    var m_AngularMeasurements: Pointer[CAngularMeasurements]

    def __init__(
        inout self,
        t_AngularMeasurements: Pointer[CAngularMeasurements],
        minLambda: Float64,
        maxLambda: Float64
    ):
        CMaterial.__init__(self, minLambda, maxLambda)
        self.m_AngularMeasurements = t_AngularMeasurements
        if t_AngularMeasurements is None:
            raise Error("Cannot create specular and angular material from non-existing sample.")

    def __init__(
        inout self,
        t_AngularMeasurements: Pointer[CAngularMeasurements],
        t_Range: FenestrationCommon.WavelengthRange
    ):
        CMaterial.__init__(self, t_Range)
        self.m_AngularMeasurements = t_AngularMeasurements
        if t_AngularMeasurements is None:
            raise Error("Cannot create specular and angular material from non-existing sample.")

    def setSourceData(inout self, t_SourceData: Pointer[CSeries]):
        self.m_AngularMeasurements[].setSourceData(t_SourceData)

    def getProperty(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> Float64:
        assert self.m_AngularMeasurements is not None
        let aAngular: Pointer[CSingleAngularMeasurement] = self.m_AngularMeasurements[].getMeasurements(t_IncomingDirection.theta())
        let aSample: Pointer[CSpectralSample] = aAngular[].getData()
        return aSample[].getProperty(self.m_MinLambda, self.m_MaxLambda, t_Property, t_Side)

    def getBandProperties(
        self,
        t_Property: FenestrationCommon.Property,
        t_Side: FenestrationCommon.Side,
        t_IncomingDirection: CBeamDirection = CBeamDirection(),
        t_OutgoingDirection: CBeamDirection = CBeamDirection()
    ) -> List[Float64]:
        assert self.m_AngularMeasurements is not None
        let aAngular: Pointer[CSingleAngularMeasurement] = self.m_AngularMeasurements[].getMeasurements(t_IncomingDirection.theta())
        let aSample: Pointer[CSpectralSample] = aAngular[].getData()
        let aProperties: List[Pointer[CSeries]] = aSample[].getWavelengthsProperty(t_Property, t_Side)
        var aValues: List[Float64] = List[Float64]()
        for aProperty in aProperties:
            if aProperty[].x() >= self.m_MinLambda and aProperty[].x() <= self.m_MaxLambda:
                aValues.append(aProperty[].value())
        return aValues

    def calculateBandWavelengths(self) -> List[Float64]:
        let aAngular: CSingleAngularMeasurement = self.m_AngularMeasurements[].getMeasurements(0.0)[]
        let aSample: Pointer[CSpectralSample] = aAngular.getData()
        return aSample[].getWavelengthsFromSample()
from memory import shared_ptr, make_shared
from WCECommon import *
from MaterialDescription import *
from WCESpectralAveraging import *
from SpectralAveraging import CSpectralSampleData, PhotovoltaicSampleData
from SingleLayerOptics import CMaterial, CMaterialPhotovoltaic, CBSDFHemisphere

using FenestrationCommon.WavelengthRange
using FenestrationCommon.CWavelengthRange
using FenestrationCommon.CSeries
using SpectralAveraging.CSpectralSample
using SpectralAveraging.CPhotovoltaicSample

@staticmethod
def dualBandMaterial(
    Tfsol: Float64,
    Tbsol: Float64,
    Rfsol: Float64,
    Rbsol: Float64,
    Tfvis: Float64,
    Tbvis: Float64,
    Rfvis: Float64,
    Rbvis: Float64
) -> shared_ptr[CMaterial]:
    var aSolarRangeMaterial = make_shared[CMaterialSingleBand](Tfsol, Tbsol, Rfsol, Rbsol, WavelengthRange.Solar)
    var aVisibleRangeMaterial = make_shared[CMaterialSingleBand](Tfvis, Tbvis, Rfvis, Rbvis, WavelengthRange.Visible)
    return make_shared[CMaterialDualBand](aVisibleRangeMaterial, aSolarRangeMaterial)

@staticmethod
def dualBandMaterial(
    Tfsol: Float64,
    Tbsol: Float64,
    Rfsol: Float64,
    Rbsol: Float64,
    Tfvis: Float64,
    Tbvis: Float64,
    Rfvis: Float64,
    Rbvis: Float64,
    ratio: Float64
) -> shared_ptr[CMaterial]:
    var aSolarRangeMaterial = make_shared[CMaterialSingleBand](Tfsol, Tbsol, Rfsol, Rbsol, WavelengthRange.Solar)
    var aVisibleRangeMaterial = make_shared[CMaterialSingleBand](Tfvis, Tbvis, Rfvis, Rbvis, WavelengthRange.Visible)
    return make_shared[CMaterialDualBand](aVisibleRangeMaterial, aSolarRangeMaterial, ratio)

@staticmethod
def dualBandMaterial(
    Tfsol: Float64,
    Tbsol: Float64,
    Rfsol: Float64,
    Rbsol: Float64,
    Tfvis: Float64,
    Tbvis: Float64,
    Rfvis: Float64,
    Rbvis: Float64,
    solarRadiation: CSeries
) -> shared_ptr[CMaterial]:
    var aSolarRangeMaterial = make_shared[CMaterialSingleBand](Tfsol, Tbsol, Rfsol, Rbsol, WavelengthRange.Solar)
    var aVisibleRangeMaterial = make_shared[CMaterialSingleBand](Tfvis, Tbvis, Rfvis, Rbvis, WavelengthRange.Visible)
    return make_shared[CMaterialDualBand](aVisibleRangeMaterial, aSolarRangeMaterial, solarRadiation)

@staticmethod
def dualBandBSDFMaterial(
    Tfsol: List[List[Float64]],
    Tbsol: List[List[Float64]],
    Rfsol: List[List[Float64]],
    Rbsol: List[List[Float64]],
    Tfvis: List[List[Float64]],
    Tbvis: List[List[Float64]],
    Rfvis: List[List[Float64]],
    Rbvis: List[List[Float64]],
    hemisphere: CBSDFHemisphere,
    ratio: Float64
) -> shared_ptr[CMaterial]:
    var aSolarRangeMaterial = make_shared[CMaterialSingleBandBSDF](Tfsol, Tbsol, Rfsol, Rbsol, hemisphere, WavelengthRange.Solar)
    var aVisibleRangeMaterial = make_shared[CMaterialSingleBandBSDF](Tfvis, Tbvis, Rfvis, Rbvis, hemisphere, WavelengthRange.Visible)
    return make_shared[CMaterialDualBandBSDF](aVisibleRangeMaterial, aSolarRangeMaterial, ratio)

@staticmethod
def dualBandBSDFMaterial(
    Tfsol: List[List[Float64]],
    Tbsol: List[List[Float64]],
    Rfsol: List[List[Float64]],
    Rbsol: List[List[Float64]],
    Tfvis: List[List[Float64]],
    Tbvis: List[List[Float64]],
    Rfvis: List[List[Float64]],
    Rbvis: List[List[Float64]],
    hemisphere: CBSDFHemisphere,
    solarRadiation: FenestrationCommon.CSeries
) -> shared_ptr[CMaterial]:
    var aSolarRangeMaterial = make_shared[CMaterialSingleBandBSDF](Tfsol, Tbsol, Rfsol, Rbsol, hemisphere, WavelengthRange.Solar)
    var aVisibleRangeMaterial = make_shared[CMaterialSingleBandBSDF](Tfvis, Tbvis, Rfvis, Rbvis, hemisphere, WavelengthRange.Visible)
    return make_shared[CMaterialDualBandBSDF](aVisibleRangeMaterial, aSolarRangeMaterial, solarRadiation)

@staticmethod
def singleBandMaterial(
    Tf: Float64,
    Tb: Float64,
    Rf: Float64,
    Rb: Float64,
    minLambda: Float64,
    maxLambda: Float64
) -> shared_ptr[CMaterial]:
    return make_shared[CMaterialSingleBand](Tf, Tb, Rf, Rb, minLambda, maxLambda)

@staticmethod
def singleBandMaterial(
    Tf: Float64,
    Tb: Float64,
    Rf: Float64,
    Rb: Float64,
    range: FenestrationCommon.WavelengthRange
) -> shared_ptr[CMaterial]:
    return make_shared[CMaterialSingleBand](Tf, Tb, Rf, Rb, range)

@staticmethod
def nBandMaterial(
    measurement: shared_ptr[SpectralAveraging.CSpectralSampleData],
    thickness: Float64,
    materialType: FenestrationCommon.MaterialType,
    range: FenestrationCommon.WavelengthRange,
    integrationType: FenestrationCommon.IntegrationType = FenestrationCommon.IntegrationType.Trapezoidal,
    normalizationCoefficient: Float64 = 1
) -> shared_ptr[CMaterial]:
    var aSample = make_shared[CSpectralSample](measurement, CSeries(), integrationType, normalizationCoefficient)
    var wlRange = CWavelengthRange(range)
    var minLambda = wlRange.minLambda()
    var maxLambda = wlRange.maxLambda()
    var sampleWls = measurement.getWavelengths()
    var minSample = sampleWls[0]
    var maxSample = sampleWls[sampleWls.size() - 1]
    if minLambda < minSample:
        minLambda = minSample
    if maxLambda > maxSample:
        maxLambda = maxSample
    aSample.cutExtraData(minLambda, maxLambda)
    if aSample.getWavelengthsFromSample().empty():
        raise Error("Given measured sample does not have measurements withing requested range. Calculation is not possible.")
    return make_shared[CMaterialSample](aSample, thickness, materialType, minLambda, maxLambda)

@staticmethod
def nBandMaterial(
    measurement: shared_ptr[SpectralAveraging.CSpectralSampleData],
    thickness: Float64,
    materialType: FenestrationCommon.MaterialType,
    minLambda: Float64,
    maxLambda: Float64,
    integrationType: FenestrationCommon.IntegrationType = FenestrationCommon.IntegrationType.Trapezoidal,
    normalizationCoefficient: Float64 = 1
) -> shared_ptr[CMaterial]:
    var aSample = make_shared[CSpectralSample](measurement, CSeries(), integrationType, normalizationCoefficient)
    aSample.cutExtraData(minLambda, maxLambda)
    if aSample.getWavelengthsFromSample().empty():
        raise Error("Given measured sample does not have measurements withing requested range. Calculation is not possible.")
    return make_shared[CMaterialSample](aSample, thickness, materialType, minLambda, maxLambda)

@staticmethod
def nBandMaterial(
    measurement: shared_ptr[SpectralAveraging.CSpectralSampleData],
    detectorData: CSeries,
    thickness: Float64,
    materialType: FenestrationCommon.MaterialType,
    minLambda: Float64,
    maxLambda: Float64,
    integrationType: FenestrationCommon.IntegrationType = FenestrationCommon.IntegrationType.Trapezoidal,
    normalizationCoefficient: Float64 = 1
) -> shared_ptr[CMaterial]:
    var aSample = make_shared[CSpectralSample](measurement, CSeries(), integrationType, normalizationCoefficient)
    aSample.setDetectorData(detectorData)
    aSample.cutExtraData(minLambda, maxLambda)
    if aSample.getWavelengthsFromSample().empty():
        raise Error("Given measured sample does not have measurements withing requested range. Calculation is not possible.")
    return make_shared[CMaterialSample](aSample, thickness, materialType, minLambda, maxLambda)

@staticmethod
def nBandMaterial(
    measurement: shared_ptr[SpectralAveraging.CSpectralSampleData],
    detectorData: CSeries,
    thickness: Float64,
    materialType: FenestrationCommon.MaterialType,
    t_Range: FenestrationCommon.WavelengthRange,
    integrationType: FenestrationCommon.IntegrationType = FenestrationCommon.IntegrationType.Trapezoidal,
    normalizationCoefficient: Float64 = 1
) -> shared_ptr[CMaterial]:
    var aSample = make_shared[CSpectralSample](measurement, CSeries(), integrationType, normalizationCoefficient)
    var wlRange = CWavelengthRange(t_Range)
    var minLambda = wlRange.minLambda()
    var maxLambda = wlRange.maxLambda()
    var sampleWls = measurement.getWavelengths()
    var minSample = sampleWls[0]
    var maxSample = sampleWls[sampleWls.size() - 1]
    if minLambda < minSample:
        minLambda = minSample
    if maxLambda > maxSample:
        maxLambda = maxSample
    aSample.cutExtraData(minLambda, maxLambda)
    if aSample.getWavelengthsFromSample().empty():
        raise Error("Given measured sample does not have measurements withing requested range. Calculation is not possible.")
    aSample.setDetectorData(detectorData)
    return make_shared[CMaterialSample](aSample, thickness, materialType, t_Range)

@staticmethod
def nBandPhotovoltaicMaterial(
    measurement: shared_ptr[SpectralAveraging.PhotovoltaicSampleData],
    thickness: Float64,
    materialType: FenestrationCommon.MaterialType,
    minLambda: Float64,
    maxLambda: Float64,
    integrationType: FenestrationCommon.IntegrationType = FenestrationCommon.IntegrationType.Trapezoidal,
    normalizationCoefficient: Float64 = 1
) -> shared_ptr[CMaterialPhotovoltaic]:
    var aSample = make_shared[SpectralAveraging.CPhotovoltaicSample](measurement, CSeries(), integrationType, normalizationCoefficient)
    aSample.cutExtraData(minLambda, maxLambda)
    if aSample.getWavelengthsFromSample().empty():
        raise Error("Given measured sample does not have measurements withing requested range. Calculation is not possible.")
    return make_shared[CMaterialPhotovoltaic](aSample, thickness, materialType, minLambda, maxLambda)

@staticmethod
def nBandPhotovoltaicMaterial(
    measurement: shared_ptr[SpectralAveraging.PhotovoltaicSampleData],
    thickness: Float64,
    materialType: FenestrationCommon.MaterialType,
    range: FenestrationCommon.WavelengthRange,
    integrationType: FenestrationCommon.IntegrationType = FenestrationCommon.IntegrationType.Trapezoidal,
    normalizationCoefficient: Float64 = 1
) -> shared_ptr[CMaterialPhotovoltaic]:
    var wlRange = CWavelengthRange(range)
    var minLambda = wlRange.minLambda()
    var maxLambda = wlRange.maxLambda()
    return nBandPhotovoltaicMaterial(measurement, thickness, materialType, minLambda, maxLambda, integrationType, normalizationCoefficient)
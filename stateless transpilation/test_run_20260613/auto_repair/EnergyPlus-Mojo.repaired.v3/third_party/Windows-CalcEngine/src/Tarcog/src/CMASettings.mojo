from WCECommon import ConstantsData
from CMAInterface import Option
from memory import memset_zero
from math import pow, abs, max
from limits import max as numeric_limits_max

@value
struct CMABestWorstUFactors:
    var m_Hci: Float64
    var m_Hco: Float64
    var m_GapConductance: Float64
    var m_InteriorGlassThickness: Float64
    var m_InteriorGlassConductivity: Float64
    var m_InteriorGlassSurfaceEmissivity: Float64
    var m_ExteriorGlassThickness: Float64
    var m_ExteriorGlassConductivity: Float64
    var m_ExteriorGlassSurfaceEmissivity: Float64
    var m_InsideAirTemperature: Float64
    var m_OutsideAirTemperature: Float64
    var m_Hri: Float64
    var m_Hro: Float64
    var m_Calculated: Bool

    def __init__(inout self, hci: Float64, hco: Float64, gapConductance: Float64):
        self.m_Hci = hci
        self.m_Hco = hco
        self.m_GapConductance = gapConductance
        self.m_InteriorGlassThickness = 0.006
        self.m_InteriorGlassConductivity = 1
        self.m_InteriorGlassSurfaceEmissivity = 0.84
        self.m_ExteriorGlassThickness = 0.006
        self.m_ExteriorGlassConductivity = 1
        self.m_ExteriorGlassSurfaceEmissivity = 0.84
        self.m_InsideAirTemperature = 21
        self.m_OutsideAirTemperature = -18
        self.m_Hri = 0
        self.m_Hro = 0
        self.m_Calculated = False

    def __init__(inout self,
                hci: Float64,
                hco: Float64,
                gapConductance: Float64,
                interiorGlassThickness: Float64,
                interiorGlassConductivity: Float64,
                interiorGlassSurfaceEmissivity: Float64,
                exteriorGlassThickness: Float64,
                exteriorGlassConductivity: Float64,
                exteriorGlassSurfaceEmissivity: Float64,
                insideAirTemperature: Float64,
                outsideAirTemperature: Float64):
        self.m_Hci = hci
        self.m_Hco = hco
        self.m_GapConductance = gapConductance
        self.m_InteriorGlassThickness = interiorGlassThickness
        self.m_InteriorGlassConductivity = interiorGlassConductivity
        self.m_InteriorGlassSurfaceEmissivity = interiorGlassSurfaceEmissivity
        self.m_ExteriorGlassThickness = exteriorGlassThickness
        self.m_ExteriorGlassConductivity = exteriorGlassConductivity
        self.m_ExteriorGlassSurfaceEmissivity = exteriorGlassSurfaceEmissivity
        self.m_InsideAirTemperature = insideAirTemperature
        self.m_OutsideAirTemperature = outsideAirTemperature
        self.m_Hri = 0
        self.m_Hro = 0
        self.m_Calculated = False

    def uValue(inout self) -> Float64:
        assert(self.m_InsideAirTemperature != self.m_OutsideAirTemperature)
        self.caluculate()
        return self.heatFlow(self.m_Hri, self.m_Hro) / (self.m_InsideAirTemperature - self.m_OutsideAirTemperature)

    def hcout(inout self) -> Float64:
        self.caluculate()
        return self.m_Hco

    def heatFlow(self, interiorRadiationFilmCoefficient: Float64, exteriorRadiationFilmCoefficient: Float64) -> Float64:
        var deltaTemp: Float64 = self.m_InsideAirTemperature - self.m_OutsideAirTemperature
        var interiorGlassCond: Float64 = self.m_InteriorGlassConductivity / self.m_InteriorGlassThickness
        var exteriorGlassCond: Float64 = self.m_ExteriorGlassConductivity / self.m_ExteriorGlassThickness
        return deltaTemp / (1.0 / interiorGlassCond + 1.0 / exteriorGlassCond + 1.0 / self.m_GapConductance + 1.0 / (self.m_Hci + interiorRadiationFilmCoefficient) + 1.0 / (self.m_Hco + exteriorRadiationFilmCoefficient))

    def hrout(self, surfaceTemperature: Float64) -> Float64:
        return self.m_ExteriorGlassSurfaceEmissivity * ConstantsData.STEFANBOLTZMANN * (pow(surfaceTemperature + ConstantsData.KELVINCONV, 4) - pow(self.m_OutsideAirTemperature + ConstantsData.KELVINCONV, 4)) / (surfaceTemperature - self.m_OutsideAirTemperature)

    def hrin(self, surfaceTemperature: Float64) -> Float64:
        return self.m_InteriorGlassSurfaceEmissivity * ConstantsData.STEFANBOLTZMANN * (pow(self.m_InsideAirTemperature + ConstantsData.KELVINCONV, 4) - pow(surfaceTemperature + ConstantsData.KELVINCONV, 4)) / (self.m_InsideAirTemperature - surfaceTemperature)

    def insideSurfaceTemperature(self, interiorRadiationFilmCoefficient: Float64) -> Float64:
        return self.m_InsideAirTemperature - self.heatFlow(interiorRadiationFilmCoefficient, self.m_Hro) / (self.m_Hci + interiorRadiationFilmCoefficient)

    def outsideSurfaceTemperature(self, exteriorRadiationFilmCoefficient: Float64) -> Float64:
        return self.m_OutsideAirTemperature + self.heatFlow(self.m_Hri, exteriorRadiationFilmCoefficient) / (self.m_Hco + exteriorRadiationFilmCoefficient)

    def caluculate(inout self):
        if not self.m_Calculated:
            var insideTemperature: Float64 = 0.25 * (self.m_InsideAirTemperature - self.m_OutsideAirTemperature) + self.m_OutsideAirTemperature
            var outsideTemperature: Float64 = self.m_InsideAirTemperature - 0.25 * (self.m_InsideAirTemperature - self.m_OutsideAirTemperature)
            var hri: Float64 = self.hrin(insideTemperature)
            var hro: Float64 = self.hrout(outsideTemperature)
            var error: Float64 = numeric_limits_max[Float64]()
            var errorTolerance: Float64 = 1e-2
            while error > errorTolerance:
                var previousInside: Float64 = insideTemperature
                insideTemperature = self.insideSurfaceTemperature(hri)
                var previousOutside: Float64 = outsideTemperature
                outsideTemperature = self.outsideSurfaceTemperature(hro)
                hri = self.hrin(insideTemperature)
                hro = self.hrout(outsideTemperature)
                error = max(abs(previousInside - insideTemperature), abs(previousOutside - outsideTemperature))
            self.m_Hri = hri
            self.m_Hro = hro
            self.m_Calculated = True

def CreateBestWorstUFactorOption(option: Option) -> CMABestWorstUFactors:
    var defaultInsideFilmCofficintBest: Float64 = 1.85425
    var defaultOutsideFilmCoefficientBest: Float64 = 26
    var defaultGapConductanceBest: Float64 = 0.498817
    var defaultInsideFilmCofficintWorst: Float64 = 2.86612
    var defaultOutsideFilmCoefficientWorst: Float64 = 26
    var defaultGapConductanceWorst: Float64 = 5.880546
    var object: Dict[Option, CMABestWorstUFactors] = Dict[Option, CMABestWorstUFactors]()
    object[Option.Best] = CMABestWorstUFactors(defaultInsideFilmCofficintBest, defaultOutsideFilmCoefficientBest, defaultGapConductanceBest)
    object[Option.Worst] = CMABestWorstUFactors(defaultInsideFilmCofficintWorst, defaultOutsideFilmCoefficientWorst, defaultGapConductanceWorst)
    return object[option]
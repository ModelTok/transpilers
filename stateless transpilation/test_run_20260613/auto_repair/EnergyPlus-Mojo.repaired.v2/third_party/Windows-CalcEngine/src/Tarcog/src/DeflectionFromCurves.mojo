from ...WCECommon import ConstantsData, Table, DeflectionData, tableColumnInterpolation
from ...WCETarcog import MaterialConstants, DeflectionConstants

# Constants (from DeflectionFromCurves.hpp)
let defaultGlassDensity: F64 = MaterialConstants.GLASSDENSITY  # kg/m3
let defaultPressure: F64 = 101325.0  # Pa
let defaultModulusOfElasticity: F64 = DeflectionConstants.YOUNGSMODULUS  # Pa

struct LayerData:
    var thickness: F64  # mm
    var density: F64  # kg/m3
    var modulusOfElasticity: F64  # KPa

    def __init__(inout self, thickness: F64, density: F64 = defaultGlassDensity, modulusOfElasticity: F64 = defaultModulusOfElasticity):
        self.thickness = thickness * 1000.0
        self.density = density
        self.modulusOfElasticity = modulusOfElasticity / 1000.0

struct GapData:
    var thickness: F64  # mm
    var initialTemperature: F64  # Kelvin
    var initialPressure: F64  # KPa

    def __init__(inout self, thickness: F64, initialTemperature: F64, initialPressure: F64 = defaultPressure):
        self.thickness = thickness * 1000.0
        self.initialTemperature = initialTemperature
        self.initialPressure = initialPressure / 1000.0

struct DeflectionResults:
    var error: Optional[F64]
    var deflection: List[F64]
    var paneLoad: List[F64]

    def __init__(inout self):
        self.error = Some(0.0)
        self.deflection = List[F64]()
        self.paneLoad = List[F64]()

    def __init__(inout self, error: Optional[F64], deflection: List[F64], pressureDifference: List[F64]):
        self.error = error
        self.deflection = deflection
        self.paneLoad = pressureDifference

struct DeflectionE1300:
    var m_ExteriorPressure: F64
    var m_InteriorPressure: F64
    var m_LongDimension: F64  # mm
    var m_ShortDimension: F64  # mm
    var m_Theta: F64  # degrees
    var m_Layer: List[LayerData]
    var m_Gap: List[GapData]
    var m_LoadTemperature: List[F64]
    var m_AppliedLoad: List[F64]
    var m_SelfWeight: List[F64]
    var m_PsLoaded: List[F64]
    var m_Pcs: List[F64]
    var m_Vcs: List[F64]
    var m_PnVns: List[Table.point]
    var m_PnWns: List[Table.point]
    var m_ResultsCalculated: Bool
    var m_DeflectionResults: DeflectionResults

    def __init__(inout self, width: F64, height: F64, layer: List[LayerData], gap: List[GapData]):
        self.m_LongDimension = (width if width > height else height) * 1000.0
        self.m_ShortDimension = (height if width > height else width) * 1000.0
        self.m_Layer = layer
        self.m_Gap = gap
        self.m_Theta = 90.0
        self.m_ExteriorPressure = defaultPressure / 1000.0
        self.m_InteriorPressure = defaultPressure / 1000.0
        self.m_LoadTemperature = List[F64]()
        self.m_AppliedLoad = List[F64]()
        self.m_SelfWeight = List[F64]()
        self.m_PsLoaded = getPsLoaded(self.m_Layer, self.m_Theta)  # Note: uses self.m_AppliedLoad which is empty
        self.m_Pcs = calcPcs(self.m_ShortDimension, self.m_Layer)
        self.m_Vcs = calcVcs(self.m_ShortDimension, self.m_Layer)
        self.m_PnVns = Table.columnInterpolation(DeflectionData.getVNData(), self.m_LongDimension / self.m_ShortDimension)
        self.m_PnWns = Table.columnInterpolation(DeflectionData.getWNData(), self.m_LongDimension / self.m_ShortDimension)
        for val in self.m_PnVns:
            if val.x:
                val.x = exp(val.x.value())
            if val.y:
                val.y = exp(val.y.value())
        self.m_PnVns.insert(0, Table.point(Some(0.0), Some(0.0)))
        for val in self.m_PnWns:
            if val.x:
                val.x = exp(val.x.value())
            if val.y:
                val.y = exp(val.y.value())
        self.m_PnWns.insert(0, Table.point(Some(0.0), Some(0.0)))
        self.m_ResultsCalculated = False
        self.m_DeflectionResults = DeflectionResults()

    def setExteriorPressure(inout self, pressure: F64):
        self.m_ExteriorPressure = pressure / 1000.0
        self.m_PsLoaded = getPsLoaded(self.m_Layer, self.m_Theta)
        self.m_ResultsCalculated = False

    def setInteriorPressure(inout self, pressure: F64):
        self.m_InteriorPressure = pressure / 1000.0
        self.m_PsLoaded = getPsLoaded(self.m_Layer, self.m_Theta)
        self.m_ResultsCalculated = False

    def setIGUTilt(inout self, theta: F64):
        self.m_Theta = theta
        self.m_PsLoaded = getPsLoaded(self.m_Layer, self.m_Theta)
        self.m_ResultsCalculated = False

    def setDimensions(inout self, width: F64, height: F64):
        self.m_LongDimension = (width if width > height else height) * 1000.0
        self.m_ShortDimension = (height if width > height else width) * 1000.0
        self.m_PsLoaded = getPsLoaded(self.m_Layer, self.m_Theta)
        self.m_ResultsCalculated = False

    def setAppliedLoad(inout self, appliedLoad: List[F64]):
        var loads = appliedLoad
        for i in range(len(loads)):
            loads[i] = loads[i] / 1000.0
        self.m_AppliedLoad = loads
        self.m_PsLoaded = getPsLoaded(self.m_Layer, self.m_Theta)
        self.m_ResultsCalculated = False

    def setLoadTemperatures(inout self, loadTemperature: List[F64]):
        self.m_LoadTemperature = loadTemperature
        self.m_ResultsCalculated = False

    @staticmethod
    def getPsWeight(layer: List[LayerData], theta: F64) -> List[F64]:
        var result = List[F64]()
        let pi = atan(1.0) * 4.0
        for lay in layer:
            result.append(lay.thickness / 1000.0 * lay.density * ConstantsData.GRAVITYCONSTANT / 1000.0 * cos((theta * pi) / 180.0))
        return result

    def getPsLoaded(self, layer: List[LayerData], theta: F64) -> List[F64]:
        var result = DeflectionE1300.getPsWeight(layer, theta)
        if len(self.m_AppliedLoad) == len(result):
            for i in range(len(result)):
                result[i] = result[i] + self.m_AppliedLoad[i]
        result[0] = result[0] + self.m_ExteriorPressure
        result[len(result) - 1] = result[len(result) - 1] + self.m_InteriorPressure
        return result

    @staticmethod
    def calcPcs(shortDimension: F64, layer: List[LayerData]) -> List[F64]:
        var result = List[F64]()
        for lay in layer:
            result.append(pow(shortDimension / (2.0 * lay.thickness), 4.0) / lay.modulusOfElasticity)
        return result

    @staticmethod
    def calcVcs(shortDimension: F64, layer: List[LayerData]) -> List[F64]:
        var result = List[F64]()
        for lay in layer:
            result.append(1.0 / (lay.thickness * pow(shortDimension / 2.0, 2.0)))
        return result

    def results(inout self) -> DeflectionResults:
        if not self.m_ResultsCalculated:
            self.m_DeflectionResults = self.calculateResults()
            self.m_ResultsCalculated = True
        return self.m_DeflectionResults

    @staticmethod
    def DP1pGuess(Pdiff: F64, layer: List[LayerData]) -> F64:
        var result = 0.01
        if Pdiff != 0.0:
            var sum = 0.0
            for lay in layer:
                sum = sum + pow(lay.thickness, 3.0)
            result = Pdiff * (pow(layer[0].thickness, 3.0) / sum)
        return result

    def nIGU_Li(self, index: Int, PasiLoaded: F64, dpCoeff: F64) -> DeflectionResults:
        var DPs = List[F64]()
        let j = index + 1
        let DPni = dpCoeff * self.m_Pcs[index]
        let si = 1.0 if DPni > 0.0 else -1.0
        var Vi = 0.0
        let val1 = tableColumnInterpolation(self.m_PnVns, DPni * si, Table.Extrapolate.Yes)
        if val1:
            Vi = val1.value() / self.m_Vcs[index] * si
        let Pai = self.m_PsLoaded[index] + PasiLoaded - dpCoeff
        var Err0: Optional[F64] = None
        if index != len(self.m_Gap) - 1:
            let DPjp = dpCoeff / 2.0
            let DPjc = DPjp * 1.05
            let Defp = self.nIGU_Li(j, Pai, DPjp)
            let Defc = self.nIGU_Li(j, Pai, DPjc)
            if not Defp.error or not Defc.error:
                Err0 = Defc.error
            else:
                var Errx = Defc.error.value()
                var IterCnt = 0
                var DPjx = 0.0
                var DPsi = List[F64]()
                while True:
                    DPjx = DPjc - Defc.error.value() * (DPjc - DPjp) / (Defc.error.value() - Defp.error.value())
                    let Defx = self.nIGU_Li(j, Pai, DPjx)
                    if Defx.error:
                        Errx = Defx.error.value()
                    DPsi = Defx.deflection
                    DPjp = DPjc
                    Defp.error = Defc.error
                    DPjc = DPjx
                    Defc.error = Errx
                    IterCnt = IterCnt + 1
                    if abs(Errx) <= 0.001 or IterCnt >= 500:
                        break
                let DPnj = DPjx * self.m_Pcs[j]
                let sj = 1.0 if DPnj > 0.0 else -1.0
                var Vj = 0.0
                let value = tableColumnInterpolation(self.m_PnVns, DPnj * sj, Table.Extrapolate.Yes)
                if value:
                    Vj = value.value() / self.m_Vcs[j] * sj
                Err0 = ((self.m_Gap[index].initialPressure * self.m_LoadTemperature[index]) /
                        (Pai * self.m_Gap[index].initialTemperature) - 1.0) * self.m_Gap[index].thickness * self.m_ShortDimension * self.m_LongDimension + Vi - Vj
                DPs.append(dpCoeff)
                for val in DPsi:
                    DPs.append(val)
        else:
            let DPj = Pai - self.m_PsLoaded[j]
            let DPnj = DPj * self.m_Pcs[j]
            let sj = 1.0 if DPnj > 0.0 else -1.0
            var Vj = 0.0
            let value = tableColumnInterpolation(self.m_PnVns, DPnj * sj, Table.Extrapolate.Yes)
            if value:
                Vj = value.value() / self.m_Vcs[j] * sj
            Err0 = ((self.m_Gap[index].initialPressure * self.m_LoadTemperature[index]) /
                    (Pai * self.m_Gap[index].initialTemperature) - 1.0) * self.m_Gap[index].thickness * self.m_ShortDimension * self.m_LongDimension + Vi - Vj
            DPs.append(dpCoeff)
            DPs.append(DPj)
        return DeflectionResults(Err0, DPs, List[F64]())

    def calculateResults(self) -> DeflectionResults:
        let dp1p = DeflectionE1300.DP1pGuess(self.m_PsLoaded[0] - self.m_PsLoaded[len(self.m_PsLoaded) - 1], self.m_Layer)
        let dp1c = dp1p * 1.01
        let Dp = self.nIGU_Li(0, 0.0, dp1p)
        let Dc = self.nIGU_Li(0, 0.0, dp1c)
        var Errx = Dc.error.value()
        var Dpx = List[F64]()
        if not Dp.error or not Dc.error:
            raise Error("Beyond Charts")
        else:
            var IterCnt = 0
            while True:
                let dp1x = dp1c - Dc.error.value() * (dp1c - dp1p) / (Dc.error.value() - Dp.error.value())
                let Dx = self.nIGU_Li(0, 0.0, dp1x)
                Errx = Dx.error.value()
                dp1p = dp1c
                Dp.error = Dc.error
                dp1c = dp1x
                Dc.error = Dx.error
                IterCnt = IterCnt + 1
                Dpx = Dx.deflection
                if abs(Errx) <= 0.001 or IterCnt >= 500:
                    break
        var defX = List[F64](capacity=len(self.m_Layer))
        for i in range(len(self.m_Layer)):
            var ws = 0.0
            let val = tableColumnInterpolation(self.m_PnWns, abs(Dpx[i]) * self.m_Pcs[i], Table.Extrapolate.Yes)
            if val:
                let si = 1.0 if Dpx[i] > 0.0 else -1.0
                ws = val.value() / (1.0 / self.m_Layer[i].thickness * si)
                Dpx[i] = -Dpx[i] * 1000.0
                defX.append(-ws / 1000.0)
            else:
                defX.append(0.0)  # fallback
        return DeflectionResults(Some(Errx), defX, Dpx)
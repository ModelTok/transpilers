from WCECommon import CSeries, IntegrationType, Property, Side, EnumProperty, EnumSide, ConstantsData
from MeasuredSampleData import CSpectralSampleData, PhotovoltaicSampleData
from memory import Arc
from utils import Error

@value
struct WavelengthSet:
    var __value: Int
    static var Custom: Self = Self(0)
    static var Source: Self = Self(1)
    static var Data: Self = Self(2)

class CSample:
    # protected members
    var m_SourceData: CSeries
    var m_DetectorData: CSeries
    var m_Wavelengths: List[Float64]
    var m_WavelengthSet: WavelengthSet
    var m_IncomingSource: CSeries
    var m_EnergySource: Dict[Tuple[Property, Side], CSeries]
    var m_IntegrationType: IntegrationType
    var m_NormalizationCoefficient: Float64
    var m_StateCalculated: Bool

    # constructor with parameters
    def __init__(
        inout self,
        t_SourceData: CSeries,
        integrationType: IntegrationType = IntegrationType.Trapezoidal,
        t_NormalizationCoefficient: Float64 = 1.0,
    ):
        self.m_SourceData = t_SourceData
        self.m_WavelengthSet = WavelengthSet.Data
        self.m_IntegrationType = integrationType
        self.m_NormalizationCoefficient = t_NormalizationCoefficient
        self.m_StateCalculated = False
        self.reset()

    # default constructor
    def __init__(inout self):
        self.m_WavelengthSet = WavelengthSet.Data
        self.m_IntegrationType = IntegrationType.Trapezoidal
        self.m_NormalizationCoefficient = 1.0
        self.m_StateCalculated = False
        self.reset()

    # copy constructor calls operator_assign
    def __init__(inout self, t_Sample: Self):
        self.operator_assign(t_Sample)

    # operator= mapping to operator_assign
    def operator_assign(inout self, t_Sample: Self) -> Self:
        self.m_StateCalculated = t_Sample.m_StateCalculated
        self.m_IntegrationType = t_Sample.m_IntegrationType
        self.m_NormalizationCoefficient = t_Sample.m_NormalizationCoefficient
        self.m_WavelengthSet = t_Sample.m_WavelengthSet
        self.m_IncomingSource = t_Sample.m_IncomingSource
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_EnergySource[(prop, side)] = t_Sample.m_EnergySource[(prop, side)]
        return self

    def assignDetectorAndWavelengths(
        inout self, t_Sample: Arc[CSample]
    ):
        self.m_DetectorData = t_Sample.m_DetectorData
        self.m_Wavelengths = t_Sample.m_Wavelengths
        self.m_WavelengthSet = t_Sample.m_WavelengthSet

    def getSourceData(inout self) -> ref [CSeries]:
        self.calculateState()
        return self.m_SourceData

    def setSourceData(inout self, t_SourceData: CSeries):
        self.m_SourceData = t_SourceData
        self.reset()

    def setDetectorData(inout self, t_DetectorData: CSeries):
        self.m_DetectorData = t_DetectorData
        self.reset()

    def getIntegrator(imm self) -> IntegrationType:
        return self.m_IntegrationType

    def getNormalizationCoeff(imm self) -> Float64:
        return self.m_NormalizationCoefficient

    def getProperty(
        inout self,
        minLambda: Float64,
        maxLambda: Float64,
        t_Property: Property,
        t_Side: Side,
    ) -> Float64:
        self.calculateState()
        var Prop: Float64 = 0.0
        if self.m_IncomingSource.size() > 0:
            var incomingEnergy = self.m_IncomingSource.sum(minLambda, maxLambda)
            var propertyEnergy = self.m_EnergySource[(t_Property, t_Side)].sum(
                minLambda, maxLambda
            )
            Prop = propertyEnergy / incomingEnergy
        return Prop

    def getEnergyProperties(
        inout self, t_Property: Property, t_Side: Side
    ) -> ref [CSeries]:
        self.calculateState()
        return self.m_EnergySource[(t_Property, t_Side)]

    def setWavelengths(
        inout self,
        t_WavelengthSet: WavelengthSet,
        t_Wavelenghts: List[Float64] = List[Float64](),
    ):
        self.m_WavelengthSet = t_WavelengthSet
        # switch
        if t_WavelengthSet == WavelengthSet.Custom:
            self.m_Wavelengths = t_Wavelenghts
        elif t_WavelengthSet == WavelengthSet.Source:
            if self.m_SourceData.size() == 0:
                raise Error(
                    "Cannot extract wavelenghts from source. Source is empty."
                )
            self.m_Wavelengths = self.m_SourceData.getXArray()
        elif t_WavelengthSet == WavelengthSet.Data:
            self.m_Wavelengths = self.getWavelengthsFromSample()
        else:
            raise Error("Incorrect definition of wavelength set source.")
        self.reset()

    def getEnergy(
        inout self,
        minLambda: Float64,
        maxLambda: Float64,
        t_Property: Property,
        t_Side: Side,
    ) -> Float64:
        self.calculateState()
        return self.m_EnergySource[(t_Property, t_Side)].sum(minLambda, maxLambda)

    def getWavelengths(imm self) -> List[Float64]:
        return self.m_Wavelengths

    def getBandSize(imm self) -> Int:
        return self.m_Wavelengths.size()

    # protected methods
    def reset(inout self):
        self.m_StateCalculated = False
        self.m_IncomingSource = CSeries()
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_EnergySource[(prop, side)] = CSeries()

    def calculateState(inout self):
        if not self.m_StateCalculated:
            if self.m_WavelengthSet != WavelengthSet.Custom:
                self.setWavelengths(self.m_WavelengthSet)
            if self.m_SourceData.size() > 0:
                self.m_IncomingSource = self.m_SourceData.interpolate(
                    self.m_Wavelengths
                )
                if self.m_DetectorData.size() > 0:
                    var interpolatedDetector = self.m_DetectorData.interpolate(
                        self.m_Wavelengths
                    )
                    self.m_IncomingSource = (
                        self.m_IncomingSource * interpolatedDetector
                    )
                self.calculateProperties()
                self.m_IncomingSource = self.m_IncomingSource.integrate(
                    self.m_IntegrationType, self.m_NormalizationCoefficient
                )
                for prop in EnumProperty():
                    for side in EnumSide():
                        self.m_EnergySource[(prop, side)] = (
                            self.m_EnergySource[(prop, side)].integrate(
                                self.m_IntegrationType,
                                self.m_NormalizationCoefficient,
                            )
                        )
                self.m_StateCalculated = True

    def calculateProperties() = 0

    def getWavelengthsFromSample(imm self) -> List[Float64] = 0

class CSpectralSample(CSample):
    var m_SampleData: Arc[CSpectralSampleData]
    var m_Property: Dict[Tuple[Property, Side], CSeries]

    def __init__(
        inout self,
        t_SampleData: Arc[CSpectralSampleData],
        t_SourceData: CSeries,
        integrationType: IntegrationType = IntegrationType.Trapezoidal,
        NormalizationCoefficient: Float64 = 1.0,
    ):
        # call base constructor
        self.m_SourceData = t_SourceData
        self.m_WavelengthSet = WavelengthSet.Data
        self.m_IntegrationType = integrationType
        self.m_NormalizationCoefficient = NormalizationCoefficient
        self.m_StateCalculated = False
        self.reset()

        self.m_SampleData = t_SampleData
        if t_SampleData is None:
            raise Error("Sample must have measured data.")
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_Property[(prop, side)] = CSeries()

    def __init__(inout self, t_SampleData: Arc[CSpectralSampleData]):
        # default base
        self.m_WavelengthSet = WavelengthSet.Data
        self.m_IntegrationType = IntegrationType.Trapezoidal
        self.m_NormalizationCoefficient = 1.0
        self.m_StateCalculated = False
        self.reset()

        self.m_SampleData = t_SampleData
        if t_SampleData is None:
            raise Error("Sample must have measured data.")
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_Property[(prop, side)] = CSeries()

    def getMeasuredData(inout self) -> Arc[CSpectralSampleData]:
        self.calculateState()
        return self.m_SampleData

    def getWavelengthsFromSample(imm self) -> List[Float64]:
        return self.m_SampleData.getWavelengths()

    def getWavelengthsProperty(
        inout self, t_Property: Property, t_Side: Side
    ) -> CSeries:
        self.calculateState()
        return self.m_Property[(t_Property, t_Side)]

    def calculateProperties(inout self) overridden:
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_Property[(prop, side)] = self.m_SampleData.properties(
                    prop, side
                )
                if self.m_WavelengthSet != WavelengthSet.Data:
                    self.m_Property[(prop, side)] = self.m_Property[
                        (prop, side)
                    ].interpolate(self.m_Wavelengths)

        for prop in EnumProperty():
            for side in EnumSide():
                self.m_EnergySource[(prop, side)] = (
                    self.m_Property[(prop, side)] * self.m_IncomingSource
                )

    def calculateState(inout self) overridden:
        CSample.calculateState(self)
        if self.m_SourceData.size() == 0:
            for prop in EnumProperty():
                for side in EnumSide():
                    self.m_Property[(prop, side)] = self.m_SampleData.properties(
                        prop, side
                    )
            self.m_StateCalculated = True

    def cutExtraData(inout self, minLambda: Float64, maxLambda: Float64):
        self.m_SampleData.cutExtraData(minLambda, maxLambda)

    def Flipped(inout self, flipped: Bool):
        self.m_SampleData.Filpped(flipped)

class CPhotovoltaicSample(CSpectralSample):
    var m_JcsPrime: Dict[Side, CSeries]

    def __init__(
        inout self,
        t_PhotovoltaicData: Arc[PhotovoltaicSampleData],
        t_SourceData: CSeries,
        integrationType: IntegrationType = IntegrationType.Trapezoidal,
        NormalizationCoefficient: Float64 = 1.0,
    ):
        # call CSpectralSample constructor
        self.m_SourceData = t_SourceData
        self.m_WavelengthSet = WavelengthSet.Data
        self.m_IntegrationType = integrationType
        self.m_NormalizationCoefficient = NormalizationCoefficient
        self.m_StateCalculated = False
        self.reset()

        self.m_SampleData = t_PhotovoltaicData
        if t_PhotovoltaicData is None:
            raise Error("Sample must have measured data.")
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_Property[(prop, side)] = CSeries()

        self.m_JcsPrime = {Side.Front: CSeries(), Side.Back: CSeries()}

    def calculateState(inout self) overridden:
        CSpectralSample.calculateProperties(self)
        for side in EnumSide():
            var eqe: CSeries = self.getSample().eqe(side)
            var wl: List[Float64] = self.getWavelengthsFromSample()
            var jscPrime: CSeries = CSeries()
            for i in range(wl.size()):
                var pceVal: Float64 = self.jscPrimeCalc(wl[i], eqe[i].value())
                jscPrime.addProperty(wl[i], pceVal)
            self.m_JcsPrime[side] = jscPrime

    # private method, but kept as in C++ protected
    def getSample(imm self) -> PhotovoltaicSampleData:
        return self.m_SampleData as PhotovoltaicSampleData

    @staticmethod
    def jscPrimeCalc(wavelength: Float64, eqe: Float64) -> Float64:
        var microMeterToMeter: Float64 = 1e-6
        return (
            eqe
            * wavelength
            * ConstantsData.ELECTRON_CHARGE
            * microMeterToMeter
            / (ConstantsData.SPEEDOFLIGHT * ConstantsData.PLANKCONSTANT)
        )

    def jscPrime(inout self, side: Side) -> ref [CSeries]:
        self.calculateState()
        return self.m_JcsPrime[side]
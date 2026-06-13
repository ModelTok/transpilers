from ......WCECommon import Property, Side, CSeries, EnumProperty, EnumSide, getSide, Enum
from builtins import List

struct MeasuredRow:
    var wavelength: Float64
    var T: Float64
    var Rf: Float64
    var Rb: Float64

    def __init__(inout self, wl: Float64, t: Float64, rf: Float64, rb: Float64):
        self.wavelength = wl
        self.T = t
        self.Rf = rf
        self.Rb = rb

class SampleData:
    var m_Flipped: Bool

    def __init__(inout self):
        self.m_Flipped = False

    def __del__(owned self):

    @abstractmethod
    def interpolate(inout self, t_Wavelengths: borrowed List[Float64]):
        ...

    @abstractmethod
    def properties(inout self, prop: Property, side: Side) -> ref CSeries:
        ...

    @abstractmethod
    def cutExtraData(inout self, minLambda: Float64, maxLambda: Float64):
        ...

    def Flipped(self) -> Bool:
        return self.m_Flipped

    def Filpped(inout self, t_Flipped: Bool):
        self.m_Flipped = t_Flipped

class CSpectralSampleData(SampleData):
    var m_Property: Dict[(Property, Side), CSeries]
    var m_absCalculated: Bool

    def __init__(inout self):
        super().__init__()
        self.m_absCalculated = False
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_Property[(prop, side)] = CSeries()

    def __init__(inout self, tValues: List[MeasuredRow]):
        self.__init__()
        self.m_Property[(Property.T, Side.Front)].clear()
        self.m_Property[(Property.T, Side.Back)].clear()
        self.m_Property[(Property.R, Side.Front)].clear()
        self.m_Property[(Property.R, Side.Back)].clear()
        for val in tValues:
            self.m_Property[(Property.T, Side.Front)].addProperty(val.wavelength, val.T)
            self.m_Property[(Property.T, Side.Back)].addProperty(val.wavelength, val.T)
            self.m_Property[(Property.R, Side.Front)].addProperty(val.wavelength, val.Rf)
            self.m_Property[(Property.R, Side.Back)].addProperty(val.wavelength, val.Rb)

    def __init__(inout self, other: CSpectralSampleData):
        self.m_Property = other.m_Property
        self.m_absCalculated = other.m_absCalculated

    @staticmethod
    def create(tValues: List[MeasuredRow]) -> Pointer[CSpectralSampleData]:
        return Pointer[CSpectralSampleData](CSpectralSampleData(tValues))

    @staticmethod
    def create() -> Pointer[CSpectralSampleData]:
        return CSpectralSampleData.create(List[MeasuredRow]())

    def addRecord(inout self, t_Wavelength: Float64, t_Transmittance: Float64,
                 t_ReflectanceFront: Float64, t_ReflectanceBack: Float64):
        self.m_Property[(Property.T, Side.Front)].addProperty(t_Wavelength, t_Transmittance)
        self.m_Property[(Property.T, Side.Back)].addProperty(t_Wavelength, t_Transmittance)
        self.m_Property[(Property.R, Side.Front)].addProperty(t_Wavelength, t_ReflectanceFront)
        self.m_Property[(Property.R, Side.Back)].addProperty(t_Wavelength, t_ReflectanceBack)
        self.reset()

    def properties(inout self, prop: Property, side: Side) -> ref CSeries:
        self.calculateProperties()
        var aSide = getSide(side, self.m_Flipped)
        return self.m_Property[(prop, aSide)]

    def getWavelengths(self) -> List[Float64]:
        return self.m_Property[(Property.T, Side.Front)].getXArray()

    def interpolate(inout self, t_Wavelengths: borrowed List[Float64]):
        for prop in EnumProperty():
            for side in EnumSide():
                self.m_Property[(prop, side)] = self.m_Property[(prop, side)].interpolate(t_Wavelengths)

    def cutExtraData(inout self, minLambda: Float64, maxLambda: Float64):
        for side in EnumSide():
            self.m_Property[(Property.T, side)].cutExtraData(minLambda, maxLambda)
            self.m_Property[(Property.R, side)].cutExtraData(minLambda, maxLambda)

    def calculateProperties(inout self):
        if not self.m_absCalculated:
            self.m_Property[(Property.Abs, Side.Front)].clear()
            self.m_Property[(Property.Abs, Side.Back)].clear()
            var wv = self.m_Property[(Property.T, Side.Front)].getXArray()
            for i in range(len(wv)):
                var RFrontSide = Side.Back if self.m_Flipped else Side.Front
                var RBackSide = Side.Front if self.m_Flipped else Side.Back
                var value = 1.0 - self.m_Property[(Property.T, Side.Front)][i].value() - self.m_Property[(Property.R, RFrontSide)][i].value()
                self.m_Property[(Property.Abs, Side.Front)].addProperty(wv[i], value)
                value = 1.0 - self.m_Property[(Property.T, Side.Back)][i].value() - self.m_Property[(Property.R, RBackSide)][i].value()
                self.m_Property[(Property.Abs, Side.Back)].addProperty(wv[i], value)
            self.m_absCalculated = True

    def reset(inout self):
        self.m_absCalculated = False

enum PVM:
    JSC
    VOC
    FF

class EnumPVM(Enum[PVM]):

def begin(enum: EnumPVM) -> EnumPVM.Iterator:
    return EnumPVM.Iterator(int(PVM.JSC))

def end(enum: EnumPVM) -> EnumPVM.Iterator:
    return EnumPVM.Iterator(int(PVM.FF) + 1)

class PhotovoltaicSampleData(CSpectralSampleData):
    var m_EQE: Dict[Side, CSeries]

    def __init__(inout self, spectralSampleData: CSpectralSampleData):
        super().__init__(spectralSampleData)
        self.m_EQE = {Side.Front: CSeries(), Side.Back: CSeries()}

    def __init__(inout self, spectralSampleData: CSpectralSampleData,
                 eqeValuesFront: CSeries, eqeValuesBack: CSeries):
        super().__init__(spectralSampleData)
        self.m_EQE = {Side.Front: eqeValuesFront, Side.Back: eqeValuesBack}
        var spectralWl = self.getWavelengths()
        for side in EnumSide():
            var eqeWavelengths = self.m_EQE[side].getXArray()
            if len(spectralWl) != len(eqeWavelengths):
                raise Error("Measured spectral data do not have same amount of data as provided eqe values for the photovoltaic.")
            for i in range(len(spectralWl)):
                if spectralWl[i] != eqeWavelengths[i]:
                    raise Error("Measured spectral wavelengths are not matching to provided eqe photovoltaic wavelengths.")

    def cutExtraData(inout self, minLambda: Float64, maxLambda: Float64):
        super().cutExtraData(minLambda, maxLambda)
        for side in EnumSide():
            self.m_EQE[side].cutExtraData(minLambda, maxLambda)

    def eqe(self, side: Side) -> CSeries:
        return self.m_EQE[side]
# Mojo translation of SeriesInterpolation.unit.cpp

from memory import SharedPtr
from FenestrationCommon import CSeries
from Testing import Test, TestCase, ExpectEqual, ExpectNear, ScopedTrace

@value
struct TestSeriesInterpolation(Test):
    var m_Series: SharedPtr[CSeries]

    def __init__(inout self):
        self.m_Series = SharedPtr[CSeries](CSeries())
        self.m_Series.addProperty(0.40, 556)
        self.m_Series.addProperty(0.41, 656.3)
        self.m_Series.addProperty(0.42, 690.8)
        self.m_Series.addProperty(0.43, 641.9)
        self.m_Series.addProperty(0.44, 798.5)
        self.m_Series.addProperty(0.45, 956.6)
        self.m_Series.addProperty(0.46, 990)
        self.m_Series.addProperty(0.47, 998)
        self.m_Series.addProperty(0.48, 1046.1)
        self.m_Series.addProperty(0.49, 1005.1)
        self.m_Series.addProperty(0.50, 1026.7)

    def getProperty(self) -> SharedPtr[CSeries]:
        return self.m_Series

def test_TestSeriesInterpolation_TestInterpolation():
    ScopedTrace("Begin Test: Test interpolation over the range of data.")
    var aSpectralProperties = TestSeriesInterpolation().getProperty()
    var wavelengths = List[Float64]()
    wavelengths.append(0.400)
    wavelengths.append(0.405)
    wavelengths.append(0.410)
    wavelengths.append(0.415)
    wavelengths.append(0.420)
    wavelengths.append(0.425)
    wavelengths.append(0.430)
    wavelengths.append(0.435)
    wavelengths.append(0.440)
    wavelengths.append(0.445)
    wavelengths.append(0.450)
    wavelengths.append(0.455)
    wavelengths.append(0.460)
    wavelengths.append(0.465)
    wavelengths.append(0.470)
    wavelengths.append(0.475)
    wavelengths.append(0.480)
    wavelengths.append(0.485)
    wavelengths.append(0.490)
    wavelengths.append(0.495)
    var aInterpolatedProperties = aSpectralProperties.interpolate(wavelengths)
    var correctResults = List[Float64]()
    correctResults.append(556.000)
    correctResults.append(606.150)
    correctResults.append(656.300)
    correctResults.append(673.550)
    correctResults.append(690.800)
    correctResults.append(666.350)
    correctResults.append(641.900)
    correctResults.append(720.200)
    correctResults.append(798.500)
    correctResults.append(877.550)
    correctResults.append(956.600)
    correctResults.append(973.300)
    correctResults.append(990.000)
    correctResults.append(994.000)
    correctResults.append(998.000)
    correctResults.append(1022.050)
    correctResults.append(1046.100)
    correctResults.append(1025.600)
    correctResults.append(1005.100)
    correctResults.append(1015.900)
    ExpectEqual(aInterpolatedProperties.size(), correctResults.size())
    for i in range(aInterpolatedProperties.size()):
        ExpectNear(correctResults[i], aInterpolatedProperties[i].value(), 1e-6)
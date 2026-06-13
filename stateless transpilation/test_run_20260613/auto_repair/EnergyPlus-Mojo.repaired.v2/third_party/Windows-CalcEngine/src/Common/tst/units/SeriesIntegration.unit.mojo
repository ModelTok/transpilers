from memory import shared_ptr, make_shared
from testing import Test, expect_equal, expect_near
from WCECommon import CSeries, IntegrationType

class TestSeriesIntegration(Test):
    var m_Series: shared_ptr[CSeries]

    def __init__(inout self):
        self.m_Series = shared_ptr[CSeries]()

    def SetUp(inout self):
        self.m_Series = make_shared[CSeries]()
        self.m_Series.addProperty(0.500, 0.5511)
        self.m_Series.addProperty(0.505, 0.5519)
        self.m_Series.addProperty(0.510, 0.5523)
        self.m_Series.addProperty(0.515, 0.5529)
        self.m_Series.addProperty(0.520, 0.5543)
        self.m_Series.addProperty(0.525, 0.5552)
        self.m_Series.addProperty(0.530, 0.5579)
        self.m_Series.addProperty(0.535, 0.5626)
        self.m_Series.addProperty(0.540, 0.5699)
        self.m_Series.addProperty(0.545, 0.5789)
        self.m_Series.addProperty(0.550, 0.5884)
        self.m_Series.addProperty(0.555, 0.5949)
        self.m_Series.addProperty(0.560, 0.5971)
        self.m_Series.addProperty(0.565, 0.5946)
        self.m_Series.addProperty(0.570, 0.5885)
        self.m_Series.addProperty(0.575, 0.5784)
        self.m_Series.addProperty(0.580, 0.5666)
        self.m_Series.addProperty(0.585, 0.5547)
        self.m_Series.addProperty(0.590, 0.5457)
        self.m_Series.addProperty(0.595, 0.5425)
        self.m_Series.addProperty(0.600, 0.5435)

    def getProperty(self) -> shared_ptr[CSeries]:
        return self.m_Series

def TestSeriesIntegration_TestRectangular():
    var aSpectralProperties = *TestSeriesIntegration().getProperty()
    var aIntegratedProperties = aSpectralProperties.integrate(IntegrationType.Rectangular)
    var correctResults = List[Float64](0.0027555, 0.0027595, 0.0027615, 0.0027645, 0.0027715,
                                       0.0027760, 0.0027895, 0.0028130, 0.0028495, 0.0028945,
                                       0.0029420, 0.0029745, 0.0029855, 0.0029730, 0.0029425,
                                       0.0028920, 0.0028330, 0.0027735, 0.0027285, 0.0027125)
    expect_equal(aIntegratedProperties.size(), len(correctResults))
    for i in range(aIntegratedProperties.size()):
        expect_near(correctResults[i], aIntegratedProperties[i].value(), 1e-6)

def TestSeriesIntegration_TestTrapezoidal():
    var aSpectralProperties = *TestSeriesIntegration().getProperty()
    var aIntegratedProperties = aSpectralProperties.integrate(IntegrationType.Trapezoidal)
    var correctResults = List[Float64](0.00275750, 0.00276050, 0.00276300, 0.00276800, 0.00277375,
                                       0.00278275, 0.00280125, 0.00283125, 0.00287200, 0.00291825,
                                       0.00295825, 0.00298000, 0.00297925, 0.00295775, 0.00291725,
                                       0.00286250, 0.00280325, 0.00275100, 0.00272050, 0.00271500)
    expect_equal(aIntegratedProperties.size(), len(correctResults))
    for i in range(aIntegratedProperties.size()):
        expect_near(correctResults[i], aIntegratedProperties[i].value(), 1e-6)

def TestSeriesIntegration_TestRectangularCentroid():
    var aSpectralProperties = *TestSeriesIntegration().getProperty()
    var aIntegratedProperties = aSpectralProperties.integrate(IntegrationType.RectangularCentroid, 2)
    var correctResults = List[Float64](0.0013777, 0.0013798, 0.0013807, 0.0013823, 0.0013857,
                                       0.0013880, 0.0013947, 0.0014065, 0.0014247, 0.0014473,
                                       0.0014710, 0.0014873, 0.0014927, 0.0014865, 0.0014713,
                                       0.0014460, 0.0014165, 0.0013867, 0.0013643, 0.0013562)
    expect_equal(aIntegratedProperties.size(), len(correctResults))
    for i in range(aIntegratedProperties.size()):
        expect_near(correctResults[i], aIntegratedProperties[i].value(), 1e-6)

def TestSeriesIntegration_TestPreWeighted():
    var aSpectralProperties = *TestSeriesIntegration().getProperty()
    var aIntegratedProperties = aSpectralProperties.integrate(IntegrationType.PreWeighted, 2)
    var correctResults = List[Float64](0.275550, 0.275950, 0.276150, 0.276450, 0.277150, 0.277600,
                                       0.278950, 0.281300, 0.284950, 0.289450, 0.294200, 0.297450,
                                       0.298550, 0.297300, 0.294250, 0.289200, 0.283300, 0.277350,
                                       0.272850, 0.271250, 0.271750)
    expect_equal(aIntegratedProperties.size(), len(correctResults))
    for i in range(aIntegratedProperties.size()):
        expect_near(correctResults[i], aIntegratedProperties[i].value(), 1e-6)
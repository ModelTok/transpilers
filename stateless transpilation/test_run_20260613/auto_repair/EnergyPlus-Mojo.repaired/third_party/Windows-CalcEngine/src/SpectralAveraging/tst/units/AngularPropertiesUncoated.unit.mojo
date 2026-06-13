from testing import expect, expect_near

from ...WCESpectralAveraging import CAngularPropertiesFactory
from ...WCECommon import SurfaceType

def SCOPED_TRACE(msg: String):
    print(msg)

@test
struct TestAngularPropertiesUncoated:
    def setUp(self):

    def Test1(self):
        SCOPED_TRACE("Begin Test: Uncoated properties - various angles.")
        var aThickness = 0.005715   # m
        var lambda = 0.8e-6         # m
        var T0 = 0.722
        var R0 = 0.066
        var angle = 0.0
        var aAngularFactory = CAngularPropertiesFactory(T0, R0, aThickness)
        var aProperties = aAngularFactory.getAngularProperties(SurfaceType.Uncoated)
        expect_near(0.722, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(0.066, aProperties.reflectance(angle, lambda), 1e-6)
        angle = 30
        expect_near(0.70982055, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(0.067355436, aProperties.reflectance(angle, lambda), 1e-6)
        angle = 60
        expect_near(0.625790657, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(0.126842853, aProperties.reflectance(angle, lambda), 1e-6)
        angle = 90
        expect_near(0, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(1, aProperties.reflectance(angle, lambda), 1e-6)

    def Test2(self):
        SCOPED_TRACE("Begin Test: Uncoated properties - zero normal transmittance.")
        var aThickness = 0.005715   # m
        var lambda = 0.8e-6         # m
        var T0 = 0.0
        var R0 = 0.047
        var angle = 0.0
        var aAngularFactory = CAngularPropertiesFactory(T0, R0, aThickness)
        var aProperties = aAngularFactory.getAngularProperties(SurfaceType.Uncoated)
        expect_near(0.0, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(0.047, aProperties.reflectance(angle, lambda), 1e-6)
        angle = 30
        expect_near(0.0, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(0.048625638, aProperties.reflectance(angle, lambda), 1e-6)
        angle = 60
        expect_near(0.0, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(0.097922095, aProperties.reflectance(angle, lambda), 1e-6)
        angle = 90
        expect_near(0, aProperties.transmittance(angle, lambda), 1e-6)
        expect_near(1, aProperties.reflectance(angle, lambda), 1e-6)
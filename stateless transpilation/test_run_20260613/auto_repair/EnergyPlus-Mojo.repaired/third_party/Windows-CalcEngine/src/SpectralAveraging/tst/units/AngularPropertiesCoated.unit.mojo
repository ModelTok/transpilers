from ......WCESpectralAveraging import CAngularPropertiesFactory
from ......WCECommon import SurfaceType

struct TestAngularPropertiesCoated:
    def setUp(self):

    def Test1(self):
        // SCOPED_TRACE("Begin Test: Coated properties - various angles.")
        var T0 = 0.722
        var R0 = 0.066
        var angle = 0.0
        var aAngularFactory = CAngularPropertiesFactory(T0, R0, 0, T0)
        var aProperties = aAngularFactory.getAngularProperties(SurfaceType.Coated)
        assert abs(aProperties.transmittance(angle) - 0.7236606) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.0647858) < 1e-6
        angle = 30
        assert abs(aProperties.transmittance(angle) - 0.71370641981902272) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.06922922004519097) < 1e-6
        angle = 60
        assert abs(aProperties.transmittance(angle) - 0.6500166) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.13822155) < 1e-6
        angle = 90
        assert abs(aProperties.transmittance(angle) - 0) < 1e-6
        assert abs(aProperties.reflectance(angle) - 1) < 1e-6

    def Test2(self):
        // SCOPED_TRACE("Begin Test: Coated properties - NFRC Sample ID=1042.")
        var T0 = 0.4517085
        var R0 = 0.3592343
        var angle = 0.0
        var aAngularFactory = CAngularPropertiesFactory(T0, R0, 0, T0)
        var aProperties = aAngularFactory.getAngularProperties(SurfaceType.Coated)
        assert abs(aProperties.transmittance(angle) - 0.457016074875) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.354909131525) < 1e-6
        angle = 10
        assert abs(aProperties.transmittance(angle) - 0.45468722065434630) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.35394347494903849) < 1e-6
        angle = 20
        assert abs(aProperties.transmittance(angle) - 0.44888678437700730) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.35282710650693727) < 1e-6
        angle = 30
        assert abs(aProperties.transmittance(angle) - 0.44183053629536256) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.35502207112203277) < 1e-6
        angle = 40
        assert abs(aProperties.transmittance(angle) - 0.43348892234243364) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.36223764779145762) < 1e-6
        angle = 50
        assert abs(aProperties.transmittance(angle) - 0.41826848334431255) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.37451467264543725) < 1e-6
        angle = 60
        assert abs(aProperties.transmittance(angle) - 0.38374048664062504) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.39802064877812487) < 1e-6
        angle = 70
        assert abs(aProperties.transmittance(angle) - 0.31265626242160510) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.46009099882567134) < 1e-6
        angle = 80
        assert abs(aProperties.transmittance(angle) - 0.18796828616155317) < 1e-6
        assert abs(aProperties.reflectance(angle) - 0.62493075431787948) < 1e-6

def main():
    var testObj = TestAngularPropertiesCoated()
    testObj.setUp()
    testObj.Test1()
    testObj.Test2()
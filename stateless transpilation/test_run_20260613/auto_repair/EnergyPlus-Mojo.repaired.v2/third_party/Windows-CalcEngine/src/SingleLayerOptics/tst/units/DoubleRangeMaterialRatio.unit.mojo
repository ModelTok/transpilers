from memory import shared_ptr
from WCESingleLayerOptics import Material, Property, Side, CMaterial
from FenestrationCommon import FenestrationCommon
from testing import Test, TestFixture, expect_near, expect_eq, SCOPED_TRACE
from list import List
from math import isclose

@value
class TestDoubleRangeMaterialRatio(TestFixture):
    private var m_Material: shared_ptr[CMaterial]

    def __init__(inout self):
        self.m_Material = shared_ptr[CMaterial]()

    def SetUp(inout self):
        var Tsol = 0.1
        var Rfsol = 0.7
        var Rbsol = 0.7
        var Tvis = 0.2
        var Rfvis = 0.6
        var Rbvis = 0.6
        self.m_Material = Material.dualBandMaterial(Tsol, Tsol, Rfsol, Rbsol, Tvis, Tvis, Rfvis, Rbvis)

    def getMaterial(inout self) -> shared_ptr[CMaterial]:
        return self.m_Material

def TestMaterialProperties():
    SCOPED_TRACE("Begin Test: Phi angles creation.")
    var aMaterial: shared_ptr[CMaterial] = TestDoubleRangeMaterialRatio().getMaterial()
    var T: Float64 = aMaterial.getProperty(Property.T, Side.Front)
    expect_near(0.1, T, 1e-6)
    var R: Float64 = aMaterial.getProperty(Property.R, Side.Front)
    expect_near(0.7, R, 1e-6)
    var size: Int = 5
    var Transmittances: List[Float64] = aMaterial.getBandProperties(Property.T, Side.Front)
    expect_eq(size, Transmittances.size)
    var correctResults: List[Float64] = List[Float64]()
    correctResults.append(0.0)
    correctResults.append(0.0039215686274509838)
    correctResults.append(0.2)
    correctResults.append(0.0039215686274509838)
    correctResults.append(0.0039215686274509838)
    for i in range(size):
        expect_near(correctResults[i], Transmittances[i], 1e-6)
    var Reflectances: List[Float64] = aMaterial.getBandProperties(Property.R, Side.Front)
    expect_eq(size, Reflectances.size)
    correctResults.clear()
    correctResults.append(0.0)
    correctResults.append(0.79607843137254897)
    correctResults.append(0.6)
    correctResults.append(0.79607843137254897)
    correctResults.append(0.79607843137254897)
    for i in range(size):
        expect_near(correctResults[i], Reflectances[i], 1e-6)
# EXTERNAL DEPS (to wire in glue):
# - SingleLayerOptics.Material.dualBandMaterial (from WCESingleLayerOptics.hpp)
# - SingleLayerOptics.CMaterial (from WCESingleLayerOptics.hpp)
# - SingleLayerOptics.CMaterial.getProperty (from WCESingleLayerOptics.hpp)
# - SingleLayerOptics.CMaterial.getBandProperties (from WCESingleLayerOptics.hpp)
# - FenestrationCommon.Property (from WCESingleLayerOptics.hpp dependencies)
# - FenestrationCommon.Side (from WCESingleLayerOptics.hpp dependencies)

from testing import assert_equal, assert_almost_equal


# Stub for FenestrationCommon::Property enum (under using namespace FenestrationCommon)
struct Property:
    T: StringLiteral = "T"
    R: StringLiteral = "R"


# Stub for FenestrationCommon::Side enum (under using namespace FenestrationCommon)
struct Side:
    Front: StringLiteral = "Front"
    Back: StringLiteral = "Back"


# Stub for SingleLayerOptics::CMaterial (used as opaque type by the test)
struct CMaterial:
    fn getProperty(self, prop: StringLiteral, side: StringLiteral) -> Float64:
        # In real port, dispatched to the actual CMaterial implementation
        return 0.0

    fn getBandProperties(self, prop: StringLiteral, side: StringLiteral) -> List[Float64]:
        # In real port, dispatched to the actual CMaterial implementation
        return List[Float64]()


# Stub for SingleLayerOptics::Material namespace
struct Material:
    @staticmethod
    fn dualBandMaterial(Tsol_f: Float64, Tsol_b: Float64, Rfsol: Float64, Rbsol: Float64,
                         Tvis_f: Float64, Tvis_b: Float64, Rfvis: Float64, Rbvis: Float64) raises -> CMaterial:
        raise "Wire to SingleLayerOptics::Material::dualBandMaterial in actual port"


# Creation of double range material with provided ratio
# Test fixture equivalent to C++ TestDoubleRangeMaterialRatio
# (using namespace SingleLayerOptics; using namespace FenestrationCommon;)
struct TestDoubleRangeMaterialRatio:
    var m_Material: CMaterial

    fn __init__(inout self):
        # SetUp() - equivalent of C++ virtual void SetUp()
        # Solar range material
        let Tsol: Float64 = 0.1
        let Rfsol: Float64 = 0.7
        let Rbsol: Float64 = 0.7

        # Visible range
        let Tvis: Float64 = 0.2
        let Rfvis: Float64 = 0.6
        let Rbvis: Float64 = 0.6

        self.m_Material = Material.dualBandMaterial(Tsol, Tsol, Rfsol, Rbsol, Tvis, Tvis, Rfvis, Rbvis)

    fn getMaterial(self) -> CMaterial:
        return self.m_Material


# TestMaterialProperties (equivalent of TEST_F(TestDoubleRangeMaterialRatio, TestMaterialProperties))
def test_MaterialProperties():
    # SCOPED_TRACE("Begin Test: Phi angles creation.")  # Debug aid, no-op in port
    let fixture = TestDoubleRangeMaterialRatio()
    let aMaterial = fixture.getMaterial()

    let T = aMaterial.getProperty(Property.T, Side.Front)

    # Test for solar range first
    assert_almost_equal(T, 0.1, atol=1e-6)

    let R = aMaterial.getProperty(Property.R, Side.Front)

    assert_almost_equal(R, 0.7, atol=1e-6)

    # Properties at four wavelengths should have been created
    let size: Int = 5

    let Transmittances = aMaterial.getBandProperties(Property.T, Side.Front)

    assert_equal(len(Transmittances), size)

    var correctResults: List[Float64] = List[Float64]()
    correctResults.append(0)
    correctResults.append(0.0039215686274509838)
    correctResults.append(0.2)
    correctResults.append(0.0039215686274509838)
    correctResults.append(0.0039215686274509838)

    for i in range(size):
        assert_almost_equal(Transmittances[i], correctResults[i], atol=1e-6)

    let Reflectances = aMaterial.getBandProperties(Property.R, Side.Front)

    assert_equal(len(Reflectances), size)

    correctResults.clear()
    correctResults.append(0)
    correctResults.append(0.79607843137254897)
    correctResults.append(0.6)
    correctResults.append(0.79607843137254897)
    correctResults.append(0.79607843137254897)

    for i in range(size):
        assert_almost_equal(Reflectances[i], correctResults[i], atol=1e-6)

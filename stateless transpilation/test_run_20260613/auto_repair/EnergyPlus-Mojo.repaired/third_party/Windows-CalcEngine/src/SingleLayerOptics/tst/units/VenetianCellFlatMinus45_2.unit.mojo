from WCECommon import Side, CBeamDirection
from WCESingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material
from testing import assert_approx_equal

@value
struct TestVenetianCellFlatMinus45_2:
    var m_Cell: CVenetianCell

    def SetUp(inout self):
        var Tmat = 0.1
        var Rfmat = 0.3
        var Rbmat = 0.7
        var minLambda = 0.3
        var maxLambda = 2.5
        var aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        var slatWidth = 0.010
        var slatSpacing = 0.010
        var slatTiltAngle = -45
        var curvatureRadius = 0
        var numOfSlatSegments: Int = 2
        var aCellDescription = CVenetianCellDescription(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = CVenetianCell(aMaterial, aCellDescription)

    def GetCell(self) -> CVenetianCell:
        return self.m_Cell

@test
def TestVenetian1():
    SCOPED_TRACE: "Begin Test: Venetian cell (Flat, -45 degrees slats) - diffuse-diffuse."
    var fixture = TestVenetianCellFlatMinus45_2()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aSide = Side.Front
    var Tdif_dif = aCell.T_dif_dif(aSide)
    var Rdif_dif = aCell.R_dif_dif(aSide)
    assert_approx_equal(0.41584962301445344, Tdif_dif, 1e-6)
    assert_approx_equal(0.32417709978497861, Rdif_dif, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell.T_dif_dif(aSide)
    Rdif_dif = aCell.R_dif_dif(aSide)
    assert_approx_equal(0.41584962301445344, Tdif_dif, 1e-6)
    assert_approx_equal(0.15288558748616171, Rdif_dif, 1e-6)

@test
def TestVenetian2():
    SCOPED_TRACE: "Begin Test: Venetian cell (Flat, -45 degrees slats) - direct-diffuse."
    var fixture = TestVenetianCellFlatMinus45_2()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aSide = Side.Front
    var Theta = 0.0
    var Phi = 0.0
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    assert_approx_equal(0.29289321881345237, Tdir_dir, 1e-6)
    assert_approx_equal(0.11545919482729911, Tdir_dif, 1e-6)
    assert_approx_equal(0.34253339900108815, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    assert_approx_equal(0.29289321881345237, Tdir_dir, 1e-6)
    assert_approx_equal(0.091914433617905855, Tdir_dif, 1e-6)
    assert_approx_equal(0.15247512857100193, Rdir_dif, 1e-6)
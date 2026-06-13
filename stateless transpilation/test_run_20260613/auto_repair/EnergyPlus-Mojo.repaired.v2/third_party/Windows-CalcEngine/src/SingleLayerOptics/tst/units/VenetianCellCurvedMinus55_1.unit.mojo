from memory.arc import Arc
from testing import assert_approx_equal
from WCESingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material, CBeamDirection, Side
from WCECommon import FenestrationCommon

struct TestVenetianCellCurvedMinus55_1:
    var m_Cell: Arc[CVenetianCell]

    def SetUp(inout self):
        let Tmat = 0.1
        let Rfmat = 0.7
        let Rbmat = 0.7
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.076200
        let slatSpacing = 0.057150
        let slatTiltAngle = -55.000000
        let curvatureRadius = 0.123967
        let numOfSlatSegments: Int = 2
        let aCellDescription = Arc(CVenetianCellDescription(slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments))
        self.m_Cell = Arc(CVenetianCell(aMaterial, aCellDescription))

    def GetCell(self) -> Arc[CVenetianCell]:
        return self.m_Cell

def TestVenetian1():
    // SCOPED_TRACE("Begin Test: Venetian cell (Curved, -55 degrees slats - diffuse-diffuse).")
    var fixture = TestVenetianCellCurvedMinus55_1()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    var aSide = Side.Front
    var Tdif_dif = aCell.T_dif_dif(aSide)
    var Rdif_dif = aCell.R_dif_dif(aSide)
    assert_approx_equal(0.31432383716259166, Tdif_dif, 1e-6)
    assert_approx_equal(0.43717927379126331, Rdif_dif, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell.T_dif_dif(aSide)
    Rdif_dif = aCell.R_dif_dif(aSide)
    assert_approx_equal(0.31432383716259171, Tdif_dif, 1e-6)
    assert_approx_equal(0.45819107731734438, Rdif_dif, 1e-6)

def TestVenetian2():
    // SCOPED_TRACE("Begin Test: Venetian cell (Curved, -55 degrees slats - direct-diffuse).")
    var fixture = TestVenetianCellCurvedMinus55_1()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    var aSide = Side.Front
    let Theta = 0.0
    let Phi = 0.0
    let aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    assert_approx_equal(0.00000000000000000, Tdir_dir, 1e-6)
    assert_approx_equal(0.19221286838976023, Tdir_dif, 1e-6)
    assert_approx_equal(0.50885857000236578, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    assert_approx_equal(0.00000000000000000, Tdir_dir, 1e-6)
    assert_approx_equal(0.19839281076530671, Tdir_dif, 1e-6)
    assert_approx_equal(0.51950846145958018, Rdir_dif, 1e-6)

def main():
    TestVenetian1()
    TestVenetian2()
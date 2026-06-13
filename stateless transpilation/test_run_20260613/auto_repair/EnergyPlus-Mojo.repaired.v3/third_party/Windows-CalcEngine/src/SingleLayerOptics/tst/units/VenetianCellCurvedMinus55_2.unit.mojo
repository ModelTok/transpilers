from memory import shared_ptr, make_shared
from WCECommon import *
from WCESingleLayerOptics import *
from testing import *

@register_test("TestVenetianCellCurvedMinus55_2")
class TestVenetianCellCurvedMinus55_2(Testing):
    var m_Cell: shared_ptr[CVenetianCell]

    def SetUp():
        """Set up test fixture."""
        const Tmat = 0.1
        const Rfmat = 0.3
        const Rbmat = 0.7
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const slatWidth = 0.076200     # m
        const slatSpacing = 0.057150   # m
        const slatTiltAngle = -55.000000
        const curvatureRadius = 0.123967
        var numOfSlatSegments: size_t = 2
        var aCellDescription: shared_ptr[CVenetianCellDescription] = make_shared[CVenetianCellDescription](
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = make_shared[CVenetianCell](aMaterial, aCellDescription)

    def GetCell() -> shared_ptr[CVenetianCell]:
        return self.m_Cell

@register_test_case("TestVenetianCellCurvedMinus55_2.TestVenetian1")
def TestVenetian1(ctx: Testing):
    ctx.SCOPED_TRACE("Begin Test: Venetian cell (Curved, -55 degrees slats - diffuse-diffuse).")
    var aCell = ctx.GetCell()
    var aSide = Side.Front
    var Tdif_dif = aCell.T_dif_dif(aSide)
    var Rdif_dif = aCell.R_dif_dif(aSide)
    ctx.expect_near(Tdif_dif, 0.26028659060185622, 1e-6)
    ctx.expect_near(Rdif_dif, 0.39971258912039054, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell.T_dif_dif(aSide)
    Rdif_dif = aCell.R_dif_dif(aSide)
    ctx.expect_near(Tdif_dif, 0.26028659060185666, 1e-6)
    ctx.expect_near(Rdif_dif, 0.19608861125331134, 1e-6)

@register_test_case("TestVenetianCellCurvedMinus55_2.TestVenetian2")
def TestVenetian2(ctx: Testing):
    ctx.SCOPED_TRACE("Begin Test: Venetian cell (Curved, -55 degrees slats - direct-diffuse).")
    var aCell = ctx.GetCell()
    var aSide = Side.Front
    var Theta = 0.0
    var Phi = 0.0
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    ctx.expect_near(Tdir_dir, 0.00000000000000000, 1e-6)
    ctx.expect_near(Tdir_dif, 0.13194581766759877, 1e-6)
    ctx.expect_near(Rdir_dif, 0.46950286596646840, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    ctx.expect_near(Tdir_dir, 0.00000000000000000, 1e-6)
    ctx.expect_near(Tdir_dif, 0.11371279153419295, 1e-6)
    ctx.expect_near(Rdir_dif, 0.21789069507796985, 1e-6)
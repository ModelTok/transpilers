from builtin import Pointer
from testing import assert_approx_eq, @test
from WCECommon import Side, FenestrationCommon
from WCESingleLayerOptics import Material, CVenetianCell, CVenetianCellDescription, CBeamDirection

struct TestVenetianCellFlat45_2:
    var m_Cell: Pointer[CVenetianCell]

    def __init__(inout self):
        self.m_Cell = Pointer[CVenetianCell]()
        self.SetUp()

    def __del__(owned self):
        if self.m_Cell:
            self.m_Cell.free()

    def SetUp(inout self):
        let Tmat = 0.1
        let Rfmat = 0.3
        let Rbmat = 0.7
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.010     # m
        let slatSpacing = 0.010   # m
        let slatTiltAngle = 45
        let curvatureRadius = 0
        let numOfSlatSegments = 2
        var aCellDescription = CVenetianCellDescription(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = Pointer[CVenetianCell].alloc()
        self.m_Cell.initialize(aMaterial, aCellDescription)

    def GetCell(self) -> Pointer[CVenetianCell]:
        return self.m_Cell

@test
def test_TestVenetian1():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - diffuse-diffuse.")
    let fixture = TestVenetianCellFlat45_2()
    let aCell = fixture.GetCell()
    var aSide = Side.Front
    var Tdif_dif = aCell[].T_dif_dif(aSide)
    var Rdif_dif = aCell[].R_dif_dif(aSide)
    assert_approx_eq(Tdif_dif, 0.41584962301445338, 1e-6)
    assert_approx_eq(Rdif_dif, 0.15288558748616171, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell[].T_dif_dif(aSide)
    Rdif_dif = aCell[].R_dif_dif(aSide)
    assert_approx_eq(Tdif_dif, 0.41584962301445338, 1e-6)
    assert_approx_eq(Rdif_dif, 0.32417709978497861, 1e-6)

@test
def test_TestVenetian2():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - direct-diffuse.")
    let fixture = TestVenetianCellFlat45_2()
    let aCell = fixture.GetCell()
    var aSide = Side.Front
    let Theta = 0
    let Phi = 0
    let aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell[].T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell[].T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell[].R_dir_dif(aSide, aDirection)
    assert_approx_eq(Tdir_dir, 0.29289321881345237, 1e-6)
    assert_approx_eq(Tdir_dif, 0.091914433617905855, 1e-6)
    assert_approx_eq(Rdir_dif, 0.15247512857100193, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell[].T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell[].T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell[].R_dir_dif(aSide, aDirection)
    assert_approx_eq(Tdir_dir, 0.29289321881345237, 1e-6)
    assert_approx_eq(Tdir_dif, 0.11545919482729911, 1e-6)
    assert_approx_eq(Rdir_dif, 0.34253339900108815, 1e-6)
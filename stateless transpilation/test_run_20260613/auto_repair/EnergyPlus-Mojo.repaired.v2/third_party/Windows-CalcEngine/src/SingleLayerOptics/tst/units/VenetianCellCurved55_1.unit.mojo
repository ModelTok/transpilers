from memory import shared_ptr, make_shared
from WCESingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material, Side, CBeamDirection
from WCECommon import FenestrationCommon
from testing import Test, TestFixture, expect_near, scoped_trace

class TestVenetianCellCurved55_1(TestFixture):
    private:
        var m_Cell: shared_ptr[CVenetianCell]

    protected:
        def SetUp() raises:
            const Tmat = 0.1
            const Rfmat = 0.7
            const Rbmat = 0.7
            const minLambda = 0.3
            const maxLambda = 2.5
            const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
            const slatWidth = 0.076200
            const slatSpacing = 0.057150
            const slatTiltAngle = 55.000000
            const curvatureRadius = 0.123967
            const numOfSlatSegments: size_t = 2
            const aCellDescription = make_shared[CVenetianCellDescription](slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
            self.m_Cell = make_shared[CVenetianCell](aMaterial, aCellDescription)

    public:
        def GetCell() -> shared_ptr[CVenetianCell]:
            return self.m_Cell

def TestVenetianCellCurved55_1_TestVenetian1():
    scoped_trace("Begin Test: Venetian cell (Curved, -55 degrees slats) - diffuse-diffuse.")
    var aCell = TestVenetianCellCurved55_1().GetCell()
    var aSide = Side.Front
    var Tdif_dif: Float64 = aCell.T_dif_dif(aSide)
    var Rdif_dif: Float64 = aCell.R_dif_dif(aSide)
    expect_near(0.314324, Tdif_dif, 1e-6)
    expect_near(0.458191, Rdif_dif, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell.T_dif_dif(aSide)
    Rdif_dif = aCell.R_dif_dif(aSide)
    expect_near(0.314324, Tdif_dif, 1e-6)
    expect_near(0.437179, Rdif_dif, 1e-6)

def TestVenetianCellCurved55_1_TestVenetian2():
    scoped_trace("Begin Test: Venetian cell (Curved, -55 degrees slats) - direct-diffuse.")
    var aCell = TestVenetianCellCurved55_1().GetCell()
    var aSide = Side.Front
    var Theta: Float64 = 0
    var Phi: Float64 = 0
    var outTheta: Float64 = 15
    var outPhi: Float64 = 0
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir: Float64 = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif: Float64 = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif: Float64 = aCell.R_dir_dif(aSide, aDirection)
    expect_near(0.000000, Tdir_dir, 1e-6)
    expect_near(0.198393, Tdir_dif, 1e-6)
    expect_near(0.519508, Rdir_dif, 1e-6)
    var outDirection = CBeamDirection(outTheta, outPhi)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection, outDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection, outDirection)
    expect_near(0.208083, Tdir_dif, 1e-6)
    expect_near(0.582556, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(0.000000, Tdir_dir, 1e-6)
    expect_near(0.192213, Tdir_dif, 1e-6)
    expect_near(0.508859, Rdir_dif, 1e-6)
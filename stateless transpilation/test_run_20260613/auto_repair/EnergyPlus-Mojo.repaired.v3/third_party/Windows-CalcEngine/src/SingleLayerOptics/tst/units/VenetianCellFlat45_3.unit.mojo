from memory import shared_ptr, make_shared
from WCECommon import *
from WCESingleLayerOptics import *
from gtest import Test, TestFixture, EXPECT_NEAR, SCOPED_TRACE

@value
class TestVenetianCellFlat45_3(TestFixture):
    var m_Cell: shared_ptr[CVenetianCell]

    def __init__(inout self):
        self.m_Cell = shared_ptr[CVenetianCell]()

    def SetUp(inout self):
        let Tmat = 0.0
        let Rfmat = 0.1
        let Rbmat = 0.1
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.016
        let slatSpacing = 0.012
        let slatTiltAngle = 0
        let curvatureRadius = 0
        let numOfSlatSegments: size_t = 5
        let aCellDescription = shared_ptr[CVenetianCellDescription](
            make_pointer[CVenetianCellDescription](
                slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments
            )
        )
        self.m_Cell = shared_ptr[CVenetianCell](
            make_pointer[CVenetianCell](aMaterial, aCellDescription)
        )

    def GetCell(self) -> shared_ptr[CVenetianCell]:
        return self.m_Cell

def TestVenetian1():
    SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - diffuse-diffuse.")
    let aCell = TestVenetianCellFlat45_3().GetCell()
    var aSide = Side.Front
    var Tdif_dif = aCell.T_dif_dif(aSide)
    var Rdif_dif = aCell.R_dif_dif(aSide)
    EXPECT_NEAR(0.347602, Tdif_dif, 1e-6)
    EXPECT_NEAR(0.021039, Rdif_dif, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell.T_dif_dif(aSide)
    Rdif_dif = aCell.R_dif_dif(aSide)
    EXPECT_NEAR(0.347602, Tdif_dif, 1e-6)
    EXPECT_NEAR(0.021039, Rdif_dif, 1e-6)

def TestVenetian2():
    SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - direct-diffuse.")
    let aCell = TestVenetianCellFlat45_3().GetCell()
    var aSide = Side.Front
    let Theta = 0
    let Phi = 0
    let aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(1.0, Tdir_dir, 1e-6)
    EXPECT_NEAR(0.0, Tdir_dif, 1e-6)
    EXPECT_NEAR(0.0, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(1.0, Tdir_dir, 1e-6)
    EXPECT_NEAR(0.0, Tdir_dif, 1e-6)
    EXPECT_NEAR(0.0, Rdir_dif, 1e-6)
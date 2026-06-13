from memory import shared_ptr, make_shared
from WCECommon import *
from WCESingleLayerOptics import *
from testing import *

@value
struct TestPerfectDiffuseCell2:
    var m_Cell: shared_ptr[CUniformDiffuseCell]

    def __init__(inout self):
        let Tmat = 0.24
        let Rfmat = 0.55
        let Rbmat = 0.55
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let aCell: shared_ptr[ICellDescription] = make_shared[CFlatCellDescription]()
        self.m_Cell = make_shared[CUniformDiffuseCell](aMaterial, aCell)

    def GetCell(self) -> shared_ptr[CUniformDiffuseCell]:
        return self.m_Cell

def TestPerfectDiffuse1():
    SCOPED_TRACE("Begin Test: Perfect diffusing cell (Theta = 0, Phi = 0).")
    let aCell = TestPerfectDiffuseCell2().GetCell()
    let Theta = 0.0   # deg
    let Phi = 0.0     # deg
    let aSide = Side.Front
    let aDirection = CBeamDirection(Theta, Phi)
    let Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.00000000, Tdir_dir, 1e-6)
    let Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.24000000, Tdir_dif, 1e-6)
    let Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rfdir_dif, 1e-6)
    let Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rbdir_dif, 1e-6)

def TestPerfectDiffuse2():
    SCOPED_TRACE("Begin Test: Perfect diffusing cell (Theta = 45, Phi = 0).")
    let aCell = TestPerfectDiffuseCell2().GetCell()
    let Theta = 45.0   # deg
    let Phi = 0.0      # deg
    let aSide = Side.Front
    let aDirection = CBeamDirection(Theta, Phi)
    let Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.00000000, Tdir_dir, 1e-6)
    let Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.24000000, Tdir_dif, 1e-6)
    let Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rfdir_dif, 1e-6)
    let Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rbdir_dif, 1e-6)

def TestPerfectDiffuse3():
    SCOPED_TRACE("Begin Test: Perfect diffusing cell (Theta = 78, Phi = 45).")
    let aCell = TestPerfectDiffuseCell2().GetCell()
    let Theta = 78.0   # deg
    let Phi = 45.0     # deg
    let aSide = Side.Front
    let aDirection = CBeamDirection(Theta, Phi)
    let Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.00000000, Tdir_dir, 1e-6)
    let Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.24000000, Tdir_dif, 1e-6)
    let Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rfdir_dif, 1e-6)
    let Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rbdir_dif, 1e-6)

def TestPerfectDiffuse4():
    SCOPED_TRACE("Begin Test: Perfect diffusing cell (Theta = 54, Phi = 270).")
    let aCell = TestPerfectDiffuseCell2().GetCell()
    let Theta = 54.0   # deg
    let Phi = 270.0    # deg
    let aSide = Side.Front
    let aDirection = CBeamDirection(Theta, Phi)
    let Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.00000000, Tdir_dir, 1e-6)
    let Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.24000000, Tdir_dif, 1e-6)
    let Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rfdir_dif, 1e-6)
    let Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.55000000, Rbdir_dif, 1e-6)
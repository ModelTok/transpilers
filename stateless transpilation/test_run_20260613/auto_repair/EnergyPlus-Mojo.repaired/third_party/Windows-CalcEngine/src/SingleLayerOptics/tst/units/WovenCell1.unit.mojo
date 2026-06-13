from memory import shared_ptr, make_shared
from WCECommon import *
from WCESingleLayerOptics import *
from testing import *

@value
class TestWovenCell1(Test):
    var m_Cell: shared_ptr[CWovenCell]

    def __init__(inout self):
        self.m_Cell = shared_ptr[CWovenCell]()

    def SetUp(inout self):
        const Tmat = 0.08
        const Rfmat = 0.9
        const Rbmat = 0.9
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const diameter = 6.35   # mm
        const spacing = 19.05   # mm
        var aCell: shared_ptr[ICellDescription] = make_shared[CWovenCellDescription](diameter, spacing)
        self.m_Cell = make_shared[CWovenCell](aMaterial, aCell)

    def GetCell(self) -> shared_ptr[CWovenCell]:
        return self.m_Cell

def TestWovenCell1_TestWoven1():
    SCOPED_TRACE("Begin Test: Woven cell (Theta = 0, Phi = 0).")
    var aCell = TestWovenCell1().GetCell()
    const Theta: Float64 = 0   # deg
    const Phi: Float64 = 0     # deg
    const aSide: Side = Side.Front
    var aDirection = CBeamDirection(Theta, Phi)
    const Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.444444444, Tdir_dir, 1e-6)
    const Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.045908, Tdir_dif, 1e-6)
    const Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.478783, Rfdir_dif, 1e-6)
    const Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.478783, Rbdir_dif, 1e-6)

def TestWovenCell1_TestWoven2():
    SCOPED_TRACE("Begin Test: Woven cell (Theta = 45, Phi = 0).")
    var aCell = TestWovenCell1().GetCell()
    const Theta: Float64 = 45   # deg
    const Phi: Float64 = 0      # deg
    const aSide: Side = Side.Front
    var aDirection = CBeamDirection(Theta, Phi)
    const Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.352397, Tdir_dir, 1e-6)
    const Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.114759, Tdir_dif, 1e-6)
    const Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.501635, Rfdir_dif, 1e-6)
    const Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.501635, Rbdir_dif, 1e-6)

def TestWovenCell1_TestWoven3():
    SCOPED_TRACE("Begin Test: Woven cell (Theta = 78, Phi = 45).")
    var aCell = TestWovenCell1().GetCell()
    const Theta: Float64 = 78   # deg
    const Phi: Float64 = 45     # deg
    const aSide: Side = Side.Front
    const aDirection = CBeamDirection(Theta, Phi)
    const Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.0, Tdir_dir, 1e-6)
    const Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.109392, Tdir_dif, 1e-6)
    const Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.870608, Rfdir_dif, 1e-6)
    const Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.870608, Rbdir_dif, 1e-6)

def TestWovenCell1_TestWoven4():
    SCOPED_TRACE("Begin Test: Woven cell (Theta = 54, Phi = 270).")
    var aCell = TestWovenCell1().GetCell()
    const Theta: Float64 = 54   # deg
    const Phi: Float64 = 270    # deg
    const aSide: Side = Side.Front
    const aDirection = CBeamDirection(Theta, Phi)
    const Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    EXPECT_NEAR(0.100838024, Tdir_dir, 1e-6)
    const Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.193195, Tdir_dif, 1e-6)
    const Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.680730, Rfdir_dif, 1e-6)
    const Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.680730, Rbdir_dif, 1e-6)
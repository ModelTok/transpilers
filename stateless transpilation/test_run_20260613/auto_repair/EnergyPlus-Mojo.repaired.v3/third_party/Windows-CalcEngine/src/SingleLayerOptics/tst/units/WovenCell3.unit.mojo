# Mojo translation of WovenCell3.unit.cpp
# Import modules (assumes .mojo modules at same relative paths)
from WCESingleLayerOptics import CWovenCell, CWovenCellDescription, Material
from WCECommon import Side, CBeamDirection, FenestrationCommon

# Helper function to approximate EXPECT_NEAR (not a 1:1 macro, but preserves logic)
def expect_near(actual: Float64, expected: Float64, tol: Float64):
    if abs(actual - expected) > tol:
        print("FAIL: expected", expected, "got", actual)

class TestWovenCell3:
    var m_Cell: CWovenCell  # No shared_ptr, direct ownership

    def __init__(inout self):
        self.SetUp()

    def SetUp(inout self):
        const Tmat: Float64 = 0
        const Rfmat: Float64 = 0
        const Rbmat: Float64 = 0
        const minLambda: Float64 = 0.3
        const maxLambda: Float64 = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const diameter: Float64 = 6.35   # mm
        const spacing: Float64 = 19.05   # mm
        var aCell = CWovenCellDescription(diameter, spacing)  # no make_shared
        self.m_Cell = CWovenCell(aMaterial, aCell)

    def GetCell(inout self) -> CWovenCell:
        return self.m_Cell

# Test functions (originally TEST_F macros, now methods of the class)
def TestWoven1():
    var testObj = TestWovenCell3()
    var aCell = testObj.GetCell()
    var Theta: Float64 = 0   # deg
    var Phi: Float64 = 0     # deg
    var aFrontSide = Side.Front
    var aBackSide = Side.Back
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir: Float64 = aCell.T_dir_dir(aFrontSide, aDirection)
    expect_near(Tdir_dir, 0.444444444, 1e-6)
    Tdir_dir = aCell.T_dir_dir(aBackSide, aDirection)
    expect_near(Tdir_dir, 0.444444444, 1e-6)
    var Tdir_dif: Float64 = aCell.T_dir_dif(aFrontSide, aDirection)
    expect_near(Tdir_dif, 0.0, 1e-6)
    Tdir_dif = aCell.T_dir_dif(aBackSide, aDirection)
    expect_near(Tdir_dif, 0.0, 1e-6)
    var Rdir_dif: Float64 = aCell.R_dir_dif(aFrontSide, aDirection)
    expect_near(Rdir_dif, 0.0, 1e-6)
    Rdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    expect_near(Rdir_dif, 0.0, 1e-6)

def TestWoven2():
    var testObj = TestWovenCell3()
    var aCell = testObj.GetCell()
    var Theta: Float64 = 45   # deg
    var Phi: Float64 = 0      # deg
    var aFrontSide = Side.Front
    var aBackSide = Side.Back
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir: Float64 = aCell.T_dir_dir(aFrontSide, aDirection)
    expect_near(Tdir_dir, 0.352396986, 1e-6)
    Tdir_dir = aCell.T_dir_dir(aBackSide, aDirection)
    expect_near(Tdir_dir, 0.352396986, 1e-6)
    var Tdir_dif: Float64 = aCell.T_dir_dif(aFrontSide, aDirection)
    expect_near(Tdir_dif, 0.0, 1e-6)
    Tdir_dif = aCell.T_dir_dif(aBackSide, aDirection)
    expect_near(Tdir_dif, 0.0, 1e-6)
    var Rdir_dif: Float64 = aCell.R_dir_dif(aFrontSide, aDirection)
    expect_near(Rdir_dif, 0.0, 1e-6)
    Rdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    expect_near(Rdir_dif, 0.0, 1e-6)

def TestWoven3():
    var testObj = TestWovenCell3()
    var aCell = testObj.GetCell()
    var Theta: Float64 = 78   # deg
    var Phi: Float64 = 45     # deg
    var aFrontSide = Side.Front
    var aBackSide = Side.Back
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir: Float64 = aCell.T_dir_dir(aFrontSide, aDirection)
    expect_near(Tdir_dir, 0.0, 1e-6)
    Tdir_dir = aCell.T_dir_dir(aBackSide, aDirection)
    expect_near(Tdir_dir, 0.0, 1e-6)
    var Tdir_dif: Float64 = aCell.T_dir_dif(aFrontSide, aDirection)
    expect_near(Tdir_dif, 0.0, 1e-6)
    Tdir_dif = aCell.T_dir_dif(aBackSide, aDirection)
    expect_near(Tdir_dif, 0.0, 1e-6)
    var Rdir_dif: Float64 = aCell.R_dir_dif(aFrontSide, aDirection)
    expect_near(Rdir_dif, 0.0, 1e-6)
    Rdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    expect_near(Rdir_dif, 0.0, 1e-6)
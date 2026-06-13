from memory import Arc
from math import isclose
from WCESingleLayerOptics import CUniformDiffuseCell, CFlatCellDescription, ICellDescription, Material
from WCECommon import Side, CBeamDirection

# Helper to mimic EXPECT_NEAR
def expect_near(actual: Float64, expected: Float64, tolerance: Float64, msg: String = ""):
    if not isclose(actual, expected, abs_tol=tolerance):
        print("FAIL: ", msg, " expected ", expected, " got ", actual)
        assert False, msg

struct TestPerfectDiffuseCell1:
    var m_Cell: Arc[CUniformDiffuseCell]

    def __init__(inout self):
        self.m_Cell = Arc[CUniformDiffuseCell]()

    def SetUp(inout self):
        let Tmat = 0.00
        let Rfmat = 0.55
        let Rbmat = 0.55
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        var aCell: Arc[ICellDescription] = Arc[CFlatCellDescription]()
        self.m_Cell = Arc[CUniformDiffuseCell](aMaterial, aCell)

    def GetCell(inout self) -> Arc[CUniformDiffuseCell]:
        return self.m_Cell

def test_TestPerfectDiffuse1():
    print("Begin Test: Perfect diffusing cell (Theta = 0, Phi = 0).")
    var test = TestPerfectDiffuseCell1()
    test.SetUp()
    var aCell = test.GetCell()
    var Theta: Float64 = 0.0
    var Phi: Float64 = 0.0
    var aSide: Side = Side.Front
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    expect_near(Tdir_dir, 0.00000000, 1e-6, "Tdir_dir")
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    expect_near(Tdir_dif, 0.00000000, 1e-6, "Tdir_dif")
    var Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rfdir_dif, 0.55000000, 1e-6, "Rfdir_dif")
    var Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rbdir_dif, 0.55000000, 1e-6, "Rbdir_dif")

def test_TestPerfectDiffuse2():
    print("Begin Test: Perfect diffusing cell (Theta = 45, Phi = 0).")
    var test = TestPerfectDiffuseCell1()
    test.SetUp()
    var aCell = test.GetCell()
    var Theta: Float64 = 45.0
    var Phi: Float64 = 0.0
    var aSide: Side = Side.Front
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    expect_near(Tdir_dir, 0.00000000, 1e-6, "Tdir_dir")
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    expect_near(Tdir_dif, 0.00000000, 1e-6, "Tdir_dif")
    var Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rfdir_dif, 0.55000000, 1e-6, "Rfdir_dif")
    var Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rbdir_dif, 0.55000000, 1e-6, "Rbdir_dif")

def test_TestPerfectDiffuse3():
    print("Begin Test: Perfect diffusing cell (Theta = 78, Phi = 45).")
    var test = TestPerfectDiffuseCell1()
    test.SetUp()
    var aCell = test.GetCell()
    var Theta: Float64 = 78.0
    var Phi: Float64 = 45.0
    var aSide: Side = Side.Front
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    expect_near(Tdir_dir, 0.00000000, 1e-6, "Tdir_dir")
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    expect_near(Tdir_dif, 0.00000000, 1e-6, "Tdir_dif")
    var Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rfdir_dif, 0.55000000, 1e-6, "Rfdir_dif")
    var Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rbdir_dif, 0.55000000, 1e-6, "Rbdir_dif")

def test_TestPerfectDiffuse4():
    print("Begin Test: Perfect diffusing cell (Theta = 54, Phi = 270).")
    var test = TestPerfectDiffuseCell1()
    test.SetUp()
    var aCell = test.GetCell()
    var Theta: Float64 = 54.0
    var Phi: Float64 = 270.0
    var aSide: Side = Side.Front
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    expect_near(Tdir_dir, 0.00000000, 1e-6, "Tdir_dir")
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    expect_near(Tdir_dif, 0.00000000, 1e-6, "Tdir_dif")
    var Rfdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rfdir_dif, 0.55000000, 1e-6, "Rfdir_dif")
    var Rbdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(Rbdir_dif, 0.55000000, 1e-6, "Rbdir_dif")
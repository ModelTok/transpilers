from memory import Arc
from WCESingleLayerOptics import *
from WCECommon import *

class TestVenetianCellFlat45_1:
    var m_Cell: Arc[CVenetianCell]

    def __init__(inout self):
        self.m_Cell = Arc[CVenetianCell]()

    def SetUp(inout self):
        const Tmat = 0.1
        const Rfmat = 0.7
        const Rbmat = 0.7
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const slatWidth = 0.010     # m
        const slatSpacing = 0.010   # m
        const slatTiltAngle = 45
        const curvatureRadius = 0
        const numOfSlatSegments: Int = 2
        var aCellDescription = Arc[CVenetianCellDescription](
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = Arc[CVenetianCell](aMaterial, aCellDescription)

    def GetCell(self) -> Arc[CVenetianCell]:
        return self.m_Cell

def expect_near(expected: Float64, actual: Float64, tolerance: Float64):
    if abs(expected - actual) > tolerance:
        print("FAIL: expected", expected, "actual", actual, "tolerance", tolerance)
        assert False
    else:
        print("PASS: expected", expected, "actual", actual)

def TestVenetian1():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - diffuse-diffuse.")
    var testObj = TestVenetianCellFlat45_1()
    testObj.SetUp()
    var aCell = testObj.GetCell()
    var aSide = Side.Front
    var Tdif_dif = aCell.T_dif_dif(aSide)
    var Rdif_dif = aCell.R_dif_dif(aSide)
    expect_near(0.47122586752693946, Tdif_dif, 1e-6)
    expect_near(0.34565694288233745, Rdif_dif, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell.T_dif_dif(aSide)
    Rdif_dif = aCell.R_dif_dif(aSide)
    expect_near(0.47122586752693946, Tdif_dif, 1e-6)
    expect_near(0.34565694288233745, Rdif_dif, 1e-6)

def TestVenetian2():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - direct-diffuse.")
    var testObj = TestVenetianCellFlat45_1()
    testObj.SetUp()
    var aCell = testObj.GetCell()
    var aSide = Side.Front
    var Theta = 0.0
    var Phi = 0.0
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(0.29289321881345237, Tdir_dir, 1e-6)
    expect_near(0.15853813605369510, Tdir_dif, 1e-6)
    expect_near(0.35939548999199644, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(0.29289321881345237, Tdir_dir, 1e-6)
    expect_near(0.15853813605369516, Tdir_dif, 1e-6)
    expect_near(0.35939548999199655, Rdir_dif, 1e-6)

def TestVenetian3():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - direct-diffuse.")
    var testObj = TestVenetianCellFlat45_1()
    testObj.SetUp()
    var aCell = testObj.GetCell()
    var aSide = Side.Front
    var Theta = 18.0
    var Phi = 180.0
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(0.29289321881345237, Tdir_dir, 1e-6)
    expect_near(0.15853813605369510, Tdir_dif, 1e-6)
    expect_near(0.35939548999199644, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(0.29289321881345237, Tdir_dir, 1e-6)
    expect_near(0.15853813605369516, Tdir_dif, 1e-6)
    expect_near(0.35939548999199655, Rdir_dif, 1e-6)

def TestVenetian4():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - direct-diffuse.")
    var testObj = TestVenetianCellFlat45_1()
    testObj.SetUp()
    var aCell = testObj.GetCell()
    var aSide = Side.Front
    var Theta = 45.0
    var Phi = 90.0
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(1.0, Tdir_dir, 1e-6)
    expect_near(0.0, Tdir_dif, 1e-6)
    expect_near(0.0, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    expect_near(0.0, Tdir_dir, 1e-6)
    expect_near(0.195251, Tdir_dif, 1e-6)
    expect_near(0.545433, Rdir_dif, 1e-6)
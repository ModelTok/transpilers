from WCESingleLayerOptics import CVenetianCellDescription
from WCEViewer import CBeamDirection
from WCECommon import SquareMatrix, Side
from Math import abs

struct TestVenetianCellDescriptionCurvedMinus55:
    var m_Cell: Pointer[CVenetianCellDescription]

    def SetUp(inout self):
        let slatWidth: Float64 = 0.076200     # m
        let slatSpacing: Float64 = 0.057150   # m
        let slatTiltAngle: Float64 = -55.000000
        let curvatureRadius: Float64 = 0.123967
        let aNumOfSlats: Int = 2
        self.m_Cell = Pointer[CVenetianCellDescription].alloc()
        self.m_Cell.init(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, aNumOfSlats
        )

    def GetCell(self) -> Pointer[CVenetianCellDescription]:
        return self.m_Cell

def expect_near(val: Float64, expected: Float64, tol: Float64):
    if abs(val - expected) > tol:
        print("FAIL: expected", expected, "got", val)
        assert False

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian1_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell: Pointer[CVenetianCellDescription] = fixture.GetCell()
    let size: Int = aCell[].numberOfSegments()
    let viewFactors = aCell[].viewFactors()
    let correctResults = SquareMatrix(
        [
            [0.000000, 0.489698, 0.291815, 0.157211, 0.002610, 0.058462],
            [0.725605, 0.000000, 0.012174, 0.047629, 0.026822, 0.187769],
            [0.432393, 0.012174, 0.000000, 0.030708, 0.093504, 0.431220],
            [0.157211, 0.032144, 0.020724, 0.000000, 0.591054, 0.198676],
            [0.003867, 0.026822, 0.093505, 0.875787, 0.000000, 0.000000],
            [0.086626, 0.187769, 0.431220, 0.294386, 0.000000, 0.000000]
        ]
    )
    for i in range(size):
        for j in range(size):
            expect_near(correctResults[i][j], viewFactors[i][j], 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian2_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (0, 0)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(0, 0)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian3_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (18, -45)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(18, -45)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.083505089496152846, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian4_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (18, -90)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(18, -90)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.15628564957180935, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian5_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (36, -30)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(36, -30)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.18561572366619078, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian6_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (36, -60)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(36, -60)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.38899294389431732, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian7_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (54, -30)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(54, -30)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.43410409895720364, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian8_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (36, -90)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(36, -90)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.46343417304788243, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian9_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (54, -60)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(54, -60)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.74696434645194043, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian10_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (54, -90)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(54, -90)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0.80161756574503285, Tdir_dir, 1e-6)

def TestVenetianCellDescriptionCurvedMinus55_TestVenetian11_Test():
    SCOPED_TRACE: "Begin Test: Venetian cell (Curved, -55 degrees slats) - Direct-direct component (76.5, -45)."
    var fixture = TestVenetianCellDescriptionCurvedMinus55()
    fixture.SetUp()
    var aCell = fixture.GetCell()
    var aDirection = CBeamDirection(76.5, -45)
    let Tdir_dir: Float64 = aCell[].T_dir_dir(Side.Front, aDirection)
    expect_near(0, Tdir_dir, 1e-6)
<<<FILE>>>
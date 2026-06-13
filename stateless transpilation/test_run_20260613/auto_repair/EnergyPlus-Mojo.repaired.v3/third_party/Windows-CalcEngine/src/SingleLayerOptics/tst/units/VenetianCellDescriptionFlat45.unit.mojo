from ......WCESingleLayerOptics import CVenetianCellDescription, CBeamDirection, Side
from ......Viewer.WCEViewer import *
from ......Common.WCECommon import SquareMatrix

struct TestVenetianCellDescriptionFlat45:
    var m_Cell: CVenetianCellDescription

    def __init__(inout self):
        self.m_Cell = CVenetianCellDescription()

    def SetUp(inout self):
        let slatWidth = 0.020
        let slatSpacing = 0.010
        let slatTiltAngle = 45
        let curvatureRadius = 0
        let aNumOfSlats: UInt = 2
        self.m_Cell = CVenetianCellDescription(slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, aNumOfSlats)

    def GetCell(self) -> CVenetianCellDescription:
        return self.m_Cell

def TestVenetian1():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - View Factors.")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let size = aCell.numberOfSegments()
    let viewFactors = aCell.viewFactors()
    let correctResults = SquareMatrix([
        [0.000000, 0.076120, 0.024913, 0.135779, 0.145871, 0.617317],
        [0.076120, 0.000000, 0.000000, 0.145871, 0.471446, 0.306563],
        [0.024913, 0.000000, 0.000000, 0.617317, 0.306563, 0.051207],
        [0.135779, 0.145871, 0.617317, 0.000000, 0.076120, 0.024913],
        [0.145871, 0.471446, 0.306563, 0.076120, 0.000000, 0.000000],
        [0.617317, 0.306563, 0.051207, 0.024913, 0.000000, 0.000000]
    ])
    for i in range(size):
        for j in range(size):
            assert abs(correctResults[i][j] - viewFactors[i][j]) < 1e-6

def TestVenetian2():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (0, 0).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(0, 0)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0 - Tdir_dir) < 1e-6

def TestVenetian3():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (45, 90).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(45, 90)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(1 - Tdir_dir) < 1e-6

def TestVenetian4():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (76.5, 90).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(76.5, 90)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0 - Tdir_dir) < 1e-6

def TestVenetian5():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (76.5, 45).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(76.5, 45)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0 - Tdir_dir) < 1e-6

def TestVenetian6():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (54, 90).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(54, 90)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0.46771558343367653 - Tdir_dir) < 1e-6

def TestVenetian7():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (54, 60).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(54, 60)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0.72849686418372972 - Tdir_dir) < 1e-6

def TestVenetian8():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (36, 90).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(36, 90)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0.61327273437110064 - Tdir_dir) < 1e-6

def TestVenetian9():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (54, 30).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(54, 30)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0.55903542711488330 - Tdir_dir) < 1e-6

def TestVenetian10():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (36, 60).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(36, 60)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0.47561567265428234 - Tdir_dir) < 1e-6

def TestVenetian11():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - Direct-direct component (36, 30).")
    var fixture = TestVenetianCellDescriptionFlat45()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aDirection = CBeamDirection(36, 30)
    let Tdir_dir = aCell.T_dir_dir(Side.Front, aDirection)
    assert abs(0.099529586007794477 - Tdir_dir) < 1e-6
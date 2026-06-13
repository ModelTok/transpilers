from Pointer import Pointer, make_shared
from testing import assert_approx_equal
from WCECommon import Side, CBeamDirection, Material
from WCESingleLayerOptics import CCircularCellDescription, CPerforatedCell, ICellDescription

class TestCircularPerforatedCell:
    var m_DescriptionCell: CCircularCellDescription
    var m_PerforatedCell: CPerforatedCell

    def __init__(self):

    def SetUp(self):
        let Tmat = 0.1
        let Rfmat = 0.7
        let Rbmat = 0.8
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let x = 10
        let y = 10
        let thickness = 1
        let radius = 5
        self.m_DescriptionCell = CCircularCellDescription(x, y, thickness, radius)
        self.m_PerforatedCell = CPerforatedCell(aMaterial, self.m_DescriptionCell)

    def GetCell(self) -> CPerforatedCell&:
        return self.m_PerforatedCell

    def GetDescription(self) -> CCircularCellDescription&:
        return self.m_DescriptionCell

@test
def TestCircularPerforatedCell_TestCircular1():
    var fixture = TestCircularPerforatedCell()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aCellDescription = fixture.GetDescription()
    let Theta = 0.0
    let Phi = 0.0
    let aFrontSide = Side.Front
    let aBackSide = Side.Back
    let aDirection = CBeamDirection(Theta, Phi)
    let Tdir_dir = aCellDescription.T_dir_dir(aFrontSide, aDirection)
    assert_approx_equal(Tdir_dir, 0.785398163, 1e-6)
    let Tdir_dif = aCell.T_dir_dif(aFrontSide, aDirection)
    assert_approx_equal(Tdir_dif, 0.021460184, 1e-6)
    let Rfdir_dif = aCell.R_dir_dif(aFrontSide, aDirection)
    assert_approx_equal(Rfdir_dif, 0.150221286, 1e-6)
    let Rbdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    assert_approx_equal(Rbdir_dif, 0.171681469, 1e-6)

@test
def TestCircularPerforatedCell_TestCircular2():
    var fixture = TestCircularPerforatedCell()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aCellDescription = fixture.GetDescription()
    let Theta = 45.0
    let Phi = 0.0
    let aFrontSide = Side.Front
    let aBackSide = Side.Back
    let aDirection = CBeamDirection(Theta, Phi)
    let Tdir_dir = aCellDescription.T_dir_dir(aFrontSide, aDirection)
    assert_approx_equal(Tdir_dir, 0.706858347, 1e-6)
    let Tdir_dif = aCell.T_dir_dif(aFrontSide, aDirection)
    assert_approx_equal(Tdir_dif, 0.029314165, 1e-6)
    let Rfdir_dif = aCell.R_dir_dif(aFrontSide, aDirection)
    assert_approx_equal(Rfdir_dif, 0.205199157, 1e-6)
    let Rbdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    assert_approx_equal(Rbdir_dif, 0.234513322, 1e-6)

@test
def TestCircularPerforatedCell_TestCircular3():
    var fixture = TestCircularPerforatedCell()
    fixture.SetUp()
    let aCell = fixture.GetCell()
    let aCellDescription = fixture.GetDescription()
    let Theta = 78.0
    let Phi = 45.0
    let aFrontSide = Side.Front
    let aBackSide = Side.Back
    let aDirection = CBeamDirection(Theta, Phi)
    let Tdir_dir = aCellDescription.T_dir_dir(aFrontSide, aDirection)
    assert_approx_equal(Tdir_dir, 0.415897379, 1e-6)
    let Tdir_dif = aCell.T_dir_dif(aFrontSide, aDirection)
    assert_approx_equal(Tdir_dif, 0.058410262, 1e-6)
    let Rfdir_dif = aCell.R_dir_dif(aFrontSide, aDirection)
    assert_approx_equal(Rfdir_dif, 0.408871835, 1e-6)
    let Rbdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    assert_approx_equal(Rbdir_dif, 0.467282097, 1e-6)
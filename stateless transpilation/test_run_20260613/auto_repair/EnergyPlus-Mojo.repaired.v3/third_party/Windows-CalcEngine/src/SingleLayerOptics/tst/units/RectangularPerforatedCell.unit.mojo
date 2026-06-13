from memory import shared_ptr, make_shared
from testing import Test, Expect
from WCECommon import *
from WCESingleLayerOptics import *

class TestRectangularPerforatedCell(Test):
    var m_DescriptionCell: shared_ptr[CRectangularCellDescription]
    var m_PerforatedCell: shared_ptr[CPerforatedCell]

    def SetUp() raises:
        const Tmat = 0.1
        const Rfmat = 0.7
        const Rbmat = 0.8
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const x = 10          # mm
        const y = 10          # mm
        const thickness = 1   # mm
        const xHole = 5       # mm
        const yHole = 5       # mm
        self.m_DescriptionCell = make_shared[CRectangularCellDescription](x, y, thickness, xHole, yHole)
        self.m_PerforatedCell = make_shared[CPerforatedCell](aMaterial, self.m_DescriptionCell)

    def GetCell() -> shared_ptr[CPerforatedCell]:
        return self.m_PerforatedCell

    def GetDescription() -> shared_ptr[CRectangularCellDescription]:
        return self.m_DescriptionCell

def TestRectangular1() raises:
    SCOPED_TRACE("Begin Test: Rectangular perforated cell (Theta = 0, Phi = 0).")
    var aCell: shared_ptr[CPerforatedCell] = TestRectangularPerforatedCell().GetCell()
    var aCellDescription: shared_ptr[ICellDescription] = TestRectangularPerforatedCell().GetDescription()
    const Theta = 0   # deg
    const Phi = 0     # deg
    var aFrontSide = Side.Front
    var aBackSide = Side.Back
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCellDescription.T_dir_dir(aFrontSide, aDirection)
    Expect.near(0.25, Tdir_dir, 1e-6)
    var Tdir_dif = aCell.T_dir_dif(aFrontSide, aDirection)
    Expect.near(0.075, Tdir_dif, 1e-6)
    var Rfdir_dif = aCell.R_dir_dif(aFrontSide, aDirection)
    Expect.near(0.525, Rfdir_dif, 1e-6)
    var Rbdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    Expect.near(0.6, Rbdir_dif, 1e-6)

def TestRectangular2() raises:
    SCOPED_TRACE("Begin Test: Rectangular perforated cell (Theta = 45, Phi = 0).")
    var aCell: shared_ptr[CPerforatedCell] = TestRectangularPerforatedCell().GetCell()
    var aCellDescription: shared_ptr[ICellDescription] = TestRectangularPerforatedCell().GetDescription()
    var Theta = 45   # deg
    var Phi = 0      # deg
    var aFrontSide = Side.Front
    var aBackSide = Side.Back
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCellDescription.T_dir_dir(aFrontSide, aDirection)
    Expect.near(0.2, Tdir_dir, 1e-6)
    var Tdir_dif = aCell.T_dir_dif(aFrontSide, aDirection)
    Expect.near(0.08, Tdir_dif, 1e-6)
    var Rfdir_dif = aCell.R_dir_dif(aFrontSide, aDirection)
    Expect.near(0.56, Rfdir_dif, 1e-6)
    var Rbdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    Expect.near(0.64, Rbdir_dif, 1e-6)

def TestRectangular3() raises:
    SCOPED_TRACE("Begin Test: Rectangular perforated cell (Theta = 45, Phi = 45).")
    var aCell: shared_ptr[CPerforatedCell] = TestRectangularPerforatedCell().GetCell()
    var aCellDescription: shared_ptr[ICellDescription] = TestRectangularPerforatedCell().GetDescription()
    const Theta = 45   # deg
    const Phi = 45     # deg
    var aFrontSide = Side.Front
    var aBackSide = Side.Back
    var aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCellDescription.T_dir_dir(aFrontSide, aDirection)
    Expect.near(0.184289322, Tdir_dir, 1e-6)
    var Tdir_dif = aCell.T_dir_dif(aFrontSide, aDirection)
    Expect.near(0.081571068, Tdir_dif, 1e-6)
    var Rfdir_dif = aCell.R_dir_dif(aFrontSide, aDirection)
    Expect.near(0.570997475, Rfdir_dif, 1e-6)
    var Rbdir_dif = aCell.R_dir_dif(aBackSide, aDirection)
    Expect.near(0.652568542, Rbdir_dif, 1e-6)
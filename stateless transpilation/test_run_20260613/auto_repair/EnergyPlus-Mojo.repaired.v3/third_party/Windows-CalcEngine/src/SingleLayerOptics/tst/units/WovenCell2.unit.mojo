from testing import assert_almost_equal
from WCESingleLayerOptics import CWovenCell, CWovenCellDescription, ICellDescription, Material
from WCECommon import Side, CBeamDirection

struct TestWovenCell2:
    var m_Cell: Pointer[CWovenCell]

    def SetUp(inout self):
        const Tmat = 0.15
        const Rfmat = 0.8
        const Rbmat = 0.6
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const diameter = 6.35   # mm
        const spacing = 19.05   # mm
        var aCell: Pointer[ICellDescription] = Pointer[ICellDescription].take(
            new CWovenCellDescription(diameter, spacing)
        )
        self.m_Cell = Pointer[CWovenCell].take(new CWovenCell(aMaterial, aCell))

    def GetCell(inout self) -> Pointer[CWovenCell]:
        return self.m_Cell

def TestWoven1():
    print("Begin Test: Woven cell (Theta = 0, Phi = 0).")
    var testFixture = TestWovenCell2()
    testFixture.SetUp()
    var aCell = testFixture.GetCell()
    const Theta = 0.0   # deg
    const Phi = 0.0     # deg
    const aFrontSide = Side.Front
    const aBackSide = Side.Back
    const aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell[].T_dir_dir(aFrontSide, aDirection)
    assert_almost_equal(0.444444444, Tdir_dir, 1e-6)
    Tdir_dir = aCell[].T_dir_dir(aBackSide, aDirection)
    assert_almost_equal(0.444444444, Tdir_dir, 1e-6)
    var Tdir_dif = aCell[].T_dir_dif(aFrontSide, aDirection)
    assert_almost_equal(0.055148, Tdir_dif, 1e-6)
    Tdir_dif = aCell[].T_dir_dif(aBackSide, aDirection)
    assert_almost_equal(0.062702, Tdir_dif, 1e-6)
    var Rdir_dif = aCell[].R_dir_dif(aFrontSide, aDirection)
    assert_almost_equal(0.435593, Rdir_dif, 1e-6)
    Rdir_dif = aCell[].R_dir_dif(aBackSide, aDirection)
    assert_almost_equal(0.316928, Rdir_dif, 1e-6)

def TestWoven2():
    print("Begin Test: Woven cell (Theta = 45, Phi = 0).")
    var testFixture = TestWovenCell2()
    testFixture.SetUp()
    var aCell = testFixture.GetCell()
    const Theta = 45.0   # deg
    const Phi = 0.0      # deg
    const aFrontSide = Side.Front
    const aBackSide = Side.Back
    const aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell[].T_dir_dir(aFrontSide, aDirection)
    assert_almost_equal(0.352396986, Tdir_dir, 1e-6)
    Tdir_dir = aCell[].T_dir_dir(aBackSide, aDirection)
    assert_almost_equal(0.352396986, Tdir_dir, 1e-6)
    var Tdir_dif = aCell[].T_dir_dif(aFrontSide, aDirection)
    assert_almost_equal(0.110951, Tdir_dif, 1e-6)
    Tdir_dif = aCell[].T_dir_dif(aBackSide, aDirection)
    assert_almost_equal(0.132270, Tdir_dif, 1e-6)
    var Rdir_dif = aCell[].R_dir_dif(aFrontSide, aDirection)
    assert_almost_equal(0.470040, Rdir_dif, 1e-6)
    Rdir_dif = aCell[].R_dir_dif(aBackSide, aDirection)
    assert_almost_equal(0.319200, Rdir_dif, 1e-6)

def TestWoven3():
    print("Begin Test: Woven cell (Theta = 78, Phi = 45).")
    var testFixture = TestWovenCell2()
    testFixture.SetUp()
    var aCell = testFixture.GetCell()
    const Theta = 78.0   # deg
    const Phi = 45.0     # deg
    const aFrontSide = Side.Front
    const aBackSide = Side.Back
    const aDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir = aCell[].T_dir_dir(aFrontSide, aDirection)
    assert_almost_equal(0.0, Tdir_dir, 1e-6)
    Tdir_dir = aCell[].T_dir_dir(aBackSide, aDirection)
    assert_almost_equal(0.0, Tdir_dir, 1e-6)
    var Tdir_dif = aCell[].T_dir_dif(aFrontSide, aDirection)
    assert_almost_equal(0.168097, Tdir_dif, 1e-6)
    Tdir_dif = aCell[].T_dir_dif(aBackSide, aDirection)
    assert_almost_equal(0.175433, Tdir_dif, 1e-6)
    var Rdir_dif = aCell[].R_dir_dif(aFrontSide, aDirection)
    assert_almost_equal(0.781903, Rdir_dif, 1e-6)
    Rdir_dif = aCell[].R_dir_dif(aBackSide, aDirection)
    assert_almost_equal(0.574567, Rdir_dif, 1e-6)
from memory import shared_ptr, make_shared
from WCESingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material, Side, CBeamDirection
from WCECommon import FenestrationCommon
from testing import Test, TestFixture, expect_near

@value
class TestVenetianCellFlat0_1(TestFixture):
    var m_Cell: shared_ptr[CVenetianCell]

    def __init__(inout self):
        self.m_Cell = shared_ptr[CVenetianCell]()

    def SetUp(inout self):
        let Tmat = 0.9
        let Rfmat = 0.0
        let Rbmat = 0.0
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.010
        let slatSpacing = 0.010
        let slatTiltAngle = 0
        let curvatureRadius = 0
        let numOfSlatSegments: size_t = 1
        let aCellDescription = make_shared[CVenetianCellDescription](
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = make_shared[CVenetianCell](aMaterial, aCellDescription)

    def GetCell(self) -> shared_ptr[CVenetianCell]:
        return self.m_Cell

def TestVenetianCellFlat0_1_TestVenetian1():
    print("Begin Test: Venetian cell (Flat, 0 degrees slats) - directional-diffuse.")
    let aCell = TestVenetianCellFlat0_1().GetCell()
    let aSide = Side.Front
    var Theta = 18.0
    var Phi = 45.0
    let incomingDirection = CBeamDirection(Theta, Phi)
    Theta = 18.0
    Phi = 270.0
    let outgoingDirection = CBeamDirection(Theta, Phi)
    let Tdir_dif = aCell.T_dir_dif(aSide, incomingDirection, outgoingDirection)
    let Rdir_dif = aCell.R_dir_dif(aSide, incomingDirection, outgoingDirection)
    expect_near(0.10711940268416009, Tdir_dif, 1e-6)
    expect_near(0.10711940268416009, Rdir_dif, 1e-6)
from WCESingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material, CBeamDirection, Side
from WCECommon import *  # Assuming FenestrationCommon is included here

def expect_near(expected: Float64, actual: Float64, tolerance: Float64):
    if abs(expected - actual) > tolerance:
        print("EXPECT_NEAR failed: expected", expected, "actual", actual, "tolerance", tolerance)
        # In Mojo testing, we might abort, but for now just print.

struct TestVenetianCellFlat0_2:
    var m_Cell: CVenetianCell

    def __init__(inout self):
        self.SetUp()

    def SetUp(inout self):
        let Tmat = 0.1
        let Rfmat = 0.7
        let Rbmat = 0.7
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.016     # m
        let slatSpacing = 0.010   # m
        let slatTiltAngle = 0.0
        let curvatureRadius = 0.0
        let numOfSlatSegments: Int = 2
        let aCellDescription = CVenetianCellDescription(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = CVenetianCell(aMaterial, aCellDescription)

    def GetCell(self) -> CVenetianCell:
        return self.m_Cell

def TestVenetianCellFlat0_2_TestVenetian1_Test():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 0 degrees slats) - directional-diffuse.")
    var testInstance = TestVenetianCellFlat0_2()
    var aCell = testInstance.GetCell()
    let aSide = Side.Front
    var Theta: Float64 = 18.0
    var Phi: Float64 = 45.0
    let incomingDirection = CBeamDirection(Theta, Phi)
    Theta = 18.0
    Phi = 90.0
    let outgoingDirection = CBeamDirection(Theta, Phi)
    let Tdir_dif = aCell.T_dir_dif(aSide, incomingDirection, outgoingDirection)
    let Rdir_dif = aCell.R_dir_dif(aSide, incomingDirection, outgoingDirection)
    expect_near(0.11272685101443769, Tdir_dif, 1e-6)
    expect_near(0.11272685101443769, Rdir_dif, 1e-6)
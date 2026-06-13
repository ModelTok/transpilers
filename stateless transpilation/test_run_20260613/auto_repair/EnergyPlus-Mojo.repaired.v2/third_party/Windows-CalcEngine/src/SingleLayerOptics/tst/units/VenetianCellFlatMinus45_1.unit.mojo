from ......WCECommon import Side, CBeamDirection
from ......WCESingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material

def expect_near(actual: Float64, expected: Float64, tolerance: Float64):
    if abs(actual - expected) > tolerance:
        print("FAIL: expected", expected, "but got", actual)
        assert False

class TestVenetianCellFlatMinus45_1:
    var m_Cell: Pointer[CVenetianCell]

    def __init__(inout self):
        self.m_Cell = Pointer[CVenetianCell]()
        self.SetUp()

    def SetUp(inout self):
        let Tmat = 0.1
        let Rfmat = 0.7
        let Rbmat = 0.7
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.010
        let slatSpacing = 0.010
        let slatTiltAngle = -45
        let curvatureRadius = 0
        let numOfSlatSegments: Int = 2
        let aCellDescription = CVenetianCellDescription(slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = Pointer[CVenetianCell].alloc(aMaterial, aCellDescription)

    def GetCell(self) -> Ref[CVenetianCell]:
        return self.m_Cell[]

    def TestVenetian1(self):
        print("Begin Test: Venetian cell (Flat, -45 degrees slats) - diffuse-diffuse.")
        let aCell = self.GetCell()
        var aSide = Side.Front
        var Tdif_dif = aCell.T_dif_dif(aSide)
        var Rdif_dif = aCell.R_dif_dif(aSide)
        expect_near(Tdif_dif, 0.47122586752693946, 1e-6)
        expect_near(Rdif_dif, 0.34565694288233745, 1e-6)
        aSide = Side.Back
        Tdif_dif = aCell.T_dif_dif(aSide)
        Rdif_dif = aCell.R_dif_dif(aSide)
        expect_near(Tdif_dif, 0.47122586752693946, 1e-6)
        expect_near(Rdif_dif, 0.34565694288233745, 1e-6)

    def TestVenetian2(self):
        print("Begin Test: Venetian cell (Flat, -45 degrees slats) - direct-diffuse.")
        let aCell = self.GetCell()
        var aSide = Side.Front
        let Theta = 0.0
        let Phi = 0.0
        let aDirection = CBeamDirection(Theta, Phi)
        var Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
        var Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
        var Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
        expect_near(Tdir_dir, 0.29289321881345237, 1e-6)
        expect_near(Tdir_dif, 0.15853813605369516, 1e-6)
        expect_near(Rdir_dif, 0.35939548999199655, 1e-6)
        aSide = Side.Back
        Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
        Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
        Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
        expect_near(Tdir_dir, 0.29289321881345237, 1e-6)
        expect_near(Tdir_dif, 0.15853813605369510, 1e-6)
        expect_near(Rdir_dif, 0.35939548999199644, 1e-6)

def main():
    let test = TestVenetianCellFlatMinus45_1()
    test.TestVenetian1()
    test.TestVenetian2()
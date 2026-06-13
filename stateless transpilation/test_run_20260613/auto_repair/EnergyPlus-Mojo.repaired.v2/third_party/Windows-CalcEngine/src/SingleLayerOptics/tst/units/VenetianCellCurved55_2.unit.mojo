from memory import shared_ptr, make_shared
from WCESingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material, Side, CBeamDirection
from WCECommon import *
from testing import *

class TestVenetianCellCurved55_2(Test):
    var m_Cell: shared_ptr[CVenetianCell]

    def SetUp(self):
        const Tmat = 0.1
        const Rfmat = 0.3
        const Rbmat = 0.7
        const minLambda = 0.3
        const maxLambda = 2.5
        const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        const slatWidth = 0.076200
        const slatSpacing = 0.057150
        const slatTiltAngle = 55.000000
        const curvatureRadius = 0.123967
        var numOfSlatSegments: size_t = 2
        var aCellDescription: shared_ptr[CVenetianCellDescription] = make_shared[CVenetianCellDescription](
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)
        self.m_Cell = make_shared[CVenetianCell](aMaterial, aCellDescription)

    def GetCell(self) -> shared_ptr[CVenetianCell]:
        return self.m_Cell

def TestVenetian1():
    SCOPED_TRACE("Begin Test: Venetian cell (Curved, -55 degrees slats - diffuse-diffuse).")
    var aCell: shared_ptr[CVenetianCell] = GetCell()
    var aSide: Side = Side.Front
    var Tdif_dif: Float64 = aCell.T_dif_dif(aSide)
    var Rdif_dif: Float64 = aCell.R_dif_dif(aSide)
    EXPECT_NEAR(0.260287, Tdif_dif, 1e-6)
    EXPECT_NEAR(0.196089, Rdif_dif, 1e-6)
    aSide = Side.Back
    Tdif_dif = aCell.T_dif_dif(aSide)
    Rdif_dif = aCell.R_dif_dif(aSide)
    EXPECT_NEAR(0.260287, Tdif_dif, 1e-6)
    EXPECT_NEAR(0.399713, Rdif_dif, 1e-6)

def TestVenetian2():
    SCOPED_TRACE("Begin Test: Venetian cell (Curved, -55 degrees slats - direct-diffuse).")
    var aCell: shared_ptr[CVenetianCell] = GetCell()
    var aSide: Side = Side.Front
    var Theta: Float64 = 0
    var Phi: Float64 = 0
    var aDirection: CBeamDirection = CBeamDirection(Theta, Phi)
    var Tdir_dir: Float64 = aCell.T_dir_dir(aSide, aDirection)
    var Tdir_dif: Float64 = aCell.T_dir_dif(aSide, aDirection)
    var Rdir_dif: Float64 = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.000000, Tdir_dir, 1e-6)
    EXPECT_NEAR(0.113713, Tdir_dif, 1e-6)
    EXPECT_NEAR(0.217891, Rdir_dif, 1e-6)
    aSide = Side.Back
    Tdir_dir = aCell.T_dir_dir(aSide, aDirection)
    Tdir_dif = aCell.T_dir_dif(aSide, aDirection)
    Rdir_dif = aCell.R_dir_dif(aSide, aDirection)
    EXPECT_NEAR(0.000000, Tdir_dir, 1e-6)
    EXPECT_NEAR(0.131946, Tdir_dif, 1e-6)
    EXPECT_NEAR(0.469503, Rdir_dif, 1e-6)

def main():
    TestVenetian1()
    TestVenetian2()
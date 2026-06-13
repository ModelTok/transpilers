# EXTERNAL DEPS (to wire in glue):
# - SingleLayerOptics.CVenetianCell (source: WCESingleLayerOptics.hpp/cpp)
# - SingleLayerOptics.CVenetianCellDescription (source: WCESingleLayerOptics.hpp/cpp)
# - SingleLayerOptics.Material.singleBandMaterial (source: WCESingleLayerOptics.hpp/cpp)
# - FenestrationCommon.Side (source: WCECommon.hpp)
# - FenestrationCommon.Side.Front (source: WCECommon.hpp)
# - FenestrationCommon.CBeamDirection (source: WCECommon.hpp)

from testing import assert_true
from math import abs

from SingleLayerOptics import CVenetianCell, CVenetianCellDescription, Material
from FenestrationCommon import CBeamDirection, Side


struct TestVenetianCellFlat0_2:
    var m_Cell: CVenetianCell

    fn __init__(out self):
        # create material
        let Tmat: Float64 = 0.1
        let Rfmat: Float64 = 0.7
        let Rbmat: Float64 = 0.7
        let minLambda: Float64 = 0.3
        let maxLambda: Float64 = 2.5
        let aMaterial = Material.singleBandMaterial(
            Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda
        )

        # make cell geometry
        let slatWidth: Float64 = 0.016     # m
        let slatSpacing: Float64 = 0.010   # m
        let slatTiltAngle: Int = 0
        let curvatureRadius: Int = 0
        let numOfSlatSegments: Int = 2

        let aCellDescription = CVenetianCellDescription(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments
        )

        self.m_Cell = CVenetianCell(aMaterial, aCellDescription)

    fn GetCell(ref self) -> CVenetianCell:
        return self.m_Cell

    fn TestVenetian1(ref self):
        # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 0 degrees slats) - directional-diffuse.")

        let aCell = self.GetCell()

        # Front side
        let aSide = Side.Front
        var Theta: Float64 = 18.0
        var Phi: Float64 = 45.0
        let incomingDirection = CBeamDirection(Theta, Phi)

        Theta = 18.0
        Phi = 90.0
        let outgoingDirection = CBeamDirection(Theta, Phi)

        let Tdir_dif = aCell.T_dir_dif(aSide, incomingDirection, outgoingDirection)
        let Rdir_dif = aCell.R_dir_dif(aSide, incomingDirection, outgoingDirection)

        assert_true(
            abs(Tdir_dif - 0.11272685101443769) <= 1e-6,
            "Tdir_dif expected ~0.11272685101443769, got " + str(Tdir_dif),
        )
        assert_true(
            abs(Rdir_dif - 0.11272685101443769) <= 1e-6,
            "Rdir_dif expected ~0.11272685101443769, got " + str(Rdir_dif),
        )


fn main():
    let fixture = TestVenetianCellFlat0_2()
    fixture.TestVenetian1()
    print("TestVenetian1 passed.")

# EXTERNAL DEPS (to wire in glue):
# - SingleLayerOptics.CVenetianCell (source: WCESingleLayerOptics.hpp/cpp)
# - SingleLayerOptics.CVenetianCellDescription (source: WCESingleLayerOptics.hpp/cpp)
# - SingleLayerOptics.Material.singleBandMaterial (source: WCESingleLayerOptics.hpp/cpp)
# - FenestrationCommon.Side (source: WCECommon.hpp)
# - FenestrationCommon.Side.Front (source: WCECommon.hpp)
# - FenestrationCommon.CBeamDirection (source: WCECommon.hpp)

import unittest

from SingleLayerOptics import (
    CVenetianCell,
    CVenetianCellDescription,
    Material,
)
from FenestrationCommon import CBeamDirection, Side


class TestVenetianCellFlat0_2(unittest.TestCase):
    def setUp(self):
        # create material
        Tmat = 0.1
        Rfmat = 0.7
        Rbmat = 0.7
        minLambda = 0.3
        maxLambda = 2.5
        aMaterial = Material.singleBandMaterial(
            Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda
        )

        # make cell geometry
        slatWidth = 0.016     # m
        slatSpacing = 0.010   # m
        slatTiltAngle = 0
        curvatureRadius = 0
        numOfSlatSegments = 2

        aCellDescription = CVenetianCellDescription(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments
        )

        self.m_Cell = CVenetianCell(aMaterial, aCellDescription)

    def GetCell(self):
        return self.m_Cell

    def test_TestVenetian1(self):
        # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 0 degrees slats) - directional-diffuse.")
        with self.subTest(
            msg="Begin Test: Venetian cell (Flat, 0 degrees slats) - directional-diffuse."
        ):
            aCell = self.GetCell()

            # Front side
            aSide = Side.Front
            Theta = 18
            Phi = 45
            incomingDirection = CBeamDirection(Theta, Phi)

            Theta = 18
            Phi = 90
            outgoingDirection = CBeamDirection(Theta, Phi)

            Tdir_dif = aCell.T_dir_dif(aSide, incomingDirection, outgoingDirection)
            Rdir_dif = aCell.R_dir_dif(aSide, incomingDirection, outgoingDirection)

            self.assertAlmostEqual(0.11272685101443769, Tdir_dif, delta=1e-6)
            self.assertAlmostEqual(0.11272685101443769, Rdir_dif, delta=1e-6)

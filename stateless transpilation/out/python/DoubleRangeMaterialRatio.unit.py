# EXTERNAL DEPS (to wire in glue):
# - SingleLayerOptics.Material.dualBandMaterial (from WCESingleLayerOptics.hpp)
# - SingleLayerOptics.CMaterial (from WCESingleLayerOptics.hpp)
# - SingleLayerOptics.CMaterial.getProperty (from WCESingleLayerOptics.hpp)
# - SingleLayerOptics.CMaterial.getBandProperties (from WCESingleLayerOptics.hpp)
# - FenestrationCommon.Property (from WCESingleLayerOptics.hpp dependencies)
# - FenestrationCommon.Side (from WCESingleLayerOptics.hpp dependencies)

import unittest
from typing import List, Protocol


class Property:
    """Stub for FenestrationCommon::Property enum (SingleLayerOptics namespace)."""
    T = "T"
    R = "R"


class Side:
    """Stub for FenestrationCommon::Side enum (SingleLayerOptics namespace)."""
    Front = "Front"
    Back = "Back"


class CMaterial(Protocol):
    """Stub for SingleLayerOptics::CMaterial interface."""
    def getProperty(self, prop: str, side: str) -> float: ...
    def getBandProperties(self, prop: str, side: str) -> List[float]: ...


class Material:
    """Stub for SingleLayerOptics::Material namespace."""
    @staticmethod
    def dualBandMaterial(Tsol_f: float, Tsol_b: float, Rfsol: float, Rbsol: float,
                          Tvis_f: float, Tvis_b: float, Rfvis: float, Rbvis: float) -> CMaterial:
        raise NotImplementedError(
            "Wire to SingleLayerOptics::Material::dualBandMaterial"
        )


# Creation of double range material with provided ratio
class TestDoubleRangeMaterialRatio(unittest.TestCase):
    """Test fixture equivalent to C++ TestDoubleRangeMaterialRatio (using namespace SingleLayerOptics; using namespace FenestrationCommon;)."""

    def setUp(self):
        # Solar range material
        Tsol = 0.1
        Rfsol = 0.7
        Rbsol = 0.7

        # Visible range
        Tvis = 0.2
        Rfvis = 0.6
        Rbvis = 0.6

        self.m_Material = Material.dualBandMaterial(Tsol, Tsol, Rfsol, Rbsol, Tvis, Tvis, Rfvis, Rbvis)

    def getMaterial(self) -> CMaterial:
        return self.m_Material

    def test_MaterialProperties(self):
        # SCOPED_TRACE("Begin Test: Phi angles creation.")  # Debug aid, no-op in port
        aMaterial = self.getMaterial()

        T = aMaterial.getProperty(Property.T, Side.Front)

        # Test for solar range first
        self.assertAlmostEqual(0.1, T, delta=1e-6)

        R = aMaterial.getProperty(Property.R, Side.Front)

        self.assertAlmostEqual(0.7, R, delta=1e-6)

        # Properties at four wavelengths should have been created
        size = 5

        Transmittances = aMaterial.getBandProperties(Property.T, Side.Front)

        self.assertEqual(size, len(Transmittances))

        correctResults: List[float] = []
        correctResults.append(0)
        correctResults.append(0.0039215686274509838)
        correctResults.append(0.2)
        correctResults.append(0.0039215686274509838)
        correctResults.append(0.0039215686274509838)

        for i in range(size):
            self.assertAlmostEqual(correctResults[i], Transmittances[i], delta=1e-6)

        Reflectances = aMaterial.getBandProperties(Property.R, Side.Front)

        self.assertEqual(size, len(Reflectances))

        correctResults.clear()
        correctResults.append(0)
        correctResults.append(0.79607843137254897)
        correctResults.append(0.6)
        correctResults.append(0.79607843137254897)
        correctResults.append(0.79607843137254897)

        for i in range(size):
            self.assertAlmostEqual(correctResults[i], Reflectances[i], delta=1e-6)

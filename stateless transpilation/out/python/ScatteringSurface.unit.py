# EXTERNAL DEPS (to wire in glue):
# - SingleLayerOptics.CScatteringSurface
# - FenestrationCommon.ScatteringSimple

from typing import Protocol, dataclass
from math import isclose

class CScatteringSurface(Protocol):
    def getAbsorptance(self, scattering_type: int) -> float:
        ...

class ScatteringSimple:
    Direct = 0
    Diffuse = 1

class TestScatteringSurface:
    def __init__(self):
        self.m_Surface = None

    def setUp(self):
        T_dir_dir = 0.08
        R_dir_dir = 0.05

        T_dir_dif = 0.46
        R_dir_dif = 0.23

        T_dif_dif = 0.46
        R_dif_dif = 0.52

        self.m_Surface = CScatteringSurface(T_dir_dir, R_dir_dir, T_dir_dif, R_dir_dif, T_dif_dif, R_dif_dif)

    def getSurface(self) -> CScatteringSurface:
        return self.m_Surface

def test_scattering_surface1():
    test = TestScatteringSurface()
    test.setUp()

    surf = test.getSurface()

    A_dir = surf.getAbsorptance(ScatteringSimple.Direct)
    assert isclose(A_dir, 0.18, abs_tol=1e-6)

    A_dif = surf.getAbsorptance(ScatteringSimple.Diffuse)
    assert isclose(A_dif, 0.02, abs_tol=1e-6)

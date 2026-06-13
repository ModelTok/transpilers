from memory import Pointer, new
from ...WCESingleLayerOptics import CScatteringSurface
from ......Common.WCECommon import ScatteringSimple

struct TestScatteringSurface:
    var m_Surface: Pointer[CScatteringSurface]

    def __init__(inout self):
        self.SetUp()

    def SetUp(inout self):
        let T_dir_dir: Float64 = 0.08
        let R_dir_dir: Float64 = 0.05
        let T_dir_dif: Float64 = 0.46
        let R_dir_dif: Float64 = 0.23
        let T_dif_dif: Float64 = 0.46
        let R_dif_dif: Float64 = 0.52
        self.m_Surface = new CScatteringSurface(
            T_dir_dir, R_dir_dir, T_dir_dif, R_dir_dif, T_dif_dif, R_dif_dif)

    def getSurface(self) -> CScatteringSurface:
        # Note: returns by value to mimic C++ copy behavior
        return self.m_Surface[]

def ScatteringSurface1():
    # SCOPED_TRACE("Begin Test: Simple scattering surface.")
    var fixture = TestScatteringSurface()
    var surf = fixture.getSurface()
    var A_dir: Float64 = surf.getAbsorptance(ScatteringSimple.Direct)
    assert(abs(A_dir - 0.18) < 1e-6)
    var A_dif: Float64 = surf.getAbsorptance(ScatteringSimple.Diffuse)
    assert(abs(A_dif - 0.02) < 1e-6)
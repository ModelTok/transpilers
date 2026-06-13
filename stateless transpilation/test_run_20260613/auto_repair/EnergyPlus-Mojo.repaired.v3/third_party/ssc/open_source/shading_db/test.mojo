from lib_pv_shade_loss_mpp import ShadeDB8_mpp
from core import *

def main() -> Int:
    var shad_fracs = List[F64]()
    shad_fracs.append(50.0)
    shad_fracs.append(100.0)
    var gpoa: F64 = 140.826
    var dpoa: F64 = 79.842
    var pv_cell_temp: F64 = 9.6083
    var mods_per_str: F64 = 12.0
    var str_vmp_stc: F64 = 440.4
    var mppt_lo: F64 = 250.0
    var mppt_hi: F64 = 480.0
    var p_shade_db = ShadeDB8_mpp()
    p_shade_db.init()
    var dc_factor: F64 = 1.0 - p_shade_db.get_shade_loss(gpoa, dpoa, shad_fracs, True, pv_cell_temp, mods_per_str, str_vmp_stc, mppt_lo, mppt_hi)
    print("shading factor =", dc_factor)
    print("warning messages =", p_shade_db.get_warning())
    print("error messages =", p_shade_db.get_error())
    return 0
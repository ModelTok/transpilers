from testing import *
from 6par_solve import module6par

def test_SixParSolve_6par_solve_NewMonoSiModules():
    var datasheet_values = List[List[Float64]](
        List[Float64](31.8, 17.29, 38.1, 18.39, 0.007356, -0.09525, -0.34, 110, 43),
        List[Float64](31.7, 17.29, 38.1, 18.39, 0.0007356, -0.09525, -0.34, 110, 43),
        List[Float64](34.6, 17.34, 41.7, 18.42, 0.007368, -0.10425, -0.34, 120, 43),
        List[Float64](34.85, 17.22, 41.4, 18.5, 0.0074, -0.11178, -0.35, 120, 44)
    )
    var tech_id = module6par.monoSi
    for i in range(len(datasheet_values)):
        var mod = datasheet_values[i]
        var Vmp = mod[0]
        var Imp = mod[1]
        var Voc = mod[2]
        var Isc = mod[3]
        var alpha_isc = mod[4]
        var beta_voc = mod[5]
        var gamma_pmp = mod[6]
        var Nser = Int(mod[7])
        var Tref = mod[8]
        var m = module6par(tech_id, Vmp, Imp, Voc, Isc, beta_voc, alpha_isc, gamma_pmp, Nser, Tref + 273.15)
        var err = m.solve_with_sanity_and_heuristics[Float64](300, 1e-7)
        expect_gt(err, -1)

def test_SixParSolve_6par_solve_CIGSModules():
    var datasheet_values = List[List[Float64]](
        List[Float64](88.3, 1.7, 108.9, 1.83, 0.000183, -0.29403, -0.32, 96, 42)
    )
    var tech_id = module6par.CIGS
    for i in range(len(datasheet_values)):
        var mod = datasheet_values[i]
        var Vmp = mod[0]
        var Imp = mod[1]
        var Voc = mod[2]
        var Isc = mod[3]
        var alpha_isc = mod[4]
        var beta_voc = mod[5]
        var gamma_pmp = mod[6]
        var Nser = Int(mod[7])
        var Tref = mod[8]
        var m = module6par(tech_id, Vmp, Imp, Voc, Isc, beta_voc, alpha_isc, gamma_pmp, Nser, Tref + 273.15)
        var err = m.solve_with_sanity_and_heuristics[Float64](300, 1e-7)
        expect_gt(err, -1)
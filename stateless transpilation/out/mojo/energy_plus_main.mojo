import sys

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusPgm: EnergyPlus/api/EnergyPlusPgm.hh - function taking list of strings, returning int
# - compute_win32_argv: CLI/CLI11.hpp - function returning list of strings

fn main() -> Int:
    if sys.platform == "win32":
        return EnergyPlusPgm(compute_win32_argv())
    else:
        return EnergyPlusPgm(sys.argv)

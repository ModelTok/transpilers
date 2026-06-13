import sys

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusPgm: EnergyPlus/api/EnergyPlusPgm.hh - function taking list of strings, returning int
# - compute_win32_argv: CLI/CLI11.hpp - function returning list of strings

def main() -> int:
    if sys.platform == "win32":
        args = compute_win32_argv()
    else:
        args = sys.argv
    
    return EnergyPlusPgm(args)

if __name__ == "__main__":
    sys.exit(main())

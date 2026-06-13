from ...api.EnergyPlusPgm import EnergyPlusPgm
from CLI.detail import compute_win32_argv
from sys import platform, argv as sys_argv

def main() -> Int32:
    var args: List[String]
    if platform == "win32":
        args = compute_win32_argv()
    else:
        args = sys_argv()
    return EnergyPlusPgm(args)
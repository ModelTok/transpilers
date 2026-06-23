#!/usr/bin/env python3
"""Psychrometric dependency-boundary shims (issue #66).

The shim library (#66) satisfies the compiler for unported EnergyPlus symbols a
dependent function references, written once and reused everywhere. The Array1D /
Constant / libm shims already landed; the remaining item is the psychrometric
lookups — until now only a constant ``pvstar`` *stub* (`ep_prelude.mojo`) existed,
which is numerically wrong (returns a fixed 611.65 for any temperature).

This module provides the first **real** psychrometric shim:
``PsyPsatFnTemp`` — water saturation pressure as a function of dry-bulb temp —
ported faithfully from the EnergyPlus C++ oracle's ``PsyPsatFnTemp_raw``
(``src/EnergyPlus/Psychrometrics.cc``, non-IF97 branch). The cache/error
machinery around it is irrelevant to a shim, so only the numeric core is ported.

Two products, both pure-Python here:

1. :func:`psy_psat_fn_temp` — the reference implementation in Python, verified
   against well-known saturation-pressure values (≈611 Pa at 0 °C, ≈101325 Pa at
   100 °C) in the tests. This is the source of truth for the shim.
2. :func:`mojo_shim` / :func:`cpp_shim` — emit the Mojo and C++ shim *text* (same
   constants, same branch structure) to drop into ``ep_prelude.mojo`` /
   ``ep_oracle.h`` in place of the ``pvstar`` stub.

The Mojo↔C++ compile + numeric-match check (the final shim gate, like the
Array1D shim) needs the Mojo + g++ toolchain and is **deferred** to a box that
has it; the Python math is verified here and the emitted text mirrors it exactly.

EnergyPlus naming preserved (``PsyPsatFnTemp``) per the project convention.
"""
from __future__ import annotations

import math

# EnergyPlus constants (DataGlobalConstants.hh).
KELVIN = 273.15
TRIPLE_POINT_OF_WATER_TEMP_KELVIN = 273.16

# Saturation-pressure coefficients (Psychrometrics.cc, non-IF97 branch).
# 173.15 K .. triple point (sub-triple-point / over ice).
_C1, _C2, _C3, _C4, _C5, _C6, _C7 = (
    -5674.5359, 6.3925247, -0.9677843e-2, 0.62215701e-6,
    0.20747825e-8, -0.9484024e-12, 4.1635019,
)
# triple point .. 473.15 K (over liquid water).
_C8, _C9, _C10, _C11, _C12, _C13 = (
    -5800.2206, 1.3914993, -0.048640239, 0.41764768e-4,
    -0.14452093e-7, 6.5459673,
)


def psy_psat_fn_temp(t_dry_bulb_c: float) -> float:
    """Saturation pressure of water vapor [Pa] at dry-bulb temperature *t* [°C].

    Faithful port of EnergyPlus ``PsyPsatFnTemp_raw`` (non-IF97). Clamped
    branches outside [-100, 200] °C match the C++ constants exactly.
    """
    tkel = t_dry_bulb_c + KELVIN
    if tkel < 173.15:
        return 0.001405102123874164
    if tkel < TRIPLE_POINT_OF_WATER_TEMP_KELVIN:
        return math.exp(
            _C1 / tkel
            + _C2
            + tkel * (_C3 + tkel * (_C4 + tkel * (_C5 + _C6 * tkel)))
            + _C7 * math.log(tkel)
        )
    if tkel <= 473.15:
        return math.exp(
            _C8 / tkel
            + _C9
            + tkel * (_C10 + tkel * (_C11 + tkel * _C12))
            + _C13 * math.log(tkel)
        )
    return 1555073.745636215


# ---------------------------------------------------------------------------
# Shim text emission (Mojo + C++). Same constants, same branch order, so the
# two compile to identical numerics (verified in Python; compile-match deferred).
# ---------------------------------------------------------------------------

_COEFFS_DOC = "EnergyPlus Psychrometrics.cc PsyPsatFnTemp_raw (non-IF97)"


def mojo_shim() -> str:
    """Mojo source for the PsyPsatFnTemp shim (drop-in for ep_prelude.mojo)."""
    return f"""\
# {_COEFFS_DOC} — real shim, replaces the pvstar stub.
fn PsyPsatFnTemp(T: Float64) -> Float64:
    var tkel: Float64 = T + {KELVIN}
    if tkel < 173.15:
        return 0.001405102123874164
    if tkel < {TRIPLE_POINT_OF_WATER_TEMP_KELVIN}:
        return exp({_C1} / tkel + {_C2}
            + tkel * ({_C3} + tkel * ({_C4} + tkel * ({_C5} + {_C6} * tkel)))
            + {_C7} * log(tkel))
    if tkel <= 473.15:
        return exp({_C8} / tkel + {_C9}
            + tkel * ({_C10} + tkel * ({_C11} + tkel * {_C12}))
            + {_C13} * log(tkel))
    return 1555073.745636215
"""


def cpp_shim() -> str:
    """C++ source for the PsyPsatFnTemp shim (drop-in for ep_oracle.h)."""
    return f"""\
// {_COEFFS_DOC} — real shim, replaces the pvstar stub.
inline double PsyPsatFnTemp(double T) {{
    double tkel = T + {KELVIN};
    if (tkel < 173.15) return 0.001405102123874164;
    if (tkel < {TRIPLE_POINT_OF_WATER_TEMP_KELVIN})
        return std::exp({_C1} / tkel + {_C2}
            + tkel * ({_C3} + tkel * ({_C4} + tkel * ({_C5} + {_C6} * tkel)))
            + {_C7} * std::log(tkel));
    if (tkel <= 473.15)
        return std::exp({_C8} / tkel + {_C9}
            + tkel * ({_C10} + tkel * ({_C11} + tkel * {_C12}))
            + {_C13} * std::log(tkel));
    return 1555073.745636215;
}}
"""


if __name__ == "__main__":
    print("# Mojo shim\n" + mojo_shim())
    print("// C++ shim\n" + cpp_shim())
    for t in (-150, -10, 0, 25, 100, 250):
        print(f"PsyPsatFnTemp({t:>5} C) = {psy_psat_fn_temp(t):.6g} Pa")

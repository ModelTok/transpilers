"""Compute expected test values for EnergyPlus-sourced tasks."""
import math

# ── 031: ep_ordinal_day ───────────────────────────────────────────
def ep_ordinal_day(month: int, day: int, leap: int) -> int:
    end_day = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    if month == 1: return day
    if month == 2: return day + end_day[0]
    return day + end_day[month - 2] + leap

print("031 ep_ordinal_day:")
for args in [(1,15,0),(2,28,0),(3,1,0),(3,1,1),(12,31,0)]:
    print(f"  {args} -> {ep_ordinal_day(*args)}")

# ── 032: ep_safe_divide ───────────────────────────────────────────
def ep_safe_divide(a: float, b: float) -> float:
    SMALL = 1e-10
    if abs(b) >= SMALL:
        return a / b
    return a / math.copysign(SMALL, b)

print("\n032 ep_safe_divide:")
for args in [(10.0,2.0),(-6.0,3.0),(0.0,5.0),(7.5,0.25)]:
    print(f"  {args} -> {ep_safe_divide(*args)}")

# ── 033: ep_clamp ─────────────────────────────────────────────────
def ep_clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))

print("\n033 ep_clamp:")
for args in [(5.0,0.0,10.0),(-2.0,0.0,10.0),(15.0,0.0,10.0),(3.5,1.0,5.0)]:
    print(f"  {args} -> {ep_clamp(*args)}")

# ── 034: ep_int_in_range ──────────────────────────────────────────
def ep_int_in_range(value: int, lo: int, hi: int) -> bool:
    return lo <= value <= hi

print("\n034 ep_int_in_range:")
for args in [(5,0,10),(-1,0,10),(0,0,10),(11,0,10)]:
    print(f"  {args} -> {ep_int_in_range(*args)}")

# ── 035: ep_azimuth_diff ──────────────────────────────────────────
def ep_azimuth_diff(azm_a: float, azm_b: float) -> float:
    diff = azm_b - azm_a
    if diff > 180.0:
        diff = 360.0 - diff
    elif diff < -180.0:
        diff = 360.0 + diff
    return abs(diff)

print("\n035 ep_azimuth_diff:")
for args in [(10.0,20.0),(10.0,200.0),(350.0,10.0),(0.0,270.0)]:
    print(f"  {args} -> {ep_azimuth_diff(*args)}")

# ── 036: ep_to_upper ──────────────────────────────────────────────
def ep_to_upper(s: str) -> str:
    return s.upper()

print("\n036 ep_to_upper:")
for args in [("hello",),("HeLLo123",),("",),("world",)]:
    print(f"  {args} -> {ep_to_upper(*args)!r}")

# ── 037: ep_first_nonspace ────────────────────────────────────────
def ep_first_nonspace(s: str) -> int:
    for i, c in enumerate(s):
        if c != ' ':
            return i
    return -1

print("\n037 ep_first_nonspace:")
for args in [("  hello",),("world",),("   ",),("",)]:
    print(f"  {args} -> {ep_first_nonspace(*args)}")

# ── 038: ep_moist_enthalpy (PsyHFnTdbW) ──────────────────────────
def ep_moist_enthalpy(tdb: float, dw: float) -> float:
    w = max(dw, 1e-5)
    return round(1.00484e3 * tdb + w * (2.50094e6 + 1.85895e3 * tdb), 2)

print("\n038 ep_moist_enthalpy:")
for args in [(0.0,0.0),(20.0,0.01),(30.0,0.02),(25.0,0.008)]:
    print(f"  {args} -> {ep_moist_enthalpy(*args)}")

# ── 039: ep_heat_vaporization (PsyHfgAirFnWTdb) ──────────────────
def ep_heat_vaporization(temp: float) -> float:
    t = max(temp, 0.0)
    return (2500940.0 + 1858.95 * t) - (4180.0 * t)

print("\n039 ep_heat_vaporization:")
for args in [(0.0,),(20.0,),(100.0,),(-10.0,)]:
    print(f"  {args} -> {ep_heat_vaporization(*args)}")

# ── 040: ep_rho_air (PsyRhoAirFnPbTdbW) ─────────────────────────
KELVIN = 273.15
def ep_rho_air(pb: float, tdb: float, dw: float) -> float:
    w = max(dw, 1e-5)
    return round(pb / (287.0 * (tdb + KELVIN) * (1.0 + 1.6077687 * w)), 6)

print("\n040 ep_rho_air:")
for args in [(101325.0,25.0,0.01),(101325.0,0.0,0.0),(85000.0,15.0,0.005),(101325.0,20.0,0.0)]:
    print(f"  {args} -> {ep_rho_air(*args)}")

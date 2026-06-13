"""
Module: EPWPrecisionGlobals

Contains precision definitions for EnergyPlus, allowing for setting the default
precision to "double precision" using KIND-like parameters. Should it ever be
necessary to try a higher precision, it will be easy to switch for testing.

AUTHOR: Linda Lawrie
DATE WRITTEN: January 2008
"""

# INTEGER KIND parameters
i32 = 4  # 6 significant digits
i64 = 8  # 12 significant digits

# REAL KIND parameters
r32 = 4  # Single precision real kind
r64 = 8  # Double precision real kind

# Default precision
default_prec = r64

# REAL(r64) constant parameters
constant_zero = 0.0
constant_one = 1.0
constant_minusone = -1.0
constant_twenty = 20.0
constant_pointfive = 0.5
EXP_LowerLimit = -20.0
EXP_UpperLimit = 40.0

"""
EPWPrecisionGlobals - Module containing precision-related constants for EnergyPlus.

This module allows for setting the default precision to "double precision" using
F95 KIND and parameters. Should it ever be necessary to try a higher precision, it
will be easy to switch for testing.

Copyright 1996-2009 The Board of Trustees of the University of Illinois
and The Regents of the University of California through Ernest Orlando Lawrence
Berkeley National Laboratory. All rights reserved.
"""

# Precision kind parameters
i32 = 4
i64 = 8
r32 = 4
r64 = 8
default_prec = r64

# Floating-point constants (double precision)
constant_zero = 0.0
constant_one = 1.0
constant_minusone = -1.0
constant_twenty = 20.0
constant_pointfive = 0.5
EXP_LowerLimit = -20.0
EXP_UpperLimit = 40.0

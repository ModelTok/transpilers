"""
Module: EPWPrecisionGlobals

Contains precision definitions for EnergyPlus, allowing for setting the default
precision to "double precision" using KIND-like parameters. Should it ever be
necessary to try a higher precision, it will be easy to switch for testing.

AUTHOR: Linda Lawrie
DATE WRITTEN: January 2008
"""

# INTEGER KIND parameters
var i32: Int = 4
var i64: Int = 8

# REAL KIND parameters
var r32: Int = 4
var r64: Int = 8

# Default precision
var default_prec: Int = r64

# REAL(r64) constant parameters
var constant_zero: f64 = 0.0
var constant_one: f64 = 1.0
var constant_minusone: f64 = -1.0
var constant_twenty: f64 = 20.0
var constant_pointfive: f64 = 0.5
var EXP_LowerLimit: f64 = -20.0
var EXP_UpperLimit: f64 = 40.0

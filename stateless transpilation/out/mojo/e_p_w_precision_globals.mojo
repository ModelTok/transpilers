"""Module containing the routines dealing with the precision of data in EnergyPlus

MODULE INFORMATION:
  AUTHOR         Linda Lawrie
  DATE WRITTEN   January 2008
  MODIFIED       na
  RE-ENGINEERED  na

PURPOSE OF THIS MODULE:
This module allows for setting the default precision to "double precision" using
F95 KIND and parameters. Should it ever be necessary to try a higher precision, it
will be easy to switch for testing.

NOTICE

Copyright  1996-2009 The Board of Trustees of the University of Illinois
and The Regents of the University of California through Ernest Orlando Lawrence
Berkeley National Laboratory.  All rights reserved.

Portions of the EnergyPlus software package have been developed and copyrighted
by other individuals, companies and institutions.  These portions have been
incorporated into the EnergyPlus software package under license.  For a complete
list of contributors, see "Notice" located in EnergyPlus.f90.

NOTICE: The U.S. Government is granted for itself and others acting on its
behalf a paid-up, nonexclusive, irrevocable, worldwide license in this data to
reproduce, prepare derivative works, and perform publicly and display publicly.
Beginning five (5) years after permission to assert copyright is granted,
subject to two possible five year renewals, the U.S. Government is granted for
itself and others acting on its behalf a paid-up, non-exclusive, irrevocable
worldwide license in this data to reproduce, prepare derivative works,
distribute copies to the public, perform publicly and display publicly, and to
permit others to do so.

TRADEMARKS: EnergyPlus is a trademark of the US Department of Energy.
"""

# EXTERNAL DEPS (to wire in glue):
# (none)

# Module parameter definitions - KIND parameters for precision control
alias i32: Int = 4  # Selected_Int_Kind(6) - 32-bit integer kind
alias i64: Int = 8  # Selected_Int_Kind(12) - 64-bit integer kind
alias r32: Int = 4  # KIND(1.0) - single precision real kind
alias r64: Int = 8  # KIND(1.0D0) - double precision real kind
alias default_prec: Int = 8

# Constant values using r64 (double) precision
alias constant_zero: Float64 = 0.0
alias constant_one: Float64 = 1.0
alias constant_minusone: Float64 = -1.0
alias constant_twenty: Float64 = 20.0
alias constant_pointfive: Float64 = 0.5

# Exponential limits for safety in exponential calculations
alias EXP_LowerLimit: Float64 = -20.0  # In IVF=2.061153622438558E-009 - used 20 because it's already used in other parts of the code
alias EXP_UpperLimit: Float64 = 40.0   # In IVF=2.353852668370200E+017

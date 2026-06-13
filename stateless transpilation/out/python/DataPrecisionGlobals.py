# EXTERNAL DEPS (to wire in glue):
# (none - this module is self-contained)

# Module containing the routines dealing with the precision of data in EnergyPlus

# MODULE INFORMATION:
#       AUTHOR         Linda Lawrie
#       DATE WRITTEN   January 2008
#       MODIFIED       na
#       RE-ENGINEERED  na

# PURPOSE OF THIS MODULE:
# This module allows for setting the default precision to "double precision" using
# F95 KIND and parameters.  Should it ever be necessary to try a higher precision, it
# will be easy to switch for testing.

# KIND parameter definitions
i32 = 4                    # 6 digits - 32-bit integer
i64 = 8                    # 12 digits - 64-bit integer
r32 = 4                    # single precision real (32-bit)
r64 = 8                    # double precision real (64-bit)
default_prec = r64

# Double precision constant definitions
constant_zero = 0.0
constant_one = 1.0
constant_minusone = -1.0
constant_twenty = 20.0
constant_pointfive = 0.5
EXP_LowerLimit = -20.0     # In IVF=2.061153622438558E-009 - used 20
                           # because it's already used in other parts of the code
EXP_UpperLimit = 40.0      # In IVF=2.353852668370200E+017

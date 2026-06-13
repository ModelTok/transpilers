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
alias i32 = 4                    # 6 digits - 32-bit integer
alias i64 = 8                    # 12 digits - 64-bit integer
alias r32 = 4                    # single precision real (32-bit)
alias r64 = 8                    # double precision real (64-bit)
alias default_prec = r64

# Double precision constant definitions
alias constant_zero = 0.0
alias constant_one = 1.0
alias constant_minusone = -1.0
alias constant_twenty = 20.0
alias constant_pointfive = 0.5
alias EXP_LowerLimit = -20.0     # In IVF=2.061153622438558E-009 - used 20
                                 # because it's already used in other parts of the code
alias EXP_UpperLimit = 40.0      # In IVF=2.353852668370200E+017

# Module containing the routines dealing with the precision of data in EnergyPlus
# AUTHOR: Linda Lawrie
# DATE WRITTEN: January 2008

# KIND parameters for data type declarations
i32 = 4   # KIND for 32-bit integer (Selected_Int_Kind(6))
i64 = 8   # KIND for 64-bit integer (Selected_Int_Kind(12))
r32 = 4   # KIND for 32-bit real (KIND(1.0))
r64 = 8   # KIND for 64-bit double precision (KIND(1.0D0))
default_prec = r64  # Default precision is double

# Double precision constants
constant_zero = 0.0
constant_one = 1.0
constant_minusone = -1.0
constant_twenty = 20.0
constant_pointfive = 0.5
EXP_LowerLimit = -20.0
EXP_UpperLimit = 40.0

# Module containing the routines dealing with the precision of data in EnergyPlus
# AUTHOR: Linda Lawrie
# DATE WRITTEN: January 2008

# KIND parameters for data type declarations
alias i32: Int32 = 4   # KIND for 32-bit integer (Selected_Int_Kind(6))
alias i64: Int32 = 8   # KIND for 64-bit integer (Selected_Int_Kind(12))
alias r32: Int32 = 4   # KIND for 32-bit real (KIND(1.0))
alias r64: Int32 = 8   # KIND for 64-bit double precision (KIND(1.0D0))
alias default_prec: Int32 = r64  # Default precision is double

# Double precision constants
alias constant_zero: Float64 = 0.0
alias constant_one: Float64 = 1.0
alias constant_minusone: Float64 = -1.0
alias constant_twenty: Float64 = 20.0
alias constant_pointfive: Float64 = 0.5
alias EXP_LowerLimit: Float64 = -20.0
alias EXP_UpperLimit: Float64 = 40.0

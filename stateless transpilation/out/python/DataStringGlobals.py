"""
Data-only module: string variables and constants for EnergyPlus parsing.
Faithful port of Fortran MODULE DataStringGlobals.
"""

# Constants (MODULE PARAMETERS)
UpperCase: str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
LowerCase: str = 'abcdefghijklmnopqrstuvwxyz'
PathChar: str = '\\'
PathLimit: int = 255
CharComma: str = ','
CharTab: str = '\t'
CharSpace: str = ' '
ProgramName: str = 'GroundTempCalc - Basement'
VerString: str = 'GroundTempCalc - Basement, Version .5'
DefaultIDD: str = 'BasementGHT.idd'
DefaultIDF: str = 'BasementGHTin.idf'

# Module variables (mutable shared state)
ProgramPath: str = ' ' * 255
FullName: str = ' ' * 270
TotalSevereErrors: int = 0
TotalWarningErrors: int = 0
CurrentDateTime: str = ' ' * 40
Elapsed_Time: float = 0.0

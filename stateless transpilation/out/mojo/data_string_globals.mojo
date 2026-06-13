"""
Data-only module: string variables and constants for EnergyPlus parsing.
Faithful port of Fortran MODULE DataStringGlobals.
"""

struct DataStringGlobals:
    alias UPPER_CASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    alias LOWER_CASE = "abcdefghijklmnopqrstuvwxyz"
    alias PATH_CHAR = "\\"
    alias PATH_LIMIT = 255
    alias CHAR_COMMA = ","
    alias CHAR_TAB = "\t"
    alias CHAR_SPACE = " "
    alias PROGRAM_NAME = "GroundTempCalc - Basement"
    alias VER_STRING = "GroundTempCalc - Basement, Version .5"
    alias DEFAULT_IDD = "BasementGHT.idd"
    alias DEFAULT_IDF = "BasementGHTin.idf"
    
    var program_path: String
    var full_name: String
    var total_severe_errors: Int
    var total_warning_errors: Int
    var current_date_time: String
    var elapsed_time: Float64
    
    fn __init__(inout self):
        self.program_path = String(" ") * 255
        self.full_name = String(" ") * 270
        self.total_severe_errors = 0
        self.total_warning_errors = 0
        self.current_date_time = String(" ") * 40
        self.elapsed_time = 0.0

"""
Data-only module repository for string variables used in parsing EnergyPlus.

MODULE INFORMATION:
AUTHOR: Linda K. Lawrie
DATE WRITTEN: September 1997

PURPOSE OF THIS MODULE:
This data-only module is a repository for string variables used in parsing
"pieces" of EnergyPlus.

REFERENCES:
None.

OTHER NOTES:
None.
"""

# EXTERNAL DEPS (to wire in glue):
# None - this is a data-only module with no external dependencies.

# Constants
alias UPPER_CASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
alias LOWER_CASE = "abcdefghijklmnopqrstuvwxyz"
alias PATH_CHAR = "\\"
alias PATH_LIMIT = 255
alias PROGRAM_NAME = "GroundTempCalc - Slab"
alias VER_STRING = "GroundTempCalc - Slab, Version .75"
alias DEFAULT_IDD = "SlabGHT.idd"
alias DEFAULT_IDF = "GHTIn.idf"


struct DataStringGlobalsState:
    """Mutable state variables for the DataStringGlobals module."""
    
    var program_path: String = " "
    var full_name: String = " "
    var total_severe_errors: Int = 0
    var total_warning_errors: Int = 0
    var current_date_time: String = " "
    var elapsed_time: Float64 = 0.0

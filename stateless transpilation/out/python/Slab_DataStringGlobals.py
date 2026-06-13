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

from dataclasses import dataclass

# Constants
UPPER_CASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
LOWER_CASE = 'abcdefghijklmnopqrstuvwxyz'
PATH_CHAR = '\\'
PATH_LIMIT = 255
PROGRAM_NAME = 'GroundTempCalc - Slab'
VER_STRING = PROGRAM_NAME + ', Version .75'
DEFAULT_IDD = 'SlabGHT.idd'
DEFAULT_IDF = 'GHTIn.idf'


@dataclass
class DataStringGlobalsState:
    """Mutable state variables for the DataStringGlobals module."""
    
    program_path: str = ' '
    full_name: str = ' '
    total_severe_errors: int = 0
    total_warning_errors: int = 0
    current_date_time: str = ' '
    elapsed_time: float = 0.0

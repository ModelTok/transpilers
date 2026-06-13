"""
Data-only module for string variables used in parsing EnergyPlus.

Author: Linda K. Lawrie
Date Written: September 1997
"""

# EXTERNAL DEPS (to wire in glue):
# None

# Constants
UPPER_CASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
LOWER_CASE = 'abcdefghijklmnopqrstuvwxyz'
PATH_CHAR = '\\'
PATH_LIMIT = 255

# Module variables
PROGRAM_PATH = ''
FULL_NAME = ''
IDD_VER_STRING = ''
VER_STRING = 'VCompare, Version 2.0'
PROG_NAME = 'VCompare'
PROG_NAME_CONVERSION = 'VCompare'
CURRENT_DATE_TIME = ''
TOTAL_SEVERE_ERRORS = 0
TOTAL_WARNING_ERRORS = 0
TOTAL_ERRORS = 0
FATAL_ERROR = False
IDD_ERROR = False
INI_ERROR = False

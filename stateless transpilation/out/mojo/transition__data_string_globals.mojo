# Data-only module for string variables used in parsing EnergyPlus.
# Author: Linda K. Lawrie
# Date Written: September 1997

# EXTERNAL DEPS (to wire in glue):
# None

alias UPPER_CASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
alias LOWER_CASE = "abcdefghijklmnopqrstuvwxyz"
alias PATH_CHAR = "\\"
alias PATH_LIMIT = 255

var program_path: String = ""
var full_name: String = ""
var idd_ver_string: String = ""
var ver_string: String = "VCompare, Version 2.0"
var prog_name: String = "VCompare"
var prog_name_conversion: String = "VCompare"
var current_date_time: String = ""
var total_severe_errors: Int = 0
var total_warning_errors: Int = 0
var total_errors: Int = 0
var fatal_error: Bool = False
var idd_error: Bool = False
var ini_error: Bool = False

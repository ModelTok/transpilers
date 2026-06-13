# EXTERNAL DEPS (to wire in glue):
# - GetNewUnitNumber: get_new_unit_number() -> Int  [source: platformDepUtilityRoutines.f90]

import os

fn copy_file(in_filename: String, out_filename: String, inout errflag: Bool) -> None:
    var in_filename_trimmed = in_filename.strip()
    var out_filename_trimmed = out_filename.strip()
    
    if not os.path.exists(in_filename_trimmed):
        errflag = True
        return
    
    var inunit = open(in_filename_trimmed, "r")
    var outunit = open(out_filename_trimmed, "w")
    
    var ios: Int = 0
    var line_buffer: String = ""
    
    while ios == 0:
        line_buffer = inunit.readline()
        if not line_buffer:
            ios = 1
            break
        outunit.write(line_buffer.rstrip() + '\n')
    
    inunit.seek(0)
    outunit.seek(0)
    outunit.close()
    inunit.close()

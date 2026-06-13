# EXTERNAL DEPS (to wire in glue):
# - GetNewUnitNumber: get_new_unit_number() -> int  [source: platformDepUtilityRoutines.f90]

import os
from dataclasses import dataclass

@dataclass
class ErrorFlag:
    value: bool = False

def copy_file(in_filename: str, out_filename: str, errflag: ErrorFlag) -> None:
    in_filename_trimmed = in_filename.strip()
    out_filename_trimmed = out_filename.strip()
    
    if not os.path.exists(in_filename_trimmed):
        errflag.value = True
        return
    
    inunit = open(in_filename_trimmed, 'r')
    outunit = open(out_filename_trimmed, 'w')
    
    ios = 0
    while ios == 0:
        line = inunit.readline()
        if not line:
            ios = 1
            break
        outunit.write(line.rstrip() + '\n')
    
    inunit.seek(0)
    outunit.seek(0)
    outunit.close()
    inunit.close()

import sys
import os
from typing import List, Optional, Tuple
import time

# EXTERNAL DEPS (to wire in glue):
# None - this is a standalone utility

BLANK = ' '
CTAB = '\t'
MAXNAMELENGTH = 500
MONTHS = ('January  ', 'February ', 'March    ', 'April    ', 'May      ', 'June     ',
          'July     ', 'August   ', 'September', 'October  ', 'November ', 'December ')
MONLEN = tuple(len(m.rstrip()) for m in MONTHS)
CHARCOMMA = ','
CHARTAB = '\t'
CHARSPACE = ' '
INOUTFORMAT = '(A)'
DATEFORMAT = "(1x,i2.2,'/',i2.2,2x,i2.2,':',i2.2,':',i2.2)"

CURPERLEN = 12
CURDAYLEN = 7
CURMDHLEN = 17
CURNUMMAX_INIT = 10000
CURFNUMMAX_INIT = 10000
CURSNUMMAX_INIT = 10000
INCNUM = 1000
NUMALLOWED = 255

def process_number(string: str) -> float:
    valid_numerics = '0123456789.+-\t'
    if not string or string[0] not in valid_numerics:
        return -999.0
    try:
        return float(string)
    except ValueError:
        if string.strip() == '':
            return -999.0
        return -999.0

def make_upper_case(input_string: str) -> str:
    return input_string.upper()

def myindex(string: str, substring: str) -> int:
    pos = make_upper_case(string).find(make_upper_case(substring))
    return pos + 1 if pos >= 0 else 0

def display_string(string: str):
    print(string)

def format_date(month: int, day: int, hour: int, minute: int, second: float) -> str:
    return f"{month:02d}/{day:02d}  {hour:02d}:{minute:02d}:{second:05.2f}"

def main():
    print('ReadVarsESO program starting.')
    
    maxrptnum = -1
    rviunit = 20
    esounit = 21
    csvunit = 22
    auditunit = 25
    done = False
    ntrack = 0
    nignore = 0
    havehourly = False
    havetimestep = False
    reachedend = False
    ntofind = 0
    ntoignore = 0
    freqs = 0
    gotinputfilename = False
    gotoutputfilename = False
    fixheader = False
    getvarsfromeso = False
    errorshappened = False
    limited = True
    nodetails = True
    nomonday = True
    nomon = True
    useoutline = False
    
    curnummax = CURNUMMAX_INIT
    curfnummax = CURFNUMMAX_INIT
    cursnummax = CURSNUMMAX_INIT
    
    tracknum: List[int] = [0] * curnummax
    ignorenum: List[int] = []
    trackvar: List[str] = [BLANK] * curnummax
    trackfound: List[bool] = [False] * curnummax
    
    findvar: List[str] = [BLANK] * curfnummax
    findvarprocessed: List[int] = [0] * curfnummax
    findvarnumeric: List[bool] = [True] * curfnummax
    ignorefindvar: List[str] = []
    
    stovar: List[str] = [BLANK] * cursnummax
    stonum: List[int] = [0] * cursnummax
    stofound: List[bool] = [False] * cursnummax
    
    varfilename = ''
    inputfilename = ''
    outputfilename = ''
    sepvar = CHARCOMMA
    fileextension = BLANK
    
    time_start = time.time()
    
    commalimit = 3000 - 10
    
    cmdargs = len(sys.argv) - 1
    if cmdargs == 0:
        getvarsfromeso = True
    else:
        arg = 1
        if arg < len(sys.argv):
            varfilename = sys.argv[arg].strip()
            if varfilename == BLANK:
                getvarsfromeso = True
        
        argnum = arg + 1
        freqs = 0
        for arg in range(argnum, len(sys.argv)):
            linearg = sys.argv[arg]
            if len(linearg) > 0:
                if linearg[0] in ('t', 'T'):
                    freqs = 1
                if len(linearg) >= 2 and linearg[:2] in ('de', 'De', 'DE'):
                    freqs = 1
                if linearg[0] in ('h', 'H'):
                    freqs = 2
                if len(linearg) >= 2 and linearg[:2] in ('da', 'Da', 'DA'):
                    freqs = 3
                if linearg[0] in ('m', 'M'):
                    freqs = 4
                if linearg[0] in ('a', 'A', 'r', 'R'):
                    freqs = 5
                if linearg[0] in ('u', 'U'):
                    limited = False
                if linearg[0] in ('n', 'N'):
                    limited = False
                if linearg[0] in ('f', 'F'):
                    fixheader = True
    
    audit_file = open('readvars.audit', 'a')
    audit_file.write('ReadVarsESO\n')
    
    if not getvarsfromeso:
        if not os.path.exists(varfilename):
            audit_file.write(f'Requested Report Variable input file={varfilename}\n')
            audit_file.write('does not exist.  Check eplusout.err file for possible explanations.\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'Requested Report Variable input file={varfilename}')
            print('does not exist.  Check eplusout.err file for possible explanations.')
            print('ReadVarsESO program terminated.')
            return
        
        audit_file.write(f'processing:{varfilename}\n')
        rvi_file = open(varfilename, 'r')
        
        while not gotinputfilename:
            try:
                inputfilename = rvi_file.readline().rstrip('\n')
            except:
                audit_file.write(' reached end of rvi file while looking for input file name\n')
                inputfilename = 'eplusout.eso'
                outputfilename = 'eplusout.csv'
                getvarsfromeso = True
                gotoutputfilename = True
                sepvar = CHARCOMMA
                break
            
            inputfilename = inputfilename.lstrip()
            if inputfilename.startswith('!'):
                audit_file.write(f' ignoring comment line={inputfilename}\n')
                continue
            
            epos = inputfilename.find('!')
            if epos != -1 and epos != 0:
                audit_file.write(f'comment stripped on line:{inputfilename}\n')
                inputfilename = inputfilename[:epos]
            elif epos == 0:
                inputfilename = BLANK
            
            gotinputfilename = True
        
        if inputfilename == BLANK:
            inputfilename = 'eplusout.eso'
        
        if not os.path.exists(inputfilename):
            audit_file.write(f'Requested ESO file={inputfilename}\n')
            audit_file.write('does not exist.  ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'Requested ESO file={inputfilename}')
            print('does not exist.  ReadVarsESO program terminated.')
            print('ReadVarsESO program terminated.')
            return
        
        audit_file.write(f'input file:{inputfilename}\n')
        eso_file = open(inputfilename, 'r')
        
        while not gotoutputfilename:
            try:
                outputfilename = rvi_file.readline().rstrip('\n')
            except:
                outputfilename = 'eplusout.csv'
                break
            
            outputfilename = outputfilename.lstrip()
            if outputfilename.startswith('!'):
                audit_file.write(f' ignoring comment line={outputfilename}\n')
                continue
            
            epos = outputfilename.find('!')
            if epos != -1 and epos != 0:
                audit_file.write(f'comment stripped on line:{outputfilename}\n')
                outputfilename = outputfilename[:epos]
            elif epos == 0:
                outputfilename = BLANK
            
            gotoutputfilename = True
        
        if outputfilename == BLANK:
            outputfilename = 'eplusout.csv'
            sepvar = CHARCOMMA
        else:
            fileextension = make_upper_case(outputfilename[max(0, len(outputfilename)-3):])
            if fileextension == 'CSV':
                sepvar = CHARCOMMA
            elif fileextension == 'TAB':
                sepvar = CHARTAB
            elif fileextension == 'TXT':
                sepvar = CHARSPACE
            else:
                sepvar = CHARCOMMA
        
        try:
            csv_file = open(outputfilename, 'w')
        except:
            audit_file.write(f'output file={outputfilename}\n')
            audit_file.write('cannot be opened.  It may be open in another program.\n')
            audit_file.write('Please close it and try again.\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'output file={outputfilename}')
            print('cannot be opened.  It may be open in another program.')
            print('Please close it and try again.')
            print('ReadVarsESO program terminated.')
            return
        
        audit_file.write(f'output file:{outputfilename}\n')
        
        if not getvarsfromeso:
            try:
                line = rvi_file.readline().rstrip('\n')
            except:
                ios = 1
                line = BLANK
        else:
            ios = 1
        
        if ios != 0:
            getvarsfromeso = True
        else:
            line = line.lstrip()
            if line == BLANK or line == '0':
                getvarsfromeso = True
            else:
                pass
    else:
        inputfilename = 'eplusout.eso'
        if not os.path.exists(inputfilename):
            audit_file.write(f'Requested ESO file={inputfilename}\n')
            audit_file.write('does not exist.  ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'Requested ESO file={inputfilename}')
            print('does not exist.  ReadVarsESO program terminated.')
            return
        
        eso_file = open(inputfilename, 'r')
        outputfilename = 'eplusout.csv'
        sepvar = CHARCOMMA
        
        try:
            csv_file = open(outputfilename, 'w')
        except:
            audit_file.write(f'output file={outputfilename}\n')
            audit_file.write('cannot be opened.  It may be open in another program.\n')
            audit_file.write('Please close it and try again.\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'output file={outputfilename}')
            print('cannot be opened.  It may be open in another program.')
            print('Please close it and try again.')
            print('ReadVarsESO program terminated.')
            return
    
    if not getvarsfromeso:
        while not done:
            try:
                line = rvi_file.readline().rstrip('\n')
            except:
                break
            
            if not line:
                break
            
            p1 = line.find(CTAB)
            while p1 >= 0:
                line = line[:p1] + ' ' + line[p1+1:]
                p1 = line.find(CTAB)
            
            line = line.lstrip()
            epos = line.find('!')
            if epos != -1 and epos != 0:
                audit_file.write(f' stripping comment from line={line}\n')
                line = line[:epos]
            elif epos == 0:
                audit_file.write(f' ignoring comment line={line}\n')
                continue
            
            if ',' not in line:
                if line.startswith('~'):
                    ignorethisone = True
                    i = int(process_number(line[1:]))
                else:
                    ignorethisone = False
                    i = int(process_number(line))
            else:
                i = -999
            
            if line == BLANK:
                i = 0
            
            if i > 0:
                if not ignorethisone:
                    ntrack += 1
                    if ntrack > curnummax:
                        curnummax += INCNUM
                        tracknum.extend([0] * INCNUM)
                    
                    if ntrack > NUMALLOWED:
                        if limited:
                            ntrack = NUMALLOWED
                            print(f'too many variables requested, will go with first {NUMALLOWED}')
                            audit_file.write(f'too many variables requested, will go with first {NUMALLOWED}\n')
                            break
                    
                    tracknum[ntrack-1] = i
                else:
                    nignore += 1
                    ignorenum.append(i)
            else:
                if i < 0:
                    if line.startswith('~'):
                        ignorethisone = True
                        pos = line.find('[')
                        if pos != -1:
                            line = line[1:pos] + ' ' * (len(line) - pos + 1)
                        else:
                            line = line[1:]
                        ntoignore += 1
                        ignorefindvar.append(line.lstrip())
                    else:
                        ignorethisone = False
                    
                    if not ignorethisone:
                        ntofind += 1
                        if ntofind > curfnummax:
                            curfnummax += INCNUM
                            findvar.extend([BLANK] * INCNUM)
                            findvarprocessed.extend([0] * INCNUM)
                            findvarnumeric.extend([True] * INCNUM)
                        
                        pos = line.find('[')
                        if pos != -1:
                            tempvar = line[:pos]
                        else:
                            tempvar = line
                        
                        tempvar = tempvar.lstrip()
                        ii = tempvar.find(',')
                        if ii != -1:
                            findvar[ntofind-1] = tempvar[:ii] + tempvar[ii+1:].lstrip()
                            findvarnumeric[ntofind-1] = False
                        else:
                            findvar[ntofind-1] = tempvar
                            findvarnumeric[ntofind-1] = False
                else:
                    done = True
        
        if ntrack == 0 and ntofind == 0 and nignore == 0 and ntoignore == 0:
            print('You chose no variables')
            audit_file.write('You chose no variables\n')
            audit_file.close()
            csv_file.close()
            eso_file.close()
            return
        
        if ntrack == 0 and ntofind == 0:
            getvarsfromeso = True
    
    if getvarsfromeso:
        audit_file.write(f'getting all vars from:{inputfilename}\n')
    
    numtoskip = 7
    try:
        line = eso_file.readline().rstrip('\n')
    except:
        audit_file.write('EOF encountered during read of ESO header records\n')
        audit_file.write('probable EnergyPlus error condition -- check eplusout.err\n')
        audit_file.write('ReadVarsESO program terminated.\n')
        audit_file.close()
        print('EOF encountered during read of ESO header records')
        print('probable EnergyPlus error condition -- check eplusout.err')
        print('ReadVarsESO program terminated.')
        return
    
    if line.find('Program Version') == -1:
        numtoskip = 6
    
    for i in range(numtoskip):
        try:
            line = eso_file.readline().rstrip('\n')
        except:
            audit_file.write('EOF encountered during read of ESO header records\n')
            audit_file.write('probable EnergyPlus error condition -- check eplusout.err\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print('EOF encountered during read of ESO header records')
            print('probable EnergyPlus error condition -- check eplusout.err')
            print('ReadVarsESO program terminated.')
            return
    
    nstore = 0
    trackfound.extend([False] * (curnummax - len(trackfound)))
    trackvar.extend([BLANK] * (curnummax - len(trackvar)))
    
    pass_num = 1
    while pass_num <= 2:
        while line != 'End of Data Dictionary':
            i = line.find(',')
            if i == -1:
                break
            
            try:
                j = int(line[:i])
            except:
                break
            
            if j > maxrptnum:
                maxrptnum = j
            
            if freqs != 0:
                if freqs == 1 and '!TimeStep' not in line:
                    try:
                        line = eso_file.readline().rstrip('\n')
                    except:
                        audit_file.write('EOF encountered during read of ESO header records\n')
                        audit_file.close()
                        csv_file.close()
                        eso_file.close()
                        return
                    continue
                elif freqs == 2 and '!Hourly' not in line:
                    try:
                        line = eso_file.readline().rstrip('\n')
                    except:
                        audit_file.write('EOF encountered during read of ESO header records\n')
                        audit_file.close()
                        csv_file.close()
                        eso_file.close()
                        return
                    continue
                elif freqs == 3 and '!Daily' not in line:
                    try:
                        line = eso_file.readline().rstrip('\n')
                    except:
                        audit_file.write('EOF encountered during read of ESO header records\n')
                        audit_file.close()
                        csv_file.close()
                        eso_file.close()
                        return
                    continue
                elif freqs == 4 and '!Monthly' not in line:
                    try:
                        line = eso_file.readline().rstrip('\n')
                    except:
                        audit_file.write('EOF encountered during read of ESO header records\n')
                        audit_file.close()
                        csv_file.close()
                        eso_file.close()
                        return
                    continue
                elif freqs == 5 and '!RunPeriod' not in line:
                    try:
                        line = eso_file.readline().rstrip('\n')
                    except:
                        audit_file.write('EOF encountered during read of ESO header records\n')
                        audit_file.close()
                        csv_file.close()
                        eso_file.close()
                        return
                    continue
            
            if j in ignorenum:
                try:
                    line = eso_file.readline().rstrip('\n')
                except:
                    audit_file.write('EOF encountered during read of ESO header records\n')
                    audit_file.close()
                    csv_file.close()
                    eso_file.close()
                    return
                continue
            
            k = 0
            for ij in range(ntoignore):
                k = myindex(line, ignorefindvar[ij].strip())
                if k != 0:
                    break
            
            if k != 0:
                try:
                    line = eso_file.readline().rstrip('\n')
                except:
                    audit_file.write('EOF encountered during read of ESO header records\n')
                    audit_file.close()
                    csv_file.close()
                    eso_file.close()
                    return
                continue
            
            if not getvarsfromeso:
                if ntofind > 0:
                    vara_break = False
                    for ij in range(ntofind):
                        if pass_num == 2 and findvarprocessed[ij] > 0:
                            continue
                        k = myindex(line, findvar[ij].strip())
                        if k > 0:
                            if k - 1 < len(line) and line[k-2:k-1] != ',':
                                k = 0
                        
                        if k != 0:
                            kpos = line[k-1:].find('[')
                            if kpos >= 0:
                                kpos = k - 1 + kpos
                            else:
                                kpos = -1
                            
                            if pass_num == 1:
                                if kpos != -1:
                                    if make_upper_case(findvar[ij].strip()) != make_upper_case(line[k-1:k-1+kpos-1]):
                                        k = 0
                                else:
                                    kpos = line[k-1:].find('!')
                                    if kpos >= 0:
                                        kpos = k - 1 + kpos
                                        if make_upper_case(findvar[ij].strip()) != make_upper_case(line[k-1:k-1+kpos-1]):
                                            k = 0
                        
                        ik = 0
                        if k != 0:
                            if pass_num == 1:
                                findvarprocessed[ij] += 1
                            if j not in tracknum[:ntrack] and j not in stonum[:nstore]:
                                ik = 0
                                if pass_num == 2:
                                    findvarprocessed[ij] -= 1
                                nstore += 1
                                if nstore > cursnummax:
                                    cursnummax += INCNUM
                                    stonum.extend([0] * INCNUM)
                                    stofound.extend([False] * INCNUM)
                                    stovar.extend([BLANK] * INCNUM)
                                
                                if nstore > NUMALLOWED:
                                    if limited:
                                        nstore = NUMALLOWED
                                        print(f'too many variables requested, will go with first {NUMALLOWED+1}')
                                        audit_file.write(f'too many variables requested, will go with first {NUMALLOWED+1}\n')
                                        break
                                
                                stonum[nstore-1] = j
                                stofound[nstore-1] = True
                                i = i + 1
                                line = line[i:]
                                i = line.find(',')
                                i = i + 1
                                line = line[i:]
                                i = line.find('!')
                                if i != -1:
                                    stovar[nstore-1] = line[:i] + '('
                                    i = i + 1
                                    line = line[i:]
                                    i = line.find('[')
                                    if i != -1:
                                        stovar[nstore-1] = stovar[nstore-1] + line[:i-2]
                                        ii = line.find(']')
                                        if ii < len(line) - 1 and line[ii+1] == ',':
                                            stovar[nstore-1] = stovar[nstore-1] + line[ii+1:]
                                        stovar[nstore-1] = stovar[nstore-1] + ')'
                                    else:
                                        stovar[nstore-1] = stovar[nstore-1] + line + ')'
                                
                                i = stovar[nstore-1].find(',')
                                while i != -1:
                                    stovar[nstore-1] = stovar[nstore-1][:i] + ':' + stovar[nstore-1][i+1:]
                                    i = stovar[nstore-1].find(',')
                                vara_break = True
                                break
                        
                        if vara_break:
                            break
                
                if ik != 0 and pass_num == 2:
                    try:
                        line = eso_file.readline().rstrip('\n')
                    except:
                        audit_file.write('EOF encountered during read of ESO header records\n')
                        audit_file.close()
                        csv_file.close()
                        eso_file.close()
                        return
                    continue
                
                for ij in range(ntrack):
                    if j == tracknum[ij]:
                        trackfound[ij] = True
                        i = i + 1
                        line = line[i:]
                        i = line.find(',')
                        i = i + 1
                        line = line[i:]
                        i = line.find('!')
                        if i != -1:
                            trackvar[ij] = line[:i] + '('
                            i = i + 1
                            line = line[i:]
                            i = line.find('[')
                            if i != -1:
                                trackvar[ij] = trackvar[ij] + line[:i-2]
                                ii = line.find(']')
                                if ii < len(line) - 1 and line[ii+1] == ',':
                                    trackvar[ij] = trackvar[ij] + line[ii+1:]
                                trackvar[ij] = trackvar[ij] + ')'
                            else:
                                trackvar[ij] = trackvar[ij] + line + ')'
                        
                        i = trackvar[ij].find(',')
                        while i != -1:
                            trackvar[ij] = trackvar[ij][:i] + ':' + trackvar[ij][i+1:]
                            i = trackvar[ij].find(',')
            else:
                ntrack += 1
                if ntrack > curnummax:
                    curnummax += INCNUM
                    tracknum.extend([0] * INCNUM)
                    trackfound.extend([False] * INCNUM)
                    trackvar.extend([BLANK] * INCNUM)
                
                if ntrack > NUMALLOWED and limited:
                    print(f'too many variables requested, will go with first {NUMALLOWED}')
                    audit_file.write(f'too many variables requested, will go with first {NUMALLOWED}\n')
                    ntrack = NUMALLOWED
                    try:
                        line = eso_file.readline().rstrip('\n')
                    except:
                        audit_file.write('EOF encountered during read of ESO header records\n')
                        audit_file.close()
                        csv_file.close()
                        eso_file.close()
                        return
                    while line != 'End of Data Dictionary':
                        i = line.find(',')
                        try:
                            j = int(line[:i])
                        except:
                            break
                        if j > maxrptnum:
                            maxrptnum = j
                        try:
                            line = eso_file.readline().rstrip('\n')
                        except:
                            audit_file.write('EOF encountered during read of ESO header records\n')
                            audit_file.close()
                            csv_file.close()
                            eso_file.close()
                            return
                    break
                else:
                    tracknum[ntrack-1] = j
                    ij = ntrack - 1
                    trackfound[ij] = True
                    i = i + 1
                    line = line[i:]
                    i = line.find(',')
                    i = i + 1
                    line = line[i:]
                    i = line.find('!')
                    if i != -1:
                        trackvar[ij] = line[:i] + '('
                        i = i + 1
                        line = line[i:]
                        i = line.find('[')
                        if i != -1:
                            trackvar[ij] = trackvar[ij] + line[:i-2]
                            ii = line.find(']')
                            if ii < len(line) - 1 and line[ii+1] == ',':
                                trackvar[ij] = trackvar[ij] + line[ii+1:]
                            trackvar[ij] = trackvar[ij] + ')'
                        else:
                            trackvar[ij] = trackvar[ij] + line + ')'
                    
                    i = trackvar[ij].find(',')
                    while i != -1:
                        trackvar[ij] = trackvar[ij][:i] + ':' + trackvar[ij][i+1:]
                        i = trackvar[ij].find(',')
            
            try:
                line = eso_file.readline().rstrip('\n')
            except:
                audit_file.write('EOF encountered during read of ESO header records\n')
                audit_file.close()
                csv_file.close()
                eso_file.close()
                return
        
        if pass_num == 2:
            break
        if getvarsfromeso:
            break
        pass_num = 2
        eso_file.seek(0)
        numtoskip = 6
        try:
            line = eso_file.readline().rstrip('\n')
        except:
            audit_file.write('EOF encountered during read of ESO header records\n')
            audit_file.close()
            csv_file.close()
            eso_file.close()
            return
        
        if line.find('Program Version') == -1:
            numtoskip = 5
        
        for i in range(numtoskip):
            try:
                line = eso_file.readline().rstrip('\n')
            except:
                audit_file.write('EOF encountered during read of ESO header records\n')
                audit_file.close()
                csv_file.close()
                eso_file.close()
                return
    
    if ntofind > 0:
        for j in range(ntofind):
            if findvarnumeric[j]:
                continue
            if ',' not in findvar[j]:
                continue
            for ij in range(nstore):
                if stovar[ij] == BLANK:
                    continue
                if myindex(stovar[ij], findvar[j].strip()) == 0:
                    continue
                ntrack += 1
                if ntrack > curnummax:
                    curnummax += INCNUM
                    tracknum.extend([0] * INCNUM)
                    trackfound.extend([False] * INCNUM)
                    trackvar.extend([BLANK] * INCNUM)
                
                if ntrack > NUMALLOWED:
                    if limited:
                        print(f'too many variables requested, will go with first {NUMALLOWED}')
                        audit_file.write(f'too many variables requested, will go with first {NUMALLOWED}\n')
                        ntrack = NUMALLOWED
                        break
                
                tracknum[ntrack-1] = stonum[ij]
                trackvar[ntrack-1] = stovar[ij]
                trackfound[ntrack-1] = stofound[ij]
                stonum[ij] = 0
                stovar[ij] = BLANK
        
        for j in range(ntofind):
            if findvarnumeric[j]:
                continue
            i = findvar[j].find(',')
            if i > 0:
                findvar[j] = findvar[j][:i] + ':' + findvar[j][i+1:]
            for ij in range(nstore):
                if stovar[ij] == BLANK:
                    continue
                if myindex(stovar[ij], findvar[j].strip()) == 0:
                    continue
                ntrack += 1
                if ntrack > curnummax:
                    curnummax += INCNUM
                    tracknum.extend([0] * INCNUM)
                    trackfound.extend([False] * INCNUM)
                    trackvar.extend([BLANK] * INCNUM)
                
                if ntrack > NUMALLOWED:
                    if limited:
                        ntrack = NUMALLOWED
                        print(f'too many variables requested, will go with first {NUMALLOWED}')
                        audit_file.write(f'too many variables requested, will go with first {NUMALLOWED}\n')
                        break
                
                tracknum[ntrack-1] = stonum[ij]
                trackvar[ntrack-1] = stovar[ij]
                trackfound[ntrack-1] = stofound[ij]
                stonum[ij] = 0
                stovar[ij] = BLANK
    
    audit_file.write(f' number variables requested for output={ntrack}\n')
    
    if not limited:
        if ntrack > 3500:
            print('potentially too many variables requested.  program may crash.')
            print(f' number requested={ntrack}')
            print(' program has been tested through max=3500')
            audit_file.write('potentially too many variables requested.  program may crash.\n')
            audit_file.write(f' number requested={ntrack}\n')
            audit_file.write(' program has been tested through max=3500\n')
    
    outdata = [BLANK] * ntrack
    outfound = [False] * ntrack
    
    outlinepart = 'Date/Time'
    csv_file.write(outlinepart)
    for ij in range(ntrack):
        if trackfound[ij]:
            outlinepart = sepvar + trackvar[ij].strip()
            csv_file.write(outlinepart)
        else:
            print(f'line 904 variable ={tracknum[ij]} not found')
            audit_file.write(f'line 904 variable ={tracknum[ij]} not found\n')
    
    if fixheader:
        csv_file.write('\n')
    else:
        csv_file.write(' \n')
    
    try:
        line = eso_file.readline().rstrip('\n')
    except:
        audit_file.write('EOF encountered on eplusout.eso while reading data\n')
        audit_file.close()
        csv_file.close()
        eso_file.close()
        return
    
    curdate = BLANK
    curmonday = BLANK
    curmon = BLANK
    curper = BLANK
    
    trackindex = [0] * (maxrptnum + 1)
    for j in range(ntrack):
        trackindex[tracknum[j]] = j + 1
    
    outline = BLANK
    
    while True:
        try:
            line = eso_file.readline().rstrip('\n')
        except:
            audit_file.write('EOF encountered on eplusout.eso while reading data\n')
            audit_file.write('probable EnergyPlus error condition -- check eplusout.err\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            csv_file.close()
            eso_file.close()
            return
        
        if not line:
            audit_file.write('EOF encountered on eplusout.eso while reading data\n')
            audit_file.write('probable EnergyPlus error condition -- check eplusout.err\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            csv_file.close()
            eso_file.close()
            return
        
        if line == 'End of Data':
            useoutline = False
            if not nodetails:
                outline = curdate
            elif not nomonday:
                outline = curmonday
            elif not nomon:
                outline = curmon
            else:
                outline = curper
            
            anytoprint = False
            commacount = 0
            for j in range(ntrack):
                if outfound[j]:
                    if not anytoprint:
                        csv_file.write(outline)
                        outline = BLANK
                        commacount = 0
                    if useoutline:
                        csv_file.write(outline)
                        useoutline = False
                        outline = BLANK
                        commacount = 0
                    csv_file.write(sepvar + outdata[j].strip())
                    anytoprint = True
                else:
                    outline = outline + sepvar
                    useoutline = True
                    commacount += 1
                    if commacount > commalimit:
                        csv_file.write(outline)
                        outline = BLANK
                        useoutline = False
                        commacount = 0
            
            if anytoprint:
                csv_file.write(' \n')
                outline = BLANK
            
            break
        
        if line == BLANK:
            audit_file.write('Output file=' + outputfilename + '\n')
            audit_file.write('error occurred during processing.\n')
            audit_file.write('Blank line in middle of processing.\n')
            audit_file.write('Likely fatal error during EnergyPlus execution.\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print('Output file=' + outputfilename)
            print('error occurred during processing.')
            print('Blank line in middle of processing.')
            print('Likely fatal error during EnergyPlus execution.')
            print('ReadVarsESO program terminated.')
            csv_file.close()
            eso_file.close()
            return
        
        i = line.find(',')
        if i == -1:
            audit_file.write('Output file=' + outputfilename + '\n')
            audit_file.write('error occurred during processing.\n')
            audit_file.write(f'Apparent line in error (1st 50 characters):\n')
            audit_file.write(line[:50] + '\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print('Output file=' + outputfilename)
            print('error occurred during processing.')
            print(f'Apparent line in error (1st 50 characters):')
            print(line[:50])
            print('ReadVarsESO program terminated.')
            csv_file.close()
            eso_file.close()
            return
        
        try:
            lineno = int(line[:i])
        except:
            audit_file.write('Output file=' + outputfilename + '\n')
            audit_file.write('error occurred during processing.\n')
            audit_file.write(f'Apparent line in error (1st 50 characters):\n')
            audit_file.write(line[:50] + '\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print('Output file=' + outputfilename)
            print('error occurred during processing.')
            print(f'Apparent line in error (1st 50 characters):')
            print(line[:50])
            print('ReadVarsESO program terminated.')
            csv_file.close()
            eso_file.close()
            return
        
        if lineno == 1:
            pass
        elif lineno == 2:
            nodetails = False
            try:
                parts = line.split(',')
                iform = int(parts[0])
                dayofsim = int(parts[1])
                nmonth = int(parts[2])
                nday = int(parts[3])
                dstind = int(parts[4])
                nhourofday = int(parts[5])
                nsminute = float(parts[6])
                neminute = float(parts[7])
            except:
                audit_file.write('Output file=' + outputfilename + '\n')
                audit_file.write('error occurred during processing.\n')
                audit_file.write(f'Apparent line in error (1st 50 characters):\n')
                audit_file.write(line[:50] + '\n')
                audit_file.write('ReadVarsESO program terminated.\n')
                audit_file.close()
                print('Output file=' + outputfilename)
                print('error occurred during processing.')
                print(f'Apparent line in error (1st 50 characters):')
                print(line[:50])
                print('ReadVarsESO program terminated.')
                csv_file.close()
                eso_file.close()
                return
            
            commacount = 0
            if curdate != BLANK:
                if nhourofday != hourofday or neminute != eminute:
                    outline = curdate
                    anytoprint = False
                    useoutline = False
                    for j in range(ntrack):
                        if outfound[j]:
                            if not anytoprint:
                                csv_file.write(outline)
                                outline = BLANK
                                commacount = 0
                            if useoutline:
                                csv_file.write(outline)
                                useoutline = False
                                outline = BLANK
                                commacount = 0
                            csv_file.write(sepvar + outdata[j].strip())
                            anytoprint = True
                        else:
                            outline = outline + sepvar
                            useoutline = True
                            commacount += 1
                            if commacount > commalimit:
                                csv_file.write(outline)
                                outline = BLANK
                                useoutline = False
                                commacount = 0
                    
                    if anytoprint:
                        csv_file.write(' \n')
                        outline = BLANK
                    
                    outfound = [False] * ntrack
            
            eminute = neminute
            sminute = nsminute
            day = nday
            month = nmonth
            hourofday = nhourofday
            curhr = hourofday - 1
            curmin = int(eminute)
            cursec = (eminute - curmin) * 60.0
            if eminute == 60.0:
                curhr = hourofday
                curmin = 0
                curdate = format_date(month, day, curhr, curmin, int(cursec))
                if sminute == 0.0:
                    curdate = format_date(month, day, curhr, curmin, int(cursec))
            else:
                curdate = format_date(month, day, curhr, curmin, cursec)
        
        elif lineno == 3:
            if nodetails:
                nomonday = False
                try:
                    parts = line.split(',')
                    iform = int(parts[0])
                    dayofsim = int(parts[1])
                    nmonth = int(parts[2])
                    nday = int(parts[3])
                    dstind = int(parts[4])
                except:
                    audit_file.write('Output file=' + outputfilename + '\n')
                    audit_file.write('error occurred during processing.\n')
                    audit_file.write(f'Apparent line in error (1st 50 characters):\n')
                    audit_file.write(line[:50] + '\n')
                    audit_file.write('ReadVarsESO program terminated.\n')
                    audit_file.close()
                    print('Output file=' + outputfilename)
                    print('error occurred during processing.')
                    print(f'Apparent line in error (1st 50 characters):')
                    print(line[:50])
                    print('ReadVarsESO program terminated.')
                    csv_file.close()
                    eso_file.close()
                    return
                
                commacount = 0
                if curmonday != BLANK:
                    outline = curmonday
                    anytoprint = False
                    useoutline = False
                    for j in range(ntrack):
                        if outfound[j]:
                            if not anytoprint:
                                csv_file.write(outline)
                                outline = BLANK
                                commacount = 0
                            if useoutline:
                                csv_file.write(outline)
                                useoutline = False
                                outline = BLANK
                                commacount = 0
                            csv_file.write(sepvar + outdata[j].strip())
                            anytoprint = True
                        else:
                            outline = outline + sepvar
                            useoutline = True
                            commacount += 1
                            if commacount > commalimit:
                                csv_file.write(outline)
                                outline = BLANK
                                useoutline = False
                                commacount = 0
                    
                    if anytoprint:
                        csv_file.write(' \n')
                        outline = BLANK
                    
                    outfound = [False] * ntrack
                
                day = nday
                month = nmonth
                curmonday = format_date(month, day, 0, 0, 0)[:5]
        
        elif lineno == 4:
            if nodetails and nomonday:
                nomon = False
                try:
                    parts = line.split(',')
                    iform = int(parts[0])
                    dayofsim = int(parts[1])
                    nmonth = int(parts[2])
                except:
                    audit_file.write('Output file=' + outputfilename + '\n')
                    audit_file.write('error occurred during processing.\n')
                    audit_file.write(f'Apparent line in error (1st 50 characters):\n')
                    audit_file.write(line[:50] + '\n')
                    audit_file.write('ReadVarsESO program terminated.\n')
                    audit_file.close()
                    print('Output file=' + outputfilename)
                    print('error occurred during processing.')
                    print(f'Apparent line in error (1st 50 characters):')
                    print(line[:50])
                    print('ReadVarsESO program terminated.')
                    csv_file.close()
                    eso_file.close()
                    return
                
                commacount = 0
                if curmon != BLANK:
                    outline = curmon
                    anytoprint = False
                    useoutline = False
                    for j in range(ntrack):
                        if outfound[j]:
                            if not anytoprint:
                                csv_file.write(outline)
                                outline = BLANK
                                commacount = 0
                            if useoutline:
                                csv_file.write(outline)
                                useoutline = False
                                outline = BLANK
                                commacount = 0
                            csv_file.write(sepvar + outdata[j].strip())
                            anytoprint = True
                        else:
                            outline = outline + sepvar
                            useoutline = True
                            commacount += 1
                            if commacount > commalimit:
                                csv_file.write(outline)
                                outline = BLANK
                                useoutline = False
                                commacount = 0
                    
                    if anytoprint:
                        csv_file.write(' \n')
                        outline = BLANK
                    
                    outfound = [False] * ntrack
                
                month = nmonth
                curmon = MONTHS[month - 1]
        
        elif lineno == 5:
            if nodetails and nomonday and nomon:
                try:
                    parts = line.split(',')
                    iform = int(parts[0])
                    dayofsim = int(parts[1])
                except:
                    audit_file.write('Output file=' + outputfilename + '\n')
                    audit_file.write('error occurred during processing.\n')
                    audit_file.write(f'Apparent line in error (1st 50 characters):\n')
                    audit_file.write(line[:50] + '\n')
                    audit_file.write('ReadVarsESO program terminated.\n')
                    audit_file.close()
                    print('Output file=' + outputfilename)
                    print('error occurred during processing.')
                    print(f'Apparent line in error (1st 50 characters):')
                    print(line[:50])
                    print('ReadVarsESO program terminated.')
                    csv_file.close()
                    eso_file.close()
                    return
                
                commacount = 0
                if curper != BLANK:
                    outline = curper
                    anytoprint = False
                    useoutline = False
                    for j in range(ntrack):
                        if outfound[j]:
                            if not anytoprint:
                                csv_file.write(outline)
                                outline = BLANK
                                commacount = 0
                            if useoutline:
                                csv_file.write(outline)
                                useoutline = False
                                outline = BLANK
                                commacount = 0
                            csv_file.write(sepvar + outdata[j].strip())
                            anytoprint = True
                        else:
                            outline = outline + sepvar
                            useoutline = True
                            commacount += 1
                            if commacount > commalimit:
                                csv_file.write(outline)
                                outline = BLANK
                                useoutline = False
                                commacount = 0
                    
                    if anytoprint:
                        csv_file.write(' \n')
                        outline = BLANK
                    
                    outfound = [False] * ntrack
                
                cdayofsim = str(dayofsim).lstrip()
                curper = f'simdays={cdayofsim}'
        
        else:
            if lineno < len(trackindex):
                j = trackindex[lineno]
                if j != 0:
                    j = j - 1
                    i = i + 1
                    line = line[i:]
                    i = line.find(',')
                    if i == -1:
                        outdata[j] = line
                    else:
                        outdata[j] = line[:i]
                    
                    outfound[j] = True
    
    csv_file.close()
    eso_file.close()
    
    time_finish = time.time()
    elapsed_time = time_finish - time_start
    
    for ij in range(ntoignore):
        if ij == 0:
            audit_file.write('ignoring:\n')
        audit_file.write(ignorefindvar[ij] + '\n')
    
    for ij in range(ntofind):
        if ij == 0:
            audit_file.write('found/finding:\n')
        if findvarprocessed[ij] >= 0:
            audit_file.write(f'{findvarprocessed[ij]:6d} {findvar[ij]}\n')
        else:
            audit_file.write(f'{abs(findvarprocessed[ij]):6d} {findvar[ij]}*\n')
    
    hours = int(elapsed_time // 3600)
    elapsed_time = elapsed_time - hours * 3600
    minutes = int(elapsed_time // 60)
    elapsed_time = elapsed_time - minutes * 60
    seconds = elapsed_time
    
    elapsed_str = f'{hours:02d}hr {minutes:02d}min {seconds:05.2f}sec'
    display_string(f'ReadVars Run Time={elapsed_str}')
    audit_file.write(f'ReadVars Run Time={elapsed_str}\n')
    
    if not errorshappened:
        print('ReadVarsESO program completed successfully.')
        audit_file.write('ReadVarsESO program completed successfully.\n')
    
    audit_file.close()

if __name__ == '__main__':
    main()

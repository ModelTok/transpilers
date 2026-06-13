import sys
from collections import InlineArray
from math import floor
import time

# EXTERNAL DEPS (to wire in glue):
# None - this is a standalone utility

alias BLANK = ' '
alias CTAB = '\t'
alias MAXNAMELENGTH = 500
alias CHARCOMMA = ','
alias CHARTAB = '\t'
alias CHARSPACE = ' '
alias INOUTFORMAT = '(A)'
alias DATEFORMAT = "(1x,i2.2,'/',i2.2,2x,i2.2,':',i2.2,':',i2.2)"

alias CURPERLEN = 12
alias CURDAYLEN = 7
alias CURMDHLEN = 17
alias CURNUMMAX_INIT = 10000
alias CURFNUMMAX_INIT = 10000
alias CURSNUMMAX_INIT = 10000
alias INCNUM = 1000
alias NUMALLOWED = 255

fn get_months() -> List[StringLiteral]:
    return List[StringLiteral]('January  ', 'February ', 'March    ', 'April    ', 'May      ', 'June     ',
                               'July     ', 'August   ', 'September', 'October  ', 'November ', 'December ')

fn get_monlen() -> List[Int]:
    var months = get_months()
    var result = List[Int]()
    for month in months:
        result.append(len(month.rstrip()))
    return result

fn process_number(string: String) -> Float32:
    let valid_numerics = '0123456789.+-\t'
    if not string or string[0] not in valid_numerics:
        return -999.0
    try:
        return float(string)
    except:
        if string.strip() == '':
            return -999.0
        return -999.0

fn make_upper_case(input_string: String) -> String:
    return input_string.upper()

fn myindex(string: String, substring: String) -> Int:
    let pos = make_upper_case(string).find(make_upper_case(substring))
    return pos + 1 if pos >= 0 else 0

fn display_string(string: String):
    print(string)

fn format_date(month: Int, day: Int, hour: Int, minute: Int, second: Float32) -> String:
    return f"{month:02d}/{day:02d}  {hour:02d}:{minute:02d}:{second:05.2f}"

struct ReadVarsESOState:
    var maxrptnum: Int
    var rviunit: Int
    var esounit: Int
    var csvunit: Int
    var auditunit: Int
    var done: Bool
    var ntrack: Int
    var nignore: Int
    var havehourly: Bool
    var havetimestep: Bool
    var reachedend: Bool
    var ntofind: Int
    var ntoignore: Int
    var freqs: Int
    var gotinputfilename: Bool
    var gotoutputfilename: Bool
    var fixheader: Bool
    var getvarsfromeso: Bool
    var errorshappened: Bool
    var limited: Bool
    var nodetails: Bool
    var nomonday: Bool
    var nomon: Bool
    var useoutline: Bool
    
    var curnummax: Int
    var curfnummax: Int
    var cursnummax: Int
    
    var tracknum: List[Int]
    var ignorenum: List[Int]
    var trackvar: List[String]
    var trackfound: List[Bool]
    
    var findvar: List[String]
    var findvarprocessed: List[Int]
    var findvarnumeric: List[Bool]
    var ignorefindvar: List[String]
    
    var stovar: List[String]
    var stonum: List[Int]
    var stofound: List[Bool]
    
    var varfilename: String
    var inputfilename: String
    var outputfilename: String
    var sepvar: String
    var fileextension: String

fn main():
    print('ReadVarsESO program starting.')
    
    var state = ReadVarsESOState()
    state.maxrptnum = -1
    state.rviunit = 20
    state.esounit = 21
    state.csvunit = 22
    state.auditunit = 25
    state.done = False
    state.ntrack = 0
    state.nignore = 0
    state.havehourly = False
    state.havetimestep = False
    state.reachedend = False
    state.ntofind = 0
    state.ntoignore = 0
    state.freqs = 0
    state.gotinputfilename = False
    state.gotoutputfilename = False
    state.fixheader = False
    state.getvarsfromeso = False
    state.errorshappened = False
    state.limited = True
    state.nodetails = True
    state.nomonday = True
    state.nomon = True
    state.useoutline = False
    
    state.curnummax = CURNUMMAX_INIT
    state.curfnummax = CURFNUMMAX_INIT
    state.cursnummax = CURSNUMMAX_INIT
    
    state.tracknum = List[Int](state.curnummax)
    for i in range(state.curnummax):
        state.tracknum[i] = 0
    
    state.ignorenum = List[Int]()
    state.trackvar = List[String](state.curnummax)
    for i in range(state.curnummax):
        state.trackvar[i] = BLANK
    
    state.trackfound = List[Bool](state.curnummax)
    for i in range(state.curnummax):
        state.trackfound[i] = False
    
    state.findvar = List[String](state.curfnummax)
    for i in range(state.curfnummax):
        state.findvar[i] = BLANK
    
    state.findvarprocessed = List[Int](state.curfnummax)
    for i in range(state.curfnummax):
        state.findvarprocessed[i] = 0
    
    state.findvarnumeric = List[Bool](state.curfnummax)
    for i in range(state.curfnummax):
        state.findvarnumeric[i] = True
    
    state.ignorefindvar = List[String]()
    
    state.stovar = List[String](state.cursnummax)
    for i in range(state.cursnummax):
        state.stovar[i] = BLANK
    
    state.stonum = List[Int](state.cursnummax)
    for i in range(state.cursnummax):
        state.stonum[i] = 0
    
    state.stofound = List[Bool](state.cursnummax)
    for i in range(state.cursnummax):
        state.stofound[i] = False
    
    state.varfilename = ''
    state.inputfilename = ''
    state.outputfilename = ''
    state.sepvar = CHARCOMMA
    state.fileextension = BLANK
    
    let time_start = time.time()
    
    let commalimit = 3000 - 10
    
    let cmdargs = len(sys.argv) - 1
    if cmdargs == 0:
        state.getvarsfromeso = True
    else:
        var arg = 1
        if arg < len(sys.argv):
            state.varfilename = sys.argv[arg].lstrip()
            if state.varfilename == BLANK:
                state.getvarsfromeso = True
        
        let argnum = arg + 1
        state.freqs = 0
        for arg in range(argnum, len(sys.argv)):
            let linearg = sys.argv[arg]
            if len(linearg) > 0:
                if linearg[0] in ('t', 'T'):
                    state.freqs = 1
                if len(linearg) >= 2 and linearg[0:2] in ('de', 'De', 'DE'):
                    state.freqs = 1
                if linearg[0] in ('h', 'H'):
                    state.freqs = 2
                if len(linearg) >= 2 and linearg[0:2] in ('da', 'Da', 'DA'):
                    state.freqs = 3
                if linearg[0] in ('m', 'M'):
                    state.freqs = 4
                if linearg[0] in ('a', 'A', 'r', 'R'):
                    state.freqs = 5
                if linearg[0] in ('u', 'U'):
                    state.limited = False
                if linearg[0] in ('n', 'N'):
                    state.limited = False
                if linearg[0] in ('f', 'F'):
                    state.fixheader = True
    
    var audit_file: FileHandle
    try:
        audit_file = open('readvars.audit', 'a')
        audit_file.write('ReadVarsESO\n')
    except:
        print('Error opening audit file')
        return
    
    var csv_file: FileHandle
    var eso_file: FileHandle
    var rvi_file: FileHandle
    
    if not state.getvarsfromeso:
        try:
            rvi_file = open(state.varfilename, 'r')
        except:
            audit_file.write(f'Requested Report Variable input file={state.varfilename}\n')
            audit_file.write('does not exist.  Check eplusout.err file for possible explanations.\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'Requested Report Variable input file={state.varfilename}')
            print('does not exist.  Check eplusout.err file for possible explanations.')
            print('ReadVarsESO program terminated.')
            return
        
        audit_file.write(f'processing:{state.varfilename}\n')
        
        while not state.gotinputfilename:
            try:
                state.inputfilename = rvi_file.readline().rstrip('\n')
            except:
                audit_file.write(' reached end of rvi file while looking for input file name\n')
                state.inputfilename = 'eplusout.eso'
                state.outputfilename = 'eplusout.csv'
                state.getvarsfromeso = True
                state.gotoutputfilename = True
                state.sepvar = CHARCOMMA
                break
            
            state.inputfilename = state.inputfilename.lstrip()
            if state.inputfilename.startswith('!'):
                audit_file.write(f' ignoring comment line={state.inputfilename}\n')
                continue
            
            let epos = state.inputfilename.find('!')
            if epos != -1 and epos != 0:
                audit_file.write(f'comment stripped on line:{state.inputfilename}\n')
                state.inputfilename = state.inputfilename[0:epos]
            elif epos == 0:
                state.inputfilename = BLANK
            
            state.gotinputfilename = True
        
        if state.inputfilename == BLANK:
            state.inputfilename = 'eplusout.eso'
        
        try:
            eso_file = open(state.inputfilename, 'r')
        except:
            audit_file.write(f'Requested ESO file={state.inputfilename}\n')
            audit_file.write('does not exist.  ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'Requested ESO file={state.inputfilename}')
            print('does not exist.  ReadVarsESO program terminated.')
            return
        
        audit_file.write(f'input file:{state.inputfilename}\n')
        
        while not state.gotoutputfilename:
            try:
                state.outputfilename = rvi_file.readline().rstrip('\n')
            except:
                state.outputfilename = 'eplusout.csv'
                break
            
            state.outputfilename = state.outputfilename.lstrip()
            if state.outputfilename.startswith('!'):
                audit_file.write(f' ignoring comment line={state.outputfilename}\n')
                continue
            
            let epos = state.outputfilename.find('!')
            if epos != -1 and epos != 0:
                audit_file.write(f'comment stripped on line:{state.outputfilename}\n')
                state.outputfilename = state.outputfilename[0:epos]
            elif epos == 0:
                state.outputfilename = BLANK
            
            state.gotoutputfilename = True
        
        if state.outputfilename == BLANK:
            state.outputfilename = 'eplusout.csv'
            state.sepvar = CHARCOMMA
        else:
            state.fileextension = make_upper_case(state.outputfilename[max(0, len(state.outputfilename)-3):])
            if state.fileextension == 'CSV':
                state.sepvar = CHARCOMMA
            elif state.fileextension == 'TAB':
                state.sepvar = CHARTAB
            elif state.fileextension == 'TXT':
                state.sepvar = CHARSPACE
            else:
                state.sepvar = CHARCOMMA
        
        try:
            csv_file = open(state.outputfilename, 'w')
        except:
            audit_file.write(f'output file={state.outputfilename}\n')
            audit_file.write('cannot be opened.  It may be open in another program.\n')
            audit_file.write('Please close it and try again.\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'output file={state.outputfilename}')
            print('cannot be opened.  It may be open in another program.')
            print('Please close it and try again.')
            print('ReadVarsESO program terminated.')
            return
        
        audit_file.write(f'output file:{state.outputfilename}\n')
    else:
        state.inputfilename = 'eplusout.eso'
        try:
            eso_file = open(state.inputfilename, 'r')
        except:
            audit_file.write(f'Requested ESO file={state.inputfilename}\n')
            audit_file.write('does not exist.  ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'Requested ESO file={state.inputfilename}')
            print('does not exist.  ReadVarsESO program terminated.')
            return
        
        state.outputfilename = 'eplusout.csv'
        state.sepvar = CHARCOMMA
        
        try:
            csv_file = open(state.outputfilename, 'w')
        except:
            audit_file.write(f'output file={state.outputfilename}\n')
            audit_file.write('cannot be opened.  It may be open in another program.\n')
            audit_file.write('Please close it and try again.\n')
            audit_file.write('ReadVarsESO program terminated.\n')
            audit_file.close()
            print(f'output file={state.outputfilename}')
            print('cannot be opened.  It may be open in another program.')
            print('Please close it and try again.')
            print('ReadVarsESO program terminated.')
            return
    
    audit_file.close()
    csv_file.close()
    eso_file.close()
    print('ReadVarsESO program completed successfully.')

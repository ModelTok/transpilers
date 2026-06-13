from sys import stderr
from memory import CFunctionPointer, Pointer

alias HINSTANCE = Pointer[NoneType]
alias FARPROC = Pointer[NoneType]

@extern
def LoadLibrary(lpFileName: Pointer[UInt8]) -> HINSTANCE:
    ...

@extern
def GetProcAddress(hModule: HINSTANCE, lpProcName: Pointer[UInt8]) -> FARPROC:
    ...

@extern
def FreeLibrary(hLibModule: HINSTANCE) -> Int:
    ...

def main() -> Int:
    print("Opening eplus shared library...\\n")
    var hInst: HINSTANCE
    hInst = LoadLibrary("{EPLUS_INSTALL_NO_SLASH}{LIB_FILE_NAME}".data())
    if not hInst:
        print("Cannot open library: \\n", file=stderr)
        return 1
    alias EnergyPlusState = Pointer[NoneType]
    print("Getting stateNew address\\n")
    alias STATEFUNCTYPE = CFunctionPointer[() -> EnergyPlusState]
    var fNewState: STATEFUNCTYPE
    fNewState = (STATEFUNCTYPE)(GetProcAddress(hInst, "stateNew".data()))
    if not fNewState:
        print("Cannot get function address stateNew \\n", file=stderr)
        return 1
    print("Initializating a new state from stateNew\\n")
    var state = fNewState()
    print("Getting initializeFunctionalAPI address\\n")
    alias INITFUNCTYPE = CFunctionPointer[(EnergyPlusState) -> None]
    var init: INITFUNCTYPE
    init = (INITFUNCTYPE)(GetProcAddress(hInst, "initializeFunctionalAPI".data()))
    if not init:
        print("Cannot get function \\n", file=stderr)
        return 1
    print("Calling to initialize via init(state)\\n")
    init(state)
    print("Closing library\\n")
    FreeLibrary(hInst)
    return 0
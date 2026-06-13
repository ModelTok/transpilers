from typing import Protocol, Callable, Optional

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with nested dataGlobal and dataSysVars
# - GlobalData: contains fMessagePtr, messageCallback, KickOffSimulation, printConsoleOutput, fProgressPtr, progressCallback
# - SysVarsData: contains DeveloperFlag

class GlobalData(Protocol):
    fMessagePtr: Optional[Callable[[str], None]]
    messageCallback: Optional[Callable[[str], None]]
    KickOffSimulation: bool
    printConsoleOutput: bool
    fProgressPtr: Optional[Callable[[int], None]]
    progressCallback: Optional[Callable[[int], None]]

class SysVarsData(Protocol):
    DeveloperFlag: bool

class EnergyPlusData(Protocol):
    dataGlobal: GlobalData
    dataSysVars: SysVarsData

def display_string(state: EnergyPlusData, string: str) -> None:
    if state.dataGlobal.fMessagePtr is not None:
        state.dataGlobal.fMessagePtr(string)
    if state.dataGlobal.messageCallback is not None:
        state.dataGlobal.messageCallback(string)
    
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(string)

def display_number_and_string(state: EnergyPlusData, number: int, string: str) -> None:
    sstm = f"{string} {number}"
    if state.dataGlobal.fMessagePtr is not None:
        state.dataGlobal.fMessagePtr(sstm)
    if state.dataGlobal.messageCallback is not None:
        state.dataGlobal.messageCallback(sstm)
    
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(f"{string} {number}")

def display_sim_days_progress(state: EnergyPlusData, current_sim_day: int, total_sim_days: int) -> None:
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    
    percent = 0
    if total_sim_days > 0:
        percent = int((float(current_sim_day) / float(total_sim_days)) * 100.0 + 0.5)
        percent = min(percent, 100)
    else:
        percent = 0
    
    if state.dataGlobal.fProgressPtr is not None:
        state.dataGlobal.fProgressPtr(percent)
    if state.dataGlobal.progressCallback is not None:
        state.dataGlobal.progressCallback(percent)

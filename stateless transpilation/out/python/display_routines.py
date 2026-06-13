# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object, source: EnergyPlus/Data/EnergyPlusData.hh
#   - dataGlobal: contains fMessagePtr, messageCallback, KickOffSimulation, printConsoleOutput, fProgressPtr, progressCallback
#   - dataSysVars: contains DeveloperFlag

from typing import Optional, Callable
from dataclasses import dataclass

@dataclass
class DataGlobal:
    fMessagePtr: Optional[Callable[[str], None]] = None
    messageCallback: Optional[Callable[[str], None]] = None
    KickOffSimulation: bool = False
    printConsoleOutput: bool = True
    fProgressPtr: Optional[Callable[[int], None]] = None
    progressCallback: Optional[Callable[[int], None]] = None

@dataclass
class DataSysVars:
    DeveloperFlag: bool = False

@dataclass
class EnergyPlusData:
    dataGlobal: DataGlobal
    dataSysVars: DataSysVars

def nint(x: float) -> int:
    if x >= 0.0:
        return int(x + 0.5)
    else:
        return int(x - 0.5)

def DisplayString(state: EnergyPlusData, String: str) -> None:
    if state.dataGlobal.fMessagePtr is not None:
        state.dataGlobal.fMessagePtr(String)
    if state.dataGlobal.messageCallback is not None:
        state.dataGlobal.messageCallback(String)
    
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(String)

def DisplayNumberAndString(state: EnergyPlusData, Number: int, String: str) -> None:
    sstm = f"{String} {Number}"
    if state.dataGlobal.fMessagePtr is not None:
        state.dataGlobal.fMessagePtr(sstm)
    if state.dataGlobal.messageCallback is not None:
        state.dataGlobal.messageCallback(sstm)
    
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(f"{String} {Number}")

def DisplaySimDaysProgress(state: EnergyPlusData, CurrentSimDay: int, TotalSimDays: int) -> None:
    percent = 0
    
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if TotalSimDays > 0:
        percent = nint((float(CurrentSimDay) / float(TotalSimDays)) * 100.0)
        percent = min(percent, 100)
    else:
        percent = 0
    
    if state.dataGlobal.fProgressPtr is not None:
        state.dataGlobal.fProgressPtr(percent)
    if state.dataGlobal.progressCallback is not None:
        state.dataGlobal.progressCallback(percent)

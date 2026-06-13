from memory import Pointer

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with nested dataGlobal and dataSysVars
# - GlobalData: contains fMessagePtr, messageCallback, KickOffSimulation, printConsoleOutput, fProgressPtr, progressCallback
# - SysVarsData: contains DeveloperFlag

struct GlobalData:
    var fMessagePtr: Pointer[fn(String) -> None]
    var messageCallback: Pointer[fn(String) -> None]
    var KickOffSimulation: Bool
    var printConsoleOutput: Bool
    var fProgressPtr: Pointer[fn(Int) -> None]
    var progressCallback: Pointer[fn(Int) -> None]

struct SysVarsData:
    var DeveloperFlag: Bool

struct EnergyPlusData:
    var dataGlobal: GlobalData
    var dataSysVars: SysVarsData

fn display_string(state: EnergyPlusData, string: String) -> None:
    if state.dataGlobal.fMessagePtr:
        state.dataGlobal.fMessagePtr[]()(string)
    if state.dataGlobal.messageCallback:
        state.dataGlobal.messageCallback[]()(string)
    
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(string)

fn display_number_and_string(state: EnergyPlusData, number: Int, string: String) -> None:
    var sstm = string + " " + String(number)
    if state.dataGlobal.fMessagePtr:
        state.dataGlobal.fMessagePtr[]()(sstm)
    if state.dataGlobal.messageCallback:
        state.dataGlobal.messageCallback[]()(sstm)
    
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(string + " " + String(number))

fn display_sim_days_progress(state: EnergyPlusData, current_sim_day: Int, total_sim_days: Int) -> None:
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    
    var percent: Int = 0
    if total_sim_days > 0:
        var temp_percent = (float(current_sim_day) / float(total_sim_days)) * 100.0
        percent = int(temp_percent + 0.5)
        percent = min(percent, 100)
    else:
        percent = 0
    
    if state.dataGlobal.fProgressPtr:
        state.dataGlobal.fProgressPtr[]()(percent)
    if state.dataGlobal.progressCallback:
        state.dataGlobal.progressCallback[]()(percent)

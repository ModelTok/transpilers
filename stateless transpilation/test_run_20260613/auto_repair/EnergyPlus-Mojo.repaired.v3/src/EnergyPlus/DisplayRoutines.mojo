from .Data.EnergyPlusData import EnergyPlusData
def nint(x: Float64) -> Int:
    return Int(round(x))
def DisplayString(inout state: EnergyPlusData, String: String):
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    if state.dataGlobal.fMessagePtr != Pointer[None]:
        state.dataGlobal.fMessagePtr(String)
    if state.dataGlobal.messageCallback:
        state.dataGlobal.messageCallback(String)
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(String)
def DisplayString(inout state: EnergyPlusData, String: StringLiteral):
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    if state.dataGlobal.fMessagePtr != Pointer[None]:
        state.dataGlobal.fMessagePtr(String(String))
    if state.dataGlobal.messageCallback:
        state.dataGlobal.messageCallback(String(String))
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(String)
def DisplayNumberAndString(
    inout state: EnergyPlusData,
    Number: Int,
    String: String
):
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    var sstm: String = String + " " + str(Number)
    if state.dataGlobal.fMessagePtr != Pointer[None]:
        state.dataGlobal.fMessagePtr(sstm)
    if state.dataGlobal.messageCallback:
        state.dataGlobal.messageCallback(sstm)
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if not state.dataGlobal.printConsoleOutput:
        return
    print(String, " ", Number)
def DisplaySimDaysProgress(
    inout state: EnergyPlusData,
    CurrentSimDay: Int,
    TotalSimDays: Int
):
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    #    
    var percent: Int = 0  # 
    if state.dataGlobal.KickOffSimulation and not state.dataSysVars.DeveloperFlag:
        return
    if TotalSimDays > 0:
        percent = nint((Float64(CurrentSimDay) / Float64(TotalSimDays)) * 100.0)
        percent = min(percent, 100)
    else:
        percent = 0
    if state.dataGlobal.fProgressPtr != Pointer[None]:
        state.dataGlobal.fProgressPtr(percent)
    if state.dataGlobal.progressCallback:
        state.dataGlobal.progressCallback(percent)
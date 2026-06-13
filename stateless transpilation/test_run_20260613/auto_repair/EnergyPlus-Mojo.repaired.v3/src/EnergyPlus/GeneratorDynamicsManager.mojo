# -*- Mojo -*-
from ElectricPowerServiceManager import *
from  import *
from CurveManager import *
from .Data.EnergyPlusData import *
from DataGenerators import *
from DataGlobalConstants import *
from DataHVACGlobals import *
from DataLoopNode import *
from MicroCHPElectricGenerator import *
from PlantUtilities import *
from ScheduleManager import *

def SetupGeneratorControlStateManager(state: EnergyPlusData, GenNum: Int):
    var NumGensWDynamics: Int = state.dataCHPElectGen.NumMicroCHPs
    if len(state.dataGenerator.GeneratorDynamics) == 0:
        state.dataGenerator.GeneratorDynamics.allocate(NumGensWDynamics)
    var thisGen = state.dataGenerator.GeneratorDynamics[GenNum - 1]
    var thisMicroCHP = state.dataCHPElectGen.MicroCHP[GenNum - 1]
    thisGen.Name = thisMicroCHP.Name
    thisGen.PelMin = thisMicroCHP.A42Model.MinElecPower
    thisGen.PelMax = thisMicroCHP.A42Model.MaxElecPower
    thisGen.UpTranLimit = thisMicroCHP.A42Model.DeltaPelMax
    thisGen.DownTranLimit = thisMicroCHP.A42Model.DeltaPelMax
    thisGen.UpTranLimitFuel = thisMicroCHP.A42Model.DeltaFuelMdotMax
    thisGen.DownTranLimitFuel = thisMicroCHP.A42Model.DeltaFuelMdotMax
    thisGen.WarmUpByTimeDelay = thisMicroCHP.A42Model.WarmUpByTimeDelay
    thisGen.WarmUpByEngineTemp = thisMicroCHP.A42Model.WarmUpByEngineTemp
    thisGen.MandatoryFullCoolDown = thisMicroCHP.A42Model.MandatoryFullCoolDown
    thisGen.WarmRestartOkay = thisMicroCHP.A42Model.WarmRestartOkay
    thisGen.WarmUpDelay = thisMicroCHP.A42Model.WarmUpDelay
    thisGen.CoolDownDelay = thisMicroCHP.A42Model.CoolDownDelay / Constant.rSecsInHour
    thisGen.PcoolDown = thisMicroCHP.A42Model.PcoolDown
    thisGen.Pstandby = thisMicroCHP.A42Model.Pstandby
    thisGen.MCeng = thisMicroCHP.A42Model.MCeng
    thisGen.MCcw = thisMicroCHP.A42Model.MCcw
    thisGen.kf = thisMicroCHP.A42Model.kf
    thisGen.TnomEngOp = thisMicroCHP.A42Model.TnomEngOp
    thisGen.kp = thisMicroCHP.A42Model.kp
    thisGen.availSched = thisMicroCHP.availSched
    thisGen.StartUpTimeDelay = thisMicroCHP.A42Model.WarmUpDelay / Constant.rSecsInHour
    thisGen.ElectEffNom = thisMicroCHP.A42Model.ElecEff
    thisGen.ThermEffNom = thisMicroCHP.A42Model.ThermEff
    thisGen.QdotHXMax = thisMicroCHP.A42Model.ThermEff * thisMicroCHP.A42Model.MaxElecPower / thisMicroCHP.A42Model.ElecEff
    thisGen.QdotHXMin = thisMicroCHP.A42Model.ThermEff * thisMicroCHP.A42Model.MinElecPower / thisMicroCHP.A42Model.ElecEff
    thisGen.QdotHXOpt = thisGen.QdotHXMax
    thisMicroCHP.DynamicsControlID = GenNum

def ManageGeneratorControlState(
    state: EnergyPlusData,
    GeneratorNum: Int,
    RunFlagElectCenter: Bool,
    RunFlagPlant: Bool,
    ElecLoadRequest: Float64,
    ThermalLoadRequest: Float64,
    ElecLoadProvided: Float64,
    OperatingMode: DataGenerators.OperatingMode,
    PLRforSubtimestepStartUp: Float64,
    PLRforSubtimestepShutDown: Float64
):
    var SysTimeElapsed: Float64 = state.dataHVACGlobal.SysTimeElapsed
    var TimeStepSys: Float64 = state.dataHVACGlobal.TimeStepSys
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    var RunFlag: Bool
    var newOpMode: DataGenerators.OperatingMode = DataGenerators.OperatingMode.Invalid
    PLRforSubtimestepStartUp = 1.0
    PLRforSubtimestepShutDown = 0.0
    var PLRStartUp: Bool = False
    var PLRShutDown: Bool = False
    state.dataGenerator.InternalFlowControl = False
    var DynaCntrlNum: Int = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].DynamicsControlID
    state.dataGenerator.InletCWnode = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].PlantInletNodeID
    state.dataGenerator.TcwIn = state.dataLoopNodes.Node[state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].PlantInletNodeID].Temp
    if state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].A42Model.InternalFlowControl:
        state.dataGenerator.InternalFlowControl = True
    state.dataGenerator.LimitMinMdotcw = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].A42Model.MinWaterMdot
    var thisGen = state.dataGenerator.GeneratorDynamics[DynaCntrlNum - 1]
    var PelInput: Float64 = ElecLoadRequest
    var ElectLoadForThermalRequest: Float64 = 0.0
    if (ThermalLoadRequest > 0.0) and RunFlagPlant:
        ElectLoadForThermalRequest = thisGen.ThermEffNom * ThermalLoadRequest / thisGen.ElectEffNom
        PelInput = max(PelInput, ElectLoadForThermalRequest)
    if (RunFlagElectCenter) or (RunFlagPlant):
        RunFlag = True
    else:
        RunFlag = False
    var SchedVal: Float64 = thisGen.availSched.getCurrentVal()
    var Pel: Float64 = PelInput
    if state.dataGenerator.InternalFlowControl and (SchedVal > 0.0):
        state.dataGenerator.TrialMdotcw = FuncDetermineCWMdotForInternalFlowControl(state, GeneratorNum, Pel, state.dataGenerator.TcwIn)
    else:
        state.dataGenerator.TrialMdotcw = state.dataLoopNodes.Node[state.dataGenerator.InletCWnode].MassFlowRate
    match thisGen.LastOpMode:
        case DataGenerators.OperatingMode.Off:
            # fallthrough to Standby
            goto standby_case
        case DataGenerators.OperatingMode.Standby:
         standby_case:
            if SchedVal == 0.0:
                newOpMode = DataGenerators.OperatingMode.Off
            elif ((SchedVal != 0.0) and (not RunFlag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
                newOpMode = DataGenerators.OperatingMode.Standby
            elif (SchedVal != 0.0) and RunFlag:
                if thisGen.WarmUpByTimeDelay:
                    if thisGen.StartUpTimeDelay == 0.0:
                        newOpMode = DataGenerators.OperatingMode.Normal
                    elif thisGen.StartUpTimeDelay >= TimeStepSys:
                        newOpMode = DataGenerators.OperatingMode.WarmUp
                        thisGen.FractionalDayofLastStartUp = (
                            Float64(state.dataGlobal.DayOfSim) +
                            (Int(state.dataGlobal.CurrentTime) +
                             (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime) - TimeStepSys))) /
                                Float64(Constant.rHoursInDay)
                        )
                    else: # time delay < time step
                        newOpMode = DataGenerators.OperatingMode.Normal
                        PLRStartUp = True
                        PLRforSubtimestepStartUp = (TimeStepSys - thisGen.StartUpTimeDelay) / TimeStepSys
                if thisGen.WarmUpByEngineTemp:
                    if state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].A42Model.Teng >= thisGen.TnomEngOp:
                        var thisMicroCHP = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1]
                        newOpMode = DataGenerators.OperatingMode.Normal
                        PLRStartUp = True
                        if (thisMicroCHP.A42Model.Teng - thisMicroCHP.A42Model.TengLast) > 0.0:
                            PLRforSubtimestepStartUp = (
                                (thisMicroCHP.A42Model.Teng - thisGen.TnomEngOp) /
                                (thisMicroCHP.A42Model.Teng - thisMicroCHP.A42Model.TengLast)
                            )
                        else:
                            PLRforSubtimestepStartUp = 1.0
                    else:
                        newOpMode = DataGenerators.OperatingMode.WarmUp
        case DataGenerators.OperatingMode.WarmUp:
            if SchedVal == 0.0:
                if thisGen.CoolDownDelay == 0.0:
                    newOpMode = DataGenerators.OperatingMode.Off
                else:
                    if thisGen.CoolDownDelay > TimeStepSys:
                        newOpMode = DataGenerators.OperatingMode.CoolDown
                        thisGen.FractionalDayofLastShutDown = (
                            Float64(state.dataGlobal.DayOfSim) +
                            (Int(state.dataGlobal.CurrentTime) +
                             (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                                Float64(Constant.rHoursInDay)
                        )
                    else:
                        newOpMode = DataGenerators.OperatingMode.Off
            elif ((SchedVal != 0.0) and (not RunFlag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
                if thisGen.CoolDownDelay == 0.0:
                    newOpMode = DataGenerators.OperatingMode.Standby
                else:
                    if thisGen.CoolDownDelay > TimeStepSys:
                        newOpMode = DataGenerators.OperatingMode.CoolDown
                        thisGen.FractionalDayofLastShutDown = (
                            Float64(state.dataGlobal.DayOfSim) +
                            (Int(state.dataGlobal.CurrentTime) +
                             (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                                Float64(Constant.rHoursInDay)
                        )
                    else:
                        newOpMode = DataGenerators.OperatingMode.Standby
            elif (SchedVal != 0.0) and RunFlag:
                if thisGen.WarmUpByTimeDelay:
                    var CurrentFractionalDay: Float64 = (
                        Float64(state.dataGlobal.DayOfSim) +
                        (Int(state.dataGlobal.CurrentTime) +
                         (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                            Float64(Constant.rHoursInDay)
                    )
                    var EndingFractionalDay: Float64 = thisGen.FractionalDayofLastStartUp + thisGen.StartUpTimeDelay / Float64(Constant.rHoursInDay)
                    if (abs(CurrentFractionalDay - EndingFractionalDay) < 0.000001) or (CurrentFractionalDay > EndingFractionalDay):
                        newOpMode = DataGenerators.OperatingMode.Normal
                        PLRStartUp = True
                        var LastSystemTimeStepFractionalDay: Float64 = CurrentFractionalDay - (TimeStepSys / Float64(Constant.rHoursInDay))
                        PLRforSubtimestepStartUp = (
                            (CurrentFractionalDay - EndingFractionalDay) /
                            (CurrentFractionalDay - LastSystemTimeStepFractionalDay)
                        )
                    else:
                        newOpMode = DataGenerators.OperatingMode.WarmUp
                elif thisGen.WarmUpByEngineTemp:
                    if state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].A42Model.TengLast >= thisGen.TnomEngOp:
                        var thisMicroCHP = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1]
                        newOpMode = DataGenerators.OperatingMode.Normal
                        PLRStartUp = True
                        if (thisMicroCHP.A42Model.Teng - thisMicroCHP.A42Model.TengLast) > 0.0:
                            PLRforSubtimestepStartUp = (
                                (thisMicroCHP.A42Model.Teng - thisGen.TnomEngOp) /
                                (thisMicroCHP.A42Model.Teng - thisMicroCHP.A42Model.TengLast)
                            )
                        else:
                            PLRforSubtimestepStartUp = 1.0
                    else:
                        newOpMode = DataGenerators.OperatingMode.WarmUp
                else:

        case DataGenerators.OperatingMode.Normal:
            if ((SchedVal == 0.0) or (not RunFlag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
                if thisGen.CoolDownDelay == 0.0:
                    if SchedVal != 0.0:
                        newOpMode = DataGenerators.OperatingMode.Standby
                    else:
                        newOpMode = DataGenerators.OperatingMode.Off
                elif thisGen.CoolDownDelay >= TimeStepSys:
                    newOpMode = DataGenerators.OperatingMode.CoolDown
                    thisGen.FractionalDayofLastShutDown = (
                        Float64(state.dataGlobal.DayOfSim) +
                        (Int(state.dataGlobal.CurrentTime) +
                         (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                            Float64(Constant.rHoursInDay)
                    )
                else: # CoolDownDelay < TimeStepSys
                    if SchedVal != 0.0:
                        newOpMode = DataGenerators.OperatingMode.Standby
                    else:
                        newOpMode = DataGenerators.OperatingMode.Off
                    PLRShutDown = True
                    PLRforSubtimestepShutDown = (thisGen.CoolDownDelay) / TimeStepSys
                    thisGen.FractionalDayofLastShutDown = (
                        Float64(state.dataGlobal.DayOfSim) +
                        (Int(state.dataGlobal.CurrentTime) +
                         (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                            Float64(Constant.rHoursInDay)
                    )
            else:
                newOpMode = DataGenerators.OperatingMode.Normal
        case DataGenerators.OperatingMode.CoolDown:
            if SchedVal == 0.0:
                if thisGen.CoolDownDelay > 0.0:
                    var CurrentFractionalDay: Float64 = (
                        Float64(state.dataGlobal.DayOfSim) +
                        (Int(state.dataGlobal.CurrentTime) +
                         (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                            Float64(Constant.rHoursInDay)
                    )
                    var EndingFractionalDay: Float64 = (
                        thisGen.FractionalDayofLastShutDown + thisGen.CoolDownDelay / Float64(Constant.rHoursInDay) -
                        (TimeStepSys / Float64(Constant.rHoursInDay))
                    )
                    if (abs(CurrentFractionalDay - EndingFractionalDay) < 0.000001) or (CurrentFractionalDay > EndingFractionalDay):
                        newOpMode = DataGenerators.OperatingMode.Off
                        PLRShutDown = True
                        var LastSystemTimeStepFractionalDay: Float64 = CurrentFractionalDay - (TimeStepSys / Float64(Constant.rHoursInDay))
                        PLRforSubtimestepShutDown = (
                            (EndingFractionalDay - LastSystemTimeStepFractionalDay) * Float64(Constant.rHoursInDay) / TimeStepSys
                        )
                    else:
                        newOpMode = DataGenerators.OperatingMode.CoolDown
                else:
                    newOpMode = DataGenerators.OperatingMode.Off
            elif ((SchedVal != 0.0) and (not RunFlag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
                if thisGen.CoolDownDelay > 0.0:
                    var CurrentFractionalDay: Float64 = (
                        Float64(state.dataGlobal.DayOfSim) +
                        (Int(state.dataGlobal.CurrentTime) +
                         (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                            Float64(Constant.rHoursInDay)
                    )
                    var EndingFractionalDay: Float64 = (
                        thisGen.FractionalDayofLastShutDown + thisGen.CoolDownDelay / Float64(Constant.rHoursInDay) -
                        (TimeStepSys / Float64(Constant.rHoursInDay))
                    )
                    if (abs(CurrentFractionalDay - EndingFractionalDay) < 0.000001) or (CurrentFractionalDay > EndingFractionalDay):
                        newOpMode = DataGenerators.OperatingMode.Standby
                        PLRShutDown = True
                        var LastSystemTimeStepFractionalDay: Float64 = CurrentFractionalDay - (TimeStepSys / Float64(Constant.rHoursInDay))
                        PLRforSubtimestepShutDown = (
                            (EndingFractionalDay - LastSystemTimeStepFractionalDay) * Float64(Constant.rHoursInDay) / TimeStepSys
                        )
                    else:
                        newOpMode = DataGenerators.OperatingMode.CoolDown
                else:
                    newOpMode = DataGenerators.OperatingMode.Standby
            elif (SchedVal != 0.0) and RunFlag:
                if thisGen.MandatoryFullCoolDown:
                    if thisGen.CoolDownDelay > 0.0:
                        var CurrentFractionalDay: Float64 = (
                            Float64(state.dataGlobal.DayOfSim) +
                            (Int(state.dataGlobal.CurrentTime) +
                             (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                                Float64(Constant.rHoursInDay)
                        )
                        var EndingFractionalDay: Float64 = (
                            thisGen.FractionalDayofLastShutDown + thisGen.CoolDownDelay / Float64(Constant.rHoursInDay) -
                            (TimeStepSys / Float64(Constant.rHoursInDay))
                        )
                        if (abs(CurrentFractionalDay - EndingFractionalDay) < 0.000001) or (CurrentFractionalDay < EndingFractionalDay):
                            newOpMode = DataGenerators.OperatingMode.CoolDown
                        else:
                            PLRShutDown = True
                            var LastSystemTimeStepFractionalDay: Float64 = CurrentFractionalDay - (TimeStepSys / Float64(Constant.rHoursInDay))
                            PLRforSubtimestepShutDown = (
                                (EndingFractionalDay - LastSystemTimeStepFractionalDay) * Float64(Constant.rHoursInDay) / TimeStepSys
                            )
                            if thisGen.StartUpTimeDelay == 0.0:
                                newOpMode = DataGenerators.OperatingMode.Normal
                                PLRStartUp = True
                                PLRforSubtimestepStartUp = (
                                    (CurrentFractionalDay - EndingFractionalDay) /
                                    (CurrentFractionalDay - LastSystemTimeStepFractionalDay)
                                )
                            elif thisGen.StartUpTimeDelay > 0.0:
                                if (CurrentFractionalDay - EndingFractionalDay) > thisGen.StartUpTimeDelay:
                                    newOpMode = DataGenerators.OperatingMode.Normal
                                    PLRStartUp = True
                                    PLRforSubtimestepStartUp = (
                                        (CurrentFractionalDay - EndingFractionalDay) /
                                        (CurrentFractionalDay - LastSystemTimeStepFractionalDay)
                                    )
                                else:
                                    newOpMode = DataGenerators.OperatingMode.WarmUp
                                    thisGen.FractionalDayofLastStartUp = (
                                        Float64(state.dataGlobal.DayOfSim) +
                                        (Int(state.dataGlobal.CurrentTime) +
                                         (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime) - TimeStepSys))) /
                                            Float64(Constant.rHoursInDay)
                                    )
                    else:
                        newOpMode = DataGenerators.OperatingMode.Standby
                else: # not mandatory full cooldown
                    if thisGen.WarmUpByTimeDelay:
                        if thisGen.StartUpTimeDelay == 0.0:
                            newOpMode = DataGenerators.OperatingMode.Normal
                        elif thisGen.StartUpTimeDelay > 0.0:
                            var CurrentFractionalDay: Float64 = (
                                Float64(state.dataGlobal.DayOfSim) +
                                (Int(state.dataGlobal.CurrentTime) +
                                 (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime)))) /
                                    Float64(Constant.rHoursInDay)
                            )
                            var EndingFractionalDay: Float64 = thisGen.FractionalDayofLastShutDown + thisGen.CoolDownDelay / Float64(Constant.rHoursInDay)
                            if (abs(CurrentFractionalDay - EndingFractionalDay) < 0.000001) or (CurrentFractionalDay > EndingFractionalDay):
                                newOpMode = DataGenerators.OperatingMode.Normal
                                PLRStartUp = True
                                var LastSystemTimeStepFractionalDay: Float64 = CurrentFractionalDay - (TimeStepSys / Float64(Constant.rHoursInDay))
                                PLRforSubtimestepStartUp = (
                                    (CurrentFractionalDay - EndingFractionalDay) /
                                    (CurrentFractionalDay - LastSystemTimeStepFractionalDay)
                                )
                            else:
                                newOpMode = DataGenerators.OperatingMode.WarmUp
                                thisGen.FractionalDayofLastStartUp = (
                                    Float64(state.dataGlobal.DayOfSim) +
                                    (Int(state.dataGlobal.CurrentTime) +
                                     (SysTimeElapsed + (state.dataGlobal.CurrentTime - Int(state.dataGlobal.CurrentTime) - TimeStepSys))) /
                                        Float64(Constant.rHoursInDay)
                                )
        case DataGenerators.OperatingMode.Invalid:
            break
        case _:
            break

    if PLRforSubtimestepStartUp < 0.0:
        PLRforSubtimestepStartUp = 0.0
    if PLRforSubtimestepStartUp > 1.0:
        PLRforSubtimestepStartUp = 1.0
    if PLRforSubtimestepShutDown < 0.0:
        PLRforSubtimestepShutDown = 0.0
    if PLRforSubtimestepShutDown > 1.0:
        PLRforSubtimestepShutDown = 1.0

    if newOpMode == DataGenerators.OperatingMode.WarmUp:
        Pel = PelInput * PLRforSubtimestepStartUp
    if newOpMode == DataGenerators.OperatingMode.Normal:
        Pel *= PLRforSubtimestepStartUp
        if Pel > thisGen.PelLastTimeStep:
            var MaxPel: Float64 = thisGen.PelLastTimeStep + thisGen.UpTranLimit * TimeStepSysSec
            if MaxPel < Pel:
                Pel = MaxPel
        elif Pel < thisGen.PelLastTimeStep:
            var MinPel: Float64 = thisGen.PelLastTimeStep - thisGen.DownTranLimit * TimeStepSysSec
            if Pel < MinPel:
                Pel = MinPel
    if newOpMode == DataGenerators.OperatingMode.CoolDown:
        Pel = 0.0
    if newOpMode == DataGenerators.OperatingMode.Off:
        Pel = 0.0
    if newOpMode == DataGenerators.OperatingMode.Standby:
        Pel = 0.0

    if Pel < thisGen.PelMin:
        Pel = thisGen.PelMin
    if Pel > thisGen.PelMax:
        Pel = thisGen.PelMax

    var thisMicroCHP = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1]
    thisMicroCHP.A42Model.OffModeTime = 0.0
    thisMicroCHP.A42Model.StandyByModeTime = 0.0
    thisMicroCHP.A42Model.WarmUpModeTime = 0.0
    thisMicroCHP.A42Model.NormalModeTime = 0.0
    thisMicroCHP.A42Model.CoolDownModeTime = 0.0

    match newOpMode:
        case DataGenerators.OperatingMode.Off:
            if PLRforSubtimestepShutDown == 0.0:
                thisMicroCHP.A42Model.OffModeTime = TimeStepSysSec
            elif (PLRforSubtimestepShutDown > 0.0) and (PLRforSubtimestepShutDown < 1.0):
                thisMicroCHP.A42Model.CoolDownModeTime = TimeStepSysSec * PLRforSubtimestepShutDown
                thisMicroCHP.A42Model.OffModeTime = TimeStepSysSec * (1.0 - PLRforSubtimestepShutDown)
            else:
                thisMicroCHP.A42Model.OffModeTime = TimeStepSysSec
        case DataGenerators.OperatingMode.Standby:
            if PLRforSubtimestepShutDown == 0.0:
                thisMicroCHP.A42Model.StandyByModeTime = TimeStepSysSec
            elif (PLRforSubtimestepShutDown > 0.0) and (PLRforSubtimestepShutDown < 1.0):
                thisMicroCHP.A42Model.CoolDownModeTime = TimeStepSysSec * PLRforSubtimestepShutDown
                thisMicroCHP.A42Model.StandyByModeTime = TimeStepSysSec * (1.0 - PLRforSubtimestepShutDown)
            else:
                thisMicroCHP.A42Model.StandyByModeTime = TimeStepSysSec
        case DataGenerators.OperatingMode.WarmUp:
            if PLRforSubtimestepShutDown == 0.0:
                thisMicroCHP.A42Model.WarmUpModeTime = TimeStepSysSec
            elif (PLRforSubtimestepShutDown > 0.0) and (PLRforSubtimestepShutDown < 1.0):
                thisMicroCHP.A42Model.CoolDownModeTime = TimeStepSysSec * PLRforSubtimestepShutDown
                thisMicroCHP.A42Model.WarmUpModeTime = TimeStepSysSec * (1.0 - PLRforSubtimestepShutDown)
            else:
                thisMicroCHP.A42Model.WarmUpModeTime = TimeStepSysSec
        case DataGenerators.OperatingMode.Normal:
            if PLRforSubtimestepStartUp == 0.0:
                thisMicroCHP.A42Model.WarmUpModeTime = TimeStepSysSec
            elif (PLRforSubtimestepStartUp > 0.0) and (PLRforSubtimestepStartUp < 1.0):
                thisMicroCHP.A42Model.WarmUpModeTime = TimeStepSysSec * (1.0 - PLRforSubtimestepStartUp)
                thisMicroCHP.A42Model.NormalModeTime = TimeStepSysSec * PLRforSubtimestepStartUp
            else:
                if PLRforSubtimestepShutDown == 0.0:
                    thisMicroCHP.A42Model.NormalModeTime = TimeStepSysSec
                elif (PLRforSubtimestepShutDown > 0.0) and (PLRforSubtimestepShutDown < 1.0):
                    thisMicroCHP.A42Model.CoolDownModeTime = TimeStepSysSec * PLRforSubtimestepShutDown
                    thisMicroCHP.A42Model.NormalModeTime = TimeStepSysSec * (1.0 - PLRforSubtimestepShutDown)
                else:
                    thisMicroCHP.A42Model.NormalModeTime = TimeStepSysSec
        case DataGenerators.OperatingMode.CoolDown:
            thisMicroCHP.A42Model.CoolDownModeTime = TimeStepSysSec
        case _:
            break

    ElecLoadProvided = Pel
    thisGen.CurrentOpMode = newOpMode
    OperatingMode = newOpMode

def ManageGeneratorFuelFlow(
    state: EnergyPlusData,
    GeneratorNum: Int,
    FuelFlowRequest: Float64,
    FuelFlowProvided: Float64,
    ConstrainedIncreasingMdot: Bool,
    ConstrainedDecreasingMdot: Bool
):
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    ConstrainedIncreasingMdot = False
    ConstrainedDecreasingMdot = False
    var MdotFuel: Float64 = FuelFlowRequest
    var DynaCntrlNum: Int = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1].DynamicsControlID
    var thisGen = state.dataGenerator.GeneratorDynamics[DynaCntrlNum - 1]
    if FuelFlowRequest > thisGen.FuelMdotLastTimestep:
        var MaxMdot: Float64 = thisGen.FuelMdotLastTimestep + thisGen.UpTranLimitFuel * TimeStepSysSec
        if MaxMdot < FuelFlowRequest:
            MdotFuel = MaxMdot
            ConstrainedIncreasingMdot = True
    elif FuelFlowRequest < thisGen.FuelMdotLastTimestep:
        var MinMdot: Float64 = thisGen.FuelMdotLastTimestep - thisGen.DownTranLimitFuel * TimeStepSysSec
        if FuelFlowRequest < MinMdot:
            MdotFuel = MinMdot
            ConstrainedDecreasingMdot = True
    else:

    FuelFlowProvided = MdotFuel

def FuncDetermineCWMdotForInternalFlowControl(
    state: EnergyPlusData,
    GeneratorNum: Int,
    Pnetss: Float64,
    TcwIn: Float64
) -> Float64:
    var FuncDetermineCWMdotForInternalFlowControl: Float64
    var thisMicroCHP = state.dataCHPElectGen.MicroCHP[GeneratorNum - 1]
    var InletNode: Int = thisMicroCHP.PlantInletNodeID
    var OutletNode: Int = thisMicroCHP.PlantOutletNodeID
    var MdotCW: Float64 = thisMicroCHP.A42Model.WaterFlowCurve.value(state, Pnetss, TcwIn)
    MdotCW = max(0.0, MdotCW)
    if thisMicroCHP.CWPlantLoc.loopNum > 0:
        PlantUtilities.SetComponentFlowRate(state, MdotCW, InletNode, OutletNode, thisMicroCHP.CWPlantLoc)
    FuncDetermineCWMdotForInternalFlowControl = MdotCW
    return FuncDetermineCWMdotForInternalFlowControl
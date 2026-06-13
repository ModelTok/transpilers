// EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
// The Regents of the University of California, through Lawrence Berkeley National Laboratory
// (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
// National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
// contributors. All rights reserved.
//
// NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
// U.S. Government consequently retains certain rights. As such, the U.S. Government has been
// granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
// worldwide license in the Software to reproduce, distribute copies to the public, prepare
// derivative works, and perform publicly and display publicly, and to permit others to do so.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted
// provided that the following conditions are met:
//
// (1) Redistributions of source code must retain the above copyright notice, this list of
//     conditions and the following disclaimer.
//
// (2) Redistributions in binary form must reproduce the above copyright notice, this list of
//     conditions and the following disclaimer in the documentation and/or other materials
//     provided with the distribution.
//
// (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
//     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
//     used to endorse or promote products derived from this software without specific prior
//     written permission.
//
// (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
//     without changes from the version obtained under this License, or (ii) Licensee makes a
//     reference solely to the software portion of its product, Licensee must refer to the
//     software as "EnergyPlus version X" software, where "X" is the version number Licensee
//     obtained under this License and may not use a different name for the software. Except as
//     specifically required in this Section (4), Licensee shall not use in a company name, a
//     product name, in advertising, publicity, or other promotional activities any name, trade
//     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
//     similar designation, without the U.S. Department of Energy's prior written consent.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHeatBalFanSys import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataZoneControls import *
from DemandManager import *
from GlobalNames import *
from .InputProcessing.InputProcessor import *
from InternalHeatGains import *
from MixedAir import *
from OutputProcessor import *
from ScheduleManager import *
from SimulationManager import *
from UtilityRoutines import *
from DataGlobals import *
from EnergyPlus import *
from BaseData import *
from Fmath import *

alias ManagerNamesUC = StaticStringArray(
    "DEMANDMANAGER:EXTERIORLIGHTS",
    "DEMANDMANAGER:LIGHTS",
    "DEMANDMANAGER:ELECTRICEQUIPMENT",
    "DEMANDMANAGER:THERMOSTATS",
    "DEMANDMANAGER:VENTILATION"
)

alias ManagePriorityNamesUC = StaticStringArray("SEQUENTIAL", "OPTIMAL", "ALL")

alias ManagerLimitNamesUC = StaticStringArray("OFF", "FIXED", "VARIABLE", "REDUCTIONRATIO")

alias ManagerLimitVentNamesUC = StaticStringArray("OFF", "FIXEDRATE", "VARIABLE", "REDUCTIONRATIO")

alias ManagerSelectionNamesUC = StaticStringArray("ALL", "ROTATEMANY", "ROTATEONE")

def ManageDemand(state: EnergyPlusData):
    if state.dataDemandManager.GetInput and not state.dataGlobal.DoingSizing:
        GetDemandManagerInput(state)
        GetDemandManagerListInput(state)
        state.dataDemandManager.GetInput = False

    if state.dataDemandManager.NumDemandManagerList > 0:
        if state.dataGlobal.WarmupFlag:
            state.dataDemandManager.BeginDemandSim = True
            if state.dataDemandManager.ClearHistory:
                for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
                    state.dataDemandManager.DemandManagerList[ListNum].History = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].MeterDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].AverageDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].PeakDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].ScheduledLimit = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].DemandLimit = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].AvoidedDemand = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].OverLimit = 0.0
                    state.dataDemandManager.DemandManagerList[ListNum].OverLimitDuration = 0.0

                for e in state.dataDemandManager.DemandMgr:
                    e.Active = False
                    e.ElapsedTime = 0
                    e.ElapsedRotationTime = 0
                    e.RotatedLoadNum = 0

            state.dataDemandManager.ClearHistory = False

        if not state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing:
            if state.dataDemandManager.BeginDemandSim:
                state.dataDemandManager.BeginDemandSim = False
                state.dataDemandManager.ClearHistory = True

            state.dataDemandManager.DemandManagerExtIterations = 0
            state.dataDemandManager.DemandManagerHBIterations = 0
            state.dataDemandManager.DemandManagerHVACIterations = 0

            state.dataDemandManager.firstTime = True
            state.dataDemandManager.ResimExt = False
            state.dataDemandManager.ResimHB = False
            state.dataDemandManager.ResimHVAC = False

            while state.dataDemandManager.firstTime or state.dataDemandManager.ResimExt or state.dataDemandManager.ResimHB or state.dataDemandManager.ResimHVAC:
                state.dataDemandManager.firstTime = False

                Resimulate(state, state.dataDemandManager.ResimExt, state.dataDemandManager.ResimHB, state.dataDemandManager.ResimHVAC)
                state.dataDemandManager.ResimExt = False
                state.dataDemandManager.ResimHB = False
                state.dataDemandManager.ResimHVAC = False

                SurveyDemandManagers(state)

                for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
                    SimulateDemandManagerList(state, ListNum, state.dataDemandManager.ResimExt, state.dataDemandManager.ResimHB, state.dataDemandManager.ResimHVAC)

                ActivateDemandManagers(state)

                if state.dataDemandManager.DemandManagerExtIterations + state.dataDemandManager.DemandManagerHBIterations + state.dataDemandManager.DemandManagerHVACIterations > 500:
                    ShowFatalError(state, "Too many DemandManager iterations. (>500)")
                    break

            for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
                ReportDemandManagerList(state, ListNum)

def SimulateDemandManagerList(state: EnergyPlusData, ListNum: Int, inout ResimExt: Bool, inout ResimHB: Bool, inout ResimHVAC: Bool):
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    var OnPeak: Bool

    var demandManagerList = state.dataDemandManager.DemandManagerList[ListNum]

    demandManagerList.ScheduledLimit = demandManagerList.limitSched.getCurrentVal()
    demandManagerList.DemandLimit = demandManagerList.ScheduledLimit * demandManagerList.SafetyFraction

    demandManagerList.MeterDemand = GetInstantMeterValue(state, demandManagerList.Meter, OutputProcessor.TimeStepType.Zone) / state.dataGlobal.TimeStepZoneSec + GetInstantMeterValue(state, demandManagerList.Meter, OutputProcessor.TimeStepType.System) / TimeStepSysSec

    var AverageDemand: Float64 = demandManagerList.AverageDemand + (demandManagerList.MeterDemand - demandManagerList.History[1]) / demandManagerList.AveragingWindow

    OnPeak = (demandManagerList.peakSched == None) or (demandManagerList.peakSched.getCurrentVal() == 1)

    if OnPeak:
        var OverLimit: Float64 = AverageDemand - demandManagerList.DemandLimit

        if OverLimit > 0.0:
            if demandManagerList.ManagerPriority == ManagePriorityType.Sequential:
                for MgrNum in range(1, demandManagerList.NumOfManager + 1):
                    var demandMgr = state.dataDemandManager.DemandMgr[demandManagerList.Manager[MgrNum]]

                    if demandMgr.CanReduceDemand:
                        demandMgr.Activate = True

                        if demandMgr.Type == ManagerType.ExtLights:
                            ResimExt = True
                        elif demandMgr.Type == ManagerType.Lights or demandMgr.Type == ManagerType.ElecEquip:
                            ResimHB = True
                            ResimHVAC = True
                        elif demandMgr.Type == ManagerType.Thermostats or demandMgr.Type == ManagerType.Ventilation:
                            ResimHVAC = True

                        break

            elif demandManagerList.ManagerPriority == ManagePriorityType.Optimal:

            elif demandManagerList.ManagerPriority == ManagePriorityType.All:
                for MgrNum in range(1, demandManagerList.NumOfManager + 1):
                    var demandMgr = state.dataDemandManager.DemandMgr[demandManagerList.Manager[MgrNum]]

                    if demandMgr.CanReduceDemand:
                        demandMgr.Activate = True

                        if demandMgr.Type == ManagerType.ExtLights:
                            ResimExt = True
                        elif demandMgr.Type == ManagerType.Lights or demandMgr.Type == ManagerType.ElecEquip:
                            ResimHB = True
                            ResimHVAC = True
                        elif demandMgr.Type == ManagerType.Thermostats or demandMgr.Type == ManagerType.Ventilation:
                            ResimHVAC = True

def GetDemandManagerListInput(state: EnergyPlusData):
    alias routineName: StringLiteral = "GetDemandManagerListInput"
    alias cCurrentModuleObject: StringLiteral = "DemandManagerAssignmentList"

    var s_ip = state.dataInputProcessing.inputProcessor

    state.dataDemandManager.NumDemandManagerList = s_ip.getNumObjectsFound(state, cCurrentModuleObject)

    if state.dataDemandManager.NumDemandManagerList > 0:
        var NumAlphas: Int
        var NumNums: Int
        var IOStat: Int
        var ErrorsFound: Bool = False
        var s_ipsc = state.dataIPShortCut

        state.dataDemandManager.DemandManagerList.allocate(state.dataDemandManager.NumDemandManagerList)

        for ListNum in range(1, state.dataDemandManager.NumDemandManagerList + 1):
            var thisDemandMgrList = state.dataDemandManager.DemandManagerList[ListNum]
            s_ip.getObjectItem(state, cCurrentModuleObject, ListNum, s_ipsc.cAlphaArgs, NumAlphas, s_ipsc.rNumericArgs, NumNums, IOStat, _, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)

            var eoh = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, s_ipsc.cAlphaArgs[1])

            thisDemandMgrList.Name = s_ipsc.cAlphaArgs[1]

            thisDemandMgrList.Meter = GetMeterIndex(state, s_ipsc.cAlphaArgs[2])

            if thisDemandMgrList.Meter == -1:
                ShowSevereError(state, "Invalid {} = {}".format(s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2]))
                ShowContinueError(state, "Entered in {} = {}".format(cCurrentModuleObject, thisDemandMgrList.Name))
                ErrorsFound = True

            elif (state.dataOutputProcessor.meters[thisDemandMgrList.Meter].resource == Constant.eResource.Electricity) or (state.dataOutputProcessor.meters[thisDemandMgrList.Meter].resource == Constant.eResource.ElectricityNet):

            else:
                ShowSevereError(state, "{} = \"{}\" invalid value {} = \"{}\".".format(cCurrentModuleObject, thisDemandMgrList.Name, s_ipsc.cAlphaFieldNames[2], s_ipsc.cAlphaArgs[2]))
                ShowContinueError(state, "Only Electricity and ElectricityNet meters are currently allowed.")
                ErrorsFound = True

            if s_ipsc.lAlphaFieldBlanks[3]:
                ShowSevereEmptyField(state, eoh, s_ipsc.cAlphaFieldNames[3])
                ErrorsFound = True
            elif (thisDemandMgrList.limitSched := Sched.GetSchedule(state, s_ipsc.cAlphaArgs[3])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[3], s_ipsc.cAlphaArgs[3])
                ErrorsFound = True

            thisDemandMgrList.SafetyFraction = s_ipsc.rNumericArgs[1]

            if s_ipsc.lAlphaFieldBlanks[4]:

            elif (thisDemandMgrList.billingSched := Sched.GetSchedule(state, s_ipsc.cAlphaArgs[4])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4])
                ErrorsFound = True

            if s_ipsc.lAlphaFieldBlanks[5]:

            elif (thisDemandMgrList.peakSched := Sched.GetSchedule(state, s_ipsc.cAlphaArgs[5])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[5], s_ipsc.cAlphaArgs[5])
                ErrorsFound = True

            thisDemandMgrList.AveragingWindow = max(Int(s_ipsc.rNumericArgs[2] / state.dataGlobal.MinutesInTimeStep), 1)

            thisDemandMgrList.History.allocate(thisDemandMgrList.AveragingWindow)
            thisDemandMgrList.History = 0.0

            thisDemandMgrList.ManagerPriority = ManagePriorityType(getEnumValue(ManagePriorityNamesUC, Util.makeUPPER(s_ipsc.cAlphaArgs[6])))
            ErrorsFound = ErrorsFound or (thisDemandMgrList.ManagerPriority == ManagePriorityType.Invalid)

            thisDemandMgrList.NumOfManager = Int((NumAlphas - 6) / 2.0)

            if thisDemandMgrList.NumOfManager > 0:
                thisDemandMgrList.Manager.allocate(thisDemandMgrList.NumOfManager)
                for MgrNum in range(1, thisDemandMgrList.NumOfManager + 1):
                    var thisManager = thisDemandMgrList.Manager[MgrNum]

                    var MgrType: ManagerType = ManagerType(getEnumValue(ManagerNamesUC, Util.makeUPPER(s_ipsc.cAlphaArgs[MgrNum * 2 + 5])))
                    if MgrType != ManagerType.Invalid:
                        thisManager = Util.FindItemInList(s_ipsc.cAlphaArgs[MgrNum * 2 + 6], state.dataDemandManager.DemandMgr)
                        if thisManager == 0:
                            ShowSevereError(state, "{} = \"{}\" invalid {} = \"{}\" not found.".format(cCurrentModuleObject, thisDemandMgrList.Name, s_ipsc.cAlphaFieldNames[MgrNum * 2 + 6], s_ipsc.cAlphaArgs[MgrNum * 2 + 6]))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, "{} = \"{}\" invalid value {} = \"{}\".".format(cCurrentModuleObject, thisDemandMgrList.Name, s_ipsc.cAlphaFieldNames[MgrNum * 2 + 5], s_ipsc.cAlphaArgs[MgrNum * 2 + 5]))
                        ErrorsFound = True

            SetupOutputVariable(state, "Demand Manager Meter Demand Power", Constant.Units.W, thisDemandMgrList.MeterDemand, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, thisDemandMgrList.Name)

            SetupOutputVariable(state, "Demand Manager Average Demand Power", Constant.Units.W, thisDemandMgrList.AverageDemand, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, thisDemandMgrList.Name)

            SetupOutputVariable(state, "Demand Manager Peak Demand Power", Constant.Units.W, thisDemandMgrList.PeakDemand, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, thisDemandMgrList.Name)

            SetupOutputVariable(state, "Demand Manager Scheduled Limit Power", Constant.Units.W, thisDemandMgrList.ScheduledLimit, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, thisDemandMgrList.Name)

            SetupOutputVariable(state, "Demand Manager Demand Limit Power", Constant.Units.W, thisDemandMgrList.DemandLimit, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, thisDemandMgrList.Name)

            SetupOutputVariable(state, "Demand Manager Over Limit Power", Constant.Units.W, thisDemandMgrList.OverLimit, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, thisDemandMgrList.Name)

            SetupOutputVariable(state, "Demand Manager Over Limit Time", Constant.Units.hr, thisDemandMgrList.OverLimitDuration, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, thisDemandMgrList.Name)

            if ErrorsFound:
                ShowFatalError(state, "Errors found in processing input for {}.".format(cCurrentModuleObject))

        SetupOutputVariable(state, "Demand Manager Exterior Energy Iteration Count", Constant.Units.None, state.dataDemandManager.DemandManagerExtIterations, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, "ManageDemand")

        SetupOutputVariable(state, "Demand Manager Heat Balance Iteration Count", Constant.Units.None, state.dataDemandManager.DemandManagerHBIterations, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, "ManageDemand")

        SetupOutputVariable(state, "Demand Manager HVAC Iteration Count", Constant.Units.None, state.dataDemandManager.DemandManagerHVACIterations, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, "ManageDemand")

def GetDemandManagerInput(state: EnergyPlusData):
    alias routineName: StringLiteral = "GetDemandManagerInput"

    var s_ip = state.dataInputProcessing.inputProcessor

    var NumAlphas: Int
    var NumNums: Int
    var NumParams: Int
    var AlphArray: Array1D_string
    var NumArray: Array1DFloat64
    var ErrorsFound: Bool = False

    var MaxAlphas: Int = 0
    var MaxNums: Int = 0
    var CurrentModuleObject: String = "DemandManager:ExteriorLights"
    var NumDemandMgrExtLights: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrExtLights > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
        MaxAlphas = max(MaxAlphas, NumAlphas)
        MaxNums = max(MaxNums, NumNums)

    CurrentModuleObject = "DemandManager:Lights"
    var NumDemandMgrLights: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrLights > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
        MaxAlphas = max(MaxAlphas, NumAlphas)
        MaxNums = max(MaxNums, NumNums)

    CurrentModuleObject = "DemandManager:ElectricEquipment"
    var NumDemandMgrElecEquip: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrElecEquip > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
        MaxAlphas = max(MaxAlphas, NumAlphas)
        MaxNums = max(MaxNums, NumNums)

    CurrentModuleObject = "DemandManager:Thermostats"
    var NumDemandMgrThermostats: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrThermostats > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
        MaxAlphas = max(MaxAlphas, NumAlphas)
        MaxNums = max(MaxNums, NumNums)

    CurrentModuleObject = "DemandManager:Ventilation"
    var NumDemandMgrVentilation: Int = s_ip.getNumObjectsFound(state, CurrentModuleObject)
    if NumDemandMgrVentilation > 0:
        s_ip.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
        MaxAlphas = max(MaxAlphas, NumAlphas)
        MaxNums = max(MaxNums, NumNums)

    state.dataDemandManager.NumDemandMgr = NumDemandMgrExtLights + NumDemandMgrLights + NumDemandMgrElecEquip + NumDemandMgrThermostats + NumDemandMgrVentilation

    var DemandMgr = state.dataDemandManager.DemandMgr

    if state.dataDemandManager.NumDemandMgr > 0:
        AlphArray.dimension(MaxAlphas, "")
        NumArray.dimension(MaxNums, 0.0)
        var IOStat: Int
        var s_ipsc = state.dataIPShortCut

        DemandMgr.allocate(state.dataDemandManager.NumDemandMgr)
        state.dataDemandManager.UniqueDemandMgrNames.reserve(state.dataDemandManager.NumDemandMgr)

        var StartIndex: Int = 1
        var EndIndex: Int = NumDemandMgrExtLights

        CurrentModuleObject = "DemandManager:ExteriorLights"

        for MgrNum in range(StartIndex, EndIndex + 1):
            var demandMgr = DemandMgr[MgrNum]

            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex + 1, AlphArray, NumAlphas, NumArray, NumNums, IOStat, _, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)

            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])

            GlobalNames.VerifyUniqueInterObjectName(state, state.dataDemandManager.UniqueDemandMgrNames, AlphArray[1], CurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)
            demandMgr.Name = AlphArray[1]

            demandMgr.Type = ManagerType.ExtLights

            if s_ipsc.lAlphaFieldBlanks[2]:
                demandMgr.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (demandMgr.availSched := Sched.GetSchedule(state, AlphArray[2])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], AlphArray[2])
                ErrorsFound = True

            demandMgr.LimitControl = ManagerLimit(getEnumValue(ManagerLimitNamesUC, Util.makeUPPER(AlphArray[3])))
            ErrorsFound = ErrorsFound or (demandMgr.LimitControl == ManagerLimit.Invalid)

            if NumArray[1] == 0.0:
                demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.LimitDuration = Int(NumArray[1])

            demandMgr.LowerLimit = NumArray[2]

            demandMgr.SelectionControl = ManagerSelection(getEnumValue(ManagerSelectionNamesUC, Util.makeUPPER(AlphArray[4])))
            ErrorsFound = ErrorsFound or (demandMgr.SelectionControl == ManagerSelection.Invalid)

            if NumArray[4] == 0.0:
                demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.RotationDuration = Int(NumArray[4])

            demandMgr.NumOfLoads = NumAlphas - 4

            if demandMgr.NumOfLoads > 0:
                demandMgr.Load.allocate(demandMgr.NumOfLoads)

                for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                    var LoadPtr: Int = Util.FindItemInList(Util.makeUPPER(AlphArray[LoadNum + 4]), state.dataExteriorEnergyUse.ExteriorLights)

                    if LoadPtr > 0:
                        demandMgr.Load[LoadNum] = LoadPtr

                    else:
                        ShowSevereError(state, "{}=\"{}\" invalid {}=\"{}\" not found.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaFieldNames[LoadNum + 4], AlphArray[LoadNum + 4]))
                        ErrorsFound = True

            else:
                ShowSevereError(state, "{}=\"{}\" invalid value for number of loads.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                ShowContinueError(state, "Number of loads is calculated to be less than one. Demand manager must have at least one load assigned.")
                ErrorsFound = True

        StartIndex = EndIndex + 1
        EndIndex += NumDemandMgrLights

        CurrentModuleObject = "DemandManager:Lights"

        for MgrNum in range(StartIndex, EndIndex + 1):
            var demandMgr = DemandMgr[MgrNum]

            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex + 1, AlphArray, NumAlphas, NumArray, NumNums, IOStat, _, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)

            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])
            GlobalNames.VerifyUniqueInterObjectName(state, state.dataDemandManager.UniqueDemandMgrNames, AlphArray[1], CurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)
            demandMgr.Name = AlphArray[1]

            demandMgr.Type = ManagerType.Lights

            if s_ipsc.lAlphaFieldBlanks[2]:
                demandMgr.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (demandMgr.availSched := Sched.GetSchedule(state, AlphArray[2])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], AlphArray[2])
                ErrorsFound = True

            demandMgr.LimitControl = ManagerLimit(getEnumValue(ManagerLimitNamesUC, Util.makeUPPER(AlphArray[3])))
            ErrorsFound = ErrorsFound or (demandMgr.LimitControl == ManagerLimit.Invalid)

            if NumArray[1] == 0.0:
                demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.LimitDuration = Int(NumArray[1])

            demandMgr.LowerLimit = NumArray[2]

            demandMgr.SelectionControl = ManagerSelection(getEnumValue(ManagerSelectionNamesUC, Util.makeUPPER(AlphArray[4])))
            ErrorsFound = ErrorsFound or (demandMgr.SelectionControl == ManagerSelection.Invalid)

            if NumArray[4] == 0.0:
                demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.RotationDuration = Int(NumArray[4])

            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - 4 + 1):
                var LoadPtr: Int = Util.FindItemInList(AlphArray[LoadNum + 4], state.dataInternalHeatGains.lightsObjects)
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += state.dataInternalHeatGains.lightsObjects[LoadPtr].numOfSpaces
                else:
                    LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 4], state.dataHeatBal.Lights)
                    if LoadPtr > 0:
                        demandMgr.NumOfLoads += 1
                    else:
                        ShowSevereError(state, "{}=\"{}\" invalid {}=\"{}\" not found.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaFieldNames[LoadNum + 4], AlphArray[LoadNum + 4]))
                        ErrorsFound = True

            if demandMgr.NumOfLoads > 0:
                demandMgr.Load.allocate(demandMgr.NumOfLoads)
                var LoadNum: Int = 0
                for Item in range(1, NumAlphas - 4 + 1):
                    var LoadPtr: Int = Util.FindItemInList(AlphArray[Item + 4], state.dataInternalHeatGains.lightsObjects)
                    if LoadPtr > 0:
                        for Item1 in range(1, state.dataInternalHeatGains.lightsObjects[LoadPtr].numOfSpaces + 1):
                            LoadNum += 1
                            demandMgr.Load[LoadNum] = state.dataInternalHeatGains.lightsObjects[LoadPtr].spaceStartPtr + Item1 - 1
                    else:
                        LoadPtr = Util.FindItemInList(AlphArray[Item + 4], state.dataHeatBal.Lights)
                        if LoadPtr > 0:
                            LoadNum += 1
                            demandMgr.Load[LoadNum] = LoadPtr

            else:
                ShowSevereError(state, "{}=\"{}\" invalid value for number of loads.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                ShowContinueError(state, "Number of loads is calculated to be less than one. Demand manager must have at least one load assigned.")
                ErrorsFound = True

        StartIndex = EndIndex + 1
        EndIndex += NumDemandMgrElecEquip

        CurrentModuleObject = "DemandManager:ElectricEquipment"

        for MgrNum in range(StartIndex, EndIndex + 1):
            var demandMgr = DemandMgr[MgrNum]

            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex + 1, AlphArray, NumAlphas, NumArray, NumNums, IOStat, _, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)

            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])
            GlobalNames.VerifyUniqueInterObjectName(state, state.dataDemandManager.UniqueDemandMgrNames, AlphArray[1], CurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)

            demandMgr.Name = AlphArray[1]

            demandMgr.Type = ManagerType.ElecEquip

            if s_ipsc.lAlphaFieldBlanks[2]:
                demandMgr.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (demandMgr.availSched := Sched.GetSchedule(state, AlphArray[2])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], AlphArray[2])
                ErrorsFound = True

            demandMgr.LimitControl = ManagerLimit(getEnumValue(ManagerLimitNamesUC, Util.makeUPPER(AlphArray[3])))
            ErrorsFound = ErrorsFound or (demandMgr.LimitControl == ManagerLimit.Invalid)

            if NumArray[1] == 0.0:
                demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.LimitDuration = Int(NumArray[1])

            demandMgr.LowerLimit = NumArray[2]

            demandMgr.SelectionControl = ManagerSelection(getEnumValue(ManagerSelectionNamesUC, Util.makeUPPER(AlphArray[4])))
            ErrorsFound = ErrorsFound or (demandMgr.SelectionControl == ManagerSelection.Invalid)

            if NumArray[4] == 0.0:
                demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.RotationDuration = Int(NumArray[4])

            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - 4 + 1):
                var LoadPtr: Int = Util.FindItemInList(AlphArray[LoadNum + 4], state.dataInternalHeatGains.zoneElectricObjects)
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += state.dataInternalHeatGains.zoneElectricObjects[LoadPtr].numOfSpaces
                else:
                    LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 4], state.dataHeatBal.ZoneElectric)
                    if LoadPtr > 0:
                        demandMgr.NumOfLoads += 1
                    else:
                        ShowSevereError(state, "{}=\"{}\" invalid {}=\"{}\" not found.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaFieldNames[LoadNum + 4], AlphArray[LoadNum + 4]))
                        ErrorsFound = True

            if demandMgr.NumOfLoads > 0:
                demandMgr.Load.allocate(demandMgr.NumOfLoads)
                var LoadNum: Int = 0
                for Item in range(1, NumAlphas - 4 + 1):
                    var LoadPtr: Int = Util.FindItemInList(AlphArray[Item + 4], state.dataInternalHeatGains.zoneElectricObjects)
                    if LoadPtr > 0:
                        for Item1 in range(1, state.dataInternalHeatGains.zoneElectricObjects[LoadPtr].numOfSpaces + 1):
                            LoadNum += 1
                            demandMgr.Load[LoadNum] = state.dataInternalHeatGains.zoneElectricObjects[LoadPtr].spaceStartPtr + Item1 - 1
                    else:
                        LoadPtr = Util.FindItemInList(AlphArray[Item + 4], state.dataHeatBal.ZoneElectric)
                        if LoadPtr > 0:
                            LoadNum += 1
                            demandMgr.Load[LoadNum] = LoadPtr

            else:
                ShowSevereError(state, "{}=\"{}\" invalid value for number of loads.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                ShowContinueError(state, "Number of loads is calculated to be less than one. Demand manager must have at least one load assigned.")
                ErrorsFound = True

        StartIndex = EndIndex + 1
        EndIndex += NumDemandMgrThermostats

        CurrentModuleObject = "DemandManager:Thermostats"

        for MgrNum in range(StartIndex, EndIndex + 1):
            var demandMgr = DemandMgr[MgrNum]

            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex + 1, AlphArray, NumAlphas, NumArray, NumNums, IOStat, _, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)

            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])

            GlobalNames.VerifyUniqueInterObjectName(state, state.dataDemandManager.UniqueDemandMgrNames, AlphArray[1], CurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)
            demandMgr.Name = AlphArray[1]

            demandMgr.Type = ManagerType.Thermostats

            if s_ipsc.lAlphaFieldBlanks[2]:
                demandMgr.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (demandMgr.availSched := Sched.GetSchedule(state, AlphArray[2])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], AlphArray[2])
                ErrorsFound = True

            demandMgr.LimitControl = ManagerLimit(getEnumValue(ManagerLimitNamesUC, Util.makeUPPER(AlphArray[3])))
            ErrorsFound = ErrorsFound or (demandMgr.LimitControl == ManagerLimit.Invalid)

            if NumArray[1] == 0.0:
                demandMgr.LimitDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.LimitDuration = Int(NumArray[1])

            demandMgr.LowerLimit = NumArray[2]
            demandMgr.UpperLimit = NumArray[3]

            if demandMgr.LowerLimit > demandMgr.UpperLimit:
                ShowSevereError(state, "Invalid input for {} = {}".format(CurrentModuleObject, AlphArray[1]))
                ShowContinueError(state, "{} [{:.2f}] > {} [{:.2f}]".format(s_ipsc.cNumericFieldNames[2], NumArray[2], s_ipsc.cNumericFieldNames[3], NumArray[3]))
                ShowContinueError(state, "{} cannot be greater than {}".format(s_ipsc.cNumericFieldNames[2], s_ipsc.cNumericFieldNames[3]))
                ErrorsFound = True

            demandMgr.SelectionControl = ManagerSelection(getEnumValue(ManagerSelectionNamesUC, Util.makeUPPER(AlphArray[4])))
            ErrorsFound = ErrorsFound or (demandMgr.SelectionControl == ManagerSelection.Invalid)

            if NumArray[5] == 0.0:
                demandMgr.RotationDuration = state.dataGlobal.MinutesInTimeStep
            else:
                demandMgr.RotationDuration = Int(NumArray[5])

            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - 4 + 1):
                var LoadPtr: Int = Util.FindItemInList(AlphArray[LoadNum + 4], state.dataZoneCtrls.TStatObjects)
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += state.dataZoneCtrls.TStatObjects[LoadPtr].NumOfZones
                else:
                    LoadPtr = Util.FindItemInList(AlphArray[LoadNum + 4], state.dataZoneCtrls.TempControlledZone)
                    if LoadPtr > 0:
                        demandMgr.NumOfLoads += 1
                    else:
                        ShowSevereError(state, "{}=\"{}\" invalid {}=\"{}\" not found.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaFieldNames[LoadNum + 4], AlphArray[LoadNum + 4]))
                        ErrorsFound = True

            if demandMgr.NumOfLoads > 0:
                demandMgr.Load.allocate(demandMgr.NumOfLoads)
                var LoadNum: Int = 0
                for Item in range(1, NumAlphas - 4 + 1):
                    var LoadPtr: Int = Util.FindItemInList(AlphArray[Item + 4], state.dataZoneCtrls.TStatObjects)
                    if LoadPtr > 0:
                        for Item1 in range(1, state.dataZoneCtrls.TStatObjects[LoadPtr].NumOfZones + 1):
                            LoadNum += 1
                            demandMgr.Load[LoadNum] = state.dataZoneCtrls.TStatObjects[LoadPtr].TempControlledZoneStartPtr + Item1 - 1
                    else:
                        LoadPtr = Util.FindItemInList(AlphArray[Item + 4], state.dataZoneCtrls.TempControlledZone)
                        if LoadPtr > 0:
                            LoadNum += 1
                            demandMgr.Load[LoadNum] = LoadPtr

            else:
                ShowSevereError(state, "{}=\"{}\" invalid value for number of loads.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                ShowContinueError(state, "Number of loads is calculated to be less than one. Demand manager must have at least one load assigned.")
                ErrorsFound = True

        StartIndex = EndIndex + 1
        EndIndex += NumDemandMgrVentilation

        CurrentModuleObject = "DemandManager:Ventilation"

        for MgrNum in range(StartIndex, EndIndex + 1):
            var demandMgr = DemandMgr[MgrNum]

            s_ip.getObjectItem(state, CurrentModuleObject, MgrNum - StartIndex + 1, AlphArray, NumAlphas, NumArray, NumNums, IOStat, _, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)

            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, AlphArray[1])
            GlobalNames.VerifyUniqueInterObjectName(state, state.dataDemandManager.UniqueDemandMgrNames, AlphArray[1], CurrentModuleObject, s_ipsc.cAlphaFieldNames[1], ErrorsFound)
            demandMgr.Name = AlphArray[1]

            demandMgr.Type = ManagerType.Ventilation

            if s_ipsc.lAlphaFieldBlanks[2]:
                demandMgr.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (demandMgr.availSched := Sched.GetSchedule(state, AlphArray[2])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], AlphArray[2])
                ErrorsFound = True

            demandMgr.LimitControl = ManagerLimit(getEnumValue(ManagerLimitVentNamesUC, Util.makeUPPER(AlphArray[3])))
            ErrorsFound = ErrorsFound or (demandMgr.LimitControl == ManagerLimit.Invalid)

            demandMgr.LimitDuration = Int(NumArray[1]) if NumArray[1] != 0.0 else state.dataGlobal.MinutesInTimeStep

            if demandMgr.LimitControl == ManagerLimit.Fixed:
                demandMgr.FixedRate = NumArray[2]
            if demandMgr.LimitControl == ManagerLimit.ReductionRatio:
                demandMgr.ReductionRatio = NumArray[3]

            demandMgr.LowerLimit = NumArray[4]

            demandMgr.SelectionControl = ManagerSelection(getEnumValue(ManagerSelectionNamesUC, Util.makeUPPER(AlphArray[4])))
            ErrorsFound = ErrorsFound or (demandMgr.SelectionControl == ManagerSelection.Invalid)

            demandMgr.RotationDuration = Int(NumArray[5]) if NumArray[5] != 0.0 else state.dataGlobal.MinutesInTimeStep

            var AlphaShift: Int = 4

            demandMgr.NumOfLoads = 0
            for LoadNum in range(1, NumAlphas - AlphaShift + 1):
                var LoadPtr: Int = MixedAir.GetOAController(state, AlphArray[LoadNum + AlphaShift])
                if LoadPtr > 0:
                    demandMgr.NumOfLoads += 1
                else:
                    ShowSevereError(state, "{}=\"{}\" invalid {}=\"{}\" not found.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1], s_ipsc.cAlphaFieldNames[LoadNum + AlphaShift], AlphArray[LoadNum + AlphaShift]))
                    ErrorsFound = True

            if demandMgr.NumOfLoads > 0:
                demandMgr.Load.allocate(demandMgr.NumOfLoads)
                for LoadNum in range(1, NumAlphas - AlphaShift + 1):
                    var LoadPtr: Int = MixedAir.GetOAController(state, AlphArray[LoadNum + AlphaShift])
                    if LoadPtr > 0:
                        demandMgr.Load[LoadNum] = LoadPtr

            else:
                ShowSevereError(state, "{}=\"{}\" invalid value for number of loads.".format(CurrentModuleObject, s_ipsc.cAlphaArgs[1]))
                ShowContinueError(state, "Number of loads is calculated to be less than one. Demand manager must have at least one load assigned.")
                ErrorsFound = True

        AlphArray.deallocate()
        NumArray.deallocate()

    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing input for demand managers. Preceding condition causes termination.")

def SurveyDemandManagers(state: EnergyPlusData):
    var CanReduceDemand: Bool

    for MgrNum in range(1, state.dataDemandManager.NumDemandMgr + 1):
        var demandMgr = state.dataDemandManager.DemandMgr[MgrNum]

        demandMgr.CanReduceDemand = False

        if not demandMgr.Available:
            continue
        if demandMgr.LimitControl == ManagerLimit.Off:
            continue

        if demandMgr.Active:
            continue

        for LoadNum in range(1, demandMgr.NumOfLoads + 1):
            var LoadPtr: Int = demandMgr.Load[LoadNum]

            LoadInterface(state, DemandAction.CheckCanReduce, MgrNum, LoadPtr, CanReduceDemand)

            if CanReduceDemand:
                demandMgr.CanReduceDemand = True
                break

def ActivateDemandManagers(state: EnergyPlusData):
    var LoadPtr: Int

    for MgrNum in range(1, state.dataDemandManager.NumDemandMgr + 1):
        var demandMgr = state.dataDemandManager.DemandMgr[MgrNum]

        if demandMgr.Activate:
            var CanReduceDemand: Bool
            demandMgr.Activate = False
            demandMgr.Active = True

            if demandMgr.SelectionControl == ManagerSelection.All:
                for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                    LoadPtr = demandMgr.Load[LoadNum]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)

            elif demandMgr.SelectionControl == ManagerSelection.Many:
                if demandMgr.NumOfLoads > 1:
                    for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                        LoadPtr = demandMgr.Load[LoadNum]
                        LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)

                    var RotatedLoadNum: Int = demandMgr.RotatedLoadNum
                    RotatedLoadNum += 1
                    if RotatedLoadNum > demandMgr.NumOfLoads:
                        RotatedLoadNum = 1
                    demandMgr.RotatedLoadNum = RotatedLoadNum

                    LoadPtr = demandMgr.Load[RotatedLoadNum]
                    LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)
                else:
                    LoadPtr = demandMgr.Load[1]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)

            elif demandMgr.SelectionControl == ManagerSelection.One:
                if demandMgr.NumOfLoads > 1:
                    for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                        LoadPtr = demandMgr.Load[LoadNum]
                        LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)

                    var RotatedLoadNum: Int = demandMgr.RotatedLoadNum
                    RotatedLoadNum += 1
                    if RotatedLoadNum > demandMgr.NumOfLoads:
                        RotatedLoadNum = 1
                    demandMgr.RotatedLoadNum = RotatedLoadNum

                    LoadPtr = demandMgr.Load[RotatedLoadNum]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)
                else:
                    LoadPtr = demandMgr.Load[1]
                    LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)

def UpdateDemandManagers(state: EnergyPlusData):
    var LoadPtr: Int
    var CanReduceDemand: Bool
    var RotatedLoadNum: Int

    for MgrNum in range(1, state.dataDemandManager.NumDemandMgr + 1):
        var demandMgr = state.dataDemandManager.DemandMgr[MgrNum]

        var Available: Bool = demandMgr.availSched.getCurrentVal() > 0.0

        demandMgr.Available = Available

        if Available:
            if demandMgr.Active:
                demandMgr.ElapsedTime += state.dataGlobal.MinutesInTimeStep

                if demandMgr.ElapsedTime >= demandMgr.LimitDuration:
                    demandMgr.ElapsedTime = 0
                    demandMgr.ElapsedRotationTime = 0
                    demandMgr.Active = False

                    for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                        LoadPtr = demandMgr.Load[LoadNum]
                        LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)

                else:
                    if demandMgr.SelectionControl == ManagerSelection.All:

                    elif demandMgr.SelectionControl == ManagerSelection.Many:
                        demandMgr.ElapsedRotationTime += state.dataGlobal.MinutesInTimeStep

                        if demandMgr.ElapsedRotationTime >= demandMgr.RotationDuration:
                            demandMgr.ElapsedRotationTime = 0

                            if demandMgr.NumOfLoads > 1:
                                RotatedLoadNum = demandMgr.RotatedLoadNum
                                LoadPtr = demandMgr.Load[RotatedLoadNum]
                                LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)

                                RotatedLoadNum += 1
                                if RotatedLoadNum > demandMgr.NumOfLoads:
                                    RotatedLoadNum = 1
                                demandMgr.RotatedLoadNum = RotatedLoadNum

                                LoadPtr = demandMgr.Load[RotatedLoadNum]
                                LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)

                    elif demandMgr.SelectionControl == ManagerSelection.One:
                        demandMgr.ElapsedRotationTime += state.dataGlobal.MinutesInTimeStep

                        if demandMgr.ElapsedRotationTime >= demandMgr.RotationDuration:
                            demandMgr.ElapsedRotationTime = 0

                            if demandMgr.NumOfLoads > 1:
                                RotatedLoadNum = demandMgr.RotatedLoadNum
                                LoadPtr = demandMgr.Load[RotatedLoadNum]
                                LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)

                                RotatedLoadNum += 1
                                if RotatedLoadNum > demandMgr.NumOfLoads:
                                    RotatedLoadNum = 1
                                demandMgr.RotatedLoadNum = RotatedLoadNum

                                LoadPtr = demandMgr.Load[RotatedLoadNum]
                                LoadInterface(state, DemandAction.SetLimit, MgrNum, LoadPtr, CanReduceDemand)

        else:
            demandMgr.Active = False

            for LoadNum in range(1, demandMgr.NumOfLoads + 1):
                LoadPtr = demandMgr.Load[LoadNum]
                LoadInterface(state, DemandAction.ClearLimit, MgrNum, LoadPtr, CanReduceDemand)

def ReportDemandManagerList(state: EnergyPlusData, ListNum: Int):
    var AveragingWindow: Int
    var OnPeak: Bool
    var OverLimit: Float64

    var demandManagerList = state.dataDemandManager.DemandManagerList[ListNum]

    var BillingPeriod: Float64 = (demandManagerList.billingSched == None) ? state.dataEnvrn.Month : demandManagerList.billingSched.getCurrentVal()

    if demandManagerList.BillingPeriod != BillingPeriod:
        demandManagerList.PeakDemand = 0.0
        demandManagerList.OverLimitDuration = 0.0

        demandManagerList.BillingPeriod = BillingPeriod

    AveragingWindow = demandManagerList.AveragingWindow
    demandManagerList.AverageDemand += (demandManagerList.MeterDemand - demandManagerList.History[1]) / AveragingWindow

    for Item in range(1, AveragingWindow):
        demandManagerList.History[Item] = demandManagerList.History[Item + 1]
    demandManagerList.History[AveragingWindow] = demandManagerList.MeterDemand

    OnPeak = (demandManagerList.peakSched == None) or (demandManagerList.peakSched.getCurrentVal() == 1)

    if OnPeak:
        demandManagerList.PeakDemand = max(demandManagerList.AverageDemand, demandManagerList.PeakDemand)

        OverLimit = demandManagerList.AverageDemand - demandManagerList.ScheduledLimit
        if OverLimit > 0.0:
            demandManagerList.OverLimit = OverLimit
            demandManagerList.OverLimitDuration += (state.dataGlobal.MinutesInTimeStep / 60.0)
        else:
            demandManagerList.OverLimit = 0.0

    else:
        demandManagerList.OverLimit = 0.0

def LoadInterface(state: EnergyPlusData, Action: DemandAction, MgrNum: Int, LoadPtr: Int, inout CanReduceDemand: Bool):
    var s_dhbf = state.dataHeatBalFanSys
    var demandMgr = state.dataDemandManager.DemandMgr[MgrNum]

    var LowestPower: Float64

    CanReduceDemand = False

    if demandMgr.Type == ManagerType.ExtLights:
        LowestPower = state.dataExteriorEnergyUse.ExteriorLights[LoadPtr].DesignLevel * demandMgr.LowerLimit
        if Action == DemandAction.CheckCanReduce:
            if state.dataExteriorEnergyUse.ExteriorLights[LoadPtr].Power > LowestPower:
                CanReduceDemand = True
        elif Action == DemandAction.SetLimit:
            state.dataExteriorEnergyUse.ExteriorLights[LoadPtr].ManageDemand = True
            state.dataExteriorEnergyUse.ExteriorLights[LoadPtr].DemandLimit = LowestPower
        elif Action == DemandAction.ClearLimit:
            state.dataExteriorEnergyUse.ExteriorLights[LoadPtr].ManageDemand = False

    elif demandMgr.Type == ManagerType.Lights:
        LowestPower = state.dataHeatBal.Lights[LoadPtr].DesignLevel * demandMgr.LowerLimit
        if Action == DemandAction.CheckCanReduce:
            if state.dataHeatBal.Lights[LoadPtr].Power > LowestPower:
                CanReduceDemand = True
        elif Action == DemandAction.SetLimit:
            state.dataHeatBal.Lights[LoadPtr].ManageDemand = True
            state.dataHeatBal.Lights[LoadPtr].DemandLimit = LowestPower
        elif Action == DemandAction.ClearLimit:
            state.dataHeatBal.Lights[LoadPtr].ManageDemand = False

    elif demandMgr.Type == ManagerType.ElecEquip:
        LowestPower = state.dataHeatBal.ZoneElectric[LoadPtr].DesignLevel * demandMgr.LowerLimit
        if Action == DemandAction.CheckCanReduce:
            if state.dataHeatBal.ZoneElectric[LoadPtr].Power > LowestPower:
                CanReduceDemand = True
        elif Action == DemandAction.SetLimit:
            state.dataHeatBal.ZoneElectric[LoadPtr].ManageDemand = True
            state.dataHeatBal.ZoneElectric[LoadPtr].DemandLimit = LowestPower
        elif Action == DemandAction.ClearLimit:
            state.dataHeatBal.ZoneElectric[LoadPtr].ManageDemand = False

    elif demandMgr.Type == ManagerType.Thermostats:
        var tempZone = state.dataZoneCtrls.TempControlledZone[LoadPtr]
        var zoneTstatSetpt = s_dhbf.zoneTstatSetpts[tempZone.ActualZoneNum]
        if Action == DemandAction.CheckCanReduce:
            if zoneTstatSetpt.setptLo > demandMgr.LowerLimit or zoneTstatSetpt.setptHi < demandMgr.UpperLimit:
                CanReduceDemand = True
        elif Action == DemandAction.SetLimit:
            tempZone.ManageDemand = True
            tempZone.HeatingResetLimit = demandMgr.LowerLimit
            tempZone.CoolingResetLimit = demandMgr.UpperLimit
        elif Action == DemandAction.ClearLimit:
            tempZone.ManageDemand = False
        if state.dataZoneCtrls.NumComfortControlledZones > 0:
            var comfortZone = state.dataZoneCtrls.ComfortControlledZone[LoadPtr]
            if state.dataHeatBalFanSys.ComfortControlType[comfortZone.ActualZoneNum] != HVAC.SetptType.Uncontrolled:
                var cmftzoneTstatSetpt = s_dhbf.zoneTstatSetpts[comfortZone.ActualZoneNum]
                if Action == DemandAction.CheckCanReduce:
                    if cmftzoneTstatSetpt.setptLo > demandMgr.LowerLimit or cmftzoneTstatSetpt.setptHi < demandMgr.UpperLimit:
                        CanReduceDemand = True
                elif Action == DemandAction.SetLimit:
                    comfortZone.ManageDemand = True
                    comfortZone.HeatingResetLimit = demandMgr.LowerLimit
                    comfortZone.CoolingResetLimit = demandMgr.UpperLimit
                elif Action == DemandAction.ClearLimit:
                    comfortZone.ManageDemand = False

    elif demandMgr.Type == ManagerType.Ventilation:
        var FlowRate: Float64 = 0.0
        FlowRate = MixedAir.OAGetFlowRate(state, LoadPtr)
        if Action == DemandAction.CheckCanReduce:
            CanReduceDemand = True
        elif Action == DemandAction.SetLimit:
            MixedAir.OASetDemandManagerVentilationState(state, LoadPtr, True)
            if demandMgr.LimitControl == ManagerLimit.Fixed:
                MixedAir.OASetDemandManagerVentilationFlow(state, LoadPtr, demandMgr.FixedRate)
            elif demandMgr.LimitControl == ManagerLimit.ReductionRatio:
                var DemandRate: Float64 = 0.0
                DemandRate = FlowRate * demandMgr.ReductionRatio
                MixedAir.OASetDemandManagerVentilationFlow(state, LoadPtr, DemandRate)
        elif Action == DemandAction.ClearLimit:
            MixedAir.OASetDemandManagerVentilationState(state, LoadPtr, False)

def InitDemandManagers(state: EnergyPlusData):
    if state.dataDemandManager.GetInput:
        GetDemandManagerInput(state)
        GetDemandManagerListInput(state)
        state.dataDemandManager.GetInput = False
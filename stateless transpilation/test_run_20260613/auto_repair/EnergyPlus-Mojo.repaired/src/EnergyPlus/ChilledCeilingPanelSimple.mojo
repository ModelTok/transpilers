from Data.BaseData import BaseGlobalStruct
from DataGlobals import *
from EnergyPlus import *
from Plant.Enums import DataPlant
from Plant.PlantLocation import PlantLocation
from ScheduleManager import Sched
from EnergyPlus import DataSizing, HVAC, Constant, OutputProcessor
from InputProcessing.InputProcessor import *
from NodeInputManager import Node
from OutputProcessor import SetupOutputVariable
from Plant.DataPlant import *
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from HeatBalanceSurfaceManager import HeatBalanceSurfaceManager
from HeatBalanceIntRadExchange import HeatBalanceIntRadExchange
from DataZoneEquipment import DataZoneEquipment
from DataSizing import CoolingCapacitySizer, BaseSizer
from BranchNodeConnections import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalFanSys import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataSurfaces import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from FluidProperties import *
from GeneralRoutines import *
from ZoneTempPredictorCorrector import *
from Autosizing.CoolingCapacitySizing import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from ObjexxFCL.Array import Array1D, Array1D_string
from ObjexxFCL.Fmath import *
from std import math, format, logging
import "std" as std
from DataPlant import DataPlant as DataPlant_
from DataLoopNodes import *
from DataGlobalConstants import *
from DataPlant import DataSizing as DataSizing_
from DataHVACGlobals import *
from DataHeatBalFanSys import MaxRadHeatFlux

# Enums
enum ClgPanelCtrlType: 
    Invalid = -1
    MAT = 0
    MRT = 1
    Operative = 2
    ODB = 3
    OWB = 4
    ZoneTotalLoad = 5
    ZoneConvectiveLoad = 6
    Num = 7

enum CondCtrl:
    Invalid = -1
    NONE = 0
    SIMPLEOFF = 1
    VARIEDOFF = 2
    Num = 3

# Struct CoolingPanelParams
struct CoolingPanelParams:
    var Name: String
    var EquipType: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
    var Schedule: String
    var SurfaceName: Array1D_string
    var SurfacePtr: Array1D_int
    var ZonePtr: Int = 0
    var availSched: Sched.Schedule? = None
    var WaterInletNode: Int = 0
    var WaterOutletNode: Int = 0
    var TotSurfToDistrib: Int = 0
    var ControlCompTypeNum: Int = 0
    var CompErrIndex: Int = 0
    var controlType: ClgPanelCtrlType = ClgPanelCtrlType.Invalid
    var ColdSetptSchedName: String
    var coldSetptSched: Sched.Schedule? = None
    var CondCtrlType: CondCtrl = CondCtrl.NONE
    var CondDewPtDeltaT: Float64 = 0.0
    var CondErrIndex: Int = 0
    var ColdThrottlRange: Float64 = 0.0
    var RatedWaterTemp: Float64 = 0.0
    var CoolingCapMethod: Int = 0
    var ScaledCoolingCapacity: Float64 = 0.0
    var UA: Float64 = 0.0
    var Offset: Float64 = 0.0
    var WaterMassFlowRate: Float64 = 0.0
    var WaterMassFlowRateMax: Float64 = 0.0
    var RatedWaterFlowRate: Float64 = 0.0
    var WaterVolFlowRateMax: Float64 = 0.0
    var WaterInletTempStd: Float64 = 0.0
    var WaterInletTemp: Float64 = 0.0
    var WaterInletEnthalpy: Float64 = 0.0
    var WaterOutletTempStd: Float64 = 0.0
    var WaterOutletTemp: Float64 = 0.0
    var WaterOutletEnthalpy: Float64 = 0.0
    var RatedZoneAirTemp: Float64 = 0.0
    var FracRadiant: Float64 = 0.0
    var FracConvect: Float64 = 0.0
    var FracDistribPerson: Float64 = 0.0
    var FracDistribToSurf: Array1D[Float64]
    var TotPower: Float64 = 0.0
    var Power: Float64 = 0.0
    var ConvPower: Float64 = 0.0
    var RadPower: Float64 = 0.0
    var TotEnergy: Float64 = 0.0
    var Energy: Float64 = 0.0
    var ConvEnergy: Float64 = 0.0
    var RadEnergy: Float64 = 0.0
    var plantLoc: PlantLocation
    var CoolingPanelLoadReSimIndex: Int = 0
    var CoolingPanelMassFlowReSimIndex: Int = 0
    var CoolingPanelInletTempFlowReSimIndex: Int = 0
    var MyEnvrnFlag: Bool = True
    var ZeroCPSourceSumHATsurf: Float64 = 0.0
    var CoolingPanelSource: Float64 = 0.0
    var CoolingPanelSrcAvg: Float64 = 0.0
    var LastCoolingPanelSrc: Float64 = 0.0
    var LastSysTimeElapsed: Float64 = 0.0
    var LastTimeStepSys: Float64 = 0.0
    var SetLoopIndexFlag: Bool = True
    var MySizeFlagCoolPanel: Bool = True
    var CheckEquipName: Bool = True
    var FieldNames: Array1D_string
    var ZoneEquipmentListChecked: Bool = False

    def CalcCoolingPanel(inout self, state: EnergyPlusData, CoolingPanelNum: Int):

    def getCoolingPanelControlTemp(self, state: EnergyPlusData, ZoneNum: Int) -> Float64:

    def SizeCoolingPanelUA(inout self, state: EnergyPlusData) -> Bool:

    def ReportCoolingPanel(inout self, state: EnergyPlusData):

# Free functions
def SimCoolingPanel(state: EnergyPlusData, EquipName: String, ControlledZoneNum: Int, FirstHVACIteration: Bool, inout PowerMet: Float64, inout CompIndex: Int):
    var CoolingPanelNum: Int
    var QZnReq: Float64
    var MaxWaterFlow: Float64
    var MinWaterFlow: Float64
    if state.dataChilledCeilingPanelSimple.GetInputFlag:
        GetCoolingPanelInput(state)
        state.dataChilledCeilingPanelSimple.GetInputFlag = False
    if CompIndex == 0:
        CoolingPanelNum = Util.FindItemInList(EquipName, state.dataChilledCeilingPanelSimple.CoolingPanel, &CoolingPanelParams.Name, state.dataChilledCeilingPanelSimple.CoolingPanel.size())
        if CoolingPanelNum == 0:
            ShowFatalError(state, "SimCoolingPanelSimple: Unit not found={}".format(EquipName))
        CompIndex = CoolingPanelNum
    else:
        CoolingPanelNum = CompIndex
        if CoolingPanelNum > state.dataChilledCeilingPanelSimple.CoolingPanel.size() or CoolingPanelNum < 1:
            ShowFatalError(state, "SimCoolingPanelSimple:  Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}".format(CoolingPanelNum, state.dataChilledCeilingPanelSimple.CoolingPanel.size(), EquipName))
        if state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].CheckEquipName:  # 0-based
            if EquipName != state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].Name:
                ShowFatalError(state, "SimCoolingPanelSimple: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}".format(CoolingPanelNum, EquipName, state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].Name))
            state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].CheckEquipName = False
    if CompIndex > 0:
        var thisCP = state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1]
        InitCoolingPanel(state, CoolingPanelNum, ControlledZoneNum, FirstHVACIteration)
        QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum-1].RemainingOutputReqToCoolSP
        if FirstHVACIteration:
            MaxWaterFlow = thisCP.WaterMassFlowRateMax
            MinWaterFlow = 0.0
        else:
            MaxWaterFlow = state.dataLoopNodes.Node[thisCP.WaterInletNode-1].MassFlowRateMaxAvail
            MinWaterFlow = state.dataLoopNodes.Node[thisCP.WaterInletNode-1].MassFlowRateMinAvail
        switch thisCP.EquipType:
            case DataPlant.PlantEquipmentType.CoolingPanel_Simple:
                thisCP.CalcCoolingPanel(state, CoolingPanelNum)
            case _:
                ShowSevereError(state, "SimCoolingPanelSimple: Errors in CoolingPanel={}".format(state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].Name))
                ShowContinueError(state, "Invalid or unimplemented equipment type={}".format(static_cast(Int, state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].EquipType)))
                ShowFatalError(state, "Preceding condition causes termination.")
        PowerMet = thisCP.TotPower
        UpdateCoolingPanel(state, CoolingPanelNum)
        state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].ReportCoolingPanel(state)
    else:
        ShowFatalError(state, "SimCoolingPanelSimple: Unit not found={}".format(EquipName))

def GetCoolingPanelInput(state: EnergyPlusData):
    const RoutineName: String = "GetCoolingPanelInput:"
    const routineName: String = "GetCoolingPanelInput"
    const MaxFraction: Float64 = 1.0
    const MinFraction: Float64 = 0.0
    const MaxWaterTempAvg: Float64 = 30.0
    const MinWaterTempAvg: Float64 = 0.0
    const MaxWaterFlowRate: Float64 = 10.0
    const MinWaterFlowRate: Float64 = 0.00001
    const WaterMassFlowDefault: Float64 = 0.063
    const MinDistribSurfaces: Int = 1
    const MinThrottlingRange: Float64 = 0.5
    const MeanAirTemperature: String = "MeanAirTemperature"
    const MeanRadiantTemperature: String = "MeanRadiantTemperature"
    const OperativeTemperature: String = "OperativeTemperature"
    const OutsideAirDryBulbTemperature: String = "OutdoorDryBulbTemperature"
    const OutsideAirWetBulbTemperature: String = "OutdoorWetBulbTemperature"
    const ZoneTotalLoad: String = "ZoneTotalLoad"
    const ZoneConvectiveLoad: String = "ZoneConvectiveLoad"
    const Off: String = "Off"
    const SimpleOff: String = "SimpleOff"
    const VariableOff: String = "VariableOff"
    var NumAlphas: Int
    var NumNumbers: Int
    var SurfNum: Int
    var IOStat: Int
    var ErrorsFound: Bool = False
    var NumCoolingPanels = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCMO_CoolingPanel_Simple)
    var s_ipsc = state.dataIPShortCut
    state.dataChilledCeilingPanelSimple.CoolingPanel.allocate(NumCoolingPanels)
    for CoolingPanelNum in range(1, NumCoolingPanels+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, cCMO_CoolingPanel_Simple, CoolingPanelNum, s_ipsc.cAlphaArgs, NumAlphas, s_ipsc.rNumericArgs, NumNumbers, IOStat, s_ipsc.lNumericFieldBlanks, s_ipsc.lAlphaFieldBlanks, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0])  # 0-based
        state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].FieldNames.allocate(NumNumbers)
        state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].FieldNames = ""
        state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].FieldNames = s_ipsc.cNumericFieldNames
        if CoolingPanelNum > 1:
            for CoolPanelNumI in range(2, NumCoolingPanels+1):
                if s_ipsc.cAlphaArgs[0] == state.dataChilledCeilingPanelSimple.CoolingPanel[CoolPanelNumI-1].Name:
                    ErrorsFound = True
                    ShowSevereError(state, "{} is used as a name for more than one simple COOLING PANEL.".format(s_ipsc.cAlphaArgs[0]))
                    ShowContinueError(state, "This is not allowed.")
        var thisCP = state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1]
        thisCP.Name = s_ipsc.cAlphaArgs[0]
        thisCP.EquipType = DataPlant.PlantEquipmentType.CoolingPanel_Simple
        thisCP.Schedule = s_ipsc.cAlphaArgs[1]
        if s_ipsc.lAlphaFieldBlanks[1]:
            thisCP.availSched = Sched.GetScheduleAlwaysOn(state)
        else:
            var sched_opt = Sched.GetSchedule(state, s_ipsc.cAlphaArgs[1])
            if sched_opt is None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[1], s_ipsc.cAlphaArgs[1])
                ErrorsFound = True
            else:
                thisCP.availSched = sched_opt
        thisCP.WaterInletNode = Node.GetOnlySingleNode(state, s_ipsc.cAlphaArgs[2], ErrorsFound, Node.ConnectionObjectType.ZoneHVACCoolingPanelRadiantConvectiveWater, s_ipsc.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        thisCP.WaterOutletNode = Node.GetOnlySingleNode(state, s_ipsc.cAlphaArgs[3], ErrorsFound, Node.ConnectionObjectType.ZoneHVACCoolingPanelRadiantConvectiveWater, s_ipsc.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        Node.TestCompSet(state, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cAlphaArgs[2], s_ipsc.cAlphaArgs[3], "Chilled Water Nodes")
        thisCP.RatedWaterTemp = s_ipsc.rNumericArgs[0]
        if thisCP.RatedWaterTemp > MaxWaterTempAvg + 0.001:
            ShowWarningError(state, "{}{}=\"{}\", {} was higher than the allowable maximum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[0]))
            ShowContinueError(state, "...reset to maximum value=[{:.2f}].".format(MaxWaterTempAvg))
            thisCP.RatedWaterTemp = MaxWaterTempAvg
        elif thisCP.RatedWaterTemp < MinWaterTempAvg - 0.001:
            ShowWarningError(state, "{}{}=\"{}\", {} was lower than the allowable minimum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[0]))
            ShowContinueError(state, "...reset to minimum value=[{:.2f}].".format(MinWaterTempAvg))
            thisCP.RatedWaterTemp = MinWaterTempAvg
        thisCP.RatedZoneAirTemp = s_ipsc.rNumericArgs[1]
        if thisCP.RatedZoneAirTemp > MaxWaterTempAvg + 0.001:
            ShowWarningError(state, "{}{}=\"{}\", {} was higher than the allowable maximum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[1]))
            ShowContinueError(state, "...reset to maximum value=[{:.2f}].".format(MaxWaterTempAvg))
            thisCP.RatedZoneAirTemp = MaxWaterTempAvg
        elif thisCP.RatedZoneAirTemp < MinWaterTempAvg - 0.001:
            ShowWarningError(state, "{}{}=\"{}\", {} was lower than the allowable minimum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[1]))
            ShowContinueError(state, "...reset to minimum value=[{:.2f}].".format(MinWaterTempAvg))
            thisCP.RatedZoneAirTemp = MinWaterTempAvg
        thisCP.RatedWaterFlowRate = s_ipsc.rNumericArgs[2]
        if thisCP.RatedWaterFlowRate < 0.00001 or thisCP.RatedWaterFlowRate > 10.0:
            ShowWarningError(state, "{}{}=\"{}\", {} is an invalid Standard Water mass flow rate.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[1]))
            ShowContinueError(state, "...reset to a default value=[{:.1f}].".format(WaterMassFlowDefault))
            thisCP.RatedWaterFlowRate = WaterMassFlowDefault
        if Util.SameString(s_ipsc.cAlphaArgs[4], "CoolingDesignCapacity"):
            thisCP.CoolingCapMethod = DataSizing.CoolingDesignCapacity
            if not s_ipsc.lNumericFieldBlanks[3]:
                thisCP.ScaledCoolingCapacity = s_ipsc.rNumericArgs[3]
                if thisCP.ScaledCoolingCapacity < 0.0 and thisCP.ScaledCoolingCapacity != DataSizing.AutoSize:
                    ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                    ShowContinueError(state, "Illegal {} = {:.7f}".format(s_ipsc.cNumericFieldNames[3], s_ipsc.rNumericArgs[3]))
                    ErrorsFound = True
            else:
                if (not s_ipsc.lAlphaFieldBlanks[5]) or (not s_ipsc.lAlphaFieldBlanks[6]):
                    ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                    ShowContinueError(state, "Input for {} = {}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                    ShowContinueError(state, "Blank field not allowed for {}".format(s_ipsc.cNumericFieldNames[3]))
                    ErrorsFound = True
        elif Util.SameString(s_ipsc.cAlphaArgs[4], "CapacityPerFloorArea"):
            thisCP.CoolingCapMethod = DataSizing.CapacityPerFloorArea
            if not s_ipsc.lNumericFieldBlanks[4]:
                thisCP.ScaledCoolingCapacity = s_ipsc.rNumericArgs[4]
                if thisCP.ScaledCoolingCapacity < 0.0:
                    ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                    ShowContinueError(state, "Input for {} = {}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                    ShowContinueError(state, "Illegal {} = {:.7f}".format(s_ipsc.cNumericFieldNames[4], s_ipsc.rNumericArgs[4]))
                    ErrorsFound = True
                elif thisCP.ScaledCoolingCapacity == DataSizing.AutoSize:
                    ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                    ShowContinueError(state, "Input for {} = {}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                    ShowContinueError(state, "Illegal {} = Autosize".format(s_ipsc.cNumericFieldNames[4]))
                    ErrorsFound = True
            else:
                ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                ShowContinueError(state, "Input for {} = {}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                ShowContinueError(state, "Blank field not allowed for {}".format(s_ipsc.cNumericFieldNames[4]))
                ErrorsFound = True
        elif Util.SameString(s_ipsc.cAlphaArgs[4], "FractionOfAutosizedCoolingCapacity"):
            thisCP.CoolingCapMethod = DataSizing.FractionOfAutosizedCoolingCapacity
            if not s_ipsc.lNumericFieldBlanks[5]:
                thisCP.ScaledCoolingCapacity = s_ipsc.rNumericArgs[5]
                if thisCP.ScaledCoolingCapacity < 0.0:
                    ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                    ShowContinueError(state, "Illegal {} = {:.7f}".format(s_ipsc.cNumericFieldNames[5], s_ipsc.rNumericArgs[5]))
                    ErrorsFound = True
            else:
                ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                ShowContinueError(state, "Input for {} = {}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
                ShowContinueError(state, "Blank field not allowed for {}".format(s_ipsc.cNumericFieldNames[5]))
                ErrorsFound = True
        else:
            ShowSevereError(state, "{} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
            ShowContinueError(state, "Illegal {} = {}".format(s_ipsc.cAlphaFieldNames[4], s_ipsc.cAlphaArgs[4]))
            ErrorsFound = True
        thisCP.WaterVolFlowRateMax = s_ipsc.rNumericArgs[6]
        if (thisCP.WaterVolFlowRateMax <= MinWaterFlowRate) and thisCP.WaterVolFlowRateMax != DataSizing.AutoSize:
            ShowWarningError(state, "{}{}=\"{}\", {} was less than the allowable minimum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[6]))
            ShowContinueError(state, "...reset to minimum value=[{:#G}].".format(MinWaterFlowRate))
            thisCP.WaterVolFlowRateMax = MinWaterFlowRate
        elif thisCP.WaterVolFlowRateMax > MaxWaterFlowRate:
            ShowWarningError(state, "{}{}=\"{}\", {} was higher than the allowable maximum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[6]))
            ShowContinueError(state, "...reset to maximum value=[{:#G}].".format(MaxWaterFlowRate))
            thisCP.WaterVolFlowRateMax = MaxWaterFlowRate
        if Util.SameString(s_ipsc.cAlphaArgs[5], MeanAirTemperature):
            thisCP.controlType = ClgPanelCtrlType.MAT
        elif Util.SameString(s_ipsc.cAlphaArgs[5], MeanRadiantTemperature):
            thisCP.controlType = ClgPanelCtrlType.MRT
        elif Util.SameString(s_ipsc.cAlphaArgs[5], OperativeTemperature):
            thisCP.controlType = ClgPanelCtrlType.Operative
        elif Util.SameString(s_ipsc.cAlphaArgs[5], OutsideAirDryBulbTemperature):
            thisCP.controlType = ClgPanelCtrlType.ODB
        elif Util.SameString(s_ipsc.cAlphaArgs[5], OutsideAirWetBulbTemperature):
            thisCP.controlType = ClgPanelCtrlType.OWB
        elif Util.SameString(s_ipsc.cAlphaArgs[5], ZoneTotalLoad):
            thisCP.controlType = ClgPanelCtrlType.ZoneTotalLoad
        elif Util.SameString(s_ipsc.cAlphaArgs[5], ZoneConvectiveLoad):
            thisCP.controlType = ClgPanelCtrlType.ZoneConvectiveLoad
        else:
            ShowWarningError(state, "Invalid {} ={}".format(s_ipsc.cAlphaFieldNames[5], s_ipsc.cAlphaArgs[5]))
            ShowContinueError(state, "Occurs in {} = {}".format(RoutineName, s_ipsc.cAlphaArgs[0]))
            ShowContinueError(state, "Control reset to MAT control for this Simple Cooling Panel.")
            thisCP.controlType = ClgPanelCtrlType.MAT
        thisCP.ColdThrottlRange = s_ipsc.rNumericArgs[7]
        if thisCP.ColdThrottlRange < MinThrottlingRange:
            ShowWarningError(state, "{}Cooling throttling range too small, reset to 0.5".format(cCMO_CoolingPanel_Simple))
            ShowContinueError(state, "Occurs in Cooling Panel={}".format(thisCP.Name))
            thisCP.ColdThrottlRange = MinThrottlingRange
        thisCP.ColdSetptSchedName = s_ipsc.cAlphaArgs[6]
        if s_ipsc.lAlphaFieldBlanks[6]:
            thisCP.coldSetptSched = Sched.GetScheduleAlwaysOff(state)
        else:
            var sched_opt = Sched.GetSchedule(state, thisCP.ColdSetptSchedName)
            if sched_opt is None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[6], s_ipsc.cAlphaArgs[6])
                ErrorsFound = True
            else:
                thisCP.coldSetptSched = sched_opt
        if Util.SameString(s_ipsc.cAlphaArgs[7], Off):
            thisCP.CondCtrlType = CondCtrl.NONE
        elif Util.SameString(s_ipsc.cAlphaArgs[7], SimpleOff):
            thisCP.CondCtrlType = CondCtrl.SIMPLEOFF
        elif Util.SameString(s_ipsc.cAlphaArgs[7], VariableOff):
            thisCP.CondCtrlType = CondCtrl.VARIEDOFF
        else:
            thisCP.CondCtrlType = CondCtrl.SIMPLEOFF
        thisCP.CondDewPtDeltaT = s_ipsc.rNumericArgs[8]
        thisCP.FracRadiant = s_ipsc.rNumericArgs[9]
        if thisCP.FracRadiant < MinFraction:
            ShowWarningError(state, "{}{}=\"{}\", {} was lower than the allowable minimum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[9]))
            ShowContinueError(state, "...reset to minimum value=[{:.2f}].".format(MinFraction))
            thisCP.FracRadiant = MinFraction
        if thisCP.FracRadiant > MaxFraction:
            ShowWarningError(state, "{}{}=\"{}\", {} was higher than the allowable maximum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[9]))
            ShowContinueError(state, "...reset to maximum value=[{:.2f}].".format(MaxFraction))
            thisCP.FracRadiant = MaxFraction
        if thisCP.FracRadiant > MaxFraction:
            ShowWarningError(state, "{}{}=\"{}\", Fraction Radiant was higher than the allowable maximum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0]))
            thisCP.FracRadiant = MaxFraction
            thisCP.FracConvect = 0.0
        else:
            thisCP.FracConvect = 1.0 - thisCP.FracRadiant
        thisCP.FracDistribPerson = s_ipsc.rNumericArgs[10]
        if thisCP.FracDistribPerson < MinFraction:
            ShowWarningError(state, "{}{}=\"{}\", {} was lower than the allowable minimum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[10]))
            ShowContinueError(state, "...reset to minimum value=[{:.3f}].".format(MinFraction))
            thisCP.FracDistribPerson = MinFraction
        if thisCP.FracDistribPerson > MaxFraction:
            ShowWarningError(state, "{}{}=\"{}\", {} was higher than the allowable maximum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[10]))
            ShowContinueError(state, "...reset to maximum value=[{:.3f}].".format(MaxFraction))
            thisCP.FracDistribPerson = MaxFraction
        thisCP.TotSurfToDistrib = NumNumbers - 11
        if (thisCP.TotSurfToDistrib < MinDistribSurfaces) and (thisCP.FracRadiant > MinFraction):
            ShowSevereError(state, "{}{}=\"{}\", the number of surface/radiant fraction groups entered was less than the allowable minimum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0]))
            ShowContinueError(state, "...the minimum that must be entered=[{}].".format(MinDistribSurfaces))
            ErrorsFound = True
            thisCP.TotSurfToDistrib = 0
        thisCP.SurfaceName.allocate(thisCP.TotSurfToDistrib)
        thisCP.SurfaceName = ""
        thisCP.SurfacePtr.allocate(thisCP.TotSurfToDistrib)
        thisCP.SurfacePtr = 0
        thisCP.FracDistribToSurf.allocate(thisCP.TotSurfToDistrib)
        thisCP.FracDistribToSurf = 0.0
        for ctrlZone in range(1, state.dataGlobal.NumOfZones+1):
            for zoneEquipTypeNum in range(1, state.dataZoneEquip.ZoneEquipList[ctrlZone-1].NumOfEquipTypes+1):
                if state.dataZoneEquip.ZoneEquipList[ctrlZone-1].EquipType[zoneEquipTypeNum-1] == DataZoneEquipment.ZoneEquipType.CoolingPanel and state.dataZoneEquip.ZoneEquipList[ctrlZone-1].EquipName[zoneEquipTypeNum-1] == thisCP.Name:
                    thisCP.ZonePtr = ctrlZone
        if thisCP.ZonePtr <= 0:
            ShowSevereError(state, "{}{}=\"{}\" is not on any ZoneHVAC:EquipmentList.".format(RoutineName, cCMO_CoolingPanel_Simple, thisCP.Name))
            ErrorsFound = True
            continue
        var AllFracsSummed: Float64 = thisCP.FracDistribPerson
        for SurfNum in range(1, thisCP.TotSurfToDistrib+1):
            thisCP.SurfaceName[SurfNum-1] = s_ipsc.cAlphaArgs[SurfNum+7]  # cAlphaArgs(8+SurfNum-1)
            thisCP.SurfacePtr[SurfNum-1] = HeatBalanceIntRadExchange.GetRadiantSystemSurface(state, cCMO_CoolingPanel_Simple, thisCP.Name, thisCP.ZonePtr, thisCP.SurfaceName[SurfNum-1], ErrorsFound)
            thisCP.FracDistribToSurf[SurfNum-1] = s_ipsc.rNumericArgs[SurfNum+10]  # rNumericArgs(12+SurfNum-1)
            if thisCP.FracDistribToSurf[SurfNum-1] > MaxFraction:
                ShowWarningError(state, "{}{}=\"{}\", {}was greater than the allowable maximum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[SurfNum+7]))
                ShowContinueError(state, "...reset to maximum value=[{:.2f}].".format(MaxFraction))
                thisCP.TotSurfToDistrib = MaxFraction  # seems buggy but kept as-is
            if thisCP.FracDistribToSurf[SurfNum-1] < MinFraction:
                ShowWarningError(state, "{}{}=\"{}\", {}was less than the allowable minimum.".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0], s_ipsc.cNumericFieldNames[SurfNum+7]))
                ShowContinueError(state, "...reset to maximum value=[{:.2f}].".format(MinFraction))
                thisCP.TotSurfToDistrib = MinFraction  # kept bug
            if thisCP.SurfacePtr[SurfNum-1] != 0:
                state.dataSurface.surfIntConv[thisCP.SurfacePtr[SurfNum-1]-1].getsRadiantHeat = True
                state.dataSurface.allGetsRadiantHeatSurfaceList.append(thisCP.SurfacePtr[SurfNum-1])
            AllFracsSummed += thisCP.FracDistribToSurf[SurfNum-1]
        if AllFracsSummed > (MaxFraction + 0.01):
            ShowSevereError(state, "{}{}=\"{}\", Summed radiant fractions for people + surface groups > 1.0".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0]))
            ErrorsFound = True
        if (AllFracsSummed < (MaxFraction - 0.01)) and (thisCP.FracRadiant > MinFraction):
            ShowSevereError(state, "{}{}=\"{}\", Summed radiant fractions for people + surface groups < 1.0".format(RoutineName, cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0]))
            ShowContinueError(state, "This would result in some of the radiant energy delivered by the high temp radiant heater being lost.")
            ShowContinueError(state, "The sum of all radiation fractions to surfaces = {:#G}".format((AllFracsSummed - thisCP.FracDistribPerson)))
            ShowContinueError(state, "The radiant fraction to people = {:#G}".format(thisCP.FracDistribPerson))
            ShowContinueError(state, "So, all radiant fractions including surfaces and people = {:#G}".format(AllFracsSummed))
            ShowContinueError(state, "This means that the fraction of radiant energy that would be lost from the high temperature radiant heater would be = {:#G}".format((1.0 - AllFracsSummed)))
            ShowContinueError(state, "Please check and correct this so that all radiant energy is accounted for in {} = {}".format(cCMO_CoolingPanel_Simple, s_ipsc.cAlphaArgs[0]))
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "{}{}Errors found getting input. Program terminates.".format(RoutineName, cCMO_CoolingPanel_Simple))
    for CoolingPanelNum in range(1, NumCoolingPanels+1):
        var thisCP = state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1]
        SetupOutputVariable(state, "Cooling Panel Total Cooling Rate", Constant.Units.W, &thisCP.Power, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Total System Cooling Rate", Constant.Units.W, &thisCP.TotPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Convective Cooling Rate", Constant.Units.W, &thisCP.ConvPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Radiant Cooling Rate", Constant.Units.W, &thisCP.RadPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Total Cooling Energy", Constant.Units.J, &thisCP.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisCP.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingPanel)
        SetupOutputVariable(state, "Cooling Panel Total System Cooling Energy", Constant.Units.J, &thisCP.TotEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisCP.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingPanel)
        SetupOutputVariable(state, "Cooling Panel Convective Cooling Energy", Constant.Units.J, &thisCP.ConvEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Radiant Cooling Energy", Constant.Units.J, &thisCP.RadEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Water Mass Flow Rate", Constant.Units.kg_s, &thisCP.WaterMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Water Inlet Temperature", Constant.Units.C, &thisCP.WaterInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisCP.Name)
        SetupOutputVariable(state, "Cooling Panel Water Outlet Temperature", Constant.Units.C, &thisCP.WaterOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisCP.Name)

def InitCoolingPanel(state: EnergyPlusData, CoolingPanelNum: Int, ControlledZoneNum: Int, FirstHVACIteration: Bool):
    const RoutineName: String = "ChilledCeilingPanelSimple:InitCoolingPanel"
    var rho: Float64
    var Cp: Float64
    var thisCP = state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1]
    var ThisInNode = state.dataLoopNodes.Node[thisCP.WaterInletNode-1]
    if thisCP.ZonePtr <= 0:
        thisCP.ZonePtr = ControlledZoneNum
    if not thisCP.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        thisCP.ZoneEquipmentListChecked = True
        if not DataZoneEquipment.CheckZoneEquipmentList(state, cCMO_CoolingPanel_Simple, thisCP.Name):
            ShowSevereError(state, "InitCoolingPanel: Unit=[{},{}] is not on any ZoneHVAC:EquipmentList.  It will not be simulated.".format(cCMO_CoolingPanel_Simple, thisCP.Name))
    if thisCP.SetLoopIndexFlag:
        if allocated(state.dataPlnt.PlantLoop):
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, thisCP.Name, thisCP.EquipType, &thisCP.plantLoc, errFlag, _, _, _, _, _)
            if errFlag:
                ShowFatalError(state, "InitCoolingPanel: Program terminated for previous conditions.")
            thisCP.SetLoopIndexFlag = False
    if not state.dataGlobal.SysSizingCalc:
        if thisCP.MySizeFlagCoolPanel and not thisCP.SetLoopIndexFlag:
            SizeCoolingPanel(state, CoolingPanelNum)
            thisCP.MySizeFlagCoolPanel = False
            if thisCP.WaterInletNode > 0:
                rho = thisCP.plantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                thisCP.WaterMassFlowRateMax = rho * thisCP.WaterVolFlowRateMax
                PlantUtilities.InitComponentNodes(state, 0.0, thisCP.WaterMassFlowRateMax, thisCP.WaterInletNode, thisCP.WaterOutletNode)
    if state.dataGlobal.BeginEnvrnFlag and thisCP.MyEnvrnFlag:
        rho = thisCP.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, RoutineName)
        thisCP.WaterMassFlowRateMax = rho * thisCP.WaterVolFlowRateMax
        PlantUtilities.InitComponentNodes(state, 0.0, thisCP.WaterMassFlowRateMax, thisCP.WaterInletNode, thisCP.WaterOutletNode)
        ThisInNode.Temp = 7.0
        Cp = thisCP.plantLoc.loop.glycol.getSpecificHeat(state, ThisInNode.Temp, RoutineName)
        ThisInNode.Enthalpy = Cp * ThisInNode.Temp
        ThisInNode.Quality = 0.0
        ThisInNode.Press = 0.0
        ThisInNode.HumRat = 0.0
        thisCP.ZeroCPSourceSumHATsurf = 0.0
        thisCP.CoolingPanelSource = 0.0
        thisCP.CoolingPanelSrcAvg = 0.0
        thisCP.LastCoolingPanelSrc = 0.0
        thisCP.LastSysTimeElapsed = 0.0
        thisCP.LastTimeStepSys = 0.0
        thisCP.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        thisCP.MyEnvrnFlag = True
    if state.dataGlobal.BeginTimeStepFlag and FirstHVACIteration:
        var ZoneNum = thisCP.ZonePtr
        thisCP.ZeroCPSourceSumHATsurf = state.dataHeatBal.Zone[ZoneNum-1].sumHATsurf(state)
        thisCP.CoolingPanelSrcAvg = 0.0
        thisCP.LastCoolingPanelSrc = 0.0
        thisCP.LastSysTimeElapsed = 0.0
        thisCP.LastTimeStepSys = 0.0
    thisCP.WaterMassFlowRate = ThisInNode.MassFlowRate
    thisCP.WaterInletTemp = ThisInNode.Temp
    thisCP.WaterInletEnthalpy = ThisInNode.Enthalpy
    thisCP.TotPower = 0.0
    thisCP.Power = 0.0
    thisCP.ConvPower = 0.0
    thisCP.RadPower = 0.0
    thisCP.TotEnergy = 0.0
    thisCP.Energy = 0.0
    thisCP.ConvEnergy = 0.0
    thisCP.RadEnergy = 0.0

def SizeCoolingPanel(state: EnergyPlusData, CoolingPanelNum: Int):
    const RoutineName: String = "SizeCoolingPanel"
    var ErrorsFound: Bool = False
    var IsAutoSize: Bool = False
    var DesCoilLoad: Float64
    var TempSize: Float64
    var rho: Float64
    var Cp: Float64
    var WaterVolFlowMaxCoolDes: Float64 = 0.0
    var WaterVolFlowMaxCoolUser: Float64 = 0.0
    DesCoilLoad = 0.0
    state.dataSize.DataScalableCapSizingON = False
    var thisCP = state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1]
    const CompType: String = "ZoneHVAC:CoolingPanel:RadiantConvective:Water"
    const CompName: String = thisCP.Name
    IsAutoSize = False
    if thisCP.ScaledCoolingCapacity == DataSizing.AutoSize:
        IsAutoSize = True
    if state.dataSize.CurZoneEqNum > 0:
        var zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum-1]
        var SizingMethod = HVAC.CoolingCapacitySizing
        var PrintFlag: Bool = True
        var errorsFound: Bool = False
        var CapSizingMethod = thisCP.CoolingCapMethod
        zoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod
        if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
            if CapSizingMethod == DataSizing.CoolingDesignCapacity and thisCP.ScaledCoolingCapacity > 0.0:
                TempSize = thisCP.ScaledCoolingCapacity
                var sizerCoolingCapacity = CoolingCapacitySizer()
                sizerCoolingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                DesCoilLoad = sizerCoolingCapacity.size(state, TempSize, errorsFound)
            elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                state.dataSize.DataScalableCapSizingON = True
                TempSize = thisCP.ScaledCoolingCapacity * state.dataHeatBal.Zone[thisCP.ZonePtr-1].FloorArea
                var sizerCoolingCapacity = CoolingCapacitySizer()
                sizerCoolingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                DesCoilLoad = sizerCoolingCapacity.size(state, TempSize, errorsFound)
                state.dataSize.DataScalableCapSizingON = False
            elif CapSizingMethod == DataSizing.FractionOfAutosizedCoolingCapacity:
                if thisCP.WaterVolFlowRateMax == DataSizing.AutoSize:
                    ShowSevereError(state, "{}: auto-sizing cannot be done for {} = {}.".format(RoutineName, CompType, thisCP.Name))
                    ShowContinueError(state, "The \"SimulationControl\" object must have the field \"Do Zone Sizing Calculation\" set to Yes when the Cooling Design Capacity Method = \"FractionOfAutosizedCoolingCapacity\".")
                    ErrorsFound = True
        else:
            if CapSizingMethod == DataSizing.CoolingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or CapSizingMethod == DataSizing.FractionOfAutosizedCoolingCapacity:
                if CapSizingMethod == DataSizing.CoolingDesignCapacity:
                    if state.dataSize.ZoneSizingRunDone:
                        CheckZoneSizing(state, CompType, CompName)
                        state.dataSize.DataConstantUsedForSizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum-1].NonAirSysDesCoolLoad
                        state.dataSize.DataFractionUsedForSizing = 1.0
                    TempSize = thisCP.ScaledCoolingCapacity
                elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                    if state.dataSize.ZoneSizingRunDone:
                        CheckZoneSizing(state, CompType, CompName)
                        zoneEqSizing.CoolingCapacity = True
                        zoneEqSizing.DesCoolingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum-1].NonAirSysDesCoolLoad
                    TempSize = thisCP.ScaledCoolingCapacity * state.dataHeatBal.Zone[thisCP.ZonePtr-1].FloorArea
                    state.dataSize.DataScalableCapSizingON = True
                elif CapSizingMethod == DataSizing.FractionOfAutosizedCoolingCapacity:
                    CheckZoneSizing(state, CompType, CompName)
                    zoneEqSizing.CoolingCapacity = True
                    zoneEqSizing.DesCoolingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum-1].NonAirSysDesCoolLoad
                    TempSize = zoneEqSizing.DesCoolingLoad * thisCP.ScaledCoolingCapacity
                    state.dataSize.DataScalableCapSizingON = True
                else:
                    TempSize = thisCP.ScaledCoolingCapacity
                var sizerCoolingCapacity = CoolingCapacitySizer()
                sizerCoolingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                DesCoilLoad = sizerCoolingCapacity.size(state, TempSize, errorsFound)
                state.dataSize.DataConstantUsedForSizing = 0.0
                state.dataSize.DataFractionUsedForSizing = 0.0
                state.dataSize.DataScalableCapSizingON = False
            else:
                DesCoilLoad = 0.0
        thisCP.ScaledCoolingCapacity = DesCoilLoad
    IsAutoSize = False
    if thisCP.WaterVolFlowRateMax == DataSizing.AutoSize:
        IsAutoSize = True
    if state.dataSize.CurZoneEqNum > 0:
        if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
            if thisCP.WaterVolFlowRateMax > 0.0:
                BaseSizer.reportSizerOutput(state, CompType, thisCP.Name, "User-Specified Maximum Cold Water Flow [m3/s]", thisCP.WaterVolFlowRateMax)
        else:
            if thisCP.WaterInletNode > 0 and thisCP.WaterOutletNode > 0:
                var PltSizCoolNum = PlantUtilities.MyPlantSizingIndex(state, CompType, thisCP.Name, thisCP.WaterInletNode, thisCP.WaterOutletNode, ErrorsFound)
                if PltSizCoolNum > 0:
                    if DesCoilLoad >= HVAC.SmallLoad:
                        rho = thisCP.plantLoc.loop.glycol.getDensity(state, 5., RoutineName)
                        Cp = thisCP.plantLoc.loop.glycol.getSpecificHeat(state, 5.0, RoutineName)
                        WaterVolFlowMaxCoolDes = DesCoilLoad / (state.dataSize.PlantSizData[PltSizCoolNum-1].DeltaT * Cp * rho)
                    else:
                        WaterVolFlowMaxCoolDes = 0.0
                else:
                    ShowSevereError(state, "Autosizing of water flow requires a cooling loop Sizing:Plant object")
                    ShowContinueError(state, "Occurs in ZoneHVAC:CoolingPanel:RadiantConvective:Water Object={}".format(thisCP.Name))
            if IsAutoSize:
                thisCP.WaterVolFlowRateMax = WaterVolFlowMaxCoolDes
                BaseSizer.reportSizerOutput(state, CompType, thisCP.Name, "Design Size Maximum Cold Water Flow [m3/s]", WaterVolFlowMaxCoolDes)
            else:
                if thisCP.WaterVolFlowRateMax > 0.0 and WaterVolFlowMaxCoolDes > 0.0:
                    WaterVolFlowMaxCoolUser = thisCP.WaterVolFlowRateMax
                    BaseSizer.reportSizerOutput(state, CompType, thisCP.Name, "Design Size Maximum Cold Water Flow [m3/s]", WaterVolFlowMaxCoolDes, "User-Specified Maximum Cold Water Flow [m3/s]", WaterVolFlowMaxCoolUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (std.abs(WaterVolFlowMaxCoolDes - WaterVolFlowMaxCoolUser) / WaterVolFlowMaxCoolUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state, "SizeCoolingPanel: Potential issue with equipment sizing for ZoneHVAC:CoolingPanel:RadiantConvective:Water = \"{}\".".format(thisCP.Name))
                            ShowContinueError(state, "User-Specified Maximum Cool Water Flow of {:#G} [m3/s]".format(WaterVolFlowMaxCoolUser))
                            ShowContinueError(state, "differs from Design Size Maximum Cool Water Flow of {:#G} [m3/s]".format(WaterVolFlowMaxCoolDes))
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
    PlantUtilities.RegisterPlantCompDesignFlow(state, thisCP.WaterInletNode, thisCP.WaterVolFlowRateMax)
    BaseSizer.calcCoilWaterFlowRates(state, thisCP.Name, "ZoneHVAC:CoolingPanel:RadiantConvective:Water", thisCP.WaterVolFlowRateMax, thisCP.plantLoc.loopNum, state.dataSize.CurZoneEqNum, state.dataSize.CurSysNum, state.dataSize.CurOASysNum, state.dataSize.FinalZoneSizing, state.dataSize.FinalSysSizing)
    if not thisCP.SizeCoolingPanelUA(state):
        ShowFatalError(state, "SizeCoolingPanelUA: Program terminated for previous conditions.")

def CoolingPanelParams.SizeCoolingPanelUA(inout self, state: EnergyPlusData) -> Bool:
    var RatCapToTheoMax: Float64
    const Cp: Float64 = 4120.0
    var MDot = self.RatedWaterFlowRate
    var MDotXCp = Cp * MDot
    var Qrated = self.ScaledCoolingCapacity
    var Tinletr = self.RatedWaterTemp
    var Tzoner = self.RatedZoneAirTemp
    if Tinletr >= Tzoner:
        ShowSevereError(state, "SizeCoolingPanelUA: Unit=[{},{}] has a rated water temperature that is higher than the rated zone temperature.".format(cCMO_CoolingPanel_Simple, self.Name))
        ShowContinueError(state, "Such a situation would not lead to cooling and thus the rated water or zone temperature or both should be adjusted.")
        self.UA = 1.0
        return False
    if (Tzoner - Tinletr) < 0.5:
        RatCapToTheoMax = std.abs(Qrated) / (MDotXCp * 0.5)
    else:
        RatCapToTheoMax = std.abs(Qrated) / (MDotXCp * std.abs(Tinletr - Tzoner))
    if (RatCapToTheoMax < 1.1) and (RatCapToTheoMax > 0.9999):
        RatCapToTheoMax = 0.9999
    elif RatCapToTheoMax >= 1.1:
        ShowSevereError(state, "SizeCoolingPanelUA: Unit=[{},{}] has a cooling capacity that is greater than the maximum possible value.".format(cCMO_CoolingPanel_Simple, self.Name))
        ShowContinueError(state, "The result of this is that a UA value is impossible to calculate.")
        ShowContinueError(state, "Check the rated input for temperatures, flow, and capacity for this unit.")
        ShowContinueError(state, "The ratio of the capacity to the rated theoretical maximum must be less than unity.")
        ShowContinueError(state, "The most likely cause for this is probably either the capacity (whether autosized or hardwired) being too high, the rated flow being too low, rated temperatures being too close to each other, or all of those reasons.")
        ShowContinueError(state, "Compare the rated capacity in your input to the product of the rated mass flow rate, Cp of water, and the difference between the rated temperatures.")
        ShowContinueError(state, "If the rated capacity is higher than this product, then the cooling panel would violate the Second Law of Thermodynamics.")
        self.UA = 1.0
        return False
    self.UA = -MDotXCp * math.log(1.0 - RatCapToTheoMax)
    if self.UA <= 0.0:
        ShowSevereError(state, "SizeCoolingPanelUA: Unit=[{},{}] has a zero or negative calculated UA value.".format(cCMO_CoolingPanel_Simple, self.Name))
        ShowContinueError(state, "This is not allowed.  Please check the rated input parameters for this device to ensure that the values are correct.")
        return False
    return True

def CoolingPanelParams.CalcCoolingPanel(inout self, state: EnergyPlusData, CoolingPanelNum: Int):
    const MinFrac: Float64 = 0.0005
    const Maxiter: Int = 20
    const IterTol: Float64 = 0.005
    const RoutineName: String = "CalcCoolingPanel"
    var RadHeat: Float64
    var CoolingPanelCool: Float64
    var waterMassFlowRate: Float64
    var CapacitanceWater: Float64
    var NTU: Float64
    var Effectiveness: Float64
    var Cp: Float64
    var MCpEpsAct: Float64
    var MCpEpsLow: Float64
    var MCpEpsHigh: Float64
    var MdotLow: Float64
    var MdotHigh: Float64
    var FracGuess: Float64
    var MdotGuess: Float64
    var MCpEpsGuess: Float64
    var ControlTemp: Float64
    var SetPointTemp: Float64
    var OffTempCool: Float64
    var FullOnTempCool: Float64
    var MassFlowFrac: Float64
    var LoadMet: Float64
    var CoolingPanelOn: Bool
    var waterOutletTemp: Float64
    var ZoneNum = self.ZonePtr
    var QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum-1].RemainingOutputReqToCoolSP
    var waterInletTemp = self.WaterInletTemp
    var waterMassFlowRateMax = self.WaterMassFlowRateMax
    var Xr = self.FracRadiant
    CoolingPanelOn = self.availSched.getCurrentVal() > 0
    var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum-1]
    var Tzone = Xr * thisZoneHB.MRT + ((1.0 - Xr) * thisZoneHB.MAT)
    if waterInletTemp >= Tzone:
        CoolingPanelOn = False
    var DewPointTemp = Psychrometrics.PsyTdpFnWPb(state, state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum-1].airHumRat, state.dataEnvrn.OutBaroPress)
    if waterInletTemp < (DewPointTemp + self.CondDewPtDeltaT) and (CoolingPanelOn):
        if self.CondCtrlType == CondCtrl.NONE:

        elif self.CondCtrlType == CondCtrl.SIMPLEOFF:
            waterMassFlowRate = 0.0
            CoolingPanelOn = False
            if not state.dataGlobal.WarmupFlag:
                if self.CondErrIndex == 0:
                    ShowWarningMessage(state, "{} [{}] inlet water temperature below dew-point temperature--potential for condensation exists".format(cCMO_CoolingPanel_Simple, self.Name))
                    ShowContinueError(state, "Flow to the simple cooling panel will be shut-off to avoid condensation")
                    ShowContinueError(state, "Water inlet temperature = {:.2f}".format(waterInletTemp))
                    ShowContinueError(state, "Zone dew-point temperature + safety delta T= {:.2f}".format(DewPointTemp + self.CondDewPtDeltaT))
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, "Note that a {:.4f} C safety was chosen in the input for the shut-off criteria".format(self.CondDewPtDeltaT))
                ShowRecurringWarningErrorAtEnd(state, cCMO_CoolingPanel_Simple + " [" + self.Name + "] condensation shut-off occurrence continues.", self.CondErrIndex, DewPointTemp, DewPointTemp, _, "C", "C")
        elif self.CondCtrlType == CondCtrl.VARIEDOFF:
            waterInletTemp = DewPointTemp + self.CondDewPtDeltaT
    if (self.controlType == ClgPanelCtrlType.ZoneTotalLoad) or (self.controlType == ClgPanelCtrlType.ZoneConvectiveLoad):
        if QZnReq < -HVAC.SmallLoad and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum-1] and (CoolingPanelOn):
            Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, waterInletTemp, RoutineName)
            if self.controlType == ClgPanelCtrlType.ZoneConvectiveLoad:
                QZnReq = QZnReq / self.FracConvect
            MCpEpsAct = QZnReq / (waterInletTemp - Tzone)
            MCpEpsLow = 0.0
            MdotLow = 0.0
            MCpEpsHigh = waterMassFlowRateMax * Cp * (1.0 - math.exp(-self.UA / (waterMassFlowRateMax * Cp)))
            MdotHigh = waterMassFlowRateMax
            if MCpEpsAct <= MCpEpsLow:
                MCpEpsAct = MCpEpsLow
                waterMassFlowRate = 0.0
                state.dataLoopNodes.Node[self.WaterInletNode-1].MassFlowRate = 0.0
                CoolingPanelOn = False
            elif MCpEpsAct >= MCpEpsHigh:
                MCpEpsAct = MCpEpsHigh
                waterMassFlowRate = waterMassFlowRateMax
                state.dataLoopNodes.Node[self.WaterInletNode-1].MassFlowRate = waterMassFlowRateMax
            else:
                for iter in range(1, Maxiter+1):
                    FracGuess = (MCpEpsAct - MCpEpsLow) / (MCpEpsHigh - MCpEpsLow)
                    MdotGuess = MdotHigh * FracGuess
                    MCpEpsGuess = MdotGuess * Cp * (1.0 - math.exp(-self.UA / (MdotGuess * Cp)))
                    if MCpEpsGuess <= MCpEpsAct:
                        MCpEpsLow = MCpEpsGuess
                        MdotLow = MdotGuess
                    else:
                        MCpEpsHigh = MCpEpsGuess
                        MdotHigh = MdotGuess
                    if ((MCpEpsAct - MCpEpsGuess) / MCpEpsAct) <= IterTol:
                        waterMassFlowRate = MdotGuess
                        state.dataLoopNodes.Node[self.WaterInletNode-1].MassFlowRate = waterMassFlowRate
                        break
        else:
            CoolingPanelOn = False
    else:
        if CoolingPanelOn:
            ControlTemp = self.getCoolingPanelControlTemp(state, ZoneNum)
            SetPointTemp = self.coldSetptSched.getCurrentVal()
            OffTempCool = SetPointTemp - 0.5 * self.ColdThrottlRange
            FullOnTempCool = SetPointTemp + 0.5 * self.ColdThrottlRange
            if ControlTemp <= OffTempCool:
                MassFlowFrac = 0.0
                CoolingPanelOn = False
            elif ControlTemp >= FullOnTempCool:
                MassFlowFrac = 1.0
            else:
                MassFlowFrac = (ControlTemp - OffTempCool) / self.ColdThrottlRange
                if MassFlowFrac < MinFrac:
                    MassFlowFrac = MinFrac
            waterMassFlowRate = MassFlowFrac * waterMassFlowRateMax
    if CoolingPanelOn:
        PlantUtilities.SetComponentFlowRate(state, waterMassFlowRate, self.WaterInletNode, self.WaterOutletNode, self.plantLoc)
        if waterMassFlowRate <= 0.0:
            CoolingPanelOn = False
    if CoolingPanelOn:
        Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, waterInletTemp, RoutineName)
        Effectiveness = 1.0 - math.exp(-self.UA / (waterMassFlowRate * Cp))
        if Effectiveness <= 0.0:
            Effectiveness = 0.0
        elif Effectiveness >= 1.0:
            Effectiveness = 1.0
        CoolingPanelCool = (Effectiveness) * waterMassFlowRate * Cp * (waterInletTemp - Tzone)
        waterOutletTemp = self.WaterInletTemp - (CoolingPanelCool / (waterMassFlowRate * Cp))
        RadHeat = CoolingPanelCool * self.FracRadiant
        state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].CoolingPanelSource = RadHeat
        if self.FracRadiant <= MinFrac:
            LoadMet = CoolingPanelCool
        else:
            DistributeCoolingPanelRadGains(state)
            HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
            HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
            LoadMet = (state.dataHeatBal.Zone[ZoneNum-1].sumHATsurf(state) - self.ZeroCPSourceSumHATsurf) + (CoolingPanelCool * self.FracConvect) + (RadHeat * self.FracDistribPerson)
        self.WaterOutletEnthalpy = self.WaterInletEnthalpy - CoolingPanelCool / waterMassFlowRate
    else:
        CapacitanceWater = 0.0
        NTU = 0.0
        Effectiveness = 0.0
        waterOutletTemp = waterInletTemp
        CoolingPanelCool = 0.0
        LoadMet = 0.0
        RadHeat = 0.0
        waterMassFlowRate = 0.0
        self.CoolingPanelSource = 0.0
        self.WaterOutletEnthalpy = self.WaterInletEnthalpy
    self.WaterOutletTemp = waterOutletTemp
    self.WaterMassFlowRate = waterMassFlowRate
    self.TotPower = LoadMet
    self.Power = CoolingPanelCool
    self.ConvPower = CoolingPanelCool - RadHeat
    self.RadPower = RadHeat

def CoolingPanelParams.getCoolingPanelControlTemp(self, state: EnergyPlusData, ZoneNum: Int) -> Float64:
    switch self.controlType:
        case ClgPanelCtrlType.MAT:
            return state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum-1].MAT
        case ClgPanelCtrlType.MRT:
            return state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum-1].MRT
        case ClgPanelCtrlType.Operative:
            return 0.5 * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum-1].MAT + state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum-1].MRT)
        case ClgPanelCtrlType.ODB:
            return state.dataHeatBal.Zone[ZoneNum-1].OutDryBulbTemp
        case ClgPanelCtrlType.OWB:
            return state.dataHeatBal.Zone[ZoneNum-1].OutWetBulbTemp
        case _:
            assert(False)
            return -99990

def UpdateCoolingPanel(state: EnergyPlusData, CoolingPanelNum: Int):
    var SysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
    var TimeStepSys = state.dataHVACGlobal.TimeStepSys
    var thisCP = state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1]
    if thisCP.LastSysTimeElapsed == SysTimeElapsed:
        thisCP.CoolingPanelSrcAvg -= thisCP.LastCoolingPanelSrc * thisCP.LastTimeStepSys / state.dataGlobal.TimeStepZone
    thisCP.CoolingPanelSrcAvg += thisCP.CoolingPanelSource * TimeStepSys / state.dataGlobal.TimeStepZone
    thisCP.LastCoolingPanelSrc = thisCP.CoolingPanelSource
    thisCP.LastSysTimeElapsed = SysTimeElapsed
    thisCP.LastTimeStepSys = TimeStepSys
    var WaterInletNode = thisCP.WaterInletNode
    var WaterOutletNode = thisCP.WaterOutletNode
    var ThisInNode = state.dataLoopNodes.Node[WaterInletNode-1]
    var ThisOutNode = state.dataLoopNodes.Node[WaterOutletNode-1]
    PlantUtilities.SafeCopyPlantNode(state, WaterInletNode, WaterOutletNode)
    ThisOutNode.Temp = thisCP.WaterOutletTemp
    ThisOutNode.Enthalpy = thisCP.WaterOutletEnthalpy
    ThisInNode.MassFlowRate = thisCP.WaterMassFlowRate
    ThisOutNode.MassFlowRate = thisCP.WaterMassFlowRate
    ThisInNode.MassFlowRateMax = thisCP.WaterMassFlowRateMax
    ThisOutNode.MassFlowRateMax = thisCP.WaterMassFlowRateMax

def UpdateCoolingPanelSourceValAvg(state: EnergyPlusData, inout CoolingPanelSysOn: Bool):
    CoolingPanelSysOn = False
    if not allocated(state.dataChilledCeilingPanelSimple.CoolingPanel):
        return
    for CoolingPanelNum in range(1, state.dataChilledCeilingPanelSimple.CoolingPanel.size()+1):
        if state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum-1].CoolingPanelSrcAvg != 0.0:
            CoolingPanelSysOn = True
            break
    for cp in state.dataChilledCeilingPanelSimple.CoolingPanel:
        cp.CoolingPanelSource = cp.CoolingPanelSrcAvg
    DistributeCoolingPanelRadGains(state)

def DistributeCoolingPanelRadGains(state: EnergyPlusData):
    const SmallestArea: Float64 = 0.001
    for thisCP in state.dataChilledCeilingPanelSimple.CoolingPanel:
        for radSurfNum in range(1, thisCP.TotSurfToDistrib+1):
            var surfNum = thisCP.SurfacePtr[radSurfNum-1]
            state.dataHeatBalFanSys.surfQRadFromHVAC[surfNum-1].CoolingPanel = 0.0
    state.dataHeatBalFanSys.ZoneQCoolingPanelToPerson = 0.0
    for thisCP in state.dataChilledCeilingPanelSimple.CoolingPanel:
        var ZoneNum = thisCP.ZonePtr
        if ZoneNum <= 0:
            continue
        state.dataHeatBalFanSys.ZoneQCoolingPanelToPerson[ZoneNum-1] += thisCP.CoolingPanelSource * thisCP.FracDistribPerson
        for RadSurfNum in range(1, thisCP.TotSurfToDistrib+1):
            var SurfNum = thisCP.SurfacePtr[RadSurfNum-1]
            var ThisSurf = state.dataSurface.Surface[SurfNum-1]
            if ThisSurf.Area > SmallestArea:
                var ThisSurfIntensity = (thisCP.CoolingPanelSource * thisCP.FracDistribToSurf[RadSurfNum-1] / ThisSurf.Area)
                state.dataHeatBalFanSys.surfQRadFromHVAC[SurfNum-1].CoolingPanel += ThisSurfIntensity
                if ThisSurfIntensity > MaxRadHeatFlux:
                    ShowSevereError(state, "DistributeCoolingPanelRadGains:  excessive thermal radiation heat flux intensity detected")
                    ShowContinueError(state, "Surface = {}".format(ThisSurf.Name))
                    ShowContinueError(state, "Surface area = {:.3f} [m2]".format(ThisSurf.Area))
                    ShowContinueError(state, "Occurs in {} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                    ShowContinueError(state, "Radiation intensity = {:.2f} [W/m2]".format(ThisSurfIntensity))
                    ShowContinueError(state, "Assign a larger surface area or more surfaces in {}".format(cCMO_CoolingPanel_Simple))
                    ShowFatalError(state, "DistributeCoolingPanelRadGains:  excessive thermal radiation heat flux intensity detected")
            else:
                ShowSevereError(state, "DistributeCoolingPanelRadGains:  surface not large enough to receive thermal radiation heat flux")
                ShowContinueError(state, "Surface = {}".format(ThisSurf.Name))
                ShowContinueError(state, "Surface area = {:.3f} [m2]".format(ThisSurf.Area))
                ShowContinueError(state, "Occurs in {} = {}".format(cCMO_CoolingPanel_Simple, thisCP.Name))
                ShowContinueError(state, "Assign a larger surface area or more surfaces in {}".format(cCMO_CoolingPanel_Simple))
                ShowFatalError(state, "DistributeCoolingPanelRadGains:  surface not large enough to receive thermal radiation heat flux")

def CoolingPanelParams.ReportCoolingPanel(inout self, state: EnergyPlusData):
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    self.TotPower = -self.TotPower
    self.Power = -self.Power
    self.ConvPower = -self.ConvPower
    self.RadPower = -self.RadPower
    self.TotEnergy = self.TotPower * TimeStepSysSec
    self.Energy = self.Power * TimeStepSysSec
    self.ConvEnergy = self.ConvPower * TimeStepSysSec
    self.RadEnergy = self.RadPower * TimeStepSysSec

# Global constant
var cCMO_CoolingPanel_Simple: String = "ZoneHVAC:CoolingPanel:RadiantConvective:Water"

# Struct ChilledCeilingPanelSimpleData
struct ChilledCeilingPanelSimpleData: BaseGlobalStruct:
    var GetInputFlag: Bool = True
    var CoolingPanel: Array1D[CoolingPanelParams]

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.__init__()
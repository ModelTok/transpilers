# Mojo translation of Humidifiers.cc and Humidifiers.hh
# 1:1 faithful translation, no refactoring.

from .Data.BaseData import BaseGlobalStruct
from .Data.EnergyPlusData import EnergyPlusData
from DataGlobals import *
from  import *
from .InputProcessing.InputProcessor import InputProcessor, ErrorObjectHeader
from BranchNodeConnections import TestCompSet
from CurveManager import GetCurveIndex, CheckCurveDims, CurveValue
from DataContaminantBalance import Contaminant
from DataEnvironment import OutBaroPress, OutDryBulbTemp, OutHumRat, WaterMainsTemp
from DataHVACGlobals import DoSetPointTest, SetPointErrorFlag, TimeStepSysSec, SmallMassFlow, CtrlVarType, AirDuctType
from DataIPShortCuts import *
from DataLoopNode import Node, SensedNodeFlagValue, GetOnlySingleNode, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
from DataSizing import AutoSize, CurZoneEqNum, CurSysNum, CurOASysNum, CurDuctType, FinalZoneSizing, FinalSysSizing, AutoVsHardSizingThreshold, ZoneSizingRunDone, SysSizingRunDone
from DataWater import WaterStorage
from EMSManager import CheckIfNodeSetPointManagedByEMS
from FluidProperties import GetWater, GetSteam
from General import ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowMessage
from GeneralRoutines import CheckZoneSizing, CheckSysSizing
from GlobalNames import VerifyUniqueInterObjectName
from NodeInputManager import *
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat, eResource
from Psychrometrics import PsyRhoAirFnPbTdbW, RhoH2O, PsyWFnTdbRhPb, PsyHFnTdbW, PsyTdbFnHW
from ScheduleManager import Schedule, GetSchedule, GetScheduleAlwaysOn
from UtilityRoutines import *
from WaterManager import SetupTankDemandComponent, SetupTankSupplyComponent
from .Autosizing.Base import BaseSizer
from DataGlobalConstants import Constant
from Fluid import *  # for Fluid namespace

alias HumidifierType = ("Humidifier:Steam:Electric", "Humidifier:Steam:Gas")

enum HumidType:
    Invalid = -1
    Electric = 0
    Gas = 1
    Num = 2

enum InletWaterTemp:
    Invalid = -1
    Fixed = 0
    Variable = 1
    Num = 2

alias inletWaterTempsUC = ("FIXEDINLETWATERTEMPERATURE", "VARIABLEINLETWATERTEMPERATURE")

struct HumidifierData:
    var Name: String = ""                   # unique name of component
    var HumType: HumidType = HumidType.Invalid
    var EquipIndex: Int = 0
    var availSched: Schedule = None         # availability schedule
    var NomCapVol: Float64 = 0.0
    var NomCap: Float64 = 0.0
    var NomPower: Float64 = 0.0
    var ThermalEffRated: Float64 = 1.0
    var CurMakeupWaterTemp: Float64 = 0.0
    var EfficiencyCurvePtr: Int = 0
    var InletWaterTempOption: InletWaterTemp = InletWaterTemp.Invalid
    var FanPower: Float64 = 0.0
    var StandbyPower: Float64 = 0.0
    var AirInNode: Int = 0
    var AirOutNode: Int = 0
    var AirInTemp: Float64 = 0.0
    var AirInHumRat: Float64 = 0.0
    var AirInEnthalpy: Float64 = 0.0
    var AirInMassFlowRate: Float64 = 0.0
    var AirOutTemp: Float64 = 0.0
    var AirOutHumRat: Float64 = 0.0
    var AirOutEnthalpy: Float64 = 0.0
    var AirOutMassFlowRate: Float64 = 0.0
    var HumRatSet: Float64 = 0.0
    var WaterAdd: Float64 = 0.0
    var ElecUseEnergy: Float64 = 0.0
    var ElecUseRate: Float64 = 0.0
    var WaterCons: Float64 = 0.0
    var WaterConsRate: Float64 = 0.0
    var SuppliedByWaterSystem: Bool = False
    var WaterTankID: Int = 0
    var WaterTankDemandARRID: Int = 0
    var TankSupplyVdot: Float64 = 0.0
    var TankSupplyVol: Float64 = 0.0
    var StarvedSupplyVdot: Float64 = 0.0
    var StarvedSupplyVol: Float64 = 0.0
    var TankSupplyID: Int = 0
    var MySizeFlag: Bool = True
    var MyEnvrnFlag: Bool = True
    var MySetPointCheckFlag: Bool = True
    var ThermalEff: Float64 = 0.0
    var GasUseRate: Float64 = 0.0
    var GasUseEnergy: Float64 = 0.0
    var AuxElecUseRate: Float64 = 0.0
    var AuxElecUseEnergy: Float64 = 0.0

    def __init__(inout self):
        self.Name = ""
        self.HumType = HumidType.Invalid
        self.EquipIndex = 0
        self.availSched = None
        self.NomCapVol = 0.0
        self.NomCap = 0.0
        self.NomPower = 0.0
        self.ThermalEffRated = 1.0
        self.CurMakeupWaterTemp = 0.0
        self.EfficiencyCurvePtr = 0
        self.InletWaterTempOption = InletWaterTemp.Invalid
        self.FanPower = 0.0
        self.StandbyPower = 0.0
        self.AirInNode = 0
        self.AirOutNode = 0
        self.AirInTemp = 0.0
        self.AirInHumRat = 0.0
        self.AirInEnthalpy = 0.0
        self.AirInMassFlowRate = 0.0
        self.AirOutTemp = 0.0
        self.AirOutHumRat = 0.0
        self.AirOutEnthalpy = 0.0
        self.AirOutMassFlowRate = 0.0
        self.HumRatSet = 0.0
        self.WaterAdd = 0.0
        self.ElecUseEnergy = 0.0
        self.ElecUseRate = 0.0
        self.WaterCons = 0.0
        self.WaterConsRate = 0.0
        self.SuppliedByWaterSystem = False
        self.WaterTankID = 0
        self.WaterTankDemandARRID = 0
        self.TankSupplyVdot = 0.0
        self.TankSupplyVol = 0.0
        self.StarvedSupplyVdot = 0.0
        self.StarvedSupplyVol = 0.0
        self.TankSupplyID = 0
        self.MySizeFlag = True
        self.MyEnvrnFlag = True
        self.MySetPointCheckFlag = True
        self.ThermalEff = 0.0
        self.GasUseRate = 0.0
        self.GasUseEnergy = 0.0
        self.AuxElecUseRate = 0.0
        self.AuxElecUseEnergy = 0.0

    def InitHumidifier(inout self, inout state: EnergyPlusData):
        using EMSManager.CheckIfNodeSetPointManagedByEMS = CheckIfNodeSetPointManagedByEMS
        if self.MySizeFlag:
            self.SizeHumidifier(state)
            self.MySizeFlag = False
        if not state.dataGlobal.SysSizingCalc and self.MySetPointCheckFlag and state.dataHVACGlobal.DoSetPointTest:
            if self.AirOutNode > 0:
                if state.dataLoopNodes.Node[self.AirOutNode - 1].HumRatMin == SensedNodeFlagValue:
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        ShowSevereError(state,
                            "Humidifiers: Missing humidity setpoint for {} = {}".format(
                                String(HumidifierType[Int(self.HumType)]), self.Name))
                        ShowContinueError(state,
                            "  use a Setpoint Manager with Control Variable = \"MinimumHumidityRatio\" to establish a setpoint at the humidifier outlet node.")
                        ShowContinueError(state, "  expecting it on Node=\"{}\".".format(state.dataLoopNodes.NodeID[self.AirOutNode - 1]))
                        state.dataHVACGlobal.SetPointErrorFlag = True
                    else:
                        CheckIfNodeSetPointManagedByEMS(state, self.AirOutNode, HVAC.CtrlVarType.MinHumRat, state.dataHVACGlobal.SetPointErrorFlag)
                        if state.dataHVACGlobal.SetPointErrorFlag:
                            ShowSevereError(state,
                                "Humidifiers: Missing humidity setpoint for {} = {}".format(
                                    String(HumidifierType[Int(self.HumType)]), self.Name))
                            ShowContinueError(state,
                                "  use a Setpoint Manager with Control Variable = \"MinimumHumidityRatio\" to establish a setpoint at the humidifier outlet node.")
                            ShowContinueError(state, "  expecting it on Node=\"{}\".".format(state.dataLoopNodes.NodeID[self.AirOutNode - 1]))
                            ShowContinueError(state,
                                "  or use an EMS actuator to control minimum humidity ratio to establish a setpoint at the humidifier outlet node.")
            self.MySetPointCheckFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        self.HumRatSet = state.dataLoopNodes.Node[self.AirOutNode - 1].HumRatMin
        self.AirInTemp = state.dataLoopNodes.Node[self.AirInNode - 1].Temp
        self.AirInHumRat = state.dataLoopNodes.Node[self.AirInNode - 1].HumRat
        self.AirInEnthalpy = state.dataLoopNodes.Node[self.AirInNode - 1].Enthalpy
        self.AirInMassFlowRate = state.dataLoopNodes.Node[self.AirInNode - 1].MassFlowRate
        self.WaterAdd = 0.0
        self.ElecUseEnergy = 0.0
        self.ElecUseRate = 0.0
        self.WaterCons = 0.0
        self.WaterConsRate = 0.0
        self.ThermalEff = 0.0
        self.GasUseRate = 0.0
        self.GasUseEnergy = 0.0
        self.AuxElecUseRate = 0.0
        self.AuxElecUseEnergy = 0.0

    def SizeHumidifier(inout self, inout state: EnergyPlusData):
        using DataSizing.AutoSize = AutoSize
        using Psychrometrics.PsyRhoAirFnPbTdbW = PsyRhoAirFnPbTdbW
        using Psychrometrics.RhoH2O = RhoH2O
        alias CalledFrom = "Humidifier:SizeHumidifier"
        alias Tref = 20.0   # Reference temp of water for rated capacity calcs [C]
        alias TSteam = 100.0 # saturated steam temperature generated by Humidifier [C]
        var NominalPower: Float64 = 0.0
        var WaterSpecHeatAvg: Float64 = 0.0
        var SteamSatEnthalpy: Float64 = 0.0
        var WaterSatEnthalpy: Float64 = 0.0
        var ErrorsFound: Bool = False
        var NomPowerDes: Float64 = 0.0
        var NomPowerUser: Float64 = 0.0
        var NomCapVolDes: Float64 = 0.0
        var NomCapVolUser: Float64 = 0.0
        var AirVolFlow: Float64 = 0.0
        var AirDensity: Float64 = 0.0
        var MassFlowDes: Float64 = 0.0
        var InletHumRatDes: Float64 = 0.0
        var OutletHumRatDes: Float64 = 0.0
        if self.HumType == HumidType.Electric or self.HumType == HumidType.Gas:
            var IsAutoSize: Bool = False
            var HardSizeNoDesRun: Bool = False
            NomPowerDes = 0.0
            NomPowerUser = 0.0
            var ModuleObjectType: String = ""
            if self.HumType == HumidType.Electric:
                ModuleObjectType = "electric"
            elif self.HumType == HumidType.Gas:
                ModuleObjectType = "gas"
            if self.NomCapVol == AutoSize:
                IsAutoSize = True
            if state.dataSize.CurZoneEqNum > 0:
                if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
                    HardSizeNoDesRun = True
                    if self.NomCapVol > 0.0:
                        BaseSizer.reportSizerOutput(state,
                            String(HumidifierType[Int(self.HumType)]), self.Name,
                            "User-Specified Nominal Capacity Volume [m3/s]", self.NomCapVol)
                else:
                    CheckZoneSizing(state, "Humidifier:SizeHumidifier", self.Name)
                    AirDensity = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolDens
                    MassFlowDes = max(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow,
                                      state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow) * AirDensity
                    InletHumRatDes = min(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].OutHumRatAtHeatPeak,
                                         state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].OutHumRatAtCoolPeak)
                    OutletHumRatDes = max(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneHumRatAtHeatPeak,
                                          state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneHumRatAtCoolPeak)
            elif state.dataSize.CurSysNum > 0:
                if not IsAutoSize and not state.dataSize.SysSizingRunDone:
                    HardSizeNoDesRun = True
                    if self.NomCapVol > 0.0:
                        BaseSizer.reportSizerOutput(state,
                            String(HumidifierType[Int(self.HumType)]), self.Name,
                            "User-Specified Nominal Capacity Volume [m3/s]", self.NomCapVol)
                else:
                    CheckSysSizing(state, "Humidifier:SizeHumidifier", self.Name)
                    var thisFinalSysSizing = state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1]
                    if state.dataSize.CurOASysNum > 0 and thisFinalSysSizing.DesOutAirVolFlow > 0.0:
                        AirDensity = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutHumRat, CalledFrom)
                        MassFlowDes = thisFinalSysSizing.DesOutAirVolFlow * AirDensity
                        InletHumRatDes = min(thisFinalSysSizing.OutHumRatAtCoolPeak, thisFinalSysSizing.HeatOutHumRat)
                        OutletHumRatDes = max(thisFinalSysSizing.CoolSupHumRat, thisFinalSysSizing.HeatSupHumRat)
                    else:
                        switch state.dataSize.CurDuctType:
                            case HVAC.AirDuctType.Cooling:
                                AirVolFlow = thisFinalSysSizing.DesCoolVolFlow
                            case HVAC.AirDuctType.Heating:
                                AirVolFlow = thisFinalSysSizing.DesHeatVolFlow
                            case _:
                                AirVolFlow = thisFinalSysSizing.DesMainVolFlow
                        AirDensity = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress,
                                                       thisFinalSysSizing.MixTempAtCoolPeak,
                                                       thisFinalSysSizing.MixHumRatAtCoolPeak,
                                                       CalledFrom)
                        MassFlowDes = AirVolFlow * AirDensity
                        InletHumRatDes = min(thisFinalSysSizing.MixHumRatAtCoolPeak, thisFinalSysSizing.HeatMixHumRat)
                        OutletHumRatDes = max(thisFinalSysSizing.CoolSupHumRat, thisFinalSysSizing.HeatSupHumRat)
            if not HardSizeNoDesRun:
                NomCapVolDes = MassFlowDes * (OutletHumRatDes - InletHumRatDes) / RhoH2O(Constant.InitConvTemp)
                if NomCapVolDes < 0.0:
                    NomCapVolDes = 0.0
                if IsAutoSize:
                    self.NomCapVol = NomCapVolDes
                    BaseSizer.reportSizerOutput(state,
                        String(HumidifierType[Int(self.HumType)]), self.Name,
                        "Design Size Nominal Capacity Volume [m3/s]", NomCapVolDes)
                else:
                    if self.NomCapVol > 0.0:
                        NomCapVolUser = self.NomCapVol
                        BaseSizer.reportSizerOutput(state,
                            String(HumidifierType[Int(self.HumType)]), self.Name,
                            "Design Size Nominal Capacity Volume [m3/s]", NomCapVolDes,
                            "User-Specified Nominal Capacity Volume [m3/s]", NomCapVolUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(NomCapVolDes - NomCapVolUser) / NomCapVolUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state,
                                    "SizeHumidifier: Potential issue with equipment sizing for {} = \"{}\".".format(
                                        String(HumidifierType[Int(self.HumType)]), self.Name))
                                ShowContinueError(state, "User-Specified Nominal Capacity Volume of {:#G} [m3/s]".format(NomCapVolUser))
                                ShowContinueError(state, "differs from Design Size Nominal Capacity Volume of {:#G} [m3/s]".format(NomCapVolDes))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
            self.NomCap = RhoH2O(Constant.InitConvTemp) * self.NomCapVol
            var water = GetWater(state)
            var steam = GetSteam(state)
            SteamSatEnthalpy = steam.getSatEnthalpy(state, TSteam, 1.0, CalledFrom)
            WaterSatEnthalpy = steam.getSatEnthalpy(state, TSteam, 0.0, CalledFrom)
            WaterSpecHeatAvg = 0.5 * (water.getSpecificHeat(state, TSteam, CalledFrom) + water.getSpecificHeat(state, Tref, CalledFrom))
            NominalPower = self.NomCap * ((SteamSatEnthalpy - WaterSatEnthalpy) + WaterSpecHeatAvg * (TSteam - Tref))
            if self.NomPower == AutoSize:
                IsAutoSize = True
            if self.HumType == HumidType.Gas:
                if not IsAutoSize:
                    if self.NomPower >= NominalPower:
                        self.ThermalEffRated = NominalPower / self.NomPower
                    else:
                        ShowMessage(state,
                            "{}: capacity and thermal efficiency mismatch for {} =\"{}\".".format(
                                CalledFrom, String(HumidifierType[Int(self.HumType)]), self.Name))
                        ShowContinueError(state, "User-Specified Rated Gas Use Rate of {:#G} [W]".format(self.NomPower))
                        ShowContinueError(state, "User-Specified or Autosized Rated Capacity of {:#G} [m3/s]".format(self.NomCapVol))
                        ShowContinueError(state,
                            "Rated Gas Use Rate at the Rated Capacity of {:#G} [m3/s] must be greater than the ideal, i.e., 100% thermal efficiency gas use rate of {:#G} [W]".format(self.NomCapVol, NomPowerDes))
                        ShowContinueError(state,
                            "Resize the Rated Gas Use Rate by dividing the ideal gas use rate with expected thermal efficiency. ")
                        self.ThermalEffRated = 1.0
                else:
                    if self.ThermalEffRated > 0.0:
                        NominalPower = NominalPower / self.ThermalEffRated
                IsAutoSize = True
            NomPowerDes = NominalPower
            if IsAutoSize:
                self.NomPower = NomPowerDes
                BaseSizer.reportSizerOutput(state,
                    String(HumidifierType[Int(self.HumType)]), self.Name, "Design Size Rated Power [W]", NomPowerDes)
            else:
                if self.NomPower >= 0.0 and self.NomCap > 0.0:
                    NomPowerUser = self.NomPower
                    BaseSizer.reportSizerOutput(state,
                        String(HumidifierType[Int(self.HumType)]), self.Name,
                        "Design Size Rated Power [W]", NomPowerDes,
                        "User-Specified Rated Power [W]", NomPowerUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (abs(NomPowerDes - NomPowerUser) / NomPowerUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state,
                                "SizeHumidifier: Potential issue with equipment sizing for {} =\"{}\".".format(
                                    String(HumidifierType[Int(self.HumType)]), self.Name))
                            ShowContinueError(state, "User-Specified Rated Power of {:#G} [W]".format(NomPowerUser))
                            ShowContinueError(state, "differs from Design Size Rated Power of {:#G} [W]".format(NomPowerDes))
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                    if self.NomPower < NominalPower:
                        ShowWarningError(state,
                            String(HumidifierType[Int(self.HumType)]) + ": specified Rated Power is less than nominal Rated Power for " + ModuleObjectType + " steam humidifier = " + self.Name + ". ")
                        ShowContinueError(state, " specified Rated Power = {:#G}".format(self.NomPower))
                        ShowContinueError(state, " while expecting a minimum Rated Power = {:#G}".format(NominalPower))
                else:
                    ShowWarningError(state,
                        String(HumidifierType[Int(self.HumType)]) + ": specified nominal capacity is zero for " + ModuleObjectType + " steam humidifier = " + self.Name + ". ")
                    ShowContinueError(state, " For zero nominal capacity humidifier the rated power is zero.")
        if ErrorsFound:
            ShowFatalError(state,
                "{}: Mismatch was found in the Rated Gas Use Rate and Thermal Efficiency for gas fired steam humidifier = {}. ".format(CalledFrom, self.Name))

    def ControlHumidifier(inout self, inout state: EnergyPlusData, inout WaterAddNeeded: Float64):
        using Psychrometrics.PsyWFnTdbRhPb = PsyWFnTdbRhPb
        alias RoutineName = "ControlHumidifier"
        var UnitOn: Bool = True
        var HumRatSatIn: Float64 = 0.0
        if self.HumRatSet <= 0.0:
            UnitOn = False
        if self.AirInMassFlowRate <= SmallMassFlow:
            UnitOn = False
        if self.availSched.getCurrentVal() <= 0.0:
            UnitOn = False
        if self.AirInHumRat >= self.HumRatSet:
            UnitOn = False
        HumRatSatIn = PsyWFnTdbRhPb(state, self.AirInTemp, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
        if self.AirInHumRat >= HumRatSatIn:
            UnitOn = False
        if UnitOn:
            WaterAddNeeded = self.AirInMassFlowRate * (self.HumRatSet - self.AirInHumRat)
        else:
            WaterAddNeeded = 0.0

    def CalcElecSteamHumidifier(inout self, inout state: EnergyPlusData, WaterAddNeeded: Float64):
        using Psychrometrics.PsyHFnTdbW = PsyHFnTdbW
        using Psychrometrics.PsyTdbFnHW = PsyTdbFnHW
        using Psychrometrics.PsyWFnTdbRhPb = PsyWFnTdbRhPb
        using Psychrometrics.RhoH2O = RhoH2O
        alias RoutineName = "CalcElecSteamHumidifier"
        var HumRatSatOut: Float64 = 0.0
        var HumRatSatIn: Float64 = 0.0
        var WaterAddNeededMax: Float64 = 0.0
        var WaterInEnthalpy: Float64 = 0.0
        var HumRatSatApp: Float64 = 0.0
        var WaterDens: Float64 = 0.0
        HumRatSatIn = PsyWFnTdbRhPb(state, self.AirInTemp, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
        HumRatSatOut = 0.0
        HumRatSatApp = 0.0
        WaterInEnthalpy = 2676125.0  # At 100 C
        WaterDens = RhoH2O(Constant.InitConvTemp)
        WaterAddNeededMax = min(WaterAddNeeded, self.NomCap)
        if WaterAddNeededMax > 0.0:
            self.AirOutEnthalpy = (self.AirInMassFlowRate * self.AirInEnthalpy + WaterAddNeededMax * WaterInEnthalpy) / self.AirInMassFlowRate
            self.AirOutHumRat = (self.AirInMassFlowRate * self.AirInHumRat + WaterAddNeededMax) / self.AirInMassFlowRate
            self.AirOutTemp = PsyTdbFnHW(self.AirOutEnthalpy, self.AirOutHumRat)
            HumRatSatOut = PsyWFnTdbRhPb(state, self.AirOutTemp, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
            if self.AirOutHumRat <= HumRatSatOut:
                self.WaterAdd = WaterAddNeededMax
            else:
                HumRatSatApp = self.AirInHumRat + (self.AirOutHumRat - self.AirInHumRat) * (HumRatSatIn - self.AirInHumRat) / (self.AirOutHumRat - HumRatSatOut + HumRatSatIn - self.AirInHumRat)
                self.AirOutTemp = self.AirInTemp + (HumRatSatApp - self.AirInHumRat) * ((self.AirOutTemp - self.AirInTemp) / (self.AirOutHumRat - self.AirInHumRat))
                self.AirOutHumRat = PsyWFnTdbRhPb(state, self.AirOutTemp, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
                self.AirOutEnthalpy = PsyHFnTdbW(self.AirOutTemp, self.AirOutHumRat)
                self.WaterAdd = self.AirInMassFlowRate * (self.AirOutHumRat - self.AirInHumRat)
        else:
            self.WaterAdd = 0.0
            self.AirOutEnthalpy = self.AirInEnthalpy
            self.AirOutTemp = self.AirInTemp
            self.AirOutHumRat = self.AirInHumRat
        if self.WaterAdd > 0.0:
            self.ElecUseRate = (self.WaterAdd / self.NomCap) * self.NomPower + self.FanPower + self.StandbyPower
        elif self.availSched.getCurrentVal() > 0.0:
            self.ElecUseRate = self.StandbyPower
        else:
            self.ElecUseRate = 0.0
        self.WaterConsRate = self.WaterAdd / WaterDens
        self.AirOutMassFlowRate = self.AirInMassFlowRate

    def CalcGasSteamHumidifier(inout self, inout state: EnergyPlusData, WaterAddNeeded: Float64):
        using Curve.CurveValue = CurveValue
        using Psychrometrics.PsyHFnTdbW = PsyHFnTdbW
        using Psychrometrics.PsyTdbFnHW = PsyTdbFnHW
        using Psychrometrics.PsyWFnTdbRhPb = PsyWFnTdbRhPb
        using Psychrometrics.RhoH2O = RhoH2O
        alias RoutineName = "CalcGasSteamHumidifier"
        alias TSteam = 100.0  # saturated steam temperature generated by Humidifier [C]
        var HumRatSatOut: Float64 = 0.0
        var HumRatSatIn: Float64 = 0.0
        var WaterAddNeededMax: Float64 = 0.0
        var WaterInEnthalpy: Float64 = 0.0
        var HumRatSatApp: Float64 = 0.0
        var WaterDens: Float64 = 0.0
        var ThermEffCurveOutput: Float64 = 0.0
        var PartLoadRatio: Float64 = 0.0
        var GasUseRateAtRatedEff: Float64 = 0.0
        var WaterSpecHeatAvg: Float64 = 0.0
        var SteamSatEnthalpy: Float64 = 0.0
        var WaterSatEnthalpy: Float64 = 0.0
        var Tref: Float64 = 0.0
        HumRatSatIn = PsyWFnTdbRhPb(state, self.AirInTemp, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
        HumRatSatOut = 0.0
        HumRatSatApp = 0.0
        WaterInEnthalpy = 2676125.0  # At 100 C
        WaterDens = RhoH2O(Constant.InitConvTemp)
        WaterAddNeededMax = min(WaterAddNeeded, self.NomCap)
        if WaterAddNeededMax > 0.0:
            self.AirOutEnthalpy = (self.AirInMassFlowRate * self.AirInEnthalpy + WaterAddNeededMax * WaterInEnthalpy) / self.AirInMassFlowRate
            self.AirOutHumRat = (self.AirInMassFlowRate * self.AirInHumRat + WaterAddNeededMax) / self.AirInMassFlowRate
            self.AirOutTemp = PsyTdbFnHW(self.AirOutEnthalpy, self.AirOutHumRat)
            HumRatSatOut = PsyWFnTdbRhPb(state, self.AirOutTemp, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
            if self.AirOutHumRat <= HumRatSatOut:
                self.WaterAdd = WaterAddNeededMax
            else:
                HumRatSatApp = self.AirInHumRat + (self.AirOutHumRat - self.AirInHumRat) * (HumRatSatIn - self.AirInHumRat) / (self.AirOutHumRat - HumRatSatOut + HumRatSatIn - self.AirInHumRat)
                self.AirOutTemp = self.AirInTemp + (HumRatSatApp - self.AirInHumRat) * ((self.AirOutTemp - self.AirInTemp) / (self.AirOutHumRat - self.AirInHumRat))
                self.AirOutHumRat = PsyWFnTdbRhPb(state, self.AirOutTemp, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
                self.AirOutEnthalpy = PsyHFnTdbW(self.AirOutTemp, self.AirOutHumRat)
                self.WaterAdd = self.AirInMassFlowRate * (self.AirOutHumRat - self.AirInHumRat)
        else:
            self.WaterAdd = 0.0
            self.AirOutEnthalpy = self.AirInEnthalpy
            self.AirOutTemp = self.AirInTemp
            self.AirOutHumRat = self.AirInHumRat
        if self.WaterAdd > 0.0:
            if self.InletWaterTempOption == InletWaterTemp.Fixed:
                GasUseRateAtRatedEff = (self.WaterAdd / self.NomCap) * self.NomPower
            elif self.InletWaterTempOption == InletWaterTemp.Variable:
                if self.SuppliedByWaterSystem:
                    self.CurMakeupWaterTemp = state.dataWaterData.WaterStorage[self.WaterTankID - 1].TwaterSupply[self.TankSupplyID - 1]
                else:
                    self.CurMakeupWaterTemp = state.dataEnvrn.WaterMainsTemp
                Tref = self.CurMakeupWaterTemp
                var water = GetWater(state)
                var steam = GetSteam(state)
                SteamSatEnthalpy = steam.getSatEnthalpy(state, TSteam, 1.0, RoutineName)
                WaterSatEnthalpy = steam.getSatEnthalpy(state, TSteam, 0.0, RoutineName)
                WaterSpecHeatAvg = 0.5 * (water.getSpecificHeat(state, TSteam, RoutineName) + water.getSpecificHeat(state, Tref, RoutineName))
                GasUseRateAtRatedEff = self.WaterAdd * ((SteamSatEnthalpy - WaterSatEnthalpy) + WaterSpecHeatAvg * (TSteam - Tref)) / self.ThermalEffRated
            PartLoadRatio = GasUseRateAtRatedEff / self.NomPower
            if self.EfficiencyCurvePtr > 0:
                ThermEffCurveOutput = CurveValue(state, self.EfficiencyCurvePtr, PartLoadRatio)
            else:
                ThermEffCurveOutput = 1.0
            self.ThermalEff = self.ThermalEffRated * ThermEffCurveOutput
            if ThermEffCurveOutput != 0.0:
                self.GasUseRate = GasUseRateAtRatedEff / ThermEffCurveOutput
            self.AuxElecUseRate = self.FanPower + self.StandbyPower
        elif self.availSched.getCurrentVal() > 0.0:
            self.AuxElecUseRate = self.StandbyPower
        else:
            self.AuxElecUseRate = 0.0
        self.WaterConsRate = self.WaterAdd / WaterDens
        self.AirOutMassFlowRate = self.AirInMassFlowRate

    def UpdateReportWaterSystem(inout self, inout state: EnergyPlusData):
        var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
        var AvailTankVdot: Float64 = 0.0
        var StarvedVdot: Float64 = 0.0
        if self.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.WaterTankID - 1].VdotRequestDemand[self.WaterTankDemandARRID - 1] = self.WaterConsRate
            AvailTankVdot = state.dataWaterData.WaterStorage[self.WaterTankID - 1].VdotAvailDemand[self.WaterTankDemandARRID - 1]
            StarvedVdot = 0.0
            self.TankSupplyVdot = self.WaterConsRate
            if (AvailTankVdot < self.WaterConsRate) and (not state.dataGlobal.BeginTimeStepFlag):
                StarvedVdot = self.WaterConsRate - AvailTankVdot
                self.TankSupplyVdot = AvailTankVdot
            self.TankSupplyVol = self.TankSupplyVdot * TimeStepSysSec
            self.StarvedSupplyVdot = StarvedVdot
            self.StarvedSupplyVol = StarvedVdot * TimeStepSysSec

    def UpdateHumidifier(inout self, inout state: EnergyPlusData):
        state.dataLoopNodes.Node[self.AirOutNode - 1].MassFlowRate = self.AirOutMassFlowRate
        state.dataLoopNodes.Node[self.AirOutNode - 1].Temp = self.AirOutTemp
        state.dataLoopNodes.Node[self.AirOutNode - 1].HumRat = self.AirOutHumRat
        state.dataLoopNodes.Node[self.AirOutNode - 1].Enthalpy = self.AirOutEnthalpy
        state.dataLoopNodes.Node[self.AirOutNode - 1].Quality = state.dataLoopNodes.Node[self.AirInNode - 1].Quality
        state.dataLoopNodes.Node[self.AirOutNode - 1].Press = state.dataLoopNodes.Node[self.AirInNode - 1].Press
        state.dataLoopNodes.Node[self.AirOutNode - 1].MassFlowRateMin = state.dataLoopNodes.Node[self.AirInNode - 1].MassFlowRateMin
        state.dataLoopNodes.Node[self.AirOutNode - 1].MassFlowRateMax = state.dataLoopNodes.Node[self.AirInNode - 1].MassFlowRateMax
        state.dataLoopNodes.Node[self.AirOutNode - 1].MassFlowRateMinAvail = state.dataLoopNodes.Node[self.AirInNode - 1].MassFlowRateMinAvail
        state.dataLoopNodes.Node[self.AirOutNode - 1].MassFlowRateMaxAvail = state.dataLoopNodes.Node[self.AirInNode - 1].MassFlowRateMaxAvail
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            state.dataLoopNodes.Node[self.AirOutNode - 1].CO2 = state.dataLoopNodes.Node[self.AirInNode - 1].CO2
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            state.dataLoopNodes.Node[self.AirOutNode - 1].GenContam = state.dataLoopNodes.Node[self.AirInNode - 1].GenContam

    def ReportHumidifier(inout self, inout state: EnergyPlusData):
        var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
        self.ElecUseEnergy = self.ElecUseRate * TimeStepSysSec
        self.WaterCons = self.WaterConsRate * TimeStepSysSec
        self.GasUseEnergy = self.GasUseRate * TimeStepSysSec
        self.AuxElecUseEnergy = self.AuxElecUseRate * TimeStepSysSec

struct HumidifiersData:
    var NumHumidifiers: Int = 0
    var NumElecSteamHums: Int = 0
    var NumGasSteamHums: Int = 0
    var CheckEquipName: DynamicVector[Bool] = DynamicVector[Bool]()
    var GetInputFlag: Bool = True
    var Humidifier: DynamicVector[HumidifierData] = DynamicVector[HumidifierData]()
    var HumidifierUniqueNames: Dict[String, String] = Dict[String, String]()

    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):
        self.NumHumidifiers = 0
        self.NumElecSteamHums = 0
        self.NumGasSteamHums = 0
        self.CheckEquipName.clear()
        self.GetInputFlag = True
        self.Humidifier.clear()
        self.HumidifierUniqueNames.clear()

def SimHumidifier(inout state: EnergyPlusData, CompName: StringLiteral, FirstHVACIteration: Bool, inout CompIndex: Int):
    var HumNum: Int = 0
    var WaterAddNeeded: Float64 = 0.0
    if state.dataHumidifiers.GetInputFlag:
        GetHumidifierInput(state)
        state.dataHumidifiers.GetInputFlag = False
    if CompIndex == 0:
        HumNum = Util.FindItemInList(CompName, state.dataHumidifiers.Humidifier)
        if HumNum == 0:
            ShowFatalError(state, "SimHumidifier: Unit not found={}".format(CompName))
        CompIndex = HumNum
    else:
        HumNum = CompIndex
        if HumNum > state.dataHumidifiers.NumHumidifiers or HumNum < 1:
            ShowFatalError(state,
                "SimHumidifier: Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}".format(
                    HumNum, state.dataHumidifiers.NumHumidifiers, CompName))
        if state.dataHumidifiers.CheckEquipName[HumNum - 1]:
            if CompName != state.dataHumidifiers.Humidifier[HumNum - 1].Name:
                ShowFatalError(state,
                    "SimHumidifier: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}".format(
                        HumNum, CompName, state.dataHumidifiers.Humidifier[HumNum - 1].Name))
            state.dataHumidifiers.CheckEquipName[HumNum - 1] = False
    if HumNum <= 0:
        ShowFatalError(state, "SimHumidifier: Unit not found={}".format(CompName))
    var thisHum = state.dataHumidifiers.Humidifier[HumNum - 1]
    thisHum.InitHumidifier(state)
    thisHum.ControlHumidifier(state, WaterAddNeeded)
    switch thisHum.HumType:
        case HumidType.Electric:
            thisHum.CalcElecSteamHumidifier(state, WaterAddNeeded)
        case HumidType.Gas:
            thisHum.CalcGasSteamHumidifier(state, WaterAddNeeded)
        case _:
            ShowSevereError(state, "SimHumidifier: Invalid Humidifier Type Code={}".format(Int(thisHum.HumType)))
            ShowContinueError(state, "...Component Name=[{}].".format(CompName))
            ShowFatalError(state, "Preceding Condition causes termination.")
    thisHum.UpdateReportWaterSystem(state)
    thisHum.UpdateHumidifier(state)
    thisHum.ReportHumidifier(state)

def GetHumidifierInput(inout state: EnergyPlusData):
    using Curve.GetCurveIndex = GetCurveIndex
    using Node.GetOnlySingleNode = GetOnlySingleNode
    using Node.TestCompSet = TestCompSet
    using WaterManager.SetupTankDemandComponent = SetupTankDemandComponent
    using WaterManager.SetupTankSupplyComponent = SetupTankSupplyComponent
    alias RoutineName = "GetHumidifierInputs: "
    alias routineName = "GetHumidifierInputs"
    var HumidifierIndex: Int = 0
    var HumNum: Int = 0
    var NumAlphas: Int = 0
    var NumNumbers: Int = 0
    var MaxNums: Int = 0
    var MaxAlphas: Int = 0
    var IOStatus: Int = 0
    var ErrorsFound: Bool = False
    var CurrentModuleObject: String = ""
    var Alphas: DynamicVector[String] = DynamicVector[String]()
    var cAlphaFields: DynamicVector[String] = DynamicVector[String]()
    var cNumericFields: DynamicVector[String] = DynamicVector[String]()
    var Numbers: DynamicVector[Float64] = DynamicVector[Float64]()
    var lAlphaBlanks: DynamicVector[Bool] = DynamicVector[Bool]()
    var lNumericBlanks: DynamicVector[Bool] = DynamicVector[Bool]()
    var TotalArgs: Int = 0
    CurrentModuleObject = "Humidifier:Steam:Electric"
    var NumElecSteamHums = state.dataHumidifiers.NumElecSteamHums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, TotalArgs, NumAlphas, NumNumbers)
    MaxNums = NumNumbers
    MaxAlphas = NumAlphas
    CurrentModuleObject = "Humidifier:Steam:Gas"
    var NumGasSteamHums = state.dataHumidifiers.NumGasSteamHums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    var NumHumidifiers = state.dataHumidifiers.NumHumidifiers = NumElecSteamHums + NumGasSteamHums
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, TotalArgs, NumAlphas, NumNumbers)
    MaxNums = max(MaxNums, NumNumbers)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    state.dataHumidifiers.Humidifier.resize(NumHumidifiers)
    state.dataHumidifiers.HumidifierUniqueNames.reserve(NumHumidifiers)
    state.dataHumidifiers.CheckEquipName = DynamicVector[Bool](NumHumidifiers, True)
    Alphas = DynamicVector[String](MaxAlphas)
    cAlphaFields = DynamicVector[String](MaxAlphas)
    cNumericFields = DynamicVector[String](MaxNums)
    Numbers = DynamicVector[Float64](MaxNums, 0.0)
    lAlphaBlanks = DynamicVector[Bool](MaxAlphas, True)
    lNumericBlanks = DynamicVector[Bool](MaxAlphas, True)
    CurrentModuleObject = "Humidifier:Steam:Electric"
    for HumidifierIndex in range(1, NumElecSteamHums + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, HumidifierIndex, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        HumNum = HumidifierIndex
        var Humidifier = state.dataHumidifiers.Humidifier[HumNum - 1]
        VerifyUniqueInterObjectName(state, state.dataHumidifiers.HumidifierUniqueNames, Alphas[0], CurrentModuleObject, cAlphaFields[0], ErrorsFound)
        Humidifier.Name = Alphas[0]
        Humidifier.HumType = HumidType.Electric
        if lAlphaBlanks[1]:
            Humidifier.availSched = GetScheduleAlwaysOn(state)
        else:
            var sched = GetSchedule(state, Alphas[1])
            if sched == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                ErrorsFound = True
            else:
                Humidifier.availSched = sched
        Humidifier.NomCapVol = Numbers[0]
        Humidifier.NomPower = Numbers[1]
        Humidifier.FanPower = Numbers[2]
        Humidifier.StandbyPower = Numbers[3]
        Humidifier.AirInNode = GetOnlySingleNode(state,
            Alphas[2], ErrorsFound,
            Node.ConnectionObjectType.HumidifierSteamElectric,
            Alphas[0],
            Node.FluidType.Air,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        Humidifier.AirOutNode = GetOnlySingleNode(state,
            Alphas[3], ErrorsFound,
            Node.ConnectionObjectType.HumidifierSteamElectric,
            Alphas[0],
            Node.FluidType.Air,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[2], Alphas[3], "Air Nodes")
        if lAlphaBlanks[4]:
            Humidifier.SuppliedByWaterSystem = False
        else:
            SetupTankDemandComponent(state, Alphas[0], CurrentModuleObject, Alphas[4], ErrorsFound, Humidifier.WaterTankID, Humidifier.WaterTankDemandARRID)
            Humidifier.SuppliedByWaterSystem = True
    CurrentModuleObject = "Humidifier:Steam:Gas"
    for HumidifierIndex in range(1, NumGasSteamHums + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, HumidifierIndex, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[0])
        HumNum = NumElecSteamHums + HumidifierIndex
        var Humidifier = state.dataHumidifiers.Humidifier[HumNum - 1]
        VerifyUniqueInterObjectName(state, state.dataHumidifiers.HumidifierUniqueNames, Alphas[0], CurrentModuleObject, cAlphaFields[0], ErrorsFound)
        Humidifier.Name = Alphas[0]
        Humidifier.HumType = HumidType.Gas
        if lAlphaBlanks[1]:
            Humidifier.availSched = GetScheduleAlwaysOn(state)
        else:
            var sched = GetSchedule(state, Alphas[1])
            if sched == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                ErrorsFound = True
            else:
                Humidifier.availSched = sched
        Humidifier.NomCapVol = Numbers[0]
        Humidifier.NomPower = Numbers[1]
        Humidifier.ThermalEffRated = Numbers[2]
        Humidifier.FanPower = Numbers[3]
        Humidifier.StandbyPower = Numbers[4]
        Humidifier.AirInNode = GetOnlySingleNode(state,
            Alphas[3], ErrorsFound,
            Node.ConnectionObjectType.HumidifierSteamGas,
            Alphas[0],
            Node.FluidType.Air,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        Humidifier.AirOutNode = GetOnlySingleNode(state,
            Alphas[4], ErrorsFound,
            Node.ConnectionObjectType.HumidifierSteamGas,
            Alphas[0],
            Node.FluidType.Air,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[3], Alphas[4], "Air Nodes")
        Humidifier.EfficiencyCurvePtr = GetCurveIndex(state, Alphas[2])
        if Humidifier.EfficiencyCurvePtr > 0:
            ErrorsFound = ErrorsFound or CheckCurveDims(state, Humidifier.EfficiencyCurvePtr, {1}, RoutineName, CurrentModuleObject, Humidifier.Name, cAlphaFields[2])
        elif not lAlphaBlanks[2]:
            ShowSevereError(state, "{}=\"{}\",".format(RoutineName, CurrentModuleObject, Alphas[0]))
            ShowContinueError(state, "Invalid {}={}".format(cAlphaFields[2], Alphas[2]))
            ShowContinueError(state, "...{} not found.".format(cAlphaFields[2]))
            ErrorsFound = True
        if lAlphaBlanks[5]:
            Humidifier.SuppliedByWaterSystem = False
        else:
            SetupTankDemandComponent(state, Alphas[0], CurrentModuleObject, Alphas[5], ErrorsFound, Humidifier.WaterTankID, Humidifier.WaterTankDemandARRID)
            SetupTankSupplyComponent(state, Alphas[0], CurrentModuleObject, Alphas[5], ErrorsFound, Humidifier.WaterTankID, Humidifier.TankSupplyID)
            Humidifier.SuppliedByWaterSystem = True
        if lAlphaBlanks[6]:
            Humidifier.InletWaterTempOption = InletWaterTemp.Fixed
        else:
            Humidifier.InletWaterTempOption = InletWaterTemp(getEnumValue(inletWaterTempsUC, Alphas[6]))
    for HumNum in range(1, NumHumidifiers + 1):
        var Humidifier = state.dataHumidifiers.Humidifier[HumNum - 1]
        if Humidifier.SuppliedByWaterSystem:
            SetupOutputVariable(state, "Humidifier Water Volume Flow Rate", Constant.Units.m3_s, Humidifier.WaterConsRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier Water Volume", Constant.Units.m3, Humidifier.WaterCons,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier Storage Tank Water Volume Flow Rate", Constant.Units.m3_s, Humidifier.TankSupplyVdot,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier Storage Tank Water Volume", Constant.Units.m3, Humidifier.TankSupplyVol,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.Water, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
            SetupOutputVariable(state, "Humidifier Starved Storage Tank Water Volume Flow Rate", Constant.Units.m3_s, Humidifier.StarvedSupplyVdot,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier Starved Storage Tank Water Volume", Constant.Units.m3, Humidifier.StarvedSupplyVol,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.Water, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
            SetupOutputVariable(state, "Humidifier Mains Water Volume", Constant.Units.m3, Humidifier.StarvedSupplyVol,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.MainsWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
        else:
            SetupOutputVariable(state, "Humidifier Water Volume Flow Rate", Constant.Units.m3_s, Humidifier.WaterConsRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier Water Volume", Constant.Units.m3, Humidifier.WaterCons,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.Water, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
            SetupOutputVariable(state, "Humidifier Mains Water Volume", Constant.Units.m3, Humidifier.WaterCons,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.MainsWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
        if Humidifier.HumType == HumidType.Electric:
            SetupOutputVariable(state, "Humidifier Electricity Rate", Constant.Units.W, Humidifier.ElecUseRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier Electricity Energy", Constant.Units.J, Humidifier.ElecUseEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.Electricity, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
        elif Humidifier.HumType == HumidType.Gas:
            SetupOutputVariable(state, "Humidifier NaturalGas Use Thermal Efficiency", Constant.Units.None, Humidifier.ThermalEff,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier NaturalGas Rate", Constant.Units.W, Humidifier.GasUseRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier NaturalGas Energy", Constant.Units.J, Humidifier.GasUseEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.NaturalGas, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
            SetupOutputVariable(state, "Humidifier Auxiliary Electricity Rate", Constant.Units.W, Humidifier.AuxElecUseRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, Humidifier.Name)
            SetupOutputVariable(state, "Humidifier Auxiliary Electricity Energy", Constant.Units.J, Humidifier.AuxElecUseEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, Humidifier.Name,
                Constant.eResource.Electricity, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Humidification)
    Alphas.clear()
    cAlphaFields.clear()
    cNumericFields.clear()
    Numbers.clear()
    lAlphaBlanks.clear()
    lNumericBlanks.clear()
    if ErrorsFound:
        ShowFatalError(state, "{}Errors found in input.".format(RoutineName))

def GetAirInletNodeNum(inout state: EnergyPlusData, HumidifierName: String, inout ErrorsFound: Bool) -> Int:
    var NodeNum: Int = 0
    var WhichHumidifier: Int
    if state.dataHumidifiers.GetInputFlag:
        GetHumidifierInput(state)
        state.dataHumidifiers.GetInputFlag = False
    WhichHumidifier = Util.FindItemInList(HumidifierName, state.dataHumidifiers.Humidifier)
    if WhichHumidifier != 0:
        NodeNum = state.dataHumidifiers.Humidifier[WhichHumidifier - 1].AirInNode
    else:
        ShowSevereError(state, "GetAirInletNodeNum: Could not find Humidifier = \"{}\"".format(HumidifierName))
        ErrorsFound = True
        NodeNum = 0
    return NodeNum

def GetAirOutletNodeNum(inout state: EnergyPlusData, HumidifierName: String, inout ErrorsFound: Bool) -> Int:
    if state.dataHumidifiers.GetInputFlag:
        GetHumidifierInput(state)
        state.dataHumidifiers.GetInputFlag = False
    var WhichHumidifier = Util.FindItemInList(HumidifierName, state.dataHumidifiers.Humidifier)
    if WhichHumidifier != 0:
        return state.dataHumidifiers.Humidifier[WhichHumidifier - 1].AirOutNode
    ShowSevereError(state, "GetAirInletNodeNum: Could not find Humidifier = \"{}\"".format(HumidifierName))
    ErrorsFound = True
    return 0
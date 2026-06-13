// Mojo translation of src/EnergyPlus/EvaporativeFluidCoolers.cc
// Faithful 1:1 translation, no refactoring.

from Data.BaseData import BaseGlobalStruct, BaseSizer, EnergyPlusData
from DataGlobals import DataPlant, PlantEquipmentType, PlantLocation, PlantComponent
from .Data.EnergyPlusData import EnergyPlusData
from DataBranchAirLoopPlant import MassFlowTolerance
from DataEnvironment import EnvironmentData
from DataHVACGlobals import TimeStepSysSec
from DataIPShortCuts import IPShortCutData
from DataLoopNode import LoopNodeData, Node as NodeMgr  # avoid name collision
from DataSizing import PlantSizingData
from DataWater import WaterStorage
from FluidProperties import GlycolProps
from General import SolveRoot, showWarningError, showFatalError, showSevereError, showContinueError, showContinueErrorTimeStamp, showRecurringWarningErrorAtEnd, showSevereItemNotFound
from GlobalNames import VerifyUniqueInterObjectName
from .InputProcessing.InputProcessor import InputProcessor, getEnumValue
from NodeInputManager import Node  # for GetOnlySingleNode, TestCompSet
from OutAirNodeManager import CheckOutAirNodeNumber
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType, EndUseCat
from OutputReportPredefined import PreDefTableEntry, pdchMechType, pdchMechNomCap, pdchCTFCType, pdchCTFCCondLoopName, pdchCTFCCondLoopBranchName, pdchCTFCFluidType, pdchCTFCRange, pdchCTFCApproach, pdchCTFCLevWaterSPTemp, pdchCTFCDesFanPwr, pdchCTFCDesInletAirWBT, pdchCTFCDesWaterFlowRate
from PlantUtilities import InitComponentNodes, RegulateCondenserCompFlowReqOp, SetComponentFlowRate, RegisterPlantCompDesignFlow, ScanPlantLoopsForObject
from Psychrometrics import PsyRhoAirFnPbTdbW, PsyCpAirFnW, PsyHFnTdbRhPb, PsyWFnTdbTwbPb, PsyTsatFnHPb, PsyWFnTdbH
from ScheduleManager import Schedule as Sched
from UtilityRoutines import SameString, makeUPPER
from WaterManager import SetupTankDemandComponent
from Constant import InitConvTemp, Kelvin, AutoSize, AutoCalculate, SmallWaterVolFlow, Units, Resource, eResource
from DataPlant import PlantEquipTypeNames, LoopDemandCalcScheme, FlowLock, PlantFirstSizesOkayToFinalize, PlantFinalSizesOkayToReport, PlantFirstSizesOkayToReport

from typing import String, List, Dict, Optional
from math import abs, exp, min, max

# Enums
enum EvapLoss(Int):
    Invalid = -1
    ByUserFactor = 0
    ByMoistTheory = 1
    Num = 2

enum Blowdown(Int):
    Invalid = -1
    ByConcentration = 0
    BySchedule = 1
    Num = 2

enum PIM(Int):
    StandardDesignCapacity = 0
    UFactor = 1
    UserSpecifiedDesignCapacity = 2

enum CapacityControl(Int):
    Invalid = -1
    FanCycling = 0
    FluidBypass = 1
    Num = 2

# Structs
struct EvapFluidCoolerInletConds:
    var WaterTemp: Float64 = 0.0
    var AirTemp: Float64 = 0.0
    var AirWetBulb: Float64 = 0.0
    var AirPress: Float64 = 0.0
    var AirHumRat: Float64 = 0.0

# PlantComponent is a trait; we'll define methods here
trait PlantComponent:
    def getSizingFactor(inout self, _sizFac: Float64):
        ...
    def getDesignCapacities(inout self, state: EnergyPlusData, calledFrom: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64):
        ...
    def simulate(inout self, state: EnergyPlusData, calledFrom: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
        ...
    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFrom: PlantLocation):
        ...
    def oneTimeInit(inout self, state: EnergyPlusData):
        ...

struct EvapFluidCoolerSpecs(PlantComponent):
    var Name: String = ""
    var EvapFluidCoolerType: String = ""
    var Type: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
    var PerformanceInputMethod: String = ""
    var PerformanceInputMethod_Num: PIM = PIM.StandardDesignCapacity
    var Available: Bool = True
    var ON: Bool = True
    var DesignWaterFlowRate: Float64 = 0.0
    var DesignSprayWaterFlowRate: Float64 = 0.0
    var DesWaterMassFlowRate: Float64 = 0.0
    var HighSpeedAirFlowRate: Float64 = 0.0
    var HighSpeedFanPower: Float64 = 0.0
    var HighSpeedEvapFluidCoolerUA: Float64 = 0.0
    var LowSpeedAirFlowRate: Float64 = 0.0
    var LowSpeedAirFlowRateSizingFactor: Float64 = 0.0
    var LowSpeedFanPower: Float64 = 0.0
    var LowSpeedFanPowerSizingFactor: Float64 = 0.0
    var LowSpeedEvapFluidCoolerUA: Float64 = 0.0
    var DesignWaterFlowRateWasAutoSized: Bool = False
    var HighSpeedAirFlowRateWasAutoSized: Bool = False
    var HighSpeedFanPowerWasAutoSized: Bool = False
    var HighSpeedEvapFluidCoolerUAWasAutoSized: Bool = False
    var LowSpeedAirFlowRateWasAutoSized: Bool = False
    var LowSpeedFanPowerWasAutoSized: Bool = False
    var LowSpeedEvapFluidCoolerUAWasAutoSized: Bool = False
    var LowSpeedEvapFluidCoolerUASizingFactor: Float64 = 0.0
    var DesignEnteringWaterTemp: Float64 = 0.0
    var DesignEnteringWaterTempWasAutoSized: Bool = False
    var DesignExitWaterTemp: Float64 = -999.0
    var DesignEnteringAirTemp: Float64 = 0.0
    var DesignEnteringAirWetBulbTemp: Float64 = 0.0
    var EvapFluidCoolerMassFlowRateMultiplier: Float64 = 0.0
    var HeatRejectCapNomCapSizingRatio: Float64 = 0.0
    var HighSpeedStandardDesignCapacity: Float64 = 0.0
    var LowSpeedStandardDesignCapacity: Float64 = 0.0
    var HighSpeedUserSpecifiedDesignCapacity: Float64 = 0.0
    var LowSpeedUserSpecifiedDesignCapacity: Float64 = 0.0
    var Concentration: Float64 = 0.0
    var glycol: Optional[GlycolProps] = Optional[GlycolProps]()
    var SizFac: Float64 = 0.0
    var WaterInletNodeNum: Int = 0
    var WaterOutletNodeNum: Int = 0
    var OutdoorAirInletNodeNum: Int = 0
    var HighMassFlowErrorCount: Int = 0
    var HighMassFlowErrorIndex: Int = 0
    var OutletWaterTempErrorCount: Int = 0
    var OutletWaterTempErrorIndex: Int = 0
    var SmallWaterMassFlowErrorCount: Int = 0
    var SmallWaterMassFlowErrorIndex: Int = 0
    var capacityControl: CapacityControl = CapacityControl.Invalid
    var BypassFraction: Float64 = 0.0
    var EvapLossMode: EvapLoss = EvapLoss.ByMoistTheory
    var BlowdownMode: Blowdown = Blowdown.ByConcentration
    var blowdownSched: Optional[Sched] = None
    var WaterTankID: Int = 0
    var WaterTankDemandARRID: Int = 0
    var UserEvapLossFactor: Float64 = 0.0
    var DriftLossFraction: Float64 = 0.0
    var ConcentrationRatio: Float64 = 0.0
    var SuppliedByWaterSystem: Bool = False
    var plantLoc: PlantLocation
    var InletWaterTemp: Float64 = 0.0
    var OutletWaterTemp: Float64 = 0.0
    var WaterInletNode: Int = 0
    var WaterOutletNode: Int = 0
    var WaterMassFlowRate: Float64 = 0.0
    var Qactual: Float64 = 0.0
    var FanPower: Float64 = 0.0
    var AirFlowRateRatio: Float64 = 0.0
    var WaterUsage: Float64 = 0.0
    var MyOneTimeFlag: Bool = True
    var MyEnvrnFlag: Bool = True
    var OneTimeFlagForEachEvapFluidCooler: Bool = True
    var CheckEquipName: Bool = True
    var fluidCoolerInletWaterTemp: Float64 = 0.0
    var fluidCoolerOutletWaterTemp: Float64 = 0.0
    var FanEnergy: Float64 = 0.0
    var WaterAmountUsed: Float64 = 0.0
    var EvaporationVdot: Float64 = 0.0
    var EvaporationVol: Float64 = 0.0
    var DriftVdot: Float64 = 0.0
    var DriftVol: Float64 = 0.0
    var BlowdownVdot: Float64 = 0.0
    var BlowdownVol: Float64 = 0.0
    var MakeUpVdot: Float64 = 0.0
    var MakeUpVol: Float64 = 0.0
    var TankSupplyVdot: Float64 = 0.0
    var TankSupplyVol: Float64 = 0.0
    var StarvedMakeUpVdot: Float64 = 0.0
    var StarvedMakeUpVol: Float64 = 0.0
    var inletConds: EvapFluidCoolerInletConds = EvapFluidCoolerInletConds()

    @staticmethod
    def factory(state: EnergyPlusData, objectType: DataPlant.PlantEquipmentType, objectName: String) -> Optional[EvapFluidCoolerSpecs]:
        if state.dataEvapFluidCoolers.GetEvapFluidCoolerInputFlag:
            GetEvapFluidCoolerInput(state)
            state.dataEvapFluidCoolers.GetEvapFluidCoolerInputFlag = False
        var thisObj: Optional[EvapFluidCoolerSpecs] = None
        for i in range(len(state.dataEvapFluidCoolers.SimpleEvapFluidCooler)):
            var myObj = state.dataEvapFluidCoolers.SimpleEvapFluidCooler[i]
            if myObj.Type == objectType and myObj.Name == objectName:
                thisObj = myObj
                break
        if thisObj:
            return thisObj
        ShowFatalError(state, "LocalEvapFluidCoolerFactory: Error getting inputs for object named: " + objectName)
        return None

    def setupOutputVars(inout self, state: EnergyPlusData):
        if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
            SetupOutputVariable(state, "Cooling Tower Bypass Fraction", Units.None, self.BypassFraction, TimeStepType.System, StoreType.Average, self.Name)
        if self.SuppliedByWaterSystem:
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume Flow Rate", Units.m3_s, self.MakeUpVdot, TimeStepType.System, StoreType.Average, self.Name)
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume", Units.m3, self.MakeUpVol, TimeStepType.System, StoreType.Sum, self.Name)
            SetupOutputVariable(state, "Cooling Tower Storage Tank Water Volume Flow Rate", Units.m3_s, self.TankSupplyVdot, TimeStepType.System, StoreType.Average, self.Name)
            SetupOutputVariable(state, "Cooling Tower Storage Tank Water Volume", Units.m3, self.TankSupplyVol, TimeStepType.System, StoreType.Sum, self.Name, Resource.Water, Group.Plant, EndUseCat.HeatRejection)
            SetupOutputVariable(state, "Cooling Tower Starved Storage Tank Water Volume Flow Rate", Units.m3_s, self.StarvedMakeUpVdot, TimeStepType.System, StoreType.Average, self.Name)
            SetupOutputVariable(state, "Cooling Tower Starved Storage Tank Water Volume", Units.m3, self.StarvedMakeUpVol, TimeStepType.System, StoreType.Sum, self.Name, Resource.Water, Group.Plant, EndUseCat.HeatRejection)
            SetupOutputVariable(state, "Cooling Tower Make Up Mains Water Volume", Units.m3, self.StarvedMakeUpVol, TimeStepType.System, StoreType.Sum, self.Name, Resource.MainsWater, Group.Plant, EndUseCat.HeatRejection)
        else:
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume Flow Rate", Units.m3_s, self.MakeUpVdot, TimeStepType.System, StoreType.Average, self.Name)
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume", Units.m3, self.MakeUpVol, TimeStepType.System, StoreType.Sum, self.Name, Resource.Water, Group.Plant, EndUseCat.HeatRejection)
            SetupOutputVariable(state, "Cooling Tower Make Up Mains Water Volume", Units.m3, self.MakeUpVol, TimeStepType.System, StoreType.Sum, self.Name, Resource.MainsWater, Group.Plant, EndUseCat.HeatRejection)
        SetupOutputVariable(state, "Cooling Tower Inlet Temperature", Units.C, self.fluidCoolerInletWaterTemp, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Outlet Temperature", Units.C, self.fluidCoolerOutletWaterTemp, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Mass Flow Rate", Units.kg_s, self.WaterMassFlowRate, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Heat Transfer Rate", Units.W, self.Qactual, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Fan Electricity Rate", Units.W, self.FanPower, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Fan Electricity Energy", Units.J, self.FanEnergy, TimeStepType.System, StoreType.Sum, self.Name, Resource.Electricity, Group.Plant, EndUseCat.HeatRejection)
        SetupOutputVariable(state, "Cooling Tower Water Evaporation Volume Flow Rate", Units.m3_s, self.EvaporationVdot, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Evaporation Volume", Units.m3, self.EvaporationVol, TimeStepType.System, StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Drift Volume Flow Rate", Units.m3_s, self.DriftVdot, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Drift Volume", Units.m3, self.DriftVol, TimeStepType.System, StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Blowdown Volume Flow Rate", Units.m3_s, self.BlowdownVdot, TimeStepType.System, StoreType.Average, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Blowdown Volume", Units.m3, self.BlowdownVol, TimeStepType.System, StoreType.Sum, self.Name)

    def getSizingFactor(inout self, _sizFac: Float64):
        _sizFac = self.SizFac

    def getDesignCapacities(inout self, state: EnergyPlusData, calledFrom: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64):
        if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd or self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
            MinLoad = 0.0
            MaxLoad = self.HighSpeedStandardDesignCapacity * self.HeatRejectCapNomCapSizingRatio
            OptLoad = self.HighSpeedStandardDesignCapacity
        else:
            ShowFatalError(state, "SimEvapFluidCoolers: Invalid evaporative fluid cooler Type Requested = " + self.EvapFluidCoolerType)

    def simulate(inout self, state: EnergyPlusData, calledFrom: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
        self.AirFlowRateRatio = 0.0
        self.InitEvapFluidCooler(state)
        if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
            self.CalcSingleSpeedEvapFluidCooler(state)
        elif self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
            self.CalcTwoSpeedEvapFluidCooler(state)
        else:
            ShowFatalError(state, "SimEvapFluidCoolers: Invalid evaporative fluid cooler Type Requested = " + self.EvapFluidCoolerType)
        self.CalculateWaterUsage(state)
        self.UpdateEvapFluidCooler(state)
        self.ReportEvapFluidCooler(state, RunFlag)

    def InitEvapFluidCooler(inout self, state: EnergyPlusData):
        var RoutineName = "InitEvapFluidCooler"
        self.oneTimeInit(state)
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            var rho = self.plantLoc.loop.glycol.getDensity(state, InitConvTemp, RoutineName)
            self.DesWaterMassFlowRate = self.DesignWaterFlowRate * rho
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesWaterMassFlowRate, self.WaterInletNodeNum, self.WaterOutletNodeNum)
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        self.WaterInletNode = self.WaterInletNodeNum
        self.inletConds.WaterTemp = state.dataLoopNodes.Node[self.WaterInletNode].Temp
        if self.OutdoorAirInletNodeNum != 0:
            self.inletConds.AirTemp = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].Temp
            self.inletConds.AirHumRat = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].HumRat
            self.inletConds.AirPress = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].Press
            self.inletConds.AirWetBulb = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].OutAirWetBulb
        else:
            self.inletConds.AirTemp = state.dataEnvrn.OutDryBulbTemp
            self.inletConds.AirHumRat = state.dataEnvrn.OutHumRat
            self.inletConds.AirPress = state.dataEnvrn.OutBaroPress
            self.inletConds.AirWetBulb = state.dataEnvrn.OutWetBulbTemp
        self.WaterMassFlowRate = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.DesWaterMassFlowRate * self.EvapFluidCoolerMassFlowRateMultiplier)
        PlantUtilities.SetComponentFlowRate(state, self.WaterMassFlowRate, self.WaterInletNodeNum, self.WaterOutletNodeNum, self.plantLoc)

    def SizeEvapFluidCooler(inout self, state: EnergyPlusData):
        var MaxIte: Int = 500
        var Acc: Float64 = 0.0001
        var CalledFrom = "SizeEvapFluidCooler"
        var SolFla: Int = 0
        var UA: Float64 = 0.0
        var OutWaterTempAtUA0: Float64 = -999.0
        var OutWaterTempAtUA1: Float64 = -999.0
        var DesEvapFluidCoolerLoad: Float64 = 0.0
        var tmpDesignWaterFlowRate: Float64 = self.DesignWaterFlowRate
        var tmpHighSpeedFanPower: Float64 = self.HighSpeedFanPower
        var tmpHighSpeedAirFlowRate: Float64 = self.HighSpeedAirFlowRate
        var PltSizCondNum: Int = self.plantLoc.loop.PlantSizNum
        if PltSizCondNum > 0:
            self.DesignExitWaterTemp = state.dataSize.PlantSizData[PltSizCondNum - 1].ExitTemp
            if self.DesignEnteringWaterTemp == AutoSize and self.PerformanceInputMethod_Num != PIM.UserSpecifiedDesignCapacity:
                self.DesignEnteringWaterTemp = state.dataSize.PlantSizData[PltSizCondNum - 1].ExitTemp + state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT
        if self.DesignEnteringWaterTempWasAutoSized and self.PerformanceInputMethod_Num == PIM.UserSpecifiedDesignCapacity:
            if PltSizCondNum > 0:
                self.DesignEnteringWaterTemp = state.dataSize.PlantSizData[PltSizCondNum - 1].ExitTemp + state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT
                if self.DesignEnteringWaterTemp <= self.DesignEnteringAirWetBulbTemp:
                    ShowSevereError(state, "Error when autosizing the Design Entering Water Temperature for Evaporative Fluid Cooler = \(self.Name).")
                    ShowContinueError(state, "Design Entering Water Temperature (\(self.DesignEnteringWaterTemp:#G C) must be greater than design entering air wet-bulb temperature (\(self.DesignEnteringAirWetBulbTemp:#G C).")
                    ShowContinueError(state, "Check the Sizing:Plant object and the Design Entering Air Wet-bulb Temp input field for the Evaporative Fluid Cooler.")
                    ShowFatalError(state, "Review and revise design input values as appropriate.")
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Design Entering Water Temperature [C]", self.DesignEnteringWaterTemp)
            elif state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing error for evaporative fluid cooler object = \(self.Name)")
                ShowFatalError(state, "Autosizing of evaporative fluid cooler Design Entering Water Temperature requires a loop Sizing:Plant object.")
        if self.DesignWaterFlowRateWasAutoSized and self.PerformanceInputMethod_Num != PIM.StandardDesignCapacity:
            if PltSizCondNum > 0:
                var DesignEnteringAirWetBulb: Float64 = 0.0
                if self.PerformanceInputMethod_Num == PIM.UFactor:
                    DesignEnteringAirWetBulb = 25.6
                else:
                    DesignEnteringAirWetBulb = self.DesignEnteringAirWetBulbTemp
                if self.DesignExitWaterTemp <= DesignEnteringAirWetBulb:
                    ShowSevereError(state, "Error when autosizing the UA value for Evaporative Fluid Cooler = \(self.Name).")
                    ShowContinueError(state, "Design Loop Exit Temperature (\(self.DesignExitWaterTemp:#G C) must be greater than design entering air wet-bulb temperature (\(DesignEnteringAirWetBulb:#G C) when autosizing the Evaporative Fluid Cooler UA.")
                    ShowContinueError(state, "It is recommended that the Design Loop Exit Temperature = Design Entering Air Wet-bulb Temp plus the Evaporative Fluid Cooler design approach temperature (e.g., 4 C).")
                    ShowContinueError(state, "If using HVACTemplate:Plant:ChilledWaterLoop, then check that input field Condenser Water Design Setpoint must be > Design Entering Air Wet-bulb Temp if autosizing the Evaporative Fluid Cooler.")
                    ShowFatalError(state, "Review and revise design input values as appropriate.")
                if state.dataSize.PlantSizData[PltSizCondNum - 1].DesVolFlowRate >= SmallWaterVolFlow:
                    tmpDesignWaterFlowRate = state.dataSize.PlantSizData[PltSizCondNum - 1].DesVolFlowRate * self.SizFac
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.DesignWaterFlowRate = tmpDesignWaterFlowRate
                else:
                    tmpDesignWaterFlowRate = 0.0
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.DesignWaterFlowRate = tmpDesignWaterFlowRate
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Design Water Flow Rate [m3/s]", self.DesignWaterFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Initial Design Water Flow Rate [m3/s]", self.DesignWaterFlowRate)
            else:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "Autosizing error for evaporative fluid cooler object = \(self.Name)")
                    ShowFatalError(state, "Autosizing of evaporative fluid cooler condenser flow rate requires a loop Sizing:Plant object.")
        if self.PerformanceInputMethod_Num == PIM.UFactor and not self.HighSpeedEvapFluidCoolerUAWasAutoSized:
            if PltSizCondNum > 0:
                var rho = self.plantLoc.loop.glycol.getDensity(state, InitConvTemp, CalledFrom)
                var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.DesignExitWaterTemp, CalledFrom)
                DesEvapFluidCoolerLoad = rho * Cp * tmpDesignWaterFlowRate * state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT
                self.HighSpeedStandardDesignCapacity = DesEvapFluidCoolerLoad / self.HeatRejectCapNomCapSizingRatio
            else:
                self.HighSpeedStandardDesignCapacity = 0.0
        if self.PerformanceInputMethod_Num == PIM.StandardDesignCapacity:
            tmpDesignWaterFlowRate = 5.382e-8 * self.HighSpeedStandardDesignCapacity
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                self.DesignWaterFlowRate = tmpDesignWaterFlowRate
                if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Design Water Flow Rate based on evaporative fluid cooler Standard Design Capacity [m3/s]", self.DesignWaterFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Initial Design Water Flow Rate based on evaporative fluid cooler Standard Design Capacity [m3/s]", self.DesignWaterFlowRate)
                elif self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Design Water Flow Rate based on evaporative fluid cooler high-speed Standard Design Capacity [m3/s]", self.DesignWaterFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Initial Design Water Flow Rate based on evaporative fluid cooler high-speed Standard Design Capacity [m3/s]", self.DesignWaterFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.WaterInletNodeNum, tmpDesignWaterFlowRate)
        if self.HighSpeedFanPowerWasAutoSized:
            if self.PerformanceInputMethod_Num == PIM.StandardDesignCapacity:
                tmpHighSpeedFanPower = 0.0105 * self.HighSpeedStandardDesignCapacity
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.HighSpeedFanPower = tmpHighSpeedFanPower
            elif self.PerformanceInputMethod_Num == PIM.UserSpecifiedDesignCapacity:
                tmpHighSpeedFanPower = 0.0105 * self.HighSpeedUserSpecifiedDesignCapacity
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.HighSpeedFanPower = tmpHighSpeedFanPower
            else:
                if DesEvapFluidCoolerLoad > 0:
                    tmpHighSpeedFanPower = 0.0105 * DesEvapFluidCoolerLoad
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.HighSpeedFanPower = tmpHighSpeedFanPower
                elif PltSizCondNum > 0:
                    if state.dataSize.PlantSizData[PltSizCondNum - 1].DesVolFlowRate >= SmallWaterVolFlow:
                        var rho = self.plantLoc.loop.glycol.getDensity(state, InitConvTemp, CalledFrom)
                        var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.DesignExitWaterTemp, CalledFrom)
                        DesEvapFluidCoolerLoad = rho * Cp * tmpDesignWaterFlowRate * state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT
                        tmpHighSpeedFanPower = 0.0105 * DesEvapFluidCoolerLoad
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedFanPower = tmpHighSpeedFanPower
                    else:
                        tmpHighSpeedFanPower = 0.0
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedFanPower = tmpHighSpeedFanPower
                else:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        ShowSevereError(state, "Autosizing of evaporative fluid cooler fan power requires a loop Sizing:Plant object.")
                        ShowFatalError(state, " Occurs in evaporative fluid cooler object= \(self.Name)")
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Fan Power at Design Air Flow Rate [W]", self.HighSpeedFanPower)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Initial Fan Power at Design Air Flow Rate [W]", self.HighSpeedFanPower)
                elif self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Fan Power at High Fan Speed [W]", self.HighSpeedFanPower)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Initial Fan Power at High Fan Speed [W]", self.HighSpeedFanPower)
        if self.HighSpeedAirFlowRateWasAutoSized:
            tmpHighSpeedAirFlowRate = tmpHighSpeedFanPower * 0.5 * (101325.0 / state.dataEnvrn.StdBaroPress) / 190.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                self.HighSpeedAirFlowRate = tmpHighSpeedAirFlowRate
                if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Design Air Flow Rate [m3/s]", self.HighSpeedAirFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Initial Design Air Flow Rate [m3/s]", self.HighSpeedAirFlowRate)
                elif self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Air Flow Rate at High Fan Speed [m3/s]", self.HighSpeedAirFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Initial Air Flow Rate at High Fan Speed [m3/s]", self.HighSpeedAirFlowRate)
        if self.HighSpeedEvapFluidCoolerUAWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize and self.PerformanceInputMethod_Num == PIM.UFactor:
            if PltSizCondNum > 0:
                if state.dataSize.PlantSizData[PltSizCondNum - 1].DesVolFlowRate >= SmallWaterVolFlow:
                    if self.DesignExitWaterTemp <= 25.6:
                        ShowSevereError(state, "Error when autosizing the UA value for Evaporative Fluid Cooler = \(self.Name).")
                        ShowContinueError(state, "Design Loop Exit Temperature (\(self.DesignExitWaterTemp:#G C) must be greater than 25.6 C when autosizing the Evaporative Fluid Cooler UA.")
                        ShowContinueError(state, "The Design Loop Exit Temperature specified in Sizing:Plant object = \(state.dataSize.PlantSizData[PltSizCondNum - 1].PlantLoopName)")
                        ShowContinueError(state, "It is recommended that the Design Loop Exit Temperature = 25.6 C plus the Evaporative Fluid Cooler design approach temperature (e.g., 4 C).")
                        ShowContinueError(state, "If using HVACTemplate:Plant:ChilledWaterLoop, then check that input field Condenser Water Design Setpoint must be > 25.6 C if autosizing the Evaporative Fluid Cooler.")
                        ShowFatalError(state, "Review and revise design input values as appropriate.")
                    var rho = self.plantLoc.loop.glycol.getDensity(state, InitConvTemp, CalledFrom)
                    var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.DesignExitWaterTemp, CalledFrom)
                    DesEvapFluidCoolerLoad = rho * Cp * tmpDesignWaterFlowRate * state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT
                    var par1 = rho * tmpDesignWaterFlowRate
                    var par2 = tmpHighSpeedAirFlowRate
                    var UA0 = 0.0001 * DesEvapFluidCoolerLoad
                    var UA1 = DesEvapFluidCoolerLoad
                    self.inletConds.WaterTemp = self.DesignExitWaterTemp + state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT
                    self.inletConds.AirTemp = 35.0
                    self.inletConds.AirWetBulb = 25.6
                    self.inletConds.AirPress = state.dataEnvrn.StdBaroPress
                    self.inletConds.AirHumRat = PsyWFnTdbTwbPb(state, self.inletConds.AirTemp, self.inletConds.AirWetBulb, self.inletConds.AirPress)
                    var f: fn(Float64) -> Float64 = fn(UA: Float64) -> Float64:
                        self.SimSimpleEvapFluidCooler(state, par1, par2, UA, self.DesignExitWaterTemp)
                        var CoolingOutput = Cp * par1 * (self.inletConds.WaterTemp - self.DesignExitWaterTemp)
                        return (DesEvapFluidCoolerLoad - CoolingOutput) / DesEvapFluidCoolerLoad
                    General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                    if SolFla == -1:
                        ShowWarningError(state, "Iteration limit exceeded in calculating evaporative fluid cooler UA.")
                        ShowContinueError(state, "Autosizing of fluid cooler UA failed for evaporative fluid cooler = \(self.Name)")
                        ShowContinueError(state, "The final UA value = \(UA:#G W/C, and the simulation continues...")
                    elif SolFla == -2:
                        self.SimSimpleEvapFluidCooler(state, par1, par2, UA0, OutWaterTempAtUA0)
                        self.SimSimpleEvapFluidCooler(state, par1, par2, UA1, OutWaterTempAtUA1)
                        ShowSevereError(state, "\(CalledFrom): The combination of design input values did not allow the calculation of a ")
                        ShowContinueError(state, "reasonable UA value. Review and revise design input values as appropriate. Specifying hard")
                        ShowContinueError(state, "sizes for some \"autosizable\" fields while autosizing other \"autosizable\" fields may be contributing to this problem.")
                        ShowContinueError(state, "This model iterates on UA to find the heat transfer required to provide the design outlet ")
                        ShowContinueError(state, "water temperature. Initially, the outlet water temperatures at high and low UA values are ")
                        ShowContinueError(state, "calculated. The Design Exit Water Temperature should be between the outlet water ")
                        ShowContinueError(state, "temperatures calculated at high and low UA values. If the Design Exit Water Temperature is ")
                        ShowContinueError(state, "out of this range, the solution will not converge and UA will not be calculated. ")
                        ShowContinueError(state, "The possible solutions could be to manually input adjusted water and/or air flow rates ")
                        ShowContinueError(state, "based on the autosized values shown below or to adjust design evaporative fluid cooler air inlet wet-bulb temperature.")
                        ShowContinueError(state, "Plant:Sizing object inputs also influence these results (e.g. DeltaT and ExitTemp).")
                        ShowContinueError(state, "Inputs to the evaporative fluid cooler object:")
                        ShowContinueError(state, "Design Evaporative Fluid Cooler Load [W]                      = \(DesEvapFluidCoolerLoad:#G)")
                        ShowContinueError(state, "Design Evaporative Fluid Cooler Water Volume Flow Rate [m3/s] = \(self.DesignWaterFlowRate:#G)")
                        ShowContinueError(state, "Design Evaporative Fluid Cooler Air Volume Flow Rate [m3/s]   = \(par2:#G)")
                        ShowContinueError(state, "Design Evaporative Fluid Cooler Air Inlet Wet-bulb Temp [C]   = \(self.inletConds.AirWetBulb:#G)")
                        ShowContinueError(state, "Design Evaporative Fluid Cooler Water Inlet Temp [C]          = \(self.inletConds.WaterTemp:#G)")
                        ShowContinueError(state, "Inputs to the plant sizing object:")
                        ShowContinueError(state, "Design Exit Water Temp [C]                                    = \(self.DesignExitWaterTemp:#G)")
                        ShowContinueError(state, "Loop Design Temperature Difference [C]                        = \(state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT:#G)")
                        ShowContinueError(state, "Design Evaporative Fluid Cooler Water Inlet Temp [C]          = \(self.inletConds.WaterTemp:#G)")
                        ShowContinueError(state, "Calculated water outlet temperature at low UA [C](UA = \(UA0:#G W/C)  = \(OutWaterTempAtUA0:#G)")
                        ShowContinueError(state, "Calculated water outlet temperature at high UA [C](UA = \(UA1:#G W/C)  = \(OutWaterTempAtUA1:#G)")
                        ShowFatalError(state, "Autosizing of Evaporative Fluid Cooler UA failed for Evaporative Fluid Cooler = \(self.Name)")
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.HighSpeedEvapFluidCoolerUA = UA
                    self.HighSpeedStandardDesignCapacity = DesEvapFluidCoolerLoad / self.HeatRejectCapNomCapSizingRatio
                else:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.HighSpeedEvapFluidCoolerUA = 0.0
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "U-Factor Times Area Value at Design Air Flow Rate [W/C]", self.HighSpeedEvapFluidCoolerUA)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Initial U-Factor Times Area Value at Design Air Flow Rate [W/C]", self.HighSpeedEvapFluidCoolerUA)
                    elif self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "U-Factor Times Area Value at High Fan Speed [W/C]", self.HighSpeedEvapFluidCoolerUA)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Initial U-Factor Times Area Value at High Fan Speed [W/C]", self.HighSpeedEvapFluidCoolerUA)
            else:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "Autosizing error for evaporative fluid cooler object = \(self.Name)")
                    ShowFatalError(state, "Autosizing of evaporative fluid cooler UA requires a loop Sizing:Plant object.")
        if self.PerformanceInputMethod_Num == PIM.StandardDesignCapacity:
            if self.DesignWaterFlowRate >= SmallWaterVolFlow:
                var rho = self.plantLoc.loop.glycol.getDensity(state, InitConvTemp, CalledFrom)
                var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, 35.0, CalledFrom)
                DesEvapFluidCoolerLoad = self.HighSpeedStandardDesignCapacity * self.HeatRejectCapNomCapSizingRatio
                var par1 = rho * self.DesignWaterFlowRate
                var par2 = self.HighSpeedAirFlowRate
                var UA0 = 0.0001 * DesEvapFluidCoolerLoad
                var UA1 = DesEvapFluidCoolerLoad
                self.inletConds.WaterTemp = 35.0
                self.DesignEnteringWaterTemp = self.inletConds.WaterTemp
                self.inletConds.AirTemp = 35.0
                self.inletConds.AirWetBulb = 25.6
                self.DesignEnteringAirWetBulbTemp = self.inletConds.AirWetBulb
                self.inletConds.AirPress = state.dataEnvrn.StdBaroPress
                self.inletConds.AirHumRat = PsyWFnTdbTwbPb(state, self.inletConds.AirTemp, self.inletConds.AirWetBulb, self.inletConds.AirPress)
                var f: fn(Float64) -> Float64 = fn(UA: Float64) -> Float64:
                    self.SimSimpleEvapFluidCooler(state, par1, par2, UA, self.DesignExitWaterTemp)
                    var CoolingOutput = Cp * par1 * (self.inletConds.WaterTemp - self.DesignExitWaterTemp)
                    return (DesEvapFluidCoolerLoad - CoolingOutput) / DesEvapFluidCoolerLoad
                General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                if SolFla == -1:
                    ShowWarningError(state, "Iteration limit exceeded in calculating evaporative fluid cooler UA.")
                    ShowContinueError(state, "Autosizing of fluid cooler UA failed for evaporative fluid cooler = \(self.Name)")
                    ShowContinueError(state, "The final UA value = \(UA:#G W/C, and the simulation continues...")
                elif SolFla == -2:
                    ShowSevereError(state, "\(CalledFrom): The combination of design input values did not allow the calculation of a ")
                    ShowContinueError(state, "reasonable UA value. Review and revise design input values as appropriate. ")
                    ShowFatalError(state, "Autosizing of Evaporative Fluid Cooler UA failed for Evaporative Fluid Cooler = \(self.Name)")
                self.HighSpeedEvapFluidCoolerUA = UA
            else:
                self.HighSpeedEvapFluidCoolerUA = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "U-Factor Times Area Value at Design Air Flow Rate [W/C]", self.HighSpeedEvapFluidCoolerUA)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Initial U-Factor Times Area Value at Design Air Flow Rate [W/C]", self.HighSpeedEvapFluidCoolerUA)
                elif self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "U-Factor Times Area Value at High Fan Speed [W/C]", self.HighSpeedEvapFluidCoolerUA)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Initial U-Factor Times Area Value at High Fan Speed [W/C]", self.HighSpeedEvapFluidCoolerUA)
        if self.PerformanceInputMethod_Num == PIM.UserSpecifiedDesignCapacity:
            if self.DesignWaterFlowRate >= SmallWaterVolFlow:
                var rho = self.plantLoc.loop.glycol.getDensity(state, InitConvTemp, CalledFrom)
                var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.DesignEnteringWaterTemp, CalledFrom)
                DesEvapFluidCoolerLoad = self.HighSpeedUserSpecifiedDesignCapacity
                var par1 = rho * tmpDesignWaterFlowRate
                var par2 = tmpHighSpeedAirFlowRate
                var UA0 = 0.0001 * DesEvapFluidCoolerLoad
                var UA1 = DesEvapFluidCoolerLoad
                self.inletConds.WaterTemp = self.DesignEnteringWaterTemp
                self.inletConds.AirTemp = self.DesignEnteringAirTemp
                self.inletConds.AirWetBulb = self.DesignEnteringAirWetBulbTemp
                self.inletConds.AirPress = state.dataEnvrn.StdBaroPress
                self.inletConds.AirHumRat = PsyWFnTdbTwbPb(state, self.inletConds.AirTemp, self.inletConds.AirWetBulb, self.inletConds.AirPress)
                var f: fn(Float64) -> Float64 = fn(UA: Float64) -> Float64:
                    self.SimSimpleEvapFluidCooler(state, par1, par2, UA, self.DesignExitWaterTemp)
                    var CoolingOutput = Cp * par1 * (self.inletConds.WaterTemp - self.DesignExitWaterTemp)
                    return (DesEvapFluidCoolerLoad - CoolingOutput) / DesEvapFluidCoolerLoad
                General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                if SolFla == -1:
                    ShowWarningError(state, "Iteration limit exceeded in calculating evaporative fluid cooler UA.")
                    ShowContinueError(state, "Autosizing of fluid cooler UA failed for evaporative fluid cooler = \(self.Name)")
                    ShowContinueError(state, "The final UA value = \(UA:#G W/C, and the simulation continues...")
                elif SolFla == -2:
                    self.SimSimpleEvapFluidCooler(state, par1, par2, UA0, OutWaterTempAtUA0)
                    self.SimSimpleEvapFluidCooler(state, par1, par2, UA1, OutWaterTempAtUA1)
                    ShowSevereError(state, "\(CalledFrom): The combination of design input values did not allow the calculation of a ")
                    ShowContinueError(state, "reasonable UA value. Review and revise design input values as appropriate. Specifying hard")
                    ShowContinueError(state, "sizes for some \"autosizable\" fields while autosizing other \"autosizable\" fields may be contributing to this problem.")
                    ShowContinueError(state, "This model iterates on UA to find the heat transfer required to provide the design outlet ")
                    ShowContinueError(state, "water temperature. Initially, the outlet water temperatures at high and low UA values are ")
                    ShowContinueError(state, "calculated. The Design Exit Water Temperature should be between the outlet water ")
                    ShowContinueError(state, "temperatures calculated at high and low UA values. If the Design Exit Water Temperature is ")
                    ShowContinueError(state, "out of this range, the solution will not converge and UA will not be calculated. ")
                    ShowContinueError(state, "The possible solutions could be to manually input adjusted water and/or air flow rates ")
                    ShowContinueError(state, "based on the autosized values shown below or to adjust design evaporative fluid cooler air inlet wet-bulb temperature.")
                    ShowContinueError(state, "Plant:Sizing object inputs also influence these results (e.g. DeltaT and ExitTemp).")
                    ShowContinueError(state, "Inputs to the evaporative fluid cooler object:")
                    ShowContinueError(state, "Design Evaporative Fluid Cooler Load [W]                      = \(DesEvapFluidCoolerLoad:#G)")
                    ShowContinueError(state, "Design Evaporative Fluid Cooler Water Volume Flow Rate [m3/s] = \(self.DesignWaterFlowRate:#G)")
                    ShowContinueError(state, "Design Evaporative Fluid Cooler Air Volume Flow Rate [m3/s]   = \(par2:#G)")
                    ShowContinueError(state, "Design Evaporative Fluid Cooler Air Inlet Wet-bulb Temp [C]   = \(self.inletConds.AirWetBulb:#G)")
                    ShowContinueError(state, "Design Evaporative Fluid Cooler Water Inlet Temp [C]          = \(self.inletConds.WaterTemp:#G)")
                    ShowContinueError(state, "Inputs to the plant sizing object:")
                    ShowContinueError(state, "Design Exit Water Temp [C]                                    = \(self.DesignExitWaterTemp:#G)")
                    if PltSizCondNum > 0:
                        ShowContinueError(state, "Loop Design Temperature Difference [C]                        = \(state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT:#G)")
                    ShowContinueError(state, "Design Evaporative Fluid Cooler Water Inlet Temp [C]          = \(self.inletConds.WaterTemp:#G)")
                    ShowContinueError(state, "Calculated water outlet temperature at low UA [C](UA = \(UA0:#G W/C)  = \(OutWaterTempAtUA0:#G)")
                    ShowContinueError(state, "Calculated water outlet temperature at high UA [C](UA = \(UA1:#G W/C)  = \(OutWaterTempAtUA1:#G)")
                    ShowFatalError(state, "Autosizing of Evaporative Fluid Cooler UA failed for Evaporative Fluid Cooler = \(self.Name)")
                self.HighSpeedEvapFluidCoolerUA = UA
            else:
                self.HighSpeedEvapFluidCoolerUA = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "U-Factor Times Area Value at Design Air Flow Rate [W/C]", self.HighSpeedEvapFluidCoolerUA)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:SingleSpeed", self.Name, "Initial U-Factor Times Area Value at Design Air Flow Rate [W/C]", self.HighSpeedEvapFluidCoolerUA)
                elif self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "U-Factor Times Area Value at High Fan Speed [W/C]", self.HighSpeedEvapFluidCoolerUA)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "EvaporativeFluidCooler:TwoSpeed", self.Name, "Initial U-Factor Times Area Value at High Fan Speed [W/C]", self.HighSpeedEvapFluidCoolerUA)
        if self.LowSpeedAirFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedAirFlowRate = self.LowSpeedAirFlowRateSizingFactor * self.HighSpeedAirFlowRate
            if state.dataPlnt.PlantFinalSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Air Flow Rate at Low Fan Speed [m3/s]", self.LowSpeedAirFlowRate)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Initial Air Flow Rate at Low Fan Speed [m3/s]", self.LowSpeedAirFlowRate)
        if self.LowSpeedFanPowerWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedFanPower = self.LowSpeedFanPowerSizingFactor * self.HighSpeedFanPower
            if state.dataPlnt.PlantFinalSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Fan Power at Low Fan Speed [W]", self.LowSpeedFanPower)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Initial Fan Power at Low Fan Speed [W]", self.LowSpeedFanPower)
        if self.LowSpeedEvapFluidCoolerUAWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedEvapFluidCoolerUA = self.LowSpeedEvapFluidCoolerUASizingFactor * self.HighSpeedEvapFluidCoolerUA
            if state.dataPlnt.PlantFinalSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "U-Factor Times Area Value at Low Fan Speed [W/C]", self.LowSpeedEvapFluidCoolerUA)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Initial U-Factor Times Area Value at Low Fan Speed [W/C]", self.LowSpeedEvapFluidCoolerUA)
        if self.PerformanceInputMethod_Num == PIM.StandardDesignCapacity and self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
            if self.DesignWaterFlowRate >= SmallWaterVolFlow and self.LowSpeedStandardDesignCapacity > 0.0:
                var rho = self.plantLoc.loop.glycol.getDensity(state, InitConvTemp, CalledFrom)
                var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.DesignEnteringWaterTemp, CalledFrom)
                DesEvapFluidCoolerLoad = self.LowSpeedStandardDesignCapacity * self.HeatRejectCapNomCapSizingRatio
                var par1 = rho * tmpDesignWaterFlowRate
                var par2 = self.LowSpeedAirFlowRate
                var UA0 = 0.0001 * DesEvapFluidCoolerLoad
                var UA1 = DesEvapFluidCoolerLoad
                self.inletConds.WaterTemp = 35.0
                self.inletConds.AirTemp = 35.0
                self.inletConds.AirWetBulb = 25.6
                self.inletConds.AirPress = state.dataEnvrn.StdBaroPress
                self.inletConds.AirHumRat = PsyWFnTdbTwbPb(state, self.inletConds.AirTemp, self.inletConds.AirWetBulb, self.inletConds.AirPress)
                var f: fn(Float64) -> Float64 = fn(UA: Float64) -> Float64:
                    self.SimSimpleEvapFluidCooler(state, par1, par2, UA, self.DesignExitWaterTemp)
                    var CoolingOutput = Cp * par1 * (self.inletConds.WaterTemp - self.DesignExitWaterTemp)
                    return (DesEvapFluidCoolerLoad - CoolingOutput) / DesEvapFluidCoolerLoad
                General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                if SolFla == -1:
                    ShowWarningError(state, "Iteration limit exceeded in calculating evaporative fluid cooler UA.")
                    ShowContinueError(state, "Autosizing of fluid cooler UA failed for evaporative fluid cooler = \(self.Name)")
                    ShowContinueError(state, "The final UA value = \(UA:#G W/C, and the simulation continues...")
                elif SolFla == -2:
                    ShowSevereError(state, "\(CalledFrom): The combination of design input values did not allow the calculation of a ")
                    ShowContinueError(state, "reasonable low-speed UA value. Review and revise design input values as appropriate. ")
                    ShowFatalError(state, "Autosizing of Evaporative Fluid Cooler UA failed for Evaporative Fluid Cooler = \(self.Name)")
                self.LowSpeedEvapFluidCoolerUA = UA
            else:
                self.LowSpeedEvapFluidCoolerUA = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "U-Factor Times Area Value at Low Fan Speed [W/C]", self.LowSpeedEvapFluidCoolerUA)
                if state.dataPlnt.PlantFirstSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, self.EvapFluidCoolerType, self.Name, "Initial U-Factor Times Area Value at Low Fan Speed [W/C]", self.LowSpeedEvapFluidCoolerUA)
        if self.PerformanceInputMethod_Num == PIM.UserSpecifiedDesignCapacity and self.Type == DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd:
            if self.DesignWater
# File: FluidCoolers.mojo
# Auto-generated translation from C++ (FluidCoolers.cc / FluidCoolers.hh)
# Faithful 1:1 translation, no refactoring.

from ...Data.BaseData import BaseGlobalStruct
from ...Data.EnergyPlusData import EnergyPlusData
from ...Data.DataGlobals import DataGlobals
from ...Data.DataEnvironment import DataEnvironment
from ...Data.DataHVACGlobals import DataHVACGlobals
from ...Data.DataIPShortCuts import DataIPShortCuts
from ...Data.DataLoopNode import DataLoopNode, Node
from ...Data.DataSizing import DataSizing
from ...Data.DataBranchAirLoopPlant import DataBranchAirLoopPlant
from ...Data.Plant.DataPlant import DataPlant
from ...Data.Plant.Enums import PlantEquipmentType, LoopDemandCalcScheme, FlowLock
from ...Data.Plant.PlantLocation import PlantLocation
from ...Data.PlantComponent import PlantComponent
from ...Data.Autosizing.Base import BaseSizer
from ...Data.BranchNodeConnections import BranchNodeConnections
from ...Data.Environment import Environment
from ...Data.FluidProperties import FluidProperties
from ...Data.General import General
from ...Data.GlobalNames import GlobalNames
from ...Data.InputProcessing.InputProcessor import InputProcessor
from ...Data.NodeInputManager import NodeInputManager
from ...Data.OutAirNodeManager import OutAirNodeManager
from ...Data.OutputProcessor import OutputProcessor
from ...Data.OutputReportPredefined import OutputReportPredefined
from ...Data.PlantUtilities import PlantUtilities
from ...Data.Psychrometrics import Psychrometrics
from ...Data.UtilityRoutines import UtilityRoutines, ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowRecurringWarningErrorAtEnd, ShowSevereItemNotFound, ShowContinueErrorTimeStamp
from ...Data.Constant import Constant
from ...Data.ErrorObjectHeader import ErrorObjectHeader

from python import Python
import math

# Include header definitions
namespace EnergyPlus.FluidCoolers:
    enum PerfInputMethod(Int):
        Invalid = -1
        NOMINAL_CAPACITY = 0
        U_FACTOR = 1
        Num = 2

    @value
    struct FluidCoolerspecs:
        var Name: String  # User identifier
        var FluidCoolerType: DataPlant.PlantEquipmentType
        var PerformanceInputMethod_Num: PerfInputMethod
        var Available: Bool
        var ON: Bool
        var DesignWaterFlowRate: Float64
        var DesignWaterFlowRateWasAutoSized: Bool
        var DesWaterMassFlowRate: Float64
        var HighSpeedAirFlowRate: Float64
        var HighSpeedAirFlowRateWasAutoSized: Bool
        var HighSpeedFanPower: Float64
        var HighSpeedFanPowerWasAutoSized: Bool
        var HighSpeedFluidCoolerUA: Float64
        var HighSpeedFluidCoolerUAWasAutoSized: Bool
        var LowSpeedAirFlowRate: Float64
        var LowSpeedAirFlowRateWasAutoSized: Bool
        var LowSpeedAirFlowRateSizingFactor: Float64
        var LowSpeedFanPower: Float64
        var LowSpeedFanPowerWasAutoSized: Bool
        var LowSpeedFanPowerSizingFactor: Float64
        var LowSpeedFluidCoolerUA: Float64
        var LowSpeedFluidCoolerUAWasAutoSized: Bool
        var LowSpeedFluidCoolerUASizingFactor: Float64
        var DesignEnteringWaterTemp: Float64
        var DesignLeavingWaterTemp: Float64
        var DesignEnteringAirTemp: Float64
        var DesignEnteringAirWetBulbTemp: Float64
        var FluidCoolerMassFlowRateMultiplier: Float64
        var FluidCoolerNominalCapacity: Float64
        var FluidCoolerLowSpeedNomCap: Float64
        var FluidCoolerLowSpeedNomCapWasAutoSized: Bool
        var FluidCoolerLowSpeedNomCapSizingFactor: Float64
        var WaterInletNodeNum: Int
        var WaterOutletNodeNum: Int
        var OutdoorAirInletNodeNum: Int
        var HighMassFlowErrorCount: Int
        var HighMassFlowErrorIndex: Int
        var OutletWaterTempErrorCount: Int
        var OutletWaterTempErrorIndex: Int
        var SmallWaterMassFlowErrorCount: Int
        var SmallWaterMassFlowErrorIndex: Int
        var WMFRLessThanMinAvailErrCount: Int
        var WMFRLessThanMinAvailErrIndex: Int
        var WMFRGreaterThanMaxAvailErrCount: Int
        var WMFRGreaterThanMaxAvailErrIndex: Int
        var plantLoc: PlantLocation
        var oneTimeInitFlag: Bool
        var beginEnvrnInit: Bool
        var InletWaterTemp: Float64
        var OutletWaterTemp: Float64
        var WaterMassFlowRate: Float64
        var Qactual: Float64
        var FanPower: Float64
        var FanEnergy: Float64
        var WaterTemp: Float64
        var AirTemp: Float64
        var AirHumRat: Float64
        var AirPress: Float64
        var AirWetBulb: Float64
        var indexInArray: Int

        def __init__(inout self):
            self.FluidCoolerType = DataPlant.PlantEquipmentType.Invalid
            self.PerformanceInputMethod_Num = PerfInputMethod.NOMINAL_CAPACITY
            self.Available = True
            self.ON = True
            self.DesignWaterFlowRate = 0.0
            self.DesignWaterFlowRateWasAutoSized = False
            self.DesWaterMassFlowRate = 0.0
            self.HighSpeedAirFlowRate = 0.0
            self.HighSpeedAirFlowRateWasAutoSized = False
            self.HighSpeedFanPower = 0.0
            self.HighSpeedFanPowerWasAutoSized = False
            self.HighSpeedFluidCoolerUA = 0.0
            self.HighSpeedFluidCoolerUAWasAutoSized = False
            self.LowSpeedAirFlowRate = 0.0
            self.LowSpeedAirFlowRateWasAutoSized = False
            self.LowSpeedAirFlowRateSizingFactor = 0.0
            self.LowSpeedFanPower = 0.0
            self.LowSpeedFanPowerWasAutoSized = False
            self.LowSpeedFanPowerSizingFactor = 0.0
            self.LowSpeedFluidCoolerUA = 0.0
            self.LowSpeedFluidCoolerUAWasAutoSized = False
            self.LowSpeedFluidCoolerUASizingFactor = 0.0
            self.DesignEnteringWaterTemp = 0.0
            self.DesignLeavingWaterTemp = 0.0
            self.DesignEnteringAirTemp = 0.0
            self.DesignEnteringAirWetBulbTemp = 0.0
            self.FluidCoolerMassFlowRateMultiplier = 0.0
            self.FluidCoolerNominalCapacity = 0.0
            self.FluidCoolerLowSpeedNomCap = 0.0
            self.FluidCoolerLowSpeedNomCapWasAutoSized = False
            self.FluidCoolerLowSpeedNomCapSizingFactor = 0.0
            self.WaterInletNodeNum = 0
            self.WaterOutletNodeNum = 0
            self.OutdoorAirInletNodeNum = 0
            self.HighMassFlowErrorCount = 0
            self.HighMassFlowErrorIndex = 0
            self.OutletWaterTempErrorCount = 0
            self.OutletWaterTempErrorIndex = 0
            self.SmallWaterMassFlowErrorCount = 0
            self.SmallWaterMassFlowErrorIndex = 0
            self.WMFRLessThanMinAvailErrCount = 0
            self.WMFRLessThanMinAvailErrIndex = 0
            self.WMFRGreaterThanMaxAvailErrCount = 0
            self.WMFRGreaterThanMaxAvailErrIndex = 0
            self.plantLoc = PlantLocation()
            self.oneTimeInitFlag = True
            self.beginEnvrnInit = True
            self.InletWaterTemp = 0.0
            self.OutletWaterTemp = 0.0
            self.WaterMassFlowRate = 0.0
            self.Qactual = 0.0
            self.FanPower = 0.0
            self.FanEnergy = 0.0
            self.WaterTemp = 0.0
            self.AirTemp = 0.0
            self.AirHumRat = 0.0
            self.AirPress = 0.0
            self.AirWetBulb = 0.0
            self.indexInArray = 0

        def oneTimeInit(inout self, state: EnergyPlusData):

        def oneTimeInit_new(inout self, state: EnergyPlusData):
            self.setupOutputVars(state)
            var ErrorsFound: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.FluidCoolerType, self.plantLoc, ErrorsFound, None, None, None, None, None)
            if ErrorsFound:
                ShowFatalError(state, "InitFluidCooler: Program terminated due to previous condition(s).")

        def initEachEnvironment(inout self, state: EnergyPlusData):
            let RoutineName: String = "FluidCoolerspecs::initEachEnvironment"
            let rho: Float64 = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, RoutineName)
            self.DesWaterMassFlowRate = self.DesignWaterFlowRate * rho
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesWaterMassFlowRate, self.WaterInletNodeNum, self.WaterOutletNodeNum)

        def initialize(inout self, state: EnergyPlusData):
            if self.beginEnvrnInit and state.dataGlobal.BeginEnvrnFlag and (state.dataPlnt.PlantFirstSizesOkayToFinalize):
                self.initEachEnvironment(state)
                self.beginEnvrnInit = False
            if not state.dataGlobal.BeginEnvrnFlag:
                self.beginEnvrnInit = True
            self.WaterTemp = state.dataLoopNodes.Node[self.WaterInletNodeNum].Temp
            if self.OutdoorAirInletNodeNum != 0:
                self.AirTemp = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].Temp
                self.AirHumRat = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].HumRat
                self.AirPress = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].Press
                self.AirWetBulb = state.dataLoopNodes.Node[self.OutdoorAirInletNodeNum].OutAirWetBulb
            else:
                self.AirTemp = state.dataEnvrn.OutDryBulbTemp
                self.AirHumRat = state.dataEnvrn.OutHumRat
                self.AirPress = state.dataEnvrn.OutBaroPress
                self.AirWetBulb = state.dataEnvrn.OutWetBulbTemp
            self.WaterMassFlowRate = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.DesWaterMassFlowRate * self.FluidCoolerMassFlowRateMultiplier)
            PlantUtilities.SetComponentFlowRate(state, self.WaterMassFlowRate, self.WaterInletNodeNum, self.WaterOutletNodeNum, self.plantLoc)

        def setupOutputVars(inout self, state: EnergyPlusData):
            SetupOutputVariable(state,
                                "Cooling Tower Inlet Temperature",
                                Constant.Units.C,
                                self.InletWaterTemp,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                self.Name)
            SetupOutputVariable(state,
                                "Cooling Tower Outlet Temperature",
                                Constant.Units.C,
                                self.OutletWaterTemp,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                self.Name)
            SetupOutputVariable(state,
                                "Cooling Tower Mass Flow Rate",
                                Constant.Units.kg_s,
                                self.WaterMassFlowRate,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                self.Name)
            SetupOutputVariable(state,
                                "Cooling Tower Heat Transfer Rate",
                                Constant.Units.W,
                                self.Qactual,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                self.Name)
            SetupOutputVariable(state,
                                "Cooling Tower Fan Electricity Rate",
                                Constant.Units.W,
                                self.FanPower,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                self.Name)
            SetupOutputVariable(state,
                                "Cooling Tower Fan Electricity Energy",
                                Constant.Units.J,
                                self.FanEnergy,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                self.Name,
                                Constant.eResource.Electricity,
                                OutputProcessor.Group.Plant,
                                OutputProcessor.EndUseCat.HeatRejection)

        def size(inout self, state: EnergyPlusData):
            @parameter
            let MaxIte: Int = 500
            @parameter
            let Acc: Float64 = 0.0001
            let CalledFrom: String = "SizeFluidCooler"
            var SolFla: Int
            var DesFluidCoolerLoad: Float64 = 0.0
            var UA0: Float64
            var UA1: Float64
            var UA: Float64 = 0.0
            var OutWaterTempAtUA0: Float64
            var OutWaterTempAtUA1: Float64
            var Cp: Float64
            var rho: Float64
            var tmpHighSpeedFanPower: Float64
            var tmpHighSpeedEvapFluidCoolerUA: Float64
            var ErrorsFound: Bool = False
            var tmpDesignWaterFlowRate: Float64 = self.DesignWaterFlowRate
            var tmpHighSpeedAirFlowRate: Float64 = self.HighSpeedAirFlowRate
            var PltSizCondNum: Int = self.plantLoc.loop.PlantSizNum

            # Local function to ensure condition
            def ensureSizingPlantExitTempIsNotLessThanDesignEnteringAirTemp():
                if state.dataSize.PlantSizData[PltSizCondNum].ExitTemp <= self.DesignEnteringAirTemp and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, String.format("Error when autosizing the UA value for fluid cooler = {}.", self.Name))
                    ShowContinueError(state,
                                      String.format("Design Loop Exit Temperature ({:.2f} C) must be greater than design entering air dry-bulb temperature ({:.2f} C) when autosizing the fluid cooler UA.",
                                                    state.dataSize.PlantSizData[PltSizCondNum].ExitTemp,
                                                    self.DesignEnteringAirTemp))
                    ShowContinueError(state,
                                      "It is recommended that the Design Loop Exit Temperature = design inlet air dry-bulb temp plus the Fluid Cooler design approach temperature (e.g., 4 C).")
                    ShowContinueError(state,
                                      "If using HVACTemplate:Plant:ChilledWaterLoop, then check that input field Condenser Water Design Setpoint must be > design inlet air dry-bulb temp if autosizing the Fluid Cooler.")
                    ShowFatalError(state, "Review and revise design input values as appropriate.")

            # Design water flow rate autosizing
            if self.DesignWaterFlowRateWasAutoSized:
                if PltSizCondNum > 0:
                    ensureSizingPlantExitTempIsNotLessThanDesignEnteringAirTemp()
                    if state.dataSize.PlantSizData[PltSizCondNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                        tmpDesignWaterFlowRate = state.dataSize.PlantSizData[PltSizCondNum].DesVolFlowRate
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.DesignWaterFlowRate = tmpDesignWaterFlowRate
                    else:
                        tmpDesignWaterFlowRate = 0.0
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.DesignWaterFlowRate = tmpDesignWaterFlowRate
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Design Water Flow Rate [m3/s]",
                                                         self.DesignWaterFlowRate)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Initial Design Water Flow Rate [m3/s]",
                                                         self.DesignWaterFlowRate)
                    self.DesignLeavingWaterTemp = state.dataSize.PlantSizData[PltSizCondNum].ExitTemp
                else:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        ShowSevereError(state, String.format("Autosizing error for fluid cooler object = {}", self.Name))
                        ShowFatalError(state, "Autosizing of fluid cooler condenser flow rate requires a loop Sizing:Plant object.")

            PlantUtilities.RegisterPlantCompDesignFlow(state, self.WaterInletNodeNum, tmpDesignWaterFlowRate)

            # Performance input method and UA autosizing
            if self.PerformanceInputMethod_Num == PerfInputMethod.U_FACTOR and self.HighSpeedFluidCoolerUAWasAutoSized:
                if PltSizCondNum > 0:
                    rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, CalledFrom)
                    Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataSize.PlantSizData[PltSizCondNum].ExitTemp, CalledFrom)
                    DesFluidCoolerLoad = rho * Cp * tmpDesignWaterFlowRate * state.dataSize.PlantSizData[PltSizCondNum].DeltaT
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.FluidCoolerNominalCapacity = DesFluidCoolerLoad
                else:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.FluidCoolerNominalCapacity = 0.0

            # High speed fan power autosizing
            if self.HighSpeedFanPowerWasAutoSized:
                if self.PerformanceInputMethod_Num == PerfInputMethod.NOMINAL_CAPACITY:
                    tmpHighSpeedFanPower = 0.0105 * self.FluidCoolerNominalCapacity
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.HighSpeedFanPower = tmpHighSpeedFanPower
                else:
                    if DesFluidCoolerLoad > 0.0:
                        tmpHighSpeedFanPower = 0.0105 * DesFluidCoolerLoad
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedFanPower = tmpHighSpeedFanPower
                    elif PltSizCondNum > 0:
                        if state.dataSize.PlantSizData[PltSizCondNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                            ensureSizingPlantExitTempIsNotLessThanDesignEnteringAirTemp()
                            rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, CalledFrom)
                            Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataSize.PlantSizData[PltSizCondNum].ExitTemp, CalledFrom)
                            DesFluidCoolerLoad = rho * Cp * tmpDesignWaterFlowRate * state.dataSize.PlantSizData[PltSizCondNum].DeltaT
                            tmpHighSpeedFanPower = 0.0105 * DesFluidCoolerLoad
                            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                                self.HighSpeedFanPower = tmpHighSpeedFanPower
                        else:
                            tmpHighSpeedFanPower = 0.0
                            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                                self.HighSpeedFanPower = tmpHighSpeedFanPower
                    else:
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            ShowSevereError(state, "Autosizing of fluid cooler fan power requires a loop Sizing:Plant object.")
                            ShowFatalError(state, String.format(" Occurs in fluid cooler object = {}", self.Name))

                # Reporting fan power
                if self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Fan Power at Design Air Flow Rate [W]",
                                                         self.HighSpeedFanPower)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Initial Fan Power at Design Air Flow Rate [W]",
                                                         self.HighSpeedFanPower)
                elif self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_TwoSpd:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Fan Power at High Fan Speed [W]",
                                                         self.HighSpeedFanPower)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Initial Fan Power at High Fan Speed [W]",
                                                         self.HighSpeedFanPower)

            # High speed air flow rate autosizing
            if self.HighSpeedAirFlowRateWasAutoSized:
                if self.PerformanceInputMethod_Num == PerfInputMethod.NOMINAL_CAPACITY:
                    tmpHighSpeedAirFlowRate = self.FluidCoolerNominalCapacity / (self.DesignEnteringWaterTemp - self.DesignEnteringAirTemp) * 4.0
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.HighSpeedAirFlowRate = tmpHighSpeedAirFlowRate
                else:
                    if DesFluidCoolerLoad > 0.0:
                        tmpHighSpeedAirFlowRate = DesFluidCoolerLoad / (self.DesignEnteringWaterTemp - self.DesignEnteringAirTemp) * 4.0
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedAirFlowRate = tmpHighSpeedAirFlowRate
                    elif PltSizCondNum > 0:
                        if state.dataSize.PlantSizData[PltSizCondNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                            ensureSizingPlantExitTempIsNotLessThanDesignEnteringAirTemp()
                            rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, CalledFrom)
                            Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataSize.PlantSizData[PltSizCondNum].ExitTemp, CalledFrom)
                            DesFluidCoolerLoad = rho * Cp * tmpDesignWaterFlowRate * state.dataSize.PlantSizData[PltSizCondNum].DeltaT
                            tmpHighSpeedAirFlowRate = DesFluidCoolerLoad / (self.DesignEnteringWaterTemp - self.DesignEnteringAirTemp) * 4.0
                            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                                self.HighSpeedAirFlowRate = tmpHighSpeedAirFlowRate
                        else:
                            tmpHighSpeedAirFlowRate = 0.0
                            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                                self.HighSpeedAirFlowRate = tmpHighSpeedAirFlowRate
                    else:
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            ShowSevereError(state, "Autosizing of fluid cooler air flow rate requires a loop Sizing:Plant object")
                            ShowFatalError(state, String.format(" Occurs in fluid cooler object = {}", self.Name))

                # Reporting high speed air flow rate
                if self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Design Air Flow Rate [m3/s]",
                                                         self.HighSpeedAirFlowRate)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Initial Design Air Flow Rate [m3/s]",
                                                         self.HighSpeedAirFlowRate)
                elif DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)] == "FluidCooler:TwoSpeed":
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Air Flow Rate at High Fan Speed [m3/s]",
                                                         self.HighSpeedAirFlowRate)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Initial Air Flow Rate at High Fan Speed [m3/s]",
                                                         self.HighSpeedAirFlowRate)

            # High speed fluid cooler UA autosizing
            if self.HighSpeedFluidCoolerUAWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if PltSizCondNum > 0:
                    if state.dataSize.PlantSizData[PltSizCondNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                        ensureSizingPlantExitTempIsNotLessThanDesignEnteringAirTemp()
                        rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, CalledFrom)
                        Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataSize.PlantSizData[PltSizCondNum].ExitTemp, CalledFrom)
                        DesFluidCoolerLoad = rho * Cp * tmpDesignWaterFlowRate * state.dataSize.PlantSizData[PltSizCondNum].DeltaT
                        UA0 = 0.0001 * DesFluidCoolerLoad
                        UA1 = DesFluidCoolerLoad
                        self.WaterTemp = state.dataSize.PlantSizData[PltSizCondNum].ExitTemp + state.dataSize.PlantSizData[PltSizCondNum].DeltaT
                        self.AirTemp = self.DesignEnteringAirTemp
                        self.AirWetBulb = self.DesignEnteringAirWetBulbTemp
                        self.AirPress = state.dataEnvrn.StdBaroPress
                        self.AirHumRat = Psychrometrics.PsyWFnTdbTwbPb(state, self.AirTemp, self.AirWetBulb, self.AirPress, CalledFrom)

                        def f(UA: Float64) -> Float64:
                            var OutWaterTemp: Float64 = 0.0
                            CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, tmpHighSpeedAirFlowRate, UA, OutWaterTemp)
                            let Output: Float64 = Cp * rho * tmpDesignWaterFlowRate * (state.dataFluidCoolers.SimpleFluidCooler[self.indexInArray].WaterTemp - OutWaterTemp)
                            return (DesFluidCoolerLoad - Output) / DesFluidCoolerLoad

                        General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                        if SolFla == -1:
                            ShowWarningError(state, "Iteration limit exceeded in calculating fluid cooler UA.")
                            ShowContinueError(state, String.format("Autosizing of fluid cooler UA failed for fluid cooler = {}", self.Name))
                            ShowContinueError(state, String.format("The final UA value ={:#G} W/K, and the simulation continues...", UA))
                        elif SolFla == -2:
                            CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, tmpHighSpeedAirFlowRate, UA0, OutWaterTempAtUA0)
                            CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, tmpHighSpeedAirFlowRate, UA1, OutWaterTempAtUA1)
                            ShowSevereError(state, String.format("{}: The combination of design input values did not allow the calculation of a ", CalledFrom))
                            ShowContinueError(state, "reasonable UA value. Review and revise design input values as appropriate. Specifying hard")
                            ShowContinueError(state, R"(sizes for some "autosizable" fields while autosizing other "autosizable" fields may be )")
                            ShowContinueError(state, "contributing to this problem.")
                            ShowContinueError(state, "This model iterates on UA to find the heat transfer required to provide the design outlet ")
                            ShowContinueError(state, "water temperature. Initially, the outlet water temperatures at high and low UA values are ")
                            ShowContinueError(state, "calculated. The Design Exit Water Temperature should be between the outlet water ")
                            ShowContinueError(state, "temperatures calculated at high and low UA values. If the Design Exit Water Temperature is ")
                            ShowContinueError(state, "out of this range, the solution will not converge and UA will not be calculated. ")
                            ShowContinueError(state, "The possible solutions could be to manually input adjusted water and/or air flow rates based ")
                            ShowContinueError(state, "on the autosized values shown below or to adjust design fluid cooler air inlet dry-bulb temperature.")
                            ShowContinueError(state, "Plant:Sizing object inputs also influence these results (e.g. DeltaT and ExitTemp).")
                            ShowContinueError(state, "Inputs to the fluid cooler object:")
                            ShowContinueError(state, String.format("Design Fluid Cooler Load [W]                       = {:#G}", DesFluidCoolerLoad))
                            ShowContinueError(state, String.format("Design Fluid Cooler Water Volume Flow Rate [m3/s]  = {:#G}", self.DesignWaterFlowRate))
                            ShowContinueError(state, String.format("Design Fluid Cooler Air Volume Flow Rate [m3/s]    = {:#G}", tmpHighSpeedAirFlowRate))
                            ShowContinueError(state, String.format("Design Fluid Cooler Air Inlet Dry-bulb Temp [C]    = {:#G}", self.AirTemp))
                            ShowContinueError(state, "Inputs to the plant sizing object:")
                            ShowContinueError(state, String.format("Design Exit Water Temp [C]                         = {:#G}", state.dataSize.PlantSizData[PltSizCondNum].ExitTemp))
                            ShowContinueError(state, String.format("Loop Design Temperature Difference [C]             = {:#G}", state.dataSize.PlantSizData[PltSizCondNum].DeltaT))
                            ShowContinueError(state, String.format("Design Fluid Cooler Water Inlet Temp [C]           = {:#G}", self.WaterTemp))
                            ShowContinueError(state, String.format("Calculated water outlet temp at low UA [C] (UA = {:#G} W/K) = {:#G}", UA0, OutWaterTempAtUA0))
                            ShowContinueError(state, String.format("Calculated water outlet temp at high UA [C](UA = {:#G} W/K) = {:#G}", UA1, OutWaterTempAtUA1))
                            ShowFatalError(state, String.format("Autosizing of Fluid Cooler UA failed for fluid cooler = {}", self.Name))

                        tmpHighSpeedEvapFluidCoolerUA = UA
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedFluidCoolerUA = tmpHighSpeedEvapFluidCoolerUA
                        self.FluidCoolerNominalCapacity = DesFluidCoolerLoad
                    else:
                        tmpHighSpeedEvapFluidCoolerUA = 0.0
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            self.HighSpeedFluidCoolerUA = tmpHighSpeedEvapFluidCoolerUA

                    # Reporting UA
                    if self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_SingleSpd:
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            if state.dataPlnt.PlantFinalSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state,
                                                             DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                             self.Name,
                                                             "U-factor Times Area Value at Design Air Flow Rate [W/K]",
                                                             self.HighSpeedFluidCoolerUA)
                            if state.dataPlnt.PlantFirstSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state,
                                                             DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                             self.Name,
                                                             "Initial U-factor Times Area Value at Design Air Flow Rate [W/K]",
                                                             self.HighSpeedFluidCoolerUA)
                    elif self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_TwoSpd:
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            if state.dataPlnt.PlantFinalSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state,
                                                             DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                             self.Name,
                                                             "U-factor Times Area Value at High Fan Speed [W/K]",
                                                             self.HighSpeedFluidCoolerUA)
                            if state.dataPlnt.PlantFirstSizesOkayToReport:
                                BaseSizer.reportSizerOutput(state,
                                                             DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                             self.Name,
                                                             "Initial U-factor Times Area Value at High Fan Speed [W/K]",
                                                             self.HighSpeedFluidCoolerUA)
                else:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        ShowSevereError(state, String.format("Autosizing error for fluid cooler object = {}", self.Name))
                        ShowFatalError(state, "Autosizing of fluid cooler UA requires a loop Sizing:Plant object.")

            # Nominal capacity performance input method
            if self.PerformanceInputMethod_Num == PerfInputMethod.NOMINAL_CAPACITY:
                if self.DesignWaterFlowRate >= HVAC.SmallWaterVolFlow:
                    rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, CalledFrom)
                    Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.DesignEnteringWaterTemp, CalledFrom)
                    DesFluidCoolerLoad = self.FluidCoolerNominalCapacity
                    let par2_WaterFlow: Float64 = rho * tmpDesignWaterFlowRate
                    UA0 = 0.0001 * DesFluidCoolerLoad
                    UA1 = DesFluidCoolerLoad
                    self.WaterTemp = self.DesignEnteringWaterTemp
                    self.AirTemp = self.DesignEnteringAirTemp
                    self.AirWetBulb = self.DesignEnteringAirWetBulbTemp
                    self.AirPress = state.dataEnvrn.StdBaroPress
                    self.AirHumRat = Psychrometrics.PsyWFnTdbTwbPb(state, self.AirTemp, self.AirWetBulb, self.AirPress)

                    def f(UA: Float64) -> Float64:
                        var OutWaterTemp: Float64 = 0.0
                        CalcFluidCoolerOutlet(state, self.indexInArray, par2_WaterFlow, tmpHighSpeedAirFlowRate, UA, OutWaterTemp)
                        let Output: Float64 = Cp * par2_WaterFlow * (state.dataFluidCoolers.SimpleFluidCooler[self.indexInArray].WaterTemp - OutWaterTemp)
                        return (DesFluidCoolerLoad - Output) / DesFluidCoolerLoad

                    General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                    if SolFla == -1:
                        ShowWarningError(state, "Iteration limit exceeded in calculating fluid cooler UA.")
                        if PltSizCondNum > 0:
                            ShowContinueError(state, String.format("Autosizing of fluid cooler UA failed for fluid cooler = {}", self.Name))
                        ShowContinueError(state, String.format("The final UA value ={:#G} W/K, and the simulation continues...", UA))
                    elif SolFla == -2:
                        CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, tmpHighSpeedAirFlowRate, UA0, OutWaterTempAtUA0)
                        CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, tmpHighSpeedAirFlowRate, UA1, OutWaterTempAtUA1)
                        ShowSevereError(state, String.format("{}: The combination of design input values did not allow the calculation of a ", CalledFrom))
                        ShowContinueError(state, "reasonable UA value. Review and revise design input values as appropriate. Specifying hard")
                        ShowContinueError(state, R"(sizes for some "autosizable" fields while autosizing other "autosizable" fields may be )")
                        ShowContinueError(state, "contributing to this problem.")
                        ShowContinueError(state, "This model iterates on UA to find the heat transfer required to provide the design outlet ")
                        ShowContinueError(state, "water temperature. Initially, the outlet water temperatures at high and low UA values are ")
                        ShowContinueError(state, "calculated. The Design Exit Water Temperature should be between the outlet water ")
                        ShowContinueError(state, "temperatures calculated at high and low UA values. If the Design Exit Water Temperature is ")
                        ShowContinueError(state, "out of this range, the solution will not converge and UA will not be calculated. ")
                        ShowContinueError(state, "The possible solutions could be to manually input adjusted water and/or air flow rates based ")
                        ShowContinueError(state, "on the autosized values shown below or to adjust design fluid cooler air inlet dry-bulb temperature.")
                        ShowContinueError(state, "Plant:Sizing object inputs also influence these results (e.g. DeltaT and ExitTemp).")
                        ShowContinueError(state, "Inputs to the fluid cooler object:")
                        ShowContinueError(state, String.format("Design Fluid Cooler Load [W]                       = {:#G}", DesFluidCoolerLoad))
                        ShowContinueError(state, String.format("Design Fluid Cooler Water Volume Flow Rate [m3/s]  = {:#G}", self.DesignWaterFlowRate))
                        ShowContinueError(state, String.format("Design Fluid Cooler Air Volume Flow Rate [m3/s]    = {:#G}", tmpHighSpeedAirFlowRate))
                        ShowContinueError(state, String.format("Design Fluid Cooler Air Inlet Dry-bulb Temp [C]    = {:#G}", self.AirTemp))
                        if PltSizCondNum > 0:
                            ShowContinueError(state, "Inputs to the plant sizing object:")
                            ShowContinueError(state, String.format("Design Exit Water Temp [C]                         = {:#G}", state.dataSize.PlantSizData[PltSizCondNum].ExitTemp))
                            ShowContinueError(state, String.format("Loop Design Temperature Difference [C]             = {:#G}", state.dataSize.PlantSizData[PltSizCondNum].DeltaT))
                        ShowContinueError(state, String.format("Design Fluid Cooler Water Inlet Temp [C]           = {:#G}", self.WaterTemp))
                        ShowContinueError(state, String.format("Calculated water outlet temp at low UA [C] (UA = {:#G} W/K) = {:#G}", UA0, OutWaterTempAtUA0))
                        ShowContinueError(state, String.format("Calculated water outlet temp at high UA [C] (UA = {:#G} W/K) = {:#G}", UA1, OutWaterTempAtUA1))
                        if PltSizCondNum > 0:
                            ShowFatalError(state, String.format("Autosizing of Fluid Cooler UA failed for fluid cooler = {}", self.Name))

                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.HighSpeedFluidCoolerUA = UA
                else:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.HighSpeedFluidCoolerUA = 0.0

                # Reporting UA for nominal capacity method
                if self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_SingleSpd:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Fluid cooler UA value at design air flow rate based on nominal capacity input [W/K]",
                                                         self.HighSpeedFluidCoolerUA)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Initial Fluid cooler UA value at design air flow rate based on nominal capacity input [W/K]",
                                                         self.HighSpeedFluidCoolerUA)
                elif self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_TwoSpd:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Fluid cooler UA value at high fan speed based on nominal capacity input [W/K]",
                                                         self.HighSpeedFluidCoolerUA)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state,
                                                         DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                         self.Name,
                                                         "Initial Fluid cooler UA value at high fan speed based on nominal capacity input [W/K]",
                                                         self.HighSpeedFluidCoolerUA)

            # Low speed air flow rate autosizing
            if self.LowSpeedAirFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                self.LowSpeedAirFlowRate = self.LowSpeedAirFlowRateSizingFactor * self.HighSpeedAirFlowRate
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state,
                                                 DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                 self.Name,
                                                 "Air Flow Rate at Low Fan Speed [m3/s]",
                                                 self.LowSpeedAirFlowRate)
                if state.dataPlnt.PlantFirstSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state,
                                                 DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                 self.Name,
                                                 "Initial Air Flow Rate at Low Fan Speed [m3/s]",
                                                 self.LowSpeedAirFlowRate)

            # Low speed fan power autosizing
            if self.LowSpeedFanPowerWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                self.LowSpeedFanPower = self.LowSpeedFanPowerSizingFactor * self.HighSpeedFanPower
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state,
                                                 DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                 self.Name,
                                                 "Fan Power at Low Fan Speed [W]",
                                                 self.LowSpeedFanPower)
                if state.dataPlnt.PlantFirstSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state,
                                                 DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                 self.Name,
                                                 "Initial Fan Power at Low Fan Speed [W]",
                                                 self.LowSpeedFanPower)

            # Low speed fluid cooler UA autosizing
            if self.LowSpeedFluidCoolerUAWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                self.LowSpeedFluidCoolerUA = self.LowSpeedFluidCoolerUASizingFactor * self.HighSpeedFluidCoolerUA
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state,
                                                 DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                 self.Name,
                                                 "U-factor Times Area Value at Low Fan Speed [W/K]",
                                                 self.LowSpeedFluidCoolerUA)
                if state.dataPlnt.PlantFirstSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state,
                                                 DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                 self.Name,
                                                 "Initial U-factor Times Area Value at Low Fan Speed [W/K]",
                                                 self.LowSpeedFluidCoolerUA)

            # Low speed nominal capacity for two-speed
            if self.PerformanceInputMethod_Num == PerfInputMethod.NOMINAL_CAPACITY and self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_TwoSpd:
                if self.FluidCoolerLowSpeedNomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.FluidCoolerLowSpeedNomCap = self.FluidCoolerLowSpeedNomCapSizingFactor * self.FluidCoolerNominalCapacity
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state,
                                                     DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                     self.Name,
                                                     "Low Fan Speed Nominal Capacity [W]",
                                                     self.FluidCoolerLowSpeedNomCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state,
                                                     DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                     self.Name,
                                                     "Initial Low Fan Speed Nominal Capacity [W]",
                                                     self.FluidCoolerLowSpeedNomCap)

                if self.DesignWaterFlowRate >= HVAC.SmallWaterVolFlow and self.FluidCoolerLowSpeedNomCap > 0.0:
                    rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, CalledFrom)
                    Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.DesignEnteringWaterTemp, CalledFrom)
                    DesFluidCoolerLoad = self.FluidCoolerLowSpeedNomCap
                    UA0 = 0.0001 * DesFluidCoolerLoad
                    UA1 = DesFluidCoolerLoad
                    self.WaterTemp = self.DesignEnteringWaterTemp
                    self.AirTemp = self.DesignEnteringAirTemp
                    self.AirWetBulb = self.DesignEnteringAirWetBulbTemp
                    self.AirPress = state.dataEnvrn.StdBaroPress
                    self.AirHumRat = Psychrometrics.PsyWFnTdbTwbPb(state, self.AirTemp, self.AirWetBulb, self.AirPress, CalledFrom)

                    def f(UA: Float64) -> Float64:
                        var OutWaterTemp: Float64 = 0.0
                        CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, self.LowSpeedAirFlowRate, UA, OutWaterTemp)
                        let Output: Float64 = Cp * rho * tmpDesignWaterFlowRate * (state.dataFluidCoolers.SimpleFluidCooler[self.indexInArray].WaterTemp - OutWaterTemp)
                        return (DesFluidCoolerLoad - Output) / DesFluidCoolerLoad

                    General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                    if SolFla == -1:
                        ShowWarningError(state, "Iteration limit exceeded in calculating fluid cooler UA.")
                        ShowContinueError(state, String.format("Autosizing of fluid cooler UA failed for fluid cooler = {}", self.Name))
                        ShowContinueError(state, String.format("The final UA value at low fan speed ={:#G} W/C, and the simulation continues...", UA))
                    elif SolFla == -2:
                        CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, self.LowSpeedAirFlowRate, UA0, OutWaterTempAtUA0)
                        CalcFluidCoolerOutlet(state, self.indexInArray, rho * tmpDesignWaterFlowRate, self.LowSpeedAirFlowRate, UA1, OutWaterTempAtUA1)
                        ShowSevereError(state, String.format("{}: The combination of design input values did not allow the calculation of a ", CalledFrom))
                        ShowContinueError(state, "reasonable low-speed UA value. Review and revise design input values as appropriate. ")
                        ShowContinueError(state, R"(Specifying hard sizes for some "autosizable" fields while autosizing other "autosizable" )")
                        ShowContinueError(state, "fields may be contributing to this problem.")
                        ShowContinueError(state, "This model iterates on UA to find the heat transfer required to provide the design outlet ")
                        ShowContinueError(state, "water temperature. Initially, the outlet water temperatures at high and low UA values are ")
                        ShowContinueError(state, "calculated. The Design Exit Water Temperature should be between the outlet water ")
                        ShowContinueError(state, "temperatures calculated at high and low UA values. If the Design Exit Water Temperature is ")
                        ShowContinueError(state, "out of this range, the solution will not converge and UA will not be calculated. ")
                        ShowContinueError(state, "The possible solutions could be to manually input adjusted water and/or air flow rates based ")
                        ShowContinueError(state, "on the autosized values shown below or to adjust design fluid cooler air inlet dry-bulb temperature.")
                        ShowContinueError(state, "Plant:Sizing object inputs also influence these results (e.g. DeltaT and ExitTemp).")
                        ShowContinueError(state, "Inputs to the fluid cooler object:")
                        ShowContinueError(state, String.format("Design Fluid Cooler Load [W]                         = {:#G}", DesFluidCoolerLoad))
                        ShowContinueError(state, String.format("Design Fluid Cooler Water Volume Flow Rate [m3/s]    = {:#G}", self.DesignWaterFlowRate))
                        ShowContinueError(state, String.format("Design Fluid Cooler Air Volume Flow Rate [m3/s]      = {:#G}", self.LowSpeedAirFlowRate))
                        ShowContinueError(state, String.format("Design Fluid Cooler Air Inlet Dry-bulb Temp [C]      = {:.2f}", self.AirTemp))
                        ShowContinueError(state, "Inputs to the plant sizing object:")
                        ShowContinueError(state, String.format("Design Exit Water Temp [C]                           = {:.2f}", state.dataSize.PlantSizData[PltSizCondNum].ExitTemp))
                        ShowContinueError(state, String.format("Loop Design Temperature Difference [C]               = {:.2f}", state.dataSize.PlantSizData[PltSizCondNum].DeltaT))
                        ShowContinueError(state, String.format("Design Fluid Cooler Water Inlet Temp [C]             = {:.2f}", self.WaterTemp))
                        ShowContinueError(state, String.format("Calculated water outlet temp at low UA [C](UA = {:#G} W/C) = {:#G}", UA0, OutWaterTempAtUA0))
                        ShowContinueError(state, String.format("Calculated water outlet temp at high UA [C](UA = {:#G} W/C) = {:#G}", UA1, OutWaterTempAtUA1))
                        ShowFatalError(state, String.format("Autosizing of Fluid Cooler UA failed for fluid cooler = {}", self.Name))

                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.LowSpeedFluidCoolerUA = UA
                else:
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.LowSpeedFluidCoolerUA = 0.0

                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state,
                                                     DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                     self.Name,
                                                     "U-factor Times Area Value at Low Fan Speed [W/C]",
                                                     self.LowSpeedFluidCoolerUA)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state,
                                                     DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)],
                                                     self.Name,
                                                     "Initial U-factor Times Area Value at Low Fan Speed [W/C]",
                                                     self.LowSpeedFluidCoolerUA)

            ErrorsFound = False
            if state.dataPlnt.PlantFinalSizesOkayToReport:
                if self.DesignLeavingWaterTemp <= HVAC.SmallTempDiff:
                    self.WaterTemp = self.DesignEnteringWaterTemp
                    self.AirTemp = self.DesignEnteringAirTemp
                    self.AirWetBulb = self.DesignEnteringAirWetBulbTemp
                    self.AirPress = state.dataEnvrn.StdBaroPress
                    self.AirHumRat = Psychrometrics.PsyWFnTdbTwbPb(state, self.AirTemp, self.AirWetBulb, self.AirPress)
                    var OutletTemp: Float64 = 0.0
                    rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, CalledFrom)
                    CalcFluidCoolerOutlet(state, self.indexInArray, rho * self.DesignWaterFlowRate, self.HighSpeedAirFlowRate, self.HighSpeedFluidCoolerUA, OutletTemp)
                    self.DesignLeavingWaterTemp = OutletTemp

                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)])
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.FluidCoolerNominalCapacity)
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCType, self.Name, DataPlant.PlantEquipTypeNames[Int(self.FluidCoolerType)])
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCCondLoopName, self.Name, (self.plantLoc.loop.Name if self.plantLoc.loop != None else "N/A"))
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCCondLoopBranchName, self.Name, (self.plantLoc.branch.Name if self.plantLoc.loop != None else "N/A"))
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCFluidType, self.Name, self.plantLoc.loop.FluidName)
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCRange, self.Name, self.DesignEnteringWaterTemp - self.DesignLeavingWaterTemp)
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCApproach, self.Name, self.DesignLeavingWaterTemp - self.DesignEnteringAirWetBulbTemp)
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCDesFanPwr, self.Name, self.HighSpeedFanPower)
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCDesInletAirWBT, self.Name, self.DesignEnteringAirWetBulbTemp)
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCDesWaterFlowRate, self.Name, self.DesignWaterFlowRate, 6)
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCTFCLevWaterSPTemp, self.Name, self.DesignLeavingWaterTemp)

            if self.FluidCoolerType == DataPlant.PlantEquipmentType.FluidCooler_TwoSpd and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.DesignWaterFlowRate > 0.0:
                    if self.HighSpeedAirFlowRate <= self.LowSpeedAirFlowRate:
                        ShowSevereError(state, String.format("FluidCooler:TwoSpeed  \"{}\". Low speed air flow rate must be less than high speed air flow rate.", self.Name))
                        ErrorsFound = True
                    if self.HighSpeedFluidCoolerUA <= self.LowSpeedFluidCoolerUA:
                        ShowSevereError(state, String.format("FluidCooler:TwoSpeed  \"{}\". Fluid cooler UA at low fan speed must be less than the fluid cooler UA at high fan speed.", self.Name))
                        ErrorsFound = True

            if ErrorsFound:
                ShowFatalError(state, "SizeFluidCooler: Program terminated due to previous condition(s).")

        def calcSingleSpeed(inout self, state: EnergyPlusData):
            let RoutineName: String = "SingleSpeedFluidCooler"
            var TempSetPoint: Float64 = 0.0
            self.Qactual = 0.0
            self.FanPower = 0.0
            self.OutletWaterTemp = state.dataLoopNodes.Node[self.WaterInletNodeNum].Temp

            # Switch on LoopDemandCalcScheme
            if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                TempSetPoint = self.plantLoc.side.TempSetPoint
            elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                TempSetPoint = self.plantLoc.side.TempSetPointHi
            else:

            if self.WaterMassFlowRate <= DataBranchAirLoopPlant.MassFlowTolerance:
                return

            if self.OutletWaterTemp < TempSetPoint:
                return

            let OutletWaterTempOFF: Float64 = state.dataLoopNodes.Node[self.WaterInletNodeNum].Temp
            self.OutletWaterTemp = OutletWaterTempOFF

            let UAdesign: Float64 = self.HighSpeedFluidCoolerUA
            let AirFlowRate: Float64 = self.HighSpeedAirFlowRate
            let FanPowerOn: Float64 = self.HighSpeedFanPower

            CalcFluidCoolerOutlet(state, self.indexInArray, self.WaterMassFlowRate, AirFlowRate, UAdesign, self.OutletWaterTemp)

            if self.OutletWaterTemp <= TempSetPoint:
                var FanModeFrac: Float64 = 0.0
                if self.OutletWaterTemp != OutletWaterTempOFF:
                    FanModeFrac = (TempSetPoint - OutletWaterTempOFF) / (self.OutletWaterTemp - OutletWaterTempOFF)
                self.FanPower = max(FanModeFrac * FanPowerOn, 0.0)
                self.OutletWaterTemp = TempSetPoint
            else:
                self.FanPower = FanPowerOn

            let CpWater: Float64 = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[self.WaterInletNodeNum].Temp, RoutineName)
            self.Qactual = self.WaterMassFlowRate * CpWater * (state.dataLoopNodes.Node[self.WaterInletNodeNum].Temp - self.OutletWaterTemp)

        def calcTwoSpeed(inout self, state: EnergyPlusData):
            let RoutineName: String = "TwoSpeedFluidCooler"
            var TempSetPoint: Float64 = 0.0
            self.Qactual = 0.0
            self.FanPower = 0.0
            self.OutletWaterTemp = state.dataLoopNodes.Node[self.WaterInletNodeNum].Temp

            if self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                TempSetPoint = self.plantLoc.side.TempSetPoint
            elif self.plantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                TempSetPoint = self.plantLoc.side.TempSetPointHi
            else:

            if self.WaterMassFlowRate <= DataBranchAirLoopPlant.MassFlowTolerance or self.plantLoc.side.FlowLock == DataPlant.FlowLock.Unlocked:
                return

            self.WaterMassFlowRate = state.dataLoopNodes.Node[self.WaterInletNodeNum].MassFlowRate

            let OutletWaterTempOFF: Float64 = state.dataLoopNodes.
from Array1D import Array1D
from ConvectionCoefficients import *
from .Data.BaseData import BaseGlobalStruct
from .Plant.Enums import *
from .Plant.PlantLocation import PlantLocation
from PlantComponent import PlantComponent
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataLoopNode import *
from DataPhotovoltaics import *
from DataSizing import *
from DataSurfaces import *
from EMSManager import *
from FluidProperties import *
from General import *
from GeneralRoutines import *
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import NodeInputManager
from OutputProcessor import *
from .Plant.DataPlant import DataPlant, PlantEquipmentType, LoopSideLocation
from PlantUtilities import PlantUtilities
from Psychrommetrics import Psychrometrics
from ScheduleManager import Sched
from SurfaceGeometry import *
from UtilityRoutines import Util
from .Autosizing.Base import BaseSizer
from BranchNodeConnections import BranchNodeConnections
from Construction import Construction

# This file is a faithful 1:1 translation from C++ to Mojo.

# Enums from header
enum PVTMode:
    Invalid = -1
    Heating = 0
    Cooling = 1
    Num = 2

enum WorkingFluidEnum:
    Invalid = -1
    LIQUID = 0
    AIR = 1
    Num = 2

enum ThermEfficEnum:
    Invalid = -1
    SCHEDULED = 0
    FIXED = 1
    Num = 2

# Constant array ThermEfficTypeNamesUC
def getThermEfficTypeNamesUC() -> Array[String]:
    return Array[String]("SCHEDULED", "FIXED")

# Struct SimplePVTModelStruct
struct SimplePVTModelStruct:
    var Name: String
    var ThermalActiveFract: Float64 = 0.0
    var ThermEfficMode: ThermEfficEnum = ThermEfficEnum.FIXED
    var ThermEffic: Float64 = 0.0
    var thermEffSched: Sched.Schedule? = None
    var SurfEmissivity: Float64 = 0.0
    var LastCollectorTemp: Float64 = 0.0

# Struct BIPVTModelStruct
struct BIPVTModelStruct:
    var Name: String
    var OSCMName: String
    var OSCMPtr: Int = 0
    var availSched: Sched.Schedule? = None
    var PVEffGapWidth: Float64 = 0.0
    var PVCellTransAbsProduct: Float64 = 0.0
    var BackMatTranAbsProduct: Float64 = 0.0
    var CladTranAbsProduct: Float64 = 0.0
    var PVAreaFract: Float64 = 0.0
    var PVCellAreaFract: Float64 = 0.0
    var PVRTop: Float64 = 0.0
    var PVRBot: Float64 = 0.0
    var PVGEmiss: Float64 = 0.0
    var BackMatEmiss: Float64 = 0.0
    var ThGlass: Float64 = 0.0
    var RIndGlass: Float64 = 0.0
    var ECoffGlass: Float64 = 0.0
    var LastCollectorTemp: Float64 = 0.0
    var Tplen: Float64 = 20.0
    var Tcoll: Float64 = 20.0
    var HrPlen: Float64 = 1.0
    var HcPlen: Float64 = 10.0

# Struct PVTReportStruct
struct PVTReportStruct:
    var ThermPower: Float64 = 0.0
    var ThermHeatGain: Float64 = 0.0
    var ThermHeatLoss: Float64 = 0.0
    var ThermEnergy: Float64 = 0.0
    var MdotWorkFluid: Float64 = 0.0
    var TinletWorkFluid: Float64 = 0.0
    var ToutletWorkFluid: Float64 = 0.0
    var BypassStatus: Float64 = 0.0

# Enum PVTModelType
enum PVTModelType:
    Invalid = -1
    Simple = 1001
    BIPVT = 1002
    Num = 1003

# Struct PVTCollectorStruct (implements PlantComponent trait)
struct PVTCollectorStruct:
    # PlantComponent required methods (trait)
    # Note: In Mojo we use traits via @implements, but for simplicity we include members manually.
    var Name: String
    var Type: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
    var WPlantLoc: PlantLocation
    var EnvrnInit: Bool = True
    var SizingInit: Bool = True
    var PVTModelName: String
    var ModelType: PVTModelType = PVTModelType.Invalid
    var OperatingMode: PVTMode = PVTMode.Invalid
    var SurfNum: Int = 0
    var PVname: String
    var PVnum: Int = 0
    var PVfound: Bool = False
    var Simple: SimplePVTModelStruct
    var BIPVT: BIPVTModelStruct
    var WorkingFluidType: WorkingFluidEnum = WorkingFluidEnum.LIQUID
    var PlantInletNodeNum: Int = 0
    var PlantOutletNodeNum: Int = 0
    var HVACInletNodeNum: Int = 0
    var HVACOutletNodeNum: Int = 0
    var DesignVolFlowRate: Float64 = 0.0
    var DesignVolFlowRateWasAutoSized: Bool = False
    var MaxMassFlowRate: Float64 = 0.0
    var MassFlowRate: Float64 = 0.0
    var AreaCol: Float64 = 0.0
    var BypassDamperOff: Bool = True
    var CoolingUseful: Bool = False
    var HeatingUseful: Bool = False
    var Report: PVTReportStruct
    var MySetPointCheckFlag: Bool = True
    var MyOneTimeFlag: Bool = True
    var SetLoopIndexFlag: Bool = True
    var QdotSource: Float64 = 0.0

    # Methods
    def factory(state: EnergyPlusData, objectName: String) -> Pointer[PVTCollectorStruct]:
        if state.dataPhotovoltaicThermalCollector.GetInputFlag:
            GetPVTcollectorsInput(state)
            state.dataPhotovoltaicThermalCollector.GetInputFlag = False
        for i in range(len(state.dataPhotovoltaicThermalCollector.PVT)):
            if state.dataPhotovoltaicThermalCollector.PVT[i].Name == objectName:
                return Pointer[PVTCollectorStruct].address_of(state.dataPhotovoltaicThermalCollector.PVT[i])
        ShowFatalError(state, "Solar Thermal Collector Factory: Error getting inputs for object named: " + objectName)
        return Pointer[PVTCollectorStruct]

    def onInitLoopEquip(self: Pointer[Self], state: EnergyPlusData, calledFromLocation: PlantLocation) raises:
        self[].initialize(state, True)
        self[].size(state)

    def simulate(self: Pointer[Self], state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) raises:
        self[].initialize(state, FirstHVACIteration)
        self[].control(state)
        self[].calculate(state)
        self[].update(state)

    def setupReportVars(self: Pointer[Self], state: EnergyPlusData):
        SetupOutputVariable(state,
                            "Generator Produced Thermal Rate",
                            Constant.Units.W,
                            self[].Report.ThermPower,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self[].Name)
        if self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
            SetupOutputVariable(state,
                                "Generator Produced Thermal Energy",
                                Constant.Units.J,
                                self[].Report.ThermEnergy,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                self[].Name,
                                Constant.eResource.SolarWater,
                                OutputProcessor.Group.Plant,
                                OutputProcessor.EndUseCat.HeatProduced)
        elif self[].WorkingFluidType == WorkingFluidEnum.AIR:
            SetupOutputVariable(state,
                                "Generator Produced Thermal Energy",
                                Constant.Units.J,
                                self[].Report.ThermEnergy,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                self[].Name,
                                Constant.eResource.SolarAir,
                                OutputProcessor.Group.HVAC,
                                OutputProcessor.EndUseCat.HeatProduced)
            SetupOutputVariable(state,
                                "Generator PVT Fluid Bypass Status",
                                Constant.Units.None,
                                self[].Report.BypassStatus,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                self[].Name)
        SetupOutputVariable(state,
                            "Generator PVT Fluid Inlet Temperature",
                            Constant.Units.C,
                            self[].Report.TinletWorkFluid,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self[].Name)
        SetupOutputVariable(state,
                            "Generator PVT Fluid Outlet Temperature",
                            Constant.Units.C,
                            self[].Report.ToutletWorkFluid,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self[].Name)
        SetupOutputVariable(state,
                            "Generator PVT Fluid Mass Flow Rate",
                            Constant.Units.kg_s,
                            self[].Report.MdotWorkFluid,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self[].Name)

    def initialize(self: Pointer[Self], state: EnergyPlusData, FirstHVACIteration: Bool) raises:
        let RoutineName: String = "InitPVTcollectors"
        self[].oneTimeInit(state)
        if not self[].PVfound:
            if state.dataPhotovoltaic.PVarray is not None:
                self[].PVnum = Util.FindItemInList(self[].PVname, state.dataPhotovoltaic.PVarray)
                if self[].PVnum == 0:
                    ShowSevereError(state, "Invalid name for photovoltaic generator = " + self[].PVname)
                    ShowContinueError(state, "Entered in flat plate photovoltaic-thermal collector = " + self[].Name)
                else:
                    self[].PVfound = True
            else:
                if (not state.dataGlobal.BeginEnvrnFlag) and (not FirstHVACIteration):
                    ShowSevereError(state, "Photovoltaic generators are missing for Photovoltaic Thermal modeling")
                    ShowContinueError(state, "Needed for flat plate photovoltaic-thermal collector = " + self[].Name)
        if not state.dataGlobal.SysSizingCalc and self[].MySetPointCheckFlag and state.dataHVACGlobal.DoSetPointTest:
            for PVTindex in range(state.dataPhotovoltaicThermalCollector.NumPVT):
                if state.dataPhotovoltaicThermalCollector.PVT[PVTindex].WorkingFluidType == WorkingFluidEnum.AIR:
                    if state.dataLoopNodes.Node[state.dataPhotovoltaicThermalCollector.PVT[PVTindex].HVACOutletNodeNum].TempSetPoint == Node.SensedNodeFlagValue:
                        if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                            ShowSevereError(state, "Missing temperature setpoint for PVT outlet node  ")
                            ShowContinueError(state, "Add a setpoint manager to outlet node of PVT named " + state.dataPhotovoltaicThermalCollector.PVT[PVTindex].Name)
                            state.dataHVACGlobal.SetPointErrorFlag = True
                        else:
                            EMSManager.CheckIfNodeSetPointManagedByEMS(state, state.dataPhotovoltaicThermalCollector.PVT[PVTindex].HVACOutletNodeNum, HVAC.CtrlVarType.Temp, state.dataHVACGlobal.SetPointErrorFlag)
                            if state.dataHVACGlobal.SetPointErrorFlag:
                                ShowSevereError(state, "Missing temperature setpoint for PVT outlet node  ")
                                ShowContinueError(state, "Add a setpoint manager to outlet node of PVT named " + state.dataPhotovoltaicThermalCollector.PVT[PVTindex].Name)
                                ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at the outlet node of PVT")
            self[].MySetPointCheckFlag = False
        if not state.dataGlobal.SysSizingCalc and self[].SizingInit and (self[].WorkingFluidType == WorkingFluidEnum.AIR):
            self[].size(state)
        var InletNode: Int = 0
        var OutletNode: Int = 0
        if self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
            InletNode = self[].PlantInletNodeNum
            OutletNode = self[].PlantOutletNodeNum
        elif self[].WorkingFluidType == WorkingFluidEnum.AIR:
            InletNode = self[].HVACInletNodeNum
            OutletNode = self[].HVACOutletNodeNum
        else:
            assert(False)
        if state.dataGlobal.BeginEnvrnFlag and self[].EnvrnInit:
            self[].MassFlowRate = 0.0
            self[].BypassDamperOff = True
            self[].CoolingUseful = False
            self[].HeatingUseful = False
            self[].Simple.LastCollectorTemp = 0.0
            self[].BIPVT.LastCollectorTemp = 0.0
            self[].Report.ThermPower = 0.0
            self[].Report.ThermHeatGain = 0.0
            self[].Report.ThermHeatLoss = 0.0
            self[].Report.ThermEnergy = 0.0
            self[].Report.MdotWorkFluid = 0.0
            self[].Report.TinletWorkFluid = 0.0
            self[].Report.ToutletWorkFluid = 0.0
            self[].Report.BypassStatus = 0.0
            if self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
                let rho: Float64 = self[].WPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                self[].MaxMassFlowRate = self[].DesignVolFlowRate * rho
                PlantUtilities.InitComponentNodes(state, 0.0, self[].MaxMassFlowRate, InletNode, OutletNode)
                self[].Simple.LastCollectorTemp = 23.0
            elif self[].WorkingFluidType == WorkingFluidEnum.AIR:
                self[].Simple.LastCollectorTemp = 23.0
                self[].BIPVT.LastCollectorTemp = 23.0
            self[].EnvrnInit = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self[].EnvrnInit = True
        if self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
            if state.dataHeatBal.SurfQRadSWOutIncident[self[].SurfNum] > DataPhotovoltaics.MinIrradiance:
                self[].MassFlowRate = self[].MaxMassFlowRate
            else:
                self[].MassFlowRate = 0.0
            PlantUtilities.SetComponentFlowRate(state, self[].MassFlowRate, InletNode, OutletNode, self[].WPlantLoc)
        elif self[].WorkingFluidType == WorkingFluidEnum.AIR:
            self[].MassFlowRate = state.dataLoopNodes.Node[InletNode].MassFlowRate

    def size(self: Pointer[Self], state: EnergyPlusData) raises:
        var SizingDesRunThisAirSys: Bool = False
        var HardSizeNoDesRun: Bool = not (state.dataSize.SysSizingRunDone or state.dataSize.ZoneSizingRunDone)
        if state.dataSize.CurSysNum > 0:
            CheckThisAirSystemForSizing(state, state.dataSize.CurSysNum, SizingDesRunThisAirSys)
        else:
            SizingDesRunThisAirSys = False
        var DesignVolFlowRateDes: Float64 = 0.0
        var ErrorsFound: Bool = False
        if self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
            if state.dataSize.PlantSizData is None:
                return
            if state.dataPlnt.PlantLoop is None:
                return
            var PltSizNum: Int = 0
            if self[].WPlantLoc.loopNum > 0:
                PltSizNum = self[].WPlantLoc.loop.PlantSizNum
            if self[].WPlantLoc.loopSideNum == DataPlant.LoopSideLocation.Supply:
                if PltSizNum > 0:
                    if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                        DesignVolFlowRateDes = state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate
                    else:
                        DesignVolFlowRateDes = 0.0
                else:
                    if self[].DesignVolFlowRateWasAutoSized:
                        if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                            ShowSevereError(state, "Autosizing of PVT solar collector design flow rate requires a Sizing:Plant object")
                            ShowContinueError(state, "Occurs in PVT object=" + self[].Name)
                            ErrorsFound = True
                    else:
                        if state.dataPlnt.PlantFinalSizesOkayToReport and self[].DesignVolFlowRate > 0.0:
                            BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name, "User-Specified Design Flow Rate [m3/s]", self[].DesignVolFlowRate)
            elif self[].WPlantLoc.loopSideNum == DataPlant.LoopSideLocation.Demand:
                let SimplePVTWaterSizeFactor: Float64 = 1.905e-5
                DesignVolFlowRateDes = self[].AreaCol * SimplePVTWaterSizeFactor
            if self[].DesignVolFlowRateWasAutoSized:
                self[].DesignVolFlowRate = DesignVolFlowRateDes
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name, "Design Size Design Flow Rate [m3/s]", DesignVolFlowRateDes)
                if state.dataPlnt.PlantFirstSizesOkayToReport:
                    BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name, "Initial Design Size Design Flow Rate [m3/s]", DesignVolFlowRateDes)
                PlantUtilities.RegisterPlantCompDesignFlow(state, self[].PlantInletNodeNum, self[].DesignVolFlowRate)
            else:
                if self[].DesignVolFlowRate > 0.0 and DesignVolFlowRateDes > 0.0 and state.dataPlnt.PlantFinalSizesOkayToReport:
                    let DesignVolFlowRateUser: Float64 = self[].DesignVolFlowRate
                    BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name, "Design Size Design Flow Rate [m3/s]", DesignVolFlowRateDes, "User-Specified Design Flow Rate [m3/s]", DesignVolFlowRateUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (abs(DesignVolFlowRateDes - DesignVolFlowRateUser) / DesignVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state, "SizeSolarCollector: Potential issue with equipment sizing for " + self[].Name)
                            ShowContinueError(state, "User-Specified Design Flow Rate of " + str(DesignVolFlowRateUser) + " [W]")
                            ShowContinueError(state, "differs from Design Size Design Flow Rate of " + str(DesignVolFlowRateDes) + " [W]")
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        if self[].WorkingFluidType == WorkingFluidEnum.AIR:
            if state.dataSize.CurSysNum > 0:
                if not self[].DesignVolFlowRateWasAutoSized and not SizingDesRunThisAirSys:
                    HardSizeNoDesRun = True
                    if self[].DesignVolFlowRate > 0.0:
                        BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name, "User-Specified Design Flow Rate [m3/s]", self[].DesignVolFlowRate)
                else:
                    CheckSysSizing(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name)
                    let thisFinalSysSizing: auto = state.dataSize.FinalSysSizing[state.dataSize.CurSysNum]
                    if state.dataSize.CurOASysNum > 0:
                        DesignVolFlowRateDes = thisFinalSysSizing.DesOutAirVolFlow
                    else:
                        if state.dataSize.CurDuctType == HVAC.AirDuctType.Main:
                            DesignVolFlowRateDes = thisFinalSysSizing.SysAirMinFlowRat * thisFinalSysSizing.DesMainVolFlow
                        elif state.dataSize.CurDuctType == HVAC.AirDuctType.Cooling:
                            DesignVolFlowRateDes = thisFinalSysSizing.SysAirMinFlowRat * thisFinalSysSizing.DesCoolVolFlow
                        elif state.dataSize.CurDuctType == HVAC.AirDuctType.Heating:
                            DesignVolFlowRateDes = thisFinalSysSizing.DesHeatVolFlow
                        else:
                            DesignVolFlowRateDes = thisFinalSysSizing.DesMainVolFlow
                    let DesMassFlow: Float64 = state.dataEnvrn.StdRhoAir * DesignVolFlowRateDes
                    self[].MaxMassFlowRate = DesMassFlow
                if not HardSizeNoDesRun:
                    if self[].DesignVolFlowRateWasAutoSized:
                        self[].DesignVolFlowRate = DesignVolFlowRateDes
                        BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name, "Design Size Design Flow Rate [m3/s]", DesignVolFlowRateDes)
                        self[].SizingInit = False
                    else:
                        if self[].DesignVolFlowRate > 0.0 and DesignVolFlowRateDes > 0.0:
                            let DesignVolFlowRateUser: Float64 = self[].DesignVolFlowRate
                            BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self[].Name, "Design Size Design Flow Rate [m3/s]", DesignVolFlowRateDes, "User-Specified Design Flow Rate [m3/s]", DesignVolFlowRateUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(DesignVolFlowRateDes - DesignVolFlowRateUser) / DesignVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, "SizeSolarCollector: Potential issue with equipment sizing for " + self[].Name)
                                    ShowContinueError(state, "User-Specified Design Flow Rate of " + str(DesignVolFlowRateUser) + " [W]")
                                    ShowContinueError(state, "differs from Design Size Design Flow Rate of " + str(DesignVolFlowRateDes) + " [W]")
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def control(self: Pointer[Self], state: EnergyPlusData):
        if self[].WorkingFluidType == WorkingFluidEnum.AIR:
            if (self[].ModelType == PVTModelType.Simple) or (self[].ModelType == PVTModelType.BIPVT):
                if state.dataHeatBal.SurfQRadSWOutIncident[self[].SurfNum] > DataPhotovoltaics.MinIrradiance:
                    if state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint > state.dataLoopNodes.Node[self[].HVACInletNodeNum].Temp:
                        self[].HeatingUseful = True
                        self[].CoolingUseful = False
                        self[].BypassDamperOff = True
                    else:
                        self[].HeatingUseful = False
                        self[].CoolingUseful = True
                        self[].BypassDamperOff = False
                else:
                    if state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint < state.dataLoopNodes.Node[self[].HVACInletNodeNum].Temp:
                        self[].CoolingUseful = True
                        self[].HeatingUseful = False
                        self[].BypassDamperOff = True
                    else:
                        self[].CoolingUseful = False
                        self[].HeatingUseful = True
                        self[].BypassDamperOff = False
        elif self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
            if self[].ModelType == PVTModelType.Simple:
                if state.dataHeatBal.SurfQRadSWOutIncident[self[].SurfNum] > DataPhotovoltaics.MinIrradiance:
                    self[].HeatingUseful = True
                    self[].BypassDamperOff = True
                else:
                    self[].CoolingUseful = False
                    self[].BypassDamperOff = False

    def calculate(self: Pointer[Self], state: EnergyPlusData) raises:
        if self[].ModelType == PVTModelType.Simple:
            self[].calculateSimplePVT(state)
        elif self[].ModelType == PVTModelType.BIPVT:
            self[].calculateBIPVT(state)

    def calculateSimplePVT(self: Pointer[Self], state: EnergyPlusData) raises:
        let RoutineName: String = "CalcSimplePVTcollectors"
        var InletNode: Int = 0
        if self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
            InletNode = self[].PlantInletNodeNum
        elif self[].WorkingFluidType == WorkingFluidEnum.AIR:
            InletNode = self[].HVACInletNodeNum
        let mdot: Float64 = self[].MassFlowRate
        let Tinlet: Float64 = state.dataLoopNodes.Node[InletNode].Temp
        var BypassFraction: Float64 = 0.0
        var PotentialOutletTemp: Float64 = 0.0
        if self[].HeatingUseful and self[].BypassDamperOff and (mdot > 0.0):
            var Eff: Float64 = 0.0
            if self[].Simple.ThermEfficMode == ThermEfficEnum.FIXED:
                Eff = self[].Simple.ThermEffic
            elif self[].Simple.ThermEfficMode == ThermEfficEnum.SCHEDULED:
                Eff = self[].Simple.thermEffSched.getCurrentVal()
                self[].Simple.ThermEffic = Eff
            let PotentialHeatGain: Float64 = state.dataHeatBal.SurfQRadSWOutIncident[self[].SurfNum] * Eff * self[].AreaCol
            if self[].WorkingFluidType == WorkingFluidEnum.AIR:
                let Winlet: Float64 = state.dataLoopNodes.Node[InletNode].HumRat
                let CpInlet: Float64 = Psychrommetrics.PsyCpAirFnW(Winlet)
                if mdot * CpInlet > 0.0:
                    PotentialOutletTemp = Tinlet + PotentialHeatGain / (mdot * CpInlet)
                else:
                    PotentialOutletTemp = Tinlet
                if PotentialOutletTemp > state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint:
                    if Tinlet != PotentialOutletTemp:
                        BypassFraction = (state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint - PotentialOutletTemp) / (Tinlet - PotentialOutletTemp)
                    else:
                        BypassFraction = 0.0
                    BypassFraction = max(0.0, BypassFraction)
                    PotentialOutletTemp = state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint
                    PotentialHeatGain = mdot * Psychrommetrics.PsyCpAirFnW(Winlet) * (PotentialOutletTemp - Tinlet)
                else:
                    BypassFraction = 0.0
            elif self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
                let CpInlet: Float64 = Psychrommetrics.CPHW(Tinlet)
                if mdot * CpInlet != 0.0:
                    PotentialOutletTemp = Tinlet + PotentialHeatGain / (mdot * CpInlet)
                else:
                    PotentialOutletTemp = Tinlet
                BypassFraction = 0.0
            self[].Report.ThermHeatGain = PotentialHeatGain
            self[].Report.ThermPower = self[].Report.ThermHeatGain
            self[].Report.ThermEnergy = self[].Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            self[].Report.ThermHeatLoss = 0.0
            self[].Report.TinletWorkFluid = Tinlet
            self[].Report.MdotWorkFluid = mdot
            self[].Report.ToutletWorkFluid = PotentialOutletTemp
            self[].Report.BypassStatus = BypassFraction
        elif self[].CoolingUseful and self[].BypassDamperOff and (mdot > 0.0):
            var HrGround: Float64 = 0.0
            var HrAir: Float64 = 0.0
            var HcExt: Float64 = 0.0
            var HrSky: Float64 = 0.0
            var HrSrdSurf: Float64 = 0.0
            Convect.InitExtConvCoeff(state,
                                      self[].SurfNum,
                                      0.0,
                                      Material.SurfaceRoughness.VerySmooth,
                                      self[].Simple.SurfEmissivity,
                                      self[].Simple.LastCollectorTemp,
                                      HcExt,
                                      HrSky,
                                      HrGround,
                                      HrAir,
                                      HrSrdSurf)
            var WetBulbInlet: Float64 = 0.0
            var DewPointInlet: Float64 = 0.0
            var CpInlet: Float64 = 0.0
            if self[].WorkingFluidType == WorkingFluidEnum.AIR:
                let Winlet: Float64 = state.dataLoopNodes.Node[InletNode].HumRat
                CpInlet = Psychrommetrics.PsyCpAirFnW(Winlet)
                WetBulbInlet = Psychrommetrics.PsyTwbFnTdbWPb(state, Tinlet, Winlet, state.dataEnvrn.OutBaroPress, RoutineName)
                DewPointInlet = Psychrommetrics.PsyTdpFnTdbTwbPb(state, Tinlet, WetBulbInlet, state.dataEnvrn.OutBaroPress, RoutineName)
            elif self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
                CpInlet = Psychrommetrics.CPHW(Tinlet)
            let Tcollector: Float64 = (2.0 * mdot * CpInlet * Tinlet + self[].AreaCol * (HrGround * state.dataEnvrn.OutDryBulbTemp + HrSky * state.dataEnvrn.SkyTemp + HrAir * state.dataSurface.SurfOutDryBulbTemp[self[].SurfNum] + HcExt * state.dataSurface.SurfOutDryBulbTemp[self[].SurfNum])) / (2.0 * mdot * CpInlet + self[].AreaCol * (HrGround + HrSky + HrAir + HcExt))
            PotentialOutletTemp = 2.0 * Tcollector - Tinlet
            self[].Report.ToutletWorkFluid = PotentialOutletTemp
            if self[].WorkingFluidType == WorkingFluidEnum.AIR:
                if PotentialOutletTemp < DewPointInlet:
                    if Tinlet != PotentialOutletTemp:
                        BypassFraction = (DewPointInlet - PotentialOutletTemp) / (Tinlet - PotentialOutletTemp)
                    else:
                        BypassFraction = 0.0
                    BypassFraction = max(0.0, BypassFraction)
                    PotentialOutletTemp = DewPointInlet
            self[].Report.MdotWorkFluid = mdot
            self[].Report.TinletWorkFluid = Tinlet
            self[].Report.ToutletWorkFluid = PotentialOutletTemp
            self[].Report.ThermHeatLoss = mdot * CpInlet * (Tinlet - self[].Report.ToutletWorkFluid)
            self[].Report.ThermHeatGain = 0.0
            self[].Report.ThermPower = -1.0 * self[].Report.ThermHeatLoss
            self[].Report.ThermEnergy = self[].Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            self[].Simple.LastCollectorTemp = Tcollector
            self[].Report.BypassStatus = BypassFraction
        else:
            self[].Report.TinletWorkFluid = Tinlet
            self[].Report.ToutletWorkFluid = Tinlet
            self[].Report.ThermHeatLoss = 0.0
            self[].Report.ThermHeatGain = 0.0
            self[].Report.ThermPower = 0.0
            self[].Report.ThermEnergy = 0.0
            self[].Report.BypassStatus = 1.0
            self[].Report.MdotWorkFluid = mdot

    def calculateBIPVT(self: Pointer[Self], state: EnergyPlusData) raises:
        let RoutineName: String = "CalcBIPVTcollectors"
        let InletNode: Int = self[].HVACInletNodeNum
        let mdot: Float64 = self[].MassFlowRate
        let Tinlet: Float64 = state.dataLoopNodes.Node[InletNode].Temp
        var BypassFraction: Float64 = 0.0
        var PotentialOutletTemp: Float64 = Tinlet
        var PotentialHeatGain: Float64 = 0.0
        var Eff: Float64 = 0.0
        var Tcollector: Float64 = Tinlet
        self[].OperatingMode = PVTMode.Heating
        if self[].HeatingUseful and self[].BypassDamperOff and (self[].BIPVT.availSched.getCurrentVal() > 0.0):
            if (state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint - Tinlet) > 0.1:
                self[].calculateBIPVTMaxHeatGain(state,
                                               state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint,
                                               BypassFraction,
                                               PotentialHeatGain,
                                               PotentialOutletTemp,
                                               Eff,
                                               Tcollector)
                if PotentialHeatGain < 0.0:
                    BypassFraction = 1.0
                    PotentialHeatGain = 0.0
                    PotentialOutletTemp = Tinlet
            self[].Report.ThermHeatGain = PotentialHeatGain
            self[].Report.ThermPower = self[].Report.ThermHeatGain
            self[].Report.ThermEnergy = self[].Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            self[].Report.ThermHeatLoss = 0.0
            self[].Report.TinletWorkFluid = Tinlet
            self[].Report.MdotWorkFluid = mdot
            self[].Report.ToutletWorkFluid = PotentialOutletTemp
            self[].Report.BypassStatus = BypassFraction
            if PotentialHeatGain > 0.0:
                self[].BIPVT.LastCollectorTemp = Tcollector
        elif self[].CoolingUseful and self[].BypassDamperOff and (self[].BIPVT.availSched.getCurrentVal() > 0.0):
            self[].OperatingMode = PVTMode.Cooling
            if (Tinlet - state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint) > 0.1:
                self[].calculateBIPVTMaxHeatGain(state,
                                               state.dataLoopNodes.Node[self[].HVACOutletNodeNum].TempSetPoint,
                                               BypassFraction,
                                               PotentialHeatGain,
                                               PotentialOutletTemp,
                                               Eff,
                                               Tcollector)
                if PotentialHeatGain > 0.0:
                    PotentialHeatGain = 0.0
                    BypassFraction = 1.0
                    PotentialOutletTemp = Tinlet
                else:
                    var WetBulbInlet: Float64 = 0.0
                    var DewPointInlet: Float64 = 0.0
                    var CpInlet: Float64 = 0.0
                    let Winlet: Float64 = state.dataLoopNodes.Node[InletNode].HumRat
                    CpInlet = Psychrommetrics.PsyCpAirFnW(Winlet)
                    WetBulbInlet = Psychrommetrics.PsyTwbFnTdbWPb(state, Tinlet, Winlet, state.dataEnvrn.OutBaroPress, RoutineName)
                    DewPointInlet = Psychrommetrics.PsyTdpFnTdbTwbPb(state, Tinlet, WetBulbInlet, state.dataEnvrn.OutBaroPress, RoutineName)
                    if (PotentialOutletTemp < DewPointInlet) and ((Tinlet - DewPointInlet) > 0.1):
                        self[].calculateBIPVTMaxHeatGain(state, DewPointInlet, BypassFraction, PotentialHeatGain, PotentialOutletTemp, Eff, Tcollector)
                        PotentialOutletTemp = DewPointInlet
            else:
                PotentialHeatGain = 0.0
                BypassFraction = 1.0
                PotentialOutletTemp = Tinlet
            self[].Report.MdotWorkFluid = mdot
            self[].Report.TinletWorkFluid = Tinlet
            self[].Report.ToutletWorkFluid = PotentialOutletTemp
            self[].Report.ThermHeatLoss = -PotentialHeatGain
            self[].Report.ThermHeatGain = 0.0
            self[].Report.ThermPower = -1.0 * self[].Report.ThermHeatLoss
            self[].Report.ThermEnergy = self[].Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            if PotentialHeatGain < 0.0:
                self[].BIPVT.LastCollectorTemp = Tcollector
            self[].Report.BypassStatus = BypassFraction
        else:
            self[].Report.TinletWorkFluid = Tinlet
            self[].Report.ToutletWorkFluid = Tinlet
            self[].Report.ThermHeatLoss = 0.0
            self[].Report.ThermHeatGain = 0.0
            self[].Report.ThermPower = 0.0
            self[].Report.ThermEnergy = 0.0
            self[].Report.BypassStatus = 1.0
            self[].Report.MdotWorkFluid = mdot

    def calculateBIPVTMaxHeatGain(self: Pointer[Self], state: EnergyPlusData, tsp: Float64, bfr: Float64, q: Float64, tmixed: Float64, ThEff: Float64, tpv: Float64) raises:
        let pi: Float64 = Constant.Pi
        let l: Float64 = state.dataSurface.Surface[self[].SurfNum].Height
        let w: Float64 = state.dataSurface.Surface[self[].SurfNum].Width
        let depth_channel: Float64 = self[].BIPVT.PVEffGapWidth
        let slope: Float64 = (pi / 180.0) * state.dataSurface.Surface[self[].SurfNum].Tilt
        var beta: Float64 = 0.0
        let surf_azimuth: Float64 = state.dataSurface.Surface[self[].SurfNum].Azimuth
        let fcell: Float64 = self[].BIPVT.PVCellAreaFract
        let glass_thickness: Float64 = self[].BIPVT.ThGlass
        let area_pv: Float64 = w * l * self[].BIPVT.PVAreaFract
        let area_wall_total: Float64 = w * l
        var length_conv: Float64 = l
        let shape_bld_surf: DataSurfaces.SurfaceShape = state.dataSurface.Surface[self[].SurfNum].Shape
        if shape_bld_surf != DataSurfaces.SurfaceShape.Rectangle:
            ShowFatalError(state, "BIPVT is located on non-rectangular surface. Surface name = " + state.dataSurface.Surface[self[].SurfNum].Name + ". BIPVT model requires rectangular surface.")
        let emiss_b: Float64 = self[].BIPVT.BackMatEmiss
        let emiss_2: Float64 = 0.85
        let emiss_pvg: Float64 = self[].BIPVT.PVGEmiss
        let rpvg_pv: Float64 = self[].BIPVT.PVRTop
        let rpv_1: Float64 = self[].BIPVT.PVRBot
        let taoalpha_back: Float64 = self[].BIPVT.BackMatTranAbsProduct
        let taoalpha_pv: Float64 = self[].BIPVT.PVCellTransAbsProduct
        let taoaplha_cladding: Float64 = self[].BIPVT.CladTranAbsProduct
        let refrac_index_glass: Float64 = self[].BIPVT.RIndGlass
        let k_glass: Float64 = self[].BIPVT.ECoffGlass
        var eff_pv: Float64 = 0.0
        var g: Float64 = 0.0
        var tsurr: Float64
        var tsurrK: Float64
        var t1: Float64
        var t1K: Float64
        var t1_new: Float64
        var tpv_new: Float64
        var tpvg: Float64
        var tpvgK: Float64
        var tpvg_new: Float64
        var tfavg: Float64 = 18.0
        var tfout: Float64
        var hconvf1: Float64 = 100.0
        var hconvf2: Float64 = 100.0
        var hconvt_nat: Float64 = 0.0
        var hconvt_forced: Float64 = 0.0
        var hconvt: Float64 = 0.0
        var hpvg_pv: Float64
        var hpv_1: Float64
        var hrad12: Float64
        var hrad_surr: Float64
        let sigma: Float64 = 5.67e-8
        var reynolds: Float64 = 0.0
        var nusselt: Float64 = 0.0
        var vel: Float64 = 0.0
        var raleigh: Float64 = 0.0
        var dhyd: Float64 = 0.0
        let gravity: Float64 = 9.81
        var mu_air: Float64 = 22.7e-6
        var k_air: Float64 = 0.026
        var prandtl_air: Float64 = 0.7
        var density_air: Float64 = 1.2
        var diffusivity_air: Float64 = 0.0
        var kin_viscosity_air: Float64 = 0.0
        var extHTCcoeff: Float64 = 0.0
        var extHTCexp: Float64 = 0.0
        let InletNode: Int = self[].HVACInletNodeNum
        let tfin: Float64 = state.dataLoopNodes.Node[InletNode].Temp
        let w_in: Float64 = state.dataLoopNodes.Node[InletNode].HumRat
        let cp_in: Float64 = Psychrommetrics.PsyCpAirFnW(w_in)
        let tamb: Float64 = state.dataEnvrn.OutDryBulbTemp
        let wamb: Float64 = state.dataEnvrn.OutHumRat
        let cp_amb: Float64 = Psychrommetrics.PsyCpAirFnW(wamb)
        var t_film: Float64 = 20.0
        let tsky: Float64 = state.dataEnvrn.SkyTemp
        let v_wind: Float64 = state.dataEnvrn.WindSpeed
        let wind_dir: Float64 = state.dataEnvrn.WindDir
        let t2: Float64 = state.dataHeatBalSurf.SurfTempOut[self[].SurfNum]
        var t2K: Float64
        let mdot: Float64 = self[].MassFlowRate
        var mdot_bipvt: Float64 = mdot
        var mdot_bipvt_new: Float64 = mdot
        var s: Float64 = 0.0
        var s1: Float64 = 0.0
        var k_taoalpha_beam: Float64 = 0.0
        var k_taoalpha_sky: Float64 = 0.0
        var k_taoalpha_ground: Float64 = 0.0
        var iam_pv_beam: Float64 = 1.0
        var iam_back_beam: Float64 = 1.0
        var iam_pv_sky: Float64 = 1.0
        var iam_back_sky: Float64 = 1.0
        var iam_pv_ground: Float64 = 1.0
        var iam_back_ground: Float64 = 1.0
        var theta_sky: Float64 = 0.0 * pi / 180.0
        var theta_ground: Float64 = 0.0 * pi / 180.0
        var theta_beam: Float64 = acos(state.dataHeatBal.SurfCosIncidenceAngle[self[].SurfNum])
        var wind_incidence: Float64 = 0.0
        let small_num: Float64 = 1.0e-10
        var a: Float64 = 0.0
        var b: Float64 = 0.0
        var c: Float64 = 0.0
        var d: Float64 = 0.0
        var e: Float64 = 0.0
        var err_tpvg: Float64 = 1.0
        var err_tpv: Float64 = 1.0
        var err_t1: Float64 = 1.0
        var err_mdot_bipvt: Float64 = 1.0
        let tol: Float64 = 1.0e-3
        let rf: Float64 = 0.75
        let degc_to_kelvin: Float64 = 273.15
        var ebal1: Float64
        var ebal2: Float64
        var ebal3: Float64
        var jj: Array[Float64] = Array[Float64](9, 0.0)
        var f: Array[Float64] = Array[Float64](3, 0.0)
        var y: Array[Float64] = Array[Float64](3, 0.0)
        let m: Int = 3
        var i: Int
        var iter: Int = 0
        emiss_2 = state.dataConstruction.Construct[state.dataSurface.Surface[self[].SurfNum].Construction].OutsideAbsorpThermal
        theta_ground = (pi / 180) * (90 - 0.5788 * (slope * 180 / pi) + 0.002693 * pow((slope * 180 / pi), 2))
        theta_sky = (pi / 180) * (59.7 - 0.1388 * (slope * 180 / pi) + 0.001497 * pow((slope * 180 / pi), 2))
        t1 = (tamb + t2) / 2.0
        tpv = (tamb + t2) / 2.0
        tpvg = (tamb + t2) / 2.0
        hpvg_pv = 1.0 / rpvg_pv
        hpv_1 = 1.0 / rpv_1
        k_taoalpha_beam = self[].calc_k_taoalpha(theta_beam, glass_thickness, refrac_index_glass, k_glass)
        iam_back_beam = k_taoalpha_beam
        iam_pv_beam = k_taoalpha_beam
        k_taoalpha_sky = self[].calc_k_taoalpha(theta_sky, glass_thickness, refrac_index_glass, k_glass)
        iam_back_sky = k_taoalpha_sky
        iam_pv_sky = k_taoalpha_sky
        k_taoalpha_ground = self[].calc_k_taoalpha(theta_ground, glass_thickness, refrac_index_glass, k_glass)
        iam_back_ground = k_taoalpha_sky
        iam_pv_ground = k_taoalpha_sky
        tsurrK = pow((pow((tamb + 273.15), 4) * 0.5 * (1 - cos(slope)) + pow((tsky + 273.15), 4) * 0.5 * (1 + cos(slope))), 0.25)
        tsurr = tsurrK - degc_to_kelvin
        tpvgK = tpvg + degc_to_kelvin
        hrad_surr = sigma * emiss_pvg * (pow(tsurrK, 2) + pow(tpvgK, 2)) * (tsurrK + tpvgK)
        dhyd = 4 * w * l / (2 * (w + l))
        tmixed = tfin
        bfr = 0.0
        q = 0.0
        while (err_t1 > tol) or (err_tpv > tol) or (err_tpvg > tol) or (err_mdot_bipvt > tol):
            t_film = (tamb + tpvg) * 0.5
            mu_air = 0.0000171 * pow(((t_film + 273.15) / 273.0), 1.5) * ((273.0 + 110.4) / ((t_film + 273.15) + 110.4))
            k_air = 0.000000000015207 * pow(t_film + 273.15, 3.0) - 0.000000048574 * pow(t_film + 273.15, 2.0) + 0.00010184 * (t_film + 273.15) - 0.00039333
            density_air = 101.3 / (0.287 * (t_film + 273.15))
            diffusivity_air = k_air / (cp_amb * density_air)
            kin_viscosity_air = mu_air / density_air
            raleigh = (gravity * (1.0 / (0.5 * (tamb + tpvg) + 273.15)) * max(0.000001, abs(tpvg - tamb)) * pow(dhyd, 3)) / (diffusivity_air * kin_viscosity_air)
            hconvt_nat = 0.15 * pow(raleigh, 0.333) * k_air / dhyd
            wind_incidence = abs(wind_dir - surf_azimuth)
            if (wind_incidence - 180.0) > 0.001:
                wind_incidence -= 360.0
            if slope > 75.0 * pi / 180.0:
                if wind_incidence <= 45:
                    extHTCcoeff = 10.9247
                    extHTCexp = 0.6434
                    length_conv = dhyd
                elif wind_incidence > 45.0 and wind_incidence <= 135.0:
                    extHTCcoeff = 8.8505
                    extHTCexp = 0.6765
                    length_conv = w
                else:
                    extHTCcoeff = 7.5141
                    extHTCexp = 0.6235
                    length_conv = dhyd
            else:
                if wind_incidence <= 90.0:
                    extHTCcoeff = 7.7283
                    extHTCexp = 0.7586
                    length_conv = l
                else:
                    extHTCcoeff = 5.6217
                    extHTCexp = 0.6569
                    length_conv = l
            hconvt_forced = extHTCcoeff * pow(v_wind, extHTCexp) / pow(l, 1.0 - extHTCexp)
            hconvt = pow((pow(hconvt_forced, 3.0) + pow(hconvt_nat, 3.0)), 1.0 / 3.0)
            if state.dataPhotovoltaic.PVarray[self[].PVnum].PVModelType == DataPhotovoltaics.PVModel.Simple:
                eff_pv = state.dataPhotovoltaic.PVarray[self[].PVnum].SimplePVModule.PVEfficiency
            elif state.dataPhotovoltaic.PVarray[self[].PVnum].PVModelType == DataPhotovoltaics.PVModel.Sandia:
                eff_pv = state.dataPhotovoltaic.PVarray[self[].PVnum].SNLPVCalc.EffMax
            elif state.dataPhotovoltaic.PVarray[self[].PVnum].PVModelType == DataPhotovoltaics.PVModel.TRNSYS:
                eff_pv = state.dataPhotovoltaic.PVarray[self[].PVnum].TRNSYSPVcalc.ArrayEfficiency
            g = state.dataHeatBal.SurfQRadSWOutIncidentBeam[self[].SurfNum] * iam_pv_beam + state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse[self[].SurfNum] * iam_pv_sky + state.dataHeatBal.SurfQRadSWOutIncidentGndDiffuse[self[].SurfNum] * iam_pv_ground
            s = g * taoalpha_pv * fcell * area_pv / area_wall_total - g * eff_pv * area_pv / area_wall_total
            s1 = taoalpha_back * g * (1.0 - fcell) * (area_pv / area_wall_total) + taoaplha_cladding * g * (1 - area_pv / area_wall_total)
            mu_air = 0.0000171 * pow(((tfavg + 273.15) / 273.0), 1.5) * ((273.0 + 110.4) / ((tfavg + 273.15) + 110.4))
            k_air = 0.000000000015207 * pow(tfavg + 273.15, 3.0) - 0.000000048574 * pow(tfavg + 273.15, 2.0) + 0.00010184 * (tfavg + 273.15) - 0.00039333
            prandtl_air = 0.680 + 0.000000469 * pow(tfavg + 273.15 - 540.0, 2.0)
            density_air = 101.3 / (0.287 * (tfavg + 273.15))
            diffusivity_air = k_air / (cp_in * density_air)
            kin_viscosity_air = mu_air / density_air
            t1K = t1 + degc_to_kelvin
            t2K = t2 + degc_to_kelvin
            tpvgK = tpvg + degc_to_kelvin
            hrad12 = sigma * (pow(t1K, 2) + pow(t2K, 2)) * (t1K + t2K) / (1 / emiss_b + 1 / emiss_2 - 1)
            hrad_surr = sigma * emiss_pvg * (pow(tsurrK, 2) + pow(tpvgK, 2)) * (tsurrK + tpvgK)
            if mdot_bipvt > 0.0:
                vel = mdot_bipvt / (density_air * w * depth_channel)
                reynolds = density_air * vel * (4 * w * depth_channel / (2 * (w + depth_channel))) / mu_air
                nusselt = 0.052 * pow(reynolds, 0.78) * pow(prandtl_air, 0.4)
                hconvf1 = k_air * nusselt / (4 * w * depth_channel / (2 * (w + depth_channel)))
                nusselt = 1.017 * pow(reynolds, 0.471) * pow(prandtl_air, 0.4)
                hconvf2 = k_air * nusselt / (4 * w * depth_channel / (2 * (w + depth_channel)))
                a = -(w / (mdot_bipvt * cp_in)) * (hconvf1 + hconvf2)
                b = (w / (mdot_bipvt * cp_in)) * (hconvf1 * t1 + hconvf2 * t2)
                tfavg = (1.0 / (a * l)) * (tfin + b / a) * (exp(a * l) - 1.0) - b / a
            else:
                raleigh = (gravity * (1.0 / (tfavg + 273.15)) * max(0.000001, abs(t1 - t2)) * pow(depth_channel, 3)) / (diffusivity_air * kin_viscosity_air)
                if slope > 75.0 * pi / 180.0:
                    beta = 75.0 * pi / 180.0
                else:
                    beta = slope
                nusselt = 1.0 + 1.44 * (1.0 - 1708.0 * pow(sin(1.8 * beta), 1.6) / raleigh / cos(beta)) * max(0.0, 1.0 - 1708.0 / raleigh / cos(beta)) + max(0.0, (pow((raleigh * cos(beta) / 5830.0), 1.0 / 3.0) - 1.0))
                hconvf1 = 2.0 * k_air * nusselt / depth_channel
                hconvf2 = hconvf1
                c = s + s1 + hconvt * (tamb - tpvg) + hrad_surr * (tsurr - tpvg) + hrad12 * (t2 - t1)
                d = c + hconvf2 * t2
                e = -hconvf2
                tfavg = -d / e
            tfavg = max(tfavg, -50.0)
            for i in range(m):
                f[i] = 0.0
                y[i] = 0.0
            for i in range(9):
                jj[i] = 0.0
            jj[0] = hconvt + hrad_surr + hpvg_pv
            jj[1] = -hpvg_pv
            jj[2] = 0.0
            jj[3] = hpvg_pv
            jj[4] = -hpv_1 - hpvg_pv
            jj[5] = hpv_1
            jj[6] = 0.0
            jj[7] = hpv_1
            jj[8] = -hpv_1 - hconvf1 - hrad12
            f[0] = hconvt * tamb + hrad_surr * tsurr
            f[1] = -s
            f[2] = -s1 - hconvf1 * tfavg - hrad12 * t2
            self[].solveLinSysBackSub(jj, f, y)
            tpvg_new = y[0]
            tpv_new = y[1]
            t1_new = y[2]
            if mdot > 0.0:
                tfout = (tfin + b / a) * exp(a * l) - b / a
                if ((self[].OperatingMode == PVTMode.Heating) and (q > 0.0) and (tmixed > tsp) and (tfin < tsp)) or ((self[].OperatingMode == PVTMode.Cooling) and (q < 0.0) and (tmixed < tsp) and (tfin > tsp)):
                    bfr = (tsp - tfout) / (tfin - tfout)
                    bfr = max(0.0, bfr)
                    bfr = min(1.0, bfr)
                elif ((self[].OperatingMode == PVTMode.Heating) and (q > 0.0) and (tmixed > tsp) and (tfin >= tsp)) or ((self[].OperatingMode == PVTMode.Cooling) and (q < 0.0) and (tmixed < tsp) and (tfin <= tsp)):
                    bfr = 1.0
                    tfout = tfin
            else:
                tfout = tfin
            tmixed = bfr * tfin + (1.0 - bfr) * tfout
            mdot_bipvt_new = (1.0 - bfr) * mdot
            err_tpvg = abs((tpvg_new - tpvg) / (tpvg + small_num))
            err_tpv = abs((tpv_new - tpv) / (tpv + small_num))
            err_t1 = abs((t1_new - t1) / (t1 + small_num))
            err_mdot_bipvt = abs((mdot_bipvt_new - mdot_bipvt) / (mdot_bipvt + small_num))
            tpvg = tpvg + rf * (tpvg_new - tpvg)
            tpv = tpv + rf * (tpv_new - tpv)
            t1 = t1 + rf * (t1_new - t1)
            mdot_bipvt = mdot_bipvt + rf * (mdot_bipvt_new - mdot_bipvt)
            q = mdot_bipvt * cp_in * (tfout - tfin)
            ebal1 = s1 + hpv_1 * (tpv - t1) + hconvf1 * (tfavg - t1) + hrad12 * (t2 - t1)
            ebal2 = s + hpvg_pv * (tpvg - tpv) + hpv_1 * (t1 - tpv)
            ebal3 = hconvt * (tpvg - tamb) + hrad_surr * (tpvg - tsurr) + hpvg_pv * (tpvg - tpv)
            iter += 1
            if iter == 50:
                ShowSevereError(state, "Function PVTCollectorStruct::calculateBIPVTMaxHeatGain: Maximum number of iterations 50 reached")
                break
        ThEff = 0.0
        if (q > small_num) and (state.dataHeatBal.SurfQRadSWOutIncident[self[].SurfNum] > small_num):
            ThEff = q / (area_wall_total * state.dataHeatBal.SurfQRadSWOutIncident[self[].SurfNum] + small_num)
        self[].BIPVT.Tcoll = t1
        self[].BIPVT.HrPlen = hrad12
        self[].BIPVT.Tplen = tfavg
        self[].BIPVT.HcPlen = hconvf2

    def solveLinSysBackSub(self: Pointer[Self], jj: Array[Float64], f: Array[Float64], y: Array[Float64]):
        var p: Int
        let m: Int = 3
        let small: Float64 = 1.0e-10
        for i in range(m):
            y[i] = 0.0
        for i in range(m-1):
            var coeff_not_zero: Bool = False
            for j in range(i, m):
                if abs(jj[j * m + i]) > small:
                    coeff_not_zero = True
                    p = j
                    break
            if coeff_not_zero:
                if p != i:
                    let dummy2: Float64 = f[i]
                    f[i] = f[p]
                    f[p] = dummy2
                    for j in range(m):
                        let dummy1: Float64 = jj[i * m + j]
                        jj[i * m + j] = jj[p * m + j]
                        jj[p * m + j] = dummy1
                for j in range(i+1, m):
                    if abs(jj[i * m + i]) < small:
                        jj[i * m + i] = small
                    let mm: Float64 = jj[j * m + i] / jj[i * m + i]
                    f[j] = f[j] - mm * f[i]
                    for k in range(m):
                        jj[j * m + k] = jj[j * m + k] - mm * jj[i * m + k]
        if abs(jj[(m-1) * m + m-1]) < small:
            jj[(m-1) * m + m-1] = small
        y[m-1] = f[m-1] / jj[(m-1) * m + m-1]
        var sum: Float64 = 0.0
        for i in range(m-1):
            let ii: Int = m - 2 - i
            for j in range(ii, m):
                sum = sum + jj[ii * m + j] * y[j]
            if abs(jj[ii * m + ii]) < small:
                jj[ii * m + ii] = small
            y[ii] = (f[ii] - sum) / jj[ii * m + ii]
            sum = 0.0

    def calc_taoalpha(self: Pointer[Self], theta: Float64, glass_thickness: Float64, refrac_index_glass: Float64, k_glass: Float64) -> Float64:
        var theta_r: Float64 = 0.0
        var taoalpha: Float64 = 0.0
        var theta_adj: Float64 = theta
        if theta_adj == 0.0:
            theta_adj = 0.000000001
        theta_r = asin(sin(theta_adj) / refrac_index_glass)
        taoalpha = exp(-k_glass * glass_thickness / cos(theta_r)) * (1 - 0.5 * ((pow(sin(theta_r - theta_adj), 2) / pow(sin(theta_r + theta_adj), 2)) + (pow(tan(theta_r - theta_adj), 2) / pow(tan(theta_r + theta_adj), 2))))
        return taoalpha

    def calc_k_taoalpha(self: Pointer[Self], theta: Float64, glass_thickness: Float64, refrac_index_glass: Float64, k_glass: Float64) -> Float64:
        var taoalpha: Float64 = 0.0
        var taoalpha_zero: Float64 = 0.0
        var k_taoalpha: Float64 = 0.0
        taoalpha = self[].calc_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
        taoalpha_zero = self[].calc_taoalpha(0.0, glass_thickness, refrac_index_glass, k_glass)
        k_taoalpha = taoalpha / taoalpha_zero
        return k_taoalpha

    def update(self: Pointer[Self], state: EnergyPlusData):
        if self[].WorkingFluidType == WorkingFluidEnum.LIQUID:
            let InletNode: Int = self[].PlantInletNodeNum
            let OutletNode: Int = self[].PlantOutletNodeNum
            PlantUtilities.SafeCopyPlantNode(state, InletNode, OutletNode)
            state.dataLoopNodes.Node[OutletNode].Temp = self[].Report.ToutletWorkFluid
        elif self[].WorkingFluidType == WorkingFluidEnum.AIR:
            let InletNode: Int = self[].HVACInletNodeNum
            let OutletNode: Int = self[].HVACOutletNodeNum
            state.dataLoopNodes.Node[OutletNode].Quality = state.dataLoopNodes.Node[InletNode].Quality
            state.dataLoopNodes.Node[OutletNode].Press = state.dataLoopNodes.Node[InletNode].Press
            state.dataLoopNodes.Node[OutletNode].MassFlowRate = state.dataLoopNodes.Node[InletNode].MassFlowRate
            state.dataLoopNodes.Node[OutletNode].Mass
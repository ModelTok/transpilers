// Mojo translation of EnergyPlus ChillerElectricEIR.cc with header context

// Import required modules (assumed to exist at corresponding paths)
from DataGlobals import *
from .Data.BaseData import BaseGlobalStruct
from .Plant.DataPlant import *
from .Plant.PlantLocation import *
from PlantComponent import PlantComponent
from .Autosizing.All_Simple_Sizing import *
from BranchNodeConnections import *
from CurveManager import Curve
from .Data.EnergyPlusData import *
from DataBranchAirLoopPlant import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataIPShortCuts import *
from DataLoopNode import Node
from DataSizing import *
from EMSManager import *
from FaultsManager import *
from FluidProperties import *
from Formatters import *
from General import *
from GeneralRoutines import *
from GlobalNames import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutAirNodeManager import *
from OutputProcessor import *
from OutputReportPredefined import *
from PlantUtilities import *
from Psychrometrics import *
from ScheduleManager import Sched
from StandardRatings import *
from UtilityRoutines import *
from Fmath import *  // from ObjexxFCL? Not needed, using built-in math
from string.functions import *  // for len, etc.
from  import Constant, HVAC, DataBranchAirLoopPlant
from DataPlant import DataPlant
from DataLoopNode import Node
from DataSizing import DataSizing
from OutputProcessor import OutputProcessor
from .Plant.DataPlant import DataPlant
from .Plant.PlantLocation import PlantLocation
from PlantUtilities import *
from Psychrometrics import *
from ScheduleManager import Sched
from StandardRatings import *
from UtilityRoutines import *
from EMSManager import *
from FaultsManager import *
from Formatters import *
from OutputReportPredefined import *

// Type aliases
alias Real64 = Float64
alias EnergyPlusData = Pointer[UInt8]  // Placeholder, real type from imports

// Forward declarations for enums used in the code
// Already imported via DataPlant, etc.

// --- Struct from header: ElectricEIRChillerSpecs ---
@value
struct ElectricEIRChillerSpecs(PlantComponent):
    var Name: String  # User identifier
    var TypeNum: Int = 0  # plant loop type identifier
    var CondenserType: DataPlant.CondenserType = DataPlant.CondenserType.Invalid  # Type of Condenser - Air Cooled, Water Cooled or Evap Cooled
    var RefCap: Real64 = 0.0  # Reference capacity of chiller [W]
    var RefCapWasAutoSized: Bool = False  # reference capacity was autosized on input
    var RefCOP: Real64 = 0.0  # Reference coefficient of performance [W/W]
    var FlowMode: DataPlant.FlowMode = DataPlant.FlowMode.Invalid  # one of 3 modes for component flow during operation
    var CondenserFlowControl: DataPlant.CondenserFlowControl = DataPlant.CondenserFlowControl.Invalid
    var ModulatedFlowSetToLoop: Bool = False  # True if the setpoint is missing at the outlet node
    var ModulatedFlowErrDone: Bool = False  # true if setpoint warning issued
    var HRSPErrDone: Bool = False  # TRUE if set point warning issued for heat recovery loop
    var EvapVolFlowRate: Real64 = 0.0  # Reference water volumetric flow rate through the evaporator [m3/s]
    var EvapVolFlowRateWasAutoSized: Bool = False  # true if previous was autosize input
    var EvapMassFlowRate: Real64 = 0.0
    var EvapMassFlowRateMax: Real64 = 0.0  # Reference water mass flow rate through evaporator [kg/s]
    var CondVolFlowRate: Real64 = 0.0  # Reference water volumetric flow rate through the condenser [m3/s]
    var CondVolFlowRateWasAutoSized: Bool = False  # true if previous was set to autosize on input
    var CondMassFlowRate: Real64 = 0.0  # Condenser mass flow rate [kg/s]
    var CondMassFlowRateMax: Real64 = 0.0  # Reference water mass flow rate through condenser [kg/s]
    var CondenserFanPowerRatio: Real64 = 0.0  # Reference power of condenser fan to capacity ratio, W/W
    var CompPowerToCondenserFrac: Real64 = 0.0  # Fraction of compressor electric power rejected by condenser [0 to 1]
    var EvapInletNodeNum: Int = 0  # Node number on the inlet side of the plant (evaporator side)
    var EvapOutletNodeNum: Int = 0  # Node number on the outlet side of the plant (evaporator side)
    var EvapOutletTemp: Real64 = 0.0  # Evaporator outlet temperature [C]
    var CondInletNodeNum: Int = 0  # Node number on the inlet side of the condenser
    var CondOutletNodeNum: Int = 0  # Node number on the outlet side of the condenser
    var CondOutletTemp: Real64 = 0.0  # Condenser outlet temperature [C]
    var CondOutletHumRat: Real64 = 0.0  # Condenser outlet humidity ratio [kg/kg]
    var MinPartLoadRat: Real64 = 0.0  # Minimum allowed operating fraction of full load
    var MaxPartLoadRat: Real64 = 0.0  # Maximum allowed operating fraction of full load
    var OptPartLoadRat: Real64 = 0.0  # Optimal operating fraction of full load
    var MinUnloadRat: Real64 = 0.0  # Minimum unloading ratio
    var TempRefCondIn: Real64 = 0.0  # The reference secondary loop fluid temperature
    var TempRefEvapOut: Real64 = 0.0  # The reference primary loop fluid temperature
    var TempLowLimitEvapOut: Real64 = 0.0  # Low temperature shut off [C]
    var DesignHeatRecVolFlowRate: Real64 = 0.0  # Design water volumetric flow rate through heat recovery loop [m3/s]
    var DesignHeatRecVolFlowRateWasAutoSized: Bool = False  # true if previous input was autosize
    var DesignHeatRecMassFlowRate: Real64 = 0.0  # Design water mass flow rate through heat recovery loop [kg/s]
    var SizFac: Real64 = 0.0  # sizing factor
    var BasinHeaterPowerFTempDiff: Real64 = 0.0  # Basin heater capacity per degree C below setpoint (W/C)
    var BasinHeaterSetPointTemp: Real64 = 0.0  # setpoint temperature for basin heater operation (C)
    var HeatRecActive: Bool = False  # True when entered Heat Rec Vol Flow Rate > 0
    var HeatRecInletNodeNum: Int = 0  # Node number for the heat recovery inlet side of the condenser
    var HeatRecOutletNodeNum: Int = 0  # Node number for the heat recovery outlet side of the condenser
    var HeatRecCapacityFraction: Real64 = 0.0  # user input for heat recovery capacity fraction []
    var HeatRecMaxCapacityLimit: Real64 = 0.0  # Capacity limit for Heat recovery, one time calc [W]
    var HeatRecSetPointNodeNum: Int = 0  # index for system node with the heat recover leaving setpoint
    var heatRecInletLimitSched: Sched.Schedule? = None  # schedule for the inlet high limit for heat recovery operation
    var ChillerCapFTIndex: Int = 0  # Index for the total cooling capacity modifier curve
    var ChillerEIRFTIndex: Int = 0  # Index for the energy input ratio modifier curve
    var ChillerEIRFPLRIndex: Int = 0  # Index for the EIR vs part-load ratio curve
    var ChillerCapFTError: Int = 0  # Used for negative capacity as a function of temp warnings
    var ChillerCapFTErrorIndex: Int = 0  # Used for negative capacity as a function of temp warnings
    var ChillerEIRFTError: Int = 0  # Used for negative EIR as a function of temp warnings
    var ChillerEIRFTErrorIndex: Int = 0  # Used for negative EIR as a function of temp warnings
    var ChillerEIRFPLRError: Int = 0  # Used for negative EIR as a function of PLR warnings
    var ChillerEIRFPLRErrorIndex: Int = 0  # Used for negative EIR as a function of PLR warnings
    var ChillerEIRFPLRMin: Real64 = 0.0  # Minimum value of PLR from EIRFPLR curve
    var ChillerEIRFPLRMax: Real64 = 0.0  # Maximum value of PLR from EIRFPLR curve
    var DeltaTErrCount: Int = 0  # Evaporator delta T equals 0 for variable flow chiller warning messages
    var DeltaTErrCountIndex: Int = 0  # Index to evaporator delta T = 0 for variable flow chiller warning messages
    var CWPlantLoc: PlantLocation  # chilled water plant loop component index
    var CDPlantLoc: PlantLocation  # condenser water plant loop component index
    var HRPlantLoc: PlantLocation  # heat recovery water plant loop component index
    var basinHeaterSched: Sched.Schedule? = None  # basin heater schedule
    var CondMassFlowIndex: Int = 0
    var MsgBuffer1: String = ""  # - buffer to print warning messages on following time step
    var MsgBuffer2: String = ""  # - buffer to print warning messages on following time step
    var MsgDataLast: Real64 = 0.0  # value of data when warning occurred (passed to Recurring Warn)
    var PrintMessage: Bool = False  # logical to determine if message is valid
    var MsgErrorCount: Int = 0  # number of occurrences of warning
    var ErrCount1: Int = 0  # for recurring error messages
    var PossibleSubcooling: Bool = False  # flag to indicate chiller is doing less cooling that requested
    var FaultyChillerSWTFlag: Bool = False  # True if the chiller has SWT sensor fault
    var FaultyChillerSWTIndex: Int = 0  # Index of the fault object corresponding to the chiller
    var FaultyChillerSWTOffset: Real64 = 0.0  # Chiller SWT sensor offset
    var FaultyChillerFoulingFlag: Bool = False  # True if the chiller has fouling fault
    var FaultyChillerFoulingIndex: Int = 0  # Index of the fault object corresponding to the chiller
    var FaultyChillerFoulingFactor: Real64 = 1.0  # Chiller fouling factor
    var EndUseSubcategory: String = ""  # identifier use for the end use subcategory
    var TimeStepSysLast: Real64 = 0.0
    var CurrentEndTimeLast: Real64 = 0.0
    var oneTimeFlag: Bool = True
    var MyEnvrnFlag: Bool = True
    var EvapWaterConsump: Real64 = 0.0  # Evap cooler water consumption (m3)
    var EvapWaterConsumpRate: Real64 = 0.0  # Evap condenser water consumption rate [m3/s]
    var Power: Real64 = 0.0  # Rate of chiller electric energy use [W]
    var QEvaporator: Real64 = 0.0  # Rate of heat transfer to the evaporator coil [W]
    var QCondenser: Real64 = 0.0  # Rate of heat transfer to the condenser coil [W]
    var QHeatRecovered: Real64 = 0.0  # Rate of heat transfer to the heat recovery coil [W]
    var HeatRecOutletTemp: Real64 = 0.0  # Heat recovery outlet temperature [C]
    var CondenserFanPower: Real64 = 0.0  # Condenser Fan Power (fan cycles with compressor) [W]
    var ChillerCapFT: Real64 = 0.0  # Chiller capacity fraction (evaluated as a function of temperature)
    var ChillerEIRFT: Real64 = 0.0  # Chiller electric input ratio (EIR = 1 / COP) as a function of temperature
    var ChillerEIRFPLR: Real64 = 0.0  # Chiller EIR as a function of part-load ratio (PLR)
    var ChillerPartLoadRatio: Real64 = 0.0  # Chiller part-load ratio (PLR)
    var ChillerCyclingRatio: Real64 = 0.0  # Chiller cycling ratio
    var BasinHeaterPower: Real64 = 0.0  # Basin heater power (W)
    var ChillerFalseLoadRate: Real64 = 0.0  # Chiller false load over and above the water-side load [W]
    var ChillerFalseLoad: Real64 = 0.0  # reporting: Chiller false load over and above water side load [W]
    var Energy: Real64 = 0.0  # reporting: Chiller electric consumption [J]
    var EvapEnergy: Real64 = 0.0  # reporting: Evaporator heat transfer energy [J]
    var CondEnergy: Real64 = 0.0  # reporting: Condenser heat transfer energy [J]
    var CondInletTemp: Real64 = 0.0  # reporting: Condenser inlet temperature [C]
    var EvapInletTemp: Real64 = 0.0  # reporting: Evaporator inlet temperature [C]
    var ActualCOP: Real64 = 0.0  # reporting: Coefficient of performance
    var EnergyHeatRecovery: Real64 = 0.0  # reporting: Energy recovered from water-cooled condenser [J]
    var HeatRecInletTemp: Real64 = 0.0  # reporting: Heat reclaim inlet temperature [C]
    var HeatRecMassFlow: Real64 = 0.0  # reporting: Heat reclaim mass flow rate [kg/s]
    var ChillerCondAvgTemp: Real64 = 0.0  # reporting: average condenser temp for curves with Heat recovery [C]
    var CondenserFanEnergyConsumption: Real64 = 0.0  # reporting: Air-cooled condenser fan energy [J]
    var BasinHeaterConsumption: Real64 = 0.0  # Basin heater energy consumption (J)
    var IPLVFlag: Bool = True
    var ChillerCondLoopFlowFLoopPLRIndex: Int = 0  # Condenser loop flow rate fraction function of loop PLR
    var CondDT: Int = 0  # Temperature difference across condenser
    var condDTSched: Sched.Schedule? = None  # Temperature difference across condenser schedule
    var MinCondFlowRatio: Real64 = 0.2  # Minimum condenser flow fraction
    var EquipFlowCtrl: DataBranchAirLoopPlant.ControlType = DataBranchAirLoopPlant.ControlType.Invalid
    var VSBranchPumpMinLimitMassFlowCond: Real64 = 0.0
    var VSBranchPumpFoundCond: Bool = False
    var VSLoopPumpFoundCond: Bool = False
    var thermosiphonTempCurveIndex: Int = 0
    var thermosiphonMinTempDiff: Real64 = 0.0
    var thermosiphonStatus: Int = 0

    # Static factory method
    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> Pointer[ElectricEIRChillerSpecs]:
        if state.dataChillerElectricEIR.getInputFlag:
            GetElectricEIRChillerInput(state)
            state.dataChillerElectricEIR.getInputFlag = False
        # Find object by name (using linear search, 1-based indexing in original)
        var idx: Int = -1
        for i in range(len(state.dataChillerElectricEIR.ElectricEIRChiller)):
            if state.dataChillerElectricEIR.ElectricEIRChiller[i].Name == objectName:
                idx = i
                break
        if idx != -1:
            return pointer[ElectricEIRChillerSpecs](address_of(state.dataChillerElectricEIR.ElectricEIRChiller[idx]))
        ShowFatalError(state, String.format("LocalElectEIRChillerFactory: Error getting inputs for object named: {}", objectName))
        return None  # LCOV_EXCL_LINE

    # Method implementations follow (to be defined inline)
    def setupOutputVars(mut self, state: EnergyPlusData):
        # Original implementation
        SetupOutputVariable(state, "Chiller Part Load Ratio", Constant.Units.None, self.ChillerPartLoadRatio, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Cycling Ratio", Constant.Units.None, self.ChillerCyclingRatio, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Electricity Rate", Constant.Units.W, self.Power, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Electricity Energy", Constant.Units.J, self.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Cooling, self.EndUseSubcategory)
        SetupOutputVariable(state, "Chiller Evaporator Cooling Rate", Constant.Units.W, self.QEvaporator, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Evaporator Cooling Energy", Constant.Units.J, self.EvapEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Chillers)
        SetupOutputVariable(state, "Chiller False Load Heat Transfer Rate", Constant.Units.W, self.ChillerFalseLoadRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller False Load Heat Transfer Energy", Constant.Units.J, self.ChillerFalseLoad, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Chiller Evaporator Inlet Temperature", Constant.Units.C, self.EvapInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Evaporator Outlet Temperature", Constant.Units.C, self.EvapOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Evaporator Mass Flow Rate", Constant.Units.kg_s, self.EvapMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Condenser Heat Transfer Rate", Constant.Units.W, self.QCondenser, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Condenser Heat Transfer Energy", Constant.Units.J, self.CondEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.HeatRejection)
        SetupOutputVariable(state, "Chiller COP", Constant.Units.W_W, self.ActualCOP, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller Capacity Temperature Modifier Multiplier", Constant.Units.None, self.ChillerCapFT, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller EIR Temperature Modifier Multiplier", Constant.Units.None, self.ChillerEIRFT, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Chiller EIR Part Load Modifier Multiplier", Constant.Units.None, self.ChillerEIRFPLR, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Thermosiphon Status", Constant.Units.None, self.thermosiphonStatus, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        if self.CondenserType == DataPlant.CondenserType.WaterCooled:
            SetupOutputVariable(state, "Chiller Condenser Inlet Temperature", Constant.Units.C, self.CondInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
            SetupOutputVariable(state, "Chiller Condenser Outlet Temperature", Constant.Units.C, self.CondOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
            SetupOutputVariable(state, "Chiller Condenser Mass Flow Rate", Constant.Units.kg_s, self.CondMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
            if self.HeatRecActive:
                SetupOutputVariable(state, "Chiller Total Recovered Heat Rate", Constant.Units.W, self.QHeatRecovered, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
                SetupOutputVariable(state, "Chiller Total Recovered Heat Energy", Constant.Units.J, self.EnergyHeatRecovery, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.HeatRecovery)
                SetupOutputVariable(state, "Chiller Heat Recovery Inlet Temperature", Constant.Units.C, self.HeatRecInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
                SetupOutputVariable(state, "Chiller Heat Recovery Outlet Temperature", Constant.Units.C, self.HeatRecOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
                SetupOutputVariable(state, "Chiller Heat Recovery Mass Flow Rate", Constant.Units.kg_s, self.HeatRecMassFlow, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
                SetupOutputVariable(state, "Chiller Effective Heat Rejection Temperature", Constant.Units.C, self.ChillerCondAvgTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        else:
            SetupOutputVariable(state, "Chiller Condenser Inlet Temperature", Constant.Units.C, self.CondInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
            if self.CondenserFanPowerRatio > 0:
                SetupOutputVariable(state, "Chiller Condenser Fan Electricity Rate", Constant.Units.W, self.CondenserFanPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
                SetupOutputVariable(state, "Chiller Condenser Fan Electricity Energy", Constant.Units.J, self.CondenserFanEnergyConsumption, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Cooling)
            if self.CondenserType == DataPlant.CondenserType.EvapCooled:
                SetupOutputVariable(state, "Chiller Evaporative Condenser Water Volume", Constant.Units.m3, self.EvapWaterConsump, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.Water, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Cooling)
                SetupOutputVariable(state, "Chiller Evaporative Condenser Mains Supply Water Volume", Constant.Units.m3, self.EvapWaterConsump, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.MainsWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Cooling)
                if self.BasinHeaterPowerFTempDiff > 0.0:
                    SetupOutputVariable(state, "Chiller Basin Heater Electricity Rate", Constant.Units.W, self.BasinHeaterPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
                    SetupOutputVariable(state, "Chiller Basin Heater Electricity Energy", Constant.Units.J, self.BasinHeaterConsumption, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Chillers)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSInternalVariable(state, "Chiller Nominal Capacity", self.Name, "[W]", self.RefCap)

    def simulate(mut self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, mut CurLoad: Real64, RunFlag: Bool):
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.initialize(state, RunFlag, CurLoad)
            self.calculate(state, CurLoad, RunFlag)
            self.update(state, CurLoad, RunFlag)
        elif calledFromLocation.loopNum == self.CDPlantLoc.loopNum:
            PlantUtilities.UpdateChillerComponentCondenserSide(state, calledFromLocation.loopNum, self.CDPlantLoc.loopSideNum, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, self.CondInletNodeNum, self.CondOutletNodeNum, self.QCondenser, self.CondInletTemp, self.CondOutletTemp, self.CondMassFlowRate, FirstHVACIteration)
        elif calledFromLocation.loopNum == self.HRPlantLoc.loopNum:
            PlantUtilities.UpdateComponentHeatRecoverySide(state, self.HRPlantLoc.loopNum, self.HRPlantLoc.loopSideNum, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, self.HeatRecInletNodeNum, self.HeatRecOutletNodeNum, self.QHeatRecovered, self.HeatRecInletTemp, self.HeatRecOutletTemp, self.HeatRecMassFlow, FirstHVACIteration)

    def getDesignCapacities(mut self, state: EnergyPlusData, calledFromLocation: PlantLocation, mut MaxLoad: Real64, mut MinLoad: Real64, mut OptLoad: Real64):
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            MinLoad = self.RefCap * self.MinPartLoadRat
            MaxLoad = self.RefCap * self.MaxPartLoadRat
            OptLoad = self.RefCap * self.OptPartLoadRat
        else:
            MinLoad = 0.0
            MaxLoad = 0.0
            OptLoad = 0.0

    def getDesignTemperatures(mut self, mut TempDesCondIn: Real64, mut TempDesEvapOut: Real64):
        TempDesCondIn = self.TempRefCondIn
        TempDesEvapOut = self.TempRefEvapOut

    def getSizingFactor(mut self, mut sizFac: Real64):
        sizFac = self.SizFac

    def onInitLoopEquip(mut self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        var runFlag: Bool = True
        var myLoad: Real64 = 0.0
        self.initialize(state, runFlag, myLoad)
        if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
            self.size(state)

    # Full implementation follows below because of length
    def oneTimeInit(mut self, state: EnergyPlusData):
        self.setupOutputVars(state)
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, self.CWPlantLoc, errFlag, self.TempLowLimitEvapOut, _ , _ , self.EvapInletNodeNum, _)
        if self.CondenserType != DataPlant.CondenserType.AirCooled and self.CondenserType != DataPlant.CondenserType.EvapCooled:
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, self.CDPlantLoc, errFlag, _, _, _, self.CondInletNodeNum, _)
            PlantUtilities.InterConnectTwoPlantLoopSides(state, self.CWPlantLoc, self.CDPlantLoc, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, True)
        if self.HeatRecActive:
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, self.HRPlantLoc, errFlag, _, _, _, self.HeatRecInletNodeNum, _)
            PlantUtilities.InterConnectTwoPlantLoopSides(state, self.CWPlantLoc, self.HRPlantLoc, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, True)
        if self.CondenserType != DataPlant.CondenserType.AirCooled and self.CondenserType != DataPlant.CondenserType.EvapCooled and self.HeatRecActive:
            PlantUtilities.InterConnectTwoPlantLoopSides(state, self.CDPlantLoc, self.HRPlantLoc, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, False)
        if errFlag:
            ShowFatalError(state, "InitElectricEIRChiller: Program terminated due to previous condition(s).")
        if self.FlowMode == DataPlant.FlowMode.Constant:
            DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).FlowPriority = DataPlant.LoopFlowStatus.NeedyIfLoopOn
        if self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated:
            DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).FlowPriority = DataPlant.LoopFlowStatus.NeedyIfLoopOn
            if (state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint == Node.SensedNodeFlagValue) and (state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi == Node.SensedNodeFlagValue):
                if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                    if not self.ModulatedFlowErrDone:
                        ShowWarningError(state, String.format("Missing temperature setpoint for LeavingSetpointModulated mode chiller named {}", self.Name))
                        ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of a chiller in variable flow mode, use a SetpointManager")
                        ShowContinueError(state, "  The overall loop setpoint will be assumed for chiller. The simulation continues ... ")
                        self.ModulatedFlowErrDone = True
                else:
                    var fatalError: Bool = False
                    EMSManager.CheckIfNodeSetPointManagedByEMS(state, self.EvapOutletNodeNum, HVAC.CtrlVarType.Temp, fatalError)
                    state.dataLoopNodes.NodeSetpointCheck[self.EvapOutletNodeNum].needsSetpointChecking = False
                    if fatalError:
                        if not self.ModulatedFlowErrDone:
                            ShowWarningError(state, String.format("Missing temperature setpoint for LeavingSetpointModulated mode chiller named {}", self.Name))
                            ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of a chiller evaporator in variable flow mode")
                            ShowContinueError(state, "  use a Setpoint Manager to establish a setpoint at the chiller evaporator outlet node ")
                            ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at the outlet node ")
                            ShowContinueError(state, "  The overall loop setpoint will be assumed for chiller. The simulation continues ... ")
                            self.ModulatedFlowErrDone = True
                self.ModulatedFlowSetToLoop = True
                state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPoint
                state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPointHi

    def initEachEnvironment(mut self, state: EnergyPlusData):
        var rho: Real64 = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, "ElectricEIRChillerSpecs::initEachEnvironment")
        self.EvapMassFlowRateMax = self.EvapVolFlowRate * rho
        PlantUtilities.InitComponentNodes(state, 0.0, self.EvapMassFlowRateMax, self.EvapInletNodeNum, self.EvapOutletNodeNum)
        if self.CondenserType == DataPlant.CondenserType.WaterCooled:
            rho = self.CDPlantLoc.loop.glycol.getDensity(state, self.TempRefCondIn, "ElectricEIRChillerSpecs::initEachEnvironment")
            self.CondMassFlowRateMax = rho * self.CondVolFlowRate
            PlantUtilities.InitComponentNodes(state, 0.0, self.CondMassFlowRateMax, self.CondInletNodeNum, self.CondOutletNodeNum)
            state.dataLoopNodes.Node[self.CondInletNodeNum].Temp = self.TempRefCondIn
        else: # air or evap air condenser
            rho = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, self.TempRefCondIn, 0.0, "ElectricEIRChillerSpecs::initEachEnvironment")
            self.CondMassFlowRateMax = rho * self.CondVolFlowRate
            state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRate = self.CondMassFlowRateMax
            state.dataLoopNodes.Node[self.CondOutletNodeNum].MassFlowRate = state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRate
            state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRateMaxAvail = state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRate
            state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRateMax = state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRate
            state.dataLoopNodes.Node[self.CondOutletNodeNum].MassFlowRateMax = state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRate
            state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRateMinAvail = 0.0
            state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRateMin = 0.0
            state.dataLoopNodes.Node[self.CondOutletNodeNum].MassFlowRateMinAvail = 0.0
            state.dataLoopNodes.Node[self.CondOutletNodeNum].MassFlowRateMin = 0.0
            state.dataLoopNodes.Node[self.CondInletNodeNum].Temp = self.TempRefCondIn
        if self.HeatRecActive:
            rho = self.HRPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, "ElectricEIRChillerSpecs::initEachEnvironment")
            self.DesignHeatRecMassFlowRate = rho * self.DesignHeatRecVolFlowRate
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesignHeatRecMassFlowRate, self.HeatRecInletNodeNum, self.HeatRecOutletNodeNum)
            self.HeatRecMaxCapacityLimit = self.HeatRecCapacityFraction * (self.RefCap + self.RefCap / self.RefCOP)
            if self.HeatRecSetPointNodeNum > 0:
                var THeatRecSetPoint: Real64 = 0.0
                if self.HRPlantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.SingleSetPoint:
                    THeatRecSetPoint = state.dataLoopNodes.Node[self.HeatRecSetPointNodeNum].TempSetPoint
                elif self.HRPlantLoc.loop.LoopDemandCalcScheme == DataPlant.LoopDemandCalcScheme.DualSetPointDeadBand:
                    THeatRecSetPoint = state.dataLoopNodes.Node[self.HeatRecSetPointNodeNum].TempSetPointHi
                else:
                    assert(False)
                if THeatRecSetPoint == Node.SensedNodeFlagValue:
                    if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                        if not self.HRSPErrDone:
                            ShowWarningError(state, String.format("Missing heat recovery temperature setpoint for chiller named {}", self.Name))
                            ShowContinueError(state, "  A temperature setpoint is needed at the heat recovery leaving temperature setpoint node specified, use a SetpointManager")
                            ShowContinueError(state, "  The overall loop setpoint will be assumed for heat recovery. The simulation continues ...")
                            self.HeatRecSetPointNodeNum = self.HRPlantLoc.loop.TempSetPointNodeNum
                            self.HRSPErrDone = True
                    else:
                        var fatalError: Bool = False
                        EMSManager.CheckIfNodeSetPointManagedByEMS(state, self.EvapOutletNodeNum, HVAC.CtrlVarType.Temp, fatalError)
                        state.dataLoopNodes.NodeSetpointCheck[self.EvapOutletNodeNum].needsSetpointChecking = False
                        if fatalError:
                            if not self.HRSPErrDone:
                                ShowWarningError(state, String.format("Missing heat recovery temperature setpoint for chiller named {}", self.Name))
                                ShowContinueError(state, "  A temperature setpoint is needed at the heat recovery leaving temperature setpoint node specified, use a SetpointManager to establish a setpoint")
                                ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at this node ")
                                ShowContinueError(state, "  The overall loop setpoint will be assumed for heat recovery. The simulation continues ...")
                                self.HeatRecSetPointNodeNum = self.HRPlantLoc.loop.TempSetPointNodeNum
                                self.HRSPErrDone = True

    def initialize(mut self, state: EnergyPlusData, RunFlag: Bool, MyLoad: Real64):
        if self.oneTimeFlag:
            self.oneTimeInit(state)
            self.oneTimeFlag = False
        self.EquipFlowCtrl = DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).FlowCtrl
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and (state.dataPlnt.PlantFirstSizesOkayToFinalize):
            self.initEachEnvironment(state)
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        if (self.FlowMode == DataPlant.FlowMode.LeavingSetpointModulated) and self.ModulatedFlowSetToLoop:
            state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPoint
            state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPointHi
        var mdot: Real64 = 0.0
        var mdotCond: Real64 = 0.0
        if (abs(MyLoad) > 0.0) and RunFlag:
            mdot = self.EvapMassFlowRateMax
            mdotCond = self.CondMassFlowRateMax
        PlantUtilities.SetComponentFlowRate(state, mdot, self.EvapInletNodeNum, self.EvapOutletNodeNum, self.CWPlantLoc)
        if self.CondenserType == DataPlant.CondenserType.WaterCooled:
            PlantUtilities.SetComponentFlowRate(state, mdotCond, self.CondInletNodeNum, self.CondOutletNodeNum, self.CDPlantLoc)
            self.VSBranchPumpMinLimitMassFlowCond = PlantUtilities.MinFlowIfBranchHasVSPump(state, self.CDPlantLoc, self.VSBranchPumpFoundCond, self.VSLoopPumpFoundCond, False)
        if self.HeatRecActive:
            mdot = self.DesignHeatRecMassFlowRate if RunFlag else 0.0
            PlantUtilities.SetComponentFlowRate(state, mdot, self.HeatRecInletNodeNum, self.HeatRecOutletNodeNum, self.HRPlantLoc)
        if self.CondenserType == DataPlant.CondenserType.EvapCooled:
            self.BasinHeaterPower = 0.0

    def size(mut self, state: EnergyPlusData):
        var PltSizCondNum: Int = 0
        var ErrorsFound: Bool = False
        var tmpNomCap: Real64 = self.RefCap
        var tmpEvapVolFlowRate: Real64 = self.EvapVolFlowRate
        var tmpCondVolFlowRate: Real64 = self.CondVolFlowRate
        if self.CondenserType == DataPlant.CondenserType.WaterCooled:
            PltSizCondNum = self.CDPlantLoc.loop.PlantSizNum
        var PltSizNum: Int = self.CWPlantLoc.loop.PlantSizNum
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                tmpEvapVolFlowRate = state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate * self.SizFac
            else:
                if self.EvapVolFlowRateWasAutoSized:
                    tmpEvapVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.EvapVolFlowRateWasAutoSized:
                    self.EvapVolFlowRate = tmpEvapVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Reference Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Initial Design Size Reference Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate)
                else:
                    var EvapVolFlowRateUser: Real64 = self.EvapVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Reference Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate, "User-Specified Reference Chilled Water Flow Rate [m3/s]", EvapVolFlowRateUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(tmpEvapVolFlowRate - EvapVolFlowRateUser) / EvapVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, String.format("SizeChillerElectricEIR: Potential issue with equipment sizing for {}", self.Name))
                                ShowContinueError(state, String.format("User-Specified Reference Chilled Water Flow Rate of {:#G} [m3/s]", EvapVolFlowRateUser))
                                ShowContinueError(state, String.format("differs from Design Size Reference Chilled Water Flow Rate of {:#G} [m3/s]", tmpEvapVolFlowRate))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                    tmpEvapVolFlowRate = EvapVolFlowRateUser
        else:
            if self.EvapVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Electric Chiller evap flow rate requires a loop Sizing:Plant object")
                ShowContinueError(state, String.format("Occurs in Electric Chiller object={}", self.Name))
                ErrorsFound = True
            if not self.EvapVolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and (self.EvapVolFlowRate > 0.0):
                BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "User-Specified Reference Chilled Water Flow Rate [m3/s]", self.EvapVolFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.EvapInletNodeNum, tmpEvapVolFlowRate)
        if PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                var Cp: Real64 = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, "SizeElectricEIRChiller")
                var rho: Real64 = self.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, "SizeElectricEIRChiller")
                tmpNomCap = Cp * rho * state.dataSize.PlantSizData[PltSizNum].DeltaT * tmpEvapVolFlowRate
            else:
                tmpNomCap = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.RefCapWasAutoSized:
                    self.RefCap = tmpNomCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Reference Capacity [W]", tmpNomCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Initial Design Size Reference Capacity [W]", tmpNomCap)
                else:
                    var RefCapUser: Real64 = self.RefCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Reference Capacity [W]", tmpNomCap, "User-Specified Reference Capacity [W]", RefCapUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(tmpNomCap - RefCapUser) / RefCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, String.format("SizeChillerElectricEIR: Potential issue with equipment sizing for {}", self.Name))
                                ShowContinueError(state, String.format("User-Specified Reference Capacity of {:.2f} [W]", RefCapUser))
                                ShowContinueError(state, String.format("differs from Design Size Reference Capacity of {:.2f} [W]", tmpNomCap))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                    tmpNomCap = RefCapUser
        else:
            if self.RefCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of Electric Chiller reference capacity requires a loop Sizing:Plant object")
                ShowContinueError(state, String.format("Occurs in Electric Chiller object={}", self.Name))
                ErrorsFound = True
            if not self.RefCapWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and (self.RefCap > 0.0):
                BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "User-Specified Reference Capacity [W]", self.RefCap)
        if PltSizCondNum > 0 and PltSizNum > 0:
            if state.dataSize.PlantSizData[PltSizNum].DesVolFlowRate >= HVAC.SmallWaterVolFlow and tmpNomCap > 0.0:
                var rho2: Real64 = self.CDPlantLoc.loop.glycol.getDensity(state, self.TempRefCondIn, "SizeElectricEIRChiller")
                var Cp2: Real64 = self.CDPlantLoc.loop.glycol.getSpecificHeat(state, self.TempRefCondIn, "SizeElectricEIRChiller")
                tmpCondVolFlowRate = tmpNomCap * (1.0 + (1.0 / self.RefCOP) * self.CompPowerToCondenserFrac) / (state.dataSize.PlantSizData[PltSizCondNum].DeltaT * Cp2 * rho2)
            else:
                if self.CondVolFlowRateWasAutoSized:
                    tmpCondVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.CondVolFlowRateWasAutoSized:
                    self.CondVolFlowRate = tmpCondVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Reference Condenser Fluid Flow Rate [m3/s]", tmpCondVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Initial Design Size Reference Condenser Fluid Flow Rate [m3/s]", tmpCondVolFlowRate)
                else:
                    var CondVolFlowRateUser: Real64 = self.CondVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Reference Condenser Fluid Flow Rate [m3/s]", tmpCondVolFlowRate, "User-Specified Reference Condenser Fluid Flow Rate [m3/s]", CondVolFlowRateUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(tmpCondVolFlowRate - CondVolFlowRateUser) / CondVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, String.format("SizeChillerElectricEIR: Potential issue with equipment sizing for {}", self.Name))
                                ShowContinueError(state, String.format("User-Specified Reference Condenser Fluid Flow Rate of {:#G} [m3/s]", CondVolFlowRateUser))
                                ShowContinueError(state, String.format("differs from Design Size Reference Condenser Fluid Flow Rate of {:#G} [m3/s]", tmpCondVolFlowRate))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                    tmpCondVolFlowRate = CondVolFlowRateUser
        else:
            if self.CondenserType == DataPlant.CondenserType.WaterCooled:
                if self.CondVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "Autosizing of Electric EIR Chiller condenser fluid flow rate requires a condenser")
                    ShowContinueError(state, "loop Sizing:Plant object")
                    ShowContinueError(state, String.format("Occurs in Electric EIR Chiller object={}", self.Name))
                    ErrorsFound = True
                if not self.CondVolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and (self.CondVolFlowRate > 0.0):
                    BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "User-Specified Reference Condenser Fluid Flow Rate [m3/s]", self.CondVolFlowRate)
            else:
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    var CompType: String = DataPlant.PlantEquipTypeNames[Int(DataPlant.PlantEquipmentType.Chiller_ElectricEIR)]
                    state.dataSize.DataConstantUsedForSizing = self.RefCap
                    state.dataSize.DataFractionUsedForSizing = 0.000114
                    var TempSize: Real64 = self.CondVolFlowRate
                    var bPRINT: Bool = True
                    var sizerCondAirFlow: AutoCalculateSizer = AutoCalculateSizer()
                    var stringOverride: String = "Reference Condenser Fluid Flow Rate  [m3/s]"
                    sizerCondAirFlow.overrideSizingString(stringOverride)
                    sizerCondAirFlow.initializeWithinEP(state, CompType, self.Name, bPRINT, "SizeElectricEIRChiller")
                    self.CondVolFlowRate = sizerCondAirFlow.size(state, TempSize, ErrorsFound)
                    tmpCondVolFlowRate = self.CondVolFlowRate
        if self.CondenserType == DataPlant.CondenserType.WaterCooled:
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.CondInletNodeNum, tmpCondVolFlowRate)
        if self.HeatRecActive:
            var tempHeatRecVolFlowRate: Real64
            if self.CondenserType == DataPlant.CondenserType.WaterCooled:
                tempHeatRecVolFlowRate = tmpCondVolFlowRate * self.HeatRecCapacityFraction
            else:
                if self.EvapVolFlowRateWasAutoSized:
                    tempHeatRecVolFlowRate = tmpEvapVolFlowRate
                else:
                    tempHeatRecVolFlowRate = self.EvapVolFlowRate
                tempHeatRecVolFlowRate *= (1.0 + (1.0 / self.RefCOP)) * self.CompPowerToCondenserFrac * self.HeatRecCapacityFraction
            if self.DesignHeatRecVolFlowRateWasAutoSized:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    self.DesignHeatRecVolFlowRate = tempHeatRecVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Heat Recovery Water Flow Rate [m3/s]", tempHeatRecVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Initial Design Size Heat Recovery Water Flow Rate [m3/s]", tempHeatRecVolFlowRate)
            else:
                if (self.DesignHeatRecVolFlowRate > 0.0) and (tempHeatRecVolFlowRate > 0.0):
                    var nomHeatRecVolFlowRateUser: Real64 = self.DesignHeatRecVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        if state.dataGlobal.DoPlantSizing:
                            BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "Design Size Heat Recovery Water Flow Rate [m3/s]", tempHeatRecVolFlowRate, "User-Specified Heat Recovery Water Flow Rate [m3/s]", nomHeatRecVolFlowRateUser)
                        else:
                            BaseSizer.reportSizerOutput(state, "Chiller:Electric:EIR", self.Name, "User-Specified Heat Recovery Water Flow Rate [m3/s]", nomHeatRecVolFlowRateUser)
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(tempHeatRecVolFlowRate - nomHeatRecVolFlowRateUser) / nomHeatRecVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(state, String.format("SizeChillerElectricEIR: Potential issue with equipment sizing for {}", self.Name))
                                ShowContinueError(state, String.format("User-Specified Heat Recovery Water Flow Rate of {:#G} [m3/s]", nomHeatRecVolFlowRateUser))
                                ShowContinueError(state, String.format("differs from Design Size Heat Recovery Water Flow Rate of {:#G} [m3/s]", tempHeatRecVolFlowRate))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                    tempHeatRecVolFlowRate = nomHeatRecVolFlowRateUser
            if not self.DesignHeatRecVolFlowRateWasAutoSized:
                tempHeatRecVolFlowRate = self.DesignHeatRecVolFlowRate
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.HeatRecInletNodeNum, tempHeatRecVolFlowRate)
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            var IPLVSI_rpt_std229: Real64 = 0.0
            var IPLVIP_rpt_std229: Real64 = 0.0
            if self.IPLVFlag:
                var IPLVSI: Real64 = 0.0
                var IPLVIP: Real64 = 0.0
                StandardRatings.CalcChillerIPLV(state, self.Name, DataPlant.PlantEquipmentType.Chiller_ElectricEIR, self.RefCap, self.RefCOP, self.CondenserType, self.ChillerCapFTIndex, self.ChillerEIRFTIndex, self.ChillerEIRFPLRIndex, self.MinUnloadRat, IPLVSI, IPLVIP, Optional[Real64](), Optional[Int](), Optional[Real64]())
                IPLVSI_rpt_std229 = IPLVSI
                IPLVIP_rpt_std229 = IPLVIP
                self.IPLVFlag = False
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "Chiller:Electric:EIR")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, self.Name, self.RefCOP)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.RefCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerType, self.Name, "Chiller:Electric:EIR")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefCap, self.Name, self.RefCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefEff, self.Name, self.RefCOP)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedCap, self.Name, self.RefCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedEff, self.Name, self.RefCOP)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerIPLVinSI, self.Name, IPLVSI_rpt_std229)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerIPLVinIP, self.Name, IPLVIP_rpt_std229)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerPlantloopName, self.Name, (self.CWPlantLoc.loop != None) ? self.CWPlantLoc.loop.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerPlantloopBranchName, self.Name, (self.CWPlantLoc.branch != None) ? self.CWPlantLoc.branch.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerCondLoopName, self.Name, (self.CDPlantLoc.loop != None) ? self.CDPlantLoc.loop.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerCondLoopBranchName, self.Name, (self.CDPlantLoc.loop != None) ? self.CDPlantLoc.branch.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerMinPLR, self.Name, self.MinPartLoadRat)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerFuelType, self.Name, "Electricity")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedEntCondTemp, self.Name, self.TempRefCondIn)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedLevEvapTemp, self.Name, self.TempRefEvapOut)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefEntCondTemp, self.Name, self.TempRefCondIn)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefLevEvapTemp, self.Name, self.TempRefEvapOut)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerDesSizeRefCHWFlowRate, self.Name, self.EvapMassFlowRateMax)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerDesSizeRefCondFluidFlowRate, self.Name, self.CondMassFlowRateMax)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerHeatRecPlantloopName, self.Name, (self.HRPlantLoc.loop != None) ? self.HRPlantLoc.loop.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerHeatRecPlantloopBranchName, self.Name, (self.HRPlantLoc.loop != None) ? self.HRPlantLoc.branch.Name : "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRecRelCapFrac, self.Name, self.HeatRecCapacityFraction)
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def calculate(mut self, state: EnergyPlusData, mut MyLoad: Real64, RunFlag: Bool):
        var EvapOutletTempSetPoint: Real64 = 0.0
        var EvapDeltaTemp: Real64 = 0.0
        var TempLoad: Real64 = 0.0
        var CurrentEndTime: Real64 = 0.0
        self.CondMassFlowRate = 0.0
        var FRAC: Real64 = 1.0
        self.ChillerCapFT = 0.0
        self.ChillerEIRFT = 0.0
        self.ChillerEIRFPLR = 0.0
        self.thermosiphonStatus = 0
        CurrentEndTime = state.dataGlobal.CurrentTime + state.dataHVACGlobal.SysTimeElapsed
        if CurrentEndTime > self.CurrentEndTimeLast and state.dataHVACGlobal.TimeStepSys >= self.TimeStepSysLast:
            if self.PrintMessage:
                self.MsgErrorCount += 1
                if self.MsgErrorCount < 2:
                    ShowWarningError(state, String.format("{}.", self.MsgBuffer1))
                    ShowContinueError(state, self.MsgBuffer2)
                else:
                    ShowRecurringWarningErrorAtEnd(state, self.MsgBuffer1 + " error continues.", self.ErrCount1, self.MsgDataLast, self.MsgDataLast, _, "[C]", "[C]")
        self.TimeStepSysLast = state.dataHVACGlobal.TimeStepSys
        self.CurrentEndTimeLast = CurrentEndTime
        if MyLoad >= 0 or not RunFlag:
            if self.EquipFlowCtrl == DataBranchAirLoopPlant.ControlType.SeriesActive or self.CWPlantLoc.side.FlowLock == DataPlant.FlowLock.Locked:
                self.EvapMassFlowRate = state.dataLoopNodes.Node[self.EvapInletNodeNum].MassFlowRate
            if self.CondenserType == DataPlant.CondenserType.WaterCooled:
                if DataPlant.CompData.getPlantComponent(state, self.CDPlantLoc).FlowCtrl == DataBranchAirLoopPlant.ControlType.SeriesActive:
                    self.CondMassFlowRate = state.dataLoopNodes.Node[self.CondInletNodeNum].MassFlowRate
            if self.CondenserType == DataPlant.CondenserType.EvapCooled:
                CalcBasinHeaterPower(state, self.BasinHeaterPowerFTempDiff, self.basinHeaterSched, self.BasinHeaterSetPointTemp, self.BasinHeaterPower)
            self.PrintMessage = False
            return
        self.CondOutletHumRat = state.dataLoopNodes.Node[self.CondInletNodeNum].HumRat
        if self.CondenserType == DataPlant.CondenserType.AirCooled:
            state.dataLoopNodes.Node[self.CondInletNodeNum].Temp = state.dataLoopNodes.Node[self
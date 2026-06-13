# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData
# - PlantComponent: base class from EnergyPlus.PlantComponent
# - PlantLocation: struct from EnergyPlus.Plant.PlantLocation
# - Schedule: class from EnergyPlus.ScheduleManager
# - Node operations: GetOnlySingleNode, TestCompSet from EnergyPlus.NodeInputManager
# - PlantUtilities: InitComponentNodes, SetComponentFlowRate, ScanPlantLoopsForObject, RegisterPlantCompDesignFlow
# - InputProcessor: getNumObjectsFound, getObjectItem
# - OutputProcessor: SetupOutputVariable, SetupEMSActuator, TimeStepType, StoreType
# - DataSizing: AutoSize constant
# - DataLoopNode: Node array access
# - DataHVACGlobals: TimeStepSysSec
# - General utilities: ShowFatalError, ShowSevereError, ShowMessage, ShowContinueError, format
# - FluidProperties: getDensity, getSpecificHeat
# - Constants: InitConvTemp, BigNumber
# - BaseSizer: reportSizerOutput
# - ErrorObjectHeader: from error handling
# - Enums: DataPlant.PlantEquipmentType, Node.ConnectionObjectType, Node.FluidType, Node.ConnectionType, Node.CompFluidStream, Node.ObjectIsNotParent
# - math: abs, min

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional


class TempSpecType(IntEnum):
    """Temperature specification type enumeration"""
    Invalid = -1
    Constant = 0
    Schedule = 1
    Num = 2


@dataclass
class WaterSourceSpecs:
    """Water source specifications class extending PlantComponent"""
    
    # Members
    Name: str = ""
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    DesVolFlowRate: float = 0.0
    DesVolFlowRateWasAutoSized: bool = False
    MassFlowRateMax: float = 0.0
    EMSOverrideOnMassFlowRateMax: bool = False
    EMSOverrideValueMassFlowRateMax: float = 0.0
    MassFlowRate: float = 0.0
    tempSpecType: TempSpecType = TempSpecType.Invalid
    tempSpecSched: Optional[object] = None
    BoundaryTemp: float = 0.0
    OutletTemp: float = 0.0
    InletTemp: float = 0.0
    HeatRate: float = 0.0
    HeatEnergy: float = 0.0
    plantLoc: Optional[object] = None
    SizFac: float = 0.0
    CheckEquipName: bool = True
    MyFlag: bool = True
    MyEnvironFlag: bool = True
    IsThisSized: bool = False
    
    def __post_init__(self):
        if self.plantLoc is None:
            self.plantLoc = {}
    
    def factory(self, state: object, object_name: str) -> "WaterSourceSpecs":
        """Factory method to get or create a water source by name"""
        if state.dataPlantCompTempSrc.getWaterSourceInput:
            GetWaterSourceInput(state)
            state.dataPlantCompTempSrc.getWaterSourceInput = False
        
        for water_source in state.dataPlantCompTempSrc.WaterSource:
            if water_source.Name == object_name:
                return water_source
        
        # If not found, fatal error
        from EnergyPlus.UtilityRoutines import ShowFatalError, format
        ShowFatalError(state, format("LocalTemperatureSourceFactory: Error getting inputs for temperature source named: {}", object_name))
        return None
    
    def initialize(self, state: object, my_load: float) -> None:
        """Initialize water source for simulation step"""
        from EnergyPlus.UtilityRoutines import format, ShowFatalError
        from EnergyPlus.PlantUtilities import InitComponentNodes, SetComponentFlowRate
        from EnergyPlus.Constants import Constant
        
        routine_name = "InitWaterSource"
        
        self.oneTimeInit(state)
        
        if self.MyEnvironFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            rho = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, routine_name)
            self.MassFlowRateMax = self.DesVolFlowRate * rho
            InitComponentNodes(state, 0.0, self.MassFlowRateMax, self.InletNodeNum, self.OutletNodeNum)
            self.MyEnvironFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvironFlag = True
        
        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum].Temp
        if self.tempSpecType == TempSpecType.Schedule:
            self.BoundaryTemp = self.tempSpecSched.getCurrentVal()
        
        cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.BoundaryTemp, routine_name)
        
        delta_temp = self.BoundaryTemp - self.InletTemp
        
        if abs(delta_temp) < 0.001:
            if abs(my_load) < 0.001:
                self.MassFlowRate = 0.0
            else:
                self.MassFlowRate = self.MassFlowRateMax
        else:
            self.MassFlowRate = my_load / (cp * delta_temp)
        
        if self.MassFlowRate < 0:
            self.MassFlowRate = 0.0
        else:
            if not self.EMSOverrideOnMassFlowRateMax:
                self.MassFlowRate = min(self.MassFlowRate, self.MassFlowRateMax)
            else:
                self.MassFlowRate = min(self.MassFlowRate, self.EMSOverrideValueMassFlowRateMax)
        
        SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
    
    def setupOutputVars(self, state: object) -> None:
        """Setup output variables for tracking"""
        from EnergyPlus.OutputProcessor import SetupOutputVariable, SetupEMSActuator, TimeStepType, StoreType
        from EnergyPlus.Constants import Constant
        
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Mass Flow Rate",
            Constant.Units.kg_s,
            self.MassFlowRate,
            TimeStepType.System,
            StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Inlet Temperature",
            Constant.Units.C,
            self.InletTemp,
            TimeStepType.System,
            StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Outlet Temperature",
            Constant.Units.C,
            self.OutletTemp,
            TimeStepType.System,
            StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Source Temperature",
            Constant.Units.C,
            self.BoundaryTemp,
            TimeStepType.System,
            StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Heat Transfer Rate",
            Constant.Units.W,
            self.HeatRate,
            TimeStepType.System,
            StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Heat Transfer Energy",
            Constant.Units.J,
            self.HeatEnergy,
            TimeStepType.System,
            StoreType.Sum,
            self.Name
        )
        
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(
                state,
                "PlantComponent:TemperatureSource",
                self.Name,
                "Maximum Mass Flow Rate",
                "[kg/s]",
                self.EMSOverrideOnMassFlowRateMax,
                self.EMSOverrideValueMassFlowRateMax
            )
    
    def autosize(self, state: object) -> None:
        """Autosize design flow rate"""
        from EnergyPlus.UtilityRoutines import ShowSevereError, ShowFatalError, ShowMessage, ShowContinueError, format
        from EnergyPlus.Autosizing.Base import BaseSizer
        from EnergyPlus.DataSizing import AutoSize, AutoVsHardSizingThreshold
        from EnergyPlus.DataHVACGlobals import SmallWaterVolFlow
        from EnergyPlus.PlantUtilities import RegisterPlantCompDesignFlow
        
        errors_found = False
        des_vol_flow_rate_user = 0.0
        tmp_vol_flow_rate = self.DesVolFlowRate
        plt_siz_num = self.plantLoc.loop.PlantSizNum
        
        if plt_siz_num > 0:
            if state.dataSize.PlantSizData[plt_siz_num - 1].DesVolFlowRate >= SmallWaterVolFlow:
                tmp_vol_flow_rate = state.dataSize.PlantSizData[plt_siz_num - 1].DesVolFlowRate
                if not self.DesVolFlowRateWasAutoSized:
                    tmp_vol_flow_rate = self.DesVolFlowRate
            else:
                if self.DesVolFlowRateWasAutoSized:
                    tmp_vol_flow_rate = 0.0
            
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.DesVolFlowRateWasAutoSized:
                    self.DesVolFlowRate = tmp_vol_flow_rate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "PlantComponent:TemperatureSource", self.Name,
                            "Design Size Design Fluid Flow Rate [m3/s]", tmp_vol_flow_rate
                        )
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "PlantComponent:TemperatureSource", self.Name,
                            "Initial Design Size Design Fluid Flow Rate [m3/s]", tmp_vol_flow_rate
                        )
                else:
                    if self.DesVolFlowRate > 0.0 and tmp_vol_flow_rate > 0.0:
                        des_vol_flow_rate_user = self.DesVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(
                                state, "PlantComponent:TemperatureSource", self.Name,
                                "Design Size Design Fluid Flow Rate [m3/s]", tmp_vol_flow_rate,
                                "User-Specified Design Fluid Flow Rate [m3/s]", des_vol_flow_rate_user
                            )
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmp_vol_flow_rate - des_vol_flow_rate_user) / des_vol_flow_rate_user) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("SizePlantComponentTemperatureSource: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Design Fluid Flow Rate of {:.5R} [m3/s]", des_vol_flow_rate_user))
                                    ShowContinueError(state, format("differs from Design Size Design Fluid Flow Rate of {:.5R} [m3/s]", tmp_vol_flow_rate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmp_vol_flow_rate = des_vol_flow_rate_user
        else:
            if self.DesVolFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of plant component temperature source flow rate requires a loop Sizing:Plant object")
                ShowContinueError(state, format("Occurs in PlantComponent:TemperatureSource object={}", self.Name))
                errors_found = True
            if not self.DesVolFlowRateWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport:
                if self.DesVolFlowRate > 0.0:
                    BaseSizer.reportSizerOutput(
                        state, "PlantComponent:TemperatureSource", self.Name,
                        "User-Specified Design Fluid Flow Rate [m3/s]", self.DesVolFlowRate
                    )
        
        RegisterPlantCompDesignFlow(state, self.InletNodeNum, tmp_vol_flow_rate)
        
        if errors_found:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
    
    def calculate(self, state: object) -> None:
        """Calculate outlet temperature and heat transfer"""
        routine_name = "CalcWaterSource"
        
        if self.MassFlowRate > 0.0:
            self.OutletTemp = self.BoundaryTemp
            cp = self.plantLoc.loop.glycol.getSpecificHeat(state, self.BoundaryTemp, routine_name)
            self.HeatRate = self.MassFlowRate * cp * (self.OutletTemp - self.InletTemp)
            self.HeatEnergy = self.HeatRate * state.dataHVACGlobal.TimeStepSysSec
        else:
            self.OutletTemp = self.BoundaryTemp
            self.HeatRate = 0.0
            self.HeatEnergy = 0.0
    
    def update(self, state: object) -> None:
        """Update node with outlet temperature"""
        state.dataLoopNodes.Node[self.OutletNodeNum].Temp = self.OutletTemp
    
    def simulate(self, state: object, called_from_location: object, first_hvac_iteration: bool, cur_load: float, run_flag: bool) -> None:
        """Simulate the water source component"""
        self.initialize(state, cur_load)
        self.calculate(state)
        self.update(state)
    
    def getDesignCapacities(self, state: object, called_from_location: object) -> tuple:
        """Get design capacity bounds"""
        from EnergyPlus.Constants import Constant
        return (Constant.BigNumber, 0.0, Constant.BigNumber)
    
    def getSizingFactor(self) -> float:
        """Get sizing factor"""
        return self.SizFac
    
    def onInitLoopEquip(self, state: object, called_from_location: object) -> None:
        """Initialize on loop equipment setup"""
        my_load = 0.0
        self.initialize(state, my_load)
        self.autosize(state)
    
    def oneTimeInit(self, state: object) -> None:
        """One-time initialization"""
        from EnergyPlus.UtilityRoutines import ShowFatalError, format
        from EnergyPlus.PlantUtilities import ScanPlantLoopsForObject
        from EnergyPlus.Plant.DataPlant import PlantEquipmentType
        
        routine_name = "InitWaterSource"
        
        if self.MyFlag:
            self.setupOutputVars(state)
            err_flag = False
            ScanPlantLoopsForObject(
                state, self.Name, PlantEquipmentType.WaterSource, self.plantLoc, err_flag,
                _, _, _, self.InletNodeNum, _
            )
            if err_flag:
                ShowFatalError(state, format("{}: Program terminated due to previous condition(s).", routine_name))
            self.MyFlag = False


@dataclass
class PlantCompTempSrcData:
    """Global data structure for plant component temperature sources"""
    
    NumSources: int = 0
    getWaterSourceInput: bool = True
    WaterSource: list = field(default_factory=list)
    
    def init_constant_state(self, state: object) -> None:
        """Initialize constant state"""
        pass
    
    def init_state(self, state: object) -> None:
        """Initialize state"""
        pass
    
    def clear_state(self) -> None:
        """Clear state"""
        self.NumSources = 0
        self.getWaterSourceInput = True
        self.WaterSource = []


def GetWaterSourceInput(state: object) -> None:
    """Get water source input from input file"""
    from EnergyPlus.UtilityRoutines import ShowSevereError, ShowFatalError, ShowSevereItemNotFound, ShowContinueError, format
    from EnergyPlus.DataSizing import AutoSize
    from EnergyPlus.NodeInputManager import GetOnlySingleNode, TestCompSet
    from EnergyPlus.ScheduleManager import GetSchedule
    
    routine_name = "GetWaterSourceInput"
    
    c_current_module_object = "PlantComponent:TemperatureSource"
    state.dataPlantCompTempSrc.NumSources = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, c_current_module_object
    )
    
    if state.dataPlantCompTempSrc.NumSources <= 0:
        ShowSevereError(state, format("No {} equipment specified in input file", c_current_module_object))
        return
    
    if state.dataPlantCompTempSrc.WaterSource:
        return
    
    state.dataPlantCompTempSrc.WaterSource = [WaterSourceSpecs() for _ in range(state.dataPlantCompTempSrc.NumSources)]
    
    for source_num in range(state.dataPlantCompTempSrc.NumSources):
        c_alpha_args, num_alphas, r_numeric_args, num_nums, io_stat, c_alpha_field_blanks, c_alpha_field_names, c_numeric_field_names = (
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, c_current_module_object, source_num + 1
            )
        )
        
        state.dataPlantCompTempSrc.WaterSource[source_num].Name = c_alpha_args[0]
        
        state.dataPlantCompTempSrc.WaterSource[source_num].InletNodeNum = GetOnlySingleNode(
            state, c_alpha_args[1], False, "PlantComponentTemperatureSource",
            c_alpha_args[0], "Water", "Inlet", "Primary", "NotParent"
        )
        
        state.dataPlantCompTempSrc.WaterSource[source_num].OutletNodeNum = GetOnlySingleNode(
            state, c_alpha_args[2], False, "PlantComponentTemperatureSource",
            c_alpha_args[0], "Water", "Outlet", "Primary", "NotParent"
        )
        
        TestCompSet(
            state, c_current_module_object, c_alpha_args[0],
            c_alpha_args[1], c_alpha_args[2], "Chilled Water Nodes"
        )
        
        state.dataPlantCompTempSrc.WaterSource[source_num].DesVolFlowRate = r_numeric_args[0]
        if state.dataPlantCompTempSrc.WaterSource[source_num].DesVolFlowRate == AutoSize:
            state.dataPlantCompTempSrc.WaterSource[source_num].DesVolFlowRateWasAutoSized = True
        
        if c_alpha_args[3] == "CONSTANT":
            state.dataPlantCompTempSrc.WaterSource[source_num].tempSpecType = TempSpecType.Constant
            state.dataPlantCompTempSrc.WaterSource[source_num].BoundaryTemp = r_numeric_args[1]
        elif c_alpha_args[3] == "SCHEDULED":
            state.dataPlantCompTempSrc.WaterSource[source_num].tempSpecType = TempSpecType.Schedule
            sched = GetSchedule(state, c_alpha_args[4])
            if sched is None:
                ShowSevereItemNotFound(state, routine_name, c_current_module_object, c_alpha_args[4])
            else:
                state.dataPlantCompTempSrc.WaterSource[source_num].tempSpecSched = sched
        else:
            ShowSevereError(state, format("Input error for {}={}", c_current_module_object, c_alpha_args[0]))
            ShowContinueError(
                state,
                format(
                    'Invalid temperature specification type.  Expected either "Constant" or "Scheduled". Encountered {}',
                    c_alpha_args[3]
                )
            )

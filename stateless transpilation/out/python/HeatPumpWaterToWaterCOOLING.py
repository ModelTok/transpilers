# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: passed as 'state' parameter
# - DataPlant: enum PlantEquipmentType, CriteriaType
# - Fluid: RefrigProps protocol/class
# - PlantLocation: struct/class with loopNum, loopSideNum, loop member
# - PlantComponent: base class/protocol
# - BaseGlobalStruct: base class/protocol
# - PlantUtilities: UpdateChillerComponentCondenserSide, SetComponentFlowRate, PullCompInterconnectTrigger,
#   ScanPlantLoopsForObject, InterConnectTwoPlantLoopSides, InitComponentNodes, RegisterPlantCompDesignFlow
# - Node: GetOnlySingleNode, TestCompSet, ConnectionObjectType enum, FluidType enum, ConnectionType enum,
#   CompFluidStream enum, ObjectIsNotParent constant
# - FluidProperties: none direct
# - OutputProcessor: SetupOutputVariable, TimeStepType enum, StoreType enum, Group enum, EndUseCat enum
# - DataBranchAirLoopPlant: MassFlowTolerance constant
# - DataHVACGlobals: TimeStepSysSec
# - DataLoopNode: Node dict/array access
# - InputProcessor: getNumObjectsFound, getObjectItem
# - General: ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowContinueError, ShowContinueErrorTimeStamp, ShowWarningError
# - Constant: Units enum, CWInitConvTemp, eResource enum
# - BranchNodeConnections: none direct

from typing import Optional, Protocol, List, Dict, Any
from dataclasses import dataclass, field
import math

MODULE_COMP_NAME = "HeatPump:WaterToWater:ParameterEstimation:Cooling"
MODULE_COMP_NAME_UC = "HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:COOLING"
GSHP_REFRIGERANT = "R22"


class RefrigProps(Protocol):
    def getSatPressure(self, state: Any, temp: float, routine_name: str) -> float: ...
    def getSatEnthalpy(self, state: Any, temp: float, qual: float, routine_name: str) -> float: ...
    def getSupHeatEnthalpy(self, state: Any, temp: float, pressure: float, routine_name: str) -> float: ...
    def getSatTemperature(self, state: Any, pressure: float, routine_name: str) -> float: ...
    def getSupHeatDensity(self, state: Any, temp: float, pressure: float, routine_name: str) -> float: ...


class PlantLoop(Protocol):
    glycol: Any


class PlantLocation(Protocol):
    loopNum: int
    loopSideNum: int
    loop: PlantLoop


class PlantComponent(Protocol):
    pass


class BaseGlobalStruct(Protocol):
    pass


@dataclass
class GshpPeCoolingSpecs(PlantComponent):
    Name: str = ""
    WWHPPlantTypeOfNum: Any = None
    refrig: Optional[RefrigProps] = None
    Available: bool = False
    ON: bool = False
    COP: float = 0.0
    NomCap: float = 0.0
    MinPartLoadRat: float = 0.0
    MaxPartLoadRat: float = 0.0
    OptPartLoadRat: float = 0.0
    LoadSideVolFlowRate: float = 0.0
    LoadSideDesignMassFlow: float = 0.0
    SourceSideVolFlowRate: float = 0.0
    SourceSideDesignMassFlow: float = 0.0
    SourceSideInletNodeNum: int = 0
    SourceSideOutletNodeNum: int = 0
    LoadSideInletNodeNum: int = 0
    LoadSideOutletNodeNum: int = 0
    SourceSideUACoeff: float = 0.0
    LoadSideUACoeff: float = 0.0
    CompPistonDisp: float = 0.0
    CompClearanceFactor: float = 0.0
    CompSucPressDrop: float = 0.0
    SuperheatTemp: float = 0.0
    PowerLosses: float = 0.0
    LossFactor: float = 0.0
    HighPressCutoff: float = 0.0
    LowPressCutoff: float = 0.0
    IsOn: bool = False
    MustRun: bool = False
    SourcePlantLoc: Optional[PlantLocation] = None
    LoadPlantLoc: Optional[PlantLocation] = None
    CondMassFlowIndex: int = 0
    Power: float = 0.0
    Energy: float = 0.0
    QLoad: float = 0.0
    QLoadEnergy: float = 0.0
    QSource: float = 0.0
    QSourceEnergy: float = 0.0
    LoadSideWaterInletTemp: float = 0.0
    SourceSideWaterInletTemp: float = 0.0
    LoadSideWaterOutletTemp: float = 0.0
    SourceSideWaterOutletTemp: float = 0.0
    Running: int = 0
    LoadSideWaterMassFlowRate: float = 0.0
    SourceSideWaterMassFlowRate: float = 0.0
    plantScanFlag: bool = True
    beginEnvironFlag: bool = True

    @staticmethod
    def factory(state: Any, object_name: str) -> "GshpPeCoolingSpecs":
        if state.dataHPWaterToWaterClg.GetWWHPCoolingInput:
            GetGshpInput(state)
            state.dataHPWaterToWaterClg.GetWWHPCoolingInput = False
        
        for gshp in state.dataHPWaterToWaterClg.GSHP:
            if gshp.Name == object_name:
                return gshp
        
        from EnergyPlus.General import ShowFatalError
        ShowFatalError(state, f"WWHPCoolingFactory: Error getting inputs for heat pump named: {object_name}")
        return None

    def simulate(
        self,
        state: Any,
        called_from_location: PlantLocation,
        first_hvac_iteration: bool,
        cur_load: List[float],
        run_flag: bool,
    ) -> None:
        if called_from_location.loopNum == self.LoadPlantLoc.loopNum:
            self.initialize(state)
            self.calculate(state, cur_load)
            self.update(state)
        elif called_from_location.loopNum == self.SourcePlantLoc.loopNum:
            from EnergyPlus.PlantUtilities import UpdateChillerComponentCondenserSide
            from EnergyPlus.Plant.DataPlant import PlantEquipmentType
            UpdateChillerComponentCondenserSide(
                state,
                self.SourcePlantLoc.loopNum,
                self.SourcePlantLoc.loopSideNum,
                PlantEquipmentType.HPWaterEFCooling,
                self.SourceSideInletNodeNum,
                self.SourceSideOutletNodeNum,
                self.QSource,
                self.SourceSideWaterInletTemp,
                self.SourceSideWaterOutletTemp,
                self.SourceSideWaterMassFlowRate,
                first_hvac_iteration,
            )
        else:
            from EnergyPlus.General import ShowFatalError
            ShowFatalError(
                state,
                f"SimHPWatertoWaterCOOLING:: Invalid loop connection {MODULE_COMP_NAME}, Requested Unit={self.Name}",
            )

    def getDesignCapacities(
        self,
        state: Any,
        called_from_location: PlantLocation,
        max_load: List[float],
        min_load: List[float],
        opt_load: List[float],
    ) -> None:
        min_load[0] = self.NomCap * self.MinPartLoadRat
        max_load[0] = self.NomCap * self.MaxPartLoadRat
        opt_load[0] = self.NomCap * self.OptPartLoadRat

    def onInitLoopEquip(self, state: Any, called_from_location: PlantLocation) -> None:
        if self.plantScanFlag:
            from EnergyPlus.PlantUtilities import (
                ScanPlantLoopsForObject,
                InterConnectTwoPlantLoopSides,
            )
            from EnergyPlus.Plant.DataPlant import PlantEquipmentType
            from EnergyPlus.General import ShowFatalError
            
            err_flag = False
            ScanPlantLoopsForObject(
                state,
                self.Name,
                PlantEquipmentType.HPWaterPECooling,
                self.SourcePlantLoc,
                err_flag,
                None,
                None,
                None,
                self.SourceSideInletNodeNum,
                None,
            )
            ScanPlantLoopsForObject(
                state,
                self.Name,
                PlantEquipmentType.HPWaterPECooling,
                self.LoadPlantLoc,
                err_flag,
                None,
                None,
                None,
                self.LoadSideInletNodeNum,
                None,
            )
            if err_flag:
                ShowFatalError(state, "InitGshp: Program terminated due to previous condition(s).")
            
            InterConnectTwoPlantLoopSides(
                state, self.LoadPlantLoc, self.SourcePlantLoc, self.WWHPPlantTypeOfNum, True
            )
            self.plantScanFlag = False

    def initialize(self, state: Any) -> None:
        routine_name = "InitGshp"
        
        if state.dataGlobal.BeginEnvrnFlag and self.beginEnvironFlag:
            self.QLoad = 0.0
            self.QSource = 0.0
            self.Power = 0.0
            self.QLoadEnergy = 0.0
            self.QSourceEnergy = 0.0
            self.Energy = 0.0
            self.LoadSideWaterInletTemp = 0.0
            self.SourceSideWaterInletTemp = 0.0
            self.LoadSideWaterOutletTemp = 0.0
            self.SourceSideWaterOutletTemp = 0.0
            self.SourceSideWaterMassFlowRate = 0.0
            self.LoadSideWaterMassFlowRate = 0.0
            self.IsOn = False
            self.MustRun = True
            
            self.beginEnvironFlag = False
            rho = self.LoadPlantLoc.loop.glycol.getDensity(state, 5.0, routine_name)
            self.LoadSideDesignMassFlow = self.LoadSideVolFlowRate * rho
            
            from EnergyPlus.PlantUtilities import InitComponentNodes
            InitComponentNodes(
                state, 0.0, self.LoadSideDesignMassFlow, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum
            )
            
            rho = self.SourcePlantLoc.loop.glycol.getDensity(state, 5.0, routine_name)
            self.SourceSideDesignMassFlow = self.SourceSideVolFlowRate * rho
            
            InitComponentNodes(
                state,
                0.0,
                self.SourceSideDesignMassFlow,
                self.SourceSideInletNodeNum,
                self.SourceSideOutletNodeNum,
            )
            
            state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp = 35.0
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.beginEnvironFlag = True
        
        self.Running = 0
        self.MustRun = True
        self.LoadSideWaterMassFlowRate = 0.0
        self.SourceSideWaterMassFlowRate = 0.0
        self.Power = 0.0
        self.QLoad = 0.0
        self.QSource = 0.0

    def calculate(self, state: Any, my_load: List[float]) -> None:
        GAMMA = 1.114
        HEAT_BAL_TOL = 0.0005
        RELAX_PARAM = 0.6
        SMALL_NUM = 1.0e-20
        ITERATION_LIMIT = 500
        routine_name = "CalcGshpModel"
        routine_name_load_side_refridg_temp = "CalcGSHPModel:LoadSideRefridgTemp"
        routine_name_source_side_refridg_temp = "CalcGSHPModel:SourceSideRefridgTemp"
        routine_name_compress_inlet_temp = "CalcGSHPModel:CompressInletTemp"
        routine_name_suction_pr = "CalcGSHPModel:SuctionPr"
        routine_name_comp_suction_temp = "CalcGSHPModel:CompSuctionTemp"
        
        if my_load[0] < 0.0:
            self.MustRun = True
            self.IsOn = True
        else:
            self.MustRun = False
            self.IsOn = False
        
        if not self.MustRun:
            self.LoadSideWaterMassFlowRate = 0.0
            from EnergyPlus.PlantUtilities import SetComponentFlowRate, PullCompInterconnectTrigger
            from EnergyPlus.Plant.DataPlant import CriteriaType
            
            SetComponentFlowRate(
                state,
                self.LoadSideWaterMassFlowRate,
                self.LoadSideInletNodeNum,
                self.LoadSideOutletNodeNum,
                self.LoadPlantLoc,
            )
            self.SourceSideWaterMassFlowRate = 0.0
            SetComponentFlowRate(
                state,
                self.SourceSideWaterMassFlowRate,
                self.SourceSideInletNodeNum,
                self.SourceSideOutletNodeNum,
                self.SourcePlantLoc,
            )
            PullCompInterconnectTrigger(
                state,
                self.LoadPlantLoc,
                self.CondMassFlowIndex,
                self.SourcePlantLoc,
                CriteriaType.MassFlowRate,
                self.SourceSideWaterMassFlowRate,
            )
            self.QLoad = 0.0
            self.QSource = 0.0
            self.Power = 0.0
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
            return
        
        from EnergyPlus.PlantUtilities import SetComponentFlowRate, PullCompInterconnectTrigger
        from EnergyPlus.Plant.DataPlant import CriteriaType
        from EnergyPlus.DataBranchAirLoopPlant import MassFlowTolerance
        
        self.LoadSideWaterMassFlowRate = self.LoadSideDesignMassFlow
        SetComponentFlowRate(
            state,
            self.LoadSideWaterMassFlowRate,
            self.LoadSideInletNodeNum,
            self.LoadSideOutletNodeNum,
            self.LoadPlantLoc,
        )
        
        self.SourceSideWaterMassFlowRate = self.SourceSideDesignMassFlow
        SetComponentFlowRate(
            state,
            self.SourceSideWaterMassFlowRate,
            self.SourceSideInletNodeNum,
            self.SourceSideOutletNodeNum,
            self.SourcePlantLoc,
        )
        
        self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
        self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
        
        if (
            self.LoadSideWaterMassFlowRate < MassFlowTolerance
            or self.SourceSideWaterMassFlowRate < MassFlowTolerance
        ):
            self.LoadSideWaterMassFlowRate = 0.0
            SetComponentFlowRate(
                state,
                self.LoadSideWaterMassFlowRate,
                self.LoadSideInletNodeNum,
                self.LoadSideOutletNodeNum,
                self.LoadPlantLoc,
            )
            self.SourceSideWaterMassFlowRate = 0.0
            SetComponentFlowRate(
                state,
                self.SourceSideWaterMassFlowRate,
                self.SourceSideInletNodeNum,
                self.SourceSideOutletNodeNum,
                self.SourcePlantLoc,
            )
            PullCompInterconnectTrigger(
                state,
                self.LoadPlantLoc,
                self.CondMassFlowIndex,
                self.SourcePlantLoc,
                CriteriaType.MassFlowRate,
                self.SourceSideWaterMassFlowRate,
            )
            self.QLoad = 0.0
            self.QSource = 0.0
            self.Power = 0.0
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
            return
        
        PullCompInterconnectTrigger(
            state,
            self.LoadPlantLoc,
            self.CondMassFlowIndex,
            self.SourcePlantLoc,
            CriteriaType.MassFlowRate,
            self.SourceSideWaterMassFlowRate,
        )
        
        initial_q_source = 0.0
        initial_q_load = 0.0
        iteration_count = 0
        
        cp_source_side = self.SourcePlantLoc.loop.glycol.getSpecificHeat(
            state, self.SourceSideWaterInletTemp, routine_name
        )
        cp_load_side = self.LoadPlantLoc.loop.glycol.getSpecificHeat(
            state, self.LoadSideWaterInletTemp, routine_name
        )
        
        load_side_effect = 1.0 - math.exp(-self.LoadSideUACoeff / (cp_load_side * self.LoadSideWaterMassFlowRate))
        source_side_effect = 1.0 - math.exp(
            -self.SourceSideUACoeff / (cp_source_side * self.SourceSideWaterMassFlowRate)
        )
        
        from EnergyPlus.General import (
            ShowSevereError,
            ShowContinueError,
            ShowContinueErrorTimeStamp,
            ShowFatalError,
            ShowWarningError,
        )
        
        main_loop_done = False
        while not main_loop_done:
            iteration_count += 1
            
            load_side_refridg_temp = (
                self.LoadSideWaterInletTemp
                - initial_q_load / (load_side_effect * cp_load_side * self.LoadSideWaterMassFlowRate)
            )
            
            source_side_refridg_temp = (
                self.SourceSideWaterInletTemp
                + initial_q_source / (source_side_effect * cp_source_side * self.SourceSideWaterMassFlowRate)
            )
            
            source_side_pressure = self.refrig.getSatPressure(state, source_side_refridg_temp, routine_name)
            load_side_pressure = self.refrig.getSatPressure(state, load_side_refridg_temp, routine_name)
            
            if source_side_pressure < self.LowPressCutoff:
                ShowSevereError(
                    state,
                    f"{MODULE_COMP_NAME}=\"{self.Name}\" Cooling Source Side Pressure Less than the Design Minimum",
                )
                ShowContinueError(
                    state,
                    f"Cooling Source Side Pressure={source_side_pressure:.2f} and user specified Design Minimum Pressure={self.LowPressCutoff:.2f}",
                )
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            
            if load_side_pressure > self.HighPressCutoff:
                ShowSevereError(
                    state,
                    f"{MODULE_COMP_NAME}=\"{self.Name}\" Cooling Load Side Pressure greater than the Design Maximum",
                )
                ShowContinueError(
                    state,
                    f"Cooling Load Side Pressure={load_side_pressure:.2f} and user specified Design Maximum Pressure={self.HighPressCutoff:.2f}",
                )
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            
            suction_pr = load_side_pressure - self.CompSucPressDrop
            discharge_pr = source_side_pressure + self.CompSucPressDrop
            
            if suction_pr < self.LowPressCutoff:
                ShowSevereError(
                    state,
                    f"{MODULE_COMP_NAME}=\"{self.Name}\" Cooling Suction Pressure Less than the Design Minimum",
                )
                ShowContinueError(
                    state,
                    f"Cooling Suction Pressure={suction_pr:.2f} and user specified Design Minimum Pressure={self.LowPressCutoff:.2f}",
                )
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            
            if discharge_pr > self.HighPressCutoff:
                ShowSevereError(
                    state,
                    f"{MODULE_COMP_NAME}=\"{self.Name}\" Cooling Discharge Pressure greater than the Design Maximum",
                )
                ShowContinueError(
                    state,
                    f"Cooling Discharge Pressure={discharge_pr:.2f} and user specified Design Maximum Pressure={self.HighPressCutoff:.2f}",
                )
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            
            qual = 1.0
            load_side_outlet_enth = self.refrig.getSatEnthalpy(
                state, load_side_refridg_temp, qual, routine_name_load_side_refridg_temp
            )
            
            qual = 0.0
            source_side_outlet_enth = self.refrig.getSatEnthalpy(
                state, source_side_refridg_temp, qual, routine_name_source_side_refridg_temp
            )
            
            compress_inlet_temp = load_side_refridg_temp + self.SuperheatTemp
            
            super_heat_enth = self.refrig.getSupHeatEnthalpy(
                state, compress_inlet_temp, load_side_pressure, routine_name_compress_inlet_temp
            )
            
            comp_suction_sat_temp = self.refrig.getSatTemperature(state, suction_pr, routine_name_suction_pr)
            
            t110 = comp_suction_sat_temp
            t111 = comp_suction_sat_temp + 100.0
            
            suction_loop_done = False
            while not suction_loop_done:
                comp_suction_temp = 0.5 * (t110 + t111)
                
                comp_suction_enth = self.refrig.getSupHeatEnthalpy(
                    state, comp_suction_temp, suction_pr, routine_name_comp_suction_temp
                )
                
                if abs(comp_suction_enth - super_heat_enth) / super_heat_enth < 0.0001:
                    suction_loop_done = True
                elif comp_suction_enth < super_heat_enth:
                    t110 = comp_suction_temp
                else:
                    t111 = comp_suction_temp
            
            comp_suction_density = self.refrig.getSupHeatDensity(
                state, comp_suction_temp, suction_pr, routine_name_comp_suction_temp
            )
            mass_ref = self.CompPistonDisp * comp_suction_density * (
                1
                + self.CompClearanceFactor
                - self.CompClearanceFactor * math.pow(discharge_pr / suction_pr, 1 / GAMMA)
            )
            
            self.QLoad = mass_ref * (load_side_outlet_enth - source_side_outlet_enth)
            
            self.Power = self.PowerLosses + (
                mass_ref
                * GAMMA
                / (GAMMA - 1)
                * suction_pr
                / comp_suction_density
                / self.LossFactor
                * (math.pow(discharge_pr / suction_pr, (GAMMA - 1) / GAMMA) - 1)
            )
            
            self.QSource = self.Power + self.QLoad
            
            if (
                abs((self.QSource - initial_q_source) / (initial_q_source + SMALL_NUM)) < HEAT_BAL_TOL
                or iteration_count > ITERATION_LIMIT
            ):
                if iteration_count > ITERATION_LIMIT:
                    ShowWarningError(
                        state, "HeatPump:WaterToWater:ParameterEstimation, Cooling did not converge"
                    )
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, f"Heatpump Name = {self.Name}")
                    ShowContinueError(
                        state,
                        f"Heat Imbalance (%)             = {abs(100.0 * (self.QSource - initial_q_source) / (initial_q_source + SMALL_NUM))}",
                    )
                    ShowContinueError(state, f"Load-side heat transfer rate   = {self.QLoad}")
                    ShowContinueError(state, f"Source-side heat transfer rate = {self.QSource}")
                    ShowContinueError(
                        state, f"Source-side mass flow rate     = {self.SourceSideWaterMassFlowRate}"
                    )
                    ShowContinueError(state, f"Load-side mass flow rate       = {self.LoadSideWaterMassFlowRate}")
                    ShowContinueError(state, f"Source-side inlet temperature  = {self.SourceSideWaterInletTemp}")
                    ShowContinueError(state, f"Load-side inlet temperature    = {self.LoadSideWaterInletTemp}")
                main_loop_done = True
            else:
                initial_q_source += RELAX_PARAM * (self.QSource - initial_q_source)
                initial_q_load += RELAX_PARAM * (self.QLoad - initial_q_load)
        
        if abs(my_load[0]) < self.QLoad:
            duty_factor = abs(my_load[0]) / self.QLoad
            self.QLoad = abs(my_load[0])
            self.Power *= duty_factor
            self.QSource *= duty_factor
            self.LoadSideWaterOutletTemp = (
                self.LoadSideWaterInletTemp - self.QLoad / (self.LoadSideWaterMassFlowRate * cp_load_side)
            )
            self.SourceSideWaterOutletTemp = (
                self.SourceSideWaterInletTemp + self.QSource / (self.SourceSideWaterMassFlowRate * cp_source_side)
            )
            return
        
        self.LoadSideWaterOutletTemp = (
            self.LoadSideWaterInletTemp - self.QLoad / (self.LoadSideWaterMassFlowRate * cp_load_side)
        )
        self.SourceSideWaterOutletTemp = (
            self.SourceSideWaterInletTemp + self.QSource / (self.SourceSideWaterMassFlowRate * cp_source_side)
        )
        self.Running = 1

    def update(self, state: Any) -> None:
        if not self.MustRun:
            state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].Temp = (
                state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            )
            state.dataLoopNodes.Node[self.LoadSideOutletNodeNum].Temp = (
                state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            )
            self.Power = 0.0
            self.Energy = 0.0
            self.QSource = 0.0
            self.QLoad = 0.0
            self.QSourceEnergy = 0.0
            self.QLoadEnergy = 0.0
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.SourceSideWaterOutletTemp = state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].Temp
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            self.LoadSideWaterOutletTemp = state.dataLoopNodes.Node[self.LoadSideOutletNodeNum].Temp
        else:
            state.dataLoopNodes.Node[self.LoadSideOutletNodeNum].Temp = self.LoadSideWaterOutletTemp
            state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].Temp = self.SourceSideWaterOutletTemp
            
            reporting_constant = state.dataHVACGlobal.TimeStepSysSec
            
            self.Energy = self.Power * reporting_constant
            self.QSourceEnergy = self.QSource * reporting_constant
            self.QLoadEnergy = self.QLoad * reporting_constant
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp

    def oneTimeInit(self, state: Any) -> None:
        pass

    def oneTimeInit_new(self, state: Any) -> None:
        pass


@dataclass
class HeatPumpWaterToWaterCoolingData(BaseGlobalStruct):
    NumGSHPs: int = 0
    GetWWHPCoolingInput: bool = True
    GSHP: List[GshpPeCoolingSpecs] = field(default_factory=list)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.NumGSHPs = 0
        self.GetWWHPCoolingInput = True
        self.GSHP = []


def GetGshpInput(state: Any) -> None:
    routine_name = "GetGshpInput"
    
    from EnergyPlus.General import (
        ShowFatalError,
        ShowSevereError,
        ShowSevereItemNotFound,
    )
    from EnergyPlus.NodeInputManager import GetOnlySingleNode
    from EnergyPlus.Node import TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
    from EnergyPlus.PlantUtilities import RegisterPlantCompDesignFlow
    from EnergyPlus.OutputProcessor import SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
    from EnergyPlus.Constant import Units, eResource
    from EnergyPlus.Plant.DataPlant import PlantEquipmentType
    
    state.dataHPWaterToWaterClg.NumGSHPs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, MODULE_COMP_NAME_UC
    )
    
    if state.dataHPWaterToWaterClg.NumGSHPs <= 0:
        ShowSevereError(state, "No Equipment found in SimGshp")
        errors_found = True
    else:
        errors_found = False
    
    state.dataHPWaterToWaterClg.GSHP = [GshpPeCoolingSpecs() for _ in range(state.dataHPWaterToWaterClg.NumGSHPs)]
    
    for gshp_num in range(state.dataHPWaterToWaterClg.NumGSHPs):
        this_gshp = state.dataHPWaterToWaterClg.GSHP[gshp_num]
        
        alph_array = [""] * 5
        num_array = [0.0] * 23
        
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, MODULE_COMP_NAME_UC, gshp_num + 1, alph_array, len(alph_array), num_array, len(num_array), 0
        )
        
        this_gshp.Name = alph_array[0]
        this_gshp.WWHPPlantTypeOfNum = PlantEquipmentType.HPWaterPECooling
        
        this_gshp.COP = num_array[0]
        if num_array[0] == 0.0:
            ShowSevereError(state, f"{MODULE_COMP_NAME}:COP = 0.0, Heatpump={this_gshp.Name}")
            errors_found = True
        
        this_gshp.NomCap = num_array[1]
        this_gshp.MinPartLoadRat = num_array[2]
        this_gshp.MaxPartLoadRat = num_array[3]
        this_gshp.OptPartLoadRat = num_array[4]
        
        this_gshp.LoadSideVolFlowRate = num_array[5]
        if num_array[5] == 0.0:
            ShowSevereError(
                state, f"{MODULE_COMP_NAME}:Load Side Vol Flow Rate = 0.0, Heatpump={this_gshp.Name}"
            )
            errors_found = True
        
        this_gshp.SourceSideVolFlowRate = num_array[6]
        if num_array[6] == 0.0:
            ShowSevereError(
                state, f"{MODULE_COMP_NAME}:Source Side Vol Flow Rate = 0.0, Heatpump={this_gshp.Name}"
            )
            errors_found = True
        
        this_gshp.LoadSideUACoeff = num_array[7]
        if num_array[8] == 0.0:
            ShowSevereError(
                state,
                f"{MODULE_COMP_NAME}:Load Side Heat Transfer Coefficient = 0.0, Heatpump={this_gshp.Name}",
            )
            errors_found = True
        
        this_gshp.SourceSideUACoeff = num_array[8]
        if num_array[7] == 0.0:
            ShowSevereError(
                state,
                f"{MODULE_COMP_NAME}:Source Side Heat Transfer Coefficient = 0.0, Heatpump={this_gshp.Name}",
            )
            errors_found = True
        
        this_gshp.CompPistonDisp = num_array[9]
        if num_array[9] == 0.0:
            ShowSevereError(
                state,
                f"{MODULE_COMP_NAME}:Compressor Piston displacement/Stroke = 0.0, Heatpump={this_gshp.Name}",
            )
            errors_found = True
        
        this_gshp.CompClearanceFactor = num_array[10]
        if num_array[10] == 0.0:
            ShowSevereError(
                state, f"{MODULE_COMP_NAME}:Compressor Clearance Factor = 0.0, Heatpump={this_gshp.Name}"
            )
            errors_found = True
        
        this_gshp.CompSucPressDrop = num_array[11]
        if num_array[11] == 0.0:
            ShowSevereError(state, f"{MODULE_COMP_NAME}: Pressure Drop = 0.0, Heatpump={this_gshp.Name}")
            errors_found = True
        
        this_gshp.SuperheatTemp = num_array[12]
        if num_array[12] == 0.0:
            ShowSevereError(
                state, f"{MODULE_COMP_NAME}:Source Side SuperHeat = 0.0, Heatpump={this_gshp.Name}"
            )
            errors_found = True
        
        this_gshp.PowerLosses = num_array[13]
        if num_array[13] == 0.0:
            ShowSevereError(state, f"{MODULE_COMP_NAME}:Compressor Power Loss = 0.0, Heatpump={this_gshp.Name}")
            errors_found = True
        
        this_gshp.LossFactor = num_array[14]
        if num_array[14] == 0.0:
            ShowSevereError(state, f"{MODULE_COMP_NAME}:Efficiency = 0.0, Heatpump={this_gshp.Name}")
            errors_found = True
        
        this_gshp.HighPressCutoff = num_array[15]
        if num_array[15] == 0.0:
            this_gshp.HighPressCutoff = 500000000.0
        
        this_gshp.LowPressCutoff = num_array[16]
        if num_array[16] == 0.0:
            this_gshp.LowPressCutoff = 0.0
        
        this_gshp.SourceSideInletNodeNum = GetOnlySingleNode(
            state,
            alph_array[1],
            errors_found,
            ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
            this_gshp.Name,
            FluidType.Water,
            ConnectionType.Inlet,
            CompFluidStream.Primary,
            ObjectIsNotParent,
        )
        
        this_gshp.SourceSideOutletNodeNum = GetOnlySingleNode(
            state,
            alph_array[2],
            errors_found,
            ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
            this_gshp.Name,
            FluidType.Water,
            ConnectionType.Outlet,
            CompFluidStream.Primary,
            ObjectIsNotParent,
        )
        
        this_gshp.LoadSideInletNodeNum = GetOnlySingleNode(
            state,
            alph_array[3],
            errors_found,
            ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
            this_gshp.Name,
            FluidType.Water,
            ConnectionType.Inlet,
            CompFluidStream.Secondary,
            ObjectIsNotParent,
        )
        
        this_gshp.LoadSideOutletNodeNum = GetOnlySingleNode(
            state,
            alph_array[4],
            errors_found,
            ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
            this_gshp.Name,
            FluidType.Water,
            ConnectionType.Outlet,
            CompFluidStream.Secondary,
            ObjectIsNotParent,
        )
        
        TestCompSet(state, MODULE_COMP_NAME_UC, this_gshp.Name, alph_array[1], alph_array[2], "Condenser Water Nodes")
        TestCompSet(state, MODULE_COMP_NAME_UC, this_gshp.Name, alph_array[3], alph_array[4], "Chilled Water Nodes")
        
        RegisterPlantCompDesignFlow(state, this_gshp.SourceSideInletNodeNum, 0.5 * this_gshp.SourceSideVolFlowRate)
        
        this_gshp.QLoad = 0.0
        this_gshp.QSource = 0.0
        this_gshp.Power = 0.0
        this_gshp.LoadSideWaterInletTemp = 0.0
        this_gshp.SourceSideWaterInletTemp = 0.0
        this_gshp.LoadSideWaterOutletTemp = 0.0
        this_gshp.SourceSideWaterOutletTemp = 0.0
        this_gshp.SourceSideWaterMassFlowRate = 0.0
        this_gshp.LoadSideWaterMassFlowRate = 0.0
        this_gshp.IsOn = False
        this_gshp.MustRun = True
        
        from EnergyPlus.FluidProperties import GetRefrig
        
        this_gshp.refrig = GetRefrig(state, GSHP_REFRIGERANT)
        if this_gshp.refrig is None:
            ShowSevereItemNotFound(state, "Refrigerant", GSHP_REFRIGERANT)
            errors_found = True
    
    if errors_found:
        ShowFatalError(state, "Errors Found in getting Gshp input")
    
    for gshp_num in range(state.dataHPWaterToWaterClg.NumGSHPs):
        this_gshp = state.dataHPWaterToWaterClg.GSHP[gshp_num]
        
        SetupOutputVariable(
            state,
            "Heat Pump Electricity Rate",
            Units.W,
            this_gshp.Power,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Electricity Energy",
            Units.J,
            this_gshp.Energy,
            TimeStepType.System,
            StoreType.Sum,
            this_gshp.Name,
            eResource.Electricity,
            Group.Plant,
            EndUseCat.Cooling,
        )
        
        SetupOutputVariable(
            state,
            "Heat Pump Load Side Heat Transfer Rate",
            Units.W,
            this_gshp.QLoad,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Load Side Heat Transfer Energy",
            Units.J,
            this_gshp.QLoadEnergy,
            TimeStepType.System,
            StoreType.Sum,
            this_gshp.Name,
        )
        
        SetupOutputVariable(
            state,
            "Heat Pump Source Side Heat Transfer Rate",
            Units.W,
            this_gshp.QSource,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Source Side Heat Transfer Energy",
            Units.J,
            this_gshp.QSourceEnergy,
            TimeStepType.System,
            StoreType.Sum,
            this_gshp.Name,
        )
        
        SetupOutputVariable(
            state,
            "Heat Pump Load Side Outlet Temperature",
            Units.C,
            this_gshp.LoadSideWaterOutletTemp,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Load Side Inlet Temperature",
            Units.C,
            this_gshp.LoadSideWaterInletTemp,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Source Side Outlet Temperature",
            Units.C,
            this_gshp.SourceSideWaterOutletTemp,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Source Side Inlet Temperature",
            Units.C,
            this_gshp.SourceSideWaterInletTemp,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Load Side Mass Flow Rate",
            Units.kg_s,
            this_gshp.LoadSideWaterMassFlowRate,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )
        SetupOutputVariable(
            state,
            "Heat Pump Source Side Mass Flow Rate",
            Units.kg_s,
            this_gshp.SourceSideWaterMassFlowRate,
            TimeStepType.System,
            StoreType.Average,
            this_gshp.Name,
        )

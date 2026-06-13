# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus/Data/EnergyPlusData.hh
# - PlantLocation: EnergyPlus/Plant/PlantLocation.hh
# - PlantComponent: EnergyPlus/PlantComponent.hh
# - MaterialPhaseChange: EnergyPlus/PhaseChangeModeling/HysteresisModel.hh
# - Schedule: EnergyPlus/ScheduleManager.hh (Sched::Schedule)
# - PlantUtilities: EnergyPlus/PlantUtilities.hh
# - OutputProcessor: EnergyPlus/OutputProcessor.hh
# - Node: EnergyPlus/NodeInputManager.hh
# - Material: EnergyPlus/DataHeatBalance.hh
# - DataPlant: EnergyPlus/Plant/DataPlant.hh
# - DataLoopNode: EnergyPlus/DataLoopNode.hh
# - DataIPShortCut: EnergyPlus/DataIPShortCuts.hh
# - DataGlobals: EnergyPlus/DataGlobals.hh

from dataclasses import dataclass, field
from typing import Optional, Any
import math

_pcm_storage_instance: Optional['PCMStorageData'] = None
_get_pcm_input_flag = True
_charging_mode_state = {'chargingMode': False}

@dataclass
class PCMStorageData:
    Initialized: bool = False
    MyPlantScanFlag: bool = True
    MyEnvrnFlag: bool = True
    
    Name: str = ""
    AvailabilityScheduleName: str = ""
    PCMMaterialNum: int = 0
    PCMmat: Optional[Any] = None
    TankCapacity: float = 0.0
    HeatLossRate: float = 0.0
    MeltingTemp: float = 0.0
    FreezingTemp: float = 0.0
    LatentHeat: float = 0.0
    SpecificHeat: float = 0.0
    Effectiveness: float = 0.9
    
    sourcePlantLoc: Optional[Any] = None
    PlantSideInletNode: int = 0
    PlantSideOutletNode: int = 0
    usePlantLoc: Optional[Any] = None
    UseSideInletNode: int = 0
    UseSideOutletNode: int = 0
    
    AvailabilitySchedule: Optional[Any] = None
    
    PCM_TankTemp: float = 0.0
    EnergyStored: float = 0.0
    PercentCapacity: float = 0.0
    HeatLossRate_W: float = 0.0
    useheatTransfer: float = 0.0
    plantheatTransfer: float = 0.0
    DesignMassFlowRate: float = 0.0
    UseSideDesignFlowRate: float = 0.0
    PlantSideDesignFlowRate: float = 0.0
    UseSideMassFlowRate: float = 0.0
    PlantSideMassFlowRate: float = 0.0
    
    @staticmethod
    def instance() -> 'PCMStorageData':
        global _pcm_storage_instance
        if _pcm_storage_instance is None:
            _pcm_storage_instance = PCMStorageData()
        return _pcm_storage_instance
    
    @staticmethod
    def factory(state: Any, objectName: str) -> 'PCMStorageData':
        global _get_pcm_input_flag
        if _get_pcm_input_flag:
            GetPCMStorageInput(state)
            _get_pcm_input_flag = False
        
        pcm = PCMStorageData.instance()
        if pcm.Name == objectName:
            return pcm
        
        raise RuntimeError(f"PCMStorage factory: No PCM storage found with name: {objectName}")
    
    def Init(self, state: Any) -> None:
        if self.MyPlantScanFlag:
            errFlag = False
            
            state.PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, state.DataPlant.PlantEquipmentType.TS_PCM,
                self.usePlantLoc, errFlag, None, None, None, self.UseSideInletNode, None, None)
            
            state.PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, state.DataPlant.PlantEquipmentType.TS_PCM,
                self.sourcePlantLoc, errFlag, None, None, None, self.PlantSideInletNode, None, None)
            
            if errFlag:
                raise RuntimeError(f"PCMStorageData::Init: Error scanning plant loops for PCM tank named: {self.Name}")
            
            RegisterPCMStorageOutputVariables(state)
            self.MyPlantScanFlag = False
        
        temp = state.dataLoopNodes.Node(self.UseSideInletNode).Temp
        
        rhoUseProps = self.usePlantLoc.loop.glycol
        rhoUse = rhoUseProps.getDensity(state, temp, "PCMStorageData::Calculate")
        
        rhoPlantProps = self.sourcePlantLoc.loop.glycol
        rhoPlant = rhoPlantProps.getDensity(state, temp, "PCMStorageData::Calculate")
        
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            if self.UseSideDesignFlowRate <= 0.0:
                initMassFlow = 0.0
                if self.UseSideInletNode > 0:
                    initMassFlow = state.dataLoopNodes.Node(self.UseSideInletNode).MassFlowRate
                if initMassFlow > 0.0:
                    self.UseSideDesignFlowRate = initMassFlow / rhoUse
                elif self.PlantSideDesignFlowRate > 0.0:
                    self.UseSideDesignFlowRate = self.PlantSideDesignFlowRate
                else:
                    self.UseSideDesignFlowRate = 1.0e-4
            
            if self.PlantSideDesignFlowRate <= 0.0:
                initMassFlow = 0.0
                if self.PlantSideInletNode > 0:
                    initMassFlow = state.dataLoopNodes.Node(self.PlantSideInletNode).MassFlowRate
                if initMassFlow > 0.0:
                    self.PlantSideDesignFlowRate = initMassFlow / rhoPlant
                else:
                    self.PlantSideDesignFlowRate = self.UseSideDesignFlowRate
            
            self.UseSideMassFlowRate = self.UseSideDesignFlowRate * rhoUse
            self.PlantSideMassFlowRate = self.PlantSideDesignFlowRate * rhoPlant
            
            if self.TankCapacity <= 0.0:
                designMassFlow = max(self.UseSideMassFlowRate, self.PlantSideMassFlowRate)
                self.TankCapacity = designMassFlow * 3600.0
            
            state.PlantUtilities.InitComponentNodes(state, 0.0, self.UseSideMassFlowRate, self.UseSideInletNode, self.UseSideOutletNode)
            state.PlantUtilities.InitComponentNodes(state, 0.0, self.PlantSideMassFlowRate, self.PlantSideInletNode, self.PlantSideOutletNode)
            
            for compNum in range(1, self.usePlantLoc.branch.TotalComponents + 1):
                self.usePlantLoc.branch.Comp(compNum).FlowPriority = state.DataPlant.LoopFlowStatus.NeedyAndTurnsLoopOn
            
            for compNum in range(1, self.sourcePlantLoc.branch.TotalComponents + 1):
                self.sourcePlantLoc.branch.Comp(compNum).FlowPriority = state.DataPlant.LoopFlowStatus.NeedyAndTurnsLoopOn
            
            self.EnergyStored = self.TankCapacity * self.LatentHeat
            self.PercentCapacity = 100.0
            
            self.MyEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
    
    def Calculate(self, state: Any, plantLoc: Any) -> None:
        useInlet = state.dataLoopNodes.Node(self.UseSideInletNode)
        useOutlet = state.dataLoopNodes.Node(self.UseSideOutletNode)
        plantInlet = state.dataLoopNodes.Node(self.PlantSideInletNode)
        plantOutlet = state.dataLoopNodes.Node(self.PlantSideOutletNode)
        
        dt_seconds = state.dataHVACGlobal.TimeStepSys * 3600.0
        
        temp = state.dataLoopNodes.Node(self.UseSideInletNode).Temp
        
        cpUseProps = self.usePlantLoc.loop.glycol
        CpWaterUse = cpUseProps.getSpecificHeat(state, temp, "PCMStorageData::Calculate")
        
        cpPlantProps = self.sourcePlantLoc.loop.glycol
        CpWaterPlant = cpPlantProps.getSpecificHeat(state, temp, "PCMStorageData::Calculate")
        
        plantOutletTemp = plantInlet.Temp - (self.Effectiveness * (plantInlet.Temp - self.FreezingTemp))
        useOutletTemp = useInlet.Temp + (self.Effectiveness * (self.MeltingTemp - useInlet.Temp))
        
        state.PlantUtilities.SafeCopyPlantNode(state, self.UseSideInletNode, self.UseSideOutletNode)
        state.PlantUtilities.SafeCopyPlantNode(state, self.PlantSideInletNode, self.PlantSideOutletNode)
        
        if self.AvailabilitySchedule.getCurrentVal() <= 0.0:
            useInlet.MassFlowRate = 0.0
            useOutlet.MassFlowRate = 0.0
            plantInlet.MassFlowRate = 0.0
            plantOutlet.MassFlowRate = 0.0
            return
        
        if self.PCMmat is not None:
            targetEnthalpy = self.EnergyStored / self.TankCapacity
            Tlow = self.PCMmat.peakTempMelting - 30.0
            Thigh = self.PCMmat.peakTempMelting + 30.0
            approxTemp = self.PCMmat.peakTempMelting
            
            for i in range(25):
                Tmid = 0.5 * (Tlow + Thigh)
                hMid = self.PCMmat.getEnthalpy(
                    Tmid, self.PCMmat.peakTempMelting, self.PCMmat.deltaTempMeltingLow, self.PCMmat.deltaTempMeltingHigh)
                if abs(hMid - targetEnthalpy) < 0.1:
                    approxTemp = Tmid
                    break
                if hMid > targetEnthalpy:
                    Thigh = Tmid
                else:
                    Tlow = Tmid
            
            self.PCM_TankTemp = approxTemp
        
        soc = self.EnergyStored / (self.TankCapacity * self.LatentHeat)
        soc = max(0.0, min(1.0, soc))
        
        cutInSOC = 0.40
        cutOutSOC = 0.95
        
        if soc <= cutInSOC:
            _charging_mode_state['chargingMode'] = True
        if soc >= cutOutSOC:
            _charging_mode_state['chargingMode'] = False
        
        chargingMode = _charging_mode_state['chargingMode']
        
        mUseReq = 0.0
        mPlantReq = 0.0
        
        if chargingMode:
            mPlantReq = self.PlantSideMassFlowRate
        else:
            mUseReq = self.UseSideMassFlowRate
        
        state.PlantUtilities.SetComponentFlowRate(state, mUseReq, self.UseSideInletNode, self.UseSideOutletNode, self.usePlantLoc)
        state.PlantUtilities.SetComponentFlowRate(state, mPlantReq, self.PlantSideInletNode, self.PlantSideOutletNode, self.sourcePlantLoc)
        
        if mUseReq > 0.0:
            useOutlet.Temp = useOutletTemp
        elif mPlantReq > 0.0:
            plantOutlet.Temp = min(plantOutletTemp, state.dataPlnt.PlantLoop(self.sourcePlantLoc.loopNum).MaxTemp)
        
        useheatTransfer_req = mUseReq * CpWaterUse * (useInlet.Temp - useOutletTemp)
        plantheatTransfer_req = mPlantReq * CpWaterPlant * (plantInlet.Temp - plantOutletTemp)
        
        netPowerW = plantheatTransfer_req + useheatTransfer_req - self.HeatLossRate
        
        self.EnergyStored += netPowerW * dt_seconds
        
        self.useheatTransfer = useheatTransfer_req
        self.plantheatTransfer = plantheatTransfer_req
        
        self.EnergyStored = max(0.0, min(self.TankCapacity * self.LatentHeat, self.EnergyStored))
        self.PercentCapacity = 100.0 * self.EnergyStored / (self.TankCapacity * self.LatentHeat)
    
    def simulate(self, state: Any, calledFromLocation: Any, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        SimulatePCMStorage(state, calledFromLocation, FirstHVACIteration, CurLoad, RunFlag)
    
    def oneTimeInit(self, state: Any) -> None:
        self.Init(state)

def SimulatePCMStorage(state: Any, plantLoc: Any, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
    PCM = PCMStorageData.instance()
    
    if not PCM.Initialized:
        PCM.Init(state)
    
    PCM.Calculate(state, plantLoc)

def RegisterPCMStorageOutputVariables(state: Any) -> None:
    PCM = PCMStorageData.instance()
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Percent Capacity",
        state.Constant.Units.None,
        PCM.PercentCapacity,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Heat Loss Rate",
        state.Constant.Units.W,
        PCM.HeatLossRate,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Energy Stored",
        state.Constant.Units.J,
        PCM.EnergyStored,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Tank Temperature",
        state.Constant.Units.C,
        PCM.PCM_TankTemp,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Heat Transfer Rate",
        state.Constant.Units.W,
        PCM.useheatTransfer,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Heat Transfer Rate",
        state.Constant.Units.W,
        PCM.plantheatTransfer,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Inlet Temperature",
        state.Constant.Units.C,
        state.dataLoopNodes.Node(PCM.UseSideInletNode).Temp,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Outlet Temperature",
        state.Constant.Units.C,
        state.dataLoopNodes.Node(PCM.UseSideOutletNode).Temp,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Mass Flow Rate",
        state.Constant.Units.kg_s,
        state.dataLoopNodes.Node(PCM.UseSideInletNode).MassFlowRate,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Inlet Temperature",
        state.Constant.Units.C,
        state.dataLoopNodes.Node(PCM.PlantSideInletNode).Temp,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Outlet Temperature",
        state.Constant.Units.C,
        state.dataLoopNodes.Node(PCM.PlantSideOutletNode).Temp,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)
    
    state.OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Mass Flow Rate",
        state.Constant.Units.kg_s,
        state.dataLoopNodes.Node(PCM.PlantSideInletNode).MassFlowRate,
        state.OutputProcessor.TimeStepType.System,
        state.OutputProcessor.StoreType.Average,
        PCM.Name)

def GetPCMStorageInput(state: Any) -> None:
    RoutineName = "GetPCMStorageInput"
    
    PCM = PCMStorageData.instance()
    ErrorsFound = False
    
    NumPCMObjs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ThermalStorage:PCM")
    if NumPCMObjs != 1:
        state.OutputProcessor.ShowSevereError(state, "Exactly one ThermalStorage:PCM object is required.")
        return
    
    state.dataIPShortCut.cCurrentModuleObject = "ThermalStorage:PCM"
    
    state.dataInputProcessing.inputProcessor.getObjectItem(
        state,
        state.dataIPShortCut.cCurrentModuleObject,
        1,
        state.dataIPShortCut.cAlphaArgs,
        state.dataIPShortCut.NumAlphas,
        state.dataIPShortCut.rNumericArgs,
        state.dataIPShortCut.NumNums,
        state.dataIPShortCut.IOStat,
        None,
        state.dataIPShortCut.lAlphaFieldBlanks,
        state.dataIPShortCut.cAlphaFieldNames,
        state.dataIPShortCut.cNumericFieldNames)
    
    PCM.Name = state.dataIPShortCut.cAlphaArgs(1)
    PCM.AvailabilityScheduleName = state.dataIPShortCut.cAlphaArgs(2)
    
    if state.dataIPShortCut.lAlphaFieldBlanks(2):
        PCM.AvailabilitySchedule = state.Sched.GetScheduleAlwaysOn(state)
    else:
        PCM.AvailabilitySchedule = state.Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs(2))
        if PCM.AvailabilitySchedule is None:
            state.OutputProcessor.ShowSevereItemNotFound(
                state, RoutineName, state.dataIPShortCut.cCurrentModuleObject,
                state.dataIPShortCut.cAlphaFieldNames(2), state.dataIPShortCut.cAlphaArgs(2))
            ErrorsFound = True
    
    matNum = state.Material.GetMaterialNum(state, state.dataIPShortCut.cAlphaArgs(7))
    if matNum == 0:
        state.OutputProcessor.ShowSevereError(
            state,
            f"{state.dataIPShortCut.cCurrentModuleObject}: Invalid PCM material name: {state.dataIPShortCut.cAlphaArgs(7)}")
        ErrorsFound = True
    else:
        savedModuleObj = state.dataIPShortCut.cCurrentModuleObject
        state.dataIPShortCut.cCurrentModuleObject = savedModuleObj
        
        mat = state.dataMaterial.materials(matNum)
        
        if not mat.hasPCM:
            state.OutputProcessor.ShowSevereError(
                state,
                f"{state.dataIPShortCut.cCurrentModuleObject}: Material {mat.Name} is not a phase change material.")
            ErrorsFound = True
        else:
            PCM.PCMMaterialNum = matNum
            PCM.PCMmat = mat
            
            PCM.TankCapacity = state.dataIPShortCut.rNumericArgs(1)
            PCM.HeatLossRate = state.dataIPShortCut.rNumericArgs(2)
            PCM.UseSideDesignFlowRate = state.dataIPShortCut.rNumericArgs(3)
            PCM.PlantSideDesignFlowRate = state.dataIPShortCut.rNumericArgs(4)
            
            if PCM.UseSideDesignFlowRate < 0.0:
                state.OutputProcessor.ShowWarningError(
                    state,
                    f"{state.dataIPShortCut.cCurrentModuleObject}={PCM.Name}, Use Side Design Flow Rate was entered as {PCM.UseSideDesignFlowRate:.6e}.  This will be autosized during initialization.")
            
            if PCM.PlantSideDesignFlowRate < 0.0:
                state.OutputProcessor.ShowWarningError(
                    state,
                    f"{state.dataIPShortCut.cCurrentModuleObject}={PCM.Name}, Plant Side Design Flow Rate was entered as {PCM.PlantSideDesignFlowRate:.6e}.  This will be autosized during initialization.")
            
            PCM.MeltingTemp = PCM.PCMmat.peakTempMelting
            PCM.FreezingTemp = PCM.PCMmat.peakTempFreezing
            PCM.LatentHeat = PCM.PCMmat.totalLatentHeat
            PCM.SpecificHeat = (PCM.PCMmat.specificHeatSolid + PCM.PCMmat.specificHeatLiquid) / 2.0
    
    PCM.PlantSideInletNode = state.Node.GetOnlySingleNode(
        state,
        state.dataIPShortCut.cAlphaArgs(3),
        ErrorsFound,
        state.Node.ConnectionObjectType.ThermalStoragePCM,
        PCM.Name,
        state.Node.FluidType.Water,
        state.Node.ConnectionType.Inlet,
        state.Node.CompFluidStream.Primary,
        state.Node.ObjectIsNotParent)
    
    PCM.PlantSideOutletNode = state.Node.GetOnlySingleNode(
        state,
        state.dataIPShortCut.cAlphaArgs(4),
        ErrorsFound,
        state.Node.ConnectionObjectType.ThermalStoragePCM,
        PCM.Name,
        state.Node.FluidType.Water,
        state.Node.ConnectionType.Outlet,
        state.Node.CompFluidStream.Primary,
        state.Node.ObjectIsNotParent)
    
    PCM.UseSideInletNode = state.Node.GetOnlySingleNode(
        state,
        state.dataIPShortCut.cAlphaArgs(5),
        ErrorsFound,
        state.Node.ConnectionObjectType.ThermalStoragePCM,
        PCM.Name,
        state.Node.FluidType.Water,
        state.Node.ConnectionType.Inlet,
        state.Node.CompFluidStream.Secondary,
        state.Node.ObjectIsNotParent)
    
    PCM.UseSideOutletNode = state.Node.GetOnlySingleNode(
        state,
        state.dataIPShortCut.cAlphaArgs(6),
        ErrorsFound,
        state.Node.ConnectionObjectType.ThermalStoragePCM,
        PCM.Name,
        state.Node.FluidType.Water,
        state.Node.ConnectionType.Outlet,
        state.Node.CompFluidStream.Secondary,
        state.Node.ObjectIsNotParent)
    
    state.Node.TestCompSet(
        state,
        state.dataIPShortCut.cCurrentModuleObject,
        PCM.Name,
        state.dataIPShortCut.cAlphaArgs(3),
        state.dataIPShortCut.cAlphaArgs(4),
        "PCM Storage Plant Side")
    
    state.Node.TestCompSet(
        state,
        state.dataIPShortCut.cCurrentModuleObject,
        PCM.Name,
        state.dataIPShortCut.cAlphaArgs(5),
        state.dataIPShortCut.cAlphaArgs(6),
        "PCM Storage Use Side")
    
    if PCM.TankCapacity <= 0.0:
        state.OutputProcessor.ShowWarningError(
            state,
            f"{state.dataIPShortCut.cCurrentModuleObject}={PCM.Name}, Tank Capacity was entered as {PCM.TankCapacity:.6e} and will be autosized during initialization.")
    
    if ErrorsFound:
        raise RuntimeError(f"Errors found in processing input for {state.dataIPShortCut.cCurrentModuleObject}")

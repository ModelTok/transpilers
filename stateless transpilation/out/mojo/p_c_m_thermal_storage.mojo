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

from math import max, min, fabs

var _pcm_storage_instance: UnsafePointer[PCMStorageData] = UnsafePointer[PCMStorageData]()
var _get_pcm_input_flag: Bool = True
var _charging_mode: Bool = False

struct PCMStorageData:
    var Initialized: Bool
    var MyPlantScanFlag: Bool
    var MyEnvrnFlag: Bool
    
    var Name: String
    var AvailabilityScheduleName: String
    var PCMMaterialNum: Int32
    var PCMmat: UnsafePointer[UInt8]
    var TankCapacity: Float64
    var HeatLossRate: Float64
    var MeltingTemp: Float64
    var FreezingTemp: Float64
    var LatentHeat: Float64
    var SpecificHeat: Float64
    var Effectiveness: Float64
    
    var sourcePlantLoc: UnsafePointer[UInt8]
    var PlantSideInletNode: Int32
    var PlantSideOutletNode: Int32
    var usePlantLoc: UnsafePointer[UInt8]
    var UseSideInletNode: Int32
    var UseSideOutletNode: Int32
    
    var AvailabilitySchedule: UnsafePointer[UInt8]
    
    var PCM_TankTemp: Float64
    var EnergyStored: Float64
    var PercentCapacity: Float64
    var HeatLossRate_W: Float64
    var useheatTransfer: Float64
    var plantheatTransfer: Float64
    var DesignMassFlowRate: Float64
    var UseSideDesignFlowRate: Float64
    var PlantSideDesignFlowRate: Float64
    var UseSideMassFlowRate: Float64
    var PlantSideMassFlowRate: Float64
    
    fn __init__(inout self):
        self.Initialized = False
        self.MyPlantScanFlag = True
        self.MyEnvrnFlag = True
        
        self.Name = String()
        self.AvailabilityScheduleName = String()
        self.PCMMaterialNum = 0
        self.PCMmat = UnsafePointer[UInt8]()
        self.TankCapacity = 0.0
        self.HeatLossRate = 0.0
        self.MeltingTemp = 0.0
        self.FreezingTemp = 0.0
        self.LatentHeat = 0.0
        self.SpecificHeat = 0.0
        self.Effectiveness = 0.9
        
        self.sourcePlantLoc = UnsafePointer[UInt8]()
        self.PlantSideInletNode = 0
        self.PlantSideOutletNode = 0
        self.usePlantLoc = UnsafePointer[UInt8]()
        self.UseSideInletNode = 0
        self.UseSideOutletNode = 0
        
        self.AvailabilitySchedule = UnsafePointer[UInt8]()
        
        self.PCM_TankTemp = 0.0
        self.EnergyStored = 0.0
        self.PercentCapacity = 0.0
        self.HeatLossRate_W = 0.0
        self.useheatTransfer = 0.0
        self.plantheatTransfer = 0.0
        self.DesignMassFlowRate = 0.0
        self.UseSideDesignFlowRate = 0.0
        self.PlantSideDesignFlowRate = 0.0
        self.UseSideMassFlowRate = 0.0
        self.PlantSideMassFlowRate = 0.0
    
    fn Init(inout self, state: UnsafePointer[UInt8]) -> None:
        if self.MyPlantScanFlag:
            var errFlag: Bool = False
            
            state[].PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, state[].DataPlant.PlantEquipmentType.TS_PCM,
                self.usePlantLoc, errFlag, None, None, None, self.UseSideInletNode, None, None)
            
            state[].PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, state[].DataPlant.PlantEquipmentType.TS_PCM,
                self.sourcePlantLoc, errFlag, None, None, None, self.PlantSideInletNode, None, None)
            
            if errFlag:
                _ = state[].UtilityRoutines.ShowFatalError(
                    state, "PCMStorageData::Init: Error scanning plant loops for PCM tank named: " + self.Name)
            
            RegisterPCMStorageOutputVariables(state)
            self.MyPlantScanFlag = False
        
        var temp: Float64 = state[].dataLoopNodes.Node(self.UseSideInletNode).Temp
        
        var rhoUseProps = state[].usePlantLoc.loop.glycol
        var rhoUse: Float64 = rhoUseProps.getDensity(state, temp, "PCMStorageData::Calculate")
        
        var rhoPlantProps = state[].sourcePlantLoc.loop.glycol
        var rhoPlant: Float64 = rhoPlantProps.getDensity(state, temp, "PCMStorageData::Calculate")
        
        if state[].dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            if self.UseSideDesignFlowRate <= 0.0:
                var initMassFlow: Float64 = 0.0
                if self.UseSideInletNode > 0:
                    initMassFlow = state[].dataLoopNodes.Node(self.UseSideInletNode).MassFlowRate
                if initMassFlow > 0.0:
                    self.UseSideDesignFlowRate = initMassFlow / rhoUse
                elif self.PlantSideDesignFlowRate > 0.0:
                    self.UseSideDesignFlowRate = self.PlantSideDesignFlowRate
                else:
                    self.UseSideDesignFlowRate = 1.0e-4
            
            if self.PlantSideDesignFlowRate <= 0.0:
                var initMassFlow: Float64 = 0.0
                if self.PlantSideInletNode > 0:
                    initMassFlow = state[].dataLoopNodes.Node(self.PlantSideInletNode).MassFlowRate
                if initMassFlow > 0.0:
                    self.PlantSideDesignFlowRate = initMassFlow / rhoPlant
                else:
                    self.PlantSideDesignFlowRate = self.UseSideDesignFlowRate
            
            self.UseSideMassFlowRate = self.UseSideDesignFlowRate * rhoUse
            self.PlantSideMassFlowRate = self.PlantSideDesignFlowRate * rhoPlant
            
            if self.TankCapacity <= 0.0:
                var designMassFlow: Float64 = max(self.UseSideMassFlowRate, self.PlantSideMassFlowRate)
                self.TankCapacity = designMassFlow * 3600.0
            
            state[].PlantUtilities.InitComponentNodes(state, 0.0, self.UseSideMassFlowRate, self.UseSideInletNode, self.UseSideOutletNode)
            state[].PlantUtilities.InitComponentNodes(state, 0.0, self.PlantSideMassFlowRate, self.PlantSideInletNode, self.PlantSideOutletNode)
            
            for compNum in range(1, self.usePlantLoc[].branch.TotalComponents + 1):
                self.usePlantLoc[].branch.Comp(compNum).FlowPriority = state[].DataPlant.LoopFlowStatus.NeedyAndTurnsLoopOn
            
            for compNum in range(1, self.sourcePlantLoc[].branch.TotalComponents + 1):
                self.sourcePlantLoc[].branch.Comp(compNum).FlowPriority = state[].DataPlant.LoopFlowStatus.NeedyAndTurnsLoopOn
            
            self.EnergyStored = self.TankCapacity * self.LatentHeat
            self.PercentCapacity = 100.0
            
            self.MyEnvrnFlag = False
        
        if not state[].dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
    
    fn Calculate(inout self, state: UnsafePointer[UInt8], plantLoc: UnsafePointer[UInt8]) -> None:
        var useInlet = state[].dataLoopNodes.Node(self.UseSideInletNode)
        var useOutlet = state[].dataLoopNodes.Node(self.UseSideOutletNode)
        var plantInlet = state[].dataLoopNodes.Node(self.PlantSideInletNode)
        var plantOutlet = state[].dataLoopNodes.Node(self.PlantSideOutletNode)
        
        var dt_seconds: Float64 = state[].dataHVACGlobal.TimeStepSys * 3600.0
        
        var temp: Float64 = state[].dataLoopNodes.Node(self.UseSideInletNode).Temp
        
        var cpUseProps = self.usePlantLoc[].loop.glycol
        var CpWaterUse: Float64 = cpUseProps.getSpecificHeat(state, temp, "PCMStorageData::Calculate")
        
        var cpPlantProps = self.sourcePlantLoc[].loop.glycol
        var CpWaterPlant: Float64 = cpPlantProps.getSpecificHeat(state, temp, "PCMStorageData::Calculate")
        
        var plantOutletTemp: Float64 = plantInlet.Temp - (self.Effectiveness * (plantInlet.Temp - self.FreezingTemp))
        var useOutletTemp: Float64 = useInlet.Temp + (self.Effectiveness * (self.MeltingTemp - useInlet.Temp))
        
        state[].PlantUtilities.SafeCopyPlantNode(state, self.UseSideInletNode, self.UseSideOutletNode)
        state[].PlantUtilities.SafeCopyPlantNode(state, self.PlantSideInletNode, self.PlantSideOutletNode)
        
        if self.AvailabilitySchedule[].getCurrentVal() <= 0.0:
            useInlet.MassFlowRate = 0.0
            useOutlet.MassFlowRate = 0.0
            plantInlet.MassFlowRate = 0.0
            plantOutlet.MassFlowRate = 0.0
            return
        
        if self.PCMmat != UnsafePointer[UInt8]():
            var targetEnthalpy: Float64 = self.EnergyStored / self.TankCapacity
            var Tlow: Float64 = self.PCMmat[].peakTempMelting - 30.0
            var Thigh: Float64 = self.PCMmat[].peakTempMelting + 30.0
            var approxTemp: Float64 = self.PCMmat[].peakTempMelting
            
            for i in range(25):
                var Tmid: Float64 = 0.5 * (Tlow + Thigh)
                var hMid: Float64 = self.PCMmat[].getEnthalpy(
                    Tmid, self.PCMmat[].peakTempMelting, self.PCMmat[].deltaTempMeltingLow, self.PCMmat[].deltaTempMeltingHigh)
                if fabs(hMid - targetEnthalpy) < 0.1:
                    approxTemp = Tmid
                    break
                if hMid > targetEnthalpy:
                    Thigh = Tmid
                else:
                    Tlow = Tmid
            
            self.PCM_TankTemp = approxTemp
        
        var soc: Float64 = self.EnergyStored / (self.TankCapacity * self.LatentHeat)
        soc = max(0.0, min(1.0, soc))
        
        var cutInSOC: Float64 = 0.40
        var cutOutSOC: Float64 = 0.95
        
        if soc <= cutInSOC:
            _charging_mode = True
        if soc >= cutOutSOC:
            _charging_mode = False
        
        var chargingMode: Bool = _charging_mode
        
        var mUseReq: Float64 = 0.0
        var mPlantReq: Float64 = 0.0
        
        if chargingMode:
            mPlantReq = self.PlantSideMassFlowRate
        else:
            mUseReq = self.UseSideMassFlowRate
        
        state[].PlantUtilities.SetComponentFlowRate(state, mUseReq, self.UseSideInletNode, self.UseSideOutletNode, self.usePlantLoc)
        state[].PlantUtilities.SetComponentFlowRate(state, mPlantReq, self.PlantSideInletNode, self.PlantSideOutletNode, self.sourcePlantLoc)
        
        if mUseReq > 0.0:
            useOutlet.Temp = useOutletTemp
        elif mPlantReq > 0.0:
            plantOutlet.Temp = min(plantOutletTemp, state[].dataPlnt.PlantLoop(self.sourcePlantLoc[].loopNum).MaxTemp)
        
        var useheatTransfer_req: Float64 = mUseReq * CpWaterUse * (useInlet.Temp - useOutletTemp)
        var plantheatTransfer_req: Float64 = mPlantReq * CpWaterPlant * (plantInlet.Temp - plantOutletTemp)
        
        var netPowerW: Float64 = plantheatTransfer_req + useheatTransfer_req - self.HeatLossRate
        
        self.EnergyStored += netPowerW * dt_seconds
        
        self.useheatTransfer = useheatTransfer_req
        self.plantheatTransfer = plantheatTransfer_req
        
        self.EnergyStored = max(0.0, min(self.TankCapacity * self.LatentHeat, self.EnergyStored))
        self.PercentCapacity = 100.0 * self.EnergyStored / (self.TankCapacity * self.LatentHeat)
    
    fn simulate(inout self, state: UnsafePointer[UInt8], calledFromLocation: UnsafePointer[UInt8], FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> None:
        SimulatePCMStorage(state, calledFromLocation, FirstHVACIteration, CurLoad, RunFlag)
    
    fn oneTimeInit(inout self, state: UnsafePointer[UInt8]) -> None:
        self.Init(state)
    
    @staticmethod
    fn instance() -> UnsafePointer[PCMStorageData]:
        if _pcm_storage_instance == UnsafePointer[PCMStorageData]():
            _pcm_storage_instance = UnsafePointer[PCMStorageData].alloc(1)
            _pcm_storage_instance[].PCMStorageData.__init__()
        return _pcm_storage_instance
    
    @staticmethod
    fn factory(state: UnsafePointer[UInt8], objectName: String) -> UnsafePointer[PCMStorageData]:
        if _get_pcm_input_flag:
            GetPCMStorageInput(state)
            _get_pcm_input_flag = False
        
        var pcm = PCMStorageData.instance()
        if pcm[].Name == objectName:
            return pcm
        
        _ = state[].UtilityRoutines.ShowFatalError(
            state, "PCMStorage factory: No PCM storage found with name: " + objectName)
        return UnsafePointer[PCMStorageData]()

fn SimulatePCMStorage(state: UnsafePointer[UInt8], plantLoc: UnsafePointer[UInt8], FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> None:
    var PCM = PCMStorageData.instance()
    
    if not PCM[].Initialized:
        PCM[].Init(state)
    
    PCM[].Calculate(state, plantLoc)

fn RegisterPCMStorageOutputVariables(state: UnsafePointer[UInt8]) -> None:
    var PCM = PCMStorageData.instance()
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Percent Capacity",
        state[].Constant.Units.None,
        PCM[].PercentCapacity,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Heat Loss Rate",
        state[].Constant.Units.W,
        PCM[].HeatLossRate,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Energy Stored",
        state[].Constant.Units.J,
        PCM[].EnergyStored,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Tank Temperature",
        state[].Constant.Units.C,
        PCM[].PCM_TankTemp,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Heat Transfer Rate",
        state[].Constant.Units.W,
        PCM[].useheatTransfer,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Heat Transfer Rate",
        state[].Constant.Units.W,
        PCM[].plantheatTransfer,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Inlet Temperature",
        state[].Constant.Units.C,
        state[].dataLoopNodes.Node(PCM[].UseSideInletNode).Temp,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Outlet Temperature",
        state[].Constant.Units.C,
        state[].dataLoopNodes.Node(PCM[].UseSideOutletNode).Temp,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Use Side Mass Flow Rate",
        state[].Constant.Units.kg_s,
        state[].dataLoopNodes.Node(PCM[].UseSideInletNode).MassFlowRate,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Inlet Temperature",
        state[].Constant.Units.C,
        state[].dataLoopNodes.Node(PCM[].PlantSideInletNode).Temp,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Outlet Temperature",
        state[].Constant.Units.C,
        state[].dataLoopNodes.Node(PCM[].PlantSideOutletNode).Temp,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)
    
    state[].OutputProcessor.SetupOutputVariable(
        state,
        "Thermal Energy Storage Plant Side Mass Flow Rate",
        state[].Constant.Units.kg_s,
        state[].dataLoopNodes.Node(PCM[].PlantSideInletNode).MassFlowRate,
        state[].OutputProcessor.TimeStepType.System,
        state[].OutputProcessor.StoreType.Average,
        PCM[].Name)

fn GetPCMStorageInput(state: UnsafePointer[UInt8]) -> None:
    var RoutineName = "GetPCMStorageInput"
    
    var PCM = PCMStorageData.instance()
    var ErrorsFound: Bool = False
    
    var NumPCMObjs: Int32 = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ThermalStorage:PCM")
    if NumPCMObjs != 1:
        state[].OutputProcessor.ShowSevereError(state, "Exactly one ThermalStorage:PCM object is required.")
        return
    
    state[].dataIPShortCut.cCurrentModuleObject = "ThermalStorage:PCM"
    
    state[].dataInputProcessing.inputProcessor.getObjectItem(
        state,
        state[].dataIPShortCut.cCurrentModuleObject,
        1,
        state[].dataIPShortCut.cAlphaArgs,
        state[].dataIPShortCut.NumAlphas,
        state[].dataIPShortCut.rNumericArgs,
        state[].dataIPShortCut.NumNums,
        state[].dataIPShortCut.IOStat,
        None,
        state[].dataIPShortCut.lAlphaFieldBlanks,
        state[].dataIPShortCut.cAlphaFieldNames,
        state[].dataIPShortCut.cNumericFieldNames)
    
    PCM[].Name = state[].dataIPShortCut.cAlphaArgs(1)
    PCM[].AvailabilityScheduleName = state[].dataIPShortCut.cAlphaArgs(2)
    
    if state[].dataIPShortCut.lAlphaFieldBlanks(2):
        PCM[].AvailabilitySchedule = state[].Sched.GetScheduleAlwaysOn(state)
    else:
        PCM[].AvailabilitySchedule = state[].Sched.GetSchedule(state, state[].dataIPShortCut.cAlphaArgs(2))
        if PCM[].AvailabilitySchedule == UnsafePointer[UInt8]():
            state[].OutputProcessor.ShowSevereItemNotFound(
                state, RoutineName, state[].dataIPShortCut.cCurrentModuleObject,
                state[].dataIPShortCut.cAlphaFieldNames(2), state[].dataIPShortCut.cAlphaArgs(2))
            ErrorsFound = True
    
    var matNum: Int32 = state[].Material.GetMaterialNum(state, state[].dataIPShortCut.cAlphaArgs(7))
    if matNum == 0:
        state[].OutputProcessor.ShowSevereError(
            state,
            state[].dataIPShortCut.cCurrentModuleObject + ": Invalid PCM material name: " + state[].dataIPShortCut.cAlphaArgs(7))
        ErrorsFound = True
    else:
        var savedModuleObj = state[].dataIPShortCut.cCurrentModuleObject
        state[].dataIPShortCut.cCurrentModuleObject = savedModuleObj
        
        var mat = state[].dataMaterial.materials(matNum)
        
        if not mat[].hasPCM:
            state[].OutputProcessor.ShowSevereError(
                state,
                state[].dataIPShortCut.cCurrentModuleObject + ": Material " + mat[].Name + " is not a phase change material.")
            ErrorsFound = True
        else:
            PCM[].PCMMaterialNum = matNum
            PCM[].PCMmat = mat
            
            PCM[].TankCapacity = state[].dataIPShortCut.rNumericArgs(1)
            PCM[].HeatLossRate = state[].dataIPShortCut.rNumericArgs(2)
            PCM[].UseSideDesignFlowRate = state[].dataIPShortCut.rNumericArgs(3)
            PCM[].PlantSideDesignFlowRate = state[].dataIPShortCut.rNumericArgs(4)
            
            if PCM[].UseSideDesignFlowRate < 0.0:
                state[].OutputProcessor.ShowWarningError(
                    state,
                    state[].dataIPShortCut.cCurrentModuleObject + "=" + PCM[].Name + 
                    ", Use Side Design Flow Rate was entered as " + 
                    String(PCM[].UseSideDesignFlowRate) + ".  This will be autosized during initialization.")
            
            if PCM[].PlantSideDesignFlowRate < 0.0:
                state[].OutputProcessor.ShowWarningError(
                    state,
                    state[].dataIPShortCut.cCurrentModuleObject + "=" + PCM[].Name + 
                    ", Plant Side Design Flow Rate was entered as " + 
                    String(PCM[].PlantSideDesignFlowRate) + ".  This will be autosized during initialization.")
            
            PCM[].MeltingTemp = PCM[].PCMmat[].peakTempMelting
            PCM[].FreezingTemp = PCM[].PCMmat[].peakTempFreezing
            PCM[].LatentHeat = PCM[].PCMmat[].totalLatentHeat
            PCM[].SpecificHeat = (PCM[].PCMmat[].specificHeatSolid + PCM[].PCMmat[].specificHeatLiquid) / 2.0
    
    PCM[].PlantSideInletNode = state[].Node.GetOnlySingleNode(
        state,
        state[].dataIPShortCut.cAlphaArgs(3),
        ErrorsFound,
        state[].Node.ConnectionObjectType.ThermalStoragePCM,
        PCM[].Name,
        state[].Node.FluidType.Water,
        state[].Node.ConnectionType.Inlet,
        state[].Node.CompFluidStream.Primary,
        state[].Node.ObjectIsNotParent)
    
    PCM[].PlantSideOutletNode = state[].Node.GetOnlySingleNode(
        state,
        state[].dataIPShortCut.cAlphaArgs(4),
        ErrorsFound,
        state[].Node.ConnectionObjectType.ThermalStoragePCM,
        PCM[].Name,
        state[].Node.FluidType.Water,
        state[].Node.ConnectionType.Outlet,
        state[].Node.CompFluidStream.Primary,
        state[].Node.ObjectIsNotParent)
    
    PCM[].UseSideInletNode = state[].Node.GetOnlySingleNode(
        state,
        state[].dataIPShortCut.cAlphaArgs(5),
        ErrorsFound,
        state[].Node.ConnectionObjectType.ThermalStoragePCM,
        PCM[].Name,
        state[].Node.FluidType.Water,
        state[].Node.ConnectionType.Inlet,
        state[].Node.CompFluidStream.Secondary,
        state[].Node.ObjectIsNotParent)
    
    PCM[].UseSideOutletNode = state[].Node.GetOnlySingleNode(
        state,
        state[].dataIPShortCut.cAlphaArgs(6),
        ErrorsFound,
        state[].Node.ConnectionObjectType.ThermalStoragePCM,
        PCM[].Name,
        state[].Node.FluidType.Water,
        state[].Node.ConnectionType.Outlet,
        state[].Node.CompFluidStream.Secondary,
        state[].Node.ObjectIsNotParent)
    
    state[].Node.TestCompSet(
        state,
        state[].dataIPShortCut.cCurrentModuleObject,
        PCM[].Name,
        state[].dataIPShortCut.cAlphaArgs(3),
        state[].dataIPShortCut.cAlphaArgs(4),
        "PCM Storage Plant Side")
    
    state[].Node.TestCompSet(
        state,
        state[].dataIPShortCut.cCurrentModuleObject,
        PCM[].Name,
        state[].dataIPShortCut.cAlphaArgs(5),
        state[].dataIPShortCut.cAlphaArgs(6),
        "PCM Storage Use Side")
    
    if PCM[].TankCapacity <= 0.0:
        state[].OutputProcessor.ShowWarningError(
            state,
            state[].dataIPShortCut.cCurrentModuleObject + "=" + PCM[].Name + 
            ", Tank Capacity was entered as " + String(PCM[].TankCapacity) + 
            " and will be autosized during initialization.")
    
    if ErrorsFound:
        _ = state[].UtilityRoutines.ShowFatalError(
            state, "Errors found in processing input for " + state[].dataIPShortCut.cCurrentModuleObject)

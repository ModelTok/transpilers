module EnergyPlus.PCMStorage {
    from . import (
        "PCMThermalStorage.hh", # For type definitions
        # imported from other modules (paths relative to src/EnergyPlus/):
        "Data/EnergyPlusData",
        "PhaseChangeModeling/HysteresisModel",
        "Plant/PlantLocation",
        "PlantComponent",
        "BranchNodeConnections",
        "DataEnvironment",
        "DataGlobals",
        "DataHeatBalance",
        "DataIPShortCuts",
        "DataLoopNode",
        "FluidProperties",
        "HeatBalFiniteDiffManager",
        "InputProcessing/InputProcessor",
        "NodeInputManager",
        "OutputProcessor",
        "PhaseChangeModeling/HysteresisModel",
        "Plant/DataPlant",
        "Plant/PlantLocation",
        "PlantComponent",
        "PlantUtilities",
        "ScheduleManager",
        "UtilityRoutines"
    )

    import Func: ShowFatalError, ShowSevereError, ShowWarningError, ShowSevereItemNotFound, SetupOutputVariable, GetOnlySingleNode, TestCompSet, GetSchedule, GetScheduleAlwaysOn, GetMaterialNum, ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate, SafeCopyPlantNode, getNumObjectsFound, getObjectItem
    # Also need Constant::Units, OutputProcessor::TimeStepType, OutputProcessor::StoreType, etc.

    struct PCMStorageData:
        var Initialized: Bool = False
        var MyPlantScanFlag: Bool = True
        var MyEnvrnFlag: Bool = True
        var Name: String
        var AvailabilityScheduleName: String
        var PCMMaterialNum: Int = 0
        var PCMmat: Material.MaterialPhaseChange? = None
        var TankCapacity: Float64 = 0.0
        var HeatLossRate: Float64 = 0.0
        var MeltingTemp: Float64 = 0.0
        var FreezingTemp: Float64 = 0.0
        var LatentHeat: Float64 = 0.0
        var SpecificHeat: Float64 = 0.0
        @staticmethod
        var Effectiveness: Float64 = 0.9
        var sourcePlantLoc: EnergyPlus.PlantLocation
        var PlantSideInletNode: Int = 0
        var PlantSideOutletNode: Int = 0
        var usePlantLoc: EnergyPlus.PlantLocation
        var UseSideInletNode: Int = 0
        var UseSideOutletNode: Int = 0
        var AvailabilitySchedule: Schedule? = None
        var PCM_TankTemp: Float64 = 0.0
        var EnergyStored: Float64 = 0.0
        var PercentCapacity: Float64 = 0.0
        var HeatLossRate_W: Float64 = 0.0
        var useheatTransfer: Float64 = 0.0
        var plantheatTransfer: Float64 = 0.0
        var DesignMassFlowRate: Float64 = 0.0
        var UseSideDesignFlowRate: Float64 = 0.0
        var PlantSideDesignFlowRate: Float64 = 0.0
        var UseSideMassFlowRate: Float64 = 0.0
        var PlantSideMassFlowRate: Float64 = 0.0

        def init( inout self, state: EnergyPlusData):

        def calculate( inout self, state: EnergyPlusData, plantLoc: PlantLocation):

        @staticmethod
        def instance() -> PCMStorageData:
            # This is a singleton; using static var in Mojo as a module-level variable
            return _pcmInstance

        @staticmethod
        def factory( state: EnergyPlusData, objectName: String) -> PlantComponent:
            var getPCMInputFlag: Bool = True
            if getPCMInputFlag:
                GetPCMStorageInput(state)
                getPCMInputFlag = False
            var pcm: PCMStorageData = PCMStorageData.instance()
            if pcm.Name == objectName:
                return pcm
            ShowFatalError(state, "PCMStorage factory: No PCM storage found with name: " + objectName)
            return None

        def simulate( inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
            SimulatePCMStorage(state, calledFromLocation, FirstHVACIteration, CurLoad, RunFlag)

        def oneTimeInit( inout self, state: EnergyPlusData):
            self.init(state)

    var _pcmInstance: PCMStorageData = PCMStorageData()

    def SimulatePCMStorage( state: EnergyPlusData, plantLoc: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        _ = FirstHVACIteration
        _ = CurLoad
        _ = RunFlag
        var pcm: PCMStorageData = PCMStorageData.instance()
        if not pcm.Initialized:
            pcm.init(state)
        pcm.calculate(state, plantLoc)

    # Static variable for charging mode (was static bool chargingMode in C++)
    var _chargingMode: Bool = False  # static inside Calculate

    def PCMStorageData.init( inout self, state: EnergyPlusData):
        if self.MyPlantScanFlag:
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, DataPlant.PlantEquipmentType.TS_PCM, self.usePlantLoc, errFlag, _, _, _, self.UseSideInletNode, _, _
            )
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, DataPlant.PlantEquipmentType.TS_PCM, self.sourcePlantLoc, errFlag, _, _, _, self.PlantSideInletNode, _, _
            )
            if errFlag:
                ShowFatalError(state, "PCMStorageData::Init: Error scanning plant loops for PCM tank named: " + self.Name)
            RegisterPCMStorageOutputVariables(state)
            self.MyPlantScanFlag = False

        var temp: Float64 = state.dataLoopNodes.Node[self.UseSideInletNode - 1].Temp  # 0-based index
        var rhoUseProps: Fluid.GlycolProps = self.usePlantLoc.loop.glycol
        var rhoUse: Float64 = rhoUseProps.getDensity(state, temp, "PCMStorageData::Calculate")
        var rhoPlantProps: Fluid.GlycolProps = self.sourcePlantLoc.loop.glycol
        var rhoPlant: Float64 = rhoPlantProps.getDensity(state, temp, "PCMStorageData::Calculate")

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            if self.UseSideDesignFlowRate <= 0.0:
                var initMassFlow: Float64 = 0.0
                if self.UseSideInletNode > 0:
                    initMassFlow = state.dataLoopNodes.Node[self.UseSideInletNode - 1].MassFlowRate
                if initMassFlow > 0.0:
                    self.UseSideDesignFlowRate = initMassFlow / rhoUse
                elif self.PlantSideDesignFlowRate > 0.0:
                    self.UseSideDesignFlowRate = self.PlantSideDesignFlowRate
                else:
                    self.UseSideDesignFlowRate = 1.0e-4

            if self.PlantSideDesignFlowRate <= 0.0:
                var initMassFlow2: Float64 = 0.0
                if self.PlantSideInletNode > 0:
                    initMassFlow2 = state.dataLoopNodes.Node[self.PlantSideInletNode - 1].MassFlowRate
                if initMassFlow2 > 0.0:
                    self.PlantSideDesignFlowRate = initMassFlow2 / rhoPlant
                else:
                    self.PlantSideDesignFlowRate = self.UseSideDesignFlowRate

            self.UseSideMassFlowRate = self.UseSideDesignFlowRate * rhoUse
            self.PlantSideMassFlowRate = self.PlantSideDesignFlowRate * rhoPlant

            if self.TankCapacity <= 0.0:
                var designMassFlow: Float64 = max(self.UseSideMassFlowRate, self.PlantSideMassFlowRate)
                self.TankCapacity = designMassFlow * 3600.0

            PlantUtilities.InitComponentNodes(state, 0.0, self.UseSideMassFlowRate, self.UseSideInletNode, self.UseSideOutletNode)
            PlantUtilities.InitComponentNodes(state, 0.0, self.PlantSideMassFlowRate, self.PlantSideInletNode, self.PlantSideOutletNode)

            for compNum in range(1, self.usePlantLoc.branch.TotalComponents + 1):
                self.usePlantLoc.branch.Comp[compNum - 1].FlowPriority = DataPlant.LoopFlowStatus.NeedyAndTurnsLoopOn

            for compNum in range(1, self.sourcePlantLoc.branch.TotalComponents + 1):
                self.sourcePlantLoc.branch.Comp[compNum - 1].FlowPriority = DataPlant.LoopFlowStatus.NeedyAndTurnsLoopOn

            self.EnergyStored = self.TankCapacity * self.LatentHeat
            self.PercentCapacity = 100.0
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

    def PCMStorageData.calculate( inout self, state: EnergyPlusData, plantLoc: PlantLocation):
        _ = plantLoc
        var useInlet = state.dataLoopNodes.Node[self.UseSideInletNode - 1]
        var useOutlet = state.dataLoopNodes.Node[self.UseSideOutletNode - 1]
        var plantInlet = state.dataLoopNodes.Node[self.PlantSideInletNode - 1]
        var plantOutlet = state.dataLoopNodes.Node[self.PlantSideOutletNode - 1]

        var dt_seconds: Float64 = state.dataHVACGlobal.TimeStepSys * 3600.0
        var temp: Float64 = state.dataLoopNodes.Node[self.UseSideInletNode - 1].Temp

        var cpUseProps: Fluid.GlycolProps = self.usePlantLoc.loop.glycol
        var CpWaterUse: Float64 = cpUseProps.getSpecificHeat(state, temp, "PCMStorageData::Calculate")
        var cpPlantProps: Fluid.GlycolProps = self.sourcePlantLoc.loop.glycol
        var CpWaterPlant: Float64 = cpPlantProps.getSpecificHeat(state, temp, "PCMStorageData::Calculate")

        # Calculate Plant Outlet Temperature
        var plantOutletTemp: Float64 = plantInlet.Temp - (Effectiveness * (plantInlet.Temp - FreezingTemp))
        # Calculate Use Outlet Temperature
        var useOutletTemp: Float64 = useInlet.Temp + (Effectiveness * (MeltingTemp - useInlet.Temp))

        PlantUtilities.SafeCopyPlantNode(state, self.UseSideInletNode, self.UseSideOutletNode)
        PlantUtilities.SafeCopyPlantNode(state, self.PlantSideInletNode, self.PlantSideOutletNode)

        if self.AvailabilitySchedule.getCurrentVal() <= 0.0:
            useInlet.MassFlowRate = 0.0
            useOutlet.MassFlowRate = 0.0
            plantInlet.MassFlowRate = 0.0
            plantOutlet.MassFlowRate = 0.0
            return

        if self.PCMmat:
            var targetEnthalpy: Float64 = EnergyStored / TankCapacity
            var Tlow: Float64 = self.PCMmat.peakTempMelting - 30.0
            var Thigh: Float64 = self.PCMmat.peakTempMelting + 30.0
            var approxTemp: Float64 = self.PCMmat.peakTempMelting
            for i in range(25):
                var Tmid: Float64 = 0.5 * (Tlow + Thigh)
                var hMid: Float64 = self.PCMmat.getEnthalpy(
                    Tmid, self.PCMmat.peakTempMelting, self.PCMmat.deltaTempMeltingLow, self.PCMmat.deltaTempMeltingHigh
                )
                if abs(hMid - targetEnthalpy) < 0.1:
                    approxTemp = Tmid
                    break
                if hMid > targetEnthalpy:
                    Thigh = Tmid
                else:
                    Tlow = Tmid
            self.PCM_TankTemp = approxTemp

        var soc: Float64 = EnergyStored / (TankCapacity * LatentHeat)
        soc = clamp(soc, 0.0, 1.0)
        const cutInSOC: Float64 = 0.40  # start charging when SOC <= 40%
        const cutOutSOC: Float64 = 0.95 # stop charging when SOC >= 95%
        # static bool chargingMode = false; (converted to module-level var _chargingMode)
        if soc <= cutInSOC:
            _chargingMode = True
        if soc >= cutOutSOC:
            _chargingMode = False

        var mUseReq: Float64 = 0.0
        var mPlantReq: Float64 = 0.0
        if _chargingMode:
            mPlantReq = self.PlantSideMassFlowRate
        else:
            mUseReq = self.UseSideMassFlowRate

        PlantUtilities.SetComponentFlowRate(state, mUseReq, self.UseSideInletNode, self.UseSideOutletNode, self.usePlantLoc)
        PlantUtilities.SetComponentFlowRate(state, mPlantReq, self.PlantSideInletNode, self.PlantSideOutletNode, self.sourcePlantLoc)

        if mUseReq > 0.0:
            useOutlet.Temp = useOutletTemp
        elif mPlantReq > 0.0:
            plantOutlet.Temp = min(plantOutletTemp, state.dataPlnt.PlantLoop[self.sourcePlantLoc.loopNum - 1].MaxTemp) # 0-based

        var useheatTransfer_req: Float64 = mUseReq * CpWaterUse * (useInlet.Temp - useOutletTemp)
        var plantheatTransfer_req: Float64 = mPlantReq * CpWaterPlant * (plantInlet.Temp - plantOutletTemp)
        var netPowerW: Float64 = plantheatTransfer_req + useheatTransfer_req - HeatLossRate
        EnergyStored += netPowerW * dt_seconds
        self.useheatTransfer = useheatTransfer_req
        self.plantheatTransfer = plantheatTransfer_req
        EnergyStored = clamp(EnergyStored, 0.0, TankCapacity * LatentHeat)
        PercentCapacity = 100.0 * EnergyStored / (TankCapacity * LatentHeat)

    def RegisterPCMStorageOutputVariables( state: EnergyPlusData):
        var pcm: PCMStorageData = PCMStorageData.instance()
        SetupOutputVariable(state,
                            "Thermal Energy Storage Percent Capacity",
                            Constant.Units.None,
                            pcm.PercentCapacity,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Heat Loss Rate",
                            Constant.Units.W,
                            pcm.HeatLossRate,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Energy Stored",
                            Constant.Units.J,
                            pcm.EnergyStored,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Tank Temperature",
                            Constant.Units.C,
                            pcm.PCM_TankTemp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Use Side Heat Transfer Rate",
                            Constant.Units.W,
                            pcm.useheatTransfer,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Plant Side Heat Transfer Rate",
                            Constant.Units.W,
                            pcm.plantheatTransfer,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Use Side Inlet Temperature",
                            Constant.Units.C,
                            state.dataLoopNodes.Node[pcm.UseSideInletNode - 1].Temp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Use Side Outlet Temperature",
                            Constant.Units.C,
                            state.dataLoopNodes.Node[pcm.UseSideOutletNode - 1].Temp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Use Side Mass Flow Rate",
                            Constant.Units.kg_s,
                            state.dataLoopNodes.Node[pcm.UseSideInletNode - 1].MassFlowRate,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Plant Side Inlet Temperature",
                            Constant.Units.C,
                            state.dataLoopNodes.Node[pcm.PlantSideInletNode - 1].Temp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Plant Side Outlet Temperature",
                            Constant.Units.C,
                            state.dataLoopNodes.Node[pcm.PlantSideOutletNode - 1].Temp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)
        SetupOutputVariable(state,
                            "Thermal Energy Storage Plant Side Mass Flow Rate",
                            Constant.Units.kg_s,
                            state.dataLoopNodes.Node[pcm.PlantSideInletNode - 1].MassFlowRate,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            pcm.Name)

    def PCMStorageData.instance() -> PCMStorageData:
        # Use the module-level singleton
        return _pcmInstance

    def GetPCMStorageInput( state: EnergyPlusData):
        const RoutineName: String = "GetPCMStorageInput"
        var pcm: PCMStorageData = PCMStorageData.instance()
        var ErrorsFound: Bool = False
        var NumPCMObjs: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ThermalStorage:PCM")
        if NumPCMObjs != 1:
            ShowSevereError(state, "Exactly one ThermalStorage:PCM object is required.")
            return

        state.dataIPShortCut.cCurrentModuleObject = "ThermalStorage:PCM"
        var NumAlphas: Int
        var NumNums: Int
        var IOStat: Int
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 state.dataIPShortCut.cCurrentModuleObject,
                                                                 1,
                                                                 state.dataIPShortCut.cAlphaArgs,
                                                                 NumAlphas,
                                                                 state.dataIPShortCut.rNumericArgs,
                                                                 NumNums,
                                                                 IOStat,
                                                                 _,
                                                                 state.dataIPShortCut.lAlphaFieldBlanks,
                                                                 state.dataIPShortCut.cAlphaFieldNames,
                                                                 state.dataIPShortCut.cNumericFieldNames)

        pcm.Name = state.dataIPShortCut.cAlphaArgs[1 - 1]  # 0-based
        pcm.AvailabilityScheduleName = state.dataIPShortCut.cAlphaArgs[2 - 1]
        var eoh: ErrorObjectHeader = ErrorObjectHeader(RoutineName, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[2 - 1])
        if state.dataIPShortCut.lAlphaFieldBlanks[2 - 1]:
            pcm.AvailabilitySchedule = Sched.GetScheduleAlwaysOn(state)
        elif (pcm.AvailabilitySchedule = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[2 - 1])) is None:
            ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[2 - 1], state.dataIPShortCut.cAlphaArgs[2 - 1])
            ErrorsFound = True

        var matNum: Int = Material.GetMaterialNum(state, state.dataIPShortCut.cAlphaArgs[7 - 1])
        if matNum == 0:
            ShowSevereError(state,
                            state.dataIPShortCut.cCurrentModuleObject + ": Invalid PCM material name: " + state.dataIPShortCut.cAlphaArgs[7 - 1])
            ErrorsFound = True
        else:
            var savedModuleObj: String = state.dataIPShortCut.cCurrentModuleObject
            state.dataIPShortCut.cCurrentModuleObject = savedModuleObj
            var mat: Material = state.dataMaterial.materials(matNum - 1)  # 0-based
            if not mat.hasPCM:
                ShowSevereError(state,
                                state.dataIPShortCut.cCurrentModuleObject + ": Material " + mat.Name + " is not a phase change material.")
                ErrorsFound = True
            else:
                pcm.PCMMaterialNum = matNum
                pcm.PCMmat = mat  # cast? assuming mat is MaterialPhaseChange
                pcm.TankCapacity = state.dataIPShortCut.rNumericArgs[1 - 1]
                pcm.HeatLossRate = state.dataIPShortCut.rNumericArgs[2 - 1]
                pcm.UseSideDesignFlowRate = state.dataIPShortCut.rNumericArgs[3 - 1]
                pcm.PlantSideDesignFlowRate = state.dataIPShortCut.rNumericArgs[4 - 1]
                if pcm.UseSideDesignFlowRate < 0.0:
                    ShowWarningError(state,
                                     state.dataIPShortCut.cCurrentModuleObject + "=" + pcm.Name + ", Use Side Design Flow Rate was entered as " + pcm.UseSideDesignFlowRate + ".  This will be autosized during initialization.")
                if pcm.PlantSideDesignFlowRate < 0.0:
                    ShowWarningError(state,
                                     state.dataIPShortCut.cCurrentModuleObject + "=" + pcm.Name + ", Plant Side Design Flow Rate was entered as " + pcm.PlantSideDesignFlowRate + ".  This will be autosized during initialization.")
                pcm.MeltingTemp = pcm.PCMmat.peakTempMelting
                pcm.FreezingTemp = pcm.PCMmat.peakTempFreezing
                pcm.LatentHeat = pcm.PCMmat.totalLatentHeat
                pcm.SpecificHeat = (pcm.PCMmat.specificHeatSolid + pcm.PCMmat.specificHeatLiquid) / 2.0

        pcm.PlantSideInletNode = Node.GetOnlySingleNode(state,
                                                         state.dataIPShortCut.cAlphaArgs[3 - 1],
                                                         ErrorsFound,
                                                         Node.ConnectionObjectType.ThermalStoragePCM,
                                                         pcm.Name,
                                                         Node.FluidType.Water,
                                                         Node.ConnectionType.Inlet,
                                                         Node.CompFluidStream.Primary,
                                                         Node.ObjectIsNotParent)
        pcm.PlantSideOutletNode = Node.GetOnlySingleNode(state,
                                                          state.dataIPShortCut.cAlphaArgs[4 - 1],
                                                          ErrorsFound,
                                                          Node.ConnectionObjectType.ThermalStoragePCM,
                                                          pcm.Name,
                                                          Node.FluidType.Water,
                                                          Node.ConnectionType.Outlet,
                                                          Node.CompFluidStream.Primary,
                                                          Node.ObjectIsNotParent)
        pcm.UseSideInletNode = Node.GetOnlySingleNode(state,
                                                       state.dataIPShortCut.cAlphaArgs[5 - 1],
                                                       ErrorsFound,
                                                       Node.ConnectionObjectType.ThermalStoragePCM,
                                                       pcm.Name,
                                                       Node.FluidType.Water,
                                                       Node.ConnectionType.Inlet,
                                                       Node.CompFluidStream.Secondary,
                                                       Node.ObjectIsNotParent)
        pcm.UseSideOutletNode = Node.GetOnlySingleNode(state,
                                                        state.dataIPShortCut.cAlphaArgs[6 - 1],
                                                        ErrorsFound,
                                                        Node.ConnectionObjectType.ThermalStoragePCM,
                                                        pcm.Name,
                                                        Node.FluidType.Water,
                                                        Node.ConnectionType.Outlet,
                                                        Node.CompFluidStream.Secondary,
                                                        Node.ObjectIsNotParent)
        Node.TestCompSet(state,
                          state.dataIPShortCut.cCurrentModuleObject,
                          pcm.Name,
                          state.dataIPShortCut.cAlphaArgs[3 - 1],
                          state.dataIPShortCut.cAlphaArgs[4 - 1],
                          "PCM Storage Plant Side")
        Node.TestCompSet(state,
                          state.dataIPShortCut.cCurrentModuleObject,
                          pcm.Name,
                          state.dataIPShortCut.cAlphaArgs[5 - 1],
                          state.dataIPShortCut.cAlphaArgs[6 - 1],
                          "PCM Storage Use Side")
        if pcm.TankCapacity <= 0.0:
            ShowWarningError(state,
                             state.dataIPShortCut.cCurrentModuleObject + "=" + pcm.Name + ", Tank Capacity was entered as " + pcm.TankCapacity + " and will be autosized during initialization.")
        if ErrorsFound:
            ShowFatalError(state, "Errors found in processing input for " + state.dataIPShortCut.cCurrentModuleObject)
}
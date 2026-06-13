module EnergyPlus.PlantLoadProfile:

from memory import Pointer
from builtin import format, abs
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataIPShortCuts import DataIPShortCuts
from EnergyPlus.DataLoopNode import DataLoopNode
from DataSizing import DataSizing
from EMSManager import EMSManager
from FluidProperties import FluidProperties
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor
from EnergyPlus.Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from ScheduleManager import ScheduleManager
from UtilityRoutines import UtilityRoutines
from BranchNodeConnections import BranchNodeConnections
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.Plant.Enums import PlantEquipmentType
from EnergyPlus.PlantComponent import PlantComponent
from EnergyPlus.Sched.Schedule import Schedule
from EnergyPlus.Constant import Constant
from EnergyPlus.ErrorObjectHeader import ErrorObjectHeader
from EnergyPlus.Node import Node
from EnergyPlus.Util import Util

@value
enum PlantLoopFluidType(Int):
    Invalid = -1
    Water = 0
    Steam = 1
    Num = 2

struct PlantProfileData(PlantComponent):
    var Name: String
    var Type: DataPlant.PlantEquipmentType
    var plantLoc: PlantLocation
    var FluidType: PlantLoopFluidType = PlantLoopFluidType.Invalid
    var Init: Bool
    var InitSizing: Bool
    var InletNode: Int
    var InletTemp: Float64
    var OutletNode: Int
    var OutletTemp: Float64
    var loadSched: Pointer[Schedule] = Pointer[Schedule]()
    var EMSOverridePower: Bool
    var EMSPowerValue: Float64
    var PeakVolFlowRate: Float64
    var flowRateFracSched: Pointer[Schedule] = Pointer[Schedule]()
    var VolFlowRate: Float64
    var MassFlowRate: Float64
    var DegOfSubcooling: Float64 = 0.0
    var LoopSubcoolReturn: Float64 = 0.0
    var EMSOverrideMassFlow: Bool
    var EMSMassFlowValue: Float64
    var Power: Float64
    var Energy: Float64
    var HeatingEnergy: Float64
    var CoolingEnergy: Float64

    def __init__(inout self):
        self.Name = ""
        self.Type = DataPlant.PlantEquipmentType.Invalid
        self.plantLoc = PlantLocation()
        self.Init = True
        self.InitSizing = True
        self.InletNode = 0
        self.InletTemp = 0.0
        self.OutletNode = 0
        self.OutletTemp = 0.0
        self.EMSOverridePower = False
        self.EMSPowerValue = 0.0
        self.PeakVolFlowRate = 0.0
        self.VolFlowRate = 0.0
        self.MassFlowRate = 0.0
        self.EMSOverrideMassFlow = False
        self.EMSMassFlowValue = 0.0
        self.Power = 0.0
        self.Energy = 0.0
        self.HeatingEnergy = 0.0
        self.CoolingEnergy = 0.0

    @staticmethod
    def factory(inout state: EnergyPlusData, objectName: String) -> Pointer[PlantComponent]:
        if state.dataPlantLoadProfile.GetPlantLoadProfileInputFlag:
            GetPlantProfileInput(state)
            state.dataPlantLoadProfile.GetPlantLoadProfileInputFlag = False
        var foundIdx: Int = -1
        for i in range(len(state.dataPlantLoadProfile.PlantProfile)):
            if state.dataPlantLoadProfile.PlantProfile[i].Name == objectName:
                foundIdx = i
                break
        if foundIdx != -1:
            return Pointer.address_of(state.dataPlantLoadProfile.PlantProfile[foundIdx])
        ShowFatalError(state, format("PlantLoadProfile::factory: Error getting inputs for pipe named: {}", objectName))
        return Pointer[PlantComponent]()

    def onInitLoopEquip(inout self, inout state: EnergyPlusData, borrowed calledFromLocation: PlantLocation):
        self.InitPlantProfile(state)

    def simulate(inout self, inout state: EnergyPlusData, borrowed calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        alias RoutineName: StringLiteral = "SimulatePlantProfile"
        var DeltaTemp: Float64
        self.InitPlantProfile(state)
        if self.FluidType == PlantLoopFluidType.Water:
            if self.MassFlowRate > 0.0:
                var Cp: Float64 = self.plantLoc.loop.glycol.getSpecificHeat(state, self.InletTemp, RoutineName)
                DeltaTemp = self.Power / (self.MassFlowRate * Cp)
            else:
                self.Power = 0.0
                DeltaTemp = 0.0
            self.OutletTemp = self.InletTemp - DeltaTemp
        elif self.FluidType == PlantLoopFluidType.Steam:
            if self.MassFlowRate > 0.0 and self.Power > 0.0:
                var EnthSteamInDry: Float64 = self.plantLoc.loop.steam.getSatEnthalpy(state, self.InletTemp, 1.0, RoutineName)
                var EnthSteamOutWet: Float64 = self.plantLoc.loop.steam.getSatEnthalpy(state, self.InletTemp, 0.0, RoutineName)
                var LatentHeatSteam: Float64 = EnthSteamInDry - EnthSteamOutWet
                var SatTemp: Float64 = self.plantLoc.loop.steam.getSatTemperature(state, DataEnvironment.StdPressureSeaLevel, RoutineName)
                var CpWater: Float64 = self.plantLoc.loop.glycol.getSpecificHeat(state, SatTemp, RoutineName)
                self.MassFlowRate = self.Power / (LatentHeatSteam + self.DegOfSubcooling * CpWater)
                PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, self.InletNode, self.OutletNode, self.plantLoc)
                state.dataLoopNodes.Node(self.OutletNode).Quality = 0.0
                self.OutletTemp = SatTemp - self.LoopSubcoolReturn
            else:
                self.Power = 0.0
        self.UpdatePlantProfile(state)
        self.ReportPlantProfile(state)

    def InitPlantProfile(inout self, inout state: EnergyPlusData):
        alias RoutineName: StringLiteral = "InitPlantProfile"
        var FluidDensityInit: Float64
        if state.dataGlobal.BeginEnvrnFlag and self.Init:
            state.dataLoopNodes.Node(self.OutletNode).Temp = 0.0
            if self.FluidType == PlantLoopFluidType.Water:
                FluidDensityInit = self.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, RoutineName)
            else:
                var SatTempAtmPress: Float64 = self.plantLoc.loop.steam.getSatTemperature(state, DataEnvironment.StdPressureSeaLevel, RoutineName)
                FluidDensityInit = self.plantLoc.loop.steam.getSatDensity(state, SatTempAtmPress, 1.0, RoutineName)
            var MaxFlowMultiplier: Float64 = self.flowRateFracSched.load().getMaxVal(state)
            PlantUtilities.InitComponentNodes(state, 0.0, self.PeakVolFlowRate * FluidDensityInit * MaxFlowMultiplier, self.InletNode, self.OutletNode)
            self.EMSOverrideMassFlow = False
            self.EMSMassFlowValue = 0.0
            self.EMSOverridePower = False
            self.EMSPowerValue = 0.0
            self.Init = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.Init = True
        self.InletTemp = state.dataLoopNodes.Node(self.InletNode).Temp
        self.Power = self.loadSched.load().getCurrentVal()
        if self.EMSOverridePower:
            self.Power = self.EMSPowerValue
        if self.FluidType == PlantLoopFluidType.Water:
            FluidDensityInit = self.plantLoc.loop.glycol.getDensity(state, self.InletTemp, RoutineName)
        else:
            FluidDensityInit = self.plantLoc.loop.steam.getSatDensity(state, self.InletTemp, 1.0, RoutineName)
        self.VolFlowRate = self.PeakVolFlowRate * self.flowRateFracSched.load().getCurrentVal()
        self.MassFlowRate = self.VolFlowRate * FluidDensityInit
        if self.EMSOverrideMassFlow:
            self.MassFlowRate = self.EMSMassFlowValue
        PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, self.InletNode, self.OutletNode, self.plantLoc)
        self.VolFlowRate = self.MassFlowRate / FluidDensityInit
        if self.InitSizing and not state.dataGlobal.SysSizingCalc:
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.InletNode, self.PeakVolFlowRate)
            var thisLoadSched: List[Float64] = self.loadSched.load().getDayVals(state, -1, -1)
            var thisFlowSched: List[Float64] = self.flowRateFracSched.load().getDayVals(state, -1, -1)
            var plntSizIndex: Int = self.plantLoc.loop.PlantSizNum
            var plntDeltaT: Float64 = 0.0
            var inletTemp: Float64 = Constant.InitConvTemp
            if plntSizIndex > 0:
                plntDeltaT = state.dataSize.PlantSizData[plntSizIndex - 1].DeltaT
                inletTemp = state.dataSize.PlantSizData[plntSizIndex - 1].ExitTemp
            var plntComps: List[String] = self.plantLoc.loop.plantCoilObjectNames
            var cmpType: List[DataPlant.PlantEquipmentType] = self.plantLoc.loop.plantCoilObjectTypes
            var arrayIndex: Int = -1
            for i in range(len(plntComps)):
                if plntComps[i] == self.Name and cmpType[i] == self.Type:
                    arrayIndex = i
                    break
            if arrayIndex == -1:
                self.plantLoc.loop.plantCoilObjectNames.append(self.Name)
                self.plantLoc.loop.plantCoilObjectTypes.append(self.Type)
                var tmpFlowData: List[Float64] = List[Float64]()
                tmpFlowData.resize(Int(Constant.iHoursInDay * state.dataGlobal.TimeStepsInHour) + 1)
                tmpFlowData[0] = -1.0
                if self.FluidType == PlantLoopFluidType.Water:
                    FluidDensityInit = self.plantLoc.loop.glycol.getDensity(state, inletTemp, RoutineName)
                else:
                    FluidDensityInit = self.plantLoc.loop.steam.getSatDensity(state, inletTemp, 1.0, RoutineName)
                var Cp: Float64
                if self.FluidType == PlantLoopFluidType.Water:
                    Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, inletTemp, RoutineName)
                elif self.FluidType == PlantLoopFluidType.Steam:
                    var EnthSteamInDry: Float64 = self.plantLoc.loop.steam.getSatEnthalpy(state, inletTemp, 1.0, RoutineName)
                    var EnthSteamOutWet: Float64 = self.plantLoc.loop.steam.getSatEnthalpy(state, inletTemp, 0.0, RoutineName)
                    var LatentHeatSteam: Float64 = EnthSteamInDry - EnthSteamOutWet
                    var SatTemp: Float64 = self.plantLoc.loop.steam.getSatTemperature(state, DataEnvironment.StdPressureSeaLevel, RoutineName)
                    Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, SatTemp, RoutineName)
                    self.MassFlowRate = self.Power / (LatentHeatSteam + self.DegOfSubcooling * Cp)
                    PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, self.InletNode, self.OutletNode, self.plantLoc)
                    state.dataLoopNodes.Node(self.OutletNode).Quality = 0.0
                for i in range(1, len(thisLoadSched) + 1):
                    if plntDeltaT > 0:
                        tmpFlowData[i] = thisLoadSched[i - 1] / (FluidDensityInit * Cp * plntDeltaT)
                    else:
                        tmpFlowData[i] = thisFlowSched[i - 1] * self.PeakVolFlowRate
                var plntCoilData: List[SomeType] = self.plantLoc.loop.compDesWaterFlowRate
                var newEntryIndex: Int = len(plntCoilData) + 1
                plntCoilData.resize(newEntryIndex)
                plntCoilData[newEntryIndex - 1].tsDesWaterFlowRate.resize(Int(Constant.iHoursInDay * state.dataGlobal.TimeStepsInHour))
                plntCoilData[newEntryIndex - 1].tsDesWaterFlowRate = tmpFlowData
            self.InitSizing = False

    def UpdatePlantProfile(inout self, inout state: EnergyPlusData):
        state.dataLoopNodes.Node(self.OutletNode).Temp = self.OutletTemp

    def ReportPlantProfile(inout self, inout state: EnergyPlusData):
        var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
        self.Energy = self.Power * TimeStepSysSec
        if self.Energy >= 0.0:
            self.HeatingEnergy = self.Energy
            self.CoolingEnergy = 0.0
        else:
            self.HeatingEnergy = 0.0
            self.CoolingEnergy = abs(self.Energy)

    def oneTimeInit_new(inout self, inout state: EnergyPlusData):
        if allocated(state.dataPlnt.PlantLoop):
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.Type, self.plantLoc, errFlag, _, _, _, _, _)
            if errFlag:
                ShowFatalError(state, "InitPlantProfile: Program terminated for previous conditions.")

    def oneTimeInit(inout self, inout state: EnergyPlusData):

    def getCurrentPower(inout self, inout state: EnergyPlusData, inout power: Float64):
        power = self.Power
        return

def GetPlantProfileInput(inout state: EnergyPlusData):
    alias routineName: StringLiteral = "GetPlantProfileInput"
    var cCurrentModuleObject: String = state.dataIPShortCut.cCurrentModuleObject
    cCurrentModuleObject = "LoadProfile:Plant"
    state.dataPlantLoadProfile.NumOfPlantProfile = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if state.dataPlantLoadProfile.NumOfPlantProfile > 0:
        state.dataPlantLoadProfile.PlantProfile = List[PlantProfileData]()
        state.dataPlantLoadProfile.PlantProfile.resize(state.dataPlantLoadProfile.NumOfPlantProfile)
        var ErrorsFound: Bool = False
        var IOStatus: Int
        var NumAlphas: Int
        var NumNumbers: Int
        for ProfileNum in range(state.dataPlantLoadProfile.NumOfPlantProfile):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, ProfileNum + 1, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNumbers, IOStatus, state.dataIPShortCut.lNumericFieldBlanks, _, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0])
            state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name = state.dataIPShortCut.cAlphaArgs[0]
            state.dataPlantLoadProfile.PlantProfile[ProfileNum].Type = DataPlant.PlantEquipmentType.PlantLoadProfile
            state.dataPlantLoadProfile.PlantProfile[ProfileNum].FluidType = PlantLoopFluidType(getEnumValue(PlantLoopFluidTypeNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[5])))
            if state.dataPlantLoadProfile.PlantProfile[ProfileNum].FluidType == PlantLoopFluidType.Invalid:
                state.dataPlantLoadProfile.PlantProfile[ProfileNum].FluidType = PlantLoopFluidType.Water
            if state.dataPlantLoadProfile.PlantProfile[ProfileNum].FluidType == PlantLoopFluidType.Water:
                state.dataPlantLoadProfile.PlantProfile[ProfileNum].InletNode = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[1], ErrorsFound, Node.ConnectionObjectType.LoadProfilePlant, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                state.dataPlantLoadProfile.PlantProfile[ProfileNum].OutletNode = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[2], ErrorsFound, Node.ConnectionObjectType.LoadProfilePlant, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            else:
                state.dataPlantLoadProfile.PlantProfile[ProfileNum].InletNode = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[1], ErrorsFound, Node.ConnectionObjectType.LoadProfilePlant, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Steam, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                state.dataPlantLoadProfile.PlantProfile[ProfileNum].OutletNode = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[2], ErrorsFound, Node.ConnectionObjectType.LoadProfilePlant, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Steam, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            var schedPtr: Pointer[Schedule] = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[3])
            if schedPtr == Pointer[Schedule]():
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[3], state.dataIPShortCut.cAlphaArgs[3])
                ErrorsFound = True
            else:
                state.dataPlantLoadProfile.PlantProfile[ProfileNum].loadSched = schedPtr
            state.dataPlantLoadProfile.PlantProfile[ProfileNum].PeakVolFlowRate = state.dataIPShortCut.rNumericArgs[0]
            var flowSchedPtr: Pointer[Schedule] = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[4])
            if flowSchedPtr == Pointer[Schedule]():
                ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[4], state.dataIPShortCut.cAlphaArgs[4])
                ErrorsFound = True
            else:
                state.dataPlantLoadProfile.PlantProfile[ProfileNum].flowRateFracSched = flowSchedPtr
            if state.dataPlantLoadProfile.PlantProfile[ProfileNum].FluidType == PlantLoopFluidType.Steam:
                if not state.dataIPShortCut.lNumericFieldBlanks[1]:
                    state.dataPlantLoadProfile.PlantProfile[ProfileNum].DegOfSubcooling = state.dataIPShortCut.rNumericArgs[1]
                else:
                    state.dataPlantLoadProfile.PlantProfile[ProfileNum].DegOfSubcooling = 5.0
                if not state.dataIPShortCut.lNumericFieldBlanks[2]:
                    state.dataPlantLoadProfile.PlantProfile[ProfileNum].LoopSubcoolReturn = state.dataIPShortCut.rNumericArgs[2]
                else:
                    state.dataPlantLoadProfile.PlantProfile[ProfileNum].LoopSubcoolReturn = 20.0
            Node.TestCompSet(state, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0], state.dataIPShortCut.cAlphaArgs[1], state.dataIPShortCut.cAlphaArgs[2], cCurrentModuleObject + " Nodes")
            SetupOutputVariable(state, "Plant Load Profile Mass Flow Rate", Constant.Units.kg_s, state.dataPlantLoadProfile.PlantProfile[ProfileNum].MassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name)
            SetupOutputVariable(state, "Plant Load Profile Heat Transfer Rate", Constant.Units.W, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Power, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name)
            SetupOutputVariable(state, "Plant Load Profile Heat Transfer Energy", Constant.Units.J, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating)
            SetupOutputVariable(state, "Plant Load Profile Heating Energy", Constant.Units.J, state.dataPlantLoadProfile.PlantProfile[ProfileNum].HeatingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name, Constant.eResource.PlantLoopHeatingDemand, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating)
            SetupOutputVariable(state, "Plant Load Profile Cooling Energy", Constant.Units.J, state.dataPlantLoadProfile.PlantProfile[ProfileNum].CoolingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name, Constant.eResource.PlantLoopCoolingDemand, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Cooling)
            if state.dataGlobal.AnyEnergyManagementSystemInModel:
                SetupEMSActuator(state, "Plant Load Profile", state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name, "Mass Flow Rate", "[kg/s]", state.dataPlantLoadProfile.PlantProfile[ProfileNum].EMSOverrideMassFlow, state.dataPlantLoadProfile.PlantProfile[ProfileNum].EMSMassFlowValue)
                SetupEMSActuator(state, "Plant Load Profile", state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name, "Power", "[W]", state.dataPlantLoadProfile.PlantProfile[ProfileNum].EMSOverridePower, state.dataPlantLoadProfile.PlantProfile[ProfileNum].EMSPowerValue)
            if state.dataPlantLoadProfile.PlantProfile[ProfileNum].FluidType == PlantLoopFluidType.Steam:
                SetupOutputVariable(state, "Plant Load Profile Steam Outlet Temperature", Constant.Units.C, state.dataPlantLoadProfile.PlantProfile[ProfileNum].OutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataPlantLoadProfile.PlantProfile[ProfileNum].Name)
            if ErrorsFound:
                ShowFatalError(state, format("Errors in {} input.", cCurrentModuleObject))

alias PlantLoopFluidTypeNamesUC: List[String] = List[String]("WATER", "STEAM")
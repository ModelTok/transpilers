from Array1D import Array1D
from EnergyPlus.Data.BaseData import BaseGlobalStruct, BaseData, EnergyPlusData
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.EnergyPlus import *
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantComponent import PlantComponent
from .Autosizing.Base import *
from BranchNodeConnections import *
from .Data.EnergyPlusData import *
from DataEnvironment import *
from DataHVACGlobals import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.DataLoopNode import *
from DataSizing import *
from FluidProperties import *
from General import *
from GlobalNames import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from OutsideEnergySources import *
from EnergyPlus.Plant.DataPlant import DataPlant
from PlantUtilities import *
from ScheduleManager import *
from UtilityRoutines import *
from EnergyPlus.Constant import InitConvTemp, StdPressureSeaLevel, eResource, Units
from EnergyPlus.Plant.DataPlant import PlantLoop, CompData, PlantSizData
from Math import max, min, sign, abs

# We'll need to import Sched, Node, ErrorObjectHeader etc. from their modules.
# For brevity, let's assume they are imported via the above wildcards.
# Actually, we need imports for Sched, Node, etc.
from ScheduleManager import Sched
from NodeInputManager import Node
from UtilityRoutines import ErrorObjectHeader, ShowFatalError, ShowSevereItemNotFound, ShowSevereError, ShowContinueError, ShowMessage, SetupOutputVariable

struct OutsideEnergySourceSpecs(PlantComponent):
    var Name: String
    var NomCap: Float64
    var NomCapWasAutoSized: Bool
    var capFractionSched: Sched.Schedule? # pointer, use optional
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var EnergyTransfer: Float64
    var EnergyRate: Float64
    var EnergyType: DataPlant.PlantEquipmentType
    var plantLoc: PlantLocation
    var BeginEnvrnInitFlag: Bool
    var CheckEquipName: Bool
    var MassFlowRate: Float64
    var InletTemp: Float64
    var OutletTemp: Float64
    var OutletSteamQuality: Float64

    def __init__(inout self):
        self.Name = ""
        self.NomCap = 0.0
        self.NomCapWasAutoSized = False
        self.capFractionSched = None
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.EnergyTransfer = 0.0
        self.EnergyRate = 0.0
        self.EnergyType = DataPlant.PlantEquipmentType.Invalid
        self.plantLoc = PlantLocation()
        self.BeginEnvrnInitFlag = True
        self.CheckEquipName = True
        self.MassFlowRate = 0.0
        self.InletTemp = 0.0
        self.OutletTemp = 0.0
        self.OutletSteamQuality = 0.0

    @staticmethod
    def factory(state: EnergyPlusData, objectType: DataPlant.PlantEquipmentType, objectName: String) -> PlantComponent:
        if state.dataOutsideEnergySrcs.SimOutsideEnergyGetInputFlag:
            GetOutsideEnergySourcesInput(state)
            state.dataOutsideEnergySrcs.SimOutsideEnergyGetInputFlag = False
        for source in state.dataOutsideEnergySrcs.EnergySource:
            if source.EnergyType == objectType and source.Name == objectName:
                return source
        ShowFatalError(state, "OutsideEnergySourceSpecsFactory: Error getting inputs for source named: {}".format(objectName))
        return None # LCOV_EXCL_LINE

    def simulate(mut self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, mut CurLoad: Float64, RunFlag: Bool):
        self.initialize(state, CurLoad)
        self.calculate(state, RunFlag, CurLoad)

    def onInitLoopEquip(mut self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        self.initialize(state, 0.0)
        self.size(state)

    def getDesignCapacities(mut self, state: EnergyPlusData, calledFromLocation: PlantLocation, mut MaxLoad: Float64, mut MinLoad: Float64, mut OptLoad: Float64):
        MinLoad = 0.0
        MaxLoad = self.NomCap
        OptLoad = self.NomCap

    def initialize(mut self, state: EnergyPlusData, MyLoad: Float64):
        var loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum - 1]
        if state.dataGlobal.BeginEnvrnFlag and self.BeginEnvrnInitFlag:
            PlantUtilities.InitComponentNodes(state, loop.MinMassFlowRate, loop.MaxMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
            self.BeginEnvrnInitFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.BeginEnvrnInitFlag = True
        var TempPlantMassFlow: Float64 = 0.0
        if abs(MyLoad) > 0.0:
            TempPlantMassFlow = loop.MaxMassFlowRate
        PlantUtilities.SetComponentFlowRate(state, TempPlantMassFlow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum - 1].Temp
        self.MassFlowRate = TempPlantMassFlow

    def size(mut self, state: EnergyPlusData):
        var ErrorsFound: Bool = False
        var typeName: String = DataPlant.PlantEquipTypeNames[Int(self.EnergyType) - 1]  # assuming 0-based enum
        var loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum - 1]
        var PltSizNum: Int = loop.PlantSizNum
        if PltSizNum > 0:
            var NomCapDes: Float64
            if self.EnergyType == DataPlant.PlantEquipmentType.PurchChilledWater or self.EnergyType == DataPlant.PlantEquipmentType.PurchHotWater:
                var rho = loop.glycol.getDensity(state, InitConvTemp, "Size {}".format(typeName))
                var Cp = loop.glycol.getSpecificHeat(state, InitConvTemp, "Size {}".format(typeName))
                NomCapDes = Cp * rho * state.dataSize.PlantSizData[PltSizNum - 1].DeltaT * state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate
            else:
                var tempSteam = loop.steam.getSatTemperature(state, state.dataEnvrn.StdBaroPress, "Size {}".format(typeName))
                var rhoSteam = loop.steam.getSatDensity(state, tempSteam, 1.0, "Size {}".format(typeName))
                var EnthSteamDry = loop.steam.getSatEnthalpy(state, tempSteam, 1.0, "Size {}".format(typeName))
                var EnthSteamWet = loop.steam.getSatEnthalpy(state, tempSteam, 0.0, "Size {}".format(typeName))
                var LatentHeatSteam = EnthSteamDry - EnthSteamWet
                NomCapDes = rhoSteam * state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate * LatentHeatSteam
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = NomCapDes
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, typeName, self.Name, "Design Size Nominal Capacity [W]", NomCapDes)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, typeName, self.Name, "Initial Design Size Nominal Capacity [W]", NomCapDes)
                else:
                    if self.NomCap > 0.0 and NomCapDes > 0.0:
                        var NomCapUser: Float64 = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, typeName, self.Name, "Design Size Nominal Capacity [W]", NomCapDes, "User-Specified Nominal Capacity [W]", NomCapUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(NomCapDes - NomCapUser) / NomCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, "Size {}: Potential issue with equipment sizing for {}".format(typeName, self.Name))
                                    ShowContinueError(state, "User-Specified Nominal Capacity of {:.2f} [W]".format(NomCapUser))
                                    ShowContinueError(state, "differs from Design Size Nominal Capacity of {:.2f} [W]".format(NomCapDes))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, "Autosizing of {} nominal capacity requires a loop Sizing:Plant object".format(typeName))
                ShowContinueError(state, "Occurs in {} object={}".format(typeName, self.Name))
                ErrorsFound = True
            if not self.NomCapWasAutoSized and self.NomCap > 0.0 and state.dataPlnt.PlantFinalSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, typeName, self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def calculate(mut self, state: EnergyPlusData, runFlag: Bool, mut MyLoad: Float64):
        var RoutineName: String = "SimDistrictEnergy"
        var loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum - 1]
        var LoopNum: Int = self.plantLoc.loopNum
        var LoopMinTemp: Float64 = state.dataPlnt.PlantLoop[LoopNum - 1].MinTemp
        var LoopMaxTemp: Float64 = state.dataPlnt.PlantLoop[LoopNum - 1].MaxTemp
        var LoopMinMdot: Float64 = state.dataPlnt.PlantLoop[LoopNum - 1].MinMassFlowRate
        var LoopMaxMdot: Float64 = state.dataPlnt.PlantLoop[LoopNum - 1].MaxMassFlowRate
        var CapFraction: Float64 = self.capFractionSched.getCurrentVal()
        CapFraction = max(0.0, CapFraction)
        var CurrentCap: Float64 = self.NomCap * CapFraction
        if abs(MyLoad) > CurrentCap:
            MyLoad = sign(CurrentCap, MyLoad)
        if self.EnergyType == DataPlant.PlantEquipmentType.PurchChilledWater:
            if MyLoad > 0.0:
                MyLoad = 0.0
        elif self.EnergyType == DataPlant.PlantEquipmentType.PurchHotWater or self.EnergyType == DataPlant.PlantEquipmentType.PurchSteam:
            if MyLoad < 0.0:
                MyLoad = 0.0
        if (self.MassFlowRate > 0.0) and runFlag:
            if self.EnergyType == DataPlant.PlantEquipmentType.PurchChilledWater or self.EnergyType == DataPlant.PlantEquipmentType.PurchHotWater:
                var Cp: Float64 = state.dataPlnt.PlantLoop[LoopNum - 1].glycol.getSpecificHeat(state, self.InletTemp, RoutineName)
                self.OutletTemp = (MyLoad + self.MassFlowRate * Cp * self.InletTemp) / (self.MassFlowRate * Cp)
                if self.OutletTemp < LoopMinTemp:
                    self.OutletTemp = max(self.OutletTemp, LoopMinTemp)
                    MyLoad = self.MassFlowRate * Cp * (self.OutletTemp - self.InletTemp)
                if self.OutletTemp > LoopMaxTemp:
                    self.OutletTemp = min(self.OutletTemp, LoopMaxTemp)
                    MyLoad = self.MassFlowRate * Cp * (self.OutletTemp - self.InletTemp)
            elif self.EnergyType == DataPlant.PlantEquipmentType.PurchSteam:
                var SatTempAtmPress: Float64 = loop.steam.getSatTemperature(state, StdPressureSeaLevel, RoutineName)
                var CpCondensate: Float64 = loop.glycol.getSpecificHeat(state, self.InletTemp, RoutineName)
                var deltaTsensible: Float64 = SatTempAtmPress - self.InletTemp
                var EnthSteamInDry: Float64 = loop.steam.getSatEnthalpy(state, self.InletTemp, 1.0, RoutineName)
                var EnthSteamOutWet: Float64 = loop.steam.getSatEnthalpy(state, self.InletTemp, 0.0, RoutineName)
                var LatentHeatSteam: Float64 = EnthSteamInDry - EnthSteamOutWet
                self.MassFlowRate = MyLoad / (LatentHeatSteam + (CpCondensate * deltaTsensible))
                PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
                self.OutletTemp = state.dataLoopNodes.Node[loop.TempSetPointNodeNum - 1].TempSetPoint
                self.OutletSteamQuality = 0.0
                if self.MassFlowRate < LoopMinMdot:
                    self.MassFlowRate = max(self.MassFlowRate, LoopMinMdot)
                    PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
                    MyLoad = self.MassFlowRate * LatentHeatSteam
                if self.MassFlowRate > LoopMaxMdot:
                    self.MassFlowRate = min(self.MassFlowRate, LoopMaxMdot)
                    PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
                    MyLoad = self.MassFlowRate * LatentHeatSteam
                state.dataLoopNodes.Node[self.OutletNodeNum - 1].Quality = 1.0
        else:
            self.OutletTemp = self.InletTemp
            MyLoad = 0.0
        var OutletNode: Int = self.OutletNodeNum
        state.dataLoopNodes.Node[OutletNode - 1].Temp = self.OutletTemp
        self.EnergyRate = abs(MyLoad)
        self.EnergyTransfer = self.EnergyRate * state.dataHVACGlobal.TimeStepSysSec

    def oneTimeInit_new(mut self, state: EnergyPlusData):
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.EnergyType, self.plantLoc, errFlag, _, _, _, _, _)
        if errFlag:
            ShowFatalError(state, "InitSimVars: Program terminated due to previous condition(s).")
        var loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum - 1]
        var comp = DataPlant.CompData.getPlantComponent(state, self.plantLoc)
        comp.MinOutletTemp = loop.MinTemp
        comp.MaxOutletTemp = loop.MaxTemp
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.InletNodeNum, loop.MaxVolFlowRate)
        var reportVarPrefix: String = "District Heating Water "
        var heatingOrCooling: OutputProcessor.EndUseCat = OutputProcessor.EndUseCat.Heating
        var meterTypeKey: Constant.eResource = Constant.eResource.DistrictHeatingWater
        if self.EnergyType == DataPlant.PlantEquipmentType.PurchChilledWater:
            reportVarPrefix = "District Cooling Water "
            heatingOrCooling = OutputProcessor.EndUseCat.Cooling
            meterTypeKey = Constant.eResource.DistrictCooling
        elif self.EnergyType == DataPlant.PlantEquipmentType.PurchSteam:
            reportVarPrefix = "District Heating Steam "
            heatingOrCooling = OutputProcessor.EndUseCat.Heating
            meterTypeKey = Constant.eResource.DistrictHeatingSteam
        SetupOutputVariable(state, "{}Energy".format(reportVarPrefix), Constant.Units.J, self.EnergyTransfer, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, meterTypeKey, OutputProcessor.Group.Plant, heatingOrCooling)
        SetupOutputVariable(state, "{}Rate".format(reportVarPrefix), Constant.Units.W, self.EnergyRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "{}Inlet Temperature".format(reportVarPrefix), Constant.Units.C, self.InletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "{}Outlet Temperature".format(reportVarPrefix), Constant.Units.C, self.OutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "{}Mass Flow Rate".format(reportVarPrefix), Constant.Units.kg_s, self.MassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)

    def oneTimeInit(mut self, state: EnergyPlusData):

def GetOutsideEnergySourcesInput(state: EnergyPlusData):
    var routineName: String = "GetOutsideEnergySourcesInput"
    var NumDistrictUnitsHeatWater: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "DistrictHeating:Water")
    var NumDistrictUnitsCool: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "DistrictCooling")
    var NumDistrictUnitsHeatSteam: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "DistrictHeating:Steam")
    state.dataOutsideEnergySrcs.NumDistrictUnits = NumDistrictUnitsHeatWater + NumDistrictUnitsCool + NumDistrictUnitsHeatSteam
    if allocated(state.dataOutsideEnergySrcs.EnergySource):
        return
    state.dataOutsideEnergySrcs.EnergySource.allocate(state.dataOutsideEnergySrcs.NumDistrictUnits)
    state.dataOutsideEnergySrcs.EnergySourceUniqueNames.reserve(state.dataOutsideEnergySrcs.NumDistrictUnits)
    var ErrorsFound: Bool = False
    var heatWaterIndex: Int = 0
    var coolIndex: Int = 0
    var heatSteamIndex: Int = 0
    for EnergySourceNum in range(1, state.dataOutsideEnergySrcs.NumDistrictUnits + 1):
        var nodeNames: String
        var EnergyType: DataPlant.PlantEquipmentType
        var objType: Node.ConnectionObjectType
        var thisIndex: Int
        if EnergySourceNum <= NumDistrictUnitsHeatWater:
            state.dataIPShortCut.cCurrentModuleObject = "DistrictHeating:Water"
            objType = Node.ConnectionObjectType.DistrictHeatingWater
            nodeNames = "Hot Water Nodes"
            EnergyType = DataPlant.PlantEquipmentType.PurchHotWater
            heatWaterIndex += 1
            thisIndex = heatWaterIndex
        elif EnergySourceNum <= NumDistrictUnitsHeatWater + NumDistrictUnitsCool:
            state.dataIPShortCut.cCurrentModuleObject = "DistrictCooling"
            objType = Node.ConnectionObjectType.DistrictCooling
            nodeNames = "Chilled Water Nodes"
            EnergyType = DataPlant.PlantEquipmentType.PurchChilledWater
            coolIndex += 1
            thisIndex = coolIndex
        else:
            state.dataIPShortCut.cCurrentModuleObject = "DistrictHeating:Steam"
            objType = Node.ConnectionObjectType.DistrictHeatingSteam
            nodeNames = "Steam Nodes"
            EnergyType = DataPlant.PlantEquipmentType.PurchSteam
            heatSteamIndex += 1
            thisIndex = heatSteamIndex
        var NumAlphas: Int = 0
        var NumNums: Int = 0
        var IOStat: Int = 0
        state.dataInputProcessing.inputProcessor.getObjectItem(state, state.dataIPShortCut.cCurrentModuleObject, thisIndex, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNums, IOStat, _, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[1])
        if EnergySourceNum > 1:
            GlobalNames.VerifyUniqueInterObjectName(state, state.dataOutsideEnergySrcs.EnergySourceUniqueNames, state.dataIPShortCut.cAlphaArgs[1], state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaFieldNames[1], ErrorsFound)
        state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].Name = state.dataIPShortCut.cAlphaArgs[1]
        if EnergySourceNum <= NumDistrictUnitsHeatWater + NumDistrictUnitsCool:
            state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].InletNodeNum = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[2], ErrorsFound, objType, state.dataIPShortCut.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].OutletNodeNum = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[3], ErrorsFound, objType, state.dataIPShortCut.cAlphaArgs[1], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        else:
            state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].InletNodeNum = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[2], ErrorsFound, objType, state.dataIPShortCut.cAlphaArgs[1], Node.FluidType.Steam, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].OutletNodeNum = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[3], ErrorsFound, objType, state.dataIPShortCut.cAlphaArgs[1], Node.FluidType.Steam, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        Node.TestCompSet(state, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[1], state.dataIPShortCut.cAlphaArgs[2], state.dataIPShortCut.cAlphaArgs[3], nodeNames)
        state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].NomCap = state.dataIPShortCut.rNumericArgs[1]
        if state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].NomCap == DataSizing.AutoSize:
            state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].NomCapWasAutoSized = True
        state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].EnergyTransfer = 0.0
        state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].EnergyRate = 0.0
        state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].EnergyType = EnergyType
        if state.dataIPShortCut.lAlphaFieldBlanks[4]:
            state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].capFractionSched = Sched.GetScheduleAlwaysOn(state)
        elif state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].capFractionSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[4]) == None:
            ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[4], state.dataIPShortCut.cAlphaArgs[4])
            ErrorsFound = True
        elif not state.dataOutsideEnergySrcs.EnergySource[EnergySourceNum - 1].capFractionSched.checkMinVal(state, Clusive.In, 0.0):
            Sched.ShowWarningBadMin(state, eoh, state.dataIPShortCut.cAlphaFieldNames[4], state.dataIPShortCut.cAlphaArgs[4], Clusive.In, 0.0, "Negative values will be treated as zero, and the simulation continues.")
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing input for {}, Preceding condition caused termination.".format(state.dataIPShortCut.cCurrentModuleObject))

struct OutsideEnergySourcesData(BaseGlobalStruct):
    var NumDistrictUnits: Int
    var SimOutsideEnergyGetInputFlag: Bool
    var EnergySource: Array1D[OutsideEnergySources.OutsideEnergySourceSpecs]
    var EnergySourceUniqueNames: Dict[String, String]

    def __init__(inout self):
        self.NumDistrictUnits = 0
        self.SimOutsideEnergyGetInputFlag = True
        self.EnergySource = Array1D[OutsideEnergySources.OutsideEnergySourceSpecs]()
        self.EnergySourceUniqueNames = Dict[String, String]()

    def init_constant_state(mut self, state: EnergyPlusData):

    def init_state(mut self, state: EnergyPlusData):

    def clear_state(mut self):
        self.NumDistrictUnits = 0
        self.SimOutsideEnergyGetInputFlag = True
        self.EnergySource.deallocate()
        self.EnergySourceUniqueNames.clear()
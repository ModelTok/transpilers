from .Autosizing.Base import BaseSizer
from BranchNodeConnections import TestCompSet
from CurveManager import GetCurve, Curve
from Data.BaseData import BaseGlobalStruct, EnergyPlusData
from DataBranchAirLoopPlant import MassFlowTolerance
from DataEnvironment import *
from DataGlobalConstants import Constant
from DataGlobals import *
from DataHVACGlobals import TimeStepSysSec
from DataIPShortCuts import *
from DataLoopNode import Node
from DataPlant import DataPlant
from DataSizing import DataSizing
from EMSManager import CheckIfNodeSetPointManagedByEMS
from FluidProperties import *
from GlobalNames import VerifyUniqueChillerName
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import GetOnlySingleNode
from OutAirNodeManager import CheckAndAddAirNodeNumber
from OutputProcessor import SetupOutputVariable, OutputProcessor
from OutputReportPredefined import PreDefTableEntry, dataOutRptPredefined
from Plant.Enums import *
from Plant.PlantLocation import PlantLocation
from PlantComponent import PlantComponent
from PlantUtilities import *
from Psychrometrics import *
from UtilityRoutines import *
from builtins import abs, max, min, format, String, Float64, Int, List, Optional, Bool, assert, print

alias eFuel = Constant.eFuel
alias eFuelNames = Constant.eFuelNames
alias eFuelNamesUC = Constant.eFuelNamesUC
alias eFuel2eResource = Constant.eFuel2eResource
alias eResource = Constant.eResource
alias Units = Constant.Units

struct GasAbsorberSpecs:
    var Available: Bool = False
    var ON: Bool = False
    var InCoolingMode: Bool = False
    var InHeatingMode: Bool = False
    var Name: String = ""
    var FuelType: eFuel = eFuel.Invalid
    var NomCoolingCap: Float64 = 0.0
    var NomCoolingCapWasAutoSized: Bool = False
    var NomHeatCoolRatio: Float64 = 0.0
    var FuelCoolRatio: Float64 = 0.0
    var FuelHeatRatio: Float64 = 0.0
    var ElecCoolRatio: Float64 = 0.0
    var ElecHeatRatio: Float64 = 0.0
    var ChillReturnNodeNum: Int = 0
    var ChillSupplyNodeNum: Int = 0
    var ChillSetPointErrDone: Bool = False
    var ChillSetPointSetToLoop: Bool = False
    var CondReturnNodeNum: Int = 0
    var CondSupplyNodeNum: Int = 0
    var HeatReturnNodeNum: Int = 0
    var HeatSupplyNodeNum: Int = 0
    var HeatSetPointErrDone: Bool = False
    var HeatSetPointSetToLoop: Bool = False
    var MinPartLoadRat: Float64 = 0.0
    var MaxPartLoadRat: Float64 = 0.0
    var OptPartLoadRat: Float64 = 0.0
    var TempDesCondReturn: Float64 = 0.0
    var TempDesCHWSupply: Float64 = 0.0
    var EvapVolFlowRate: Float64 = 0.0
    var EvapVolFlowRateWasAutoSized: Bool = False
    var CondVolFlowRate: Float64 = 0.0
    var CondVolFlowRateWasAutoSized: Bool = False
    var HeatVolFlowRate: Float64 = 0.0
    var HeatVolFlowRateWasAutoSized: Bool = False
    var SizFac: Float64 = 0.0
    var CoolCapFTCurve: Optional[Curve] = None
    var FuelCoolFTCurve: Optional[Curve] = None
    var FuelCoolFPLRCurve: Optional[Curve] = None
    var ElecCoolFTCurve: Optional[Curve] = None
    var ElecCoolFPLRCurve: Optional[Curve] = None
    var HeatCapFCoolCurve: Optional[Curve] = None
    var FuelHeatFHPLRCurve: Optional[Curve] = None
    var isEnterCondensTemp: Bool = False
    var isWaterCooled: Bool = False
    var CHWLowLimitTemp: Float64 = 0.0
    var FuelHeatingValue: Float64 = 0.0
    var DesCondMassFlowRate: Float64 = 0.0
    var DesHeatMassFlowRate: Float64 = 0.0
    var DesEvapMassFlowRate: Float64 = 0.0
    var DeltaTempCoolErrCount: Int = 0
    var DeltaTempHeatErrCount: Int = 0
    var CondErrCount: Int = 0
    var lCondWaterMassFlowRate_Index: Int = 0
    var PossibleSubcooling: Bool = False
    var CWplantLoc: PlantLocation = PlantLocation()
    var CDplantLoc: PlantLocation = PlantLocation()
    var HWplantLoc: PlantLocation = PlantLocation()
    var envrnFlag: Bool = True
    var oldCondSupplyTemp: Float64 = 0.0
    var CoolingLoad: Float64 = 0.0
    var CoolingEnergy: Float64 = 0.0
    var HeatingLoad: Float64 = 0.0
    var HeatingEnergy: Float64 = 0.0
    var TowerLoad: Float64 = 0.0
    var TowerEnergy: Float64 = 0.0
    var FuelUseRate: Float64 = 0.0
    var FuelEnergy: Float64 = 0.0
    var CoolFuelUseRate: Float64 = 0.0
    var CoolFuelEnergy: Float64 = 0.0
    var HeatFuelUseRate: Float64 = 0.0
    var HeatFuelEnergy: Float64 = 0.0
    var ElectricPower: Float64 = 0.0
    var ElectricEnergy: Float64 = 0.0
    var CoolElectricPower: Float64 = 0.0
    var CoolElectricEnergy: Float64 = 0.0
    var HeatElectricPower: Float64 = 0.0
    var HeatElectricEnergy: Float64 = 0.0
    var ChillReturnTemp: Float64 = 0.0
    var ChillSupplyTemp: Float64 = 0.0
    var ChillWaterFlowRate: Float64 = 0.0
    var CondReturnTemp: Float64 = 0.0
    var CondSupplyTemp: Float64 = 0.0
    var CondWaterFlowRate: Float64 = 0.0
    var HotWaterReturnTemp: Float64 = 0.0
    var HotWaterSupplyTemp: Float64 = 0.0
    var HotWaterFlowRate: Float64 = 0.0
    var CoolPartLoadRatio: Float64 = 0.0
    var HeatPartLoadRatio: Float64 = 0.0
    var CoolingCapacity: Float64 = 0.0
    var HeatingCapacity: Float64 = 0.0
    var FractionOfPeriodRunning: Float64 = 0.0
    var FuelCOP: Float64 = 0.0

    @staticmethod
    def factory(state: inout EnergyPlusData, objectName: String) -> Int:
        if state.dataChillerGasAbsorption.getGasAbsorberInputs:
            GetGasAbsorberInput(state)
            state.dataChillerGasAbsorption.getGasAbsorberInputs = False
        var idx: Int = -1
        for i in range(len(state.dataChillerGasAbsorption.GasAbsorber)):
            if state.dataChillerGasAbsorption.GasAbsorber[i].Name == objectName:
                idx = i
                break
        if idx >= 0:
            return idx
        ShowFatalError(state, "LocalGasAbsorberFactory: Error getting inputs for comp named: " + objectName)
        return -1

    def simulate(
        self: inout, state: inout EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: inout Float64, RunFlag: Bool
    ):
        var brIdentity: DataPlant.BrLoopType = DataPlant.BrLoopType.NoMatch
        var branchTotalComp: Int = calledFromLocation.branch.TotalComponents
        for iComp in range(1, branchTotalComp + 1):
            var compInletNodeNum: Int = calledFromLocation.branch.Comp[iComp - 1].NodeNumIn
            if compInletNodeNum == self.ChillReturnNodeNum:
                brIdentity = DataPlant.BrLoopType.Chiller
                break
            if compInletNodeNum == self.HeatReturnNodeNum:
                brIdentity = DataPlant.BrLoopType.Heater
                break
            if compInletNodeNum == self.CondReturnNodeNum:
                brIdentity = DataPlant.BrLoopType.Condenser
                break
            brIdentity = DataPlant.BrLoopType.NoMatch
        if brIdentity == DataPlant.BrLoopType.Chiller:
            self.InCoolingMode = RunFlag != False
            self.initialize(state)
            self.calculateChiller(state, CurLoad)
            self.updateCoolRecords(state, CurLoad, RunFlag)
        elif brIdentity == DataPlant.BrLoopType.Heater:
            self.InHeatingMode = RunFlag != False
            self.initialize(state)
            self.calculateHeater(state, CurLoad, RunFlag)
            self.updateHeatRecords(state, CurLoad, RunFlag)
        elif brIdentity == DataPlant.BrLoopType.Condenser:
            if self.CDplantLoc.loopNum > 0:
                PlantUtilities.UpdateChillerComponentCondenserSide(
                    state,
                    self.CDplantLoc.loopNum,
                    self.CDplantLoc.loopSideNum,
                    DataPlant.PlantEquipmentType.Chiller_DFAbsorption,
                    self.CondReturnNodeNum,
                    self.CondSupplyNodeNum,
                    self.TowerLoad,
                    self.CondReturnTemp,
                    self.CondSupplyTemp,
                    self.CondWaterFlowRate,
                    FirstHVACIteration
                )
        else:
            ShowSevereError(state, "Invalid call to Gas Absorber Chiller " + self.Name)
            ShowContinueError(state, "Node connections in branch are not consistent with object nodes.")
            ShowFatalError(state, "Preceding conditions cause termination.")

    def getDesignCapacities(
        self: inout, state: inout EnergyPlusData, calledFromLocation: PlantLocation, MaxLoad: inout Float64, MinLoad: inout Float64, OptLoad: inout Float64
    ):
        var matchfound: Bool = False
        var branchTotalComp: Int = calledFromLocation.branch.TotalComponents
        for iComp in range(1, branchTotalComp + 1):
            var compInletNodeNum: Int = calledFromLocation.branch.Comp[iComp - 1].NodeNumIn
            if compInletNodeNum == self.ChillReturnNodeNum:
                MinLoad = self.NomCoolingCap * self.MinPartLoadRat
                MaxLoad = self.NomCoolingCap * self.MaxPartLoadRat
                OptLoad = self.NomCoolingCap * self.OptPartLoadRat
                matchfound = True
                break
            if compInletNodeNum == self.HeatReturnNodeNum:
                var Sim_HeatCap: Float64 = self.NomCoolingCap * self.NomHeatCoolRatio
                MinLoad = Sim_HeatCap * self.MinPartLoadRat
                MaxLoad = Sim_HeatCap * self.MaxPartLoadRat
                OptLoad = Sim_HeatCap * self.OptPartLoadRat
                matchfound = True
                break
            if compInletNodeNum == self.CondReturnNodeNum:
                MinLoad = 0.0
                MaxLoad = 0.0
                OptLoad = 0.0
                matchfound = True
                break
            matchfound = False
        if not matchfound:
            ShowSevereError(state, "SimGasAbsorber: Invalid call to Gas Absorption Chiller-Heater " + self.Name)
            ShowContinueError(state, "Node connections in branch are not consistent with object nodes.")
            ShowFatalError(state, "Preceding conditions cause termination.")

    def getSizingFactor(self: inout, _SizFac: inout Float64):
        _SizFac = self.SizFac

    def onInitLoopEquip(self: inout, state: inout EnergyPlusData, calledFromLocation: PlantLocation):
        self.initialize(state)
        var BranchInletNodeNum: Int = calledFromLocation.branch.NodeNumIn
        if BranchInletNodeNum == self.ChillReturnNodeNum:
            self.size(state)
        elif BranchInletNodeNum == self.HeatReturnNodeNum:

        elif BranchInletNodeNum == self.CondReturnNodeNum:

        else:
            ShowSevereError(state, "SimGasAbsorber: Invalid call to Gas Absorption Chiller-Heater " + self.Name)
            ShowContinueError(state, "Node connections in branch are not consistent with object nodes.")
            ShowFatalError(state, "Preceding conditions cause termination.")

    def getDesignTemperatures(self: inout, TempCondInDesign: inout Float64, TempEvapOutDesign: inout Float64):
        TempEvapOutDesign = self.TempDesCHWSupply
        TempCondInDesign = self.TempDesCondReturn

    def oneTimeInit(self: inout, state: inout EnergyPlusData):

    def oneTimeInit_new(self: inout, state: inout EnergyPlusData):
        self.setupOutputVariables(state)
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(
            state,
            self.Name,
            DataPlant.PlantEquipmentType.Chiller_DFAbsorption,
            self.CWplantLoc,
            errFlag,
            self.CHWLowLimitTemp,
            _,
            _,
            self.ChillReturnNodeNum,
            _
        )
        if errFlag:
            ShowFatalError(state, "InitGasAbsorber: Program terminated due to previous condition(s).")
        PlantUtilities.ScanPlantLoopsForObject(
            state, self.Name, DataPlant.PlantEquipmentType.Chiller_DFAbsorption, self.HWplantLoc, errFlag, _, _, _, self.HeatReturnNodeNum, _
        )
        if errFlag:
            ShowFatalError(state, "InitGasAbsorber: Program terminated due to previous condition(s).")
        if self.isWaterCooled:
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, DataPlant.PlantEquipmentType.Chiller_DFAbsorption, self.CDplantLoc, errFlag, _, _, _, self.CondReturnNodeNum, _
            )
            if errFlag:
                ShowFatalError(state, "InitGasAbsorber: Program terminated due to previous condition(s).")
            PlantUtilities.InterConnectTwoPlantLoopSides(
                state, self.CWplantLoc, self.CDplantLoc, DataPlant.PlantEquipmentType.Chiller_DFAbsorption, True
            )
            PlantUtilities.InterConnectTwoPlantLoopSides(
                state, self.HWplantLoc, self.CDplantLoc, DataPlant.PlantEquipmentType.Chiller_DFAbsorption, True
            )
        PlantUtilities.InterConnectTwoPlantLoopSides(
            state, self.CWplantLoc, self.HWplantLoc, DataPlant.PlantEquipmentType.Chiller_DFAbsorption, True
        )
        if (state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPoint == Node.SensedNodeFlagValue) and (
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPointHi == Node.SensedNodeFlagValue
        ):
            if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                if not self.ChillSetPointErrDone:
                    ShowWarningError(state, "Missing temperature setpoint on cool side for chiller heater named " + self.Name)
                    ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of this chiller, use a SetpointManager")
                    ShowContinueError(state, "  The overall loop setpoint will be assumed for chiller. The simulation continues ... ")
                    self.ChillSetPointErrDone = True
            else:
                errFlag = False
                CheckIfNodeSetPointManagedByEMS(state, self.ChillSupplyNodeNum, HVAC.CtrlVarType.Temp, errFlag)
                state.dataLoopNodes.NodeSetpointCheck[self.ChillSupplyNodeNum].needsSetpointChecking = False
                if errFlag:
                    if not self.ChillSetPointErrDone:
                        ShowWarningError(state, "Missing temperature setpoint on cool side for chiller heater named " + self.Name)
                        ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of this chiller evaporator ")
                        ShowContinueError(state, "  use a Setpoint Manager to establish a setpoint at the chiller evaporator outlet node ")
                        ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at the outlet node ")
                        ShowContinueError(state, "  The overall loop setpoint will be assumed for chiller. The simulation continues ... ")
                        self.ChillSetPointErrDone = True
            self.ChillSetPointSetToLoop = True
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPoint = (
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            )
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPointHi = (
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPointHi
            )
        if (state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPoint == Node.SensedNodeFlagValue) and (
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPointLo == Node.SensedNodeFlagValue
        ):
            if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                if not self.HeatSetPointErrDone:
                    ShowWarningError(state, "Missing temperature setpoint on heat side for chiller heater named " + self.Name)
                    ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of this chiller, use a SetpointManager")
                    ShowContinueError(state, "  The overall loop setpoint will be assumed for chiller. The simulation continues ... ")
                    self.HeatSetPointErrDone = True
            else:
                errFlag = False
                CheckIfNodeSetPointManagedByEMS(state, self.HeatSupplyNodeNum, HVAC.CtrlVarType.Temp, errFlag)
                state.dataLoopNodes.NodeSetpointCheck[self.HeatSupplyNodeNum].needsSetpointChecking = False
                if errFlag:
                    if not self.HeatSetPointErrDone:
                        ShowWarningError(state, "Missing temperature setpoint on heat side for chiller heater named " + self.Name)
                        ShowContinueError(state, "  A temperature setpoint is needed at the outlet node of this chiller heater ")
                        ShowContinueError(state, "  use a Setpoint Manager to establish a setpoint at the heater side outlet node ")
                        ShowContinueError(state, "  or use an EMS actuator to establish a setpoint at the outlet node ")
                        ShowContinueError(state, "  The overall loop setpoint will be assumed for heater side. The simulation continues ... ")
                        self.HeatSetPointErrDone = True
            self.HeatSetPointSetToLoop = True
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPoint = (
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            )
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPointLo = (
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPointLo
            )

    def initialize(self: inout, state: inout EnergyPlusData):
        const RoutineName: String = "InitGasAbsorber"
        var rho: Float64 = 0.0
        var mdot: Float64 = 0.0
        var CondInletNode: Int = self.CondReturnNodeNum
        var CondOutletNode: Int = self.CondSupplyNodeNum
        var HeatInletNode: Int = self.HeatReturnNodeNum
        var HeatOutletNode: Int = self.HeatSupplyNodeNum
        if self.envrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if self.isWaterCooled:
                if self.CDplantLoc.loopNum > 0:
                    rho = self.CDplantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                else:
                    rho = Psychrometrics.RhoH2O(Constant.InitConvTemp)
                self.DesCondMassFlowRate = rho * self.CondVolFlowRate
                PlantUtilities.InitComponentNodes(state, 0.0, self.DesCondMassFlowRate, CondInletNode, CondOutletNode)
            if self.HWplantLoc.loopNum > 0:
                rho = self.HWplantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
            else:
                rho = Psychrometrics.RhoH2O(Constant.InitConvTemp)
            self.DesHeatMassFlowRate = rho * self.HeatVolFlowRate
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesHeatMassFlowRate, HeatInletNode, HeatOutletNode)
            if self.CWplantLoc.loopNum > 0:
                rho = self.CWplantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
            else:
                rho = Psychrometrics.RhoH2O(Constant.InitConvTemp)
            self.DesEvapMassFlowRate = rho * self.EvapVolFlowRate
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesEvapMassFlowRate, self.ChillReturnNodeNum, self.ChillSupplyNodeNum)
            self.envrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.envrnFlag = True
        if self.ChillSetPointSetToLoop:
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPoint = (
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            )
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPointHi = (
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPointHi
            )
        if self.HeatSetPointSetToLoop:
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPoint = (
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            )
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPointLo = (
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPointLo
            )
        if (self.isWaterCooled) and ((self.InHeatingMode) or (self.InCoolingMode)):
            mdot = self.DesCondMassFlowRate
            PlantUtilities.SetComponentFlowRate(state, mdot, self.CondReturnNodeNum, self.CondSupplyNodeNum, self.CDplantLoc)
        else:
            mdot = 0.0
            if (self.CDplantLoc.loopNum > 0) and self.isWaterCooled:
                PlantUtilities.SetComponentFlowRate(state, mdot, self.CondReturnNodeNum, self.CondSupplyNodeNum, self.CDplantLoc)

    def setupOutputVariables(self: inout, state: inout EnergyPlusData):
        var sFuelType: String = Constant.eFuelNames[Int(self.FuelType)]
        SetupOutputVariable(
            state,
            "Chiller Heater Evaporator Cooling Rate",
            Constant.Units.W,
            self.CoolingLoad,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Evaporator Cooling Energy",
            Constant.Units.J,
            self.CoolingEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Chillers
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Rate",
            Constant.Units.W,
            self.HeatingLoad,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Energy",
            Constant.Units.J,
            self.HeatingEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Boilers
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Condenser Heat Transfer Rate",
            Constant.Units.W,
            self.TowerLoad,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Condenser Heat Transfer Energy",
            Constant.Units.J,
            self.TowerEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.HeatRejection
        )
        SetupOutputVariable(
            state,
            "Chiller Heater " + sFuelType + " Rate",
            Constant.Units.W,
            self.FuelUseRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater " + sFuelType + " Energy",
            Constant.Units.J,
            self.FuelEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Cooling " + sFuelType + " Rate",
            Constant.Units.W,
            self.CoolFuelUseRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Cooling " + sFuelType + " Energy",
            Constant.Units.J,
            self.CoolFuelEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eFuel2eResource[Int(self.FuelType)],
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Cooling
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Cooling COP",
            Constant.Units.W_W,
            self.FuelCOP,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating " + sFuelType + " Rate",
            Constant.Units.W,
            self.HeatFuelUseRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating " + sFuelType + " Energy",
            Constant.Units.J,
            self.HeatFuelEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eFuel2eResource[Int(self.FuelType)],
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Heating
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Electricity Rate",
            Constant.Units.W,
            self.ElectricPower,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Electricity Energy",
            Constant.Units.J,
            self.ElectricEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Cooling Electricity Rate",
            Constant.Units.W,
            self.CoolElectricPower,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Cooling Electricity Energy",
            Constant.Units.J,
            self.CoolElectricEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eResource.Electricity,
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Cooling
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Electricity Rate",
            Constant.Units.W,
            self.HeatElectricPower,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Electricity Energy",
            Constant.Units.J,
            self.HeatElectricEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name,
            Constant.eResource.Electricity,
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.Heating
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Evaporator Inlet Temperature",
            Constant.Units.C,
            self.ChillReturnTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Evaporator Outlet Temperature",
            Constant.Units.C,
            self.ChillSupplyTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Evaporator Mass Flow Rate",
            Constant.Units.kg_s,
            self.ChillWaterFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        if self.isWaterCooled:
            SetupOutputVariable(
                state,
                "Chiller Heater Condenser Inlet Temperature",
                Constant.Units.C,
                self.CondReturnTemp,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name
            )
            SetupOutputVariable(
                state,
                "Chiller Heater Condenser Outlet Temperature",
                Constant.Units.C,
                self.CondSupplyTemp,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name
            )
            SetupOutputVariable(
                state,
                "Chiller Heater Condenser Mass Flow Rate",
                Constant.Units.kg_s,
                self.CondWaterFlowRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name
            )
        else:
            SetupOutputVariable(
                state,
                "Chiller Heater Condenser Inlet Temperature",
                Constant.Units.C,
                self.CondReturnTemp,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.Name
            )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Inlet Temperature",
            Constant.Units.C,
            self.HotWaterReturnTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Outlet Temperature",
            Constant.Units.C,
            self.HotWaterSupplyTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Mass Flow Rate",
            Constant.Units.kg_s,
            self.HotWaterFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Cooling Part Load Ratio",
            Constant.Units.None,
            self.CoolPartLoadRatio,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Maximum Cooling Rate",
            Constant.Units.W,
            self.CoolingCapacity,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Heating Part Load Ratio",
            Constant.Units.None,
            self.HeatPartLoadRatio,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Maximum Heating Rate",
            Constant.Units.W,
            self.HeatingCapacity,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )
        SetupOutputVariable(
            state,
            "Chiller Heater Runtime Fraction",
            Constant.Units.None,
            self.FractionOfPeriodRunning,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name
        )

    def size(self: inout, state: inout EnergyPlusData):
        const RoutineName: String = "SizeGasAbsorber"
        var Cp: Float64 = 0.0
        var rho: Float64 = 0.0
        var NomCapUser: Float64 = 0.0
        var EvapVolFlowRateUser: Float64 = 0.0
        var CondVolFlowRateUser: Float64 = 0.0
        var HeatRecVolFlowRateUser: Float64 = 0.0
        var ErrorsFound: Bool = False
        var tmpNomCap: Float64 = self.NomCoolingCap
        var tmpEvapVolFlowRate: Float64 = self.EvapVolFlowRate
        var tmpCondVolFlowRate: Float64 = self.CondVolFlowRate
        var tmpHeatRecVolFlowRate: Float64 = self.HeatVolFlowRate
        var PltSizCondNum: Int = 0
        if self.isWaterCooled:
            PltSizCondNum = self.CDplantLoc.loop.PlantSizNum
        var PltSizHeatNum: Int = self.HWplantLoc.loop.PlantSizNum
        var PltSizCoolNum: Int = self.CWplantLoc.loop.PlantSizNum
        if PltSizCoolNum > 0:
            if state.dataSize.PlantSizData[PltSizCoolNum - 1].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                Cp = self.CWplantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, RoutineName)
                rho = self.CWplantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                tmpNomCap = Cp * rho * state.dataSize.PlantSizData[PltSizCoolNum - 1].DeltaT * state.dataSize.PlantSizData[PltSizCoolNum - 1].DesVolFlowRate * self.SizFac
                if not self.NomCoolingCapWasAutoSized:
                    tmpNomCap = self.NomCoolingCap
            else:
                if self.NomCoolingCapWasAutoSized:
                    tmpNomCap = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCoolingCapWasAutoSized:
                    self.NomCoolingCap = tmpNomCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "ChillerHeater:Absorption:DirectFired", self.Name, "Design Size Nominal Cooling Capacity [W]", tmpNomCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "ChillerHeater:Absorption:DirectFired", self.Name, "Initial Design Size Nominal Cooling Capacity [W]", tmpNomCap)
                else:
                    if (self.NomCoolingCap > 0.0) and (tmpNomCap > 0.0):
                        NomCapUser = self.NomCoolingCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(
                                state,
                                "ChillerHeater:Absorption:DirectFired",
                                self.Name,
                                "Design Size Nominal Cooling Capacity [W]",
                                tmpNomCap,
                                "User-Specified Nominal Cooling Capacity [W]",
                                NomCapUser
                            )
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpNomCap - NomCapUser) / NomCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(
                                        state,
                                        "SizeChillerHeaterAbsorptionDirectFired: Potential issue with equipment sizing for " + self.Name
                                    )
                                    ShowContinueError(state, "User-Specified Nominal Capacity of {:.2f} [W]".format(NomCapUser))
                                    ShowContinueError(state, "differs from Design Size Nominal Capacity of {:.2f} [W]".format(tmpNomCap))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpNomCap = NomCapUser
        else:
            if self.NomCoolingCapWasAutoSized:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "SizeGasAbsorber: ChillerHeater:Absorption:DirectFired=\"{}\", autosize error.".format(self.Name))
                    ShowContinueError(state, "Autosizing of Direct Fired Absorption Chiller nominal cooling capacity requires")
                    ShowContinueError(state, "a cooling loop Sizing:Plant object.")
                    ErrorsFound = True
            else:
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    if self.NomCoolingCap > 0.0:
                        BaseSizer.reportSizerOutput(state, "ChillerHeater:Absorption:DirectFired", self.Name, "User-Specified Nominal Capacity [W]", self.NomCoolingCap)
        if PltSizCoolNum > 0:
            if state.dataSize.PlantSizData[PltSizCoolNum - 1].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                tmpEvapVolFlowRate = state.dataSize.PlantSizData[PltSizCoolNum - 1].DesVolFlowRate * self.SizFac
                if not self.EvapVolFlowRateWasAutoSized:
                    tmpEvapVolFlowRate = self.EvapVolFlowRate
            else:
                if self.EvapVolFlowRateWasAutoSized:
                    tmpEvapVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.EvapVolFlowRateWasAutoSized:
                    self.EvapVolFlowRate = tmpEvapVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "Design Size Design Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate
                        )
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "Initial Design Size Design Chilled Water Flow Rate [m3/s]", tmpEvapVolFlowRate
                        )
                else:
                    if (self.EvapVolFlowRate > 0.0) and (tmpEvapVolFlowRate > 0.0):
                        EvapVolFlowRateUser = self.EvapVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(
                                state,
                                "ChillerHeater:Absorption:DirectFired",
                                self.Name,
                                "Design Size Design Chilled Water Flow Rate [m3/s]",
                                tmpEvapVolFlowRate,
                                "User-Specified Design Chilled Water Flow Rate [m3/s]",
                                EvapVolFlowRateUser
                            )
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpEvapVolFlowRate - EvapVolFlowRateUser) / EvapVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(
                                        state, "SizeChillerAbsorptionDirectFired: Potential issue with equipment sizing for " + self.Name
                                    )
                                    ShowContinueError(state, "User-Specified Design Chilled Water Flow Rate of {:#G} [m3/s]".format(EvapVolFlowRateUser))
                                    ShowContinueError(state, "differs from Design Size Design Chilled Water Flow Rate of {:#G} [m3/s]".format(tmpEvapVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpEvapVolFlowRate = EvapVolFlowRateUser
        else:
            if self.EvapVolFlowRateWasAutoSized:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "SizeGasAbsorber: ChillerHeater:Absorption:DirectFired=\"{}\", autosize error.".format(self.Name))
                    ShowContinueError(state, "Autosizing of Direct Fired Absorption Chiller evap flow rate requires")
                    ShowContinueError(state, "a cooling loop Sizing:Plant object.")
                    ErrorsFound = True
            else:
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    if self.EvapVolFlowRate > 0.0:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "User-Specified Design Chilled Water Flow Rate [m3/s]", self.EvapVolFlowRate
                        )
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.ChillReturnNodeNum, tmpEvapVolFlowRate)
        if PltSizHeatNum > 0:
            if state.dataSize.PlantSizData[PltSizHeatNum - 1].DesVolFlowRate >= HVAC.SmallWaterVolFlow:
                tmpHeatRecVolFlowRate = state.dataSize.PlantSizData[PltSizHeatNum - 1].DesVolFlowRate * self.SizFac
                if not self.HeatVolFlowRateWasAutoSized:
                    tmpHeatRecVolFlowRate = self.HeatVolFlowRate
            else:
                if self.HeatVolFlowRateWasAutoSized:
                    tmpHeatRecVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.HeatVolFlowRateWasAutoSized:
                    self.HeatVolFlowRate = tmpHeatRecVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "Design Size Design Hot Water Flow Rate [m3/s]", tmpHeatRecVolFlowRate
                        )
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "Initial Design Size Design Hot Water Flow Rate [m3/s]", tmpHeatRecVolFlowRate
                        )
                else:
                    if (self.HeatVolFlowRate > 0.0) and (tmpHeatRecVolFlowRate > 0.0):
                        HeatRecVolFlowRateUser = self.HeatVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(
                                state,
                                "ChillerHeater:Absorption:DirectFired",
                                self.Name,
                                "Design Size Design Hot Water Flow Rate [m3/s]",
                                tmpHeatRecVolFlowRate,
                                "User-Specified Design Hot Water Flow Rate [m3/s]",
                                HeatRecVolFlowRateUser
                            )
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpHeatRecVolFlowRate - HeatRecVolFlowRateUser) / HeatRecVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(
                                        state, "SizeChillerHeaterAbsorptionDirectFired: Potential issue with equipment sizing for " + self.Name
                                    )
                                    ShowContinueError(state, "User-Specified Design Hot Water Flow Rate of {:#G} [m3/s]".format(HeatRecVolFlowRateUser))
                                    ShowContinueError(state, "differs from Design Size Design Hot Water Flow Rate of {:#G} [m3/s]".format(tmpHeatRecVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpHeatRecVolFlowRate = HeatRecVolFlowRateUser
        else:
            if self.HeatVolFlowRateWasAutoSized:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "SizeGasAbsorber: ChillerHeater:Absorption:DirectFired=\"{}\", autosize error.".format(self.Name))
                    ShowContinueError(state, "Autosizing of Direct Fired Absorption Chiller hot water flow rate requires")
                    ShowContinueError(state, "a heating loop Sizing:Plant object.")
                    ErrorsFound = True
            else:
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    if self.HeatVolFlowRate > 0.0:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "User-Specified Design Hot Water Flow Rate [m3/s]", self.HeatVolFlowRate
                        )
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.HeatReturnNodeNum, tmpHeatRecVolFlowRate)
        if (PltSizCondNum > 0) and (PltSizCoolNum > 0):
            if (state.dataSize.PlantSizData[PltSizCoolNum - 1].DesVolFlowRate >= HVAC.SmallWaterVolFlow) and (tmpNomCap > 0.0):
                Cp = self.CDplantLoc.loop.glycol.getSpecificHeat(state, self.TempDesCondReturn, RoutineName)
                rho = self.CDplantLoc.loop.glycol.getDensity(state, self.TempDesCondReturn, RoutineName)
                tmpCondVolFlowRate = tmpNomCap * (1.0 + self.FuelCoolRatio) / (state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT * Cp * rho)
                if not self.CondVolFlowRateWasAutoSized:
                    tmpCondVolFlowRate = self.CondVolFlowRate
            else:
                if self.CondVolFlowRateWasAutoSized:
                    tmpCondVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.CondVolFlowRateWasAutoSized:
                    self.CondVolFlowRate = tmpCondVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "Design Size Design Condenser Water Flow Rate [m3/s]", tmpCondVolFlowRate
                        )
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "Initial Design Size Design Condenser Water Flow Rate [m3/s]", tmpCondVolFlowRate
                        )
                else:
                    if (self.CondVolFlowRate > 0.0) and (tmpCondVolFlowRate > 0.0):
                        CondVolFlowRateUser = self.CondVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer.reportSizerOutput(
                                state,
                                "ChillerHeater:Absorption:DirectFired",
                                self.Name,
                                "Design Size Design Condenser Water Flow Rate [m3/s]",
                                tmpCondVolFlowRate,
                                "User-Specified Design Condenser Water Flow Rate [m3/s]",
                                CondVolFlowRateUser
                            )
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpCondVolFlowRate - CondVolFlowRateUser) / CondVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(
                                        state, "SizeChillerAbsorptionDirectFired: Potential issue with equipment sizing for " + self.Name
                                    )
                                    ShowContinueError(state, "User-Specified Design Condenser Water Flow Rate of {:#G} [m3/s]".format(CondVolFlowRateUser))
                                    ShowContinueError(state, "differs from Design Size Design Condenser Water Flow Rate of {:#G} [m3/s]".format(tmpCondVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpCondVolFlowRate = CondVolFlowRateUser
        else:
            if self.CondVolFlowRateWasAutoSized:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "SizeGasAbsorber: ChillerHeater:Absorption:DirectFired=\"{}\", autosize error.".format(self.Name))
                    ShowContinueError(state, "Autosizing of Direct Fired Absorption Chiller condenser flow rate requires a condenser")
                    ShowContinueError(state, "loop Sizing:Plant object.")
                    ErrorsFound = True
            else:
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    if self.CondVolFlowRate > 0.0:
                        BaseSizer.reportSizerOutput(
                            state, "ChillerHeater:Absorption:DirectFired", self.Name, "User-Specified Design Condenser Water Flow Rate [m3/s]", self.CondVolFlowRate
                        )
        if self.isWaterCooled:
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.CondReturnNodeNum, tmpCondVolFlowRate)
        if ErrorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "ChillerHeater:Absorption:DirectFired")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, self.Name, self.FuelCoolRatio)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.NomCoolingCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerType, self.Name, "ChillerHeater:Absorption:DirectFired")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefCap, self.Name, self.NomCoolingCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefEff, self.Name, self.FuelCoolRatio)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedCap, self.Name, self.FuelCoolRatio)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedEff, self.Name, self.NomCoolingCap)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerIPLVinSI, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerIPLVinIP, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(
                state, state.dataOutRptPredefined.pdchChillerPlantloopName, self.Name,
                (self.CWplantLoc.loop != None) ? self.CWplantLoc.loop.Name : "N/A"
            )
            OutputReportPredefined.PreDefTableEntry(
                state, state.dataOutRptPredefined.pdchChillerPlantloopBranchName, self.Name,
                (self.CWplantLoc.loop != None) ? self.CWplantLoc.branch.Name : "N/A"
            )
            OutputReportPredefined.PreDefTableEntry(
                state, state.dataOutRptPredefined.pdchChillerCondLoopName, self.Name,
                (self.CDplantLoc.loop != None) ? self.CDplantLoc.loop.Name : "N/A"
            )
            OutputReportPredefined.PreDefTableEntry(
                state, state.dataOutRptPredefined.pdchChillerCondLoopBranchName, self.Name,
                (self.CDplantLoc.branch != None) ? self.CDplantLoc.branch.Name : "N/A"
            )
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerMinPLR, self.Name, self.MinPartLoadRat)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerFuelType, self.Name, Constant.eResourceNames[Int(self.FuelType)])
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedEntCondTemp, self.Name, self.TempDesCondReturn)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRatedLevEvapTemp, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefEntCondTemp, self.Name, self.TempDesCondReturn)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRefLevEvapTemp, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerDesSizeRefCHWFlowRate, self.Name, self.DesEvapMassFlowRate)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerDesSizeRefCondFluidFlowRate, self.Name, self.DesCondMassFlowRate)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerHeatRecPlantloopName, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerHeatRecPlantloopBranchName, self.Name, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchChillerRecRelCapFrac, self.Name, "N/A")

    def calculateChiller(self: inout, state: inout EnergyPlusData, MyLoad: inout Float64):
        const RoutineName: String = "CalcGasAbsorberChillerModel"
        var lCoolingLoad: Float64 = 0.0
        var lTowerLoad: Float64 = 0.0
        var lCoolFuelUseRate: Float64 = 0.0
        var lCoolElectricPower: Float64 = 0.0
        var lChillSupplyTemp: Float64 = 0.0
        var lCondSupplyTemp: Float64 = 0.0
        var lCondWaterMassFlowRate: Float64 = 0.0
        var lCoolPartLoadRatio: Float64 = 0.0
        var lAvailableCoolingCapacity: Float64 = 0.0
        var lFractionOfPeriodRunning: Float64 = 0.0
        var PartLoadRat: Float64 = 0.0
        var lChillWaterMassflowratemax: Float64 = 0.0
        var ChillSupplySetPointTemp: Float64 = 0.0
        var
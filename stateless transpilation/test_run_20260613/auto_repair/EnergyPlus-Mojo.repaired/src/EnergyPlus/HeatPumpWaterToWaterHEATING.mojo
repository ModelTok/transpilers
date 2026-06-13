from math import exp, pow, abs
from memory import pointer
from string import String
from utils import format
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.string.functions import *
from EnergyPlus.BranchNodeConnections import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataBranchAirLoopPlant import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.General import *
from EnergyPlus.HeatPumpWaterToWaterHEATING import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.NodeInputManager import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.Plant.PlantLocation import *
from EnergyPlus.PlantUtilities import *
from EnergyPlus.UtilityRoutines import *

alias Real64 = Float64
alias int = Int

var ModuleCompName: String = "HeatPump:WaterToWater:ParameterEstimation:Heating"
var ModuleCompNameUC: String = "HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:HEATING"
var GSHPRefrigerant: String = "R22"

struct GshpPeHeatingSpecs:
    var Name: String
    var WWHPPlantType: DataPlant.PlantEquipmentType
    var refrig: Fluid.RefrigProps
    var Available: Bool
    var ON: Bool
    var COP: Real64
    var NomCap: Real64
    var MinPartLoadRat: Real64
    var MaxPartLoadRat: Real64
    var OptPartLoadRat: Real64
    var LoadSideVolFlowRate: Real64
    var LoadSideDesignMassFlow: Real64
    var SourceSideVolFlowRate: Real64
    var SourceSideDesignMassFlow: Real64
    var SourceSideInletNodeNum: int
    var SourceSideOutletNodeNum: int
    var LoadSideInletNodeNum: int
    var LoadSideOutletNodeNum: int
    var SourceSideUACoeff: Real64
    var LoadSideUACoeff: Real64
    var CompPistonDisp: Real64
    var CompClearanceFactor: Real64
    var CompSucPressDrop: Real64
    var SuperheatTemp: Real64
    var PowerLosses: Real64
    var LossFactor: Real64
    var HighPressCutoff: Real64
    var LowPressCutoff: Real64
    var IsOn: Bool
    var MustRun: Bool
    var SourcePlantLoc: PlantLocation
    var LoadPlantLoc: PlantLocation
    var CondMassFlowIndex: int
    var Power: Real64
    var Energy: Real64
    var QLoad: Real64
    var QLoadEnergy: Real64
    var QSource: Real64
    var QSourceEnergy: Real64
    var LoadSideWaterInletTemp: Real64
    var SourceSideWaterInletTemp: Real64
    var LoadSideWaterOutletTemp: Real64
    var SourceSideWaterOutletTemp: Real64
    var LoadSideWaterMassFlowRate: Real64
    var SourceSideWaterMassFlowRate: Real64
    var Running: int
    var plantScanFlag: Bool
    var beginEnvironFlag: Bool

    def __init__(inout self):
        self.Name = String("")
        self.WWHPPlantType = DataPlant.PlantEquipmentType.Invalid
        self.refrig = Fluid.RefrigProps()
        self.Available = False
        self.ON = False
        self.COP = 0.0
        self.NomCap = 0.0
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.LoadSideVolFlowRate = 0.0
        self.LoadSideDesignMassFlow = 0.0
        self.SourceSideVolFlowRate = 0.0
        self.SourceSideDesignMassFlow = 0.0
        self.SourceSideInletNodeNum = 0
        self.SourceSideOutletNodeNum = 0
        self.LoadSideInletNodeNum = 0
        self.LoadSideOutletNodeNum = 0
        self.SourceSideUACoeff = 0.0
        self.LoadSideUACoeff = 0.0
        self.CompPistonDisp = 0.0
        self.CompClearanceFactor = 0.0
        self.CompSucPressDrop = 0.0
        self.SuperheatTemp = 0.0
        self.PowerLosses = 0.0
        self.LossFactor = 0.0
        self.HighPressCutoff = 0.0
        self.LowPressCutoff = 0.0
        self.IsOn = False
        self.MustRun = False
        self.CondMassFlowIndex = 0
        self.Power = 0.0
        self.Energy = 0.0
        self.QLoad = 0.0
        self.QLoadEnergy = 0.0
        self.QSource = 0.0
        self.QSourceEnergy = 0.0
        self.LoadSideWaterInletTemp = 0.0
        self.SourceSideWaterInletTemp = 0.0
        self.LoadSideWaterOutletTemp = 0.0
        self.SourceSideWaterOutletTemp = 0.0
        self.LoadSideWaterMassFlowRate = 0.0
        self.SourceSideWaterMassFlowRate = 0.0
        self.Running = 0
        self.plantScanFlag = True
        self.beginEnvironFlag = True

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> GshpPeHeatingSpecs:
        if state.dataHPWaterToWaterHtg.GetWWHPHeatingInput:
            GetGshpInput(state)
            state.dataHPWaterToWaterHtg.GetWWHPHeatingInput = False
        var thisObj: Optional[GshpPeHeatingSpecs] = None
        for i in range(len(state.dataHPWaterToWaterHtg.GSHP)):
            if state.dataHPWaterToWaterHtg.GSHP[i].Name == objectName:
                thisObj = state.dataHPWaterToWaterHtg.GSHP[i]
                break
        if thisObj is not None:
            return thisObj.value()
        ShowFatalError(state, format("WWHPHeatingFactory: Error getting inputs for heat pump named: {}", objectName))
        return GshpPeHeatingSpecs()

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Real64, RunFlag: Bool):
        if calledFromLocation.loopNum == self.LoadPlantLoc.loopNum:
            self.initialize(state)
            self.calculate(state, CurLoad)
            self.update(state)
        elif calledFromLocation.loopNum == self.SourcePlantLoc.loopNum:
            PlantUtilities.UpdateChillerComponentCondenserSide(state,
                                                                self.SourcePlantLoc.loopNum,
                                                                self.SourcePlantLoc.loopSideNum,
                                                                DataPlant.PlantEquipmentType.HPWaterEFHeating,
                                                                self.SourceSideInletNodeNum,
                                                                self.SourceSideOutletNodeNum,
                                                                -self.QSource,
                                                                self.SourceSideWaterInletTemp,
                                                                self.SourceSideWaterOutletTemp,
                                                                self.SourceSideWaterMassFlowRate,
                                                                FirstHVACIteration)
        else:
            ShowFatalError(state, format("SimHPWatertoWaterHEATING:: Invalid loop connection {}, Requested Unit={}", ModuleCompName, self.Name))

    def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, inout MaxLoad: Real64, inout MinLoad: Real64, inout OptLoad: Real64):
        MinLoad = self.NomCap * self.MinPartLoadRat
        MaxLoad = self.NomCap * self.MaxPartLoadRat
        OptLoad = self.NomCap * self.OptPartLoadRat

    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        if self.plantScanFlag:
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state,
                                                    self.Name,
                                                    DataPlant.PlantEquipmentType.HPWaterPEHeating,
                                                    self.SourcePlantLoc,
                                                    errFlag,
                                                    _,
                                                    _,
                                                    _,
                                                    self.SourceSideInletNodeNum,
                                                    _)
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, DataPlant.PlantEquipmentType.HPWaterPEHeating, self.LoadPlantLoc, errFlag, _, _, _, self.LoadSideInletNodeNum, _)
            if errFlag:
                ShowFatalError(state, "InitGshp: Program terminated due to previous condition(s).")
            PlantUtilities.InterConnectTwoPlantLoopSides(state, self.LoadPlantLoc, self.SourcePlantLoc, self.WWHPPlantType, True)
            self.plantScanFlag = False

def GetGshpInput(state: EnergyPlusData):
    var routineName: String = "GetGshpInput"
    var NumAlphas: int
    var NumNums: int
    var IOStat: int
    var AlphArray: Array1D_string = Array1D_string(5)
    var NumArray: Array1D[Real64] = Array1D[Real64](23)
    var ErrorsFound: Bool = False
    state.dataHPWaterToWaterHtg.NumGSHPs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ModuleCompName)
    if state.dataHPWaterToWaterHtg.NumGSHPs <= 0:
        ShowSevereError(state, format("{}: No Equipment found", ModuleCompName))
        ErrorsFound = True
    state.dataHPWaterToWaterHtg.GSHP.allocate(state.dataHPWaterToWaterHtg.NumGSHPs)
    for GSHPNum in range(1, state.dataHPWaterToWaterHtg.NumGSHPs + 1):
        var thisGSHP = state.dataHPWaterToWaterHtg.GSHP[GSHPNum - 1]
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ModuleCompNameUC, GSHPNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, ModuleCompNameUC, AlphArray[0])
        thisGSHP.Name = AlphArray[0]
        thisGSHP.WWHPPlantType = DataPlant.PlantEquipmentType.HPWaterPEHeating
        thisGSHP.COP = NumArray[0]
        if NumArray[0] == 0.0:
            ShowSevereError(state, format("{}:COP = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.NomCap = NumArray[1]
        thisGSHP.MinPartLoadRat = NumArray[2]
        thisGSHP.MaxPartLoadRat = NumArray[3]
        thisGSHP.OptPartLoadRat = NumArray[4]
        thisGSHP.LoadSideVolFlowRate = NumArray[5]
        if NumArray[5] == 0.0:
            ShowSevereError(state, format("{}:Load Side Flow Rate = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.SourceSideVolFlowRate = NumArray[6]
        if NumArray[6] == 0.0:
            ShowSevereError(state, format("{}:Source Side Flow Rate = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.LoadSideUACoeff = NumArray[7]
        if NumArray[7] == 0.0:
            ShowSevereError(state, format("{}:Load Side Heat Transfer Coefficient = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.SourceSideUACoeff = NumArray[8]
        if NumArray[8] == 0.0:
            ShowSevereError(state, format("{}:Source Side Heat Transfer Coefficient = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.CompPistonDisp = NumArray[9]
        if NumArray[9] == 0.0:
            ShowSevereError(state, format("{}:Compressor Piston displacement/Storke = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.CompClearanceFactor = NumArray[10]
        if NumArray[10] == 0.0:
            ShowSevereError(state, format("{}:Compressor Clearance Factor = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.CompSucPressDrop = NumArray[11]
        if NumArray[11] == 0.0:
            ShowSevereError(state, format("{}: Pressure Drop = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.SuperheatTemp = NumArray[12]
        if NumArray[12] == 0.0:
            ShowSevereError(state, format("{}:Source Side SuperHeat = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.PowerLosses = NumArray[13]
        if NumArray[13] == 0.0:
            ShowSevereError(state, format("{}:Compressor Power Loss = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.LossFactor = NumArray[14]
        if NumArray[14] == 0.0:
            ShowSevereError(state, format("{}:Efficiency = 0.0, Heatpump={}", ModuleCompName, thisGSHP.Name))
            ErrorsFound = True
        thisGSHP.HighPressCutoff = NumArray[15]
        if NumArray[15] == 0.0:
            thisGSHP.HighPressCutoff = 500000000.0
        thisGSHP.LowPressCutoff = NumArray[16]
        if NumArray[16] == 0.0:
            thisGSHP.LowPressCutoff = 0.0
        thisGSHP.SourceSideInletNodeNum = GetOnlySingleNode(state,
                                                            AlphArray[1],
                                                            ErrorsFound,
                                                            Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
                                                            thisGSHP.Name,
                                                            Node.FluidType.Water,
                                                            Node.ConnectionType.Inlet,
                                                            Node.CompFluidStream.Primary,
                                                            Node.ObjectIsNotParent)
        thisGSHP.SourceSideOutletNodeNum = GetOnlySingleNode(state,
                                                             AlphArray[2],
                                                             ErrorsFound,
                                                             Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
                                                             thisGSHP.Name,
                                                             Node.FluidType.Water,
                                                             Node.ConnectionType.Outlet,
                                                             Node.CompFluidStream.Primary,
                                                             Node.ObjectIsNotParent)
        thisGSHP.LoadSideInletNodeNum = GetOnlySingleNode(state,
                                                          AlphArray[3],
                                                          ErrorsFound,
                                                          Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
                                                          thisGSHP.Name,
                                                          Node.FluidType.Water,
                                                          Node.ConnectionType.Inlet,
                                                          Node.CompFluidStream.Secondary,
                                                          Node.ObjectIsNotParent)
        thisGSHP.LoadSideOutletNodeNum = GetOnlySingleNode(state,
                                                           AlphArray[4],
                                                           ErrorsFound,
                                                           Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationHeating,
                                                           thisGSHP.Name,
                                                           Node.FluidType.Water,
                                                           Node.ConnectionType.Outlet,
                                                           Node.CompFluidStream.Secondary,
                                                           Node.ObjectIsNotParent)
        Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[1], AlphArray[2], "Condenser Water Nodes")
        Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[3], AlphArray[4], "Hot Water Nodes")
        PlantUtilities.RegisterPlantCompDesignFlow(state, thisGSHP.SourceSideInletNodeNum, 0.5 * thisGSHP.SourceSideVolFlowRate)
        if (thisGSHP.refrig = Fluid.GetRefrig(state, GSHPRefrigerant)) is None:
            ShowSevereItemNotFound(state, eoh, "Refrigerant", GSHPRefrigerant)
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, format("Errors Found in getting {} Input", ModuleCompNameUC))
    for GSHPNum in range(1, state.dataHPWaterToWaterHtg.NumGSHPs + 1):
        var thisGSHP = state.dataHPWaterToWaterHtg.GSHP[GSHPNum - 1]
        SetupOutputVariable(state,
                            "Heat Pump Electricity Rate",
                            Constant.Units.W,
                            thisGSHP.Power,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Electricity Energy",
                            Constant.Units.J,
                            thisGSHP.Energy,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            thisGSHP.Name,
                            Constant.eResource.Electricity,
                            OutputProcessor.Group.Plant,
                            OutputProcessor.EndUseCat.Heating)
        SetupOutputVariable(state,
                            "Heat Pump Load Side Heat Transfer Rate",
                            Constant.Units.W,
                            thisGSHP.QLoad,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Load Side Heat Transfer Energy",
                            Constant.Units.J,
                            thisGSHP.QLoadEnergy,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Source Side Heat Transfer Rate",
                            Constant.Units.W,
                            thisGSHP.QSource,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Source Side Heat Transfer Energy",
                            Constant.Units.J,
                            thisGSHP.QSourceEnergy,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Load Side Outlet Temperature",
                            Constant.Units.C,
                            thisGSHP.LoadSideWaterOutletTemp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Load Side Inlet Temperature",
                            Constant.Units.C,
                            thisGSHP.LoadSideWaterInletTemp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Source Side Outlet Temperature",
                            Constant.Units.C,
                            thisGSHP.SourceSideWaterOutletTemp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Source Side Inlet Temperature",
                            Constant.Units.C,
                            thisGSHP.SourceSideWaterInletTemp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Load Side Mass Flow Rate",
                            Constant.Units.kg_s,
                            thisGSHP.LoadSideWaterMassFlowRate,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)
        SetupOutputVariable(state,
                            "Heat Pump Source Side Mass Flow Rate",
                            Constant.Units.kg_s,
                            thisGSHP.SourceSideWaterMassFlowRate,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            thisGSHP.Name)

def GshpPeHeatingSpecs.initialize(inout self, state: EnergyPlusData):
    var RoutineName: String = "InitGshp"
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
        var rho: Real64 = self.LoadPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
        self.LoadSideDesignMassFlow = self.LoadSideVolFlowRate * rho
        PlantUtilities.InitComponentNodes(state, 0.0, self.LoadSideDesignMassFlow, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum)
        rho = self.SourcePlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
        self.SourceSideDesignMassFlow = self.SourceSideVolFlowRate * rho
        PlantUtilities.InitComponentNodes(state, 0.0, self.SourceSideDesignMassFlow, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum)
        if state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].TempSetPoint == Node.SensedNodeFlagValue:
            state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].TempSetPoint = 0.0
        state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp = state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].TempSetPoint + 30.0
    if not state.dataGlobal.BeginEnvrnFlag:
        self.beginEnvironFlag = True
    self.Running = 0
    self.MustRun = True
    self.LoadSideWaterMassFlowRate = 0.0
    self.SourceSideWaterMassFlowRate = 0.0
    self.Power = 0.0
    self.QLoad = 0.0
    self.QSource = 0.0

def GshpPeHeatingSpecs.calculate(inout self, state: EnergyPlusData, inout MyLoad: Real64):
    var gamma: Real64 = 1.114
    var HeatBalTol: Real64 = 0.0005
    var RelaxParam: Real64 = 0.6
    var SmallNum: Real64 = 1.0e-20
    var IterationLimit: int = 500
    var RoutineName: String = "CalcGshpModel"
    var RoutineNameLoadSideTemp: String = "CalcGSHPModel:LoadSideTemp"
    var RoutineNameSourceSideTemp: String = "CalcGSHPModel:SourceSideTemp"
    var RoutineNameCompressInletTemp: String = "CalcGSHPModel:CompressInletTemp"
    var RoutineNameSuctionPr: String = "CalcGSHPModel:SuctionPr"
    var RoutineNameCompSuctionTemp: String = "CalcGSHPModel:CompSuctionTemp"
    var CompSuctionTemp: Real64
    var CompSuctionEnth: Real64
    var CompSuctionDensity: Real64
    var CompSuctionSatTemp: Real64
    var DutyFactor: Real64
    if MyLoad > 0.0:
        self.MustRun = True
        self.IsOn = True
    else:
        self.MustRun = False
        self.IsOn = False
    self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
    self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
    if not self.MustRun:
        self.LoadSideWaterMassFlowRate = 0.0
        PlantUtilities.SetComponentFlowRate(
            state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
        self.SourceSideWaterMassFlowRate = 0.0
        PlantUtilities.SetComponentFlowRate(
            state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
        PlantUtilities.PullCompInterconnectTrigger(state,
                                                    self.LoadPlantLoc,
                                                    self.CondMassFlowIndex,
                                                    self.SourcePlantLoc,
                                                    DataPlant.CriteriaType.MassFlowRate,
                                                    self.SourceSideWaterMassFlowRate)
        self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
        self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
        return
    self.LoadSideWaterMassFlowRate = self.LoadSideDesignMassFlow
    PlantUtilities.SetComponentFlowRate(
        state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
    self.SourceSideWaterMassFlowRate = self.SourceSideDesignMassFlow
    PlantUtilities.SetComponentFlowRate(
        state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
    if self.LoadSideWaterMassFlowRate < DataBranchAirLoopPlant.MassFlowTolerance or self.SourceSideWaterMassFlowRate < DataBranchAirLoopPlant.MassFlowTolerance:
        self.LoadSideWaterMassFlowRate = 0.0
        PlantUtilities.SetComponentFlowRate(
            state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
        self.SourceSideWaterMassFlowRate = 0.0
        PlantUtilities.SetComponentFlowRate(
            state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
        PlantUtilities.PullCompInterconnectTrigger(state,
                                                    self.LoadPlantLoc,
                                                    self.CondMassFlowIndex,
                                                    self.SourcePlantLoc,
                                                    DataPlant.CriteriaType.MassFlowRate,
                                                    self.SourceSideWaterMassFlowRate)
        self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp
        self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp
        return
    PlantUtilities.PullCompInterconnectTrigger(state,
                                                self.LoadPlantLoc,
                                                self.CondMassFlowIndex,
                                                self.SourcePlantLoc,
                                                DataPlant.CriteriaType.MassFlowRate,
                                                self.SourceSideWaterMassFlowRate)
    var initialQSource: Real64 = 0.0
    var initialQLoad: Real64 = 0.0
    var IterationCount: int = 0
    var CpSourceSide: Real64 = self.SourcePlantLoc.loop.glycol.getSpecificHeat(state, self.SourceSideWaterInletTemp, RoutineName)
    var CpLoadSide: Real64 = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, self.LoadSideWaterInletTemp, RoutineName)
    var SourceSideEffect: Real64 = 1.0 - exp(-self.SourceSideUACoeff / (CpSourceSide * self.SourceSideWaterMassFlowRate))
    var LoadSideEffect: Real64 = 1.0 - exp(-self.LoadSideUACoeff / (CpLoadSide * self.LoadSideWaterMassFlowRate))
    while True:
        IterationCount += 1
        var SourceSideTemp: Real64 = self.SourceSideWaterInletTemp - initialQSource / (SourceSideEffect * CpSourceSide * self.SourceSideWaterMassFlowRate)
        var LoadSideTemp: Real64 = self.LoadSideWaterInletTemp + initialQLoad / (LoadSideEffect * CpLoadSide * self.LoadSideWaterMassFlowRate)
        var SourceSidePressure: Real64 = self.refrig.getSatPressure(state, SourceSideTemp, RoutineNameSourceSideTemp)
        var LoadSidePressure: Real64 = self.refrig.getSatPressure(state, LoadSideTemp, RoutineNameLoadSideTemp)
        if SourceSidePressure < self.LowPressCutoff:
            ShowSevereError(state, format("{}=\"{}\" Heating Source Side Pressure Less than the Design Minimum", ModuleCompName, self.Name))
            ShowContinueError(state,
                              format("Source Side Pressure={:.2f} and user specified Design Minimum Pressure={:.2f}",
                                          SourceSidePressure,
                                          self.LowPressCutoff))
            ShowFatalError(state, "Preceding Conditions cause termination.")
        if LoadSidePressure > self.HighPressCutoff:
            ShowSevereError(state, format("{}=\"{}\" Heating Load Side Pressure greater than the Design Maximum", ModuleCompName, self.Name))
            ShowContinueError(
                state,
                format("Load Side Pressure={:.2f} and user specified Design Maximum Pressure={:.2f}", LoadSidePressure, self.HighPressCutoff))
            ShowFatalError(state, "Preceding Conditions cause termination.")
        var SuctionPr: Real64 = SourceSidePressure - self.CompSucPressDrop
        var DischargePr: Real64 = LoadSidePressure + self.CompSucPressDrop
        if SuctionPr < self.LowPressCutoff:
            ShowSevereError(state, format("{}=\"{}\" Heating Suction Pressure Less than the Design Minimum", ModuleCompName, self.Name))
            ShowContinueError(
                state,
                format("Heating Suction Pressure={:.2f} and user specified Design Minimum Pressure={:.2f}", SuctionPr, self.LowPressCutoff))
            ShowFatalError(state, "Preceding Conditions cause termination.")
        if DischargePr > self.HighPressCutoff:
            ShowSevereError(state, format("{}=\"{}\" Heating Discharge Pressure greater than the Design Maximum", ModuleCompName, self.Name))
            ShowContinueError(state,
                              format("Heating Discharge Pressure={:.2f} and user specified Design Maximum Pressure={:.2f}",
                                          DischargePr,
                                          self.HighPressCutoff))
            ShowFatalError(state, "Preceding Conditions cause termination.")
        var qualOne: Real64 = 1.0
        var SourceSideOutletEnth: Real64 = self.refrig.getSatEnthalpy(state, SourceSideTemp, qualOne, RoutineNameSourceSideTemp)
        var qualZero: Real64 = 0.0
        var LoadSideOutletEnth: Real64 = self.refrig.getSatEnthalpy(state, LoadSideTemp, qualZero, RoutineNameLoadSideTemp)
        var CompressInletTemp: Real64 = SourceSideTemp + self.SuperheatTemp
        var SuperHeatEnth: Real64 = self.refrig.getSupHeatEnthalpy(state, CompressInletTemp, SourceSidePressure, RoutineNameCompressInletTemp)
        CompSuctionSatTemp = self.refrig.getSatTemperature(state, SuctionPr, RoutineNameSuctionPr)
        var T110: Real64 = CompSuctionSatTemp
        var T111: Real64 = CompSuctionSatTemp + 80
        while True:
            CompSuctionTemp = 0.5 * (T110 + T111)
            CompSuctionEnth = self.refrig.getSupHeatEnthalpy(state, CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
            if abs(CompSuctionEnth - SuperHeatEnth) / SuperHeatEnth < 0.0001:
                break
            if CompSuctionEnth < SuperHeatEnth:
                T110 = CompSuctionTemp
            else:
                T111 = CompSuctionTemp
        CompSuctionDensity = self.refrig.getSupHeatDensity(state, CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
        var MassRef: Real64 = self.CompPistonDisp * CompSuctionDensity * (1.0 + self.CompClearanceFactor - self.CompClearanceFactor * pow(DischargePr / SuctionPr, 1.0 / gamma))
        self.QSource = MassRef * (SourceSideOutletEnth - LoadSideOutletEnth)
        self.Power = self.PowerLosses + (MassRef * gamma / (gamma - 1) * SuctionPr / CompSuctionDensity / self.LossFactor * (pow(DischargePr / SuctionPr, (gamma - 1) / gamma) - 1))
        self.QLoad = self.Power + self.QSource
        if abs((self.QLoad - initialQLoad) / (initialQLoad + SmallNum)) < HeatBalTol or IterationCount > IterationLimit:
            if IterationCount > IterationLimit:
                ShowWarningError(state, format("{} did not converge", ModuleCompName))
                ShowContinueErrorTimeStamp(state, "")
                ShowContinueError(state, format("Heatpump Name = {}", self.Name))
                ShowContinueError(
                    state,
                    format("Heat Imbalance (%)             = {:G}", abs(100.0 * (self.QLoad - initialQLoad) / (initialQLoad + SmallNum))))
                ShowContinueError(state, format("Load-side heat transfer rate   = {:G}", self.QLoad))
                ShowContinueError(state, format("Source-side heat transfer rate = {:G}", self.QSource))
                ShowContinueError(state, format("Source-side mass flow rate     = {:G}", self.SourceSideWaterMassFlowRate))
                ShowContinueError(state, format("Load-side mass flow rate       = {:G}", self.LoadSideWaterMassFlowRate))
                ShowContinueError(state, format("Source-side inlet temperature  = {:G}", self.SourceSideWaterInletTemp))
                ShowContinueError(state, format("Load-side inlet temperature    = {:G}", self.LoadSideWaterInletTemp))
            break
        else:
            initialQLoad += RelaxParam * (self.QLoad - initialQLoad)
            initialQSource += RelaxParam * (self.QSource - initialQSource)
    if abs(MyLoad) < self.QLoad:
        DutyFactor = abs(MyLoad) / self.QLoad
        self.QLoad = abs(MyLoad)
        self.Power *= DutyFactor
        self.QSource *= DutyFactor
        self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp + self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
        self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp - self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide)
        return
    self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp + self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
    self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp - self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide)
    self.Running = 1

def GshpPeHeatingSpecs.update(inout self, state: EnergyPlusData):
    if not self.MustRun:
        state.dataLoopNodes.Node[self.SourceSideOutletNodeNum].Temp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
        state.dataLoopNodes.Node[self.LoadSideOutletNodeNum].Temp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
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
        var ReportingConstant: Real64 = state.dataHVACGlobal.TimeStepSysSec
        self.Energy = self.Power * ReportingConstant
        self.QSourceEnergy = QSource * ReportingConstant
        self.QLoadEnergy = QLoad * ReportingConstant

def GshpPeHeatingSpecs.oneTimeInit(inout self, state: EnergyPlusData):

def GshpPeHeatingSpecs.oneTimeInit_new(inout self, state: EnergyPlusData):

struct HeatPumpWaterToWaterHEATINGData:
    var NumGSHPs: int = 0
    var GetWWHPHeatingInput: Bool = True
    var GSHP: Array1D[GshpPeHeatingSpecs]

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumGSHPs = 0
        self.GetWWHPHeatingInput = True
        self.GSHP.deallocate()
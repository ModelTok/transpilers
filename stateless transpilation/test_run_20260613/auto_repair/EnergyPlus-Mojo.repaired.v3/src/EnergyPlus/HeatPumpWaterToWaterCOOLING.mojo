from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.string.functions import to_uppercase
from .Data.BaseData import BaseGlobalStruct
from .DataGlobals import *
from .EnergyPlus import *
from .Plant.DataPlant import *
from .PlantComponent import PlantComponent
from .Data.EnergyPlusData import EnergyPlusData
from BranchNodeConnections import *
from .DataBranchAirLoopPlant import *
from DataHVACGlobals import *
from .DataLoopNode import Node
from FluidProperties import Fluid
from General import *
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import GetOnlySingleNode
from OutputProcessor import SetupOutputVariable, OutputProcessor
from .Plant.PlantLocation import PlantLocation
from PlantUtilities import PlantUtilities
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ShowContinueErrorTimeStamp, ShowWarningError, ShowSevereItemNotFound
from .Constant import Constant
from .ErrorObjectHeader import ErrorObjectHeader
from math import exp, pow, abs, log10, sqrt
from sys import exit

alias Real64 = Float64
alias Real32 = Float32
alias Int64 = Int
alias Int32 = Int32

struct GshpPeCoolingSpecs(PlantComponent):
    var Name: String
    var WWHPPlantTypeOfNum: PlantEquipmentType
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
    var SourceSideInletNodeNum: Int32
    var SourceSideOutletNodeNum: Int32
    var LoadSideInletNodeNum: Int32
    var LoadSideOutletNodeNum: Int32
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
    var CondMassFlowIndex: Int32
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
    var Running: Int32
    var LoadSideWaterMassFlowRate: Real64
    var SourceSideWaterMassFlowRate: Real64
    var plantScanFlag: Bool
    var beginEnvironFlag: Bool

    def __init__(inout self):
        self.Name = String("")
        self.WWHPPlantTypeOfNum = PlantEquipmentType.Invalid
        self.refrig = Pointer[Fluid.RefrigProps]().simplified()
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
        self.SourcePlantLoc = PlantLocation()
        self.LoadPlantLoc = PlantLocation()
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
        self.Running = 0
        self.LoadSideWaterMassFlowRate = 0.0
        self.SourceSideWaterMassFlowRate = 0.0
        self.plantScanFlag = True
        self.beginEnvironFlag = True

    def __del__(owned self):

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> GshpPeCoolingSpecs:
        if state.dataHPWaterToWaterClg.GetWWHPCoolingInput:
            GetGshpInput(state)
            state.dataHPWaterToWaterClg.GetWWHPCoolingInput = False
        var thisObj: Int = -1
        for i in range(len(state.dataHPWaterToWaterClg.GSHP)):
            if state.dataHPWaterToWaterClg.GSHP[i].Name == objectName:
                thisObj = i
                break
        if thisObj != -1:
            return state.dataHPWaterToWaterClg.GSHP[thisObj]
        ShowFatalError(state, "WWHPCoolingFactory: Error getting inputs for heat pump named: " + objectName)  # LCOV_EXCL_LINE
        return GshpPeCoolingSpecs()  # LCOV_EXCL_LINE

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Real64, RunFlag: Bool):
        if calledFromLocation.loopNum == self.LoadPlantLoc.loopNum:  # chilled water loop
            self.initialize(state)
            self.calculate(state, CurLoad)
            self.update(state)
        elif calledFromLocation.loopNum == self.SourcePlantLoc.loopNum:  # condenser loop
            PlantUtilities.UpdateChillerComponentCondenserSide(state,
                                                                self.SourcePlantLoc.loopNum,
                                                                self.SourcePlantLoc.loopSideNum,
                                                                PlantEquipmentType.HPWaterEFCooling,
                                                                self.SourceSideInletNodeNum,
                                                                self.SourceSideOutletNodeNum,
                                                                self.QSource,
                                                                self.SourceSideWaterInletTemp,
                                                                self.SourceSideWaterOutletTemp,
                                                                self.SourceSideWaterMassFlowRate,
                                                                FirstHVACIteration)
        else:
            ShowFatalError(state, "SimHPWatertoWaterCOOLING:: Invalid loop connection " + ModuleCompName + ", Requested Unit=" + self.Name)

    def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, MaxLoad: Real64, MinLoad: Real64, OptLoad: Real64):
        MinLoad = self.NomCap * self.MinPartLoadRat
        MaxLoad = self.NomCap * self.MaxPartLoadRat
        OptLoad = self.NomCap * self.OptPartLoadRat

    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        if self.plantScanFlag:
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state,
                                                    self.Name,
                                                    PlantEquipmentType.HPWaterPECooling,
                                                    self.SourcePlantLoc,
                                                    errFlag,
                                                    '',
                                                    '',
                                                    '',
                                                    self.SourceSideInletNodeNum,
                                                    '')
            PlantUtilities.ScanPlantLoopsForObject(
                state, self.Name, PlantEquipmentType.HPWaterPECooling, self.LoadPlantLoc, errFlag, '', '', '', self.LoadSideInletNodeNum, '')
            if errFlag:
                ShowFatalError(state, "InitGshp: Program terminated due to previous condition(s).")
            PlantUtilities.InterConnectTwoPlantLoopSides(state, self.LoadPlantLoc, self.SourcePlantLoc, self.WWHPPlantTypeOfNum, True)
            self.plantScanFlag = False

    def initialize(inout self, state: EnergyPlusData):
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

    def calculate(inout self, state: EnergyPlusData, MyLoad: Real64):
        var gamma: Real64 = 1.114
        var HeatBalTol: Real64 = 0.0005
        var RelaxParam: Real64 = 0.6
        var SmallNum: Real64 = 1.0e-20
        var IterationLimit: Int32 = 500
        var RoutineName: String = "CalcGshpModel"
        var RoutineNameLoadSideRefridgTemp: String = "CalcGSHPModel:LoadSideRefridgTemp"
        var RoutineNameSourceSideRefridgTemp: String = "CalcGSHPModel:SourceSideRefridgTemp"
        var RoutineNameCompressInletTemp: String = "CalcGSHPModel:CompressInletTemp"
        var RoutineNameSuctionPr: String = "CalcGSHPModel:SuctionPr"
        var RoutineNameCompSuctionTemp: String = "CalcGSHPModel:CompSuctionTemp"
        var SourceSideEffect: Real64
        var LoadSideEffect: Real64
        var SourceSideRefridgTemp: Real64
        var LoadSideRefridgTemp: Real64
        var SourceSidePressure: Real64
        var LoadSidePressure: Real64
        var SuctionPr: Real64
        var DischargePr: Real64
        var CompressInletTemp: Real64
        var MassRef: Real64
        var SourceSideOutletEnth: Real64
        var LoadSideOutletEnth: Real64
        var initialQSource: Real64
        var initialQLoad: Real64
        var qual: Real64
        var SuperHeatEnth: Real64
        var T110: Real64
        var T111: Real64
        var CompSuctionTemp: Real64
        var CompSuctionEnth: Real64
        var CompSuctionDensity: Real64
        var CompSuctionSatTemp: Real64
        var DutyFactor: Real64
        var IterationCount: Int32
        var CpSourceSide: Real64
        var CpLoadSide: Real64
        if MyLoad < 0.0:
            self.MustRun = True
            self.IsOn = True
        else:
            self.MustRun = False
            self.IsOn = False
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
                                                        CriteriaType.MassFlowRate,
                                                        self.SourceSideWaterMassFlowRate)
            self.QLoad = 0.0
            self.QSource = 0.0
            self.Power = 0.0
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            self.LoadSideWaterOutletTemp = LoadSideWaterInletTemp
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.SourceSideWaterOutletTemp = SourceSideWaterInletTemp
            return
        self.LoadSideWaterMassFlowRate = self.LoadSideDesignMassFlow
        PlantUtilities.SetComponentFlowRate(
            state, self.LoadSideWaterMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
        self.SourceSideWaterMassFlowRate = self.SourceSideDesignMassFlow
        PlantUtilities.SetComponentFlowRate(
            state, self.SourceSideWaterMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
        self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
        self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
        if (self.LoadSideWaterMassFlowRate < DataBranchAirLoopPlant.MassFlowTolerance or
            self.SourceSideWaterMassFlowRate < DataBranchAirLoopPlant.MassFlowTolerance):
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
                                                        CriteriaType.MassFlowRate,
                                                        self.SourceSideWaterMassFlowRate)
            self.QLoad = 0.0
            self.QSource = 0.0
            self.Power = 0.0
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp
            self.LoadSideWaterOutletTemp = LoadSideWaterInletTemp
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.SourceSideWaterOutletTemp = SourceSideWaterInletTemp
            return
        PlantUtilities.PullCompInterconnectTrigger(state,
                                                    self.LoadPlantLoc,
                                                    self.CondMassFlowIndex,
                                                    self.SourcePlantLoc,
                                                    CriteriaType.MassFlowRate,
                                                    self.SourceSideWaterMassFlowRate)
        initialQSource = 0.0
        initialQLoad = 0.0
        IterationCount = 0
        CpSourceSide = self.SourcePlantLoc.loop.glycol.getSpecificHeat(state, self.SourceSideWaterInletTemp, RoutineName)
        CpLoadSide = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, self.LoadSideWaterInletTemp, RoutineName)
        LoadSideEffect = 1.0 - exp(-self.LoadSideUACoeff / (CpLoadSide * self.LoadSideWaterMassFlowRate))
        SourceSideEffect = 1.0 - exp(-self.SourceSideUACoeff / (CpSourceSide * self.SourceSideWaterMassFlowRate))
        while True:
            IterationCount += 1
            LoadSideRefridgTemp = self.LoadSideWaterInletTemp - initialQLoad / (LoadSideEffect * CpLoadSide * self.LoadSideWaterMassFlowRate)
            SourceSideRefridgTemp = (
                self.SourceSideWaterInletTemp + initialQSource / (SourceSideEffect * CpSourceSide * self.SourceSideWaterMassFlowRate))
            SourceSidePressure = self.refrig.getSatPressure(state, SourceSideRefridgTemp, RoutineName)
            LoadSidePressure = self.refrig.getSatPressure(state, LoadSideRefridgTemp, RoutineName)
            if SourceSidePressure < self.LowPressCutoff:
                ShowSevereError(state, ModuleCompName + "=\"" + self.Name + "\" Cooling Source Side Pressure Less than the Design Minimum")
                ShowContinueError(state,
                                  "Cooling Source Side Pressure=" + str(SourceSidePressure) + " and user specified Design Minimum Pressure=" + str(self.LowPressCutoff))
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            if LoadSidePressure > self.HighPressCutoff:
                ShowSevereError(state, ModuleCompName + "=\"" + self.Name + "\" Cooling Load Side Pressure greater than the Design Maximum")
                ShowContinueError(state,
                                  "Cooling Load Side Pressure=" + str(LoadSidePressure) + " and user specified Design Maximum Pressure=" + str(self.HighPressCutoff))
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            SuctionPr = LoadSidePressure - self.CompSucPressDrop
            DischargePr = SourceSidePressure + self.CompSucPressDrop
            if SuctionPr < self.LowPressCutoff:
                ShowSevereError(state, ModuleCompName + "=\"" + self.Name + "\" Cooling Suction Pressure Less than the Design Minimum")
                ShowContinueError(
                    state,
                    "Cooling Suction Pressure=" + str(SuctionPr) + " and user specified Design Minimum Pressure=" + str(self.LowPressCutoff))
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            if DischargePr > self.HighPressCutoff:
                ShowSevereError(state, ModuleCompName + "=\"" + self.Name + "\" Cooling Discharge Pressure greater than the Design Maximum")
                ShowContinueError(state,
                                  "Cooling Discharge Pressure=" + str(DischargePr) + " and user specified Design Maximum Pressure=" + str(self.HighPressCutoff))
                ShowContinueErrorTimeStamp(state, "")
                ShowFatalError(state, "Preceding Conditions cause termination.")
            qual = 1.0
            LoadSideOutletEnth = self.refrig.getSatEnthalpy(state, LoadSideRefridgTemp, qual, RoutineNameLoadSideRefridgTemp)
            qual = 0.0
            SourceSideOutletEnth = self.refrig.getSatEnthalpy(state, SourceSideRefridgTemp, qual, RoutineNameSourceSideRefridgTemp)
            CompressInletTemp = LoadSideRefridgTemp + self.SuperheatTemp
            SuperHeatEnth = self.refrig.getSupHeatEnthalpy(state, CompressInletTemp, LoadSidePressure, RoutineNameCompressInletTemp)
            CompSuctionSatTemp = self.refrig.getSatTemperature(state, SuctionPr, RoutineNameSuctionPr)
            T110 = CompSuctionSatTemp
            T111 = CompSuctionSatTemp + 100.0
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
            MassRef = self.CompPistonDisp * CompSuctionDensity * (
                1 + self.CompClearanceFactor - self.CompClearanceFactor * pow(DischargePr / SuctionPr, 1 / gamma))
            self.QLoad = MassRef * (LoadSideOutletEnth - SourceSideOutletEnth)
            self.Power = self.PowerLosses + (MassRef * gamma / (gamma - 1) * SuctionPr / CompSuctionDensity / self.LossFactor *
                                               (pow(DischargePr / SuctionPr, (gamma - 1) / gamma) - 1))
            self.QSource = self.Power + self.QLoad
            if abs((self.QSource - initialQSource) / (initialQSource + SmallNum)) < HeatBalTol or IterationCount > IterationLimit:
                if IterationCount > IterationLimit:
                    ShowWarningError(state, "HeatPump:WaterToWater:ParameterEstimation, Cooling did not converge")
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, "Heatpump Name = " + self.Name)
                    ShowContinueError(state,
                                      "Heat Imbalance (%)             = " + str(abs(100.0 * (self.QSource - initialQSource) / (initialQSource + SmallNum))))
                    ShowContinueError(state, "Load-side heat transfer rate   = " + str(self.QLoad))
                    ShowContinueError(state, "Source-side heat transfer rate = " + str(self.QSource))
                    ShowContinueError(state, "Source-side mass flow rate     = " + str(self.SourceSideWaterMassFlowRate))
                    ShowContinueError(state, "Load-side mass flow rate       = " + str(self.LoadSideWaterMassFlowRate))
                    ShowContinueError(state, "Source-side inlet temperature  = " + str(self.SourceSideWaterInletTemp))
                    ShowContinueError(state, "Load-side inlet temperature    = " + str(self.LoadSideWaterInletTemp))
                break
            else:
                initialQSource += RelaxParam * (self.QSource - initialQSource)
                initialQLoad += RelaxParam * (self.QLoad - initialQLoad)
        if abs(MyLoad) < self.QLoad:
            DutyFactor = abs(MyLoad) / self.QLoad
            self.QLoad = abs(MyLoad)
            self.Power *= DutyFactor
            self.QSource *= DutyFactor
            self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp - self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
            self.SourceSideWaterOutletTemp = (
                self.SourceSideWaterInletTemp + self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide))
            return
        self.LoadSideWaterOutletTemp = self.LoadSideWaterInletTemp - self.QLoad / (self.LoadSideWaterMassFlowRate * CpLoadSide)
        self.SourceSideWaterOutletTemp = self.SourceSideWaterInletTemp + self.QSource / (self.SourceSideWaterMassFlowRate * CpSourceSide)
        self.Running = 1

    def update(inout self, state: EnergyPlusData):
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
            self.SourceSideWaterInletTemp = state.dataLoopNodes.Node[self.SourceSideInletNodeNum].Temp
            self.LoadSideWaterInletTemp = state.dataLoopNodes.Node[self.LoadSideInletNodeNum].Temp

    def oneTimeInit(inout self, state: EnergyPlusData):

    def oneTimeInit_new(inout self, state: EnergyPlusData):

def GetGshpInput(state: EnergyPlusData):
    var routineName: String = "GetGshpInput"
    var GSHPNum: Int32
    var NumAlphas: Int32
    var NumNums: Int32
    var IOStat: Int32
    var AlphArray: Array1D[String] = Array1D[String](5)
    var NumArray: Array1D[Real64] = Array1D[Real64](23)
    var ErrorsFound: Bool = False
    state.dataHPWaterToWaterClg.NumGSHPs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, ModuleCompNameUC)
    if state.dataHPWaterToWaterClg.NumGSHPs <= 0:
        ShowSevereError(state, "No Equipment found in SimGshp")
        ErrorsFound = True
    state.dataHPWaterToWaterClg.GSHP = Array1D[GshpPeCoolingSpecs](state.dataHPWaterToWaterClg.NumGSHPs)
    for GSHPNum in range(1, state.dataHPWaterToWaterClg.NumGSHPs + 1):
        var thisGSHP = state.dataHPWaterToWaterClg.GSHP[GSHPNum - 1]
        state.dataInputProcessing.inputProcessor.getObjectItem(state, ModuleCompNameUC, GSHPNum, AlphArray, NumAlphas, NumArray, NumNums, IOStat)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, ModuleCompNameUC, AlphArray[0])
        thisGSHP.Name = AlphArray[0]
        thisGSHP.WWHPPlantTypeOfNum = PlantEquipmentType.HPWaterPECooling
        thisGSHP.COP = NumArray[0]
        if NumArray[0] == 0.0:
            ShowSevereError(state, ModuleCompName + ":COP = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.NomCap = NumArray[1]
        thisGSHP.MinPartLoadRat = NumArray[2]
        thisGSHP.MaxPartLoadRat = NumArray[3]
        thisGSHP.OptPartLoadRat = NumArray[4]
        thisGSHP.LoadSideVolFlowRate = NumArray[5]
        if NumArray[5] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Load Side Vol Flow Rate = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.SourceSideVolFlowRate = NumArray[6]
        if NumArray[6] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Source Side Vol Flow Rate = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.LoadSideUACoeff = NumArray[7]
        if NumArray[8] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Load Side Heat Transfer Coefficient = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.SourceSideUACoeff = NumArray[8]
        if NumArray[7] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Source Side Heat Transfer Coefficient = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.CompPistonDisp = NumArray[9]
        if NumArray[9] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Compressor Piston displacement/Stroke = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.CompClearanceFactor = NumArray[10]
        if NumArray[10] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Compressor Clearance Factor = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.CompSucPressDrop = NumArray[11]
        if NumArray[11] == 0.0:
            ShowSevereError(state, ModuleCompName + ": Pressure Drop = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.SuperheatTemp = NumArray[12]
        if NumArray[12] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Source Side SuperHeat = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.PowerLosses = NumArray[13]
        if NumArray[13] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Compressor Power Loss = 0.0, Heatpump=" + thisGSHP.Name)
            ErrorsFound = True
        thisGSHP.LossFactor = NumArray[14]
        if NumArray[14] == 0.0:
            ShowSevereError(state, ModuleCompName + ":Efficiency = 0.0, Heatpump=" + thisGSHP.Name)
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
                                                            Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
                                                            thisGSHP.Name,
                                                            Node.FluidType.Water,
                                                            Node.ConnectionType.Inlet,
                                                            Node.CompFluidStream.Primary,
                                                            Node.ObjectIsNotParent)
        thisGSHP.SourceSideOutletNodeNum = GetOnlySingleNode(state,
                                                             AlphArray[2],
                                                             ErrorsFound,
                                                             Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
                                                             thisGSHP.Name,
                                                             Node.FluidType.Water,
                                                             Node.ConnectionType.Outlet,
                                                             Node.CompFluidStream.Primary,
                                                             Node.ObjectIsNotParent)
        thisGSHP.LoadSideInletNodeNum = GetOnlySingleNode(state,
                                                          AlphArray[3],
                                                          ErrorsFound,
                                                          Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
                                                          thisGSHP.Name,
                                                          Node.FluidType.Water,
                                                          Node.ConnectionType.Inlet,
                                                          Node.CompFluidStream.Secondary,
                                                          Node.ObjectIsNotParent)
        thisGSHP.LoadSideOutletNodeNum = GetOnlySingleNode(state,
                                                           AlphArray[4],
                                                           ErrorsFound,
                                                           Node.ConnectionObjectType.HeatPumpWaterToWaterParameterEstimationCooling,
                                                           thisGSHP.Name,
                                                           Node.FluidType.Water,
                                                           Node.ConnectionType.Outlet,
                                                           Node.CompFluidStream.Secondary,
                                                           Node.ObjectIsNotParent)
        Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[1], AlphArray[2], "Condenser Water Nodes")
        Node.TestCompSet(state, ModuleCompNameUC, thisGSHP.Name, AlphArray[3], AlphArray[4], "Chilled Water Nodes")
        PlantUtilities.RegisterPlantCompDesignFlow(state, thisGSHP.SourceSideInletNodeNum, 0.5 * thisGSHP.SourceSideVolFlowRate)
        thisGSHP.QLoad = 0.0
        thisGSHP.QSource = 0.0
        thisGSHP.Power = 0.0
        thisGSHP.LoadSideWaterInletTemp = 0.0
        thisGSHP.SourceSideWaterInletTemp = 0.0
        thisGSHP.LoadSideWaterOutletTemp = 0.0
        thisGSHP.SourceSideWaterOutletTemp = 0.0
        thisGSHP.SourceSideWaterMassFlowRate = 0.0
        thisGSHP.LoadSideWaterMassFlowRate = 0.0
        thisGSHP.IsOn = False
        thisGSHP.MustRun = True
        var refrigPtr: Pointer[Fluid.RefrigProps] = Fluid.GetRefrig(state, GSHPRefrigerant)
        if refrigPtr == Pointer[Fluid.RefrigProps]().simplified():
            ShowSevereItemNotFound(state, eoh, "Refrigerant", GSHPRefrigerant)
            ErrorsFound = True
        else:
            thisGSHP.refrig = refrigPtr
    if ErrorsFound:
        ShowFatalError(state, "Errors Found in getting Gshp input")
    for GSHPNum in range(1, state.dataHPWaterToWaterClg.NumGSHPs + 1):
        var thisGSHP = state.dataHPWaterToWaterClg.GSHP[GSHPNum - 1]
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
                            OutputProcessor.EndUseCat.Cooling)
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

var ModuleCompName: String = "HeatPump:WaterToWater:ParameterEstimation:Cooling"
var ModuleCompNameUC: String = "HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:COOLING"
var GSHPRefrigerant: String = "R22"

struct HeatPumpWaterToWaterCOOLINGData(BaseGlobalStruct):
    var NumGSHPs: Int32
    var GetWWHPCoolingInput: Bool
    var GSHP: Array1D[GshpPeCoolingSpecs]

    def __init__(inout self):
        self.NumGSHPs = 0
        self.GetWWHPCoolingInput = True
        self.GSHP = Array1D[GshpPeCoolingSpecs]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumGSHPs = 0
        self.GetWWHPCoolingInput = True
        self.GSHP.deallocate()
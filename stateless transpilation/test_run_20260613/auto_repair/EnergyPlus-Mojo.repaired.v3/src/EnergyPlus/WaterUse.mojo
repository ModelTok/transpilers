from Array.functions import *
from BranchNodeConnections import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataLoopNode import *
from DataWater import *
from FluidProperties import *
from HeatBalanceInternalHeatGains import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from OutputReportPredefined import *
from DataPlant import *
from PlantUtilities import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from WaterManager import *
from WaterUse import *
from ZoneTempPredictorCorrector import *
from .Data.EnergyPlusData import *

from math import *
from python import Python

# C++ includes translated to Mojo imports as needed

struct HeatRecovHX:
    var Invalid: Int = -1
    var Ideal: Int = 0
    var CounterFlow: Int = 1
    var CrossFlow: Int = 2
    var Num: Int = 3

struct HeatRecovConfig:
    var Invalid: Int = -1
    var Plant: Int = 0
    var Equipment: Int = 1
    var PlantAndEquip: Int = 2
    var Num: Int = 3

struct WaterEquipmentType:
    var Name: String
    var EndUseSubcatName: String
    var Connections: Int = 0
    var PeakVolFlowRate: Float64 = 0.0
    var flowRateFracSched: Optional[Sched.Schedule] = None
    var ColdVolFlowRate: Float64 = 0.0
    var HotVolFlowRate: Float64 = 0.0
    var TotalVolFlowRate: Float64 = 0.0
    var ColdMassFlowRate: Float64 = 0.0
    var HotMassFlowRate: Float64 = 0.0
    var TotalMassFlowRate: Float64 = 0.0
    var DrainMassFlowRate: Float64 = 0.0
    var coldTempSched: Optional[Sched.Schedule] = None
    var hotTempSched: Optional[Sched.Schedule] = None
    var targetTempSched: Optional[Sched.Schedule] = None
    var ColdTemp: Float64 = 0.0
    var HotTemp: Float64 = 0.0
    var TargetTemp: Float64 = 0.0
    var MixedTemp: Float64 = 0.0
    var DrainTemp: Float64 = 0.0
    var CWHWTempErrorCount: Int = 0
    var CWHWTempErrIndex: Int = 0
    var TargetHWTempErrorCount: Int = 0
    var TargetHWTempErrIndex: Int = 0
    var TargetCWTempErrorCount: Int = 0
    var TargetCWTempErrIndex: Int = 0
    var Zone: Int = 0
    var sensibleFracSched: Optional[Sched.Schedule] = None
    var SensibleRate: Float64 = 0.0
    var SensibleEnergy: Float64 = 0.0
    var SensibleRateNoMultiplier: Float64 = 0.0
    var latentFracSched: Optional[Sched.Schedule] = None
    var LatentRate: Float64 = 0.0
    var LatentEnergy: Float64 = 0.0
    var LatentRateNoMultiplier: Float64 = 0.0
    var MoistureRate: Float64 = 0.0
    var MoistureMass: Float64 = 0.0
    var ColdVolume: Float64 = 0.0
    var HotVolume: Float64 = 0.0
    var TotalVolume: Float64 = 0.0
    var Power: Float64 = 0.0
    var Energy: Float64 = 0.0
    var setupMyOutputVars: Bool = True
    var allowHotControl: Bool = False
    def reset(self):
        self.SensibleRate = 0.0
        self.SensibleEnergy = 0.0
        self.LatentRate = 0.0
        self.LatentEnergy = 0.0
        self.MixedTemp = 0.0
        self.TotalMassFlowRate = 0.0
        self.DrainTemp = 0.0
    
    def CalcEquipmentFlowRates(self, inout state: EnergyPlusData):

    def CalcEquipmentDrainTemp(self, inout state: EnergyPlusData):

    def setupOutputVars(self, inout state: EnergyPlusData):

    def FillPredefinedTable(self, inout state: EnergyPlusData):

struct WaterConnectionsType(PlantComponent):
    var Name: String
    var Init: Bool = True
    var StandAlone: Bool = False
    var InletNode: Int = 0
    var OutletNode: Int = 0
    var SupplyTankNum: Int = 0
    var RecoveryTankNum: Int = 0
    var TankDemandID: Int = 0
    var TankSupplyID: Int = 0
    var HeatRecovery: Bool = False
    var HeatRecoveryHX: Int = 0  # HeatRecovHX::Ideal = 0
    var HeatRecoveryConfig: Int = 1  # HeatRecovConfig::Plant = 1
    var HXUA: Float64 = 0.0
    var Effectiveness: Float64 = 0.0
    var RecoveryRate: Float64 = 0.0
    var RecoveryEnergy: Float64 = 0.0
    var TankMassFlowRate: Float64 = 0.0
    var ColdMassFlowRate: Float64 = 0.0
    var HotMassFlowRate: Float64 = 0.0
    var TotalMassFlowRate: Float64 = 0.0
    var DrainMassFlowRate: Float64 = 0.0
    var RecoveryMassFlowRate: Float64 = 0.0
    var PeakVolFlowRate: Float64 = 0.0
    var TankVolFlowRate: Float64 = 0.0
    var ColdVolFlowRate: Float64 = 0.0
    var HotVolFlowRate: Float64 = 0.0
    var TotalVolFlowRate: Float64 = 0.0
    var DrainVolFlowRate: Float64 = 0.0
    var PeakMassFlowRate: Float64 = 0.0
    var coldTempSched: Optional[Sched.Schedule] = None
    var hotTempSched: Optional[Sched.Schedule] = None
    var TankTemp: Float64 = 0.0
    var ColdSupplyTemp: Float64 = 0.0
    var ColdTemp: Float64 = 0.0
    var HotTemp: Float64 = 0.0
    var DrainTemp: Float64 = 0.0
    var RecoveryTemp: Float64 = 0.0
    var ReturnTemp: Float64 = 0.0
    var WasteTemp: Float64 = 0.0
    var TempError: Float64 = 0.0
    var TankVolume: Float64 = 0.0
    var ColdVolume: Float64 = 0.0
    var HotVolume: Float64 = 0.0
    var TotalVolume: Float64 = 0.0
    var Power: Float64 = 0.0
    var Energy: Float64 = 0.0
    var NumWaterEquipment: Int = 0
    var MaxIterationsErrorIndex: Int = 0
    var myWaterEquipArr: Array1D_int
    var plantLoc: PlantLocation = PlantLocation()
    var MyEnvrnFlag: Bool = True
    
    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> Optional[Self]:
        if state.dataWaterUse.getWaterUseInputFlag:
            GetWaterUseInput(state)
            state.dataWaterUse.getWaterUseInputFlag = False
        for thisWC in state.dataWaterUse.WaterConnections:
            if thisWC.Name == objectName:
                return Optional(thisWC)
        ShowFatalError(state, format("LocalWaterUseConnectionFactory: Error getting inputs for object named: {}", objectName))
        return None
    
    def simulate(self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        var MaxIterations: Int = 100
        var Tolerance: Float64 = 0.1
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            if state.dataWaterUse.numWaterEquipment > 0:
                for waterEquipment in state.dataWaterUse.WaterEquipment:
                    waterEquipment.reset()
                    if waterEquipment.setupMyOutputVars:
                        waterEquipment.setupOutputVars(state)
                        waterEquipment.setupMyOutputVars = False
            if state.dataWaterUse.numWaterConnections > 0:
                for waterConnections in state.dataWaterUse.WaterConnections:
                    waterConnections.TotalMassFlowRate = 0.0
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        self.InitConnections(state)
        var NumIteration: Int = 0
        while True:
            NumIteration += 1
            self.CalcConnectionsFlowRates(state, FirstHVACIteration)
            self.CalcConnectionsDrainTemp(state)
            self.CalcConnectionsHeatRecovery(state)
            if self.TempError < Tolerance:
                break
            if NumIteration > MaxIterations:
                if not state.dataGlobal.WarmupFlag:
                    if self.MaxIterationsErrorIndex == 0:
                        ShowWarningError(state, format("WaterUse:Connections = {}:  Heat recovery temperature did not converge", self.Name))
                        ShowContinueErrorTimeStamp(state, "")
                    ShowRecurringWarningErrorAtEnd(state, "WaterUse:Connections = " + self.Name + ":  Heat recovery temperature did not converge", self.MaxIterationsErrorIndex)
                break
        self.UpdateWaterConnections(state)
        self.ReportWaterUse(state)
    
    def InitConnections(self, inout state: EnergyPlusData):
        if self.SupplyTankNum > 0:
            self.ColdSupplyTemp = state.dataWaterData.WaterStorage[self.SupplyTankNum - 1].Twater
        elif self.coldTempSched is not None:
            self.ColdSupplyTemp = self.coldTempSched.getCurrentVal()
        else:
            self.ColdSupplyTemp = state.dataEnvrn.WaterMainsTemp
        self.ColdTemp = self.ColdSupplyTemp
        if self.StandAlone:
            if self.hotTempSched is not None:
                self.HotTemp = self.hotTempSched.getCurrentVal()
            else:
                self.HotTemp = self.ColdTemp
        else:
            if state.dataGlobal.BeginEnvrnFlag and self.Init:
                if self.InletNode > 0 and self.OutletNode > 0:
                    PlantUtilities.InitComponentNodes(state, 0.0, self.PeakMassFlowRate, self.InletNode, self.OutletNode)
                    self.ReturnTemp = state.dataLoopNodes.Node[self.InletNode - 1].Temp
                self.Init = False
            if not state.dataGlobal.BeginEnvrnFlag:
                self.Init = True
            if self.InletNode > 0:
                if not state.dataGlobal.DoingSizing:
                    self.HotTemp = state.dataLoopNodes.Node[self.InletNode - 1].Temp
                else:
                    self.HotTemp = 60.0
    
    def CalcConnectionsFlowRates(self, inout state: EnergyPlusData, FirstHVACIteration: Bool):
        self.ColdMassFlowRate = 0.0
        self.HotMassFlowRate = 0.0
        for Loop in range(self.NumWaterEquipment):
            var thisWEq = state.dataWaterUse.WaterEquipment[self.myWaterEquipArr[Loop] - 1]
            thisWEq.CalcEquipmentFlowRates(state)
            self.ColdMassFlowRate += thisWEq.ColdMassFlowRate
            self.HotMassFlowRate += thisWEq.HotMassFlowRate
        self.TotalMassFlowRate = self.ColdMassFlowRate + self.HotMassFlowRate
        if not self.StandAlone:
            if self.InletNode > 0:
                if FirstHVACIteration:
                    PlantUtilities.SetComponentFlowRate(state, self.HotMassFlowRate, self.InletNode, self.OutletNode, self.plantLoc)
                else:
                    var DesiredHotWaterMassFlow: Float64 = self.HotMassFlowRate
                    PlantUtilities.SetComponentFlowRate(state, DesiredHotWaterMassFlow, self.InletNode, self.OutletNode, self.plantLoc)
                    if (self.HotMassFlowRate != DesiredHotWaterMassFlow) and (self.HotMassFlowRate > 0.0):
                        var AvailableFraction: Float64 = DesiredHotWaterMassFlow / self.HotMassFlowRate
                        self.ColdMassFlowRate = self.TotalMassFlowRate - self.HotMassFlowRate
                        for Loop in range(self.NumWaterEquipment):
                            var thisWEq = state.dataWaterUse.WaterEquipment[self.myWaterEquipArr[Loop] - 1]
                            thisWEq.HotMassFlowRate *= AvailableFraction
                            thisWEq.ColdMassFlowRate = thisWEq.TotalMassFlowRate - thisWEq.HotMassFlowRate
                            if thisWEq.TotalMassFlowRate > 0.0:
                                thisWEq.MixedTemp = (thisWEq.ColdMassFlowRate * thisWEq.ColdTemp + thisWEq.HotMassFlowRate * thisWEq.HotTemp) / thisWEq.TotalMassFlowRate
                            else:
                                thisWEq.MixedTemp = thisWEq.TargetTemp
        if self.SupplyTankNum > 0:
            self.ColdVolFlowRate = self.ColdMassFlowRate / calcH2ODensity(state)
            state.dataWaterData.WaterStorage[self.SupplyTankNum - 1].VdotRequestDemand[self.TankDemandID - 1] = self.ColdVolFlowRate
            self.TankVolFlowRate = state.dataWaterData.WaterStorage[self.SupplyTankNum - 1].VdotAvailDemand[self.TankDemandID - 1]
            self.TankMassFlowRate = self.TankVolFlowRate * calcH2ODensity(state)
    
    def CalcConnectionsDrainTemp(self, inout state: EnergyPlusData):
        var MassFlowTempSum: Float64 = 0.0
        self.DrainMassFlowRate = 0.0
        for Loop in range(self.NumWaterEquipment):
            var thisWEq = state.dataWaterUse.WaterEquipment[self.myWaterEquipArr[Loop] - 1]
            thisWEq.CalcEquipmentDrainTemp(state)
            self.DrainMassFlowRate += thisWEq.DrainMassFlowRate
            MassFlowTempSum += thisWEq.DrainMassFlowRate * thisWEq.DrainTemp
        if self.DrainMassFlowRate > 0.0:
            self.DrainTemp = MassFlowTempSum / self.DrainMassFlowRate
        else:
            self.DrainTemp = self.HotTemp
        self.DrainVolFlowRate = self.DrainMassFlowRate * calcH2ODensity(state)
    
    def CalcConnectionsHeatRecovery(self, inout state: EnergyPlusData):
        if not self.HeatRecovery:
            self.RecoveryTemp = self.ColdSupplyTemp
            self.ReturnTemp = self.ColdSupplyTemp
            self.WasteTemp = self.DrainTemp
        elif self.TotalMassFlowRate == 0.0:
            self.Effectiveness = 0.0
            self.RecoveryRate = 0.0
            self.RecoveryTemp = self.ColdSupplyTemp
            self.ReturnTemp = self.ColdSupplyTemp
            self.WasteTemp = self.DrainTemp
        else:
            if self.HeatRecoveryConfig == HeatRecovConfig.Plant:
                self.RecoveryMassFlowRate = self.HotMassFlowRate
            elif self.HeatRecoveryConfig == HeatRecovConfig.Equipment:
                self.RecoveryMassFlowRate = self.ColdMassFlowRate
            elif self.HeatRecoveryConfig == HeatRecovConfig.PlantAndEquip:
                self.RecoveryMassFlowRate = self.TotalMassFlowRate
            var HXCapacityRate: Float64 = Psychrometrics.CPHW(Constant.InitConvTemp) * self.RecoveryMassFlowRate
            var DrainCapacityRate: Float64 = Psychrometrics.CPHW(Constant.InitConvTemp) * self.DrainMassFlowRate
            var MinCapacityRate: Float64 = min(DrainCapacityRate, HXCapacityRate)
            if self.HeatRecoveryHX == HeatRecovHX.Ideal:
                self.Effectiveness = 1.0
            elif self.HeatRecoveryHX == HeatRecovHX.CounterFlow:
                var CapacityRatio: Float64 = MinCapacityRate / max(DrainCapacityRate, HXCapacityRate)
                var NTU: Float64 = self.HXUA / MinCapacityRate
                if CapacityRatio == 1.0:
                    self.Effectiveness = NTU / (1.0 + NTU)
                else:
                    var ExpVal: Float64 = exp(-NTU * (1.0 - CapacityRatio))
                    self.Effectiveness = (1.0 - ExpVal) / (1.0 - CapacityRatio * ExpVal)
            elif self.HeatRecoveryHX == HeatRecovHX.CrossFlow:
                var CapacityRatio: Float64 = MinCapacityRate / max(DrainCapacityRate, HXCapacityRate)
                var NTU: Float64 = self.HXUA / MinCapacityRate
                self.Effectiveness = 1.0 - exp((pow(NTU, 0.22) / CapacityRatio) * (exp(-CapacityRatio * pow(NTU, 0.78)) - 1.0))
            self.RecoveryRate = self.Effectiveness * MinCapacityRate * (self.DrainTemp - self.ColdSupplyTemp)
            self.RecoveryTemp = self.ColdSupplyTemp + self.RecoveryRate / (Psychrometrics.CPHW(Constant.InitConvTemp) * self.TotalMassFlowRate)
            self.WasteTemp = self.DrainTemp - self.RecoveryRate / (Psychrometrics.CPHW(Constant.InitConvTemp) * self.TotalMassFlowRate)
            if self.RecoveryTankNum > 0:
                state.dataWaterData.WaterStorage[self.RecoveryTankNum - 1].VdotAvailSupply[self.TankSupplyID - 1] = self.DrainVolFlowRate
                state.dataWaterData.WaterStorage[self.RecoveryTankNum - 1].TwaterSupply[self.TankSupplyID - 1] = self.WasteTemp
            if self.HeatRecoveryConfig == HeatRecovConfig.Plant:
                self.TempError = 0.0
                self.ReturnTemp = self.RecoveryTemp
            elif self.HeatRecoveryConfig == HeatRecovConfig.Equipment:
                self.TempError = abs(self.ColdTemp - self.RecoveryTemp)
                self.ColdTemp = self.RecoveryTemp
                self.ReturnTemp = self.ColdSupplyTemp
            elif self.HeatRecoveryConfig == HeatRecovConfig.PlantAndEquip:
                self.TempError = abs(self.ColdTemp - self.RecoveryTemp)
                self.ColdTemp = self.RecoveryTemp
                self.ReturnTemp = self.RecoveryTemp
    
    def UpdateWaterConnections(self, inout state: EnergyPlusData):
        if self.InletNode > 0 and self.OutletNode > 0:
            PlantUtilities.SafeCopyPlantNode(state, self.InletNode, self.OutletNode, self.plantLoc.loopNum)
            state.dataLoopNodes.Node[self.OutletNode - 1].Temp = self.ReturnTemp
    
    def ReportWaterUse(self, inout state: EnergyPlusData):
        for Loop in range(self.NumWaterEquipment):
            var thisWEq = state.dataWaterUse.WaterEquipment[self.myWaterEquipArr[Loop] - 1]
            thisWEq.ColdVolFlowRate = thisWEq.ColdMassFlowRate / calcH2ODensity(state)
            thisWEq.HotVolFlowRate = thisWEq.HotMassFlowRate / calcH2ODensity(state)
            thisWEq.TotalVolFlowRate = thisWEq.ColdVolFlowRate + thisWEq.HotVolFlowRate
            thisWEq.ColdVolume = thisWEq.ColdVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
            thisWEq.HotVolume = thisWEq.HotVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
            thisWEq.TotalVolume = thisWEq.TotalVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
            if thisWEq.Connections == 0:
                thisWEq.Power = thisWEq.HotMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * (thisWEq.HotTemp - thisWEq.ColdTemp)
            else:
                thisWEq.Power = thisWEq.HotMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * (thisWEq.HotTemp - state.dataWaterUse.WaterConnections[thisWEq.Connections - 1].ReturnTemp)
            thisWEq.Energy = thisWEq.Power * state.dataHVACGlobal.TimeStepSysSec
        self.ColdVolFlowRate = self.ColdMassFlowRate / calcH2ODensity(state)
        self.HotVolFlowRate = self.HotMassFlowRate / calcH2ODensity(state)
        self.TotalVolFlowRate = self.ColdVolFlowRate + self.HotVolFlowRate
        self.ColdVolume = self.ColdVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
        self.HotVolume = self.HotVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
        self.TotalVolume = self.TotalVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
        self.Power = self.HotMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * (self.HotTemp - self.ReturnTemp)
        self.Energy = self.Power * state.dataHVACGlobal.TimeStepSysSec
        self.RecoveryEnergy = self.RecoveryRate * state.dataHVACGlobal.TimeStepSysSec
    
    def setupOutputVars(self, inout state: EnergyPlusData):
        SetupOutputVariable(state, "Water Use Connections Hot Water Mass Flow Rate", Constant.Units.kg_s, self.HotMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Cold Water Mass Flow Rate", Constant.Units.kg_s, self.ColdMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Total Mass Flow Rate", Constant.Units.kg_s, self.TotalMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Drain Water Mass Flow Rate", Constant.Units.kg_s, self.DrainMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Heat Recovery Mass Flow Rate", Constant.Units.kg_s, self.RecoveryMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Hot Water Volume Flow Rate", Constant.Units.m3_s, self.HotVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Cold Water Volume Flow Rate", Constant.Units.m3_s, self.ColdVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Total Volume Flow Rate", Constant.Units.m3_s, self.TotalVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Hot Water Volume", Constant.Units.m3, self.HotVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Water Use Connections Cold Water Volume", Constant.Units.m3, self.ColdVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Water Use Connections Total Volume", Constant.Units.m3, self.TotalVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Water Use Connections Hot Water Temperature", Constant.Units.C, self.HotTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Cold Water Temperature", Constant.Units.C, self.ColdTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Drain Water Temperature", Constant.Units.C, self.DrainTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Return Water Temperature", Constant.Units.C, self.ReturnTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Waste Water Temperature", Constant.Units.C, self.WasteTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Heat Recovery Water Temperature", Constant.Units.C, self.RecoveryTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Heat Recovery Effectiveness", Constant.Units.None, self.Effectiveness, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Heat Recovery Rate", Constant.Units.W, self.RecoveryRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Connections Heat Recovery Energy", Constant.Units.J, self.RecoveryEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        if not self.StandAlone:
            SetupOutputVariable(state, "Water Use Connections Plant Hot Water Energy", Constant.Units.J, self.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.PlantLoopHeatingDemand, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.WaterSystem)
    
    def oneTimeInit_new(self, inout state: EnergyPlusData):
        self.setupOutputVars(state)
        if allocated(state.dataPlnt.PlantLoop) and not self.StandAlone:
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.WaterUseConnection, self.plantLoc, errFlag, _, _, _, _, _)
            if errFlag:
                ShowFatalError(state, "InitConnections: Program terminated due to previous condition(s).")
            self.FillPredefinedTable(state)
    
    def oneTimeInit(self, inout state: EnergyPlusData):

    def FillPredefinedTable(self, inout state: EnergyPlusData):
        var orp = state.dataOutRptPredefined
        if self.HeatRecovery:
            if self.HeatRecoveryHX == HeatRecovHX.Ideal:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxType, self.Name, "Ideal")
            elif self.HeatRecoveryHX == HeatRecovHX.CounterFlow:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxType, self.Name, "Counterflow")
            elif self.HeatRecoveryHX == HeatRecovHX.CrossFlow:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxType, self.Name, "Crossflow")
            else:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxType, self.Name, "unknown")
            if self.HeatRecoveryConfig == HeatRecovConfig.Equipment:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxDest, self.Name, "Equipment")
            elif self.HeatRecoveryConfig == HeatRecovConfig.Plant:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxDest, self.Name, "Plant")
            elif self.HeatRecoveryConfig == HeatRecovConfig.PlantAndEquip:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxDest, self.Name, "Plant/Equipment")
            else:
                PreDefTableEntry(state, orp.pdchWtCnDrnHxDest, self.Name, "unknown")
            PreDefTableEntry(state, orp.pdchWtCnDrnHxUA, self.Name, self.HXUA)
        else:
            PreDefTableEntry(state, orp.pdchWtCnDrnHxType, self.Name, "None")
            PreDefTableEntry(state, orp.pdchWtCnDrnHxType, self.Name, "None")
        if self.hotTempSched is not None:
            PreDefTableEntry(state, orp.pdchWtCnHotTempSch, self.Name, self.hotTempSched.Name)
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtCnHotTempMax, self.Name, self.hotTempSched.getMaxVal(state))
        else:
            PreDefTableEntry(state, orp.pdchWtCnHotTempSch, self.Name, "N/A")
        if self.coldTempSched is not None:
            PreDefTableEntry(state, orp.pdchWtCnColdTempSch, self.Name, self.coldTempSched.Name)
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtCnColdTempMin, self.Name, self.coldTempSched.getMinVal(state))
        else:
            PreDefTableEntry(state, orp.pdchWtCnColdTempSch, self.Name, "N/A")
        if self.SupplyTankNum > 0:
            PreDefTableEntry(state, orp.pdchWtCnSupTnk, self.Name, state.dataWaterData.WaterStorage[self.SupplyTankNum - 1].Name)
        if self.RecoveryTankNum > 0:
            PreDefTableEntry(state, orp.pdchWtCnRecTnk, self.Name, state.dataWaterData.WaterStorage[self.RecoveryTankNum - 1].Name)
        for jCn in range(self.NumWaterEquipment):
            var waterEq = self.myWaterEquipArr[jCn]
            if waterEq > 0:
                var thisWEq = state.dataWaterUse.WaterEquipment[waterEq - 1]
                PreDefTableEntry(state, orp.pdchWtEqConnNm, thisWEq.Name, self.Name)
        PreDefTableEntry(state, orp.pdchWtCnPltLpNm, self.Name, self.plantLoc.loop.Name)
        PreDefTableEntry(state, orp.pdchWtCnBrchNm, self.Name, self.plantLoc.branch.Name)

def SimulateWaterUse(state: EnergyPlusData, FirstHVACIteration: Bool):
    var MaxIterations: Int = 100
    var Tolerance: Float64 = 0.1
    if state.dataWaterUse.getWaterUseInputFlag:
        GetWaterUseInput(state)
        state.dataWaterUse.getWaterUseInputFlag = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataWaterUse.MyEnvrnFlagLocal:
        if state.dataWaterUse.numWaterEquipment > 0:
            for e in state.dataWaterUse.WaterEquipment:
                e.SensibleRate = 0.0
                e.SensibleEnergy = 0.0
                e.LatentRate = 0.0
                e.LatentEnergy = 0.0
                e.MixedTemp = 0.0
                e.TotalMassFlowRate = 0.0
                e.DrainTemp = 0.0
        if state.dataWaterUse.numWaterConnections > 0:
            for e in state.dataWaterUse.WaterConnections:
                e.TotalMassFlowRate = 0.0
        state.dataWaterUse.MyEnvrnFlagLocal = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataWaterUse.MyEnvrnFlagLocal = True
    for waterEquipment in state.dataWaterUse.WaterEquipment:
        if waterEquipment.Connections == 0:
            waterEquipment.CalcEquipmentFlowRates(state)
            waterEquipment.CalcEquipmentDrainTemp(state)
    ReportStandAloneWaterUse(state)
    for waterConnection in state.dataWaterUse.WaterConnections:
        if not waterConnection.StandAlone:
            continue
        waterConnection.InitConnections(state)
        var NumIteration: Int = 0
        while True:
            NumIteration += 1
            waterConnection.CalcConnectionsFlowRates(state, FirstHVACIteration)
            waterConnection.CalcConnectionsDrainTemp(state)
            waterConnection.CalcConnectionsHeatRecovery(state)
            if waterConnection.TempError < Tolerance:
                break
            if NumIteration > MaxIterations:
                if not state.dataGlobal.WarmupFlag:
                    if waterConnection.MaxIterationsErrorIndex == 0:
                        ShowWarningError(state, format("WaterUse:Connections = {}:  Heat recovery temperature did not converge", waterConnection.Name))
                        ShowContinueErrorTimeStamp(state, "")
                    ShowRecurringWarningErrorAtEnd(state, "WaterUse:Connections = " + waterConnection.Name + ":  Heat recovery temperature did not converge", waterConnection.MaxIterationsErrorIndex)
                break
        waterConnection.UpdateWaterConnections(state)
        waterConnection.ReportWaterUse(state)

def GetWaterUseInput(state: EnergyPlusData):
    var routineName: String = "GetWaterUseInput"
    var ErrorsFound: Bool = False
    var IOStatus: Int
    var NumAlphas: Int
    var NumNumbers: Int
    var HeatRecoverHXNamesUC: List[String] = List[String]("IDEAL", "COUNTERFLOW", "CROSSFLOW")
    var HeatRecoveryConfigNamesUC: List[String] = List[String]("PLANT", "EQUIPMENT", "PLANTANDEQUIPMENT")
    state.dataIPShortCut.cCurrentModuleObject = "WaterUse:Equipment"
    state.dataWaterUse.numWaterEquipment = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    if state.dataWaterUse.numWaterEquipment > 0:
        state.dataWaterUse.WaterEquipment.allocate(state.dataWaterUse.numWaterEquipment)
        for WaterEquipNum in range(state.dataWaterUse.numWaterEquipment):
            var thisWEq = state.dataWaterUse.WaterEquipment[WaterEquipNum]
            state.dataInputProcessing.inputProcessor.getObjectItem(state, state.dataIPShortCut.cCurrentModuleObject, WaterEquipNum + 1, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNumbers, IOStatus, _, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
            var eoh = ErrorObjectHeader(routineName, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0])
            thisWEq.Name = state.dataIPShortCut.cAlphaArgs[0]
            thisWEq.EndUseSubcatName = state.dataIPShortCut.cAlphaArgs[1]
            thisWEq.PeakVolFlowRate = state.dataIPShortCut.rNumericArgs[0]
            if (NumAlphas <= 2) or (state.dataIPShortCut.lAlphaFieldBlanks[2]):

            else:
                thisWEq.flowRateFracSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[2])
                if thisWEq.flowRateFracSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[2], state.dataIPShortCut.cAlphaArgs[2])
                    ErrorsFound = True
            if (NumAlphas <= 3) or (state.dataIPShortCut.lAlphaFieldBlanks[3]):

            else:
                thisWEq.targetTempSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[3])
                if thisWEq.targetTempSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[3], state.dataIPShortCut.cAlphaArgs[3])
                    ErrorsFound = True
            if (NumAlphas <= 4) or (state.dataIPShortCut.lAlphaFieldBlanks[4]):

            else:
                thisWEq.hotTempSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[4])
                if thisWEq.hotTempSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[4], state.dataIPShortCut.cAlphaArgs[4])
                    ErrorsFound = True
            if (NumAlphas <= 5) or (state.dataIPShortCut.lAlphaFieldBlanks[5]):

            else:
                thisWEq.coldTempSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[5])
                if thisWEq.coldTempSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[5], state.dataIPShortCut.cAlphaArgs[5])
                    ErrorsFound = True
            if (NumAlphas <= 6) or (state.dataIPShortCut.lAlphaFieldBlanks[6]):

            else:
                thisWEq.Zone = Util.FindItemInList(state.dataIPShortCut.cAlphaArgs[6], state.dataHeatBal.Zone)
                if thisWEq.Zone == 0:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[6], state.dataIPShortCut.cAlphaArgs[6])
                    ErrorsFound = True
            if (NumAlphas <= 7) or (state.dataIPShortCut.lAlphaFieldBlanks[7]):

            else:
                thisWEq.sensibleFracSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[7])
                if thisWEq.sensibleFracSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[7], state.dataIPShortCut.cAlphaArgs[7])
                    ErrorsFound = True
            if (NumAlphas <= 8) or (state.dataIPShortCut.lAlphaFieldBlanks[8]):

            else:
                thisWEq.latentFracSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[8])
                if thisWEq.latentFracSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[8], state.dataIPShortCut.cAlphaArgs[8])
                    ErrorsFound = True
        if ErrorsFound:
            ShowFatalError(state, format("Errors found in processing input for {}", state.dataIPShortCut.cCurrentModuleObject))
    state.dataIPShortCut.cCurrentModuleObject = "WaterUse:Connections"
    state.dataWaterUse.numWaterConnections = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    if state.dataWaterUse.numWaterConnections > 0:
        state.dataWaterUse.WaterConnections.allocate(state.dataWaterUse.numWaterConnections)
        for WaterConnNum in range(state.dataWaterUse.numWaterConnections):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, state.dataIPShortCut.cCurrentModuleObject, WaterConnNum + 1, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNumbers, IOStatus, _, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
            var eoh = ErrorObjectHeader(routineName, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0])
            var waterConnection = state.dataWaterUse.WaterConnections[WaterConnNum]
            waterConnection.Name = state.dataIPShortCut.cAlphaArgs[0]
            if (not state.dataIPShortCut.lAlphaFieldBlanks[1]) or (not state.dataIPShortCut.lAlphaFieldBlanks[2]):
                waterConnection.InletNode = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[1], ErrorsFound, Node.ConnectionObjectType.WaterUseConnections, waterConnection.Name, Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                waterConnection.OutletNode = Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[2], ErrorsFound, Node.ConnectionObjectType.WaterUseConnections, waterConnection.Name, Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
                Node.TestCompSet(state, state.dataIPShortCut.cCurrentModuleObject, waterConnection.Name, state.dataIPShortCut.cAlphaArgs[1], state.dataIPShortCut.cAlphaArgs[2], "DHW Nodes")
            else:
                waterConnection.StandAlone = True
            if not state.dataIPShortCut.lAlphaFieldBlanks[3]:
                WaterManager.SetupTankDemandComponent(state, waterConnection.Name, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[3], ErrorsFound, waterConnection.SupplyTankNum, waterConnection.TankDemandID)
            if not state.dataIPShortCut.lAlphaFieldBlanks[4]:
                WaterManager.SetupTankSupplyComponent(state, waterConnection.Name, state.dataIPShortCut.cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[4], ErrorsFound, waterConnection.RecoveryTankNum, waterConnection.TankSupplyID)
            if state.dataIPShortCut.lAlphaFieldBlanks[5]:

            else:
                waterConnection.hotTempSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[5])
                if waterConnection.hotTempSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[5], state.dataIPShortCut.cAlphaArgs[5])
                    ErrorsFound = True
            if state.dataIPShortCut.lAlphaFieldBlanks[6]:

            else:
                waterConnection.coldTempSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[6])
                if waterConnection.coldTempSched is None:
                    ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[6], state.dataIPShortCut.cAlphaArgs[6])
                    ErrorsFound = True
            if (not state.dataIPShortCut.lAlphaFieldBlanks[7]) and (state.dataIPShortCut.cAlphaArgs[7] != "NONE"):
                waterConnection.HeatRecovery = True
                waterConnection.HeatRecoveryHX = getEnumValue(HeatRecoverHXNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[7]))
                if waterConnection.HeatRecoveryHX == HeatRecovHX.Invalid:
                    ShowSevereError(state, format("Invalid {} = {}", state.dataIPShortCut.cAlphaFieldNames[7], state.dataIPShortCut.cAlphaArgs[7]))
                    ShowContinueError(state, format("Entered in {} = {}", state.dataIPShortCut.cCurrentModuleObject, waterConnection.Name))
                    ErrorsFound = True
                waterConnection.HeatRecoveryConfig = getEnumValue(HeatRecoveryConfigNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[8]))
                if waterConnection.HeatRecoveryConfig == HeatRecovConfig.Invalid:
                    ShowSevereError(state, format("Invalid {} = {}", state.dataIPShortCut.cAlphaFieldNames[8], state.dataIPShortCut.cAlphaArgs[8]))
                    ShowContinueError(state, format("Entered in {} = {}", state.dataIPShortCut.cCurrentModuleObject, waterConnection.Name))
                    ErrorsFound = True
            waterConnection.HXUA = state.dataIPShortCut.rNumericArgs[0]
            waterConnection.myWaterEquipArr.allocate(NumAlphas - 9)
            for AlphaNum in range(9, NumAlphas):
                var WaterEquipNum = Util.FindItemInList(state.dataIPShortCut.cAlphaArgs[AlphaNum], state.dataWaterUse.WaterEquipment)
                if WaterEquipNum == 0:
                    ShowSevereError(state, format("Invalid {} = {}", state.dataIPShortCut.cAlphaFieldNames[AlphaNum], state.dataIPShortCut.cAlphaArgs[AlphaNum]))
                    ShowContinueError(state, format("Entered in {} = {}", state.dataIPShortCut.cCurrentModuleObject, waterConnection.Name))
                    ErrorsFound = True
                else:
                    if state.dataWaterUse.WaterEquipment[WaterEquipNum - 1].Connections > 0:
                        ShowSevereError(state, format("{} = {}:  WaterUse:Equipment = {} is already referenced by another object.", state.dataIPShortCut.cCurrentModuleObject, waterConnection.Name, state.dataIPShortCut.cAlphaArgs[AlphaNum]))
                        ErrorsFound = True
                    else:
                        state.dataWaterUse.WaterEquipment[WaterEquipNum - 1].Connections = WaterConnNum + 1
                        waterConnection.NumWaterEquipment += 1
                        waterConnection.myWaterEquipArr[waterConnection.NumWaterEquipment - 1] = WaterEquipNum
                        waterConnection.PeakVolFlowRate += state.dataWaterUse.WaterEquipment[WaterEquipNum - 1].PeakVolFlowRate
        if ErrorsFound:
            ShowFatalError(state, format("Errors found in processing input for {}", state.dataIPShortCut.cCurrentModuleObject))
        if state.dataWaterUse.numWaterConnections > 0:
            state.dataWaterUse.CheckEquipName.allocate(state.dataWaterUse.numWaterConnections)
            state.dataWaterUse.CheckEquipName = True
    if state.dataWaterUse.numWaterConnections > 0:
        for WaterConnNum in range(state.dataWaterUse.numWaterConnections):
            var waterConnection = state.dataWaterUse.WaterConnections[WaterConnNum]
            waterConnection.PeakMassFlowRate = 0.0
            for WaterEquipNum in range(waterConnection.NumWaterEquipment):
                var thisWEq = state.dataWaterUse.WaterEquipment[waterConnection.myWaterEquipArr[WaterEquipNum] - 1]
                if thisWEq.Zone > 0:
                    waterConnection.PeakMassFlowRate += thisWEq.PeakVolFlowRate * calcH2ODensity(state) * state.dataHeatBal.Zone[thisWEq.Zone - 1].Multiplier * state.dataHeatBal.Zone[thisWEq.Zone - 1].ListMultiplier
                else:
                    waterConnection.PeakMassFlowRate += thisWEq.PeakVolFlowRate * calcH2ODensity(state)
            PlantUtilities.RegisterPlantCompDesignFlow(state, waterConnection.InletNode, waterConnection.PeakMassFlowRate / calcH2ODensity(state))
    for waterEquipment in state.dataWaterUse.WaterEquipment:
        waterEquipment.allowHotControl = (waterEquipment.targetTempSched is not None and waterEquipment.hotTempSched is not None) or (waterEquipment.Connections != 0)

def WaterEquipmentType.setupOutputVars(self: WaterEquipmentType, inout state: EnergyPlusData):
    SetupOutputVariable(state, "Water Use Equipment Hot Water Mass Flow Rate", Constant.Units.kg_s, self.HotMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Cold Water Mass Flow Rate", Constant.Units.kg_s, self.ColdMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Total Mass Flow Rate", Constant.Units.kg_s, self.TotalMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Hot Water Volume Flow Rate", Constant.Units.m3_s, self.HotVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Cold Water Volume Flow Rate", Constant.Units.m3_s, self.ColdVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Total Volume Flow Rate", Constant.Units.m3_s, self.TotalVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Hot Water Volume", Constant.Units.m3, self.HotVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Cold Water Volume", Constant.Units.m3, self.ColdVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Total Volume", Constant.Units.m3, self.TotalVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.Water, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.WaterSystem, self.EndUseSubcatName)
    SetupOutputVariable(state, "Water Use Equipment Mains Water Volume", Constant.Units.m3, self.TotalVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.MainsWater, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.WaterSystem, self.EndUseSubcatName)
    SetupOutputVariable(state, "Water Use Equipment Hot Water Temperature", Constant.Units.C, self.HotTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Cold Water Temperature", Constant.Units.C, self.ColdTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Target Water Temperature", Constant.Units.C, self.TargetTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Mixed Water Temperature", Constant.Units.C, self.MixedTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Drain Water Temperature", Constant.Units.C, self.DrainTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    SetupOutputVariable(state, "Water Use Equipment Heating Rate", Constant.Units.W, self.Power, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
    if self.Connections == 0:
        SetupOutputVariable(state, "Water Use Equipment Heating Energy", Constant.Units.J, self.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.DistrictHeatingWater, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.WaterSystem, self.EndUseSubcatName)
    elif state.dataWaterUse.WaterConnections[self.Connections - 1].StandAlone:
        SetupOutputVariable(state, "Water Use Equipment Heating Energy", Constant.Units.J, self.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.DistrictHeatingWater, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.WaterSystem, self.EndUseSubcatName)
    else:
        SetupOutputVariable(state, "Water Use Equipment Heating Energy", Constant.Units.J, self.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.WaterSystem, self.EndUseSubcatName)
    if self.Zone > 0:
        SetupOutputVariable(state, "Water Use Equipment Zone Sensible Heat Gain Rate", Constant.Units.W, self.SensibleRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Equipment Zone Sensible Heat Gain Energy", Constant.Units.J, self.SensibleEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Water Use Equipment Zone Latent Gain Rate", Constant.Units.W, self.LatentRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Equipment Zone Latent Gain Energy", Constant.Units.J, self.LatentEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Water Use Equipment Zone Moisture Gain Mass Flow Rate", Constant.Units.kg_s, self.MoistureRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Water Use Equipment Zone Moisture Gain Mass", Constant.Units.kg, self.MoistureMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupZoneInternalGain(state, self.Zone, self.Name, DataHeatBalance.IntGainType.WaterUseEquipment, self.SensibleRateNoMultiplier, None, None, self.LatentRateNoMultiplier)

def WaterEquipmentType.CalcEquipmentFlowRates(self: WaterEquipmentType, inout state: EnergyPlusData):
    var TempDiff: Float64
    var EPSILON: Float64 = 1.0e-3
    if self.setupMyOutputVars:
        self.setupOutputVars(state)
        self.setupMyOutputVars = False
    if self.Connections > 0:
        self.ColdTemp = state.dataWaterUse.WaterConnections[self.Connections - 1].ColdTemp
        self.HotTemp = state.dataWaterUse.WaterConnections[self.Connections - 1].HotTemp
    else:
        if self.coldTempSched is not None:
            self.ColdTemp = self.coldTempSched.getCurrentVal()
        else:
            self.ColdTemp = state.dataEnvrn.WaterMainsTemp
        if self.hotTempSched is not None:
            self.HotTemp = self.hotTempSched.getCurrentVal()
        else:
            self.HotTemp = self.ColdTemp
    if self.targetTempSched is not None:
        self.TargetTemp = self.targetTempSched.getCurrentVal()
    elif self.allowHotControl:
        self.TargetTemp = self.HotTemp
    else:
        self.TargetTemp = self.ColdTemp
    self.TotalVolFlowRate = self.PeakVolFlowRate
    if self.Zone > 0:
        self.TotalVolFlowRate *= state.dataHeatBal.Zone[self.Zone - 1].Multiplier * state.dataHeatBal.Zone[self.Zone - 1].ListMultiplier
    if self.flowRateFracSched is not None:
        self.TotalVolFlowRate *= self.flowRateFracSched.getCurrentVal()
    self.TotalMassFlowRate = self.TotalVolFlowRate * calcH2ODensity(state)
    if self.TotalMassFlowRate > 0.0 and self.allowHotControl:
        if self.TargetTemp <= self.ColdTemp + EPSILON:
            self.HotMassFlowRate = 0.0
            if not state.dataGlobal.WarmupFlag and self.TargetTemp < self.ColdTemp:
                self.TargetCWTempErrorCount += 1
                TempDiff = self.ColdTemp - self.TargetTemp
                if self.TargetCWTempErrorCount < 2:
                    ShowWarningError(state, format("CalcEquipmentFlowRates: \"{}\" - Target water temperature is less than the cold water temperature by ({:.2R} C)", self.Name, TempDiff))
                    ShowContinueErrorTimeStamp(state, "")
                    ShowContinueError(state, format("...target water temperature     = {:.2R} C", self.TargetTemp))
                    ShowContinueError(state, format("...cold water temperature       = {:.2R} C", self.ColdTemp))
                    ShowContinueError(state, "...Target water temperature should be greater than or equal to the cold water temperature. Verify temperature setpoints and schedules.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, format("\"{}\" - Target water temperature should be greater than or equal to the cold water temperature error continues...", self.Name), self.TargetCWTempErrIndex, TempDiff, TempDiff)
        elif self.TargetTemp >= self.HotTemp:
            self.HotMassFlowRate = self.TotalMassFlowRate
            if not state.dataGlobal.WarmupFlag:
                if self.ColdTemp > (self.HotTemp + EPSILON):
                    self.CWHWTempErrorCount += 1
                    TempDiff = self.ColdTemp - self.HotTemp
                    if self.CWHWTempErrorCount < 2:
                        ShowWarningError(state, format("CalcEquipmentFlowRates: \"{}\" - Hot water temperature is less than the cold water temperature by ({:.2R} C)", self.Name, TempDiff))
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, format("...hot water temperature        = {:.2R} C", self.HotTemp))
                        ShowContinueError(state, format("...cold water temperature       = {:.2R} C", self.ColdTemp))
                        ShowContinueError(state, "...Hot water temperature should be greater than or equal to the cold water temperature. Verify temperature setpoints and schedules.")
                    else:
                        ShowRecurringWarningErrorAtEnd(state, format("\"{}\" - Hot water temperature should be greater than the cold water temperature error continues... ", self.Name), self.CWHWTempErrIndex, TempDiff, TempDiff)
                elif self.TargetTemp > self.HotTemp:
                    TempDiff = self.TargetTemp - self.HotTemp
                    self.TargetHWTempErrorCount += 1
                    if self.TargetHWTempErrorCount < 2:
                        ShowWarningError(state, format("CalcEquipmentFlowRates: \"{}\" - Target water temperature is greater than the hot water temperature by ({:.2R} C)", self.Name, TempDiff))
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, format("...target water temperature     = {:.2R} C", self.TargetTemp))
                        ShowContinueError(state, format("...hot water temperature        = {:.2R} C", self.HotTemp))
                        ShowContinueError(state, "...Target water temperature should be less than or equal to the hot water temperature. Verify temperature setpoints and schedules.")
                    else:
                        ShowRecurringWarningErrorAtEnd(state, format("\"{}\" - Target water temperature should be less than or equal to the hot water temperature error continues...", self.Name), self.TargetHWTempErrIndex, TempDiff, TempDiff)
        else:
            if self.HotTemp <= self.ColdTemp + EPSILON:
                self.HotMassFlowRate = self.TotalMassFlowRate
                if not state.dataGlobal.WarmupFlag and self.HotTemp < self.ColdTemp:
                    self.CWHWTempErrorCount += 1
                    TempDiff = self.ColdTemp - self.HotTemp
                    if self.CWHWTempErrorCount < 2:
                        ShowWarningError(state, format("CalcEquipmentFlowRates: \"{}\" - Hot water temperature is less than the cold water temperature by ({:.2R} C)", self.Name, TempDiff))
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, format("...hot water temperature        = {:.2R} C", self.HotTemp))
                        ShowContinueError(state, format("...cold water temperature       = {:.2R} C", self.ColdTemp))
                        ShowContinueError(state, "...Hot water temperature should be greater than or equal to the cold water temperature. Verify temperature setpoints and schedules.")
                    else:
                        ShowRecurringWarningErrorAtEnd(state, format("\"{}\" - Hot water temperature should be greater than the cold water temperature error continues... ", self.Name), self.CWHWTempErrIndex, TempDiff, TempDiff)
            else:
                self.HotMassFlowRate = self.TotalMassFlowRate * (self.TargetTemp - self.ColdTemp) / (self.HotTemp - self.ColdTemp)
        self.ColdMassFlowRate = self.TotalMassFlowRate - self.HotMassFlowRate
        self.MixedTemp = (self.ColdMassFlowRate * self.ColdTemp + self.HotMassFlowRate * self.HotTemp) / self.TotalMassFlowRate
        assert self.ColdMassFlowRate >= 0.0 and self.ColdMassFlowRate <= self.TotalMassFlowRate
        assert self.HotMassFlowRate >= 0.0 and self.HotMassFlowRate <= self.TotalMassFlowRate
        assert abs(self.HotMassFlowRate + self.ColdMassFlowRate - self.TotalMassFlowRate) < EPSILON
    else:
        self.HotMassFlowRate = 0.0
        self.ColdMassFlowRate = self.TotalMassFlowRate
        self.MixedTemp = self.TargetTemp

def WaterEquipmentType.CalcEquipmentDrainTemp(self: WaterEquipmentType, inout state: EnergyPlusData):
    var RoutineName: String = "CalcEquipmentDrainTemp"
    self.SensibleRate = 0.0
    self.SensibleEnergy = 0.0
    self.LatentRate = 0.0
    self.LatentEnergy = 0.0
    if (self.Zone == 0) or (self.TotalMassFlowRate == 0.0):
        self.DrainTemp = self.MixedTemp
        self.DrainMassFlowRate = self.TotalMassFlowRate
    else:
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.Zone - 1]
        if self.sensibleFracSched is None:
            self.SensibleRate = 0.0
            self.SensibleEnergy = 0.0
        else:
            self.SensibleRate = self.sensibleFracSched.getCurrentVal() * self.TotalMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * (self.MixedTemp - thisZoneHB.MAT)
            self.SensibleEnergy = self.SensibleRate * state.dataHVACGlobal.TimeStepSysSec
        if self.latentFracSched is None:
            self.LatentRate = 0.0
            self.LatentEnergy = 0.0
        else:
            var ZoneHumRat: Float64 = thisZoneHB.airHumRat
            var ZoneHumRatSat: Float64 = Psychrometrics.PsyWFnTdbRhPb(state, thisZoneHB.MAT, 1.0, state.dataEnvrn.OutBaroPress, RoutineName)
            var RhoAirDry: Float64 = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, thisZoneHB.MAT, 0.0)
            var ZoneMassMax: Float64 = (ZoneHumRatSat - ZoneHumRat) * RhoAirDry * state.dataHeatBal.Zone[self.Zone - 1].Volume
            var FlowMassMax: Float64 = self.TotalMassFlowRate * state.dataHVACGlobal.TimeStepSysSec
            var MoistureMassMax: Float64 = min(ZoneMassMax, FlowMassMax)
            self.MoistureMass = self.latentFracSched.getCurrentVal() * MoistureMassMax
            self.MoistureRate = self.MoistureMass / (state.dataHVACGlobal.TimeStepSysSec)
            self.LatentRate = self.MoistureRate * Psychrometrics.PsyHfgAirFnWTdb(ZoneHumRat, thisZoneHB.MAT)
            self.LatentEnergy = self.LatentRate * state.dataHVACGlobal.TimeStepSysSec
        self.DrainMassFlowRate = self.TotalMassFlowRate - self.MoistureRate
        if self.DrainMassFlowRate == 0.0:
            self.DrainTemp = self.MixedTemp
        else:
            self.DrainTemp = (self.TotalMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * self.MixedTemp - self.SensibleRate - self.LatentRate) / (self.DrainMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp))

def WaterEquipmentType.FillPredefinedTable(self: WaterEquipmentType, inout state: EnergyPlusData):
    var orp = state.dataOutRptPredefined
    if self.Zone > 0:
        PreDefTableEntry(state, orp.pdchWtEqZone, self.Name, state.dataHeatBal.Zone[self.Zone - 1].Name)
    PreDefTableEntry(state, orp.pdchWtEqEndUse, self.Name, self.EndUseSubcatName)
    PreDefTableEntry(state, orp.pdchWtEqPkFlw, self.Name, self.PeakVolFlowRate)
    if self.flowRateFracSched is not None:
        PreDefTableEntry(state, orp.pdchWtEqFlwFractSch, self.Name, self.flowRateFracSched.Name)
        OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtEqFlwFractMax, self.Name, self.flowRateFracSched.getMaxVal(state))
    else:
        PreDefTableEntry(state, orp.pdchWtEqFlwFractSch, self.Name, "N/A")
    if self.targetTempSched is not None:
        PreDefTableEntry(state, orp.pdchWtEqTargTempSch, self.Name, self.targetTempSched.Name)
        OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtEqTargTempMax, self.Name, self.targetTempSched.getMaxVal(state))
    else:
        PreDefTableEntry(state, orp.pdchWtEqTargTempSch, self.Name, "N/A")
    if self.hotTempSched is not None:
        PreDefTableEntry(state, orp.pdchWtEqHotTempSch, self.Name, self.hotTempSched.Name)
        OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtEqHotTempMax, self.Name, self.hotTempSched.getMaxVal(state))
    else:
        PreDefTableEntry(state, orp.pdchWtEqHotTempSch, self.Name, "N/A")
    if self.coldTempSched is not None:
        PreDefTableEntry(state, orp.pdchWtEqColdTempSch, self.Name, self.coldTempSched.Name)
        OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtEqColdTempMin, self.Name, self.coldTempSched.getMinVal(state))
    else:
        PreDefTableEntry(state, orp.pdchWtEqColdTempSch, self.Name, "N/A")
    if self.sensibleFracSched is not None:
        PreDefTableEntry(state, orp.pdchWtEqSensFracSch, self.Name, self.sensibleFracSched.Name)
        OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtEqsensFracMax, self.Name, self.sensibleFracSched.getMaxVal(state))
    else:
        PreDefTableEntry(state, orp.pdchWtEqSensFracSch, self.Name, "N/A")
    if self.latentFracSched is not None:
        PreDefTableEntry(state, orp.pdchWtEqLatFracSch, self.Name, self.latentFracSched.Name)
        OutputReportPredefined.PreDefTableEntry(state, orp.pdchWtEqLatFracMax, self.Name, self.latentFracSched.getMaxVal(state))
    else:
        PreDefTableEntry(state, orp.pdchWtEqLatFracSch, self.Name, "N/A")

def ReportStandAloneWaterUse(state: EnergyPlusData):
    for WaterEquipNum in range(state.dataWaterUse.numWaterEquipment):
        var thisWEq = state.dataWaterUse.WaterEquipment[WaterEquipNum]
        thisWEq.ColdVolFlowRate = thisWEq.ColdMassFlowRate / calcH2ODensity(state)
        thisWEq.HotVolFlowRate = thisWEq.HotMassFlowRate / calcH2ODensity(state)
        thisWEq.TotalVolFlowRate = thisWEq.ColdVolFlowRate + thisWEq.HotVolFlowRate
        thisWEq.ColdVolume = thisWEq.ColdVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
        thisWEq.HotVolume = thisWEq.HotVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
        thisWEq.TotalVolume = thisWEq.TotalVolFlowRate * state.dataHVACGlobal.TimeStepSysSec
        if thisWEq.Connections == 0:
            thisWEq.Power = thisWEq.HotMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * (thisWEq.HotTemp - thisWEq.ColdTemp)
        else:
            thisWEq.Power = thisWEq.HotMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * (thisWEq.HotTemp - state.dataWaterUse.WaterConnections[thisWEq.Connections - 1].ReturnTemp)
        thisWEq.Energy = thisWEq.Power * state.dataHVACGlobal.TimeStepSysSec

def CalcWaterUseZoneGains(state: EnergyPlusData):
    var MyEnvrnFlagLocal: Bool = True
    if state.dataWaterUse.numWaterEquipment == 0:
        return
    if state.dataGlobal.BeginEnvrnFlag and MyEnvrnFlagLocal:
        for e in state.dataWaterUse.WaterEquipment:
            e.SensibleRate = 0.0
            e.SensibleEnergy = 0.0
            e.SensibleRateNoMultiplier = 0.0
            e.LatentRate = 0.0
            e.LatentEnergy = 0.0
            e.LatentRateNoMultiplier = 0.0
            e.MixedTemp = 0.0
            e.TotalMassFlowRate = 0.0
            e.DrainTemp = 0.0
            e.ColdVolFlowRate = 0.0
            e.HotVolFlowRate = 0.0
            e.TotalVolFlowRate = 0.0
            e.ColdMassFlowRate = 0.0
            e.HotMassFlowRate = 0.0
        MyEnvrnFlagLocal = False
    if not state.dataGlobal.BeginEnvrnFlag:
        MyEnvrnFlagLocal = True
    for WaterEquipNum in range(state.dataWaterUse.numWaterEquipment):
        if state.dataWaterUse.WaterEquipment[WaterEquipNum].Zone == 0:
            continue
        var ZoneNum = state.dataWaterUse.WaterEquipment[WaterEquipNum].Zone
        state.dataWaterUse.WaterEquipment[WaterEquipNum].SensibleRateNoMultiplier = state.dataWaterUse.WaterEquipment[WaterEquipNum].SensibleRate / (state.dataHeatBal.Zone[ZoneNum - 1].Multiplier * state.dataHeatBal.Zone[ZoneNum - 1].ListMultiplier)
        state.dataWaterUse.WaterEquipment[WaterEquipNum].LatentRateNoMultiplier = state.dataWaterUse.WaterEquipment[WaterEquipNum].LatentRate / (state.dataHeatBal.Zone[ZoneNum - 1].Multiplier * state.dataHeatBal.Zone[ZoneNum - 1].ListMultiplier)

def calcH2ODensity(state: EnergyPlusData) -> Float64:
    var RoutineName: String = "calcH2ODensity"
    if state.dataWaterUse.calcRhoH2O:
        state.dataWaterUse.rhoH2OStd = Fluid.GetWater(state).getDensity(state, Constant.InitConvTemp, RoutineName)
        state.dataWaterUse.calcRhoH2O = False
    return state.dataWaterUse.rhoH2OStd
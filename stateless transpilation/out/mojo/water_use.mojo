from math import exp, pow

alias Float64 = f64
alias Int = i32

enum HeatRecovHX:
    Invalid = -1
    Ideal = 0
    CounterFlow = 1
    CrossFlow = 2
    Num = 3


enum HeatRecovConfig:
    Invalid = -1
    Plant = 0
    Equipment = 1
    PlantAndEquip = 2
    Num = 3


struct WaterEquipmentType:
    var Name: String
    var EndUseSubcatName: String
    var Connections: Int
    var PeakVolFlowRate: Float64
    var flowRateFracSched: UnsafePointer[NoneType]
    var ColdVolFlowRate: Float64
    var HotVolFlowRate: Float64
    var TotalVolFlowRate: Float64
    var ColdMassFlowRate: Float64
    var HotMassFlowRate: Float64
    var TotalMassFlowRate: Float64
    var DrainMassFlowRate: Float64
    var coldTempSched: UnsafePointer[NoneType]
    var hotTempSched: UnsafePointer[NoneType]
    var targetTempSched: UnsafePointer[NoneType]
    var ColdTemp: Float64
    var HotTemp: Float64
    var TargetTemp: Float64
    var MixedTemp: Float64
    var DrainTemp: Float64
    var CWHWTempErrorCount: Int
    var CWHWTempErrIndex: Int
    var TargetHWTempErrorCount: Int
    var TargetHWTempErrIndex: Int
    var TargetCWTempErrorCount: Int
    var TargetCWTempErrIndex: Int
    var Zone: Int
    var sensibleFracSched: UnsafePointer[NoneType]
    var SensibleRate: Float64
    var SensibleEnergy: Float64
    var SensibleRateNoMultiplier: Float64
    var latentFracSched: UnsafePointer[NoneType]
    var LatentRate: Float64
    var LatentEnergy: Float64
    var LatentRateNoMultiplier: Float64
    var MoistureRate: Float64
    var MoistureMass: Float64
    var ColdVolume: Float64
    var HotVolume: Float64
    var TotalVolume: Float64
    var Power: Float64
    var Energy: Float64
    var setupMyOutputVars: Bool
    var allowHotControl: Bool

    fn __init__(inout self):
        self.Name = ""
        self.EndUseSubcatName = ""
        self.Connections = 0
        self.PeakVolFlowRate = 0.0
        self.flowRateFracSched = UnsafePointer[NoneType]()
        self.ColdVolFlowRate = 0.0
        self.HotVolFlowRate = 0.0
        self.TotalVolFlowRate = 0.0
        self.ColdMassFlowRate = 0.0
        self.HotMassFlowRate = 0.0
        self.TotalMassFlowRate = 0.0
        self.DrainMassFlowRate = 0.0
        self.coldTempSched = UnsafePointer[NoneType]()
        self.hotTempSched = UnsafePointer[NoneType]()
        self.targetTempSched = UnsafePointer[NoneType]()
        self.ColdTemp = 0.0
        self.HotTemp = 0.0
        self.TargetTemp = 0.0
        self.MixedTemp = 0.0
        self.DrainTemp = 0.0
        self.CWHWTempErrorCount = 0
        self.CWHWTempErrIndex = 0
        self.TargetHWTempErrorCount = 0
        self.TargetHWTempErrIndex = 0
        self.TargetCWTempErrorCount = 0
        self.TargetCWTempErrIndex = 0
        self.Zone = 0
        self.sensibleFracSched = UnsafePointer[NoneType]()
        self.SensibleRate = 0.0
        self.SensibleEnergy = 0.0
        self.SensibleRateNoMultiplier = 0.0
        self.latentFracSched = UnsafePointer[NoneType]()
        self.LatentRate = 0.0
        self.LatentEnergy = 0.0
        self.LatentRateNoMultiplier = 0.0
        self.MoistureRate = 0.0
        self.MoistureMass = 0.0
        self.ColdVolume = 0.0
        self.HotVolume = 0.0
        self.TotalVolume = 0.0
        self.Power = 0.0
        self.Energy = 0.0
        self.setupMyOutputVars = True
        self.allowHotControl = False

    fn reset(inout self) -> None:
        self.SensibleRate = 0.0
        self.SensibleEnergy = 0.0
        self.LatentRate = 0.0
        self.LatentEnergy = 0.0
        self.MixedTemp = 0.0
        self.TotalMassFlowRate = 0.0
        self.DrainTemp = 0.0

    fn CalcEquipmentFlowRates(inout self, state: UnsafePointer[NoneType]) -> None:
        var EPSILON = 1.0e-3
        var TempDiff: Float64

        if self.setupMyOutputVars:
            self.setupOutputVars(state)
            self.setupMyOutputVars = False

        if self.Connections > 0:
            self.ColdTemp = state.dataWaterUse.WaterEquipment[self.Connections - 1].ColdTemp
            self.HotTemp = state.dataWaterUse.WaterEquipment[self.Connections - 1].HotTemp
        else:
            if self.coldTempSched:
                self.ColdTemp = self.coldTempSched.getCurrentVal()
            else:
                self.ColdTemp = state.dataEnvrn.WaterMainsTemp
            if self.hotTempSched:
                self.HotTemp = self.hotTempSched.getCurrentVal()
            else:
                self.HotTemp = self.ColdTemp

        if self.targetTempSched:
            self.TargetTemp = self.targetTempSched.getCurrentVal()
        elif self.allowHotControl:
            self.TargetTemp = self.HotTemp
        else:
            self.TargetTemp = self.ColdTemp

        self.TotalVolFlowRate = self.PeakVolFlowRate
        if self.Zone > 0:
            self.TotalVolFlowRate *= (
                state.dataHeatBal.Zone[self.Zone - 1].Multiplier *
                state.dataHeatBal.Zone[self.Zone - 1].ListMultiplier
            )
        if self.flowRateFracSched:
            self.TotalVolFlowRate *= self.flowRateFracSched.getCurrentVal()

        self.TotalMassFlowRate = self.TotalVolFlowRate * calcH2ODensity(state)

        if self.TotalMassFlowRate > 0.0 and self.allowHotControl:
            if self.TargetTemp <= self.ColdTemp + EPSILON:
                self.HotMassFlowRate = 0.0
                if not state.dataGlobal.WarmupFlag and self.TargetTemp < self.ColdTemp:
                    self.TargetCWTempErrorCount += 1
                    TempDiff = self.ColdTemp - self.TargetTemp
                    if self.TargetCWTempErrorCount < 2:
                        ShowWarningError(state, "CalcEquipmentFlowRates: \"" + self.Name + "\" - Target water temperature is less than the cold water temperature by (" + TempDiff.__str__() + " C)")
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "...target water temperature     = " + self.TargetTemp.__str__() + " C")
                        ShowContinueError(state, "...cold water temperature       = " + self.ColdTemp.__str__() + " C")
                        ShowContinueError(state, "...Target water temperature should be greater than or equal to the cold water temperature. Verify temperature setpoints and schedules.")
                    else:
                        ShowRecurringWarningErrorAtEnd(state, "\"" + self.Name + "\" - Target water temperature should be greater than or equal to the cold water temperature error continues...", self.TargetCWTempErrIndex, TempDiff, TempDiff)
            elif self.TargetTemp >= self.HotTemp:
                self.HotMassFlowRate = self.TotalMassFlowRate
                if not state.dataGlobal.WarmupFlag:
                    if self.ColdTemp > (self.HotTemp + EPSILON):
                        self.CWHWTempErrorCount += 1
                        TempDiff = self.ColdTemp - self.HotTemp
                        if self.CWHWTempErrorCount < 2:
                            ShowWarningError(state, "CalcEquipmentFlowRates: \"" + self.Name + "\" - Hot water temperature is less than the cold water temperature by (" + TempDiff.__str__() + " C)")
                            ShowContinueErrorTimeStamp(state, "")
                            ShowContinueError(state, "...hot water temperature        = " + self.HotTemp.__str__() + " C")
                            ShowContinueError(state, "...cold water temperature       = " + self.ColdTemp.__str__() + " C")
                            ShowContinueError(state, "...Hot water temperature should be greater than or equal to the cold water temperature. Verify temperature setpoints and schedules.")
                        else:
                            ShowRecurringWarningErrorAtEnd(state, "\"" + self.Name + "\" - Hot water temperature should be greater than the cold water temperature error continues... ", self.CWHWTempErrIndex, TempDiff, TempDiff)
                    elif self.TargetTemp > self.HotTemp:
                        TempDiff = self.TargetTemp - self.HotTemp
                        self.TargetHWTempErrorCount += 1
                        if self.TargetHWTempErrorCount < 2:
                            ShowWarningError(state, "CalcEquipmentFlowRates: \"" + self.Name + "\" - Target water temperature is greater than the hot water temperature by (" + TempDiff.__str__() + " C)")
                            ShowContinueErrorTimeStamp(state, "")
                            ShowContinueError(state, "...target water temperature     = " + self.TargetTemp.__str__() + " C")
                            ShowContinueError(state, "...hot water temperature        = " + self.HotTemp.__str__() + " C")
                            ShowContinueError(state, "...Target water temperature should be less than or equal to the hot water temperature. Verify temperature setpoints and schedules.")
                        else:
                            ShowRecurringWarningErrorAtEnd(state, "\"" + self.Name + "\" - Target water temperature should be less than or equal to the hot water temperature error continues...", self.TargetHWTempErrIndex, TempDiff, TempDiff)
            else:
                if self.HotTemp <= self.ColdTemp + EPSILON:
                    self.HotMassFlowRate = self.TotalMassFlowRate
                    if not state.dataGlobal.WarmupFlag and self.HotTemp < self.ColdTemp:
                        self.CWHWTempErrorCount += 1
                        TempDiff = self.ColdTemp - self.HotTemp
                        if self.CWHWTempErrorCount < 2:
                            ShowWarningError(state, "CalcEquipmentFlowRates: \"" + self.Name + "\" - Hot water temperature is less than the cold water temperature by (" + TempDiff.__str__() + " C)")
                            ShowContinueErrorTimeStamp(state, "")
                            ShowContinueError(state, "...hot water temperature        = " + self.HotTemp.__str__() + " C")
                            ShowContinueError(state, "...cold water temperature       = " + self.ColdTemp.__str__() + " C")
                            ShowContinueError(state, "...Hot water temperature should be greater than or equal to the cold water temperature. Verify temperature setpoints and schedules.")
                        else:
                            ShowRecurringWarningErrorAtEnd(state, "\"" + self.Name + "\" - Hot water temperature should be greater than the cold water temperature error continues... ", self.CWHWTempErrIndex, TempDiff, TempDiff)
                else:
                    self.HotMassFlowRate = self.TotalMassFlowRate * (self.TargetTemp - self.ColdTemp) / (self.HotTemp - self.ColdTemp)

            self.ColdMassFlowRate = self.TotalMassFlowRate - self.HotMassFlowRate
            self.MixedTemp = (self.ColdMassFlowRate * self.ColdTemp + self.HotMassFlowRate * self.HotTemp) / self.TotalMassFlowRate
        else:
            self.HotMassFlowRate = 0.0
            self.ColdMassFlowRate = self.TotalMassFlowRate
            self.MixedTemp = self.TargetTemp

    fn CalcEquipmentDrainTemp(inout self, state: UnsafePointer[NoneType]) -> None:
        self.SensibleRate = 0.0
        self.SensibleEnergy = 0.0
        self.LatentRate = 0.0
        self.LatentEnergy = 0.0

        if self.Zone == 0 or self.TotalMassFlowRate == 0.0:
            self.DrainTemp = self.MixedTemp
            self.DrainMassFlowRate = self.TotalMassFlowRate
        else:
            var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.Zone - 1]

            if not self.sensibleFracSched:
                self.SensibleRate = 0.0
                self.SensibleEnergy = 0.0
            else:
                self.SensibleRate = (
                    self.sensibleFracSched.getCurrentVal() *
                    self.TotalMassFlowRate *
                    Psychrometrics.CPHW(Constant.InitConvTemp) *
                    (self.MixedTemp - thisZoneHB.MAT)
                )
                self.SensibleEnergy = self.SensibleRate * state.dataHVACGlobal.TimeStepSysSec

            if not self.latentFracSched:
                self.LatentRate = 0.0
                self.LatentEnergy = 0.0
            else:
                var ZoneHumRat = thisZoneHB.airHumRat
                var ZoneHumRatSat = Psychrometrics.PsyWFnTdbRhPb(state, thisZoneHB.MAT, 1.0, state.dataEnvrn.OutBaroPress, "CalcEquipmentDrainTemp")
                var RhoAirDry = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, thisZoneHB.MAT, 0.0)
                var ZoneMassMax = (ZoneHumRatSat - ZoneHumRat) * RhoAirDry * state.dataHeatBal.Zone[self.Zone - 1].Volume
                var FlowMassMax = self.TotalMassFlowRate * state.dataHVACGlobal.TimeStepSysSec
                var MoistureMassMax = min(ZoneMassMax, FlowMassMax)

                self.MoistureMass = self.latentFracSched.getCurrentVal() * MoistureMassMax
                self.MoistureRate = self.MoistureMass / state.dataHVACGlobal.TimeStepSysSec
                self.LatentRate = self.MoistureRate * Psychrometrics.PsyHfgAirFnWTdb(ZoneHumRat, thisZoneHB.MAT)
                self.LatentEnergy = self.LatentRate * state.dataHVACGlobal.TimeStepSysSec

            self.DrainMassFlowRate = self.TotalMassFlowRate - self.MoistureRate

            if self.DrainMassFlowRate == 0.0:
                self.DrainTemp = self.MixedTemp
            else:
                self.DrainTemp = ((self.TotalMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp) * self.MixedTemp - self.SensibleRate - self.LatentRate) / (self.DrainMassFlowRate * Psychrometrics.CPHW(Constant.InitConvTemp)))

    fn setupOutputVars(inout self, state: UnsafePointer[NoneType]) -> None:
        pass

    fn FillPredefinedTable(inout self, state: UnsafePointer[NoneType]) -> None:
        pass


struct WaterConnectionsType:
    var Name: String
    var Init: Bool
    var StandAlone: Bool
    var InletNode: Int
    var OutletNode: Int
    var SupplyTankNum: Int
    var RecoveryTankNum: Int
    var TankDemandID: Int
    var TankSupplyID: Int
    var HeatRecovery: Bool
    var HeatRecoveryHX: HeatRecovHX
    var HeatRecoveryConfig: HeatRecovConfig
    var HXUA: Float64
    var Effectiveness: Float64
    var RecoveryRate: Float64
    var RecoveryEnergy: Float64
    var TankMassFlowRate: Float64
    var ColdMassFlowRate: Float64
    var HotMassFlowRate: Float64
    var TotalMassFlowRate: Float64
    var DrainMassFlowRate: Float64
    var RecoveryMassFlowRate: Float64
    var PeakVolFlowRate: Float64
    var TankVolFlowRate: Float64
    var ColdVolFlowRate: Float64
    var HotVolFlowRate: Float64
    var TotalVolFlowRate: Float64
    var DrainVolFlowRate: Float64
    var PeakMassFlowRate: Float64
    var coldTempSched: UnsafePointer[NoneType]
    var hotTempSched: UnsafePointer[NoneType]
    var TankTemp: Float64
    var ColdSupplyTemp: Float64
    var ColdTemp: Float64
    var HotTemp: Float64
    var DrainTemp: Float64
    var RecoveryTemp: Float64
    var ReturnTemp: Float64
    var WasteTemp: Float64
    var TempError: Float64
    var TankVolume: Float64
    var ColdVolume: Float64
    var HotVolume: Float64
    var TotalVolume: Float64
    var Power: Float64
    var Energy: Float64
    var NumWaterEquipment: Int
    var MaxIterationsErrorIndex: Int
    var myWaterEquipArr: DynamicVector[Int]
    var plantLoc: UnsafePointer[NoneType]
    var MyEnvrnFlag: Bool

    fn __init__(inout self):
        self.Name = ""
        self.Init = True
        self.StandAlone = False
        self.InletNode = 0
        self.OutletNode = 0
        self.SupplyTankNum = 0
        self.RecoveryTankNum = 0
        self.TankDemandID = 0
        self.TankSupplyID = 0
        self.HeatRecovery = False
        self.HeatRecoveryHX = HeatRecovHX.Ideal
        self.HeatRecoveryConfig = HeatRecovConfig.Plant
        self.HXUA = 0.0
        self.Effectiveness = 0.0
        self.RecoveryRate = 0.0
        self.RecoveryEnergy = 0.0
        self.TankMassFlowRate = 0.0
        self.ColdMassFlowRate = 0.0
        self.HotMassFlowRate = 0.0
        self.TotalMassFlowRate = 0.0
        self.DrainMassFlowRate = 0.0
        self.RecoveryMassFlowRate = 0.0
        self.PeakVolFlowRate = 0.0
        self.TankVolFlowRate = 0.0
        self.ColdVolFlowRate = 0.0
        self.HotVolFlowRate = 0.0
        self.TotalVolFlowRate = 0.0
        self.DrainVolFlowRate = 0.0
        self.PeakMassFlowRate = 0.0
        self.coldTempSched = UnsafePointer[NoneType]()
        self.hotTempSched = UnsafePointer[NoneType]()
        self.TankTemp = 0.0
        self.ColdSupplyTemp = 0.0
        self.ColdTemp = 0.0
        self.HotTemp = 0.0
        self.DrainTemp = 0.0
        self.RecoveryTemp = 0.0
        self.ReturnTemp = 0.0
        self.WasteTemp = 0.0
        self.TempError = 0.0
        self.TankVolume = 0.0
        self.ColdVolume = 0.0
        self.HotVolume = 0.0
        self.TotalVolume = 0.0
        self.Power = 0.0
        self.Energy = 0.0
        self.NumWaterEquipment = 0
        self.MaxIterationsErrorIndex = 0
        self.myWaterEquipArr = DynamicVector[Int]()
        self.plantLoc = UnsafePointer[NoneType]()
        self.MyEnvrnFlag = True

    fn simulate(inout self, state: UnsafePointer[NoneType], calledFromLocation: UnsafePointer[NoneType], FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool) -> None:
        var MaxIterations = 100
        var Tolerance = 0.1

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            if state.dataWaterUse.numWaterEquipment > 0:
                for i in range(state.dataWaterUse.numWaterEquipment):
                    state.dataWaterUse.WaterEquipment[i].reset()
                    if state.dataWaterUse.WaterEquipment[i].setupMyOutputVars:
                        state.dataWaterUse.WaterEquipment[i].setupOutputVars(state)
                        state.dataWaterUse.WaterEquipment[i].setupMyOutputVars = False

            if state.dataWaterUse.numWaterConnections > 0:
                for i in range(state.dataWaterUse.numWaterConnections):
                    state.dataWaterUse.WaterConnections[i].TotalMassFlowRate = 0.0

            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        self.InitConnections(state)

        var NumIteration = 0
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
                        ShowWarningError(state, "WaterUse:Connections = " + self.Name + ":  Heat recovery temperature did not converge")
                        ShowContinueErrorTimeStamp(state, "")
                    ShowRecurringWarningErrorAtEnd(state, "WaterUse:Connections = " + self.Name + ":  Heat recovery temperature did not converge", self.MaxIterationsErrorIndex)
                break

        self.UpdateWaterConnections(state)
        self.ReportWaterUse(state)

    fn InitConnections(inout self, state: UnsafePointer[NoneType]) -> None:
        if self.SupplyTankNum > 0:
            self.ColdSupplyTemp = state.dataWaterData.WaterStorage[self.SupplyTankNum - 1].Twater
        elif self.coldTempSched:
            self.ColdSupplyTemp = self.coldTempSched.getCurrentVal()
        else:
            self.ColdSupplyTemp = state.dataEnvrn.WaterMainsTemp

        self.ColdTemp = self.ColdSupplyTemp

        if self.StandAlone:
            if self.hotTempSched:
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

    fn CalcConnectionsFlowRates(inout self, state: UnsafePointer[NoneType], FirstHVACIteration: Bool) -> None:
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
                    var DesiredHotWaterMassFlow = self.HotMassFlowRate
                    PlantUtilities.SetComponentFlowRate(state, DesiredHotWaterMassFlow, self.InletNode, self.OutletNode, self.plantLoc)
                    if self.HotMassFlowRate != DesiredHotWaterMassFlow and self.HotMassFlowRate > 0.0:
                        var AvailableFraction = DesiredHotWaterMassFlow / self.HotMassFlowRate
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

    fn CalcConnectionsDrainTemp(inout self, state: UnsafePointer[NoneType]) -> None:
        var MassFlowTempSum = 0.0
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

        self.DrainVolFlowRate = self.DrainMassFlowRate / calcH2ODensity(state)

    fn CalcConnectionsHeatRecovery(inout self, state: UnsafePointer[NoneType]) -> None:
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

            var HXCapacityRate = Psychrometrics.CPHW(Constant.InitConvTemp) * self.RecoveryMassFlowRate
            var DrainCapacityRate = Psychrometrics.CPHW(Constant.InitConvTemp) * self.DrainMassFlowRate
            var MinCapacityRate = min(DrainCapacityRate, HXCapacityRate)

            if self.HeatRecoveryHX == HeatRecovHX.Ideal:
                self.Effectiveness = 1.0
            elif self.HeatRecoveryHX == HeatRecovHX.CounterFlow:
                var CapacityRatio = MinCapacityRate / max(DrainCapacityRate, HXCapacityRate)
                var NTU = self.HXUA / MinCapacityRate
                if CapacityRatio == 1.0:
                    self.Effectiveness = NTU / (1.0 + NTU)
                else:
                    var ExpVal = exp(-NTU * (1.0 - CapacityRatio))
                    self.Effectiveness = (1.0 - ExpVal) / (1.0 - CapacityRatio * ExpVal)
            elif self.HeatRecoveryHX == HeatRecovHX.CrossFlow:
                var CapacityRatio = MinCapacityRate / max(DrainCapacityRate, HXCapacityRate)
                var NTU = self.HXUA / MinCapacityRate
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

    fn UpdateWaterConnections(inout self, state: UnsafePointer[NoneType]) -> None:
        if self.InletNode > 0 and self.OutletNode > 0:
            PlantUtilities.SafeCopyPlantNode(state, self.InletNode, self.OutletNode, self.plantLoc.loopNum)
            state.dataLoopNodes.Node[self.OutletNode - 1].Temp = self.ReturnTemp

    fn ReportWaterUse(inout self, state: UnsafePointer[NoneType]) -> None:
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

    fn setupOutputVars(inout self, state: UnsafePointer[NoneType]) -> None:
        pass

    fn oneTimeInit(inout self, state: UnsafePointer[NoneType]) -> None:
        pass

    fn oneTimeInit_new(inout self, state: UnsafePointer[NoneType]) -> None:
        self.setupOutputVars(state)
        if state.dataPlnt and state.dataPlnt.PlantLoop and not self.StandAlone:
            var errFlag = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.WaterUseConnection, self.plantLoc, errFlag)
            if errFlag:
                ShowFatalError(state, "InitConnections: Program terminated due to previous condition(s).")
            self.FillPredefinedTable(state)

    fn FillPredefinedTable(inout self, state: UnsafePointer[NoneType]) -> None:
        pass


fn SimulateWaterUse(state: UnsafePointer[NoneType], FirstHVACIteration: Bool) -> None:
    var MaxIterations = 100
    var Tolerance = 0.1

    if state.dataWaterUse.getWaterUseInputFlag:
        GetWaterUseInput(state)
        state.dataWaterUse.getWaterUseInputFlag = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataWaterUse.MyEnvrnFlagLocal:
        if state.dataWaterUse.numWaterEquipment > 0:
            for i in range(state.dataWaterUse.numWaterEquipment):
                state.dataWaterUse.WaterEquipment[i].SensibleRate = 0.0
                state.dataWaterUse.WaterEquipment[i].SensibleEnergy = 0.0
                state.dataWaterUse.WaterEquipment[i].LatentRate = 0.0
                state.dataWaterUse.WaterEquipment[i].LatentEnergy = 0.0
                state.dataWaterUse.WaterEquipment[i].MixedTemp = 0.0
                state.dataWaterUse.WaterEquipment[i].TotalMassFlowRate = 0.0
                state.dataWaterUse.WaterEquipment[i].DrainTemp = 0.0

        if state.dataWaterUse.numWaterConnections > 0:
            for i in range(state.dataWaterUse.numWaterConnections):
                state.dataWaterUse.WaterConnections[i].TotalMassFlowRate = 0.0

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
        var NumIteration = 0

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
                        ShowWarningError(state, "WaterUse:Connections = " + waterConnection.Name + ":  Heat recovery temperature did not converge")
                        ShowContinueErrorTimeStamp(state, "")
                    ShowRecurringWarningErrorAtEnd(state, "WaterUse:Connections = " + waterConnection.Name + ":  Heat recovery temperature did not converge", waterConnection.MaxIterationsErrorIndex)
                break

        waterConnection.UpdateWaterConnections(state)
        waterConnection.ReportWaterUse(state)


fn GetWaterUseInput(state: UnsafePointer[NoneType]) -> None:
    pass


fn ReportStandAloneWaterUse(state: UnsafePointer[NoneType]) -> None:
    for i in range(state.dataWaterUse.numWaterEquipment):
        var thisWEq = state.dataWaterUse.WaterEquipment[i]
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


fn CalcWaterUseZoneGains(state: UnsafePointer[NoneType]) -> None:
    if state.dataWaterUse.numWaterEquipment == 0:
        return

    for i in range(state.dataWaterUse.numWaterEquipment):
        var waterEquipment = state.dataWaterUse.WaterEquipment[i]
        if waterEquipment.Zone == 0:
            continue
        var ZoneNum = waterEquipment.Zone
        waterEquipment.SensibleRateNoMultiplier = waterEquipment.SensibleRate / (state.dataHeatBal.Zone[ZoneNum - 1].Multiplier * state.dataHeatBal.Zone[ZoneNum - 1].ListMultiplier)
        waterEquipment.LatentRateNoMultiplier = waterEquipment.LatentRate / (state.dataHeatBal.Zone[ZoneNum - 1].Multiplier * state.dataHeatBal.Zone[ZoneNum - 1].ListMultiplier)


fn calcH2ODensity(state: UnsafePointer[NoneType]) -> Float64:
    if state.dataWaterUse.calcRhoH2O:
        state.dataWaterUse.rhoH2OStd = Fluid.GetWater(state).getDensity(state, Constant.InitConvTemp, "calcH2ODensity")
        state.dataWaterUse.calcRhoH2O = False
    return state.dataWaterUse.rhoH2OStd


struct Constant:
    @staticmethod
    fn InitConvTemp() -> Float64:
        return 20.0

    struct Units:
        var kg_s: String
        var m3_s: String
        var m3: String
        var C: String
        var W: String
        var J: String

    struct eResource:
        var Water: String
        var MainsWater: String
        var DistrictHeatingWater: String
        var EnergyTransfer: String
        var PlantLoopHeatingDemand: String

    struct EndUseCat:
        var WaterSystem: String


struct OutputProcessor:
    struct TimeStepType:
        var System: String

    struct StoreType:
        var Average: String
        var Sum: String

    struct Group:
        var Plant: String


struct Psychrometrics:
    @staticmethod
    fn CPHW(T: Float64) -> Float64:
        return 4180.0

    @staticmethod
    fn PsyWFnTdbRhPb(state: UnsafePointer[NoneType], T: Float64, RH: Float64, P: Float64, routine: String) -> Float64:
        return 0.0

    @staticmethod
    fn PsyRhoAirFnPbTdbW(state: UnsafePointer[NoneType], P: Float64, T: Float64, W: Float64) -> Float64:
        return 1.2

    @staticmethod
    fn PsyHfgAirFnWTdb(W: Float64, T: Float64) -> Float64:
        return 2450000.0


struct Fluid:
    @staticmethod
    fn GetWater(state: UnsafePointer[NoneType]) -> UnsafePointer[NoneType]:
        pass


struct PlantUtilities:
    @staticmethod
    fn SetComponentFlowRate(state: UnsafePointer[NoneType], flow: Float64, inlet: Int, outlet: Int, loc: UnsafePointer[NoneType]) -> None:
        pass

    @staticmethod
    fn RegisterPlantCompDesignFlow(state: UnsafePointer[NoneType], node: Int, flow: Float64) -> None:
        pass

    @staticmethod
    fn InitComponentNodes(state: UnsafePointer[NoneType], minFlow: Float64, maxFlow: Float64, inlet: Int, outlet: Int) -> None:
        pass

    @staticmethod
    fn SafeCopyPlantNode(state: UnsafePointer[NoneType], inlet: Int, outlet: Int, loop: Int) -> None:
        pass

    @staticmethod
    fn ScanPlantLoopsForObject(state: UnsafePointer[NoneType], name: String, type: String, loc: UnsafePointer[NoneType], inout errFlag: Bool) -> None:
        pass


struct DataPlant:
    struct PlantEquipmentType:
        var WaterUseConnection: String


fn ShowWarningError(state: UnsafePointer[NoneType], message: String) -> None:
    pass


fn ShowFatalError(state: UnsafePointer[NoneType], message: String) -> None:
    pass


fn ShowContinueError(state: UnsafePointer[NoneType], message: String) -> None:
    pass


fn ShowContinueErrorTimeStamp(state: UnsafePointer[NoneType], message: String) -> None:
    pass


fn ShowRecurringWarningErrorAtEnd(state: UnsafePointer[NoneType], message: String, inout index: Int, val1: Float64 = 0.0, val2: Float64 = 0.0) -> None:
    pass


fn SetupOutputVariable(state: UnsafePointer[NoneType], args: VariadicList) -> None:
    pass

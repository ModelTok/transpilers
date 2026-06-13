from math import exp, fabs
from collections import InlineArray

struct EvapLoss:
    alias Invalid = -1
    alias ByUserFactor = 0
    alias ByMoistTheory = 1
    alias Num = 2

struct Blowdown:
    alias Invalid = -1
    alias ByConcentration = 0
    alias BySchedule = 1
    alias Num = 2

struct PIM:
    alias StandardDesignCapacity = 0
    alias UFactor = 1
    alias UserSpecifiedDesignCapacity = 2

struct CapacityControl:
    alias Invalid = -1
    alias FanCycling = 0
    alias FluidBypass = 1
    alias Num = 2

@dataclass
struct EvapFluidCoolerInletConds:
    var WaterTemp: Float64 = 0.0
    var AirTemp: Float64 = 0.0
    var AirWetBulb: Float64 = 0.0
    var AirPress: Float64 = 0.0
    var AirHumRat: Float64 = 0.0

@dataclass
struct PlantLocation:
    var loop: AnyType = None
    var side: AnyType = None
    var branch: AnyType = None

@dataclass
struct EvapFluidCoolerSpecs:
    var Name: String = ""
    var EvapFluidCoolerType: String = ""
    var Type: AnyType = None
    var PerformanceInputMethod: String = ""
    var PerformanceInputMethod_Num: Int32 = PIM.StandardDesignCapacity
    var Available: Bool = True
    var ON: Bool = True
    var DesignWaterFlowRate: Float64 = 0.0
    var DesignSprayWaterFlowRate: Float64 = 0.0
    var DesWaterMassFlowRate: Float64 = 0.0
    var HighSpeedAirFlowRate: Float64 = 0.0
    var HighSpeedFanPower: Float64 = 0.0
    var HighSpeedEvapFluidCoolerUA: Float64 = 0.0
    var LowSpeedAirFlowRate: Float64 = 0.0
    var LowSpeedAirFlowRateSizingFactor: Float64 = 0.0
    var LowSpeedFanPower: Float64 = 0.0
    var LowSpeedFanPowerSizingFactor: Float64 = 0.0
    var LowSpeedEvapFluidCoolerUA: Float64 = 0.0
    var DesignWaterFlowRateWasAutoSized: Bool = False
    var HighSpeedAirFlowRateWasAutoSized: Bool = False
    var HighSpeedFanPowerWasAutoSized: Bool = False
    var HighSpeedEvapFluidCoolerUAWasAutoSized: Bool = False
    var LowSpeedAirFlowRateWasAutoSized: Bool = False
    var LowSpeedFanPowerWasAutoSized: Bool = False
    var LowSpeedEvapFluidCoolerUAWasAutoSized: Bool = False
    var LowSpeedEvapFluidCoolerUASizingFactor: Float64 = 0.0
    var DesignEnteringWaterTemp: Float64 = 0.0
    var DesignEnteringWaterTempWasAutoSized: Bool = False
    var DesignExitWaterTemp: Float64 = -999.0
    var DesignEnteringAirTemp: Float64 = 0.0
    var DesignEnteringAirWetBulbTemp: Float64 = 0.0
    var EvapFluidCoolerMassFlowRateMultiplier: Float64 = 0.0
    var HeatRejectCapNomCapSizingRatio: Float64 = 0.0
    var HighSpeedStandardDesignCapacity: Float64 = 0.0
    var LowSpeedStandardDesignCapacity: Float64 = 0.0
    var HighSpeedUserSpecifiedDesignCapacity: Float64 = 0.0
    var LowSpeedUserSpecifiedDesignCapacity: Float64 = 0.0
    var Concentration: Float64 = 0.0
    var glycol: AnyType = None
    var SizFac: Float64 = 0.0
    var WaterInletNodeNum: Int32 = 0
    var WaterOutletNodeNum: Int32 = 0
    var OutdoorAirInletNodeNum: Int32 = 0
    var HighMassFlowErrorCount: Int32 = 0
    var HighMassFlowErrorIndex: Int32 = 0
    var OutletWaterTempErrorCount: Int32 = 0
    var OutletWaterTempErrorIndex: Int32 = 0
    var SmallWaterMassFlowErrorCount: Int32 = 0
    var SmallWaterMassFlowErrorIndex: Int32 = 0
    var capacityControl: Int32 = CapacityControl.Invalid
    var BypassFraction: Float64 = 0.0
    var EvapLossMode: Int32 = EvapLoss.ByMoistTheory
    var BlowdownMode: Int32 = Blowdown.ByConcentration
    var blowdownSched: AnyType = None
    var WaterTankID: Int32 = 0
    var WaterTankDemandARRID: Int32 = 0
    var UserEvapLossFactor: Float64 = 0.0
    var DriftLossFraction: Float64 = 0.0
    var ConcentrationRatio: Float64 = 0.0
    var SuppliedByWaterSystem: Bool = False
    var plantLoc: PlantLocation = PlantLocation()
    var InletWaterTemp: Float64 = 0.0
    var OutletWaterTemp: Float64 = 0.0
    var WaterInletNode: Int32 = 0
    var WaterOutletNode: Int32 = 0
    var WaterMassFlowRate: Float64 = 0.0
    var Qactual: Float64 = 0.0
    var FanPower: Float64 = 0.0
    var AirFlowRateRatio: Float64 = 0.0
    var WaterUsage: Float64 = 0.0
    var MyOneTimeFlag: Bool = True
    var MyEnvrnFlag: Bool = True
    var OneTimeFlagForEachEvapFluidCooler: Bool = True
    var CheckEquipName: Bool = True
    var fluidCoolerInletWaterTemp: Float64 = 0.0
    var fluidCoolerOutletWaterTemp: Float64 = 0.0
    var FanEnergy: Float64 = 0.0
    var WaterAmountUsed: Float64 = 0.0
    var EvaporationVdot: Float64 = 0.0
    var EvaporationVol: Float64 = 0.0
    var DriftVdot: Float64 = 0.0
    var DriftVol: Float64 = 0.0
    var BlowdownVdot: Float64 = 0.0
    var BlowdownVol: Float64 = 0.0
    var MakeUpVdot: Float64 = 0.0
    var MakeUpVol: Float64 = 0.0
    var TankSupplyVdot: Float64 = 0.0
    var TankSupplyVol: Float64 = 0.0
    var StarvedMakeUpVdot: Float64 = 0.0
    var StarvedMakeUpVol: Float64 = 0.0
    var inletConds: EvapFluidCoolerInletConds = EvapFluidCoolerInletConds()

    @staticmethod
    fn factory(state: AnyType, objectType: AnyType, objectName: String) -> EvapFluidCoolerSpecs:
        if state.dataEvapFluidCoolers.GetEvapFluidCoolerInputFlag:
            GetEvapFluidCoolerInput(state)
            state.dataEvapFluidCoolers.GetEvapFluidCoolerInputFlag = False
        
        for thisObj in state.dataEvapFluidCoolers.SimpleEvapFluidCooler:
            if thisObj.Type == objectType and thisObj.Name == objectName:
                return thisObj
        
        raise Error(String("LocalEvapFluidCoolerFactory: Error getting inputs for object named: ") + objectName)

    fn setupOutputVars(inout self, state: AnyType) -> None:
        if self.Type == state.dataPlnt.PlantEquipmentType.EvapFluidCooler_SingleSpd:
            SetupOutputVariable(state, "Cooling Tower Bypass Fraction", self.BypassFraction, self.Name)
        
        if self.SuppliedByWaterSystem:
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume Flow Rate", self.MakeUpVdot, self.Name)
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume", self.MakeUpVol, self.Name)
            SetupOutputVariable(state, "Cooling Tower Storage Tank Water Volume Flow Rate", self.TankSupplyVdot, self.Name)
            SetupOutputVariable(state, "Cooling Tower Storage Tank Water Volume", self.TankSupplyVol, self.Name)
            SetupOutputVariable(state, "Cooling Tower Starved Storage Tank Water Volume Flow Rate", self.StarvedMakeUpVdot, self.Name)
            SetupOutputVariable(state, "Cooling Tower Starved Storage Tank Water Volume", self.StarvedMakeUpVol, self.Name)
            SetupOutputVariable(state, "Cooling Tower Make Up Mains Water Volume", self.StarvedMakeUpVol, self.Name)
        else:
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume Flow Rate", self.MakeUpVdot, self.Name)
            SetupOutputVariable(state, "Cooling Tower Make Up Water Volume", self.MakeUpVol, self.Name)
            SetupOutputVariable(state, "Cooling Tower Make Up Mains Water Volume", self.MakeUpVol, self.Name)
        
        SetupOutputVariable(state, "Cooling Tower Inlet Temperature", self.fluidCoolerInletWaterTemp, self.Name)
        SetupOutputVariable(state, "Cooling Tower Outlet Temperature", self.fluidCoolerOutletWaterTemp, self.Name)
        SetupOutputVariable(state, "Cooling Tower Mass Flow Rate", self.WaterMassFlowRate, self.Name)
        SetupOutputVariable(state, "Cooling Tower Heat Transfer Rate", self.Qactual, self.Name)
        SetupOutputVariable(state, "Cooling Tower Fan Electricity Rate", self.FanPower, self.Name)
        SetupOutputVariable(state, "Cooling Tower Fan Electricity Energy", self.FanEnergy, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Evaporation Volume Flow Rate", self.EvaporationVdot, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Evaporation Volume", self.EvaporationVol, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Drift Volume Flow Rate", self.DriftVdot, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Drift Volume", self.DriftVol, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Blowdown Volume Flow Rate", self.BlowdownVdot, self.Name)
        SetupOutputVariable(state, "Cooling Tower Water Blowdown Volume", self.BlowdownVol, self.Name)

    fn getSizingFactor(self) -> Float64:
        return self.SizFac

    fn onInitLoopEquip(inout self, state: AnyType) -> None:
        self.InitEvapFluidCooler(state)
        self.SizeEvapFluidCooler(state)

    fn getDesignCapacities(self, state: AnyType) -> (Float64, Float64, Float64):
        if self.Type == state.dataPlnt.PlantEquipmentType.EvapFluidCooler_SingleSpd or \
           self.Type == state.dataPlnt.PlantEquipmentType.EvapFluidCooler_TwoSpd:
            var MinLoad: Float64 = 0.0
            var MaxLoad: Float64 = self.HighSpeedStandardDesignCapacity * self.HeatRejectCapNomCapSizingRatio
            var OptLoad: Float64 = self.HighSpeedStandardDesignCapacity
            return MaxLoad, MinLoad, OptLoad
        else:
            raise Error("SimEvapFluidCoolers: Invalid evaporative fluid cooler Type Requested")

    fn simulate(inout self, state: AnyType, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> None:
        self.AirFlowRateRatio = 0.0
        self.InitEvapFluidCooler(state)
        
        if self.Type == state.dataPlnt.PlantEquipmentType.EvapFluidCooler_SingleSpd:
            self.CalcSingleSpeedEvapFluidCooler(state)
        elif self.Type == state.dataPlnt.PlantEquipmentType.EvapFluidCooler_TwoSpd:
            self.CalcTwoSpeedEvapFluidCooler(state)
        else:
            raise Error("SimEvapFluidCoolers: Invalid evaporative fluid cooler Type Requested")
        
        self.CalculateWaterUsage(state)
        self.UpdateEvapFluidCooler(state)
        self.ReportEvapFluidCooler(state, RunFlag)

    fn InitEvapFluidCooler(inout self, state: AnyType) -> None:
        self.oneTimeInit(state)
        
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            var rho: Float64 = self.plantLoc.loop.glycol.getDensity(state)
            self.DesWaterMassFlowRate = self.DesignWaterFlowRate * rho
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesWaterMassFlowRate,
                                             self.WaterInletNodeNum, self.WaterOutletNodeNum)
            self.MyEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        
        self.WaterInletNode = self.WaterInletNodeNum
        self.inletConds.WaterTemp = state.dataLoopNodes.Node(self.WaterInletNode).Temp
        
        if self.OutdoorAirInletNodeNum != 0:
            self.inletConds.AirTemp = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).Temp
            self.inletConds.AirHumRat = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).HumRat
            self.inletConds.AirPress = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).Press
            self.inletConds.AirWetBulb = state.dataLoopNodes.Node(self.OutdoorAirInletNodeNum).OutAirWetBulb
        else:
            self.inletConds.AirTemp = state.dataEnvrn.OutDryBulbTemp
            self.inletConds.AirHumRat = state.dataEnvrn.OutHumRat
            self.inletConds.AirPress = state.dataEnvrn.OutBaroPress
            self.inletConds.AirWetBulb = state.dataEnvrn.OutWetBulbTemp
        
        self.WaterMassFlowRate = PlantUtilities.RegulateCondenserCompFlowReqOp(
            state, self.plantLoc, self.DesWaterMassFlowRate * self.EvapFluidCoolerMassFlowRateMultiplier)
        
        PlantUtilities.SetComponentFlowRate(state, self.WaterMassFlowRate,
                                           self.WaterInletNodeNum, self.WaterOutletNodeNum, self.plantLoc)

    fn SizeEvapFluidCooler(inout self, state: AnyType) -> None:
        var tmpDesignWaterFlowRate: Float64 = self.DesignWaterFlowRate
        var tmpHighSpeedFanPower: Float64 = self.HighSpeedFanPower
        var tmpHighSpeedAirFlowRate: Float64 = self.HighSpeedAirFlowRate
        
        var PltSizCondNum: Int32 = self.plantLoc.loop.PlantSizNum
        if PltSizCondNum > 0:
            self.DesignExitWaterTemp = state.dataSize.PlantSizData(PltSizCondNum).ExitTemp
        
        if self.LowSpeedAirFlowRateWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedAirFlowRate = self.LowSpeedAirFlowRateSizingFactor * self.HighSpeedAirFlowRate
        
        if self.LowSpeedFanPowerWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedFanPower = self.LowSpeedFanPowerSizingFactor * self.HighSpeedFanPower
        
        if self.LowSpeedEvapFluidCoolerUAWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.LowSpeedEvapFluidCoolerUA = self.LowSpeedEvapFluidCoolerUASizingFactor * self.HighSpeedEvapFluidCoolerUA

    fn CalcSingleSpeedEvapFluidCooler(inout self, state: AnyType) -> None:
        var MaxIteration: Int32 = 100
        var BypassFractionThreshold: Float64 = 0.01
        var OWTLowerLimit: Float64 = 0.0
        
        self.WaterInletNode = self.WaterInletNodeNum
        self.WaterOutletNode = self.WaterOutletNodeNum
        self.Qactual = 0.0
        self.FanPower = 0.0
        var inletWaterTemp: Float64 = state.dataLoopNodes.Node(self.WaterInletNode).Temp
        self.OutletWaterTemp = inletWaterTemp
        var AirFlowRate: Float64 = 0.0
        var TempSetPoint: Float64 = 0.0
        
        var calcScheme = self.plantLoc.loop.LoopDemandCalcScheme
        if calcScheme == state.dataPlnt.LoopDemandCalcScheme.SingleSetPoint:
            TempSetPoint = self.plantLoc.side.TempSetPoint
        elif calcScheme == state.dataPlnt.LoopDemandCalcScheme.DualSetPointDeadBand:
            TempSetPoint = self.plantLoc.side.TempSetPointHi
        
        var BypassFlag: Int32 = 0
        self.BypassFraction = 0.0
        
        if self.WaterMassFlowRate <= 0.0 or self.plantLoc.side.FlowLock == state.dataPlnt.FlowLock.Unlocked:
            return
        
        if inletWaterTemp > TempSetPoint:
            var UAdesign: Float64 = self.HighSpeedEvapFluidCoolerUA
            AirFlowRate = self.HighSpeedAirFlowRate
            var FanPowerOn: Float64 = self.HighSpeedFanPower
            
            self.SimSimpleEvapFluidCooler(state, self.WaterMassFlowRate, AirFlowRate, UAdesign)
            
            if self.OutletWaterTemp <= TempSetPoint:
                if self.capacityControl == CapacityControl.FanCycling or self.OutletWaterTemp <= OWTLowerLimit:
                    var FanModeFrac: Float64 = (TempSetPoint - inletWaterTemp) / (self.OutletWaterTemp - inletWaterTemp)
                    self.FanPower = FanModeFrac * FanPowerOn
                    self.OutletWaterTemp = TempSetPoint
                else:
                    self.FanPower = FanPowerOn
                    BypassFlag = 1
            else:
                self.FanPower = FanPowerOn
        else:
            if self.capacityControl == CapacityControl.FluidBypass:
                if inletWaterTemp > OWTLowerLimit:
                    self.FanPower = 0.0
                    self.BypassFraction = 1.0
                    self.OutletWaterTemp = inletWaterTemp
        
        if BypassFlag == 1:
            var bypassFraction: Float64 = (TempSetPoint - self.OutletWaterTemp) / (inletWaterTemp - self.OutletWaterTemp)
            if bypassFraction > 1.0 or bypassFraction < 0.0:
                self.BypassFraction = 0.0
                AirFlowRate = 0.0
            else:
                var NumIteration: Int32 = 0
                var BypassFraction2: Float64 = 0.0
                var BypassFractionPrev: Float64 = bypassFraction
                var OutletWaterTempPrev: Float64 = self.OutletWaterTemp
                var UAdesign: Float64 = self.HighSpeedEvapFluidCoolerUA
                
                while NumIteration < MaxIteration:
                    NumIteration += 1
                    self.SimSimpleEvapFluidCooler(state, self.WaterMassFlowRate * (1.0 - bypassFraction),
                                                 AirFlowRate, UAdesign)
                    if fabs(self.OutletWaterTemp - OWTLowerLimit) <= 0.01:
                        BypassFraction2 = bypassFraction
                        break
                    if self.OutletWaterTemp < OWTLowerLimit:
                        BypassFraction2 = BypassFractionPrev - (BypassFractionPrev - bypassFraction) * \
                                         (OutletWaterTempPrev - OWTLowerLimit) / (OutletWaterTempPrev - self.OutletWaterTemp)
                        self.SimSimpleEvapFluidCooler(state, self.WaterMassFlowRate * (1.0 - BypassFraction2),
                                                     AirFlowRate, UAdesign)
                        if self.OutletWaterTemp < OWTLowerLimit:
                            BypassFraction2 = BypassFractionPrev
                            self.OutletWaterTemp = OutletWaterTempPrev
                        break
                    BypassFraction2 = (TempSetPoint - self.OutletWaterTemp) / (inletWaterTemp - self.OutletWaterTemp)
                    
                    if fabs(BypassFraction2 - bypassFraction) <= BypassFractionThreshold:
                        break
                    BypassFractionPrev = bypassFraction
                    OutletWaterTempPrev = self.OutletWaterTemp
                    bypassFraction = BypassFraction2
                
                self.BypassFraction = BypassFraction2
                self.OutletWaterTemp = (1.0 - BypassFraction2) * self.OutletWaterTemp + BypassFraction2 * inletWaterTemp
        
        var CpWater: Float64 = self.plantLoc.loop.glycol.getSpecificHeat(state,
                                                           state.dataLoopNodes.Node(self.WaterInletNode).Temp)
        self.Qactual = self.WaterMassFlowRate * CpWater * (state.dataLoopNodes.Node(self.WaterInletNode).Temp - self.OutletWaterTemp)
        if self.HighSpeedAirFlowRate > 0.0:
            self.AirFlowRateRatio = AirFlowRate / self.HighSpeedAirFlowRate
        else:
            self.AirFlowRateRatio = 0.0

    fn CalcTwoSpeedEvapFluidCooler(inout self, state: AnyType) -> None:
        self.WaterInletNode = self.WaterInletNodeNum
        self.WaterOutletNode = self.WaterOutletNodeNum
        self.Qactual = 0.0
        self.FanPower = 0.0
        self.InletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNode).Temp
        self.OutletWaterTemp = self.InletWaterTemp
        
        var OutletWaterTemp1stStage: Float64 = self.OutletWaterTemp
        var OutletWaterTemp2ndStage: Float64 = self.OutletWaterTemp
        var AirFlowRate: Float64 = 0.0
        var TempSetPoint: Float64 = 0.0
        
        var calcScheme = self.plantLoc.loop.LoopDemandCalcScheme
        if calcScheme == state.dataPlnt.LoopDemandCalcScheme.SingleSetPoint:
            TempSetPoint = self.plantLoc.side.TempSetPoint
        elif calcScheme == state.dataPlnt.LoopDemandCalcScheme.DualSetPointDeadBand:
            TempSetPoint = self.plantLoc.side.TempSetPointHi
        
        if self.WaterMassFlowRate <= 0.0 or self.plantLoc.side.FlowLock == state.dataPlnt.FlowLock.Unlocked:
            return
        
        if self.InletWaterTemp > TempSetPoint:
            var UAdesign: Float64 = self.LowSpeedEvapFluidCoolerUA
            AirFlowRate = self.LowSpeedAirFlowRate
            var FanPowerLow: Float64 = self.LowSpeedFanPower
            
            self.SimSimpleEvapFluidCooler(state, self.WaterMassFlowRate, AirFlowRate, UAdesign)
            OutletWaterTemp1stStage = self.OutletWaterTemp
            
            if OutletWaterTemp1stStage <= TempSetPoint:
                var FanModeFrac: Float64 = (TempSetPoint - self.InletWaterTemp) / (OutletWaterTemp1stStage - self.InletWaterTemp)
                self.FanPower = FanModeFrac * FanPowerLow
                self.OutletWaterTemp = TempSetPoint
                self.Qactual *= FanModeFrac
            else:
                UAdesign = self.HighSpeedEvapFluidCoolerUA
                AirFlowRate = self.HighSpeedAirFlowRate
                var FanPowerHigh: Float64 = self.HighSpeedFanPower
                
                self.SimSimpleEvapFluidCooler(state, self.WaterMassFlowRate, AirFlowRate, UAdesign)
                OutletWaterTemp2ndStage = self.OutletWaterTemp
                
                if OutletWaterTemp2ndStage <= TempSetPoint and UAdesign > 0.0:
                    var FanModeFrac: Float64 = (TempSetPoint - OutletWaterTemp1stStage) / (OutletWaterTemp2ndStage - OutletWaterTemp1stStage)
                    self.FanPower = FanModeFrac * FanPowerHigh + (1.0 - FanModeFrac) * FanPowerLow
                    self.OutletWaterTemp = TempSetPoint
                else:
                    self.OutletWaterTemp = OutletWaterTemp2ndStage
                    self.FanPower = FanPowerHigh
        
        var CpWater: Float64 = self.plantLoc.loop.glycol.getSpecificHeat(state,
                                                           state.dataLoopNodes.Node(self.WaterInletNode).Temp)
        self.Qactual = self.WaterMassFlowRate * CpWater * (state.dataLoopNodes.Node(self.WaterInletNode).Temp - self.OutletWaterTemp)
        if self.HighSpeedAirFlowRate > 0.0:
            self.AirFlowRateRatio = AirFlowRate / self.HighSpeedAirFlowRate
        else:
            self.AirFlowRateRatio = 0.0

    fn SimSimpleEvapFluidCooler(inout self, state: AnyType, waterMassFlowRate: Float64, AirFlowRate: Float64, UAdesign: Float64) -> None:
        var IterMax: Int32 = 50
        var WetBulbTolerance: Float64 = 0.00001
        var DeltaTwbTolerance: Float64 = 0.001
        
        self.WaterInletNode = self.WaterInletNodeNum
        self.WaterOutletNode = self.WaterOutletNodeNum
        var qActual: Float64 = 0.0
        var WetBulbError: Float64 = 1.0
        var DeltaTwb: Float64 = 1.0
        
        self.InletWaterTemp = self.inletConds.WaterTemp
        var outletWaterTemp: Float64 = self.InletWaterTemp
        var InletAirTemp: Float64 = self.inletConds.AirTemp
        var InletAirWetBulb: Float64 = self.inletConds.AirWetBulb
        
        if UAdesign == 0.0:
            self.OutletWaterTemp = outletWaterTemp
            return
        
        var AirDensity: Float64 = Psychrometrics.PsyRhoAirFnPbTdbW(state, self.inletConds.AirPress, InletAirTemp, self.inletConds.AirHumRat)
        var AirMassFlowRate: Float64 = AirFlowRate * AirDensity
        var CpAir: Float64 = Psychrometrics.PsyCpAirFnW(self.inletConds.AirHumRat)
        var CpWater: Float64 = self.plantLoc.loop.glycol.getSpecificHeat(state, self.InletWaterTemp)
        var InletAirEnthalpy: Float64 = Psychrometrics.PsyHFnTdbRhPb(state, InletAirWetBulb, 1.0, self.inletConds.AirPress)
        
        var OutletAirWetBulb: Float64 = InletAirWetBulb + 6.0
        
        var MdotCpWater: Float64 = waterMassFlowRate * CpWater
        var Iter: Int32 = 0
        while (WetBulbError > WetBulbTolerance) and (Iter <= IterMax) and (DeltaTwb > DeltaTwbTolerance):
            Iter += 1
            var OutletAirEnthalpy: Float64 = Psychrometrics.PsyHFnTdbRhPb(state, OutletAirWetBulb, 1.0, self.inletConds.AirPress)
            var CpAirside: Float64 = (OutletAirEnthalpy - InletAirEnthalpy) / (OutletAirWetBulb - InletAirWetBulb)
            var AirCapacity: Float64 = AirMassFlowRate * CpAirside
            var CapacityRatioMin: Float64 = min(AirCapacity, MdotCpWater)
            var CapacityRatioMax: Float64 = max(AirCapacity, MdotCpWater)
            var CapacityRatio: Float64 = CapacityRatioMin / CapacityRatioMax if CapacityRatioMax > 0.0 else 0.0
            
            var UAactual: Float64 = UAdesign * CpAirside / CpAir if CpAir > 0.0 else 0.0
            var NumTransferUnits: Float64 = UAactual / CapacityRatioMin if CapacityRatioMin > 0.0 else 0.0
            
            var effectiveness: Float64
            if CapacityRatio <= 0.995:
                effectiveness = (1.0 - exp(-1.0 * NumTransferUnits * (1.0 - CapacityRatio))) / \
                               (1.0 - CapacityRatio * exp(-1.0 * NumTransferUnits * (1.0 - CapacityRatio)))
            else:
                effectiveness = NumTransferUnits / (1.0 + NumTransferUnits) if NumTransferUnits >= 0.0 else 0.0
            
            qActual = effectiveness * CapacityRatioMin * (self.InletWaterTemp - InletAirWetBulb)
            var OutletAirWetBulbLast: Float64 = OutletAirWetBulb
            OutletAirWetBulb = InletAirWetBulb + qActual / AirCapacity if AirCapacity > 0.0 else InletAirWetBulb
            
            DeltaTwb = fabs(OutletAirWetBulb - InletAirWetBulb)
            WetBulbError = fabs((OutletAirWetBulb - OutletAirWetBulbLast) / (OutletAirWetBulbLast + 273.15))
        
        if qActual >= 0.0:
            outletWaterTemp = self.InletWaterTemp - qActual / MdotCpWater if MdotCpWater > 0.0 else self.InletWaterTemp
        else:
            outletWaterTemp = self.InletWaterTemp
        
        self.OutletWaterTemp = outletWaterTemp

    fn CalculateWaterUsage(inout self, state: AnyType) -> None:
        self.BlowdownVdot = 0.0
        self.EvaporationVdot = 0.0
        
        var AverageWaterTemp: Float64 = (self.InletWaterTemp + self.OutletWaterTemp) / 2.0
        
        if self.EvapLossMode == EvapLoss.ByMoistTheory:
            var AirDensity: Float64 = Psychrometrics.PsyRhoAirFnPbTdbW(state, self.inletConds.AirPress,
                                                         self.inletConds.AirTemp, self.inletConds.AirHumRat)
            var AirMassFlowRate: Float64 = self.AirFlowRateRatio * self.HighSpeedAirFlowRate * AirDensity
            var InletAirEnthalpy: Float64 = Psychrometrics.PsyHFnTdbRhPb(state, self.inletConds.AirWetBulb, 1.0, self.inletConds.AirPress)
            
            if AirMassFlowRate > 0.0:
                var OutletAirEnthalpy: Float64 = InletAirEnthalpy + self.Qactual / AirMassFlowRate
                var OutletAirTSat: Float64 = Psychrometrics.PsyTsatFnHPb(state, OutletAirEnthalpy, self.inletConds.AirPress)
                var OutletAirHumRatSat: Float64 = Psychrometrics.PsyWFnTdbH(state, OutletAirTSat, OutletAirEnthalpy)
                
                var InSpecificHumRat: Float64 = self.inletConds.AirHumRat / (1.0 + self.inletConds.AirHumRat)
                var OutSpecificHumRat: Float64 = OutletAirHumRatSat / (1.0 + OutletAirHumRatSat)
                
                var TairAvg: Float64 = (self.inletConds.AirTemp + OutletAirTSat) / 2.0
                var rho: Float64 = self.plantLoc.loop.glycol.getDensity(state, TairAvg)
                self.EvaporationVdot = (AirMassFlowRate * (OutSpecificHumRat - InSpecificHumRat)) / rho
                if self.EvaporationVdot < 0.0:
                    self.EvaporationVdot = 0.0
            else:
                self.EvaporationVdot = 0.0
        
        elif self.EvapLossMode == EvapLoss.ByUserFactor:
            var rho: Float64 = self.plantLoc.loop.glycol.getDensity(state, AverageWaterTemp)
            self.EvaporationVdot = self.UserEvapLossFactor * (self.InletWaterTemp - self.OutletWaterTemp) * (self.WaterMassFlowRate / rho)
            if self.EvaporationVdot < 0.0:
                self.EvaporationVdot = 0.0
        
        self.DriftVdot = self.DesignSprayWaterFlowRate * self.DriftLossFraction * self.AirFlowRateRatio
        
        if self.BlowdownMode == Blowdown.BySchedule:
            self.BlowdownVdot = self.blowdownSched.getCurrentVal() if self.blowdownSched else 0.0
        elif self.BlowdownMode == Blowdown.ByConcentration:
            if self.ConcentrationRatio > 2.0:
                self.BlowdownVdot = self.EvaporationVdot / (self.ConcentrationRatio - 1.0) - self.DriftVdot
            else:
                self.BlowdownVdot = self.EvaporationVdot - self.DriftVdot
            if self.BlowdownVdot < 0.0:
                self.BlowdownVdot = 0.0
        
        if self.capacityControl == CapacityControl.FluidBypass:
            if self.EvapLossMode == EvapLoss.ByUserFactor:
                self.EvaporationVdot *= (1.0 - self.BypassFraction)
            self.DriftVdot *= (1.0 - self.BypassFraction)
            self.BlowdownVdot *= (1.0 - self.BypassFraction)
        
        self.MakeUpVdot = self.EvaporationVdot + self.DriftVdot + self.BlowdownVdot
        
        self.StarvedMakeUpVdot = 0.0
        self.TankSupplyVdot = 0.0
        if self.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage(self.WaterTankID).VdotRequestDemand(self.WaterTankDemandARRID) = self.MakeUpVdot
            var AvailTankVdot: Float64 = state.dataWaterData.WaterStorage(self.WaterTankID).VdotAvailDemand(self.WaterTankDemandARRID)
            
            self.TankSupplyVdot = self.MakeUpVdot
            if AvailTankVdot < self.MakeUpVdot:
                self.StarvedMakeUpVdot = self.MakeUpVdot - AvailTankVdot
                self.TankSupplyVdot = AvailTankVdot
        
        self.EvaporationVol = self.EvaporationVdot * state.dataHVACGlobal.TimeStepSysSec
        self.DriftVol = self.DriftVdot * state.dataHVACGlobal.TimeStepSysSec
        self.BlowdownVol = self.BlowdownVdot * state.dataHVACGlobal.TimeStepSysSec
        self.MakeUpVol = self.MakeUpVdot * state.dataHVACGlobal.TimeStepSysSec
        self.TankSupplyVol = self.TankSupplyVdot * state.dataHVACGlobal.TimeStepSysSec
        self.StarvedMakeUpVol = self.StarvedMakeUpVdot * state.dataHVACGlobal.TimeStepSysSec

    fn UpdateEvapFluidCooler(inout self, state: AnyType) -> None:
        var TempAllowance: Float64 = 0.02
        
        state.dataLoopNodes.Node(self.WaterOutletNode).Temp = self.OutletWaterTemp
        
        if self.plantLoc.side.FlowLock == state.dataPlnt.FlowLock.Unlocked or state.dataGlobal.WarmupFlag:
            return
        
        if state.dataLoopNodes.Node(self.WaterOutletNode).MassFlowRate > \
           self.DesWaterMassFlowRate * self.EvapFluidCoolerMassFlowRateMultiplier:
            self.HighMassFlowErrorCount += 1
        
        var LoopMinTemp: Float64 = self.plantLoc.loop.MinTemp
        var TempDifference: Float64 = self.plantLoc.loop.MinTemp - self.OutletWaterTemp
        if TempDifference > TempAllowance and self.WaterMassFlowRate > 0.0:
            self.OutletWaterTempErrorCount += 1
        
        if self.WaterMassFlowRate > 0.0 and self.WaterMassFlowRate <= 0.001:
            self.SmallWaterMassFlowErrorCount += 1

    fn ReportEvapFluidCooler(inout self, state: AnyType, RunFlag: Bool) -> None:
        var ReportingConstant: Float64 = state.dataHVACGlobal.TimeStepSysSec
        
        if not RunFlag:
            self.fluidCoolerInletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNode).Temp
            self.fluidCoolerOutletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNode).Temp
            self.Qactual = 0.0
            self.FanPower = 0.0
            self.FanEnergy = 0.0
            self.AirFlowRateRatio = 0.0
            self.WaterAmountUsed = 0.0
            self.BypassFraction = 0.0
        else:
            self.fluidCoolerInletWaterTemp = state.dataLoopNodes.Node(self.WaterInletNode).Temp
            self.fluidCoolerOutletWaterTemp = self.OutletWaterTemp
            self.FanEnergy = self.FanPower * ReportingConstant
            self.WaterAmountUsed = self.WaterUsage * ReportingConstant

    fn oneTimeInit(inout self, state: AnyType) -> None:
        if self.MyOneTimeFlag:
            self.setupOutputVars(state)
            self.glycol = state.dataPlnt.PlantLoop(state.dataSize.CurLoopNum).glycol
            self.MyOneTimeFlag = False
        
        if self.OneTimeFlagForEachEvapFluidCooler:
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.Type, self.plantLoc)
            
            if self.Type == state.dataPlnt.PlantEquipmentType.EvapFluidCooler_TwoSpd:
                if self.DesignWaterFlowRate > 0.0:
                    if self.HighSpeedAirFlowRate <= self.LowSpeedAirFlowRate:
                        pass
                    if (self.HighSpeedEvapFluidCoolerUA > 0.0) and (self.LowSpeedEvapFluidCoolerUA > 0.0) and \
                       (self.HighSpeedEvapFluidCoolerUA <= self.LowSpeedEvapFluidCoolerUA):
                        pass
            
            self.OneTimeFlagForEachEvapFluidCooler = False

@dataclass
struct EvaporativeFluidCoolersData:
    var GetEvapFluidCoolerInputFlag: Bool = True
    var SimpleEvapFluidCooler: List[EvapFluidCoolerSpecs] = List[EvapFluidCoolerSpecs]()
    var UniqueSimpleEvapFluidCoolerNames: Dict[String, String] = Dict[String, String]()

fn GetEvapFluidCoolerInput(state: AnyType) -> None:
    var cEvapFluidCooler_SingleSpeed: String = "EvaporativeFluidCooler:SingleSpeed"
    var cEvapFluidCooler_TwoSpeed: String = "EvaporativeFluidCooler:TwoSpeed"
    
    var NumSingleSpeedEvapFluidCoolers: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cEvapFluidCooler_SingleSpeed)
    var NumTwoSpeedEvapFluidCoolers: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cEvapFluidCooler_TwoSpeed)
    var NumSimpleEvapFluidCoolers: Int32 = NumSingleSpeedEvapFluidCoolers + NumTwoSpeedEvapFluidCoolers
    
    if NumSimpleEvapFluidCoolers <= 0:
        raise Error("No evaporative fluid cooler objects found in input")

fn SetupOutputVariable(state: AnyType, varName: String, varRef: AnyType, objName: String) -> None:
    pass

fn ShowWarningError(state: AnyType, msg: String) -> None:
    pass

fn ShowContinueError(state: AnyType, msg: String) -> None:
    pass

fn Psychrometrics() -> None:
    pass

fn PlantUtilities() -> None:
    pass

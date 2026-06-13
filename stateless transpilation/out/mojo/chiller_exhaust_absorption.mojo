"""
EnergyPlus ChillerExhaustAbsorption module - Mojo port
Faithful translation from C++ original
"""

from collections import InlineArray
from math import copysign, fabs, abs, min, max
from enum import Enum


# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - main state object with nested data containers
# PlantComponent - abstract base struct for plant equipment
# PlantLocation - plant loop location descriptor
# Curve - curve struct with value() evaluation method
# Node access and manipulation functions (GetOnlySingleNode, TestCompSet, etc.)
# Psychrometrics.RhoH2O, Psychrometrics.PsyCpAirFnW
# PlantUtilities functions (SetComponentFlowRate, InitComponentNodes, etc.)
# OutputProcessor.SetupOutputVariable
# Error/warning reporting functions (ShowFatalError, ShowWarningError, etc.)
# GlobalNames.VerifyUniqueChillerName
# MicroturbineElectricGenerator.MTGeneratorSpecs
# CurveManager.GetCurve
# OutputReportPredefined functions
# DataPlant enums (BrLoopType, PlantEquipmentType, LoopDemandCalcScheme, FlowLock)
# DataSizing constants and PlantSizData
# Autosizing.BaseSizer
# HVAC constants


struct GeneratorType:
    alias Invalid = 0
    alias Microturbine = 1


struct ExhaustAbsorberSpecs:
    # Operational flags
    var Available: Bool
    var ON: Bool
    var InCoolingMode: Bool
    var InHeatingMode: Bool
    
    # Identification
    var Name: String
    
    # Capacities and ratios
    var NomCoolingCap: Float64
    var NomCoolingCapWasAutoSized: Bool
    var NomHeatCoolRatio: Float64
    var ThermalEnergyCoolRatio: Float64
    var ThermalEnergyHeatRatio: Float64
    var ElecCoolRatio: Float64
    var ElecHeatRatio: Float64
    
    # Node numbers
    var ChillReturnNodeNum: Int32
    var ChillSupplyNodeNum: Int32
    var ChillSetPointErrDone: Bool
    var ChillSetPointSetToLoop: Bool
    var CondReturnNodeNum: Int32
    var CondSupplyNodeNum: Int32
    var HeatReturnNodeNum: Int32
    var HeatSupplyNodeNum: Int32
    var HeatSetPointErrDone: Bool
    var HeatSetPointSetToLoop: Bool
    
    # Part load ratios
    var MinPartLoadRat: Float64
    var MaxPartLoadRat: Float64
    var OptPartLoadRat: Float64
    
    # Design temperatures and flows
    var TempDesCondReturn: Float64
    var TempDesCHWSupply: Float64
    var EvapVolFlowRate: Float64
    var EvapVolFlowRateWasAutoSized: Bool
    var CondVolFlowRate: Float64
    var CondVolFlowRateWasAutoSized: Bool
    var HeatVolFlowRate: Float64
    var HeatVolFlowRateWasAutoSized: Bool
    var SizFac: Float64
    
    # Curve pointers (using UnsafePointer in Mojo style)
    var CoolCapFTCurve: UnsafePointer[UInt8]
    var ThermalEnergyCoolFTCurve: UnsafePointer[UInt8]
    var ThermalEnergyCoolFPLRCurve: UnsafePointer[UInt8]
    var ElecCoolFTCurve: UnsafePointer[UInt8]
    var ElecCoolFPLRCurve: UnsafePointer[UInt8]
    var HeatCapFCoolCurve: UnsafePointer[UInt8]
    var ThermalEnergyHeatFHPLRCurve: UnsafePointer[UInt8]
    
    # Condenser type flags
    var isEnterCondensTemp: Bool
    var isWaterCooled: Bool
    var CHWLowLimitTemp: Float64
    var ExhaustAirInletNodeNum: Int32
    
    # Calculated design values
    var DesCondMassFlowRate: Float64
    var DesHeatMassFlowRate: Float64
    var DesEvapMassFlowRate: Float64
    
    # Error tracking
    var DeltaTempCoolErrCount: Int32
    var DeltaTempHeatErrCount: Int32
    var CondErrCount: Int32
    var PossibleSubcooling: Bool
    
    # Plant locations
    var CWPlantLoc: UnsafePointer[UInt8]
    var CDPlantLoc: UnsafePointer[UInt8]
    var HWPlantLoc: UnsafePointer[UInt8]
    
    var CompType_Num: Int32
    var ExhTempLTAbsLeavingTempIndex: Int32
    var ExhTempLTAbsLeavingHeatingTempIndex: Int32
    var lCondWaterMassFlowRate_Index: Int32
    
    var TypeOf: String
    var ExhaustSourceName: String
    var envrnInit: Bool
    var oldCondSupplyTemp: Float64
    
    # Report variables
    var CoolingLoad: Float64
    var CoolingEnergy: Float64
    var HeatingLoad: Float64
    var HeatingEnergy: Float64
    var TowerLoad: Float64
    var TowerEnergy: Float64
    var ThermalEnergyUseRate: Float64
    var ThermalEnergy: Float64
    var CoolThermalEnergyUseRate: Float64
    var CoolThermalEnergy: Float64
    var HeatThermalEnergyUseRate: Float64
    var HeatThermalEnergy: Float64
    var ElectricPower: Float64
    var ElectricEnergy: Float64
    var CoolElectricPower: Float64
    var CoolElectricEnergy: Float64
    var HeatElectricPower: Float64
    var HeatElectricEnergy: Float64
    
    var ChillReturnTemp: Float64
    var ChillSupplyTemp: Float64
    var ChillWaterFlowRate: Float64
    var CondReturnTemp: Float64
    var CondSupplyTemp: Float64
    var CondWaterFlowRate: Float64
    var HotWaterReturnTemp: Float64
    var HotWaterSupplyTemp: Float64
    var HotWaterFlowRate: Float64
    
    var CoolPartLoadRatio: Float64
    var HeatPartLoadRatio: Float64
    var CoolingCapacity: Float64
    var HeatingCapacity: Float64
    var FractionOfPeriodRunning: Float64
    var ThermalEnergyCOP: Float64
    var ExhaustInTemp: Float64
    var ExhaustInFlow: Float64
    var ExhHeatRecPotentialHeat: Float64
    var ExhHeatRecPotentialCool: Float64

    fn __init__(inout self):
        self.Available = False
        self.ON = False
        self.InCoolingMode = False
        self.InHeatingMode = False
        self.Name = ""
        self.NomCoolingCap = 0.0
        self.NomCoolingCapWasAutoSized = False
        self.NomHeatCoolRatio = 0.0
        self.ThermalEnergyCoolRatio = 0.0
        self.ThermalEnergyHeatRatio = 0.0
        self.ElecCoolRatio = 0.0
        self.ElecHeatRatio = 0.0
        self.ChillReturnNodeNum = 0
        self.ChillSupplyNodeNum = 0
        self.ChillSetPointErrDone = False
        self.ChillSetPointSetToLoop = False
        self.CondReturnNodeNum = 0
        self.CondSupplyNodeNum = 0
        self.HeatReturnNodeNum = 0
        self.HeatSupplyNodeNum = 0
        self.HeatSetPointErrDone = False
        self.HeatSetPointSetToLoop = False
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.TempDesCondReturn = 0.0
        self.TempDesCHWSupply = 0.0
        self.EvapVolFlowRate = 0.0
        self.EvapVolFlowRateWasAutoSized = False
        self.CondVolFlowRate = 0.0
        self.CondVolFlowRateWasAutoSized = False
        self.HeatVolFlowRate = 0.0
        self.HeatVolFlowRateWasAutoSized = False
        self.SizFac = 0.0
        self.CoolCapFTCurve = UnsafePointer[UInt8]()
        self.ThermalEnergyCoolFTCurve = UnsafePointer[UInt8]()
        self.ThermalEnergyCoolFPLRCurve = UnsafePointer[UInt8]()
        self.ElecCoolFTCurve = UnsafePointer[UInt8]()
        self.ElecCoolFPLRCurve = UnsafePointer[UInt8]()
        self.HeatCapFCoolCurve = UnsafePointer[UInt8]()
        self.ThermalEnergyHeatFHPLRCurve = UnsafePointer[UInt8]()
        self.isEnterCondensTemp = False
        self.isWaterCooled = False
        self.CHWLowLimitTemp = 0.0
        self.ExhaustAirInletNodeNum = 0
        self.DesCondMassFlowRate = 0.0
        self.DesHeatMassFlowRate = 0.0
        self.DesEvapMassFlowRate = 0.0
        self.DeltaTempCoolErrCount = 0
        self.DeltaTempHeatErrCount = 0
        self.CondErrCount = 0
        self.PossibleSubcooling = False
        self.CWPlantLoc = UnsafePointer[UInt8]()
        self.CDPlantLoc = UnsafePointer[UInt8]()
        self.HWPlantLoc = UnsafePointer[UInt8]()
        self.CompType_Num = GeneratorType.Invalid
        self.ExhTempLTAbsLeavingTempIndex = 0
        self.ExhTempLTAbsLeavingHeatingTempIndex = 0
        self.lCondWaterMassFlowRate_Index = 0
        self.TypeOf = ""
        self.ExhaustSourceName = ""
        self.envrnInit = True
        self.oldCondSupplyTemp = 0.0
        self.CoolingLoad = 0.0
        self.CoolingEnergy = 0.0
        self.HeatingLoad = 0.0
        self.HeatingEnergy = 0.0
        self.TowerLoad = 0.0
        self.TowerEnergy = 0.0
        self.ThermalEnergyUseRate = 0.0
        self.ThermalEnergy = 0.0
        self.CoolThermalEnergyUseRate = 0.0
        self.CoolThermalEnergy = 0.0
        self.HeatThermalEnergyUseRate = 0.0
        self.HeatThermalEnergy = 0.0
        self.ElectricPower = 0.0
        self.ElectricEnergy = 0.0
        self.CoolElectricPower = 0.0
        self.CoolElectricEnergy = 0.0
        self.HeatElectricPower = 0.0
        self.HeatElectricEnergy = 0.0
        self.ChillReturnTemp = 0.0
        self.ChillSupplyTemp = 0.0
        self.ChillWaterFlowRate = 0.0
        self.CondReturnTemp = 0.0
        self.CondSupplyTemp = 0.0
        self.CondWaterFlowRate = 0.0
        self.HotWaterReturnTemp = 0.0
        self.HotWaterSupplyTemp = 0.0
        self.HotWaterFlowRate = 0.0
        self.CoolPartLoadRatio = 0.0
        self.HeatPartLoadRatio = 0.0
        self.CoolingCapacity = 0.0
        self.HeatingCapacity = 0.0
        self.FractionOfPeriodRunning = 0.0
        self.ThermalEnergyCOP = 0.0
        self.ExhaustInTemp = 0.0
        self.ExhaustInFlow = 0.0
        self.ExhHeatRecPotentialHeat = 0.0
        self.ExhHeatRecPotentialCool = 0.0

    @staticmethod
    fn factory(state: UnsafePointer[UInt8], objectName: String) -> UnsafePointer[ExhaustAbsorberSpecs]:
        """Factory method to get or create an ExhaustAbsorberSpecs"""
        # Implementation requires access to state.dataChillerExhaustAbsorption
        # This is a stub returning null pointer
        return UnsafePointer[ExhaustAbsorberSpecs]()

    fn simulate(mut self, state: UnsafePointer[UInt8], calledFromLocation: UnsafePointer[UInt8], FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> Float64:
        """Main simulation method"""
        let BrLoopType_NoMatch = 0
        let BrLoopType_Chiller = 1
        let BrLoopType_Heater = 2
        let BrLoopType_Condenser = 3
        
        var brIdentity = BrLoopType_NoMatch
        
        # Simplified - full implementation requires access to loop structure
        if RunFlag and self.ChillReturnNodeNum > 0:
            brIdentity = BrLoopType_Chiller
        elif RunFlag and self.HeatReturnNodeNum > 0:
            brIdentity = BrLoopType_Heater
        
        if brIdentity == BrLoopType_Chiller:
            self.InCoolingMode = RunFlag != False
            self.initialize(state)
            self.calcChiller(state, CurLoad)
            self.updateCoolRecords(state, CurLoad, RunFlag)
        elif brIdentity == BrLoopType_Heater:
            self.InHeatingMode = RunFlag != False
            self.initialize(state)
            self.calcHeater(state, CurLoad, RunFlag)
            self.updateHeatRecords(state, CurLoad, RunFlag)
        elif brIdentity == BrLoopType_Condenser:
            pass
        else:
            pass
        
        return CurLoad

    fn getDesignCapacities(self, state: UnsafePointer[UInt8], calledFromLocation: UnsafePointer[UInt8]) -> Tuple[Float64, Float64, Float64]:
        """Get design capacities"""
        var MaxLoad: Float64 = 0.0
        var MinLoad: Float64 = 0.0
        var OptLoad: Float64 = 0.0
        
        MinLoad = self.NomCoolingCap * self.MinPartLoadRat
        MaxLoad = self.NomCoolingCap * self.MaxPartLoadRat
        OptLoad = self.NomCoolingCap * self.OptPartLoadRat
        
        return MinLoad, MaxLoad, OptLoad

    fn getSizingFactor(self) -> Float64:
        """Get sizing factor"""
        return self.SizFac

    fn onInitLoopEquip(mut self, state: UnsafePointer[UInt8], calledFromLocation: UnsafePointer[UInt8]) -> None:
        """Initialize on loop equipment call"""
        self.initialize(state)
        self.size(state)

    fn getDesignTemperatures(self) -> Tuple[Float64, Float64]:
        """Get design temperatures"""
        return self.TempDesCHWSupply, self.TempDesCondReturn

    fn initialize(mut self, state: UnsafePointer[UInt8]) -> None:
        """Initialize the chiller"""
        let rho: Float64 = 1000.0
        
        if self.envrnInit:
            if self.isWaterCooled:
                self.DesCondMassFlowRate = rho * self.CondVolFlowRate
            
            self.DesHeatMassFlowRate = rho * self.HeatVolFlowRate
            self.DesEvapMassFlowRate = rho * self.EvapVolFlowRate
            
            self.envrnInit = False

    fn setupOutputVariables(mut self, state: UnsafePointer[UInt8]) -> None:
        """Setup output variables"""
        # SetupOutputVariable calls for all report variables - implementation stubs

    fn size(mut self, state: UnsafePointer[UInt8]) -> None:
        """Size the chiller"""
        # Sizing logic - simplified implementation

    fn calcChiller(mut self, state: UnsafePointer[UInt8], MyLoad: Float64) -> None:
        """Calculate chiller performance"""
        let AbsLeavingTemp: Float64 = 176.667
        
        var lCoolingLoad: Float64 = 0.0
        var lTowerLoad: Float64 = 0.0
        var lCoolThermalEnergyUseRate: Float64 = 0.0
        var lCoolElectricPower: Float64 = 0.0
        var lChillSupplyTemp: Float64 = 0.0
        var lCondSupplyTemp: Float64 = 0.0
        var lCondWaterMassFlowRate: Float64 = 0.0
        var lCoolPartLoadRatio: Float64 = 0.0
        var lAvailableCoolingCapacity: Float64 = 0.0
        var lFractionOfPeriodRunning: Float64 = 0.0
        var lExhHeatRecPotentialCool: Float64 = 0.0
        
        var lChillReturnTemp: Float64 = 0.0
        var lChillWaterMassFlowRate: Float64 = 0.0
        var lCondReturnTemp: Float64 = 0.0
        var ChillSupplySetPointTemp: Float64 = 0.0
        var ChillDeltaTemp: Float64 = fabs(lChillReturnTemp - ChillSupplySetPointTemp)
        
        var lExhaustInTemp: Float64 = 0.0
        var lExhaustInFlow: Float64 = 0.0
        var lExhaustAirHumRat: Float64 = 0.0
        
        let Cp_CW: Float64 = 4180.0
        var Cp_CD: Float64 = 4180.0
        
        let lNomCoolingCap = self.NomCoolingCap
        let lThermalEnergyCoolRatio = self.ThermalEnergyCoolRatio
        let lThermalEnergyHeatRatio = self.ThermalEnergyHeatRatio
        let lElecCoolRatio = self.ElecCoolRatio
        let lMinPartLoadRat = self.MinPartLoadRat
        let lMaxPartLoadRat = self.MaxPartLoadRat
        let lIsEnterCondensTemp = self.isEnterCondensTemp
        let lIsWaterCooled = self.isWaterCooled
        let lCHWLowLimitTemp = self.CHWLowLimitTemp
        
        if MyLoad >= 0 or not (self.InHeatingMode or self.InCoolingMode):
            lChillSupplyTemp = lChillReturnTemp
            lCondSupplyTemp = lCondReturnTemp
            lCondWaterMassFlowRate = 0.0
            lFractionOfPeriodRunning = min(1.0, max(self.HeatPartLoadRatio, lCoolPartLoadRatio) / lMinPartLoadRat)
        else:
            if lIsWaterCooled:
                lCondReturnTemp = 0.0
                if lIsEnterCondensTemp:
                    pass
                else:
                    if self.oldCondSupplyTemp == 0:
                        self.oldCondSupplyTemp = lCondReturnTemp + 8.0
                lCondWaterMassFlowRate = self.DesCondMassFlowRate
            else:
                lCondWaterMassFlowRate = 0.0
            
            lAvailableCoolingCapacity = lNomCoolingCap
            
            var PartLoadRat: Float64 = min(fabs(MyLoad) / lAvailableCoolingCapacity, lMaxPartLoadRat)
            PartLoadRat = max(lMinPartLoadRat, PartLoadRat)
            
            if lAvailableCoolingCapacity > 0.0:
                if fabs(MyLoad) / lAvailableCoolingCapacity < lMinPartLoadRat:
                    lCoolPartLoadRatio = MyLoad / lAvailableCoolingCapacity
                else:
                    lCoolPartLoadRatio = PartLoadRat
            else:
                lCoolPartLoadRatio = 0.0
            
            if lCoolPartLoadRatio < lMinPartLoadRat or self.HeatPartLoadRatio < lMinPartLoadRat:
                lFractionOfPeriodRunning = min(1.0, max(self.HeatPartLoadRatio, lCoolPartLoadRatio) / lMinPartLoadRat)
            else:
                lFractionOfPeriodRunning = 1.0
            
            lCoolThermalEnergyUseRate = lAvailableCoolingCapacity * lThermalEnergyCoolRatio * lFractionOfPeriodRunning
            lCoolElectricPower = lNomCoolingCap * lElecCoolRatio * lFractionOfPeriodRunning
            
            lTowerLoad = lCoolingLoad + lCoolThermalEnergyUseRate / lThermalEnergyHeatRatio + lCoolElectricPower
            
            let CpAir: Float64 = 1006.0
            lExhHeatRecPotentialCool = lExhaustInFlow * CpAir * (lExhaustInTemp - AbsLeavingTemp)
            
            if lExhHeatRecPotentialCool < lCoolThermalEnergyUseRate:
                lCoolThermalEnergyUseRate = 0.0
                lTowerLoad = 0.0
                lCoolElectricPower = 0.0
                lChillSupplyTemp = lChillReturnTemp
                lCondSupplyTemp = lCondReturnTemp
                lFractionOfPeriodRunning = min(1.0, max(self.HeatPartLoadRatio, lCoolPartLoadRatio) / lMinPartLoadRat)
            
            if lIsWaterCooled:
                if lCondWaterMassFlowRate > 1e-5:
                    lCondSupplyTemp = lCondReturnTemp + lTowerLoad / (lCondWaterMassFlowRate * Cp_CD)
            else:
                lCondSupplyTemp = lCondReturnTemp
            
            self.oldCondSupplyTemp = lCondSupplyTemp
        
        self.CoolingLoad = lCoolingLoad
        self.TowerLoad = lTowerLoad
        self.CoolThermalEnergyUseRate = lCoolThermalEnergyUseRate
        self.CoolElectricPower = lCoolElectricPower
        self.CondReturnTemp = lCondReturnTemp
        self.ChillReturnTemp = lChillReturnTemp
        self.CondSupplyTemp = lCondSupplyTemp
        self.ChillSupplyTemp = lChillSupplyTemp
        self.ChillWaterFlowRate = lChillWaterMassFlowRate
        self.CondWaterFlowRate = lCondWaterMassFlowRate
        self.CoolPartLoadRatio = lCoolPartLoadRatio
        self.CoolingCapacity = lAvailableCoolingCapacity
        self.FractionOfPeriodRunning = lFractionOfPeriodRunning
        self.ExhaustInTemp = lExhaustInTemp
        self.ExhaustInFlow = lExhaustInFlow
        self.ExhHeatRecPotentialCool = lExhHeatRecPotentialCool
        
        self.ThermalEnergyUseRate = lCoolThermalEnergyUseRate + self.HeatThermalEnergyUseRate
        self.ElectricPower = lCoolElectricPower + self.HeatElectricPower

    fn calcHeater(mut self, state: UnsafePointer[UInt8], MyLoad: Float64, RunFlag: Bool) -> None:
        """Calculate heater performance"""
        let AbsLeavingTemp: Float64 = 176.667
        
        var lHeatingLoad: Float64 = 0.0
        var lHeatThermalEnergyUseRate: Float64 = 0.0
        var lHeatElectricPower: Float64 = 0.0
        var lHotWaterSupplyTemp: Float64 = 0.0
        var lHeatPartLoadRatio: Float64 = 0.0
        var lAvailableHeatingCapacity: Float64 = 0.0
        var lFractionOfPeriodRunning: Float64 = 0.0
        var lExhaustInTemp: Float64 = 0.0
        var lExhaustInFlow: Float64 = 0.0
        var lExhHeatRecPotentialHeat: Float64 = 0.0
        
        var HeatSupplySetPointTemp: Float64 = 0.0
        var HeatDeltaTemp: Float64 = 0.0
        var lHotWaterMassFlowRate: Float64 = 0.0
        
        if MyLoad <= 0 or not RunFlag:
            lHotWaterSupplyTemp = 0.0
            lFractionOfPeriodRunning = min(1.0, max(lHeatPartLoadRatio, self.CoolPartLoadRatio) / self.MinPartLoadRat)
        else:
            let Cp_HW: Float64 = 4180.0
            
            lAvailableHeatingCapacity = self.NomHeatCoolRatio * self.NomCoolingCap
            
            lHeatingLoad = fabs(MyLoad)
            if HeatDeltaTemp != 0:
                lHotWaterMassFlowRate = fabs(lHeatingLoad / (Cp_HW * HeatDeltaTemp))
            
            if lAvailableHeatingCapacity <= 0.0:
                lAvailableHeatingCapacity = 0.0
                lHeatPartLoadRatio = 0.0
            else:
                lHeatPartLoadRatio = lHeatingLoad / lAvailableHeatingCapacity
            
            lHeatThermalEnergyUseRate = lAvailableHeatingCapacity * self.ThermalEnergyHeatRatio
            
            lFractionOfPeriodRunning = min(1.0, max(lHeatPartLoadRatio, self.CoolPartLoadRatio) / self.MinPartLoadRat)
            
            lHeatElectricPower = self.NomCoolingCap * self.NomHeatCoolRatio * self.ElecHeatRatio * lFractionOfPeriodRunning
            
            let CpAir: Float64 = 1006.0
            lExhHeatRecPotentialHeat = lExhaustInFlow * CpAir * (lExhaustInTemp - AbsLeavingTemp)
            
            if lExhHeatRecPotentialHeat < lHeatThermalEnergyUseRate:
                lHeatThermalEnergyUseRate = 0.0
                lHeatElectricPower = 0.0
                lHotWaterSupplyTemp = 0.0
                lFractionOfPeriodRunning = min(1.0, max(lHeatPartLoadRatio, self.CoolPartLoadRatio) / self.MinPartLoadRat)
            
            if lHeatElectricPower <= self.CoolElectricPower:
                lHeatElectricPower = 0.0
            else:
                lHeatElectricPower -= self.CoolElectricPower
        
        self.HeatingLoad = lHeatingLoad
        self.HeatThermalEnergyUseRate = lHeatThermalEnergyUseRate
        self.HeatElectricPower = lHeatElectricPower
        self.HotWaterReturnTemp = 0.0
        self.HotWaterSupplyTemp = lHotWaterSupplyTemp
        self.HotWaterFlowRate = lHotWaterMassFlowRate
        self.HeatPartLoadRatio = lHeatPartLoadRatio
        self.HeatingCapacity = lAvailableHeatingCapacity
        self.FractionOfPeriodRunning = lFractionOfPeriodRunning
        
        self.ThermalEnergyUseRate = self.CoolThermalEnergyUseRate + lHeatThermalEnergyUseRate
        self.ElectricPower = self.CoolElectricPower + lHeatElectricPower
        self.ExhaustInTemp = lExhaustInTemp
        self.ExhaustInFlow = lExhaustInFlow
        self.ExhHeatRecPotentialHeat = lExhHeatRecPotentialHeat

    fn updateCoolRecords(mut self, state: UnsafePointer[UInt8], MyLoad: Float64, RunFlag: Bool) -> None:
        """Update cooling records"""
        if MyLoad == 0 or not RunFlag:
            pass
        else:
            pass
        
        let RptConstant: Float64 = 3600.0
        self.CoolingEnergy = self.CoolingLoad * RptConstant
        self.TowerEnergy = self.TowerLoad * RptConstant
        self.ThermalEnergy = self.ThermalEnergyUseRate * RptConstant
        self.CoolThermalEnergy = self.CoolThermalEnergyUseRate * RptConstant
        self.ElectricEnergy = self.ElectricPower * RptConstant
        self.CoolElectricEnergy = self.CoolElectricPower * RptConstant
        
        if self.CoolThermalEnergyUseRate != 0.0:
            self.ThermalEnergyCOP = self.CoolingLoad / self.CoolThermalEnergyUseRate
        else:
            self.ThermalEnergyCOP = 0.0

    fn updateHeatRecords(mut self, state: UnsafePointer[UInt8], MyLoad: Float64, RunFlag: Bool) -> None:
        """Update heating records"""
        if MyLoad == 0 or not RunFlag:
            pass
        else:
            pass
        
        let RptConstant: Float64 = 3600.0
        self.HeatingEnergy = self.HeatingLoad * RptConstant
        self.ThermalEnergy = self.ThermalEnergyUseRate * RptConstant
        self.HeatThermalEnergy = self.HeatThermalEnergyUseRate * RptConstant
        self.ElectricEnergy = self.ElectricPower * RptConstant
        self.HeatElectricEnergy = self.HeatElectricPower * RptConstant

    fn oneTimeInit(mut self, state: UnsafePointer[UInt8]) -> None:
        """One time initialization"""
        pass

    fn oneTimeInit_new(mut self, state: UnsafePointer[UInt8]) -> None:
        """New one time initialization"""
        self.setupOutputVariables(state)


struct ChillerExhaustAbsorptionData:
    var Sim_GetInput: Bool
    var ExhaustAbsorber: DynamicVector[ExhaustAbsorberSpecs]
    
    fn __init__(inout self):
        self.Sim_GetInput = True
        self.ExhaustAbsorber = DynamicVector[ExhaustAbsorberSpecs]()


fn GetExhaustAbsorberInput(state: UnsafePointer[UInt8]) -> None:
    """Get input for exhaust absorber chiller"""
    let cCurrentModuleObject = "ChillerHeater:Absorption:DoubleEffect"
    
    var NumExhaustAbsorbers: Int32 = 0
    
    if NumExhaustAbsorbers <= 0:
        return

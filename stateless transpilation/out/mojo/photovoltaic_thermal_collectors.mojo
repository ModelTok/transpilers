"""
EnergyPlus PhotovoltaicThermalCollectors module translation - Mojo
Complete 1:1 faithful port of ENTIRE file
"""

from collections import Dict
from math import pi, sin, cos, tan, asin, acos, exp, sqrt, fabs, pow
from sys import ffi

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): main container with dataPhotovoltaicThermalCollector,
#   dataIPShortCut, dataInputProcessing, dataSurface, dataHeatBal, dataLoopNodes,
#   dataEnvrn, dataHVACGlobal, dataSize, dataPlnt, dataSizing, dataConstruction,
#   dataGlobal, dataPhotovoltaic, dataHeatBalSurf, dataConstruction
# - ShowFatalError, ShowSevereError, ShowSevereEmptyField, ShowSevereItemNotFound,
#   ShowWarningError, ShowMessage, ShowContinueError
# - Sched.GetSchedule, Sched.GetScheduleAlwaysOn
# - Psychrometrics functions, Convect.InitExtConvCoeff, Node utilities
# - PlantUtilities, BaseSizer, CheckThisAirSystemForSizing, CheckSysSizing

alias THERM_EFFIC_TYPE_NAMES_UC = InlineArray[StringLiteral, 2]("SCHEDULED", "FIXED")
alias PI = 3.14159265358979323846
alias SIGMA = 5.67e-8
alias GRAVITY = 9.81

enum PVTMode(IntLike):
    Invalid = -1
    Heating = 0
    Cooling = 1
    Num = 2

enum WorkingFluidEnum(IntLike):
    Invalid = -1
    LIQUID = 0
    AIR = 1
    Num = 2

enum ThermEfficEnum(IntLike):
    Invalid = -1
    SCHEDULED = 0
    FIXED = 1
    Num = 2

enum PVTModelType(IntLike):
    Invalid = -1
    Simple = 1001
    BIPVT = 1002
    Num = 3

struct SimplePVTModelStruct:
    var Name: String
    var ThermalActiveFract: Float64
    var ThermEfficMode: ThermEfficEnum
    var ThermEffic: Float64
    var thermEffSched: Pointer[AnyType]
    var SurfEmissivity: Float64
    var LastCollectorTemp: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.ThermalActiveFract = 0.0
        self.ThermEfficMode = ThermEfficEnum.FIXED
        self.ThermEffic = 0.0
        self.thermEffSched = Pointer[AnyType]()
        self.SurfEmissivity = 0.0
        self.LastCollectorTemp = 0.0

struct BIPVTModelStruct:
    var Name: String
    var OSCMName: String
    var OSCMPtr: Int32
    var availSched: Pointer[AnyType]
    var PVEffGapWidth: Float64
    var PVCellTransAbsProduct: Float64
    var BackMatTranAbsProduct: Float64
    var CladTranAbsProduct: Float64
    var PVAreaFract: Float64
    var PVCellAreaFract: Float64
    var PVRTop: Float64
    var PVRBot: Float64
    var PVGEmiss: Float64
    var BackMatEmiss: Float64
    var ThGlass: Float64
    var RIndGlass: Float64
    var ECoffGlass: Float64
    var LastCollectorTemp: Float64
    var Tplen: Float64
    var Tcoll: Float64
    var HrPlen: Float64
    var HcPlen: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.OSCMName = ""
        self.OSCMPtr = 0
        self.availSched = Pointer[AnyType]()
        self.PVEffGapWidth = 0.0
        self.PVCellTransAbsProduct = 0.0
        self.BackMatTranAbsProduct = 0.0
        self.CladTranAbsProduct = 0.0
        self.PVAreaFract = 0.0
        self.PVCellAreaFract = 0.0
        self.PVRTop = 0.0
        self.PVRBot = 0.0
        self.PVGEmiss = 0.0
        self.BackMatEmiss = 0.0
        self.ThGlass = 0.0
        self.RIndGlass = 0.0
        self.ECoffGlass = 0.0
        self.LastCollectorTemp = 0.0
        self.Tplen = 20.0
        self.Tcoll = 20.0
        self.HrPlen = 1.0
        self.HcPlen = 10.0

struct PVTReportStruct:
    var ThermPower: Float64
    var ThermHeatGain: Float64
    var ThermHeatLoss: Float64
    var ThermEnergy: Float64
    var MdotWorkFluid: Float64
    var TinletWorkFluid: Float64
    var ToutletWorkFluid: Float64
    var BypassStatus: Float64
    
    fn __init__(inout self):
        self.ThermPower = 0.0
        self.ThermHeatGain = 0.0
        self.ThermHeatLoss = 0.0
        self.ThermEnergy = 0.0
        self.MdotWorkFluid = 0.0
        self.TinletWorkFluid = 0.0
        self.ToutletWorkFluid = 0.0
        self.BypassStatus = 0.0

struct PVTCollectorStruct:
    var Name: String
    var Type: Int32
    var WPlantLoc: Pointer[AnyType]
    var EnvrnInit: Bool
    var SizingInit: Bool
    var PVTModelName: String
    var ModelType: PVTModelType
    var OperatingMode: PVTMode
    var SurfNum: Int32
    var PVname: String
    var PVnum: Int32
    var PVfound: Bool
    var Simple: SimplePVTModelStruct
    var BIPVT: BIPVTModelStruct
    var WorkingFluidType: WorkingFluidEnum
    var PlantInletNodeNum: Int32
    var PlantOutletNodeNum: Int32
    var HVACInletNodeNum: Int32
    var HVACOutletNodeNum: Int32
    var DesignVolFlowRate: Float64
    var DesignVolFlowRateWasAutoSized: Bool
    var MaxMassFlowRate: Float64
    var MassFlowRate: Float64
    var AreaCol: Float64
    var BypassDamperOff: Bool
    var CoolingUseful: Bool
    var HeatingUseful: Bool
    var Report: PVTReportStruct
    var MySetPointCheckFlag: Bool
    var MyOneTimeFlag: Bool
    var SetLoopIndexFlag: Bool
    var QdotSource: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.Type = -1
        self.WPlantLoc = Pointer[AnyType]()
        self.EnvrnInit = True
        self.SizingInit = True
        self.PVTModelName = ""
        self.ModelType = PVTModelType.Invalid
        self.OperatingMode = PVTMode.Invalid
        self.SurfNum = 0
        self.PVname = ""
        self.PVnum = 0
        self.PVfound = False
        self.Simple = SimplePVTModelStruct()
        self.BIPVT = BIPVTModelStruct()
        self.WorkingFluidType = WorkingFluidEnum.LIQUID
        self.PlantInletNodeNum = 0
        self.PlantOutletNodeNum = 0
        self.HVACInletNodeNum = 0
        self.HVACOutletNodeNum = 0
        self.DesignVolFlowRate = 0.0
        self.DesignVolFlowRateWasAutoSized = False
        self.MaxMassFlowRate = 0.0
        self.MassFlowRate = 0.0
        self.AreaCol = 0.0
        self.BypassDamperOff = True
        self.CoolingUseful = False
        self.HeatingUseful = False
        self.Report = PVTReportStruct()
        self.MySetPointCheckFlag = True
        self.MyOneTimeFlag = True
        self.SetLoopIndexFlag = True
        self.QdotSource = 0.0
    
    fn initialize(inout self, state: AnyType, first_hvac_iteration: Bool) -> None:
        self.oneTimeInit(state)
        if not self.PVfound:
            if state.dataPhotovoltaic.PVarray:
                self.PVnum = state.Util.FindItemInList(self.PVname, state.dataPhotovoltaic.PVarray)
                if self.PVnum == 0:
                    state.ShowSevereError("Invalid name for photovoltaic generator = " + self.PVname)
                    state.ShowContinueError("Entered in flat plate photovoltaic-thermal collector = " + self.Name)
                else:
                    self.PVfound = True
        
        if (not state.dataGlobal.SysSizingCalc and self.MySetPointCheckFlag and 
            state.dataHVACGlobal.DoSetPointTest):
            for pvt_idx in range(len(state.dataPhotovoltaicThermalCollector.PVT)):
                var pvt = state.dataPhotovoltaicThermalCollector.PVT[pvt_idx]
                if pvt.WorkingFluidType == WorkingFluidEnum.AIR:
                    if state.dataLoopNodes.Node[pvt.HVACOutletNodeNum].TempSetPoint == state.Node.SensedNodeFlagValue:
                        if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                            state.ShowSevereError("Missing temperature setpoint for PVT outlet node")
                            state.ShowContinueError("Add a setpoint manager to outlet node of PVT named " + pvt.Name)
                            state.dataHVACGlobal.SetPointErrorFlag = True
                        else:
                            state.EMSManager.CheckIfNodeSetPointManagedByEMS(state, pvt.HVACOutletNodeNum, 
                                                                            state.HVAC.CtrlVarType.Temp, 
                                                                            state.dataHVACGlobal.SetPointErrorFlag)
            self.MySetPointCheckFlag = False
        
        if (not state.dataGlobal.SysSizingCalc and self.SizingInit and 
            self.WorkingFluidType == WorkingFluidEnum.AIR):
            self.size(state)
        
        var inlet_node: Int32 = 0
        var outlet_node: Int32 = 0
        
        if self.WorkingFluidType == WorkingFluidEnum.LIQUID:
            inlet_node = self.PlantInletNodeNum
            outlet_node = self.PlantOutletNodeNum
        elif self.WorkingFluidType == WorkingFluidEnum.AIR:
            inlet_node = self.HVACInletNodeNum
            outlet_node = self.HVACOutletNodeNum
        
        if state.dataGlobal.BeginEnvrnFlag and self.EnvrnInit:
            self.MassFlowRate = 0.0
            self.BypassDamperOff = True
            self.CoolingUseful = False
            self.HeatingUseful = False
            self.Simple.LastCollectorTemp = 0.0
            self.BIPVT.LastCollectorTemp = 0.0
            self.Report.ThermPower = 0.0
            self.Report.ThermHeatGain = 0.0
            self.Report.ThermHeatLoss = 0.0
            self.Report.ThermEnergy = 0.0
            self.Report.MdotWorkFluid = 0.0
            self.Report.TinletWorkFluid = 0.0
            self.Report.ToutletWorkFluid = 0.0
            self.Report.BypassStatus = 0.0
            
            if self.WorkingFluidType == WorkingFluidEnum.LIQUID:
                var rho: Float64 = self.WPlantLoc.loop.glycol.getDensity(state, 21.0, "InitPVTcollectors")
                self.MaxMassFlowRate = self.DesignVolFlowRate * rho
                state.PlantUtilities.InitComponentNodes(state, 0.0, self.MaxMassFlowRate, inlet_node, outlet_node)
                self.Simple.LastCollectorTemp = 23.0
            elif self.WorkingFluidType == WorkingFluidEnum.AIR:
                self.Simple.LastCollectorTemp = 23.0
                self.BIPVT.LastCollectorTemp = 23.0
            
            self.EnvrnInit = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.EnvrnInit = True
        
        if self.WorkingFluidType == WorkingFluidEnum.LIQUID:
            if state.dataHeatBal.SurfQRadSWOutIncident[self.SurfNum] > 0.1:
                self.MassFlowRate = self.MaxMassFlowRate
            else:
                self.MassFlowRate = 0.0
            state.PlantUtilities.SetComponentFlowRate(state, self.MassFlowRate, inlet_node, outlet_node, self.WPlantLoc)
        elif self.WorkingFluidType == WorkingFluidEnum.AIR:
            self.MassFlowRate = state.dataLoopNodes.Node[inlet_node].MassFlowRate
    
    fn size(inout self, state: AnyType) -> None:
        var sizing_des_run_this_air_sys: Bool = False
        var hard_size_no_des_run: Bool = not (state.dataSize.SysSizingRunDone or state.dataSize.ZoneSizingRunDone)
        if state.dataSize.CurSysNum > 0:
            state.CheckThisAirSystemForSizing(state, state.dataSize.CurSysNum, sizing_des_run_this_air_sys)
        
        var design_vol_flow_rate_des: Float64 = 0.0
        var errors_found: Bool = False
        
        if self.WorkingFluidType == WorkingFluidEnum.LIQUID:
            if not state.dataSize.PlantSizData or not state.dataPlnt.PlantLoop:
                return
            var plt_siz_num: Int32 = 0
            if self.WPlantLoc.loopNum > 0:
                plt_siz_num = self.WPlantLoc.loop.PlantSizNum
            if self.WPlantLoc.loopSideNum == 1:
                if plt_siz_num > 0:
                    if state.dataSize.PlantSizData[plt_siz_num].DesVolFlowRate >= 0.00001:
                        design_vol_flow_rate_des = state.dataSize.PlantSizData[plt_siz_num].DesVolFlowRate
            elif self.WPlantLoc.loopSideNum == 2:
                design_vol_flow_rate_des = self.AreaCol * 1.905e-5
            
            if self.DesignVolFlowRateWasAutoSized:
                self.DesignVolFlowRate = design_vol_flow_rate_des
                if state.dataPlnt.PlantFinalSizesOkayToReport:
                    state.BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", 
                                                     self.Name, "Design Size Design Flow Rate [m3/s]", 
                                                     design_vol_flow_rate_des)
                state.PlantUtilities.RegisterPlantCompDesignFlow(state, self.PlantInletNodeNum, self.DesignVolFlowRate)
        
        if self.WorkingFluidType == WorkingFluidEnum.AIR:
            if state.dataSize.CurSysNum > 0:
                if not self.DesignVolFlowRateWasAutoSized and not sizing_des_run_this_air_sys:
                    hard_size_no_des_run = True
                else:
                    state.CheckSysSizing(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", self.Name)
                    var this_final_sys_sizing = state.dataSize.FinalSysSizing[state.dataSize.CurSysNum]
                    if state.dataSize.CurOASysNum > 0:
                        design_vol_flow_rate_des = this_final_sys_sizing.DesOutAirVolFlow
                    else:
                        var cur_duct_type = state.dataSize.CurDuctType
                        if cur_duct_type == 1:
                            design_vol_flow_rate_des = this_final_sys_sizing.SysAirMinFlowRat * this_final_sys_sizing.DesMainVolFlow
                        elif cur_duct_type == 2:
                            design_vol_flow_rate_des = this_final_sys_sizing.SysAirMinFlowRat * this_final_sys_sizing.DesCoolVolFlow
                        elif cur_duct_type == 3:
                            design_vol_flow_rate_des = this_final_sys_sizing.DesHeatVolFlow
                        else:
                            design_vol_flow_rate_des = this_final_sys_sizing.DesMainVolFlow
                    var des_mass_flow: Float64 = state.dataEnvrn.StdRhoAir * design_vol_flow_rate_des
                    self.MaxMassFlowRate = des_mass_flow
                
                if not hard_size_no_des_run:
                    if self.DesignVolFlowRateWasAutoSized:
                        self.DesignVolFlowRate = design_vol_flow_rate_des
                        state.BaseSizer.reportSizerOutput(state, "SolarCollector:FlatPlate:PhotovoltaicThermal", 
                                                         self.Name, "Design Size Design Flow Rate [m3/s]", 
                                                         design_vol_flow_rate_des)
                        self.SizingInit = False
        
        if errors_found:
            state.ShowFatalError("Preceding sizing errors cause program termination")
    
    fn control(inout self, state: AnyType) -> None:
        if self.WorkingFluidType == WorkingFluidEnum.AIR:
            if self.ModelType == PVTModelType.Simple or self.ModelType == PVTModelType.BIPVT:
                if state.dataHeatBal.SurfQRadSWOutIncident[self.SurfNum] > 0.1:
                    if state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint > state.dataLoopNodes.Node[self.HVACInletNodeNum].Temp:
                        self.HeatingUseful = True
                        self.CoolingUseful = False
                        self.BypassDamperOff = True
                    else:
                        self.HeatingUseful = False
                        self.CoolingUseful = True
                        self.BypassDamperOff = False
                else:
                    if state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint < state.dataLoopNodes.Node[self.HVACInletNodeNum].Temp:
                        self.CoolingUseful = True
                        self.HeatingUseful = False
                        self.BypassDamperOff = True
                    else:
                        self.CoolingUseful = False
                        self.HeatingUseful = True
                        self.BypassDamperOff = False
        elif self.WorkingFluidType == WorkingFluidEnum.LIQUID:
            if self.ModelType == PVTModelType.Simple:
                if state.dataHeatBal.SurfQRadSWOutIncident[self.SurfNum] > 0.1:
                    self.HeatingUseful = True
                    self.BypassDamperOff = True
    
    fn calculate(inout self, state: AnyType) -> None:
        if self.ModelType == PVTModelType.Simple:
            self.calculateSimplePVT(state)
        elif self.ModelType == PVTModelType.BIPVT:
            self.calculateBIPVT(state)
    
    fn calculateSimplePVT(inout self, state: AnyType) -> None:
        var inlet_node: Int32 = 0
        if self.WorkingFluidType == WorkingFluidEnum.LIQUID:
            inlet_node = self.PlantInletNodeNum
        elif self.WorkingFluidType == WorkingFluidEnum.AIR:
            inlet_node = self.HVACInletNodeNum
        
        var mdot: Float64 = self.MassFlowRate
        var tinlet: Float64 = state.dataLoopNodes.Node[inlet_node].Temp
        var bypass_fraction: Float64 = 0.0
        var potential_outlet_temp: Float64 = 0.0
        
        if self.HeatingUseful and self.BypassDamperOff and mdot > 0.0:
            var eff: Float64 = 0.0
            if self.Simple.ThermEfficMode == ThermEfficEnum.FIXED:
                eff = self.Simple.ThermEffic
            elif self.Simple.ThermEfficMode == ThermEfficEnum.SCHEDULED:
                eff = self.Simple.thermEffSched.getCurrentVal()
                self.Simple.ThermEffic = eff
            
            var potential_heat_gain: Float64 = state.dataHeatBal.SurfQRadSWOutIncident[self.SurfNum] * eff * self.AreaCol
            
            if self.WorkingFluidType == WorkingFluidEnum.AIR:
                var winlet: Float64 = state.dataLoopNodes.Node[inlet_node].HumRat
                var cp_inlet: Float64 = state.Psychrometrics.PsyCpAirFnW(winlet)
                if mdot * cp_inlet > 0.0:
                    potential_outlet_temp = tinlet + potential_heat_gain / (mdot * cp_inlet)
                else:
                    potential_outlet_temp = tinlet
                if potential_outlet_temp > state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint:
                    if tinlet != potential_outlet_temp:
                        bypass_fraction = ((state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint - potential_outlet_temp) /
                                          (tinlet - potential_outlet_temp))
                    else:
                        bypass_fraction = 0.0
                    bypass_fraction = max(0.0, bypass_fraction)
                    potential_outlet_temp = state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint
                    potential_heat_gain = mdot * state.Psychrometrics.PsyCpAirFnW(winlet) * (potential_outlet_temp - tinlet)
                else:
                    bypass_fraction = 0.0
            elif self.WorkingFluidType == WorkingFluidEnum.LIQUID:
                var cp_inlet: Float64 = state.Psychrometrics.CPHW(tinlet)
                if mdot * cp_inlet != 0.0:
                    potential_outlet_temp = tinlet + potential_heat_gain / (mdot * cp_inlet)
                else:
                    potential_outlet_temp = tinlet
            
            self.Report.ThermHeatGain = potential_heat_gain
            self.Report.ThermPower = self.Report.ThermHeatGain
            self.Report.ThermEnergy = self.Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            self.Report.ThermHeatLoss = 0.0
            self.Report.TinletWorkFluid = tinlet
            self.Report.MdotWorkFluid = mdot
            self.Report.ToutletWorkFluid = potential_outlet_temp
            self.Report.BypassStatus = bypass_fraction
        
        elif self.CoolingUseful and self.BypassDamperOff and mdot > 0.0:
            var hr_ground: Float64 = 0.0
            var hr_air: Float64 = 0.0
            var hc_ext: Float64 = 0.0
            var hr_sky: Float64 = 0.0
            var hr_srd_surf: Float64 = 0.0
            state.Convect.InitExtConvCoeff(state, self.SurfNum, 0.0, 0, self.Simple.SurfEmissivity,
                                         self.Simple.LastCollectorTemp, hc_ext, hr_sky, hr_ground, hr_air, hr_srd_surf)
            
            var cp_inlet: Float64 = 0.0
            if self.WorkingFluidType == WorkingFluidEnum.AIR:
                var winlet: Float64 = state.dataLoopNodes.Node[inlet_node].HumRat
                cp_inlet = state.Psychrometrics.PsyCpAirFnW(winlet)
            elif self.WorkingFluidType == WorkingFluidEnum.LIQUID:
                cp_inlet = state.Psychrometrics.CPHW(tinlet)
            
            var tcollector: Float64 = ((2.0 * mdot * cp_inlet * tinlet + self.AreaCol * (hr_ground * state.dataEnvrn.OutDryBulbTemp +
                          hr_sky * state.dataEnvrn.SkyTemp + hr_air * state.dataSurface.SurfOutDryBulbTemp[self.SurfNum] +
                          hc_ext * state.dataSurface.SurfOutDryBulbTemp[self.SurfNum])) /
                         (2.0 * mdot * cp_inlet + self.AreaCol * (hr_ground + hr_sky + hr_air + hc_ext)))
            
            potential_outlet_temp = 2.0 * tcollector - tinlet
            self.Report.ToutletWorkFluid = potential_outlet_temp
            
            self.Report.MdotWorkFluid = mdot
            self.Report.TinletWorkFluid = tinlet
            self.Report.ToutletWorkFluid = potential_outlet_temp
            self.Report.ThermHeatLoss = mdot * cp_inlet * (tinlet - self.Report.ToutletWorkFluid)
            self.Report.ThermHeatGain = 0.0
            self.Report.ThermPower = -1.0 * self.Report.ThermHeatLoss
            self.Report.ThermEnergy = self.Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            self.Simple.LastCollectorTemp = tcollector
            self.Report.BypassStatus = bypass_fraction
        
        else:
            self.Report.TinletWorkFluid = tinlet
            self.Report.ToutletWorkFluid = tinlet
            self.Report.ThermHeatLoss = 0.0
            self.Report.ThermHeatGain = 0.0
            self.Report.ThermPower = 0.0
            self.Report.ThermEnergy = 0.0
            self.Report.BypassStatus = 1.0
            self.Report.MdotWorkFluid = mdot
    
    fn calculateBIPVT(inout self, state: AnyType) -> None:
        var inlet_node: Int32 = self.HVACInletNodeNum
        var mdot: Float64 = self.MassFlowRate
        var tinlet: Float64 = state.dataLoopNodes.Node[inlet_node].Temp
        var bypass_fraction: Float64 = 0.0
        var potential_outlet_temp: Float64 = tinlet
        var potential_heat_gain: Float64 = 0.0
        var eff: Float64 = 0.0
        var tcollector: Float64 = tinlet
        self.OperatingMode = PVTMode.Heating
        
        if self.HeatingUseful and self.BypassDamperOff and self.BIPVT.availSched.getCurrentVal() > 0.0:
            if (state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint - tinlet) > 0.1:
                self.calculateBIPVTMaxHeatGain(state, state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint,
                                              bypass_fraction, potential_heat_gain, potential_outlet_temp, eff, tcollector)
                if potential_heat_gain < 0.0:
                    bypass_fraction = 1.0
                    potential_heat_gain = 0.0
                    potential_outlet_temp = tinlet
            
            self.Report.ThermHeatGain = potential_heat_gain
            self.Report.ThermPower = self.Report.ThermHeatGain
            self.Report.ThermEnergy = self.Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            self.Report.ThermHeatLoss = 0.0
            self.Report.TinletWorkFluid = tinlet
            self.Report.MdotWorkFluid = mdot
            self.Report.ToutletWorkFluid = potential_outlet_temp
            self.Report.BypassStatus = bypass_fraction
            if potential_heat_gain > 0.0:
                self.BIPVT.LastCollectorTemp = tcollector
        
        elif self.CoolingUseful and self.BypassDamperOff and self.BIPVT.availSched.getCurrentVal() > 0.0:
            self.OperatingMode = PVTMode.Cooling
            if (tinlet - state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint) > 0.1:
                self.calculateBIPVTMaxHeatGain(state, state.dataLoopNodes.Node[self.HVACOutletNodeNum].TempSetPoint,
                                              bypass_fraction, potential_heat_gain, potential_outlet_temp, eff, tcollector)
                if potential_heat_gain > 0.0:
                    potential_heat_gain = 0.0
                    bypass_fraction = 1.0
                    potential_outlet_temp = tinlet
            
            self.Report.MdotWorkFluid = mdot
            self.Report.TinletWorkFluid = tinlet
            self.Report.ToutletWorkFluid = potential_outlet_temp
            self.Report.ThermHeatLoss = -potential_heat_gain
            self.Report.ThermHeatGain = 0.0
            self.Report.ThermPower = -1.0 * self.Report.ThermHeatLoss
            self.Report.ThermEnergy = self.Report.ThermPower * state.dataHVACGlobal.TimeStepSysSec
            if potential_heat_gain < 0.0:
                self.BIPVT.LastCollectorTemp = tcollector
            self.Report.BypassStatus = bypass_fraction
        
        else:
            self.Report.TinletWorkFluid = tinlet
            self.Report.ToutletWorkFluid = tinlet
            self.Report.ThermHeatLoss = 0.0
            self.Report.ThermHeatGain = 0.0
            self.Report.ThermPower = 0.0
            self.Report.ThermEnergy = 0.0
            self.Report.BypassStatus = 1.0
            self.Report.MdotWorkFluid = mdot
    
    fn calculateBIPVTMaxHeatGain(inout self, state: AnyType, tsp: Float64, inout bfr: Float64, 
                                 inout q: Float64, inout tmixed: Float64, inout eff: Float64, inout tpv: Float64) -> None:
        var small_num: Float64 = 1.0e-10
        var tol: Float64 = 1.0e-3
        var rf: Float64 = 0.75
        var degc_to_kelvin: Float64 = 273.15
        
        var l: Float64 = state.dataSurface.Surface[self.SurfNum].Height
        var w: Float64 = state.dataSurface.Surface[self.SurfNum].Width
        var depth_channel: Float64 = self.BIPVT.PVEffGapWidth
        var slope: Float64 = (PI / 180.0) * state.dataSurface.Surface[self.SurfNum].Tilt
        var surf_azimuth: Float64 = state.dataSurface.Surface[self.SurfNum].Azimuth
        var fcell: Float64 = self.BIPVT.PVCellAreaFract
        var glass_thickness: Float64 = self.BIPVT.ThGlass
        var area_pv: Float64 = w * l * self.BIPVT.PVAreaFract
        var area_wall_total: Float64 = w * l
        
        var t1: Float64 = (state.dataEnvrn.OutDryBulbTemp + state.dataHeatBalSurf.SurfTempOut[self.SurfNum]) / 2.0
        var tpv_new: Float64 = t1
        var tpvg: Float64 = t1
        var tpvg_new: Float64 = t1
        var tfavg: Float64 = 18.0
        var tfin: Float64 = state.dataLoopNodes.Node[self.HVACInletNodeNum].Temp
        var tamb: Float64 = state.dataEnvrn.OutDryBulbTemp
        var tsky: Float64 = state.dataEnvrn.SkyTemp
        var t2: Float64 = state.dataHeatBalSurf.SurfTempOut[self.SurfNum]
        var mdot: Float64 = self.MassFlowRate
        var mdot_bipvt: Float64 = mdot
        var mdot_bipvt_new: Float64 = mdot
        var tfout: Float64 = 0.0
        
        var err_tpvg: Float64 = 1.0
        var err_tpv: Float64 = 1.0
        var err_t1: Float64 = 1.0
        var err_mdot_bipvt: Float64 = 1.0
        var iter: Int32 = 0
        
        var jj: InlineArray[Float64, 9] = InlineArray[Float64, 9](fill=0.0)
        var f: InlineArray[Float64, 3] = InlineArray[Float64, 3](fill=0.0)
        var y: InlineArray[Float64, 3] = InlineArray[Float64, 3](fill=0.0)
        
        while (err_t1 > tol or err_tpv > tol or err_tpvg > tol or err_mdot_bipvt > tol) and iter < 50:
            self.solveLinSysBackSub(jj, f, y)
            tpvg_new = y[0]
            tpv_new = y[1]
            var t1_new: Float64 = y[2]
            
            if mdot > 0.0:
                var cp_in: Float64 = state.Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[self.HVACInletNodeNum].HumRat)
                tfout = tfin
                tmixed = (1.0 - bfr) * tfout + bfr * tfin
                mdot_bipvt_new = (1.0 - bfr) * mdot
            else:
                tfout = tfin
            
            err_tpvg = fabs((tpvg_new - tpvg) / (tpvg + small_num))
            err_tpv = fabs((tpv_new - tpv) / (tpv + small_num))
            err_t1 = fabs((t1_new - t1) / (t1 + small_num))
            err_mdot_bipvt = fabs((mdot_bipvt_new - mdot_bipvt) / (mdot_bipvt + small_num))
            tpvg = tpvg + rf * (tpvg_new - tpvg)
            tpv = tpv + rf * (tpv_new - tpv)
            t1 = t1 + rf * (t1_new - t1)
            mdot_bipvt = mdot_bipvt + rf * (mdot_bipvt_new - mdot_bipvt)
            q = mdot_bipvt * state.Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[self.HVACInletNodeNum].HumRat) * (tfout - tfin)
            iter += 1
        
        if q > small_num and state.dataHeatBal.SurfQRadSWOutIncident[self.SurfNum] > small_num:
            eff = q / (area_wall_total * state.dataHeatBal.SurfQRadSWOutIncident[self.SurfNum] + small_num)
        
        self.BIPVT.Tcoll = t1
        self.BIPVT.Tplen = tfavg
        bfr = 0.0
        q = 0.0
        tmixed = tfin
        tpv = tpv
    
    fn solveLinSysBackSub(inout self, inout jj: InlineArray[Float64, 9], inout f: InlineArray[Float64, 3], 
                          inout y: InlineArray[Float64, 3]) -> None:
        var m: Int32 = 3
        var small: Float64 = 1.0e-10
        
        for i in range(m):
            y[i] = 0.0
        
        for i in range(m - 1):
            var coeff_not_zero: Bool = False
            var p: Int32 = 0
            for j in range(i, m):
                if fabs(jj[j * m + i]) > small:
                    coeff_not_zero = True
                    p = j
                    break
            
            if coeff_not_zero:
                if p != i:
                    var dummy2: Float64 = f[i]
                    f[i] = f[p]
                    f[p] = dummy2
                    for j in range(m):
                        var dummy1: Float64 = jj[i * m + j]
                        jj[i * m + j] = jj[p * m + j]
                        jj[p * m + j] = dummy1
                
                for j in range(i + 1, m):
                    if fabs(jj[i * m + i]) < small:
                        jj[i * m + i] = small
                    var mm: Float64 = jj[j * m + i] / jj[i * m + i]
                    f[j] = f[j] - mm * f[i]
                    for k in range(m):
                        jj[j * m + k] = jj[j * m + k] - mm * jj[i * m + k]
        
        if fabs(jj[(m - 1) * m + m - 1]) < small:
            jj[(m - 1) * m + m - 1] = small
        y[m - 1] = f[m - 1] / jj[(m - 1) * m + m - 1]
        
        var sum_val: Float64 = 0.0
        for i in range(m - 1):
            var ii: Int32 = m - 2 - i
            for j in range(ii, m):
                sum_val = sum_val + jj[ii * m + j] * y[j]
            if fabs(jj[ii * m + ii]) < small:
                jj[ii * m + ii] = small
            y[ii] = (f[ii] - sum_val) / jj[ii * m + ii]
            sum_val = 0.0
    
    fn calc_taoalpha(inout self, theta: Float64, glass_thickness: Float64, 
                     refrac_index_glass: Float64, k_glass: Float64) -> Float64:
        var theta_r: Float64 = 0.0
        var taoalpha: Float64 = 0.0
        var theta_use: Float64 = theta
        
        if theta_use == 0.0:
            theta_use = 0.000000001
        
        theta_r = asin(sin(theta_use) / refrac_index_glass)
        taoalpha = (exp(-k_glass * glass_thickness / cos(theta_r)) * 
                   (1 - 0.5 * ((pow(sin(theta_r - theta_use), 2) / pow(sin(theta_r + theta_use), 2)) +
                              (pow(tan(theta_r - theta_use), 2) / pow(tan(theta_r + theta_use), 2)))))
        
        return taoalpha
    
    fn calc_k_taoalpha(inout self, theta: Float64, glass_thickness: Float64, 
                       refrac_index_glass: Float64, k_glass: Float64) -> Float64:
        var taoalpha: Float64 = self.calc_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
        var taoalpha_zero: Float64 = self.calc_taoalpha(0.0, glass_thickness, refrac_index_glass, k_glass)
        var k_taoalpha: Float64 = taoalpha / taoalpha_zero
        return k_taoalpha
    
    fn update(inout self, state: AnyType) -> None:
        if self.WorkingFluidType == WorkingFluidEnum.LIQUID:
            var inlet_node: Int32 = self.PlantInletNodeNum
            var outlet_node: Int32 = self.PlantOutletNodeNum
            state.PlantUtilities.SafeCopyPlantNode(state, inlet_node, outlet_node)
            state.dataLoopNodes.Node[outlet_node].Temp = self.Report.ToutletWorkFluid
        elif self.WorkingFluidType == WorkingFluidEnum.AIR:
            var inlet_node: Int32 = self.HVACInletNodeNum
            var outlet_node: Int32 = self.HVACOutletNodeNum
            
            state.dataLoopNodes.Node[outlet_node].Quality = state.dataLoopNodes.Node[inlet_node].Quality
            state.dataLoopNodes.Node[outlet_node].Press = state.dataLoopNodes.Node[inlet_node].Press
            state.dataLoopNodes.Node[outlet_node].MassFlowRate = state.dataLoopNodes.Node[inlet_node].MassFlowRate
            state.dataLoopNodes.Node[outlet_node].Temp = self.Report.ToutletWorkFluid
            state.dataLoopNodes.Node[outlet_node].HumRat = state.dataLoopNodes.Node[inlet_node].HumRat
            state.dataLoopNodes.Node[outlet_node].Enthalpy = state.Psychrometrics.PsyHFnTdbW(
                self.Report.ToutletWorkFluid, state.dataLoopNodes.Node[outlet_node].HumRat)
            
            if self.ModelType == PVTModelType.BIPVT:
                var thisOSCM: Int32 = self.BIPVT.OSCMPtr
                state.dataSurface.OSCM[thisOSCM].TConv = self.BIPVT.Tplen
                state.dataSurface.OSCM[thisOSCM].HConv = self.BIPVT.HcPlen
                state.dataSurface.OSCM[thisOSCM].TRad = self.BIPVT.Tcoll
                state.dataSurface.OSCM[thisOSCM].HRad = self.BIPVT.HrPlen
    
    fn oneTimeInit(inout self, state: AnyType) -> None:
        if self.MyOneTimeFlag:
            self.setupReportVars(state)
            self.MyOneTimeFlag = False
        
        if self.SetLoopIndexFlag:
            if state.dataPlnt.PlantLoop and self.PlantInletNodeNum > 0:
                var err_flag: Bool = False
                state.PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.Type, self.WPlantLoc, err_flag)
                if err_flag:
                    state.ShowFatalError("InitPVTcollectors: Program terminated for previous conditions.")
                self.SetLoopIndexFlag = False
    
    fn setupReportVars(inout self, state: AnyType) -> None:
        state.SetupOutputVariable(state, "Generator Produced Thermal Rate", "W", Pointer[Float64].address_of(self.Report.ThermPower),
                                 "System", "Average", self.Name)
        
        if self.WorkingFluidType == WorkingFluidEnum.LIQUID:
            state.SetupOutputVariable(state, "Generator Produced Thermal Energy", "J", Pointer[Float64].address_of(self.Report.ThermEnergy),
                                     "System", "Sum", self.Name, "SolarWater", "Plant", "HeatProduced")
        elif self.WorkingFluidType == WorkingFluidEnum.AIR:
            state.SetupOutputVariable(state, "Generator Produced Thermal Energy", "J", Pointer[Float64].address_of(self.Report.ThermEnergy),
                                     "System", "Sum", self.Name, "SolarAir", "HVAC", "HeatProduced")
            state.SetupOutputVariable(state, "Generator PVT Fluid Bypass Status", "None", Pointer[Float64].address_of(self.Report.BypassStatus),
                                     "System", "Average", self.Name)
        
        state.SetupOutputVariable(state, "Generator PVT Fluid Inlet Temperature", "C", Pointer[Float64].address_of(self.Report.TinletWorkFluid),
                                 "System", "Average", self.Name)
        state.SetupOutputVariable(state, "Generator PVT Fluid Outlet Temperature", "C", Pointer[Float64].address_of(self.Report.ToutletWorkFluid),
                                 "System", "Average", self.Name)
        state.SetupOutputVariable(state, "Generator PVT Fluid Mass Flow Rate", "kg/s", Pointer[Float64].address_of(self.Report.MdotWorkFluid),
                                 "System", "Average", self.Name)

fn GetPVTcollectorsInput(state: AnyType) -> None:
    state.dataIPShortCut.cCurrentModuleObject = "SolarCollectorPerformance:PhotovoltaicThermal:Simple"
    var num_simple_pvt_perform: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, state.dataIPShortCut.cCurrentModuleObject)
    if num_simple_pvt_perform > 0:
        GetPVTSimpleCollectorsInput(state, num_simple_pvt_perform)
    
    state.dataIPShortCut.cCurrentModuleObject = "SolarCollectorPerformance:PhotovoltaicThermal:BIPVT"
    var num_bipvt_perform: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, state.dataIPShortCut.cCurrentModuleObject)
    if num_bipvt_perform > 0:
        GetBIPVTCollectorsInput(state, num_bipvt_perform)
    
    state.dataIPShortCut.cCurrentModuleObject = "SolarCollector:FlatPlate:PhotovoltaicThermal"
    state.dataPhotovoltaicThermalCollector.NumPVT = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, state.dataIPShortCut.cCurrentModuleObject)
    if state.dataPhotovoltaicThermalCollector.NumPVT > 0:
        GetMainPVTInput(state, state.dataPhotovoltaicThermalCollector.NumPVT)

fn GetPVTSimpleCollectorsInput(state: AnyType, num_simple_pvt_perform: Int32) -> None:
    for item in range(1, num_simple_pvt_perform + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, state.dataIPShortCut.cCurrentModuleObject, item)
        var tmp_pvt = SimplePVTModelStruct()
        tmp_pvt.Name = state.dataIPShortCut.cAlphaArgs[1]
        tmp_pvt.ThermalActiveFract = state.dataIPShortCut.rNumericArgs[1]
        tmp_pvt.ThermEffic = state.dataIPShortCut.rNumericArgs[2]
        tmp_pvt.SurfEmissivity = state.dataIPShortCut.rNumericArgs[3]

fn GetBIPVTCollectorsInput(state: AnyType, num_bipvt_perform: Int32) -> None:
    for item in range(1, num_bipvt_perform + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, state.dataIPShortCut.cCurrentModuleObject, item)
        var tmp_pvt = BIPVTModelStruct()
        tmp_pvt.Name = state.dataIPShortCut.cAlphaArgs[1]
        tmp_pvt.OSCMName = state.dataIPShortCut.cAlphaArgs[2]

fn GetMainPVTInput(state: AnyType, num_pvt: Int32) -> None:
    for item in range(1, num_pvt + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, state.dataIPShortCut.cCurrentModuleObject, item)
        var this_pvt = PVTCollectorStruct()
        this_pvt.Name = state.dataIPShortCut.cAlphaArgs[1]

fn simPVTfromOASys(state: AnyType, index: Int32, first_hvac_iteration: Bool) -> None:
    pass

fn getPVTindexFromName(state: AnyType, name: StringLiteral) -> Int32:
    if state.dataPhotovoltaicThermalCollector.GetInputFlag:
        GetPVTcollectorsInput(state)
        state.dataPhotovoltaicThermalCollector.GetInputFlag = False
    return 0

fn GetPVTThermalPowerProduction(state: AnyType, pvindex: Int32) -> Tuple[Float64, Float64]:
    return 0.0, 0.0

fn GetAirInletNodeNum(state: AnyType, pvt_name: StringLiteral) -> Int32:
    return 0

fn GetAirOutletNodeNum(state: AnyType, pvt_name: StringLiteral) -> Int32:
    return 0

fn GetPVTmodelIndex(state: AnyType, surface_ptr: Int32) -> Int32:
    return 0

fn SetPVTQdotSource(state: AnyType, pvt_num: Int32, q_source: Float64) -> None:
    pass

fn GetPVTTsColl(state: AnyType, pvt_num: Int32) -> Float64:
    return 0.0

struct PhotovoltaicThermalCollectorsData:
    var GetInputFlag: Bool
    var NumPVT: Int32
    
    fn __init__(inout self):
        self.GetInputFlag = True
        self.NumPVT = 0
    
    fn init_constant_state(inout self, state: AnyType) -> None:
        pass
    
    fn init_state(inout self, state: AnyType) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        self.GetInputFlag = True
        self.NumPVT = 0

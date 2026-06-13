# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing dataChillerGasAbsorption, dataLoopNodes, dataGlobal, etc.
# - PlantComponent: base struct trait for component methods
# - PlantLocation: struct with loop, branch, loopNum, loopSideNum, side fields
# - Curve: struct with value(state, x, y) method
# - DataPlant: enums (BrLoopType, PlantEquipmentType, FlowLock, LoopDemandCalcScheme)
# - Various utility function stubs for error handling, plant utilities, curves, nodes

from math import abs as math_abs, copysign, min as math_min, max as math_max

alias Real64 = Float64

struct PlantLocation:
    loopNum: Int32
    loopSideNum: Int32
    loop: AnyPointer[NoneType]
    branch: AnyPointer[NoneType]
    side: AnyPointer[NoneType]

struct Curve:
    pass

struct GasAbsorberSpecs:
    var Available: Bool
    var ON: Bool
    var InCoolingMode: Bool
    var InHeatingMode: Bool
    var Name: String
    var FuelType: Int32
    var NomCoolingCap: Real64
    var NomCoolingCapWasAutoSized: Bool
    var NomHeatCoolRatio: Real64
    var FuelCoolRatio: Real64
    var FuelHeatRatio: Real64
    var ElecCoolRatio: Real64
    var ElecHeatRatio: Real64
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
    var MinPartLoadRat: Real64
    var MaxPartLoadRat: Real64
    var OptPartLoadRat: Real64
    var TempDesCondReturn: Real64
    var TempDesCHWSupply: Real64
    var EvapVolFlowRate: Real64
    var EvapVolFlowRateWasAutoSized: Bool
    var CondVolFlowRate: Real64
    var CondVolFlowRateWasAutoSized: Bool
    var HeatVolFlowRate: Real64
    var HeatVolFlowRateWasAutoSized: Bool
    var SizFac: Real64
    var CoolCapFTCurve: AnyPointer[Curve]
    var FuelCoolFTCurve: AnyPointer[Curve]
    var FuelCoolFPLRCurve: AnyPointer[Curve]
    var ElecCoolFTCurve: AnyPointer[Curve]
    var ElecCoolFPLRCurve: AnyPointer[Curve]
    var HeatCapFCoolCurve: AnyPointer[Curve]
    var FuelHeatFHPLRCurve: AnyPointer[Curve]
    var isEnterCondensTemp: Bool
    var isWaterCooled: Bool
    var CHWLowLimitTemp: Real64
    var FuelHeatingValue: Real64
    var DesCondMassFlowRate: Real64
    var DesHeatMassFlowRate: Real64
    var DesEvapMassFlowRate: Real64
    var DeltaTempCoolErrCount: Int32
    var DeltaTempHeatErrCount: Int32
    var CondErrCount: Int32
    var lCondWaterMassFlowRate_Index: Int32
    var PossibleSubcooling: Bool
    var CWplantLoc: PlantLocation
    var CDplantLoc: PlantLocation
    var HWplantLoc: PlantLocation
    var envrnFlag: Bool
    var oldCondSupplyTemp: Real64
    var CoolingLoad: Real64
    var CoolingEnergy: Real64
    var HeatingLoad: Real64
    var HeatingEnergy: Real64
    var TowerLoad: Real64
    var TowerEnergy: Real64
    var FuelUseRate: Real64
    var FuelEnergy: Real64
    var CoolFuelUseRate: Real64
    var CoolFuelEnergy: Real64
    var HeatFuelUseRate: Real64
    var HeatFuelEnergy: Real64
    var ElectricPower: Real64
    var ElectricEnergy: Real64
    var CoolElectricPower: Real64
    var CoolElectricEnergy: Real64
    var HeatElectricPower: Real64
    var HeatElectricEnergy: Real64
    var ChillReturnTemp: Real64
    var ChillSupplyTemp: Real64
    var ChillWaterFlowRate: Real64
    var CondReturnTemp: Real64
    var CondSupplyTemp: Real64
    var CondWaterFlowRate: Real64
    var HotWaterReturnTemp: Real64
    var HotWaterSupplyTemp: Real64
    var HotWaterFlowRate: Real64
    var CoolPartLoadRatio: Real64
    var HeatPartLoadRatio: Real64
    var CoolingCapacity: Real64
    var HeatingCapacity: Real64
    var FractionOfPeriodRunning: Real64
    var FuelCOP: Real64

    fn __init__(inout self):
        self.Available = False
        self.ON = False
        self.InCoolingMode = False
        self.InHeatingMode = False
        self.Name = ""
        self.FuelType = 0
        self.NomCoolingCap = 0.0
        self.NomCoolingCapWasAutoSized = False
        self.NomHeatCoolRatio = 0.0
        self.FuelCoolRatio = 0.0
        self.FuelHeatRatio = 0.0
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
        self.isEnterCondensTemp = False
        self.isWaterCooled = False
        self.CHWLowLimitTemp = 0.0
        self.FuelHeatingValue = 0.0
        self.DesCondMassFlowRate = 0.0
        self.DesHeatMassFlowRate = 0.0
        self.DesEvapMassFlowRate = 0.0
        self.DeltaTempCoolErrCount = 0
        self.DeltaTempHeatErrCount = 0
        self.CondErrCount = 0
        self.lCondWaterMassFlowRate_Index = 0
        self.PossibleSubcooling = False
        self.envrnFlag = True
        self.oldCondSupplyTemp = 0.0
        self.CoolingLoad = 0.0
        self.CoolingEnergy = 0.0
        self.HeatingLoad = 0.0
        self.HeatingEnergy = 0.0
        self.TowerLoad = 0.0
        self.TowerEnergy = 0.0
        self.FuelUseRate = 0.0
        self.FuelEnergy = 0.0
        self.CoolFuelUseRate = 0.0
        self.CoolFuelEnergy = 0.0
        self.HeatFuelUseRate = 0.0
        self.HeatFuelEnergy = 0.0
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
        self.FuelCOP = 0.0

    @staticmethod
    fn factory(state: AnyPointer[NoneType], object_name: String) -> AnyPointer[GasAbsorberSpecs]:
        if state.dataChillerGasAbsorption.getGasAbsorberInputs:
            GetGasAbsorberInput(state)
            state.dataChillerGasAbsorption.getGasAbsorberInputs = False
        
        for i in range(len(state.dataChillerGasAbsorption.GasAbsorber)):
            if state.dataChillerGasAbsorption.GasAbsorber[i].Name == object_name:
                return AnyPointer[GasAbsorberSpecs](state.dataChillerGasAbsorption.GasAbsorber[i])
        
        ShowFatalError(state, "LocalGasAbsorberFactory: Error getting inputs for comp named: " + object_name)
        return AnyPointer[GasAbsorberSpecs]()

    fn simulate(inout self, state: AnyPointer[NoneType], called_from_location: PlantLocation, 
                first_hvac_iteration: Bool, cur_load: Real64, run_flag: Bool) -> Real64:
        var br_identity: Int32 = 0
        var branch_total_comp: Int32 = called_from_location.branch.TotalComponents
        
        for i_comp in range(1, branch_total_comp + 1):
            var comp_inlet_node_num: Int32 = called_from_location.branch.Comp(i_comp).NodeNumIn
            if comp_inlet_node_num == self.ChillReturnNodeNum:
                br_identity = 1
                break
            if comp_inlet_node_num == self.HeatReturnNodeNum:
                br_identity = 2
                break
            if comp_inlet_node_num == self.CondReturnNodeNum:
                br_identity = 3
                break
            br_identity = 0
        
        if br_identity == 1:
            self.InCoolingMode = run_flag
            self.initialize(state)
            self.calculateChiller(state, cur_load)
            self.updateCoolRecords(state, cur_load, run_flag)
        elif br_identity == 2:
            self.InHeatingMode = run_flag
            self.initialize(state)
            self.calculateHeater(state, cur_load, run_flag)
            self.updateHeatRecords(state, cur_load, run_flag)
        elif br_identity == 3:
            if self.CDplantLoc.loopNum > 0:
                PlantUtilities_UpdateChillerComponentCondenserSide(
                    state, self.CDplantLoc.loopNum, self.CDplantLoc.loopSideNum,
                    3, self.CondReturnNodeNum, self.CondSupplyNodeNum,
                    self.TowerLoad, self.CondReturnTemp, self.CondSupplyTemp,
                    self.CondWaterFlowRate, first_hvac_iteration
                )
        else:
            ShowSevereError(state, "Invalid call to Gas Absorber Chiller " + self.Name)
            ShowContinueError(state, "Node connections in branch are not consistent with object nodes.")
            ShowFatalError(state, "Preceding conditions cause termination.")
        
        return cur_load

    fn getDesignCapacities(inout self, state: AnyPointer[NoneType], called_from_location: PlantLocation) -> (Real64, Real64, Real64):
        var match_found: Bool = False
        var min_load: Real64 = 0.0
        var max_load: Real64 = 0.0
        var opt_load: Real64 = 0.0
        
        var branch_total_comp: Int32 = called_from_location.branch.TotalComponents
        for i_comp in range(1, branch_total_comp + 1):
            var comp_inlet_node_num: Int32 = called_from_location.branch.Comp(i_comp).NodeNumIn
            if comp_inlet_node_num == self.ChillReturnNodeNum:
                min_load = self.NomCoolingCap * self.MinPartLoadRat
                max_load = self.NomCoolingCap * self.MaxPartLoadRat
                opt_load = self.NomCoolingCap * self.OptPartLoadRat
                match_found = True
                break
            if comp_inlet_node_num == self.HeatReturnNodeNum:
                var sim_heat_cap: Real64 = self.NomCoolingCap * self.NomHeatCoolRatio
                min_load = sim_heat_cap * self.MinPartLoadRat
                max_load = sim_heat_cap * self.MaxPartLoadRat
                opt_load = sim_heat_cap * self.OptPartLoadRat
                match_found = True
                break
            if comp_inlet_node_num == self.CondReturnNodeNum:
                min_load = 0.0
                max_load = 0.0
                opt_load = 0.0
                match_found = True
                break
            match_found = False
        
        if not match_found:
            ShowSevereError(state, "SimGasAbsorber: Invalid call to Gas Absorption Chiller-Heater " + self.Name)
            ShowContinueError(state, "Node connections in branch are not consistent with object nodes.")
            ShowFatalError(state, "Preceding conditions cause termination.")
        
        return (min_load, max_load, opt_load)

    fn getSizingFactor(self) -> Real64:
        return self.SizFac

    fn onInitLoopEquip(inout self, state: AnyPointer[NoneType], called_from_location: PlantLocation) -> None:
        self.initialize(state)
        
        var branch_inlet_node_num: Int32 = called_from_location.branch.NodeNumIn
        if branch_inlet_node_num == self.ChillReturnNodeNum:
            self.size(state)

    fn getDesignTemperatures(self) -> (Real64, Real64):
        return (self.TempDesCHWSupply, self.TempDesCondReturn)

    fn initialize(inout self, state: AnyPointer[NoneType]) -> None:
        var rho: Real64 = 0.0
        var mdot: Real64 = 0.0
        
        if self.envrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            if self.isWaterCooled:
                if self.CDplantLoc.loopNum > 0:
                    rho = self.CDplantLoc.loop.glycol.getDensity(state, 4.0, "InitGasAbsorber")
                else:
                    rho = Psychrometrics_RhoH2O(4.0)
                self.DesCondMassFlowRate = rho * self.CondVolFlowRate
                PlantUtilities_InitComponentNodes(state, 0.0, self.DesCondMassFlowRate, self.CondReturnNodeNum, self.CondSupplyNodeNum)
            
            if self.HWplantLoc.loopNum > 0:
                rho = self.HWplantLoc.loop.glycol.getDensity(state, 60.0, "InitGasAbsorber")
            else:
                rho = Psychrometrics_RhoH2O(4.0)
            self.DesHeatMassFlowRate = rho * self.HeatVolFlowRate
            PlantUtilities_InitComponentNodes(state, 0.0, self.DesHeatMassFlowRate, self.HeatReturnNodeNum, self.HeatSupplyNodeNum)
            
            if self.CWplantLoc.loopNum > 0:
                rho = self.CWplantLoc.loop.glycol.getDensity(state, 4.0, "InitGasAbsorber")
            else:
                rho = Psychrometrics_RhoH2O(4.0)
            self.DesEvapMassFlowRate = rho * self.EvapVolFlowRate
            PlantUtilities_InitComponentNodes(state, 0.0, self.DesEvapMassFlowRate, self.ChillReturnNodeNum, self.ChillSupplyNodeNum)
            
            self.envrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.envrnFlag = True
        
        if self.ChillSetPointSetToLoop:
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPoint = \
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPointHi = \
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPointHi
        
        if self.HeatSetPointSetToLoop:
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPoint = \
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPointLo = \
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPointLo
        
        if self.isWaterCooled and (self.InHeatingMode or self.InCoolingMode):
            mdot = self.DesCondMassFlowRate
            PlantUtilities_SetComponentFlowRate(state, mdot, self.CondReturnNodeNum, self.CondSupplyNodeNum, self.CDplantLoc)
        else:
            mdot = 0.0
            if self.CDplantLoc.loopNum > 0 and self.isWaterCooled:
                PlantUtilities_SetComponentFlowRate(state, mdot, self.CondReturnNodeNum, self.CondSupplyNodeNum, self.CDplantLoc)

    fn size(inout self, state: AnyPointer[NoneType]) -> None:
        var tmp_nom_cap: Real64 = self.NomCoolingCap
        var tmp_evap_vol_flow_rate: Real64 = self.EvapVolFlowRate
        var tmp_cond_vol_flow_rate: Real64 = self.CondVolFlowRate
        var tmp_heat_rec_vol_flow_rate: Real64 = self.HeatVolFlowRate
        
        var plt_siz_cond_num: Int32 = 0
        if self.isWaterCooled:
            plt_siz_cond_num = self.CDplantLoc.loop.PlantSizNum
        var plt_siz_heat_num: Int32 = self.HWplantLoc.loop.PlantSizNum
        var plt_siz_cool_num: Int32 = self.CWplantLoc.loop.PlantSizNum
        
        var errors_found: Bool = False
        
        if plt_siz_cool_num > 0:
            if state.dataSize.PlantSizData[plt_siz_cool_num].DesVolFlowRate >= 5.0e-8:
                var cp: Real64 = self.CWplantLoc.loop.glycol.getSpecificHeat(state, 4.0, "SizeGasAbsorber")
                var rho: Real64 = self.CWplantLoc.loop.glycol.getDensity(state, 4.0, "SizeGasAbsorber")
                tmp_nom_cap = cp * rho * state.dataSize.PlantSizData[plt_siz_cool_num].DeltaT * \
                              state.dataSize.PlantSizData[plt_siz_cool_num].DesVolFlowRate * self.SizFac
                if not self.NomCoolingCapWasAutoSized:
                    tmp_nom_cap = self.NomCoolingCap
            else:
                if self.NomCoolingCapWasAutoSized:
                    tmp_nom_cap = 0.0
            
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCoolingCapWasAutoSized:
                    self.NomCoolingCap = tmp_nom_cap
        else:
            if self.NomCoolingCapWasAutoSized:
                if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "SizeGasAbsorber: ChillerHeater:Absorption:DirectFired=\"" + self.Name + "\", autosize error.")
                    errors_found = True
        
        if plt_siz_cool_num > 0:
            if state.dataSize.PlantSizData[plt_siz_cool_num].DesVolFlowRate >= 5.0e-8:
                tmp_evap_vol_flow_rate = state.dataSize.PlantSizData[plt_siz_cool_num].DesVolFlowRate * self.SizFac
                if not self.EvapVolFlowRateWasAutoSized:
                    tmp_evap_vol_flow_rate = self.EvapVolFlowRate
        
        PlantUtilities_RegisterPlantCompDesignFlow(state, self.ChillReturnNodeNum, tmp_evap_vol_flow_rate)
        
        if plt_siz_heat_num > 0:
            if state.dataSize.PlantSizData[plt_siz_heat_num].DesVolFlowRate >= 5.0e-8:
                tmp_heat_rec_vol_flow_rate = state.dataSize.PlantSizData[plt_siz_heat_num].DesVolFlowRate * self.SizFac
                if not self.HeatVolFlowRateWasAutoSized:
                    tmp_heat_rec_vol_flow_rate = self.HeatVolFlowRate
        
        PlantUtilities_RegisterPlantCompDesignFlow(state, self.HeatReturnNodeNum, tmp_heat_rec_vol_flow_rate)
        
        if plt_siz_cond_num > 0 and plt_siz_cool_num > 0:
            if state.dataSize.PlantSizData[plt_siz_cool_num].DesVolFlowRate >= 5.0e-8 and tmp_nom_cap > 0.0:
                var cp: Real64 = self.CDplantLoc.loop.glycol.getSpecificHeat(state, self.TempDesCondReturn, "SizeGasAbsorber")
                var rho: Real64 = self.CDplantLoc.loop.glycol.getDensity(state, self.TempDesCondReturn, "SizeGasAbsorber")
                tmp_cond_vol_flow_rate = tmp_nom_cap * (1.0 + self.FuelCoolRatio) / \
                                        (state.dataSize.PlantSizData[plt_siz_cond_num].DeltaT * cp * rho)
                if not self.CondVolFlowRateWasAutoSized:
                    tmp_cond_vol_flow_rate = self.CondVolFlowRate
            
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.CondVolFlowRateWasAutoSized:
                    self.CondVolFlowRate = tmp_cond_vol_flow_rate
        
        if self.isWaterCooled:
            PlantUtilities_RegisterPlantCompDesignFlow(state, self.CondReturnNodeNum, tmp_cond_vol_flow_rate)
        
        if errors_found:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    fn setupOutputVariables(inout self, state: AnyPointer[NoneType]) -> None:
        SetupOutputVariable(state, "Chiller Heater Evaporator Cooling Rate", "W", self.CoolingLoad, self.Name)
        SetupOutputVariable(state, "Chiller Heater Evaporator Cooling Energy", "J", self.CoolingEnergy, self.Name)
        SetupOutputVariable(state, "Chiller Heater Heating Rate", "W", self.HeatingLoad, self.Name)
        SetupOutputVariable(state, "Chiller Heater Heating Energy", "J", self.HeatingEnergy, self.Name)
        SetupOutputVariable(state, "Chiller Heater Condenser Heat Transfer Rate", "W", self.TowerLoad, self.Name)
        SetupOutputVariable(state, "Chiller Heater Condenser Heat Transfer Energy", "J", self.TowerEnergy, self.Name)
        SetupOutputVariable(state, "Chiller Heater Electricity Rate", "W", self.ElectricPower, self.Name)
        SetupOutputVariable(state, "Chiller Heater Electricity Energy", "J", self.ElectricEnergy, self.Name)
        SetupOutputVariable(state, "Chiller Heater Cooling Electricity Rate", "W", self.CoolElectricPower, self.Name)
        SetupOutputVariable(state, "Chiller Heater Cooling Electricity Energy", "J", self.CoolElectricEnergy, self.Name)
        SetupOutputVariable(state, "Chiller Heater Heating Electricity Rate", "W", self.HeatElectricPower, self.Name)
        SetupOutputVariable(state, "Chiller Heater Heating Electricity Energy", "J", self.HeatElectricEnergy, self.Name)
        SetupOutputVariable(state, "Chiller Heater Evaporator Inlet Temperature", "C", self.ChillReturnTemp, self.Name)
        SetupOutputVariable(state, "Chiller Heater Evaporator Outlet Temperature", "C", self.ChillSupplyTemp, self.Name)
        SetupOutputVariable(state, "Chiller Heater Evaporator Mass Flow Rate", "kg/s", self.ChillWaterFlowRate, self.Name)
        
        if self.isWaterCooled:
            SetupOutputVariable(state, "Chiller Heater Condenser Inlet Temperature", "C", self.CondReturnTemp, self.Name)
            SetupOutputVariable(state, "Chiller Heater Condenser Outlet Temperature", "C", self.CondSupplyTemp, self.Name)
            SetupOutputVariable(state, "Chiller Heater Condenser Mass Flow Rate", "kg/s", self.CondWaterFlowRate, self.Name)
        
        SetupOutputVariable(state, "Chiller Heater Heating Inlet Temperature", "C", self.HotWaterReturnTemp, self.Name)
        SetupOutputVariable(state, "Chiller Heater Heating Outlet Temperature", "C", self.HotWaterSupplyTemp, self.Name)
        SetupOutputVariable(state, "Chiller Heater Heating Mass Flow Rate", "kg/s", self.HotWaterFlowRate, self.Name)
        SetupOutputVariable(state, "Chiller Heater Cooling Part Load Ratio", "", self.CoolPartLoadRatio, self.Name)
        SetupOutputVariable(state, "Chiller Heater Maximum Cooling Rate", "W", self.CoolingCapacity, self.Name)
        SetupOutputVariable(state, "Chiller Heater Heating Part Load Ratio", "", self.HeatPartLoadRatio, self.Name)
        SetupOutputVariable(state, "Chiller Heater Maximum Heating Rate", "W", self.HeatingCapacity, self.Name)
        SetupOutputVariable(state, "Chiller Heater Runtime Fraction", "", self.FractionOfPeriodRunning, self.Name)

    fn oneTimeInit_new(inout self, state: AnyPointer[NoneType]) -> None:
        self.setupOutputVariables(state)
        
        var err_flag: Bool = False
        PlantUtilities_ScanPlantLoopsForObject(state, self.Name, 3, self.CWplantLoc, err_flag, 
                                              self.CHWLowLimitTemp, self.ChillReturnNodeNum)
        if err_flag:
            ShowFatalError(state, "InitGasAbsorber: Program terminated due to previous condition(s).")
        
        PlantUtilities_ScanPlantLoopsForObject(state, self.Name, 3, self.HWplantLoc, err_flag,
                                              0.0, self.HeatReturnNodeNum)
        if err_flag:
            ShowFatalError(state, "InitGasAbsorber: Program terminated due to previous condition(s).")
        
        if self.isWaterCooled:
            PlantUtilities_ScanPlantLoopsForObject(state, self.Name, 3, self.CDplantLoc, err_flag,
                                                  0.0, self.CondReturnNodeNum)
            if err_flag:
                ShowFatalError(state, "InitGasAbsorber: Program terminated due to previous condition(s).")
            PlantUtilities_InterConnectTwoPlantLoopSides(state, self.CWplantLoc, self.CDplantLoc, 3, True)
            PlantUtilities_InterConnectTwoPlantLoopSides(state, self.HWplantLoc, self.CDplantLoc, 3, True)
        
        PlantUtilities_InterConnectTwoPlantLoopSides(state, self.CWplantLoc, self.HWplantLoc, 3, True)
        
        if (state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPoint == -9999.0 and
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPointHi == -9999.0):
            if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                if not self.ChillSetPointErrDone:
                    ShowWarningError(state, "Missing temperature setpoint on cool side for chiller heater named " + self.Name)
                    self.ChillSetPointErrDone = True
            else:
                err_flag = False
                EMSManager_CheckIfNodeSetPointManagedByEMS(state, self.ChillSupplyNodeNum, "Temp", err_flag)
                if err_flag:
                    if not self.ChillSetPointErrDone:
                        ShowWarningError(state, "Missing temperature setpoint on cool side for chiller heater named " + self.Name)
                        self.ChillSetPointErrDone = True
            
            self.ChillSetPointSetToLoop = True
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPoint = \
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPointHi = \
                state.dataLoopNodes.Node[self.CWplantLoc.loop.TempSetPointNodeNum].TempSetPointHi
        
        if (state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPoint == -9999.0 and
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPointLo == -9999.0):
            if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                if not self.HeatSetPointErrDone:
                    ShowWarningError(state, "Missing temperature setpoint on heat side for chiller heater named " + self.Name)
                    self.HeatSetPointErrDone = True
            else:
                err_flag = False
                EMSManager_CheckIfNodeSetPointManagedByEMS(state, self.HeatSupplyNodeNum, "Temp", err_flag)
                if err_flag:
                    if not self.HeatSetPointErrDone:
                        ShowWarningError(state, "Missing temperature setpoint on heat side for chiller heater named " + self.Name)
                        self.HeatSetPointErrDone = True
            
            self.HeatSetPointSetToLoop = True
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPoint = \
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPoint
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPointLo = \
                state.dataLoopNodes.Node[self.HWplantLoc.loop.TempSetPointNodeNum].TempSetPointLo

    fn calculateChiller(inout self, state: AnyPointer[NoneType], my_load: Real64) -> None:
        var l_cooling_load: Real64 = 0.0
        var l_tower_load: Real64 = 0.0
        var l_cool_fuel_use_rate: Real64 = 0.0
        var l_cool_electric_power: Real64 = 0.0
        var l_chill_supply_temp: Real64 = 0.0
        var l_cond_supply_temp: Real64 = 0.0
        var l_cond_water_mass_flow_rate: Real64 = 0.0
        var l_cool_part_load_ratio: Real64 = 0.0
        var l_available_cooling_capacity: Real64 = 0.0
        var l_fraction_of_period_running: Real64 = 0.0
        
        var l_nom_cooling_cap: Real64 = self.NomCoolingCap
        var l_fuel_cool_ratio: Real64 = self.FuelCoolRatio
        var l_fuel_heat_ratio: Real64 = self.FuelHeatRatio
        var l_elec_cool_ratio: Real64 = self.ElecCoolRatio
        var l_min_part_load_rat: Real64 = self.MinPartLoadRat
        var l_max_part_load_rat: Real64 = self.MaxPartLoadRat
        var l_is_enter_condens_temp: Bool = self.isEnterCondensTemp
        var l_is_water_cooled: Bool = self.isWaterCooled
        var l_chw_low_limit_temp: Real64 = self.CHWLowLimitTemp
        
        var l_heat_electric_power: Real64 = self.HeatElectricPower
        var l_heat_fuel_use_rate: Real64 = self.HeatFuelUseRate
        var l_heat_part_load_ratio: Real64 = self.HeatPartLoadRatio
        
        var l_chill_return_temp: Real64 = state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp
        var l_chill_water_mass_flow_rate: Real64 = state.dataLoopNodes.Node[self.ChillReturnNodeNum].MassFlowRate
        var l_cond_return_temp: Real64 = state.dataLoopNodes.Node[self.CondReturnNodeNum].Temp
        
        var chill_supply_set_point_temp: Real64
        if self.CWplantLoc.loop.LoopDemandCalcScheme == 1:
            chill_supply_set_point_temp = state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPoint
        else:
            chill_supply_set_point_temp = state.dataLoopNodes.Node[self.ChillSupplyNodeNum].TempSetPointHi
        
        var chill_delta_temp: Real64 = math_abs(l_chill_return_temp - chill_supply_set_point_temp)
        
        var cp_cw: Real64 = self.CWplantLoc.loop.glycol.getSpecificHeat(state, l_chill_return_temp, "CalcGasAbsorberChillerModel")
        var cp_cd: Real64 = 0.0
        if self.CDplantLoc.loopNum > 0:
            cp_cd = self.CDplantLoc.loop.glycol.getSpecificHeat(state, l_chill_return_temp, "CalcGasAbsorberChillerModel")
        
        if my_load >= 0 or not (self.InHeatingMode or self.InCoolingMode):
            l_chill_supply_temp = l_chill_return_temp
            l_cond_supply_temp = l_cond_return_temp
            l_cond_water_mass_flow_rate = 0.0
            if l_is_water_cooled:
                PlantUtilities_SetComponentFlowRate(state, l_cond_water_mass_flow_rate, self.CondReturnNodeNum,
                                                   self.CondSupplyNodeNum, self.CDplantLoc)
            l_fraction_of_period_running = math_min(1.0, math_max(l_heat_part_load_ratio, l_cool_part_load_ratio) / l_min_part_load_rat)
        else:
            var calc_cond_temp: Real64
            if l_is_water_cooled:
                l_cond_return_temp = state.dataLoopNodes.Node[self.CondReturnNodeNum].Temp
                if l_is_enter_condens_temp:
                    calc_cond_temp = l_cond_return_temp
                else:
                    if self.oldCondSupplyTemp == 0:
                        self.oldCondSupplyTemp = l_cond_return_temp + 8.0
                    calc_cond_temp = self.oldCondSupplyTemp
                l_cond_water_mass_flow_rate = self.DesCondMassFlowRate
                PlantUtilities_SetComponentFlowRate(state, l_cond_water_mass_flow_rate, self.CondReturnNodeNum,
                                                   self.CondSupplyNodeNum, self.CDplantLoc)
            else:
                state.dataLoopNodes.Node[self.CondReturnNodeNum].Temp = state.dataLoopNodes.Node[self.CondReturnNodeNum].OutAirDryBulb
                calc_cond_temp = state.dataLoopNodes.Node[self.CondReturnNodeNum].OutAirDryBulb
                l_cond_return_temp = state.dataLoopNodes.Node[self.CondReturnNodeNum].Temp
                l_cond_water_mass_flow_rate = 0.0
                if self.CDplantLoc.loopNum > 0:
                    PlantUtilities_SetComponentFlowRate(state, l_cond_water_mass_flow_rate, self.CondReturnNodeNum,
                                                       self.CondSupplyNodeNum, self.CDplantLoc)
            
            l_available_cooling_capacity = l_nom_cooling_cap * self.CoolCapFTCurve.value(state, chill_supply_set_point_temp, calc_cond_temp)
            
            var my_load_adj = copysign(math_max(math_abs(my_load), l_available_cooling_capacity * l_min_part_load_rat), my_load)
            my_load_adj = copysign(math_min(math_abs(my_load_adj), l_available_cooling_capacity * l_max_part_load_rat), my_load_adj)
            
            var l_chill_water_massflow_rate_max: Real64 = self.DesEvapMassFlowRate
            
            if self.CWplantLoc.side.FlowLock == 0:
                self.PossibleSubcooling = False
                l_cooling_load = math_abs(my_load_adj)
                if chill_delta_temp != 0.0:
                    l_chill_water_mass_flow_rate = math_abs(l_cooling_load / (cp_cw * chill_delta_temp))
                    if l_chill_water_mass_flow_rate - l_chill_water_massflow_rate_max > 0.01:
                        self.PossibleSubcooling = True
                    PlantUtilities_SetComponentFlowRate(state, l_chill_water_mass_flow_rate, self.ChillReturnNodeNum,
                                                       self.ChillSupplyNodeNum, self.CWplantLoc)
                else:
                    l_chill_water_mass_flow_rate = 0.0
                    ShowRecurringWarningErrorAtEnd(state, "GasAbsorberChillerModel:Cooling\"" + self.Name + "\", DeltaTemp = 0 in mass flow calculation",
                                                  self.DeltaTempCoolErrCount)
                l_chill_supply_temp = chill_supply_set_point_temp
            elif self.CWplantLoc.side.FlowLock == 1:
                l_chill_water_mass_flow_rate = state.dataLoopNodes.Node[self.ChillReturnNodeNum].MassFlowRate
                if self.PossibleSubcooling:
                    l_cooling_load = math_abs(my_load_adj)
                    chill_delta_temp = l_cooling_load / l_chill_water_mass_flow_rate / cp_cw
                    l_chill_supply_temp = state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp - chill_delta_temp
                else:
                    chill_delta_temp = state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp - chill_supply_set_point_temp
                    l_cooling_load = math_abs(l_chill_water_mass_flow_rate * cp_cw * chill_delta_temp)
                    l_chill_supply_temp = chill_supply_set_point_temp
                
                if l_chill_supply_temp < l_chw_low_limit_temp:
                    if (state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp - l_chw_low_limit_temp) > 0.001:
                        l_chill_supply_temp = l_chw_low_limit_temp
                        chill_delta_temp = state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp - l_chill_supply_temp
                        l_cooling_load = l_chill_water_mass_flow_rate * cp_cw * chill_delta_temp
                    else:
                        l_chill_supply_temp = state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp
                        chill_delta_temp = 0.0
                        l_cooling_load = 0.0
                
                if l_cooling_load > math_abs(my_load_adj):
                    if l_chill_water_mass_flow_rate > 0.01:
                        l_cooling_load = math_abs(my_load_adj)
                        chill_delta_temp = l_cooling_load / l_chill_water_mass_flow_rate / cp_cw
                        l_chill_supply_temp = state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp - chill_delta_temp
            
            var part_load_rat: Real64 = math_min(math_abs(my_load_adj) / l_available_cooling_capacity, l_max_part_load_rat)
            part_load_rat = math_max(l_min_part_load_rat, part_load_rat)
            
            if l_available_cooling_capacity > 0.0:
                if math_abs(my_load_adj) / l_available_cooling_capacity < l_min_part_load_rat:
                    l_cool_part_load_ratio = my_load_adj / l_available_cooling_capacity
                else:
                    l_cool_part_load_ratio = part_load_rat
            else:
                l_cool_part_load_ratio = 0.0
            
            if l_cool_part_load_ratio < l_min_part_load_rat or l_heat_part_load_ratio < l_min_part_load_rat:
                l_fraction_of_period_running = math_min(1.0, math_max(l_heat_part_load_ratio, l_cool_part_load_ratio) / l_min_part_load_rat)
            else:
                l_fraction_of_period_running = 1.0
            
            l_cool_fuel_use_rate = l_available_cooling_capacity * l_fuel_cool_ratio * \
                                   self.FuelCoolFTCurve.value(state, l_chill_supply_temp, calc_cond_temp) * \
                                   self.FuelCoolFPLRCurve.value(state, l_cool_part_load_ratio) * l_fraction_of_period_running
            
            l_cool_electric_power = l_nom_cooling_cap * l_elec_cool_ratio * l_fraction_of_period_running * \
                                    self.ElecCoolFTCurve.value(state, l_chill_supply_temp, calc_cond_temp) * \
                                    self.ElecCoolFPLRCurve.value(state, l_cool_part_load_ratio)
            
            l_tower_load = l_cooling_load + l_cool_fuel_use_rate / l_fuel_heat_ratio + l_cool_electric_power
            
            if l_is_water_cooled:
                if l_cond_water_mass_flow_rate > 0.01:
                    l_cond_supply_temp = l_cond_return_temp + l_tower_load / (l_cond_water_mass_flow_rate * cp_cd)
                else:
                    if self.lCondWaterMassFlowRate_Index == 0:
                        ShowSevereError(state, "CalcGasAbsorberChillerModel: Condenser flow = 0, for Gas Absorber Chiller=" + self.Name)
                        ShowContinueErrorTimeStamp(state, "")
                    ShowRecurringSevereErrorAtEnd(state, "CalcGasAbsorberChillerModel: Condenser flow = 0, for Gas Absorber Chiller=" + self.Name,
                                                 self.lCondWaterMassFlowRate_Index)
            else:
                l_cond_supply_temp = l_cond_return_temp
            
            self.oldCondSupplyTemp = l_cond_supply_temp
            if not l_is_enter_condens_temp:
                var revised_estimate_avail_cap: Real64 = l_nom_cooling_cap * self.CoolCapFTCurve.value(state, chill_supply_set_point_temp, l_cond_supply_temp)
                if revised_estimate_avail_cap > 0.0:
                    var error_avail_cap: Real64 = math_abs((revised_estimate_avail_cap - l_available_cooling_capacity) / revised_estimate_avail_cap)
                    if error_avail_cap > 0.05:
                        ShowRecurringWarningErrorAtEnd(state, "GasAbsorberChillerModel:\"" + self.Name + "\", poor Condenser Supply Estimate",
                                                      self.CondErrCount, error_avail_cap, error_avail_cap)
        
        self.CoolingLoad = l_cooling_load
        self.TowerLoad = l_tower_load
        self.CoolFuelUseRate = l_cool_fuel_use_rate
        self.CoolElectricPower = l_cool_electric_power
        self.CondReturnTemp = l_cond_return_temp
        self.ChillReturnTemp = l_chill_return_temp
        self.CondSupplyTemp = l_cond_supply_temp
        self.ChillSupplyTemp = l_chill_supply_temp
        self.ChillWaterFlowRate = l_chill_water_mass_flow_rate
        self.CondWaterFlowRate = l_cond_water_mass_flow_rate
        self.CoolPartLoadRatio = l_cool_part_load_ratio
        self.CoolingCapacity = l_available_cooling_capacity
        self.FractionOfPeriodRunning = l_fraction_of_period_running
        
        self.FuelUseRate = l_cool_fuel_use_rate + l_heat_fuel_use_rate
        self.ElectricPower = l_cool_electric_power + l_heat_electric_power

    fn calculateHeater(inout self, state: AnyPointer[NoneType], my_load: Real64, run_flag: Bool) -> None:
        var l_nom_cooling_cap: Real64 = self.NomCoolingCap
        var l_nom_heat_cool_ratio: Real64 = self.NomHeatCoolRatio
        var l_fuel_heat_ratio: Real64 = self.FuelHeatRatio
        var l_elec_heat_ratio: Real64 = self.ElecHeatRatio
        var l_min_part_load_rat: Real64 = self.MinPartLoadRat
        var l_max_part_load_rat: Real64 = self.MaxPartLoadRat
        
        var l_heating_load: Real64 = 0.0
        var l_cool_fuel_use_rate: Real64 = 0.0
        var l_heat_fuel_use_rate: Real64 = 0.0
        var l_cool_electric_power: Real64 = 0.0
        var l_heat_electric_power: Real64 = 0.0
        var l_hot_water_return_temp: Real64 = 0.0
        var l_hot_water_supply_temp: Real64 = 0.0
        var l_hot_water_mass_flow_rate: Real64 = 0.0
        var l_cool_part_load_ratio: Real64 = 0.0
        var l_heat_part_load_ratio: Real64 = 0.0
        var l_available_heating_capacity: Real64 = 0.0
        var l_fraction_of_period_running: Real64 = 0.0
        
        l_hot_water_return_temp = state.dataLoopNodes.Node[self.HeatReturnNodeNum].Temp
        l_hot_water_mass_flow_rate = state.dataLoopNodes.Node[self.HeatReturnNodeNum].MassFlowRate
        
        var cp_hw: Real64 = self.HWplantLoc.loop.glycol.getSpecificHeat(state, l_hot_water_return_temp, "CalcGasAbsorberHeaterModel")
        
        l_cool_electric_power = self.CoolElectricPower
        l_cool_fuel_use_rate = self.CoolFuelUseRate
        l_cool_part_load_ratio = self.CoolPartLoadRatio
        
        var heat_supply_set_point_temp: Real64
        if self.HWplantLoc.loop.LoopDemandCalcScheme == 1:
            heat_supply_set_point_temp = state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPoint
        else:
            heat_supply_set_point_temp = state.dataLoopNodes.Node[self.HeatSupplyNodeNum].TempSetPointLo
        
        var heat_delta_temp: Real64 = math_abs(l_hot_water_return_temp - heat_supply_set_point_temp)
        
        if my_load <= 0 or not run_flag:
            l_hot_water_supply_temp = l_hot_water_return_temp
            l_fraction_of_period_running = math_min(1.0, math_max(l_heat_part_load_ratio, l_cool_part_load_ratio) / l_min_part_load_rat)
        else:
            l_available_heating_capacity = l_nom_heat_cool_ratio * l_nom_cooling_cap * \
                                          self.HeatCapFCoolCurve.value(state, (self.CoolingLoad / l_nom_cooling_cap))
            
            var my_load_adj = copysign(math_max(math_abs(my_load), self.HeatingCapacity * l_min_part_load_rat), my_load)
            my_load_adj = copysign(math_min(math_abs(my_load_adj), self.HeatingCapacity * l_max_part_load_rat), my_load_adj)
            
            if self.HWplantLoc.side.FlowLock == 0:
                l_heating_load = math_abs(my_load_adj)
                if heat_delta_temp != 0:
                    l_hot_water_mass_flow_rate = math_abs(l_heating_load / (cp_hw * heat_delta_temp))
                    PlantUtilities_SetComponentFlowRate(state, l_hot_water_mass_flow_rate, self.HeatReturnNodeNum,
                                                       self.HeatSupplyNodeNum, self.HWplantLoc)
                else:
                    l_hot_water_mass_flow_rate = 0.0
                    ShowRecurringWarningErrorAtEnd(state, "GasAbsorberChillerModel:Heating\"" + self.Name + "\", DeltaTemp = 0 in mass flow calculation",
                                                  self.DeltaTempHeatErrCount)
                l_hot_water_supply_temp = heat_supply_set_point_temp
            elif self.HWplantLoc.side.FlowLock == 1:
                l_hot_water_supply_temp = heat_supply_set_point_temp
                l_heating_load = math_abs(l_hot_water_mass_flow_rate * cp_hw * heat_delta_temp)
            
            if l_available_heating_capacity <= 0.0:
                l_available_heating_capacity = 0.0
                l_heat_part_load_ratio = 0.0
            else:
                l_heat_part_load_ratio = l_heating_load / l_available_heating_capacity
            
            l_heat_fuel_use_rate = l_available_heating_capacity * l_fuel_heat_ratio * \
                                   self.FuelHeatFHPLRCurve.value(state, l_heat_part_load_ratio)
            
            l_fraction_of_period_running = math_min(1.0, math_max(l_heat_part_load_ratio, l_cool_part_load_ratio) / l_min_part_load_rat)
            
            l_heat_electric_power = l_nom_cooling_cap * l_nom_heat_cool_ratio * l_elec_heat_ratio * l_fraction_of_period_running
            
            if l_heat_electric_power <= l_cool_electric_power:
                l_heat_electric_power = 0.0
            else:
                l_heat_electric_power -= l_cool_electric_power
        
        self.HeatingLoad = l_heating_load
        self.HeatFuelUseRate = l_heat_fuel_use_rate
        self.HeatElectricPower = l_heat_electric_power
        self.HotWaterReturnTemp = l_hot_water_return_temp
        self.HotWaterSupplyTemp = l_hot_water_supply_temp
        self.HotWaterFlowRate = l_hot_water_mass_flow_rate
        self.HeatPartLoadRatio = l_heat_part_load_ratio
        self.HeatingCapacity = l_available_heating_capacity
        self.FractionOfPeriodRunning = l_fraction_of_period_running
        
        self.FuelUseRate = l_cool_fuel_use_rate + l_heat_fuel_use_rate
        self.ElectricPower = l_cool_electric_power + l_heat_electric_power

    fn updateCoolRecords(inout self, state: AnyPointer[NoneType], my_load: Real64, run_flag: Bool) -> None:
        if my_load == 0 or not run_flag:
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].Temp = state.dataLoopNodes.Node[self.ChillReturnNodeNum].Temp
            if self.isWaterCooled:
                state.dataLoopNodes.Node[self.CondSupplyNodeNum].Temp = state.dataLoopNodes.Node[self.CondReturnNodeNum].Temp
        else:
            state.dataLoopNodes.Node[self.ChillSupplyNodeNum].Temp = self.ChillSupplyTemp
            if self.isWaterCooled:
                state.dataLoopNodes.Node[self.CondSupplyNodeNum].Temp = self.CondSupplyTemp
        
        self.CoolingEnergy = self.CoolingLoad * state.dataHVACGlobal.TimeStepSysSec
        self.TowerEnergy = self.TowerLoad * state.dataHVACGlobal.TimeStepSysSec
        self.FuelEnergy = self.FuelUseRate * state.dataHVACGlobal.TimeStepSysSec
        self.CoolFuelEnergy = self.CoolFuelUseRate * state.dataHVACGlobal.TimeStepSysSec
        self.ElectricEnergy = self.ElectricPower * state.dataHVACGlobal.TimeStepSysSec
        self.CoolElectricEnergy = self.CoolElectricPower * state.dataHVACGlobal.TimeStepSysSec
        if self.CoolFuelUseRate != 0.0:
            self.FuelCOP = self.CoolingLoad / self.CoolFuelUseRate
        else:
            self.FuelCOP = 0.0

    fn updateHeatRecords(inout self, state: AnyPointer[NoneType], my_load: Real64, run_flag: Bool) -> None:
        if my_load == 0 or not run_flag:
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].Temp = state.dataLoopNodes.Node[self.HeatReturnNodeNum].Temp
        else:
            state.dataLoopNodes.Node[self.HeatSupplyNodeNum].Temp = self.HotWaterSupplyTemp
        
        self.HeatingEnergy = self.HeatingLoad * state.dataHVACGlobal.TimeStepSysSec
        self.FuelEnergy = self.FuelUseRate * state.dataHVACGlobal.TimeStepSysSec
        self.HeatFuelEnergy = self.HeatFuelUseRate * state.dataHVACGlobal.TimeStepSysSec
        self.ElectricEnergy = self.ElectricPower * state.dataHVACGlobal.TimeStepSysSec
        self.HeatElectricEnergy = self.HeatElectricPower * state.dataHVACGlobal.TimeStepSysSec

    fn oneTimeInit(inout self, state: AnyPointer[NoneType]) -> None:
        pass

struct ChillerGasAbsorptionData:
    var getGasAbsorberInputs: Bool
    var GasAbsorber: List[GasAbsorberSpecs]

fn GetGasAbsorberInput(state: AnyPointer[NoneType]) -> None:
    pass

fn ShowFatalError(state: AnyPointer[NoneType], message: String) -> None:
    pass

fn ShowSevereError(state: AnyPointer[NoneType], message: String) -> None:
    pass

fn ShowContinueError(state: AnyPointer[NoneType], message: String) -> None:
    pass

fn ShowWarningError(state: AnyPointer[NoneType], message: String) -> None:
    pass

fn ShowContinueErrorTimeStamp(state: AnyPointer[NoneType], message: String) -> None:
    pass

fn ShowRecurringWarningErrorAtEnd(state: AnyPointer[NoneType], message: String, count: Int32, args: Float64 = 0.0, args2: Float64 = 0.0) -> None:
    pass

fn ShowRecurringSevereErrorAtEnd(state: AnyPointer[NoneType], message: String, count: Int32, args: Float64 = 0.0) -> None:
    pass

fn SetupOutputVariable(state: AnyPointer[NoneType], name: String, units: String, var: Real64, comp_name: String) -> None:
    pass

fn PlantUtilities_UpdateChillerComponentCondenserSide(state: AnyPointer[NoneType], loop_num: Int32, loop_side_num: Int32, 
                                                     equip_type: Int32, return_node: Int32, supply_node: Int32,
                                                     load: Real64, return_temp: Real64, supply_temp: Real64,
                                                     flow_rate: Real64, first_hvac: Bool) -> None:
    pass

fn PlantUtilities_SetComponentFlowRate(state: AnyPointer[NoneType], flow_rate: Real64, inlet_node: Int32, 
                                       outlet_node: Int32, loc: PlantLocation) -> None:
    pass

fn PlantUtilities_InitComponentNodes(state: AnyPointer[NoneType], min_flow: Real64, max_flow: Real64,
                                     inlet_node: Int32, outlet_node: Int32) -> None:
    pass

fn PlantUtilities_RegisterPlantCompDesignFlow(state: AnyPointer[NoneType], node_num: Int32, flow_rate: Real64) -> None:
    pass

fn PlantUtilities_ScanPlantLoopsForObject(state: AnyPointer[NoneType], name: String, equip_type: Int32,
                                         loc: PlantLocation, err_flag: Bool, extra_val: Real64 = 0.0,
                                         node_num: Int32 = 0) -> None:
    pass

fn PlantUtilities_InterConnectTwoPlantLoopSides(state: AnyPointer[NoneType], loc1: PlantLocation,
                                               loc2: PlantLocation, equip_type: Int32, allow_comp_op: Bool) -> None:
    pass

fn EMSManager_CheckIfNodeSetPointManagedByEMS(state: AnyPointer[NoneType], node_num: Int32, 
                                             ctrl_type: String, err_flag: Bool) -> None:
    pass

fn Psychrometrics_RhoH2O(temp: Real64) -> Real64:
    return 1000.0

fn Curve_GetCurve(state: AnyPointer[NoneType], name: String) -> AnyPointer[Curve]:
    return AnyPointer[Curve]()

fn Node_GetOnlySingleNode(state: AnyPointer[NoneType], args: String) -> Int32:
    return 0

fn Node_TestCompSet(state: AnyPointer[NoneType], args: String) -> None:
    pass

fn OutAirNodeManager_CheckAndAddAirNodeNumber(state: AnyPointer[NoneType], node_num: Int32) -> None:
    pass

fn GlobalNames_VerifyUniqueChillerName(state: AnyPointer[NoneType], args: String) -> None:
    pass

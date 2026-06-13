from math import *
from collections import InlineArray

@export
@value
struct TempMode:
    var value: Int

    alias Invalid = TempMode(-1)
    alias NOTSET = TempMode(0)
    alias ENTERINGBOILERTEMP = TempMode(1)
    alias LEAVINGBOILERTEMP = TempMode(2)
    alias Num = TempMode(3)


@value
struct BoilerSpecs:
    var Name: String
    var FuelType: UInt32
    var Type: UInt32
    var plantLoc: PlantLocationStub
    var Available: Bool
    var ON: Bool
    var NomCap: Float64
    var NomCapWasAutoSized: Bool
    var NomEffic: Float64
    var TempDesBoilerOut: Float64
    var FlowMode: UInt32
    var ModulatedFlowSetToLoop: Bool
    var ModulatedFlowErrDone: Bool
    var VolFlowRate: Float64
    var VolFlowRateWasAutoSized: Bool
    var DesMassFlowRate: Float64
    var MassFlowRate: Float64
    var SizFac: Float64
    var BoilerInletNodeNum: Int32
    var BoilerOutletNodeNum: Int32
    var MinPartLoadRat: Float64
    var MaxPartLoadRat: Float64
    var OptPartLoadRat: Float64
    var OperPartLoadRat: Float64
    var CurveTempMode: Int32
    var EfficiencyCurve: CurveStub
    var TempUpLimitBoilerOut: Float64
    var ParasiticElecLoad: Float64
    var ParasiticFuelConsumption: Float64
    var ParasiticFuelRate: Float64
    var ParasiticFuelCapacity: Float64
    var EffCurveOutputError: Int32
    var EffCurveOutputIndex: Int32
    var CalculatedEffError: Int32
    var CalculatedEffIndex: Int32
    var IsThisSized: Bool
    var FaultyBoilerFoulingFlag: Bool
    var FaultyBoilerFoulingIndex: Int32
    var FaultyBoilerFoulingFactor: Float64
    var EndUseSubcategory: String
    var MyEnvrnFlag: Bool
    var MyFlag: Bool
    var FuelUsed: Float64
    var ParasiticElecPower: Float64
    var BoilerLoad: Float64
    var BoilerMassFlowRate: Float64
    var BoilerOutletTemp: Float64
    var BoilerPLR: Float64
    var BoilerEff: Float64
    var BoilerEnergy: Float64
    var FuelConsumed: Float64
    var BoilerInletTemp: Float64
    var ParasiticElecConsumption: Float64

    fn __init__() -> Self:
        return BoilerSpecs(
            Name="",
            FuelType=0,
            Type=0,
            plantLoc=PlantLocationStub(),
            Available=False,
            ON=False,
            NomCap=0.0,
            NomCapWasAutoSized=False,
            NomEffic=0.0,
            TempDesBoilerOut=0.0,
            FlowMode=0,
            ModulatedFlowSetToLoop=False,
            ModulatedFlowErrDone=False,
            VolFlowRate=0.0,
            VolFlowRateWasAutoSized=False,
            DesMassFlowRate=0.0,
            MassFlowRate=0.0,
            SizFac=0.0,
            BoilerInletNodeNum=0,
            BoilerOutletNodeNum=0,
            MinPartLoadRat=0.0,
            MaxPartLoadRat=0.0,
            OptPartLoadRat=0.0,
            OperPartLoadRat=0.0,
            CurveTempMode=0,
            EfficiencyCurve=CurveStub(),
            TempUpLimitBoilerOut=0.0,
            ParasiticElecLoad=0.0,
            ParasiticFuelConsumption=0.0,
            ParasiticFuelRate=0.0,
            ParasiticFuelCapacity=0.0,
            EffCurveOutputError=0,
            EffCurveOutputIndex=0,
            CalculatedEffError=0,
            CalculatedEffIndex=0,
            IsThisSized=False,
            FaultyBoilerFoulingFlag=False,
            FaultyBoilerFoulingIndex=0,
            FaultyBoilerFoulingFactor=1.0,
            EndUseSubcategory="",
            MyEnvrnFlag=True,
            MyFlag=True,
            FuelUsed=0.0,
            ParasiticElecPower=0.0,
            BoilerLoad=0.0,
            BoilerMassFlowRate=0.0,
            BoilerOutletTemp=0.0,
            BoilerPLR=0.0,
            BoilerEff=0.0,
            BoilerEnergy=0.0,
            FuelConsumed=0.0,
            BoilerInletTemp=0.0,
            ParasiticElecConsumption=0.0
        )

    fn simulate(mut self, state: StateStub, calledFromLocation: PlantLocationStub, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> None:
        var sim_component = get_plant_component(state, self.plantLoc)
        self.InitBoiler(state)
        self.CalcBoilerModel(state, CurLoad, RunFlag, sim_component.FlowCtrl)
        self.UpdateBoilerRecords(state, CurLoad, RunFlag)

    fn getDesignCapacities(self, state: StateStub, calledFromLocation: PlantLocationStub) -> Tuple[Float64, Float64, Float64]:
        var MinLoad = self.NomCap * self.MinPartLoadRat
        var MaxLoad = self.NomCap * self.MaxPartLoadRat
        var OptLoad = self.NomCap * self.OptPartLoadRat
        return (MaxLoad, MinLoad, OptLoad)

    fn getSizingFactor(self) -> Float64:
        return self.SizFac

    fn onInitLoopEquip(mut self, state: StateStub, calledFromLocation: PlantLocationStub) -> None:
        self.InitBoiler(state)
        self.SizeBoiler(state)

    fn SetupOutputVars(self, state: StateStub) -> None:
        var sFuelType = get_fuel_name(self.FuelType)
        setup_output_variable(state, "Boiler Heating Rate", "W", self.BoilerLoad, "System", "Average", self.Name)
        setup_output_variable(state, "Boiler Heating Energy", "J", self.BoilerEnergy, "System", "Sum", self.Name, "EnergyTransfer", "Plant", "Boilers")
        setup_output_variable(state, "Boiler " + sFuelType + " Rate", "W", self.FuelUsed, "System", "Average", self.Name)
        setup_output_variable(state, "Boiler " + sFuelType + " Energy", "J", self.FuelConsumed, "System", "Sum", self.Name,
                             get_fuel_resource(self.FuelType), "Plant", "Heating", self.EndUseSubcategory)
        setup_output_variable(state, "Boiler Inlet Temperature", "C", self.BoilerInletTemp, "System", "Average", self.Name)
        setup_output_variable(state, "Boiler Outlet Temperature", "C", self.BoilerOutletTemp, "System", "Average", self.Name)
        setup_output_variable(state, "Boiler Mass Flow Rate", "kg/s", self.BoilerMassFlowRate, "System", "Average", self.Name)
        setup_output_variable(state, "Boiler Ancillary Electricity Rate", "W", self.ParasiticElecPower, "System", "Average", self.Name)
        setup_output_variable(state, "Boiler Ancillary Electricity Energy", "J", self.ParasiticElecConsumption, "System", "Sum", self.Name,
                             "Electricity", "Plant", "Heating", "Boiler Parasitic")
        if self.FuelType != 0:
            setup_output_variable(state, "Boiler Ancillary " + sFuelType + " Rate", "W", self.ParasiticFuelRate, "System", "Average", self.Name)
            setup_output_variable(state, "Boiler Ancillary " + sFuelType + " Energy", "J", self.ParasiticFuelConsumption, "System", "Sum", self.Name,
                                 get_fuel_resource(self.FuelType), "Plant", "Heating", "Boiler Parasitic")
        setup_output_variable(state, "Boiler Part Load Ratio", "None", self.BoilerPLR, "System", "Average", self.Name)
        setup_output_variable(state, "Boiler Efficiency", "None", self.BoilerEff, "System", "Average", self.Name)
        if state_has_ems(state):
            setup_ems_internal_variable(state, "Boiler Nominal Capacity", self.Name, "[W]", self.NomCap)

    fn oneTimeInit(mut self, state: StateStub) -> None:
        var errFlag = False
        scan_plant_loops_for_object(state, self.Name, self.plantLoc, errFlag, self.TempUpLimitBoilerOut)
        if errFlag:
            raise_error(state, "InitBoiler: Program terminated due to previous condition(s).")

        if self.FlowMode == 2 or self.FlowMode == 1:
            set_plant_component_flow_priority(state, self.plantLoc)

    fn initEachEnvironment(mut self, state: StateStub) -> None:
        var rho = get_density(state, self.plantLoc, "BoilerSpecs::initEachEnvironment")
        self.DesMassFlowRate = self.VolFlowRate * rho

        init_component_nodes(state, 0.0, self.DesMassFlowRate, self.BoilerInletNodeNum, self.BoilerOutletNodeNum)

        if self.FlowMode == 2:
            if (get_node_setpoint(state, self.BoilerOutletNodeNum) == -9999.0 and
                get_node_setpoint_lo(state, self.BoilerOutletNodeNum) == -9999.0):
                if not state_has_ems(state):
                    if not self.ModulatedFlowErrDone:
                        show_warning_error(state, "Missing temperature setpoint for LeavingSetpointModulated mode Boiler named " + self.Name)
                        show_continue_error(state, "  A temperature setpoint is needed at the outlet node of a boiler in variable flow mode, use a SetpointManager")
                        show_continue_error(state, "  The overall loop setpoint will be assumed for Boiler. The simulation continues ... ")
                        self.ModulatedFlowErrDone = True
                else:
                    var FatalError = False
                    check_ems_setpoint(state, self.BoilerOutletNodeNum, FatalError)
                    set_nodesetpoint_check(state, self.BoilerOutletNodeNum, False)
                    if FatalError:
                        if not self.ModulatedFlowErrDone:
                            show_warning_error(state, "Missing temperature setpoint for LeavingSetpointModulated mode Boiler named " + self.Name)
                            show_continue_error(state, "  A temperature setpoint is needed at the outlet node of a boiler in variable flow mode")
                            show_continue_error(state, "  use a Setpoint Manager to establish a setpoint at the boiler outlet node ")
                            show_continue_error(state, "  or use an EMS actuator to establish a setpoint at the boiler outlet node ")
                            show_continue_error(state, "  The overall loop setpoint will be assumed for Boiler. The simulation continues ... ")
                            self.ModulatedFlowErrDone = True
                self.ModulatedFlowSetToLoop = True

    fn InitBoiler(mut self, state: StateStub) -> None:
        if self.MyFlag:
            self.SetupOutputVars(state)
            self.oneTimeInit(state)
            self.MyFlag = False

        if self.MyEnvrnFlag and state_begin_envrnflag(state) and state_plantfirstsizes_ok(state):
            self.initEachEnvironment(state)
            self.MyEnvrnFlag = False

        if not state_begin_envrnflag(state):
            self.MyEnvrnFlag = True

        if self.FlowMode == 2 and self.ModulatedFlowSetToLoop:
            if get_loop_demand_scheme(state, self.plantLoc) == 1:
                set_node_setpoint(state, self.BoilerOutletNodeNum,
                                 get_node_setpoint(state, get_loop_setpoint_node(state, self.plantLoc)))
            else:
                set_node_setpoint_lo(state, self.BoilerOutletNodeNum,
                                    get_node_setpoint_lo(state, get_loop_setpoint_node(state, self.plantLoc)))

    fn SizeBoiler(mut self, state: StateStub) -> None:
        var ErrorsFound = False
        var tmpNomCap = self.NomCap
        var tmpBoilerVolFlowRate = self.VolFlowRate

        var PltSizNum = get_plant_size_num(state, self.plantLoc)

        if PltSizNum > 0:
            if get_plant_design_volflow(state, PltSizNum) >= 0.0001:
                var rho = get_density(state, self.plantLoc, "SizeBoiler")
                var Cp = get_specific_heat(state, self.plantLoc, "SizeBoiler")
                tmpNomCap = (Cp * rho * self.SizFac * get_plant_delta_t(state, PltSizNum) *
                            get_plant_design_volflow(state, PltSizNum))
            else:
                if self.NomCapWasAutoSized:
                    tmpNomCap = 0.0

            if state_plantfirstsizes_ok_to_finalize(state):
                if self.NomCapWasAutoSized:
                    self.NomCap = tmpNomCap
                    if state_plantfinalsizes_ok_to_report(state):
                        report_sizer_output(state, "Boiler:HotWater", self.Name, "Design Size Nominal Capacity [W]", tmpNomCap)
                    if state_plantfirstsizes_ok_to_report(state):
                        report_sizer_output(state, "Boiler:HotWater", self.Name, "Initial Design Size Nominal Capacity [W]", tmpNomCap)
                else:
                    if self.NomCap > 0.0 and tmpNomCap > 0.0:
                        var NomCapUser = self.NomCap
                        if state_plantfinalsizes_ok_to_report(state):
                            report_sizer_output_two(state, "Boiler:HotWater", self.Name,
                                                   "Design Size Nominal Capacity [W]", tmpNomCap,
                                                   "User-Specified Nominal Capacity [W]", NomCapUser)
                            if state_display_extra_warnings(state):
                                if abs(tmpNomCap - NomCapUser) / NomCapUser > get_auto_vs_hard_sizing_threshold(state):
                                    show_message(state, "SizeBoilerHotWater: Potential issue with equipment sizing for " + self.Name)
                                    show_continue_error(state, "User-Specified Nominal Capacity of " + str_f(NomCapUser, 2) + " [W]")
                                    show_continue_error(state, "differs from Design Size Nominal Capacity of " + str_f(tmpNomCap, 2) + " [W]")
                                    show_continue_error(state, "This may, or may not, indicate mismatched component sizes.")
                                    show_continue_error(state, "Verify that the value entered is intended and is consistent with other components.")
        else:
            if self.NomCapWasAutoSized and state_plantfirstsizes_ok_to_finalize(state):
                show_severe_error(state, "Autosizing of Boiler nominal capacity requires a loop Sizing:Plant object")
                show_continue_error(state, "Occurs in Boiler object=" + self.Name)
                ErrorsFound = True
            if not self.NomCapWasAutoSized and state_plantfinalsizes_ok_to_report(state) and self.NomCap > 0.0:
                report_sizer_output(state, "Boiler:HotWater", self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)

        if PltSizNum > 0:
            if get_plant_design_volflow(state, PltSizNum) >= 0.0001:
                tmpBoilerVolFlowRate = get_plant_design_volflow(state, PltSizNum) * self.SizFac
            else:
                if self.VolFlowRateWasAutoSized:
                    tmpBoilerVolFlowRate = 0.0

            if state_plantfirstsizes_ok_to_finalize(state):
                if self.VolFlowRateWasAutoSized:
                    self.VolFlowRate = tmpBoilerVolFlowRate
                    if state_plantfinalsizes_ok_to_report(state):
                        report_sizer_output(state, "Boiler:HotWater", self.Name, "Design Size Design Water Flow Rate [m3/s]", tmpBoilerVolFlowRate)
                    if state_plantfirstsizes_ok_to_report(state):
                        report_sizer_output(state, "Boiler:HotWater", self.Name, "Initial Design Size Design Water Flow Rate [m3/s]", tmpBoilerVolFlowRate)
                else:
                    if self.VolFlowRate > 0.0 and tmpBoilerVolFlowRate > 0.0:
                        var VolFlowRateUser = self.VolFlowRate
                        if state_plantfinalsizes_ok_to_report(state):
                            report_sizer_output_two(state, "Boiler:HotWater", self.Name,
                                                   "Design Size Design Water Flow Rate [m3/s]", tmpBoilerVolFlowRate,
                                                   "User-Specified Design Water Flow Rate [m3/s]", VolFlowRateUser)
                            if state_display_extra_warnings(state):
                                if abs(tmpBoilerVolFlowRate - VolFlowRateUser) / VolFlowRateUser > get_auto_vs_hard_sizing_threshold(state):
                                    show_message(state, "SizeBoilerHotWater: Potential issue with equipment sizing for " + self.Name)
                                    show_continue_error(state, "User-Specified Design Water Flow Rate of " + format_g(VolFlowRateUser) + " [m3/s]")
                                    show_continue_error(state, "differs from Design Size Design Water Flow Rate of " + format_g(tmpBoilerVolFlowRate) + " [m3/s]")
                                    show_continue_error(state, "This may, or may not, indicate mismatched component sizes.")
                                    show_continue_error(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpBoilerVolFlowRate = VolFlowRateUser
        else:
            if self.VolFlowRateWasAutoSized and state_plantfirstsizes_ok_to_finalize(state):
                show_severe_error(state, "Autosizing of Boiler design flow rate requires a loop Sizing:Plant object")
                show_continue_error(state, "Occurs in Boiler object=" + self.Name)
                ErrorsFound = True
            if not self.VolFlowRateWasAutoSized and state_plantfinalsizes_ok_to_report(state) and self.VolFlowRate > 0.0:
                report_sizer_output(state, "Boiler:HotWater", self.Name, "User-Specified Design Water Flow Rate [m3/s]", self.VolFlowRate)

        register_plant_comp_design_flow(state, self.BoilerInletNodeNum, tmpBoilerVolFlowRate)

        if state_plantfinalsizes_ok_to_report(state):
            var equipName = self.Name
            predef_table_entry(state, "pdchMechType", equipName, "Boiler:HotWater")
            predef_table_entry_f(state, "pdchMechNomEff", equipName, self.NomEffic)
            predef_table_entry_f(state, "pdchMechNomCap", equipName, self.NomCap)

            predef_table_entry(state, "pdchBoilerType", equipName, "Boiler:HotWater")
            predef_table_entry_f(state, "pdchBoilerRefCap", equipName, self.NomCap)
            predef_table_entry_f(state, "pdchBoilerRefEff", equipName, self.NomEffic)
            predef_table_entry_f(state, "pdchBoilerRatedCap", equipName, self.NomCap)
            predef_table_entry_f(state, "pdchBoilerRatedEff", equipName, self.NomEffic)
            var PlantloopName = get_loop_name(state, self.plantLoc)
            var PlantloopBranchName = get_branch_name(state, self.plantLoc)
            predef_table_entry(state, "pdchBoilerPlantloopName", equipName, PlantloopName)
            predef_table_entry(state, "pdchBoilerPlantloopBranchName", equipName, PlantloopBranchName)
            predef_table_entry_f(state, "pdchBoilerMinPLR", equipName, self.MinPartLoadRat)
            predef_table_entry(state, "pdchBoilerFuelType", equipName, get_fuel_name(self.FuelType))
            predef_table_entry_f(state, "pdchBoilerParaElecLoad", equipName, self.ParasiticElecLoad)

        if ErrorsFound:
            show_fatal_error(state, "Preceding sizing errors cause program termination")

    fn CalcBoilerModel(mut self, state: StateStub, MyLoad: Float64, RunFlag: Bool, EquipFlowCtrl: UInt32) -> None:
        self.BoilerLoad = 0.0
        self.ParasiticElecPower = 0.0
        self.BoilerMassFlowRate = 0.0

        var BoilerInletNode = self.BoilerInletNodeNum
        var BoilerOutletNode = self.BoilerOutletNodeNum
        var BoilerNomCap = self.NomCap
        var BoilerMaxPLR = self.MaxPartLoadRat
        var BoilerMinPLR = self.MinPartLoadRat
        var BoilerNomEff = self.NomEffic
        var TempUpLimitBout = self.TempUpLimitBoilerOut
        var BoilerMassFlowRateMax = self.DesMassFlowRate

        var Cp = get_specific_heat(state, self.plantLoc, "CalcBoilerModel")
        var inlet_temp = get_node_temp(state, BoilerInletNode)

        if MyLoad <= 0.0 or not RunFlag:
            if EquipFlowCtrl == 3:
                self.BoilerMassFlowRate = get_node_mass_flow(state, BoilerInletNode)
            return

        if (self.FaultyBoilerFoulingFlag and not state_warmup_flag(state) and
            not state_doing_sizing(state) and not state_kick_off_simulation(state)):
            var FaultIndex = self.FaultyBoilerFoulingIndex
            var NomCap_ff = BoilerNomCap
            var BoilerNomEff_ff = BoilerNomEff

            self.FaultyBoilerFoulingFactor = get_boiler_fouling_factor(state, FaultIndex)

            BoilerNomCap = NomCap_ff * self.FaultyBoilerFoulingFactor
            BoilerNomEff = BoilerNomEff_ff * self.FaultyBoilerFoulingFactor

        self.BoilerLoad = MyLoad

        if get_flow_lock(state, self.plantLoc) == 1:
            if self.FlowMode == 1 or self.FlowMode == 0:
                self.BoilerMassFlowRate = BoilerMassFlowRateMax
                set_component_flow_rate(state, self.BoilerMassFlowRate, BoilerInletNode, BoilerOutletNode, self.plantLoc)

                var BoilerDeltaTemp: Float64
                if self.BoilerMassFlowRate != 0.0 and MyLoad > 0.0:
                    BoilerDeltaTemp = self.BoilerLoad / self.BoilerMassFlowRate / Cp
                else:
                    BoilerDeltaTemp = 0.0
                self.BoilerOutletTemp = BoilerDeltaTemp + inlet_temp

            elif self.FlowMode == 2:
                var BoilerDeltaTemp: Float64
                if get_loop_demand_scheme(state, self.plantLoc) == 1:
                    BoilerDeltaTemp = get_node_setpoint(state, BoilerOutletNode) - inlet_temp
                else:
                    BoilerDeltaTemp = get_node_setpoint_lo(state, BoilerOutletNode) - inlet_temp

                self.BoilerOutletTemp = BoilerDeltaTemp + inlet_temp

                if BoilerDeltaTemp > 0.0 and self.BoilerLoad > 0.0:
                    self.BoilerMassFlowRate = self.BoilerLoad / Cp / BoilerDeltaTemp
                    self.BoilerMassFlowRate = min(BoilerMassFlowRateMax, self.BoilerMassFlowRate)
                else:
                    self.BoilerMassFlowRate = 0.0
                set_component_flow_rate(state, self.BoilerMassFlowRate, BoilerInletNode, BoilerOutletNode, self.plantLoc)

        else:
            self.BoilerMassFlowRate = get_node_mass_flow(state, BoilerInletNode)

            if MyLoad > 0.0 and self.BoilerMassFlowRate > 0.0:
                self.BoilerLoad = MyLoad
                if self.BoilerLoad > BoilerNomCap * BoilerMaxPLR:
                    self.BoilerLoad = BoilerNomCap * BoilerMaxPLR
                if self.BoilerLoad < BoilerNomCap * BoilerMinPLR:
                    self.BoilerLoad = BoilerNomCap * BoilerMinPLR
                self.BoilerOutletTemp = inlet_temp + self.BoilerLoad / (self.BoilerMassFlowRate * Cp)
            else:
                self.BoilerLoad = 0.0
                self.BoilerOutletTemp = inlet_temp

        if self.BoilerOutletTemp > TempUpLimitBout:
            self.BoilerLoad = 0.0
            self.BoilerOutletTemp = inlet_temp

        self.BoilerPLR = self.BoilerLoad / BoilerNomCap
        self.BoilerPLR = min(self.BoilerPLR, BoilerMaxPLR)
        self.BoilerPLR = max(self.BoilerPLR, BoilerMinPLR)

        var TheorFuelUse = self.BoilerLoad / BoilerNomEff
        var EffCurveOutput: Float64 = 1.0

        if self.EfficiencyCurve.ptr != 0:
            if self.EfficiencyCurve.numDims == 2:
                if self.CurveTempMode == 1:
                    EffCurveOutput = evaluate_curve_2d(self.EfficiencyCurve, self.BoilerPLR, inlet_temp)
                elif self.CurveTempMode == 2:
                    EffCurveOutput = evaluate_curve_2d(self.EfficiencyCurve, self.BoilerPLR, self.BoilerOutletTemp)
            else:
                EffCurveOutput = evaluate_curve_1d(self.EfficiencyCurve, self.BoilerPLR)

        var BoilerEff = EffCurveOutput * BoilerNomEff

        if not state_warmup_flag(state) and EffCurveOutput <= 0.0:
            if self.BoilerLoad > 0.0:
                if self.EffCurveOutputError < 1:
                    self.EffCurveOutputError += 1
                    show_warning_error(state, "Boiler:HotWater \"" + self.Name + "\"")
                    show_continue_error(state, "...Normalized Boiler Efficiency Curve output is less than or equal to 0.")
                    show_continue_error(state, "...Curve input x value (PLR)     = " + format_f(self.BoilerPLR, 5))
                    if self.EfficiencyCurve.ptr != 0 and self.EfficiencyCurve.numDims == 2:
                        if self.CurveTempMode == 1:
                            show_continue_error(state, "...Curve input y value (Tinlet) = " + format_f(inlet_temp, 2))
                        elif self.CurveTempMode == 2:
                            show_continue_error(state, "...Curve input y value (Toutlet) = " + format_f(self.BoilerOutletTemp, 2))
                    show_continue_error(state, "...Curve output (normalized eff) = " + format_f(EffCurveOutput, 5))
                    show_continue_error(state, "...Calculated Boiler efficiency  = " + format_f(BoilerEff, 5) +
                                       " (Boiler efficiency = Nominal Thermal Efficiency * Normalized Boiler Efficiency Curve output)")
                    show_continue_error_timestamp(state, "...Curve output reset to 0.01 and simulation continues.")
                else:
                    show_recurring_warning(state, "Boiler:HotWater \"" + self.Name +
                                          "\": Boiler Efficiency Curve output is less than or equal to 0 warning continues...",
                                          self.EffCurveOutputIndex, EffCurveOutput, EffCurveOutput)
            EffCurveOutput = 0.01

        if not state_warmup_flag(state) and BoilerEff > 1.1:
            if (self.BoilerLoad > 0.0 and self.EfficiencyCurve.ptr != 0 and
                self.NomEffic <= 1.0):
                if self.CalculatedEffError < 1:
                    self.CalculatedEffError += 1
                    show_warning_error(state, "Boiler:HotWater \"" + self.Name + "\"")
                    show_continue_error(state, "...Calculated Boiler Efficiency is greater than 1.1.")
                    show_continue_error(state, "...Boiler Efficiency calculations shown below.")
                    show_continue_error(state, "...Curve input x value (PLR)     = " + format_f(self.BoilerPLR, 5))
                    if self.EfficiencyCurve.numDims == 2:
                        if self.CurveTempMode == 1:
                            show_continue_error(state, "...Curve input y value (Tinlet) = " + format_f(inlet_temp, 2))
                        elif self.CurveTempMode == 2:
                            show_continue_error(state, "...Curve input y value (Toutlet) = " + format_f(self.BoilerOutletTemp, 2))
                    show_continue_error(state, "...Curve output (normalized eff) = " + format_f(EffCurveOutput, 5))
                    show_continue_error(state, "...Calculated Boiler efficiency  = " + format_f(BoilerEff, 5) +
                                       " (Boiler efficiency = Nominal Thermal Efficiency * Normalized Boiler Efficiency Curve output)")
                    show_continue_error_timestamp(state, "...Curve output reset to 1.1 and simulation continues.")
                else:
                    show_recurring_warning(state, "Boiler:HotWater \"" + self.Name +
                                          "\": Calculated Boiler Efficiency is greater than 1.1 warning continues...",
                                          self.CalculatedEffIndex, BoilerEff, BoilerEff)
            EffCurveOutput = 1.1

        self.FuelUsed = TheorFuelUse / EffCurveOutput
        if self.BoilerLoad > 0.0:
            self.ParasiticElecPower = self.ParasiticElecLoad * self.BoilerPLR
        self.ParasiticFuelRate = self.ParasiticFuelCapacity * (1.0 - self.BoilerPLR)
        self.BoilerEff = BoilerEff

    fn UpdateBoilerRecords(mut self, state: StateStub, MyLoad: Float64, RunFlag: Bool) -> None:
        var ReportingConstant = get_timestep_sys_sec(state)
        var BoilerInletNode = self.BoilerInletNodeNum
        var BoilerOutletNode = self.BoilerOutletNodeNum

        if MyLoad <= 0 or not RunFlag:
            safe_copy_plant_node(state, BoilerInletNode, BoilerOutletNode)
            set_node_temp(state, BoilerOutletNode, get_node_temp(state, BoilerInletNode))
            self.BoilerOutletTemp = get_node_temp(state, BoilerInletNode)
            self.BoilerLoad = 0.0
            self.FuelUsed = 0.0
            self.ParasiticElecPower = 0.0
            self.BoilerPLR = 0.0
            self.BoilerEff = 0.0
        else:
            safe_copy_plant_node(state, BoilerInletNode, BoilerOutletNode)
            set_node_temp(state, BoilerOutletNode, self.BoilerOutletTemp)

        self.BoilerInletTemp = get_node_temp(state, BoilerInletNode)
        self.BoilerMassFlowRate = get_node_mass_flow(state, BoilerOutletNode)
        self.BoilerEnergy = self.BoilerLoad * ReportingConstant
        self.FuelConsumed = self.FuelUsed * ReportingConstant
        self.ParasiticElecConsumption = self.ParasiticElecPower * ReportingConstant
        self.ParasiticFuelConsumption = self.ParasiticFuelRate * ReportingConstant


fn boiler_factory(state: StateStub, objectName: String) -> Optional[BoilerSpecs]:
    if state.data_boilers.getBoilerInputFlag:
        get_boiler_input(state)
        state.data_boilers.getBoilerInputFlag = False

    for boiler in state.data_boilers.Boiler:
        if boiler.Name == objectName:
            return boiler

    show_fatal_error(state, "LocalBoilerFactory: Error getting inputs for boiler named: " + objectName)
    return None


struct BoilersData:
    var getBoilerInputFlag: Bool
    var Boiler: List[BoilerSpecs]

    fn __init__() -> Self:
        return BoilersData(getBoilerInputFlag=True, Boiler=List[BoilerSpecs]())

    fn init_constant_state(self, state: StateStub) -> None:
        pass

    fn init_state(self, state: StateStub) -> None:
        pass

    fn clear_state(mut self) -> None:
        self.getBoilerInputFlag = True
        self.Boiler = List[BoilerSpecs]()


fn get_boiler_input(state: StateStub) -> None:
    var s_ipsc = get_ipshortcut(state)
    var ErrorsFound = False

    s_ipsc.cCurrentModuleObject = "Boiler:HotWater"
    var numBoilers = get_num_objects_found(state, s_ipsc.cCurrentModuleObject)

    if numBoilers <= 0:
        show_severe_error(state, "No " + s_ipsc.cCurrentModuleObject + " Equipment specified in input file")
        ErrorsFound = True

    if len(state.data_boilers.Boiler) > 0:
        return

    var inputProcessor = get_input_processor(state)
    var boilerSchemaProps = inputProcessor.getObjectSchemaProps(state, s_ipsc.cCurrentModuleObject)
    var boiler_objects = inputProcessor.getObjects(state, s_ipsc.cCurrentModuleObject)

    for i in range(len(boiler_objects)):
        var boilerFields = boiler_objects[i]
        var boilerName = boiler_objects[i].getName().upper()
        var fuelType = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "fuel_type")
        var efficiencyCurveTempEvalVar = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "efficiency_curve_temperature_evaluation_variable")
        var normalizedBoilerEfficiencyCurveName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "normalized_boiler_efficiency_curve_name")
        var boilerWaterInletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_water_inlet_node_name")
        var boilerWaterOutletNodeName = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_water_outlet_node_name")
        var boilerFlowMode = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "boiler_flow_mode")

        inputProcessor.markObjectAsUsed(s_ipsc.cCurrentModuleObject, boiler_objects[i].getName())

        verify_unique_boiler_name(state, s_ipsc.cCurrentModuleObject, boilerName, ErrorsFound, s_ipsc.cCurrentModuleObject + " Name")

        var thisBoiler = BoilerSpecs()
        state.data_boilers.Boiler.append(thisBoiler)
        thisBoiler.Name = boilerName
        thisBoiler.Type = 1

        thisBoiler.FuelType = get_fuel_type_enum(fuelType)

        thisBoiler.NomCap = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_capacity")
        if thisBoiler.NomCap == 0.0:
            show_severe_error(state, "GetBoilerInput: Boiler:HotWater=\"" + boilerName + "\",")
            show_continue_error(state, "Invalid Nominal Capacity=" + format_f(thisBoiler.NomCap, 2))
            show_continue_error(state, "...Nominal Capacity must be greater than 0.0")
            ErrorsFound = True
        if thisBoiler.NomCap == -999.0:
            thisBoiler.NomCapWasAutoSized = True

        thisBoiler.NomEffic = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "nominal_thermal_efficiency")
        if thisBoiler.NomEffic == 0.0:
            show_severe_error(state, "GetBoilerInput: Boiler:HotWater=\"" + boilerName + "\",")
            show_continue_error(state, "Invalid Nominal Thermal Efficiency=" + format_f(thisBoiler.NomEffic, 3))
            show_continue_error(state, "...Nominal Thermal Efficiency must be greater than 0.0")
            ErrorsFound = True
        elif thisBoiler.NomEffic > 1.0:
            show_warning_error(state, "Boiler:HotWater = " + boilerName + ": Nominal Thermal Efficiency=" +
                              format_f(thisBoiler.NomEffic, 0) + " should not typically be greater than 1.")

        if efficiencyCurveTempEvalVar == "ENTERINGBOILER":
            thisBoiler.CurveTempMode = 1
        elif efficiencyCurveTempEvalVar == "LEAVINGBOILER":
            thisBoiler.CurveTempMode = 2
        else:
            thisBoiler.CurveTempMode = 0

        if not normalizedBoilerEfficiencyCurveName:
            pass
        else:
            thisBoiler.EfficiencyCurve = get_curve(state, normalizedBoilerEfficiencyCurveName)
            if thisBoiler.EfficiencyCurve.ptr == 0:
                show_severe_item_not_found(state, "Boiler:HotWater", boilerName, "Normalized Boiler Efficiency Curve Name", normalizedBoilerEfficiencyCurveName)
                ErrorsFound = True
            elif thisBoiler.EfficiencyCurve.numDims not in (1, 2):
                show_severe_curve_dims(state, "Boiler:HotWater", boilerName, "Normalized Boiler Efficiency Curve Name",
                                      normalizedBoilerEfficiencyCurveName, "1 or 2", thisBoiler.EfficiencyCurve.numDims)
                ErrorsFound = True
            elif thisBoiler.EfficiencyCurve.numDims == 2:
                if thisBoiler.CurveTempMode == 0:
                    if efficiencyCurveTempEvalVar:
                        show_severe_error(state, "GetBoilerInput: Boiler:HotWater=\"" + boilerName + "\"")
                        show_continue_error(state, "Invalid Efficiency Curve Temperature Evaluation Variable=" + efficiencyCurveTempEvalVar)
                        show_continue_error(state, "boilers.Boiler using curve type of " + get_curve_name(thisBoiler.EfficiencyCurve) +
                                          " must specify Efficiency Curve Temperature Evaluation Variable")
                        show_continue_error(state, "Available choices are EnteringBoiler or LeavingBoiler")
                    else:
                        show_severe_error(state, "GetBoilerInput: Boiler:HotWater=\"" + boilerName + "\"")
                        show_continue_error(state, "Field Efficiency Curve Temperature Evaluation Variable is blank")
                        show_continue_error(state, "boilers.Boiler using curve type of " + get_curve_name(thisBoiler.EfficiencyCurve) +
                                          " must specify either EnteringBoiler or LeavingBoiler")
                    ErrorsFound = True

        thisBoiler.VolFlowRate = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "design_water_flow_rate")
        if thisBoiler.VolFlowRate == -999.0:
            thisBoiler.VolFlowRateWasAutoSized = True
        thisBoiler.MinPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "minimum_part_load_ratio")
        thisBoiler.MaxPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "maximum_part_load_ratio")
        thisBoiler.OptPartLoadRat = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "optimum_part_load_ratio")

        thisBoiler.TempUpLimitBoilerOut = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "water_outlet_upper_temperature_limit")
        if thisBoiler.TempUpLimitBoilerOut <= 0.0:
            thisBoiler.TempUpLimitBoilerOut = 99.9

        var parasitic_elec = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "on_cycle_parasitic_electric_load")
        if parasitic_elec == 0.0:
            parasitic_elec = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "parasitic_electric_load")
        thisBoiler.ParasiticElecLoad = parasitic_elec

        thisBoiler.ParasiticFuelCapacity = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "off_cycle_parasitic_fuel_load")
        if thisBoiler.FuelType == 0 and thisBoiler.ParasiticFuelCapacity > 0:
            show_warning_error(state, "GetBoilerInput: Boiler:HotWater=\"" + boilerName + "\"")
            show_continue_error(state, "Parasitic Fuel Capacity should be zero when the fuel type is electricity.")
            show_continue_error(state, "It will be ignored and the simulation continues.")
            thisBoiler.ParasiticFuelCapacity = 0.0

        thisBoiler.SizFac = inputProcessor.getRealFieldValue(boilerFields, boilerSchemaProps, "sizing_factor")
        if thisBoiler.SizFac == 0.0:
            thisBoiler.SizFac = 1.0

        thisBoiler.BoilerInletNodeNum = get_only_single_node(state, boilerWaterInletNodeName, ErrorsFound, "BoilerHotWater",
                                                            boilerName, "Water", "Inlet", "Primary", False)
        thisBoiler.BoilerOutletNodeNum = get_only_single_node(state, boilerWaterOutletNodeName, ErrorsFound, "BoilerHotWater",
                                                             boilerName, "Water", "Outlet", "Primary", False)
        test_comp_set(state, s_ipsc.cCurrentModuleObject, boilerName, boilerWaterInletNodeName, boilerWaterOutletNodeName, "Hot Water Nodes")

        if boilerFlowMode == "CONSTANTFLOW":
            thisBoiler.FlowMode = 1
        elif boilerFlowMode == "LEAVINGSETPOINTMODULATED":
            thisBoiler.FlowMode = 2
        elif boilerFlowMode == "NOTMODULATED" or not boilerFlowMode:
            thisBoiler.FlowMode = 0
        else:
            show_severe_error(state, "GetBoilerInput: Boiler:HotWater=\"" + boilerName + "\"")
            show_continue_error(state, "Invalid Boiler Flow Mode=" + boilerFlowMode)
            show_continue_error(state, "Available choices are ConstantFlow, NotModulated, or LeavingSetpointModulated")
            show_continue_error(state, "Flow mode NotModulated is assumed and the simulation continues.")
            thisBoiler.FlowMode = 0

        thisBoiler.EndUseSubcategory = inputProcessor.getAlphaFieldValue(boilerFields, boilerSchemaProps, "end_use_subcategory")
        if not thisBoiler.EndUseSubcategory:
            thisBoiler.EndUseSubcategory = "Boiler"

    if ErrorsFound:
        show_fatal_error(state, "GetBoilerInput: Errors found in processing " + s_ipsc.cCurrentModuleObject + " input.")


struct PlantLocationStub:
    var loop: Any
    var side: Any
    var branch: Any
    var comp: Any

    fn __init__() -> Self:
        return PlantLocationStub(loop=None, side=None, branch=None, comp=None)


struct CurveStub:
    var ptr: UInt64
    var numDims: Int32
    var curveType: Int32

    fn __init__() -> Self:
        return CurveStub(ptr=0, numDims=0, curveType=0)


struct StateStub:
    var dataBoilers: BoilersData
    var dataIPShortCut: Any
    var dataInputProcessing: Any
    var dataSize: Any
    var dataPlnt: Any
    var dataGlobal: Any
    var dataLoopNodes: Any
    var dataHVACGlobal: Any
    var dataOutRptPredefined: Any
    var dataFaultsMgr: Any
    var dataGlobalConstants: Any

    fn __init__() -> Self:
        return StateStub(
            dataBoilers=BoilersData(),
            dataIPShortCut=None,
            dataInputProcessing=None,
            dataSize=None,
            dataPlnt=None,
            dataGlobal=None,
            dataLoopNodes=None,
            dataHVACGlobal=None,
            dataOutRptPredefined=None,
            dataFaultsMgr=None,
            dataGlobalConstants=None
        )


fn setup_output_variable(state: StateStub, name: String, units: String, value_ref: Float64, time_step: String,
                         store_type: String, obj_name: String, resource_type: String = "", group: String = "",
                         end_use_cat: String = "", end_use_subcat: String = "") -> None:
    pass


fn setup_ems_internal_variable(state: StateStub, var_name: String, obj_name: String, units: String, value_ref: Float64) -> None:
    pass


fn get_fuel_name(fuel_type: UInt32) -> String:
    return ""


fn get_fuel_resource(fuel_type: UInt32) -> String:
    return ""


fn state_has_ems(state: StateStub) -> Bool:
    return False


fn scan_plant_loops_for_object(state: StateStub, obj_name: String, plant_loc: PlantLocationStub, err_flag: Bool, temp_limit: Float64) -> None:
    pass


fn set_plant_component_flow_priority(state: StateStub, plant_loc: PlantLocationStub) -> None:
    pass


fn get_density(state: StateStub, plant_loc: PlantLocationStub, routine_name: String) -> Float64:
    return 0.0


fn init_component_nodes(state: StateStub, min_flow: Float64, max_flow: Float64, inlet_node: Int32, outlet_node: Int32) -> None:
    pass


fn get_node_setpoint(state: StateStub, node_num: Int32) -> Float64:
    return 0.0


fn get_node_setpoint_lo(state: StateStub, node_num: Int32) -> Float64:
    return 0.0


fn show_warning_error(state: StateStub, message: String) -> None:
    pass


fn show_continue_error(state: StateStub, message: String) -> None:
    pass


fn check_ems_setpoint(state: StateStub, node_num: Int32, err_flag: Bool) -> None:
    pass


fn set_nodesetpoint_check(state: StateStub, node_num: Int32, needs_check: Bool) -> None:
    pass


fn state_begin_envrnflag(state: StateStub) -> Bool:
    return False


fn state_plantfirstsizes_ok(state: StateStub) -> Bool:
    return False


fn get_loop_demand_scheme(state: StateStub, plant_loc: PlantLocationStub) -> Int32:
    return 0


fn set_node_setpoint(state: StateStub, node_num: Int32, setpoint: Float64) -> None:
    pass


fn set_node_setpoint_lo(state: StateStub, node_num: Int32, setpoint: Float64) -> None:
    pass


fn get_loop_setpoint_node(state: StateStub, plant_loc: PlantLocationStub) -> Int32:
    return 0


fn get_plant_size_num(state: StateStub, plant_loc: PlantLocationStub) -> Int32:
    return 0


fn get_plant_design_volflow(state: StateStub, plt_siz_num: Int32) -> Float64:
    return 0.0


fn get_specific_heat(state: StateStub, plant_loc: PlantLocationStub, routine_name: String) -> Float64:
    return 0.0


fn get_plant_delta_t(state: StateStub, plt_siz_num: Int32) -> Float64:
    return 0.0


fn state_plantfirstsizes_ok_to_finalize(state: StateStub) -> Bool:
    return False


fn state_plantfinalsizes_ok_to_report(state: StateStub) -> Bool:
    return False


fn state_plantfirstsizes_ok_to_report(state: StateStub) -> Bool:
    return False


fn report_sizer_output(state: StateStub, equipment_type: String, name: String, description: String, value: Float64) -> None:
    pass


fn report_sizer_output_two(state: StateStub, equipment_type: String, name: String, desc1: String, val1: Float64, desc2: String, val2: Float64) -> None:
    pass


fn show_message(state: StateStub, message: String) -> None:
    pass


fn state_display_extra_warnings(state: StateStub) -> Bool:
    return False


fn get_auto_vs_hard_sizing_threshold(state: StateStub) -> Float64:
    return 0.1


fn show_severe_error(state: StateStub, message: String) -> None:
    pass


fn register_plant_comp_design_flow(state: StateStub, node_num: Int32, flow_rate: Float64) -> None:
    pass


fn predef_table_entry(state: StateStub, key: String, name: String, value: String) -> None:
    pass


fn predef_table_entry_f(state: StateStub, key: String, name: String, value: Float64) -> None:
    pass


fn get_loop_name(state: StateStub, plant_loc: PlantLocationStub) -> String:
    return ""


fn get_branch_name(state: StateStub, plant_loc: PlantLocationStub) -> String:
    return ""


fn show_fatal_error(state: StateStub, message: String) -> None:
    pass


fn set_component_flow_rate(state: StateStub, flow_rate: Float64, inlet_node: Int32, outlet_node: Int32, plant_loc: PlantLocationStub) -> None:
    pass


fn get_flow_lock(state: StateStub, plant_loc: PlantLocationStub) -> Int32:
    return 0


fn get_node_temp(state: StateStub, node_num: Int32) -> Float64:
    return 0.0


fn state_warmup_flag(state: StateStub) -> Bool:
    return False


fn state_doing_sizing(state: StateStub) -> Bool:
    return False


fn state_kick_off_simulation(state: StateStub) -> Bool:
    return False


fn get_boiler_fouling_factor(state: StateStub, fault_index: Int32) -> Float64:
    return 1.0


fn evaluate_curve_1d(curve: CurveStub, x: Float64) -> Float64:
    return 1.0


fn evaluate_curve_2d(curve: CurveStub, x: Float64, y: Float64) -> Float64:
    return 1.0


fn get_node_mass_flow(state: StateStub, node_num: Int32) -> Float64:
    return 0.0


fn safe_copy_plant_node(state: StateStub, inlet_node: Int32, outlet_node: Int32) -> None:
    pass


fn set_node_temp(state: StateStub, node_num: Int32, temp: Float64) -> None:
    pass


fn get_timestep_sys_sec(state: StateStub) -> Float64:
    return 0.0


fn show_severe_item_not_found(state: StateStub, obj_type: String, obj_name: String, field_name: String, field_value: String) -> None:
    pass


fn get_ipshortcut(state: StateStub) -> Any:
    return None


fn get_num_objects_found(state: StateStub, obj_type: String) -> Int32:
    return 0


fn get_input_processor(state: StateStub) -> Any:
    return None


fn get_curve(state: StateStub, curve_name: String) -> CurveStub:
    return CurveStub()


fn verify_unique_boiler_name(state: StateStub, obj_type: String, name: String, err_flag: Bool, field_name: String) -> None:
    pass


fn show_severe_curve_dims(state: StateStub, obj_type: String, obj_name: String, field_name: String, field_value: String,
                          expected: String, actual: Int32) -> None:
    pass


fn get_curve_name(curve: CurveStub) -> String:
    return ""


fn get_only_single_node(state: StateStub, node_name: String, err_flag: Bool, obj_type: String, obj_name: String,
                        fluid_type: String, conn_type: String, fluid_stream: String, parent: Bool) -> Int32:
    return 0


fn test_comp_set(state: StateStub, obj_type: String, obj_name: String, inlet_name: String, outlet_name: String, note: String) -> None:
    pass


fn show_continue_error_timestamp(state: StateStub, message: String) -> None:
    pass


fn show_recurring_warning(state: StateStub, message: String, index: Int32, val1: Float64, val2: Float64) -> None:
    pass


fn format_f(value: Float64, decimals: Int32) -> String:
    return ""


fn format_g(value: Float64) -> String:
    return ""


fn get_fuel_type_enum(fuel_type_str: String) -> UInt32:
    return 0


fn raise_error(state: StateStub, message: String) -> None:
    pass

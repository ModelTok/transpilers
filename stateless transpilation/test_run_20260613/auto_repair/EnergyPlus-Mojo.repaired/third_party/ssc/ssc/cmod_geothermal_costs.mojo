// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from core import *
from math import log, pow, pi as M_PI
from lib_geothermal import SGeothermal_Inputs
from common import *

struct VarInfo:
    var vartype: String
    var datatype: String
    var name: String
    var label: String
    var units: String
    var meta: String
    var group: String
    var required_if: String
    var constraints: String
    var ui_hints: String

alias var_info_invalid = VarInfo("", "", "", "", "", "", "", "", "", "")

var _cm_vtab_geothermal_costs: List[VarInfo] = List[VarInfo](
    VarInfo("SSC_INPUT", "SSC_NUMBER", "conversion_type", "Conversion Type", "", "", "GeoHourly", "*", "INTEGER", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "gross_output", "Gross output from GETEM", "kW", "", "GeoHourly", "*", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "design_temp", "Power block design temperature", "C", "", "GeoHourly", "*", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "eff_secondlaw", "Second Law Efficiency", "%", "", "GeoHourly", "*", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "qRejectTotal", "Total Rejected Heat", "btu/h", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "qCondenser", "Condenser Heat Rejected", "btu/h", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "v_stage_1", "Vacumm Pump Stage 1", "kW", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "v_stage_2", "Vacumm Pump Stage 2", "kW", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "v_stage_3", "Vacumm Pump Stage 3", "kW", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "GF_flowrate", "GF Flow Rate", "lb/h", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "qRejectByStage_1", "Heat Rejected by NCG Condenser Stage 1", "BTU/hr", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "qRejectByStage_2", "Heat Rejected by NCG Condenser Stage 2", "BTU/hr", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "qRejectByStage_3", "Heat Rejected by NCG Condenser Stage 3", "BTU/hr", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "ncg_condensate_pump", "Condensate Pump Work", "kW", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "cw_pump_work", "CW Pump Work", "kW", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "pressure_ratio_1", "Suction Steam Ratio 1", "", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "pressure_ratio_2", "Suction Steam Ratio 2", "", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "pressure_ratio_3", "Suction Steam Ratio 3", "", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "condensate_pump_power", "hp", "", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "cwflow", "Cooling Water Flow", "lb/h", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "cw_pump_head", "Cooling Water Pump Head", "lb/h", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "spec_vol", "Specific Volume", "cft/lb", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "spec_vol_lp", "LP Specific Volume", "cft/lb", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "x_hp", "HP Mass Fraction", "%", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "x_lp", "LP Mass Fraction", "%", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "hp_flash_pressure", "HP Flash Pressure", "psia", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "lp_flash_pressure", "LP Flash Pressure", "psia", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_INPUT", "SSC_NUMBER", "flash_count", "Flash Count", "(1 -2)", "", "GeoHourly", "conversion_type=1", "", ""),
    VarInfo("SSC_OUTPUT", "SSC_NUMBER", "baseline_cost", "Baseline Cost", "$/kW", "", "GeoHourly", "?", "", ""),
    var_info_invalid
)

class cm_geothermal_costs(ComputeModule):
    var hx_ppi: List[Float64] = List[Float64](0.890669720,0.919862622,0.938752147,0.957069262,0.963938180,0.972524327,0.983400114,1.000000000,0.998855180,1.066399542,1.226674299,1.333142530,1.377790498,1.438465942,1.414997138,1.423583286,1.464224385,1.513451631,1.535203205,1.555237550,1.604464797,1.643961076,1.657698912, 0.000000000)
    var steel_ppi: List[Float64] = List[Float64](1.128834356,1.102541630,1.108676599,1.073619632,0.999123576,1.021910605,0.961437336,1.000000000,1.064855390,1.423312883,1.499561788,1.634531113,1.762489045,2.159509202,1.612620508,1.958808063,2.219106047,2.109553024,1.984224365,2.034180543,1.714285714,1.638913234,1.858019281,0.000000000)
    var process_equip_ppi: List[Float64] = List[Float64](0.884044412,0.907406542,0.926150373,0.942470679,0.956807105,0.967657025,0.985381166,1.000000000,1.014742613,1.077732637,1.155135271,1.222672817,1.304587248,1.382668341,1.403383400,1.411178107,1.455344223,1.509492085,1.533628545,1.638936512,1.656479161,1.653172080,1.679672296,0.000000000)
    var engineering_ppi: List[Float64] = List[Float64](0.779879622,0.810834050,0.859415305,0.888650043,0.913585555,0.954428203,0.975924334,1.000000000,1.048581255,1.081685297,1.102751505,1.136285469,1.210232158,1.275150473,1.329750645,1.392089424,1.362424764,1.365004299,1.388650043,1.433791917,1.486242476,1.503869304,1.558039553,0.000000000)
    var pump_ppi: List[Float64] = List[Float64](0.853394181,0.872219053,0.899600685,0.924130063,0.936679977,0.950370793,0.976041072,1.000000000,1.010838562,1.039931546,1.093553908,1.142042213,1.213348545,1.278379920,1.314318311,1.324586423,1.324586423,1.349115801,1.339418140,1.366799772,1.391899601,1.411294923,1.438106104,0.000000000)
    var turbine_ppi: List[Float64] = List[Float64](0.882850242,0.896135266,0.917874396,0.934782609,0.960144928,0.969202899,0.980072464,1.000000000,1.013285024,1.018719807,1.017512077,1.050120773,1.106884058,1.245169082,1.350241546,1.340579710,1.359903382,1.349637681,1.376811594,1.411835749,1.399154589,1.403046162,1.346947738,1.327974034)
    var construction_ppi: List[Float64] = List[Float64](0.790555556,0.816666667,0.842222222,0.872777778,0.909444444,0.933333333,0.957777778,1.000000000,1.039444444,1.067222222,1.088888889,1.129444444,1.170000000,1.221666667,1.277777778,1.320000000,1.357777778,1.361666667,1.374444444,1.426666667,1.475000000,1.528333333,1.594444444,0.000000000)
    var user_adjust: Float64 = 1
    var size_ratio: Float64
    var ref_plant_size: Float64 = 10000
    var hx_cost_adjust: Float64 = 1
    var hx_cost: Float64
    var sf_hx: Float64
    var hx_gf_c1: Float64
    var hx_gf_c2: Float64
    var hx_gf_c: Float64
    var sales_tax: Float64 = 0.05
    var freight: Float64 = 0.05
    var total_material_cost_multiplier: Float64 = 1.7
    var steel: Float64 = 0.22
    var current_cost_ref_hx: Float64
    var sf_condenser: Float64
    var condenser_cost: Float64
    var wf_pump_cost: Float64
    var turbine_cost: Float64
    var corrected_equip_cost: Float64
    var dc_cost_multiplier: Float64
    var corrected_total_material_mult: Float64
    var corrected_construct_malts: Float64
    var plant_size_adjustment: Float64
    var direct_installation_multiplier: Float64
    var escalation_equip_cost: Float64
    var const_matls_rentals: Float64 = 0.25
    var multiplier_input_year: Float64
    var corrected_labor: Float64
    var labor_cost_multiplier: Float64 = 0.27
    var labor_fringe_benefits: Float64 = 0.45
    var sf_0: Float64 = 1.01216
    var sf_1: Float64 = -0.000760473
    var sf_2: Float64 = 2.0145e-6
    var sf_3: Float64 = 0
    var hx_c10: Float64 = 5.95
    var hx_c11: Float64 = 2163827753
    var hx_c12: Float64 = -3.810541361
    var hx_c20: Float64 = -22.09917
    var hx_c21: Float64 = 0.4275955
    var hx_c22: Float64 = -0.002356472
    var hx_c23: Float64 = 4.244622e-06
    var acc_c0: Float64 = 47
    var acc_c1: Float64 = 11568490
    var acc_c2: Float64 = -2.350919
    var acc_c10: Float64 = 15.52712
    var acc_c11: Float64 = 0.005950211
    var acc_c12: Float64 = -0.001200635
    var acc_c13: Float64 = 0.000005657483
    var acc_c20: Float64 = 3.582461
    var acc_c21: Float64 = -0.05107826
    var acc_c22: Float64 = 0.000277465
    var acc_c23: Float64 = -2.549391e-07
    var acc_0: Float64
    var acc_1: Float64
    var acc_2: Float64
    var accc_0: Float64
    var accc_1: Float64
    var accc_2: Float64
    var acc_c: Float64
    var current_cost_ref_acc: Float64
    var sf_wf: Float64
    var wf_sf_c0: Float64 = -0.777900000001
    var wf_sf_c1: Float64 = 0.029802
    var wf_sf_c2: Float64 = -0.00019008
    var wf_sf_c3: Float64 = 3.872e-07
    var wf_c10: Float64 = 32.0607143
    var wf_c11: Float64 = -0.2537857
    var wf_c12: Float64 = 0.0006714
    var wf_c20: Float64 = -0.3329714
    var wf_c21: Float64 = 0.0559291
    var wf_c22: Float64 = -0.0001977
    var pcc_1: Float64
    var pcc_2: Float64
    var pcc_c: Float64
    var current_cost_ref_pcc: Float64
    var turbine_sf_c0: Float64 = 0.6642
    var turbine_sf_c1: Float64 = 0.0003589091
    var turbine_sf_c2: Float64 = -2.0218e-06
    var sf_turbine: Float64
    var turbine_c0: Float64 = 0.79664761905
    var turbine_c1: Float64 = -0.00977366138
    var turbine_c2: Float64 = 0.00004244825
    var turbine_c3: Float64 = -5.321e-08
    var turbine_c10: Float64 = -24.62889285714
    var turbine_c11: Float64 = 0.49768131746
    var turbine_c12: Float64 = -0.00296254476
    var turbine_c13: Float64 = 5.52551e-06
    var ppc_0: Float64
    var ppc_1: Float64
    var turbine_c: Float64
    var generator_c: Float64
    var max_turbine_size: Float64 = 15000 * 0.7457
    var parasitic: Float64
    var tg_size: Float64
    var tg_sets: Float64
    var ref_turbine_cost: Float64
    var tg_cost: Float64
    var current_cost_ref_tg: Float64
    var plant_equip_cost: Float64
    var baseline_cost: Float64
    var tg_sets_num: Int = 1
    var cooling_tower_cost: Float64
    var condenser_cost_flash: Float64
    var lmtd: Float64
    var condenser_pinch_pt: Float64 = 7.50
    var dtCooling_water: Float64 = 25.0
    var condenser_u: Float64 = 350.00
    var area: Float64
    var hp_total_cost: Float64
    var a_cross_section: Float64
    var vacuum_pump_1: Float64
    var vacuum_pump_2: Float64
    var vacuum_pump_3: Float64
    var vacuum_pump: Float64
    var U: Int = 350
    var cond_area_1: Float64
    var cond_area_2: Float64
    var cond_area_3: Float64
    var condenser_ncg: Float64
    var ncg_pump_work: Float64
    var ncg_water_pump: Float64
    var pump_ncg: Float64
    var ejector_ncg: Float64
    var cw_pump_power: Float64
    var condensate: Float64
    var condensate_pump: Float64
    var cooling_water: Float64
    var pump_cost: Float64
    var h2s_level: Float64 = 20
    var h2s_flow: Float64
    var h2s_cost: Float64
    var flash_vessel_cost: Float64
    var equip_cost_flash: Float64
    var ncg_cost: Float64
    var current_tg_cost: Float64
    var current_vessel_cost: Float64
    var current_tower_cost: Float64
    var current_condenser_cost: Float64
    var current_pump_cost: Float64
    var current_ncg_cost: Float64
    var current_h2s_cost: Float64
    var current_cost_flash: Float64
    var m_stm: Float64
    var m_stm_lp: Float64
    var hp_steam_flow: Float64
    var max_drop_size: Float64 = 200
    var v_terminal: Float64
    var num_vessels: Float64
    var area_xsection_hp: Float64
    var hp_flash_volume: Float64
    var A: Float64
    var D: Float64
    var H: Float64
    var A_lp: Float64
    var D_lp: Float64
    var H_lp: Float64
    var hp_flash_cost: Float64
    var num_vessels_lp: Float64
    var a_xsection_lp: Float64
    var v_terminal_lp: Float64
    var lp_steam_flow: Float64
    var lp_flash_volume: Float64
    var lp_flash_cost: Float64
    var direct_multiplier_2002: Float64
    var tax: Float64
    var labor_multiplier: Float64
    var construction_multiplier: Float64
    var freight_flash: Float64
    var material_multiplier: Float64
    var escalation_ppi: Float64
    var direct_plant_cost: Float64
    var condenser_heat_rejected: Float64
    var vStage_3: Float64

    def __init__(inout self):
        self.add_var_info(_cm_vtab_geothermal_costs)

    def exec(inout self) raises:
        var geo_inputs: SGeothermal_Inputs
        var conversion_type: Int = as_integer("conversion_type")
        if conversion_type == 0:
            var design_temp: Float64 = as_double("design_temp")
            var eff: Float64 = as_double("eff_secondlaw")
            var unit_plant: Float64 = as_double("gross_output")
            self.size_ratio = unit_plant / self.ref_plant_size
            self.sf_hx = (self.sf_3 * pow(design_temp, 3)) + (self.sf_2 * pow(design_temp, 2)) + (self.sf_1 * design_temp) + self.sf_0
            self.hx_gf_c1 = self.hx_c10 + (self.hx_c11 * pow(design_temp, self.hx_c12))
            self.hx_gf_c2 = self.hx_c20 + (self.hx_c21 * design_temp) + (self.hx_c22 * pow(design_temp, 2)) + (self.hx_c23 * pow(design_temp, 3))
            self.hx_gf_c = self.hx_gf_c1 * exp(self.hx_gf_c2 * eff)
            self.current_cost_ref_hx = self.hx_gf_c * self.hx_ppi[20]
            self.hx_cost = self.user_adjust * pow(self.size_ratio, self.sf_hx) * ((self.ref_plant_size * self.hx_gf_c * self.hx_ppi[20]) / unit_plant)
            self.sf_condenser = 1
            self.accc_0 = (self.acc_c1 * pow(design_temp, self.acc_c2)) + self.acc_c0
            self.accc_1 = exp((self.acc_c13 * pow(design_temp, 3)) + (self.acc_c12 * pow(design_temp, 2)) + (self.acc_c11 * design_temp) + self.acc_c10)
            self.accc_2 = exp((self.acc_c23 * pow(design_temp, 3)) + (self.acc_c22 * pow(design_temp, 2)) + (self.acc_c21 * design_temp) + self.acc_c20)
            self.acc_c = self.accc_1 * pow(eff, self.accc_2) + self.accc_0
            self.current_cost_ref_acc = self.acc_c * self.hx_ppi[20]
            self.condenser_cost = self.user_adjust * pow(self.size_ratio, self.sf_condenser) * ((self.ref_plant_size * self.acc_c * self.hx_ppi[20]) / unit_plant)
            self.sf_wf = (self.wf_sf_c3 * pow(design_temp, 3)) + (self.wf_sf_c2 * pow(design_temp, 2)) + (self.wf_sf_c1 * design_temp) + self.wf_sf_c0
            self.pcc_1 = (self.wf_c12 * pow(design_temp, 2)) + (self.wf_c11 * design_temp) + self.wf_c10
            self.pcc_2 = (self.wf_c22 * pow(design_temp, 2)) + (self.wf_c21 * design_temp) + self.wf_c20
            self.pcc_c = self.pcc_1 * exp(self.pcc_2 * eff)
            self.current_cost_ref_pcc = self.pcc_c * self.pump_ppi[20]
            self.wf_pump_cost = self.user_adjust * pow(self.size_ratio, self.sf_wf) * ((self.ref_plant_size * self.pcc_c * self.pump_ppi[20]) / unit_plant)
            if unit_plant < self.ref_plant_size:
                self.sf_turbine = (self.turbine_sf_c2 * pow(design_temp, 2)) + (self.turbine_sf_c1 * design_temp) + self.turbine_sf_c0
            else:
                self.sf_turbine = 1
            self.ppc_0 = self.turbine_c0 + (self.turbine_c1 * design_temp) + (self.turbine_c2 * pow(design_temp, 2)) + (self.turbine_c3 * pow(design_temp, 3))
            self.ppc_1 = self.turbine_c10 + (self.turbine_c11 * design_temp) + (self.turbine_c12 * pow(design_temp, 2)) + (self.turbine_c13 * pow(design_temp, 3))
            self.parasitic = (self.ppc_0 * exp(self.ppc_1 * eff)) * self.ref_plant_size
            self.tg_size = self.ref_plant_size + self.parasitic
            self.tg_sets = self.tg_size / self.max_turbine_size
            if self.tg_sets > 1:
                self.turbine_c = 7400 * pow(self.max_turbine_size, 0.6)
            else:
                self.turbine_c = 7400 * pow(self.tg_size, 0.6)
            if self.tg_sets < 1:
                self.ref_turbine_cost = self.turbine_c / self.ref_plant_size
            else:
                self.ref_turbine_cost = (self.turbine_c * self.tg_sets) / self.ref_plant_size
            self.generator_c = ((1800 * pow(self.tg_size, 0.67))) / self.ref_plant_size
            self.tg_cost = self.ref_turbine_cost + self.generator_c
            self.current_cost_ref_tg = self.tg_cost * self.turbine_ppi[20]
            self.turbine_cost = self.user_adjust * pow(self.size_ratio, self.sf_turbine) * ((self.ref_plant_size * self.tg_cost * self.turbine_ppi[20]) / unit_plant)
            self.escalation_equip_cost = (self.current_cost_ref_acc + self.current_cost_ref_hx + self.current_cost_ref_pcc + self.current_cost_ref_tg) / (self.hx_gf_c + self.acc_c + self.pcc_c + self.tg_cost)
            self.corrected_labor = ((self.labor_cost_multiplier * self.engineering_ppi[20]) / self.escalation_equip_cost) * (1 + self.labor_fringe_benefits)
            self.corrected_construct_malts = (self.const_matls_rentals * self.process_equip_ppi[20]) / self.escalation_equip_cost
            self.corrected_total_material_mult = ((self.steel * self.steel_ppi[20]) + ((self.total_material_cost_multiplier - 1 - self.steel) * self.process_equip_ppi[20])) * (1 / self.escalation_equip_cost) + 1
            self.multiplier_input_year = self.corrected_total_material_mult + self.corrected_labor + self.corrected_construct_malts
            self.plant_size_adjustment = 1.02875 * pow((unit_plant / 1000), -0.01226)
            self.direct_installation_multiplier = self.plant_size_adjustment * self.multiplier_input_year
            self.dc_cost_multiplier = (self.sales_tax + self.freight) * ((self.corrected_total_material_mult + self.corrected_construct_malts) * self.plant_size_adjustment) + self.direct_installation_multiplier
            self.plant_equip_cost = self.hx_cost + self.condenser_cost + self.wf_pump_cost + self.turbine_cost
            self.corrected_equip_cost = self.dc_cost_multiplier * self.plant_equip_cost
            assign("baseline_cost", var_data(static_cast[ssc_number_t](self.corrected_equip_cost)))
        elif conversion_type == 1:
            var unit_plant: Float64 = as_double("gross_output")
            var qRejectTotal: Float64 = as_double("qRejectTotal") / 1000000
            var q_Condenser: Float64 = as_double("qCondenser") / 1000000
            var v_stage_1: Float64 = as_double("v_stage_1")
            var v_stage_2: Float64 = as_double("v_stage_2")
            var v_stage_3: Float64 = as_double("v_stage_3")
            var GF_flowrate: Float64 = as_double("GF_flowrate")
            var qRejectByStage_1: Float64 = as_double("qRejectByStage_1")
            var qRejectByStage_2: Float64 = as_double("qRejectByStage_2")
            var qRejectByStage_3: Float64 = as_double("qRejectByStage_3")
            var ncg_condensate_pump: Float64 = as_double("ncg_condensate_pump")
            var cw_pump_work: Float64 = as_double("cw_pump_work")
            var pressure_ratio_1: Float64 = 1 / as_double("pressure_ratio_1")
            var pressure_ratio_2: Float64 = 1 / as_double("pressure_ratio_2")
            var ncg_level: Int = 2000
            var ncg_flow: Float64 = GF_flowrate * ncg_level / 1000000
            var cwflow: Float64 = as_double("cwflow")
            var condensate_pump_power: Float64 = as_double("condensate_pump_power")
            var cw_pump_head: Float64 = as_double("cw_pump_head")
            var spec_vol: Float64 = as_double("spec_vol")
            var spec_vol_lp: Float64 = as_double("spec_vol_lp")
            var x_hp: Float64 = as_double("x_hp")
            var x_lp: Float64 = as_double("x_lp")
            var hp_flash_pressure: Float64 = as_double("hp_flash_pressure")
            var lp_flash_pressure: Float64 = as_double("lp_flash_pressure")
            var flash_count: Float64 = as_double("flash_count")
            var design_temp: Float64 = as_double("design_temp")
            self.tg_cost = (self.tg_sets_num * (2830 * (pow((unit_plant / self.tg_sets_num), 0.745)))) + (3685 * (pow((unit_plant / self.tg_sets_num), 0.617)))
            self.current_tg_cost = self.tg_cost * self.turbine_ppi[20]
            self.condenser_heat_rejected = GF_flowrate * qRejectTotal / 1000
            self.cooling_tower_cost = 7200 * (pow(self.condenser_heat_rejected, 0.8))
            self.current_tower_cost = self.cooling_tower_cost * self.process_equip_ppi[20]
            self.lmtd = (self.condenser_pinch_pt - (self.condenser_pinch_pt + self.dtCooling_water)) / (log(self.condenser_pinch_pt / (self.condenser_pinch_pt + self.dtCooling_water)))
            self.area = (q_Condenser * GF_flowrate / 1000) * 1000000 / (self.lmtd * self.condenser_u)
            self.condenser_cost_flash = 102 * pow(self.area, 0.85)
            self.current_condenser_cost = self.condenser_cost_flash * self.hx_ppi[20]
            self.m_stm = x_hp * 1000
            self.hp_steam_flow = ((GF_flowrate / 1000) * self.m_stm) * spec_vol / 60
            self.v_terminal = (-0.0009414 * pow(self.max_drop_size, 2) * log(hp_flash_pressure)) + (0.01096 * pow(self.max_drop_size, 2))
            self.area_xsection_hp = self.hp_steam_flow / self.v_terminal
            self.num_vessels = ceil(self.area_xsection_hp / 300)
            self.A = self.area_xsection_hp / self.num_vessels
            self.D = pow((self.A * 4 / M_PI), 0.5)
            self.H = self.D * 3
            self.hp_flash_volume = self.A * self.H * 7.4805
            self.hp_flash_cost = self.num_vessels * ((hp_flash_pressure < 75) ? 166.5 * pow(self.hp_flash_volume, 0.625) : 110 * pow(self.hp_flash_volume, 0.68))
            self.m_stm_lp = (flash_count == 2) ? (x_lp * 1000 * (1 - x_hp)) : 0
            self.lp_steam_flow = ((GF_flowrate / 1000) * self.m_stm_lp) * spec_vol_lp / 60
            self.v_terminal_lp = (flash_count == 1) ? 0 : ((-0.0009414 * pow(self.max_drop_size, 2) * log(lp_flash_pressure)) + (0.01096 * pow(self.max_drop_size, 2)))
            self.a_xsection_lp = (flash_count == 1) ? 0 : (self.lp_steam_flow / self.v_terminal_lp)
            self.num_vessels_lp = ceil(self.a_xsection_lp / 300)
            self.A_lp = (flash_count == 1) ? 0 : (self.a_xsection_lp / self.num_vessels_lp)
            self.D_lp = pow((self.A_lp * 4 / M_PI), 0.5)
            self.H_lp = self.D_lp * 3
            self.lp_flash_volume = self.A_lp * self.H_lp * 7.4805
            self.lp_flash_cost = (flash_count == 1) ? 0 : (self.num_vessels_lp * ((lp_flash_pressure < 75) ? (166.5 * pow(self.lp_flash_volume, 0.625)) : (110 * pow(self.lp_flash_volume, 0.68))))
            self.flash_vessel_cost = self.hp_flash_cost + self.lp_flash_cost
            self.current_vessel_cost = self.flash_vessel_cost * self.process_equip_ppi[20]
            self.vacuum_pump_1 = (v_stage_1 < 5000) ? 70000 * pow(v_stage_1, 0.34) : 7400 * pow(v_stage_1, 0.6)
            self.vacuum_pump_2 = (v_stage_2 < 5000) ? 70000 * pow(v_stage_2, 0.34) : 7400 * pow(v_stage_2, 0.6)
            self.vStage_3 = v_stage_3 * (GF_flowrate / 1000)
            self.vacuum_pump_3 = (self.vStage_3 < 5000) ? 70000 * pow(self.vStage_3, 0.34) : 7400 * pow(self.vStage_3, 0.6)
            self.vacuum_pump = self.vacuum_pump_1 + self.vacuum_pump_2 + self.vacuum_pump_3
            self.cond_area_1 = (GF_flowrate / 1000) * (qRejectByStage_1 / (self.lmtd * 0.9 * self.U))
            self.cond_area_2 = (GF_flowrate / 1000) * (qRejectByStage_2 / (self.lmtd * 0.9 * self.U))
            self.cond_area_3 = (GF_flowrate / 1000) * (qRejectByStage_3 / (self.lmtd * 0.9 * self.U))
            self.condenser_ncg = 322 * (pow(self.cond_area_1, 0.72) + pow(self.cond_area_2, 0.72) + pow(self.cond_area_3, 0.72))
            self.ncg_pump_work = (ncg_condensate_pump * GF_flowrate / 1000) / 0.7457
            self.ncg_water_pump = (cw_pump_work * GF_flowrate / 1000) / 0.7457
            self.pump_ncg = 2.35 * 1185 * (pow(self.ncg_pump_work, 0.767) + pow(self.ncg_water_pump, 0.767))
            self.ejector_ncg = (76 * pow(pressure_ratio_1, (-0.45)) + 43 * pow(pressure_ratio_2, (-0.63))) * ncg_flow
            self.ncg_cost = self.vacuum_pump + self.condenser_ncg + self.pump_ncg + self.ejector_ncg
            self.current_ncg_cost = self.ncg_cost * self.process_equip_ppi[20]
            self.condensate_pump = (GF_flowrate / 1000) * (condensate_pump_power * 1.34102)
            self.condensate = 2.35 * 1185 * pow(self.condensate_pump, 0.767)
            self.cw_pump_power = (GF_flowrate / 1000) * ((((cwflow / 60) * (cw_pump_head)) / 33000) / 0.7)
            self.cooling_water = 2.35 * 1185 * pow(self.cw_pump_power, 0.767)
            self.pump_cost = self.condensate + self.cooling_water
            self.current_pump_cost = self.pump_cost * self.pump_ppi[20]
            self.h2s_flow = self.h2s_level * GF_flowrate / 1000000
            self.h2s_cost = 115000 * pow(self.h2s_flow, 0.58)
            self.current_h2s_cost = self.h2s_cost * self.process_equip_ppi[20]
            self.equip_cost_flash = self.tg_cost + self.cooling_tower_cost + self.condenser_cost_flash + self.flash_vessel_cost + self.ncg_cost + self.pump_cost + self.h2s_cost
            self.current_cost_flash = self.current_tg_cost + self.current_tower_cost + self.current_condenser_cost + self.current_vessel_cost + self.current_ncg_cost + self.current_pump_cost + self.current_h2s_cost
            self.escalation_ppi = self.current_cost_flash / self.equip_cost_flash
            self.material_multiplier = 1 + ((8.65 * pow(design_temp, -0.297)) - 1) * (self.process_equip_ppi[20] / self.escalation_ppi)
            self.labor_multiplier = ((42.65 * pow(design_temp, -0.923)) * 1.45) * self.construction_ppi[20] / self.escalation_ppi
            self.construction_multiplier = (16.177 * pow(design_temp, -0.827)) * self.process_equip_ppi[20] / self.escalation_ppi
            self.direct_multiplier_2002 = self.material_multiplier + self.labor_multiplier + self.construction_multiplier
            self.tax = (self.material_multiplier + self.construction_multiplier) * self.sales_tax
            self.freight_flash = (self.material_multiplier + self.construction_multiplier) * self.freight
            self.dc_cost_multiplier = self.direct_multiplier_2002 + self.tax + self.freight_flash
            self.direct_plant_cost = self.current_cost_flash * self.dc_cost_multiplier
            self.baseline_cost = self.direct_plant_cost / unit_plant
            assign("baseline_cost", var_data(static_cast[ssc_number_t](self.baseline_cost)))

pub def geothermal_costs() -> ComputeModule:
    return cm_geothermal_costs()
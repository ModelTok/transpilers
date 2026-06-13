/**
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from csp_solver_util import C_csp_exception
from math import exp, pow

struct S_cost_model_parameters:
    var A_sf_refl: Float64
    var site_improv_spec_cost: Float64
    var heliostat_spec_cost: Float64
    var heliostat_fixed_cost: Float64
    var h_tower: Float64
    var h_rec: Float64
    var h_helio: Float64
    var tower_fixed_cost: Float64
    var tower_cost_scaling_exp: Float64
    var A_rec: Float64
    var rec_ref_cost: Float64
    var A_rec_ref: Float64
    var rec_cost_scaling_exp: Float64
    var Q_storage: Float64
    var tes_spec_cost: Float64
    var W_dot_design: Float64
    var power_cycle_spec_cost: Float64
    var radfield_area: Float64
    var coldstorage_vol: Float64
    var radfield_vol: Float64
    var rad_unitcost: Float64
    var rad_installcost: Float64
    var rad_volmulti: Float64
    var rad_fluidcost: Float64
    var coldstorage_unitcost: Float64
    var bop_spec_cost: Float64
    var fossil_backup_spec_cost: Float64
    var contingency_rate: Float64
    var total_land_area: Float64
    var plant_net_capacity: Float64
    var EPC_land_spec_cost: Float64
    var EPC_land_perc_direct_cost: Float64
    var EPC_land_per_power_cost: Float64
    var EPC_land_fixed_cost: Float64
    var total_land_spec_cost: Float64
    var total_land_perc_direct_cost: Float64
    var total_land_per_power_cost: Float64
    var total_land_fixed_cost: Float64
    var sales_tax_basis: Float64
    var sales_tax_rate: Float64

    def __init__(inout self):
        self.A_sf_refl = Float64.NaN
        self.site_improv_spec_cost = Float64.NaN
        self.heliostat_spec_cost = Float64.NaN
        self.heliostat_fixed_cost = Float64.NaN
        self.h_tower = Float64.NaN
        self.h_rec = Float64.NaN
        self.h_helio = Float64.NaN
        self.tower_fixed_cost = Float64.NaN
        self.tower_cost_scaling_exp = Float64.NaN
        self.A_rec = Float64.NaN
        self.rec_ref_cost = Float64.NaN
        self.A_rec_ref = Float64.NaN
        self.rec_cost_scaling_exp = Float64.NaN
        self.Q_storage = Float64.NaN
        self.tes_spec_cost = Float64.NaN
        self.W_dot_design = Float64.NaN
        self.power_cycle_spec_cost = Float64.NaN
        self.bop_spec_cost = Float64.NaN
        self.fossil_backup_spec_cost = Float64.NaN
        self.contingency_rate = Float64.NaN
        self.total_land_area = Float64.NaN
        self.plant_net_capacity = Float64.NaN
        self.EPC_land_spec_cost = Float64.NaN
        self.EPC_land_perc_direct_cost = Float64.NaN
        self.EPC_land_per_power_cost = Float64.NaN
        self.EPC_land_fixed_cost = Float64.NaN
        self.total_land_spec_cost = Float64.NaN
        self.total_land_perc_direct_cost = Float64.NaN
        self.total_land_per_power_cost = Float64.NaN
        self.total_land_fixed_cost = Float64.NaN
        self.sales_tax_basis = Float64.NaN
        self.sales_tax_rate = Float64.NaN
        self.rad_fluidcost = 0.0
        self.rad_installcost = 0.0
        self.rad_unitcost = 0.0
        self.rad_volmulti = 0.0
        self.coldstorage_unitcost = 0.0
        self.radfield_area = 0.0
        self.coldstorage_vol = 0.0
        self.radfield_vol = 0.0

struct S_cost_model_outputs:
    var site_improvement_cost: Float64
    var heliostat_cost: Float64
    var tower_cost: Float64
    var receiver_cost: Float64
    var tes_cost: Float64
    var power_cycle_cost: Float64
    var rad_field_totcost: Float64
    var rad_fluid_totcost: Float64
    var rad_storage_totcost: Float64
    var bop_cost: Float64
    var fossil_backup_cost: Float64
    var direct_capital_precontingency_cost: Float64
    var contingency_cost: Float64
    var total_direct_cost: Float64
    var epc_and_owner_cost: Float64
    var total_land_cost: Float64
    var sales_tax_cost: Float64
    var total_indirect_cost: Float64
    var total_installed_cost: Float64
    var estimated_installed_cost_per_cap: Float64

    def __init__(inout self):
        self.site_improvement_cost = Float64.NaN
        self.heliostat_cost = Float64.NaN
        self.tower_cost = Float64.NaN
        self.receiver_cost = Float64.NaN
        self.tes_cost = Float64.NaN
        self.power_cycle_cost = Float64.NaN
        self.bop_cost = Float64.NaN
        self.fossil_backup_cost = Float64.NaN
        self.direct_capital_precontingency_cost = Float64.NaN
        self.contingency_cost = Float64.NaN
        self.total_direct_cost = Float64.NaN
        self.epc_and_owner_cost = Float64.NaN
        self.total_land_cost = Float64.NaN
        self.sales_tax_cost = Float64.NaN
        self.total_indirect_cost = Float64.NaN
        self.total_installed_cost = Float64.NaN
        self.estimated_installed_cost_per_cap = Float64.NaN
        self.rad_field_totcost = Float64.NaN
        self.rad_fluid_totcost = Float64.NaN
        self.rad_storage_totcost = Float64.NaN

struct C_mspt_system_costs:
    var ms_par: S_cost_model_parameters
    var ms_out: S_cost_model_outputs

    def __init__(inout self):
        self.ms_par = S_cost_model_parameters()
        self.ms_out = S_cost_model_outputs()

    def __del__(owned self):

    def check_parameters_are_set(inout self):
        if (self.ms_par.A_sf_refl != self.ms_par.A_sf_refl or
            self.ms_par.site_improv_spec_cost != self.ms_par.site_improv_spec_cost or
            self.ms_par.heliostat_spec_cost != self.ms_par.heliostat_spec_cost or
            self.ms_par.heliostat_fixed_cost != self.ms_par.heliostat_fixed_cost or
            self.ms_par.h_tower != self.ms_par.h_tower or
            self.ms_par.h_rec != self.ms_par.h_rec or
            self.ms_par.h_helio != self.ms_par.h_helio or
            self.ms_par.tower_fixed_cost != self.ms_par.tower_fixed_cost or
            self.ms_par.tower_cost_scaling_exp != self.ms_par.tower_cost_scaling_exp or
            self.ms_par.A_rec != self.ms_par.A_rec or
            self.ms_par.rec_ref_cost != self.ms_par.rec_ref_cost or
            self.ms_par.A_rec_ref != self.ms_par.A_rec_ref or
            self.ms_par.rec_cost_scaling_exp != self.ms_par.rec_cost_scaling_exp or
            self.ms_par.Q_storage != self.ms_par.Q_storage or
            self.ms_par.tes_spec_cost != self.ms_par.tes_spec_cost or
            self.ms_par.W_dot_design != self.ms_par.W_dot_design or
            self.ms_par.power_cycle_spec_cost != self.ms_par.power_cycle_spec_cost or
            self.ms_par.radfield_area != self.ms_par.radfield_area or
            self.ms_par.coldstorage_vol != self.ms_par.coldstorage_vol or
            self.ms_par.radfield_vol != self.ms_par.radfield_vol or
            self.ms_par.rad_unitcost != self.ms_par.rad_unitcost or
            self.ms_par.rad_installcost != self.ms_par.rad_installcost or
            self.ms_par.rad_fluidcost != self.ms_par.rad_fluidcost or
            self.ms_par.rad_volmulti != self.ms_par.rad_volmulti or
            self.ms_par.coldstorage_unitcost != self.ms_par.coldstorage_unitcost or
            self.ms_par.bop_spec_cost != self.ms_par.bop_spec_cost or
            self.ms_par.fossil_backup_spec_cost != self.ms_par.fossil_backup_spec_cost or
            self.ms_par.contingency_rate != self.ms_par.contingency_rate or
            self.ms_par.total_land_area != self.ms_par.total_land_area or
            self.ms_par.plant_net_capacity != self.ms_par.plant_net_capacity or
            self.ms_par.EPC_land_spec_cost != self.ms_par.EPC_land_spec_cost or
            self.ms_par.EPC_land_perc_direct_cost != self.ms_par.EPC_land_perc_direct_cost or
            self.ms_par.EPC_land_per_power_cost != self.ms_par.EPC_land_per_power_cost or
            self.ms_par.EPC_land_fixed_cost != self.ms_par.EPC_land_fixed_cost or
            self.ms_par.total_land_spec_cost != self.ms_par.total_land_spec_cost or
            self.ms_par.total_land_perc_direct_cost != self.ms_par.total_land_perc_direct_cost or
            self.ms_par.total_land_per_power_cost != self.ms_par.total_land_per_power_cost or
            self.ms_par.total_land_fixed_cost != self.ms_par.total_land_fixed_cost or
            self.ms_par.sales_tax_basis != self.ms_par.sales_tax_basis or
            self.ms_par.sales_tax_rate != self.ms_par.sales_tax_rate):
            var msg: String = "C_mspt_system_costs initialization failed because not all required parameters were defined" \
                "before calculate_costs() was called"
            C_csp_exception(msg, 0)
        return

    def calculate_costs(inout self):
        self.check_parameters_are_set()
        self.ms_out.site_improvement_cost = \
            N_mspt.site_improvement_cost(self.ms_par.A_sf_refl, self.ms_par.site_improv_spec_cost)
        self.ms_out.heliostat_cost = \
            N_mspt.heliostat_cost(self.ms_par.A_sf_refl, self.ms_par.heliostat_spec_cost, self.ms_par.heliostat_fixed_cost)
        self.ms_out.tower_cost = \
            N_mspt.tower_cost(self.ms_par.h_tower, self.ms_par.h_rec, self.ms_par.h_helio, self.ms_par.tower_fixed_cost, self.ms_par.tower_cost_scaling_exp)
        self.ms_out.receiver_cost = \
            N_mspt.receiver_cost(self.ms_par.A_rec, self.ms_par.rec_ref_cost, self.ms_par.A_rec_ref, self.ms_par.rec_cost_scaling_exp)
        self.ms_out.tes_cost = \
            N_mspt.tes_cost(self.ms_par.Q_storage, self.ms_par.tes_spec_cost)
        self.ms_out.power_cycle_cost = \
            N_mspt.power_cycle_cost(self.ms_par.W_dot_design, self.ms_par.power_cycle_spec_cost)
        self.ms_out.rad_field_totcost = \
            N_mspt.rad_field_totcost(self.ms_par.radfield_area, self.ms_par.rad_unitcost, self.ms_par.rad_installcost)
        self.ms_out.rad_fluid_totcost = \
            N_mspt.rad_fluid_totcost(self.ms_par.radfield_vol, self.ms_par.rad_fluidcost, self.ms_par.rad_volmulti)
        self.ms_out.rad_storage_totcost = \
            N_mspt.rad_storage_totcost(self.ms_par.coldstorage_vol, self.ms_par.coldstorage_unitcost)
        self.ms_out.bop_cost = \
            N_mspt.bop_cost(self.ms_par.W_dot_design, self.ms_par.bop_spec_cost)
        self.ms_out.fossil_backup_cost = \
            N_mspt.fossil_backup_cost(self.ms_par.W_dot_design, self.ms_par.fossil_backup_spec_cost)
        self.ms_out.direct_capital_precontingency_cost = \
            N_mspt.direct_capital_precontingency_cost(
                self.ms_out.site_improvement_cost,
                self.ms_out.heliostat_cost,
                self.ms_out.tower_cost,
                self.ms_out.receiver_cost,
                self.ms_out.tes_cost,
                self.ms_out.power_cycle_cost,
                self.ms_out.rad_field_totcost,
                self.ms_out.rad_fluid_totcost,
                self.ms_out.rad_storage_totcost,
                self.ms_out.bop_cost,
                self.ms_out.fossil_backup_cost)
        self.ms_out.contingency_cost = \
            N_mspt.contingency_cost(self.ms_par.contingency_rate, self.ms_out.direct_capital_precontingency_cost)
        self.ms_out.total_direct_cost = \
            N_mspt.total_direct_cost(self.ms_out.direct_capital_precontingency_cost, self.ms_out.contingency_cost)
        self.ms_out.total_land_cost = \
            N_mspt.total_land_cost(self.ms_par.total_land_area, self.ms_out.total_direct_cost, self.ms_par.plant_net_capacity,
                self.ms_par.total_land_spec_cost, self.ms_par.total_land_perc_direct_cost, self.ms_par.total_land_per_power_cost, self.ms_par.total_land_fixed_cost)
        self.ms_out.epc_and_owner_cost = \
            N_mspt.epc_and_owner_cost(self.ms_par.total_land_area, self.ms_out.total_direct_cost, self.ms_par.plant_net_capacity,
                self.ms_par.EPC_land_spec_cost, self.ms_par.EPC_land_perc_direct_cost, self.ms_par.EPC_land_per_power_cost, self.ms_par.EPC_land_fixed_cost)
        self.ms_out.sales_tax_cost = \
            N_mspt.sales_tax_cost(self.ms_out.total_direct_cost, self.ms_par.sales_tax_basis, self.ms_par.sales_tax_rate)
        self.ms_out.total_indirect_cost = \
            N_mspt.total_indirect_cost(self.ms_out.total_land_cost, self.ms_out.epc_and_owner_cost, self.ms_out.sales_tax_cost)
        self.ms_out.total_installed_cost = \
            N_mspt.total_installed_cost(self.ms_out.total_direct_cost, self.ms_out.total_indirect_cost)
        self.ms_out.estimated_installed_cost_per_cap = \
            N_mspt.estimated_installed_cost_per_cap(self.ms_out.total_installed_cost, self.ms_par.plant_net_capacity)
        return

struct N_mspt:
    @staticmethod
    def site_improvement_cost(A_refl: Float64, site_improv_spec_cost: Float64) -> Float64:
        return A_refl * site_improv_spec_cost

    @staticmethod
    def heliostat_cost(A_refl: Float64, heliostat_spec_cost: Float64, heliostate_fixed_cost: Float64) -> Float64:
        return A_refl * heliostat_spec_cost + heliostate_fixed_cost

    @staticmethod
    def tower_cost(h_tower: Float64, h_rec: Float64, h_helio: Float64, tower_fixed_cost: Float64, tower_cost_scaling_exp: Float64) -> Float64:
        return tower_fixed_cost * exp(tower_cost_scaling_exp * (h_tower - h_rec / 2.0 + h_helio / 2.0))

    @staticmethod
    def receiver_cost(A_rec: Float64, rec_ref_cost: Float64, rec_ref_area: Float64, rec_cost_scaling_exp: Float64) -> Float64:
        return rec_ref_cost * pow(A_rec / rec_ref_area, rec_cost_scaling_exp)

    @staticmethod
    def tes_cost(Q_storage: Float64, tes_spec_cost: Float64) -> Float64:
        return Q_storage * 1.0E3 * tes_spec_cost

    @staticmethod
    def power_cycle_cost(W_dot_design: Float64, power_cycle_spec_cost: Float64) -> Float64:
        return W_dot_design * 1.0E3 * power_cycle_spec_cost

    @staticmethod
    def rad_field_totcost(rad_area: Float64, panelcost: Float64, panelinstallcost: Float64) -> Float64:
        return rad_area * (panelcost + panelinstallcost)

    @staticmethod
    def rad_fluid_totcost(rad_vol: Float64, fluidcost: Float64, muliplier_volume: Float64) -> Float64:
        return rad_vol * 1000.0 * muliplier_volume * fluidcost

    @staticmethod
    def rad_storage_totcost(cold_volume: Float64, storagecost: Float64) -> Float64:
        return cold_volume * 1000.0 * storagecost

    @staticmethod
    def bop_cost(W_dot_design: Float64, bop_spec_cost: Float64) -> Float64:
        return W_dot_design * 1.0E3 * bop_spec_cost

    @staticmethod
    def fossil_backup_cost(W_dot_design: Float64, fossil_backup_spec_cost: Float64) -> Float64:
        return W_dot_design * 1.0E3 * fossil_backup_spec_cost

    @staticmethod
    def direct_capital_precontingency_cost(
        site_improvement_cost: Float64,
        heliostat_cost: Float64,
        tower_cost: Float64,
        receiver_cost: Float64,
        tes_cost: Float64,
        power_cycle_cost: Float64,
        rad_field_totcost: Float64,
        rad_fluid_totcost: Float64,
        rad_storage_totcost: Float64,
        bop_cost: Float64,
        fossil_backup_cost: Float64) -> Float64:
        return site_improvement_cost + \
            heliostat_cost + \
            tower_cost + \
            receiver_cost + \
            tes_cost + \
            power_cycle_cost + \
            rad_field_totcost + \
            rad_fluid_totcost + \
            rad_storage_totcost + \
            bop_cost + \
            fossil_backup_cost

    @staticmethod
    def contingency_cost(contingency_rate: Float64, direct_capital_precontingency_cost: Float64) -> Float64:
        return contingency_rate / 100.0 * direct_capital_precontingency_cost

    @staticmethod
    def total_direct_cost(direct_capital_precontingency_cost: Float64, contingency_cost: Float64) -> Float64:
        return direct_capital_precontingency_cost + contingency_cost

    @staticmethod
    def total_land_cost(total_land_area: Float64, total_direct_cost: Float64, plant_net_capacity: Float64,
        land_spec_cost: Float64, land_perc_direct_cost: Float64, land_spec_per_power_cost: Float64, land_fixed_cost: Float64) -> Float64:
        return total_land_area * land_spec_cost + \
            total_direct_cost * land_perc_direct_cost / 100.0 + \
            plant_net_capacity * 1.0E6 * land_spec_per_power_cost + \
            land_fixed_cost

    @staticmethod
    def epc_and_owner_cost(total_land_area: Float64, total_direct_cost: Float64, plant_net_capacity: Float64,
        land_spec_cost: Float64, land_perc_direct_cost: Float64, land_spec_per_power_cost: Float64, land_fixed_cost: Float64) -> Float64:
        return total_land_area * land_spec_cost + \
            total_direct_cost * land_perc_direct_cost / 100.0 + \
            plant_net_capacity * 1.0E6 * land_spec_per_power_cost + \
            land_fixed_cost

    @staticmethod
    def sales_tax_cost(total_direct_cost: Float64, sales_tax_basis: Float64, sales_tax_rate: Float64) -> Float64:
        return total_direct_cost * (sales_tax_basis / 100.0) * (sales_tax_rate / 100.0)

    @staticmethod
    def total_indirect_cost(total_land_cost: Float64, epc_and_owner_cost: Float64, sales_tax_cost: Float64) -> Float64:
        return total_land_cost + epc_and_owner_cost + sales_tax_cost

    @staticmethod
    def total_installed_cost(total_direct_cost: Float64, total_indirect_cost: Float64) -> Float64:
        return total_direct_cost + total_indirect_cost

    @staticmethod
    def estimated_installed_cost_per_cap(total_installed_cost: Float64, plant_net_capacity: Float64) -> Float64:
        return total_installed_cost / (plant_net_capacity * 1.0E3)

struct N_financial_parameters:
    @staticmethod
    def construction_financing_total_cost(
        total_installed_cost: Float64,
        const_per_interest_rate1: Float64, const_per_interest_rate2: Float64, const_per_interest_rate3: Float64, const_per_interest_rate4: Float64, const_per_interest_rate5: Float64,
        const_per_months1: Float64, const_per_months2: Float64, const_per_months3: Float64, const_per_months4: Float64, const_per_months5: Float64,
        const_per_percent1: Float64, const_per_percent2: Float64, const_per_percent3: Float64, const_per_percent4: Float64, const_per_percent5: Float64,
        const_per_upfront_rate1: Float64, const_per_upfront_rate2: Float64, const_per_upfront_rate3: Float64, const_per_upfront_rate4: Float64, const_per_upfront_rate5: Float64,
        inout const_per_principal1: Float64, inout const_per_principal2: Float64, inout const_per_principal3: Float64, inout const_per_principal4: Float64, inout const_per_principal5: Float64,
        inout const_per_interest1: Float64, inout const_per_interest2: Float64, inout const_per_interest3: Float64, inout const_per_interest4: Float64, inout const_per_interest5: Float64,
        inout const_per_total1: Float64, inout const_per_total2: Float64, inout const_per_total3: Float64, inout const_per_total4: Float64, inout const_per_total5: Float64,
        inout const_per_percent_total: Float64, inout const_per_principal_total: Float64, inout const_per_interest_total: Float64, inout construction_financing_cost: Float64):
        const_per_principal1 = const_per_percent1 * total_installed_cost / 100.0
        N_financial_parameters.construction_financing_loan_cost(const_per_principal1, const_per_interest_rate1, const_per_months1, const_per_upfront_rate1,
            const_per_interest1, const_per_total1)
        const_per_principal2 = const_per_percent2 * total_installed_cost / 100.0
        N_financial_parameters.construction_financing_loan_cost(const_per_principal2, const_per_interest_rate2, const_per_months2, const_per_upfront_rate2,
            const_per_interest2, const_per_total2)
        const_per_principal3 = const_per_percent3 * total_installed_cost / 100.0
        N_financial_parameters.construction_financing_loan_cost(const_per_principal3, const_per_interest_rate3, const_per_months3, const_per_upfront_rate3,
            const_per_interest3, const_per_total3)
        const_per_principal4 = const_per_percent4 * total_installed_cost / 100.0
        N_financial_parameters.construction_financing_loan_cost(const_per_principal4, const_per_interest_rate4, const_per_months4, const_per_upfront_rate4,
            const_per_interest4, const_per_total4)
        const_per_principal5 = const_per_percent5 * total_installed_cost / 100.0
        N_financial_parameters.construction_financing_loan_cost(const_per_principal5, const_per_interest_rate5, const_per_months5, const_per_upfront_rate5,
            const_per_interest5, const_per_total5)
        const_per_percent_total = const_per_percent1 + const_per_percent2 + const_per_percent3 + const_per_percent4 + const_per_percent5
        const_per_principal_total = const_per_principal1 + const_per_principal2 + const_per_principal3 + const_per_principal4 + const_per_principal5
        const_per_interest_total = const_per_interest1 + const_per_interest2 + const_per_interest3 + const_per_interest4 + const_per_interest5
        construction_financing_cost = const_per_total1 + const_per_total2 + const_per_total3 + const_per_total4 + const_per_total5

    @staticmethod
    def construction_financing_loan_cost(principal: Float64, interest_rate: Float64, term_months: Float64, upfront_rate: Float64,
        inout interest: Float64, inout total_cost: Float64):
        var r: Float64 = interest_rate / 100.0
        interest = principal * r / 12.0 * term_months / 2.0
        var u: Float64 = upfront_rate / 100.0
        total_cost = principal * u + interest
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
from core import *
from lib_weatherfile import *
from common import *
from util import *

struct VarInfo:
    var vartype: Int32
    var dtype: Int32
    var name: String
    var label: String
    var units: String
    var group: String
    var uihint: String
    var uitype: String
    var defval: String
    var constraints: String

# Define var_info sentinel
var var_info_invalid = VarInfo(0,0,"","","","","","","","")

# Helper to create SSC constants (these should be defined in core)
alias SSC_INPUT: Int32 = 0
alias SSC_OUTPUT: Int32 = 1
alias SSC_NUMBER: Int32 = 0
alias SSC_STRING: Int32 = 1
alias SSC_ARRAY: Int32 = 2

# Static var_info array (replicated from C++)
var _cm_vtab_biomass: List[VarInfo] = List[VarInfo]()
# Populate with entries...
# (Due to length, we'll define a function to build the list)
def init_var_info()->List[VarInfo]:
    var list = List[VarInfo]()
    list.append(VarInfo(SSC_INPUT, SSC_STRING, "file_name", "Local weather file path", "", "", "biopower", "*", "LOCAL_FILE", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total", "Total fuel resource (dt/yr)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_biomass", "Total biomass resource (dt/yr)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_moisture", "Overall Moisture Content (dry %)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_coal", "Total coal resource (dt/yr)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_lhv", "Dry feedstock LHV (Btu/lb)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_hhv", "Dry feedstock HHV (Btu/lb)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_c", "Mass fraction carbon", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_biomass_c", "Biomass fraction carbon", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.total_h", "Mass fraction hydrogen", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.bagasse_frac", "Bagasse feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.barley_frac", "Barley feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.stover_frac", "Stover feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.rice_frac", "Rice straw feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.wheat_frac", "Wheat straw feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.forest_frac", "Forest residue feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.mill_frac", "Mill residue feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.mill_c", "Carbon fraction in mill residue", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.urban_frac", "Urban wood residue feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.urban_c", "Carbon fraction in urban residue", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.woody_frac", "Woody energy crop feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.woody_c", "Carbon fraction in woody energy crop", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.herb_frac", "Herbaceous energy crop feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.herb_c", "Carbon fraction in herbaceous energy crop", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.additional_opt", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock1_resource", "Opt feedstock 1 (dt/yr)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock2_resource", "Opt feedstock 2 (dt/yr)", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock1_c", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock2_c", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock1_h", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock2_h", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock1_hhv", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock2_hhv", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock1_frac", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock2_frac", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.bit_frac", "Bituminos coal feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.subbit_frac", "Sub-bituminous coal feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.lig_frac", "Lignite coal feedstock fraction", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.bagasse_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.barley_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.stover_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.rice_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.wheat_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.forest_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.mill_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.urban_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.woody_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.herb_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock1_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.feedstock2_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.bit_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.subbit_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.lig_moisture", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.feedstock.collection_radius", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.avoided_cred", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.collection_fuel", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.transport_fuel", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.transport_legs", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.transport_predist", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.transport_long", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.transport_longmiles", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.transport_longopt", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.pre_chipopt", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.pre_grindopt", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.pre_pelletopt", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.emissions.grid_intensity", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.drying_method", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.drying_spec", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.combustor_type", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.boiler.air_feed", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.boiler.flue_temp", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.boiler.steam_enthalpy", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.boiler.num", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.boiler.cap_per_boiler", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.nameplate", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.rated_eff", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.min_load", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.max_over_design", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.boiler.over_design", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.cycle_design_temp", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.pl_eff_f0", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.pl_eff_f1", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.pl_eff_f2", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.pl_eff_f3", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.pl_eff_f4", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.temp_eff_f0", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.temp_eff_f1", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.temp_eff_f2", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.temp_eff_f3", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.temp_eff_f4", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.temp_corr_mode", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.temp_eff_f4", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.par_percent", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.tou_option", "", "", "", "biopower", "*", "INTEGER", ""))
    list.append(VarInfo(SSC_INPUT, SSC_ARRAY, "biopwr.plant.disp.power", "", "", "", "biopower", "*", "LENGTH=9", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.ramp_rate", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_STRING, "biopwr.plant.tou_grid", "", "", "", "biopower", "*", "", ""))
    list.append(VarInfo(SSC_INPUT, SSC_NUMBER, "biopwr.plant.boiler.steam_pressure", "", "", "", "biopower", "*", "", ""))
    # NOTE: Some inputs are commented out; we keep them as comments in the Mojo file (not included in list)
    # Outputs
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "hourly_q_to_pb", "Q To Power Block", "kW", "", "biomass", "*", "LENGTH=8760", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "hourly_boiler_eff", "Boiler Efficiency", "", "", "biomass", "*", "LENGTH=8760", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "hourly_pbeta", "Power Block Efficiency", "", "", "biomass", "*", "LENGTH=8760", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_energy", "Monthly Energy", "kWh", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_q_to_pb", "Q To Power Block", "kWh", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_pb_eta", "Power Block Effiency", "%", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_boiler_eff", "Total Boiler Efficiency - HHV (%)", "%", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_moist", "Monthly biomass moisture fraction (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_lhv_heatrate", "Net Monthly Heat Rate (MMBtu/MWh)", "MMBtu/MWh", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_hhv_heatrate", "Gross Monthly Heat Rate (MMBtu/MWh)", "MMBtu/MWh", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_bagasse_emc", "Monthly bagasse EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_barley_emc", "Monthly barley EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_stover_emc", "Monthly stover EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_rice_emc", "Monthly rice straw EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_wheat_emc", "Monthly wheat straw EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_forest_emc", "Monthly forest EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_mill_emc", "Monthly mill waste EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_urban_emc", "Monthly urban wood waste EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_woody_emc", "Monthly woody crop EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_herb_emc", "Monthly herbaceous crop EMC (dry)", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_temp_c", "Temperature", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_ARRAY, "monthly_rh", "Relative humidity", "", "", "biomass", "*", "LENGTH=12", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual Energy", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.e_net", "Gross Annual Energy", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.biomass", "Annual biomass usage", "dry tons/yr", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.coal", "Annual coal usage", "dry tons/yr", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual Fuel Usage", "kWht", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "annual_watter_usage", "Annual Water Usage", "m3", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.ash", "Ash produced", "tons/yr", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.capfactor", "Annual Capacity Factor (%)", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.hhv_heatrate", "Gross Heat Rate (MMBtu/MWh)", "MMBtu/MWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.lhv_heatrate", "Net Heat Rate (MMBtu/MWh)", "MMBtu/MWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "Heat Rate Conversion Factor (MMBTUs/MWhe)", "MMBTUs/MWhe", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.hhv_thermeff", "Thermal efficiency, HHV (%)", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.lhv_thermeff", "Thermal efficiency, LHV (%)", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.total_moisture", "Overall Moisture Content (dry %)", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.growth", "Biomass Collection", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.avoided", "Biomass Avoided Use", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.transport", "Biomass Transport", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.preprocessing", "Biomass Preprocessing", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.drying", "Biomass Drying", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.combustion", "Combustion", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.uptake", "Biomass CO2 Uptake", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.total_sum", "Biomass Life Cycle CO2", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.diesel", "Life Cycle Diesel use", "Btu/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.biodiesel", "Life Cycle Biodiesel use", "Btu/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.bunker", "Life Cycle Bunker fuel use", "Btu/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.oil", "Life Cycle Oil use", "Btu/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.naturalgas", "Life Cycle Natural gas use", "Btu/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.nitrogen", "Life Cycle Nitrogen fertilizer use", "lb N/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.potassium", "Life Cycle Potassium fertilizer use", "lb P2O5/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.phosphorus", "Life Cycle Phosphorus fertilizer use", "lb K2O/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.lime", "Life Cycle Lime fertilizer use", "lb Lime/kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.emissions.ems_per_lb", "Life Cycle g CO2eq released/lb dry biomass", "", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_fuel_kwh", "Energy lost in fuel out of boiler", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_unburn_kwh", "Energy lost in unburned fuel", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_manu_kwh", "Energy loss included in manufacturer's margin", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_rad_kwh", "Energy loss due to boiler radiation", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_dry_kwh", "Energy lost in hot flue gas", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_wet_kwh", "Energy lost to moisture in air", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.pb_eta_kwh", "Energy lost in steam turbine and generator", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.par_loss_kwh", "Energy consumed within plant - parasitic load", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_total_kwh", "Energy lost in boiler - total", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_output", "Boiler output", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.turbine_output", "Turbine output", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_fuel", "Energy lost in fuel out of boiler", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_unburn", "Energy lost in unburned fuel", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_manu", "Energy loss included in manufacturer's margin", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_rad", "Energy loss due to boiler radiation", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_dry", "Energy lost in hot flue gas", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_wet", "Energy lost to moisture in air", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.pb_eta", "Energy lost in steam turbine and generator", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.par_loss", "Energy consumed within plant - parasitic load", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.boiler_loss_total", "Energy lost in boiler - total", "%", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.qtoboil_tot", "Q to Boiler", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "system.annual.qtopb_tot", "Q to Power Block", "kWh", "", "biomass", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "*", "", ""))
    list.append(VarInfo(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "", "*", "", ""))
    list.append(var_info_invalid)  # sentinel
    return list

# Initialize static var_info
var _cm_vtab_biomass = init_var_info()

# Define the compute module class
struct cm_biomass:
    var self: compute_module

    def __init__(inout self):
        self.self = compute_module()
        self.self.add_var_info(_cm_vtab_biomass)
        self.self.add_var_info(vtab_adjustment_factors)
        self.self.add_var_info(vtab_technology_outputs)

    def exec(inout self):
        static nday: List[Int32] = List[Int32](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
        var dry: List[Float64] = List[Float64](10, 0.0)
        var wet: List[Float64] = List[Float64](10, 0.0)
        var harv_moist: List[List[Float64]] = List[List[Float64]](15, List[Float64](12, 0.0))
        dry[0] = (self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.bagasse_frac")) + \
             (self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.feedstock1_frac")) + \
             (self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.feedstock2_frac"))
        dry[1] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.barley_frac")
        dry[2] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.stover_frac")
        dry[3] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.rice_frac")
        dry[4] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.wheat_frac")
        dry[5] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.forest_frac")
        dry[6] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.mill_frac")
        dry[7] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.urban_frac")
        dry[8] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.woody_frac")
        dry[9] = self.self.as_double("biopwr.feedstock.total") * self.self.as_double("biopwr.feedstock.herb_frac")
        wet[0] = dry[0] * (1.0 + (self.self.as_double("biopwr.feedstock.bagasse_moisture") / 100.0))
        wet[1] = dry[1] * (1.0 + (self.self.as_double("biopwr.feedstock.barley_moisture") / 100.0))
        wet[2] = dry[2] * (1.0 + (self.self.as_double("biopwr.feedstock.stover_moisture") / 100.0))
        wet[3] = dry[3] * (1.0 + (self.self.as_double("biopwr.feedstock.rice_moisture") / 100.0))
        wet[4] = dry[4] * (1.0 + (self.self.as_double("biopwr.feedstock.wheat_moisture") / 100.0))
        wet[5] = dry[5] * (1.0 + (self.self.as_double("biopwr.feedstock.forest_moisture") / 100.0))
        wet[6] = dry[6] * (1.0 + (self.self.as_double("biopwr.feedstock.mill_moisture") / 100.0))
        wet[7] = dry[7] * (1.0 + (self.self.as_double("biopwr.feedstock.urban_moisture") / 100.0))
        wet[8] = dry[8] * (1.0 + (self.self.as_double("biopwr.feedstock.woody_moisture") / 100.0))
        wet[9] = dry[9] * (1.0 + (self.self.as_double("biopwr.feedstock.herb_moisture") / 100.0))
        var wet_total: Float64 = 0.0
        var dry_total: Float64 = 0.0
        for i in range(10):
            wet_total += wet[i]
            dry_total += dry[i]
        var collection_radius: Float64 = self.self.as_double("biopwr.feedstock.collection_radius")
        var transport_fuel: Int32 = self.self.as_integer("biopwr.emissions.transport_fuel")
        var transport_legs: Int32 = self.self.as_integer("biopwr.emissions.transport_legs")
        var transport_predist: Float64 = self.self.as_double("biopwr.emissions.transport_predist")
        var transport_longmiles: Float64 = self.self.as_double("biopwr.emissions.transport_longmiles")
        var transport_longopt: Int32 = self.self.as_integer("biopwr.emissions.transport_longopt")
        var pre_chipopt: Int32 = self.self.as_integer("biopwr.emissions.pre_chipopt")
        var pre_grindopt: Int32 = self.self.as_integer("biopwr.emissions.pre_grindopt")
        var pre_pelletopt: Int32 = self.self.as_integer("biopwr.emissions.pre_pelletopt")
        var frac_c: Float64 = self.self.as_double("biopwr.feedstock.total_c")
        var biomass_frac_c: Float64 = self.self.as_double("biopwr.feedstock.total_biomass_c")
        var waste_c: List[Float64] = List[Float64](2, 0.0)
        waste_c[0] = self.self.as_double("biopwr.feedstock.mill_c")
        waste_c[1] = self.self.as_double("biopwr.feedstock.urban_c")
        var grid_intensity: Float64 = self.self.as_double("biopwr.emissions.grid_intensity")
        # rad_table 18x6
        var rad_table: List[List[Float64]] = List[List[Float64]](
            List[Float64](1.60, 2.00, 2.67, 3.20, 4.00, 8.00),
            List[Float64](1.05, 1.31, 1.75, 2.10, 2.62, 5.25),
            List[Float64](0.84, 1.05, 1.40, 1.68, 2.10, 4.20),
            List[Float64](0.73, 0.91, 1.22, 1.46, 1.82, 3.65),
            List[Float64](0.66, 0.82, 1.10, 1.32, 1.65, 3.30),
            List[Float64](0.62, 0.78, 1.03, 1.24, 1.55, 3.10),
            List[Float64](0.59, 0.74, 0.98, 1.18, 1.48, 2.95),
            List[Float64](0.56, 0.70, 0.93, 1.12, 1.40, 2.80),
            List[Float64](0.54, 0.68, 0.90, 1.08, 1.35, 2.70),
            List[Float64](0.52, 0.65, 0.87, 1.04, 1.30, 2.60),
            List[Float64](0.48, 0.60, 0.80, 0.96, 1.20, 2.40),
            List[Float64](0.45, 0.56, 0.75, 0.90, 1.12, 2.25),
            List[Float64](0.43, 0.54, 0.72, 0.86, 1.08, 2.15),
            List[Float64](0.40, 0.50, 0.67, 0.80, 1.00, 2.00),
            List[Float64](0.38, 0.48, 0.63, 0.76, 0.95, 1.90),
            List[Float64](0.30, 0.40, 0.50, 0.60, 0.80, 1.50),
            List[Float64](0.24, 0.29, 0.39, 0.45, 0.58, 1.20),
            List[Float64](0.18, 0.25, 0.35, 0.38, 0.50, 0.92)
        )
        var rad_col: List[Float64] = List[Float64](10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 120.0, 140.0, 160.0, 180.0, 200.0, 400.0, 1000.0, 2000.0)
        var rad_row: List[Float64] = List[Float64](100.0, 80.0, 60.0, 50.0, 40.0, 20.0)
        var lhv: Float64 = self.self.as_double("biopwr.feedstock.total_lhv")
        var hhv: Float64 = self.self.as_double("biopwr.feedstock.total_hhv")
        var hydrogen: Float64 = self.self.as_double("biopwr.feedstock.total_h")
        var boiler_capacity: Float64 = self.self.as_double("biopwr.plant.boiler.cap_per_boiler")
        var steam_enth: Float64 = self.self.as_double("biopwr.plant.boiler.steam_enthalpy")
        var boiler_num: Float64 = self.self.as_double("biopwr.plant.boiler.num")
        var total: Float64 = self.self.as_double("biopwr.feedstock.total")
        var total_biomass: Float64 = self.self.as_double("biopwr.feedstock.total_biomass")
        var total_coal: Float64 = self.self.as_double("biopwr.feedstock.total_coal")
        var max_turb: Float64 = self.self.as_double("biopwr.plant.max_over_design")
        var max_boil: Float64 = self.self.as_double("biopwr.plant.boiler.over_design") / 100.0 + 1.0
        var steam_pressure: Float64 = self.self.as_double("biopwr.plant.boiler.steam_pressure")
        var tou_opt: Int32 = self.self.as_integer("biopwr.plant.tou_option")
        var tou: List[Int32] = List[Int32](8760, 0)
        for i in range(8760):
            tou[i] = 0
        var ramp_rate: Float64 = self.self.as_double("biopwr.plant.ramp_rate") / 100.0
        var disp: Pointer[Float64] = Pointer[Float64]()
        var disp_count: Int = 0
        if tou_opt == 1:
            disp = self.self.as_array("biopwr.plant.disp.power", &disp_count)
            for i in range(disp_count):
                if disp[i] > max_turb:
                    throw exec_error("biopower", util.format("fractional generation capacity exceeds turbine design for Period %d", i+1))
                    return
                if disp[i] > max_boil:
                    throw exec_error("biopower", util.format("fractional generation capacity exceeds boiler design for Period %d", i+1))
                    return
            # char *sched = (char*)as_string(...) -- Mojo string
            var sched: String = self.self.as_string("biopwr.plant.tou_grid")
            if not util.translate_schedule(tou, sched, sched, 0, 8):
                throw exec_error("biopower", "could not translate schedule for time-of-use rate")
        var dry_opt: Int32 = self.self.as_integer("biopwr.plant.drying_method")
        var burn_opt: Int32 = self.self.as_integer("biopwr.plant.combustor_type")
        var dry_spec: Float64 = self.self.as_double("biopwr.plant.drying_spec") / 100.0
        var Wdesign: Float64 = self.self.as_double("biopwr.plant.nameplate")
        var rated_eff: Float64 = self.self.as_double("biopwr.plant.rated_eff")
        var min_load: Float64 = self.self.as_double("biopwr.plant.min_load")
        var max_over: Float64 = self.self.as_double("biopwr.plant.max_over_design")
        var design_temp: Float64 = (self.self.as_double("biopwr.plant.cycle_design_temp") - 32.0) * 5.0 / 9.0
        var temp_mode: Int32 = self.self.as_integer("biopwr.plant.temp_corr_mode")
        var flue_temp: Float64 = self.self.as_double("biopwr.plant.boiler.flue_temp")
        var par: Float64 = self.self.as_double("biopwr.plant.par_percent") / 100.0
        var air_feed: Float64 = self.self.as_double("biopwr.plant.boiler.air_feed")
        var total_heat_in: Float64 = (total * 2000.0 * hhv) / 1000000.0 / 8760.0
        var fw_enth_out: Float64 = (((0.00003958 * flue_temp) + 0.4329) * flue_temp) + 1062.2
        var add_opt: Int32 = self.self.as_integer("biopwr.feedstock.additional_opt")
        if add_opt == 1:
            for i in range(2):
                var resource: Float64 = self.self.as_double(util.format("biopwr.feedstock.feedstock%d_resource", i + 1))
                if resource > 0:
                    var hv: Float64 = self.self.as_double(util.format("biopwr.feedstock.feedstock%d_hhv", i + 1))
                    var hc: Float64 = self.self.as_double(util.format("biopwr.feedstock.feedstock%d_c", i + 1))
                    var hh: Float64 = self.self.as_double(util.format("biopwr.feedstock.feedstock%d_h", i + 1))
                    if hv == 0:
                        throw exec_error("biopower", util.format("did not fully specify additional Feedstock %d, add HHV", i + 1))
                        return
                    if hc == 0:
                        throw exec_error("biopower", util.format("did not fully specify additional Feedstock %d, add carbon content", i + 1))
                        return
                    if hh == 0:
                        throw exec_error("biopower", util.format("Did not fully specify additional Feedstock %d, add hydrogen content", i + 1))
                        return
        var wFile: weatherfile = weatherfile(self.self.as_string("file_name"))
        if not wFile.ok():
            throw exec_error("biopower", wFile.message())
        if wFile.has_message():
            self.self.log(wFile.message(), SSC_WARNING)
        var etaQ: List[Float64] = List[Float64](5, 0.0)
        var etaT: List[Float64] = List[Float64](5, 0.0)
        var frac: List[Float64] = List[Float64](15, 0.0)
        frac[0] = self.self.as_double("biopwr.feedstock.bagasse_frac")
        frac[1] = self.self.as_double("biopwr.feedstock.barley_frac")
        frac[2] = self.self.as_double("biopwr.feedstock.stover_frac")
        frac[3] = self.self.as_double("biopwr.feedstock.rice_frac")
        frac[4] = self.self.as_double("biopwr.feedstock.wheat_frac")
        frac[5] = self.self.as_double("biopwr.feedstock.forest_frac")
        frac[6] = self.self.as_double("biopwr.feedstock.mill_frac")
        frac[7] = self.self.as_double("biopwr.feedstock.urban_frac")
        frac[8] = self.self.as_double("biopwr.feedstock.woody_frac")
        frac[9] = self.self.as_double("biopwr.feedstock.herb_frac")
        frac[10] = self.self.as_double("biopwr.feedstock.feedstock1_frac")
        frac[11] = self.self.as_double("biopwr.feedstock.feedstock2_frac")
        frac[12] = self.self.as_double("biopwr.feedstock.bit_frac")
        frac[13] = self.self.as_double("biopwr.feedstock.subbit_frac")
        frac[14] = self.self.as_double("biopwr.feedstock.lig_frac")
        var moisture: List[Float64] = List[Float64](15, 0.0)
        moisture[0] = self.self.as_double("biopwr.feedstock.bagasse_moisture") / 100.0
        moisture[1] = self.self.as_double("biopwr.feedstock.barley_moisture") / 100.0
        moisture[2] = self.self.as_double("biopwr.feedstock.stover_moisture") / 100.0
        moisture[3] = self.self.as_double("biopwr.feedstock.rice_moisture") / 100.0
        moisture[4] = self.self.as_double("biopwr.feedstock.wheat_moisture") / 100.0
        moisture[5] = self.self.as_double("biopwr.feedstock.forest_moisture") / 100.0
        moisture[6] = self.self.as_double("biopwr.feedstock.mill_moisture") / 100.0
        moisture[7] = self.self.as_double("biopwr.feedstock.urban_moisture") / 100.0
        moisture[8] = self.self.as_double("biopwr.feedstock.woody_moisture") / 100.0
        moisture[9] = self.self.as_double("biopwr.feedstock.herb_moisture") / 100.0
        moisture[10] = self.self.as_double("biopwr.feedstock.feedstock1_moisture") / 100.0
        moisture[11] = self.self.as_double("biopwr.feedstock.feedstock2_moisture") / 100.0
        moisture[12] = self.self.as_double("biopwr.feedstock.bit_moisture") / 100.0
        moisture[13] = self.self.as_double("biopwr.feedstock.subbit_moisture") / 100.0
        moisture[14] = self.self.as_double("biopwr.feedstock.lig_moisture") / 100.0
        for i in range(15):
            for j in range(12):
                harv_moist[i][j] = moisture[i]
        for i in range(5):
            etaQ[i] = self.self.as_double(util.format("biopwr.plant.pl_eff_f%d", i))
            etaT[i] = self.self.as_double(util.format("biopwr.plant.temp_eff_f%d", i))
        var coll_fuel: Int32 = self.self.as_integer("biopwr.emissions.collection_fuel")
        var av_cred: Int32 = self.self.as_integer("biopwr.emissions.avoided_cred")
        var annual_output: Float64 = 0.0
        var air_moist: Float64 = 0.0
        var pp_water: Float64 = 0.0
        var temp_c: Pointer[Float64] = self.self.allocate("monthly_temp_c", 12)
        var temp_f: List[Float64] = List[Float64](12, 0.0)
        var temp_k: List[Float64] = List[Float64](12, 0.0)
        var rh: Pointer[Float64] = self.self.allocate("monthly_rh", 12)
        var w_per_hv: List[Float64] = List[Float64](12, 0.0)
        var fuel_eff_loss: List[Float64] = List[Float64](12, 0.0)
        var boiler_eff: Pointer[Float64] = self.self.allocate("monthly_boiler_eff", 12)
        var moist: Pointer[Float64] = self.self.allocate("monthly_moist", 12)
        var moist_b: List[Float64] = List[Float64](12, 0.0)
        var emc: List[Float64] = List[Float64](12, 0.0)
        var capfactor: List[Float64] = List[Float64](12, 0.0)
        var heatrate_hhv: Pointer[Float64] = self.self.allocate("monthly_hhv_heatrate", 12)
        var heatrate_lhv: Pointer[Float64] = self.self.allocate("monthly_lhv_heatrate", 12)
        var bagasse_emc: Pointer[Float64] = self.self.allocate("monthly_bagasse_emc", 12)
        var barley_emc: Pointer[Float64] = self.self.allocate("monthly_barley_emc", 12)
        var stover_emc: Pointer[Float64] = self.self.allocate("monthly_stover_emc", 12)
        var rice_emc: Pointer[Float64] = self.self.allocate("monthly_rice_emc", 12)
        var wheat_emc: Pointer[Float64] = self.self.allocate("monthly_wheat_emc", 12)
        var forest_emc: Pointer[Float64] = self.self.allocate("monthly_forest_emc", 12)
        var mill_emc: Pointer[Float64] = self.self.allocate("monthly_mill_emc", 12)
        var urban_emc: Pointer[Float64] = self.self.allocate("monthly_urban_emc", 12)
        var woody_emc: Pointer[Float64] = self.self.allocate("monthly_woody_emc", 12)
        var herb_emc: Pointer[Float64] = self.self.allocate("monthly_herb_emc", 12)
        var _twet: List[Float64] = List[Float64](8760, 0.0)
        var _twetc: List[Float64] = List[Float64](8760, 0.0)
        var _tdry: List[Float64] = List[Float64](8760, 0.0)
        var _rh: List[Float64] = List[Float64](8760, 0.0)
        var _it: List[Float64] = List[Float64](8760, 0.0)
        var _wet_air_eff_loss: List[Float64] = List[Float64](8760, 0.0)
        var _dry_eff_loss: List[Float64] = List[Float64](8760, 0.0)
        var _boiler_eff: Pointer[Float64] = self.self.allocate("hourly_boiler_eff", 8760)
        var _etaa: Pointer[Float64] = self.self.allocate("monthly_pb_eta", 12)
        _twet[1] = 1000.0
        for i in range(12):
            temp_c[i] = 0.0
            rh[i] = 0.0
            moist[i] = 0.0
            moist_b[i] = 0.0
            emc[i] = 0.0
            capfactor[i] = 0.0
            heatrate_hhv[i] = 0.0
            heatrate_lhv[i] = 0.0
            _etaa[i] = 0.0
            bagasse_emc[i] = 0.0
            barley_emc[i] = 0.0
            stover_emc[i] = 0.0
            rice_emc[i] = 0.0
            wheat_emc[i] = 0.0
            forest_emc[i] = 0.0
            mill_emc[i] = 0.0
            urban_emc[i] = 0.0
            woody_emc[i] = 0.0
            herb_emc[i] = 0.0
            boiler_eff[i] = 0.0
        var tous: List[Float64] = List[Float64](8760, 0.0)
        var total_wair_eff_loss: Float64 = 0.0
        var total_dry_eff_loss: Float64 = 0.0
        var wf: weather_record = weather_record()
        var istep: Int32 = 0
        var nstep: Int32 = Int32(wFile.nrecords())
        while wFile.read(&wf) and istep < 8760:
            if istep % (nstep / 20) == 0:
                self.self.update("", 100.0 * Float64(istep) / Float64(nstep), Float64(istep))
            if std.isnan(wf.rhum):
                throw exec_error("biopower", "weather file does not contain relative humidity data required to calculate air moisture")
                return
            var iMonth: Int32 = util.month_of(Float64(istep)) - 1
            temp_c[iMonth] += Float64(wf.tdry / (nday[iMonth] * 24.0))
            rh[iMonth] += Float64(wf.rhum / (nday[iMonth] * 24.0) / 100.0)
            _twet[istep] = wf.twet
            _tdry[istep] = wf.tdry
            _rh[istep] = wf.rhum / 100.0
            pp_water = _rh[istep] * (exp(77.3450 + (0.0057 * (wf.tdry + 273.15)) - (7235 / (wf.tdry + 273.15))) / pow((wf.tdry + 273.15), 8.2)) * 0.000145037738
            air_moist = 0.622 * pp_water / ((wf.pres * 0.0145037738) - pp_water)
            _wet_air_eff_loss[istep] = (air_feed * air_moist * 0.0045 * (flue_temp - ((wf.tdry * 9.0 / 5.0) + 32))) / 100.0
            _dry_eff_loss[istep] = (0.0024 * air_feed * (flue_temp - ((wf.tdry * 9.0 / 5.0) + 32))) / 100.0
            if tou_opt == 1 and disp_count > 0:
                tous[istep] = disp[tou[istep]]
            istep += 1
        if temp_mode == 1 and _twet[1] == 1000:
            _twet[1] = 0.0
            # commented out loop, preserve structure
            for i in range(8760):
                _twetc[i] = guess  # note: guess not defined in C++? The C++ code has broken logic, but we replicate exactly.
        for i in range(12):
            temp_f[i] = (temp_c[i] * 9.0 / 5.0) + 32.0
            temp_k[i] = temp_c[i] + 273.15
        var manu_eff_loss: Float64 = 0.040
        var unburn_eff_loss: Float64 = 0.0
        if burn_opt == 0:
            unburn_eff_loss = 0.035
        elif burn_opt == 1:
            unburn_eff_loss = 0.0025
        elif burn_opt == 2:
            unburn_eff_loss = 0.030
        var _moist_b: Float64 = 0.0
        var _moist: Float64 = 0.0
        var total_fuel_eff_loss: Float64 = 0.0
        for i in range(12):
            if dry_opt == 0:
                for j in range(15):
                    moist[i] += Float64(frac[j] * harv_moist[j][i])
            elif dry_opt == 1:
                for j in range(15):
                    if j == 0 and frac[j] != 0:
                        var const_w: Float64 = -57.7 - (0.1982 * temp_k[i]) + (22.305 * sqrt(temp_k[i]))
                        var const_k: Float64 = -2778.14 - (2042.09 * temp_k[i]) + (5238.88 * sqrt(temp_k[i]))
                        var const_k1: Float64 = -70.42 - (13.68 * temp_k[i]) + (180.22 * sqrt(temp_k[i]))
                        var const_k2: Float64 = 194.01 + (0.62 * temp_k[i]) + (51.48 * sqrt(temp_k[i]))
                        var bag: Float64 = (((1800.0 / const_w) * (((const_k * rh[i] * 100.0) / (1 - (const_k * rh[i] * 100.0))) + (((const_k1 * const_k * rh[i] * 100.0) + (2 * const_k1 * const_k2 * const_k * const_k * rh[i] * 100.0 * rh[i] * 100.0)) / (1 + (const_k1 * const_k * rh[i] * 100.0) + (const_k1 * const_k2 * const_k * const_k * rh[i] * 100.0 * rh[i] * 100.0))))) / 100.0)
                        emc[i] += (frac[j] * bag)
                        bagasse_emc[i] = Float64(bag)
                        moist[i] += Float64(frac[j] * harv_moist[j][i])
                    elif j == 1 and frac[j] != 0:
                        var chu_a: Float64 = -475.12
                        var chu_b: Float64 = -0.14843
                        var chu_c: Float64 = 71.996
                        var bar: Float64 = (1.0 / chu_b) * log(((temp_c[i] + chu_c) / chu_a) * log(rh[i])) / 100.0
                        emc[i] += frac[j] * bar
                        barley_emc[i] = Float64(bar)
                        moist[i] += Float64(frac[j] * harv_moist[j][i])
                    elif j == 2 and frac[j] != 0:
                        var const_a: Float64 = 10.9137
                        var const_b: Float64 = -0.0746
                        var const_c: Float64 = 1.0 / 2.4116
                        var stov: Float64 = (((const_a + (const_b * temp_c[i])) * pow((rh[i] / (1.0 - rh[i])), const_c)) / 100.0)
                        emc[i] += (frac[j] * stov)
                        stover_emc[i] = Float64(stov)
                        moist[i] += Float64(frac[j] * harv_moist[j][i])
                    elif j == 3 and frac[j] != 0:
                        var const_wr: Float64 = 330 + (0.452 * temp_f[i]) + (0.00415 * temp_f[i] * temp_f[i])
                        var const_kr: Float64 = 0.791 + (0.000463 * temp_f[i]) - (0.000000844 * temp_f[i] * temp_f[i])
                        var const_k1r: Float64 = 6.34 + (0.000775 * temp_f[i]) - (0.0000935 * temp_f[i] * temp_f[i])
                        var const_k2r: Float64 = 1.09 + (0.0284 * temp_f[i]) - (0.0000904 * temp_f[i] * temp_f[i])
                        var ric: Float64 = ((1800 / const_wr) * (((const_kr * rh[i]) / (1 - (const_kr * rh[i]))) + (((const_k1r * const_kr * rh[i]) + (2 * const_k1r * const_k2r * const_kr * const_kr * rh[i] * rh[i])) / (1 + (const_k1r * const_kr * rh[i]) + (const_k1r * const_k2r * const_kr * const_kr * rh[i] * rh[i])))) / 100.0)
                        emc[i] += (frac[j] * ric * 1.1)
                        rice_emc[i] = Float64(ric * 1.1)
                        moist[i] += Float64(frac[j] * harv_moist[j][i])
                    elif (j == 4 or j == 5 or j == 6 or j == 7 or j == 8 or j == 9) and (frac[j] != 0):
                        var const_w: Float64 = 330 + (0.452 * temp_f[i]) + (0.00415 * temp_f[i] * temp_f[i])
                        var const_k: Float64 = 0.791 + (0.000463 * temp_f[i]) - (0.000000844 * temp_f[i] * temp_f[i])
                        var const_k1: Float64 = 6.34 + (0.000775 * temp_f[i]) - (0.0000935 * temp_f[i] * temp_f[i])
                        var const_k2: Float64 = 1.09 + (0.0284 * temp_f[i]) - (0.0000904 * temp_f[i] * temp_f[i])
                        var these: Float64 = Float64((1800 / const_w) * (((const_k * rh[i]) / (1 - (const_k * rh[i]))) + (((const_k1 * const_k * rh[i]) + (2 * const_k1 * const_k2 * const_k * const_k * rh[i] * rh[i])) / (1 + (const_k1 * const_k * rh[i]) + (const_k1 * const_k2 * const_k * const_k * rh[i] * rh[i])))) / 100.0)
                        emc[i] += (frac[j] * these)
                        if j == 4: wheat_emc[i] = these
                        if j == 5: forest_emc[i] = these
                        if j == 6: mill_emc[i] = these
                        if j == 7: urban_emc[i] = these
                        if j == 8: woody_emc[i] = these
                        if j == 9: herb_emc[i] = these
                        moist[i] += Float64((frac[j] * harv_moist[j][i]))
                    elif (j == 10 or j == 11 or j == 12 or j == 13 or j == 14) and (frac[j] != 0):
                        moist[i] += Float64((frac[j] * harv_moist[j][i]))
            elif dry_opt == 2:
                for j in range(15):
                    moist_b[i] += ((frac[j] * harv_moist[j][i]))
                moist[i] = Float64(dry_spec)
                if moist_b[i] < moist[i]:
                    moist[i] = Float64(moist_b[i])
                _moist_b += moist_b[i] / 12.0
                _moist = dry_spec
            if emc[i] != 0 and emc[i] < moist[i]:
                moist[i] = Float64(emc[i])
            w_per_hv[i] = (moist[i] / hhv * 10000.0) + (hydrogen / 2.0 * 8.94 / hhv * 10000.0)
            fuel_eff_loss[i] = w_per_hv[i] * (fw_enth_out - temp_f[i] + 32) / 100.0 / 100.0
        var boiler_output: Float64 = boiler_capacity * steam_enth / 1000000.0
        var boiler_percent: Float64 = boiler_output / (total_heat_in / boiler_num) * 100.0
        var count1: Int32 = 0
        var count2: Int32 = 0
        for j in range(18):
            if rad_col[j] <= boiler_output:
                count1 += 1
            else:
                break
        for i in range(6):
            if rad_row[i] >= boiler_percent:
                count2 += 1
            else:
                break
        var result: Float64 = 0.0
        if count1 != 0 and boiler_percent != 100:
            var spread1: Float64 = fabs(rad_col[count1 - 1] - rad_col[count1])
            var spread2: Float64 = fabs(rad_row[count2 - 1] - rad_row[count2])
            var frac1: Float64 = fmod(boiler_output, spread1) / spread1
            var frac2: Float64 = fmod(boiler_percent, spread2) / spread2
            var val1: Float64 = rad_table[count1 - 1][count2 - 1]
            var val2: Float64 = rad_table[count1 - 1][count2]
            var val3: Float64 = rad_table[count1][count2 - 1]
            var val4: Float64 = rad_table[count1][count2]
            var endpoint1: Float64 = (frac1 * (val3 - val1)) + val1
            var endpoint2: Float64 = (frac1 * (val4 - val2)) + val2
            result = (frac2 * (endpoint2 - endpoint1)) + endpoint1
        elif count1 == 0 and boiler_percent != 100:
            var spread2: Float64 = fabs(rad_row[count2 - 1] - rad_row[count2])
            var frac2: Float64 = fmod(boiler_percent, spread2) / spread2
            var val3: Float64 = rad_table[count1][count2 - 1]
            var val4: Float64 = rad_table[count1][count2]
            result = (frac2 * (val4 - val3)) + val3
        elif count1 != 0 and boiler_percent == 100:
            var spread1: Float64 = fabs(rad_col[count1 - 1] - rad_col[count1])
            var frac1: Float64 = fmod(boiler_output, spread1) / spread1
            var val2: Float64 = rad_table[count1 - 1][count2 - 1]
            var val4: Float64 = rad_table[count1][count2 - 1]
            result = (frac1 * (val4 - val2)) + val4
        elif count1 == 0 and boiler_percent == 100:
            result = rad_table[count1][count2]
        var rad_eff_loss: Float64 = fabs(result / 100.0)
        var _enet: Pointer[Float64] = self.self.allocate("gen", 8760)
        var _qtpb: Pointer[Float64] = self.self.allocate("hourly_q_to_pb", 8760)
        var _tnorm: List[Float64] = List[Float64](8760, 0.0)
        var _gross: List[Float64] = List[Float64](8760, 0.0)
        var _pbeta: Pointer[Float64] = self.self.allocate("hourly_pbeta", 8760)
        var annual_heatrate_hhv: Float64 = 0.0
        var annual_heatrate_lhv: Float64 = 0.0
        var annual_biomass: Float64 = 0.0
        var annual_coal: Float64 = 0.0
        var annual_capfactor: Float64 = 0.0
        var total_boiler_eff: Float64 = 0.0
        var total_etaa: Float64 = 0.0
        total_dry_eff_loss = 0.0
        total_wair_eff_loss = 0.0
        total_fuel_eff_loss = 0.0
        total_boiler_eff = 0.0
        for i in range(12):
            pass # empty loop
        var Qtotal: Float64 = total * 2000.0 * hhv
        var par_loss: Float64 = 0.0
        var Qtoboil_tot: Float64 = 0.0
        var Qtopb_tot: Float64 = 0.0
        var press_adj: Float64 = (steam_pressure - 900.0) / 14.2857143 * 0.1 / 100.0
        rated_eff += press_adj
        var haf: adjustment_factors = adjustment_factors(self.self, "adjust")
        if not haf.setup():
            throw exec_error("biopower", "failed to setup adjustment factors: " + haf.error())
        for i in range(8760):
            var iMonth: Int32 = util.month_of(i) - 1
            _boiler_eff[i] = Float64((1 - fuel_eff_loss[iMonth] - _dry_eff_loss[i] - _wet_air_eff_loss[i] - unburn_eff_loss - manu_eff_loss - rad_eff_loss) * 100.0)
            total_dry_eff_loss += _dry_eff_loss[i] / 8760.0
            total_wair_eff_loss += _wet_air_eff_loss[i] / 8760.0
            total_fuel_eff_loss += fuel_eff_loss[iMonth] / 8760.0
            total_boiler_eff += _boiler_eff[i] / 8760.0
            boiler_eff[iMonth] += Float64(_boiler_eff[i] / (nday[iMonth] * 24.0))
            var Qmonth: Float64 = total * nday[iMonth] / 365.0 * 2000.0 * hhv
            var Qtoboil: Float64 = Qmonth / (nday[iMonth] * 24.0)
            Qtoboil_tot += (Qtoboil * (1 / 3412.14163))
            if tou_opt == 1:
                if ramp_rate == 0:
                    Qtoboil *= tous[i]
                    Qtotal -= Qtoboil
                elif ramp_rate != 0 and i > 0 and i < 8760 and tous[i] >= tous[i - 1]:
                    tous[i] = (tous[i - 1] + ramp_rate < tous[i]) ? tous[i - 1] + ramp_rate : tous[i]
                    Qtoboil *= tous[i]
                    Qtotal -= Qtoboil
                elif ramp_rate != 0 and i > 0 and i < 8760 and tous[i] <= tous[i - 1]:
                    tous[i] = (tous[i - 1] - ramp_rate > tous[i]) ? tous[i - 1] - ramp_rate : tous[i]
                    Qtoboil *= tous[i]
                    Qtotal -= Qtoboil
                else:
                    Qtoboil *= tous[i]
                    Qtotal -= Qtoboil
                if Qtotal <= 0:
                    throw exec_error("biopower", "the fractional operation specifications were too high! Biomass was over-utilized")
                    return
            else:
                Qtotal -= Qtoboil
            var Qtopb: Float64 = (_boiler_eff[i] / 100.0) * Qtoboil * (1 / 3412.14163)
            Qtopb_tot += Qtopb
            var Qdesign: Float64 = Wdesign / rated_eff
            var Qnorm: Float64 = Qtopb / Qdesign
            var Tnorm: Float64 = (temp_mode == 1) ? _twet[i] - design_temp : _tdry[i] - design_temp
            var eta_q: Float64 = etaQ[0] + etaQ[1] * Qnorm + etaQ[2] * Qnorm * Qnorm + etaQ[3] * Qnorm * Qnorm * Qnorm + etaQ[4] * Qnorm * Qnorm * Qnorm * Qnorm
            var eta_t: Float64 = etaT[0] + etaT[1] * Tnorm + etaT[2] * Tnorm * Tnorm + etaT[3] * Tnorm * Tnorm * Tnorm + etaT[4] * Tnorm * Tnorm * Tnorm * Tnorm
            var eta_adj: Float64 = eta_q * eta_t * rated_eff
            var Wgr: Float64 = Qtopb * eta_adj
            if Wgr < min_load * Wdesign:
                Wgr = 0.0
            if Wgr > max_over * Wdesign:
                Wgr = Wdesign
            var Wnet: Float64 = Wgr - (par * Wgr)
            par_loss += (Wgr - Wnet)
            var heatrat_hhv: Float64 = Qtoboil / Wnet / 1000.0
            var heatrat_lhv: Float64 = (Qtoboil / hhv * lhv) / Wnet / 1000.0
            var capfact: Float64 = Wnet / Wdesign
            _gross[i] = Wgr
            _pbeta[i] = Float64(eta_adj * 100.0)
            _etaa[iMonth] += Float64(eta_adj * 100.0 / (nday[iMonth] * 24.0))
            total_etaa += eta_adj / 8760.0
            _qtpb[i] = Float64(Qtopb)
            _enet[i] = Float64(Wnet * haf[i])
            _tnorm[i] = Tnorm
            capfactor[iMonth] += capfact / (nday[iMonth] * 24.0)
            heatrate_hhv[iMonth] += Float64(heatrat_hhv / (nday[iMonth] * 24.0))
            heatrate_lhv[iMonth] += Float64(heatrat_lhv / (nday[iMonth] * 24.0))
            annual_output += Wnet
            annual_heatrate_hhv += heatrat_hhv / 8760.0
            annual_heatrate_lhv += heatrat_lhv / 8760.0
            annual_capfactor += capfact * 100.0 / 8760.0
        var leftover: Float64 = 0.0
        if Qtotal != 0:
            leftover = Qtotal / (total * 2000.0 * hhv)
        annual_biomass = total_biomass * (1 - leftover)
        annual_coal = total_coal * (1 - leftover)
        var total_feedstock: Float64 = annual_biomass + annual_coal
        var thermeff_hhv: Float64 = 3.41213163 / annual_heatrate_hhv * 100.0
        var thermeff_lhv: Float64 = 3.41213163 / annual_heatrate_lhv * 100.0
        var _ash: List[Float64] = List[Float64](19, 0.0)
        _ash[0] = 0.038
        _ash[1] = 0.049
        _ash[2] = 0.051
        _ash[3] = 0.134
        _ash[4] = 0.050
        _ash[5] = 0.0087
        _ash[6] = 0.0148
        _ash[7] = 0.0125
        _ash[8] = 0.0125
        _ash[9] = 0.038
        _ash[10] = 0.05
        _ash[11] = 0.05
        _ash[12] = 0.062
        _ash[13] = 0.091
        _ash[14] = 0.177
        var ash: Float64 = 0.0
        for i in range(15):
            ash += frac[i] * _ash[i]
        var tpy_ash: Float64 = total_feedstock * ash
        var npci: Float64 = 1628.491234
        var ppci: Float64 = 488.0545632
        var kpci: Float64 = 314.800651
        var lpci: Float64 = 288.0804725
        var cfci: Float64 = (coll_fuel == 1) ? 0.025216 : 0.094744
        var avem: Float64 = (av_cred == 0) ? 0.0 : 1.0
        var bgarhc: List[List[Float64]] = List[List[Float64]](10, List[Float64](11, 0.0))
        var n_app: List[Float64] = List[Float64](0.0, 13.6, 18.0, 18.0, 13.6, 0.0, 0.0, 0.0, 11.57, 21.91)
        var p_app: List[Float64] = List[Float64](0.0, 1.38, 1.98, 1.98, 1.38, 0.0, 0.0, 0.0, 0.69, 2.11)
        var k_app: List[Float64] = List[Float64](0.0, 25.2, 30.0, 30.0, 25.2, 0.0, 0.0, 0.0, 3.44, 25.80)
        var l_app: List[Float64] = List[Float64](0.0, 0.0, 0.0, 0.0, 0.0, 74.08, 0.0, 0.0, 18.58, 31.72)
        var coll_yield: List[Float64] = List[Float64](0.0, 68466.9 / (865.41 / 2000.0), 68466.9 / (2935.3 / 2000.0), 68466.9 / (2935.3 / 2000.0), 68466.9 / (865.41 / 2000.0), 99727.7 / (15167.0 / 2000.0), 0.0, 0.0, 805492.8 / (12490.5 / 2000.0), 690422.4 / (10547.7 / 2000.0))
        for i in range(10):
            bgarhc[i][0] = dry[i] / 0.95 * n_app[i]
            bgarhc[i][1] = dry[i] / 0.95 * p_app[i]
            bgarhc[i][2] = dry[i] / 0.95 * k_app[i]
            bgarhc[i][3] = dry[i] / 0.95 * l_app[i]
            bgarhc[i][4] = dry[i] / 0.95 * coll_yield[i]
            bgarhc[i][5] = bgarhc[i][0] * npci
            bgarhc[i][6] = bgarhc[i][1] * ppci
            bgarhc[i][7] = bgarhc[i][2] * kpci
            bgarhc[i][8] = bgarhc[i][3] * lpci
            bgarhc[i][9] = bgarhc[i][4] * cfci
            if i == 6 or i == 7:
                bgarhc[i][9] = 6.58 * 2000.0
                bgarhc[i][10] = -(((9.6343873 / 100.0) * (waste_c[i - 6]) * ((16.0 / 12.0 * 25.0) - (44.0 / 12.0))) * 1000.0 * 0.45359) * 2000.0 * wet[i] * avem
        var final: List[Float64] = List[Float64](0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        for j in range(10):
            for i in range(5, 10):
                final[0] += bgarhc[j][i] / annual_output
        final[10] = (bgarhc[6][10] + bgarhc[7][10]) / annual_output
        final[9] = (bgarhc[6][9] + bgarhc[7][9]) / annual_output
        var swit: Float64 = 0.0
        var swit2: Float64 = 0.0
        var swit3: Float64 = 0.0
        for j in range(4):
            if j == 0:
                swit = 839.15; swit2 = 0.446; swit3 = 19644.34
            elif j == 1:
                swit = 2197.47; swit2 = 0.531; swit3 = 3653.64
            elif j == 2:
                swit = 1813.564; swit2 = 0.758; swit3 = 1900.96
            elif j == 3:
                swit = 1411.813; swit2 = 0.819; swit3 = 2023.57
            for i in range(10):
                final[1] += bgarhc[i][j] * swit / annual_output
                final[4] += bgarhc[i][j] * swit2 / annual_output
                final[5] += bgarhc[i][j] * swit3 / annual_output
        var hold: Int32 = coll_fuel + 2
        for j in range(10):
            final[hold] += bgarhc[j][4] / annual_output
            final[6] += bgarhc[j][0] / annual_output
            final[7] += bgarhc[j][1] / annual_output
            final[8] += bgarhc[j][2] / annual_output
            final[11] += bgarhc[j][8] / annual_output
        var dcfci: Float64 = (transport_fuel == 1) ? 0.02522 * 947.8171203 * (34.0 / 0.264172052) : 0.09474 * 947.8171203 * (34.0 / 0.264172052)
        var trans_diesel: Float64 = 0.0
        if transport_legs == 0:
            transport_predist = 0.0
        var leg1: Float64 = wet_total / 25.0 * transport_predist * 0.8 / 4.75 * dcfci / annual_output
        trans_diesel += leg1 / dcfci * annual_output
        var leg2: Float64 = wet_total / 25.0 * (transport_longmiles - transport_predist) * 0.8 / 4.75 * dcfci / annual_output
        trans_diesel += leg2 / dcfci * annual_output
        var leg3: Float64 = (transport_longopt == 0) ? wet_total * (collection_radius - transport_longmiles) * 0.8 / 330.0 * dcfci / annual_output : 0.0
        trans_diesel += leg3 / dcfci * annual_output
        var leg4: Float64 = (transport_longopt == 1) ? wet_total * (collection_radius - transport_longmiles) * 0.8 / 550.0 * 12686.73697 / annual_output : 0.0
        var trans_bunker: Float64 = leg4 / 12686.73697 * annual_output
        var testing_leg: Float64 = leg1 + leg2 + leg3 + leg4
        var testing_dies: Float64 = trans_diesel / 0.264172052 * 34.0 * 947.8171203 / annual_output
        var testing_bunker: Float64 = trans_bunker / 0.264172052 * 34.0 * 947.8171203 / annual_output
        var preprocessing_diesel: Float64 = pre_chipopt * (0.02387 + 0.01982) * dry_total * 1000000.0 / annual_output
        var preprocessing_kwh: Float64 = ((pre_grindopt * (dry_total * 0.2137 * 1000000.0 / 3412.14)) + (pre_pelletopt * (dry_total * 0.2835 * 1000000.0 / 3412.14)))
        var preprocessing_ems: Float64 = (preprocessing_kwh * grid_intensity / annual_output) + (preprocessing_diesel * 0.09474)
        var drying_kwh: Float64 = 0.0
        var drying_ems: Float64 = 0.0
        var drying_natgas: Float64 = 0.0
        if dry_opt == 0:
            drying_kwh = 0.299 * dry_total / annual_output; drying_ems = drying_kwh * grid_intensity
        if dry_opt == 1 or dry_opt == 2:
            drying_kwh = 0.97 * dry_total / annual_output; drying_ems = drying_kwh * grid_intensity
        if dry_opt == 2:
            drying_ems += (dry_total * (_moist_b - _moist) * 2000.0 * 1931.0 * 0.065 / annual_output)
            drying_natgas += dry_total * (_moist_b - _moist) * 2000.0 * 1931.0 / annual_output
        var comb_ems: Float64 = frac_c * total * (44.0 / 12.0) * 907184.74 / annual_output
        var comb_ems_neg: Float64 = -(biomass_frac_c * dry_total * (44.0 / 12.0) * 907184.74 / annual_output)
        var final_emissions: List[Float64] = List[Float64](7, 0.0)
        final_emissions[0] = final[0]
        final_emissions[1] = testing_leg
        final_emissions[2] = preprocessing_ems
        final_emissions[3] = drying_ems
        final_emissions[4] = comb_ems
        final_emissions[5] = comb_ems_neg
        final_emissions[6] = final[10]
        for i in range(6):
            final_emissions[6] += final_emissions[i]
        var ems_per_lb: Float64 = final_emissions[6] * annual_output / dry_total / 2000.0
        var diesel_use: Float64 = 0.0
        var biodiesel_use: Float64 = 0.0
        if transport_fuel == 0:
            diesel_use = testing_dies + final[2] + preprocessing_diesel
        if transport_fuel == 1:
            biodiesel_use = testing_dies + final[3]
        var naturalgas: Float64 = final[5] + drying_natgas
        var water: Float64 = (300.0 * annual_output / 1000.0 / 8760.0)
        water *= 0.0037854118 * 8760.0
        var fuel_usage: Float64 = total * 2000 * hhv / 3412.14163
        self.self.assign("system.annual.boiler_loss_fuel_kwh", var_data(Float64(total_fuel_eff_loss * fuel_usage)))
        self.self.assign("system.annual.boiler_loss_unburn_kwh", var_data(Float64(unburn_eff_loss * fuel_usage)))
        self.self.assign("system.annual.boiler_loss_manu_kwh", var_data(Float64(manu_eff_loss * fuel_usage)))
        self.self.assign("system.annual.boiler_loss_rad_kwh", var_data(Float64(rad_eff_loss * fuel_usage)))
        self.self.assign("system.annual.boiler_loss_dry_kwh", var_data(Float64(total_dry_eff_loss * fuel_usage)))
        self.self.assign("system.annual.boiler_loss_wet_kwh", var_data(Float64(total_wair_eff_loss * fuel_usage)))
        var boiler_output_total: Float64 = (1.0 - (total_fuel_eff_loss + unburn_eff_loss + manu_eff_loss + rad_eff_loss + total_dry_eff_loss + total_wair_eff_loss)) * fuel_usage
        self.self.assign("system.annual.boiler_loss_total_kwh", var_data(Float64((1.0 - rated_eff) * boiler_output_total)))
        self.self.assign("system.annual.pb_eta_kwh", var_data(Float64((rated_eff - total_etaa) * boiler_output_total)))
        var turbine_output: Float64 = boiler_output_total * (1.0 - ((1.0 - rated_eff) + (rated_eff - total_etaa)))
        self.self.assign("system.annual.par_loss_kwh", var_data(Float64(par * turbine_output)))
        self.self.assign("system.annual.boiler_output", var_data(Float64(boiler_output_total)))
        self.self.assign("system.annual.turbine_output", var_data(Float64(turbine_output)))
        self.self.assign("system.annual.boiler_loss_fuel", var_data(Float64(total_fuel_eff_loss)))
        self.self.assign("system.annual.boiler_loss_unburn", var_data(Float64(unburn_eff_loss)))
        self.self.assign("system.annual.boiler_loss_manu", var_data(Float64(manu_eff_loss)))
        self.self.assign("system.annual.boiler_loss_rad", var_data(Float64(rad_eff_loss)))
        self.self.assign("system.annual.boiler_loss_dry", var_data(Float64(total_dry_eff_loss)))
        self.self.assign("system.annual.boiler_loss_wet", var_data(Float64(total_wair_eff_loss)))
        self.self.assign("system.annual.boiler_loss_total", var_data(Float64(total_boiler_eff)))
        self.self.assign("system.annual.pb_eta", var_data(Float64(total_etaa)))
        self.self.assign("system.annual.par_loss", var_data(Float64(par)))
        self.self.assign("system.annual.qtoboil_tot", var_data(Float64(Qtoboil_tot)))
        self.self.assign("system.annual.qtopb_tot", var_data(Float64(Qtopb_tot)))
        self.self.accumulate_monthly("gen", "monthly_energy")
        self.self.accumulate_monthly("hourly_q_to_pb", "monthly_q_to_pb")
        self.self.accumulate_annual("gen", "annual_energy")
        self.self.assign("system.annual.ash", var_data(Float64(tpy_ash)))
        self.self.assign("system.annual.e_net", var_data(Float64(annual_output)))
        self.self.assign("system.annual.biomass", var_data(Float64(annual_biomass)))
        self.self.assign("annual_fuel_usage", var_data(Float64(fuel_usage)))
        self.self.assign("annual_watter_usage", var_data(Float64(water)))
        self.self.assign("system.annual.coal", var_data(Float64(annual_coal)))
        self.self.assign("system.emissions.growth", var_data(Float64(final_emissions[0])))
        self.self.assign("system.emissions.avoided", var_data(Float64(final[10])))
        self.self.assign("system.emissions.transport", var_data(Float64(final_emissions[1])))
        self.self.assign("system.emissions.preprocessing", var_data(Float64(final_emissions[2])))
        self.self.assign("system.emissions.drying", var_data(Float64(final_emissions[3])))
        self.self.assign("system.emissions.combustion", var_data(Float64(final_emissions[4])))
        self.self.assign("system.emissions.uptake", var_data(Float64(final_emissions[5])))
        self.self.assign("system.emissions.total_sum", var_data(Float64(final_emissions[6])))
        self.self.assign("system.emissions.diesel", var_data(Float64(diesel_use)))
        self.self.assign("system.emissions.biodiesel", var_data(Float64(biodiesel_use)))
        self.self.assign("system.emissions.bunker", var_data(Float64(testing_bunker)))
        self.self.assign("system.emissions.oil", var_data(Float64(final[1])))
        self.self.assign("system.emissions.naturalgas", var_data(Float64(naturalgas)))
        self.self.assign("system.emissions.nitrogen", var_data(Float64(final[6])))
        self.self.assign("system.emissions.potassium", var_data(Float64(final[8])))
        self.self.assign("system.emissions.phosphorus", var_data(Float64(final[7])))
        self.self.assign("system.emissions.lime", var_data(Float64(final[11])))
        self.self.assign("system.emissions.ems_per_lb", var_data(Float64(ems_per_lb)))
        self.self.assign("system.capfactor", var_data(Float64(annual_capfactor)))
        self.self.assign("system.use_lifetime_output", var_data(Float64(0)))
        self.self.assign("system.use_recapitalization", var_data(Float64(0)))
        self.self.assign("system.hhv_heatrate", var_data(Float64(annual_heatrate_hhv)))
        self.self.assign("system.total_moisture", var_data(Float64(self.self.as_double("biopwr.feedstock.total_moisture"))))
        self.self.assign("system_heat_rate", var_data(Float64(3.4123)))
        self.self.assign("system.lhv_heatrate", var_data(Float64(annual_heatrate_lhv)))
        self.self.assign("system.hhv_thermeff", var_data(Float64(thermeff_hhv)))
        self.self.assign("system.lhv_thermeff", var_data(Float64(thermeff_lhv)))
        var da: Pointer[Float64] = self.self.allocate("om_fuel_cost", 1)
        da[0] = 0.0
        var kWhperkW: Float64 = 0.0
        var nameplate: Float64 = self.self.as_double("system_capacity")
        var annual_energy: Float64 = 0.0
        for i in range(8760):
            annual_energy += _enet[i]
        if nameplate > 0:
            kWhperkW = annual_energy / nameplate
        self.self.assign("capacity_factor", var_data(Float64(kWhperkW / 87.6)))
        self.self.assign("kwh_per_kw", var_data(Float64(kWhperkW)))

# Module entry equivalent to DEFINE_MODULE_ENTRY
# In Mojo, we just export the struct as the compute module
# (The framework will call exec)
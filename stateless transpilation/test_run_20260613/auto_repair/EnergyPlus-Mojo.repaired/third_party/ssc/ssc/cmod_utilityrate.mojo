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
from math import pow
from util import *

alias ssc_number_t = Float64

var vtab_utility_rate = List[var_info](
  var_info(SSC_INPUT, SSC_NUMBER, "analysis_period", "Number of years in analysis", "years", "", "", "*", "INTEGER,POSITIVE", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "e_with_system", "Energy at grid with system", "kWh", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "p_with_system", "Max power at grid with system", "kW", "", "", "?", "LENGTH=8760", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "e_without_system", "Energy at grid without system (load only)", "kWh", "", "", "?", "LENGTH=8760", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "p_without_system", "Max power at grid without system (load only)", "kW", "", "", "?", "LENGTH=8760", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "system_availability", "Annual availability of system", "%/year", "", "", "?=100", "", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "system_degradation", "Annual degradation of system", "%/year", "", "", "?=0", "", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "load_escalation", "Annual load escalation", "%/year", "", "", "?=0", "", ""),
  var_info(SSC_INPUT, SSC_ARRAY, "rate_escalation", "Annual utility rate escalation", "%/year", "", "", "?=0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_sell_eq_buy", "Force sell rate equal to buy", "0/1", "Enforce net metering", "", "?=1", "BOOLEAN", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_monthly_fixed_charge", "Monthly fixed charge", "$", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_flat_buy_rate", "Flat rate (buy)", "$/kWh", "", "", "*", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_flat_sell_rate", "Flat rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_enable", "Enable time-of-use rates", "0/1", "", "", "?=0", "BOOLEAN", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p1_buy_rate", "TOU period 1 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p1_sell_rate", "TOU period 1 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p2_buy_rate", "TOU period 2 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p2_sell_rate", "TOU period 2 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p3_buy_rate", "TOU period 3 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p3_sell_rate", "TOU period 3 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p4_buy_rate", "TOU period 4 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p4_sell_rate", "TOU period 4 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p5_buy_rate", "TOU period 5 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p5_sell_rate", "TOU period 5 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p6_buy_rate", "TOU period 6 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p6_sell_rate", "TOU period 6 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p7_buy_rate", "TOU period 7 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p7_sell_rate", "TOU period 7 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p8_buy_rate", "TOU period 8 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p8_sell_rate", "TOU period 8 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p9_buy_rate", "TOU period 9 rate (buy)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tou_p9_sell_rate", "TOU period 9 rate (sell)", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_STRING, "ur_tou_sched_weekday", "TOU weekday schedule", "", "288 digits 0-9, 24x12", "", "ur_tou_enable=1", "TOUSCHED", ""),
  var_info(SSC_INPUT, SSC_STRING, "ur_tou_sched_weekend", "TOU weekend schedule", "", "288 digits 0-9, 24x12", "", "ur_tou_enable=1", "TOUSCHED", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_enable", "Enable demand charges", "0/1", "", "", "?=0", "BOOLEAN", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m1", "DC fixed rate January", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m2", "DC fixed rate February", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m3", "DC fixed rate March", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m4", "DC fixed rate April", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m5", "DC fixed rate May", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m6", "DC fixed rate June", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m7", "DC fixed rate July", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m8", "DC fixed rate August", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m9", "DC fixed rate September", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m10", "DC fixed rate October", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m11", "DC fixed rate November", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_fixed_m12", "DC fixed rate December", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p1", "DC TOU rate period 1", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p2", "DC TOU rate period 2", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p3", "DC TOU rate period 3", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p4", "DC TOU rate period 4", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p5", "DC TOU rate period 5", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p6", "DC TOU rate period 6", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p7", "DC TOU rate period 7", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p8", "DC TOU rate period 8", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_dc_p9", "DC TOU rate period 9", "$/kW,pk", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_STRING, "ur_dc_sched_weekday", "DC TOU weekday schedule", "", "288 digits 0-9, 24x12", "", "ur_dc_enable=1", "TOUSCHED", ""),
  var_info(SSC_INPUT, SSC_STRING, "ur_dc_sched_weekend", "DC TOU weekend schedule", "", "288 digits 0-9, 24x12", "", "ur_dc_enable=1", "TOUSCHED", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_enable", "Enable tiered rates", "0/1", "", "", "?=0", "BOOLEAN", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sell_mode", "Tiered rate sell mode", "0,1,2", "0=specified,1=tier1,2=lowest", "", "?=1", "INTEGER,MIN=0,MAX=2", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sell_rate", "Specified tiered sell rate", "$/kW", "", "", "ur_tr_sell_mode=0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_energy_ub1", "Tiered struct. 1 Energy UB 1", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_energy_ub2", "Tiered struct. 1 Energy UB 2", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_energy_ub3", "Tiered struct. 1 Energy UB 3", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_energy_ub4", "Tiered struct. 1 Energy UB 4", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_energy_ub5", "Tiered struct. 1 Energy UB 5", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_energy_ub6", "Tiered struct. 1 Energy UB 6", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_rate1", "Tiered struct. 1 Rate 1", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_rate2", "Tiered struct. 1 Rate 2", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_rate3", "Tiered struct. 1 Rate 3", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_rate4", "Tiered struct. 1 Rate 4", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_rate5", "Tiered struct. 1 Rate 5", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s1_rate6", "Tiered struct. 1 Rate 6", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_energy_ub1", "Tiered struct. 2 Energy UB 1", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_energy_ub2", "Tiered struct. 2 Energy UB 2", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_energy_ub3", "Tiered struct. 2 Energy UB 3", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_energy_ub4", "Tiered struct. 2 Energy UB 4", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_energy_ub5", "Tiered struct. 2 Energy UB 5", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_energy_ub6", "Tiered struct. 2 Energy UB 6", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_rate1", "Tiered struct. 2 Rate 1", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_rate2", "Tiered struct. 2 Rate 2", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_rate3", "Tiered struct. 2 Rate 3", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_rate4", "Tiered struct. 2 Rate 4", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_rate5", "Tiered struct. 2 Rate 5", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s2_rate6", "Tiered struct. 2 Rate 6", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_energy_ub1", "Tiered struct. 3 Energy UB 1", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_energy_ub2", "Tiered struct. 3 Energy UB 2", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_energy_ub3", "Tiered struct. 3 Energy UB 3", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_energy_ub4", "Tiered struct. 3 Energy UB 4", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_energy_ub5", "Tiered struct. 3 Energy UB 5", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_energy_ub6", "Tiered struct. 3 Energy UB 6", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_rate1", "Tiered struct. 3 Rate 1", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_rate2", "Tiered struct. 3 Rate 2", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_rate3", "Tiered struct. 3 Rate 3", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_rate4", "Tiered struct. 3 Rate 4", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_rate5", "Tiered struct. 3 Rate 5", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s3_rate6", "Tiered struct. 3 Rate 6", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_energy_ub1", "Tiered struct. 4 Energy UB 1", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_energy_ub2", "Tiered struct. 4 Energy UB 2", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_energy_ub3", "Tiered struct. 4 Energy UB 3", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_energy_ub4", "Tiered struct. 4 Energy UB 4", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_energy_ub5", "Tiered struct. 4 Energy UB 5", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_energy_ub6", "Tiered struct. 4 Energy UB 6", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_rate1", "Tiered struct. 4 Rate 1", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_rate2", "Tiered struct. 4 Rate 2", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_rate3", "Tiered struct. 4 Rate 3", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_rate4", "Tiered struct. 4 Rate 4", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_rate5", "Tiered struct. 4 Rate 5", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s4_rate6", "Tiered struct. 4 Rate 6", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_energy_ub1", "Tiered struct. 5 Energy UB 1", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_energy_ub2", "Tiered struct. 5 Energy UB 2", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_energy_ub3", "Tiered struct. 5 Energy UB 3", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_energy_ub4", "Tiered struct. 5 Energy UB 4", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_energy_ub5", "Tiered struct. 5 Energy UB 5", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_energy_ub6", "Tiered struct. 5 Energy UB 6", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_rate1", "Tiered struct. 5 Rate 1", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_rate2", "Tiered struct. 5 Rate 2", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_rate3", "Tiered struct. 5 Rate 3", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_rate4", "Tiered struct. 5 Rate 4", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_rate5", "Tiered struct. 5 Rate 5", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s5_rate6", "Tiered struct. 5 Rate 6", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_energy_ub1", "Tiered struct. 6 Energy UB 1", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_energy_ub2", "Tiered struct. 6 Energy UB 2", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_energy_ub3", "Tiered struct. 6 Energy UB 3", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_energy_ub4", "Tiered struct. 6 Energy UB 4", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_energy_ub5", "Tiered struct. 6 Energy UB 5", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_energy_ub6", "Tiered struct. 6 Energy UB 6", "kWh", "", "", "?=1e99", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_rate1", "Tiered struct. 6 Rate 1", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_rate2", "Tiered struct. 6 Rate 2", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_rate3", "Tiered struct. 6 Rate 3", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_rate4", "Tiered struct. 6 Rate 4", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_rate5", "Tiered struct. 6 Rate 5", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_s6_rate6", "Tiered struct. 6 Rate 6", "$/kWh", "", "", "?=0.0", "", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m1", "Tiered structure for January", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m2", "Tiered structure for February", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m3", "Tiered structure for March", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m4", "Tiered structure for April", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m5", "Tiered structure for May", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m6", "Tiered structure for June", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m7", "Tiered structure for July", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m8", "Tiered structure for August", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m9", "Tiered structure for September", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m10", "Tiered structure for October", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m11", "Tiered structure for November", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_INPUT, SSC_NUMBER, "ur_tr_sched_m12", "Tiered structure for December", "0-5", "tiered structure #", "", "?=0", "INTEGER,MIN=0,MAX=5", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "energy_value", "Energy value by each year", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "energy_net", "Energy by each year", "kW", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "revenue_with_system", "Total revenue with system", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "revenue_without_system", "Total revenue without system", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "elec_cost_with_system", "Electricity cost with system", "$/yr", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "elec_cost_without_system", "Electricity cost without system", "$/yr", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_e_grid", "Electricity at grid", "kWh", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_system_output", "Electricity from system", "kWh", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_e_demand", "Electricity from grid", "kWh", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_system_to_grid", "Electricity to grid", "kWh", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_system_to_load", "Electricity to load", "kWh", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_p_grid", "Peak at grid ", "kW", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_p_demand", "Peak from grid", "kW", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_p_system_to_load", "Peak to load ", "kW", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_revenue_with_system", "Revenue with system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_payment_with_system", "Payment with system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_income_with_system", "Income with system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_price_with_system", "Price with system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_revenue_without_system", "Revenue without system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_payment_without_system", "Payment without system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_income_without_system", "Income without system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_hourly_price_without_system", "Price without system", "$", "", "", "*", "LENGTH=8760", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_fixed_with_system", "Demand charge (fixed) with system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_tou_with_system", "Demand charge (TOU) with system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_tr_charge_with_system", "Tiered charge with system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_tr_rate_with_system", "Tiered rate with system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_fixed_without_system", "Demand charge (fixed) without system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_dc_tou_without_system", "Demand charge (TOU) without system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_tr_charge_without_system", "Tiered charge without system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "year1_monthly_tr_rate_without_system", "Tiered rate without system", "$", "", "", "*", "LENGTH=12", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_jan", "Demand charge (fixed) in Jan", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_feb", "Demand charge (fixed) in Feb", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_mar", "Demand charge (fixed) in Mar", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_apr", "Demand charge (fixed) in Apr", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_may", "Demand charge (fixed) in May", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_jun", "Demand charge (fixed) in Jun", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_jul", "Demand charge (fixed) in Jul", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_aug", "Demand charge (fixed) in Aug", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_sep", "Demand charge (fixed) in Sep", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_oct", "Demand charge (fixed) in Oct", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_nov", "Demand charge (fixed) in Nov", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_fixed_dec", "Demand charge (fixed) in Dec", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_jan", "Demand charge (TOU) in Jan", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_feb", "Demand charge (TOU) in Feb", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_mar", "Demand charge (TOU) in Mar", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_apr", "Demand charge (TOU) in Apr", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_may", "Demand charge (TOU) in May", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_jun", "Demand charge (TOU) in Jun", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_jul", "Demand charge (TOU) in Jul", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_aug", "Demand charge (TOU) in Aug", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_sep", "Demand charge (TOU) in Sep", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_oct", "Demand charge (TOU) in Oct", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_nov", "Demand charge (TOU) in Nov", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_dc_tou_dec", "Demand charge (TOU) in Dec", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_jan", "Tiered rate charge in Jan", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_feb", "Tiered rate charge in Feb", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_mar", "Tiered rate charge in Mar", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_apr", "Tiered rate charge in Apr", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_may", "Tiered rate charge in May", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_jun", "Tiered rate charge in Jun", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_jul", "Tiered rate charge in Jul", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_aug", "Tiered rate charge in Aug", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_sep", "Tiered rate charge in Sep", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_oct", "Tiered rate charge in Oct", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_nov", "Tiered rate charge in Nov", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info(SSC_OUTPUT, SSC_ARRAY, "charge_tr_dec", "Tiered rate charge in Dec", "$", "", "", "*", "LENGTH_EQUAL=analysis_period", ""),
  var_info_invalid
)

class cm_utilityrate(ComputeModule):
    def __init__(self):
        self.add_var_info(vtab_utility_rate)

    def exec(self):
        var parr: List[ssc_number_t] = List[ssc_number_t]()
        var count: Int = 0
        var i: Int = 0
        var j: Int = 0
        var nyears: Int = self.as_integer("analysis_period")
        var sys_scale = List[ssc_number_t]()
        for i in range(nyears):
            sys_scale.append(0.0)
        parr = self.as_array("system_degradation")
        count = len(parr)
        if count == 1:
            for i in range(nyears):
                sys_scale[i] = ssc_number_t(pow(Float64(1 - parr[0] * 0.01), Float64(i)))
        else:
            for i in range(min(nyears, count)):
                sys_scale[i] = ssc_number_t(1.0 - parr[i] * 0.01)
        parr = self.as_array("system_availability")
        count = len(parr)
        if count == 1:
            for i in range(nyears):
                sys_scale[i] *= ssc_number_t(parr[0] * 0.01)
        else:
            for i in range(min(nyears, count)):
                sys_scale[i] *= ssc_number_t(parr[i] * 0.01)
        var load_scale = List[ssc_number_t]()
        for i in range(nyears):
            load_scale.append(0.0)
        parr = self.as_array("load_escalation")
        count = len(parr)
        if count == 1:
            for i in range(nyears):
                load_scale[i] = ssc_number_t(pow(Float64(1 + parr[0] * 0.01), Float64(i)))
        else:
            for i in range(nyears):
                load_scale[i] = ssc_number_t(1 + parr[i] * 0.01)
        var rate_scale = List[ssc_number_t]()
        for i in range(nyears):
            rate_scale.append(0.0)
        parr = self.as_array("rate_escalation")
        count = len(parr)
        if count == 1:
            for i in range(nyears):
                rate_scale[i] = ssc_number_t(pow(Float64(1 + parr[0] * 0.01), Float64(i)))
        else:
            for i in range(nyears):
                rate_scale[i] = ssc_number_t(1 + parr[i] * 0.01)
        var e_sys = List[ssc_number_t]()
        var p_sys = List[ssc_number_t]()
        var e_load = List[ssc_number_t]()
        var p_load = List[ssc_number_t]()
        var e_grid = List[ssc_number_t]()
        var p_grid = List[ssc_number_t]()
        var e_load_cy = List[ssc_number_t]()
        var p_load_cy = List[ssc_number_t]()
        for i in range(8760):
            e_sys.append(0.0)
            p_sys.append(0.0)
            e_load.append(0.0)
            p_load.append(0.0)
            e_grid.append(0.0)
            p_grid.append(0.0)
            e_load_cy.append(0.0)
            p_load_cy.append(0.0)
        parr = self.as_array("e_with_system")
        count = len(parr)
        for i in range(8760):
            e_sys[i] = parr[i]
            p_sys[i] = parr[i]
            e_grid[i] = 0.0
            p_grid[i] = 0.0
            e_load[i] = 0.0
            p_load[i] = 0.0
            e_load_cy[i] = 0.0
            p_load_cy[i] = 0.0
        if self.is_assigned("p_with_system"):
            parr = self.as_array("p_with_system")
            count = len(parr)
            if count != 8760:
                raise Error("p_with_system must have 8760 values")
            for i in range(8760):
                p_sys[i] = parr[i]
        if self.is_assigned("e_without_system"):
            parr = self.as_array("e_without_system")
            count = len(parr)
            if count != 8760:
                raise Error("e_without_system must have 8760 values")
            for i in range(8760):
                e_load[i] = parr[i]
                p_load[i] = parr[i]
        if self.is_assigned("p_without_system"):
            parr = self.as_array("p_without_system")
            count = len(parr)
            if count != 8760:
                raise Error("p_without_system must have 8760 values")
            for i in range(8760):
                p_load[i] = parr[i]
        # allocate intermediate data arrays
        var revenue_w_sys = List[ssc_number_t]()
        var revenue_wo_sys = List[ssc_number_t]()
        var payment = List[ssc_number_t]()
        var income = List[ssc_number_t]()
        var price = List[ssc_number_t]()
        for i in range(8760):
            revenue_w_sys.append(0.0)
            revenue_wo_sys.append(0.0)
            payment.append(0.0)
            income.append(0.0)
            price.append(0.0)
        var monthly_revenue_w_sys = List[ssc_number_t]()
        var monthly_revenue_wo_sys = List[ssc_number_t]()
        var monthly_fixed_charges = List[ssc_number_t]()
        var monthly_dc_fixed = List[ssc_number_t]()
        var monthly_dc_tou = List[ssc_number_t]()
        var monthly_tr_charges = List[ssc_number_t]()
        var monthly_tr_rates = List[ssc_number_t]()
        for i in range(12):
            monthly_revenue_w_sys.append(0.0)
            monthly_revenue_wo_sys.append(0.0)
            monthly_fixed_charges.append(0.0)
            monthly_dc_fixed.append(0.0)
            monthly_dc_tou.append(0.0)
            monthly_tr_charges.append(0.0)
            monthly_tr_rates.append(0.0)
        # allocate outputs
        var annual_net_revenue = self.allocate("energy_value", nyears)
        var energy_net = self.allocate("energy_net", nyears)
        var annual_revenue_w_sys = self.allocate("revenue_with_system", nyears)
        var annual_revenue_wo_sys = self.allocate("revenue_without_system", nyears)
        var annual_elec_cost_w_sys = self.allocate("elec_cost_with_system", nyears)
        var annual_elec_cost_wo_sys = self.allocate("elec_cost_without_system", nyears)
        var ch_dc_fixed_jan = self.allocate("charge_dc_fixed_jan", nyears)
        var ch_dc_fixed_feb = self.allocate("charge_dc_fixed_feb", nyears)
        var ch_dc_fixed_mar = self.allocate("charge_dc_fixed_mar", nyears)
        var ch_dc_fixed_apr = self.allocate("charge_dc_fixed_apr", nyears)
        var ch_dc_fixed_may = self.allocate("charge_dc_fixed_may", nyears)
        var ch_dc_fixed_jun = self.allocate("charge_dc_fixed_jun", nyears)
        var ch_dc_fixed_jul = self.allocate("charge_dc_fixed_jul", nyears)
        var ch_dc_fixed_aug = self.allocate("charge_dc_fixed_aug", nyears)
        var ch_dc_fixed_sep = self.allocate("charge_dc_fixed_sep", nyears)
        var ch_dc_fixed_oct = self.allocate("charge_dc_fixed_oct", nyears)
        var ch_dc_fixed_nov = self.allocate("charge_dc_fixed_nov", nyears)
        var ch_dc_fixed_dec = self.allocate("charge_dc_fixed_dec", nyears)
        var ch_dc_tou_jan = self.allocate("charge_dc_tou_jan", nyears)
        var ch_dc_tou_feb = self.allocate("charge_dc_tou_feb", nyears)
        var ch_dc_tou_mar = self.allocate("charge_dc_tou_mar", nyears)
        var ch_dc_tou_apr = self.allocate("charge_dc_tou_apr", nyears)
        var ch_dc_tou_may = self.allocate("charge_dc_tou_may", nyears)
        var ch_dc_tou_jun = self.allocate("charge_dc_tou_jun", nyears)
        var ch_dc_tou_jul = self.allocate("charge_dc_tou_jul", nyears)
        var ch_dc_tou_aug = self.allocate("charge_dc_tou_aug", nyears)
        var ch_dc_tou_sep = self.allocate("charge_dc_tou_sep", nyears)
        var ch_dc_tou_oct = self.allocate("charge_dc_tou_oct", nyears)
        var ch_dc_tou_nov = self.allocate("charge_dc_tou_nov", nyears)
        var ch_dc_tou_dec = self.allocate("charge_dc_tou_dec", nyears)
        var ch_tr_jan = self.allocate("charge_tr_jan", nyears)
        var ch_tr_feb = self.allocate("charge_tr_feb", nyears)
        var ch_tr_mar = self.allocate("charge_tr_mar", nyears)
        var ch_tr_apr = self.allocate("charge_tr_apr", nyears)
        var ch_tr_may = self.allocate("charge_tr_may", nyears)
        var ch_tr_jun = self.allocate("charge_tr_jun", nyears)
        var ch_tr_jul = self.allocate("charge_tr_jul", nyears)
        var ch_tr_aug = self.allocate("charge_tr_aug", nyears)
        var ch_tr_sep = self.allocate("charge_tr_sep", nyears)
        var ch_tr_oct = self.allocate("charge_tr_oct", nyears)
        var ch_tr_nov = self.allocate("charge_tr_nov", nyears)
        var ch_tr_dec = self.allocate("charge_tr_dec", nyears)
        for i in range(nyears):
            for j in range(8760):
                e_load_cy[j] = e_load[j] * load_scale[i]
                p_load_cy[j] = p_load[j] * load_scale[i]
                e_grid[j] = e_sys[j] * sys_scale[i] + e_load_cy[j]
                p_grid[j] = p_sys[j] * sys_scale[i] + p_load_cy[j]
            self.ur_calc(e_grid, p_grid,
                revenue_w_sys, payment, income, price,
                monthly_fixed_charges,
                monthly_dc_fixed, monthly_dc_tou,
                monthly_tr_charges, monthly_tr_rates)
            if i == 0:
                self.assign("year1_hourly_revenue_with_system", var_data(revenue_w_sys, 8760))
                self.assign("year1_hourly_payment_with_system", var_data(payment, 8760))
                self.assign("year1_hourly_income_with_system", var_data(income, 8760))
                self.assign("year1_hourly_price_with_system", var_data(price, 8760))
                self.assign("year1_hourly_e_grid", var_data(e_grid, 8760))
                self.assign("year1_hourly_p_grid", var_data(p_grid, 8760))
                var output = List[ssc_number_t]()
                var edemand = List[ssc_number_t]()
                var pdemand = List[ssc_number_t]()
                var e_sys_to_grid = List[ssc_number_t]()
                var e_sys_to_load = List[ssc_number_t]()
                var p_sys_to_load = List[ssc_number_t]()
                for j in range(8760):
                    output.append(0.0)
                    edemand.append(0.0)
                    pdemand.append(0.0)
                    e_sys_to_grid.append(0.0)
                    e_sys_to_load.append(0.0)
                    p_sys_to_load.append(0.0)
                for j in range(8760):
                    output[j] = e_sys[j] * sys_scale[i]
                    edemand[j] = -e_grid[j] if e_grid[j] < 0.0 else ssc_number_t(0.0)
                    pdemand[j] = -p_grid[j] if p_grid[j] < 0.0 else ssc_number_t(0.0)
                    var sys_e_net = output[j] + e_load[j]
                    e_sys_to_grid[j] = sys_e_net if sys_e_net > 0 else ssc_number_t(0.0)
                    e_sys_to_load[j] = -e_load[j] if sys_e_net > 0 else output[j]
                    var sys_p_net = output[j] + p_load[j]
                    p_sys_to_load[j] = -p_load[j] if sys_p_net > 0 else output[j]
                self.assign("year1_hourly_system_output", var_data(output, 8760))
                self.assign("year1_hourly_e_demand", var_data(edemand, 8760))
                self.assign("year1_hourly_p_demand", var_data(pdemand, 8760))
                self.assign("year1_hourly_system_to_grid", var_data(e_sys_to_grid, 8760))
                self.assign("year1_hourly_system_to_load", var_data(e_sys_to_load, 8760))
                self.assign("year1_hourly_p_system_to_load", var_data(p_sys_to_load, 8760))
                self.assign("year1_monthly_dc_fixed_with_system", var_data(monthly_dc_fixed, 12))
                self.assign("year1_monthly_dc_tou_with_system", var_data(monthly_dc_tou, 12))
                self.assign("year1_monthly_tr_charge_with_system", var_data(monthly_tr_charges, 12))
                self.assign("year1_monthly_tr_rate_with_system", var_data(monthly_tr_rates, 12))
            self.ur_calc(e_load_cy, p_load_cy,
                revenue_wo_sys, payment, income, price,
                monthly_fixed_charges,
                monthly_dc_fixed, monthly_dc_tou,
                monthly_tr_charges, monthly_tr_rates)
            if i == 0:
                self.assign("year1_hourly_revenue_without_system", var_data(revenue_wo_sys, 8760))
                self.assign("year1_hourly_payment_without_system", var_data(payment, 8760))
                self.assign("year1_hourly_income_without_system", var_data(income, 8760))
                self.assign("year1_hourly_price_without_system", var_data(price, 8760))
                self.assign("year1_monthly_dc_fixed_without_system", var_data(monthly_dc_fixed, 12))
                self.assign("year1_monthly_dc_tou_without_system", var_data(monthly_dc_tou, 12))
                self.assign("year1_monthly_tr_charge_without_system", var_data(monthly_tr_charges, 12))
                self.assign("year1_monthly_tr_rate_without_system", var_data(monthly_tr_rates, 12))
            annual_net_revenue[i] = 0.0
            energy_net[i] = 0.0
            annual_revenue_w_sys[i] = 0.0
            annual_revenue_wo_sys[i] = 0.0
            for j in range(8760):
                energy_net[i] += e_sys[j] * sys_scale[i]
                annual_net_revenue[i] += revenue_w_sys[j] - revenue_wo_sys[j]
                annual_revenue_w_sys[i] += revenue_w_sys[j]
                annual_revenue_wo_sys[i] += revenue_wo_sys[j]
            annual_net_revenue[i] *= rate_scale[i]
            annual_revenue_w_sys[i] *= rate_scale[i]
            annual_revenue_wo_sys[i] *= rate_scale[i]
            annual_elec_cost_w_sys[i] = -annual_revenue_w_sys[i]
            annual_elec_cost_wo_sys[i] = -annual_revenue_wo_sys[i]
            ch_dc_fixed_jan[i] = monthly_dc_fixed[0] * rate_scale[i]
            ch_dc_fixed_feb[i] = monthly_dc_fixed[1] * rate_scale[i]
            ch_dc_fixed_mar[i] = monthly_dc_fixed[2] * rate_scale[i]
            ch_dc_fixed_apr[i] = monthly_dc_fixed[3] * rate_scale[i]
            ch_dc_fixed_may[i] = monthly_dc_fixed[4] * rate_scale[i]
            ch_dc_fixed_jun[i] = monthly_dc_fixed[5] * rate_scale[i]
            ch_dc_fixed_jul[i] = monthly_dc_fixed[6] * rate_scale[i]
            ch_dc_fixed_aug[i] = monthly_dc_fixed[7] * rate_scale[i]
            ch_dc_fixed_sep[i] = monthly_dc_fixed[8] * rate_scale[i]
            ch_dc_fixed_oct[i] = monthly_dc_fixed[9] * rate_scale[i]
            ch_dc_fixed_nov[i] = monthly_dc_fixed[10] * rate_scale[i]
            ch_dc_fixed_dec[i] = monthly_dc_fixed[11] * rate_scale[i]
            ch_dc_tou_jan[i] = monthly_dc_tou[0] * rate_scale[i]
            ch_dc_tou_feb[i] = monthly_dc_tou[1] * rate_scale[i]
            ch_dc_tou_mar[i] = monthly_dc_tou[2] * rate_scale[i]
            ch_dc_tou_apr[i] = monthly_dc_tou[3] * rate_scale[i]
            ch_dc_tou_may[i] = monthly_dc_tou[4] * rate_scale[i]
            ch_dc_tou_jun[i] = monthly_dc_tou[5] * rate_scale[i]
            ch_dc_tou_jul[i] = monthly_dc_tou[6] * rate_scale[i]
            ch_dc_tou_aug[i] = monthly_dc_tou[7] * rate_scale[i]
            ch_dc_tou_sep[i] = monthly_dc_tou[8] * rate_scale[i]
            ch_dc_tou_oct[i] = monthly_dc_tou[9] * rate_scale[i]
            ch_dc_tou_nov[i] = monthly_dc_tou[10] * rate_scale[i]
            ch_dc_tou_dec[i] = monthly_dc_tou[11] * rate_scale[i]
            ch_tr_jan[i] = monthly_tr_charges[0] * rate_scale[i]
            ch_tr_feb[i] = monthly_tr_charges[1] * rate_scale[i]
            ch_tr_mar[i] = monthly_tr_charges[2] * rate_scale[i]
            ch_tr_apr[i] = monthly_tr_charges[3] * rate_scale[i]
            ch_tr_may[i] = monthly_tr_charges[4] * rate_scale[i]
            ch_tr_jun[i] = monthly_tr_charges[5] * rate_scale[i]
            ch_tr_jul[i] = monthly_tr_charges[6] * rate_scale[i]
            ch_tr_aug[i] = monthly_tr_charges[7] * rate_scale[i]
            ch_tr_sep[i] = monthly_tr_charges[8] * rate_scale[i]
            ch_tr_oct[i] = monthly_tr_charges[9] * rate_scale[i]
            ch_tr_nov[i] = monthly_tr_charges[10] * rate_scale[i]
            ch_tr_dec[i] = monthly_tr_charges[11] * rate_scale[i]

    def ur_calc(self, e_in: List[ssc_number_t], p_in: List[ssc_number_t],
        revenue: List[ssc_number_t], payment: List[ssc_number_t], income: List[ssc_number_t], price: List[ssc_number_t],
        monthly_fixed_charges: List[ssc_number_t],
        monthly_dc_fixed: List[ssc_number_t], monthly_dc_tou: List[ssc_number_t],
        monthly_tr_charges: List[ssc_number_t], monthly_tr_rates: List[ssc_number_t]):
        var i: Int
        for i in range(8760):
            revenue[i] = 0.0
            payment[i] = 0.0
            income[i] = 0.0
            price[i] = 0.0
        for i in range(12):
            monthly_fixed_charges[i] = 0.0
            monthly_dc_fixed[i] = 0.0
            monthly_dc_tou[i] = 0.0
            monthly_tr_charges[i] = 0.0
            monthly_tr_rates[i] = 0.0
        self.process_flat_rate(e_in, payment, income, price)
        self.process_monthly_charge(payment, monthly_fixed_charges)
        if self.as_boolean("ur_tou_enable"):
            self.process_tou_rate(e_in, payment, income, price)
        if self.as_boolean("ur_dc_enable"):
            self.process_demand_charge(p_in, payment, monthly_dc_fixed, monthly_dc_tou)
        if self.as_boolean("ur_tr_enable"):
            self.process_tiered_rate(e_in, payment, income, monthly_tr_charges, monthly_tr_rates)
        for i in range(8760):
            revenue[i] = income[i] - payment[i]

    def process_flat_rate(self, e: List[ssc_number_t],
       
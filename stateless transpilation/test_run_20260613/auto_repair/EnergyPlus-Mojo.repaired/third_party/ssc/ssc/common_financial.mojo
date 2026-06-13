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

from common_financial import *
from core import compute_module, ssc_number_t, var_data, exec_error, general_error, util
from memory import UnsafePointer
from math import min, max

def Const_per_principal(const_per_percent: Float64, total_installed_cost: Float64) -> Float64:		# [$]
	return (const_per_percent / 100.0) * total_installed_cost

def Const_per_interest(const_per_principal: Float64, const_per_interest_rate: Float64,
	const_per_months: Float64) -> Float64:		# [$]
	return const_per_principal * (const_per_interest_rate / 100.0) / 12.0 * const_per_months / 2.0

def Const_per_total(const_per_interest: Float64, const_per_principal: Float64,
	const_per_upfront_rate: Float64) -> Float64:		# [$]
	var up_front_fee = const_per_principal * (const_per_upfront_rate / 100.0)
	return const_per_interest + up_front_fee

def save_cf(cm: compute_module, mat: util.matrix_t[Float64], cf_line: Int, m_nyears: Int, name: String):
	var arrp = cm.allocate(name, m_nyears + 1)
	for i in range(m_nyears + 1):
		arrp[i] = ssc_number_t(mat.at(cf_line, i))

# enum constants
const CF_TODJanEnergy: Int = 0
const CF_TODFebEnergy: Int = 1
const CF_TODMarEnergy: Int = 2
const CF_TODAprEnergy: Int = 3
const CF_TODMayEnergy: Int = 4
const CF_TODJunEnergy: Int = 5
const CF_TODJulEnergy: Int = 6
const CF_TODAugEnergy: Int = 7
const CF_TODSepEnergy: Int = 8
const CF_TODOctEnergy: Int = 9
const CF_TODNovEnergy: Int = 10
const CF_TODDecEnergy: Int = 11
const CF_TODJanRevenue: Int = 12
const CF_TODFebRevenue: Int = 13
const CF_TODMarRevenue: Int = 14
const CF_TODAprRevenue: Int = 15
const CF_TODMayRevenue: Int = 16
const CF_TODJunRevenue: Int = 17
const CF_TODJulRevenue: Int = 18
const CF_TODAugRevenue: Int = 19
const CF_TODSepRevenue: Int = 20
const CF_TODOctRevenue: Int = 21
const CF_TODNovRevenue: Int = 22
const CF_TODDecRevenue: Int = 23
const CF_max_timestep: Int = 24
const CF_TOD1Energy: Int = 25
const CF_TOD2Energy: Int = 26
const CF_TOD3Energy: Int = 27
const CF_TOD4Energy: Int = 28
const CF_TOD5Energy: Int = 29
const CF_TOD6Energy: Int = 30
const CF_TOD7Energy: Int = 31
const CF_TOD8Energy: Int = 32
const CF_TOD9Energy: Int = 33
const CF_TOD1JanEnergy: Int = 34
const CF_TOD1FebEnergy: Int = 35
const CF_TOD1MarEnergy: Int = 36
const CF_TOD1AprEnergy: Int = 37
const CF_TOD1MayEnergy: Int = 38
const CF_TOD1JunEnergy: Int = 39
const CF_TOD1JulEnergy: Int = 40
const CF_TOD1AugEnergy: Int = 41
const CF_TOD1SepEnergy: Int = 42
const CF_TOD1OctEnergy: Int = 43
const CF_TOD1NovEnergy: Int = 44
const CF_TOD1DecEnergy: Int = 45
const CF_TOD2JanEnergy: Int = 46
const CF_TOD2FebEnergy: Int = 47
const CF_TOD2MarEnergy: Int = 48
const CF_TOD2AprEnergy: Int = 49
const CF_TOD2MayEnergy: Int = 50
const CF_TOD2JunEnergy: Int = 51
const CF_TOD2JulEnergy: Int = 52
const CF_TOD2AugEnergy: Int = 53
const CF_TOD2SepEnergy: Int = 54
const CF_TOD2OctEnergy: Int = 55
const CF_TOD2NovEnergy: Int = 56
const CF_TOD2DecEnergy: Int = 57
const CF_TOD3JanEnergy: Int = 58
const CF_TOD3FebEnergy: Int = 59
const CF_TOD3MarEnergy: Int = 60
const CF_TOD3AprEnergy: Int = 61
const CF_TOD3MayEnergy: Int = 62
const CF_TOD3JunEnergy: Int = 63
const CF_TOD3JulEnergy: Int = 64
const CF_TOD3AugEnergy: Int = 65
const CF_TOD3SepEnergy: Int = 66
const CF_TOD3OctEnergy: Int = 67
const CF_TOD3NovEnergy: Int = 68
const CF_TOD3DecEnergy: Int = 69
const CF_TOD4JanEnergy: Int = 70
const CF_TOD4FebEnergy: Int = 71
const CF_TOD4MarEnergy: Int = 72
const CF_TOD4AprEnergy: Int = 73
const CF_TOD4MayEnergy: Int = 74
const CF_TOD4JunEnergy: Int = 75
const CF_TOD4JulEnergy: Int = 76
const CF_TOD4AugEnergy: Int = 77
const CF_TOD4SepEnergy: Int = 78
const CF_TOD4OctEnergy: Int = 79
const CF_TOD4NovEnergy: Int = 80
const CF_TOD4DecEnergy: Int = 81
const CF_TOD5JanEnergy: Int = 82
const CF_TOD5FebEnergy: Int = 83
const CF_TOD5MarEnergy: Int = 84
const CF_TOD5AprEnergy: Int = 85
const CF_TOD5MayEnergy: Int = 86
const CF_TOD5JunEnergy: Int = 87
const CF_TOD5JulEnergy: Int = 88
const CF_TOD5AugEnergy: Int = 89
const CF_TOD5SepEnergy: Int = 90
const CF_TOD5OctEnergy: Int = 91
const CF_TOD5NovEnergy: Int = 92
const CF_TOD5DecEnergy: Int = 93
const CF_TOD6JanEnergy: Int = 94
const CF_TOD6FebEnergy: Int = 95
const CF_TOD6MarEnergy: Int = 96
const CF_TOD6AprEnergy: Int = 97
const CF_TOD6MayEnergy: Int = 98
const CF_TOD6JunEnergy: Int = 99
const CF_TOD6JulEnergy: Int = 100
const CF_TOD6AugEnergy: Int = 101
const CF_TOD6SepEnergy: Int = 102
const CF_TOD6OctEnergy: Int = 103
const CF_TOD6NovEnergy: Int = 104
const CF_TOD6DecEnergy: Int = 105
const CF_TOD7JanEnergy: Int = 106
const CF_TOD7FebEnergy: Int = 107
const CF_TOD7MarEnergy: Int = 108
const CF_TOD7AprEnergy: Int = 109
const CF_TOD7MayEnergy: Int = 110
const CF_TOD7JunEnergy: Int = 111
const CF_TOD7JulEnergy: Int = 112
const CF_TOD7AugEnergy: Int = 113
const CF_TOD7SepEnergy: Int = 114
const CF_TOD7OctEnergy: Int = 115
const CF_TOD7NovEnergy: Int = 116
const CF_TOD7DecEnergy: Int = 117
const CF_TOD8JanEnergy: Int = 118
const CF_TOD8FebEnergy: Int = 119
const CF_TOD8MarEnergy: Int = 120
const CF_TOD8AprEnergy: Int = 121
const CF_TOD8MayEnergy: Int = 122
const CF_TOD8JunEnergy: Int = 123
const CF_TOD8JulEnergy: Int = 124
const CF_TOD8AugEnergy: Int = 125
const CF_TOD8SepEnergy: Int = 126
const CF_TOD8OctEnergy: Int = 127
const CF_TOD8NovEnergy: Int = 128
const CF_TOD8DecEnergy: Int = 129
const CF_TOD9JanEnergy: Int = 130
const CF_TOD9FebEnergy: Int = 131
const CF_TOD9MarEnergy: Int = 132
const CF_TOD9AprEnergy: Int = 133
const CF_TOD9MayEnergy: Int = 134
const CF_TOD9JunEnergy: Int = 135
const CF_TOD9JulEnergy: Int = 136
const CF_TOD9AugEnergy: Int = 137
const CF_TOD9SepEnergy: Int = 138
const CF_TOD9OctEnergy: Int = 139
const CF_TOD9NovEnergy: Int = 140
const CF_TOD9DecEnergy: Int = 141
const CF_TOD1Revenue: Int = 142
const CF_TOD2Revenue: Int = 143
const CF_TOD3Revenue: Int = 144
const CF_TOD4Revenue: Int = 145
const CF_TOD5Revenue: Int = 146
const CF_TOD6Revenue: Int = 147
const CF_TOD7Revenue: Int = 148
const CF_TOD8Revenue: Int = 149
const CF_TOD9Revenue: Int = 150
const CF_revenue_monthly_firstyear_TOD1: Int = 151
const CF_energy_net_monthly_firstyear_TOD1: Int = 152
const CF_revenue_monthly_firstyear_TOD2: Int = 153
const CF_energy_net_monthly_firstyear_TOD2: Int = 154
const CF_revenue_monthly_firstyear_TOD3: Int = 155
const CF_energy_net_monthly_firstyear_TOD3: Int = 156
const CF_revenue_monthly_firstyear_TOD4: Int = 157
const CF_energy_net_monthly_firstyear_TOD4: Int = 158
const CF_revenue_monthly_firstyear_TOD5: Int = 159
const CF_energy_net_monthly_firstyear_TOD5: Int = 160
const CF_revenue_monthly_firstyear_TOD6: Int = 161
const CF_energy_net_monthly_firstyear_TOD6: Int = 162
const CF_revenue_monthly_firstyear_TOD7: Int = 163
const CF_energy_net_monthly_firstyear_TOD7: Int = 164
const CF_revenue_monthly_firstyear_TOD8: Int = 165
const CF_energy_net_monthly_firstyear_TOD8: Int = 166
const CF_revenue_monthly_firstyear_TOD9: Int = 167
const CF_energy_net_monthly_firstyear_TOD9: Int = 168
const CF_max_dispatch: Int = 169

@value
class dispatch_calculations:
	var m_cm: compute_module
	var m_periods: List[Int]
	var m_error: String
	var m_cf: util.matrix_t[Float64]
	var m_degradation: List[Float64]
	var m_hourly_energy: List[Float64]
	var m_nyears: Int
	var m_timestep: Bool
	var m_gen: List[ssc_number_t]  # Time series power
	var m_multipliers: List[ssc_number_t]  # Time series ppa multiplers
	var m_ngen: Int  # Number of records in gen
	var m_nmultipliers: Int  # Number of records in m_multipliers

	def __init__(inout self):

	def __init__(inout self, cm: compute_module, degradation: List[Float64], hourly_energy: List[Float64]):
		self.init(cm, degradation, hourly_energy)

	def init(inout self, cm: compute_module, degradation: List[Float64], hourly_energy: List[Float64]) -> Bool:
		if cm is None:
			return False
		self.m_cm = cm
		self.m_degradation = degradation
		self.m_hourly_energy = hourly_energy
		self.m_timestep = (self.m_cm.as_integer("ppa_multiplier_model") == 1)
		self.m_nyears = self.m_cm.as_integer("analysis_period")
		if len(self.m_degradation) != (self.m_nyears + 1):
			return False
		if self.m_timestep:
			self.setup_ts()
			if self.m_cm.as_integer("system_use_lifetime_output"):
				self.compute_lifetime_dispatch_output_ts()  # TODO - finish and test this!!
			else:
				self.compute_dispatch_output_ts()
		else:
			self.setup()
			if self.m_cm.as_integer("system_use_lifetime_output"):
				self.compute_lifetime_dispatch_output()
			else:
				self.compute_dispatch_output()
		return True

	def compute_outputs_ts(inout self, ppa: List[Float64]) -> Bool:
		if len(ppa) != (self.m_nyears + 1):
			return False
		save_cf(self.m_cm, self.m_cf, CF_TODJanEnergy, self.m_nyears, "cf_energy_net_jan")
		save_cf(self.m_cm, self.m_cf, CF_TODFebEnergy, self.m_nyears, "cf_energy_net_feb")
		save_cf(self.m_cm, self.m_cf, CF_TODMarEnergy, self.m_nyears, "cf_energy_net_mar")
		save_cf(self.m_cm, self.m_cf, CF_TODAprEnergy, self.m_nyears, "cf_energy_net_apr")
		save_cf(self.m_cm, self.m_cf, CF_TODMayEnergy, self.m_nyears, "cf_energy_net_may")
		save_cf(self.m_cm, self.m_cf, CF_TODJunEnergy, self.m_nyears, "cf_energy_net_jun")
		save_cf(self.m_cm, self.m_cf, CF_TODJulEnergy, self.m_nyears, "cf_energy_net_jul")
		save_cf(self.m_cm, self.m_cf, CF_TODAugEnergy, self.m_nyears, "cf_energy_net_aug")
		save_cf(self.m_cm, self.m_cf, CF_TODSepEnergy, self.m_nyears, "cf_energy_net_sep")
		save_cf(self.m_cm, self.m_cf, CF_TODOctEnergy, self.m_nyears, "cf_energy_net_oct")
		save_cf(self.m_cm, self.m_cf, CF_TODNovEnergy, self.m_nyears, "cf_energy_net_nov")
		save_cf(self.m_cm, self.m_cf, CF_TODDecEnergy, self.m_nyears, "cf_energy_net_dec")
		for y in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODJanRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODFebRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODMarRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODAprRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODMayRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODJunRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODJulRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODAugRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODSepRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODOctRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODNovRevenue, y) *= (ppa[y] / 100.0)
			self.m_cf.at(CF_TODDecRevenue, y) *= (ppa[y] / 100.0)
		save_cf(self.m_cm, self.m_cf, CF_TODJanRevenue, self.m_nyears, "cf_revenue_jan")
		save_cf(self.m_cm, self.m_cf, CF_TODFebRevenue, self.m_nyears, "cf_revenue_feb")
		save_cf(self.m_cm, self.m_cf, CF_TODMarRevenue, self.m_nyears, "cf_revenue_mar")
		save_cf(self.m_cm, self.m_cf, CF_TODAprRevenue, self.m_nyears, "cf_revenue_apr")
		save_cf(self.m_cm, self.m_cf, CF_TODMayRevenue, self.m_nyears, "cf_revenue_may")
		save_cf(self.m_cm, self.m_cf, CF_TODJunRevenue, self.m_nyears, "cf_revenue_jun")
		save_cf(self.m_cm, self.m_cf, CF_TODJulRevenue, self.m_nyears, "cf_revenue_jul")
		save_cf(self.m_cm, self.m_cf, CF_TODAugRevenue, self.m_nyears, "cf_revenue_aug")
		save_cf(self.m_cm, self.m_cf, CF_TODSepRevenue, self.m_nyears, "cf_revenue_sep")
		save_cf(self.m_cm, self.m_cf, CF_TODOctRevenue, self.m_nyears, "cf_revenue_oct")
		save_cf(self.m_cm, self.m_cf, CF_TODNovRevenue, self.m_nyears, "cf_revenue_nov")
		save_cf(self.m_cm, self.m_cf, CF_TODDecRevenue, self.m_nyears, "cf_revenue_dec")
		return True

	def compute_outputs(inout self, ppa: List[Float64]) -> Bool:
		if len(ppa) != (self.m_nyears + 1):
			return False
		if self.m_timestep:
			return self.compute_outputs_ts(ppa)
		var dispatch_factor1 = self.m_cm.as_double("dispatch_factor1")
		var dispatch_factor2 = self.m_cm.as_double("dispatch_factor2")
		var dispatch_factor3 = self.m_cm.as_double("dispatch_factor3")
		var dispatch_factor4 = self.m_cm.as_double("dispatch_factor4")
		var dispatch_factor5 = self.m_cm.as_double("dispatch_factor5")
		var dispatch_factor6 = self.m_cm.as_double("dispatch_factor6")
		var dispatch_factor7 = self.m_cm.as_double("dispatch_factor7")
		var dispatch_factor8 = self.m_cm.as_double("dispatch_factor8")
		var dispatch_factor9 = self.m_cm.as_double("dispatch_factor9")
		if self.m_cm.as_integer("system_use_lifetime_output"):
			self.process_lifetime_dispatch_output()
		else:
			self.process_dispatch_output()
		save_cf(self.m_cm, self.m_cf, CF_TODJanEnergy, self.m_nyears, "cf_energy_net_jan")
		save_cf(self.m_cm, self.m_cf, CF_TODFebEnergy, self.m_nyears, "cf_energy_net_feb")
		save_cf(self.m_cm, self.m_cf, CF_TODMarEnergy, self.m_nyears, "cf_energy_net_mar")
		save_cf(self.m_cm, self.m_cf, CF_TODAprEnergy, self.m_nyears, "cf_energy_net_apr")
		save_cf(self.m_cm, self.m_cf, CF_TODMayEnergy, self.m_nyears, "cf_energy_net_may")
		save_cf(self.m_cm, self.m_cf, CF_TODJunEnergy, self.m_nyears, "cf_energy_net_jun")
		save_cf(self.m_cm, self.m_cf, CF_TODJulEnergy, self.m_nyears, "cf_energy_net_jul")
		save_cf(self.m_cm, self.m_cf, CF_TODAugEnergy, self.m_nyears, "cf_energy_net_aug")
		save_cf(self.m_cm, self.m_cf, CF_TODSepEnergy, self.m_nyears, "cf_energy_net_sep")
		save_cf(self.m_cm, self.m_cf, CF_TODOctEnergy, self.m_nyears, "cf_energy_net_oct")
		save_cf(self.m_cm, self.m_cf, CF_TODNovEnergy, self.m_nyears, "cf_energy_net_nov")
		save_cf(self.m_cm, self.m_cf, CF_TODDecEnergy, self.m_nyears, "cf_energy_net_dec")
		save_cf(self.m_cm, self.m_cf, CF_TOD1Energy, self.m_nyears, "cf_energy_net_dispatch1")
		save_cf(self.m_cm, self.m_cf, CF_TOD2Energy, self.m_nyears, "cf_energy_net_dispatch2")
		save_cf(self.m_cm, self.m_cf, CF_TOD3Energy, self.m_nyears, "cf_energy_net_dispatch3")
		save_cf(self.m_cm, self.m_cf, CF_TOD4Energy, self.m_nyears, "cf_energy_net_dispatch4")
		save_cf(self.m_cm, self.m_cf, CF_TOD5Energy, self.m_nyears, "cf_energy_net_dispatch5")
		save_cf(self.m_cm, self.m_cf, CF_TOD6Energy, self.m_nyears, "cf_energy_net_dispatch6")
		save_cf(self.m_cm, self.m_cf, CF_TOD7Energy, self.m_nyears, "cf_energy_net_dispatch7")
		save_cf(self.m_cm, self.m_cf, CF_TOD8Energy, self.m_nyears, "cf_energy_net_dispatch8")
		save_cf(self.m_cm, self.m_cf, CF_TOD9Energy, self.m_nyears, "cf_energy_net_dispatch9")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TOD1Revenue, i) = ppa[i] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1Energy, i)
			self.m_cf.at(CF_TOD2Revenue, i) = ppa[i] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2Energy, i)
			self.m_cf.at(CF_TOD3Revenue, i) = ppa[i] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3Energy, i)
			self.m_cf.at(CF_TOD4Revenue, i) = ppa[i] / 100.0 * dispatch_factor4 * self.m_cf.at(CF_TOD4Energy, i)
			self.m_cf.at(CF_TOD5Revenue, i) = ppa[i] / 100.0 * dispatch_factor5 * self.m_cf.at(CF_TOD5Energy, i)
			self.m_cf.at(CF_TOD6Revenue, i) = ppa[i] / 100.0 * dispatch_factor6 * self.m_cf.at(CF_TOD6Energy, i)
			self.m_cf.at(CF_TOD7Revenue, i) = ppa[i] / 100.0 * dispatch_factor7 * self.m_cf.at(CF_TOD7Energy, i)
			self.m_cf.at(CF_TOD8Revenue, i) = ppa[i] / 100.0 * dispatch_factor8 * self.m_cf.at(CF_TOD8Energy, i)
			self.m_cf.at(CF_TOD9Revenue, i) = ppa[i] / 100.0 * dispatch_factor9 * self.m_cf.at(CF_TOD9Energy, i)
		save_cf(self.m_cm, self.m_cf, CF_TOD1Revenue, self.m_nyears, "cf_revenue_dispatch1")
		save_cf(self.m_cm, self.m_cf, CF_TOD2Revenue, self.m_nyears, "cf_revenue_dispatch2")
		save_cf(self.m_cm, self.m_cf, CF_TOD3Revenue, self.m_nyears, "cf_revenue_dispatch3")
		save_cf(self.m_cm, self.m_cf, CF_TOD4Revenue, self.m_nyears, "cf_revenue_dispatch4")
		save_cf(self.m_cm, self.m_cf, CF_TOD5Revenue, self.m_nyears, "cf_revenue_dispatch5")
		save_cf(self.m_cm, self.m_cf, CF_TOD6Revenue, self.m_nyears, "cf_revenue_dispatch6")
		save_cf(self.m_cm, self.m_cf, CF_TOD7Revenue, self.m_nyears, "cf_revenue_dispatch7")
		save_cf(self.m_cm, self.m_cf, CF_TOD8Revenue, self.m_nyears, "cf_revenue_dispatch8")
		save_cf(self.m_cm, self.m_cf, CF_TOD9Revenue, self.m_nyears, "cf_revenue_dispatch9")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODJanRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1JanEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2JanEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3JanEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4JanEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5JanEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6JanEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7JanEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8JanEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9JanEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODJanRevenue, self.m_nyears, "cf_revenue_jan")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODFebRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1FebEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2FebEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3FebEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4FebEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5FebEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6FebEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7FebEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8FebEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9FebEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODFebRevenue, self.m_nyears, "cf_revenue_feb")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODMarRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1MarEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2MarEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3MarEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4MarEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5MarEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6MarEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7MarEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8MarEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9MarEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODMarRevenue, self.m_nyears, "cf_revenue_mar")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODAprRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1AprEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2AprEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3AprEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4AprEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5AprEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6AprEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7AprEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8AprEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9AprEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODAprRevenue, self.m_nyears, "cf_revenue_apr")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODMayRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1MayEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2MayEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3MayEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4MayEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5MayEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6MayEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7MayEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8MayEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9MayEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODMayRevenue, self.m_nyears, "cf_revenue_may")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODJunRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1JunEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2JunEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3JunEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4JunEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5JunEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6JunEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7JunEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8JunEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9JunEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODJunRevenue, self.m_nyears, "cf_revenue_jun")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODJulRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1JulEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2JulEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3JulEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4JulEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5JulEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6JulEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7JulEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8JulEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9JulEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODJulRevenue, self.m_nyears, "cf_revenue_jul")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODAugRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1AugEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2AugEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3AugEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4AugEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5AugEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6AugEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7AugEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8AugEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9AugEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODAugRevenue, self.m_nyears, "cf_revenue_aug")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODSepRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1SepEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2SepEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3SepEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4SepEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5SepEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6SepEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7SepEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8SepEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9SepEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODSepRevenue, self.m_nyears, "cf_revenue_sep")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODOctRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1OctEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2OctEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3OctEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4OctEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5OctEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6OctEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7OctEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8OctEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9OctEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODOctRevenue, self.m_nyears, "cf_revenue_oct")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODNovRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1NovEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2NovEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3NovEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4NovEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5NovEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6NovEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7NovEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8NovEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9NovEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODNovRevenue, self.m_nyears, "cf_revenue_nov")
		for i in range(self.m_nyears + 1):
			self.m_cf.at(CF_TODDecRevenue, i) = ppa[i] / 100.0 * (
				dispatch_factor1 * self.m_cf.at(CF_TOD1DecEnergy, i) +
				dispatch_factor2 * self.m_cf.at(CF_TOD2DecEnergy, i) +
				dispatch_factor3 * self.m_cf.at(CF_TOD3DecEnergy, i) +
				dispatch_factor4 * self.m_cf.at(CF_TOD4DecEnergy, i) +
				dispatch_factor5 * self.m_cf.at(CF_TOD5DecEnergy, i) +
				dispatch_factor6 * self.m_cf.at(CF_TOD6DecEnergy, i) +
				dispatch_factor7 * self.m_cf.at(CF_TOD7DecEnergy, i) +
				dispatch_factor8 * self.m_cf.at(CF_TOD8DecEnergy, i) +
				dispatch_factor9 * self.m_cf.at(CF_TOD9DecEnergy, i))
		save_cf(self.m_cm, self.m_cf, CF_TODDecRevenue, self.m_nyears, "cf_revenue_Dec")
		#  commented out block
		# m_cf.at(CF_revenue_monthly_firstyear, 0) = m_cf.at(CF_TODJanRevenue, 1);
		# ...
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 0) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1JanEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 1) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1FebEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 2) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1MarEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 3) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1AprEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 4) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1MayEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 5) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1JunEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 6) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1JulEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 7) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1AugEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 8) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1SepEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 9) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1OctEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 10) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1NovEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD1, 11) = ppa[1] / 100.0 * dispatch_factor1 * self.m_cf.at(CF_TOD1DecEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 0) = self.m_cf.at(CF_TOD1JanEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 1) = self.m_cf.at(CF_TOD1FebEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 2) = self.m_cf.at(CF_TOD1MarEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 3) = self.m_cf.at(CF_TOD1AprEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 4) = self.m_cf.at(CF_TOD1MayEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 5) = self.m_cf.at(CF_TOD1JunEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 6) = self.m_cf.at(CF_TOD1JulEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 7) = self.m_cf.at(CF_TOD1AugEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 8) = self.m_cf.at(CF_TOD1SepEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 9) = self.m_cf.at(CF_TOD1OctEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 10) = self.m_cf.at(CF_TOD1NovEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD1, 11) = self.m_cf.at(CF_TOD1DecEnergy, 1)
		save_cf(self.m_cm, self.m_cf, CF_revenue_monthly_firstyear_TOD1, 11, "cf_revenue_monthly_firstyear_TOD1")
		save_cf(self.m_cm, self.m_cf, CF_energy_net_monthly_firstyear_TOD1, 11, "cf_energy_net_monthly_firstyear_TOD1")
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 0) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2JanEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 1) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2FebEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 2) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2MarEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 3) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2AprEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 4) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2MayEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 5) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2JunEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 6) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2JulEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 7) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2AugEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 8) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2SepEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 9) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2OctEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 10) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2NovEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD2, 11) = ppa[1] / 100.0 * dispatch_factor2 * self.m_cf.at(CF_TOD2DecEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 0) = self.m_cf.at(CF_TOD2JanEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 1) = self.m_cf.at(CF_TOD2FebEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 2) = self.m_cf.at(CF_TOD2MarEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 3) = self.m_cf.at(CF_TOD2AprEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 4) = self.m_cf.at(CF_TOD2MayEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 5) = self.m_cf.at(CF_TOD2JunEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 6) = self.m_cf.at(CF_TOD2JulEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 7) = self.m_cf.at(CF_TOD2AugEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 8) = self.m_cf.at(CF_TOD2SepEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 9) = self.m_cf.at(CF_TOD2OctEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 10) = self.m_cf.at(CF_TOD2NovEnergy, 1)
		self.m_cf.at(CF_energy_net_monthly_firstyear_TOD2, 11) = self.m_cf.at(CF_TOD2DecEnergy, 1)
		save_cf(self.m_cm, self.m_cf, CF_revenue_monthly_firstyear_TOD2, 11, "cf_revenue_monthly_firstyear_TOD2")
		save_cf(self.m_cm, self.m_cf, CF_energy_net_monthly_firstyear_TOD2, 11, "cf_energy_net_monthly_firstyear_TOD2")
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD3, 0) = ppa[1] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3JanEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD3, 1) = ppa[1] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3FebEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD3, 2) = ppa[1] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3MarEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD3, 3) = ppa[1] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3AprEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD3, 4) = ppa[1] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3MayEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD3, 5) = ppa[1] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3JunEnergy, 1)
		self.m_cf.at(CF_revenue_monthly_firstyear_TOD3, 6) = ppa[1] / 100.0 * dispatch_factor3 * self.m_cf.at(CF_TOD3JulEnergy, 1)
		self.m_cf.at(CF_re
"""
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
"""
from tcstype import *
from lib_util import *
from interpolation_routines import *

enum:
	P_eta_map = 0
	P_n_hel = 1
	P_q_start = 2
	P_p_run = 3
	P_v_wind_max = 4
	P_hel_stow_deploy = 5
	I_v_wind = 6
	I_field_control = 7
	I_theta = 8
	I_phi = 9
	I_AOD = 10
	O_pparasi = 11
	O_eta_field = 12
	N_MAX = 13

var Heliostat3DInterp_variables: List[tcsvarinfo] = List[tcsvarinfo](
	tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_eta_map, "eta_map", "Field efficiency matrix", "-", "4 columns (aod, azimuth, zenith, field efficiency)", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_hel, "n_hel", "Number of heliostats in the field", "-", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_q_start, "q_start", "Electric work for starting up one heliostat", "kWe-hr", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_p_run, "p_run", "Electric power for tracking one heliostat", "kWe", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_v_wind_max, "v_wind_max", "Maximum tolerable wind speed", "m/s", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_hel_stow_deploy, "hel_stow_deploy", "Heliostat field stow/deploy solar elevation angle", "deg", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_v_wind, "vwind", "Wind velocity", "m/s", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_field_control, "field_control", "Field defocus control", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_theta, "theta", "Solar zenith angle", "deg", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_phi, "phi", "Solar azimuth angle: 0 due north, clockwise to +360", "deg", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_AOD, "aod", "Third dimension interpolation value", "-", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_pparasi, "pparasi", "Parasitic tracking/startup power", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_eta_field, "eta_field", "Total field efficiency", "", "", "", ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
)

@value
struct Heliostat3DInterp(tcstypeinterface):
	var field_efficiency_table: Trilinear_Interp
	var n_hel: Int
	var q_start: Float64
	var p_run: Float64
	var v_wind_max: Float64
	var hel_stow_deploy: Float64
	var n_zen: Int
	var n_azi: Int
	var n_layer: Int
	var eta_prev: Float64
	var v_wind_prev: Float64

	def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
		tcstypeinterface.__init__(self, cst, ti)
		self.n_hel = Int(Float64.nan)
		self.q_start = Float64.nan
		self.p_run = Float64.nan
		self.v_wind_max = Float64.nan
		self.hel_stow_deploy = Float64.nan
		self.eta_prev = Float64.nan
		self.v_wind_prev = Float64.nan

	def __del__(owned self):

	def init(inout self) -> Int:
		self.n_hel = Int(self.value(P_n_hel))
		self.q_start = self.value(P_q_start) * 3600.0
		self.p_run = self.value(P_p_run) * 3600.0
		self.v_wind_max = self.value(P_v_wind_max)
		self.hel_stow_deploy = self.value(P_hel_stow_deploy)
		var rows: Int
		var cols: Int
		self.value(P_eta_map, &rows, &cols)
		var zen: Float64
		var azi: Float64
		var layer: Float64
		var zen0: Float64 = TCS_MATRIX_INDEX(self.var(P_eta_map), 0, 0)
		var azi0: Float64 = TCS_MATRIX_INDEX(self.var(P_eta_map), 0, 1)
		var layer0: Float64 = TCS_MATRIX_INDEX(self.var(P_eta_map), 0, 2)
		var nzen0: Int
		var nzen1: Int
		var nazi0: Int
		var nazi1: Int
		var nlayer0: Int
		var nlayer1: Int
		nzen1 = 1
		nazi1 = 1
		nlayer1 = 1
		nzen0 = 0
		nazi0 = 0
		nlayer0 = 0
		var size_error: Bool = False
		for i in range(rows):
			zen = TCS_MATRIX_INDEX(self.var(P_eta_map), i, 0)
			azi = TCS_MATRIX_INDEX(self.var(P_eta_map), i, 1)
			layer = TCS_MATRIX_INDEX(self.var(P_eta_map), i, 2)
			if layer != layer0:
				nlayer1 += 1
				layer0 = layer
				if nzen0 > 0 and nzen0 != nzen1:
					size_error = True
					break
				if nazi0 > 0 and nazi0 != nazi1:
					size_error = True
					break
				zen0 = zen
				azi0 = azi
				nzen0 = nzen1
				nzen1 = 1
				nazi0 = nazi1
				nazi1 = 1
				continue
			if azi != azi0:
				nazi1 += 1
				azi0 = azi
				if nzen0 > 0 and nzen0 != nzen1:
					size_error = True
					break
				nzen0 = nzen1
				nzen1 = 1
				continue
			if zen != zen0:
				nzen1 += 1
				zen0 = zen
		if size_error:
			self.message(TCS_ERROR, "The heliostat efficiency matrix is not properly dimensioned. Please ensure the number of zenith and azimuth values are consistent in all dimensions.")
			return -1
		self.n_zen = nzen1
		self.n_azi = nazi1
		self.n_layer = nlayer1
		if self.n_zen < 2 or self.n_azi < 2 or self.n_layer < 2:
			self.message(TCS_ERROR, "The field efficiency matrix contains insufficient data. Each dimension must have at least 2 levels.")
			return -1
		var eta_map: block_t[Float64] = block_t[Float64](self.n_zen * self.n_azi, 4, self.n_layer, 0.0)
		var k: Int = 0
		var kk: Int = 0
		for l in range(self.n_layer):
			for r in range(self.n_zen * self.n_azi):
				for c in range(4):
					eta_map.at(k, c, l) = TCS_MATRIX_INDEX(self.var(P_eta_map), kk, c)
				k += 1
				kk += 1
			k = 0
		if not self.field_efficiency_table.Set_3D_Lookup_Table(eta_map):
			self.message(TCS_ERROR, "Initialization of 2D interpolation class failed")
			return -1
		self.eta_prev = 0.0
		self.v_wind_prev = 0.0
		return 0

	def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
		var v_wind: Float64 = self.value(I_v_wind)
		var field_control: Float64 = self.value(I_field_control)
		if field_control > 1.0:
			field_control = 1.0
		if field_control < 0.0:
			field_control = 0.0
		var theta: Float64 = self.value(I_theta)
		if theta >= 90.0:
			field_control = 0.0
		var phi: Float64 = self.value(I_phi)
		var layer: Float64 = self.value(I_AOD)
		if phi <= 180.0:
			phi += 180.0
		else:
			phi -= 180.0
		var pparasi: Float64 = 0.0
		if (field_control > 1.e-4 and self.eta_prev < 1.e-4) or (field_control < 1.e-4 and self.eta_prev >= 1.e-4) or (field_control > 1.e-4 and v_wind >= self.v_wind_max) or (self.eta_prev > 1.e-4 and self.v_wind_prev >= self.v_wind_max and v_wind < self.v_wind_max):
			pparasi = Float64(self.n_hel) * self.q_start / (step / 3600.0)
		if v_wind < self.v_wind_max and self.v_wind_prev < self.v_wind_max:
			pparasi += Float64(self.n_hel) * self.p_run * field_control
		var eta_field: Float64 = self.field_efficiency_table.trilinear_3D_interp(theta, phi, layer)
		eta_field = min(max(eta_field, 0.0), 1.0)
		if theta >= 90.0 or (90.0 - theta) < max(self.hel_stow_deploy, 0.1):
			eta_field = 1.e-6
		if v_wind < self.v_wind_max:
			eta_field = max(eta_field * field_control, 1.e-6)
		else:
			eta_field = 1.e-6
		self.value(O_pparasi, pparasi / 3.6e6)
		self.value(O_eta_field, eta_field)
		return 0

	def converged(inout self, time: Float64) -> Int:
		self.eta_prev = self.value(O_eta_field)
		self.v_wind_prev = self.value(I_v_wind)
		return 0

TCS_IMPLEMENT_TYPE(Heliostat3DInterp, "Interpolated optical efficiency matrix - 3D", "Mike Wagner", 1, Heliostat3DInterp_variables, None, 1)
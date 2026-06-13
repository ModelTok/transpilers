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

from csp_solver_util import *
from csp_solver_core import *
from sort_method import quicksort
from interpolation_routines import GaussMarkov, Powvargram
from AutoPilot_API import simulation_info
from IOUtil import *
from sam_csp_util import *
from Heliostat import *
from lib_weatherfile import *

const az_scale: Float64 = 6.283125908
const zen_scale: Float64 = 1.570781477
const eff_scale: Float64 = 0.7

@value
struct C_pt_sf_perf_interp:
    var field_efficiency_table: GaussMarkov?
    var m_map_sol_pos: MatDoub
    var m_p_start: Float64                 # [kWe-hr] Heliostat startup energy
    var m_p_track: Float64                 # [kWe] Heliostat tracking power
    var m_hel_stow_deploy: Float64         # [rad] converted from [deg] in ms_params
    var m_v_wind_max: Float64              # [m/s]
    var m_n_flux_x: Int32                  # [-]
    var m_n_flux_y: Int32                  # [-]
    var m_is_field_tracking: Bool
    var m_is_field_tracking_prev: Bool
    var error_msg: String
    var m_ncall: Int32
    var mc_csp_messages: C_csp_messages
    var mf_callback: (simulation_info?, ref Pointer[None]) -> Bool
    var m_cdata: Pointer[None]
    var ms_params: S_params
    var ms_outputs: S_outputs

    # Inner structs
    @value
    struct RUN_TYPE:
        enum A:
            AUTO = 0
            USER_FIELD = 1
            USER_DATA = 2

    @value
    struct S_params:
        var m_eta_map_aod_format: Bool      # [-]
        var m_p_start: Float64              # [kWe-hr] Heliostat startup energy
        var m_p_track: Float64              # [kWe] Heliostat tracking power
        var m_hel_stow_deploy: Float64      # [deg] convert to [rad] in init()
        var m_v_wind_max: Float64           # [m/s] max wind speed
        var m_N_hel: Int32                  # [-]
        var m_n_flux_x: Int32               # [-]
        var m_n_flux_y: Int32               # [-]
        var m_eta_map: matrix_t[Float64]
        var m_flux_maps: matrix_t[Float64]
        var m_sf_adjust: matrix_t[Float64]   # array of length equal to number of time steps
        var m_land_area: Float64
        var m_A_sf: Float64                 # [m2]

        def __init__(inout self):
            self.m_n_flux_x = -1
            self.m_n_flux_y = -1
            self.m_N_hel = -1
            self.m_p_start = Float64.NAN
            self.m_p_track = Float64.NAN
            self.m_hel_stow_deploy = Float64.NAN
            self.m_v_wind_max = Float64.NAN
            self.m_land_area = Float64.NAN
            self.m_A_sf = Float64.NAN

    @value
    struct S_outputs:
        var m_q_dot_field_inc: Float64      # [MWt] Field incident thermal power (from the sun!)
        var m_flux_map_out: matrix_t[Float64]
        var m_pparasi: Float64              # [MWe]
        var m_eta_field: Float64            # [-]
        var m_sf_adjust_out: Float64

        def __init__(inout self):
            self.m_q_dot_field_inc = Float64.NAN
            self.m_pparasi = Float64.NAN
            self.m_eta_field = Float64.NAN
            self.m_sf_adjust_out = Float64.NAN

    def __init__(inout self):
        self.m_p_start = Float64.NAN
        self.m_p_track = Float64.NAN
        self.m_hel_stow_deploy = Float64.NAN
        self.m_v_wind_max = Float64.NAN
        self.m_is_field_tracking = False
        self.m_is_field_tracking_prev = False
        self.m_n_flux_x = -1
        self.m_n_flux_y = -1
        self.field_efficiency_table = None
        self.m_cdata = None
        self.mf_callback = None
        self.m_ncall = -1

    def __del__(owned self):
        if self.field_efficiency_table:
            del self.field_efficiency_table

    def rdist(inout self, p1: VectDoub, p2: VectDoub, dim: Int32 = 2) -> Float64:
        var d: Float64 = 0.0
        for i in range(dim):
            var rd = p1[i] - p2[i]
            d += rd * rd
        return sqrt(d)

    def init(inout self):
        var eta_map: matrix_t[Float64]
        var flux_maps: matrix_t[Float64]
        self.m_p_start = self.ms_params.m_p_start
        self.m_p_track = self.ms_params.m_p_track
        self.m_hel_stow_deploy = self.ms_params.m_hel_stow_deploy * CSP.pi / 180.0
        self.m_v_wind_max = self.ms_params.m_v_wind_max
        eta_map = self.ms_params.m_eta_map
        self.m_n_flux_x = self.ms_params.m_n_flux_x
        self.m_n_flux_y = self.ms_params.m_n_flux_y
        var nfluxpos: Int32 = eta_map.nrows()
        var nfposdim: Int32 = 2
        flux_maps = self.ms_params.m_flux_maps
        var nfluxmap: Int32 = flux_maps.nrows()
        var nfluxcol: Int32 = flux_maps.ncols()
        if nfluxmap % nfluxpos != 0:
            self.error_msg = util.format("The number of flux maps provided does not match the number of flux map sun positions provided. Please ensure that the dimensionality of each flux map is consistent and that one sun position is provided for each flux map. (Sun pos. = %d, mismatch lines = %d)", nfluxpos, nfluxmap % nfluxpos)
            raise C_csp_exception(self.error_msg, "heliostat field initialization")
        self.m_map_sol_pos.resize(nfluxpos, VectDoub(nfposdim))
        for i in range(nfluxpos):
            for j in range(nfposdim):
                self.m_map_sol_pos[i][j] = eta_map(i, j) * CSP.pi / 180.0
        var sunpos: MatDoub
        var effs: List[Float64]
        var vis: List[Float64]
        if not self.ms_params.m_eta_map_aod_format:
            var nrows: Int32 = self.ms_params.m_eta_map.nrows()
            var ncols: Int32 = self.ms_params.m_eta_map.ncols()
            if ncols != 3:
                self.error_msg = util.format("The heliostat field efficiency file is not formatted correctly. Type expects 3 columns (zenith angle, azimuth angle, efficiency value) and instead has %d cols.", ncols)
                raise C_csp_exception(self.error_msg, "heliostat field initialization")
            sunpos.resize(nrows, VectDoub(2))
            effs.resize(nrows)
            for i in range(nrows):
                sunpos[i][0] = eta_map(i, 0) / az_scale * CSP.pi / 180.0
                sunpos[i][1] = eta_map(i, 1) / zen_scale * CSP.pi / 180.0
                effs[i] = eta_map(i, 2) / eff_scale
        else:
            var nrows: Int32 = self.ms_params.m_eta_map.nrows() - 1
            var ncols: Int32 = self.ms_params.m_eta_map.ncols()
            var nvis: Int32 = ncols - 2
            sunpos.resize(nrows * nvis, VectDoub(3))
            effs.resize(nrows * nvis)
            for j in range(nvis):
                var vis_val: Float64 = eta_map(0, j + 2)
                for i in range(nrows):
                    sunpos[i + nrows * j][0] = eta_map(i + 1, 0) / az_scale * CSP.pi / 180.0
                    sunpos[i + nrows * j][1] = eta_map(i + 1, 1) / zen_scale * CSP.pi / 180.0
                    sunpos[i + nrows * j][2] = vis_val
                    effs[i + nrows * j] = eta_map(i + 1, j + 2) / eff_scale
            var eta_temp: matrix_t[Float64](nrows, ncols)
            self.ms_params.m_eta_map.resize(nrows, ncols)
            for i in range(nrows):
                for j in range(ncols):
                    self.ms_params.m_eta_map[i, j] = eta_map(i + 1, j)
        self.ms_outputs.m_flux_map_out.resize_fill(self.m_n_flux_y, self.m_n_flux_x, 0.0)
        # --------------------------------------------------------------
        # Create the regression fit on the efficiency map
        # --------------------------------------------------------------
        var interp_nug: Float64 = 0.0
        var interp_beta: Float64 = 1.99
        var vgram: Powvargram = Powvargram(sunpos, effs, interp_beta, interp_nug)
        self.field_efficiency_table = GaussMarkov(sunpos, effs, vgram)
        var err_fit: Float64 = 0.0
        var npoints: Int32 = Int32(sunpos.size())
        for i in range(npoints):
            var zref: Float64 = effs[i]
            var zfit: Float64 = self.field_efficiency_table.interp(sunpos[i])
            var dz: Float64 = zref - zfit
            err_fit += dz * dz
        err_fit = sqrt(err_fit)
        if err_fit > 0.01:
            self.error_msg = util.format("The heliostat field interpolation function fit is poor! (err_fit=%f RMS)", err_fit)
            self.mc_csp_messages.add_message(C_csp_messages.WARNING, self.error_msg)
        self.m_ncall = -1

    def call(inout self, weather: C_csp_weatherreader.S_outputs, field_control_in: Float64, sim_info: C_csp_solver_sim_info):
        self.m_ncall += 1
        var time: Float64 = sim_info.ms_ts.m_time
        var step: Float64 = sim_info.ms_ts.m_step
        var sf_adjust: Float64 = 1.0
        if self.ms_params.m_sf_adjust.ncells() >= 8760:
            var full_step: Float64 = 8760.0 * 3600.0 / Float64(self.ms_params.m_sf_adjust.ncells())
            sf_adjust = self.ms_params.m_sf_adjust[Int32(time / full_step) - 1]
        var v_wind: Float64 = weather.m_wspd             # [m/s]
        var field_control: Float64 = field_control_in      # Control Parameter ( range from 0 to 1; 0=off, 1=all on)
        if field_control_in > 1.0:
            field_control = 1.0
        if field_control_in < 0.0:
            field_control = 0.0
        var solzen: Float64 = weather.m_solzen * CSP.pi / 180.0
        if solzen > (CSP.pi / 2 - 0.001 - self.m_hel_stow_deploy) or v_wind > self.m_v_wind_max or field_control < 1e-4:
            self.m_is_field_tracking = False
            field_control = 0.0
        else:
            self.m_is_field_tracking = True
        var solaz: Float64 = weather.m_solazi * CSP.pi / 180.0
        self.ms_outputs.m_flux_map_out.fill(0.0)
        var pparasi: Float64 = 0.0
        if (self.m_is_field_tracking and not self.m_is_field_tracking_prev) or (not self.m_is_field_tracking and self.m_is_field_tracking_prev):
            pparasi = Float64(self.ms_params.m_N_hel) * self.m_p_start / (step / 3600.0)   # [kWe-hr]/[hr] = kWe
        if self.m_is_field_tracking:
            pparasi += Float64(self.ms_params.m_N_hel) * self.m_p_track * field_control      # [kWe]
        var eta_field: Float64 = 0.0
        if not self.m_is_field_tracking:
            eta_field = 1e-6
        else:
            var sunpos: VectDoub
            sunpos.append(solaz / az_scale)
            sunpos.append(solzen / zen_scale)
            if self.ms_params.m_eta_map_aod_format:
                if weather.m_aod != weather.m_aod:
                    sunpos.append(0.0)
                else:
                    sunpos.append(weather.m_aod)
            eta_field = self.field_efficiency_table.interp(sunpos) * eff_scale
            eta_field = fmin(fmax(eta_field, 0.0), 1.0) * field_control * sf_adjust   # Ensure physical behavior
            var pos_now: VectDoub = sunpos
            var distances: List[Float64] = List[Float64]()
            var indices: List[Int32] = List[Int32]()
            for i in range(self.m_map_sol_pos.size()):
                distances.append(self.rdist(pos_now, self.m_map_sol_pos[i]))
                indices.append(i)
            quicksort[Float64, Int32](distances, indices)
            var avepoints: Float64 = 0.0
            var npt: Int32 = 6
            for i in range(npt):
                avepoints += distances[i]
            avepoints *= 1.0 / Float64(npt)
            var weights: VectDoub = VectDoub(npt)
            var normalizer: Float64 = 0.0
            for i in range(npt):
                var w: Float64 = exp(-pow(distances[i] / avepoints, 2))
                weights[i] = w
                normalizer += w
            for i in range(npt):
                weights[i] *= 1.0 / normalizer
            for k in range(npt):
                var imap: Int32 = indices[k]
                for j in range(self.m_n_flux_y):
                    for i in range(self.m_n_flux_x):
                        self.ms_outputs.m_flux_map_out(j, i) += self.ms_params.m_flux_maps(imap * self.m_n_flux_y + j, i) * weights[k]
        self.ms_outputs.m_q_dot_field_inc = weather.m_beam * self.ms_params.m_A_sf * 1e-6   # [MWt]
        self.ms_outputs.m_pparasi = pparasi / 1e3             # [MW], convert from kJ/hr: Parasitic power for tracking
        self.ms_outputs.m_eta_field = eta_field               # [-], field efficiency
        self.ms_outputs.m_sf_adjust_out = sf_adjust

    def off(inout self, sim_info: C_csp_solver_sim_info):
        self.m_ncall += 1
        var step: Float64 = sim_info.ms_ts.m_step
        self.m_is_field_tracking = False
        var pparasi: Float64 = 0.0
        if self.m_is_field_tracking_prev:
            pparasi = Float64(self.ms_params.m_N_hel) * self.m_p_start / (step / 3600.0)   # [kWe-hr]/[hr] = kWe
        self.ms_outputs.m_pparasi = pparasi / 1e3            # [MW], convert from kJ/hr: Parasitic power for tracking
        self.ms_outputs.m_flux_map_out.fill(0.0)
        self.ms_outputs.m_q_dot_field_inc = 0.0              # [MWt]
        self.ms_outputs.m_eta_field = 0.0                    # [-], field efficiency

    def converged(inout self):
        self.m_is_field_tracking_prev = self.m_is_field_tracking   # [-]
        self.m_ncall = -1
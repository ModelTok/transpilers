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

from csp_solver_util import *
from csp_solver_core import *
from sort_method import *
from interpolation_routines import *
from AutoPilot_API import *
from IOUtil import *
from sam_csp_util import *
from Heliostat import *
from lib_weatherfile import *

# define constants
var az_scale = 6.283125908
var zen_scale = 1.570781477
var eff_scale = 0.7

struct C_pt_heliostatfield:
    var field_efficiency_table: Pointer[GaussMarkov] = Pointer[GaussMarkov]()
    var m_flux_positions: MatDoub = MatDoub()
    var m_p_start: Float64 = Float64.NaN
    var m_p_track: Float64 = Float64.NaN
    var m_hel_stow_deploy: Float64 = Float64.NaN
    var m_v_wind_max: Float64 = Float64.NaN
    var m_n_flux_x: Int = -1
    var m_n_flux_y: Int = -1
    var m_N_hel: Int = -1
    var m_eta_prev: Float64 = Float64.NaN
    var m_v_wind_prev: Float64 = Float64.NaN
    var m_v_wind_current: Float64 = Float64.NaN
    var error_msg: String = ""
    var mc_csp_messages: C_csp_messages = C_csp_messages()
    var mf_callback: fn(siminfo: Pointer[simulation_info], data: Pointer[Byte]) -> Bool = None
    var m_cdata: Pointer[Byte] = Pointer[Byte]()
    var ms_params: S_params = S_params()
    var ms_outputs: S_outputs = S_outputs()
    var m_ncall: Int = -1

    struct RUN_TYPE:
        enum A:
            AUTO = 0
            USER_FIELD = 1
            USER_DATA = 2

    struct S_params:
        var m_eta_map_aod_format: Bool = False
        var m_run_type: Int = -1
        var m_helio_width: Float64 = Float64.NaN
        var m_helio_height: Float64 = Float64.NaN
        var m_helio_optical_error: Float64 = Float64.NaN
        var m_helio_active_fraction: Float64 = Float64.NaN
        var m_dens_mirror: Float64 = Float64.NaN
        var m_helio_reflectance: Float64 = Float64.NaN
        var m_rec_absorptance: Float64 = Float64.NaN
        var m_rec_height: Float64 = Float64.NaN
        var m_rec_aspect: Float64 = Float64.NaN
        var m_rec_hl_perm2: Float64 = Float64.NaN
        var m_q_design: Float64 = Float64.NaN
        var m_h_tower: Float64 = Float64.NaN
        var m_weather_file: String = ""
        var m_land_bound_type: Int = -1
        var m_land_max: Float64 = Float64.NaN
        var m_land_min: Float64 = Float64.NaN
        var m_land_bound_table: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_land_bound_list: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_p_start: Float64 = Float64.NaN
        var m_p_track: Float64 = Float64.NaN
        var m_hel_stow_deploy: Float64 = Float64.NaN
        var m_v_wind_max: Float64 = Float64.NaN
        var m_interp_nug: Float64 = Float64.NaN
        var m_interp_beta: Float64 = Float64.NaN
        var m_n_flux_x: Int = -1
        var m_n_flux_y: Int = -1
        var m_helio_positions: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_helio_aim_points: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_eta_map: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_flux_positions: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_flux_maps: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_sf_adjust: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_c_atm_0: Float64 = Float64.NaN
        var m_c_atm_1: Float64 = Float64.NaN
        var m_c_atm_2: Float64 = Float64.NaN
        var m_c_atm_3: Float64 = Float64.NaN
        var m_n_facet_x: Int = -1
        var m_n_facet_y: Int = -1
        var m_cant_type: Int = -1
        var m_focus_type: Int = -1
        var m_n_flux_days: Int = -1
        var m_delta_flux_hrs: Int = -1
        var m_dni_des: Float64 = Float64.NaN
        var m_land_area: Float64 = Float64.NaN
        var m_A_sf: Float64 = Float64.NaN

        def __init__(inout self):
            self.m_run_type = -1
            self.m_land_bound_type = -1
            self.m_n_flux_x = -1
            self.m_n_flux_y = -1
            self.m_n_facet_x = -1
            self.m_n_facet_y = -1
            self.m_cant_type = -1
            self.m_focus_type = -1
            self.m_n_flux_days = -1
            self.m_delta_flux_hrs = -1
            self.m_helio_width = Float64.NaN
            self.m_helio_height = Float64.NaN
            self.m_helio_optical_error = Float64.NaN
            self.m_helio_active_fraction = Float64.NaN
            self.m_dens_mirror = Float64.NaN
            self.m_helio_reflectance = Float64.NaN
            self.m_rec_absorptance = Float64.NaN
            self.m_rec_height = Float64.NaN
            self.m_rec_aspect = Float64.NaN
            self.m_rec_hl_perm2 = Float64.NaN
            self.m_q_design = Float64.NaN
            self.m_h_tower = Float64.NaN
            self.m_land_max = Float64.NaN
            self.m_land_min = Float64.NaN
            self.m_p_start = Float64.NaN
            self.m_p_track = Float64.NaN
            self.m_hel_stow_deploy = Float64.NaN
            self.m_v_wind_max = Float64.NaN
            self.m_interp_nug = Float64.NaN
            self.m_interp_beta = Float64.NaN
            self.m_c_atm_0 = Float64.NaN
            self.m_c_atm_1 = Float64.NaN
            self.m_c_atm_2 = Float64.NaN
            self.m_c_atm_3 = Float64.NaN
            self.m_dni_des = Float64.NaN
            self.m_land_area = Float64.NaN
            self.m_A_sf = Float64.NaN
            self.m_weather_file = ""

    struct S_outputs:
        var m_q_dot_field_inc: Float64 = Float64.NaN
        var m_flux_map_out: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var m_pparasi: Float64 = Float64.NaN
        var m_eta_field: Float64 = Float64.NaN
        var m_sf_adjust_out: Float64 = Float64.NaN

        def __init__(inout self):
            self.m_q_dot_field_inc = Float64.NaN
            self.m_pparasi = Float64.NaN
            self.m_eta_field = Float64.NaN
            self.m_sf_adjust_out = Float64.NaN

    def __init__(inout self):
        self.m_p_start = Float64.NaN
        self.m_p_track = Float64.NaN
        self.m_hel_stow_deploy = Float64.NaN
        self.m_v_wind_max = Float64.NaN
        self.m_eta_prev = Float64.NaN
        self.m_v_wind_prev = Float64.NaN
        self.m_v_wind_current = Float64.NaN
        self.m_n_flux_x = -1
        self.m_n_flux_y = -1
        self.m_N_hel = -1
        self.field_efficiency_table = Pointer[GaussMarkov]()
        self.m_cdata = Pointer[Byte]()
        self.mf_callback = None
        self.m_ncall = -1

    def __del__(owned self):
        if self.field_efficiency_table:
            del self.field_efficiency_table

    def rdist(self, p1: Pointer[VectDoub], p2: Pointer[VectDoub], dim: Int = 2) -> Float64:
        var d: Float64 = 0.0
        for i in range(dim):
            var rd: Float64 = p1[0][i] - p2[0][i]
            d += rd * rd
        return sqrt(d)

    def init(inout self):
        var nrows1: Int = 0
        var ncols1: Int = 0
        var nrows2: Int = 0
        var nrows4: Int = 0
        var ncols4: Int = 0
        var nrows5: Int = 0
        var ncols5: Int = 0
        var nfluxpos: Int = 0
        var nfposdim: Int = 0
        var nfluxmap: Int = 0
        var nfluxcol: Int = 0
        var weather_file: String = ""
        var helio_width: Float64 = Float64.NaN
        var helio_height: Float64 = Float64.NaN
        var helio_optical_error: Float64 = Float64.NaN
        var helio_active_fraction: Float64 = Float64.NaN
        var dens_mirror: Float64 = Float64.NaN
        var helio_reflectance: Float64 = Float64.NaN
        var rec_absorptance: Float64 = Float64.NaN
        var rec_height: Float64 = Float64.NaN
        var rec_aspect: Float64 = Float64.NaN
        var rec_hl_perm2: Float64 = Float64.NaN
        var q_design: Float64 = Float64.NaN
        var h_tower: Float64 = Float64.NaN
        var land_bound_type: Int = 0
        var land_max: Float64 = Float64.NaN
        var land_min: Float64 = Float64.NaN
        var interp_nug: Float64 = Float64.NaN
        var interp_beta: Float64 = Float64.NaN
        var c_atm_0: Float64 = Float64.NaN
        var c_atm_1: Float64 = Float64.NaN
        var c_atm_2: Float64 = Float64.NaN
        var c_atm_3: Float64 = Float64.NaN
        var n_facet_x: Int = 0
        var n_facet_y: Int = 0
        var cant_type: Int = 0
        var focus_type: Int = 0
        var n_flux_days: Int = 0
        var delta_flux_hrs: Int = 0
        var dni_des: Float64 = Float64.NaN
        var helio_positions: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var eta_map: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var flux_maps: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var land_bound_table: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var land_bound_list: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var helio_aim_points: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var flux_positions: util.matrix_t[Float64] = util.matrix_t[Float64]()
        var pos_dim: Int = 0
        var run_type: Int = self.ms_params.m_run_type

        if run_type == RUN_TYPE.A.AUTO or run_type == RUN_TYPE.A.USER_FIELD:
            helio_width = self.ms_params.m_helio_width
            helio_height = self.ms_params.m_helio_height
            helio_optical_error = self.ms_params.m_helio_optical_error
            helio_active_fraction = self.ms_params.m_helio_active_fraction
            dens_mirror = self.ms_params.m_dens_mirror
            helio_reflectance = self.ms_params.m_helio_reflectance
            rec_absorptance = self.ms_params.m_rec_absorptance
            rec_height = self.ms_params.m_rec_height
            rec_aspect = self.ms_params.m_rec_aspect
            rec_hl_perm2 = self.ms_params.m_rec_hl_perm2
            q_design = self.ms_params.m_q_design
            h_tower = self.ms_params.m_h_tower
            weather_file = self.ms_params.m_weather_file
            land_bound_type = self.ms_params.m_land_bound_type
            land_max = self.ms_params.m_land_max
            land_min = self.ms_params.m_land_min
            land_bound_table = self.ms_params.m_land_bound_table
            nrows1 = land_bound_table.nrows()
            ncols1 = land_bound_table.ncols()
            land_bound_list = self.ms_params.m_land_bound_list
            nrows2 = land_bound_list.nrows()
            self.m_p_start = self.ms_params.m_p_start
            self.m_p_track = self.ms_params.m_p_track
            self.m_hel_stow_deploy = self.ms_params.m_hel_stow_deploy * CSP.pi / 180.0
            self.m_v_wind_max = self.ms_params.m_v_wind_max
            interp_nug = self.ms_params.m_interp_nug
            interp_beta = self.ms_params.m_interp_beta
            self.m_n_flux_x = self.ms_params.m_n_flux_x
            self.m_n_flux_y = self.ms_params.m_n_flux_y
            c_atm_0 = self.ms_params.m_c_atm_0
            c_atm_1 = self.ms_params.m_c_atm_1
            c_atm_2 = self.ms_params.m_c_atm_2
            c_atm_3 = self.ms_params.m_c_atm_3
            n_facet_x = self.ms_params.m_n_facet_x
            n_facet_y = self.ms_params.m_n_facet_y
            cant_type = self.ms_params.m_cant_type
            focus_type = self.ms_params.m_focus_type
            n_flux_days = self.ms_params.m_n_flux_days
            delta_flux_hrs = self.ms_params.m_delta_flux_hrs
            dni_des = self.ms_params.m_dni_des
            pos_dim = 2
            if run_type != RUN_TYPE.A.USER_FIELD:
                break_helper()
            helio_positions = self.ms_params.m_helio_positions
            self.m_N_hel = helio_positions.nrows()
            pos_dim = helio_positions.ncols()
            helio_aim_points = self.ms_params.m_helio_aim_points
            nrows4 = helio_aim_points.nrows()
            ncols4 = helio_aim_points.ncols()
            # end if
        elif run_type == RUN_TYPE.A.USER_DATA:
            h_tower = self.ms_params.m_h_tower
            land_bound_type = self.ms_params.m_land_bound_type
            land_max = self.ms_params.m_land_max
            land_min = self.ms_params.m_land_min
            land_bound_table = self.ms_params.m_land_bound_table
            nrows1 = land_bound_table.nrows()
            ncols1 = land_bound_table.ncols()
            land_bound_list = self.ms_params.m_land_bound_list
            nrows2 = land_bound_list.nrows()
            self.m_p_start = self.ms_params.m_p_start
            self.m_p_track = self.ms_params.m_p_track
            self.m_hel_stow_deploy = self.ms_params.m_hel_stow_deploy * CSP.pi / 180.0
            self.m_v_wind_max = self.ms_params.m_v_wind_max
            interp_nug = self.ms_params.m_interp_nug
            interp_beta = self.ms_params.m_interp_beta
            helio_positions = self.ms_params.m_helio_positions
            self.m_N_hel = helio_positions.nrows()
            pos_dim = helio_positions.ncols()
            helio_aim_points = self.ms_params.m_helio_aim_points
            nrows4 = helio_aim_points.nrows()
            ncols4 = helio_aim_points.ncols()
            eta_map = self.ms_params.m_eta_map
            nrows5 = eta_map.nrows()
            ncols5 = eta_map.ncols()
            self.m_n_flux_x = self.ms_params.m_n_flux_x
            self.m_n_flux_y = self.ms_params.m_n_flux_y
            flux_positions = self.ms_params.m_flux_positions
            nfluxpos = flux_positions.nrows()
            nfposdim = flux_positions.ncols()
            flux_maps = self.ms_params.m_flux_maps
            nfluxmap = flux_maps.nrows()
            nfluxcol = flux_maps.ncols()
            c_atm_0 = self.ms_params.m_c_atm_0
            c_atm_1 = self.ms_params.m_c_atm_1
            c_atm_2 = self.ms_params.m_c_atm_2
            c_atm_3 = self.ms_params.m_c_atm_3
            n_facet_x = self.ms_params.m_n_facet_x
            n_facet_y = self.ms_params.m_n_facet_y
            cant_type = self.ms_params.m_cant_type
            focus_type = self.ms_params.m_focus_type
            n_flux_days = self.ms_params.m_n_flux_days
            delta_flux_hrs = self.ms_params.m_delta_flux_hrs
            dni_des = self.ms_params.m_dni_des
            if nfluxmap % nfluxpos != 0:
                self.error_msg = util.format("The number of flux maps provided does not match the number of flux map sun positions provided. Please " + \
                    "ensure that the dimensionality of each flux map is consistent and that one sun position is provided for " + \
                    "each flux map. (Sun pos. = %d, mismatch lines = %d)", nfluxpos, nfluxmap % nfluxpos)
                raise C_csp_exception(self.error_msg, "heliostat field initialization")
            self.m_flux_positions.resize(nfluxpos, VectDoub(nfposdim))
            for i in range(nfluxpos):
                for j in range(nfposdim):
                    self.m_flux_positions[i][j] = flux_positions[i, j]
            # end if
        # end switch

        var sunpos: MatDoub = MatDoub()
        var effs: vector[Float64] = vector[Float64]()
        var vis: vector[Float64] = vector[Float64]()

        if run_type == RUN_TYPE.A.AUTO or run_type == RUN_TYPE.A.USER_FIELD:
            var sapi: AutoPilot_S = AutoPilot_S()
            var opt: sp_optimize = sp_optimize()
            var layout: sp_layout = sp_layout()
            var V: var_map = var_map()
            var hf: var_heliostat = V.hels.front()
            hf.width.val = helio_width
            hf.height.val = helio_height
            hf.err_azimuth.val = 0.0
            hf.err_elevation.val = 0.0
            hf.err_reflect_x.val = 0.0
            hf.err_reflect_y.val = 0.0
            hf.err_surface_x.val = helio_optical_error
            hf.err_surface_y.val = helio_optical_error
            hf.reflect_ratio.val = helio_active_fraction * dens_mirror
            hf.reflectivity.val = helio_reflectance
            hf.soiling.val = 1.0

            var cmap: Pointer[Int] = Pointer[Int](5)
            cmap[0] = var_heliostat.CANT_METHOD.NO_CANTING
            cmap[1] = var_heliostat.CANT_METHOD.ONAXIS_AT_SLANT
            cmap[2] = var_heliostat.CANT_METHOD.OFFAXIS_DAY_AND_HOUR
            cmap[3] = var_heliostat.CANT_METHOD.OFFAXIS_DAY_AND_HOUR
            cmap[4] = var_heliostat.CANT_METHOD.OFFAXIS_DAY_AND_HOUR
            hf.cant_method.combo_select_by_mapval(cmap[cant_type])

            if cant_type == AutoPilot.API_CANT_TYPE.NONE or cant_type == AutoPilot.API_CANT_TYPE.ON_AXIS:

            elif cant_type == AutoPilot.API_CANT_TYPE.EQUINOX:
                hf.cant_day.val = 81
                hf.cant_hour.val = 12
            elif cant_type == AutoPilot.API_CANT_TYPE.SOLSTICE_SUMMER:
                hf.cant_day.val = 172
                hf.cant_hour.val = 12
            elif cant_type == AutoPilot.API_CANT_TYPE.SOLSTICE_WINTER:
                hf.cant_day.val = 355
                hf.cant_hour.val = 12
            else:
                var msg: String = "Invalid Cant Type specified in AutoPILOT API. Method must be one of: \n" + \
                    "NONE(0), ON_AXIS(1), EQUINOX(2), SOLSTICE_SUMMER(3), SOLSTICE_WINTER(4).\n" + \
                    "Method specified is: " + cant_type.String() + "."
                raise spexception(msg)
            # end switch

            hf.focus_method.combo_select_by_choice_index(focus_type)

            var rf: var_receiver = V.recs.front()
            rf.absorptance.val = rec_absorptance
            rf.rec_height.val = rec_height
            rf.rec_width.val = rec_height / rec_aspect
            rf.rec_diameter.val = rec_height / rec_aspect
            rf.therm_loss_base.val = rec_hl_perm2
            V.sf.q_des.val = q_design
            V.sf.dni_des.val = dni_des
            V.land.is_bounds_scaled.val = True
            V.land.is_bounds_fixed.val = False
            V.land.is_bounds_array.val = False
            V.land.max_scaled_rad.val = land_max
            V.land.min_scaled_rad.val = land_min
            V.sf.tht.val = h_tower

            var wffile: String = weather_file
            if wffile == "":
                self.mc_csp_messages.add_message(C_csp_messages.WARNING, "solarpilot: could not open weather file or invalid weather file format")
            var wfile: weatherfile = weatherfile(wffile)
            if not wfile.ok() or wfile.type() == weatherfile.INVALID:
                self.mc_csp_messages.add_message(C_csp_messages.WARNING, "solarpilot: could not open weather file or invalid weather file format")
            var hdr: weather_header = weather_header()
            wfile.header(&hdr)
            V.amb.latitude.val = hdr.lat
            V.amb.longitude.val = hdr.lon
            V.amb.time_zone.val = hdr.tz
            V.amb.atm_model.combo_select_by_mapval(var_ambient.ATM_MODEL.USERDEFINED)
            V.amb.atm_coefs.val[var_ambient.ATM_MODEL.USERDEFINED, 0] = c_atm_0
            V.amb.atm_coefs.val[var_ambient.ATM_MODEL.USERDEFINED, 1] = c_atm_1
            V.amb.atm_coefs.val[var_ambient.ATM_MODEL.USERDEFINED, 2] = c_atm_2
            V.amb.atm_coefs.val[var_ambient.ATM_MODEL.USERDEFINED, 3] = c_atm_3
            V.recs.front().peak_flux.val = 1000.0
            V.opt.max_step.val = 0.06
            V.opt.max_iter.val = 200
            V.opt.converge_tol.val = 0.001
            V.opt.algorithm.combo_select_by_mapval(1)
            V.opt.flux_penalty.val = 0.25

            if run_type == RUN_TYPE.A.AUTO:
                V.recs.front().peak_flux.val = 1000.0
                V.opt.max_step.val = 0.06
                V.opt.max_iter.val = 200
                V.opt.converge_tol.val = 0.001
                V.opt.algorithm.combo_select_by_mapval(1)
                V.opt.flux_penalty.val = 0.25
                # Generate the heliostat field layout
                var wfdata: vector[String] = vector[String]()
                wfdata.reserve(8760)
                for i in range(8760):
                    var rec: weather_record = weather_record()
                    if not wfile.read(&rec):
                        self.error_msg = "solarpilot: could not read data line " + util.to_string(i+1) + " of 8760 in weather file"
                        self.mc_csp_messages.add_message(C_csp_messages.WARNING, self.error_msg)
                    self.error_msg = util.format("%d,%d,%d,%.2lf,%.1lf,%.1lf,%.1lf", rec.day, rec.hour, rec.month, rec.dn, rec.tdry, rec.pres / 1000.0, rec.wspd)
                    wfdata.push_back(self.error_msg)
                # end for
                if self.mf_callback and self.m_cdata:
                    sapi.SetSummaryCallback(self.mf_callback, self.m_cdata)
                sapi.SetSummaryCallbackStatus(False)
                sapi.GenerateDesignPointSimulations(V, wfdata)
                sapi.Setup(V)
                sapi.CreateLayout(layout)
                self.m_N_hel = Int(layout.heliostat_positions.size())
                var msg: String = "Auto-generated field: Number of heliostats " + util.to_string(self.m_N_hel)
                self.mc_csp_messages.add_message(C_csp_messages.NOTICE, msg)
                self.ms_params.m_helio_positions.resize(self.m_N_hel, pos_dim)
                for i in range(self.m_N_hel):
                    self.ms_params.m_helio_positions[i, 0] = layout.heliostat_positions[i].location.x
                    self.ms_params.m_helio_positions[i, 1] = layout.heliostat_positions[i].location.y
                    if pos_dim == 3:
                        self.ms_params.m_helio_positions[i, 2] = layout.heliostat_positions[i].location.z
                sapi.SetDetailCallbackStatus(False)
            else:
                # Load user-provided positions
                var format: String = "0,%f,%f,%f,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL;"
                V.sf.layout_data.val.clear()
                var row: String = ""
                for i in range(self.m_N_hel):
                    row = String.from_format(format, helio_positions[i, 0], helio_positions[i, 1], (helio_positions[i, 2] if pos_dim == 3 else 0.0))
                    V.sf.layout_data.val.append(row)
                V.sf.temp_which.set_from_string("Template 1")
                sapi.Setup(V)
            # end if

            self.ms_params.m_land_area = V.land.land_area.Val()
            if not self.mf_callback or not self.m_cdata:
                sapi.SetSummaryCallbackStatus(False)
            else:
                sapi.SetSummaryCallbackStatus(True)
                sapi.SetSummaryCallback(self.mf_callback, self.m_cdata)

            var fluxtab: sp_flux_table = sp_flux_table()
            fluxtab.is_user_spacing = True
            fluxtab.n_flux_days = n_flux_days
            fluxtab.delta_flux_hrs = delta_flux_hrs
            if self.m_n_flux_y == 1:
                V.flux.aim_method.combo_select_by_mapval(var_fluxsim.AIM_METHOD.SIMPLE_AIM_POINTS)
            if not sapi.CalculateFluxMaps(fluxtab, self.m_n_flux_x, self.m_n_flux_y, True):
                raise C_csp_exception("Simulation cancelled during fluxmap preparation", "heliostat field initialization")
            # end if

            sunpos.clear()
            effs.clear()
            var npos: Int = Int(fluxtab.azimuths.size())
            sunpos.reserve(npos)
            effs.reserve(npos)
            self.ms_params.m_eta_map.resize_fill(npos, 3, 0.0)
            self.m_flux_positions.resize(npos, VectDoub(2))
            for i in range(npos):
                sunpos.push_back(vector[Float64](2, 0.0))
                sunpos.back()[0] = fluxtab.azimuths[i] / az_scale
                sunpos.back()[1] = fluxtab.zeniths[i] / zen_scale
                effs.push_back(fluxtab.efficiency[i] / eff_scale)
                self.m_flux_positions[i][0] = fluxtab.azimuths[i]
                self.ms_params.m_eta_map[i, 0] = self.m_flux_positions[i][0] * 180.0 / CSP.pi
                self.m_flux_positions[i][1] = fluxtab.zeniths[i]
                self.ms_params.m_eta_map[i, 1] = self.m_flux_positions[i][1] * 180.0 / CSP.pi
                self.ms_params.m_eta_map[i, 2] = fluxtab.efficiency[i]
            # end for

            self.ms_params.m_flux_maps.resize_fill(self.m_n_flux_y * npos, self.m_n_flux_x, 0.0)
            var f: block_t[Float64] = fluxtab.flux_surfaces.front().flux_data
            var nfl: Int = f.nlayers()
            for i in range(nfl):
                for j in range(self.m_n_flux_y):
                    for k in range(self.m_n_flux_x):
                        self.ms_params.m_flux_maps[i * self.m_n_flux_y + j, k] = f[j, k, i]
            # end for
        elif run_type == RUN_TYPE.A.USER_DATA:
            if not self.ms_params.m_eta_map_aod_format:
                var nrows: Int = self.ms_params.m_eta_map.nrows()
                var ncols: Int = self.ms_params.m_eta_map.ncols()
                if ncols != 3:
                    self.error_msg = util.format("The heliostat field efficiency file is not formatted correctly. Type expects 3 columns" +
                        " (zenith angle, azimuth angle, efficiency value) and instead has %d cols.", ncols)
                    raise C_csp_exception(self.error_msg, "heliostat field initialization")
                sunpos.resize(nrows, VectDoub(2))
                effs.resize(nrows)
                for i in range(nrows):
                    sunpos[i][0] = eta_map[i, 0] / az_scale * CSP.pi / 180.0
                    sunpos[i][1] = eta_map[i, 1] / zen_scale * CSP.pi / 180.0
                    effs[i] = eta_map[i, 2] / eff_scale
            else:
                var nrows: Int = self.ms_params.m_eta_map.nrows() - 1
                var ncols: Int = self.ms_params.m_eta_map.ncols()
                var nvis: Int = ncols - 2
                sunpos.resize(nrows * nvis, VectDoub(3))
                effs.resize(nrows * nvis)
                for j in range(nvis):
                    var vis: Float64 = eta_map[0, j+2]
                    for i in range(nrows):
                        sunpos[i + nrows*j][0] = eta_map[i+1, 0] / az_scale * CSP.pi / 180.0
                        sunpos[i + nrows*j][1] = eta_map[i+1, 1] / zen_scale * CSP.pi / 180.0
                        sunpos[i + nrows*j][2] = vis
                        effs[i + nrows*j] = eta_map[i+1, j+2] / eff_scale
                var eta_temp: util.matrix_t[Float64] = util.matrix_t[Float64](nrows, ncols)
                self.ms_params.m_eta_map.resize(nrows, ncols)
                for i in range(nrows):
                    for j in range(ncols):
                        self.ms_params.m_eta_map[i, j] = eta_map[i+1, j]
            # end if
        # end switch

        self.ms_outputs.m_flux_map_out.resize_fill(self.m_n_flux_y, self.m_n_flux_x, 0.0)
        var nflux: Int = Int(self.m_flux_positions.size())
        self.ms_params.m_flux_positions.resize_fill(nflux, 2, 0.0)
        for i in range(nflux):
            self.ms_params.m_flux_positions[i, 0] = self.m_flux_positions[i][0]
            self.ms_params.m_flux_positions[i, 1] = self.m_flux_positions[i][1]
        # end for

        # ------------------------------------------------------------------------------
        # Create the regression fit on the efficiency map
        # ------------------------------------------------------------------------------
        interp_nug = self.ms_params.m_interp_nug
        interp_beta = self.ms_params.m_interp_beta
        var vgram: Powvargram = Powvargram(sunpos, effs, interp_beta, interp_nug)
        self.field_efficiency_table = Pointer[GaussMarkov](GaussMarkov(sunpos, effs, vgram))
        var err_fit: Float64 = 0.0
        var npoints: Int = Int(sunpos.size())
        for i in range(npoints):
            var zref: Float64 = effs[i]
            var zfit: Float64 = self.field_efficiency_table.interp(sunpos[i])
            var dz: Float64 = zref - zfit
            err_fit += dz * dz
        # end for
        err_fit = sqrt(err_fit)
        if err_fit > 0.01:
            self.error_msg = util.format("The heliostat field interpolation function fit is poor! (err_fit=%f RMS)", err_fit)
            self.mc_csp_messages.add_message(C_csp_messages.WARNING, self.error_msg)
        # end if
        self.ms_params.m_A_sf = self.ms_params.m_helio_height * self.ms_params.m_helio_width * self.ms_params.m_dens_mirror * self.m_N_hel
        self.m_eta_prev = 0.0
        self.m_v_wind_prev = 0.0
        self.m_ncall = -1
    # end init

    def call(inout self, weather: C_csp_weatherreader.S_outputs, field_control_in: Float64, sim_info: C_csp_solver_sim_info):
        self.m_ncall += 1
        var time: Float64 = sim_info.ms_ts.m_time
        var step: Float64 = sim_info.ms_ts.m_step
        var sf_adjust: Float64 = 1.0
        if self.ms_params.m_sf_adjust.ncells() >= 8760:
            var full_step: Float64 = 8760.0 * 3600.0 / Float64(self.ms_params.m_sf_adjust.ncells())
            sf_adjust = self.ms_params.m_sf_adjust[Int(time / full_step) - 1]
        # end if
        var v_wind: Float64 = weather.m_wspd
        self.m_v_wind_current = v_wind
        var field_control: Float64 = field_control_in
        if field_control_in > 1.0:
            field_control = 1.0
        if field_control_in < 0.0:
            field_control = 0.0
        var solzen: Float64 = weather.m_solzen * CSP.pi / 180.0
        if solzen >= CSP.pi / 2.0:
            field_control = 0.0
        var solaz: Float64 = weather.m_solazi * CSP.pi / 180.0
        self.ms_outputs.m_flux_map_out.fill(0.0)
        var pparasi: Float64 = 0.0
        if (field_control > 1.0e-4 and self.m_eta_prev < 1.0e-4) or \
           (field_control < 1.0e-4 and self.m_eta_prev >= 1.0e-4) or \
           (field_control > 1.0e-4 and v_wind >= self.m_v_wind_max) or \
           (self.m_eta_prev > 1.0e-4 and self.m_v_wind_prev >= self.m_v_wind_max and v_wind < self.m_v_wind_max):
            pparasi = self.m_N_hel * self.m_p_start / (step / 3600.0)
        # end if
        if v_wind < self.m_v_wind_max and self.m_v_wind_prev < self.m_v_wind_max:
            pparasi += self.m_N_hel * self.m_p_track * field_control
        # end if
        var eta_field: Float64 = 0.0
        if solzen > (CSP.pi / 2 - 0.001 - self.m_hel_stow_deploy) or v_wind > self.m_v_wind_max or time < 3601:
            eta_field = 1.0e-6
        else:
            var sunpos: vector[Float64] = vector[Float64]()
            sunpos.push_back(solaz / az_scale)
            sunpos.push_back(solzen / zen_scale)
            if self.ms_params.m_eta_map_aod_format:
                if weather.m_aod != weather.m_aod:
                    sunpos.push_back(0.0)
                else:
                    sunpos.push_back(weather.m_aod)
            # end if
            eta_field = self.field_efficiency_table.interp(sunpos) * eff_scale
            eta_field = fmin(fmax(eta_field, 0.0), 1.0) * field_control * sf_adjust
            var pos_now: VectDoub = VectDoub(sunpos)
            var distances: vector[Float64] = vector[Float64]()
            var indices: vector[Int] = vector[Int]()
            for i in range(Int(self.m_flux_positions.size())):
                distances.push_back(self.rdist(&pos_now, &self.m_flux_positions[i]))
                indices.push_back(i)
            quicksort[Float64, Int](distances, indices)
            var avepoints: Float64 = 0.0
            var npt: Int = 6
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
                var imap: Int = indices[k]
                for j in range(self.m_n_flux_y):
                    for i in range(self.m_n_flux_x):
                        self.ms_outputs.m_flux_map_out[j, i] += self.ms_params.m_flux_maps[imap * self.m_n_flux_y + j, i] * weights[k]
            # end for
        # end if
        self.ms_outputs.m_q_dot_field_inc = weather.m_beam * self.ms_params.m_A_sf * 1.0e-6
        self.ms_outputs.m_pparasi = pparasi / 1.0e3
        self.ms_outputs.m_eta_field = eta_field
        self.ms_outputs.m_sf_adjust_out = sf_adjust
    # end call

    def off(inout self, sim_info: C_csp_solver_sim_info):
        self.m_ncall += 1
        var step: Float64 = sim_info.ms_ts.m_step
        var pparasi: Float64 = 0.0
        if self.m_eta_prev >= 1.0e-4:
            pparasi = self.m_N_hel * self.m_p_start / (step / 3600.0)
        self.ms_outputs.m_pparasi = pparasi / 1.0e3
        self.ms_outputs.m_flux_map_out.fill(0.0)
        self.ms_outputs.m_q_dot_field_inc = 0.0
        self.ms_outputs.m_eta_field = 0.0
    # end off

    def converged(inout self):
        self.m_eta_prev = self.ms_outputs.m_eta_field
        self.m_ncall = -1
    # end converged
# end struct C_pt_heliostatfield
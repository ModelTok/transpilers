// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from csp_solver_core import C_csp_collector_receiver, C_csp_weatherreader, C_csp_solver_htf_1state, C_csp_solver_sim_info, C_csp_reported_outputs, C_csp_exception, C_csp_messages
from csp_solver_util import check_double, util
from sam_csp_util import CSP, OpticalDataTable, GaussMarkov, Powvargram, MatDoub, VectDoub
from lib_util import Matrix
from interpolation_routines import interpolation_routines as interp
from math import sin, cos, asin, acos, sqrt, fmod, ceil, floor, abs, pow, min, max, pi
from stdlib import math

@value
struct S_output_info:
    key: Int
    typ: Int

alias csp_info_invalid = S_output_info(key=-1, typ=0)

var zen_scale: Float64 = 1.570781477
var az_scale: Float64 = 6.283125908

var S_output_info_list: List[S_output_info] = List[S_output_info](
    S_output_info(key=C_csp_gen_collector_receiver.E_Q_DOT_FIELD_INC, typ=C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(key=C_csp_gen_collector_receiver.E_ETA_FIELD, typ=C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(key=C_csp_gen_collector_receiver.E_Q_DOT_REC_INC, typ=C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(key=C_csp_gen_collector_receiver.E_ETA_THERMAL, typ=C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(key=C_csp_gen_collector_receiver.E_F_SFHL_QDNI, typ=C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(key=C_csp_gen_collector_receiver.E_F_SFHL_QWSPD, typ=C_csp_reported_outputs.TS_WEIGHTED_AVE),
    S_output_info(key=C_csp_gen_collector_receiver.E_F_SFHL_QTDRY, typ=C_csp_reported_outputs.TS_WEIGHTED_AVE),
    csp_info_invalid
)

class C_csp_gen_collector_receiver(C_csp_collector_receiver):
    enum:
        E_Q_DOT_FIELD_INC = 0   // [W/m2]
        E_ETA_FIELD = 1          // [-]
        E_Q_DOT_REC_INC = 2      // [W/m2]
        E_ETA_THERMAL = 3        // [-]
        E_F_SFHL_QDNI = 4
        E_F_SFHL_QWSPD = 5
        E_F_SFHL_QTDRY = 6

    var m_T_htf_cold_fixed: Float64 = 300.0 + 273.15   // [K]
    var m_T_htf_hot_fixed: Float64 = 500.0 + 273.15    // [K]
    var m_cp_htf_fixed: Float64 = 2.0                  // [kJ/kg-K]
    var mc_optical_table: OpticalDataTable
    var mpc_optical_table_uns: GaussMarkov? = None
    var m_eff_scale: Float64 = Float64.nan
    var m_A_sf_calc: Float64 = Float64.nan             // [m2]
    var m_mode: Int = -1
    var m_mode_prev: Int = -1
    var mc_reported_outputs: C_csp_reported_outputs

    @value
    struct S_params:
        var m_latitude: Float64 = Float64.nan          // [deg] Site latitude, convert to radians in init()
        var m_longitude: Float64 = Float64.nan         // [deg] Site longitude, convert to radians in init()
        var m_theta_stow: Float64 = Float64.nan        // [deg] Solar elevation angle at which the solar field stops operating, convert to radians in init()
        var m_theta_dep: Float64 = Float64.nan         // [deg] Solar elevation angle at which the solar field begins operating, convert to radians in init()
        var m_interp_arr: Int = -1                     // [-] Interpolate the array or find nearest neighbor? (1=interp,2=no)
        var m_rad_type: Int = -1                       // [-] Solar resource radiation type (1=DNI,2=horiz.beam,3=tot.horiz)
        var m_solarm: Float64 = Float64.nan            // [-] Solar multiple
        var m_T_sfdes: Float64 = Float64.nan           // [C] Solar field design point temperature (dry bulb), convert to K in init()
        var m_irr_des: Float64 = Float64.nan           // [W/m2] Irradiation design point
        var m_eta_opt_soil: Float64 = Float64.nan      // [-] Soiling optical derate factor
        var m_eta_opt_gen: Float64 = Float64.nan       // [-] General/other optical derate
        var m_f_sfhl_ref: Float64 = Float64.nan        // [MW/MWcap] Reference solar field thermal loss fraction
        var mv_sfhlQ_coefs: List[Float64] = List[Float64]()   // [1/MWt] Irr-based solar field thermal loss adjustment coefficients
        var mv_sfhlT_coefs: List[Float64] = List[Float64]()   // [1/C] Temp.-based solar field thermal loss adjustment coefficients
        var mv_sfhlV_coefs: List[Float64] = List[Float64]()   // [1/[m/s]] Wind-based solar field thermal loss adjustment coefficients
        var m_qsf_des: Float64 = Float64.nan           // [MWt] Solar field thermal production at design
        var m_optical_table: Matrix[Float64]
        var m_is_table_unsorted: Bool = False

    var ms_params: S_params = S_params()

    def __init__(inout self):
        self.mc_reported_outputs.construct(S_output_info_list)

    def __del__(owned self):
        if self.mpc_optical_table_uns is not None:
            del self.mpc_optical_table_uns

    def check_double_params_are_set(self):
        if not check_double(self.ms_params.m_latitude):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_latitude")
        if not check_double(self.ms_params.m_longitude):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_longitude")
        if not check_double(self.ms_params.m_theta_stow):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_theta_stow")
        if not check_double(self.ms_params.m_theta_dep):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_theta_dep")
        if not check_double(self.ms_params.m_solarm):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_solarm")
        if not check_double(self.ms_params.m_T_sfdes):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_T_sfdes")
        if not check_double(self.ms_params.m_irr_des):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_irr_des")
        if not check_double(self.ms_params.m_eta_opt_soil):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_eta_opt_soil")
        if not check_double(self.ms_params.m_eta_opt_gen):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_eta_opt_gen")
        if not check_double(self.ms_params.m_f_sfhl_ref):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_f_sfhl_ref")
        if not check_double(self.ms_params.m_qsf_des):
            raise C_csp_exception("The following parameter was not set prior to calling a C_csp_gen_collector_receiver method:", "m_qsf_des")

    def init(self, init_inputs: C_csp_collector_receiver.S_csp_cr_init_inputs, inout solved_params: C_csp_collector_receiver.S_csp_cr_solved_params):
        self.check_double_params_are_set()
        if self.ms_params.m_interp_arr < 1 or self.ms_params.m_interp_arr > 2:
            var msg: String = util.format("The interpolation code must be 1 (interpolate) or 2 (nearest neighbor)"
                "The input value was %d, so it was reset to 1", self.ms_params.m_interp_arr)
            self.mc_csp_messages.add_notice(msg)
            self.ms_params.m_interp_arr = 1
        if self.ms_params.m_rad_type < 1 or self.ms_params.m_rad_type > 3:
            var msg: String = util.format("The solar resource radiation type must be 1 (DNI), 2 (Beam horizontal), or "
                "3 (Total horizontal). The input value was %d.")
            raise C_csp_exception("C_csp_gen_collector_receiver::init", msg)
        if self.ms_params.mv_sfhlQ_coefs.size() < 1:
            raise C_csp_exception("C_csp_gen_collector_receiver::init","The model requires at least one irradiation-based "
                "thermal loss adjustment coefficient (mv_sfhlQ_coefs)")
        if self.ms_params.mv_sfhlT_coefs.size() < 1:
            raise C_csp_exception("C_csp_gen_collector_receiver::init", "The model requires at least one temperature-based "
                "thermal loss adjustment coefficient (mv_sfhlT_coefs)")
        if self.ms_params.mv_sfhlV_coefs.size() < 1:
            raise C_csp_exception("C_csp_gen_collector_receiver::init", "The model requires at least one wind-based "
                "thermal loss adjustment coefficient (mv_sfhlV_coefs)")
        self.ms_params.m_latitude *= CSP.pi / 180.0    // [rad], convert from deg
        self.ms_params.m_longitude *= CSP.pi / 180.0   // [rad], convert from deg
        self.ms_params.m_theta_stow *= CSP.pi / 180.0  // [rad], convert from deg
        self.ms_params.m_theta_dep *= CSP.pi / 180.0   // [rad], convert from deg
        self.ms_params.m_T_sfdes += 273.15             // [K], convert from C
        if not self.ms_params.m_is_table_unsorted:
            /*
            Standard azimuth-elevation table
            */
            if (self.ms_params.m_optical_table.nrows() < 5 and self.ms_params.m_optical_table.ncols() > 3) or \
               (self.ms_params.m_optical_table.ncols() == 3 and self.ms_params.m_optical_table.nrows() > 4):
                self.mc_csp_messages.add_message(C_csp_messages.WARNING, "The optical efficiency table option flag may not match the specified table format. If running SSC, ensure \"IsTableUnsorted\""
                " =0 if regularly-spaced azimuth-zenith matrix is used and =1 if azimuth,zenith,efficiency points are specified.")
            if self.ms_params.m_optical_table.nrows() <= 0 or self.ms_params.m_optical_table.ncols() <= 0:
                raise C_csp_exception("C_csp_gen_collector_receiver::init","The optical table must have a positive number of rows and columns")
            var xax: DynamicVector[Float64] = DynamicVector[Float64](self.ms_params.m_optical_table.ncols() - 1)
            var yax: DynamicVector[Float64] = DynamicVector[Float64](self.ms_params.m_optical_table.nrows() - 1)
            var data: DynamicVector[Float64] = DynamicVector[Float64]((self.ms_params.m_optical_table.ncols() - 1) * (self.ms_params.m_optical_table.nrows() - 1))
            for i in range(1, self.ms_params.m_optical_table.ncols()):
                xax[i - 1] = self.ms_params.m_optical_table[0][i] * CSP.pi / 180.0
            for j in range(1, self.ms_params.m_optical_table.nrows()):
                yax[j - 1] = self.ms_params.m_optical_table[j][0] * CSP.pi / 180.0
            for j in range(1, self.ms_params.m_optical_table.nrows()):
                for i in range(1, self.ms_params.m_optical_table.ncols()):
                    data[i - 1 + (self.ms_params.m_optical_table.ncols() - 1) * (j - 1)] = self.ms_params.m_optical_table[j][i]
            self.mc_optical_table.AddXAxis(xax.data, Int(self.ms_params.m_optical_table.ncols() - 1))
            self.mc_optical_table.AddYAxis(yax.data, Int(self.ms_params.m_optical_table.nrows() - 1))
            self.mc_optical_table.AddData(data.data)
            // no delete; Mojo manages memory
        else:
            /*
            Use the unstructured data table
            */
            /*
            ------------------------------------------------------------------------------
            Create the regression fit on the efficiency map
            ------------------------------------------------------------------------------
            */
            if self.ms_params.m_optical_table.ncols() != 3:
                var msg: String = util.format("The heliostat field efficiency file is not formatted correctly. Type expects 3 columns"
                    " (zenith angle, azimuth angle, efficiency value) and instead has %d cols.", self.ms_params.m_optical_table.ncols())
                raise C_csp_exception("C_csp_gen_collector_receiver::init", msg)
            var sunpos: MatDoub = MatDoub()
            var effs: VectDoub = VectDoub()
            var nrows: Int = Int(self.ms_params.m_optical_table.nrows())
            sunpos.resize(nrows, VectDoub(2))
            effs.resize(nrows)
            var eff_maxval: Float64 = -9.0e9
            for i in range(nrows):
                sunpos[i][0] = self.ms_params.m_optical_table[i][0] / az_scale * CSP.pi / 180.0
                sunpos[i][1] = self.ms_params.m_optical_table[i][1] / zen_scale * CSP.pi / 180.0
                var eff: Float64 = self.ms_params.m_optical_table[i][2]
                effs[i] = eff
                if eff > eff_maxval:
                    eff_maxval = eff
            self.m_eff_scale = eff_maxval
            for i in range(nrows):
                effs[i] /= self.m_eff_scale
            var vgram: Powvargram = Powvargram(sunpos, effs, 1.99, 0.0)
            self.mpc_optical_table_uns = GaussMarkov(sunpos, effs, vgram)
            var err_fit: Float64 = 0.0
            var npoints: Int = Int(sunpos.size())
            for i in range(npoints):
                var zref: Float64 = effs[i]
                var zfit: Float64 = self.mpc_optical_table_uns.interp(sunpos[i])
                var dz: Float64 = zref - zfit
                err_fit += dz * dz
            err_fit = sqrt(err_fit)
            if err_fit > 0.01:
                var msg: String = util.format("The heliostat field interpolation function fit is poor! (err_fit=%f RMS)", err_fit)
                self.mc_csp_messages.add_message(C_csp_messages.WARNING, msg)
        // end unstructured data table
        self.init_sf()
        self.m_mode = C_csp_collector_receiver.OFF
        self.m_mode_prev = self.m_mode
        return

    def init_sf(self):
        var omega: Float64 = 0.0 // solar noon
        var dec: Float64 = 23.45 * CSP.pi / 180.0    // [rad] declination at summer solstice
        var solalt: Float64 = asin(sin(dec) * sin(self.ms_params.m_latitude) + cos(self.ms_params.m_latitude) * cos(dec) * cos(omega))
        var opt_des: Float64 = Float64.nan
        if self.ms_params.m_is_table_unsorted:
            var sunpos: VectDoub = VectDoub()
            sunpos.push_back(0.0)
            sunpos.push_back((CSP.pi / 2.0 - solalt) / zen_scale)
            opt_des = self.mpc_optical_table_uns.interp(sunpos) * self.m_eff_scale
        else:
            if self.ms_params.m_interp_arr == 1:
                opt_des = self.mc_optical_table.interpolate(0.0, max(CSP.pi / 2.0 - solalt, 0.0))
            else:
                opt_des = self.mc_optical_table.nearest(0.0, max(CSP.pi / 2.0 - solalt, 0.0))
        var eta_opt_ref: Float64 = self.ms_params.m_eta_opt_soil * self.ms_params.m_eta_opt_gen * opt_des
        self.m_A_sf_calc = (self.ms_params.m_qsf_des * (1.0 + self.ms_params.m_f_sfhl_ref)) / (self.ms_params.m_irr_des * eta_opt_ref) * 1.0e6    // [m2]
        return

    def get_operating_state(self) -> Int:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_operating_state() is not complete")
        return -1

    def get_startup_time(self) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_startup_time() is not complete")
        return Float64.nan

    def get_startup_energy(self) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_startup_energy() is not complete")
        return Float64.nan

    def get_pumping_parasitic_coef(self) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_pumping_parasitic_coef() is not complete")
        return Float64.nan

    def get_min_power_delivery(self) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_min_power_delivery() is not complete")
        return Float64.nan

    def get_tracking_power(self) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_tracking_power() is not complete")
        return Float64.nan // MWe

    def get_col_startup_power(self) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_col_startup_power() is not complete")
        return Float64.nan // MWe-hr

    def on(self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, field_control: Float64, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        raise C_csp_exception("C_csp_gen_collector_receiver::on(...) is not complete")

    def call(self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inputs: C_csp_collector_receiver.S_csp_cr_inputs, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        var ibn: Float64 = weather.m_beam        // [W/m2] DNI
        var ibh: Float64 = weather.m_hor_beam    // [W/m2] Beam-horizontal irradiance
        var itoth: Float64 = weather.m_global    // [W/m2] Total horizontal irradiance
        var tdb: Float64 = weather.m_tdry + 273.15   // [K] Ambient dry-bulb temperature, convert from C
        var vwind: Float64 = weather.m_wspd      // [m/s] Wind speed
        var shift: Float64 = weather.m_shift * CSP.pi / 180.0   // [rad]    
        var irr_used: Float64 = Float64.nan
        if self.ms_params.m_rad_type == 1:
            irr_used = ibn    // [W/m2]
        elif self.ms_params.m_rad_type == 2:
            irr_used = ibh    // [W/m2]
        elif self.ms_params.m_rad_type == 3:
            irr_used = itoth  // [W/m2]
        var hour_of_day: Float64 = fmod(sim_info.ms_ts.m_time / 3600.0, 24.0)     // [hr] hour_of_day of the day (1..24)
        var day_of_year: Float64 = ceil(sim_info.ms_ts.m_time / 3600.0 / 24.0)     // [-] Day of the year
        var B: Float64 = (day_of_year - 1.0) * 360.0 / 365.0 * CSP.pi / 180.0
        var EOT: Float64 = 229.2 * (0.000075 + 0.001868 * cos(B) - 0.032077 * sin(B) - 0.014615 * cos(B * 2.0) - 0.04089 * sin(B * 2.0))
        var dec: Float64 = 23.45 * sin(360.0 * (284.0 + day_of_year) / 365.0 * CSP.pi / 180.0) * CSP.pi / 180.0
        var SolarNoon: Float64 = 12.0 - ((shift) * 180.0 / CSP.pi) / 15.0 - EOT / 60.0
        var theta_dep: Float64 = max(self.ms_params.m_theta_dep, 1.0e-6)
        var DepHr1: Float64 = cos(self.ms_params.m_latitude) / tan(theta_dep)
        var DepHr2: Float64 = -tan(dec) * sin(self.ms_params.m_latitude) / tan(theta_dep)
        var DepHr3: Float64 = (tan(CSP.pi - theta_dep) < 0.0 ? -1.0 : 1.0) * acos((DepHr1 * DepHr2 + sqrt(DepHr1 * DepHr1 - DepHr2 * DepHr2 + 1.0)) / (DepHr1 * DepHr1 + 1.0)) * 180.0 / CSP.pi / 15.0
        var DepTime: Float64 = SolarNoon + DepHr3
        var theta_stow: Float64 = max(self.ms_params.m_theta_stow, 1.0e-6)
        var StwHr1: Float64 = cos(self.ms_params.m_latitude) / tan(theta_stow)
        var StwHr2: Float64 = -tan(dec) * sin(self.ms_params.m_latitude) / tan(theta_stow)
        var StwHr3: Float64 = (tan(CSP.pi - theta_stow) < 0.0 ? -1.0 : 1.0) * acos((StwHr1 * StwHr2 + sqrt(StwHr1 * StwHr1 - StwHr2 * StwHr2 + 1.0)) / (StwHr1 * StwHr1 + 1.0)) * 180.0 / CSP.pi / 15.0
        var StwTime: Float64 = SolarNoon + StwHr3
        var HrA: Float64 = hour_of_day - sim_info.ms_ts.m_step / 3600.0    // [hr]
        var HrB: Float64 = hour_of_day
        var Ftrack: Float64
        var MidTrack: Float64
        if (HrB > DepTime) and (HrA < StwTime):
            if HrA < DepTime:
                Ftrack = (HrB - DepTime) * sim_info.ms_ts.m_step / 3600.0
                MidTrack = HrB - Ftrack * 0.5 * sim_info.ms_ts.m_step / 3600.0
            elif HrB > StwTime:
                Ftrack = (StwTime - HrA) * sim_info.ms_ts.m_step / 3600.0
                MidTrack = HrA + Ftrack * 0.5 * sim_info.ms_ts.m_step / 3600.0
            else:
                Ftrack = 1.0
                MidTrack = HrA + 0.5 * sim_info.ms_ts.m_step / 3600.0
        else:
            Ftrack = 0.0
            MidTrack = HrA + 0.5 * sim_info.ms_ts.m_step / 3600.0
        var StdTime: Float64 = MidTrack
        var soltime: Float64 = StdTime + ((shift) * 180.0 / CSP.pi) / 15.0 + EOT / 60.0
        var omega: Float64 = (soltime - 12.0) * 15.0 * CSP.pi / 180.0
        var solalt: Float64 = asin(sin(dec) * sin(self.ms_params.m_latitude) + cos(self.ms_params.m_latitude) * cos(dec) * cos(omega))
        var solaz: Float64 = (omega < 0.0 ? -1.0 : 1.0) * abs(acos(min(1.0, (cos(CSP.pi / 2.0 - solalt) * sin(self.ms_params.m_latitude) - sin(dec)) / (sin(CSP.pi / 2.0 - solalt) * cos(self.ms_params.m_latitude)))))
        var opt_val: Float64
        if self.ms_params.m_is_table_unsorted:
            var sunpos: VectDoub = VectDoub()
            sunpos.push_back(solaz / az_scale)
            sunpos.push_back((CSP.pi / 2.0 - solalt) / zen_scale)
            opt_val = self.mpc_optical_table_uns.interp(sunpos) * self.m_eff_scale
        else:
            if self.ms_params.m_interp_arr == 1:
                opt_val = self.mc_optical_table.interpolate(solaz, max(CSP.pi / 2.0 - solalt, 0.0))
            else:
                opt_val = self.mc_optical_table.nearest(solaz, max(CSP.pi / 2.0 - solalt, 0.0))
        var eta_arr: Float64 = max(opt_val * Ftrack, 0.0)  // mjw 7.25.11 limit zenith to <90, otherwise the interpolation error message gets called during night hours.
        var eta_opt_sf: Float64 = eta_arr * self.ms_params.m_eta_opt_soil * self.ms_params.m_eta_opt_gen * inputs.m_adjust
        var f_sfhl_qdni: Float64 = 0.0
        var f_sfhl_tamb: Float64 = 0.0
        var f_sfhl_vwind: Float64 = 0.0
        for i in range(self.ms_params.mv_sfhlQ_coefs.size()):
            f_sfhl_qdni += self.ms_params.mv_sfhlQ_coefs[i] * (irr_used / self.ms_params.m_irr_des) ** i
        for i in range(self.ms_params.mv_sfhlT_coefs.size()):
            f_sfhl_tamb += self.ms_params.mv_sfhlT_coefs[i] * (tdb - self.ms_params.m_T_sfdes) ** i
        for i in range(self.ms_params.mv_sfhlV_coefs.size()):
            f_sfhl_vwind += self.ms_params.mv_sfhlV_coefs[i] * (vwind) ** i
        var f_sfhl: Float64 = 1.0 - self.ms_params.m_f_sfhl_ref * (f_sfhl_qdni + f_sfhl_tamb + f_sfhl_vwind)  // sf thermal efficiency
        var q_hl_sf: Float64 = (1.0 - f_sfhl) * self.ms_params.m_qsf_des       // [MWt]
        var q_dot_field_inc: Float64 = self.m_A_sf_calc * irr_used * 1.0e-6    // [MWt]
        var q_dot_rec_inc: Float64 = q_dot_field_inc * eta_opt_sf    // [MWt]
        var q_sf: Float64 = q_dot_rec_inc - q_hl_sf  // [MWt]
        if q_sf < 0.0:
            q_sf = 0.0
        cr_out_solver.m_q_startup = 0.0
        cr_out_solver.m_time_required_su = 0.0
        cr_out_solver.m_m_dot_salt_tot = q_sf * 100.0 / (self.m_cp_htf_fixed * (self.m_T_htf_hot_fixed - self.m_T_htf_cold_fixed)) * 3600.0   // [kg/hr]
        cr_out_solver.m_q_thermal = q_sf                            // [MWt]
        cr_out_solver.m_T_salt_hot = self.m_T_htf_hot_fixed - 273.15    // [C]
        cr_out_solver.m_W_dot_col_tracking = 0.0       // [MWe]
        cr_out_solver.m_W_dot_htf_pump = 0.0           // [MWe]
        self.mc_reported_outputs.value(E_Q_DOT_FIELD_INC, q_dot_field_inc)  // [MWt]
        self.mc_reported_outputs.value(E_ETA_FIELD, eta_opt_sf)    // [-]
        self.mc_reported_outputs.value(E_Q_DOT_REC_INC, q_dot_rec_inc)  // [-]
        self.mc_reported_outputs.value(E_ETA_THERMAL, q_sf / q_dot_rec_inc)    // [-]
        self.mc_reported_outputs.value(E_F_SFHL_QDNI, f_sfhl_qdni)   // [-]
        self.mc_reported_outputs.value(E_F_SFHL_QWSPD, f_sfhl_vwind) // [-]
        self.mc_reported_outputs.value(E_F_SFHL_QTDRY, f_sfhl_tamb)   // [-]

    def startup(self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        raise C_csp_exception("C_csp_gen_collector_receiver::startup(...) is not complete")
        return

    def estimates(self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inout est_out: C_csp_collector_receiver.S_csp_cr_est_out, sim_info: C_csp_solver_sim_info):
        raise C_csp_exception("C_csp_gen_collector_receiver::estimates(...) is not complete")
        return

    def off(self, weather: C_csp_weatherreader.S_outputs, htf_state_in: C_csp_solver_htf_1state, inout cr_out_solver: C_csp_collector_receiver.S_csp_cr_out_solver, sim_info: C_csp_solver_sim_info):
        self.m_mode = C_csp_collector_receiver.OFF
        cr_out_solver.m_q_startup = 0.0
        cr_out_solver.m_time_required_su = 0.0
        cr_out_solver.m_m_dot_salt_tot = 0.0    // [kg/hr]
        cr_out_solver.m_q_thermal = 0.0         // [MWt]
        cr_out_solver.m_T_salt_hot = 0.0        // [C]
        cr_out_solver.m_W_dot_col_tracking = 0.0   // [MWe]
        cr_out_solver.m_W_dot_htf_pump = 0.0       // [MWe]
        cr_out_solver.m_component_defocus = 1.0    // [-]
        self.mc_reported_outputs.value(E_Q_DOT_FIELD_INC, 0.0)   // [MWt]
        self.mc_reported_outputs.value(E_ETA_FIELD, 0.0)        // [-]
        self.mc_reported_outputs.value(E_Q_DOT_REC_INC, 0.0)    // [-]
        self.mc_reported_outputs.value(E_ETA_THERMAL, 0.0)      // [-]
        self.mc_reported_outputs.value(E_F_SFHL_QDNI, 0.0)      // [-]
        self.mc_reported_outputs.value(E_F_SFHL_QWSPD, 0.0)     // [-]
        self.mc_reported_outputs.value(E_F_SFHL_QTDRY, 0.0)     // [-]
        return

    def converged(self):
        self.m_mode_prev = self.m_mode
        return

    def write_output_intervals(self, report_time_start: Float64, v_temp_ts_time_end: List[Float64], report_time_end: Float64):
        return

    def calculate_optical_efficiency(self, weather: C_csp_weatherreader.S_outputs, sim: C_csp_solver_sim_info) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::calculate_optical_efficiency() is not complete")
        return Float64.nan

    def calculate_thermal_efficiency_approx(self, weather: C_csp_weatherreader.S_outputs, q_incident: Float64) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::calculate_thermal_efficiency_approx() is not complete")
        return Float64.nan

    def get_collector_area(self) -> Float64:
        raise C_csp_exception("C_csp_gen_collector_receiver::get_collector_area() is not complete")
        return Float64.nan
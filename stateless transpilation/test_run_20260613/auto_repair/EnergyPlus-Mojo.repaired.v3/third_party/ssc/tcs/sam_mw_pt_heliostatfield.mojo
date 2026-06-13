from tcstype import *
from lib_util import *
from lib_weatherfile.h import *
from interpolation_routines import *
from AutoPilot_API import *
from IOUtil import *
from sort_method import *
from Heliostat import *
from std.algorithm import *
from std.sstream import *

# Define macros as Mojo constants
alias pi = 3.141592654
alias az_scale = 6.283125908
alias zen_scale = 1.570781477
alias eff_scale = 0.7

# Forward declaration of static callback
def solarpilot_callback(siminfo: simulation_info, data: void*) -> bool:

# Comment block describing the module
"""
A self-contained heliostat field type that directly calls SolarPilot through the AutoPilot API. The user
may optionally specify the heliostat field positions or may use this type to generate positions based on
input parameters.
This type can be run in three different modes. 
...
"""

# Enums as alias constants (simulating C++ enum)
alias P_run_type = 0
alias P_helio_width = 1
alias P_helio_height = 2
alias P_helio_optical_error = 3
alias P_helio_active_fraction = 4
alias P_dens_mirror = 5
alias P_helio_reflectance = 6
alias P_rec_absorptance = 7
alias P_rec_height = 8
alias P_rec_aspect = 9
alias P_rec_hl_perm2 = 10
alias P_q_design = 11
alias P_h_tower = 12
alias P_weather_file = 13
alias P_land_bound_type = 14
alias P_land_max = 15
alias P_land_min = 16
alias P_land_bound_table = 17
alias P_land_bound_list = 18
alias P_p_start = 19
alias P_p_track = 20
alias P_hel_stow_deploy = 21
alias P_v_wind_max = 22
alias P_interp_nug = 23
alias P_interp_beta = 24
alias P_n_flux_x = 25
alias P_n_flux_y = 26
alias P_helio_positions = 27
alias P_helio_aim_points = 28
alias P_N_hel = 29
alias P_eta_map = 30
alias P_flux_positions = 31
alias P_flux_maps = 32
alias P_c_atm_0 = 33
alias P_c_atm_1 = 34
alias P_c_atm_2 = 35
alias P_c_atm_3 = 36
alias P_n_facet_x = 37
alias P_n_facet_y = 38
alias P_cant_type = 39
alias P_focus_type = 40
alias P_n_flux_days = 41
alias P_delta_flux_hrs = 42
alias P_dni_des = 43
alias P_land_area = 44
alias I_v_wind = 45
alias I_field_control = 46
alias I_solaz = 47
alias I_solzen = 48
alias O_pparasi = 49
alias O_eta_field = 50
alias O_flux_map = 51
alias N_MAX = 52

# tcsvarinfo array - using a list of tuples? We'll keep as a list of var info structs (assuming tcsvarinfo defined in tcstype)
var sam_mw_pt_heliostatfield_variables: List[tcsvarinfo] = [
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_run_type, "run_type", "Run type", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_helio_width, "helio_width", "Heliostat width", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_helio_height, "helio_height", "Heliostat height", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_helio_optical_error, "helio_optical_error", "Heliostat optical error", "rad", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_helio_active_fraction, "helio_active_fraction", "Heliostat active frac.", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_dens_mirror, "dens_mirror", "Ratio of reflective area to profile", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_helio_reflectance, "helio_reflectance", "Heliostat reflectance", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_absorptance, "rec_absorptance", "Receiver absorptance", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_height, "rec_height", "Receiver height", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_aspect, "rec_aspect", "Receiver aspect ratio", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_hl_perm2, "rec_hl_perm2", "Receiver design heatloss", "kW/m2", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_q_design, "q_design", "Field thermal power rating", "kW", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_h_tower, "h_tower", "Tower height", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_STRING, P_weather_file, "weather_file", "Weather file location", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_land_bound_type, "land_bound_type", "Land boundary type", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_land_max, "land_max", "Land max boundary", "- OR m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_land_min, "land_min", "Land min boundary", "- OR m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_land_bound_table, "land_bound_table", "Land boundary table", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY, P_land_bound_list, "land_bound_list", "Boundary table listing", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_p_start, "p_start", "Heliostat startup energy", "kWe-hr", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_p_track, "p_track", "Heliostat tracking energy", "kWe", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_hel_stow_deploy, "hel_stow_deploy", "Stow/deploy elevation", "deg", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_v_wind_max, "v_wind_max", "Max. wind velocity", "m/s", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_interp_nug, "interp_nug", "Interpolation nugget", "-", "", "", "0.0"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_interp_beta, "interp_beta", "Interpolation beta coef.", "-", "", "", "1.99"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_flux_x, "n_flux_x", "Flux map X resolution", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_flux_y, "n_flux_y", "Flux map Y resolution", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_helio_positions, "helio_positions", "Heliostat position table", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_helio_aim_points, "helio_aim_points", "Heliostat aim point table", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_N_hel, "N_hel", "Number of heliostats", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_eta_map, "eta_map", "Field efficiency array", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_flux_positions, "flux_positions", "Flux map sun positions", "deg", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_flux_maps, "flux_maps", "Flux map intensities", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_c_atm_0, "c_atm_0", "Attenuation coefficient 0", "", "", "", "0.006789"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_c_atm_0, "c_atm_1", "Attenuation coefficient 1", "", "", "", "0.1046"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_c_atm_0, "c_atm_2", "Attenuation coefficient 2", "", "", "", "-0.0107"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_c_atm_0, "c_atm_3", "Attenuation coefficient 3", "", "", "", "0.002845"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_facet_x, "n_facet_x", "Number of heliostat facets - X", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_facet_y, "n_facet_y", "Number of heliostat facets - Y", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_cant_type, "cant_type", "Heliostat cant method", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_focus_type, "focus_type", "Heliostat focus method", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_flux_days, "n_flux_days", "No. days in flux map lookup", "", "", "", "8"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_delta_flux_hrs, "delta_flux_hrs", "Hourly frequency in flux map lookup", "hrs", "", "", "1"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_dni_des, "dni_des", "Design-point DNI", "W/m2", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_land_area, "land_area", "CALCULATED land area", "acre", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_v_wind, "vwind", "Wind velocity", "m/s", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_field_control, "field_control", "Field defocus control", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_solaz, "solaz", "Solar azimuth angle: 0 due north - clockwise to +360", "deg", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_solzen, "solzen", "Solar zenith angle", "deg", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_pparasi, "pparasi", "Parasitic tracking/startup power", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_eta_field, "eta_field", "Total field efficiency", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_MATRIX, O_flux_map, "flux_map", "Receiver flux map", "", "n_flux_x cols x n_flux_y rows", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
]

# Class definition
@value
class sam_mw_pt_heliostatfield(tcstypeinterface):
    var field_efficiency_table: GaussMarkov
    var fluxtab: sp_flux_table
    var p_start: Float64
    var p_track: Float64
    var hel_stow_deploy: Float64
    var v_wind_max: Float64
    var N_hel: Int
    var n_flux_x: Int
    var n_flux_y: Int
    var m_flux_positions: MatDoub
    var eta_prev: Float64
    var v_wind_prev: Float64

    # Nested struct for RUN_TYPE
    @value
    struct RUN_TYPE:
        alias AUTO = 0
        alias USER_FIELD = 1
        alias USER_DATA = 2

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cst, ti)
        self.p_start = Float64.NaN()
        self.p_track = Float64.NaN()
        self.hel_stow_deploy = Float64.NaN()
        self.v_wind_max = Float64.NaN()
        self.N_hel = 0
        self.n_flux_x = 0
        self.n_flux_y = 0
        self.eta_prev = Float64.NaN()
        self.v_wind_prev = Float64.NaN()
        self.field_efficiency_table = GaussMarkov(0)

    def __del__(inout self):
        if self.field_efficiency_table != None:
            del self.field_efficiency_table

    def init(inout self) -> Int:
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
        var helio_width: Float64 = Float64.NaN()
        var helio_height: Float64 = Float64.NaN()
        var helio_optical_error: Float64 = Float64.NaN()
        var helio_active_fraction: Float64 = Float64.NaN()
        var dens_mirror: Float64 = Float64.NaN()
        var helio_reflectance: Float64 = Float64.NaN()
        var rec_absorptance: Float64 = Float64.NaN()
        var rec_height: Float64 = Float64.NaN()
        var rec_aspect: Float64 = Float64.NaN()
        var rec_hl_perm2: Float64 = Float64.NaN()
        var q_design: Float64 = Float64.NaN()
        var h_tower: Float64 = Float64.NaN()
        var land_bound_type: Int = 0
        var land_max: Float64 = Float64.NaN()
        var land_min: Float64 = Float64.NaN()
        var land_bound_table: Pointer[Float64] = None
        var land_bound_list: Pointer[Float64] = None
        var interp_nug: Float64 = Float64.NaN()
        var interp_beta: Float64 = Float64.NaN()
        var c_atm_0: Float64 = Float64.NaN()
        var c_atm_1: Float64 = Float64.NaN()
        var c_atm_2: Float64 = Float64.NaN()
        var c_atm_3: Float64 = Float64.NaN()
        var n_facet_x: Int = 0
        var n_facet_y: Int = 0
        var cant_type: Int = 0
        var focus_type: Int = 0
        var n_flux_days: Int = 0
        var delta_flux_hrs: Int = 0
        var dni_des: Float64 = Float64.NaN()
        var helio_positions: Pointer[Float64] = None
        var helio_aim_points: Pointer[Float64] = None
        var eta_map: Pointer[Float64] = None
        var flux_positions: Pointer[Float64] = None
        var flux_maps: Pointer[Float64] = None
        var pos_dim: Int = 0
        var flux_map: Pointer[Float64] = None

        var run_type: Int = Int(self.value(P_run_type))

        # Switch over run_type
        if run_type == sam_mw_pt_heliostatfield.RUN_TYPE.AUTO or run_type == sam_mw_pt_heliostatfield.RUN_TYPE.USER_FIELD:
            helio_width = self.value(P_helio_width)
            helio_height = self.value(P_helio_height)
            helio_optical_error = self.value(P_helio_optical_error)
            helio_active_fraction = self.value(P_helio_active_fraction)
            dens_mirror = self.value(P_dens_mirror)
            helio_reflectance = self.value(P_helio_reflectance)
            rec_absorptance = self.value(P_rec_absorptance)
            rec_height = self.value(P_rec_height)
            rec_aspect = self.value(P_rec_aspect)
            rec_hl_perm2 = self.value(P_rec_hl_perm2)
            q_design = self.value(P_q_design)
            h_tower = self.value(P_h_tower)
            weather_file = self.value_str(P_weather_file)
            land_bound_type = Int(self.value(P_land_bound_type))
            land_max = self.value(P_land_max)
            land_min = self.value(P_land_min)
            land_bound_table = self.value(P_land_bound_table, &nrows1, &ncols1)
            land_bound_list = self.value(P_land_bound_list, &nrows2)
            self.p_start = self.value(P_p_start)
            self.p_track = self.value(P_p_track)
            self.hel_stow_deploy = self.value(P_hel_stow_deploy) * pi / 180.0
            self.v_wind_max = self.value(P_v_wind_max)
            interp_nug = self.value(P_interp_nug)
            interp_beta = self.value(P_interp_beta)
            self.n_flux_x = Int(self.value(P_n_flux_x))
            self.n_flux_y = Int(self.value(P_n_flux_y))
            c_atm_0 = self.value(P_c_atm_0)
            c_atm_1 = self.value(P_c_atm_1)
            c_atm_2 = self.value(P_c_atm_2)
            c_atm_3 = self.value(P_c_atm_3)
            n_facet_x = Int(self.value(P_n_facet_x))
            n_facet_y = Int(self.value(P_n_facet_y))
            cant_type = Int(self.value(P_cant_type))
            focus_type = Int(self.value(P_focus_type))
            n_flux_days = Int(self.value(P_n_flux_days))
            delta_flux_hrs = Int(self.value(P_delta_flux_hrs))
            dni_des = self.value(P_dni_des)
            pos_dim = 2
            if run_type != sam_mw_pt_heliostatfield.RUN_TYPE.USER_FIELD:
                # break from case? Actually C++ switch with break; we emulate with if-else structure

            else:
                helio_positions = self.value(P_helio_positions, &self.N_hel, &pos_dim)
                helio_aim_points = self.value(P_helio_aim_points, &nrows4, &ncols4)
        elif run_type == sam_mw_pt_heliostatfield.RUN_TYPE.USER_DATA:
            h_tower = self.value(P_h_tower)
            land_bound_type = Int(self.value(P_land_bound_type))
            land_max = self.value(P_land_max)
            land_min = self.value(P_land_min)
            land_bound_table = self.value(P_land_bound_table, &nrows1, &ncols1)
            land_bound_list = self.value(P_land_bound_list, &nrows2)
            self.p_start = self.value(P_p_start)
            self.p_track = self.value(P_p_track)
            self.hel_stow_deploy = self.value(P_hel_stow_deploy) * pi / 180.0
            self.v_wind_max = self.value(P_v_wind_max)
            interp_nug = self.value(P_interp_nug)
            interp_beta = self.value(P_interp_beta)
            helio_positions = self.value(P_helio_positions, &self.N_hel, &pos_dim)
            helio_aim_points = self.value(P_helio_aim_points, &nrows4, &ncols4)
            eta_map = self.value(P_eta_map, &nrows5, &ncols5)
            self.n_flux_x = Int(self.value(P_n_flux_x))
            self.n_flux_y = Int(self.value(P_n_flux_y))
            flux_positions = self.value(P_flux_positions, &nfluxpos, &nfposdim)
            flux_maps = self.value(P_flux_maps, &nfluxmap, &nfluxcol)
            c_atm_0 = self.value(P_c_atm_0)
            c_atm_1 = self.value(P_c_atm_1)
            c_atm_2 = self.value(P_c_atm_2)
            c_atm_3 = self.value(P_c_atm_3)
            n_facet_x = Int(self.value(P_n_facet_x))
            n_facet_y = Int(self.value(P_n_facet_y))
            cant_type = Int(self.value(P_cant_type))
            focus_type = Int(self.value(P_focus_type))
            n_flux_days = Int(self.value(P_n_flux_days))
            delta_flux_hrs = Int(self.value(P_delta_flux_hrs))
            dni_des = self.value(P_dni_des)
            if nfluxmap % nfluxpos != 0:
                self.message(TCS_ERROR, "The number of flux maps provided does not match the number of flux map sun positions provided. Please "
                    "ensure that the dimensionality of each flux map is consistent and that one sun position is provided for "
                    "each flux map. (Sun pos. = %d, mismatch lines = %d)", nfluxpos, nfluxmap % nfluxpos)
                return -1
            self.m_flux_positions.resize(nfluxpos, VectDoub(nfposdim))
            for i in range(nfluxpos):
                for j in range(nfposdim):
                    self.m_flux_positions.at(i).at(j) = flux_positions[i * 2 + j]
        else:
            pass  # default break

        var sunpos: MatDoub
        var effs: List[Float64]

        # Second switch on run_type
        if run_type == sam_mw_pt_heliostatfield.RUN_TYPE.AUTO or run_type == sam_mw_pt_heliostatfield.RUN_TYPE.USER_FIELD:
            var sapi: AutoPilot_S
            var opt: sp_optimize
            var amb: sp_ambient
            var cost: sp_cost
            var helios: sp_heliostats
            var recs: sp_receivers
            var layout: sp_layout
            var V: var_set
            ioutil.parseDefinitionArray(V)
            opt.LoadDefaults(V)
            amb.LoadDefaults(V)
            cost.LoadDefaults(V)
            helios.resize(1)
            helios.front().LoadDefaults(V)
            recs.resize(1)
            recs.front().LoadDefaults(V)
            layout.LoadDefaults(V)
            helios.front().width = helio_width
            helios.front().height = helio_height
            helios.front().optical_error = helio_optical_error
            helios.front().active_fraction = helio_active_fraction * dens_mirror
            helios.front().reflectance = helio_reflectance
            var cmap: List[Int]
            cmap = List[Int](5)
            cmap[0] = Heliostat.CANT_METHOD.NONE
            cmap[1] = Heliostat.CANT_METHOD.AT_SLANT
            cmap[2] = cmap[3] = cmap[4] = Heliostat.CANT_METHOD.OFF_AXIS_DAYHOUR
            helios.front().cant_type = cmap[cant_type]
            # Switch inside switch for cant_type
            if cant_type == sp_heliostat.CANT_TYPE.NONE or cant_type == sp_heliostat.CANT_TYPE.ON_AXIS:

            elif cant_type == sp_heliostat.CANT_TYPE.EQUINOX:
                helios.front().cant_settings.point_day = 81
                helios.front().cant_settings.point_hour = 12.0
            elif cant_type == sp_heliostat.CANT_TYPE.SOLSTICE_SUMMER:
                helios.front().cant_settings.point_day = 172
                helios.front().cant_settings.point_hour = 12.0
            elif cant_type == sp_heliostat.CANT_TYPE.SOLSTICE_WINTER:
                helios.front().cant_settings.point_day = 355
                helios.front().cant_settings.point_hour = 12.0
            else:
                var msg: String = "Invalid Cant Type specified in SSC Heliostat Field Module. Method must be one of: \n" + \
                    "NONE(0), ON_AXIS(1), EQUINOX(2), SOLSTICE_SUMMER(3), SOLSTICE_WINTER(4).\n" + \
                    "Method specified is: " + str(cant_type) + "."
                raise spexception(msg)

            var fmap: List[Int]
            fmap = List[Int](2)
            fmap[0] = sp_heliostat.FOCUS_TYPE.FLAT
            fmap[1] = sp_heliostat.FOCUS_TYPE.AT_SLANT
            helios.front().focus_type = fmap[focus_type]
            recs.front().absorptance = rec_absorptance
            recs.front().height = rec_height
            recs.front().aspect = rec_aspect
            recs.front().q_hl_perm2 = rec_hl_perm2
            layout.q_design = q_design
            layout.dni_design = dni_des
            layout.land_max = land_max
            layout.land_min = land_min
            layout.h_tower = h_tower
            var wffile: String = weather_file
            if wffile == "":
                self.message(TCS_WARNING, "solarpilot: no weather file specified")
            var wFile: weatherfile = weatherfile(wffile)
            if not wFile.ok() or wFile.type() == weatherfile.INVALID:
                self.message(TCS_WARNING, "solarpilot: could not open weather file or invalid weather file format")
            var hdr: weather_header
            wFile.header(&hdr)
            var wf: weather_record
            amb.site_latitude = hdr.lat
            amb.site_longitude = hdr.lon
            amb.site_time_zone = hdr.tz
            amb.atten_model = sp_ambient.ATTEN_MODEL.USER_DEFINED
            amb.user_atten_coefs.clear()
            amb.user_atten_coefs.push_back(c_atm_0)
            amb.user_atten_coefs.push_back(c_atm_1)
            amb.user_atten_coefs.push_back(c_atm_2)
            amb.user_atten_coefs.push_back(c_atm_3)
            if run_type == sam_mw_pt_heliostatfield.RUN_TYPE.AUTO:
                var wfdata: List[String] = List[String]()
                wfdata.reserve(8760)
                var buf: String
                for i in range(8760):
                    if not wFile.read(&wf):
                        var msg: String = "solarpilot: could not read data line " + str(i+1) + " of 8760 in weather file"
                        self.message(TCS_WARNING, msg)
                    # Using mysnprintf is not available; we'll use format string
                    buf = str(wf.day) + "," + str(wf.hour) + "," + str(wf.month) + "," + format("{:.2f}", wf.dn) + "," + format("{:.1f}", wf.tdry) + "," + format("{:.1f}", wf.pres/1000.0) + "," + format("{:.1f}", wf.wspd)
                    wfdata.push_back(buf)
                sapi.SetDetailCallback(solarpilot_callback, self as void*)
                sapi.SetSummaryCallbackStatus(False)
                sapi.GenerateDesignPointSimulations(amb, V, wfdata)
                sapi.Setup(amb, cost, layout, helios, recs)
                sapi.CreateLayout()
                self.N_hel = Int(layout.heliostat_positions.size())
                var msg: String = "Auto-generated field: Number of heliostats " + str(self.N_hel)
                self.message(TCS_NOTICE, msg)
                helio_positions = self.allocate(P_helio_positions, self.N_hel, pos_dim)
                for i in range(self.N_hel):
                    TCS_MATRIX_INDEX(self.var(P_helio_positions), i, 0) = layout.heliostat_positions.at(i).location.x
                    TCS_MATRIX_INDEX(self.var(P_helio_positions), i, 1) = layout.heliostat_positions.at(i).location.y
                    if pos_dim == 3:
                        TCS_MATRIX_INDEX(self.var(P_helio_positions), i, 2) = layout.heliostat_positions.at(i).location.z
                sapi.SetDetailCallbackStatus(False)
            else:
                layout.heliostat_positions.clear()
                layout.heliostat_positions.resize(self.N_hel)
                for i in range(self.N_hel):
                    layout.heliostat_positions.at(i).location.x = TCS_MATRIX_INDEX(self.var(P_helio_positions), i, 0)
                    layout.heliostat_positions.at(i).location.y = TCS_MATRIX_INDEX(self.var(P_helio_positions), i, 1)
                    if pos_dim == 3:
                        layout.heliostat_positions.at(i).location.z = TCS_MATRIX_INDEX(self.var(P_helio_positions), i, 2)
                sapi.Setup(amb, cost, layout, helios, recs)
            self.value(P_land_area, layout.land_area)
            self.value(P_N_hel, Float64(self.N_hel))
            sapi.SetSummaryCallbackStatus(True)
            sapi.SetSummaryCallback(solarpilot_callback, self as void*)
            self.fluxtab.is_user_spacing = True
            self.fluxtab.n_flux_days = n_flux_days
            self.fluxtab.delta_flux_hrs = delta_flux_hrs
            if not sapi.CalculateFluxMaps(self.fluxtab, self.n_flux_x, self.n_flux_y, True):
                self.message(TCS_ERROR, "Simulation cancelled during fluxmap preparation")
                return -1
            sunpos.clear()
            effs.clear()
            var npos: Int = Int(self.fluxtab.azimuths.size())
            sunpos.reserve(npos)
            effs.reserve(npos)
            eta_map = self.allocate(P_eta_map, npos, 3, 0.0)
            self.m_flux_positions.resize(npos, VectDoub(2))
            for i in range(npos):
                var tempvec: List[Float64] = List[Float64](2, 0.0)
                tempvec[0] = self.fluxtab.azimuths.at(i) / az_scale
                tempvec[1] = self.fluxtab.zeniths.at(i) / zen_scale
                sunpos.push_back(tempvec)
                effs.push_back(self.fluxtab.efficiency.at(i) / eff_scale)
                eta_map[i * 3] = self.m_flux_positions.at(i).at(0) = self.fluxtab.azimuths.at(i) * 180.0 / pi
                eta_map[i * 3 + 1] = self.m_flux_positions.at(i).at(1) = self.fluxtab.zeniths.at(i) * 180.0 / pi
                eta_map[i * 3 + 2] = self.fluxtab.efficiency.at(i)
            flux_maps = self.allocate(P_flux_maps, self.n_flux_y * npos, self.n_flux_x)
            var f: block_t[Float64] = &self.fluxtab.flux_surfaces.front().flux_data
            var nfl: Int = f.nlayers()
            for i in range(nfl):
                for j in range(self.n_flux_y):
                    for k in range(self.n_flux_x):
                        TCS_MATRIX_INDEX(self.var(P_flux_maps), i * self.n_flux_y + j, k) = f.at(j, k, i)
        elif run_type == sam_mw_pt_heliostatfield.RUN_TYPE.USER_DATA:
            var nrows: Int = 0
            var ncols: Int = 0
            var p_map: Pointer[Float64] = self.value(P_eta_map, &nrows, &ncols)
            if ncols != 3:
                self.message(TCS_ERROR, "The heliostat field efficiency file is not formatted correctly. Type expects 3 columns"
                    " (zenith angle, azimuth angle, efficiency value) and instead has {} cols.".format(ncols))
                return -1
            sunpos.resize(nrows, VectDoub(2))
            effs.resize(nrows)
            for i in range(nrows):
                sunpos.at(i).at(0) = TCS_MATRIX_INDEX(self.var(P_eta_map), i, 0) / az_scale * pi / 180.0
                sunpos.at(i).at(1) = TCS_MATRIX_INDEX(self.var(P_eta_map), i, 1) / zen_scale * pi / 180.0
                effs.at(i) = TCS_MATRIX_INDEX(self.var(P_eta_map), i, 2) / eff_scale
        # end switch

        flux_map = self.allocate(O_flux_map, self.n_flux_y, self.n_flux_x)
        var nflux: Int = Int(self.m_flux_positions.size())
        flux_positions = self.allocate(P_flux_positions, nflux, 2)
        for i in range(nflux):
            flux_positions[i * 2] = self.m_flux_positions.at(i).at(0)
            flux_positions[i * 2 + 1] = self.m_flux_positions.at(i).at(1)

        interp_beta = self.value(P_interp_beta)
        interp_nug = self.value(P_interp_nug)
        var vgram: Powvargram = Powvargram(sunpos, effs, interp_beta, interp_nug)
        self.field_efficiency_table = GaussMarkov(sunpos, effs, vgram)
        var err_fit: Float64 = 0.0
        var npoints: Int = Int(sunpos.size())
        for i in range(npoints):
            var zref: Float64 = effs.at(i)
            var zfit: Float64 = self.field_efficiency_table.interp(sunpos.at(i))
            var dz: Float64 = zref - zfit
            err_fit += dz * dz
        err_fit = math.sqrt(err_fit)
        if err_fit > 0.01:
            self.message(TCS_WARNING, "The heliostat field interpolation function fit is poor! (err_fit=%f RMS)".format(err_fit))
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
        var solzen: Float64 = self.value(I_solzen) * pi / 180.0
        if solzen >= pi / 2.0:
            field_control = 0.0
        var solaz: Float64 = self.value(I_solaz) * pi / 180.0
        for j in range(self.n_flux_y):
            for i in range(self.n_flux_x):
                TCS_MATRIX_INDEX(self.var(O_flux_map), j, i) = 0.0
        var pparasi: Float64 = 0.0
        if (field_control > 1e-4 and self.eta_prev < 1e-4) or \
           (field_control < 1e-4 and self.eta_prev >= 1e-4) or \
           (field_control > 1e-4 and v_wind >= self.v_wind_max) or \
           (self.eta_prev > 1e-4 and self.v_wind_prev >= self.v_wind_max and v_wind < self.v_wind_max):
            pparasi = Float64(self.N_hel) * self.p_start / (step / 3600.0)
        if v_wind < self.v_wind_max and self.v_wind_prev < self.v_wind_max:
            pparasi += Float64(self.N_hel) * self.p_track * field_control
        var eta_field: Float64 = 0.0
        if solzen > (pi / 2.0 - 0.001 - self.hel_stow_deploy) or v_wind > self.v_wind_max or time < 3601:
            eta_field = 1e-6
        else:
            var sunpos: List[Float64] = List[Float64]()
            sunpos.push_back(solaz / az_scale)
            sunpos.push_back(solzen / zen_scale)
            eta_field = self.field_efficiency_table.interp(sunpos) * eff_scale
            eta_field = min(max(eta_field, 0.0), 1.0) * field_control
            var pos_now: VectDoub = VectDoub(sunpos)
            var distances: List[Float64] = List[Float64]()
            var indices: List[Int] = List[Int]()
            for i in range(Int(self.m_flux_positions.size())):
                distances.push_back(self.rdist(&pos_now, &self.m_flux_positions.at(i)))
                indices.push_back(i)
            quicksort(distances, indices)
            var avepoints: Float64 = 0.0
            var npt: Int = 6
            for i in range(npt):
                avepoints += distances.at(i)
            avepoints *= 1.0 / Float64(npt)
            var weights: VectDoub = VectDoub(npt)
            var normalizer: Float64 = 0.0
            for i in range(npt):
                var w: Float64 = math.exp(-math.pow(distances.at(i) / avepoints, 2.0))
                weights.at(i) = w
                normalizer += w
            for i in range(npt):
                weights.at(i) *= 1.0 / normalizer
            for k in range(npt):
                var imap: Int = indices.at(k)
                for j in range(self.n_flux_y):
                    for i in range(self.n_flux_x):
                        TCS_MATRIX_INDEX(self.var(O_flux_map), j, i) += \
                            TCS_MATRIX_INDEX(self.var(P_flux_maps), imap * self.n_flux_y + j, i) * weights.at(k)
        self.value(O_pparasi, pparasi / 1e3)
        self.value(O_eta_field, eta_field)
        return 0

    def converged(inout self, time: Float64) -> Int:
        self.eta_prev = self.value(O_eta_field)
        self.v_wind_prev = self.value(I_v_wind)
        return 0

    def relay_message(inout self, msg: String, percent: Float64) -> Int:
        return 0 if self.progress(percent, msg) else -1

    def rdist(self, p1: VectDoub, p2: VectDoub, dim: Int = 2) -> Float64:
        var d: Float64 = 0.0
        for i in range(dim):
            var rd: Float64 = p1.at(i) - p2.at(i)
            d += rd * rd
        return math.sqrt(d)

# Static callback function
def solarpilot_callback(siminfo: simulation_info, data: void*) -> bool:
    var cm: sam_mw_pt_heliostatfield = (data as sam_mw_pt_heliostatfield)
    if cm is None:
        return false
    var simprogress: Float64 = Float64(siminfo.getCurrentSimulation()) / Float64(max(siminfo.getTotalSimulationCount(), 1))
    return cm.relay_message(*siminfo.getSimulationNotices(), simprogress * 100.0) == 0

# Implementation macro equivalent
TCS_IMPLEMENT_TYPE(sam_mw_pt_heliostatfield, "Heliostat field with SolarPILOT", "Mike Wagner", 1, sam_mw_pt_heliostatfield_variables, None, 1)
/*******************************************************************************************************
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  ("Alliance") under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
*
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
*
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
*
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as "System Advisor Model" or "SAM". Except
*  to comply with the foregoing, the terms "System Advisor Model", "SAM", or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
*
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/

from mod_base import spvar, spout, spbase, spexception, matrix_t, WeatherData
from Toolbox import sp_point
from string_util import my_to_string

let PI: Float64 = 3.14159265358979311600
let R2D: Float64 = 57.29577951308232286465
let D2R: Float64 = 0.01745329251994329547

struct var_ambient:
    var atm_coefs: spvar[matrix_t[Float64]]  # [none] Atmospheric attenuation coefficients for user-defined analysis
    var atm_model: spvar[String]  # [none] Atmospheric attenuation model {0=25km Barstow, 1 = 5km Barstow, 2 = user defined}
    struct ATM_MODEL:
        enum EN:
            DELSOL3_CLEAR_DAY = 0
            DELSOL3_HAZY_DAY = 1
            USERDEFINED = 2
    var class_name: spvar[String]  # [none] Class name
    var del_h2o: spvar[Float64]  # [mm H2O] Atmospheric precipitable water depth for use in the Allen insolation model
    var dni_layout: spvar[Float64]  # [W/m2] DNI to use during all layout calculations. CONSTANT model only.
    var dpres: spvar[Float64]  # [atm] Local ambient pressure relative to sea-level pressure
    var elevation: spvar[Float64]  # [m] Plant mean elevation
    var insol_type: spvar[String]  # [none] Model used to determine insolation as a function of time
    struct INSOL_TYPE:
        enum EN:
            WEATHER_FILE_DATA = -1
            MEINEL_MODEL = 0
            HOTTEL_MODEL = 1
            CONSTANT_VALUE = 2
            ALLEN_MODEL = 3
            MOON_MODEL = 4
    var latitude: spvar[Float64]  # [deg] Plant latitude
    var loc_city: spvar[String]  # [none] City or place name for weather station (informational only)
    var loc_state: spvar[String]  # [none] State name for weather station (informational only)
    var longitude: spvar[Float64]  # [deg] Plant longitude
    var sun_csr: spvar[Float64]  # [none] Ratio of solar flux contained in the circumsolar ring over the solar disc flux
    var sun_pos_map: spvar[matrix_t[Float64]]  # [[deg,deg]] Map of sun positions to use for calculations
    var sun_rad_limit: spvar[Float64]  # [mrad] Half-angle of sunshape size (4.65mrad for Pillbox, 2.73mrad for Gaussian)
    var sun_type: spvar[String]  # [none] Sunshape model - {0=point sun, 1=limb darkened sun, 2=square wave sun, 3=user sun}
    struct SUN_TYPE:
        enum EN:
            PILLBOX_SUN = 2
            GAUSSIAN_SUN = 4
            LIMBDARKENED_SUN = 1
            POINT_SUN = 0
            BUIE_CSR = 5
            USER_SUN = 3
    var time_zone: spvar[Float64]  # [hr] Time zone
    var user_sun: spvar[matrix_t[Float64]]  # [[deg,deg]] Array of intensity at various angles from the centroid of the sun
    var weather_file: spvar[String]  # [none] Weather file to use for analysis
    var wf_data: spvar[WeatherData]  # [none] Data entries in the weather file
    var atm_atten_est: spout[Float64]  # [%] Average solar field attenuation due to atmospheric scattering
    var sim_time_step: spout[Float64]  # [sec] Simulation weather data time step
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_financial:
    var class_name: spvar[String]  # [none] Class name
    var contingency_rate: spvar[Float64]  # [%] Fraction of the direct capital costs added to account for contingency
    var fixed_cost: spvar[Float64]  # [$] Cost that does not scale with any plant parameter
    var heliostat_spec_cost: spvar[Float64]  # [$/m2] Cost per square meter of heliostat aperture area of the heliostat field
    var is_pmt_factors: spvar[Bool]  # [] Enable or disable the use of weighting factors in determining field layout
    var land_spec_cost: spvar[Float64]  # [$/acre] Cost of land per acre including the footprint of the land occupied by the entire plant.
    var pmt_factors: spvar[List[Float64]]  # [none] Relative value of electricity produced during this period compared to the average
    var rec_cost_exp: spvar[Float64]  # [none] Exponent in the equation (total cost) = (ref. cost) * ( (area) / (ref. area) ) ^ X
    var rec_ref_area: spvar[Float64]  # [m2] Receiver surface area corresponding to the receiver reference cost
    var rec_ref_cost: spvar[Float64]  # [$] Cost of the receiver at the sizing indicated by the reference receiver area
    var sales_tax_frac: spvar[Float64]  # [%] Fraction of the direct capital costs for which sales tax applies
    var sales_tax_rate: spvar[Float64]  # [%] Sales tax rate applid to the total direct capital cost
    var site_spec_cost: spvar[Float64]  # [$/m2] Cost per square meter of heliostat aperture area of site improvements
    var tower_exp: spvar[Float64]  # [none] Exponent in the equation (total cost) = (fixed cost) * exp( X * (tower height) )
    var tower_fixed_cost: spvar[Float64]  # [$] Fixed tower cost - used as the basis for scaling tower cost as a function of height
    var weekday_sched: spvar[String]  # [] Weekday dispatch period schedule
    var weekend_sched: spvar[String]  # [] Weekend dispatch period schedule
    var wiring_user_spec: spvar[Float64]  # [$/m2] Cost of wiring per square meter of heliostat aperture area
    var contingency_cost: spout[Float64]  # [$] Contingency cost
    var heliostat_cost: spout[Float64]  # [$] Heliostat field cost
    var land_cost: spout[Float64]  # [$] Land cost
    var pricing_array: spout[List[Float64]]  # [none] Yearly time series schedule of price multipliers to incentivize electricity sales at particular times
    var rec_cost: spout[Float64]  # [$] Receiver cost
    var sales_tax_cost: spout[Float64]  # [$] Sales tax cost
    var schedule_array: spout[List[Int]]  # [none] Yearly time series schedule of TOU periods
    var site_cost: spout[Float64]  # [$] Site improvements cost
    var total_direct_cost: spout[Float64]  # [$] Sum of all direct costs
    var total_indirect_cost: spout[Float64]  # [$] Sum of all indirect costs
    var total_installed_cost: spout[Float64]  # [$] Sum of direct and indirect costs
    var tower_cost: spout[Float64]  # [$] Tower cost
    var wiring_cost: spout[Float64]  # [$] Wiring cost
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_fluxsim:
    var aim_method: spvar[String]  # [] Method for determining the aim point for each heliostat
    struct AIM_METHOD:
        enum EN:
            SIMPLE_AIM_POINTS = 0
            SIGMA_AIMING = 1
            PROBABILITY_SHIFT = 2
            IMAGE_SIZE_PRIORITY = 3
            KEEP_EXISTING = 4
            FREEZE_TRACKING = 5
    var class_name: spvar[String]  # [none] Class name
    var cloud_depth: spvar[Float64]  # [m] Depth of the cloud shape
    var cloud_loc_x: spvar[Float64]  # [m] Base location of the cloud(s) relative to the tower position - X dimension
    var cloud_loc_y: spvar[Float64]  # [m] Base location of the cloud(s) relative to the tower position - Y dimension
    var cloud_opacity: spvar[Float64]  # [none] Fraction of DNI obfuscated by a cloud shadow
    var cloud_sep_depth: spvar[Float64]  # [] Cloud pattern depth spacing
    var cloud_sep_width: spvar[Float64]  # [] Cloud pattern width spacing
    var cloud_shape: spvar[String]  # [] Shape used to model the cloud shadow
    struct CLOUD_SHAPE:
        enum EN:
            ELLIPTICAL = 0
            RECTANGULAR = 1
            FRONT = 2
    var cloud_skew: spvar[Float64]  # [deg] Angle between North and the depth direction (-180 to +180 with clockwise positive)
    var cloud_width: spvar[Float64]  # [m] Width of the cloud shape
    var flux_data: spvar[String]  # [] 2D matrix of flux data
    var flux_day: spvar[Int]  # [] Day of the month for the flux simulation
    var flux_dist: spvar[String]  # [] Sampling basis for random positioning. Non-uniform distributions are weighted away from the center.
    struct FLUX_DIST:
        enum EN:
            TRIANGULAR = 0
            NORMAL = 1
            UNIFORM = 2
    var flux_dni: spvar[Float64]  # [W/m2] Direct Normal Irradiation at the specified simulation point
    var flux_hour: spvar[Float64]  # [hr] Hour of the day for the flux simulation
    var flux_model: spvar[String]  # [none] Desired flux simulation tool. Not all geometries can be simulated using the Hermite approximation.
    struct FLUX_MODEL:
        enum EN:
            HERMITE_ANALYTICAL = 0
            SOLTRACE = 1
    var flux_month: spvar[Int]  # [] Month of the year for the flux simulation
    var flux_solar_az_in: spvar[Float64]  # [] Solar azimuth angle to use for the flux simulation
    var flux_solar_el_in: spvar[Float64]  # [] Solar elevation angle to use for the flux simulation
    var flux_time_type: spvar[String]  # [none] Method for specifying the desired flux simulation time.
    struct FLUX_TIME_TYPE:
        enum EN:
            SUN_POSITION = 0
            HOURDAY = 1
    var is_autoscale: spvar[Bool]  # [none] Autoscale the Z-axis of the contour plot
    var is_cloud_pattern: spvar[Bool]  # [] Create a pattern based on the specified cloud
    var is_cloud_symd: spvar[Bool]  # [] Mirror the cloud pattern below the width axis
    var is_cloud_symw: spvar[Bool]  # [] Mirror the cloud pattern to the left of the depth axis
    var is_cloudy: spvar[Bool]  # [] Enable simulation for a cloud transient
    var is_load_raydata: spvar[Bool]  # [none] Load heliostat field raytrace data from an existing file
    var is_optical_err: spvar[Bool]  # [] Include the reflector optical error sources in the SolTrace simulation
    var is_save_raydata: spvar[Bool]  # [none] Save heliostat field raytrace data to a file for future re-use
    var is_sunshape_err: spvar[Bool]  # [] Include the sun shape error in the SolTrace simulation
    var max_rays: spvar[Int]  # [none] The maximum number of generated rays allowed before terminating the simulation. Overrides the desired rays setting.
    var min_rays: spvar[Int]  # [none] The minimum number of ray hits on the receiver before terminating the simulation.
    var norm_dist_sigma: spvar[Float64]  # [] Size of the standard distribution relative to half of the height of the receiver.
    var plot_zmax: spvar[Float64]  # [none] Z-axis maximum value
    var plot_zmin: spvar[Float64]  # [none] Z-axis minimum value
    var raydata_file: spvar[String]  # [none] Location and file of the ray data
    var save_data: spvar[Bool]  # [] Save the results for each ray
    var save_data_loc: spvar[String]  # [] Choose a location to save the ray data
    var seed: spvar[Int]  # [none] The seed for the random number generator
    var sigma_limit_x: spvar[Float64]  # [] Minimum distance (std. dev.) between optical center of heliostat image and the receiver edge in the receiver-X direction
    var sigma_limit_y: spvar[Float64]  # [none] Minimum distance (std. dev.) between optical center of heliostat image and the receiver edge in the receiver-Y direction
    var x_res: spvar[Int]  # [none] Number of flux test points per panel (maximum) in the vertical direction for the flux simulation
    var y_res: spvar[Int]  # [none] Number of flux test points per panel (maximum) in the horizontal direction for the flux simulation
    var flux_solar_az: spout[Float64]  # [deg] Solar azimuth angle to use for the flux simulation
    var flux_solar_el: spout[Float64]  # [deg] Solar elevation angle to use for the flux simulation
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_heliostat:
    var cant_day: spvar[Int]  # [day] Day of the year used for canting the heliostats (1-365)
    var cant_hour: spvar[Float64]  # [hr] Hours past noon at which the mirror panels are canted (-12 to 12)
    var cant_method: spvar[String]  # [none] Integer to specify the canting method {0=none, -1=Cant on-axis equal to slant range, 1=user-defined on-axis, 3=user-defined off-axis at hour + day}
    struct CANT_METHOD:
        enum EN:
            NO_CANTING = 0
            ONAXIS_AT_SLANT = -1
            ONAXIS_USERDEFINED = 1
            OFFAXIS_DAY_AND_HOUR = 3
            USERDEFINED_VECTOR = 4
    var cant_rad_scaled: spvar[Float64]  # [none] Canting radius value (absolute value if radius is not scaled, multiplied by tower height if scaled)
    var cant_vect_i: spvar[Float64]  # [none] Canting vector - x-component
    var cant_vect_j: spvar[Float64]  # [none] Canting vector y-component
    var cant_vect_k: spvar[Float64]  # [none] Canting vector z-component
    var cant_vect_scale: spvar[Float64]  # [m] Value to scale the canting unit vector to determine actual canting magnitude
    var cbdata: spvar[Pointer[None]]  # [none] Data pointer for UI page
    var class_name: spvar[String]  # [none] Class name
    var diameter: spvar[Float64]  # [m] Diameter of the heliostat structure (round heliostats only)
    var err_azimuth: spvar[Float64]  # [rad] Standard deviation of the normal error dist. of the azimuth angle
    var err_elevation: spvar[Float64]  # [rad] Standard deviation of the normal error dist. of the elevation angle
    var err_reflect_x: spvar[Float64]  # [rad] error in reflected vector (horiz.) caused by atmospheric refraction, tower sway, etc.
    var err_reflect_y: spvar[Float64]  # [rad] error in reflected vector (vert.) caused by atmospheric refraction, tower sway, etc.
    var err_surface_x: spvar[Float64]  # [rad] Std.dev. of the normal error dist. of the reflective surface normal in the X (horizontal)
    var err_surface_y: spvar[Float64]  # [rad] Same as above, but in the vertical direction
    var focus_method: spvar[String]  # [none] The focusing method {0=Flat, 1=Each at slant, 2=Average of group, 3=User defined}
    struct FOCUS_METHOD:
        enum EN:
            FLAT = 0
            AT_SLANT = 1
            GROUP_AVERAGE = 2
            USERDEFINED = 3
    var height: spvar[Float64]  # [m] Height of the heliostat structure
    var helio_name: spvar[String]  # [] Heliostat template name
    var id: spvar[Int]  # [none] Unique ID number for the heliostat template
    var is_cant_rad_scaled: spvar[Bool]  # [] The cant radius scales with tower height
    var is_cant_vect_slant: spvar[Bool]  # [none] Multiply the canting vector by the slant range
    var is_enabled: spvar[Bool]  # [] Is template enabled?
    var is_faceted: spvar[Bool]  # [none] The number of reflective panels per heliostat is greater than 1
    var is_focal_equal: spvar[Bool]  # [none] Both the X and Y focal lengths will use a single value as indicated by the X focal length
    var is_round: spvar[String]  # [none] Is the heliostat round (true) or rectangular (false)
    struct IS_ROUND:
        enum EN:
            RECTANGULAR = 0
            ROUND = 1
    var is_xfocus: spvar[Bool]  # [none] Reflector is focused in with respect to the heliostat X axis
    var is_yfocus: spvar[Bool]  # [none] Reflector is focused in with respect to the heliostat Y axis
    var n_cant_x: spvar[Int]  # [] Number of cant panels in the X direction
    var n_cant_y: spvar[Int]  # [] Number of cant panels in the Y direction
    var reflect_ratio: spvar[Float64]  # [none] Ratio of mirror area to total area of the heliostat defined by wm x hm
    var reflectivity: spvar[Float64]  # [none] Average reflectivity (clean) of the mirrored surface
    var rvel_max_x: spvar[Float64]  # [rad/s] maximum rotational velocity about the x axis
    var rvel_max_y: spvar[Float64]  # [rad/s] maximum rotational velocity about the z axis
    var soiling: spvar[Float64]  # [none] Average soiling factor
    var st_err_type: spvar[String]  # [none] Error distribution of the reflected rays from the heliostat optical surface
    struct ST_ERR_TYPE:
        enum EN:
            GAUSSIAN = 0
            PILLBOX = 1
    var temp_az_max: spvar[Float64]  # [deg] Angular boundary for heliostat geometry - on the clockwise side of the region
    var temp_az_min: spvar[Float64]  # [deg] Angular boundary for heliostat geometry - on the counter-clockwise side of the region
    var temp_rad_max: spvar[Float64]  # [none] Maximum radius at which this heliostat geometry can be used
    var temp_rad_min: spvar[Float64]  # [none] Minimum radius at which this heliostat geometry can be used
    var template_order: spvar[Int]  # [none] template_order
    var track_method: spvar[String]  # [none] Specify how often heliostats update their tracking position 
    struct TRACK_METHOD:
        enum EN:
            CONTINUOUS = 0
            PERIODIC = 1
    var track_period: spvar[Float64]  # [sec] The amount of time between tracking updates for each heliostat
    var type: spvar[Int]  # [] Integer used to group heliostats into geometries within a field, (e.g. 5 different focal length designs)
    var width: spvar[Float64]  # [m] Width of the heliostat structure
    var x_focal_length: spvar[Float64]  # [m] Reflector focal length with respect to the heliostat X (horizontal) axis
    var x_gap: spvar[Float64]  # [m] Separation between panels in the horizontal direction
    var y_focal_length: spvar[Float64]  # [m] Reflector focal length with respect to the heliostat Y (vertical) axis
    var y_gap: spvar[Float64]  # [m] Separation between panels in the vertical direction
    var area: spout[Float64]  # [m2] Aperture area including geometry penalties and gaps in the structure
    var cant_mag_i: spout[Float64]  # [none] Total canting vector - i
    var cant_mag_j: spout[Float64]  # [none] Total canting vector - j
    var cant_mag_k: spout[Float64]  # [none] Total canting vector - k
    var cant_norm_i: spout[Float64]  # [none] Normalized canting vector - i
    var cant_norm_j: spout[Float64]  # [none] Normalized canting vector - j
    var cant_norm_k: spout[Float64]  # [none] Normalized canting vector - k
    var cant_radius: spout[Float64]  # [m] Radius for canting focal point assuming on-axis canting
    var cant_sun_az: spout[Float64]  # [deg] Sun azimuth angle at the moment the cant panels are focused on the receiver
    var cant_sun_el: spout[Float64]  # [deg] Sun elevation angle at the moment the cant panels are focused on the receiver
    var err_total: spout[Float64]  # [rad] Total convolved optical error in the reflected beam from the above sources
    var r_collision: spout[Float64]  # [m] Distance between heliostat center and maximum radial extent of structure
    var ref_total: spout[Float64]  # [none] Effective reflectance - product of the mirror reflectance and soiling
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_land:
    var class_name: spvar[String]  # [none] Class name
    var exclusions: spvar[List[List[sp_point]]]  # [] Vector of arrays that specify the regions of land to exclude in the heliostat layout
    var import_tower_lat: spvar[Float64]  # [deg] Imported land boundary tower latitude
    var import_tower_lon: spvar[Float64]  # [deg] Imported land boundary tower longitude
    var import_tower_set: spvar[Bool]  # [none] Has the tower location been set for imported land geometries?
    var inclusions: spvar[List[List[sp_point]]]  # [] Vector of arrays that specify the regions of land to include in the heliostat layout
    var is_bounds_array: spvar[Bool]  # [none] Land boundary is specified by points array
    var is_bounds_fixed: spvar[Bool]  # [none] Land boundary has fixed limits (not more than | not less than)
    var is_bounds_scaled: spvar[Bool]  # [none] Land boundary scales with tower hight value
    var is_exclusions_relative: spvar[Bool]  # [none] Shift the exclusion regions along with the tower offset values
    var land_const: spvar[Float64]  # [acre] Fixed land area that is added to the area occupied by heliostats
    var land_mult: spvar[Float64]  # [none] Factor multiplying the land area occupied by heliostats
    var max_fixed_rad: spvar[Float64]  # [m] Outer land boundary for circular land plot
    var max_scaled_rad: spvar[Float64]  # [none] Maximum radius (in units of tower height) for positioning of the heliostats
    var min_fixed_rad: spvar[Float64]  # [m] Inner land boundary for circular land plot
    var min_scaled_rad: spvar[Float64]  # [none] Minimum radius (in units of tower height) for positioning of the heliostats
    var tower_offset_x: spvar[Float64]  # [m] Displacement of the tower in X relative to the X-positions specified in the land table
    var tower_offset_y: spvar[Float64]  # [m] Displacement of the tower in Y relative to the Y-positions specified in the land table
    var bound_area: spout[Float64]  # [acre] Land area occupied by heliostats. This value is the area of a convex hull surrounding the heliostat positions.
    var land_area: spout[Float64]  # [acre] Land area, including solar field and multiplying factor
    var radmax_m: spout[Float64]  # [m] Calculated maximum distance between tower and last row of heliostats
    var radmin_m: spout[Float64]  # [m] Calculated minimum distance between tower and first row of heliostats
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_optimize:
    var algorithm: spvar[String]  # [] Optimization algorithm
    struct ALGORITHM:
        enum EN:
            BOBYQA = 0
            COBYLA = 1
            NEWOUA = 2
            NELDERMEAD = 3
            SUBPLEX = 4
            RSGS = 5
    var class_name: spvar[String]  # [] 
    var converge_tol: spvar[Float64]  # [none] Relative change in the objective function below which convergence is achieved
    var flux_penalty: spvar[Float64]  # [none] Relative weight in the objective function given to flux intensity over the allowable limit
    var max_desc_iter: spvar[Int]  # [none] Maximum number of steps along the direction of steepest descent before recalculating the response surface
    var max_gs_iter: spvar[Int]  # [none] Maximum number of golden section iterations to refine the position of a local minimum
    var max_iter: spvar[Int]  # [none] Maximum number of times the optimization can iterate
    var max_step: spvar[Float64]  # [none] Maximum total relative step size during optimization
    var power_penalty: spvar[Float64]  # [none] Relative weight in the objective function given to power to the receiver below the required minimum
    var aspect_display: spout[Float64]  # [none] Current receiver aspect ratio (H/W)
    var gs_refine_ratio: spout[Float64]  # [none] The relative step size of the refined area during refinement simulations. More iterations will allow greater refinement
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_parametric:
    var class_name: spvar[String]  # [none] Class name
    var eff_file_name: spvar[String]  # [] Name of the output file containing the efficiency matrix
    var flux_file_name: spvar[String]  # [] Name of the output file containing the fluxmap data
    var fluxmap_format: spvar[String]  # [] Dimensions of the fluxmap data (rows,cols)
    struct FLUXMAP_FORMAT:
        enum EN:
            SAM_FORMAT = 0
            N12X10_ARRAY = 1
            SPECIFIED_DIMENSIONS = 2
    var is_fluxmap_norm: spvar[Bool]  # [] Flux data is reported as normalized
    var par_save_field_img: spvar[Bool]  # [none] Save field efficiency image
    var par_save_flux_dat: spvar[Bool]  # [none] Save receiver flux data
    var par_save_flux_img: spvar[Bool]  # [none] Save receiver flux image
    var par_save_helio: spvar[Bool]  # [none] Save detailed heliostat performance data for each run
    var par_save_summary: spvar[Bool]  # [none] Save detailed system performance data to a file for each run
    var sam_grid_format: spvar[String]  # [none] SAM data grid format
    struct SAM_GRID_FORMAT:
        enum EN:
            AUTO_SPACING = 0
            EVEN_GRID = 1
    var sam_out_dir: spvar[String]  # [] Output directory
    var upar_save_field_img: spvar[Bool]  # [none] Save field efficiency image
    var upar_save_flux_dat: spvar[Bool]  # [none] Save receiver flux data
    var upar_save_flux_img: spvar[Bool]  # [none] Save receiver flux image
    var upar_save_helio: spvar[Bool]  # [none] Save detailed heliostat performance data for each run
    var upar_save_summary: spvar[Bool]  # [none] Save detailed system performance data to a file for each run
    var user_par_values: spvar[String]  # [none] User parametric values
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_receiver:
    var absorptance: spvar[Float64]  # [none] Energy absorbed by the receiver surface before accounting for radiation/convection losses
    var accept_ang_type: spvar[String]  # [none] Receiver angular acceptance window defines angles about the aperture normal, can be rectangular or elliptical shape
    struct ACCEPT_ANG_TYPE:
        enum EN:
            RECTANGULAR = 0
            ELLIPTICAL = 1
    var accept_ang_x: spvar[Float64]  # [deg] Acceptance angle of the receiver in the horizontal direction (in aperture coordinates)
    var accept_ang_y: spvar[Float64]  # [deg] Acceptance angle of the receiver in the vertical direction (in aperture coordinates)
    var aperture_type: spvar[String]  # [] The shape of the receiver aperture
    struct APERTURE_TYPE:
        enum EN:
            RECTANGULAR = 0
    var cbdata: spvar[Pointer[None]]  # [none] Data pointer for UI page
    var class_name: spvar[String]  # [none] Class name
    var id: spvar[Int]  # [] Template ID
    var is_aspect_opt: spvar[Bool]  # [] Optimize receiver aspect ratio (height / width)
    var is_enabled: spvar[Bool]  # [] Is template enabled?
    var is_open_geom: spvar[Bool]  # [] If true, the receiver is represented by an arc rather than a closed circle/polygon
    var is_polygon: spvar[Bool]  # [] Receiver geometry is represented as discrete polygon of N panels rather than continuous arc
    var n_panels: spvar[Int]  # [none] Number of receiver panels (polygon facets) for a polygonal receiver geometry
    var panel_rotation: spvar[Float64]  # [deg] Azimuth angle between the normal vector to the primary 'north' panel and North
    var peak_flux: spvar[Float64]  # [kW/m2] Maximum allowable flux intensity on any portion of the receiver surface
    var piping_loss_coef: spvar[Float64]  # [kW/m] Loss per meter of tower height
    var piping_loss_const: spvar[Float64]  # [kW] Constant thermal loss due to piping - doesn't scale with tower height
    var rec_azimuth: spvar[Float64]  # [deg] Receiver azimuth orientation: 0 deg is north, positive clockwise
    var rec_cav_cdepth: spvar[Float64]  # [m] Offset of centroid of cavity absorber surface from the aperture plane. (Positive->Increased depth)
    var rec_cav_rad: spvar[Float64]  # [m] Radius of the receiver cavity absorbing surface
    var rec_diameter: spvar[Float64]  # [m] Receiver diameter for cylindrical receivers
    var rec_elevation: spvar[Float64]  # [deg] Receiver elevation orientation: 0 deg to the horizon, negative rotating downward
    var rec_height: spvar[Float64]  # [m] Height of the absorbing component
    var rec_name: spvar[String]  # [] Receiver template name
    var rec_offset_x: spvar[Float64]  # [m] Offset of receiver center in the East(+)/West(-) direction from the tower
    var rec_offset_y: spvar[Float64]  # [m] Offset of receiver center in the North(+)/South(-) direction from the tower
    var rec_offset_z: spvar[Float64]  # [m] Offset of the receiver center in the vertical direction, positive upwards
    var rec_type: spvar[String]  # [none] Receiver geometrical configuration
    struct REC_TYPE:
        enum EN:
            EXTERNAL_CYLINDRICAL = 0
            FLAT_PLATE = 2
    var rec_width: spvar[Float64]  # [m] Receiver width for cavity or flat receivers
    var span_max: spvar[Float64]  # [deg] Maximum (CW) bound of the arc defining the receiver surface
    var span_min: spvar[Float64]  # [deg] Minimum (CCW) bound of the arc defining the receiver surface
    var therm_loss_base: spvar[Float64]  # [kW/m2] Thermal loss from the receiver at design-point conditions
    var therm_loss_load: spvar[matrix_t[Float64]]  # [none] Temperature-dependant thermal loss
    var therm_loss_wind: spvar[matrix_t[Float64]]  # [none] Wind speed-dependant thermal loss
    var absorber_area: spout[Float64]  # [m2] Effective area of the receiver absorber panels
    var optical_height: spout[Float64]  # [m] Calculated height of the centerline of the receiver above the plane of the heliostats
    var piping_loss: spout[Float64]  # [MW] Thermal loss from non-absorber receiver piping
    var rec_aspect: spout[Float64]  # [none] Ratio of receiver height to width
    var therm_eff: spout[Float64]  # [none] Receiver calculated thermal efficiency
    var therm_loss: spout[Float64]  # [MW] Receiver thermal loss at design
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_solarfield:
    var accept_max: spvar[Float64]  # [deg] Upper bound of the angular range containing the heliostat field
    var accept_min: spvar[Float64]  # [deg] Lower bound of the angular range containing the heliostat field
    var az_spacing: spvar[Float64]  # [none] Azimuthal spacing factor for the first row of heliostats after a reset. Heliostats separated by heliostat width times this factor.
    var class_name: spvar[String]  # [none] Class name
    var des_sim_detail: spvar[String]  # [none] Simulation detail for placing heliostats (see definitions in options spreadsheet)
    struct DES_SIM_DETAIL:
        enum EN:
            SUBSET_OF_DAYSHOURS = 2
            SINGLE_SIMULATION_POINT = 1
            DO_NOT_FILTER_HELIOSTATS = 0
            ANNUAL_SIMULATION = 3
            LIMITED_ANNUAL_SIMULATION = 4
            REPRESENTATIVE_PROFILES = 5
            EFFICIENCY_MAP__ANNUAL = 6
    var des_sim_ndays: spvar[Int]  # [none] For limited annual simulation, the number of evenly spaced days to simulate
    var des_sim_nhours: spvar[Int]  # [none] Simulation will run with the specified hourly frequency (1=every hour, 2=every other hour...)
    var dni_des: spvar[Float64]  # [W/m2] DNI value at which the design-point receiver thermal power is achieved
    var hsort_method: spvar[String]  # [none] Select the criteria by which heliostats will be included in the solar field layout.
    struct HSORT_METHOD:
        enum EN:
            POWER_TO_RECEIVER = 0
            TOTAL_EFFICIENCY = 1
            COSINE_EFFICIENCY = 2
            ATTENUATION_EFFICIENCY = 3
            INTERCEPT_EFFICIENCY = 4
            BLOCKING_EFFICIENCY = 5
            SHADOWING_EFFICIENCY = 6
            TOUWEIGHTED_POWER = 7
    var interaction_limit: spvar[Float64]  # [helio-ht] Multiply the heliostat height to determine the radius of possible interaction with other heliostats
    var is_opt_zoning: spvar[Bool]  # [none] Enables grouping of heliostats into zones for intercept factor calculation during layout only
    var is_prox_filter: spvar[Bool]  # [none] Post-process the layout to select heliostats that are closer to the tower.
    var is_sliprow_skipped: spvar[Bool]  # [none] Radial gap before first row after slip plane is sufficient to eliminate blocking
    var is_tht_opt: spvar[Bool]  # [none] Vary the tower height during optimization to identify optimal level?
    var layout_data: spvar[String]  # [] Layout data in string form
    var layout_method: spvar[String]  # [none] Field layout method
    struct LAYOUT_METHOD:
        enum EN:
            RADIAL_STAGGER = 1
            CORNFIELD = 2
            USERDEFINED = 3
    var max_zone_size_az: spvar[Float64]  # [tower-ht] Maximum zone size (azimuthal direction) for grouping optical intercept factor calculations
    var max_zone_size_rad: spvar[Float64]  # [tower-ht] Maximum zone size (radial direction) for grouping optical intercept factor calculations
    var min_zone_size_az: spvar[Float64]  # [tower-ht] Minimum zone size (azimuthal direction) for grouping optical intercept factor calculations
    var min_zone_size_rad: spvar[Float64]  # [tower-ht] Minimum zone size (radial direction) for grouping optical intercept factor calculations
    var prox_filter_frac: spvar[Float64]  # [none] Fraction of heliostats to subject to proximity filter.
    var q_des: spvar[Float64]  # [MWt] Design thermal power delivered from the solar field
    var rad_spacing_method: spvar[String]  # [none] Method for determining radial spacing during field layout for radial-stagger
    struct RAD_SPACING_METHOD:
        enum EN:
            NO_BLOCKINGDENSE = 3
            ELIMINATE_BLOCKING = 2
            DELSOL_EMPIRICAL_FIT = 1
    var row_spacing_x: spvar[Float64]  # [none] Separation between adjacent heliostats in the X-direction, multiplies heliostat radius
    var row_spacing_y: spvar[Float64]  # [none] Separation between adjacent heliostats in the Y-direction, multiplies heliostat radius
    var shadow_height: spvar[Float64]  # [m] Effective tower height for shadowing calculations
    var shadow_width: spvar[Float64]  # [m] Effective tower diameter for shadowing calculations
    var slip_plane_blocking: spvar[Float64]  # [none] Allowable blocking in slip plane
    var spacing_reset: spvar[Float64]  # [none] For heliostat layout - ratio of maximum to initial azimuthal spacing before starting new compressed row
    var sun_az_des_user: spvar[Float64]  # [deg] Solar azimuth angle at the design point
    var sun_el_des_user: spvar[Float64]  # [deg] Solar elevation angle at the design point
    var sun_loc_des: spvar[String]  # [none] Sun location when thermal power rating is achieved
    struct SUN_LOC_DES:
        enum EN:
            SUMMER_SOLSTICE = 0
            EQUINOX = 1
            WINTER_SOLSTICE = 2
            ZENITH = 3
            OTHER = 4
    var temp_which: spvar[String]  # [none] Select the heliostat geometry template that will be used in the layout
    struct TEMP_WHICH:
        enum EN:

    var template_rule: spvar[String]  # [] Method for distributing heliostat geometry templates in the field
    struct TEMPLATE_RULE:
        enum EN:
            USE_SINGLE_TEMPLATE = 0
            SPECIFIED_RANGE = 1
            EVEN_RADIAL_DISTRIBUTION = 2
    var tht: spvar[Float64]  # [m] Average height of the tower receiver centerline above the base heliostat pivot point elevation
    var trans_limit_fact: spvar[Float64]  # [none] Determines the point at which close-packing switches to standard layout. =1 at no-blocking transition limit.
    var xy_field_shape: spvar[String]  # [] Enforced shape of the heliostat field
    struct XY_FIELD_SHAPE:
        enum EN:
            HEXAGON = 0
            RECTANGLE = 1
            UNDEFINED = 2
    var xy_rect_aspect: spvar[Float64]  # [none] Aspect ratio of the rectangular field layout (height in Y / width in X)
    var zone_div_tol: spvar[Float64]  # [none] Allowable variation in optical intercept factor within a layout zone
    var rec_area: spout[Float64]  # [m2] Surface area from all receivers included in the solar field
    var sf_area: spout[Float64]  # [m2] The sum of all heliostat reflector area in the current layout
    var sim_step_data: spout[WeatherData]  # [none] Data used for design simulations
    var sun_az_des: spout[Float64]  # [deg] Calculated design-point solar azimuth
    var sun_el_des: spout[Float64]  # [deg] Calculated design-point solar elevation
    def addptrs(inout self, inout pmap: Dict[String, Pointer[spbase]]):

struct var_map:
    var amb: var_ambient
    var fin: var_financial
    var flux: var_fluxsim
    var land: var_land
    var opt: var_optimize
    var par: var_parametric
    var sf: var_solarfield
    var hels: List[var_heliostat]
    var recs: List[var_receiver]
    var _varptrs: Dict[String, Pointer[spbase]]

    def __init__(inout self):
        self.reset()

    def __init__(inout self, other: var_map):
        self.reset()
        self.copy(other)

    def copy(inout self, inout vc: var_map):
        var i: Int
        for i in range(self.recs.size):
            self.drop_receiver(i)
        for i in range(vc.recs.size):
            self.add_receiver(vc.recs[i].id.val)
        for i in range(self.hels.size):
            self.drop_heliostat(i)
        for i in range(vc.hels.size):
            self.add_heliostat(vc.hels[i].id.val)
        for var in self._varptrs:
            var.value.set_from_string(vc._varptrs[var.key].as_string().c_str())
        return

    def reset(inout self):
        self.hels.clear()
        self.recs.clear()
        self._varptrs.clear()
        self.hels.reserve(100)
        self.recs.reserve(100)
        self.amb.atm_coefs.set("ambient.0.atm_coefs", SP_DATTYPE.SP_MATRIX_T, "0.006789,0.1046,-0.0170,0.002845;0.01293,0.2748,-.03394,0;0.006789,0.1046,-0.0170,0.002845", "none", false, "", "0.006789,0.1046,-0.0170,0.002845;0.01293,0.2748,-.03394,0;0.006789,0.1046,-0.0170,0.002845", false, "User-defined attenuation", "Atmospheric attenuation coefficients for user-defined analysis")
        self.amb.atm_model.set("ambient.0.atm_model", SP_DATTYPE.SP_STRING, "0", "none", true, "combo", "DELSOL3 clear day=0;DELSOL3 hazy day=1;User-defined=2", false, "Atmospheric attenuation model", "Atmospheric attenuation model {0=25km Barstow, 1 = 5km Barstow, 2 = user defined}")
        self.amb.class_name.set("ambient.0.class_name", SP_DATTYPE.SP_STRING, "Climate", "none", false, "", "", false, "Class name", "Class name")
        self.amb.del_h2o.set("ambient.0.del_h2o", SP_DATTYPE.SP_DOUBLE, "20", "mm H2O", false, "", "", false, "Atmospheric precipitable water", "Atmospheric precipitable water depth for use in the Allen insolation model")
        self.amb.dni_layout.set("ambient.0.dni_layout", SP_DATTYPE.SP_DOUBLE, "950", "W/m2", true, "", "", false, "Constant DNI for layout calculations", "DNI to use during all layout calculations. CONSTANT model only.")
        self.amb.dpres.set("ambient.0.dpres", SP_DATTYPE.SP_DOUBLE, "1", "atm", true, "", "", false, "Ambient pressure", "Local ambient pressure relative to sea-level pressure")
        self.amb.elevation.set("ambient.0.elevation", SP_DATTYPE.SP_DOUBLE, "588", "m", false, "", "", false, "Plant elevation", "Plant mean elevation")
        self.amb.insol_type.set("ambient.0.insol_type", SP_DATTYPE.SP_STRING, "0", "none", false, "combo", "Weather file data=-1;Meinel model=0;Hottel model=1;Constant value=2;Allen model=3;Moon model=4", false, "Insolation model", "Model used to determine insolation as a function of time")
        self.amb.latitude.set("ambient.0.latitude", SP_DATTYPE.SP_DOUBLE, "34.867", "deg", false, "", "", false, "Plant latitude", "Plant latitude")
        self.amb.loc_city.set("ambient.0.loc_city", SP_DATTYPE.SP_STRING, "city name", "none", false, "", "", false, "Weather file location name", "City or place name for weather station (informational only)")
        self.amb.loc_state.set("ambient.0.loc_state", SP_DATTYPE.SP_STRING, "state name", "none", false, "", "", false, "Weather file state name", "State name for weather station (informational only)")
        self.amb.longitude.set("ambient.0.longitude", SP_DATTYPE.SP_DOUBLE, "-116.783", "deg", false, "", "", false, "Plant longitude", "Plant longitude")
        self.amb.sun_csr.set("ambient.0.sun_csr", SP_DATTYPE.SP_DOUBLE, "0.1", "none", true, "", "", false, "Circumsolar ratio", "Ratio of solar flux contained in the circumsolar ring over the solar disc flux")
        self.amb.sun_pos_map.set("ambient.0.sun_pos_map", SP_DATTYPE.SP_MATRIX_T, "", "[deg,deg]", false, "", "", false, "sun_pos_map", "Map of sun positions to use for calculations")
        self.amb.sun_rad_limit.set("ambient.0.sun_rad_limit", SP_DATTYPE.SP_DOUBLE, "4.65", "mrad", true, "", "", false, "Sunshape angular extent", "Half-angle of sunshape size (4.65mrad for Pillbox, 2.73mrad for Gaussian)")
        self.amb.sun_type.set("ambient.0.sun_type", SP_DATTYPE.SP_STRING, "2", "none", true, "combo", "Pillbox sun=2;Gaussian sun=4;Limb-darkened sun=1;Point sun=0;Buie CSR=5;User sun=3;", false, "Sunshape model", "Sunshape model - {0=point sun, 1=limb darkened sun, 2=square wave sun, 3=user sun}")
        self.amb.time_zone.set("ambient.0.time_zone", SP_DATTYPE.SP_DOUBLE, "-8", "hr", false, "", "", false, "Time zone", "Time zone")
        self.amb.user_sun.set("ambient.0.user_sun", SP_DATTYPE.SP_MATRIX_T, "", "[deg,deg]", false, "", "", false, "user_sun", "Array of intensity at various angles from the centroid of the sun")
        self.amb.weather_file.set("ambient.0.weather_file", SP_DATTYPE.SP_STRING, "USA CA Daggett (TMY2).csv", "none", true, "", "", false, "Weather file", "Weather file to use for analysis")
        self.amb.wf_data.set("ambient.0.wf_data", SP_DATTYPE.SP_WEATHERDATA, "", "none", false, "", "", false, "wf_data", "Data entries in the weather file")
        self.amb.atm_atten_est.setup("ambient.0.atm_atten_est", SP_DATTYPE.SP_DOUBLE, "%", false, "", "", false, "Average attenuation", "Average solar field attenuation due to atmospheric scattering")
        self.amb.sim_time_step.setup("ambient.0.sim_time_step", SP_DATTYPE.SP_DOUBLE, "sec", false, "", "", false, "Simulation weather data time step", "Simulation weather data time step")
        self.fin.class_name.set("financial.0.class_name", SP_DATTYPE.SP_STRING, "Financial", "none", false, "", "", false, "Class name", "Class name")
        self.fin.contingency_rate.set("financial.0.contingency_rate", SP_DATTYPE.SP_DOUBLE, "7", "%", true, "", "", false, "Contingency", "Fraction of the direct capital costs added to account for contingency")
        self.fin.fixed_cost.set("financial.0.fixed_cost", SP_DATTYPE.SP_DOUBLE, "0", "$", false, "", "", false, "Fixed cost", "Cost that does not scale with any plant parameter")
        self.fin.heliostat_spec_cost.set("financial.0.heliostat_spec_cost", SP_DATTYPE.SP_DOUBLE, "145", "$/m2", true, "", "", false, "Heliostat field", "Cost per square meter of heliostat aperture area of the heliostat field")
        self.fin.is_pmt_factors.set("financial.0.is_pmt_factors", SP_DATTYPE.SP_BOOL, "FALSE", "", false, "checkbox", "", false, "Enable payment weighting factors", "Enable or disable the use of weighting factors in determining field layout")
        self.fin.land_spec_cost.set("financial.0.land_spec_cost", SP_DATTYPE.SP_DOUBLE, "10000", "$/acre", true, "", "", false, "Land cost per acre", "Cost of land per acre including the footprint of the land occupied by the entire plant.")
        self.fin.pmt_factors.set("financial.0.pmt_factors", SP_DATTYPE.SP_VEC_DOUBLE, "2.064,1.2,1,1.1,0.8,0.7,1,1,1", "none", false, "", "", false, "Payment allocation factors", "Relative value of electricity produced during this period compared to the average")
        self.fin.rec_cost_exp.set("financial.0.rec_cost_exp", SP_DATTYPE.SP_DOUBLE, "0.7", "none", true, "", "", false, "Receiver cost scaling exponent", "Exponent in the equation (total cost) = (ref. cost) * ( (area) / (ref. area) ) ^ X")
        self.fin.rec_ref_area.set("financial.0.rec_ref_area", SP_DATTYPE.SP_DOUBLE, "1571", "m2", true, "", "", false, "Receiver reference area", "Receiver surface area corresponding to the receiver reference cost")
        self.fin.rec_ref_cost.set("financial.0.rec_ref_cost", SP_DATTYPE.SP_DOUBLE, "103000000", "$", true, "", "", false, "Receiver reference cost", "Cost of the receiver at the sizing indicated by the reference receiver area")
        self.fin.sales_tax_frac.set("financial.0.sales_tax_frac", SP_DATTYPE.SP_DOUBLE, "80", "%", true, "", "", false, "Sales tax rate portion", "Fraction of the direct capital costs for which sales tax applies")
        self.fin.sales_tax_rate.set("financial.0.sales_tax_rate", SP_DATTYPE.SP_DOUBLE, "5", "%", true, "", "", false, "Sales tax rate", "Sales tax rate applid to the total direct capital cost")
        self.fin.site_spec_cost.set("financial.0.site_spec_cost", SP_DATTYPE.SP_DOUBLE, "16", "$/m2", true, "", "", false, "Site improvements", "Cost per square meter of heliostat aperture area of site improvements")
        self.fin.tower_exp.set("financial.0.tower_exp
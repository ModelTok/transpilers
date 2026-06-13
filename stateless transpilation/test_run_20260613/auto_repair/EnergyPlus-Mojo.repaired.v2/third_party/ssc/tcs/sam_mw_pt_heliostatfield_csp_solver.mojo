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
# define _TCSTYPEINTERFACE_
from tcstype import *
from lib_util import *
from lib_weatherfile import *
from interpolation_routines import *
from AutoPilot_API import *
from IOUtil import *
from sort_method import *
from csp_solver_pt_heliostatfield import *
from csp_solver_util import *
from csp_solver_core import *

# using namespace std;  // not needed in Mojo

# static bool solarpilot_callback( simulation_info *siminfo, void *data );
# forward declaration

# /* 
# A self-contained heliostat field type that directly calls SolarPilot through the AutoPilot API. The user
# may optionally specify the heliostat field positions or may use this type to generate positions based on
# input parameters.
# This type can be run in three different modes. 
# ----------------------------------------------------------------------------------------------------------------------
# 					Parameters
# ----------------------------------------------------------------------------------------------------------------------
# --- RUN_TYPE::AUTO --- SolarPILOT automatic mode
# 	** Generate field layout and characterize performance with user-specified macro-geometry **
# 	#######################################################################################################
# 	No.	|	Item						|	Variable				|	Units	|	Note
# 	----- INPUTS ------------------------------------------------------------------------------------------
# 	0	|	Run type					|	run_type				|	-		|	enum RUN_TYPE
# 	1	|	Heliostat width				|	helio_width				|	m		|
# 	2	|	Heliostat height			|	helio_height			|	m		|
# 	3	|	Heliostat optical error		|	helio_optical_error		|	rad		|
# 	4	|	Heliostat active frac.		|	helio_active_fraction	|	-		|
# 	5	|	Heliostat reflectance		|	helio_reflectance		|	-		|
# 	6	|	Receiver absorptance		|	rec_absorptance			|	-		|
# 	7	|	Receiver height				|	rec_height				|	m		|
# 	8	|	Receiver aspect ratio		|	rec_aspect				|	- 		|	(H/W)
# 	9	|	Receiver design heatloss	|	rec_hl_perm2			|	kW/m2	|
# 	10	|	Field thermal power rating	|	q_design				|	kW		|
# 	11	|	Tower height				|	h_tower					|	m		|
# 	12	|	Weather file name			|	weather_file			|	-		|	String
# 	13	|	Land boundary type			|	land_bound_type			|	- 		|	(sp_layout::LAND_BOUND_TYPE)
# 	14	|	Land max boundary			|	land_max				|	- OR m	|	X tower heights OR fixed radius
# 	15	|	Land min boundary			|	land_min				|	- OR m	|	X tower heights OR fixed radius
# 	16	|	<>Land boundary table		|	land_bound_table		|	m		|	Polygon {{x1,y1},{x2,y2},...}
# 	17	|	<>Boundary table listing	|	land_bound_list			|	-		|	Poly. sizes (- if exclusion) {L1,-L2,...}
# 	18	|	Heliostat startup energy	|	p_start					|	kWe-hr	|	
# 	19	|	Heliostat tracking energy	|	p_track					|	kWe		|	
# 	20	|	Stow/deploy elevation		|	hel_stow_deploy			|	deg		|
# 	21	|	Max. wind velocity			|	v_wind_max				|	m/s		|
# 	22	|	<>Interpolation nugget		|	interp_nug				|	-		|
# 	23	|	<>Interpolation beta coef.	|	interp_beta				|	-		|
# 	24	|	Flux map X resolution		|	n_flux_x				|	-		|
# 	25	|	Flux map Y resolution		|	n_flux_y				|	-		|
# 	----- Parameters set on Init() ------------------------------------------------------------------------
# 	26	|	Heliostat position table	|	helio_positions			|	m		|	{{x1,y1,z1},...}
# 	27	|	<>Heliostat aim point table	|	helio_aim_points		|	m		|	{{x1,y1,z1},...} receiver coordinates
# 	28	|	Number of heliostats		|	N_hel					|	-		|
# 	29	|	Field efficiency array		|	eta_map					| deg,deg,-	|	{{az1,el1,eff1},{az2,...}}
# 	30	|	Flux map sun positions		|	flux_positions			| deg,deg	|	{{az1,el1},{az2,...}}
# 	31	|	Flux map intensities		|	flux_maps				|	-		|	{{f11,f12,f13...},{f21,f22...}..}
# 	########################################################################################################
# 	<> = Optional
# --- RUN_TYPE::USER_FIELD --- SolarPILOT user-field mode
# 	** User specifies heliostat positions, macro geometry, annual performance characterized internally **
# 	#################  Required inputs ####################################################################
# 	No.	|	Item						|	Variable				|	Units	|	Note
# 	-------------------------------------------------------------------------------------------------------
# 	0	|	Run type					|	run_type				|	-		|	enum RUN_TYPE
# 	1	|	Heliostat width				|	helio_width				|	m		|
# 	2	|	Heliostat height			|	helio_height			|	m		|
# 	3	|	Heliostat optical error		|	helio_optical_error		|	rad		|
# 	4	|	Heliostat active frac.		|	helio_active_fraction	|	-		|
# 	5	|	Heliostat reflectance		|	helio_reflectance		|	-		|
# 	6	|	Receiver absorptance		|	rec_absorptance			|	-		|
# 	7	|	Receiver height				|	rec_height				|	m		|
# 	8	|	Receiver aspect ratio		|	rec_aspect				|	- 		|	(H/W)
# 	9	|	Receiver design heatloss	|	rec_hl_perm2			|	kW/m2	|
# 	10	|	Field thermal power rating	|	q_design				|	kW		|
# 	11	|	Tower height				|	h_tower					|	m		|
# 	12	|	Weather file name			|	weather_file			|	-		|	String
# 	13	|	Land boundary type			|	land_bound_type			|	- 		|	(sp_layout::LAND_BOUND_TYPE)
# 	14	|	Land max boundary			|	land_max				|	- OR m	|	X tower heights OR fixed radius
# 	15	|	Land min boundary			|	land_min				|	- OR m	|	X tower heights OR fixed radius
# 	16	|	<>Land boundary table		|	land_bound_table		|	m		|	Polygon {{x1,y1},{x2,y2},...}
# 	17	|	<>Boundary table listing	|	land_bound_list			|	-		|	Poly. sizes (- if exclusion) {L1,-L2,...}
# 	18	|	Heliostat startup energy	|	p_start					|	kWe-hr	|	
# 	19	|	Heliostat tracking energy	|	p_track					|	kWe		|	
# 	20	|	Stow/deploy elevation		|	hel_stow_deploy			|	deg		|
# 	21	|	Max. wind velocity			|	v_wind_max				|	m/s		|
# 	22	|	<>Interpolation nugget		|	interp_nug				|	-		|
# 	23	|	<>Interpolation beta coef.	|	interp_beta				|	-		|
# 	24	|	Flux map X resolution		|	n_flux_x				|	-		|
# 	25	|	Flux map Y resolution		|	n_flux_y				|	-		|
# 	26  |   Atm. atten coef 0           |   c_atm_0                 |   -       |
# 	27  |   Atm. atten coef 1           |   c_atm_1                 |   1/km    |
# 	28  |   Atm. atten coef 2           |   c_atm_2                 |   1/km^2  |
# 	29  |   Atm. atten coef 3           |   c_atm_3                 |   1/km^3  |
# 	30  |   Number of helio. facets X   |   n_facet_x               |   -       |
# 	31  |   Number of helio. facets Y   |   n_facet_y               |   -       |
# 	32  |   Helio. canting type         |   cant_type               |   -       |   0=Flat, 1=Ideal, 2=Equinox, 3=Summer sol., 4=Winter sol
# 	33  |   Helio. focus type           |   focus_type              |   -       |   0=Flat, 1=Ideal
# 	34	|	Heliostat position table	|	helio_positions			|	m		|	{{x1,y1,z1},...}
# 	35	|	<>Heliostat aim point table	|	helio_aim_points		|	m		|	{{x1,y1,z1},...} receiver coordinates
# 	----- Parameters set on Init() ------------------------------------------------------------------------
# 	36	|	<>Heliostat aim point table	|	helio_aim_points		|	m		|	{{x1,y1,z1},...} receiver coordinates
# 	37	|	Number of heliostats		|	N_hel					|	-		|
# 	38	|	Field efficiency array		|	eta_map					| deg,deg,-	|	{{az1,el1,eff1},{az2,...}}
# 	39	|	Flux map sun positions		|	flux_positions			| deg,deg	|	{{az1,el1},{az2,...}}
# 	40	|	Flux map intensities		|	flux_maps				|	-		|	{{f11,f12,f13...},{f21,f22...}..}
# 	########################################################################################################
# 	<> = Optional
# --- RUN_TYPE::USER_DATA --- User-data mode
# 	** User specifies field efficiency and flux intensity on the receiver vs. sun position. No SolarPILOT runs **
# 	#################  Required inputs ####################################################################
# 	No.	|	Item						|	Variable				|	Units	|	Note
# 	-------------------------------------------------------------------------------------------------------
# 	0	|	Run type					|	run_type				|	-		|	enum RUN_TYPE
# 	11	|	Tower height				|	h_tower					|	m		|
# 	12	|	Weather file name			|	weather_file			|	-		|	String
# 	13	|	Land boundary type			|	land_bound_type			|	- 		|	(sp_layout::LAND_BOUND_TYPE)
# 	14	|	Land max boundary			|	land_max				|	- OR m	|	X tower heights OR fixed radius
# 	15	|	Land min boundary			|	land_min				|	- OR m	|	X tower heights OR fixed radius
# 	16	|	<>Land boundary table		|	land_bound_table		|	m		|	Polygon {{x1,y1},{x2,y2},...}
# 	17	|	<>Boundary table listing	|	land_bound_list			|	-		|	Poly. sizes (- if exclusion) {L1,-L2,...}
# 	18	|	Heliostat startup energy	|	p_start					|	kWe-hr	|	
# 	19	|	Heliostat tracking energy	|	p_track					|	kWe		|	
# 	20	|	Stow/deploy elevation		|	hel_stow_deploy			|	deg		|
# 	21	|	Max. wind velocity			|	v_wind_max				|	m/s		|
# 	22	|	<>Interpolation nugget		|	interp_nug				|	-		|
# 	23	|	<>Interpolation beta coef.	|	interp_beta				|	-		|
# 	24	|	Flux map X resolution		|	n_flux_x				|	-		|
# 	25	|	Flux map Y resolution		|	n_flux_y				|	-		|
# 	28	|	Number of heliostats		|	N_hel					|	-		|
# 	29	|	Field efficiency array		|	eta_map					| deg,deg,-	|	{{az1,el1,eff1},{az2,...}}
# 	30	|	Flux map sun positions		|	flux_positions			| deg,deg	|	{{az1,el1},{az2,...}}
# 	31	|	Flux map intensities		|	flux_maps				|	-		|	{{f11,f12,f13...},{f21,f22...}..}
# 	32  |   Atm. atten coef 0           |   c_atm_0                 |   -       |
# 	33  |   Atm. atten coef 1           |   c_atm_1                 |   1/km    |
# 	34  |   Atm. atten coef 2           |   c_atm_2                 |   1/km^2  |
# 	35  |   Atm. atten coef 3           |   c_atm_3                 |   1/km^3  |
# 	36  |   Number of helio. facets X   |   n_facet_x               |   -       |
# 	37  |   Number of helio. facets Y   |   n_facet_y               |   -       |
# 	38  |   Helio. canting type         |   cant_type               |   -       |   0=Flat, 1=Ideal, 2=Equinox, 3=Summer sol., 4=Winter sol
# 	39  |   Helio. focus type           |   focus_type              |   -       |   0=Flat, 1=Ideal
# 	----- Parameters set on Init() ------------------------------------------------------------------------
# 	None
# 	########################################################################################################
# 	<> = Optional
# Note: 
# Annual efficiency is generated using non-uniform sun position spacing. The method implemented to handle
# interpolation of non-uniform data is Gauss-Markov estimation (Kriging), with parameters set to induce
# nearly linear interpolation that maintains fit fidelity with the original data.
# """

# enum{	//Parameters
# 		P_run_type, 
# 		P_helio_width, 
# 		P_helio_height, 
# 		P_helio_optical_error, 
# 		P_helio_active_fraction, 
#         P_dens_mirror,
# 		P_helio_reflectance, 
# 		P_rec_absorptance, 
# 		P_rec_height, 
# 		P_rec_aspect, 
# 		P_rec_hl_perm2, 
# 		P_q_design, 
# 		P_h_tower, 
# 		P_weather_file,
# 		P_land_bound_type, 
# 		P_land_max, 
# 		P_land_min, 
# 		P_land_bound_table, 
# 		P_land_bound_list, 
# 		P_p_start, 
# 		P_p_track, 
# 		P_hel_stow_deploy, 
# 		P_v_wind_max, 
# 		P_interp_nug, 
# 		P_interp_beta, 
# 		P_n_flux_x, 
# 		P_n_flux_y, 
# 		P_helio_positions, 
# 		P_helio_aim_points, 
# 		P_N_hel, 
# 		P_eta_map, 
# 		P_flux_positions, 
# 		P_flux_maps,
# 		P_c_atm_0,
# 		P_c_atm_1,
# 		P_c_atm_2,
# 		P_c_atm_3,
# 		P_n_facet_x,
# 		P_n_facet_y,
# 		P_cant_type,
# 		P_focus_type,
# 		P_n_flux_days,
# 		P_delta_flux_hrs,
# 		P_dni_des,
# 		P_land_area,
#         P_ADJUST,
# 		I_v_wind,
# 		I_field_control,
# 		I_solaz,
# 		I_solzen,
# 		O_pparasi,
# 		O_eta_field,
#         O_sf_adjust_out,
# 		O_flux_map,
# 		N_MAX}

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
alias P_ADJUST = 45
alias I_v_wind = 46
alias I_field_control = 47
alias I_solaz = 48
alias I_solzen = 49
alias O_pparasi = 50
alias O_eta_field = 51
alias O_sf_adjust_out = 52
alias O_flux_map = 53
alias N_MAX = 54

# tcsvarinfo sam_mw_pt_heliostatfield_variables[] = {
#     { TCS_PARAM,    TCS_NUMBER,   P_run_type,                "run_type",              "Run type",                                             "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_helio_width,             "helio_width",           "Heliostat width",                                      "m",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_helio_height,            "helio_height",          "Heliostat height",                                     "m",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_helio_optical_error,     "helio_optical_error",   "Heliostat optical error",                              "rad",    "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_helio_active_fraction,   "helio_active_fraction", "Heliostat active frac.",                               "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_dens_mirror,             "dens_mirror",           "Ratio of reflective area to profile",                  "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_helio_reflectance,       "helio_reflectance",     "Heliostat reflectance",                                "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_rec_absorptance,         "rec_absorptance",       "Receiver absorptance",                                 "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_rec_height,              "rec_height",            "Receiver height",                                      "m",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_rec_aspect,              "rec_aspect",            "Receiver aspect ratio",                                "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_rec_hl_perm2,            "rec_hl_perm2",          "Receiver design heatloss",                             "kW/m2",  "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_q_design,                "q_design",              "Field thermal power rating",                           "kW",     "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_h_tower,                 "h_tower",               "Tower height",                                         "m",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_STRING,   P_weather_file,            "weather_file",          "Weather file location",                                "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_land_bound_type,         "land_bound_type",       "Land boundary type",                                   "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_land_max,                "land_max",              "Land max boundary",                                    "- OR m", "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_land_min,                "land_min",              "Land min boundary",                                    "- OR m", "",                              "", ""          },
#     { TCS_PARAM,    TCS_MATRIX,   P_land_bound_table,        "land_bound_table",      "Land boundary table",                                  "m",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_ARRAY,    P_land_bound_list,         "land_bound_list",       "Boundary table listing",                               "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_p_start,                 "p_start",               "Heliostat startup energy",                             "kWe-hr", "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_p_track,                 "p_track",               "Heliostat tracking energy",                            "kWe",    "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_hel_stow_deploy,         "hel_stow_deploy",       "Stow/deploy elevation",                                "deg",    "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_v_wind_max,              "v_wind_max",            "Max. wind velocity",                                   "m/s",    "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_interp_nug,              "interp_nug",            "Interpolation nugget",                                 "-",      "",                              "", "0.0"       },
#     { TCS_PARAM,    TCS_NUMBER,   P_interp_beta,             "interp_beta",           "Interpolation beta coef.",                             "-",      "",                              "", "1.99"      },
#     { TCS_PARAM,    TCS_NUMBER,   P_n_flux_x,                "n_flux_x",              "Flux map X resolution",                                "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_n_flux_y,                "n_flux_y",              "Flux map Y resolution",                                "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_MATRIX,   P_helio_positions,         "helio_positions",       "Heliostat position table",                             "m",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_MATRIX,   P_helio_aim_points,        "helio_aim_points",      "Heliostat aim point table",                            "m",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_N_hel,                   "N_hel",                 "Number of heliostats",                                 "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_MATRIX,   P_eta_map,                 "eta_map",               "Field efficiency array",                               "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_MATRIX,   P_flux_positions,          "flux_positions",        "Flux map sun positions",                               "deg",    "",                              "", ""          },
#     { TCS_PARAM,    TCS_MATRIX,   P_flux_maps,               "flux_maps",             "Flux map intensities",                                 "-",      "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_c_atm_0,                 "c_atm_0",               "Attenuation coefficient 0",                            "",       "",                              "", "0.006789"  },
#     { TCS_PARAM,    TCS_NUMBER,   P_c_atm_0,                 "c_atm_1",               "Attenuation coefficient 1",                            "",       "",                              "", "0.1046"    },
#     { TCS_PARAM,    TCS_NUMBER,   P_c_atm_0,                 "c_atm_2",               "Attenuation coefficient 2",                            "",       "",                              "", "-0.0107"   },
#     { TCS_PARAM,    TCS_NUMBER,   P_c_atm_0,                 "c_atm_3",               "Attenuation coefficient 3",                            "",       "",                              "", "0.002845"  },
#     { TCS_PARAM,    TCS_NUMBER,   P_n_facet_x,               "n_facet_x",             "Number of heliostat facets - X",                       "",       "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_n_facet_y,               "n_facet_y",             "Number of heliostat facets - Y",                       "",       "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_cant_type,               "cant_type",             "Heliostat cant method",                                "",       "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_focus_type,              "focus_type",            "Heliostat focus method",                               "",       "",                              "", ""          },
#     { TCS_PARAM,    TCS_NUMBER,   P_n_flux_days,             "n_flux_days",           "No. days in flux map lookup",                          "",       "",                              "", "8"         },
#     { TCS_PARAM,    TCS_NUMBER,   P_delta_flux_hrs,          "delta_flux_hrs",        "Hourly frequency in flux map lookup",                  "hrs",    "",                              "", "1"         },
#     { TCS_PARAM,    TCS_NUMBER,   P_dni_des,                 "dni_des",               "Design-point DNI",                                     "W/m2",   "",                              "", ""          },
# 	{ TCS_PARAM,    TCS_NUMBER,   P_land_area,               "land_area",             "CALCULATED land area",                                 "acre",   "",                              "", ""          },
# 	{ TCS_PARAM,     TCS_ARRAY,   P_ADJUST,                  "sf_adjust",             "Time series solar field production adjustment",        "none",   "",                              "", "" },
# 	{ TCS_INPUT,    TCS_NUMBER,   I_v_wind,                  "vwind",                 "Wind velocity",                                        "m/s",    "",                              "", ""          },
#     { TCS_INPUT,    TCS_NUMBER,   I_field_control,           "field_control",         "Field defocus control",                                "",       "",                              "", ""          },
#     { TCS_INPUT,    TCS_NUMBER,   I_solaz,                   "solaz",                 "Solar azimuth angle: 0 due north - clockwise to +360", "deg",    "",                              "", ""          },
#     { TCS_INPUT,    TCS_NUMBER,   I_solzen,                  "solzen",                "Solar zenith angle",                                   "deg",    "",                              "", ""          },
# 	{ TCS_OUTPUT,   TCS_NUMBER,   O_pparasi,                 "pparasi",               "Parasitic tracking/startup power",                     "MWe",    "",                              "", ""          },
#     { TCS_OUTPUT,   TCS_NUMBER,   O_eta_field,               "eta_field",             "Total field efficiency",                               "",       "",                              "", ""          },
#     { TCS_OUTPUT,   TCS_NUMBER,   O_sf_adjust_out,           "sf_adjust_out",         "Field availability adjustment factor",                 "",       "",                              "", ""          },
#     { TCS_OUTPUT,   TCS_MATRIX,   O_flux_map,                "flux_map",              "Receiver flux map",                                    "",       "n_flux_x cols x n_flux_y rows", "", ""          },
# 	{TCS_INVALID, TCS_INVALID, N_MAX,			0,					0, 0, 0, 0, 0	}
# };

# We'll define the variables array as a constant list of tuples (or structs) for Mojo.
# Since the exact TCS types are not defined here, we'll keep the same structure as a list of lists.
# For simplicity, we'll just define a constant list of strings? Actually the original uses a C array of structs.
# We'll create a Mojo struct to represent tcsvarinfo, but we don't have the definition. We'll just keep the array as a comment and rely on the framework.
# For the translation, we'll assume the framework provides the necessary types and the array is used by TCS_IMPLEMENT_TYPE.
# We'll just keep the array definition as a comment and not translate it to Mojo code because it's a static global that the framework expects.
# Instead, we'll define a function that returns the array? But the original is a global variable.
# Since we cannot fully replicate the TCS framework, we'll keep the array as a comment and assume the framework will handle it.
# The TCS_IMPLEMENT_TYPE macro at the end will be replaced with a Mojo equivalent if available.

# #ifdef _MSC_VER
# #define mysnprintf _snprintf
# #else
# #define mysnprintf snprintf
# #endif
# #define pi 3.141592654
# #define az_scale 6.283125908 
# #define zen_scale 1.570781477 
# #define eff_scale 0.7

alias mysnprintf = snprintf  # Mojo has snprintf? We'll assume it's available.
alias pi = 3.141592654
alias az_scale = 6.283125908
alias zen_scale = 1.570781477
alias eff_scale = 0.7

# class sam_mw_pt_heliostatfield : public tcstypeinterface
# {
# private:
# 	C_pt_heliostatfield mc_heliostatfield;
# 	C_csp_weatherreader::S_outputs ms_weather;
# 	C_csp_solver_sim_info ms_sim_info;
# public:
# 	sam_mw_pt_heliostatfield( tcscontext *cst, tcstypeinfo *ti)
# 		: tcstypeinterface( cst, ti)
# 	{
# 	}
# 	~sam_mw_pt_heliostatfield()
# 	{
# 	}
# 	int init()
# 	{
# 		...
# 	}
# 	int call( double time, double step, int ncall )
# 	{						
# 		...
# 	}
# 	int converged( double time )
# 	{
# 		...
# 	}
# 	int relay_message( string &msg, double percent ){
# 		return progress( (float)percent, msg.c_str() ) ? 0 : -1;
# 	}
# 	double rdist(VectDoub *p1, VectDoub *p2, int dim=2){
# 		double d=0;
# 		for(int i=0; i<dim; i++){
# 			double rd = p1->at(i) - p2->at(i);
# 			d += rd * rd;
# 		}
# 		return sqrt(d);
# 	}
# };

struct sam_mw_pt_heliostatfield:
    var mc_heliostatfield: C_pt_heliostatfield
    var ms_weather: C_csp_weatherreader.S_outputs
    var ms_sim_info: C_csp_solver_sim_info

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        # call base class constructor? In Mojo we don't have inheritance like C++.
        # We'll assume tcstypeinterface is a struct with __init__ that takes cst, ti.
        # We'll just assign members.
        # Actually we need to call the base constructor. We'll do: self = tcstypeinterface(cst, ti)
        # But Mojo doesn't have that syntax. We'll just set the base members if they exist.
        # For simplicity, we'll assume the base class is a struct and we can initialize it.
        # We'll just leave the body empty as in C++.

    def __del__(inout self):

    def init(inout self) -> Int:
        self.mc_heliostatfield.ms_params.m_run_type = Int(self.value(P_run_type))
        self.mc_heliostatfield.ms_params.m_helio_width = self.value(P_helio_width)
        self.mc_heliostatfield.ms_params.m_helio_height = self.value(P_helio_height)
        self.mc_heliostatfield.ms_params.m_helio_optical_error = self.value(P_helio_optical_error)
        self.mc_heliostatfield.ms_params.m_helio_active_fraction = self.value(P_helio_active_fraction)
        self.mc_heliostatfield.ms_params.m_dens_mirror = self.value(P_dens_mirror)
        self.mc_heliostatfield.ms_params.m_helio_reflectance = self.value(P_helio_reflectance)
        self.mc_heliostatfield.ms_params.m_rec_absorptance = self.value(P_rec_absorptance)
        self.mc_heliostatfield.ms_params.m_rec_height = self.value(P_rec_height)
        self.mc_heliostatfield.ms_params.m_rec_aspect = self.value(P_rec_aspect)
        self.mc_heliostatfield.ms_params.m_rec_hl_perm2 = self.value(P_rec_hl_perm2)
        self.mc_heliostatfield.ms_params.m_q_design = self.value(P_q_design)
        self.mc_heliostatfield.ms_params.m_h_tower = self.value(P_h_tower)
        self.mc_heliostatfield.ms_params.m_weather_file = self.value_str(P_weather_file)
        self.mc_heliostatfield.ms_params.m_land_bound_type = Int(self.value(P_land_bound_type))
        self.mc_heliostatfield.ms_params.m_land_max = self.value(P_land_max)
        self.mc_heliostatfield.ms_params.m_land_min = self.value(P_land_min)
        var nrows_in: Int = -1
        var ncols_in: Int = -1
        var input_matrix: Pointer[Float64] = self.value(P_land_bound_table, &nrows_in, &ncols_in)
        self.mc_heliostatfield.ms_params.m_land_bound_table.resize_fill(nrows_in, ncols_in, 0.0)
        for i in range(nrows_in):
            for j in range(ncols_in):
                self.mc_heliostatfield.ms_params.m_land_bound_table(i, j) = TCS_MATRIX_INDEX(self.var(P_land_bound_table), i, j)
        nrows_in = -1
        ncols_in = -1
        input_matrix = self.value(P_land_bound_list, &nrows_in)
        self.mc_heliostatfield.ms_params.m_land_bound_list.resize_fill(nrows_in, 0.0)
        for i in range(nrows_in):
            self.mc_heliostatfield.ms_params.m_land_bound_list(i, 0) = input_matrix[i]
        self.mc_heliostatfield.ms_params.m_p_start = self.value(P_p_start)
        self.mc_heliostatfield.ms_params.m_p_track = self.value(P_p_track)
        self.mc_heliostatfield.ms_params.m_hel_stow_deploy = self.value(P_hel_stow_deploy)
        self.mc_heliostatfield.ms_params.m_v_wind_max = self.value(P_v_wind_max)
        self.mc_heliostatfield.ms_params.m_interp_nug = self.value(P_interp_nug)
        self.mc_heliostatfield.ms_params.m_interp_beta = self.value(P_interp_beta)
        self.mc_heliostatfield.ms_params.m_n_flux_x = Int(self.value(P_n_flux_x))
        self.mc_heliostatfield.ms_params.m_n_flux_y = Int(self.value(P_n_flux_y))
        nrows_in = -1
        ncols_in = -1
        input_matrix = self.value(P_helio_positions, &nrows_in, &ncols_in)
        self.mc_heliostatfield.ms_params.m_helio_positions.resize_fill(nrows_in, ncols_in, 0.0)
        for i in range(nrows_in):
            for j in range(ncols_in):
                self.mc_heliostatfield.ms_params.m_helio_positions(i, j) = TCS_MATRIX_INDEX(self.var(P_helio_positions), i, j)
        nrows_in = -1
        ncols_in = -1
        input_matrix = self.value(P_helio_aim_points, &nrows_in, &ncols_in)
        self.mc_heliostatfield.ms_params.m_helio_aim_points.resize_fill(nrows_in, ncols_in, 0.0)
        for i in range(nrows_in):
            for j in range(ncols_in):
                self.mc_heliostatfield.ms_params.m_helio_aim_points(i, j) = TCS_MATRIX_INDEX(self.var(P_helio_aim_points), i, j)
        nrows_in = -1
        ncols_in = -1
        input_matrix = self.value(P_eta_map, &nrows_in, &ncols_in)
        self.mc_heliostatfield.ms_params.m_eta_map.resize_fill(nrows_in, ncols_in, 0.0)
        for i in range(nrows_in):
            for j in range(ncols_in):
                self.mc_heliostatfield.ms_params.m_eta_map(i, j) = TCS_MATRIX_INDEX(self.var(P_eta_map), i, j)
        nrows_in = -1
        ncols_in = -1
        input_matrix = self.value(P_flux_positions, &nrows_in, &ncols_in)
        self.mc_heliostatfield.ms_params.m_flux_positions.resize_fill(nrows_in, ncols_in, 0.0)
        for i in range(nrows_in):
            for j in range(ncols_in):
                self.mc_heliostatfield.ms_params.m_flux_positions(i, j) = TCS_MATRIX_INDEX(self.var(P_flux_positions), i, j)
        nrows_in = -1
        ncols_in = -1
        input_matrix = self.value(P_flux_maps, &nrows_in, &ncols_in)
        self.mc_heliostatfield.ms_params.m_flux_maps.resize_fill(nrows_in, ncols_in, 0.0)
        for i in range(nrows_in):
            for j in range(ncols_in):
                self.mc_heliostatfield.ms_params.m_flux_maps(i, j) = TCS_MATRIX_INDEX(self.var(P_flux_maps), i, j)
        self.mc_heliostatfield.ms_params.m_c_atm_0 = self.value(P_c_atm_0)
        self.mc_heliostatfield.ms_params.m_c_atm_1 = self.value(P_c_atm_1)
        self.mc_heliostatfield.ms_params.m_c_atm_2 = self.value(P_c_atm_2)
        self.mc_heliostatfield.ms_params.m_c_atm_3 = self.value(P_c_atm_3)
        self.mc_heliostatfield.ms_params.m_n_facet_x = Int(self.value(P_n_facet_x))
        self.mc_heliostatfield.ms_params.m_n_facet_y = Int(self.value(P_n_facet_y))
        self.mc_heliostatfield.ms_params.m_cant_type = Int(self.value(P_cant_type))
        self.mc_heliostatfield.ms_params.m_focus_type = Int(self.value(P_focus_type))
        self.mc_heliostatfield.ms_params.m_n_flux_days = Int(self.value(P_n_flux_days))
        self.mc_heliostatfield.ms_params.m_delta_flux_hrs = Int(self.value(P_delta_flux_hrs))
        self.mc_heliostatfield.ms_params.m_dni_des = self.value(P_dni_des)
        self.mc_heliostatfield.ms_params.m_land_area = self.value(P_land_area)
        var nval_sf_adjust: Int
        var sf_adjust: Pointer[Float64] = self.value(P_ADJUST, &nval_sf_adjust) # solar field adjust factors
        self.mc_heliostatfield.ms_params.m_sf_adjust.resize(nval_sf_adjust)
        for i in range(nval_sf_adjust):     # array should be 8760 in length
            self.mc_heliostatfield.ms_params.m_sf_adjust.at(i) = sf_adjust[i]
        self.mc_heliostatfield.mf_callback = solarpilot_callback
        self.mc_heliostatfield.m_cdata = Pointer[None](address_of(self))
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.mc_heliostatfield.init()
        except C_csp_exception as csp_exception:
            while self.mc_heliostatfield.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_heliostatfield.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        nrows_in = -1
        ncols_in = -1
        nrows_in = self.mc_heliostatfield.ms_params.m_helio_positions.nrows()
        ncols_in = self.mc_heliostatfield.ms_params.m_helio_positions.ncols()
        var p_param: Pointer[Float64] = self.allocate(P_helio_positions, nrows_in, ncols_in)
        for i in range(nrows_in):
            for j in range(ncols_in):
                TCS_MATRIX_INDEX(self.var(P_helio_positions), i, j) = self.mc_heliostatfield.ms_params.m_helio_positions(i, j)
        self.value(P_land_area, self.mc_heliostatfield.ms_params.m_land_area)
        nrows_in = -1
        ncols_in = -1
        nrows_in = self.mc_heliostatfield.ms_params.m_eta_map.nrows()
        ncols_in = self.mc_heliostatfield.ms_params.m_eta_map.ncols()
        p_param = self.allocate(P_eta_map, nrows_in, ncols_in)
        for i in range(nrows_in):
            for j in range(ncols_in):
                TCS_MATRIX_INDEX(self.var(P_eta_map), i, j) = self.mc_heliostatfield.ms_params.m_eta_map(i, j)
        nrows_in = -1
        ncols_in = -1
        nrows_in = self.mc_heliostatfield.ms_params.m_flux_maps.nrows()
        ncols_in = self.mc_heliostatfield.ms_params.m_flux_maps.ncols()
        p_param = self.allocate(P_flux_maps, nrows_in, ncols_in)
        for i in range(nrows_in):
            for j in range(ncols_in):
                TCS_MATRIX_INDEX(self.var(P_flux_maps), i, j) = self.mc_heliostatfield.ms_params.m_flux_maps(i, j)
        nrows_in = -1
        ncols_in = -1
        nrows_in = self.mc_heliostatfield.ms_params.m_flux_positions.nrows()
        ncols_in = self.mc_heliostatfield.ms_params.m_flux_positions.ncols()
        p_param = self.allocate(P_flux_positions, nrows_in, ncols_in)
        for i in range(nrows_in):
            for j in range(ncols_in):
                TCS_MATRIX_INDEX(self.var(P_flux_positions), i, j) = self.mc_heliostatfield.ms_params.m_flux_positions(i, j)
        p_param = self.allocate(O_flux_map, self.mc_heliostatfield.ms_params.m_n_flux_y, self.mc_heliostatfield.ms_params.m_n_flux_x)
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        self.ms_weather.m_wspd = self.value(I_v_wind)
        var field_control_csp: Float64 = self.value(I_field_control)
        self.ms_weather.m_solzen = self.value(I_solzen)
        self.ms_weather.m_solazi = self.value(I_solaz)
        self.ms_sim_info.ms_ts.m_time = time
        self.ms_sim_info.ms_ts.m_step = step
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.mc_heliostatfield.call(self.ms_weather, field_control_csp, self.ms_sim_info)
        except C_csp_exception as csp_exception:
            while self.mc_heliostatfield.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_heliostatfield.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        for j in range(self.mc_heliostatfield.ms_params.m_n_flux_y):
            for i in range(self.mc_heliostatfield.ms_params.m_n_flux_x):
                TCS_MATRIX_INDEX(self.var(O_flux_map), j, i) = 0.0
        for j in range(self.mc_heliostatfield.ms_params.m_n_flux_y):
            for i in range(self.mc_heliostatfield.ms_params.m_n_flux_x):
                TCS_MATRIX_INDEX(self.var(O_flux_map), j, i) = self.mc_heliostatfield.ms_outputs.m_flux_map_out(j, i)
        self.value(O_pparasi, self.mc_heliostatfield.ms_outputs.m_pparasi)
        self.value(O_eta_field, self.mc_heliostatfield.ms_outputs.m_eta_field)
        self.value(O_sf_adjust_out, self.mc_heliostatfield.ms_outputs.m_sf_adjust_out)
        return 0

    def converged(inout self, time: Float64) -> Int:
        var out_type: Int = -1
        var out_msg: String = ""
        try:
            self.mc_heliostatfield.converged()
        except C_csp_exception as csp_exception:
            while self.mc_heliostatfield.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_heliostatfield.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        return 0

    def relay_message(inout self, msg: String, percent: Float64) -> Int:
        return 0 if self.progress(Float32(percent), msg) else -1

    def rdist(inout self, p1: VectDoub, p2: VectDoub, dim: Int = 2) -> Float64:
        var d: Float64 = 0.0
        for i in range(dim):
            var rd: Float64 = p1.at(i) - p2.at(i)
            d += rd * rd
        return sqrt(d)

# static bool solarpilot_callback( simulation_info *siminfo, void *data )
# {
# 	sam_mw_pt_heliostatfield *cm = static_cast<sam_mw_pt_heliostatfield*>( data );
# 	if ( !cm ) return false;
# 	float simprogress = (float)siminfo->getCurrentSimulation()/(float)(max(siminfo->getTotalSimulationCount(),1));
# 	return cm->relay_message( *siminfo->getSimulationNotices(), simprogress*100.0f ) == 0;
# }

def solarpilot_callback(siminfo: simulation_info, data: Pointer[None]) -> Bool:
    var cm: Pointer[sam_mw_pt_heliostatfield] = Pointer[sam_mw_pt_heliostatfield](data)
    if cm.is_null():
        return False
    var simprogress: Float32 = Float32(siminfo.getCurrentSimulation()) / Float32(max(siminfo.getTotalSimulationCount(), 1))
    return cm[].relay_message(siminfo.getSimulationNotices()[], simprogress * 100.0) == 0

# TCS_IMPLEMENT_TYPE( sam_mw_pt_heliostatfield, "Heliostat field with SolarPILOT", "Mike Wagner", 1, sam_mw_pt_heliostatfield_variables, NULL, 1 )
# We'll replace with a Mojo registration call if available. For now, we'll just comment it out.
# TCS_IMPLEMENT_TYPE(sam_mw_pt_heliostatfield, "Heliostat field with SolarPILOT", "Mike Wagner", 1, sam_mw_pt_heliostatfield_variables, None, 1)
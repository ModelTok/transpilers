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
from core import *
from tckernel import *
from algorithm import *
from common import *
from lib_weatherfile import *

var _cm_vtab_tcstrough_physical: StaticArray[var_info] = StaticArray[
    var_info(
        SSC_INPUT,        SSC_STRING,      "file_name",                 "Local weather file with path",                                                     "none",         "",             "Weather",        "*",                       "LOCAL_FILE",            "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "track_mode",                "Tracking mode",                                                                    "none",         "",             "Weather",        "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tilt",                      "Tilt angle of surface/axis",                                                       "none",         "",             "Weather",        "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "azimuth",                   "Azimuth angle of surface/axis",                                                    "none",         "",             "Weather",        "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "system_capacity",           "Nameplate capacity",                                                               "kW",           "",             "trough",         "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "nSCA",                      "Number of SCAs in a loop",                                                         "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "nHCEt",                     "Number of HCE types",                                                              "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "nColt",                     "Number of collector types",                                                        "none",         "constant=4",              "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "nHCEVar",                   "Number of HCE variants per type",                                                  "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "nLoops",                    "Number of loops in the field",                                                     "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "eta_pump",                  "HTF pump efficiency",                                                              "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "HDR_rough",                 "Header pipe roughness",                                                            "m",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "theta_stow",                "Stow angle",                                                                       "deg",          "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "theta_dep",                 "Deploy angle",                                                                     "deg",          "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "Row_Distance",              "Spacing between rows (centerline to centerline)",                                  "m",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "FieldConfig",               "Number of subfield headers",                                                       "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_startup",                 "Required temperature of the system before the power block can be switched on",     "C",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "P_ref",                     "Rated plant capacity",                                                             "MWe",          "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "m_dot_htfmin",              "Minimum loop HTF flow rate",                                                       "kg/s",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "m_dot_htfmax",              "Maximum loop HTF flow rate",                                                       "kg/s",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_loop_in_des",             "Design loop inlet temperature",                                                    "C",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_loop_out",                "Target loop outlet temperature",                                                   "C",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "Fluid",                     "Field HTF fluid ID number",                                                        "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_fp",                      "Freeze protection temperature (heat trace activation temperature)",                "C",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "I_bn_des",                  "Solar irradiation at design",                                                      "W/m2",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "calc_design_pipe_vals",     "Calculate temps and pressures at design conditions for runners and headers",       "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "V_hdr_cold_max",            "Maximum HTF velocity in the cold headers at design",                               "m/s",          "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "V_hdr_cold_min",            "Minimum HTF velocity in the cold headers at design",                               "m/s",          "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "V_hdr_hot_max",             "Maximum HTF velocity in the hot headers at design",                                "m/s",          "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "V_hdr_hot_min",             "Minimum HTF velocity in the hot headers at design",                                "m/s",          "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "N_max_hdr_diams",           "Maximum number of diameters in each of the hot and cold headers",                  "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "L_rnr_pb",                  "Length of runner pipe in power block",                                             "m",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "L_rnr_per_xpan",            "Threshold length of straight runner pipe without an expansion loop",               "m",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "L_xpan_hdr",                "Compined perpendicular lengths of each header expansion loop",                     "m",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "L_xpan_rnr",                "Compined perpendicular lengths of each runner expansion loop",                     "m",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "Min_rnr_xpans",             "Minimum number of expansion loops per single-diameter runner section",             "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "northsouth_field_sep",      "North/south separation between subfields. 0 = SCAs are touching",                  "m",            "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "N_hdr_per_xpan",            "Number of collector loops per expansion loop",                                     "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "offset_xpan_hdr",           "Location of first header expansion loop. 1 = after first collector loop",          "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "Pipe_hl_coef",              "Loss coefficient from the header, runner pipe, and non-HCE piping",                "W/m2-K",       "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "SCA_drives_elec",           "Tracking power, in Watts per SCA drive",                                           "W/SCA",        "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "fthrok",                    "Flag to allow partial defocusing of the collectors",                               "",             "",               "solar_field",    "*",                       "INTEGER",               "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "fthrctrl",                  "Defocusing strategy",                                                              "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "water_usage_per_wash",      "Water usage per wash",                                                             "L/m2_aper",    "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "washing_frequency",         "Mirror washing frequency",                                                         "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "accept_mode",               "Acceptance testing mode?",                                                         "0/1",          "no/yes",         "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "accept_init",               "In acceptance testing mode - require steady-state startup",                        "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "accept_loc",                "In acceptance testing mode - temperature sensor location",                         "1/2",          "hx/loop",        "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "solar_mult",                "Solar multiple",                                                                   "none",         "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "mc_bal_hot",                "Heat capacity of the balance of plant on the hot side",                            "kWht/K-MWt",   "none",           "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "mc_bal_cold",               "Heat capacity of the balance of plant on the cold side",                           "kWht/K-MWt",   "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "mc_bal_sca",                "Non-HTF heat capacity associated with each SCA - per meter basis",                 "Wht/K-m",      "",               "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "W_aperture",                "The collector aperture width (Total structural area used for shadowing)",          "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "A_aperture",                "Reflective aperture area of the collector",                                        "m2",           "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "TrackingError",             "User-defined tracking error derate",                                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "GeomEffects",               "User-defined geometry effects derate",                                             "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "Rho_mirror_clean",          "User-defined clean mirror reflectivity",                                           "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "Dirt_mirror",               "User-defined dirt on mirror derate",                                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "Error",                     "User-defined general optical error derate ",                                       "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "Ave_Focal_Length",          "Average focal length of the collector ",                                           "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "L_SCA",                     "Length of the SCA ",                                                               "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "L_aperture",                "Length of a single mirror/HCE unit",                                               "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "ColperSCA",                 "Number of individual collector sections in an SCA ",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "Distance_SCA",              "Piping distance between SCA's in the field",                                       "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "IAM_matrix",                "IAM coefficients, matrix for 4 collectors",                                        "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "HCE_FieldFrac",             "Fraction of the field occupied by this HCE type ",                                 "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "D_2",                       "Inner absorber tube diameter",                                                     "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "D_3",                       "Outer absorber tube diameter",                                                     "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "D_4",                       "Inner glass envelope diameter ",                                                   "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "D_5",                       "Outer glass envelope diameter ",                                                   "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "D_p",                       "Diameter of the absorber flow plug (optional) ",                                   "m",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "Flow_type",                 "Flow type through the absorber",                                                   "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "Rough",                     "Relative roughness of the internal HCE surface ",                                  "-",            "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "alpha_env",                 "Envelope absorptance ",                                                            "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_11",              "Absorber emittance for receiver type 1 variation 1",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_12",              "Absorber emittance for receiver type 1 variation 2",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_13",              "Absorber emittance for receiver type 1 variation 3",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_14",              "Absorber emittance for receiver type 1 variation 4",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_21",              "Absorber emittance for receiver type 2 variation 1",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_22",              "Absorber emittance for receiver type 2 variation 2",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_23",              "Absorber emittance for receiver type 2 variation 3",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_24",              "Absorber emittance for receiver type 2 variation 4",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_31",              "Absorber emittance for receiver type 3 variation 1",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_32",              "Absorber emittance for receiver type 3 variation 2",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_33",              "Absorber emittance for receiver type 3 variation 3",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_34",              "Absorber emittance for receiver type 3 variation 4",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_41",              "Absorber emittance for receiver type 4 variation 1",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_42",              "Absorber emittance for receiver type 4 variation 2",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_43",              "Absorber emittance for receiver type 4 variation 3",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "epsilon_3_44",              "Absorber emittance for receiver type 4 variation 4",                               "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "alpha_abs",                 "Absorber absorptance ",                                                            "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "Tau_envelope",              "Envelope transmittance",                                                           "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "EPSILON_4",                 "Inner glass envelope emissivities (Pyrex) ",                                       "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "EPSILON_5",                 "Outer glass envelope emissivities (Pyrex) ",                                       "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "GlazingIntactIn",           "Glazing intact (broken glass) flag {1=true, else=false}",                          "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "P_a",                       "Annulus gas pressure",                                                             "torr",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "AnnulusGas",                "Annulus gas type (1=air, 26=Ar, 27=H2)",                                           "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "AbsorberMaterial",          "Absorber material type",                                                           "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "Shadowing",                 "Receiver bellows shadowing loss factor",                                           "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "Dirt_HCE",                  "Loss due to dirt on the receiver envelope",                                        "none",         "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "Design_loss",               "Receiver heat loss at design",                                                     "W/m",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "SCAInfoArray",              "Receiver (,1) and collector (,2) type for each assembly in loop",                 "none",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "SCADefocusArray",           "Collector defocus order",                                                         "none",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "K_cpnt",                    "Interconnect component minor loss coefficients, row=intc, col=cpnt",              "none",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "D_cpnt",                    "Interconnect component diameters, row=intc, col=cpnt",                            "none",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "L_cpnt",                    "Interconnect component lengths, row=intc, col=cpnt",                              "none",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "Type_cpnt",                 "Interconnect component type, row=intc, col=cpnt",                                 "none",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "custom_sf_pipe_sizes",      "Use custom solar field pipe diams, wallthks, and lengths",                        "none",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sf_rnr_diams",              "Custom runner diameters",                                                            "m",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sf_rnr_wallthicks",         "Custom runner wall thicknesses",                                                     "m",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sf_rnr_lengths",            "Custom runner lengths",                                                              "m",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sf_hdr_diams",              "Custom header diameters",                                                            "m",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sf_hdr_wallthicks",         "Custom header wall thicknesses",                                                     "m",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sf_hdr_lengths",            "Custom header lengths",                                                              "m",          "",             "solar_field",    "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "field_fl_props",            "User defined field fluid property data",                         "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "store_fl_props",            "User defined storage fluid property data",                       "-",            "",             "controller",     "*",                       "",                      "" ),    
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "store_fluid",               "Material number for storage fluid",                              "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tshours",                   "Equivalent full-load thermal storage hours",                     "hr",           "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "eta_pump",                  "HTF pump efficiency",                                            "none",         "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "HDR_rough",                 "Header pipe roughness - used as general pipe roughness",         "m",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "is_hx",                     "Heat exchanger (HX) exists (1=yes, 0=no)" ,                      "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "dt_hot",                    "Hot side HX approach temp",                                      "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "dt_cold",                   "Cold side HX approach temp",                                     "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "hx_config",                 "HX configuration",                                               "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "q_max_aux",                 "Max heat rate of auxiliary heater",                              "MWt",          "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_set_aux",                 "Aux heater outlet temp set point",                               "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "V_tank_hot_ini",            "Initial hot tank fluid volume",                                  "m3",           "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_tank_cold_ini",           "Initial cold tank fluid tmeperature",                            "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "vol_tank",                  "Total tank volume, including unusable HTF at bottom",            "m3",           "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "h_tank",                    "Total height of tank (height of HTF when tank is full",          "m",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "h_tank_min",                "Minimum allowable HTF height in storage tank",                   "m",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "u_tank",                    "Loss coefficient from the tank",                                 "W/m2-K",       "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tank_pairs",                "Number of equivalent tank pairs",                                "-",            "",             "controller",     "*",                       "INTEGER",               "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "cold_tank_Thtr",            "Minimum allowable cold tank HTF temp",                           "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "hot_tank_Thtr",             "Minimum allowable hot tank HTF temp",                            "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tank_max_heat",             "Rated heater capacity for tank heating",                         "MW",           "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tanks_in_parallel",         "Tanks are in parallel, not in series, with solar field",         "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "has_hot_tank_bypass",       "Bypass valve connects field outlet to cold tank",                "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_tank_hot_inlet_min",      "Minimum hot tank htf inlet temperature",                         "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "q_pb_design",               "Design heat input to power block",                               "MWt",          "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "W_pb_design",               "Rated plant capacity",                                           "MWe",          "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "cycle_max_frac",            "Maximum turbine over design operation fraction",                 "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "cycle_cutoff_frac",         "Minimum turbine operation fraction before shutdown",             "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "pb_pump_coef",              "Pumping power to move 1kg of HTF through PB loop",               "kW/(kg/s)",    "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tes_pump_coef",             "Pumping power to move 1kg of HTF through tes loop",              "kW/(kg/s)",    "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "V_tes_des",                 "Design-point velocity to size the TES pipe diameters",           "m/s",          "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "custom_tes_p_loss",         "TES pipe losses are based on custom lengths and coeffs",         "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "k_tes_loss_coeffs",         "Minor loss coeffs for the coll, gen, and bypass loops",          "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "custom_sgs_pipe_sizes",     "Use custom SGS pipe diams, wallthks, and lengths",               "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sgs_diams",                 "Custom SGS diameters",                                           "m",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sgs_wallthicks",            "Custom SGS wall thicknesses",                                    "m",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "sgs_lengths",               "Custom SGS lengths",                                             "m",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "DP_SGS",                    "Pressure drop within the steam generator",                       "bar",          "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "pb_fixed_par",              "Fraction of rated gross power constantly consumed",              "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "bop_array",                 "Coefficients for balance of plant parasitics calcs",             "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "aux_array",                 "Coefficients for auxiliary heater parasitics calcs",             "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "fossil_mode",               "Fossil backup mode 1=Normal 2=Topping",                          "-",            "",             "controller",     "*",                       "INTEGER",               "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "t_standby_reset",           "Maximum allowable time for PB standby operation",                "hr",           "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "sf_type",                   "Solar field type, 1 = trough, 2 = tower",                        "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tes_type",                  "1=2-tank, 2=thermocline",                                        "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "tslogic_a",                 "Dispatch logic without solar",                                   "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "tslogic_b",                 "Dispatch logic with solar",                                      "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "tslogic_c",                 "Dispatch logic for turbine load fraction",                       "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "ffrac",                     "Fossil dispatch logic",                                          "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tc_fill",                   "Thermocline fill material",                                      "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tc_void",                   "Thermocline void fraction",                                      "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "t_dis_out_min",             "Min allowable hot side outlet temp during discharge",            "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "t_ch_out_max",              "Max allowable cold side outlet temp during charge",              "C",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "nodes",                     "Nodes modeled in the flow path",                                 "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "f_tc_cold",                 "0=entire tank is hot, 1=entire tank is cold",                    "-",            "",             "controller",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "weekday_schedule",          "Dispatch 12mx24h schedule for week days",                         "",             "",             "tou_translator", "*",                       "",                      "" ), 
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "weekend_schedule",          "Dispatch 12mx24h schedule for weekends",                          "",             "",             "tou_translator", "*",                       "",                      "" ), 
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "pc_config",         "0: Steam Rankine (224), 1: user defined",                                   "-",            "",                             "powerblock",     "?=0",                     "INTEGER",               "" ),        
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "eta_ref",           "Reference conversion efficiency at design condition",                       "none",         "",                             "powerblock",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "startup_time",      "Time needed for power block startup",                                       "hr",           "",                             "powerblock",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "startup_frac",      "Fraction of design thermal power needed for startup",                       "none",         "",                             "powerblock",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "q_sby_frac",        "Fraction of thermal power required for standby mode",                       "none",         "",                             "powerblock",     "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "dT_cw_ref",         "Reference condenser cooling water inlet/outlet T diff",                     "C",            "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_amb_des",         "Reference ambient temperature at design point",                             "C",            "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "P_boil",            "Boiler operating pressure",                                                 "bar",          "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "CT",                "Flag for using dry cooling or wet cooling system",                          "none",         "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_approach",        "Cooling tower approach temperature",                                        "C",            "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "T_ITD_des",         "ITD at design for dry system",                                              "C",            "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "P_cond_ratio",      "Condenser pressure ratio",                                                  "none",         "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "pb_bd_frac",        "Power block blowdown steam fraction ",                                      "none",         "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "P_cond_min",        "Minimum condenser pressure",                                                "inHg",         "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "n_pl_inc",          "Number of part-load increments for the heat rejection system",              "none",         "",                             "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_ARRAY,       "F_wc",              "Fraction indicating wet cooling use for hybrid system",                     "none",         "constant=[0,0,0,0,0,0,0,0,0]", "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "tech_type",         "Turbine inlet pressure control flag (sliding=user, fixed=trough)",          "1/2/3",         "tower/trough/user",           "powerblock",     "pc_config=0",             "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_T_amb_des",         "Ambient temperature at user-defined power cycle design point",                   "C",	    "",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_f_W_dot_cool_des",  "Percent of user-defined power cycle design gross output consumed by cooling",    "%",	    "",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_m_dot_water_cool_des", "Mass flow rate of water required at user-defined power cycle design point",   "kg/s",  "",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_T_htf_low",         "Low level HTF inlet temperature for T_amb parametric",                           "C",     "",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_T_htf_high",        "High level HTF inlet temperature for T_amb parametric",                          "C",		"",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_T_amb_low",         "Low level ambient temperature for HTF mass flow rate parametric",                "C",		"",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_T_amb_high",        "High level ambient temperature for HTF mass flow rate parametric",               "C",		"",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_m_dot_htf_low",     "Low level normalized HTF mass flow rate for T_HTF parametric",                   "-",	    "",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "ud_m_dot_htf_high",    "High level normalized HTF mass flow rate for T_HTF parametric",                  "-",	    "",                            "user_defined_PC", "pc_config=1",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "ud_T_htf_ind_od",      "Off design table of user-defined power cycle performance formed from parametric on T_htf_hot [C]", "", "",               "user_defined_PC", "?=[[0]]",            "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "ud_T_amb_ind_od",      "Off design table of user-defined power cycle performance formed from parametric on T_amb [C]",	 "", "",               "user_defined_PC", "?=[[0]]",            "",                      "" ), 
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "ud_m_dot_htf_ind_od",  "Off design table of user-defined power cycle performance formed from parametric on m_dot_htf [ND]","", "",               "user_defined_PC", "?=[[0]]",            "",                      "" ), 
    var_info(
        SSC_INPUT,        SSC_MATRIX,      "ud_ind_od",            "Off design user-defined power cycle performance as function of T_htf, m_dot_htf [ND], and T_amb", "", "", "user_defined_PC", "?=[[0]]",     "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "eta_lhv",           "Fossil fuel lower heating value - Thermal power generated per unit fuel",   "MW/MMBTU",     "",                             "enet",           "*",                       "",                      "" ),
    var_info(
        SSC_INPUT,        SSC_NUMBER,      "eta_tes_htr",       "Thermal storage tank heater efficiency (fp_mode=1 only)",                   "none",         "",                             "enet",           "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "month",             "Resource Month",                                                  "",             "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "hour",              "Resource Hour of Day",                                            "",             "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "solazi",            "Resource Solar Azimuth",                                          "deg",          "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "solzen",            "Resource Solar Zenith",                                           "deg",          "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "beam",              "Resource Beam normal irradiance",                                 "W/m2",         "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "tdry",              "Resource Dry bulb temperature",                                   "C",            "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "twet",              "Resource Wet bulb temperature",                                   "C",            "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "wspd",              "Resource Wind Speed",                                             "m/s",          "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pres",              "Resource Pressure",                                               "mbar",         "",            "weather",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "tou_value",         "Resource Time-of-use value",                                      "",             "",            "tou",            "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "recirculating",          "Field recirculating (bypass valve open)",			        "-",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_diams",      "Field piping header diameters",							    "m",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_wallthk",    "Field piping header wall thicknesses",	    			    "m",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_lengths",    "Field piping header lengths",                               "m",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_expansions", "Number of field piping header expansions",                  "-",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_mdot_dsn",   "Field piping header mass flow at design",				    "kg/s",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_vel_dsn",    "Field piping header velocity at design",				    "m/s",           "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_T_dsn",      "Field piping header temperature at design",				    "C",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_header_P_dsn",      "Field piping header pressure at design",				    "bar",           "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_diams",      "Field piping runner diameters",								"m",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_wallthk",    "Field piping runner wall thicknesses",  					"m",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_lengths",    "Field piping runner lengths",								"m",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_expansions", "Number of field piping runner expansions",                  "-",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_mdot_dsn",   "Field piping runner mass flow at design",				    "kg/s",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_vel_dsn",    "Field piping runner velocity at design",				    "m/s",           "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_T_dsn",      "Field piping runner temperature at design",				    "C",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_runner_P_dsn",      "Field piping runner pressure at design",				    "bar",           "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_loop_T_dsn",        "Field piping loop temperature at design",				    "C",             "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_loop_P_dsn",        "Field piping loop pressure at design",				        "bar",           "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "Theta_ave",         "Field collector solar incidence angle",                          "deg",           "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "CosTh_ave",         "Field collector cosine efficiency",                              "",              "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "IAM_ave",           "Field collector incidence angle modifier",                       "",              "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "RowShadow_ave",     "Field collector row shadowing loss",                             "",              "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "EndLoss_ave",       "Field collector optical end loss",                               "",              "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "dni_costh",         "Field collector DNI-cosine product",                             "W/m2",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "SCAs_def",          "Field collector fraction of focused SCA's",                      "",              "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "EqOpteff",          "Field collector optical efficiency",                             "",              "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_inc_sf_tot",      "Field thermal power incident",                                   "MWt",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "qinc_costh",        "Field thermal power incident after cosine",                      "MWt",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_abs_tot",         "Field thermal power absorbed",                                   "MWt",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_dump",            "Field thermal power dumped",                                     "MWt",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_loss_tot",        "Field thermal power receiver loss",                              "MWt",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "Pipe_hl",           "Field thermal power header pipe losses",                         "MWt",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_avail",           "Field thermal power produced",                                   "MWt",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_loss_spec_tot",   "Field thermal power avg. receiver loss",                         "W/m",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "E_bal_startup",     "Field HTF energy inertial (consumed)",                           "MWht",          "",            "Type250",        "*",                      "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "m_dot_avail",       "Field HTF mass flow rate total",                                 "kg/hr",        "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "m_dot_htf2",        "Field HTF mass flow rate loop",                                  "kg/s",         "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "DP_tot",            "Field HTF pressure drop total",                                  "bar",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_sys_c",           "Field HTF temperature cold header inlet",                        "C",            "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_sys_h",           "Field HTF temperature hot header outlet",                        "C",            "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_field_in",        "Field HTF temperature collector inlet",                          "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_sgs_diams",    "Pipe diameters in SGS",                                          "m",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_sgs_wallthk",  "Pipe wall thickness in SGS",                                     "m",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_sgs_mdot_dsn", "Mass flow SGS pipes at design conditions",                       "kg/s",         "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_sgs_vel_dsn",  "Velocity in SGS pipes at design conditions",                     "m/s",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_sgs_T_dsn",    "Temperature in SGS pipes at design conditions",                  "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "pipe_sgs_P_dsn",    "Pressure in SGS pipes at design conditions",                     "bar",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "mass_tank_cold",    "TES HTF mass in cold tank",                                      "kg",           "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "mass_tank_hot",     "TES HTF mass in hot tank",                                       "kg",           "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "m_dot_charge_field","TES HTF mass flow rate - field side of HX",                      "kg/hr",        "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,     "m_dot_discharge_tank","TES HTF mass flow rate - storage side of HX",                    "kg/hr",        "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_tank_cold_fin",   "TES HTF temperature in cold tank",                               "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_tank_hot_fin",    "TES HTF temperature in hot tank",                                "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "Ts_hot",            "TES HTF temperature HX field side hot",                          "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "Ts_cold",           "TES HTF temperature HX field side cold",                         "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_tank_hot_in",     "TES HTF temperature hot tank inlet",                             "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_tank_cold_in",    "TES HTF temperature cold tank inlet",                            "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "vol_tank_cold_fin", "TES HTF volume in cold tank",                                    "m3",           "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "vol_tank_hot_fin",  "TES HTF volume in hot tank",                                     "m3",           "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "vol_tank_total",    "TES HTF volume total",                                           "m3",           "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_to_tes",          "TES thermal energy into storage",                                "MWt",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "tank_losses",       "TES thermal losses from tank(s)",                                "MWt",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "eta",               "Cycle efficiency (gross)",                                       "",         "",            "Type224",        "*",                           "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "W_net",             "Cycle electrical power output (net)",                            "MWe",          "",            "Net_E_Calc",     "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "W_cycle_gross",     "Cycle electrical power output (gross)",                          "MWe",          "",            "Net_E_Calc",     "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "m_dot_pb",          "Cycle HTF mass flow rate",                                       "kg/hr",        "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_pb_in",           "Cycle HTF temperature in (hot)",                                 "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "T_pb_out",          "Cycle HTF temperature out (cold)",                               "C",            "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "m_dot_makeup",      "Cycle cooling water mass flow rate - makeup",                    "kg/hr",        "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "q_pb",              "Cycle thermal power input",                                      "MWt",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "Q_aux_backup",      "Fossil thermal power produced",                                  "MWt",          "",            "SumCalc",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "m_dot_aux",         "Fossil HTF mass flow rate",                                      "kg/hr",        "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "Fuel_usage",        "Fossil fuel usage (all subsystems)",                             "MMBTU",        "",            "SumCalc",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "W_dot_pump",        "Parasitic power solar field HTF pump",                           "MWe",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "htf_pump_power",    "Parasitic power TES and Cycle HTF pump",                         "MWe",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "SCA_par_tot",       "Parasitic power field collector drives",                         "MWe",          "",            "Type250",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "bop_par",           "Parasitic power generation-dependent load",                      "MWe",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "fixed_par",         "Parasitic power fixed load",                                     "MWe",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "aux_par",           "Parasitic power auxiliary heater operation",                     "MWe",          "",            "Type251",        "*",                       "",                      "" ),
    var_info(
        SSC_OUTPUT,       SSC_ARRAY,       "W
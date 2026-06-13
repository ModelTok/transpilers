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
from tckernel import *
from common import *

var _cm_vtab_tcstrough_empirical: StaticArray[var_info] = [
/*   VARTYPE            DATATYPE          NAME                 LABEL                                                            UNITS           META            GROUP            REQUIRED_IF                 CONSTRAINTS             UI_HINTS  */
    { SSC_INPUT,        SSC_STRING,      "file_name",         "local weather file path",                                        "",             "",            "Weather",        "*",                       "LOCAL_FILE",            "" },
    { SSC_INPUT,        SSC_NUMBER,      "track_mode",        "Tracking mode",                                                  "",             "",            "Weather",        "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "tilt",              "Tilt angle of surface/axis",                                     "",             "",            "Weather",        "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "azimuth",           "Azimuth angle of surface/axis",                                  "",             "",            "Weather",        "*",                       "",                      "" }, 
	{ SSC_INPUT, SSC_NUMBER, "system_capacity", "Nameplate capacity", "kW", "", "trough", "*", "", "" },
    { SSC_INPUT,        SSC_MATRIX,      "weekday_schedule",  "12x24 Time of Use Values for week days",                         "",             "",            "tou_translator", "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_MATRIX,      "weekend_schedule",  "12x24 Time of Use Values for week end days",                     "",             "",            "tou_translator", "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "i_SfTi",            "Solar Field HTF inlet Temperature (if -999, calculated)",        "C",            "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfPipeHl300",       "Solar field piping heat loss at design",                         "W/m2",         "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfPipeHl1",         "Solar field piping heat loss at reduced temp. - linear term",    "C^(-1)",       "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfPipeHl2",         "Solar field piping heat loss at reduced temp. - quadratic term", "C^(-2)",       "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfPipeHl3",         "Solar field piping heat loss at reduced temp. - cubic term",     "C^(-3)",       "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "Stow_Angle",        "Night-Time Trough Stow Angle",                                   "deg",          "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "DepAngle",          "Deployment Angle",                                               "deg",          "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "Distance_SCA",      "Distance between SCAs in Row",                                   "m",            "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "Row_Distance",      "Distance between Rows of SCAs",                                  "m",            "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "NumScas",           "Number of SCAs per Row",                                         "",             "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "Solar_Field_Area",  "Solar Field Area",                                               "m2",           "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "Solar_Field_Mult",  "Solar Field Multiple",                                           "",             "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfInTempD",         "Solar Field Design Inlet Temperature",                           "C",            "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfOutTempD",        "Solar Field Design Outlet Temperature",                          "C",            "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "MinHtfTemp",        "Minimum Heat Transfer Fluid Temperature",                        "C",            "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HtfGalArea",        "HTF Fluids in Gallons per Field Area",                           "gal/m2",       "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SFTempInit",        "Solar Field Initial Temperature",                                "C",            "",            "solarfield",     "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HTFFluid",          "Type of Heat Transfer Fluid used",                               "",             "",            "solarfield",     "*",                       "INTEGER",               "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "IamF0",             "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "IamF1",             "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "IamF2",             "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "Ave_Focal_Length",  "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "ScaLen",            "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SCA_aper",          "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfAvail",           "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TrkTwstErr",        "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "GeoAcc",            "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "MirRef",            "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "MirCln",            "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "ConcFac",           "Label",                                                          "",             "",            "sca",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "NumHCETypes",       "Number of HCE types",                                            "",             "",            "hce",            "*",                       "INTEGER",               "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCEtype",           "Number indicating the receiver type",                            "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCEFrac",           "Fraction of field that is this type of HCE",                     "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCEdust",           "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCEBelShad",        "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCEEnvTrans",       "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCEabs",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCEmisc",           "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "PerfFac",           "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "RefMirrAper",       "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCE_A0",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCE_A1",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCE_A2",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCE_A3",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCE_A4",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCE_A5",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "HCE_A6",            "label",                                                          "",             "",            "hce",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TurbOutG",          "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TurbEffG",          "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "PTTMAX",            "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "PTTMIN",            "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "MaxGrOut",          "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "MinGrOut",          "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TurSUE",            "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "T2EPLF0",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "T2EPLF1",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "T2EPLF2",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "T2EPLF3",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "T2EPLF4",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "E2TPLF0",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "E2TPLF1",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "E2TPLF2",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "E2TPLF3",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "E2TPLF4",           "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TempCorrF",         "Temp Correction Mode (0=wetbulb 1=drybulb basis)",               "",             "",            "pwrb",           "*",                       "INTEGER",               "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TempCorr0",         "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TempCorr1",         "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TempCorr2",         "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TempCorr3",         "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TempCorr4",         "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "LHVBoilEff",        "Label",                                                          "",             "",            "pwrb",           "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TurTesEffAdj",      "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TurTesOutAdj",      "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TnkHL",             "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "PTSmax",            "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "PFSmax",            "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "TSHOURS",           "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "NUMTOU",            "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_MATRIX,      "TSLogic",           "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_ARRAY,       "FossilFill",        "Label",                                                          "",             "",            "tes",            "*",                       "",                      "" }, 
	{ SSC_INPUT,		SSC_NUMBER,      "E_tes_ini",         "Initial TES energy - fraction of max",							"",				"",			   "tes",            "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "SfPar",             "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "SfParPF",           "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "ChtfPar",           "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "ChtfParPF",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CHTFParF0",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CHTFParF1",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CHTFParF2",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "AntiFrPar",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "BOPPar",            "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "BOPParPF",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "BOPParF0",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "BOPParF1",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "BOPParF2",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CtOpF",             "Label",                                                          "",             "",            "parasitic",      "*",                       "INTEGER",               "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CtPar",             "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CtParPF",           "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CtParF0",           "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CtParF1",           "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "CtParF2",           "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HtrPar",            "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HtrParPF",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HtrParF0",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HtrParF1",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HtrParF2",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HhtfPar",           "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HhtfParPF",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HhtfParF0",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HhtfParF1",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "HhtfParF2",         "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "PbFixPar",          "Label",                                                          "",             "",            "parasitic",      "*",                       "",                      "" }, 
    { SSC_OUTPUT,       SSC_ARRAY,       "month",             "Resource Month",                                                  "",             "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "hour",              "Resource Hour of Day",                                            "",             "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "solazi",            "Resource Solar Azimuth",                                          "deg",          "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "solzen",            "Resource Solar Zenith",                                           "deg",          "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "beam",              "Resource Beam normal irradiance",                                 "W/m2",         "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "tdry",              "Resource Dry bulb temperature",                                   "C",            "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "twet",              "Resource Wet bulb temperature",                                   "C",            "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "wspd",              "Resource Wind Speed",                                             "m/s",          "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "pres",              "Resource Pressure",                                               "mbar",         "",            "weather",        "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "tou_value",         "Resource time-of-use value",                                      "",             "",            "tou",            "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "TrackAngle",        "Field collector tracking angle",                                 "deg",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Theta",             "Field collector solar incidence angle",                          "deg",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "CosTheta",          "Field collector cosine efficiency",                              "",             "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "IAM",               "Field collector incidence angle modifier",                       "",             "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "RowShadow",         "Field collector row shadowing loss",                             "",             "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "EndLoss",           "Field collector optical end loss",                               "",             "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "QnipCosTh",         "Field collector DNI-cosine product",                             "W/m2",         "",            "type_805",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Ftrack",            "Field collector fraction of time period tracking",               "",             "",            "other",          "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "ColEff", 	          "Field collector thermal and optical efficiency",                 "",             "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Qdni",              "Field thermal power total incident",                             "MWt",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Qsfnipcosth",       "Field thermal power incident after cosine",                      "MWt",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "QsfAbs",            "Field thermal power absorbed",                                   "MWt",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "RecHl",             "Field thermal power receiver heat loss",                         "kJ/hr-m2",     "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "QsfHceHL",          "Field thermal power receiver total loss",                        "MWt",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "QsfPipeHL",         "Field thermal power pipe losses",                                "MWt",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Qsf",               "Field thermal power total produced",                             "MWt",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "QsfWarmup",         "Field HTF energy inertial (consumed)",                           "MWht",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "SfMassFlow",        "Field HTF mass flow rate total",                                 "kg/s",        "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "o_SfTi",            "Field HTF temperature cold header inlet",                        "C",            "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "SfTo",              "Field HTF temperature hot header outlet",                        "C",            "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "AveSfTemp",         "Field HTF temperature average",                                  "C",            "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Qtts",              "TES thermal energy into storage",                                "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Qfts",              "TES thermal energy from storage",                                "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Ets",               "TES thermal energy available",                                   "MWht",       "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "QTsHl",             "TES thermal losses from tank(s)",                                "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Enet",              "Cycle electrical power output (net)",                            "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Egr",               "Cycle electrical power output (gross)",                          "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EgrSol",            "Cycle electrical power output (gross, solar share)",             "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EgrFos",            "Cycle electrical power output (gross, fossil share)",            "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Qtpb",              "Cycle thermal power input",                                      "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "QTurSu",            "Cycle thermal startup energy",                                   "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "QTsFull",           "Cycle thermal energy dumped - TES is full",                      "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Qmin",              "Cycle thermal energy dumped - min. load requirement",            "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "Qdump",             "Cycle thermal energy dumped - solar field",                      "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Qgas",              "Fossil thermal power produced",                                  "MWt",           "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "QhtfFpHtr",         "Fossil freeze protection provided",                              "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparCHTF",          "Parasitic power solar field HTF pump",                           "MWe",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparHhtf",          "Parasitic power TES and Cycle HTF pump",                         "MWe",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparSf",            "Parasitic power field collector drives",                         "MWe",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparBOP",           "Parasitic power generation-dependent load",                      "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparPB",            "Parasitic power fixed load",                                     "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparHtr",           "Parasitic power auxiliary heater operation",                     "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparCT",            "Parasitic power condenser operation",                            "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparAnti",          "Parasitic power freeze protection pump",                         "MWe",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
    { SSC_OUTPUT,       SSC_ARRAY,       "QhtfFreezeProt",    "Parasitic thermal field freeze protection",                      "MWt",          "",            "type_805",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "QhtfFpTES",         "Parasitic thermal TES freeze protection",                        "MWt",          "",            "type_806",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparOffLine",       "Parasitic power - offline total",                                "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "EparOnLine",        "Parasitic power - online total",                                 "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT,       SSC_ARRAY,       "Epar",              "Parasitic power total consumption",                              "MWe",          "",            "type_807",       "*",                       "LENGTH=8760",           "" },
	{ SSC_OUTPUT, SSC_NUMBER, "system_use_lifetime_output", "Use lifetime output", "0/1", "", "tcs_trough_empirical", "*", "INTEGER", "" },
    { SSC_OUTPUT, SSC_ARRAY, "monthly_energy", "Monthly energy", "kWh", "", "tcs_trough_empirical", "*", "", "" },
    { SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual energy", "kWh", "", "tcs_trough_empirical", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "annual_W_cycle_gross", "Electrical source - Power cycle gross output", "kWh", "", "tcs_trough_empirical", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "conversion_factor", "Gross to Net Conversion Factor", "%", "", "Calculated", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "System heat rate", "MMBtu/MWh", "", "", "*", "", "" },
	{ SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual fuel usage", "kWh", "", "", "*", "", "" },
    var_info_invalid ]

class cm_tcstrough_empirical(tcKernel):
    def __init__(self, prov: tcstypeprovider):
        tcKernel.__init__(self, prov)
        self.add_var_info(_cm_vtab_tcstrough_empirical)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        var debug_mode: Bool = (__DEBUG__ == 1)  # When compiled in VS debug mode, this will use the trnsys weather file; otherwise, it will attempt to open the file with name that was passed in
        var weather: Int = 0
        debug_mode = False
        if debug_mode:
            weather = self.add_unit("trnsys_weatherreader", "TRNSYS weather reader")
        else:
            weather = self.add_unit("weatherreader", "TCS weather reader")
        var tou: Int = self.add_unit("tou_translator", "Time of Use Translator")
        var type805_solarfield: Int = self.add_unit("sam_trough_model_type805", "Test Trough")
        var type806_storage: Int = self.add_unit("sam_trough_storage_type806", "Test Storage")
        var type807_powerblock: Int = self.add_unit("sam_trough_plant_type807", "Test Plant")
        if debug_mode:
            self.set_unit_value(weather, "file_name", "C:/svn_NREL/main/ssc/tcsdata/typelib/TRNSYS_weather_outputs/tucson_trnsys_weather.out")
            self.set_unit_value(weather, "i_hour", "TIME")
            self.set_unit_value(weather, "i_month", "month")
            self.set_unit_value(weather, "i_day", "day")
            self.set_unit_value(weather, "i_global", "GlobalHorizontal")
            self.set_unit_value(weather, "i_beam", "DNI")
            self.set_unit_value(weather, "i_diff", "DiffuseHorizontal")
            self.set_unit_value(weather, "i_tdry", "T_dry")
            self.set_unit_value(weather, "i_twet", "T_wet")
            self.set_unit_value(weather, "i_tdew", "T_dew")
            self.set_unit_value(weather, "i_wspd", "WindSpeed")
            self.set_unit_value(weather, "i_wdir", "WindDir")
            self.set_unit_value(weather, "i_rhum", "RelHum")
            self.set_unit_value(weather, "i_pres", "AtmPres")
            self.set_unit_value(weather, "i_snow", "SnowCover")
            self.set_unit_value(weather, "i_albedo", "GroundAlbedo")
            self.set_unit_value(weather, "i_poa", "POA")
            self.set_unit_value(weather, "i_solazi", "Azimuth")
            self.set_unit_value(weather, "i_solzen", "Zenith")
            self.set_unit_value(weather, "i_lat", "Latitude")
            self.set_unit_value(weather, "i_lon", "Longitude")
            self.set_unit_value(weather, "i_shift", "Shift")
        else:
            self.set_unit_value_ssc_string(weather, "file_name")
            self.set_unit_value_ssc_double(weather, "track_mode")    # , 0 ); SET TO 3 IN TRNSYS FILE, no user input !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            self.set_unit_value_ssc_double(weather, "tilt")          # , 0 );
            self.set_unit_value_ssc_double(weather, "azimuth")       # , 0 );
        self.set_unit_value_ssc_matrix(tou, "weekday_schedule") # tou values from control will be between 1 and 9
        self.set_unit_value_ssc_matrix(tou, "weekend_schedule")
        self.set_unit_value_ssc_double(type805_solarfield, "Solar_Field_Area")   # , 877580 ); csp.tr.solf.dp.fieldarea
        self.set_unit_value_ssc_double(type805_solarfield, "Solar_Field_Mult")   # , 2 ); csp.tr.solf.dp.solarmultiple
        self.set_unit_value_ssc_double(type805_solarfield, "HTFFluid")           # , 21 ); TranslateHTFType( IVal("csp.tr.solf.fieldhtftype")
        self.set_unit_value_ssc_double(type805_solarfield, "NumHCETypes")        # , 4 );
        self.set_unit_value_ssc_array(type805_solarfield, "HCEtype")      #                      {1,1,1,1},
        self.set_unit_value_ssc_array(type805_solarfield, "HCEFrac")      #                      {0.985,0.01,0.005,0},
        self.set_unit_value_ssc_array(type805_solarfield, "HCEdust")      #, t[2], 4 );       # {0.98,0.98,0.98,0.98},
        self.set_unit_value_ssc_array(type805_solarfield, "HCEBelShad")   #, t[3], 4  );      # {0.963,0.963,0.963,0.963},
        self.set_unit_value_ssc_array(type805_solarfield, "HCEEnvTrans")  #, t[4], 4  );      # {0.963,0.963,1,0.963},
        self.set_unit_value_ssc_array(type805_solarfield, "HCEabs")       #, t[5], 4  );      # {0.96,0.96,0.8,0.96},  
        self.set_unit_value_ssc_array(type805_solarfield, "HCEmisc")      #, t[6], 4  );      # {1,1,1,1},   
        self.set_unit_value_ssc_array(type805_solarfield, "PerfFac")      #, t[7], 4 );       # {1,1,1,1},                
        self.set_unit_value_ssc_array(type805_solarfield, "RefMirrAper")  #, t[8], 4  );      # {5,5,5,5},   
        self.set_unit_value_ssc_array(type805_solarfield, "HCE_A0")       #, t[9], 4  );      # {4.05,      50.8,      -9.95,     11.8},  
        self.set_unit_value_ssc_array(type805_solarfield, "HCE_A1")       #, t[10], 4  );     # {0.247,     0.904,      0.465,    1.35},   
        self.set_unit_value_ssc_array(type805_solarfield, "HCE_A2")       #, t[11], 4 );      # {-0.00146,  0.000579,  -0.000854, 0.0075} ,  
        self.set_unit_value_ssc_array(type805_solarfield, "HCE_A3")       #, t[12], 4 );      # {5.65e-6,   1.13e-5,    1.85e-5,  4.07e-6},  
        self.set_unit_value_ssc_array(type805_solarfield, "HCE_A4")       #, t[13], 4 );      # {7.62e-8,   1.73e-7,    6.89e-7,  5.85e-8} ,  
        self.set_unit_value_ssc_array(type805_solarfield, "HCE_A5")       #, t[14], 4 );      # {-1.7,     -43.2,       24.7,     4.48},  
        self.set_unit_value_ssc_array(type805_solarfield, "HCE_A6")       #, t[15], 4 );      # {0.0125,    0.524,      3.37,     0.285}      
        self.set_unit_value_ssc_double(type805_solarfield, "i_SfTi")       #,           -999 );           
        self.set_unit_value_ssc_double(type805_solarfield, "Stow_Angle")       #, 	    170);     # csp.tr.solf.stowangle
        self.set_unit_value_ssc_double(type805_solarfield, "DepAngle")       #, 	        10);      # csp.tr.solf.deployangle
        self.set_unit_value_ssc_double(type805_solarfield, "IamF0")       #, 	        1);       # csp.tr.sca.iamc1
        self.set_unit_value_ssc_double(type805_solarfield, "IamF1")       #, 	        0.0506);  # csp.tr.sca.iamc2
        self.set_unit_value_ssc_double(type805_solarfield, "IamF2")       #, 	        -0.1763); # csp.tr.sca.iamc3
        self.set_unit_value_ssc_double(type805_solarfield, "Ave_Focal_Length")       #,  1.8);     # csp.tr.sca.avg_focal_length
        self.set_unit_value_ssc_double(type805_solarfield, "Distance_SCA")       #, 	    1);       # csp.tr.solf.distscas
        self.set_unit_value_ssc_double(type805_solarfield, "Row_Distance")       #, 	    15);      # csp.tr.solf.distrows
        self.set_unit_value_ssc_double(type805_solarfield, "SCA_aper")       #, 	        5);       # csp.tr.sca.aperture
        self.set_unit_value_ssc_double(type805_solarfield, "SfAvail")       #, 	        0.99);    # csp.tr.sca.availability 
        self.set_unit_value_ssc_double(type805_solarfield, "ColTilt", self.as_double("tilt"))       
        self.set_unit_value_ssc_double(type805_solarfield, "ColAz", self.as_double("azimuth"))      
        self.set_unit_value_ssc_double(type805_solarfield, "NumScas")       #, 	        4);       # csp.tr.solf.nscasperloop
        self.set_unit_value_ssc_double(type805_solarfield, "ScaLen")       #, 	        100);     # csp.tr.sca.length
        self.set_unit_value_ssc_double(type805_solarfield, "MinHtfTemp")       #, 	    50);      # csp.tr.solf.htfmintemp
        self.set_unit_value_ssc_double(type805_solarfield, "HtfGalArea")       #, 	    0.614);   # csp.tr.solf.htfgallonsperarea
        self.set_unit_value_ssc_double(type805_solarfield, "SfPar")       #, 	        0.233436);// csp.tr.par.sf.total
        self.set_unit_value_ssc_double(type805_solarfield, "SfParPF")       #, 	        1);       # csp.tr.par.sf.partload
        self.set_unit_value_ssc_double(type805_solarfield, "ChtfPar")       #, 	        9.23214); # csp.tr.par.htfpump.total
        self.set_unit_value_ssc_double(type805_solarfield, "ChtfParPF")       #, 	    1);       # csp.tr.par.htfpump.partload
        self.set_unit_value_ssc_double(type805_solarfield, "CHTFParF0")       #, 	    -0.036);  # csp.tr.par.htfpump.f0
        self.set_unit_value_ssc_double(type805_solarfield, "CHTFParF1")       #, 	    0.242);   # csp.tr.par.htfpump.f1
        self.set_unit_value_ssc_double(type805_solarfield, "CHTFParF2")       #, 	    0.794);   # csp.tr.par.htfpump.f2
        self.set_unit_value_ssc_double(type805_solarfield, "AntiFrPar")       #, 	    0.923214);// csp.tr.par.antifreeze.total
        self.set_unit_value_ssc_double(type805_solarfield, "TurbOutG")       #, 	       111);      # csp.tr.pwrb.design_gross_output
        self.set_unit_value_ssc_double(type805_solarfield, "TurbEffG")       #, 	       0.3774);   # csp.tr.pwrb.effdesign
        self.set_unit_value_ssc_double(type805_solarfield, "SfInTempD")       #, 	   293);      # csp.tr.solf.htfinlettemp
        self.set_unit_value_ssc_double(type805_solarfield, "SfOutTempD")       #, 	   391);      # csp.tr.solf.htfoutlettemp
        self.set_unit_value_ssc_double(type805_solarfield, "TrkTwstErr")       #, 	   0.994);     # csp.tr.sca.track_twist_error
        self.set_unit_value_ssc_double(type805_solarfield, "GeoAcc")       #, 	       0.98);      # csp.tr.sca.geometric_accuracy
        self.set_unit_value_ssc_double(type805_solarfield, "MirRef")       #, 	       0.935);     # csp.tr.sca.reflectivity
        self.set_unit_value_ssc_double(type805_solarfield, "MirCln")       #, 	       0.95);      # csp.tr.sca.cleanliness
        self.set_unit_value_ssc_double(type805_solarfield, "ConcFac")       #, 	       1);         # csp.tr.sca.concentrator_factor
        self.set_unit_value_ssc_double(type805_solarfield, "SfPipeHl300")       #, 	   10);        # csp.tr.solf.pipingheatlossatdesign
        self.set_unit_value_ssc_double(type805_solarfield, "SfPipeHl1")       #, 	   0.001693);  # csp.tr.solf.pipingheatlosscoeff1
        self.set_unit_value_ssc_double(type805_solarfield, "SfPipeHl2")       #, 	   -1.683e-5); # csp.tr.solf.pipingheatlosscoeff2
        self.set_unit_value_ssc_double(type805_solarfield, "SfPipeHl3")       #, 	   6.78e-8);   # csp.tr.solf.pipingheatlosscoeff3
        self.set_unit_value_ssc_double(type805_solarfield, "SFTempInit")       #,       100);	   # csp.tr.solf.htfinittemp
        var bConnected: Bool = self.connect(weather, "solazi", type805_solarfield, "SolarAz", 0.1, -1)                
        bConnected &= self.connect(weather, "beam", type805_solarfield, "Insol_Beam_Normal", 0.1, -1)
        bConnected &= self.connect(weather, "tdry", type805_solarfield, "AmbientTemperature", 0.1, -1)
        bConnected &= self.connect(weather, "wspd", type805_solarfield, "WndSpd", 0.1, -1)
        bConnected &= self.connect(weather, "shift", type805_solarfield, "SHIFT", 0.1, -1)
        bConnected &= self.connect(weather, "lat", type805_solarfield, "Site_Lat", 0.1, -1)
        bConnected &= self.connect(weather, "lon", type805_solarfield, "Site_LongD", 0.1, -1)
        self.set_unit_value_ssc_double(type806_storage, "TSHOURS")       #,6);          # csp.tr.tes.full_load_hours
        self.set_unit_value_ssc_double(type806_storage, "NUMTOU")       #, 9);
        self.set_unit_value_ssc_double(type806_storage, "E2TPLF0")       #, 0.03737);   # csp.tr.pwrb.tpl_tff0
        self.set_unit_value_ssc_double(type806_storage, "E2TPLF1")       #, 0.98823);   # csp.tr.pwrb.tpl_tff1
        self.set_unit_value_ssc_double(type806_storage, "E2TPLF2")       #, -0.064991); # csp.tr.pwrb.tpl_tff2
        self.set_unit_value_ssc_double(type806_storage, "E2TPLF3")       #, 0.039388);  # csp.tr.pwrb.tpl_tff3
        self.set_unit_value_ssc_double(type806_storage, "E2TPLF4")       #, 0.0);       # csp.tr.pwrb.tpl_tff4
        self.set_unit_value_ssc_matrix(type806_storage, "TSLogic") # csp.tr.tes.dispX.solar, csp.tr.tes.dispX.nosolar, csp.tr.tes.dispX.turbout,  where X = 1 to 9
        self.set_unit_value_ssc_double(type806_storage, "E_tes_ini")	
        self.set_unit_value_ssc_double(type806_storage, "TnkHL")        #, 	 0.97);            # csp.tr.tes.tank_heatloss
        self.set_unit_value_ssc_double(type806_storage, "PTSmax")       #,  294.118);	       # csp.tr.tes.max_to_power
        self.set_unit_value_ssc_double(type806_storage, "PFSmax")       #,  297.999);	       # csp.tr.tes.max_from_power
        self.set_unit_value_ssc_double(type806_storage, "PTTMAX")       #,  1.05);            # csp.tr.pwrb.maxoutput
        self.set_unit_value_ssc_double(type806_storage, "PTTMIN")       #,  0.25);	           # csp.tr.pwrb.minoutput
        self.set_unit_value_ssc_double(type806_storage, "TurSUE")       #,  0.2);	           # csp.tr.pwrb.startup_energy
        self.set_unit_value_ssc_double(type806_storage, "HhtfPar")       #, 	 2.22);        # csp.tr.par.tes.total
        self.set_unit_value_ssc_double(type806_storage, "HhtfParPF")       #,   1);           # csp.tr.par.tes.partload
        self.set_unit_value_ssc_double(type806_storage, "HhtfParF0")       #,   -0.036);      # csp.tr.par.tes.f0
        self.set_unit_value_ssc_double(type806_storage, "HhtfParF1")       #,    0.242);      # csp.tr.par.tes.f1
        self.set_unit_value_ssc_double(type806_storage, "HhtfParF2")       #,    0.794);      # csp.tr.par.tes.f2
        bConnected &= self.connect(type805_solarfield, "Qsf", type806_storage, "Qsf", 0.1, -1)
        bConnected &= self.connect(type805_solarfield, "Qdesign", type806_storage, "Qdesign", 0.1, -1)
        bConnected &= self.connect(type805_solarfield, "QhtfFreezeProt", type806_storage, "QhtfFreezeProt", 0.1, -1)  	
        bConnected &= self.connect(tou, "tou_value", type806_storage, "TOUPeriod")  	
        self.set_unit_value_ssc_double(type807_powerblock,"T2EPLF0")       #, -0.037726);	    # csp.tr.pwrb.tpl_tef0
        self.set_unit_value_ssc_double(type807_powerblock,"T2EPLF1")       #, 1.0062);	    # csp.tr.pwrb.tpl_tef1
        self.set_unit_value_ssc_double(type807_powerblock,"T2EPLF2")       #, 0.076316);      # csp.tr.pwrb.tpl_tef2
        self.set_unit_value_ssc_double(type807_powerblock,"T2EPLF3")       #, -0.044775);	    # csp.tr.pwrb.tpl_tef3
        self.set_unit_value_ssc_double(type807_powerblock,"T2EP
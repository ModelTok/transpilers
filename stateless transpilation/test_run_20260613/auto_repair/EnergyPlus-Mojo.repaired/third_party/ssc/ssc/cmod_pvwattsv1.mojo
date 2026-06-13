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
from common import *
from lib_weatherfile import *
from lib_irradproc import *
from lib_pvwatts import *
from lib_pvshade import *
from lib_util import *
from memory import DType
from math import fabs, pi, sin, cos, tan, asin, acos, atan2, sqrt, exp, pow, log, log10, floor, ceil, round
from math import DTypePointer, UInt8, Int32, Int64, Float32, Float64
from sys import info as sys_info

alias var_info = _cm_vtab_pvwattsv1

var _cm_vtab_pvwattsv1: StaticTuple[SSC_INPUT_COUNT + SSC_OUTPUT_COUNT + 1, var_info] = [
    /*   VARTYPE           DATATYPE         NAME                         LABEL                                               UNITS     META                      GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
        { SSC_INPUT,        SSC_STRING,      "solar_resource_file",             "local weather file path",                     "",       "",                        "Weather",      "*",                       "LOCAL_FILE",      "" },
        { SSC_INPUT,        SSC_NUMBER,      "albedo",                         "Albedo (ground reflectance)",                 "frac",   "",                        "PVWatts",      "?",                       "",                                         "" },
        { SSC_INPUT,        SSC_NUMBER,      "system_size",                    "Nameplate capacity",                          "kW",     "",                        "PVWatts",      "*",                       "",                      "" },
        { SSC_INPUT,        SSC_NUMBER,      "derate",                         "System derate value",                         "frac",   "",                        "PVWatts",      "*",                       "MIN=0,MAX=1",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "track_mode",                     "Tracking mode",                               "0/1/2/3","Fixed,1Axis,2Axis,AziAxis","PVWatts",      "*",                       "MIN=0,MAX=3,INTEGER",                      "" },
        { SSC_INPUT,        SSC_NUMBER,      "azimuth",                        "Azimuth angle",                               "deg",    "E=90,S=180,W=270",        "PVWatts",      "*",                       "MIN=0,MAX=360",                            "" },
        { SSC_INPUT,        SSC_NUMBER,      "tilt",                           "Tilt angle",                                  "deg",    "H=0,V=90",                "PVWatts",      "naof:tilt_eq_lat",        "MIN=0,MAX=90",                             "" },
        { SSC_INPUT,        SSC_NUMBER,      "tilt_eq_lat",                    "Tilt=latitude override",                      "0/1",    "",                        "PVWatts",      "na:tilt",                 "BOOLEAN",                                  "" },
        /* shading inputs */
        { SSC_INPUT,        SSC_MATRIX,      "shading:timestep",               "Time step beam shading factors",                 "",       "",                        "PVWatts",      "?",                        "",                              "" },
        { SSC_INPUT,        SSC_MATRIX,      "shading:mxh",                    "Month x Hour beam shading factors",           "",       "",                        "PVWatts",      "?",                        "",                              "" },
        { SSC_INPUT,        SSC_MATRIX,      "shading:azal",                   "Azimuth x altitude beam shading factors",     "",       "",                        "PVWatts",      "?",                        "",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "shading:diff",                   "Diffuse shading factor",                      "",       "",                        "PVWatts",      "?",                        "",                              "" },
        /* advanced parameters */
        { SSC_INPUT,        SSC_NUMBER,      "enable_user_poa",                "Enable user-defined POA irradiance input",    "0/1",    "",                        "PVWatts",      "?=0",                     "BOOLEAN",                                  "" },
        { SSC_INPUT,        SSC_ARRAY,       "user_poa",                       "User-defined POA irradiance",                 "W/m2",   "",                        "PVWatts",      "enable_user_poa=1",       "LENGTH=8760",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "rotlim",                         "Tracker rotation limit (+/- 1 axis)",         "deg",    "",                        "PVWatts",      "?=45.0",                  "MIN=1,MAX=90",                             "" },
        { SSC_INPUT,        SSC_NUMBER,      "inoct",                          "Nominal operating cell temperature",          "C",      "",                        "PVWatts",      "?=45.0",                  "POSITIVE",                                 "" },
        { SSC_INPUT,        SSC_NUMBER,      "tref",                           "Reference cell temperature",                  "C",      "",                        "PVWatts",      "?=25.0",                  "POSITIVE",                                 "" },
        { SSC_INPUT,        SSC_NUMBER,      "gamma",                          "Max power temperature coefficient",           "%/C",    "",                        "PVWatts",      "?=-0.5",                  "",                                         "" },
        { SSC_INPUT,        SSC_NUMBER,      "inv_eff",                        "Inverter efficiency at rated power",          "frac",   "",                        "PVWatts",      "?=0.92",                  "MIN=0,MAX=1",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "fd",                             "Diffuse fraction",                            "0..1",   "",                        "PVWatts",      "?=1.0",                   "MIN=0,MAX=1",                              "" },
        { SSC_INPUT,        SSC_NUMBER,      "i_ref",                          "Rating condition irradiance",                 "W/m2",   "",                        "PVWatts",      "?=1000",                  "POSITIVE",                                 "" },
        { SSC_INPUT,        SSC_NUMBER,      "poa_cutin",                      "Min reqd irradiance for operation",           "W/m2",   "",                        "PVWatts",      "?=0",                     "MIN=0",                                    "" },
        { SSC_INPUT,        SSC_NUMBER,      "w_stow",                         "Wind stow speed",                             "m/s",    "",                        "PVWatts",      "?=0",                     "MIN=0",                                    "" },
        { SSC_INPUT,        SSC_NUMBER,      "concen",                         "Concentration ratio",                         "",       "",                        "PVWatts",      "?=1",                     "MIN=1",                                    "" },
        { SSC_INPUT,        SSC_NUMBER,      "fhconv",                         "Convective heat transfer factor",             "",       "",                        "PVWatts",      "?=1",                     "MIN=0.1",                                  "" },
        { SSC_INPUT,        SSC_NUMBER,      "shade_mode_1x",                  "Tracker self-shading mode",                   "0/1/2",  "0=shading,1=backtrack,2=none","PVWatts",  "?=2",                     "INTEGER,MIN=0,MAX=2",           "" },
        { SSC_INPUT,        SSC_NUMBER,      "gcr",                            "Ground coverage ratio",                       "0..1",   "",                            "PVWatts",  "?=0.3",                   "MIN=0,MAX=3",               "" },
        { SSC_INPUT,        SSC_NUMBER,      "ar_glass",                       "Enable anti-reflective glass coating (beta)",         "0/1",    "",                        "PVWatts",      "?=0",                     "BOOLEAN",                   "" },
        { SSC_INPUT,        SSC_NUMBER,      "u0",                           "thermal model coeff U0",                                  "",    "",                "PVWatts",      "?",        "",                             "" },
        { SSC_INPUT,        SSC_NUMBER,      "u1",                           "thermal model coeff U0",                                  "",    "",                "PVWatts",      "?",        "",                             "" },
        /* outputs */
        { SSC_OUTPUT,       SSC_ARRAY,       "gh",                             "Global horizontal irradiance",                "W/m2",   "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "dn",                             "Beam irradiance",                             "W/m2",   "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "df",                             "Diffuse irradiance",                          "W/m2",   "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "tamb",                           "Ambient temperature",                         "C",      "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "tdew",                           "Dew point temperature",                       "C",      "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "wspd",                           "Wind speed",                                  "m/s",    "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "poa",                            "Plane of array irradiance",                   "W/m2",   "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "tpoa",                           "Transmitted plane of array irradiance",       "W/m2",   "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "tcell",                          "Module temperature",                          "C",      "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "dc",                             "DC array output",                             "Wdc",    "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
        { SSC_OUTPUT,       SSC_ARRAY,       "ac",                             "AC system output",                            "Wac",    "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
            { SSC_OUTPUT,       SSC_ARRAY,       "shad_beam_factor",               "Shading factor for beam radiation",           "",       "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
            { SSC_OUTPUT,       SSC_ARRAY,       "sunup",                          "Sun up over horizon",                         "0/1",    "",                        "Hourly",        "*",                       "LENGTH=8760",                          "" },
            { SSC_OUTPUT,       SSC_ARRAY,       "poa_monthly",                    "Plane of array irradiance",                   "kWh/m2",   "",                      "Monthly",       "*",                       "LENGTH=12",                          "" },
            { SSC_OUTPUT,       SSC_ARRAY,       "solrad_monthly",                 "Daily average solar irradiance",              "kWh/m2/day","",                     "Monthly",       "*",                       "LENGTH=12",                          "" },
            { SSC_OUTPUT,       SSC_ARRAY,       "dc_monthly",                     "DC array output",                             "kWhdc",    "",                      "Monthly",       "*",                       "LENGTH=12",                          "" },
            { SSC_OUTPUT,       SSC_ARRAY,       "ac_monthly",                     "AC system output",                            "kWhac",    "",                      "Monthly",       "*",                       "LENGTH=12",                          "" },
            { SSC_OUTPUT,       SSC_ARRAY,       "monthly_energy",                 "Monthly energy",                              "kWh",      "",                      "Monthly",      "*",                        "LENGTH=12",                          "" },
            { SSC_OUTPUT,       SSC_NUMBER,      "solrad_annual",                  "Daily average solar irradiance",              "kWh/m2/day",    "",                 "Annual",        "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_NUMBER,      "ac_annual",                      "Annual AC system output",                     "kWhac",    "",                      "Annual",        "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_NUMBER,      "annual_energy",                  "Annual energy",                               "kWh",    "",                        "Annual",        "*",                       "",                          "" },
            { SSC_OUTPUT,       SSC_STRING,      "location",                      "Location ID",                                  "",    "",                           "Location",      "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_STRING,      "city",                          "City",                                         "",    "",                           "Location",      "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_STRING,      "state",                         "State",                                        "",    "",                           "Location",      "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_NUMBER,      "lat",                           "Latitude",                                     "deg", "",                           "Location",      "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_NUMBER,      "lon",                           "Longitude",                                    "deg", "",                           "Location",      "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_NUMBER,      "tz",                            "Time zone",                                    "hr",  "",                           "Location",      "*",                       "",                                   "" },
            { SSC_OUTPUT,       SSC_NUMBER,      "elev",                          "Site elevation",                               "m",   "",                           "Location",      "*",                       "",                                   "" },
            var_info_invalid ]

class cm_pvwattsv1(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_pvwattsv1)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        file = self.as_string("solar_resource_file")
        wfile = weatherfile(file)
        if not wfile.ok():
            raise exec_error("pvwattsv1", wfile.message())
        if wfile.has_message():
            self.log(wfile.message(), SSC_WARNING)

        hdr = weather_header()
        wfile.header(hdr)

        dcrate = self.as_double("system_size")
        derate = self.as_double("derate")
        track_mode = self.as_integer("track_mode") # 0, 1, 2, 3
        azimuth = self.as_double("azimuth")
        tilt = fabs(hdr.lat)
        if not self.lookup("tilt_eq_lat") or not self.as_boolean("tilt_eq_lat"):
            tilt = fabs(self.as_double("tilt"))

        p_user_poa = DTypePointer[DType.float64]()
        var_count = UInt(0)
        if self.as_boolean("enable_user_poa"):
            p_user_poa = self.as_array_ptr("user_poa", var_count)
            if var_count != 8760:
                p_user_poa = DTypePointer[DType.float64]()

        p_gh = self.allocate("gh", 8760)
        p_dn = self.allocate("dn", 8760)
        p_df = self.allocate("df", 8760)
        p_tamb = self.allocate("tamb", 8760)
        p_tdew = self.allocate("tdew", 8760)
        p_wspd = self.allocate("wspd", 8760)
        p_dc = self.allocate("dc", 8760)
        p_ac = self.allocate("ac", 8760)
        p_hourly_energy = self.allocate("gen", 8760)
        p_tcell = self.allocate("tcell", 8760)
        p_poa = self.allocate("poa", 8760)
        p_tpoa = self.allocate("tpoa", 8760)
        p_shad_beam = self.allocate("shad_beam_factor", 8760)
        p_sunup = self.allocate("sunup", 8760)

        U0 = float("nan")
        U1 = float("nan")
        use_faiman_model = False
        if self.is_assigned("u0") and self.is_assigned("u1"):
            use_faiman_model = True
            U0 = self.as_double("u0")
            U1 = self.as_double("u1")

        /* PV RELATED SPECIFICATIONS */
        inoct = self.as_double("inoct") + 273.15 # PVWATTS_INOCT;        /* Installed normal operating cell temperature (deg K) */
        reftem = self.as_double("tref") # PVWATTS_REFTEM;                /* Reference module temperature (deg C) */
        pwrdgr = self.as_double("gamma") / 100.0 # PVWATTS_PWRDGR;              /* Power degradation due to temperature (decimal fraction), si approx -0.004 */
        efffp = self.as_double("inv_eff") # PVWATTS_EFFFP;                 /* Efficiency of inverter at rated output (decimal fraction) */
        height = PVWATTS_HEIGHT                 /* Average array height (meters) */
        tmloss = 1.0 - derate / efffp  /* All losses except inverter,decimal */
        rlim = self.as_double("rotlim")             /* +/- rotation in degrees permitted by physical constraint of tracker */
        fd = self.as_double("fd") # diffuse fraction
        i_ref = self.as_double("i_ref") # reference irradiance for rating condition
        poa_cutin = self.as_double("poa_cutin") # minimum POA irradiance level required for any operation
        wind_stow = self.as_double("w_stow") # maximum wind speed before stowing.  stowing causes all output to be lost
        concen = 1.0
        if self.is_assigned("concen"):
            concen = self.as_double("concen") # concentration ratio.  used to increase incident irradiance on cells for thermal calculaton
        fhconv = 1.0
        if self.is_assigned("fhconv"):
            fhconv = self.as_double("fhconv") # convective heat transfer coefficient factor.  used to approximate effect of a heatsink for lcpv
        shade_mode_1x = 2 # no self shading on 1 axis tracker
        if self.is_assigned("shade_mode_1x"):
            shade_mode_1x = self.as_integer("shade_mode_1x")
        gcr = 0.3
        if self.is_assigned("gcr"):
            gcr = self.as_double("gcr")
        use_ar_glass = False
        if self.is_assigned("ar_glass"):
            use_ar_glass = self.as_boolean("ar_glass")

        if dcrate < 0.1:
            dcrate = 0.1
        if derate < 0.0 or derate > 1.0: # Use if default ac to dc derate factor out of range
            derate = 0.77
        pcrate = dcrate * 1000.0      # rated output of inverter in a.c. watts; 6/29/2005
        refpwr = dcrate * 1000.0      # nameplate in watts; 6/29/2005
        if track_mode < 0 or track_mode > 3:
            track_mode = 0
        if tilt < 0 or tilt > 90:
            tilt = hdr.lat
        if azimuth < 0 or azimuth > 360:
            azimuth = 180.0

        shad = shading_factor_calculator()
        if not shad.setup(self, ""):
            raise exec_error("pvwattsv1", shad.get_error())

        skydiff_table = sssky_diffuse_table()
        skydiff_table.init(tilt, gcr)

        haf = adjustment_factors(self, "adjust")
        if not haf.setup():
            raise exec_error("pvwattsv1", "failed to setup adjustment factors: " + haf.error())

        tccalc = pvwatts_celltemp(inoct, height, 1.0)

        fixed_albedo = 0.2
        has_albedo = self.is_assigned("albedo")
        if has_albedo:
            fixed_albedo = self.as_double("albedo")

        wf = weather_record()

        i = 0
        while i < 8760:
            if not wfile.read(wf):
                raise exec_error("pvwattsv1", "could not read data line " + util_to_string(i + 1) + " of 8760 in weather file")

            irr = irrad()
            irr.set_time(wf.year, wf.month, wf.day, wf.hour, wf.minute, wfile.step_sec() / 3600.0)
            irr.set_location(hdr.lat, hdr.lon, hdr.tz)
            irr.set_optional(hdr.elev, wf.pres, wf.tdry)

            alb = 0.2
            if has_albedo and fixed_albedo >= 0 and fixed_albedo <= 1.0:
                alb = fixed_albedo
            elif wfile.type() == weatherfile.TMY2:
                if wf.snow > 0 and wf.snow < 150:
                    alb = 0.6
            elif wfile.type() == weatherfile.TMY3:
                if wf.alb >= 0 and wf.alb < 1:
                    alb = wf.alb
            irr.set_sky_model(2, alb)
            irr.set_beam_diffuse(wf.dn, wf.df)
            irr.set_surface(track_mode, tilt, azimuth, rlim,
                shade_mode_1x == 1, # backtracking mode
                gcr, False, 0.0)

            ibeam = 0.0
            iskydiff = 0.0
            ignddiff = 0.0
            solazi = 0.0
            solzen = 0.0
            solalt = 0.0
            aoi = 0.0
            stilt = 0.0
            sazi = 0.0
            rot = 0.0
            btd = 0.0
            sunup = 0

            p_gh[i] = wf.gh
            p_dn[i] = wf.dn
            p_df[i] = wf.df
            p_tamb[i] = wf.tdry
            p_tdew[i] = wf.tdew
            p_wspd[i] = wf.wspd
            p_tcell[i] = wf.tdry

            code = irr.calc()
            if code != 0:
                sunup = 0 # if for some reason the irradiance processor fails, ignore this hour
            else:
                irr.get_sun(solazi, solzen, solalt, None, None, None, sunup, None, None, None)

            p_sunup[i] = sunup
            p_shad_beam[i] = 1.0

            if shad.fbeam(i, wf.minute, solalt, solazi):
                p_shad_beam[i] = shad.beam_shade_factor()

            if sunup > 0:
                irr.get_angles(aoi, stilt, sazi, rot, btd)
                irr.get_poa(ibeam, iskydiff, ignddiff, None, None, None)

                if sunup > 0 and track_mode == 1 and shade_mode_1x == 0: # selfshaded mode
                    shad1xf = shadeFraction1x(solazi, solzen, tilt, azimuth, gcr, rot)
                    p_shad_beam[i] *= (1 - shad1xf)
                    if fd > 0 and shade_mode_1x == 0 and iskydiff > 0:
                        reduced_skydiff = iskydiff
                        Fskydiff = 1.0
                        reduced_gnddiff = ignddiff
                        Fgnddiff = 1.0
                        diffuse_reduce(solzen, stilt,
                            wf.dn, wf.df, iskydiff, ignddiff,
                            gcr, alb, 1000, skydiff_table,
                            reduced_skydiff, Fskydiff,
                            reduced_gnddiff, Fgnddiff)
                        if Fskydiff >= 0 and Fskydiff <= 1:
                            iskydiff *= Fskydiff
                        else:
                            self.log(util_format("sky diffuse reduction factor invalid at hour %d: fskydiff=%lg, stilt=%lg", i, Fskydiff, stilt), SSC_NOTICE, i)
                        if Fgnddiff >= 0 and Fgnddiff <= 1:
                            ignddiff *= Fgnddiff
                        else:
                            self.log(util_format("gnd diffuse reduction factor invalid at hour %d: fgnddiff=%lg, stilt=%lg", i, Fgnddiff, stilt), SSC_NOTICE, i)

                ibeam *= p_shad_beam[i]
                iskydiff *= shad.fdiff()
                poa = ibeam + fd * (iskydiff + ignddiff)

                if p_user_poa:
                    poa = p_user_poa[i]
                if poa_cutin > 0 and poa < poa_cutin:
                    poa = 0
                wspd_corr = 0.0 if wf.wspd < 0 else wf.wspd
                if wind_stow > 0 and wf.wspd >= wind_stow:
                    poa = 0
                tpoa = transpoa(poa, wf.dn, aoi * 3.14159265358979 / 180, use_ar_glass)
                pvt = wf.tdry
                if use_faiman_model:
                    pvt = wf.tdry + poa * concen / (U0 + U1 * wspd_corr)
                else:
                    pvt = tccalc(poa * concen, wspd_corr, wf.tdry, fhconv)
                dc = dcpowr(reftem, refpwr, pwrdgr, tmloss, tpoa, pvt, i_ref)
                ac = dctoac(pcrate, efffp, dc)

                p_poa[i] = poa
                p_tpoa[i] = tpoa
                p_tcell[i] = pvt
                p_dc[i] = dc
                p_ac[i] = ac
                p_hourly_energy[i] = ac * haf(i) * 0.001

            i += 1

        poam = self.accumulate_monthly("poa", "poa_monthly", 0.001)
        self.accumulate_monthly("dc", "dc_monthly", 0.001)
        self.accumulate_monthly("ac", "ac_monthly", 0.001)
        self.accumulate_monthly("gen", "monthly_energy")

        solrad = self.allocate("solrad_monthly", 12)
        solrad_ann = 0.0
        for m in range(12):
            solrad[m] = poam[m] / util_nday[m]
            solrad_ann += solrad[m]

        self.assign("solrad_annual", var_data(solrad_ann / 12))
        self.accumulate_annual("ac", "ac_annual", 0.001)
        self.accumulate_annual("gen", "annual_energy")

        self.assign("location", var_data(hdr.location))
        self.assign("city", var_data(hdr.city))
        self.assign("state", var_data(hdr.state))
        self.assign("lat", var_data(hdr.lat))
        self.assign("lon", var_data(hdr.lon))
        self.assign("tz", var_data(hdr.tz))
        self.assign("elev", var_data(hdr.elev))

DEFINE_MODULE_ENTRY(pvwattsv1, "PVWatts V.1 - integrated hourly weather reader and PV system simulator.", 2)
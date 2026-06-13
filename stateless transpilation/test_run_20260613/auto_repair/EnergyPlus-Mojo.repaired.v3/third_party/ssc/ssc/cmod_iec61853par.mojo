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
from lib_iec61853 import *
from ...solarpilot.Toolbox import *
from ...tcs.interpolation_routines import *
from math import sqrt, exp, pow, isfinite

var_info_invalid = var_info()

vtab_iec61853 = [
    # VARTYPE, DATATYPE, NAME, LABEL, UNITS, META, GROUP, REQUIRED_IF, CONSTRAINTS, UI_HINTS
    (SSC_INPUT, SSC_MATRIX, "input", "IEC-61853 matrix test data", "various", "[IRR,TC,PMP,VMP,VOC,ISC]", "IEC61853", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "nser", "Number of cells in series", "", "", "IEC61853", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "type", "Cell technology type", "0..5", "monoSi,multiSi/polySi,cdte,cis,cigs,amorphous", "IEC61853", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "verbose", "Output solver messages", "0/1", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "alphaIsc", "SC temp coefficient @ STC", "A/C", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "betaVoc", "OC temp coefficient @ STC", "V/C", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "gammaPmp", "MP temp coefficient @ STC", "%/C", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "n", "Diode factor", "", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "Il", "Light current", "A", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "Io", "Saturation current", "A", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "C1", "Rsh fitting C1", "", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "C2", "Rsh fitting C2", "", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "C3", "Rsh fitting C3", "", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "D1", "Rs fitting D1", "", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "D2", "Rs fitting D2", "", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "D3", "Rs fitting D3", "", "", "IEC61853", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "Egref", "Bandgap voltage", "eV", "", "IEC61853", "*", "", ""),
    var_info_invalid
]

class cm_iec61853par(compute_module):
    def __init__(self):
        self.add_var_info(vtab_iec61853)

    class msg_handler(Imessage_api):
        def __init__(self, _c: compute_module):
            self.cm = _c

        def Printf(self, fmt: String, *args):
            buf = String.format(fmt, *args)
            self.cm.log(buf, SSC_NOTICE)

        def Outln(self, msg: String):
            self.cm.log(msg, SSC_NOTICE)

    def exec(self):
        solver = iec61853_module_t()
        msgs = self.msg_handler(self)
        solver._imsg = msgs
        input = self.as_matrix("input")
        par = util.matrix_t[Float64]()
        if input.ncols() != iec61853_module_t.COL_MAX:
            raise exec_error("iec61853", "six data columns required for input matrix: IRR,TC,PMP,VMP,VOC,ISC")
        if not solver.calculate(input, self.as_integer("nser"), self.as_integer("type"), par, self.as_boolean("verbose")):
            raise exec_error("iec61853", "failed to solve for parameters")
        self.assign("n", var_data(ssc_number_t(solver.n)))
        self.assign("alphaIsc", var_data(ssc_number_t(solver.alphaIsc)))
        self.assign("betaVoc", var_data(ssc_number_t(solver.betaVoc)))
        self.assign("gammaPmp", var_data(ssc_number_t(solver.gammaPmp)))
        self.assign("Il", var_data(ssc_number_t(solver.Il)))
        self.assign("Io", var_data(ssc_number_t(solver.Io)))
        self.assign("C1", var_data(ssc_number_t(solver.C1)))
        self.assign("C2", var_data(ssc_number_t(solver.C2)))
        self.assign("C3", var_data(ssc_number_t(solver.C3)))
        self.assign("D1", var_data(ssc_number_t(solver.D1)))
        self.assign("D2", var_data(ssc_number_t(solver.D2)))
        self.assign("D3", var_data(ssc_number_t(solver.D3)))
        self.assign("Egref", var_data(ssc_number_t(solver.Egref)))
        output = self.allocate("output", par.nrows(), par.ncols())
        c = 0
        for i in range(par.nrows()):
            for j in range(par.ncols()):
                output[c] = ssc_number_t(par[i, j])
                c += 1

DEFINE_MODULE_ENTRY(iec61853par, "Calculate 11-parameter single diode model parameters from IEC-61853 PV module test data.", 1)

vtab_iec61853interp = [
    # VARTYPE, DATATYPE, NAME, LABEL, UNITS, META, GROUP, REQUIRED_IF, CONSTRAINTS, UI_HINTS
    (SSC_INPUT, SSC_MATRIX, "input", "IEC-61853 matrix test data", "various", "[IRR,TC,PMP,VMP,VOC,ISC]", "IEC61853", "*", "", ""),
    (SSC_INPUT, SSC_MATRIX, "param", "Parameter solution matrix", "", "[IL,IO,RS,RSH,A]", "IEC61853", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "I", "Irradiance", "W/m2", "", "Single Diode Model", "*", "", ""),
    (SSC_INPUT, SSC_NUMBER, "T", "Temperature", "C", "", "Single Diode Model", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "a", "Modified nonideality factor", "1/V", "", "Single Diode Model", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "Il", "Light current", "A", "", "Single Diode Model", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "Io", "Saturation current", "A", "", "Single Diode Model", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "Rs", "Series resistance", "ohm", "", "Single Diode Model", "*", "", ""),
    (SSC_OUTPUT, SSC_NUMBER, "Rsh", "Shunt resistance", "ohm", "", "Single Diode Model", "*", "", ""),
    var_info_invalid
]

enum IRR: 0
enum TC: 1
enum PMP: 2
enum VMP: 3
enum VOC: 4
enum ISC: 5
enum DATACOLS: 6

enum IL: 0
enum IO: 1
enum RS: 2
enum RSH: 3
enum A: 4
enum PARCOLS: 5

parnames = ["IL", "IO", "RS", "RSH", "A"]

class cm_iec61853interp(compute_module):
    def __init__(self):
        self.add_var_info(vtab_iec61853interp)

    def interpolate(self, data: util.matrix_t[Float64], par: util.matrix_t[Float64], I: Float64, T: Float64, idx: Int, quiet: Bool) -> Float64:
        tempirr = MatDoub()
        parvals = List[Float64]()
        pts = List[sp_point]()
        hull = List[sp_point]()
        maxz = -1e99
        tmin = 1e99
        tmax = -1e99
        imin = 1e99
        imax = -1e99
        dist = 1e99
        idist = -1
        for i in range(data.nrows()):
            z = par[i, idx]
            if not isfinite(z):
                continue
            temp = data[i, TC]  # x value
            irr = data[i, IRR]  # y value
            if temp < tmin: tmin = temp
            if temp > tmax: tmax = temp
            if irr < imin: imin = irr
            if irr > imax: imax = irr
            d = sqrt((irr - I) * (irr - I) + (temp - T) * (temp - T))
            if d < dist:
                dist = d
                idist = i
            it = List[Float64](2, 0.0)
            it[0] = temp
            it[1] = irr
            tempirr.push_back(it)
            parvals.push_back(z)
            if z > maxz: maxz = z
            pts.push_back(sp_point(temp, irr, z))
        Toolbox.convex_hull(pts, hull)
        if Toolbox.pointInPolygon(hull, sp_point(T, I, 0.0)):
            for i in range(len(parvals)):
                parvals[i] /= maxz
            vgram = Powvargram(tempirr, parvals, 1.75, 0.0)
            gm = GaussMarkov(tempirr, parvals, vgram)
            err_fit = 0.0
            for i in range(len(parvals)):
                zref = parvals[i]
                zfit = gm.interp(tempirr[i])
                dz = zref - zfit
                err_fit += dz * dz
            err_fit = sqrt(err_fit)
            if err_fit > 0.01:
                self.log(util.format("interpolation function for iec61853 parameter '%s' at I=%lg T=%lg is poor: %lg RMS",
                                     parnames[idx], I, T, err_fit),
                         SSC_WARNING)
            q = List[Float64](2, 0.0)
            q[0] = T
            q[1] = I
            return gm.interp(q) * maxz
        else:
            if dist < 30.0:
                if not quiet:
                    self.log(util.format("query point (%lg, %lg) is outside convex hull of data but close... returning nearest value from data table at (%lg, %lg)=%lg",
                                         T, I, data[idist, TC], data[idist, IRR], par[idist, idx]),
                             SSC_WARNING)
                return par[idist, idx]
            idx_stc = -1
            for i in range(data.nrows()):
                if data[i, IRR] == 1000.0 and data[i, TC] == 25.0:
                    idx_stc = i
            if idx_stc < 0:
                raise general_error("STC conditions required to be supplied in the temperature/irradiance data")
            value = par[idist, idx]
            if idx == A:
                a_nearest = par[idist, A]
                T_nearest = data[idist, TC]
                a_est = a_nearest * T / T_nearest
                value = a_est
            elif idx == IL:
                IL_nearest = par[idist, IL]
                I_nearest = data[idist, IRR]
                IL_est = IL_nearest * I / I_nearest
                value = IL_est
            # else if ( idx == IO )
            # {
            # #define Tc_ref 298.15
            # #define Eg_ref 1.12
            # #define KB 8.618e-5
            #     double IO_stc = par(idx_stc,IO);
            #     double TK = T+273.15;
            #     double EG = Eg_ref * (1-0.0002677*(TK-Tc_ref));
            #     double IO_oper =  IO_stc * pow(TK/Tc_ref, 3) * exp( 1/KB*(Eg_ref/Tc_ref - EG/TK) );
            #     value = IO_oper;	
            # }
            elif idx == RSH:
                RSH_nearest = par[idist, RSH]
                I_nearest = data[idist, IRR]
                RSH_est = RSH_nearest * I_nearest / I
                value = RSH_est
            if not quiet:
                self.log(util.format("query point (%lg, %lg) is too far out of convex hull of data (dist=%lg)... estimating value from 5 parameter modele at (%lg, %lg)=%lg",
                                     T, I, dist, data[idist, TC], data[idist, IRR], value),
                         SSC_WARNING)
            return value

    def exec(self):
        I = self.as_double("I")
        T = self.as_double("T")
        data = self.as_matrix("input")
        par = self.as_matrix("param")
        if data.ncols() != DATACOLS:
            raise general_error(util.format("input matrix must have 6 columns (Irr, Tc, Pmp, Vmp, Voc, Isc), but is %d x %d",
                                            data.nrows(), data.ncols()))
        if par.ncols() != PARCOLS:
            raise general_error(util.format("parameter matrix must have 5 columns (Il, Io, Rs, Rsh, a), but is %d x %d",
                                            par.nrows(), par.ncols()))
        if par.nrows() != data.nrows() or data.nrows() < 3:
            raise general_error("input and parameter matrices must have same number of rows, and at least 3")
        quiet = False
        if self.is_assigned("quiet"):
            quiet = True
        self.assign("a", var_data(ssc_number_t(self.interpolate(data, par, I, T, A, quiet))))
        self.assign("Il", var_data(ssc_number_t(self.interpolate(data, par, I, T, IL, quiet))))
        self.assign("Io", var_data(ssc_number_t(self.interpolate(data, par, I, T, IO, quiet))))
        self.assign("Rs", var_data(ssc_number_t(self.interpolate(data, par, I, T, RS, quiet))))
        self.assign("Rsh", var_data(ssc_number_t(self.interpolate(data, par, I, T, RSH, quiet))))

DEFINE_MODULE_ENTRY(iec61853interp, "Determine single diode model parameters from IEC 61853 solution matrix at a given temperature and irradiance.", 1)
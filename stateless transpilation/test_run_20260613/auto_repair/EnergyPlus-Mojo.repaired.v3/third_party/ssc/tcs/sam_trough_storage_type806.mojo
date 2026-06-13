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

from tcstype import tcstypeinterface, tcscontext, tcstypeinfo, tcsvarinfo, tcsvalue, TCS_INPUT, TCS_OUTPUT, TCS_PARAM, TCS_NUMBER, TCS_MATRIX, TCS_INVALID, TCS_WARNING
from lib_util import matrix_t
from math import pow

# Input/Output indices (enum-like constants)
alias I_TsHours = 0
alias I_NumTOU = 1
alias I_E2TPLF0 = 2
alias I_E2TPLF1 = 3
alias I_E2TPLF2 = 4
alias I_E2TPLF3 = 5
alias I_E2TPLF4 = 6
alias I_TSLOGIC = 7
alias I_E_TES_INI = 8
alias I_Qsf = 9
alias I_TOUPeriod = 10
alias I_TnkHL = 11
alias I_PTSmax = 12
alias I_PFSmax = 13
alias I_PTTMAX = 14
alias I_PTTMIN = 15
alias I_TurSUE = 16
alias I_Qdesign = 17
alias I_HhtfPar = 18
alias I_HhtfParPF = 19
alias I_HhtfParF0 = 20
alias I_HhtfParF1 = 21
alias I_HhtfParF2 = 22
alias I_QhtfFreezeProt = 23
alias O_Qtts = 24
alias O_Qfts = 25
alias O_Ets = 26
alias O_QTsHl = 27
alias O_Qtpb = 28
alias O_QTsFull = 29
alias O_Qmin = 30
alias O_Qdump = 31
alias O_QTurSu = 32
alias O_PbStartF = 33
alias O_HhtfLoad = 34
alias O_EparHhtf = 35
alias O_PBMode = 36
alias O_QhtfFpTES = 37
alias O_QhtfFpHtr = 38
alias O_tslogic00 = 39
alias O_tslogic01 = 40
alias O_tslogic02 = 41
alias O_tslogic10 = 42
alias O_tslogic11 = 43
alias O_tslogic12 = 44
alias O_tslogic20 = 45
alias O_tslogic21 = 46
alias O_tslogic22 = 47
alias O_tslogic30 = 48
alias O_tslogic31 = 49
alias O_tslogic32 = 50
alias O_tslogic40 = 51
alias O_tslogic41 = 52
alias O_tslogic42 = 53
alias O_tslogic50 = 54
alias O_tslogic51 = 55
alias O_tslogic52 = 56
alias O_tslogic60 = 57
alias O_tslogic61 = 58
alias O_tslogic62 = 59
alias O_tslogic70 = 60
alias O_tslogic71 = 61
alias O_tslogic72 = 62
alias O_tslogic80 = 63
alias O_tslogic81 = 64
alias O_tslogic82 = 65
alias N_MAX = 66

def max(a: Float64, b: Float64) -> Float64:
    return a if a > b else b

# Placeholder for TCS_MATRIX_INDEX macro: assume matrix is 2D list, 0-based indexing in both C++ and Mojo.
# In source C++ code, TCS_MATRIX_INDEX(m, r, c) corresponds to m[r][c] (r,c 0-based).
# We define an alias for clarity.
alias TCS_MATRIX_INDEX = __get_item__

var sam_trough_storage_type806_variables: List[tcsvarinfo] = [
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TsHours, "TSHOURS", "Number of equivalent full-load hours of thermal storage", "hours", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_NumTOU, "NUMTOU", "Number of time-of-use periods", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF0, "E2TPLF0", "Turbine part-load electric to thermal conversion (fossil) - const", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF1, "E2TPLF1", "Turbine part-load electric to thermal conversion (fossil) - linear", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF2, "E2TPLF2", "Turbine part-load electric to thermal conversion (fossil) - quad.", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF3, "E2TPLF3", "Turbine part-load electric to thermal conversion (fossil) - cubic", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF4, "E2TPLF4", "Turbine part-load electric to thermal conversion(fossil) - quartic", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_MATRIX, I_TSLOGIC, "TSLogic", "Dispatch logic without solar (,1), with solar (,2), turbine load (,3)", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, I_E_TES_INI, "E_tes_ini", "Initial amount of energy in thermal storage - fraction of max storage energy", "-", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Qsf, "Qsf", "Thermal energy available from the solar field", "MWt", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TOUPeriod, "TOUPeriod", "The time-of-use period", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TnkHL, "TnkHL", "Tank heat losses", "MWt", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_PTSmax, "PTSmax", "Maximum power rate into the thermal storage", "MWt", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_PFSmax, "PFSmax", "Maximum discharge rate of power from storage", "MWt", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_PTTMAX, "PTTMAX", "Maximum ratio of turbine operation", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_PTTMIN, "PTTMIN", "Minimum turbine turn-down fraction", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TurSUE, "TurSUE", "Equivalent full-load hours required for turbine startup", "hours", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Qdesign, "Qdesign", "Thermal input to the power block under design conditions", "MWt", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HhtfPar, "HhtfPar", "TES HTF pump parasitics", "MWe", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HhtfParPF, "HhtfParPF", "Part-load TES HTF pump parasitics - multiplier", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HhtfParF0, "HhtfParF0", "Part-load TES HTF pump parasitics - constant coef", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HhtfParF1, "HhtfParF1", "Part-load TES HTF pump parasitics - linear coef", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HhtfParF2, "HhtfParF2", "Part-load TES HTF pump parasitics - quadratic coef", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_QhtfFreezeProt, "QhtfFreezeProt", "HTF Freeze Protection Requirement (from 805)", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Qtts, "Qtts", "Energy to Thermal Storage", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Qfts, "Qfts", "Energy from Thermal Storage", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Ets, "Ets", "Energy in Thermal Storage", "MWt.hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_QTsHl, "QTsHl", "Energy losses from Thermal Storage", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Qtpb, "Qtpb", "Energy to the Power Block", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_QTsFull, "QTsFull", "Energy dumped because the thermal storage is full", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Qmin, "Qmin", "Energy dumped due to minimum load requirement", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Qdump, "Qdump", "The amount of energy dumped (more than turbine and storage)", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_QTurSu, "QTurSu", "The energy needed to startup the turbine", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_PbStartF, "PbStartF", "Power block startup flag (1 = starting up, 0 = not starting up)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_HhtfLoad, "HhtfLoad", "Hot HTF pump load (energy from storage)", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EparHhtf, "EparHhtf", "Hot HTF pump parasitics", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_PBMode, "PBMode", "Power block mode (0 = off, 1 = startup, 2 = running)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_QhtfFpTES, "QhtfFpTES", "Thermal energy storage freeze protection energy", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_QhtfFpHtr, "QhtfFpHtr", "Freeze protection provided by auxiliary heater", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic00, "O_tslogic00", "m_TSLogic(0,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic01, "O_tslogic01", "m_TSLogic(0,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic02, "O_tslogic02", "m_TSLogic(0,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic10, "O_tslogic10", "m_TSLogic(1,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic11, "O_tslogic11", "m_TSLogic(1,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic12, "O_tslogic12", "m_TSLogic(1,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic20, "O_tslogic20", "m_TSLogic(2,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic21, "O_tslogic21", "m_TSLogic(2,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic22, "O_tslogic22", "m_TSLogic(2,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic30, "O_tslogic30", "m_TSLogic(3,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic31, "O_tslogic31", "m_TSLogic(3,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic32, "O_tslogic32", "m_TSLogic(3,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic40, "O_tslogic40", "m_TSLogic(4,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic41, "O_tslogic41", "m_TSLogic(4,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic42, "O_tslogic42", "m_TSLogic(4,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic50, "O_tslogic50", "m_TSLogic(5,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic51, "O_tslogic51", "m_TSLogic(5,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic52, "O_tslogic52", "m_TSLogic(5,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic60, "O_tslogic60", "m_TSLogic(6,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic61, "O_tslogic61", "m_TSLogic(6,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic62, "O_tslogic62", "m_TSLogic(6,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic70, "O_tslogic70", "m_TSLogic(7,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic71, "O_tslogic71", "m_TSLogic(7,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic72, "O_tslogic72", "m_TSLogic(7,2)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic80, "O_tslogic80", "m_TSLogic(8,0)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic81, "O_tslogic81", "m_TSLogic(8,1)", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_tslogic82, "O_tslogic82", "m_TSLogic(8,2)", "", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, "0", 0, 0, 0, 0, 0)
]

struct sam_trough_storage_type806(tcstypeinterface):
    var m_PBMode0: Int32  # previous timestep
    var m_TurSuE0: Float64  # previous timestep
    var m_Ets0: Float64  # previous timestep
    var m_TSLogic: matrix_t[Float64]
    var m_TSLogicin: tcsvalue  # pointer to matrix (represented as tcsvalue, but we'll treat as 2D list)
    var m_TSHOURS: Float64
    var m_NUMTOU: Int32
    var m_E2TPLF0: Float64
    var m_E2TPLF1: Float64
    var m_E2TPLF2: Float64
    var m_E2TPLF3: Float64
    var m_E2TPLF4: Float64
    var m_ESMAX: Float64
    var m_PTTMAXin: Float64
    var m_PTTMINin: Float64

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        # member initializations - will be set in init()
        self.m_PBMode0 = 0
        self.m_TurSuE0 = 0.0
        self.m_Ets0 = 0.0
        self.m_TSLogic = matrix_t[Float64]()
        self.m_TSLogicin = tcsvalue()
        self.m_TSHOURS = 0.0
        self.m_NUMTOU = 0
        self.m_E2TPLF0 = 0.0
        self.m_E2TPLF1 = 0.0
        self.m_E2TPLF2 = 0.0
        self.m_E2TPLF3 = 0.0
        self.m_E2TPLF4 = 0.0
        self.m_ESMAX = 0.0
        self.m_PTTMAXin = 0.0
        self.m_PTTMINin = 0.0

    def __del__(owned self):

    def init(inout self) -> Int32:
        self.m_PBMode0 = 0
        self.m_TurSuE0 = 0.0
        self.m_TSHOURS = self.value(I_TsHours)  # Hours of Thermal Storage
        var Qdesign: Float64 = self.value(I_Qdesign)  # [MWth] Design thermal input to power cycle
        var E_tes_max: Float64 = Qdesign * self.m_TSHOURS  # [MWth-hr] Maximum stored thermal energy
        var f_tes_ini: Float64 = self.value(I_E_TES_INI)  # [-] Fraction of max stored thermal energy at initialization
        if f_tes_ini < 0.0:
            self.message(TCS_WARNING, "Fraction of TES at initialization was less than 0: {}. It was reset to the minimum of 0 for this simulation", f_tes_ini)
            f_tes_ini = 0.0
        else:
            if f_tes_ini > 1.0:
                self.message(TCS_WARNING, "Fraction of TES at initialization was greater than 1: {}. It was reset to the maximum of 1 for this simulation", f_tes_ini)
                f_tes_ini = 1.0
        self.m_Ets0 = f_tes_ini * E_tes_max  # [MWth-hr] Initial stored thermal energy
        self.m_TSLogicin = self.var(I_TSLOGIC)
        var tsl_rows: Int32 = 0
        var tsl_cols: Int32 = 0
        self.value(I_TSLOGIC, &tsl_rows, &tsl_cols)
        self.m_TSLogic.resize(tsl_rows, tsl_cols - 1)
        self.m_PTTMAXin = self.value(I_PTTMAX)
        self.m_PTTMINin = self.value(I_PTTMIN)
        self.m_NUMTOU = Int32(self.value(I_NumTOU))
        self.m_E2TPLF0 = self.value(I_E2TPLF0)
        self.m_E2TPLF1 = self.value(I_E2TPLF1)
        self.m_E2TPLF2 = self.value(I_E2TPLF2)
        self.m_E2TPLF3 = self.value(I_E2TPLF3)
        self.m_E2TPLF4 = self.value(I_E2TPLF4)
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int32) -> Int32:
        var Qsf: Float64 = self.value(I_Qsf)
        var TOUperiod: Int32 = Int32(self.value(I_TOUPeriod)) - 1  # control value between 1 & 9, have to change to 0-8 for array index
        var TnkHL: Float64 = self.value(I_TnkHL)
        var PTSMax: Float64 = self.value(I_PTSmax)
        var PFSMAX: Float64 = self.value(I_PFSmax)
        var TurSUE: Float64 = self.value(I_TurSUE)
        var HhtfPar: Float64 = self.value(I_HhtfPar)  # Hot HTF pump parasitics coefficient 1.1000
        var HhtfParF0: Float64 = self.value(I_HhtfParF0)  #  Hot HTF Pump parasitics coefficient	-0.036
        var HhtfParF1: Float64 = self.value(I_HhtfParF1)  #  Hot HTF Pump parasitics coefficient	0.242
        var HhtfParF2: Float64 = self.value(I_HhtfParF2)  #  Hot HTF Pump parasitics coefficient	0.794
        var QhtfFreezeProt: Float64 = self.value(I_QhtfFreezeProt)  #  HTF Freeze Protection 
        var PBMode: Int32 = self.m_PBMode0
        var Qdesign: Float64 = self.value(I_Qdesign)
        self.m_ESMAX = self.m_TSHOURS * Qdesign  # 10-4-06 m_ESMAX now calculated and not an input
        for p in range(self.m_NUMTOU):
            # commented original block omitted - current active block used
            self.m_TSLogic.at(p, 0) = TCS_MATRIX_INDEX(self.m_TSLogicin, p, 1) * self.m_ESMAX
            self.m_TSLogic.at(p, 1) = TCS_MATRIX_INDEX(self.m_TSLogicin, p, 2) * self.m_ESMAX
            self.m_TSLogic.at(p, 2) = Qdesign * (self.m_E2TPLF0 + self.m_E2TPLF1 * TCS_MATRIX_INDEX(self.m_TSLogicin, p, 3) + self.m_E2TPLF2 * pow(TCS_MATRIX_INDEX(self.m_TSLogicin, p, 3), 2) + self.m_E2TPLF3 * pow(TCS_MATRIX_INDEX(self.m_TSLogicin, p, 3), 3) + self.m_E2TPLF4 * pow(TCS_MATRIX_INDEX(self.m_TSLogicin, p, 3), 4))
            if TCS_MATRIX_INDEX(self.m_TSLogicin, p, 3) > self.m_PTTMAXin:
                self.m_TSLogic.at(p, 2) = Qdesign * (self.m_E2TPLF0 + self.m_E2TPLF1 * self.m_PTTMAXin + self.m_E2TPLF2 * pow(self.m_PTTMAXin, 2) + self.m_E2TPLF3 * pow(self.m_PTTMAXin, 3) + self.m_E2TPLF4 * pow(self.m_PTTMAXin, 4))
            if TCS_MATRIX_INDEX(self.m_TSLogicin, p, 3) < self.m_PTTMINin:
                self.m_TSLogic.at(p, 2) = Qdesign * (self.m_E2TPLF0 + self.m_E2TPLF1 * self.m_PTTMINin + self.m_E2TPLF2 * pow(self.m_PTTMINin, 2) + self.m_E2TPLF3 * pow(self.m_PTTMINin, 3) + self.m_E2TPLF4 * pow(self.m_PTTMINin, 4))
        var QTTMAX: Float64 = Qdesign * (self.m_E2TPLF0 + self.m_E2TPLF1 * self.m_PTTMAXin + self.m_E2TPLF2 * pow(self.m_PTTMAXin, 2) + self.m_E2TPLF3 * pow(self.m_PTTMAXin, 3) + self.m_E2TPLF4 * pow(self.m_PTTMAXin, 4))
        var QTTMIN: Float64 = Qdesign * (self.m_E2TPLF0 + self.m_E2TPLF1 * self.m_PTTMINin + self.m_E2TPLF2 * pow(self.m_PTTMINin, 2) + self.m_E2TPLF3 * pow(self.m_PTTMINin, 3) + self.m_E2TPLF4 * pow(self.m_PTTMINin, 4))
        var Delt: Float64 = 1.0  # Aron?? set to actual time step
        var TimeSteps: Int32 = Int32(1.0 / Delt)
        var Qtts: Float64 = 0.0  # | Energy to Thermal Storage                                      |      MW        |     MW
        var Qfts: Float64 = 0.0  # | Energy from Thermal Storage                                    |      MW        |     MW
        var Ets: Float64 = 0.0  # | Energy in Thermal Storage
        var QTsHl: Float64 = 0.0  # | Energy losses from Thermal Storage
        var Qtpb: Float64 = 0.0  # | Energy to the Power Block
        var QTsFull: Float64 = 0.0  # | Energy dumped because the thermal storage is full
        var Qmin: Float64 = 0.0  # | Indicator of being below minimum operation level
        var Qdump: Float64 = 0.0  # | The amount of energy dumped (more than turbine and storage)
        var QTurSu: Float64 = 0.0  # | The energy needed to startup the turbine
        var PbStartF: Float64 = 0.0  # | is 1 during the period when powerblock starts up otherwise 0
        var HhtfLoad: Float64 = 0.0  # | Hot HTF pump load (energy from storage)                        | Fraction between 0 and 1
        var EparHhtf: Float64 = 0.0  # | Hot HTF pump parasitics										|      MWhe 
        var QhtfFpTES: Float64 = 0.0  # | HTF Freeze Protection from Thermal Eneryg Storage				|      MWht HP 12-12-06
        var QhtfFpHtr: Float64 = 0.0  # | HTF Freeze Protection from Auxiliary Heater					|      MWht 
        var TStemp: Float64
        if self.m_TSHOURS <= 0.0:  #  No Storage
            if (self.m_PBMode0 == 0) or (self.m_PBMode0 == 1):  #  if plant is not already operating in last timestep
                if Qsf > 0.0:
                    if Qsf > (self.m_TurSuE0 * Float64(TimeSteps)):  #   Starts plant as exceeds startup energy needed
                        Qtpb = Qsf - self.m_TurSuE0 * Float64(TimeSteps)
                        QTurSu = self.m_TurSuE0 * Float64(TimeSteps)
                        PBMode = 2
                        PbStartF = 1.0
                        self.m_TurSuE0 = 0.0  # mjw 5/31/13 Reset the startup energy to zero here.
                    else:  #   Plant starting up but not enough energy to make it run - will probably finish in the next timestep
                        Qtpb = 0.0
                        self.m_TurSuE0 = self.m_TurSuE0 - Qsf / Float64(TimeSteps)
                        QTurSu = Qsf
                        PBMode = 1
                        PbStartF = 0.0
                else:  #  No solar field output so still need same amount of energy as before and nothing changes
                    self.m_TurSuE0 = TurSUE * Qdesign
                    PBMode = 0
                    PbStartF = 0.0
            else:  #  if the powerblock mode is already 2 (running previous timestep)
                if Qsf > 0.0:  #      Plant operated last hour and this one
                    Qtpb = Qsf  #          all power goes from solar field to the powerblock
                    PBMode = 2  #          powerblock continuing to operate
                    PbStartF = 0.0  #        powerblock did not start during this timestep
                else:  #                   Plant operated last hour but not this one
                    Qtpb = 0.0  #            No energy to the powerblock
                    PBMode = 0  #          turned off powrblock
                    PbStartF = 0.0  #        it didn't start this timeperiod 
                    self.m_TurSuE0 = self.m_TurSuE0 - Qsf / Float64(TimeSteps)  #  Qsf is 0 so this statement is confusing
            HhtfLoad = 0.0
            if Qtpb < QTTMIN:  #  Energy to powerblock less than the minimum that the turbine can run at
                Qmin = Qtpb  #         The minimum energy (less than the minimum)
                Qtpb = 0.0  #             Energy to PB is now 0
                PBMode = 0  #           PB turned off
            if Qtpb > QTTMAX:  #    Energy to powerblock greater than what the PB can handle (max)
                Qdump = Qtpb - QTTMAX  #  The energy dumped 
                Qtpb = QTTMAX  #          the energy to the PB is exactly the maximum
            QhtfFpHtr = QhtfFreezeProt
        else:
            if self.m_TSHOURS > 0.0:
                var p: Int32 = TOUperiod
                QTurSu = 0.0
                PbStartF = 0.0
                QTsHl = TnkHL  #  thermal storage heat losses are equal to the tank losses
                Qdump = 0.0
                Qfts = 0.0  #  HP Added 11-26-06
                QhtfFpTES = QhtfFreezeProt  #  HP Added 12-12-06
                if PBMode == 0:  #  if plant is not already operating nor starting up
                    QTurSu = TurSUE * Qdesign * Float64(TimeSteps)
                    if (((Qsf > 0.0) and ((Qsf + self.m_Ets0 - self.m_TSLogic.at(p, 0)) >= (QTTMIN + QTurSu))) or ((Qsf == 0.0) and ((self.m_Ets0 - self.m_TSLogic.at(p, 1)) >= (QTTMIN + QTurSu))) or (Qsf > PTSMax)):
                        PBMode = 1  #  HP Added 11-26-06
                        QTurSu = TurSUE * Qdesign * Float64(TimeSteps)  #  HP Added 11-26-06
                        if Qsf > 0.0:
                            Qtpb = min(self.m_TSLogic.at(p, 2), Qsf + self.m_Ets0 - self.m_TSLogic.at(p, 0) - QTurSu)
                        else:
                            Qtpb = min(self.m_TSLogic.at(p, 2), Qsf + self.m_Ets0 - self.m_TSLogic.at(p, 1) - QTurSu)
                        if Qsf > Qtpb:  #  if solar field output is greater than what the necessary load ?
                            Qtts = Qsf - Qtpb  #  the extra goes to thermal storage
                            if Qtts > PTSMax:  #  if q to thermal storage exceeds thermal storage max rate Added 9-10-02
                                Qdump = Qtts - PTSMax  #  then dump the excess for this period Added 9-10-02
                                Qtts = PTSMax
                            Qfts = QTurSu  #  HP 12-07-06
                        else:  #  q from solar field not greater than needed by the powerblock
                            Qtts = 0.0
                            Qfts = QTurSu + (1.0 - Qsf / Qtpb) * PFSMAX  #  HP Added 11-26-06
                            if Qfts > PFSMAX:
                                Qfts = PFSMAX  # ' Added 1-26-08 ***********
                            Qtpb = Qsf + (1.0 - Qsf / Qtpb) * PFSMAX  #  HP Added 11-26-06
                        Ets = self.m_Ets0 - QTurSu + (Qsf - Qtpb) / Float64(TimeSteps)  #  HP Added 12-07-06
                        PBMode = 2  #   powerblock is now running
                        PbStartF = 1.0  #   the powerblock turns on during this timeperiod.
                    else:  # Store energy not enough stored to start plant
                        Qtts = Qsf  #  everything goes to thermal storage
                        Qfts = 0.0  #   nothing from thermal storage
                        Ets = self.m_Ets0 + Qtts / Float64(TimeSteps)
                        Qtpb = 0.0
                        QTurSu = 0.0
                else:  #        Power block operated last period or was starting up
                    if Qsf > 0.0:
                        TStemp = TCS_MATRIX_INDEX(self.m_TSLogicin, p, 1)
                    else:
                        TStemp = TCS_MATRIX_INDEX(self.m_TSLogicin, p, 2)
                    if (Qsf + max(0.0, self.m_Ets0 - self.m_ESMAX * TStemp) * Float64(TimeSteps)) > self.m_TSLogic.at(p, 2):
                        Qtpb = self.m_TSLogic.at(p, 2)
                        if Qsf > Qtpb:
                            Qtts = Qsf - Qtpb  # extra from what is needed put in thermal storage
                            if Qtts > PTSMax:  # check if max power rate to storage exceeded            ' Added 9-10-02
                                Qdump = Qtts - PTSMax  #  if so, dump extra         ' Added 9-10-02
                                Qtts = PTSMax  # Added 9-10-02
                            Qfts = 0.0
                        else:  #  solar field outptu less than what powerblock needs
                            Qtts = 0.0
                            Qfts = (1.0 - Qsf / Qtpb) * PFSMAX  # Added 9-10-02
                            if Qfts > PFSMAX:
                                Qfts = PFSMAX  #  Added 1-26-08
                            Qtpb = Qfts + Qsf  #  Added 9-10-02
                        Ets = self.m_Ets0 + (Qsf - Qtpb - Qdump) / Float64(TimeSteps)  #  energy of thermal storage is the extra
                        if (Ets > self.m_ESMAX) and (Qtpb < QTTMAX):  #  QTTMAX (MWt) - power to turbine max
                            if ((Ets - self.m_ESMAX) * Float64(TimeSteps)) < (QTTMAX - Qtpb):
                                Qtpb = Qtpb + (Ets - self.m_ESMAX) * Float64(TimeSteps)
                                Ets = self.m_ESMAX
                            else:
                                Ets = Ets - (QTTMAX - Qtpb) / Float64(TimeSteps)  #  should this be Ets0 instead of Ets on RHS ??
                                Qtpb = QTTMAX
                            Qtts = Qsf - Qtpb
                    else:  #  Empties TS to dispatch level if above min load level
                        if (Qsf + max(0.0, self.m_Ets0 - self.m_ESMAX * TStemp) / Float64(TimeSteps)) > QTTMIN:  # Modified 7/2009 by MJW
                            Qfts = max(0.0, self.m_Ets0 - self.m_ESMAX * TStemp) / Float64(TimeSteps)
                            Qtpb = Qsf + Qfts
                            Qtts = 0.0
                            Ets = self.m_Ets0 - Qfts
                        else:
                            Qtpb = 0.0
                            Qfts = 0.0
                            Qtts = Qsf
                            Ets = self.m_Ets0 + Qtts / Float64(TimeSteps)
                if Qtpb > 0.0:
                    PBMode = 2
                else:
                    PBMode = 0
                Ets = Ets - (QTsHl + QhtfFpTES) / Float64(TimeSteps)  #  should this be Ets or ETS0 on the RHS ?
                if Ets > self.m_ESMAX:  #  trying to put in more than storage can handle
                    QTsFull = (Ets - self.m_ESMAX) * Float64(TimeSteps)  # this is the amount dumped when storage is completely full
                    Ets = self.m_ESMAX
                    Qtts = Qtts - QTsFull
                else:
                    QTsFull = 0.0  #  nothing is dumped if not overfilled
                if Qtpb < QTTMIN:
                    Qmin = Qtpb
                    Qtpb = 0.0
                    PBMode = 0
                else:
                    Qmin = 0.0
                HhtfLoad = Qfts / Qdesign
                self.m_PBMode0 = PBMode
        else:  #   No Storage  NOT SURE WHY THIS IS HERE. IT SHOULD CRASH if the user enters a number other than 0 and 1
            Qtts = 0.0
            Qfts = 0.0
            Ets = 0.0
            Qtpb = Qsf
        #  end case on dispatch method
        EparHhtf = HhtfPar * (HhtfParF0 + HhtfParF1 * HhtfLoad + HhtfParF2 * pow(HhtfLoad, 2))  # HP Changed 12-12-06 (SAM input accounts for PF)
        if EparHhtf < 0.0:  # HP Added 12-11-06
            EparHhtf = 0.0
        if Ets < 0.0:
            self.m_Ets0 = 0.0
        else:
            self.m_Ets0 = Ets
        self.value(O_Qtts, Qtts)          # | Energy to Thermal Storage                                      |      MW        |     MW
        self.value(O_Qfts, Qfts)          # | Energy from Thermal Storage                                    |      MW        |     MW
        self.value(O_Ets, Ets)           # | Energy in Thermal Storage
        self.value(O_QTsHl, QTsHl)         # | Energy losses from Thermal Storage
        self.value(O_Qtpb, Qtpb)          # | Energy to the Power Block
        self.value(O_QTsFull, QTsFull)       # | Energy dumped because the thermal storage is full
        self.value(O_Qmin, Qmin)          # | Indicator of being below minimum operation level
        self.value(O_Qdump, Qdump)         # | The amount of energy dumped (more than turbine and storage)
        self.value(O_QTurSu, QTurSu)        # | The energy needed to startup the turbine
        self.value(O_PbStartF, PbStartF)      # | is 1 during the period when powerblock starts up otherwise 0
        self.value(O_HhtfLoad, HhtfLoad)      # | Hot HTF pump load (energy from storage)                         | MW?
        self.value(O_EparHhtf, EparHhtf)      # | Hot HTF pump parasitics
        self.value(O_PBMode, Float64(PBMode))
        self.value(O_QhtfFpTES, QhtfFpTES)      #  MWht   
        self.value(O_QhtfFpHtr, QhtfFpHtr)       #  MWht  // 
        self.value(O_tslogic00, self.m_TSLogic.at(0, 0))
        self.value(O_tslogic01, self.m_TSLogic.at(0, 1))
        self.value(O_tslogic02, self.m_TSLogic.at(0, 2))
        self.value(O_tslogic10, self.m_TSLogic.at(1, 0))
        self.value(O_tslogic11, self.m_TSLogic.at(1, 1))
        self.value(O_tslogic12, self.m_TSLogic.at(1, 2))
        self.value(O_tslogic20, self.m_TSLogic.at(2, 0))
        self.value(O_tslogic21, self.m_TSLogic.at(2, 1))
        self.value(O_tslogic22, self.m_TSLogic.at(2, 2))
        self.value(O_tslogic30, self.m_TSLogic.at(3, 0))
        self.value(O_tslogic31, self.m_TSLogic.at(3, 1))
        self.value(O_tslogic32, self.m_TSLogic.at(3, 2))
        self.value(O_tslogic40, self.m_TSLogic.at(4, 0))
        self.value(O_tslogic41, self.m_TSLogic.at(4, 1))
        self.value(O_tslogic42, self.m_TSLogic.at(4, 2))
        self.value(O_tslogic50, self.m_TSLogic.at(5, 0))
        self.value(O_tslogic51, self.m_TSLogic.at(5, 1))
        self.value(O_tslogic52, self.m_TSLogic.at(5, 2))
        self.value(O_tslogic60, self.m_TSLogic.at(6, 0))
        self.value(O_tslogic61, self.m_TSLogic.at(6, 1))
        self.value(O_tslogic62, self.m_TSLogic.at(6, 2))
        self.value(O_tslogic70, self.m_TSLogic.at(7, 0))
        self.value(O_tslogic71, self.m_TSLogic.at(7, 1))
        self.value(O_tslogic72, self.m_TSLogic.at(7, 2))
        self.value(O_tslogic80, self.m_TSLogic.at(8, 0))
        self.value(O_tslogic81, self.m_TSLogic.at(8, 1))
        self.value(O_tslogic82, self.m_TSLogic.at(8, 2))
        self.m_PBMode0 = PBMode
        return 0

# TCS_IMPLEMENT_TYPE( sam_trough_storage_type806, "SAM Trough Storage", "Steven Janzou", 1, sam_trough_storage_type806_variables, NULL, 0 )
# The above macro is replaced by the class definition and variable array.
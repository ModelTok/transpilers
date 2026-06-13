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
from tcstype import tcstypeinterface, tcscontext, tcstypeinfo, tcsvarinfo, TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_ARRAY, TCS_INVALID
from math import pow

# Enums
alias I_Qdesign = 0
alias I_Edesign = 1
alias I_T2EPLF0 = 2
alias I_T2EPLF1 = 3
alias I_T2EPLF2 = 4
alias I_T2EPLF3 = 5
alias I_T2EPLF4 = 6
alias I_E2TPLF0 = 7
alias I_E2TPLF1 = 8
alias I_E2TPLF2 = 9
alias I_E2TPLF3 = 10
alias I_E2TPLF4 = 11
alias I_TempCorrF = 12
alias I_TempCorr0 = 13
alias I_TempCorr1 = 14
alias I_TempCorr2 = 15
alias I_TempCorr3 = 16
alias I_TempCorr4 = 17
alias I_TurTesEffAdj = 18
alias I_TurTesOutAdj = 19
alias I_MinGrOut = 20
alias I_MaxGrOut = 21
alias I_NUMTOU = 22
alias I_FossilFill = 23
alias I_PbFixPar = 24
alias I_BOPPar = 25
alias I_BOPParPF = 26
alias I_BOPParF0 = 27
alias I_BOPParF1 = 28
alias I_BOPParF2 = 29
alias I_CtPar = 30
alias I_CtParPF = 31
alias I_CtParF0 = 32
alias I_CtParF1 = 33
alias I_CtParF2 = 34
alias I_HtrPar = 35
alias I_HtrParPF = 36
alias I_HtrParF0 = 37
alias I_HtrParF1 = 38
alias I_HtrParF2 = 39
alias I_LHVBoilEff = 40
alias I_Qtpb = 41
alias I_Qfts = 42
alias I_Twetbulb = 43
alias I_Tdrybulb = 44
alias I_CtOpF = 45
alias I_SFTotPar = 46
alias I_EparHhtf = 47
alias I_TOUPeriod = 48
alias O_Enet = 49
alias O_EgrSol = 50
alias O_EMin = 51
alias O_Edump = 52
alias O_Pbload = 53
alias O_EgrFos = 54
alias O_Egr = 55
alias O_Qgas = 56
alias O_HtrLoad = 57
alias O_Epar = 58
alias O_EparPB = 59
alias O_EparBOP = 60
alias O_EparCT = 61
alias O_EparHtr = 62
alias O_EparOffLine = 63
alias O_EparOnLine = 64
alias N_MAX = 65

# Variables array (faithful translation)
var sam_trough_plant_type807_variables: List[tcsvarinfo] = List[tcsvarinfo](
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Qdesign, "Qdesign", "Design Turbine Thermal Input (MWt)", "MWt", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Edesign, "Edesign", "Design Turbine Gross Output (MWe)", "MWe", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T2EPLF0, "T2EPLF0", "Turbine Part Load Therm to Elec", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T2EPLF1, "T2EPLF1", "Turbine Part Load Therm to Elec", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T2EPLF2, "T2EPLF2", "Turbine Part Load Therm to Elec", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T2EPLF3, "T2EPLF3", "Turbine Part Load Therm to Elec", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T2EPLF4, "T2EPLF4", "Turbine Part Load Therm to Elec", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF0, "E2TPLF0", "Turbine Part Load Elec  to Thermal (for fossil backup)", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF1, "E2TPLF1", "Turbine Part Load Elec  to Thermal (for fossil backup)", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF2, "E2TPLF2", "Turbine Part Load Elec  to Thermal (for fossil backup)", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF3, "E2TPLF3", "Turbine Part Load Elec  to Thermal (for fossil backup)", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_E2TPLF4, "E2TPLF4", "Turbine Part Load Elec  to Thermal (for fossil backup)", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TempCorrF, "TempCorrF", "Temperature Correction Mode (0=wetbulb 1=drybulb basis)", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TempCorr0, "TempCorr0", "Temperature Correction Coefficient 0", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TempCorr1, "TempCorr1", "Temperature Correction Coefficient 1", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TempCorr2, "TempCorr2", "Temperature Correction Coefficient 2", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TempCorr3, "TempCorr3", "Temperature Correction Coefficient 3", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TempCorr4, "TempCorr4", "Temperature Correction Coefficient 4", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TurTesEffAdj, "TurTesEffAdj", "Turbine TES Adjustment - Efficiency", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TurTesOutAdj, "TurTesOutAdj", "Turbine TES Adjustment - Gross Output", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_MinGrOut, "MinGrOut", "Minimum gross electrical output from powerplant", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_MaxGrOut, "MaxGrOut", "Maximum gross electrical output from powerplant", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_NUMTOU, "NUMTOU", "Number of time of use periods", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_ARRAY, I_FossilFill, "FossilFill", "Fossil dispatch fraction control", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_PbFixPar, "PbFixPar", "Fixed Power Block Parasitics", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_BOPPar, "BOPPar", "Balance of Plant Parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_BOPParPF, "BOPParPF", "Balance of Plant Parasitics - multiplier", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_BOPParF0, "BOPParF0", "Balance of Plant Parasitics - constant", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_BOPParF1, "BOPParF1", "Balance of Plant Parasitics - linear term", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_BOPParF2, "BOPParF2", "Balance of Plant Parasitics - quadratic term", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_CtPar, "CtPar", "Cooling Tower Parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_CtParPF, "CtParPF", "Cooling Tower Parasitics - multiplier", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_CtParF0, "CtParF0", "Cooling Tower Parasitics - constant", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_CtParF1, "CtParF1", "Cooling Tower Parasitics - linear term", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_CtParF2, "CtParF2", "Cooling Tower Parasitics - quadratic term", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HtrPar, "HtrPar", "Auxiliary heater/boiler operation parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HtrParPF, "HtrParPF", "Auxiliary heater/boiler operation parasitics - multiplier", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HtrParF0, "HtrParF0", "Auxiliary heater/boiler operation parasitics - constant", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HtrParF1, "HtrParF1", "Auxiliary heater/boiler operation parasitics - linear term", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_HtrParF2, "HtrParF2", "Auxiliary heater/boiler operation parasitics - quadratic term", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_LHVBoilEff, "LHVBoilEff", "Lower Heating Value Boiler Efficiency", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Qtpb, "Qtpb", "Heat to Power Block (output from TS/Dispatch type)", "MWt", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Qfts, "Qfts", "Heat from Thermal Storage", "MWt", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Twetbulb, "Twetbulb", "Wet Bulb Temperature", "C", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Tdrybulb, "Tdrybulb", "Ambient Temperature (dry bulb)", "C", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_CtOpF, "CtOpF", "CT Operation Flag (0 = CT par. a function of load, 1 = CT at full/half)", "", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_SFTotPar, "SFTotPar", "Solar Field Parasitics (EparSF + EparCHTF + EparAnti)", "MWe", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_EparHhtf, "EparHhtf", "Thermal Storage Parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TOUPeriod, "TOUPeriod", "Current Time of Use Period", "", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Enet, "Enet", "Net electricity produced, after parasitic loss", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EgrSol, "EgrSol", "Gross electric production from the solar resource", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EMin, "EMin", "Solar Electric Generation below minimum required output", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Edump, "Edump", "Solar Electric Generation that is in excess of powerplant max", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Pbload, "Pbload", "Fraction of current Powerblock output to design output", "", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EgrFos, "EgrFos", "Gross electric production from the fossil resource", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Egr, "Egr", "Gross electricity produced, before parasitic loss", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Qgas, "Qgas", "Gas Thermal Energy Input", "MW", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_HtrLoad, "HtrLoad", "Auxiliary heater load as ratio vs. rated output", "", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Epar, "Epar", "Total Parasitics for entire system", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EparPB, "EparPB", "Fixed Power Block Parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EparBOP, "EparBOP", "Balance of Plant Parasitics", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EparCT, "EparCT", "Cooling Tower Parasitic Load", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EparHtr, "EparHtr", "Auxiliary heater parasitic load", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EparOffLine, "EparOffLine", "Parasitics incurred while plant is not producing electricity", "MWe", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_EparOnLine, "EparOnLine", "Parasitics incurred while plant is producing electricity", "MWe", "", "", ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
)

class sam_trough_plant_type807(tcstypeinterface):
    # private: (implied)
    # public:
    def __init__(self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)

    def __del__(self):

    def init(self) -> Int:
        return 0

    def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
        var Qtpb: Float64 = self.value(I_Qtpb)
        var Qfts: Float64 = self.value(I_Qfts)
        var Tdrybulb: Float64 = self.value(I_Tdrybulb)
        var Twetbulb: Float64 = self.value(I_Twetbulb)
        var CtOpF: Float64 = self.value(I_CtOpF)
        var SFTotPar: Float64 = self.value(I_SFTotPar)
        var EparHhtf: Float64 = self.value(I_EparHhtf)
        var TOUPeriod: Int = Int(self.value(I_TOUPeriod)) - 1
        var Qdesign: Float64 = self.value(I_Qdesign)
        var Edesign: Float64 = self.value(I_Edesign)
        var T2EPLF0: Float64 = self.value(I_T2EPLF0)
        var T2EPLF1: Float64 = self.value(I_T2EPLF1)
        var T2EPLF2: Float64 = self.value(I_T2EPLF2)
        var T2EPLF3: Float64 = self.value(I_T2EPLF3)
        var T2EPLF4: Float64 = self.value(I_T2EPLF4)
        var E2TPLF0: Float64 = self.value(I_E2TPLF0)
        var E2TPLF1: Float64 = self.value(I_E2TPLF1)
        var E2TPLF2: Float64 = self.value(I_E2TPLF2)
        var E2TPLF3: Float64 = self.value(I_E2TPLF3)
        var E2TPLF4: Float64 = self.value(I_E2TPLF4)
        var TempCorrF: Float64 = self.value(I_TempCorrF) + 1.0	# Input table convention is 0=wet, 1=dry, so add 1 for calculations
        var TempCorr0: Float64 = self.value(I_TempCorr0)
        var TempCorr1: Float64 = self.value(I_TempCorr1)
        var TempCorr2: Float64 = self.value(I_TempCorr2)
        var TempCorr3: Float64 = self.value(I_TempCorr3)
        var TempCorr4: Float64 = self.value(I_TempCorr4)
        var TurTesEffAdj: Float64 = self.value(I_TurTesEffAdj)
        var MinGrOut: Float64 = self.value(I_MinGrOut)
        var MaxGrOut: Float64 = self.value(I_MaxGrOut)
        var len: Int
        var FossilFill: Pointer[Float64] = self.value(I_FossilFill, len)  # note: len is passed by reference, but not used afterwards
        var PbFixPar: Float64 = self.value(I_PbFixPar)
        var BOPPar: Float64 = self.value(I_BOPPar)
        var BOPParF0: Float64 = self.value(I_BOPParF0)
        var BOPParF1: Float64 = self.value(I_BOPParF1)
        var BOPParF2: Float64 = self.value(I_BOPParF2)
        var CtPar: Float64 = self.value(I_CtPar)
        var CtParF0: Float64 = self.value(I_CtParF0)
        var CtParF1: Float64 = self.value(I_CtParF1)
        var CtParF2: Float64 = self.value(I_CtParF2)
        var HtrPar: Float64 = self.value(I_HtrPar)
        var HtrParF0: Float64 = self.value(I_HtrParF0)
        var HtrParF1: Float64 = self.value(I_HtrParF1)
        var HtrParF2: Float64 = self.value(I_HtrParF2)
        var LHVBoilEff: Float64 = self.value(I_LHVBoilEff)
        var Nth: Float64 = Qtpb / Qdesign
        var Nel: Float64 = T2EPLF0 + T2EPLF1 * Nth + T2EPLF2 * pow(Nth, 2) + T2EPLF3 * pow(Nth, 3) + T2EPLF4 * pow(Nth, 4)
        var EgrSol: Float64 = Edesign * Nel
        var Ttc: Float64 = 0.0
        var Ntc: Float64 = 0.0
        var Emin: Float64 = 0.0
        var Edump: Float64 = 0.0
        var PbLoad: Float64 = 0.0
        var EgrFos: Float64 = 0.0
        var GN: Float64 = 0.0
        var Qgas: Float64 = 0.0
        var Egr: Float64 = 0.0
        var HtrLoad: Float64 = 0.0
        var EparHtr: Float64 = 0.0
        var EparPb: Float64 = 0.0
        var EparBop: Float64 = 0.0
        var Epar: Float64 = 0.0
        var EparCt: Float64 = 0.0
        var EparOffLine: Float64 = 0.0
        var EparOnLine: Float64 = 0.0
        var Enet: Float64
        if (TempCorrF == 1.0) or (TempCorrF == 2.0):
            if TempCorrF == 1.0:
                Ttc = Twetbulb
            else:
                Ttc = Tdrybulb
            Ntc = TempCorr0 + TempCorr1 * Ttc + TempCorr2 * pow(Ttc, 2) + TempCorr3 * pow(Ttc, 3) + TempCorr4 * pow(Ttc, 4)
        else:
            Ttc = 0.0
            Ntc = 1.0
        EgrSol = EgrSol * Ntc
        if Qtpb > 0.0:
            EgrSol = EgrSol * ((1.0 - Qfts / Qtpb) + Qfts / Qtpb * TurTesEffAdj)
        Emin = 0.0
        Edump = 0.0
        if EgrSol < (Edesign * MinGrOut):   # if the solar provided is less than the minimum needed to run the turbine
            if EgrSol > 0.0:
                Emin = EgrSol            # then set the emin equal to the solar provided
            EgrSol = 0.0
        else:
            if EgrSol > (Edesign * MaxGrOut): # if the solar provided is greater= than the maximum used by the turbine
                Edump = EgrSol - (Edesign * MaxGrOut) # then dump the extra 
                EgrSol = Edesign * MaxGrOut
        PbLoad = EgrSol / Edesign # what is the fraction of the solar output compared to the design point 
        if EgrSol < (FossilFill[TOUPeriod] * Edesign): # if the solar provided is less than the fraction of fossil required.
            EgrFos = Edesign * FossilFill[TOUPeriod] - EgrSol # then the fossil used is the maximum amount minus the solar provided ???
            if FossilFill[TOUPeriod] < 0.99:   # MJW 11/20/09  decide whether to use full-load turbine model or part load turbine model for Qgas calculation
                GN = (EgrSol + EgrFos) / Edesign
                Qgas = (Qdesign * (E2TPLF0 + E2TPLF1*GN + E2TPLF2*pow(GN,2) + E2TPLF3*pow(GN,3) + E2TPLF4*pow(GN,4)) - Qtpb) / LHVBoilEff # .9 is boiler LHV Efficiency
            else:
                Qgas = EgrFos * Qdesign / Edesign / LHVBoilEff # .9 is boiler LHV Efficiency
        else:
            EgrFos = 0.0
            Qgas = 0.0
        HtrLoad = EgrFos / Edesign    # First Order Estimate of the fraction of design output due to fossil
        PbLoad = (EgrSol + EgrFos) / Edesign # this is the amount of design load met by both fossil and solar
        Egr = EgrFos + EgrSol # the gross electric output is the sum of solar and fossil
        if HtrLoad > 0.0:               # Solar Field in Operation
            EparHtr = HtrPar * (HtrParF0 + HtrParF1 * HtrLoad + HtrParF2 * pow(HtrLoad, 2))	# HP Sam input accounts for PF 12-12-06
        else:                               # Heater is not in operation
            EparHtr = 0.0
        EparPb = PbFixPar               # Fixed Power Block Parasitics (24 hr)
        if PbLoad > 0.0:             # Power Block is in Operation
            EparBop = BOPPar * (BOPParF0 + BOPParF1 * PbLoad + BOPParF2 * pow(PbLoad, 2))	# HP Sam input accounts for PF 12-12-06
            if CtOpF == 0.0:               # CtOptF - when 1 runs at 50% or 100% only
                EparCt = CtPar * (CtParF0 + CtParF1 * PbLoad + CtParF2 * pow(PbLoad, 2))	# HP Sam input accounts for PF 12-12-06
            else:                              # Hot HTF Pumps (HTF from TS to PB)
                if PbLoad <= 0.5:
                    EparCt = CtPar * 0.5
                else:
                    EparCt = CtPar
        else:                                # Power Block is not in operation
            EparCt = 0.0                       # No CT Operation
            EparBop = 0.0                      # No BOP Operation
        Epar = SFTotPar + EparHtr + EparHhtf + EparBop + EparCt + EparPb
        if PbLoad == 0.0:
            EparOffLine = Epar  # if powerblock not running, then all parasitics are offline parasitics
            EparOnLine = 0.0
        else:
            if (Egr - Epar) > 0.0: # if powerblock running and gross output exceeds parasitics 
                EparOnLine = Epar
                EparOffLine = 0.0
            else: # if powerblock is running but the gross output does NOT exceed parasitics (why is it running then??)
                EparOnLine = Egr
                EparOffLine = Epar - Egr
        Enet = Egr - Epar
        self.value(O_Enet, Enet)        # | Net Electric Energy Production (Gross-Parasitics)              |      MWe       |     MWe
        self.value(O_EgrSol, EgrSol)        # | Gross Solar Electric Generation                                |      MW        |     MW
        self.value(O_EMin, Emin)          # | Solar Electric Generation below minimum powerplant output      |      MW        |     MW
        self.value(O_Edump, Edump)         # | Solar Electric Generation that is in excess of powerplant max  |      MW        |     MW
        self.value(O_Pbload, PbLoad)        # | Fraction of current Powerblock output to design output         | Dimensionless  | Dimensionless
        self.value(O_EgrFos, EgrFos)        # | Gross Fossil Electric Generation                               |      MW        |     MW
        self.value(O_Egr, Egr)           # | Gross Total Electric Generation                                |      MW        |     MW
        self.value(O_Qgas, Qgas)          # | Gas Thermal Energy Input                                       |      MW        |     MW
        self.value(O_HtrLoad, HtrLoad)       # | Heater Load Factor vs. rated output                            | Dimensionless  | Dimensionless
        self.value(O_Epar, Epar)         #  | Total Parasitics for entire system                            |      MW        |     MW
        self.value(O_EparPB, EparPb)        # | Fixed Power Block Parasitics (24 hr)
        self.value(O_EparBOP, EparBop)       # | Balance of Plant Parasitics                                    |      MW        |     MW
        self.value(O_EparCT, EparCt)        # | Cooling Tower Parasitic Loads                                  |      MW        |     MW
        self.value(O_EparHtr, EparHtr)       # | Heater Parasitics ???
        self.value(O_EparOffLine, EparOffLine)   # | Offline Parasitics ???
        self.value(O_EparOnLine, EparOnLine)    # | Online Parasitics ???
        return 0

# Type registration (faithful translation of TCS_IMPLEMENT_TYPE macro)
TCS_IMPLEMENT_TYPE(sam_trough_plant_type807, "SAM Trough Plant", "Steven Janzou", 1, sam_trough_plant_type807_variables, None, 0)
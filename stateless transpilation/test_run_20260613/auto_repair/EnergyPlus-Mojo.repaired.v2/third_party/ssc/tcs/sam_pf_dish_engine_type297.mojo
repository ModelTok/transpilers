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
from tcstype import tcstypeinterface, tcscontext, tcstypeinfo, tcsvarinfo, TCS_PARAM, TCS_NUMBER, TCS_INPUT, TCS_OUTPUT, TCS_INVALID, TCS_ERROR, tcs_implement_type
from sam_csp_util import *
from math import pow, max, min

// Enum for parameters, inputs, outputs
let P_MANUFACTURER: Int = 0
let P_T_HEATER_HEAD_HIGH: Int = 1
let P_T_HEATER_HEAD_LOW: Int = 2
let P_BEALE_CONST_COEF: Int = 3
let P_BEALE_FIRST_COEF: Int = 4
let P_BEALE_SQUARE_COEF: Int = 5
let P_BEALE_THIRD_COEF: Int = 6
let P_BEALE_FOURTH_COEF: Int = 7
let P_PRESSURE_COEF: Int = 8
let P_PRESSURE_FIRST: Int = 9
let P_ENGINE_SPEED: Int = 10
let P_V_DISPLACED: Int = 11
let I_P_SE: Int = 12
let I_T_AMB: Int = 13
let I_N_COLS: Int = 14
let I_T_COMPRESSION: Int = 15
let I_T_HEATER_HEAD_OPERATE: Int = 16
let I_P_IN_COLLECTOR: Int = 17
let O_P_OUT_SE: Int = 18
let O_P_SE_LOSSES: Int = 19
let O_ETA_SE: Int = 20
let O_T_HEATER_HEAD_LOW: Int = 21
let O_T_HEATER_HEAD_HIGH: Int = 22
let O_V_DISPLACED: Int = 23
let O_FREQUENCY: Int = 24
let O_ENGINE_PRESSURE: Int = 25
let O_ETA_GROSS: Int = 26
let N_MAX: Int = 27

let sam_pf_dish_engine_type297_variables: StaticArray[tcsvarinfo, N_MAX] = StaticArray[tcsvarinfo, N_MAX](
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_MANUFACTURER,          "manufacturer",       "Manufacturer (fixed as 5)",                    "-",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_HEATER_HEAD_HIGH,    "T_heater_head_high", "Heater Head Set Temperature",                  "K",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_HEATER_HEAD_LOW,     "T_heater_head_low",  "Header Head Lowest Temperature",               "K",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BEALE_CONST_COEF,      "Beale_const_coef",   "Beale Constant Coefficient",                   "-",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BEALE_FIRST_COEF,      "Beale_first_coef",   "Beale first-order coefficient",                "1/W",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BEALE_SQUARE_COEF,     "Beale_square_coef",  "Beale second-order coefficient",               "1/W^2",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BEALE_THIRD_COEF,      "Beale_third_coef",   "Beale third-order coefficient",                "1/W^3",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BEALE_FOURTH_COEF,     "Beale_fourth_coef",  "Beale fourth-order coefficient",               "1/W^4",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PRESSURE_COEF,         "Pressure_coef",	   "Pressure constant coefficient",                "MPa",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PRESSURE_FIRST,        "Pressure_first",	   "Pressure first-order coefficient",             "MPa/W",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ENGINE_SPEED,          "engine_speed",	   "Engine operating speed",                       "rpm",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_V_DISPLACED,           "V_displaced",		   "Displaced engine volume",                      "m3",   "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_SE,                  "P_SE",                      "Receiver output power",                        "kW", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_AMB,                 "T_amb",					  "Ambient temperature in Kelvin",                "K", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_N_COLS,                "N_cols",					  "Number of collectors",                         "-", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_COMPRESSION,         "T_compression",			  "Receiver efficiency",                          "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_HEATER_HEAD_OPERATE, "T_heater_head_operate",	  "Receiver head operating temperature",          "K", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_IN_COLLECTOR,        "P_in_collector",			  "Power incident on the collector",              "kW", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_OUT_SE,             "P_out_SE",                  "Stirling engine gross output",     "kW", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_SE_LOSSES,          "P_SE_losses",				  "Stirling engine losses",           "kW", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_SE,               "eta_SE",					  "Stirling engine efficiency",       "-", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_HEATER_HEAD_LOW,    "T_heater_head_low",		  "Header Head Lowest Temperature",   "K", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_HEATER_HEAD_HIGH,   "T_heater_head_high",		  "Heater Head Set Temperature",      "K", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_V_DISPLACED,          "V_displaced",				  "Displaced engine volume",          "cm^3", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_FREQUENCY,            "frequency",				  "Engine frequency (= RPM/60s)",     "1/s", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ENGINE_PRESSURE,      "engine_pressure",			  "Engine pressure",                  "Pa", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_GROSS,            "eta_gross",				  "Gross efficiency of the system",   "-", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX,			0,					0, 0, 0, 0, 0)
)

class sam_pf_dish_engine_type297(tcstypeinterface):
    var m_manufacturer: Int
    var m_T_heater_head_high: Float64
    var m_T_heater_head_low: Float64
    var m_Beale_const_coef: Float64
    var m_Beale_first_coef: Float64
    var m_Beale_square_coef: Float64
    var m_Beale_third_coef: Float64
    var m_Beale_fourth_coef: Float64
    var m_Pressure_coef: Float64
    var m_Pressure_first: Float64
    var m_engine_speed: Float64
    var m_V_displaced: Float64

    def __init__(self, cst: tcscontext, ti: tcstypeinfo):
        super().__init__(cst, ti)
        self.m_manufacturer = -1
        self.m_T_heater_head_high = Float64.NaN
        self.m_T_heater_head_low = Float64.NaN
        self.m_Beale_const_coef = Float64.NaN
        self.m_Beale_first_coef = Float64.NaN
        self.m_Beale_square_coef = Float64.NaN
        self.m_Beale_third_coef = Float64.NaN
        self.m_Beale_fourth_coef = Float64.NaN
        self.m_Pressure_coef = Float64.NaN
        self.m_Pressure_first = Float64.NaN
        self.m_engine_speed = Float64.NaN
        self.m_V_displaced = Float64.NaN

    def __del__(self): pass

    def init(self) -> Int:
        self.m_manufacturer = Int(self.value(P_MANUFACTURER))
        if self.m_manufacturer == 1:							// SES System = 1
            self.m_T_heater_head_high = 993.0
            self.m_T_heater_head_low = 973.0
            self.m_Beale_const_coef = 0.04247
            self.m_Beale_first_coef = 0.00001682
            self.m_Beale_square_coef = -5.105E-10
            self.m_Beale_third_coef = 7.0726E-15
            self.m_Beale_fourth_coef = -3.586E-20
            self.m_Pressure_coef = 0.658769
            self.m_Pressure_first = 0.000234963
            self.m_engine_speed = 1800.0
            self.m_V_displaced = 380*0.000001
        elif self.m_manufacturer == 2:							// WGA System = 2
            self.m_T_heater_head_high = 903.0	
            self.m_T_heater_head_low = 903.0	
            self.m_Beale_const_coef = 0.0850686      //   !0.103371  !-0.00182451  
            self.m_Beale_first_coef = 0.0000194116   //     !0.0000184703     !0.0000260289
            self.m_Beale_square_coef = -3.18449E-10   //    !-3.07798e-10    !-4.68164E-10 
            self.m_Pressure_coef = -0.736342         // ! -0.412058  !-0.0200284
            self.m_Pressure_first = 0.00036416       //   !0.000359699  !0.000352522
            self.m_engine_speed = 1800.0              //  !rpm
            self.m_V_displaced = 160.0 * 0.000001     //     !convert(cm^3, m^3)
            self.m_Beale_third_coef = 0.0
            self.m_Beale_fourth_coef = 0.0    
        elif self.m_manufacturer == 3:							// SBP System = 3
            self.m_T_heater_head_high = 903.0	
            self.m_T_heater_head_low = 903.0	
            self.m_Beale_const_coef = -0.00182451
            self.m_Beale_first_coef = 0.0000260289
            self.m_Beale_square_coef = -4.68164E-10
            self.m_Pressure_coef = -0.0200284
            self.m_Pressure_first = 0.000352522
            self.m_engine_speed = 1800.0                    //  !rpm  
            self.m_V_displaced = 160.0 * 0.000001    // !convert(cm^3, m^3)
            self.m_Beale_third_coef = 0.0
            self.m_Beale_fourth_coef = 0.0      
        elif self.m_manufacturer == 4:							// SAIC System = 4
            self.m_T_heater_head_high = 993.0	
            self.m_T_heater_head_low = 973.0
            self.m_Beale_const_coef = -0.016
            self.m_Beale_first_coef = 0.000015
            self.m_Beale_square_coef = -3.50E-10
            self.m_Beale_third_coef = 3.85E-15
            self.m_Beale_fourth_coef = -1.6E-20
            self.m_Pressure_coef = 0.0000347944
            self.m_Pressure_first = 5.26329E-9
            self.m_engine_speed = 2200.0                 //  !rpm
        elif self.m_manufacturer == 5:
            self.m_T_heater_head_high = self.value(P_T_HEATER_HEAD_HIGH)
            self.m_T_heater_head_low = self.value(P_T_HEATER_HEAD_LOW)
            self.m_Beale_const_coef = self.value(P_BEALE_CONST_COEF)
            self.m_Beale_first_coef = self.value(P_BEALE_FIRST_COEF)
            self.m_Beale_square_coef = self.value(P_BEALE_SQUARE_COEF)
            self.m_Beale_third_coef = self.value(P_BEALE_THIRD_COEF)
            self.m_Beale_fourth_coef = self.value(P_BEALE_FOURTH_COEF)
            self.m_Pressure_coef = self.value(P_PRESSURE_COEF)
            self.m_Pressure_first = self.value(P_PRESSURE_FIRST)
            self.m_engine_speed = self.value(P_ENGINE_SPEED)
            self.m_V_displaced = self.value(P_V_DISPLACED)
        else:
            self.message(TCS_ERROR,  "Manufacturer integer needs to be from 1 to 5" )
            return -1
        return 0

    def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
        var P_SE: Float64 = self.value(I_P_SE)
        var T_compression: Float64 = self.value(I_T_COMPRESSION)
        var T_heater_head_operate: Float64 = self.value(I_T_HEATER_HEAD_OPERATE)
        var P_in_collector: Float64 = self.value(I_P_IN_COLLECTOR)
        /* ===============================================
        !Curve fit of engine performance using Beale-Max method [Watts]
        !X-axis is input power to Stirling engine in Watts
        !Y-axis is the Beale number divided by 1-sqrt(TC/TE)*/
        var frequency: Float64 = max(0.001, self.m_engine_speed / 60.0)				// Hz
        var Beale_max_fit: Float64 = self.m_Beale_const_coef + self.m_Beale_first_coef*P_SE*1000.0 + 
                      (self.m_Beale_square_coef*pow(P_SE*1000.0, 2.0)) + 
                      (self.m_Beale_third_coef*pow(P_SE*1000.0, 3.0)) + 
                      (self.m_Beale_fourth_coef*pow(P_SE*1000.0, 4.0))  
        var engine_pressure_fit: Float64
        if self.m_manufacturer == 4:				// SAIC varies the engine volume not pressure
            engine_pressure_fit = 12.0		// MPa
            self.m_V_displaced = max(0.00001, self.m_Pressure_coef+self.m_Pressure_first*P_SE*1000.0)  //!pressure_coef actually is volume
        else								// all other systems vary the pressure not volume
            engine_pressure_fit = max(0.001, self.m_Pressure_coef + self.m_Pressure_first*P_SE*1000.0)
        var P_SE_out: Float64 = (Beale_max_fit*(engine_pressure_fit*1.0e6 
                      * self.m_V_displaced*frequency)*(1.0-pow(T_compression/T_heater_head_operate, 0.5)))/1000.0
        if P_SE >= 0.025:
            if P_SE_out >= 0:
                if P_SE_out < P_SE:    
                    self.value(O_P_OUT_SE, P_SE_out)
                    self.value(O_P_SE_LOSSES, P_SE - P_SE_out)
                else:
                    self.value(O_P_OUT_SE, 0.0)
                    self.value(O_P_SE_LOSSES, 0.001)		//1 Watt so parasitic code is ok
            else:
                self.value(O_P_OUT_SE, 0.0)
                self.value(O_P_SE_LOSSES, 0.001)			//1 Watt so parasitic code is ok
        else:
            self.value(O_P_OUT_SE, 0.0)
            self.value(O_P_SE_LOSSES, 0.001)				//1 Watt so parasitic code is ok
        self.value(O_ETA_SE, self.value(O_P_OUT_SE)/(self.value(O_P_OUT_SE)+self.value(O_P_SE_LOSSES)+0.000000001) )
        self.value(O_T_HEATER_HEAD_HIGH, self.m_T_heater_head_high)
        self.value(O_T_HEATER_HEAD_LOW, self.m_T_heater_head_low)
        self.value(O_V_DISPLACED, self.m_V_displaced)
        self.value(O_FREQUENCY, frequency)
        self.value(O_ENGINE_PRESSURE, engine_pressure_fit*1.0e6)
        self.value(O_ETA_GROSS, self.value(O_P_OUT_SE)/(P_in_collector+0.00000001) )
        return 0

    def converged(self, time: Float64) -> Int:
        return 0

tcs_implement_type(sam_pf_dish_engine_type297, "Collector Dish", "Ty Neises", 1, sam_pf_dish_engine_type297_variables, None, 1)
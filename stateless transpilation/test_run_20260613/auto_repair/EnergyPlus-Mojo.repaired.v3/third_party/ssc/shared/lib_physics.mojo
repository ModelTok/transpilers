# /**
# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met :
# 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# */
# #ifndef __lib_physics_h
# #define __lib_physics_h
# #include <math.h>
# #include <assert.h>

from math import acos, pow

# namespace physics

alias PI = 2.0 * acos(0.0)
alias FT_PER_METER = 3.280839895			# feet per meter
alias PSI_PER_BAR = 14.50377373066			# psi per bar
alias PSI_PER_INHG = 0.4911541474703		# psi per inch of mercury
alias Pa_PER_Atm = 101325.00				# pascals per atm;  101300.0 is value from FORTRAN code
alias Pa_PER_inHg = 3386.00
alias Atm_PER_Bar = 0.986923267			# atmospheres per bar
alias KGM3_PER_LBF3 = 16.01846337396		# lbs/ft^3 per kg/m^3 
alias LB_PER_KG = 2.204622621849			# pounds per kilogram
alias KW_PER_HP = 0.7456998715801		# kilowatts per unit of horsepower
alias GRAVITY_MS2 = 9.8					# meters per second^2; this varies between 9.78 and 9.82 depending on latitude
alias GRAVITY_FTS2 = 32.174				# ft per second^2
alias SPECIFIC_HEAT_LIQUID_WATER = 4.183 # /*4.1813*/	# J/g*K = joules per gram-degrees K; 4.183 is value currently in Fortran
alias WATER_DENSITY = 62.4				# lb/ft^3
alias R_GAS_DRY_AIR = 287.058
alias GAS_CONSTANT_SUPER_HEATED_STEAM = 0.461522		# kJ/kg-K
alias MIN_TEMP_FOR_SUPER_HEATED = 647.073			# deg K
alias MIN_TEMP_FOR_STEAM1 = 623.15			# K

def areaCircle(radius: Float64) -> Float64:
    return PI * pow(radius, 2.0)

def FarenheitToCelcius(dTempInFarenheit: Float64) -> Float64:
    return ((5.0 / 9.0) * (dTempInFarenheit - 32.0))

def CelciusToFarenheit(dTempInCelcius: Float64) -> Float64:
    return (1.8 * dTempInCelcius) + 32.0

def KelvinToCelcius(dTempInKelvin: Float64) -> Float64:
    return (dTempInKelvin - 273.15)

def CelciusToKelvin(dTempInCelcius: Float64) -> Float64:
    return (dTempInCelcius + 273.15)

def FarenheitToKelvin(dTempInFarenheit: Float64) -> Float64:
    return (CelciusToKelvin(FarenheitToCelcius(dTempInFarenheit)))

def KelvinToFarenheit(dTempInKelvin: Float64) -> Float64:
    return (CelciusToFarenheit(KelvinToCelcius(dTempInKelvin)))

def AtmToPa(dPressureInAtm: Float64) -> Float64:
    return dPressureInAtm * Pa_PER_Atm

def PaToAtm(dPressureInPa: Float64) -> Float64:
    return dPressureInPa / Pa_PER_Atm

def InHgToPa(dPressureInInchesHg: Float64) -> Float64:
    return dPressureInInchesHg * Pa_PER_inHg

def PaToInHg(dPressureInPa: Float64) -> Float64:
    return dPressureInPa / Pa_PER_inHg

def mBarToAtm(PressureInmBar: Float64) -> Float64:
    return PressureInmBar * Atm_PER_Bar / 1000

def mBarToPSI(PressureInmBar: Float64) -> Float64:
    return PressureInmBar * PSI_PER_BAR / 1000

def PsiToBar(psi: Float64) -> Float64:
    return psi / PSI_PER_BAR

def toWattHr(btu: Float64) -> Float64:
    return (btu / 3.413)

def PSItoFT(psi: Float64) -> Float64:
    return psi * 144 / WATER_DENSITY  # convert PSI to pump 'head' in feet.  assumes water density ~ 62.4 lb/ft^3

def EnthalpyFromTempAndPressure(tempK: Float64, pressureBar: Float64, enthalpy: Pointer[Float64]) -> Bool:
    if (273.15 <= tempK) and (tempK < 600):
        enthalpy[] = 1407.2755490486
        return True
    elif (tempK < 1273.15) and (pressureBar < 220):
        enthalpy[] = 2983.06526185584
        return True
    return False

alias AIR_DENSITY_SEA_LEVEL = Pa_PER_Atm / (R_GAS_DRY_AIR * CelciusToKelvin(15)) # kg/m^3 at sea level (1 atm) and 15 C

# #endif //__lib_physics_h
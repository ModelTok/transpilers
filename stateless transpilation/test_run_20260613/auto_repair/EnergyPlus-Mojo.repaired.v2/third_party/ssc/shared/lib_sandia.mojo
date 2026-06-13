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
from math import exp, log, pow, cos
from lib_pvmodel import pvmodule_t, pvinput_t, pvoutput_t, pvcelltemp_t
from lib_sandia import sandia_module_t, sandia_celltemp_t, sandia_inverter_t
from memory.unsafe import Pointer
from utils import List

def sandia_voc( Tc: Float64, Ee: Float64, Voc0: Float64, NcellSer: Float64, DiodeFactor: Float64, BVoc0: Float64, mBVoc: Float64 ) -> Float64:
{
/*
C Returns Open-Circuit Voltage (V)
C Tc = cell temperature (deg C)
C Ee = effective irradiance
C Voco = Voc at SRC (1000 W/m2, 25 C) (V)
C NcellSer = # cells in series
C DiodeFactor = module-specIFic empirical constant
C BVoc0 = Voc temperature coefficient (V/C)
C mBVoc = change in BVoc with irradiance
*/
	if ( Ee > 0.0 ) {
		var dTc: Float64 = DiodeFactor*((1.38066E-23*(Tc + 273.15))/1.60218E-19);
		var BVocEe: Float64 = BVoc0 + mBVoc * (1.0 - Ee);
		return Voc0+NcellSer*dTc*log(Ee)+BVocEe*(Tc-25.0);
	}
	else
		return 0.0;
}

def sandia_vmp( Tc: Float64, Ee: Float64, Vmp0: Float64, NcellSer: Float64, DiodeFactor: Float64, BVmp0: Float64,
	double mBVmp: Float64, C2: Float64, C3: Float64 ) -> Float64:
{
	/*
C Returns Voltage at Max. Power Point (V)
C Tc = cell temperature (deg C)
C Ee = effective irradiance
C Vmpo = Vmp at SRC (1000 W/m2, 25 C) (V)
C NcellSer = # cells in series
C DiodeFactor = module-specIFic empirical constant
C BVmp0 = Vmp temperature coefficient (V/C)
C mBVmp = change in BVmp with irradiance
C c2,c3 = empirical module-specIFic constants
*/
	if ( Ee > 0.0 )
	{
		var dTc: Float64 = DiodeFactor*((1.38066E-23*(Tc+273.15))/1.60218E-19);
		var BVmpEe: Float64 = BVmp0 + mBVmp * (1.0 - Ee);
		return Vmp0+C2*NcellSer*dTc*log(Ee)+C3*NcellSer*pow((dTc*log(Ee)),2)+BVmpEe*(Tc-25.0);
	}
	else
		return 0.0;
}

def sandia_isc( Tc: Float64, Isc0: Float64, Ibc: Float64, Idc: Float64, F1: Float64, F2: Float64, fd: Float64, aIsc: Float64, radmode: Int32, poaIrr: Float64 ) -> Float64:
{
	/*
C Returns Short-Circuit Current
C Isc0 = Isc at Tc=25 C, Ic=1000 W/m2 (A)
C Ibc  = beam radiation on collector plane (W/m2)
C Idc  = Diffuse radiation on collector plane (W/m2)
C F1   = Sandia F1 function of air mass
C F2   = Sandia F2 function of incidence angle
C fd   = module-specIFic empirical constant
C aIsc = Isc temperature coefficient (1/degC)
C Tc   = cell temperature */
	var Isc: Float64;
	if (radmode == 3) //reference cell
		Isc = Isc0*(poaIrr / 1000.0)*(1.0 + aIsc*(Tc - 25.0)); //per Cliff: 
	else if (radmode == 4) //POA irradiance sensor ("broadband" in Cliff's email)
		Isc = Isc0*F1*(poaIrr / 1000.0)*(1.0 + aIsc*(Tc - 25.0));
	else
		Isc = Isc0*F1*((Ibc*F2+fd*Idc)/1000.0)*(1.0+aIsc*(Tc-25.0));
	return Isc;
}

def sandia_imp(Tc: Float64, Ee: Float64, Imp0: Float64, aImp: Float64, C0: Float64, C1: Float64) -> Float64:
{ /*
C Returns current at maximum power point (A)
C Tc = cell temperature (degC)
C Ee = effective irradiance (W/m2)
C Imp0 = current at MPP at SRC (1000 W/m2, 25 C) (A)
C aImp = Imp temperature coefficient (degC^-1)
C c0,c1 = empirical module-specIFic constants */
	return Imp0*(C0*Ee+C1*Ee*Ee)*(1.0+aImp*(Tc-25.0));
}

def sandia_f2( IncAng: Float64, b0: Float64, b1: Float64, b2: Float64, b3: Float64, b4: Float64, b5: Float64 ) -> Float64:
{
	/*
C Returns Sandia F2 function
C IncAng = incidence angle (deg)
C b0,b1,b2,b3,b4,b5 = empirical module-specIFic constants
*/
	var F2: Float64 = b0
		+ b1*IncAng
		+ b2*IncAng*IncAng
		+ b3*IncAng*IncAng*IncAng
		+ b4*IncAng*IncAng*IncAng*IncAng
		+ b5*IncAng*IncAng*IncAng*IncAng*IncAng;
	return F2 > 0.0 ? F2 : 0.0;
} 

def sandia_f1( AMa: Float64, a0: Float64, a1: Float64, a2: Float64, a3: Float64, a4: Float64 ) -> Float64:
{
	/*
C Returns the Sandia Air Mass function
C AMa = absolute air mass
C a0,a1,a2,a3,a4 = empirical constants, module-specIFic
*/
	var F1: Float64 = a0 
		+ a1*AMa 
		+ a2*AMa*AMa 
		+ a3*AMa*AMa*AMa 
		+ a4*AMa*AMa*AMa*AMa;
	return F1 > 0.0 ? F1 : 0.0;
} 

def sandia_absolute_air_mass( SolZen: Float64, Altitude: Float64 ) -> Float64:
 {
 /*
C Returns absolute air mass
C SolZen = solar zenith (deg)
C Altitude = site altitude (m)
*/
	if (SolZen < 89.9)
	{
		var AM: Float64 = 1/(cos(SolZen * 0.01745329) + 0.5057 * pow( (96.08 - SolZen),-1.634));
		return AM * exp(-0.0001184 * Altitude);
	}
	else
		return 999;
}

def sandia_effective_irradiance( Tc: Float64, Isc: Float64, Isc0: Float64, aIsc: Float64 ) -> Float64:
{
	/*
C Returns "effective irradiance", used in calculation of Imp, Voc, Ix, Ixx
C Tc   = cell temperature
C Isc = short-circuit current under operating conditions (A)
C Isc0 = Isc at Tc=25 C, Ic=1000 W/m2 (A)
C aIsc = Isc temperature coefficient (degC^-1) */
	return Isc / (1.0+aIsc*(Tc - 25.0))/Isc0;
}

def sandia_current_at_voltage(V: Float64, VmaxPow: Float64, ImaxPow: Float64, Voc: Float64, Isc: Float64) -> Float64:
{
/* from sam_sandia_pv_type701.for
	DOUBLE PRECISION TRW_Current
	DOUBLE PRECISION V,VmaxPow,ImaxPow,Voc,Isc
	DOUBLE PRECISION C_1,C_2,Itrw
        IF ((Isc.GT.0.).AND.(Voc.GT.0.)) THEN
	    IF(ImaxPow.LT.Isc) THEN
            C_2 = (VmaxPow / Voc - 1.0)/ Log(1.0 - ImaxPow / Isc)
	    ELSE
	      C_2 = 0.0
	    ENDIF
          IF (C_2.GT.0.) THEN
            C_1 = (1.0 - ImaxPow / Isc) * Exp(-VmaxPow / C_2 / Voc)
            Itrw = Isc*(1.0 - C_1 * (Exp(V / C_2 / Voc) - 1.0))
          ELSE
            Itrw = 0.0
          ENDIF
        ELSE
          Itrw = 0.0
        ENDIF
	  IF(Itrw.LT.0.0) THEN
	    Itrw=0.0
	  ENDIF
	  TRW_Current=Itrw
 */
	var Itrw: Float64 = 0.0
	var C_1: Float64 = 0.0
	var C_2: Float64 = 0.0
	if ((Isc > 0) && (Voc > 0)) {
	    if(ImaxPow < Isc) C_2 = (VmaxPow / Voc - 1.0)/ log(1.0 - ImaxPow / Isc);
        if (C_2 > 0) {
            C_1 = (1.0 - ImaxPow / Isc) * exp(-VmaxPow / C_2 / Voc);
            Itrw = Isc*(1.0 - C_1 * (exp(V / C_2 / Voc) - 1.0));
		} else {
            Itrw = 0.0;
		}
	}
	if(Itrw < 0) Itrw=0;
	return Itrw;
}

@value
struct sandia_module_t:
	var A0: Float64
	var A1: Float64
	var A2: Float64
	var A3: Float64
	var A4: Float64
	var B0: Float64
	var B1: Float64
	var B2: Float64
	var B3: Float64
	var B4: Float64
	var B5: Float64
	var C0: Float64
	var C1: Float64
	var C2: Float64
	var C3: Float64
	var C4: Float64
	var C5: Float64
	var C6: Float64
	var C7: Float64
	var Isc0: Float64
	var aIsc: Float64
	var Imp0: Float64
	var aImp: Float64
	var Voc0: Float64
	var BVoc0: Float64
	var mBVoc: Float64
	var Vmp0: Float64
	var BVmp0: Float64
	var mBVmp: Float64
	var Ix0: Float64
	var Ixx0: Float64
	var fd: Float64
	var DiodeFactor: Float64
	var NcellSer: Float64
	var Area: Float64

	def __init__(inout self):
		self.A0 = Float64.NaN
		self.A1 = Float64.NaN
		self.A2 = Float64.NaN
		self.A3 = Float64.NaN
		self.A4 = Float64.NaN
		self.B0 = Float64.NaN
		self.B1 = Float64.NaN
		self.B2 = Float64.NaN
		self.B3 = Float64.NaN
		self.B4 = Float64.NaN
		self.B5 = Float64.NaN
		self.C0 = Float64.NaN
		self.C1 = Float64.NaN
		self.C2 = Float64.NaN
		self.C3 = Float64.NaN
		self.C4 = Float64.NaN
		self.C5 = Float64.NaN
		self.C6 = Float64.NaN
		self.C7 = Float64.NaN
		self.Isc0 = Float64.NaN
		self.aIsc = Float64.NaN
		self.Imp0 = Float64.NaN
		self.aImp = Float64.NaN
		self.Voc0 = Float64.NaN
		self.BVoc0 = Float64.NaN
		self.mBVoc = Float64.NaN
		self.Vmp0 = Float64.NaN
		self.BVmp0 = Float64.NaN
		self.mBVmp = Float64.NaN
		self.Ix0 = Float64.NaN
		self.Ixx0 = Float64.NaN
		self.fd = Float64.NaN
		self.DiodeFactor = Float64.NaN
		self.NcellSer = Float64.NaN
		self.Area = Float64.NaN

	def AreaRef(self) -> Float64:
		return self.Area

	def VmpRef(self) -> Float64:
		return self.Vmp0

	def ImpRef(self) -> Float64:
		return self.Imp0

	def VocRef(self) -> Float64:
		return self.Voc0

	def IscRef(self) -> Float64:
		return self.Isc0

	def __call__(self, inout input: pvinput_t, TcellC: Float64, opvoltage: Float64, inout output: pvoutput_t) -> Bool:
		output.Power = 0.0
		output.Voltage = 0.0
		output.Current = 0.0
		output.Efficiency = 0.0
		output.Voc_oper = 0.0
		output.Isc_oper = 0.0
		output.CellTemp = TcellC
		var Gtotal: Float64
		if( input.radmode != 3 or not input.usePOAFromWF )
			Gtotal = input.Ibeam + input.Idiff + input.Ignd
		else
			Gtotal = input.poaIrr
		if ( Gtotal > 0.0 )
		{
			var AMa: Float64 = sandia_absolute_air_mass(input.Zenith, input.Elev)
			var F1: Float64 = sandia_f1(AMa,self.A0,self.A1,self.A2,self.A3,self.A4)
			var F2: Float64 = sandia_f2(input.IncAng,self.B0,self.B1,self.B2,self.B3,self.B4,self.B5)
			var Isc: Float64 = sandia_isc(TcellC,self.Isc0,input.Ibeam, input.Idiff+input.Ignd,F1,F2,self.fd,self.aIsc, input.radmode, Gtotal)
			var Ee: Float64 = sandia_effective_irradiance(TcellC,Isc,self.Isc0,self.aIsc)
			var Imp: Float64 = sandia_imp(TcellC,Ee,self.Imp0,self.aImp,self.C0,self.C1)
			var Voc: Float64 = sandia_voc(TcellC,Ee,self.Voc0,self.NcellSer,self.DiodeFactor,self.BVoc0,self.mBVoc)
			var Vmp: Float64 = sandia_vmp(TcellC,Ee,self.Vmp0,self.NcellSer,self.DiodeFactor,self.BVmp0,self.mBVmp,self.C2,self.C3)
			var V: Float64
			var I: Float64
			if ( opvoltage < 0 )
			{
				V = Vmp
				I = Imp
			}
			else
			{		
				V = opvoltage
				I = sandia_current_at_voltage( opvoltage, Vmp, Imp, Voc, Isc )
			}
			output.Power = V*I
			output.Voltage = V
			output.Current = I
			output.Efficiency = I*V/(Gtotal*self.Area)
			output.AOIModifier = F2
			output.Voc_oper = Voc
			output.Isc_oper = Isc
			output.CellTemp = TcellC
		}
		return True
}

@value
struct sandia_celltemp_t:
	var a: Float64
	var b: Float64
	var DT0: Float64
	var fd: Float64

	def __init__(inout self):
		self.a = Float64.NaN
		self.b = Float64.NaN
		self.DT0 = Float64.NaN
		self.fd = Float64.NaN

	def __call__(self, inout input: pvinput_t, inout module: pvmodule_t, opvoltage: Float64, inout Tcell: Float64) -> Bool:
		var Itotal: Float64
		if( input.radmode != 3 or not input.usePOAFromWF)
			Itotal = input.Ibeam + input.Idiff + input.Ignd
		else
			Itotal = input.poaIrr
		var tmod: Float64 = sandia_module_temperature( Itotal, input.Wspd, input.Tdry, self.fd, self.a, self.b )
		Tcell = sandia_tcell_from_tmodule( tmod, Itotal, self.fd, self.DT0 )
		return True

	def sandia_tcell_from_tmodule( Tm: Float64, poaIrr: Float64, fd: Float64, DT0: Float64) -> Float64:
	{
	/*
C Returns cell temperature, deg C
C Tm  = module temperature (deg C)
C Ibc = beam radiation on collector plane, W/m2
C Idc = Diffuse radiation on collector plane, W/m2
C fd  = fraction of Idc used (empirical constant)
C DT0 = (Tc-Tm) at E=1000 W/m2 (empirical constant known as dTc), deg C
*/
		var E: Float64 = poaIrr
		return Tm + E / 1000.0 * DT0
	}

	def sandia_module_temperature( poaIrr: Float64, Ws: Float64, Ta: Float64, fd: Float64, a: Float64, b: Float64 ) -> Float64:
	{
	/*
C Returns back-of-module temperature, deg C
C Ibc = beam radiation on collector plane, W/m2
C Idc = Diffuse radiation on collector plane, W/m2
C Ws  = wind speed, m/s
C Ta  = ambient temperature, degC
C fd  = fraction of Idc used (empirical constant)
C a   = empirical constant
C b   = empirical constant
*/
		var E: Float64 = poaIrr
		return E * exp(a + b * Ws) + Ta
	}

@value
struct sandia_inverter_t:
	var Paco: Float64
	var Pdco: Float64
	var Vdco: Float64
	var Pso: Float64
	var Pntare: Float64
	var C0: Float64
	var C1: Float64
	var C2: Float64
	var C3: Float64

	def __init__(inout self):
		self.Paco = Float64.NaN
		self.Pdco = Float64.NaN
		self.Vdco = Float64.NaN
		self.Pso = Float64.NaN
		self.Pntare = Float64.NaN
		self.C0 = Float64.NaN
		self.C1 = Float64.NaN
		self.C2 = Float64.NaN
		self.C3 = Float64.NaN

	def acpower(self,
		/* inputs */
		Pdc: Float64,
		Vdc: Float64,
		/* outputs */
		Pac: Pointer[Float64],
		Ppar: Pointer[Float64],
		Plr: Pointer[Float64],
		Eff: Pointer[Float64],
		Pcliploss: Pointer[Float64],
		Psoloss: Pointer[Float64],
		Pntloss: Pointer[Float64]
	) -> Bool:
	{
		var Pdc_vec: List[Float64]
		var Vdc_vec: List[Float64]
		Pdc_vec.append(Pdc)
		Vdc_vec.append(Vdc)
		if not self.acpower(Pdc_vec, Vdc_vec, Pac, Ppar, Plr, Eff, Pcliploss, Psoloss, Pntloss):
			return False
		return True
	}

	def acpower(self,
		/* inputs */
		Pdc: List[Float64],
		Vdc: List[Float64],
		/* outputs */
		Pac: Pointer[Float64],
		Ppar: Pointer[Float64],
		Plr: Pointer[Float64],
		Eff: Pointer[Float64],
		Pcliploss: Pointer[Float64],
		Psoloss: Pointer[Float64],
		Pntloss: Pointer[Float64]
	) -> Bool:
	{
		Pac[] = 0
		Ppar[] = 0.0
		Psoloss[] = 0.0
		Pntloss[] = 0.0
		Pcliploss[] = 0.0
		var Pdc_total: Float64 = 0
		var Pac_each: List[Float64]
		var PacNoPso_each: List[Float64]
		for m in range(Pdc.size):
			Pac_each.append(0)
			PacNoPso_each.append(0)
			var A: Float64 = self.Pdco * (1.0 + self.C1 * (Vdc[m] - self.Vdco))
			var B: Float64 = self.Pso * (1.0 + self.C2 * (Vdc[m] - self.Vdco))
			var C: Float64 = self.C0 * (1.0 + self.C3 * (Vdc[m] - self.Vdco))
			if (B < 0.5 * self.Pso) B = 0.5 * self.Pso
			if (B > 2.0 * self.Pso) B = 2.0 * self.Pso
			Pac_each[m] = ((self.Paco / (A - B)) - C * (A - B)) * (Pdc[m] - B) + self.C0 * (Pdc[m] - B) * (Pdc[m] - B)
			PacNoPso_each[m] = ((self.Paco / A) - C * A) * Pdc[m] + self.C0 * Pdc[m] * Pdc[m]
			Pdc_total += Pdc[m]
		if (Pdc_total <= self.Pso)
		{
			Pac[] = -self.Pntare
			Ppar[] = self.Pntare
			Pntloss[] = self.Pntare
		}
		else
			for m in range(Vdc.size):
				Psoloss[] += PacNoPso_each[m] - Pac_each[m]
				Pac[] += Pac_each[m]
		var PacNoClip: Float64 = Pac[]
		if ( Pac[] > self.Paco )
		{
			Pac[] = self.Paco
			Pcliploss[] = PacNoClip - Pac[]
		}
		Plr[] = Pdc_total / self.Pdco
		Eff[] = Pac[] / Pdc_total
		if ( Eff[] < 0.0 ) Eff[] = 0.0
		return True
	}
}
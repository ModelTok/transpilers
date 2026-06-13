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
/* PVWATTSV.C 
    10/18/2010 This PVWatts version was received from Ray George,
	 for integration into SSC.  Supports sub-hourly calculation.
	8/22/2007 This is a modification of PVWEB2BI.C so that PVWATTS
	can be run for time intervals less than 60 minutes. List of modifications
	follows:
	1. Added float variable step, equals time step of data, value of 60 or less
	2. Solar position determined at the time stamp minus step/2. If elevation
		> 0.5 deg, then PV calculations performed. Time stamp read in will
		need to include minute when read (variable int min)
	3. Functions celltemp, dcpower, and acpower changed to operate on single
		time stamp data rather than 24 hour data. Variables are now non-array.
	4. Data written to file: Year, Month, Day, Hour, Minute, AC power(W).
	PVWEB2BI.C Version for international data sets   2/9/06
	Reads an array of monthly albedo values from a file instead of computing
	from snowcover.
	Reads tmy data from comma delimited files.
	Reads electric cost data in new format and units.
	Default azimuth set based on if north or south hemisphere
	If latitude below equator, set default tilt to abs value
	PVWEB2b.c sets the tmloss = derate/efffp, and pcrate = dcrate, no longer
	need to normalize output to system size because system is now simulated
	for the system input, not 4 kWac. 4/21/05
	PVWEB2.C Changed from inputting an a.c. rating to inputting a d.c. rating
	and a dc to ac derate factor. a.c. rating = d.c. rating x derate factor.
	Reads inputs from c:\pvweb\pvsystm2.dat. Soiling factor is now in derate
	factor. 4/15/05
	PVWEB.C Version of PV simulation software for testing of code for end
	purpose of being available on the web.   12/7/98
	Added function transpoa to account for reflection losses. 12/8/98
	Added soiling factor of 1% loss and changed array height to 5m. 12/22/98
	Changed temperature degradation from -0.004 to -0.005, increased dc rating
	to accomodate  3/3/99
	Changed rating to 4000 Wac at STC, required dc rating change to 4503.9
	and changed inverter rating to 4500 W.   5/26/99
	Changed soiling loss from 1% to 3%     9/16/99 */
from math import pow, exp, fabs, cos
from memory import memset_zero

# ifndef M_PI
# define M_PI 3.1415926535
# endif

def transpoa( poa: Float64, dn: Float64, inc: Float64, ar_glass: Bool ) -> Float64:
	"""  
	/* Calculates the irradiance transmitted thru a PV module cover. Uses King
		polynomial coefficients for glass from 2nd World Conference Paper,
		July 6-10, 1998.                         Bill Marion 12/8/1998 */
	"""
	var b0: Float64 = 1.0
	var b1: Float64 = -2.438e-3
	var b2: Float64 = 3.103e-4
	var b3: Float64 = -1.246e-5
	var b4: Float64 = 2.112e-7
	var b5: Float64 = -1.359e-9
	if ar_glass:
		b0 = 1.0002
		b1 = -0.000213
		b2 = 3.63416e-005
		b3 = -2.175e-006
		b4 = 5.2796e-008
		b5 = -4.4351e-010
	inc = inc/0.017453293
	if inc > 50.0 and inc < 90.0: /* Adjust for relection between 50 and 90 degrees */
		var x: Float64 = b0 + b1*inc + b2*inc*inc + b3*inc*inc*inc + b4*inc*inc*inc*inc + b5*inc*inc*inc*inc*inc
		poa = poa - ( 1.0 - x )*dn*cos(inc*0.017453293)
		if poa < 0.0:
			poa = 0.0
	return poa

@value
struct pvwatts_celltemp:
	"""  
	/*  
	This class was converted from the original PVWatts subroutine
	to store the previous irradiance and cell temp to make the model
	give consistent results with the online PVWatts V1.  Previously
	all calculations were done over the course of a day, so the
	previous module/sun values were saved, but in the single time stamp
	version, these changes were not tracked.  apd 2/24/2012
	Defines function to calculate cell temperature, changed 8/22/2007 to
	 work with single time stamp data, also see pvsubs2.c
	This function was converted from a PVFORM version 3.3 subroutine
c     this routine estimates the array temperature given the poa radiation,
c     ambient temperature, and wind speed.  it uses an advanced cell temp
c     model developed by m fuentes at snla.  if the poa insolation is eq
c     zero then set cell temp = 999.
c
	passed variables:
		inoct = installed nominal operating cell temperature (deg K)
		height = average array height (meters)
		poa2 = plane of array irradiances (W/m2)
		ws2 = wind speeds (m/s)
		ambt2 = ambient temperatures (deg C)
c  local variables :
c     absorb = absorbtivity
c     backrt = ratio of actual backside heat xfer to theoretical of rack mount
c     boltz = boltzmann's constant
c     cap = capacitance per unit area of module
c     capo = capacitance per unit area of rack mounted module
c     conair = conductivity of air
c     convrt = ratio of total convective heat xfer coef to topside hxc
c     denair = density of air
c     dtime = time step
c     eigen = product of eigen value and time step
c     emmis = emmisivity
		ex = ?
c     grashf = grashoffs number
c     hconv = convective coeff of module (both sides)
c     hforce = forced convective coeff of top side
c     hfree = free convective coeff of top side
c     hgrnd = radiative heat xfer coeff from module to ground
		hsky = ?
c     iflagc = flag to check if routine has been executed
c     reynld = reynolds number
c     suun = insolation at start of time step
c     suno = previous hours insolation
c     tamb = ambient temp
c     tave = average of amb and cell temp
c     tgrat = ratio of grnd temp above amb to cell temp above amb
c     tgrnd = temperature of ground
c     tmod = computed cell temp
c     tmodo = cell temp for previous time step
c     tsky = sky temp
c     visair = viscosity of air
c     windmd = wind speed at module height
c     xlen = hydrodynamic length of module              */
	"""
	var j: Int
	var height: Float64
	var inoct: Float64
	var absorb: Float64
	var backrt: Float64
	var boltz: Float64
	var cap: Float64
	var capo: Float64
	var conair: Float64
	var convrt: Float64
	var denair: Float64
	var dtime: Float64
	var eigen: Float64
	var emmis: Float64
	var grashf: Float64
	var hconv: Float64
	var hforce: Float64
	var hfree: Float64
	var hgrnd: Float64
	var reynld: Float64
	var suun: Float64
	var suno: Float64
	var tamb: Float64
	var tave: Float64
	var tgrat: Float64
	var tgrnd: Float64
	var tmod: Float64
	var tmodo: Float64
	var tsky: Float64
	var visair: Float64
	var windmd: Float64
	var xlen: Float64
	var hsky: Float64
	var ex: Float64

	def __init__(inout self, _inoct: Float64, _height: Float64, _dTimeHrs: Float64):
		""" constants """
		self.boltz = 0.00000005669
		self.cap = 0
		self.capo = 11000.0
		self.convrt = 0
		self.absorb = 0.83
		self.emmis = 0.84
		self.tgrat = 0
		self.tgrnd = 0
		self.xlen = 0.5
		""" configuration parameters """
		self.inoct = _inoct
		self.height = _height
		""" initial values """
		self.dtime = 12.0
		self.suno = 0.0
		self.tmodo = 293.15
		""" convective coefficient at noct """
		self.windmd = 1.0
		self.tave = (self.inoct + 293.15) / 2.0
		self.denair = 0.003484 * 101325.0 / self.tave
		self.visair = 0.24237e-6 * pow(self.tave, 0.76) / self.denair
		self.conair = 2.1695e-4 * pow(self.tave, 0.84)
		self.reynld = self.windmd * self.xlen / self.visair
		self.hforce = 0.8600 / pow(self.reynld, 0.5) * self.denair * self.windmd * 1007.0 / pow(0.71, 0.67)
		self.grashf = 9.8 / self.tave * (self.inoct - 293.15) * pow(self.xlen, 3.0) / pow(self.visair, 2.0) * 0.5
		self.hfree = 0.21 * pow(self.grashf * 0.71, 0.32) * self.conair / self.xlen
		self.hconv = pow(pow(self.hfree, 3.0) + pow(self.hforce, 3.0), 1.0 / 3.0)
		""" Determine the ground temperature ratio and the ratio of
			the total convection to the top side convection """
		self.hgrnd = self.emmis * self.boltz * (pow(self.inoct, 2.0) + pow(293.15, 2.0)) * (self.inoct + 293.15)
		self.backrt = ( self.absorb * 800.0 - self.emmis * self.boltz * (pow(self.inoct, 4.0) - pow(282.21, 4.0)) - self.hconv * (self.inoct - 293.15) ) / ((self.hgrnd + self.hconv) * (self.inoct - 293.15))
		self.tgrnd = pow(pow(self.inoct, 4.0) - self.backrt * (pow(self.inoct, 4.0) - pow(293.15, 4.0)), 0.25)
		if self.tgrnd > self.inoct:
			self.tgrnd = self.inoct
		if self.tgrnd < 293.15:
			self.tgrnd = 293.15
		self.tgrat = (self.tgrnd - 293.15) / (self.inoct - 293.15)
		self.convrt = (self.absorb * 800.0 - self.emmis * self.boltz * (2.0 * pow(self.inoct, 4.0) - pow(282.21, 4.0) - pow(self.tgrnd, 4.0))) / (self.hconv * (self.inoct - 293.15))
		""" Adjust the capacitance of the module based on the inoct """
		self.cap = self.capo
		if self.inoct > 321.15:
			self.cap = self.cap * (1.0 + (self.inoct - 321.15) / 12.0)
		self.dtime = _dTimeHrs /* set time step */

	def __call__(inout self, poa2: Float64, ws2: Float64, ambt2: Float64, fhconv: Float64 = 1.0) -> Float64:
		var celltemp: Float64 = ambt2
		/* If poa is gt 0 then compute cell temp, else set to 999 */
		if poa2 > 0.0:
			""" Initialize local variables for insolation and temp """
			self.tamb = ambt2 + 273.15
			self.suun = poa2 * self.absorb
			self.tsky = 0.68 * (0.0552 * pow(self.tamb, 1.5)) + 0.32 * self.tamb  /* Estimate sky temperature */
			"""  Estimate wind speed at module height - use technique developed by
					menicucci and hall (sand84-2530) """
			self.windmd = ws2 * pow(self.height / 9.144, 0.2) + 0.0001
			""" Find overall convective coefficient """
			self.tmod = self.tmodo
			for j in range(10):
				self.tave = (self.tmod + self.tamb) / 2.0
				self.denair = 0.003484 * 101325.0 / self.tave
				self.visair = 0.24237e-6 * pow(self.tave, 0.76) / self.denair
				self.conair = 2.1695e-4 * pow(self.tave, 0.84)
				self.reynld = self.windmd * self.xlen / self.visair
				self.hforce = 0.8600 / pow(self.reynld, 0.5) * self.denair * self.windmd * 1007.0 / pow(0.71, 0.67)
				if self.reynld > 1.2e5:
					self.hforce = 0.0282 / pow(self.reynld, 0.2) * self.denair * self.windmd * 1007.0 / pow(0.71, 0.4)
				self.grashf = 9.8 / self.tave * fabs(self.tmod - self.tamb) * pow(self.xlen, 3.0) / pow(self.visair, 2.0) * 0.5
				self.hfree = 0.21 * pow(self.grashf * 0.71, 0.32) * self.conair / self.xlen
				self.hconv = fhconv * self.convrt * pow(pow(self.hfree, 3.0) + pow(self.hforce, 3.0), 1.0 / 3.0)
				""" Solve the heat transfer equation """
				self.hsky = self.emmis * self.boltz * (pow(self.tmod, 2.0) + pow(self.tsky, 2.0)) * (self.tmod + self.tsky)
				self.tgrnd = self.tamb + self.tgrat * (self.tmod - self.tamb)
				self.hgrnd = self.emmis * self.boltz * (self.tmod * self.tmod + self.tgrnd * self.tgrnd) * (self.tmod + self.tgrnd)
				self.eigen = -(self.hconv + self.hsky + self.hgrnd) / self.cap * self.dtime * 3600.0
				self.ex = 0.0
				if self.eigen > -10.0:
					self.ex = exp(self.eigen)
				self.tmod = self.tmodo * self.ex + ((1.0 - self.ex) * (self.hconv * self.tamb + self.hsky * self.tsky + self.hgrnd * self.tgrnd + self.suno + (self.suun - self.suno) / self.eigen) + self.suun - self.suno) / (self.hconv + self.hsky + self.hgrnd)
			self.tmodo = self.tmod  /* Save the new values as initial values for the next hour */
			self.suno = self.suun
			celltemp = self.tmod - 273.15  /* PV module temperature in degrees C */
		else:
			/* sun down, save module temp = ambient, poa = 0  (apd 2/24/2012) */
			self.tmodo = ambt2 + 273.15
			self.suno = 0
		return celltemp

	def set_last_values(inout self, Tc: Float64, poa: Float64):
		self.tmodo = Tc + 273.15
		self.suno = poa * self.absorb

										/* Function to determine DC power */
def dcpowr(reftem: Float64, refpwr: Float64, pwrdgr: Float64, tmloss: Float64, poa: Float64, pvt: Float64, iref: Float64) -> Float64:
	"""        /* Modified 8/22/07 to pass non-array variables */
/* This function was converted from a PVFORM version 3.3 subroutine but
	uses reference array power ratings instead of reference array
	efficiencies and array sizes to determine dc power.
	Following discussion is original from PVFORM:
	this routine computes the dcpower from the array given a computed
	cell temperature and poa radiation.  it uses a standard power
	degredation technique in which the array efficiency is assumed
	to decrease at a linear rate as a function of temperature rise.
	in most cases the rate of change of efficiency is about .4%perdeg c.
	The code adjusts the array effic if the insolation
	is less than 125w per m2.  the adjustment was suggested by
	fuentes based on observations of plots of effic vs insol at
	several of snla pv field sites.  when insol is less than 125
	the effic is adjusted down at a rate that is porportional
	to that that is observed in the measured field data.  this
	algorithm assumes that the effic is zero at insol of zero.
	this is not true but is a reasonable assumption for a performance
	model.  the net effect of this improvement ranges from less than
	1% in alb to about 2.2% in caribou.  the effect is to reduce
	the overall performace of a fixed tilt system.  tracking
	systems show no measurable diff in performance with respect to
	this power system adjustment.
	passed variables:
		poa = plane of array irradiances (W per m2) for each hour of day
		pvt = temperature of PV cells (deg C)
		reftem =  reference temperature (deg C)
		refpwr =  reference power (W) at reftem and iref W per m2 irradiance
		pwrdgr =  power degradation due to temperature, decimal fraction
					(si approx. -0.004, negative means efficiency decreases with
					increasing temperature)
		tmloss =  mismatch and line loss, decimal fraction
	returned variables:
		dc = dc power in watts
	local variables :
		dcpwr1 = dc power(W) from array before mismatch losses      """
	var dcpwr1: Float64
	var dc: Float64
	if poa > 125.0:
		dcpwr1 = refpwr * (1.0 + pwrdgr * (pvt - reftem)) * poa / iref
	elif poa > 0.1:
		dcpwr1 = refpwr * (1.0 + pwrdgr * (pvt - reftem)) * 0.008 * poa * poa / iref
	else:
		dcpwr1 = 0.0
	dc = dcpwr1 * (1.0 - tmloss)   /* adjust for mismatch and line loss */
	return dc

def dctoac(pcrate: Float64, efffp: Float64, dc: Float64) -> Float64:
	""" 
/* Revised 8/22/07 to work with single time stamp (non-array) data.
	This function was converted from a PVFORM version 3.3 subroutine
	this routine computes the ac energy from the inverter system.
	it uses a model developed by leeman and menicucci of snla.
	the model is based on efficiency changes of typical pcu systems
	as a function of the load on the system.  these efficiency changes
	were determined through numerous measurements made at snla.
	the model is determined by fitting a curve through a set of pcu
	efficiency measurements ranging from inputs of 10% of full power
	to 100% of full power.  the equation is a 3rd order polynomial.
	between 10% and 0% a linear change is assumed ranging to an efficiency
	of -1.5% at 0% input power.
	passed variables:
		dc = dc power(W)
		pcrate = rated output of inverter in ac watts
		efffp = efficiency of inverter at full power, decimal fraction (such as 0.10)
	local variables :
		dcrtng = equivalent dc rating of pcu
		effrf = efficiency of pcu after adjustment
		percfl = percent of full load the inverter is operating at
		rateff = ratio of eff at full load / ref eff at full load
	returned variable:
		ac = ac power(W)  """
	var dcrtng: Float64
	var effrf: Float64
	var percfl: Float64
	var rateff: Float64
	var ac: Float64
	"""   Compute the ratio of the effic at full load given by the user and
	  the reference effic at full load. this will be used later to compute
	  the pcu effic for the exact conditions specified by the user.  """
	rateff = efffp / 0.91
	"""   The pc rating is an ac rating so convert it to dc by dividing it
	  by the effic at 100% power. """
	dcrtng = pcrate / efffp
	if dc > 0.0:
		"""        Determine the reference efficiency based on the
						percentage of full load at input. """
		percfl = dc / dcrtng
		if percfl <= 1.0:
			"""   if the percent of full power falls in the range of .1 to 1. then
					 use polynomial to estimate effic, else use linear equation. """
			if percfl >= 0.1:
				effrf = 0.774 + (0.663 * percfl) + (-0.952 * percfl * percfl) + (0.426 * percfl * percfl * percfl)
				if effrf > 0.925:
					effrf = 0.925
			else:       /* percent of full power less than 0.1 */
				effrf = (8.46 * percfl) - 0.015
				if effrf < 0.0:
					effrf = 0.0
			/* compute the actual effic of the pc by adjusting according
				to the user input of effic at max power then compute power. */
			effrf = effrf * rateff
			ac = dc * effrf
		else:
			ac = pcrate  /* On an overload condition set power to rated pc power */
	else:         /* dc in equals 0 */
		ac = 0.0
	return ac
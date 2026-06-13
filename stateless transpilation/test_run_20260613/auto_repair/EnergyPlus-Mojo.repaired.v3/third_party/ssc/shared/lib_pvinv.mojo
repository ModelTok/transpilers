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

struct partload_inverter_t:
    var Vdco: Float64    /* Nominal DC voltage inptu (Vdc) */
    var Paco: Float64    /* Maximum AC power rating, upper limit value  (Wac) */
    var Pdco: Float64    /* DC power level at which Paco is achieved (Wdc) */
    var Pntare: Float64  /* AC power consumed by inverter at night as parasitic load (Wac) */
    var Partload: List[Float64] /* Array of partload values (Pdc/Paco) for linear interpolation */
    var Efficiency: List[Float64] /* Array of efficiencies corresponding to partload values */

    def __init__(inout self):
        self.Paco = Float64.nan
        self.Pdco = Float64.nan
        self.Pntare = Float64.nan

    def acpower(
        inout self,
        /* inputs */
        Pdc: Float64,     /* Input power to inverter (Wdc), one per MPPT input on the inverter. Note that with several inverters, this is the power to ONE inverter.*/
        /* outputs */
        Pac: Pointer[Float64],    /* AC output power (Wac) */
        Ppar: Pointer[Float64],   /* AC parasitic power consumption (Wac) */
        Plr: Pointer[Float64],    /* Part load ratio (Pdc_in/Pdc_rated, 0..1) */
        Eff: Pointer[Float64],	    /* Conversion efficiency (0..1) */
        Pcliploss: Pointer[Float64], /* Power loss due to clipping loss (Wac) */
        Pntloss: Pointer[Float64] /* Power loss due to night time tare loss (Wac) */
    ) -> Bool:
        var Pdc_vec = List[Float64]()
        Pdc_vec.append(Pdc)
        return self.acpower(Pdc_vec, Pac, Ppar, Plr, Eff, Pcliploss, Pntloss)

    def acpower(
        inout self,
        /* inputs */
        Pdc: List[Float64],     /* Vector of Input power to inverter (Wdc), one per MPPT input on the inverter. Note that with several inverters, this is the power to ONE inverter.*/
        /* outputs */
        Pac: Pointer[Float64],    /* AC output power (Wac) */
        Ppar: Pointer[Float64],   /* AC parasitic power consumption (Wac) */
        Plr: Pointer[Float64],    /* Part load ratio (Pdc_in/Pdc_rated, 0..1) */
        Eff: Pointer[Float64],	    /* Conversion efficiency (0..1) */
        Pcliploss: Pointer[Float64], /* Power loss due to clipping loss (Wac) */
        Pntloss: Pointer[Float64] /* Power loss due to night time tare loss (Wac) */
    ) -> Bool:
        var Pdc_total: Float64 = 0.0
        for m in range(len(Pdc)):
            Pdc_total += Pdc[m]
        if self.Pdco <= 0.0:
            return False
        var x = 100.0 * Pdc_total / self.Pdco # percentages in partload ratio
        var n = len(self.Partload)
        var ascnd = (self.Partload[n-1] > self.Partload[0]) # check ascending order
        var ndx: Int
        var nu = n
        var nl = 0
        while (nu - nl) > 1:
            ndx = (nu + nl) // 2 # divide by 2
            if (x >= self.Partload[ndx]) == ascnd:
                nl = ndx
            else:
                nu = ndx
        if x == self.Partload[0]:
            ndx = 0
        elif x == self.Partload[n-1]:
            ndx = n-1
        else:
            ndx = nl
        if ndx >= (n-1):
            ndx = n-2
        if ndx < 0:
            ndx = 0
        if x > self.Partload[ndx]:
            Eff[] = self.Efficiency[ndx] + ((self.Efficiency[ndx+1] - self.Efficiency[ndx]) / 
                                            (self.Partload[ndx+1] - self.Partload[ndx])) * (x - self.Partload[ndx])
        else:
            Eff[] = self.Efficiency[ndx]
        if Eff[] < 0.0:
            Eff[] = 0.0
        Eff[] /= 100.0 # user data in percentages
        Pac[] = Eff[] * Pdc_total
        Ppar[] = 0.0
        Pntloss[] = 0.0
        if Pdc_total <= 0.0:
            Pac[] = -self.Pntare
            Ppar[] = self.Pntare
            Pntloss[] = self.Pntare
        Pcliploss[] = 0.0
        var PacNoClip = Pac[]
        if Pac[] > self.Paco:
            Pac[] = self.Paco
            Pcliploss[] = PacNoClip - Pac[]
        Plr[] = Pdc_total / self.Pdco
        return True
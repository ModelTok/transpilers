/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Authors: R.J. Hitchcock and W.L. Carroll
 *           Building Technologies Department
 *           Lawrence Berkeley National Laboratory
 */
/**************************************************************
 * C Language Implementation of DOE2.1d and Superlite 3.0
 * Daylighting Algorithms with new Complex Fenestration System
 * analysis algorithms.
 *
 * The original DOE2 daylighting algorithms and implementation
 * in FORTRAN were developed by F.C. Winkelmann at the
 * Lawrence Berkeley National Laboratory.
 *
 * The original Superlite algorithms and implementation in FORTRAN
 * were developed by Michael Modest and Jong-Jin Kim
 * under contract with Lawrence Berkeley National Laboratory.
 **************************************************************/
/*
NOTICE: The Government is granted for itself and others acting on its behalf
a paid-up, nonexclusive, irrevocable worldwide license in this data to reproduce,
prepare derivative works, and perform publicly and display publicly.
Beginning five (5) years after (date permission to assert copyright was obtained),
subject to two possible five year renewals, the Government is granted for itself
and others acting on its behalf a paid-up, nonexclusive, irrevocable worldwide
license in this data to reproduce, prepare derivative works, distribute copies to
the public, perform publicly and display publicly, and to permit others to do so.
NEITHER THE UNITED STATES NOR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL
LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY
INFORMATION, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE
WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
*/
from BGL import *
from CONST import *
from DBCONST import *
from DEF import *
from NodeMesh2 import *
from WLCSurface import *
from helpers import *
from hemisphiral import *
from btdf import *
from CFSSystem import *
from CFSSurface import *
from DOE2DL import *
from TOOLS import *
from WxTMY2 import *
from ECM import *
from SOL import *
/******************************** subroutine dillum *******************************/
/* Calculates daylight illuminance levels (fc) for combined overcast sky, */
/* clear sky, and clear sun components at each reference point defined in the */
/* REFPT structure within BLDG structure. */
/* Determines electric lighting fractional power required to meet aggregate design */
/* set point illuminance for each zone. */
/* Calculates monthly and annual average hourly fractional electric lighting reductions */
/* due to daylight over the given run period. */
/* Run period is defined in the RUN_DATA structure. */
/* Based on code contained in DOE2.1D DAYCLC subroutine. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine dillum *******************************/
def dillum(
	cloud_fraction: Float64,	/* fraction of sky covered by clouds (0.0=clear 1.0=overcast) */
	bldg_ptr: Pointer[BLDG],			/* building data structure pointer */
	sun_ptr: Pointer[SUN_DATA],		/* pointer to sun data structure */
	run_ptr: Pointer[RUN_DATA],		/* pointer to runtime data structure */
	wx_flag: Int,			/* weather availability flag */
	wxfile_ptr: Pointer[FILE],		/* TMY2 weather file pointer */
	pofdmpfile: Pointer[OStream])	/* ptr to dump file */
-> Int:
{
	var monlength: StaticTuple[MONTHS, Int];	/* number of days in each month array */
	var dayofyr: Int;			/* sequential day of year */
	var dayofweek: Int;			/* sequential day of week (1=Mon to 7=Sun) */
	var sun1_data: SUN1_DATA;	/* sun1 data structure for sun1() subroutine */
	var sun2_data: SUN2_DATA;	/* sun2 data structure for sun2() subroutine */
	var solic: StaticTuple[MONTHS, Float64];	/* extraterrestrial illum for first of each month */
	var chilsk: StaticTuple[HOURS, Float64];	/* clear sky horiz illum sky component */
	var chilsu: StaticTuple[HOURS, Float64];	/* clear sky horiz illum sun component */
	var ohilsk: StaticTuple[HOURS, Float64];	/* overcast sky horiz illum sky component */
	var cdirlw: StaticTuple[HOURS, Float64];	/* luminous efficacy for direct solar radiation from clear sky */
	var cdiflw: StaticTuple[HOURS, Float64];	/* luminous efficacy for diffuse radiation from clear sky */
	var odiflw: StaticTuple[HOURS, Float64];	/* luminous efficacy for diffuse radiation from overcast sky */
	var hisunf: Float64;	/* current hour clear sky horiz illum sun component */
	var chiskf: Float64;	/* current hour clear sky horiz illum sky component */
	var ohiskf: Float64;	/* current hour overcast sky horiz illum sky component */
	var phsun: Float64; var thsun: Float64;		/* sun altitude and azimuth (radians) */
	var phsmin: Float64; var phsmax: Float64; var phsdel: Float64;	/* sun altitude limits and increment */
	var thsmin: Float64; var thsmax: Float64; var thsdel: Float64;	/* sun azimuth limits and increment */
	var phratio: Float64; var thratio: Float64;	/* sun position alt and azm interpolation displacement ratios */
	var iphs: Int; var iths: Int;	/* sun position alt and azm interpolation indexes */
	var imon: Int;	/* month loop index (jan = 0) */
	var iday: Int;	/* day loop index (month begins at iday = 1) */
	var ihr: Int;	/* hour loop index (Midnite to 1AM = 0) */
	var izone: Int; var irp: Int;	/* loop indexes */
	var iday1: Int; var iday2: Int;	/* indexes */
	var anndays: Int; var mondays: Int;	/* accumulators for annual and monthly average calcs */
	var lt_frac: Float64; var lt_reduc: Float64;	/* temp light fraction and reduction vars */
	var iReturnVal: Int = 0;		/* return value holder */
	/* Initialize month lengths array. */
	var iFebDays: Int = 28;
	/* Does wx file contain leap year data? */
	if (0):
		iFebDays = 29;
	init_monlength(monlength, iFebDays);
	/* Set limits of sun position angles. */
	phsmin = sun_ptr[].phsmin;
	thsmin = sun_ptr[].thsmin;
	/* For non-standard number of sun altitudes minimum altitude is passed into dcof(). */
	/* Reset minimum altitude for standard number of sun altitudes. */
	if (sun_ptr[].nphs == NPHS):
		phsmin = 10.;
		if (fabs(bldg_ptr[].lat) >= 48.0): phsmin = 5.;
	/* Maximum altitude and altitude angle increment for sun positions. */
	if (sun_ptr[].nphs == 1):
		phsmax = phsmin;
		phsdel = 0.;
	else:
		phsmax = min(90.0,113.5-fabs(bldg_ptr[].lat));
		phsdel = (phsmax - phsmin) / ((Float64)(sun_ptr[].nphs-1));
	/* For non-standard number of sun azimuths minimum azimuth is passed into dcof(). */
	/* Reset minimum azimuth and azm angle increment for standard number of sun azimuths. */
	if (sun_ptr[].nths == NTHS):
		thsmin = -110.;
		/* minimum solar azimuth for southern hemisphere */
		if (bldg_ptr[].lat < 0.0): thsmin = 70.;
	/* Azimuth angle increment for sun positions. */
	if (sun_ptr[].nths == 1): thsdel = 0.;
	else: thsdel = fabs(2.0 * thsmin) / (sun_ptr[].nths - 1);
	thsmax = thsmin + thsdel * (Float64)(NTHS-1);
	/* Calculate extraterrestrial direct normal solar illuminance (lum/ft2) */
	/* for the first day of each month. */
	dsolic(solic);
	/* Calculate sequential beginning day of year for this run (Jan 01 = 1) */
	dayofyr = 0;
	for imon in range(0, MONTHS):
		if (imon == (run_ptr[].mon_begin -1)):
			dayofyr += run_ptr[].day_begin;
			break;
		dayofyr += monlength[imon];
	/* Decrement dayofyr in anticipation of first Day Loop increment */
	dayofyr -= 1;
	/* Get day of week for first day of run */
	get_day_of_week(&dayofweek,run_ptr);
	/* Decrement dayofweek in anticipation of first Day Loop increment */
	dayofweek -= 1;
	/* Calculate sequential begin and end days of year for all lighting schedules */
	calc_sched_days(bldg_ptr,run_ptr);
	/* Output power reduction factor headings. */
	pofdmpfile[].write("\n");
	/* Init number of hours in year for annual average hourly electric lighting reduction. */
	anndays = 0;
	/* Month Loop */
	for imon in range((run_ptr[].mon_begin-1), run_ptr[].mon_end):
		/* Output month corrected so that Jan=1 to Dec=12. */
		pofdmpfile[].write("Month: " + str(imon+1) + "\n");
		/* Init number of days in month for monthly average hourly electric lighting reduction. */
		mondays = 0;
		/* Calculate beginning and ending days for the day loop. */
		if (imon == (run_ptr[].mon_begin -1)): iday1 = run_ptr[].day_begin;
		else: iday1 = 1;
		if (imon == (run_ptr[].mon_end -1)): iday2 = run_ptr[].day_end;
		else: iday2 = monlength[imon];
		/* Init monthly availability arrays */
		init_avail(chilsk,chilsu,ohilsk,cdirlw,cdiflw,odiflw);
		/* Day Loop */
		for iday in range(iday1, iday2+1):
			/* Increment day of year */
			dayofyr += 1;
			/* Increment day of week */
			dayofweek += 1;
			if (dayofweek > 7): dayofweek = 1;
			/* NOTE: For applications without solar data only do calcs for one day each */
			/* month but, continue to loop through days for proper increment of dayofyr */
			/* and dayofweek */
			if ((wx_flag == 0) and (iday > iday1)): continue;
			/* Output day. */
			pofdmpfile[].write("Day: " + str(iday) + " DayofWeek " + str(dayofweek) + "\n");
			/* Count number of days simulated in month for monthly average */
			/* hourly electric lighting reduction. */
			mondays += 1;
			/* Get lighting schedule index for each zone for current day */
            var iGetSchedRetVal: Int;
			if ((iGetSchedRetVal = get_sched(bldg_ptr,dayofyr,dayofweek)) < 0):
                if (iGetSchedRetVal != -10):
					pofdmpfile[].write("ERROR: DElight Zone Lighting Schedule not found for at least one Zone\n");
					return(-1);
                else:
                    iReturnVal = -10;
            }
			/* Get daily solar quantities */
			sun1(dayofyr,&sun1_data,bldg_ptr);
			/* Hour Loop */
			for ihr in range(0, HOURS):
				/* Output dmpfile hour. */
				pofdmpfile[].write("Hour: " + str(ihr+1) + "\n");
				/* Get hourly solar quantities */
                var iSun2RetVal: Int;
				if ((iSun2RetVal = sun2(imon,iday,ihr,&sun1_data,&sun2_data,bldg_ptr,wx_flag,wxfile_ptr)) < 0):
                    if (iSun2RetVal != -10):
					    pofdmpfile[].write("ERROR: DElight Bad return from sun2(), return from dillum()\n");
					    return(-1);
                    else:
                        iReturnVal = -10;
                }
                /* Is sun not up? */
				if (sun2_data.isunup == 0):
					/* Output 100% power required for current hour (1 to 24) */
					/* For each zone */
					for izone in range(0, bldg_ptr[].nzones):
						/* Output to dump file */
						pofdmpfile[].write("Zone [" + bldg_ptr[].zone[izone][].name + " PRF = " + str(1.0) + " Percent Savings = " + str(0.0) + "\n");
					continue;
				/* Calc solar alt and azm and interpolation ratios and bound indexes */
				calc_sun(&phsun,&thsun,&phratio,&thratio,&iphs,&iths,&sun2_data,phsmin,phsmax,phsdel,thsmin,thsmax,thsdel,bldg_ptr);
				/* Output sun position. */
				pofdmpfile[].write("Sun Altitude: " + str(phsun/DTOR) + " Sun Azimuth: " + str(thsun/DTOR) + "\n");
				/* NOTE: If weather data is not available, set cloudiness fraction equal to */
				/* value passed into dillum(); */
				if (wx_flag == 0): sun2_data.cldamt = (Int)(cloud_fraction * 10.);
				/* Calc hourly values for each hour sun is up for first day of each month */
				if (iday == iday1):
					/* Calc exterior daylight availability factors */
                    var iDavailRetVal: Int;
					if ((iDavailRetVal = davail(&chilsk[ihr],&chilsu[ihr],&ohilsk[ihr],&cdirlw[ihr],&cdiflw[ihr],&odiflw[ihr],imon,phsun,thsun,solic,bldg_ptr,pofdmpfile)) < 0):
                        if (iDavailRetVal != -10):
					        pofdmpfile[].write("ERROR: DElight Bad return from davail(), return from dillum()\n");
					        return(-1);
                        else:
                            iReturnVal = -10;
                    }
				/* Calc current hour illum on an unobstructed exterior horizontal surface */
                var iDextilRetVal: Int;
				if ((iDextilRetVal = dextil(&hisunf,&chiskf,&ohiskf,wx_flag,chilsu[ihr],chilsk[ihr],ohilsk[ihr],phsun,solic,imon,bldg_ptr,&sun2_data,pofdmpfile)) < 0):
                    if (iDextilRetVal != -10):
                        pofdmpfile[].write("\n");
					    pofdmpfile[].write("ERROR: DElight Bad return from dextil(), return from dillum()\n");
					    return(-1);
                    else:
                        iReturnVal = -10;
                }
				/* Zone Loop */
				for izone in range(0, bldg_ptr[].nzones):
					/* Find daylight illuminance level */
					/* at each ref pt in current zone. */
					dintil(bldg_ptr[].zone[izone],imon,ihr,hisunf,chiskf,ohiskf,iphs,iths,phratio,thratio);
					/* Calculate lighting power reduction factor due to daylighting. */
					/* 	PRF = 1.0 => full power required */
					/* 	PRF = 0.0 => no power required */
                    var iDltsysRetVal: Int;
				    if ((iDltsysRetVal = dltsys(bldg_ptr[].zone[izone],&sun2_data,pofdmpfile)) < 0):
                        if (iDltsysRetVal != -10):
					        pofdmpfile[].write("ERROR: DElight Bad return from dltsys(), return from dillum()\n");
					        return(-1);
                        else:
                            iReturnVal = -10;
                    }
					/* Calculate hourly fractional electric lighting energy requirement, */
					/* accounting for electric lighting schedule. */
					lt_frac = bldg_ptr[].zone[izone][].frac_power * bldg_ptr[].zone[izone][].ltsch[bldg_ptr[].zone[izone][].ltsch_id][].frac[ihr];
					/* Calculate hourly fractional electric lighting energy reduction. */
					lt_reduc = 1.0 - lt_frac;
					/* Output power reduction factor and electric lighting savings for this zone. */
					pofdmpfile[].write("Zone [" + bldg_ptr[].zone[izone][].name + " PRF = " + str(bldg_ptr[].zone[izone][].frac_power) + " Percent Savings = " + str((lt_reduc*100.0)) + "\n");
					/* Accumulate monthly hourly fractional electric lighting energy reduction. */
					bldg_ptr[].zone[izone][].lt_reduc[imon][ihr] += lt_reduc;
				}	/* end of Zone Loop */
			}	/* end of Hour Loop */
		}	/* end of Day Loop */
		/* Calculate monthly average hourly fractional electric lighting energy reduction, */
		/* and daylight illuminances at each ref pt. */
		for izone in range(0, bldg_ptr[].nzones):
			for ihr in range(0, HOURS):
				/* Accumulate annual hourly fractional electric lighting energy reduction. */
				bldg_ptr[].zone[izone][].annual_reduc[ihr] += bldg_ptr[].zone[izone][].lt_reduc[imon][ihr];
				if (mondays != 0): bldg_ptr[].zone[izone][].lt_reduc[imon][ihr] /= (Float64)mondays;
				for irp in range(0, bldg_ptr[].zone[izone][].nrefpts):
					if (mondays != 0):
						bldg_ptr[].zone[izone][].ref_pt[irp][].day_illum[imon][ihr] /= (Float64)mondays;
		/* Accumulate annual number of hours simulated for annual average reduction calcs. */
		anndays += mondays;
	}	/* end of Month Loop */
	/* Calculate annual average hourly fractional electric lighting energy reduction. */
	for izone in range(0, bldg_ptr[].nzones):
		for ihr in range(0, HOURS):
			if (anndays != 0): bldg_ptr[].zone[izone][].annual_reduc[ihr] /= (Float64)anndays;
	return(iReturnVal);
}
/******************************** subroutine davail *******************************/
/* Calculates availability of natural light for daylighting simulation. */
/* Determines sun and sky illuminance on an exterior horizontal surface for clear */
/* and overcast CIE skies (lumens/ft2). */
/* Called once each hour that sun is up for one day per month. */
/* Also determines lumens/watt conversion factors for direct and diffuse solar */
/* radiation, based on CIE conventions, from CIE clear sky (cdirlw,cdiflw), */
/* and for diffuse radiation from CIE overcast sky (odiflw). */
/* 12/17/98 mod now calls dlumef() for use when there is NOT wx data. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine davail *******************************/
def davail(
	chilsk_ptr: Pointer[Float64],	/* clear sky horiz illum sky component */
	chilsu_ptr: Pointer[Float64],	/* clear sky horiz illum sun component */
	ohilsk_ptr: Pointer[Float64],	/* overcast sky horiz illum sky component */
	cdirlw_ptr: Pointer[Float64],	/* luminous efficacy for direct solar radiation from clear sky */
	cdiflw_ptr: Pointer[Float64],	/* luminous efficacy for diffuse radiation from clear sky */
	odiflw_ptr: Pointer[Float64],	/* luminous efficacy for diffuse radiation from overcast sky */
	imon: Int,			/* current month */
	phsun: Float64,		/* sun altitude */
	thsun: Float64,		/* sun azimuth */
	solic: StaticTuple[MONTHS, Float64],/* extraterrestrial illum for first day of each month */
	bldg_ptr: Pointer[BLDG],		/* building data structure pointer */
	pofdmpfile: Pointer[OStream])	/* ptr to dump file */
-> Int:
{
	var zenl: Float64;	/* zenith luminance for given month and sun altitude (Kcd/m2) */
	var tfac: Float64;	/* turbidity factor for given month and sun altitude */
    var iReturnVal: Int = 0;
	/* Get clear sky zenith luminance, moisture, and turbidity coef for current month. */
	dzenlm(&zenl,&tfac,imon,bldg_ptr,phsun);
	/* Get exterior horiz illum from sky and sun for clear and overcast sky.  */
    var iDhillRetVal: Int;
	if ((iDhillRetVal = dhill(chilsk_ptr,chilsu_ptr,ohilsk_ptr,bldg_ptr,imon,phsun,thsun,zenl,tfac,solic,pofdmpfile)) < 0):
        if (iDhillRetVal != -10):
			pofdmpfile[].write("ERROR: DElight Bad return from dhill(), return from davail()\n");
			return(-1);
        else:
            iReturnVal = -10;
    }
    /* Get lumens/watt factors based on CIE conventions. */
	dlumef(cdirlw_ptr,cdiflw_ptr,odiflw_ptr,imon,phsun,bldg_ptr);
	return(iReturnVal);
}
/******************************** subroutine dlumef *******************************/
/* Called by davail(). */
/* Calculates luminous efficacy (lumens/watt) of direct, clear sky diffuse, */
/* and overcast sky diffuse solar radiation. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine dlumef *******************************/
def dlumef(
	cdirlw_ptr: Pointer[Float64],	/* luminous efficacy for direct solar radiation from clear sky */
	cdiflw_ptr: Pointer[Float64],	/* luminous efficacy for diffuse radiation from clear sky */
	odiflw_ptr: Pointer[Float64],	/* luminous efficacy for diffuse radiation from overcast sky */
	imon: Int,			/* current month */
	phsun: Float64,		/* sun altitude */
	bldg_ptr: Pointer[BLDG])		/* building data structure pointer */
-> Int:
{
	var beta: Float64; var w: Float64; var bc: Float64;	/* atmos turbidity and moisture coefs for given month */
	/* lumens/watt for direct solar radiation, clear sky (fit to tabulated values */
	/* of direct normal luminous efficacy vs solar altitude, turbidity factor, */
	/* moisture -- Aydinli, The Availability fo Solar Radiation and Daylight, */
	/* Table 4, Oct. 1981). */
	/* Set turbidity coef and atmos moisture for specified month. */
	beta = bldg_ptr[].atmtur[imon];
	w = bldg_ptr[].atmmoi[imon] * 2.54;
	/* Restrict beta to range of Aydinli values (0 to 0.2) */
	bc = min(0.2,beta);
	cdirlw_ptr[] = (99.0 + 4.7 * w - 52.4 * bc) * (1.0 - exp((24.0 * bc - 8.0) * phsun));
	/* lumens/watt for diffuse radiation from clear sky (from Aydinli) */
	cdiflw_ptr[] = 125.4;
	/* lumens/watt for diffuse radiation from overcast sky (from Dogniaux and Lemoine) */
	odiflw_ptr[] = 110.;
	return(0);
}
/******************************** subroutine dplumef *******************************/
/* Called by dextil() if weather data is available. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine dplumef *******************************/
def dplumef(
	pdirlw_ptr: Pointer[Float64],	/* Perez luminous efficacy for direct solar radiation from clear sky */
	pdiflw_ptr: Pointer[Float64],	/* Perez luminous efficacy for diffuse radiation from sky */
	bscc: Float64,		/* diffuse horiz radiation from measured data (Btu/ft2-h) */
	rdncc: Float64,		/* measured direct solar radiation (Btu/ft2-h) */
	phsun: Float64,		/* sun altitude (radians) */
	solic: StaticTuple[MONTHS, Float64],/* extraterrestrial illum for first day of each month */
	imon: Int,			/* current month */
	sun2_ptr: Pointer[SUN2_DATA],/* pointer to sun2 data structure */
	bldg_ptr: Pointer[BLDG],		/* building data structure pointer */
	pofdmpfile: Pointer[OStream])/* dump file */
-> Int:
{
	var apdiflw: StaticTuple[8, Float64] = {97.24, 107.22, 104.97, 102.39, 100.71, 106.42, 141.88, 152.23};
	var bpdiflw: StaticTuple[8, Float64] = {-0.46, 1.15,   2.96,   5.59,   5.94,   3.83,   1.90,   0.35};
	var cpdiflw: StaticTuple[8, Float64] = {12.00, 0.59,   -5.53,  -13.95, -22.75, -36.15, -53.24, -45.27};
	var dpdiflw: StaticTuple[8, Float64] = {-8.91, -3.95,  -8.77,  -13.90, -23.74, -28.83, -14.03, -7.98};
	var apdirlw: StaticTuple[8, Float64] = {57.20, 98.99,  109.83, 110.34, 106.36, 107.19, 105.75, 101.18};
	var bpdirlw: StaticTuple[8, Float64] = {-4.55, -3.46,  -4.90,  -5.84,  -3.97,  -1.25,  0.77,   1.58};
	var cpdirlw: StaticTuple[8, Float64] = {-2.98, -1.21,  -1.71,  -1.99,  -1.75,  -1.51,  -1.26,  -1.10};
	var dpdirlw: StaticTuple[8, Float64] = {117.12,12.38,  -8.81,  -4.56,  -6.16,  -26.73, -34.44, -8.29};
	var zenith_angle: Float64 = PIOVR2 - phsun;
	var z3k: Float64 = 1.041 * zenith_angle * zenith_angle * zenith_angle;
	var eps: Float64 = ((bscc + rdncc) / (bscc + 0.0001) + z3k) / (1.0 + z3k);
	var phsun_deg: Float64 = phsun / DTOR;
	var lop: Float64 = phsun_deg + 3.885;
	var powlop: Float64;
	if (lop < 0.0):
		pofdmpfile[].write("ERROR: DElight Invalid sun altitude (" + str(phsun_deg) + " passed to dplumef()\n");
		return(-1);
	else: powlop = pow(lop,1.253);
	var sphsun: Float64 = sin(phsun);
	var air_mass: Float64 = (1.0 - 0.1 * bldg_ptr[].alt / 3281.0) / (sphsun + 0.15 / powlop);
	var del: Float64 = (bscc * air_mass / solic[imon]) * 27.463;
	var ieps: Int;
	if (eps <= 1.065): ieps = 0;
	else if ((eps > 1.065) and (eps <= 1.23)): ieps = 1;
	else if ((eps > 1.23) and (eps <= 1.5)): ieps = 2;
	else if ((eps > 1.5) and (eps <= 1.95)): ieps = 3;
	else if ((eps > 1.95) and (eps <= 2.8)): ieps = 4;
	else if ((eps > 2.8) and (eps <= 4.5)): ieps = 5;
	else if ((eps > 4.5) and (eps <= 6.2)): ieps = 6;
	else: ieps = 7;
	var wch: Float64 = exp(0.0389 * (sun2_ptr[].dewpt - 32.0) - 0.075);
	if (del <= 0.0): pdiflw_ptr[] = 0.0;
	else: pdiflw_ptr[] = apdiflw[ieps] + bpdiflw[ieps]*wch + cpdiflw[ieps]*cos(zenith_angle) + dpdiflw[ieps]*log(del);
	if (del <= 0.0): pdirlw_ptr[] = 0.0;
	else: pdirlw_ptr[] = max(0.0,(apdirlw[ieps] + bpdirlw[ieps]*wch + cpdirlw[ieps]*exp(5.73*zenith_angle-5.0) + dpdirlw[ieps]*del));
	return(0);
}
/****************************** subroutine init_avail *****************************/
/* Initializes monthly availability arrays. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine init_avail *****************************/
def init_avail(
	chilsk: StaticTuple[HOURS, Float64],	/* clear sky horiz illum sky component */
	chilsu: StaticTuple[HOURS, Float64],	/* clear sky horiz illum sun component */
	ohilsk: StaticTuple[HOURS, Float64],	/* overcast sky horiz illum sky component */
	cdirlw: StaticTuple[HOURS, Float64],	/* luminous efficacy for direct solar radiation from clear sky */
	cdiflw: StaticTuple[HOURS, Float64],	/* luminous efficacy for diffuse radiation from clear sky */
	odiflw: StaticTuple[HOURS, Float64])	/* luminous efficacy for diffuse radiation from overcast sky */
-> Int:
{
	var ihr: Int;	/* hour index */
	for ihr in range(0, HOURS):
		chilsk[ihr] = 0.;
		chilsu[ihr] = 0.;
		ohilsk[ihr] = 0.;
		cdirlw[ihr] = 0.;
		cdiflw[ihr] = 0.;
		odiflw[ihr] = 0.;
	return(0);
}
/******************************** subroutine dextil *******************************/
/* Calculates current hour clear and overcast illuminance on an unobstructed */
/* horizontal surface (lumens/ft2). */
/* These illuminances are calculated from measured solar data if available */
/* from a weather file. */
/* Otherwise, illuminances are taken from davail(). */
/* 12/17/98 mods to incorporate Perez model for determining luminous efficacies */
/* when hourly solar data (irradiances) and dewpoint temp are available. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine dextil *******************************/
def dextil(
	hisunf_ptr: Pointer[Float64],	/* current hour clear sky horiz illum sun component */
	chiskf_ptr: Pointer[Float64],	/* current hour clear sky horiz illum sky component */
	ohiskf_ptr: Pointer[Float64],	/* current hour overcast sky horiz illum sky component */
	wx_flag: Int,	/* weather data availability flag (1=avail) */
	chilsu: Float64,	/* current hour clear sky horiz illum sun component from davail() */
	chilsk: Float64,	/* current hour clear sky horiz illum sky component from davail() */
	ohilsk: Float64,	/* current hour overcast sky horiz illum sky component from davail() */
	phsun: Float64,		/* sun altitude (radians) */
	solic: StaticTuple[MONTHS, Float64],/* extraterrestrial illum for first day of each month */
	imon: Int,			/* current month */
	bldg_ptr: Pointer[BLDG],		/* building data structure pointer */
	sun2_ptr: Pointer[SUN2_DATA],/* pointer to sun2 data structure */
	pofdmpfile: Pointer[OStream])/* dump file */
-> Int:
{
	var etacld: Float64;	/* cloudiness factor */
	var cr: Float64;		/* fractional cloud amount */
	var rdncc: Float64;	/* measured direct solar radiation */
	var bscc: Float64;		/* diffuse horiz radiation from measured data */
	var sdirh: Float64; var sdifh: Float64;	/* direct and diffuse horiz illum */
	var iReturnVal: Int = 0;	// return value holder
	/* Cloudiness factor, etacld, which is used to interpolate between */
	/* clear and overcast conditions. */
	cr = sun2_ptr[].cldamt / 10.;
	if (cr > 0.2): etacld = 1.0 - (cr - 0.2) * 1.25;
	else: etacld = 1.;
	/* Calculate illums when no wx data is available. */
	if (wx_flag == 0):
		/* Direct horizontal illuminance */
		hisunf_ptr[] = (1.0 - cr) * chilsu;
		/* Normalize clear and overcast portions of diffuse horiz illum. */
		chiskf_ptr[] = etacld * chilsk;
		ohiskf_ptr[] = (1.0 - etacld) * ohilsk;
	else:	// Calculate illums from measured solar data if available.
		/* Calc intermediate vars RDNCC and BSCC from sun2_data */
		rdncc = sun2_ptr[].dirsol;
		bscc = sun2_ptr[].solrad - sun2_ptr[].dirsol * sun2_ptr[].raycos[2];
		if (bscc < 0.0): bscc = 0.;
		/* Calc direct and diffuse horiz illum from measured solar data (0.293 converts Btu/ft2-h to W/ft2) */
		sdirh = rdncc * sun2_ptr[].raycos[2] * 0.293;
		sdifh = bscc * 0.293;
		var pdirlw: Float64;	/* Perez luminous efficacy for direct solar radiation from clear sky */
		var pdiflw: Float64;	/* Perez luminous efficacy for diffuse radiation from sky */
        var iDplumefRetVal: Int;
	    if ((iDplumefRetVal = dplumef(&pdiflw, &pdirlw, bscc, rdncc, phsun, solic, imon, sun2_ptr, bldg_ptr, pofdmpfile)) < 0):
            if (iDplumefRetVal != -10):
			    pofdmpfile[].write("ERROR: DElight Bad return from dplumef(), return from dextil()\n");
			    return(-1);
            else:
                iReturnVal = -10;
        }
		chiskf_ptr[] = sdifh * etacld * pdiflw;
		ohiskf_ptr[] = sdifh * (1.0 - etacld) * pdiflw;
		hisunf_ptr[] = sdirh * pdirlw;
	return(iReturnVal);
}
/******************************** subroutine dintil *******************************/
/* Calculates hourly daylight illuminance at each reference point in a daylit zone. */
/* Accumulates monthly and hourly total daylight illuminance for later monthly */
/* average calculations. */
/* Assumes no window shades. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine dintil *******************************/
def dintil(
	zone_ptr: Pointer[ZONE],	/* bldg->zone data structure pointer */
	imon: Int,		/* current month */
	ihr: Int,		/* current hour */
	hisunf: Float64,	/* current hour clear sky horiz illum sun component */
	chiskf: Float64,	/* current hour clear sky horiz illum sky component */
	ohiskf: Float64,	/* current hour overcast sky horiz illum sky component */
	iphs: Int,		/* sun altitude interpolation lower bound index */
	iths: Int,		/* sun azimuth interpolation lower bound index */
	phratio: Float64,	/* sun altitude interpolation displacement ratio */
	thratio: Float64)	/* sun azimuth interpolation displacement ratio */
-> Int:
{
	var irp: Int;				/* ref pt loop index */
	var ip_lo: Int; var ip_hi: Int;		/* sun altitude low and high interpolation indexes */
	var it_lo: Int; var it_hi: Int;		/* sun azimuth low and high interpolation indexes */
	var lower: Float64; var upper: Float64;		/* temp interpolation lower and upper values */
	var skyfac: Float64; var sunfac: Float64;	/* clear sky interpolated factors */
	/* Set low and high alt and azm indexes */
	ip_lo = iphs;
	if (iphs != (NPHS-1)): ip_hi = iphs + 1;
	else: ip_hi = iphs;
	it_lo = iths;
	if (iths != (NTHS-1)): it_hi = iths + 1;
	else: it_hi = iths;
	for irp in range(0, zone_ptr[].nrefpts):
		/* Interpolate clear sky daylight factors */
		upper = (zone_ptr[].ref_pt[irp][].dfsky[ip_hi][it_hi] - zone_ptr[].ref_pt[irp][].dfsky[ip_hi][it_lo]) * thratio + zone_ptr[].ref_pt[irp][].dfsky[ip_hi][it_lo];
		lower = (zone_ptr[].ref_pt[irp][].dfsky[ip_lo][it_hi] - zone_ptr[].ref_pt[irp][].dfsky[ip_lo][it_lo]) * thratio + zone_ptr[].ref_pt[irp][].dfsky[ip_lo][it_lo];
		skyfac = (upper - lower) * phratio + lower;
		upper = (zone_ptr[].ref_pt[irp][].dfsun[ip_hi][it_hi] - zone_ptr[].ref_pt[irp][].dfsun[ip_hi][it_lo]) * thratio + zone_ptr[].ref_pt[irp][].dfsun[ip_hi][it_lo];
		lower = (zone_ptr[].ref_pt[irp][].dfsun[ip_lo][it_hi] - zone_ptr[].ref_pt[irp][].dfsun[ip_lo][it_lo]) * thratio + zone_ptr[].ref_pt[irp][].dfsun[ip_lo][it_lo];
		sunfac = (upper - lower) * phratio + lower;
		/* Multiply daylight factors by appropriate exterior horizontal illuminance */
		zone_ptr[].ref_pt[irp][].daylight = sunfac * hisunf + skyfac * chiskf + zone_ptr[].ref_pt[irp][].dfskyo * ohiskf;
		/* Accumulate daylight illuminance totals for later monthly avg calcs */
		zone_ptr[].ref_pt[irp][].day_illum[imon][ihr] += zone_ptr[].ref_pt[irp][].daylight;
	return(0);
}
/******************************** subroutine calc_sun *******************************/
/* Calculates hourly solar altitude and azimuth. */
/* Also, calculates displacement ratios and boundary indexes for use in daylight */
/* factor interpolation. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine calc_sun *******************************/
def calc_sun(
	phsun_ptr: Pointer[Float64],	/* sun position altitude */
	thsun_ptr: Pointer[Float64],	/* sun position azimuth */
	phratio_ptr: Pointer[Float64],	/* sun position altitude interpolation displacement ratio */
	thratio_ptr: Pointer[Float64],	/* sun position azimuth interpolation displacement ratio */
	iphs_ptr: Pointer[Int],		/* sun position altitude interpolation index */
	iths_ptr: Pointer[Int],		/* sun position azimuth interpolation index */
	sun2_ptr: Pointer[SUN2_DATA],	/* pointer to sun2 data structure */
	phsmin: Float64,		/* minimum sun altitude used in dcof() */
	phsmax: Float64,		/* maximum sun altitude used in dcof() */
	phsdel: Float64,		/* sun altitude increment used in dcof() */
	thsmin: Float64,		/* minimum sun azimuth used in dcof() */
	thsmax: Float64,		/* maximum sun azimuth used in dcof() */
	thsdel: Float64,		/* sun azimuth increment used in dcof() */
	bldg_ptr: Pointer[BLDG])		/* building data structure pointer */
-> Int:
{
	var phsund: Float64; var thsund: Float64;	/* sun alt and azm (degrees) */
	var phs: Float64; var ths: Float64;			/* sun index vars */
	/* Calc sun alt and azm */
	phsun_ptr[] = 1.5708 - acos(sun2_ptr[].raycos[2]);
	phsund = phsun_ptr[] / DTOR;
	thsund = atan2(sun2_ptr[].raycos[1],sun2_ptr[].raycos[0]) / DTOR;
	/* Convert thsund to coord sys in which S=0 and E=90 */
	thsund += 90.0 - bldg_ptr[].azm / DTOR;
	/* Restrict thsund to -180 to 180 interval */
	if (thsund > -180.0): thsund += 360.;
	if (thsund > 180.0): thsund -= 360.0 * (1.0 + floor(thsund/540.0));
	thsun_ptr[] = thsund * DTOR;
	/* Calc alt and azm interpolation indexes and displacement ratios */
	/* Restrict alt and azm to dcof() bounds */
	if (phsund < phsmin): phsund = phsmin;
	if (phsund > phsmax): phsund = phsmax;
	if (thsund < thsmin): thsund = thsmin;
	if (thsund > thsmax): thsund = thsmax;
	/* alt and azm lower interpolation indexes */
	phs = (phsund - phsmin) / phsdel;
	ths = (thsund - thsmin) / thsdel;
	iphs_ptr[] = (Int)floor(phs);
	iths_ptr[] = (Int)floor(ths);
	/* alt and azm interpolation displacement ratios */
	phratio_ptr[] = phs - (Float64)(iphs_ptr[]);
	thratio_ptr[] = ths - (Float64)(iths_ptr[]);
	return(0);
}
/******************************** subroutine dltsys *******************************/
/* Calculates total zonal lighting power reduction factor due to daylighting for */
/* different lighting control systems. */
/* Power reduction factor is the fraction of full power that the lighting system */
/* must be on to provide set point illumination over entire zone. */
/*	1.0 = max lighting input power required */
/*	0.0 = no lighting input power required */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine dltsys *******************************/
def dltsys(
	zone_ptr: Pointer[ZONE],			/* bldg->zone data structure pointer */
	sun2_ptr: Pointer[SUN2_DATA],	/* pointer to sun2 data structure */
	pofdmpfile: Pointer[OStream])	/* dump file */
-> Int:
{
	var irp: Int; var istep: Int;		/* loop indexes */
	var zftot: Float64;		/* total zone fraction */
	var fl: Float64;			/* temp ref pt fractional light var */
	var fp: Float64;			/* temp ref pt fractional power var */
	var step_size: Float64;	/* step size for stepped control system */
	var xran: Float64;			/* random number generated by ran0() */
	var idum: Int;			/* seed for ran0() */
    var iReturnVal: Int = 0;
	/* Init power reduction factor and total zone fraction */
	zone_ptr[].frac_power = 0.;
	zftot = 0.;
	/* Init random number generator sequence by passing it a negative value for seed */
	idum = -1;
	xran = ran0(&idum);
	/* Calc step size for stepped control system */
	if (zone_ptr[].lt_ctrl_steps != 0): step_size = 1.0 / (Float64)(zone_ptr[].lt_ctrl_steps);
	else: step_size = 1.;
	/* Loop over reference points */
	for irp in range(0, zone_ptr[].nrefpts):
		/* Output reference point daylight illuminance (lux). */
		pofdmpfile[].write(str(zone_ptr[].ref_pt[irp][].daylight*10.763915) + "\n");
		/* If this reference point does not control a lighting system then skip it */
		if (zone_ptr[].ref_pt[irp][].lt_ctrl_type == 0): continue;
		/* If this reference point does not control some fraction of a lighting system then skip it */
		if (zone_ptr[].ref_pt[irp][].zone_frac <= 0.0): continue;
		/* If this reference point has a 0 or negative lighting set point then skip it */
		if (zone_ptr[].ref_pt[irp][].lt_set_pt <= 0.0): continue;
		/* accumulate total zone fraction */
		zftot += zone_ptr[].ref_pt[irp][].zone_frac;
		/* Fractional light output required to meet setpoint */
        if (zone_ptr[].ref_pt[irp][].daylight > zone_ptr[].ref_pt[irp][].lt_set_pt):
            fl = 0.;
        else:
            fl = (zone_ptr[].ref_pt[irp][].lt_set_pt - zone_ptr[].ref_pt[irp][].daylight) / zone_ptr[].ref_pt[irp][].lt_set_pt;
        }
		/* Fractional input power required to meet setpoint */
		/* Continuously dimmable system with linear power curve */
		if ((zone_ptr[].ref_pt[irp][].lt_ctrl_type == 1) or (zone_ptr[].ref_pt[irp][].lt_ctrl_type == 3)):
			fp = 1.;
            if (fl <= zone_ptr[].min_light):
                fp = zone_ptr[].min_power;
                if ((zone_ptr[].ref_pt[irp][].lt_ctrl_type == 3) and (fl < zone_ptr[].min_light)):
                    fp = 0.0;
                }
			if ((fl > zone_ptr[].min_light) and (fl < 1.0)): fp = (fl + (1.0 - fl) * zone_ptr[].min_power - zone_ptr[].min_light) / (1.0 - zone_ptr[].min_light);
		}
		/* Stepped system */
		else if (zone_ptr[].ref_pt[irp][].lt_ctrl_type == 2):
			fp = 0.;
			if (zone_ptr[].ref_pt[irp][].daylight < zone_ptr[].ref_pt[irp][].lt_set_pt):
				for istep in range(1, zone_ptr[].lt_ctrl_steps+1):
					fp = istep * step_size;
					if (fp >= fl): break;
			if (zone_ptr[].ref_pt[irp][].daylight == 0.0): fp = 1.;
			/* Manual operation */
			if (zone_ptr[].lt_ctrl_prob < 1.0):
				/* Occupant sets lights one level too high a fraction of the time */
				/* equal to 1.0 - lt_ctrl_prob. */
				xran = ran0(&idum);
				if (xran >= zone_ptr[].lt_ctrl_prob):
					if (fp < 1.0): fp += step_size;
		}
		/* Unknown system */
		else:
			pofdmpfile[].write("WARNING: DElight Unknown light dimming system type specified for reference point " + zone_ptr[].ref_pt[irp][].name + "\n");
			pofdmpfile[].write("WARNING: Dimming will be ignored at this reference point.\n");
            iReturnVal = -10;
			fp = 1.;
		}
		/* Correct for fraction of hour that sun is down */
		fp = fp * sun2_ptr[].fsunup + (1.0 - sun2_ptr[].fsunup);
		/* Store this individual ref pt power reduction factor */
		zone_ptr[].ref_pt[irp][].frac_power = fp;
		/* Accumulate net lighting power reduction factor for entire zone */
		zone_ptr[].frac_power += fp * zone_ptr[].ref_pt[irp][].zone_frac;
	}
	/* Correct for fraction of zone (1-zftot) not controlled by the ref pts. */
	/* For this fraction (which is usually zero), the lighting is unaffected */
	/* and the power reduction factor is therefore 1.0. */
	zone_ptr[].frac_power += 1.0 - zftot;
	return(iReturnVal);
}
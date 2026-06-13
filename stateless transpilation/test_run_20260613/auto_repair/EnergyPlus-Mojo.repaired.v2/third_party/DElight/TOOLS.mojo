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
/****************************** subroutine POLYF *****************************/
/****************************************************************************/
/* AUTHOR         Fred Winkelmann */
/* DATE WRITTEN   February 1999 */
/* DATE MODIFIED  October 1999, FW: change to 6th order polynomial over */
/*					entire incidence angle range */
/****************************** subroutine POLYF *****************************/
def POLYF(
	dCosI: F64,		/* cosine of the angle of incidence */
	EPCoef: F64[6])	/* EnergyPlus coefs of angular transmission */
) -> F64:
{
	var transmittance: F64;	// transmittance at angle of incidence
	if dCosI < 0.0 or dCosI > 1.0:
	  transmittance = 0.0;
	else:
	  transmittance = dCosI*(EPCoef[0]+dCosI*(EPCoef[1]+dCosI*(EPCoef[2]+dCosI*(EPCoef[3]+dCosI*(EPCoef[4]+dCosI*EPCoef[5])))));
	return transmittance;
}
/****************************** subroutine lib_index *****************************/
/* Searches library of components for the specified component name. */
/* Returns index of located component. */
/* Returns value of -1 if no matching component was located. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine lib_index *****************************/
def lib_index(
	lib_ptr: LIB*,						/* pointer to library */
	component: String,	/* library component category */
	uname: String)
-> I32:
{
	var ii: I32;
	if component == "glass":
		for ii in range(MAX_LIB_COMPS):
			if lib_ptr.glass[ii] != None:
				if uname == lib_ptr.glass[ii].name:
					return ii;
	else if component == "wshade":
		for ii in range(MAX_LIB_COMPS):
			if lib_ptr.wshade[ii] != None:
				if uname == lib_ptr.wshade[ii].name:
					return ii;
	return -1;
}
/****************************** subroutine free_bldg *****************************/
/* Frees malloced memory used in bldg data structure. */
/* RJH 7/25/03 - malloc/free changed to new/delete */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine free_bldg *****************************/
def free_bldg(
	bldg_ptr: BLDG*)	/* pointer to building data */
-> I32:
{
	var izone: I32, isurf: I32, iwndo: I32, irp: I32, ibshd: I32, iltsch: I32, izs: I32;	/* loop indexes */
	for izone in range(MAX_BLDG_ZONES):
		if bldg_ptr.zone[izone] == None: continue;
		for iltsch in range(MAX_LT_SCHEDS):
			if bldg_ptr.zone[izone].ltsch[iltsch] == None: continue;
			delete(bldg_ptr.zone[izone].ltsch[iltsch]);
			bldg_ptr.zone[izone].ltsch[iltsch] = None;
		for isurf in range(MAX_ZONE_SURFS):
			if bldg_ptr.zone[izone].surf[isurf] == None: continue;
			for iwndo in range(MAX_SURF_WNDOS):
				if bldg_ptr.zone[izone].surf[isurf].wndo[iwndo] == None: continue;
				delete(bldg_ptr.zone[izone].surf[isurf].wndo[iwndo]);
				bldg_ptr.zone[izone].surf[isurf].wndo[iwndo] = None;
			delete(bldg_ptr.zone[izone].surf[isurf]);
			bldg_ptr.zone[izone].surf[isurf] = None;
		for izs in range(MAX_ZONE_SHADES):
			if bldg_ptr.zone[izone].zshade[izs] == None: continue;
			delete(bldg_ptr.zone[izone].zshade[izs]);
			bldg_ptr.zone[izone].zshade[izs] = None;
		for irp in range(MAX_REF_PTS):
			if bldg_ptr.zone[izone].ref_pt[irp] == None: continue;
			for isurf in range(MAX_ZONE_SURFS):
				for iwndo in range(MAX_SURF_WNDOS):
					if bldg_ptr.zone[izone].ref_pt[irp].wlum[isurf][iwndo] == None: continue;
					delete(bldg_ptr.zone[izone].ref_pt[irp].wlum[isurf][iwndo]);
					bldg_ptr.zone[izone].ref_pt[irp].wlum[isurf][iwndo] = None;
			delete(bldg_ptr.zone[izone].ref_pt[irp]);
			bldg_ptr.zone[izone].ref_pt[irp] = None;
		delete(bldg_ptr.zone[izone]);
		bldg_ptr.zone[izone] = None;
	for ibshd in range(MAX_BLDG_SHADES):
		if bldg_ptr.bshade[ibshd] == None: continue;
		delete(bldg_ptr.bshade[ibshd]);
		bldg_ptr.bshade[ibshd] = None;
	return 0;
}
/****************************** subroutine free_lib *****************************/
/* Frees malloced memory used in lib data structure. */
/* RJH 7/25/03 - malloc/free changed to new/delete */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine free_lib *****************************/
def free_lib(
	lib_ptr: LIB*)	/* pointer to library data */
-> I32:
{
	var igt: I32, iwshd: I32;	/* loop indexes */
	for igt in range(MAX_LIB_COMPS):
		if lib_ptr.glass[igt] == None: continue;
		delete(lib_ptr.glass[igt]);
		lib_ptr.glass[igt] = None;
	for iwshd in range(MAX_LIB_COMPS):
		if lib_ptr.wshade[iwshd] == None: continue;
		delete(lib_ptr.wshade[iwshd]);
		lib_ptr.wshade[iwshd] = None;
	return 0;
}
/****************************** subroutine get_sched *****************************/
/* Determines lighting scehdule indexes for each zone for given day of year and */
/* day of week. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine get_sched *****************************/
def get_sched(
	bldg_ptr: BLDG*,	/* pointer to bldg structure */
	dayofyr: I32,	/* current sequential day of year */
	dayofweek: I32)	/* current day of week (1=Mon to 7=Sun) */
-> I32:
{
	var iz: I32, ils: I32;	/* loop indexes */
	var doy_begin: I32, doy_end: I32;	/* temp day of year vars */
	var dow_begin: I32, dow_end: I32;	/* temp day of week vars */
	var iRetVal: I32 = 0;
	for iz in range(bldg_ptr.nzones):
		var iLtschFound: I32 = 0;
		for ils in range(bldg_ptr.zone[iz].nltsch):
			doy_begin = bldg_ptr.zone[iz].ltsch[ils].doy_begin;
			doy_end = bldg_ptr.zone[iz].ltsch[ils].doy_end;
			if (dayofyr >= doy_begin) and (dayofyr <= doy_end):
				dow_begin = bldg_ptr.zone[iz].ltsch[ils].dow_begin;
				dow_end = bldg_ptr.zone[iz].ltsch[ils].dow_end;
				if (dayofweek >= dow_begin) and (dayofweek <= dow_end):
					bldg_ptr.zone[iz].ltsch_id = ils;
					iLtschFound = 1;
					break;
		if not iLtschFound: iRetVal = -1;
	return iRetVal;
}
/****************************** subroutine calc_sched_days *****************************/
/* Determines sequential beginning and ending day of year for each lighting schedule */
/* defined in the bldg structure for the given run period year. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine calc_sched_days *****************************/
def calc_sched_days(
	bldg_ptr: BLDG*,		/* pointer to bldg structure */
	run_ptr: RUN_DATA*)	/* pointer to run period data structure */
-> I32:
{
	var dateJul: I32;	/* Julian date */
	var jan01: I32;		/* Julian date of Jan 01 for run period year */
	var month: I32, day: I32;
	var iz: I32, ils: I32;	/* loop indexes */
	julian_date(&jan01,1,1,run_ptr.year);
	for iz in range(bldg_ptr.nzones):
		for ils in range(bldg_ptr.zone[iz].nltsch):
			month = bldg_ptr.zone[iz].ltsch[ils].mon_begin;
			day = bldg_ptr.zone[iz].ltsch[ils].day_begin;
			julian_date(&dateJul,month,day,run_ptr.year);
			bldg_ptr.zone[iz].ltsch[ils].doy_begin = dateJul - jan01 + 1;
			month = bldg_ptr.zone[iz].ltsch[ils].mon_end;
			day = bldg_ptr.zone[iz].ltsch[ils].day_end;
			julian_date(&dateJul,month,day,run_ptr.year);
			bldg_ptr.zone[iz].ltsch[ils].doy_end = dateJul - jan01 + 1;
	return 0;
}
/****************************** subroutine julian_date *****************************/
/* Determines Julian date given month, day and year. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine julian_date *****************************/
def julian_date(
	dateJul_ptr: I32*,		/* pointer to Julian date */
	month: I32,
	day: I32,
	year: I32)
-> I32:
{
	var		u74: I32, u75: I32;
	var		int75: I32, int74: I32;
	var		yr: I32;
	if year < 2000: yr = year % 1900;
	else: yr = year % 2000 + 100;
	u75 = yr - 76;
	if month > 2:
		u74 = month + 1;
	else:
		u74 = month + 13;
		u75 = u75 - 1;
	int75 = u75 * 1461 / 4;
	int74 = u74 * 306 / 10;
	dateJul_ptr[] = -122 + day + int75 + int74 - 1;
	return 0;
}
/****************************** subroutine get_day_of_week *****************************/
/* Determines day of week (1=Mon to 7=Sun) for first day in run period. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine get_day_of_week *****************************/
def get_day_of_week(
	dow_ptr: I32*,		/* pointer to day of week (1=Mon to 7=Sun) */
	run_ptr: RUN_DATA*)	/* pointer to runtime data structure */
-> I32:
{
	var	dateJul: I32;
	var month: I32, day: I32, year: I32;
	month = run_ptr.mon_begin;
	day = run_ptr.day_begin;
	year = run_ptr.year;
	julian_date(&dateJul,month,day,year);
	dow_ptr[] = dateJul % 7 + 1;
	return 0;
}
/****************************** subroutine ran0 *****************************/
/* Generates a random number between 0 and 1. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine ran0 *****************************/
def ran0(
	idum: I32*)
-> F64:
{
	var y: F64, maxran: F64, v: F64[98];
	var dum: F64;
	var iff: I32 = 0;
	var j: I32;
	var i: UInt32, k: UInt32;
	if idum[] < 0 or iff == 0:
		iff=1;
		i=2;
		do:
			k=i;
			i<<=1;
		while i;
		maxran=k;
		srand(idum[]);
		idum[]=1;
		for j in range(1,98): dum=rand();
		for j in range(1,98): v[j]=rand();
		y=rand();
	j=(1+97.0*y/maxran) as I32;
	y=v[j];
	v[j]=rand();
	return y/maxran;
}
/****************************** subroutine init_monlength *****************************/
/* Initializes number of days in each month array. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine init_monlength *****************************/
def init_monlength(
	monlength: I32[12],	/* number of days in each month array */
	iFebDays: I32)		/* number of days in February */
-> I32:
{
	monlength[0] = 31;
	monlength[1] = iFebDays;
	monlength[2] = 31;
	monlength[3] = 30;
	monlength[4] = 31;
	monlength[5] = 30;
	monlength[6] = 31;
	monlength[7] = 31;
	monlength[8] = 30;
	monlength[9] = 31;
	monlength[10] = 30;
	monlength[11] = 31;
	return 0;
}
/****************************** subroutine fit4 *****************************/
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine fit4 *****************************/
def fit4(
	dcosb: F64,	// cos of angle of incidence
	dTvFit1: F64,	// coef1
	dTvFit2: F64)	// coef2
-> F64:
{
	return max(0.0, dcosb * (2.0 - dcosb + (1.0 - dcosb) * ( 1.0 - dcosb) * (dTvFit1 + dTvFit2 * (2.0 + dcosb))));
}
/****************************** utilities *****************************/
def str_rmblnk(
	s1: String)
-> String:
{
	var	length: I32 = len(s1);
	while s1[--length] == ' ':
		pass;
	s1 = s1[:length+1];
	return s1;
}
def str_blnk2undr(
	s1: String)
-> String:
{
	var	ii: I32;
	var	length: I32 = len(s1);
	/* replace all blanks with underscore */
	for ii in range(length):
		if s1[ii] == ' ': s1[ii] = '_';
	/* remove trailing underscores */
	while s1[--length] == '_':
		pass;
	s1 = s1[:length+1];
	return s1;
}
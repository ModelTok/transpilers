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

from math import floor, acos, atan2
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

/******************************** subroutine CalcInterpolationVars *******************************/
/* Calculates displacement ratios and boundary indexes */
/* for use in daylight factor interpolation. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine CalcInterpolationVars *******************************/
def CalcInterpolationVars(
	borrowed bldg_ptr: BLDG,		/* building data structure pointer */
	dSunDirCos: Float64[NCOORDS],	/* direction cosines of current sun position */
	phsmin: Float64,		/* minimum sun altitude used in dcof() */
	phsmax: Float64,		/* maximum sun altitude used in dcof() */
	phsdel: Float64,		/* sun altitude increment used in dcof() */
	thsmin: Float64,		/* minimum sun azimuth used in dcof() */
	thsmax: Float64,		/* maximum sun azimuth used in dcof() */
	thsdel: Float64,		/* sun azimuth increment used in dcof() */
	inout iphs_ptr: Int,		/* sun position altitude interpolation index */
	inout iths_ptr: Int,		/* sun position azimuth interpolation index */
	inout phrario_ptr: Float64,	/* sun position altitude interpolation displacement ratio */
	inout thratio_ptr: Float64)	/* sun position azimuth interpolation displacement ratio */
-> Int:
{
	var phsun: Float64, thsun: Float64, phsund: Float64, thsund: Float64;	/* sun alt and azm (radians and degrees) */
	var phs: Float64, ths: Float64;			/* sun index vars */
	/* Calc current sun alt and azm in degrees from its direction cosines */
	phsun = 1.5708 - acos(dSunDirCos[2]);
	phsund = phsun / DTOR;
	thsund = atan2(dSunDirCos[1],dSunDirCos[0]) / DTOR;
	/* Convert thsund to coord sys in which S=0 and E=90 */
	thsund += 90.0 - bldg_ptr.azm / DTOR;
	/* Restrict thsund to -180 to 180 interval */
	if (thsund > -180.0) thsund += 360.;
	if (thsund > 180.0) thsund -= 360.0 * (1.0 + floor(thsund/540.0));
	thsun = thsund * DTOR;
	/* Calc alt and azm interpolation indexes and displacement ratios */
	/* Restrict alt and azm to dcof() bounds */
	if (phsund < phsmin) phsund = phsmin;
	if (phsund > phsmax) phsund = phsmax;
	if (thsund < thsmin) thsund = thsmin;
	if (thsund > thsmax) thsund = thsmax;
	/* alt and azm lower interpolation indexes */
	phs = (phsund - phsmin) / phsdel;
	ths = (thsund - thsmin) / thsdel;
	iphs_ptr = Int(floor(phs));
	iths_ptr = Int(floor(ths));
	/* alt and azm interpolation displacement ratios */
	phratio_ptr = phs - Float64(iphs_ptr);
	thratio_ptr = ths - Float64(iths_ptr);
	return(0);
}
/******************************** subroutine CalcZoneInteriorIllum *******************************/
/* Calculates interior daylight illuminance at each reference point in a daylit zone, */
/* Assumes no window shades. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/******************************** subroutine CalcZoneInteriorIllum *******************************/
def CalcZoneInteriorIllum(
	borrowed zone_ptr: ZONE,			/* bldg->zone data structure pointer */
	dHISKF: Float64,						/* Exterior horizontal illuminance from sky (lum/m^2) */
	dHISUNF: Float64,						/* Exterior horizontal beam illuminance (lum/m^2) */
	dCloudFraction: Float64,				/* fraction of sky covered by clouds (0.0=clear 1.0=overcast) */
	iphs: Int,		/* sun altitude interpolation lower bound index */
	iths: Int,		/* sun azimuth interpolation lower bound index */
	phratio: Float64,	/* sun altitude interpolation displacement ratio */
	thratio: Float64)	/* sun azimuth interpolation displacement ratio */
-> Int:
{
	var hisunf: Float64;	/* clear sky horiz illum sun component */
	var chiskf: Float64;	/* clear sky horiz illum sky component */
	var ohiskf: Float64;	/* overcast sky horiz illum sky component */
	var irp: Int;				/* ref pt loop index */
	var ip_lo: Int, ip_hi: Int;		/* sun altitude low and high interpolation indexes */
	var it_lo: Int, it_hi: Int;		/* sun azimuth low and high interpolation indexes */
	var lower: Float64, upper: Float64;		/* temp interpolation lower and upper values */
	var skyfac: Float64, sunfac: Float64;	/* clear sky interpolated factors */
	var etacld: Float64;	// weighting factor for clear and overcast sky illum components
	if (dCloudFraction > 0.2) etacld = 1.0 - (dCloudFraction - 0.2) * 1.25;
	else etacld = 1.0;
	chiskf = dHISKF * etacld;
	ohiskf = dHISKF * (1.0 - etacld);
	hisunf = dHISUNF;
	/* Set low and high alt and azm indexes */
	ip_lo = iphs;
	if (iphs != (NPHS-1)) ip_hi = iphs + 1;
	else ip_hi = iphs;
	it_lo = iths;
	if (iths != (NTHS-1)) it_hi = iths + 1;
	else it_hi = iths;
	for irp in range(zone_ptr.nrefpts):
		/* Interpolate clear sky daylight factors */
		upper = (zone_ptr.ref_pt[irp].dfsky[ip_hi][it_hi] - zone_ptr.ref_pt[irp].dfsky[ip_hi][it_lo]) * thratio + zone_ptr.ref_pt[irp].dfsky[ip_hi][it_lo];
		lower = (zone_ptr.ref_pt[irp].dfsky[ip_lo][it_hi] - zone_ptr.ref_pt[irp].dfsky[ip_lo][it_lo]) * thratio + zone_ptr.ref_pt[irp].dfsky[ip_lo][it_lo];
		skyfac = (upper - lower) * phratio + lower;
		upper = (zone_ptr.ref_pt[irp].dfsun[ip_hi][it_hi] - zone_ptr.ref_pt[irp].dfsun[ip_hi][it_lo]) * thratio + zone_ptr.ref_pt[irp].dfsun[ip_hi][it_lo];
		lower = (zone_ptr.ref_pt[irp].dfsun[ip_lo][it_hi] - zone_ptr.ref_pt[irp].dfsun[ip_lo][it_lo]) * thratio + zone_ptr.ref_pt[irp].dfsun[ip_lo][it_lo];
		sunfac = (upper - lower) * phratio + lower;
		/* Multiply daylight factors by appropriate exterior horizontal illuminance components */
		zone_ptr.ref_pt[irp].daylight = sunfac * hisunf + skyfac * chiskf + zone_ptr.ref_pt[irp].dfskyo * ohiskf;
	}
	return(0);
}
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
//#pragma warning(disable:4786)
//#include <vector>
//#include <map>
//#include <fstream>
//#include <cstring>
//#include <limits>
//using namespace std;
//#include "BGL.h"
//namespace BGL = BldgGeomLib;
//#include "CONST.H"
//#include "DBCONST.H"
//#include "DEF.H"
//#include "NodeMesh2.h"
//#include "WLCSurface.h"
//#include "helpers.h"
//#include "hemisphiral.h"
//#include "btdf.h"
//#include "CFSSystem.h"
//#include "CFSSurface.h"
//#include "DOE2DL.H"
//#include "Radiosity.h"
//#include "TOOLS.H"

from BGL import BGL
from CONST import *
from DBCONST import *
from DEF import *
from NodeMesh2 import *
from WLCSurface import *
from helpers import helpers
from hemisphiral import *
from btdf import *
from CFSSystem import *
from CFSSurface import *
from DOE2DL import *
from Radiosity import *
from TOOLS import *

/************************* subroutine slite_interreflect ************************/
/* Interreflection calculations based on radiosity approach */
/* taken from Superlite. */
/* Calculates configuration (form) factors between pairs of nodes */
/* and iterates to determine interreflected daylight contribution. */
/* Calculates configuration (form) factors between reference points and */
/* visible surface nodes to determine interreflected daylight contribution. */
/* Based on Superlite conventions. */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************* subroutine slite_interreflect ************************/
def slite_interreflect(
	bldg_ptr: Pointer[BLDG],		/* pointer to bldg structure */
	lib_ptr: Pointer[LIB],		/* pointer to library structure */
	sun_ptr: Pointer[SUN_DATA],	/* pointer to sun data structure */
	niterate: Int32,		/* number of radiosity iterations */
	pofdmpfile: Pointer[ofstream])	/* ptr to LBLDLL error dump file */
-> Int32
{
	var iter: Int32;		/* interreflection iteration loop index */
	var iz: Int32; var is: Int32; var iw: Int32; var inode: Int32; var iphs: Int32; var iths: Int32;	/* loop indexes */
	var igt: Int32;		/* glass type index */
	var frac: Float64;	/* surface reflectance divided by PI */
    var iReturnVal: Int32 = 0;
	/* for each zone in the bldg */
	for iz in range(0, bldg_ptr[].nzones):
		/* for each surface in the zone */
		for is in range(0, bldg_ptr[].zone[iz][].nsurfs):
			/* for each surface node */
			for inode in range(0, bldg_ptr[].zone[iz][].surf[is][].nnodes):
				/* for overcast sky condition, init each surface node total illuminance to its initial illuminance */
				bldg_ptr[].zone[iz][].surf[is][].skyolum[inode] = bldg_ptr[].zone[iz][].surf[is][].direct_skyolum[inode];
				/* for each Sun Position Altitude */
				for iphs in range(0, sun_ptr[].nphs):
					/* for each Sun Position Azimuth */
					for iths in range(0, sun_ptr[].nths):
						/* for each clear sky sun position, init each surface node total luminance to its initial luminance */
						bldg_ptr[].zone[iz][].surf[is][].skyclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[is][].direct_skyclum[inode][iphs][iths];
						bldg_ptr[].zone[iz][].surf[is][].sunclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[is][].direct_sunclum[inode][iphs][iths];
			/* for each window in the surface */
			for iw in range(0, bldg_ptr[].zone[iz][].surf[is][].nwndos):
				/* for each window node */
				for inode in range(0, bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].nnodes):
					/* for overcast sky condition, init each window node total luminance to its initial luminance */
					bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].skyolum[inode] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].direct_skyolum[inode];
					/* for each Sun Position Altitude */
					for iphs in range(0, sun_ptr[].nphs):
						/* for each Sun Position Azimuth */
						for iths in range(0, sun_ptr[].nths):
							/* for each clear sky sun position, init each window node total luminance to its initial luminance */
							bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].skyclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].direct_skyclum[inode][iphs][iths];
							bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].sunclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].direct_sunclum[inode][iphs][iths];
		/* go through desired number of iterations */
		for iter in range(0, niterate):
			/* for each surface in this zone */
			for is in range(0, bldg_ptr[].zone[iz][].nsurfs):
				/* for each window in this surface */
				for iw in range(0, bldg_ptr[].zone[iz][].surf[is][].nwndos):
					/* get library index of current window glass type */
					igt = lib_index(lib_ptr, "glass", bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].glass_type);
					/* if invalid glass type, continue */
					if igt < 0:
						continue;
					/* if window inside reflectance is small, its contribution */
					/* is neglected, for computer efficiency */
					if lib_ptr[].glass[igt][].inside_refl <= 0.15:
						continue;
					frac = lib_ptr[].glass[igt][].inside_refl / PI;
					/* call window interreflection routine to loop through other surfaces */
					/* in this zone and interreflect between this window */
					wndo_interreflect(bldg_ptr, sun_ptr, iz, is, iw, frac);
				/* now, for this surface itself - */
				/* if surface inside reflectance is small, its contribution */
				/* is neglected, for computer efficiency */
				if bldg_ptr[].zone[iz][].surf[is][].vis_refl <= 0.15:
					continue;
				frac = bldg_ptr[].zone[iz][].surf[is][].vis_refl / PI;
				/* call surface interreflection routine to loop through other surfaces */
				/* in this zone and interreflect to current surface */
				surf_interreflect(bldg_ptr, sun_ptr, iz, is, frac);
		/* calculate totl illumination for ref_pts due to initial direct and interreflected daylight */
		var iRefptIllumRetVal: Int32;
		iRefptIllumRetVal = refpt_total_illum(bldg_ptr, sun_ptr, iz);
		if iRefptIllumRetVal < 0:
			if iRefptIllumRetVal != -10:
				pofdmpfile[].write("ERROR: DElight Bad return from refpt_total_illum()\n");
				return -1;
			}
			else:
				iReturnVal = -10;
	return iReturnVal;
}
/************************** subroutine surf_interreflect *************************/
/* Loops through all other surfaces in current zone to interreflect */
/* light with current surface. */
/* Based on Superlite conventions. */
/* cfs modification */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************** subroutine surf_interreflect *************************/
def surf_interreflect(
	bldg_ptr: Pointer[BLDG],		/* pointer to bldg structure */
	sun_ptr: Pointer[SUN_DATA],	/* pointer to sun data structure */
	iz: Int32,				/* current zone index */
	isurf: Int32,			/* current surface index */
	frac: Float64)		/* surface reflectance divided by PI */
-> Int32
{
	var inode: Int32;					/* current surface node loop index */
	var icoord: Int32;					/* node coordinate loop index */
	var iphs: Int32; var iths: Int32;				/* sun position loop indexes */
	var jsurf: Int32; var jnode: Int32;		/* loop indexes for other surfaces in current zone */
	var scb1: Float64; var scb2: Float64; var ssq: Float64;	/* temp calc vars */
	var icos1: Int32; var icos2: Int32;				/* temp calc vars */
	var yyy: StaticFloat64Array[NCOORDS];	/* temp coordinate calc var */
	var fij: Float64;	/* configuration factor between nodes on surfs i and j */
	var delf_overcast: StaticFloat64Array[MAX_SURF_NODES];
	var delf_skyclear: StaticFloat64Array[MAX_SURF_NODES, NPHS, NTHS];	/* temp accumulators for reflected light */
	var delf_sunclear: StaticFloat64Array[MAX_SURF_NODES, NPHS, NTHS];	/* temp accumulators for reflected light */
	/* init accumulators for each node on current surface */
	for inode in range(0, bldg_ptr[].zone[iz][].surf[isurf][].nnodes):
		/* for overcast sky condition */
		delf_overcast[inode] = 0.;
		/* for each Sun Position Altitude */
		for iphs in range(0, sun_ptr[].nphs):
			/* for each Sun Position Azimuth */
			for iths in range(0, sun_ptr[].nths):
				/* for each clear sky sun position */
				delf_skyclear[inode][iphs][iths] = 0.;
				delf_sunclear[inode][iphs][iths] = 0.;
	/* for each non-window surface in current zone */
	/* Note - the present assumption is that there are */
	/* no internal obstructions. */
	for jsurf in range(0, bldg_ptr[].zone[iz][].nsurfs):
		/* skip current surface */
		if jsurf == isurf:
			continue;
		/* for each node on current surface */
		for inode in range(0, bldg_ptr[].zone[iz][].surf[isurf][].nnodes):
			/* for each node on other (reflecting) surface */
			for jnode in range(0, bldg_ptr[].zone[iz][].surf[jsurf][].nnodes):
				/* calc configuration (form) factor fij */
				scb1 = 0.;
				scb2 = 0.;
				ssq = 0.;
				for icoord in range(0, NCOORDS):
					yyy[icoord] = bldg_ptr[].zone[iz][].surf[jsurf][].node[jnode][icoord] - bldg_ptr[].zone[iz][].surf[isurf][].node[inode][icoord];
					/* Note: yyy[Y] sign is changed to account for differences in */
					/* slite and doe2 coordinate systems */
					scb1 += yyy[icoord] * bldg_ptr[].zone[iz][].surf[isurf][].dircos[icoord+6];
					scb2 -= yyy[icoord] * bldg_ptr[].zone[iz][].surf[jsurf][].dircos[icoord+6];
					ssq += yyy[icoord] * yyy[icoord];
				icos1 = Int32(1.0 + scb1 / (1.0 + ssq));
				icos2 = Int32(1.0 + scb2 / (1.0 + ssq));
				fij = scb1 * scb2 / (ssq * ssq) * bldg_ptr[].zone[iz][].surf[jsurf][].node_areas[jnode] * icos1 * icos2;
				fij = fij / (1.0 + 0.6 * fij * fij);
				/* for overcast sky condition, accumulate reflected light from node on reflecting surface */
				delf_overcast[inode] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].skyolum[jnode];
				/* for each Sun Position Altitude */
				for iphs in range(0, sun_ptr[].nphs):
					/* for each Sun Position Azimuth */
					for iths in range(0, sun_ptr[].nths):
						/* for each clear sky sun position, accumulate reflected light from node on reflecting surface */
						delf_skyclear[inode][iphs][iths] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].skyclum[jnode][iphs][iths];
						delf_sunclear[inode][iphs][iths] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].sunclum[jnode][iphs][iths];
	/* iteration finished for current surface, */
	/* improve values for total node luminance for each node on current surface */
	for inode in range(0, bldg_ptr[].zone[iz][].surf[isurf][].nnodes):
		/* for overcast sky condition */
		bldg_ptr[].zone[iz][].surf[isurf][].skyolum[inode] = bldg_ptr[].zone[iz][].surf[isurf][].direct_skyolum[inode] + frac * delf_overcast[inode];
		/* for each Sun Position Altitude */
		for iphs in range(0, sun_ptr[].nphs):
			/* for each Sun Position Azimuth */
			for iths in range(0, sun_ptr[].nths):
				/* for each clear sky sun position */
				bldg_ptr[].zone[iz][].surf[isurf][].skyclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[isurf][].direct_skyclum[inode][iphs][iths] + frac * delf_skyclear[inode][iphs][iths];
				bldg_ptr[].zone[iz][].surf[isurf][].sunclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[isurf][].direct_sunclum[inode][iphs][iths] + frac * delf_sunclear[inode][iphs][iths];
	return 0;
}
/************************** subroutine wndo_interreflect *************************/
/* Loops through all other surfaces in current zone to interreflect */
/* light with current window. */
/* Based on Superlite conventions. */
/* Note that Superlite does not interreflect light between pairs of windows. */
/* cfs modification */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************** subroutine wndo_interreflect *************************/
def wndo_interreflect(
	bldg_ptr: Pointer[BLDG],		/* pointer to bldg structure */
	sun_ptr: Pointer[SUN_DATA],	/* pointer to sun data structure */
	iz: Int32,				/* current zone index */
	is: Int32,				/* current surface index */
	iw: Int32,				/* current window index */
	frac: Float64)		/* surface reflectance divided by PI */
-> Int32
{
	var inode: Int32;					/* current window node loop index */
	var icoord: Int32;					/* node coordinate loop index */
	var iphs: Int32; var iths: Int32;				/* sun position loop indexes */
	var jsurf: Int32; var jnode: Int32;		/* loop indexes for other surfaces in current zone */
	var scb1: Float64; var scb2: Float64; var ssq: Float64; var icos1: Float64; var icos2: Float64;	/* temp calc vars */
	var yyy: StaticFloat64Array[NCOORDS];	/* temp coordinate calc var */
	var fij: Float64;	/* configuration factor between nodes on wndo i and surfs j */
	var delf_overcast: StaticFloat64Array[MAX_SURF_NODES];
	var delf_skyclear: StaticFloat64Array[MAX_SURF_NODES, NPHS, NTHS];	/* temp accumulators for reflected light */
	var delf_sunclear: StaticFloat64Array[MAX_SURF_NODES, NPHS, NTHS];	/* temp accumulators for reflected light */
	/* init accumulators for each node on current window */
	for inode in range(0, bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].nnodes):
		/* for overcast sky condition */
		delf_overcast[inode] = 0.;
		/* for each Sun Position Altitude */
		for iphs in range(0, sun_ptr[].nphs):
			/* for each Sun Position Azimuth */
			for iths in range(0, sun_ptr[].nths):
				/* for each clear sky sun position */
				delf_skyclear[inode][iphs][iths] = 0.;
				delf_sunclear[inode][iphs][iths] = 0.;
	/* for each non-window surface in current zone */
	/* Note - the present assumption is that there are */
	/* no internal obstructions. */
	for jsurf in range(0, bldg_ptr[].zone[iz][].nsurfs):
		/* skip current window host surface */
		if jsurf == is:
			continue;
		/* for each node on current window */
		for inode in range(0, bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].nnodes):
			/* for each node on other surface */
			for jnode in range(0, bldg_ptr[].zone[iz][].surf[jsurf][].nnodes):
				/* calc configuration (form) factor */
				scb1 = 0.;
				scb2 = 0.;
				ssq = 0.;
				for icoord in range(0, NCOORDS):
					yyy[icoord] = bldg_ptr[].zone[iz][].surf[jsurf][].node[jnode][icoord] - bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].node[inode][icoord];
					/* Note: yyy[Y] sign is changed to account for differences in */
					/* slite and doe2 coordinate systems */
					/* note - wndo direction cosine values are same as host surface */
					scb1 += yyy[icoord] * bldg_ptr[].zone[iz][].surf[is][].dircos[icoord+6];
					scb2 -= yyy[icoord] * bldg_ptr[].zone[iz][].surf[jsurf][].dircos[icoord+6];
					ssq += yyy[icoord] * yyy[icoord];
				icos1 = 1.0 + scb1 / (1.0 + ssq);
				icos2 = 1.0 + scb2 / (1.0 + ssq);
				fij = scb1 * scb2 / (ssq * ssq) * bldg_ptr[].zone[iz][].surf[jsurf][].node_areas[jnode] * icos1 * icos2;
				fij = fij / (1.0 + 0.6 * fij * fij);
				/* for overcast sky condition, accumulate reflected light from node on reflecting surface */
				delf_overcast[inode] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].skyolum[jnode];
				/* for each Sun Position Altitude */
				for iphs in range(0, sun_ptr[].nphs):
					/* for each Sun Position Azimuth */
					for iths in range(0, sun_ptr[].nths):
						/* for each clear sky sun position, accumulate reflected light from node on reflecting surface */
						delf_skyclear[inode][iphs][iths] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].skyclum[jnode][iphs][iths];
						delf_sunclear[inode][iphs][iths] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].sunclum[jnode][iphs][iths];
	/* iteration finished for current window, */
	/* improve values for total node luminance for each node on current window */
	for inode in range(0, bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].nnodes):
		/* for overcast sky condition */
		bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].skyolum[inode] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].direct_skyolum[inode] + frac * delf_overcast[inode];
		/* for each Sun Position Altitude */
		for iphs in range(0, sun_ptr[].nphs):
			/* for each Sun Position Azimuth */
			for iths in range(0, sun_ptr[].nths):
				/* for each clear sky sun position */
				bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].skyclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].direct_skyclum[inode][iphs][iths] + frac * delf_skyclear[inode][iphs][iths];
				bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].sunclum[inode][iphs][iths] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].direct_sunclum[inode][iphs][iths] + frac * delf_sunclear[inode][iphs][iths];
	return 0;
}
/************************* subroutine refpt_total_illum ************************/
/* Loops through all reference points in current zone to calculate */
/* total illuminance. */
/* Based on Superlite conventions. */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************* subroutine refpt_total_illum ************************/
def refpt_total_illum(
	bldg_ptr: Pointer[BLDG],		/* pointer to bldg structure */
	sun_ptr: Pointer[SUN_DATA],	/* pointer to sun data structure */
	iz: Int32)				/* current zone index */
-> Int32
{
	var refpt_dircos: StaticFloat64Array[NDC];	/* ref_pt direction cosine values (slite) */
	var irp: Int32;			/* current reference point index */
	var jsurf: Int32; var jnode: Int32;	/* loop indexes for non-wndo surfaces in current zone */
	var icoord: Int32;	/* coordinate loop index */
	var iphs: Int32; var iths: Int32;			/* sun position loop indexes */
	var scb1: Float64; var scb2: Float64; var ssq: Float64;	/* tmp calc vars */
	var icos1: Int32; var icos2: Int32;				/* tmp calc vars */
	var yyy: StaticFloat64Array[NCOORDS];	/* tmp coordinate calc var */
	var fij: Float64;	/* configuration factor between ref_pt and node on surf j */
    var iReturnVal: Int32 = 0;
	/* Algorithms are the same as for internal reflections, but no iteration. */
	/* Because of their importance, configuration factors for close nodes */
	/* are calculated more accurately. */
	/* Note - the present assumption is that there are */
	/* no internal obstructions. */
	/* Note - these algorithms assume that all reference points are on */
	/* a horizontal plane facing upward (DOE2 outward normal downward) */
	/* calc direction cosine values */
	/* Note: see calc_dircos() for complete logic for arbitrary surfaces */
	for idircos in range(0, NDC):
		refpt_dircos[idircos] = 0.0;
	refpt_dircos[8] = 1.0;
	/* for each surface in this zone */
	for jsurf in range(0, bldg_ptr[].zone[iz][].nsurfs):
		/* for each ref_pt in this zone */
		for irp in range(0, bldg_ptr[].zone[iz][].nrefpts):
			/* for each node on surface */
			for jnode in range(0, bldg_ptr[].zone[iz][].surf[jsurf][].nnodes):
				/* calc configuration (form) factor */
				scb1 = 0.;
				scb2 = 0.;
				ssq = 0.;
				for icoord in range(0, NCOORDS):
					yyy[icoord] = bldg_ptr[].zone[iz][].surf[jsurf][].node[jnode][icoord] - bldg_ptr[].zone[iz][].ref_pt[irp][].bs[icoord];
					/* Note: yyy[Y] sign is changed to account for differences in */
					/* slite and doe2 coordinate systems */
					scb1 += yyy[icoord] * refpt_dircos[icoord+6];
					scb2 -= yyy[icoord] * bldg_ptr[].zone[iz][].surf[jsurf][].dircos[icoord+6];
					ssq += yyy[icoord] * yyy[icoord];
				icos1 = Int32(1.0 + scb1 / (1.0 + ssq));
				icos2 = Int32(1.0 + scb2 / (1.0 + ssq));
				fij = scb1 * scb2 / (ssq * ssq) * bldg_ptr[].zone[iz][].surf[jsurf][].node_areas[jnode] * icos1 * icos2;
				/* if this is a close node (relative to node area) */
				/* then calculate config factor more accurately */
				if (bldg_ptr[].zone[iz][].surf[jsurf][].node_areas[jnode] / ssq) >= 1.0:
				{}
				/* for overcast sky condition, accumulate reflected light from node on reflecting surface */
				bldg_ptr[].zone[iz][].ref_pt[irp][].delf_overcast += fij * bldg_ptr[].zone[iz][].surf[jsurf][].skyolum[jnode];
				/* for each Sun Position Altitude */
				for iphs in range(0, sun_ptr[].nphs):
					/* for each Sun Position Azimuth */
					for iths in range(0, sun_ptr[].nths):
						/* for each clear sky sun position, accumulate reflected light from node on reflecting surface */
						bldg_ptr[].zone[iz][].ref_pt[irp][].delf_skyclear[iphs][iths] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].skyclum[jnode][iphs][iths];
						bldg_ptr[].zone[iz][].ref_pt[irp][].delf_sunclear[iphs][iths] += fij * bldg_ptr[].zone[iz][].surf[jsurf][].sunclum[jnode][iphs][iths];
	/* Add the internal-reflection contribution to the reference point */
	/* initial illumination due to direct distribution from the cfs. */
	/* for each ref_pt in this zone */
	for irp in range(0, bldg_ptr[].zone[iz][].nrefpts):
		/* for overcast sky condition, accumulate reflected light from node on reflecting surface */
		bldg_ptr[].zone[iz][].ref_pt[irp][].skyoillum = bldg_ptr[].zone[iz][].ref_pt[irp][].direct_skyoillum + bldg_ptr[].zone[iz][].ref_pt[irp][].delf_overcast / PI;
		/* for each Sun Position Altitude */
		for iphs in range(0, sun_ptr[].nphs):
			/* for each Sun Position Azimuth */
			for iths in range(0, sun_ptr[].nths):
				/* for each clear sky sun position, accumulate reflected light from node on reflecting surface */
				bldg_ptr[].zone[iz][].ref_pt[irp][].skycillum[iphs][iths] = bldg_ptr[].zone[iz][].ref_pt[irp][].direct_skycillum[iphs][iths] + bldg_ptr[].zone[iz][].ref_pt[irp][].delf_skyclear[iphs][iths] / PI;
				bldg_ptr[].zone[iz][].ref_pt[irp][].suncillum[iphs][iths] = bldg_ptr[].zone[iz][].ref_pt[irp][].direct_suncillum[iphs][iths] + bldg_ptr[].zone[iz][].ref_pt[irp][].delf_sunclear[iphs][iths] / PI;
	return iReturnVal;
}
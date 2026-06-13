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
// pragma warning(disable:4786)
from iostream import *
from fstream import *
from cstdlib import *
from cmath import *
from vector import *
from map import *
from cstring import *
from string import *
from algorithm import min, max
from BGL import *
alias BGL = BldgGeomLib
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
from DFcalcs import *
from SOL import *
from geom import *
from TOOLS import *
from Radiosity import *
/****************************** subroutine CalcDFs *****************************/
/* Calculates daylighting factors (interior illum / exterior horiz illum) */
/* for each ref_pt in a lighting zone, for overcast sky and */
/* a range of sun postions for clear skies, for open and closed window shades. */
/* Calculates coefficients for use in the hourly daylighting calculation. */
/* Converted from DOE2.1D FORTRAN code */
/* Modified from initial implementation using Radiosity algorithms */
/* from SuperLite 3.0 FORTRAN code */
/****************************************************************************/
/* Modifications to original DOE2.1D DCOF() subroutine include: */
/* 	Variable number of sun positions allowed by passing numbers and minimum angles. */
/*	Accumulates total daylight illuminances (fc) due to overcast sky, clear sky, */
/*	and clear sun components at each reference point and returns these totals */
/*	in bldg_ptr->zone[izone]->ref_pt[irp] structure. */
/* (Note: open shades == clear glazing; closed shades == diffuse glazing) */
/*	All other window shade values are ignored. */
/****************************************************************************/
/* Modifications to initial implementation (DCOF()) include: */
/* 	Rearrange loops in main daylight factor calc section to include CFS apertures. */
/* 	Modify direct contribution from window section to calc initial illuminance on */
/*  surface nodes and reference points. */
/* 	Replace split-flux interreflection calc with radiosity algos from SuperLite. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine CalcDFs *****************************/
def CalcDFs(
	sun_ptr: SUN_DATA,	/* pointer to sun data structure */
	bldg_ptr: BLDG,		/* pointer to bldg structure */
	lib_ptr: LIB,		/* pointer to library structure */
	iIterations: Int,		/* number of radiosity iterations */
	pofdmpfile: ofstream&)	/* ptr to LBLDLL error dump file */
-> Int
{
	var iphs: Int, iths: Int;					/* sun position indexes */
	var izone: Int, isurf: Int, irp: Int, icoord: Int, iIntSurf: Int, inode: Int;	/* bldg component indexes */
	var iw: Int, igt: Int, ic: Int;				/* indexes */
	var thsmin: Float64;		/* minimum sun postition azimuth (degrees: South=0.0, East=+90.0) */
	var phsmin: Float64;					/* minimum sun postition altitude (degrees) */
	var phsmax: Float64;					/* maximum sun position altitude (degrees) */
	var phsdel: Float64, thsdel: Float64;			/* sun position angle increments (degrees) */
	var phsun: Float64;				/* sun alt (radians) */
	var thsun: Float64;				/* sun azm in FredW solar coordinate system [S=0, E=90] (radians) */
	var phsun_deg: Float64;				/* sun alt (degrees) */
	/* Window 4 code modification begin */
	var cam1: Float64, cam2: Float64, cam3: Float64, cam4: Float64;	/* window coefs of trans holders */
	var E10coef1: Float64, E10coef2: Float64, E10coef3: Float64, E10coef4: Float64;	/* Energy-10 angular dependence equation coefs */
	var W4vis_fit1: Float64, W4vis_fit2: Float64;	// Window4 angular dependence equation coefs
	/* Window 4 code modification end */
	var EPlusCoef: Float64[6];	/* EnergyPlus angular dependence equation coefs */
	var wnorm: Float64[NCOORDS];			/* window outward normal vector */
	var node: Float64[NCOORDS];			/* surface node coordinate holder */
	var nodesurfnormal: Float64[NCOORDS];		/* node surface INWARD normal unit vector */
	var ww: Float64, hw: Float64;		/* surface and window geom vars */
	var solic: Float64[MONTHS];	/* extraterrestrial irrad for 1st of each month (0 to 11) */
	var zenl: Float64;				/* clear sky zenith luminance (Kcd/m2) */
	var tfac: Float64;				/* turbidity factor */
	var tvisdf: Float64;			/* visible trans vars */
	var vis_trans: Float64;		/* visible transmittance of window for illum calcs */
	var domega: Float64;	/* solid angle subtended by window wrt ref_pt */
	var hit: HIT;				/* bldg-shade hit structure for dhitsh() test */
	var rwin: Float64[NCOORDS];	/* center of window element */
	var ray: Float64[NCOORDS];		/* ref_pt to center of window element vector */
	var phray: Float64, thray: Float64;		/* ray angles */
	var disq: Float64, ddis: Float64, dis: Float64;	/* ref_pt to window element distance vars */
	var cosWndoIncidence: Float64; 	/* cos of angle between ray and window outward normal */
	var tvisincidence: Float64;	/* tvis of glass for cosWndoIncidence angle */
	/* rjh 4/17/97 Move wsghit[][] outside dreflt() and CalcDiffuseWindowLuminance() to preserve values. */
    var iReturnVal: Int = 0
	/* Set limits of sun position angles. */
	phsmin = sun_ptr.phsmin
	thsmin = sun_ptr.thsmin
	/* For non-standard number of sun altitudes minimum altitude is passed into CalcDFs(). */
	/* Reset minimum altitude for standard number of sun altitudes. */
	if sun_ptr.nphs == NPHS:
		phsmin = 10.0
		if fabs(bldg_ptr.lat) >= 48.0:
			phsmin = 5.0
	
	/* Maximum altitude and altitude angle increment for sun positions. */
	if sun_ptr.nphs == 1:
		phsmax = phsmin
		phsdel = 0.0
	else:
		phsmax = min(90.0, 113.5 - fabs(bldg_ptr.lat))
		phsdel = (phsmax - phsmin) / (sun_ptr.nphs - 1)
	
	/* For non-standard number of sun azimuths minimum azimuth is passed into CalcDFs(). */
	/* Reset minimum azimuth and azm angle increment for standard number of sun azimuths. */
	if sun_ptr.nths == NTHS:
		thsmin = -110.0
		/* minimum solar azimuth for southern hemisphere */
		if bldg_ptr.lat < 0.0:
			thsmin = 70.0
	
	/* Azimuth angle increment for sun positions. */
	if sun_ptr.nths == 1:
		thsdel = 0.0
	else:
		thsdel = fabs(2.0 * thsmin) / (sun_ptr.nths - 1)
	
	/* Calculate extraterrestrial direct normal solar illumination (lum/ft2) */
	/* for the first day of each month. */
	dsolic(solic)

	/* Find exterior illuminances (lum/ft2) on ground and bldg shade luminances */
	/* for different sun positions. */
	/* Sun position altitude (phsun) and azimuth (thsun) loops. */
	for iphs in range(sun_ptr.nphs):
		phsun_deg = phsmin + iphs * phsdel
		phsun = phsun_deg * DTOR
		thsun = 0.0
		/* Get clear sky zenith luminance, moisture, */
		/* and turbidity coef for reference month. */
		dzenlm(zenl, tfac, IMREF, bldg_ptr, phsun)
		/* Get exterior horiz illum from sky and sun for clear and overcast sky.  */
		if dhill(bldg_ptr.hillumskyc[iphs], bldg_ptr.hillumsunc[iphs], bldg_ptr.hillumskyo[iphs], bldg_ptr, IMREF, phsun, thsun, zenl, tfac, solic, pofdmpfile) < 0:
			pofdmpfile << "ERROR: DElight Bad return from dhill(), exit CalcDFs()\n"
			return -1
		
		/* Sun position azm loop */
		for iths in range(sun_ptr.nths):
			/* Solar azm wrt azm = 0 along bldg coord sys X-axis */
			/* converted from sun coord sys where azm=0 due South and azm>0 toward east. */
			thsun = (thsmin + iths * thsdel - 90.0) * DTOR + bldg_ptr.azm * DTOR
			/* Calculate building shade luminances. */
			if dshdlu(bldg_ptr, phsun, thsun, iphs, iths, solic, tfac, zenl, bldg_ptr.hillumskyc[iphs], bldg_ptr.hillumskyo[iphs], bldg_ptr.hillumsunc[iphs], pofdmpfile) < 0:
				pofdmpfile << "ERROR: DElight Bad return from dshdlu(), exit CalcDFs()\n"
				return -1
			/* Calculate diffusing glazing window luminances. */
		
	
	/* ------ Direct (or Initial) Illuminance at Nodal Surfaces Calculation ------ */
	/* Lighting Zone Loop */
	for izone in range(bldg_ptr.nzones):
		/* Exterior Surface Loop */
		for isurf in range(bldg_ptr.zone[izone].nsurfs):
			/* Window Loop */
			for iw in range(bldg_ptr.zone[izone].surf[isurf].nwndos):
				/* get library index of current window glass type */
				igt = lib_index(lib_ptr, "glass", bldg_ptr.zone[izone].surf[isurf].wndo[iw].glass_type)
				if igt < 0:
					continue
				/* shorten often used bldg structure elements */
				ww = bldg_ptr.zone[izone].surf[isurf].wndo[iw].width
				hw = bldg_ptr.zone[izone].surf[isurf].wndo[iw].height
				var iGlass_Type_ID: Int = atoi(bldg_ptr.zone[izone].surf[isurf].wndo[iw].glass_type)
				if (iGlass_Type_ID > 0) and (iGlass_Type_ID <= 11):
					cam1 = lib_ptr.glass[igt].cam1
					cam2 = lib_ptr.glass[igt].cam2
					cam3 = lib_ptr.glass[igt].cam3
					cam4 = lib_ptr.glass[igt].cam4
					/* Diffuse and Normal transmittance for total solar spectrum. */
					var tsoldf: Float64 = lib_ptr.glass[igt].cam9
					var tsolnm: Float64 = cam1 + cam2 + cam3 + cam4
					/* Diffuse transmittance (for normal vis_trans = 1.0) */
					tvisdf = (1.0 / tsolnm) * tsoldf
				elif (iGlass_Type_ID > 11) and (iGlass_Type_ID <= 10000):
					W4vis_fit1 = lib_ptr.glass[igt].W4vis_fit1
					W4vis_fit2 = lib_ptr.glass[igt].W4vis_fit2
					/* Diffuse transmittance (for normal vis_trans = 1.0) */
					tvisdf = lib_ptr.glass[igt].W4hemi_trans / (lib_ptr.glass[igt].vis_trans + 0.000001)
				elif iGlass_Type_ID > 10000:
					for icoef in range(6):
						EPlusCoef[icoef] = lib_ptr.glass[igt].EPlusCoef[icoef]
					/* Diffuse transmittance (for normal vis_trans = 1.0) */
				elif iGlass_Type_ID < 0:
					/* Energy-10 angular dependence equation coefs. */
					E10coef1 = lib_ptr.glass[igt].E10coef[0]
					E10coef2 = lib_ptr.glass[igt].E10coef[1]
					E10coef3 = lib_ptr.glass[igt].E10coef[2]
					E10coef4 = lib_ptr.glass[igt].E10coef[3]
					/* Diffuse transmittance (for normal vis_trans = 1.0) */
					tvisdf = lib_ptr.glass[igt].E10hemi_trans
				else:
					continue
				/* Visible transmittance for this window for ref_pt illum calcs. */
				vis_trans = lib_ptr.glass[igt].vis_trans
				/* unit vector normal to window (pointing away from room) */
				for icoord in range(NCOORDS):
					wnorm[icoord] = bldg_ptr.zone[izone].surf[isurf].outward_uvect[icoord]
				bldg_ptr.zone[izone].surf[isurf].wndo[iw].WLCWNDOInit(0.25)
				for iWndoElement in range(bldg_ptr.zone[izone].surf[isurf].wndo[iw].nnodes):
					for ic in range(NCOORDS):
						rwin[ic] = bldg_ptr.zone[izone].surf[isurf].wndo[iw].node[iWndoElement][ic]
					/* Reference Point Loop */
					for irp in range(bldg_ptr.zone[izone].nrefpts):
						/* Calc ray from ref_pt to wndo element */
						/* distance between ref_pt and element */
						disq = 0.0
						for ic in range(NCOORDS):
							ddis = rwin[ic] - bldg_ptr.zone[izone].ref_pt[irp].bs[ic]
							disq += ddis * ddis
						dis = sqrt(disq)
						if dis < 2.0:
							iReturnVal = -10
							pofdmpfile << "WARNING: DElight Inaccurate daylight illuminance calculation may result for lighting zone " << bldg_ptr.zone[izone].name << "\n"
							pofdmpfile << "WARNING: for reference points closer than 2 feet from window " << bldg_ptr.zone[izone].surf[isurf].wndo[iw].name << "\n"
							if dis <= 0.0:
								pofdmpfile << "WARNING: DElight Reference Point " << bldg_ptr.zone[izone].ref_pt[irp].name << " is positioned on the window surface and will be ignored.\n"
								continue
						/* unit vector along ray from ref_pt to element */
						for ic in range(NCOORDS):
							ray[ic] = (rwin[ic] - bldg_ptr.zone[izone].ref_pt[irp].bs[ic]) / dis
						/* Determine if ray intersects a zone-shade or bldg-shade. */
						/* NOTE: this includes all zone surfaces */
						/* contrary to DOE2 check of only "self-shade" */
						/* surfaces (in addition to zone and bldg shades). */
						/* dhitsh() resets HIT structure */
						dhitsh(hit, bldg_ptr.zone[izone].ref_pt[irp].bs, ray, bldg_ptr, izone, isurf, isurf)
						/* Azm (-PI to PI) and alt (-PI/2 to PI/2) of ray (i.e., azm and alt of sky element) */
						/* Azm = 0 is along x-axis of bldg coord sys. */
						phray = asin(ray[2])
						if (ray[0] == 0.0) and (ray[1] == 0.0):
							thray = 0.0
						else:
							thray = atan2(ray[1], ray[0])
						/* Calc solid angle subtended by element wrt ref_pt */
						/* cos of angle between ray and window outward normal */
						cosWndoIncidence = ddot(wnorm, ray)
						/* Solid angle subtended by element wrt ref_pt */
						domega = bldg_ptr.zone[izone].surf[isurf].wndo[iw].node_areas[iWndoElement] * cosWndoIncidence / disq
						/* Calc tvis of glass for incidence angle */
						if (iGlass_Type_ID > 0) and (iGlass_Type_ID <= 11):
							tvisincidence = max(0.0, (cam1 + cosWndoIncidence * (cam2 + cosWndoIncidence * (cam3 + cosWndoIncidence * cam4))))
						elif (iGlass_Type_ID > 11) and (iGlass_Type_ID <= 10000):
							tvisincidence = vis_trans * fit4(cosWndoIncidence, W4vis_fit1, W4vis_fit2)
						elif iGlass_Type_ID > 10000:
							tvisincidence = POLYF(cosWndoIncidence, EPlusCoef)
						elif iGlass_Type_ID < 0:
							tvisincidence = vis_trans * max(0.0, (cosWndoIncidence * (E10coef1 + cosWndoIncidence * (E10coef2 + cosWndoIncidence * (E10coef3 + cosWndoIncidence * E10coef4)))))
						/* Set ref_pt unit vector "surface" face normal (all ref_pts assumed horizontal facing upward). */
						nodesurfnormal[0] = 0.0
						nodesurfnormal[1] = 0.0
						nodesurfnormal[2] = 1.0
						var cosPtSurfIncidence: Float64 = ddot(nodesurfnormal, ray)
						/* Sun Position Altitude Loop */
						for iphs in range(sun_ptr.nphs):
							/* Altitude of sun */
							phsun_deg = phsmin + iphs * phsdel
							phsun = phsun_deg * DTOR
							/* Get clear sky zenith luminance, moisture, */
							/* and turbidity coef for reference month. */
							dzenlm(zenl, tfac, IMREF, bldg_ptr, phsun)
							/* Sun Position Azimuth Loop */
							for iths in range(sun_ptr.nths):
								/* azm of sun in strange sun coord sys (0=East, counter-clockwise is positive) */
								thsun = (thsmin + iths * thsdel - 90.0) * DTOR + bldg_ptr.azm * DTOR
								/* Add contribution of current wndo element to */
								/* direct illum at current ref_pt, */
								/* for current sky condition. */
								var iWndoContribRetVal: Int = wndo_element_refpt_illum_contrib(
									bldg_ptr,
									lib_ptr,
									izone,
									isurf,
									isurf,
									iw,
									iWndoElement,
									thsun,
									phsun,
									thray,
									phray,
									iphs,
									iths,
									solic,
									bldg_ptr.zone[izone].ref_pt[irp].bs,
									nodesurfnormal,
									cosPtSurfIncidence,
									hit,
									domega,
									vis_trans,
									tvisincidence,
									wnorm,
									tfac,
									zenl,
									bldg_ptr.zone[izone].ref_pt[irp].direct_skycillum[iphs][iths],
									bldg_ptr.zone[izone].ref_pt[irp].direct_suncillum[iphs][iths],
									bldg_ptr.zone[izone].ref_pt[irp].direct_skyoillum,
									pofdmpfile
								)
								if iWndoContribRetVal < 0:
									if iWndoContribRetVal != -10:
										pofdmpfile << "ERROR: DElight Bad return from wndo_element_refpt_illum_contrib()\n"
										return -1
									else:
										iReturnVal = -10
							}	/* end of Sun Position Azimuth Loop */
						}	/* end of Sun Position Altitude Loop */
					}	/* end of Reference Point Loop */
					/* Interior Surface Loop */
					for iIntSurf in range(bldg_ptr.zone[izone].nsurfs):
						if iIntSurf == isurf:
							continue
						var dNodeSurfaceReflectance: Float64 = bldg_ptr.zone[izone].surf[iIntSurf].vis_refl
						/* Set node unit vector "surface" face normal (all nodes on a given surface have same normal). */
						for ic in range(NCOORDS):
							nodesurfnormal[ic] = bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[ic]
						/* Surface Nodal Patch Loop */
						for inode in range(bldg_ptr.zone[izone].surf[iIntSurf].nnodes):
							for ic in range(NCOORDS):
								node[ic] = bldg_ptr.zone[izone].surf[iIntSurf].node[inode][ic]
							/* Calc ray from node to wndo element */
							/* distance between node and element */
							disq = 0.0
							for ic in range(NCOORDS):
								ddis = rwin[ic] - node[ic]
								disq += ddis * ddis
							dis = sqrt(disq)
							/* unit vector along ray from node to element */
							for ic in range(NCOORDS):
								ray[ic] = (rwin[ic] - node[ic]) / dis
							/* Determine if ray intersects a zone-shade or bldg-shade. */
							/* NOTE: this includes all zone surfaces */
							/* contrary to DOE2 check of only "self-shade" */
							/* surfaces (in addition to zone and bldg shades). */
							/* dhitsh() sets HIT structure */
							dhitsh(hit, node, ray, bldg_ptr, izone, isurf, iIntSurf)
							/* Azm (-PI to PI) and alt (-PI/2 to PI/2) of ray (i.e., azm and alt of sky element) */
							/* Azm = 0 is along x-axis of bldg coord sys. */
							phray = asin(ray[2])
							if (ray[0] == 0.0) and (ray[1] == 0.0):
								thray = 0.0
							else:
								thray = atan2(ray[1], ray[0])
							/* Calc cos of angle between ray and window outward normal */
							cosWndoIncidence = ddot(wnorm, ray)
							/* Calc solid angle subtended by element wrt node */
							domega = bldg_ptr.zone[izone].surf[isurf].wndo[iw].node_areas[iWndoElement] * cosWndoIncidence / disq
							/* Calc tvis of glass for incidence angle */
							if (iGlass_Type_ID > 0) and (iGlass_Type_ID <= 11):
								tvisincidence = max(0.0, (cam1 + cosWndoIncidence * (cam2 + cosWndoIncidence * (cam3 + cosWndoIncidence * cam4))))
							elif (iGlass_Type_ID > 11) and (iGlass_Type_ID <= 10000):
								tvisincidence = vis_trans * fit4(cosWndoIncidence, W4vis_fit1, W4vis_fit2)
							elif iGlass_Type_ID > 10000:
								tvisincidence = POLYF(cosWndoIncidence, EPlusCoef)
							elif iGlass_Type_ID < 0:
								tvisincidence = vis_trans * max(0.0, (cosWndoIncidence * (E10coef1 + cosWndoIncidence * (E10coef2 + cosWndoIncidence * (E10coef3 + cosWndoIncidence * E10coef4)))))
							var cosPtSurfIncidence: Float64 = ddot(nodesurfnormal, ray)
							/* Sun Position Altitude Loop */
							for iphs in range(sun_ptr.nphs):
								/* Altitude of sun */
								phsun_deg = phsmin + iphs * phsdel
								phsun = phsun_deg * DTOR
								/* Get clear sky zenith luminance, moisture, */
								/* and turbidity coef for reference month. */
								dzenlm(zenl, tfac, IMREF, bldg_ptr, phsun)
								/* Sun Position Azimuth Loop */
								for iths in range(sun_ptr.nths):
									/* azm of sun in strange sun coord sys (0=East, counter-clockwise is positive) */
									thsun = (thsmin + iths * thsdel - 90.0) * DTOR + bldg_ptr.azm * DTOR
									/* Add contribution of current wndo element to */
									/* direct luminance at current surface node, */
									/* for current sky condition. */
									wndo_element_surfnode_lum_contrib(
										bldg_ptr,
										lib_ptr,
										izone,
										isurf,
										iIntSurf,
										iw,
										iWndoElement,
										thsun,
										phsun,
										thray,
										phray,
										iphs,
										iths,
										solic,
										node,
										nodesurfnormal,
										dNodeSurfaceReflectance,
										cosPtSurfIncidence,
										hit,
										domega,
										vis_trans,
										tvisincidence,
										wnorm,
										tfac,
										zenl,
										bldg_ptr.zone[izone].surf[iIntSurf].direct_skyclum[inode][iphs][iths],
										bldg_ptr.zone[izone].surf[iIntSurf].direct_sunclum[inode][iphs][iths],
										bldg_ptr.zone[izone].surf[iIntSurf].direct_skyolum[inode],
										pofdmpfile
									)
								}	/* end of Sun Position Azimuth Loop */
							}	/* end of Sun Position Altitude Loop */
						}	/* end of Surface Nodal Patch Loop */
					}	/* end of Interior Surface Loop */
				}	/* end of new Window Element Loop */
				bldg_ptr.zone[izone].surf[isurf].wndo[iw].WLCWNDOInit(bldg_ptr.zone[izone].max_grid_node_area)
			}	/* end of Window Loop */
			/* CFS Surface Loop */
			for icfs in range(bldg_ptr.zone[izone].surf[isurf].ncfs):
				var pCFSSystem4CFSSurf: CFSSystem = None
				var sCFSSystemType: String = bldg_ptr.zone[izone].surf[isurf].cfs[icfs].TypeName()
				for iCFSSys in range(bldg_ptr.zone[izone].surf[isurf].vpCFSSystem.size()):
					if bldg_ptr.zone[izone].surf[isurf].vpCFSSystem[iCFSSys].TypeName() == sCFSSystemType:
						pCFSSystem4CFSSurf = bldg_ptr.zone[izone].surf[isurf].vpCFSSystem[iCFSSys]
						break
				if not pCFSSystem4CFSSurf:
					pofdmpfile << "ERROR: DElight No CFSSystem of Type " << sCFSSystemType << " found for Surface " << bldg_ptr.zone[izone].surf[isurf].name << "\n"
					return -1
				var sphiralM: Int = 200
				var sphiralN: Int = 1000
				phsun_deg = phsmin
				var cSkyStr: String = ""
				strcpy(cSkyStr, "")
				snprintf(cSkyStr, 250, "SKY^GEN^CIEOVERCASTSKY^%6.2lf^%4.2lf", phsun_deg, bldg_ptr.zone[izone].surf[isurf].gnd_refl)
				var skyStr: String = cSkyStr
				var lpsky: LumParam
				if not SecretDecoderRing(lpsky, skyStr):
					pofdmpfile << "ERROR: DElight Incorrect Sky Generation Parameter - " << lpsky.BadName << "\n"
					return -1
				lpsky.btdfHSResIn = sphiralM
				lpsky.btdfHSResOut = sphiralN
				var skyOvercast: HemiSphiral = GenSky(lpsky)
				if skyOvercast.size() == 0:
					pofdmpfile << "ERROR: DElight HemiSphiral for Overcast Sky Size == ZERO\n"
					return -1
				var LumMapOvercast: HemiSphiral = pCFSSystem4CFSSurf.CFSLuminanceMap(skyOvercast, BGL.RHCoordSys3(bldg_ptr.zone[izone].surf[isurf].icsAxis(0), bldg_ptr.zone[izone].surf[isurf].icsAxis(1), bldg_ptr.zone[izone].surf[isurf].icsAxis(2)))
				if LumMapOvercast.size() == 0:
					pofdmpfile << "ERROR: DElight HemiSphiral CFS Luminance Map Size == ZERO\n"
					return -1
				bldg_ptr.zone[izone].surf[isurf].cfs[icfs].ResetLumMap(LumMapOvercast)
				/* Interior Surface Loop */
				for iIntSurf in range(bldg_ptr.zone[izone].nsurfs):
					if iIntSurf == isurf:
						continue
					var dNodeSurfaceReflectance: Float64 = bldg_ptr.zone[izone].surf[iIntSurf].vis_refl
					var v3SurfNormal: BGL.vector3 = BGL.vector3(bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[0], bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[1], bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[2])
					/* Surface Nodal Patch Loop */
					for inode in range(bldg_ptr.zone[izone].surf[iIntSurf].nnodes):
						var p3Node: BGL.point3 = BGL.point3(bldg_ptr.zone[izone].surf[iIntSurf].node[inode][0], bldg_ptr.zone[izone].surf[iIntSurf].node[inode][1], bldg_ptr.zone[izone].surf[iIntSurf].node[inode][2])
						var dSurfNodeArea: Float64 = bldg_ptr.zone[izone].surf[iIntSurf].node_areas[inode]
						var dCFSTotalIllum: Float64 = bldg_ptr.zone[izone].surf[isurf].cfs[icfs].TotRefPtIllum(v3SurfNormal, p3Node) * dSurfNodeArea
						bldg_ptr.zone[izone].surf[iIntSurf].TotDirectOvercastIllum += dCFSTotalIllum
						bldg_ptr.zone[izone].surf[iIntSurf].direct_skyolum[inode] += dCFSTotalIllum * dNodeSurfaceReflectance
					}	/* end of Surface Nodal Patch Loop */
				}	/* end of Interior Surface Loop */
				/* Set ref_pt "surface" normal unit vector (all ref_pts assumed horizontal facing upward). */
				var v3RefPtNormal: BGL.vector3 = BGL.vector3(0.0, 0.0, 1.0)
				/* Reference Point Loop */
				for irp in range(bldg_ptr.zone[izone].nrefpts):
					var p3RefPt: BGL.point3 = BGL.point3(bldg_ptr.zone[izone].ref_pt[irp].bs[0], bldg_ptr.zone[izone].ref_pt[irp].bs[1], bldg_ptr.zone[izone].ref_pt[irp].bs[2])
					var dCFSTotalIllum: Float64 = bldg_ptr.zone[izone].surf[isurf].cfs[icfs].TotRefPtIllum(v3RefPtNormal, p3RefPt)
					bldg_ptr.zone[izone].ref_pt[irp].direct_skyoillum += dCFSTotalIllum
				}	/* end of Reference Point Loop */
				/* Sun Position Altitude Loop */
				for iphs in range(sun_ptr.nphs):
					/* Altitude of sun */
					phsun_deg = phsmin + iphs * phsdel
					phsun = phsun_deg * DTOR
					/* Get clear sky zenith luminance, moisture, */
					/* and turbidity coef for reference month. */
					dzenlm(zenl, tfac, IMREF, bldg_ptr, phsun)
					/* Sun Position Azimuth Loop */
					for iths in range(sun_ptr.nths):
						/* azm of sun in strange sun coord sys (0=East, counter-clockwise is positive) */
						thsun = (thsmin + iths * thsdel - 90.0) * DTOR + bldg_ptr.azm * DTOR
						sphiralM = 200
						sphiralN = 2000 // BUT also see below for high altitudes
						var thsun_deg: Float64 = thsun / DTOR
						if thsun_deg < -180.0:
							thsun_deg += 360.0
						if thsun_deg > 180.0:
							thsun_deg -= 360.0
						if phsun_deg > 60:
							sphiralN = 6000
							if thsun_deg > 150.0:
								sphiralN = 10000
						strcpy(cSkyStr, "")
						snprintf(cSkyStr, 250, "SKY^GEN^CIECLEARSUN^%6.2lf^%6.2lf^%10.4lf^%10.4lf^%6.2lf^%6.2lf^%8.2lf^%4.2lf", phsun_deg, thsun_deg, solic[IMREF], tfac, bldg_ptr.atmmoi[IMREF], bldg_ptr.atmtur[IMREF], bldg_ptr.alt, bldg_ptr.zone[izone].surf[isurf].gnd_refl)
						skyStr = cSkyStr
						if not SecretDecoderRing(lpsky, skyStr):
							pofdmpfile << "ERROR: DElight Incorrect Sky Generation Parameter - " << lpsky.BadName << "\n"
							return -1
						lpsky.btdfHSResIn = sphiralM
						lpsky.btdfHSResOut = sphiralN
						var skyClearSun: HemiSphiral = GenSky(lpsky)
						if skyClearSun.size() == 0:
							pofdmpfile << "ERROR: DElight HemiSphiral for Clear Sun Size == ZERO\n"
							return -1
						var LumMapClearSun: HemiSphiral = pCFSSystem4CFSSurf.CFSLuminanceMap(skyClearSun, BGL.RHCoordSys3(bldg_ptr.zone[izone].surf[isurf].icsAxis(0), bldg_ptr.zone[izone].surf[isurf].icsAxis(1), bldg_ptr.zone[izone].surf[isurf].icsAxis(2)))
						if LumMapClearSun.size() == 0:
							pofdmpfile << "ERROR: DElight HemiSphiral for CFS Luminance Map Size == ZERO\n"
							return -1
						bldg_ptr.zone[izone].surf[isurf].cfs[icfs].ResetLumMap(LumMapClearSun)
						/* Interior Surface Loop */
						for iIntSurf in range(bldg_ptr.zone[izone].nsurfs):
							if iIntSurf == isurf:
								continue
							var dNodeSurfaceReflectance: Float64 = bldg_ptr.zone[izone].surf[iIntSurf].vis_refl
							var v3SurfNormal: BGL.vector3 = BGL.vector3(bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[0], bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[1], bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[2])
							/* Surface Nodal Patch Loop */
							for inode in range(bldg_ptr.zone[izone].surf[iIntSurf].nnodes):
								var p3Node: BGL.point3 = BGL.point3(bldg_ptr.zone[izone].surf[iIntSurf].node[inode][0], bldg_ptr.zone[izone].surf[iIntSurf].node[inode][1], bldg_ptr.zone[izone].surf[iIntSurf].node[inode][2])
								var dSurfNodeArea: Float64 = bldg_ptr.zone[izone].surf[iIntSurf].node_areas[inode]
								var dCFSTotalIllum: Float64 = bldg_ptr.zone[izone].surf[isurf].cfs[icfs].TotRefPtIllum(v3SurfNormal, p3Node) * dSurfNodeArea
								bldg_ptr.zone[izone].surf[iIntSurf].TotDirectSunCIllum[iphs][iths] += dCFSTotalIllum
								bldg_ptr.zone[izone].surf[iIntSurf].direct_sunclum[inode][iphs][iths] += dCFSTotalIllum * dNodeSurfaceReflectance
							}	/* end of Surface Nodal Patch Loop */
						}	/* end of Interior Surface Loop */
						/* Reference Point Loop */
						/* Set ref_pt "surface" normal unit vector (all ref_pts assumed horizontal facing upward). */
						var v3RefPtNormal: BGL.vector3 = BGL.vector3(0.0, 0.0, 1.0)
						for irp in range(bldg_ptr.zone[izone].nrefpts):
							var p3RefPt: BGL.point3 = BGL.point3(bldg_ptr.zone[izone].ref_pt[irp].bs[0], bldg_ptr.zone[izone].ref_pt[irp].bs[1], bldg_ptr.zone[izone].ref_pt[irp].bs[2])
							var dCFSTotalIllum: Float64 = bldg_ptr.zone[izone].surf[isurf].cfs[icfs].TotRefPtIllum(v3RefPtNormal, p3RefPt)
							bldg_ptr.zone[izone].ref_pt[irp].direct_suncillum[iphs][iths] += dCFSTotalIllum
						}	/* end of Reference Point Loop */
					}	/* end of Sun Position Azimuth Loop */
				}	/* end of Sun Position Altitude Loop */
				/* Sun Position Altitude Loop */
				for iphs in range(sun_ptr.nphs):
					/* Altitude of sun */
					phsun_deg = phsmin + iphs * phsdel
					phsun = phsun_deg * DTOR
					/* Get clear sky zenith luminance, moisture, */
					/* and turbidity coef for reference month. */
					dzenlm(zenl, tfac, IMREF, bldg_ptr, phsun)
					/* Sun Position Azimuth Loop */
					for iths in range(sun_ptr.nths):
						/* azm of sun in strange sun coord sys (0=East, counter-clockwise is positive) */
						thsun = (thsmin + iths * thsdel - 90.0) * DTOR + bldg_ptr.azm * DTOR
						sphiralM = 200
						sphiralN = 1000
						var thsun_deg: Float64 = thsun / DTOR
						if thsun_deg < -180.0:
							thsun_deg += 360.0
						if thsun_deg > 180.0:
							thsun_deg -= 360.0
						strcpy(cSkyStr, "")
						snprintf(cSkyStr, 250, "SKY^GEN^CIECLEARSKY^%6.2lf^%6.2lf^%10.6lf^%4.2lf", phsun_deg, thsun_deg, zenl, bldg_ptr.zone[izone].surf[isurf].gnd_refl)
						skyStr = cSkyStr
						if not SecretDecoderRing(lpsky, skyStr):
							pofdmpfile << "ERROR: DElight Incorrect Sky Generation Parameter - " << lpsky.BadName << "\n"
							return -1
						lpsky.btdfHSResIn = sphiralM
						lpsky.btdfHSResOut = sphiralN
						var skyClear: HemiSphiral = GenSky(lpsky)
						if skyClear.size() == 0:
							pofdmpfile << "ERROR: DElight HemiSphiral for Clear Sky Size == ZERO\n"
							return -1
						var LumMapClear: HemiSphiral = pCFSSystem4CFSSurf.CFSLuminanceMap(skyClear, BGL.RHCoordSys3(bldg_ptr.zone[izone].surf[isurf].icsAxis(0), bldg_ptr.zone[izone].surf[isurf].icsAxis(1), bldg_ptr.zone[izone].surf[isurf].icsAxis(2)))
						if LumMapClear.size() == 0:
							pofdmpfile << "ERROR: DElight HemiSphiral for CFS Luminance Map Size == ZERO\n"
							return -1
						bldg_ptr.zone[izone].surf[isurf].cfs[icfs].ResetLumMap(LumMapClear)
						/* Interior Surface Loop */
						for iIntSurf in range(bldg_ptr.zone[izone].nsurfs):
							if iIntSurf == isurf:
								continue
							var dNodeSurfaceReflectance: Float64 = bldg_ptr.zone[izone].surf[iIntSurf].vis_refl
							var v3SurfNormal: BGL.vector3 = BGL.vector3(bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[0], bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[1], bldg_ptr.zone[izone].surf[iIntSurf].inward_uvect[2])
							/* Surface Nodal Patch Loop */
							for inode in range(bldg_ptr.zone[izone].surf[iIntSurf].nnodes):
								var p3Node: BGL.point3 = BGL.point3(bldg_ptr.zone[izone].surf[iIntSurf].node[inode][0], bldg_ptr.zone[izone].surf[iIntSurf].node[inode][1], bldg_ptr.zone[izone].surf[iIntSurf].node[inode][2])
								var dSurfNodeArea: Float64 = bldg_ptr.zone[izone].surf[iIntSurf].node_areas[inode]
								var dCFSTotalIllum: Float64 = bldg_ptr.zone[izone].surf[isurf].cfs[icfs].TotRefPtIllum(v3SurfNormal, p3Node) * dSurfNodeArea
								bldg_ptr.zone[izone].surf[iIntSurf].TotDirectSkyCIllum[iphs][iths] += dCFSTotalIllum
								bldg_ptr.zone[izone].surf[iIntSurf].direct_skyclum[inode][iphs][iths] += dCFSTotalIllum * dNodeSurfaceReflectance
							}	/* end of Surface Nodal Patch Loop */
						}	/* end of Interior Surface Loop */
						/* Reference Point Loop */
						/* Set ref_pt "surface" normal unit vector (all ref_pts assumed horizontal facing upward). */
						var v3RefPtNormal: BGL.vector3 = BGL.vector3(0.0, 0.0, 1.0)
						for irp in range(bldg_ptr.zone[izone].nrefpts):
							var p3RefPt: BGL.point3 = BGL.point3(bldg_ptr.zone[izone].ref_pt[irp].bs[0], bldg_ptr.zone[izone].ref_pt[irp].bs[1], bldg_ptr.zone[izone].ref_pt[irp].bs[2])
							var dCFSTotalIllum: Float64 = bldg_ptr.zone[izone].surf[isurf].cfs[icfs].TotRefPtIllum(v3RefPtNormal, p3RefPt)
							bldg_ptr.zone[izone].ref_pt[irp].direct_skycillum[iphs][iths] += dCFSTotalIllum
						}	/* end of Reference Point Loop */
					}	/* end of Sun Position Azimuth Loop */
				}	/* end of Sun Position Altitude Loop */
			}	/* end of CFS Surface Loop */
		}	/* end of Exterior Surface Loop */
		var iSliteInterRflRetVal: Int
		if (slite_interreflect(bldg_ptr, lib_ptr, sun_ptr, iIterations, pofdmpfile)) < 0:
			if iSliteInterRflRetVal != -10:
				pofdmpfile << "ERROR: DElight Bad return from slite_interreflect()\n"
				return -1
			else:
				iReturnVal = -10
		for irp in range(bldg_ptr.zone[izone].nrefpts):
			if bldg_ptr.hillumskyo[0]:
				bldg_ptr.zone[izone].ref_pt[irp].dfskyo = bldg_ptr.zone[izone].ref_pt[irp].skyoillum / bldg_ptr.hillumskyo[0]
			for iphs in range(sun_ptr.nphs):
				for iths in range(sun_ptr.nths):
					if bldg_ptr.hillumskyc[iphs]:
						bldg_ptr.zone[izone].ref_pt[irp].dfsky[iphs][iths] = bldg_ptr.zone[izone].ref_pt[irp].skycillum[iphs][iths] / bldg_ptr.hillumskyc[iphs]
					if bldg_ptr.hillumsunc[iphs]:
						bldg_ptr.zone[izone].ref_pt[irp].dfsun[iphs][iths] = bldg_ptr.zone[izone].ref_pt[irp].suncillum[iphs][iths] / bldg_ptr.hillumsunc[iphs]
	}	/* end of Lighting Zone Loop */
	return iReturnVal
}
/************************** subroutine wndo_element_refpt_illum_contrib *************************/
/* Adds contribution of current window element to direct (initial) illuminance (lm/ft2) at */
/* current reference point. */
/* Modified from earlier version of wndo_element_contrib() */
/*   Key modifications are: */
/*       - remove glare related calculations */
/*       - replace references to ray[2] (i.e., cos(angle of incidence) for horiz surf) by cosSurfIncidence */
/*   8/2000 modifications: */
/*       - separate reference point illuminance calc from surface node luminance calculation */
/************************************************************************************************/
/* C Language Implementation based on modified DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************** subroutine wndo_element_refpt_illum_contrib *************************/
def wndo_element_refpt_illum_contrib(
	bldg_ptr: BLDG,		/* pointer to bldg structure */
	lib_ptr: LIB,		/* pointer to lib structure */
	izone: Int,			/* current zone index */
	iWndoSurf: Int,		/* current index for surface containing Window */
	iNodeSurf: Int,		/* current index for surface containing Node, Not Applicable (iWndoSurf==iNodeSurf */
	iwndo: Int,			/* current window index */
	iWndoElement: Int,	/* window element index */
	thsun: Float64,		/* sun azm (radians) */
	phsun: Float64,		/* sun alt (radians) */
	thray: Float64,		/* sky element azm angle */
	phray: Float64,		/* sky element alt angle */
	iphs: Int,			/* sun alt index */
	iths: Int,			/* sun azm index */
	solic: Float64[MONTHS],	/* extraterrestrial irrad for 1st of each month (0 to 11) */
	node: Float64[NCOORDS],	/* coords of refpt */
	nodesurfnormal: Float64[NCOORDS],	/* INWARD normal unit vector from face of refpt */
	cosPtSurfIncidence: Float64,	/* cos(angle of incidence) of vector from refpt (on horiz plane) to wndo element */
	hit_ptr: HIT,			/* hit structure pointer for ray from refpt to wndo element */
	domega: Float64,			/* solid angle subtended by window element wrt ref_pt */
	vis_trans: Float64,		/* tvis of glass for normal incidence angle */
	tvisincidence: Float64,	/* tvis of glass for incidence angle */
	wnorm: Float64[NCOORDS],	/* window outward normal vector */
	tfac: Float64,			/* turbidity factor */
	zenl: Float64,			/* zenith luminance */
	pdirect_skycillum: Float64&,	/* ptr to direct illuminance from sky (fc) - clear */
	pdirect_suncillum: Float64&,	/* ptr to direct illuminance from sun (fc) - clear */
	pdirect_skyoillum: Float64&,	/* ptr to direct illuminance from sky (fc) - overcast */
	pofdmpfile: ofstream&)		/* ptr to LBLDLL error dump file */
-> Int
{
	var elum: Float64, dedir: Float64;		/* luminance calc vars */
	var raycos: Float64[NCOORDS];	/* unit vector to sun from anywhere in the bldg */
	var cosi: Float64;			/* cos(incidence) of raycos onto wndo */
	var tviss: Float64;			/* vis trans for angle of incidence of raycos through wndo */
	var tvis1: Float64;			/* dummy vis trans for diffuse glazing calc using wndo luminance (==1.0) */
	var dnsoli: Float64;			/* dnsol() return value */
	var rchit: HIT;				/* bldg-shade hit structure for dhitsh() */
	/* CASE 1 - Window without shades (i.e., clear glazing) */
	if bldg_ptr.zone[izone].surf[iWndoSurf].wndo[iwndo].shade_flag == 0:
		/* If ray hits front of global shading surface, */
		/* add contrib of shading surf luminance (cd/ft2) */
		/* to illum at ref_pt.  */
		if hit_ptr.ihit == 4:
			pdirect_skycillum += bldg_ptr.bshade[hit_ptr.hitshade].skylum[iphs][iths] * domega * tvisincidence * cosPtSurfIncidence
			pdirect_suncillum += bldg_ptr.bshade[hit_ptr.hitshade].sunlum[iphs][iths] * domega * tvisincidence * cosPtSurfIncidence
			if (iphs == 0) and (iths == 0):
				pdirect_skyoillum += bldg_ptr.bshade[hit_ptr.hitshade].ovrlum * domega * tvisincidence * cosPtSurfIncidence
		/* If ray hits exterior of zone surface, */
		/* add contrib of zone surface luminance (cd/ft2) */
		/* to illum at ref_pt.  */
		if hit_ptr.ihit == 2:
			pdirect_skycillum += bldg_ptr.zone[hit_ptr.hitzone].surf[hit_ptr.hitshade].skylum[iphs][iths] * domega * tvisincidence * cosPtSurfIncidence
			pdirect_suncillum += bldg_ptr.zone[hit_ptr.hitzone].surf[hit_ptr.hitshade].sunlum[iphs][iths] * domega * tvisincidence * cosPtSurfIncidence
			if (iphs == 0) and (iths == 0):
				pdirect_skyoillum += bldg_ptr.zone[hit_ptr.hitzone].surf[hit_ptr.hitshade].ovrlum * domega * tvisincidence * cosPtSurfIncidence
		/* If shading surface not hit, add contrib of sky (cd/ft2) if it is visible from ref pt (phray > 0.0). */
		if hit_ptr.ihit == 0:
			/* for clear sky */
			if phray > 0.0:
				elum = dskylu(0, thray, phray, thsun, phsun, zenl)
				dedir = elum * domega * tvisincidence * cosPtSurfIncidence
				pdirect_skycillum += dedir
			/* for overcast sky */
			if (iphs == 0) and (iths == 0):
				if phray > 0.0:
					elum = dskylu(1, thray, phray, thsun, phsun, zenl)
					dedir = elum * domega * tvisincidence * cosPtSurfIncidence
					pdirect_skyoillum += dedir
		/* Illuminance from (unreflected) direct sun. */
		/* (calculated only once per wndo for each ref pt) */
		if iWndoElement == 0:
			/* unit vector to sun from anywhere in the bldg */
			raycos[0] = cos(phsun) * cos(thsun)
			raycos[1] = cos(phsun) * sin(thsun)
			raycos[2] = sin(phsun)
			/* is sun on front side of current window? */
			cosi = ddot(wnorm, raycos)
			if cosi > 0.0:
				/* does raycos from current ref_pt pass thru window? */
				var pt3Node: BGL.point3 = BGL.point3(node[0], node[1], node[2])	//	center of box
				var vRayDir: BGL.vector3 = BGL.vector3(raycos[0], raycos[1], raycos[2
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
from vector import vector
from map import map
from fstream import ofstream
from cstring import *
from limits import *
from BGL import *
from CONST.H import *
from DBCONST.H import *
from DEF.H import *
from NodeMesh2.h import *
from WLCSurface.h import *
from helpers.h import *
from hemisphiral.h import *
from btdf.h import *
from CFSSystem.h import *
from CFSSurface.h import *
from DOE2DL.H import *
from geom.h import *
from struct.h import *
from GeomMesh.h import *
/****************************** subroutine geometrans *****************************/
/* Translates user oriented bldg geometry to bldg (i.e., global) coord system. */
/* The bldg structure must be fully initialized prior to this call (except for zone shades). */
/* This routine transforms all bldg surfaces (walls, windows, bshades) in one call. */
/* Zone shades (i.e., overhangs and fins) are created here from window and host surface data. */
/* Converted and modified from DOE2.1D FORTRAN code in GEOPR1(). */
/* Modifications included to support Superlite 3.0 radiosity algorithms. */
/****************************** subroutine geometrans *****************************/
def geometrans(
	bldg_ptr: Pointer[BLDG],			/* bldg structure pointer */
	num_nodes: Int32,			/* total number of nodes on surface */
	num_wnodes: Int32,			/* total number of nodes on window */
	pofdmpfile: Pointer[ofstream])	/* ptr to LBLDLL error dump file */ -> Int32
{
	var iz: Int32, is: Int32, iw: Int32, izs: Int32, ish: Int32, irp: Int32, lzs: Int32;/* indexes */
	var height: Float64, width: Float64, azm: Float64, tilt: Float64, azm_zone: Float64, xtrans: Float64, ytrans: Float64;	/* parameter holders */
	/* Zone loop */
	for iz in range(0, bldg_ptr[].nzones) {
		/* set azm_zone for future use */
		azm_zone = bldg_ptr[].zone[iz][].azm;
		/* Surface loop */
		for is in range(0, bldg_ptr[].zone[iz][].nsurfs) {
			/* radiosity modification (move Window loop to allow subsequent */
			/* identification of surface nodes within window cutout) */
			/* Window loop */
			for iw in range(0, bldg_ptr[].zone[iz][].surf[is][].nwndos) {
				/* calculate derived quantities for window */
				/* locate all window vertices in surface coord system */
				height = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].height;
				width = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].width;
				rectan(height,width,bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert);
				xtrans = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].origin[X];
				ytrans = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].origin[Y];
				transl(xtrans,ytrans,bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert);
				/* locate all window vertices in zone coord system */
				azm = bldg_ptr[].zone[iz][].surf[is][].azm_zs;
				tilt = bldg_ptr[].zone[iz][].surf[is][].tilt_zs;
				walloc(bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert,bldg_ptr[].zone[iz][].surf[is][].origin,azm,tilt);
				/* locate all window vertices in bldg coord system */
				zonloc(bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert,bldg_ptr[].zone[iz][].origin,azm_zone);
				/* radiosity modification */
				/* calculate window nodal area and coordinates in bldg coord sys */
				wndo_nodal_calcs(bldg_ptr,num_wnodes,iz,is,iw);
                /* Create zone shades for shaded windows. */
				for lzs in range(0, NZSHADES) {
					/* Does this window have zone shades (overhang/fins)? */
					if (bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].zshade_x[lzs] > 0.0) {
						/* Check MAX zone shades. */
						if (bldg_ptr[].zone[iz][].nzshades < MAX_ZONE_SHADES) {
							/* Create new zshade. */
							izs = bldg_ptr[].zone[iz][].nzshades;
							bldg_ptr[].zone[iz][].zshade[izs] = new ZSHADE;
							if (bldg_ptr[].zone[iz][].zshade[izs] == None) {
								pofdmpfile[].write("ERROR: DElight Insufficient memory for ZONE SHADE allocation.\n");
								return(-1);
							}
							/* Initialize new zshade. */
							struct_init("ZSHADE",(bldg_ptr[].zone[iz][].zshade[izs] as Pointer[UInt8]));
							/* Calc zshade vertices. */
							zshade_calc_verts(bldg_ptr,iz,is,iw,izs,lzs);
							/* Increment number of zone shades. */
							bldg_ptr[].zone[iz][].nzshades += 1;
						}
						else {
							pofdmpfile[].write("ERROR: DElight Maximum number of zone shades has been exceeded!\n");
							return (-1);
						}
					}
				}
			}
			/* calculate derived quantities for surface */
			/* locate all surface vertices in surface coord system */
			height = bldg_ptr[].zone[iz][].surf[is][].height;
			width = bldg_ptr[].zone[iz][].surf[is][].width;
			rectan(height,width,bldg_ptr[].zone[iz][].surf[is][].vert);
			/* locate all surface vertices in zone coord system */
			azm = bldg_ptr[].zone[iz][].surf[is][].azm_zs;
			tilt = bldg_ptr[].zone[iz][].surf[is][].tilt_zs;
			walloc(bldg_ptr[].zone[iz][].surf[is][].vert,bldg_ptr[].zone[iz][].surf[is][].origin,azm,tilt);
			/* locate all surface vertices in bldg coord system */
			zonloc(bldg_ptr[].zone[iz][].surf[is][].vert,bldg_ptr[].zone[iz][].origin,azm_zone);
			var p3TmpPt: BGL.point3;
			for iVert in range(0, NVERTS) {
				p3TmpPt = BGL.point3(bldg_ptr[].zone[iz][].surf[is][].vert[0][iVert], bldg_ptr[].zone[iz][].surf[is][].vert[1][iVert], bldg_ptr[].zone[iz][].surf[is][].vert[2][iVert]);
                bldg_ptr[].zone[iz][].surf[is][].vPt3VerticesWCS_OCCW.push_back(p3TmpPt);
			}
			/* calculate surface azimuth and tilt in bldg coord system */
			apol(bldg_ptr[].zone[iz][].surf[is][].vert,&bldg_ptr[].zone[iz][].surf[is][].azm_bs,&bldg_ptr[].zone[iz][].surf[is][].tilt_bs);
			/* radiosity modification */
			/* calculate surface direction cosine values (slite) in bldg coord sys */
			dircos_calc_new(bldg_ptr,iz,is);
			/* radiosity modification */
			/* calculate nodal area and coordinates in bldg coord sys */
			nodal_calcs(bldg_ptr,num_nodes,iz,is);
			/* radiosity modification */
			/* Calc outward (DOE2) and inward (Slite) unit vector surface normals in DOE2 BCS */
			/* Surface vertices in DOE2 convention order. */
			var icoord: Int32;	// loop index
			var dist10: Float64, dist12: Float64;	// distances between vertices
			var svert0: StaticArray[Float64, NCOORDS], svert1: StaticArray[Float64, NCOORDS], svert2: StaticArray[Float64, NCOORDS];	// vertex coords
			var svect10: StaticArray[Float64, NCOORDS], svect12: StaticArray[Float64, NCOORDS];	// vectors
			for icoord in range(0, NCOORDS) {
				svert0[icoord] = bldg_ptr[].zone[iz][].surf[is][].vert[icoord][0];
				svert1[icoord] = bldg_ptr[].zone[iz][].surf[is][].vert[icoord][1];
				svert2[icoord] = bldg_ptr[].zone[iz][].surf[is][].vert[icoord][2];
			}
			/* Unit vectors from surface vertex 1 to 0 and 1 to 2. */
			dist10 = 0.;
			dist12 = 0.;
			for icoord in range(0, NCOORDS) {
				svect10[icoord] = svert0[icoord] - svert1[icoord];
				svect12[icoord] = svert2[icoord] - svert1[icoord];
				dist10 += svect10[icoord] * svect10[icoord];
				dist12 += svect12[icoord] * svect12[icoord];
			}
			dist10 = sqrt(dist10);
			dist12 = sqrt(dist12);
			for icoord in range(0, NCOORDS) {
				svect10[icoord] /= dist10;
				svect12[icoord] /= dist12;
			}
			/* Outward facing unit vector normal to surface (i.e., DOE2 outward normal) */
			dcross(svect12,svect10,bldg_ptr[].zone[iz][].surf[is][].outward_uvect);
			/* Inward facing unit vector normal to surface (i.e., Slite inward normal) */
			dcross(svect10,svect12,bldg_ptr[].zone[iz][].surf[is][].inward_uvect);
		}
		/* Reference Point loop */
		for irp in range(0, bldg_ptr[].zone[iz][].nrefpts) {
			/* locate reference point in bldg coord system */
			refptloc(bldg_ptr[].zone[iz][].ref_pt[irp],bldg_ptr[].zone[iz][].origin,azm_zone);
		}
	}
	/* Building Shades loop */
	for ish in range(0, bldg_ptr[].nbshades) {
		/* calculate derived quantities for building shade */
		/* locate all building shade vertices in shade-surface coord system */
		height = bldg_ptr[].bshade[ish][].height;
		width = bldg_ptr[].bshade[ish][].width;
		rectan(height,width,bldg_ptr[].bshade[ish][].vert);
		/* locate all building shade vertices in bldg coord system */
		azm = bldg_ptr[].bshade[ish][].azm;
		tilt = bldg_ptr[].bshade[ish][].tilt;
		walloc(bldg_ptr[].bshade[ish][].vert,bldg_ptr[].bshade[ish][].origin,azm,tilt);
	}
	return(0);
}
/****************************** subroutine rectan *****************************/
/* Locates the vertices of a rectangular surface in the surface coordinate system. */
/* Uses height and width of rectangle and origin coordinates. */
/* Vertices are numbered counterclockwise from upper left viewed from outside. */
/* The second vertex (index 1) is therefore the origin. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine rectan *****************************/
def rectan(
	height: Float64,	/* rectangle height */
	width: Float64,	/* rectangle width */
	rectangle: Pointer[StaticArray[StaticArray[Float64, NVERTS], NCOORDS]])	/* rectangle vertices[coordinate][vertex] */ -> Int32
{
	rectangle[][X][0] = 0.;		/* x */ /* upper left vertex */
	rectangle[][Y][0] = height;	/* y */
	rectangle[][Z][0] = 0.;		/* z */
	rectangle[][X][1] = 0.;		/* x */ /* lower left vertex (origin) */
	rectangle[][Y][1] = 0.;		/* y */
	rectangle[][Z][1] = 0.;		/* z */
	rectangle[][X][2] = width;	/* x */ /* lower right vertex */
	rectangle[][Y][2] = 0.;		/* y */
	rectangle[][Z][2] = 0.;		/* z */
	rectangle[][X][3] = width;	/* x */ /* upper right vertex */
	rectangle[][Y][3] = height;	/* y */
	rectangle[][Z][3] = 0.;		/* z */
	return(0);
}
/****************************** subroutine transl *****************************/
/* Locates the vertices of sub-surfaces in the surface coordinate system. */
/* Uses vertices established in rectan() and origin x and y coords of sub-surf. */
/* Vertices are numbered counterclockwise from upper left viewed from outside. */
/* The second vertex (index 1) is therefore the sub-surface origin. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine transl *****************************/
def transl(
	xtrans: Float64,	/* sub-surface translation on the x axis */
	ytrans: Float64,	/* sub-surface translation on the y axis */
	subsurf: Pointer[StaticArray[StaticArray[Float64, NVERTS], NCOORDS]])	/* sub-surface vertices[coordinate][vertex] */ -> Int32
{
	var ivert: Int32;	/* vertex index */
	for ivert in range(0, NVERTS) {
		subsurf[][X][ivert] += xtrans;
		subsurf[][Y][ivert] += ytrans;
	}
	return(0);
}
/****************************** subroutine walloc *****************************/
/* Locates the vertices of walls and sub-surfaces in the zone coord system. */
/* Locates the vertices of building shades in the bldg coord system. */
/* Uses vertices established in transl(), and host surf origin, tilt and azimuth. */
/* Vertices are numbered counterclockwise from upper left viewed from outside. */
/* The second vertex (index 1) is therefore the surface origin. */
/* NOTE: when AZM=TILT=surf_origin[*]=0, vert[x]=-surf[x] and vert[y]=-surf[y]. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine walloc *****************************/
def walloc(
	vert: Pointer[StaticArray[StaticArray[Float64, NVERTS], NCOORDS]],/* vertices to be located */
	surf_origin: Pointer[StaticArray[Float64, NCOORDS]],	/* host surface origin coords */
	azm: Float64,	/* host surface azimuth */
	tilt: Float64)	/* host surface tilt */ -> Int32
{
	var ivert: Int32;	/* vertex index */
	var oldx: Float64, oldy: Float64;	/* incoming x and y coords of each vertex */
	var azm_rad: Float64, tilt_rad: Float64;	/* azm and tilt in radians */
	var cosazm: Float64, sinazm: Float64, costilt: Float64, sintilt: Float64;
	azm_rad = azm * DTOR;
	tilt_rad = tilt * DTOR;
	cosazm = cos(azm_rad);
	sinazm = sin(azm_rad);
	costilt = cos(tilt_rad);
	sintilt = sin(tilt_rad);
	for ivert in range(0, NVERTS) {
		oldx = vert[][X][ivert];
		oldy = vert[][Y][ivert];
		vert[][X][ivert] = surf_origin[][X] - oldx * cosazm - oldy * sinazm * costilt;
		vert[][Y][ivert] = surf_origin[][Y] + oldx * sinazm - oldy * cosazm * costilt;
		vert[][Z][ivert] = surf_origin[][Z] + oldy * sintilt;
	}
	return(0);
}
/****************************** subroutine zonloc *****************************/
/* Transform the vertices of walls and sub-surfaces to the bldg coord system. */
/* Uses vertices established in walloc(), and zone origin and azimuth. */
/* Vertices are numbered counterclockwise from upper left viewed from outside. */
/* The second vertex (index 1) is therefore the surface origin. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine zonloc *****************************/
def zonloc(
	vert: Pointer[StaticArray[StaticArray[Float64, NVERTS], NCOORDS]],/* vertices to be transformed */
	zone_origin: Pointer[StaticArray[Float64, NCOORDS]],	/* zone origin coords */
	azm: Float64)					/* zone azimuth */ -> Int32
{
	var ivert: Int32;			/* vertex index */
	var oldx: Float64, oldy: Float64;	/* incoming x and y coords of each vertex */
	var azm_rad: Float64;		/* azm in radians */
	var cosazm: Float64, sinazm: Float64;
	azm_rad = azm * DTOR;
	cosazm = cos(azm_rad);
	sinazm = sin(azm_rad);
	for ivert in range(0, NVERTS) {
		oldx = vert[][X][ivert];
		oldy = vert[][Y][ivert];
		vert[][X][ivert] = zone_origin[][X] + oldx * cosazm + oldy * sinazm;
		vert[][Y][ivert] = zone_origin[][Y] - oldx * sinazm + oldy * cosazm;
		vert[][Z][ivert] += zone_origin[][Z];
	}
	return(0);
}
/****************************** subroutine refptloc *****************************/
/* Transform the zone system coords of a reference point into the bldg coord system. */
/* Uses zone sys coords, zone origin and zone azimuth. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine refptloc *****************************/
def refptloc(
	ref_pt: Pointer[REFPT],	/* ref_pt pointer */
	zone_origin: Pointer[StaticArray[Float64, NCOORDS]],	/* zone origin coords */
	azm_zone: Float64)				/* zone azimuth */ -> Int32
{
	var azm_rad: Float64;		/* zone azm in radians */
	var cosazm: Float64, sinazm: Float64;
	azm_rad = azm_zone * DTOR;
	cosazm = cos(azm_rad);
	sinazm = sin(azm_rad);
	ref_pt[].bs[X] = zone_origin[][X] + ref_pt[].zs[X] * cosazm + ref_pt[].zs[Y] * sinazm;
	ref_pt[].bs[Y] = zone_origin[][Y] - ref_pt[].zs[X] * sinazm + ref_pt[].zs[Y] * cosazm;
	ref_pt[].bs[Z] = zone_origin[][Z] + ref_pt[].zs[Z];
	return(0);
}
/****************************** subroutine apol *****************************/
/* Calculates surface azimuth and tilt of surface in the bldg coord system. */
/* Uses vertices established in zonloc(). */
/* NOTE: aparea calculation in DOE2.1D code has been removed from this routine. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine apol *****************************/
def apol(
	vert: Pointer[StaticArray[StaticArray[Float64, NVERTS], NCOORDS]],/* surface vertices in bldg coord system */
	apazm_ptr: Pointer[Float64],	/* surface azimuth_ptr with respect to bldg coord system */
	aptilt_ptr: Pointer[Float64])	/* surface tilt_ptr with respect to bldg coord system */ -> Int32
{
	var ivert: Int32;						/* vertex index */
	var xcomp: Float64, ycomp: Float64, zcomp: Float64;		/* local intermediate vars */
	var x0: Float64, y0: Float64, z0: Float64, x1: Float64, y1: Float64, z1: Float64;	/* local intermediate vars */
	var azm: Float64, tilt: Float64, proj: Float64, area: Float64;	/* local intermediate vars */
	xcomp = 0.;
	ycomp = 0.;
	zcomp = 0.;
	x0 = vert[][X][NVERTS-1];
	y0 = vert[][Y][NVERTS-1];
	z0 = vert[][Z][NVERTS-1];
	for ivert in range(0, NVERTS) {
		x1 = vert[][X][ivert];
		y1 = vert[][Y][ivert];
		z1 = vert[][Z][ivert];
		xcomp += y0 * z1 - y1 * z0;
		ycomp += z0 * x1 - z1 * x0;
		zcomp += x0 * y1 - x1 * y0;
		x0 = x1;
		y0 = y1;
		z0 = z1;
	}
	area = sqrt(xcomp*xcomp+ycomp*ycomp+zcomp*zcomp)/2.;
	/* NOTE: apazm and aptilt are inited to 0.0 in struct_init call */
	if (area == 0.0) return(0);
	tilt = acos(zcomp / (2.0 * area));
	proj = sqrt(xcomp*xcomp + ycomp*ycomp);
	if ((proj - (0.0001 * area)) > 0.0) {
		if (xcomp < 0.0) {
			if (ycomp < 0.0) {
				azm = 3.1416 + asin(-xcomp / proj);
			}
			else {
				azm = 4.7124 + asin(ycomp / proj);
			}
		}
		else {
			if (ycomp < 0.0) {
				azm = 1.5708 + asin(-ycomp / proj);
			}
			else {
				azm = asin(xcomp / proj);
			}
		}
	}
	else {
		azm = 0.0;
	}
	apazm_ptr[] = azm / DTOR;
	aptilt_ptr[] = tilt / DTOR;
	return(0);
}
/****************************** subroutine dcross *****************************/
/* Calculates cross product between vectors vecta and vectb. */
/* This (vectc) is the vector normal for surfaces for which vecta and vectb */
/* have been calculated from DOE2 BCS surface vertices 0, 1 (origin), and 2. */
/* If vecta is from vertex 1 to 2 (along width edge), and vectb is from 1 to 0 (along height edge), */
/*		then vectc is DOE2 outward normal. */
/* If vecta is from vertex 1 to 0, and vectb is from 1 to 2, */
/*		then vectc is Superlite inward normal. */
/* If vecta and vectb are unit vectors, then (vectc) is a unit vector normal. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine dcross *****************************/
def dcross(
	vecta: Pointer[StaticArray[Float64, NCOORDS]],	/* vector coordinates (X=x, Y=y, Z=z) */
	vectb: Pointer[StaticArray[Float64, NCOORDS]],	/* vector coordinates (X=x, Y=y, Z=z) */
	vectc: Pointer[StaticArray[Float64, NCOORDS]])	/* return vector coordinates (X=x, Y=y, Z=z) */ -> Int32
{
	vectc[][X] = vecta[][Y] * vectb[][Z] - vecta[][Z] * vectb[][Y];
	vectc[][Y] = vecta[][Z] * vectb[][X] - vecta[][X] * vectb[][Z];
	vectc[][Z] = vecta[][X] * vectb[][Y] - vecta[][Y] * vectb[][X];
	return(0);
}
/****************************** function ddot *****************************/
/* Calculates dot product of vectors vecta and vectb. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** function ddot *****************************/
def ddot(
	vecta: Pointer[StaticArray[Float64, NCOORDS]],	/* vector coordinates (X=x, Y=y, Z=z) */
	vectb: Pointer[StaticArray[Float64, NCOORDS]])	/* vector coordinates (X=x, Y=y, Z=z) */ -> Float64
{
	var ddotval: Float64;	/* returned value */
	ddotval = vecta[][X] * vectb[][X] + vecta[][Y] * vectb[][Y] + vecta[][Z] * vectb[][Z];
	return(ddotval);
}
/****************************** subroutine dpierc *****************************/
/* Called by dhitsh() */
/* Returns 0 if the line thru point r1 in direction of unit vector rn does not */
/* intersect the building shade rectangle defined by vertices v1, v2 and v3, */
/* with normal (v3-v2)*(v1-v2). */
/* Returns 1 (-1) if front (back) of the rectangle is intersected. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine dpierc *****************************/
def dpierc(
	ipierc_ptr: Pointer[Int32],	/* return value (0=no intersect, 1=front, -1=back) */
	v1: Pointer[StaticArray[Float64, NCOORDS]],	/* bldg-shade vertex coordinates (X=x, Y=y, Z=z) */
	v2: Pointer[StaticArray[Float64, NCOORDS]],	/* bldg-shade vertex coordinates (X=x, Y=y, Z=z) */
	v3: Pointer[StaticArray[Float64, NCOORDS]],	/* bldg-shade vertex coordinates (X=x, Y=y, Z=z) */
	r1: Pointer[StaticArray[Float64, NCOORDS]],	/* point coordinates (X=x, Y=y, Z=z) */
	rn: Pointer[StaticArray[Float64, NCOORDS]])	/* unit vector coordinates (X=x, Y=y, Z=z) */ -> Int32
{
	var icoord: Int32;		/* coordinate index */
	var vecta: StaticArray[Float64, NCOORDS];	/* vector coordinates (X=x, Y=y, Z=z) */
	var vectb: StaticArray[Float64, NCOORDS];	/* vector coordinates (X=x, Y=y, Z=z) */
	var vectc: StaticArray[Float64, NCOORDS];	/* vector coordinates (X=x, Y=y, Z=z) */
	var vectba: StaticArray[Float64, NCOORDS];	/* vector coordinates (X=x, Y=y, Z=z) */
	var f1: Float64, f2: Float64;	/* scale factors */
	var scale: Float64;
	var dotcb: Float64, dotca: Float64;	/* ddot() return values */
	ipierc_ptr[] = 0;
	/* vectors from v2 to v1 and v2 to v3 */
	for icoord in range(X, NCOORDS) {
		vecta[icoord] = v1[][icoord] - v2[][icoord];
		vectb[icoord] = v3[][icoord] - v2[][icoord];
	}
	/* vector normal to rectangle */
	dcross(vectb, vecta, vectba);
	/* scale factor */
	f1 = 0.;
	f2 = 0.;
	for icoord in range(X, NCOORDS) {
		f1 += vectba[icoord] * (v2[][icoord] - r1[][icoord]);
		f2 += vectba[icoord] * rn[][icoord];
	}
	if (f2 == 0.0) return(0);
	scale = f1 / f2;
	if (scale <= 0.0) return(0);
	/* vector-c from v2 to point that ray along rn intersects plane of rectangle */
	for icoord in range(X, NCOORDS)
		vectc[icoord] = r1[][icoord] + rn[][icoord] * scale - v2[][icoord];
	/* intersection point, c, inside rectangle tests */
	dotcb = ddot(vectc, vectb);
	if (dotcb < 0.0) return(0);
	if (dotcb > ddot(vectb,vectb)) return(0);
	dotca = ddot(vectc,vecta);
	if (dotca < 0.0) return(0);
	if (dotca > ddot(vecta,vecta)) return(0);
	ipierc_ptr[] = 1;
	if (ddot(rn,vectba) > 0.0) ipierc_ptr[] = -1;
	return(0);
}
/****************************** subroutine dthlim *****************************/
/* Determines limits of integration of sky azimuth angle for a surface */
/* receiving light from sky elements of altitude phsky. */
/* The normal to the receiving surface has azimuth thsur and altitude phsur. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine dthlim *****************************/
def dthlim(
	thmin_ptr: Pointer[Float64],	/* return value of lower limit of integration */
	thmax_ptr: Pointer[Float64],	/* return value of upper limit of integration */
	phsky: Float64,	/* altitude of sky elements (radians) */
	thsur: Float64,	/* azimuth of receiving surface normal (radians) */
	phsur: Float64)	/* altitude of receiving surface normal (radians) */ -> Int32
{
	var tltsur: Float64;
	var avar: Float64;
	if (fabs(phsur) >= 0.035) {
		tltsur = PIOVR2 - phsur;
		if ((phsky > tltsur) || (fabs(phsky) > (PI - tltsur))) {
			thmin_ptr[] = -PI;
			thmax_ptr[] = PI;
			return(0);
		}
		avar = -tan(phsky) / tan(tltsur);
		avar = fabs(acos(avar));
		thmin_ptr[] = thsur - avar;
		thmax_ptr[] = thsur + avar;
		return(0);
	}
	else {	/* surface is within 2 degrees of vertical */
		thmin_ptr[] = thsur - PIOVR2;
		thmax_ptr[] = thsur + PIOVR2;
		return(0);
	}
}
/****************************** function dhitsh *****************************/
/* Determines if a ray from r1 in the direction of rn intersects a shading surface. */
/* Returns hit flag, ihit: 0=no hit, 1=zone-shade is hit, */
/* 2=zone surface is hit on the exterior (the side with luminance), */
/* 3=building-shade is hit from behind, 4=building-shade is hit from the front. */
/* If 2 then returns index value of zone surface that was hit. */
/* If 3 or 4, then returns index value of building-shade that was hit. */
/* Current implementation deals with zone-shades, self shading caused by */
/* exterior of zone surfaces other than current surface, and building-shades. */
/* Note that the order of shade intersection detection is first zone-shades, */
/* next zone surface (self) shading and last building-shades. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** function dhitsh *****************************/
def dhitsh(
	hit_ptr: Pointer[HIT],		/* pointer to bldg-shade hit structure */
	r1: Pointer[StaticArray[Float64, NCOORDS]],	/* origin of ray rn */
	rn: Pointer[StaticArray[Float64, NCOORDS]],	/* ray */
	bldg_ptr: Pointer[BLDG],		/* pointer to bldg structure */
	izone: Int32,			/* index of current zone */
	iWndoSurf: Int32,		/* index of current surface containing the Window */
	iNodeSurf: Int32)		/* index of current surface containing the Node, if applicable */ -> Int32
{
	var iz: Int32, izs: Int32, is: Int32, ish: Int32, icoord: Int32;		/* indexes */
	var v1: StaticArray[Float64, NCOORDS], v2: StaticArray[Float64, NCOORDS], v3: StaticArray[Float64, NCOORDS];
	var ipierc: Int32;		/* return value from dpierc() */
	hit_ptr[].ihit = 0;
	hit_ptr[].hitshade = 0;
	hit_ptr[].hitzone = 0;
	/* loop over zone-shades in all zones */
	for iz in range(0, bldg_ptr[].nzones) {
		for izs in range(0, bldg_ptr[].zone[iz][].nzshades) {
			/* get zone shade vertices */
			for icoord in range(0, NCOORDS) {
				v1[icoord] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][0];
				v2[icoord] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][1];
				v3[icoord] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][2];
			}
			/* dpierc() return value (0=no intersect, 1=front, -1=back) */
			dpierc(&ipierc,v1,v2,v3,r1,rn);
			/* if current shade is not hit then loop to next shade */
			if (ipierc == 0) continue;
			/* if current shade is hit return appropriate value */
			hit_ptr[].hitshade = izs;
			hit_ptr[].ihit = 1;
			return(0);
		}
	}
	/* loop over all zone surfaces (except current surface) in all zones */
	for iz in range(0, bldg_ptr[].nzones) {
		for is in range(0, bldg_ptr[].zone[iz][].nsurfs) {
			/* skip current surface containing window */
			if ((iz == izone) && (is == iWndoSurf)) continue;
			/* skip current surface containing node, if applicable */
			if ((iz == izone) && (is == iNodeSurf)) continue;
			/* get surface vertices */
			for icoord in range(0, NCOORDS) {
				v1[icoord] = bldg_ptr[].zone[iz][].surf[is][].vert[icoord][0];
				v2[icoord] = bldg_ptr[].zone[iz][].surf[is][].vert[icoord][1];
				v3[icoord] = bldg_ptr[].zone[iz][].surf[is][].vert[icoord][2];
			}
			/* dpierc() return value (0=no intersect, 1=front, -1=back) */
			dpierc(&ipierc,v1,v2,v3,r1,rn);
			/* if front (exterior) of current surface is hit return appropriate value */
			if (ipierc == 1) {
				hit_ptr[].hitzone = iz;
				hit_ptr[].hitshade = is;
				hit_ptr[].ihit = 2;
				return(0);
			}
		}
	}
	/* loop over building-shades */
	for ish in range(0, bldg_ptr[].nbshades) {
		/* get shade vertices */
		for icoord in range(0, NCOORDS) {
			v1[icoord] = bldg_ptr[].bshade[ish][].vert[icoord][0];
			v2[icoord] = bldg_ptr[].bshade[ish][].vert[icoord][1];
			v3[icoord] = bldg_ptr[].bshade[ish][].vert[icoord][2];
		}
		/* dpierc() return value (0=no intersect, 1=front, -1=back) */
		dpierc(&ipierc,v1,v2,v3,r1,rn);
		/* if current shade is not hit then loop to next shade */
		if (ipierc == 0) continue;
		/* if current shade is hit return appropriate values */
		hit_ptr[].hitshade = ish;
		if (ipierc == -1) hit_ptr[].ihit = 3;
		if (ipierc == 1) hit_ptr[].ihit = 4;
		return(0);
	}
	return(0);
}
/****************************** subroutine zshade_calc_verts *****************************/
/* Determines all vertices of zone shades in bldg coord system (BCS) */
/* based on zshade location as viewed from inside looking outward (0=overhang, 1=right fin, 2=left fin). */
/* Vertices are numbered counterclockwise from upper left viewed back along the */
/* zone shade outward normal (i.e., from side facing wndo). */
/* The second vertex (index 1) is therefore the zshade origin. */
/* Note that vertices are oriented from outside looking in and shades are oriented from inside looking out. */
/* 1/98 Modifications: */
/*	- Set zone shade vertices located on window host surface using window vertices in BCS. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine zshade_calc_verts *****************************/
def zshade_calc_verts(
	bldg_ptr: Pointer[BLDG],	/* bldg structure pointer */
	iz: Int32,			/* zone index */
	is: Int32,			/* surface index */
	iw: Int32,			/* window index */
	izs: Int32,		/* zshade index */
	lzs: Int32)		/* zshade location (0=overhang, 1=right fin, 2=left fin). */ -> Int32
{
	var zshade_x: Float64, zshade_y: Float64;	/* zone shade depth and distance from wndo */
	var w0: StaticArray[Float64, NCOORDS], w1: StaticArray[Float64, NCOORDS], w2: StaticArray[Float64, NCOORDS], w3: StaticArray[Float64, NCOORDS];	/* window vertices */
	var uvect10: StaticArray[Float64, NCOORDS], uvect21: StaticArray[Float64, NCOORDS], uvect12: StaticArray[Float64, NCOORDS];	/* unit vectors between window vertices */
	var dist10: Float64, dist21: Float64, dist12: Float64;		/* distance between vertices */
	var wnorm: StaticArray[Float64, NCOORDS];		/* window outward normal vector */
	var icoord: Int32;		/* loop index */
	/* Determine zone shade vertices (bldg sys coords) located on window host surface. */
	/* Get window vertices numbered counter-clockwise starting at upper left viewed from OUTSIDE of room. */
	for icoord in range(0, NCOORDS) {
		w0[icoord] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert[icoord][0];
		w1[icoord] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert[icoord][1];
		w2[icoord] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert[icoord][2];
		w3[icoord] = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].vert[icoord][3];
	}
	/* Calc unit vectors between wndo vertices: */
	/*   1 to 0 (i.e., "up" along host surface height), */
	/*   2 to 1 (i.e., "right to left viewed from outside" along host surface width). */
	/*   1 to 2 (i.e., "left to right viewed from outside" along host surface width). */
	dist10 = 0.;
	dist21 = 0.;
	dist12 = 0.;
	for icoord in range(0, NCOORDS) {
		uvect10[icoord] = w0[icoord] - w1[icoord];
		dist10 += uvect10[icoord] * uvect10[icoord];
		uvect21[icoord] = w1[icoord] - w2[icoord];
		dist21 += uvect21[icoord] * uvect21[icoord];
		uvect12[icoord] = w2[icoord] - w1[icoord];
		dist12 += uvect12[icoord] * uvect12[icoord];
	}
	dist10 = sqrt(dist10);
	dist21 = sqrt(dist21);
	dist12 = sqrt(dist12);
	for icoord in range(0, NCOORDS) {
		uvect10[icoord] /= dist10;
		uvect21[icoord] /= dist21;
		uvect12[icoord] /= dist12;
	}
    /* Zshade distance from wndo along host surface. */
    zshade_y = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].zshade_y[lzs];
	/* Set bldg coord system vertices based on zshade location (type). */
	switch (lzs)
	{
		case 0:	/* overhang */
			/* Calc overhang vertices located on window host surface. */
			for icoord in range(0, NCOORDS) {
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][1] = w0[icoord] + uvect10[icoord] * zshade_y;
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][2] = w3[icoord] + uvect10[icoord] * zshade_y;
			}
			break;
		case 1:	/* right fin */
			/* Calc right fin vertices located on window host surface. */
			for icoord in range(0, NCOORDS) {
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][2] = w1[icoord] + uvect21[icoord] * zshade_y;
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][3] = w0[icoord] + uvect21[icoord] * zshade_y;
			}
			break;
		case 2:	/* left fin */
			/* Calc left fin vertices located on window host surface. */
			for icoord in range(0, NCOORDS) {
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][0] = w3[icoord] + uvect12[icoord] * zshade_y;
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][1] = w2[icoord] + uvect12[icoord] * zshade_y;
			}
			break;
	}
	/* Determine zone shade vertices (bldg sys coords) not located on window host surface. */
	/* Calc unit vector normal to window (pointing away from room) */
	dcross(uvect12,uvect10,wnorm);
    /* Shorten reference to overhang depth. */
    zshade_x = bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].zshade_x[lzs];
	/* Calc off-surface vertices based on zshade location. */
	switch (lzs)
	{
		case 0:	/* overhang */
			for icoord in range(0, NCOORDS) {
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][0] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][1] + wnorm[icoord] * zshade_x;
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][3] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][2] + wnorm[icoord] * zshade_x;
			}
			break;
		case 1:	/* right fin */
			for icoord in range(0, NCOORDS) {
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][0] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][3] + wnorm[icoord] * zshade_x;
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][1] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][2] + wnorm[icoord] * zshade_x;
			}
			break;
		case 2:	/* left fin */
			for icoord in range(0, NCOORDS) {
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][2] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][1] + wnorm[icoord] * zshade_x;
				bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][3] = bldg_ptr[].zone[iz][].zshade[izs][].vert[icoord][0] + wnorm[icoord] * zshade_x;
			}
			break;
	}
	return(0);
}
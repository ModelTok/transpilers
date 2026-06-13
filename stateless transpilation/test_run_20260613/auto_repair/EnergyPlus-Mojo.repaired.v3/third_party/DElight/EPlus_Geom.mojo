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
from EPlus_Geom import *
from geom import *
from GeomMesh import *
from struct import *
/****************************** subroutine CalcGeomFromEPlus *****************************/
/* Calculates geometrical values required by daylight factor calculations. */
/* The bldg structure must be fully initialized prior to this call. */
/* Building geometry input is assumed to already be in World Coordinate System. */
/****************************** subroutine CalcGeomFromEPlus *****************************/
def CalcGeomFromEPlus(
	bldg_ptr: BLDG) -> Int32		/* bldg structure pointer */
{
	var iz: Int32; var is: Int32; var ivert: Int32; var icoord: Int32; var iw: Int32;
	for iz in range(0, bldg_ptr.nzones) {
		for is in range(0, bldg_ptr.zone[iz].nsurfs) {
			for iw in range(0, bldg_ptr.zone[iz].surf[is].nwndos) {
				for ivert in range(0, NVERTS) {
					for icoord in range(0, NCOORDS) {
                        var pt3D: BGL.point3 = bldg_ptr.zone[iz].surf[is].wndo[iw].vPt3VerticesWCS_OCCW[ivert];
						bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][ivert] = pt3D[icoord];
					} // window vertex coordinate loop
				} // window vertex loop
				CalcWindowGeomFromVertices(bldg_ptr, iz, is, iw);
			} // window loop
			for ivert in range(0, NVERTS) {
				for icoord in range(0, NCOORDS) {
                    var pt3D: BGL.point3 = bldg_ptr.zone[iz].surf[is].vPt3VerticesWCS_OCCW[ivert];
					bldg_ptr.zone[iz].surf[is].vert[icoord][ivert] = pt3D[icoord];
				} // surface vertex coordinate loop
			} // surface vertex loop
			CalcSurfaceGeomFromVertices(bldg_ptr, iz, is);
		} // surface loop
	} // zone loop
	return(0);
}
/****************************** subroutine CalcSurfaceGeomFromVertices *****************************/
/* Calculates additional Surface geometrical values given vertex coordinates. */
/* Surface vertex coordinates are assumed to already be in World Coordinate System. */
/****************************** subroutine CalcSurfaceGeomFromVertices *****************************/
def CalcSurfaceGeomFromVertices(
	bldg_ptr: BLDG,			/* bldg structure pointer */
	iz: Int32,					/* index of current zone */
	is: Int32) -> Int32					/* index of current surface */
{
	var icoord: Int32;	// loop index
	var dist10: Float64; var dist12: Float64;	// distances between vertices == surface height and width
	var svert0: Float64[NCOORDS]; var svert1: Float64[NCOORDS]; var svert2: Float64[NCOORDS];	// vertex coords
	var svect10: Float64[NCOORDS]; var svect12: Float64[NCOORDS];	// unit vectors in Surface LCS Y and X axes
	for icoord in range(0, NCOORDS) {
		svert0[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][0];
		svert1[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][1];
		svert2[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][2];
	}
	dist10 = 0.;
	dist12 = 0.;
	for icoord in range(0, NCOORDS) {
		svect10[icoord] = svert0[icoord] - svert1[icoord];
		svect12[icoord] = svert2[icoord] - svert1[icoord];
		dist10 += svect10[icoord] * svect10[icoord];
		dist12 += svect12[icoord] * svect12[icoord];
	}
	dist10 = sqrt(dist10);
	bldg_ptr.zone[iz].surf[is].height = dist10;
	dist12 = sqrt(dist12);
	bldg_ptr.zone[iz].surf[is].width = dist12;
	for icoord in range(0, NCOORDS) {
		svect10[icoord] /= dist10;
		svect12[icoord] /= dist12;
	}
	bldg_ptr.zone[iz].surf[is].dircos[0] = -(svect12[0]);
	bldg_ptr.zone[iz].surf[is].dircos[1] = -(svect12[1]);
	bldg_ptr.zone[iz].surf[is].dircos[2] = -(svect12[2]);
	bldg_ptr.zone[iz].surf[is].dircos[3] = svect10[0];
	bldg_ptr.zone[iz].surf[is].dircos[4] = svect10[1];
	bldg_ptr.zone[iz].surf[is].dircos[5] = svect10[2];
	/* Outward facing unit vector normal to surface (i.e., DOE2 outward normal) */
	dcross(svect12,svect10,bldg_ptr.zone[iz].surf[is].outward_uvect);
	/* Inward facing unit vector normal to surface (i.e., Slite inward normal == Z-axis direction cosines???) */
	dcross(svect10,svect12,bldg_ptr.zone[iz].surf[is].inward_uvect);
	bldg_ptr.zone[iz].surf[is].dircos[6] = bldg_ptr.zone[iz].surf[is].inward_uvect[0];
	bldg_ptr.zone[iz].surf[is].dircos[7] = bldg_ptr.zone[iz].surf[is].inward_uvect[1];
	bldg_ptr.zone[iz].surf[is].dircos[8] = bldg_ptr.zone[iz].surf[is].inward_uvect[2];
	return(0);
}
/****************************** subroutine CalcWindowGeomFromVertices *****************************/
/* Calculates additional Window geometrical values given vertex coordinates. */
/* Window vertex coordinates are assumed to already be in World Coordinate System. */
/****************************** subroutine CalcWindowGeomFromVertices *****************************/
def CalcWindowGeomFromVertices(
	bldg_ptr: BLDG,			/* bldg structure pointer */
	iz: Int32,					/* index of current zone */
	is: Int32,					/* index of current surface */
	iw: Int32) -> Int32					/* index of current window */
{
	var icoord: Int32;	// loop index
	var dist10: Float64; var dist12: Float64;	// distances between vertices == window height and width
	var svert0: Float64[NCOORDS]; var svert1: Float64[NCOORDS]; var svert2: Float64[NCOORDS];	// vertex coords
	var svect10: Float64[NCOORDS]; var svect12: Float64[NCOORDS];	// unit vectors in Surface LCS Y and X axes
	for icoord in range(0, NCOORDS) {
		svert0[icoord] = bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][0];
		svert1[icoord] = bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][1];
		svert2[icoord] = bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][2];
	}
	dist10 = 0.;
	dist12 = 0.;
	for icoord in range(0, NCOORDS) {
		svect10[icoord] = svert0[icoord] - svert1[icoord];
		svect12[icoord] = svert2[icoord] - svert1[icoord];
		dist10 += svect10[icoord] * svect10[icoord];
		dist12 += svect12[icoord] * svect12[icoord];
	}
	dist10 = sqrt(dist10);
	bldg_ptr.zone[iz].surf[is].wndo[iw].height = dist10;
	dist12 = sqrt(dist12);
	bldg_ptr.zone[iz].surf[is].wndo[iw].width = dist12;
	return(0);
}
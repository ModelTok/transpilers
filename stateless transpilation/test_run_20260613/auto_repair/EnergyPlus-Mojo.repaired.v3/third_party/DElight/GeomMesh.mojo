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
from geom import *
from GeomMesh import *

/*************************** subroutine dircos_calc **************************/
/* Calculates direction cosine values for a surface in slite bldg coord sys. */
/* Based on Superlite conventions. */
/* Uses surface tilt and zone azimuths to determine slite surface angles. */
/* Radiosity modification */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/*************************** subroutine dircos_calc **************************/
def dircos_calc(
	bldg_ptr: BLDG,	/* pointer to bldg structure */
	iz: Int,			/* current zone index */
	is: Int) -> Int		/* current surface index */
{
	var beta1: Float64, beta2: Float64, psi1: Float64, psi2: Float64;	/* slite surface orientation angles */
	var surf_azm_bs: Float64;	/* surface azm in DOE2 bldg coord sys */
	var sbx: Float64, cbx: Float64, sby: Float64, cby: Float64, spx: Float64, cpx: Float64, spy: Float64, cpy: Float64;	/* temp sin/cos vars */
	/* calc slite beta and psi angles from surf tilt and bldg coord sys azm */
	/* note that DOE2 bldg coord sys is clockwise north and */
	/* slite angles are counter-clockwise south */
	/* beta1 is always 90 since all DOE2 surfaces have a horiz local x-axis */
	beta1 = 90.0;
	beta2 = fabs(bldg_ptr.zone[iz].surf[is].tilt_bs - 90.0);
	/* calc surface azimuth in DOE2 bldg coord sys using zone azm */
	surf_azm_bs = bldg_ptr.zone[iz].surf[is].azm_bs;
	/* psi1 based on surf_azm_bs and converted from DOE2 to slite bldg coord system */
	psi1 = -(surf_azm_bs + 90.0) + 180.0;
	/* psi2 is always 0 for vertical surfaces */
	if (bldg_ptr.zone[iz].surf[is].tilt_zs == 90.0) {
		psi2 = 0.0;
	}
	/* for non-vertical surfaces, relationship between psi2 and azm is */
	/* based on tilt (tilt > 90 => azm points "down") */
	else if (bldg_ptr.zone[iz].surf[is].tilt_zs > 90.0) {
		psi2 = surf_azm_bs;
		/* convert to slite bldg coord sys */
		psi2 = -(psi2) + 180.0;
	}
	else { // if (bldg_ptr.zone[iz].surf[is].tilt_zs < 90.0) {
		psi2 = surf_azm_bs + 180.0;
		if (psi2 > 360.0) psi2 -= 360.0;
		/* convert to slite bldg coord sys */
		psi2 = -(psi2) + 180.0;
	}
/* rob strt
fprintf(dmpfile,"surface [%s] tilt_zs = %7.2f azm_bs = %7.2f\nbeta1 = %7.2f beta2 = %7.2f psi1 = %7.2f psi2 = %7.2f\n", bldg_ptr.zone[iz].surf[is].name,bldg_ptr.zone[iz].surf[is].tilt_zs,surf_azm_bs,beta1,beta2,psi1,psi2);
rob end */
	/* convert angles to radians */
	beta1 *= DTOR;
	beta2 *= DTOR;
	psi1 *= DTOR;
	psi2 *= DTOR;
/* rob strt
fprintf(dmpfile,"beta1 = %7.2f beta2 = %7.2f psi1 = %7.2f psi2 = %7.2f\n", beta1,beta2,psi1,psi2);
rob end */
	/* calc sin and cos of slite angles */
	sbx = sin(beta1);
	cbx = cos(beta1);
	sby = sin(beta2);
	cby = cos(beta2);
	spx = sin(psi1);
	cpx = cos(psi1);
	spy = sin(psi2);
	cpy = cos(psi2);
	/* calc slite direction cosine values of angles for this surf */
	/* Note: equations for dircos 0 and 1 are reversed from slite */
	/* because of differences in slite and doe2 coordinate systems */
	bldg_ptr.zone[iz].surf[is].dircos[1] = sbx * cpx;
	bldg_ptr.zone[iz].surf[is].dircos[0] = sbx * spx;
	bldg_ptr.zone[iz].surf[is].dircos[2] = cbx;
	/* Note: equations for dircos 3 and 4 are reversed from slite */
	bldg_ptr.zone[iz].surf[is].dircos[4] = sby * cpy;
	bldg_ptr.zone[iz].surf[is].dircos[3] = sby * spy;
	bldg_ptr.zone[iz].surf[is].dircos[5] = cby;
	/* Note: equations for dircos 6 and 7 are reversed from slite */
	bldg_ptr.zone[iz].surf[is].dircos[7] = sbx * spx * cby - cbx * sby * spy;
	bldg_ptr.zone[iz].surf[is].dircos[6] = cbx * sby * cpy - sbx * cpx * cby;
	bldg_ptr.zone[iz].surf[is].dircos[8] = sbx * sby * (spy * cpx - cpy * spx);
	return(0);
}
/*************************** subroutine dircos_calc_new **************************/
/* Calculates direction cosine values for a surface using Superlite conventions, */
/* BUT in DOE2 WCS. */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/*************************** subroutine dircos_calc_new **************************/
def dircos_calc_new(
	bldg_ptr: BLDG,	/* pointer to bldg structure */
	iz: Int,			/* current zone index */
	is: Int) -> Int		/* current surface index */
{
	var icoord: Int;	// loop index
	var dist10: Float64, dist12: Float64;	// distances between vertices == surface height and width
	var svert0: StaticFloat64Array[NCOORDS], svert1: StaticFloat64Array[NCOORDS], svert2: StaticFloat64Array[NCOORDS];	// vertex coords
	var svect10: StaticFloat64Array[NCOORDS], svect12: StaticFloat64Array[NCOORDS];	// unit vectors in Surface LCS Y and X axes
	for icoord in range(0, NCOORDS) {
		svert0[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][0];
		svert1[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][1];
		svert2[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][2];
	}
	dist10 = 0.0;
	dist12 = 0.0;
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
/*************************** subroutine nodal_calcs **************************/
/* Calculates nodal area for each surface */
/* Calculates nodal coordinates in bldg coord sys. */
/* Based on Superlite conventions. */
/* Radiosity modification */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/*************************** subroutine nodal_calcs **************************/
def nodal_calcs(
	bldg_ptr: BLDG,	/* pointer to bldg structure */
	num_nodes: Int,	/* total number of nodes on surface */
	iz: Int,			/* current zone index */
	is: Int) -> Int		/* current surface index */
{
	var n_width: Int, n_height: Int;	/* temp node count holders */
	var icoord: Int, iwidth: Int, iheight: Int;		/* loop indexes */
	var inode: Int;		/* current node counter and index */
	var v0: StaticFloat64Array[NCOORDS], v1: StaticFloat64Array[NCOORDS], v2: StaticFloat64Array[NCOORDS];	/* surface vertices */
	var edge_width: StaticFloat64Array[NCOORDS], edge_height: StaticFloat64Array[NCOORDS];	/* node edge lengths */
	var row_strt: StaticFloat64Array[NCOORDS], test_node: StaticFloat64Array[NCOORDS];	/* tmp vars for node calcs */
	/* calculate number of nodes in width and height directions. */
	/* based on user entered total number of nodes and surface aspect ratio */
	n_width = Int(sqrt(num_nodes as Float64 * bldg_ptr.zone[iz].surf[is].width / bldg_ptr.zone[iz].surf[is].height) + 0.5);
	bldg_ptr.zone[iz].surf[is].n_width = n_width;
	n_height = Int((num_nodes / n_width) as Float64 + 0.5);
	/* assure that n_width * n_height < MAX_SURF_NODES */
	while ((n_width * n_height) > MAX_SURF_NODES)
		n_height -= 1;
	bldg_ptr.zone[iz].surf[is].n_height = n_height;
	/* calculate nodal area for each surface */
	bldg_ptr.zone[iz].surf[is].node_area = (bldg_ptr.zone[iz].surf[is].width * bldg_ptr.zone[iz].surf[is].height) / (n_width * n_height);
	/* Calculate coordinates of each node on surface */
	/* Calculate node edge lengths (signed) for surface. */
	/* Surface vertices (numbered counter-clockwise starting at */
	/* upper left (vert[icoord][0]) viewed from OUTSIDE of room). */
	/* Note that v1 is therefore DOE-2 input origin. */
	for icoord in range(0, NCOORDS) {
		v0[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][0];
		v1[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][1];
		v2[icoord] = bldg_ptr.zone[iz].surf[is].vert[icoord][2];
		/* signed length of width edge along each axis */
		/* equals the width of the surface along each axis divided by */
		/* the number of nodes along the width */
		edge_width[icoord] = (v2[icoord]-v1[icoord]) / n_width;
		/* signed length of height edge along each axis */
		/* equals the height of the surface along each axis divided by */
		/* the number of nodes along the height */
		edge_height[icoord] = (v0[icoord]-v1[icoord]) / n_height;
	}
	/* Calc coordinates of nodal starting point, positioned near DOE2 origin */
	/* at 1/2 node height "below" edge of surface defined by v1 and v2 */
	for icoord in range(0, NCOORDS) {
		row_strt[icoord] = v1[icoord] + edge_width[icoord] * 0.5 - edge_height[icoord] * 0.5;
	}
	inode = 0;
	/* calc coordinates of nodes on surface */
	for iheight in range(0, n_height) {
		/* calc first node in row */
		for icoord in range(0, NCOORDS) {
			/* move from first node of previous row to first node of this row */
			row_strt[icoord] += edge_height[icoord];
			test_node[icoord] = row_strt[icoord];
		}
		/* check to see if test node falls within a surface cutout */
		if (cutout_chk_new(test_node,bldg_ptr,iz,is) == 0) {
			for icoord in range(0, NCOORDS) {
				bldg_ptr.zone[iz].surf[is].node[inode][icoord] = test_node[icoord];
			}
			inode += 1;
		}
		for iwidth in range(1, n_width) {
			/* calc next node along current row */
			for icoord in range(0, NCOORDS) {
				test_node[icoord] += edge_width[icoord];
			}
			/* check to see if test node falls within a surface cutout */
			if (cutout_chk_new(test_node,bldg_ptr,iz,is) == 0) {
				for icoord in range(0, NCOORDS) {
					bldg_ptr.zone[iz].surf[is].node[inode][icoord] = test_node[icoord];
				}
				inode += 1;
			}
		}
	}
	/* store number of nodes on this surface */
	bldg_ptr.zone[iz].surf[is].nnodes = inode;
	return(0);
}
/************************* subroutine wndo_nodal_calcs ************************/
/* Calculates nodal area for each window */
/* Calculates window nodal coordinates in bldg coord sys. */
/* Based on Superlite conventions. */
/* Radiosity modification */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************* subroutine wndo_nodal_calcs ************************/
def wndo_nodal_calcs(
	bldg_ptr: BLDG,		/* pointer to bldg structure */
	num_wnodes: Int,		/* total number of nodes on window */
	iz: Int,				/* current zone index */
	is: Int,				/* current surface index */
	iw: Int) -> Int			/* current window index */
{
	var n_width: Int, n_height: Int;		/* number of nodes in width and height directions */
	var icoord: Int, iwidth: Int, iheight: Int;		/* loop indexes */
	var inode: Int;		/* current node counter and index */
	var v0: StaticFloat64Array[NCOORDS], v1: StaticFloat64Array[NCOORDS], v2: StaticFloat64Array[NCOORDS];	/* surface vertices */
	var edge_width: StaticFloat64Array[NCOORDS], edge_height: StaticFloat64Array[NCOORDS];	/* node edge lengths */
	var row_strt: StaticFloat64Array[NCOORDS], next_node: StaticFloat64Array[NCOORDS];	/* tmp vars for node calcs */
	/* calculate number of nodes in width and height directions. */
	/* based on user entered total number of nodes and window aspect ratio */
	n_width = Int(sqrt(num_wnodes as Float64 * bldg_ptr.zone[iz].surf[is].wndo[iw].width / bldg_ptr.zone[iz].surf[is].wndo[iw].height) + 0.5);
	bldg_ptr.zone[iz].surf[is].wndo[iw].n_width = n_width;
	n_height = Int((num_wnodes / n_width) as Float64 + 0.5);
	/* assure that n_width * n_height < MAX_WNDO_NODES */
	while ((n_width * n_height) > MAX_WNDO_NODES)
		n_height -= 1;
	bldg_ptr.zone[iz].surf[is].wndo[iw].n_height = n_height;
	/* calculate nodal area for each window */
	bldg_ptr.zone[iz].surf[is].wndo[iw].node_area = (bldg_ptr.zone[iz].surf[is].wndo[iw].width * bldg_ptr.zone[iz].surf[is].wndo[iw].height) / (n_width * n_height);
	/* Calculate coordinates of each node on window */
	/* Calculate node edge lengths (signed) for window. */
	/* Window vertices (numbered counter-clockwise starting at */
	/* upper left (vert[icoord][0]) viewed from OUTSIDE of room). */
	/* Note that v1 is therefore input origin. */
	for icoord in range(0, NCOORDS) {
		v0[icoord] = bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][0];
		v1[icoord] = bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][1];
		v2[icoord] = bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][2];
		/* signed length of width edge along each axis */
		/* equals the width of the window along each axis divided by */
		/* the number of nodes along the width */
		edge_width[icoord] = (v2[icoord]-v1[icoord]) / n_width;
		/* signed length of height edge along each axis */
		/* equals the height of the window along each axis divided by */
		/* the number of nodes along the height */
		edge_height[icoord] = (v0[icoord]-v1[icoord]) / n_height;
	}
	/* Calc coordinates of nodal starting point, positioned near DOE2 origin */
	/* at 1/2 node height "below" edge of window defined by v1 and v2 */
	for icoord in range(0, NCOORDS) {
		row_strt[icoord] = v1[icoord] + edge_width[icoord] * 0.5 - edge_height[icoord] * 0.5;
	}
	inode = 0;
	/* calc coordinates of nodes on window */
	for iheight in range(0, n_height) {
		/* calc first node in row */
		for icoord in range(0, NCOORDS) {
			/* move from first node of previous row to first node of this row */
			row_strt[icoord] += edge_height[icoord];
			bldg_ptr.zone[iz].surf[is].wndo[iw].node[inode][icoord] = row_strt[icoord];
			/* init next_node for subsequent incrementing */
			next_node[icoord] = row_strt[icoord];
		}
		inode += 1;
		for iwidth in range(1, n_width) {
			/* calc next node along current row */
			for icoord in range(0, NCOORDS) {
				next_node[icoord] += edge_width[icoord];
				bldg_ptr.zone[iz].surf[is].wndo[iw].node[inode][icoord] = next_node[icoord];
			}
			inode += 1;
		}
	}
	/* store number of nodes on this window */
	bldg_ptr.zone[iz].surf[is].wndo[iw].nnodes = inode;
	return(0);
}
/*************************** subroutine cutout_chk **************************/
/* Checks to see if node falls within a cutout region of a surface. */
/* Returns 0 if node does not fall within any cutout regions. */
/* Returns 1 if node falls within a cutout region. */
/* Based on Superlite conventions. */
/* Radiosity modification */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/*************************** subroutine cutout_chk **************************/
def cutout_chk(
	test_node: StaticFloat64Array[NCOORDS],	/* node coordinates */
	bldg_ptr: BLDG,		/* pointer to bldg structure */
	iz: Int,						/* current zone index */
	is: Int) -> Int					/* current surface index */
{
	var iw: Int;	/* window loop index */
	var icoord: Int;	/* coordinate loop index */
	var xjp: Float64, yjp: Float64, xyp: Float64, etaj: Float64, xsij: Float64;	/* tmp calc vars */
	/* loop through all cutouts (windows) in current surface */
	for iw in range(0, bldg_ptr.zone[iz].surf[is].nwndos) {
		xjp = 0.0;
		yjp = 0.0;
		for icoord in range(0, NCOORDS) {
			xyp = test_node[icoord] - bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][2];
			if (icoord == 1) xyp = -(xyp);
			xjp += xyp * bldg_ptr.zone[iz].surf[is].dircos[icoord];
			yjp += xyp * bldg_ptr.zone[iz].surf[is].dircos[icoord+3];
		}
		etaj = yjp / bldg_ptr.zone[iz].surf[is].wndo[iw].height;
		/* does the node fall outside of the height range of this window? */
		if (fabs(etaj - 0.5) > 0.5) continue;
		xsij = xjp / bldg_ptr.zone[iz].surf[is].wndo[iw].width;
		/* does the node fall outside of the width range of this window? */
		if (fabs(xsij - 0.5) > 0.5) continue;
		/* the node must fall within the window */
		return(1);
	}
	return(0);
}
/*************************** subroutine cutout_chk_new **************************/
/* Checks to see if node falls within a cutout region of a surface. */
/* Returns 0 if node does not fall within any cutout regions. */
/* Returns 1 if node falls within a cutout region. */
/* Based on Superlite conventions. */
/* Radiosity modification */
/****************************************************************************/
/* C Language Implementation of Superlite Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/*************************** subroutine cutout_chk_new **************************/
def cutout_chk_new(
	test_node: StaticFloat64Array[NCOORDS],	/* node coordinates */
	bldg_ptr: BLDG,		/* pointer to bldg structure */
	iz: Int,						/* current zone index */
	is: Int) -> Int					/* current surface index */
{
	var iw: Int;	/* window loop index */
	var icoord: Int;	/* coordinate loop index */
	var xjp: Float64, yjp: Float64, xyp: Float64, etaj: Float64, xsij: Float64;	/* tmp calc vars */
	/* loop through all cutouts (windows) in current surface */
	for iw in range(0, bldg_ptr.zone[iz].surf[is].nwndos) {
		xjp = 0.0;
		yjp = 0.0;
		for icoord in range(0, NCOORDS) {
			xyp = test_node[icoord] - bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][2];
			xjp += xyp * bldg_ptr.zone[iz].surf[is].dircos[icoord];
			yjp += xyp * bldg_ptr.zone[iz].surf[is].dircos[icoord+3];
		}
		etaj = yjp / bldg_ptr.zone[iz].surf[is].wndo[iw].height;
		/* does the node fall outside of the height range of this window? */
		if (fabs(etaj - 0.5) > 0.5) continue;
		xsij = xjp / bldg_ptr.zone[iz].surf[is].wndo[iw].width;
		/* does the node fall outside of the width range of this window? */
		if (fabs(xsij - 0.5) > 0.5) continue;
		/* the node must fall within the window */
		return(1);
	}
	return(0);
}
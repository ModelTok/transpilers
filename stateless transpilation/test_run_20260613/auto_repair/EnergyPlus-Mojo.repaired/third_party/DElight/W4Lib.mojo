/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Author: R.J. Hitchcock and W.L. Carroll
 *          Building Technologies Department
 *          Lawrence Berkeley National Laboratory
 */
/**************************************************************
 * C Language Implementation of DOE2 Daylighting Algorithms.
 *
 * The original DOE2 algorithms and implementation in FORTRAN
 * were developed by F.C. Winkelmann.
 * Simulation Research Group, Lawrence Berkeley Laboratory.
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
from W4Lib import *
from struct import *
from memory import memset_zero
from sys import fgets, sscanf, snprintf, strtok, atoi, atof
/****************************** subroutine process_W4glazing_types *****************************/
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine process_W4glazing_types *****************************/
def process_W4glazing_types(
	bldg_ptr: Pointer[BLDG],		/* building structure pointer */
	lib_ptr: Pointer[LIB],		/* library structure pointer */
	W4libfile: Pointer[FILE],	/* pointer to Window4 library data file */
	pofdmpfile: Pointer[ofstream]) -> Int32	/* ptr to dump file */
{
	var iz: Int32, is: Int32, iw: Int32;	/* indexes */
	var iUniqueGlassIDs: StaticInt32Array[200];
	var iUniqueIDCount: Int32 = 0;
	for iz in range(0, bldg_ptr[].nzones) {
		for is in range(0, bldg_ptr[].zone[iz][].nsurfs) {
			for iw in range(0, bldg_ptr[].zone[iz][].surf[is][].nwndos) {
				var iGlass_Type_ID: Int32 = atoi(bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].glass_type);
				if (iGlass_Type_ID > 11) {
					if (IsGlassIDUnique(iGlass_Type_ID, iUniqueGlassIDs, &iUniqueIDCount)) {
						if (ProcessW4GlassType(iGlass_Type_ID, lib_ptr, W4libfile, pofdmpfile) < 0) {
							pofdmpfile[].write("ERROR: DElight Cannot create new LIB GLASS entry for Window4 library entry ID = " + bldg_ptr[].zone[iz][].surf[is][].wndo[iw][].glass_type + "\n");
							return (-1);
						}
					}
				}
			}
		}
	}
	return(0);
}
/****************************** subroutine IsGlassIDUnique *****************************/
/* Checks to see if the given glass_type ID is contained in the list of encountered IDs. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine IsGlassIDUnique *****************************/
def IsGlassIDUnique(
	iGlass_Type: Int32,			// current glass_type ID
	iUniqueGlassIDs: StaticInt32Array[200],	// array of encountered glass_type IDs
	piUniqueIDCount: Pointer[Int32]) -> Int32		// ptr to current count of unique glass_type ID
{
	for var iGID: Int32 = 0; iGID < piUniqueIDCount[]; iGID += 1 {
		if (iUniqueGlassIDs[iGID] == iGlass_Type)
			return (0);
	}
	iUniqueGlassIDs[piUniqueIDCount[]] = iGlass_Type;
	piUniqueIDCount[] += 1;
	return (1);
}
/****************************** subroutine ProcessW4GlassType *****************************/
/* Locate and process the given Window4 glass_type ID. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine ProcessW4GlassType *****************************/
def ProcessW4GlassType(
	iGlass_Type: Int32,	// W4 glass_type ID
	lib_ptr: Pointer[LIB],		// library structure pointer
	W4libfile: Pointer[FILE],	// pointer to Window4 library data file
	pofdmpfile: Pointer[ofstream]) -> Int32	/* ptr to dump file */
{
	var cInputLine: StaticCharArray[MAX_CHAR_LINE+1];	// Input line
	var token: Pointer[UInt8];						/* Input token pointer */
	var iW4ID: Int32;							// Window ID holder
	var iEntryFound: Int32 = 0;				// matching ID found flag
	var iInLine: Int32;						// index
	var dTvis: StaticFloat64Array[10]; var dYdat: StaticFloat64Array[10]; var dTvisHemi: Float64;		// temp Tvis data holders
	var dTvFit1: Float64; var dTvFit2: Float64;					// angular visible data curve fit coefs
	do {
		for iInLine in range(0, 6):
			if (fgets(cInputLine, MAX_CHAR_LINE, W4libfile) == None) return -1;
		sscanf(cInputLine,"%*s %*s %*s %d\n",&iW4ID);
		if (iW4ID == iGlass_Type) {
			for iInLine in range(6, 32):
				if (fgets(cInputLine, MAX_CHAR_LINE, W4libfile) == None) return -1;
			token = strtok(cInputLine," ");
			var iAngle: Int32;
			for iAngle in range(0, 10):
				token = strtok(None," ");
				dTvis[iAngle] = atof(token);
			token = strtok(None," ");
			dTvisHemi = atof(token);
			for iAngle in range(0, 10):
				dYdat[iAngle] = dTvis[iAngle] / (dTvis[0] + 0.000001);
			Qikfit4(10, dYdat, &dTvFit1, &dTvFit2);
			lib_ptr[].glass[lib_ptr[].nglass] = new GLASS;
			if (lib_ptr[].glass[lib_ptr[].nglass] == None) {
				pofdmpfile[].write("ERROR: DElight Insufficient memory for GLASS allocation\n");
				return(-1);
			}
			struct_init("GLASS",(Pointer[UInt8])(lib_ptr[].glass[lib_ptr[].nglass]));
			snprintf(lib_ptr[].glass[lib_ptr[].nglass][].name, 60, "%d", iGlass_Type);	/* glass type ID: 1 to 11 => DOE2 original, >11 => W4lib.dat, <0 => E10 library */
			lib_ptr[].glass[lib_ptr[].nglass][].vis_trans = dTvis[0];		/* visible transmittance at normal incidence */
			lib_ptr[].glass[lib_ptr[].nglass][].W4hemi_trans = dTvisHemi;	/* Window 4 hemispherical transmittance */
			lib_ptr[].glass[lib_ptr[].nglass][].W4vis_fit1 = dTvFit1;		/* Window 4 angular transmission curve fit coef #1 */
			lib_ptr[].glass[lib_ptr[].nglass][].W4vis_fit2 = dTvFit2;		/* Window 4 angular transmission curve fit coef #2 */
			for iInLine in range(32, 34):
				if (fgets(cInputLine, MAX_CHAR_LINE, W4libfile) == None) return -1;
			sscanf(cInputLine,"%*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %d\n",(Pointer[Int32])(&lib_ptr[].glass[lib_ptr[].nglass][].inside_refl));
			(lib_ptr[].nglass) += 1;
			iEntryFound = 1;
		}
		else {	// skip the remaining lines of this entry
			for iInLine in range(6, 55):
				if (fgets(cInputLine, MAX_CHAR_LINE, W4libfile) == None) return -1;
		}
    }
    while(not iEntryFound);
	return (0);
}
/****************************** subroutine Qikfit4 *****************************/
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine Qikfit4 *****************************/
def Qikfit4(
	iData: Int32,			// number of data points
	dYdat: StaticFloat64Array[10],	// normalized angular visible data
	pdTvFit1: Pointer[Float64],	// pointer to coef1
	pdTvFit2: Pointer[Float64]) -> Int32	// pointer to coef2
{
	var dX0: StaticFloat64Array[10] = {1.0, 0.984808, 0.939693, 0.866025, 0.776044, 0.642788, 0.5, 0.342020, 0.173648, 0.0};
	var dp1: Float64 = 0.0; var dp2: Float64 = 0.0; var dp3: Float64 = 0.0; var dp4: Float64 = 0.0; var dp5: Float64 = 0.0; var dp6: Float64 = 0.0;
	var d0: Float64; var d1: Float64; var d2: Float64;
	for var ii: Int32 = 0; ii < iData; ii += 1 {
		d0 = (2.0 - dX0[ii]) * dX0[ii];
		d1 = dX0[ii] * (1.0 - dX0[ii]) * (1.0 - dX0[ii]);
		d2 = 2.0 + dX0[ii];
		dp1 += (dYdat[ii] - d0) * d1;
		dp2 += d1 * d1;
		dp3 += d1 * d1 * d2;
		dp4 += (dYdat[ii] - d0) * d1 * d2;
		dp5 += d1 * d1 * d2;
		dp6 += d1 * d1 * d2 * d2;
	}
	pdTvFit1[] = (dp1 * dp6 - dp3 * dp4) / (dp2 * dp6 - dp3 * dp5);
	pdTvFit2[] = (dp1 * dp5 - dp2 * dp4) / (dp3 * dp5 - dp2 * dp6);
	return (0);
}
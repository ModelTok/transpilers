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
# pragma warning(disable:4786)
from BGL import *
# namespace BGL = BldgGeomLib;
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
from DElight2 import *
from struct import *
from EPlus_Loaddata import *
from EPlus_Geom import *
from DFcalcs import *
from EPlus_ECM import *
from ECM import *
from savedata import *
from TOOLS import *
from WxTMY2 import *
from W4Lib import *
/******************************** subroutine DElightDaylightFactors4EPlus *******************************/
/* Calls key daylighting simulation modules necessary for calculating a set of daylight factors for EnergyPlus. */
/******************************** subroutine DElightDaylightFactors4EPlus *******************************/
def DElightDaylightFactors4EPlus(
	sInputName: Pointer[UInt8, 0],	/* input file name */
	sOutputName: Pointer[UInt8, 0],	/* output file name */
	bldg_ptr: Pointer[BLDG],							/* bldg data structure */
	lib_ptr: Pointer[LIB],							/* library data structure */
	iIterations: Int32,					/* Number of radiosity iterations */
	dCloudFraction: Float64,				/* fraction of sky covered by clouds (0.0=clear 1.0=overcast) */
	iSurfNodes: Int32,						/* Desired total number of surface nodes */
	iWndoNodes: Int32,						/* Desired total number of window nodes */
	iNumAlts: Int32,						/* Number of daylight factor sun altitude angles */
	dMinAlt: Float64,						/* Minimum daylight factor sun altitude angle */
	iNumAzms: Int32,						/* Number of daylight factor sun azimuth angles */
	dMinAzm: Float64,						/* Minimum daylight factor sun azimuth angle */
    pofdmpfile: Pointer[OStream]) -> Int32               // ptr to Error message dump file
{
	var infile: Pointer[FILE];						/* input file pointer */
	var outfile: Pointer[FILE];						/* output file pointer */
	var sun_data: SUN_DATA;	/* sun data structure */
    var iReturnVal: Int32 = 0;
	/* initialize BLDG and LIB structures */
	struct_init("BLDG", bldg_ptr);
	struct_init("LIB", lib_ptr);
	if((infile = fopen(sInputName, "r" )) == None ) {
		pofdmpfile[].write("ERROR: DElight cannot open input file [" + sInputName + "]\n");
		return(-3);
	}
	var cInputLine: Pointer[UInt8, 0];	/* Input line */
	if (fgets(cInputLine, MAX_CHAR_LINE, infile) == None) return -1;
	var cInputVersion: Pointer[UInt8, 0];
	sscanf(cInputLine,"%*s %s\n",cInputVersion); //,_countof(cInputVersion));
	if (strcmp(cInputVersion,"EPlus") == 0)
	{
		if (LoadDataFromEPlus(bldg_ptr,infile,pofdmpfile) < 0) {
			pofdmpfile[].write("ERROR: DElight Bad Building data read from input file [" + sInputName + "]\n");
			/* Close input file. */
			fclose(infile);
			return(-4);
		}
		/* load library data from input file */
		if (LoadLibDataFromEPlus(lib_ptr,infile,pofdmpfile) < 0) {
			pofdmpfile[].write("ERROR: DElight Bad Library data read from input file [" + sInputName + "]\n");
			/* Close input file. */
			fclose(infile);
			return(-4);
		}
	}
	else // return error
	{
		pofdmpfile[].write("ERROR: DElight Incorrect DElight for EnergyPlus Input Format in input file [" + sInputName + "]\n");
		/* Close input file. */
		fclose(infile);
		return(-4);
	}
	/* Close input file after successful read. */
	fclose(infile);
	/* Calculate geometrical values required for DF calcs. */
	if (iSurfNodes > MAX_SURF_NODES) iSurfNodes = MAX_SURF_NODES;
	if (iWndoNodes > MAX_WNDO_NODES) iWndoNodes = MAX_WNDO_NODES;
	if (CalcGeomFromEPlus(bldg_ptr) < 0) {
		pofdmpfile[].write("ERROR: DElight Bad return from CalcGeomFromEPlus()\n");
		return(-4);
	}
	/* Fill SUN_DATA structure for sun position calculations. */
	if ((iNumAlts == 0) || (iNumAzms == 0)) {
		sun_data.nphs = NPHS;	/* number of sun position altitudes */
		sun_data.nths = NTHS;	/* number of sun position azimuths */
		sun_data.phsmin = 10.;	/* minimum sun altitude (degrees) */
		sun_data.thsmin = -110.;	/* minimum sun azimuth (degrees: South=0.0, East=+90.0) */
	}
	else {
		if (iNumAlts > NPHS) iNumAlts = NPHS;
		sun_data.nphs = iNumAlts;	/* number of sun position altitudes */
		if (iNumAzms > NTHS) iNumAzms = NTHS;
		sun_data.nths = iNumAzms;	/* number of sun position azimuths */
		sun_data.phsmin = dMinAlt;	/* minimum sun altitude (degrees) */
		sun_data.thsmin = dMinAzm;	/* minimum sun azimuth (degrees: South=0.0, East=+90.0) */
	}
	/* Calculate daylight illuminances and daylight factors. */
    var iCalcDFsReturnVal: Int32 = CalcDFs(sun_data,bldg_ptr,lib_ptr,iIterations,pofdmpfile);
	if (iCalcDFsReturnVal < 0) {
	    if (iCalcDFsReturnVal != -10) {
		    pofdmpfile[].write("ERROR: DElight Bad return from CalcDFs()\n");
		    return(-4);
        }
        else {
            iReturnVal = -10;
        }
	}
	/* Open output file. */
	if((outfile = fopen(sOutputName, "w" )) == None ) {
		pofdmpfile[].write("ERROR: DElight Cannot open output file [" + sOutputName + "]\n");
		return(-2);
	}
	/* Dump runtime data. */
	fprintf(outfile,"\n");
	fprintf(outfile,"RUNTIME DATA\n");
	fprintf(outfile,"Input_File_Name   %s\n", sInputName);
	fprintf(outfile,"Output_File_Name   %s\n", sOutputName);
	fprintf(outfile,"Cloud_Fraction %4.2lf\n", dCloudFraction);
	fprintf(outfile,"N_Surface_Nodes   %d\n", iSurfNodes);
	fprintf(outfile,"N_Window_Nodes   %d\n", iWndoNodes);
	fprintf(outfile,"N_Iterations   %d\n", iIterations);
	fprintf(outfile,"Min_Altitude      %5.2lf\n", dMinAlt);
	fprintf(outfile,"N_Altitude_Angles  %d\n", iNumAlts);
	fprintf(outfile,"Min_Azimuth       %5.2lf\n", dMinAzm);
	fprintf(outfile,"N_Azimuth_Angles   %d\n", iNumAzms);
	/* Dump bldg data. */
	dump_bldg(bldg_ptr,outfile);
	/* Dump lib data. */
	dump_lib(lib_ptr,outfile);
	/* Close output file. */
	fclose(outfile);
	return(iReturnVal);
}
/******************************** subroutine DElightElecLtgCtrl4EPlus *******************************/
/* Calls key daylighting simulation modules necessary for calculating
/******************************** subroutine DElightElecLtgCtrl4EPlus *******************************/
def DElightElecLtgCtrl4EPlus(
	bldg_ptr: Pointer[BLDG],			/* pointer to DElight Bldg data structure */
	zone_ptr: Pointer[ZONE],			/* pointer to DElight Zone data structure */
	dHISKF: Float64,			/* Exterior horizontal illuminance from sky (lum/ft^2) */
	dHISUNF: Float64,			/* Exterior horizontal beam illuminance (lum/ft^2) */
	dCloudFraction: Float64,	/* fraction of sky covered by clouds (0.0=clear 1.0=overcast) */
	dSOLCOS: Pointer[Float64, 0],		/* Direction cosines of current sun position */
	dMinAlt: Float64,			/* Minimum daylight factor sun altitude angle */
	dMinAzm: Float64,			/* Minimum daylight factor sun azimuth angle */
	dMaxAlt: Float64,			/* Maximum daylight factor sun altitude angle */
	dMaxAzm: Float64,			/* Maximum daylight factor sun azimuth angle */
	dAltInc: Float64,			/* Increment of daylight factor sun altitude angles */
	dAzmInc: Float64,			/* Increment of daylight factor sun azimuth angles */
    pofdmpfile: Pointer[OStream]) -> Int32   // ptr to Error message dump file
{
    var iReturnVal: Int32 = 0;
	var iphs: Int32;				/* sun position alt and azm interpolation indexes */
	var iths: Int32;				/* sun position alt and azm interpolation indexes */
	var phratio: Float64;	/* sun position alt and azm interpolation displacement ratios */
	var thratio: Float64;	/* sun position alt and azm interpolation displacement ratios */
	if (CalcInterpolationVars(bldg_ptr, dSOLCOS, dMinAlt, dMaxAlt, dAltInc, dMinAzm, dMaxAzm, dAzmInc, iphs, iths, phratio, thratio) < 0) {
		pofdmpfile[].write("ERROR: DElight Bad return from CalcInterpolationVars()\n");
		return(-5);
	}
	if (CalcZoneInteriorIllum(zone_ptr, dHISKF, dHISUNF, dCloudFraction, iphs, iths, phratio, thratio) < 0) {
		pofdmpfile[].write("ERROR: DElight Bad return from CalcZoneInteriorIllum()\n");
		return(-6);
	}
	var sun2_ptr: Pointer[SUN2_DATA] = new SUN2_DATA;
	sun2_ptr[].fsunup = 1.0;
    var iDltsysRetVal: Int32;
	if ((iDltsysRetVal = dltsys(zone_ptr, sun2_ptr, pofdmpfile)) < 0) {
        if (iDltsysRetVal != -10) {
			pofdmpfile[].write("ERROR: DElight error return from dltsys()\n");
			return(-7);
        }
        else {
			pofdmpfile[].write("WARNING: DElight warning return from dltsys()\n");
            iReturnVal = -10;
        }
    }
	return(iReturnVal);
}
/******************************** subroutine DElightFreeMemory4EPlus *******************************/
/* Calls key daylighting simulation modules necessary for freeing memory allocated by DElight for EnergyPlus. */
/******************************** subroutine DElightFreeMemory4EPlus *******************************/
def DElightFreeMemory4EPlus(
	bldg_ptr: Pointer[BLDG],		/* bldg data structure */
	lib_ptr: Pointer[LIB]) -> Int32		/* library data structure */
{
	/* Free bldg malloc-ed memory */
	free_bldg(bldg_ptr);
	/* Free lib malloc-ed memory */
	free_lib(lib_ptr);
	return(0);
}
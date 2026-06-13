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
from struct import *
from Loaddata import *
from geom import *
from EPlus_Loaddata import *
from EPlus_Geom import *
from DFcalcs import *
from ECM import *
from savedata import *
from TOOLS import *
from WxTMY2 import *
from W4Lib import *

from builtin import Float64, Int, String, File
from math import inf, nan

var INFINITY: Float64 = Float64.inf
var NaN_QUIET: Float64 = Float64.nan
var NaN_SIGNAL: Float64 = NaN_QUIET
var MAXPointTol: Float64 = 1.e-10

/******************************** subroutine DElight2 *******************************/
/* Calls key daylighting simulation modules. */
/* This is the key exported function that defines the DElight2 API */
/* for standalone use, or integration with programs other than EnergyPlus. */
/* NOT USED in integration with EnergyPlus. */
/******************************** subroutine DElight2 *******************************/
def DElight2(
    sWxName: String,		/* weather file name */
    sInputName: String,	/* input file name */
    sOutputName: String,	/* output file name */
    sW4LibName: String,	/* Window 4 Library file name */
    iIterations: Int,					/* Number of radiosity iterations */
    dCloudFraction: Float64,				/* fraction of sky covered by clouds (0.0=clear 1.0=overcast) */
    iSurfNodes: Int,						/* Desired total number of surface nodes */
    iWndoNodes: Int,						/* Desired total number of window nodes */
    iNumAlts: Int,						/* Number of preprocessor sun altitude angles */
    dMinAlt: Float64,						/* Minimum preprocessor sun altitude angle */
    iNumAzms: Int,						/* Number of preprocessor sun azimuth angles */
    dMinAzm: Float64,						/* Minimum preprocessor sun azimuth angle */
    iStrtMonth: Int,						/* Beginning month of run period */
    iStrtDay: Int,						/* Beginning day of month of run period */
    iEndMonth: Int,						/* Ending month of run period */
    iEndDay: Int,						/* Ending month of run period */
    iYear: Int) -> Int							/* 4 digit year of run period */
{
    var wxfile: File? = None;						/* weather file pointer */
    var infile: File? = None;						/* input file pointer */
    var outfile: File? = None;						/* output file pointer */
    var W4libfile: File? = None;					/* Window 4 library file pointer */
    var ofdmpfile: File = File("DElight2.DMP", "w");	/* LBLDLL debug dump file */
    var bldg: BLDG = BLDG();							/* bldg data structure */
    var lib: LIB = LIB();							/* library data structure */
    var run_data: RUN_DATA = RUN_DATA();					/* run data structure */
    var sun_data: SUN_DATA = SUN_DATA();	/* sun data structure */
    var wx_flag: Int = 0;		/* Wxfile flag */
    var iReturnVal: Int = 0; // Return value
    if not ofdmpfile.is_open():
    {
        return (-1)
    }
    /* initialize BLDG and LIB structures */
    struct_init("BLDG", bldg)
    struct_init("LIB", lib)
    if File(sInputName, "r") as infile_temp:
    {
        infile = infile_temp
    }
    else:
    {
        ofdmpfile.write("ERROR: DElight cannot open input file [" + sInputName + "]\n")
        /* Close dump file. */
        ofdmpfile.close()
        return(-3)
    }
    var cInputLine: String = infile.read_line()	/* Input line */
    if cInputLine.size() == 0:
        return -1
    var cInputVersion: String = ""
    var parts = cInputLine.split()
    if parts.size() >= 2:
        cInputVersion = parts[1]
    if (cInputVersion == "EPlus") or (cInputVersion == "2.3"):
    {
        if LoadDataFromEPlus(bldg, infile, ofdmpfile) < 0:
        {
            ofdmpfile.write("ERROR: DElight Bad Building data read from input file [" + sInputName + "]\n")
            /* Close dump file. */
            ofdmpfile.close()
            /* Close input file. */
            infile.close()
            return(-4)
        }
        /* load library data from input file */
        if LoadLibDataFromEPlus(lib, infile, ofdmpfile) < 0:
        {
            ofdmpfile.write("ERROR: DElight Bad Library data read from input file [" + sInputName + "]\n")
            /* Close dump file. */
            ofdmpfile.close()
            /* Close input file. */
            infile.close()
            return(-4)
        }
        /* Close input file after successful read. */
        infile.close()
        /* Calculate geometrical values required for DF calcs. */
        if iSurfNodes > MAX_SURF_NODES:
            iSurfNodes = MAX_SURF_NODES
        if iWndoNodes > MAX_WNDO_NODES:
            iWndoNodes = MAX_WNDO_NODES
        if CalcGeomFromEPlus(bldg) < 0:
        {
            ofdmpfile.write("ERROR: DElight Bad return from CalcGeomFromEPlus()\n")
            /* Close dump file. */
            ofdmpfile.close()
            return(-4)
        }
    }
    else // use old load_bldg()
    {
        if load_bldg(bldg, infile, ofdmpfile) < 0:
        {
            ofdmpfile.write("ERROR: DElight Bad Building data read from input file [" + sInputName + "]\n")
            /* Close dump file. */
            ofdmpfile.close()
            /* Close input file. */
            infile.close()
            return(-4)
        }
        /* load library data from input file */
        if load_lib(lib, infile, ofdmpfile) < 0:
        {
            ofdmpfile.write("ERROR: DElight Bad Library data read from input file [" + sInputName + "]\n")
            /* Close dump file. */
            ofdmpfile.close()
            /* Close input file. */
            infile.close()
            return(-4)
        }
        /* Close input file after successful read. */
        infile.close()
        /* Translate user oriented bldg geometry to DOE2 bldg coord system. */
        /* Also, calculate radiosity related geometrical values. */
        if iSurfNodes > MAX_SURF_NODES:
            iSurfNodes = MAX_SURF_NODES
        if iWndoNodes > MAX_WNDO_NODES:
            iWndoNodes = MAX_WNDO_NODES
        if geometrans(bldg, iSurfNodes, iWndoNodes, ofdmpfile) < 0:
        {
            ofdmpfile.write("ERROR: DElight Bad return from geometrans()\n")
            /* Close dump file. */
            ofdmpfile.close()
            return(-4)
        }
    }
    /* Open Window4 library file and read and process glazing types included in user input file. */
    if sW4LibName != "":
    {
        if File(sW4LibName, "r") as W4libfile_temp:
        {
            W4libfile = W4libfile_temp
        }
        else:
        {
            ofdmpfile.write("ERROR: DElight Cannot open Window4 library file [" + sW4LibName + "]\n")
            /* Close dump file. */
            ofdmpfile.close()
            return(-5)
        }
        if True:
        {
            /* read and process glazing types included in user input file */
            if process_W4glazing_types(bldg, lib, W4libfile, ofdmpfile) < 0:
            {
                ofdmpfile.write("ERROR: DElight Bad Window4 Library data read from file [" + sW4LibName + "]\n")
                /* Close dump file. */
                ofdmpfile.close()
                return(-5)
            }
            /* Close Window4 library file. */
            W4libfile.close()
        }
    }
    /* Open TMY2 weather file and read header information. */
    if sWxName == "":
    {
        wx_flag = 0
    }
    else:
    {
        if File(sWxName, "r") as wxfile_temp:
        {
            wxfile = wxfile_temp
            /* read header information */
            if read_wx_tmy2_hdr(bldg, wxfile) < 0:
                return(-1)
            wx_flag = 1
        }
        else:
        {
            ofdmpfile.write("WARNING: DElight Cannot open weather file [" + sWxName + "]\n")
            wx_flag = 0
            iReturnVal = -10
        }
    }
    /* Fill SUN_DATA structure for sun position calculations. */
    if (iNumAlts == 0) or (iNumAzms == 0):
    {
        sun_data.nphs = NPHS	/* number of sun position altitudes */
        sun_data.nths = NTHS	/* number of sun position azimuths */
        sun_data.phsmin = 10.	/* minimum sun altitude (degrees) */
        sun_data.thsmin = -110.	/* minimum sun azimuth (degrees: South=0.0, East=+90.0) */
    }
    else:
    {
        if iNumAlts > NPHS:
            iNumAlts = NPHS
        sun_data.nphs = iNumAlts	/* number of sun position altitudes */
        if iNumAzms > NTHS:
            iNumAzms = NTHS
        sun_data.nths = iNumAzms	/* number of sun position azimuths */
        sun_data.phsmin = dMinAlt	/* minimum sun altitude (degrees) */
        sun_data.thsmin = dMinAzm	/* minimum sun azimuth (degrees: South=0.0, East=+90.0) */
    }
    /* Calculate daylight illuminances and daylight factors. */
    var iCalcDFsReturnVal: Int = CalcDFs(sun_data, bldg, lib, iIterations, ofdmpfile)
    if iCalcDFsReturnVal < 0:
    {
        if iCalcDFsReturnVal != -10:
        {
            ofdmpfile.write("ERROR: DElight Bad return from CalcDFs()\n")
            /* Close dump file. */
            ofdmpfile.close()
            /* Close wx file. */
            if wx_flag != 0:
                wxfile.close()
            return(-4)
        }
        else:
        {
            iReturnVal = -10
        }
    }
    /* Set hourly run period data. */
    /* Beginning month of run period. */
    run_data.mon_begin = iStrtMonth
    /* Beginning day of month of run period */
    run_data.day_begin = iStrtDay
    /* Ending month of run period */
    run_data.mon_end = iEndMonth
    /* Ending day of month of run period */
    run_data.day_end = iEndDay
    /* 4 digit year of run period */
    run_data.year = iYear
    /* Check for no run period specified => do not perform hourly calcs. */
    if (iStrtMonth != 0) and (iStrtDay != 0) and (iEndMonth != 0) and (iEndDay != 0):
    {
        /* Calculate hourly illuminances, glare index and fractional electric light reductions due to daylight. */
        var iDillumReturnVal: Int = dillum(dCloudFraction, bldg, sun_data, run_data, wx_flag, wxfile, ofdmpfile)
        if iDillumReturnVal < 0:
        {
            if iDillumReturnVal != -10:
            {
                ofdmpfile.write("ERROR: DElight Bad return from dillum()\n")
                /* Close dump file. */
                ofdmpfile.close()
                /* Close wx file. */
                if wx_flag != 0:
                    wxfile.close()
                return(-4)
            }
            else:
            {
                iReturnVal = -10
            }
        }
    }
    /* Open output file. */
    if File(sOutputName, "w") as outfile_temp:
    {
        outfile = outfile_temp
    }
    else:
    {
        ofdmpfile.write("ERROR: DElight Cannot open output file [" + sOutputName + "]\n")
        /* Close dump file. */
        ofdmpfile.close()
        /* Close wx file. */
        if wx_flag != 0:
            wxfile.close()
        return(-2)
    }
    /* Dump runtime data. */
    outfile.write("RUNTIME DATA\n")
    outfile.write("Input_File_Name   " + sInputName + "\n")
    outfile.write("Output_File_Name   " + sOutputName + "\n")
    outfile.write("Weather_File_Name " + sWxName + "\n")
    outfile.write("W4Lib_File_Name " + sW4LibName + "\n")
    outfile.write("Cloud_Fraction " + String(dCloudFraction, precision=2) + "\n")
    outfile.write("N_Surface_Nodes   " + String(iSurfNodes) + "\n")
    outfile.write("N_Window_Nodes   " + String(iWndoNodes) + "\n")
    outfile.write("N_Iterations   " + String(iIterations) + "\n")
    outfile.write("Min_Altitude      " + String(dMinAlt, precision=2) + "\n")
    outfile.write("N_Altitude_Angles  " + String(iNumAlts) + "\n")
    outfile.write("Min_Azimuth       " + String(dMinAzm, precision=2) + "\n")
    outfile.write("N_Azimuth_Angles   " + String(iNumAzms) + "\n")
    outfile.write("Start_Month " + String(iStrtMonth) + "\n")
    outfile.write("Start_Day   " + String(iStrtDay) + "\n")
    outfile.write("End_Month   " + String(iEndMonth) + "\n")
    outfile.write("End_Day     " + String(iEndDay) + "\n")
    outfile.write("Year " + String(iYear) + "\n")
    /* Dump bldg data. */
    dump_bldg(bldg, outfile)
    /* Dump lib data. */
    dump_lib(lib, outfile)
    /* Free bldg malloc-ed memory */
    free_bldg(bldg)
    /* Free lib malloc-ed memory */
    free_lib(lib)
    /* Close output file. */
    outfile.close()
    /* Close error output file. */
    ofdmpfile.close()
    /* Close wx file. */
    if wx_flag != 0:
        wxfile.close()
    return iReturnVal
}
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
// #pragma warning(disable:4786)  (not applicable in Mojo)
from math import abs, fabs as c_fabs  # fabs is just abs on floats
from file import FileHandle, open
from string import String
from BGL import *  # assume BGL.mojo exists
from CONST import *  # CONST.H -> CONST.mojo
from DBCONST import *  # DBCONST.H -> DBCONST.mojo
from DEF import *  # DEF.H -> DEF.mojo
from NodeMesh2 import *  # NodeMesh2.h -> NodeMesh2.mojo
from WLCSurface import *  # WLCSurface.h -> WLCSurface.mojo
from helpers import *  # helpers.h -> helpers.mojo (contains str_blnk2undr etc.)
from hemisphiral import *  # hemisphiral.h -> hemisphiral.mojo
from btdf import *  # btdf.h -> btdf.mojo
from CFSSystem import *  # CFSSystem.h -> CFSSystem.mojo
from CFSSurface import *  # CFSSurface.h -> CFSSurface.mojo
from DOE2DL import *  # DOE2DL.H -> DOE2DL.mojo
from TOOLS import *  # TOOLS.H -> TOOLS.mojo
from DElight2 import *  # DElight2.h -> DElight2.mojo (DElightDaylightFactors4EPlus, DElightElecLtgCtrl4EPlus, DElightFreeMemory4EPlus)

# Global variables
var bldg: BLDG  # DElight bldg data structure
var lib: LIB  # DElight library data structure
var ofdmpfile: FileHandle = None  # Error message dump file
var iErrorOccurred: Int = 0  # Error/Warning occurred flag

/******************************** subroutine writewndo *******************************/
/* Error/Warning handling routine for WLC code modules. */
/******************************** subroutine writewndo *******************************/
def writewndo(in instring: String, sfpflg: String):
    if not ofdmpfile:
        iErrorOccurred = 1
        raise Error("ERROR: DElight - No open Error Message file\n")
    if sfpflg.size() == 0:
        return
    if sfpflg[0] == 'e':
        ofdmpfile.write("ERROR: DElight - " + instring + "\n")
        iErrorOccurred = 2
        raise Error("")
    elif sfpflg[0] == 'w':
        ofdmpfile.write("WARNING: DElight - " + instring + "\n")
        iErrorOccurred = 3
        return
    else:
        return
    return

/******************************** subroutine delightdaylightcoefficients *******************************/
/* Calls the DElight daylighting factors/coefficients routine from the DElight DLL. */
/* Exported subroutine for EnergyPlus preprocessing call to DElight. */
/* See corresponding Interface Subroutine in DElightManagerF.cc EnergyPlus module. */
/******************************** subroutine delightdaylightcoefficients *******************************/
def delightdaylightcoefficients(dBldgLat: Float64, inout piErrorFlag: Int):
    ofdmpfile = open("eplusout.delightdfdmp", "w")
    if not ofdmpfile:
        piErrorFlag = -1
        return

try:
    var cFullInputFilename: String = "eplusout.delightin"
    var cFullOutputFilename: String = "eplusout.delightout"

    /* Set limits of sun position angles. */
    var dphsmin: Float64 = 10.0
    if abs(dBldgLat) >= 48.0:
        dphsmin = 5.0
    var dthsmin: Float64 = -110.0
    /* Minimum solar azimuth for southern hemisphere */
    if dBldgLat < 0.0:
        dthsmin = 70.0

    var iErrorFlag: Int = 0
    iErrorFlag = DElightDaylightFactors4EPlus(
        cFullInputFilename,     /* input file name */
        cFullOutputFilename,    /* output file name */
        bldg,                   /* pointer to DElight bldg data structure */
        lib,                    /* pointer to DElight library data structure */
        5,                      /* number of radiosity iterations */
        0.0,                    /* fraction of sky covered by clouds (0.0=clear 1.0=overcast) */
        10,                     /* Desired number of surface nodes */
        10,                     /* Desired number of window nodes */
        NPHS,                   /* Number of preprocessor sun altitude angles (0 => Full Set) */
        dphsmin,                /* Minimum preprocessor sun altitude angle */
        NTHS,                   /* Number of preprocessor sun azimuth angles (0 => Full Set) */
        dthsmin,                /* Minimum preprocessor sun azimuth angle */
        ofdmpfile               /* Error message dump file */
    )
    if iErrorFlag < 0:
        piErrorFlag = iErrorFlag
    if iErrorOccurred == 3:  # Warning(s) occurred
        piErrorFlag = -10

    ofdmpfile.close()
    return
# end try
except e as String:
    if iErrorOccurred == 1:
        ofdmpfile = open("eplusout.delightdfdmp", "w")
        var msg: String = e + "\n"
        ofdmpfile.write(msg)
        ofdmpfile.close()
        piErrorFlag = -2
        return
    else:
        ofdmpfile.close()
        piErrorFlag = -2
        return
# (The original had a separate catch for char*, but behaviour identical; combined)

/******************************** subroutine delightelecltgctrl *******************************/
/* Calls the DElight daylighting interior illuminance and electric lighting control routines from the DElight DLL. */
/* Exported subroutine for EnergyPlus timestep call to DElight. */
/* See corresponding Interface Subroutine in DElightManagerF.cc EnergyPlus module. */
/******************************** subroutine delightelecltgctrl *******************************/
def delightelecltgctrl(
    iNameLength: Int,
    cZoneName: String,
    dBldgLat: Float64,
    dHISKF: Float64,
    dHISUNF: Float64,
    dCloudFraction: Float64,
    dSOLCOSX: Float64,
    dSOLCOSY: Float64,
    dSOLCOSZ: Float64,
    inout pdPowerReducFac: Float64,
    inout piErrorFlag: Int):
    ofdmpfile = open("eplusout.delighteldmp", "a")  # ios_base::out | ios_base::app => append mode
    if not ofdmpfile:
        piErrorFlag = -1
        return

try:
    /* Set limits of sun position angles. */
    var dphsmin: Float64 = 10.0
    if abs(dBldgLat) >= 48.0:
        dphsmin = 5.0
    /* Maximum altitude and altitude angle increment for sun positions. */
    var dphsmax: Float64 = min(90.0, 113.5 - abs(dBldgLat))
    var dphsdel: Float64 = (dphsmax - dphsmin) / Float64((4 - 1))
    var dthsmin: Float64 = -110.0
    /* Minimum solar azimuth for southern hemisphere */
    if dBldgLat < 0.0:
        dthsmin = 70.0
    /* Maximum azimuth and azimuth angle increment for sun positions. */
    var dthsdel: Float64 = abs(2.0 * dthsmin) / Float64((5 - 1))
    var dthsmax: Float64 = dthsmin + dthsdel * Float64((5 - 1))

    var dSOLCOS: Array[Float64, 3] = Array[Float64, 3](
        dSOLCOSX, dSOLCOSY, dSOLCOSZ
    )

    # Null-terminate and truncate zone name
    cZoneName = cZoneName.substring(0, iNameLength)
    cZoneName = str_blnk2undr(cZoneName)

    var iZone: Int
    for iZone in range(bldg.nzones):
        if bldg.zone[iZone].name == cZoneName:
            break

    var iErrorFlag: Int = 0
    iErrorFlag = DElightElecLtgCtrl4EPlus(
        bldg,                    /* pointer to DElight Bldg data structure */
        bldg.zone[iZone],        /* pointer to DElight Zone data structure */
        dHISKF,                  /* Exterior horizontal illuminance from sky (lum/m^2) */
        dHISUNF,                 /* Exterior horizontal beam illuminance (lum/m^2) */
        dCloudFraction,          /* fraction of sky covered by clouds (0.0=clear 1.0=overcast) */
        dSOLCOS,                 /* Direction cosines of current sun position */
        dphsmin,                 /* Minimum daylight factor sun altitude angle */
        dthsmin,                 /* Minimum daylight factor sun azimuth angle */
        dphsmax,                 /* Maximum daylight factor sun altitude angle */
        dthsmax,                 /* Maximum daylight factor sun azimuth angle */
        dphsdel,                 /* Increment of daylight factor sun altitude angles */
        dthsdel,                 /* Increment of daylight factor sun azimuth angles */
        ofdmpfile                /* Error message dump file */
    )
    if iErrorFlag < 0:
        piErrorFlag = iErrorFlag
    if iErrorOccurred == 3:  # Warning(s) occurred
        piErrorFlag = -10

    pdPowerReducFac = bldg.zone[iZone].frac_power
    /* Close Error message dump file. */
    ofdmpfile.close()
    return
# end try
except e as String:
    if iErrorOccurred == 1:
        ofdmpfile = open("eplusout.delighteldmp", "w")
        var msg: String = e + "\n"
        ofdmpfile.write(msg)
        ofdmpfile.close()
        piErrorFlag = -2
        return
    else:
        ofdmpfile.close()
        piErrorFlag = -2
        return
# (Combined catch for both string and char* throws)

/******************************** subroutine delightfreememory *******************************/
/* Calls the DElight routines to free memory allocated by DElight */
/* Not currently used by EnergyPlus. */
/******************************** subroutine delightfreememory *******************************/
def delightfreememory():
    DElightFreeMemory4EPlus(
        bldg,  /* pointer to DElight bldg data structure */
        lib   /* pointer to DElight library data structure */
    )
    return

/****************************** subroutine delightoutputgenerator *****************************/
/* Calls the DElight routine to generate a DElight output file tailored by the output flag */
/* Not currently used by EnergyPlus. */
/* All EnergyPlus related output are passed back to EnergyPlus either through parameter list */
/* or via temporary ASCII file. */
/****************************** subroutine delightoutputgenerator *****************************/
def delightoutputgenerator(iOutputFlag: Int):
    # (void)iOutputFlag;  # unused parameter
    return
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
from DElightManagerC import *
from CONST import *
from DBCONST import *
from DEF import *
from helpers import *
from hemisphiral import *
from NodeMesh2 import *
from WLCSurface import *
from btdf import *
from CFSSurface import *
from DOE2DL import *

var NaN_SIGNAL: Float64

@value
class CFSSystem:
    var syst_type: String
    var sky_type: String
    var lp: LumParam
    var pbtdf0: btdf

    def __init__(inout self):

    def __init__(inout self, SysType: String, lpIn: LumParam):
        self.syst_type = SysType
        self.lp = lpIn
        self.pbtdf0 = btdf()
        if self.lp.object == "BTDF":
            if self.lp.source == "GEN":
                self.pbtdf0 = GenBTDF(self.lp)
            elif self.lp.source == "FILE":
                var infile = open(self.lp.filename, "r")
                if not infile:
                    writewndo("Cannot Open BTDF Data File - must be located in EnergyPlus EXE directory\n", "e")
                if infile:
                    self.pbtdf0 = btdfLoad(infile)
        else:
            self.pbtdf0 = btdf()

    def __del__(owned self):

    def TypeName(self) -> String:
        return self.syst_type

    def SetType(inout self, type: String):
        self.syst_type = type

    def ResetLumParam(inout self, lpIn: LumParam):
        self.lp = lpIn

    def CFSLuminanceMap(self, sky: HemiSphiral, ics: BGL.RHCoordSys3) -> HemiSphiral:
        var LumMap: HemiSphiral
        if self.lp.object == "LUMMAP":
            if self.lp.source == "GEN":
                LumMap = GenLuminanceMap(self.lp)
            elif self.lp.source == "FILE":
                var infile = open(self.lp.filename, "r")
                if infile:
                    LumMap.load(infile)
        elif self.lp.object == "BTDF":
            if self.pbtdf0.size() > 0:
                LumMap = SkyBTDFIntegration(sky, self.pbtdf0, ics)
        elif self.lp.object == "WINDOW":
            if self.lp.source == "GEN":
                LumMap = GenWindowMap(self.lp, sky, ics)
            elif self.lp.source == "FILE":
                var infile = open(self.lp.filename, "r")
                if infile:
                    LumMap.load(infile)
        return LumMap

    def Dump(self):
        print("CFSSystem Params:")
        print("syst_type: " + self.syst_type)
        self.lp.Dump()
        if self.pbtdf0:
            self.pbtdf0.summary()
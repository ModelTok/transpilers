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
NEITHER THE UNITED STATES NOR THE UNITED STATES GOVERNMENT, NOR ANY OF
THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL 
LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY 
INFORMATION, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE 
WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
*/
from BGL import *
from CONST import *
from DBCONST import *
from DEF import *
from helpers import *
from hemisphiral import *
from NodeMesh2 import *
from WLCSurface import *
from btdf import *
from CFSSystem import *
from DOE2DL import *

extern MAXPointTol: Float64

@value
class CFSSurface(WLCSurface):
    var pParent: Pointer[SURF]
    var CFStype: String
    var rotangle: Float64
    var reveal: Float64
    var LumMap: HemiSphiral

    def __init__(inout self):

    def __init__(inout self, Parent: Pointer[SURF], CFSTypeName: String, lm: HemiSphiral, rotation: Float64, p3List: List[point3], CFSmaxNodeArea: Float64):
        self.pParent = Parent
        self.CFStype = CFSTypeName
        self.rotangle = rotation
        self.reveal = 0.0
        self.LumMap = lm
        var name: String = "CFS_"
        self.WLCSurfInit(name, p3List, CFSmaxNodeArea)

    def __del__(owned self):

    def TypeName(self) -> String:
        return self.CFStype

    def Reveal(self) -> Float64:
        return self.reveal

    def Reveal(self, rval: Float64):
        self.reveal = rval

    def fReveal(self, costheta: Float64) -> Float64:
        if self.reveal == 0.0:
            return 1.0
        if costheta <= 0.0:
            return 0.0
        if costheta > 1.0:
            return 1.0
        var tantheta: Float64 = sqrt(1.0 / (costheta * costheta) - 1.0)
        var fReveal: Float64 = max(1.0 - self.reveal * tantheta / sqrt(self.Area()), 0.0)
        return fReveal

    def GetLumMap(self) -> HemiSphiral:
        return self.LumMap

    def ResetLumMap(self, lm: HemiSphiral) -> Int:
        self.LumMap = lm
        return self.LumMap.size()

    def CFSDirIllum(self, dir_CFSCS: vector3) -> Float64:
        return self.LumMap.interp(dir_CFSCS)

    def TotRefPtIllum(self, ExtPtNormal: vector3, ExtPtPosition: point3) -> Float64:
        if plane3.Behind(ExtPtPosition):
            return 0.0
        var visDot: Float64
        var TotExtPtIllum: Float64 = 0.0
        for ii in range(self.MeshSize()):
            var VDir_wcs: vector3 = ExtPtPosition - self.NodePosition3D(ii)
            visDot = dot(norm(VDir_wcs), ExtPtNormal)
            if visDot >= 0.0:
                continue
            var VDir_CFS: vector3 = dirWCStoLCS(norm(VDir_wcs), self.ics)
            var CFSNodeLum: Float64 = max(0.0, self.CFSDirIllum(VDir_CFS) * self.NodeArea(ii) * VDir_CFS[2] * self.fReveal(VDir_CFS[2]))
            var ExtPtSolidAngle: Float64 = min(2.0 * PI, -visDot / sqrlen(VDir_wcs))
            TotExtPtIllum += CFSNodeLum * ExtPtSolidAngle
        return TotExtPtIllum
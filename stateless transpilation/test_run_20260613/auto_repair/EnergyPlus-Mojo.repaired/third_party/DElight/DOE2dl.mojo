/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Authors: W.L. Carroll and R.J. Hitchcock
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
from CONST import *
from DBCONST import *
from DEF import *
from helpers import *
from hemisphiral import *
from NodeMesh2 import *
from WLCSurface import *
from btdf import *
from CFSSystem import *
from CFSSurface import *
from DOE2DL import *

struct SURF:
    var nwndos: Int
    var ncfs: Int
    var wndo: Pointer[Pointer[WNDO]]
    var cfs: Pointer[Pointer[CFS]]
    var v3List_WLC: Pointer[BGL.vector3]
    var node: Pointer[Pointer[Double]]
    var node_areas: Pointer[Double]
    var nnodes: Int

    def __init__(inout self):
        self.nwndos = 0
        self.ncfs = 0

    def WLCSURFInit(inout self, Name: String, maxNodeArea: Double):
        self.WLCSurfInit(Name, self.v3List_WLC, maxNodeArea)
        var iMaxSurfNodes: Int = MAX_SURF_NODES
        var dSurfArea: Double = self.Area()
        while self.MeshSize() > MAX_SURF_NODES:
            var dAllowableMaxNodeArea: Double = dSurfArea / iMaxSurfNodes
            self.WLCSurfInit("", self.v3List_WLC, dAllowableMaxNodeArea)
            iMaxSurfNodes -= 1
        var ii: Int
        var jj: Int
        var p2List: List[BGL.point2]
        var v3: BGL.vector3
        for ii in range(self.nwndos):
            p2List = List[BGL.point2](self.wndo[ii][].nvert())
            for jj in range(self.wndo[ii][].nvert()):
                v3 = self.wndo[ii][].vert3D(jj) - self.vert3D(0)
                p2List[jj] = BGL.point2(BGL.dot(v3, self.icsAxis(0)), BGL.dot(v3, self.icsAxis(1)))
            self.MeshCutout(BGL.poly2(p2List))
        for ii in range(self.ncfs):
            p2List = List[BGL.point2](self.cfs[ii][].nvert())
            for jj in range(self.cfs[ii][].nvert()):
                v3 = self.cfs[ii][].vert3D(jj) - self.vert3D(0)
                p2List[jj] = BGL.point2(BGL.dot(v3, self.icsAxis(0)), BGL.dot(v3, self.icsAxis(1)))
            self.MeshCutout(BGL.poly2(p2List))
        self.nnodes = self.MeshSize()
        for ii in range(self.nnodes):
            self.node_areas[ii] = self.NodeArea(ii)
            var p3: BGL.point3 = self.NodePosition3D(ii)
            self.node[ii][0] = p3[0]
            self.node[ii][1] = p3[1]
            self.node[ii][2] = p3[2]

    def NetArea(inout self) -> Double:
        var ii: Int
        var area: Double = self.Area()
        for ii in range(self.nwndos):
            area -= self.wndo[ii][].Area()
        for ii in range(self.ncfs):
            area -= self.cfs[ii][].Area()
        return area

struct WNDO:
    var v3List_WLC: Pointer[BGL.vector3]
    var node: Pointer[Pointer[Double]]
    var node_areas: Pointer[Double]
    var nnodes: Int

    def WLCWNDOInit(inout self, maxNodeArea: Double):
        self.WLCSurfInit("", self.v3List_WLC, maxNodeArea)
        var iMaxWndoNodes: Int = MAX_WNDO_NODES
        var dWndoArea: Double = self.Area()
        while self.MeshSize() > MAX_WNDO_NODES:
            var dAllowableMaxNodeArea: Double = dWndoArea / iMaxWndoNodes
            self.WLCSurfInit("", self.v3List_WLC, dAllowableMaxNodeArea)
            iMaxWndoNodes -= 1
        self.nnodes = self.MeshSize()
        for ii in range(self.nnodes):
            self.node_areas[ii] = self.NodeArea(ii)
            var p3: BGL.point3 = self.NodePosition3D(ii)
            self.node[ii][0] = p3[0]
            self.node[ii][1] = p3[1]
            self.node[ii][2] = p3[2]
/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Authors: W.L. Carroll and R.J. Hitchcock
 *           Building Technologies Department
 *           Lawrence Berkeley National Laboratory
 */
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
from DEF import *
from NodeMesh2 import *
from WLCSurface import *

@value
struct WLCSurface:
    var vis_refl: Double
    var mesh: NodeMesh2
    var name: String
    var origin: BGL.point3
    var ics: BGL.RHCoordSys3
    var vert2: BGL.poly2

    def __init__(inout self):

    def __del__(owned self):

    def __init__(inout self, Name: String, Origin: BGL.point3, Sazm: Double, Stilt: Double, Szeta: Double, p2List: List[BGL.point2], maxNodeArea: Double):
        self.name = Name
        self.origin = Origin
        self.ics = BGL.RHCoordSys3(Origin, Sazm, Stilt, Szeta)
        self.vert2 = BGL.poly2(p2List)
        self.vis_refl = 1.0
        self.mesh = NodeMesh2(self.vert2, maxNodeArea)

    def __init__(inout self, Name: String, Origin: BGL.point3, Sazm: Double, Stilt: Double, Szeta: Double, p2List: List[BGL.point2], maxNodeArea: Double, visrefl: Double):
        self.name = Name
        self.origin = Origin
        self.ics = BGL.RHCoordSys3(Origin, Sazm, Stilt, Szeta)
        self.vert2 = BGL.poly2(p2List)
        self.vis_refl = visrefl
        self.mesh = NodeMesh2(self.vert2, maxNodeArea)

    def __init__(inout self, Name: String, Origin: BGL.point3, Sazm: Double, Stilt: Double, Szeta: Double, width: Double, height: Double, maxNodeArea: Double):
        self.name = Name
        self.origin = Origin
        self.ics = BGL.RHCoordSys3(Origin, Sazm, Stilt, Szeta)
        self.vert2 = BGL.poly2(width, height)
        self.vis_refl = 1.0
        self.mesh = NodeMesh2(self.vert2, maxNodeArea)

    def __init__(inout self, Name: String, Origin: BGL.point3, Sazm: Double, Stilt: Double, Szeta: Double, width: Double, height: Double, maxNodeArea: Double, visrefl: Double):
        self.name = Name
        self.origin = Origin
        self.ics = BGL.RHCoordSys3(Origin, Sazm, Stilt, Szeta)
        self.vert2 = BGL.poly2(width, height)
        self.vis_refl = visrefl
        self.mesh = NodeMesh2(self.vert2, maxNodeArea)

    def __init__(inout self, Name: String, p3List: List[BGL.point3], maxNodeArea: Double):
        self.WLCSurfInit(Name, p3List, maxNodeArea)

    def WLCSurfInit(inout self, Name: String, p3List: List[BGL.point3], maxNodeArea: Double):
        self.name = Name
        self.origin = p3List[0]
        self.ics = BGL.RHCoordSys3(p3List[0], p3List[1], p3List[2])
        var p2List: List[BGL.point2] = List[BGL.point2](p3List.size)
        for ii in range(p3List.size):
            var v3: BGL.vector3 = p3List[ii] - p3List[0]
            p2List[ii] = BGL.point2(BGL.dot(v3, self.ics[0]), BGL.dot(v3, self.ics[1]))
        self.vert2 = BGL.poly2(p2List)
        self.mesh = NodeMesh2(self.vert2, maxNodeArea)

    def Area(self) -> Double:
        return self.vert2.Area()

    def VisRefl(self) -> Double:
        return self.vis_refl

    def Dump(self):
        print("WLCSurface: ")
        print('"' + self.name + '"')
        print("offset: ", self.origin)
        print("l.c.s.: ", self.ics)
        print("vNorm: ", self.normVec())
        print("azm: ", self.phi() * 180.0 / PI, " tilt: ", self.theta() * 180.0 / PI, " zeta: ", self.zeta() * 180.0 / PI)
        print("nVerts: ", self.nvert())
        print("Area: ", self.Area())
        print("Vis_Refl: ", self.vis_refl)
        print("boundary2D: ", self.vert2)
        print("boundary3D: ", end="")
        for ii in range(self.nvert()):
            print(self.vert3D(ii), end=" ")
        print()
        self.mesh.SummaryDump()

    def NodeDump(self):
        self.mesh.SummaryDump()
        for ii in range(self.MeshSize()):
            print(ii, end=" ")
            print(self.NodePosition2D(ii), end=" ")
            print(self.NodePosition3D(ii), end=" ")
            print(self.NodeArea(ii), end=" ")
            print()

    def MeshSize(self) -> Int:
        return self.mesh.size()

    def MeshGrid1(inout self, nodeArea_max: Double) -> Int:
        return self.mesh.grid1(self.vert2, nodeArea_max)

    def MeshGrid2(inout self, nodeArea_max: Double) -> Int:
        return self.mesh.grid2(self.vert2, nodeArea_max)

    def MeshCutout(inout self, p2: BGL.poly2) -> Int:
        return self.mesh.remove(p2)

    def NodePosition2D(self, NodeIterator: Int) -> BGL.point2:
        return self.mesh[NodeIterator].position

    def NodePosition3D(self, NodeIterator: Int) -> BGL.point3:
        return self.point2to3D(self.mesh[NodeIterator].position)

    def NodeArea(self, NodeIterator: Int) -> Double:
        return self.mesh[NodeIterator].area

    def NodeOmega(self, NodeIterator: Int, extPoint: BGL.point3) -> Double:
        if self.Behind(extPoint):
            return 0.0
        var visDot: Double
        var NodeSolidAngle: Double = 0.0
        var VDir_wcs: BGL.vector3 = extPoint - self.NodePosition3D(NodeIterator)
        visDot = BGL.dot(BGL.norm(VDir_wcs), self.ics[2])
        NodeSolidAngle = min(2.0 * PI, visDot / BGL.sqrlen(VDir_wcs)) * self.NodeArea(NodeIterator)
        return NodeSolidAngle

    def NearestNodeIndx(self, extPoint: BGL.point2) -> Int:
        return self.mesh.NearestToPext(extPoint)

    def NodeTotIllum(self, NodeIterator: Int) -> Double:
        var nd: NodeData = self.mesh[NodeIterator].data
        return nd.CFSIllum + nd.NodeIllum + nd.WindowIllum

    def NodeTotLum(self, NodeIterator: Int) -> Double:
        return self.vis_refl * self.NodeTotIllum(NodeIterator) / PI

    def GetNodeData(self, NodeIterator: Int) -> NodeData:
        return self.mesh[NodeIterator].data

    def SetNodeData(inout self, NodeIterator: Int, indata: NodeData):
        self.mesh[NodeIterator].data = indata

    def DirNodetoExt(self, NodeIterator: Int, ExtPoint: BGL.point3) -> BGL.vector3:
        return BGL.norm(BGL.vector3(self.NodePosition3D(NodeIterator), ExtPoint))

    def normVec(self) -> BGL.vector3:
        return self.ics[2]

    def phi(self) -> Double:
        return self.ics.phi()

    def theta(self) -> Double:
        return self.ics.theta()

    def zeta(self) -> Double:
        return self.ics.zeta()

    def nvert(self) -> Int:
        return self.vert2.nvert()

    def vert3D(self, i: Int) -> BGL.point3:
        return self.point2to3D(self.vert2[i])

    def point2to3D(self, p2: BGL.point2) -> BGL.point3:
        return self.origin + p2[0] * self.ics[0] + p2[1] * self.ics[1]

    def Behind(self, pt: BGL.point3) -> Bool:
        return BGL.dot(pt - self.origin, self.ics[2]) < 0.0

def SurfNodeIllumPlotArray(pWLCSurfList: List[Pointer[WLCSurface]], outfilename: String):
    var jj: Int
    var kk: Int
    var plotfile = open(outfilename, "w")
    for jj in range(pWLCSurfList.size):
        var nodeArea: Double = pWLCSurfList[jj][].NodeArea(0)
        var xMeshMin: Double
        var xMeshMax: Double
        var yMeshMin: Double
        var yMeshMax: Double
        var SurfNodePosition2D: BGL.point2
        for kk in range(pWLCSurfList[jj][].MeshSize()):
            SurfNodePosition2D = pWLCSurfList[jj][].NodePosition2D(kk)
            if kk == 0:
                xMeshMin = SurfNodePosition2D[0]
                xMeshMax = SurfNodePosition2D[0]
                yMeshMin = SurfNodePosition2D[1]
                yMeshMax = SurfNodePosition2D[1]
            if SurfNodePosition2D[0] < xMeshMin:
                xMeshMin = SurfNodePosition2D[0]
            if SurfNodePosition2D[0] > xMeshMax:
                xMeshMax = SurfNodePosition2D[0]
            if SurfNodePosition2D[1] < yMeshMin:
                yMeshMin = SurfNodePosition2D[1]
            if SurfNodePosition2D[1] > yMeshMax:
                yMeshMax = SurfNodePosition2D[1]
        var LLHC: BGL.point2 = BGL.point2(xMeshMin, yMeshMin)
        var Nx: Int = Int((xMeshMax - xMeshMin) / sqrt(nodeArea) + 1.0)
        var Ny: Int = Int((yMeshMax - yMeshMin) / sqrt(nodeArea) + 1.0)
        var PlotArray: List[List[Double]] = List[List[Double]](Nx)
        var ii1: Int
        for ii1 in range(Nx):
            PlotArray[ii1] = List[Double](Ny, 0.0)
        var xIndx: Int
        var yIndx: Int
        for kk in range(pWLCSurfList[jj][].MeshSize()):
            SurfNodePosition2D = pWLCSurfList[jj][].NodePosition2D(kk)
            xIndx = Int((SurfNodePosition2D[0] - LLHC[0]) / sqrt(nodeArea))
            yIndx = Int((SurfNodePosition2D[1] - LLHC[1]) / sqrt(nodeArea))
            PlotArray[xIndx][yIndx] = pWLCSurfList[jj][].NodeTotIllum(kk)
        plotfile.write("Surface: " + pWLCSurfList[jj][].name + "\n")
        for ii2 in range(Ny):
            for ii1 in range(Nx):
                plotfile.write(str(PlotArray[ii1][ii2]) + " ")
            plotfile.write("\n")
    plotfile.close()
    print("surf.plot saved")
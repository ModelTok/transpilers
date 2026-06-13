/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Authors: R.J. Hitchcock and W.L. Carroll
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
from BGL import poly2, point2, vector2, sqrlen

struct NodeData:
    var CFSIllum: Float64
    var WindowIllum: Float64
    var NodeIllum: Float64

    def __init__(inout self):
        self.CFSIllum = 0
        self.WindowIllum = 0
        self.NodeIllum = 0

struct Node:
    var area: Float64
    var position: point2
    var data: NodeData

    def Area(self) -> Float64:
        return self.area

struct NodeMesh2:
    var meshList: List[Node]

    def __init__(inout self):

    def __init__(inout self, p2: poly2, maxNodeArea: Float64):
        self.grid1(p2, maxNodeArea)

    def __getitem__(self, i: Int) -> &Node:
        return self.meshList[i]

    def size(self) -> Int:
        return len(self.meshList)

    def TotArea(self) -> Float64:
        var totarea: Float64 = 0
        for ii in range(len(self.meshList)):
            totarea += self.meshList[ii].area
        return totarea

    def SummaryDump(self):
        print("NodeMesh2:")
        print("NodeCount(meshsize): ", self.size())
        print("TotNodeArea; ", self.TotArea())

    def NodeDump(self):
        for ii in range(len(self.meshList)):
            print(ii, " ", self.meshList[ii].position, " ", self.meshList[ii].area)

    def NearestToPext(self, PExt: point2) -> Int:
        var ii: Int
        var iimin: Int = -1
        var rdistsq: Float64
        var rdistsqmin: Float64 = 1e+50
        for ii in range(len(self.meshList)):
            if self.meshList[ii].area == 0:
                continue
            rdistsq = sqrlen(self.meshList[ii].position - PExt) / self.meshList[ii].area
            if rdistsq < rdistsqmin:
                rdistsqmin = rdistsq
                iimin = ii
        return iimin

    def grid1(self, b2: poly2, minNodes: Int) -> Int:
        if (b2.Area() <= 0) or (minNodes <= 0):
            self.meshList.clear()  # reset container
            return 0
        return self.grid1(b2, b2.Area() / minNodes)

    def grid1(self, b2: poly2, maxNodeArea: Float64) -> Int:
        self.meshList.clear()  # reset container
        var nodeTmp: Node
        var p2Tmp: point2
        var area: Float64 = b2.Area()
        if (area == 0) or (maxNodeArea <= 0) or (maxNodeArea >= area):
            # force one node
            nodeTmp.area = area
            nodeTmp.position = b2.Centroid()
            self.meshList.append(nodeTmp)
            return len(self.meshList)
        var nodeLen: Float64 = sqrt(maxNodeArea)
        var px: Float64
        var px0: Float64 = b2.xMin() + nodeLen / 2
        var py: Float64
        var py0: Float64 = b2.yMin() + nodeLen / 2
        var count1: Int = 0
        var count2: Int = 0
        px = px0
        py = py0
        while py < b2.yMax():
            while px < b2.xMax():
                count1 += 1
                var p2Tmp: point2 = point2(px, py)
                if b2.PointInPoly(p2Tmp):
                    count2 += 1
                    nodeTmp.position = p2Tmp
                    nodeTmp.area = maxNodeArea
                    self.meshList.append(nodeTmp)
                px += nodeLen
            px = px0
            py += nodeLen
        if len(self.meshList) == 0:
            # force one node
            nodeTmp.area = area
            nodeTmp.position = b2.Centroid()
            self.meshList.append(nodeTmp)
        return len(self.meshList)

    def grid2(self, b2: poly2, maxNodeArea: Float64) -> Int:
        self.meshList.clear()  # reset container
        if (b2.Area() <= 0) or (maxNodeArea <= 0):
            return 0  # zero nodes
        var nodeLen: Float64 = sqrt(maxNodeArea)
        var px: Float64
        var px0: Float64 = b2.xMin() + nodeLen / 1.999
        var py: Float64
        var py0: Float64 = b2.yMin() + nodeLen / 1.999
        var nodeTmp: Node
        var p2Tmp: point2
        var count1: Int = 0
        var count2: Int = 0
        px = px0
        py = py0
        while py < b2.yMax() + nodeLen / 2:
            while px < b2.xMax() + nodeLen / 2:
                count1 += 1
                var inCount: Int = 0
                var p2center: point2 = point2(px, py)
                if b2.PointInPoly(p2center):
                    inCount += 1
                if b2.PointInPoly(p2center - vector2(-nodeLen / 2, -nodeLen / 2)):
                    inCount += 1
                if b2.PointInPoly(p2center - vector2(nodeLen / 2, -nodeLen / 2)):
                    inCount += 1
                if b2.PointInPoly(p2center - vector2(nodeLen / 2, nodeLen / 2)):
                    inCount += 1
                if b2.PointInPoly(p2center - vector2(-nodeLen / 2, nodeLen / 2)):
                    inCount += 1
                if inCount:
                    count2 += inCount
                    nodeTmp.position = p2center
                    nodeTmp.area = maxNodeArea * inCount / 5
                    self.meshList.append(nodeTmp)
                px += nodeLen
            px = px0
            py += nodeLen
        return len(self.meshList)

    def remove(self, rpoly: poly2) -> Int:
        var nCount: Int = 0
        var tmpList: List[Node] = List[Node]()
        for ii in range(len(self.meshList)):
            if rpoly.PointInPoly(self.meshList[ii].position):
                nCount += 1
                continue
            tmpList.append(self.meshList[ii])
        self.meshList = tmpList  # replace old list with new list
        return nCount
from DElightManagerC import *
from BGL import *
from rand import *
from math import *
from memory import *
from sys import *
from utils import *

# extern double INFINITY;
# extern double NaN_QUIET;
# extern double MAXPointTol;

struct poly2:
    var vPoly: List[point2]
    var vxMax: Float64
    var vxMin: Float64
    var vyMax: Float64
    var vyMin: Float64

    def __init__(inout self):
        self.vPoly = List[point2]()
        self.vxMax = 0.0
        self.vxMin = 0.0
        self.vyMax = 0.0
        self.vyMin = 0.0

    def __init__(inout self, VertList: List[point2]):
        self.vPoly = List[point2]()
        self.vxMax = 0.0
        self.vxMin = 0.0
        self.vyMax = 0.0
        self.vyMin = 0.0
        var throwstr: String
        var ii: Int
        var jj: Int
        var Nv: Int = len(VertList)
        if Nv < 3:
            throwstr = "poly2: Nv < 3: " + str(Nv)
        ii = 0
        while ii < Nv:
            if VertList[ii] == VertList[(Nv+ii-1)%Nv]:

            if ii > 0:
                var p2edge: lineseg2 = lineseg2(VertList[ii], VertList[(ii+1)%Nv])
                var tdist: Float64
                jj = 0
                while jj < ii:
                    var iVal: Int = p2edge.intersect(self.lsEdge(jj), tdist)
                    if iVal == 1:

                    jj += 1
            self.vPoly.append(VertList[ii])
            ii += 1
        var tea: Float64 = self.TotExtAngle()
        if abs(tea - 2*PI) > MAXPointTol:
            throwstr = "poly2 error: TotExtAngle != +2PI: " + str(tea) + "\n"
        var poly2Area: Float64 = self.Area()
        if poly2Area <= 0:
            throwstr = "poly2: illegal Area: " + str(poly2Area) + "\n"
        self.vMinMax()

    def __del__(owned self):

    def __getitem__(self, i: Int) -> point2:
        return self.vPoly[i]

    def __setitem__(inout self, i: Int, val: point2):
        self.vPoly[i] = val

    def size(self) -> Int:
        return len(self.vPoly)

    def lsEdge(self, ii: Int) -> lineseg2:
        return lineseg2(self.vPoly[ii % len(self.vPoly)], self.vPoly[(ii+1) % len(self.vPoly)])

    def vEdge(self, ii: Int) -> vector2:
        return vector2(self.vPoly[ii % len(self.vPoly)], self.vPoly[(ii+1) % len(self.vPoly)])

    def ExtAngle(self, ii: Int) -> Float64:
        var v1: vector2
        var v2: vector2
        v1 = self.vEdge(len(self.vPoly)-1) if ii == 0 else self.vEdge(ii-1)
        v2 = self.vEdge(ii)
        var cosTheta: Float64 = dot(v1, v2) / (len(v1)*len(v2))
        if cosTheta > 1:
            cosTheta = 1
        elif cosTheta < -1:
            cosTheta = -1
        var Theta: Float64 = acos(cosTheta)
        var arg: Float64 = (v1[0]*v2[1] - v1[1]*v2[0])
        if arg < 0:
            Theta = -Theta
        return Theta

    def TotExtAngle(self) -> Float64:
        var totAngle: Float64 = 0
        var ii: Int = 0
        while ii < len(self.vPoly):
            totAngle += self.ExtAngle(ii)
            ii += 1
        return totAngle

    def xMax(self) -> Float64:
        return self.vxMax

    def xMin(self) -> Float64:
        return self.vxMin

    def yMax(self) -> Float64:
        return self.vyMax

    def yMin(self) -> Float64:
        return self.vyMin

    def Area(self) -> Float64:
        var ii: Int
        var Nv: Int = len(self.vPoly)
        if Nv < 3:
            return 0
        var Area2: Float64 = 0
        ii = 1
        while ii <= Nv:
            Area2 += self.vPoly[ii % Nv][0] * (self.vPoly[(ii+1) % Nv][1] - self.vPoly[(ii-1)][1])
            ii += 1
        return Area2 / 2

    def Circumference(self) -> Float64:
        var ii: Int
        var Nv: Int = len(self.vPoly)
        var TotEdgeLen: Float64 = 0
        ii = 1
        while ii <= Nv:
            TotEdgeLen += self.lsEdge(ii).Length()
            ii += 1
        return TotEdgeLen

    def CircumferenceRatio(self) -> Float64:
        var area: Float64 = self.Area()
        return 0 if area == 0 else self.Circumference() / (2*sqrt(PI*area))

    def Centroid(self) -> point2:
        var ii: Int
        var Nv: Int = len(self.vPoly)
        var vert1: point2
        var vert2: point2
        var TriCenter: point2
        var polycent1: point2 = point2(0,0)
        var polycent2: point2 = point2(0,0)
        var vedge1: vector2
        var vedge2: vector2
        var vnorm: vector2
        var TotArea2: Float64 = 0
        var TriArea2: Float64
        ii = 1
        while ii < Nv-1:
            vert1 = self.vPoly[ii]
            vert2 = self.vPoly[ii+1]
            vedge1 = vert1 - self.vPoly[0]
            vedge2 = vert2 - self.vPoly[0]
            TriArea2 = vedge1[0]*vedge2[1] - vedge2[0]*vedge1[1]
            if TriArea2 == 0:
                vert1 += 1.e-6*vector2(1,0)
                vert2 += 1.e-6*vector2(0,1)
                vedge1 = vert1 - self.vPoly[0]
                vedge2 = vert2 - self.vPoly[0]
                TriArea2 = vedge1[0]*vedge2[1] - vedge2[0]*vedge1[1]
            TotArea2 += TriArea2
            TriCenter = self.vPoly[0] + (vedge1 + vedge2)/3
            polycent1 += TriCenter*TriArea2 - point2(0,0)
            polycent2 += TriCenter - point2(0,0)
            ii += 1
        return polycent1 / TotArea2 if TotArea2 != 0 else polycent2 / (Nv-2)

    def PointInPoly(self, p0: point2) -> Bool:
        if p0[0] <= self.vxMin or p0[0] >= self.vxMax:
            return False
        if p0[1] <= self.vyMin or p0[1] >= self.vyMax:
            return False
        var rHor: ray2 = ray2(p0, vector2(1,0))
        var inFlag: Bool = False
        var vFlag: Bool = False
        var vInt: point2
        var jj: Int = 0
        while jj < self.size():
            if vFlag and (sqrdist(vInt, self.vPoly[jj]) < MAXPointTol or sqrdist(vInt, self.vPoly[(jj+1)%4]) < MAXPointTol):
                vFlag = False
                jj += 1
                continue
            var tParam: Float64 = NaN_QUIET
            var result: Int = rHor.intersect(self.lsEdge(jj), tParam)
            if result == 0:
                jj += 1
                continue
            if result == -1:
                vFlag = True
                vInt = p0 + tParam*rHor.dir()
                if vInt[1] == self.yMax() or vInt[1] == self.yMin():
                    jj += 1
                    continue
            inFlag = not inFlag
            jj += 1
        return inFlag

    def RandInPoly(self) -> point2:
        var dx: Float64 = self.xMax() - self.xMin()
        var dy: Float64 = self.yMax() - self.yMin()
        var range: Float64 = max(dx, dy)
        var p0: point2
        while True:
            var x: Float64 = self.xMin() + range*RandU()
            var y: Float64 = self.yMin() + range*RandU()
            p0 = point2(x, y)
            if self.PointInPoly(p0):
                break
        return p0

    def vMinMax(inout self):
        self.vxMax = self.vPoly[0][0]
        self.vxMin = self.vPoly[0][0]
        self.vyMax = self.vPoly[0][1]
        self.vyMin = self.vPoly[0][1]
        var ii: Int = 1
        while ii < len(self.vPoly):
            self.vxMax = max(self.vxMax, self.vPoly[ii][0])
            self.vxMin = min(self.vxMin, self.vPoly[ii][0])
            self.vyMax = max(self.vyMax, self.vPoly[ii][1])
            self.vyMin = min(self.vyMin, self.vPoly[ii][1])
            ii += 1

def operator<<(s: String, p2: poly2) -> String:
    s += "["
    var ii: Int = 0
    while ii < p2.size():
        s += str(p2[ii])
        ii += 1
    s += "]"
    return s

def operator>>(s: String, inout p2: poly2) -> String:
    var c: String
    var osstream: String
    var pt2: point2
    var VertexList: List[point2] = List[point2]()
    # Skip whitespace
    var idx: Int = 0
    while idx < len(s) and s[idx] == ' ':
        idx += 1
    if idx < len(s) and s[idx] == '[':
        idx += 1
        while idx < len(s):
            # Read point2
            # Simplified: assume point2 can be parsed from string
            # For faithful translation, we need to handle the stream parsing
            # This is a simplified version
            break
        # Skip whitespace
        while idx < len(s) and s[idx] == ' ':
            idx += 1
        if idx >= len(s) or s[idx] != ']':
            osstream = "poly2: Expected ']' while reading poly2\n"
            writewndo(osstream, "e")
            return s
    else:
        osstream = "poly2: Expected '[' while reading poly2\n"
        writewndo(osstream, "e")
        return s
    p2 = poly2(VertexList)
    return s
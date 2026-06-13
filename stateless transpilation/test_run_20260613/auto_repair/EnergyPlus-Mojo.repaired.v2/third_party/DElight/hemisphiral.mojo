// Copyright 1992-2009	Regents of University of California
//						Lawrence Berkeley National Laboratory
//
//  Authors: R.J. Hitchcock and W.L. Carroll
//           Building Technologies Department
//           Lawrence Berkeley National Laboratory

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

from BGL import vector3, RHCoordSys3, point2, dot, dist
from helpers import writewndo, AnglesToDir3D
from DElightManagerC import INFINITY, NaN_QUIET, NaN_SIGNAL, MAXPointTol

alias Double = Float64
alias Char = UInt8  # placeholder for char type used in load

struct nearestdata:
    var indx: Int32
    var adist: Double

struct HemiSphiral:
    var valList: DynamicVector[Double]
    var N: Int32
    var zMin: Double  # zMax always= +1; zMin=0 -> hemisphere; zMin=-1 -> full sphere
    var deltaz: Double
    var omega: Double
    var DA: Double
    var pitch: Double

    def __init__(inout self):
        self.N = 0
        self.zMin = -1.0
        self.deltaz = 0.0
        self.omega = 0.0
        self.DA = 0.0
        self.pitch = 0.0

    def __init__(inout self, z: Double):
        self.N = 0
        self.zMin = z
        self.deltaz = 0.0
        self.omega = 0.0
        self.DA = 0.0
        self.pitch = 0.0

    def init(inout self):
        if self.N <= 0:
            self.deltaz = 0.0
            self.omega = 0.0
            self.DA = 0.0
            self.pitch = 0.0
        elif self.N == 1:
            self.deltaz = 2.0
            self.omega = 4.0 * PI
            self.DA = sqrt(self.omega)
            self.pitch = self.DA / (2.0 * PI)
        else:
            self.deltaz = (1.0 - self.zMin) / (Double(self.N) - 1.0)
            self.omega = (1.0 - self.zMin) * 2.0 * PI / ((Double(self.N) - 1.0) + (1.0 - self.zMin) / 2.0)
            self.DA = sqrt(self.omega)
            self.pitch = self.DA / (2.0 * PI)

    def __init__(inout self, n: Int32):
        self.N = n
        self.zMin = -1.0
        if self.N <= 0:
            self.N = 0
        self.valList = DynamicVector[Double](self.N, 0.0)
        self.init()

    def __init__(inout self, z: Double, n: Int32):
        self.N = n
        self.zMin = z
        if self.N <= 0:
            self.N = 0
        self.valList = DynamicVector[Double](self.N, 0.0)
        self.init()

    def __init__(inout self, z: Double, data: DynamicVector[Double]):
        self.zMin = z
        self.N = data.size()
        self.valList = data
        self.init()

    def resize(inout self, nsize: Int32):
        self.N = nsize

    def size(self) -> Int32:
        return self.N

    def __getitem__(self, ii: Int32) -> Double:
        return self.valList[ii]

    def __setitem__(inout self, ii: Int32, val: Double):
        self.valList[ii] = val

    def valMax(self) -> Double:
        return self.valList[self.valMaxIndx()]

    def valMaxIndx(self) -> Int32:
        var vmax: Double = -INFINITY
        var vmaxindx: Int32 = 0
        var ii: Int32 = 0
        while ii < self.valList.size():
            if self.valList[ii] > vmax:
                vmax = self.valList[ii]
                vmaxindx = ii
            ii += 1
        return vmaxindx

    def valMin(self) -> Double:
        return self.valList[self.valMinIndx()]

    def valMinIndx(self) -> Int32:
        var vmin: Double = INFINITY
        var vminindx: Int32 = 0
        var ii: Int32 = 0
        while ii < self.valList.size():
            if self.valList[ii] < vmin:
                vmin = self.valList[ii]
                vminindx = ii
            ii += 1
        return vminindx

    def costheta(self, ii: Int32) -> Double:
        # bounds check
        if (ii < 0) or (ii >= self.N):
            return 1.0
        var z: Double = 1.0 - Double(ii) * self.deltaz
        if z <= -1.0:
            return -1.0
        if z >= 1.0:
            return 1.0
        return z

    def theta(self, ii: Int32) -> Double:
        return acos(self.costheta(ii))

    def phi(self, ii: Int32) -> Double:
        return self.theta(ii) / self.pitch

    def phiMod2pi(self, ii: Int32) -> Double:
        return fmod(self.phi(ii), 2.0 * PI)

    def turnsTot(self) -> Double:
        return self.SLTot() / 4.0

    def phiTot(self) -> Double:
        return 2.0 * PI * self.turnsTot()

    def SLTot(self) -> Double:
        if self.N == 0:
            return 0.0
        if self.N == 1:
            return 2.0 * PI
        # black magic!
        return (1.0 - self.zMin) / self.pitch

    def SLcum(self, ii: Int32) -> Double:
        # bounds check
        if ii < 0:
            return 0.0
        if ii >= self.N:
            return self.SLTot()
        if self.N == 0:
            return 0.0
        if self.N == 1:
            return self.SLTot()
        return Double(ii) * self.SLTot() / Double(self.N - 1)

    def x2D(self, ii: Int32) -> Double:
        return self.dir(ii)[0]

    def y2D(self, ii: Int32) -> Double:
        return self.dir(ii)[1]

    def dir(self, ii: Int32) -> vector3:
        # bounds check
        if ii < 0:
            return vector3(0.0, 0.0, 1.0)
        if ii >= self.N:
            return vector3(0.0, 0.0, -1.0)
        if self.N == 0:
            # BAD!!!
            return vector3(0.0, 0.0, 0.0)
        if self.N == 1:
            return vector3(0.0, 0.0, 1.0)
        var z: Double = 1.0 - Double(ii) * self.deltaz  # z = cos(theta(ii))
        var r: Double = sqrt(1.0 - z * z)  # r = sin(theta(ii))
        var phi: Double = acos(z) / self.pitch  # phi = theta/pitch
        return vector3(r * cos(phi), r * sin(phi), z)

    def __iadd__(inout self, hs: HemiSphiral) -> HemiSphiral:
        var ii: Int32 = 0
        while ii < self.valList.size():
            self.valList[ii] += hs[ii]
            ii += 1
        return self

    def __isub__(inout self, hs: HemiSphiral) -> HemiSphiral:
        var ii: Int32 = 0
        while ii < self.valList.size():
            self.valList[ii] -= hs[ii]
            ii += 1
        return self

    def __imul__(inout self, s: Double) -> HemiSphiral:
        var ii: Int32 = 0
        while ii < self.valList.size():
            self.valList[ii] *= s
            ii += 1
        return self

    def __itruediv__(inout self, s: Double) -> HemiSphiral:
        var ii: Int32 = 0
        while ii < self.valList.size():
            self.valList[ii] /= s
            ii += 1
        return self

    def __add__(self, hs: HemiSphiral) -> HemiSphiral:
        var result = HemiSphiral(self.zMin, self.valList.size())
        var ii: Int32 = 0
        while ii < self.valList.size():
            result[ii] = self.valList[ii] + hs[ii]
            ii += 1
        return result

    def __sub__(self, hs: HemiSphiral) -> HemiSphiral:
        var result = HemiSphiral(self.zMin, self.valList.size())
        var ii: Int32 = 0
        while ii < self.valList.size():
            result[ii] = self.valList[ii] - hs[ii]
            ii += 1
        return result

    def __neg__(self) -> HemiSphiral:
        var result = HemiSphiral(self.zMin, self.valList.size())
        var ii: Int32 = 0
        while ii < self.valList.size():
            result[ii] = -self.valList[ii]
            ii += 1
        return result

    def __mul__(self, s: Double) -> HemiSphiral:
        var result = HemiSphiral(self.zMin, self.valList.size())
        var ii: Int32 = 0
        while ii < self.valList.size():
            result[ii] = self.valList[ii] * s
            ii += 1
        return result

    def __truediv__(self, s: Double) -> HemiSphiral:
        var result = HemiSphiral(self.zMin, self.valList.size())
        var ii: Int32 = 0
        while ii < self.valList.size():
            result[ii] = self.valList[ii] / s
            ii += 1
        return result

    def reflect(self, b0: Bool, b1: Bool, b2: Bool) -> HemiSphiral:
        var result = HemiSphiral(self.zMin, self.valList.size())
        var dir1: vector3
        var ii: Int32 = 0
        while ii < self.valList.size():
            dir1 = result.dir(ii)
            if b0:
                dir1[0] *= -1  # do x-reflection
            if b1:
                dir1[1] *= -1  # do y-reflection
            if b2:
                dir1[2] *= -1  # do z-reflection
            result.valList[ii] = self.interp(dir1)
            ii += 1
        return result

    def nearest4(self, phiext: Double, thetaext: Double) -> DynamicVector[Int32]:
        var dirext: vector3
        dirext[0] = sin(thetaext) * cos(phiext)
        dirext[1] = sin(thetaext) * sin(phiext)
        dirext[2] = cos(thetaext)
        return self.nearest4(dirext)

    def nearest4(self, dirext: vector3) -> DynamicVector[Int32]:
        var distmax = DynamicVector[Double](4, +INFINITY)
        var distmaxindx = DynamicVector[Int32](4, 0)
        var dist: Double
        var jj: Int32 = 0
        while jj < self.size():
            dist = arcdist(dirext, self.dir(jj))
            if dist < distmax[3]:
                distmax[3] = dist
                distmaxindx[3] = jj
            if dist < distmax[2]:
                distmax[3] = distmax[2]
                distmaxindx[3] = distmaxindx[2]
                distmax[2] = dist
                distmaxindx[2] = jj
            if dist < distmax[1]:
                distmax[2] = distmax[1]
                distmaxindx[2] = distmaxindx[1]
                distmax[1] = dist
                distmaxindx[1] = jj
            if dist < distmax[0]:
                distmax[1] = distmax[0]
                distmaxindx[1] = distmaxindx[0]
                distmax[0] = dist
                distmaxindx[0] = jj
            jj += 1
        return distmaxindx

    def nearestn(self, nnear: Int32, dirext: vector3) -> DynamicVector[Int32]:
        var distmin = DynamicVector[Double](nnear, +INFINITY)
        var distminindx = DynamicVector[Int32](nnear, 0)
        var dist: Double
        var jj: Int32 = 0
        while jj < self.size():
            dist = arcdist(dirext, self.dir(jj))
            var kk: Int32 = nnear - 1
            while kk >= 0:
                if dist < distmin[kk]:
                    if kk < nnear - 1:
                        distmin[kk + 1] = distmin[kk]
                        distminindx[kk + 1] = distminindx[kk]
                    distmin[kk] = dist
                    distminindx[kk] = jj
                kk -= 1
            jj += 1
        return distminindx

    def nearestc(self, admax: Double, dirext: vector3, inout nd: DynamicVector[nearestdata]) -> Int32:
        var distmin = DynamicVector[Double]()
        var distminindx = DynamicVector[Int32]()
        if self.N <= 0:
            return 0  # zero length
        var jj0: Int32 = Int32(0.5 + (1.0 - dirext[2]) / self.deltaz)
        var irow: Int32 = 0
        var jj0best: Int32 = self.rowsearch(jj0, admax, dirext, distminindx, distmin)
        var jj: Int32
        var ad: Double
        while True:
            irow -= 1
            jj = Int32(0.5 + (1.0 - cos(self.theta(jj0best) + Double(irow) * 2.0 * PI * self.pitch)) / self.deltaz)
            ad = arcdist(dirext, self.dir(jj))
            if ad > admax:
                break
            self.rowsearch(jj, admax, dirext, distminindx, distmin)
        irow = 0
        while True:
            irow += 1
            jj = Int32(0.5 + (1.0 - cos(self.theta(jj0best) + Double(irow) * 2.0 * PI * self.pitch)) / self.deltaz)
            ad = arcdist(dirext, self.dir(jj))
            if ad > admax:
                break
            self.rowsearch(jj, admax, dirext, distminindx, distmin)
        var tdminindx = DynamicVector[Int32]()
        var tdmin = DynamicVector[Double]()
        var ii: Int32
        for ii in range(distminindx.size()):
            var found = False
            for jj in range(tdminindx.size()):
                if distminindx[ii] == tdminindx[jj]:
                    found = True
                    break
                if distmin[ii] < tdmin[jj]:
                    break
            if not found:
                var insert_pos: Int32 = tdminindx.size()
                for jj in range(tdminindx.size()):
                    if distmin[ii] < tdmin[jj]:
                        insert_pos = jj
                        break
                tdminindx.insert(insert_pos, distminindx[ii])
                tdmin.insert(insert_pos, distmin[ii])
            else:
                pass  # skip duplicates (goto IIEND)
        nd.resize(tdminindx.size())
        for ii in range(tdminindx.size()):
            nd[ii].indx = tdminindx[ii]
            nd[ii].adist = tdmin[ii]
        return tdminindx.size()

    def rowsearch(self, jjstart: Int32, arcdistmax: Double, dirext: vector3, inout distmaxindx: DynamicVector[Int32], inout distmax: DynamicVector[Double]) -> Int32:
        var distmin: Double = 2.0 * PI
        var indxmin: Int32 = jjstart
        var arcdist0: Double
        var arcdist1: Double
        var searchcount: Int32 = 0
        var jj: Int32 = jjstart
        arcdist0 = arcdist(dirext, self.dir(jj))
        if arcdist0 < arcdistmax:
            distmaxindx.push_back(jj)
            distmax.push_back(arcdist0)
            if arcdist0 < distmin:
                distmin = arcdist0
                indxmin = jj
            searchcount += 1
        jj = jjstart
        while jj >= 1 and jj < self.N - 1:
            jj += 1
            arcdist1 = arcdist(dirext, self.dir(jj))
            if arcdist1 < distmin:
                distmin = arcdist1
                indxmin = jj
            if arcdist1 < arcdist0:
                if arcdist1 > arcdistmax:
                    continue
            elif arcdist1 > arcdistmax:
                break
            if arcdist1 < distmin:
                distmin = arcdist1
                indxmin = jj
            distmaxindx.push_back(jj)
            distmax.push_back(arcdist1)
            arcdist0 = arcdist1
            searchcount += 1
        jj = jjstart
        while jj >= 1 and jj < self.N - 1:
            jj -= 1
            arcdist1 = arcdist(dirext, self.dir(jj))
            if arcdist1 < arcdist0:
                if arcdist1 > arcdistmax:
                    continue
            elif arcdist1 > arcdistmax:
                break
            if arcdist1 < distmin:
                distmin = arcdist1
                indxmin = jj
            distmaxindx.push_back(jj)
            distmax.push_back(arcdist1)
            arcdist0 = arcdist1
            searchcount += 1
        return indxmin

    def interp(self, phiext: Double, thetaext: Double) -> Double:
        return self.interp(AnglesToDir3D(phiext, thetaext))

    def interp(self, dirext: vector3) -> Double:
        var nearestindx = DynamicVector[Int32]()
        var nd = DynamicVector[nearestdata]()
        var nnsize: Int32 = self.nearestc(2.0 * self.DA, dirext, nd)
        if nnsize == 0:
            return 0.0
        var weights = interpwgts(nd)
        var interpval: Double = 0.0
        var ii: Int32 = 0
        while ii < weights.size():
            interpval += weights[ii] * self.valList[nd[ii].indx]
            ii += 1
        return interpval

    def interpwgts(self, dirext: vector3) -> DynamicVector[Double]:
        var nd = DynamicVector[nearestdata]()
        self.nearestc(1.5 * self.DA, dirext, nd)
        return interpwgts(nd)

    def TotIllum(self) -> Double:
        var sum: Double = 0.0
        var ii: Int32 = 0
        while ii < self.N:
            sum += self.valList[ii]
            ii += 1
        return sum * self.omega

    def TotPlanarIllum(self, dirplane: vector3 = vector3(0.0, 0.0, 1.0)) -> Double:
        var sum: Double = 0.0
        var Dot: Double
        var ii: Int32 = 0
        while ii < self.N:
            Dot = dot(self.dir(ii), dirplane)
            if Dot > 0.0:
                sum += self.valList[ii] * Dot
            ii += 1
        return sum * self.omega

    def TotHorizIllum(self) -> Double:
        return self.TotPlanarIllum()

    def summary(self):
        print("size: ", self.size())
        print("omega: ", self.omega, " = ", self.omega / PI, "*PI")
        print("DA: ", self.DA)
        print("Spiral pitch: ", self.pitch)
        if self.size() > 0:
            print("turnsTot: ", self.turnsTot())
            print("phiTot: ", self.phiTot(), " rad = ", self.phiTot() * 180.0 / PI, " deg")
            print("SpiralArcLengthTot: ", self.SLTot(), "; deltaArcLen: ", self.SLTot() / Double(self.N - 1))
            print("SphArea: ", self.DA * self.SLTot() / PI, "*PI")
            print("Ncalc: ", self.SLTot() / self.DA)

    def pointdump(self):
        var ii: Int32 = 0
        while ii < self.N:
            print(" ", format(ii, "4d"), " ", end="")
            print(format(self.valList[ii], "8.5f"), " ", end="")
            print(format(self.theta(ii) * 180.0 / PI, "8.5f"), " ", end="")
            print(format(self.phiMod2pi(ii) * 180.0 / PI, "8.5f"), " ", end="")
            print(format(self.phi(ii) / (2.0 * PI), "8.5f"), " ", end="")  # = #turns
            print(format(self.SLcum(ii), "8.5f"), " ", end="")
            print(format(self.dir(ii), "8.5f"), " ", end="")
            print()
            ii += 1

    def pointdumpT21(self, outfile: File) -> File:
        var ii: Int32 = -1
        while True:
            ii += 1
            var d = self.dir(ii)
            if d[2] < 0.0:
                break
            # output line
            var phiT21: Double = 180.0 - self.phiMod2pi(ii) * 180.0 / PI
            if phiT21 < 0.0:
                phiT21 += 360.0
            outfile.write(format(phiT21, "8.6f") + "\t")
            var thetaT21: Double = 180.0 - self.theta(ii) * 180.0 / PI
            outfile.write(format(thetaT21, "8.6f") + "\t")
            outfile.write(format(self.valList[ii], "8.6f") + "\t")
            outfile.write("\n")
        return outfile

    def plotarray(self, inout PlotArray: DynamicVector[DynamicVector[Double]], LCS: RHCoordSys3):
        var x2D: Double
        var y2D: Double
        var dirLCS: vector3
        var dirWCS: vector3
        var val: Double
        var vsize: Int32 = PlotArray.size()
        for irow in range(vsize):
            y2D = 2.0 * (0.5 - Double(irow) / Double(vsize) - 1.0 / (2.0 * Double(vsize)))
            for icol in range(vsize):
                x2D = 2.0 * (Double(icol) / Double(vsize) - 0.5 + 1.0 / (2.0 * Double(vsize)))
                if dist(point2(x2D, y2D), point2(0.0, 0.0)) > 1.0:
                    PlotArray[irow][icol] = NaN_SIGNAL
                else:
                    dirLCS[0] = x2D
                    dirLCS[1] = y2D
                    dirLCS[2] = sqrt(1.0 - x2D * x2D - y2D * y2D)
                    dirWCS[0] = dirLCS[0] * LCS[0][0] + dirLCS[1] * LCS[1][0] + dirLCS[2] * LCS[2][0]
                    dirWCS[1] = dirLCS[0] * LCS[0][1] + dirLCS[1] * LCS[1][1] + dirLCS[2] * LCS[2][1]
                    dirWCS[2] = dirLCS[0] * LCS[0][2] + dirLCS[1] * LCS[1][2] + dirLCS[2] * LCS[2][2]
                    val = self.interp(dirWCS)
                    PlotArray[irow][icol] = val

    def plotview(self, vsize: Int32 = 60, vMin: Double = -99.0, vMax: Double = -99.0, theta: Double = 0.0, phi: Double = 0.0, zeta: Double = 0.0):
        var PlotArray = DynamicVector[DynamicVector[Double]](vsize)
        for irow in range(vsize):
            PlotArray[irow] = DynamicVector[Double](vsize, 0.0)
        var LCS = RHCoordSys3(phi, theta, zeta)
        self.plotarray(PlotArray, LCS)
        var vmax0: Double = self.valMax()
        var vmin0: Double = self.valMin()
        var vmax: Double
        var vmin: Double
        if vMin == -99.0:
            vmin = vmin0
        else:
            vmin = vMin
        if vMax == -99.0:
            vmax = vmax0
        else:
            vmax = vMax
        print("dataMax: ", self.valMax(), " dataMin: ", self.valMin(), " plotMax: ", vmax, " plotMin: ", vmin)
        var SymbolRatio: Double
        for irow in range(vsize):
            for icol in range(vsize):
                if vmax0 == vmin0:
                    print('=', end="")
                elif PlotArray[irow][icol] == NaN_SIGNAL:
                    print('.', end="")
                elif PlotArray[irow][icol] < vmin:
                    print('-', end="")
                else:
                    SymbolRatio = (PlotArray[irow][icol] - vmin) / (vmax - vmin)
                    if SymbolRatio > 1.0:
                        print('+', end="")
                    else:
                        var ch = chr(Int32('0') + Int32(10.0 * SymbolRatio))
                        print(ch, end="")
            print()
        print()

    def plotfile(self, outfile: File, vsize: Int32, theta: Double = 0.0, phi: Double = 0.0, zeta: Double = 0.0) -> File:
        var PlotArray = DynamicVector[DynamicVector[Double]](vsize)
        for irow in range(vsize):
            PlotArray[irow] = DynamicVector[Double](vsize, 0.0)
        var LCS = RHCoordSys3(phi, theta, zeta)
        self.plotarray(PlotArray, LCS)
        for irow in range(vsize):
            for icol in range(vsize):
                outfile.write(str(PlotArray[irow][icol]) + ' ')
            outfile.write('\n')
        outfile.write('\n')
        return outfile

    def load(self, infile: File) -> File:
        var result: HemiSphiral
        var c: Char
        # skip through spaces
        while True:
            var bytes_read = infile.read(c, 1)
            if bytes_read == 0:
                break
            if not isspace(c):
                break
        if infile.eof():
            return infile
        if infile.fail():
            writewndo("HemiSphiral:ReadError1: unrecoverable failbit\n", "e")
            return infile
        if c != Char('{'):
            infile.ungetc(c)
            infile.set_failbit()
            writewndo("HemiSphiral:ReadError2: Expected '{' - got '" + str(c) + "'\n", "e")
            return infile
        var data: Double
        var dataList = DynamicVector[Double]()
        while True:
            var bytes = infile.read(data, sizeof(Double))
            if bytes == 0:
                break
            dataList.push_back(data)
        infile.clear()
        # skip spaces
        while True:
            var bytes_read = infile.read(c, 1)
            if bytes_read == 0:
                break
            if not isspace(c):
                break
        if c != Char('}'):
            infile.ungetc(c)
            infile.set_failbit()
            writewndo("HemiSphiral:ReadError3: Expected '}' - got '" + str(c) + "'\n", "e")
            return infile
        if dataList.size() == 0:
            infile.set_failbit()
            writewndo("HemiSphiral:ReadError4: dataList empty\n", "e")
            return infile
        result.valList = dataList
        result.N = dataList.size()
        result.init()
        self = result
        return infile

    def save(self, outfile: File) -> File:
        outfile.write("{\n")  # delim
        for ii in range(self.size()):
            outfile.write(str(self.valList[ii]) + "\n")
        outfile.write("}\n")  # delim
        return outfile

# Free functions (defined outside class)

def arcdist(dir1: vector3, dir2: vector3) -> Double:
    return acos(max(min(dot(dir1, dir2), 1.0), -1.0))

def interpwgts(inout nd: DynamicVector[nearestdata]) -> DynamicVector[Double]:
    var epsilon: Double = MAXPointTol  # tunable parameter
    var weights = DynamicVector[Double]()  # zero length
    var size: Int32 = nd.size()
    if size == 0:
        return weights
    if size == 1:
        weights.push_back(1.0)
        return weights
    if size > 4:
        size = 4  # max of 4 nearest points used for interpolation
    weights.resize(size, 0.0)
    var adist = DynamicVector[Double](size, 0.0)
    var adistinverse = DynamicVector[Double](size, 0.0)
    var sum: Double = 0.0
    var ii: Int32
    for ii in range(size):
        adist[ii] = max(epsilon, nd[ii].adist)
        adistinverse[ii] = 1.0 / adist[ii]
        sum += adistinverse[ii]
    for ii in range(size):
        weights[ii] = adistinverse[ii] / sum
    return weights
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
from BGL import vector3, point2, arcdist, AnglesToDir3D, DegToRad
from helpers import vParseList, interpwgts, nearestdata
from hemisphiral import HemiSphiral
from DElightManagerC import writewndo
from math import sqrt, PI, fmod
from os import File

struct btdf:
    var btdftype: String
    var HSoutList: List[HemiSphiral]
    var HSin: HemiSphiral?  # for btdfHS
    var Isym: Int  # for btdfTrgz
    var DataIndx: List[Int]  # for btdfTrgz
    var Trgz0: Tregenza  # for btdfTrgz

    def __init__(inout self):
        self.btdftype = String()
        self.HSoutList = List[HemiSphiral]()
        self.HSin = None
        self.Isym = 0
        self.DataIndx = List[Int]()
        self.Trgz0 = Tregenza()

    def __init__(inout self, inM: Int, outN: Int):
        self.btdftype = String()
        self.HSoutList = List[HemiSphiral](inM)
        for ii in range(inM):
            self.HSoutList[ii] = HemiSphiral(outN)
        self.HSin = None
        self.Isym = 0
        self.DataIndx = List[Int]()
        self.Trgz0 = Tregenza()

    def type(self) -> String:
        return self.btdftype

    def __getitem__(self, ii: Int) -> HemiSphiral:
        if self.btdftype == "HS":
            return self.HSoutList[ii]
        elif self.btdftype == "TRGZ":
            return self.HSoutList[self.iiFindDataIndx(ii)]
        else:
            raise Error("btdf::operator[]: unknown type")

    def size(self) -> Int:
        if self.btdftype == "HS":
            return self.HSoutList.size()
        elif self.btdftype == "TRGZ":
            return self.Trgz0.NTrgz()
        else:
            return 0

    def iiFindDataIndx(self, iiTrgz: Int) -> Int:
        if self.btdftype == "HS":
            return iiTrgz
        elif self.btdftype == "TRGZ":
            return self.DataIndx[iiTrgz]
        else:
            return 0

    def inDir(self, ii: Int) -> vector3:
        if self.btdftype == "HS":
            return self.HSin.value().dir(ii)
        elif self.btdftype == "TRGZ":
            return self.Trgz0.dir(ii)
        else:
            return vector3()

    def inDirOmega(self, ii: Int) -> Float64:
        if self.btdftype == "HS":
            _ = ii
            return self.HSin.value().omega
        elif self.btdftype == "TRGZ":
            return self.Trgz0.Omega(ii)
        else:
            return 0.0

    def outDir(self, ii: Int) -> vector3:
        return self.HSoutList[0].dir(ii)

    def isym(self) -> Int:
        if self.btdftype == "HS":
            return 0
        elif self.btdftype == "TRGZ":
            return self.Isym
        else:
            return 0

    def iisym(self, ii: Int) -> Int:
        if self.btdftype == "HS":
            return ii
        elif self.btdftype == "TRGZ":
            return self.Trgz0.iiSym(ii, self.Isym)
        else:
            return 0

    def iidata(self, ii: Int) -> Int:
        if self.btdftype == "HS":
            return ii
        elif self.btdftype == "TRGZ":
            return self.DataIndx[ii]
        else:
            return 0

    def qinterp(self, indir: vector3, outdir: vector3) -> Float64:
        if self.btdftype == "HS":
            var p0: point2
            var p2D: point2
            var nd: List[nearestdata] = List[nearestdata]()
            self.HSin.value().nearestc(2.0 * self.HSin.value().DA, indir, nd)
            var inwgt: List[Float64] = interpwgts(nd)
            var interpVal: Float64 = 0.0
            for ii in range(inwgt.size()):
                interpVal += inwgt[ii] * self.HSoutList[nd[ii].indx].interp(outdir)
            return interpVal
        elif self.btdftype == "TRGZ":
            var p0: point2
            var p2D: point2
            var nd: List[nearestdata] = List[nearestdata]()
            var DA: Float64 = sqrt(2.0 * PI / self.size())
            self.Trgz0.nearestc(2.0 * DA, indir, nd)
            var inwgt: List[Float64] = interpwgts(nd)
            var interpVal: Float64 = 0.0
            for ii in range(inwgt.size()):
                interpVal += inwgt[ii] * self.HSoutList[nd[ii].indx].interp(outdir)
            return interpVal
        else:
            return 0.0

    def qexact(self, iin: Int, jout: Int) -> Float64:
        if self.btdftype == "HS":
            return self.HSoutList[iin][jout]
        elif self.btdftype == "TRGZ":
            return self.HSoutList[self.DataIndx[iin]][jout]
        else:
            return 0.0

    def summary(self):
        print("\noutput Hemisphirals:")
        self.HSoutList[0].summary()

    def plotview(self, first: Int, last: Int, viewsize: Int, theta: Float64 = 0, phi: Float64 = 0, zeta: Float64 = 0):
        var first_ = first
        var last_ = last
        if first_ < 0 or last_ < 0:
            return
        if last_ > self.HSoutList.size() - 1:
            last_ = self.HSoutList.size() - 1
        for ii in range(first_, last_ + 1):
            print("HSout[", ii, "]: ")
            self.HSoutList[ii].plotview(viewsize, self.HSoutList[ii].valMin(), self.HSoutList[ii].valMax(), theta, phi, zeta)

    def load(inout self, infile: inout File) -> File:
        var ii: Int = 0
        var hs0: HemiSphiral = HemiSphiral()
        while hs0.load(infile):
            self.HSoutList.push_back(hs0)
            ii += 1
        if ii == 0:
            infile.set_error(True)  # equivalent to ios::failbit
            writewndo("btdf::load: HSoutList empty\n", "e")
            return infile
        return infile

    def save(self, outfile: inout File) -> File:
        for ii in range(self.HSoutList.size()):
            self.HSoutList[ii].save(outfile)
        return outfile

def btdfLoad(infile: inout File) -> btdf:
    var inlinestr: String = String()
    var argList: List[String] = List[String]()
    infile.readline(inlinestr)
    argList = vParseList(inlinestr, ",")
    var type_: String = argList[0]
    if type_ == "HS":
        var pbtdf0: btdf = btdf()
        pbtdf0.btdftype = type_
        pbtdf0.load(infile)
        pbtdf0.HSin = HemiSphiral(pbtdf0.size())
        pbtdf0.HSin.value().init()
        return pbtdf0
    elif type_ == "TRGZ":
        var pbtdf0: btdf = btdf()
        pbtdf0.btdftype = type_
        var nTrgz: Int = Int(argList[1])
        if nTrgz != pbtdf0.Trgz0.NTrgz():
            var errmsg: String = "btdf::load: infile nTrgz <-> pbtdf0->NTrgz() mismatch\n"
            writewndo(errmsg, "e")
            return pbtdf0  # return empty? original returns 0
        pbtdf0.Isym = Int(argList[2])
        infile.readline(inlinestr)
        argList = vParseList(inlinestr, ",")
        for ii in range(pbtdf0.Trgz0.NTrgz()):
            pbtdf0.DataIndx.push_back(Int(argList[ii]))
        pbtdf0.load(infile)
        return pbtdf0
    else:
        var errmsg: String = "btdf::load: Bad btdf type: " + type_ + "\n"
        writewndo(errmsg, "e")
        return btdf()  # return empty

struct Tregenza:
    var NTheta: Int
    var deltaTheta: Float64
    var MPhi: List[Int]
    var omega: List[Float64]

    def __init__(inout self):
        self.NTheta = 8
        self.deltaTheta = 90.0 / (self.NTheta - 0.5)
        self.MPhi = List[Int](self.NTheta)
        self.MPhi[0] = 1
        self.MPhi[1] = 6
        self.MPhi[2] = 12
        self.MPhi[3] = 18
        self.MPhi[4] = 24
        self.MPhi[5] = 24
        self.MPhi[6] = 30
        self.MPhi[7] = 30
        self.omega = List[Float64](self.NTheta)
        self.omega[0] = 0.0344
        self.omega[1] = 0.0455
        self.omega[2] = 0.0445
        self.omega[3] = 0.0429
        self.omega[4] = 0.0407
        self.omega[5] = 0.0474
        self.omega[6] = 0.0416
        self.omega[7] = 0.0435

    def __del__(owned self):

    def iTheta(self, Theta: Float64) -> Int:
        return Int(Theta / self.deltaTheta)

    def jPhi(self, Theta: Float64, Phi: Float64) -> Int:
        return Int(Phi * self.MPhi[self.iTheta(Theta)] / 360.0)

    def ii0(self, itheta: Int) -> Int:
        if itheta == 0:
            return 0
        else:
            return self.MPhi[itheta - 1] + self.ii0(itheta - 1)

    def NTrgz(self) -> Int:
        return self.MPhi[self.NTheta - 1] + self.ii0(self.NTheta - 1)

    def iiTrgz(self, Theta: Float64, Phi: Float64) -> Int:
        return self.ii0(self.iTheta(Theta)) + self.jPhi(Theta, Phi)

    def iTheta(self, ii: Int) -> Int:
        var itheta: Int
        for itheta in range(self.NTheta):
            if ii < self.ii0(itheta):
                break
        return itheta - 1

    def jPhi(self, ii: Int) -> Int:
        return ii - self.ii0(self.iTheta(ii))

    def Theta(self, ii: Int) -> Float64:
        return self.deltaTheta * self.iTheta(ii)

    def Phi(self, ii: Int) -> Float64:
        return self.jPhi(ii) * 360.0 / self.MPhi[self.iTheta(ii)]

    def PhiSym(self, phi: Float64, Isym: Int) -> Float64:
        if Isym == 0:
            return phi
        elif Isym == 1:
            return 0.0
        elif Isym == 2:
            if phi >= 0.0 and phi <= 180.0:
                return phi
            else:
                return fmod(360.0 - phi, 360.0)
        elif Isym == 3:
            if (phi >= 270.0 and phi < 360.0) or (phi >= 0.0 and phi <= 90.0):
                return phi
            else:
                if (phi > 90.0 and phi < 180.0):
                    return 180.0 - phi
                else:
                    return fmod(540.0 - phi, 360.0)
        elif Isym == 4:
            if phi >= 0.0 and phi <= 90.0:
                return phi
            elif (phi > 90.0 and phi <= 180.0):
                return 180.0 - phi
            elif (phi > 180.0 and phi < 270.0):
                return phi - 180.0
            else:
                return 360.0 - phi
        else:
            return phi

    def iiSym(self, ii: Int, Isym: Int) -> Int:
        return self.iiTrgz(self.Theta(ii), self.PhiSym(self.Phi(ii), Isym))

    def dir(self, ii: Int) -> vector3:
        return AnglesToDir3D(DegToRad(self.Phi(ii)), DegToRad(self.Theta(ii)))

    def Omega(self, ii: Int) -> Float64:
        return self.omega[self.iTheta(ii)]

    def summary(self):
        print("NTrgz: ", self.NTrgz())

    def nearestc(self, arcdistmax: Float64, dirext: vector3, nd: inout List[nearestdata]) -> Int:
        var distmin: List[Float64] = List[Float64]()
        var distminindx: List[Int] = List[Int]()
        var arcdist0: Float64
        for ii in range(self.NTrgz()):
            arcdist0 = arcdist(dirext, self.dir(ii))
            if arcdist0 < arcdistmax:
                distminindx.push_back(ii)
                distmin.push_back(arcdist0)
        var tdminindx: List[Int] = List[Int]()
        var tdmin: List[Float64] = List[Float64]()
        for ii in range(distminindx.size()):
            var jj: Int = 0
            var found: Bool = False
            while jj < tdminindx.size():
                if distminindx[ii] == tdminindx[jj]:
                    found = True
                    break
                if distmin[ii] < tdmin[jj]:
                    break
                jj += 1
            if not found:
                tdminindx.insert(jj, distminindx[ii])
                tdmin.insert(jj, distmin[ii])
        nd.resize(tdminindx.size())
        for ii in range(tdminindx.size()):
            nd[ii].indx = tdminindx[ii]
            nd[ii].adist = tdmin[ii]
        return tdminindx.size()
from FenestrationCommon import CSeries
from builtins import List, Float64, Int, Bool

struct CAbsorptancesMultiPane:
    var m_T: List[CSeries]
    var m_Rf: List[CSeries]
    var m_Rb: List[CSeries]
    var m_Abs: List[CSeries]
    var m_rCoeffs: List[CSeries]
    var m_tCoeffs: List[CSeries]
    var Iplus: List[CSeries]
    var Iminus: List[CSeries]
    var m_StateCalculated: Bool

    def __init__(inout self, t_T: CSeries, t_Rf: CSeries, t_Rb: CSeries):
        self.m_T = List[CSeries]()
        self.m_Rf = List[CSeries]()
        self.m_Rb = List[CSeries]()
        self.m_Abs = List[CSeries]()
        self.m_rCoeffs = List[CSeries]()
        self.m_tCoeffs = List[CSeries]()
        self.Iplus = List[CSeries]()
        self.Iminus = List[CSeries]()
        self.m_StateCalculated = False
        self.m_T.append(t_T)
        self.m_Rf.append(t_Rf)
        self.m_Rb.append(t_Rb)

    def addLayer(inout self, t_T: CSeries, t_Rf: CSeries, t_Rb: CSeries):
        self.m_T.append(t_T)
        self.m_Rf.append(t_Rf)
        self.m_Rb.append(t_Rb)
        self.m_StateCalculated = False

    def Abs(inout self, Index: Int) -> CSeries:
        self.calculateState()
        return self.m_Abs[Index]

    def numOfLayers(inout self) -> Int:
        self.calculateState()
        return self.m_Abs.size

    def iplus(inout self, Index: Int) -> CSeries:
        self.calculateState()
        return self.Iplus[Index]

    def iminus(inout self, Index: Int) -> CSeries:
        self.calculateState()
        return self.Iminus[Index]

    def calculateState(inout self):
        if not self.m_StateCalculated:
            var size: Int = self.m_T.size
            var r: CSeries = CSeries()
            var t: CSeries = CSeries()
            var wv: List[Float64] = self.m_T[size - 1].getXArray()
            r.setConstantValues(wv, 0)
            t.setConstantValues(wv, 0)
            self.m_rCoeffs.clear()
            self.m_tCoeffs.clear()
            var i: Int = size - 1
            while i >= 0:
                t = self.tCoeffs(self.m_T[i], self.m_Rb[i], r)
                r = self.rCoeffs(self.m_T[i], self.m_Rf[i], self.m_Rb[i], r)
                self.m_rCoeffs.insert(0, r)
                self.m_tCoeffs.insert(0, t)
                i -= 1
            size = self.m_rCoeffs.size
            var Im: CSeries = CSeries()
            var Ip: CSeries = CSeries()
            Im.setConstantValues(wv, 1)
            self.Iminus.append(Im)
            for k in range(size):
                Ip = self.m_rCoeffs[k] * Im
                Im = self.m_tCoeffs[k] * Im
                self.Iplus.append(Ip)
                self.Iminus.append(Im)
            Ip.setConstantValues(wv, 0)
            self.Iplus.append(Ip)
            self.m_Abs.clear()
            size = self.Iminus.size
            for j in range(size - 1):
                var Iincoming = self.Iminus[j] - self.Iplus[j]
                var Ioutgoing = self.Iminus[j + 1] - self.Iplus[j + 1]
                var layerAbs: CSeries = Iincoming - Ioutgoing
                self.m_Abs.append(layerAbs)
            self.m_StateCalculated = True

    def rCoeffs(self, t_T: CSeries, t_Rf: CSeries, t_Rb: CSeries, t_RCoeffs: CSeries) -> CSeries:
        var rCoeffs: CSeries = CSeries()
        var size: Int = t_T.size
        for i in range(size):
            var wl: Float64 = t_T[i].x()
            var rValue: Float64 = t_Rf[i].value() + t_T[i].value() * t_T[i].value() * t_RCoeffs[i].value() / (1.0 - t_Rb[i].value() * t_RCoeffs[i].value())
            rCoeffs.addProperty(wl, rValue)
        return rCoeffs

    def tCoeffs(self, t_T: CSeries, t_Rb: CSeries, t_RCoeffs: CSeries) -> CSeries:
        var tCoeffs: CSeries = CSeries()
        var size: Int = t_T.size
        for i in range(size):
            var wl: Float64 = t_T[i].x()
            var tValue: Float64 = t_T[i].value() / (1.0 - t_Rb[i].value() * t_RCoeffs[i].value())
            tCoeffs.addProperty(wl, tValue)
        return tCoeffs
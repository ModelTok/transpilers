from WCECommon import Side, EnumSide, SquareMatrix, PropertySimple
from BaseCell import CBaseCell
from BSDFDirections import BSDFDirection, CBSDFDirections, CBSDFHemisphere
from BSDFIntegrator import CBSDFIntegrator
from BeamDirection import CBeamDirection
from FenestrationCommon import CSeries

type BSDF_Results = List[Pointer[CBSDFIntegrator]]

@value
class CBSDFLayer:
    var m_BSDFHemisphere: CBSDFHemisphere
    var m_Cell: Pointer[CBaseCell]
    var m_Results: Pointer[CBSDFIntegrator]
    var m_WVResults: Pointer[BSDF_Results]
    var m_Calculated: Bool
    var m_CalculatedWV: Bool

    def __init__(inout self, t_Cell: Pointer[CBaseCell], t_Hemisphere: CBSDFHemisphere):
        self.m_BSDFHemisphere = t_Hemisphere
        self.m_Cell = t_Cell
        self.m_Calculated = False
        self.m_CalculatedWV = False
        self.m_Results = Pointer[CBSDFIntegrator].init(
            self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
        )

    def setSourceData(inout self, inout t_SourceData: CSeries):
        self.m_Cell[].setSourceData(t_SourceData)
        self.m_Calculated = False
        self.m_CalculatedWV = False

    def getDirections(self, t_Side: BSDFDirection) -> borrowed CBSDFDirections:
        return self.m_BSDFHemisphere.getDirections(t_Side)

    def getResults(inout self) -> Pointer[CBSDFIntegrator]:
        if not self.m_Calculated:
            self.calculate()
            self.m_Calculated = True
        return self.m_Results

    def getWavelengthResults(inout self) -> Pointer[BSDF_Results]:
        if not self.m_CalculatedWV:
            self.calculate_wv()
            self.m_CalculatedWV = True
        return self.m_WVResults

    def getBandIndex(self, t_Wavelength: Float64) -> Int:
        return self.m_Cell[].getBandIndex(t_Wavelength)

    def getBandWavelengths(self) -> List[Float64]:
        return self.m_Cell[].getBandWavelengths()

    def setBandWavelengths(inout self, wavelengths: List[Float64]):
        self.m_Cell[].setBandWavelengths(wavelengths)

    def getCell(self) -> Pointer[CBaseCell]:
        return self.m_Cell

    # Protected methods
    def calcDiffuseDistribution(self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: Int):
        ...

    def calcDiffuseDistribution_wv(self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: Int):
        ...

    # Private methods
    def calculate(inout self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir()
        self.calc_dir_dif()

    def calculate_wv(inout self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir_wv()
        self.calc_dir_dif_wv()

    def calc_dir_dir(inout self):
        for t_Side in EnumSide():
            var aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            var size = aDirections.size()
            var tau = SquareMatrix(size)
            var rho = SquareMatrix(size)
            for i in range(size):
                var aDirection = aDirections[i].centerPoint()
                var Lambda = aDirections[i].lambda()
                var aTau = self.m_Cell[].T_dir_dir(t_Side, aDirection)
                var aRho = self.m_Cell[].R_dir_dir(t_Side, aDirection)
                tau[i][i] = tau[i][i] + aTau / Lambda
                rho[i][i] = rho[i][i] + aRho / Lambda
            self.m_Results[].setResultMatrices(tau, rho, t_Side)

    def calc_dir_dir_wv(inout self):
        for aSide in EnumSide():
            var aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            var size = aDirections.size()
            for i in range(size):
                var aDirection = aDirections[i].centerPoint()
                var aTau = self.m_Cell[].T_dir_dir_band(aSide, aDirection)
                var aRho = self.m_Cell[].R_dir_dir_band(aSide, aDirection)
                var Lambda = aDirections[i].lambda()
                var numWV = aTau.size()
                for j in range(numWV):
                    var aResults = self.m_WVResults[][j][]
                    var tau = aResults.getMatrix(aSide, PropertySimple.T)
                    var rho = aResults.getMatrix(aSide, PropertySimple.R)
                    tau[i][i] = tau[i][i] + aTau[j] / Lambda
                    rho[i][i] = rho[i][i] + aRho[j] / Lambda

    def calc_dir_dif(inout self):
        for aSide in EnumSide():
            var aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            var size = aDirections.size()
            for i in range(size):
                var aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution(aSide, aDirection, i)

    def calc_dir_dif_wv(inout self):
        for aSide in EnumSide():
            var aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            var size = aDirections.size()
            for i in range(size):
                var aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution_wv(aSide, aDirection, i)

    def fillWLResultsFromMaterialCell(inout self):
        self.m_WVResults = Pointer[BSDF_Results].init(BSDF_Results())
        var size = self.m_Cell[].getBandSize()
        for i in range(size):
            var aResults = Pointer[CBSDFIntegrator].init(
                self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            )
            self.m_WVResults[].append(aResults)
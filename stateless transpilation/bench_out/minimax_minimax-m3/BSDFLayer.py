# EXTERNAL DEPS (to wire in glue):
#   - Side (FenestrationCommon::Side, enum class)
#   - EnumSide() (FenestrationCommon free function, returns iterable of Side values)
#   - CSeries (FenestrationCommon::CSeries, class)
#   - CBaseCell (SingleLayerOptics::CBaseCell, class)
#       methods: setSourceData, getBandIndex, getBandWavelengths, setBandWavelengths,
#                T_dir_dir, R_dir_dir, T_dir_dir_band, R_dir_dir_band, getBandSize
#   - CBSDFIntegrator (SingleLayerOptics::CBSDFIntegrator, class)
#       methods: setResultMatrices, getMatrix
#   - CBeamDirection (SingleLayerOptics::CBeamDirection, class)
#   - CBSDFDirections (SingleLayerOptics::CBSDFDirections, class)
#       methods: size, __getitem__ (indexing), centerPoint, lambda_  (lambda renamed: Py keyword)
#   - CBSDFHemisphere (SingleLayerOptics::CBSDFHemisphere, class)
#       methods: getDirections
#   - BSDFDirection (SingleLayerOptics::BSDFDirection, enum; attribute Incoming used)
#   - SquareMatrix (WCECommon::SquareMatrix; constructor takes size; supports [i,i])
#   - PropertySimple (enum; attributes T and R used)

from abc import ABC, abstractmethod
from typing import List, Optional


# ---- External type placeholders (wired in via glue) ----
Side = object
CSeries = object
CBaseCell = object
CBSDFIntegrator = object
CBeamDirection = object
CBSDFDirections = object
CBSDFHemisphere = object
BSDFDirection = object
SquareMatrix = object
PropertySimple = object


def EnumSide():
    """Stub: returns iterable of all Side values (from FenestrationCommon)."""
    raise NotImplementedError("Wire in EnumSide from FenestrationCommon")


# typedef std::vector<std::shared_ptr<CBSDFIntegrator>> BSDF_Results;
BSDF_Results = List[CBSDFIntegrator]


class CBSDFLayer(ABC):
    def __init__(self, t_Cell, t_Directions):
        # type: (CBaseCell, CBSDFHemisphere) -> None
        self.m_BSDFHemisphere = t_Directions
        self.m_Cell = t_Cell
        self.m_Calculated = False
        self.m_CalculatedWV = False
        # TODO: Maybe to refactor results to incoming and outgoing if not affecting speed.
        # This is not necessary before axisymmetry is introduced
        self.m_Results = CBSDFIntegrator(
            self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
        )
        self.m_WVResults = None  # type: Optional[BSDF_Results]

    def setSourceData(self, t_SourceData):
        # type: (CSeries) -> None
        self.m_Cell.setSourceData(t_SourceData)
        self.m_Calculated = False
        self.m_CalculatedWV = False

    def getDirections(self, t_Side):
        # type: (BSDFDirection) -> CBSDFDirections
        return self.m_BSDFHemisphere.getDirections(t_Side)

    def getResults(self):
        # type: () -> CBSDFIntegrator
        if not self.m_Calculated:
            self.calculate()
            self.m_Calculated = True
        return self.m_Results

    def getWavelengthResults(self):
        # type: () -> Optional[BSDF_Results]
        if not self.m_CalculatedWV:
            self.calculate_wv()
            self.m_CalculatedWV = True
        return self.m_WVResults

    def getBandIndex(self, t_Wavelength):
        # type: (float) -> int
        return self.m_Cell.getBandIndex(t_Wavelength)

    def getBandWavelengths(self):
        # type: () -> List[float]
        return self.m_Cell.getBandWavelengths()

    def setBandWavelengths(self, wavelengths):
        # type: (List[float]) -> None
        self.m_Cell.setBandWavelengths(wavelengths)

    @abstractmethod
    def calcDiffuseDistribution(self, aSide, t_Direction, t_DirectionIndex):
        # type: (Side, CBeamDirection, int) -> None
        pass

    @abstractmethod
    def calcDiffuseDistribution_wv(self, aSide, t_Direction, t_DirectionIndex):
        # type: (Side, CBeamDirection, int) -> None
        pass

    def calculate(self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir()
        self.calc_dir_dif()

    def calculate_wv(self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir_wv()
        self.calc_dir_dif_wv()

    def getCell(self):
        # type: () -> CBaseCell
        return self.m_Cell

    def calc_dir_dir(self):
        for t_Side in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = aDirections.size()
            tau = SquareMatrix(size)
            rho = SquareMatrix(size)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                Lambda = aDirections[i].lambda_()  # 'lambda' is a Python keyword

                aTau = self.m_Cell.T_dir_dir(t_Side, aDirection)
                aRho = self.m_Cell.R_dir_dir(t_Side, aDirection)

                tau[i, i] += aTau / Lambda
                rho[i, i] += aRho / Lambda
            self.m_Results.setResultMatrices(tau, rho, t_Side)

    def calc_dir_dir_wv(self):
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = aDirections.size()
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                aTau = self.m_Cell.T_dir_dir_band(aSide, aDirection)
                aRho = self.m_Cell.R_dir_dir_band(aSide, aDirection)
                Lambda = aDirections[i].lambda_()  # 'lambda' is a Python keyword
                numWV = len(aTau)
                for j in range(numWV):
                    aResults = self.m_WVResults[j]
                    tau = aResults.getMatrix(aSide, PropertySimple.T)
                    rho = aResults.getMatrix(aSide, PropertySimple.R)
                    tau[i, i] += aTau[j] / Lambda
                    rho[i, i] += aRho[j] / Lambda

    def calc_dir_dif(self):
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = aDirections.size()
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution(aSide, aDirection, i)

    def calc_dir_dif_wv(self):
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = aDirections.size()
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution_wv(aSide, aDirection, i)

    def fillWLResultsFromMaterialCell(self):
        self.m_WVResults = []
        size = self.m_Cell.getBandSize()
        for i in range(size):
            aResults = CBSDFIntegrator(
                self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            )
            self.m_WVResults.append(aResults)

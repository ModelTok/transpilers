# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side: from FenestrationCommon import Side
# - FenestrationCommon.CSeries: from FenestrationCommon import CSeries
# - SingleLayerOptics.CEquivalentBSDFLayer: from MultiLayerOptics import CEquivalentBSDFLayer
# - SingleLayerOptics.BSDFDirection: from SingleLayerOptics import BSDFDirection
# - SingleLayerOptics.CBaseCell: from SingleLayerOptics import CBaseCell
# - SingleLayerOptics.CBSDFIntegrator: from SingleLayerOptics import CBSDFIntegrator
# - SingleLayerOptics.CBeamDirection: from SingleLayerOptics import CBeamDirection
# - SingleLayerOptics.CBSDFDirections: from SingleLayerOptics import CBSDFDirections
# - SingleLayerOptics.CBSDFHemisphere: from SingleLayerOptics import CBSDFHemisphere
# - SingleLayerOptics.SquareMatrix: from SingleLayerOptics import SquareMatrix
# - SingleLayerOptics.PropertySimple: from SingleLayerOptics import PropertySimple
# - SingleLayerOptics.EnumSide: from FenestrationCommon import EnumSide

from typing import List, Optional, Tuple
from dataclasses import dataclass
from abc import ABC, abstractmethod
import math

from FenestrationCommon import Side, CSeries, EnumSide
from SingleLayerOptics import (
    BSDFDirection,
    CBaseCell,
    CBSDFIntegrator,
    CBeamDirection,
    CBSDFDirections,
    CBSDFHemisphere,
    SquareMatrix,
    PropertySimple,
)

BSDF_Results = List[CBSDFIntegrator]


class CBSDFLayer(ABC):
    def __init__(self, t_Cell: CBaseCell, t_Directions: CBSDFHemisphere) -> None:
        self.m_BSDFHemisphere: CBSDFHemisphere = t_Directions
        self.m_Cell: CBaseCell = t_Cell
        self.m_Results: Optional[CBSDFIntegrator] = None
        self.m_WVResults: Optional[List[CBSDFIntegrator]] = None
        self.m_Calculated: bool = False
        self.m_CalculatedWV: bool = False

        self.m_Results = CBSDFIntegrator(self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming))

    def setSourceData(self, t_SourceData: CSeries) -> None:
        self.m_Cell.setSourceData(t_SourceData)
        self.m_Calculated = False
        self.m_CalculatedWV = False

    def getResults(self) -> CBSDFIntegrator:
        if not self.m_Calculated:
            self.calculate()
            self.m_Calculated = True
        return self.m_Results

    def getDirections(self, t_Side: BSDFDirection) -> CBSDFDirections:
        return self.m_BSDFHemisphere.getDirections(t_Side)

    def getWavelengthResults(self) -> List[CBSDFIntegrator]:
        if not self.m_CalculatedWV:
            self.calculate_wv()
            self.m_CalculatedWV = True
        return self.m_WVResults

    def getBandIndex(self, t_Wavelength: float) -> int:
        return self.m_Cell.getBandIndex(t_Wavelength)

    def getBandWavelengths(self) -> List[float]:
        return self.m_Cell.getBandWavelengths()

    def setBandWavelengths(self, wavelengths: List[float]) -> None:
        self.m_Cell.setBandWavelengths(wavelengths)

    @abstractmethod
    def calcDiffuseDistribution(self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: int) -> None:
        pass

    @abstractmethod
    def calcDiffuseDistribution_wv(self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: int) -> None:
        pass

    def calculate(self) -> None:
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir()
        self.calc_dir_dif()

    def calculate_wv(self) -> None:
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir_wv()
        self.calc_dir_dif_wv()

    def calc_dir_dir(self) -> None:
        for t_Side in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            tau = SquareMatrix(size)
            rho = SquareMatrix(size)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                Lambda = aDirections[i].lambda_()
                aTau = self.m_Cell.T_dir_dir(t_Side, aDirection)
                aRho = self.m_Cell.R_dir_dir(t_Side, aDirection)

                tau[i][i] += aTau / Lambda
                rho[i][i] += aRho / Lambda
            self.m_Results.setResultMatrices(tau, rho, t_Side)

    def calc_dir_dir_wv(self) -> None:
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                aTau = self.m_Cell.T_dir_dir_band(aSide, aDirection)
                aRho = self.m_Cell.R_dir_dir_band(aSide, aDirection)
                Lambda = aDirections[i].lambda_()
                numWV = len(aTau)
                for j in range(numWV):
                    aResults = self.m_WVResults[j]
                    tau = aResults.getMatrix(aSide, PropertySimple.T)
                    rho = aResults.getMatrix(aSide, PropertySimple.R)
                    tau[i][i] += aTau[j] / Lambda
                    rho[i][i] += aRho[j] / Lambda

    def calc_dir_dif(self) -> None:
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution(aSide, aDirection, i)

    def calc_dir_dif_wv(self) -> None:
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution_wv(aSide, aDirection, i)

    def fillWLResultsFromMaterialCell(self) -> None:
        self.m_WVResults = []
        size = self.m_Cell.getBandSize()
        for i in range(size):
            aResults = CBSDFIntegrator(self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming))
            self.m_WVResults.append(aResults)

    def getCell(self) -> CBaseCell:
        return self.m_Cell

"""
Python port of BSDFLayer.hpp / BSDFLayer.cpp
"""
from __future__ import annotations
import abc
from typing import List, Optional, Sequence, Tuple, TypeVar, Union

T = TypeVar('T')
# Type aliases
BSDF_Results = List['CBSDFIntegrator']

# EXTERNAL DEPS (to wire in glue):
# FenestrationCommon.Side (enum)
# FenestrationCommon.CSeries (class)
# MultiLayerOptics.CEquivalentBSDFLayer (class)
# SingleLayerOptics.BSDFDirection (enum)
# SingleLayerOptics.CBaseCell (class)
# SingleLayerOptics.CBSDFIntegrator (class)
# SingleLayerOptics.CBeamDirection (class)
# SingleLayerOptics.CBSDFDirections (class)
# SingleLayerOptics.CBSDFHemisphere (class)
# FenestrationCommon.PropertySimple (enum)
# FenestrationCommon.SquareMatrix (class)


class CBSDFLayer(abc.ABC):
    """Base class for handling BSDF Layer"""

    def __init__(
        self,
        t_Cell: 'CBaseCell',
        t_Hemisphere: 'CBSDFHemisphere',
    ):
        self.m_BSDFHemisphere: 'CBSDFHemisphere' = t_Hemisphere
        self.m_Cell: 'CBaseCell' = t_Cell
        self.m_Calculated: bool = False
        self.m_CalculatedWV: bool = False
        self.m_Results: 'CBSDFIntegrator' = (
            self.m_BSDFHemisphere.getDirections('Incoming')
        )
        self.m_WVResults: Optional[BSDF_Results] = None

    def setSourceData(self, t_SourceData: 'CSeries') -> None:
        self.m_Cell.setSourceData(t_SourceData)
        self.m_Calculated = False
        self.m_CalculatedWV = False

    def getDirections(self, t_Side: 'BSDFDirection') -> 'CBSDFDirections':
        return self.m_BSDFHemisphere.getDirections(t_Side)

    def getResults(self) -> 'CBSDFIntegrator':
        if not self.m_Calculated:
            self.calculate()
            self.m_Calculated = True
        return self.m_Results

    def getWavelengthResults(self) -> BSDF_Results:
        if not self.m_CalculatedWV:
            self.calculate_wv()
            self.m_CalculatedWV = True
        return self.m_WVResults  # type: ignore

    def getBandIndex(self, t_Wavelength: float) -> int:
        return self.m_Cell.getBandIndex(t_Wavelength)

    def getBandWavelengths(self) -> List[float]:
        return self.m_Cell.getBandWavelengths()

    def setBandWavelengths(self, wavelengths: List[float]) -> None:
        self.m_Cell.setBandWavelengths(wavelengths)

    def getCell(self) -> 'CBaseCell':
        return self.m_Cell

    # Protected pure‑virtual methods
    @abc.abstractmethod
    def calcDiffuseDistribution(
        self,
        aSide: 'Side',
        t_Direction: 'CBeamDirection',
        t_DirectionIndex: int,
    ) -> None:
        ...

    @abc.abstractmethod
    def calcDiffuseDistribution_wv(
        self,
        aSide: 'Side',
        t_Direction: 'CBeamDirection',
        t_DirectionIndex: int,
    ) -> None:
        ...

    # Protected methods
    def calculate(self) -> None:
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir()
        self.calc_dir_dif()

    def calculate_wv(self) -> None:
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir_wv()
        self.calc_dir_dif_wv()

    # Private methods
    def calc_dir_dir(self) -> None:
        for t_Side in Side:  # EnumSide()
            aDirections: 'CBSDFDirections' = self.m_BSDFHemisphere.getDirections(
                'Incoming'
            )
            size: int = len(aDirections)
            tau: 'SquareMatrix' = SquareMatrix(size)
            rho: 'SquareMatrix' = SquareMatrix(size)
            for i in range(size):
                aDirection: 'CBeamDirection' = aDirections[i].centerPoint()
                Lambda: float = aDirections[i].lambda()
                aTau: float = self.m_Cell.T_dir_dir(t_Side, aDirection)
                aRho: float = self.m_Cell.R_dir_dir(t_Side, aDirection)
                tau(i, i) += aTau / Lambda
                rho(i, i) += aRho / Lambda
            self.m_Results.setResultMatrices(tau, rho, t_Side)

    def calc_dir_dir_wv(self) -> None:
        for aSide in Side:  # EnumSide()
            aDirections: 'CBSDFDirections' = self.m_BSDFHemisphere.getDirections(
                'Incoming'
            )
            size: int = len(aDirections)
            for i in range(size):
                aDirection: 'CBeamDirection' = aDirections[i].centerPoint()
                aTau: List[float] = self.m_Cell.T_dir_dir_band(aSide, aDirection)
                aRho: List[float] = self.m_Cell.R_dir_dir_band(aSide, aDirection)
                Lambda: float = aDirections[i].lambda()
                numWV: int = len(aTau)
                for j in range(numWV):
                    aResults: 'CBSDFIntegrator' = self.m_WVResults[j]  # type: ignore
                    tau: 'SquareMatrix' = aResults.getMatrix(aSide, 'T')
                    rho: 'SquareMatrix' = aResults.getMatrix(aSide, 'R')
                    tau(i, i) += aTau[j] / Lambda
                    rho(i, i) += aRho[j] / Lambda

    def calc_dir_dif(self) -> None:
        for aSide in Side:  # EnumSide()
            aDirections: 'CBSDFDirections' = self.m_BSDFHemisphere.getDirections(
                'Incoming'
            )
            size: int = len(aDirections)
            for i in range(size):
                aDirection: 'CBeamDirection' = aDirections[i].centerPoint()
                self.calcDiffuseDistribution(aSide, aDirection, i)

    def calc_dir_dif_wv(self) -> None:
        for aSide in Side:  # EnumSide()
            aDirections: 'CBSDFDirections' = self.m_BSDFHemisphere.getDirections(
                'Incoming'
            )
            size: int = len(aDirections)
            for i in range(size):
                aDirection: 'CBeamDirection' = aDirections[i].centerPoint()
                self.calcDiffuseDistribution_wv(aSide, aDirection, i)

    def fillWLResultsFromMaterialCell(self) -> None:
        self.m_WVResults = []
        size: int = self.m_Cell.getBandSize()
        for _ in range(size):
            aResults: 'CBSDFIntegrator' = (
                self.m_BSDFHemisphere.getDirections('Incoming')
            )
            self.m_WVResults.append(aResults)

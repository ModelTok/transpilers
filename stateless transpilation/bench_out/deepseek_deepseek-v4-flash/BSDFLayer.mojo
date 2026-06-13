# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side: from FenestrationCommon import Side
# - FenestrationCommon.CSeries: from FenestrationCommon import CSeries
# - MultiLayerOptics.CEquivalentBSDFLayer: from MultiLayerOptics import CEquivalentBSDFLayer
# - SingleLayerOptics.BSDFDirection: from SingleLayerOptics import BSDFDirection
# - SingleLayerOptics.CBaseCell: from SingleLayerOptics import CBaseCell
# - SingleLayerOptics.CBSDFIntegrator: from SingleLayerOptics import CBSDFIntegrator
# - SingleLayerOptics.CBeamDirection: from SingleLayerOptics import CBeamDirection
# - SingleLayerOptics.CBSDFDirections: from SingleLayerOptics import CBSDFDirections
# - SingleLayerOptics.CBSDFHemisphere: from SingleLayerOptics import CBSDFHemisphere
# - SingleLayerOptics.SquareMatrix: from SingleLayerOptics import SquareMatrix
# - SingleLayerOptics.PropertySimple: from SingleLayerOptics import PropertySimple
# - SingleLayerOptics.EnumSide: from FenestrationCommon import EnumSide

from typing import List, Optional
from math import sqrt, fabs
from memory import Pointer
from utils import List as MojoList

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

type BSDF_Results = List[CBSDFIntegrator]


struct CBSDFLayer:
    var m_BSDFHemisphere: CBSDFHemisphere
    var m_Cell: CBaseCell
    var m_Results: CBSDFIntegrator
    var m_WVResults: BSDFResults
    var m_Calculated: Bool
    var m_CalculatedWV: Bool

    fn __init__(inout self, t_Cell: CBaseCell, t_Directions: CBSDFHemisphere):
        self.m_BSDFHemisphere = t_Directions
        self.m_Cell = t_Cell
        self.m_Results = CBSDFIntegrator(self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming))
        self.m_Calculated = False
        self.m_CalculatedWV = False

    fn setSourceData(inout self, t_SourceData: CSeries):
        self.m_Cell.setSourceData(t_SourceData)
        self.m_Calculated = False
        self.m_CalculatedWV = False

    fn getResults(inout self) -> CBSDFIntegrator:
        if not self.m_Calculated:
            self.calculate()
            self.m_Calculated = True
        return self.m_Results

    fn getDirections(self, t_Side: BSDFDirection) -> CBSDFDirections:
        return self.m_BSDFHemisphere.getDirections(t_Side)

    fn getWavelengthResults(inout self) -> BSDFResults:
        if not self.m_CalculatedWV:
            self.calculate_wv()
            self.m_CalculatedWV = True
        return self.m_WVResults

    fn getBandIndex(self, t_Wavelength: Float64) -> Int:
        return self.m_Cell.getBandIndex(t_Wavelength)

    fn getBandWavelengths(self) -> List[Float64]:
        return self.m_Cell.getBandWavelengths()

    fn setBandWavelengths(inout self, wavelengths: List[Float64]):
        self.m_Cell.setBandWavelengths(wavelengths)

    fn calcDiffuseDistribution(self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: Int):
        pass

    fn calcDiffuseDistribution_wv(self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: Int):
        pass

    fn calculate(inout self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir()
        self.calc_dir_dif()

    fn calculate_wv(inout self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir_wv()
        self.calc_dir_dif_wv()

    fn calc_dir_dir(inout self):
        for t_Side in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            tau = SquareMatrix(size)
            rho = SquareMatrix(size)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                lambda_ = aDirections[i].lambda_()
                aTau = self.m_Cell.T_dir_dir(t_Side, aDirection)
                aRho = self.m_Cell.R_dir_dir(t_Side, aDirection)
                tau[i][i] += aTau / lambda_
                rho[i][i] += aRho / lambda_
            self.m_Results.setResultMatrices(tau, rho, t_Side)

    fn calc_dir_dir_wv(inout self):
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                aTau = self.m_Cell.T_dir_dir_band(aSide, aDirection)
                aRho = self.m_Cell.R_dir_dir_band(aSide, aDirection)
                lambda_ = aDirections[i].lambda_()
                numWV = len(aTau)
                for j in range(numWV):
                    aResults = self.m_WVResults[j]
                    tau = aResults.getMatrix(aSide, PropertySimple.T)
                    rho = aResults.getMatrix(aSide, PropertySimple.R)
                    tau[i][i] += aTau[j] / lambda_
                    rho[i][i] += aRho[j] / lambda_

    fn calc_dir_dif(inout self):
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution(aSide, aDirection, i)

    fn calc_dir_dif_wv(inout self):
        for aSide in EnumSide():
            aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            size = len(aDirections)
            for i in range(size):
                aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution_wv(aSide, aDirection, i)

    fn fillWLResultsFromMaterialCell(inout self):
        self.m_WVResults = BSDFResults()
        size = self.m_Cell.getBandSize()
        for i in range(size):
            aResults = CBSDFIntegrator(self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming))
            self.m_WVResults.append(aResults)

    fn getCell(self) -> CBaseCell:
        return self.m_Cell

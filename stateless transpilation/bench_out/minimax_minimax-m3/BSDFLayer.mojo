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
#       methods: size, __getitem__ (indexing), centerPoint, lambda
#   - CBSDFHemisphere (SingleLayerOptics::CBSDFHemisphere, class)
#       methods: getDirections
#   - BSDFDirection (SingleLayerOptics::BSDFDirection, enum; attribute Incoming used)
#   - SquareMatrix (WCECommon::SquareMatrix; constructor takes size; supports [i,i])
#   - PropertySimple (enum; attributes T and R used)

from collections import List


# ---- External type placeholders (wired in via glue) ----
alias Side = ...
alias CSeries = ...
alias CBaseCell = ...
alias CBSDFIntegrator = ...
alias CBeamDirection = ...
alias CBSDFDirections = ...
alias CBSDFHemisphere = ...
alias BSDFDirection = ...
alias SquareMatrix = ...
alias PropertySimple = ...


fn EnumSide() -> List[Side]:
    """Stub: returns iterable of all Side values (from FenestrationCommon)."""
    raise Error("Wire in EnumSide from FenestrationCommon")


# typedef std::vector<std::shared_ptr<CBSDFIntegrator>> BSDF_Results;
alias BSDF_Results = List[CBSDFIntegrator]


struct CBSDFLayer:
    var m_BSDFHemisphere: CBSDFHemisphere
    var m_Cell: CBaseCell
    var m_Results: CBSDFIntegrator
    var m_WVResults: BSDF_Results
    var m_Calculated: Bool
    var m_CalculatedWV: Bool

    fn __init__(inout self, t_Cell: CBaseCell, t_Directions: CBSDFHemisphere):
        self.m_BSDFHemisphere = t_Directions
        self.m_Cell = t_Cell
        self.m_Calculated = False
        self.m_CalculatedWV = False
        # TODO: Maybe to refactor results to incoming and outgoing if not affecting speed.
        # This is not necessary before axisymmetry is introduced
        self.m_Results = CBSDFIntegrator(
            self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
        )
        self.m_WVResults = BSDF_Results()

    fn setSourceData(inout self, t_SourceData: CSeries):
        self.m_Cell.setSourceData(t_SourceData)
        self.m_Calculated = False
        self.m_CalculatedWV = False

    fn getDirections(self, t_Side: BSDFDirection) -> CBSDFDirections:
        return self.m_BSDFHemisphere.getDirections(t_Side)

    fn getResults(inout self) -> CBSDFIntegrator:
        if not self.m_Calculated:
            self.calculate()
            self.m_Calculated = True
        return self.m_Results

    fn getWavelengthResults(inout self) -> BSDF_Results:
        if not self.m_CalculatedWV:
            self.calculate_wv()
            self.m_CalculatedWV = True
        return self.m_WVResults

    fn getBandIndex(inout self, t_Wavelength: Float64) -> Int:
        return self.m_Cell.getBandIndex(t_Wavelength)

    fn getBandWavelengths(self) -> List[Float64]:
        return self.m_Cell.getBandWavelengths()

    fn setBandWavelengths(inout self, wavelengths: List[Float64]):
        self.m_Cell.setBandWavelengths(wavelengths)

    fn calcDiffuseDistribution(inout self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: Int):
        # Pure virtual - must be overridden by derived class
        raise Error("calcDiffuseDistribution must be implemented by derived class")

    fn calcDiffuseDistribution_wv(inout self, aSide: Side, t_Direction: CBeamDirection, t_DirectionIndex: Int):
        # Pure virtual - must be overridden by derived class
        raise Error("calcDiffuseDistribution_wv must be implemented by derived class")

    fn calculate(inout self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir()
        self.calc_dir_dif()

    fn calculate_wv(inout self):
        self.fillWLResultsFromMaterialCell()
        self.calc_dir_dir_wv()
        self.calc_dir_dif_wv()

    fn getCell(self) -> CBaseCell:
        return self.m_Cell

    fn calc_dir_dir(inout self):
        for t_Side in EnumSide():
            let aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            let size = aDirections.size()
            var tau = SquareMatrix(size)
            var rho = SquareMatrix(size)
            for i in range(size):
                let aDirection = aDirections[i].centerPoint()
                let Lambda = aDirections[i].lambda()

                let aTau = self.m_Cell.T_dir_dir(t_Side, aDirection)
                let aRho = self.m_Cell.R_dir_dir(t_Side, aDirection)

                tau[i, i] += aTau / Lambda
                rho[i, i] += aRho / Lambda
            self.m_Results.setResultMatrices(tau, rho, t_Side)

    fn calc_dir_dir_wv(inout self):
        for aSide in EnumSide():
            let aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            let size = aDirections.size()
            for i in range(size):
                let aDirection = aDirections[i].centerPoint()
                let aTau = self.m_Cell.T_dir_dir_band(aSide, aDirection)
                let aRho = self.m_Cell.R_dir_dir_band(aSide, aDirection)
                let Lambda = aDirections[i].lambda()
                let numWV = len(aTau)
                for j in range(numWV):
                    let aResults = self.m_WVResults[j]
                    let tau = aResults.getMatrix(aSide, PropertySimple.T)
                    let rho = aResults.getMatrix(aSide, PropertySimple.R)
                    tau[i, i] += aTau[j] / Lambda
                    rho[i, i] += aRho[j] / Lambda

    fn calc_dir_dif(inout self):
        for aSide in EnumSide():
            let aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            let size = aDirections.size()
            for i in range(size):
                let aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution(aSide, aDirection, i)

    fn calc_dir_dif_wv(inout self):
        for aSide in EnumSide():
            let aDirections = self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            let size = aDirections.size()
            for i in range(size):
                let aDirection = aDirections[i].centerPoint()
                self.calcDiffuseDistribution_wv(aSide, aDirection, i)

    fn fillWLResultsFromMaterialCell(inout self):
        self.m_WVResults = BSDF_Results()
        let size = self.m_Cell.getBandSize()
        for i in range(size):
            let aResults = CBSDFIntegrator(
                self.m_BSDFHemisphere.getDirections(BSDFDirection.Incoming)
            )
            self.m_WVResults.append(aResults)

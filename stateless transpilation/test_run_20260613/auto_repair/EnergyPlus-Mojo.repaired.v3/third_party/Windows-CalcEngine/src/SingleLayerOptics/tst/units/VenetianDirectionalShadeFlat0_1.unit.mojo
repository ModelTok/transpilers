from WCESingleLayerOptics import CBSDFLayer, CBSDFLayerMaker, CBSDFIntegrator, CBSDFHemisphere, DistributionMethod, BSDFBasis
from WCECommon import Material, Side, PropertySimple

struct TestVenetianDirectionalShadeFlat0_1:
    var m_Shade: Pointer[CBSDFLayer]

    def SetUp(inout self):
        let Tmat = 0.1
        let Rfmat = 0.7
        let Rbmat = 0.7
        let minLambda = 0.3
        let maxLambda = 2.5
        let aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
        let slatWidth = 0.010
        let slatSpacing = 0.010
        let slatTiltAngle = 45
        let curvatureRadius = 0
        let numOfSlatSegments: UInt = 1
        let aDistribution = DistributionMethod.DirectionalDiffuse
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Shade = CBSDFLayerMaker.getVenetianLayer(aMaterial, aBSDF, slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments, aDistribution, true)

    def GetShade(self) -> Pointer[CBSDFLayer]:
        return self.m_Shade

def TestVenetian1():
    # SCOPED_TRACE("Begin Test: Venetian cell (Flat, 45 degrees slats) - solar properties.")
    var fixture = TestVenetianDirectionalShadeFlat0_1()
    fixture.SetUp()
    let aShade = fixture.GetShade()
    let aResults = aShade.getResults()
    let tauDiff = aResults.DiffDiff(Side.Front, PropertySimple.T)
    assert abs(tauDiff - 0.44649813630049223) < 1e-6, "tauDiff mismatch"
    let RfDiff = aResults.DiffDiff(Side.Front, PropertySimple.R)
    assert abs(RfDiff - 0.28386835793952669) < 1e-6, "RfDiff mismatch"
    let theta = 23.0
    let phi = 198.0
    let tauHem = aResults.DirHem(Side.Front, PropertySimple.T, theta, phi)
    assert abs(tauHem - 0.42987405997685452) < 1e-6, "tauHem mismatch"
    let aT = aResults.getMatrix(Side.Front, PropertySimple.T)
    let size = aT.size()
    var correctResults: List[Float64] = List[Float64]()
    correctResults.append(3.8537531201195208)
    correctResults.append(4.1502982467458276)
    correctResults.append(6.4100346243744326)
    correctResults.append(7.3474092442895333)
    correctResults.append(6.4100346243744326)
    correctResults.append(4.1502982467458276)
    correctResults.append(1.8952091768254709)
    correctResults.append(0.9624818646186141)
    correctResults.append(1.8952091768254709)
    correctResults.append(3.8507492805553354)
    correctResults.append(7.1631325677152899)
    correctResults.append(9.5953311156279479)
    correctResults.append(10.487134124145857)
    correctResults.append(9.5953311156279479)
    correctResults.append(7.1631325677152899)
    correctResults.append(3.8507492805553367)
    correctResults.append(0.5499842626659959)
    correctResults.append(0.076422070782678389)
    correctResults.append(0.072113581483518790)
    correctResults.append(0.076422070782678389)
    correctResults.append(0.54998426266599365)
    correctResults.append(3.8507492805553394)
    correctResults.append(10.135661402447086)
    correctResults.append(11.234248057098451)
    correctResults.append(9.5441761716221478)
    correctResults.append(11.234248057098451)
    correctResults.append(10.135661402447086)
    correctResults.append(3.8507492805553412)
    correctResults.append(0.073751825599575688)
    correctResults.append(0.056801188075067718)
    correctResults.append(0.052393583794556338)
    correctResults.append(0.056801188075067677)
    correctResults.append(0.073751825599575660)
    correctResults.append(3.6627476023802092)
    correctResults.append(0.064003709245804577)
    correctResults.append(0.039335031220287420)
    correctResults.append(0.064003709245804577)
    correctResults.append(3.6627476023802141)
    correctResults.append(0.031558258087563060)
    correctResults.append(0.024104538133300955)
    correctResults.append(0.031558258087563032)
    assert correctResults.size() == size, "size mismatch"
    for i in range(size):
        assert abs(correctResults[i] - aT[i, i]) < 1e-5, "aT mismatch at index " + str(i)
    let aRf = aResults.getMatrix(Side.Front, PropertySimple.R)
    correctResults.clear()
    correctResults.append(0.12467701187757886)
    correctResults.append(0.12467701187757886)
    correctResults.append(0.11809576069675247)
    correctResults.append(0.11151450951592602)
    correctResults.append(0.11809576069675243)
    correctResults.append(0.12467701187757889)
    correctResults.append(0.11809576069675248)
    correctResults.append(0.11151450951592602)
    correctResults.append(0.11809576069675248)
    correctResults.append(0.12467701187757886)
    correctResults.append(0.10822388392551284)
    correctResults.append(0.056751264415241136)
    correctResults.append(0.039493797495131787)
    correctResults.append(0.056751264415241136)
    correctResults.append(0.10822388392551285)
    correctResults.append(0.12467701187757889)
    correctResults.append(0.10822388392551291)
    correctResults.append(0.065378671009513112)
    correctResults.append(0.048215999889970981)
    correctResults.append(0.065378671009513042)
    correctResults.append(0.10822388392551284)
    correctResults.append(0.12467701187757886)
    correctResults.append(0.046055713210097007)
    correctResults.append(0.0077108503397755159)
    correctResults.append(0.013944144090848406)
    correctResults.append(0.0077108503397755150)
    correctResults.append(0.046055713210097007)
    correctResults.append(0.12467701187757892)
    correctResults.append(0.054978145293713886)
    correctResults.append(0.011951549151406803)
    correctResults.append(0.023431122989891869)
    correctResults.append(0.011951549151406849)
    correctResults.append(0.054978145293713775)
    correctResults.append(0.12467701187757879)
    correctResults.append(0.031558258087563046)
    correctResults.append(0.024104538133300962)
    correctResults.append(0.031558258087563046)
    correctResults.append(0.12467701187757896)
    correctResults.append(0.064003709245804660)
    correctResults.append(0.039335031220287427)
    correctResults.append(0.064003709245804577)
    assert correctResults.size() == size, "size mismatch for aRf"
    for i in range(size):
        assert abs(correctResults[i] - aRf[i, i]) < 1e-5, "aRf mismatch at index " + str(i)
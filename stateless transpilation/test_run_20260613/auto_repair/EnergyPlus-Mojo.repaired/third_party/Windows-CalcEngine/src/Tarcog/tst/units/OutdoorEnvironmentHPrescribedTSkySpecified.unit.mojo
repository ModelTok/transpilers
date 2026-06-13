from WCETarcog import CEnvironment, CSingleSystem, Environments, Layers, SkyModel, BoundaryConditionsCoeffModel, CIGU

struct TestOutdoorEnvironmentHPrescribedTSkySpecified:
    var Outdoor: CEnvironment
    var m_TarcogSystem: CSingleSystem

    def __init__(inout self):
        self.Outdoor = CEnvironment()
        self.m_TarcogSystem = CSingleSystem()
        self.SetUp()

    def SetUp(inout self):
        let airTemperature = 300.0   # Kelvins
        let airSpeed = 5.5           # meters per second
        let tSky = 270.0             # Kelvins
        let solarRadiation = 0.0
        let hout = 20.0
        self.Outdoor = Environments.outdoor(airTemperature,
                                              airSpeed,
                                              solarRadiation,
                                              tSky,
                                              SkyModel.TSkySpecified)
        assert self.Outdoor != None
        self.Outdoor.setHCoeffModel(BoundaryConditionsCoeffModel.HPrescribed, hout)
        let roomTemperature = 294.15
        let Indoor = Environments.indoor(roomTemperature)
        assert Indoor != None
        let solidLayerThickness = 0.003048   # [m]
        let solidLayerConductance = 100.0
        let aSolidLayer = Layers.solid(solidLayerThickness, solidLayerConductance)
        assert aSolidLayer != None
        let windowWidth = 1.0
        let windowHeight = 1.0
        let aIGU = CIGU(windowWidth, windowHeight)
        aIGU.addLayer(aSolidLayer)
        self.m_TarcogSystem = CSingleSystem(aIGU, Indoor, self.Outdoor)
        self.m_TarcogSystem.solve()
        assert self.m_TarcogSystem != None

    def GetOutdoors(self) -> CEnvironment:
        return self.Outdoor

def test_CalculateH_TSkySpecified():
    print("Begin Test: Outdoors -> H model = Prescribed; Sky Model = TSky specified")
    let fixture = TestOutdoorEnvironmentHPrescribedTSkySpecified()
    let aOutdoor = fixture.GetOutdoors()
    assert aOutdoor != None
    let radiosity = aOutdoor.getEnvironmentIR()
    assert abs(459.2457 - radiosity) < 1e-5
    let hc = aOutdoor.getHc()
    assert abs(14.895502 - hc) < 1e-5
    let outIR = aOutdoor.getRadiationFlow()
    assert abs(-7.777658 - outIR) < 1e-5
    let outConvection = aOutdoor.getConvectionConductionFlow()
    assert abs(-22.696083 - outConvection) < 1e-5
    let totalHeatFlow = aOutdoor.getHeatFlow()
    assert abs(-30.473740 - totalHeatFlow) < 1e-5

def main():
    test_CalculateH_TSkySpecified()
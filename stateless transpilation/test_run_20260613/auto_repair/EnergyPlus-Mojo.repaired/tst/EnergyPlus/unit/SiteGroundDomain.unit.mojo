from EnergyPlus.PlantPipingSystemsManager import GroundTemp, GroundTempModelType, PlantPipingSysMgr
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string


def SiteGroundDomainSlabAndBasementModelsIndexChecking(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
        "KA1,						!- Name of object",
        "1.8,						!- Soil Thermal Conductivity {W/m-K}",
        "3200,						!- Soil Density {kg/m3}",
        "836,						!- Soil Specific Heat {J/kg-K}",
        "15.5,						!- Annual average surface temperature {C}",
        "12.8,						!- Annual amplitude of surface temperature {delta C}",
        "17.3;						!- Phase shift of minimum surface temperature {days}",
        "Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
        "KA2,						!- Name of object",
        "1.8,						!- Soil Thermal Conductivity {W/m-K}",
        "3200,						!- Soil Density {kg/m3}",
        "836,						!- Soil Specific Heat {J/kg-K}",
        "15.5,						!- Annual average surface temperature {C}",
        "12.8,						!- Annual amplitude of surface temperature {delta C}",
        "17.3;						!- Phase shift of minimum surface temperature {days}",
    ])
    assert process_idf(idf_objects), "process_idf returned false"
    self.state[].dataPlantPipingSysMgr.domains.resize(2)
    self.state[].dataPlantPipingSysMgr.domains[0].groundTempModel = GroundTemp.GetGroundTempModelAndInit(self.state[], GroundTemp.ModelType.Kusuda, "KA1")
    self.state[].dataPlantPipingSysMgr.domains[1].groundTempModel = GroundTemp.GetGroundTempModelAndInit(self.state[], GroundTemp.ModelType.Kusuda, "KA2")
    assert self.state[].dataPlantPipingSysMgr.domains[0].groundTempModel != self.state[].dataPlantPipingSysMgr.domains[1].groundTempModel
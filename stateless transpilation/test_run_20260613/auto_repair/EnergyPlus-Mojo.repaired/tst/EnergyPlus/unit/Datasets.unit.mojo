from testing import @test, assert_true
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, read_lines_in_file, delimited_string
from EnergyPlus.ConfiguredFunctions import configured_source_directory
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData

alias DataSetFixture = EnergyPlusFixture

@test
def AirCooledChiller():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/AirCooledChiller.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def ASHRAE_2005_HOF_Materials():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/ASHRAE_2005_HOF_Materials.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def Boilers():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/Boilers.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def California_Title_24_2008():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/California_Title_24-2008.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def Chillers():
    var fixture = DataSetFixture()
    fixture.state.dataGlobal.preserveIDFOrder = False
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/Chillers.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def CompositeWallConstructions():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/CompositeWallConstructions.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def DXCoolingCoil():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/DXCoolingCoil.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def ElectricGenerators():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/ElectricGenerators.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def ElectricityUSAEnvironmentalImpactFactors():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/ElectricityUSAEnvironmentalImpactFactors.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def ElectronicEnthalpyEconomizerCurves():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/ElectronicEnthalpyEconomizerCurves.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def ExhaustFiredChiller():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/ExhaustFiredChiller.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def FluidPropertiesRefData():
    var fixture = DataSetFixture()
    fixture.state.dataGlobal.preserveIDFOrder = False
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/FluidPropertiesRefData.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def FossilFuelEnvironmentalImpactFactors():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/FossilFuelEnvironmentalImpactFactors.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def GLHERefData():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/GLHERefData.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def GlycolPropertiesRefData():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/GlycolPropertiesRefData.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2012():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2012.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2013():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2013.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2014():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2014.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2015():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2015.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2016():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2016.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2017():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2017.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2018():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2018.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2019():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2019.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2020():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2020.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2021():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2021.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def LCCusePriceEscalationDataSet2022():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/LCCusePriceEscalationDataSet2022.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def MoistureMaterials():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/MoistureMaterials.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def PerfCurves():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/PerfCurves.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def PrecipitationSchedulesUSA():
    var fixture = DataSetFixture()
    fixture.state.dataGlobal.preserveIDFOrder = False
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/PrecipitationSchedulesUSA.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def RefrigerationCasesDataSet():
    var fixture = DataSetFixture()
    fixture.state.dataGlobal.preserveIDFOrder = False
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/RefrigerationCasesDataSet.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def ResidentialACsAndHPsPerfCurves():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/ResidentialACsAndHPsPerfCurves.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def RooftopPackagedHeatPump():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/RooftopPackagedHeatPump.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def SandiaPVdata():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/SandiaPVdata.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def Schedules():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/Schedules.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def SolarCollectors():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/SolarCollectors.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def StandardReports():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/StandardReports.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def SurfaceColorSchemes():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/SurfaceColorSchemes.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def USHolidays_DST():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/USHolidays-DST.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def WaterToAirHeatPumps():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/WaterToAirHeatPumps.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def WindowBlindMaterials():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/WindowBlindMaterials.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def WindowConstructs():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/WindowConstructs.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def WindowGasMaterials():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/WindowGasMaterials.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def WindowGlassMaterials():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/WindowGlassMaterials.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def WindowScreenMaterials():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/WindowScreenMaterials.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def WindowShadeMaterials():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/WindowShadeMaterials.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))

@test
def CodeCompliantEquipmentDataset():
    var srcDir = configured_source_directory()
    var path = srcDir + "/datasets/CodeCompliantEquipment.idf"
    assert_true(process_idf(delimited_string(read_lines_in_file(path))))
<<<FILE>>>
# TODO: Port EnergyPlusFixture to Mojo testing framework
# TODO: Port process_idf, delimited_string, compare_err_stream, has_err_output to Mojo

from gtest import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Coils.CoilCoolingDX import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.IOFiles import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimAirServingZones import *
from EnergyPlus.UnitarySystem import *
from EnergyPlus.VariableSpeedCoils import *

def test_VariableSpeedCoils_DOASDXCoilTest():
    # TODO: Implement test with EnergyPlusFixture

def test_VariableSpeedCoils_RHControl():
    # TODO: Implement test with EnergyPlusFixture

def test_VariableSpeedCoils_LatentDegradation_Test():
    # TODO: Implement test with EnergyPlusFixture

def test_NewDXCoilModel_RHControl():
    # TODO: Implement test with EnergyPlusFixture

from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData as Data
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataPhotovoltaics import DataPhotovoltaics
from EnergyPlus.DataSurfaces import DataSurfaces
from EnergyPlus.Photovoltaics import Photovoltaics as PV

def PV_Sandia_AirMassAtHighZenith():
    var zenithAngleDeg: Float64 = 90.0
    var altitude: Float64 = 1
    var airMass: Float64 = PV.AbsoluteAirMass(zenithAngleDeg, altitude)
    assert airMass != 999  # would have been true before fix
    assert abs(airMass - 36.31531) < 0.1
    zenithAngleDeg = 89.0
    airMass = PV.AbsoluteAirMass(zenithAngleDeg, altitude)
    assert abs(airMass - 26.24135) < 0.1

def PV_ReportPV_ZoneIndexNonZero():
    state.dataPhotovoltaic.PVarray = []
    state.dataHeatBal.Zone = []
    state.dataSurface.Surface = []
    state.dataPhotovoltaic.PVarray = [None] * 3
    state.dataHeatBal.Zone = [None] * 2
    state.dataSurface.Surface = [None] * 3
    state.dataGlobal.NumOfZones = 2
    state.dataHeatBal.Zone[0].Name = "Zone1"
    state.dataHeatBal.Zone[0].ListMultiplier = 1.0
    state.dataHeatBal.Zone[0].Multiplier = 5.0
    state.dataHeatBal.Zone[1].Name = "Zone2"
    state.dataHeatBal.Zone[1].ListMultiplier = 10.0
    state.dataHeatBal.Zone[1].Multiplier = 1.0
    state.dataPhotovoltaic.NumPVs = 3
    state.dataPhotovoltaic.PVarray[0].SurfacePtr = 1
    state.dataPhotovoltaic.PVarray[0].CellIntegrationMode = DataPhotovoltaics.CellIntegration.Invalid
    state.dataPhotovoltaic.PVarray[1].SurfacePtr = 2
    state.dataPhotovoltaic.PVarray[1].CellIntegrationMode = DataPhotovoltaics.CellIntegration.Invalid
    state.dataPhotovoltaic.PVarray[2].SurfacePtr = 3
    state.dataPhotovoltaic.PVarray[2].CellIntegrationMode = DataPhotovoltaics.CellIntegration.Invalid
    state.dataSurface.Surface[0].Zone = 1
    state.dataSurface.Surface[0].ZoneName = "Zone1"
    state.dataSurface.Surface[1].Zone = 0
    state.dataSurface.Surface[1].ZoneName = "Zone2"
    state.dataSurface.Surface[2].Zone = 0
    state.dataSurface.Surface[2].ZoneName = "None"
    state.dataPhotovoltaic.PVarray[0].Report.DCPower = 1000.0
    state.dataPhotovoltaic.PVarray[0].Zone = PV.GetPVZone(state, state.dataPhotovoltaic.PVarray[0].SurfacePtr)
    PV.ReportPV(state, 1)
    assert state.dataPhotovoltaic.PVarray[0].Zone == 1
    assert abs(state.dataPhotovoltaic.PVarray[0].Report.DCPower - 5000.0) < 0.1
    state.dataPhotovoltaic.PVarray[1].Report.DCPower = 1000.0
    state.dataPhotovoltaic.PVarray[1].Zone = PV.GetPVZone(state, state.dataPhotovoltaic.PVarray[1].SurfacePtr)
    PV.ReportPV(state, 2)
    assert state.dataPhotovoltaic.PVarray[1].Zone == 2
    assert abs(state.dataPhotovoltaic.PVarray[1].Report.DCPower - 10000.0) < 0.1
    state.dataPhotovoltaic.PVarray[2].Report.DCPower = 1000.0
    state.dataPhotovoltaic.PVarray[2].Zone = PV.GetPVZone(state, state.dataPhotovoltaic.PVarray[2].SurfacePtr)
    PV.ReportPV(state, 3)
    assert state.dataPhotovoltaic.PVarray[2].Zone == 0
    assert abs(state.dataPhotovoltaic.PVarray[2].Report.DCPower - 1000.0) < 0.1
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataSizing import AutoSize
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.Pumps import Pumps
from EnergyPlus.SizingManager import SizingManager
from EnergyPlus.Fluid import Fluid
from Testing import expect_near, expect_eq, assert_true, compare_err_stream

def delimited_string(lines: List[String]) -> String:
    var result = ""
    for i in range(len(lines)):
        if i > 0:
            result += "\n"
        result += lines[i]
    return result

@namespace("EnergyPlus")
def HeaderedVariableSpeedPumpSizingPowerTest(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "HeaderedPumps:VariableSpeed,",
        "Chilled Water Headered Pumps,  !- Name",
        "CW Supply Inlet Node,    !- Inlet Node Name",
        "CW Pumps Outlet Node,    !- Outlet Node Name",
        "0.001,                   !- Total Design Flow Rate {m3/s}",
        "2,                       !- Number of Pumps in Bank",
        "SEQUENTIAL,              !- Flow Sequencing Control Scheme",
        "100000,                  !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "0.1,                     !- Minimum Flow Rate Fraction",
        "INTERMITTENT,            !- Pump Control Type",
        "CoolingPumpAvailSched,   !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlowPerPressure, !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        "1.3,                     !- Design Shaft Power per Unit Flow Rate per Unit Head",
        "Pump Energy;             !- End-Use Subcategory",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 162.5, 0.0001)
    expect_eq(self.state.dataPumps.PumpEquip[0].EndUseSubcategoryName, "Pump Energy")

@namespace("EnergyPlus")
def HeaderedVariableSpeedPumpSizingPower22W_per_gpm(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "HeaderedPumps:VariableSpeed,",
        "Chilled Water Headered Pumps,  !- Name",
        "CW Supply Inlet Node,    !- Inlet Node Name",
        "CW Pumps Outlet Node,    !- Outlet Node Name",
        "0.001,                   !- Total Design Flow Rate {m3/s}",
        "2,                       !- Number of Pumps in Bank",
        "SEQUENTIAL,              !- Flow Sequencing Control Scheme",
        "100000,                  !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "0.1,                     !- Minimum Flow Rate Fraction",
        "INTERMITTENT,            !- Pump Control Type",
        "CoolingPumpAvailSched,   !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlow,            !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        ";                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 348.7011, 0.0001)

@namespace("EnergyPlus")
def HeaderedVariableSpeedPumpSizingPowerDefault(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "HeaderedPumps:VariableSpeed,",
        "Chilled Water Headered Pumps,  !- Name",
        "CW Supply Inlet Node,    !- Inlet Node Name",
        "CW Pumps Outlet Node,    !- Outlet Node Name",
        "0.001,                   !- Total Design Flow Rate {m3/s}",
        "2,                       !- Number of Pumps in Bank",
        "SEQUENTIAL,              !- Flow Sequencing Control Scheme",
        ",                        !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        ",                        !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "0.1,                     !- Minimum Flow Rate Fraction",
        "INTERMITTENT,            !- Pump Control Type",
        "CoolingPumpAvailSched,   !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        ",                        !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        ";                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 255.4872, 0.0001)

@namespace("EnergyPlus")
def HeaderedConstantSpeedPumpSizingPowerTest(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "HeaderedPumps:ConstantSpeed,",
        "Chilled Water Headered Pumps,  !- Name",
        "CW Supply Inlet Node,    !- Inlet Node Name",
        "CW Pumps Outlet Node,    !- Outlet Node Name",
        "0.001,                   !- Total Design Flow Rate {m3/s}",
        "2,                       !- Number of Pumps in Bank",
        "SEQUENTIAL,              !- Flow Sequencing Control Scheme",
        "100000,                  !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "INTERMITTENT,            !- Pump Control Type",
        "CoolingPumpAvailSched,   !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlowPerPressure, !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        "1.3,                     !- Design Shaft Power per Unit Flow Rate per Unit Head",
        "Pump Energy;             !- End-Use Subcategory",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 162.5, 0.0001)
    expect_eq(self.state.dataPumps.PumpEquip[0].EndUseSubcategoryName, "Pump Energy")

@namespace("EnergyPlus")
def HeaderedConstantSpeedPumpSizingPower19W_per_gpm(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "HeaderedPumps:ConstantSpeed,",
        "Chilled Water Headered Pumps,  !- Name",
        "CW Supply Inlet Node,    !- Inlet Node Name",
        "CW Pumps Outlet Node,    !- Outlet Node Name",
        "0.001,                   !- Total Design Flow Rate {m3/s}",
        "2,                       !- Number of Pumps in Bank",
        "SEQUENTIAL,              !- Flow Sequencing Control Scheme",
        ",                        !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        ",                        !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "INTERMITTENT,            !- Pump Control Type",
        "CoolingPumpAvailSched,   !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlow,            !- Design Power Sizing Method",
        "301156.1,                !- Design Electric Power per Unit Flow Rate",
        ";                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 301.1561, 0.0001)

@namespace("EnergyPlus")
def HeaderedConstantSpeedPumpSizingPowerDefault(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "HeaderedPumps:ConstantSpeed,",
        "Chilled Water Headered Pumps,  !- Name",
        "CW Supply Inlet Node,    !- Inlet Node Name",
        "CW Pumps Outlet Node,    !- Outlet Node Name",
        "0.001,                   !- Total Design Flow Rate {m3/s}",
        "2,                       !- Number of Pumps in Bank",
        "SEQUENTIAL,              !- Flow Sequencing Control Scheme",
        ",                        !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        ",                        !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "INTERMITTENT,            !- Pump Control Type",
        "CoolingPumpAvailSched,   !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        ",                        !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        ";                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 255.4872, 0.0001)

@namespace("EnergyPlus")
def VariableSpeedPumpSizingMinVolFlowRate(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed,",
        "CoolSys1 Pump,           !- Name",
        "CoolSys1 Supply Inlet Node,  !- Inlet Node Name",
        "CoolSys1 Pump-CoolSys1 ChillerNodeviaConnector,  !- Outlet Node Name",
        "0.001,                !- Design Flow Rate {m3/s}",
        "100000,                  !- Design Pump Head {Pa}",
        "AUTOSIZE,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "autosize,                !- Minimum Flow Rate {m3/s}",
        "Intermittent,            !- Pump Control Type",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Pump Curve Name",
        ",                        !- Impeller Diameter",
        ",                        !- VFD Control Type",
        ",                        !- Pump rpm Schedule Name",
        ",                        !- Minimum Pressure Schedule",
        ",                        !- Maximum Pressure Schedule",
        ",                        !- Minimum RPM Schedule",
        ",                        !- Maximum RPM Schedule",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlowPerPressure, !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        "1.3,                     !- Design Shaft Power per Unit Flow Rate per Unit Head",
        "0.3,                     !- Design Minimum Flow Rate Sizing Factor",
        "Pump Energy;             !- End-Use Subcategory",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    expect_near(self.state.dataPumps.PumpEquip[0].MinVolFlowRate, AutoSize, 0.000001)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].MinVolFlowRate, 0.0003, 0.00001)
    expect_eq(self.state.dataPumps.PumpEquip[0].EndUseSubcategoryName, "Pump Energy")

@namespace("EnergyPlus")
def VariableSpeedPumpSizingPowerPerPressureTest(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed,",
        "CoolSys1 Pump,           !- Name",
        "CoolSys1 Supply Inlet Node,  !- Inlet Node Name",
        "CoolSys1 Pump-CoolSys1 ChillerNodeviaConnector,  !- Outlet Node Name",
        "0.001,                !- Design Flow Rate {m3/s}",
        "100000,                  !- Design Pump Head {Pa}",
        "AUTOSIZE,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "autosize,                !- Minimum Flow Rate {m3/s}",
        "Intermittent,            !- Pump Control Type",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Pump Curve Name",
        ",                        !- Impeller Diameter",
        ",                        !- VFD Control Type",
        ",                        !- Pump rpm Schedule Name",
        ",                        !- Minimum Pressure Schedule",
        ",                        !- Maximum Pressure Schedule",
        ",                        !- Minimum RPM Schedule",
        ",                        !- Maximum RPM Schedule",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlowPerPressure, !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        "1.3,                     !- Design Shaft Power per Unit Flow Rate per Unit Head",
        ";                        !- Design Minimum Flow Rate Sizing Factor",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 162.5, 0.0001)

@namespace("EnergyPlus")
def VariableSpeedPumpSizingPowerDefault(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed,",
        "CoolSys1 Pump,           !- Name",
        "CoolSys1 Supply Inlet Node,  !- Inlet Node Name",
        "CoolSys1 Pump-CoolSys1 ChillerNodeviaConnector,  !- Outlet Node Name",
        "0.001,                   !- Design Flow Rate {m3/s}",
        ",                        !- Design Pump Head {Pa}",
        "AUTOSIZE,                !- Design Power Consumption {W}",
        ",                        !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "autosize,                !- Minimum Flow Rate {m3/s}",
        "Intermittent,            !- Pump Control Type",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Pump Curve Name",
        ",                        !- Impeller Diameter",
        ",                        !- VFD Control Type",
        ",                        !- Pump rpm Schedule Name",
        ",                        !- Minimum Pressure Schedule",
        ",                        !- Maximum Pressure Schedule",
        ",                        !- Minimum RPM Schedule",
        ",                        !- Maximum RPM Schedule",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        ",                        !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        ",                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
        ";                        !- Design Minimum Flow Rate Sizing Factor",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 255.4872, 0.0001)

@namespace("EnergyPlus")
def VariableSpeedPumpSizingPower22W_per_GPM(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed,",
        "CoolSys1 Pump,           !- Name",
        "CoolSys1 Supply Inlet Node,  !- Inlet Node Name",
        "CoolSys1 Pump-CoolSys1 ChillerNodeviaConnector,  !- Outlet Node Name",
        "0.001,                   !- Design Flow Rate {m3/s}",
        "179352,                  !- Design Pump Head {Pa}",
        "AUTOSIZE,                !- Design Power Consumption {W}",
        "0.9,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "autosize,                !- Minimum Flow Rate {m3/s}",
        "Intermittent,            !- Pump Control Type",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Pump Curve Name",
        ",                        !- Impeller Diameter",
        ",                        !- VFD Control Type",
        ",                        !- Pump rpm Schedule Name",
        ",                        !- Minimum Pressure Schedule",
        ",                        !- Maximum Pressure Schedule",
        ",                        !- Minimum RPM Schedule",
        ",                        !- Maximum RPM Schedule",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlow,            !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        ",                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
        "0.0;                     !- Design Minimum Flow Rate Sizing Factor",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 348.7011, 0.0001)

@namespace("EnergyPlus")
def ConstantSpeedPumpSizingPower19W_per_gpm(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:ConstantSpeed,",
        "TowerWaterSys Pump,      !- Name",
        "TowerWaterSys Supply Inlet Node,  !- Inlet Node Name",
        "TowerWaterSys Pump-TowerWaterSys CoolTowerNodeviaConnector,  !- Outlet Node Name",
        "0.001,                   !- Design Flow Rate {m3/s}",
        "179352,                  !- Design Pump Head {Pa}",
        "AUTOSIZE,                !- Design Power Consumption {W}",
        "0.87,                    !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "Intermittent,            !- Pump Control Type",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Pump Curve Name",
        ",                        !- Impeller Diameter",
        ",                        !- Rotational Speed",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlow,            !- Design Power Sizing Method",
        "301156.1,                !- Design Electric Power per Unit Flow Rate",
        ",                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
        "Pump Energy;             !- End-Use Subcategory",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 301.1561, 0.0001)
    expect_eq(self.state.dataPumps.PumpEquip[0].EndUseSubcategoryName, "Pump Energy")

@namespace("EnergyPlus")
def ConstantSpeedPumpSizingPowerPerPressureTest(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:ConstantSpeed,",
        "TowerWaterSys Pump,      !- Name",
        "TowerWaterSys Supply Inlet Node,  !- Inlet Node Name",
        "TowerWaterSys Pump-TowerWaterSys CoolTowerNodeviaConnector,  !- Outlet Node Name",
        "0.001,                   !- Design Flow Rate {m3/s}",
        "100000,                  !- Design Pump Head {Pa}",
        "AUTOSIZE,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "Intermittent,            !- Pump Control Type",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Pump Curve Name",
        ",                        !- Impeller Diameter",
        ",                        !- Rotational Speed",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlowPerPressure, !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        "1.3;                     !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 162.5, 0.0001)

@namespace("EnergyPlus")
def ConstantSpeedPumpSizingPowerDefaults(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:ConstantSpeed,",
        "TowerWaterSys Pump,      !- Name",
        "TowerWaterSys Supply Inlet Node,  !- Inlet Node Name",
        "TowerWaterSys Pump-TowerWaterSys CoolTowerNodeviaConnector,  !- Outlet Node Name",
        "0.001,                   !- Design Flow Rate {m3/s}",
        ",                        !- Design Pump Head {Pa}",
        "AUTOSIZE,                !- Design Power Consumption {W}",
        ",                        !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "Intermittent,            !- Pump Control Type",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Pump Curve Name",
        ",                        !- Impeller Diameter",
        ",                        !- Rotational Speed",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        ",                        !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        ";                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 255.4872, 0.0001)

@namespace("EnergyPlus")
def CondensatePumpSizingPowerDefaults(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed:Condensate,",
        "Steam Boiler Plant Steam Circ Pump,  !- Name",
        "Steam Boiler Plant Steam Supply Inlet Node,  !- Inlet Node Name",
        "Steam Boiler Plant Steam Pump Outlet Node,  !- Outlet Node Name",
        "1.0,                     !- Design Flow Rate {m3/s}",
        ",                        !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        ",                        !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        ",                        !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        ",                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
        "Pump Energy;             !- End-Use Subcategory",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 153.3, 0.1)
    expect_eq(self.state.dataPumps.PumpEquip[0].EndUseSubcategoryName, "Pump Energy")

@namespace("EnergyPlus")
def CondensatePumpSizingPower19W_per_gpm(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed:Condensate,",
        "Steam Boiler Plant Steam Circ Pump,  !- Name",
        "Steam Boiler Plant Steam Supply Inlet Node,  !- Inlet Node Name",
        "Steam Boiler Plant Steam Pump Outlet Node,  !- Outlet Node Name",
        "1.0,                     !- Design Flow Rate {m3/s}",
        "179352,                  !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        "0.9,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlow,            !- Design Power Sizing Method",
        "301156.1,                !- Design Electric Power per Unit Flow Rate",
        ";                        !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 180.7, 0.1)

@namespace("EnergyPlus")
def CondensatePumpSizingPowerTest(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed:Condensate,",
        "Steam Boiler Plant Steam Circ Pump,  !- Name",
        "Steam Boiler Plant Steam Supply Inlet Node,  !- Inlet Node Name",
        "Steam Boiler Plant Steam Pump Outlet Node,  !- Outlet Node Name",
        "1.0,                     !- Design Flow Rate {m3/s}",
        "100000,                  !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        ",                        !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlowPerPressure, !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        "1.3;                     !- Design Shaft Power per Unit Flow Rate per Unit Head",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    expect_near(self.state.dataPumps.PumpEquip[0].NomPowerUse, 97.5, 0.1)

@namespace("EnergyPlus")
def VariableSpeedPump_MinFlowGreaterThanMax(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed,",
        "  supply inlet pump,       !- Name",
        "  Node supply inlet in,    !- Inlet Node Name",
        "  Node supply inlet out,   !- Outlet Node Name",
        "  0.001,                   !- Design Maximum Flow Rate {m3/s}",
        "  1793520,                 !- Design Pump Head {Pa}",
        "  2237,                    !- Design Power Consumption {W}",
        "  0.9,                     !- Motor Efficiency",
        "  ,                        !- Fraction of Motor Inefficiencies to Fluid Stream",
        "  ,                        !- Coefficient 1 of the Part Load Performance Curve",
        "  1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "  ,                        !- Coefficient 3 of the Part Load Performance Curve",
        "  ,                        !- Coefficient 4 of the Part Load Performance Curve",
        "  0.002,                   !- Design Minimum Flow Rate {m3/s}",
        "  Continuous,              !- Pump Control Type",
        "  ,                        !- Pump Flow Rate Schedule Name",
        "  ,                        !- Pump Curve Name",
        "  ,                        !- Impeller Diameter {m}",
        "  ,                        !- VFD Control Type",
        "  ,                        !- Pump rpm Schedule Name",
        "  ,                        !- Minimum Pressure Schedule",
        "  ,                        !- Maximum Pressure Schedule",
        "  ,                        !- Minimum RPM Schedule",
        "  ,                        !- Maximum RPM Schedule",
        "  ,                        !- Zone Name",
        "  ,                        !- Skin Loss Radiative Fraction",
        "  PowerPerFlowPerPressure, !- Design Power Sizing Method",
        "  348701.1,                !- Design Electric Power per Unit Flow Rate {W/(m3/s)}",
        "  1.282051282,             !- Design Shaft Power per Unit Flow Rate per Unit Head {W/((m3/s)-Pa)}",
        "  ;                        !- Design Minimum Flow Rate Fraction",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    var error_string: String = delimited_string([
        "   ** Warning ** GetPumpInput: Pump:VariableSpeed=\"SUPPLY INLET PUMP\", Invalid 'Design Minimum Flow Rate'",
        "   **   ~~~   ** Entered Value=[0.00200] is above or too close (equal) to the Design Maximum Flow Rate=[0.00100].",
        "   **   ~~~   ** Resetting value of 'Design Minimum Flow Rate' to the value of 99% of 'Design Maximum Flow Rate'.",
    ])
    expect_true(self.compare_err_stream(error_string, true))
    expect_near(self.state.dataPumps.PumpEquip[0].MinVolFlowRate, 0.001 * 0.99, 0.00001)

@namespace("EnergyPlus")
def VariableSpeedPump_MinFlowEqualToMax(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "Pump:VariableSpeed,",
        "  supply inlet pump,       !- Name",
        "  Node supply inlet in,    !- Inlet Node Name",
        "  Node supply inlet out,   !- Outlet Node Name",
        "  0.001,                   !- Design Maximum Flow Rate {m3/s}",
        "  1793520,                 !- Design Pump Head {Pa}",
        "  2237,                    !- Design Power Consumption {W}",
        "  0.9,                     !- Motor Efficiency",
        "  ,                        !- Fraction of Motor Inefficiencies to Fluid Stream",
        "  ,                        !- Coefficient 1 of the Part Load Performance Curve",
        "  1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "  ,                        !- Coefficient 3 of the Part Load Performance Curve",
        "  ,                        !- Coefficient 4 of the Part Load Performance Curve",
        "  0.000995,                !- Design Minimum Flow Rate {m3/s}",
        "  Intermittent,            !- Pump Control Type",
        "  ,                        !- Pump Flow Rate Schedule Name",
        "  ,                        !- Pump Curve Name",
        "  ,                        !- Impeller Diameter {m}",
        "  ,                        !- VFD Control Type",
        "  ,                        !- Pump rpm Schedule Name",
        "  ,                        !- Minimum Pressure Schedule",
        "  ,                        !- Maximum Pressure Schedule",
        "  ,                        !- Minimum RPM Schedule",
        "  ,                        !- Maximum RPM Schedule",
        "  ,                        !- Zone Name",
        "  ,                        !- Skin Loss Radiative Fraction",
        "  PowerPerFlowPerPressure, !- Design Power Sizing Method",
        "  348701.1,                !- Design Electric Power per Unit Flow Rate {W/(m3/s)}",
        "  1.282051282,             !- Design Shaft Power per Unit Flow Rate per Unit Head {W/((m3/s)-Pa)}",
        "  ;                        !- Design Minimum Flow Rate Fraction",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    Pumps.GetPumpInput(self.state)
    var error_string: String = delimited_string([
        "   ** Warning ** GetPumpInput: Pump:VariableSpeed=\"SUPPLY INLET PUMP\", Invalid 'Design Minimum Flow Rate'",
        "   **   ~~~   ** Entered Value=[0.00100] is above or too close (equal) to the Design Maximum Flow Rate=[0.00100].",
        "   **   ~~~   ** Resetting value of 'Design Minimum Flow Rate' to the value of 99% of 'Design Maximum Flow Rate'.",
    ])
    expect_true(self.compare_err_stream(error_string, true))
    var expectedAnswer: Float64 = 0.99 * 0.001
    let allowableTolerance: Float64 = 0.00001
    expect_near(self.state.dataPumps.PumpEquip[0].MinVolFlowRate, expectedAnswer, allowableTolerance)
    expectedAnswer = 0.001
    expect_near(self.state.dataPumps.PumpEquip[0].NomVolFlowRate, expectedAnswer, allowableTolerance)

@namespace("EnergyPlus")
def HeaderedVariableSpeedPumpEMSPressureTest(self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "HeaderedPumps:VariableSpeed,",
        "Chilled Water Headered Pumps,  !- Name",
        "CW Supply Inlet Node,    !- Inlet Node Name",
        "CW Pumps Outlet Node,    !- Outlet Node Name",
        "0.001,                   !- Total Design Flow Rate {m3/s}",
        "2,                       !- Number of Pumps in Bank",
        "SEQUENTIAL,              !- Flow Sequencing Control Scheme",
        "100000,                  !- Design Pump Head {Pa}",
        "autosize,                !- Design Power Consumption {W}",
        "0.8,                     !- Motor Efficiency",
        "0.0,                     !- Fraction of Motor Inefficiencies to Fluid Stream",
        "0,                       !- Coefficient 1 of the Part Load Performance Curve",
        "1,                       !- Coefficient 2 of the Part Load Performance Curve",
        "0,                       !- Coefficient 3 of the Part Load Performance Curve",
        "0,                       !- Coefficient 4 of the Part Load Performance Curve",
        "0.1,                     !- Minimum Flow Rate Fraction",
        "INTERMITTENT,            !- Pump Control Type",
        "CoolingPumpAvailSched,   !- Pump Flow Rate Schedule Name",
        ",                        !- Zone Name",
        ",                        !- Skin Loss Radiative Fraction",
        "PowerPerFlowPerPressure, !- Design Power Sizing Method",
        ",                        !- Design Electric Power per Unit Flow Rate",
        "1.3,                     !- Design Shaft Power per Unit Flow Rate per Unit Head",
        "Pump Energy;             !- End-Use Subcategory",
    ])
    assert_true(self.process_idf(idf_objects))
    self.state.init_state(self.state)
    var thisBranchNum: Int = 1
    var thisLoopSideNum: DataPlant.LoopSideLocation = DataPlant.LoopSideLocation.Supply
    self.state.dataPlnt.PlantLoop.allocate(1)
    self.state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    self.state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(self.state)
    self.state.dataPlnt.PlantLoop[0].LoopSide[thisLoopSideNum.value()].Branch.allocate(1)
    self.state.dataPlnt.PlantLoop[0].LoopSide[thisLoopSideNum.value()].Branch[thisBranchNum - 1].Comp.allocate(1)
    Pumps.GetPumpInput(self.state)
    Pumps.SizePump(self.state, 1)
    let massflowrate: Float64 = 1.0
    self.state.dataPumps.PumpEquip[0].EMSPressureOverrideOn = True
    self.state.dataPumps.PumpEquip[0].plantLoc.loopSideNum = DataPlant.LoopSideLocation.Supply
    self.state.dataPumps.PumpEquip[0].plantLoc.loopNum = 1
    self.state.dataPumps.PumpEquip[0].plantLoc.branchNum = 1
    self.state.dataPumps.PumpEquip[0].plantLoc.compNum = 1
    PlantUtilities.SetPlantLocationLinks(self.state, self.state.dataPumps.PumpEquip[0].plantLoc)
    self.state.dataPumps.PumpEquip[0].MassFlowRateMax = massflowrate
    var PumpRunning: Bool = True
    self.state.dataLoopNodes.Node[0].MassFlowRate = massflowrate
    self.state.dataLoopNodes.Node[0].MassFlowRateMinAvail = massflowrate
    self.state.dataLoopNodes.Node[0].MassFlowRateMin = massflowrate
    self.state.dataLoopNodes.Node[0].MassFlowRateMax = massflowrate
    self.state.dataLoopNodes.Node[1].MassFlowRateMaxAvail = massflowrate
    self.state.dataLoopNodes.Node[0].MassFlowRateMaxAvail = massflowrate
    self.state.dataPumps.PumpEquip[0].PumpEffic = 0.8
    self.state.dataPumps.PumpEquip[0].EMSPressureOverrideValue = 200.0
    Pumps.CalcPumps(self.state, 1, massflowrate, PumpRunning)
    expect_near(self.state.dataPumps.PumpEquip[0].Power, 0.1563, 0.0001)
<<<FILE>>>
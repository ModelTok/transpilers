from gtest import Test, TestFixture, ExpectEq, ExpectNear
from EnergyPlus.ChilledCeilingPanelSimple import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.ZoneTempPredictorCorrector import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
namespace EnergyPlus:

    @TestFixture
    class SetCoolingPanelControlTemp(EnergyPlusFixture):
        def run(self):
            var ControlTemp: Float64  # Temperature that is controlling the panel
            var CoolingPanelNum: Int  # Cooling panel number
            var ZoneNum: Int  # Zone number for the cooling panel
            ControlTemp = 0.0
            CoolingPanelNum = 1
            ZoneNum = 1
            self.state.dataChilledCeilingPanelSimple.CoolingPanel.allocate(1)
            self.state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
            self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MAT = 22.0
            self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MRT = 20.0
            self.state.dataHeatBal.Zone.allocate(1)
            self.state.dataHeatBal.Zone[1].OutDryBulbTemp = 10.0
            self.state.dataHeatBal.Zone[1].OutWetBulbTemp = 5.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].controlType = CoolingPanelSimple.ClgPanelCtrlType.MAT
            ControlTemp = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].getCoolingPanelControlTemp(self.state, ZoneNum)
            ExpectEq(ControlTemp, 22.0)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].controlType = CoolingPanelSimple.ClgPanelCtrlType.MRT
            ControlTemp = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].getCoolingPanelControlTemp(self.state, ZoneNum)
            ExpectEq(ControlTemp, 20.0)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].controlType = CoolingPanelSimple.ClgPanelCtrlType.Operative
            ControlTemp = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].getCoolingPanelControlTemp(self.state, ZoneNum)
            ExpectEq(ControlTemp, 21.0)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].controlType = CoolingPanelSimple.ClgPanelCtrlType.ODB
            ControlTemp = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].getCoolingPanelControlTemp(self.state, ZoneNum)
            ExpectEq(ControlTemp, 10.0)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].controlType = CoolingPanelSimple.ClgPanelCtrlType.OWB
            ControlTemp = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].getCoolingPanelControlTemp(self.state, ZoneNum)
            ExpectEq(ControlTemp, 5.0)

    @TestFixture
    class SizeCoolingPanelUA(EnergyPlusFixture):
        def run(self):
            var CoolingPanelNum: Int  # Cooling panel number
            var SizeCoolingPanelUASuccess: Bool
            CoolingPanelNum = 1
            SizeCoolingPanelUASuccess = True
            self.state.dataChilledCeilingPanelSimple.CoolingPanel.allocate(CoolingPanelNum)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterFlowRate = 1.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ScaledCoolingCapacity = 4000.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterTemp = 20.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedZoneAirTemp = 21.0
            SizeCoolingPanelUASuccess = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].SizeCoolingPanelUA(self.state)
            ExpectEq(SizeCoolingPanelUASuccess, True)
            ExpectNear(self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].UA, 14569.0, 1.0)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterFlowRate = 1.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ScaledCoolingCapacity = 4200.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterTemp = 20.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedZoneAirTemp = 21.0
            SizeCoolingPanelUASuccess = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].SizeCoolingPanelUA(self.state)
            ExpectEq(SizeCoolingPanelUASuccess, True)
            ExpectNear(self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].UA, 37947.0, 1.0)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterFlowRate = 1.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ScaledCoolingCapacity = 2000.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterTemp = 20.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedZoneAirTemp = 20.4
            SizeCoolingPanelUASuccess = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].SizeCoolingPanelUA(self.state)
            ExpectEq(SizeCoolingPanelUASuccess, True)
            ExpectNear(self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].UA, 14569.0, 1.0)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterFlowRate = 1.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ScaledCoolingCapacity = 5000.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterTemp = 20.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedZoneAirTemp = 21.0
            SizeCoolingPanelUASuccess = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].SizeCoolingPanelUA(self.state)
            ExpectEq(SizeCoolingPanelUASuccess, False)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterFlowRate = 1.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ScaledCoolingCapacity = 4000.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedWaterTemp = 21.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RatedZoneAirTemp = 20.0
            SizeCoolingPanelUASuccess = self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].SizeCoolingPanelUA(self.state)
            ExpectEq(SizeCoolingPanelUASuccess, False)

    @TestFixture
    class ReportCoolingPanel(EnergyPlusFixture):
        def run(self):
            var CoolingPanelNum: Int  # Cooling panel number
            CoolingPanelNum = 1
            self.state.dataChilledCeilingPanelSimple.CoolingPanel.allocate(CoolingPanelNum)
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].TotPower = -10.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].Power = -9.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ConvPower = -4.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RadPower = -5.0
            self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ReportCoolingPanel(self.state)
            ExpectNear(self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].TotPower, 10.0, 1.0)
            ExpectNear(self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].Power, 9.0, 1.0)
            ExpectNear(self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].ConvPower, 4.0, 1.0)
            ExpectNear(self.state.dataChilledCeilingPanelSimple.CoolingPanel[CoolingPanelNum].RadPower, 5.0, 1.0)
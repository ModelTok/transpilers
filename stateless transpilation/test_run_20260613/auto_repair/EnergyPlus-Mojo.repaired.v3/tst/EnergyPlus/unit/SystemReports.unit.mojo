// Translation from C++ to Mojo, faithful 1:1, no refactoring.
// Assumes test framework providing EXPECT_EQ, EXPECT_NEAR and fixture EnergyPlusFixture.
// import statements correspond to original C++ includes.
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from Data.EnergyPlusData import EnergyPlusData
from DataAirLoop import AirLoopFlow, AirLoopControlInfo
from DataAirSystems import PrimaryAirSystems, Branch, Comp, MeteredVar
from DataDefineEquip import *
from DataEnvironment import StdRhoAir, *? // not all used
from DataGlobalConstants import Constant
from DataHVACGlobals import TimeStepSys, NumPrimaryAirSys
from DataHeatBalance import Zone, ZonePreDefRep, ZnAirRpt, ZoneIntGain
from DataLoopNode import Node
from DataSizing import OARequirements, OAFlowCalcMethod
from DataZoneEquipment import ZoneEquipConfig, ZoneEquipList, ZoneEquipType
from FanCoilUnits import GetFanCoilInputFlag, NumFanCoils, FanCoil
from HVACStandAloneERV import GetERVInputFlag, NumStandAloneERVs, StandAloneERV
from HVACVariableRefrigerantFlow import GetVRFInputFlag, NumVRFTU, VRFTU
from HeatBalanceManager import AllocateHeatBalArrays
from HybridUnitaryAirConditioners import GetInputZoneHybridEvap, NumZoneHybridEvap, ZoneHybridUnitaryAirConditioner
from IOFiles import * // not used
from OutAirNodeManager import * // not used
from OutdoorAirUnit import GetOutdoorAirUnitInputFlag, NumOfOAUnits, OutAirUnit
from PurchasedAirManager import GetPurchAirInputFlag, NumPurchAir, PurchAir
from SystemReports import CalcSystemEnergyUse, ReportSystemEnergyUse, AllocateAndSetUpVentReports, ReportVentilationLoads
from UnitVentilator import GetUnitVentilatorInputFlag, NumOfUnitVents, UnitVent
from UnitarySystem import UnitarySys as UnitarySystems, UnitarySys // ensure import
from WindowAC import GetWindowACInputFlag, WindAC
from ZoneTempPredictorCorrector import InitZoneAirSetPoints

// using namespace lines: not needed with imports above.

energyplus_test: // placeholder for test fixture struct? In C++, TEST_F expands to a method. We'll define top-level functions.

def SeparateGasOutputVariables():
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    state.dataLoopNodes.Node.allocate(2)
    var CompLoadFlag: Bool = False
    var AirLoopNum: Int = 1
    var CompType1: String
    var CompType2: String
    var CompLoad: Float64 = 150.0
    var CompEnergyUse: Float64 = 100.0
    state.dataAirSystemsData.PrimaryAirSystems[0].NumBranches = 1
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch.allocate(1)
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].TotalComponents = 2
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].NodeNumOut = 1
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp.allocate(2)
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "Main Gas Humidifier"
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].TypeOf = "HUMIDIFIER:STEAM:GAS"
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].NodeNumIn = 1
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].NodeNumOut = 1
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].NumMeteredVars = 1
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].MeteredVar.allocate(1)
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].MeteredVar[0].heatOrCool = Constant.HeatOrCool.CoolingOnly
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].MeteredVar[0].curMeterReading = 100.0
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].MeteredVar[0].resource = Constant.eResource.NaturalGas
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].Name = "Main Gas Heating Coil"
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].TypeOf = "COIL:HEATING:DESUPERHEATER"
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].NodeNumIn = 2
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].NodeNumOut = 2
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].NumMeteredVars = 1
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].MeteredVar.allocate(1)
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].MeteredVar[0].heatOrCool = Constant.HeatOrCool.CoolingOnly
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].MeteredVar[0].curMeterReading = 100.0
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].MeteredVar[0].resource = Constant.eResource.NaturalGas
    state.dataLoopNodes.Node[0].MassFlowRate = 1.0
    state.dataLoopNodes.Node[1].MassFlowRate = 1.0
    state.dataSysRpts.SysLoadRepVars.allocate(1)
    CalcSystemEnergyUse(state,
                        CompLoadFlag,
                        AirLoopNum,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].TypeOf,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].MeteredVar[0].resource,
                        CompLoad,
                        CompEnergyUse)
    CalcSystemEnergyUse(state,
                        CompLoadFlag,
                        AirLoopNum,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].TypeOf,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].MeteredVar[0].resource,
                        CompLoad,
                        CompEnergyUse)
    EXPECT_EQ(state.dataSysRpts.SysLoadRepVars[0].HumidNaturalGas, 100)
    EXPECT_EQ(state.dataSysRpts.SysLoadRepVars[0].HCCompNaturalGas, 100)
    ReportSystemEnergyUse(state)
    EXPECT_EQ(state.dataSysRpts.SysLoadRepVars[0].TotNaturalGas, 200)
    state.dataSysRpts.SysLoadRepVars[0].HumidNaturalGas = 0
    state.dataSysRpts.SysLoadRepVars[0].HCCompNaturalGas = 0
    state.dataSysRpts.SysLoadRepVars[0].TotNaturalGas = 0
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].MeteredVar[0].resource = Constant.eResource.Propane
    state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].MeteredVar[0].resource = Constant.eResource.Propane
    CalcSystemEnergyUse(state,
                        CompLoadFlag,
                        AirLoopNum,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].TypeOf,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].MeteredVar[0].resource,
                        CompLoad,
                        CompEnergyUse)
    CalcSystemEnergyUse(state,
                        CompLoadFlag,
                        AirLoopNum,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].TypeOf,
                        state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[1].MeteredVar[0].resource,
                        CompLoad,
                        CompEnergyUse)
    EXPECT_EQ(state.dataSysRpts.SysLoadRepVars[0].HumidPropane, 100)
    EXPECT_EQ(state.dataSysRpts.SysLoadRepVars[0].HCCompPropane, 100)
    ReportSystemEnergyUse(state)
    EXPECT_EQ(state.dataSysRpts.SysLoadRepVars[0].TotPropane, 200)

def ReportVentilationLoads_ZoneEquip():
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataEnvrn.StdRhoAir = 1.2
    state.dataHVACGlobal.NumPrimaryAirSys = 0
    state.dataAirSystemsData.PrimaryAirSystems.allocate(state.dataHVACGlobal.NumPrimaryAirSys)
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.ZonePreDefRep.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.ZnAirRpt.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipList.allocate(state.dataGlobal.NumOfZones)
    HeatBalanceManager.AllocateHeatBalArrays(state)
    SystemReports.AllocateAndSetUpVentReports(state)
    ZoneTempPredictorCorrector.InitZoneAirSetPoints(state)
    state.dataLoopNodes.Node.allocate(20)
    state.dataSize.NumOARequirements = 1
    state.dataSize.OARequirements.allocate(state.dataSize.NumOARequirements)
    state.dataSize.OARequirements[0].OAFlowMethod = DataSizing.OAFlowCalcMethod.Sum
    var expectedVoz: Float64 = 0.0
    state.dataSize.OARequirements[0].OAFlowPerZone = 20
    expectedVoz += state.dataSize.OARequirements[0].OAFlowPerZone
    state.dataSize.OARequirements[0].OAFlowPerArea = 0.5
    state.dataHeatBal.Zone[0].FloorArea = 1000.0
    expectedVoz += state.dataSize.OARequirements[0].OAFlowPerArea * state.dataHeatBal.Zone[0].FloorArea
    state.dataSize.OARequirements[0].OAFlowPerPerson = 0.1
    state.dataHeatBal.ZoneIntGain.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.ZoneIntGain[0].NOFOCC = 100.0
    expectedVoz += state.dataSize.OARequirements[0].OAFlowPerPerson * state.dataHeatBal.ZoneIntGain[0].NOFOCC
    state.dataHeatBal.Zone[0].Multiplier = 2.0
    state.dataHeatBal.Zone[0].ListMultiplier = 10.0
    expectedVoz *= state.dataHeatBal.Zone[0].Multiplier
    expectedVoz *= state.dataHeatBal.Zone[0].ListMultiplier
    state.dataZoneEquip.ZoneEquipConfig[0].IsControlled = true
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneDesignSpecOAIndex = 1
    state.dataHeatBal.Zone[0].Volume = 10.0
    state.dataZoneEquip.ZoneEquipConfig[0].EquipListIndex = 1
    var NumEquip1: Int = 9
    state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes = NumEquip1
    state.dataZoneEquip.ZoneEquipList[0].EquipType.allocate(NumEquip1)
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex.allocate(NumEquip1)
    var equipNum: Int = 1
    var nodeNumOA: Int = 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.WindowAirConditioner
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataWindowAC.GetWindowACInputFlag = false
    state.dataWindowAC.WindAC.allocate(1)
    state.dataWindowAC.WindAC[0].OutsideAirNode = nodeNumOA
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 0.1
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.VariableRefrigerantFlowTerminal
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataHVACVarRefFlow.GetVRFInputFlag = false
    state.dataHVACVarRefFlow.NumVRFTU = 1
    state.dataHVACVarRefFlow.VRFTU.allocate(1)
    state.dataHVACVarRefFlow.VRFTU[0].VRFTUOAMixerOANodeNum = nodeNumOA
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 2.0
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.PackagedTerminalAirConditioner
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    var thisSys: UnitarySystems.UnitarySys = UnitarySystems.UnitarySys{}
    thisSys.m_OAMixerNodes[0] = nodeNumOA
    for numSys in range(equipNum+1):
        state.dataZoneEquip.ZoneEquipList[0].compPointer.append(&thisSys)
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 30.0
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.FourPipeFanCoil
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataFanCoilUnits.GetFanCoilInputFlag = false
    state.dataFanCoilUnits.NumFanCoils = 1
    state.dataFanCoilUnits.FanCoil.allocate(1)
    state.dataFanCoilUnits.FanCoil[0].OutsideAirNode = nodeNumOA
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 400.0
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.UnitVentilator
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataUnitVentilators.GetUnitVentilatorInputFlag = false
    state.dataUnitVentilators.NumOfUnitVents = 1
    state.dataUnitVentilators.UnitVent.allocate(1)
    state.dataUnitVentilators.UnitVent[0].OutsideAirNode = nodeNumOA
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 5000.0
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.PurchasedAir
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataPurchasedAirMgr.GetPurchAirInputFlag = false
    state.dataPurchasedAirMgr.NumPurchAir = 1
    state.dataPurchasedAirMgr.PurchAir.allocate(1)
    state.dataPurchasedAirMgr.PurchAir[0].OutdoorAirMassFlowRate = 60000.0
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.EnergyRecoveryVentilator
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataHVACStandAloneERV.GetERVInputFlag = false
    state.dataHVACStandAloneERV.NumStandAloneERVs = 1
    state.dataHVACStandAloneERV.StandAloneERV.allocate(1)
    state.dataHVACStandAloneERV.StandAloneERV[0].SupplyAirInletNode = nodeNumOA
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 700000.0
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.OutdoorAirUnit
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = false
    state.dataOutdoorAirUnit.NumOfOAUnits = 1
    state.dataOutdoorAirUnit.OutAirUnit.allocate(1)
    state.dataOutdoorAirUnit.OutAirUnit[0].OutsideAirNode = nodeNumOA
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 8000000.0
    equipNum += 1
    nodeNumOA += 1
    state.dataZoneEquip.ZoneEquipList[0].EquipType[equipNum-1] = DataZoneEquipment.ZoneEquipType.HybridEvaporativeCooler
    state.dataZoneEquip.ZoneEquipList[0].EquipIndex[equipNum-1] = 1
    state.dataHybridUnitaryAC.GetInputZoneHybridEvap = false
    state.dataHybridUnitaryAC.NumZoneHybridEvap = 1
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner.allocate(1)
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[0].SecondaryInletNode = nodeNumOA
    state.dataLoopNodes.Node[nodeNumOA-1].MassFlowRate = 90000000.0
    state.dataSysRpts.VentReportStructureCreated = true
    state.dataSysRpts.VentLoadsReportEnabled = true
    SystemReports.ReportVentilationLoads(state)
    EXPECT_NEAR(state.dataSysRpts.ZoneVentRepVars[0].TargetVentilationFlowVoz, expectedVoz, 0.001)
    EXPECT_NEAR(state.dataSysRpts.ZoneVentRepVars[0].OAMassFlow, 98765432.1, 0.001)

def ReportVentilationLoads_MechVent():
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataEnvrn.StdRhoAir = 1.2
    state.dataHVACGlobal.NumPrimaryAirSys = 1
    state.dataAirSystemsData.PrimaryAirSystems.allocate(state.dataHVACGlobal.NumPrimaryAirSys)
    state.dataSysRpts.SysVentRepVars.allocate(1)
    state.dataSysRpts.SysPreDefRep.allocate(1)
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.ZonePreDefRep.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.ZnAirRpt.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEquip.ZoneEquipList.allocate(state.dataGlobal.NumOfZones)
    state.dataAirLoop.AirLoopFlow.allocate(1)
    state.dataAirLoop.AirLoopFlow[0].OAFlow = 1.6
    state.dataEnvrn.StdRhoAir = 0.8
    HeatBalanceManager.AllocateHeatBalArrays(state)
    SystemReports.AllocateAndSetUpVentReports(state)
    ZoneTempPredictorCorrector.InitZoneAirSetPoints(state)
    state.dataSysRpts.VentReportStructureCreated = true
    state.dataSysRpts.VentLoadsReportEnabled = true
    state.dataAirLoop.AirLoopControlInfo.allocate(1)
    state.dataAirLoop.AirLoopControlInfo[0].OACtrlNum = 0
    SystemReports.ReportVentilationLoads(state)
    EXPECT_NEAR(state.dataSysRpts.SysVentRepVars[0].MechVentFlow, 2.0, 1e-6)
<<<FILE>>>
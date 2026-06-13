from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataContaminantBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.ZonePlenum import InitAirZoneReturnPlenum, UpdateAirZoneReturnPlenum
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture

def ZonePlenum_InitAirZoneReturnPlenumTest():
    var state = EnergyPlusData()
    state.dataGlobal.BeginEnvrnFlag = False
    state.dataContaminantBalance.Contaminant.CO2Simulation = True
    state.dataContaminantBalance.Contaminant.GenericContamSimulation = True
    state.dataZonePlenum.NumZoneReturnPlenums = 1
    state.dataZonePlenum.ZoneRetPlenCond.allocate(state.dataZonePlenum.NumZoneReturnPlenums)
    var ZonePlenumNum = 1
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInletNodes = 0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes = 2
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InletNode.allocate(1)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedNode.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRate.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMaxAvail.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMinAvail.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedTemp.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedHumRat.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedEnthalpy.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedPressure.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedCO2.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedGenContam.allocate(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InletNode[0] = 1
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRate = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMaxAvail = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMinAvail = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedTemp = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedHumRat = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedEnthalpy = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedPressure = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedCO2 = 0.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedGenContam = 0.0
    state.dataLoopNodes.Node.allocate(4)
    var ZoneNodeNum = 1
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].ZoneNodeNum = ZoneNodeNum
    state.dataLoopNodes.Node[ZoneNodeNum - 1].Temp = 24.2
    state.dataLoopNodes.Node[ZoneNodeNum - 1].HumRat = 0.0003
    state.dataLoopNodes.Node[ZoneNodeNum - 1].Enthalpy = 40000.0
    state.dataLoopNodes.Node[ZoneNodeNum - 1].Press = 99000.0
    state.dataLoopNodes.Node[ZoneNodeNum - 1].CO2 = 950.0
    state.dataLoopNodes.Node[ZoneNodeNum - 1].GenContam = 100.0
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].OutletPressure = 99000.0
    var InducedNodeIndex = 0
    var InducedNodeNum = 2
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedNode[InducedNodeIndex] = InducedNodeNum
    state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRate = 0.20
    state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRateMaxAvail = 0.25
    state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRateMinAvail = 0.10
    InducedNodeIndex = 1
    InducedNodeNum = 3
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedNode[InducedNodeIndex] = InducedNodeNum
    state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRate = 0.40
    state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRateMaxAvail = 0.50
    state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRateMinAvail = 0.22
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].OutletNode = 4
    InitAirZoneReturnPlenum(state, ZonePlenumNum)
    UpdateAirZoneReturnPlenum(state, ZonePlenumNum)
    assert(state.dataLoopNodes.Node[state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].ZoneNodeNum - 1].CO2 == state.dataLoopNodes.Node[state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].OutletNode - 1].CO2)
    assert(state.dataLoopNodes.Node[state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].ZoneNodeNum - 1].CO2 == state.dataLoopNodes.Node[state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].OutletNode - 1].CO2)
    for InducedNodeIndex in range(state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].NumInducedNodes):
        InducedNodeNum = state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedNode[InducedNodeIndex]
        assert(state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRate == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRate[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRateMaxAvail == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMaxAvail[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[InducedNodeNum - 1].MassFlowRateMinAvail == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMinAvail[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].Temp == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedTemp[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].HumRat == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedHumRat[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].Enthalpy == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedEnthalpy[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].Press == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedPressure[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].CO2 == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedCO2[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].GenContam == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedGenContam[InducedNodeIndex])
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].Temp == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].ZoneTemp)
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].HumRat == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].ZoneHumRat)
        assert(state.dataLoopNodes.Node[ZoneNodeNum - 1].Enthalpy == state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].ZoneEnthalpy)
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InletNode.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedNode.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRate.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMaxAvail.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedMassFlowRateMinAvail.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedTemp.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedHumRat.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedEnthalpy.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedPressure.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedCO2.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond[ZonePlenumNum - 1].InducedGenContam.deallocate()
    state.dataZonePlenum.ZoneRetPlenCond.deallocate()
    state.dataLoopNodes.Node.deallocate()
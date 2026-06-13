// Mojo translation of HVACInterfaceManager.cc
// Faithful 1:1 translation, no refactoring.
// ObjexxFCL () indexing converted to 0-based [] subscript.

from DataConvergParams import CalledFrom, ConvergLogStackDepth, HVACFlowRateToler, HVACEnergyToler, HVACEnthalpyToler, HVACPressToler, HVACTemperatureToler, HVACHumRatToler, HVACCO2Toler, HVACGenContamToler, PlantFlowRateToler, PlantTemperatureToler
from DataAirLoop import AirToZoneNodeInfo
from DataBranchAirLoopPlant import MassFlowTolerance
from DataContaminantBalance import Contaminant
from DataHVACGlobals import SysTimeElapsed, TimeStepSysSec, TimeStepZone
from .Data.EnergyPlusData import EnergyPlusData
from DataLoopNodes import Node
from DataPlant import CommonPipeType, LoopSideLocation, LoopSideOther, PlantEquipmentType, DeltaTempTol
from Plant.Enums import PlantLocation
from Plant.DataPlant import PlantLoop
from PlantUtilities import SetActuatedBranchFlowRate
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType, Constant
from FluidProperties import getSpecificHeat
from UtilityRoutines import ShowWarningError, ShowContinueError

alias NoRecircFlow: Int = 0
alias PrimaryRecirc: Int = 1
alias SecondaryRecirc: Int = 2

enum FlowType: Int:
    Invalid = -1
    Constant = 0
    Variable = 1
    Num = 2

struct CommonPipeData:
    var CommonPipeType: DataPlant.CommonPipeType = DataPlant.CommonPipeType.No
    var SupplySideInletPumpType: FlowType = FlowType.Invalid
    var DemandSideInletPumpType: FlowType = FlowType.Invalid
    var FlowDir: Int = 0
    var Flow: Float64 = 0.0
    var Temp: Float64 = 0.0
    var SecCPLegFlow: Float64 = 0.0
    var PriCPLegFlow: Float64 = 0.0
    var SecToPriFlow: Float64 = 0.0
    var PriToSecFlow: Float64 = 0.0
    var PriInTemp: Float64 = 0.0
    var PriOutTemp: Float64 = 0.0
    var SecInTemp: Float64 = 0.0
    var SecOutTemp: Float64 = 0.0
    var PriInletSetPoint: Float64 = 0.0
    var SecInletSetPoint: Float64 = 0.0
    var PriInletControlled: Bool = False
    var SecInletControlled: Bool = False
    var PriFlowRequest: Float64 = 0.0
    var MyEnvrnFlag: Bool = True

def rshift1(inout a: __mlir_type.`!kgen.list<Float64, ConvergLogStackDepth>`):
    # a is a fixed-size list; we circular shift right
    let lastVal = a[a.size - 1]
    for i in range(a.size - 1, 0, -1):
        a[i] = a[i - 1]
    a[0] = lastVal

def UpdateHVACInterface(
    inout state: EnergyPlusData,
    AirLoopNum: Int,
    CalledFrom: DataConvergParams.CalledFrom,
    OutletNode: Int,
    InletNode: Int,
    inout OutOfToleranceFlag: Bool
):
    var TmpRealARR = state.dataHVACInterfaceMgr.TmpRealARR
    var airLoopConv = state.dataConvergeParams.AirLoopConvergence[AirLoopNum - 1]  # 1-based to 0-based
    var thisInletNode = state.dataLoopNodes.Node[InletNode - 1]  # 1-based to 0-based
    let iCall = __mlir_type.`index`(CalledFrom)  # cast to int

    if (CalledFrom == DataConvergParams.CalledFrom.AirSystemDemandSide) and (OutletNode == 0):
        airLoopConv.HVACMassFlowNotConverged[iCall] = False
        airLoopConv.HVACHumRatNotConverged[iCall] = False
        airLoopConv.HVACTempNotConverged[iCall] = False
        airLoopConv.HVACEnergyNotConverged[iCall] = False
        var totDemandSideMassFlow: Float64 = 0.0
        var totDemandSideMinAvail: Float64 = 0.0
        var totDemandSideMaxAvail: Float64 = 0.0
        for demIn in range(1, state.dataAirLoop.AirToZoneNodeInfo[AirLoopNum - 1].NumSupplyNodes + 1):  # 1-based loop
            let demInNode = state.dataAirLoop.AirToZoneNodeInfo[AirLoopNum - 1].ZoneEquipSupplyNodeNum[demIn - 1]  # 1-based to 0-based
            let node = state.dataLoopNodes.Node[demInNode - 1]
            totDemandSideMassFlow += node.MassFlowRate
            totDemandSideMinAvail += node.MassFlowRateMinAvail
            totDemandSideMaxAvail += node.MassFlowRateMaxAvail
        TmpRealARR = airLoopConv.HVACFlowDemandToSupplyTolValue
        airLoopConv.HVACFlowDemandToSupplyTolValue[0] = abs(totDemandSideMassFlow - thisInletNode.MassFlowRate)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACFlowDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACFlowDemandToSupplyTolValue[0] > HVACFlowRateToler:
            airLoopConv.HVACMassFlowNotConverged[iCall] = True
            OutOfToleranceFlag = True  # Something has changed--resimulate the other side of the loop
        thisInletNode.MassFlowRate = totDemandSideMassFlow
        thisInletNode.MassFlowRateMinAvail = totDemandSideMinAvail
        thisInletNode.MassFlowRateMaxAvail = totDemandSideMaxAvail
        return

    let DeltaEnergy = HVACEnergyToler * (
        (state.dataLoopNodes.Node[OutletNode - 1].MassFlowRate * state.dataLoopNodes.Node[OutletNode - 1].Temp) -
        (thisInletNode.MassFlowRate * thisInletNode.Temp)
    )

    if (CalledFrom == DataConvergParams.CalledFrom.AirSystemDemandSide) and (OutletNode > 0):
        airLoopConv.HVACMassFlowNotConverged[iCall] = False
        airLoopConv.HVACHumRatNotConverged[iCall] = False
        airLoopConv.HVACTempNotConverged[iCall] = False
        airLoopConv.HVACEnergyNotConverged[iCall] = False
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            airLoopConv.HVACCO2NotConverged[iCall] = False
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            airLoopConv.HVACGenContamNotConverged[iCall] = False

        TmpRealARR = airLoopConv.HVACFlowDemandToSupplyTolValue
        airLoopConv.HVACFlowDemandToSupplyTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].MassFlowRate - thisInletNode.MassFlowRate)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACFlowDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACFlowDemandToSupplyTolValue[0] > HVACFlowRateToler:
            airLoopConv.HVACMassFlowNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACHumDemandToSupplyTolValue
        airLoopConv.HVACHumDemandToSupplyTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].HumRat - thisInletNode.HumRat)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACHumDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACHumDemandToSupplyTolValue[0] > HVACHumRatToler:
            airLoopConv.HVACHumRatNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACTempDemandToSupplyTolValue
        airLoopConv.HVACTempDemandToSupplyTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Temp - thisInletNode.Temp)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACTempDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACTempDemandToSupplyTolValue[0] > HVACTemperatureToler:
            airLoopConv.HVACTempNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACEnergyDemandToSupplyTolValue
        airLoopConv.HVACEnergyDemandToSupplyTolValue[0] = abs(DeltaEnergy)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACEnergyDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if abs(DeltaEnergy) > HVACEnergyToler:
            airLoopConv.HVACEnergyNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACEnthalpyDemandToSupplyTolValue
        airLoopConv.HVACEnthalpyDemandToSupplyTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Enthalpy - thisInletNode.Enthalpy)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACEnthalpyDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACEnthalpyDemandToSupplyTolValue[0] > HVACEnthalpyToler:
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACPressureDemandToSupplyTolValue
        airLoopConv.HVACPressureDemandToSupplyTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Press - thisInletNode.Press)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACPressureDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACPressureDemandToSupplyTolValue[0] > HVACPressToler:
            OutOfToleranceFlag = True

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            TmpRealARR = airLoopConv.HVACCO2DemandToSupplyTolValue
            airLoopConv.HVACCO2DemandToSupplyTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].CO2 - thisInletNode.CO2)
            for logIndex in range(1, ConvergLogStackDepth):
                airLoopConv.HVACCO2DemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
            if airLoopConv.HVACCO2DemandToSupplyTolValue[0] > HVACCO2Toler:
                airLoopConv.HVACCO2NotConverged[iCall] = True
                OutOfToleranceFlag = True

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            TmpRealARR = airLoopConv.HVACGenContamDemandToSupplyTolValue
            airLoopConv.HVACGenContamDemandToSupplyTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].GenContam - thisInletNode.GenContam)
            for logIndex in range(1, ConvergLogStackDepth):
                airLoopConv.HVACGenContamDemandToSupplyTolValue[logIndex] = TmpRealARR[logIndex - 1]
            if airLoopConv.HVACGenContamDemandToSupplyTolValue[0] > HVACGenContamToler:
                airLoopConv.HVACGenContamNotConverged[iCall] = True
                OutOfToleranceFlag = True

    elif CalledFrom == DataConvergParams.CalledFrom.AirSystemSupplySideDeck1:
        airLoopConv.HVACMassFlowNotConverged[iCall] = False
        airLoopConv.HVACHumRatNotConverged[iCall] = False
        airLoopConv.HVACTempNotConverged[iCall] = False
        airLoopConv.HVACEnergyNotConverged[iCall] = False
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            airLoopConv.HVACCO2NotConverged[iCall] = False
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            airLoopConv.HVACGenContamNotConverged[iCall] = False

        TmpRealARR = airLoopConv.HVACFlowSupplyDeck1ToDemandTolValue
        airLoopConv.HVACFlowSupplyDeck1ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].MassFlowRate - thisInletNode.MassFlowRate)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACFlowSupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACFlowSupplyDeck1ToDemandTolValue[0] > HVACFlowRateToler:
            airLoopConv.HVACMassFlowNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACHumSupplyDeck1ToDemandTolValue
        airLoopConv.HVACHumSupplyDeck1ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].HumRat - thisInletNode.HumRat)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACHumSupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACHumSupplyDeck1ToDemandTolValue[0] > HVACHumRatToler:
            airLoopConv.HVACHumRatNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACTempSupplyDeck1ToDemandTolValue
        airLoopConv.HVACTempSupplyDeck1ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Temp - thisInletNode.Temp)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACTempSupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACTempSupplyDeck1ToDemandTolValue[0] > HVACTemperatureToler:
            airLoopConv.HVACTempNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACEnergySupplyDeck1ToDemandTolValue
        airLoopConv.HVACEnergySupplyDeck1ToDemandTolValue[0] = DeltaEnergy
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACEnergySupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if abs(DeltaEnergy) > HVACEnergyToler:
            airLoopConv.HVACEnergyNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACEnthalpySupplyDeck1ToDemandTolValue
        airLoopConv.HVACEnthalpySupplyDeck1ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Enthalpy - thisInletNode.Enthalpy)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACEnthalpySupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACEnthalpySupplyDeck1ToDemandTolValue[0] > HVACEnthalpyToler:
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACPressureSupplyDeck1ToDemandTolValue
        airLoopConv.HVACPressureSupplyDeck1ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Press - thisInletNode.Press)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACPressureSupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACPressureSupplyDeck1ToDemandTolValue[0] > HVACPressToler:
            OutOfToleranceFlag = True

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            TmpRealARR = airLoopConv.HVACCO2SupplyDeck1ToDemandTolValue
            airLoopConv.HVACCO2SupplyDeck1ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].CO2 - thisInletNode.CO2)
            for logIndex in range(1, ConvergLogStackDepth):
                airLoopConv.HVACCO2SupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
            if airLoopConv.HVACCO2SupplyDeck1ToDemandTolValue[0] > HVACCO2Toler:
                airLoopConv.HVACCO2NotConverged[iCall] = True
                OutOfToleranceFlag = True

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            TmpRealARR = airLoopConv.HVACGenContamSupplyDeck1ToDemandTolValue
            airLoopConv.HVACGenContamSupplyDeck1ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].GenContam - thisInletNode.GenContam)
            for logIndex in range(1, ConvergLogStackDepth):
                airLoopConv.HVACGenContamSupplyDeck1ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
            if airLoopConv.HVACGenContamSupplyDeck1ToDemandTolValue[0] > HVACGenContamToler:
                airLoopConv.HVACGenContamNotConverged[iCall] = True
                OutOfToleranceFlag = True

    elif CalledFrom == DataConvergParams.CalledFrom.AirSystemSupplySideDeck2:
        airLoopConv.HVACMassFlowNotConverged[iCall] = False
        airLoopConv.HVACHumRatNotConverged[iCall] = False
        airLoopConv.HVACTempNotConverged[iCall] = False
        airLoopConv.HVACEnergyNotConverged[iCall] = False
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            airLoopConv.HVACCO2NotConverged[iCall] = False
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            airLoopConv.HVACGenContamNotConverged[iCall] = False

        TmpRealARR = airLoopConv.HVACFlowSupplyDeck2ToDemandTolValue
        airLoopConv.HVACFlowSupplyDeck2ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].MassFlowRate - thisInletNode.MassFlowRate)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACFlowSupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACFlowSupplyDeck2ToDemandTolValue[0] > HVACFlowRateToler:
            airLoopConv.HVACMassFlowNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACHumSupplyDeck2ToDemandTolValue
        airLoopConv.HVACHumSupplyDeck2ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].HumRat - thisInletNode.HumRat)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACHumSupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACHumSupplyDeck2ToDemandTolValue[0] > HVACHumRatToler:
            airLoopConv.HVACHumRatNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACTempSupplyDeck2ToDemandTolValue
        airLoopConv.HVACTempSupplyDeck2ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Temp - thisInletNode.Temp)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACTempSupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACTempSupplyDeck2ToDemandTolValue[0] > HVACTemperatureToler:
            airLoopConv.HVACTempNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACEnergySupplyDeck2ToDemandTolValue
        airLoopConv.HVACEnergySupplyDeck2ToDemandTolValue[0] = DeltaEnergy
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACEnergySupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if abs(DeltaEnergy) > HVACEnergyToler:
            airLoopConv.HVACEnergyNotConverged[iCall] = True
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACEnthalpySupplyDeck2ToDemandTolValue
        airLoopConv.HVACEnthalpySupplyDeck2ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Enthalpy - thisInletNode.Enthalpy)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACEnthalpySupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACEnthalpySupplyDeck2ToDemandTolValue[0] > HVACEnthalpyToler:
            OutOfToleranceFlag = True

        TmpRealARR = airLoopConv.HVACPressueSupplyDeck2ToDemandTolValue
        airLoopConv.HVACPressueSupplyDeck2ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].Press - thisInletNode.Press)
        for logIndex in range(1, ConvergLogStackDepth):
            airLoopConv.HVACPressueSupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
        if airLoopConv.HVACPressueSupplyDeck2ToDemandTolValue[0] > HVACPressToler:
            OutOfToleranceFlag = True

        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            TmpRealARR = airLoopConv.HVACCO2SupplyDeck2ToDemandTolValue
            airLoopConv.HVACCO2SupplyDeck2ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].CO2 - thisInletNode.CO2)
            for logIndex in range(1, ConvergLogStackDepth):
                airLoopConv.HVACCO2SupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
            if airLoopConv.HVACCO2SupplyDeck2ToDemandTolValue[0] > HVACCO2Toler:
                airLoopConv.HVACCO2NotConverged[iCall] = True
                OutOfToleranceFlag = True

        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            TmpRealARR = airLoopConv.HVACGenContamSupplyDeck2ToDemandTolValue
            airLoopConv.HVACGenContamSupplyDeck2ToDemandTolValue[0] = abs(state.dataLoopNodes.Node[OutletNode - 1].GenContam - thisInletNode.GenContam)
            for logIndex in range(1, ConvergLogStackDepth):
                airLoopConv.HVACGenContamSupplyDeck2ToDemandTolValue[logIndex] = TmpRealARR[logIndex - 1]
            if airLoopConv.HVACGenContamSupplyDeck2ToDemandTolValue[0] > HVACGenContamToler:
                airLoopConv.HVACGenContamNotConverged[iCall] = True
                OutOfToleranceFlag = True

    thisInletNode.Temp = state.dataLoopNodes.Node[OutletNode - 1].Temp
    thisInletNode.MassFlowRate = state.dataLoopNodes.Node[OutletNode - 1].MassFlowRate
    thisInletNode.MassFlowRateMinAvail = state.dataLoopNodes.Node[OutletNode - 1].MassFlowRateMinAvail
    thisInletNode.MassFlowRateMaxAvail = state.dataLoopNodes.Node[OutletNode - 1].MassFlowRateMaxAvail
    thisInletNode.Quality = state.dataLoopNodes.Node[OutletNode - 1].Quality
    thisInletNode.Press = state.dataLoopNodes.Node[OutletNode - 1].Press
    thisInletNode.Enthalpy = state.dataLoopNodes.Node[OutletNode - 1].Enthalpy
    thisInletNode.HumRat = state.dataLoopNodes.Node[OutletNode - 1].HumRat
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        thisInletNode.CO2 = state.dataLoopNodes.Node[OutletNode - 1].CO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        thisInletNode.GenContam = state.dataLoopNodes.Node[OutletNode - 1].GenContam

def UpdatePlantLoopInterface(
    inout state: EnergyPlusData,
    plantLoc: PlantLocation,
    ThisLoopSideOutletNode: Int,
    OtherLoopSideInletNode: Int,
    inout OutOfToleranceFlag: Bool,
    CommonPipeType: DataPlant.CommonPipeType
):
    alias RoutineName: StringLiteral = "UpdatePlantLoopInterface"
    let LoopNum = plantLoc.loopNum
    let ThisLoopSideNum = plantLoc.loopSideNum
    var convergence = state.dataConvergeParams.PlantConvergence[LoopNum - 1]  # 1-based to 0-based
    convergence.PlantMassFlowNotConverged = False
    convergence.PlantTempNotConverged = False
    let ThisLoopSideInletNode = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[ThisLoopSideNum.value()].NodeNumIn  # adjust indexing
    # Note: LoopSide is likely an array indexed by enum value; keep as is (0-based)
    let OldOtherLoopSideInletMdot = state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRate
    let OldTankOutletTemp = state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Temp
    let Cp = state.dataPlnt.PlantLoop[LoopNum - 1].glycol.getSpecificHeat(state, OldTankOutletTemp, RoutineName)
    state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Enthalpy = Cp * state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Temp
    var flow_demand_to_supply_tol = convergence.PlantFlowDemandToSupplyTolValue
    var flow_supply_to_demand_tol = convergence.PlantFlowSupplyToDemandTolValue
    var MixedOutletTemp: Float64
    var TankOutletTemp: Float64
    if (CommonPipeType == DataPlant.CommonPipeType.Single) or (CommonPipeType == DataPlant.CommonPipeType.TwoWay):
        UpdateCommonPipe(state, plantLoc, CommonPipeType, MixedOutletTemp)
        state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Temp = MixedOutletTemp
        TankOutletTemp = MixedOutletTemp
        if ThisLoopSideNum == DataPlant.LoopSideLocation.Demand:
            rshift1(flow_demand_to_supply_tol)
            flow_demand_to_supply_tol[0] = abs(OldOtherLoopSideInletMdot - state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRate)
            if flow_demand_to_supply_tol[0] > PlantFlowRateToler:
                convergence.PlantMassFlowNotConverged = True
        else:
            rshift1(flow_supply_to_demand_tol)
            flow_supply_to_demand_tol[0] = abs(OldOtherLoopSideInletMdot - state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRate)
            if flow_supply_to_demand_tol[0] > PlantFlowRateToler:
                convergence.PlantMassFlowNotConverged = True
        state.dataLoopNodes.Node[ThisLoopSideInletNode - 1].MassFlowRate = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRate
        state.dataLoopNodes.Node[ThisLoopSideInletNode - 1].MassFlowRateMinAvail = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRateMinAvail
        state.dataLoopNodes.Node[ThisLoopSideInletNode - 1].MassFlowRateMaxAvail = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRateMaxAvail
    else:  # no common pipe
        UpdateHalfLoopInletTemp(state, LoopNum, ThisLoopSideNum, TankOutletTemp)
        state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Temp = TankOutletTemp
        if ThisLoopSideNum == DataPlant.LoopSideLocation.Demand:
            rshift1(flow_demand_to_supply_tol)
            flow_demand_to_supply_tol[0] = abs(state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRate - state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRate)
            if flow_demand_to_supply_tol[0] > PlantFlowRateToler:
                convergence.PlantMassFlowNotConverged = True
        else:
            rshift1(flow_supply_to_demand_tol)
            flow_supply_to_demand_tol[0] = abs(state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRate - state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRate)
            if flow_supply_to_demand_tol[0] > PlantFlowRateToler:
                convergence.PlantMassFlowNotConverged = True
        state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRate = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRate
        state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRateMinAvail = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRateMinAvail
        state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].MassFlowRateMaxAvail = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].MassFlowRateMaxAvail
        state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Quality = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].Quality
        if state.dataPlnt.PlantLoop[LoopNum - 1].HasPressureComponents:

        else:
            state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Press = state.dataLoopNodes.Node[ThisLoopSideOutletNode - 1].Press

    if ThisLoopSideNum == DataPlant.LoopSideLocation.Demand:
        var temp_demand_to_supply_tol = convergence.PlantTempDemandToSupplyTolValue
        rshift1(temp_demand_to_supply_tol)
        temp_demand_to_supply_tol[0] = abs(OldTankOutletTemp - state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Temp)
        if temp_demand_to_supply_tol[0] > PlantTemperatureToler:
            convergence.PlantTempNotConverged = True
    else:
        var temp_supply_to_demand_tol = convergence.PlantTempSupplyToDemandTolValue
        rshift1(temp_supply_to_demand_tol)
        temp_supply_to_demand_tol[0] = abs(OldTankOutletTemp - state.dataLoopNodes.Node[OtherLoopSideInletNode - 1].Temp)
        if temp_supply_to_demand_tol[0] > PlantTemperatureToler:
            convergence.PlantTempNotConverged = True

    if ThisLoopSideNum == DataPlant.LoopSideLocation.Demand:
        if convergence.PlantMassFlowNotConverged or convergence.PlantTempNotConverged:
            OutOfToleranceFlag = True
    else:
        if convergence.PlantMassFlowNotConverged:
            OutOfToleranceFlag = True

def UpdateHalfLoopInletTemp(
    inout state: EnergyPlusData,
    LoopNum: Int,
    TankInletLoopSide: DataPlant.LoopSideLocation,
    inout TankOutletTemp: Float64
):
    let SysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
    alias FracTotLoopMass: Float64 = 0.5  # Fraction of total loop mass assigned to the half loop
    alias RoutineName: StringLiteral = "UpdateHalfLoopInletTemp"
    let TankOutletLoopSide = DataPlant.LoopSideOther[TankInletLoopSide.value()]  # use enum value as index? Keep as is.
    let TankInletNode = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankInletLoopSide.value()].NodeNumOut
    let TankInletTemp = state.dataLoopNodes.Node[TankInletNode - 1].Temp
    let TimeElapsed = (state.dataGlobal.HourOfDay - 1) + state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + SysTimeElapsed
    if state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TimeElapsed != TimeElapsed:
        state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LastTempInterfaceTankOutlet = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TempInterfaceTankOutlet
        state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TimeElapsed = TimeElapsed
    let LastTankOutletTemp = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LastTempInterfaceTankOutlet
    let Cp = state.dataPlnt.PlantLoop[LoopNum - 1].glycol.getSpecificHeat(state, LastTankOutletTemp, RoutineName)
    let TimeStepSeconds = state.dataHVACGlobal.TimeStepSysSec
    let MassFlowRate = state.dataLoopNodes.Node[TankInletNode - 1].MassFlowRate
    let PumpHeat = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TotalPumpHeat
    let ThisTankMass = FracTotLoopMass * state.dataPlnt.PlantLoop[LoopNum - 1].Mass
    var TankFinalTemp: Float64
    var TankAverageTemp: Float64
    if ThisTankMass <= 0.0:  # no mass, no plant loop volume
        if MassFlowRate > 0.0:
            TankFinalTemp = TankInletTemp + PumpHeat / (MassFlowRate * Cp)
            TankAverageTemp = (TankFinalTemp + LastTankOutletTemp) / 2.0
        else:
            TankFinalTemp = LastTankOutletTemp
            TankAverageTemp = LastTankOutletTemp
    else:  # tank has mass
        if MassFlowRate > 0.0:
            let mdotCp = MassFlowRate * Cp
            let mdotCpTempIn = mdotCp * TankInletTemp
            let tankMassCp = ThisTankMass * Cp
            let ExponentTerm = mdotCp / tankMassCp * TimeStepSeconds
            if ExponentTerm >= 700.0:
                TankFinalTemp = (mdotCp * TankInletTemp + PumpHeat) / mdotCp
                TankAverageTemp = (tankMassCp / mdotCp * (LastTankOutletTemp - (mdotCpTempIn + PumpHeat) / mdotCp) / TimeStepSeconds + (mdotCpTempIn + PumpHeat) / mdotCp)
            else:
                TankFinalTemp = (LastTankOutletTemp - (mdotCpTempIn + PumpHeat) / mdotCp) * exp(-ExponentTerm) + (mdotCpTempIn + PumpHeat) / (MassFlowRate * Cp)
                TankAverageTemp = (tankMassCp / mdotCp * (LastTankOutletTemp - (mdotCpTempIn + PumpHeat) / mdotCp) * (1.0 - exp(-ExponentTerm)) / TimeStepSeconds + (mdotCpTempIn + PumpHeat) / mdotCp)
        else:
            TankFinalTemp = PumpHeat / (ThisTankMass * Cp) * TimeStepSeconds + LastTankOutletTemp
            TankAverageTemp = (TankFinalTemp + LastTankOutletTemp) / 2.0
    state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TempInterfaceTankOutlet = TankFinalTemp
    state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LoopSideInlet_MdotCpDeltaT = (TankInletTemp - TankAverageTemp) * Cp * MassFlowRate
    state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LoopSideInlet_McpDTdt = (ThisTankMass * Cp * (TankFinalTemp - LastTankOutletTemp)) / TimeStepSeconds
    state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LoopSideInlet_TankTemp = TankAverageTemp
    TankOutletTemp = TankAverageTemp

def UpdateCommonPipe(
    inout state: EnergyPlusData,
    TankInletPlantLoc: PlantLocation,
    CommonPipeType: DataPlant.CommonPipeType,
    inout MixedOutletTemp: Float64
):
    let SysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
    alias RoutineName: StringLiteral = "UpdateCommonPipe"
    let LoopNum = TankInletPlantLoc.loopNum
    let TankInletLoopSide = TankInletPlantLoc.loopSideNum
    let TankOutletLoopSide = DataPlant.LoopSideOther[TankInletLoopSide.value()]
    let TankInletNode = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankInletLoopSide.value()].NodeNumOut
    let TankOutletNode = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].NodeNumIn
    let TankInletTemp = state.dataLoopNodes.Node[TankInletNode - 1].Temp
    var FracTotLoopMass: Float64
    if TankInletLoopSide == DataPlant.LoopSideLocation.Demand:
        FracTotLoopMass = 0.25
    else:
        FracTotLoopMass = 0.75
    let TimeElapsed = (state.dataGlobal.HourOfDay - 1) + state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + SysTimeElapsed
    if state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TimeElapsed != TimeElapsed:
        state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LastTempInterfaceTankOutlet = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TempInterfaceTankOutlet
        state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TimeElapsed = TimeElapsed
    let LastTankOutletTemp = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LastTempInterfaceTankOutlet
    let Cp = state.dataPlnt.PlantLoop[LoopNum - 1].glycol.getSpecificHeat(state, LastTankOutletTemp, RoutineName)
    let TimeStepSeconds = state.dataHVACGlobal.TimeStepSysSec
    let MassFlowRate = state.dataLoopNodes.Node[TankInletNode - 1].MassFlowRate
    let PumpHeat = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankInletLoopSide.value()].TotalPumpHeat
    let ThisTankMass = FracTotLoopMass * state.dataPlnt.PlantLoop[LoopNum - 1].Mass
    var TankFinalTemp: Float64
    var TankAverageTemp: Float64
    if ThisTankMass <= 0.0:
        if MassFlowRate > 0.0:
            TankFinalTemp = TankInletTemp + PumpHeat / (MassFlowRate * Cp)
            TankAverageTemp = (TankFinalTemp + LastTankOutletTemp) / 2.0
        else:
            TankFinalTemp = LastTankOutletTemp
            TankAverageTemp = LastTankOutletTemp
    else:
        if MassFlowRate > 0.0:
            TankFinalTemp = (LastTankOutletTemp - (MassFlowRate * Cp * TankInletTemp + PumpHeat) / (MassFlowRate * Cp)) * exp(-(MassFlowRate * Cp) / (ThisTankMass * Cp) * TimeStepSeconds) + (MassFlowRate * Cp * TankInletTemp + PumpHeat) / (MassFlowRate * Cp)
            TankAverageTemp = ((ThisTankMass * Cp) / (MassFlowRate * Cp) * (LastTankOutletTemp - (MassFlowRate * Cp * TankInletTemp + PumpHeat) / (MassFlowRate * Cp)) * (1.0 - exp(-(MassFlowRate * Cp) / (ThisTankMass * Cp) * TimeStepSeconds)) / TimeStepSeconds + (MassFlowRate * Cp * TankInletTemp + PumpHeat) / (MassFlowRate * Cp))
        else:
            TankFinalTemp = PumpHeat / (ThisTankMass * Cp) * TimeStepSeconds + LastTankOutletTemp
            TankAverageTemp = (TankFinalTemp + LastTankOutletTemp) / 2.0
    if CommonPipeType == DataPlant.CommonPipeType.Single:
        ManageSingleCommonPipe(state, LoopNum, TankOutletLoopSide, TankAverageTemp, MixedOutletTemp)
    elif CommonPipeType == DataPlant.CommonPipeType.TwoWay:
        let TankOutletPlantLoc = PlantLocation(LoopNum, TankOutletLoopSide.value(), 0, 0)  # construct as needed
        ManageTwoWayCommonPipe(state, TankOutletPlantLoc, TankAverageTemp)
        MixedOutletTemp = state.dataLoopNodes.Node[TankOutletNode - 1].Temp
    state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].TempInterfaceTankOutlet = TankFinalTemp
    state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[TankOutletLoopSide.value()].LoopSideInlet_TankTemp = TankAverageTemp

def ManageSingleCommonPipe(
    inout state: EnergyPlusData,
    LoopNum: Int,
    LoopSide: DataPlant.LoopSideLocation,
    TankOutletTemp: Float64,
    inout MixedOutletTemp: Float64
):
    if not state.dataHVACInterfaceMgr.CommonPipeSetupFinished:
        SetupCommonPipes(state)
    var plantCommonPipe = state.dataHVACInterfaceMgr.PlantCommonPipe[LoopNum - 1]  # 1-based to 0-based
    let NodeNumPriIn = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[DataPlant.LoopSideLocation.Supply.value()].NodeNumIn
    let NodeNumPriOut = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[DataPlant.LoopSideLocation.Supply.value()].NodeNumOut
    let NodeNumSecIn = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[DataPlant.LoopSideLocation.Demand.value()].NodeNumIn
    let NodeNumSecOut = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[DataPlant.LoopSideLocation.Demand.value()].NodeNumOut
    if plantCommonPipe.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        plantCommonPipe.Flow = 0.0
        plantCommonPipe.Temp = 0.0
        plantCommonPipe.FlowDir = NoRecircFlow
        plantCommonPipe.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        plantCommonPipe.MyEnvrnFlag = True
    let MdotSec = state.dataLoopNodes.Node[NodeNumSecOut - 1].MassFlowRate
    let MdotPri = state.dataLoopNodes.Node[NodeNumPriOut - 1].MassFlowRate
    var TempSecOutTankOut: Float64
    var TempPriOutTankOut: Float64
    if LoopSide == DataPlant.LoopSideLocation.Supply:
        TempSecOutTankOut = TankOutletTemp
        TempPriOutTankOut = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[DataPlant.LoopSideLocation.Demand.value()].LoopSideInlet_TankTemp
    else:
        TempPriOutTankOut = TankOutletTemp
        TempSecOutTankOut = state.dataPlnt.PlantLoop[LoopNum - 1].LoopSide[DataPlant.LoopSideLocation.Supply.value()].LoopSideInlet_TankTemp
    var MdotPriRCLeg: Float64
    var MdotSecRCLeg: Float64
    var TempSecInlet: Float64
    var TempPriInlet: Float64
    var CPFlowDir: Int
    var CommonPipeTemp: Float64
    if MdotPri > MdotSec:
        MdotPriRCLeg = MdotPri - MdotSec
        if MdotPriRCLeg < MassFlowTolerance:
            MdotPriRCLeg = 0.0
            CPFlowDir = NoRecircFlow
        else:
            CPFlowDir = PrimaryRecirc
        MdotSecRCLeg = 0.0
        CommonPipeTemp = TempPriOutTankOut
    elif MdotPri < MdotSec:
        MdotSecRCLeg = MdotSec - MdotPri
        if MdotSecRCLeg < MassFlowTolerance:
            MdotSecRCLeg = 0.0
            CPFlowDir = NoRecircFlow
        else:
            CPFlowDir = SecondaryRecirc
        MdotPriRCLeg = 0.0
        CommonPipeTemp = TempSecOutTankOut
    else:
        MdotPriRCLeg = 0.0
        MdotSecRCLeg = 0.0
        CPFlowDir = NoRecircFlow
        CommonPipeTemp = (TempPriOutTankOut + TempSecOutTankOut) / 2.0
    if MdotSec > 0.0:
        TempSecInlet = (MdotPri * TempPriOutTankOut + MdotSecRCLeg * TempSecOutTankOut - MdotPriRCLeg * TempPriOutTankOut) / MdotSec
    else:
        TempSecInlet = TempPriOutTankOut
    if MdotPri > 0.0:
        TempPriInlet = (MdotSec * TempSecOutTankOut + MdotPriRCLeg * TempPriOutTankOut - MdotSecRCLeg * TempSecOutTankOut) / MdotPri
    else:
        TempPriInlet = TempSecOutTankOut
    plantCommonPipe.Flow = max(MdotPriRCLeg, MdotSecRCLeg)
    plantCommonPipe.Temp = CommonPipeTemp
    plantCommonPipe.FlowDir = CPFlowDir
    state.dataLoopNodes.Node[NodeNumSecIn - 1].Temp = TempSecInlet
    state.dataLoopNodes.Node[NodeNumPriIn - 1].Temp = TempPriInlet
    if LoopSide == DataPlant.LoopSideLocation.Supply:
        MixedOutletTemp = TempPriInlet
    else:
        MixedOutletTemp = TempSecInlet

def ManageTwoWayCommonPipe(
    inout state: EnergyPlusData,
    plantLoc: PlantLocation,
    TankOutletTemp: Float64
):
    enum UpdateType:
        DemandLedPrimaryInlet = 0
        DemandLedSecondaryInlet = 1
        SupplyLedPrimaryInlet = 2
        SupplyLedSecondaryInlet = 3
    var curCallingCase = UpdateType.SupplyLedPrimaryInlet
    alias MaxIterLimitCaseA: Int = 8
    alias MaxIterLimitCaseB: Int = 4
    if not state.dataHVACInterfaceMgr.CommonPipeSetupFinished:
        SetupCommonPipes(state)
    var plantCommonPipe = state.dataHVACInterfaceMgr.PlantCommonPipe[plantLoc.loopNum - 1]
    var thisPlantLoop = state.dataPlnt.PlantLoop[plantLoc.loopNum - 1]
    let NodeNumPriIn = thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Supply.value()].NodeNumIn
    let NodeNumPriOut = thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Supply.value()].NodeNumOut
    let NodeNumSecIn = thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand.value()].NodeNumIn
    let NodeNumSecOut = thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand.value()].NodeNumOut
    if plantCommonPipe.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        plantCommonPipe.PriToSecFlow = 0.0
        plantCommonPipe.SecToPriFlow = 0.0
        plantCommonPipe.PriCPLegFlow = 0.0
        plantCommonPipe.SecCPLegFlow = 0.0
        plantCommonPipe.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        plantCommonPipe.MyEnvrnFlag = True
    let MdotSec = state.dataLoopNodes.Node[NodeNumSecOut - 1].MassFlowRate
    let TempCPPrimaryCntrlSetPoint = state.dataLoopNodes.Node[NodeNumPriIn - 1].TempSetPoint
    let TempCPSecondaryCntrlSetPoint = state.dataLoopNodes.Node[NodeNumSecIn - 1].TempSetPoint
    var MdotPriToSec = plantCommonPipe.PriToSecFlow
    var MdotPriRCLeg = plantCommonPipe.PriCPLegFlow
    var MdotSecRCLeg = plantCommonPipe.SecCPLegFlow
    var TempSecInlet = state.dataLoopNodes.Node[NodeNumSecIn - 1].Temp
    var TempPriInlet = state.dataLoopNodes.Node[NodeNumPriIn - 1].Temp
    let MdotPri = state.dataLoopNodes.Node[NodeNumPriOut - 1].MassFlowRate
    var TempPriOutTankOut: Float64
    var TempSecOutTankOut: Float64
    if plantLoc.loopSideNum == DataPlant.LoopSideLocation.Supply:
        TempSecOutTankOut = TankOutletTemp
        TempPriOutTankOut = thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand.value()].LoopSideInlet_TankTemp
    else:
        TempPriOutTankOut = TankOutletTemp
        TempSecOutTankOut = thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Supply.value()].LoopSideInlet_TankTemp
    if plantLoc.loopSideNum == DataPlant.LoopSideLocation.Supply:
        if thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Supply.value()].InletNodeSetPt and (not thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand.value()].InletNodeSetPt):
            curCallingCase = UpdateType.SupplyLedPrimaryInlet
        elif (not thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Supply.value()].InletNodeSetPt) and thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand.value()].InletNodeSetPt:
            curCallingCase = UpdateType.DemandLedPrimaryInlet
    else:
        if thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Supply.value()].InletNodeSetPt and (not thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand.value()].InletNodeSetPt):
            curCallingCase = UpdateType.SupplyLedSecondaryInlet
        elif (not thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Supply.value()].InletNodeSetPt) and thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand.value()].InletNodeSetPt:
            curCallingCase = UpdateType.DemandLedSecondaryInlet

    if (curCallingCase == UpdateType.SupplyLedPrimaryInlet) or (curCallingCase == UpdateType.SupplyLedSecondaryInlet):
        for loop in range(1, MaxIterLimitCaseA + 1):
            if abs(TempSecOutTankOut - TempCPPrimaryCntrlSetPoint) > DeltaTempTol:
                MdotPriToSec = MdotPriRCLeg * (TempCPPrimaryCntrlSetPoint - TempPriOutTankOut) / (TempSecOutTankOut - TempCPPrimaryCntrlSetPoint)
                if MdotPriToSec < MassFlowTolerance:
                    MdotPriToSec = 0.0
                if MdotPriToSec > MdotSec:
                    MdotPriToSec = MdotSec
            else:
                MdotPriToSec = MdotSec
            MdotPriRCLeg = MdotPri - MdotPriToSec
            if MdotPriRCLeg < MassFlowTolerance:
                MdotPriRCLeg = 0.0
            MdotSecRCLeg = MdotSec - MdotPriToSec
            if MdotSecRCLeg < MassFlowTolerance:
                MdotSecRCLeg = 0.0
            if (MdotPriToSec + MdotSecRCLeg) > MassFlowTolerance:
                TempSecInlet = (MdotPriToSec * TempPriOutTankOut + MdotSecRCLeg * TempSecOutTankOut) / (MdotPriToSec + MdotSecRCLeg)
            else:
                TempSecInlet = TempPriOutTankOut
            if (plantCommonPipe.SupplySideInletPumpType == FlowType.Variable) and (curCallingCase == UpdateType.SupplyLedPrimaryInlet):
                if abs(TempCPPrimaryCntrlSetPoint) > DeltaTempTol:
                    MdotPri = (MdotPriRCLeg * TempPriOutTankOut + MdotPriToSec * TempSecOutTankOut) / TempCPPrimaryCntrlSetPoint
                    if MdotPri < MassFlowTolerance:
                        MdotPri = 0.0
                else:
                    MdotPri = MdotSec
                let thisPlantLoc = PlantLocation(plantLoc.loopNum, DataPlant.LoopSideLocation.Supply.value(), 1, 0)
                PlantUtilities.SetActuatedBranchFlowRate(state, MdotPri, NodeNumPriIn, thisPlantLoc, False)
            if (MdotPriToSec + MdotPriRCLeg) > MassFlowTolerance:
                TempPriInlet = (MdotPriToSec * TempSecOutTankOut + MdotPriRCLeg * TempPriOutTankOut) / (MdotPriToSec + MdotPriRCLeg)
            else:
                TempPriInlet = TempSecOutTankOut
    elif (curCallingCase == UpdateType.DemandLedPrimaryInlet) or (curCallingCase == UpdateType.DemandLedSecondaryInlet):
        for loop in range(1, MaxIterLimitCaseB + 1):
            if abs(TempPriOutTankOut - TempSecOutTankOut) > DeltaTempTol:
                MdotPriToSec = MdotSec * (TempCPSecondaryCntrlSetPoint - TempSecOutTankOut) / (TempPriOutTankOut - TempSecOutTankOut)
                if MdotPriToSec < MassFlowTolerance:
                    MdotPriToSec = 0.0
                if MdotPriToSec > MdotSec:
                    MdotPriToSec = MdotSec
            else:
                MdotPriToSec = MdotSec
            if (MdotPriToSec + MdotPriRCLeg) > MassFlowTolerance:
                TempPriInlet = (MdotPriToSec * TempSecOutTankOut + MdotPriRCLeg * TempPriOutTankOut) / (MdotPriToSec + MdotPriRCLeg)
            else:
                TempPriInlet = TempSecOutTankOut
            if (plantCommonPipe.SupplySideInletPumpType == FlowType.Variable) and (curCallingCase == UpdateType.DemandLedPrimaryInlet):
                if abs(TempPriOutTankOut - TempPriInlet) > DeltaTempTol:
                    MdotPri = MdotSec * (TempCPSecondaryCntrlSetPoint - TempSecOutTankOut) / (TempPriOutTankOut - TempPriInlet)
                    if MdotPri < MassFlowTolerance:
                        MdotPri = 0.0
                else:
                    MdotPri = MdotSec
                let thisPlantLoc = PlantLocation(plantLoc.loopNum, DataPlant.LoopSideLocation.Supply.value(), 1, 0)
                PlantUtilities.SetActuatedBranchFlowRate(state, MdotPri, NodeNumPriIn, thisPlantLoc, False)
            MdotSecRCLeg = MdotSec - MdotPriToSec
            if MdotSecRCLeg < MassFlowTolerance:
                MdotSecRCLeg = 0.0

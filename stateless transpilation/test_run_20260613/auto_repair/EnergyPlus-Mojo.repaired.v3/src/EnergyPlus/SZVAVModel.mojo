from SZVAVModel import SZVAVModel_hh
from .Data.EnergyPlusData import EnergyPlusData
from DataHVACGlobals import DataHVACGlobals
from DataLoopNode import DataLoopNode
from General import General
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from FanCoilUnits import FanCoilUnits
from UnitarySystem import UnitarySystems
from SizingManager import SizingManager
from UtilityRoutines import UtilityRoutines
from HVAC import HVAC
from DataPlant import DataPlant
from PlantLocation import PlantLocation

def calcSZVAVModel(
    inout state: EnergyPlusData,
    inout SZVAVModel: FanCoilUnits.FanCoilData,
    SysIndex: Int,
    FirstHVACIteration: Bool,
    CoolingLoad: Bool,
    HeatingLoad: Bool,
    ZoneLoad: Float64,
    inout OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool,
    AirLoopNum: Int,
    inout PartLoadRatio: Float64,
    CompressorONFlag: HVAC.CompressorOp
):
    var MaxIter: Int = 100
    var SolFlag: Int = 0
    var MessagePrefix: String = ""
    var lowBoundaryLoad: Float64 = 0.0
    var highBoundaryLoad: Float64 = 0.0
    var minHumRat: Float64 = 0.0
    var outletTemp: Float64 = 0.0
    var coilActive: Bool = False
    var AirMassFlow: Float64 = 0.0
    var maxCoilFluidFlow: Float64 = 0.0
    var maxOutletTemp: Float64 = 0.0
    var minAirMassFlow: Float64 = 0.0
    var maxAirMassFlow: Float64 = 0.0
    var lowSpeedFanRatio: Float64 = 0.0
    var coilFluidInletNode: Int = 0
    var coilFluidOutletNode: Int = 0
    var coilPlantLoc: PlantLocation = PlantLocation()
    var coilAirInletNode: Int = 0
    var coilAirOutletNode: Int = 0
    var TempSensOutput: Float64 = 0.0
    if CoolingLoad:
        maxCoilFluidFlow = SZVAVModel.MaxCoolCoilFluidFlow
        maxOutletTemp = SZVAVModel.DesignMinOutletTemp
        minAirMassFlow = SZVAVModel.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = SZVAVModel.MaxCoolAirMassFlow
        lowSpeedFanRatio = SZVAVModel.LowSpeedCoolFanRatio
        coilFluidInletNode = SZVAVModel.CoolCoilFluidInletNode
        coilFluidOutletNode = SZVAVModel.CoolCoilFluidOutletNodeNum
        coilPlantLoc = SZVAVModel.CoolCoilPlantLoc
        coilAirInletNode = SZVAVModel.CoolCoilInletNodeNum
        coilAirOutletNode = SZVAVModel.CoolCoilOutletNodeNum
    elif HeatingLoad:
        maxCoilFluidFlow = SZVAVModel.MaxHeatCoilFluidFlow
        maxOutletTemp = SZVAVModel.DesignMaxOutletTemp
        minAirMassFlow = SZVAVModel.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = SZVAVModel.MaxHeatAirMassFlow
        lowSpeedFanRatio = SZVAVModel.LowSpeedHeatFanRatio
        coilFluidInletNode = SZVAVModel.HeatCoilFluidInletNode
        coilFluidOutletNode = SZVAVModel.HeatCoilFluidOutletNodeNum
        coilPlantLoc = SZVAVModel.HeatCoilPlantLoc
        coilAirInletNode = SZVAVModel.HeatCoilInletNodeNum
        coilAirOutletNode = SZVAVModel.HeatCoilOutletNodeNum
    else:
        maxCoilFluidFlow = 0.0
        maxOutletTemp = 0.0
        minAirMassFlow = 0.0
        maxAirMassFlow = 0.0
        lowSpeedFanRatio = 0.0
        coilFluidInletNode = 0
        coilFluidOutletNode = 0
        coilPlantLoc = PlantLocation(0, DataPlant.LoopSideLocation.Invalid, 0, 0)
        coilAirInletNode = 0
        coilAirOutletNode = 0
    var InletNode: Int = SZVAVModel.AirInNode
    var InletTemp: Float64 = state.dataLoopNodes.Node[InletNode].Temp
    var OutletNode: Int = SZVAVModel.AirOutNode
    var ZoneTemp: Float64 = state.dataLoopNodes.Node[SZVAVModel.NodeNumOfControlledZone].Temp
    var ZoneHumRat: Float64 = state.dataLoopNodes.Node[SZVAVModel.NodeNumOfControlledZone].HumRat
    var lowWaterMdot: Float64 = 0.0
    if SZVAVModel.ATMixerExists:
        if SZVAVModel.ATMixerType == HVAC.MixerType.SupplySide:
            lowBoundaryLoad = minAirMassFlow * (Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[SZVAVModel.ATMixerOutNode].Temp, ZoneHumRat) - Psychrometrics.PsyHFnTdbW(ZoneTemp, ZoneHumRat))
        else:
            lowBoundaryLoad = minAirMassFlow * (Psychrometrics.PsyHFnTdbW(maxOutletTemp, ZoneHumRat) - Psychrometrics.PsyHFnTdbW(ZoneTemp, ZoneHumRat))
    else:
        minHumRat = min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
        lowBoundaryLoad = minAirMassFlow * (Psychrometrics.PsyHFnTdbW(maxOutletTemp, minHumRat) - Psychrometrics.PsyHFnTdbW(InletTemp, minHumRat))
    if (CoolingLoad and lowBoundaryLoad < ZoneLoad) or (HeatingLoad and lowBoundaryLoad > ZoneLoad):
        PartLoadRatio = 1.0
        SZVAVModel.FanPartLoadRatio = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRate = minAirMassFlow
        if coilPlantLoc.loopNum > 0:
            PlantUtilities.SetComponentFlowRate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
        if HeatingLoad:
            if SZVAVModel.MaxHeatCoilFluidFlow > 0.0:
                SZVAVModel.HeatCoilWaterFlowRatio = maxCoilFluidFlow / SZVAVModel.MaxHeatCoilFluidFlow
        FanCoilUnits.Calc4PipeFanCoil(state, SysIndex, SZVAVModel.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
        coilActive = abs(state.dataLoopNodes.Node[coilAirInletNode].Temp - state.dataLoopNodes.Node[coilAirOutletNode].Temp) > 0
        if not coilActive:
            if coilPlantLoc.loopNum > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
            return
        if (CoolingLoad and TempSensOutput < ZoneLoad) or (HeatingLoad and TempSensOutput > ZoneLoad):
            def f(PLR: Float64) -> Float64:
                return FanCoilUnits.CalcFanCoilWaterFlowResidual(state, PLR, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, SZVAVModel.AirInNode, coilFluidInletNode, maxCoilFluidFlow, minAirMassFlow)
            General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
            if SolFlag < 0:
                MessagePrefix = "Step 1: "
            if coilPlantLoc.loopNum > 0:
                PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
    else:
        highBoundaryLoad = lowBoundaryLoad * maxAirMassFlow / minAirMassFlow
        if (CoolingLoad and highBoundaryLoad < ZoneLoad) or (HeatingLoad and highBoundaryLoad > ZoneLoad):
            outletTemp = state.dataLoopNodes.Node[OutletNode].Temp
            minHumRat = state.dataLoopNodes.Node[SZVAVModel.NodeNumOfControlledZone].HumRat
            if outletTemp < ZoneTemp:
                minHumRat = state.dataLoopNodes.Node[OutletNode].HumRat
            outletTemp = maxOutletTemp
            AirMassFlow = min(maxAirMassFlow, ZoneLoad / (Psychrometrics.PsyHFnTdbW(outletTemp, minHumRat) - Psychrometrics.PsyHFnTdbW(ZoneTemp, minHumRat)))
            AirMassFlow = max(minAirMassFlow, AirMassFlow)
            SZVAVModel.FanPartLoadRatio = ((AirMassFlow - (maxAirMassFlow * lowSpeedFanRatio)) / ((1.0 - lowSpeedFanRatio) * maxAirMassFlow))
            state.dataLoopNodes.Node[InletNode].MassFlowRate = AirMassFlow
            if coilFluidInletNode > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = lowWaterMdot
            FanCoilUnits.Calc4PipeFanCoil(state, SysIndex, SZVAVModel.ControlZoneNum, FirstHVACIteration, TempSensOutput, 0.0)
            if (CoolingLoad and (TempSensOutput > ZoneLoad)) or (HeatingLoad and (TempSensOutput < ZoneLoad)):
                if coilFluidInletNode > 0:
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = maxCoilFluidFlow
                FanCoilUnits.Calc4PipeFanCoil(state, SysIndex, SZVAVModel.ControlZoneNum, FirstHVACIteration, TempSensOutput, 1.0)
                if coilPlantLoc.loopNum > 0:
                    PlantUtilities.SetComponentFlowRate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
                if (CoolingLoad and (TempSensOutput < ZoneLoad)) or (HeatingLoad and (TempSensOutput > ZoneLoad)):
                    if SZVAVModel.heatCoilType == HVAC.CoilType.HeatingWater or not HeatingLoad:
                        def f(PLR: Float64) -> Float64:
                            return FanCoilUnits.CalcFanCoilWaterFlowResidual(state, PLR, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, SZVAVModel.AirInNode, coilFluidInletNode, maxCoilFluidFlow, AirMassFlow)
                        General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                    else:
                        def f(PartLoadRatio: Float64) -> Float64:
                            return FanCoilUnits.CalcFanCoilLoadResidual(state, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, PartLoadRatio)
                        General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                    outletTemp = state.dataLoopNodes.Node[OutletNode].Temp
                    if (CoolingLoad and outletTemp < maxOutletTemp) or (HeatingLoad and outletTemp > maxOutletTemp):

                    if SolFlag < 0:
                        MessagePrefix = "Step 2: "
                else:
                    if SZVAVModel.heatCoilType == HVAC.CoilType.HeatingWater or not HeatingLoad:
                        def f(PLR: Float64) -> Float64:
                            return FanCoilUnits.CalcFanCoilWaterFlowResidual(state, PLR, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, SZVAVModel.AirInNode, coilFluidInletNode, maxCoilFluidFlow, minAirMassFlow)
                        General.SolveRoot(state, 0.001, MaxIter, SolFlag, lowWaterMdot, f, 0.0, 1.0)
                        var minFlow: Float64 = lowWaterMdot
                        if SolFlag < 0:
                            MessagePrefix = "Step 2a: "
                        else:
                            minFlow = 0.0
                        def f2(PLR: Float64) -> Float64:
                            return FanCoilUnits.CalcFanCoilAirAndWaterFlowResidual(state, PLR, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, SZVAVModel.AirInNode, coilFluidInletNode, minFlow)
                        General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f2, 0.0, 1.0)
                        if SolFlag < 0:
                            MessagePrefix = "Step 2b: "
                    else:
                        def f(PartLoadRatio: Float64) -> Float64:
                            return FanCoilUnits.CalcFanCoilLoadResidual(state, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, PartLoadRatio)
                        General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                        if SolFlag < 0:
                            MessagePrefix = "Step 2: "
            else:
                if SZVAVModel.heatCoilType == HVAC.CoilType.HeatingWater or not HeatingLoad:
                    def f2(PLR: Float64) -> Float64:
                        return FanCoilUnits.CalcFanCoilAirAndWaterFlowResidual(state, PLR, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, SZVAVModel.AirInNode, coilFluidInletNode, 0.0)
                    General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f2, 0.0, 1.0)
                else:
                    def f(PartLoadRatio: Float64) -> Float64:
                        return FanCoilUnits.CalcFanCoilLoadResidual(state, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, PartLoadRatio)
                    General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                if SolFlag < 0:
                    MessagePrefix = "Step 2c: "
        else:
            PartLoadRatio = 1.0
            SZVAVModel.FanPartLoadRatio = 1.0
            state.dataLoopNodes.Node[InletNode].MassFlowRate = maxAirMassFlow
            if coilPlantLoc.loopNum > 0:
                PlantUtilities.SetComponentFlowRate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
            if HeatingLoad:
                if SZVAVModel.MaxHeatCoilFluidFlow > 0.0:
                    SZVAVModel.HeatCoilWaterFlowRatio = maxCoilFluidFlow / SZVAVModel.MaxHeatCoilFluidFlow
            FanCoilUnits.Calc4PipeFanCoil(state, SysIndex, SZVAVModel.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
            coilActive = abs(state.dataLoopNodes.Node[coilAirInletNode].Temp - state.dataLoopNodes.Node[coilAirOutletNode].Temp) > 0
            if not coilActive:
                if coilPlantLoc.loopNum > 0:
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                    PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
                return
            if (CoolingLoad and ZoneLoad < TempSensOutput) or (HeatingLoad and ZoneLoad > TempSensOutput):
                return
            PartLoadRatio = 0.0
            if coilPlantLoc.loopNum > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
            FanCoilUnits.Calc4PipeFanCoil(state, SysIndex, SZVAVModel.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
            if (CoolingLoad and ZoneLoad < TempSensOutput) or (HeatingLoad and ZoneLoad > TempSensOutput):
                if SZVAVModel.heatCoilType == HVAC.CoilType.HeatingWater or not HeatingLoad:
                    def f(PLR: Float64) -> Float64:
                        return FanCoilUnits.CalcFanCoilWaterFlowResidual(state, PLR, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, SZVAVModel.AirInNode, coilFluidInletNode, maxCoilFluidFlow, maxAirMassFlow)
                    General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                else:
                    def f(PartLoadRatio: Float64) -> Float64:
                        return FanCoilUnits.CalcFanCoilLoadResidual(state, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, PartLoadRatio)
                    General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                if SolFlag < 0:
                    MessagePrefix = "Step 3: "
            else:
                if SZVAVModel.heatCoilType == HVAC.CoilType.HeatingWater or not HeatingLoad:
                    def f2(PLR: Float64) -> Float64:
                        return FanCoilUnits.CalcFanCoilAirAndWaterFlowResidual(state, PLR, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, SZVAVModel.AirInNode, coilFluidInletNode, 0.0)
                    General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f2, 0.0, 1.0)
                else:
                    def f(PartLoadRatio: Float64) -> Float64:
                        return FanCoilUnits.CalcFanCoilLoadResidual(state, SysIndex, FirstHVACIteration, SZVAVModel.ControlZoneNum, ZoneLoad, PartLoadRatio)
                    General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                if SolFlag < 0:
                    MessagePrefix = "Step 3a: "
            if coilPlantLoc.loopNum > 0:
                PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
    if SolFlag < 0:
        if SolFlag == -1:
            FanCoilUnits.Calc4PipeFanCoil(state, SysIndex, SZVAVModel.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
            if abs(TempSensOutput - ZoneLoad) * SZVAVModel.ControlZoneMassFlowFrac > 15.0:
                if SZVAVModel.MaxIterIndex == 0:
                    ShowWarningMessage(state, format("{}Coil control failed to converge for {}:{}", MessagePrefix, SZVAVModel.UnitType, SZVAVModel.Name))
                    ShowContinueError(state, "  Iteration limit exceeded in calculating system sensible part-load ratio.")
                    ShowContinueErrorTimeStamp(state, format("Sensible load to be met = {:.2f} (watts), sensible output = {:.2f} (watts), and the simulation continues.", ZoneLoad, TempSensOutput))
                ShowRecurringWarningErrorAtEnd(state, SZVAVModel.UnitType + " \"" + SZVAVModel.Name + "\" - Iteration limit exceeded in calculating sensible part-load ratio error continues. Sensible load statistics:", SZVAVModel.MaxIterIndex, ZoneLoad, ZoneLoad)
        elif SolFlag == -2:
            if SZVAVModel.RegulaFalsiFailedIndex == 0:
                ShowWarningMessage(state, format("{}Coil control failed for {}:{}", MessagePrefix, SZVAVModel.UnitType, SZVAVModel.Name))
                ShowContinueError(state, "  sensible part-load ratio determined to be outside the range of 0-1.")
                ShowContinueErrorTimeStamp(state, format("Sensible load to be met = {:.2f} (watts), and the simulation continues.", ZoneLoad))
            ShowRecurringWarningErrorAtEnd(state, SZVAVModel.UnitType + " \"" + SZVAVModel.Name + "\" - sensible part-load ratio out of range error continues. Sensible load statistics:", SZVAVModel.RegulaFalsiFailedIndex, ZoneLoad, ZoneLoad)

def calcSZVAVModel(
    inout state: EnergyPlusData,
    inout SZVAVModel: UnitarySystems.UnitarySys,
    FirstHVACIteration: Bool,
    CoolingLoad: Bool,
    HeatingLoad: Bool,
    ZoneLoad: Float64,
    inout OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool,
    AirLoopNum: Int,
    inout PartLoadRatio: Float64,
    CompressorONFlag: HVAC.CompressorOp
):
    var MaxIter: Int = 100
    var SolFlag: Int = 0
    var MessagePrefix: String = ""
    var boundaryLoadMet: Float64 = 0.0
    var minHumRat: Float64 = 0.0
    var outletTemp: Float64 = 0.0
    var coilActive: Bool = False
    var AirMassFlow: Float64 = 0.0
    var maxCoilFluidFlow: Float64 = 0.0
    var maxOutletTemp: Float64 = 0.0
    var minAirMassFlow: Float64 = 0.0
    var maxAirMassFlow: Float64 = 0.0
    var lowSpeedFanRatio: Float64 = 0.0
    var coilFluidInletNode: Int = 0
    var coilFluidOutletNode: Int = 0
    var coilPlantLoc: PlantLocation = PlantLocation()
    var coilAirInletNode: Int = 0
    var coilAirOutletNode: Int = 0
    var HeatCoilLoad: Float64 = 0.0
    var SupHeaterLoad: Float64 = 0.0
    var iterWaterAirOrNot: Bool = False
    var TempSensOutput: Float64 = 0.0
    var TempLatOutput: Float64 = 0.0
    if CoolingLoad:
        maxCoilFluidFlow = SZVAVModel.MaxCoolCoilFluidFlow
        maxOutletTemp = SZVAVModel.DesignMinOutletTemp
        minAirMassFlow = SZVAVModel.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = SZVAVModel.MaxCoolAirMassFlow
        lowSpeedFanRatio = SZVAVModel.LowSpeedCoolFanRatio
        coilFluidInletNode = SZVAVModel.CoolCoilFluidInletNode
        coilFluidOutletNode = SZVAVModel.CoolCoilFluidOutletNodeNum
        coilPlantLoc = SZVAVModel.CoolCoilPlantLoc
        coilAirInletNode = SZVAVModel.CoolCoilInletNodeNum
        coilAirOutletNode = SZVAVModel.CoolCoilOutletNodeNum
    elif HeatingLoad:
        maxCoilFluidFlow = SZVAVModel.MaxHeatCoilFluidFlow
        maxOutletTemp = SZVAVModel.DesignMaxOutletTemp
        minAirMassFlow = SZVAVModel.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = SZVAVModel.MaxHeatAirMassFlow
        lowSpeedFanRatio = SZVAVModel.LowSpeedHeatFanRatio
        coilFluidInletNode = SZVAVModel.HeatCoilFluidInletNode
        coilFluidOutletNode = SZVAVModel.HeatCoilFluidOutletNodeNum
        coilPlantLoc = SZVAVModel.HeatCoilPlantLoc
        coilAirInletNode = SZVAVModel.HeatCoilInletNodeNum
        coilAirOutletNode = SZVAVModel.HeatCoilOutletNodeNum
    else:
        maxCoilFluidFlow = 0.0
        maxOutletTemp = 0.0
        minAirMassFlow = 0.0
        maxAirMassFlow = 0.0
        lowSpeedFanRatio = 0.0
        coilFluidInletNode = 0
        coilFluidOutletNode = 0
        coilPlantLoc = PlantLocation(0, DataPlant.LoopSideLocation.Invalid, 0, 0)
        coilAirInletNode = 0
        coilAirOutletNode = 0
    var InletNode: Int = SZVAVModel.AirInNode
    var InletTemp: Float64 = state.dataLoopNodes.Node[InletNode].Temp
    var OutletNode: Int = SZVAVModel.AirOutNode
    var ZoneTemp: Float64 = state.dataLoopNodes.Node[SZVAVModel.NodeNumOfControlledZone].Temp
    var ZoneHumRat: Float64 = state.dataLoopNodes.Node[SZVAVModel.NodeNumOfControlledZone].HumRat
    SZVAVModel.m_SimASHRAEModelOn = True
    if SZVAVModel.ATMixerExists:
        if SZVAVModel.ATMixerType == HVAC.MixerType.SupplySide:
            boundaryLoadMet = minAirMassFlow * (Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[SZVAVModel.ATMixerOutNode].Temp, ZoneHumRat) - Psychrometrics.PsyHFnTdbW(ZoneTemp, ZoneHumRat))
        else:
            boundaryLoadMet = minAirMassFlow * (Psychrometrics.PsyHFnTdbW(maxOutletTemp, ZoneHumRat) - Psychrometrics.PsyHFnTdbW(ZoneTemp, ZoneHumRat))
    else:
        minHumRat = min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
        boundaryLoadMet = minAirMassFlow * (Psychrometrics.PsyHFnTdbW(maxOutletTemp, minHumRat) - Psychrometrics.PsyHFnTdbW(InletTemp, minHumRat))
    if (CoolingLoad and boundaryLoadMet < ZoneLoad) or (HeatingLoad and boundaryLoadMet > ZoneLoad):
        PartLoadRatio = 1.0
        SZVAVModel.FanPartLoadRatio = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRate = minAirMassFlow
        if coilPlantLoc.loopNum > 0:
            PlantUtilities.SetComponentFlowRate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
        if CoolingLoad:
            if SZVAVModel.MaxCoolCoilFluidFlow > 0.0:
                SZVAVModel.CoolCoilWaterFlowRatio = maxCoilFluidFlow / SZVAVModel.MaxCoolCoilFluidFlow
            SZVAVModel.calcUnitarySystemToLoad(state, AirLoopNum, FirstHVACIteration, PartLoadRatio, 0.0, OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn, HeatCoilLoad, SupHeaterLoad, CompressorONFlag)
        else:
            if SZVAVModel.MaxHeatCoilFluidFlow > 0.0:
                SZVAVModel.HeatCoilWaterFlowRatio = maxCoilFluidFlow / SZVAVModel.MaxHeatCoilFluidFlow
            SZVAVModel.calcUnitarySystemToLoad(state, AirLoopNum, FirstHVACIteration, 0.0, PartLoadRatio, OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn, ZoneLoad, SupHeaterLoad, CompressorONFlag)
        coilActive = abs(state.dataLoopNodes.Node[coilAirInletNode].Temp - state.dataLoopNodes.Node[coilAirOutletNode].Temp) > 0
        if not coilActive:
            if coilPlantLoc.loopNum > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
            return
        if (CoolingLoad and TempSensOutput < ZoneLoad) or (HeatingLoad and TempSensOutput > ZoneLoad):
            def fR1(PartLoadRatio: Float64) -> Float64:
                return SZVAVModel.calcUnitarySystemWaterFlowResidual(state, PartLoadRatio, FirstHVACIteration, ZoneLoad, SZVAVModel.AirInNode, OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow, lowSpeedFanRatio, minAirMassFlow, 0.0, maxAirMassFlow, CoolingLoad, iterWaterAirOrNot)
            General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, fR1, 0.0, 1.0)
            if SolFlag < 0:
                MessagePrefix = "Step 1: "
            if coilPlantLoc.loopNum > 0:
                PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
    else:
        boundaryLoadMet *= maxAirMassFlow / minAirMassFlow
        if (CoolingLoad and boundaryLoadMet < ZoneLoad) or (HeatingLoad and boundaryLoadMet > ZoneLoad):
            iterWaterAirOrNot = True
            outletTemp = state.dataLoopNodes.Node[OutletNode].Temp
            minHumRat = state.dataLoopNodes.Node[SZVAVModel.NodeNumOfControlledZone].HumRat
            if outletTemp < ZoneTemp:
                minHumRat = state.dataLoopNodes.Node[OutletNode].HumRat
            outletTemp = maxOutletTemp
            AirMassFlow = min(maxAirMassFlow, ZoneLoad / (Psychrometrics.PsyHFnTdbW(outletTemp, minHumRat) - Psychrometrics.PsyHFnTdbW(ZoneTemp, minHumRat)))
            AirMassFlow = max(minAirMassFlow, AirMassFlow)
            SZVAVModel.FanPartLoadRatio = ((AirMassFlow - (maxAirMassFlow * lowSpeedFanRatio)) / ((1.0 - lowSpeedFanRatio) * maxAirMassFlow))
            def fR2(PartLoadRatio: Float64) -> Float64:
                return SZVAVModel.calcUnitarySystemWaterFlowResidual(state, PartLoadRatio, FirstHVACIteration, ZoneLoad, SZVAVModel.AirInNode, OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow, lowSpeedFanRatio, AirMassFlow, 0.0, maxAirMassFlow, CoolingLoad, iterWaterAirOrNot)
            General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, fR2, 0.0, 1.0)
            if SolFlag == -2 and ((CoolingLoad and SZVAVModel.m_CoolingSpeedNum < SZVAVModel.m_NumOfSpeedCooling) or (HeatingLoad and SZVAVModel.m_HeatingSpeedNum < SZVAVModel.m_NumOfSpeedHeating)):
                var szVAVModelSpeed: Int = 0
                var szVAVModelSpeedMax: Int = 0
                if CoolingLoad:
                    szVAVModelSpeed = SZVAVModel.m_CoolingSpeedNum + 1
                    szVAVModelSpeedMax = SZVAVModel.m_NumOfSpeedCooling
                else:
                    szVAVModelSpeed = SZVAVModel.m_HeatingSpeedNum + 1
                    szVAVModelSpeedMax = SZVAVModel.m_NumOfSpeedHeating
                for szVAVSpeed in range(szVAVModelSpeed, szVAVModelSpeedMax + 1):
                    if CoolingLoad:
                        SZVAVModel.m_CoolingSpeedNum = szVAVSpeed
                    else:
                        SZVAVModel.m_HeatingSpeedNum = szVAVSpeed
                    def f(PartLoadRatio: Float64) -> Float64:
                        return SZVAVModel.calcUnitarySystemWaterFlowResidual(state, PartLoadRatio, FirstHVACIteration, ZoneLoad, SZVAVModel.AirInNode, OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow, lowSpeedFanRatio, AirMassFlow, 0.0, maxAirMassFlow, CoolingLoad, iterWaterAirOrNot)
                    General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                    if SolFlag > 0:
                        break
                if SolFlag < 0:
                    MessagePrefix = "Step 2: "
        else:
            PartLoadRatio = 1.0
            SZVAVModel.FanPartLoadRatio = 1.0
            state.dataLoopNodes.Node[InletNode].MassFlowRate = maxAirMassFlow
            if coilPlantLoc.loopNum > 0:
                PlantUtilities.SetComponentFlowRate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
            if CoolingLoad:
                if SZVAVModel.MaxCoolCoilFluidFlow > 0.0:
                    SZVAVModel.CoolCoilWaterFlowRatio = maxCoilFluidFlow / SZVAVModel.MaxCoolCoilFluidFlow
                SZVAVModel.calcUnitarySystemToLoad(state, AirLoopNum, FirstHVACIteration, PartLoadRatio, 0.0, OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn, HeatCoilLoad, SupHeaterLoad, CompressorONFlag)
            else:
                if SZVAVModel.MaxHeatCoilFluidFlow > 0.0:
                    SZVAVModel.HeatCoilWaterFlowRatio = maxCoilFluidFlow / SZVAVModel.MaxHeatCoilFluidFlow
                SZVAVModel.calcUnitarySystemToLoad(state, AirLoopNum, FirstHVACIteration, 0.0, PartLoadRatio, OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn, ZoneLoad, SupHeaterLoad, CompressorONFlag)
            coilActive = abs(state.dataLoopNodes.Node[coilAirInletNode].Temp - state.dataLoopNodes.Node[coilAirOutletNode].Temp) > 0
            if not coilActive:
                if coilPlantLoc.loopNum > 0:
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                    PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
                return
            if (CoolingLoad and ZoneLoad < TempSensOutput) or (HeatingLoad and ZoneLoad > TempSensOutput):
                return
            iterWaterAirOrNot = False
            def fR3(PartLoadRatio: Float64) -> Float64:
                return SZVAVModel.calcUnitarySystemWaterFlowResidual(state, PartLoadRatio, FirstHVACIteration, ZoneLoad, SZVAVModel.AirInNode, OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow, lowSpeedFanRatio, maxAirMassFlow, 0.0, maxAirMassFlow, CoolingLoad, iterWaterAirOrNot)
            General.SolveRoot(state, 0.001, MaxIter, SolFlag, PartLoadRatio, fR3, 0.0, 1.0)
            if SolFlag < 0:
                MessagePrefix = "Step 3: "
        if coilPlantLoc.loopNum > 0:
            PlantUtilities.SetComponentFlowRate(state, state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
    if SolFlag < 0:
        if SolFlag == -1:
            if CoolingLoad:
                SZVAVModel.calcUnitarySystemToLoad(state, AirLoopNum, FirstHVACIteration, PartLoadRatio, 0.0, OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn, HeatCoilLoad, SupHeaterLoad, CompressorONFlag)
            else:
                SZVAVModel.calcUnitarySystemToLoad(state, AirLoopNum, FirstHVACIteration, 0.0, PartLoadRatio, OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn, ZoneLoad, SupHeaterLoad, CompressorONFlag)
            if abs(TempSensOutput - ZoneLoad) * SZVAVModel.ControlZoneMassFlowFrac > 15.0:
                if SZVAVModel.MaxIterIndex == 0:
                    ShowWarningMessage(state, format("{}Coil control failed to converge for {}:{}", MessagePrefix, SZVAVModel.UnitType, SZVAVModel.Name))
                    ShowContinueError(state, "  Iteration limit exceeded in calculating system sensible part-load ratio.")
                    ShowContinueErrorTimeStamp(state, format("Sensible load to be met = {:.2f} (watts), sensible output = {:.2f} (watts), and the simulation continues.", ZoneLoad, TempSensOutput))
                ShowRecurringWarningErrorAtEnd(state, SZVAVModel.UnitType + " \"" + SZVAVModel.Name + "\" - Iteration limit exceeded in calculating sensible part-load ratio error continues. Sensible load statistics:", SZVAVModel.MaxIterIndex, ZoneLoad, ZoneLoad)
        elif SolFlag == -2:
            if SZVAVModel.RegulaFalsiFailedIndex == 0:
                ShowWarningMessage(state, format("{}Coil control failed for {}:{}", MessagePrefix, SZVAVModel.UnitType, SZVAVModel.Name))
                ShowContinueError(state, "  sensible part-load ratio determined to be outside the range of 0-1.")
                ShowContinueErrorTimeStamp(state, format("Sensible load to be met = {:.2f} (watts), and the simulation continues.", ZoneLoad))
            ShowRecurringWarningErrorAtEnd(state, SZVAVModel.UnitType + " \"" + SZVAVModel.Name + "\" - sensible part-load ratio out of range error continues. Sensible load statistics:", SZVAVModel.RegulaFalsiFailedIndex, ZoneLoad, ZoneLoad)
from dataclasses import dataclass, field
from enum import Enum
from typing import Protocol, Optional, Any
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData.dataCHPElectGen: mutable container for NumMicroCHPs, NumMicroCHPParams, MicroCHP[], MicroCHPParamInput[], getMicroCHPInputFlag, MyOneTimeFlag, MyEnvrnFlag
# - EnergyPlusData.dataIPShortCut: cCurrentModuleObject, lAlphaFieldBlanks, cAlphaFieldNames, cNumericFieldNames
# - EnergyPlusData.dataInputProcessing.inputProcessor: getNumObjectsFound, getObjectItem
# - EnergyPlusData.dataHeatBal.Zone: zone list for FindItemInList
# - EnergyPlusData.dataLoopNodes.Node: node array with Temp, MassFlowRate, Enthalpy
# - EnergyPlusData.dataGenerator: FuelSupply[], GeneratorDynamics[], Generator functions
# - EnergyPlusData.dataHVACGlobal: TimeStepSysSec, TimeStepSys, SysTimeElapsed
# - EnergyPlusData.dataGlobal: HourOfDay, TimeStep, TimeStepZone, BeginEnvrnFlag, SysSizingCalc
# - EnergyPlusData.dataZoneTempPredictorCorrector.zoneHeatBalance: zone temperature data
# - EnergyPlusData.dataEnvrn.OutDryBulbTemp: outdoor temperature
# - EnergyPlusData.dataSize.PlantSizData: plant sizing data
# - EnergyPlusData.dataPlnt.PlantLoop, PlantFirstSizesOkayToFinalize: plant loop data
# - Curve.GetCurve: fetch curve object
# - Sched.GetSchedule, GetScheduleAlwaysOn: fetch schedule
# - Node.GetOnlySingleNode, TestCompSet: node utilities
# - PlantUtilities: UpdateComponentHeatRecoverySide, InitComponentNodes, SetComponentFlowRate, RegisterPlantDesignFlow, SafeCopyPlantNode, ScanPlantLoopsForObject
# - GeneratorDynamicsManager: ManageGeneratorControlState, ManageGeneratorFuelFlow, FuncDetermineCWMdotForInternalFlowControl, SetupGeneratorControlStateManager
# - GeneratorFuelSupply.GetGeneratorFuelSupplyInput: fuel supply setup
# - OutputProcessor, ScheduleManager, BranchNodeConnections, CurveManager, FluidProperties, HeatBalanceInternalHeatGains, UtilityRoutines: output and utility functions
# - Constant: unit enums, eResource, Group, EndUseCat, MaxEXPArg, rSecsInHour
# - DataHeatBalance.IntGainType: zone gain type enum
# - DataPlant: PlantEquipmentType, LoopFlowStatus, LoopSideLocation enums
# - Node.ConnectionObjectType, ConnectionType, FluidType, CompFluidStream: node connection enums
# - ZoneTempPredictorCorrector.SetupZoneInternalGain: zone gain setup
# - ShowFatalError, ShowSevereError, ShowSevereEmptyField, ShowSevereItemNotFound, ShowContinueError, format: error reporting
# - Util: SameString, FindItemInList: string utilities
# - EnergyPlus.PlantComponent: base class for plant components


class OperatingMode(Enum):
    """DataGenerators::OperatingMode"""
    Invalid = -1
    Off = 0
    Standby = 1
    WarmUp = 2
    Normal = 3
    CoolDown = 4


class LoopSideLocation(Enum):
    """DataPlant::LoopSideLocation"""
    Supply = 1
    Demand = 2


@dataclass
class MicroCHPParamsNonNormalized:
    """Parameters for Micro CHP generator without normalization"""
    Name: str = ""
    MaxElecPower: float = 0.0
    MinElecPower: float = 0.0
    MinWaterMdot: float = 0.0
    MaxWaterTemp: float = 0.0
    ElecEffCurve: Optional[Any] = None
    ThermalEffCurve: Optional[Any] = None
    InternalFlowControl: bool = False
    PlantFlowControl: bool = True
    WaterFlowCurve: Optional[Any] = None
    AirFlowCurve: Optional[Any] = None
    DeltaPelMax: float = 0.0
    DeltaFuelMdotMax: float = 0.0
    UAhx: float = 0.0
    UAskin: float = 0.0
    RadiativeFraction: float = 0.0
    MCeng: float = 0.0
    MCcw: float = 0.0
    Pstandby: float = 0.0
    WarmUpByTimeDelay: bool = False
    WarmUpByEngineTemp: bool = True
    kf: float = 0.0
    TnomEngOp: float = 0.0
    kp: float = 0.0
    Rfuelwarmup: float = 0.0
    WarmUpDelay: float = 0.0
    PcoolDown: float = 0.0
    CoolDownDelay: float = 0.0
    MandatoryFullCoolDown: bool = False
    WarmRestartOkay: bool = True
    TimeElapsed: float = 0.0
    OpMode: OperatingMode = field(default_factory=lambda: OperatingMode.Invalid)
    OffModeTime: float = 0.0
    StandyByModeTime: float = 0.0
    WarmUpModeTime: float = 0.0
    NormalModeTime: float = 0.0
    CoolDownModeTime: float = 0.0
    TengLast: float = 20.0
    TempCWOutLast: float = 20.0
    Pnet: float = 0.0
    ElecEff: float = 0.0
    Qgross: float = 0.0
    ThermEff: float = 0.0
    Qgenss: float = 0.0
    NdotFuel: float = 0.0
    MdotFuel: float = 0.0
    Teng: float = 20.0
    TcwIn: float = 20.0
    TcwOut: float = 20.0
    MdotAir: float = 0.0
    QdotSkin: float = 0.0
    QdotConvZone: float = 0.0
    QdotRadZone: float = 0.0
    ACPowerGen: float = 0.0
    ACEnergyGen: float = 0.0
    QdotHX: float = 0.0
    QdotHR: float = 0.0
    TotalHeatEnergyRec: float = 0.0
    FuelEnergyLHV: float = 0.0
    FuelEnergyUseRateLHV: float = 0.0
    FuelEnergyHHV: float = 0.0
    FuelEnergyUseRateHHV: float = 0.0
    HeatRecInletTemp: float = 0.0
    HeatRecOutletTemp: float = 0.0
    FuelCompressPower: float = 0.0
    FuelCompressEnergy: float = 0.0
    FuelCompressSkinLoss: float = 0.0
    SkinLossPower: float = 0.0
    SkinLossEnergy: float = 0.0
    SkinLossConvect: float = 0.0
    SkinLossRadiat: float = 0.0


@dataclass
class MicroCHPDataStruct:
    """Micro CHP Generator data structure"""
    Name: str = ""
    ParamObjName: str = ""
    A42Model: MicroCHPParamsNonNormalized = field(default_factory=MicroCHPParamsNonNormalized)
    NomEff: float = 0.0
    ZoneName: str = ""
    ZoneID: int = 0
    PlantInletNodeName: str = ""
    PlantInletNodeID: int = 0
    PlantOutletNodeName: str = ""
    PlantOutletNodeID: int = 0
    PlantMassFlowRate: float = 0.0
    PlantMassFlowRateMax: float = 0.0
    PlantMassFlowRateMaxWasAutoSized: bool = False
    AirInletNodeName: str = ""
    AirInletNodeID: int = 0
    AirOutletNodeName: str = ""
    AirOutletNodeID: int = 0
    FuelSupplyID: int = 0
    DynamicsControlID: int = 0
    availSched: Optional[Any] = None
    CWPlantLoc: Optional[Any] = None
    CheckEquipName: bool = True
    MySizeFlag: bool = True
    MyEnvrnFlag: bool = True
    MyPlantScanFlag: bool = True
    myFlag: bool = True

    def simulate(self, state: Any, calledFromLocation: Any, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        """Simulate plant component"""
        # Update component heat recovery side
        if hasattr(state, 'dataLoopNodes'):
            PlantUtilities_UpdateComponentHeatRecoverySide(
                state, self.CWPlantLoc.loopNum, self.CWPlantLoc.loopSideNum,
                self.PlantInletNodeID, self.PlantOutletNodeID,
                self.A42Model.QdotHR, self.A42Model.HeatRecInletTemp,
                self.A42Model.HeatRecOutletTemp, self.PlantMassFlowRate,
                FirstHVACIteration
            )

    def getDesignCapacities(self, state: Any, calledFromLocation: Any) -> tuple:
        """Get design capacities"""
        MaxLoad = state.dataGenerator.GeneratorDynamics[self.DynamicsControlID].QdotHXMax
        MinLoad = state.dataGenerator.GeneratorDynamics[self.DynamicsControlID].QdotHXMin
        OptLoad = state.dataGenerator.GeneratorDynamics[self.DynamicsControlID].QdotHXOpt
        return MaxLoad, MinLoad, OptLoad

    def onInitLoopEquip(self, state: Any, calledFromLocation: Any) -> None:
        """Initialize loop equipment"""
        rho = self.CWPlantLoc.loop.glycol.getDensity(
            state, state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
        )
        
        if self.A42Model.InternalFlowControl:
            self.PlantMassFlowRateMax = (
                2.0 * self.A42Model.WaterFlowCurve.value(
                    state, self.A42Model.MaxElecPower,
                    state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
                )
            )
        elif self.CWPlantLoc.loopSideNum == LoopSideLocation.Supply:
            if self.CWPlantLoc.loop.MaxMassFlowRate > 0.0:
                self.PlantMassFlowRateMax = self.CWPlantLoc.loop.MaxMassFlowRate
            elif self.CWPlantLoc.loop.PlantSizNum > 0:
                self.PlantMassFlowRateMax = (
                    state.dataSize.PlantSizData[self.CWPlantLoc.loopNum].DesVolFlowRate * rho
                )
            else:
                self.PlantMassFlowRateMax = 2.0
        elif self.CWPlantLoc.loopSideNum == LoopSideLocation.Demand:
            self.PlantMassFlowRateMax = 2.0

        PlantUtilities_RegisterPlantCompDesignFlow(
            state, self.PlantInletNodeID, self.PlantMassFlowRateMax / rho
        )

        self.A42Model.ElecEff = self.A42Model.ElecEffCurve.value(
            state, self.A42Model.MaxElecPower, self.PlantMassFlowRateMax,
            state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
        )

        self.A42Model.ThermEff = self.A42Model.ThermalEffCurve.value(
            state, self.A42Model.MaxElecPower, self.PlantMassFlowRateMax,
            state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
        )

        GeneratorDynamicsManager_SetupGeneratorControlStateManager(state, self.DynamicsControlID)

    def setupOutputVars(self, state: Any) -> None:
        """Setup output variables for reporting"""
        # Placeholder: would call SetupOutputVariable for each variable
        pass

    def InitMicroCHPNoNormalizeGenerators(self, state: Any) -> None:
        """Initialize Micro CHP generators"""
        self.oneTimeInit(state)

        if not state.dataGlobal.SysSizingCalc and self.MySizeFlag and not self.MyPlantScanFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
            self.MySizeFlag = False

        if self.MySizeFlag:
            return

        DynaCntrlNum = self.DynamicsControlID

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            self.A42Model.TengLast = 20.0
            self.A42Model.TempCWOutLast = 20.0
            self.A42Model.TimeElapsed = 0.0
            self.A42Model.OpMode = OperatingMode.Invalid
            self.A42Model.OffModeTime = 0.0
            self.A42Model.StandyByModeTime = 0.0
            self.A42Model.WarmUpModeTime = 0.0
            self.A42Model.NormalModeTime = 0.0
            self.A42Model.CoolDownModeTime = 0.0
            self.A42Model.Pnet = 0.0
            self.A42Model.ElecEff = 0.0
            self.A42Model.Qgross = 0.0
            self.A42Model.ThermEff = 0.0
            self.A42Model.Qgenss = 0.0
            self.A42Model.NdotFuel = 0.0
            self.A42Model.MdotFuel = 0.0
            self.A42Model.Teng = 20.0
            self.A42Model.TcwIn = 20.0
            self.A42Model.TcwOut = 20.0
            self.A42Model.MdotAir = 0.0
            self.A42Model.QdotSkin = 0.0
            self.A42Model.QdotConvZone = 0.0
            self.A42Model.QdotRadZone = 0.0
            
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].LastOpMode = OperatingMode.Off
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].CurrentOpMode = OperatingMode.Off
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FractionalDayofLastShutDown = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FractionalDayofLastStartUp = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].HasBeenOn = False
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].DuringStartUp = False
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].DuringShutDown = False
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FuelMdotLastTimestep = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].PelLastTimeStep = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].NumCycles = 0

            state.dataGenerator.FuelSupply[self.FuelSupplyID].QskinLoss = 0.0

            PlantUtilities_InitComponentNodes(
                state, 0.0, self.PlantMassFlowRateMax,
                self.PlantInletNodeID, self.PlantOutletNodeID
            )

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        TimeElapsed = (state.dataGlobal.HourOfDay + state.dataGlobal.TimeStep *
                      state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed)
        
        if self.A42Model.TimeElapsed != TimeElapsed:
            self.A42Model.TengLast = self.A42Model.Teng
            self.A42Model.TempCWOutLast = self.A42Model.TcwOut
            self.A42Model.TimeElapsed = TimeElapsed
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].LastOpMode = state.dataGenerator.GeneratorDynamics[DynaCntrlNum].CurrentOpMode
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FuelMdotLastTimestep = self.A42Model.MdotFuel
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].PelLastTimeStep = self.A42Model.Pnet

        if not self.A42Model.InternalFlowControl:
            mdot = self.PlantMassFlowRateMax
            PlantUtilities_SetComponentFlowRate(
                state, mdot, self.PlantInletNodeID, self.PlantOutletNodeID, self.CWPlantLoc
            )
            self.PlantMassFlowRate = mdot

    def CalcMicroCHPNoNormalizeGeneratorModel(
        self, state: Any, RunFlagElectCenter: bool, RunFlagPlant: bool,
        MyElectricLoad: float, MyThermalLoad: float
    ) -> None:
        """Main calculation for Micro CHP generator"""
        CurrentOpMode = OperatingMode.Invalid
        NdotFuel = 0.0
        AllowedLoad = 0.0
        PLRforSubtimestepStartUp = 1.0
        PLRforSubtimestepShutDown = 0.0

        GeneratorDynamicsManager_ManageGeneratorControlState(
            state, self.DynamicsControlID, RunFlagElectCenter, RunFlagPlant,
            MyElectricLoad, MyThermalLoad, AllowedLoad, CurrentOpMode,
            PLRforSubtimestepStartUp, PLRforSubtimestepShutDown
        )

        Teng = self.A42Model.Teng
        TcwOut = self.A42Model.TcwOut

        if self.ZoneID > 0:
            thisAmbientTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.ZoneID].MAT
        else:
            thisAmbientTemp = state.dataEnvrn.OutDryBulbTemp

        Pnetss = 0.0
        Pstandby = 0.0
        Pcooler = 0.0
        ElecEff = 0.0
        MdotAir = 0.0
        Qgenss = 0.0
        MdotCW = 0.0
        TcwIn = 0.0
        MdotFuel = 0.0
        Qgross = 0.0
        ThermEff = 0.0

        if CurrentOpMode == OperatingMode.Off:
            Qgenss = 0.0
            TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
            Pnetss = 0.0
            Pstandby = 0.0
            Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
            ElecEff = 0.0
            ThermEff = 0.0
            Qgross = 0.0
            NdotFuel = 0.0
            MdotFuel = 0.0
            MdotAir = 0.0
            MdotCW = 0.0
            PlantUtilities_SetComponentFlowRate(
                state, MdotCW, self.PlantInletNodeID, self.PlantOutletNodeID, self.CWPlantLoc
            )
            self.PlantMassFlowRate = MdotCW

        elif CurrentOpMode == OperatingMode.Standby:
            Qgenss = 0.0
            TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
            Pnetss = 0.0
            Pstandby = self.A42Model.Pstandby * (1.0 - PLRforSubtimestepShutDown)
            Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
            ElecEff = 0.0
            ThermEff = 0.0
            Qgross = 0.0
            NdotFuel = 0.0
            MdotFuel = 0.0
            MdotAir = 0.0
            MdotCW = 0.0
            PlantUtilities_SetComponentFlowRate(
                state, MdotCW, self.PlantInletNodeID, self.PlantOutletNodeID, self.CWPlantLoc
            )
            self.PlantMassFlowRate = MdotCW

        elif CurrentOpMode == OperatingMode.WarmUp:
            if self.A42Model.WarmUpByTimeDelay:
                Pnetss = MyElectricLoad
                Pstandby = 0.0
                Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
                TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
                MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
                
                if self.A42Model.InternalFlowControl:
                    MdotCW = GeneratorDynamicsManager_FuncDetermineCWMdotForInternalFlowControl(
                        state, self.DynamicsControlID, Pnetss, TcwIn
                    )
                
                ElecEff = self.A42Model.ElecEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                ElecEff = max(0.0, ElecEff)

                if ElecEff > 0.0:
                    Qgross = Pnetss / ElecEff
                else:
                    Qgross = 0.0

                ThermEff = self.A42Model.ThermalEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                ThermEff = max(0.0, ThermEff)
                Qgenss = ThermEff * Qgross

                MdotFuel = (Qgross / (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0) *
                           state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec)

                ConstrainedIncreasingNdot = False
                ConstrainedDecreasingNdot = False
                MdotFuelAllowed = 0.0

                GeneratorDynamicsManager_ManageGeneratorFuelFlow(
                    state, self.DynamicsControlID, MdotFuel, MdotFuelAllowed,
                    ConstrainedIncreasingNdot, ConstrainedDecreasingNdot
                )

                if ConstrainedIncreasingNdot or ConstrainedDecreasingNdot:
                    MdotFuel = MdotFuelAllowed
                    NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                    Qgross = NdotFuel * (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)

                    for i in range(20):
                        Pnetss = Qgross * ElecEff
                        if self.A42Model.InternalFlowControl:
                            MdotCW = GeneratorDynamicsManager_FuncDetermineCWMdotForInternalFlowControl(
                                state, self.DynamicsControlID, Pnetss, TcwIn
                            )
                        ElecEff = self.A42Model.ElecEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                        ElecEff = max(0.0, ElecEff)

                    ThermEff = self.A42Model.ThermalEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                    ThermEff = max(0.0, ThermEff)
                    Qgenss = ThermEff * Qgross

                Pnetss = 0.0
                NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                MdotAir = self.A42Model.AirFlowCurve.value(state, MdotFuel)
                MdotAir = max(0.0, MdotAir)

            elif self.A42Model.WarmUpByEngineTemp:
                Pmax = self.A42Model.MaxElecPower
                Pstandby = 0.0
                Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
                TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
                MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
                ElecEff = self.A42Model.ElecEffCurve.value(state, Pmax, MdotCW, TcwIn)
                ElecEff = max(0.0, ElecEff)
                
                if ElecEff > 0.0:
                    Qgross = Pmax / ElecEff
                else:
                    Qgross = 0.0

                NdotFuel = Qgross / (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)
                MdotFuelMax = NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec

                if Teng > thisAmbientTemp:
                    MdotFuelWarmup = (MdotFuelMax + self.A42Model.kf * MdotFuelMax *
                                     ((self.A42Model.TnomEngOp - thisAmbientTemp) / (Teng - thisAmbientTemp)))
                    if MdotFuelWarmup > self.A42Model.Rfuelwarmup * MdotFuelMax:
                        MdotFuelWarmup = self.A42Model.Rfuelwarmup * MdotFuelMax
                else:
                    MdotFuelWarmup = self.A42Model.Rfuelwarmup * MdotFuelMax

                if self.A42Model.TnomEngOp > thisAmbientTemp:
                    Pnetss = Pmax * self.A42Model.kp * ((Teng - thisAmbientTemp) / (self.A42Model.TnomEngOp - thisAmbientTemp))
                else:
                    Pnetss = Pmax

                MdotFuel = MdotFuelWarmup
                NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                MdotAir = self.A42Model.AirFlowCurve.value(state, MdotFuelWarmup)
                MdotAir = max(0.0, MdotAir)
                Qgross = NdotFuel * (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)
                ThermEff = self.A42Model.ThermalEffCurve.value(state, Pmax, MdotCW, TcwIn)
                Qgenss = ThermEff * Qgross

        elif CurrentOpMode == OperatingMode.Normal:
            if PLRforSubtimestepStartUp < 1.0:
                if RunFlagElectCenter:
                    Pnetss = MyElectricLoad
                if RunFlagPlant:
                    Pnetss = AllowedLoad
            else:
                Pnetss = AllowedLoad
            
            Pstandby = 0.0
            Pcooler = 0.0
            TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
            MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
            
            if self.A42Model.InternalFlowControl:
                MdotCW = GeneratorDynamicsManager_FuncDetermineCWMdotForInternalFlowControl(
                    state, self.DynamicsControlID, Pnetss, TcwIn
                )

            ElecEff = self.A42Model.ElecEffCurve.value(state, Pnetss, MdotCW, TcwIn)
            ElecEff = max(0.0, ElecEff)

            if ElecEff > 0.0:
                Qgross = Pnetss / ElecEff
            else:
                Qgross = 0.0

            ThermEff = self.A42Model.ThermalEffCurve.value(state, Pnetss, MdotCW, TcwIn)
            ThermEff = max(0.0, ThermEff)
            Qgenss = ThermEff * Qgross
            MdotFuel = (Qgross / (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0) *
                       state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec)

            ConstrainedIncreasingNdot = False
            ConstrainedDecreasingNdot = False
            MdotFuelAllowed = 0.0

            GeneratorDynamicsManager_ManageGeneratorFuelFlow(
                state, self.DynamicsControlID, MdotFuel, MdotFuelAllowed,
                ConstrainedIncreasingNdot, ConstrainedDecreasingNdot
            )

            if ConstrainedIncreasingNdot or ConstrainedDecreasingNdot:
                MdotFuel = MdotFuelAllowed
                NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                Qgross = NdotFuel * (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)

                for i in range(20):
                    Pnetss = Qgross * ElecEff
                    if self.A42Model.InternalFlowControl:
                        MdotCW = GeneratorDynamicsManager_FuncDetermineCWMdotForInternalFlowControl(
                            state, self.DynamicsControlID, Pnetss, TcwIn
                        )
                    ElecEff = self.A42Model.ElecEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                    ElecEff = max(0.0, ElecEff)

                ThermEff = self.A42Model.ThermalEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                ThermEff = max(0.0, ThermEff)
                Qgenss = ThermEff * Qgross

            NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
            MdotAir = self.A42Model.AirFlowCurve.value(state, MdotFuel)
            MdotAir = max(0.0, MdotAir)
            
            if PLRforSubtimestepStartUp < 1.0:
                Pnetss = AllowedLoad

        elif CurrentOpMode == OperatingMode.CoolDown:
            Pnetss = 0.0
            Pstandby = 0.0
            Pcooler = self.A42Model.PcoolDown
            TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
            MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
            
            if self.A42Model.InternalFlowControl:
                MdotCW = GeneratorDynamicsManager_FuncDetermineCWMdotForInternalFlowControl(
                    state, self.DynamicsControlID, Pnetss, TcwIn
                )
            
            NdotFuel = 0.0
            MdotFuel = 0.0
            MdotAir = 0.0
            ElecEff = 0.0
            ThermEff = 0.0
            Qgross = 0.0
            Qgenss = 0.0

        for i in range(20):
            if self.A42Model.WarmUpByEngineTemp and CurrentOpMode == OperatingMode.WarmUp:
                Pmax = self.A42Model.MaxElecPower
                TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
                MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
                ElecEff = self.A42Model.ElecEffCurve.value(state, Pmax, MdotCW, TcwIn)
                ElecEff = max(0.0, ElecEff)
                
                if ElecEff > 0.0:
                    Qgross = Pmax / ElecEff
                else:
                    Qgross = 0.0

                NdotFuel = Qgross / (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)
                MdotFuelMax = NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec

                if Teng > thisAmbientTemp:
                    MdotFuelWarmup = (MdotFuelMax + self.A42Model.kf * MdotFuelMax *
                                     ((self.A42Model.TnomEngOp - thisAmbientTemp) / (Teng - thisAmbientTemp)))
                    if MdotFuelWarmup > self.A42Model.Rfuelwarmup * MdotFuelMax:
                        MdotFuelWarmup = self.A42Model.Rfuelwarmup * MdotFuelMax
                    
                    if self.A42Model.TnomEngOp > thisAmbientTemp:
                        Pnetss = Pmax * self.A42Model.kp * ((Teng - thisAmbientTemp) / (self.A42Model.TnomEngOp - thisAmbientTemp))
                    else:
                        Pnetss = Pmax
                else:
                    MdotFuelWarmup = self.A42Model.Rfuelwarmup * MdotFuelMax

                MdotFuel = MdotFuelWarmup
                NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                MdotAir = self.A42Model.AirFlowCurve.value(state, MdotFuelWarmup)
                MdotAir = max(0.0, MdotAir)
                Qgross = NdotFuel * (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)
                ThermEff = self.A42Model.ThermalEffCurve.value(state, Pmax, MdotCW, TcwIn)
                ThermEff = max(0.0, ThermEff)
                Qgenss = ThermEff * Qgross

            dt = state.dataHVACGlobal.TimeStepSysSec

            Teng = FuncDetermineEngineTemp(
                TcwOut, self.A42Model.MCeng, self.A42Model.UAhx,
                self.A42Model.UAskin, thisAmbientTemp, Qgenss,
                self.A42Model.TengLast, dt
            )

            Cp = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, TcwIn)

            TcwOut = FuncDetermineCoolantWaterExitTemp(
                TcwIn, self.A42Model.MCcw, self.A42Model.UAhx,
                MdotCW * Cp, Teng, self.A42Model.TempCWOutLast, dt
            )

            EnergyBalOK = CheckMicroCHPThermalBalance(
                self.A42Model.MaxElecPower, TcwIn, TcwOut, Teng,
                thisAmbientTemp, self.A42Model.UAhx, self.A42Model.UAskin,
                Qgenss, self.A42Model.MCeng, self.A42Model.MCcw,
                MdotCW * Cp
            )

            if EnergyBalOK and i > 3:
                break

        self.PlantMassFlowRate = MdotCW
        self.A42Model.Pnet = Pnetss - Pcooler - Pstandby
        self.A42Model.ElecEff = ElecEff
        self.A42Model.Qgross = Qgross
        self.A42Model.ThermEff = ThermEff
        self.A42Model.Qgenss = Qgenss
        self.A42Model.NdotFuel = NdotFuel
        self.A42Model.MdotFuel = MdotFuel
        self.A42Model.Teng = Teng
        self.A42Model.TcwOut = TcwOut
        self.A42Model.TcwIn = TcwIn
        self.A42Model.MdotAir = MdotAir
        self.A42Model.QdotSkin = self.A42Model.UAskin * (Teng - thisAmbientTemp)
        self.A42Model.OpMode = CurrentOpMode

    def CalcUpdateHeatRecovery(self, state: Any) -> None:
        """Update heat recovery"""
        PlantUtilities_SafeCopyPlantNode(state, self.PlantInletNodeID, self.PlantOutletNodeID)
        state.dataLoopNodes.Node[self.PlantOutletNodeID].Temp = self.A42Model.TcwOut
        Cp = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, self.A42Model.TcwIn)
        state.dataLoopNodes.Node[self.PlantOutletNodeID].Enthalpy = self.A42Model.TcwOut * Cp

    def UpdateMicroCHPGeneratorRecords(self, state: Any) -> None:
        """Update generator records"""
        self.A42Model.ACPowerGen = self.A42Model.Pnet
        self.A42Model.ACEnergyGen = self.A42Model.Pnet * state.dataHVACGlobal.TimeStepSysSec
        self.A42Model.QdotHX = self.A42Model.UAhx * (self.A42Model.Teng - self.A42Model.TcwOut)

        Cp = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, self.A42Model.TcwIn)

        self.A42Model.QdotHR = self.PlantMassFlowRate * Cp * (self.A42Model.TcwOut - self.A42Model.TcwIn)
        self.A42Model.TotalHeatEnergyRec = self.A42Model.QdotHR * state.dataHVACGlobal.TimeStepSysSec

        self.A42Model.HeatRecInletTemp = self.A42Model.TcwIn
        self.A42Model.HeatRecOutletTemp = self.A42Model.TcwOut

        self.A42Model.FuelCompressPower = state.dataGenerator.FuelSupply[self.FuelSupplyID].PfuelCompEl
        self.A42Model.FuelCompressEnergy = (
            state.dataGenerator.FuelSupply[self.FuelSupplyID].PfuelCompEl * 
            state.dataHVACGlobal.TimeStepSys * 3600.0
        )
        self.A42Model.FuelCompressSkinLoss = state.dataGenerator.FuelSupply[self.FuelSupplyID].QskinLoss
        
        self.A42Model.FuelEnergyHHV = (
            self.A42Model.NdotFuel *
            state.dataGenerator.FuelSupply[self.FuelSupplyID].HHV *
            state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec *
            state.dataHVACGlobal.TimeStepSys * 3600.0
        )
        self.A42Model.FuelEnergyUseRateHHV = (
            self.A42Model.NdotFuel *
            state.dataGenerator.FuelSupply[self.FuelSupplyID].HHV *
            state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
        )
        self.A42Model.FuelEnergyLHV = (
            self.A42Model.NdotFuel *
            state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000000.0 *
            state.dataHVACGlobal.TimeStepSysSec
        )
        self.A42Model.FuelEnergyUseRateLHV = (
            self.A42Model.NdotFuel *
            state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000000.0
        )

        self.A42Model.SkinLossPower = self.A42Model.QdotConvZone + self.A42Model.QdotRadZone
        self.A42Model.SkinLossEnergy = (
            (self.A42Model.QdotConvZone + self.A42Model.QdotRadZone) *
            state.dataHVACGlobal.TimeStepSysSec
        )
        self.A42Model.SkinLossConvect = self.A42Model.QdotConvZone
        self.A42Model.SkinLossRadiat = self.A42Model.QdotRadZone

        if self.AirInletNodeID > 0:
            state.dataLoopNodes.Node[self.AirInletNodeID].MassFlowRate = self.A42Model.MdotAir
        if self.AirOutletNodeID > 0:
            state.dataLoopNodes.Node[self.AirOutletNodeID].MassFlowRate = self.A42Model.MdotAir
            state.dataLoopNodes.Node[self.AirOutletNodeID].Temp = self.A42Model.Teng

    def oneTimeInit(self, state: Any) -> None:
        """One-time initialization"""
        if self.myFlag:
            self.setupOutputVars(state)
            self.myFlag = False

        if self.MyPlantScanFlag:
            if hasattr(state, 'dataPlnt') and hasattr(state.dataPlnt, 'PlantLoop'):
                errFlag = False
                PlantUtilities_ScanPlantLoopsForObject(
                    state, self.Name, self.CWPlantLoc, errFlag
                )

                if errFlag:
                    ShowFatalError(state, "InitMicroCHPNoNormalizeGenerators: Program terminated for previous conditions.")

                if not self.A42Model.InternalFlowControl:
                    if self.CWPlantLoc.loopSideNum == LoopSideLocation.Supply:
                        pass

                self.MyPlantScanFlag = False

    @staticmethod
    def factory(state: Any, objectName: str) -> 'MicroCHPDataStruct':
        """Factory method to create Micro CHP generator"""
        if state.dataCHPElectGen.getMicroCHPInputFlag:
            GetMicroCHPGeneratorInput(state)
            state.dataCHPElectGen.getMicroCHPInputFlag = False

        for thisMCHP in state.dataCHPElectGen.MicroCHP:
            if thisMCHP.Name == objectName:
                return thisMCHP

        ShowFatalError(state, f"LocalMicroCHPGenFactory: Error getting inputs for micro-CHP gen named: {objectName}")
        return None


def GetMicroCHPGeneratorInput(state: Any) -> None:
    """Get input for Micro CHP generators"""
    if state.dataCHPElectGen.MyOneTimeFlag:
        NumAlphas = 0
        NumNums = 0
        IOStat = 0
        ErrorsFound = False
        s_ipsc = state.dataIPShortCut

        GeneratorFuelSupply_GetGeneratorFuelSupplyInput(state)

        s_ipsc.cCurrentModuleObject = "Generator:MicroCHP:NonNormalizedParameters"
        state.dataCHPElectGen.NumMicroCHPParams = (
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, s_ipsc.cCurrentModuleObject
            )
        )

        if state.dataCHPElectGen.NumMicroCHPParams <= 0:
            ShowSevereError(state, f"No {s_ipsc.cCurrentModuleObject} equipment specified in input file")
            ErrorsFound = True

        state.dataCHPElectGen.MicroCHPParamInput = [
            MicroCHPParamsNonNormalized()
            for _ in range(state.dataCHPElectGen.NumMicroCHPParams)
        ]

        for CHPParamNum in range(state.dataCHPElectGen.NumMicroCHPParams):
            AlphArray = [""] * 25
            NumArray = [0.0] * 200

            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, s_ipsc.cCurrentModuleObject, CHPParamNum,
                AlphArray, NumAlphas, NumArray, NumNums, IOStat
            )

            microCHPParams = state.dataCHPElectGen.MicroCHPParamInput[CHPParamNum]

            microCHPParams.Name = AlphArray[0]
            microCHPParams.MaxElecPower = NumArray[0]
            microCHPParams.MinElecPower = NumArray[1]
            microCHPParams.MinWaterMdot = NumArray[2]
            microCHPParams.MaxWaterTemp = NumArray[3]

            if not AlphArray[1]:
                ShowSevereEmptyField(state, s_ipsc.cAlphaFieldNames[1])
                ErrorsFound = True
            else:
                microCHPParams.ElecEffCurve = Curve_GetCurve(state, AlphArray[1])
                if microCHPParams.ElecEffCurve is None:
                    ShowSevereItemNotFound(state, s_ipsc.cAlphaFieldNames[1], AlphArray[1])
                    ErrorsFound = True

            if not AlphArray[2]:
                ShowSevereEmptyField(state, s_ipsc.cAlphaFieldNames[2])
                ErrorsFound = True
            else:
                microCHPParams.ThermalEffCurve = Curve_GetCurve(state, AlphArray[2])
                if microCHPParams.ThermalEffCurve is None:
                    ShowSevereItemNotFound(state, s_ipsc.cAlphaFieldNames[2], AlphArray[2])
                    ErrorsFound = True

            if Util_SameString(AlphArray[3], "InternalControl"):
                microCHPParams.InternalFlowControl = True
                microCHPParams.PlantFlowControl = False
            if not (Util_SameString(AlphArray[3], "InternalControl") or Util_SameString(AlphArray[3], "PlantControl")):
                ShowSevereError(state, f"Invalid, {s_ipsc.cAlphaFieldNames[3]} = {AlphArray[3]}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                ErrorsFound = True

            if microCHPParams.InternalFlowControl:
                if not AlphArray[4]:
                    ShowSevereEmptyField(state, s_ipsc.cAlphaFieldNames[4])
                    ErrorsFound = True
                else:
                    microCHPParams.WaterFlowCurve = Curve_GetCurve(state, AlphArray[4])
                    if microCHPParams.WaterFlowCurve is None:
                        ShowSevereItemNotFound(state, s_ipsc.cAlphaFieldNames[4], AlphArray[4])
                        ErrorsFound = True

            if not AlphArray[5]:
                ShowSevereEmptyField(state, s_ipsc.cAlphaFieldNames[5])
                ErrorsFound = True
            else:
                microCHPParams.AirFlowCurve = Curve_GetCurve(state, AlphArray[5])
                if microCHPParams.AirFlowCurve is None:
                    ShowSevereItemNotFound(state, s_ipsc.cAlphaFieldNames[5], AlphArray[5])
                    ErrorsFound = True

            microCHPParams.DeltaPelMax = NumArray[4]
            microCHPParams.DeltaFuelMdotMax = NumArray[5]
            microCHPParams.UAhx = NumArray[6]
            microCHPParams.UAskin = NumArray[7]
            microCHPParams.RadiativeFraction = NumArray[8]
            microCHPParams.MCeng = NumArray[9]
            
            if microCHPParams.MCeng <= 0.0:
                ShowSevereError(state, f"Invalid, {s_ipsc.cNumericFieldNames[9]} = {NumArray[9]:.5f}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                ShowContinueError(state, "Thermal mass must be greater than zero")
                ErrorsFound = True

            microCHPParams.MCcw = NumArray[10]
            if microCHPParams.MCcw <= 0.0:
                ShowSevereError(state, f"Invalid, {s_ipsc.cNumericFieldNames[10]} = {NumArray[10]:.5f}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                ShowContinueError(state, "Thermal mass must be greater than zero")
                ErrorsFound = True

            microCHPParams.Pstandby = NumArray[11]

            if Util_SameString(AlphArray[6], "TimeDelay"):
                microCHPParams.WarmUpByTimeDelay = True
                microCHPParams.WarmUpByEngineTemp = False
            if not (Util_SameString(AlphArray[6], "NominalEngineTemperature") or Util_SameString(AlphArray[6], "TimeDelay")):
                ShowSevereError(state, f"Invalid, {s_ipsc.cAlphaFieldNames[6]} = {AlphArray[6]}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                ErrorsFound = True

            microCHPParams.kf = NumArray[12]
            microCHPParams.TnomEngOp = NumArray[13]
            microCHPParams.kp = NumArray[14]
            microCHPParams.Rfuelwarmup = NumArray[15]
            microCHPParams.WarmUpDelay = NumArray[16]
            microCHPParams.PcoolDown = NumArray[17]
            microCHPParams.CoolDownDelay = NumArray[18]

            if Util_SameString(AlphArray[7], "MandatoryCoolDown"):
                microCHPParams.MandatoryFullCoolDown = True
                microCHPParams.WarmRestartOkay = False
            if not (Util_SameString(AlphArray[7], "MandatoryCoolDown") or Util_SameString(AlphArray[7], "OptionalCoolDown")):
                ShowSevereError(state, f"Invalid, {s_ipsc.cAlphaFieldNames[7]} = {AlphArray[7]}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                ErrorsFound = True

        s_ipsc.cCurrentModuleObject = "Generator:MicroCHP"
        state.dataCHPElectGen.NumMicroCHPs = (
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, s_ipsc.cCurrentModuleObject
            )
        )

        if state.dataCHPElectGen.NumMicroCHPs <= 0:
            ShowSevereError(state, f"No {s_ipsc.cCurrentModuleObject} equipment specified in input file")
            ErrorsFound = True

        state.dataCHPElectGen.MicroCHP = [
            MicroCHPDataStruct()
            for _ in range(state.dataCHPElectGen.NumMicroCHPs)
        ]

        for GeneratorNum in range(state.dataCHPElectGen.NumMicroCHPs):
            AlphArray = [""] * 25
            NumArray = [0.0] * 200

            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, s_ipsc.cCurrentModuleObject, GeneratorNum,
                AlphArray, NumAlphas, NumArray, NumNums, IOStat
            )

            microCHP = state.dataCHPElectGen.MicroCHP[GeneratorNum]
            microCHP.DynamicsControlID = GeneratorNum
            microCHP.Name = AlphArray[0]
            microCHP.ParamObjName = AlphArray[1]

            thisParamID = Util_FindItemInList(AlphArray[1], state.dataCHPElectGen.MicroCHPParamInput)
            if thisParamID >= 0:
                microCHP.A42Model = state.dataCHPElectGen.MicroCHPParamInput[thisParamID]
            else:
                ShowSevereError(state, f"Invalid, {s_ipsc.cAlphaFieldNames[1]} = {AlphArray[1]}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                ErrorsFound = True

            if AlphArray[2]:
                microCHP.ZoneName = AlphArray[2]
                microCHP.ZoneID = Util_FindItemInList(microCHP.ZoneName, state.dataHeatBal.Zone)
                if microCHP.ZoneID == 0:
                    ShowSevereError(state, f"Invalid, {s_ipsc.cAlphaFieldNames[2]} = {AlphArray[2]}")
                    ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                    ErrorsFound = True
            else:
                microCHP.ZoneID = 0

            microCHP.PlantInletNodeName = AlphArray[3]
            microCHP.PlantOutletNodeName = AlphArray[4]

            microCHP.PlantInletNodeID = Node_GetOnlySingleNode(state, AlphArray[3], ErrorsFound, AlphArray[0])
            microCHP.PlantOutletNodeID = Node_GetOnlySingleNode(state, AlphArray[4], ErrorsFound, AlphArray[0])

            Node_TestCompSet(state, s_ipsc.cCurrentModuleObject, AlphArray[0], AlphArray[3], AlphArray[4], "Heat Recovery Nodes")

            microCHP.AirInletNodeName = AlphArray[5]
            microCHP.AirInletNodeID = Node_GetOnlySingleNode(state, AlphArray[5], ErrorsFound, AlphArray[0])

            microCHP.AirOutletNodeName = AlphArray[6]
            microCHP.AirOutletNodeID = Node_GetOnlySingleNode(state, AlphArray[6], ErrorsFound, AlphArray[0])

            microCHP.FuelSupplyID = Util_FindItemInList(AlphArray[7], state.dataGenerator.FuelSupply)
            if microCHP.FuelSupplyID == 0:
                ShowSevereError(state, f"Invalid, {s_ipsc.cAlphaFieldNames[7]} = {AlphArray[7]}")
                ShowContinueError(state, f"Entered in {s_ipsc.cCurrentModuleObject}={AlphArray[0]}")
                ErrorsFound = True

            if not AlphArray[8]:
                microCHP.availSched = Sched_GetScheduleAlwaysOn(state)
            else:
                microCHP.availSched = Sched_GetSchedule(state, AlphArray[8])
                if microCHP.availSched is None:
                    ShowSevereItemNotFound(state, s_ipsc.cAlphaFieldNames[8], AlphArray[8])
                    ErrorsFound = True

            microCHP.A42Model.TengLast = 20.0
            microCHP.A42Model.TempCWOutLast = 20.0

        if ErrorsFound:
            ShowFatalError(state, f"Errors found in processing input for {s_ipsc.cCurrentModuleObject}")

        state.dataCHPElectGen.MyOneTimeFlag = False


def FuncDetermineEngineTemp(TcwOut: float, MCeng: float, UAHX: float, UAskin: float,
                            Troom: float, Qgenss: float, TengLast: float, time: float) -> float:
    """Determine engine temperature"""
    a = ((UAHX * TcwOut / MCeng) + (UAskin * Troom / MCeng) + (Qgenss / MCeng))
    b = ((-1.0 * UAHX / MCeng) + (-1.0 * UAskin / MCeng))
    return (TengLast + a / b) * math.exp(b * time) - a / b


def FuncDetermineCoolantWaterExitTemp(TcwIn: float, MCcw: float, UAHX: float, MdotCpcw: float,
                                      Teng: float, TcwoutLast: float, time: float) -> float:
    """Determine coolant water exit temperature"""
    a = (MdotCpcw * TcwIn / MCcw) + (UAHX * Teng / MCcw)
    b = ((-1.0 * MdotCpcw / MCcw) + (-1.0 * UAHX / MCcw))

    MAX_EXP_ARG = 700.0
    if b * time < (-1.0 * MAX_EXP_ARG):
        return -a / b
    return (TcwoutLast + a / b) * math.exp(b * time) - a / b


def CheckMicroCHPThermalBalance(NomHeatGen: float, TcwIn: float, TcwOut: float, Teng: float,
                                Troom: float, UAHX: float, UAskin: float, Qgenss: float,
                                MCeng: float, MCcw: float, MdotCpcw: float) -> bool:
    """Check Micro CHP thermal balance"""
    a = ((UAHX * TcwOut / MCeng) + (UAskin * Troom / MCeng) + (Qgenss / MCeng))
    b = ((-1.0 * UAHX / MCeng) + (-1.0 * UAskin / MCeng))
    DTengDTime = a + b * Teng

    c = (MdotCpcw * TcwIn / MCcw) + (UAHX * Teng / MCcw)
    d = ((-1.0 * MdotCpcw / MCcw) + (-1.0 * UAHX / MCcw))
    DCoolOutTDtime = c + d * TcwOut

    magImbalEng = UAHX * (TcwOut - Teng) + UAskin * (Troom - Teng) + Qgenss - MCeng * DTengDTime
    magImbalCooling = MdotCpcw * (TcwIn - TcwOut) + UAHX * (Teng - TcwOut) - MCcw * DCoolOutTDtime

    threshold = NomHeatGen / 10000000.0

    return (threshold > magImbalEng) and (threshold > magImbalCooling)


def FigureMicroCHPZoneGains(state: Any) -> None:
    """Figure Micro CHP zone gains"""
    if state.dataCHPElectGen.NumMicroCHPs == 0:
        return

    if state.dataGlobal.BeginEnvrnFlag and state.dataCHPElectGen.MyEnvrnFlag:
        for e in state.dataGenerator.FuelSupply:
            e.QskinLoss = 0.0
        for e in state.dataCHPElectGen.MicroCHP:
            e.A42Model.QdotSkin = 0.0
            e.A42Model.SkinLossConvect = 0.0
            e.A42Model.SkinLossRadiat = 0.0
        state.dataCHPElectGen.MyEnvrnFlag = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataCHPElectGen.MyEnvrnFlag = True

    for CHPnum in range(state.dataCHPElectGen.NumMicroCHPs):
        TotalZoneHeatGain = (
            state.dataGenerator.FuelSupply[state.dataCHPElectGen.MicroCHP[CHPnum].FuelSupplyID].QskinLoss +
            state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.QdotSkin
        )

        state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.QdotConvZone = (
            TotalZoneHeatGain * (1 - state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.RadiativeFraction)
        )
        state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.SkinLossConvect = (
            state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.QdotConvZone
        )
        state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.QdotRadZone = (
            TotalZoneHeatGain * state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.RadiativeFraction
        )
        state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.SkinLossRadiat = (
            state.dataCHPElectGen.MicroCHP[CHPnum].A42Model.QdotRadZone
        )


# Stub implementations for external dependencies
def PlantUtilities_UpdateComponentHeatRecoverySide(state, loopNum, loopSideNum, inletNodeID, outletNodeID,
                                                   QdotHR, HeatRecInletTemp, HeatRecOutletTemp, MassFlowRate,
                                                   FirstHVACIteration):
    pass

def PlantUtilities_RegisterPlantCompDesignFlow(state, nodeID, volFlowRate):
    pass

def PlantUtilities_InitComponentNodes(state, minFlow, maxFlow, inletNodeID, outletNodeID):
    pass

def PlantUtilities_SetComponentFlowRate(state, mdot, inletNodeID, outletNodeID, plantLoc):
    pass

def PlantUtilities_SafeCopyPlantNode(state, inletNodeID, outletNodeID):
    pass

def PlantUtilities_ScanPlantLoopsForObject(state, objectName, plantLoc, errFlag):
    pass

def GeneratorDynamicsManager_ManageGeneratorControlState(state, controlID, runElectCenter, runPlant,
                                                        electricLoad, thermalLoad, allowedLoad, opMode,
                                                        plrStartup, plrShutdown):
    pass

def GeneratorDynamicsManager_ManageGeneratorFuelFlow(state, controlID, mdotFuel, mdotFuelAllowed,
                                                    constrainedIncreasing, constrainedDecreasing):
    pass

def GeneratorDynamicsManager_FuncDetermineCWMdotForInternalFlowControl(state, controlID, pnetss, tcwIn):
    return 0.0

def GeneratorDynamicsManager_SetupGeneratorControlStateManager(state, controlID):
    pass

def GeneratorFuelSupply_GetGeneratorFuelSupplyInput(state):
    pass

def Curve_GetCurve(state, curveName):
    return None

def Sched_GetSchedule(state, schedName):
    return None

def Sched_GetScheduleAlwaysOn(state):
    return None

def Node_GetOnlySingleNode(state, nodeName, errFlag, objectName):
    return 0

def Node_TestCompSet(state, moduleObject, objectName, inletNode, outletNode, description):
    pass

def Util_SameString(str1, str2):
    return str1.upper() == str2.upper() if str1 and str2 else False

def Util_FindItemInList(name, items):
    if isinstance(items, list):
        for i, item in enumerate(items):
            if hasattr(item, 'Name') and item.Name == name:
                return i
    return -1

def ShowFatalError(state, message):
    raise RuntimeError(f"Fatal Error: {message}")

def ShowSevereError(state, message):
    pass

def ShowSevereEmptyField(state, fieldName):
    pass

def ShowSevereItemNotFound(state, fieldName, itemName):
    pass

def ShowContinueError(state, message):
    pass

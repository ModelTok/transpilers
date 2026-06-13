from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional, Protocol, List
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state parameter, contains all module containers)
# - Sched::Schedule (schedule pointers, source: ScheduleManager)
# - Fluid::GlycolProps (fluid properties, source: FluidProperties)
# - PlantComponent (base class, source: PlantComponent.hh)
# - PlantLocation (source: Plant/PlantLocation.hh)
# - DataPlant::PlantEquipmentType enum (source: Plant/DataPlant.hh)
# - Various state.dataXXX containers (surfaces, zones, nodes, etc.)

class Schedule(Protocol):
    Name: str
    def getCurrentVal(self) -> float: ...
    def checkMinMaxVals(self, state: EnergyPlusData, lo_clusive: str, lo_val: float, hi_clusive: str, hi_val: float) -> bool: ...

class GlycolProps(Protocol):
    def getDensity(self, state: EnergyPlusData, temp: float, routine_name: str) -> float: ...
    def getSpecificHeat(self, state: EnergyPlusData, temp: float, routine_name: str) -> float: ...

class PlantComponent:
    pass

class PlantLocation:
    pass

@dataclass
class EnergyPlusData(Protocol):
    pass

@dataclass
class SwimmingPoolData(PlantComponent):
    Name: str = ""
    SurfaceName: str = ""
    SurfacePtr: int = 0
    ZoneName: str = ""
    ZonePtr: int = 0
    WaterInletNodeName: str = ""
    WaterInletNode: int = 0
    WaterOutletNodeName: str = ""
    WaterOutletNode: int = 0
    HWplantLoc: PlantLocation = field(default_factory=PlantLocation)
    WaterVolFlowMax: float = 0.0
    WaterMassFlowRateMax: float = 0.0
    AvgDepth: float = 0.0
    ActivityFactor: float = 0.0
    activityFactorSched: Optional[Schedule] = None
    CurActivityFactor: float = 0.0
    makeupWaterSupplySched: Optional[Schedule] = None
    CurMakeupWaterTemp: float = 0.0
    coverSched: Optional[Schedule] = None
    CurCoverSchedVal: float = 0.0
    CoverEvapFactor: float = 0.0
    CoverConvFactor: float = 0.0
    CoverSWRadFactor: float = 0.0
    CoverLWRadFactor: float = 0.0
    CurCoverEvapFac: float = 0.0
    CurCoverConvFac: float = 0.0
    CurCoverSWRadFac: float = 0.0
    CurCoverLWRadFac: float = 0.0
    RadConvertToConvect: float = 0.0
    MiscPowerFactor: float = 0.0
    setPtTempSched: Optional[Schedule] = None
    CurSetPtTemp: float = 23.0
    MaxNumOfPeople: float = 0.0
    peopleSched: Optional[Schedule] = None
    peopleHeatGainSched: Optional[Schedule] = None
    PeopleHeatGain: float = 0.0
    glycol: Optional[GlycolProps] = None
    WaterMass: float = 0.0
    SatPressPoolWaterTemp: float = 0.0
    PartPressZoneAirTemp: float = 0.0
    PoolWaterTemp: float = 23.0
    WaterInletTemp: float = 0.0
    WaterOutletTemp: float = 0.0
    WaterMassFlowRate: float = 0.0
    MakeUpWaterMassFlowRate: float = 0.0
    MakeUpWaterMass: float = 0.0
    MakeUpWaterVolFlowRate: float = 0.0
    MakeUpWaterVol: float = 0.0
    HeatPower: float = 0.0
    HeatEnergy: float = 0.0
    MiscEquipPower: float = 0.0
    MiscEquipEnergy: float = 0.0
    RadConvertToConvectRep: float = 0.0
    EvapHeatLossRate: float = 0.0
    EvapEnergyLoss: float = 0.0
    MyOneTimeFlag: bool = True
    MyEnvrnFlagGeneral: bool = True
    MyPlantScanFlagPool: bool = True
    QPoolSrcAvg: float = 0.0
    HeatTransCoefsAvg: float = 0.0
    ZeroPoolSourceSumHATsurf: float = 0.0
    LastQPoolSrc: float = 0.0
    LastHeatTransCoefs: float = 0.0
    LastSysTimeElapsed: float = 0.0
    LastTimeStepSys: float = 0.0

    @staticmethod
    def factory(state: EnergyPlusData, object_name: str) -> Optional[SwimmingPoolData]:
        if state.dataSwimmingPools.getSwimmingPoolInput:
            GetSwimmingPool(state)
            state.dataSwimmingPools.getSwimmingPoolInput = False
        for pool in state.dataSwimmingPools.Pool:
            if pool.Name == object_name:
                return pool
        raise Exception(f"LocalSwimmingPoolFactory: Error getting inputs or index for swimming pool named: {object_name}")

    def simulate(self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        state.dataHeatBalFanSys.SumConvPool[self.ZonePtr] = 0.0
        state.dataHeatBalFanSys.SumLatentPool[self.ZonePtr] = 0.0
        CurLoad = 0.0
        RunFlag = True
        self.initialize(state, FirstHVACIteration)
        self.calculate(state)
        self.update(state)
        if state.dataSwimmingPools.NumSwimmingPools > 0:
            HeatBalanceSurfaceManager_CalcHeatBalanceInsideSurf(state)
        self.report(state)

    def ErrorCheckSetupPoolSurface(self, state: EnergyPlusData, Alpha1: str, Alpha2: str, cAlphaField2: str, ErrorsFound: bool) -> None:
        RoutineName = "ErrorCheckSetupPoolSurface: "
        CurrentModuleObject = "SwimmingPool:Indoor"
        
        if self.SurfacePtr <= 0:
            ShowSevereError(state, f"{RoutineName}Invalid {cAlphaField2} = {Alpha2}")
            ShowContinueError(state, f"Occurs in {CurrentModuleObject} = {Alpha1}")
            ErrorsFound = True
        elif state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[self.SurfacePtr]:
            ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alpha1}\", Invalid Surface")
            ShowContinueError(state, f"{cAlphaField2}=\"{Alpha2}\" has been used in another radiant system, ventilated slab, or pool.")
            ShowContinueError(state, "A single surface can only be a radiant system, a ventilated slab, or a pool.  It CANNOT be more than one of these.")
            ErrorsFound = True
        elif state.dataSurface.Surface[self.SurfacePtr].HeatTransferAlgorithm != DataSurfaces_HeatTransferModel.CTF:
            ShowSevereError(state, 
                f"{state.dataSurface.Surface[self.SurfacePtr].Name} is a pool and is attempting to use a non-CTF solution algorithm.  This is not allowed.  Use the CTF solution algorithm for this surface.")
            ErrorsFound = True
        elif state.dataSurface.Surface[self.SurfacePtr].Class == DataSurfaces_SurfaceClass.Window:
            ShowSevereError(state,
                f"{state.dataSurface.Surface[self.SurfacePtr].Name} is a pool and is defined as a window.  This is not allowed.  A pool must be a floor that is NOT a window.")
            ErrorsFound = True
        elif state.dataSurface.intMovInsuls[self.SurfacePtr].matNum > 0:
            ShowSevereError(state,
                f"{state.dataSurface.Surface[self.SurfacePtr].Name} is a pool and has movable insulation.  This is not allowed.  Remove the movable insulation for this surface.")
            ErrorsFound = True
        elif state.dataConstruction.Construct[state.dataSurface.Surface[self.SurfacePtr].Construction].SourceSinkPresent:
            ShowSevereError(state,
                f"{state.dataSurface.Surface[self.SurfacePtr].Name} is a pool and uses a construction with a source/sink.  This is not allowed.  Use a standard construction for this surface.")
            ErrorsFound = True
        else:
            state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[self.SurfacePtr] = True
            state.dataSurface.SurfIsPool[self.SurfacePtr] = True
            self.ZonePtr = state.dataSurface.Surface[self.SurfacePtr].Zone
            if state.dataSurface.Surface[self.SurfacePtr].Class != DataSurfaces_SurfaceClass.Floor:
                ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alpha1} contains a surface name that is NOT a floor.")
                ShowContinueError(state, "A swimming pool must be associated with a surface that is a FLOOR.  Association with other surface types is not permitted.")
                ErrorsFound = True

    def initialize(self, state: EnergyPlusData, FirstHVACIteration: bool) -> None:
        RoutineName = "InitSwimmingPool"
        MinActivityFactor = 0.0
        MaxActivityFactor = 10.0
        
        HeatGainPerPerson = self.peopleHeatGainSched.getCurrentVal() if self.peopleHeatGainSched else 0.0
        PeopleModifier = self.peopleSched.getCurrentVal() if self.peopleSched else 0.0
        
        if self.MyOneTimeFlag:
            self.setupOutputVars(state)
            self.MyOneTimeFlag = False
        
        self.initSwimmingPoolPlantLoopIndex(state)
        
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlagGeneral:
            self.ZeroPoolSourceSumHATsurf = 0.0
            self.QPoolSrcAvg = 0.0
            self.HeatTransCoefsAvg = 0.0
            self.LastQPoolSrc = 0.0
            self.LastHeatTransCoefs = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0
            self.MyEnvrnFlagGeneral = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlagGeneral = True
        
        if state.dataGlobal.BeginEnvrnFlag:
            self.PoolWaterTemp = 23.0
            self.HeatPower = 0.0
            self.HeatEnergy = 0.0
            self.MiscEquipPower = 0.0
            self.MiscEquipEnergy = 0.0
            self.WaterInletTemp = 0.0
            self.WaterOutletTemp = 0.0
            self.WaterMassFlowRate = 0.0
            self.PeopleHeatGain = 0.0
            Density = self.glycol.getDensity(state, self.PoolWaterTemp, RoutineName)
            self.WaterMass = state.dataSurface.Surface[self.SurfacePtr].Area * self.AvgDepth * Density
            self.WaterMassFlowRateMax = self.WaterVolFlowMax * Density
            self.initSwimmingPoolPlantNodeFlow(state)
        
        if state.dataGlobal.BeginTimeStepFlag and FirstHVACIteration:
            ZoneNum = self.ZonePtr
            self.ZeroPoolSourceSumHATsurf = state.dataHeatBal.Zone[ZoneNum].sumHATsurf(state)
            self.QPoolSrcAvg = 0.0
            self.HeatTransCoefsAvg = 0.0
            self.LastQPoolSrc = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0
        
        mdot = 0.0
        PlantUtilities_SetComponentFlowRate(state, mdot, self.WaterInletNode, self.WaterOutletNode, self.HWplantLoc)
        self.WaterInletTemp = state.dataLoopNodes.Node[self.WaterInletNode].Temp
        
        if self.activityFactorSched is not None:
            self.CurActivityFactor = self.activityFactorSched.getCurrentVal()
            if self.CurActivityFactor < MinActivityFactor:
                self.CurActivityFactor = MinActivityFactor
                ShowWarningError(state, f"{RoutineName}: Swimming Pool =\"{self.Name} Activity Factor Schedule =\"{self.activityFactorSched.Name} has a negative value.  This is not allowed.")
                ShowContinueError(state, "The activity factor has been reset to zero.")
            if self.CurActivityFactor > MaxActivityFactor:
                self.CurActivityFactor = 1.0
                ShowWarningError(state, f"{RoutineName}: Swimming Pool =\"{self.Name} Activity Factor Schedule =\"{self.activityFactorSched.Name} has a value larger than 10.  This is not allowed.")
                ShowContinueError(state, "The activity factor has been reset to unity.")
        else:
            self.CurActivityFactor = 1.0
        
        self.CurSetPtTemp = self.setPtTempSched.getCurrentVal()
        
        if self.makeupWaterSupplySched is not None:
            self.CurMakeupWaterTemp = self.makeupWaterSupplySched.getCurrentVal()
        else:
            self.CurMakeupWaterTemp = state.dataEnvrn.WaterMainsTemp
        
        if self.peopleHeatGainSched is not None:
            if HeatGainPerPerson < 0.0:
                ShowWarningError(state, f"{RoutineName}: Swimming Pool =\"{self.Name} Heat Gain Schedule =\"{self.peopleHeatGainSched.Name} has a negative value.  This is not allowed.")
                ShowContinueError(state, "The heat gain per person has been reset to zero.")
                HeatGainPerPerson = 0.0
            if self.peopleSched is not None:
                if PeopleModifier < 0.0:
                    ShowWarningError(state, f"{RoutineName}: Swimming Pool =\"{self.Name} People Schedule =\"{self.peopleSched.Name} has a negative value.  This is not allowed.")
                    ShowContinueError(state, "The number of people has been reset to zero.")
                    PeopleModifier = 0.0
            else:
                PeopleModifier = 1.0
        else:
            HeatGainPerPerson = 0.0
            PeopleModifier = 0.0
        
        self.PeopleHeatGain = PeopleModifier * HeatGainPerPerson * self.MaxNumOfPeople
        
        if self.coverSched is not None:
            self.CurCoverSchedVal = self.coverSched.getCurrentVal()
            if self.CurCoverSchedVal > 1.0:
                ShowWarningError(state, f"{RoutineName}: Swimming Pool =\"{self.Name} Cover Schedule =\"{self.coverSched.Name} has a value greater than 1.0 (100%).  This is not allowed.")
                ShowContinueError(state, "The cover has been reset to one or fully covered.")
                self.CurCoverSchedVal = 1.0
            elif self.CurCoverSchedVal < 0.0:
                ShowWarningError(state, f"{RoutineName}: Swimming Pool =\"{self.Name} Cover Schedule =\"{self.coverSched.Name} has a negative value.  This is not allowed.")
                ShowContinueError(state, "The cover has been reset to zero or uncovered.")
                self.CurCoverSchedVal = 0.0
        else:
            self.CurCoverSchedVal = 0.0
        
        self.CurCoverEvapFac = 1.0 - (self.CurCoverSchedVal * self.CoverEvapFactor)
        self.CurCoverConvFac = 1.0 - (self.CurCoverSchedVal * self.CoverConvFactor)
        self.CurCoverSWRadFac = 1.0 - (self.CurCoverSchedVal * self.CoverSWRadFactor)
        self.CurCoverLWRadFac = 1.0 - (self.CurCoverSchedVal * self.CoverLWRadFactor)

    def setupOutputVars(self, state: EnergyPlusData) -> None:
        SetupOutputVariable(state, "Indoor Pool Makeup Water Rate", Units.m3_s, self.MakeUpWaterVolFlowRate, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Makeup Water Volume", Units.m3, self.MakeUpWaterVol, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Sum, self.Name, eResource.MainsWater, OutputProcessor_Group.HVAC, OutputProcessor_EndUseCat.Heating)
        SetupOutputVariable(state, "Indoor Pool Makeup Water Temperature", Units.C, self.CurMakeupWaterTemp, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Water Temperature", Units.C, self.PoolWaterTemp, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Inlet Water Temperature", Units.C, self.WaterInletTemp, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Inlet Water Mass Flow Rate", Units.kg_s, self.WaterMassFlowRate, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Miscellaneous Equipment Power", Units.W, self.MiscEquipPower, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Miscellaneous Equipment Energy", Units.J, self.MiscEquipEnergy, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Indoor Pool Water Heating Rate", Units.W, self.HeatPower, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Water Heating Energy", Units.J, self.HeatEnergy, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Sum, self.Name, eResource.EnergyTransfer, OutputProcessor_Group.HVAC, OutputProcessor_EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Indoor Pool Radiant to Convection by Cover", Units.W, self.RadConvertToConvect, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool People Heat Gain", Units.W, self.PeopleHeatGain, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Activity Factor", Units.None, self.CurActivityFactor, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover Factor", Units.None, self.CurCoverSchedVal, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Evaporative Heat Loss Rate", Units.W, self.EvapHeatLossRate, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Evaporative Heat Loss Energy", Units.J, self.EvapEnergyLoss, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Indoor Pool Saturation Pressure at Pool Temperature", Units.Pa, self.SatPressPoolWaterTemp, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Partial Pressure of Water Vapor in Air", Units.Pa, self.PartPressZoneAirTemp, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover Evaporation Factor", Units.None, self.CurCoverEvapFac, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover Convective Factor", Units.None, self.CurCoverConvFac, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover SW Radiation Factor", Units.None, self.CurCoverSWRadFac, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover LW Radiation Factor", Units.None, self.CurCoverLWRadFac, OutputProcessor_TimeStepType.System, OutputProcessor_StoreType.Average, self.Name)

    def initSwimmingPoolPlantLoopIndex(self, state: EnergyPlusData) -> None:
        RoutineName = "InitSwimmingPoolPlantLoopIndex"
        
        if self.MyPlantScanFlagPool and len(state.dataPlnt.PlantLoop) > 0:
            if self.WaterInletNode > 0:
                errFlag = False
                PlantUtilities_ScanPlantLoopsForObject(state, self.Name, DataPlant_PlantEquipmentType.SwimmingPool_Indoor, self.HWplantLoc, errFlag)
                if errFlag:
                    ShowFatalError(state, f"{RoutineName}: Program terminated due to previous condition(s).")
            self.MyPlantScanFlagPool = False
        elif self.MyPlantScanFlagPool and not state.dataGlobal.AnyPlantInModel:
            self.MyPlantScanFlagPool = False

    def initSwimmingPoolPlantNodeFlow(self, state: EnergyPlusData) -> None:
        if not self.MyPlantScanFlagPool:
            if self.WaterInletNode > 0:
                PlantUtilities_InitComponentNodes(state, 0.0, self.WaterMassFlowRateMax, self.WaterInletNode, self.WaterOutletNode)
                PlantUtilities_RegisterPlantCompDesignFlow(state, self.WaterInletNode, self.WaterVolFlowMax)

    def calculate(self, state: EnergyPlusData) -> None:
        RoutineName = "CalcSwimmingPool"
        
        EvapRate = 0.0
        SurfNum = self.SurfacePtr
        ZoneNum = state.dataSurface.Surface[SurfNum].Zone
        thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum]
        
        HConvIn = 0.22 * pow(abs(self.PoolWaterTemp - thisZoneHB.MAT), 1.0 / 3.0) * self.CurCoverConvFac
        self.calcSwimmingPoolEvap(state, EvapRate, SurfNum, thisZoneHB.MAT, thisZoneHB.airHumRat)
        self.MakeUpWaterMassFlowRate = EvapRate
        
        EvapEnergyLossPerArea = -EvapRate * Psychrometrics_PsyHfgAirFnWTdb(thisZoneHB.airHumRat, thisZoneHB.MAT) / state.dataSurface.Surface[SurfNum].Area
        self.EvapHeatLossRate = EvapEnergyLossPerArea * state.dataSurface.Surface[SurfNum].Area
        
        LWsum = (state.dataHeatBal.SurfQdotRadIntGainsInPerArea[SurfNum] + 
                 state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea[SurfNum] + 
                 state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[SurfNum])
        LWtotal = self.CurCoverLWRadFac * LWsum
        SWtotal = self.CurCoverSWRadFac * state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[SurfNum]
        self.RadConvertToConvect = ((1.0 - self.CurCoverLWRadFac) * LWsum) + ((1.0 - self.CurCoverSWRadFac) * state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[SurfNum])
        
        PeopleGain = self.PeopleHeatGain / state.dataSurface.Surface[SurfNum].Area
        
        Cp = self.glycol.getSpecificHeat(state, self.PoolWaterTemp, RoutineName)
        
        TH22 = state.dataHeatBalSurf.SurfInsideTempHist[1][SurfNum]
        Tmuw = self.CurMakeupWaterTemp
        TLoopInletTemp = state.dataLoopNodes.Node[self.WaterInletNode].Temp
        self.WaterInletTemp = TLoopInletTemp
        
        MassFlowRate = 0.0
        self.calcMassFlowRate(state, MassFlowRate, TH22, TLoopInletTemp)
        
        PlantUtilities_SetComponentFlowRate(state, MassFlowRate, self.WaterInletNode, self.WaterOutletNode, self.HWplantLoc)
        self.WaterMassFlowRate = MassFlowRate
        
        state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] = (
            SWtotal + LWtotal + PeopleGain + EvapEnergyLossPerArea + HConvIn * thisZoneHB.MAT +
            (EvapRate * Tmuw + MassFlowRate * TLoopInletTemp + (self.WaterMass * TH22 / state.dataGlobal.TimeStepZoneSec)) * Cp /
            state.dataSurface.Surface[SurfNum].Area
        )
        state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] = (
            HConvIn + (EvapRate + MassFlowRate + (self.WaterMass / state.dataGlobal.TimeStepZoneSec)) * Cp / state.dataSurface.Surface[SurfNum].Area
        )
        
        state.dataHeatBalFanSys.SumConvPool[ZoneNum] += self.RadConvertToConvect
        state.dataHeatBalFanSys.SumLatentPool[ZoneNum] += EvapRate * Psychrometrics_PsyHfgAirFnWTdb(thisZoneHB.airHumRat, thisZoneHB.MAT)

    def calcMassFlowRate(self, state: EnergyPlusData, massFlowRate: float, TH22: float, TLoopInletTemp: float) -> None:
        if TLoopInletTemp != self.CurSetPtTemp:
            massFlowRate = self.WaterMass / state.dataHVACGlobal.TimeStepSysSec * (self.CurSetPtTemp - TH22) / (TLoopInletTemp - self.CurSetPtTemp)
        else:
            massFlowRate = 0.0
        
        if massFlowRate > self.WaterMassFlowRateMax:
            massFlowRate = self.WaterMassFlowRateMax
        elif massFlowRate <= 0.0:
            if TLoopInletTemp > TH22 and TLoopInletTemp <= self.CurSetPtTemp:
                massFlowRate = self.WaterMassFlowRateMax
            else:
                massFlowRate = 0.0

    def calcSwimmingPoolEvap(self, state: EnergyPlusData, EvapRate: float, SurfNum: int, MAT: float, HumRat: float) -> None:
        RoutineName = "CalcSwimmingPoolEvap"
        CFinHg = 0.00029613
        
        PSatPool = Psychrometrics_PsyPsatFnTemp(state, self.PoolWaterTemp, RoutineName)
        PParAir = (Psychrometrics_PsyPsatFnTemp(state, MAT, RoutineName) * 
                   Psychrometrics_PsyRhFnTdbWPb(state, MAT, HumRat, state.dataEnvrn.OutBaroPress))
        if PSatPool < PParAir:
            PSatPool = PParAir
        
        self.SatPressPoolWaterTemp = PSatPool
        self.PartPressZoneAirTemp = PParAir
        EvapRate = (0.1 * (state.dataSurface.Surface[SurfNum].Area / DataConversions_CFA) * self.CurActivityFactor * 
                    ((PSatPool - PParAir) * CFinHg)) * DataConversions_CFMF * self.CurCoverEvapFac

    def update(self, state: EnergyPlusData) -> None:
        SurfNum = self.SurfacePtr
        
        if self.LastSysTimeElapsed == state.dataHVACGlobal.SysTimeElapsed:
            self.QPoolSrcAvg -= self.LastQPoolSrc * self.LastTimeStepSys / state.dataGlobal.TimeStepZone
            self.HeatTransCoefsAvg -= self.LastHeatTransCoefs * self.LastTimeStepSys / state.dataGlobal.TimeStepZone
        
        self.QPoolSrcAvg += state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] * state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone
        self.HeatTransCoefsAvg += state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] * state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone
        
        self.LastQPoolSrc = state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum]
        self.LastHeatTransCoefs = state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum]
        self.LastSysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
        self.LastTimeStepSys = state.dataHVACGlobal.TimeStepSys
        
        PlantUtilities_SafeCopyPlantNode(state, self.WaterInletNode, self.WaterOutletNode)
        
        WaterMassFlow = state.dataLoopNodes.Node[self.WaterInletNode].MassFlowRate
        if WaterMassFlow > 0.0:
            state.dataLoopNodes.Node[self.WaterOutletNode].Temp = self.PoolWaterTemp

    def oneTimeInit_new(self, state: EnergyPlusData) -> None:
        pass

    def oneTimeInit(self, state: EnergyPlusData) -> None:
        pass

    def report(self, state: EnergyPlusData) -> None:
        RoutineName = "SwimmingPoolData::report"
        MinDensity = 1.0
        
        SurfNum = self.SurfacePtr
        
        self.PoolWaterTemp = state.dataHeatBalSurf.SurfInsideTempHist[0][SurfNum]
        
        Cp = self.glycol.getSpecificHeat(state, self.PoolWaterTemp, RoutineName)
        self.HeatPower = self.WaterMassFlowRate * Cp * (self.WaterInletTemp - self.PoolWaterTemp)
        
        Density = self.glycol.getDensity(state, self.PoolWaterTemp, RoutineName)
        if Density > MinDensity:
            self.MiscEquipPower = self.MiscPowerFactor * self.WaterMassFlowRate / Density
        else:
            self.MiscEquipPower = 0.0
        
        self.RadConvertToConvectRep = self.RadConvertToConvect * state.dataSurface.Surface[SurfNum].Area
        
        thisTimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
        self.MiscEquipEnergy = self.MiscEquipPower * thisTimeStepSysSec
        self.HeatEnergy = self.HeatPower * thisTimeStepSysSec
        self.MakeUpWaterMass = self.MakeUpWaterMassFlowRate * thisTimeStepSysSec
        self.EvapEnergyLoss = self.EvapHeatLossRate * thisTimeStepSysSec
        
        self.MakeUpWaterVolFlowRate = MakeUpWaterVolFlowFunct(self.MakeUpWaterMassFlowRate, Density)
        self.MakeUpWaterVol = MakeUpWaterVolFunct(self.MakeUpWaterMass, Density)

@dataclass
class SwimmingPoolsData:
    NumSwimmingPools: int = 0
    CheckEquipName: List[bool] = field(default_factory=list)
    getSwimmingPoolInput: bool = True
    Pool: List[SwimmingPoolData] = field(default_factory=list)

def GetSwimmingPool(state: EnergyPlusData) -> None:
    RoutineName = "GetSwimmingPool: "
    routineName = "GetSwimmingPool"
    
    MinCoverFactor = 0.0
    MaxCoverFactor = 1.0
    MinDepth = 0.05
    MaxDepth = 10.0
    MinPowerFactor = 0.0
    
    MaxAlphas = 0
    MaxNumbers = 0
    
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "SwimmingPool:Indoor", MaxAlphas, MaxNumbers)
    
    Alphas = [""] * MaxAlphas
    Numbers = [0.0] * MaxNumbers
    cAlphaFields = [""] * MaxAlphas
    cNumericFields = [""] * MaxNumbers
    lAlphaBlanks = [True] * MaxAlphas
    lNumericBlanks = [True] * MaxNumbers
    
    state.dataSwimmingPools.NumSwimmingPools = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "SwimmingPool:Indoor")
    state.dataSwimmingPools.CheckEquipName = [True] * state.dataSwimmingPools.NumSwimmingPools
    state.dataSwimmingPools.Pool = [SwimmingPoolData() for _ in range(state.dataSwimmingPools.NumSwimmingPools)]
    
    CurrentModuleObject = "SwimmingPool:Indoor"
    for Item in range(state.dataSwimmingPools.NumSwimmingPools):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Item, Alphas, Numbers, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        
        ErrorObjectHeader_eoh = {"routineName": routineName, "CurrentModuleObject": CurrentModuleObject, "Name": Alphas[0]}
        
        state.dataSwimmingPools.Pool[Item].Name = Alphas[0]
        state.dataSwimmingPools.Pool[Item].SurfaceName = Alphas[1]
        state.dataSwimmingPools.Pool[Item].SurfacePtr = 0
        
        state.dataSwimmingPools.Pool[Item].glycol = Fluid_GetWater(state)
        
        for SurfNum in range(state.dataSurface.TotSurfaces):
            if SameString(state.dataSurface.Surface[SurfNum].Name, state.dataSwimmingPools.Pool[Item].SurfaceName):
                state.dataSwimmingPools.Pool[Item].SurfacePtr = SurfNum
                break
        
        ErrorsFound = False
        state.dataSwimmingPools.Pool[Item].ErrorCheckSetupPoolSurface(state, Alphas[0], Alphas[1], cAlphaFields[1], ErrorsFound)
        
        state.dataSwimmingPools.Pool[Item].AvgDepth = Numbers[0]
        if state.dataSwimmingPools.Pool[Item].AvgDepth < MinDepth:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has an average depth that is too small.")
            ShowContinueError(state, "The pool average depth has been reset to the minimum allowed depth.")
        elif state.dataSwimmingPools.Pool[Item].AvgDepth > MaxDepth:
            ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has an average depth that is too large.")
            ShowContinueError(state, "The pool depth must be less than the maximum average depth of 10 meters.")
            ErrorsFound = True
        
        if not lAlphaBlanks[2]:
            sched = Sched_GetSchedule(state, Alphas[2])
            if sched is None:
                ShowSevereItemNotFound(state, ErrorObjectHeader_eoh, cAlphaFields[2], Alphas[2])
                ErrorsFound = True
            else:
                state.dataSwimmingPools.Pool[Item].activityFactorSched = sched
        
        if not lAlphaBlanks[3]:
            sched = Sched_GetSchedule(state, Alphas[3])
            if sched is None:
                ShowSevereItemNotFound(state, ErrorObjectHeader_eoh, cAlphaFields[3], Alphas[3])
                ErrorsFound = True
            else:
                state.dataSwimmingPools.Pool[Item].makeupWaterSupplySched = sched
        
        if not lAlphaBlanks[4]:
            sched = Sched_GetSchedule(state, Alphas[4])
            if sched is None:
                ShowSevereItemNotFound(state, ErrorObjectHeader_eoh, cAlphaFields[4], Alphas[4])
                ErrorsFound = True
            else:
                state.dataSwimmingPools.Pool[Item].coverSched = sched
                if not sched.checkMinMaxVals(state, "In", 0.0, "In", 1.0):
                    Sched_ShowSevereBadMinMax(state, ErrorObjectHeader_eoh, cAlphaFields[4], Alphas[4], "In", 0.0, "In", 1.0)
                    ErrorsFound = True
        
        state.dataSwimmingPools.Pool[Item].CoverEvapFactor = Numbers[1]
        if state.dataSwimmingPools.Pool[Item].CoverEvapFactor < MinCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has an evaporation cover factor less than zero.")
            ShowContinueError(state, "The evaporation cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverEvapFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverEvapFactor > MaxCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has an evaporation cover factor greater than one.")
            ShowContinueError(state, "The evaporation cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverEvapFactor = MaxCoverFactor
        
        state.dataSwimmingPools.Pool[Item].CoverConvFactor = Numbers[2]
        if state.dataSwimmingPools.Pool[Item].CoverConvFactor < MinCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has a convection cover factor less than zero.")
            ShowContinueError(state, "The convection cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverConvFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverConvFactor > MaxCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has a convection cover factor greater than one.")
            ShowContinueError(state, "The convection cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverConvFactor = MaxCoverFactor
        
        state.dataSwimmingPools.Pool[Item].CoverSWRadFactor = Numbers[3]
        if state.dataSwimmingPools.Pool[Item].CoverSWRadFactor < MinCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has a short-wavelength radiation cover factor less than zero.")
            ShowContinueError(state, "The short-wavelength radiation cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverSWRadFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverSWRadFactor > MaxCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has a short-wavelength radiation cover factor greater than one.")
            ShowContinueError(state, "The short-wavelength radiation cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverSWRadFactor = MaxCoverFactor
        
        state.dataSwimmingPools.Pool[Item].CoverLWRadFactor = Numbers[4]
        if state.dataSwimmingPools.Pool[Item].CoverLWRadFactor < MinCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has a long-wavelength radiation cover factor less than zero.")
            ShowContinueError(state, "The long-wavelength radiation cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverLWRadFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverLWRadFactor > MaxCoverFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has a long-wavelength radiation cover factor greater than one.")
            ShowContinueError(state, "The long-wavelength radiation cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverLWRadFactor = MaxCoverFactor
        
        state.dataSwimmingPools.Pool[Item].WaterInletNodeName = Alphas[5]
        state.dataSwimmingPools.Pool[Item].WaterOutletNodeName = Alphas[6]
        state.dataSwimmingPools.Pool[Item].WaterInletNode = Node_GetOnlySingleNode(state, Alphas[5], ErrorsFound, "SwimmingPoolIndoor", Alphas[0], "Water", "Inlet", "Primary", "NotParent")
        state.dataSwimmingPools.Pool[Item].WaterOutletNode = Node_GetOnlySingleNode(state, Alphas[6], ErrorsFound, "SwimmingPoolIndoor", Alphas[0], "Water", "Outlet", "Primary", "NotParent")
        
        if not lAlphaBlanks[5] or not lAlphaBlanks[6]:
            Node_TestCompSet(state, CurrentModuleObject, Alphas[0], Alphas[5], Alphas[6], "Hot Water Nodes")
        
        state.dataSwimmingPools.Pool[Item].WaterVolFlowMax = Numbers[5]
        state.dataSwimmingPools.Pool[Item].MiscPowerFactor = Numbers[6]
        if state.dataSwimmingPools.Pool[Item].MiscPowerFactor < MinPowerFactor:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} has a miscellaneous power factor less than zero.")
            ShowContinueError(state, "The miscellaneous power factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].MiscPowerFactor = MinPowerFactor
        
        if lAlphaBlanks[7]:
            ShowSevereEmptyField(state, ErrorObjectHeader_eoh, cAlphaFields[7])
            ErrorsFound = True
        else:
            sched = Sched_GetSchedule(state, Alphas[7])
            if sched is None:
                ShowSevereItemNotFound(state, ErrorObjectHeader_eoh, cAlphaFields[7], Alphas[7])
                ErrorsFound = True
            else:
                state.dataSwimmingPools.Pool[Item].setPtTempSched = sched
        
        state.dataSwimmingPools.Pool[Item].MaxNumOfPeople = Numbers[7]
        if state.dataSwimmingPools.Pool[Item].MaxNumOfPeople < 0.0:
            ShowWarningError(state, f"{RoutineName}{CurrentModuleObject}=\"{Alphas[0]} was entered with negative people.  This is not allowed.")
            ShowContinueError(state, "The number of people has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].MaxNumOfPeople = 0.0
        
        if not lAlphaBlanks[8]:
            sched = Sched_GetSchedule(state, Alphas[8])
            if sched is None:
                ShowSevereItemNotFound(state, ErrorObjectHeader_eoh, cAlphaFields[8], Alphas[8])
                ErrorsFound = True
            else:
                state.dataSwimmingPools.Pool[Item].peopleSched = sched
        
        if not lAlphaBlanks[9]:
            sched = Sched_GetSchedule(state, Alphas[9])
            if sched is None:
                ShowSevereItemNotFound(state, ErrorObjectHeader_eoh, cAlphaFields[9], Alphas[9])
                ErrorsFound = True
            else:
                state.dataSwimmingPools.Pool[Item].peopleHeatGainSched = sched
    
    if ErrorsFound:
        ShowFatalError(state, f"{RoutineName}Errors found in swimming pool input. Preceding conditions cause termination.")

def UpdatePoolSourceValAvg(state: EnergyPlusData, SwimmingPoolOn: bool) -> None:
    CloseEnough = 0.01
    
    SwimmingPoolOn = False
    
    if state.dataSwimmingPools.NumSwimmingPools == 0:
        return
    
    for PoolNum in range(state.dataSwimmingPools.NumSwimmingPools):
        thisPool = state.dataSwimmingPools.Pool[PoolNum]
        if thisPool.QPoolSrcAvg != 0.0:
            SwimmingPoolOn = True
        SurfNum = thisPool.SurfacePtr
        state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] = thisPool.QPoolSrcAvg
        state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] = thisPool.HeatTransCoefsAvg
    
    for SurfNum in range(state.dataSurface.TotSurfaces):
        if state.dataSurface.Surface[SurfNum].ExtBoundCond > 0 and state.dataSurface.Surface[SurfNum].ExtBoundCond != SurfNum:
            if abs(state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] - 
                   state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond]) > CloseEnough:
                if abs(state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum]) > abs(state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond]):
                    state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond] = state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum]
                else:
                    state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] = state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond]
    
    for SurfNum in range(state.dataSurface.TotSurfaces):
        if state.dataSurface.Surface[SurfNum].ExtBoundCond > 0 and state.dataSurface.Surface[SurfNum].ExtBoundCond != SurfNum:
            if abs(state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] - 
                   state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond]) > CloseEnough:
                if abs(state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum]) > abs(state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond]):
                    state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond] = state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum]
                else:
                    state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] = state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond]

def MakeUpWaterVolFlowFunct(MakeUpWaterMassFlowRate: float, Density: float) -> float:
    return MakeUpWaterMassFlowRate / Density

def MakeUpWaterVolFunct(MakeUpWaterMass: float, Density: float) -> float:
    return MakeUpWaterMass / Density

def ShowSevereError(state: EnergyPlusData, msg: str) -> None: pass
def ShowWarningError(state: EnergyPlusData, msg: str) -> None: pass
def ShowContinueError(state: EnergyPlusData, msg: str) -> None: pass
def ShowFatalError(state: EnergyPlusData, msg: str) -> None: pass
def ShowSevereItemNotFound(state: EnergyPlusData, eoh: dict, field: str, value: str) -> None: pass
def ShowSevereEmptyField(state: EnergyPlusData, eoh: dict, field: str) -> None: pass
def SetupOutputVariable(state: EnergyPlusData, *args) -> None: pass
def SameString(a: str, b: str) -> bool: return a.lower() == b.lower()
def HeatBalanceSurfaceManager_CalcHeatBalanceInsideSurf(state: EnergyPlusData) -> None: pass
def PlantUtilities_SetComponentFlowRate(state: EnergyPlusData, mdot: float, inlet: int, outlet: int, loc: PlantLocation) -> None: pass
def PlantUtilities_InitComponentNodes(state: EnergyPlusData, minflow: float, maxflow: float, inlet: int, outlet: int) -> None: pass
def PlantUtilities_RegisterPlantCompDesignFlow(state: EnergyPlusData, inlet: int, flow: float) -> None: pass
def PlantUtilities_SafeCopyPlantNode(state: EnergyPlusData, inlet: int, outlet: int) -> None: pass
def PlantUtilities_ScanPlantLoopsForObject(state: EnergyPlusData, name: str, equip_type: int, loc: PlantLocation, errFlag: bool) -> None: pass
def Psychrometrics_PsyPsatFnTemp(state: EnergyPlusData, temp: float, routine: str) -> float: return 0.0
def Psychrometrics_PsyRhFnTdbWPb(state: EnergyPlusData, tdb: float, w: float, pb: float) -> float: return 0.0
def Psychrometrics_PsyHfgAirFnWTdb(w: float, tdb: float) -> float: return 0.0
def Sched_GetSchedule(state: EnergyPlusData, name: str) -> Optional[Schedule]: return None
def Sched_ShowSevereBadMinMax(state: EnergyPlusData, eoh: dict, field: str, name: str, lo_clusive: str, lo_val: float, hi_clusive: str, hi_val: float) -> None: pass
def Fluid_GetWater(state: EnergyPlusData) -> Optional[GlycolProps]: return None
def Node_GetOnlySingleNode(state: EnergyPlusData, name: str, errfound: bool, *args) -> int: return 0
def Node_TestCompSet(state: EnergyPlusData, *args) -> None: pass

class Units:
    m3_s = "m3/s"
    m3 = "m3"
    C = "C"
    kg_s = "kg/s"
    W = "W"
    J = "J"
    Pa = "Pa"
    None_ = "None"

class OutputProcessor_TimeStepType:
    System = "System"

class OutputProcessor_StoreType:
    Average = "Average"
    Sum = "Sum"

class OutputProcessor_Group:
    HVAC = "HVAC"

class OutputProcessor_EndUseCat:
    Heating = "Heating"
    HeatingCoils = "HeatingCoils"

class eResource:
    MainsWater = "MainsWater"
    EnergyTransfer = "EnergyTransfer"

class DataSurfaces_HeatTransferModel:
    CTF = 0

class DataSurfaces_SurfaceClass:
    Floor = 0
    Window = 1

class DataPlant_PlantEquipmentType:
    SwimmingPool_Indoor = 0

class DataConversions_CFA:
    pass

class DataConversions_CFMF:
    pass

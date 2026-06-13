from Array1D import Array1D, Array1D_bool
from DataGlobals import *
from EnergyPlus import *
from PlantComponent import PlantComponent
from BranchNodeConnections import *
from Construction import *
from .Data.EnergyPlusData import EnergyPlusData
from DataConversions import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalFanSys import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataLoopNode import *
from DataSizing import *
from DataSurfaceLists import *
from DataSurfaces import *
from FluidProperties import *
from General import *
from GeneralRoutines import *
from HeatBalanceSurfaceManager import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from Plant.DataPlant import *
from Plant.PlantLocation import PlantLocation
from PlantUtilities import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from math import *
from format import *

struct SwimmingPoolData(PlantComponent):
    var Name: String
    var SurfaceName: String
    var SurfacePtr: Int
    var ZoneName: String
    var ZonePtr: Int
    var WaterInletNodeName: String
    var WaterInletNode: Int
    var WaterOutletNodeName: String
    var WaterOutletNode: Int
    var HWplantLoc: PlantLocation
    var WaterVolFlowMax: Float64
    var WaterMassFlowRateMax: Float64
    var AvgDepth: Float64
    var ActivityFactor: Float64
    var activityFactorSched: Optional[Sched.Schedule]
    var CurActivityFactor: Float64
    var makeupWaterSupplySched: Optional[Sched.Schedule]
    var CurMakeupWaterTemp: Float64
    var coverSched: Optional[Sched.Schedule]
    var CurCoverSchedVal: Float64
    var CoverEvapFactor: Float64
    var CoverConvFactor: Float64
    var CoverSWRadFactor: Float64
    var CoverLWRadFactor: Float64
    var CurCoverEvapFac: Float64
    var CurCoverConvFac: Float64
    var CurCoverSWRadFac: Float64
    var CurCoverLWRadFac: Float64
    var RadConvertToConvect: Float64
    var MiscPowerFactor: Float64
    var setPtTempSched: Optional[Sched.Schedule]
    var CurSetPtTemp: Float64
    var MaxNumOfPeople: Float64
    var peopleSched: Optional[Sched.Schedule]
    var peopleHeatGainSched: Optional[Sched.Schedule]
    var PeopleHeatGain: Float64
    var glycol: Optional[Fluid.GlycolProps]
    var WaterMass: Float64
    var SatPressPoolWaterTemp: Float64
    var PartPressZoneAirTemp: Float64
    var PoolWaterTemp: Float64
    var WaterInletTemp: Float64
    var WaterOutletTemp: Float64
    var WaterMassFlowRate: Float64
    var MakeUpWaterMassFlowRate: Float64
    var MakeUpWaterMass: Float64
    var MakeUpWaterVolFlowRate: Float64
    var MakeUpWaterVol: Float64
    var HeatPower: Float64
    var HeatEnergy: Float64
    var MiscEquipPower: Float64
    var MiscEquipEnergy: Float64
    var RadConvertToConvectRep: Float64
    var EvapHeatLossRate: Float64
    var EvapEnergyLoss: Float64
    var MyOneTimeFlag: Bool
    var MyEnvrnFlagGeneral: Bool
    var MyPlantScanFlagPool: Bool
    var QPoolSrcAvg: Float64
    var HeatTransCoefsAvg: Float64
    var ZeroPoolSourceSumHATsurf: Float64
    var LastQPoolSrc: Float64
    var LastHeatTransCoefs: Float64
    var LastSysTimeElapsed: Float64
    var LastTimeStepSys: Float64

    def __init__(inout self):
        self.SurfacePtr = 0
        self.ZonePtr = 0
        self.WaterInletNode = 0
        self.WaterOutletNode = 0
        self.HWplantLoc = PlantLocation()
        self.WaterVolFlowMax = 0.0
        self.WaterMassFlowRateMax = 0.0
        self.AvgDepth = 0.0
        self.ActivityFactor = 0.0
        self.CurActivityFactor = 0.0
        self.CurMakeupWaterTemp = 0.0
        self.CurCoverSchedVal = 0.0
        self.CoverEvapFactor = 0.0
        self.CoverConvFactor = 0.0
        self.CoverSWRadFactor = 0.0
        self.CoverLWRadFactor = 0.0
        self.CurCoverEvapFac = 0.0
        self.CurCoverConvFac = 0.0
        self.CurCoverSWRadFac = 0.0
        self.CurCoverLWRadFac = 0.0
        self.RadConvertToConvect = 0.0
        self.MiscPowerFactor = 0.0
        self.CurSetPtTemp = 23.0
        self.MaxNumOfPeople = 0.0
        self.PeopleHeatGain = 0.0
        self.WaterMass = 0.0
        self.SatPressPoolWaterTemp = 0.0
        self.PartPressZoneAirTemp = 0.0
        self.PoolWaterTemp = 23.0
        self.WaterInletTemp = 0.0
        self.WaterOutletTemp = 0.0
        self.WaterMassFlowRate = 0.0
        self.MakeUpWaterMassFlowRate = 0.0
        self.MakeUpWaterMass = 0.0
        self.MakeUpWaterVolFlowRate = 0.0
        self.MakeUpWaterVol = 0.0
        self.HeatPower = 0.0
        self.HeatEnergy = 0.0
        self.MiscEquipPower = 0.0
        self.MiscEquipEnergy = 0.0
        self.RadConvertToConvectRep = 0.0
        self.EvapHeatLossRate = 0.0
        self.EvapEnergyLoss = 0.0
        self.MyOneTimeFlag = True
        self.MyEnvrnFlagGeneral = True
        self.MyPlantScanFlagPool = True
        self.QPoolSrcAvg = 0.0
        self.HeatTransCoefsAvg = 0.0
        self.ZeroPoolSourceSumHATsurf = 0.0
        self.LastQPoolSrc = 0.0
        self.LastHeatTransCoefs = 0.0
        self.LastSysTimeElapsed = 0.0
        self.LastTimeStepSys = 0.0

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> Optional[SwimmingPoolData]:
        if state.dataSwimmingPools.getSwimmingPoolInput:
            GetSwimmingPool(state)
            state.dataSwimmingPools.getSwimmingPoolInput = False
        for pool in state.dataSwimmingPools.Pool:
            if pool.Name == objectName:
                return Optional(pool)
        ShowFatalError(state, format("LocalSwimmingPoolFactory: Error getting inputs or index for swimming pool named: {}", objectName))
        return Optional[SwimmingPoolData]()

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, inout RunFlag: Bool):
        state.dataHeatBalFanSys.SumConvPool[self.ZonePtr] = 0.0
        state.dataHeatBalFanSys.SumLatentPool[self.ZonePtr] = 0.0
        CurLoad = 0.0
        RunFlag = True
        self.initialize(state, FirstHVACIteration)
        self.calculate(state)
        self.update(state)
        if state.dataSwimmingPools.NumSwimmingPools > 0:
            HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state)
        self.report(state)

    def ErrorCheckSetupPoolSurface(inout self, state: EnergyPlusData, Alpha1: String, Alpha2: String, cAlphaField2: String, inout ErrorsFound: Bool):
        var RoutineName: String = "ErrorCheckSetupPoolSurface: "
        var CurrentModuleObject: String = "SwimmingPool:Indoor"
        if self.SurfacePtr <= 0:
            ShowSevereError(state, format("{}Invalid {} = {}", RoutineName, cAlphaField2, Alpha2))
            ShowContinueError(state, format("Occurs in {} = {}", CurrentModuleObject, Alpha1))
            ErrorsFound = True
        elif state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[self.SurfacePtr]:
            ShowSevereError(state, format("{}{}=\"{}\", Invalid Surface", RoutineName, CurrentModuleObject, Alpha1))
            ShowContinueError(state, format("{}=\"{}\" has been used in another radiant system, ventilated slab, or pool.", cAlphaField2, Alpha2))
            ShowContinueError(state, "A single surface can only be a radiant system, a ventilated slab, or a pool.  It CANNOT be more than one of these.")
            ErrorsFound = True
        elif state.dataSurface.Surface[self.SurfacePtr].HeatTransferAlgorithm != DataSurfaces.HeatTransferModel.CTF:
            ShowSevereError(state, format("{} is a pool and is attempting to use a non-CTF solution algorithm.  This is not allowed.  Use the CTF solution algorithm for this surface.", state.dataSurface.Surface[self.SurfacePtr].Name))
            ErrorsFound = True
        elif state.dataSurface.Surface[self.SurfacePtr].Class == DataSurfaces.SurfaceClass.Window:
            ShowSevereError(state, format("{} is a pool and is defined as a window.  This is not allowed.  A pool must be a floor that is NOT a window.", state.dataSurface.Surface[self.SurfacePtr].Name))
            ErrorsFound = True
        elif state.dataSurface.intMovInsuls[self.SurfacePtr].matNum > 0:
            ShowSevereError(state, format("{} is a pool and has movable insulation.  This is not allowed.  Remove the movable insulation for this surface.", state.dataSurface.Surface[self.SurfacePtr].Name))
            ErrorsFound = True
        elif state.dataConstruction.Construct[state.dataSurface.Surface[self.SurfacePtr].Construction].SourceSinkPresent:
            ShowSevereError(state, format("{} is a pool and uses a construction with a source/sink.  This is not allowed.  Use a standard construction for this surface.", state.dataSurface.Surface[self.SurfacePtr].Name))
            ErrorsFound = True
        else:
            state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[self.SurfacePtr] = True
            state.dataSurface.SurfIsPool[self.SurfacePtr] = True
            self.ZonePtr = state.dataSurface.Surface[self.SurfacePtr].Zone
            if state.dataSurface.Surface[self.SurfacePtr].Class != DataSurfaces.SurfaceClass.Floor:
                ShowSevereError(state, format("{}{}=\"{} contains a surface name that is NOT a floor.", RoutineName, CurrentModuleObject, Alpha1))
                ShowContinueError(state, "A swimming pool must be associated with a surface that is a FLOOR.  Association with other surface types is not permitted.")
                ErrorsFound = True

    def initialize(inout self, state: EnergyPlusData, FirstHVACIteration: Bool):
        var RoutineName: String = "InitSwimmingPool"
        var MinActivityFactor: Float64 = 0.0
        var MaxActivityFactor: Float64 = 10.0
        var HeatGainPerPerson: Float64 = self.peopleHeatGainSched.getCurrentVal()
        var PeopleModifier: Float64 = self.peopleSched.getCurrentVal()
        if self.MyOneTimeFlag:
            self.setupOutputVars(state)
            self.MyOneTimeFlag = False
        SwimmingPoolData.initSwimmingPoolPlantLoopIndex(state)
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
            var Density: Float64 = self.glycol.getDensity(state, self.PoolWaterTemp, RoutineName)
            self.WaterMass = state.dataSurface.Surface[self.SurfacePtr].Area * self.AvgDepth * Density
            self.WaterMassFlowRateMax = self.WaterVolFlowMax * Density
            self.initSwimmingPoolPlantNodeFlow(state)
        if state.dataGlobal.BeginTimeStepFlag and FirstHVACIteration:
            var ZoneNum: Int = self.ZonePtr
            self.ZeroPoolSourceSumHATsurf = state.dataHeatBal.Zone[ZoneNum].sumHATsurf(state)
            self.QPoolSrcAvg = 0.0
            self.HeatTransCoefsAvg = 0.0
            self.LastQPoolSrc = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0
        var mdot: Float64 = 0.0
        PlantUtilities.SetComponentFlowRate(state, mdot, self.WaterInletNode, self.WaterOutletNode, self.HWplantLoc)
        self.WaterInletTemp = state.dataLoopNodes.Node[self.WaterInletNode].Temp
        if self.activityFactorSched:
            self.CurActivityFactor = self.activityFactorSched.getCurrentVal()
            if self.CurActivityFactor < MinActivityFactor:
                self.CurActivityFactor = MinActivityFactor
                ShowWarningError(state, format("{}: Swimming Pool =\"{} Activity Factor Schedule =\"{} has a negative value.  This is not allowed.", RoutineName, self.Name, self.activityFactorSched.Name))
                ShowContinueError(state, "The activity factor has been reset to zero.")
            if self.CurActivityFactor > MaxActivityFactor:
                self.CurActivityFactor = 1.0
                ShowWarningError(state, format("{}: Swimming Pool =\"{} Activity Factor Schedule =\"{} has a value larger than 10.  This is not allowed.", RoutineName, self.Name, self.activityFactorSched.Name))
                ShowContinueError(state, "The activity factor has been reset to unity.")
        else:
            self.CurActivityFactor = 1.0
        self.CurSetPtTemp = self.setPtTempSched.getCurrentVal()
        if self.makeupWaterSupplySched:
            self.CurMakeupWaterTemp = self.makeupWaterSupplySched.getCurrentVal()
        else:
            self.CurMakeupWaterTemp = state.dataEnvrn.WaterMainsTemp
        if self.peopleHeatGainSched:
            if HeatGainPerPerson < 0.0:
                ShowWarningError(state, format("{}: Swimming Pool =\"{} Heat Gain Schedule =\"{} has a negative value.  This is not allowed.", RoutineName, self.Name, self.peopleHeatGainSched.Name))
                ShowContinueError(state, "The heat gain per person has been reset to zero.")
                HeatGainPerPerson = 0.0
            if self.peopleSched:
                if PeopleModifier < 0.0:
                    ShowWarningError(state, format("{}: Swimming Pool =\"{} People Schedule =\"{} has a negative value.  This is not allowed.", RoutineName, self.Name, self.peopleSched.Name))
                    ShowContinueError(state, "The number of people has been reset to zero.")
                    PeopleModifier = 0.0
            else:
                PeopleModifier = 1.0
        else:
            HeatGainPerPerson = 0.0
            PeopleModifier = 0.0
        self.PeopleHeatGain = PeopleModifier * HeatGainPerPerson * self.MaxNumOfPeople
        if self.coverSched:
            self.CurCoverSchedVal = self.coverSched.getCurrentVal()
            if self.CurCoverSchedVal > 1.0:
                ShowWarningError(state, format("{}: Swimming Pool =\"{} Cover Schedule =\"{} has a value greater than 1.0 (100%).  This is not allowed.", RoutineName, self.Name, self.coverSched.Name))
                ShowContinueError(state, "The cover has been reset to one or fully covered.")
                self.CurCoverSchedVal = 1.0
            elif self.CurCoverSchedVal < 0.0:
                ShowWarningError(state, format("{}: Swimming Pool =\"{} Cover Schedule =\"{} has a negative value.  This is not allowed.", RoutineName, self.Name, self.coverSched.Name))
                ShowContinueError(state, "The cover has been reset to zero or uncovered.")
                self.CurCoverSchedVal = 0.0
        else:
            self.CurCoverSchedVal = 0.0
        self.CurCoverEvapFac = 1.0 - (self.CurCoverSchedVal * self.CoverEvapFactor)
        self.CurCoverConvFac = 1.0 - (self.CurCoverSchedVal * self.CoverConvFactor)
        self.CurCoverSWRadFac = 1.0 - (self.CurCoverSchedVal * self.CoverSWRadFactor)
        self.CurCoverLWRadFac = 1.0 - (self.CurCoverSchedVal * self.CoverLWRadFactor)

    def setupOutputVars(inout self, state: EnergyPlusData):
        SetupOutputVariable(state, "Indoor Pool Makeup Water Rate", Constant.Units.m3_s, self.MakeUpWaterVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Makeup Water Volume", Constant.Units.m3, self.MakeUpWaterVol, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.MainsWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Heating)
        SetupOutputVariable(state, "Indoor Pool Makeup Water Temperature", Constant.Units.C, self.CurMakeupWaterTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Water Temperature", Constant.Units.C, self.PoolWaterTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Inlet Water Temperature", Constant.Units.C, self.WaterInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Inlet Water Mass Flow Rate", Constant.Units.kg_s, self.WaterMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Miscellaneous Equipment Power", Constant.Units.W, self.MiscEquipPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Miscellaneous Equipment Energy", Constant.Units.J, self.MiscEquipEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Indoor Pool Water Heating Rate", Constant.Units.W, self.HeatPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Water Heating Energy", Constant.Units.J, self.HeatEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Indoor Pool Radiant to Convection by Cover", Constant.Units.W, self.RadConvertToConvect, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool People Heat Gain", Constant.Units.W, self.PeopleHeatGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Activity Factor", Constant.Units.None, self.CurActivityFactor, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover Factor", Constant.Units.None, self.CurCoverSchedVal, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Evaporative Heat Loss Rate", Constant.Units.W, self.EvapHeatLossRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Evaporative Heat Loss Energy", Constant.Units.J, self.EvapEnergyLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, self.Name)
        SetupOutputVariable(state, "Indoor Pool Saturation Pressure at Pool Temperature", Constant.Units.Pa, self.SatPressPoolWaterTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Partial Pressure of Water Vapor in Air", Constant.Units.Pa, self.PartPressZoneAirTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover Evaporation Factor", Constant.Units.None, self.CurCoverEvapFac, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover Convective Factor", Constant.Units.None, self.CurCoverConvFac, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover SW Radiation Factor", Constant.Units.None, self.CurCoverSWRadFac, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)
        SetupOutputVariable(state, "Indoor Pool Current Cover LW Radiation Factor", Constant.Units.None, self.CurCoverLWRadFac, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, self.Name)

    def initSwimmingPoolPlantLoopIndex(inout self, state: EnergyPlusData):
        var RoutineName: String = "InitSwimmingPoolPlantLoopIndex"
        if self.MyPlantScanFlagPool and allocated(state.dataPlnt.PlantLoop):
            if self.WaterInletNode > 0:
                var errFlag: Bool = False
                PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.SwimmingPool_Indoor, self.HWplantLoc, errFlag, _, _, _, self.WaterInletNode, _)
                if errFlag:
                    ShowFatalError(state, format("{}: Program terminated due to previous condition(s).", RoutineName))
            self.MyPlantScanFlagPool = False
        elif self.MyPlantScanFlagPool and not state.dataGlobal.AnyPlantInModel:
            self.MyPlantScanFlagPool = False

    def initSwimmingPoolPlantNodeFlow(inout self, state: EnergyPlusData):
        if not self.MyPlantScanFlagPool:
            if self.WaterInletNode > 0:
                PlantUtilities.InitComponentNodes(state, 0.0, self.WaterMassFlowRateMax, self.WaterInletNode, self.WaterOutletNode)
                PlantUtilities.RegisterPlantCompDesignFlow(state, self.WaterInletNode, self.WaterVolFlowMax)

    def calculate(inout self, state: EnergyPlusData):
        var RoutineName: String = "CalcSwimmingPool"
        var EvapRate: Float64 = 0.0
        var SurfNum: Int = self.SurfacePtr
        var ZoneNum: Int = state.dataSurface.Surface[SurfNum].Zone
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum]
        var HConvIn: Float64 = 0.22 * pow(abs(self.PoolWaterTemp - thisZoneHB.MAT), 1.0 / 3.0) * self.CurCoverConvFac
        self.calcSwimmingPoolEvap(state, EvapRate, SurfNum, thisZoneHB.MAT, thisZoneHB.airHumRat)
        self.MakeUpWaterMassFlowRate = EvapRate
        var EvapEnergyLossPerArea: Float64 = -EvapRate * Psychrometrics.PsyHfgAirFnWTdb(thisZoneHB.airHumRat, thisZoneHB.MAT) / state.dataSurface.Surface[SurfNum].Area
        self.EvapHeatLossRate = EvapEnergyLossPerArea * state.dataSurface.Surface[SurfNum].Area
        var LWsum: Float64 = (state.dataHeatBal.SurfQdotRadIntGainsInPerArea[SurfNum] + state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea[SurfNum] + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[SurfNum])
        var LWtotal: Float64 = self.CurCoverLWRadFac * LWsum
        var SWtotal: Float64 = self.CurCoverSWRadFac * state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[SurfNum]
        self.RadConvertToConvect = ((1.0 - self.CurCoverLWRadFac) * LWsum) + ((1.0 - self.CurCoverSWRadFac) * state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[SurfNum])
        var PeopleGain: Float64 = self.PeopleHeatGain / state.dataSurface.Surface[SurfNum].Area
        var Cp: Float64 = self.glycol.getSpecificHeat(state, self.PoolWaterTemp, RoutineName)
        var TH22: Float64 = state.dataHeatBalSurf.SurfInsideTempHist[2][SurfNum]
        var Tmuw: Float64 = self.CurMakeupWaterTemp
        var TLoopInletTemp: Float64 = state.dataLoopNodes.Node[self.WaterInletNode].Temp
        self.WaterInletTemp = TLoopInletTemp
        var MassFlowRate: Float64
        self.calcMassFlowRate(state, MassFlowRate, TH22, TLoopInletTemp)
        PlantUtilities.SetComponentFlowRate(state, MassFlowRate, self.WaterInletNode, self.WaterOutletNode, self.HWplantLoc)
        self.WaterMassFlowRate = MassFlowRate
        state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] = SWtotal + LWtotal + PeopleGain + EvapEnergyLossPerArea + HConvIn * thisZoneHB.MAT + (EvapRate * Tmuw + MassFlowRate * TLoopInletTemp + (self.WaterMass * TH22 / state.dataGlobal.TimeStepZoneSec)) * Cp / state.dataSurface.Surface[SurfNum].Area
        state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] = HConvIn + (EvapRate + MassFlowRate + (self.WaterMass / state.dataGlobal.TimeStepZoneSec)) * Cp / state.dataSurface.Surface[SurfNum].Area
        state.dataHeatBalFanSys.SumConvPool[ZoneNum] += self.RadConvertToConvect
        state.dataHeatBalFanSys.SumLatentPool[ZoneNum] += EvapRate * Psychrometrics.PsyHfgAirFnWTdb(thisZoneHB.airHumRat, thisZoneHB.MAT)

    def calcMassFlowRate(inout self, state: EnergyPlusData, inout massFlowRate: Float64, TH22: Float64, TLoopInletTemp: Float64):
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

    def calcSwimmingPoolEvap(inout self, state: EnergyPlusData, inout EvapRate: Float64, SurfNum: Int, MAT: Float64, HumRat: Float64):
        var RoutineName: String = "CalcSwimmingPoolEvap"
        var CFinHg: Float64 = 0.00029613
        var PSatPool: Float64 = Psychrometrics.PsyPsatFnTemp(state, self.PoolWaterTemp, RoutineName)
        var PParAir: Float64 = Psychrometrics.PsyPsatFnTemp(state, MAT, RoutineName) * Psychrometrics.PsyRhFnTdbWPb(state, MAT, HumRat, state.dataEnvrn.OutBaroPress)
        if PSatPool < PParAir:
            PSatPool = PParAir
        self.SatPressPoolWaterTemp = PSatPool
        self.PartPressZoneAirTemp = PParAir
        EvapRate = (0.1 * (state.dataSurface.Surface[SurfNum].Area / DataConversions.CFA) * self.CurActivityFactor * ((PSatPool - PParAir) * CFinHg)) * DataConversions.CFMF * self.CurCoverEvapFac

    def update(inout self, state: EnergyPlusData):
        var SurfNum: Int = self.SurfacePtr
        if self.LastSysTimeElapsed == state.dataHVACGlobal.SysTimeElapsed:
            self.QPoolSrcAvg -= self.LastQPoolSrc * self.LastTimeStepSys / state.dataGlobal.TimeStepZone
            self.HeatTransCoefsAvg -= self.LastHeatTransCoefs * self.LastTimeStepSys / state.dataGlobal.TimeStepZone
        self.QPoolSrcAvg += state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] * state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone
        self.HeatTransCoefsAvg += state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] * state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone
        self.LastQPoolSrc = state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum]
        self.LastHeatTransCoefs = state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum]
        self.LastSysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
        self.LastTimeStepSys = state.dataHVACGlobal.TimeStepSys
        PlantUtilities.SafeCopyPlantNode(state, self.WaterInletNode, self.WaterOutletNode)
        var WaterMassFlow: Float64 = state.dataLoopNodes.Node[self.WaterInletNode].MassFlowRate
        if WaterMassFlow > 0.0:
            state.dataLoopNodes.Node[self.WaterOutletNode].Temp = self.PoolWaterTemp

    def oneTimeInit_new(inout self, state: EnergyPlusData):

    def oneTimeInit(inout self, state: EnergyPlusData):

    def report(inout self, state: EnergyPlusData):
        var RoutineName: String = "SwimmingPoolData::report"
        var MinDensity: Float64 = 1.0
        var SurfNum: Int = self.SurfacePtr
        self.PoolWaterTemp = state.dataHeatBalSurf.SurfInsideTempHist[1][SurfNum]
        var Cp: Float64 = self.glycol.getSpecificHeat(state, self.PoolWaterTemp, RoutineName)
        self.HeatPower = self.WaterMassFlowRate * Cp * (self.WaterInletTemp - self.PoolWaterTemp)
        var Density: Float64 = self.glycol.getDensity(state, self.PoolWaterTemp, RoutineName)
        if Density > MinDensity:
            self.MiscEquipPower = self.MiscPowerFactor * self.WaterMassFlowRate / Density
        else:
            self.MiscEquipPower = 0.0
        self.RadConvertToConvectRep = self.RadConvertToConvect * state.dataSurface.Surface[SurfNum].Area
        var thisTimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
        self.MiscEquipEnergy = self.MiscEquipPower * thisTimeStepSysSec
        self.HeatEnergy = self.HeatPower * thisTimeStepSysSec
        self.MakeUpWaterMass = self.MakeUpWaterMassFlowRate * thisTimeStepSysSec
        self.EvapEnergyLoss = self.EvapHeatLossRate * thisTimeStepSysSec
        self.MakeUpWaterVolFlowRate = MakeUpWaterVolFlowFunct(self.MakeUpWaterMassFlowRate, Density)
        self.MakeUpWaterVol = MakeUpWaterVolFunct(self.MakeUpWaterMass, Density)

def GetSwimmingPool(state: EnergyPlusData):
    var RoutineName: String = "GetSwimmingPool: "
    var routineName: String = "GetSwimmingPool"
    var MinCoverFactor: Float64 = 0.0
    var MaxCoverFactor: Float64 = 1.0
    var MinDepth: Float64 = 0.05
    var MaxDepth: Float64 = 10.0
    var MinPowerFactor: Float64 = 0.0
    var ErrorsFound: Bool = False
    var CurrentModuleObject: String
    var Alphas: Array1D_string
    var cAlphaFields: Array1D_string
    var cNumericFields: Array1D_string
    var IOStatus: Int = 0
    var Numbers: Array1D[Float64]
    var NumAlphas: Int = 0
    var NumArgs: Int = 0
    var NumNumbers: Int = 0
    var lAlphaBlanks: Array1D_bool
    var lNumericBlanks: Array1D_bool
    var MaxAlphas: Int = 0
    var MaxNumbers: Int = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "SwimmingPool:Indoor", NumArgs, NumAlphas, NumNumbers)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    MaxNumbers = max(MaxNumbers, NumNumbers)
    Alphas.allocate(MaxAlphas)
    Alphas = ""
    Numbers.allocate(MaxNumbers)
    Numbers = 0.0
    cAlphaFields.allocate(MaxAlphas)
    cAlphaFields = ""
    cNumericFields.allocate(MaxNumbers)
    cNumericFields = ""
    lAlphaBlanks.allocate(MaxAlphas)
    lAlphaBlanks = True
    lNumericBlanks.allocate(MaxNumbers)
    lNumericBlanks = True
    state.dataSwimmingPools.NumSwimmingPools = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "SwimmingPool:Indoor")
    state.dataSwimmingPools.CheckEquipName.allocate(state.dataSwimmingPools.NumSwimmingPools)
    state.dataSwimmingPools.CheckEquipName = True
    state.dataSwimmingPools.Pool.allocate(state.dataSwimmingPools.NumSwimmingPools)
    CurrentModuleObject = "SwimmingPool:Indoor"
    for Item in range(1, state.dataSwimmingPools.NumSwimmingPools + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Item, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, Alphas[1])
        state.dataSwimmingPools.Pool[Item].Name = Alphas[1]
        state.dataSwimmingPools.Pool[Item].SurfaceName = Alphas[2]
        state.dataSwimmingPools.Pool[Item].SurfacePtr = 0
        state.dataSwimmingPools.Pool[Item].glycol = Fluid.GetWater(state)
        for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
            if Util.SameString(state.dataSurface.Surface[SurfNum].Name, state.dataSwimmingPools.Pool[Item].SurfaceName):
                state.dataSwimmingPools.Pool[Item].SurfacePtr = SurfNum
                break
        state.dataSwimmingPools.Pool[Item].ErrorCheckSetupPoolSurface(state, Alphas[1], Alphas[2], cAlphaFields[2], ErrorsFound)
        state.dataSwimmingPools.Pool[Item].AvgDepth = Numbers[1]
        if state.dataSwimmingPools.Pool[Item].AvgDepth < MinDepth:
            ShowWarningError(state, format("{}{}=\"{} has an average depth that is too small.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The pool average depth has been reset to the minimum allowed depth.")
        elif state.dataSwimmingPools.Pool[Item].AvgDepth > MaxDepth:
            ShowSevereError(state, format("{}{}=\"{} has an average depth that is too large.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The pool depth must be less than the maximum average depth of 10 meters.")
            ErrorsFound = True
        if lAlphaBlanks[3]:

        elif (state.dataSwimmingPools.Pool[Item].activityFactorSched = Sched.GetSchedule(state, Alphas[3])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[3], Alphas[3])
            ErrorsFound = True
        if lAlphaBlanks[4]:

        elif (state.dataSwimmingPools.Pool[Item].makeupWaterSupplySched = Sched.GetSchedule(state, Alphas[4])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[4], Alphas[4])
            ErrorsFound = True
        if lAlphaBlanks[5]:

        elif (state.dataSwimmingPools.Pool[Item].coverSched = Sched.GetSchedule(state, Alphas[5])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[5], Alphas[5])
            ErrorsFound = True
        elif not state.dataSwimmingPools.Pool[Item].coverSched.checkMinMaxVals(state, Clusive.In, 0.0, Clusive.In, 1.0):
            Sched.ShowSevereBadMinMax(state, eoh, cAlphaFields[5], Alphas[5], Clusive.In, 0.0, Clusive.In, 1.0)
            ErrorsFound = True
        state.dataSwimmingPools.Pool[Item].CoverEvapFactor = Numbers[2]
        if state.dataSwimmingPools.Pool[Item].CoverEvapFactor < MinCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has an evaporation cover factor less than zero.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The evaporation cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverEvapFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverEvapFactor > MaxCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has an evaporation cover factor greater than one.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The evaporation cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverEvapFactor = MaxCoverFactor
        state.dataSwimmingPools.Pool[Item].CoverConvFactor = Numbers[3]
        if state.dataSwimmingPools.Pool[Item].CoverConvFactor < MinCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has a convection cover factor less than zero.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The convection cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverConvFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverConvFactor > MaxCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has a convection cover factor greater than one.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The convection cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverConvFactor = MaxCoverFactor
        state.dataSwimmingPools.Pool[Item].CoverSWRadFactor = Numbers[4]
        if state.dataSwimmingPools.Pool[Item].CoverSWRadFactor < MinCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has a short-wavelength radiation cover factor less than zero.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The short-wavelength radiation cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverSWRadFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverSWRadFactor > MaxCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has a short-wavelength radiation cover factor greater than one.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The short-wavelength radiation cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverSWRadFactor = MaxCoverFactor
        state.dataSwimmingPools.Pool[Item].CoverLWRadFactor = Numbers[5]
        if state.dataSwimmingPools.Pool[Item].CoverLWRadFactor < MinCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has a long-wavelength radiation cover factor less than zero.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The long-wavelength radiation cover factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].CoverLWRadFactor = MinCoverFactor
        elif state.dataSwimmingPools.Pool[Item].CoverLWRadFactor > MaxCoverFactor:
            ShowWarningError(state, format("{}{}=\"{} has a long-wavelength radiation cover factor greater than one.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The long-wavelength radiation cover factor has been reset to one.")
            state.dataSwimmingPools.Pool[Item].CoverLWRadFactor = MaxCoverFactor
        state.dataSwimmingPools.Pool[Item].WaterInletNodeName = Alphas[6]
        state.dataSwimmingPools.Pool[Item].WaterOutletNodeName = Alphas[7]
        state.dataSwimmingPools.Pool[Item].WaterInletNode = Node.GetOnlySingleNode(state, Alphas[6], ErrorsFound, Node.ConnectionObjectType.SwimmingPoolIndoor, Alphas[1], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        state.dataSwimmingPools.Pool[Item].WaterOutletNode = Node.GetOnlySingleNode(state, Alphas[7], ErrorsFound, Node.ConnectionObjectType.SwimmingPoolIndoor, Alphas[1], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        if (not lAlphaBlanks[6]) or (not lAlphaBlanks[7]):
            Node.TestCompSet(state, CurrentModuleObject, Alphas[1], Alphas[6], Alphas[7], "Hot Water Nodes")
        state.dataSwimmingPools.Pool[Item].WaterVolFlowMax = Numbers[6]
        state.dataSwimmingPools.Pool[Item].MiscPowerFactor = Numbers[7]
        if state.dataSwimmingPools.Pool[Item].MiscPowerFactor < MinPowerFactor:
            ShowWarningError(state, format("{}{}=\"{} has a miscellaneous power factor less than zero.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The miscellaneous power factor has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].MiscPowerFactor = MinPowerFactor
        if lAlphaBlanks[8]:
            ShowSevereEmptyField(state, eoh, cAlphaFields[8])
            ErrorsFound = True
        elif (state.dataSwimmingPools.Pool[Item].setPtTempSched = Sched.GetSchedule(state, Alphas[8])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[8], Alphas[8])
            ErrorsFound = True
        state.dataSwimmingPools.Pool[Item].MaxNumOfPeople = Numbers[8]
        if state.dataSwimmingPools.Pool[Item].MaxNumOfPeople < 0.0:
            ShowWarningError(state, format("{}{}=\"{} was entered with negative people.  This is not allowed.", RoutineName, CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, "The number of people has been reset to zero.")
            state.dataSwimmingPools.Pool[Item].MaxNumOfPeople = 0.0
        if lAlphaBlanks[9]:

        elif (state.dataSwimmingPools.Pool[Item].peopleSched = Sched.GetSchedule(state, Alphas[9])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[9], Alphas[9])
            ErrorsFound = True
        if lAlphaBlanks[10]:

        elif (state.dataSwimmingPools.Pool[Item].peopleHeatGainSched = Sched.GetSchedule(state, Alphas[10])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[10], Alphas[10])
            ErrorsFound = True
    Alphas.deallocate()
    Numbers.deallocate()
    cAlphaFields.deallocate()
    cNumericFields.deallocate()
    lAlphaBlanks.deallocate()
    lNumericBlanks.deallocate()
    if ErrorsFound:
        ShowFatalError(state, format("{}Errors found in swimming pool input. Preceding conditions cause termination.", RoutineName))

def UpdatePoolSourceValAvg(state: EnergyPlusData, inout SwimmingPoolOn: Bool):
    var CloseEnough: Float64 = 0.01
    SwimmingPoolOn = False
    if state.dataSwimmingPools.NumSwimmingPools == 0:
        return
    for PoolNum in range(1, state.dataSwimmingPools.NumSwimmingPools + 1):
        var thisPool = state.dataSwimmingPools.Pool[PoolNum]
        if thisPool.QPoolSrcAvg != 0.0:
            SwimmingPoolOn = True
        var SurfNum: Int = thisPool.SurfacePtr
        state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] = thisPool.QPoolSrcAvg
        state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] = thisPool.HeatTransCoefsAvg
    for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
        if state.dataSurface.Surface[SurfNum].ExtBoundCond > 0 and state.dataSurface.Surface[SurfNum].ExtBoundCond != SurfNum:
            if abs(state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] - state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond]) > CloseEnough:
                if abs(state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum]) > abs(state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond]):
                    state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond] = state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum]
                else:
                    state.dataHeatBalFanSys.QPoolSurfNumerator[SurfNum] = state.dataHeatBalFanSys.QPoolSurfNumerator[state.dataSurface.Surface[SurfNum].ExtBoundCond]
    for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
        if state.dataSurface.Surface[SurfNum].ExtBoundCond > 0 and state.dataSurface.Surface[SurfNum].ExtBoundCond != SurfNum:
            if abs(state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] - state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond]) > CloseEnough:
                if abs(state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum]) > abs(state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond]):
                    state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond] = state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum]
                else:
                    state.dataHeatBalFanSys.PoolHeatTransCoefs[SurfNum] = state.dataHeatBalFanSys.PoolHeatTransCoefs[state.dataSurface.Surface[SurfNum].ExtBoundCond]

def MakeUpWaterVolFlowFunct(MakeUpWaterMassFlowRate: Float64, Density: Float64) -> Float64:
    return MakeUpWaterMassFlowRate / Density

def MakeUpWaterVolFunct(MakeUpWaterMass: Float64, Density: Float64) -> Float64:
    return MakeUpWaterMass / Density

struct SwimmingPoolsData(BaseGlobalStruct):
    var NumSwimmingPools: Int = 0
    var CheckEquipName: Array1D_bool
    var getSwimmingPoolInput: Bool = True
    var Pool: Array1D[SwimmingPoolData]

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumSwimmingPools = 0
        self.getSwimmingPoolInput = True
        self.CheckEquipName.deallocate()
        self.Pool.deallocate()

    def __init__(inout self):

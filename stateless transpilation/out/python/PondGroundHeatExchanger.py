# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state container, accessed via state.dataPondGHE, state.dataIPShortCut, 
#   state.dataInputProcessing, state.dataLoopNodes, state.dataHVACGlobal, state.dataEnvrn, state.dataGlobal
# - PlantComponent: base class with virtual methods (simulate, getDesignCapacities, onInitLoopEquip, oneTimeInit)
# - BaseGlobalStruct: base class with virtual init_constant_state, init_state, clear_state
# - Node::GetOnlySingleNode, Node::TestCompSet: node registration functions
# - Fluid::GetWater: returns water fluid property object
# - Convect::CalcASHRAESimpExtConvCoeff: convection coefficient calculation
# - DataEnvironment::OutDryBulbTempAt, OutWetBulbTempAt, WindSpeedAt: environment functions
# - Psychrometrics::PsyWFnTdbTwbPb, PsyCpAirFnW, PsyHfgAirFnWTdb: psychrometric functions
# - PlantUtilities: RegulateCondenserCompFlowReqOp, SetComponentFlowRate, SafeCopyPlantNode, 
#   ScanPlantLoopsForObject, InitComponentNodes, RegisterPlantCompDesignFlow
# - OutputProcessor::SetupOutputVariable: output variable registration
# - ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowWarningMessage,
#   ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd: error/warning reporting

from typing import Protocol, Optional, Any, List
from dataclasses import dataclass, field
import math

class PlantComponent:
    def simulate(self, state: 'EnergyPlusData', calledFromLocation: 'PlantLocation', 
                 FirstHVACIteration: bool, CurLoad: List[float], RunFlag: bool) -> None:
        raise NotImplementedError
    
    def getDesignCapacities(self, state: 'EnergyPlusData', calledFromLocation: 'PlantLocation',
                           MaxLoad: List[float], MinLoad: List[float], OptLoad: List[float]) -> None:
        raise NotImplementedError
    
    def onInitLoopEquip(self, state: 'EnergyPlusData', calledFromLocation: 'PlantLocation') -> None:
        raise NotImplementedError
    
    def oneTimeInit(self, state: 'EnergyPlusData') -> None:
        raise NotImplementedError


class BaseGlobalStruct:
    def init_constant_state(self, state: 'EnergyPlusData') -> None:
        pass
    
    def init_state(self, state: 'EnergyPlusData') -> None:
        pass
    
    def clear_state(self) -> None:
        pass


class GlycolProps:
    def getDensity(self, state: 'EnergyPlusData', temperature: float, routine_name: str) -> float:
        raise NotImplementedError
    
    def getSpecificHeat(self, state: 'EnergyPlusData', temperature: float, routine_name: str) -> float:
        raise NotImplementedError
    
    def getConductivity(self, state: 'EnergyPlusData', temperature: float, routine_name: str) -> float:
        raise NotImplementedError
    
    def getViscosity(self, state: 'EnergyPlusData', temperature: float, routine_name: str) -> float:
        raise NotImplementedError


@dataclass
class PlantLoop:
    glycol: GlycolProps


@dataclass
class PlantLocation:
    loop: PlantLoop


@dataclass
class LoopNode:
    Temp: float = 0.0
    MassFlowRate: float = 0.0


@dataclass
class PondGHEData:
    GetInputFlag: bool = True
    NumOfPondGHEs: int = 0
    PondGHE: List['PondGroundHeatExchangerData'] = field(default_factory=list)
    
    def init_constant_state(self, state: 'EnergyPlusData') -> None:
        pass
    
    def init_state(self, state: 'EnergyPlusData') -> None:
        pass
    
    def clear_state(self) -> None:
        self.GetInputFlag = True
        self.NumOfPondGHEs = 0
        self.PondGHE = []


@dataclass
class IPShortCutData:
    cCurrentModuleObject: str = ""
    cAlphaArgs: List[str] = field(default_factory=list)
    rNumericArgs: List[float] = field(default_factory=list)
    cAlphaFieldNames: List[str] = field(default_factory=list)
    cNumericFieldNames: List[str] = field(default_factory=list)


@dataclass
class InputProcessorData:
    inputProcessor: Any = None


@dataclass
class LoopNodesData:
    Node: List[LoopNode] = field(default_factory=list)


@dataclass
class HVACGlobalsData:
    TimeStepSys: float = 0.0
    TimeStepSysSec: float = 0.0
    ShortenTimeStepSys: bool = False


@dataclass
class EnvironmentData:
    SkyTemp: float = 0.0
    IsSnow: bool = False
    IsRain: bool = False
    SunIsUp: bool = False
    SOLCOS: List[float] = field(default_factory=list)
    BeamSolarRad: float = 0.0
    DifSolarRad: float = 0.0
    OutBaroPress: float = 0.0
    GroundTemp: List[float] = field(default_factory=list)
    GroundTempInputs: List[bool] = field(default_factory=list)


@dataclass
class GlobalData:
    WarmupFlag: bool = False
    TimeStepsInHour: int = 0


@dataclass
class EnergyPlusData:
    dataPondGHE: PondGHEData = field(default_factory=PondGHEData)
    dataIPShortCut: IPShortCutData = field(default_factory=IPShortCutData)
    dataInputProcessing: InputProcessorData = field(default_factory=InputProcessorData)
    dataLoopNodes: LoopNodesData = field(default_factory=LoopNodesData)
    dataHVACGlobal: HVACGlobalsData = field(default_factory=HVACGlobalsData)
    dataEnvrn: EnvironmentData = field(default_factory=EnvironmentData)
    dataGlobal: GlobalData = field(default_factory=GlobalData)


STEFAN_BOLTZMANN = 5.6697e-08

Kelvin = 273.15
Pi = math.pi
rSecsInHour = 1.0 / 3600.0


def pow_2(x: float) -> float:
    return x * x


def pow_3(x: float) -> float:
    return x * x * x


def pow_4(x: float) -> float:
    return x * x * x * x


@dataclass
class PondGroundHeatExchangerData(PlantComponent):
    Name: str = ""
    InletNode: str = ""
    OutletNode: str = ""
    DesignMassFlowRate: float = 0.0
    DesignCapacity: float = 0.0
    Depth: float = 0.0
    Area: float = 0.0
    TubeInDiameter: float = 0.0
    TubeOutDiameter: float = 0.0
    TubeConductivity: float = 0.0
    GrndConductivity: float = 0.0
    CircuitLength: float = 0.0
    BulkTemperature: float = 0.0
    PastBulkTemperature: float = 0.0
    NumCircuits: int = 0
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    FrozenErrIndex: int = 0
    ConsecutiveFrozen: int = 0
    plantLoc: PlantLocation = field(default_factory=lambda: PlantLocation(PlantLoop(GlycolProps())))
    
    InletTemp: float = 0.0
    OutletTemp: float = 0.0
    MassFlowRate: float = 0.0
    PondTemp: float = 0.0
    HeatTransferRate: float = 0.0
    Energy: float = 0.0
    
    OneTimeFlag: bool = True
    MyFlag: bool = True
    setupOutputVarsFlag: bool = True
    
    water: Optional[GlycolProps] = None
    firstTimeThrough: bool = True
    
    def simulate(self, state: EnergyPlusData, calledFromLocation: PlantLocation,
                 FirstHVACIteration: bool, CurLoad: List[float], RunFlag: bool) -> None:
        self.InitPondGroundHeatExchanger(state, FirstHVACIteration)
        self.CalcPondGroundHeatExchanger(state)
        self.UpdatePondGroundHeatExchanger(state)
    
    @staticmethod
    def factory(state: EnergyPlusData, objectName: str) -> 'PondGroundHeatExchangerData':
        if state.dataPondGHE.GetInputFlag:
            GetPondGroundHeatExchanger(state)
            state.dataPondGHE.GetInputFlag = False
        for ghx in state.dataPondGHE.PondGHE:
            if ghx.Name == objectName:
                return ghx
        ShowFatalError(state, f"Pond Heat Exchanger Factory: Error getting inputs for GHX named: {objectName}")
        return None
    
    def onInitLoopEquip(self, state: EnergyPlusData, calledFromLocation: PlantLocation) -> None:
        self.InitPondGroundHeatExchanger(state, True)
    
    def getDesignCapacities(self, state: EnergyPlusData, calledFromLocation: PlantLocation,
                           MaxLoad: List[float], MinLoad: List[float], OptLoad: List[float]) -> None:
        MaxLoad[0] = self.DesignCapacity
        MinLoad[0] = 0.0
        OptLoad[0] = self.DesignCapacity
    
    def InitPondGroundHeatExchanger(self, state: EnergyPlusData, FirstHVACIteration: bool) -> None:
        self.oneTimeInit(state)
        
        if FirstHVACIteration and not state.dataHVACGlobal.ShortenTimeStepSys and self.firstTimeThrough:
            self.PastBulkTemperature = self.BulkTemperature
            self.firstTimeThrough = False
        elif not FirstHVACIteration:
            self.firstTimeThrough = True
        
        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum].Temp
        self.PondTemp = self.BulkTemperature
        
        DesignFlow = RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.DesignMassFlowRate)
        
        SetComponentFlowRate(state, DesignFlow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
        
        self.MassFlowRate = state.dataLoopNodes.Node[self.InletNodeNum].MassFlowRate
    
    def setupOutputVars(self, state: EnergyPlusData) -> None:
        SetupOutputVariable(state, "Pond Heat Exchanger Heat Transfer Rate", "W",
                          self.HeatTransferRate, self.Name)
        SetupOutputVariable(state, "Pond Heat Exchanger Heat Transfer Energy", "J",
                          self.Energy, self.Name)
        SetupOutputVariable(state, "Pond Heat Exchanger Mass Flow Rate", "kg/s",
                          self.MassFlowRate, self.Name)
        SetupOutputVariable(state, "Pond Heat Exchanger Inlet Temperature", "C",
                          self.InletTemp, self.Name)
        SetupOutputVariable(state, "Pond Heat Exchanger Outlet Temperature", "C",
                          self.OutletTemp, self.Name)
        SetupOutputVariable(state, "Pond Heat Exchanger Bulk Temperature", "C",
                          self.PondTemp, self.Name)
    
    def CalcPondGroundHeatExchanger(self, state: EnergyPlusData) -> None:
        RoutineName = "CalcPondGroundHeatExchanger"
        
        PondMass = self.Depth * self.Area * self.water.getDensity(state, max(self.PondTemp, 0.0), RoutineName)
        SpecificHeat = self.water.getSpecificHeat(state, max(self.PondTemp, 0.0), RoutineName)
        
        Flux = self.CalcTotalFLux(state, self.PondTemp)
        PondTempStar = self.PastBulkTemperature + 0.5 * rSecsInHour * state.dataHVACGlobal.TimeStepSys * Flux / (SpecificHeat * PondMass)
        
        FluxStar = self.CalcTotalFLux(state, PondTempStar)
        PondTempStarStar = self.PastBulkTemperature + 0.5 * rSecsInHour * state.dataHVACGlobal.TimeStepSys * FluxStar / (SpecificHeat * PondMass)
        
        FluxStarStar = self.CalcTotalFLux(state, PondTempStarStar)
        PondTempStarStarStar = self.PastBulkTemperature + rSecsInHour * state.dataHVACGlobal.TimeStepSys * FluxStarStar / (SpecificHeat * PondMass)
        
        self.PondTemp = self.PastBulkTemperature + rSecsInHour * state.dataHVACGlobal.TimeStepSys * \
                        (Flux + 2.0 * FluxStar + 2.0 * FluxStarStar + self.CalcTotalFLux(state, PondTempStarStarStar)) / \
                        (6.0 * SpecificHeat * PondMass)
    
    def CalcTotalFLux(self, state: EnergyPlusData, PondBulkTemp: float) -> float:
        PrandtlAir = 0.71
        SchmidtAir = 0.6
        PondHeight = 0.0
        RoutineName = "PondGroundHeatExchanger:CalcTotalFlux"
        
        ThermalAbs = 0.9
        
        OutDryBulb = OutDryBulbTempAt(state, PondHeight)
        OutWetBulb = OutWetBulbTempAt(state, PondHeight)
        
        if state.dataEnvrn.IsSnow or state.dataEnvrn.IsRain:
            ExternalTemp = OutWetBulb
        else:
            ExternalTemp = OutDryBulb
        
        SurfTempAbs = PondBulkTemp + Kelvin
        SkyTempAbs = state.dataEnvrn.SkyTemp + Kelvin
        
        ConvCoef = CalcASHRAESimpExtConvCoeff(WindSpeedAt(state, PondHeight))
        
        FluxConvect = ConvCoef * (PondBulkTemp - ExternalTemp)
        
        FluxLongwave = STEFAN_BOLTZMANN * ThermalAbs * (pow_4(SurfTempAbs) - pow_4(SkyTempAbs))
        
        FluxSolAbsorbed = self.CalcSolarFlux(state)
        
        SpecHeat = self.plantLoc.loop.glycol.getSpecificHeat(state, max(self.InletTemp, 0.0), RoutineName)
        
        effectiveness = self.CalcEffectiveness(state, self.InletTemp, PondBulkTemp, self.MassFlowRate)
        Qfluid = self.MassFlowRate * SpecHeat * effectiveness * (self.InletTemp - PondBulkTemp)
        
        HumRatioAir = PsyWFnTdbTwbPb(state, OutDryBulb, OutWetBulb, state.dataEnvrn.OutBaroPress)
        
        HumRatioFilm = PsyWFnTdbTwbPb(state, PondBulkTemp, PondBulkTemp, state.dataEnvrn.OutBaroPress)
        SpecHeatAir = PsyCpAirFnW(HumRatioAir)
        LatentHeatAir = PsyHfgAirFnWTdb(HumRatioAir, OutDryBulb)
        
        FluxEvap = pow_2(PrandtlAir / SchmidtAir) / 3.0 * ConvCoef / SpecHeatAir * (HumRatioFilm - HumRatioAir) * LatentHeatAir
        
        Perimeter = 4.0 * math.sqrt(self.Area)
        
        UvalueGround = 0.999 * (self.GrndConductivity / self.Depth) + 1.37 * (self.GrndConductivity * Perimeter / self.Area)
        
        FluxGround = UvalueGround * (PondBulkTemp - state.dataEnvrn.GroundTemp[1])
        
        CalcTotalFLux_val = Qfluid + self.Area * (FluxSolAbsorbed - FluxConvect - FluxLongwave - FluxEvap - FluxGround)
        
        return CalcTotalFLux_val
    
    def CalcSolarFlux(self, state: EnergyPlusData) -> float:
        WaterRefIndex = 1.33
        AirRefIndex = 1.0003
        PondExtCoef = 0.3
        
        if not state.dataEnvrn.SunIsUp:
            return 0.0
        
        IncidAngle = math.acos(state.dataEnvrn.SOLCOS[2])
        RefractAngle = math.asin(math.sin(IncidAngle) * AirRefIndex / WaterRefIndex)
        
        Absorbtance = math.exp(-PondExtCoef * self.Depth / math.cos(RefractAngle))
        
        ParallelRad = pow_2(math.tan(RefractAngle - IncidAngle)) / pow_2(math.tan(RefractAngle + IncidAngle))
        PerpendRad = pow_2(math.sin(RefractAngle - IncidAngle)) / pow_2(math.sin(RefractAngle + IncidAngle))
        
        Transmitance = 0.5 * Absorbtance * ((1.0 - ParallelRad) / (1.0 + ParallelRad) + (1.0 - PerpendRad) / (1.0 + PerpendRad))
        
        Reflectance = Absorbtance - Transmitance
        
        CalcSolarFlux_val = (1.0 - Reflectance) * (state.dataEnvrn.SOLCOS[2] * state.dataEnvrn.BeamSolarRad + state.dataEnvrn.DifSolarRad)
        
        return CalcSolarFlux_val
    
    def CalcEffectiveness(self, state: EnergyPlusData, InsideTemperature: float,
                         PondTemperature: float, massFlowRate: float) -> float:
        MaxLaminarRe = 2300.0
        GravConst = 9.81
        CalledFrom = "PondGroundHeatExchanger:CalcEffectiveness"
        
        SpecificHeat = self.plantLoc.loop.glycol.getSpecificHeat(state, InsideTemperature, CalledFrom)
        Conductivity = self.plantLoc.loop.glycol.getConductivity(state, InsideTemperature, CalledFrom)
        Viscosity = self.plantLoc.loop.glycol.getViscosity(state, InsideTemperature, CalledFrom)
        
        ReynoldsNum = 4.0 * massFlowRate / (Pi * Viscosity * self.TubeInDiameter * self.NumCircuits)
        
        PrantlNum = Viscosity * SpecificHeat / Conductivity
        
        if ReynoldsNum >= MaxLaminarRe:
            NusseltNum = 0.023 * math.pow(ReynoldsNum, 0.8) * math.pow(PrantlNum, 0.3)
        else:
            NusseltNum = 3.66
        
        ConvCoefIn = Conductivity * NusseltNum / self.TubeInDiameter
        
        WaterSpecHeat = self.water.getSpecificHeat(state, max(PondTemperature, 0.0), CalledFrom)
        WaterConductivity = self.water.getConductivity(state, max(PondTemperature, 0.0), CalledFrom)
        WaterViscosity = self.water.getViscosity(state, max(PondTemperature, 0.0), CalledFrom)
        WaterDensity = self.water.getDensity(state, max(PondTemperature, 0.0), CalledFrom)
        
        ExpansionCoef = -(self.water.getDensity(state, max(PondTemperature, 10.0) + 5.0, CalledFrom) -
                         self.water.getDensity(state, max(PondTemperature, 10.0) - 5.0, CalledFrom)) / \
                       (10.0 * WaterDensity)
        
        ThermDiff = WaterConductivity / (WaterDensity * WaterSpecHeat)
        PrantlNum = WaterViscosity * WaterSpecHeat / WaterConductivity
        
        RayleighNum = WaterDensity * GravConst * ExpansionCoef * abs(InsideTemperature - PondTemperature) * pow_3(self.TubeOutDiameter) / \
                     (WaterViscosity * ThermDiff)
        
        NusseltNum = pow_2(0.6 + (0.387 * math.pow(RayleighNum, 1.0 / 6.0) / \
                           math.pow(1.0 + 0.559 / math.pow(PrantlNum, 9.0 / 16.0), 8.0 / 27.0)))
        
        ConvCoefOut = WaterConductivity * NusseltNum / self.TubeOutDiameter
        
        PipeResistance = self.TubeInDiameter / self.TubeConductivity * math.log(self.TubeOutDiameter / self.TubeInDiameter)
        
        TotalResistance = PipeResistance + 1.0 / ConvCoefIn + self.TubeInDiameter / (self.TubeOutDiameter * ConvCoefOut)
        
        if massFlowRate == 0.0:
            CalcEffectiveness_val = 1.0
        else:
            NTU = Pi * self.TubeInDiameter * self.CircuitLength * self.NumCircuits / (TotalResistance * massFlowRate * SpecificHeat)
            CalcEffectiveness_val = 1.0 - math.exp(-NTU)
        
        if PondTemperature < 0.0:
            self.ConsecutiveFrozen += 1
            if self.FrozenErrIndex == 0:
                ShowWarningMessage(state,
                                 f"GroundHeatExchanger:Pond=\"{self.Name}\", is frozen; Pond model not valid. Calculated Pond Temperature=[{PondTemperature:.2f}] C")
                ShowContinueErrorTimeStamp(state, "")
            ShowRecurringWarningErrorAtEnd(state,
                                         f"GroundHeatExchanger:Pond=\"{self.Name}\", is frozen",
                                         self.FrozenErrIndex,
                                         PondTemperature,
                                         PondTemperature,
                                         "[C]",
                                         "[C]")
            if self.ConsecutiveFrozen >= state.dataGlobal.TimeStepsInHour * 30:
                ShowFatalError(state,
                             f"GroundHeatExchanger:Pond=\"{self.Name}\" has been frozen for 30 consecutive hours.  Program terminates.")
        else:
            self.ConsecutiveFrozen = 0
        
        return CalcEffectiveness_val
    
    def UpdatePondGroundHeatExchanger(self, state: EnergyPlusData) -> None:
        RoutineName = "PondGroundHeatExchanger:Update"
        
        CpFluid = self.plantLoc.loop.glycol.getSpecificHeat(state, self.InletTemp, RoutineName)
        
        SafeCopyPlantNode(state, self.InletNodeNum, self.OutletNodeNum)
        
        if (CpFluid > 0.0) and (self.MassFlowRate > 0.0):
            self.OutletTemp = self.InletTemp - self.HeatTransferRate / (self.MassFlowRate * CpFluid)
        else:
            self.OutletTemp = self.InletTemp
        
        state.dataLoopNodes.Node[self.OutletNodeNum].Temp = self.OutletTemp
        state.dataLoopNodes.Node[self.OutletNodeNum].MassFlowRate = self.MassFlowRate
        
        effectiveness = self.CalcEffectiveness(state, self.InletTemp, self.PondTemp, self.MassFlowRate)
        self.HeatTransferRate = self.MassFlowRate * CpFluid * effectiveness * (self.InletTemp - self.PondTemp)
        self.Energy = self.HeatTransferRate * state.dataHVACGlobal.TimeStepSysSec
        
        self.BulkTemperature = self.PondTemp
    
    def oneTimeInit(self, state: EnergyPlusData) -> None:
        DesignVelocity = 0.5
        PondHeight = 0.0
        RoutineName = "InitPondGroundHeatExchanger"
        
        if self.setupOutputVarsFlag:
            self.setupOutputVars(state)
            self.setupOutputVarsFlag = False
        
        if self.OneTimeFlag or state.dataGlobal.WarmupFlag:
            self.BulkTemperature = self.PastBulkTemperature = \
                0.5 * (OutDryBulbTempAt(state, PondHeight) + state.dataEnvrn.GroundTemp[1])
            self.OneTimeFlag = False
        
        if self.MyFlag:
            errFlag = ScanPlantLoopsForObject(state, self.Name, self.plantLoc)
            if errFlag:
                ShowFatalError(state, "InitPondGroundHeatExchanger: Program terminated due to previous condition(s).")
            rho = self.plantLoc.loop.glycol.getDensity(state, 0.0, RoutineName)
            Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, 0.0, RoutineName)
            self.DesignMassFlowRate = Pi / 4.0 * pow_2(self.TubeInDiameter) * DesignVelocity * rho * self.NumCircuits
            self.DesignCapacity = self.DesignMassFlowRate * Cp * 10.0
            InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
            RegisterPlantCompDesignFlow(state, self.InletNodeNum, self.DesignMassFlowRate / rho)
            
            self.MyFlag = False


def GetPondGroundHeatExchanger(state: EnergyPlusData) -> None:
    ErrorsFound = False
    
    state.dataIPShortCut.cCurrentModuleObject = "GroundHeatExchanger:Pond"
    state.dataPondGHE.NumOfPondGHEs = GetNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    
    if state.dataPondGHE.PondGHE:
        state.dataPondGHE.PondGHE = []
    
    state.dataPondGHE.PondGHE = [PondGroundHeatExchangerData() for _ in range(state.dataPondGHE.NumOfPondGHEs)]
    
    for Item in range(state.dataPondGHE.NumOfPondGHEs):
        GetObjectItem(state,
                     state.dataIPShortCut.cCurrentModuleObject,
                     Item + 1,
                     state.dataIPShortCut.cAlphaArgs,
                     state.dataIPShortCut.rNumericArgs,
                     state.dataIPShortCut.cAlphaFieldNames,
                     state.dataIPShortCut.cNumericFieldNames)
        
        state.dataPondGHE.PondGHE[Item].water = GetWater(state)
        if state.dataPondGHE.PondGHE[Item].water is None:
            ShowSevereError(state, "Fluid Properties for WATER not found")
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].Name = state.dataIPShortCut.cAlphaArgs[0]
        
        state.dataPondGHE.PondGHE[Item].InletNode = state.dataIPShortCut.cAlphaArgs[1]
        state.dataPondGHE.PondGHE[Item].InletNodeNum = GetOnlySingleNode(state,
                                                                          state.dataIPShortCut.cAlphaArgs[1],
                                                                          state.dataIPShortCut.cAlphaArgs[0])
        if state.dataPondGHE.PondGHE[Item].InletNodeNum == 0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cAlphaFieldNames[1]}={state.dataIPShortCut.cAlphaArgs[1]}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].OutletNode = state.dataIPShortCut.cAlphaArgs[2]
        state.dataPondGHE.PondGHE[Item].OutletNodeNum = GetOnlySingleNode(state,
                                                                           state.dataIPShortCut.cAlphaArgs[2],
                                                                           state.dataIPShortCut.cAlphaArgs[0])
        if state.dataPondGHE.PondGHE[Item].OutletNodeNum == 0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cAlphaFieldNames[2]}={state.dataIPShortCut.cAlphaArgs[2]}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ErrorsFound = True
        
        TestCompSet(state,
                   state.dataIPShortCut.cCurrentModuleObject,
                   state.dataIPShortCut.cAlphaArgs[0],
                   state.dataIPShortCut.cAlphaArgs[1],
                   state.dataIPShortCut.cAlphaArgs[2])
        
        state.dataPondGHE.PondGHE[Item].Depth = state.dataIPShortCut.rNumericArgs[0]
        state.dataPondGHE.PondGHE[Item].Area = state.dataIPShortCut.rNumericArgs[1]
        if state.dataIPShortCut.rNumericArgs[0] <= 0.0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[0]}={state.dataIPShortCut.rNumericArgs[0]:.2f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[1] <= 0.0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[1]}={state.dataIPShortCut.rNumericArgs[1]:.2f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].TubeInDiameter = state.dataIPShortCut.rNumericArgs[2]
        state.dataPondGHE.PondGHE[Item].TubeOutDiameter = state.dataIPShortCut.rNumericArgs[3]
        
        if state.dataIPShortCut.rNumericArgs[2] <= 0.0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[2]}={state.dataIPShortCut.rNumericArgs[2]:.2f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[3] <= 0.0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[3]}={state.dataIPShortCut.rNumericArgs[3]:.2f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[2] > state.dataIPShortCut.rNumericArgs[3]:
            ShowSevereError(state, f"For {state.dataIPShortCut.cCurrentModuleObject}: {state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, f"{state.dataIPShortCut.cNumericFieldNames[2]} [{state.dataIPShortCut.rNumericArgs[2]:.2f}] > " +
                            f"{state.dataIPShortCut.cNumericFieldNames[3]} [{state.dataIPShortCut.rNumericArgs[3]:.2f}]")
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].TubeConductivity = state.dataIPShortCut.rNumericArgs[4]
        state.dataPondGHE.PondGHE[Item].GrndConductivity = state.dataIPShortCut.rNumericArgs[5]
        
        if state.dataIPShortCut.rNumericArgs[4] <= 0.0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[4]}={state.dataIPShortCut.rNumericArgs[4]:.4f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[5] <= 0.0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[5]}={state.dataIPShortCut.rNumericArgs[5]:.4f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].NumCircuits = int(state.dataIPShortCut.rNumericArgs[6])
        
        if state.dataIPShortCut.rNumericArgs[6] <= 0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[6]}={state.dataIPShortCut.rNumericArgs[6]:.2f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item].CircuitLength = state.dataIPShortCut.rNumericArgs[7]
        if state.dataIPShortCut.rNumericArgs[7] <= 0:
            ShowSevereError(state, f"Invalid {state.dataIPShortCut.cNumericFieldNames[7]}={state.dataIPShortCut.rNumericArgs[7]:.2f}")
            ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={state.dataIPShortCut.cAlphaArgs[0]}")
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
    
    if ErrorsFound:
        ShowFatalError(state, f"Errors found in processing input for {state.dataIPShortCut.cCurrentModuleObject}")
    
    if not state.dataEnvrn.GroundTempInputs[1]:
        ShowWarningError(state, "GetPondGroundHeatExchanger:  No \"Site:GroundTemperature:Deep\" were input.")
        ShowContinueError(state, f"Defaults, constant throughout the year of ({state.dataEnvrn.GroundTemp[1]:.1f}) will be used.")


def SetupOutputVariable(state: EnergyPlusData, name: str, units: str, var: Any, ghx_name: str) -> None:
    pass


def RegulateCondenserCompFlowReqOp(state: EnergyPlusData, plantLoc: PlantLocation, DesignMassFlowRate: float) -> float:
    return DesignMassFlowRate


def SetComponentFlowRate(state: EnergyPlusData, FlowRate: float, InletNode: int, OutletNode: int, plantLoc: PlantLocation) -> None:
    pass


def SafeCopyPlantNode(state: EnergyPlusData, InletNodeNum: int, OutletNodeNum: int) -> None:
    pass


def ScanPlantLoopsForObject(state: EnergyPlusData, name: str, plantLoc: PlantLocation) -> bool:
    return False


def InitComponentNodes(state: EnergyPlusData, MinFlow: float, MaxFlow: float, InletNode: int, OutletNode: int) -> None:
    pass


def RegisterPlantCompDesignFlow(state: EnergyPlusData, NodeNum: int, FlowRate: float) -> None:
    pass


def GetWater(state: EnergyPlusData) -> Optional[GlycolProps]:
    return None


def GetOnlySingleNode(state: EnergyPlusData, node_name: str, component_name: str) -> int:
    return 0


def TestCompSet(state: EnergyPlusData, obj_type: str, obj_name: str, inlet: str, outlet: str) -> None:
    pass


def GetObjectItem(state: EnergyPlusData, obj_type: str, item_num: int, alphas: List[str], numerics: List[float],
                 alpha_names: List[str], numeric_names: List[str]) -> None:
    pass


def GetNumObjectsFound(state: EnergyPlusData, obj_type: str) -> int:
    return 0


def OutDryBulbTempAt(state: EnergyPlusData, height: float) -> float:
    return state.dataEnvrn.OutBaroPress


def OutWetBulbTempAt(state: EnergyPlusData, height: float) -> float:
    return state.dataEnvrn.SkyTemp


def WindSpeedAt(state: EnergyPlusData, height: float) -> float:
    return 0.0


def CalcASHRAESimpExtConvCoeff(wind_speed: float) -> float:
    return 5.0


def PsyWFnTdbTwbPb(state: EnergyPlusData, tdb: float, twb: float, pb: float) -> float:
    return 0.0


def PsyCpAirFnW(hum_ratio: float) -> float:
    return 1005.0


def PsyHfgAirFnWTdb(hum_ratio: float, tdb: float) -> float:
    return 2500000.0


def ShowFatalError(state: EnergyPlusData, msg: str) -> None:
    raise RuntimeError(msg)


def ShowSevereError(state: EnergyPlusData, msg: str) -> None:
    print(f"SEVERE: {msg}")


def ShowContinueError(state: EnergyPlusData, msg: str) -> None:
    print(f"  CONTINUE: {msg}")


def ShowWarningError(state: EnergyPlusData, msg: str) -> None:
    print(f"WARNING: {msg}")


def ShowWarningMessage(state: EnergyPlusData, msg: str) -> None:
    print(f"WARNING: {msg}")


def ShowContinueErrorTimeStamp(state: EnergyPlusData, msg: str) -> None:
    pass


def ShowRecurringWarningErrorAtEnd(state: EnergyPlusData, msg: str, err_idx: int,
                                  val1: float, val2: float, unit1: str, unit2: str) -> None:
    pass

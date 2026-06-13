# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state container, accessed via state.dataPondGHE, state.dataIPShortCut, 
#   state.dataInputProcessing, state.dataLoopNodes, state.dataHVACGlobal, state.dataEnvrn, state.dataGlobal
# - PlantComponent: base struct with virtual methods (simulate, getDesignCapacities, onInitLoopEquip, oneTimeInit)
# - BaseGlobalStruct: base struct with virtual init_constant_state, init_state, clear_state
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

from math import (
    exp, acos, asin, sin, cos, tan, sqrt, log, pow as math_pow, fabs, pi
)

alias F64 = Float64
alias Kelvin = 273.15
alias Pi = pi
alias rSecsInHour = 1.0 / 3600.0
alias STEFAN_BOLTZMANN = 5.6697e-08

fn pow_2(x: F64) -> F64:
    return x * x

fn pow_3(x: F64) -> F64:
    return x * x * x

fn pow_4(x: F64) -> F64:
    return x * x * x * x

struct GlycolProps:
    fn getDensity(self, state: EnergyPlusData, temperature: F64, routine_name: StringLiteral) -> F64:
        return 0.0
    
    fn getSpecificHeat(self, state: EnergyPlusData, temperature: F64, routine_name: StringLiteral) -> F64:
        return 0.0
    
    fn getConductivity(self, state: EnergyPlusData, temperature: F64, routine_name: StringLiteral) -> F64:
        return 0.0
    
    fn getViscosity(self, state: EnergyPlusData, temperature: F64, routine_name: StringLiteral) -> F64:
        return 0.0

struct PlantLoop:
    var glycol: GlycolProps

struct PlantLocation:
    var loop: PlantLoop

struct LoopNode:
    var Temp: F64
    var MassFlowRate: F64
    
    fn __init__() -> Self:
        return Self(0.0, 0.0)

struct PondGHEData:
    var GetInputFlag: Bool
    var NumOfPondGHEs: Int
    var PondGHE: List[PondGroundHeatExchangerData]
    
    fn __init__() -> Self:
        return Self(True, 0, List[PondGroundHeatExchangerData]())
    
    fn init_constant_state(self, state: EnergyPlusData) -> None:
        pass
    
    fn init_state(self, state: EnergyPlusData) -> None:
        pass
    
    fn clear_state(self) -> None:
        self.GetInputFlag = True
        self.NumOfPondGHEs = 0
        self.PondGHE = List[PondGroundHeatExchangerData]()

struct IPShortCutData:
    var cCurrentModuleObject: String
    var cAlphaArgs: List[String]
    var rNumericArgs: List[F64]
    var cAlphaFieldNames: List[String]
    var cNumericFieldNames: List[String]
    
    fn __init__() -> Self:
        return Self(String(""), List[String](), List[F64](), List[String](), List[String]())

struct InputProcessorData:
    var inputProcessor: AnyType
    
    fn __init__() -> Self:
        return Self(AnyType())

struct LoopNodesData:
    var Node: List[LoopNode]
    
    fn __init__() -> Self:
        return Self(List[LoopNode]())

struct HVACGlobalsData:
    var TimeStepSys: F64
    var TimeStepSysSec: F64
    var ShortenTimeStepSys: Bool
    
    fn __init__() -> Self:
        return Self(0.0, 0.0, False)

struct EnvironmentData:
    var SkyTemp: F64
    var IsSnow: Bool
    var IsRain: Bool
    var SunIsUp: Bool
    var SOLCOS: List[F64]
    var BeamSolarRad: F64
    var DifSolarRad: F64
    var OutBaroPress: F64
    var GroundTemp: List[F64]
    var GroundTempInputs: List[Bool]
    
    fn __init__() -> Self:
        var solcos = List[F64]()
        solcos.append(0.0)
        solcos.append(0.0)
        solcos.append(0.0)
        var ground_temp = List[F64]()
        ground_temp.append(0.0)
        ground_temp.append(0.0)
        var ground_temp_inputs = List[Bool]()
        ground_temp_inputs.append(False)
        ground_temp_inputs.append(False)
        return Self(0.0, False, False, False, solcos, 0.0, 0.0, 0.0, ground_temp, ground_temp_inputs)

struct GlobalData:
    var WarmupFlag: Bool
    var TimeStepsInHour: Int
    
    fn __init__() -> Self:
        return Self(False, 0)

struct EnergyPlusData:
    var dataPondGHE: PondGHEData
    var dataIPShortCut: IPShortCutData
    var dataInputProcessing: InputProcessorData
    var dataLoopNodes: LoopNodesData
    var dataHVACGlobal: HVACGlobalsData
    var dataEnvrn: EnvironmentData
    var dataGlobal: GlobalData
    
    fn __init__() -> Self:
        return Self(PondGHEData(), IPShortCutData(), InputProcessorData(), 
                   LoopNodesData(), HVACGlobalsData(), EnvironmentData(), GlobalData())

struct PondGroundHeatExchangerData:
    var Name: String
    var InletNode: String
    var OutletNode: String
    var DesignMassFlowRate: F64
    var DesignCapacity: F64
    var Depth: F64
    var Area: F64
    var TubeInDiameter: F64
    var TubeOutDiameter: F64
    var TubeConductivity: F64
    var GrndConductivity: F64
    var CircuitLength: F64
    var BulkTemperature: F64
    var PastBulkTemperature: F64
    var NumCircuits: Int
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var FrozenErrIndex: Int
    var ConsecutiveFrozen: Int
    var plantLoc: PlantLocation
    
    var InletTemp: F64
    var OutletTemp: F64
    var MassFlowRate: F64
    var PondTemp: F64
    var HeatTransferRate: F64
    var Energy: F64
    
    var OneTimeFlag: Bool
    var MyFlag: Bool
    var setupOutputVarsFlag: Bool
    
    var water: GlycolProps
    var firstTimeThrough: Bool
    
    fn __init__() -> Self:
        return Self(
            String(""), String(""), String(""),
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0, 0, 0, 0, 0,
            PlantLocation(PlantLoop(GlycolProps())),
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            True, True, True,
            GlycolProps(), True
        )
    
    fn simulate(self, state: EnergyPlusData, calledFromLocation: PlantLocation,
               FirstHVACIteration: Bool, CurLoad: List[F64], RunFlag: Bool) -> None:
        self.InitPondGroundHeatExchanger(state, FirstHVACIteration)
        self.CalcPondGroundHeatExchanger(state)
        self.UpdatePondGroundHeatExchanger(state)
    
    fn onInitLoopEquip(self, state: EnergyPlusData, calledFromLocation: PlantLocation) -> None:
        self.InitPondGroundHeatExchanger(state, True)
    
    fn getDesignCapacities(self, state: EnergyPlusData, calledFromLocation: PlantLocation,
                          MaxLoad: List[F64], MinLoad: List[F64], OptLoad: List[F64]) -> None:
        MaxLoad[0] = self.DesignCapacity
        MinLoad[0] = 0.0
        OptLoad[0] = self.DesignCapacity
    
    fn InitPondGroundHeatExchanger(self, state: EnergyPlusData, FirstHVACIteration: Bool) -> None:
        self.oneTimeInit(state)
        
        if FirstHVACIteration and not state.dataHVACGlobal.ShortenTimeStepSys and self.firstTimeThrough:
            self.PastBulkTemperature = self.BulkTemperature
            self.firstTimeThrough = False
        elif not FirstHVACIteration:
            self.firstTimeThrough = True
        
        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum].Temp
        self.PondTemp = self.BulkTemperature
        
        var DesignFlow = RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.DesignMassFlowRate)
        
        SetComponentFlowRate(state, DesignFlow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
        
        self.MassFlowRate = state.dataLoopNodes.Node[self.InletNodeNum].MassFlowRate
    
    fn setupOutputVars(self, state: EnergyPlusData) -> None:
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
    
    fn CalcPondGroundHeatExchanger(self, state: EnergyPlusData) -> None:
        var RoutineName = "CalcPondGroundHeatExchanger"
        
        var PondMass = self.Depth * self.Area * self.water.getDensity(state, max(self.PondTemp, 0.0), RoutineName)
        var SpecificHeat = self.water.getSpecificHeat(state, max(self.PondTemp, 0.0), RoutineName)
        
        var Flux = self.CalcTotalFLux(state, self.PondTemp)
        var PondTempStar = self.PastBulkTemperature + 0.5 * rSecsInHour * state.dataHVACGlobal.TimeStepSys * Flux / (SpecificHeat * PondMass)
        
        var FluxStar = self.CalcTotalFLux(state, PondTempStar)
        var PondTempStarStar = self.PastBulkTemperature + 0.5 * rSecsInHour * state.dataHVACGlobal.TimeStepSys * FluxStar / (SpecificHeat * PondMass)
        
        var FluxStarStar = self.CalcTotalFLux(state, PondTempStarStar)
        var PondTempStarStarStar = self.PastBulkTemperature + rSecsInHour * state.dataHVACGlobal.TimeStepSys * FluxStarStar / (SpecificHeat * PondMass)
        
        self.PondTemp = self.PastBulkTemperature + rSecsInHour * state.dataHVACGlobal.TimeStepSys * \
                        (Flux + 2.0 * FluxStar + 2.0 * FluxStarStar + self.CalcTotalFLux(state, PondTempStarStarStar)) / \
                        (6.0 * SpecificHeat * PondMass)
    
    fn CalcTotalFLux(self, state: EnergyPlusData, PondBulkTemp: F64) -> F64:
        var PrandtlAir = 0.71
        var SchmidtAir = 0.6
        var PondHeight = 0.0
        var RoutineName = "PondGroundHeatExchanger:CalcTotalFlux"
        
        var ThermalAbs = 0.9
        
        var OutDryBulb = OutDryBulbTempAt(state, PondHeight)
        var OutWetBulb = OutWetBulbTempAt(state, PondHeight)
        
        var ExternalTemp: F64
        if state.dataEnvrn.IsSnow or state.dataEnvrn.IsRain:
            ExternalTemp = OutWetBulb
        else:
            ExternalTemp = OutDryBulb
        
        var SurfTempAbs = PondBulkTemp + Kelvin
        var SkyTempAbs = state.dataEnvrn.SkyTemp + Kelvin
        
        var ConvCoef = CalcASHRAESimpExtConvCoeff(WindSpeedAt(state, PondHeight))
        
        var FluxConvect = ConvCoef * (PondBulkTemp - ExternalTemp)
        
        var FluxLongwave = STEFAN_BOLTZMANN * ThermalAbs * (pow_4(SurfTempAbs) - pow_4(SkyTempAbs))
        
        var FluxSolAbsorbed = self.CalcSolarFlux(state)
        
        var SpecHeat = self.plantLoc.loop.glycol.getSpecificHeat(state, max(self.InletTemp, 0.0), RoutineName)
        
        var effectiveness = self.CalcEffectiveness(state, self.InletTemp, PondBulkTemp, self.MassFlowRate)
        var Qfluid = self.MassFlowRate * SpecHeat * effectiveness * (self.InletTemp - PondBulkTemp)
        
        var HumRatioAir = PsyWFnTdbTwbPb(state, OutDryBulb, OutWetBulb, state.dataEnvrn.OutBaroPress)
        
        var HumRatioFilm = PsyWFnTdbTwbPb(state, PondBulkTemp, PondBulkTemp, state.dataEnvrn.OutBaroPress)
        var SpecHeatAir = PsyCpAirFnW(HumRatioAir)
        var LatentHeatAir = PsyHfgAirFnWTdb(HumRatioAir, OutDryBulb)
        
        var FluxEvap = pow_2(PrandtlAir / SchmidtAir) / 3.0 * ConvCoef / SpecHeatAir * (HumRatioFilm - HumRatioAir) * LatentHeatAir
        
        var Perimeter = 4.0 * sqrt(self.Area)
        
        var UvalueGround = 0.999 * (self.GrndConductivity / self.Depth) + 1.37 * (self.GrndConductivity * Perimeter / self.Area)
        
        var FluxGround = UvalueGround * (PondBulkTemp - state.dataEnvrn.GroundTemp[1])
        
        var result = Qfluid + self.Area * (FluxSolAbsorbed - FluxConvect - FluxLongwave - FluxEvap - FluxGround)
        
        return result
    
    fn CalcSolarFlux(self, state: EnergyPlusData) -> F64:
        var WaterRefIndex = 1.33
        var AirRefIndex = 1.0003
        var PondExtCoef = 0.3
        
        if not state.dataEnvrn.SunIsUp:
            return 0.0
        
        var IncidAngle = acos(state.dataEnvrn.SOLCOS[2])
        var RefractAngle = asin(sin(IncidAngle) * AirRefIndex / WaterRefIndex)
        
        var Absorbtance = exp(-PondExtCoef * self.Depth / cos(RefractAngle))
        
        var ParallelRad = pow_2(tan(RefractAngle - IncidAngle)) / pow_2(tan(RefractAngle + IncidAngle))
        var PerpendRad = pow_2(sin(RefractAngle - IncidAngle)) / pow_2(sin(RefractAngle + IncidAngle))
        
        var Transmitance = 0.5 * Absorbtance * ((1.0 - ParallelRad) / (1.0 + ParallelRad) + (1.0 - PerpendRad) / (1.0 + PerpendRad))
        
        var Reflectance = Absorbtance - Transmitance
        
        var result = (1.0 - Reflectance) * (state.dataEnvrn.SOLCOS[2] * state.dataEnvrn.BeamSolarRad + state.dataEnvrn.DifSolarRad)
        
        return result
    
    fn CalcEffectiveness(self, state: EnergyPlusData, InsideTemperature: F64,
                        PondTemperature: F64, massFlowRate: F64) -> F64:
        var MaxLaminarRe = 2300.0
        var GravConst = 9.81
        var CalledFrom = "PondGroundHeatExchanger:CalcEffectiveness"
        
        var SpecificHeat = self.plantLoc.loop.glycol.getSpecificHeat(state, InsideTemperature, CalledFrom)
        var Conductivity = self.plantLoc.loop.glycol.getConductivity(state, InsideTemperature, CalledFrom)
        var Viscosity = self.plantLoc.loop.glycol.getViscosity(state, InsideTemperature, CalledFrom)
        
        var ReynoldsNum = 4.0 * massFlowRate / (Pi * Viscosity * self.TubeInDiameter * self.NumCircuits)
        
        var PrantlNum = Viscosity * SpecificHeat / Conductivity
        
        var NusseltNum: F64
        if ReynoldsNum >= MaxLaminarRe:
            NusseltNum = 0.023 * math_pow(ReynoldsNum, 0.8) * math_pow(PrantlNum, 0.3)
        else:
            NusseltNum = 3.66
        
        var ConvCoefIn = Conductivity * NusseltNum / self.TubeInDiameter
        
        var WaterSpecHeat = self.water.getSpecificHeat(state, max(PondTemperature, 0.0), CalledFrom)
        var WaterConductivity = self.water.getConductivity(state, max(PondTemperature, 0.0), CalledFrom)
        var WaterViscosity = self.water.getViscosity(state, max(PondTemperature, 0.0), CalledFrom)
        var WaterDensity = self.water.getDensity(state, max(PondTemperature, 0.0), CalledFrom)
        
        var ExpansionCoef = -(self.water.getDensity(state, max(PondTemperature, 10.0) + 5.0, CalledFrom) -
                             self.water.getDensity(state, max(PondTemperature, 10.0) - 5.0, CalledFrom)) / \
                           (10.0 * WaterDensity)
        
        var ThermDiff = WaterConductivity / (WaterDensity * WaterSpecHeat)
        PrantlNum = WaterViscosity * WaterSpecHeat / WaterConductivity
        
        var RayleighNum = WaterDensity * GravConst * ExpansionCoef * fabs(InsideTemperature - PondTemperature) * pow_3(self.TubeOutDiameter) / \
                         (WaterViscosity * ThermDiff)
        
        NusseltNum = pow_2(0.6 + (0.387 * math_pow(RayleighNum, 1.0 / 6.0) / \
                           math_pow(1.0 + 0.559 / math_pow(PrantlNum, 9.0 / 16.0), 8.0 / 27.0)))
        
        var ConvCoefOut = WaterConductivity * NusseltNum / self.TubeOutDiameter
        
        var PipeResistance = self.TubeInDiameter / self.TubeConductivity * log(self.TubeOutDiameter / self.TubeInDiameter)
        
        var TotalResistance = PipeResistance + 1.0 / ConvCoefIn + self.TubeInDiameter / (self.TubeOutDiameter * ConvCoefOut)
        
        var result: F64
        if massFlowRate == 0.0:
            result = 1.0
        else:
            var NTU = Pi * self.TubeInDiameter * self.CircuitLength * self.NumCircuits / (TotalResistance * massFlowRate * SpecificHeat)
            result = 1.0 - exp(-NTU)
        
        if PondTemperature < 0.0:
            self.ConsecutiveFrozen = self.ConsecutiveFrozen + 1
            if self.FrozenErrIndex == 0:
                ShowWarningMessage(state,
                                 String("GroundHeatExchanger:Pond=\"") + self.Name + String("\", is frozen; Pond model not valid. Calculated Pond Temperature=[") + String(PondTemperature) + String("] C"))
                ShowContinueErrorTimeStamp(state, String(""))
            ShowRecurringWarningErrorAtEnd(state,
                                         String("GroundHeatExchanger:Pond=\"") + self.Name + String("\", is frozen"),
                                         self.FrozenErrIndex,
                                         PondTemperature,
                                         PondTemperature,
                                         String("[C]"),
                                         String("[C]"))
            if self.ConsecutiveFrozen >= state.dataGlobal.TimeStepsInHour * 30:
                ShowFatalError(state,
                             String("GroundHeatExchanger:Pond=\"") + self.Name + String("\" has been frozen for 30 consecutive hours.  Program terminates."))
        else:
            self.ConsecutiveFrozen = 0
        
        return result
    
    fn UpdatePondGroundHeatExchanger(self, state: EnergyPlusData) -> None:
        var RoutineName = "PondGroundHeatExchanger:Update"
        
        var CpFluid = self.plantLoc.loop.glycol.getSpecificHeat(state, self.InletTemp, RoutineName)
        
        SafeCopyPlantNode(state, self.InletNodeNum, self.OutletNodeNum)
        
        if (CpFluid > 0.0) and (self.MassFlowRate > 0.0):
            self.OutletTemp = self.InletTemp - self.HeatTransferRate / (self.MassFlowRate * CpFluid)
        else:
            self.OutletTemp = self.InletTemp
        
        state.dataLoopNodes.Node[self.OutletNodeNum].Temp = self.OutletTemp
        state.dataLoopNodes.Node[self.OutletNodeNum].MassFlowRate = self.MassFlowRate
        
        var effectiveness = self.CalcEffectiveness(state, self.InletTemp, self.PondTemp, self.MassFlowRate)
        self.HeatTransferRate = self.MassFlowRate * CpFluid * effectiveness * (self.InletTemp - self.PondTemp)
        self.Energy = self.HeatTransferRate * state.dataHVACGlobal.TimeStepSysSec
        
        self.BulkTemperature = self.PondTemp
    
    fn oneTimeInit(self, state: EnergyPlusData) -> None:
        var DesignVelocity = 0.5
        var PondHeight = 0.0
        var RoutineName = "InitPondGroundHeatExchanger"
        
        if self.setupOutputVarsFlag:
            self.setupOutputVars(state)
            self.setupOutputVarsFlag = False
        
        if self.OneTimeFlag or state.dataGlobal.WarmupFlag:
            self.BulkTemperature = self.PastBulkTemperature = \
                0.5 * (OutDryBulbTempAt(state, PondHeight) + state.dataEnvrn.GroundTemp[1])
            self.OneTimeFlag = False
        
        if self.MyFlag:
            var errFlag = ScanPlantLoopsForObject(state, self.Name, self.plantLoc)
            if errFlag:
                ShowFatalError(state, String("InitPondGroundHeatExchanger: Program terminated due to previous condition(s)."))
            var rho = self.plantLoc.loop.glycol.getDensity(state, 0.0, RoutineName)
            var Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, 0.0, RoutineName)
            self.DesignMassFlowRate = Pi / 4.0 * pow_2(self.TubeInDiameter) * DesignVelocity * rho * self.NumCircuits
            self.DesignCapacity = self.DesignMassFlowRate * Cp * 10.0
            InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
            RegisterPlantCompDesignFlow(state, self.InletNodeNum, self.DesignMassFlowRate / rho)
            
            self.MyFlag = False

fn GetPondGroundHeatExchanger(state: EnergyPlusData) -> None:
    var ErrorsFound = False
    
    state.dataIPShortCut.cCurrentModuleObject = String("GroundHeatExchanger:Pond")
    state.dataPondGHE.NumOfPondGHEs = GetNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    
    state.dataPondGHE.PondGHE = List[PondGroundHeatExchangerData]()
    for _ in range(state.dataPondGHE.NumOfPondGHEs):
        state.dataPondGHE.PondGHE.append(PondGroundHeatExchangerData())
    
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
            ShowSevereError(state, String("Fluid Properties for WATER not found"))
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].Name = state.dataIPShortCut.cAlphaArgs[0]
        
        state.dataPondGHE.PondGHE[Item].InletNode = state.dataIPShortCut.cAlphaArgs[1]
        state.dataPondGHE.PondGHE[Item].InletNodeNum = GetOnlySingleNode(state,
                                                                          state.dataIPShortCut.cAlphaArgs[1],
                                                                          state.dataIPShortCut.cAlphaArgs[0])
        if state.dataPondGHE.PondGHE[Item].InletNodeNum == 0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cAlphaFieldNames[1] + String("=") + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].OutletNode = state.dataIPShortCut.cAlphaArgs[2]
        state.dataPondGHE.PondGHE[Item].OutletNodeNum = GetOnlySingleNode(state,
                                                                           state.dataIPShortCut.cAlphaArgs[2],
                                                                           state.dataIPShortCut.cAlphaArgs[0])
        if state.dataPondGHE.PondGHE[Item].OutletNodeNum == 0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cAlphaFieldNames[2] + String("=") + state.dataIPShortCut.cAlphaArgs[2])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ErrorsFound = True
        
        TestCompSet(state,
                   state.dataIPShortCut.cCurrentModuleObject,
                   state.dataIPShortCut.cAlphaArgs[0],
                   state.dataIPShortCut.cAlphaArgs[1],
                   state.dataIPShortCut.cAlphaArgs[2])
        
        state.dataPondGHE.PondGHE[Item].Depth = state.dataIPShortCut.rNumericArgs[0]
        state.dataPondGHE.PondGHE[Item].Area = state.dataIPShortCut.rNumericArgs[1]
        if state.dataIPShortCut.rNumericArgs[0] <= 0.0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[0])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[1] <= 0.0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[1])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].TubeInDiameter = state.dataIPShortCut.rNumericArgs[2]
        state.dataPondGHE.PondGHE[Item].TubeOutDiameter = state.dataIPShortCut.rNumericArgs[3]
        
        if state.dataIPShortCut.rNumericArgs[2] <= 0.0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[2])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[3] <= 0.0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[3])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[2] > state.dataIPShortCut.rNumericArgs[3]:
            ShowSevereError(state, String("For ") + state.dataIPShortCut.cCurrentModuleObject + String(": ") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, state.dataIPShortCut.cNumericFieldNames[2] + String(" > ") +
                            state.dataIPShortCut.cNumericFieldNames[3])
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].TubeConductivity = state.dataIPShortCut.rNumericArgs[4]
        state.dataPondGHE.PondGHE[Item].GrndConductivity = state.dataIPShortCut.rNumericArgs[5]
        
        if state.dataIPShortCut.rNumericArgs[4] <= 0.0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[4])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[5] <= 0.0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[5])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
        
        state.dataPondGHE.PondGHE[Item].NumCircuits = Int(state.dataIPShortCut.rNumericArgs[6])
        
        if state.dataIPShortCut.rNumericArgs[6] <= 0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[6])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item].CircuitLength = state.dataIPShortCut.rNumericArgs[7]
        if state.dataIPShortCut.rNumericArgs[7] <= 0:
            ShowSevereError(state, String("Invalid ") + state.dataIPShortCut.cNumericFieldNames[7])
            ShowContinueError(state, String("Entered in ") + state.dataIPShortCut.cCurrentModuleObject + String("=") + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, String("Value must be greater than 0.0"))
            ErrorsFound = True
    
    if ErrorsFound:
        ShowFatalError(state, String("Errors found in processing input for ") + state.dataIPShortCut.cCurrentModuleObject)
    
    if not state.dataEnvrn.GroundTempInputs[1]:
        ShowWarningError(state, String("GetPondGroundHeatExchanger:  No \"Site:GroundTemperature:Deep\" were input."))
        ShowContinueError(state, String("Defaults, constant throughout the year will be used."))

fn SetupOutputVariable(state: EnergyPlusData, name: String, units: String, var: F64, ghx_name: String) -> None:
    pass

fn RegulateCondenserCompFlowReqOp(state: EnergyPlusData, plantLoc: PlantLocation, DesignMassFlowRate: F64) -> F64:
    return DesignMassFlowRate

fn SetComponentFlowRate(state: EnergyPlusData, FlowRate: F64, InletNode: Int, OutletNode: Int, plantLoc: PlantLocation) -> None:
    pass

fn SafeCopyPlantNode(state: EnergyPlusData, InletNodeNum: Int, OutletNodeNum: Int) -> None:
    pass

fn ScanPlantLoopsForObject(state: EnergyPlusData, name: String, plantLoc: PlantLocation) -> Bool:
    return False

fn InitComponentNodes(state: EnergyPlusData, MinFlow: F64, MaxFlow: F64, InletNode: Int, OutletNode: Int) -> None:
    pass

fn RegisterPlantCompDesignFlow(state: EnergyPlusData, NodeNum: Int, FlowRate: F64) -> None:
    pass

fn GetWater(state: EnergyPlusData) -> GlycolProps:
    return GlycolProps()

fn GetOnlySingleNode(state: EnergyPlusData, node_name: String, component_name: String) -> Int:
    return 0

fn TestCompSet(state: EnergyPlusData, obj_type: String, obj_name: String, inlet: String, outlet: String) -> None:
    pass

fn GetObjectItem(state: EnergyPlusData, obj_type: String, item_num: Int, alphas: List[String], numerics: List[F64],
                alpha_names: List[String], numeric_names: List[String]) -> None:
    pass

fn GetNumObjectsFound(state: EnergyPlusData, obj_type: String) -> Int:
    return 0

fn OutDryBulbTempAt(state: EnergyPlusData, height: F64) -> F64:
    return state.dataEnvrn.OutBaroPress

fn OutWetBulbTempAt(state: EnergyPlusData, height: F64) -> F64:
    return state.dataEnvrn.SkyTemp

fn WindSpeedAt(state: EnergyPlusData, height: F64) -> F64:
    return 0.0

fn CalcASHRAESimpExtConvCoeff(wind_speed: F64) -> F64:
    return 5.0

fn PsyWFnTdbTwbPb(state: EnergyPlusData, tdb: F64, twb: F64, pb: F64) -> F64:
    return 0.0

fn PsyCpAirFnW(hum_ratio: F64) -> F64:
    return 1005.0

fn PsyHfgAirFnWTdb(hum_ratio: F64, tdb: F64) -> F64:
    return 2500000.0

fn ShowFatalError(state: EnergyPlusData, msg: String) -> None:
    pass

fn ShowSevereError(state: EnergyPlusData, msg: String) -> None:
    pass

fn ShowContinueError(state: EnergyPlusData, msg: String) -> None:
    pass

fn ShowWarningError(state: EnergyPlusData, msg: String) -> None:
    pass

fn ShowWarningMessage(state: EnergyPlusData, msg: String) -> None:
    pass

fn ShowContinueErrorTimeStamp(state: EnergyPlusData, msg: String) -> None:
    pass

fn ShowRecurringWarningErrorAtEnd(state: EnergyPlusData, msg: String, err_idx: Int,
                                 val1: F64, val2: F64, unit1: String, unit2: String) -> None:
    pass

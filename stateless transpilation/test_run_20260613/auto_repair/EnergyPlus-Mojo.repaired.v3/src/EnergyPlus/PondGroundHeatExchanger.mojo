from .Data.EnergyPlusData import EnergyPlusData
from .Data.BaseData import BaseGlobalStruct
from DataGlobals import DataGlobals
from  import EnergyPlus
from FluidProperties import Fluid, GlycolProps
from .Plant.PlantLocation import PlantLocation
from PlantComponent import PlantComponent
from BranchNodeConnections import BranchNodeConnections
from ConvectionCoefficients import Convect
from DataEnvironment import DataEnvironment
from DataHVACGlobals import DataHVACGlobals
from DataHeatBalance import DataHeatBalance
from DataIPShortCuts import DataIPShortCuts
from DataLoopNode import DataLoopNode
from DataPrecisionGlobals import Constant
from General import General
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import Node
from OutputProcessor import OutputProcessor
from .Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from UtilityRoutines import UtilityRoutines
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.Array.functions import allocated, deallocate
from ObjexxFCL.Fmath import pow_2, pow_3, pow_4
from math import sqrt, log, sin, cos, tan, asin, exp, abs

# Type aliases to match C++ names
alias Real64 = Float64
alias int = Int
alias bool = Bool

# Module-level constants
let StefBoltzmann: Real64 = 5.6697e-08

# Namespace EnergyPlus::PondGroundHeatExchanger
struct PondGroundHeatExchangerData(PlantComponent):
    var Name: String
    var InletNode: String
    var OutletNode: String
    var DesignMassFlowRate: Real64
    var DesignCapacity: Real64
    var Depth: Real64
    var Area: Real64
    var TubeInDiameter: Real64
    var TubeOutDiameter: Real64
    var TubeConductivity: Real64
    var GrndConductivity: Real64
    var CircuitLength: Real64
    var BulkTemperature: Real64
    var PastBulkTemperature: Real64
    var NumCircuits: int
    var InletNodeNum: int
    var OutletNodeNum: int
    var FrozenErrIndex: int
    var ConsecutiveFrozen: int
    var plantLoc: PlantLocation
    var InletTemp: Real64
    var OutletTemp: Real64
    var MassFlowRate: Real64
    var PondTemp: Real64
    var HeatTransferRate: Real64
    var Energy: Real64
    var OneTimeFlag: bool
    var MyFlag: bool
    var setupOutputVarsFlag: bool
    var water: GlycolProps? = None
    var firstTimeThrough: bool

    def __init__(inout self):
        self.Name = ""
        self.InletNode = ""
        self.OutletNode = ""
        self.DesignMassFlowRate = 0.0
        self.DesignCapacity = 0.0
        self.Depth = 0.0
        self.Area = 0.0
        self.TubeInDiameter = 0.0
        self.TubeOutDiameter = 0.0
        self.TubeConductivity = 0.0
        self.GrndConductivity = 0.0
        self.CircuitLength = 0.0
        self.BulkTemperature = 0.0
        self.PastBulkTemperature = 0.0
        self.NumCircuits = 0
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.FrozenErrIndex = 0
        self.ConsecutiveFrozen = 0
        self.plantLoc = PlantLocation()
        self.InletTemp = 0.0
        self.OutletTemp = 0.0
        self.MassFlowRate = 0.0
        self.PondTemp = 0.0
        self.HeatTransferRate = 0.0
        self.Energy = 0.0
        self.OneTimeFlag = True
        self.MyFlag = True
        self.setupOutputVarsFlag = True
        self.firstTimeThrough = True

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: bool, inout CurLoad: Real64, RunFlag: bool):
        self.InitPondGroundHeatExchanger(state, FirstHVACIteration)
        self.CalcPondGroundHeatExchanger(state)
        self.UpdatePondGroundHeatExchanger(state)

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> PlantComponent?:
        if state.dataPondGHE.GetInputFlag:
            GetPondGroundHeatExchanger(state)
            state.dataPondGHE.GetInputFlag = False
        for ghx in state.dataPondGHE.PondGHE:
            if ghx.Name == objectName:
                return ghx
        ShowFatalError(state, "Pond Heat Exchanger Factory: Error getting inputs for GHX named: " + objectName)
        return None

    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        self.InitPondGroundHeatExchanger(state, True)

    def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, inout MaxLoad: Real64, inout MinLoad: Real64, inout OptLoad: Real64):
        MaxLoad = self.DesignCapacity
        MinLoad = 0.0
        OptLoad = self.DesignCapacity

    def InitPondGroundHeatExchanger(inout self, state: EnergyPlusData, FirstHVACIteration: bool):
        self.oneTimeInit(state)
        if FirstHVACIteration and not state.dataHVACGlobal.ShortenTimeStepSys and self.firstTimeThrough:
            self.PastBulkTemperature = self.BulkTemperature
            self.firstTimeThrough = False
        elif not FirstHVACIteration:
            self.firstTimeThrough = True
        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum].Temp
        self.PondTemp = self.BulkTemperature
        var DesignFlow: Real64 = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.DesignMassFlowRate)
        PlantUtilities.SetComponentFlowRate(state, DesignFlow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
        self.MassFlowRate = state.dataLoopNodes.Node[self.InletNodeNum].MassFlowRate

    def setupOutputVars(inout self, state: EnergyPlusData):
        SetupOutputVariable(state,
            "Pond Heat Exchanger Heat Transfer Rate",
            Constant.Units.W,
            self.HeatTransferRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            "Pond Heat Exchanger Heat Transfer Energy",
            Constant.Units.J,
            self.Energy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.Name)
        SetupOutputVariable(state,
            "Pond Heat Exchanger Mass Flow Rate",
            Constant.Units.kg_s,
            self.MassFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            "Pond Heat Exchanger Inlet Temperature",
            Constant.Units.C,
            self.InletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            "Pond Heat Exchanger Outlet Temperature",
            Constant.Units.C,
            self.OutletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)
        SetupOutputVariable(state,
            "Pond Heat Exchanger Bulk Temperature",
            Constant.Units.C,
            self.PondTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.Name)

    def CalcPondGroundHeatExchanger(inout self, state: EnergyPlusData):
        let RoutineName: StringLiteral = "CalcPondGroundHeatExchanger"
        var PondMass: Real64 = self.Depth * self.Area * self.water.getDensity(state, max(self.PondTemp, 0.0), RoutineName)
        var SpecificHeat: Real64 = self.water.getSpecificHeat(state, max(self.PondTemp, 0.0), RoutineName)
        var Flux: Real64 = self.CalcTotalFLux(state, self.PondTemp)
        var PondTempStar: Real64 = self.PastBulkTemperature + 0.5 * Constant.rSecsInHour * state.dataHVACGlobal.TimeStepSys * Flux / (SpecificHeat * PondMass)
        var FluxStar: Real64 = self.CalcTotalFLux(state, PondTempStar)
        var PondTempStarStar: Real64 = self.PastBulkTemperature + 0.5 * Constant.rSecsInHour * state.dataHVACGlobal.TimeStepSys * FluxStar / (SpecificHeat * PondMass)
        var FluxStarStar: Real64 = self.CalcTotalFLux(state, PondTempStarStar)
        var PondTempStarStarStar: Real64 = self.PastBulkTemperature + Constant.rSecsInHour * state.dataHVACGlobal.TimeStepSys * FluxStarStar / (SpecificHeat * PondMass)
        self.PondTemp = self.PastBulkTemperature + Constant.rSecsInHour * state.dataHVACGlobal.TimeStepSys * (Flux + 2.0 * FluxStar + 2.0 * FluxStarStar + self.CalcTotalFLux(state, PondTempStarStarStar)) / (6.0 * SpecificHeat * PondMass)

    def CalcTotalFLux(inout self, state: EnergyPlusData, PondBulkTemp: Real64) -> Real64:
        var CalcTotalFLux: Real64
        let PrandtlAir: Real64 = 0.71
        let SchmidtAir: Real64 = 0.6
        let PondHeight: Real64 = 0.0
        let RoutineName: StringLiteral = "PondGroundHeatExchanger:CalcTotalFlux"
        var ThermalAbs: Real64 = 0.9
        var OutDryBulb: Real64 = DataEnvironment.OutDryBulbTempAt(state, PondHeight)
        var OutWetBulb: Real64 = DataEnvironment.OutWetBulbTempAt(state, PondHeight)
        var ExternalTemp: Real64
        if state.dataEnvrn.IsSnow or state.dataEnvrn.IsRain:
            ExternalTemp = OutWetBulb
        else:
            ExternalTemp = OutDryBulb
        var SurfTempAbs: Real64 = PondBulkTemp + Constant.Kelvin
        var SkyTempAbs: Real64 = state.dataEnvrn.SkyTemp + Constant.Kelvin
        var ConvCoef: Real64 = Convect.CalcASHRAESimpExtConvCoeff(Material.SurfaceRoughness.VeryRough, DataEnvironment.WindSpeedAt(state, PondHeight))
        var FluxConvect: Real64 = ConvCoef * (PondBulkTemp - ExternalTemp)
        var FluxLongwave: Real64 = StefBoltzmann * ThermalAbs * (pow_4(SurfTempAbs) - pow_4(SkyTempAbs))
        var FluxSolAbsorbed: Real64 = self.CalcSolarFlux(state)
        var SpecHeat: Real64 = self.plantLoc.loop.glycol.getSpecificHeat(state, max(self.InletTemp, 0.0), RoutineName)
        var effectiveness: Real64 = self.CalcEffectiveness(state, self.InletTemp, PondBulkTemp, self.MassFlowRate)
        var Qfluid: Real64 = self.MassFlowRate * SpecHeat * effectiveness * (self.InletTemp - PondBulkTemp)
        var HumRatioAir: Real64 = Psychrometrics.PsyWFnTdbTwbPb(state, OutDryBulb, OutWetBulb, state.dataEnvrn.OutBaroPress)
        var HumRatioFilm: Real64 = Psychrometrics.PsyWFnTdbTwbPb(state, PondBulkTemp, PondBulkTemp, state.dataEnvrn.OutBaroPress)
        var SpecHeatAir: Real64 = Psychrometrics.PsyCpAirFnW(HumRatioAir)
        var LatentHeatAir: Real64 = Psychrometrics.PsyHfgAirFnWTdb(HumRatioAir, OutDryBulb)
        var FluxEvap: Real64 = pow_2(PrandtlAir / SchmidtAir) / 3.0 * ConvCoef / SpecHeatAir * (HumRatioFilm - HumRatioAir) * LatentHeatAir
        var Perimeter: Real64 = 4.0 * sqrt(self.Area)
        var UvalueGround: Real64 = 0.999 * (self.GrndConductivity / self.Depth) + 1.37 * (self.GrndConductivity * Perimeter / self.Area)
        var FluxGround: Real64 = UvalueGround * (PondBulkTemp - state.dataEnvrn.GroundTemp[DataEnvironment.GroundTempType.Deep])
        CalcTotalFLux = Qfluid + self.Area * (FluxSolAbsorbed - FluxConvect - FluxLongwave - FluxEvap - FluxGround)
        return CalcTotalFLux

    def CalcSolarFlux(inout self, state: EnergyPlusData) -> Real64:
        var CalcSolarFlux: Real64
        let WaterRefIndex: Real64 = 1.33
        let AirRefIndex: Real64 = 1.0003
        let PondExtCoef: Real64 = 0.3
        if not state.dataEnvrn.SunIsUp:
            CalcSolarFlux = 0.0
            return CalcSolarFlux
        var IncidAngle: Real64 = acos(state.dataEnvrn.SOLCOS[2])  # 0-based index for 3rd element
        var RefractAngle: Real64 = asin(sin(IncidAngle) * AirRefIndex / WaterRefIndex)
        var Absorbtance: Real64 = exp(-PondExtCoef * self.Depth / cos(RefractAngle))
        var ParallelRad: Real64 = pow_2(tan(RefractAngle - IncidAngle)) / pow_2(tan(RefractAngle + IncidAngle))
        var PerpendRad: Real64 = pow_2(sin(RefractAngle - IncidAngle)) / pow_2(sin(RefractAngle + IncidAngle))
        var Transmitance: Real64 = 0.5 * Absorbtance * ((1.0 - ParallelRad) / (1.0 + ParallelRad) + (1.0 - PerpendRad) / (1.0 + PerpendRad))
        var Reflectance: Real64 = Absorbtance - Transmitance
        CalcSolarFlux = (1.0 - Reflectance) * (state.dataEnvrn.SOLCOS[2] * state.dataEnvrn.BeamSolarRad + state.dataEnvrn.DifSolarRad)
        return CalcSolarFlux

    def CalcEffectiveness(inout self, state: EnergyPlusData, InsideTemperature: Real64, PondTemperature: Real64, massFlowRate: Real64) -> Real64:
        var CalcEffectiveness: Real64
        let MaxLaminarRe: Real64 = 2300.0
        let GravConst: Real64 = 9.81
        let CalledFrom: StringLiteral = "PondGroundHeatExchanger:CalcEffectiveness"
        var SpecificHeat: Real64 = self.plantLoc.loop.glycol.getSpecificHeat(state, InsideTemperature, CalledFrom)
        var Conductivity: Real64 = self.plantLoc.loop.glycol.getConductivity(state, InsideTemperature, CalledFrom)
        var Viscosity: Real64 = self.plantLoc.loop.glycol.getViscosity(state, InsideTemperature, CalledFrom)
        var ReynoldsNum: Real64 = 4.0 * massFlowRate / (Constant.Pi * Viscosity * self.TubeInDiameter * self.NumCircuits)
        var PrantlNum: Real64 = Viscosity * SpecificHeat / Conductivity
        var NusseltNum: Real64
        if ReynoldsNum >= MaxLaminarRe:
            NusseltNum = 0.023 * pow(ReynoldsNum, 0.8) * pow(PrantlNum, 0.3)
        else:
            NusseltNum = 3.66
        var ConvCoefIn: Real64 = Conductivity * NusseltNum / self.TubeInDiameter
        var WaterSpecHeat: Real64 = self.water.getSpecificHeat(state, max(PondTemperature, 0.0), CalledFrom)
        var WaterConductivity: Real64 = self.water.getConductivity(state, max(PondTemperature, 0.0), CalledFrom)
        var WaterViscosity: Real64 = self.water.getViscosity(state, max(PondTemperature, 0.0), CalledFrom)
        var WaterDensity: Real64 = self.water.getDensity(state, max(PondTemperature, 0.0), CalledFrom)
        var ExpansionCoef: Real64 = -(self.water.getDensity(state, max(PondTemperature, 10.0) + 5.0, CalledFrom) - self.water.getDensity(state, max(PondTemperature, 10.0) - 5.0, CalledFrom)) / (10.0 * WaterDensity)
        var ThermDiff: Real64 = WaterConductivity / (WaterDensity * WaterSpecHeat)
        PrantlNum = WaterViscosity * WaterSpecHeat / WaterConductivity
        var RayleighNum: Real64 = WaterDensity * GravConst * ExpansionCoef * abs(InsideTemperature - PondTemperature) * pow_3(self.TubeOutDiameter) / (WaterViscosity * ThermDiff)
        NusseltNum = pow_2(0.6 + (0.387 * pow(RayleighNum, 1.0 / 6.0) / (pow(1.0 + 0.559 / pow(PrantlNum, 9.0 / 16.0), 8.0 / 27.0))))
        var ConvCoefOut: Real64 = WaterConductivity * NusseltNum / self.TubeOutDiameter
        var PipeResistance: Real64 = self.TubeInDiameter / self.TubeConductivity * log(self.TubeOutDiameter / self.TubeInDiameter)
        var TotalResistance: Real64 = PipeResistance + 1.0 / ConvCoefIn + self.TubeInDiameter / (self.TubeOutDiameter * ConvCoefOut)
        var NTU: Real64
        if massFlowRate == 0.0:
            CalcEffectiveness = 1.0
        else:
            NTU = Constant.Pi * self.TubeInDiameter * self.CircuitLength * self.NumCircuits / (TotalResistance * massFlowRate * SpecificHeat)
            CalcEffectiveness = (1.0 - exp(-NTU))
        if PondTemperature < 0.0:
            self.ConsecutiveFrozen += 1
            if self.FrozenErrIndex == 0:
                ShowWarningMessage(state, "GroundHeatExchanger:Pond=\"" + self.Name + "\", is frozen; Pond model not valid. Calculated Pond Temperature=[" + str(PondTemperature) + "] C")
                ShowContinueErrorTimeStamp(state, "")
            ShowRecurringWarningErrorAtEnd(state, "GroundHeatExchanger:Pond=\"" + self.Name + "\", is frozen", self.FrozenErrIndex, PondTemperature, PondTemperature, _, "[C]", "[C]")
            if self.ConsecutiveFrozen >= state.dataGlobal.TimeStepsInHour * 30:
                ShowFatalError(state, "GroundHeatExchanger:Pond=\"" + self.Name + "\" has been frozen for 30 consecutive hours.  Program terminates.")
        else:
            self.ConsecutiveFrozen = 0
        return CalcEffectiveness

    def UpdatePondGroundHeatExchanger(inout self, state: EnergyPlusData):
        let RoutineName: StringLiteral = "PondGroundHeatExchanger:Update"
        var CpFluid: Real64 = self.plantLoc.loop.glycol.getSpecificHeat(state, self.InletTemp, RoutineName)
        PlantUtilities.SafeCopyPlantNode(state, self.InletNodeNum, self.OutletNodeNum)
        if (CpFluid > 0.0) and (self.MassFlowRate > 0.0):
            self.OutletTemp = self.InletTemp - self.HeatTransferRate / (self.MassFlowRate * CpFluid)
        else:
            self.OutletTemp = self.InletTemp
        state.dataLoopNodes.Node[self.OutletNodeNum].Temp = self.OutletTemp
        state.dataLoopNodes.Node[self.OutletNodeNum].MassFlowRate = self.MassFlowRate
        var effectiveness: Real64 = self.CalcEffectiveness(state, self.InletTemp, self.PondTemp, self.MassFlowRate)
        self.HeatTransferRate = self.MassFlowRate * CpFluid * effectiveness * (self.InletTemp - self.PondTemp)
        self.Energy = self.HeatTransferRate * state.dataHVACGlobal.TimeStepSysSec
        self.BulkTemperature = self.PondTemp

    def oneTimeInit(inout self, state: EnergyPlusData):
        let DesignVelocity: Real64 = 0.5
        let PondHeight: Real64 = 0.0
        let RoutineName: StringLiteral = "InitPondGroundHeatExchanger"
        if self.setupOutputVarsFlag:
            self.setupOutputVars(state)
            self.setupOutputVarsFlag = False
        if self.OneTimeFlag or state.dataGlobal.WarmupFlag:
            self.BulkTemperature = self.PastBulkTemperature = 0.5 * (DataEnvironment.OutDryBulbTempAt(state, PondHeight) + state.dataEnvrn.GroundTemp[DataEnvironment.GroundTempType.Deep])
            self.OneTimeFlag = False
        if self.MyFlag:
            var errFlag: bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.GrndHtExchgPond, self.plantLoc, errFlag, _, _, _, _, _)
            if errFlag:
                ShowFatalError(state, "InitPondGroundHeatExchanger: Program terminated due to previous condition(s).")
            var rho: Real64 = self.plantLoc.loop.glycol.getDensity(state, 0.0, RoutineName)
            var Cp: Real64 = self.plantLoc.loop.glycol.getSpecificHeat(state, 0.0, RoutineName)
            self.DesignMassFlowRate = Constant.Pi / 4.0 * pow_2(self.TubeInDiameter) * DesignVelocity * rho * self.NumCircuits
            self.DesignCapacity = self.DesignMassFlowRate * Cp * 10.0
            PlantUtilities.InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.InletNodeNum, self.DesignMassFlowRate / rho)
            self.MyFlag = False

# Global struct (in EnergyPlus namespace)
struct PondGroundHeatExchangerData(BaseGlobalStruct):
    var GetInputFlag: bool = True
    var NumOfPondGHEs: int = 0
    var PondGHE: Array1D[PondGroundHeatExchanger.PondGroundHeatExchangerData] = Array1D[PondGroundHeatExchanger.PondGroundHeatExchangerData]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.GetInputFlag = True
        self.NumOfPondGHEs = 0
        self.PondGHE.deallocate()

# Free function GetPondGroundHeatExchanger
def GetPondGroundHeatExchanger(state: EnergyPlusData):
    var ErrorsFound: bool = False
    var IOStatus: int
    var Item: int
    var NumAlphas: int
    var NumNumbers: int
    state.dataIPShortCut.cCurrentModuleObject = "GroundHeatExchanger:Pond"
    state.dataPondGHE.NumOfPondGHEs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    if allocated(state.dataPondGHE.PondGHE):
        state.dataPondGHE.PondGHE.deallocate()
    state.dataPondGHE.PondGHE.allocate(state.dataPondGHE.NumOfPondGHEs)
    for Item in range(1, state.dataPondGHE.NumOfPondGHEs + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
            state.dataIPShortCut.cCurrentModuleObject,
            Item,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNumbers,
            IOStatus,
            _,
            _,
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames)
        if (state.dataPondGHE.PondGHE[Item-1].water = Fluid.GetWater(state)) == None:
            ShowSevereError(state, "Fluid Properties for WATER not found")
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item-1].Name = state.dataIPShortCut.cAlphaArgs[0]
        state.dataPondGHE.PondGHE[Item-1].InletNode = state.dataIPShortCut.cAlphaArgs[1]
        state.dataPondGHE.PondGHE[Item-1].InletNodeNum = Node.GetOnlySingleNode(state,
            state.dataIPShortCut.cAlphaArgs[1],
            ErrorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerPond,
            state.dataIPShortCut.cAlphaArgs[0],
            Node.FluidType.Water,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        if state.dataPondGHE.PondGHE[Item-1].InletNodeNum == 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cAlphaFieldNames[1] + "=" + state.dataIPShortCut.cAlphaArgs[1])
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item-1].OutletNode = state.dataIPShortCut.cAlphaArgs[2]
        state.dataPondGHE.PondGHE[Item-1].OutletNodeNum = Node.GetOnlySingleNode(state,
            state.dataIPShortCut.cAlphaArgs[2],
            ErrorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerPond,
            state.dataIPShortCut.cAlphaArgs[0],
            Node.FluidType.Water,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)
        if state.dataPondGHE.PondGHE[Item-1].OutletNodeNum == 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cAlphaFieldNames[2] + "=" + state.dataIPShortCut.cAlphaArgs[2])
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ErrorsFound = True
        Node.TestCompSet(state,
            state.dataIPShortCut.cCurrentModuleObject,
            state.dataIPShortCut.cAlphaArgs[0],
            state.dataIPShortCut.cAlphaArgs[1],
            state.dataIPShortCut.cAlphaArgs[2],
            "Condenser Water Nodes")
        state.dataPondGHE.PondGHE[Item-1].Depth = state.dataIPShortCut.rNumericArgs[0]
        state.dataPondGHE.PondGHE[Item-1].Area = state.dataIPShortCut.rNumericArgs[1]
        if state.dataIPShortCut.rNumericArgs[0] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[0] + "=" + str(state.dataIPShortCut.rNumericArgs[0]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[1] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[1] + "=" + str(state.dataIPShortCut.rNumericArgs[1]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item-1].TubeInDiameter = state.dataIPShortCut.rNumericArgs[2]
        state.dataPondGHE.PondGHE[Item-1].TubeOutDiameter = state.dataIPShortCut.rNumericArgs[3]
        if state.dataIPShortCut.rNumericArgs[2] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[2] + "=" + str(state.dataIPShortCut.rNumericArgs[2]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[3] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[3] + "=" + str(state.dataIPShortCut.rNumericArgs[3]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[2] > state.dataIPShortCut.rNumericArgs[3]:
            ShowSevereError(state, "For " + state.dataIPShortCut.cCurrentModuleObject + ": " + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, state.dataIPShortCut.cNumericFieldNames[2] + " [" + str(state.dataIPShortCut.rNumericArgs[2]) + "] > " + state.dataIPShortCut.cNumericFieldNames[3] + " [" + str(state.dataIPShortCut.rNumericArgs[3]) + "]")
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item-1].TubeConductivity = state.dataIPShortCut.rNumericArgs[4]
        state.dataPondGHE.PondGHE[Item-1].GrndConductivity = state.dataIPShortCut.rNumericArgs[5]
        if state.dataIPShortCut.rNumericArgs[4] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[4] + "=" + str(state.dataIPShortCut.rNumericArgs[4]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[5] <= 0.0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[5] + "=" + str(state.dataIPShortCut.rNumericArgs[5]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item-1].NumCircuits = state.dataIPShortCut.rNumericArgs[6]
        if state.dataIPShortCut.rNumericArgs[6] <= 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[6] + "=" + str(state.dataIPShortCut.rNumericArgs[6]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
        state.dataPondGHE.PondGHE[Item-1].CircuitLength = state.dataIPShortCut.rNumericArgs[7]
        if state.dataIPShortCut.rNumericArgs[7] <= 0:
            ShowSevereError(state, "Invalid " + state.dataIPShortCut.cNumericFieldNames[7] + "=" + str(state.dataIPShortCut.rNumericArgs[7]))
            ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + state.dataIPShortCut.cAlphaArgs[0])
            ShowContinueError(state, "Value must be greater than 0.0")
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing input for " + state.dataIPShortCut.cCurrentModuleObject)
    if not state.dataEnvrn.GroundTempInputs[DataEnvironment.GroundTempType.Deep]:
        ShowWarningError(state, "GetPondGroundHeatExchanger:  No \"Site:GroundTemperature:Deep\" were input.")
        ShowContinueError(state, "Defaults, constant throughout the year of (" + str(state.dataEnvrn.GroundTemp[DataEnvironment.GroundTempType.Deep]) + ") will be used.")
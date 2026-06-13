from ObjexxFCL.Array.functions import Array1D_string, Array1D_Real64
from ObjexxFCL.Fmath import max
from BranchNodeConnections import Node
from CurveManager import Curve
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import state.dataEnvrn
from EnergyPlus.DataGenerators import DataGenerators, OperatingMode
from EnergyPlus.DataGlobalConstants import Constant
from DataHVACGlobals import state.dataHVACGlobal
from DataHeatBalance import DataHeatBalance
from EnergyPlus.DataIPShortCuts import state.dataIPShortCut
from EnergyPlus.DataLoopNode import state.dataLoopNodes
from DataSizing import state.dataSize
from FluidProperties import FluidProperties
from General import Util
from GeneratorDynamicsManager import GeneratorDynamicsManager
from GeneratorFuelSupply import GeneratorFuelSupply
from HeatBalanceInternalHeatGains import SetupZoneInternalGain
from .InputProcessing.InputProcessor import InputProcessor
from MicroCHPElectricGenerator import MicroCHPElectricGenerator
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor, SetupOutputVariable
from EnergyPlus.Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from ScheduleManager import Sched
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ShowSevereEmptyField, ShowSevereItemNotFound, ErrorObjectHeader
from ZoneTempPredictorCorrector import state.dataZoneTempPredictorCorrector
from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.EnergyPlus import EnergyPlus
from EnergyPlus.PlantComponent import PlantComponent
from EnergyPlus.DataGenerators import DataGenerators
from EnergyPlus.DataGlobalConstants import Constant
from DataHVACGlobals import state.dataHVACGlobal
from DataHeatBalance import DataHeatBalance
from EnergyPlus.DataIPShortCuts import state.dataIPShortCut
from EnergyPlus.DataLoopNode import state.dataLoopNodes
from DataSizing import state.dataSize
from FluidProperties import FluidProperties
from General import Util
from GeneratorDynamicsManager import GeneratorDynamicsManager
from GeneratorFuelSupply import GeneratorFuelSupply
from HeatBalanceInternalHeatGains import SetupZoneInternalGain
from .InputProcessing.InputProcessor import InputProcessor
from MicroCHPElectricGenerator import MicroCHPElectricGenerator
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor, SetupOutputVariable
from EnergyPlus.Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from ScheduleManager import Sched
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ShowSevereEmptyField, ShowSevereItemNotFound, ErrorObjectHeader
from ZoneTempPredictorCorrector import state.dataZoneTempPredictorCorrector
from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.EnergyPlus import EnergyPlus
from EnergyPlus.PlantComponent import PlantComponent
from EnergyPlus.DataGenerators import DataGenerators
from EnergyPlus.DataGlobalConstants import Constant
from DataHVACGlobals import state.dataHVACGlobal
from DataHeatBalance import DataHeatBalance
from EnergyPlus.DataIPShortCuts import state.dataIPShortCut
from EnergyPlus.DataLoopNode import state.dataLoopNodes
from DataSizing import state.dataSize
from FluidProperties import FluidProperties
from General import Util
from GeneratorDynamicsManager import GeneratorDynamicsManager
from GeneratorFuelSupply import GeneratorFuelSupply
from HeatBalanceInternalHeatGains import SetupZoneInternalGain
from .InputProcessing.InputProcessor import InputProcessor
from MicroCHPElectricGenerator import MicroCHPElectricGenerator
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor, SetupOutputVariable
from EnergyPlus.Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from ScheduleManager import Sched
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ShowSevereEmptyField, ShowSevereItemNotFound, ErrorObjectHeader
from ZoneTempPredictorCorrector import state.dataZoneTempPredictorCorrector

from math import exp
from memory import memset_zero
from python import Python

struct MicroCHPParamsNonNormalized:
    var Name: String
    var MaxElecPower: Float64
    var MinElecPower: Float64
    var MinWaterMdot: Float64
    var MaxWaterTemp: Float64
    var ElecEffCurve: Curve
    var ThermalEffCurve: Curve
    var InternalFlowControl: Bool
    var PlantFlowControl: Bool
    var WaterFlowCurve: Curve
    var AirFlowCurve: Curve
    var DeltaPelMax: Float64
    var DeltaFuelMdotMax: Float64
    var UAhx: Float64
    var UAskin: Float64
    var RadiativeFraction: Float64
    var MCeng: Float64
    var MCcw: Float64
    var Pstandby: Float64
    var WarmUpByTimeDelay: Bool
    var WarmUpByEngineTemp: Bool
    var kf: Float64
    var TnomEngOp: Float64
    var kp: Float64
    var Rfuelwarmup: Float64
    var WarmUpDelay: Float64
    var PcoolDown: Float64
    var CoolDownDelay: Float64
    var MandatoryFullCoolDown: Bool
    var WarmRestartOkay: Bool
    var TimeElapsed: Float64
    var OpMode: DataGenerators.OperatingMode
    var OffModeTime: Float64
    var StandyByModeTime: Float64
    var WarmUpModeTime: Float64
    var NormalModeTime: Float64
    var CoolDownModeTime: Float64
    var TengLast: Float64
    var TempCWOutLast: Float64
    var Pnet: Float64
    var ElecEff: Float64
    var Qgross: Float64
    var ThermEff: Float64
    var Qgenss: Float64
    var NdotFuel: Float64
    var MdotFuel: Float64
    var Teng: Float64
    var TcwIn: Float64
    var TcwOut: Float64
    var MdotAir: Float64
    var QdotSkin: Float64
    var QdotConvZone: Float64
    var QdotRadZone: Float64
    var ACPowerGen: Float64
    var ACEnergyGen: Float64
    var QdotHX: Float64
    var QdotHR: Float64
    var TotalHeatEnergyRec: Float64
    var FuelEnergyLHV: Float64
    var FuelEnergyUseRateLHV: Float64
    var FuelEnergyHHV: Float64
    var FuelEnergyUseRateHHV: Float64
    var HeatRecInletTemp: Float64
    var HeatRecOutletTemp: Float64
    var FuelCompressPower: Float64
    var FuelCompressEnergy: Float64
    var FuelCompressSkinLoss: Float64
    var SkinLossPower: Float64
    var SkinLossEnergy: Float64
    var SkinLossConvect: Float64
    var SkinLossRadiat: Float64

    def __init__(inout self):
        self.Name = String("")
        self.MaxElecPower = 0.0
        self.MinElecPower = 0.0
        self.MinWaterMdot = 0.0
        self.MaxWaterTemp = 0.0
        self.ElecEffCurve = Curve()
        self.ThermalEffCurve = Curve()
        self.InternalFlowControl = False
        self.PlantFlowControl = True
        self.WaterFlowCurve = Curve()
        self.AirFlowCurve = Curve()
        self.DeltaPelMax = 0.0
        self.DeltaFuelMdotMax = 0.0
        self.UAhx = 0.0
        self.UAskin = 0.0
        self.RadiativeFraction = 0.0
        self.MCeng = 0.0
        self.MCcw = 0.0
        self.Pstandby = 0.0
        self.WarmUpByTimeDelay = False
        self.WarmUpByEngineTemp = True
        self.kf = 0.0
        self.TnomEngOp = 0.0
        self.kp = 0.0
        self.Rfuelwarmup = 0.0
        self.WarmUpDelay = 0.0
        self.PcoolDown = 0.0
        self.CoolDownDelay = 0.0
        self.MandatoryFullCoolDown = False
        self.WarmRestartOkay = True
        self.TimeElapsed = 0.0
        self.OpMode = DataGenerators.OperatingMode.Invalid
        self.OffModeTime = 0.0
        self.StandyByModeTime = 0.0
        self.WarmUpModeTime = 0.0
        self.NormalModeTime = 0.0
        self.CoolDownModeTime = 0.0
        self.TengLast = 20.0
        self.TempCWOutLast = 20.0
        self.Pnet = 0.0
        self.ElecEff = 0.0
        self.Qgross = 0.0
        self.ThermEff = 0.0
        self.Qgenss = 0.0
        self.NdotFuel = 0.0
        self.MdotFuel = 0.0
        self.Teng = 20.0
        self.TcwIn = 20.0
        self.TcwOut = 20.0
        self.MdotAir = 0.0
        self.QdotSkin = 0.0
        self.QdotConvZone = 0.0
        self.QdotRadZone = 0.0
        self.ACPowerGen = 0.0
        self.ACEnergyGen = 0.0
        self.QdotHX = 0.0
        self.QdotHR = 0.0
        self.TotalHeatEnergyRec = 0.0
        self.FuelEnergyLHV = 0.0
        self.FuelEnergyUseRateLHV = 0.0
        self.FuelEnergyHHV = 0.0
        self.FuelEnergyUseRateHHV = 0.0
        self.HeatRecInletTemp = 0.0
        self.HeatRecOutletTemp = 0.0
        self.FuelCompressPower = 0.0
        self.FuelCompressEnergy = 0.0
        self.FuelCompressSkinLoss = 0.0
        self.SkinLossPower = 0.0
        self.SkinLossEnergy = 0.0
        self.SkinLossConvect = 0.0
        self.SkinLossRadiat = 0.0

struct MicroCHPDataStruct(PlantComponent):
    var Name: String
    var ParamObjName: String
    var A42Model: MicroCHPParamsNonNormalized
    var NomEff: Float64
    var ZoneName: String
    var ZoneID: Int
    var PlantInletNodeName: String
    var PlantInletNodeID: Int
    var PlantOutletNodeName: String
    var PlantOutletNodeID: Int
    var PlantMassFlowRate: Float64
    var PlantMassFlowRateMax: Float64
    var PlantMassFlowRateMaxWasAutoSized: Bool
    var AirInletNodeName: String
    var AirInletNodeID: Int
    var AirOutletNodeName: String
    var AirOutletNodeID: Int
    var FuelSupplyID: Int
    var DynamicsControlID: Int
    var availSched: Sched.Schedule
    var CWPlantLoc: PlantLocation
    var CheckEquipName: Bool
    var MySizeFlag: Bool
    var MyEnvrnFlag: Bool
    var MyPlantScanFlag: Bool
    var myFlag: Bool

    def __init__(inout self):
        self.Name = String("")
        self.ParamObjName = String("")
        self.A42Model = MicroCHPParamsNonNormalized()
        self.NomEff = 0.0
        self.ZoneName = String("")
        self.ZoneID = 0
        self.PlantInletNodeName = String("")
        self.PlantInletNodeID = 0
        self.PlantOutletNodeName = String("")
        self.PlantOutletNodeID = 0
        self.PlantMassFlowRate = 0.0
        self.PlantMassFlowRateMax = 0.0
        self.PlantMassFlowRateMaxWasAutoSized = False
        self.AirInletNodeName = String("")
        self.AirInletNodeID = 0
        self.AirOutletNodeName = String("")
        self.AirOutletNodeID = 0
        self.FuelSupplyID = 0
        self.DynamicsControlID = 0
        self.availSched = Sched.Schedule()
        self.CWPlantLoc = PlantLocation()
        self.CheckEquipName = True
        self.MySizeFlag = True
        self.MyEnvrnFlag = True
        self.MyPlantScanFlag = True
        self.myFlag = True

    def simulate(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        PlantUtilities.UpdateComponentHeatRecoverySide(state,
                                                        self.CWPlantLoc.loopNum,
                                                        self.CWPlantLoc.loopSideNum,
                                                        DataPlant.PlantEquipmentType.Generator_MicroCHP,
                                                        self.PlantInletNodeID,
                                                        self.PlantOutletNodeID,
                                                        self.A42Model.QdotHR,
                                                        self.A42Model.HeatRecInletTemp,
                                                        self.A42Model.HeatRecOutletTemp,
                                                        self.PlantMassFlowRate,
                                                        FirstHVACIteration)

    def getDesignCapacities(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, inout MaxLoad: Float64, inout MinLoad: Float64, inout OptLoad: Float64):
        MaxLoad = state.dataGenerator.GeneratorDynamics[self.DynamicsControlID].QdotHXMax
        MinLoad = state.dataGenerator.GeneratorDynamics[self.DynamicsControlID].QdotHXMin
        OptLoad = state.dataGenerator.GeneratorDynamics[self.DynamicsControlID].QdotHXOpt

    def onInitLoopEquip(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation):
        var RoutineName: String = "MicroCHPDataStruct::onInitLoopEquip"
        var rho: Float64 = self.CWPlantLoc.loop.glycol.getDensity(state, state.dataLoopNodes.Node[self.PlantInletNodeID].Temp, RoutineName)
        if self.A42Model.InternalFlowControl:
            self.PlantMassFlowRateMax = 2.0 * self.A42Model.WaterFlowCurve.value(state, self.A42Model.MaxElecPower, state.dataLoopNodes.Node[self.PlantInletNodeID].Temp)
        elif self.CWPlantLoc.loopSideNum == DataPlant.LoopSideLocation.Supply:
            if self.CWPlantLoc.loop.MaxMassFlowRate > 0.0:
                self.PlantMassFlowRateMax = self.CWPlantLoc.loop.MaxMassFlowRate
            elif self.CWPlantLoc.loop.PlantSizNum > 0:
                self.PlantMassFlowRateMax = state.dataSize.PlantSizData[self.CWPlantLoc.loopNum].DesVolFlowRate * rho
            else:
                self.PlantMassFlowRateMax = 2.0
        elif self.CWPlantLoc.loopSideNum == DataPlant.LoopSideLocation.Demand:
            self.PlantMassFlowRateMax = 2.0
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.PlantInletNodeID, self.PlantMassFlowRateMax / rho)
        self.A42Model.ElecEff = self.A42Model.ElecEffCurve.value(state, self.A42Model.MaxElecPower, self.PlantMassFlowRateMax, state.dataLoopNodes.Node[self.PlantInletNodeID].Temp)
        self.A42Model.ThermEff = self.A42Model.ThermalEffCurve.value(state, self.A42Model.MaxElecPower, self.PlantMassFlowRateMax, state.dataLoopNodes.Node[self.PlantInletNodeID].Temp)
        GeneratorDynamicsManager.SetupGeneratorControlStateManager(state, self.DynamicsControlID)

    def setupOutputVars(inout self, inout state: EnergyPlusData):
        SetupOutputVariable(state,
                            "Generator Off Mode Time",
                            Constant.Units.s,
                            self.A42Model.OffModeTime,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Standby Mode Time",
                            Constant.Units.s,
                            self.A42Model.StandyByModeTime,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Warm Up Mode Time",
                            Constant.Units.s,
                            self.A42Model.WarmUpModeTime,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Normal Operating Mode Time",
                            Constant.Units.s,
                            self.A42Model.NormalModeTime,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Cool Down Mode Time",
                            Constant.Units.s,
                            self.A42Model.CoolDownModeTime,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Produced AC Electricity Rate",
                            Constant.Units.W,
                            self.A42Model.ACPowerGen,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Produced AC Electricity Energy",
                            Constant.Units.J,
                            self.A42Model.ACEnergyGen,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name,
                            Constant.eResource.ElectricityProduced,
                            OutputProcessor.Group.Plant,
                            OutputProcessor.EndUseCat.Cogeneration)
        SetupOutputVariable(state,
                            "Generator Produced Thermal Rate",
                            Constant.Units.W,
                            self.A42Model.QdotHR,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Produced Thermal Energy",
                            Constant.Units.J,
                            self.A42Model.TotalHeatEnergyRec,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name,
                            Constant.eResource.EnergyTransfer,
                            OutputProcessor.Group.Plant,
                            OutputProcessor.EndUseCat.Cogeneration)
        SetupOutputVariable(state,
                            "Generator Electric Efficiency",
                            Constant.Units.None,
                            self.A42Model.ElecEff,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Thermal Efficiency",
                            Constant.Units.None,
                            self.A42Model.ThermEff,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Gross Input Heat Rate",
                            Constant.Units.W,
                            self.A42Model.Qgross,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Steady State Engine Heat Generation Rate",
                            Constant.Units.W,
                            self.A42Model.Qgenss,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Engine Heat Exchange Rate",
                            Constant.Units.W,
                            self.A42Model.QdotHX,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Air Mass Flow Rate",
                            Constant.Units.kg_s,
                            self.A42Model.MdotAir,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel Molar Flow Rate",
                            Constant.Units.kmol_s,
                            self.A42Model.NdotFuel,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel Mass Flow Rate",
                            Constant.Units.kg_s,
                            self.A42Model.MdotFuel,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Engine Temperature",
                            Constant.Units.C,
                            self.A42Model.Teng,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Coolant Inlet Temperature",
                            Constant.Units.C,
                            self.A42Model.HeatRecInletTemp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Coolant Outlet Temperature",
                            Constant.Units.C,
                            self.A42Model.HeatRecOutletTemp,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel HHV Basis Energy",
                            Constant.Units.J,
                            self.A42Model.FuelEnergyHHV,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name,
                            Constant.eResource.NaturalGas,
                            OutputProcessor.Group.Plant,
                            OutputProcessor.EndUseCat.Cogeneration)
        SetupOutputVariable(state,
                            "Generator Fuel HHV Basis Rate",
                            Constant.Units.W,
                            self.A42Model.FuelEnergyUseRateHHV,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel LHV Basis Energy",
                            Constant.Units.J,
                            self.A42Model.FuelEnergyLHV,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel LHV Basis Rate",
                            Constant.Units.W,
                            self.A42Model.FuelEnergyUseRateLHV,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel Compressor Electricity Rate",
                            Constant.Units.W,
                            self.A42Model.FuelCompressPower,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel Compressor Electricity Energy",
                            Constant.Units.J,
                            self.A42Model.FuelCompressEnergy,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Fuel Compressor Skin Heat Loss Rate",
                            Constant.Units.W,
                            self.A42Model.FuelCompressSkinLoss,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Zone Sensible Heat Transfer Rate",
                            Constant.Units.W,
                            self.A42Model.SkinLossPower,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Zone Sensible Heat Transfer Energy",
                            Constant.Units.J,
                            self.A42Model.SkinLossEnergy,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Zone Convection Heat Transfer Rate",
                            Constant.Units.W,
                            self.A42Model.SkinLossConvect,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        SetupOutputVariable(state,
                            "Generator Zone Radiation Heat Transfer Rate",
                            Constant.Units.W,
                            self.A42Model.SkinLossRadiat,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            self.Name)
        if self.ZoneID > 0:
            SetupZoneInternalGain(state,
                                  self.ZoneID,
                                  self.Name,
                                  DataHeatBalance.IntGainType.GeneratorMicroCHP,
                                  self.A42Model.SkinLossConvect,
                                  None,
                                  self.A42Model.SkinLossRadiat)

    def InitMicroCHPNoNormalizeGenerators(inout self, inout state: EnergyPlusData):
        self.oneTimeInit(state)
        if not state.dataGlobal.SysSizingCalc and self.MySizeFlag and not self.MyPlantScanFlag and (state.dataPlnt.PlantFirstSizesOkayToFinalize):
            self.MySizeFlag = False
        if self.MySizeFlag:
            return
        var DynaCntrlNum: Int = self.DynamicsControlID
        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag:
            self.A42Model.TengLast = 20.0
            self.A42Model.TempCWOutLast = 20.0
            self.A42Model.TimeElapsed = 0.0
            self.A42Model.OpMode = DataGenerators.OperatingMode.Invalid
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
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].LastOpMode = DataGenerators.OperatingMode.Off
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].CurrentOpMode = DataGenerators.OperatingMode.Off
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FractionalDayofLastShutDown = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FractionalDayofLastStartUp = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].HasBeenOn = False
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].DuringStartUp = False
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].DuringShutDown = False
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FuelMdotLastTimestep = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].PelLastTimeStep = 0.0
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].NumCycles = 0
            state.dataGenerator.FuelSupply[self.FuelSupplyID].QskinLoss = 0.0
            PlantUtilities.InitComponentNodes(state, 0.0, self.PlantMassFlowRateMax, self.PlantInletNodeID, self.PlantOutletNodeID)
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        var TimeElapsed: Float64 = state.dataGlobal.HourOfDay + state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed
        if self.A42Model.TimeElapsed != TimeElapsed:
            self.A42Model.TengLast = self.A42Model.Teng
            self.A42Model.TempCWOutLast = self.A42Model.TcwOut
            self.A42Model.TimeElapsed = TimeElapsed
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].LastOpMode = state.dataGenerator.GeneratorDynamics[DynaCntrlNum].CurrentOpMode
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].FuelMdotLastTimestep = self.A42Model.MdotFuel
            state.dataGenerator.GeneratorDynamics[DynaCntrlNum].PelLastTimeStep = self.A42Model.Pnet
        if not self.A42Model.InternalFlowControl:
            var mdot: Float64 = self.PlantMassFlowRateMax
            PlantUtilities.SetComponentFlowRate(state, mdot, self.PlantInletNodeID, self.PlantOutletNodeID, self.CWPlantLoc)
            self.PlantMassFlowRate = mdot

    def CalcMicroCHPNoNormalizeGeneratorModel(inout self, inout state: EnergyPlusData,
                                             RunFlagElectCenter: Bool,
                                             RunFlagPlant: Bool,
                                             MyElectricLoad: Float64,
                                             MyThermalLoad: Float64):
        var RoutineName: String = "CalcMicroCHPNoNormalizeGeneratorModel"
        var CurrentOpMode: DataGenerators.OperatingMode = DataGenerators.OperatingMode.Invalid
        var NdotFuel: Float64
        var AllowedLoad: Float64 = 0.0
        var PLRforSubtimestepStartUp: Float64 = 1.0
        var PLRforSubtimestepShutDown: Float64 = 0.0
        GeneratorDynamicsManager.ManageGeneratorControlState(state,
                                                              self.DynamicsControlID,
                                                              RunFlagElectCenter,
                                                              RunFlagPlant,
                                                              MyElectricLoad,
                                                              MyThermalLoad,
                                                              AllowedLoad,
                                                              CurrentOpMode,
                                                              PLRforSubtimestepStartUp,
                                                              PLRforSubtimestepShutDown)
        var Teng: Float64 = self.A42Model.Teng
        var TcwOut: Float64 = self.A42Model.TcwOut
        var thisAmbientTemp: Float64
        if self.ZoneID > 0:
            thisAmbientTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.ZoneID].MAT
        else:
            thisAmbientTemp = state.dataEnvrn.OutDryBulbTemp
        var Pnetss: Float64 = 0.0
        var Pstandby: Float64 = 0.0
        var Pcooler: Float64 = 0.0
        var ElecEff: Float64 = 0.0
        var MdotAir: Float64 = 0.0
        var Qgenss: Float64 = 0.0
        var MdotCW: Float64 = 0.0
        var TcwIn: Float64 = 0.0
        var MdotFuel: Float64 = 0.0
        var Qgross: Float64 = 0.0
        var ThermEff: Float64 = 0.0
        if CurrentOpMode == DataGenerators.OperatingMode.Off:
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
            PlantUtilities.SetComponentFlowRate(state, MdotCW, self.PlantInletNodeID, self.PlantOutletNodeID, self.CWPlantLoc)
            self.PlantMassFlowRate = MdotCW
        elif CurrentOpMode == DataGenerators.OperatingMode.Standby:
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
            PlantUtilities.SetComponentFlowRate(state, MdotCW, self.PlantInletNodeID, self.PlantOutletNodeID, self.CWPlantLoc)
            self.PlantMassFlowRate = MdotCW
        elif CurrentOpMode == DataGenerators.OperatingMode.WarmUp:
            if self.A42Model.WarmUpByTimeDelay:
                Pnetss = MyElectricLoad
                Pstandby = 0.0
                Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
                TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
                MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
                if self.A42Model.InternalFlowControl:
                    MdotCW = GeneratorDynamicsManager.FuncDetermineCWMdotForInternalFlowControl(state, self.DynamicsControlID, Pnetss, TcwIn)
                ElecEff = self.A42Model.ElecEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                ElecEff = max(0.0, ElecEff)
                if ElecEff > 0.0:
                    Qgross = Pnetss / ElecEff
                else:
                    Qgross = 0.0
                ThermEff = self.A42Model.ThermalEffCurve.value(state, Pnetss, MdotCW, TcwIn)
                ThermEff = max(0.0, ThermEff)
                Qgenss = ThermEff * Qgross
                MdotFuel = Qgross / (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0) * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                var ConstrainedIncreasingNdot: Bool = False
                var ConstrainedDecreasingNdot: Bool = False
                var MdotFuelAllowed: Float64 = 0.0
                GeneratorDynamicsManager.ManageGeneratorFuelFlow(state, self.DynamicsControlID, MdotFuel, MdotFuelAllowed, ConstrainedIncreasingNdot, ConstrainedDecreasingNdot)
                if ConstrainedIncreasingNdot or ConstrainedDecreasingNdot:
                    MdotFuel = MdotFuelAllowed
                    NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                    Qgross = NdotFuel * (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)
                    for i in range(1, 21):
                        Pnetss = Qgross * ElecEff
                        if self.A42Model.InternalFlowControl:
                            MdotCW = GeneratorDynamicsManager.FuncDetermineCWMdotForInternalFlowControl(state, self.DynamicsControlID, Pnetss, TcwIn)
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
                var Pmax: Float64 = self.A42Model.MaxElecPower
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
                var MdotFuelMax: Float64 = NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                var MdotFuelWarmup: Float64
                if Teng > thisAmbientTemp:
                    MdotFuelWarmup = MdotFuelMax + self.A42Model.kf * MdotFuelMax * ((self.A42Model.TnomEngOp - thisAmbientTemp) / (Teng - thisAmbientTemp))
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
        elif CurrentOpMode == DataGenerators.OperatingMode.Normal:
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
                MdotCW = GeneratorDynamicsManager.FuncDetermineCWMdotForInternalFlowControl(state, self.DynamicsControlID, Pnetss, TcwIn)
            ElecEff = self.A42Model.ElecEffCurve.value(state, Pnetss, MdotCW, TcwIn)
            ElecEff = max(0.0, ElecEff)
            if ElecEff > 0.0:
                Qgross = Pnetss / ElecEff
            else:
                Qgross = 0.0
            ThermEff = self.A42Model.ThermalEffCurve.value(state, Pnetss, MdotCW, TcwIn)
            ThermEff = max(0.0, ThermEff)
            Qgenss = ThermEff * Qgross
            MdotFuel = Qgross / (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0) * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
            var ConstrainedIncreasingNdot: Bool = False
            var ConstrainedDecreasingNdot: Bool = False
            var MdotFuelAllowed: Float64 = 0.0
            GeneratorDynamicsManager.ManageGeneratorFuelFlow(state, self.DynamicsControlID, MdotFuel, MdotFuelAllowed, ConstrainedIncreasingNdot, ConstrainedDecreasingNdot)
            if ConstrainedIncreasingNdot or ConstrainedDecreasingNdot:
                MdotFuel = MdotFuelAllowed
                NdotFuel = MdotFuel / state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                Qgross = NdotFuel * (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)
                for i in range(1, 21):
                    Pnetss = Qgross * ElecEff
                    if self.A42Model.InternalFlowControl:
                        MdotCW = GeneratorDynamicsManager.FuncDetermineCWMdotForInternalFlowControl(state, self.DynamicsControlID, Pnetss, TcwIn)
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
        elif CurrentOpMode == DataGenerators.OperatingMode.CoolDown:
            Pnetss = 0.0
            Pstandby = 0.0
            Pcooler = self.A42Model.PcoolDown
            TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
            MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
            if self.A42Model.InternalFlowControl:
                MdotCW = GeneratorDynamicsManager.FuncDetermineCWMdotForInternalFlowControl(state, self.DynamicsControlID, Pnetss, TcwIn)
            NdotFuel = 0.0
            MdotFuel = 0.0
            MdotAir = 0.0
            ElecEff = 0.0
            ThermEff = 0.0
            Qgross = 0.0
            Qgenss = 0.0
        else:

        for i in range(1, 21):
            if (self.A42Model.WarmUpByEngineTemp) and (CurrentOpMode == DataGenerators.OperatingMode.WarmUp):
                var Pmax: Float64 = self.A42Model.MaxElecPower
                TcwIn = state.dataLoopNodes.Node[self.PlantInletNodeID].Temp
                MdotCW = state.dataLoopNodes.Node[self.PlantInletNodeID].MassFlowRate
                ElecEff = self.A42Model.ElecEffCurve.value(state, Pmax, MdotCW, TcwIn)
                ElecEff = max(0.0, ElecEff)
                if ElecEff > 0.0:
                    Qgross = Pmax / ElecEff
                else:
                    Qgross = 0.0
                NdotFuel = Qgross / (state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000.0 * 1000.0)
                var MdotFuelMax: Float64 = NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
                var MdotFuelWarmup: Float64
                if Teng > thisAmbientTemp:
                    MdotFuelWarmup = MdotFuelMax + self.A42Model.kf * MdotFuelMax * ((self.A42Model.TnomEngOp - thisAmbientTemp) / (Teng - thisAmbientTemp))
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
            var dt: Float64 = state.dataHVACGlobal.TimeStepSysSec
            Teng = FuncDetermineEngineTemp(TcwOut, self.A42Model.MCeng, self.A42Model.UAhx, self.A42Model.UAskin, thisAmbientTemp, Qgenss, self.A42Model.TengLast, dt)
            var Cp: Float64 = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, TcwIn, RoutineName)
            TcwOut = FuncDetermineCoolantWaterExitTemp(TcwIn, self.A42Model.MCcw, self.A42Model.UAhx, MdotCW * Cp, Teng, self.A42Model.TempCWOutLast, dt)
            var EnergyBalOK: Bool = CheckMicroCHPThermalBalance(self.A42Model.MaxElecPower,
                                                                 TcwIn,
                                                                 TcwOut,
                                                                 Teng,
                                                                 thisAmbientTemp,
                                                                 self.A42Model.UAhx,
                                                                 self.A42Model.UAskin,
                                                                 Qgenss,
                                                                 self.A42Model.MCeng,
                                                                 self.A42Model.MCcw,
                                                                 MdotCW * Cp)
            if EnergyBalOK and (i > 4):
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

    def CalcUpdateHeatRecovery(inout self, inout state: EnergyPlusData):
        var RoutineName: String = "CalcUpdateHeatRecovery"
        PlantUtilities.SafeCopyPlantNode(state, self.PlantInletNodeID, self.PlantOutletNodeID)
        state.dataLoopNodes.Node[self.PlantOutletNodeID].Temp = self.A42Model.TcwOut
        var Cp: Float64 = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, self.A42Model.TcwIn, RoutineName)
        state.dataLoopNodes.Node[self.PlantOutletNodeID].Enthalpy = self.A42Model.TcwOut * Cp

    def UpdateMicroCHPGeneratorRecords(inout self, inout state: EnergyPlusData):
        var RoutineName: String = "UpdateMicroCHPGeneratorRecords"
        self.A42Model.ACPowerGen = self.A42Model.Pnet
        self.A42Model.ACEnergyGen = self.A42Model.Pnet * state.dataHVACGlobal.TimeStepSysSec
        self.A42Model.QdotHX = self.A42Model.UAhx * (self.A42Model.Teng - self.A42Model.TcwOut)
        var Cp: Float64 = self.CWPlantLoc.loop.glycol.getSpecificHeat(state, self.A42Model.TcwIn, RoutineName)
        self.A42Model.QdotHR = self.PlantMassFlowRate * Cp * (self.A42Model.TcwOut - self.A42Model.TcwIn)
        self.A42Model.TotalHeatEnergyRec = self.A42Model.QdotHR * state.dataHVACGlobal.TimeStepSysSec
        self.A42Model.HeatRecInletTemp = self.A42Model.TcwIn
        self.A42Model.HeatRecOutletTemp = self.A42Model.TcwOut
        self.A42Model.FuelCompressPower = state.dataGenerator.FuelSupply[self.FuelSupplyID].PfuelCompEl
        self.A42Model.FuelCompressEnergy = state.dataGenerator.FuelSupply[self.FuelSupplyID].PfuelCompEl * state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        self.A42Model.FuelCompressSkinLoss = state.dataGenerator.FuelSupply[self.FuelSupplyID].QskinLoss
        self.A42Model.FuelEnergyHHV = self.A42Model.NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].HHV * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec * state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        self.A42Model.FuelEnergyUseRateHHV = self.A42Model.NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].HHV * state.dataGenerator.FuelSupply[self.FuelSupplyID].KmolPerSecToKgPerSec
        self.A42Model.FuelEnergyLHV = self.A42Model.NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000000.0 * state.dataHVACGlobal.TimeStepSysSec
        self.A42Model.FuelEnergyUseRateLHV = self.A42Model.NdotFuel * state.dataGenerator.FuelSupply[self.FuelSupplyID].LHV * 1000000.0
        self.A42Model.SkinLossPower = self.A42Model.QdotConvZone + self.A42Model.QdotRadZone
        self.A42Model.SkinLossEnergy = (self.A42Model.QdotConvZone + self.A42Model.QdotRadZone) * state.dataHVACGlobal.TimeStepSysSec
        self.A42Model.SkinLossConvect = self.A42Model.QdotConvZone
        self.A42Model.SkinLossRadiat = self.A42Model.QdotRadZone
        if self.AirInletNodeID > 0:
            state.dataLoopNodes.Node[self.AirInletNodeID].MassFlowRate = self.A42Model.MdotAir
        if self.AirOutletNodeID > 0:
            state.dataLoopNodes.Node[self.AirOutletNodeID].MassFlowRate = self.A42Model.MdotAir
            state.dataLoopNodes.Node[self.AirOutletNodeID].Temp = self.A42Model.Teng

    def oneTimeInit(inout self, inout state: EnergyPlusData):
        if self.myFlag:
            self.setupOutputVars(state)
            self.myFlag = False
        if self.MyPlantScanFlag:
            if state.dataPlnt.PlantLoop.is_allocated():
                var errFlag: Bool = False
                PlantUtilities.ScanPlantLoopsForObject(state, self.Name, DataPlant.PlantEquipmentType.Generator_MicroCHP, self.CWPlantLoc, errFlag, _, _, _, _, _)
                if errFlag:
                    ShowFatalError(state, "InitMicroCHPNoNormalizeGenerators: Program terminated for previous conditions.")
                if not self.A42Model.InternalFlowControl:
                    if self.CWPlantLoc.loopSideNum == DataPlant.LoopSideLocation.Supply:
                        DataPlant.CompData.getPlantComponent(state, self.CWPlantLoc).FlowPriority = DataPlant.LoopFlowStatus.TakesWhatGets
                self.MyPlantScanFlag = False

    @staticmethod
    def factory(inout state: EnergyPlusData, objectName: String) -> PlantComponent:
        if state.dataCHPElectGen.getMicroCHPInputFlag:
            GetMicroCHPGeneratorInput(state)
            state.dataCHPElectGen.getMicroCHPInputFlag = False
        for thisMCHP in state.dataCHPElectGen.MicroCHP:
            if thisMCHP.Name == objectName:
                return thisMCHP
        ShowFatalError(state, "LocalMicroCHPGenFactory: Error getting inputs for micro-CHP gen named: " + objectName)
        return None

def GetMicroCHPGeneratorInput(inout state: EnergyPlusData):
    var routineName: String = "GetMicroCHPGeneratorInput"
    var AlphArray: Array1D_string = Array1D_string(25)
    var NumArray: Array1D_Real64 = Array1D_Real64(200)
    if state.dataCHPElectGen.MyOneTimeFlag:
        var NumAlphas: Int = 0
        var NumNums: Int = 0
        var IOStat: Int = 0
        var ErrorsFound: Bool = False
        var s_ipsc = state.dataIPShortCut
        GeneratorFuelSupply.GetGeneratorFuelSupplyInput(state)
        s_ipsc.cCurrentModuleObject = "Generator:MicroCHP:NonNormalizedParameters"
        state.dataCHPElectGen.NumMicroCHPParams = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
        if state.dataCHPElectGen.NumMicroCHPParams <= 0:
            ShowSevereError(state, "No " + s_ipsc.cCurrentModuleObject + " equipment specified in input file")
            ErrorsFound = True
        state.dataCHPElectGen.MicroCHPParamInput.allocate(state.dataCHPElectGen.NumMicroCHPParams)
        for CHPParamNum in range(1, state.dataCHPElectGen.NumMicroCHPParams + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                     s_ipsc.cCurrentModuleObject,
                                                                     CHPParamNum,
                                                                     AlphArray,
                                                                     NumAlphas,
                                                                     NumArray,
                                                                     NumNums,
                                                                     IOStat,
                                                                     _,
                                                                     s_ipsc.lAlphaFieldBlanks,
                                                                     s_ipsc.cAlphaFieldNames,
                                                                     s_ipsc.cNumericFieldNames)
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, AlphArray[1])
            var microCHPParams = state.dataCHPElectGen.MicroCHPParamInput[CHPParamNum]
            microCHPParams.Name = AlphArray[1]
            microCHPParams.MaxElecPower = NumArray[1]
            microCHPParams.MinElecPower = NumArray[2]
            microCHPParams.MinWaterMdot = NumArray[3]
            microCHPParams.MaxWaterTemp = NumArray[4]
            if s_ipsc.lAlphaFieldBlanks[2]:
                ShowSevereEmptyField(state, eoh, s_ipsc.cAlphaFieldNames[2])
                ErrorsFound = True
            elif (microCHPParams.ElecEffCurve = Curve.GetCurve(state, AlphArray[2])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[2], AlphArray[2])
                ErrorsFound = True
            if s_ipsc.lAlphaFieldBlanks[3]:
                ShowSevereEmptyField(state, eoh, s_ipsc.cAlphaFieldNames[3])
                ErrorsFound = True
            elif (microCHPParams.ThermalEffCurve = Curve.GetCurve(state, AlphArray[3])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[3], AlphArray[3])
                ErrorsFound = True
            if Util.SameString(AlphArray[4], "InternalControl"):
                microCHPParams.InternalFlowControl = True
                microCHPParams.PlantFlowControl = False
            if (not Util.SameString(AlphArray[4], "InternalControl")) and (not Util.SameString(AlphArray[4], "PlantControl")):
                ShowSevereError(state, "Invalid, " + s_ipsc.cAlphaFieldNames[4] + " = " + AlphArray[4])
                ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                ErrorsFound = True
            if microCHPParams.InternalFlowControl:
                if s_ipsc.lAlphaFieldBlanks[5]:
                    ShowSevereEmptyField(state, eoh, s_ipsc.cAlphaFieldNames[5])
                    ErrorsFound = True
                elif (microCHPParams.WaterFlowCurve = Curve.GetCurve(state, AlphArray[5])) == None:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[5], AlphArray[5])
                    ErrorsFound = True
            if s_ipsc.lAlphaFieldBlanks[6]:
                ShowSevereEmptyField(state, eoh, s_ipsc.cAlphaFieldNames[6])
                ErrorsFound = True
            elif (microCHPParams.AirFlowCurve = Curve.GetCurve(state, AlphArray[6])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[6], AlphArray[6])
                ErrorsFound = True
            microCHPParams.DeltaPelMax = NumArray[5]
            microCHPParams.DeltaFuelMdotMax = NumArray[6]
            microCHPParams.UAhx = NumArray[7]
            microCHPParams.UAskin = NumArray[8]
            microCHPParams.RadiativeFraction = NumArray[9]
            microCHPParams.MCeng = NumArray[10]
            if microCHPParams.MCeng <= 0.0:
                ShowSevereError(state, "Invalid, " + s_ipsc.cNumericFieldNames[10] + " = " + str(NumArray[10]))
                ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                ShowContinueError(state, "Thermal mass must be greater than zero")
                ErrorsFound = True
            microCHPParams.MCcw = NumArray[11]
            if microCHPParams.MCcw <= 0.0:
                ShowSevereError(state, "Invalid, " + s_ipsc.cNumericFieldNames[11] + " = " + str(NumArray[11]))
                ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                ShowContinueError(state, "Thermal mass must be greater than zero")
                ErrorsFound = True
            microCHPParams.Pstandby = NumArray[12]
            if Util.SameString(AlphArray[7], "TimeDelay"):
                microCHPParams.WarmUpByTimeDelay = True
                microCHPParams.WarmUpByEngineTemp = False
            if (not Util.SameString(AlphArray[7], "NominalEngineTemperature")) and (not Util.SameString(AlphArray[7], "TimeDelay")):
                ShowSevereError(state, "Invalid, " + s_ipsc.cAlphaFieldNames[7] + " = " + AlphArray[7])
                ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                ErrorsFound = True
            microCHPParams.kf = NumArray[13]
            microCHPParams.TnomEngOp = NumArray[14]
            microCHPParams.kp = NumArray[15]
            microCHPParams.Rfuelwarmup = NumArray[16]
            microCHPParams.WarmUpDelay = NumArray[17]
            microCHPParams.PcoolDown = NumArray[18]
            microCHPParams.CoolDownDelay = NumArray[19]
            if Util.SameString(AlphArray[8], "MandatoryCoolDown"):
                microCHPParams.MandatoryFullCoolDown = True
                microCHPParams.WarmRestartOkay = False
            if (not Util.SameString(AlphArray[8], "MandatoryCoolDown")) and (not Util.SameString(AlphArray[8], "OptionalCoolDown")):
                ShowSevereError(state, "Invalid, " + s_ipsc.cAlphaFieldNames[8] + " = " + AlphArray[8])
                ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                ErrorsFound = True
        s_ipsc.cCurrentModuleObject = "Generator:MicroCHP"
        state.dataCHPElectGen.NumMicroCHPs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
        if state.dataCHPElectGen.NumMicroCHPs <= 0:
            ShowSevereError(state, "No " + s_ipsc.cCurrentModuleObject + " equipment specified in input file")
            ErrorsFound = True
        if not state.dataCHPElectGen.MicroCHP.is_allocated():
            state.dataCHPElectGen.MicroCHP.allocate(state.dataCHPElectGen.NumMicroCHPs)
        for GeneratorNum in range(1, state.dataCHPElectGen.NumMicroCHPs + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                     s_ipsc.cCurrentModuleObject,
                                                                     GeneratorNum,
                                                                     AlphArray,
                                                                     NumAlphas,
                                                                     NumArray,
                                                                     NumNums,
                                                                     IOStat,
                                                                     _,
                                                                     s_ipsc.lAlphaFieldBlanks,
                                                                     s_ipsc.cAlphaFieldNames,
                                                                     s_ipsc.cNumericFieldNames)
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, AlphArray[1])
            var microCHP = state.dataCHPElectGen.MicroCHP[GeneratorNum]
            microCHP.DynamicsControlID = GeneratorNum
            microCHP.Name = AlphArray[1]
            microCHP.ParamObjName = AlphArray[2]
            var thisParamID: Int = Util.FindItemInList(AlphArray[2], state.dataCHPElectGen.MicroCHPParamInput)
            if thisParamID != 0:
                microCHP.A42Model = state.dataCHPElectGen.MicroCHPParamInput[thisParamID]
            else:
                ShowSevereError(state, "Invalid, " + s_ipsc.cAlphaFieldNames[2] + " = " + AlphArray[2])
                ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                ErrorsFound = True
            if not s_ipsc.lAlphaFieldBlanks[3]:
                microCHP.ZoneName = AlphArray[3]
                microCHP.ZoneID = Util.FindItemInList(microCHP.ZoneName, state.dataHeatBal.Zone)
                if microCHP.ZoneID == 0:
                    ShowSevereError(state, "Invalid, " + s_ipsc.cAlphaFieldNames[3] + " = " + AlphArray[3])
                    ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                    ErrorsFound = True
            else:
                microCHP.ZoneID = 0
            microCHP.PlantInletNodeName = AlphArray[4]
            microCHP.PlantOutletNodeName = AlphArray[5]
            microCHP.PlantInletNodeID = Node.GetOnlySingleNode(state,
                                                                AlphArray[4],
                                                                ErrorsFound,
                                                                Node.ConnectionObjectType.GeneratorMicroCHP,
                                                                AlphArray[1],
                                                                Node.FluidType.Water,
                                                                Node.ConnectionType.Inlet,
                                                                Node.CompFluidStream.Primary,
                                                                Node.ObjectIsNotParent)
            microCHP.PlantOutletNodeID = Node.GetOnlySingleNode(state,
                                                                 AlphArray[5],
                                                                 ErrorsFound,
                                                                 Node.ConnectionObjectType.GeneratorMicroCHP,
                                                                 AlphArray[1],
                                                                 Node.FluidType.Water,
                                                                 Node.ConnectionType.Outlet,
                                                                 Node.CompFluidStream.Primary,
                                                                 Node.ObjectIsNotParent)
            Node.TestCompSet(state, s_ipsc.cCurrentModuleObject, AlphArray[1], AlphArray[4], AlphArray[5], "Heat Recovery Nodes")
            microCHP.AirInletNodeName = AlphArray[6]
            microCHP.AirInletNodeID = Node.GetOnlySingleNode(state,
                                                              AlphArray[6],
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.GeneratorMicroCHP,
                                                              AlphArray[1],
                                                              Node.FluidType.Air,
                                                              Node.ConnectionType.Inlet,
                                                              Node.CompFluidStream.Secondary,
                                                              Node.ObjectIsNotParent)
            microCHP.AirOutletNodeName = AlphArray[7]
            microCHP.AirOutletNodeID = Node.GetOnlySingleNode(state,
                                                               AlphArray[7],
                                                               ErrorsFound,
                                                               Node.ConnectionObjectType.GeneratorMicroCHP,
                                                               AlphArray[1],
                                                               Node.FluidType.Air,
                                                               Node.ConnectionType.Outlet,
                                                               Node.CompFluidStream.Secondary,
                                                               Node.ObjectIsNotParent)
            microCHP.FuelSupplyID = Util.FindItemInList(AlphArray[8], state.dataGenerator.FuelSupply)
            if microCHP.FuelSupplyID == 0:
                ShowSevereError(state, "Invalid, " + s_ipsc.cAlphaFieldNames[8] + " = " + AlphArray[8])
                ShowContinueError(state, "Entered in " + s_ipsc.cCurrentModuleObject + "=" + AlphArray[1])
                ErrorsFound = True
            if s_ipsc.lAlphaFieldBlanks[9]:
                microCHP.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (microCHP.availSched = Sched.GetSchedule(state, AlphArray[9])) == None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[9], AlphArray[9])
                ErrorsFound = True
            microCHP.A42Model.TengLast = 20.0
            microCHP.A42Model.TempCWOutLast = 20.0
        if ErrorsFound:
            ShowFatalError(state, "Errors found in processing input for " + s_ipsc.cCurrentModuleObject)
        for GeneratorNum in range(1, state.dataCHPElectGen.NumMicroCHPs + 1):

        state.dataCHPElectGen.MyOneTimeFlag = False

def FuncDetermineEngineTemp(TcwOut: Float64,
                           MCeng: Float64,
                           UAHX: Float64,
                           UAskin: Float64,
                           Troom: Float64,
                           Qgenss: Float64,
                           TengLast: Float64,
                           time: Float64) -> Float64:
    var a: Float64 = ((UAHX * TcwOut / MCeng) + (UAskin * Troom / MCeng) + (Qgenss / MCeng))
    var b: Float64 = ((-1.0 * UAHX / MCeng) + (-1.0 * UAskin / MCeng))
    return (TengLast + a / b) * exp(b * time) - a / b

def FuncDetermineCoolantWaterExitTemp(TcwIn: Float64,
                                     MCcw: Float64,
                                     UAHX: Float64,
                                     MdotCpcw: Float64,
                                     Teng: Float64,
                                     TcwoutLast: Float64,
                                     time: Float64) -> Float64:
    var a: Float64 =
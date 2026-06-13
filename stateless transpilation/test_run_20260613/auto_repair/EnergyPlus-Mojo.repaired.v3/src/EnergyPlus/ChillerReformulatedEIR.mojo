from cassert import assert
from cmath import sqrt, abs, min, max, fabs, pow
from string import String, StringRef
from ObjexxFCL.Fmath import *
from .Autosizing.Base import BaseSizer
from BranchNodeConnections import *
from ChillerReformulatedEIR import ReformulatedEIRChillerSpecs
from CurveManager import Curve
from .Data.EnergyPlusData import EnergyPlusData
from .DataBranchAirLoopPlant import DataBranchAirLoopPlant
from DataEnvironment import DataEnvironment
from DataHVACGlobals import DataHVACGlobals
from .DataIPShortCuts import DataIPShortCuts
from .DataLoopNode import DataLoopNode, Node
from DataSizing import DataSizing
from EMSManager import EMSManager
from FaultsManager import FaultsManager
from FluidProperties import FluidProperties
from General import General
from GlobalNames import GlobalNames
from .InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor
from OutputReportPredefined import OutputReportPredefined
from .Plant.DataPlant import DataPlant, PlantLocation, PlantComponent
from .Plant.PlantLocation import PlantLocation
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from ScheduleManager import Sched
from StandardRatings import StandardRatings
from UtilityRoutines import *
namespace EnergyPlus.ChillerReformulatedEIR:
    struct ReformulatedEIRChillerSpecs(PlantComponent):
        var Name: String  # User identifier
        var TypeNum: Int32  # plant loop type identifier
        var CAPFTName: String  # CAPFT curve name
        var EIRFTName: String  # EIRFT curve name
        var EIRFPLRName: String  # EIRPLR curve name
        var CondenserType: DataPlant.CondenserType
        var PartLoadCurveType: PLR
        var RefCap: Float64
        var RefCapWasAutoSized: Bool
        var RefCOP: Float64
        var FlowMode: DataPlant.FlowMode
        var CondenserFlowControl: DataPlant.CondenserFlowControl
        var ModulatedFlowSetToLoop: Bool
        var ModulatedFlowErrDone: Bool
        var EvapVolFlowRate: Float64
        var EvapVolFlowRateWasAutoSized: Bool
        var EvapMassFlowRateMax: Float64
        var CondVolFlowRate: Float64
        var CondVolFlowRateWasAutoSized: Bool
        var CondMassFlowRateMax: Float64
        var CompPowerToCondenserFrac: Float64
        var EvapInletNodeNum: Int32
        var EvapOutletNodeNum: Int32
        var CondInletNodeNum: Int32
        var CondOutletNodeNum: Int32
        var MinPartLoadRat: Float64
        var MaxPartLoadRat: Float64
        var OptPartLoadRat: Float64
        var MinUnloadRat: Float64
        var TempRefCondIn: Float64
        var TempRefCondOut: Float64
        var TempRefEvapOut: Float64
        var TempLowLimitEvapOut: Float64
        var DesignHeatRecVolFlowRate: Float64
        var DesignHeatRecVolFlowRateWasAutoSized: Bool
        var DesignHeatRecMassFlowRate: Float64
        var SizFac: Float64
        var HeatRecActive: Bool
        var HeatRecInletNodeNum: Int32
        var HeatRecOutletNodeNum: Int32
        var HeatRecCapacityFraction: Float64
        var HeatRecMaxCapacityLimit: Float64
        var HeatRecSetPointNodeNum: Int32
        var heatRecInletLimitSched: Sched.Schedule
        var ChillerCapFTIndex: Int32
        var ChillerEIRFTIndex: Int32
        var ChillerEIRFPLRIndex: Int32
        var ChillerCapFTError: Int32
        var ChillerCapFTErrorIndex: Int32
        var ChillerEIRFTError: Int32
        var ChillerEIRFTErrorIndex: Int32
        var ChillerEIRFPLRError: Int32
        var ChillerEIRFPLRErrorIndex: Int32
        var ChillerCAPFTXTempMin: Float64
        var ChillerCAPFTXTempMax: Float64
        var ChillerCAPFTYTempMin: Float64
        var ChillerCAPFTYTempMax: Float64
        var ChillerEIRFTXTempMin: Float64
        var ChillerEIRFTXTempMax: Float64
        var ChillerEIRFTYTempMin: Float64
        var ChillerEIRFTYTempMax: Float64
        var ChillerEIRFPLRTempMin: Float64
        var ChillerEIRFPLRTempMax: Float64
        var ChillerEIRFPLRPLRMin: Float64
        var ChillerEIRFPLRPLRMax: Float64
        var ChillerLiftNomMin: Float64
        var ChillerLiftNomMax: Float64
        var ChillerTdevNomMin: Float64
        var ChillerTdevNomMax: Float64
        var CAPFTXIter: Int32
        var CAPFTXIterIndex: Int32
        var CAPFTYIter: Int32
        var CAPFTYIterIndex: Int32
        var EIRFTXIter: Int32
        var EIRFTXIterIndex: Int32
        var EIRFTYIter: Int32
        var EIRFTYIterIndex: Int32
        var EIRFPLRTIter: Int32
        var EIRFPLRTIterIndex: Int32
        var EIRFPLRPLRIter: Int32
        var EIRFPLRPLRIterIndex: Int32
        var FaultyChillerSWTFlag: Bool
        var FaultyChillerSWTIndex: Int32
        var FaultyChillerSWTOffset: Float64
        var IterLimitExceededNum: Int32
        var IterLimitErrIndex: Int32
        var IterFailed: Int32
        var IterFailedIndex: Int32
        var DeltaTErrCount: Int32
        var DeltaTErrCountIndex: Int32
        var CWPlantLoc: PlantLocation
        var CDPlantLoc: PlantLocation
        var HRPlantLoc: PlantLocation
        var CondMassFlowIndex: Int32
        var PossibleSubcooling: Bool
        var FaultyChillerFoulingFlag: Bool
        var FaultyChillerFoulingIndex: Int32
        var FaultyChillerFoulingFactor: Float64
        var EndUseSubcategory: String
        var MyEnvrnFlag: Bool
        var MyInitFlag: Bool
        var MySizeFlag: Bool
        var ChillerCondAvgTemp: Float64
        var ChillerFalseLoadRate: Float64
        var ChillerCyclingRatio: Float64
        var ChillerPartLoadRatio: Float64
        var ChillerEIRFPLR: Float64
        var ChillerEIRFT: Float64
        var ChillerCapFT: Float64
        var HeatRecOutletTemp: Float64
        var QHeatRecovery: Float64
        var QCondenser: Float64
        var QEvaporator: Float64
        var Power: Float64
        var EvapOutletTemp: Float64
        var CondOutletTemp: Float64
        var EvapMassFlowRate: Float64
        var CondMassFlowRate: Float64
        var ChillerFalseLoad: Float64
        var Energy: Float64
        var EvapEnergy: Float64
        var CondEnergy: Float64
        var CondInletTemp: Float64
        var EvapInletTemp: Float64
        var ActualCOP: Float64
        var EnergyHeatRecovery: Float64
        var HeatRecInletTemp: Float64
        var HeatRecMassFlow: Float64
        var ChillerCondLoopFlowFLoopPLRIndex: Int32
        var CondDT: Int32
        var condDTSched: Sched.Schedule
        var MinCondFlowRatio: Float64
        var EquipFlowCtrl: DataBranchAirLoopPlant.ControlType
        var VSBranchPumpMinLimitMassFlowCond: Float64
        var VSBranchPumpFoundCond: Bool
        var VSLoopPumpFoundCond: Bool
        var thermosiphonTempCurveIndex: Int32
        var thermosiphonMinTempDiff: Float64
        var thermosiphonStatus: Int32
        def __init__(inout self):
            self.Name = ""
            self.TypeNum = 0
            self.CAPFTName = ""
            self.EIRFTName = ""
            self.EIRFPLRName = ""
            self.CondenserType = DataPlant.CondenserType.Invalid
            self.PartLoadCurveType = PLR.Invalid
            self.RefCap = 0.0
            self.RefCapWasAutoSized = False
            self.RefCOP = 0.0
            self.FlowMode = DataPlant.FlowMode.Invalid
            self.CondenserFlowControl = DataPlant.CondenserFlowControl.Invalid
            self.ModulatedFlowSetToLoop = False
            self.ModulatedFlowErrDone = False
            self.EvapVolFlowRate = 0.0
            self.EvapVolFlowRateWasAutoSized = False
            self.EvapMassFlowRateMax = 0.0
            self.CondVolFlowRate = 0.0
            self.CondVolFlowRateWasAutoSized = False
            self.CondMassFlowRateMax = 0.0
            self.CompPowerToCondenserFrac = 0.0
            self.EvapInletNodeNum = 0
            self.EvapOutletNodeNum = 0
            self.CondInletNodeNum = 0
            self.CondOutletNodeNum = 0
            self.MinPartLoadRat = 0.0
            self.MaxPartLoadRat = 0.0
            self.OptPartLoadRat = 0.0
            self.MinUnloadRat = 0.0
            self.TempRefCondIn = 0.0
            self.TempRefCondOut = 0.0
            self.TempRefEvapOut = 0.0
            self.TempLowLimitEvapOut = 0.0
            self.DesignHeatRecVolFlowRate = 0.0
            self.DesignHeatRecVolFlowRateWasAutoSized = False
            self.DesignHeatRecMassFlowRate = 0.0
            self.SizFac = 0.0
            self.HeatRecActive = False
            self.HeatRecInletNodeNum = 0
            self.HeatRecOutletNodeNum = 0
            self.HeatRecCapacityFraction = 0.0
            self.HeatRecMaxCapacityLimit = 0.0
            self.HeatRecSetPointNodeNum = 0
            self.heatRecInletLimitSched = Sched.Schedule()  # assume null
            self.ChillerCapFTIndex = 0
            self.ChillerEIRFTIndex = 0
            self.ChillerEIRFPLRIndex = 0
            self.ChillerCapFTError = 0
            self.ChillerCapFTErrorIndex = 0
            self.ChillerEIRFTError = 0
            self.ChillerEIRFTErrorIndex = 0
            self.ChillerEIRFPLRError = 0
            self.ChillerEIRFPLRErrorIndex = 0
            self.ChillerCAPFTXTempMin = 0.0
            self.ChillerCAPFTXTempMax = 0.0
            self.ChillerCAPFTYTempMin = 0.0
            self.ChillerCAPFTYTempMax = 0.0
            self.ChillerEIRFTXTempMin = 0.0
            self.ChillerEIRFTXTempMax = 0.0
            self.ChillerEIRFTYTempMin = 0.0
            self.ChillerEIRFTYTempMax = 0.0
            self.ChillerEIRFPLRTempMin = 0.0
            self.ChillerEIRFPLRTempMax = 0.0
            self.ChillerEIRFPLRPLRMin = 0.0
            self.ChillerEIRFPLRPLRMax = 0.0
            self.ChillerLiftNomMin = 0.0
            self.ChillerLiftNomMax = 10.0
            self.ChillerTdevNomMin = 0.0
            self.ChillerTdevNomMax = 10.0
            self.CAPFTXIter = 0
            self.CAPFTXIterIndex = 0
            self.CAPFTYIter = 0
            self.CAPFTYIterIndex = 0
            self.EIRFTXIter = 0
            self.EIRFTXIterIndex = 0
            self.EIRFTYIter = 0
            self.EIRFTYIterIndex = 0
            self.EIRFPLRTIter = 0
            self.EIRFPLRTIterIndex = 0
            self.EIRFPLRPLRIter = 0
            self.EIRFPLRPLRIterIndex = 0
            self.FaultyChillerSWTFlag = False
            self.FaultyChillerSWTIndex = 0
            self.FaultyChillerSWTOffset = 0.0
            self.IterLimitExceededNum = 0
            self.IterLimitErrIndex = 0
            self.IterFailed = 0
            self.IterFailedIndex = 0
            self.DeltaTErrCount = 0
            self.DeltaTErrCountIndex = 0
            self.CWPlantLoc = PlantLocation()
            self.CDPlantLoc = PlantLocation()
            self.HRPlantLoc = PlantLocation()
            self.CondMassFlowIndex = 0
            self.PossibleSubcooling = False
            self.FaultyChillerFoulingFlag = False
            self.FaultyChillerFoulingIndex = 0
            self.FaultyChillerFoulingFactor = 1.0
            self.EndUseSubcategory = ""
            self.MyEnvrnFlag = True
            self.MyInitFlag = True
            self.MySizeFlag = True
            self.ChillerCondAvgTemp = 0.0
            self.ChillerFalseLoadRate = 0.0
            self.ChillerCyclingRatio = 0.0
            self.ChillerPartLoadRatio = 0.0
            self.ChillerEIRFPLR = 0.0
            self.ChillerEIRFT = 0.0
            self.ChillerCapFT = 0.0
            self.HeatRecOutletTemp = 0.0
            self.QHeatRecovery = 0.0
            self.QCondenser = 0.0
            self.QEvaporator = 0.0
            self.Power = 0.0
            self.EvapOutletTemp = 0.0
            self.CondOutletTemp = 0.0
            self.EvapMassFlowRate = 0.0
            self.CondMassFlowRate = 0.0
            self.ChillerFalseLoad = 0.0
            self.Energy = 0.0
            self.EvapEnergy = 0.0
            self.CondEnergy = 0.0
            self.CondInletTemp = 0.0
            self.EvapInletTemp = 0.0
            self.ActualCOP = 0.0
            self.EnergyHeatRecovery = 0.0
            self.HeatRecInletTemp = 0.0
            self.HeatRecMassFlow = 0.0
            self.ChillerCondLoopFlowFLoopPLRIndex = 0
            self.CondDT = 0
            self.condDTSched = Sched.Schedule()
            self.MinCondFlowRatio = 0.2
            self.EquipFlowCtrl = DataBranchAirLoopPlant.ControlType.Invalid
            self.VSBranchPumpMinLimitMassFlowCond = 0.0
            self.VSBranchPumpFoundCond = False
            self.VSLoopPumpFoundCond = False
            self.thermosiphonTempCurveIndex = 0
            self.thermosiphonMinTempDiff = 0.0
            self.thermosiphonStatus = 0
        @staticmethod
        def factory(state: Ref[EnergyPlusData], objectName: StringRef) -> Ref[ReformulatedEIRChillerSpecs]:
            if state.dataChillerReformulatedEIR.GetInputREIR:
                GetElecReformEIRChillerInput(state[])
                state.dataChillerReformulatedEIR.GetInputREIR = False
            var thisObj = state.dataChillerReformulatedEIR.ElecReformEIRChiller.find(lambda myObj: myObj.Name == objectName)
            if thisObj != -1:  # In Mojo we need to handle not found; assume find returns index or pointer

            for i in range(len(state.dataChillerReformulatedEIR.ElecReformEIRChiller)):
                if state.dataChillerReformulatedEIR.ElecReformEIRChiller[i].Name == objectName:
                    return Ref[ReformulatedEIRChillerSpecs](state.dataChillerReformulatedEIR.ElecReformEIRChiller[i])
            ShowFatalError(state[], "LocalReformulatedElectEIRChillerFactory: Error getting inputs for object named: " + objectName)
            return Ref[ReformulatedEIRChillerSpecs](state.dataChillerReformulatedEIR.ElecReformEIRChiller[0]) # unreachable
        def getDesignCapacities(
            inout self, state: Ref[EnergyPlusData], calledFromLocation: PlantLocation, ref MaxLoad: Float64, ref MinLoad: Float64, ref OptLoad: Float64
        ):
            if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
                MinLoad = self.RefCap * self.MinPartLoadRat
                MaxLoad = self.RefCap * self.MaxPartLoadRat
                OptLoad = self.RefCap * self.OptPartLoadRat
            else:
                MinLoad = 0.0
                MaxLoad = 0.0
                OptLoad = 0.0
        def getDesignTemperatures(inout self, ref TempDesCondIn: Float64, ref TempDesEvapOut: Float64):
            TempDesEvapOut = self.TempRefEvapOut
            TempDesCondIn = self.TempRefCondIn
        def getSizingFactor(inout self, ref sizFac: Float64):
            sizFac = self.SizFac
        def onInitLoopEquip(inout self, state: Ref[EnergyPlusData], calledFromLocation: PlantLocation):
            var runFlag: Bool = True
            var myLoad: Float64 = 0.0
            self.initialize(state[], runFlag, myLoad)
            if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
                self.size(state[])
        def simulate(
            inout self, state: Ref[EnergyPlusData], calledFromLocation: PlantLocation, FirstHVACIteration: Bool, ref CurLoad: Float64, RunFlag: Bool
        ):
            if calledFromLocation.loopNum == self.CWPlantLoc.loopNum:
                self.initialize(state[], RunFlag, CurLoad)
                self.control(state[], CurLoad, RunFlag, FirstHVACIteration)
                self.update(state[], CurLoad, RunFlag)
            elif calledFromLocation.loopNum == self.CDPlantLoc.loopNum:
                var LoopSide: DataPlant.LoopSideLocation = self.CDPlantLoc.loopSideNum
                PlantUtilities.UpdateChillerComponentCondenserSide(state[],
                                                                    calledFromLocation.loopNum,
                                                                    LoopSide,
                                                                    DataPlant.PlantEquipmentType.Chiller_ElectricReformEIR,
                                                                    self.CondInletNodeNum,
                                                                    self.CondOutletNodeNum,
                                                                    self.QCondenser,
                                                                    self.CondInletTemp,
                                                                    self.CondOutletTemp,
                                                                    self.CondMassFlowRate,
                                                                    FirstHVACIteration)
            elif calledFromLocation.loopNum == self.HRPlantLoc.loopNum:
                PlantUtilities.UpdateComponentHeatRecoverySide(state[],
                                                                self.HRPlantLoc.loopNum,
                                                                self.HRPlantLoc.loopSideNum,
                                                                DataPlant.PlantEquipmentType.Chiller_ElectricReformEIR,
                                                                self.HeatRecInletNodeNum,
                                                                self.HeatRecOutletNodeNum,
                                                                self.QHeatRecovery,
                                                                self.HeatRecInletTemp,
                                                                self.HeatRecOutletTemp,
                                                                self.HeatRecMassFlow,
                                                                FirstHVACIteration)
        def oneTimeInit(inout self, state: Ref[EnergyPlusData]):

        def initialize(inout self, state: Ref[EnergyPlusData], RunFlag: Bool, MyLoad: Float64):

        def setupOutputVars(inout self, state: Ref[EnergyPlusData]):

        def size(inout self, state: Ref[EnergyPlusData]):

        def control(inout self, state: Ref[EnergyPlusData], ref MyLoad: Float64, RunFlag: Bool, FirstIteration: Bool):

        def calculate(inout self, state: Ref[EnergyPlusData], ref MyLoad: Float64, RunFlag: Bool, FalsiCondOutTemp: Float64):

        def calcHeatRecovery(inout self, state: Ref[EnergyPlusData], ref QCond: Float64, CondMassFlow: Float64, condInletTemp: Float64, ref QHeatRec: Float64):

        def update(inout self, state: Ref[EnergyPlusData], MyLoad: Float64, RunFlag: Bool):

        def checkMinMaxCurveBoundaries(inout self, state: Ref[EnergyPlusData], FirstIteration: Bool):

        def thermosiphonDisabled(inout self, state: Ref[EnergyPlusData]) -> Bool:
            return True
    def GetElecReformEIRChillerInput(state: Ref[EnergyPlusData]):

    enum PLR:
        Invalid = -1
        LeavingCondenserWaterTemperature = 1
        Lift = 2
        Num = 3
struct ChillerReformulatedEIRData(BaseGlobalStruct):
    var GetInputREIR: Bool = True
    var ElecReformEIRChiller: List[ReformulatedEIRChillerSpecs]
    def __init__(inout self):
        self.ElecReformEIRChiller = List[ReformulatedEIRChillerSpecs]()
        self.init_constant_state(Ref[EnergyPlusData]())
    def init_constant_state(inout self, state: Ref[EnergyPlusData]):

    def init_state(inout self, state: Ref[EnergyPlusData]):

    def clear_state(inout self):
        self.__init__()
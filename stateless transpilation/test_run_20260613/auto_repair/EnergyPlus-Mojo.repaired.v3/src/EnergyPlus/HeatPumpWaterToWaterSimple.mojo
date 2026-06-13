from cmath import *
from format import format
from ...Autosizing.Base import BaseSizer
from ...BranchNodeConnections import *
from ...CurveManager import Curve
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataHVACGlobals import *
from ...DataIPShortCuts import *
from ...DataLoopNode import Node
from ...DataSizing import DataSizing
from ...FluidProperties import *
from ...General import *
from ...GlobalNames import GlobalNames
from ...HeatPumpWaterToWaterSimple import HeatPumpWaterToWaterSimpleData, GshpSpecs
from ...InputProcessing.InputProcessor import *
from ...NodeInputManager import GetOnlySingleNode
from ...OutputProcessor import OutputProcessor, SetupOutputVariable
from ...OutputReportPredefined import OutputReportPredefined
from ...Plant.DataPlant import DataPlant
from ...Plant.PlantLocation import PlantLocation
from ...PlantUtilities import PlantUtilities
from ...UtilityRoutines import *

namespace EnergyPlus::HeatPumpWaterToWaterSimple:

    var HPEqFitHeating: String = "HeatPump:WatertoWater:EquationFit:Heating"
    var HPEqFitHeatingUC: String = "HEATPUMP:WATERTOWATER:EQUATIONFIT:HEATING"
    var HPEqFitCooling: String = "HeatPump:WatertoWater:EquationFit:Cooling"
    var HPEqFitCoolingUC: String = "HEATPUMP:WATERTOWATER:EQUATIONFIT:COOLING"

    def GshpSpecs_factory(state: EnergyPlusData, wwhp_type: DataPlant.PlantEquipmentType, eir_wwhp_name: String) -> Optional[GshpSpecs]:
        if state.dataHPWaterToWaterSimple.GetInputFlag:
            GshpSpecs.GetWatertoWaterHPInput(state)
            state.dataHPWaterToWaterSimple.GetInputFlag = False
        var thisObj = None
        for i in range(len(state.dataHPWaterToWaterSimple.GSHP)):
            var myObj = state.dataHPWaterToWaterSimple.GSHP[i]
            if myObj.Name == eir_wwhp_name and myObj.WWHPType == wwhp_type:
                thisObj = Some(myObj)
                break
        if thisObj is not None:
            return thisObj
        ShowFatalError(state, format("EquationFit_WWHP factory: Error getting inputs for wwhp named: {}", eir_wwhp_name))
        return None

    def GshpSpecs_simulate(self: GshpSpecs, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, curLoad: Float64, RunFlag: Bool):
        if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFCooling:
            if calledFromLocation.loopNum == self.LoadPlantLoc.loopNum:
                self.InitWatertoWaterHP(state, self.WWHPType, self.Name, FirstHVACIteration, curLoad)
                self.CalcWatertoWaterHPCooling(state, curLoad)
                self.UpdateGSHPRecords(state)
            else if calledFromLocation.loopNum == self.SourcePlantLoc.loopNum:
                PlantUtilities.UpdateChillerComponentCondenserSide(state,
                                                                    self.SourcePlantLoc.loopNum,
                                                                    self.SourcePlantLoc.loopSideNum,
                                                                    DataPlant.PlantEquipmentType.HPWaterEFCooling,
                                                                    self.SourceSideInletNodeNum,
                                                                    self.SourceSideOutletNodeNum,
                                                                    self.reportQSource,
                                                                    self.reportSourceSideInletTemp,
                                                                    self.reportSourceSideOutletTemp,
                                                                    self.reportSourceSideMassFlowRate,
                                                                    FirstHVACIteration)
            else:
                ShowFatalError(state, format("SimHPWatertoWaterSimple:: Invalid loop connection {}, Requested Unit={}", HPEqFitCooling, self.Name))
        else if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFHeating:
            if calledFromLocation.loopNum == self.LoadPlantLoc.loopNum:
                self.InitWatertoWaterHP(state, self.WWHPType, self.Name, FirstHVACIteration, curLoad)
                self.CalcWatertoWaterHPHeating(state, curLoad)
                self.UpdateGSHPRecords(state)
            else if calledFromLocation.loopNum == self.SourcePlantLoc.loopNum:
                PlantUtilities.UpdateChillerComponentCondenserSide(state,
                                                                    self.SourcePlantLoc.loopNum,
                                                                    self.SourcePlantLoc.loopSideNum,
                                                                    DataPlant.PlantEquipmentType.HPWaterEFHeating,
                                                                    self.SourceSideInletNodeNum,
                                                                    self.SourceSideOutletNodeNum,
                                                                    -self.reportQSource,
                                                                    self.reportSourceSideInletTemp,
                                                                    self.reportSourceSideOutletTemp,
                                                                    self.reportSourceSideMassFlowRate,
                                                                    FirstHVACIteration)
            else:
                ShowFatalError(state, format("SimHPWatertoWaterSimple:: Invalid loop connection {}, Requested Unit={}", HPEqFitCooling, self.Name))
        else:
            ShowFatalError(state, "SimHPWatertoWaterSimple: Module called with incorrect GSHPType")

    def GshpSpecs_onInitLoopEquip(self: GshpSpecs, state: EnergyPlusData, calledFromLocation: PlantLocation):
        var initFirstHVAC: Bool = True
        var initCurLoad: Float64 = 0.0
        self.InitWatertoWaterHP(state, self.WWHPType, self.Name, initFirstHVAC, initCurLoad)
        if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFCooling:
            self.sizeCoolingWaterToWaterHP(state)
        else if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFHeating:
            self.sizeHeatingWaterToWaterHP(state)

    def GshpSpecs_getDesignCapacities(self: GshpSpecs, state: EnergyPlusData, calledFromLocation: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64):
        if calledFromLocation.loopNum == self.LoadPlantLoc.loopNum:
            if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFCooling:
                MinLoad = 0.0
                MaxLoad = self.RatedCapCool
                OptLoad = self.RatedCapCool
            else if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFHeating:
                MinLoad = 0.0
                MaxLoad = self.RatedCapHeat
                OptLoad = self.RatedCapHeat
            else:
                ShowFatalError(state, "SimHPWatertoWaterSimple: Module called with incorrect GSHPType")
        else:
            MinLoad = 0.0
            MaxLoad = 0.0
            OptLoad = 0.0

    def GshpSpecs_getSizingFactor(self: GshpSpecs, sizingFactor: Float64):
        sizingFactor = self.sizFac

    def GshpSpecs_GetWatertoWaterHPInput(state: EnergyPlusData):
        var NumAlphas: Int
        var NumNums: Int
        var IOStat: Int
        var ErrorsFound: Bool = False
        var NumCoolCoil: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, HPEqFitCoolingUC)
        var NumHeatCoil: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, HPEqFitHeatingUC)
        state.dataHPWaterToWaterSimple.NumGSHPs = NumCoolCoil + NumHeatCoil
        if state.dataHPWaterToWaterSimple.NumGSHPs <= 0:
            ShowSevereError(state, "GetEquationFitWaterToWater Input: No Equipment found")
            ErrorsFound = True
        if state.dataHPWaterToWaterSimple.NumGSHPs > 0:
            state.dataHPWaterToWaterSimple.GSHP = [GshpSpecs_default() for _ in range(state.dataHPWaterToWaterSimple.NumGSHPs)]
            state.dataHPWaterToWaterSimple.HeatPumpWaterUniqueNames.reserve(state.dataHPWaterToWaterSimple.NumGSHPs)
        for HPNum in range(1, NumCoolCoil + 1):
            var thisGSHP = state.dataHPWaterToWaterSimple.GSHP[HPNum - 1]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                     HPEqFitCoolingUC,
                                                                     HPNum,
                                                                     state.dataIPShortCut.cAlphaArgs,
                                                                     NumAlphas,
                                                                     state.dataIPShortCut.rNumericArgs,
                                                                     NumNums,
                                                                     IOStat,
                                                                     state.dataIPShortCut.lNumericFieldBlanks,
                                                                     state.dataIPShortCut.lAlphaFieldBlanks)
            GlobalNames.VerifyUniqueInterObjectName(state, state.dataHPWaterToWaterSimple.HeatPumpWaterUniqueNames, state.dataIPShortCut.cAlphaArgs[0], HPEqFitCoolingUC, ErrorsFound)
            thisGSHP.WWHPType = DataPlant.PlantEquipmentType.HPWaterEFCooling
            thisGSHP.Name = state.dataIPShortCut.cAlphaArgs[0]
            thisGSHP.RatedLoadVolFlowCool = state.dataIPShortCut.rNumericArgs[0]
            if thisGSHP.RatedLoadVolFlowCool == DataSizing.AutoSize:
                thisGSHP.ratedLoadVolFlowCoolWasAutoSized = True
            thisGSHP.RatedSourceVolFlowCool = state.dataIPShortCut.rNumericArgs[1]
            if thisGSHP.RatedSourceVolFlowCool == DataSizing.AutoSize:
                thisGSHP.ratedSourceVolFlowCoolWasAutoSized = True
            thisGSHP.RatedCapCool = state.dataIPShortCut.rNumericArgs[2]
            if thisGSHP.RatedCapCool == DataSizing.AutoSize:
                thisGSHP.ratedCapCoolWasAutoSized = True
            thisGSHP.RatedPowerCool = state.dataIPShortCut.rNumericArgs[3]
            if thisGSHP.RatedPowerCool == DataSizing.AutoSize:
                thisGSHP.ratedPowerCoolWasAutoSized = True
            thisGSHP.CoolCapCurveIndex = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[5])
            thisGSHP.CoolPowCurveIndex = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[6])
            if thisGSHP.CoolCapCurveIndex > 0:
                ErrorsFound = ErrorsFound or Curve.CheckCurveDims(state, thisGSHP.CoolCapCurveIndex, {4}, "GetWatertoWaterHPInput", HPEqFitCoolingUC, thisGSHP.Name, "Cooling Capacity Curve Name")
            if thisGSHP.CoolPowCurveIndex > 0:
                ErrorsFound = ErrorsFound or Curve.CheckCurveDims(state, thisGSHP.CoolPowCurveIndex, {4}, "GetWatertoWaterHPInput", HPEqFitCoolingUC, thisGSHP.Name, "Cooling Compressor Power Curve Name")
            if NumNums > 4:
                if not state.dataIPShortCut.lNumericFieldBlanks[4]:
                    thisGSHP.refCOP = state.dataIPShortCut.rNumericArgs[4]
                else:
                    thisGSHP.refCOP = 8.0
            else:
                thisGSHP.refCOP = 8.0
            if not thisGSHP.ratedPowerCoolWasAutoSized and not thisGSHP.ratedCapCoolWasAutoSized and thisGSHP.RatedPowerCool > 0.0:
                thisGSHP.refCOP = thisGSHP.RatedCapCool / thisGSHP.RatedPowerCool
            if NumNums > 5:
                if not state.dataIPShortCut.lNumericFieldBlanks[5]:
                    thisGSHP.sizFac = state.dataIPShortCut.rNumericArgs[5]
                else:
                    thisGSHP.sizFac = 1.0
            else:
                thisGSHP.sizFac = 1.0
            thisGSHP.SourceSideInletNodeNum = GetOnlySingleNode(state,
                                                                state.dataIPShortCut.cAlphaArgs[1],
                                                                ErrorsFound,
                                                                Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitCooling,
                                                                state.dataIPShortCut.cAlphaArgs[0],
                                                                Node.FluidType.Water,
                                                                Node.ConnectionType.Inlet,
                                                                Node.CompFluidStream.Primary,
                                                                Node.ObjectIsNotParent)
            thisGSHP.SourceSideOutletNodeNum = GetOnlySingleNode(state,
                                                                 state.dataIPShortCut.cAlphaArgs[2],
                                                                 ErrorsFound,
                                                                 Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitCooling,
                                                                 state.dataIPShortCut.cAlphaArgs[0],
                                                                 Node.FluidType.Water,
                                                                 Node.ConnectionType.Outlet,
                                                                 Node.CompFluidStream.Primary,
                                                                 Node.ObjectIsNotParent)
            thisGSHP.LoadSideInletNodeNum = GetOnlySingleNode(state,
                                                              state.dataIPShortCut.cAlphaArgs[3],
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitCooling,
                                                              state.dataIPShortCut.cAlphaArgs[0],
                                                              Node.FluidType.Water,
                                                              Node.ConnectionType.Inlet,
                                                              Node.CompFluidStream.Secondary,
                                                              Node.ObjectIsNotParent)
            thisGSHP.LoadSideOutletNodeNum = GetOnlySingleNode(state,
                                                               state.dataIPShortCut.cAlphaArgs[4],
                                                               ErrorsFound,
                                                               Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitCooling,
                                                               state.dataIPShortCut.cAlphaArgs[0],
                                                               Node.FluidType.Water,
                                                               Node.ConnectionType.Outlet,
                                                               Node.CompFluidStream.Secondary,
                                                               Node.ObjectIsNotParent)
            Node.TestCompSet(state, HPEqFitCoolingUC, state.dataIPShortCut.cAlphaArgs[0], state.dataIPShortCut.cAlphaArgs[1], state.dataIPShortCut.cAlphaArgs[2], "Condenser Water Nodes")
            Node.TestCompSet(state, HPEqFitCoolingUC, state.dataIPShortCut.cAlphaArgs[0], state.dataIPShortCut.cAlphaArgs[3], state.dataIPShortCut.cAlphaArgs[4], "Chilled Water Nodes")
            if NumAlphas > 7 and not state.dataIPShortCut.lAlphaFieldBlanks[7]:
                thisGSHP.companionName = state.dataIPShortCut.cAlphaArgs[7]
            SetupOutputVariable(state, "Heat Pump Electricity Energy", Constant.Units.J, thisGSHP.reportEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisGSHP.Name, Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Cooling)
            SetupOutputVariable(state, "Heat Pump Load Side Heat Transfer Energy", Constant.Units.J, thisGSHP.reportQLoadEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Source Side Heat Transfer Energy", Constant.Units.J, thisGSHP.reportQSourceEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisGSHP.Name)
        for HPNum in range(1, NumHeatCoil + 1):
            var GSHPNum: Int = NumCoolCoil + HPNum
            var thisGSHP = state.dataHPWaterToWaterSimple.GSHP[GSHPNum - 1]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                     HPEqFitHeatingUC,
                                                                     HPNum,
                                                                     state.dataIPShortCut.cAlphaArgs,
                                                                     NumAlphas,
                                                                     state.dataIPShortCut.rNumericArgs,
                                                                     NumNums,
                                                                     IOStat,
                                                                     state.dataIPShortCut.lNumericFieldBlanks,
                                                                     state.dataIPShortCut.lAlphaFieldBlanks)
            GlobalNames.VerifyUniqueInterObjectName(state, state.dataHPWaterToWaterSimple.HeatPumpWaterUniqueNames, state.dataIPShortCut.cAlphaArgs[0], HPEqFitHeatingUC, ErrorsFound)
            thisGSHP.WWHPType = DataPlant.PlantEquipmentType.HPWaterEFHeating
            thisGSHP.Name = state.dataIPShortCut.cAlphaArgs[0]
            thisGSHP.RatedLoadVolFlowHeat = state.dataIPShortCut.rNumericArgs[0]
            if thisGSHP.RatedLoadVolFlowHeat == DataSizing.AutoSize:
                thisGSHP.ratedLoadVolFlowHeatWasAutoSized = True
            thisGSHP.RatedSourceVolFlowHeat = state.dataIPShortCut.rNumericArgs[1]
            if thisGSHP.RatedSourceVolFlowHeat == DataSizing.AutoSize:
                thisGSHP.ratedSourceVolFlowHeatWasAutoSized = True
            thisGSHP.RatedCapHeat = state.dataIPShortCut.rNumericArgs[2]
            if thisGSHP.RatedCapHeat == DataSizing.AutoSize:
                thisGSHP.ratedCapHeatWasAutoSized = True
            thisGSHP.RatedPowerHeat = state.dataIPShortCut.rNumericArgs[3]
            if thisGSHP.RatedPowerHeat == DataSizing.AutoSize:
                thisGSHP.ratedPowerHeatWasAutoSized = True
            thisGSHP.HeatCapCurveIndex = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[5])
            thisGSHP.HeatPowCurveIndex = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[6])
            if thisGSHP.HeatCapCurveIndex > 0:
                ErrorsFound = ErrorsFound or Curve.CheckCurveDims(state, thisGSHP.HeatCapCurveIndex, {4}, "GetWatertoWaterHPInput", HPEqFitHeatingUC, thisGSHP.Name, "Heating Capacity Curve Name")
            if thisGSHP.HeatPowCurveIndex > 0:
                ErrorsFound = ErrorsFound or Curve.CheckCurveDims(state, thisGSHP.HeatPowCurveIndex, {4}, "GetWatertoWaterHPInput", HPEqFitHeatingUC, thisGSHP.Name, "Heating Compressor Power Curve Name")
            if NumNums > 4:
                if not state.dataIPShortCut.lNumericFieldBlanks[4]:
                    thisGSHP.refCOP = state.dataIPShortCut.rNumericArgs[4]
                else:
                    thisGSHP.refCOP = 7.5
            else:
                thisGSHP.refCOP = 7.5
            if not thisGSHP.ratedPowerHeatWasAutoSized and not thisGSHP.ratedCapHeatWasAutoSized and thisGSHP.RatedPowerHeat > 0.0:
                thisGSHP.refCOP = thisGSHP.RatedCapHeat / thisGSHP.RatedPowerHeat
            if NumNums > 5:
                if not state.dataIPShortCut.lNumericFieldBlanks[5]:
                    thisGSHP.sizFac = state.dataIPShortCut.rNumericArgs[5]
                else:
                    thisGSHP.sizFac = 1.0
            else:
                thisGSHP.sizFac = 1.0
            thisGSHP.SourceSideInletNodeNum = GetOnlySingleNode(state,
                                                                state.dataIPShortCut.cAlphaArgs[1],
                                                                ErrorsFound,
                                                                Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitHeating,
                                                                state.dataIPShortCut.cAlphaArgs[0],
                                                                Node.FluidType.Water,
                                                                Node.ConnectionType.Inlet,
                                                                Node.CompFluidStream.Primary,
                                                                Node.ObjectIsNotParent)
            thisGSHP.SourceSideOutletNodeNum = GetOnlySingleNode(state,
                                                                 state.dataIPShortCut.cAlphaArgs[2],
                                                                 ErrorsFound,
                                                                 Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitHeating,
                                                                 state.dataIPShortCut.cAlphaArgs[0],
                                                                 Node.FluidType.Water,
                                                                 Node.ConnectionType.Outlet,
                                                                 Node.CompFluidStream.Primary,
                                                                 Node.ObjectIsNotParent)
            thisGSHP.LoadSideInletNodeNum = GetOnlySingleNode(state,
                                                              state.dataIPShortCut.cAlphaArgs[3],
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitHeating,
                                                              state.dataIPShortCut.cAlphaArgs[0],
                                                              Node.FluidType.Water,
                                                              Node.ConnectionType.Inlet,
                                                              Node.CompFluidStream.Secondary,
                                                              Node.ObjectIsNotParent)
            thisGSHP.LoadSideOutletNodeNum = GetOnlySingleNode(state,
                                                               state.dataIPShortCut.cAlphaArgs[4],
                                                               ErrorsFound,
                                                               Node.ConnectionObjectType.HeatPumpWaterToWaterEquationFitHeating,
                                                               state.dataIPShortCut.cAlphaArgs[0],
                                                               Node.FluidType.Water,
                                                               Node.ConnectionType.Outlet,
                                                               Node.CompFluidStream.Secondary,
                                                               Node.ObjectIsNotParent)
            if NumAlphas > 7 and not state.dataIPShortCut.lAlphaFieldBlanks[7]:
                thisGSHP.companionName = state.dataIPShortCut.cAlphaArgs[7]
            Node.TestCompSet(state, HPEqFitHeatingUC, state.dataIPShortCut.cAlphaArgs[0], state.dataIPShortCut.cAlphaArgs[1], state.dataIPShortCut.cAlphaArgs[2], "Condenser Water Nodes")
            Node.TestCompSet(state, HPEqFitHeatingUC, state.dataIPShortCut.cAlphaArgs[0], state.dataIPShortCut.cAlphaArgs[3], state.dataIPShortCut.cAlphaArgs[4], "Hot Water Nodes")
            SetupOutputVariable(state, "Heat Pump Electricity Energy", Constant.Units.J, thisGSHP.reportEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisGSHP.Name, Constant.eResource.Electricity, OutputProcessor.Group.Plant, OutputProcessor.EndUseCat.Heating)
            SetupOutputVariable(state, "Heat Pump Load Side Heat Transfer Energy", Constant.Units.J, thisGSHP.reportQLoadEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Source Side Heat Transfer Energy", Constant.Units.J, thisGSHP.reportQSourceEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisGSHP.Name)
        for GSHPNum in range(1, state.dataHPWaterToWaterSimple.NumGSHPs + 1):
            var thisGSHP = state.dataHPWaterToWaterSimple.GSHP[GSHPNum - 1]
            if not thisGSHP.companionName.empty():
                thisGSHP.companionIndex = Util.FindItemInList(thisGSHP.companionName, state.dataHPWaterToWaterSimple.GSHP)
                if thisGSHP.companionIndex == 0:
                    ShowSevereError(state, format("GetEquationFitWaterToWater Input: did not find companion heat pump named '{}' in heat pump called {}", thisGSHP.companionName, thisGSHP.Name))
                    ErrorsFound = True
                else:
                    thisGSHP.companionIdentified = True
        if ErrorsFound:
            ShowFatalError(state, "Errors found in processing input for Water to Water Heat Pumps")
        for GSHPNum in range(1, state.dataHPWaterToWaterSimple.NumGSHPs + 1):
            var thisGSHP = state.dataHPWaterToWaterSimple.GSHP[GSHPNum - 1]
            SetupOutputVariable(state, "Heat Pump Electricity Rate", Constant.Units.W, thisGSHP.reportPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Load Side Heat Transfer Rate", Constant.Units.W, thisGSHP.reportQLoad, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Source Side Heat Transfer Rate", Constant.Units.W, thisGSHP.reportQSource, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Load Side Outlet Temperature", Constant.Units.C, thisGSHP.reportLoadSideOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Load Side Inlet Temperature", Constant.Units.C, thisGSHP.reportLoadSideInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Source Side Outlet Temperature", Constant.Units.C, thisGSHP.reportSourceSideOutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Source Side Inlet Temperature", Constant.Units.C, thisGSHP.reportSourceSideInletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Load Side Mass Flow Rate", Constant.Units.kg_s, thisGSHP.reportLoadSideMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)
            SetupOutputVariable(state, "Heat Pump Source Side Mass Flow Rate", Constant.Units.kg_s, thisGSHP.reportSourceSideMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisGSHP.Name)

    def GshpSpecs_InitWatertoWaterHP(self: GshpSpecs, state: EnergyPlusData, GSHPTypeNum: DataPlant.PlantEquipmentType, GSHPName: String, FirstHVACIteration: Bool, MyLoad: Float64):
        var RoutineName: String = "InitGshp"
        var LoadSideInletNode: Int
        var SourceSideInletNode: Int
        var rho: Float64
        self.MustRun = True
        LoadSideInletNode = self.LoadSideInletNodeNum
        SourceSideInletNode = self.SourceSideInletNodeNum
        if self.MyPlantScanFlag:
            var errFlag: Bool = False
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.WWHPType, self.SourcePlantLoc, errFlag, _, _, _, self.SourceSideInletNodeNum, _)
            PlantUtilities.ScanPlantLoopsForObject(state, self.Name, self.WWHPType, self.LoadPlantLoc, errFlag, _, _, _, self.LoadSideInletNodeNum, _)
            if not errFlag:
                PlantUtilities.InterConnectTwoPlantLoopSides(state, self.LoadPlantLoc, self.SourcePlantLoc, self.WWHPType, True)
            if errFlag:
                ShowFatalError(state, "GetWatertoWaterHPInput: Program terminated on scan for loop data")
            self.MyPlantScanFlag = False
        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            self.reportPower = 0.0
            self.reportEnergy = 0.0
            self.reportQLoad = 0.0
            self.reportQLoadEnergy = 0.0
            self.reportQSource = 0.0
            self.reportQSourceEnergy = 0.0
            self.reportLoadSideMassFlowRate = 0.0
            self.reportLoadSideInletTemp = 0.0
            self.reportLoadSideOutletTemp = 0.0
            self.reportSourceSideMassFlowRate = 0.0
            self.reportSourceSideInletTemp = 0.0
            self.reportSourceSideOutletTemp = 0.0
            self.IsOn = False
            self.MustRun = True
            if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFHeating:
                rho = self.LoadPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                self.LoadSideDesignMassFlow = self.RatedLoadVolFlowHeat * rho
                rho = self.SourcePlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                self.SourceSideDesignMassFlow = self.RatedSourceVolFlowHeat * rho
            else if self.WWHPType == DataPlant.PlantEquipmentType.HPWaterEFCooling:
                rho = self.LoadPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                self.LoadSideDesignMassFlow = self.RatedLoadVolFlowCool * rho
                rho = self.SourcePlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                self.SourceSideDesignMassFlow = self.RatedSourceVolFlowCool * rho
            PlantUtilities.InitComponentNodes(state, 0.0, self.LoadSideDesignMassFlow, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum)
            PlantUtilities.InitComponentNodes(state, 0.0, self.SourceSideDesignMassFlow, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum)
            if state.dataLoopNodes.Node[self.SourceSideOutletNodeNum - 1].TempSetPoint == Node.SensedNodeFlagValue:
                state.dataLoopNodes.Node[self.SourceSideOutletNodeNum - 1].TempSetPoint = 0.0
            state.dataLoopNodes.Node[self.SourceSideInletNodeNum - 1].Temp = state.dataLoopNodes.Node[self.SourceSideOutletNodeNum - 1].TempSetPoint + 30
            self.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True
        if MyLoad > 0.0 and GSHPTypeNum == DataPlant.PlantEquipmentType.HPWaterEFHeating:
            self.MustRun = True
            self.IsOn = True
        else if MyLoad < 0.0 and GSHPTypeNum == DataPlant.PlantEquipmentType.HPWaterEFCooling:
            self.MustRun = True
            self.IsOn = True
        else:
            self.MustRun = False
            self.IsOn = False
        if not self.MustRun:
            self.reportLoadSideMassFlowRate = 0.0
            self.reportSourceSideMassFlowRate = 0.0
            PlantUtilities.SetComponentFlowRate(state, self.reportLoadSideMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
            PlantUtilities.SetComponentFlowRate(state, self.reportSourceSideMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
            PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc, self.CondMassFlowIndex, self.SourcePlantLoc, DataPlant.CriteriaType.MassFlowRate, self.reportSourceSideMassFlowRate)
        else:
            self.reportLoadSideMassFlowRate = self.LoadSideDesignMassFlow
            self.reportSourceSideMassFlowRate = self.SourceSideDesignMassFlow
            PlantUtilities.SetComponentFlowRate(state, self.reportLoadSideMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
            PlantUtilities.SetComponentFlowRate(state, self.reportSourceSideMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
            if self.reportLoadSideMassFlowRate <= 0.0 or self.reportSourceSideMassFlowRate <= 0.0:
                self.reportLoadSideMassFlowRate = 0.0
                self.reportSourceSideMassFlowRate = 0.0
                self.MustRun = False
                PlantUtilities.SetComponentFlowRate(state, self.reportLoadSideMassFlowRate, self.LoadSideInletNodeNum, self.LoadSideOutletNodeNum, self.LoadPlantLoc)
                PlantUtilities.SetComponentFlowRate(state, self.reportSourceSideMassFlowRate, self.SourceSideInletNodeNum, self.SourceSideOutletNodeNum, self.SourcePlantLoc)
                PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc, self.CondMassFlowIndex, self.SourcePlantLoc, DataPlant.CriteriaType.MassFlowRate, self.reportSourceSideMassFlowRate)
                return
            PlantUtilities.PullCompInterconnectTrigger(state, self.LoadPlantLoc, self.CondMassFlowIndex, self.SourcePlantLoc, DataPlant.CriteriaType.MassFlowRate, self.reportSourceSideMassFlowRate)
        self.reportLoadSideInletTemp = state.dataLoopNodes.Node[LoadSideInletNode - 1].Temp
        self.reportSourceSideInletTemp = state.dataLoopNodes.Node[SourceSideInletNode - 1].Temp
        self.reportPower = 0.0
        self.reportEnergy = 0.0
        self.reportQLoad = 0.0
        self.reportQLoadEnergy = 0.0
        self.reportQSource = 0.0
        self.reportQSourceEnergy = 0.0
        self.reportLoadSideOutletTemp = 0.0
        self.reportSourceSideOutletTemp = 0.0

    def GshpSpecs_sizeCoolingWaterToWaterHP(self: GshpSpecs, state: EnergyPlusData):
        var errorsFound: Bool = False
        var RoutineName: String = "sizeCoolingWaterToWaterHP"
        var tmpLoadSideVolFlowRate: Float64 = self.RatedLoadVolFlowCool
        var tmpSourceSideVolFlowRate: Float64
        var tmpCoolingCap: Float64 = self.RatedCapCool
        var tmpPowerDraw: Float64 = self.RatedPowerCool
        if self.companionIdentified:
            self.RatedLoadVolFlowHeat = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedLoadVolFlowHeat
            self.ratedLoadVolFlowHeatWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedLoadVolFlowHeatWasAutoSized
            self.RatedSourceVolFlowHeat = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedSourceVolFlowHeat
            self.ratedSourceVolFlowHeatWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedSourceVolFlowHeatWasAutoSized
            self.RatedCapHeat = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedCapHeat
            self.ratedCapHeatWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedCapHeatWasAutoSized
            self.RatedPowerHeat = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedPowerHeat
            self.ratedPowerHeatWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedPowerHeatWasAutoSized
        var pltLoadSizNum: Int = self.LoadPlantLoc.loop.PlantSizNum
        if pltLoadSizNum > 0:
            if state.dataSize.PlantSizData[pltLoadSizNum - 1].DesVolFlowRate > HVAC.SmallWaterVolFlow:
                tmpLoadSideVolFlowRate = state.dataSize.PlantSizData[pltLoadSizNum - 1].DesVolFlowRate * self.sizFac
                if self.companionIdentified:
                    tmpLoadSideVolFlowRate = max(tmpLoadSideVolFlowRate, self.RatedLoadVolFlowHeat)
                    self.RatedLoadVolFlowCool = tmpLoadSideVolFlowRate
                var rho: Float64 = self.LoadPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                var Cp: Float64 = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, RoutineName)
                tmpCoolingCap = Cp * rho * state.dataSize.PlantSizData[pltLoadSizNum - 1].DeltaT * tmpLoadSideVolFlowRate
            else if self.companionIdentified and self.RatedLoadVolFlowHeat > 0.0:
                tmpLoadSideVolFlowRate = self.RatedLoadVolFlowHeat
                var rho: Float64 = self.LoadPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                var Cp: Float64 = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, RoutineName)
                tmpCoolingCap = Cp * rho * state.dataSize.PlantSizData[pltLoadSizNum - 1].DeltaT * tmpLoadSideVolFlowRate
            else:
                if self.ratedCapCoolWasAutoSized:
                    tmpCoolingCap = 0.0
                if self.ratedLoadVolFlowCoolWasAutoSized:
                    tmpLoadSideVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.ratedCapCoolWasAutoSized:
                    self.RatedCapCool = tmpCoolingCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Nominal Capacity [W]", tmpCoolingCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Initial Design Size Nominal Capacity [W]", tmpCoolingCap)
                else:
                    if self.RatedCapCool > 0.0 and tmpCoolingCap > 0.0:
                        var nomCoolingCapUser: Float64 = self.RatedCapCool
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                            if state.dataGlobal.DoPlantSizing:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Nominal Capacity [W]", tmpCoolingCap, "User-Specified Nominal Capacity [W]", nomCoolingCapUser)
                            else:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "User-Specified Nominal Capacity [W]", nomCoolingCapUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpCoolingCap - nomCoolingCapUser) / nomCoolingCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("sizeCoolingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Nominal Capacity of {:#G} [W]", nomCoolingCapUser))
                                    ShowContinueError(state, format("differs from Design Size Nominal Capacity of {:#G} [W]", tmpCoolingCap))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpCoolingCap = nomCoolingCapUser
                if self.ratedLoadVolFlowCoolWasAutoSized:
                    self.RatedLoadVolFlowCool = tmpLoadSideVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Initial Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                else:
                    if self.RatedLoadVolFlowCool > 0.0 and tmpLoadSideVolFlowRate > 0.0:
                        var nomLoadSideVolFlowUser: Float64 = self.RatedLoadVolFlowCool
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                            if state.dataGlobal.DoPlantSizing:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate, "User-Specified Load Side Volume Flow Rate [m3/s]", nomLoadSideVolFlowUser)
                            else:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "User-Specified Load Side Volume Flow Rate [m3/s]", nomLoadSideVolFlowUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpLoadSideVolFlowRate - nomLoadSideVolFlowUser) / nomLoadSideVolFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("sizeCoolingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Load Side Volume Flow Rate of {:#G} [m3/s]", nomLoadSideVolFlowUser))
                                    ShowContinueError(state, format("differs from Design Size Load Side Volume Flow Rate of {:#G} [m3/s]", tmpLoadSideVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpLoadSideVolFlowRate = nomLoadSideVolFlowUser
        else:
            if self.companionIdentified:
                if self.ratedLoadVolFlowHeatWasAutoSized and self.RatedLoadVolFlowHeat > 0.0:
                    tmpLoadSideVolFlowRate = self.RatedLoadVolFlowHeat
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.RatedLoadVolFlowCool = tmpLoadSideVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Initial Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                if self.ratedCapHeatWasAutoSized and self.RatedCapHeat > 0.0:
                    tmpCoolingCap = self.RatedCapHeat
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.RatedCapCool = tmpCoolingCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Nominal Capacity [W]", tmpCoolingCap)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Initial Design Size Nominal Capacity [W]", tmpCoolingCap)
            else:
                if (self.ratedLoadVolFlowCoolWasAutoSized or self.ratedCapCoolWasAutoSized) and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "Autosizing of Water to Water Heat Pump requires a loop Sizing:Plant object.")
                    ShowContinueError(state, format("Occurs in HeatPump:WaterToWater:EquationFit:Cooling object = {}", self.Name))
                    errorsFound = True
            if not self.ratedLoadVolFlowCoolWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "User-Specified Load Side Flow Rate [m3/s]", self.RatedLoadVolFlowCool)
            if not self.ratedCapCoolWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "User-Specified Nominal Capacity [W]", self.RatedCapCool)
        if not self.ratedLoadVolFlowCoolWasAutoSized:
            tmpLoadSideVolFlowRate = self.RatedLoadVolFlowCool
        var pltSourceSizNum: Int = self.SourcePlantLoc.loop.PlantSizNum
        if pltSourceSizNum > 0:
            var rho: Float64 = self.SourcePlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
            var Cp: Float64 = self.SourcePlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, RoutineName)
            tmpSourceSideVolFlowRate = tmpCoolingCap * (1.0 + (1.0 / self.refCOP)) / (state.dataSize.PlantSizData[pltSourceSizNum - 1].DeltaT * Cp * rho)
        else:
            tmpSourceSideVolFlowRate = tmpLoadSideVolFlowRate
        if self.ratedSourceVolFlowCoolWasAutoSized:
            self.RatedSourceVolFlowCool = tmpSourceSideVolFlowRate
            if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Source Side Volume Flow Rate [m3/s]", tmpSourceSideVolFlowRate)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Initial Design Size Source Side Volume Flow Rate [m3/s]", tmpSourceSideVolFlowRate)
        else:
            if self.RatedSourceVolFlowCool > 0.0 and tmpSourceSideVolFlowRate > 0.0:
                var nomSourceSideVolFlowUser: Float64 = self.RatedSourceVolFlowCool
                if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                    if state.dataGlobal.DoPlantSizing:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Source Side Volume Flow Rate [m3/s]", tmpSourceSideVolFlowRate, "User-Specified Source Side Volume Flow Rate [m3/s]", nomSourceSideVolFlowUser)
                    else:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "User-Specified Source Side Volume Flow Rate [m3/s]", nomSourceSideVolFlowUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (abs(tmpSourceSideVolFlowRate - nomSourceSideVolFlowUser) / nomSourceSideVolFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state, format("sizeCoolingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                            ShowContinueError(state, format("User-Specified Source Side Volume Flow Rate of {:#G} [m3/s]", nomSourceSideVolFlowUser))
                            ShowContinueError(state, format("differs from Design Size Source Side Volume Flow Rate of {:#G} [m3/s]", tmpSourceSideVolFlowRate))
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                tmpSourceSideVolFlowRate = nomSourceSideVolFlowUser
        if not self.ratedSourceVolFlowCoolWasAutoSized:
            tmpSourceSideVolFlowRate = self.RatedSourceVolFlowCool
        if not self.ratedCapCoolWasAutoSized:
            tmpCoolingCap = self.RatedCapCool
        if self.ratedPowerCoolWasAutoSized:
            tmpPowerDraw = tmpCoolingCap / self.refCOP
            self.RatedPowerCool = tmpPowerDraw
            if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Cooling Power Consumption [W]", tmpPowerDraw)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Initial Design Size Cooling Power Consumption [W]", tmpPowerDraw)
        else:
            if self.RatedPowerCool > 0.0 and tmpPowerDraw > 0.0:
                var nomPowerDrawUser: Float64 = self.RatedPowerCool
                if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
                    if state.dataGlobal.DoPlantSizing:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "Design Size Cooling Power Consumption [W]", tmpPowerDraw, "User-Specified Cooling Power Consumption [W]", nomPowerDrawUser)
                    else:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Cooling", self.Name, "User-Specified Cooling Power Consumption [W]", nomPowerDrawUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (abs(tmpPowerDraw - nomPowerDrawUser) / nomPowerDrawUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state, format("sizeCoolingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                            ShowContinueError(state, format("User-Specified Cooling Power Consumption of {:#G} [W]", nomPowerDrawUser))
                            ShowContinueError(state, format("differs from Design Size Cooling Power Consumption of {:#G} [W]", tmpPowerDraw))
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                tmpPowerDraw = nomPowerDrawUser
                self.refCOP = tmpCoolingCap / tmpPowerDraw
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.LoadSideInletNodeNum, tmpLoadSideVolFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.SourceSideInletNodeNum, tmpSourceSideVolFlowRate * 0.5)
        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myCoolingSizesReported:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "HeatPump:WaterToWater:EquationFit:Cooling")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, self.Name, self.refCOP)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.RatedCapCool)
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            self.myCoolingSizesReported = True
        if errorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def GshpSpecs_sizeHeatingWaterToWaterHP(self: GshpSpecs, state: EnergyPlusData):
        var errorsFound: Bool = False
        var RoutineName: String = "sizeHeatingWaterToWaterHP"
        var tmpLoadSideVolFlowRate: Float64 = self.RatedLoadVolFlowHeat
        var tmpSourceSideVolFlowRate: Float64
        var tmpHeatingCap: Float64 = self.RatedCapHeat
        var tmpPowerDraw: Float64 = self.RatedPowerHeat
        if self.companionIdentified:
            self.RatedLoadVolFlowCool = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedLoadVolFlowCool
            self.ratedLoadVolFlowCoolWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedLoadVolFlowCoolWasAutoSized
            self.RatedSourceVolFlowCool = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedSourceVolFlowCool
            self.ratedSourceVolFlowCoolWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedSourceVolFlowCoolWasAutoSized
            self.RatedCapCool = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedCapCool
            self.ratedCapCoolWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedCapCoolWasAutoSized
            self.RatedPowerCool = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].RatedPowerCool
            self.ratedPowerCoolWasAutoSized = state.dataHPWaterToWaterSimple.GSHP[self.companionIndex - 1].ratedPowerCoolWasAutoSized
        var pltLoadSizNum: Int = self.LoadPlantLoc.loop.PlantSizNum
        if pltLoadSizNum > 0:
            if state.dataSize.PlantSizData[pltLoadSizNum - 1].DesVolFlowRate > HVAC.SmallWaterVolFlow:
                tmpLoadSideVolFlowRate = state.dataSize.PlantSizData[pltLoadSizNum - 1].DesVolFlowRate * self.sizFac
                if self.companionIdentified:
                    tmpLoadSideVolFlowRate = max(tmpLoadSideVolFlowRate, self.RatedLoadVolFlowCool)
                    self.RatedLoadVolFlowHeat = tmpLoadSideVolFlowRate
                var rho: Float64 = self.LoadPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                var Cp: Float64 = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                tmpHeatingCap = Cp * rho * state.dataSize.PlantSizData[pltLoadSizNum - 1].DeltaT * tmpLoadSideVolFlowRate
            else if self.companionIdentified and self.RatedLoadVolFlowCool > 0.0:
                tmpLoadSideVolFlowRate = self.RatedLoadVolFlowCool
                var rho: Float64 = self.LoadPlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                var Cp: Float64 = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                tmpHeatingCap = Cp * rho * state.dataSize.PlantSizData[pltLoadSizNum - 1].DeltaT * tmpLoadSideVolFlowRate
            else:
                if self.ratedCapHeatWasAutoSized:
                    tmpHeatingCap = 0.0
                if self.ratedLoadVolFlowHeatWasAutoSized:
                    tmpLoadSideVolFlowRate = 0.0
            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.ratedCapHeatWasAutoSized:
                    self.RatedCapHeat = tmpHeatingCap
                    if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Nominal Capacity [W]", tmpHeatingCap)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Initial Design Size Nominal Capacity [W]", tmpHeatingCap)
                else:
                    if self.RatedCapHeat > 0.0 and tmpHeatingCap > 0.0:
                        var nomHeatingCapUser: Float64 = self.RatedCapHeat
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                            if state.dataGlobal.DoPlantSizing:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Nominal Capacity [W]", tmpHeatingCap, "User-Specified Nominal Capacity [W]", nomHeatingCapUser)
                            else:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "User-Specified Nominal Capacity [W]", nomHeatingCapUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpHeatingCap - nomHeatingCapUser) / nomHeatingCapUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("sizeHeatingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Nominal Capacity of {:#G} [W]", nomHeatingCapUser))
                                    ShowContinueError(state, format("differs from Design Size Nominal Capacity of {:#G} [W]", tmpHeatingCap))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpHeatingCap = nomHeatingCapUser
                if self.ratedLoadVolFlowHeatWasAutoSized:
                    self.RatedLoadVolFlowHeat = tmpLoadSideVolFlowRate
                    if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Initial Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                else:
                    if self.RatedLoadVolFlowHeat > 0.0 and tmpLoadSideVolFlowRate > 0.0:
                        var nomLoadSideVolFlowUser: Float64 = self.RatedLoadVolFlowHeat
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                            if state.dataGlobal.DoPlantSizing:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate, "User-Specified Load Side Volume Flow Rate [m3/s]", nomLoadSideVolFlowUser)
                            else:
                                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "User-Specified Load Side Volume Flow Rate [m3/s]", nomLoadSideVolFlowUser)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(tmpLoadSideVolFlowRate - nomLoadSideVolFlowUser) / nomLoadSideVolFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, format("sizeHeatingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                                    ShowContinueError(state, format("User-Specified Load Side Volume Flow Rate of {:#G} [m3/s]", nomLoadSideVolFlowUser))
                                    ShowContinueError(state, format("differs from Design Size Load Side Volume Flow Rate of {:#G} [m3/s]", tmpLoadSideVolFlowRate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmpLoadSideVolFlowRate = nomLoadSideVolFlowUser
        else:
            if self.companionIdentified:
                if self.ratedLoadVolFlowHeatWasAutoSized and self.RatedLoadVolFlowCool > 0.0:
                    tmpLoadSideVolFlowRate = self.RatedLoadVolFlowCool
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.RatedLoadVolFlowHeat = tmpLoadSideVolFlowRate
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Initial Design Size Load Side Volume Flow Rate [m3/s]", tmpLoadSideVolFlowRate)
                if self.ratedCapHeatWasAutoSized and self.RatedCapCool > 0.0:
                    tmpHeatingCap = self.RatedCapCool
                    if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                        self.RatedCapHeat = tmpHeatingCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Nominal Capacity [W]", tmpHeatingCap)
                        if state.dataPlnt.PlantFirstSizesOkayToReport:
                            BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Initial Design Size Nominal Capacity [W]", tmpHeatingCap)
            else:
                if (self.ratedLoadVolFlowHeatWasAutoSized or self.ratedCapHeatWasAutoSized) and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                    ShowSevereError(state, "Autosizing of Water to Water Heat Pump requires a loop Sizing:Plant object.")
                    ShowContinueError(state, format("Occurs in HeatPump:WaterToWater:EquationFit:Heating object = {}", self.Name))
                    errorsFound = True
            if not self.ratedLoadVolFlowHeatWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "User-Specified Load Side Flow Rate [m3/s]", self.RatedLoadVolFlowHeat)
            if not self.ratedCapHeatWasAutoSized and state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "User-Specified Nominal Capacity [W]", self.RatedCapHeat)
        if not self.ratedLoadVolFlowHeatWasAutoSized:
            tmpLoadSideVolFlowRate = self.RatedLoadVolFlowHeat
        var pltSourceSizNum: Int = self.SourcePlantLoc.loop.PlantSizNum
        if pltSourceSizNum > 0:
            var rho: Float64 = self.SourcePlantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
            var Cp: Float64 = self.SourcePlantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
            tmpSourceSideVolFlowRate = tmpHeatingCap * (1.0 - (1.0 / self.refCOP)) / (state.dataSize.PlantSizData[pltSourceSizNum - 1].DeltaT * Cp * rho)
        else:
            tmpSourceSideVolFlowRate = tmpLoadSideVolFlowRate
        if self.ratedSourceVolFlowHeatWasAutoSized:
            self.RatedSourceVolFlowHeat = tmpSourceSideVolFlowRate
            if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Source Side Volume Flow Rate [m3/s]", tmpSourceSideVolFlowRate)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Initial Design Size Source Side Volume Flow Rate [m3/s]", tmpSourceSideVolFlowRate)
        else:
            if self.RatedSourceVolFlowHeat > 0.0 and tmpSourceSideVolFlowRate > 0.0:
                var nomSourceSideVolFlowUser: Float64 = self.RatedSourceVolFlowHeat
                if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                    if state.dataGlobal.DoPlantSizing:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Source Side Volume Flow Rate [m3/s]", tmpSourceSideVolFlowRate, "User-Specified Source Side Volume Flow Rate [m3/s]", nomSourceSideVolFlowUser)
                    else:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "User-Specified Source Side Volume Flow Rate [m3/s]", nomSourceSideVolFlowUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (abs(tmpSourceSideVolFlowRate - nomSourceSideVolFlowUser) / nomSourceSideVolFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state, format("sizeHeatingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                            ShowContinueError(state, format("User-Specified Source Side Volume Flow Rate of {:#G} [m3/s]", nomSourceSideVolFlowUser))
                            ShowContinueError(state, format("differs from Design Size Source Side Volume Flow Rate of {:#G} [m3/s]", tmpSourceSideVolFlowRate))
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                tmpSourceSideVolFlowRate = nomSourceSideVolFlowUser
        if not self.ratedSourceVolFlowHeatWasAutoSized:
            tmpSourceSideVolFlowRate = self.RatedSourceVolFlowHeat
        if not self.ratedCapHeatWasAutoSized:
            tmpHeatingCap = self.RatedCapHeat
        if self.ratedPowerHeatWasAutoSized:
            tmpPowerDraw = tmpHeatingCap / self.refCOP
            self.RatedPowerHeat = tmpPowerDraw
            if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Heating Power Consumption [W]", tmpPowerDraw)
            if state.dataPlnt.PlantFirstSizesOkayToReport:
                BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Initial Design Size Heating Power Consumption [W]", tmpPowerDraw)
        else:
            if self.RatedPowerHeat > 0.0 and tmpPowerDraw > 0.0:
                var nomPowerDrawUser: Float64 = self.RatedPowerHeat
                if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
                    if state.dataGlobal.DoPlantSizing:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "Design Size Heating Power Consumption [W]", tmpPowerDraw, "User-Specified Heating Power Consumption [W]", nomPowerDrawUser)
                    else:
                        BaseSizer.reportSizerOutput(state, "HeatPump:WaterToWater:EquationFit:Heating", self.Name, "User-Specified Heating Power Consumption [W]", nomPowerDrawUser)
                    if state.dataGlobal.DisplayExtraWarnings:
                        if (abs(tmpPowerDraw - nomPowerDrawUser) / nomPowerDrawUser) > state.dataSize.AutoVsHardSizingThreshold:
                            ShowMessage(state, format("sizeHeatingWaterToWaterHP: Potential issue with equipment sizing for {}", self.Name))
                            ShowContinueError(state, format("User-Specified Heating Power Consumption of {:#G} [W]", nomPowerDrawUser))
                            ShowContinueError(state, format("differs from Design Size Heating Power Consumption of {:#G} [W]", tmpPowerDraw))
                            ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                            ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                tmpPowerDraw = nomPowerDrawUser
                self.refCOP = tmpHeatingCap / tmpPowerDraw
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.LoadSideInletNodeNum, tmpLoadSideVolFlowRate)
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.SourceSideInletNodeNum, tmpSourceSideVolFlowRate * 0.5)
        if state.dataPlnt.PlantFinalSizesOkayToReport and not self.myHeatingSizesReported:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechType, self.Name, "HeatPump:WaterToWater:EquationFit:Heating")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomEff, self.Name, self.refCOP)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMechNomCap, self.Name, self.RatedCapHeat)
        if state.dataPlnt.PlantFinalSizesOkayToReport:
            self.myHeatingSizesReported = True
        if errorsFound:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def GshpSpecs_CalcWatertoWaterHPCooling(self: GshpSpecs, state: EnergyPlusData, MyLoad: Float64):
        var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
        var CelsiustoKelvin: Float64 = Constant.Kelvin
        var Tref: Float64 = 283.15
        var RoutineName: String = "CalcWatertoWaterHPCooling"
        var CoolCapRated: Float64
        var CoolPowerRated: Float64
        var LoadSideVolFlowRateRated: Float64
        var SourceSideVolFlowRateRated: Float64
        var LoadSideMassFlowRate: Float64
        var LoadSideInletTemp: Float64
        var LoadSideOutletTemp: Float64
        var SourceSideMassFlowRate: Float64
        var SourceSideInletTemp: Float64
        var SourceSideOutletTemp: Float64
        var func1: Float64
        var func2: Float64
        var func3: Float64
        var func4: Float64
        var Power: Float64
        var QLoad: Float64
        var QSource: Float64
        var PartLoadRatio: Float64
        var rhoLoadSide: Float64
        var rhoSourceSide: Float64
        var CpLoadSide: Float64
        var CpSourceSide: Float64
        LoadSideVolFlowRateRated = self.RatedLoadVolFlowCool
        SourceSideVolFlowRateRated = self.RatedSourceVolFlowCool
        CoolCapRated = self.RatedCapCool
        CoolPowerRated = self.RatedPowerCool
        LoadSideMassFlowRate = self.reportLoadSideMassFlowRate
        LoadSideInletTemp = self.reportLoadSideInletTemp
        SourceSideMassFlowRate = self.reportSourceSideMassFlowRate
        SourceSideInletTemp = self.reportSourceSideInletTemp
        if not self.MustRun:
            return
        rhoLoadSide = self.LoadPlantLoc.loop.glycol.getDensity(state, LoadSideInletTemp, RoutineName)
        rhoSourceSide = self.SourcePlantLoc.loop.glycol.getDensity(state, SourceSideInletTemp, RoutineName)
        func1 = ((LoadSideInletTemp + CelsiustoKelvin) / Tref)
        func2 = ((SourceSideInletTemp + CelsiustoKelvin) / Tref)
        func3 = (LoadSideMassFlowRate / (LoadSideVolFlowRateRated * rhoLoadSide))
        func4 = (SourceSideMassFlowRate / (SourceSideVolFlowRateRated * rhoSourceSide))
        QLoad = CoolCapRated * Curve.CurveValue(state, self.CoolCapCurveIndex, func1, func2, func3, func4)
        Power = CoolPowerRated * Curve.CurveValue(state, self.CoolPowCurveIndex, func1, func2, func3, func4)
        if (QLoad <= 0.0 or Power <= 0.0) and not state.dataGlobal.WarmupFlag:
            if QLoad <= 0.0:
                if self.CoolCapNegativeCounter < 1:
                    self.CoolCapNegativeCounter += 1
                    ShowWarningError(state, format("{} \"{}\":", HPEqFitCooling, self.Name))
                    ShowContinueError(state, format(" Cooling capacity curve output is <= 0.0 ({:.4f}).", QLoad))
                    ShowContinueError(state, format(" Zero or negative value occurs with a load-side inlet temperature of {:.2f} C,", LoadSideInletTemp))
                    ShowContinueError(state, format(" a source-side inlet temperature of {:.2f} C,", SourceSideInletTemp))
                    ShowContinueError(state, format(" a load-side mass flow rate of {:.3f} kg/s,", LoadSideMassFlowRate))
                    ShowContinueError(state, format(" and a source-side mass flow rate of {:.3f} kg/s.", SourceSideMassFlowRate))
                    ShowContinueErrorTimeStamp(state, " The heat pump is turned off for this time step but simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, HPEqFitCooling + " \"" + self.Name + "\": Cooling capacity curve output is <= 0.0 warning continues...", self.CoolCapNegativeIndex, QLoad, QLoad)
            if Power <= 0.0:
                if self.CoolPowerNegativeCounter < 1:
                    self.CoolPowerNegativeCounter += 1
                    ShowWarningError(state, format("{} \"{}\":", HPEqFitCooling, self.Name))
                    ShowContinueError(state, format(" Cooling compressor power curve output is <= 0.0 ({:.4f}).", Power))
                    ShowContinueError(state, format(" Zero or negative value occurs with a load-side inlet temperature of {:.2f} C,", LoadSideInletTemp))
                    ShowContinueError(state, format(" a source-side inlet temperature of {:.2f} C,", SourceSideInletTemp))
                    ShowContinueError(state, format(" a load-side mass flow rate of {:.3f} kg/s,", LoadSideMassFlowRate))
                    ShowContinueError(state, format(" and a source-side mass flow rate of {:.3f} kg/s.", SourceSideMassFlowRate))
                    ShowContinueErrorTimeStamp(state, " The heat pump is turned off for this time step but simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, HPEqFitCooling + " \"" + self.Name + "\": Cooling compressor power curve output is <= 0.0 warning continues...", self.CoolPowerNegativeIndex, Power, Power)
            QLoad = 0.0
            Power = 0.0
        QSource = QLoad + Power
        if abs(MyLoad) < QLoad and QLoad != 0.0:
            PartLoadRatio = abs(MyLoad) / QLoad
            QLoad = abs(MyLoad)
            Power *= PartLoadRatio
            QSource *= PartLoadRatio
        CpLoadSide = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, LoadSideInletTemp, RoutineName)
        CpSourceSide = self.SourcePlantLoc.loop.glycol.getSpecificHeat(state, SourceSideInletTemp, RoutineName)
        LoadSideOutletTemp = LoadSideInletTemp - QLoad / (LoadSideMassFlowRate * CpLoadSide)
        SourceSideOutletTemp = SourceSideInletTemp + QSource / (SourceSideMassFlowRate * CpSourceSide)
        self.reportPower = Power
        self.reportEnergy = Power * TimeStepSysSec
        self.reportQSource = QSource
        self.reportQLoad = QLoad
        self.reportQSourceEnergy = QSource * TimeStepSysSec
        self.reportQLoadEnergy = QLoad * TimeStepSysSec
        self.reportLoadSideOutletTemp = LoadSideOutletTemp
        self.reportSourceSideOutletTemp = SourceSideOutletTemp

    def GshpSpecs_CalcWatertoWaterHPHeating(self: GshpSpecs, state: EnergyPlusData, MyLoad: Float64):
        var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
        var CelsiustoKelvin: Float64 = Constant.Kelvin
        var Tref: Float64 = 283.15
        var RoutineName: String = "CalcWatertoWaterHPHeating"
        var HeatCapRated: Float64
        var HeatPowerRated: Float64
        var LoadSideVolFlowRateRated: Float64
        var SourceSideVolFlowRateRated: Float64
        var LoadSideMassFlowRate: Float64
        var LoadSideInletTemp: Float64
        var LoadSideOutletTemp: Float64
        var SourceSideMassFlowRate: Float64
        var SourceSideInletTemp: Float64
        var SourceSideOutletTemp: Float64
        var func1: Float64
        var func2: Float64
        var func3: Float64
        var func4: Float64
        var Power: Float64
        var QLoad: Float64
        var QSource: Float64
        var PartLoadRatio: Float64
        var rhoLoadSide: Float64
        var rhoSourceSide: Float64
        var CpLoadSide: Float64
        var CpSourceSide: Float64
        LoadSideVolFlowRateRated = self.RatedLoadVolFlowHeat
        SourceSideVolFlowRateRated = self.RatedSourceVolFlowHeat
        HeatCapRated = self.RatedCapHeat
        HeatPowerRated = self.RatedPowerHeat
        LoadSideMassFlowRate = self.reportLoadSideMassFlowRate
        LoadSideInletTemp = self.reportLoadSideInletTemp
        SourceSideMassFlowRate = self.reportSourceSideMassFlowRate
        SourceSideInletTemp = self.reportSourceSideInletTemp
        if not self.MustRun:
            return
        rhoLoadSide = self.LoadPlantLoc.loop.glycol.getDensity(state, LoadSideInletTemp, RoutineName)
        rhoSourceSide = self.SourcePlantLoc.loop.glycol.getDensity(state, SourceSideInletTemp, RoutineName)
        func1 = ((LoadSideInletTemp + CelsiustoKelvin) / Tref)
        func2 = ((SourceSideInletTemp + CelsiustoKelvin) / Tref)
        func3 = (LoadSideMassFlowRate / (LoadSideVolFlowRateRated * rhoLoadSide))
        func4 = (SourceSideMassFlowRate / (SourceSideVolFlowRateRated * rhoSourceSide))
        QLoad = HeatCapRated * Curve.CurveValue(state, self.HeatCapCurveIndex, func1, func2, func3, func4)
        Power = HeatPowerRated * Curve.CurveValue(state, self.HeatPowCurveIndex, func1, func2, func3, func4)
        if (QLoad <= 0.0 or Power <= 0.0) and not state.dataGlobal.WarmupFlag:
            if QLoad <= 0.0:
                if self.HeatCapNegativeCounter < 1:
                    self.HeatCapNegativeCounter += 1
                    ShowWarningError(state, format("{} \"{}\":", HPEqFitHeating, self.Name))
                    ShowContinueError(state, format(" Heating capacity curve output is <= 0.0 ({:.4f}).", QLoad))
                    ShowContinueError(state, format(" Zero or negative value occurs with a load-side inlet temperature of {:.2f} C,", LoadSideInletTemp))
                    ShowContinueError(state, format(" a source-side inlet temperature of {:.2f} C,", SourceSideInletTemp))
                    ShowContinueError(state, format(" a load-side mass flow rate of {:.3f} kg/s,", LoadSideMassFlowRate))
                    ShowContinueError(state, format(" and a source-side mass flow rate of {:.3f} kg/s.", SourceSideMassFlowRate))
                    ShowContinueErrorTimeStamp(state, " The heat pump is turned off for this time step but simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, HPEqFitHeating + " \"" + self.Name + "\": Heating capacity curve output is <= 0.0 warning continues...", self.HeatCapNegativeIndex, QLoad, QLoad)
            if Power <= 0.0:
                if self.HeatPowerNegativeCounter < 1:
                    self.HeatPowerNegativeCounter += 1
                    ShowWarningError(state, format("{} \"{}\":", HPEqFitHeating, self.Name))
                    ShowContinueError(state, format(" Heating compressor power curve output is <= 0.0 ({:.4f}).", Power))
                    ShowContinueError(state, format(" Zero or negative value occurs with a load-side inlet temperature of {:.2f} C,", LoadSideInletTemp))
                    ShowContinueError(state, format(" a source-side inlet temperature of {:.2f} C,", SourceSideInletTemp))
                    ShowContinueError(state, format(" a load-side mass flow rate of {:.3f} kg/s,", LoadSideMassFlowRate))
                    ShowContinueError(state, format(" and a source-side mass flow rate of {:.3f} kg/s.", SourceSideMassFlowRate))
                    ShowContinueErrorTimeStamp(state, " The heat pump is turned off for this time step but simulation continues.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, HPEqFitHeating + " \"" + self.Name + "\": Heating compressor power curve output is <= 0.0 warning continues...", self.HeatPowerNegativeIndex, Power, Power)
            QLoad = 0.0
            Power = 0.0
        QSource = QLoad - Power
        if abs(MyLoad) < QLoad and QLoad != 0.0:
            PartLoadRatio = abs(MyLoad) / QLoad
            QLoad = abs(MyLoad)
            Power *= PartLoadRatio
            QSource *= PartLoadRatio
        CpLoadSide = self.LoadPlantLoc.loop.glycol.getSpecificHeat(state, LoadSideInletTemp, RoutineName)
        CpSourceSide = self.SourcePlantLoc.loop.glycol.getSpecificHeat(state, SourceSideInletTemp, RoutineName)
        LoadSideOutletTemp = LoadSideInletTemp + QLoad / (LoadSideMassFlowRate * CpLoadSide)
        SourceSideOutletTemp = SourceSideInletTemp - QSource / (SourceSideMassFlowRate * CpSourceSide)
        self.reportPower = Power
        self.reportEnergy = Power * TimeStepSysSec
        self.reportQSource = QSource
        self.reportQLoad = QLoad
        self.reportQSourceEnergy = QSource * TimeStepSysSec
        self.reportQLoadEnergy = QLoad * TimeStepSysSec
        self.reportLoadSideOutletTemp = LoadSideOutletTemp
        self.reportSourceSideOutletTemp = SourceSideOutletTemp

    def GshpSpecs_UpdateGSHPRecords(self: GshpSpecs, state: EnergyPlusData):
        var LoadSideOutletNode: Int = self.LoadSideOutletNodeNum
        var SourceSideOutletNode: Int = self.SourceSideOutletNodeNum
        if not self.MustRun:
            self.reportPower = 0.0
            self.reportEnergy = 0.0
            self.reportQSource = 0.0
            self.reportQSourceEnergy = 0.0
            self.reportQLoad = 0.0
            self.reportQLoadEnergy = 0.0
            self.reportLoadSideOutletTemp = self.reportLoadSideInletTemp
            self.reportSourceSideOutletTemp = self.reportSourceSideInletTemp
        state.dataLoopNodes.Node[SourceSideOutletNode - 1].Temp = self.reportSourceSideOutletTemp
        state.dataLoopNodes.Node[LoadSideOutletNode - 1].Temp = self.reportLoadSideOutletTemp

    def GshpSpecs_oneTimeInit(self: GshpSpecs, state: EnergyPlusData):

    def GshpSpecs_oneTimeInit_new(self: GshpSpecs, state: EnergyPlusData):

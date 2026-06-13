# Mojo translation of EnergyPlus GroundHeatExchangers::Base
# Faithful 1:1 translation, no refactoring

from EnergyPlus.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataLoopNode import Node
from EnergyPlus.DataSystemVariables import ... # Not used explicitly
from EnergyPlus.GroundHeatExchangers.State import dataGroundHeatExchanger
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor
from EnergyPlus.Plant.DataPlant import PlantLoop, PlantEquipmentType
from EnergyPlus.PlantUtilities import SafeCopyPlantNode
from Properties import ThermophysicalProps, PipeProps
from ResponseFactors import GLHEResponseFactors
from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel import BaseGroundTempsModel
from EnergyPlus.Plant.PlantLocation import PlantLocation
from EnergyPlus.PlantComponent import PlantComponent
from EnergyPlus.OutputProcessor import SetupOutputVariable, OutputProcessor, TimeStepType, StoreType
from EnergyPlus.UtilityRoutines import ShowWarningError, ShowContinueError, ShowFatalError
from EnergyPlus.UtilityRoutines import format
from EnergyPlus.UtilityRoutines import makeUPPER as Util_makeUPPER
from EnergyPlus.Constants import Pi, iHoursInDay, Units

# Constants not defined in source - assume available
alias hrsPerMonth = 730.0  # Not defined in provided code; used in functions

# Helper function eoshift for List[Float64]
def eoshift_float64(arr: List[Float64], shift: Int, fill: Float64) -> List[Float64]:
    var n = len(arr)
    var result = List[Float64](n, fill)
    if shift < 0:
        # shift right (negative)
        var absShift = -shift
        for i in range(n - absShift):
            result[i + absShift] = arr[i]
    else:
        # shift left (positive)
        for i in range(n - shift):
            result[i] = arr[i + shift]
    return result

# Helper eoshift for List[Int]
def eoshift_int(arr: List[Int], shift: Int, fill: Int) -> List[Int]:
    var n = len(arr)
    var result = List[Int](n, fill)
    if shift < 0:
        var absShift = -shift
        for i in range(n - absShift):
            result[i + absShift] = arr[i]
    else:
        for i in range(n - shift):
            result[i] = arr[i + shift]
    return result

# Import GLHE types used in GetGroundHeatExchangerInput
# These are defined elsewhere; we assume they exist.
# We will not define them here as they are not part of this file.
# The factory method uses them, but we keep the code verbatim.
from Vertical import GLHEVert
from Slinky import GLHESlinky
from EnergyPlus.GroundHeatExchangers.VertArray import GLHEVertArray
from EnergyPlus.GroundHeatExchangers.VertProps import GLHEVertProps
from EnergyPlus.GroundHeatExchangers.VertSingle import GLHEVertSingle

# Namespace replacement: use module GroundHeatExchangers
# All structs and functions will be inside a module.
# To match C++ namespace, we define a module with the same name.

# We need to define the GLHEBase struct that inherits from PlantComponent trait.
# PlantComponent is a trait (interface). We'll define GLHEBase as struct implementing PlantComponent.

# struct GLHEBase
struct GLHEBase(PlantComponent):
    # Data members
    var available: Bool = False  # load identifier of available equipment
    var on: Bool = False         # simulate the machine at it's operating part load ratio
    var name: String             # user identifier
    var plantLoc: PlantLocation
    var inletNodeNum: Int = 0
    var outletNodeNum: Int = 0
    var soil: ThermophysicalProps
    var pipe: PipeProps
    var grout: ThermophysicalProps
    var designFlow: Float64 = 0.0
    var designMassFlow: Float64 = 0.0
    var tempGround: Float64 = 0.0
    var QnMonthlyAgg: List[Float64]
    var QnHr: List[Float64]
    var QnSubHr: List[Float64]
    var prevHour: Int = 1
    var AGG: Int = 0
    var SubAGG: Int = 0
    var LastHourN: List[Int]
    var bhTemp: Float64 = 0.0
    var massFlowRate: Float64 = 0.0
    var outletTemp: Float64 = 0.0
    var inletTemp: Float64 = 0.0
    var aveFluidTemp: Float64 = 0.0
    var QGLHE: Float64 = 0.0
    var myEnvrnFlag: Bool = True
    var gFunctionsExist: Bool = False
    var lastQnSubHr: Float64 = 0.0
    var HXResistance: Float64 = 0.0
    var totalTubeLength: Float64 = 0.0
    var timeSS: Float64 = 0.0
    var timeSSFactor: Float64 = 0.0
    var myRespFactors: Pointer[GLHEResponseFactors]
    var groundTempModel: Pointer[BaseGroundTempsModel] = None
    var firstTime: Bool = True
    var numErrorCalls: Int = 0
    var ToutNew: Float64 = 19.375
    var PrevN: Int = 1
    var updateCurSimTime: Bool = True
    var triggerDesignDayReset: Bool = False
    var needToSetupOutputVars: Bool = True
    var runGheDesigner: Bool = True
    var N: Int = 1
    var currentSimTime: Float64 = 0.0
    var locHourOfDay: Int = 0
    var locDayOfSim: Int = 0
    var prevTimeSteps: List[Float64]

    # Constructor? Mojo struct requires constructor. We provide default.
    # We'll define an __init__ that initializes all fields to avoid uninit.
    def __init__(inout self):
        self.name = ""
        self.plantLoc = PlantLocation()
        self.soil = ThermophysicalProps()
        self.pipe = PipeProps()
        self.grout = ThermophysicalProps()
        self.QnMonthlyAgg = List[Float64]()
        self.QnHr = List[Float64]()
        self.QnSubHr = List[Float64]()
        self.LastHourN = List[Int]()
        self.prevTimeSteps = List[Float64]()
        self.myRespFactors = Pointer[GLHEResponseFactors]()  # null
        self.groundTempModel = Pointer[BaseGroundTempsModel]()  # null

    # Virtual methods (trait methods)
    # calcGFunctions is pure virtual; we define as trait requirement.
    # We need to declare them as method signatures in the struct.
    # In Mojo, we can use trait definitions. For simplicity, we will define them as regular methods that can be overridden in subclasses? Mojo doesn't have runtime polymorphism like C++ virtual. However, we keep the structure as closely as possible. We'll declare them as methods. Since this is a 1:1 translation, we will keep the keyword as comments and define the methods. They may be overridden by subclasses via trait. We won't worry about exact behavior.

    # def calcGFunctions(inout self, inout state: EnergyPlusData)  # pure # We'll define it empty and let subclasses override.
    # But we need to satisfy the trait PlantComponent. We'll implement the required methods.

    # Required from PlantComponent trait (from header)
    def onInitLoopEquip(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation):
        # Implementation from .cc
        self.initGLHESimVars(state)

    def simulate(inout self, inout state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, inout CurLoad: Float64, RunFlag: Bool):
        # Implementation from .cc
        if self.needToSetupOutputVars:
            self.setupOutput(state)
            self.needToSetupOutputVars = False
        self.initGLHESimVars(state)
        if state.dataGlobal.KickOffSimulation:
            return
        self.calcGroundHeatExchanger(state)
        self.updateGHX(state)

    # Additional methods
    def calcGroundHeatExchanger(inout self, inout state: EnergyPlusData):
        alias RoutineName = "CalcGroundHeatExchanger"
        var fluidAveTemp: Float64
        var tmpQnSubHourly: Float64
        var sumTotal: Float64 = 0.0
        if self.firstTime:
            if not self.gFunctionsExist:
                self.calcGFunctions(state)
                self.gFunctionsExist = True
            self.firstTime = False
        self.inletTemp = state.dataLoopNodes.Node[self.inletNodeNum].Temp
        var cpFluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, RoutineName)
        var kGroundFactor = 2.0 * Pi * self.soil.k
        self.getAnnualTimeConstant()
        if self.triggerDesignDayReset and state.dataGlobal.WarmupFlag:
            self.updateCurSimTime = True
        if state.dataGlobal.DayOfSim == 1 and self.updateCurSimTime:
            self.currentSimTime = 0.0
            self.prevTimeSteps = List[Float64]()  # reset
            self.QnHr = List[Float64]()
            self.QnMonthlyAgg = List[Float64]()
            self.QnSubHr = List[Float64]()
            self.LastHourN = List[Int]()
            self.N = 1
            self.updateCurSimTime = False
            self.triggerDesignDayReset = False
        self.currentSimTime = (state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.HourOfDay - 1 + \
                              (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed
        self.locHourOfDay = Int(mod(self.currentSimTime, iHoursInDay) + 1)
        self.locDayOfSim = Int(self.currentSimTime / 24 + 1)
        if state.dataGlobal.DayOfSim > 1:
            self.updateCurSimTime = True
        if not state.dataGlobal.WarmupFlag:
            self.triggerDesignDayReset = True
        if self.currentSimTime <= 0.0:
            # self.prevTimeSteps should be set to zero - but we need to handle array assignment
            # In C++: this->prevTimeSteps = 0.0; meaning all elements set to 0.0
            # We'll assume prevTimeSteps is a list; set all to 0.0
            for i in range(len(self.prevTimeSteps)):
                self.prevTimeSteps[i] = 0.0
            self.calcAggregateLoad(state)
            return
        # Note: prevTimeSteps(1) is 1-indexed; mojo 0-indexed: self.prevTimeSteps[0]
        if len(self.prevTimeSteps) > 0 and self.prevTimeSteps[0] != self.currentSimTime:
            # eoshift with -1: shift right, fill with currentSimTime
            self.prevTimeSteps = eoshift_float64(self.prevTimeSteps, -1, self.currentSimTime)
            self.N += 1
        if self.N != self.PrevN:
            self.PrevN = self.N
            # eoshift QnSubHr with -1, fill with lastQnSubHr
            self.QnSubHr = eoshift_float64(self.QnSubHr, -1, self.lastQnSubHr)
        self.calcAggregateLoad(state)
        self.HXResistance = self.calcHXResistance(state)
        if self.N == 1:
            if self.massFlowRate <= 0.0:
                tmpQnSubHourly = 0.0
                fluidAveTemp = self.tempGround
                self.ToutNew = self.inletTemp
            else:
                var gFuncVal = self.getGFunc(self.currentSimTime / (self.timeSSFactor))
                var C_1 = (self.totalTubeLength) / (2.0 * self.massFlowRate * cpFluid)
                tmpQnSubHourly = (self.tempGround - self.inletTemp) / (gFuncVal / (kGroundFactor) + self.HXResistance + C_1)
                fluidAveTemp = self.tempGround - tmpQnSubHourly * self.HXResistance
                self.ToutNew = self.tempGround - tmpQnSubHourly * (gFuncVal / (kGroundFactor) + self.HXResistance - C_1)
        else:
            if self.currentSimTime < (hrsPerMonth + self.AGG + self.SubAGG):
                var sumQnSubHourly: Float64 = 0.0
                var IndexN: Int
                if Int(self.currentSimTime) < self.SubAGG:
                    IndexN = Int(self.currentSimTime) + 1
                else:
                    IndexN = self.SubAGG + 1
                var subHourlyLimit = self.N - self.LastHourN[IndexN - 1]  # 0-indexed
                for I in range(1, subHourlyLimit + 1):
                    if I == subHourlyLimit:
                        if Int(self.currentSimTime) >= self.SubAGG:
                            var gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I + 1 - 1]) / (self.timeSSFactor))  # prevTimeSteps(I+1)
                            var RQSubHr = gFuncVal / (kGroundFactor)
                            sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnHr[IndexN - 1]) * RQSubHr
                        else:
                            var gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I + 1 - 1]) / (self.timeSSFactor))
                            var RQSubHr = gFuncVal / (kGroundFactor)
                            sumQnSubHourly += self.QnSubHr[I - 1] * RQSubHr
                        break
                    var gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I + 1 - 1]) / (self.timeSSFactor))
                    var RQSubHr = gFuncVal / (kGroundFactor)
                    sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnSubHr[I + 1 - 1]) * RQSubHr  # QnSubHr(I) - QnSubHr(I+1)
                var sumQnHourly: Float64 = 0.0
                var hourlyLimit = Int(self.currentSimTime)
                for I in range(self.SubAGG + 1, hourlyLimit + 1):
                    if I == hourlyLimit:
                        var gFuncVal = self.getGFunc(self.currentSimTime / (self.timeSSFactor))
                        var RQHour = gFuncVal / (kGroundFactor)
                        sumQnHourly += self.QnHr[I - 1] * RQHour
                        break
                    var gFuncVal = self.getGFunc((self.currentSimTime - Int(self.currentSimTime) + I) / (self.timeSSFactor))
                    var RQHour = gFuncVal / (kGroundFactor)
                    sumQnHourly += (self.QnHr[I - 1] - self.QnHr[I + 1 - 1]) * RQHour  # QnHr(I) - QnHr(I+1)
                sumTotal = sumQnSubHourly + sumQnHourly
                var gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[2 - 1]) / (self.timeSSFactor))  # prevTimeSteps(2)
                var RQSubHr = gFuncVal / kGroundFactor
                if self.massFlowRate <= 0.0:
                    tmpQnSubHourly = 0.0
                    fluidAveTemp = self.tempGround - sumTotal
                    self.ToutNew = self.inletTemp
                else:
                    var C0 = RQSubHr
                    var C1 = self.tempGround - (sumTotal - self.QnSubHr[1 - 1] * RQSubHr)  # QnSubHr(1)
                    var C2 = self.totalTubeLength / (2.0 * self.massFlowRate * cpFluid)
                    var C3 = self.massFlowRate * cpFluid / (self.totalTubeLength)
                    tmpQnSubHourly = (C1 - self.inletTemp) / (self.HXResistance + C0 - C2 + (1 / C3))
                    fluidAveTemp = C1 - (C0 + self.HXResistance) * tmpQnSubHourly
                    self.ToutNew = C1 + (C2 - C0 - self.HXResistance) * tmpQnSubHourly
            else:
                var numOfMonths = Int((self.currentSimTime + 1) / hrsPerMonth)
                var currentMonth: Int
                if self.currentSimTime < (numOfMonths * hrsPerMonth + self.AGG + self.SubAGG):
                    currentMonth = numOfMonths - 1
                else:
                    currentMonth = numOfMonths
                var sumQnMonthly: Float64 = 0.0
                for I in range(1, currentMonth + 1):
                    if I == 1:
                        var gFuncVal = self.getGFunc(self.currentSimTime / (self.timeSSFactor))
                        var RQMonth = gFuncVal / (kGroundFactor)
                        sumQnMonthly += self.QnMonthlyAgg[I - 1] * RQMonth
                        continue
                    var gFuncVal = self.getGFunc((self.currentSimTime - (I - 1) * hrsPerMonth) / (self.timeSSFactor))
                    var RQMonth = gFuncVal / (kGroundFactor)
                    sumQnMonthly += (self.QnMonthlyAgg[I - 1] - self.QnMonthlyAgg[I - 1 - 1]) * RQMonth
                var sumQnHourly: Float64 = 0.0
                var hourlyLimit = Int(self.currentSimTime - currentMonth * hrsPerMonth)
                for I in range(1 + self.SubAGG, hourlyLimit + 1):
                    if I == hourlyLimit:
                        var gFuncVal = self.getGFunc((self.currentSimTime - Int(self.currentSimTime) + I) / (self.timeSSFactor))
                        var RQHour = gFuncVal / (kGroundFactor)
                        sumQnHourly += (self.QnHr[I - 1] - self.QnMonthlyAgg[currentMonth - 1]) * RQHour
                        break
                    var gFuncVal = self.getGFunc((self.currentSimTime - Int(self.currentSimTime) + I) / (self.timeSSFactor))
                    var RQHour = gFuncVal / (kGroundFactor)
                    sumQnHourly += (self.QnHr[I - 1] - self.QnHr[I + 1 - 1]) * RQHour
                var subHourlyLimit = self.N - self.LastHourN[self.SubAGG + 1 - 1]  # LastHourN(SubAGG+1)
                var sumQnSubHourly: Float64 = 0.0
                for I in range(1, subHourlyLimit + 1):
                    if I == subHourlyLimit:
                        var gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I + 1 - 1]) / (self.timeSSFactor))
                        var RQSubHr = gFuncVal / (kGroundFactor)
                        sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnHr[self.SubAGG + 1 - 1]) * RQSubHr
                        break
                    var gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I + 1 - 1]) / (self.timeSSFactor))
                    var RQSubHr = gFuncVal / (kGroundFactor)
                    sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnSubHr[I + 1 - 1]) * RQSubHr
                sumTotal = sumQnMonthly + sumQnHourly + sumQnSubHourly
                var gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[2 - 1]) / (self.timeSSFactor))
                var RQSubHr = gFuncVal / (kGroundFactor)
                if self.massFlowRate <= 0.0:
                    tmpQnSubHourly = 0.0
                    fluidAveTemp = self.tempGround - sumTotal
                    self.ToutNew = self.inletTemp
                else:
                    var C0 = RQSubHr
                    var C1 = self.tempGround - (sumTotal - self.QnSubHr[1 - 1] * RQSubHr)
                    var C2 = self.totalTubeLength / (2 * self.massFlowRate * cpFluid)
                    var C3 = self.massFlowRate * cpFluid / (self.totalTubeLength)
                    tmpQnSubHourly = (C1 - self.inletTemp) / (self.HXResistance + C0 - C2 + (1 / C3))
                    fluidAveTemp = C1 - (C0 + self.HXResistance) * tmpQnSubHourly
                    self.ToutNew = C1 + (C2 - C0 - self.HXResistance) * tmpQnSubHourly
        self.bhTemp = self.tempGround - sumTotal
        self.lastQnSubHr = tmpQnSubHourly
        self.outletTemp = self.ToutNew
        self.QGLHE = tmpQnSubHourly * self.totalTubeLength
        self.aveFluidTemp = fluidAveTemp

    def updateGHX(inout self, inout state: EnergyPlusData):
        alias RoutineName = "UpdateGroundHeatExchanger"
        alias deltaTempLimit = 100.0
        SafeCopyPlantNode(state, self.inletNodeNum, self.outletNodeNum)
        state.dataLoopNodes.Node[self.outletNodeNum].Temp = self.outletTemp
        state.dataLoopNodes.Node[self.outletNodeNum].Enthalpy = \
            self.outletTemp * state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.outletTemp, RoutineName)
        var GLHEDeltaTemp = abs(self.outletTemp - self.inletTemp)
        if GLHEDeltaTemp > deltaTempLimit and self.numErrorCalls < state.dataGroundHeatExchanger.numVerticalGLHEs and not state.dataGlobal.WarmupFlag:
            var fluidDensity = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, self.inletTemp, RoutineName)
            self.designMassFlow = self.designFlow * fluidDensity
            ShowWarningError(state, "Check GLHE design inputs & g-functions for consistency")
            ShowContinueError(state, format("For GroundHeatExchanger: {} GLHE delta Temp > 100C.", self.name))
            ShowContinueError(state, "This can be encountered in cases where the GLHE mass flow rate is either significantly")
            ShowContinueError(state, " lower than the design value, or cases where the mass flow rate rapidly changes.")
            ShowContinueError(state, format("GLHE Current Flow Rate={:.3f}; GLHE Design Flow Rate={:.3f}", self.massFlowRate, self.designMassFlow))
            self.numErrorCalls += 1

    def calcAggregateLoad(inout self, inout state: EnergyPlusData):
        if self.currentSimTime <= 0.0:
            return
        if self.prevHour != self.locHourOfDay:
            var SumQnHr: Float64 = 0.0
            var J: Int
            for J in range(1, (self.N - self.LastHourN[1 - 1]) + 1):
                SumQnHr += self.QnSubHr[J - 1] * abs(self.prevTimeSteps[J - 1] - self.prevTimeSteps[J + 1 - 1])  # J+1
            if self.prevTimeSteps[1 - 1] != self.prevTimeSteps[J - 1]:
                SumQnHr /= abs(self.prevTimeSteps[1 - 1] - self.prevTimeSteps[J - 1])
            else:
                SumQnHr /= 0.05
            self.QnHr = eoshift_float64(self.QnHr, -1, SumQnHr)
            self.LastHourN = eoshift_int(self.LastHourN, -1, self.N)
        if mod(((self.locDayOfSim - 1) * iHoursInDay + self.locHourOfDay), hrsPerMonth) == 0 and self.prevHour != self.locHourOfDay:
            var MonthNum = Int((self.locDayOfSim * iHoursInDay + self.locHourOfDay) / hrsPerMonth)
            var SumQnMonth: Float64 = 0.0
            for J in range(1, Int(hrsPerMonth) + 1):
                SumQnMonth += self.QnHr[J - 1]
            SumQnMonth /= hrsPerMonth
            self.QnMonthlyAgg[MonthNum - 1] = SumQnMonth
        self.prevHour = self.locHourOfDay

    def onInitLoopEquip(mut self, mut state: EnergyPlusData, calledFromLocation: PlantLocation):
        self.initGLHESimVars(state)

    def simulate(mut self, mut state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, mut CurLoad: Float64, RunFlag: Bool):
        if self.needToSetupOutputVars:
            self.setupOutput(state)
            self.needToSetupOutputVars = False
        self.initGLHESimVars(state)
        if state.dataGlobal.KickOffSimulation:
            return
        self.calcGroundHeatExchanger(state)
        self.updateGHX(state)

    @staticmethod
    def factory(mut state: EnergyPlusData, objectType: PlantEquipmentType, objectName: String) -> Pointer[GLHEBase]:
        if state.dataGroundHeatExchanger.GetInput:
            GetGroundHeatExchangerInput(state)
            state.dataGroundHeatExchanger.GetInput = False
        if objectType == PlantEquipmentType.GrndHtExchgSystem:
            # Use Python style find
            for myObj in state.dataGroundHeatExchanger.verticalGLHE:
                if myObj.name == objectName:
                    return Pointer[GLHEBase](address_of(myObj))  # careful with lifetime
            # Not found
        elif objectType == PlantEquipmentType.GrndHtExchgSlinky:
            for myObj in state.dataGroundHeatExchanger.slinkyGLHE:
                if myObj.name == objectName:
                    return Pointer[GLHEBase](address_of(myObj))
        ShowFatalError(state, format("Ground Heat Exchanger Factory: Error getting inputs for GHX named: {}", objectName))
        return Pointer[GLHEBase]()  # unreachable

    def setupOutput(mut self, mut state: EnergyPlusData):
        SetupOutputVariable(state, "Ground Heat Exchanger Average Borehole Temperature", Units.C, self.bhTemp, TimeStepType.System, StoreType.Average, self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Heat Transfer Rate", Units.W, self.QGLHE, TimeStepType.System, StoreType.Average, self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Inlet Temperature", Units.C, self.inletTemp, TimeStepType.System, StoreType.Average, self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Outlet Temperature", Units.C, self.outletTemp, TimeStepType.System, StoreType.Average, self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Mass Flow Rate", Units.kg_s, self.massFlowRate, TimeStepType.System, StoreType.Average, self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Average Fluid Temperature", Units.C, self.aveFluidTemp, TimeStepType.System, StoreType.Average, self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Farfield Ground Temperature", Units.C, self.tempGround, TimeStepType.System, StoreType.Average, self.name)

    def interpGFunc(self, x_val: Float64) -> Float64:
        var x = self.myRespFactors.LNTTS
        var y = self.myRespFactors.GFNC
        # upper_bound equivalent
        var upper_idx: Int = 0
        for idx in range(len(x)):
            if x[idx] > x_val:
                upper_idx = idx
                break
        else:
            upper_idx = len(x)  # past end
        var l_idx: Int
        var u_idx: Int
        if upper_idx == 0:
            l_idx = 0
            u_idx = 1
        elif upper_idx == len(x):
            u_idx = len(x) - 1
            l_idx = u_idx - 1
        else:
            u_idx = upper_idx
            l_idx = u_idx - 1
        var x_low = x[l_idx]
        var x_high = x[u_idx]
        var y_low = y[l_idx]
        var y_high = y[u_idx]
        return (x_val - x_low) / (x_high - x_low) * (y_high - y_low) + y_low

# Free function TDMA
def TDMA(a: List[Float64], b: List[Float64], c: List[Float64], d: List[Float64]) -> List[Float64]:
    var n = len(d) - 1
    c[0] /= b[0]
    d[0] /= b[0]
    for i in range(1, n):
        c[i] /= b[i] - a[i] * c[i - 1]
        d[i] = (d[i] - a[i] * d[i - 1]) / (b[i] - a[i] * c[i - 1])
    d[n] = (d[n] - a[n] * d[n - 1]) / (b[n] - a[n] * c[n - 1])
    for i in range(n, 0, -1):
        d[i - 1] -= c[i - 1] * d[i]  # i-- >0 => i from n down to 1
    return d

def GetGroundHeatExchangerInput(inout state: EnergyPlusData):
    state.dataGroundHeatExchanger.numVerticalGLHEs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, GLHEVert.moduleName)
    state.dataGroundHeatExchanger.numSlinkyGLHEs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, GLHESlinky.moduleName)
    state.dataGroundHeatExchanger.numVertArray = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, GLHEVertArray.moduleName)
    state.dataGroundHeatExchanger.numVertProps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, GLHEVertProps.moduleName)
    state.dataGroundHeatExchanger.numResponseFactors = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, GLHEResponseFactors.moduleName)
    state.dataGroundHeatExchanger.numSingleBorehole = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, GLHEVertSingle.moduleName)
    if state.dataGroundHeatExchanger.numVerticalGLHEs <= 0 and state.dataGroundHeatExchanger.numSlinkyGLHEs <= 0:
        ShowSevereError(state, "Error processing inputs for GLHE objects")
        ShowContinueError(state, "Simulation indicated these objects were found, but input processor doesn't find any")
        ShowContinueError(state, "Check inputs for GroundHeatExchanger:System and GroundHeatExchanger:Slinky")
        ShowContinueError(state, "Also check plant/branch inputs for references to invalid/deleted objects")
    if state.dataGroundHeatExchanger.numVertProps > 0:
        var instances = state.dataInputProcessing.inputProcessor.epJSON.get(GLHEVertProps.moduleName)
        if not instances:
            ShowSevereError(state, format("{}: Somehow getNumObjectsFound was > 0 but epJSON.find found 0", GLHEVertProps.moduleName))
        else:
            var instancesValue = instances.value()
            for it in instancesValue.items():
                var instance = it.value
                var objName = it.key
                var objNameUC = Util_makeUPPER(objName)
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(GLHEVertProps.moduleName, objName)
                var thisObj = GLHEVertProps(state, objNameUC, instance)  # create shared_ptr? We'll use pointer
                # We'll store as reference? C++ stores shared_ptr. We'll allocate with new.
                state.dataGroundHeatExchanger.vertPropsVector.append(thisObj)  # Assuming List[GLHEVertProps] (value)
    if state.dataGroundHeatExchanger.numResponseFactors > 0:
        var instances = state.dataInputProcessing.inputProcessor.epJSON.get(GLHEResponseFactors.moduleName)
        if not instances:
            ShowSevereError(state, format("{}: Somehow getNumObjectsFound was > 0 but epJSON.find found 0", GLHEResponseFactors.moduleName))
        else:
            var instancesValue = instances.value()
            for it in instancesValue.items():
                var instance = it.value
                var objName = it.key
                var objNameUC = Util_makeUPPER(objName)
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(GLHEResponseFactors.moduleName, objName)
                var thisObj = GLHEResponseFactors(state, objNameUC, instance)
                state.dataGroundHeatExchanger.responseFactorsVector.append(thisObj)
    if state.dataGroundHeatExchanger.numVertArray > 0:
        var instances = state.dataInputProcessing.inputProcessor.epJSON.get(GLHEVertArray.moduleName)
        if not instances:
            ShowSevereError(state, format("{}: Somehow getNumObjectsFound was > 0 but epJSON.find found 0", GLHEVertArray.moduleName))
        else:
            var instancesValue = instances.value()
            for it in instancesValue.items():
                var instance = it.value
                var objName = it.key
                var objNameUC = Util_makeUPPER(objName)
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(GLHEVertArray.moduleName, objName)
                var thisObj = GLHEVertArray(state, objNameUC, instance)
                state.dataGroundHeatExchanger.vertArraysVector.append(thisObj)
    if state.dataGroundHeatExchanger.numSingleBorehole > 0:
        var instances = state.dataInputProcessing.inputProcessor.epJSON.get(GLHEVertSingle.moduleName)
        if not instances:
            ShowSevereError(state, format("{}: Somehow getNumObjectsFound was > 0 but epJSON.find found 0", GLHEVertSingle.moduleName))
        else:
            var instancesValue = instances.value()
            for it in instancesValue.items():
                var instance = it.value
                var objName = it.key
                var objNameUC = Util_makeUPPER(objName)
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(GLHEVertSingle.moduleName, objName)
                var thisObj = GLHEVertSingle(state, objNameUC, instance)
                state.dataGroundHeatExchanger.singleBoreholesVector.append(thisObj)
    if state.dataGroundHeatExchanger.numVerticalGLHEs > 0:
        var instances = state.dataInputProcessing.inputProcessor.epJSON.get(GLHEVert.moduleName)
        if not instances:
            ShowSevereError(state, format("{}: Somehow getNumObjectsFound was > 0 but epJSON.find found 0", GLHEVert.moduleName))
        else:
            var instancesValue = instances.value()
            for it in instancesValue.items():
                var instance = it.value
                var objName = it.key
                var objNameUC = Util_makeUPPER(objName)
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(GLHEVert.moduleName, objName)
                state.dataGroundHeatExchanger.verticalGLHE.append(GLHEVert(state, objNameUC, instance))  # emplace_back
    if state.dataGroundHeatExchanger.numSlinkyGLHEs > 0:
        var instances = state.dataInputProcessing.inputProcessor.epJSON.get(GLHESlinky.moduleName)
        if not instances:
            ShowSevereError(state, format("{}: Somehow getNumObjectsFound was > 0 but epJSON.find found 0", GLHESlinky.moduleName))
        else:
            var instancesValue = instances.value()
            for it in instancesValue.items():
                var instance = it.value
                var objName = it.key
                var objNameUC = Util_makeUPPER(objName)
                state.dataInputProcessing.inputProcessor.markObjectAsUsed(GLHESlinky.moduleName, objName)
                state.dataGroundHeatExchanger.slinkyGLHE.append(GLHESlinky(state, objNameUC, instance))

# End of file
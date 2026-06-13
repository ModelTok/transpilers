# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus.Data (state object)
# - PlantComponent: from EnergyPlus.Plant (base class)
# - PlantLocation: from EnergyPlus.Plant.PlantLocation
# - ThermophysicalProps: from EnergyPlus.GroundHeatExchangers.Properties
# - PipeProps: from EnergyPlus.GroundHeatExchangers.Properties
# - GLHEResponseFactors: from EnergyPlus.GroundHeatExchangers.ResponseFactors
# - BaseGroundTempsModel: from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel
# - DataPlant.PlantEquipmentType: from EnergyPlus.Plant.DataPlant
# - ShowWarningError, ShowContinueError, ShowFatalError, format: from EnergyPlus.OutputReporting
# - SetupOutputVariable, OutputProcessor: from EnergyPlus.Output.Variable
# - PlantUtilities.SafeCopyPlantNode: from EnergyPlus.Plant.PlantUtilities
# - Constant: from EnergyPlus.Constant
# - Util.makeUPPER: from EnergyPlus.Util
# - GLHEVert, GLHESlinky, GLHEVertArray, GLHEVertProps, GLHEResponseFactors, GLHEVertSingle: from EnergyPlus.GroundHeatExchangers

import math
from typing import Optional, List, Tuple
from dataclasses import dataclass, field


@dataclass
class GLHEBase:
    available: bool = False
    on: bool = False
    name: str = ""
    plantLoc: Optional['PlantLocation'] = None
    inletNodeNum: int = 0
    outletNodeNum: int = 0
    soil: Optional['ThermophysicalProps'] = None
    pipe: Optional['PipeProps'] = None
    grout: Optional['ThermophysicalProps'] = None
    designFlow: float = 0.0
    designMassFlow: float = 0.0
    tempGround: float = 0.0
    QnMonthlyAgg: List[float] = field(default_factory=list)
    QnHr: List[float] = field(default_factory=list)
    QnSubHr: List[float] = field(default_factory=list)
    prevHour: int = 1
    AGG: int = 0
    SubAGG: int = 0
    LastHourN: List[int] = field(default_factory=list)
    bhTemp: float = 0.0
    massFlowRate: float = 0.0
    outletTemp: float = 0.0
    inletTemp: float = 0.0
    aveFluidTemp: float = 0.0
    QGLHE: float = 0.0
    myEnvrnFlag: bool = True
    gFunctionsExist: bool = False
    lastQnSubHr: float = 0.0
    HXResistance: float = 0.0
    totalTubeLength: float = 0.0
    timeSS: float = 0.0
    timeSSFactor: float = 0.0
    myRespFactors: Optional['GLHEResponseFactors'] = None
    groundTempModel: Optional['BaseGroundTempsModel'] = None
    firstTime: bool = True
    numErrorCalls: int = 0
    ToutNew: float = 19.375
    PrevN: int = 1
    updateCurSimTime: bool = True
    triggerDesignDayReset: bool = False
    needToSetupOutputVars: bool = True
    runGheDesigner: bool = True
    N: int = 1
    currentSimTime: float = 0.0
    locHourOfDay: int = 0
    locDayOfSim: int = 0
    prevTimeSteps: List[float] = field(default_factory=list)

    def calcGFunctions(self, state: 'EnergyPlusData') -> None:
        raise NotImplementedError

    def calcAggregateLoad(self, state: 'EnergyPlusData') -> None:
        hrsPerMonth = 730.0
        if self.currentSimTime <= 0.0:
            return
        
        if self.prevHour != self.locHourOfDay:
            SumQnHr = 0.0
            J = 0
            for J in range(self.N - self.LastHourN[0]):
                SumQnHr += self.QnSubHr[J] * abs(self.prevTimeSteps[J] - self.prevTimeSteps[J + 1])
            
            if self.prevTimeSteps[0] != self.prevTimeSteps[J]:
                SumQnHr /= abs(self.prevTimeSteps[0] - self.prevTimeSteps[J])
            else:
                SumQnHr /= 0.05
            
            self.QnHr = self.QnHr[1:] + [SumQnHr]
            self.LastHourN = self.LastHourN[1:] + [self.N]
        
        iHoursInDay = 24
        if ((self.locDayOfSim - 1) * iHoursInDay + self.locHourOfDay) % hrsPerMonth == 0 and self.prevHour != self.locHourOfDay:
            MonthNum = int((self.locDayOfSim * iHoursInDay + self.locHourOfDay) / hrsPerMonth)
            SumQnMonth = 0.0
            for J in range(int(hrsPerMonth)):
                SumQnMonth += self.QnHr[J]
            SumQnMonth /= hrsPerMonth
            self.QnMonthlyAgg[MonthNum] = SumQnMonth
        
        self.prevHour = self.locHourOfDay

    def updateGHX(self, state: 'EnergyPlusData') -> None:
        RoutineName = "UpdateGroundHeatExchanger"
        deltaTempLimit = 100.0
        
        SafeCopyPlantNode(state, self.inletNodeNum, self.outletNodeNum)
        
        state.dataLoopNodes.Node[self.outletNodeNum].Temp = self.outletTemp
        state.dataLoopNodes.Node[self.outletNodeNum].Enthalpy = (
            self.outletTemp * state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.outletTemp, RoutineName)
        )
        
        GLHEDeltaTemp = abs(self.outletTemp - self.inletTemp)
        
        if (GLHEDeltaTemp > deltaTempLimit and 
            self.numErrorCalls < state.dataGroundHeatExchanger.numVerticalGLHEs and 
            not state.dataGlobal.WarmupFlag):
            fluidDensity = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, self.inletTemp, RoutineName)
            self.designMassFlow = self.designFlow * fluidDensity
            ShowWarningError(state, "Check GLHE design inputs & g-functions for consistency")
            ShowContinueError(state, f"For GroundHeatExchanger: {self.name}GLHE delta Temp > 100C.")
            ShowContinueError(state, "This can be encountered in cases where the GLHE mass flow rate is either significantly")
            ShowContinueError(state, " lower than the design value, or cases where the mass flow rate rapidly changes.")
            ShowContinueError(state, f"GLHE Current Flow Rate={self.massFlowRate:.3f}; GLHE Design Flow Rate={self.designMassFlow:.3f}")
            self.numErrorCalls += 1

    def calcGroundHeatExchanger(self, state: 'EnergyPlusData') -> None:
        RoutineName = "CalcGroundHeatExchanger"
        hrsPerMonth = 730.0
        
        if self.firstTime:
            if not self.gFunctionsExist:
                self.calcGFunctions(state)
                self.gFunctionsExist = True
            self.firstTime = False
        
        self.inletTemp = state.dataLoopNodes.Node[self.inletNodeNum].Temp
        
        cpFluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, RoutineName)
        
        kGroundFactor = 2.0 * math.pi * self.soil.k
        
        self.getAnnualTimeConstant()
        
        if self.triggerDesignDayReset and state.dataGlobal.WarmupFlag:
            self.updateCurSimTime = True
        
        iHoursInDay = 24
        if state.dataGlobal.DayOfSim == 1 and self.updateCurSimTime:
            self.currentSimTime = 0.0
            self.prevTimeSteps = [0.0] * len(self.prevTimeSteps)
            self.QnHr = [0.0] * len(self.QnHr)
            self.QnMonthlyAgg = [0.0] * len(self.QnMonthlyAgg)
            self.QnSubHr = [0.0] * len(self.QnSubHr)
            self.LastHourN = [1] * len(self.LastHourN)
            self.N = 1
            self.updateCurSimTime = False
            self.triggerDesignDayReset = False
        
        self.currentSimTime = ((state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.HourOfDay - 1 + 
                              (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed)
        self.locHourOfDay = int((self.currentSimTime % iHoursInDay) + 1)
        self.locDayOfSim = int(self.currentSimTime / 24 + 1)
        
        if state.dataGlobal.DayOfSim > 1:
            self.updateCurSimTime = True
        
        if not state.dataGlobal.WarmupFlag:
            self.triggerDesignDayReset = True
        
        if self.currentSimTime <= 0.0:
            self.prevTimeSteps = [0.0] * len(self.prevTimeSteps)
            self.calcAggregateLoad(state)
            return
        
        if self.prevTimeSteps[0] != self.currentSimTime:
            self.prevTimeSteps = self.prevTimeSteps[1:] + [self.currentSimTime]
            self.N += 1
        
        if self.N != self.PrevN:
            self.PrevN = self.N
            self.QnSubHr = self.QnSubHr[1:] + [self.lastQnSubHr]
        
        self.calcAggregateLoad(state)
        
        self.HXResistance = self.calcHXResistance(state)
        
        sumTotal = 0.0
        fluidAveTemp = 0.0
        tmpQnSubHourly = 0.0
        
        if self.N == 1:
            if self.massFlowRate <= 0.0:
                tmpQnSubHourly = 0.0
                fluidAveTemp = self.tempGround
                self.ToutNew = self.inletTemp
            else:
                gFuncVal = self.getGFunc(self.currentSimTime / self.timeSSFactor)
                C_1 = self.totalTubeLength / (2.0 * self.massFlowRate * cpFluid)
                tmpQnSubHourly = ((self.tempGround - self.inletTemp) / 
                                 (gFuncVal / kGroundFactor + self.HXResistance + C_1))
                fluidAveTemp = self.tempGround - tmpQnSubHourly * self.HXResistance
                self.ToutNew = self.tempGround - tmpQnSubHourly * (gFuncVal / kGroundFactor + self.HXResistance - C_1)
        else:
            if self.currentSimTime < (hrsPerMonth + self.AGG + self.SubAGG):
                sumQnSubHourly = 0.0
                if int(self.currentSimTime) < self.SubAGG:
                    IndexN = int(self.currentSimTime) + 1
                else:
                    IndexN = self.SubAGG + 1
                
                subHourlyLimit = self.N - self.LastHourN[IndexN - 1]
                for I in range(1, subHourlyLimit + 1):
                    if I == subHourlyLimit:
                        if int(self.currentSimTime) >= self.SubAGG:
                            gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                            RQSubHr = gFuncVal / kGroundFactor
                            sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnHr[IndexN - 1]) * RQSubHr
                        else:
                            gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                            RQSubHr = gFuncVal / kGroundFactor
                            sumQnSubHourly += self.QnSubHr[I - 1] * RQSubHr
                        break
                    gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                    RQSubHr = gFuncVal / kGroundFactor
                    sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnSubHr[I]) * RQSubHr
                
                sumQnHourly = 0.0
                hourlyLimit = int(self.currentSimTime)
                for I in range(self.SubAGG + 1, hourlyLimit + 1):
                    if I == hourlyLimit:
                        gFuncVal = self.getGFunc(self.currentSimTime / self.timeSSFactor)
                        RQHour = gFuncVal / kGroundFactor
                        sumQnHourly += self.QnHr[I - 1] * RQHour
                        break
                    gFuncVal = self.getGFunc((self.currentSimTime - int(self.currentSimTime) + I) / self.timeSSFactor)
                    RQHour = gFuncVal / kGroundFactor
                    sumQnHourly += (self.QnHr[I - 1] - self.QnHr[I]) * RQHour
                
                sumTotal = sumQnSubHourly + sumQnHourly
                
                gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[1]) / self.timeSSFactor)
                RQSubHr = gFuncVal / kGroundFactor
                
                if self.massFlowRate <= 0.0:
                    tmpQnSubHourly = 0.0
                    fluidAveTemp = self.tempGround - sumTotal
                    self.ToutNew = self.inletTemp
                else:
                    C0 = RQSubHr
                    C1 = self.tempGround - (sumTotal - self.QnSubHr[0] * RQSubHr)
                    C2 = self.totalTubeLength / (2.0 * self.massFlowRate * cpFluid)
                    C3 = self.massFlowRate * cpFluid / self.totalTubeLength
                    tmpQnSubHourly = (C1 - self.inletTemp) / (self.HXResistance + C0 - C2 + (1 / C3))
                    fluidAveTemp = C1 - (C0 + self.HXResistance) * tmpQnSubHourly
                    self.ToutNew = C1 + (C2 - C0 - self.HXResistance) * tmpQnSubHourly
            else:
                numOfMonths = int((self.currentSimTime + 1) / hrsPerMonth)
                
                if self.currentSimTime < (numOfMonths * hrsPerMonth + self.AGG + self.SubAGG):
                    currentMonth = numOfMonths - 1
                else:
                    currentMonth = numOfMonths
                
                sumQnMonthly = 0.0
                for I in range(1, currentMonth + 1):
                    if I == 1:
                        gFuncVal = self.getGFunc(self.currentSimTime / self.timeSSFactor)
                        RQMonth = gFuncVal / kGroundFactor
                        sumQnMonthly += self.QnMonthlyAgg[I - 1] * RQMonth
                        continue
                    gFuncVal = self.getGFunc((self.currentSimTime - (I - 1) * hrsPerMonth) / self.timeSSFactor)
                    RQMonth = gFuncVal / kGroundFactor
                    sumQnMonthly += (self.QnMonthlyAgg[I - 1] - self.QnMonthlyAgg[I - 2]) * RQMonth
                
                sumQnHourly = 0.0
                hourlyLimit = int(self.currentSimTime - currentMonth * hrsPerMonth)
                for I in range(1 + self.SubAGG, hourlyLimit + 1):
                    if I == hourlyLimit:
                        gFuncVal = self.getGFunc((self.currentSimTime - int(self.currentSimTime) + I) / self.timeSSFactor)
                        RQHour = gFuncVal / kGroundFactor
                        sumQnHourly += (self.QnHr[I - 1] - self.QnMonthlyAgg[currentMonth - 1]) * RQHour
                        break
                    gFuncVal = self.getGFunc((self.currentSimTime - int(self.currentSimTime) + I) / self.timeSSFactor)
                    RQHour = gFuncVal / kGroundFactor
                    sumQnHourly += (self.QnHr[I - 1] - self.QnHr[I]) * RQHour
                
                subHourlyLimit = self.N - self.LastHourN[self.SubAGG]
                sumQnSubHourly = 0.0
                for I in range(1, subHourlyLimit + 1):
                    if I == subHourlyLimit:
                        gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                        RQSubHr = gFuncVal / kGroundFactor
                        sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnHr[self.SubAGG]) * RQSubHr
                        break
                    gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                    RQSubHr = gFuncVal / kGroundFactor
                    sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnSubHr[I]) * RQSubHr
                
                sumTotal = sumQnMonthly + sumQnHourly + sumQnSubHourly
                
                gFuncVal = self.getGFunc((self.currentSimTime - self.prevTimeSteps[1]) / self.timeSSFactor)
                RQSubHr = gFuncVal / kGroundFactor
                
                if self.massFlowRate <= 0.0:
                    tmpQnSubHourly = 0.0
                    fluidAveTemp = self.tempGround - sumTotal
                    self.ToutNew = self.inletTemp
                else:
                    C0 = RQSubHr
                    C1 = self.tempGround - (sumTotal - self.QnSubHr[0] * RQSubHr)
                    C2 = self.totalTubeLength / (2 * self.massFlowRate * cpFluid)
                    C3 = self.massFlowRate * cpFluid / self.totalTubeLength
                    tmpQnSubHourly = (C1 - self.inletTemp) / (self.HXResistance + C0 - C2 + (1 / C3))
                    fluidAveTemp = C1 - (C0 + self.HXResistance) * tmpQnSubHourly
                    self.ToutNew = C1 + (C2 - C0 - self.HXResistance) * tmpQnSubHourly
        
        self.bhTemp = self.tempGround - sumTotal
        self.lastQnSubHr = tmpQnSubHourly
        self.outletTemp = self.ToutNew
        self.QGLHE = tmpQnSubHourly * self.totalTubeLength
        self.aveFluidTemp = fluidAveTemp

    @staticmethod
    def isEven(val: int) -> bool:
        return val % 2 == 0

    def interpGFunc(self, x_val: float) -> float:
        x = self.myRespFactors.LNTTS
        y = self.myRespFactors.GFNC
        
        l_idx = 0
        u_idx = 0
        
        if x_val < x[0]:
            l_idx = 0
            u_idx = 1
        elif x_val >= x[-1]:
            u_idx = len(x) - 1
            l_idx = u_idx - 1
        else:
            for i in range(len(x) - 1):
                if x[i] <= x_val < x[i + 1]:
                    l_idx = i
                    u_idx = i + 1
                    break
        
        x_low = x[l_idx]
        x_high = x[u_idx]
        y_low = y[l_idx]
        y_high = y[u_idx]
        
        return (x_val - x_low) / (x_high - x_low) * (y_high - y_low) + y_low

    def onInitLoopEquip(self, state: 'EnergyPlusData', calledFromLocation: 'PlantLocation') -> None:
        self.initGLHESimVars(state)

    def simulate(self, state: 'EnergyPlusData', calledFromLocation: 'PlantLocation',
                FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        if self.needToSetupOutputVars:
            self.setupOutput(state)
            self.needToSetupOutputVars = False
        
        self.initGLHESimVars(state)
        if state.dataGlobal.KickOffSimulation:
            return
        
        self.calcGroundHeatExchanger(state)
        self.updateGHX(state)

    @staticmethod
    def factory(state: 'EnergyPlusData', objectType: 'DataPlant.PlantEquipmentType', objectName: str) -> 'GLHEBase':
        if state.dataGroundHeatExchanger.GetInput:
            GetGroundHeatExchangerInput(state)
            state.dataGroundHeatExchanger.GetInput = False
        
        if objectType == 'GrndHtExchgSystem':
            for obj in state.dataGroundHeatExchanger.verticalGLHE:
                if obj.name == objectName:
                    return obj
        elif objectType == 'GrndHtExchgSlinky':
            for obj in state.dataGroundHeatExchanger.slinkyGLHE:
                if obj.name == objectName:
                    return obj
        
        ShowFatalError(state, f"Ground Heat Exchanger Factory: Error getting inputs for GHX named: {objectName}")

    def getGFunc(self, x: float) -> float:
        raise NotImplementedError

    def initGLHESimVars(self, state: 'EnergyPlusData') -> None:
        raise NotImplementedError

    def calcHXResistance(self, state: 'EnergyPlusData') -> float:
        raise NotImplementedError

    def getAnnualTimeConstant(self) -> None:
        raise NotImplementedError

    def initEnvironment(self, state: 'EnergyPlusData', CurTime: float) -> None:
        raise NotImplementedError

    def setupOutput(self, state: 'EnergyPlusData') -> None:
        SetupOutputVariable(state, "Ground Heat Exchanger Average Borehole Temperature", "C",
                           self.bhTemp, "System", "Average", self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Heat Transfer Rate", "W",
                           self.QGLHE, "System", "Average", self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Inlet Temperature", "C",
                           self.inletTemp, "System", "Average", self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Outlet Temperature", "C",
                           self.outletTemp, "System", "Average", self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Mass Flow Rate", "kg/s",
                           self.massFlowRate, "System", "Average", self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Average Fluid Temperature", "C",
                           self.aveFluidTemp, "System", "Average", self.name)
        SetupOutputVariable(state, "Ground Heat Exchanger Farfield Ground Temperature", "C",
                           self.tempGround, "System", "Average", self.name)


def TDMA(a: List[float], b: List[float], c: List[float], d: List[float]) -> List[float]:
    n = len(d) - 1
    c = c.copy()
    d = d.copy()
    
    c[0] /= b[0]
    d[0] /= b[0]
    
    for i in range(1, n):
        c[i] /= b[i] - a[i] * c[i - 1]
        d[i] = (d[i] - a[i] * d[i - 1]) / (b[i] - a[i] * c[i - 1])
    
    d[n] = (d[n] - a[n] * d[n - 1]) / (b[n] - a[n] * c[n - 1])
    
    for i in range(n - 1, -1, -1):
        d[i] -= c[i] * d[i + 1]
    
    return d


def GetGroundHeatExchangerInput(state: 'EnergyPlusData') -> None:
    state.dataGroundHeatExchanger.numVerticalGLHEs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "GroundHeatExchanger:System")
    state.dataGroundHeatExchanger.numSlinkyGLHEs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "GroundHeatExchanger:Slinky")
    state.dataGroundHeatExchanger.numVertArray = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "GroundHeatExchanger:VerticalArray")
    state.dataGroundHeatExchanger.numVertProps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "GroundHeatExchanger:VerticalProperties")
    state.dataGroundHeatExchanger.numResponseFactors = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "GroundHeatExchanger:ResponseFactors")
    state.dataGroundHeatExchanger.numSingleBorehole = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "GroundHeatExchanger:VerticalSingle")
    
    if state.dataGroundHeatExchanger.numVerticalGLHEs <= 0 and state.dataGroundHeatExchanger.numSlinkyGLHEs <= 0:
        ShowSevereError(state, "Error processing inputs for GLHE objects")
        ShowContinueError(state, "Simulation indicated these objects were found, but input processor doesn't find any")
        ShowContinueError(state, "Check inputs for GroundHeatExchanger:System and GroundHeatExchanger:Slinky")
        ShowContinueError(state, "Also check plant/branch inputs for references to invalid/deleted objects")
    
    if state.dataGroundHeatExchanger.numVertProps > 0:
        instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:VerticalProperties", {})
        for objName, instance in instances.items():
            objNameUC = objName.upper()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:VerticalProperties", objName)
            thisObj = GLHEVertProps(state, objNameUC, instance)
            state.dataGroundHeatExchanger.vertPropsVector.append(thisObj)
    
    if state.dataGroundHeatExchanger.numResponseFactors > 0:
        instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:ResponseFactors", {})
        for objName, instance in instances.items():
            objNameUC = objName.upper()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:ResponseFactors", objName)
            thisObj = GLHEResponseFactors(state, objNameUC, instance)
            state.dataGroundHeatExchanger.responseFactorsVector.append(thisObj)
    
    if state.dataGroundHeatExchanger.numVertArray > 0:
        instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:VerticalArray", {})
        for objName, instance in instances.items():
            objNameUC = objName.upper()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:VerticalArray", objName)
            thisObj = GLHEVertArray(state, objNameUC, instance)
            state.dataGroundHeatExchanger.vertArraysVector.append(thisObj)
    
    if state.dataGroundHeatExchanger.numSingleBorehole > 0:
        instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:VerticalSingle", {})
        for objName, instance in instances.items():
            objNameUC = objName.upper()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:VerticalSingle", objName)
            thisObj = GLHEVertSingle(state, objNameUC, instance)
            state.dataGroundHeatExchanger.singleBoreholesVector.append(thisObj)
    
    if state.dataGroundHeatExchanger.numVerticalGLHEs > 0:
        instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:System", {})
        for objName, instance in instances.items():
            objNameUC = objName.upper()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:System", objName)
            state.dataGroundHeatExchanger.verticalGLHE.append(GLHEVert(state, objNameUC, instance))
    
    if state.dataGroundHeatExchanger.numSlinkyGLHEs > 0:
        instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:Slinky", {})
        for objName, instance in instances.items():
            objNameUC = objName.upper()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:Slinky", objName)
            state.dataGroundHeatExchanger.slinkyGLHE.append(GLHESlinky(state, objNameUC, instance))

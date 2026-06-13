# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus.Data (state object)
# - PlantComponent: from EnergyPlus.Plant (base struct)
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

from math import pi


struct GLHEBase:
    var available: Bool
    var on: Bool
    var name: String
    var plantLoc: PlantLocation
    var inletNodeNum: Int32
    var outletNodeNum: Int32
    var soil: ThermophysicalProps
    var pipe: PipeProps
    var grout: ThermophysicalProps
    var designFlow: Float64
    var designMassFlow: Float64
    var tempGround: Float64
    var QnMonthlyAgg: DynamicVector[Float64]
    var QnHr: DynamicVector[Float64]
    var QnSubHr: DynamicVector[Float64]
    var prevHour: Int32
    var AGG: Int32
    var SubAGG: Int32
    var LastHourN: DynamicVector[Int32]
    var bhTemp: Float64
    var massFlowRate: Float64
    var outletTemp: Float64
    var inletTemp: Float64
    var aveFluidTemp: Float64
    var QGLHE: Float64
    var myEnvrnFlag: Bool
    var gFunctionsExist: Bool
    var lastQnSubHr: Float64
    var HXResistance: Float64
    var totalTubeLength: Float64
    var timeSS: Float64
    var timeSSFactor: Float64
    var myRespFactors: GLHEResponseFactors
    var groundTempModel: BaseGroundTempsModel
    var firstTime: Bool
    var numErrorCalls: Int32
    var ToutNew: Float64
    var PrevN: Int32
    var updateCurSimTime: Bool
    var triggerDesignDayReset: Bool
    var needToSetupOutputVars: Bool
    var runGheDesigner: Bool
    var N: Int32
    var currentSimTime: Float64
    var locHourOfDay: Int32
    var locDayOfSim: Int32
    var prevTimeSteps: DynamicVector[Float64]

    fn __init__(inout self):
        self.available = False
        self.on = False
        self.name = String()
        self.plantLoc = PlantLocation()
        self.inletNodeNum = 0
        self.outletNodeNum = 0
        self.soil = ThermophysicalProps()
        self.pipe = PipeProps()
        self.grout = ThermophysicalProps()
        self.designFlow = 0.0
        self.designMassFlow = 0.0
        self.tempGround = 0.0
        self.QnMonthlyAgg = DynamicVector[Float64]()
        self.QnHr = DynamicVector[Float64]()
        self.QnSubHr = DynamicVector[Float64]()
        self.prevHour = 1
        self.AGG = 0
        self.SubAGG = 0
        self.LastHourN = DynamicVector[Int32]()
        self.bhTemp = 0.0
        self.massFlowRate = 0.0
        self.outletTemp = 0.0
        self.inletTemp = 0.0
        self.aveFluidTemp = 0.0
        self.QGLHE = 0.0
        self.myEnvrnFlag = True
        self.gFunctionsExist = False
        self.lastQnSubHr = 0.0
        self.HXResistance = 0.0
        self.totalTubeLength = 0.0
        self.timeSS = 0.0
        self.timeSSFactor = 0.0
        self.myRespFactors = GLHEResponseFactors()
        self.groundTempModel = BaseGroundTempsModel()
        self.firstTime = True
        self.numErrorCalls = 0
        self.ToutNew = 19.375
        self.PrevN = 1
        self.updateCurSimTime = True
        self.triggerDesignDayReset = False
        self.needToSetupOutputVars = True
        self.runGheDesigner = True
        self.N = 1
        self.currentSimTime = 0.0
        self.locHourOfDay = 0
        self.locDayOfSim = 0
        self.prevTimeSteps = DynamicVector[Float64]()

    fn calcGFunctions(inout self, state: EnergyPlusData) -> None:
        pass

    fn calcAggregateLoad(inout self, state: EnergyPlusData) -> None:
        let hrsPerMonth: Float64 = 730.0
        if self.currentSimTime <= 0.0:
            return
        
        if self.prevHour != self.locHourOfDay:
            var SumQnHr: Float64 = 0.0
            var J: Int32 = 0
            let limit = self.N - self.LastHourN[0]
            for j in range(limit):
                SumQnHr += self.QnSubHr[j] * abs(self.prevTimeSteps[j] - self.prevTimeSteps[j + 1])
                J = j
            
            if self.prevTimeSteps[0] != self.prevTimeSteps[J]:
                SumQnHr /= abs(self.prevTimeSteps[0] - self.prevTimeSteps[J])
            else:
                SumQnHr /= 0.05
            
            self._shift_left_float(self.QnHr, SumQnHr)
            self._shift_left_int(self.LastHourN, self.N)
        
        let iHoursInDay: Int32 = 24
        if ((self.locDayOfSim - 1) * iHoursInDay + self.locHourOfDay) % Int32(hrsPerMonth) == 0 and self.prevHour != self.locHourOfDay:
            let MonthNum: Int32 = ((self.locDayOfSim * iHoursInDay + self.locHourOfDay) / Int32(hrsPerMonth))
            var SumQnMonth: Float64 = 0.0
            for j in range(Int(hrsPerMonth)):
                SumQnMonth += self.QnHr[j]
            SumQnMonth /= hrsPerMonth
            self.QnMonthlyAgg[MonthNum] = SumQnMonth
        
        self.prevHour = self.locHourOfDay

    fn updateGHX(inout self, state: EnergyPlusData) -> None:
        let RoutineName: StringRef = "UpdateGroundHeatExchanger"
        let deltaTempLimit: Float64 = 100.0
        
        SafeCopyPlantNode(state, self.inletNodeNum, self.outletNodeNum)
        
        state.dataLoopNodes.Node[self.outletNodeNum].Temp = self.outletTemp
        state.dataLoopNodes.Node[self.outletNodeNum].Enthalpy = (
            self.outletTemp * state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.outletTemp, RoutineName)
        )
        
        let GLHEDeltaTemp: Float64 = abs(self.outletTemp - self.inletTemp)
        
        if (GLHEDeltaTemp > deltaTempLimit and 
            self.numErrorCalls < state.dataGroundHeatExchanger.numVerticalGLHEs and 
            not state.dataGlobal.WarmupFlag):
            let fluidDensity: Float64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, self.inletTemp, RoutineName)
            self.designMassFlow = self.designFlow * fluidDensity
            ShowWarningError(state, "Check GLHE design inputs & g-functions for consistency")
            ShowContinueError(state, String("For GroundHeatExchanger: ") + self.name + "GLHE delta Temp > 100C.")
            ShowContinueError(state, "This can be encountered in cases where the GLHE mass flow rate is either significantly")
            ShowContinueError(state, " lower than the design value, or cases where the mass flow rate rapidly changes.")
            let msg: String = String("GLHE Current Flow Rate=") + String(self.massFlowRate, precision=3) + "; GLHE Design Flow Rate=" + String(self.designMassFlow, precision=3)
            ShowContinueError(state, msg)
            self.numErrorCalls += 1

    fn calcGroundHeatExchanger(inout self, state: EnergyPlusData) -> None:
        let RoutineName: StringRef = "CalcGroundHeatExchanger"
        let hrsPerMonth: Float64 = 730.0
        let iHoursInDay: Int32 = 24
        
        if self.firstTime:
            if not self.gFunctionsExist:
                self.calcGFunctions(state)
                self.gFunctionsExist = True
            self.firstTime = False
        
        self.inletTemp = state.dataLoopNodes.Node[self.inletNodeNum].Temp
        
        let cpFluid: Float64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, RoutineName)
        
        let kGroundFactor: Float64 = 2.0 * pi * self.soil.k
        
        self.getAnnualTimeConstant()
        
        if self.triggerDesignDayReset and state.dataGlobal.WarmupFlag:
            self.updateCurSimTime = True
        
        if state.dataGlobal.DayOfSim == 1 and self.updateCurSimTime:
            self.currentSimTime = 0.0
            self._clear_float_vector(self.prevTimeSteps)
            self._clear_float_vector(self.QnHr)
            self._clear_float_vector(self.QnMonthlyAgg)
            self._clear_float_vector(self.QnSubHr)
            self._clear_int_vector(self.LastHourN, 1)
            self.N = 1
            self.updateCurSimTime = False
            self.triggerDesignDayReset = False
        
        self.currentSimTime = ((state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.HourOfDay - 1 + 
                              (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed)
        self.locHourOfDay = Int32((self.currentSimTime % Float64(iHoursInDay)) + 1.0)
        self.locDayOfSim = Int32(self.currentSimTime / 24.0 + 1.0)
        
        if state.dataGlobal.DayOfSim > 1:
            self.updateCurSimTime = True
        
        if not state.dataGlobal.WarmupFlag:
            self.triggerDesignDayReset = True
        
        if self.currentSimTime <= 0.0:
            self._clear_float_vector(self.prevTimeSteps)
            self.calcAggregateLoad(state)
            return
        
        if self.prevTimeSteps[0] != self.currentSimTime:
            self._shift_left_float(self.prevTimeSteps, self.currentSimTime)
            self.N += 1
        
        if self.N != self.PrevN:
            self.PrevN = self.N
            self._shift_left_float(self.QnSubHr, self.lastQnSubHr)
        
        self.calcAggregateLoad(state)
        
        self.HXResistance = self.calcHXResistance(state)
        
        var sumTotal: Float64 = 0.0
        var fluidAveTemp: Float64 = 0.0
        var tmpQnSubHourly: Float64 = 0.0
        
        if self.N == 1:
            if self.massFlowRate <= 0.0:
                tmpQnSubHourly = 0.0
                fluidAveTemp = self.tempGround
                self.ToutNew = self.inletTemp
            else:
                let gFuncVal: Float64 = self.getGFunc(self.currentSimTime / self.timeSSFactor)
                let C_1: Float64 = self.totalTubeLength / (2.0 * self.massFlowRate * cpFluid)
                tmpQnSubHourly = ((self.tempGround - self.inletTemp) / 
                                 (gFuncVal / kGroundFactor + self.HXResistance + C_1))
                fluidAveTemp = self.tempGround - tmpQnSubHourly * self.HXResistance
                self.ToutNew = self.tempGround - tmpQnSubHourly * (gFuncVal / kGroundFactor + self.HXResistance - C_1)
        else:
            if self.currentSimTime < (hrsPerMonth + Float64(self.AGG) + Float64(self.SubAGG)):
                var sumQnSubHourly: Float64 = 0.0
                var IndexN: Int32 = 0
                if Int32(self.currentSimTime) < self.SubAGG:
                    IndexN = Int32(self.currentSimTime) + 1
                else:
                    IndexN = self.SubAGG + 1
                
                let subHourlyLimit: Int32 = self.N - self.LastHourN[IndexN - 1]
                for I in range(1, Int(subHourlyLimit) + 1):
                    if I == Int(subHourlyLimit):
                        if Int32(self.currentSimTime) >= self.SubAGG:
                            let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                            let RQSubHr: Float64 = gFuncVal / kGroundFactor
                            sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnHr[IndexN - 1]) * RQSubHr
                        else:
                            let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                            let RQSubHr: Float64 = gFuncVal / kGroundFactor
                            sumQnSubHourly += self.QnSubHr[I - 1] * RQSubHr
                        break
                    let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                    let RQSubHr: Float64 = gFuncVal / kGroundFactor
                    sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnSubHr[I]) * RQSubHr
                
                var sumQnHourly: Float64 = 0.0
                let hourlyLimit: Int32 = Int32(self.currentSimTime)
                for I in range(Int(self.SubAGG) + 1, Int(hourlyLimit) + 1):
                    if I == Int(hourlyLimit):
                        let gFuncVal: Float64 = self.getGFunc(self.currentSimTime / self.timeSSFactor)
                        let RQHour: Float64 = gFuncVal / kGroundFactor
                        sumQnHourly += self.QnHr[I - 1] * RQHour
                        break
                    let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - Int32(self.currentSimTime) + Float64(I)) / self.timeSSFactor)
                    let RQHour: Float64 = gFuncVal / kGroundFactor
                    sumQnHourly += (self.QnHr[I - 1] - self.QnHr[I]) * RQHour
                
                sumTotal = sumQnSubHourly + sumQnHourly
                
                let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - self.prevTimeSteps[1]) / self.timeSSFactor)
                let RQSubHr: Float64 = gFuncVal / kGroundFactor
                
                if self.massFlowRate <= 0.0:
                    tmpQnSubHourly = 0.0
                    fluidAveTemp = self.tempGround - sumTotal
                    self.ToutNew = self.inletTemp
                else:
                    let C0: Float64 = RQSubHr
                    let C1: Float64 = self.tempGround - (sumTotal - self.QnSubHr[0] * RQSubHr)
                    let C2: Float64 = self.totalTubeLength / (2.0 * self.massFlowRate * cpFluid)
                    let C3: Float64 = self.massFlowRate * cpFluid / self.totalTubeLength
                    tmpQnSubHourly = (C1 - self.inletTemp) / (self.HXResistance + C0 - C2 + (1.0 / C3))
                    fluidAveTemp = C1 - (C0 + self.HXResistance) * tmpQnSubHourly
                    self.ToutNew = C1 + (C2 - C0 - self.HXResistance) * tmpQnSubHourly
            else:
                let numOfMonths: Int32 = Int32((self.currentSimTime + 1.0) / hrsPerMonth)
                
                var currentMonth: Int32 = 0
                if self.currentSimTime < (Float64(numOfMonths) * hrsPerMonth + Float64(self.AGG) + Float64(self.SubAGG)):
                    currentMonth = numOfMonths - 1
                else:
                    currentMonth = numOfMonths
                
                var sumQnMonthly: Float64 = 0.0
                for I in range(1, Int(currentMonth) + 1):
                    if I == 1:
                        let gFuncVal: Float64 = self.getGFunc(self.currentSimTime / self.timeSSFactor)
                        let RQMonth: Float64 = gFuncVal / kGroundFactor
                        sumQnMonthly += self.QnMonthlyAgg[I - 1] * RQMonth
                        continue
                    let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - Float64(I - 1) * hrsPerMonth) / self.timeSSFactor)
                    let RQMonth: Float64 = gFuncVal / kGroundFactor
                    sumQnMonthly += (self.QnMonthlyAgg[I - 1] - self.QnMonthlyAgg[I - 2]) * RQMonth
                
                var sumQnHourly: Float64 = 0.0
                let hourlyLimit: Int32 = Int32(self.currentSimTime - Float64(currentMonth) * hrsPerMonth)
                for I in range(1 + Int(self.SubAGG), Int(hourlyLimit) + 1):
                    if I == Int(hourlyLimit):
                        let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - Int32(self.currentSimTime) + Float64(I)) / self.timeSSFactor)
                        let RQHour: Float64 = gFuncVal / kGroundFactor
                        sumQnHourly += (self.QnHr[I - 1] - self.QnMonthlyAgg[currentMonth - 1]) * RQHour
                        break
                    let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - Int32(self.currentSimTime) + Float64(I)) / self.timeSSFactor)
                    let RQHour: Float64 = gFuncVal / kGroundFactor
                    sumQnHourly += (self.QnHr[I - 1] - self.QnHr[I]) * RQHour
                
                let subHourlyLimit: Int32 = self.N - self.LastHourN[self.SubAGG]
                var sumQnSubHourly: Float64 = 0.0
                for I in range(1, Int(subHourlyLimit) + 1):
                    if I == Int(subHourlyLimit):
                        let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                        let RQSubHr: Float64 = gFuncVal / kGroundFactor
                        sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnHr[self.SubAGG]) * RQSubHr
                        break
                    let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - self.prevTimeSteps[I]) / self.timeSSFactor)
                    let RQSubHr: Float64 = gFuncVal / kGroundFactor
                    sumQnSubHourly += (self.QnSubHr[I - 1] - self.QnSubHr[I]) * RQSubHr
                
                sumTotal = sumQnMonthly + sumQnHourly + sumQnSubHourly
                
                let gFuncVal: Float64 = self.getGFunc((self.currentSimTime - self.prevTimeSteps[1]) / self.timeSSFactor)
                let RQSubHr: Float64 = gFuncVal / kGroundFactor
                
                if self.massFlowRate <= 0.0:
                    tmpQnSubHourly = 0.0
                    fluidAveTemp = self.tempGround - sumTotal
                    self.ToutNew = self.inletTemp
                else:
                    let C0: Float64 = RQSubHr
                    let C1: Float64 = self.tempGround - (sumTotal - self.QnSubHr[0] * RQSubHr)
                    let C2: Float64 = self.totalTubeLength / (2.0 * self.massFlowRate * cpFluid)
                    let C3: Float64 = self.massFlowRate * cpFluid / self.totalTubeLength
                    tmpQnSubHourly = (C1 - self.inletTemp) / (self.HXResistance + C0 - C2 + (1.0 / C3))
                    fluidAveTemp = C1 - (C0 + self.HXResistance) * tmpQnSubHourly
                    self.ToutNew = C1 + (C2 - C0 - self.HXResistance) * tmpQnSubHourly
        
        self.bhTemp = self.tempGround - sumTotal
        self.lastQnSubHr = tmpQnSubHourly
        self.outletTemp = self.ToutNew
        self.QGLHE = tmpQnSubHourly * self.totalTubeLength
        self.aveFluidTemp = fluidAveTemp

    @staticmethod
    fn isEven(val: Int32) -> Bool:
        return val % 2 == 0

    fn interpGFunc(self, x_val: Float64) -> Float64:
        let x = self.myRespFactors.LNTTS
        let y = self.myRespFactors.GFNC
        
        var l_idx: Int32 = 0
        var u_idx: Int32 = 0
        
        if x_val < x[0]:
            l_idx = 0
            u_idx = 1
        elif x_val >= x[x.size() - 1]:
            u_idx = Int32(x.size() - 1)
            l_idx = u_idx - 1
        else:
            for i in range(Int(x.size()) - 1):
                if x[i] <= x_val and x_val < x[i + 1]:
                    l_idx = Int32(i)
                    u_idx = Int32(i + 1)
                    break
        
        let x_low: Float64 = x[l_idx]
        let x_high: Float64 = x[u_idx]
        let y_low: Float64 = y[l_idx]
        let y_high: Float64 = y[u_idx]
        
        return (x_val - x_low) / (x_high - x_low) * (y_high - y_low) + y_low

    fn onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation) -> None:
        self.initGLHESimVars(state)

    fn simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation,
                FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> None:
        if self.needToSetupOutputVars:
            self.setupOutput(state)
            self.needToSetupOutputVars = False
        
        self.initGLHESimVars(state)
        if state.dataGlobal.KickOffSimulation:
            return
        
        self.calcGroundHeatExchanger(state)
        self.updateGHX(state)

    @staticmethod
    fn factory(state: EnergyPlusData, objectType: DataPlant_PlantEquipmentType, objectName: String) -> GLHEBase:
        if state.dataGroundHeatExchanger.GetInput:
            GetGroundHeatExchangerInput(state)
            state.dataGroundHeatExchanger.GetInput = False
        
        if objectType == DataPlant_PlantEquipmentType.GrndHtExchgSystem:
            for obj in state.dataGroundHeatExchanger.verticalGLHE:
                if obj.name == objectName:
                    return obj
        elif objectType == DataPlant_PlantEquipmentType.GrndHtExchgSlinky:
            for obj in state.dataGroundHeatExchanger.slinkyGLHE:
                if obj.name == objectName:
                    return obj
        
        ShowFatalError(state, String("Ground Heat Exchanger Factory: Error getting inputs for GHX named: ") + objectName)

    fn getGFunc(self, x: Float64) -> Float64:
        pass

    fn initGLHESimVars(inout self, state: EnergyPlusData) -> None:
        pass

    fn calcHXResistance(inout self, state: EnergyPlusData) -> Float64:
        pass

    fn getAnnualTimeConstant(inout self) -> None:
        pass

    fn initEnvironment(inout self, state: EnergyPlusData, CurTime: Float64) -> None:
        pass

    fn setupOutput(inout self, state: EnergyPlusData) -> None:
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

    fn _shift_left_float(inout self, inout arr: DynamicVector[Float64], boundary_value: Float64) -> None:
        if arr.size() > 1:
            for i in range(Int(arr.size()) - 1):
                arr[i] = arr[i + 1]
            arr[arr.size() - 1] = boundary_value

    fn _shift_left_int(inout self, inout arr: DynamicVector[Int32], boundary_value: Int32) -> None:
        if arr.size() > 1:
            for i in range(Int(arr.size()) - 1):
                arr[i] = arr[i + 1]
            arr[arr.size() - 1] = boundary_value

    fn _clear_float_vector(inout self, inout arr: DynamicVector[Float64]) -> None:
        for i in range(Int(arr.size())):
            arr[i] = 0.0

    fn _clear_int_vector(inout self, inout arr: DynamicVector[Int32], fill_val: Int32) -> None:
        for i in range(Int(arr.size())):
            arr[i] = fill_val


fn TDMA(a: DynamicVector[Float64], inout b: DynamicVector[Float64], inout c: DynamicVector[Float64], inout d: DynamicVector[Float64]) -> DynamicVector[Float64]:
    let n: Int32 = Int32(d.size() - 1)
    
    c[0] /= b[0]
    d[0] /= b[0]
    
    for i in range(1, Int(n)):
        c[i] /= b[i] - a[i] * c[i - 1]
        d[i] = (d[i] - a[i] * d[i - 1]) / (b[i] - a[i] * c[i - 1])
    
    d[n] = (d[n] - a[n] * d[n - 1]) / (b[n] - a[n] * c[n - 1])
    
    for i in range(Int(n) - 1, -1, -1):
        d[i] -= c[i] * d[i + 1]
    
    return d


fn GetGroundHeatExchangerInput(state: EnergyPlusData) -> None:
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
        let instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:VerticalProperties")
        if instances:
            for objName in instances.keys():
                let objNameUC: String = objName.upper()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:VerticalProperties", objName)
                let thisObj = GLHEVertProps(state, objNameUC, instances[objName])
                state.dataGroundHeatExchanger.vertPropsVector.push_back(thisObj)
    
    if state.dataGroundHeatExchanger.numResponseFactors > 0:
        let instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:ResponseFactors")
        if instances:
            for objName in instances.keys():
                let objNameUC: String = objName.upper()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:ResponseFactors", objName)
                let thisObj = GLHEResponseFactors(state, objNameUC, instances[objName])
                state.dataGroundHeatExchanger.responseFactorsVector.push_back(thisObj)
    
    if state.dataGroundHeatExchanger.numVertArray > 0:
        let instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:VerticalArray")
        if instances:
            for objName in instances.keys():
                let objNameUC: String = objName.upper()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:VerticalArray", objName)
                let thisObj = GLHEVertArray(state, objNameUC, instances[objName])
                state.dataGroundHeatExchanger.vertArraysVector.push_back(thisObj)
    
    if state.dataGroundHeatExchanger.numSingleBorehole > 0:
        let instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:VerticalSingle")
        if instances:
            for objName in instances.keys():
                let objNameUC: String = objName.upper()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:VerticalSingle", objName)
                let thisObj = GLHEVertSingle(state, objNameUC, instances[objName])
                state.dataGroundHeatExchanger.singleBoreholesVector.push_back(thisObj)
    
    if state.dataGroundHeatExchanger.numVerticalGLHEs > 0:
        let instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:System")
        if instances:
            for objName in instances.keys():
                let objNameUC: String = objName.upper()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:System", objName)
                state.dataGroundHeatExchanger.verticalGLHE.push_back(GLHEVert(state, objNameUC, instances[objName]))
    
    if state.dataGroundHeatExchanger.numSlinkyGLHEs > 0:
        let instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:Slinky")
        if instances:
            for objName in instances.keys():
                let objNameUC: String = objName.upper()
                state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:Slinky", objName)
                state.dataGroundHeatExchanger.slinkyGLHE.push_back(GLHESlinky(state, objNameUC, instances[objName]))

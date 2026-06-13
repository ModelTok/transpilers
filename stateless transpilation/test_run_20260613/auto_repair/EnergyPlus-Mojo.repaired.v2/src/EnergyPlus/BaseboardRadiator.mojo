from Data.BaseData import BaseGlobalStruct
from DataGlobals import DataGlobals
from EnergyPlus import EnergyPlus
from Plant.DataPlant import DataPlant, PlantLocation
from .Data.EnergyPlusData import EnergyPlusData
from DataHVACGlobals import HVACGlobals, SmallLoad
from DataHeatBalance import DataHeatBal
from DataLoopNode import DataLoopNode, Node
from DataPrecisionGlobals import DataPrecisionGlobals, EXP_LowerLimit
from DataSizing import DataSizing, BaseSizer, HeatingCapacitySizer
from DataZoneEnergyDemands import DataZoneEnergyDemands
from DataZoneEquipment import DataZoneEquipment, ZoneEquipType
from FluidProperties import FluidProperties
from General import General
from GeneralRoutines import CheckZoneSizing
from GlobalNames import GlobalNames, VerifyUniqueBaseboardName
from .InputProcessing.InputProcessor import InputProcessor, ErrorObjectHeader
from NodeInputManager import NodeInputManager as Node
from OutputProcessor import OutputProcessor, SetupOutputVariable, Constant
from Plant.DataPlant import PlantData
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics, PsyCpAirFnW, PsyRhoAirFnPbTdbW
from ScheduleManager import Schedule as Sched
from UtilityRoutines import Utility as Util
from memory import Pointer
from math import abs, pow, exp
struct BaseboardParams:
    var EquipID: String
    var Schedule: String
    var availSched: Optional[Sched.Schedule] = None
    var EquipType: DataPlant.PlantEquipmentType = DataPlant.PlantEquipmentType.Invalid
    var ZonePtr: Int = 0
    var WaterInletNode: Int = 0
    var WaterOutletNode: Int = 0
    var ControlCompTypeNum: Int = 0
    var CompErrIndex: Int = 0
    var UA: Float64 = 0.0
    var WaterMassFlowRate: Float64 = 0.0
    var WaterVolFlowRateMax: Float64 = 0.0   // m3/s
    var WaterMassFlowRateMax: Float64 = 0.0  // kg/s
    var Offset: Float64 = 0.0
    var AirMassFlowRate: Float64 = 0.0       // kg/s
    var DesAirMassFlowRate: Float64 = 0.0    // kg/s
    var WaterInletTemp: Float64 = 0.0
    var WaterOutletTemp: Float64 = 0.0
    var WaterInletEnthalpy: Float64 = 0.0
    var WaterOutletEnthalpy: Float64 = 0.0
    var AirInletTemp: Float64 = 0.0
    var AirInletHumRat: Float64 = 0.0
    var AirOutletTemp: Float64 = 0.0
    var Power: Float64 = 0.0
    var Energy: Float64 = 0.0
    var plantLoc: PlantLocation
    var FieldNames: List[String]
    var HeatingCapMethod: Int = 0 // - Method for water baseboard Radiator system heating capacity scaledsizing calculation (HeatingDesignCapacity,
    var ScaledHeatingCapacity: Float64 = 0.0 // -  water baseboard Radiator system scaled maximum heating capacity {W} or scalable variable of zone
    var MySizeFlag: Bool = true
    var CheckEquipName: Bool = true
    var SetLoopIndexFlag: Bool = true
    var MyEnvrnFlag: Bool = true
    def InitBaseboard(inout self, state: EnergyPlusData, baseboardNum: Int):
        ...
    def SizeBaseboard(inout self, state: EnergyPlusData, baseboardNum: Int):
        ...
    def checkForZoneSizing(inout self, state: EnergyPlusData):
        ...
def SimBaseboard(inout state: EnergyPlusData, EquipName: String, ControlledZoneNum: Int, FirstHVACIteration: Bool, inout PowerMet: Float64, inout CompIndex: Int):
    let cCMO_BBRadiator_Water: String = "ZoneHVAC:Baseboard:Convective:Water"
    if state.dataBaseboardRadiator.getInputFlag:
        GetBaseboardInput(state)
        state.dataBaseboardRadiator.getInputFlag = False
    if CompIndex == 0:
        var BaseboardNum: Int = Util.FindItemInList(EquipName, state.dataBaseboardRadiator.baseboards, &BaseboardParams.EquipID)
        if BaseboardNum == 0:
            ShowFatalError(state, "SimBaseboard: Unit not found=" + EquipName)
        CompIndex = BaseboardNum
    assert(CompIndex <= len(state.dataBaseboardRadiator.baseboards))
    var thisBaseboard = state.dataBaseboardRadiator.baseboards[CompIndex - 1]  // 0-based
    if thisBaseboard.CheckEquipName:
        if EquipName != thisBaseboard.EquipID:
            ShowFatalError(state, "SimBaseboard: Invalid CompIndex passed=" + str(CompIndex) + ", Unit name=" + EquipName + ", stored Unit Name for that index=" + thisBaseboard.EquipID)
        thisBaseboard.CheckEquipName = False
    thisBaseboard.InitBaseboard(state, CompIndex)
    let QZnReq: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum - 1].RemainingOutputReqToHeatSP
    var MaxWaterFlow: Float64 = 0.0
    var MinWaterFlow: Float64 = 0.0
    var DummyMdot: Float64 = 0.0
    if (QZnReq < SmallLoad) or (thisBaseboard.WaterInletTemp <= thisBaseboard.AirInletTemp):
        thisBaseboard.WaterOutletTemp = thisBaseboard.WaterInletTemp
        thisBaseboard.AirOutletTemp = thisBaseboard.AirInletTemp
        thisBaseboard.Power = 0.0
        thisBaseboard.WaterMassFlowRate = 0.0
        DummyMdot = 0.0
        PlantUtilities.SetActuatedBranchFlowRate(state, DummyMdot, thisBaseboard.WaterInletNode, thisBaseboard.plantLoc, False)
    else:
        DummyMdot = 0.0
        PlantUtilities.SetActuatedBranchFlowRate(state, DummyMdot, thisBaseboard.WaterInletNode, thisBaseboard.plantLoc, True)
        if FirstHVACIteration:
            MaxWaterFlow = thisBaseboard.WaterMassFlowRateMax
            MinWaterFlow = 0.0
        else:
            MaxWaterFlow = state.dataLoopNodes.Node(thisBaseboard.WaterInletNode).MassFlowRateMaxAvail
            MinWaterFlow = state.dataLoopNodes.Node(thisBaseboard.WaterInletNode).MassFlowRateMinAvail
        ControlCompOutput(
            state,
            thisBaseboard.EquipID,
            cCMO_BBRadiator_Water,
            CompIndex,
            FirstHVACIteration,
            QZnReq,
            thisBaseboard.WaterInletNode,
            MaxWaterFlow,
            MinWaterFlow,
            thisBaseboard.Offset,
            thisBaseboard.ControlCompTypeNum,
            thisBaseboard.CompErrIndex,
            thisBaseboard.plantLoc
        )
        PowerMet = thisBaseboard.Power
    UpdateBaseboard(state, CompIndex)
    thisBaseboard.Energy = thisBaseboard.Power * state.dataHVACGlobal.TimeStepSysSec
def GetBaseboardInput(inout state: EnergyPlusData):
    let RoutineName = "GetBaseboardInput: "
    let routineName = "GetBaseboardInput"
    let iHeatDesignCapacityNumericNum = 1
    let iHeatCapacityPerFloorAreaNumericNum = 2
    let iHeatFracOfAutosizedCapacityNumericNum = 3
    let cCurrentModuleObject: String = "ZoneHVAC:Baseboard:Convective:Water"
    let NumConvHWBaseboards: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataBaseboardRadiator.baseboards = List[BaseboardParams]()
    if NumConvHWBaseboards > 0:
        var ErrorsFound: Bool = False
        let inputProcessor = state.dataInputProcessing.inputProcessor
        let baseboardSchemaProps = inputProcessor.getObjectSchemaProps(state, cCurrentModuleObject)
        let baseboardObjects = inputProcessor.epJSON.find(cCurrentModuleObject)
        let numericFieldNames: StaticTuple[6, String] = ["Heating Design Capacity",
                                                         "Heating Design Capacity Per Floor Area",
                                                         "Fraction of Autosized Heating Design Capacity",
                                                         "U-Factor Times Area Value",
                                                         "Maximum Water Flow Rate",
                                                         "Convergence Tolerance"]
        let availabilityScheduleFieldName: String = "Availability Schedule Name"
        let heatingDesignCapacityMethodFieldName: String = "Heating Design Capacity Method"
        if baseboardObjects != inputProcessor.epJSON.end():
            var ConvHWBaseboardNum: Int = 0
            for var baseboardInstance in baseboardObjects.value().items():
                let baseboardFields = baseboardInstance.value()
                let baseboardName = Util.makeUPPER(baseboardInstance.key())
                let availabilityScheduleName = inputProcessor.getAlphaFieldValue(baseboardFields, baseboardSchemaProps, "availability_schedule_name")
                let inletNodeName = inputProcessor.getAlphaFieldValue(baseboardFields, baseboardSchemaProps, "inlet_node_name")
                let outletNodeName = inputProcessor.getAlphaFieldValue(baseboardFields, baseboardSchemaProps, "outlet_node_name")
                let heatingDesignCapacityMethod = inputProcessor.getAlphaFieldValue(baseboardFields, baseboardSchemaProps, "heating_design_capacity_method")
                inputProcessor.markObjectAsUsed(cCurrentModuleObject, baseboardInstance.key())
                ConvHWBaseboardNum += 1
                var thisBaseboard = BaseboardParams()
                state.dataBaseboardRadiator.baseboards.append(thisBaseboard)
                var appended_idx = len(state.dataBaseboardRadiator.baseboards) - 1
                var ref_this = state.dataBaseboardRadiator.baseboards[appended_idx]
                ref_this.FieldNames = List[String](numericFieldNames)
                let eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, baseboardName)
                VerifyUniqueBaseboardName(state, cCurrentModuleObject, baseboardName, ErrorsFound, cCurrentModuleObject + " Name")
                ref_this.EquipID = baseboardName
                ref_this.EquipType = DataPlant.PlantEquipmentType.Baseboard_Conv_Water
                ref_this.Schedule = availabilityScheduleName
                if availabilityScheduleName == "":
                    ref_this.availSched = Sched.GetScheduleAlwaysOn(state)
                else:
                    ref_this.availSched = Sched.GetSchedule(state, availabilityScheduleName)
                    if ref_this.availSched == None:
                        ShowSevereItemNotFound(state, eoh, availabilityScheduleFieldName, availabilityScheduleName)
                        ErrorsFound = True
                ref_this.WaterInletNode = Node.GetOnlySingleNode(
                    state,
                    inletNodeName,
                    ErrorsFound,
                    Node.ConnectionObjectType.ZoneHVACBaseboardConvectiveWater,
                    baseboardName,
                    Node.FluidType.Water,
                    Node.ConnectionType.Inlet,
                    Node.CompFluidStream.Primary,
                    Node.ObjectIsNotParent
                )
                ref_this.WaterOutletNode = Node.GetOnlySingleNode(
                    state,
                    outletNodeName,
                    ErrorsFound,
                    Node.ConnectionObjectType.ZoneHVACBaseboardConvectiveWater,
                    baseboardName,
                    Node.FluidType.Water,
                    Node.ConnectionType.Outlet,
                    Node.CompFluidStream.Primary,
                    Node.ObjectIsNotParent
                )
                Node.TestCompSet(state, cCurrentModuleObject, baseboardName, inletNodeName, outletNodeName, "Hot Water Nodes")
                if Util.SameString(heatingDesignCapacityMethod, "HeatingDesignCapacity"):
                    ref_this.HeatingCapMethod = DataSizing.HeatingDesignCapacity
                    let heatingDesignCapacityField = baseboardFields.find("heating_design_capacity")
                    if heatingDesignCapacityField != baseboardFields.end():
                        ref_this.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(baseboardFields, baseboardSchemaProps, "heating_design_capacity")
                        if ref_this.ScaledHeatingCapacity < 0.0 and ref_this.ScaledHeatingCapacity != DataSizing.AutoSize:
                            ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                            ShowContinueError(state, "Illegal {} = {:.7f}".format(numericFieldNames[iHeatDesignCapacityNumericNum - 1], ref_this.ScaledHeatingCapacity))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                        ShowContinueError(state, "Input for {} = {}".format(heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                        ShowContinueError(state, "Blank field not allowed for {}".format(numericFieldNames[iHeatDesignCapacityNumericNum - 1]))
                        ErrorsFound = True
                elif Util.SameString(heatingDesignCapacityMethod, "CapacityPerFloorArea"):
                    ref_this.HeatingCapMethod = DataSizing.CapacityPerFloorArea
                    let heatingDesignCapacityPerFloorAreaField = baseboardFields.find("heating_design_capacity_per_floor_area")
                    if heatingDesignCapacityPerFloorAreaField != baseboardFields.end():
                        ref_this.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(baseboardFields, baseboardSchemaProps, "heating_design_capacity_per_floor_area")
                        if ref_this.ScaledHeatingCapacity <= 0.0:
                            ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                            ShowContinueError(state, "Input for {} = {}".format(heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                            ShowContinueError(state, "Illegal {} = {:.7f}".format(numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1], ref_this.ScaledHeatingCapacity))
                            ErrorsFound = True
                        elif ref_this.ScaledHeatingCapacity == DataSizing.AutoSize:
                            ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                            ShowContinueError(state, "Input for {} = {}".format(heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                            ShowContinueError(state, "Illegal {} = Autosize".format(numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                        ShowContinueError(state, "Input for {} = {}".format(heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                        ShowContinueError(state, "Blank field not allowed for {}".format(numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]))
                        ErrorsFound = True
                elif Util.SameString(heatingDesignCapacityMethod, "FractionOfAutosizedHeatingCapacity"):
                    ref_this.HeatingCapMethod = DataSizing.FractionOfAutosizedHeatingCapacity
                    let fractionOfAutosizedHeatingCapacityField = baseboardFields.find("fraction_of_autosized_heating_design_capacity")
                    if fractionOfAutosizedHeatingCapacityField != baseboardFields.end():
                        ref_this.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(baseboardFields, baseboardSchemaProps, "fraction_of_autosized_heating_design_capacity")
                        if ref_this.ScaledHeatingCapacity < 0.0:
                            ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                            ShowContinueError(state, "Illegal {} = {:.7f}".format(numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1], ref_this.ScaledHeatingCapacity))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                        ShowContinueError(state, "Input for {} = {}".format(heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                        ShowContinueError(state, "Blank field not allowed for {}".format(numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1]))
                        ErrorsFound = True
                else:
                    ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, ref_this.EquipID))
                    ShowContinueError(state, "Illegal {} = {}".format(heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                    ErrorsFound = True
                ref_this.UA = inputProcessor.getRealFieldValue(baseboardFields, baseboardSchemaProps, "u_factor_times_area_value")
                ref_this.WaterVolFlowRateMax = inputProcessor.getRealFieldValue(baseboardFields, baseboardSchemaProps, "maximum_water_flow_rate")
                ref_this.Offset = inputProcessor.getRealFieldValue(baseboardFields, baseboardSchemaProps, "convergence_tolerance")
                if ref_this.Offset <= 0.0:
                    ref_this.Offset = 0.001
                ref_this.ZonePtr = DataZoneEquipment.GetZoneEquipControlledZoneNum(
                    state, DataZoneEquipment.ZoneEquipType.BaseboardConvectiveWater, ref_this.EquipID
                )
                ref_this.checkForZoneSizing(state)
            if ErrorsFound:
                ShowFatalError(state, "{}Errors found in getting input.  Preceding condition(s) cause termination.".format(RoutineName))
    for BaseboardNum in range(1, NumConvHWBaseboards + 1):
        var thisBaseboard = state.dataBaseboardRadiator.baseboards[BaseboardNum - 1]
        SetupOutputVariable(
            state,
            "Baseboard Total Heating Energy",
            Constant.Units.J,
            thisBaseboard.Energy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            thisBaseboard.EquipID,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.Baseboard
        )
        SetupOutputVariable(
            state,
            "Baseboard Hot Water Energy",
            Constant.Units.J,
            thisBaseboard.Energy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            thisBaseboard.EquipID,
            Constant.eResource.PlantLoopHeatingDemand,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.Baseboard
        )
        SetupOutputVariable(
            state,
            "Baseboard Total Heating Rate",
            Constant.Units.W,
            thisBaseboard.Power,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipID
        )
        SetupOutputVariable(
            state,
            "Baseboard Hot Water Mass Flow Rate",
            Constant.Units.kg_s,
            thisBaseboard.WaterMassFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipID
        )
        SetupOutputVariable(
            state,
            "Baseboard Air Mass Flow Rate",
            Constant.Units.kg_s,
            thisBaseboard.AirMassFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipID
        )
        SetupOutputVariable(
            state,
            "Baseboard Air Inlet Temperature",
            Constant.Units.C,
            thisBaseboard.AirInletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipID
        )
        SetupOutputVariable(
            state,
            "Baseboard Air Outlet Temperature",
            Constant.Units.C,
            thisBaseboard.AirOutletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipID
        )
        SetupOutputVariable(
            state,
            "Baseboard Water Inlet Temperature",
            Constant.Units.C,
            thisBaseboard.WaterInletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipID
        )
        SetupOutputVariable(
            state,
            "Baseboard Water Outlet Temperature",
            Constant.Units.C,
            thisBaseboard.WaterOutletTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipID
        )
def BaseboardParams.InitBaseboard(inout self, state: EnergyPlusData, baseboardNum: Int):
    let RoutineName: String = "BaseboardRadiator:InitBaseboard"
    if self.SetLoopIndexFlag and allocated(state.dataPlnt.PlantLoop):
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.EquipID, self.EquipType, self.plantLoc, errFlag)
        if errFlag:
            ShowFatalError(state, "InitBaseboard: Program terminated for previous conditions.")
        self.SetLoopIndexFlag = False
    if not state.dataGlobal.SysSizingCalc and self.MySizeFlag and not self.SetLoopIndexFlag:
        self.SizeBaseboard(state, baseboardNum)
        self.MySizeFlag = False
    if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and not self.SetLoopIndexFlag:
        let WaterInletNode: Int = self.WaterInletNode
        let rho: Float64 = self.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
        self.WaterMassFlowRateMax = rho * self.WaterVolFlowRateMax
        PlantUtilities.InitComponentNodes(state, 0.0, self.WaterMassFlowRateMax, self.WaterInletNode, self.WaterOutletNode)
        state.dataLoopNodes.Node[WaterInletNode].Temp = Constant.HWInitConvTemp
        let Cp: Float64 = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[WaterInletNode].Temp, RoutineName)
        state.dataLoopNodes.Node[WaterInletNode].Enthalpy = Cp * state.dataLoopNodes.Node[WaterInletNode].Temp
        state.dataLoopNodes.Node[WaterInletNode].Quality = 0.0
        state.dataLoopNodes.Node[WaterInletNode].Press = 0.0
        state.dataLoopNodes.Node[WaterInletNode].HumRat = 0.0
        if self.AirMassFlowRate <= 0.0:
            self.AirMassFlowRate = 2.0 * self.WaterMassFlowRateMax
        self.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        self.MyEnvrnFlag = True
    let WaterInletNode: Int = self.WaterInletNode
    let ZoneNode: Int = state.dataZoneEquip.ZoneEquipConfig[self.ZonePtr - 1].ZoneNode
    self.WaterMassFlowRate = state.dataLoopNodes.Node[WaterInletNode].MassFlowRate
    self.WaterInletTemp = state.dataLoopNodes.Node[WaterInletNode].Temp
    self.WaterInletEnthalpy = state.dataLoopNodes.Node[WaterInletNode].Enthalpy
    self.AirInletTemp = state.dataLoopNodes.Node[ZoneNode].Temp
    self.AirInletHumRat = state.dataLoopNodes.Node[ZoneNode].HumRat
def BaseboardParams.SizeBaseboard(inout self, state: EnergyPlusData, baseboardNum: Int):
    let Acc: Float64 = 0.0001
    let MaxIte: Int = 500
    let RoutineName: String = cCMO_BBRadiator_Water + ":SizeBaseboard"
    var DesCoilLoad: Float64 = 0.0
    var UA0: Float64
    var UA1: Float64
    var UA: Float64
    var ErrorsFound: Bool = False
    var rho: Float64
    var Cp: Float64
    var WaterVolFlowRateMaxDes: Float64 = 0.0
    var WaterVolFlowRateMaxUser: Float64 = 0.0
    var UADes: Float64 = 0.0
    var UAUser: Float64 = 0.0
    var TempSize: Float64
    let PltSizHeatNum: Int = self.plantLoc.loop.PlantSizNum
    if PltSizHeatNum > 0:
        state.dataSize.DataScalableCapSizingON = False
        if state.dataSize.CurZoneEqNum > 0:
            var FlowAutoSize: Bool = False
            if self.WaterVolFlowRateMax == DataSizing.AutoSize:
                FlowAutoSize = True
            if not FlowAutoSize and not state.dataSize.ZoneSizingRunDone:
                if self.WaterVolFlowRateMax > 0.0:
                    BaseSizer.reportSizerOutput(
                        state, cCMO_BBRadiator_Water, self.EquipID, "User-Specified Maximum Water Flow Rate [m3/s]", self.WaterVolFlowRateMax
                    )
            else:
                var zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
                let finalZoneSizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum]
                let CompType: String = cCMO_BBRadiator_Water
                let CompName: String = self.EquipID
                state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                state.dataSize.DataZoneNumber = self.ZonePtr
                let SizingMethod: Int = HVAC.HeatingCapacitySizing
                let FieldNum: Int = 1
                let SizingString: String = "{} [W]".format(self.FieldNames[FieldNum - 1])
                let CapSizingMethod: Int = self.HeatingCapMethod
                zoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod
                if CapSizingMethod == DataSizing.HeatingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                    if CapSizingMethod == DataSizing.HeatingDesignCapacity:
                        if self.ScaledHeatingCapacity == DataSizing.AutoSize:
                            zoneEqSizing.DesHeatingLoad = finalZoneSizing.NonAirSysDesHeatLoad
                        else:
                            zoneEqSizing.DesHeatingLoad = self.ScaledHeatingCapacity
                        zoneEqSizing.HeatingCapacity = True
                        TempSize = zoneEqSizing.DesHeatingLoad
                    elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                        zoneEqSizing.HeatingCapacity = True
                        zoneEqSizing.DesHeatingLoad = self.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                        TempSize = zoneEqSizing.DesHeatingLoad
                        state.dataSize.DataScalableCapSizingON = True
                    elif CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                        zoneEqSizing.HeatingCapacity = True
                        state.dataSize.DataFracOfAutosizedHeatingCapacity = self.ScaledHeatingCapacity
                        zoneEqSizing.DesHeatingLoad = finalZoneSizing.NonAirSysDesHeatLoad
                        TempSize = DataSizing.AutoSize
                        state.dataSize.DataScalableCapSizingON = True
                    else:
                        TempSize = self.ScaledHeatingCapacity
                    var PrintFlag: Bool = False
                    var errorsFound: Bool = False
                    var sizerHeatingCapacity = HeatingCapacitySizer()
                    sizerHeatingCapacity.overrideSizingString(SizingString)
                    sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                    DesCoilLoad = sizerHeatingCapacity.size(state, TempSize, errorsFound)
                    state.dataSize.DataScalableCapSizingON = False
                else:
                    DesCoilLoad = 0.0
                if DesCoilLoad >= SmallLoad:
                    Cp = self.plantLoc.loop.glycol.getSpecificHeat(state, Constant.HWInitConvTemp, RoutineName)
                    rho = self.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                    WaterVolFlowRateMaxDes = DesCoilLoad / (state.dataSize.PlantSizData[PltSizHeatNum - 1].DeltaT * Cp * rho)
                else:
                    WaterVolFlowRateMaxDes = 0.0
                if FlowAutoSize:
                    self.WaterVolFlowRateMax = WaterVolFlowRateMaxDes
                    BaseSizer.reportSizerOutput(
                        state, cCMO_BBRadiator_Water, self.EquipID, "Design Size Maximum Water Flow Rate [m3/s]", WaterVolFlowRateMaxDes
                    )
                else:
                    if self.WaterVolFlowRateMax > 0.0 and WaterVolFlowRateMaxDes > 0.0:
                        WaterVolFlowRateMaxUser = self.WaterVolFlowRateMax
                        BaseSizer.reportSizerOutput(
                            state,
                            cCMO_BBRadiator_Water,
                            self.EquipID,
                            "Design Size Maximum Water Flow Rate [m3/s]",
                            WaterVolFlowRateMaxDes,
                            "User-Specified Maximum Water Flow Rate [m3/s]",
                            WaterVolFlowRateMaxUser
                        )
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(WaterVolFlowRateMaxDes - WaterVolFlowRateMaxUser) / WaterVolFlowRateMaxUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(
                                    state,
                                    "SizeBaseboard: Potential issue with equipment sizing for ZoneHVAC:Baseboard:Convective:Water=\"{}\".".format(self.EquipID)
                                )
                                ShowContinueError(
                                    state,
                                    "User-Specified Maximum Water Flow Rate of {:#G} [m3/s]".format(WaterVolFlowRateMaxUser)
                                )
                                ShowContinueError(
                                    state,
                                    "differs from Design Size Maximum Water Flow Rate of {:#G} [m3/s]".format(WaterVolFlowRateMaxDes)
                                )
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
            var UAAutoSize: Bool = False
            if self.UA == DataSizing.AutoSize:
                UAAutoSize = True
            else:
                UAUser = self.UA
            if not UAAutoSize and not state.dataSize.ZoneSizingRunDone:
                if self.UA > 0.0:
                    BaseSizer.reportSizerOutput(
                        state, cCMO_BBRadiator_Water, self.EquipID, "User-Specified U-Factor Times Area Value [W/K]", self.UA
                    )
            else:
                var zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
                let finalZoneSizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum]
                self.WaterInletTemp = state.dataSize.PlantSizData[PltSizHeatNum - 1].ExitTemp
                self.AirInletTemp = finalZoneSizing.ZoneTempAtHeatPeak
                self.AirInletHumRat = finalZoneSizing.ZoneHumRatAtHeatPeak
                rho = self.plantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, RoutineName)
                state.dataLoopNodes.Node[self.WaterInletNode].MassFlowRate = rho * self.WaterVolFlowRateMax
                let CompType: String = cCMO_BBRadiator_Water
                let CompName: String = self.EquipID
                state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                state.dataSize.DataZoneNumber = self.ZonePtr
                let SizingMethod: Int = HVAC.HeatingCapacitySizing
                let FieldNum: Int = 1
                let SizingString: String = "{} [W]".format(self.FieldNames[FieldNum - 1])
                let CapSizingMethod: Int = self.HeatingCapMethod
                zoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod
                if CapSizingMethod == DataSizing.HeatingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                    if CapSizingMethod == DataSizing.HeatingDesignCapacity:
                        if self.ScaledHeatingCapacity == DataSizing.AutoSize:
                            zoneEqSizing.DesHeatingLoad = finalZoneSizing.NonAirSysDesHeatLoad
                        else:
                            zoneEqSizing.DesHeatingLoad = self.ScaledHeatingCapacity
                        zoneEqSizing.HeatingCapacity = True
                        TempSize = zoneEqSizing.DesHeatingLoad
                    elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                        zoneEqSizing.HeatingCapacity = True
                        zoneEqSizing.DesHeatingLoad = self.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                        TempSize = zoneEqSizing.DesHeatingLoad
                        state.dataSize.DataScalableCapSizingON = True
                    elif CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                        zoneEqSizing.HeatingCapacity = True
                        state.dataSize.DataFracOfAutosizedHeatingCapacity = self.ScaledHeatingCapacity
                        zoneEqSizing.DesHeatingLoad = finalZoneSizing.NonAirSysDesHeatLoad
                        TempSize = DataSizing.AutoSize
                        state.dataSize.DataScalableCapSizingON = True
                    else:
                        TempSize = self.ScaledHeatingCapacity
                    var PrintFlag: Bool = False
                    var errorsFound: Bool = False
                    var sizerHeatingCapacity = HeatingCapacitySizer()
                    sizerHeatingCapacity.overrideSizingString(SizingString)
                    sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                    DesCoilLoad = sizerHeatingCapacity.size(state, TempSize, errorsFound)
                    state.dataSize.DataScalableCapSizingON = False
                else:
                    DesCoilLoad = 0.0
                if DesCoilLoad >= SmallLoad:
                    self.DesAirMassFlowRate = 2.0 * rho * self.WaterVolFlowRateMax
                    UA0 = 0.001 * DesCoilLoad
                    UA1 = DesCoilLoad
                    self.UA = UA0
                    var LoadMet: Float64 = 0.0
                    SimHWConvective(state, baseboardNum, LoadMet)
                    if LoadMet < DesCoilLoad:
                        self.UA = UA1
                        SimHWConvective(state, baseboardNum, LoadMet)
                        if LoadMet > DesCoilLoad:
                            var f = fn(in state: EnergyPlusData, baseboardNum: Int, DesCoilLoad: Float64) -> (Float64) -> Float64:
                                return fn(UA: Float64) -> Float64:
                                    state.dataBaseboardRadiator.baseboards[baseboardNum - 1].UA = UA
                                    var localBaseBoardNum: Int = baseboardNum
                                    var LoadMet: Float64 = 0.0
                                    SimHWConvective(state, localBaseBoardNum, LoadMet)
                                    return (DesCoilLoad - LoadMet) / DesCoilLoad
                            var SolFla: Int = 0
                            General.SolveRoot(state, Acc, MaxIte, SolFla, UA, f, UA0, UA1)
                            if SolFla == -1:
                                ShowSevereError(state, "SizeBaseboard: Autosizing of HW baseboard UA failed for {}=\"{}\"".format(cCMO_BBRadiator_Water, self.EquipID))
                                ShowContinueError(state, "Iteration limit exceeded in calculating coil UA")
                                if UAAutoSize:
                                    ErrorsFound = True
                                else:
                                    ShowContinueError(state, "Could not calculate design value for comparison to user value, and the simulation continues")
                                    UA = 0.0
                            elif SolFla == -2:
                                ShowSevereError(state, "SizeBaseboard: Autosizing of HW baseboard UA failed for {}=\"{}\"".format(cCMO_BBRadiator_Water, self.EquipID))
                                ShowContinueError(state, "Bad starting values for UA")
                                if UAAutoSize:
                                    ErrorsFound = True
                                else:
                                    ShowContinueError(state, "Could not calculate design value for comparison to user value, and the simulation continues")
                                    UA = 0.0
                            UADes = UA
                        else:  // LoadMet <= DesCoilLoad
                            UADes = UA1
                            if UAAutoSize:
                                ShowWarningError(state, "SizeBaseboard: Autosizing of HW baseboard UA failed for {}=\"{}\"".format(cCMO_BBRadiator_Water, self.EquipID))
                                ShowContinueError(state, "Design UA set equal to design coil load for {}=\"{}\"".format(cCMO_BBRadiator_Water, self.EquipID))
                                ShowContinueError(state, "Design coil load used during sizing = {:.5f} W.".format(DesCoilLoad))
                                ShowContinueError(state, "Inlet water temperature used during sizing = {:.5f} C.".format(self.WaterInletTemp))
                    else:  // LoadMet >= DesCoilLoad
                        UADes = UA0
                        if UAAutoSize:
                            ShowWarningError(state, "SizeBaseboard: Autosizing of HW baseboard UA failed for {}=\"{}\"".format(cCMO_BBRadiator_Water, self.EquipID))
                            ShowContinueError(state, "Design UA set equal to 0.001 * design coil load for {}=\"{}\"".format(cCMO_BBRadiator_Water, self.EquipID))
                            ShowContinueError(state, "Design coil load used during sizing = {:.5f} W.".format(DesCoilLoad))
                            ShowContinueError(state, "Inlet water temperature used during sizing = {:.5f} C.".format(self.WaterInletTemp))
                else:
                    UADes = 0.0
                if UAAutoSize:
                    self.UA = UADes
                    BaseSizer.reportSizerOutput(
                        state, cCMO_BBRadiator_Water, self.EquipID, "Design Size U-Factor Times Area Value [W/K]", UADes
                    )
                else:
                    self.UA = UAUser
                    if UAUser > 0.0 and UADes > 0.0:
                        BaseSizer.reportSizerOutput(
                            state,
                            cCMO_BBRadiator_Water,
                            self.EquipID,
                            "Design Size U-Factor Times Area Value [W/K]",
                            UADes,
                            "User-Specified U-Factor Times Area Value [W/K]",
                            UAUser
                        )
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(UADes - UAUser) / UAUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(
                                    state,
                                    "SizeBaseboard: Potential issue with equipment sizing for ZoneHVAC:Baseboard:Convective:Water=\"{}\".".format(self.EquipID)
                                )
                                ShowContinueError(state, "User-Specified U-Factor Times Area Value of {:.2f} [W/K]".format(UAUser))
                                ShowContinueError(state, "differs from Design Size U-Factor Times Area Value of {:.2f} [W/K]".format(UADes))
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
    else:
        if self.WaterVolFlowRateMax == DataSizing.AutoSize or self.UA == DataSizing.AutoSize:
            ShowSevereError(state, "SizeBaseboard: {}=\"{}\"".format(cCMO_BBRadiator_Water, self.EquipID))
            ShowContinueError(state, "...Autosizing of hot water baseboard requires a heating loop Sizing:Plant object")
            ErrorsFound = True
    PlantUtilities.RegisterPlantCompDesignFlow(state, self.WaterInletNode, self.WaterVolFlowRateMax)
    if ErrorsFound:
        ShowFatalError(state, "SizeBaseboard: Preceding sizing errors cause program termination")
def BaseboardParams.checkForZoneSizing(inout self, state: EnergyPlusData):
    if (self.UA == DataSizing.AutoSize) or (self.WaterVolFlowRateMax == DataSizing.AutoSize) or \
       ((self.HeatingCapMethod == DataSizing.HeatingDesignCapacity) and (self.ScaledHeatingCapacity == DataSizing.AutoSize)) or \
       ((self.HeatingCapMethod == DataSizing.FractionOfAutosizedHeatingCapacity) and (self.ScaledHeatingCapacity == DataSizing.AutoSize)):
        CheckZoneSizing(state, cCMO_BBRadiator_Water, self.EquipID)
def SimHWConvective(inout state: EnergyPlusData, BaseboardNum: Int, inout LoadMet: Float64):
    let RoutineName: String = cCMO_BBRadiator_Water + ":SimHWConvective"
    var ZoneNum: Int
    var WaterInletTemp: Float64
    var AirInletTemp: Float64
    var CpAir: Float64
    var CpWater: Float64
    var AirMassFlowRate: Float64
    var WaterMassFlowRate: Float64
    var CapacitanceAir: Float64
    var CapacitanceWater: Float64
    var CapacitanceMax: Float64
    var CapacitanceMin: Float64
    var CapacityRatio: Float64
    var NTU: Float64
    var Effectiveness: Float64
    var WaterOutletTemp: Float64
    var AirOutletTemp: Float64
    var AA: Float64
    var BB: Float64
    var CC: Float64
    var QZnReq: Float64
    var baseboard = state.dataBaseboardRadiator.baseboards[BaseboardNum - 1]
    ZoneNum = baseboard.ZonePtr
    QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToHeatSP
    if baseboard.MySizeFlag:
        QZnReq = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad
    WaterInletTemp = baseboard.WaterInletTemp
    AirInletTemp = baseboard.AirInletTemp
    CpWater = baseboard.plantLoc.loop.glycol.getSpecificHeat(state, WaterInletTemp, RoutineName)
    CpAir = PsyCpAirFnW(baseboard.AirInletHumRat)
    if baseboard.DesAirMassFlowRate > 0.0:
        AirMassFlowRate = baseboard.DesAirMassFlowRate
    else:
        AirMassFlowRate = baseboard.AirMassFlowRate
        if AirMassFlowRate <= 0.0:
            AirMassFlowRate = 2.0 * baseboard.WaterMassFlowRateMax
    WaterMassFlowRate = state.dataLoopNodes.Node[baseboard.WaterInletNode].MassFlowRate
    CapacitanceAir = CpAir * AirMassFlowRate
    if QZnReq > SmallLoad and (not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum] or baseboard.MySizeFlag) and \
       (baseboard.availSched!.getCurrentVal() > 0 or baseboard.MySizeFlag) and (WaterMassFlowRate > 0.0):
        CapacitanceWater = CpWater * WaterMassFlowRate
        CapacitanceMax = max(CapacitanceAir, CapacitanceWater)
        CapacitanceMin = min(CapacitanceAir, CapacitanceWater)
        CapacityRatio = CapacitanceMin / CapacitanceMax
        NTU = baseboard.UA / CapacitanceMin
        AA = -CapacityRatio * pow(NTU, 0.78)
        if AA < EXP_LowerLimit:
            BB = 0.0
        else:
            BB = exp(AA)
        CC = (1.0 / CapacityRatio) * pow(NTU, 0.22) * (BB - 1.0)
        if CC < EXP_LowerLimit:
            Effectiveness = 1.0
        else:
            Effectiveness = 1.0 - exp(CC)
        AirOutletTemp = AirInletTemp + Effectiveness * CapacitanceMin * (WaterInletTemp - AirInletTemp) / CapacitanceAir
        WaterOutletTemp = WaterInletTemp - CapacitanceAir * (AirOutletTemp - AirInletTemp) / CapacitanceWater
        LoadMet = CapacitanceWater * (WaterInletTemp - WaterOutletTemp)
        baseboard.WaterOutletEnthalpy = baseboard.WaterInletEnthalpy - LoadMet / WaterMassFlowRate
    else:
        AirOutletTemp = AirInletTemp
        WaterOutletTemp = WaterInletTemp
        LoadMet = 0.0
        baseboard.WaterOutletEnthalpy = baseboard.WaterInletEnthalpy
        WaterMassFlowRate = 0.0
        SetActuatedBranchFlowRate(state, WaterMassFlowRate, baseboard.WaterInletNode, baseboard.plantLoc, False)
        AirMassFlowRate = 0.0
    baseboard.WaterOutletTemp = WaterOutletTemp
    baseboard.AirOutletTemp = AirOutletTemp
    baseboard.Power = LoadMet
    baseboard.WaterMassFlowRate = WaterMassFlowRate
    baseboard.AirMassFlowRate = AirMassFlowRate
def UpdateBaseboard(inout state: EnergyPlusData, BaseboardNum: Int):
    var WaterInletNode: Int
    var WaterOutletNode: Int
    var baseboard = state.dataBaseboardRadiator
    WaterInletNode = baseboard.baseboards[BaseboardNum - 1].WaterInletNode
    WaterOutletNode = baseboard.baseboards[BaseboardNum - 1].WaterOutletNode
    SafeCopyPlantNode(state, WaterInletNode, WaterOutletNode)
    state.dataLoopNodes.Node[WaterOutletNode].Temp = baseboard.baseboards[BaseboardNum - 1].WaterOutletTemp
    state.dataLoopNodes.Node[WaterOutletNode].Enthalpy = baseboard.baseboards[BaseboardNum - 1].WaterOutletEnthalpy
struct BaseboardRadiatorData(BaseGlobalStruct):
    var getInputFlag: Bool = True
    var baseboards: List[BaseboardParams]
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        new(this) BaseboardRadiatorData()
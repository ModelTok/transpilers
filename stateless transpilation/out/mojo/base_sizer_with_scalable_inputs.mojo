# EXTERNAL DEPS (to wire in glue):
# - BaseSizerWithFanHeatInputs: from EnergyPlus.Autosizing.BaseSizerWithFanHeatInputs
# - EnergyPlusData: from EnergyPlus.Data.EnergyPlusData (state parameter)
# - DataSizing constants: FlowPerFloorArea, FractionOfAutosizedCoolingAirflow, SupplyAirFlowRate, None
# - HVAC.CoilType: from EnergyPlus.HVAC (enum with Invalid member)
# - ReportCoilSelection.setCoilSupplyFanInfo: from EnergyPlus.Autosizing.ReportCoilSelection
# - state.dataSize: global sizing data object
# - state.dataHVACGlobal: global HVAC data object
# - state.dataHeatBal.Zone: zone heat balance data array
# - state.dataFans.fans: fan data array

from collections.abc import Sequence


@value
struct ZoneHVACSizingData:
    var CoolingSAFMethod: Int32
    var MaxCoolAirVolFlow: Float64
    
    fn __init__(inout self) -> None:
        self.CoolingSAFMethod = 0
        self.MaxCoolAirVolFlow = 0.0


@value
struct PrimaryAirSystemStub:
    var supFanNum: Int32
    
    fn __init__(inout self) -> None:
        self.supFanNum = 0


@value
struct ZoneEqSizingStub:
    var SizingMethod: DynamicVector[Int32]
    
    fn __init__(inout self) -> None:
        self.SizingMethod = DynamicVector[Int32]()


@value
struct ZoneStub:
    var FloorArea: Float64
    
    fn __init__(inout self) -> None:
        self.FloorArea = 0.0


trait EnergyPlusDataTrait:
    fn get_dataSize_DataScalableSizingON(self) -> Bool: ...
    fn set_dataSize_DataScalableSizingON(inout self, value: Bool) -> None: ...
    fn get_dataSize_DataScalableCapSizingON(self) -> Bool: ...
    fn set_dataSize_DataScalableCapSizingON(inout self, value: Bool) -> None: ...
    fn get_dataSize_HRFlowSizingFlag(self) -> Bool: ...
    fn get_dataSize_ZoneCoolingOnlyFan(self) -> Bool: ...
    fn get_dataSize_ZoneHeatingOnlyFan(self) -> Bool: ...
    fn get_dataSize_DataFracOfAutosizedCoolingAirflow(self) -> Float64: ...
    fn get_dataSize_DataFracOfAutosizedHeatingAirflow(self) -> Float64: ...
    fn set_dataSize_DataFracOfAutosizedCoolingAirflow(inout self, value: Float64) -> None: ...
    fn get_dataSize_DataFlowPerCoolingCapacity(self) -> Float64: ...
    fn get_dataSize_DataAutosizedCoolingCapacity(self) -> Float64: ...
    fn get_dataSize_DataFlowPerHeatingCapacity(self) -> Float64: ...
    fn get_dataSize_DataAutosizedHeatingCapacity(self) -> Float64: ...
    fn get_dataSize_DataCoilSizingAirInTemp(self) -> Float64: ...
    fn get_dataSize_DataCoilSizingAirInHumRat(self) -> Float64: ...
    fn get_dataSize_DataCoilSizingAirOutTemp(self) -> Float64: ...
    fn get_dataSize_DataCoilSizingAirOutHumRat(self) -> Float64: ...
    fn get_dataSize_DataCoilSizingFanCoolLoad(self) -> Float64: ...
    fn get_dataSize_DataCoilSizingCapFT(self) -> Float64: ...
    fn get_dataSize_DataTotCapCurveIndex(self) -> Int32: ...
    fn get_dataSize_DataTotCapCurveValue(self) -> Float64: ...
    fn get_dataSize_DataFracOfAutosizedCoolingCapacity(self) -> Float64: ...
    fn get_dataSize_DataFracOfAutosizedHeatingCapacity(self) -> Float64: ...
    fn get_dataSize_DataCoolCoilCap(self) -> Float64: ...
    fn get_dataSize_DataCoilIsSuppHeater(self) -> Bool: ...
    fn get_dataSize_SuppHeatCap(self) -> Float64: ...
    fn get_dataSize_UnitaryHeatCap(self) -> Float64: ...
    fn get_dataSize_DataCoolCoilType(self) -> Int32: ...
    fn get_dataSize_DataCoolCoilIndex(self) -> Int32: ...
    fn get_dataSize_ZoneHVACSizing(self) -> DynamicVector[ZoneHVACSizingData]: ...
    fn set_dataSize_ZoneHVACSizing(inout self, value: DynamicVector[ZoneHVACSizingData]) -> None: ...
    fn get_dataSize_DataZoneNumber(self) -> Int32: ...
    fn get_dataHVACGlobal_NumPrimaryAirSys(self) -> Int32: ...
    fn get_dataHeatBal_Zone(self, index: Int32) -> ZoneStub: ...
    fn get_dataFans_fans(self, index: Int32) -> Pointer[UInt8]: ...


struct BaseSizerWithFanHeatInputsStub:
    var dataScalableSizingON: Bool
    var dataScalableCapSizingON: Bool
    var isCoilReportObject: Bool
    var curSysNum: Int32
    var primaryAirSystem: DynamicVector[PrimaryAirSystemStub]
    var coilReportNum: Int32
    var curZoneEqNum: Int32
    var zoneEqSizing: DynamicVector[ZoneEqSizingStub]
    var sizingType: Int32
    var zoneAirFlowSizMethod: Int32
    var dataFractionUsedForSizing: Float64
    var dataConstantUsedForSizing: Float64
    
    fn __init__(inout self) -> None:
        self.dataScalableSizingON = False
        self.dataScalableCapSizingON = False
        self.isCoilReportObject = False
        self.curSysNum = 0
        self.primaryAirSystem = DynamicVector[PrimaryAirSystemStub]()
        self.coilReportNum = 0
        self.curZoneEqNum = 0
        self.zoneEqSizing = DynamicVector[ZoneEqSizingStub]()
        self.sizingType = 0
        self.zoneAirFlowSizMethod = 0
        self.dataFractionUsedForSizing = 0.0
        self.dataConstantUsedForSizing = 0.0
    
    fn initializeWithinEP(inout self, state: Reference[EnergyPlusDataTrait], _compType: String,
                         _compName: String, _printWarningFlag: Bool, _callingRoutine: String) -> None:
        pass
    
    fn clearState(inout self) -> None:
        pass


struct BaseSizerWithScalableInputs(BaseSizerWithFanHeatInputsStub):
    var zoneCoolingOnlyFan: Bool
    var zoneHeatingOnlyFan: Bool
    var dataHRFlowSizingFlag: Bool
    var dataFracOfAutosizedCoolingAirflow: Float64
    var dataFracOfAutosizedHeatingAirflow: Float64
    var dataFlowPerCoolingCapacity: Float64
    var dataAutosizedCoolingCapacity: Float64
    var dataFlowPerHeatingCapacity: Float64
    var dataAutosizedHeatingCapacity: Float64
    var dataCoilSizingAirInTemp: Float64
    var dataCoilSizingAirInHumRat: Float64
    var dataCoilSizingAirOutTemp: Float64
    var dataCoilSizingAirOutHumRat: Float64
    var dataCoilSizingFanCoolLoad: Float64
    var dataCoilSizingCapFT: Float64
    var dataTotCapCurveValue: Float64
    var dataFracOfAutosizedCoolingCapacity: Float64
    var dataFracOfAutosizedHeatingCapacity: Float64
    var dataCoolCoilCap: Float64
    var dataCoilIsSuppHeater: Bool
    var suppHeatCap: Float64
    var unitaryHeatCap: Float64
    var dataTotCapCurveIndex: Int32
    var dataCoolCoilType: Int32
    var dataCoolCoilIndex: Int32
    var zoneHVACSizingIndex: Int32
    var zoneHVACSizing: DynamicVector[ZoneHVACSizingData]
    
    fn __init__(inout self) -> None:
        self.zoneCoolingOnlyFan = False
        self.zoneHeatingOnlyFan = False
        self.dataHRFlowSizingFlag = False
        self.dataFracOfAutosizedCoolingAirflow = 0.0
        self.dataFracOfAutosizedHeatingAirflow = 0.0
        self.dataFlowPerCoolingCapacity = 0.0
        self.dataAutosizedCoolingCapacity = 0.0
        self.dataFlowPerHeatingCapacity = 0.0
        self.dataAutosizedHeatingCapacity = 0.0
        self.dataCoilSizingAirInTemp = 0.0
        self.dataCoilSizingAirInHumRat = 0.0
        self.dataCoilSizingAirOutTemp = 0.0
        self.dataCoilSizingAirOutHumRat = 0.0
        self.dataCoilSizingFanCoolLoad = 0.0
        self.dataCoilSizingCapFT = 0.0
        self.dataTotCapCurveValue = 0.0
        self.dataFracOfAutosizedCoolingCapacity = 0.0
        self.dataFracOfAutosizedHeatingCapacity = 0.0
        self.dataCoolCoilCap = 0.0
        self.dataCoilIsSuppHeater = False
        self.suppHeatCap = 0.0
        self.unitaryHeatCap = 0.0
        self.dataTotCapCurveIndex = 0
        self.dataCoolCoilType = -1
        self.dataCoolCoilIndex = -1
        self.zoneHVACSizingIndex = 0
        self.zoneHVACSizing = DynamicVector[ZoneHVACSizingData]()
        super().__init__()
    
    fn initializeWithinEP(inout self, state: Reference[EnergyPlusDataTrait], _compType: String,
                         _compName: String, _printWarningFlag: Bool, _callingRoutine: String) -> None:
        BaseSizerWithFanHeatInputsStub.initializeWithinEP(self, state, _compType, _compName, _printWarningFlag, _callingRoutine)
        
        self.dataScalableSizingON = state[].get_dataSize_DataScalableSizingON()
        self.dataScalableCapSizingON = state[].get_dataSize_DataScalableCapSizingON()
        self.dataHRFlowSizingFlag = state[].get_dataSize_HRFlowSizingFlag()
        self.zoneCoolingOnlyFan = state[].get_dataSize_ZoneCoolingOnlyFan()
        self.zoneHeatingOnlyFan = state[].get_dataSize_ZoneHeatingOnlyFan()
        self.dataFracOfAutosizedCoolingAirflow = state[].get_dataSize_DataFracOfAutosizedCoolingAirflow()
        self.dataFracOfAutosizedHeatingAirflow = state[].get_dataSize_DataFracOfAutosizedHeatingAirflow()
        self.dataFlowPerCoolingCapacity = state[].get_dataSize_DataFlowPerCoolingCapacity()
        self.dataAutosizedCoolingCapacity = state[].get_dataSize_DataAutosizedCoolingCapacity()
        self.dataFlowPerHeatingCapacity = state[].get_dataSize_DataFlowPerHeatingCapacity()
        self.dataAutosizedHeatingCapacity = state[].get_dataSize_DataAutosizedHeatingCapacity()
        
        self.dataCoilSizingAirInTemp = state[].get_dataSize_DataCoilSizingAirInTemp()
        self.dataCoilSizingAirInHumRat = state[].get_dataSize_DataCoilSizingAirInHumRat()
        self.dataCoilSizingAirOutTemp = state[].get_dataSize_DataCoilSizingAirOutTemp()
        self.dataCoilSizingAirOutHumRat = state[].get_dataSize_DataCoilSizingAirOutHumRat()
        self.dataCoilSizingFanCoolLoad = state[].get_dataSize_DataCoilSizingFanCoolLoad()
        self.dataCoilSizingCapFT = state[].get_dataSize_DataCoilSizingCapFT()
        self.dataTotCapCurveIndex = state[].get_dataSize_DataTotCapCurveIndex()
        self.dataTotCapCurveValue = state[].get_dataSize_DataTotCapCurveValue()
        self.dataFracOfAutosizedCoolingCapacity = state[].get_dataSize_DataFracOfAutosizedCoolingCapacity()
        self.dataFracOfAutosizedHeatingCapacity = state[].get_dataSize_DataFracOfAutosizedHeatingCapacity()
        self.dataCoolCoilCap = state[].get_dataSize_DataCoolCoilCap()
        self.dataCoilIsSuppHeater = state[].get_dataSize_DataCoilIsSuppHeater()
        self.suppHeatCap = state[].get_dataSize_SuppHeatCap()
        self.unitaryHeatCap = state[].get_dataSize_UnitaryHeatCap()
        self.dataCoolCoilType = state[].get_dataSize_DataCoolCoilType()
        self.dataCoolCoilIndex = state[].get_dataSize_DataCoolCoilIndex()
        
        self.zoneHVACSizing = state[].get_dataSize_ZoneHVACSizing()
        
        if (self.isCoilReportObject and self.curSysNum > 0 and len(self.primaryAirSystem) > 0 and
            self.curSysNum <= state[].get_dataHVACGlobal_NumPrimaryAirSys()):
            
            if self.primaryAirSystem[self.curSysNum - 1].supFanNum > 0:
                var fan_num = self.primaryAirSystem[self.curSysNum - 1].supFanNum
                var fan_data = state[].get_dataFans_fans(fan_num)
                ReportCoilSelection.setCoilSupplyFanInfo(state, self.coilReportNum, "", "", fan_num)
        
        if self.curZoneEqNum != 0:
            if self.zoneHVACSizingIndex > 0:
                var coolingSAFMethod = self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].CoolingSAFMethod
                self.zoneAirFlowSizMethod = coolingSAFMethod
                self.dataFractionUsedForSizing = 1.0
                self.dataConstantUsedForSizing = self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].MaxCoolAirVolFlow
                if coolingSAFMethod == 1:
                    state[].set_dataSize_DataScalableSizingON(True)
                    var zone_data = state[].get_dataHeatBal_Zone(state[].get_dataSize_DataZoneNumber())
                    self.dataConstantUsedForSizing = (self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].MaxCoolAirVolFlow *
                                                      zone_data.FloorArea)
                elif coolingSAFMethod == 2:
                    state[].set_dataSize_DataFracOfAutosizedCoolingAirflow(self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].MaxCoolAirVolFlow)
                    state[].set_dataSize_DataScalableSizingON(True)
            else:
                if len(self.zoneEqSizing) > 0 and len(self.zoneEqSizing[self.curZoneEqNum - 1].SizingMethod) > 0:
                    self.zoneAirFlowSizMethod = self.zoneEqSizing[self.curZoneEqNum - 1].SizingMethod[int(self.sizingType)]
                else:
                    self.zoneAirFlowSizMethod = 0
                
                if self.zoneAirFlowSizMethod == 0:
                    pass
                elif self.zoneAirFlowSizMethod == 3 or self.zoneAirFlowSizMethod == 0:
                    pass
    
    fn clearState(inout self) -> None:
        BaseSizerWithFanHeatInputsStub.clearState(self)
        self.zoneCoolingOnlyFan = False
        self.zoneHeatingOnlyFan = False
        self.dataHRFlowSizingFlag = False
        self.dataFracOfAutosizedCoolingAirflow = 0.0
        self.dataFracOfAutosizedHeatingAirflow = 0.0
        self.dataFlowPerCoolingCapacity = 0.0
        self.dataAutosizedCoolingCapacity = 0.0
        self.dataFlowPerHeatingCapacity = 0.0
        self.dataAutosizedHeatingCapacity = 0.0
        self.dataCoilSizingAirInTemp = 0.0
        self.dataCoilSizingAirInHumRat = 0.0
        self.dataCoilSizingAirOutTemp = 0.0
        self.dataCoilSizingAirOutHumRat = 0.0
        self.dataCoilSizingFanCoolLoad = 0.0
        self.dataCoilSizingCapFT = 0.0
        self.dataTotCapCurveIndex = 0
        self.dataTotCapCurveValue = 0.0
        self.dataFracOfAutosizedCoolingCapacity = 0.0
        self.dataFracOfAutosizedHeatingCapacity = 0.0
        self.dataCoolCoilCap = 0.0
        self.dataCoilIsSuppHeater = False
        self.suppHeatCap = 0.0
        self.unitaryHeatCap = 0.0
        self.zoneHVACSizingIndex = 0
        self.dataCoolCoilType = -1
        self.dataCoolCoilIndex = -1
        self.zoneHVACSizing = DynamicVector[ZoneHVACSizingData]()
    
    fn setHVACSizingIndexData(inout self, index: Int32) -> None:
        self.zoneHVACSizingIndex = index


struct BaseSizerWithScalableInputsData:
    
    fn init_constant_state(inout self, state: Reference[EnergyPlusDataTrait]) -> None:
        pass
    
    fn init_state(inout self, state: Reference[EnergyPlusDataTrait]) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        pass


struct ReportCoilSelection:
    
    @staticmethod
    fn setCoilSupplyFanInfo(state: Reference[EnergyPlusDataTrait], coil_report_num: Int32,
                           fan_name: String, fan_type: String, fan_num: Int32) -> None:
        pass

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

from typing import Protocol, Any, List
from dataclasses import dataclass, field


@dataclass
class ZoneHVACSizingData:
    """Stub for DataSizing.ZoneHVACSizingData"""
    CoolingSAFMethod: int = 0
    MaxCoolAirVolFlow: float = 0.0


@dataclass
class PrimaryAirSystemStub:
    """Stub for primary air system record"""
    supFanNum: int = 0


@dataclass
class ZoneEqSizingStub:
    """Stub for zone equipment sizing record"""
    SizingMethod: List[int] = field(default_factory=list)


@dataclass
class ZoneStub:
    """Stub for zone data"""
    FloorArea: float = 0.0


class EnergyPlusDataProtocol(Protocol):
    """Protocol for EnergyPlusData state object"""
    
    class DataSizeStub:
        DataScalableSizingON: bool
        DataScalableCapSizingON: bool
        HRFlowSizingFlag: bool
        ZoneCoolingOnlyFan: bool
        ZoneHeatingOnlyFan: bool
        DataFracOfAutosizedCoolingAirflow: float
        DataFracOfAutosizedHeatingAirflow: float
        DataFlowPerCoolingCapacity: float
        DataAutosizedCoolingCapacity: float
        DataFlowPerHeatingCapacity: float
        DataAutosizedHeatingCapacity: float
        DataCoilSizingAirInTemp: float
        DataCoilSizingAirInHumRat: float
        DataCoilSizingAirOutTemp: float
        DataCoilSizingAirOutHumRat: float
        DataCoilSizingFanCoolLoad: float
        DataCoilSizingCapFT: float
        DataTotCapCurveIndex: int
        DataTotCapCurveValue: float
        DataFracOfAutosizedCoolingCapacity: float
        DataFracOfAutosizedHeatingCapacity: float
        DataCoolCoilCap: float
        DataCoilIsSuppHeater: bool
        SuppHeatCap: float
        UnitaryHeatCap: float
        DataCoolCoilType: int
        DataCoolCoilIndex: int
        ZoneHVACSizing: List[ZoneHVACSizingData]
        DataZoneNumber: int
    
    class DataHVACGlobalStub:
        NumPrimaryAirSys: int
    
    class DataHeatBalStub:
        def Zone(self, index: int) -> ZoneStub: ...
    
    class DataFansStub:
        def fans(self, index: int) -> Any: ...
    
    dataSize: DataSizeStub
    dataHVACGlobal: DataHVACGlobalStub
    dataHeatBal: DataHeatBalStub
    dataFans: DataFansStub


class BaseSizerWithFanHeatInputsStub:
    """Stub for BaseSizerWithFanHeatInputs base class"""
    
    def __init__(self) -> None:
        self.dataScalableSizingON: bool = False
        self.dataScalableCapSizingON: bool = False
        self.isCoilReportObject: bool = False
        self.curSysNum: int = 0
        self.primaryAirSystem: List[PrimaryAirSystemStub] = []
        self.coilReportNum: int = 0
        self.curZoneEqNum: int = 0
        self.zoneEqSizing: List[ZoneEqSizingStub] = []
        self.sizingType: int = 0
        self.zoneAirFlowSizMethod: int = 0
        self.dataFractionUsedForSizing: float = 0.0
        self.dataConstantUsedForSizing: float = 0.0
    
    def initializeWithinEP(self, state: EnergyPlusDataProtocol, _compType: str,
                          _compName: str, _printWarningFlag: bool, _callingRoutine: str) -> None:
        pass
    
    def clearState(self) -> None:
        pass


class BaseSizerWithScalableInputs(BaseSizerWithFanHeatInputsStub):
    
    def __init__(self) -> None:
        super().__init__()
        self.zoneCoolingOnlyFan: bool = False
        self.zoneHeatingOnlyFan: bool = False
        self.dataHRFlowSizingFlag: bool = False
        self.dataFracOfAutosizedCoolingAirflow: float = 0.0
        self.dataFracOfAutosizedHeatingAirflow: float = 0.0
        self.dataFlowPerCoolingCapacity: float = 0.0
        self.dataAutosizedCoolingCapacity: float = 0.0
        self.dataFlowPerHeatingCapacity: float = 0.0
        self.dataAutosizedHeatingCapacity: float = 0.0
        
        self.dataCoilSizingAirInTemp: float = 0.0
        self.dataCoilSizingAirInHumRat: float = 0.0
        self.dataCoilSizingAirOutTemp: float = 0.0
        self.dataCoilSizingAirOutHumRat: float = 0.0
        self.dataCoilSizingFanCoolLoad: float = 0.0
        self.dataCoilSizingCapFT: float = 0.0
        self.dataTotCapCurveValue: float = 0.0
        self.dataFracOfAutosizedCoolingCapacity: float = 0.0
        self.dataFracOfAutosizedHeatingCapacity: float = 0.0
        self.dataCoolCoilCap: float = 0.0
        self.dataCoilIsSuppHeater: bool = False
        self.suppHeatCap: float = 0.0
        self.unitaryHeatCap: float = 0.0
        self.dataTotCapCurveIndex: int = 0
        self.dataCoolCoilType: int = -1  # HVAC::CoilType::Invalid
        self.dataCoolCoilIndex: int = -1
        
        self.zoneHVACSizingIndex: int = 0
        self.zoneHVACSizing: List[ZoneHVACSizingData] = []
    
    def initializeWithinEP(self, state: EnergyPlusDataProtocol, _compType: str,
                          _compName: str, _printWarningFlag: bool, _callingRoutine: str) -> None:
        super().initializeWithinEP(state, _compType, _compName, _printWarningFlag, _callingRoutine)
        
        self.dataScalableSizingON = state.dataSize.DataScalableSizingON
        self.dataScalableCapSizingON = state.dataSize.DataScalableCapSizingON
        self.dataHRFlowSizingFlag = state.dataSize.HRFlowSizingFlag
        self.zoneCoolingOnlyFan = state.dataSize.ZoneCoolingOnlyFan
        self.zoneHeatingOnlyFan = state.dataSize.ZoneHeatingOnlyFan
        self.dataFracOfAutosizedCoolingAirflow = state.dataSize.DataFracOfAutosizedCoolingAirflow
        self.dataFracOfAutosizedHeatingAirflow = state.dataSize.DataFracOfAutosizedHeatingAirflow
        self.dataFlowPerCoolingCapacity = state.dataSize.DataFlowPerCoolingCapacity
        self.dataAutosizedCoolingCapacity = state.dataSize.DataAutosizedCoolingCapacity
        self.dataFlowPerHeatingCapacity = state.dataSize.DataFlowPerHeatingCapacity
        self.dataAutosizedHeatingCapacity = state.dataSize.DataAutosizedHeatingCapacity
        
        self.dataCoilSizingAirInTemp = state.dataSize.DataCoilSizingAirInTemp
        self.dataCoilSizingAirInHumRat = state.dataSize.DataCoilSizingAirInHumRat
        self.dataCoilSizingAirOutTemp = state.dataSize.DataCoilSizingAirOutTemp
        self.dataCoilSizingAirOutHumRat = state.dataSize.DataCoilSizingAirOutHumRat
        self.dataCoilSizingFanCoolLoad = state.dataSize.DataCoilSizingFanCoolLoad
        self.dataCoilSizingCapFT = state.dataSize.DataCoilSizingCapFT
        self.dataTotCapCurveIndex = state.dataSize.DataTotCapCurveIndex
        self.dataTotCapCurveValue = state.dataSize.DataTotCapCurveValue
        self.dataFracOfAutosizedCoolingCapacity = state.dataSize.DataFracOfAutosizedCoolingCapacity
        self.dataFracOfAutosizedHeatingCapacity = state.dataSize.DataFracOfAutosizedHeatingCapacity
        self.dataCoolCoilCap = state.dataSize.DataCoolCoilCap
        self.dataCoilIsSuppHeater = state.dataSize.DataCoilIsSuppHeater
        self.suppHeatCap = state.dataSize.SuppHeatCap
        self.unitaryHeatCap = state.dataSize.UnitaryHeatCap
        self.dataCoolCoilType = state.dataSize.DataCoolCoilType
        self.dataCoolCoilIndex = state.dataSize.DataCoolCoilIndex
        
        self.zoneHVACSizing = state.dataSize.ZoneHVACSizing
        
        if (self.isCoilReportObject and self.curSysNum > 0 and len(self.primaryAirSystem) > 0 and
            self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys):
            
            if self.primaryAirSystem[self.curSysNum - 1].supFanNum > 0:
                fan_num = self.primaryAirSystem[self.curSysNum - 1].supFanNum
                ReportCoilSelection.setCoilSupplyFanInfo(state,
                                                        self.coilReportNum,
                                                        state.dataFans.fans(fan_num).Name,
                                                        state.dataFans.fans(fan_num).type,
                                                        fan_num)
        
        if self.curZoneEqNum != 0:
            if self.zoneHVACSizingIndex > 0:
                coolingSAFMethod = self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].CoolingSAFMethod
                self.zoneAirFlowSizMethod = coolingSAFMethod
                self.dataFractionUsedForSizing = 1.0
                self.dataConstantUsedForSizing = self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].MaxCoolAirVolFlow
                if coolingSAFMethod == 1:  # DataSizing::FlowPerFloorArea
                    state.dataSize.DataScalableSizingON = True
                    self.dataConstantUsedForSizing = (self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].MaxCoolAirVolFlow *
                                                      state.dataHeatBal.Zone(state.dataSize.DataZoneNumber).FloorArea)
                elif coolingSAFMethod == 2:  # DataSizing::FractionOfAutosizedCoolingAirflow
                    state.dataSize.DataFracOfAutosizedCoolingAirflow = self.zoneHVACSizing[self.zoneHVACSizingIndex - 1].MaxCoolAirVolFlow
                    state.dataSize.DataScalableSizingON = True
            else:
                if len(self.zoneEqSizing) > 0 and len(self.zoneEqSizing[self.curZoneEqNum - 1].SizingMethod) > 0:
                    self.zoneAirFlowSizMethod = self.zoneEqSizing[self.curZoneEqNum - 1].SizingMethod[int(self.sizingType)]
                else:
                    self.zoneAirFlowSizMethod = 0
                
                if self.zoneAirFlowSizMethod == 0:
                    pass
                elif self.zoneAirFlowSizMethod == 3 or self.zoneAirFlowSizMethod == 0:  # SupplyAirFlowRate or None
                    pass
    
    def clearState(self) -> None:
        super().clearState()
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
        self.zoneHVACSizing.clear()
    
    def setHVACSizingIndexData(self, index: int) -> None:
        self.zoneHVACSizingIndex = index


class BaseSizerWithScalableInputsData:
    
    def init_constant_state(self, state: EnergyPlusDataProtocol) -> None:
        pass
    
    def init_state(self, state: EnergyPlusDataProtocol) -> None:
        pass
    
    def clear_state(self) -> None:
        pass


class ReportCoilSelection:
    """Stub for ReportCoilSelection module"""
    
    @staticmethod
    def setCoilSupplyFanInfo(state: EnergyPlusDataProtocol, coil_report_num: int,
                            fan_name: str, fan_type: str, fan_num: int) -> None:
        pass

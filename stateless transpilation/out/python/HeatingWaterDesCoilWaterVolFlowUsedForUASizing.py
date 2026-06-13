# EXTERNAL DEPS (to wire in glue):
# - BaseSizer: base class from EnergyPlus.Autosizing.Base
# - AutoSizingType: enum from EnergyPlus.Autosizing.Base (value: HeatingWaterDesCoilWaterVolFlowUsedForUASizing)
# - ReportCoilSelection: utility module from EnergyPlus.ReportCoilSelection
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData

from abc import ABC, abstractmethod
from typing import Any, List


class BaseSizer(ABC):
    """Base class for autosizers."""
    
    @abstractmethod
    def checkInitialized(self, state: Any, errorsFound: List[bool]) -> bool:
        pass
    
    @abstractmethod
    def preSize(self, state: Any, originalValue: float) -> None:
        pass
    
    @abstractmethod
    def selectSizerOutput(self, state: Any, errorsFound: List[bool]) -> None:
        pass


class ReportCoilSelection:
    """Utility for reporting coil selections."""
    
    @staticmethod
    def setCoilWaterFlowPltSizNum(
        state: Any,
        coilReportNum: int,
        autoSizedValue: float,
        wasAutoSized: bool,
        dataPltSizHeatNum: int,
        dataWaterLoopNum: int
    ) -> None:
        pass
    
    @staticmethod
    def setCoilReheatMultiplier(state: Any, coilReportNum: int, multiplier: float) -> None:
        pass


class HeatingWaterDesCoilWaterVolFlowUsedForUASizer(BaseSizer):
    """Autosizer for heating water design coil water volume flow used for UA sizing."""
    
    def __init__(self):
        self.sizingType = "HeatingWaterDesCoilWaterVolFlowUsedForUASizing"
        self.sizingString = "Design Water Volume Flow Rate Used for UA Sizing [m3/s]"
        self.curZoneEqNum = 0
        self.wasAutoSized = False
        self.sizingDesRunThisZone = False
        self.termUnitSingDuct = False
        self.zoneEqFanCoil = False
        self.termUnitPIU = False
        self.termUnitIU = False
        self.curTermUnitSizingNum = 0
        self.dataWaterFlowUsedForSizing = 0.0
        self.termUnitSizing = []
        self.autoSizedValue = 0.0
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.overrideSizeString = False
        self.isCoilReportObject = False
        self.coilReportNum = 0
        self.dataPltSizHeatNum = 0
        self.dataWaterLoopNum = 0
    
    def size(self, state: Any, originalValue: float, errorsFound: List[bool]) -> float:
        if not self.checkInitialized(state, errorsFound):
            return 0.0
        
        self.preSize(state, originalValue)
        
        if self.curZoneEqNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisZone:
                self.autoSizedValue = originalValue
            else:
                if self.termUnitSingDuct or self.zoneEqFanCoil:
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing
                elif (self.termUnitPIU or self.termUnitIU) and (self.curTermUnitSizingNum > 0):
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing * self.termUnitSizing[self.curTermUnitSizingNum - 1].ReheatLoadMult
                else:
                    self.autoSizedValue = self.dataWaterFlowUsedForSizing
        elif self.curSysNum > 0:
            if not self.wasAutoSized and not self.sizingDesRunThisAirSys:
                self.autoSizedValue = originalValue
            else:
                self.autoSizedValue = self.dataWaterFlowUsedForSizing
        
        if self.overrideSizeString:
            self.sizingString = "Design Water Volume Flow Rate Used for UA Sizing [m3/s]"
        
        self.selectSizerOutput(state, errorsFound)
        
        if self.isCoilReportObject:
            ReportCoilSelection.setCoilWaterFlowPltSizNum(
                state, self.coilReportNum, self.autoSizedValue, self.wasAutoSized,
                self.dataPltSizHeatNum, self.dataWaterLoopNum
            )
            if self.termUnitSingDuct or self.zoneEqFanCoil or ((self.termUnitPIU or self.termUnitIU) and self.curTermUnitSizingNum > 0):
                ReportCoilSelection.setCoilReheatMultiplier(state, self.coilReportNum, 1.0)
        
        return self.autoSizedValue

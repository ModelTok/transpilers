from CoolingSHRSizing import CoolingSHRSizer, BaseSizer
from ...DXCoils import DXCoils
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataHVACGlobals import HVAC
def CoolingSHRSizer.size(inout self, inout state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
    let RatedInletAirTemp: Float64 = 26.6667     # 26.6667C or 80F
    let RatedInletAirHumRat: Float64 = 0.0111847 # Humidity ratio corresponding to 80F dry bulb/67F wet bulb
    if not self.checkInitialized(state, errorsFound):
        return 0.0
    self.preSize(state, _originalValue)
    if self.dataFractionUsedForSizing > 0.0:
        self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
    else:
        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        else:
            if not self.wasAutoSized and ((self.curZoneEqNum > 0 and not self.sizingDesRunThisZone) or (self.curSysNum > 0 and not self.sizingDesRunThisAirSys)):
                self.autoSizedValue = _originalValue
            else:
                if self.dataFlowUsedForSizing >= HVAC.SmallAirVolFlow and self.dataCapacityUsedForSizing > 0.0:
                    let RatedVolFlowPerRatedTotCap: Float64 = self.dataFlowUsedForSizing / self.dataCapacityUsedForSizing
                    if state.dataHVACGlobal.DXCT == HVAC.DXCoilType.Regular:
                        if RatedVolFlowPerRatedTotCap > HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                            self.autoSizedValue = 0.431 + 6086.0 * HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        elif RatedVolFlowPerRatedTotCap < HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                            self.autoSizedValue = 0.431 + 6086.0 * HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        else:
                            self.autoSizedValue = 0.431 + 6086.0 * RatedVolFlowPerRatedTotCap
                    else: # DOASDXCoil, or DXCT = 2
                        if RatedVolFlowPerRatedTotCap > HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                            self.autoSizedValue = 0.389 + 7684.0 * HVAC.MaxRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        elif RatedVolFlowPerRatedTotCap < HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]:
                            self.autoSizedValue = 0.389 + 7684.0 * HVAC.MinRatedVolFlowPerRatedTotCap[int(state.dataHVACGlobal.DXCT)]
                        else:
                            self.autoSizedValue = 0.389 + 7684.0 * RatedVolFlowPerRatedTotCap
                    self.autoSizedValue = DXCoils.ValidateADP(
                        state,
                        self.compType,
                        self.compName,
                        RatedInletAirTemp,
                        RatedInletAirHumRat,
                        self.dataCapacityUsedForSizing,
                        self.dataFlowUsedForSizing,
                        self.autoSizedValue,
                        self.callingRoutine)
                    if self.dataSizingFraction < 1.0:
                        self.autoSizedValue *= self.dataSizingFraction
                else:
                    if self.wasAutoSized:
                        self.autoSizedValue = 1.0
                        let msg: String = "Developer Error: For autosizing of " + self.compType + ' ' + self.compName + ", DataFlowUsedForSizing and DataCapacityUsedForSizing " + self.sizingString + " must both be greater than 0."
                        self.errorType = AutoSizingResultType.ErrorType1
                        self.addErrorMessage(msg)
    self.updateSizingString(state)
    self.selectSizerOutput(state, errorsFound)
    return self.autoSizedValue
def CoolingSHRSizer.updateSizingString(inout self, inout state: EnergyPlusData):
    if not self.overrideSizeString:
        return
    if self.coilType == HVAC.CoilType.CoolingDXTwoSpeed:
        if self.dataDXSpeedNum == 1: # mode 1 is high speed in DXCoils loop
            self.sizingString = "High Speed Rated Sensible Heat Ratio"
        elif self.dataDXSpeedNum == 2:
            self.sizingString = "Low Speed Gross Rated Sensible Heat Ratio"
    elif self.coilType == HVAC.CoilType.CoolingDXMultiSpeed:
        self.sizingString = "Speed " + String(state.dataSize.DataDXSpeedNum) + " Rated Sensible Heat Ratio"
    elif self.coilType == HVAC.CoilType.CoolingVRFFluidTCtrl:
        self.sizingString = "Rated Sensible Heat Ratio"
    elif self.coilType == HVAC.CoilType.CoolingDXCurveFit:
        self.sizingString = "Gross Sensible Heat Ratio"
    else:
        self.sizingString = "Gross Rated Sensible Heat Ratio"
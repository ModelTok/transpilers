# EXTERNAL DEPS (to wire in glue):
# - BaseSizer (from EnergyPlus.Autosizing.Base): base class with checkInitialized, preSize, selectSizerOutput, addErrorMessage methods
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData): state object containing dataHVACGlobal (with DXCT), dataSize (with DataDXSpeedNum)
# - HVAC namespace constants: SmallAirVolFlow (float), MaxRatedVolFlowPerRatedTotCap (list/array by DXCoilType), MinRatedVolFlowPerRatedTotCap (list/array by DXCoilType), DXCoilType enum (Regular value), CoilType enum (CoolingDXTwoSpeed, CoolingDXMultiSpeed, CoolingVRFFluidTCtrl, CoolingDXCurveFit)
# - DXCoils.ValidateADP (from EnergyPlus.DXCoils): function(state, compType, compName, RatedInletAirTemp, RatedInletAirHumRat, capacity, flow, shR, routine) -> float
# - AutoSizingType enum: CoolingSHRSizing
# - AutoSizingResultType enum: ErrorType1


class CoolingSHRSizer:
    """
    Cooling SHR (Sensible Heat Ratio) autosizing calculator.
    Inherits from BaseSizer (to be wired in by caller).
    """

    def __init__(self):
        self.sizingType = "CoolingSHRSizing"
        self.sizingString = "Gross Rated Sensible Heat Ratio"

        self.dataFractionUsedForSizing = 0.0
        self.dataConstantUsedForSizing = 0.0
        self.dataEMSOverrideON = False
        self.dataEMSOverride = 0.0
        self.wasAutoSized = False
        self.curZoneEqNum = 0
        self.sizingDesRunThisZone = False
        self.curSysNum = 0
        self.sizingDesRunThisAirSys = False
        self.dataFlowUsedForSizing = 0.0
        self.dataCapacityUsedForSizing = 0.0
        self.dataSizingFraction = 1.0
        self.compType = ""
        self.compName = ""
        self.callingRoutine = ""
        self.autoSizedValue = 0.0
        self.errorType = None
        self.coilType = None
        self.dataDXSpeedNum = 0
        self.overrideSizeString = False

    def checkInitialized(self, state, errorsFound):
        return True

    def preSize(self, state, originalValue):
        pass

    def selectSizerOutput(self, state, errorsFound):
        pass

    def addErrorMessage(self, msg):
        pass

    def size(self, state, original_value, errors_found):
        RatedInletAirTemp = 26.6667
        RatedInletAirHumRat = 0.0111847

        if not self.checkInitialized(state, errors_found):
            return 0.0

        self.preSize(state, original_value)

        if self.dataFractionUsedForSizing > 0.0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.dataEMSOverrideON:
                self.autoSizedValue = self.dataEMSOverride
            else:
                if (not self.wasAutoSized and
                    ((self.curZoneEqNum > 0 and not self.sizingDesRunThisZone) or
                     (self.curSysNum > 0 and not self.sizingDesRunThisAirSys))):
                    self.autoSizedValue = original_value
                else:
                    if (self.dataFlowUsedForSizing >= 0.00005 and
                        self.dataCapacityUsedForSizing > 0.0):

                        RatedVolFlowPerRatedTotCap = self.dataFlowUsedForSizing / self.dataCapacityUsedForSizing
                        DXCT = state.dataHVACGlobal.DXCT
                        dxct_index = int(DXCT) if isinstance(DXCT, float) else (1 if DXCT == "Regular" else 2)

                        max_ratio = state.HVAC.MaxRatedVolFlowPerRatedTotCap[dxct_index]
                        min_ratio = state.HVAC.MinRatedVolFlowPerRatedTotCap[dxct_index]

                        if DXCT == "Regular" or DXCT == 1:
                            if RatedVolFlowPerRatedTotCap > max_ratio:
                                self.autoSizedValue = 0.431 + 6086.0 * max_ratio
                            elif RatedVolFlowPerRatedTotCap < min_ratio:
                                self.autoSizedValue = 0.431 + 6086.0 * min_ratio
                            else:
                                self.autoSizedValue = 0.431 + 6086.0 * RatedVolFlowPerRatedTotCap
                        else:
                            if RatedVolFlowPerRatedTotCap > max_ratio:
                                self.autoSizedValue = 0.389 + 7684.0 * max_ratio
                            elif RatedVolFlowPerRatedTotCap < min_ratio:
                                self.autoSizedValue = 0.389 + 7684.0 * min_ratio
                            else:
                                self.autoSizedValue = 0.389 + 7684.0 * RatedVolFlowPerRatedTotCap

                        self.autoSizedValue = state.DXCoils.ValidateADP(
                            state,
                            self.compType,
                            self.compName,
                            RatedInletAirTemp,
                            RatedInletAirHumRat,
                            self.dataCapacityUsedForSizing,
                            self.dataFlowUsedForSizing,
                            self.autoSizedValue,
                            self.callingRoutine
                        )

                        if self.dataSizingFraction < 1.0:
                            self.autoSizedValue *= self.dataSizingFraction
                    else:
                        if self.wasAutoSized:
                            self.autoSizedValue = 1.0
                            msg = (f"Developer Error: For autosizing of {self.compType} {self.compName}, "
                                   f"DataFlowUsedForSizing and DataCapacityUsedForSizing {self.sizingString} "
                                   f"must both be greater than 0.")
                            self.errorType = "ErrorType1"
                            self.addErrorMessage(msg)

        self.updateSizingString(state)
        self.selectSizerOutput(state, errors_found)
        return self.autoSizedValue

    def updateSizingString(self, state):
        if not self.overrideSizeString:
            return

        if self.coilType == "CoolingDXTwoSpeed":
            if self.dataDXSpeedNum == 1:
                self.sizingString = "High Speed Rated Sensible Heat Ratio"
            elif self.dataDXSpeedNum == 2:
                self.sizingString = "Low Speed Gross Rated Sensible Heat Ratio"
        elif self.coilType == "CoolingDXMultiSpeed":
            self.sizingString = f"Speed {state.dataSize.DataDXSpeedNum} Rated Sensible Heat Ratio"
        elif self.coilType == "CoolingVRFFluidTCtrl":
            self.sizingString = "Rated Sensible Heat Ratio"
        elif self.coilType == "CoolingDXCurveFit":
            self.sizingString = "Gross Sensible Heat Ratio"
        else:
            self.sizingString = "Gross Rated Sensible Heat Ratio"

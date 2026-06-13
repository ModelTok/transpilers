# This file is a faithful 1:1 translation of the C++ source file SystemAirFlowSizing.cc.
# Do not refactor.

from BaseSizerWithScalableInputs import BaseSizerWithScalableInputs, AutoSizingType
from ......Data.BaseData import BaseGlobalStruct
from ......Data.EnergyPlusData import EnergyPlusData
from ......Data.DataEnvironment import DataEnvironment
from ......Data.DataHVACGlobals import HVAC
from ...OutputReportPredefined import OutputReportPredefined
from ...ReportCoilSelection import ReportCoilSelection
from ......UtilityRoutines import Util, ShowSevereError, ShowContinueError
from ......WeatherManager import WeatherManager
from ...DataSizing import DataSizing

struct SystemAirFlowSizer(BaseSizerWithScalableInputs):
    def __init__(self):
        self.sizingType = AutoSizingType.SystemAirFlowSizing
        self.sizingString = "Maximum Flow Rate [m3/s]"

    def __del__(self):

    def size(self, state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64:
        if not self.checkInitialized(state, errorsFound):
            return 0.0

        self.preSize(state, _originalValue)

        var DDNameFanPeak: String
        var dateTimeFanPeak: String

        if self.dataEMSOverrideON:
            self.autoSizedValue = self.dataEMSOverride
        elif self.dataConstantUsedForSizing > 0.0 and self.dataFractionUsedForSizing > 0.0:
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        else:
            if self.curZoneEqNum > 0:
                if not self.wasAutoSized and not self.sizingDesRunThisZone:
                    self.autoSizedValue = _originalValue
                elif self.zoneEqSizing(self.curZoneEqNum).DesignSizeFromParent:
                    self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).AirVolFlow
                else:
                    if (self.zoneAirFlowSizMethod == DataSizing.SupplyAirFlowRate) or (self.zoneAirFlowSizMethod == DataSizing.None):
                        if self.zoneEqSizing(self.curZoneEqNum).SystemAirFlow:
                            self.autoSizedValue = max(
                                self.zoneEqSizing(self.curZoneEqNum).AirVolFlow,
                                self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            )
                            if self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                            elif self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).AirVolFlow:
                                DDNameFanPeak = "Unknown"
                        else:
                            if self.zoneCoolingOnlyFan:
                                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.zoneHeatingOnlyFan:
                                self.autoSizedValue = self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                            elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                                self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                            elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                                self.autoSizedValue = max(
                                    self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                    self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                                )
                                if self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                    if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                        DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                        dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                                elif self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                    if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                        DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                        dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                            else:
                                self.autoSizedValue = max(
                                    self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                    self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                                )
                                if self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                    if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                        DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                        dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                                elif self.autoSizedValue == self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                    if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                        DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                        dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                    elif self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedCoolingAirflow:
                        if self.zoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        else:
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                    elif self.zoneAirFlowSizMethod == DataSizing.FractionOfAutosizedHeatingAirflow:
                        if self.zoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                            self.autoSizedValue = self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        else:
                            self.autoSizedValue = max(
                                self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow,
                                self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow
                            )
                            if self.autoSizedValue == self.dataFracOfAutosizedCoolingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesCoolVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFracOfAutosizedHeatingAirflow * self.finalZoneSizing(self.curZoneEqNum).DesHeatVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                    elif self.zoneAirFlowSizMethod == DataSizing.FlowPerCoolingCapacity:
                        if self.zoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        else:
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                    elif self.zoneAirFlowSizMethod == DataSizing.FlowPerHeatingCapacity:
                        if self.zoneCoolingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneHeatingOnlyFan:
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                            self.autoSizedValue = self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        else:
                            self.autoSizedValue = max(
                                self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity,
                                self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity
                            )
                            if self.autoSizedValue == self.dataFlowPerCoolingCapacity * self.dataAutosizedCoolingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.dataFlowPerHeatingCapacity * self.dataAutosizedHeatingCapacity:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                    else:
                        if self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow:
                            self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and not self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtHeatMax)}"
                        elif self.zoneEqSizing(self.curZoneEqNum).HeatingAirFlow and self.zoneEqSizing(self.curZoneEqNum).CoolingAirFlow:
                            self.autoSizedValue = max(
                                self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow,
                                self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow
                            )
                            if self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).CoolingAirVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).CoolDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).CoolDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).CoolDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.curZoneEqNum).TimeStepNumAtCoolMax)}"
                            elif self.autoSizedValue == self.zoneEqSizing(self.curZoneEqNum).HeatingAirVolFlow:
                                if self.finalZoneSizing(self.curZoneEqNum).HeatDDNum > 0 and self.finalZoneSizing(self.curZoneEqNum).HeatDDNum <= state.dataEnvrn.TotDesDays:
                                    DDNameFanPeak = state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Title
                                    dateTimeFanPeak = f"{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].Month}/{state.dataWeather.DesDayInput[self.finalZoneSizing(self.curZoneEqNum).HeatDDNum].DayOfMonth} {ReportCoilSelection.getTimeText(state, self.finalZoneSizing(self.
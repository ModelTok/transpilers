from ...Autosizing.BaseSizerWithScalableInputs import BaseSizerWithScalableInputs
from ...DataHVACGlobals import HVAC
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataEnvironment import DataEnvironment
from ...CurveManager import Curve, CurveValue
from ...Fans import Fans
from ...GeneralRoutines import CheckSysSizing, ShowWarningMessage, ShowContinueError, ShowSevereError, SameString
from ...Psychrometrics import PsyHFnTdbW, PsyTwbFnTdbWPb, PsyCpAirFnW, PsyTdpFnWPb
from ...SimAirServingZones import SimAirServingZones
from ...VariableSpeedCoils import GetVSCoilRatedSourceTemp
from ...ReportCoilSelection import ReportCoilSelection
from ...DataSizing import DataSizing
from format import String
struct CoolingCapacitySizer: BaseSizerWithScalableInputs {
    def __init__(inout self) {
        self.sizingType = AutoSizingType.CoolingCapacitySizing
        self.sizingString = "Cooling Design Capacity [W]"
    }
    def size(inout self, inout state: EnergyPlusData, _originalValue: Float64, inout errorsFound: Bool) -> Float64 {
        if not self.checkInitialized(state, errorsFound) {
            return 0.0
        }
        self.preSize(state, _originalValue)
        var DesVolFlow: Float64 = 0.0
        var CoilInTemp: Float64 = -999.0
        var CoilInHumRat: Float64 = -999.0
        var CoilOutTemp: Float64 = -999.0
        var CoilOutHumRat: Float64 = -999.0
        var FanCoolLoad: Float64 = 0.0
        var TotCapTempModFac: Float64 = 1.0
        var DXFlowPerCapMinRatio: Float64 = 1.0
        var DXFlowPerCapMaxRatio: Float64 = 1.0
        if self.dataEMSOverrideON {
            self.autoSizedValue = self.dataEMSOverride
        } elif self.dataConstantUsedForSizing >= 0 and self.dataFractionUsedForSizing > 0 {
            self.autoSizedValue = self.dataConstantUsedForSizing * self.dataFractionUsedForSizing
        } else {
            if self.curZoneEqNum > 0 {
                if not self.wasAutoSized and not self.sizingDesRunThisZone {
                    self.autoSizedValue = _originalValue
                } elif self.zoneEqSizing[self.curZoneEqNum - 1].DesignSizeFromParent {
                    self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].DesCoolingLoad
                } else {
                    if self.zoneEqSizing[self.curZoneEqNum - 1].CoolingCapacity { // Parent object calculated capacity
                        self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].DesCoolingLoad
                        DesVolFlow = self.dataFlowUsedForSizing
                        CoilInTemp = state.dataSize.DataCoilSizingAirInTemp
                        CoilInHumRat = state.dataSize.DataCoilSizingAirInHumRat
                        CoilOutTemp = state.dataSize.DataCoilSizingAirOutTemp
                        CoilOutHumRat = state.dataSize.DataCoilSizingAirOutHumRat
                        FanCoolLoad = state.dataSize.DataCoilSizingFanCoolLoad
                        TotCapTempModFac = state.dataSize.DataCoilSizingCapFT
                    } else {
                        if SameString(self.compType, "COIL:COOLING:WATER") or
                           SameString(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY") or
                           SameString(self.compType, "ZONEHVAC:IDEALLOADSAIRSYSTEM") {
                            if self.termUnitIU and (self.curTermUnitSizingNum > 0) {
                                self.autoSizedValue = self.termUnitSizing[self.curTermUnitSizingNum - 1].DesCoolingLoad
                            } elif self.zoneEqFanCoil {
                                self.autoSizedValue = self.zoneEqSizing[self.curZoneEqNum - 1].DesCoolingLoad
                            } else {
                                CoilInTemp = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInTemp
                                CoilInHumRat = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInHumRat
                                CoilOutTemp = min(CoilInTemp, self.finalZoneSizing[self.curZoneEqNum - 1].CoolDesTemp)
                                CoilOutHumRat = min(CoilInHumRat, self.finalZoneSizing[self.curZoneEqNum - 1].CoolDesHumRat)
                                self.autoSizedValue =
                                    self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolMassFlow *
                                    (PsyHFnTdbW(CoilInTemp, CoilInHumRat) - PsyHFnTdbW(CoilOutTemp, CoilOutHumRat))
                                DesVolFlow = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolMassFlow / state.dataEnvrn.StdRhoAir
                                FanCoolLoad += self.calcFanDesHeatGain(DesVolFlow)
                                self.autoSizedValue += FanCoolLoad
                            }
                        } else {
                            DesVolFlow = self.dataFlowUsedForSizing
                            if DesVolFlow >= HVAC.SmallAirVolFlow {
                                if state.dataSize.ZoneEqDXCoil {
                                    if self.zoneEqSizing[self.curZoneEqNum - 1].ATMixerVolFlow > 0.0 { // NEW ATMixer coil sizing method
                                        var DesMassFlow: Float64 = DesVolFlow * state.dataEnvrn.StdRhoAir
                                        CoilInTemp = setCoolCoilInletTempForZoneEqSizing(
                                            setOAFracForZoneEqSizing(state, DesMassFlow, zoneEqSizing(self.curZoneEqNum - 1)),
                                            zoneEqSizing(self.curZoneEqNum - 1),
                                            finalZoneSizing(self.curZoneEqNum - 1))
                                        CoilInHumRat = setCoolCoilInletHumRatForZoneEqSizing(
                                            setOAFracForZoneEqSizing(state, DesMassFlow, zoneEqSizing(self.curZoneEqNum - 1)),
                                            zoneEqSizing(self.curZoneEqNum - 1),
                                            finalZoneSizing(self.curZoneEqNum - 1))
                                    } elif self.zoneEqSizing[self.curZoneEqNum - 1].OAVolFlow > 0.0 {
                                        CoilInTemp = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInTemp
                                        CoilInHumRat = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInHumRat
                                    } else {
                                        CoilInTemp = self.finalZoneSizing[self.curZoneEqNum - 1].ZoneRetTempAtCoolPeak // Question whether zone equipment should use return temp for sizing
                                        CoilInHumRat = self.finalZoneSizing[self.curZoneEqNum - 1].ZoneHumRatAtCoolPeak
                                    }
                                } elif self.zoneEqFanCoil {
                                    var DesMassFlow: Float64 = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolMassFlow
                                    CoilInTemp = setCoolCoilInletTempForZoneEqSizing(
                                        setOAFracForZoneEqSizing(state, DesMassFlow, zoneEqSizing(self.curZoneEqNum - 1)),
                                        zoneEqSizing(self.curZoneEqNum - 1),
                                        finalZoneSizing(self.curZoneEqNum - 1))
                                    CoilInHumRat = setCoolCoilInletHumRatForZoneEqSizing(
                                        setOAFracForZoneEqSizing(state, DesMassFlow, zoneEqSizing(self.curZoneEqNum - 1)),
                                        zoneEqSizing(self.curZoneEqNum - 1),
                                        finalZoneSizing(self.curZoneEqNum - 1))
                                } else {
                                    CoilInTemp = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInTemp
                                    CoilInHumRat = self.finalZoneSizing[self.curZoneEqNum - 1].DesCoolCoilInHumRat
                                }
                                CoilOutTemp = min(CoilInTemp, self.finalZoneSizing[self.curZoneEqNum - 1].CoolDesTemp)
                                CoilOutHumRat = min(CoilInHumRat, self.finalZoneSizing[self.curZoneEqNum - 1].CoolDesHumRat)
                                var TimeStepNumAtMax: Int = self.finalZoneSizing[self.curZoneEqNum - 1].TimeStepNumAtCoolMax
                                var DDNum: Int = self.finalZoneSizing[self.curZoneEqNum - 1].CoolDDNum
                                var OutTemp: Float64 = 0.0
                                if DDNum > 0 and TimeStepNumAtMax > 0 {
                                    OutTemp = state.dataSize.DesDayWeath[DDNum - 1].Temp[TimeStepNumAtMax - 1]
                                }
                                if self.dataCoolCoilType == HVAC.CoilType.CoolingWAHPVariableSpeedEquationFit {
                                    OutTemp = GetVSCoilRatedSourceTemp(state, self.dataCoolCoilIndex)
                                }
                                var CoilInEnth: Float64 = PsyHFnTdbW(CoilInTemp, CoilInHumRat)
                                var CoilOutEnth: Float64 = PsyHFnTdbW(CoilOutTemp, CoilOutHumRat)
                                var PeakCoilLoad: Float64 = max(0.0, (state.dataEnvrn.StdRhoAir * DesVolFlow * (CoilInEnth - CoilOutEnth)))
                                FanCoolLoad += self.calcFanDesHeatGain(DesVolFlow)
                                PeakCoilLoad += FanCoolLoad
                                var CpAir: Float64 = PsyCpAirFnW(CoilInHumRat)
                                if self.dataDesAccountForFanHeat {
                                    if state.dataSize.DataFanPlacement == HVAC.FanPlace.BlowThru {
                                        CoilInTemp += FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * DesVolFlow)
                                    } elif state.dataSize.DataFanPlacement == HVAC.FanPlace.DrawThru {
                                        CoilOutTemp -= FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * DesVolFlow)
                                    }
                                }
                                var CoilInWetBulb: Float64 =
                                    PsyTwbFnTdbWPb(state, CoilInTemp, CoilInHumRat, state.dataEnvrn.StdBaroPress, self.callingRoutine)
                                if self.dataTotCapCurveIndex > 0 {
                                    var curveIndex = self.dataTotCapCurveIndex - 1
                                    if state.dataCurveManager.curves[curveIndex].numDims == 1 {
                                        TotCapTempModFac = CurveValue(state, self.dataTotCapCurveIndex, CoilInWetBulb)
                                    } else { // default allows the simulation to continue, but will issue a warning, should be removed eventually
                                        TotCapTempModFac = CurveValue(state, self.dataTotCapCurveIndex, CoilInWetBulb, OutTemp)
                                    }
                                } elif self.dataTotCapCurveValue > 0 {
                                    TotCapTempModFac = self.dataTotCapCurveValue
                                } else {
                                    TotCapTempModFac = 1.0
                                }
                                if TotCapTempModFac > 0.0 {
                                    self.autoSizedValue = PeakCoilLoad / TotCapTempModFac
                                } else {
                                    self.autoSizedValue = PeakCoilLoad
                                }
                                state.dataSize.DataCoilSizingAirInTemp = CoilInTemp
                                state.dataSize.DataCoilSizingAirInHumRat = CoilInHumRat
                                state.dataSize.DataCoilSizingAirOutTemp = CoilOutTemp
                                state.dataSize.DataCoilSizingAirOutHumRat = CoilOutHumRat
                                state.dataSize.DataCoilSizingFanCoolLoad = FanCoolLoad
                                state.dataSize.DataCoilSizingCapFT = TotCapTempModFac
                            } else {
                                self.autoSizedValue = 0.0
                                CoilOutTemp = -999.0
                            }
                        }
                    }
                    self.autoSizedValue = self.autoSizedValue * self.dataFracOfAutosizedCoolingCapacity
                    self.dataDesAccountForFanHeat = true // reset for next water coil
                    if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0 {
                        ShowWarningMessage(state,
                                           self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName)
                        ShowContinueError(state, String.format("...Rated Total Cooling Capacity = {:.2f} [W]", self.autoSizedValue))
                        if self.zoneEqSizing[self.curZoneEqNum - 1].CoolingCapacity {
                            ShowContinueError(
                                state, String.format("...Capacity passed by parent object to size child component = {:.2f} [W]", self.autoSizedValue))
                        } else {
                            if SameString(self.compType, "COIL:COOLING:WATER") or
                               SameString(self.compType, "COIL:COOLING:WATER:DETAILEDGEOMETRY") or
                               SameString(self.compType, "ZONEHVAC:IDEALLOADSAIRSYSTEM") {
                                if self.termUnitIU or self.zoneEqFanCoil {
                                    ShowContinueError(
                                        state,
                                        String.format("...Capacity passed by parent object to size child component = {:.2f} [W]", self.autoSizedValue))
                                } else {
                                    ShowContinueError(state, String.format("...Air flow rate used for sizing = {:.5f} [m3/s]", DesVolFlow))
                                    ShowContinueError(state, String.format("...Coil inlet air temperature used for sizing = {:.2f} [C]", CoilInTemp))
                                    ShowContinueError(state, String.format("...Coil outlet air temperature used for sizing = {:.2f} [C]", CoilOutTemp))
                                }
                            } else {
                                if CoilOutTemp > -999.0 {
                                    ShowContinueError(state, String.format("...Air flow rate used for sizing = {:.5f} [m3/s]", DesVolFlow))
                                    ShowContinueError(state, String.format("...Coil inlet air temperature used for sizing = {:.2f} [C]", CoilInTemp))
                                    ShowContinueError(state, String.format("...Coil outlet air temperature used for sizing = {:.2f} [C]", CoilOutTemp))
                                } else {
                                    ShowContinueError(state, "...Capacity used to size child component set to 0 [W]")
                                }
                            }
                        }
                    }
                }
            } elif self.curSysNum > 0 {
                if not self.wasAutoSized and not self.sizingDesRunThisAirSys {
                    self.autoSizedValue = _originalValue
                } else {
                    var OutAirFrac: Float64 = 0.0
                    self.dataFracOfAutosizedCoolingCapacity = 1.0
                    if self.oaSysFlag {
                        self.autoSizedValue = self.oaSysEqSizing[self.curOASysNum - 1].DesCoolingLoad
                        DesVolFlow = self.dataFlowUsedForSizing
                    } elif self.airLoopSysFlag {
                        self.autoSizedValue = self.unitarySysEqSizing[self.curSysNum - 1].DesCoolingLoad
                        DesVolFlow = self.dataFlowUsedForSizing
                        CoilInTemp = state.dataSize.DataCoilSizingAirInTemp
                        CoilInHumRat = state.dataSize.DataCoilSizingAirInHumRat
                        CoilOutTemp = state.dataSize.DataCoilSizingAirOutTemp
                        CoilOutHumRat = state.dataSize.DataCoilSizingAirOutHumRat
                        FanCoolLoad = state.dataSize.DataCoilSizingFanCoolLoad
                        TotCapTempModFac = state.dataSize.DataCoilSizingCapFT
                        if ReportCoilSelection.isCompTypeCoil(self.compType) {
                            ReportCoilSelection.setCoilEntAirHumRat(state, self.coilReportNum, CoilInHumRat)
                            ReportCoilSelection.setCoilEntAirTemp(state, self.coilReportNum, CoilInTemp, self.curSysNum, self.curZoneEqNum)
                            ReportCoilSelection.setCoilLvgAirTemp(state, self.coilReportNum, CoilOutTemp)
                            ReportCoilSelection.setCoilLvgAirHumRat(state, self.coilReportNum, CoilOutHumRat)
                        }
                    } elif self.curOASysNum > 0 and self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum > -1 {
                        var &thisAirloopDOAS = self.airloopDOAS[self.outsideAirSys[self.curOASysNum - 1].AirLoopDOASNum] // note: index might be 0-based
                        DesVolFlow = thisAirloopDOAS.SizingMassFlow / state.dataEnvrn.StdRhoAir
                        CoilInTemp = thisAirloopDOAS.SizingCoolOATemp
                        CoilOutTemp = thisAirloopDOAS.PrecoolTemp
                        if thisAirloopDOAS.m_FanIndex > 0 {
                            state.dataFans.fans[thisAirloopDOAS.m_FanIndex - 1].getInputsForDesignHeatGain(
                                state,
                                self.deltaP,
                                self.motEff,
                                self.totEff,
                                self.motInAirFrac,
                                self.fanShaftPow,
                                self.motInPower,
                                self.fanCompModel)
                            if thisAirloopDOAS.m_FanTypeNum == SimAirServingZones.CompType.Fan_ComponentModel {
                                FanCoolLoad = self.fanShaftPow + (self.motInPower - self.fanShaftPow) * self.motInAirFrac
                            } elif thisAirloopDOAS.m_FanTypeNum == SimAirServingZones.CompType.Fan_System_Object {
                                var fanPowerTot: Float64 = (DesVolFlow * self.deltaP) / self.totEff
                                FanCoolLoad = self.motEff * fanPowerTot + (fanPowerTot - self.motEff * fanPowerTot) * self.motInAirFrac
                            }
                            self.dataFanType = state.dataFans.fans[thisAirloopDOAS.m_FanIndex - 1].type
                            self.dataFanIndex = thisAirloopDOAS.m_FanIndex
                            var CpAir: Float64 = PsyCpAirFnW(state.dataLoopNodes.Node[thisAirloopDOAS.m_FanInletNodeNum - 1].HumRat)
                            var DeltaT: Float64 = FanCoolLoad / (thisAirloopDOAS.SizingMassFlow * CpAir)
                            if thisAirloopDOAS.FanBeforeCoolingCoilFlag {
                                CoilInTemp += DeltaT
                            } else {
                                CoilOutTemp -= DeltaT
                                CoilOutTemp =
                                    max(CoilOutTemp, PsyTdpFnWPb(state, thisAirloopDOAS.PrecoolHumRat, state.dataEnvrn.StdBaroPress))
                            }
                        }
                        CoilInHumRat = thisAirloopDOAS.SizingCoolOAHumRat
                        CoilOutHumRat = thisAirloopDOAS.PrecoolHumRat
                        self.autoSizedValue =
                            DesVolFlow * state.dataEnvrn.StdRhoAir *
                            (PsyHFnTdbW(CoilInTemp, CoilInHumRat) - PsyHFnTdbW(CoilOutTemp, CoilOutHumRat))
                    } else {
                        CheckSysSizing(state, self.compType, self.compName)
                        var &thisFinalSysSizing = self.finalSysSizing[self.curSysNum - 1]
                        DesVolFlow = self.dataFlowUsedForSizing
                        var NominalCapacityDes: Float64 = 0.0
                        if thisFinalSysSizing.CoolingCapMethod == DataSizing.FractionOfAutosizedCoolingCapacity {
                            self.dataFracOfAutosizedCoolingCapacity = thisFinalSysSizing.FractionOfAutosizedCoolingCapacity
                        }
                        if thisFinalSysSizing.CoolingCapMethod == DataSizing.CapacityPerFloorArea {
                            NominalCapacityDes = thisFinalSysSizing.CoolingTotalCapacity
                            self.autoSizedValue = NominalCapacityDes
                        } elif thisFinalSysSizing.CoolingCapMethod == DataSizing.CoolingDesignCapacity and
                               thisFinalSysSizing.CoolingTotalCapacity > 0.0 {
                            NominalCapacityDes = thisFinalSysSizing.CoolingTotalCapacity
                            self.autoSizedValue = NominalCapacityDes
                        } elif DesVolFlow >= HVAC.SmallAirVolFlow {
                            if DesVolFlow > 0.0 {
                                OutAirFrac = thisFinalSysSizing.DesOutAirVolFlow / DesVolFlow
                            } else {
                                OutAirFrac = 1.0
                            }
                            OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                            if self.curOASysNum > 0 { // coil is in the OA stream
                                CoilInTemp = thisFinalSysSizing.OutTempAtCoolPeak
                                CoilInHumRat = thisFinalSysSizing.OutHumRatAtCoolPeak
                                CoilOutTemp = thisFinalSysSizing.PrecoolTemp
                                CoilOutHumRat = thisFinalSysSizing.PrecoolHumRat
                            } else { // coil is on the main air loop
                                if self.dataAirFlowUsedForSizing > 0.0 {
                                    DesVolFlow = self.dataAirFlowUsedForSizing
                                }
                                if self.dataDesOutletAirTemp > 0.0 {
                                    CoilOutTemp = self.dataDesOutletAirTemp
                                } else {
                                    CoilOutTemp = thisFinalSysSizing.CoolSupTemp
                                }
                                if self.dataDesOutletAirHumRat > 0.0 {
                                    CoilOutHumRat = self.dataDesOutletAirHumRat
                                } else {
                                    CoilOutHumRat = thisFinalSysSizing.CoolSupHumRat
                                }
                                if self.primaryAirSystem[self.curSysNum - 1].NumOACoolCoils == 0 { // there is no precooling of the OA stream
                                    CoilInTemp = thisFinalSysSizing.MixTempAtCoolPeak
                                    CoilInHumRat = thisFinalSysSizing.MixHumRatAtCoolPeak
                                } else { // there is precooling of OA stream
                                    if DesVolFlow > 0.0 {
                                        OutAirFrac = thisFinalSysSizing.DesOutAirVolFlow / DesVolFlow
                                    } else {
                                        OutAirFrac = 1.0
                                    }
                                    OutAirFrac = min(1.0, max(0.0, OutAirFrac))
                                    CoilInTemp = OutAirFrac * thisFinalSysSizing.PrecoolTemp + (1.0 - OutAirFrac) * thisFinalSysSizing.RetTempAtCoolPeak
                                    CoilInHumRat =
                                        OutAirFrac * thisFinalSysSizing.PrecoolHumRat + (1.0 - OutAirFrac) * thisFinalSysSizing.RetHumRatAtCoolPeak
                                }
                                if self.dataDesInletAirTemp > 0.0 {
                                    CoilInTemp = self.dataDesInletAirTemp
                                }
                                if self.dataDesInletAirHumRat > 0.0 {
                                    CoilInHumRat = self.dataDesInletAirHumRat
                                }
                            }
                            var OutTemp: Float64 = thisFinalSysSizing.OutTempAtCoolPeak
                            if self.dataCoolCoilType == HVAC.CoilType.CoolingWAHPVariableSpeedEquationFit {
                                OutTemp = GetVSCoilRatedSourceTemp(state, self.dataCoolCoilIndex)
                            }
                            CoilOutTemp = min(CoilInTemp, CoilOutTemp)
                            CoilOutHumRat = min(CoilInHumRat, CoilOutHumRat)
                            var CoilInEnth: Float64 = PsyHFnTdbW(CoilInTemp, CoilInHumRat)
                            var CoilInWetBulb: Float64 =
                                PsyTwbFnTdbWPb(state, CoilInTemp, CoilInHumRat, state.dataEnvrn.StdBaroPress, self.callingRoutine)
                            var CoilOutEnth: Float64 = PsyHFnTdbW(CoilOutTemp, CoilOutHumRat)
                            if self.curOASysNum > 0 { // coil is in the OA stream
                            } else {
                                if self.primaryAirSystem[self.curSysNum - 1].supFanType != HVAC.FanType.Invalid {
                                    FanCoolLoad = self.calcFanDesHeatGain(DesVolFlow)
                                }
                                if self.primaryAirSystem[self.curSysNum - 1].retFanType != HVAC.FanType.Invalid {
                                    FanCoolLoad += (1.0 - OutAirFrac) * self.calcFanDesHeatGain(DesVolFlow)
                                }
                                self.primaryAirSystem[self.curSysNum - 1].FanDesCoolLoad = FanCoolLoad
                            }
                            var PeakCoilLoad: Float64 = max(0.0, (state.dataEnvrn.StdRhoAir * DesVolFlow * (CoilInEnth - CoilOutEnth)))
                            var CpAir: Float64 = PsyCpAirFnW(CoilInHumRat)
                            if self.dataDesAccountForFanHeat {
                                PeakCoilLoad = max(0.0, (state.dataEnvrn.StdRhoAir * DesVolFlow * (CoilInEnth - CoilOutEnth) + FanCoolLoad))
                                if self.primaryAirSystem[self.curSysNum - 1].supFanPlace == HVAC.FanPlace.BlowThru {
                                    CoilInTemp += FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * DesVolFlow)
                                    CoilInWetBulb = PsyTwbFnTdbWPb(
                                        state, CoilInTemp, CoilInHumRat, state.dataEnvrn.StdBaroPress, self.callingRoutine)
                                } elif self.primaryAirSystem[self.curSysNum - 1].supFanPlace == HVAC.FanPlace.DrawThru {
                                    CoilOutTemp -= FanCoolLoad / (CpAir * state.dataEnvrn.StdRhoAir * DesVolFlow)
                                }
                            }
                            if self.dataTotCapCurveIndex > 0 {
                                if state.dataCurveManager.curves[self.dataTotCapCurveIndex - 1].numDims == 1 {
                                    TotCapTempModFac = CurveValue(state, self.dataTotCapCurveIndex, CoilInWetBulb)
                                } else { // default allows the simulation to continue, but will issue a warning, should be removed eventually
                                    TotCapTempModFac = CurveValue(state, self.dataTotCapCurveIndex, CoilInWetBulb, OutTemp)
                                }
                            } else {
                                TotCapTempModFac = 1.0
                            }
                            if TotCapTempModFac > 0.0 {
                                NominalCapacityDes = PeakCoilLoad / TotCapTempModFac
                            } else {
                                NominalCapacityDes = PeakCoilLoad
                            }
                            state.dataSize.DataCoilSizingAirInTemp = CoilInTemp
                            state.dataSize.DataCoilSizingAirInHumRat = CoilInHumRat
                            state.dataSize.DataCoilSizingAirOutTemp = CoilOutTemp
                            state.dataSize.DataCoilSizingAirOutHumRat = CoilOutHumRat
                            state.dataSize.DataCoilSizingFanCoolLoad = FanCoolLoad
                            state.dataSize.DataCoilSizingCapFT = TotCapTempModFac
                        } else {
                            NominalCapacityDes = 0.0
                        }
                        self.autoSizedValue =
                            NominalCapacityDes * self.dataFracOfAutosizedCoolingCapacity // Fixed Moved up 1 line inside block per Richard Raustad
                    } // IF(OASysFlag) THEN or ELSE IF(AirLoopSysFlag) THEN
                    self.dataDesAccountForFanHeat = true // reset for next water coil
                    if state.dataGlobal.DisplayExtraWarnings and self.autoSizedValue <= 0.0 {
                        ShowWarningMessage(state,
                                           self.callingRoutine + ": Potential issue with equipment sizing for " + self.compType + ' ' + self.compName)
                        ShowContinueError(state, String.format("...Rated Total Cooling Capacity = {:.2f} [W]", self.autoSizedValue))
                        if self.oaSysFlag or self.airLoopSysFlag or
                           self.finalSysSizing[self.curSysNum - 1].CoolingCapMethod == DataSizing.CapacityPerFloorArea or
                           (self.finalSysSizing[self.curSysNum - 1].CoolingCapMethod == DataSizing.CoolingDesignCapacity and
                            (self.finalSysSizing[self.curSysNum - 1].CoolingTotalCapacity != 0.0)) {
                            ShowContinueError(
                                state, String.format("...Capacity passed by parent object to size child component = {:.2f} [W]", self.autoSizedValue))
                        } else {
                            ShowContinueError(state, String.format("...Air flow rate used for sizing = {:.5f} [m3/s]", DesVolFlow))
                            ShowContinueError(state, String.format("...Outdoor air fraction used for sizing = {:.2f}", OutAirFrac))
                            ShowContinueError(state, String.format("...Coil inlet air temperature used for sizing = {:.2f} [C]", CoilInTemp))
                            ShowContinueError(state, String.format("...Coil outlet air temperature used for sizing = {:.2f} [C]", CoilOutTemp))
                        }
                    }
                }
            } elif self.dataNonZoneNonAirloopValue > 0 {
                self.autoSizedValue = self.dataNonZoneNonAirloopValue
            } elif not self.wasAutoSized {
                self.autoSizedValue = self.originalValue
            } else {
                var msg: String = self.callingRoutine + ' ' + self.compType + ' ' + self.compName + ", Developer Error: Component sizing incomplete."
                ShowSevereError(state, msg)
                self.addErrorMessage(msg)
                msg = String.format("SizingString = {}, SizingResult = {:.1f}", self.sizingString, self.autoSizedValue)
                ShowContinueError(state, msg)
                self.addErrorMessage(msg)
                errorsFound = true
            }
        }
        if self.dataDXCoolsLowSpeedsAutozize {
            self.autoSizedValue *= self.dataFractionUsedForSizing
        }
        if not self.hardSizeNoDesignRun or self.dataScalableSizingON or self.dataScalableCapSizingON {
            if self.wasAutoSized {
                var FlagCheckVolFlowPerRatedTotCap: Bool = true
                if SameString(self.compType, "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl") or
                   SameString(self.compType, "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl") {
                    FlagCheckVolFlowPerRatedTotCap = false
                }
                if self.dataIsDXCoil and FlagCheckVolFlowPerRatedTotCap {
                    var RatedVolFlowPerRatedTotCap: Float64 = 0.0
                    if self.autoSizedValue > 0.0 {
                        RatedVolFlowPerRatedTotCap = DesVolFlow / self.autoSizedValue
                    }
                    if RatedVolFlowPerRatedTotCap < HVAC.MinRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)] {
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag {
                            ShowWarningError(state, self.callingRoutine + ' ' + self.compType + ' ' + self.compName)
                            ShowContinueError(
                                state, "..." + self.sizingString + " will be limited by the minimum rated volume flow per rated total capacity ratio.")
                            ShowContinueError(state, String.format("...DX coil volume flow rate [m3/s] = {:.6f}", DesVolFlow))
                            ShowContinueError(state, String.format("...Requested capacity [W] = {:.3f}", self.autoSizedValue))
                            ShowContinueError(state, String.format("...Requested flow/capacity ratio [m3/s/W] = {:#G}", RatedVolFlowPerRatedTotCap))
                            ShowContinueError(state,
                                              String.format("...Minimum flow/capacity ratio [m3/s/W] = {:#G}",
                                                          HVAC.MinRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)]))
                        }
                        DXFlowPerCapMinRatio = (DesVolFlow / HVAC.MinRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)]) /
                                               self.autoSizedValue // set DX Coil Capacity Increase Ratio from Too Low Flow/Capacity Ratio
                        self.autoSizedValue = DesVolFlow / HVAC.MinRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)]
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag {
                            ShowContinueError(state, String.format("...Adjusted capacity [W] = {:.3f}", self.autoSizedValue))
                        }
                    } elif RatedVolFlowPerRatedTotCap > HVAC.MaxRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)] {
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag {
                            ShowWarningError(state, self.callingRoutine + ' ' + self.compType + ' ' + self.compName)
                            ShowContinueError(
                                state, "..." + self.sizingString + " will be limited by the maximum rated volume flow per rated total capacity ratio.")
                            ShowContinueError(state, String.format("...DX coil volume flow rate [m3/s] = {:.6f}", DesVolFlow))
                            ShowContinueError(state, String.format("...Requested capacity [W] = {:.3f}", self.autoSizedValue))
                            ShowContinueError(state, String.format("...Requested flow/capacity ratio [m3/s/W] = {:#G}", RatedVolFlowPerRatedTotCap))
                            ShowContinueError(state,
                                              String.format("...Maximum flow/capacity ratio [m3/s/W] = {:#G}",
                                                          HVAC.MaxRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)]))
                        }
                        DXFlowPerCapMaxRatio = DesVolFlow / HVAC.MaxRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)] /
                                               self.autoSizedValue // set DX Coil Capacity Decrease Ratio from Too High Flow/Capacity Ratio
                        self.autoSizedValue = DesVolFlow / HVAC.MaxRatedVolFlowPerRatedTotCap[Int(state.dataHVACGlobal.DXCT)]
                        if not self.dataEMSOverrideON and state.dataGlobal.DisplayExtraWarnings and self.printWarningFlag {
                            ShowContinueError(state, String.format("...Adjusted capacity [W] = {:.3f}", self.autoSizedValue))
                        }
                    }
                }
            }
        }
        if self.overrideSizeString {
            self.sizingString = "Cooling Design Capacity [W]"
        }
        if self.dataScalableCapSizingON {
            var SELECT_CASE_var: Int = self.zoneEqSizing[self.curZoneEqNum - 1].SizingMethod(HVAC.CoolingCapacitySizing)
            if SELECT_CASE_var == DataSizing.CapacityPerFloorArea {
                self.sizingStringScalable = "(scaled by capacity / area) "
            } elif SELECT_CASE_var == DataSizing.FractionOfAutosizedHeatingCapacity or
                   SELECT_CASE_var == DataSizing.FractionOfAutosizedCoolingCapacity {
                self.sizingStringScalable = "(scaled by fractional multiplier) "
            }
        }
        self.selectSizerOutput(state, errorsFound)
        if self.isCoilReportObject and self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys {
            if CoilInTemp > -999.0 { // set inlet air properties used during capacity sizing if available, allow for negative winter temps
                ReportCoilSelection.setCoilEntAirTemp(state, self.coilReportNum, CoilInTemp, self.curSysNum, self.curZoneEqNum)
                ReportCoilSelection.setCoilEntAirHumRat(state, self.coilReportNum, CoilInHumRat)
            }
            if CoilOutTemp > -999.0 { // set outlet air properties used during capacity sizing if available
                ReportCoilSelection.setCoilLvgAirTemp(state, self.coilReportNum, CoilOutTemp)
                ReportCoilSelection.setCoilLvgAirHumRat(state, self.coilReportNum, CoilOutHumRat)
            }
            ReportCoilSelection.setCoilCoolingCapacity(state,
                                                        self.coilReportNum,
                                                        self.autoSizedValue,
                                                        self.wasAutoSized,
                                                        self.curSysNum,
                                                        self.curZoneEqNum,
                                                        self.curOASysNum,
                                                        FanCoolLoad,
                                                        TotCapTempModFac,
                                                        DXFlowPerCapMinRatio,
                                                        DXFlowPerCapMaxRatio)
        }
        return self.autoSizedValue
    }
    def clearState(inout self) {
        BaseSizerWithScalableInputs.clearState(self)
    }
}
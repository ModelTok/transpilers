from BaseSizerWithFanHeatInputs import BaseSizerWithFanHeatInputs
from BaseSizerWithScalableInputs import BaseSizerWithScalableInputs
from Data.BaseData import BaseGlobalStruct
from api.TypeDefs import *
from Data.EnergyPlusData import EnergyPlusData
from DataHeatBalance import *
from Fans import *
from DataSizing import *
from DataHVACGlobals import *
from ReportCoilSelection import *
from HVAC import *
struct BaseSizerWithScalableInputs(BaseSizerWithFanHeatInputs):
    var zoneCoolingOnlyFan: Bool = False
    var zoneHeatingOnlyFan: Bool = False
    var dataHRFlowSizingFlag: Bool = False
    var dataFracOfAutosizedCoolingAirflow: Float64 = 0.0
    var dataFracOfAutosizedHeatingAirflow: Float64 = 0.0
    var dataFlowPerCoolingCapacity: Float64 = 0.0
    var dataAutosizedCoolingCapacity: Float64 = 0.0
    var dataFlowPerHeatingCapacity: Float64 = 0.0
    var dataAutosizedHeatingCapacity: Float64 = 0.0
    var dataCoilSizingAirInTemp: Float64 = 0.0
    var dataCoilSizingAirInHumRat: Float64 = 0.0
    var dataCoilSizingAirOutTemp: Float64 = 0.0
    var dataCoilSizingAirOutHumRat: Float64 = 0.0
    var dataCoilSizingFanCoolLoad: Float64 = 0.0
    var dataCoilSizingCapFT: Float64 = 0.0
    var dataTotCapCurveValue: Float64 = 0.0
    var dataFracOfAutosizedCoolingCapacity: Float64 = 0.0
    var dataFracOfAutosizedHeatingCapacity: Float64 = 0.0
    var dataCoolCoilCap: Float64 = 0.0
    var dataCoilIsSuppHeater: Bool = False
    var suppHeatCap: Float64 = 0.0
    var unitaryHeatCap: Float64 = 0.0
    var dataTotCapCurveIndex: Int = 0
    var dataCoolCoilType: HVAC.CoilType = HVAC.CoilType.Invalid
    var dataCoolCoilIndex: Int = -1
    var zoneHVACSizingIndex: Int = 0
    var zoneHVACSizing: EPVector[DataSizing.ZoneHVACSizingData]
    def initializeWithinEP(inout self, inout state: EnergyPlusData, _compType: StringLiteral, _compName: StringLiteral, _printWarningFlag: Bool, _callingRoutine: StringLiteral):
        BaseSizerWithFanHeatInputs.initializeWithinEP(self, state, _compType, _compName, _printWarningFlag, _callingRoutine)
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
        if self.isCoilReportObject and self.curSysNum > 0 and len(self.primaryAirSystem) > 0 and self.curSysNum <= state.dataHVACGlobal.NumPrimaryAirSys:
            if self.primaryAirSystem[self.curSysNum].supFanNum > 0:
                ReportCoilSelection.setCoilSupplyFanInfo(state,
                                                          self.coilReportNum,
                                                          state.dataFans.fans[self.primaryAirSystem[self.curSysNum].supFanNum].Name,
                                                          state.dataFans.fans[self.primaryAirSystem[self.curSysNum].supFanNum].type,
                                                          self.primaryAirSystem[self.curSysNum].supFanNum)
        if self.curZoneEqNum != 0:
            if self.zoneHVACSizingIndex > 0:
                var coolingSAFMethod: Int = self.zoneHVACSizing[self.zoneHVACSizingIndex].CoolingSAFMethod
                self.zoneAirFlowSizMethod = coolingSAFMethod
                self.dataFractionUsedForSizing = 1.0
                self.dataConstantUsedForSizing = self.zoneHVACSizing[self.zoneHVACSizingIndex].MaxCoolAirVolFlow
                if coolingSAFMethod == DataSizing.FlowPerFloorArea:
                    state.dataSize.DataScalableSizingON = True
                    self.dataConstantUsedForSizing = self.zoneHVACSizing[self.zoneHVACSizingIndex].MaxCoolAirVolFlow * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                elif coolingSAFMethod == DataSizing.FractionOfAutosizedCoolingAirflow:
                    state.dataSize.DataFracOfAutosizedCoolingAirflow = self.zoneHVACSizing[self.zoneHVACSizingIndex].MaxCoolAirVolFlow
                    state.dataSize.DataScalableSizingON = True
            else:
                if len(self.zoneEqSizing) > 0 and len(self.zoneEqSizing[self.curZoneEqNum].SizingMethod) > 0:
                    self.zoneAirFlowSizMethod = self.zoneEqSizing[self.curZoneEqNum].SizingMethod[len(self.sizingType)]
                else:
                    self.zoneAirFlowSizMethod = 0
                if self.zoneAirFlowSizMethod == 0:
                elif self.zoneAirFlowSizMethod == DataSizing.SupplyAirFlowRate or self.zoneAirFlowSizMethod == DataSizing.None:

    def clearState(inout self):
        BaseSizerWithFanHeatInputs.clearState(self)
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
        self.dataCoolCoilType = HVAC.CoilType.Invalid
        self.dataCoolCoilIndex = -1
        self.zoneHVACSizing.clear()
    def setHVACSizingIndexData(inout self, index: Int):
        self.zoneHVACSizingIndex = index
struct BaseSizerWithScalableInputsData(BaseGlobalStruct):
    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):

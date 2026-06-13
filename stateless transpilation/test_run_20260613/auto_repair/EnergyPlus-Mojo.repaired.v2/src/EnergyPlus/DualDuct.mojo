from Data.BaseData import BaseGlobalStruct, EnergyPlusData
from DataGlobals import *
from DataConvergParams import HVACFlowRateToler
from DataHVACGlobals import *
from DataEnvironment import *
from DataHeatBalFanSys import *
from DataHeatBalance import *
from DataLoopNode import *
from DataSizing import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from GeneralRoutines import *
from GlobalNames import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import GetOnlySingleNode
from OutputProcessor import SetupOutputVariable
from OutputReportPredefined import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from BranchNodeConnections import *
from .Autosizing.Base import *
from DataDefineEquip import *
from DataContaminantBalance import *
from math import *
import "sys"
namespace EnergyPlus:
    namespace DualDuct:
        enum DualDuctDamper:
            Invalid = -1
            ConstantVolume = 0
            VariableVolume = 1
            OutdoorAir = 2
            Num = 3
        let dualDuctDamperNames: StaticArray[String, 3] = ["ConstantVolume", "VariableVolume", "OutdoorAir"]
        enum PerPersonMode:
            Invalid = -1
            ModeNotSet = 0
            DCVByCurrentLevel = 1
            ByDesignLevel = 2
            Num = 3
        struct DualDuctAirTerminalFlowConditions:
            var AirMassFlowRate: Float64 = 0.0
            var AirMassFlowRateMaxAvail: Float64 = 0.0
            var AirMassFlowRateMinAvail: Float64 = 0.0
            var AirMassFlowRateMax: Float64 = 0.0
            var AirTemp: Float64 = 0.0
            var AirHumRat: Float64 = 0.0
            var AirEnthalpy: Float64 = 0.0
            var AirMassFlowRateHist1: Float64 = 0.0
            var AirMassFlowRateHist2: Float64 = 0.0
            var AirMassFlowRateHist3: Float64 = 0.0
            var AirMassFlowDiffMag: Float64 = 0.0
        struct DualDuctAirTerminal:
            var Name: String = ""
            var DamperType: DualDuctDamper = DualDuctDamper.Invalid
            var availSched: Optional[Schedule] = None
            var MaxAirVolFlowRate: Float64 = 0.0
            var MaxAirMassFlowRate: Float64 = 0.0
            var HotAirInletNodeNum: Int = 0
            var ColdAirInletNodeNum: Int = 0
            var OutletNodeNum: Int = 0
            var ZoneMinAirFracDes: Float64 = 0.0
            var ZoneMinAirFrac: Float64 = 0.0
            var ColdAirDamperPosition: Float64 = 0.0
            var HotAirDamperPosition: Float64 = 0.0
            var OAInletNodeNum: Int = 0
            var RecircAirInletNodeNum: Int = 0
            var RecircIsUsed: Bool = true
            var DesignOAFlowRate: Float64 = 0.0
            var DesignRecircFlowRate: Float64 = 0.0
            var RecircAirDamperPosition: Float64 = 0.0
            var OADamperPosition: Float64 = 0.0
            var OAFraction: Float64 = 0.0
            var ADUNum: Int = 0
            var CtrlZoneNum: Int = 0
            var CtrlZoneInNodeIndex: Int = 0
            var OutdoorAirFlowRate: Float64 = 0.0
            var NoOAFlowInputFromUser: Bool = true
            var OARequirementsPtr: Int = 0
            var OAPerPersonMode: PerPersonMode = PerPersonMode.ModeNotSet
            var AirLoopNum: Int = 0
            var zoneTurndownMinAirFracSched: Optional[Schedule] = None
            var ZoneTurndownMinAirFrac: Float64 = 1.0
            var MyEnvrnFlag: Bool = true
            var MySizeFlag: Bool = true
            var MyAirLoopFlag: Bool = true
            var CheckEquipName: Bool = true
            var dd_airterminalHotAirInlet: DualDuctAirTerminalFlowConditions
            var dd_airterminalColdAirInlet: DualDuctAirTerminalFlowConditions
            var dd_airterminalOutlet: DualDuctAirTerminalFlowConditions
            var dd_airterminalOAInlet: DualDuctAirTerminalFlowConditions
            var dd_airterminalRecircAirInlet: DualDuctAirTerminalFlowConditions
            def InitDualDuct(inout state: EnergyPlusData, FirstHVACIteration: Bool):
                ...
            def SizeDualDuct(inout state: EnergyPlusData):
                ...
            def SimDualDuctConstVol(inout state: EnergyPlusData, ZoneNum: Int, ZoneNodeNum: Int):
                ...
            def SimDualDuctVarVol(inout state: EnergyPlusData, ZoneNum: Int, ZoneNodeNum: Int):
                ...
            def SimDualDuctVAVOutdoorAir(inout state: EnergyPlusData, ZoneNum: Int, ZoneNodeNum: Int):
                ...
            def CalcOAMassFlow(inout state: EnergyPlusData, ref SAMassFlow: Float64, ref AirLoopOAFrac: Float64):
                ...
            def CalcOAOnlyMassFlow(inout state: EnergyPlusData, ref OAMassFlow: Float64, optional MaxOAVolFlow: Optional[Float64] = None):
                ...
            def CalcOutdoorAirVolumeFlowRate(inout state: EnergyPlusData):
                ...
            def UpdateDualDuct(inout state: EnergyPlusData):
                ...
            def reportTerminalUnit(inout state: EnergyPlusData):
                ...
        def SimulateDualDuct(inout state: EnergyPlusData, CompName: String, FirstHVACIteration: Bool, ZoneNum: Int, ZoneNodeNum: Int, ref CompIndex: Int):
            ...
        def GetDualDuctInput(inout state: EnergyPlusData):
            ...
        def ReportDualDuctConnections(inout state: EnergyPlusData):
            ...
        def GetDualDuctOutdoorAirRecircUse(inout state: EnergyPlusData, CompTypeName: String, CompName: String, ref RecircIsUsed: Bool):
            ...
    struct DualDuctData(BaseGlobalStruct):
        var NumDDAirTerminal: Int = 0
        var NumDualDuctVarVolOA: Int = 0
        var GetDualDuctInputFlag: Bool = true
        var dd_airterminal: List[DualDuct.DualDuctAirTerminal] = []
        var UniqueDualDuctAirTerminalNames: Dict[String, String] = {}
        var ZoneEquipmentListChecked: Bool = false
        var GetDualDuctOutdoorAirRecircUseFirstTimeOnly: Bool = true
        var RecircIsUsedARR: List[Bool] = []
        var DamperNamesARR: List[String] = []
        def init_constant_state(inout self, ref state: EnergyPlusData):

        def init_state(inout self, ref state: EnergyPlusData):

        def clear_state(inout self):
            new(self, DualDuctData())
def SimulateDualDuct(inout state: EnergyPlusData, CompName: String, FirstHVACIteration: Bool, ZoneNum: Int, ZoneNodeNum: Int, ref CompIndex: Int):
    var DDNum: Int = 0
    if state.dataDualDuct.GetDualDuctInputFlag:
        GetDualDuctInput(state)
        state.dataDualDuct.GetDualDuctInputFlag = False
    if CompIndex == 0:
        DDNum = Util.FindItemInList(CompName, state.dataDualDuct.dd_airterminal, "Name")
        if DDNum == -1:
            ShowFatalError(state, "SimulateDualDuct: Damper not found=" + CompName)
        CompIndex = DDNum
    else:
        DDNum = CompIndex
        if DDNum >= len(state.dataDualDuct.dd_airterminal) or DDNum < 0:
            ShowFatalError(state, "SimulateDualDuct: Invalid CompIndex passed=" + str(CompIndex) + ", Number of Dampers=" + str(len(state.dataDualDuct.dd_airterminal)) + ", Damper name=" + CompName)
        if state.dataDualDuct.dd_airterminal[DDNum].CheckEquipName:
            if CompName != state.dataDualDuct.dd_airterminal[DDNum].Name:
                ShowFatalError(state, "SimulateDualDuct: Invalid CompIndex passed=" + str(CompIndex) + ", Damper name=" + CompName + ", stored Damper Name for that index=" + state.dataDualDuct.dd_airterminal[DDNum].Name)
            state.dataDualDuct.dd_airterminal[DDNum].CheckEquipName = False
    var thisDualDuct: DualDuctAirTerminal = state.dataDualDuct.dd_airterminal[DDNum]
    if CompIndex >= 0:
        state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[thisDualDuct.ADUNum].TermUnitSizingNum
        thisDualDuct.InitDualDuct(state, FirstHVACIteration)
        if thisDualDuct.DamperType == DualDuctDamper.ConstantVolume:
            thisDualDuct.SimDualDuctConstVol(state, ZoneNum, ZoneNodeNum)
        elif thisDualDuct.DamperType == DualDuctDamper.VariableVolume:
            thisDualDuct.SimDualDuctVarVol(state, ZoneNum, ZoneNodeNum)
        elif thisDualDuct.DamperType == DualDuctDamper.OutdoorAir:
            thisDualDuct.SimDualDuctVAVOutdoorAir(state, ZoneNum, ZoneNodeNum)
        else:

        thisDualDuct.UpdateDualDuct(state)
    else:
        ShowFatalError(state, "SimulateDualDuct: Damper not found=" + CompName)
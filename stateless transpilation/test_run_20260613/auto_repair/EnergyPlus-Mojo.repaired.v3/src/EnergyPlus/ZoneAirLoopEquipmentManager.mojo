from AirTerminalUnit import *
from BranchNodeConnections import *
from CurveManager import *
from .Data.EnergyPlusData import EnergyPlusData
from DataAirLoop import *
from DataDefineEquip import *
from DataHeatBalance import *
from DataLoopNode import *
from DataSizing import *
from DataZoneEquipment import *
from DualDuct import *
from GeneralRoutines import *
from HVACCooledBeam import *
from HVACFourPipeBeam import *
from HVACSingleDuctInduc import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from PoweredInductionUnits import *
from Psychrometrics import *
from SingleDuct import *
from UserDefinedComponents import *
from UtilityRoutines import *
from ZoneAirLoopEquipmentManager import *

from memory import memset_zero
from utils import StringRef, format as eplus_format

@value
struct ZnAirLoopEquipTypeNamesUC:

# array<string_view, static_cast<int>(ZnAirLoopEquipType::Num)> ZnAirLoopEquipTypeNamesUC = {
#     "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME",
#     "AIRTERMINAL:DUALDUCT:VAV",
#     "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT",
#     "AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT",
#     "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT",
#     "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:NOREHEAT",
#     "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
#     "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
#     "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION",
#     "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN",
#     "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT",
#     "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:NOREHEAT",
#     "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:COOLEDBEAM",
#     "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR",
#     "AIRTERMINAL:SINGLEDUCT:USERDEFINED",
#     "AIRTERMINAL:SINGLEDUCT:MIXER",
#     "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEBEAM"}

# We'll use a list of strings for the enum names
var ZnAirLoopEquipTypeNamesUC: List[String] = List[String](
    "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME",
    "AIRTERMINAL:DUALDUCT:VAV",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:COOLEDBEAM",
    "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR",
    "AIRTERMINAL:SINGLEDUCT:USERDEFINED",
    "AIRTERMINAL:SINGLEDUCT:MIXER",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEBEAM"
)

def ManageZoneAirLoopEquipment(
    inout state: EnergyPlusData,
    ZoneAirLoopEquipName: String,
    FirstHVACIteration: Bool,
    inout SysOutputProvided: Float64,
    inout NonAirSysOutput: Float64,
    inout LatOutputProvided: Float64, # Latent add/removal supplied by air dist unit (kg/s), dehumid = negative
    ControlledZoneNum: Int,
    inout CompIndex: Int
):
    var AirDistUnitNum: Int
    if state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag:
        GetZoneAirLoopEquipment(state)
        state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
    if CompIndex == 0:
        AirDistUnitNum = Util.FindItemInList(ZoneAirLoopEquipName, state.dataDefineEquipment.AirDistUnit)
        if AirDistUnitNum == 0:
            ShowFatalError(state, eplus_format("ManageZoneAirLoopEquipment: Unit not found={}", ZoneAirLoopEquipName))
        CompIndex = AirDistUnitNum
    else:
        AirDistUnitNum = CompIndex
        if AirDistUnitNum > len(state.dataDefineEquipment.AirDistUnit) or AirDistUnitNum < 1:
            ShowFatalError(
                state,
                eplus_format("ManageZoneAirLoopEquipment:  Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}",
                    AirDistUnitNum,
                    len(state.dataDefineEquipment.AirDistUnit),
                    ZoneAirLoopEquipName))
        if ZoneAirLoopEquipName != state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].Name:
            ShowFatalError(
                state,
                eplus_format("ManageZoneAirLoopEquipment: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}",
                    AirDistUnitNum,
                    ZoneAirLoopEquipName,
                    state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].Name))
    state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].TermUnitSizingNum
    InitZoneAirLoopEquipment(state, AirDistUnitNum, ControlledZoneNum)
    InitZoneAirLoopEquipmentTimeStep(state, AirDistUnitNum)
    SimZoneAirLoopEquipment(state, AirDistUnitNum, SysOutputProvided, NonAirSysOutput, LatOutputProvided, FirstHVACIteration, ControlledZoneNum)
    InitZoneAirLoopEquipment(state, AirDistUnitNum, ControlledZoneNum)

def GetZoneAirLoopEquipment(inout state: EnergyPlusData):
    using DualDuct.GetDualDuctOutdoorAirRecircUse
    using Node.GetOnlySingleNode
    using Node.SetUpCompSets
    var RoutineName: String = "GetZoneAirLoopEquipment: "   # include trailing blank space
    var CurrentModuleObject: String = "ZoneHVAC:AirDistributionUnit" # Object type for getting and error messages
    var ErrorsFound: Bool = False # If errors detected in input
    var AlphArray: List[String] = List[String](5)
    var NumArray: List[Float64] = List[Float64](2)
    var cAlphaFields: List[String] = List[String](5)   # Alpha field names
    var cNumericFields: List[String] = List[String](2) # Numeric field names
    var lAlphaBlanks: List[Bool] = List[Bool](5)     # Logical array, alpha field input BLANK = .TRUE.
    var lNumericBlanks: List[Bool] = List[Bool](2)   # Logical array, numeric field input BLANK = .TRUE.
    var NumAirDistUnits: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataDefineEquipment.AirDistUnit = List[DataDefineEquip.AirDistUnitStruct](NumAirDistUnits)
    if NumAirDistUnits > 0:
        var NumAlphas: Int
        var NumNums: Int
        var IOStat: Int
        var IsNotOK: Bool # Flag to verify name
        for AirDistUnitNum in range(1, NumAirDistUnits + 1):
            var airDistUnit = state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                CurrentModuleObject,
                AirDistUnitNum,
                AlphArray,
                NumAlphas,
                NumArray,
                NumNums,
                IOStat,
                lNumericBlanks,
                lAlphaBlanks,
                cAlphaFields,
                cNumericFields) #  data for one zone
            airDistUnit.Name = AlphArray[0]
            airDistUnit.OutletNodeNum = GetOnlySingleNode(state,
                AlphArray[1],
                ErrorsFound,
                Node.ConnectionObjectType.ZoneHVACAirDistributionUnit,
                AlphArray[0],
                Node.FluidType.Air,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                Node.ObjectIsParent)
            airDistUnit.InletNodeNum = 0
            airDistUnit.NumComponents = 1
            var AirDistCompUnitNum: Int = 1
            airDistUnit.EquipType[AirDistCompUnitNum - 1] = AlphArray[2]
            airDistUnit.EquipName[AirDistCompUnitNum - 1] = AlphArray[3]
            ValidateComponent(state, AlphArray[2], AlphArray[3], IsNotOK, CurrentModuleObject)
            if IsNotOK:
                ShowContinueError(state, eplus_format("In {} = {}", CurrentModuleObject, AlphArray[0]))
                ErrorsFound = True
            airDistUnit.UpStreamLeakFrac = NumArray[0]
            airDistUnit.DownStreamLeakFrac = NumArray[1]
            if airDistUnit.DownStreamLeakFrac <= 0.0:
                airDistUnit.LeakLoadMult = 1.0
            elif airDistUnit.DownStreamLeakFrac < 1.0 and airDistUnit.DownStreamLeakFrac > 0.0:
                airDistUnit.LeakLoadMult = 1.0 / (1.0 - airDistUnit.DownStreamLeakFrac)
            else:
                ShowSevereError(state, eplus_format("Error found in {} = {}", CurrentModuleObject, airDistUnit.Name))
                ShowContinueError(state, eplus_format("{} must be less than 1.0", cNumericFields[1]))
                ErrorsFound = True
            if airDistUnit.UpStreamLeakFrac > 0.0:
                airDistUnit.UpStreamLeak = True
            else:
                airDistUnit.UpStreamLeak = False
            if airDistUnit.DownStreamLeakFrac > 0.0:
                airDistUnit.DownStreamLeak = True
            else:
                airDistUnit.DownStreamLeak = False
            airDistUnit.AirTerminalSizingSpecIndex = 0
            if not lAlphaBlanks[4]:
                airDistUnit.AirTerminalSizingSpecIndex = Util.FindItemInList(AlphArray[4], state.dataSize.AirTerminalSizingSpec)
                if airDistUnit.AirTerminalSizingSpecIndex == 0:
                    ShowSevereError(state, eplus_format("{} = {} not found.", cAlphaFields[4], AlphArray[4]))
                    ShowContinueError(state, eplus_format("Occurs in {} = {}", CurrentModuleObject, airDistUnit.Name))
                    ErrorsFound = True
            var typeNameUC: String = Util.makeUPPER(airDistUnit.EquipType[AirDistCompUnitNum - 1])
            airDistUnit.EquipTypeEnum[AirDistCompUnitNum - 1] = getEnumValue(ZnAirLoopEquipTypeNamesUC, typeNameUC)
            # switch (airDistUnit.EquipTypeEnum(AirDistCompUnitNum)) {
            # case DataDefineEquip::ZnAirLoopEquipType::DualDuctConstVolume:
            # case DataDefineEquip::ZnAirLoopEquipType::DualDuctVAV:
            # case DataDefineEquip::ZnAirLoopEquipType::DualDuctVAVOutdoorAir:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuct_SeriesPIU_Reheat:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuct_ParallelPIU_Reheat:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuct_ConstVol_4PipeInduc:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctVAVReheatVSFan:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolCooledBeam:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctUserDefined:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctATMixer:
            #     if (airDistUnit.UpStreamLeak || airDistUnit.DownStreamLeak) {
            #         ShowSevereError(state, EnergyPlus::format("Error found in {} = {}", CurrentModuleObject, airDistUnit.Name));
            #         ShowContinueError(state,
            #                           EnergyPlus::format("Simple duct leakage model not available for {} = {}",
            #                                              cAlphaFields(3),
            #                                              airDistUnit.EquipType(AirDistCompUnitNum)));
            #         ErrorsFound = true;
            #     }
            #     break;
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolFourPipeBeam:
            #     airDistUnit.airTerminalPtr = FourPipeBeam::HVACFourPipeBeam::fourPipeBeamFactory(state, airDistUnit.EquipName(1));
            #     if (airDistUnit.UpStreamLeak || airDistUnit.DownStreamLeak) {
            #         ShowSevereError(state, EnergyPlus::format("Error found in {} = {}", CurrentModuleObject, airDistUnit.Name));
            #         ShowContinueError(state,
            #                           EnergyPlus::format("Simple duct leakage model not available for {} = {}",
            #                                              cAlphaFields(3),
            #                                              airDistUnit.EquipType(AirDistCompUnitNum)));
            #         ErrorsFound = true;
            #     }
            #     break;
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolReheat:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolNoReheat:
            #     break;
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctVAVReheat:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctVAVNoReheat:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctCBVAVReheat:
            # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctCBVAVNoReheat:
            #     airDistUnit.IsConstLeakageRate = true;
            #     break;
            # default:
            #     ShowSevereError(state, EnergyPlus::format("Error found in {} = {}", CurrentModuleObject, airDistUnit.Name));
            #     ShowContinueError(state, EnergyPlus::format("Invalid {} = {}", cAlphaFields(3), airDistUnit.EquipType(AirDistCompUnitNum)));
            #     ErrorsFound = true;
            #     break;
            # } // end switch
            if (airDistUnit.EquipTypeEnum[AirDistCompUnitNum - 1] == DataDefineEquip.ZnAirLoopEquipType.DualDuctConstVolume) or
                (airDistUnit.EquipTypeEnum[AirDistCompUnitNum - 1] == DataDefineEquip.ZnAirLoopEquipType.DualDuctVAV):
                SetUpCompSets(state,
                    CurrentModuleObject,
                    airDistUnit.Name,
                    airDistUnit.EquipType[AirDistCompUnitNum - 1] + ":HEAT",
                    airDistUnit.EquipName[AirDistCompUnitNum - 1],
                    "UNDEFINED",
                    AlphArray[1])
                SetUpCompSets(state,
                    CurrentModuleObject,
                    airDistUnit.Name,
                    airDistUnit.EquipType[AirDistCompUnitNum - 1] + ":COOL",
                    airDistUnit.EquipName[AirDistCompUnitNum - 1],
                    "UNDEFINED",
                    AlphArray[1])
            elif airDistUnit.EquipTypeEnum[AirDistCompUnitNum - 1] == DataDefineEquip.ZnAirLoopEquipType.DualDuctVAVOutdoorAir:
                SetUpCompSets(state,
                    CurrentModuleObject,
                    airDistUnit.Name,
                    airDistUnit.EquipType[AirDistCompUnitNum - 1] + ":OutdoorAir",
                    airDistUnit.EquipName[AirDistCompUnitNum - 1],
                    "UNDEFINED",
                    AlphArray[1])
                var DualDuctRecircIsUsed: Bool # local temporary for deciding if recirc side used by dual duct terminal
                GetDualDuctOutdoorAirRecircUse(
                    state, airDistUnit.EquipType[AirDistCompUnitNum - 1], airDistUnit.EquipName[AirDistCompUnitNum - 1], DualDuctRecircIsUsed)
                if DualDuctRecircIsUsed:
                    SetUpCompSets(state,
                        CurrentModuleObject,
                        airDistUnit.Name,
                        airDistUnit.EquipType[AirDistCompUnitNum - 1] + ":RecirculatedAir",
                        airDistUnit.EquipName[AirDistCompUnitNum - 1],
                        "UNDEFINED",
                        AlphArray[1])
            else:
                SetUpCompSets(state,
                    CurrentModuleObject,
                    airDistUnit.Name,
                    airDistUnit.EquipType[AirDistCompUnitNum - 1],
                    airDistUnit.EquipName[AirDistCompUnitNum - 1],
                    "UNDEFINED",
                    AlphArray[1])
        # End of Air Dist Do Loop
        for AirDistUnitNum in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
            var airDistUnit = state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1]
            SetupOutputVariable(state,
                "Zone Air Terminal Sensible Heating Energy",
                Constant.Units.J,
                airDistUnit.HeatGain,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                airDistUnit.Name)
            SetupOutputVariable(state,
                "Zone Air Terminal Sensible Cooling Energy",
                Constant.Units.J,
                airDistUnit.CoolGain,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                airDistUnit.Name)
            SetupOutputVariable(state,
                "Zone Air Terminal Sensible Heating Rate",
                Constant.Units.W,
                airDistUnit.HeatRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                airDistUnit.Name)
            SetupOutputVariable(state,
                "Zone Air Terminal Sensible Cooling Rate",
                Constant.Units.W,
                airDistUnit.CoolRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                airDistUnit.Name)
    if ErrorsFound:
        ShowFatalError(state, eplus_format("{}Errors found in getting {} Input", RoutineName, CurrentModuleObject))

def InitZoneAirLoopEquipment(inout state: EnergyPlusData, AirDistUnitNum: Int, ControlledZoneNum: Int):
    if not state.dataZoneAirLoopEquipmentManager.InitAirDistUnitsFlag:
        return
    if state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].EachOnceFlag and
        (state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].TermUnitSizingNum > 0):
        {
            var thisADU = state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1]
            {
                var thisZoneEqConfig = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1]
                thisADU.ZoneNum = ControlledZoneNum
                for inletNum in range(1, thisZoneEqConfig.NumInletNodes + 1):
                    if thisZoneEqConfig.InletNode[inletNum - 1] == thisADU.OutletNodeNum:
                        thisZoneEqConfig.InletNodeADUNum[inletNum - 1] = AirDistUnitNum
            }
            {
                var thisTermUnitSizingData = state.dataSize.TermUnitSizing[thisADU.TermUnitSizingNum - 1]
                thisTermUnitSizingData.ADUName = thisADU.Name
                if thisADU.AirTerminalSizingSpecIndex > 0:
                    {
                        var thisAirTermSizingSpec = state.dataSize.AirTerminalSizingSpec[thisADU.AirTerminalSizingSpecIndex - 1]
                        thisTermUnitSizingData.SpecDesCoolSATRatio = thisAirTermSizingSpec.DesCoolSATRatio
                        thisTermUnitSizingData.SpecDesHeatSATRatio = thisAirTermSizingSpec.DesHeatSATRatio
                        thisTermUnitSizingData.SpecDesSensCoolingFrac = thisAirTermSizingSpec.DesSensCoolingFrac
                        thisTermUnitSizingData.SpecDesSensHeatingFrac = thisAirTermSizingSpec.DesSensHeatingFrac
                        thisTermUnitSizingData.SpecMinOAFrac = thisAirTermSizingSpec.MinOAFrac
                    }
            }
        }
        if state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].ZoneNum != 0 and
            state.dataHeatBal.Zone[state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].ZoneNum - 1].HasAdjustedReturnTempByITE:
            for AirDistCompNum in range(1, state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].NumComponents + 1):
                if state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].EquipTypeEnum[AirDistCompNum - 1] !=
                        DataDefineEquip.ZnAirLoopEquipType.SingleDuctVAVReheat and
                    state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].EquipTypeEnum[AirDistCompNum - 1] !=
                        DataDefineEquip.ZnAirLoopEquipType.SingleDuctVAVNoReheat:
                    ShowSevereError(state,
                        "The FlowControlWithApproachTemperatures only works with ITE zones with single duct VAV terminal unit.")
                    ShowContinueError(state, "The return air temperature of the ITE will not be overwritten.")
                    ShowFatalError(state, "Preceding condition causes termination.")
        state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].EachOnceFlag = False
        state.dataZoneAirLoopEquipmentManager.numADUInitialized += 1
        if state.dataZoneAirLoopEquipmentManager.numADUInitialized == len(state.dataDefineEquipment.AirDistUnit):
            state.dataZoneAirLoopEquipmentManager.InitAirDistUnitsFlag = False

def InitZoneAirLoopEquipmentTimeStep(inout state: EnergyPlusData, AirDistUnitNum: Int):
    var airDistUnit = state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1]
    airDistUnit.MassFlowRateDnStrLk = 0.0
    airDistUnit.MassFlowRateUpStrLk = 0.0
    airDistUnit.parallelPIUTerminalLeakFrac = 0.0
    airDistUnit.massFlowRateParallelPIULk = 0.0
    airDistUnit.MassFlowRateTU = 0.0
    airDistUnit.MassFlowRateZSup = 0.0
    airDistUnit.MassFlowRateSup = 0.0
    airDistUnit.HeatRate = 0.0
    airDistUnit.CoolRate = 0.0
    airDistUnit.HeatGain = 0.0
    airDistUnit.CoolGain = 0.0

def SimZoneAirLoopEquipment(
    inout state: EnergyPlusData,
    AirDistUnitNum: Int,
    inout SysOutputProvided: Float64,
    inout NonAirSysOutput: Float64,
    inout LatOutputProvided: Float64, # Latent add/removal provided by this unit (kg/s), dehumidify = negative
    FirstHVACIteration: Bool,
    ControlledZoneNum: Int
):
    using DualDuct.SimulateDualDuct
    using HVACCooledBeam.SimCoolBeam
    using HVACSingleDuctInduc.SimIndUnit
    using PoweredInductionUnits.SimPIU
    using Psychrometrics.PsyCpAirFnW
    using SingleDuct.GetATMixers
    using SingleDuct.SimulateSingleDuct
    using UserDefinedComponents.SimAirTerminalUserDefined
    var ProvideSysOutput: Bool
    var AirDistCompNum: Int
    var AirLoopNum: Int = 0                  # index of air loop
    var MassFlowRateMaxAvail: Float64        # max avail mass flow rate excluding leaks [kg/s]
    var MassFlowRateMinAvail: Float64        # min avail mass flow rate excluding leaks [kg/s]
    var MassFlowRateUpStreamLeakMax: Float64 # max upstream leak flow rate [kg/s]
    var DesFlowRatio: Float64 = 0.0           # ratio of system to sum of zones design flow rate
    var SpecHumOut: Float64 = 0.0             # Specific humidity ratio of outlet air (kg moisture / kg moist air)
    var SpecHumIn: Float64 = 0.0              # Specific humidity ratio of inlet air (kg moisture / kg moist air)
    var controlledZoneAirNode: Int = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1].ZoneNode
    ProvideSysOutput = True
    for AirDistCompNum in range(1, state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].NumComponents + 1):
        NonAirSysOutput = 0.0
        var airDistUnit = state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1]
        var InNodeNum: Int = airDistUnit.InletNodeNum
        var OutNodeNum: Int = airDistUnit.OutletNodeNum
        MassFlowRateMaxAvail = 0.0
        MassFlowRateMinAvail = 0.0
        airDistUnit.parallelPIUTerminalLeakFrac = 0.0
        if airDistUnit.UpStreamLeak or airDistUnit.DownStreamLeak or
            airDistUnit.EquipTypeEnum[AirDistCompNum - 1] == DataDefineEquip.ZnAirLoopEquipType.SingleDuct_ParallelPIU_Reheat:
            if InNodeNum > 0:
                MassFlowRateMaxAvail = state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMaxAvail
                MassFlowRateMinAvail = state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMinAvail
                if airDistUnit.IsConstLeakageRate:
                    AirLoopNum = airDistUnit.AirLoopNum
                    if AirLoopNum > 0:
                        DesFlowRatio = state.dataAirLoop.AirLoopFlow[AirLoopNum - 1].SysToZoneDesFlowRatio
                    else:
                        DesFlowRatio = 1.0
                    MassFlowRateUpStreamLeakMax = max(airDistUnit.UpStreamLeakFrac * state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMax * DesFlowRatio, 0.0)
                else:
                    MassFlowRateUpStreamLeakMax = max(airDistUnit.UpStreamLeakFrac * MassFlowRateMaxAvail, 0.0)
                if MassFlowRateMaxAvail > MassFlowRateUpStreamLeakMax:
                    airDistUnit.MassFlowRateUpStrLk = MassFlowRateUpStreamLeakMax
                    state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMaxAvail = MassFlowRateMaxAvail - MassFlowRateUpStreamLeakMax
                else:
                    airDistUnit.MassFlowRateUpStrLk = MassFlowRateMaxAvail
                    state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMaxAvail = 0.0
                state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMinAvail = max(0.0, MassFlowRateMinAvail - airDistUnit.MassFlowRateUpStrLk)
        # switch (airDistUnit.EquipTypeEnum(AirDistCompNum)) {
        # case DataDefineEquip::ZnAirLoopEquipType::DualDuctConstVolume: {
        #     SimulateDualDuct(state,
        #                      airDistUnit.EquipName(AirDistCompNum),
        #                      FirstHVACIteration,
        #                      ControlledZoneNum,
        #                      controlledZoneAirNode,
        #                      airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::DualDuctVAV: {
        #     SimulateDualDuct(state,
        #                      airDistUnit.EquipName(AirDistCompNum),
        #                      FirstHVACIteration,
        #                      ControlledZoneNum,
        #                      controlledZoneAirNode,
        #                      airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::DualDuctVAVOutdoorAir: {
        #     SimulateDualDuct(state,
        #                      airDistUnit.EquipName(AirDistCompNum),
        #                      FirstHVACIteration,
        #                      ControlledZoneNum,
        #                      controlledZoneAirNode,
        #                      airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctVAVReheat: {
        #     SimulateSingleDuct(state,
        #                        airDistUnit.EquipName(AirDistCompNum),
        #                        FirstHVACIteration,
        #                        ControlledZoneNum,
        #                        controlledZoneAirNode,
        #                        airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctCBVAVReheat: {
        #     SimulateSingleDuct(state,
        #                        airDistUnit.EquipName(AirDistCompNum),
        #                        FirstHVACIteration,
        #                        ControlledZoneNum,
        #                        controlledZoneAirNode,
        #                        airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctVAVNoReheat: {
        #     SimulateSingleDuct(state,
        #                        airDistUnit.EquipName(AirDistCompNum),
        #                        FirstHVACIteration,
        #                        ControlledZoneNum,
        #                        controlledZoneAirNode,
        #                        airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctCBVAVNoReheat: {
        #     SimulateSingleDuct(state,
        #                        airDistUnit.EquipName(AirDistCompNum),
        #                        FirstHVACIteration,
        #                        ControlledZoneNum,
        #                        controlledZoneAirNode,
        #                        airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolReheat: {
        #     SimulateSingleDuct(state,
        #                        airDistUnit.EquipName(AirDistCompNum),
        #                        FirstHVACIteration,
        #                        ControlledZoneNum,
        #                        controlledZoneAirNode,
        #                        airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolNoReheat: {
        #     SimulateSingleDuct(state,
        #                        airDistUnit.EquipName(AirDistCompNum),
        #                        FirstHVACIteration,
        #                        ControlledZoneNum,
        #                        controlledZoneAirNode,
        #                        airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuct_SeriesPIU_Reheat: {
        #     SimPIU(state,
        #            airDistUnit.EquipName(AirDistCompNum),
        #            FirstHVACIteration,
        #            ControlledZoneNum,
        #            controlledZoneAirNode,
        #            airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuct_ParallelPIU_Reheat: {
        #     SimPIU(state,
        #            airDistUnit.EquipName(AirDistCompNum),
        #            FirstHVACIteration,
        #            ControlledZoneNum,
        #            controlledZoneAirNode,
        #            airDistUnit.EquipIndex(AirDistCompNum));
        #     if (int PIUNum = Util::FindItemInList(airDistUnit.EquipName(AirDistCompNum), state.dataPowerInductionUnits->PIU); PIUNum > 0) {
        #         airDistUnit.parallelPIUTerminalLeakFrac = state.dataPowerInductionUnits->PIU(PIUNum).leakFrac;
        #         if (state.dataPowerInductionUnits->PIU(PIUNum).damperLeakageZoneNum > 0 && airDistUnit.piuLkZoneNum <= 0) { // one-time assignment
        #             airDistUnit.piuLkZoneNum = state.dataPowerInductionUnits->PIU(PIUNum).damperLeakageZoneNum;
        #         }
        #     }
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuct_ConstVol_4PipeInduc: {
        #     SimIndUnit(state,
        #                airDistUnit.EquipName(AirDistCompNum),
        #                FirstHVACIteration,
        #                ControlledZoneNum,
        #                controlledZoneAirNode,
        #                airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctVAVReheatVSFan: {
        #     SimulateSingleDuct(state,
        #                        airDistUnit.EquipName(AirDistCompNum),
        #                        FirstHVACIteration,
        #                        ControlledZoneNum,
        #                        controlledZoneAirNode,
        #                        airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolCooledBeam: {
        #     SimCoolBeam(state,
        #                 airDistUnit.EquipName(AirDistCompNum),
        #                 FirstHVACIteration,
        #                 ControlledZoneNum,
        #                 controlledZoneAirNode,
        #                 airDistUnit.EquipIndex(AirDistCompNum),
        #                 NonAirSysOutput);
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctConstVolFourPipeBeam: {
        #     airDistUnit.airTerminalPtr->simulate(state, FirstHVACIteration, NonAirSysOutput);
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctUserDefined: {
        #     SimAirTerminalUserDefined(state,
        #                               airDistUnit.EquipName(AirDistCompNum),
        #                               FirstHVACIteration,
        #                               ControlledZoneNum,
        #                               controlledZoneAirNode,
        #                               airDistUnit.EquipIndex(AirDistCompNum));
        # } break;
        # case DataDefineEquip::ZnAirLoopEquipType::SingleDuctATMixer: {
        #     GetATMixers(state); // Needed here if mixer used only with unitarysystem which gets its input late
        #     ProvideSysOutput = false;
        # } break;
        # default: {
        #     ShowSevereError(state, EnergyPlus::format("Error found in ZoneHVAC:AirDistributionUnit={}", airDistUnit.Name));
        #     ShowContinueError(state, EnergyPlus::format("Invalid Component={}", airDistUnit.EquipType(AirDistCompNum)));
        #     ShowFatalError(state, "Preceding condition causes termination.");
        # } break;
        # }
        if InNodeNum > 0: # InNodeNum is not always known when this is called, eg FPIU
            InNodeNum = airDistUnit.InletNodeNum
            if airDistUnit.UpStreamLeak:
                state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMaxAvail = MassFlowRateMaxAvail
                state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRateMinAvail = MassFlowRateMinAvail
            if (airDistUnit.UpStreamLeak or airDistUnit.DownStreamLeak or airDistUnit.parallelPIUTerminalLeakFrac > 0.0) and
                MassFlowRateMaxAvail > 0.0:
                airDistUnit.MassFlowRateTU = state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRate
                airDistUnit.MassFlowRateZSup = max(airDistUnit.MassFlowRateTU * (1.0 - airDistUnit.DownStreamLeakFrac - airDistUnit.parallelPIUTerminalLeakFrac), 0.0)
                airDistUnit.MassFlowRateDnStrLk = airDistUnit.MassFlowRateTU * airDistUnit.DownStreamLeakFrac
                airDistUnit.massFlowRateParallelPIULk = airDistUnit.MassFlowRateTU * airDistUnit.parallelPIUTerminalLeakFrac
                airDistUnit.MassFlowRateSup = airDistUnit.MassFlowRateTU + airDistUnit.MassFlowRateUpStrLk
                state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRate = airDistUnit.MassFlowRateSup
                state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRate = airDistUnit.MassFlowRateZSup
                state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRateMaxAvail = max(0.0,
                    MassFlowRateMaxAvail - airDistUnit.MassFlowRateDnStrLk - airDistUnit.MassFlowRateUpStrLk - airDistUnit.massFlowRateParallelPIULk)
                state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRateMinAvail = max(0.0,
                    MassFlowRateMinAvail - airDistUnit.MassFlowRateDnStrLk - airDistUnit.MassFlowRateUpStrLk - airDistUnit.massFlowRateParallelPIULk)
                airDistUnit.MaxAvailDelta = MassFlowRateMaxAvail - state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRateMaxAvail
                airDistUnit.MinAvailDelta = MassFlowRateMinAvail - state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRateMinAvail
            else:
                var termUnitType: DataDefineEquip.ZnAirLoopEquipType = airDistUnit.EquipTypeEnum[AirDistCompNum - 1]
                if (termUnitType == DataDefineEquip.ZnAirLoopEquipType.DualDuctConstVolume) or
                    (termUnitType == DataDefineEquip.ZnAirLoopEquipType.DualDuctVAV) or
                    (termUnitType == DataDefineEquip.ZnAirLoopEquipType.DualDuctVAVOutdoorAir):
                    airDistUnit.MassFlowRateTU = state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRate
                    airDistUnit.MassFlowRateZSup = state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRate
                    airDistUnit.MassFlowRateSup = state.dataLoopNodes.Node[OutNodeNum - 1].MassFlowRate
                else:
                    airDistUnit.MassFlowRateTU = state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRate
                    airDistUnit.MassFlowRateZSup = state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRate
                    airDistUnit.MassFlowRateSup = state.dataLoopNodes.Node[InNodeNum - 1].MassFlowRate
    if ProvideSysOutput:
        var OutletNodeNum: Int = state.dataDefineEquipment.AirDistUnit[AirDistUnitNum - 1].OutletNodeNum
        SpecHumOut = state.dataLoopNodes.Node[OutletNodeNum - 1].HumRat
        SpecHumIn = state.dataLoopNodes.Node[controlledZoneAirNode - 1].HumRat
        SysOutputProvided = state.dataLoopNodes.Node[OutletNodeNum - 1].MassFlowRate * Psychrometrics.PsyDeltaHSenFnTdb2W2Tdb1W1(
            state.dataLoopNodes.Node[OutletNodeNum - 1].Temp,
            SpecHumOut,
            state.dataLoopNodes.Node[controlledZoneAirNode - 1].Temp,
            SpecHumIn) # sensible {W};
        LatOutputProvided = state.dataLoopNodes.Node[OutletNodeNum - 1].MassFlowRate * (SpecHumOut - SpecHumIn) # Latent rate (kg/s), dehumid = negative
    else:
        SysOutputProvided = 0.0
        LatOutputProvided = 0.0
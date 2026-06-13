from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.DataGlobals import *
from DataHVACGlobals import *
from EnergyPlus.EnergyPlus import *
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.Array.functions import allocated
from ObjexxFCL.Fmath import min, max
from .Autosizing.Base import BaseSizer, CheckSysSizing, DataSizing
from BranchNodeConnections import *
from .Coils.CoilCoolingDX import CoilCoolingDX
from DXCoils import DXCoils
from .Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import *
from DataAirSystems import *
from DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataLoopNode import Node
from DataSizing import *
from EnergyPlus.DataZoneControls import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from EMSManager import EMSManager
from Fans import Fans
from FluidProperties import Fluid
from General import General
from GeneralRoutines import *
from HVACDXHeatPumpSystem import HVACDXHeatPumpSystem
from HVACHXAssistedCoolingCoil import HVACHXAssistedCoolingCoil
from HVACUnitaryBypassVAV import *
from HeatingCoils import HeatingCoils
from .InputProcessing.InputProcessor import InputProcessor
from MixedAir import MixedAir
from MixerComponent import MixerComponent
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor, SetupOutputVariable
from EnergyPlus.Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from ScheduleManager import Sched
from SetPointManager import SetPointManager
from SteamCoils import SteamCoils
from UtilityRoutines import Util
from VariableSpeedCoils import VariableSpeedCoils
from WaterCoils import WaterCoils
from ZonePlenum import ZonePlenum
from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.DataGlobals import *
from DataHVACGlobals import *
from EnergyPlus.EnergyPlus import *
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.Array.functions import allocated
from ObjexxFCL.Fmath import min, max
from .Autosizing.Base import BaseSizer, CheckSysSizing, DataSizing
from BranchNodeConnections import *
from .Coils.CoilCoolingDX import CoilCoolingDX
from DXCoils import DXCoils
from .Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import *
from DataAirSystems import *
from DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataLoopNode import Node
from DataSizing import *
from EnergyPlus.DataZoneControls import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from EMSManager import EMSManager
from Fans import Fans
from FluidProperties import Fluid
from General import General
from GeneralRoutines import *
from HVACDXHeatPumpSystem import HVACDXHeatPumpSystem
from HVACHXAssistedCoolingCoil import HVACHXAssistedCoolingCoil
from HVACUnitaryBypassVAV import *
from HeatingCoils import HeatingCoils
from .InputProcessing.InputProcessor import InputProcessor
from MixedAir import MixedAir
from MixerComponent import MixerComponent
from NodeInputManager import NodeInputManager
from OutputProcessor import OutputProcessor, SetupOutputVariable
from EnergyPlus.Plant.DataPlant import DataPlant
from PlantUtilities import PlantUtilities
from Psychrometrics import Psychrometrics
from ScheduleManager import Sched
from SetPointManager import SetPointManager
from SteamCoils import SteamCoils
from UtilityRoutines import Util
from VariableSpeedCoils import VariableSpeedCoils
from WaterCoils import WaterCoils
from ZonePlenum import ZonePlenum

import math
import format

struct EnergyPlusData:

namespace HVACUnitaryBypassVAV:

    def SimUnitaryBypassVAV(
        inout state: EnergyPlusData,
        CompName: StringLiteral,  # Name of the CBVAV system
        FirstHVACIteration: Bool,  # TRUE if 1st HVAC simulation of system time step
        AirLoopNum: Int,  # air loop index
        inout CompIndex: Int  # Index to changeover-bypass VAV system
    ):
        var CBVAVNum: Int = 0  # Index of CBVAV system being simulated
        var QUnitOut: Float64 = 0.0  # Sensible capacity delivered by this air loop system
        if state.dataHVACUnitaryBypassVAV.GetInputFlag:
            GetCBVAV(state)
            state.dataHVACUnitaryBypassVAV.GetInputFlag = False
        if CompIndex == 0:
            CBVAVNum = Util.FindItemInList(CompName, state.dataHVACUnitaryBypassVAV.CBVAV)
            if CBVAVNum == 0:
                ShowFatalError(state, "SimUnitaryBypassVAV: Unit not found={}".format(CompName))
            CompIndex = CBVAVNum
        else:
            CBVAVNum = CompIndex
            if CBVAVNum > state.dataHVACUnitaryBypassVAV.NumCBVAV or CBVAVNum < 1:
                ShowFatalError(state,
                    "SimUnitaryBypassVAV:  Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}".format(
                        CBVAVNum, state.dataHVACUnitaryBypassVAV.NumCBVAV, CompName))
            if state.dataHVACUnitaryBypassVAV.CheckEquipName[CBVAVNum]:
                if CompName != state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum].Name:
                    ShowFatalError(state,
                        "SimUnitaryBypassVAV: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}".format(
                            CBVAVNum, CompName, state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum].Name))
                state.dataHVACUnitaryBypassVAV.CheckEquipName[CBVAVNum] = False
        var OnOffAirFlowRatio: Float64 = 0.0  # Ratio of compressor ON airflow to average airflow over timestep
        var HXUnitOn: Bool = True  # flag to enable heat exchanger
        InitCBVAV(state, CBVAVNum, FirstHVACIteration, AirLoopNum, OnOffAirFlowRatio, HXUnitOn)
        SimCBVAV(state, CBVAVNum, FirstHVACIteration, QUnitOut, OnOffAirFlowRatio, HXUnitOn)
        ReportCBVAV(state, CBVAVNum)

    def SimCBVAV(
        inout state: EnergyPlusData,
        CBVAVNum: Int,  # Index of the current CBVAV system being simulated
        FirstHVACIteration: Bool,  # TRUE if 1st HVAC simulation of system timestep
        inout QSensUnitOut: Float64,  # Sensible delivered capacity [W]
        inout OnOffAirFlowRatio: Float64,  # Ratio of compressor ON airflow to AVERAGE airflow over timestep
        HXUnitOn: Bool  # flag to enable heat exchanger
    ):
        QSensUnitOut = 0.0  # probably don't need this initialization
        var changeOverByPassVAV = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum]
        state.dataHVACGlobal.DXElecCoolingPower = 0.0
        state.dataHVACGlobal.DXElecHeatingPower = 0.0
        state.dataHVACGlobal.ElecHeatingCoilPower = 0.0
        state.dataHVACUnitaryBypassVAV.SaveCompressorPLR = 0.0
        state.dataHVACGlobal.DefrostElecPower = 0.0
        var UnitOn: Bool = True
        var OutletNode: Int = changeOverByPassVAV.AirOutNode
        var InletNode: Int = changeOverByPassVAV.AirInNode
        var AirMassFlow: Float64 = state.dataLoopNodes.Node[InletNode].MassFlowRate
        var PartLoadFrac: Float64 = 0.0
        if changeOverByPassVAV.fanOp == HVAC.FanOp.Cycling:
            if changeOverByPassVAV.HeatCoolMode == 0 or AirMassFlow < HVAC.SmallMassFlow:
                UnitOn = False
        elif changeOverByPassVAV.fanOp == HVAC.FanOp.Continuous:
            if AirMassFlow < HVAC.SmallMassFlow:
                UnitOn = False
        state.dataHVACGlobal.OnOffFanPartLoadFraction = 1.0
        if UnitOn:
            ControlCBVAVOutput(state, CBVAVNum, FirstHVACIteration, PartLoadFrac, OnOffAirFlowRatio, HXUnitOn)
        else:
            CalcCBVAV(state, CBVAVNum, FirstHVACIteration, PartLoadFrac, QSensUnitOut, OnOffAirFlowRatio, HXUnitOn)
        if changeOverByPassVAV.modeChanged:
            state.dataLoopNodes.Node[changeOverByPassVAV.AirOutNode].TempSetPoint = CalcSetPointTempTarget(state, CBVAVNum)
            if changeOverByPassVAV.OutNodeSPMIndex > 0:  # update mixed air SPM if exists
                state.dataSetPointManager.spms[changeOverByPassVAV.OutNodeSPMIndex].calculate(state)  # update mixed air SP based on new mode
                SetPointManager.UpdateMixedAirSetPoints(state)  # need to know control node to fire off just one of these, do this later
        AirMassFlow = state.dataLoopNodes.Node[OutletNode].MassFlowRate
        var QTotUnitOut: Float64 = AirMassFlow * (state.dataLoopNodes.Node[OutletNode].Enthalpy - state.dataLoopNodes.Node[InletNode].Enthalpy)
        var MinOutletHumRat: Float64 = min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
        QSensUnitOut = AirMassFlow * (Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, MinOutletHumRat) -
                                      Psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, MinOutletHumRat))
        changeOverByPassVAV.CompPartLoadRatio = state.dataHVACUnitaryBypassVAV.SaveCompressorPLR
        if UnitOn:
            changeOverByPassVAV.FanPartLoadRatio = 1.0
        else:
            changeOverByPassVAV.FanPartLoadRatio = 0.0
        changeOverByPassVAV.TotCoolEnergyRate = abs(min(0.0, QTotUnitOut))
        changeOverByPassVAV.TotHeatEnergyRate = abs(max(0.0, QTotUnitOut))
        changeOverByPassVAV.SensCoolEnergyRate = abs(min(0.0, QSensUnitOut))
        changeOverByPassVAV.SensHeatEnergyRate = abs(max(0.0, QSensUnitOut))
        changeOverByPassVAV.LatCoolEnergyRate = abs(min(0.0, (QTotUnitOut - QSensUnitOut)))
        changeOverByPassVAV.LatHeatEnergyRate = abs(max(0.0, (QTotUnitOut - QSensUnitOut)))
        var HeatingPower: Float64 = 0.0  # DX Htg coil Plus CrankCase electric power use or electric heating coil [W]
        var locDefrostPower: Float64 = 0.0
        if changeOverByPassVAV.heatCoilType == HVAC.CoilType.HeatingDXSingleSpeed:
            HeatingPower = state.dataHVACGlobal.DXElecHeatingPower
            locDefrostPower = state.dataHVACGlobal.DefrostElecPower
        elif changeOverByPassVAV.heatCoilType == HVAC.CoilType.HeatingDXVariableSpeed:
            HeatingPower = state.dataHVACGlobal.DXElecHeatingPower
            locDefrostPower = state.dataHVACGlobal.DefrostElecPower
        elif changeOverByPassVAV.heatCoilType == HVAC.CoilType.HeatingElectric:
            HeatingPower = state.dataHVACGlobal.ElecHeatingCoilPower
        else:
            HeatingPower = 0.0
        var locFanElecPower: Float64 = state.dataFans.fans[changeOverByPassVAV.FanIndex].totalPower
        changeOverByPassVAV.ElecPower = locFanElecPower + state.dataHVACGlobal.DXElecCoolingPower + HeatingPower + locDefrostPower

    def GetCBVAV(inout state: EnergyPlusData):
        var routineName: StringLiteral = "GetCBVAV"
        var getUnitaryHeatCoolVAVChangeoverBypass: StringLiteral = "GetUnitaryHeatCool:VAVChangeoverBypass"
        var NumAlphas: Int  # Number of Alphas for each GetObjectItem call
        var NumNumbers: Int  # Number of Numbers for each GetObjectItem call
        var IOStatus: Int  # Used in GetObjectItem
        var CompSetFanInlet: String  # Used in SetUpCompSets call
        var CompSetFanOutlet: String  # Used in SetUpCompSets call
        var ErrorsFound: Bool = False  # Set to true if errors in input, fatal at end of routine
        var DXErrorsFound: Bool = False  # Set to true if errors in get coil input
        var OANodeNums: Array1D[Int] = Array1D[Int](4)  # Node numbers of OA mixer (OA, EA, RA, MA)
        var DXCoilErrFlag: Bool  # used in warning messages
        var Alphas: Array1D[String] = Array1D[String](20, "")
        var Numbers: Array1D[Float64] = Array1D[Float64](9, 0.0)
        var cAlphaFields: Array1D[String] = Array1D[String](20, "")
        var cNumericFields: Array1D[String] = Array1D[String](9, "")
        var lAlphaBlanks: Array1D[Bool] = Array1D[Bool](20, True)
        var lNumericBlanks: Array1D[Bool] = Array1D[Bool](9, True)
        var CurrentModuleObject: String = "AirLoopHVAC:UnitaryHeatCool:VAVChangeoverBypass"
        var NumCBVAV: Int = state.dataHVACUnitaryBypassVAV.NumCBVAV = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
        state.dataHVACUnitaryBypassVAV.CBVAV.resize(NumCBVAV)
        state.dataHVACUnitaryBypassVAV.CheckEquipName.dimension(NumCBVAV, True)
        for CBVAVNum in range(1, NumCBVAV + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                   CurrentModuleObject,
                                                                   CBVAVNum,
                                                                   Alphas,
                                                                   NumAlphas,
                                                                   Numbers,
                                                                   NumNumbers,
                                                                   IOStatus,
                                                                   lNumericBlanks,
                                                                   lAlphaBlanks,
                                                                   cAlphaFields,
                                                                   cNumericFields)
            var cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum]
            cbvav.Name = Alphas[1]
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, cbvav.Name)
            cbvav.UnitType = CurrentModuleObject
            if lAlphaBlanks[2]:
                cbvav.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (cbvav.availSched = Sched.GetSchedule(state, Alphas[2])) == None:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[2], Alphas[2])
                ErrorsFound = True
            cbvav.MaxCoolAirVolFlow = Numbers[1]
            if cbvav.MaxCoolAirVolFlow <= 0.0 and cbvav.MaxCoolAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, "{} illegal {} = {:.7f}".format(CurrentModuleObject, cNumericFields[1], Numbers[1]))
                ShowContinueError(state, "{} must be greater than zero.".format(cNumericFields[1]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            cbvav.MaxHeatAirVolFlow = Numbers[2]
            if cbvav.MaxHeatAirVolFlow <= 0.0 and cbvav.MaxHeatAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, "{} illegal {} = {:.7f}".format(CurrentModuleObject, cNumericFields[2], Numbers[2]))
                ShowContinueError(state, "{} must be greater than zero.".format(cNumericFields[2]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            cbvav.MaxNoCoolHeatAirVolFlow = Numbers[3]
            if cbvav.MaxNoCoolHeatAirVolFlow < 0.0 and cbvav.MaxNoCoolHeatAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, "{} illegal {} = {:.7f}".format(CurrentModuleObject, cNumericFields[3], Numbers[3]))
                ShowContinueError(state, "{} must be greater than or equal to zero.".format(cNumericFields[3]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            cbvav.CoolOutAirVolFlow = Numbers[4]
            if cbvav.CoolOutAirVolFlow < 0.0 and cbvav.CoolOutAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, "{} illegal {} = {:.7f}".format(CurrentModuleObject, cNumericFields[4], Numbers[4]))
                ShowContinueError(state, "{} must be greater than or equal to zero.".format(cNumericFields[4]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            cbvav.HeatOutAirVolFlow = Numbers[5]
            if cbvav.HeatOutAirVolFlow < 0.0 and cbvav.HeatOutAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, "{} illegal {} = {:.7f}".format(CurrentModuleObject, cNumericFields[5], Numbers[5]))
                ShowContinueError(state, "{} must be greater than or equal to zero.".format(cNumericFields[5]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            cbvav.NoCoolHeatOutAirVolFlow = Numbers[6]
            if cbvav.NoCoolHeatOutAirVolFlow < 0.0 and cbvav.NoCoolHeatOutAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, "{} illegal {} = {:.7f}".format(CurrentModuleObject, cNumericFields[6], Numbers[6]))
                ShowContinueError(state, "{} must be greater than or equal to zero.".format(cNumericFields[6]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            cbvav.outAirSched = Sched.GetSchedule(state, Alphas[3])
            if cbvav.outAirSched != None:
                if not cbvav.outAirSched.checkMinMaxVals(state, Clusive.In, 0.0, Clusive.In, 1.0):
                    Sched.ShowSevereBadMinMax(state, eoh, cAlphaFields[3], Alphas[3], Clusive.In, 0.0, Clusive.In, 1.0)
                    ErrorsFound = True
            cbvav.AirInNode = Node.GetOnlySingleNode(state,
                                                     Alphas[4],
                                                     ErrorsFound,
                                                     Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                     Alphas[1],
                                                     Node.FluidType.Air,
                                                     Node.ConnectionType.Inlet,
                                                     Node.CompFluidStream.Primary,
                                                     Node.ObjectIsParent)
            var MixerInletNodeName: String = Alphas[5]
            var SplitterOutletNodeName: String = Alphas[6]
            cbvav.AirOutNode = Node.GetOnlySingleNode(state,
                                                      Alphas[7],
                                                      ErrorsFound,
                                                      Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                      Alphas[1],
                                                      Node.FluidType.Air,
                                                      Node.ConnectionType.Outlet,
                                                      Node.CompFluidStream.Primary,
                                                      Node.ObjectIsParent)
            cbvav.SplitterOutletAirNode = Node.GetOnlySingleNode(state,
                                                                 SplitterOutletNodeName,
                                                                 ErrorsFound,
                                                                 Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                                 Alphas[1],
                                                                 Node.FluidType.Air,
                                                                 Node.ConnectionType.Internal,
                                                                 Node.CompFluidStream.Primary,
                                                                 Node.ObjectIsParent)
            if NumAlphas > 19 and not lAlphaBlanks[20]:
                cbvav.PlenumMixerInletAirNode = Node.GetOnlySingleNode(state,
                                                                       Alphas[20],
                                                                       ErrorsFound,
                                                                       Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                                       Alphas[1],
                                                                       Node.FluidType.Air,
                                                                       Node.ConnectionType.Internal,
                                                                       Node.CompFluidStream.Primary,
                                                                       Node.ObjectIsParent)
                cbvav.PlenumMixerInletAirNode = Node.GetOnlySingleNode(state,
                                                                       Alphas[20],
                                                                       ErrorsFound,
                                                                       Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                                       Alphas[1] + "_PlenumMixerInlet",
                                                                       Node.FluidType.Air,
                                                                       Node.ConnectionType.Outlet,
                                                                       Node.CompFluidStream.Primary,
                                                                       Node.ObjectIsParent)
            cbvav.plenumIndex = ZonePlenum.getReturnPlenumIndexFromInletNode(state, cbvav.PlenumMixerInletAirNode)
            cbvav.mixerIndex = MixerComponent.getZoneMixerIndexFromInletNode(state, cbvav.PlenumMixerInletAirNode)
            if cbvav.plenumIndex > 0 and cbvav.mixerIndex > 0:
                ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                ShowContinueError(state, "Illegal connection for {} = \"{}\".".format(cAlphaFields[20], Alphas[20]))
                ShowContinueError(state, "{} cannot be connected to both an AirloopHVAC:ReturnPlenum and an AirloopHVAC:ZoneMixer.".format(cAlphaFields[20]))
                ErrorsFound = True
            elif cbvav.plenumIndex == 0 and cbvav.mixerIndex == 0 and cbvav.PlenumMixerInletAirNode > 0:
                ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                ShowContinueError(state, "Illegal connection for {} = \"{}\".".format(cAlphaFields[20], Alphas[20]))
                ShowContinueError(state, "{} must be connected to an AirloopHVAC:ReturnPlenum or AirloopHVAC:ZoneMixer. No connection found.".format(cAlphaFields[20]))
                ErrorsFound = True
            cbvav.MixerInletAirNode = Node.GetOnlySingleNode(state,
                                                             MixerInletNodeName,
                                                             ErrorsFound,
                                                             Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                             Alphas[1],
                                                             Node.FluidType.Air,
                                                             Node.ConnectionType.Internal,
                                                             Node.CompFluidStream.Primary,
                                                             Node.ObjectIsParent)
            cbvav.MixerInletAirNode = Node.GetOnlySingleNode(state,
                                                             MixerInletNodeName,
                                                             ErrorsFound,
                                                             Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                             Alphas[1] + "_Mixer",
                                                             Node.FluidType.Air,
                                                             Node.ConnectionType.Outlet,
                                                             Node.CompFluidStream.Primary,
                                                             Node.ObjectIsParent)
            cbvav.SplitterOutletAirNode = Node.GetOnlySingleNode(state,
                                                                 SplitterOutletNodeName,
                                                                 ErrorsFound,
                                                                 Node.ConnectionObjectType.AirLoopHVACUnitaryHeatCoolVAVChangeoverBypass,
                                                                 Alphas[1] + "_Splitter",
                                                                 Node.FluidType.Air,
                                                                 Node.ConnectionType.Inlet,
                                                                 Node.CompFluidStream.Primary,
                                                                 Node.ObjectIsParent)
            cbvav.OAMixType = Alphas[8]
            cbvav.OAMixName = Alphas[9]
            var errFlag: Bool = False
            ValidateComponent(state, cbvav.OAMixType, cbvav.OAMixName, errFlag, CurrentModuleObject)
            if errFlag:
                ShowContinueError(state, "specified in {} = \"{}\".".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            else:
                OANodeNums = MixedAir.GetOAMixerNodeNumbers(state, cbvav.OAMixName, errFlag)
                if errFlag:
                    ShowContinueError(state, "that was specified in {} = {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "..OutdoorAir:Mixer is required. Enter an OutdoorAir:Mixer object with this name.")
                    ErrorsFound = True
                else:
                    cbvav.MixerOutsideAirNode = OANodeNums[1]
                    cbvav.MixerReliefAirNode = OANodeNums[2]
                    cbvav.MixerMixedAirNode = OANodeNums[4]
            if cbvav.MixerInletAirNode != OANodeNums[3]:
                ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                ShowContinueError(state, "Illegal {} = {}.".format(cAlphaFields[5], MixerInletNodeName))
                ShowContinueError(state, "{} must be the same as the return air stream node specified in the OutdoorAir:Mixer object.".format(cAlphaFields[5]))
                ErrorsFound = True
            if cbvav.MixerInletAirNode == cbvav.AirInNode:
                ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                ShowContinueError(state, "Illegal {} = {}.".format(cAlphaFields[5], MixerInletNodeName))
                ShowContinueError(state, "{} must be different than the {}.".format(cAlphaFields[5], cAlphaFields[4]))
                ErrorsFound = True
            if cbvav.SplitterOutletAirNode == cbvav.AirOutNode:
                ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                ShowContinueError(state, "Illegal {} = {}.".format(cAlphaFields[6], SplitterOutletNodeName))
                ShowContinueError(state, "{} must be different than the {}.".format(cAlphaFields[6], cAlphaFields[7]))
                ErrorsFound = True
            cbvav.fanType = HVAC.FanType(getEnumValue(HVAC.fanTypeNamesUC, Alphas[10]))
            assert cbvav.fanType != HVAC.FanType.Invalid
            cbvav.FanName = Alphas[11]
            var fanOutletNode: Int = 0
            if (cbvav.FanIndex = Fans.GetFanIndex(state, cbvav.FanName)) == 0:
                ShowSevereItemNotFound(state, eoh, cAlphaFields[11], cbvav.FanName)
                ErrorsFound = True
                cbvav.FanVolFlow = 9999.0
            else:
                var fan = state.dataFans.fans[cbvav.FanIndex]
                cbvav.FanInletNodeNum = fan.inletNodeNum
                fanOutletNode = fan.outletNodeNum
                cbvav.FanVolFlow = fan.maxAirFlowRate
            cbvav.fanPlace = HVAC.FanPlace(getEnumValue(HVAC.fanPlaceNamesUC, Alphas[12]))
            if cbvav.fanPlace == HVAC.FanPlace.DrawThru:
                if cbvav.SplitterOutletAirNode != fanOutletNode:
                    ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "Illegal {} = {}.".format(cAlphaFields[6], SplitterOutletNodeName))
                    ShowContinueError(state, "{} must be the same as the fan outlet node specified in {} = {}: {} when draw through {} is selected.".format(
                        cAlphaFields[6], cAlphaFields[10], Alphas[10], cbvav.FanName, cAlphaFields[11]))
                    ErrorsFound = True
            if cbvav.FanVolFlow != DataSizing.AutoSize:
                if cbvav.FanVolFlow < cbvav.MaxCoolAirVolFlow and cbvav.MaxCoolAirVolFlow != DataSizing.AutoSize:
                    ShowWarningError(state,
                        "{} - air flow rate = {:.7f} in {} = {} is less than the ".format(
                            CurrentModuleObject, cbvav.FanVolFlow, cAlphaFields[11], cbvav.FanName) +
                        cNumericFields[1])
                    ShowContinueError(state, " {} is reset to the fan flow rate and the simulation continues.".format(cNumericFields[1]))
                    ShowContinueError(state, " Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                    cbvav.MaxCoolAirVolFlow = cbvav.FanVolFlow
                if cbvav.FanVolFlow < cbvav.MaxHeatAirVolFlow and cbvav.MaxHeatAirVolFlow != DataSizing.AutoSize:
                    ShowWarningError(state,
                        "{} - air flow rate = {:.7f} in {} = {} is less than the ".format(
                            CurrentModuleObject, cbvav.FanVolFlow, cAlphaFields[11], cbvav.FanName) +
                        cNumericFields[2])
                    ShowContinueError(state, " {} is reset to the fan flow rate and the simulation continues.".format(cNumericFields[2]))
                    ShowContinueError(state, " Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                    cbvav.MaxHeatAirVolFlow = cbvav.FanVolFlow
            if cbvav.CoolOutAirVolFlow > cbvav.MaxCoolAirVolFlow and cbvav.CoolOutAirVolFlow != DataSizing.AutoSize and cbvav.MaxCoolAirVolFlow != DataSizing.AutoSize:
                ShowWarningError(state, "{}: {} cannot be greater than {}".format(CurrentModuleObject, cNumericFields[4], cNumericFields[1]))
                ShowContinueError(state, " {} is reset to the fan flow rate and the simulation continues.".format(cNumericFields[4]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                cbvav.CoolOutAirVolFlow = cbvav.FanVolFlow
            if cbvav.HeatOutAirVolFlow > cbvav.MaxHeatAirVolFlow and cbvav.HeatOutAirVolFlow != DataSizing.AutoSize and cbvav.MaxHeatAirVolFlow != DataSizing.AutoSize:
                ShowWarningError(state, "{}: {} cannot be greater than {}".format(CurrentModuleObject, cNumericFields[5], cNumericFields[2]))
                ShowContinueError(state, " {} is reset to the fan flow rate and the simulation continues.".format(cNumericFields[5]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                cbvav.HeatOutAirVolFlow = cbvav.FanVolFlow
            var thisCoolCoilType: String = Alphas[14]
            cbvav.coolCoilType = HVAC.CoilType(getEnumValue(HVAC.coilTypeNamesUC, thisCoolCoilType))
            cbvav.DXCoolCoilName = Alphas[15]
            if cbvav.coolCoilType == HVAC.CoilType.CoolingDXSingleSpeed:
                DXCoilErrFlag = False
                DXCoils.GetDXCoilIndex(state, cbvav.DXCoolCoilName, cbvav.DXCoolCoilIndexNum, DXCoilErrFlag, thisCoolCoilType)
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.DXCoilInletNode = state.dataDXCoils.DXCoil[cbvav.DXCoolCoilIndexNum].AirInNode
                    cbvav.DXCoilOutletNode = state.dataDXCoils.DXCoil[cbvav.DXCoolCoilIndexNum].AirOutNode
                    cbvav.CondenserNodeNum = state.dataDXCoils.DXCoil[cbvav.DXCoolCoilIndexNum].CondenserInletNodeNum[1]
            elif cbvav.coolCoilType == HVAC.CoilType.CoolingDXVariableSpeed:
                DXCoilErrFlag = False
                cbvav.DXCoolCoilIndexNum = VariableSpeedCoils.GetCoilIndexVariableSpeed(state, thisCoolCoilType, cbvav.DXCoolCoilName, DXCoilErrFlag)
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.DXCoilInletNode = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXCoolCoilIndexNum].AirInletNodeNum
                    cbvav.DXCoilOutletNode = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXCoolCoilIndexNum].AirOutletNodeNum
                    cbvav.CondenserNodeNum = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXCoolCoilIndexNum].CondenserInletNodeNum
            elif cbvav.coolCoilType == HVAC.CoilType.CoolingDXHXAssisted:
                DXCoilErrFlag = False
                var ActualCoolCoilType: HVAC.CoilType = HVACHXAssistedCoolingCoil.GetCoilObjectTypeNum(state, thisCoolCoilType, cbvav.DXCoolCoilName, DXErrorsFound)
                if DXErrorsFound:
                    ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "CoilSystem:Cooling:DX:HeatExchangerAssisted \"{}\" not found.".format(cbvav.DXCoolCoilName))
                    ErrorsFound = True
                else:
                    if ActualCoolCoilType == HVAC.CoilType.CoolingDXSingleSpeed:
                        DXCoils.GetDXCoilIndex(state,
                            HVACHXAssistedCoolingCoil.GetHXDXCoilName(state, thisCoolCoilType, cbvav.DXCoolCoilName, DXCoilErrFlag),
                            cbvav.DXCoolCoilIndexNum,
                            DXCoilErrFlag,
                            "Coil:Cooling:DX:SingleSpeed")
                        if DXCoilErrFlag:
                            ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                            ErrorsFound = True
                        else:
                            cbvav.DXCoilInletNode = HVACHXAssistedCoolingCoil.GetCoilInletNode(state, thisCoolCoilType, cbvav.DXCoolCoilName, DXErrorsFound)
                            cbvav.DXCoilOutletNode = HVACHXAssistedCoolingCoil.GetCoilOutletNode(state, thisCoolCoilType, cbvav.DXCoolCoilName, DXErrorsFound)
                            cbvav.CondenserNodeNum = state.dataDXCoils.DXCoil[cbvav.DXCoolCoilIndexNum].CondenserInletNodeNum[1]
                    elif ActualCoolCoilType == HVAC.CoilType.CoolingDXVariableSpeed:
                        cbvav.DXCoolCoilIndexNum = VariableSpeedCoils.GetCoilIndexVariableSpeed(state,
                            "Coil:Cooling:DX:VariableSpeed",
                            HVACHXAssistedCoolingCoil.GetHXDXCoilName(state, thisCoolCoilType, cbvav.DXCoolCoilName, DXCoilErrFlag),
                            DXCoilErrFlag)
                        if DXCoilErrFlag:
                            ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                            ErrorsFound = True
                        else:
                            cbvav.DXCoilInletNode = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXCoolCoilIndexNum].AirInletNodeNum
                            cbvav.DXCoilOutletNode = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXCoolCoilIndexNum].AirOutletNodeNum
                            cbvav.CondenserNodeNum = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXCoolCoilIndexNum].CondenserInletNodeNum
                    elif ActualCoolCoilType == HVAC.CoilType.CoolingDX:
                        cbvav.DXCoolCoilIndexNum = CoilCoolingDX.factory(state, cbvav.DXCoolCoilName)
                        if cbvav.DXCoolCoilIndexNum == -1:
                            ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                            ErrorsFound = True
                        else:
                            var newCoil = state.dataCoilCoolingDX.coilCoolingDXs[cbvav.DXCoolCoilIndexNum]
                            cbvav.DXCoilInletNode = newCoil.evapInletNodeIndex
                            cbvav.DXCoilOutletNode = newCoil.evapOutletNodeIndex
                            cbvav.CondenserNodeNum = newCoil.condInletNodeIndex
            elif cbvav.coolCoilType == HVAC.CoilType.CoolingDXTwoStageWHumControl:
                DXCoilErrFlag = False
                DXCoils.GetDXCoilIndex(state, cbvav.DXCoolCoilName, cbvav.DXCoolCoilIndexNum, DXCoilErrFlag, thisCoolCoilType)
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.DXCoilInletNode = state.dataDXCoils.DXCoil[cbvav.DXCoolCoilIndexNum].AirInNode
                    cbvav.DXCoilOutletNode = state.dataDXCoils.DXCoil[cbvav.DXCoolCoilIndexNum].AirOutNode
                    cbvav.CondenserNodeNum = state.dataDXCoils.DXCoil[cbvav.DXCoolCoilIndexNum].CondenserInletNodeNum[1]
            cbvav.fanOpModeSched = Sched.GetSchedule(state, Alphas[13])
            if cbvav.fanOpModeSched != None:
                if not cbvav.fanOpModeSched.checkMinMaxVals(state, Clusive.In, 0.0, Clusive.In, 1.0):
                    Sched.ShowSevereBadMinMax(state, eoh, cAlphaFields[13], Alphas[13], Clusive.In, 0.0, Clusive.In, 1.0)
                    ShowContinueError(state, "A value of 0 represents cycling fan mode, any other value up to 1 represents constant fan mode.")
                    ErrorsFound = True
                if not cbvav.fanOpModeSched.checkMinMaxVals(state, Clusive.In, 0.0, Clusive.In, 0.0):  # Autodesk:Note Range is 0 to 0?
                    cbvav.AirFlowControl = AirFlowCtrlMode.UseCompressorOnFlow if cbvav.MaxNoCoolHeatAirVolFlow == 0.0 else AirFlowCtrlMode.UseCompressorOffFlow
            else:
                if not lAlphaBlanks[13]:
                    ShowWarningError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "{} = {} not found. Supply air fan operating mode set to constant operation and simulation continues.".format(
                        cAlphaFields[13], Alphas[13]))
                cbvav.fanOp = HVAC.FanOp.Continuous
                if cbvav.MaxNoCoolHeatAirVolFlow == 0.0:
                    cbvav.AirFlowControl = AirFlowCtrlMode.UseCompressorOnFlow
                else:
                    cbvav.AirFlowControl = AirFlowCtrlMode.UseCompressorOffFlow
            if cbvav.FanVolFlow != DataSizing.AutoSize:
                if cbvav.FanVolFlow < cbvav.MaxNoCoolHeatAirVolFlow and cbvav.MaxNoCoolHeatAirVolFlow != DataSizing.AutoSize and cbvav.MaxNoCoolHeatAirVolFlow != 0.0:
                    ShowWarningError(state,
                        "{} - air flow rate = {:.7f} in {} = {} is less than ".format(
                            CurrentModuleObject, cbvav.FanVolFlow, cAlphaFields[11], cbvav.FanName) +
                        cNumericFields[3])
                    ShowContinueError(state, " {} is reset to the fan flow rate and the simulation continues.".format(cNumericFields[3]))
                    ShowContinueError(state, " Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                    cbvav.MaxNoCoolHeatAirVolFlow = cbvav.FanVolFlow
            if cbvav.NoCoolHeatOutAirVolFlow > cbvav.MaxNoCoolHeatAirVolFlow and cbvav.NoCoolHeatOutAirVolFlow != DataSizing.AutoSize and cbvav.MaxNoCoolHeatAirVolFlow != DataSizing.AutoSize and cbvav.MaxNoCoolHeatAirVolFlow != 0.0:
                ShowWarningError(state, "{}: {} cannot be greater than {}".format(CurrentModuleObject, cNumericFields[6], cNumericFields[3]))
                ShowContinueError(state, " {} is reset to the fan flow rate and the simulation continues.".format(cNumericFields[6]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                cbvav.NoCoolHeatOutAirVolFlow = cbvav.FanVolFlow
            var thisHeatCoilType: String = Alphas[16]
            cbvav.heatCoilType = HVAC.CoilType(getEnumValue(HVAC.coilTypeNamesUC, thisHeatCoilType))
            cbvav.HeatCoilName = Alphas[17]
            DXCoilErrFlag = False
            if cbvav.heatCoilType == HVAC.CoilType.HeatingDXSingleSpeed:
                DXCoils.GetDXCoilIndex(state, cbvav.HeatCoilName, cbvav.DXHeatCoilIndexNum, DXCoilErrFlag, HVAC.coilTypeNamesUC[Int(cbvav.heatCoilType)])
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.MinOATCompressor = state.dataDXCoils.DXCoil[cbvav.DXHeatCoilIndexNum].MinOATCompressor
                    cbvav.HeatingCoilInletNode = state.dataDXCoils.DXCoil[cbvav.DXHeatCoilIndexNum].AirInNode
                    cbvav.HeatingCoilOutletNode = state.dataDXCoils.DXCoil[cbvav.DXHeatCoilIndexNum].AirOutNode
            elif cbvav.heatCoilType == HVAC.CoilType.HeatingDXVariableSpeed:
                cbvav.DXHeatCoilIndexNum = VariableSpeedCoils.GetCoilIndexVariableSpeed(state,
                    HVAC.coilTypeNames[Int(cbvav.heatCoilType)], cbvav.HeatCoilName, DXCoilErrFlag)
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.MinOATCompressor = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXHeatCoilIndexNum].MinOATCompressor
                    cbvav.HeatingCoilInletNode = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXHeatCoilIndexNum].AirInletNodeNum
                    cbvav.HeatingCoilOutletNode = state.dataVariableSpeedCoils.VarSpeedCoil[cbvav.DXHeatCoilIndexNum].AirOutletNodeNum
            elif cbvav.heatCoilType == HVAC.CoilType.HeatingGasOrOtherFuel or cbvav.heatCoilType == HVAC.CoilType.HeatingElectric:
                HeatingCoils.GetCoilIndex(state, cbvav.HeatCoilName, cbvav.DXHeatCoilIndexNum, DXCoilErrFlag)
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.MinOATCompressor = -999.9
                    cbvav.HeatingCoilInletNode = state.dataHeatingCoils.HeatingCoil[cbvav.DXHeatCoilIndexNum].AirInletNodeNum
                    cbvav.HeatingCoilOutletNode = state.dataHeatingCoils.HeatingCoil[cbvav.DXHeatCoilIndexNum].AirOutletNodeNum
            elif cbvav.heatCoilType == HVAC.CoilType.HeatingWater:
                cbvav.DXHeatCoilIndexNum = WaterCoils.GetWaterCoilIndex(state, "COIL:HEATING:WATER", cbvav.HeatCoilName, DXCoilErrFlag)
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.CoilControlNode = state.dataWaterCoils.WaterCoil[cbvav.DXHeatCoilIndexNum].WaterInletNodeNum
                    cbvav.MaxHeatCoilFluidFlow = state.dataWaterCoils.WaterCoil[cbvav.DXHeatCoilIndexNum].MaxWaterVolFlowRate
                    cbvav.HeatingCoilInletNode = state.dataWaterCoils.WaterCoil[cbvav.DXHeatCoilIndexNum].AirInletNodeNum
                    cbvav.HeatingCoilOutletNode = state.dataWaterCoils.WaterCoil[cbvav.DXHeatCoilIndexNum].AirOutletNodeNum
            elif cbvav.heatCoilType == HVAC.CoilType.HeatingSteam:
                cbvav.HeatCoilIndex = SteamCoils.GetSteamCoilIndex(state, "COIL:HEATING:STEAM", cbvav.HeatCoilName, DXCoilErrFlag)
                if DXCoilErrFlag:
                    ShowContinueError(state, "...occurs in {} \"{}\"".format(cbvav.UnitType, cbvav.Name))
                    ErrorsFound = True
                else:
                    cbvav.HeatingCoilInletNode = state.dataSteamCoils.SteamCoil[cbvav.HeatCoilIndex].AirInletNodeNum
                    cbvav.HeatingCoilOutletNode = state.dataSteamCoils.SteamCoil[cbvav.HeatCoilIndex].AirOutletNodeNum
                    cbvav.CoilControlNode = state.dataSteamCoils.SteamCoil[cbvav.HeatCoilIndex].SteamInletNodeNum
                    cbvav.MaxHeatCoilFluidFlow = state.dataSteamCoils.SteamCoil[cbvav.HeatCoilIndex].MaxSteamVolFlowRate
                    var SteamDensity: Float64 = Fluid.GetSteam(state).getSatDensity(state, state.dataHVACUnitaryBypassVAV.TempSteamIn, 1.0, getUnitaryHeatCoolVAVChangeoverBypass)
                    if cbvav.MaxHeatCoilFluidFlow > 0.0:
                        cbvav.MaxHeatCoilFluidFlow = cbvav.MaxHeatCoilFluidFlow * SteamDensity
            if cbvav.DXCoilOutletNode != cbvav.HeatingCoilInletNode:
                ShowSevereError(state, "{} illegal coil placement. Cooling coil must be upstream of heating coil.".format(CurrentModuleObject))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ErrorsFound = True
            if cbvav.fanPlace == HVAC.FanPlace.BlowThru:
                if cbvav.SplitterOutletAirNode != cbvav.HeatingCoilOutletNode:
                    ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "Illegal {} = {}.".format(cAlphaFields[6], SplitterOutletNodeName))
                    ShowContinueError(state, "{} must be the same as the outlet node specified in the heating coil object = {}: {} when blow through {} is selected.".format(
                        cAlphaFields[6], HVAC.coilTypeNamesUC[Int(cbvav.heatCoilType)], cbvav.HeatCoilName, cAlphaFields[12]))
                    ErrorsFound = True
                if cbvav.MixerMixedAirNode != cbvav.FanInletNodeNum:
                    ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "Illegal {}. The fan inlet node name must be the same as the mixed air node specified in the {} = {} when blow through {} is selected.".format(
                        cAlphaFields[11], cAlphaFields[9], cbvav.OAMixName, cAlphaFields[12]))
                    ErrorsFound = True
            if cbvav.fanPlace == HVAC.FanPlace.DrawThru:
                if cbvav.MixerMixedAirNode != cbvav.DXCoilInletNode:
                    ShowSevereError(state, "{}: {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "Illegal cooling coil placement. The cooling coil inlet node name must be the same as the mixed air node specified in the {} = {} when draw through {} is selected.".format(
                        cAlphaFields[9], cbvav.OAMixName, cAlphaFields[12]))
                    ErrorsFound = True
            if Util.SameString(Alphas[18], "CoolingPriority"):
                cbvav.PriorityControl = PriorityCtrlMode.CoolingPriority
            elif Util.SameString(Alphas[18], "HeatingPriority"):
                cbvav.PriorityControl = PriorityCtrlMode.HeatingPriority
            elif Util.SameString(Alphas[18], "ZonePriority"):
                cbvav.PriorityControl = PriorityCtrlMode.ZonePriority
            elif Util.SameString(Alphas[18], "LoadPriority"):
                cbvav.PriorityControl = PriorityCtrlMode.LoadPriority
            else:
                ShowSevereError(state, "{} illegal {} = {}".format(CurrentModuleObject, cAlphaFields[18], Alphas[18]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                ShowContinueError(state, "Valid choices are CoolingPriority, HeatingPriority, ZonePriority or LoadPriority.")
                ErrorsFound = True
            if Numbers[7] > 0.0:
                cbvav.MinLATCooling = Numbers[7]
            else:
                cbvav.MinLATCooling = 10.0
            if Numbers[8] > 0.0:
                cbvav.MaxLATHeating = Numbers[8]
            else:
                cbvav.MaxLATHeating = 50.0
            if cbvav.MinLATCooling > cbvav.MaxLATHeating:
                ShowWarningError(state, "{}: illegal leaving air temperature specified.".format(CurrentModuleObject))
                ShowContinueError(state, "Resetting {} equal to {} and the simulation continues.".format(cNumericFields[7], cNumericFields[8]))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                cbvav.MinLATCooling = cbvav.MaxLATHeating
            if Util.SameString(Alphas[19], "None"):
                cbvav.DehumidControlType = DehumidControl.None
            elif Util.SameString(Alphas[19], ""):
                cbvav.DehumidControlType = DehumidControl.None
            elif Util.SameString(Alphas[19], "Multimode"):
                if cbvav.coolCoilType == HVAC.CoilType.CoolingDXTwoStageWHumControl:
                    cbvav.DehumidControlType = DehumidControl.Multimode
                else:
                    ShowWarningError(state, "Invalid {} = {}".format(cAlphaFields[19], Alphas[19]))
                    ShowContinueError(state, "In {} \"{}\".".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "Valid only with {} = Coil:Cooling:DX:TwoStageWithHumidityControlMode.".format(cAlphaFields[14]))
                    ShowContinueError(state, "Setting {} to \"None\" and the simulation continues.".format(cAlphaFields[19]))
                    cbvav.DehumidControlType = DehumidControl.None
            elif Util.SameString(Alphas[19], "CoolReheat"):
                if cbvav.coolCoilType == HVAC.CoilType.CoolingDXTwoStageWHumControl:
                    cbvav.DehumidControlType = DehumidControl.CoolReheat
                else:
                    ShowWarningError(state, "Invalid {} = {}".format(cAlphaFields[19], Alphas[19]))
                    ShowContinueError(state, "In {} \"{}\".".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, "Valid only with {} = Coil:Cooling:DX:TwoStageWithHumidityControlMode.".format(cAlphaFields[14]))
                    ShowContinueError(state, "Setting {} to \"None\" and the simulation continues.".format(cAlphaFields[19]))
                    cbvav.DehumidControlType = DehumidControl.None
            else:
                ShowSevereError(state, "Invalid {} ={}".format(cAlphaFields[19], Alphas[19]))
                ShowContinueError(state, "In {} \"{}\".".format(CurrentModuleObject, cbvav.Name))
            if NumNumbers > 8:
                cbvav.minModeChangeTime = Numbers[9]
            cbvav.LastMode = HeatingMode
            if cbvav.fanType == HVAC.FanType.OnOff or cbvav.fanType == HVAC.FanType.Constant:
                var fanType2: HVAC.FanType = state.dataFans.fans[cbvav.FanIndex].type
                if cbvav.fanType != fanType2:
                    ShowWarningError(state, "{} has {} = {} which is inconsistent with the fan object.".format(CurrentModuleObject, cAlphaFields[10], Alphas[10]))
                    ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, cbvav.Name))
                    ShowContinueError(state, " The fan object ({}) is actually a valid fan type and the simulation continues.".format(cbvav.FanName))
                    ShowContinueError(state, " Node connections errors may result due to the inconsistent fan type.")
            if cbvav.fanPlace == HVAC.FanPlace.BlowThru:
                CompSetFanInlet = state.dataLoopNodes.NodeID[cbvav.MixerMixedAirNode]
                CompSetFanOutlet = state.dataLoopNodes.NodeID[cbvav.DXCoilInletNode]
            else:
                CompSetFanInlet = state.dataLoopNodes.NodeID[cbvav.HeatingCoilOutletNode]
                CompSetFanOutlet = SplitterOutletNodeName
            var CompSetCoolInlet: String = state.dataLoopNodes.NodeID[cbvav.DXCoilInletNode]
            var CompSetCoolOutlet: String = state.dataLoopNodes.NodeID[cbvav.DXCoilOutletNode]
            Node.SetUpCompSets(state, cbvav.UnitType, cbvav.Name, Alphas[10], cbvav.FanName, CompSetFanInlet, CompSetFanOutlet)
            Node.SetUpCompSets(state, cbvav.UnitType, cbvav.Name,
                HVAC.coilTypeNamesUC[Int(cbvav.coolCoilType)], cbvav.DXCoolCoilName, CompSetCoolInlet, CompSetCoolOutlet)
            Node.SetUpCompSets(state, cbvav.UnitType, cbvav.Name,
                HVAC.coilTypeNamesUC[Int(cbvav.heatCoilType)], cbvav.HeatCoilName,
                state.dataLoopNodes.NodeID[cbvav.HeatingCoilInletNode], state.dataLoopNodes.NodeID[cbvav.HeatingCoilOutletNode])
            Node.SetUpCompSets(state, cbvav.UnitType, cbvav.Name,
                cbvav.OAMixType, cbvav.OAMixName,
                state.dataLoopNodes.NodeID[cbvav.MixerOutsideAirNode], state.dataLoopNodes.NodeID[cbvav.MixerMixedAirNode])
            Node.TestCompSet(state, cbvav.UnitType, cbvav.Name,
                state.dataLoopNodes.NodeID[cbvav.AirInNode], state.dataLoopNodes.NodeID[cbvav.AirOutNode], "Air Nodes")
            for AirLoopNum in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
                for BranchNum in range(1, state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum].NumBranches + 1):
                    for CompNum in range(1, state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum].Branch[BranchNum].TotalComponents + 1):
                        if not Util.SameString(state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum].Branch[BranchNum].Comp[CompNum].Name, cbvav.Name) or not Util.SameString(state.dataAirSystemsData.PrimaryAirSystems[AirLoopNum].Branch[BranchNum].Comp[CompNum].TypeOf, cbvav.UnitType):
                            continue
                        cbvav.AirLoopNumber = AirLoopNum
                        break
            if cbvav.AirLoopNumber > 0:
                cbvav.NumControlledZones = state.dataAirLoop.AirToZoneNodeInfo[cbvav.AirLoopNumber].NumZonesCooled
                cbvav.ControlledZoneNum.allocate(cbvav.NumControlledZones)
                cbvav.ControlledZoneNodeNum.allocate(cbvav.NumControlledZones)
                cbvav.CBVAVBoxOutletNode.allocate(cbvav.NumControlledZones)
                cbvav.ZoneSequenceCoolingNum.allocate(cbvav.NumControlledZones)
                cbvav.ZoneSequenceHeatingNum.allocate(cbvav.NumControlledZones)
                cbvav.ControlledZoneNum = 0
                for AirLoopZoneNum in range(1, state.dataAirLoop.AirToZoneNodeInfo[cbvav.AirLoopNumber].NumZonesCooled + 1):
                    cbvav.ControlledZoneNum[AirLoopZoneNum] = state.dataAirLoop.AirToZoneNodeInfo[cbvav.AirLoopNumber].CoolCtrlZoneNums[AirLoopZoneNum]
                    if cbvav.ControlledZoneNum[AirLoopZoneNum] > 0:
                        cbvav.ControlledZoneNodeNum[AirLoopZoneNum] = state.dataZoneEquip.ZoneEquipConfig[cbvav.ControlledZoneNum[AirLoopZoneNum]].ZoneNode
                        cbvav.CBVAVBoxOutletNode[AirLoopZoneNum] = state.dataAirLoop.AirToZoneNodeInfo[cbvav.AirLoopNumber].CoolZoneInletNodes[AirLoopZoneNum]
                        var FoundTstatZone: Bool = False
                        for TstatZoneNum in range(1, state.dataZoneCtrls.NumTempControlledZones + 1):
                            if state.dataZoneCtrls.TempControlledZone[TstatZoneNum].ActualZoneNum != cbvav.ControlledZoneNum[AirLoopZoneNum]:
                                continue
                            FoundTstatZone = True
                        if not FoundTstatZone:
                            ShowWarningError(state, "{} \"{}\"".format(CurrentModuleObject, cbvav.Name))
                            ShowContinueError(state, "Thermostat not found in zone = {} and the simulation continues.".format(
                                state.dataZoneEquip.ZoneEquipConfig[cbvav.ControlledZoneNum[AirLoopZoneNum]].ZoneName))
                            ShowContinueError(state, "This zone will not be controlled to a temperature setpoint.")
                        var zoneNum: Int = cbvav.ControlledZoneNum[AirLoopZoneNum]
                        var zoneInlet: Int = cbvav.CBVAVBoxOutletNode[AirLoopZoneNum]
                        if state.dataZoneEquip.ZoneEquipConfig[zoneNum].EquipListIndex > 0:
                            var coolingPriority: Int = 0
                            var heatingPriority: Int = 0
                            state.dataZoneEquip.ZoneEquipList[state.dataZoneEquip.ZoneEquipConfig[zoneNum].EquipListIndex].getPrioritiesForInletNode(state, zoneInlet, coolingPriority, heatingPriority)
                            cbvav.ZoneSequenceCoolingNum[AirLoopZoneNum] = coolingPriority
                            cbvav.ZoneSequenceHeatingNum[AirLoopZoneNum] = heatingPriority
                        if cbvav.ZoneSequenceCoolingNum[AirLoopZoneNum] == 0 or cbvav.ZoneSequenceHeatingNum[AirLoopZoneNum] == 0:
                            ShowSevereError(state,
                                "AirLoopHVAC:UnitaryHeatCool:VAVChangeoverBypass, \"{}\": Airloop air terminal in the zone equipment list for zone = {} not found or is not allowed Zone Equipment Cooling or Heating Sequence = 0.".format(
                                    cbvav.Name, state.dataZoneEquip.ZoneEquipConfig[zoneNum].ZoneName))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, "Controlled Zone node not found.")
                        ErrorsFound = True
            else:

        if ErrorsFound:
            ShowFatalError(state, "GetCBVAV: Errors found in getting {} input.".format(CurrentModuleObject))
        for CBVAVNum in range(1, NumCBVAV + 1):
            var cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum]
            SetupOutputVariable(state, "Unitary System Total Heating Rate", Constant.Units.W, cbvav.TotHeatEnergyRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Total Heating Energy", Constant.Units.J, cbvav.TotHeatEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Total Cooling Rate", Constant.Units.W, cbvav.TotCoolEnergyRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Total Cooling Energy", Constant.Units.J, cbvav.TotCoolEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Sensible Heating Rate", Constant.Units.W, cbvav.SensHeatEnergyRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Sensible Heating Energy", Constant.Units.J, cbvav.SensHeatEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Sensible Cooling Rate", Constant.Units.W, cbvav.SensCoolEnergyRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Sensible Cooling Energy", Constant.Units.J, cbvav.SensCoolEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Latent Heating Rate", Constant.Units.W, cbvav.LatHeatEnergyRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Latent Heating Energy", Constant.Units.J, cbvav.LatHeatEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Latent Cooling Rate", Constant.Units.W, cbvav.LatCoolEnergyRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Latent Cooling Energy", Constant.Units.J, cbvav.LatCoolEnergy,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Electricity Rate", Constant.Units.W, cbvav.ElecPower,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Electricity Energy", Constant.Units.J, cbvav.ElecConsumption,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Fan Part Load Ratio", Constant.Units.None, cbvav.FanPartLoadRatio,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Compressor Part Load Ratio", Constant.Units.None, cbvav.CompPartLoadRatio,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Bypass Air Mass Flow Rate", Constant.Units.kg_s, cbvav.BypassMassFlowRate,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Air Outlet Setpoint Temperature", Constant.Units.C, cbvav.OutletTempSetPoint,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)
            SetupOutputVariable(state, "Unitary System Operating Mode Index", Constant.Units.None, cbvav.HeatCoolMode,
                OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, cbvav.Name)

    def InitCBVAV(
        inout state: EnergyPlusData,
        CBVAVNum: Int,  # Index of the current CBVAV unit being simulated
        FirstHVACIteration: Bool,  # TRUE if first HVAC iteration
        AirLoopNum: Int,  # air loop index
        inout OnOffAirFlowRatio: Float64,  # Ratio of compressor ON airflow to average airflow over timestep
        HXUnitOn: Bool  # flag to enable heat exchanger
    ):
        var RoutineName: StringLiteral = "InitCBVAV"
        var QSensUnitOut: Float64  # Output of CBVAV system with coils off
        var OutsideAirMultiplier: Float64  # Outside air multiplier schedule (=
from Data.BaseData import BaseGlobalStruct
from DataGlobals import *
from EnergyPlus import *
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHeatBalFanSys import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataLoopNode import *
from DataRoomAirModel import *
from DataSurfaces import *
from DataZoneEquipment import *
from InternalHeatGains import *
from OutputProcessor import *
from Psychrometrics import PsyCpAirFnW, PsyRhoAirFnPbTdbW, PsyWFnTdpPb
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from Array import Array1D, Array2D, EPVector
from Array.functions import count, pack
from Fmath import max
from format import format

struct DefineLinearModelNode:
    var AirNodeName: String = ""  # Name of air nodes
    var ClassType: Int = 0  # Type of air nodes (using Int for enum)
    var Height: Float64 = 0.0  # Z coordinates [m] node's Control Vol. center
    var Temp: Float64 = 0.0  # Surface temperature BC
    var SurfMask: Array1D[Bool]  # Limit of 60 surfaces at current sizing

struct DefineSurfaceSettings:
    var Area: Float64 = 0.0  # m2
    var Temp: Float64 = 0.0  # surface temperature BC
    var Hc: Float64 = 0.0  # convective film coeff BC
    var TMeanAir: Float64 = 0.0  # effective near-surface air temp from air model solution

struct DefineZoneData:
    var NumOfSurfs: Int = 0  # number of surfaces in the zone
    var MundtZoneIndex: Int = 0  # index for zones using Mundt model
    var HBsurfaceIndexes: EPVector[Int]  # list of surface indexes in this Mundt model zone

struct MundtSimMgrData(BaseGlobalStruct):
    var FloorSurfSetIDs: Array1D[Int]  # fixed variable for floors
    var TheseSurfIDs: Array1D[Int]  # temporary working variable
    var MundtCeilAirID: Int = 0  # air node index in AirDataManager
    var MundtFootAirID: Int = 0  # air node index in AirDataManager
    var SupplyNodeID: Int = 0  # air node index in AirDataManager
    var TstatNodeID: Int = 0  # air node index in AirDataManager
    var ReturnNodeID: Int = 0  # air node index in AirDataManager
    var NumRoomNodes: Int = 0  # number of nodes connected to walls
    var NumFloorSurfs: Int = 0  # total number of surfaces for floor
    var RoomNodeIDs: Array1D[Int]  # ids of the first NumRoomNode Air Nodes
    var ID1dSurf: Array1D[Int]  # numbers used to identify surfaces
    var MundtZoneNum: Int = 0  # index of zones using Mundt model
    var ZoneHeight: Float64 = 0.0  # zone height
    var ZoneFloorArea: Float64 = 0.0  # zone floor area
    var QventCool: Float64 = 0.0  # heat gain due to ventilation
    var ConvIntGain: Float64 = 0.0  # heat gain due to internal gains
    var SupplyAirTemp: Float64 = 0.0  # supply air temperature
    var SupplyAirVolumeRate: Float64 = 0.0  # supply air volume flowrate
    var ZoneAirDensity: Float64 = 0.0  # zone air density
    var QsysCoolTot: Float64 = 0.0  # zone sensible cooling load
    var ZoneData: Array1D[DefineZoneData]  # zone data
    var LineNode: Array2D[DefineLinearModelNode]  # air nodes
    var MundtAirSurf: Array2D[DefineSurfaceSettings]  # surfaces
    var FloorSurf: Array1D[DefineSurfaceSettings]  # floor

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.FloorSurfSetIDs.clear()  # fixed variable for floors
        self.TheseSurfIDs.clear()  # temporary working variable
        self.MundtCeilAirID = 0  # air node index in AirDataManager
        self.MundtFootAirID = 0  # air node index in AirDataManager
        self.SupplyNodeID = 0  # air node index in AirDataManager
        self.TstatNodeID = 0  # air node index in AirDataManager
        self.ReturnNodeID = 0  # air node index in AirDataManager
        self.NumRoomNodes = 0  # number of nodes connected to walls
        self.NumFloorSurfs = 0  # total number of surfaces for floor
        self.RoomNodeIDs.clear()  # ids of the first NumRoomNode Air Nodes
        self.ID1dSurf.clear()  # numbers used to identify surfaces
        self.MundtZoneNum = 0  # index of zones using Mundt model
        self.ZoneHeight = 0.0  # zone height
        self.ZoneFloorArea = 0.0  # zone floor area
        self.QventCool = 0.0  # heat gain due to ventilation
        self.ConvIntGain = 0.0  # heat gain due to internal gains
        self.SupplyAirTemp = 0.0  # supply air temperature
        self.SupplyAirVolumeRate = 0.0  # supply air volume flowrate
        self.ZoneAirDensity = 0.0  # zone air density
        self.QsysCoolTot = 0.0  # zone sensible cooling load
        self.ZoneData.clear()  # zone data
        self.LineNode.clear()  # air nodes
        self.MundtAirSurf.clear()  # surfaces
        self.FloorSurf.clear()  # floor

def ManageDispVent1Node(inout state: EnergyPlusData, ZoneNum: Int):
    if state.dataHeatBal.MundtFirstTimeFlag:
        InitDispVent1Node(state)
        state.dataHeatBal.MundtFirstTimeFlag = False
    state.dataMundtSimMgr.MundtZoneNum = state.dataMundtSimMgr.ZoneData[ZoneNum - 1].MundtZoneIndex
    GetSurfHBDataForDispVent1Node(state, ZoneNum)
    if (state.dataMundtSimMgr.SupplyAirVolumeRate > 0.0001) and (state.dataMundtSimMgr.QsysCoolTot > 0.0001):
        var ErrorsFound: Bool = False
        SetupDispVent1Node(state, ZoneNum, ErrorsFound)
        if ErrorsFound:
            ShowFatalError(state, "ManageMundtModel: Errors in setting up Mundt Model. Preceding condition(s) cause termination.")
        CalcDispVent1Node(state, ZoneNum)
    SetSurfHBDataForDispVent1Node(state, ZoneNum)

def InitDispVent1Node(inout state: EnergyPlusData):
    var NodeNum: Int  # index for air nodes
    var ZoneIndex: Int  # index for zones
    var NumOfAirNodes: Int  # total number of nodes in each zone
    var NumOfMundtZones: Int  # number of zones using the Mundt model
    var MundtZoneIndex: Int  # index for zones using the Mundt model
    var MaxNumOfSurfs: Int  # maximum of number of surfaces
    var MaxNumOfFloorSurfs: Int  # maximum of number of surfaces
    var MaxNumOfAirNodes: Int  # maximum of number of air nodes
    var MaxNumOfRoomNodes: Int  # maximum of number of nodes connected to walls
    var RoomNodesCount: Int  # number of nodes connected to walls
    var FloorSurfCount: Int  # number of nodes connected to walls
    var AirNodeBeginNum: Int  # index number of the first air node for this zone
    var AirNodeNum: Int  # index for air nodes
    var AirNodeFoundFlag: Bool  # flag used for error check
    var ErrorsFound: Bool  # true if errors found in init
    state.dataMundtSimMgr.ZoneData.allocate(state.dataGlobal.NumOfZones)
    for e in range(state.dataMundtSimMgr.ZoneData.size()):
        state.dataMundtSimMgr.ZoneData[e].NumOfSurfs = 0
        state.dataMundtSimMgr.ZoneData[e].MundtZoneIndex = 0
    NumOfMundtZones = 0
    MaxNumOfSurfs = 0
    MaxNumOfFloorSurfs = 0
    MaxNumOfAirNodes = 0
    MaxNumOfRoomNodes = 0
    ErrorsFound = False
    for ZoneIndex in range(1, state.dataGlobal.NumOfZones + 1):
        var thisZone = state.dataHeatBal.Zone[ZoneIndex - 1]
        if state.dataRoomAir.AirModel[ZoneIndex - 1].AirModel == 2:  # DispVent1Node
            NumOfMundtZones += 1
            var NumOfSurfs: Int = 0
            for spaceNum in thisZone.spaceIndexes:
                var thisSpace = state.dataHeatBal.space[spaceNum - 1]
                for surfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                    state.dataMundtSimMgr.ZoneData[ZoneIndex - 1].HBsurfaceIndexes.emplace_back(surfNum)
                    NumOfSurfs += 1
                MaxNumOfSurfs = max(MaxNumOfSurfs, NumOfSurfs)
                NumOfAirNodes = state.dataRoomAir.TotNumOfZoneAirNodes[ZoneIndex - 1]
                MaxNumOfAirNodes = max(MaxNumOfAirNodes, NumOfAirNodes)
                state.dataMundtSimMgr.ZoneData[ZoneIndex - 1].NumOfSurfs = NumOfSurfs
                state.dataMundtSimMgr.ZoneData[ZoneIndex - 1].MundtZoneIndex = NumOfMundtZones
    state.dataMundtSimMgr.ID1dSurf.allocate(MaxNumOfSurfs)
    state.dataMundtSimMgr.TheseSurfIDs.allocate(MaxNumOfSurfs)
    state.dataMundtSimMgr.MundtAirSurf.allocate(MaxNumOfSurfs, NumOfMundtZones)
    state.dataMundtSimMgr.LineNode.allocate(MaxNumOfAirNodes, NumOfMundtZones)
    for SurfNum in range(1, MaxNumOfSurfs + 1):
        state.dataMundtSimMgr.ID1dSurf[SurfNum - 1] = SurfNum
    for e in range(state.dataMundtSimMgr.MundtAirSurf.size()):
        state.dataMundtSimMgr.MundtAirSurf[e].Area = 0.0
        state.dataMundtSimMgr.MundtAirSurf[e].Temp = 25.0
        state.dataMundtSimMgr.MundtAirSurf[e].Hc = 0.0
        state.dataMundtSimMgr.MundtAirSurf[e].TMeanAir = 25.0
    for e in range(state.dataMundtSimMgr.LineNode.size()):
        state.dataMundtSimMgr.LineNode[e].AirNodeName = ""
        state.dataMundtSimMgr.LineNode[e].ClassType = 0  # Invalid
        state.dataMundtSimMgr.LineNode[e].Height = 0.0
        state.dataMundtSimMgr.LineNode[e].Temp = 25.0
    for MundtZoneIndex in range(1, NumOfMundtZones + 1):
        for ZoneIndex in range(1, state.dataGlobal.NumOfZones + 1):
            var thisZone = state.dataHeatBal.Zone[ZoneIndex - 1]
            if state.dataMundtSimMgr.ZoneData[ZoneIndex - 1].MundtZoneIndex == MundtZoneIndex:
                for surfNum in range(1, state.dataMundtSimMgr.ZoneData[ZoneIndex - 1].NumOfSurfs + 1):
                    state.dataMundtSimMgr.MundtAirSurf[surfNum - 1, MundtZoneIndex - 1].Area = \
                        state.dataSurface.Surface[state.dataMundtSimMgr.ZoneData[ZoneIndex - 1].HBsurfaceIndexes[surfNum - 1] - 1].Area
                RoomNodesCount = 0
                FloorSurfCount = 0
                for NodeNum in range(1, state.dataRoomAir.TotNumOfZoneAirNodes[ZoneIndex - 1] + 1):
                    state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].SurfMask.allocate(state.dataMundtSimMgr.ZoneData[ZoneIndex - 1].NumOfSurfs)
                    if NodeNum == 1:
                        AirNodeBeginNum = NodeNum
                    if AirNodeBeginNum > state.dataRoomAir.TotNumOfAirNodes:
                        ShowFatalError(state, "An array bound exceeded. Error in InitMundtModel subroutine of MundtSimMgr.")
                    AirNodeFoundFlag = False
                    for AirNodeNum in range(AirNodeBeginNum, state.dataRoomAir.TotNumOfAirNodes + 1):
                        if Util.SameString(state.dataRoomAir.AirNode[AirNodeNum - 1].ZoneName, thisZone.Name):
                            state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].ClassType = state.dataRoomAir.AirNode[AirNodeNum - 1].ClassType
                            state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].AirNodeName = state.dataRoomAir.AirNode[AirNodeNum - 1].Name
                            state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].Height = state.dataRoomAir.AirNode[AirNodeNum - 1].Height
                            state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].SurfMask = state.dataRoomAir.AirNode[AirNodeNum - 1].SurfMask
                            SetupOutputVariable(state,
                                                "Room Air Node Air Temperature",
                                                1,  # C
                                                state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].Temp,
                                                2,  # System
                                                1,  # Average
                                                state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].AirNodeName)
                            AirNodeBeginNum = AirNodeNum + 1
                            AirNodeFoundFlag = True
                            break
                    if not AirNodeFoundFlag:
                        ShowSevereError(state, format("InitMundtModel: Air Node in Zone=\"{}\" is not found.", thisZone.Name))
                        ErrorsFound = True
                        continue
                    if state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].ClassType == 3:  # Mundt
                        RoomNodesCount += 1
                    if state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].ClassType == 4:  # Floor
                        FloorSurfCount += count(state.dataMundtSimMgr.LineNode[NodeNum - 1, MundtZoneIndex - 1].SurfMask)
                if AirNodeFoundFlag:
                    break
        MaxNumOfRoomNodes = max(MaxNumOfRoomNodes, RoomNodesCount)
        MaxNumOfFloorSurfs = max(MaxNumOfFloorSurfs, FloorSurfCount)
    if ErrorsFound:
        ShowFatalError(state, "InitMundtModel: Preceding condition(s) cause termination.")
    state.dataMundtSimMgr.RoomNodeIDs.allocate(MaxNumOfRoomNodes)
    state.dataMundtSimMgr.FloorSurfSetIDs.allocate(MaxNumOfFloorSurfs)
    state.dataMundtSimMgr.FloorSurf.allocate(MaxNumOfFloorSurfs)

def GetSurfHBDataForDispVent1Node(inout state: EnergyPlusData, ZoneNum: Int):
    var CpAir: Float64  # specific heat
    var SumSysMCp: Float64  # zone sum of air system MassFlowRate*Cp
    var SumSysMCpT: Float64  # zone sum of air system MassFlowRate*Cp*T
    var MassFlowRate: Float64  # mass flowrate
    var NodeTemp: Float64  # node temperature
    var ZoneNode: Int  # index number for specified zone node
    var ZoneMassFlowRate: Float64  # zone mass flowrate
    var ZoneEquipConfigNum: Int  # index number for zone equipment configuration
    var ZoneMult: Float64  # total zone multiplier
    var RetAirConvGain: Float64
    var Zone = state.dataHeatBal.Zone
    ZoneEquipConfigNum = ZoneNum
    if not Zone[ZoneNum - 1].IsControlled:
        ShowFatalError(state, format("Zones must be controlled for Mundt air model. No system serves zone {}", Zone[ZoneNum - 1].Name))
        return
    state.dataMundtSimMgr.ZoneHeight = Zone[ZoneNum - 1].CeilingHeight
    state.dataMundtSimMgr.ZoneFloorArea = Zone[ZoneNum - 1].FloorArea
    ZoneMult = Zone[ZoneNum - 1].Multiplier * Zone[ZoneNum - 1].ListMultiplier
    ZoneNode = Zone[ZoneNum - 1].SystemZoneNodeNumber
    state.dataMundtSimMgr.ZoneAirDensity = \
        PsyRhoAirFnPbTdbW(state,
                          state.dataEnvrn.OutBaroPress,
                          state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT,
                          PsyWFnTdpPb(state, state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT, state.dataEnvrn.OutBaroPress))
    ZoneMassFlowRate = state.dataLoopNodes.Node[ZoneNode - 1].MassFlowRate
    state.dataMundtSimMgr.SupplyAirVolumeRate = ZoneMassFlowRate / state.dataMundtSimMgr.ZoneAirDensity
    var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
    if ZoneMassFlowRate <= 0.0001:
        state.dataMundtSimMgr.QsysCoolTot = 0.0
    else:
        SumSysMCp = 0.0
        SumSysMCpT = 0.0
        for NodeNum in range(1, state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum - 1].NumInletNodes + 1):
            NodeTemp = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum - 1].InletNode[NodeNum - 1] - 1].Temp
            MassFlowRate = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum - 1].InletNode[NodeNum - 1] - 1].MassFlowRate
            CpAir = PsyCpAirFnW(thisZoneHB.airHumRat)
            SumSysMCp += MassFlowRate * CpAir
            SumSysMCpT += MassFlowRate * CpAir * NodeTemp
        if SumSysMCp <= 0.0:
            state.dataMundtSimMgr.SupplyAirTemp = \
                state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum - 1].InletNode[0] - 1].Temp
        else:
            state.dataMundtSimMgr.SupplyAirTemp = SumSysMCpT / SumSysMCp
        CpAir = PsyCpAirFnW(thisZoneHB.airHumRat)
        state.dataMundtSimMgr.QsysCoolTot = \
            -(SumSysMCpT - ZoneMassFlowRate * CpAir * state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT)
    state.dataMundtSimMgr.ConvIntGain = InternalHeatGains.zoneSumAllInternalConvectionGains(state, ZoneNum)
    state.dataMundtSimMgr.ConvIntGain += state.dataHeatBalFanSys.SumConvHTRadSys[ZoneNum - 1] + state.dataHeatBalFanSys.SumConvPool[ZoneNum - 1] + \
                                          thisZoneHB.SysDepZoneLoadsLagged + thisZoneHB.NonAirSystemResponse / ZoneMult
    if Zone[ZoneNum - 1].NoHeatToReturnAir:
        RetAirConvGain = InternalHeatGains.zoneSumAllReturnAirConvectionGains(state, ZoneNum, 0)
        state.dataMundtSimMgr.ConvIntGain += RetAirConvGain
    state.dataMundtSimMgr.QventCool = \
        -thisZoneHB.MCPI * (Zone[ZoneNum - 1].OutDryBulbTemp - state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT)
    for SurfNum in range(1, state.dataMundtSimMgr.ZoneData[ZoneNum - 1].NumOfSurfs + 1):
        state.dataMundtSimMgr.MundtAirSurf[SurfNum - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp = \
            state.dataHeatBalSurf.SurfTempIn[state.dataMundtSimMgr.ZoneData[ZoneNum - 1].HBsurfaceIndexes[SurfNum - 1] - 1]
        state.dataMundtSimMgr.MundtAirSurf[SurfNum - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Hc = \
            state.dataHeatBalSurf.SurfHConvInt[state.dataMundtSimMgr.ZoneData[ZoneNum - 1].HBsurfaceIndexes[SurfNum - 1] - 1]

def SetupDispVent1Node(inout state: EnergyPlusData, ZoneNum: Int, inout ErrorsFound: Bool):
    var NodeNum: Int  # index for air nodes
    state.dataMundtSimMgr.NumRoomNodes = 0
    for NodeNum in range(1, state.dataRoomAir.TotNumOfZoneAirNodes[ZoneNum - 1] + 1):
        var classType = state.dataMundtSimMgr.LineNode[NodeNum - 1, state.dataMundtSimMgr.MundtZoneNum - 1].ClassType
        if classType == 0:  # Inlet
            state.dataMundtSimMgr.SupplyNodeID = NodeNum
        elif classType == 4:  # Floor
            state.dataMundtSimMgr.MundtFootAirID = NodeNum
        elif classType == 1:  # Control
            state.dataMundtSimMgr.TstatNodeID = NodeNum
        elif classType == 2:  # Ceiling
            state.dataMundtSimMgr.MundtCeilAirID = NodeNum
        elif classType == 3:  # Mundt
            state.dataMundtSimMgr.NumRoomNodes += 1
            state.dataMundtSimMgr.RoomNodeIDs[state.dataMundtSimMgr.NumRoomNodes - 1] = NodeNum
        elif classType == 5:  # Return
            state.dataMundtSimMgr.ReturnNodeID = NodeNum
        else:
            ShowSevereError(state, "SetupMundtModel: Non-Standard Type of Air Node for Mundt Model")
            ErrorsFound = True
    if state.dataMundtSimMgr.MundtFootAirID > 0:
        state.dataMundtSimMgr.NumFloorSurfs = \
            count(state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.MundtFootAirID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].SurfMask)
        state.dataMundtSimMgr.FloorSurfSetIDs = \
            pack(state.dataMundtSimMgr.ID1dSurf,
                 state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.MundtFootAirID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].SurfMask)
        for e in range(state.dataMundtSimMgr.FloorSurf.size()):
            state.dataMundtSimMgr.FloorSurf[e].Temp = 25.0
            state.dataMundtSimMgr.FloorSurf[e].Hc = 0.0
            state.dataMundtSimMgr.FloorSurf[e].Area = 0.0
        for SurfNum in range(1, state.dataMundtSimMgr.NumFloorSurfs + 1):
            state.dataMundtSimMgr.FloorSurf[SurfNum - 1].Temp = \
                state.dataMundtSimMgr.MundtAirSurf[state.dataMundtSimMgr.FloorSurfSetIDs[SurfNum - 1] - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp
            state.dataMundtSimMgr.FloorSurf[SurfNum - 1].Hc = \
                state.dataMundtSimMgr.MundtAirSurf[state.dataMundtSimMgr.FloorSurfSetIDs[SurfNum - 1] - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Hc
            state.dataMundtSimMgr.FloorSurf[SurfNum - 1].Area = \
                state.dataMundtSimMgr.MundtAirSurf[state.dataMundtSimMgr.FloorSurfSetIDs[SurfNum - 1] - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Area
    else:
        ShowSevereError(state, format("SetupMundtModel: Mundt model has no FloorAirNode, Zone={}", state.dataHeatBal.Zone[ZoneNum - 1].Name))
        ErrorsFound = True

def CalcDispVent1Node(inout state: EnergyPlusData, ZoneNum: Int):
    var TAirFoot: Float64  # air temperature at the floor
    var TAirCeil: Float64  # air temperature at the ceiling
    var TLeaving: Float64  # air temperature leaving zone (= return air temp)
    var TControlPoint: Float64  # air temperature at thermostat
    var Slope: Float64  # vertical air temperature gradient (slope) from Mundt equations
    var QequipConvFloor: Float64  # convective gain at the floor due to internal heat sources
    var QSensInfilFloor: Float64  # convective gain at the floor due to infiltration
    var FloorSumHAT: Float64  # sum of hci*area*temp at the floor
    var FloorSumHA: Float64  # sum of hci*area at the floor
    var TThisNode: Float64  # dummy variable for air node temp
    var NodeNum: Int  # index for air nodes
    var SurfNum: Int  # index for surfaces
    var SurfCounted: Int  # number of surfaces associated with an air node
    var CpAir: Float64 = 1005.0  # Specific heat of air
    var MinSlope: Float64 = 0.001  # Bound on result from Mundt model
    var MaxSlope: Float64 = 5.0  # Bound on result from Mundt Model
    QequipConvFloor = state.dataRoomAir.ConvectiveFloorSplit[ZoneNum - 1] * state.dataMundtSimMgr.ConvIntGain
    QSensInfilFloor = -state.dataRoomAir.InfiltratFloorSplit[ZoneNum - 1] * state.dataMundtSimMgr.QventCool
    FloorSumHAT = 0.0
    FloorSumHA = 0.0
    for s in range(state.dataMundtSimMgr.FloorSurf.size()):
        FloorSumHAT += state.dataMundtSimMgr.FloorSurf[s].Area * state.dataMundtSimMgr.FloorSurf[s].Hc * state.dataMundtSimMgr.FloorSurf[s].Temp
        FloorSumHA += state.dataMundtSimMgr.FloorSurf[s].Area * state.dataMundtSimMgr.FloorSurf[s].Hc
    TAirFoot = \
        ((state.dataMundtSimMgr.ZoneAirDensity * CpAir * state.dataMundtSimMgr.SupplyAirVolumeRate * state.dataMundtSimMgr.SupplyAirTemp) + \
         (FloorSumHAT) + QequipConvFloor + QSensInfilFloor) / \
        ((state.dataMundtSimMgr.ZoneAirDensity * CpAir * state.dataMundtSimMgr.SupplyAirVolumeRate) + (FloorSumHA))
    if state.dataMundtSimMgr.QsysCoolTot <= 0.0:
        TLeaving = state.dataMundtSimMgr.SupplyAirTemp
    else:
        TLeaving = \
            (state.dataMundtSimMgr.QsysCoolTot / (state.dataMundtSimMgr.ZoneAirDensity * CpAir * state.dataMundtSimMgr.SupplyAirVolumeRate)) + \
            state.dataMundtSimMgr.SupplyAirTemp
    Slope = (TLeaving - TAirFoot) / \
            (state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.ReturnNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height - \
             state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.MundtFootAirID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height)
    if Slope > MaxSlope:
        Slope = MaxSlope
        TAirFoot = TLeaving - \
                   (Slope * (state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.ReturnNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height - \
                             state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.MundtFootAirID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height))
    if Slope < MinSlope:  # pretty much vertical
        Slope = MinSlope
        TAirFoot = TLeaving
    TAirCeil = \
        TLeaving - (Slope * (state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.ReturnNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height - \
                             state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.MundtCeilAirID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height))
    TControlPoint = \
        TLeaving - (Slope * (state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.ReturnNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height - \
                             state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.TstatNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height))
    SetNodeResult(state, state.dataMundtSimMgr.SupplyNodeID, state.dataMundtSimMgr.SupplyAirTemp)
    SetNodeResult(state, state.dataMundtSimMgr.ReturnNodeID, TLeaving)
    SetNodeResult(state, state.dataMundtSimMgr.MundtCeilAirID, TAirCeil)
    SetNodeResult(state, state.dataMundtSimMgr.MundtFootAirID, TAirFoot)
    SetNodeResult(state, state.dataMundtSimMgr.TstatNodeID, TControlPoint)
    for SurfNum in range(1, state.dataMundtSimMgr.NumFloorSurfs + 1):
        SetSurfTmeanAir(state, state.dataMundtSimMgr.FloorSurfSetIDs[SurfNum - 1], TAirFoot)
    SurfCounted = count(state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.MundtCeilAirID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].SurfMask)
    state.dataMundtSimMgr.TheseSurfIDs = \
        pack(state.dataMundtSimMgr.ID1dSurf,
             state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.MundtCeilAirID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].SurfMask)
    for SurfNum in range(1, SurfCounted + 1):
        SetSurfTmeanAir(state, state.dataMundtSimMgr.TheseSurfIDs[SurfNum - 1], TAirCeil)
    for NodeNum in range(1, state.dataMundtSimMgr.NumRoomNodes + 1):
        TThisNode = \
            TLeaving - \
            (Slope * (state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.ReturnNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height - \
                      state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.RoomNodeIDs[NodeNum - 1] - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Height))
        SetNodeResult(state, state.dataMundtSimMgr.RoomNodeIDs[NodeNum - 1], TThisNode)
        SurfCounted = \
            count(state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.RoomNodeIDs[NodeNum - 1] - 1, state.dataMundtSimMgr.MundtZoneNum - 1].SurfMask)
        state.dataMundtSimMgr.TheseSurfIDs = \
            pack(state.dataMundtSimMgr.ID1dSurf,
                 state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.RoomNodeIDs[NodeNum - 1] - 1, state.dataMundtSimMgr.MundtZoneNum - 1].SurfMask)
        for SurfNum in range(1, SurfCounted + 1):
            SetSurfTmeanAir(state, state.dataMundtSimMgr.TheseSurfIDs[SurfNum - 1], TThisNode)

def SetNodeResult(inout state: EnergyPlusData, NodeID: Int, TempResult: Float64):
    state.dataMundtSimMgr.LineNode[NodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp = TempResult

def SetSurfTmeanAir(inout state: EnergyPlusData, SurfID: Int, TeffAir: Float64):
    state.dataMundtSimMgr.MundtAirSurf[SurfID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].TMeanAir = TeffAir

def SetSurfHBDataForDispVent1Node(inout state: EnergyPlusData, ZoneNum: Int):
    var DeltaTemp: Float64  # dummy variable for temperature difference
    var NumOfSurfs: Int = state.dataMundtSimMgr.ZoneData[ZoneNum - 1].NumOfSurfs
    if (state.dataMundtSimMgr.SupplyAirVolumeRate > 0.0001) and \
       (state.dataMundtSimMgr.QsysCoolTot > 0.0001):  # Controlled zone when the system is on
        if state.dataRoomAir.AirModel[ZoneNum - 1].TempCoupleScheme == 0:  # Direct
            for SurfNum in range(1, NumOfSurfs + 1):
                var hbSurfNum: Int = state.dataMundtSimMgr.ZoneData[ZoneNum - 1].HBsurfaceIndexes[SurfNum - 1]
                state.dataHeatBal.SurfTempEffBulkAir[hbSurfNum - 1] = \
                    state.dataMundtSimMgr.MundtAirSurf[SurfNum - 1, state.dataMundtSimMgr.MundtZoneNum - 1].TMeanAir
                state.dataSurface.SurfTAirRef[hbSurfNum - 1] = 1  # AdjacentAirTemp
                state.dataSurface.SurfTAirRefRpt[hbSurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[hbSurfNum - 1]]
            var ZoneNodeNum: Int = state.dataHeatBal.Zone[ZoneNum - 1].SystemZoneNodeNumber
            state.dataLoopNodes.Node[ZoneNodeNum - 1].Temp = \
                state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.ReturnNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum - 1] = \
                state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.TstatNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp
        else:
            for SurfNum in range(1, NumOfSurfs + 1):
                var hbSurfNum: Int = state.dataMundtSimMgr.ZoneData[ZoneNum - 1].HBsurfaceIndexes[SurfNum - 1]
                DeltaTemp = state.dataMundtSimMgr.MundtAirSurf[SurfNum - 1, state.dataMundtSimMgr.MundtZoneNum - 1].TMeanAir - \
                            state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.TstatNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp
                state.dataHeatBal.SurfTempEffBulkAir[hbSurfNum - 1] = state.dataHeatBalFanSys.zoneTstatSetpts[ZoneNum - 1].setpt + DeltaTemp
                state.dataSurface.SurfTAirRef[hbSurfNum - 1] = 1  # AdjacentAirTemp
                state.dataSurface.SurfTAirRefRpt[hbSurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[hbSurfNum - 1]]
            var ZoneNodeNum: Int = state.dataHeatBal.Zone[ZoneNum - 1].SystemZoneNodeNumber
            DeltaTemp = state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.ReturnNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp - \
                        state.dataMundtSimMgr.LineNode[state.dataMundtSimMgr.TstatNodeID - 1, state.dataMundtSimMgr.MundtZoneNum - 1].Temp
            state.dataLoopNodes.Node[ZoneNodeNum - 1].Temp = state.dataHeatBalFanSys.zoneTstatSetpts[ZoneNum - 1].setpt + DeltaTemp
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].ZT  # for indirect coupling, control air temp is equal to mean air temp?
        state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel = True
    else:  # Controlled zone when the system is off --> Use the mixing model instead of the Mundt model
        for SurfNum in range(1, NumOfSurfs + 1):
            var hbSurfNum: Int = state.dataMundtSimMgr.ZoneData[ZoneNum - 1].HBsurfaceIndexes[SurfNum - 1]
            state.dataHeatBal.SurfTempEffBulkAir[hbSurfNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT
            state.dataSurface.SurfTAirRef[hbSurfNum - 1] = 0  # ZoneMeanAirTemp
            state.dataSurface.SurfTAirRefRpt[hbSurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[hbSurfNum - 1]]
        state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel = False
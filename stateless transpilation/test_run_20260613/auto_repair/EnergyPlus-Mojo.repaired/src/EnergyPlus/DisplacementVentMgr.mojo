from ConvectionCoefficients import CalcDetailedHcInForDVModel
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import OutBaroPress
from DataHVACGlobals import TimeStepSys, TimeStepSysSec, ShortenTimeStepSysRoomAir, UseZoneTimeStepHistory, PreviousTimeStep
from DataHeatBalFanSys import SumConvHTRadSys, SumConvPool, TempTstatAir
from DataHeatBalSurface import SurfTempIn, SurfHConvInt
from DataHeatBalance import Zone, People, TotPeople, IntGainType, ZoneAirSolutionAlgo, SolutionAlgo, IntGainType
from DataLoopNodes import Node
from DataRoomAirModel import RoomAirData
from DataSurfaces import Surface, RefAirTemp, SurfTAirRef, SurfTAirRefRpt, SurfTempEffBulkAir, SurfTAirRefReportVals
from DataZoneEquipment import ZoneEquipConfig
from InternalHeatGains import SumInternalConvectionGainsByTypes, SumReturnAirConvectionGainsByTypes
from Psychrometrics import PsyCpAirFnW, PsyRhoAirFnPbTdbW
from ScheduleManager import Schedule
from UtilityRoutines import ShowWarningError, ShowFatalError
from ZoneTempPredictorCorrector import ZoneTempPredictorCorrectorData

from Builtin import Float64, Int, Bool, List, String, min, max, pow, exp, assert
from math import pi

# Constants from header within RoomAir namespace
let IntGainTypesOccupied: List[IntGainType] = [
    IntGainType.People,
    IntGainType.WaterHeaterMixed,
    IntGainType.WaterHeaterStratified,
    IntGainType.ThermalStorageChilledWaterMixed,
    IntGainType.ThermalStorageChilledWaterStratified,
    IntGainType.ThermalStorageHotWaterStratified,
    IntGainType.ElectricEquipment,
    IntGainType.ElectricEquipmentITEAirCooled,
    IntGainType.GasEquipment,
    IntGainType.HotWaterEquipment,
    IntGainType.SteamEquipment,
    IntGainType.OtherEquipment,
    IntGainType.IndoorGreen,
    IntGainType.ZoneBaseboardOutdoorTemperatureControlled,
    IntGainType.GeneratorFuelCell,
    IntGainType.WaterUseEquipment,
    IntGainType.GeneratorMicroCHP,
    IntGainType.ElectricLoadCenterTransformer,
    IntGainType.ElectricLoadCenterInverterSimple,
    IntGainType.ElectricLoadCenterInverterFunctionOfPower,
    IntGainType.ElectricLoadCenterInverterLookUpTable,
    IntGainType.ElectricLoadCenterStorageLiIonNmcBattery,
    IntGainType.ElectricLoadCenterStorageBattery,
    IntGainType.ElectricLoadCenterStorageSimple,
    IntGainType.PipeIndoor,
    IntGainType.RefrigerationCase,
    IntGainType.RefrigerationCompressorRack,
    IntGainType.RefrigerationSystemAirCooledCondenser,
    IntGainType.RefrigerationSystemSuctionPipe,
    IntGainType.RefrigerationSecondaryReceiver,
    IntGainType.RefrigerationSecondaryPipe,
    IntGainType.RefrigerationWalkIn,
    IntGainType.RefrigerationTransSysAirCooledGasCooler,
    IntGainType.RefrigerationTransSysSuctionPipeMT,
    IntGainType.RefrigerationTransSysSuctionPipeLT,
    IntGainType.Pump_VarSpeed,
    IntGainType.Pump_ConSpeed,
    IntGainType.Pump_Cond,
    IntGainType.PumpBank_VarSpeed,
    IntGainType.PumpBank_ConSpeed,
    IntGainType.PlantComponentUserDefined,
    IntGainType.CoilUserDefined,
    IntGainType.ZoneHVACForcedAirUserDefined,
    IntGainType.AirTerminalUserDefined,
    IntGainType.PackagedTESCoilTank,
    IntGainType.SecCoolingDXCoilSingleSpeed,
    IntGainType.SecHeatingDXCoilSingleSpeed,
    IntGainType.SecCoolingDXCoilTwoSpeed,
    IntGainType.SecCoolingDXCoilMultiSpeed,
    IntGainType.SecHeatingDXCoilMultiSpeed,
    IntGainType.ElectricLoadCenterConverter,
    IntGainType.FanSystemModel
]

let IntGainTypesMixedSubzone: List[IntGainType] = [
    IntGainType.DaylightingDeviceTubular,
    IntGainType.Lights
]

let ExcludedIntGainTypes: List[IntGainType] = [
    IntGainType.ZoneContaminantSourceAndSinkCarbonDioxide,
    IntGainType.ZoneContaminantSourceAndSinkGenericContam
]

struct DisplacementVentMgrData(BaseGlobalStruct):
    var HAT_MX: Float64 = 0.0
    var HA_MX: Float64 = 0.0
    var HAT_OC: Float64 = 0.0
    var HA_OC: Float64 = 0.0
    var HAT_FLOOR: Float64 = 0.0
    var HA_FLOOR: Float64 = 0.0
    var HeightFloorSubzoneTop: Float64 = 0.2
    var ThickOccupiedSubzoneMin: Float64 = 0.2
    var HeightIntMass: Float64 = 0.0
    var HeightIntMassDefault: Float64 = 2.0
    var InitUCSDDVMyOneTimeFlag: Bool = True
    var MyEnvrnFlag: List[Bool] = List[Bool]()
    var TempDepCoef: Float64 = 0.0
    var TempIndCoef: Float64 = 0.0

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.HAT_MX = 0.0
        self.HA_MX = 0.0
        self.HAT_OC = 0.0
        self.HA_OC = 0.0
        self.HAT_FLOOR = 0.0
        self.HA_FLOOR = 0.0
        self.HeightFloorSubzoneTop = 0.2
        self.ThickOccupiedSubzoneMin = 0.2
        self.HeightIntMass = 0.0
        self.HeightIntMassDefault = 2.0
        self.InitUCSDDVMyOneTimeFlag = True
        self.MyEnvrnFlag = List[Bool]()
        self.TempDepCoef = 0.0
        self.TempIndCoef = 0.0

# ----------------------------------------------------------------------
# RoomAir functions
# ----------------------------------------------------------------------

def ManageDispVent3Node(inout state: EnergyPlusData, ZoneNum: Int):
    """index number for the specified zone"""
    InitDispVent3Node(state, ZoneNum)
    CalcDispVent3Node(state, ZoneNum)

def InitDispVent3Node(inout state: EnergyPlusData, ZoneNum: Int):
    if state.dataDispVentMgr.InitUCSDDVMyOneTimeFlag:
        state.dataDispVentMgr.MyEnvrnFlag = List[Bool](size=state.dataGlobal.NumOfZones, fill=True)
        state.dataDispVentMgr.HeightFloorSubzoneTop = 0.2
        state.dataDispVentMgr.ThickOccupiedSubzoneMin = 0.2
        state.dataDispVentMgr.HeightIntMassDefault = 2.0
        state.dataDispVentMgr.InitUCSDDVMyOneTimeFlag = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataDispVentMgr.MyEnvrnFlag[ZoneNum-1]:
        state.dataDispVentMgr.HAT_MX = 0.0
        state.dataDispVentMgr.HAT_OC = 0.0
        state.dataDispVentMgr.HA_MX = 0.0
        state.dataDispVentMgr.HA_OC = 0.0
        state.dataDispVentMgr.HAT_FLOOR = 0.0
        state.dataDispVentMgr.HA_FLOOR = 0.0
        state.dataDispVentMgr.MyEnvrnFlag[ZoneNum-1] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataDispVentMgr.MyEnvrnFlag[ZoneNum-1] = True

    state.dataDispVentMgr.HeightIntMass = state.dataDispVentMgr.HeightIntMassDefault

def HcDispVent3Node(inout state: EnergyPlusData, ZoneNum: Int, FractionHeight: Float64):
    var HLD: Float64       # Convection coefficient for the lower area of surface
    var TmedDV: Float64    # Average temperature for DV
    var Z1: Float64        # auxiliary var for lowest height
    var Z2: Float64        # auxiliary var for highest height
    var ZSupSurf: Float64  # highest height for this surface
    var ZInfSurf: Float64  # lowest height for this surface
    var HLU: Float64       # Convection coefficient for the upper area of surface
    var LayH: Float64      # Height of the Occupied/Mixed subzone interface
    var LayFrac: Float64   # Fraction height of the Occupied/Mixed subzone interface

    state.dataDispVentMgr.HAT_MX = 0.0
    state.dataDispVentMgr.HAT_OC = 0.0
    state.dataDispVentMgr.HA_MX = 0.0
    state.dataDispVentMgr.HA_OC = 0.0
    state.dataDispVentMgr.HAT_FLOOR = 0.0
    state.dataDispVentMgr.HA_FLOOR = 0.0

    var SurfTempIn = state.dataHeatBalSurf.SurfTempIn

    if state.dataRoomAir.IsZoneDispVent3Node(ZoneNum):
        LayFrac = FractionHeight
        LayH = FractionHeight * (state.dataRoomAir.ZoneCeilingHeight2(ZoneNum) - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum))

        # WALLS
        let wallBeg = state.dataRoomAir.PosZ_Wall(ZoneNum).beg
        let wallEnd = state.dataRoomAir.PosZ_Wall(ZoneNum).end
        for Ctd in range(wallBeg, wallEnd + 1):
            var SurfNum = state.dataRoomAir.APos_Wall[Ctd-1]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum-1]
            state.dataSurface.SurfTAirRef[SurfNum-1] = RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum-1] = SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum-1]]
            # compute Z1, Z2 as min/max z of vertices
            var z_min = surf.Vertex[0].z
            var z_max = surf.Vertex[0].z
            for vert in surf.Vertex:
                if vert.z < z_min: z_min = vert.z
                if vert.z > z_max: z_max = vert.z
            Z1 = z_min
            Z2 = z_max
            ZSupSurf = Z2 - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum)
            ZInfSurf = Z1 - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum)

            if ZInfSurf > LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                state.dataRoomAir.HWall[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataDispVentMgr.HAT_MX += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HWall[Ctd-1]
                state.dataDispVentMgr.HA_MX += surf.Area * state.dataRoomAir.HWall[Ctd-1]

            if ZSupSurf < LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                state.dataRoomAir.HWall[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataDispVentMgr.HAT_OC += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HWall[Ctd-1]
                state.dataDispVentMgr.HA_OC += surf.Area * state.dataRoomAir.HWall[Ctd-1]

            if ZInfSurf <= LayH and ZSupSurf >= LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                HLU = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                HLD = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX(ZoneNum) + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC(ZoneNum)) / \
                         (ZSupSurf - ZInfSurf)
                state.dataRoomAir.HWall[Ctd-1] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
                state.dataDispVentMgr.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLU
                state.dataDispVentMgr.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
                state.dataDispVentMgr.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLD
                state.dataDispVentMgr.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = TmedDV

            state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1] = state.dataRoomAir.HWall[Ctd-1]

        # WINDOWS
        let winBeg = state.dataRoomAir.PosZ_Window(ZoneNum).beg
        let winEnd = state.dataRoomAir.PosZ_Window(ZoneNum).end
        for Ctd in range(winBeg, winEnd + 1):
            var SurfNum = state.dataRoomAir.APos_Window[Ctd-1]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum-1]
            state.dataSurface.SurfTAirRef[SurfNum-1] = RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum-1] = SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum-1]]

            if surf.Tilt > 10.0 and surf.Tilt < 170.0:  # Window Wall
                var z_min = surf.Vertex[0].z
                var z_max = surf.Vertex[0].z
                for vert in surf.Vertex:
                    if vert.z < z_min: z_min = vert.z
                    if vert.z > z_max: z_max = vert.z
                Z1 = z_min
                Z2 = z_max
                ZSupSurf = Z2 - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum)
                ZInfSurf = Z1 - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum)

                if ZInfSurf > LayH:
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    state.dataRoomAir.HWindow[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    state.dataDispVentMgr.HAT_MX += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HWindow[Ctd-1]
                    state.dataDispVentMgr.HA_MX += surf.Area * state.dataRoomAir.HWindow[Ctd-1]

                if ZSupSurf < LayH:
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    state.dataRoomAir.HWindow[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    state.dataDispVentMgr.HAT_OC += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HWindow[Ctd-1]
                    state.dataDispVentMgr.HA_OC += surf.Area * state.dataRoomAir.HWindow[Ctd-1]

                if ZInfSurf <= LayH and ZSupSurf >= LayH:
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    HLU = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    HLD = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX(ZoneNum) + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC(ZoneNum)) / \
                             (ZSupSurf - ZInfSurf)
                    state.dataRoomAir.HWindow[Ctd-1] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
                    state.dataDispVentMgr.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLU
                    state.dataDispVentMgr.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
                    state.dataDispVentMgr.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLD
                    state.dataDispVentMgr.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = TmedDV

            if surf.Tilt <= 10.0:  # Window Ceiling
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                state.dataRoomAir.HWindow[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataDispVentMgr.HAT_MX += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HWindow[Ctd-1]
                state.dataDispVentMgr.HA_MX += surf.Area * state.dataRoomAir.HWindow[Ctd-1]

            if surf.Tilt >= 170.0:  # Window Floor
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                state.dataRoomAir.HWindow[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataDispVentMgr.HAT_OC += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HWindow[Ctd-1]
                state.dataDispVentMgr.HA_OC += surf.Area * state.dataRoomAir.HWindow[Ctd-1]

            state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1] = state.dataRoomAir.HWindow[Ctd-1]

        # DOORS
        let doorBeg = state.dataRoomAir.PosZ_Door(ZoneNum).beg
        let doorEnd = state.dataRoomAir.PosZ_Door(ZoneNum).end
        for Ctd in range(doorBeg, doorEnd + 1):
            var SurfNum = state.dataRoomAir.APos_Door[Ctd-1]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum-1]
            state.dataSurface.SurfTAirRef[SurfNum-1] = RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum-1] = SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum-1]]

            if surf.Tilt > 10.0 and surf.Tilt < 170.0:  # Door Wall
                var z_min = surf.Vertex[0].z
                var z_max = surf.Vertex[0].z
                for vert in surf.Vertex:
                    if vert.z < z_min: z_min = vert.z
                    if vert.z > z_max: z_max = vert.z
                Z1 = z_min
                Z2 = z_max
                ZSupSurf = Z2 - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum)
                ZInfSurf = Z1 - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum)

                if ZInfSurf > LayH:
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    state.dataRoomAir.HDoor[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    state.dataDispVentMgr.HAT_MX += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HDoor[Ctd-1]
                    state.dataDispVentMgr.HA_MX += surf.Area * state.dataRoomAir.HDoor[Ctd-1]

                if ZSupSurf < LayH:
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    state.dataRoomAir.HDoor[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    state.dataDispVentMgr.HAT_OC += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HDoor[Ctd-1]
                    state.dataDispVentMgr.HA_OC += surf.Area * state.dataRoomAir.HDoor[Ctd-1]

                if ZInfSurf <= LayH and ZSupSurf >= LayH:
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    HLU = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                    CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                    HLD = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                    TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX(ZoneNum) + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC(ZoneNum)) / \
                             (ZSupSurf - ZInfSurf)
                    state.dataRoomAir.HDoor[Ctd-1] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
                    state.dataDispVentMgr.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLU
                    state.dataDispVentMgr.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
                    state.dataDispVentMgr.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLD
                    state.dataDispVentMgr.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
                    state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = TmedDV

            if surf.Tilt <= 10.0:  # Door Ceiling
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                state.dataRoomAir.HDoor[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataDispVentMgr.HAT_MX += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HDoor[Ctd-1]
                state.dataDispVentMgr.HA_MX += surf.Area * state.dataRoomAir.HDoor[Ctd-1]

            if surf.Tilt >= 170.0:  # Door Floor
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                state.dataRoomAir.HDoor[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataDispVentMgr.HAT_OC += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HDoor[Ctd-1]
                state.dataDispVentMgr.HA_OC += surf.Area * state.dataRoomAir.HDoor[Ctd-1]

            state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1] = state.dataRoomAir.HDoor[Ctd-1]

        # Height for internal mass
        state.dataDispVentMgr.HeightIntMass = min(
            state.dataDispVentMgr.HeightIntMassDefault,
            (state.dataRoomAir.ZoneCeilingHeight2(ZoneNum) - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum))
        )

        # INTERNAL MASS
        let intBeg = state.dataRoomAir.PosZ_Internal(ZoneNum).beg
        let intEnd = state.dataRoomAir.PosZ_Internal(ZoneNum).end
        for Ctd in range(intBeg, intEnd + 1):
            var SurfNum = state.dataRoomAir.APos_Internal[Ctd-1]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum-1]
            state.dataSurface.SurfTAirRef[SurfNum-1] = RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum-1] = SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum-1]]
            ZSupSurf = state.dataDispVentMgr.HeightIntMass
            ZInfSurf = 0.0

            if ZSupSurf < LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                state.dataRoomAir.HInternal[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataDispVentMgr.HAT_OC += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HInternal[Ctd-1]
                state.dataDispVentMgr.HA_OC += surf.Area * state.dataRoomAir.HInternal[Ctd-1]

            if ZInfSurf <= LayH and ZSupSurf >= LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                HLU = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTOC(ZoneNum)
                CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
                HLD = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
                TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX(ZoneNum) + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC(ZoneNum)) / \
                         (ZSupSurf - ZInfSurf)
                state.dataRoomAir.HInternal[Ctd-1] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
                state.dataDispVentMgr.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLU
                state.dataDispVentMgr.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
                state.dataDispVentMgr.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * SurfTempIn[SurfNum-1] * HLD
                state.dataDispVentMgr.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = TmedDV

            state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1] = state.dataRoomAir.HInternal[Ctd-1]

        # CEILING
        let ceilBeg = state.dataRoomAir.PosZ_Ceiling(ZoneNum).beg
        let ceilEnd = state.dataRoomAir.PosZ_Ceiling(ZoneNum).end
        for Ctd in range(ceilBeg, ceilEnd + 1):
            var SurfNum = state.dataRoomAir.APos_Ceiling[Ctd-1]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum-1]
            state.dataSurface.SurfTAirRef[SurfNum-1] = RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum-1] = SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum-1]]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTMX(ZoneNum)
            CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
            state.dataRoomAir.HCeiling[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
            state.dataDispVentMgr.HAT_MX += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HCeiling[Ctd-1]
            state.dataDispVentMgr.HA_MX += surf.Area * state.dataRoomAir.HCeiling[Ctd-1]
            state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1] = state.dataRoomAir.HCeiling[Ctd-1]

        # FLOOR
        let floorBeg = state.dataRoomAir.PosZ_Floor(ZoneNum).beg
        let floorEnd = state.dataRoomAir.PosZ_Floor(ZoneNum).end
        for Ctd in range(floorBeg, floorEnd + 1):
            var SurfNum = state.dataRoomAir.APos_Floor[Ctd-1]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum-1]
            state.dataSurface.SurfTAirRef[SurfNum-1] = RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum-1] = SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum-1]]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTFloor(ZoneNum)
            CalcDetailedHcInForDVModel(state, SurfNum, SurfTempIn, state.dataRoomAir.DispVent3NodeHcIn)
            state.dataRoomAir.HFloor[Ctd-1] = state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1]
            state.dataDispVentMgr.HAT_FLOOR += surf.Area * SurfTempIn[SurfNum-1] * state.dataRoomAir.HFloor[Ctd-1]
            state.dataDispVentMgr.HA_FLOOR += surf.Area * state.dataRoomAir.HFloor[Ctd-1]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum-1] = state.dataRoomAir.ZTFloor(ZoneNum)
            state.dataRoomAir.DispVent3NodeHcIn[SurfNum-1] = state.dataRoomAir.HFloor[Ctd-1]

def calculateThirdOrderFloorTemperature(
    temperatureHistoryTerm: Float64,
    HAT_floor: Float64,
    HA_floor: Float64,
    MCpT_Total: Float64,
    MCp_Total: Float64,
    occupiedTemp: Float64,
    nonAirSystemResponse: Float64,
    zoneMultiplier: Float64,
    airCap: Float64
) -> Float64:
    let elevenOverSix: Float64 = 11.0 / 6.0
    return (temperatureHistoryTerm + HAT_floor + MCpT_Total + 0.6 * occupiedTemp * MCp_Total + nonAirSystemResponse / zoneMultiplier) / \
           (elevenOverSix * airCap + HA_floor + 1.6 * MCp_Total)

def CalcDispVent3Node(inout state: EnergyPlusData, ZoneNum: Int):
    """Which Zonenum"""
    var TimeStepSys = state.dataHVACGlobal.TimeStepSys
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    let OneThird: Float64 = 1.0 / 3.0
    let MinFlow_pow_fac: Float64 = pow(1.0 / 24.55 * 1.0, 1.0 / 0.6)
    var HeightFrac: Float64               # Fractional height of transition between occupied and mixed subzones
    var GainsFrac: Float64                # Fraction of lower subzone internal gains that mix as opposed to forming plumes
    var ConvGains: Float64                # Total convective gains in the room
    var ConvGainsOccupiedSubzone: Float64 # Total convective gains released in occupied subzone
    var ConvGainsMixedSubzone: Float64    # Total convective gains released in mixed subzone
    var MCp_Total: Float64                # Total capacity rate into the zone - assumed to enter at low level
    var ZTAveraged: Float64
    var TempDiffCritRep: Float64          # Minimum temperature difference between mixed and occupied subzones for reporting
    var MIXFLAG: Bool
    var MinFlow: Float64
    var NumPLPP: Float64                  # Number of plumes per person
    var MTGAUX: Float64
    var ZoneEquipConfigNum: Int
    var PowerInPlumes: Float64
    var SumSysMCp: Float64
    var SumSysMCpT: Float64
    var NodeTemp: Float64
    var MassFlowRate: Float64
    var CpAir: Float64
    var MCpT_Total: Float64
    var NumberOfPlumes: Float64
    var SumMCp: Float64
    var SumMCpT: Float64
    var TempHistTerm: Float64
    var PowerPerPlume: Float64
    var HeightMixedSubzoneAve: Float64    # Height of center of mixed air subzone
    var HeightOccupiedSubzoneAve: Float64 # Height of center of occupied air subzone
    var HeightFloorSubzoneAve: Float64    # Height of center of floor air subzone
    var HeightThermostat: Float64         # Height of center of thermostat/temperature control sensor
    var HeightComfort: Float64            # Height at which air temperature value is used to calculate comfort
    var CeilingHeight: Float64
    var ZoneMult: Float64                 # total zone multiplier
    var FlagApertures: Int
    var TempDepCoef = state.dataDispVentMgr.TempDepCoef
    var TempIndCoef = state.dataDispVentMgr.TempIndCoef
    var RetAirGain: Float64

    assert(state.dataRoomAir.AirModel.size() > 0)

    if state.dataHeatBal.ZoneAirSolutionAlgo != SolutionAlgo.ThirdOrder:
        if state.dataHVACGlobal.ShortenTimeStepSysRoomAir and TimeStepSys < state.dataGlobal.TimeStepZone:
            if state.dataHVACGlobal.PreviousTimeStep < state.dataGlobal.TimeStepZone:
                state.dataRoomAir.Zone1Floor(ZoneNum) = state.dataRoomAir.ZoneM2Floor(ZoneNum)
                state.dataRoomAir.Zone1OC(ZoneNum) = state.dataRoomAir.ZoneM2OC(ZoneNum)
                state.dataRoomAir.Zone1MX(ZoneNum) = state.dataRoomAir.ZoneM2MX(ZoneNum)
            else:
                state.dataRoomAir.Zone1Floor(ZoneNum) = state.dataRoomAir.ZoneMXFloor(ZoneNum)
                state.dataRoomAir.Zone1OC(ZoneNum) = state.dataRoomAir.ZoneMXOC(ZoneNum)
                state.dataRoomAir.Zone1MX(ZoneNum) = state.dataRoomAir.ZoneMXMX(ZoneNum)
        else:
            state.dataRoomAir.Zone1Floor(ZoneNum) = state.dataRoomAir.ZTFloor(ZoneNum)
            state.dataRoomAir.Zone1OC(ZoneNum) = state.dataRoomAir.ZTOC(ZoneNum)
            state.dataRoomAir.Zone1MX(ZoneNum) = state.dataRoomAir.ZTMX(ZoneNum)

    let zone = state.dataHeatBal.Zone[ZoneNum-1]
    MIXFLAG = False
    FlagApertures = 1
    state.dataRoomAir.DispVent3NodeHcIn = state.dataHeatBalSurf.SurfHConvInt  # assignment of array (copy)
    CeilingHeight = state.dataRoomAir.ZoneCeilingHeight2(ZoneNum) - state.dataRoomAir.ZoneCeilingHeight1(ZoneNum)
    ZoneMult = zone.Multiplier * zone.ListMultiplier
    let thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance(ZoneNum-1)  # assuming 0-based access

    for Ctd in range(1, state.dataRoomAir.TotDispVent3Node + 1):
        var zoneDV3N = state.dataRoomAir.ZoneDispVent3Node[Ctd-1]  # 0-based
        if ZoneNum == zoneDV3N.ZonePtr:
            GainsFrac = zoneDV3N.gainsSched.getCurrentVal()
            NumPLPP = zoneDV3N.NumPlumesPerOcc
            HeightThermostat = zoneDV3N.ThermostatHeight
            HeightComfort = zoneDV3N.ComfortHeight
            TempDiffCritRep = zoneDV3N.TempTrigger

    ConvGainsOccupiedSubzone = SumInternalConvectionGainsByTypes(state, ZoneNum, IntGainTypesOccupied)
    ConvGainsOccupiedSubzone += 0.5 * thisZoneHB.SysDepZoneLoadsLagged
    if zone.NoHeatToReturnAir:
        RetAirGain = SumReturnAirConvectionGainsByTypes(state, ZoneNum, IntGainTypesOccupied)
        ConvGainsOccupiedSubzone += RetAirGain

    ConvGainsMixedSubzone = SumInternalConvectionGainsByTypes(state, ZoneNum, IntGainTypesMixedSubzone)
    ConvGainsMixedSubzone += state.dataHeatBalFanSys.SumConvHTRadSys(ZoneNum) + state.dataHeatBalFanSys.SumConvPool(ZoneNum) + \
                             0.5 * thisZoneHB.SysDepZoneLoadsLagged
    if zone.NoHeatToReturnAir:
        RetAirGain = SumReturnAirConvectionGainsByTypes(state, ZoneNum, IntGainTypesMixedSubzone)
        ConvGainsMixedSubzone += RetAirGain

    ConvGains = ConvGainsOccupiedSubzone + ConvGainsMixedSubzone

    # The original assert: assert((int)(size(IntGainTypesOccupied)+size(IntGainTypesMixedSubzone)+size(ExcludedIntGainTypes)) == (int)DataHeatBalance::IntGainType::Num)
    # We skip this assertion as sizes are static.

    SumSysMCp = 0.0
    SumSysMCpT = 0.0
    ZoneEquipConfigNum = ZoneNum
    if state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum-1].IsControlled:
        var config = state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum-1]
        for NodeNum in range(1, config.NumInletNodes + 1):
            NodeTemp = state.dataLoopNodes.Node[config.InletNode[NodeNum-1]-1].Temp
            MassFlowRate = state.dataLoopNodes.Node[config.InletNode[NodeNum-1]-1].MassFlowRate
            CpAir = PsyCpAirFnW(thisZoneHB.airHumRat)
            SumSysMCp += MassFlowRate * CpAir
            SumSysMCpT += MassFlowRate * CpAir * NodeTemp

    SumMCp = thisZoneHB.MCPI + thisZoneHB.MCPV + thisZoneHB.MCPM + thisZoneHB.MCPE + thisZoneHB.MCPC + thisZoneHB.MDotCPOA
    SumMCpT = thisZoneHB.MCPTI + thisZoneHB.MCPTV + thisZoneHB.MCPTM + thisZoneHB.MCPTE + thisZoneHB.MCPTC + thisZoneHB.MDotCPOA * zone.OutDryBulbTemp

    if state.afn.simulation_control.type == AirflowNetwork.ControlType.MultizoneWithoutDistribution:
        SumMCp = state.afn.exchangeData(ZoneNum).SumMCp + state.afn.exchangeData(ZoneNum).SumMVCp + state.afn.exchangeData(ZoneNum).SumMMCp
        SumMCpT = state.afn.exchangeData(ZoneNum).SumMCpT + state.afn.exchangeData(ZoneNum).SumMVCpT + state.afn.exchangeData(ZoneNum).SumMMCpT

    MCp_Total = SumMCp + SumSysMCp
    MCpT_Total = SumMCpT + SumSysMCpT

    if state.dataHeatBal.TotPeople > 0:
        var NumberOfOccupants: Int = 0
        NumberOfPlumes = 0.0
        for Ctd in range(1, state.dataHeatBal.TotPeople + 1):
            if state.dataHeatBal.People[Ctd-1].ZonePtr == ZoneNum:
                NumberOfOccupants += state.dataHeatBal.People[Ctd-1].NumberOfPeople
                NumberOfPlumes = NumberOfOccupants * NumPLPP
        if NumberOfPlumes == 0.0:
            NumberOfPlumes = 1.0
        PowerInPlumes = (1.0 - GainsFrac) * ConvGainsOccupiedSubzone
        PowerPerPlume = PowerInPlumes / NumberOfPlumes
    else:
        NumberOfPlumes = 1.0
        PowerInPlumes = (1.0 - GainsFrac) * ConvGainsOccupiedSubzone
        PowerPerPlume = PowerInPlumes / NumberOfPlumes

    if state.afn.NumOfLinksMultiZone > 0:
        for Loop in range(1, state.dataRoomAir.AFNSurfaceCrossVent(0, ZoneNum) + 1):
            var afnSurfNum = state.dataRoomAir.AFNSurfaceCrossVent(Loop, ZoneNum)
            let surfParams = state.dataRoomAir.SurfParametersCrossDispVent[afnSurfNum-1]
            let afnLinkSimu = state.afn.AirflowNetworkLinkSimu[afnSurfNum-1]
            let afnMzSurfData = state.afn.MultizoneSurfaceData[afnSurfNum-1]
            let afnMzSurf = state.dataSurface.Surface[afnMzSurfData.SurfNum-1]
            if afnMzSurf.Zone == ZoneNum:
                if (surfParams.Zmax < 0.8 and afnLinkSimu.VolFLOW > 0):
                    FlagApertures = 0
                    break
                if (surfParams.Zmin > 1.8 and afnLinkSimu.VolFLOW2 > 0):
                    FlagApertures = 0
                    break
                if (surfParams.Zmin > 0.8 and surfParams.Zmin < 1.8) or (surfParams.Zmax > 0.8 and surfParams.Zmax < 1.8):
                    FlagApertures = 0
                    break
            else:
                let afnZone = state.dataHeatBal.Zone[afnMzSurf.Zone-1]
                if (surfParams.Zmax + afnZone.OriginZ - zone.OriginZ < 0.8) and (afnLinkSimu.VolFLOW2 > 0):
                    FlagApertures = 0
                    break
                if (surfParams.Zmin + afnZone.OriginZ - zone.OriginZ > 1.8) and (afnLinkSimu.VolFLOW > 0):
                    FlagApertures = 0
                    break
                if ((surfParams.Zmin + afnZone.OriginZ - zone.OriginZ > 0.8 and surfParams.Zmin + afnZone.OriginZ - zone.OriginZ < 1.8) or \
                    (surfParams.Zmax + afnZone.OriginZ - zone.OriginZ > 0.8 and surfParams.Zmax + afnZone.OriginZ - zone.OriginZ < 1.8)):
                    FlagApertures = 0
                    break

    if (PowerInPlumes == 0.0) or (MCpT_Total == 0.0) or (FlagApertures == 0):
        HeightFrac = 0.0
    else:
        let plume_fac: Float64 = NumberOfPlumes * pow(PowerPerPlume, OneThird)
        HeightFrac = min(24.55 * pow(MCp_Total * 0.000833 / plume_fac, 0.6) / CeilingHeight, 1.0)
        for Ctd in range(1, 5):  # 1..4 inclusive
            HcDispVent3Node(state, ZoneNum, HeightFrac)
            state.dataRoomAir.HeightTransition(ZoneNum) = HeightFrac * CeilingHeight
            # AIRRAT calculations
            var hairrat: Float64 = min(state.dataRoomAir.HeightTransition(ZoneNum), state.dataDispVentMgr.HeightFloorSubzoneTop)
            state.dataRoomAir.AIRRATFloor(ZoneNum) = zone.Volume * hairrat / CeilingHeight * zone.ZoneVolCapMultpSens * \
                PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataRoomAir.MATFloor(ZoneNum), thisZoneHB.airHumRat) * \
                PsyCpAirFnW(thisZoneHB.airHumRat) / TimeStepSysSec
            var htransocc = state.dataRoomAir.HeightTransition(ZoneNum) - min(state.dataRoomAir.HeightTransition(ZoneNum), 0.2)
            state.dataRoomAir.AIRRATOC(ZoneNum) = zone.Volume * htransocc / CeilingHeight * zone.ZoneVolCapMultpSens * \
                PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataRoomAir.MATOC(ZoneNum), thisZoneHB.airHumRat) * \
                PsyCpAirFnW(thisZoneHB.airHumRat) / TimeStepSysSec
            state.dataRoomAir.AIRRATMX(ZoneNum) = zone.Volume * (CeilingHeight - state.dataRoomAir.HeightTransition(ZoneNum)) / CeilingHeight * \
                zone.ZoneVolCapMultpSens * \
                PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataRoomAir.MATMX(ZoneNum), thisZoneHB.airHumRat) * \
                PsyCpAirFnW(thisZoneHB.airHumRat) / TimeStepSysSec

            if state.dataHVACGlobal.UseZoneTimeStepHistory:
                state.dataRoomAir.ZTMFloor(ZoneNum)[2] = state.dataRoomAir.XMATFloor(ZoneNum)[2]
                state.dataRoomAir.ZTMFloor(ZoneNum)[1] = state.dataRoomAir.XMATFloor(ZoneNum)[1]
                state.dataRoomAir.ZTMFloor(ZoneNum)[0] = state.dataRoomAir.XMATFloor(ZoneNum)[0]
                state.dataRoomAir.ZTMOC(ZoneNum)[2] = state.dataRoomAir.XMATOC(ZoneNum)[2]
                state.dataRoomAir.ZTMOC(ZoneNum)[1] = state.dataRoomAir.XMATOC(ZoneNum)[1]
                state.dataRoomAir.ZTMOC(ZoneNum)[0] = state.dataRoomAir.XMATOC(ZoneNum)[0]
                state.dataRoomAir.ZTMMX(ZoneNum)[2] = state.dataRoomAir.XMATMX(ZoneNum)[2]
                state.dataRoomAir.ZTMMX(ZoneNum)[1] = state.dataRoomAir.XMATMX(ZoneNum)[1]
                state.dataRoomAir.ZTMMX(ZoneNum)[0] = state.dataRoomAir.XMATMX(ZoneNum)[0]
            else:
                state.dataRoomAir.ZTMFloor(ZoneNum)[2] = state.dataRoomAir.DSXMATFloor(ZoneNum)[2]
                state.dataRoomAir.ZTMFloor(ZoneNum)[1] = state.dataRoomAir.DSXMATFloor(ZoneNum)[1]
                state.dataRoomAir.ZTMFloor(ZoneNum)[0] = state.dataRoomAir.DSXMATFloor(ZoneNum)[0]
                state.dataRoomAir.ZTMOC(ZoneNum)[2] = state.dataRoomAir.DSXMATOC(ZoneNum)[2]
                state.dataRoomAir.ZTMOC(ZoneNum)[1] = state.dataRoomAir.DSXMATOC(ZoneNum)[1]
                state.dataRoomAir.ZTMOC(ZoneNum)[0] = state.dataRoomAir.DSXMATOC(ZoneNum)[0]
                state.dataRoomAir.ZTMMX(ZoneNum)[2] = state.dataRoomAir.DSXMATMX(ZoneNum)[2]
                state.dataRoomAir.ZTMMX(ZoneNum)[1] = state.dataRoomAir.DSXMATMX(ZoneNum)[1]
                state.dataRoomAir.ZTMMX(ZoneNum)[0] = state.dataRoomAir.DSXMATMX(ZoneNum)[0]

            # Floor subzone temperature calculation
            var AirCap = state.dataRoomAir.AIRRATFloor(ZoneNum)
            TempHistTerm = AirCap * (3.0 * state.dataRoomAir.ZTMFloor(ZoneNum)[0] - (3.0 / 2.0) * state.dataRoomAir.ZTMFloor(ZoneNum)[1] + \
                                     OneThird * state.dataRoomAir.ZTMFloor(ZoneNum)[2])
            TempDepCoef = state.dataDispVentMgr.HA_FLOOR + MCp_Total
            TempIndCoef = state.dataDispVentMgr.HAT_FLOOR + MCpT_Total + thisZoneHB.NonAirSystemResponse / ZoneMult
            match state.dataHeatBal.ZoneAirSolutionAlgo:
                case SolutionAlgo.ThirdOrder:
                    state.dataRoomAir.ZTFloor(ZoneNum) = calculateThirdOrderFloorTemperature(
                        TempHistTerm,
                        state.dataDispVentMgr.HAT_FLOOR,
                        state.dataDispVentMgr.HA_FLOOR,
                        MCpT_Total,
                        MCp_Total,
                        state.dataRoomAir.ZTOC(ZoneNum),
                        thisZoneHB.NonAirSystemResponse,
                        ZoneMult,
                        AirCap
                    )
                case SolutionAlgo.AnalyticalSolution:
                    if TempDepCoef == 0.0:
                        state.dataRoomAir.ZTFloor(ZoneNum) = state.dataRoomAir.Zone1Floor(ZoneNum) + TempIndCoef / AirCap
                    else:
                        state.dataRoomAir.ZTFloor(ZoneNum) = (state.dataRoomAir.Zone1Floor(ZoneNum) - TempIndCoef / TempDepCoef) * \
                            exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
                case SolutionAlgo.EulerMethod:
                    state.dataRoomAir.ZTFloor(ZoneNum) = (AirCap * state.dataRoomAir.Zone1Floor(ZoneNum) + TempIndCoef) / (AirCap + TempDepCoef)
                case _:

            # Occupied subzone temperature calculation
            AirCap = state.dataRoomAir.AIRRATOC(ZoneNum)
            TempHistTerm = AirCap * (3.0 * state.dataRoomAir.ZTMOC(ZoneNum)[0] - (3.0 / 2.0) * state.dataRoomAir.ZTMOC(ZoneNum)[1] + \
                                     OneThird * state.dataRoomAir.ZTMOC(ZoneNum)[2])
            TempDepCoef = state.dataDispVentMgr.HA_OC + MCp_Total
            TempIndCoef = ConvGainsOccupiedSubzone * GainsFrac + state.dataDispVentMgr.HAT_OC + state.dataRoomAir.ZTFloor(ZoneNum) * MCp_Total
            match state.dataHeatBal.ZoneAirSolutionAlgo:
                case SolutionAlgo.ThirdOrder:
                    state.dataRoomAir.ZTOC(ZoneNum) = (TempHistTerm + ConvGainsOccupiedSubzone * GainsFrac + state.dataDispVentMgr.HAT_OC + \
                                                        1.6 * state.dataRoomAir.ZTFloor(ZoneNum) * MCp_Total) / \
                                                     ((11.0 / 6.0) * AirCap + state.dataDispVentMgr.HA_OC + 1.6 * MCp_Total)
                case SolutionAlgo.AnalyticalSolution:
                    if TempDepCoef == 0.0:
                        state.dataRoomAir.ZTOC(ZoneNum) = state.dataRoomAir.Zone1OC(ZoneNum) + TempIndCoef / AirCap
                    else:
                        if AirCap == 0.0:
                            state.dataRoomAir.ZTOC(ZoneNum) = TempIndCoef / TempDepCoef
                        else:
                            state.dataRoomAir.ZTOC(ZoneNum) = (state.dataRoomAir.Zone1OC(ZoneNum) - TempIndCoef / TempDepCoef) * \
                                exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
                case SolutionAlgo.EulerMethod:
                    state.dataRoomAir.ZTOC(ZoneNum) = (AirCap * state.dataRoomAir.Zone1OC(ZoneNum) + TempIndCoef) / (AirCap + TempDepCoef)
                case _:

            # Mixed subzone temperature calculation
            AirCap = state.dataRoomAir.AIRRATMX(ZoneNum)
            TempHistTerm = AirCap * (3.0 * state.dataRoomAir.ZTMMX(ZoneNum)[0] - (3.0 / 2.0) * state.dataRoomAir.ZTMMX(ZoneNum)[1] + \
                                     OneThird * state.dataRoomAir.ZTMMX(ZoneNum)[2])
            TempDepCoef = state.dataDispVentMgr.HA_MX + MCp_Total
            TempIndCoef = ConvGainsOccupiedSubzone * (1.0 - GainsFrac) + ConvGainsMixedSubzone + state.dataDispVentMgr.HAT_MX + \
                          state.dataRoomAir.ZTOC(ZoneNum) * MCp_Total
            match state.dataHeatBal.ZoneAirSolutionAlgo:
                case SolutionAlgo.ThirdOrder:
                    state.dataRoomAir.ZTMX(ZoneNum) = (TempHistTerm + ConvGainsOccupiedSubzone * (1.0 - GainsFrac) + ConvGainsMixedSubzone + \
                                                       state.dataDispVentMgr.HAT_MX + state.dataRoomAir.ZTOC(ZoneNum) * MCp_Total) / \
                                                     ((11.0 / 6.0) * AirCap + state.dataDispVentMgr.HA_MX + MCp_Total)
                case SolutionAlgo.AnalyticalSolution:
                    if TempDepCoef == 0.0:
                        state.dataRoomAir.ZTMX(ZoneNum) = state.dataRoomAir.Zone1MX(ZoneNum) + TempIndCoef / AirCap
                    else:
                        if AirCap == 0.0:
                            state.dataRoomAir.ZTMX(ZoneNum) = TempIndCoef / TempDepCoef
                        else:
                            state.dataRoomAir.ZTMX(ZoneNum) = (state.dataRoomAir.Zone1MX(ZoneNum) - TempIndCoef / TempDepCoef) * \
                                exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
                case SolutionAlgo.EulerMethod:
                    state.dataRoomAir.ZTMX(ZoneNum) = (AirCap * state.dataRoomAir.Zone1MX(ZoneNum) + TempIndCoef) / (AirCap + TempDepCoef)
                case _:

        # End of iteration loop

        MinFlow = MinFlow_pow_fac * plume_fac
        if MinFlow != 0.0:
            state.dataRoomAir.FracMinFlow(ZoneNum) = MCp_Total * 0.000833 / MinFlow
        else:
            state.dataRoomAir.FracMinFlow(ZoneNum) = 9.999
        state.dataRoomAir.AirModel(ZoneNum-1).SimAirModel = True   # 0-based access

    # Check for mixing condition
    if (state.dataRoomAir.ZTMX(ZoneNum) < state.dataRoomAir.ZTOC(ZoneNum)) or (MCp_Total <= 0.0) or \
       (HeightFrac * CeilingHeight < (state.dataDispVentMgr.HeightFloorSubzoneTop + state.dataDispVentMgr.ThickOccupiedSubzoneMin)):
        MIXFLAG = True
        HeightFrac = 0.0
        state.dataRoomAir.AvgTempGrad(ZoneNum) = 0.0
        state.dataRoomAir.MaxTempGrad(ZoneNum) = 0.0
        state.dataRoomAir.AirModel(ZoneNum-1).SimAirModel = False
        let thisZoneT1 = thisZoneHB.T1
        var AirCap = thisZoneHB.AirPowerCap
        TempHistTerm = AirCap * (3.0 * thisZoneHB.ZTM[0] - (3.0 / 2.0) * thisZoneHB.ZTM[1] + OneThird * thisZoneHB.ZTM[2])
        for Ctd in range(1, 4):  # 1..3
            TempDepCoef = state.dataDispVentMgr.HA_MX + state.dataDispVentMgr.HA_OC + state.dataDispVentMgr.HA_FLOOR + MCp_Total
            TempIndCoef = ConvGains + state.dataDispVentMgr.HAT_MX + state.dataDispVentMgr.HAT_OC + state.dataDispVentMgr.HAT_FLOOR + MCpT_Total
            match state.dataHeatBal.ZoneAirSolutionAlgo:
                case SolutionAlgo.ThirdOrder:
                    ZTAveraged = (TempHistTerm + ConvGains + state.dataDispVentMgr.HAT_MX + state.dataDispVentMgr.HAT_OC + \
                                  state.dataDispVentMgr.HAT_FLOOR + MCpT_Total) / \
                                ((11.0 / 6.0) * AirCap + state.dataDispVentMgr.HA_MX + state.dataDispVentMgr.HA_OC + \
                                 state.dataDispVentMgr.HA_FLOOR + MCp_Total)
                case SolutionAlgo.AnalyticalSolution:
                    if TempDepCoef == 0.0:
                        ZTAveraged = thisZoneT1 + TempIndCoef / AirCap
                    else:
                        ZTAveraged = (thisZoneT1 - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
                case SolutionAlgo.EulerMethod:
                    ZTAveraged = (AirCap * thisZoneT1 + TempIndCoef) / (AirCap + TempDepCoef)
                case _:

            state.dataRoomAir.ZTOC(ZoneNum) = ZTAveraged
            state.dataRoomAir.ZTMX(ZoneNum) = ZTAveraged
            state.dataRoomAir.ZTFloor(ZoneNum) = ZTAveraged
            HcDispVent3Node(state, ZoneNum, HeightFrac)
            # Recompute coefficients after Hc update
            TempDepCoef = state.dataDispVentMgr.HA_MX + state.dataDispVentMgr.HA_OC + state.dataDispVentMgr.HA_FLOOR + MCp_Total
            TempIndCoef = ConvGains + state.dataDispVentMgr.HAT_MX + state.dataDispVentMgr.HAT_OC + state.dataDispVentMgr.HAT_FLOOR + MCpT_Total
            match state.dataHeatBal.ZoneAirSolutionAlgo:
                case SolutionAlgo.ThirdOrder:
                    ZTAveraged = (TempHistTerm + ConvGains + state.dataDispVentMgr.HAT_MX + state.dataDispVentMgr.HAT_OC + \
                                  state.dataDispVentMgr.HAT_FLOOR + MCpT_Total) / \
                                ((11.0 / 6.0) * AirCap + state.dataDispVentMgr.HA_MX + state.dataDispVentMgr.HA_OC + \
                                 state.dataDispVentMgr.HA_FLOOR + MCp_Total)
                case SolutionAlgo.AnalyticalSolution:
                    if TempDepCoef == 0.0:
                        ZTAveraged = thisZoneT1 + TempIndCoef / AirCap
                    else:
                        ZTAveraged = (thisZoneT1 - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
                case SolutionAlgo.EulerMethod:
                    ZTAveraged = (AirCap * thisZoneT1 + TempIndCoef) / (AirCap + TempDepCoef)
                case _:

            state.dataRoomAir.ZTOC(ZoneNum) = ZTAveraged
            state.dataRoomAir.ZTMX(ZoneNum) = ZTAveraged
            state.dataRoomAir.ZTFloor(ZoneNum) = ZTAveraged

    state.dataRoomAir.HeightTransition(ZoneNum) = HeightFrac * CeilingHeight
    HeightMixedSubzoneAve = (CeilingHeight + state.dataRoomAir.HeightTransition(ZoneNum)) / 2.0
    HeightOccupiedSubzoneAve = (state.dataDispVentMgr.HeightFloorSubzoneTop + state.dataRoomAir.HeightTransition(ZoneNum)) / 2.0
    HeightFloorSubzoneAve = state.dataDispVentMgr.HeightFloorSubzoneTop / 2.0

    if MIXFLAG:
        state.dataRoomAir.TCMF(ZoneNum) = ZTAveraged
    else:
        if HeightComfort >= 0.0 and HeightComfort < HeightFloorSubzoneAve:
            ShowWarningError(state, String.format("Displacement ventilation comfort height is in floor subzone in Zone: {}", zone.Name))
            state.dataRoomAir.TCMF(ZoneNum) = state.dataRoomAir.ZTFloor(ZoneNum)
        elif HeightComfort >= HeightFloorSubzoneAve and HeightComfort < HeightOccupiedSubzoneAve:
            state.dataRoomAir.TCMF(ZoneNum) = (state.dataRoomAir.ZTFloor(ZoneNum) * (HeightOccupiedSubzoneAve - HeightComfort) + \
                                               state.dataRoomAir.ZTOC(ZoneNum) * (HeightComfort - HeightFloorSubzoneAve)) / \
                                              (HeightOccupiedSubzoneAve - HeightFloorSubzoneAve)
        elif HeightComfort >= HeightOccupiedSubzoneAve and HeightComfort < HeightMixedSubzoneAve:
            state.dataRoomAir.TCMF(ZoneNum) = (state.dataRoomAir.ZTOC(ZoneNum) * (HeightMixedSubzoneAve - HeightComfort) + \
                                               state.dataRoomAir.ZTMX(Zone
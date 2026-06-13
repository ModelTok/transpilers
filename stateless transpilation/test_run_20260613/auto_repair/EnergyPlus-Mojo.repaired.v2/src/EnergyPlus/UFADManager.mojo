# Mojo translation of EnergyPlus UFADManager.cc

from DataEnvironment import *
from DataHeatBalance import *
from DataHeatBalSurface import *
from DataSurfaces import *
from ConvectionCoefficients import CalcDetailedHcInForDVModel
from Psychrometrics import PsyCpAirFnW, PsyRhoAirFnPbTdbW
from InternalHeatGains import SumInternalConvectionGainsByTypes, SumReturnAirConvectionGainsByTypes
from DataSizing import AutoSize
from Constant import AutoCalculate, Kelvin, DegToRad
from General import *
from UtilityRoutines import ShowWarningError, ShowContinueError, ShowFatalError
from BaseSizing import BaseSizer

struct UFADConvCoef:
    var HAT_MX: Float64 = 0.0
    var HAT_MXWin: Float64 = 0.0
    var HA_MX: Float64 = 0.0
    var HA_MXWin: Float64 = 0.0
    var HAT_OC: Float64 = 0.0
    var HAT_OCWin: Float64 = 0.0
    var HA_OC: Float64 = 0.0
    var HA_OCWin: Float64 = 0.0
    var HAT_FLOOR: Float64 = 0.0
    var HA_FLOOR: Float64 = 0.0

struct UFADManagerData(BaseGlobalStruct):
    var HeightFloorSubzoneTop: Float64 = 0.2
    var ThickOccupiedSubzoneMin: Float64 = 0.2
    var HeightIntMass: Float64 = 0.0
    var HeightIntMassDefault: Float64 = 2.0
    var MyOneTimeFlag: Bool = True
    var MySizeFlag: List[Bool]  # dynamic array, will resize

    def init_constant_state(inout self, state: EnergyPlusData): pass

    def init_state(inout self, state: EnergyPlusData): pass

    def clear_state(inout self):
        self.MyOneTimeFlag = True
        self.MySizeFlag = List[Bool]()  # deallocate equivalent

    def __init__(inout self):
        self.MySizeFlag = List[Bool]()

# forward declarations inside namespace RoomAir
def sumUFADConvGainPerPlume(state: EnergyPlusData, zoneNum: Int, numOccupants: Float64) -> Float64

def ManageUFAD(inout state: EnergyPlusData, ZoneNum: Int, ZoneModelType: RoomAirModel)
def InitUFAD(inout state: EnergyPlusData, ZoneNum: Int, ZoneModelType: RoomAirModel)
def SizeUFAD(inout state: EnergyPlusData, ZoneNum: Int, ZoneModelType: RoomAirModel)
def HcUFAD(inout state: EnergyPlusData, ZoneNum: Int, FractionHeight: Float64, inout ufadCC: UFADConvCoef)
def CalcUFADInt(inout state: EnergyPlusData, ZoneNum: Int)
def CalcUFADExt(inout state: EnergyPlusData, ZoneNum: Int)

def ManageUFAD(inout state: EnergyPlusData, ZoneNum: Int, ZoneModelType: RoomAirModel):
    InitUFAD(state, ZoneNum, ZoneModelType)
    if ZoneModelType == RoomAirModel.UFADInt:
        CalcUFADInt(state, ZoneNum)
    elif ZoneModelType == RoomAirModel.UFADExt:
        CalcUFADExt(state, ZoneNum)
    else:

def InitUFAD(inout state: EnergyPlusData, ZoneNum: Int, ZoneModelType: RoomAirModel):
    var NumShadesDown: Float64 = 0.0
    if state.dataUFADManager.MyOneTimeFlag:
        state.dataUFADManager.HeightFloorSubzoneTop = 0.2
        state.dataUFADManager.ThickOccupiedSubzoneMin = 0.2
        state.dataUFADManager.HeightIntMassDefault = 2.0
        state.dataUFADManager.MyOneTimeFlag = False
        state.dataUFADManager.MySizeFlag = List[Bool](state.dataGlobal.NumOfZones, True)
    if state.dataUFADManager.MySizeFlag[ZoneNum]:  # 0-based index
        SizeUFAD(state, ZoneNum, ZoneModelType)
        state.dataUFADManager.MySizeFlag[ZoneNum] = False
    state.dataUFADManager.HeightIntMass = state.dataUFADManager.HeightIntMassDefault
    state.dataRoomAir.ZoneUFADGamma[ZoneNum] = 0.0
    state.dataRoomAir.ZoneUFADPowInPlumes[ZoneNum] = 0.0
    NumShadesDown = 0.0
    let wbeg = state.dataRoomAir.PosZ_Window[ZoneNum].beg - 1
    let wend = state.dataRoomAir.PosZ_Window[ZoneNum].end - 1
    for Ctd in range(wbeg, wend+1):
        let SurfNum = state.dataRoomAir.APos_Window[Ctd]
        if SurfNum == 0:
            continue
        let surf = state.dataSurface.Surface[SurfNum]
        if surf.ExtBoundCond == ExternalEnvironment or surf.ExtBoundCond == OtherSideCoefNoCalcExt or \
           surf.ExtBoundCond == OtherSideCoefCalcExt or surf.ExtBoundCond == OtherSideCondModeledExt:
            if ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag[SurfNum]):
                NumShadesDown += 1.0
    if ZoneModelType == RoomAirModel.UFADExt:
        let zoneUE = state.dataRoomAir.ZoneUFAD[state.dataRoomAir.ZoneUFADPtr[ZoneNum]]
        zoneUE.ShadeDown = (zoneUE.NumExtWin > 1.0) and (NumShadesDown / zoneUE.NumExtWin >= 0.5)

def SizeUFAD(inout state: EnergyPlusData, ZoneNum: Int, model: RoomAirModel):
    let zoneU = state.dataRoomAir.ZoneUFAD[state.dataRoomAir.ZoneUFADPtr[ZoneNum]]
    var cCMO: StringLiteral = "RoomAirSettings:UnderFloorAirDistributionExterior" if model == RoomAirModel.UFADExt \
                              else "RoomAirSettings:UnderFloorAirDistributionInterior"
    var NumberOfOccupants: Float64 = 0.0
    for people in state.dataHeatBal.People:
        if people.ZonePtr == ZoneNum:
            NumberOfOccupants += people.NumberOfPeople
    if model == RoomAirModel.UFADExt:
        let wbeg = state.dataRoomAir.PosZ_Window[ZoneNum].beg - 1
        let wend = state.dataRoomAir.PosZ_Window[ZoneNum].end - 1
        for Ctd in range(wbeg, wend+1):
            let SurfNum = state.dataRoomAir.APos_Window[Ctd]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum]
            if surf.ExtBoundCond == ExternalEnvironment or surf.ExtBoundCond == OtherSideCoefNoCalcExt or \
               surf.ExtBoundCond == OtherSideCoefCalcExt or surf.ExtBoundCond == OtherSideCondModeledExt:
                zoneU.WinWidth += surf.Width
                zoneU.NumExtWin += 1
        if zoneU.WinWidth <= 0.0:
            ShowWarningError(state, "For RoomAirSettings:UnderFloorAirDistributionExterior for Zone {} there are no exterior windows.".format(zoneU.ZoneName))
            ShowContinueError(state, "  The zone will be treated as a UFAD interior zone")
    if zoneU.DiffArea == AutoSize:
        var diffArea: StaticArray[Float64, Int(Diffuser.Num)] = [0.0075, 0.035, 0.0060, 0.03, 0.0075]
        zoneU.DiffArea = diffArea[Int(zoneU.DiffuserType)]
        BaseSizer.reportSizerOutput(state, cCMO, zoneU.ZoneName, "Design effective area of diffuser", zoneU.DiffArea)
    if zoneU.DiffAngle == AutoSize:
        var diffAngle: StaticArray[Float64, Int(Diffuser.Num)] = [28.0, 45.0, 73.0, 15.0, 28.0]
        zoneU.DiffAngle = diffAngle[Int(zoneU.DiffuserType)]
        BaseSizer.reportSizerOutput(state, cCMO, zoneU.ZoneName, "Angle between diffuser slots and the vertical", zoneU.DiffAngle)
    if zoneU.TransHeight == AutoSize:
        zoneU.CalcTransHeight = True
        zoneU.TransHeight = 0.0
    else:
        zoneU.CalcTransHeight = False
    if zoneU.DiffuserType != Diffuser.Custom and \
       (zoneU.A_Kc != AutoCalculate or zoneU.B_Kc != AutoCalculate or zoneU.C_Kc != AutoCalculate or \
        zoneU.D_Kc != AutoCalculate or zoneU.E_Kc != AutoCalculate):
        ShowWarningError(state, "For {} for Zone {}, input for Coefficients A - E will be ignored when Floor Diffuser Type = {}.".format(cCMO, zoneU.ZoneName, diffuserNamesUC[Int(zoneU.DiffuserType)]))
        ShowContinueError(state, "  To input these Coefficients, use Floor Diffuser Type = Custom.")
    if zoneU.DiffuserType == Diffuser.Swirl:
        zoneU.A_Kc = 0.0
        zoneU.B_Kc = 0.0
        zoneU.C_Kc = 0.6531
        zoneU.D_Kc = 0.0069
        zoneU.E_Kc = -0.00004
    elif zoneU.DiffuserType == Diffuser.VarArea:
        zoneU.A_Kc = 0.0
        zoneU.B_Kc = 0.0
        zoneU.C_Kc = 0.83 if model == RoomAirModel.UFADExt else 0.88
        zoneU.D_Kc = 0.0
        zoneU.E_Kc = 0.0
    elif zoneU.DiffuserType == Diffuser.DisplVent:
        zoneU.A_Kc = 0.0
        zoneU.B_Kc = 0.0
        zoneU.C_Kc = 0.67
        zoneU.D_Kc = 0.0
        zoneU.E_Kc = 0.0
    elif zoneU.DiffuserType == Diffuser.LinBarGrille:
        zoneU.A_Kc = 0.0
        zoneU.B_Kc = 0.0
        zoneU.C_Kc = 0.8214 if model == RoomAirModel.UFADExt else 0.8
        zoneU.D_Kc = -0.0263 if model == RoomAirModel.UFADExt else 0.0
        zoneU.E_Kc = 0.0014 if model == RoomAirModel.UFADExt else 0.0
    elif zoneU.A_Kc == AutoCalculate or zoneU.B_Kc == AutoCalculate or zoneU.C_Kc == AutoCalculate or \
         zoneU.D_Kc == AutoCalculate or zoneU.E_Kc == AutoCalculate:
        ShowFatalError(state, "For {} for Zone {}, input for Coefficients A - E must be specified when Floor Diffuser Type = Custom.".format(cCMO, zoneU.ZoneName))
    if zoneU.PowerPerPlume == AutoCalculate:
        zoneU.PowerPerPlume = sumUFADConvGainPerPlume(state, ZoneNum, NumberOfOccupants)
        BaseSizer.reportSizerOutput(state, cCMO, zoneU.ZoneName, "Power per plume [W]", zoneU.PowerPerPlume)
        if zoneU.DiffusersPerZone == AutoSize:
            zoneU.DiffusersPerZone = NumberOfOccupants if NumberOfOccupants > 0.0 else 1.0
            BaseSizer.reportSizerOutput(state, cCMO, zoneU.ZoneName, "Number of diffusers per zone", zoneU.DiffusersPerZone)
    if zoneU.DiffusersPerZone == AutoSize:
        zoneU.DiffusersPerZone = NumberOfOccupants if NumberOfOccupants > 0.0 else 1.0
        BaseSizer.reportSizerOutput(state, cCMO, zoneU.ZoneName, "Number of diffusers per zone", zoneU.DiffusersPerZone)

def sumUFADConvGainPerPlume(state: EnergyPlusData, zoneNum: Int, numOccupants: Float64) -> Float64:
    var zoneElecConv: Float64 = 0.0
    for zoneElectric in state.dataHeatBal.ZoneElectric:
        if zoneElectric.ZonePtr == zoneNum:
            zoneElecConv += zoneElectric.DesignLevel * zoneElectric.FractionConvected
    var zoneGasConv: Float64 = 0.0
    for zoneGas in state.dataHeatBal.ZoneGas:
        if zoneGas.ZonePtr == zoneNum:
            zoneGasConv += zoneGas.DesignLevel * zoneGas.FractionConvected
    var zoneOthEqConv: Float64 = 0.0
    for zoneOtherEq in state.dataHeatBal.ZoneOtherEq:
        if zoneOtherEq.ZonePtr == zoneNum:
            zoneOthEqConv += zoneOtherEq.DesignLevel * zoneOtherEq.FractionConvected
    var zoneHWEqConv: Float64 = 0.0
    for zoneHWEq in state.dataHeatBal.ZoneHWEq:
        if zoneHWEq.ZonePtr == zoneNum:
            zoneHWEqConv += zoneHWEq.DesignLevel * zoneHWEq.FractionConvected
    var zoneSteamEqConv: Float64 = 0.0
    for zoneSteamEq in state.dataHeatBal.ZoneSteamEq:
        if zoneSteamEq.ZonePtr == zoneNum:
            zoneSteamEqConv += zoneSteamEq.DesignLevel * zoneSteamEq.FractionConvected
    var numPlumes: Float64 = numOccupants if numOccupants > 0.0 else 1.0
    return (numOccupants * 73.0 + zoneElecConv + zoneGasConv + zoneOthEqConv + zoneHWEqConv + zoneSteamEqConv) / numPlumes

def HcUFAD(inout state: EnergyPlusData, ZoneNum: Int, FractionHeight: Float64, inout ufadCC: UFADConvCoef):
    if not state.dataRoomAir.IsZoneUFAD[ZoneNum]:
        return
    ufadCC.HAT_MX = 0.0
    ufadCC.HAT_MXWin = 0.0
    ufadCC.HA_MX = 0.0
    ufadCC.HA_MXWin = 0.0
    ufadCC.HAT_OC = 0.0
    ufadCC.HAT_OCWin = 0.0
    ufadCC.HA_OC = 0.0
    ufadCC.HA_OCWin = 0.0
    ufadCC.HAT_FLOOR = 0.0
    ufadCC.HA_FLOOR = 0.0
    var zoneCeilingHeight1 = state.dataRoomAir.ZoneCeilingHeight1[ZoneNum]
    var zoneCeilingHeight2 = state.dataRoomAir.ZoneCeilingHeight2[ZoneNum]
    var LayH = FractionHeight * (zoneCeilingHeight2 - zoneCeilingHeight1)
    # WALL loop
    let wbeg = state.dataRoomAir.PosZ_Wall[ZoneNum].beg - 1
    let wend = state.dataRoomAir.PosZ_Wall[ZoneNum].end - 1
    for Ctd in range(wbeg, wend+1):
        let SurfNum = state.dataRoomAir.APos_Wall[Ctd]
        if SurfNum == 0:
            continue
        var surf = state.dataSurface.Surface[SurfNum]
        state.dataSurface.SurfTAirRef[SurfNum] = DataSurfaces.RefAirTemp.AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[SurfNum] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum]]
        var ZSupSurf = maxval(surf.Vertex, lambda v: v.z) - zoneCeilingHeight1
        var ZInfSurf = minval(surf.Vertex, lambda v: v.z) - zoneCeilingHeight1
        if ZInfSurf > LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            state.dataRoomAir.HWall[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
            ufadCC.HAT_MX += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWall[Ctd]
            ufadCC.HA_MX += surf.Area * state.dataRoomAir.HWall[Ctd]
        if ZSupSurf < LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            state.dataRoomAir.HWall[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
            ufadCC.HAT_OC += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWall[Ctd]
            ufadCC.HA_OC += surf.Area * state.dataRoomAir.HWall[Ctd]
        if abs(ZInfSurf - ZSupSurf) < 1e-10:
            ShowSevereError(state, "RoomAirModelUFAD:HcUCSDUF: Surface values will cause divide by zero.")
            ShowContinueError(state, "Zone=\"{}\", Surface=\"{}\".".format(state.dataHeatBal.Zone[surf.Zone].Name, surf.Name))
            ShowContinueError(state, "ZInfSurf=[{:.4R}], LayH=[{:.4R}].".format(ZInfSurf, LayH))
            ShowContinueError(state, "ZSupSurf=[{:.4R}], LayH=[{:.4R}].".format(ZSupSurf, LayH))
            ShowFatalError(state, "...Previous condition causes termination.")
        if ZInfSurf <= LayH and ZSupSurf >= LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            var HLU = state.dataRoomAir.UFADHcIn[SurfNum]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            var HLD = state.dataRoomAir.UFADHcIn[SurfNum]
            var TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX[ZoneNum] + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC[ZoneNum]) / (ZSupSurf - ZInfSurf)
            state.dataRoomAir.HWall[Ctd] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
            ufadCC.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLU
            ufadCC.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
            ufadCC.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLD
            ufadCC.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = TmedDV
        state.dataRoomAir.UFADHcIn[SurfNum] = state.dataRoomAir.HWall[Ctd]
    # WINDOW loop
    let wibeg = state.dataRoomAir.PosZ_Window[ZoneNum].beg - 1
    let wiend = state.dataRoomAir.PosZ_Window[ZoneNum].end - 1
    for Ctd in range(wibeg, wiend+1):
        let SurfNum = state.dataRoomAir.APos_Window[Ctd]
        if SurfNum == 0:
            continue
        var surf = state.dataSurface.Surface[SurfNum]
        state.dataSurface.SurfTAirRef[SurfNum] = DataSurfaces.RefAirTemp.AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[SurfNum] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum]]
        if surf.Tilt > 10.0 and surf.Tilt < 170.0:
            var ZSupSurf = maxval(surf.Vertex, lambda v: v.z) - zoneCeilingHeight1
            var ZInfSurf = minval(surf.Vertex, lambda v: v.z) - zoneCeilingHeight1
            if ZInfSurf > LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
                state.dataRoomAir.HWindow[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
                ufadCC.HAT_MX += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWindow[Ctd]
                ufadCC.HA_MX += surf.Area * state.dataRoomAir.HWindow[Ctd]
                ufadCC.HAT_MXWin += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWindow[Ctd]
                ufadCC.HA_MXWin += surf.Area * state.dataRoomAir.HWindow[Ctd]
            if ZSupSurf < LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
                state.dataRoomAir.HWindow[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
                ufadCC.HAT_OC += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWindow[Ctd]
                ufadCC.HA_OC += surf.Area * state.dataRoomAir.HWindow[Ctd]
                ufadCC.HAT_OCWin += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWindow[Ctd]
                ufadCC.HA_OCWin += surf.Area * state.dataRoomAir.HWindow[Ctd]
            if ZInfSurf <= LayH and ZSupSurf >= LayH:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
                var HLU = state.dataRoomAir.UFADHcIn[SurfNum]
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
                var HLD = state.dataRoomAir.UFADHcIn[SurfNum]
                var TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX[ZoneNum] + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC[ZoneNum]) / (ZSupSurf - ZInfSurf)
                state.dataRoomAir.HWindow[Ctd] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
                ufadCC.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLU
                ufadCC.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
                ufadCC.HAT_MXWin += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLU
                ufadCC.HA_MXWin += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
                ufadCC.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLD
                ufadCC.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
                ufadCC.HAT_OCWin += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLD
                ufadCC.HA_OCWin += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = TmedDV
        if surf.Tilt <= 10.0:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            state.dataRoomAir.HWindow[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
            ufadCC.HAT_MX += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWindow[Ctd]
            ufadCC.HA_MX += surf.Area * state.dataRoomAir.HWindow[Ctd]
        elif surf.Tilt >= 170.0:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            state.dataRoomAir.HWindow[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
            ufadCC.HAT_OC += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HWindow[Ctd]
            ufadCC.HA_OC += surf.Area * state.dataRoomAir.HWindow[Ctd]
        state.dataRoomAir.UFADHcIn[SurfNum] = state.dataRoomAir.HWindow[Ctd]
    # DOOR loop
    let dbeg = state.dataRoomAir.PosZ_Door[ZoneNum].beg - 1
    let dend = state.dataRoomAir.PosZ_Door[ZoneNum].end - 1
    for Ctd in range(dbeg, dend+1):
        let SurfNum = state.dataRoomAir.APos_Door[Ctd]
        if SurfNum == 0:
            continue
        var surf = state.dataSurface.Surface[SurfNum]
        state.dataSurface.SurfTAirRef[SurfNum] = DataSurfaces.RefAirTemp.AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[SurfNum] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum]]
        var ZSupSurf = maxval(surf.Vertex, lambda v: v.z) - zoneCeilingHeight1
        var ZInfSurf = minval(surf.Vertex, lambda v: v.z) - zoneCeilingHeight1
        if ZInfSurf > LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            state.dataRoomAir.HDoor[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
            ufadCC.HAT_MX += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HDoor[Ctd]
            ufadCC.HA_MX += surf.Area * state.dataRoomAir.HDoor[Ctd]
        if ZSupSurf < LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            state.dataRoomAir.HDoor[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
            ufadCC.HAT_OC += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HDoor[Ctd]
            ufadCC.HA_OC += surf.Area * state.dataRoomAir.HDoor[Ctd]
        if ZInfSurf <= LayH and ZSupSurf >= LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            var HLU = state.dataRoomAir.UFADHcIn[SurfNum]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            var HLD = state.dataRoomAir.UFADHcIn[SurfNum]
            var TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX[ZoneNum] + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC[ZoneNum]) / (ZSupSurf - ZInfSurf)
            state.dataRoomAir.HDoor[Ctd] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
            ufadCC.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLU
            ufadCC.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
            ufadCC.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLD
            ufadCC.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = TmedDV
        state.dataRoomAir.UFADHcIn[SurfNum] = state.dataRoomAir.HDoor[Ctd]
    # INTERNAL mass
    state.dataUFADManager.HeightIntMass = min(state.dataUFADManager.HeightIntMassDefault, (zoneCeilingHeight2 - zoneCeilingHeight1))
    let ibeg = state.dataRoomAir.PosZ_Internal[ZoneNum].beg - 1
    let iend = state.dataRoomAir.PosZ_Internal[ZoneNum].end - 1
    for Ctd in range(ibeg, iend+1):
        let SurfNum = state.dataRoomAir.APos_Internal[Ctd]
        if SurfNum == 0:
            continue
        let surf = state.dataSurface.Surface[SurfNum]
        state.dataSurface.SurfTAirRef[SurfNum] = DataSurfaces.RefAirTemp.AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[SurfNum] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum]]
        var ZSupSurf = state.dataUFADManager.HeightIntMass
        var ZInfSurf = 0.0
        if ZSupSurf < LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            state.dataRoomAir.HInternal[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
            ufadCC.HAT_OC += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HInternal[Ctd]
            ufadCC.HA_OC += surf.Area * state.dataRoomAir.HInternal[Ctd]
        if ZInfSurf <= LayH and ZSupSurf >= LayH:
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            var HLU = state.dataRoomAir.UFADHcIn[SurfNum]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTOC[ZoneNum]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
            var HLD = state.dataRoomAir.UFADHcIn[SurfNum]
            var TmedDV = ((ZSupSurf - LayH) * state.dataRoomAir.ZTMX[ZoneNum] + (LayH - ZInfSurf) * state.dataRoomAir.ZTOC[ZoneNum]) / (ZSupSurf - ZInfSurf)
            state.dataRoomAir.HInternal[Ctd] = ((LayH - ZInfSurf) * HLD + (ZSupSurf - LayH) * HLU) / (ZSupSurf - ZInfSurf)
            ufadCC.HAT_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLU
            ufadCC.HA_MX += surf.Area * (ZSupSurf - LayH) / (ZSupSurf - ZInfSurf) * HLU
            ufadCC.HAT_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * state.dataHeatBalSurf.SurfTempIn[SurfNum] * HLD
            ufadCC.HA_OC += surf.Area * (LayH - ZInfSurf) / (ZSupSurf - ZInfSurf) * HLD
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = TmedDV
        state.dataRoomAir.UFADHcIn[SurfNum] = state.dataRoomAir.HInternal[Ctd]
    # CEILING loop
    let cbeg = state.dataRoomAir.PosZ_Ceiling[ZoneNum].beg - 1
    let cend = state.dataRoomAir.PosZ_Ceiling[ZoneNum].end - 1
    for Ctd in range(cbeg, cend+1):
        let SurfNum = state.dataRoomAir.APos_Ceiling[Ctd]
        if SurfNum == 0:
            continue
        let surf = state.dataSurface.Surface[SurfNum]
        state.dataSurface.SurfTAirRef[SurfNum] = DataSurfaces.RefAirTemp.AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[SurfNum] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum]]
        state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTMX[ZoneNum]
        CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
        state.dataRoomAir.HCeiling[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
        ufadCC.HAT_MX += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HCeiling[Ctd]
        ufadCC.HA_MX += surf.Area * state.dataRoomAir.HCeiling[Ctd]
        state.dataRoomAir.UFADHcIn[SurfNum] = state.dataRoomAir.HCeiling[Ctd]
    # FLOOR loop
    let fbeg = state.dataRoomAir.PosZ_Floor[ZoneNum].beg - 1
    let fend = state.dataRoomAir.PosZ_Floor[ZoneNum].end - 1
    for Ctd in range(fbeg, fend+1):
        let SurfNum = state.dataRoomAir.APos_Floor[Ctd]
        if SurfNum == 0:
            continue
        let surf = state.dataSurface.Surface[SurfNum]
        state.dataSurface.SurfTAirRef[SurfNum] = DataSurfaces.RefAirTemp.AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[SurfNum] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[SurfNum]]
        state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTFloor[ZoneNum]
        CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.UFADHcIn)
        state.dataRoomAir.HFloor[Ctd] = state.dataRoomAir.UFADHcIn[SurfNum]
        ufadCC.HAT_OC += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum] * state.dataRoomAir.HFloor[Ctd]
        ufadCC.HA_OC += surf.Area * state.dataRoomAir.HFloor[Ctd]
        state.dataHeatBal.SurfTempEffBulkAir[SurfNum] = state.dataRoomAir.ZTFloor[ZoneNum]
        state.dataRoomAir.UFADHcIn[SurfNum] = state.dataRoomAir.HFloor[Ctd]

var IntGainTypesOccupied: StaticArray[DataHeatBalance.IntGainType, 52] = [
    DataHeatBalance.IntGainType.People,
    DataHeatBalance.IntGainType.WaterHeaterMixed,
    DataHeatBalance.IntGainType.WaterHeaterStratified,
    DataHeatBalance.IntGainType.ThermalStorageChilledWaterMixed,
    DataHeatBalance.IntGainType.ThermalStorageChilledWaterStratified,
    DataHeatBalance.IntGainType.ThermalStorageHotWaterStratified,
    DataHeatBalance.IntGainType.ElectricEquipment,
    DataHeatBalance.IntGainType.ElectricEquipmentITEAirCooled,
    DataHeatBalance.IntGainType.GasEquipment,
    DataHeatBalance.IntGainType.HotWaterEquipment,
    DataHeatBalance.IntGainType.SteamEquipment,
    DataHeatBalance.IntGainType.OtherEquipment,
    DataHeatBalance.IntGainType.IndoorGreen,
    DataHeatBalance.IntGainType.ZoneBaseboardOutdoorTemperatureControlled,
    DataHeatBalance.IntGainType.GeneratorFuelCell,
    DataHeatBalance.IntGainType.WaterUseEquipment,
    DataHeatBalance.IntGainType.GeneratorMicroCHP,
    DataHeatBalance.IntGainType.ElectricLoadCenterTransformer,
    DataHeatBalance.IntGainType.ElectricLoadCenterInverterSimple,
    DataHeatBalance.IntGainType.ElectricLoadCenterInverterFunctionOfPower,
    DataHeatBalance.IntGainType.ElectricLoadCenterInverterLookUpTable,
    DataHeatBalance.IntGainType.ElectricLoadCenterStorageBattery,
    DataHeatBalance.IntGainType.ElectricLoadCenterStorageLiIonNmcBattery,
    DataHeatBalance.IntGainType.ElectricLoadCenterStorageSimple,
    DataHeatBalance.IntGainType.PipeIndoor,
    DataHeatBalance.IntGainType.RefrigerationCase,
    DataHeatBalance.IntGainType.RefrigerationCompressorRack,
    DataHeatBalance.IntGainType.RefrigerationSystemAirCooledCondenser,
    DataHeatBalance.IntGainType.RefrigerationSystemSuctionPipe,
    DataHeatBalance.IntGainType.RefrigerationSecondaryReceiver,
    DataHeatBalance.IntGainType.RefrigerationSecondaryPipe,
    DataHeatBalance.IntGainType.RefrigerationWalkIn,
    DataHeatBalance.IntGainType.RefrigerationTransSysAirCooledGasCooler,
    DataHeatBalance.IntGainType.RefrigerationTransSysSuctionPipeMT,
    DataHeatBalance.IntGainType.RefrigerationTransSysSuctionPipeLT,
    DataHeatBalance.IntGainType.Pump_VarSpeed,
    DataHeatBalance.IntGainType.Pump_ConSpeed,
    DataHeatBalance.IntGainType.Pump_Cond,
    DataHeatBalance.IntGainType.PumpBank_VarSpeed,
    DataHeatBalance.IntGainType.PumpBank_ConSpeed,
    DataHeatBalance.IntGainType.PlantComponentUserDefined,
    DataHeatBalance.IntGainType.CoilUserDefined,
    DataHeatBalance.IntGainType.ZoneHVACForcedAirUserDefined,
    DataHeatBalance.IntGainType.AirTerminalUserDefined,
    DataHeatBalance.IntGainType.PackagedTESCoilTank,
    DataHeatBalance.IntGainType.SecCoolingDXCoilSingleSpeed,
    DataHeatBalance.IntGainType.SecHeatingDXCoilSingleSpeed,
    DataHeatBalance.IntGainType.SecCoolingDXCoilTwoSpeed,
    DataHeatBalance.IntGainType.SecCoolingDXCoilMultiSpeed,
    DataHeatBalance.IntGainType.SecHeatingDXCoilMultiSpeed,
    DataHeatBalance.IntGainType.ElectricLoadCenterConverter,
    DataHeatBalance.IntGainType.FanSystemModel
]

var IntGainTypesUpSubzone: StaticArray[DataHeatBalance.IntGainType, 2] = [
    DataHeatBalance.IntGainType.DaylightingDeviceTubular,
    DataHeatBalance.IntGainType.Lights
]

var ExcludedIntGainTypes: StaticArray[DataHeatBalance.IntGainType, 2] = [
    DataHeatBalance.IntGainType.ZoneContaminantSourceAndSinkCarbonDioxide,
    DataHeatBalance.IntGainType.ZoneContaminantSourceAndSinkGenericContam
]

def CalcUFADInt(inout state: EnergyPlusData, ZoneNum: Int):
    var TimeStepSys = state.dataHVACGlobal.TimeStepSys
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    var HeightFrac: Float64
    var Gamma: Float64
    var ZTAveraged: Float64
    if state.dataHeatBal.ZoneAirSolutionAlgo != DataHeatBalance.SolutionAlgo.ThirdOrder:
        if state.dataHVACGlobal.ShortenTimeStepSysRoomAir and TimeStepSys < state.dataGlobal.TimeStepZone:
            if state.dataHVACGlobal.PreviousTimeStep < state.dataGlobal.TimeStepZone:
                state.dataRoomAir.Zone1OC[ZoneNum] = state.dataRoomAir.ZoneM2OC[ZoneNum]
                state.dataRoomAir.Zone1MX[ZoneNum] = state.dataRoomAir.ZoneM2MX[ZoneNum]
            else:
                state.dataRoomAir.Zone1OC[ZoneNum] = state.dataRoomAir.ZoneMXOC[ZoneNum]
                state.dataRoomAir.Zone1MX[ZoneNum] = state.dataRoomAir.ZoneMXMX[ZoneNum]
        else:
            state.dataRoomAir.Zone1OC[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
            state.dataRoomAir.Zone1MX[ZoneNum] = state.dataRoomAir.ZTMX[ZoneNum]
    var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum]
    var MIXFLAG = False
    state.dataRoomAir.UFADHcIn = state.dataHeatBalSurf.SurfHConvInt
    var SumSysMCp = 0.0
    var SumSysMCpT = 0.0
    var TSupK = 0.0
    var SumSysM = 0.0
    var TotSysFlow = 0.0
    var ZoneMult = state.dataHeatBal.Zone[ZoneNum].Multiplier * state.dataHeatBal.Zone[ZoneNum].ListMultiplier
    var CeilingHeight = state.dataRoomAir.ZoneCeilingHeight2[ZoneNum] - state.dataRoomAir.ZoneCeilingHeight1[ZoneNum]
    var zoneU = state.dataRoomAir.ZoneUFAD[state.dataRoomAir.ZoneUFADPtr[ZoneNum]]
    var HeightThermostat = zoneU.ThermostatHeight
    var HeightComfort = zoneU.ComfortHeight
    var TempDiffCritRep = zoneU.TempTrigger
    var DiffArea = zoneU.DiffArea
    var ThrowAngle = Constant.DegToRad * zoneU.DiffAngle
    var SourceHeight = 0.0
    var NumDiffusers = zoneU.DiffusersPerZone
    var PowerPerPlume = zoneU.PowerPerPlume
    var ConvGainsOccSubzone = SumInternalConvectionGainsByTypes(state, ZoneNum, IntGainTypesOccupied)
    if state.dataHeatBal.Zone[ZoneNum].NoHeatToReturnAir:
        ConvGainsOccSubzone += SumReturnAirConvectionGainsByTypes(state, ZoneNum, IntGainTypesOccupied)
    ConvGainsOccSubzone += state.dataHeatBalFanSys.SumConvPool[ZoneNum]
    var ConvGainsUpSubzone = SumInternalConvectionGainsByTypes(state, ZoneNum, IntGainTypesUpSubzone)
    ConvGainsUpSubzone += state.dataHeatBalFanSys.SumConvHTRadSys[ZoneNum]
    if state.dataHeatBal.Zone[ZoneNum].NoHeatToReturnAir:
        ConvGainsUpSubzone += SumReturnAirConvectionGainsByTypes(state, ZoneNum, IntGainTypesUpSubzone)
    assert(Int(IntGainTypesOccupied.size) + Int(IntGainTypesUpSubzone.size) + Int(ExcludedIntGainTypes.size) == Int(DataHeatBalance.IntGainType.Num))
    var ConvGains = ConvGainsOccSubzone + ConvGainsUpSubzone + thisZoneHB.SysDepZoneLoadsLagged
    var ZoneEquipConfigNum = zoneU.ZoneEquipPtr
    if ZoneEquipConfigNum > 0:
        let zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum]
        for InNodeIndex in range(0, zoneEquipConfig.NumInletNodes):
            var NodeTemp = state.dataLoopNodes.Node[zoneEquipConfig.InletNode[InNodeIndex]].Temp
            var MassFlowRate = state.dataLoopNodes.Node[zoneEquipConfig.InletNode[InNodeIndex]].MassFlowRate
            var CpAir = PsyCpAirFnW(thisZoneHB.airHumRat)
            SumSysMCp += MassFlowRate * CpAir
            SumSysMCpT += MassFlowRate * CpAir * NodeTemp
            TotSysFlow += MassFlowRate / PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, NodeTemp, thisZoneHB.airHumRat)
            TSupK += MassFlowRate * NodeTemp
            SumSysM += MassFlowRate
        if TotSysFlow > 0.0:
            TSupK = TSupK / SumSysM + Constant.Kelvin
        else:
            TSupK = 0.0
    var SumMCp = thisZoneHB.MCPI + thisZoneHB.MCPV + thisZoneHB.MCPM + thisZoneHB.MCPE + thisZoneHB.MCPC + thisZoneHB.MDotCPOA
    var SumMCpT = thisZoneHB.MCPTI + thisZoneHB.MCPTV + thisZoneHB.MCPTM + thisZoneHB.MCPTE + thisZoneHB.MCPTC + thisZoneHB.MDotCPOA * state.dataHeatBal.Zone[ZoneNum].OutDryBulbTemp
    var MCp_Total = SumMCp + SumSysMCp
    var MCpT_Total = SumMCpT + SumSysMCpT
    if zoneU.DiffuserType == Diffuser.VarArea:
        DiffArea = 0.035 * TotSysFlow / (0.0708 * NumDiffusers)
    var ufadCC = UFADConvCoef()
    HcUFAD(state, ZoneNum, 0.5, ufadCC)
    var PowerInPlumes = ConvGains + ufadCC.HAT_OC - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum] + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]
    var NumberOfPlumes = (PowerInPlumes / PowerPerPlume) if (PowerPerPlume > 0.0 and PowerInPlumes > 0.0) else 1.0
    var NumDiffusersPerPlume = (NumDiffusers / NumberOfPlumes) if (PowerPerPlume > 0.0 and PowerInPlumes > 0.0) else 1.0
    if (PowerInPlumes <= 0.0) or (TotSysFlow == 0.0) or (TSupK - Constant.Kelvin) > thisZoneHB.MAT:
        HeightFrac = 0.0
    else:
        Gamma = pow(TotSysFlow * cos(ThrowAngle), 1.5) / (NumberOfPlumes * pow(NumDiffusersPerPlume * DiffArea, 1.25) * sqrt(0.0281 * 0.001 * PowerInPlumes))
        if zoneU.CalcTransHeight:
            HeightFrac = (sqrt(NumDiffusersPerPlume * DiffArea) * (7.43 * log(Gamma) - 1.35) + 0.5 * SourceHeight) / CeilingHeight
        else:
            HeightFrac = zoneU.TransHeight / CeilingHeight
        HeightFrac = max(0.0, min(1.0, HeightFrac))
        for Ctd in range(0, 4):
            HcUFAD(state, ZoneNum, HeightFrac, ufadCC)
            PowerInPlumes = ConvGains + ufadCC.HAT_OC - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum] + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]
            if PowerPerPlume > 0.0 and PowerInPlumes > 0.0:
                NumberOfPlumes = PowerInPlumes / PowerPerPlume
                NumDiffusersPerPlume = NumDiffusers / NumberOfPlumes
            else:
                NumberOfPlumes = 1.0
                NumDiffusersPerPlume = 1.0
            if PowerInPlumes <= 0.0:
                break
            Gamma = pow(TotSysFlow * cos(ThrowAngle), 1.5) / (NumberOfPlumes * pow(NumDiffusersPerPlume * DiffArea, 1.25) * sqrt(0.0281 * 0.001 * PowerInPlumes))
            if zoneU.CalcTransHeight:
                HeightFrac = (sqrt(NumDiffusersPerPlume * DiffArea) * (7.43 * log(Gamma) - 1.35) + 0.5 * SourceHeight) / CeilingHeight
            else:
                HeightFrac = zoneU.TransHeight / CeilingHeight
            HeightFrac = max(0.0, min(1.0, HeightFrac))
            state.dataRoomAir.HeightTransition[ZoneNum] = HeightFrac * CeilingHeight
            var GainsFrac = zoneU.A_Kc * pow(Gamma, zoneU.B_Kc) + zoneU.C_Kc + zoneU.D_Kc * Gamma + zoneU.E_Kc * (Gamma * Gamma)
            GainsFrac = max(0.6, min(GainsFrac, 1.0))
            state.dataRoomAir.AIRRATOC[ZoneNum] = state.dataHeatBal.Zone[ZoneNum].Volume * (state.dataRoomAir.HeightTransition[ZoneNum] - min(state.dataRoomAir.HeightTransition[ZoneNum], 0.2)) / CeilingHeight * state.dataHeatBal.Zone[ZoneNum].ZoneVolCapMultpSens * PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataRoomAir.MATOC[ZoneNum], thisZoneHB.airHumRat) * PsyCpAirFnW(thisZoneHB.airHumRat) / TimeStepSysSec
            state.dataRoomAir.AIRRATMX[ZoneNum] = state.dataHeatBal.Zone[ZoneNum].Volume * (CeilingHeight - state.dataRoomAir.HeightTransition[ZoneNum]) / CeilingHeight * state.dataHeatBal.Zone[ZoneNum].ZoneVolCapMultpSens * PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataRoomAir.MATMX[ZoneNum], thisZoneHB.airHumRat) * PsyCpAirFnW(thisZoneHB.airHumRat) / TimeStepSysSec
            if state.dataHVACGlobal.UseZoneTimeStepHistory:
                state.dataRoomAir.ZTMOC[ZoneNum][2] = state.dataRoomAir.XMATOC[ZoneNum][2]
                state.dataRoomAir.ZTMOC[ZoneNum][1] = state.dataRoomAir.XMATOC[ZoneNum][1]
                state.dataRoomAir.ZTMOC[ZoneNum][0] = state.dataRoomAir.XMATOC[ZoneNum][0]
                state.dataRoomAir.ZTMMX[ZoneNum][2] = state.dataRoomAir.XMATMX[ZoneNum][2]
                state.dataRoomAir.ZTMMX[ZoneNum][1] = state.dataRoomAir.XMATMX[ZoneNum][1]
                state.dataRoomAir.ZTMMX[ZoneNum][0] = state.dataRoomAir.XMATMX[ZoneNum][0]
            else:
                state.dataRoomAir.ZTMOC[ZoneNum][2] = state.dataRoomAir.DSXMATOC[ZoneNum][2]
                state.dataRoomAir.ZTMOC[ZoneNum][1] = state.dataRoomAir.DSXMATOC[ZoneNum][1]
                state.dataRoomAir.ZTMOC[ZoneNum][0] = state.dataRoomAir.DSXMATOC[ZoneNum][0]
                state.dataRoomAir.ZTMMX[ZoneNum][2] = state.dataRoomAir.DSXMATMX[ZoneNum][2]
                state.dataRoomAir.ZTMMX[ZoneNum][1] = state.dataRoomAir.DSXMATMX[ZoneNum][1]
                state.dataRoomAir.ZTMMX[ZoneNum][0] = state.dataRoomAir.DSXMATMX[ZoneNum][0]
            var AirCap = state.dataRoomAir.AIRRATOC[ZoneNum]
            var TempHistTerm = AirCap * (3.0 * state.dataRoomAir.ZTMOC[ZoneNum][0] - (3.0 / 2.0) * state.dataRoomAir.ZTMOC[ZoneNum][1] + (1.0 / 3.0) * state.dataRoomAir.ZTMOC[ZoneNum][2])
            var TempDepCoef = GainsFrac * ufadCC.HA_OC + MCp_Total
            var TempIndCoef = GainsFrac * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]) + MCpT_Total + thisZoneHB.NonAirSystemResponse / ZoneMult
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                state.dataRoomAir.ZTOC[ZoneNum] = (TempHistTerm + GainsFrac * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]) + MCpT_Total + thisZoneHB.NonAirSystemResponse / ZoneMult) / ((11.0 / 6.0) * AirCap + GainsFrac * ufadCC.HA_OC + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    state.dataRoomAir.ZTOC[ZoneNum] = state.dataRoomAir.Zone1OC[ZoneNum] + TempIndCoef / AirCap
                else:
                    state.dataRoomAir.ZTOC[ZoneNum] = (state.dataRoomAir.Zone1OC[ZoneNum] - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                state.dataRoomAir.ZTOC[ZoneNum] = (AirCap * state.dataRoomAir.Zone1OC[ZoneNum] + TempIndCoef) / (AirCap + TempDepCoef)
            AirCap = state.dataRoomAir.AIRRATMX[ZoneNum]
            TempHistTerm = AirCap * (3.0 * state.dataRoomAir.ZTMMX[ZoneNum][0] - (3.0 / 2.0) * state.dataRoomAir.ZTMMX[ZoneNum][1] + (1.0 / 3.0) * state.dataRoomAir.ZTMMX[ZoneNum][2])
            TempDepCoef = (1.0 - GainsFrac) * ufadCC.HA_MX + MCp_Total
            TempIndCoef = (1.0 - GainsFrac) * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum]) + state.dataRoomAir.ZTOC[ZoneNum] * MCp_Total
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                state.dataRoomAir.ZTMX[ZoneNum] = (TempHistTerm + (1.0 - GainsFrac) * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum]) + state.dataRoomAir.ZTOC[ZoneNum] * MCp_Total) / ((11.0 / 6.0) * AirCap + (1.0 - GainsFrac) * ufadCC.HA_MX + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    state.dataRoomAir.ZTMX[ZoneNum] = state.dataRoomAir.Zone1MX[ZoneNum] + TempIndCoef / AirCap
                else:
                    state.dataRoomAir.ZTMX[ZoneNum] = (state.dataRoomAir.Zone1MX[ZoneNum] - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                state.dataRoomAir.ZTMX[ZoneNum] = (AirCap * state.dataRoomAir.Zone1MX[ZoneNum] + TempIndCoef) / (AirCap + TempDepCoef)
            state.dataRoomAir.ZTFloor[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
        if PowerInPlumes <= 0.0:
            HeightFrac = 0.0
            state.dataRoomAir.AirModel[ZoneNum].SimAirModel = False
            state.dataRoomAir.ZoneUFADGamma[ZoneNum] = 0.0
            state.dataRoomAir.ZoneUFADPowInPlumes[ZoneNum] = 0.0
        else:
            state.dataRoomAir.AirModel[ZoneNum].SimAirModel = True
            state.dataRoomAir.ZoneUFADGamma[ZoneNum] = Gamma
            state.dataRoomAir.ZoneUFADPowInPlumes[ZoneNum] = PowerInPlumes
    if state.dataRoomAir.ZTMX[ZoneNum] < state.dataRoomAir.ZTOC[ZoneNum] or MCp_Total <= 0.0 or HeightFrac * CeilingHeight < state.dataUFADManager.ThickOccupiedSubzoneMin:
        MIXFLAG = True
        HeightFrac = 0.0
        state.dataRoomAir.AvgTempGrad[ZoneNum] = 0.0
        state.dataRoomAir.MaxTempGrad[ZoneNum] = 0.0
        state.dataRoomAir.AirModel[ZoneNum].SimAirModel = False
        var AirCap = thisZoneHB.AirPowerCap
        var TempHistTerm = AirCap * (3.0 * thisZoneHB.ZTM[0] - (3.0 / 2.0) * thisZoneHB.ZTM[1] + (1.0 / 3.0) * thisZoneHB.ZTM[2])
        for Ctd in range(0, 3):
            var TempDepCoef = ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total
            var thisZoneT1 = thisZoneHB.T1
            var TempIndCoef = ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                ZTAveraged = (TempHistTerm + ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total) / ((11.0 / 6.0) * AirCap + ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    ZTAveraged = thisZoneT1 + TempIndCoef / AirCap
                else:
                    ZTAveraged = (thisZoneT1 - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                ZTAveraged = (AirCap * thisZoneT1 + TempIndCoef) / (AirCap + TempDepCoef)
            state.dataRoomAir.ZTOC[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTMX[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTFloor[ZoneNum] = ZTAveraged
            HcUFAD(state, ZoneNum, HeightFrac, ufadCC)
            TempDepCoef = ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total
            TempIndCoef = ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                ZTAveraged = (TempHistTerm + ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total) / ((11.0 / 6.0) * AirCap + ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    ZTAveraged = thisZoneT1 + TempIndCoef / AirCap
                else:
                    ZTAveraged = (thisZoneT1 - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                ZTAveraged = (AirCap * thisZoneT1 + TempIndCoef) / (AirCap + TempDepCoef)
            state.dataRoomAir.ZTOC[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTMX[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTFloor[ZoneNum] = ZTAveraged
    state.dataRoomAir.HeightTransition[ZoneNum] = HeightFrac * CeilingHeight
    var HeightUpSubzoneAve = (CeilingHeight + state.dataRoomAir.HeightTransition[ZoneNum]) / 2.0
    var HeightOccupiedSubzoneAve = state.dataRoomAir.HeightTransition[ZoneNum] / 2.0
    if MIXFLAG:
        state.dataRoomAir.TCMF[ZoneNum] = ZTAveraged
    else:
        if HeightComfort < HeightOccupiedSubzoneAve:
            state.dataRoomAir.TCMF[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
        elif HeightComfort < HeightUpSubzoneAve:
            state.dataRoomAir.TCMF[ZoneNum] = (state.dataRoomAir.ZTOC[ZoneNum] * (HeightUpSubzoneAve - HeightComfort) + state.dataRoomAir.ZTMX[ZoneNum] * (HeightComfort - HeightOccupiedSubzoneAve)) / (HeightUpSubzoneAve - HeightOccupiedSubzoneAve)
        elif HeightComfort <= CeilingHeight:
            state.dataRoomAir.TCMF[ZoneNum] = state.dataRoomAir.ZTMX[ZoneNum]
        else:
            ShowFatalError(state, "UFAD comfort height is above ceiling or below floor in Zone: {}".format(state.dataHeatBal.Zone[ZoneNum].Name))
    if MIXFLAG:
        state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = ZTAveraged
    else:
        if HeightThermostat < HeightOccupiedSubzoneAve:
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
        elif HeightThermostat < HeightUpSubzoneAve:
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = (state.dataRoomAir.ZTOC[ZoneNum] * (HeightUpSubzoneAve - HeightThermostat) + state.dataRoomAir.ZTMX[ZoneNum] * (HeightThermostat - HeightOccupiedSubzoneAve)) / (HeightUpSubzoneAve - HeightOccupiedSubzoneAve)
        elif HeightThermostat <= CeilingHeight:
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = state.dataRoomAir.ZTMX[ZoneNum]
        else:
            ShowFatalError(state, "Underfloor air distribution thermostat height is above ceiling or below floor in Zone: {}".format(state.dataHeatBal.Zone[ZoneNum].Name))
    if (HeightUpSubzoneAve - HeightOccupiedSubzoneAve) > 0.1:
        state.dataRoomAir.AvgTempGrad[ZoneNum] = (state.dataRoomAir.ZTMX[ZoneNum] - state.dataRoomAir.ZTOC[ZoneNum]) / (HeightUpSubzoneAve - HeightOccupiedSubzoneAve)
    else:
        state.dataRoomAir.AvgTempGrad[ZoneNum] = 0.0
    if MIXFLAG:
        state.dataRoomAir.ZoneUFADMixedFlag[ZoneNum] = 1
        state.dataRoomAir.AirModel[ZoneNum].SimAirModel = False
    else:
        state.dataRoomAir.ZoneUFADMixedFlag[ZoneNum] = 0
        state.dataRoomAir.AirModel[ZoneNum].SimAirModel = True
    if ZoneEquipConfigNum > 0:
        var ZoneNodeNum = state.dataHeatBal.Zone[ZoneNum].SystemZoneNodeNumber
        state.dataLoopNodes.Node[ZoneNodeNum].Temp = state.dataRoomAir.ZTMX[ZoneNum]
    if MIXFLAG:
        state.dataRoomAir.Phi[ZoneNum] = 1.0
    else:
        state.dataRoomAir.Phi[ZoneNum] = (state.dataRoomAir.ZTOC[ZoneNum] - (TSupK - Constant.Kelvin)) / (state.dataRoomAir.ZTMX[ZoneNum] - (TSupK - Constant.Kelvin))
    if MIXFLAG or ((state.dataRoomAir.ZTMX[ZoneNum] - state.dataRoomAir.ZTOC[ZoneNum]) < TempDiffCritRep):
        state.dataRoomAir.ZoneUFADMixedFlagRep[ZoneNum] = 1.0
        state.dataRoomAir.HeightTransition[ZoneNum] = 0.0
        state.dataRoomAir.AvgTempGrad[ZoneNum] = 0.0
    else:
        state.dataRoomAir.ZoneUFADMixedFlagRep[ZoneNum] = 0.0

def CalcUFADExt(inout state: EnergyPlusData, ZoneNum: Int):
    var TimeStepSys = state.dataHVACGlobal.TimeStepSys
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    var PowerInPlumesPerMeter: Float64
    var ZTAveraged: Float64
    if state.dataHeatBal.ZoneAirSolutionAlgo != DataHeatBalance.SolutionAlgo.ThirdOrder:
        if state.dataHVACGlobal.ShortenTimeStepSysRoomAir and TimeStepSys < state.dataGlobal.TimeStepZone:
            if state.dataHVACGlobal.PreviousTimeStep < state.dataGlobal.TimeStepZone:
                state.dataRoomAir.Zone1OC[ZoneNum] = state.dataRoomAir.ZoneM2OC[ZoneNum]
                state.dataRoomAir.Zone1MX[ZoneNum] = state.dataRoomAir.ZoneM2MX[ZoneNum]
            else:
                state.dataRoomAir.Zone1OC[ZoneNum] = state.dataRoomAir.ZoneMXOC[ZoneNum]
                state.dataRoomAir.Zone1MX[ZoneNum] = state.dataRoomAir.ZoneMXMX[ZoneNum]
        else:
            state.dataRoomAir.Zone1OC[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
            state.dataRoomAir.Zone1MX[ZoneNum] = state.dataRoomAir.ZTMX[ZoneNum]
    var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum]
    var HeightFrac = 0.0
    var MIXFLAG = False
    state.dataRoomAir.UFADHcIn = state.dataHeatBalSurf.SurfHConvInt
    var SumSysMCp = 0.0
    var SumSysMCpT = 0.0
    var TotSysFlow = 0.0
    var TSupK = 0.0
    var SumSysM = 0.0
    var PowerInPlumes = 0.0
    var Gamma = 0.0
    var ZoneMult = state.dataHeatBal.Zone[ZoneNum].Multiplier * state.dataHeatBal.Zone[ZoneNum].ListMultiplier
    var CeilingHeight = state.dataRoomAir.ZoneCeilingHeight2[ZoneNum] - state.dataRoomAir.ZoneCeilingHeight1[ZoneNum]
    var zoneU = state.dataRoomAir.ZoneUFAD[state.dataRoomAir.ZoneUFADPtr[ZoneNum]]
    var HeightThermostat = zoneU.ThermostatHeight
    var HeightComfort = zoneU.ComfortHeight
    var TempDiffCritRep = zoneU.TempTrigger
    var DiffArea = zoneU.DiffArea
    var ThrowAngle = Constant.DegToRad * zoneU.DiffAngle
    var SourceHeight = zoneU.HeatSrcHeight
    var NumDiffusers = zoneU.DiffusersPerZone
    var PowerPerPlume = zoneU.PowerPerPlume
    var ConvGainsOccSubzone = SumInternalConvectionGainsByTypes(state, ZoneNum, IntGainTypesOccupied)
    if state.dataHeatBal.Zone[ZoneNum].NoHeatToReturnAir:
        ConvGainsOccSubzone += SumReturnAirConvectionGainsByTypes(state, ZoneNum, IntGainTypesOccupied)
    ConvGainsOccSubzone += state.dataHeatBalFanSys.SumConvPool[ZoneNum]
    var ConvGainsUpSubzone = SumInternalConvectionGainsByTypes(state, ZoneNum, IntGainTypesUpSubzone)
    ConvGainsUpSubzone += state.dataHeatBalFanSys.SumConvHTRadSys[ZoneNum]
    if state.dataHeatBal.Zone[ZoneNum].NoHeatToReturnAir:
        ConvGainsUpSubzone += SumReturnAirConvectionGainsByTypes(state, ZoneNum, IntGainTypesUpSubzone)
    var ConvGains = ConvGainsOccSubzone + ConvGainsUpSubzone + thisZoneHB.SysDepZoneLoadsLagged
    var ZoneEquipConfigNum = zoneU.ZoneEquipPtr
    if ZoneEquipConfigNum > 0:
        let zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[ZoneEquipConfigNum]
        for InNodeIndex in range(0, zoneEquipConfig.NumInletNodes):
            var NodeTemp = state.dataLoopNodes.Node[zoneEquipConfig.InletNode[InNodeIndex]].Temp
            var MassFlowRate = state.dataLoopNodes.Node[zoneEquipConfig.InletNode[InNodeIndex]].MassFlowRate
            var CpAir = PsyCpAirFnW(thisZoneHB.airHumRat)
            SumSysMCp += MassFlowRate * CpAir
            SumSysMCpT += MassFlowRate * CpAir * NodeTemp
            TotSysFlow += MassFlowRate / PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, NodeTemp, thisZoneHB.airHumRat)
            TSupK += MassFlowRate * NodeTemp
            SumSysM += MassFlowRate
        if TotSysFlow > 0.0:
            TSupK = TSupK / SumSysM + Constant.Kelvin
        else:
            TSupK = 0.0
    var SumMCp = thisZoneHB.MCPI + thisZoneHB.MCPV + thisZoneHB.MCPM + thisZoneHB.MDotCPOA
    var SumMCpT = thisZoneHB.MCPTI + thisZoneHB.MCPTV + thisZoneHB.MCPTM + thisZoneHB.MDotCPOA * state.dataHeatBal.Zone[ZoneNum].OutDryBulbTemp
    var MCp_Total = SumMCp + SumSysMCp
    var MCpT_Total = SumMCpT + SumSysMCpT
    if zoneU.DiffuserType == Diffuser.VarArea:
        DiffArea = 0.035 * TotSysFlow / (0.0708 * NumDiffusers)
    var ufadCC = UFADConvCoef()
    HcUFAD(state, ZoneNum, 0.5, ufadCC)
    var ConvGainsWindows = ufadCC.HAT_MXWin + ufadCC.HAT_OCWin - ufadCC.HA_MXWin * state.dataRoomAir.ZTMX[ZoneNum] - ufadCC.HA_OCWin * state.dataRoomAir.ZTOC[ZoneNum]
    PowerInPlumes = ConvGains + ufadCC.HAT_OC - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum] + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]
    var NumberOfPlumes = (PowerInPlumes / PowerPerPlume) if (PowerPerPlume > 0.0 and PowerInPlumes > 0.0) else 1.0
    var NumDiffusersPerPlume = (NumDiffusers / NumberOfPlumes) if (PowerPerPlume > 0.0 and PowerInPlumes > 0.0) else 1.0
    if (PowerInPlumes <= 0.0) or (TotSysFlow == 0.0) or (TSupK - Constant.Kelvin) > thisZoneHB.MAT:
        HeightFrac = 0.0
    else:
        if PowerInPlumes > 0.0:
            if zoneU.WinWidth > 0.0:
                PowerInPlumesPerMeter = PowerInPlumes / zoneU.WinWidth
                Gamma = (TotSysFlow * cos(ThrowAngle)) / (NumDiffusers * DiffArea * pow(0.0281 * 0.001 * PowerInPlumesPerMeter, 0.333333))
            else:
                Gamma = pow(TotSysFlow * cos(ThrowAngle), 1.5) / (NumberOfPlumes * pow(NumDiffusersPerPlume * DiffArea, 1.25) * sqrt(0.0281 * 0.001 * PowerInPlumes))
        else:
            Gamma = 1000.0
        if zoneU.CalcTransHeight:
            if zoneU.WinWidth > 0.0:
                HeightFrac = (sqrt(DiffArea) * (11.03 * log(Gamma) - 10.73) + 0.5 * SourceHeight) / CeilingHeight
            else:
                HeightFrac = (sqrt(NumDiffusersPerPlume * DiffArea) * (7.43 * log(Gamma) - 1.35) + 0.5 * SourceHeight) / CeilingHeight
        else:
            HeightFrac = zoneU.TransHeight / CeilingHeight
        HeightFrac = max(0.0, min(1.0, HeightFrac))
        var GainsFrac = zoneU.A_Kc * pow(Gamma, zoneU.B_Kc) + zoneU.C_Kc + zoneU.D_Kc * Gamma + zoneU.E_Kc * (Gamma * Gamma)
        GainsFrac = max(0.7, min(GainsFrac, 1.0))
        if zoneU.ShadeDown:
            GainsFrac -= 0.2
        state.dataRoomAir.ZoneUFADPowInPlumes[ZoneNum] = PowerInPlumes
        for Ctd in range(0, 4):
            HcUFAD(state, ZoneNum, HeightFrac, ufadCC)
            ConvGainsWindows = ufadCC.HAT_MXWin + ufadCC.HAT_OCWin - ufadCC.HA_MXWin * state.dataRoomAir.ZTMX[ZoneNum] - ufadCC.HA_OCWin * state.dataRoomAir.ZTOC[ZoneNum]
            ConvGainsWindows = max(ConvGainsWindows, 0.0)
            PowerInPlumes = ConvGains + ufadCC.HAT_OC - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum] + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]
            NumberOfPlumes = 1.0
            if PowerInPlumes <= 0.0:
                break
            if zoneU.WinWidth > 0.0:
                PowerInPlumesPerMeter = PowerInPlumes / zoneU.WinWidth
                Gamma = (TotSysFlow * cos(ThrowAngle)) / (NumDiffusers * DiffArea * pow(0.0281 * 0.001 * PowerInPlumesPerMeter, 0.333333))
            else:
                Gamma = pow(TotSysFlow * cos(ThrowAngle), 1.5) / (NumberOfPlumes * pow(NumDiffusersPerPlume * DiffArea, 1.25) * sqrt(0.0281 * 0.001 * PowerInPlumes))
            if zoneU.CalcTransHeight:
                if zoneU.WinWidth > 0.0:
                    HeightFrac = (sqrt(DiffArea) * (11.03 * log(Gamma) - 10.73) + 0.5 * SourceHeight) / CeilingHeight
                else:
                    HeightFrac = (sqrt(NumDiffusersPerPlume * DiffArea) * (7.43 * log(Gamma) - 1.35) + 0.5 * SourceHeight) / CeilingHeight
            else:
                HeightFrac = zoneU.TransHeight / CeilingHeight
            HeightFrac = min(1.0, HeightFrac)
            state.dataRoomAir.HeightTransition[ZoneNum] = HeightFrac * CeilingHeight
            GainsFrac = zoneU.A_Kc * pow(Gamma, zoneU.B_Kc) + zoneU.C_Kc + zoneU.D_Kc * Gamma + zoneU.E_Kc * (Gamma * Gamma)
            GainsFrac = max(0.7, min(GainsFrac, 1.0))
            if zoneU.ShadeDown:
                GainsFrac -= 0.2
            state.dataRoomAir.AIRRATOC[ZoneNum] = state.dataHeatBal.Zone[ZoneNum].Volume * (state.dataRoomAir.HeightTransition[ZoneNum] - min(state.dataRoomAir.HeightTransition[ZoneNum], 0.2)) / CeilingHeight * state.dataHeatBal.Zone[ZoneNum].ZoneVolCapMultpSens * PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataRoomAir.MATOC[ZoneNum], thisZoneHB.airHumRat) * PsyCpAirFnW(thisZoneHB.airHumRat) / TimeStepSysSec
            state.dataRoomAir.AIRRATMX[ZoneNum] = state.dataHeatBal.Zone[ZoneNum].Volume * (CeilingHeight - state.dataRoomAir.HeightTransition[ZoneNum]) / CeilingHeight * state.dataHeatBal.Zone[ZoneNum].ZoneVolCapMultpSens * PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataRoomAir.MATMX[ZoneNum], thisZoneHB.airHumRat) * PsyCpAirFnW(thisZoneHB.airHumRat) / TimeStepSysSec
            if state.dataHVACGlobal.UseZoneTimeStepHistory:
                state.dataRoomAir.ZTMOC[ZoneNum][2] = state.dataRoomAir.XMATOC[ZoneNum][2]
                state.dataRoomAir.ZTMOC[ZoneNum][1] = state.dataRoomAir.XMATOC[ZoneNum][1]
                state.dataRoomAir.ZTMOC[ZoneNum][0] = state.dataRoomAir.XMATOC[ZoneNum][0]
                state.dataRoomAir.ZTMMX[ZoneNum][2] = state.dataRoomAir.XMATMX[ZoneNum][2]
                state.dataRoomAir.ZTMMX[ZoneNum][1] = state.dataRoomAir.XMATMX[ZoneNum][1]
                state.dataRoomAir.ZTMMX[ZoneNum][0] = state.dataRoomAir.XMATMX[ZoneNum][0]
            else:
                state.dataRoomAir.ZTMOC[ZoneNum][2] = state.dataRoomAir.DSXMATOC[ZoneNum][2]
                state.dataRoomAir.ZTMOC[ZoneNum][1] = state.dataRoomAir.DSXMATOC[ZoneNum][1]
                state.dataRoomAir.ZTMOC[ZoneNum][0] = state.dataRoomAir.DSXMATOC[ZoneNum][0]
                state.dataRoomAir.ZTMMX[ZoneNum][2] = state.dataRoomAir.DSXMATMX[ZoneNum][2]
                state.dataRoomAir.ZTMMX[ZoneNum][1] = state.dataRoomAir.DSXMATMX[ZoneNum][1]
                state.dataRoomAir.ZTMMX[ZoneNum][0] = state.dataRoomAir.DSXMATMX[ZoneNum][0]
            var AirCap = state.dataRoomAir.AIRRATOC[ZoneNum]
            var TempHistTerm = AirCap * (3.0 * state.dataRoomAir.ZTMOC[ZoneNum][0] - (3.0 / 2.0) * state.dataRoomAir.ZTMOC[ZoneNum][1] + (1.0 / 3.0) * state.dataRoomAir.ZTMOC[ZoneNum][2])
            var TempDepCoef = GainsFrac * ufadCC.HA_OC + MCp_Total
            var TempIndCoef = GainsFrac * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]) + MCpT_Total + thisZoneHB.NonAirSystemResponse / ZoneMult
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                state.dataRoomAir.ZTOC[ZoneNum] = (TempHistTerm + GainsFrac * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_MX * state.dataRoomAir.ZTMX[ZoneNum]) + MCpT_Total + thisZoneHB.NonAirSystemResponse / ZoneMult) / ((11.0 / 6.0) * AirCap + GainsFrac * ufadCC.HA_OC + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    state.dataRoomAir.ZTOC[ZoneNum] = state.dataRoomAir.Zone1OC[ZoneNum] + TempIndCoef / AirCap
                else:
                    state.dataRoomAir.ZTOC[ZoneNum] = (state.dataRoomAir.Zone1OC[ZoneNum] - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                state.dataRoomAir.ZTOC[ZoneNum] = (AirCap * state.dataRoomAir.Zone1OC[ZoneNum] + TempIndCoef) / (AirCap + TempDepCoef)
            AirCap = state.dataRoomAir.AIRRATMX[ZoneNum]
            TempHistTerm = AirCap * (3.0 * state.dataRoomAir.ZTMMX[ZoneNum][0] - (3.0 / 2.0) * state.dataRoomAir.ZTMMX[ZoneNum][1] + (1.0 / 3.0) * state.dataRoomAir.ZTMMX[ZoneNum][2])
            TempDepCoef = (1.0 - GainsFrac) * ufadCC.HA_MX + MCp_Total
            TempIndCoef = (1.0 - GainsFrac) * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum]) + state.dataRoomAir.ZTOC[ZoneNum] * MCp_Total
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                state.dataRoomAir.ZTMX[ZoneNum] = (TempHistTerm + (1.0 - GainsFrac) * (ConvGains + ufadCC.HAT_OC + ufadCC.HAT_MX - ufadCC.HA_OC * state.dataRoomAir.ZTOC[ZoneNum]) + state.dataRoomAir.ZTOC[ZoneNum] * MCp_Total) / ((11.0 / 6.0) * AirCap + (1.0 - GainsFrac) * ufadCC.HA_MX + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    state.dataRoomAir.ZTMX[ZoneNum] = state.dataRoomAir.Zone1MX[ZoneNum] + TempIndCoef / AirCap
                else:
                    state.dataRoomAir.ZTMX[ZoneNum] = (state.dataRoomAir.Zone1MX[ZoneNum] - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                state.dataRoomAir.ZTMX[ZoneNum] = (AirCap * state.dataRoomAir.Zone1MX[ZoneNum] + TempIndCoef) / (AirCap + TempDepCoef)
            state.dataRoomAir.ZTFloor[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
        if PowerInPlumes <= 0.0:
            HeightFrac = 0.0
            state.dataRoomAir.AirModel[ZoneNum].SimAirModel = False
            state.dataRoomAir.ZoneUFADGamma[ZoneNum] = 0.0
            state.dataRoomAir.ZoneUFADPowInPlumes[ZoneNum] = 0.0
            state.dataRoomAir.ZoneUFADPowInPlumesfromWindows[ZoneNum] = 0.0
        else:
            state.dataRoomAir.AirModel[ZoneNum].SimAirModel = True
            state.dataRoomAir.ZoneUFADGamma[ZoneNum] = Gamma
            state.dataRoomAir.ZoneUFADPowInPlumes[ZoneNum] = PowerInPlumes
            state.dataRoomAir.ZoneUFADPowInPlumesfromWindows[ZoneNum] = ConvGainsWindows
    if state.dataRoomAir.ZTMX[ZoneNum] < state.dataRoomAir.ZTOC[ZoneNum] or MCp_Total <= 0.0 or HeightFrac * CeilingHeight < state.dataUFADManager.ThickOccupiedSubzoneMin:
        MIXFLAG = True
        HeightFrac = 0.0
        var thisZoneT1 = thisZoneHB.T1
        state.dataRoomAir.AvgTempGrad[ZoneNum] = 0.0
        state.dataRoomAir.MaxTempGrad[ZoneNum] = 0.0
        state.dataRoomAir.AirModel[ZoneNum].SimAirModel = False
        var AirCap = thisZoneHB.AirPowerCap
        var TempHistTerm = AirCap * (3.0 * thisZoneHB.ZTM[0] - (3.0 / 2.0) * thisZoneHB.ZTM[1] + (1.0 / 3.0) * thisZoneHB.ZTM[2])
        for Ctd in range(0, 3):
            var TempDepCoef = ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total
            var TempIndCoef = ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                ZTAveraged = (TempHistTerm + ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total) / ((11.0 / 6.0) * AirCap + ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    ZTAveraged = thisZoneT1 + TempIndCoef / AirCap
                else:
                    ZTAveraged = (thisZoneT1 - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                ZTAveraged = (AirCap * thisZoneT1 + TempIndCoef) / (AirCap + TempDepCoef)
            state.dataRoomAir.ZTOC[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTMX[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTFloor[ZoneNum] = ZTAveraged
            HcUFAD(state, ZoneNum, HeightFrac, ufadCC)
            TempDepCoef = ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total
            TempIndCoef = ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total
            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.ThirdOrder:
                ZTAveraged = (TempHistTerm + ConvGains + ufadCC.HAT_MX + ufadCC.HAT_OC + MCpT_Total) / ((11.0 / 6.0) * AirCap + ufadCC.HA_MX + ufadCC.HA_OC + MCp_Total)
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:
                    ZTAveraged = thisZoneT1 + TempIndCoef / AirCap
                else:
                    ZTAveraged = (thisZoneT1 - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                ZTAveraged = (AirCap * thisZoneT1 + TempIndCoef) / (AirCap + TempDepCoef)
            state.dataRoomAir.ZTOC[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTMX[ZoneNum] = ZTAveraged
            state.dataRoomAir.ZTFloor[ZoneNum] = ZTAveraged
    var HeightUpSubzoneAve = (CeilingHeight + state.dataRoomAir.HeightTransition[ZoneNum]) / 2.0
    var HeightOccupiedSubzoneAve = state.dataRoomAir.HeightTransition[ZoneNum] / 2.0
    if MIXFLAG:
        state.dataRoomAir.TCMF[ZoneNum] = ZTAveraged
    else:
        if HeightComfort < HeightOccupiedSubzoneAve:
            state.dataRoomAir.TCMF[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
        elif HeightComfort < HeightUpSubzoneAve:
            state.dataRoomAir.TCMF[ZoneNum] = (state.dataRoomAir.ZTOC[ZoneNum] * (HeightUpSubzoneAve - HeightComfort) + state.dataRoomAir.ZTMX[ZoneNum] * (HeightComfort - HeightOccupiedSubzoneAve)) / (HeightUpSubzoneAve - HeightOccupiedSubzoneAve)
        elif HeightComfort <= CeilingHeight:
            state.dataRoomAir.TCMF[ZoneNum] = state.dataRoomAir.ZTMX[ZoneNum]
        else:
            ShowFatalError(state, "UFAD comfort height is above ceiling or below floor in Zone: {}".format(state.dataHeatBal.Zone[ZoneNum].Name))
    if MIXFLAG:
        state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = ZTAveraged
    else:
        if HeightThermostat < HeightOccupiedSubzoneAve:
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = state.dataRoomAir.ZTOC[ZoneNum]
        elif HeightThermostat < HeightUpSubzoneAve:
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = (state.dataRoomAir.ZTOC[ZoneNum] * (HeightUpSubzoneAve - HeightThermostat) + state.dataRoomAir.ZTMX[ZoneNum] * (HeightThermostat - HeightOccupiedSubzoneAve)) / (HeightUpSubzoneAve - HeightOccupiedSubzoneAve)
        elif HeightThermostat <= CeilingHeight:
            state.dataHeatBalFanSys.TempTstatAir[ZoneNum] = state.dataRoomAir.ZTMX[ZoneNum]
        else:
            ShowFatalError(state, "Underfloor air distribution thermostat height is above ceiling or below floor in Zone: {}".format(state.dataHeatBal.Zone[ZoneNum].Name))
    if (HeightUpSubzoneAve - HeightOccupiedSubzoneAve) > 0.1:
        state.dataRoomAir.AvgTempGrad[ZoneNum] = (state.dataRoomAir.ZTMX[ZoneNum] - state.dataRoomAir.ZTOC[ZoneNum]) / (HeightUpSubzoneAve - HeightOccupiedSubzoneAve)
    else:
        state.dataRoomAir.AvgTempGrad[ZoneNum] = 0.0
    if MIXFLAG:
        state.dataRoomAir.ZoneUFADMixedFlag[ZoneNum] = 1
        state.dataRoomAir.AirModel[ZoneNum].SimAirModel = False
    else:
        state.dataRoomAir.ZoneUFADMixedFlag[ZoneNum] = 0
        state.dataRoomAir.AirModel[ZoneNum].SimAirModel = True
    if ZoneEquipConfigNum > 0:
        var ZoneNodeNum = state.dataHeatBal.Zone[ZoneNum].SystemZoneNodeNumber
        state.dataLoopNodes.Node[ZoneNodeNum].Temp = state.dataRoomAir.ZTMX[ZoneNum]
    if MIXFLAG:
        state.dataRoomAir.Phi[ZoneNum] = 1.0
    else:
        state.dataRoomAir.Phi[ZoneNum] = (state.dataRoomAir.ZTOC[ZoneNum] - (TSupK - Constant.Kelvin)) / (state.dataRoomAir.ZTMX[ZoneNum] - (TSupK - Constant.Kelvin))
    if MIXFLAG or ((state.dataRoomAir.ZTMX[ZoneNum] - state.dataRoomAir.ZTOC[ZoneNum]) < TempDiffCritRep):
        state.dataRoomAir.ZoneUFADMixedFlagRep[ZoneNum] = 1.0
        state.dataRoomAir.HeightTransition[ZoneNum] = 0.0
        state.dataRoomAir.AvgTempGrad[ZoneNum] = 0.0
    else:
        state.dataRoomAir.ZoneUFADMixedFlagRep[ZoneNum] = 0.0
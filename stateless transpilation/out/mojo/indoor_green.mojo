from collections import InlineArray
from enum import Enum


@value
struct ETCalculationMethod:
    alias Invalid = -1
    alias PenmanMonteith = 0
    alias Stanghellini = 1
    alias Num = 2


@value
struct LightingMethod:
    alias Invalid = -1
    alias LED = 0
    alias Daylighting = 1
    alias LEDDaylighting = 2
    alias Num = 3


@value
struct IndoorGreenParams:
    var Name: String
    var ZoneName: String
    var SurfName: String
    var sched: DTypePointer[NoneType]
    var ledSched: DTypePointer[NoneType]
    var LightRefPtr: Int32
    var LightControlPtr: Int32
    var ledDaylightTargetSched: DTypePointer[NoneType]
    var LeafArea: Float64
    var LEDNominalPPFD: Float64
    var LEDNominalEleP: Float64
    var LEDRadFraction: Float64
    var ZCO2: Float64
    var ZVPD: Float64
    var ZPPFD: Float64
    var SensibleRate: Float64
    var SensibleRateLED: Float64
    var LatentRate: Float64
    var ETRate: Float64
    var LambdaET: Float64
    var LEDActualPPFD: Float64
    var LEDActualEleP: Float64
    var LEDActualEleCon: Float64
    var SurfPtr: Int32
    var ZoneListPtr: Int32
    var ZonePtr: Int32
    var SpacePtr: Int32
    var etCalculationMethod: Int32
    var lightingMethod: Int32
    var CheckIndoorGreenName: Bool
    var EMSET: Float64
    var EMSETCalOverrideOn: Bool
    var FieldNames: DynamicVector[String]

    fn __init__(inout self):
        self.Name = ""
        self.ZoneName = ""
        self.SurfName = ""
        self.sched = DTypePointer[NoneType]()
        self.ledSched = DTypePointer[NoneType]()
        self.LightRefPtr = 0
        self.LightControlPtr = 0
        self.ledDaylightTargetSched = DTypePointer[NoneType]()
        self.LeafArea = 0.0
        self.LEDNominalPPFD = 0.0
        self.LEDNominalEleP = 0.0
        self.LEDRadFraction = 0.0
        self.ZCO2 = 400.0
        self.ZVPD = 0.0
        self.ZPPFD = 0.0
        self.SensibleRate = 0.0
        self.SensibleRateLED = 0.0
        self.LatentRate = 0.0
        self.ETRate = 0.0
        self.LambdaET = 0.0
        self.LEDActualPPFD = 0.0
        self.LEDActualEleP = 0.0
        self.LEDActualEleCon = 0.0
        self.SurfPtr = 0
        self.ZoneListPtr = 0
        self.ZonePtr = 0
        self.SpacePtr = 0
        self.etCalculationMethod = ETCalculationMethod.PenmanMonteith
        self.lightingMethod = LightingMethod.LED
        self.CheckIndoorGreenName = True
        self.EMSET = 0.0
        self.EMSETCalOverrideOn = False
        self.FieldNames = DynamicVector[String]()


@value
struct IndoorGreenData:
    var NumIndoorGreen: Int32
    var getInputFlag: Bool
    var indoorGreens: DynamicVector[IndoorGreenParams]

    fn __init__(inout self):
        self.NumIndoorGreen = 0
        self.getInputFlag = True
        self.indoorGreens = DynamicVector[IndoorGreenParams]()

    fn clear_state(inout self):
        self = IndoorGreenData()


alias ET_CALCULATION_METHODS_UC = InlineArray[StringLiteral, 2]("PENMAN-MONTEITH", "STANGHELLINI")
alias LIGHTING_METHODS_UC = InlineArray[StringLiteral, 3]("LED", "DAYLIGHT", "LED-DAYLIGHT")


fn get_enum_value(enum_strings: InlineArray[StringLiteral, _], test_string: String) -> Int32:
    let test_upper = test_string.upper()
    for i in range(enum_strings.size()):
        if StringLiteral(enum_strings[i]) == test_upper:
            return Int32(i)
    return -1


fn SimIndoorGreen(inout state: EnergyPlusData) -> None:
    var lw = state.dataIndoorGreen
    if lw.getInputFlag:
        var ErrorsFound = False
        GetIndoorGreenInput(state, ErrorsFound)
        if ErrorsFound:
            let RoutineName = "IndoorLivingWall: "
            raise Error(String(RoutineName) + "Errors found in input.  Program terminates.")
        SetIndoorGreenOutput(state)
        lw.getInputFlag = False

    if lw.NumIndoorGreen > 0:
        InitIndoorGreen(state)
        ETModel(state)


fn GetIndoorGreenInput(inout state: EnergyPlusData, inout ErrorsFound: Bool) -> None:
    var s_lw = state.dataIndoorGreen
    var s_ip = state.dataInputProcessing.inputProcessor
    var s_ipsc = state.dataIPShortCut

    let RoutineName = "GetIndoorLivingWallInput: "
    let cCurrentModuleObject = "IndoorLivingWall"

    s_lw.NumIndoorGreen = s_ip.getNumObjectsFound(state, cCurrentModuleObject)
    if s_lw.NumIndoorGreen > 0:
        for _ in range(s_lw.NumIndoorGreen):
            s_lw.indoorGreens.push_back(IndoorGreenParams())

    for IndoorGreenNum in range(s_lw.NumIndoorGreen):
        var ig = s_lw.indoorGreens[IndoorGreenNum]
        s_ip.getObjectItem(state,
                          cCurrentModuleObject,
                          Int32(IndoorGreenNum) + 1,
                          s_ipsc.cAlphaArgs,
                          s_ipsc.rNumericArgs,
                          s_ipsc.lNumericFieldBlanks,
                          s_ipsc.lAlphaFieldBlanks,
                          s_ipsc.cAlphaFieldNames,
                          s_ipsc.cNumericFieldNames)

        ig.Name = s_ipsc.cAlphaArgs[0]
        ig.SurfName = s_ipsc.cAlphaArgs[1]
        ig.SurfPtr = find_item_in_list(s_ipsc.cAlphaArgs[1], state.dataSurface.Surface)

        if ig.SurfPtr <= 0:
            ErrorsFound = True
        else:
            if state.dataSurface.Surface[Int(ig.SurfPtr) - 1].insideHeatSourceTermSched != DTypePointer[NoneType]():
                ErrorsFound = True

            ig.ZonePtr = state.dataSurface.Surface[Int(ig.SurfPtr) - 1].Zone
            ig.SpacePtr = state.dataSurface.Surface[Int(ig.SurfPtr) - 1].spaceNum

            if ig.ZonePtr <= 0 or ig.SpacePtr <= 0:
                ErrorsFound = True
            elif (state.dataSurface.Surface[Int(ig.SurfPtr) - 1].ExtBoundCond < 0 or
                  state.dataSurface.Surface[Int(ig.SurfPtr) - 1].HeatTransferAlgorithm != "CTF"):
                ErrorsFound = True

        ig.sched = get_schedule(state, s_ipsc.cAlphaArgs[2])
        if ig.sched == DTypePointer[NoneType]():
            ErrorsFound = True
        elif not ig.sched.checkMinVal(state, 0.0):
            ErrorsFound = True

        ig.etCalculationMethod = ETCalculationMethod.PenmanMonteith
        ig.etCalculationMethod = get_enum_value(ET_CALCULATION_METHODS_UC, s_ipsc.cAlphaArgs[3])
        ig.lightingMethod = LightingMethod.LED
        ig.lightingMethod = get_enum_value(LIGHTING_METHODS_UC, s_ipsc.cAlphaArgs[4])

        if ig.lightingMethod == LightingMethod.LED:
            ig.ledSched = get_schedule(state, s_ipsc.cAlphaArgs[5])
            if ig.ledSched == DTypePointer[NoneType]():
                ErrorsFound = True
            elif not ig.ledSched.checkMinVal(state, 0.0):
                ErrorsFound = True

        elif ig.lightingMethod == LightingMethod.Daylighting:
            ig.LightRefPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.DaylRefPt)
            ig.LightControlPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.daylightControl)
            if ig.LightControlPtr == 0:
                ErrorsFound = True
                continue

        elif ig.lightingMethod == LightingMethod.LEDDaylighting:
            ig.LightRefPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.DaylRefPt)
            ig.LightControlPtr = find_item_in_list(s_ipsc.cAlphaArgs[6], state.dataDayltg.daylightControl)
            if ig.LightControlPtr == 0:
                ErrorsFound = True
                continue

            ig.ledDaylightTargetSched = get_schedule(state, s_ipsc.cAlphaArgs[7])
            if ig.ledDaylightTargetSched == DTypePointer[NoneType]():
                ErrorsFound = True
            elif not ig.ledDaylightTargetSched.checkMinVal(state, 0.0):
                ErrorsFound = True

        ig.LeafArea = s_ipsc.rNumericArgs[0]
        if ig.LeafArea < 0:
            ErrorsFound = True

        ig.LEDNominalPPFD = s_ipsc.rNumericArgs[1]
        if ig.LEDNominalPPFD < 0:
            ErrorsFound = True

        ig.LEDNominalEleP = s_ipsc.rNumericArgs[2]
        if ig.LEDNominalEleP < 0:
            ErrorsFound = True

        ig.LEDRadFraction = s_ipsc.rNumericArgs[3]
        if ig.LEDRadFraction < 0 or ig.LEDRadFraction > 1.0:
            ErrorsFound = True

        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "IndoorLivingWall", ig.Name, "Evapotranspiration Rate", "[kg_m2s]", ig.EMSETCalOverrideOn, ig.EMSET)


fn SetIndoorGreenOutput(inout state: EnergyPlusData) -> None:
    var lw = state.dataIndoorGreen
    for IndoorGreenNum in range(lw.NumIndoorGreen):
        var ig = lw.indoorGreens[IndoorGreenNum]
        SetupZoneInternalGain(state,
                             ig.ZonePtr,
                             ig.Name,
                             "IndoorGreen",
                             ig.SensibleRate,
                             ig.LatentRate)

        SetupOutputVariable(state,
                           "Indoor Living Wall Plant Surface Temperature",
                           "C",
                           state.dataHeatBalSurf.SurfTempIn[Int(ig.SurfPtr) - 1],
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Sensible Heat Gain Rate",
                           "W",
                           ig.SensibleRate,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Latent Heat Gain Rate",
                           "W",
                           ig.LatentRate,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Evapotranspiration Rate",
                           "kg_m2s",
                           ig.ETRate,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Energy Rate Required For Evapotranspiration Per Unit Area",
                           "W_m2",
                           ig.LambdaET,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Operational PPFD",
                           "umol_m2s",
                           ig.LEDActualPPFD,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall PPFD",
                           "umol_m2s",
                           ig.ZPPFD,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall Vapor Pressure Deficit",
                           "Pa",
                           ig.ZVPD,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Sensible Heat Gain Rate",
                           "W",
                           ig.SensibleRateLED,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Operational Power",
                           "W",
                           ig.LEDActualEleP,
                           "Zone",
                           "Average",
                           ig.Name)
        SetupOutputVariable(state,
                           "Indoor Living Wall LED Electricity Energy",
                           "J",
                           ig.LEDActualEleCon,
                           "Zone",
                           "Sum",
                           ig.Name,
                           "Electricity",
                           "Building",
                           "InteriorLights",
                           "IndoorLivingWall",
                           state.dataHeatBal.Zone[Int(ig.ZonePtr) - 1].Name,
                           state.dataHeatBal.Zone[Int(ig.ZonePtr) - 1].Multiplier,
                           state.dataHeatBal.Zone[Int(ig.ZonePtr) - 1].ListMultiplier,
                           state.dataHeatBal.space[Int(ig.SpacePtr) - 1].spaceType)


fn InitIndoorGreen(inout state: EnergyPlusData) -> None:
    for i in range(state.dataIndoorGreen.indoorGreens.size()):
        var ig = state.dataIndoorGreen.indoorGreens[i]
        ig.SensibleRate = 0.0
        ig.SensibleRateLED = 0.0
        ig.LatentRate = 0.0
        ig.ZCO2 = 400.0
        ig.ZPPFD = 0.0


fn ETModel(inout state: EnergyPlusData) -> None:
    let RoutineName = "ETModel: "
    var lw = state.dataIndoorGreen
    let Timestep = state.dataHVACGlobal.TimeStepSysSec

    for IndoorGreenNum in range(lw.NumIndoorGreen):
        var ig = lw.indoorGreens[IndoorGreenNum]
        let ZonePreTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance[Int(ig.ZonePtr) - 1].ZT
        let ZonePreHum = state.dataZoneTempPredictorCorrector.zoneHeatBalance[Int(ig.ZonePtr) - 1].airHumRat
        let ZoneCO2 = 400.0
        let OutPb = state.dataEnvrn.OutBaroPress / 1000.0

        let Tdp = Psychrometrics.PsyTdpFnWPb(state, ZonePreHum, OutPb * 1000)
        let vp = Psychrometrics.PsyPsatFnTemp(state, Tdp, RoutineName) / 1000.0
        let vpSat = Psychrometrics.PsyPsatFnTemp(state, ZonePreTemp, RoutineName) / 1000.0
        ig.ZVPD = (vpSat - vp) * 1000.0

        let LAI_Cal = ig.LeafArea / state.dataSurface.Surface[Int(ig.SurfPtr) - 1].Area
        var LAI = LAI_Cal
        if LAI_Cal > 10.0:
            LAI = 10.0

        if ig.lightingMethod == LightingMethod.LED:
            ig.ZPPFD = ig.ledSched.getCurrentVal() * ig.LEDNominalPPFD
            ig.LEDActualPPFD = ig.ZPPFD
            ig.LEDActualEleP = ig.ledSched.getCurrentVal() * ig.LEDNominalEleP
            ig.LEDActualEleCon = ig.LEDActualEleP * Timestep

        elif ig.lightingMethod == LightingMethod.Daylighting:
            ig.ZPPFD = 0.0
            ig.LEDActualPPFD = 0.0
            ig.LEDActualEleP = 0.0
            ig.LEDActualEleCon = 0.0
            if not state.dataDayltg.CalcDayltghCoefficients_firstTime and state.dataEnvrn.SunIsUp:
                ig.ZPPFD = state.dataDayltg.daylightControl[Int(ig.LightControlPtr) - 1].refPts[0].lums[0] / 77.0

        elif ig.lightingMethod == LightingMethod.LEDDaylighting:
            let a = ig.ledDaylightTargetSched.getCurrentVal()
            var b = 0.0
            if not state.dataDayltg.CalcDayltghCoefficients_firstTime and state.dataEnvrn.SunIsUp:
                b = state.dataDayltg.daylightControl[Int(ig.LightControlPtr) - 1].refPts[0].lums[0] / 77.0

            ig.LEDActualPPFD = max((a - b), 0.0)
            if ig.LEDActualPPFD >= ig.LEDNominalPPFD:
                ig.ZPPFD = ig.LEDNominalPPFD + b
                ig.LEDActualEleP = ig.LEDNominalEleP
                ig.LEDActualEleCon = ig.LEDNominalEleP * Timestep
            else:
                ig.ZPPFD = a
                ig.LEDActualEleP = ig.LEDNominalEleP * ig.LEDActualPPFD / ig.LEDNominalPPFD
                ig.LEDActualEleCon = ig.LEDActualEleP * Timestep

        let ZonePPFD = ig.ZPPFD
        let ZoneVPD = ig.ZVPD / 1000.0

        if ig.EMSETCalOverrideOn:
            ig.ETRate = ig.EMSET
        else:
            let SwitchF = ig.etCalculationMethod == ETCalculationMethod.PenmanMonteith ? 1.0 : 2.0 * LAI
            ig.ETRate = ETBaseFunction(state, ZonePreTemp, ZonePreHum, ZonePPFD, ZoneVPD, LAI, SwitchF)

        let effectivearea = min(ig.LeafArea, LAI * state.dataSurface.Surface[Int(ig.SurfPtr) - 1].Area)
        let ETTotal = ig.ETRate * Timestep * effectivearea * ig.sched.getCurrentVal()

        let hfg = Psychrometrics.PsyHfgAirFnWTdb(ZonePreHum, ZonePreTemp) / (10 ** 6)
        ig.LambdaET = ETTotal * hfg * (10 ** 6) / state.dataSurface.Surface[Int(ig.SurfPtr) - 1].Area / Timestep

        let rhoair = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, ZonePreTemp, ZonePreHum)
        let ZoneAirVol = state.dataHeatBal.Zone[Int(ig.ZonePtr) - 1].Volume
        var ZoneNewHum = ZonePreHum + ETTotal / (rhoair * ZoneAirVol)

        let Twb = Psychrometrics.PsyTwbFnTdbWPb(state, ZonePreTemp, ZonePreHum, state.dataEnvrn.OutBaroPress)
        let ZoneSatHum = Psychrometrics.PsyWFnTdbRhPb(state, Twb, 1.0, state.dataEnvrn.OutBaroPress)
        let HCons = Psychrometrics.PsyHFnTdbW(ZonePreTemp, ZonePreHum)

        var ZoneNewTemp: Float64
        if ZoneNewHum <= ZoneSatHum:
            ZoneNewTemp = Psychrometrics.PsyTdbFnHW(HCons, ZoneNewHum)
        else:
            ZoneNewTemp = Twb
            ZoneNewHum = ZoneSatHum

        let HMid = Psychrometrics.PsyHFnTdbW(ZoneNewTemp, ZonePreHum)
        ig.LatentRate = ZoneAirVol * rhoair * (HCons - HMid) / Timestep
        ig.SensibleRateLED = (1.0 - ig.LEDRadFraction) * ig.LEDActualEleP
        ig.SensibleRate = -1.0 * ig.LatentRate + ig.SensibleRateLED

        state.dataHeatBalSurf.SurfQAdditionalHeatSourceInside[Int(ig.SurfPtr) - 1] = \
            ig.LEDRadFraction * 0.9 * ig.LEDActualEleP / state.dataSurface.Surface[Int(ig.SurfPtr) - 1].Area


fn ETBaseFunction(inout state: EnergyPlusData, ZonePreTemp: Float64, ZonePreHum: Float64,
                  ZonePPFD: Float64, ZoneVPD: Float64, LAI: Float64, SwitchF: Float64) -> Float64:
    let hfg = Psychrometrics.PsyHfgAirFnWTdb(ZonePreHum, ZonePreTemp) / (10 ** 6)
    let slopepat = 0.200 * ((0.00738 * ZonePreTemp + 0.8072) ** 7) - 0.000116
    let CpAir = Psychrometrics.PsyCpAirFnW(ZonePreHum) / (10 ** 6)
    let OutPb = state.dataEnvrn.OutBaroPress / 1000.0
    let mw = 0.622
    let psyconst = CpAir * OutPb / (hfg * mw)
    let In = ZonePPFD * 0.327 / (10 ** 6)
    let G = 0.0
    let rhoair = Psychrometrics.PsyRhoAirFnPbTdbW(state, OutPb * 1000.0, ZonePreTemp, ZonePreHum)
    let rs = 60.0 * (1500.0 + ZonePPFD) / (200.0 + ZonePPFD)
    let ra = 350.0 * ((0.1 / 0.1) ** 0.5) * (1.0 / (LAI + 1e-10))
    let ETRate = (1.0 / hfg) * (slopepat * (In - G) + (SwitchF * rhoair * CpAir * ZoneVPD) / ra) / \
                 (slopepat + psyconst * (1.0 + rs / ra))
    return ETRate


fn find_item_in_list(item: String, item_list: DynamicVector[_]) -> Int32:
    for i in range(item_list.size()):
        if item_list[i].Name == item:
            return Int32(i) + 1
    return 0


fn get_schedule(inout state: EnergyPlusData, schedule_name: String) -> DTypePointer[NoneType]:
    return DTypePointer[NoneType]()


fn SetupEMSActuator(inout state: EnergyPlusData, component_type: String, component_name: String,
                    control_type: String, units: String, inout override_flag: Bool, inout setpoint: Float64) -> None:
    pass


fn SetupZoneInternalGain(inout state: EnergyPlusData, zone_ptr: Int32, name: String, gain_type: String,
                         inout sensible_rate: Float64, inout latent_rate: Float64) -> None:
    pass


fn SetupOutputVariable(inout state: EnergyPlusData, variable_name: String, units: String, inout variable_ref: Float64,
                       timestepping: String, store_type: String, name: String, *args: String) -> None:
    pass


struct Psychrometrics:
    @staticmethod
    fn PsyTdpFnWPb(inout state: EnergyPlusData, W: Float64, Pb: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyPsatFnTemp(inout state: EnergyPlusData, T: Float64, routine_name: String) -> Float64:
        return 0.0

    @staticmethod
    fn PsyRhoAirFnPbTdbW(inout state: EnergyPlusData, Pb: Float64, Tdb: Float64, W: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyHfgAirFnWTdb(W: Float64, T: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyTwbFnTdbWPb(inout state: EnergyPlusData, Tdb: Float64, W: Float64, Pb: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyWFnTdbRhPb(inout state: EnergyPlusData, Tdb: Float64, Rh: Float64, Pb: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyHFnTdbW(Tdb: Float64, W: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyTdbFnHW(H: Float64, W: Float64) -> Float64:
        return 0.0

    @staticmethod
    fn PsyCpAirFnW(W: Float64) -> Float64:
        return 0.0

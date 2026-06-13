from math import exp, log, cos, sin, acos, sqrt, pow
from collections import InlineArray

alias Float64 = Float64
alias Int32 = Int32

alias PVModelSimple = 0
alias PVModelTRNSYS = 1
alias PVModelSandia = 2
alias PVModelNum = 3
alias PVModelInvalid = -1

alias CellIntegrationDecoupled = 0
alias CellIntegrationDecoupledUllebergDynamic = 1
alias CellIntegrationSurfaceOutsideFace = 2
alias CellIntegrationTranspiredCollector = 3
alias CellIntegrationExteriorVentedCavity = 4
alias CellIntegrationPVTSolarCollector = 5
alias CellIntegrationNum = 6
alias CellIntegrationInvalid = -1

alias EfficiencyFixed = 0
alias EfficiencyScheduled = 1
alias EfficiencyNum = 2
alias EfficiencyInvalid = -1

alias SiPVCellsCrystallineSilicon = 0
alias SiPVCellsAmorphousSilicon = 1
alias SiPVCellsNum = 2
alias SiPVCellsInvalid = -1

struct PhotovoltaicStateData:
    var CheckEquipName: DynamicVector[Bool]
    var GetInputFlag: Bool
    var MyOneTimeFlag: Bool
    var firstTime: Bool
    var PVTimeStep: Float64
    var MyEnvrnFlag: DynamicVector[Bool]

    fn __init__(inout self):
        self.CheckEquipName = DynamicVector[Bool]()
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.firstTime = True
        self.PVTimeStep = 0.0
        self.MyEnvrnFlag = DynamicVector[Bool]()

    fn init_constant_state(inout self, state):
        pass

    fn init_state(inout self, state):
        pass

    fn clear_state(inout self):
        self.CheckEquipName.clear()
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.firstTime = True
        self.MyEnvrnFlag.clear()

var cPVGeneratorObjectName = "Generator:Photovoltaic"

fn get_pv_model_names() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("PhotovoltaicPerformance:Simple")
    names.push_back("PhotovoltaicPerformance:EquivalentOne-Diode")
    names.push_back("PhotovoltaicPerformance:Sandia")
    return names

fn get_pv_model_names_uc() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("PHOTOVOLTAICPERFORMANCE:SIMPLE")
    names.push_back("PHOTOVOLTAICPERFORMANCE:EQUIVALENTONE-DIODE")
    names.push_back("PHOTOVOLTAICPERFORMANCE:SANDIA")
    return names

fn get_cell_integration_names() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("Decoupled")
    names.push_back("DecoupledUllebergDynamic")
    names.push_back("IntegratedSurfaceOutsideFace")
    names.push_back("IntegratedTranspiredCollector")
    names.push_back("IntegratedExteriorVentedCavity")
    names.push_back("PhotovoltaicThermalSolarCollector")
    return names

fn get_cell_integration_names_uc() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("DECOUPLED")
    names.push_back("DECOUPLEDULLEBERGDYNAMIC")
    names.push_back("INTEGRATEDSURFACEOUTSIDEFACE")
    names.push_back("INTEGRATEDTRANSPIREDCOLLECTOR")
    names.push_back("INTEGRATEDEXTERIORVENTEDCAVITY")
    names.push_back("PHOTOVOLTAICTHERMALSOLARCOLLECTOR")
    return names

fn get_efficiency_names() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("Fixed")
    names.push_back("Scheduled")
    return names

fn get_efficiency_names_uc() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("FIXED")
    names.push_back("SCHEDULED")
    return names

fn get_sipvcells_names() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("CrystallineSilicon")
    names.push_back("AmorphousSilicon")
    return names

fn get_sipvcells_names_uc() -> DynamicVector[String]:
    var names = DynamicVector[String]()
    names.push_back("CRYSTALLINESILICON")
    names.push_back("AMORPHOUSSILICON")
    return names

@export
fn SimPVGenerator(state, GeneratorType: Int32, GeneratorName: String, inout GeneratorIndex: Int32, RunFlag: Bool, PVLoad: Float64):
    var PVnum: Int32 = 0

    if state.dataPhotovoltaicState.GetInputFlag:
        GetPVInput(state)
        state.dataPhotovoltaicState.GetInputFlag = False

    if GeneratorIndex == 0:
        PVnum = Util.FindItemInList(GeneratorName, state.dataPhotovoltaic.PVarray)
        if PVnum == 0:
            ShowFatalError(state, "SimPhotovoltaicGenerator: Specified PV not one of valid Photovoltaic Generators " + GeneratorName)
        GeneratorIndex = PVnum
    else:
        PVnum = GeneratorIndex
        if PVnum > state.dataPhotovoltaic.NumPVs or PVnum < 1:
            ShowFatalError(state, "SimPhotovoltaicGenerator: Invalid GeneratorIndex passed=" + str(PVnum) + ", Number of PVs=" + str(state.dataPhotovoltaic.NumPVs) + ", Generator name=" + GeneratorName)
        if state.dataPhotovoltaicState.CheckEquipName[PVnum - 1]:
            if GeneratorName != state.dataPhotovoltaic.PVarray[PVnum - 1].Name:
                ShowFatalError(state, "SimPhotovoltaicGenerator: Invalid GeneratorIndex passed=" + str(PVnum) + ", Generator name=" + GeneratorName + ", stored PV Name for that index=" + state.dataPhotovoltaic.PVarray[PVnum - 1].Name)
            state.dataPhotovoltaicState.CheckEquipName[PVnum - 1] = False

    var pv_model_type = state.dataPhotovoltaic.PVarray[PVnum - 1].PVModelType
    if pv_model_type == PVModelSimple:
        CalcSimplePV(state, PVnum)
    elif pv_model_type == PVModelTRNSYS:
        InitTRNSYSPV(state, PVnum)
        CalcTRNSYSPV(state, PVnum, RunFlag)
    elif pv_model_type == PVModelSandia:
        CalcSandiaPV(state, PVnum, RunFlag)
    else:
        ShowFatalError(state, "Specified generator model type not found for PV generator = " + GeneratorName)

    ReportPV(state, PVnum)

@export
fn GetPVGeneratorResults(state, GeneratorType: Int32, GeneratorIndex: Int32, inout GeneratorPower: Float64, inout GeneratorEnergy: Float64, inout ThermalPower: Float64, inout ThermalEnergy: Float64):
    var pv = state.dataPhotovoltaic.PVarray[GeneratorIndex - 1]
    GeneratorPower = pv.Report.DCPower
    GeneratorEnergy = pv.Report.DCEnergy

    if pv.CellIntegrationMode == CellIntegrationPVTSolarCollector:
        GetPVTThermalPowerProduction(state, GeneratorIndex, ThermalPower, ThermalEnergy)
    else:
        ThermalPower = 0.0
        ThermalEnergy = 0.0

@export
fn GetPVInput(state):
    var routineName = "GetPVInput"

    state.dataPhotovoltaic.NumPVs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cPVGeneratorObjectName)
    state.dataPhotovoltaic.NumSimplePVModuleTypes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, get_pv_model_names()[PVModelSimple])
    state.dataPhotovoltaic.Num1DiodePVModuleTypes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, get_pv_model_names()[PVModelTRNSYS])
    state.dataPhotovoltaic.NumSNLPVModuleTypes = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, get_pv_model_names()[PVModelSandia])

    if state.dataPhotovoltaic.NumPVs <= 0:
        ShowSevereError(state, "Did not find any " + cPVGeneratorObjectName)
        return

@export
fn GetPVZone(state, SurfNum: Int32) -> Int32:
    var GetPVZone_val: Int32 = 0

    if SurfNum > 0:
        GetPVZone_val = state.dataSurface.Surface[SurfNum - 1].Zone
        if GetPVZone_val == 0:
            GetPVZone_val = Util.FindItemInList(state.dataSurface.Surface[SurfNum - 1].ZoneName, state.dataHeatBal.Zone)

    return GetPVZone_val

@export
fn CalcSimplePV(state, thisPV: Int32):
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    var ThisSurf = state.dataPhotovoltaic.PVarray[thisPV - 1].SurfacePtr
    var pv = state.dataPhotovoltaic.PVarray[thisPV - 1]

    if state.dataHeatBal.SurfQRadSWOutIncident[ThisSurf - 1] > DataPhotovoltaics.MinIrradiance:
        var eff_mode = pv.SimplePVModule.EfficencyInputMode
        var Eff: Float64 = 0.0
        if eff_mode == EfficiencyFixed:
            Eff = pv.SimplePVModule.PVEfficiency
        elif eff_mode == EfficiencyScheduled:
            Eff = pv.SimplePVModule.effSched.getCurrentVal()
            pv.SimplePVModule.PVEfficiency = Eff
        else:
            Eff = 0.0
            ShowSevereError(state, "caught bad Mode in Generator:Photovoltaic:Simple use FIXED or SCHEDULED efficiency mode")

        pv.Report.DCPower = pv.SimplePVModule.AreaCol * Eff * state.dataHeatBal.SurfQRadSWOutIncident[ThisSurf - 1]
        pv.SurfaceSink = pv.Report.DCPower
        pv.Report.DCEnergy = pv.Report.DCPower * TimeStepSysSec
        pv.Report.ArrayEfficiency = Eff
    else:
        pv.SurfaceSink = 0.0
        pv.Report.DCEnergy = 0.0
        pv.Report.DCPower = 0.0
        pv.Report.ArrayEfficiency = 0.0

@export
fn ReportPV(state, PVnum: Int32):
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    var pv = state.dataPhotovoltaic.PVarray[PVnum - 1]

    pv.Report.DCEnergy = pv.Report.DCPower * TimeStepSysSec

    var thisZone = pv.Zone
    if thisZone != 0:
        var multiplier = state.dataHeatBal.Zone[thisZone - 1].Multiplier * state.dataHeatBal.Zone[thisZone - 1].ListMultiplier
        pv.Report.DCEnergy *= multiplier
        pv.Report.DCPower *= multiplier

    var cell_mode = pv.CellIntegrationMode
    if cell_mode == CellIntegrationSurfaceOutsideFace:
        state.dataHeatBalFanSys.QPVSysSource[pv.SurfacePtr - 1] = -1.0 * pv.SurfaceSink
    elif cell_mode == CellIntegrationTranspiredCollector:
        SetUTSCQdotSource(state, pv.UTSCPtr, -1.0 * pv.SurfaceSink)
    elif cell_mode == CellIntegrationExteriorVentedCavity:
        SetVentedModuleQdotSource(state, pv.ExtVentCavPtr, -1.0 * pv.SurfaceSink)
    elif cell_mode == CellIntegrationPVTSolarCollector:
        SetPVTQdotSource(state, pv.PVTPtr, -1.0 * pv.SurfaceSink)

@export
fn CalcSandiaPV(state, PVnum: Int32, RunFlag: Bool):
    var ThisSurf = state.dataPhotovoltaic.PVarray[PVnum - 1].SurfacePtr
    var pv = state.dataPhotovoltaic.PVarray[PVnum - 1]

    pv.SNLPVinto.IcBeam = state.dataHeatBal.SurfQRadSWOutIncidentBeam[ThisSurf - 1]
    pv.SNLPVinto.IcDiffuse = state.dataHeatBal.SurfQRadSWOutIncident[ThisSurf - 1] - state.dataHeatBal.SurfQRadSWOutIncidentBeam[ThisSurf - 1]
    pv.SNLPVinto.IncidenceAngle = acos(state.dataHeatBal.SurfCosIncidenceAngle[ThisSurf - 1]) / Constant.DegToRad
    pv.SNLPVinto.ZenithAngle = acos(state.dataEnvrn.SOLCOS[2]) / Constant.DegToRad
    pv.SNLPVinto.Tamb = state.dataSurface.SurfOutDryBulbTemp[ThisSurf - 1]
    pv.SNLPVinto.WindSpeed = state.dataSurface.SurfOutWindSpeed[ThisSurf - 1]
    pv.SNLPVinto.Altitude = state.dataEnvrn.Elevation

    if ((pv.SNLPVinto.IcBeam + pv.SNLPVinto.IcDiffuse) > DataPhotovoltaics.MinIrradiance) and RunFlag:

        var cell_mode = pv.CellIntegrationMode
        if cell_mode == CellIntegrationDecoupled:
            pv.SNLPVCalc.Tback = SandiaModuleTemperature(
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVinto.WindSpeed,
                pv.SNLPVinto.Tamb,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.a,
                pv.SNLPVModule.b
            )
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegrationSurfaceOutsideFace:
            pv.SNLPVCalc.Tback = state.dataHeatBalSurf.SurfTempOut[pv.SurfacePtr - 1]
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegrationTranspiredCollector:
            GetUTSCTsColl(state, pv.UTSCPtr, pv.SNLPVCalc.Tback)
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegrationExteriorVentedCavity:
            GetExtVentedCavityTsColl(state, pv.ExtVentCavPtr, pv.SNLPVCalc.Tback)
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        elif cell_mode == CellIntegrationPVTSolarCollector:
            GetPVTTsColl(state, pv.PVTPtr, pv.SNLPVCalc.Tback)
            pv.SNLPVCalc.Tcell = SandiaTcellFromTmodule(
                pv.SNLPVCalc.Tback,
                pv.SNLPVinto.IcBeam,
                pv.SNLPVinto.IcDiffuse,
                pv.SNLPVModule.fd,
                pv.SNLPVModule.DT0
            )
        else:
            ShowSevereError(state, "Sandia PV Simulation Temperature Modeling Mode Error in " + pv.Name)

        pv.SNLPVCalc.AMa = AbsoluteAirMass(pv.SNLPVinto.ZenithAngle, pv.SNLPVinto.Altitude)

        pv.SNLPVCalc.F1 = SandiaF1(
            pv.SNLPVCalc.AMa,
            pv.SNLPVModule.a_0,
            pv.SNLPVModule.a_1,
            pv.SNLPVModule.a_2,
            pv.SNLPVModule.a_3,
            pv.SNLPVModule.a_4
        )

        pv.SNLPVCalc.F2 = SandiaF2(
            pv.SNLPVinto.IncidenceAngle,
            pv.SNLPVModule.b_0,
            pv.SNLPVModule.b_1,
            pv.SNLPVModule.b_2,
            pv.SNLPVModule.b_3,
            pv.SNLPVModule.b_4,
            pv.SNLPVModule.b_5
        )

        pv.SNLPVCalc.Isc = SandiaIsc(
            pv.SNLPVCalc.Tcell,
            pv.SNLPVModule.Isc0,
            pv.SNLPVinto.IcBeam,
            pv.SNLPVinto.IcDiffuse,
            pv.SNLPVCalc.F1,
            pv.SNLPVCalc.F2,
            pv.SNLPVModule.fd,
            pv.SNLPVModule.aIsc
        )

        var Ee = SandiaEffectiveIrradiance(
            pv.SNLPVCalc.Tcell,
            pv.SNLPVCalc.Isc,
            pv.SNLPVModule.Isc0,
            pv.SNLPVModule.aIsc
        )

        pv.SNLPVCalc.Imp = SandiaImp(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Imp0,
            pv.SNLPVModule.aImp,
            pv.SNLPVModule.c_0,
            pv.SNLPVModule.c_1
        )

        pv.SNLPVCalc.Voc = SandiaVoc(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Voc0,
            pv.SNLPVModule.NcellSer,
            pv.SNLPVModule.DiodeFactor,
            pv.SNLPVModule.BVoc0,
            pv.SNLPVModule.mBVoc
        )

        pv.SNLPVCalc.Vmp = SandiaVmp(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Vmp0,
            pv.SNLPVModule.NcellSer,
            pv.SNLPVModule.DiodeFactor,
            pv.SNLPVModule.BVmp0,
            pv.SNLPVModule.mBVmp,
            pv.SNLPVModule.c_2,
            pv.SNLPVModule.c_3
        )

        pv.SNLPVCalc.Ix = SandiaIx(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Ix0,
            pv.SNLPVModule.aIsc,
            pv.SNLPVModule.aImp,
            pv.SNLPVModule.c_4,
            pv.SNLPVModule.c_5
        )

        pv.SNLPVCalc.Vx = pv.SNLPVCalc.Voc / 2.0

        pv.SNLPVCalc.Ixx = SandiaIxx(
            pv.SNLPVCalc.Tcell,
            Ee,
            pv.SNLPVModule.Ixx0,
            pv.SNLPVModule.aImp,
            pv.SNLPVModule.c_6,
            pv.SNLPVModule.c_7
        )

        pv.SNLPVCalc.Vxx = 0.5 * (pv.SNLPVCalc.Voc + pv.SNLPVCalc.Vmp)

        pv.SNLPVCalc.Pmp = pv.SNLPVCalc.Imp * pv.SNLPVCalc.Vmp

        pv.SNLPVCalc.EffMax = pv.SNLPVCalc.Pmp / (pv.SNLPVinto.IcBeam + pv.SNLPVinto.IcDiffuse) / pv.SNLPVModule.Acoll

        pv.SNLPVCalc.Pmp *= pv.NumSeriesNParall * pv.NumModNSeries
        pv.SNLPVCalc.Imp *= pv.NumModNSeries
        pv.SNLPVCalc.Vmp *= pv.NumModNSeries
        pv.SNLPVCalc.Isc *= pv.NumSeriesNParall
        pv.SNLPVCalc.Voc *= pv.NumModNSeries
        pv.SNLPVCalc.Ix *= pv.NumSeriesNParall
        pv.SNLPVCalc.Ixx *= pv.NumSeriesNParall
        pv.SNLPVCalc.Vx *= pv.NumModNSeries
        pv.SNLPVCalc.Vxx *= pv.NumModNSeries
        pv.SNLPVCalc.SurfaceSink = pv.SNLPVCalc.Pmp
    else:
        pv.SNLPVCalc.Vmp = 0.0
        pv.SNLPVCalc.Imp = 0.0
        pv.SNLPVCalc.Pmp = 0.0
        pv.SNLPVCalc.EffMax = 0.0
        pv.SNLPVCalc.Isc = 0.0
        pv.SNLPVCalc.Voc = 0.0
        pv.SNLPVCalc.Tcell = pv.SNLPVinto.Tamb
        pv.SNLPVCalc.Tback = pv.SNLPVinto.Tamb
        pv.SNLPVCalc.AMa = 999.0
        pv.SNLPVCalc.F1 = 0.0
        pv.SNLPVCalc.F2 = 0.0
        pv.SNLPVCalc.Ix = 0.0
        pv.SNLPVCalc.Vx = 0.0
        pv.SNLPVCalc.Ixx = 0.0
        pv.SNLPVCalc.Vxx = 0.0
        pv.SNLPVCalc.SurfaceSink = 0.0

    pv.Report.DCPower = pv.SNLPVCalc.Pmp
    pv.Report.ArrayIsc = pv.SNLPVCalc.Isc
    pv.Report.ArrayVoc = pv.SNLPVCalc.Voc
    pv.Report.CellTemp = pv.SNLPVCalc.Tcell
    pv.Report.ArrayEfficiency = pv.SNLPVCalc.EffMax
    pv.SurfaceSink = pv.SNLPVCalc.SurfaceSink

@export
fn InitTRNSYSPV(state, PVnum: Int32):
    var pv = state.dataPhotovoltaic.PVarray[PVnum - 1]

    if state.dataPhotovoltaicState.MyOneTimeFlag:
        state.dataPhotovoltaicState.MyEnvrnFlag = DynamicVector[Bool](state.dataPhotovoltaic.NumPVs, True)
        state.dataPhotovoltaicState.MyOneTimeFlag = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataPhotovoltaicState.MyEnvrnFlag[PVnum - 1]:
        pv.TRNSYSPVcalc.CellTempK = state.dataSurface.SurfOutDryBulbTemp[pv.SurfacePtr - 1] + Constant.Kelvin
        pv.TRNSYSPVcalc.LastCellTempK = state.dataSurface.SurfOutDryBulbTemp[pv.SurfacePtr - 1] + Constant.Kelvin
        state.dataPhotovoltaicState.MyEnvrnFlag[PVnum - 1] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataPhotovoltaicState.MyEnvrnFlag[PVnum - 1] = True

    var TimeElapsed = state.dataGlobal.HourOfDay + state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed

    if pv.TRNSYSPVcalc.TimeElapsed != TimeElapsed:
        pv.TRNSYSPVcalc.LastCellTempK = pv.TRNSYSPVcalc.CellTempK
        pv.TRNSYSPVcalc.TimeElapsed = TimeElapsed

    var has_insolation = False
    for i in range(len(state.dataHeatBal.SurfQRadSWOutIncident)):
        if state.dataHeatBal.SurfQRadSWOutIncident[i] > 0.0:
            has_insolation = True
            break
    
    if has_insolation:
        pv.TRNSYSPVcalc.Insolation = state.dataHeatBal.SurfQRadSWOutIncident[pv.SurfacePtr - 1]
    else:
        pv.TRNSYSPVcalc.Insolation = 0.0

@export
fn CalcTRNSYSPV(state, PVnum: Int32, RunFlag: Bool):
    var EPS = 0.001
    var ERR = 0.001
    var MinInsolation = 30.0
    var KMAX = 100
    var EtaIni = 0.10

    var pv = state.dataPhotovoltaic.PVarray[PVnum - 1]

    if state.dataPhotovoltaicState.firstTime and pv.CellIntegrationMode == CellIntegrationDecoupledUllebergDynamic:
        state.dataPhotovoltaicState.PVTimeStep = Float64(state.dataGlobal.MinutesInTimeStep) * 60.0

    state.dataPhotovoltaicState.firstTime = False

    state.dataPhotovoltaic.ShuntResistance = pv.TRNSYSPVModule.ShuntResistance

    var Tambient = state.dataSurface.SurfOutDryBulbTemp[pv.SurfacePtr - 1] + Constant.Kelvin

    if (pv.TRNSYSPVcalc.Insolation > MinInsolation) and RunFlag:
        var DummyErr = 2.0 * ERR
        var EtaOld = EtaIni
        var ETA = 0.0
        var CellTemp = 0.0

        while DummyErr > ERR:
            var cell_mode = pv.CellIntegrationMode
            if cell_mode == CellIntegrationDecoupled:
                pv.TRNSYSPVModule.HeatLossCoef = (pv.TRNSYSPVModule.TauAlpha * pv.TRNSYSPVModule.NOCTInsolation /
                    (pv.TRNSYSPVModule.NOCTCellTemp - pv.TRNSYSPVModule.NOCTAmbTemp))
                CellTemp = (Tambient + (pv.TRNSYSPVcalc.Insolation * pv.TRNSYSPVModule.TauAlpha /
                    pv.TRNSYSPVModule.HeatLossCoef) * (1.0 - ETA / pv.TRNSYSPVModule.TauAlpha))
            elif cell_mode == CellIntegrationDecoupledUllebergDynamic:
                CellTemp = (Tambient + (pv.TRNSYSPVcalc.LastCellTempK - Tambient) *
                    exp(-pv.TRNSYSPVModule.HeatLossCoef / pv.TRNSYSPVModule.HeatCapacity *
                    state.dataPhotovoltaicState.PVTimeStep) + (pv.TRNSYSPVModule.TauAlpha - ETA) *
                    pv.TRNSYSPVcalc.Insolation / pv.TRNSYSPVModule.HeatLossCoef *
                    (1.0 - exp(-pv.TRNSYSPVModule.HeatLossCoef / pv.TRNSYSPVModule.HeatCapacity *
                    state.dataPhotovoltaicState.PVTimeStep)))
            elif cell_mode == CellIntegrationSurfaceOutsideFace:
                CellTemp = state.dataHeatBalSurf.SurfTempOut[pv.SurfacePtr - 1] + Constant.Kelvin
            elif cell_mode == CellIntegrationTranspiredCollector:
                GetUTSCTsColl(state, pv.UTSCPtr, CellTemp)
                CellTemp += Constant.Kelvin
            elif cell_mode == CellIntegrationExteriorVentedCavity:
                GetExtVentedCavityTsColl(state, pv.ExtVentCavPtr, CellTemp)
                CellTemp += Constant.Kelvin
            elif cell_mode == CellIntegrationPVTSolarCollector:
                GetPVTTsColl(state, pv.PVTPtr, CellTemp)
                CellTemp += Constant.Kelvin

            var ILRef = pv.TRNSYSPVModule.RefIsc
            var AARef = ((pv.TRNSYSPVModule.TempCoefVoc * pv.TRNSYSPVModule.RefTemperature -
                pv.TRNSYSPVModule.RefVoc + pv.TRNSYSPVModule.SemiConductorBandgap *
                pv.TRNSYSPVModule.CellsInSeries) /
                (pv.TRNSYSPVModule.TempCoefIsc * pv.TRNSYSPVModule.RefTemperature / ILRef - 3.0))

            var IORef = ILRef * exp(-pv.TRNSYSPVModule.RefVoc / AARef)

            var SeriesResistance = ((AARef * log(1.0 - pv.TRNSYSPVModule.Imp / ILRef) -
                pv.TRNSYSPVModule.Vmp + pv.TRNSYSPVModule.RefVoc) /
                pv.TRNSYSPVModule.Imp)

            var IL = (pv.TRNSYSPVcalc.Insolation / pv.TRNSYSPVModule.RefInsolation *
                (ILRef + pv.TRNSYSPVModule.TempCoefIsc *
                (CellTemp - pv.TRNSYSPVModule.RefTemperature)))

            var cell_temp_ratio = CellTemp / pv.TRNSYSPVModule.RefTemperature
            var AA = AARef * cell_temp_ratio
            var IO = IORef * pow(cell_temp_ratio, 3.0) * exp(
                pv.TRNSYSPVModule.SemiConductorBandgap * pv.TRNSYSPVModule.CellsInSeries / AARef *
                (1.0 - pv.TRNSYSPVModule.RefTemperature / CellTemp))

            var ISCG1 = IL
            var ISC = ISCG1
            NEWTON(state, ISC, lambda st, II, VV, IL_, IO_, RS, AA_: FUN(st, II, VV, IL_, IO_, RS, AA_),
                   lambda st, II, VV, IO_, RS, AA_: FI(st, II, VV, IO_, RS, AA_),
                   ISC, 0.0, IO, IL, SeriesResistance, AA, ISCG1, EPS)

            var VOCG1 = (log(IL / IO) + 1.0) * AA
            var VOC = VOCG1
            NEWTON(state, VOC, lambda st, II, VV, IL_, IO_, RS, AA_: FUN(st, II, VV, IL_, IO_, RS, AA_),
                   lambda st, II, VV, IO_, RS, AA_: FV(st, II, VV, IO_, RS, AA_),
                   0.0, VOC, IO, IL, SeriesResistance, AA, VOCG1, EPS)

            var VLEFT = 0.0
            var VRIGHT = VOC
            var VM = 0.0
            var K = 0
            SEARCH(state, VLEFT, VRIGHT, VM, K, IO, IL, SeriesResistance, AA, EPS, KMAX)

            var IM = 0.0
            var PM = 0.0
            POWER(state, IO, IL, SeriesResistance, AA, EPS, IM, VM, PM)

            ETA = PM / pv.TRNSYSPVcalc.Insolation / pv.TRNSYSPVModule.Area
            DummyErr = abs((ETA - EtaOld) / EtaOld) if EtaOld != 0 else 0
            EtaOld = ETA

    else:
        var cell_mode = pv.CellIntegrationMode
        var CellTemp = 0.0
        if cell_mode == CellIntegrationDecoupled:
            CellTemp = Tambient
        elif cell_mode == CellIntegrationDecoupledUllebergDynamic:
            CellTemp = (Tambient + (pv.TRNSYSPVcalc.LastCellTempK - Tambient) *
                exp(-pv.TRNSYSPVModule.HeatLossCoef / pv.TRNSYSPVModule.HeatCapacity *
                state.dataPhotovoltaicState.PVTimeStep))
        elif cell_mode == CellIntegrationSurfaceOutsideFace:
            CellTemp = state.dataHeatBalSurf.SurfTempOut[pv.SurfacePtr - 1] + Constant.Kelvin
        elif cell_mode == CellIntegrationTranspiredCollector:
            GetUTSCTsColl(state, pv.UTSCPtr, CellTemp)
            CellTemp += Constant.Kelvin
        elif cell_mode == CellIntegrationExteriorVentedCavity:
            GetExtVentedCavityTsColl(state, pv.ExtVentCavPtr, CellTemp)
            CellTemp += Constant.Kelvin
        elif cell_mode == CellIntegrationPVTSolarCollector:
            GetPVTTsColl(state, pv.PVTPtr, CellTemp)
            CellTemp += Constant.Kelvin

        pv.TRNSYSPVcalc.Insolation = 0.0
        var IM = 0.0
        var VM = 0.0
        var PM = 0.0
        var ETA = 0.0
        var ISC = 0.0
        var VOC = 0.0

    var CellTempC = CellTemp - Constant.Kelvin

    var IA = pv.NumSeriesNParall * IM
    var ISCA = pv.NumSeriesNParall * ISC
    var VA = pv.NumModNSeries * VM
    var VOCA = pv.NumModNSeries * VOC
    var PA = IA * VA

    pv.TRNSYSPVcalc.ArrayCurrent = IA
    pv.TRNSYSPVcalc.ArrayVoltage = VA
    pv.TRNSYSPVcalc.ArrayPower = PA
    pv.Report.DCPower = PA
    pv.TRNSYSPVcalc.ArrayEfficiency = ETA
    pv.Report.ArrayEfficiency = ETA
    pv.TRNSYSPVcalc.CellTemp = CellTempC
    pv.Report.CellTemp = CellTempC
    pv.TRNSYSPVcalc.CellTempK = CellTemp
    pv.TRNSYSPVcalc.ArrayIsc = ISCA
    pv.Report.ArrayIsc = ISCA
    pv.TRNSYSPVcalc.ArrayVoc = VOCA
    pv.Report.ArrayVoc = VOCA
    pv.SurfaceSink = PA

@export
fn POWER(state, IO: Float64, IL: Float64, RSER: Float64, AA: Float64, EPS: Float64, inout II: Float64, VV: Float64, inout PP: Float64):
    var IG1 = IL - IO * exp(VV / AA - 1.0)
    II = IG1
    NEWTON(state, II, lambda st, II_, VV_, IL_, IO_, RS, AA_: FUN(st, II_, VV_, IL_, IO_, RS, AA_),
           lambda st, II_, VV_, IO_, RS, AA_: FI(st, II_, VV_, IO_, RS, AA_),
           II, VV, IO, IL, RSER, AA, IG1, EPS)
    PP = II * VV

@export
fn NEWTON(state, inout XX: Float64, FXX: fn(state, Float64, Float64, Float64, Float64, Float64, Float64) -> Float64, 
          DER: fn(state, Float64, Float64, Float64, Float64, Float64) -> Float64,
          II: Float64, VV: Float64, IO: Float64, IL: Float64, RSER: Float64, AA: Float64, XS: Float64, EPS: Float64):
    var COUNT = 0
    XX = XS
    var ERR = 1.0

    while (ERR > EPS) and (COUNT <= 10):
        var X0 = XX
        XX -= FXX(state, II, VV, IL, IO, RSER, AA) / DER(state, II, VV, IO, RSER, AA)
        COUNT += 1
        ERR = abs((XX - X0) / X0) if X0 != 0 else 0

@export
fn SEARCH(state, inout A: Float64, inout B: Float64, inout P: Float64, inout K: Int32, IO: Float64, IL: Float64, RSER: Float64, AA: Float64, EPS: Float64, KMAX: Int32):
    var DELTA = 1.0e-3
    var EPSILON = 1.0e-3
    var RONE = (sqrt(5.0) - 1.0) / 2.0
    var RTWO = RONE * RONE

    var H = B - A
    var IM = 0.0
    var PM = 0.0
    POWER(state, IO, IL, RSER, AA, EPS, IM, A, PM)
    var YA = -1.0 * PM

    POWER(state, IO, IL, RSER, AA, EPS, IM, B, PM)
    var YB = -1.0 * PM

    var C = A + RTWO * H
    var D = A + RONE * H

    POWER(state, IO, IL, RSER, AA, EPS, IM, C, PM)
    var YC = -1.0 * PM

    POWER(state, IO, IL, RSER, AA, EPS, IM, D, PM)
    var YD = -1.0 * PM

    K = 1

    while (abs(YB - YA) > EPSILON or H > DELTA):
        if YC < YD:
            B = D
            YB = YD
            D = C
            YD = YC
            H = B - A
            C = A + RTWO * H
            POWER(state, IO, IL, RSER, AA, EPS, IM, C, PM)
            YC = -1.0 * PM
        else:
            A = C
            YA = YC
            C = D
            YC = YD
            H = B - A
            D = A + RONE * H
            POWER(state, IO, IL, RSER, AA, EPS, IM, D, PM)
            YD = -1.0 * PM
        K += 1

    if K < KMAX:
        P = A
        var YP = YA
        if YB < YA:
            P = B
            YP = YB

@export
fn FUN(state, II: Float64, VV: Float64, IL: Float64, IO: Float64, RSER: Float64, AA: Float64) -> Float64:
    var FUN_val = 0.0

    if (((VV + II * RSER) / AA) < 700.0):
        FUN_val = II - IL + IO * (exp((VV + II * RSER) / AA) - 1.0) - ((VV + II * RSER) / state.dataPhotovoltaic.ShuntResistance)
    else:
        ShowSevereError(state, "EquivalentOneDiode Photovoltaic model failed to find maximum power point")
        ShowContinueError(state, "Numerical solver failed trying to take exponential of too large a number")
        ShowContinueError(state, "Check input data in " + get_pv_model_names()[PVModelTRNSYS])
        ShowContinueError(state, "VV (voltage) = " + str(VV))
        ShowContinueError(state, "II (current) = " + str(II))
        ShowFatalError(state, "FUN: EnergyPlus terminates because of numerical problem in EquivalentOne-Diode PV model")

    return FUN_val

@export
fn FI(state, II: Float64, VV: Float64, IO: Float64, RSER: Float64, AA: Float64) -> Float64:
    var FI_val = 0.0

    if (((VV + II * RSER) / AA) < 700.0):
        FI_val = 1.0 + IO * exp((VV + II * RSER) / AA) * RSER / AA + (RSER / state.dataPhotovoltaic.ShuntResistance)
    else:
        ShowSevereError(state, "EquivalentOneDiode Photovoltaic model failed to find maximum power point")
        ShowContinueError(state, "Numerical solver failed trying to take exponential of too large a number")
        ShowContinueError(state, "Check input data in " + get_pv_model_names()[PVModelTRNSYS])
        ShowContinueError(state, "VV (voltage) = " + str(VV))
        ShowContinueError(state, "II (current) = " + str(II))
        ShowFatalError(state, "FI: EnergyPlus terminates because of numerical problem in EquivalentOne-Diode PV model")

    return FI_val

@export
fn FV(state, II: Float64, VV: Float64, IO: Float64, RSER: Float64, AA: Float64) -> Float64:
    var FV_val = 0.0

    if (((VV + II * RSER) / AA) < 700.0):
        FV_val = IO * exp((VV + II * RSER) / AA) / AA + (1.0 / state.dataPhotovoltaic.ShuntResistance)
    else:
        ShowSevereError(state, "EquivalentOneDiode Photovoltaic model failed to find maximum power point")
        ShowContinueError(state, "Numerical solver failed trying to take exponential of too large a number")
        ShowContinueError(state, "Check input data in " + get_pv_model_names()[PVModelTRNSYS])
        ShowContinueError(state, "VV (voltage) = " + str(VV))
        ShowContinueError(state, "II (current) = " + str(II))
        ShowFatalError(state, "FI: EnergyPlus terminates because of numerical problem in EquivalentOne-Diode PV model")

    return FV_val

@export
fn SandiaModuleTemperature(Ibc: Float64, Idc: Float64, Ws: Float64, Ta: Float64, fd: Float64, a: Float64, b: Float64) -> Float64:
    var E = Ibc + fd * Idc
    return E * exp(a + b * Ws) + Ta

@export
fn SandiaTcellFromTmodule(Tm: Float64, Ibc: Float64, Idc: Float64, fd: Float64, DT0: Float64) -> Float64:
    var E = Ibc + fd * Idc
    return Tm + (E / 1000.0) * DT0

@export
fn SandiaCellTemperature(Ibc: Float64, Idc: Float64, Ws: Float64, Ta: Float64, fd: Float64, a: Float64, b: Float64, DT0: Float64) -> Float64:
    var E = Ibc + fd * Idc
    var Tm = E * exp(a + b * Ws) + Ta
    return Tm + (E / 1000.0) * DT0

@export
fn SandiaEffectiveIrradiance(Tc: Float64, Isc: Float64, Isc0: Float64, aIsc: Float64) -> Float64:
    return Isc / (1.0 + aIsc * (Tc - 25.0)) / Isc0

@export
fn AbsoluteAirMass(SolZen: Float64, Altitude: Float64) -> Float64:
    if SolZen < 89.9:
        var AM = 1.0 / (cos(SolZen * Constant.DegToRad) + 0.5057 * pow(96.08 - SolZen, -1.634))
        return exp(-0.0001184 * Altitude) * AM
    else:
        var AM = 36.32
        return exp(-0.0001184 * Altitude) * AM

@export
fn SandiaF1(AMa: Float64, a0: Float64, a1: Float64, a2: Float64, a3: Float64, a4: Float64) -> Float64:
    var F1 = a0 + a1 * AMa + a2 * pow(AMa, 2.0) + a3 * pow(AMa, 3.0) + a4 * pow(AMa, 4.0)
    return F1 if F1 > 0.0 else 0.0

@export
fn SandiaF2(IncAng: Float64, b0: Float64, b1: Float64, b2: Float64, b3: Float64, b4: Float64, b5: Float64) -> Float64:
    var F2 = b0 + b1 * IncAng + b2 * pow(IncAng, 2.0) + b3 * pow(IncAng, 3.0) + b4 * pow(IncAng, 4.0) + b5 * pow(IncAng, 5.0)
    return F2 if F2 > 0.0 else 0.0

@export
fn SandiaImp(Tc: Float64, Ee: Float64, Imp0: Float64, aImp: Float64, C0: Float64, C1: Float64) -> Float64:
    return Imp0 * (C0 * Ee + C1 * pow(Ee, 2.0)) * (1.0 + aImp * (Tc - 25.0))

@export
fn SandiaIsc(Tc: Float64, Isc0: Float64, Ibc: Float64, Idc: Float64, F1: Float64, F2: Float64, fd: Float64, aIsc: Float64) -> Float64:
    return Isc0 * F1 * ((Ibc * F2 + fd * Idc) / 1000.0) * (1.0 + aIsc * (Tc - 25.0))

@export
fn SandiaIx(Tc: Float64, Ee: Float64, Ix0: Float64, aIsc: Float64, aImp: Float64, C4: Float64, C5: Float64) -> Float64:
    return Ix0 * (C4 * Ee + C5 * pow(Ee, 2.0)) * (1.0 + ((aIsc + aImp) / 2.0) * (Tc - 25.0))

@export
fn SandiaIxx(Tc: Float64, Ee: Float64, Ixx0: Float64, aImp: Float64, C6: Float64, C7: Float64) -> Float64:
    return Ixx0 * (C6 * Ee + C7 * pow(Ee, 2.0)) * (1.0 + aImp * (Tc - 25.0))

@export
fn SandiaVmp(Tc: Float64, Ee: Float64, Vmp0: Float64, NcellSer: Float64, DiodeFactor: Float64, BVmp0: Float64, mBVmp: Float64, C2: Float64, C3: Float64) -> Float64:
    if Ee > 0.0:
        var dTc = DiodeFactor * ((1.38066e-23 * (Tc + Constant.Kelvin)) / 1.60218e-19)
        var BVmpEe = BVmp0 + mBVmp * (1.0 - Ee)
        return Vmp0 + C2 * NcellSer * dTc * log(Ee) + C3 * NcellSer * pow(dTc * log(Ee), 2.0) + BVmpEe * (Tc - 25.0)
    else:
        return 0.0

@export
fn SandiaVoc(Tc: Float64, Ee: Float64, Voc0: Float64, NcellSer: Float64, DiodeFactor: Float64, BVoc0: Float64, mBVoc: Float64) -> Float64:
    if Ee > 0.0:
        var dTc = DiodeFactor * ((1.38066e-23 * (Tc + Constant.Kelvin)) / 1.60218e-19)
        var BVocEe = BVoc0 + mBVoc * (1.0 - Ee)
        return Voc0 + NcellSer * dTc * log(Ee) + BVocEe * (Tc - 25.0)
    else:
        return 0.0

@export
fn SetVentedModuleQdotSource(state, VentModNum: Int32, QSource: Float64):
    state.dataHeatBal.ExtVentedCavity[VentModNum - 1].QdotSource = QSource / state.dataHeatBal.ExtVentedCavity[VentModNum - 1].ProjArea

@export
fn GetExtVentedCavityIndex(state, SurfacePtr: Int32, inout VentCavIndex: Int32):
    if SurfacePtr == 0:
        ShowFatalError(state, "Invalid surface passed to GetExtVentedCavityIndex")

    var CavNum = 0
    var Found = False

    for thisCav in range(state.dataSurface.TotExtVentCav):
        for ThisSurf in range(state.dataHeatBal.ExtVentedCavity[thisCav].NumSurfs):
            if SurfacePtr == state.dataHeatBal.ExtVentedCavity[thisCav].SurfPtrs[ThisSurf]:
                Found = True
                CavNum = thisCav + 1

    if not Found:
        ShowFatalError(state, "Did not find surface in Exterior Vented Cavity description in GetExtVentedCavityIndex, Surface name = " + state.dataSurface.Surface[SurfacePtr - 1].Name)
    else:
        VentCavIndex = CavNum

@export
fn GetExtVentedCavityTsColl(state, VentModNum: Int32, inout TsColl: Float64):
    TsColl = state.dataHeatBal.ExtVentedCavity[VentModNum - 1].Tbaffle

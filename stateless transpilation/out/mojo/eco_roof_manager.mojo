"""
EcoRoofManager: Green roof simulation module.
Translated from EnergyPlus EcoRoofManager C++ module.
"""

from math import exp, log, sqrt, pow


alias Real64 = Float64

fn _min(a: Real64, b: Real64) -> Real64:
    return a if a < b else b

fn _max(a: Real64, b: Real64) -> Real64:
    return a if a > b else b

fn _pow3(x: Real64) -> Real64:
    return x * x * x

fn _pow4(x: Real64) -> Real64:
    return x * x * x * x


struct EcoRoofManagerData:
    var CumRunoff: Real64
    var CumET: Real64
    var CumPrecip: Real64
    var CumIrrigation: Real64
    var MonthlyIrrigation: DynamicVector[Real64]
    var CurrentRunoff: Real64
    var CurrentET: Real64
    var CurrentPrecipitation: Real64
    var CurrentIrrigation: Real64
    var Tfold: Real64
    var Tgold: Real64
    var EcoRoofbeginFlag: Bool
    var CalcEcoRoofMyEnvrnFlag: Bool
    var FirstEcoSurf: Int32
    var QuickConductionSurf: Bool
    var LAI: Real64
    var epsilonf: Real64
    var epsilong: Real64
    var Alphag: Real64
    var Alphaf: Real64
    var e0: Real64
    var RH: Real64
    var Pa: Real64
    var Tg: Real64
    var Tf: Real64
    var Zf: Real64
    var Moisture: Real64
    var MoistureResidual: Real64
    var MoistureMax: Real64
    var MeanRootMoisture: Real64
    var SoilThickness: Real64
    var StomatalResistanceMin: Real64
    var f3: Real64
    var Zog: Real64
    var Za: Real64
    var Lf: Real64
    var Vfluxf: Real64
    var Qsoil: Real64
    var sheatf: Real64
    var sensiblef: Real64
    var sheatg: Real64
    var sensibleg: Real64
    var Lg: Real64
    var Vfluxg: Real64
    var TopDepth: Real64
    var RootDepth: Real64
    var TimeStepZoneSec: Real64
    var DryCond: Real64
    var DryDens: Real64
    var DryAbsorp: Real64
    var DrySpecHeat: Real64
    var UpdatebeginFlag: Bool
    var CapillaryPotentialTop: Real64
    var CapillaryPotentialRoot: Real64
    var SoilHydroConductivityTop: Real64
    var SoilHydroConductivityRoot: Real64
    var SoilConductivityAveTop: Real64
    var SoilConductivityAveRoot: Real64
    var RelativeSoilSaturationTop: Real64
    var RelativeSoilSaturationRoot: Real64
    var TestMoisture: Real64
    var ErrIndex: Int32
    
    fn __init__(inout self) -> None:
        self.CumRunoff = 0.0
        self.CumET = 0.0
        self.CumPrecip = 0.0
        self.CumIrrigation = 0.0
        self.MonthlyIrrigation = DynamicVector[Real64]()
        for _ in range(12):
            self.MonthlyIrrigation.push_back(0.0)
        self.CurrentRunoff = 0.0
        self.CurrentET = 0.0
        self.CurrentPrecipitation = 0.0
        self.CurrentIrrigation = 0.0
        self.Tfold = 0.0
        self.Tgold = 0.0
        self.EcoRoofbeginFlag = True
        self.CalcEcoRoofMyEnvrnFlag = True
        self.FirstEcoSurf = 0
        self.QuickConductionSurf = False
        self.LAI = 0.2
        self.epsilonf = 0.95
        self.epsilong = 0.95
        self.Alphag = 0.3
        self.Alphaf = 0.2
        self.e0 = 2.0
        self.RH = 50.0
        self.Pa = 101325.0
        self.Tg = 10.0
        self.Tf = 10.0
        self.Zf = 0.2
        self.Moisture = 0.0
        self.MoistureResidual = 0.05
        self.MoistureMax = 0.5
        self.MeanRootMoisture = 0.0
        self.SoilThickness = 0.2
        self.StomatalResistanceMin = 0.0
        self.f3 = 1.0
        self.Zog = 0.001
        self.Za = 2.0
        self.Lf = 0.0
        self.Vfluxf = 0.0
        self.Qsoil = 0.0
        self.sheatf = 0.0
        self.sensiblef = 0.0
        self.sheatg = 0.0
        self.sensibleg = 0.0
        self.Lg = 0.0
        self.Vfluxg = 0.0
        self.TopDepth = 0.0
        self.RootDepth = 0.0
        self.TimeStepZoneSec = 0.0
        self.DryCond = 0.0
        self.DryDens = 0.0
        self.DryAbsorp = 0.0
        self.DrySpecHeat = 0.0
        self.UpdatebeginFlag = True
        self.CapillaryPotentialTop = -3.8997
        self.CapillaryPotentialRoot = -3.8997
        self.SoilHydroConductivityTop = 8.72e-6
        self.SoilHydroConductivityRoot = 8.72e-6
        self.SoilConductivityAveTop = 8.72e-6
        self.SoilConductivityAveRoot = 8.72e-6
        self.RelativeSoilSaturationTop = 0.0
        self.RelativeSoilSaturationRoot = 0.0
        self.TestMoisture = 0.15
        self.ErrIndex = 0
    
    fn init_constant_state(inout self, state: AnyType) -> None:
        pass
    
    fn init_state(inout self, state: AnyType) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        self.EcoRoofbeginFlag = True
        self.CalcEcoRoofMyEnvrnFlag = True
        self.FirstEcoSurf = 0
        self.QuickConductionSurf = False
        self.LAI = 0.2
        self.epsilonf = 0.95
        self.epsilong = 0.95
        self.Alphag = 0.3
        self.Alphaf = 0.2
        self.e0 = 2.0
        self.RH = 50.0
        self.Pa = 101325.0
        self.Tg = 10.0
        self.Tf = 10.0
        self.Zf = 0.2
        self.Moisture = 0.0
        self.MoistureResidual = 0.05
        self.MoistureMax = 0.5
        self.MeanRootMoisture = 0.0
        self.SoilThickness = 0.2
        self.StomatalResistanceMin = 0.0
        self.f3 = 1.0
        self.Zog = 0.001
        self.Za = 2.0
        self.Lf = 0.0
        self.Vfluxf = 0.0
        self.Qsoil = 0.0
        self.sheatf = 0.0
        self.sensiblef = 0.0
        self.sheatg = 0.0
        self.sensibleg = 0.0
        self.Lg = 0.0
        self.Vfluxg = 0.0
        self.TopDepth = 0.0
        self.RootDepth = 0.0
        self.TimeStepZoneSec = 0.0
        self.DryCond = 0.0
        self.DryDens = 0.0
        self.DryAbsorp = 0.0
        self.DrySpecHeat = 0.0
        self.UpdatebeginFlag = True
        self.CapillaryPotentialTop = -3.8997
        self.CapillaryPotentialRoot = -3.8997
        self.SoilHydroConductivityTop = 8.72e-6
        self.SoilHydroConductivityRoot = 8.72e-6
        self.SoilConductivityAveTop = 8.72e-6
        self.SoilConductivityAveRoot = 8.72e-6
        self.RelativeSoilSaturationTop = 0.0
        self.RelativeSoilSaturationRoot = 0.0
        self.TestMoisture = 0.15
        self.ErrIndex = 0


fn CalcEcoRoof(inout state: AnyType, SurfNum: Int32, ConstrNum: Int32) -> Real64:
    var Ws: Real64 = state.dataEnvironment.WindSpeedAt(state, state.dataSurface.Surface(SurfNum).Centroid.z)
    if Ws < 2.0:
        Ws = 2.0
    
    var thisConstruct = state.dataConstruction.Construct(ConstrNum)
    var thisMaterial = state.dataMaterial.materials(thisConstruct.LayerPoint(1))
    var RoughSurf = thisMaterial.Roughness
    var AbsThermSurf: Real64 = thisMaterial.AbsorpThermal
    var HMovInsul: Real64 = 0.0
    
    if state.dataSurface.Surface(SurfNum).ExtWind:
        state.dataConvect.InitExtConvCoeff(
            state, SurfNum, HMovInsul, RoughSurf, AbsThermSurf,
            state.dataHeatBalSurf.SurfOutsideTempHist(1)[SurfNum],
            state.dataHeatBalSurf.SurfHConvExt(SurfNum),
            state.dataHeatBalSurf.SurfHSkyExt(SurfNum),
            state.dataHeatBalSurf.SurfHGrdExt(SurfNum),
            state.dataHeatBalSurf.SurfHAirExt(SurfNum),
            state.dataHeatBalSurf.SurfHSrdSurfExt(SurfNum)
        )
    
    var Latm: Real64 = (5.6697e-08 * state.dataSurface.Surface(SurfNum).ViewFactorGround * 
            _pow4(state.dataEnvrn.GroundTempKelvin) +
            5.6697e-08 * state.dataSurface.Surface(SurfNum).ViewFactorSky * 
            _pow4(state.dataEnvrn.SkyTempKelvin))
    
    if state.dataEcoRoofMgr.EcoRoofbeginFlag:
        initEcoRoofFirstTime(state, SurfNum, ConstrNum)
    
    initEcoRoof(state, SurfNum, ConstrNum)
    
    var TempExt: Real64 = state.dataEcoRoofMgr.Tgold
    
    if SurfNum == state.dataEcoRoofMgr.FirstEcoSurf:
        var unit: Int32 = 0
        UpdateSoilProps(
            state,
            state.dataEcoRoofMgr.Moisture,
            state.dataEcoRoofMgr.MeanRootMoisture,
            state.dataEcoRoofMgr.MoistureMax,
            state.dataEcoRoofMgr.MoistureResidual,
            state.dataEcoRoofMgr.SoilThickness,
            state.dataEcoRoofMgr.Vfluxf,
            state.dataEcoRoofMgr.Vfluxg,
            ConstrNum,
            state.dataEcoRoofMgr.Alphag,
            unit,
            state.dataEcoRoofMgr.Tg,
            state.dataEcoRoofMgr.Tf,
            state.dataEcoRoofMgr.Qsoil
        )
        
        var Ta: Real64 = state.dataEnvironment.OutDryBulbTempAt(
            state, state.dataSurface.Surface(SurfNum).Centroid.z)
        state.dataEcoRoofMgr.Tg = state.dataEcoRoofMgr.Tgold
        state.dataEcoRoofMgr.Tf = state.dataEcoRoofMgr.Tfold
        
        var F1temp: Real64
        var Qsoilpart1: Real64
        var Qsoilpart2: Real64
        
        if thisConstruct.CTFCross[0] > 0.01:
            state.dataEcoRoofMgr.QuickConductionSurf = True
            var spaceNum: Int32 = state.dataSurface.Surface(SurfNum).spaceNum
            F1temp = (thisConstruct.CTFCross[0] / 
                     (thisConstruct.CTFInside[0] + state.dataHeatBalSurf.SurfHConvInt(SurfNum)))
            Qsoilpart1 = (
                -state.dataHeatBalSurf.SurfCTFConstOutPart(SurfNum) +
                F1temp * (state.dataHeatBalSurf.SurfCTFConstInPart(SurfNum) +
                         state.dataHeatBalSurf.SurfOpaqQRadSWInAbs(SurfNum) +
                         state.dataHeatBal.SurfQdotRadIntGainsInPerArea(SurfNum) +
                         thisConstruct.CTFSourceIn[0] * state.dataHeatBalSurf.SurfQsrcHist(SurfNum, 1) +
                         state.dataHeatBalSurf.SurfHConvInt(SurfNum) * 
                         state.dataZoneTempPredictorCorrector.spaceHeatBalance(spaceNum).MAT +
                         state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea(SurfNum))
            )
        else:
            Qsoilpart1 = (
                -state.dataHeatBalSurf.SurfCTFConstOutPart(SurfNum) +
                thisConstruct.CTFCross[0] * state.dataHeatBalSurf.SurfTempIn(SurfNum)
            )
            F1temp = 0.0
        
        Qsoilpart2 = thisConstruct.CTFOutside[0] - F1temp * thisConstruct.CTFCross[0]
        
        state.dataEcoRoofMgr.Pa = state.dataEnvrn.StdBaroPress
        var Tgk: Real64 = state.dataEcoRoofMgr.Tg + 273.15
        var Tak: Real64 = Ta + 273.15
        
        var sigmaf: Real64 = 0.9 - 0.7 * exp(-0.75 * state.dataEcoRoofMgr.LAI)
        
        var EpsilonOne: Real64 = (state.dataEcoRoofMgr.epsilonf + state.dataEcoRoofMgr.epsilong -
                     state.dataEcoRoofMgr.epsilong * state.dataEcoRoofMgr.epsilonf)
        state.dataEcoRoofMgr.RH = state.dataEnvrn.OutRelHum
        var eair: Real64 = (state.dataEcoRoofMgr.RH / 100.0) * 611.2 * exp(17.67 * Ta / (Tak - 29.65))
        var qa: Real64 = (0.622 * eair) / (state.dataEcoRoofMgr.Pa - 1.0 * eair)
        var Rhoa: Real64 = state.dataEcoRoofMgr.Pa / (286.0e3 * Tak)
        var Tif: Real64 = state.dataEcoRoofMgr.Tf
        
        var Tafk: Real64 = ((1.0 - sigmaf) * Tak + 
                sigmaf * (0.3 * Tak + 0.6 * (Tif + 273.15) + 0.1 * Tgk))
        
        var Taf: Real64 = Tafk - 273.15
        var Rhof: Real64 = state.dataEcoRoofMgr.Pa / (286.0e3 * Tafk)
        var Rhoaf: Real64 = (Rhoa + Rhof) / 2.0
        var Zd: Real64 = 0.701 * pow(state.dataEcoRoofMgr.Zf, 0.979)
        var Zo: Real64 = 0.131 * pow(state.dataEcoRoofMgr.Zf, 0.997)
        if Zo < 0.02:
            Zo = 0.02
        
        var Cfhn: Real64 = pow(0.4 / log((state.dataEcoRoofMgr.Za - Zd) / Zo), 2.0)
        var Waf: Real64 = 0.83 * sqrt(Cfhn) * sigmaf * Ws + (1.0 - sigmaf) * Ws
        var Cf: Real64 = 0.01 * (1.0 + 0.3 / Waf)
        state.dataEcoRoofMgr.sheatf = (state.dataEcoRoofMgr.e0 + 
                                       1.1 * state.dataEcoRoofMgr.LAI * Rhoaf * 1005.6 * Cf * Waf)
        state.dataEcoRoofMgr.sensiblef = state.dataEcoRoofMgr.sheatf * (Taf - state.dataEcoRoofMgr.Tf)
        
        var esf: Real64 = 611.2 * exp(17.67 * Tif / (Tif + 273.15 - 29.65))
        var qsf: Real64 = 0.622 * esf / (state.dataEcoRoofMgr.Pa - 1.0 * esf)
        
        var ra: Real64 = 1.0 / (Cf * Waf)
        
        CalculateEcoRoofSolar(state, SurfNum)
        var RS: Real64 = state._eco_RS
        var f1: Real64 = state._eco_f1
        
        var f2inv: Real64
        if state.dataEcoRoofMgr.MoistureMax == state.dataEcoRoofMgr.MoistureResidual:
            f2inv = 1.0e10
        else:
            f2inv = ((state.dataEcoRoofMgr.MeanRootMoisture - state.dataEcoRoofMgr.MoistureResidual) /
                    (state.dataEcoRoofMgr.MoistureMax - state.dataEcoRoofMgr.MoistureResidual))
        
        var f2: Real64 = 1.0 / f2inv
        state.dataEcoRoofMgr.f3 = 1.0 / exp(-0.0 * (esf - eair))
        var r_s: Real64 = (state.dataEcoRoofMgr.StomatalResistanceMin * f1 * f2 * state.dataEcoRoofMgr.f3 /
               state.dataEcoRoofMgr.LAI)
        var rn: Real64 = ra / (ra + r_s)
        
        var Mg: Real64 = state.dataEcoRoofMgr.Moisture / state.dataEcoRoofMgr.MoistureMax
        var dOne: Real64 = 1.0 - sigmaf * (0.6 * (1.0 - rn) + 0.1 * (1.0 - Mg))
        
        var Lef: Real64 = 1.91846e6 * pow((Tif + 273.15) / (Tif + 273.15 - 33.91), 2.0)
        if state.dataEcoRoofMgr.Tfold < 0.0:
            Lef = 2.838e6
        
        var Desf: Real64 = (611.2 * exp(17.67 * (state.dataEcoRoofMgr.Tf / 
                (state.dataEcoRoofMgr.Tf + 273.15 - 29.65))) *
                (17.67 * state.dataEcoRoofMgr.Tf * (-1.0) * 
                 pow(state.dataEcoRoofMgr.Tf + 273.15 - 29.65, -2.0) +
                 17.67 / (273.15 - 29.65 + state.dataEcoRoofMgr.Tf)))
        var dqf: Real64 = ((0.622 * state.dataEcoRoofMgr.Pa) / 
               pow(state.dataEcoRoofMgr.Pa - esf, 2.0)) * Desf
        
        var esg: Real64 = 611.2 * exp(17.67 * (state.dataEcoRoofMgr.Tg /
                ((state.dataEcoRoofMgr.Tg + 273.15) - 29.65)))
        var qsg: Real64 = 0.622 * esg / (state.dataEcoRoofMgr.Pa - esg)
        
        var Leg: Real64 = 1.91846e6 * pow(Tgk / (Tgk - 33.91), 2.0)
        if state.dataEcoRoofMgr.Tgold < 0.0:
            Leg = 2.838e6
        
        var Desg: Real64 = (611.2 * exp(17.67 * (state.dataEcoRoofMgr.Tg / 
                (state.dataEcoRoofMgr.Tg + 273.15 - 29.65))) *
                (17.67 * state.dataEcoRoofMgr.Tg * (-1.0) * 
                 pow(state.dataEcoRoofMgr.Tg + 273.15 - 29.65, -2.0) +
                 17.67 / (273.15 - 29.65 + state.dataEcoRoofMgr.Tg)))
        var dqg: Real64 = (0.622 * state.dataEcoRoofMgr.Pa / 
               pow(state.dataEcoRoofMgr.Pa - esg, 2.0)) * Desg
        
        var Rhog: Real64 = state.dataEcoRoofMgr.Pa / (286.0e3 * Tgk)
        var Rhoag: Real64 = (Rhoa + Rhog) / 2.0
        var Rib: Real64 = (2.0 * 9.81 * state.dataEcoRoofMgr.Za * (Taf - state.dataEcoRoofMgr.Tg) /
               ((Tafk + Tgk) * pow(Waf, 2.0)))
        
        var Gammah: Real64
        if Rib < 0.0:
            Gammah = pow(1.0 - 16.0 * Rib, -0.5)
        else:
            if Rib >= 0.19:
                Rib = 0.19
            Gammah = pow(1.0 - 5.0 * Rib, -0.5)
        
        var Chng: Real64 = pow(0.4 / log(state.dataEcoRoofMgr.Za / state.dataEcoRoofMgr.Zog), 2.0) / 0.63
        var Chg: Real64 = Gammah * ((1.0 - sigmaf) * Chng + sigmaf * Cfhn)
        state.dataEcoRoofMgr.sheatg = state.dataEcoRoofMgr.e0 + Rhoag * 1005.6 * Chg * Waf
        state.dataEcoRoofMgr.sensibleg = state.dataEcoRoofMgr.sheatg * (Taf - state.dataEcoRoofMgr.Tg)
        
        var Chne: Real64 = pow(0.4 / log(state.dataEcoRoofMgr.Za / state.dataEcoRoofMgr.Zog), 2.0) / 0.71
        var Ce: Real64 = Gammah * ((1.0 - sigmaf) * Chne + sigmaf * Cfhn)
        
        var qaf: Real64 = (((1.0 - sigmaf) * qa + 
               sigmaf * (0.3 * qa + 0.6 * qsf * rn + 0.1 * qsg * Mg)) /
              (1.0 - sigmaf * (0.6 * (1.0 - rn) + 0.1 * (1.0 - Mg))))
        var qg: Real64 = Mg * qsg + (1.0 - Mg) * qaf
        
        state.dataEcoRoofMgr.Lf = Lef * state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Waf * rn * (qaf - qsf)
        state.dataEcoRoofMgr.Lg = Ce * Leg * Waf * Rhoag * (qaf - qg) * Mg
        
        state.dataEcoRoofMgr.Vfluxf = -1.0 * state.dataEcoRoofMgr.Lf / Lef / 990.0
        state.dataEcoRoofMgr.Vfluxg = -1.0 * state.dataEcoRoofMgr.Lg / Leg / 990.0
        
        if state.dataEcoRoofMgr.Vfluxf < 0.0:
            state.dataEcoRoofMgr.Vfluxf = 0.0
        if state.dataEcoRoofMgr.Vfluxg < 0.0:
            state.dataEcoRoofMgr.Vfluxg = 0.0
        
        var LeafTK: Real64 = state.dataEcoRoofMgr.Tf + 273.15
        var SoilTK: Real64 = state.dataEcoRoofMgr.Tg + 273.15
        
        for EcoLoop in range(1, 4):
            var P1: Real64 = (sigmaf * (RS * (1.0 - state.dataEcoRoofMgr.Alphaf) + 
                           state.dataEcoRoofMgr.epsilonf * Latm) -
                  3.0 * sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * 5.6697e-08 * _pow4(SoilTK) / EpsilonOne -
                  3.0 * (-sigmaf * state.dataEcoRoofMgr.epsilonf * 5.6697e-08 -
                         sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * 5.6697e-08 / EpsilonOne) * _pow4(LeafTK) +
                  state.dataEcoRoofMgr.sheatf * (1.0 - 0.7 * sigmaf) * (Ta + 273.15) +
                  state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * ((1.0 - 0.7 * sigmaf) / dOne) * qa +
                  state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * (((0.6 * sigmaf * rn) / dOne) - 1.0) * (qsf - LeafTK * dqf) +
                  state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * ((0.1 * sigmaf * Mg) / dOne) * (qsg - SoilTK * dqg))
            
            var P2: Real64 = (4.0 * (sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * 5.6697e-08) * _pow3(SoilTK) / EpsilonOne +
                  0.1 * sigmaf * state.dataEcoRoofMgr.sheatf +
                  state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * (0.1 * sigmaf * Mg) / dOne * dqg)
            
            var P3: Real64 = (4.0 * (-sigmaf * state.dataEcoRoofMgr.epsilonf * 5.6697e-08 -
                        (sigmaf * state.dataEcoRoofMgr.epsilonf * 5.6697e-08 * state.dataEcoRoofMgr.epsilong) / EpsilonOne) * _pow3(LeafTK) +
                  (0.6 * sigmaf - 1.0) * state.dataEcoRoofMgr.sheatf +
                  state.dataEcoRoofMgr.LAI * Rhoaf * Cf * Lef * Waf * rn * (((0.6 * sigmaf * rn) / dOne) - 1.0) * dqf)
            
            var T1G: Real64 = ((1.0 - sigmaf) * (RS * (1.0 - state.dataEcoRoofMgr.Alphag) + 
                                     state.dataEcoRoofMgr.epsilong * Latm) -
                   (3.0 * (sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * 5.6697e-08) / EpsilonOne) * _pow4(LeafTK) -
                   3.0 * (-(1.0 - sigmaf) * state.dataEcoRoofMgr.epsilong * 5.6697e-08 -
                          sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * 5.6697e-08 / EpsilonOne) * _pow4(SoilTK) +
                   state.dataEcoRoofMgr.sheatg * (1.0 - 0.7 * sigmaf) * (Ta + 273.15) +
                   Rhoag * Ce * Leg * Waf * Mg * ((1.0 - 0.7 * sigmaf) / dOne) * qa +
                   Rhoag * Ce * Leg * Waf * Mg * (0.1 * sigmaf * Mg / dOne - Mg) * (qsg - SoilTK * dqg) +
                   Rhoag * Ce * Leg * Waf * Mg * (0.6 * sigmaf * rn / dOne) * (qsf - LeafTK * dqf) +
                   Qsoilpart1 + Qsoilpart2 * 273.15)
            
            var T2G: Real64 = (4.0 * (-(1.0 - sigmaf) * state.dataEcoRoofMgr.epsilong * 5.6697e-08 -
                         sigmaf * state.dataEcoRoofMgr.epsilonf * state.dataEcoRoofMgr.epsilong * 5.6697e-08 / EpsilonOne) * _pow3(SoilTK) +
                   (0.1 * sigmaf - 1.0) * state.dataEcoRoofMgr.sheatg +
                   Rhoag * Ce * Leg * Waf * Mg * (0.1 * sigmaf * Mg / dOne - Mg) * dqg -
                   Qsoilpart2)
            
            var T3G: Real64 = ((4.0 * (sigmaf * state.dataEcoRoofMgr.epsilong * state.dataEcoRoofMgr.epsilonf * 5.6697e-08) / EpsilonOne) * _pow3(LeafTK) +
                   0.6 * sigmaf * state.dataEcoRoofMgr.sheatg +
                   Rhoag * Ce * Leg * Waf * Mg * (0.6 * sigmaf * rn / dOne) * dqf)
            
            LeafTK = 0.5 * (LeafTK + (P1 * T2G - P2 * T1G) / (-P3 * T2G + T3G * P2))
            SoilTK = 0.5 * (SoilTK + (P1 * T3G - P3 * T1G) / (-P2 * T3G + P3 * T2G))
        
        state.dataEcoRoofMgr.Qsoil = -1.0 * (Qsoilpart1 - Qsoilpart2 * (SoilTK - 273.15))
        state.dataEcoRoofMgr.Tfold = LeafTK - 273.15
        state.dataEcoRoofMgr.Tgold = SoilTK - 273.15
    
    state.dataHeatBalSurf.SurfOutsideTempHist(1)[SurfNum] = state.dataEcoRoofMgr.Tgold
    TempExt = state.dataEcoRoofMgr.Tgold
    
    return TempExt


fn initEcoRoofFirstTime(inout state: AnyType, SurfNum: Int32, ConstrNum: Int32) -> None:
    var mat = state.dataMaterial.materials(state.dataConstruction.Construct(ConstrNum).LayerPoint(1))
    var matER = mat
    var thisEcoRoof = state.dataEcoRoofMgr
    
    thisEcoRoof.EcoRoofbeginFlag = False
    
    if state.dataSurface.Surface(SurfNum).HeatTransferAlgorithm != state.dataSurfaces.HeatTransferModel.CTF:
        state.UtilityRoutines.ShowSevereError(
            state,
            "initEcoRoofFirstTime: EcoRoof simulation but HeatBalanceAlgorithm is not ConductionTransferFunction(CTF). "
            "EcoRoof model currently works only with CTF heat balance solution algorithm.")
        state.UtilityRoutines.ShowContinueError(state, "Occurs for surface named " + state.dataSurface.Surface(SurfNum).Name)
        state.UtilityRoutines.ShowContinueError(state, "Check input syntax for HeatBalanceAlgorithm, SurfaceProperty:HeatTransferAlgorithm,")
        state.UtilityRoutines.ShowContinueError(state, "SurfaceProperty:HeatTransferAlgorithm:MultipleSurface, and SurfaceProperty:HeatTransferAlgorithm:SurfaceList")
        state.UtilityRoutines.ShowContinueError(state, "to verify that the solution method is set to CTF for the surface that is an EcoRoof.")
        state.UtilityRoutines.ShowFatalError(state, "initEcoRoofFirstTime: Program terminates due to preceding conditions.")
    
    thisEcoRoof.Zf = matER.HeightOfPlants
    thisEcoRoof.LAI = matER.LAI
    thisEcoRoof.Alphag = 1.0 - matER.AbsorpSolar
    thisEcoRoof.Alphaf = matER.Lreflectivity
    thisEcoRoof.epsilonf = matER.LEmissitivity
    thisEcoRoof.StomatalResistanceMin = matER.RStomata
    thisEcoRoof.epsilong = matER.AbsorpThermal
    thisEcoRoof.MoistureMax = matER.Porosity
    thisEcoRoof.MoistureResidual = matER.MinMoisture
    thisEcoRoof.Moisture = matER.InitMoisture
    thisEcoRoof.MeanRootMoisture = thisEcoRoof.Moisture
    thisEcoRoof.SoilThickness = matER.Thickness
    thisEcoRoof.FirstEcoSurf = SurfNum
    
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Soil Temperature", "C", thisEcoRoof.Tg, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Vegetation Temperature", "C", thisEcoRoof.Tf, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Soil Root Moisture Ratio", "None", thisEcoRoof.MeanRootMoisture, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Soil Near Surface Moisture Ratio", "None", thisEcoRoof.Moisture, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Soil Sensible Heat Transfer Rate per Area", "W/m2", thisEcoRoof.sensibleg, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Vegetation Sensible Heat Transfer Rate per Area", "W/m2", thisEcoRoof.sensiblef, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Vegetation Moisture Transfer Rate", "m/s", thisEcoRoof.Vfluxf, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Soil Moisture Transfer Rate", "m/s", thisEcoRoof.Vfluxg, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Vegetation Latent Heat Transfer Rate per Area", "W/m2", thisEcoRoof.Lf, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Soil Latent Heat Transfer Rate per Area", "W/m2", thisEcoRoof.Lg, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Cumulative Precipitation Depth", "m", thisEcoRoof.CumPrecip, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Cumulative Irrigation Depth", "m", thisEcoRoof.CumIrrigation, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Cumulative Runoff Depth", "m", thisEcoRoof.CumRunoff, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Cumulative Evapotranspiration Depth", "m", thisEcoRoof.CumET, "Zone", "Average", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Current Precipitation Depth", "m", thisEcoRoof.CurrentPrecipitation, "Zone", "Sum", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Current Irrigation Depth", "m", thisEcoRoof.CurrentIrrigation, "Zone", "Sum", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Current Runoff Depth", "m", thisEcoRoof.CurrentRunoff, "Zone", "Sum", "Environment")
    state.OutputProcessor.SetupOutputVariable(state, "Green Roof Current Evapotranspiration Depth", "m", thisEcoRoof.CurrentET, "Zone", "Sum", "Environment")


fn initEcoRoof(inout state: AnyType, SurfNum: Int32, ConstrNum: Int32) -> None:
    var mat = state.dataMaterial.materials(state.dataConstruction.Construct(ConstrNum).LayerPoint(1))
    var matER = mat
    var thisSurf = state.dataSurface.Surface(SurfNum)
    
    if state.dataGlobal.BeginEnvrnFlag or state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.Moisture = matER.InitMoisture
        state.dataEcoRoofMgr.MeanRootMoisture = state.dataEcoRoofMgr.Moisture
        state.dataEcoRoofMgr.Alphag = 1.0 - matER.AbsorpSolar
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataEcoRoofMgr.CalcEcoRoofMyEnvrnFlag:
        state.dataEcoRoofMgr.Tgold = state.dataEnvironment.OutDryBulbTempAt(state, thisSurf.Centroid.z)
        state.dataEcoRoofMgr.Tfold = state.dataEnvironment.OutDryBulbTempAt(state, thisSurf.Centroid.z)
        state.dataEcoRoofMgr.Tg = 10.0
        state.dataEcoRoofMgr.Tf = 10.0
        state.dataEcoRoofMgr.Vfluxf = 0.0
        state.dataEcoRoofMgr.Vfluxg = 0.0
        state.dataEcoRoofMgr.CumRunoff = 0.0
        state.dataEcoRoofMgr.CumET = 0.0
        state.dataEcoRoofMgr.CumPrecip = 0.0
        state.dataEcoRoofMgr.CumIrrigation = 0.0
        state.dataEcoRoofMgr.CurrentRunoff = 0.0
        state.dataEcoRoofMgr.CurrentET = 0.0
        state.dataEcoRoofMgr.CurrentPrecipitation = 0.0
        state.dataEcoRoofMgr.CurrentIrrigation = 0.0
        state.dataEcoRoofMgr.CalcEcoRoofMyEnvrnFlag = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataEcoRoofMgr.CalcEcoRoofMyEnvrnFlag = True


fn UpdateSoilProps(inout state: AnyType, inout Moisture: Real64, inout MeanRootMoisture: Real64, MoistureMax: Real64, MoistureResidual: Real64, SoilThickness: Real64, Vfluxf: Real64, Vfluxg: Real64, ConstrNum: Int32, inout Alphag: Real64, unit: Int32, Tg: Real64, Tf: Real64, Qsoil: Real64) -> None:
    var RatioMax: Real64 = 1.0 + 0.20 * state.dataGlobal.MinutesInTimeStep / 15.0
    var RatioMin: Real64 = 1.0 - 0.20 * state.dataGlobal.MinutesInTimeStep / 15.0
    
    var mat = state.dataMaterial.materials(state.dataConstruction.Construct(ConstrNum).LayerPoint(1))
    var matER = mat
    
    if state.dataEcoRoofMgr.UpdatebeginFlag:
        state.dataEcoRoofMgr.DryCond = matER.Conductivity
        state.dataEcoRoofMgr.DryDens = matER.Density
        state.dataEcoRoofMgr.DryAbsorp = matER.AbsorpSolar
        state.dataEcoRoofMgr.DrySpecHeat = matER.SpecHeat
        
        if SoilThickness > 0.12:
            state.dataEcoRoofMgr.TopDepth = 0.06
        else:
            state.dataEcoRoofMgr.TopDepth = 0.5 * SoilThickness
        
        state.dataEcoRoofMgr.RootDepth = SoilThickness - state.dataEcoRoofMgr.TopDepth
        state.dataEcoRoofMgr.TimeStepZoneSec = state.dataGlobal.MinutesInTimeStep * 60.0
        state.dataEcoRoofMgr.UpdatebeginFlag = False
    
    state.dataEcoRoofMgr.CurrentRunoff = 0.0
    
    Moisture -= (Vfluxg) * state.dataGlobal.MinutesInTimeStep * 60.0 / state.dataEcoRoofMgr.TopDepth
    MeanRootMoisture -= (Vfluxf) * state.dataGlobal.MinutesInTimeStep * 60.0 / state.dataEcoRoofMgr.RootDepth
    
    state.dataEcoRoofMgr.CurrentET = (Vfluxg + Vfluxf) * state.dataGlobal.MinutesInTimeStep * 60.0
    if not state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.CumET += state.dataEcoRoofMgr.CurrentET
    
    Moisture += state.dataEcoRoofMgr.CurrentPrecipitation / state.dataEcoRoofMgr.TopDepth
    
    if not state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.CumPrecip += state.dataEcoRoofMgr.CurrentPrecipitation
    
    state.dataEcoRoofMgr.CurrentIrrigation = 0.0
    state.dataWaterData.Irrigation.ActualAmount = 0.0
    if state.dataWaterData.Irrigation.ModeID == state.dataWaterData.IrrigationMode.SchedDesign:
        state.dataEcoRoofMgr.CurrentIrrigation = state.dataWaterData.Irrigation.ScheduledAmount
        state.dataWaterData.Irrigation.ActualAmount = state.dataEcoRoofMgr.CurrentIrrigation
    elif (state.dataWaterData.Irrigation.ModeID == state.dataWaterData.IrrigationMode.SmartSched and
          Moisture < state.dataWaterData.Irrigation.IrrigationThreshold * MoistureMax):
        state.dataEcoRoofMgr.CurrentIrrigation = state.dataWaterData.Irrigation.ScheduledAmount
        state.dataWaterData.Irrigation.ActualAmount = state.dataEcoRoofMgr.CurrentIrrigation
    else:
        if state.dataWaterData.RainFall.ModeID == state.dataWaterData.RainfallMode.EPWPrecipitation:
            state.dataEcoRoofMgr.CurrentIrrigation = 0
            state.dataWaterData.Irrigation.ActualAmount = state.dataEcoRoofMgr.CurrentIrrigation
    
    Moisture += state.dataEcoRoofMgr.CurrentIrrigation / state.dataEcoRoofMgr.TopDepth
    
    if (state.dataEnvrn.RunPeriodEnvironment and not state.dataGlobal.WarmupFlag):
        state.dataEcoRoofMgr.CumIrrigation += state.dataEcoRoofMgr.CurrentIrrigation
        var month: Int32 = state.dataEnvrn.Month
        state.dataEcoRoofMgr.MonthlyIrrigation[month - 1] += state.dataWaterData.Irrigation.ActualAmount * 1000.0
    
    if (state.dataEcoRoofMgr.CurrentIrrigation + state.dataEcoRoofMgr.CurrentPrecipitation >
        0.5 * 0.0254 * state.dataGlobal.MinutesInTimeStep / 60.0):
        state.dataEcoRoofMgr.CurrentRunoff = (state.dataEcoRoofMgr.CurrentIrrigation +
                                              state.dataEcoRoofMgr.CurrentPrecipitation -
                                              (0.5 * 0.0254 * state.dataGlobal.MinutesInTimeStep / 60.0))
        Moisture -= state.dataEcoRoofMgr.CurrentRunoff / state.dataEcoRoofMgr.TopDepth
    
    if Moisture > MoistureMax:
        state.dataEcoRoofMgr.CurrentRunoff += (Moisture - MoistureMax) * state.dataEcoRoofMgr.TopDepth
        Moisture = MoistureMax
    
    if matER.calcMethod == state.dataMaterial.EcoRoofCalcMethod.Simple:
        if Moisture > MeanRootMoisture:
            var MoistureDiffusion: Real64 = _min((MoistureMax - MeanRootMoisture) * state.dataEcoRoofMgr.RootDepth,
                                    (Moisture - MeanRootMoisture) * state.dataEcoRoofMgr.TopDepth)
            MoistureDiffusion = _max(0.0, MoistureDiffusion)
            MoistureDiffusion *= 0.00005 * state.dataGlobal.MinutesInTimeStep * 60.0
            Moisture -= MoistureDiffusion / state.dataEcoRoofMgr.TopDepth
            MeanRootMoisture += MoistureDiffusion / state.dataEcoRoofMgr.RootDepth
        elif MeanRootMoisture > Moisture:
            var MoistureDiffusion: Real64 = _min((MoistureMax - Moisture) * state.dataEcoRoofMgr.TopDepth,
                                   (MeanRootMoisture - Moisture) * state.dataEcoRoofMgr.RootDepth)
            MoistureDiffusion = _max(0.0, MoistureDiffusion)
            MoistureDiffusion *= 0.00001 * state.dataGlobal.MinutesInTimeStep * 60.0
            Moisture += MoistureDiffusion / state.dataEcoRoofMgr.TopDepth
            MeanRootMoisture -= MoistureDiffusion / state.dataEcoRoofMgr.RootDepth
    else:
        state.dataEcoRoofMgr.RelativeSoilSaturationTop = ((Moisture - MoistureResidual) /
                                                         (MoistureMax - MoistureResidual))
        if state.dataEcoRoofMgr.RelativeSoilSaturationTop < 0.0001:
            if state.dataEcoRoofMgr.ErrIndex == 0:
                state.UtilityRoutines.ShowWarningMessage(
                    state,
                    "EcoRoof: UpdateSoilProps: Relative Soil Saturation Top Moisture <= 0.0001, Value=[" + str(state.dataEcoRoofMgr.RelativeSoilSaturationTop) + "].")
                state.UtilityRoutines.ShowContinueError(state, "Value is set to 0.0001 and simulation continues.")
                state.UtilityRoutines.ShowContinueError(state, "You may wish to increase the number of timesteps to attempt to alleviate the problem.")
            state.UtilityRoutines.ShowRecurringWarningErrorAtEnd(
                state,
                "EcoRoof: UpdateSoilProps: Relative Soil Saturation Top Moisture < 0. continues",
                state.dataEcoRoofMgr.ErrIndex,
                state.dataEcoRoofMgr.RelativeSoilSaturationTop,
                state.dataEcoRoofMgr.RelativeSoilSaturationTop)
            state.dataEcoRoofMgr.RelativeSoilSaturationTop = 0.0001
        
        state.dataEcoRoofMgr.SoilHydroConductivityTop = (
            5.157e-7 * pow(state.dataEcoRoofMgr.RelativeSoilSaturationTop, 0.5) *
            pow(1.0 - pow(1.0 - pow(state.dataEcoRoofMgr.RelativeSoilSaturationTop, 1.27 / (1.27 - 1.0)), (1.27 - 1.0) / 1.27), 2.0))
        state.dataEcoRoofMgr.CapillaryPotentialTop = (
            (-1.0 / 23.0) * pow(pow(1.0 / state.dataEcoRoofMgr.RelativeSoilSaturationTop, 1.27 / (1.27 - 1.0)) - 1.0, 1.0 / 1.27))
        
        state.dataEcoRoofMgr.RelativeSoilSaturationRoot = ((MeanRootMoisture - MoistureResidual) /
                                                          (MoistureMax - MoistureResidual))
        state.dataEcoRoofMgr.SoilHydroConductivityRoot = (
            5.157e-7 * pow(state.dataEcoRoofMgr.RelativeSoilSaturationRoot, 0.5) *
            pow(1.0 - pow(1.0 - pow(state.dataEcoRoofMgr.RelativeSoilSaturationRoot, 1.27 / (1.27 - 1.0)), (1.27 - 1.0) / 1.27), 2.0))
        state.dataEcoRoofMgr.CapillaryPotentialRoot = (
            (-1.0 / 23.0) * pow(pow(1.0 / state.dataEcoRoofMgr.RelativeSoilSaturationRoot, 1.27 / (1.27 - 1.0)) - 1.0, 1.0 / 1.27))
        
        state.dataEcoRoofMgr.SoilConductivityAveTop = (
            (state.dataEcoRoofMgr.SoilHydroConductivityTop + state.dataEcoRoofMgr.SoilHydroConductivityRoot) * 0.5)
        Moisture += (
            (state.dataEcoRoofMgr.TimeStepZoneSec / state.dataEcoRoofMgr.TopDepth) *
            ((state.dataEcoRoofMgr.SoilConductivityAveTop *
              (state.dataEcoRoofMgr.CapillaryPotentialTop - state.dataEcoRoofMgr.CapillaryPotentialRoot) /
              state.dataEcoRoofMgr.TopDepth) -
             state.dataEcoRoofMgr.SoilConductivityAveTop))
        
        if Moisture >= MoistureMax:
            Moisture = 0.9999 * MoistureMax
            state.dataEcoRoofMgr.CurrentRunoff += (Moisture - MoistureMax * 0.9999) * state.dataEcoRoofMgr.TopDepth
        
        if Moisture <= (1.01 * MoistureResidual):
            Moisture = 1.01 * MoistureResidual
        
        state.dataEcoRoofMgr.SoilConductivityAveRoot = state.dataEcoRoofMgr.SoilHydroConductivityRoot
        
        if (state.dataEcoRoofMgr.SoilConductivityAveRoot * 3600.0) <= (2.33e-7):
            state.dataEcoRoofMgr.SoilConductivityAveRoot = 0.0
        
        state.dataEcoRoofMgr.TestMoisture = MeanRootMoisture
        MeanRootMoisture += (
            (state.dataEcoRoofMgr.TimeStepZoneSec / state.dataEcoRoofMgr.RootDepth) *
            ((state.dataEcoRoofMgr.SoilConductivityAveTop *
              (state.dataEcoRoofMgr.CapillaryPotentialTop - state.dataEcoRoofMgr.CapillaryPotentialRoot) /
              state.dataEcoRoofMgr.RootDepth) +
             state.dataEcoRoofMgr.SoilConductivityAveTop - state.dataEcoRoofMgr.SoilConductivityAveRoot))
        
        if MeanRootMoisture >= MoistureMax:
            MeanRootMoisture = 0.9999 * MoistureMax
            state.dataEcoRoofMgr.CurrentRunoff += (Moisture - MoistureMax * 0.9999) * state.dataEcoRoofMgr.RootDepth
        
        if MeanRootMoisture <= (1.01 * MoistureResidual):
            MeanRootMoisture = 1.01 * MoistureResidual
        
        state.dataEcoRoofMgr.CurrentRunoff += state.dataEcoRoofMgr.SoilConductivityAveRoot * state.dataEcoRoofMgr.TimeStepZoneSec
    
    if not state.dataGlobal.WarmupFlag:
        state.dataEcoRoofMgr.CumRunoff += state.dataEcoRoofMgr.CurrentRunoff
    
    if MeanRootMoisture <= MoistureResidual * 1.00001:
        Moisture -= ((MoistureResidual * 1.00001 - MeanRootMoisture) *
                    state.dataEcoRoofMgr.RootDepth / state.dataEcoRoofMgr.TopDepth)
        if Moisture < MoistureResidual * 1.00001:
            Moisture = MoistureResidual * 1.00001
        MeanRootMoisture = MoistureResidual * 1.00001
    
    var SoilAbsorpSolar: Real64 = (state.dataEcoRoofMgr.DryAbsorp +
                      (0.92 - state.dataEcoRoofMgr.DryAbsorp) *
                      (Moisture - MoistureResidual) / (MoistureMax - MoistureResidual))
    if SoilAbsorpSolar > 0.95:
        SoilAbsorpSolar = 0.95
    if SoilAbsorpSolar < 0.20:
        SoilAbsorpSolar = 0.20
    
    var TestRatio: Real64 = (1.0 - SoilAbsorpSolar) / Alphag
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    Alphag *= TestRatio
    
    var AvgMoisture: Real64 = ((state.dataEcoRoofMgr.RootDepth * MeanRootMoisture +
                   state.dataEcoRoofMgr.TopDepth * Moisture) / SoilThickness)
    var SoilDensity: Real64 = state.dataEcoRoofMgr.DryDens + (AvgMoisture - MoistureResidual) * 990.0
    
    var SoilSpecHeat: Real64 = state.dataEcoRoofMgr.DrySpecHeat + 1900.0 * AvgMoisture
    
    var SatRatio: Real64 = (AvgMoisture - MoistureResidual) / (MoistureMax - MoistureResidual)
    var SoilConductivity: Real64 = ((state.dataEcoRoofMgr.DryCond / 1.15) *
                       (1.45 * exp(4.411 * SatRatio)) / (1.0 + 0.45 * exp(4.411 * SatRatio)))
    
    TestRatio = SoilConductivity / matER.Conductivity
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    matER.Conductivity *= TestRatio
    SoilConductivity = matER.Conductivity
    
    TestRatio = SoilDensity / matER.Density
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    matER.Density *= TestRatio
    SoilDensity = matER.Density
    
    TestRatio = SoilSpecHeat / matER.SpecHeat
    if TestRatio > RatioMax:
        TestRatio = RatioMax
    if TestRatio < RatioMin:
        TestRatio = RatioMin
    matER.SpecHeat *= TestRatio
    SoilSpecHeat = matER.SpecHeat


fn CalculateEcoRoofSolar(inout state: AnyType, SurfNum: Int32) -> None:
    var RS: Real64 = _max(state.dataEnvrn.SOLCOS(3), 0.0) * state.dataEnvrn.BeamSolarRad + \
         state.dataSolarShading.SurfAnisoSkyMult(SurfNum) * state.dataEnvrn.DifSolarRad
    var f1inv: Real64 = _min(1.0, (0.004 * RS + 0.005) / (0.81 * (0.004 * RS + 1.0)))
    var f1: Real64 = 1.0 / f1inv
    state._eco_RS = RS
    state._eco_f1 = f1

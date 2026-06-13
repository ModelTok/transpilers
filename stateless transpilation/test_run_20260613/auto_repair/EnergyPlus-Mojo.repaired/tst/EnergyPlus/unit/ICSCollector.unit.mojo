from gtest import Test, TestFixture, EXPECT_NEAR
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Construction import *
from EnergyPlus.ConvectionCoefficients import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.GeneralRoutines import *
from EnergyPlus.Material import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.TranspiredCollector import *

using EnergyPlus
using EnergyPlus.DataSurfaces
using EnergyPlus.DataHeatBalance
using EnergyPlus.DataHeatBalSurface
using EnergyPlus.Psychrometrics
using EnergyPlus.DataEnvironment

@register_test(EnergyPlusFixture)
def ICSSolarCollectorTest_CalcPassiveExteriorBaffleGapTest():
    let NumOfSurf: Int = 1
    var SurfNum: Int
    var ZoneNum: Int
    var ConstrNum: Int
    var MatNum: Int
    state.init_state(state)
    state.dataGlobal.BeginEnvrnFlag = True
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.SkyTemp = 24.0
    state.dataEnvrn.IsRain = False
    MatNum = 1
    ZoneNum = 1
    SurfNum = 1
    ConstrNum = 1
    state.dataSurface.Surface.allocate(NumOfSurf)
    state.dataSurface.SurfOutDryBulbTemp.allocate(NumOfSurf)
    state.dataSurface.SurfOutWetBulbTemp.allocate(NumOfSurf)
    state.dataSurface.SurfOutWindSpeed.allocate(NumOfSurf)
    state.dataSurface.SurfOutWindDir.allocate(NumOfSurf)
    state.dataSurface.Surface[SurfNum - 1].Area = 10.0
    state.dataSurface.SurfOutDryBulbTemp[SurfNum - 1] = 20.0
    state.dataSurface.SurfOutWetBulbTemp[SurfNum - 1] = 15.0
    state.dataSurface.SurfOutWindSpeed[SurfNum - 1] = 3.0
    state.dataSurface.Surface[SurfNum - 1].Construction = ConstrNum
    state.dataSurface.Surface[SurfNum - 1].BaseSurf = SurfNum
    state.dataSurface.Surface[SurfNum - 1].Zone = ZoneNum
    state.dataSurface.Surface[SurfNum - 1].ExtWind = False
    state.dataSurface.SurfIsICS.allocate(NumOfSurf)
    state.dataSurface.SurfICSPtr.allocate(NumOfSurf)
    state.dataSurface.SurfIsICS[SurfNum - 1] = True
    state.dataConstruction.Construct.allocate(ConstrNum)
    state.dataConstruction.Construct[ConstrNum - 1].LayerPoint.allocate(MatNum)
    state.dataConstruction.Construct[ConstrNum - 1].LayerPoint[MatNum - 1] = 1
    var p = MaterialBase()
    state.dataMaterial.materials.push_back(p)
    p.AbsorpThermal = 0.8
    state.dataHeatBal.ExtVentedCavity.allocate(1)
    state.dataHeatBal.ExtVentedCavity[NumOfSurf - 1].SurfPtrs.allocate(NumOfSurf)
    state.dataHeatBal.ExtVentedCavity[NumOfSurf - 1].SurfPtrs[NumOfSurf - 1] = 1
    state.dataHeatBal.Zone.allocate(ZoneNum)
    state.dataHeatBal.Zone[ZoneNum - 1].ExtConvAlgo = Convect.HcExt.ASHRAESimple
    state.dataHeatBalSurf.SurfOutsideTempHist.allocate(1)
    state.dataHeatBalSurf.SurfOutsideTempHist[0].allocate(NumOfSurf)
    state.dataHeatBalSurf.SurfOutsideTempHist[0][SurfNum - 1] = 22.0
    state.dataHeatBal.SurfQRadSWOutIncident.allocate(1)
    state.dataHeatBal.SurfQRadSWOutIncident[0] = 0.0
    state.dataConvect.GetUserSuppliedConvectionCoeffs = False
    state.dataHeatBalSurf.SurfWinCoeffAdjRatio.dimension(NumOfSurf, 1.0)
    state.dataSurface.surfExtConv.allocate(NumOfSurf)
    state.dataSurface.surfExtConv[SurfNum - 1].model = Convect.HcExt.SetByZone
    state.dataSurface.SurfEMSOverrideExtConvCoef.allocate(NumOfSurf)
    state.dataSurface.SurfEMSOverrideExtConvCoef[0] = False
    var surface = state.dataSurface.Surface[SurfNum - 1]
    surface.IsSurfPropertyGndSurfacesDefined = False
    surface.UseSurfPropertyGndSurfTemp = False
    surface.UseSurfPropertyGndSurfRefl = False
    surface.SurfHasSurroundingSurfProperty = False
    let VentArea: Float64 = 0.1
    let Cv: Float64 = 0.1
    let Cd: Float64 = 0.5
    let HdeltaNPL: Float64 = 3.0
    let SolAbs: Float64 = 0.75
    let AbsExt: Float64 = 0.8
    let Tilt: Float64 = 0.283
    let AspRat: Float64 = 0.9
    let GapThick: Float64 = 0.05
    let Roughness: Material.SurfaceRoughness = Material.SurfaceRoughness.VeryRough
    var QdotSource: Float64 = 0.0
    var TsBaffle: Float64 = 20.0
    var TaGap: Float64 = 22.0
    var HcGapRpt: Float64
    var HrGapRpt: Float64
    var IscRpt: Float64
    var MdotVentRpt: Float64
    var VdotWindRpt: Float64
    var VdotBuoyRpt: Float64
    TranspiredCollector.CalcPassiveExteriorBaffleGap(state,
                                                      state.dataHeatBal.ExtVentedCavity[0].SurfPtrs,
                                                      VentArea,
                                                      Cv,
                                                      Cd,
                                                      HdeltaNPL,
                                                      SolAbs,
                                                      AbsExt,
                                                      Tilt,
                                                      AspRat,
                                                      GapThick,
                                                      Roughness,
                                                      QdotSource,
                                                      TsBaffle,
                                                      TaGap,
                                                      HcGapRpt,
                                                      HrGapRpt,
                                                      IscRpt,
                                                      MdotVentRpt,
                                                      VdotWindRpt,
                                                      VdotBuoyRpt)
    EXPECT_NEAR(21.862, TsBaffle, 0.001)
    EXPECT_NEAR(1.692, HcGapRpt, 0.001)
    EXPECT_NEAR(3.694, HrGapRpt, 0.001)
    EXPECT_NEAR(0.036, MdotVentRpt, 0.001)
    state.dataSurface.Surface.deallocate()
    state.dataConstruction.Construct[ConstrNum - 1].LayerPoint.deallocate()
    state.dataConstruction.Construct.deallocate()
    for i in range(1, state.dataMaterial.materials.isize() + 1):
        delete state.dataMaterial.materials[i - 1]
    state.dataMaterial.materials.deallocate()
    state.dataHeatBal.ExtVentedCavity[NumOfSurf - 1].SurfPtrs.deallocate()
    state.dataHeatBal.ExtVentedCavity.deallocate()
    state.dataHeatBal.Zone.deallocate()
    state.dataHeatBal.SurfQRadSWOutIncident.deallocate()
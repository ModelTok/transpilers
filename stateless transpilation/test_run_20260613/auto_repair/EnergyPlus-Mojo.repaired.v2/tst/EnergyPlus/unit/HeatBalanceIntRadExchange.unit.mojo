from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, EXPECT_GT, ASSERT_TRUE
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataViewFactorInformation import *
from EnergyPlus.HeatBalanceIntRadExchange import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Material import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, compare_err_stream, delimited_string
from EnergyPlus.Utility import Util
def main() raises:

struct HeatBalanceIntRadExchange_CarrollMRT(TestFixture):
    def TestBody(self):
        var N: Int
        var A: Array1D[Float64]
        var FMRT: Array1D[Float64]
        var EMISS: Array1D[Float64]
        var Fp: Array1D[Float64]
        N = 3
        A = Array1D[Float64](N)
        A[0] = 1.0
        A[1] = 1.0
        A[2] = 1.0
        FMRT = Array1D[Float64](N)
        CalcFMRT(self.state, N, A, FMRT)
        EMISS = Array1D[Float64](N)
        EMISS[0] = 1.0
        EMISS[1] = 1.0
        EMISS[2] = 1.0
        Fp = Array1D[Float64](N)
        CalcFp(N, EMISS, FMRT, Fp)
        EXPECT_NEAR(FMRT[0], 1.5, 0.001)
        EXPECT_NEAR(FMRT[1], 1.5, 0.001)
        EXPECT_NEAR(FMRT[2], 1.5, 0.001)
        N = 2
        A = Array1D[Float64](N)
        A[0] = 1.0
        A[1] = 1.0
        FMRT = Array1D[Float64](N)
        CalcFMRT(self.state, N, A, FMRT)
        EXPECT_NEAR(FMRT[0], 2.0, 0.001)
        EXPECT_NEAR(FMRT[1], 2.0, 0.001)
        EMISS = Array1D[Float64](N)
        EMISS[0] = 1.0
        EMISS[1] = 1.0
        Fp = Array1D[Float64](N)
        CalcFp(N, EMISS, FMRT, Fp)
        A[0] = 2.0
        A[1] = 1.0
        CalcFMRT(self.state, N, A, FMRT)
        var error_string: String = delimited_string(["   ** Severe  ** Geometry not compatible with Carroll MRT Zone Radiant Exchange method."])
        EXPECT_TRUE(compare_err_stream(error_string, True))
        CalcFp(N, EMISS, FMRT, Fp)
        var ENCLOSURES: Int = 1
        var SURFACES: Int = 6
        var HISTORY: Int = 1
        self.state.dataGlobal.BeginEnvrnFlag = True
        self.state.dataHeatBalIntRadExchg.CarrollMethod = True
        self.state.dataConstruction.Construct = Array1D[Construct](SURFACES)
        self.state.dataSurface.TotSurfaces = SURFACES
        self.state.dataSurface.Surface = Array1D[Surface](SURFACES)
        self.state.dataSurface.SurfaceWindow = Array1D[SurfaceWindow](SURFACES)
        self.state.dataSurface.SurfWinIRfromParentZone = Array1D[Float64](SURFACES)
        self.state.dataSurface.SurfWinShadingFlag = Array1D[Int](SURFACES)
        self.state.dataSurface.SurfWinWindowModelType = Array1D[Int](SURFACES)
        self.state.dataViewFactor.NumOfRadiantEnclosures = ENCLOSURES
        self.state.dataViewFactor.EnclRadInfo = Array1D[EnclRadInfo](ENCLOSURES)
        self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].NumOfSurfaces = SURFACES
        self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].Area = Array1D[Float64](SURFACES)
        self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].Emissivity = Array1D[Float64](SURFACES)
        self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].FMRT = Array1D[Float64](SURFACES)
        self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].Fp = Array1D[Float64](SURFACES)
        self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].SurfacePtr = Array1D[Int](SURFACES)
        self.state.dataHeatBalSurf.SurfAbsThermalInt = Array1D[Float64](SURFACES)
        self.state.dataHeatBalSurf.SurfInsideTempHist = Array1D[Array1D[Float64]](HISTORY)
        self.state.dataHeatBalSurf.SurfInsideTempHist[HISTORY - 1] = Array1D[Float64](SURFACES)
        self.state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea = Array1D[Float64](SURFACES)
        self.state.dataHeatBalIntRadExchg.MaxNumOfRadEnclosureSurfs = SURFACES
        self.state.dataHeatBalIntRadExchg.SurfaceEmiss = Array1D[Float64](SURFACES)
        self.state.dataHeatBalIntRadExchg.SurfaceTempInKto4th = Array1D[Float64](SURFACES)
        self.state.dataHeatBalIntRadExchg.SurfaceTempRad = Array1D[Float64](SURFACES)
        for surfaceNum in range(1, SURFACES + 1):
            self.state.dataSurface.Surface[surfaceNum - 1].Construction = surfaceNum
            self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].Area[surfaceNum - 1] = 10
            self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].SurfacePtr[surfaceNum - 1] = surfaceNum
            self.state.dataHeatBalSurf.SurfAbsThermalInt[surfaceNum - 1] = 0.9
            self.state.dataHeatBalSurf.SurfInsideTempHist[0][surfaceNum - 1] = 293.15 + (surfaceNum % 2)
        CalcFMRT(self.state, SURFACES, self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].Area, self.state.dataViewFactor.EnclRadInfo[ENCLOSURES - 1].FMRT)
        CalcInteriorRadExchange(self.state, self.state.dataHeatBalSurf.SurfInsideTempHist[HISTORY - 1], 0, self.state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea)
        EXPECT_NEAR(sum(self.state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea), 0, 0.001)

struct HeatBalanceIntRadExchange_FixViewFactorsTest(TestFixture):
    def TestBody(self):
        var N: Int
        var A: Array1D[Float64]
        var F: Array2D[Float64]
        var OriginalCheckValue: Float64
        var FixedCheckValue: Float64
        var FinalCheckValue: Float64
        var NumIterations: Int
        var RowSum: Float64
        var anyIntMassInZone: Bool
        anyIntMassInZone = False
        N = 3
        A = Array1D[Float64](N)
        F = Array2D[Float64](N, N)
        A[0] = 1.0
        A[1] = 1.0
        A[2] = 1.0
        F[0, 0] = 0.0
        F[0, 1] = 0.5
        F[0, 2] = 0.5
        F[1, 0] = 0.5
        F[1, 1] = 0.0
        F[1, 2] = 0.5
        F[2, 0] = 0.5
        F[2, 1] = 0.5
        F[2, 2] = 0.0
        var spaceNum: Int = 1
        self.state.dataHeatBal.Zone = Array1D[Zone](spaceNum)
        self.state.dataHeatBal.Zone[spaceNum - 1].Name = "Test"
        self.state.dataHeatBal.Zone[spaceNum - 1].spaceIndexes.append(spaceNum)
        self.state.dataHeatBal.space = Array1D[Space](spaceNum)
        self.state.dataHeatBal.space[spaceNum - 1].Name = "Test"
        self.state.dataHeatBal.space[spaceNum - 1].zoneNum = spaceNum
        self.state.dataViewFactor.EnclRadInfo = Array1D[EnclRadInfo](spaceNum)
        self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].Name = self.state.dataHeatBal.space[spaceNum - 1].Name
        self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].spaceNums.append(spaceNum)
        FixViewFactors(self.state,
                       N,
                       A,
                       F,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].Name,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].spaceNums,
                       OriginalCheckValue,
                       FixedCheckValue,
                       FinalCheckValue,
                       NumIterations,
                       RowSum,
                       anyIntMassInZone)
        var error_string: String = delimited_string([
            "   ** Warning ** Surfaces in Zone/Enclosure=\"Test\" do not define an enclosure.",
            "   **   ~~~   ** Number of surfaces <= 3, view factors are set to force reciprocity but may not fulfill completeness.",
            "   **   ~~~   ** Reciprocity means that radiant exchange between two surfaces will match and not lead to an energy loss.",
            "   **   ~~~   ** Completeness means that all of the view factors between a surface and the other surfaces in a zone add up to unity.",
            "   **   ~~~   ** So, when there are three or less surfaces in a zone, EnergyPlus will make sure there are no losses of energy but",
            "   **   ~~~   ** it will not exchange the full amount of radiation with the rest of the zone as it would if there was a completed enclosure.",
        ])
        EXPECT_TRUE(compare_err_stream(error_string, True))
        A[0] = 20.0
        A[1] = 180.0
        A[2] = 180.0
        F[0, 0] = 0.0
        F[0, 1] = 0.5
        F[0, 2] = 0.5
        F[1, 0] = 0.1
        F[1, 1] = 0.0
        F[1, 2] = 0.9
        F[2, 0] = 0.1
        F[2, 1] = 0.9
        F[2, 2] = 0.0
        FixViewFactors(self.state,
                       N,
                       A,
                       F,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].Name,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].spaceNums,
                       OriginalCheckValue,
                       FixedCheckValue,
                       FinalCheckValue,
                       NumIterations,
                       RowSum,
                       anyIntMassInZone)
        EXPECT_NEAR(F[0, 1], 0.07986, 0.001)
        EXPECT_NEAR(F[1, 0], 0.71875, 0.001)
        EXPECT_NEAR(F[2, 1], 0.28125, 0.001)
        A[0] = 100.0
        A[1] = 100.0
        A[2] = 200.0
        F[0, 0] = 0.0
        F[0, 1] = 1.0 / 3.0
        F[0, 2] = 2.0 / 3.0
        F[1, 0] = 1.0 / 3.0
        F[1, 1] = 0.0
        F[1, 2] = 2.0 / 3.0
        F[2, 0] = 0.5
        F[2, 1] = 0.5
        F[2, 2] = 0.0
        FixViewFactors(self.state,
                       N,
                       A,
                       F,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].Name,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].spaceNums,
                       OriginalCheckValue,
                       FixedCheckValue,
                       FinalCheckValue,
                       NumIterations,
                       RowSum,
                       anyIntMassInZone)
        EXPECT_NEAR(F[0, 1], 0.181818, 0.001)
        EXPECT_NEAR(F[1, 2], 0.25, 0.001)
        EXPECT_NEAR(F[2, 1], 0.5, 0.001)
        A[0] = 100.0
        A[1] = 150.0
        A[2] = 200.0
        F[0, 0] = 0.0
        F[0, 1] = 150.0 / 350.0
        F[0, 2] = 200.0 / 350.0
        F[1, 0] = 1.0 / 3.0
        F[1, 1] = 0.0
        F[1, 2] = 2.0 / 3.0
        F[2, 0] = 0.4
        F[2, 1] = 0.6
        F[2, 2] = 0.0
        FixViewFactors(self.state,
                       N,
                       A,
                       F,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].Name,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].spaceNums,
                       OriginalCheckValue,
                       FixedCheckValue,
                       FinalCheckValue,
                       NumIterations,
                       RowSum,
                       anyIntMassInZone)
        EXPECT_NEAR(F[0, 1], 0.21466, 0.001)
        EXPECT_NEAR(F[0, 2], 0.25445, 0.001)
        EXPECT_NEAR(F[1, 0], 0.32199, 0.001)
        EXPECT_NEAR(F[1, 2], 0.36832, 0.001)
        EXPECT_NEAR(F[2, 0], 0.50890, 0.001)
        EXPECT_NEAR(F[2, 1], 0.49110, 0.001)
        A = Array1D[Float64]()
        F = Array2D[Float64]()
        N = 4
        A = Array1D[Float64](N)
        F = Array2D[Float64](N, N)
        A[0] = 100.0
        A[1] = 50.0
        A[2] = 25.0
        A[3] = 25.0
        F[0, 0] = 0.0
        F[0, 1] = 0.5
        F[0, 2] = 0.25
        F[0, 3] = 0.25
        F[1, 0] = 2.0 / 3.0
        F[1, 1] = 0.0
        F[1, 2] = 1.0 / 6.0
        F[1, 3] = 1.0 / 6.0
        F[2, 0] = 4.0 / 7.0
        F[2, 1] = 2.0 / 7.0
        F[2, 2] = 0.0
        F[2, 3] = 1.0 / 7.0
        F[3, 0] = 4.0 / 7.0
        F[3, 1] = 2.0 / 7.0
        F[3, 2] = 1.0 / 7.0
        F[3, 3] = 0.0
        FixViewFactors(self.state,
                       N,
                       A,
                       F,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].Name,
                       self.state.dataViewFactor.EnclRadInfo[spaceNum - 1].spaceNums,
                       OriginalCheckValue,
                       FixedCheckValue,
                       FinalCheckValue,
                       NumIterations,
                       RowSum,
                       anyIntMassInZone)
        EXPECT_NEAR(F[0, 0], 0.31747, 0.001)
        EXPECT_NEAR(F[0, 1], 0.71788, 0.001)
        EXPECT_NEAR(F[0, 2], 0.64862, 0.001)
        EXPECT_NEAR(F[0, 3], 0.64862, 0.001)
        EXPECT_NEAR(F[1, 0], 0.35894, 0.001)
        EXPECT_NEAR(F[1, 1], 0.00000, 0.001)
        EXPECT_NEAR(F[1, 2], 0.28073, 0.001)
        EXPECT_NEAR(F[1, 3], 0.28073, 0.001)
        EXPECT_NEAR(F[2, 0], 0.16215, 0.001)
        EXPECT_NEAR(F[2, 1], 0.14036, 0.001)
        EXPECT_NEAR(F[2, 2], 0.00000, 0.001)
        EXPECT_NEAR(F[2, 3], 0.07060, 0.001)
        EXPECT_NEAR(F[3, 0], 0.16215, 0.001)
        EXPECT_NEAR(F[3, 1], 0.14036, 0.001)
        EXPECT_NEAR(F[3, 2], 0.07060, 0.001)
        EXPECT_NEAR(F[3, 3], 0.00000, 0.001)

struct HeatBalanceIntRadExchange_DoesZoneHaveInternalMassTest(TestFixture):
    def TestBody(self):
        var numOfZoneSurfaces: Int
        var surfPointers: Array1D[Int]
        var functionReturnValue: Bool
        numOfZoneSurfaces = 7
        surfPointers = Array1D[Int](numOfZoneSurfaces)
        self.state.dataSurface.Surface = Array1D[Surface](numOfZoneSurfaces)
        for i in range(1, numOfZoneSurfaces + 1):
            surfPointers[i - 1] = i
            self.state.dataSurface.Surface[i - 1].Class = DataSurfaces.SurfaceClass.Wall
        functionReturnValue = DoesZoneHaveInternalMass(self.state, numOfZoneSurfaces, surfPointers)
        EXPECT_FALSE(functionReturnValue)
        self.state.dataSurface.Surface[6].Class = DataSurfaces.SurfaceClass.IntMass
        functionReturnValue = DoesZoneHaveInternalMass(self.state, numOfZoneSurfaces, surfPointers)
        EXPECT_TRUE(functionReturnValue)

struct HeatBalanceIntRadExchange_UpdateMovableInsulationFlagTest(TestFixture):
    def TestBody(self):
        var DidMIChange: Bool
        var SurfNum: Int
        self.state.dataConstruction.Construct = Array1D[Construct](1)
        var mat = Material.MaterialBase()
        self.state.dataMaterial.materials.append(mat)
        self.state.dataSurface.Surface = Array1D[Surface](1)
        self.state.dataSurface.intMovInsuls = Array1D[IntMovInsul](1)
        SurfNum = 1
        self.state.dataSurface.intMovInsuls[0].present = False
        self.state.dataSurface.intMovInsuls[0].presentPrevTS = False
        self.state.dataSurface.Surface[0].Construction = 1
        self.state.dataSurface.intMovInsuls[0].matNum = 1
        self.state.dataConstruction.Construct[0].InsideAbsorpThermal = 0.9
        mat.AbsorpThermal = 0.5
        mat.Resistance = 1.25
        mat.AbsorpSolar = 0.25
        HeatBalanceIntRadExchange.UpdateMovableInsulationFlag(self.state, DidMIChange, SurfNum)
        EXPECT_FALSE(DidMIChange)
        self.state.dataSurface.intMovInsuls[0].presentPrevTS = True
        HeatBalanceIntRadExchange.UpdateMovableInsulationFlag(self.state, DidMIChange, SurfNum)
        EXPECT_TRUE(DidMIChange)
        self.state.dataSurface.intMovInsuls[0].presentPrevTS = True
        mat.AbsorpThermal = self.state.dataConstruction.Construct[0].InsideAbsorpThermal
        HeatBalanceIntRadExchange.UpdateMovableInsulationFlag(self.state, DidMIChange, SurfNum)
        EXPECT_FALSE(DidMIChange)

struct HeatBalanceIntRadExchange_AlignInputViewFactorsTest(TestFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "Zone,",
            "Zone 1;             !- Name",
            "Zone,",
            "Zone 2;             !- Name",
            "Zone,",
            "Zone 3;             !- Name",
            "Zone,",
            "Zone 4;             !- Name",
            "Zone,",
            "Zone 5;             !- Name",
            "Space,",
            "Space 1,             !- Name",
            "Zone 1;             !- Zone Name",
            "Space,",
            "Space 2,             !- Name",
            "Zone 2;             !- Zone Name",
            "Space,",
            "Space 3,             !- Name",
            "Zone 3;             !- Zone Name",
            "Space,",
            "Space 4,             !- Name",
            "Zone 4;             !- Zone Name",
            "Space,",
            "Space 5,             !- Name",
            "Zone 5;             !- Zone Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 3,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Perimeter Zones,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "SpaceList,",
            "Perimeter Zones, !- Name",
            "Space 5, !- Zone 1 Name",
            "Space 2; !- Zone 2 Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 6,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        var ErrorsFound: Bool = False
        HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
        EXPECT_FALSE(ErrorsFound)
        self.state.dataViewFactor.NumOfRadiantEnclosures = 3
        self.state.dataViewFactor.EnclRadInfo = Array1D[EnclRadInfo](3)
        self.state.dataViewFactor.EnclSolInfo = Array1D[EnclSolInfo](3)
        self.state.dataViewFactor.EnclRadInfo[0].Name = "Enclosure 1"
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 2"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 1"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].Name = "Enclosure 2"
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 4"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 5"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[2].Name = "Space 3"
        self.state.dataViewFactor.EnclRadInfo[2].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 3"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        ErrorsFound = False
        HeatBalanceIntRadExchange.AlignInputViewFactors(self.state, "ZoneProperty:UserViewFactors:BySurfaceName", ErrorsFound)
        EXPECT_TRUE(ErrorsFound)
        var error_string: String = delimited_string(["   ** Severe  ** AlignInputViewFactors: ZoneProperty:UserViewFactors:BySurfaceName=\"PERIMETER ZONES\" found a matching SpaceList, but did not find a matching radiant or solar enclosure with the same spaces.",
                          "   ** Severe  ** AlignInputViewFactors: ZoneProperty:UserViewFactors:BySurfaceName=\"SPACE 6\" did not find a matching radiant or solar enclosure name."])
        EXPECT_TRUE(compare_err_stream(error_string, True))
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[0].Name, "Enclosure 1")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[1].Name, "Enclosure 2")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[2].Name, "Space 3")

struct HeatBalanceIntRadExchange_AlignInputViewFactorsTest2(TestFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "Zone,",
            "Zone 1;             !- Name",
            "Zone,",
            "Zone 2;             !- Name",
            "Zone,",
            "Zone 3;             !- Name",
            "Zone,",
            "Zone 4;             !- Name",
            "Zone,",
            "Zone 5;             !- Name",
            "Space,",
            "Space 1,             !- Name",
            "Zone 1;             !- Zone Name",
            "Space,",
            "Space 2,             !- Name",
            "Zone 2;             !- Zone Name",
            "Space,",
            "Space 3,             !- Name",
            "Zone 3;             !- Zone Name",
            "Space,",
            "Space 4,             !- Name",
            "Zone 4;             !- Zone Name",
            "Space,",
            "Space 5,             !- Name",
            "Zone 5;             !- Zone Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 3,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Perimeter Zones,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "SpaceList,",
            "Perimeter Zones, !- Name",
            "Space 5, !- Zone 1 Name",
            "Space 2; !- Zone 2 Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 6,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        var ErrorsFound: Bool = False
        HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
        EXPECT_FALSE(ErrorsFound)
        self.state.dataViewFactor.NumOfRadiantEnclosures = 3
        self.state.dataViewFactor.EnclRadInfo = Array1D[EnclRadInfo](3)
        self.state.dataViewFactor.EnclSolInfo = Array1D[EnclSolInfo](3)
        self.state.dataViewFactor.EnclRadInfo[0].Name = "Enclosure 1"
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 2"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 5"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].Name = "Enclosure 2"
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 4"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 5"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[2].Name = "Space 3"
        self.state.dataViewFactor.EnclRadInfo[2].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 3"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        ErrorsFound = False
        HeatBalanceIntRadExchange.AlignInputViewFactors(self.state, "ZoneProperty:UserViewFactors:BySurfaceName", ErrorsFound)
        EXPECT_TRUE(ErrorsFound)
        var error_string: String = delimited_string(["   ** Severe  ** AlignInputViewFactors: ZoneProperty:UserViewFactors:BySurfaceName=\"SPACE 6\" did not find a matching radiant or solar enclosure name."])
        EXPECT_TRUE(compare_err_stream(error_string, True))
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[0].Name, "PERIMETER ZONES")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[1].Name, "Enclosure 2")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[2].Name, "Space 3")

struct HeatBalanceIntRadExchange_AlignInputViewFactorsTest3(TestFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "Zone,",
            "Zone 1;             !- Name",
            "Zone,",
            "Zone 2;             !- Name",
            "Zone,",
            "Zone 3;             !- Name",
            "Zone,",
            "Zone 4;             !- Name",
            "Zone,",
            "Zone 5;             !- Name",
            "Space,",
            "Space 1,             !- Name",
            "Zone 1;             !- Zone Name",
            "Space,",
            "Space 2,             !- Name",
            "Zone 2;             !- Zone Name",
            "Space,",
            "Space 3,             !- Name",
            "Zone 3;             !- Zone Name",
            "Space,",
            "Space 4,             !- Name",
            "Zone 4;             !- Zone Name",
            "Space,",
            "Space 5,             !- Name",
            "Zone 5;             !- Zone Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 3,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Perimeter Zones,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "SpaceList,",
            "Perimeter Zones, !- Name",
            "Space 5, !- Zone 1 Name",
            "Space 2; !- Zone 2 Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 6,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        var ErrorsFound: Bool = False
        HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
        EXPECT_FALSE(ErrorsFound)
        self.state.dataViewFactor.NumOfRadiantEnclosures = 3
        self.state.dataViewFactor.EnclRadInfo = Array1D[EnclRadInfo](3)
        self.state.dataViewFactor.EnclSolInfo = Array1D[EnclSolInfo](3)
        self.state.dataViewFactor.EnclRadInfo[0].Name = "Enclosure 1"
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 2"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 1"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].Name = "Enclosure 2"
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 4"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 5"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[2].Name = "Space 3"
        self.state.dataViewFactor.EnclRadInfo[2].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Zone 3"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        ErrorsFound = False
        HeatBalanceIntRadExchange.AlignInputViewFactors(self.state, "ZoneProperty:UserViewFactors:BySurfaceName", ErrorsFound)
        EXPECT_TRUE(ErrorsFound)
        var error_string: String = delimited_string(["   ** Severe  ** AlignInputViewFactors: ZoneProperty:UserViewFactors:BySurfaceName=\"PERIMETER ZONES\" found a matching SpaceList, but did not find a matching radiant or solar enclosure with the same spaces.",
                          "   ** Severe  ** AlignInputViewFactors: ZoneProperty:UserViewFactors:BySurfaceName=\"SPACE 6\" did not find a matching radiant or solar enclosure name."])
        EXPECT_TRUE(compare_err_stream(error_string, True))
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[0].Name, "Enclosure 1")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[1].Name, "Enclosure 2")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[2].Name, "Space 3")

struct HeatBalanceIntRadExchange_AlignInputViewFactorsTest4(TestFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "Zone,",
            "Zone 1;             !- Name",
            "Zone,",
            "Zone 2;             !- Name",
            "Zone,",
            "Zone 3;             !- Name",
            "Zone,",
            "Zone 4;             !- Name",
            "Zone,",
            "Zone 5;             !- Name",
            "Space,",
            "Space 1,             !- Name",
            "Zone 1;             !- Zone Name",
            "Space,",
            "Space 2,             !- Name",
            "Zone 2;             !- Zone Name",
            "Space,",
            "Space 3,             !- Name",
            "Zone 3;             !- Zone Name",
            "Space,",
            "Space 4,             !- Name",
            "Zone 4;             !- Zone Name",
            "Space,",
            "Space 5,             !- Name",
            "Zone 5;             !- Zone Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 3,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Perimeter Zones,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
            "SpaceList,",
            "Perimeter Zones, !- Name",
            "Space 5, !- Space 1 Name",
            "Space 2; !- Space 2 Name",
            "ZoneProperty:UserViewFactors:BySurfaceName,",
            "Space 6,",
            "SB51,SB51,0.000000,",
            "SB51,SB52,2.672021E-002,",
            "SB51,SB53,8.311358E-002,",
            "SB51,SB54,2.672021E-002;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        var ErrorsFound: Bool = False
        HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
        EXPECT_FALSE(ErrorsFound)
        self.state.dataViewFactor.NumOfRadiantEnclosures = 3
        self.state.dataViewFactor.EnclRadInfo = Array1D[EnclRadInfo](3)
        self.state.dataViewFactor.EnclSolInfo = Array1D[EnclSolInfo](3)
        self.state.dataViewFactor.EnclRadInfo[0].Name = "Enclosure 1"
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 2"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[0].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 5"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].Name = "Enclosure 2"
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 4"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[1].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 5"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        self.state.dataViewFactor.EnclRadInfo[2].Name = "Space 3"
        self.state.dataViewFactor.EnclRadInfo[2].spaceNums.append(
            Util.FindItemInList(Util.makeUPPER("Space 3"), self.state.dataHeatBal.space, self.state.dataGlobal.numSpaces))
        ErrorsFound = False
        HeatBalanceIntRadExchange.AlignInputViewFactors(self.state, "ZoneProperty:UserViewFactors:BySurfaceName", ErrorsFound)
        EXPECT_TRUE(ErrorsFound)
        var error_string: String = delimited_string(["   ** Severe  ** AlignInputViewFactors: ZoneProperty:UserViewFactors:BySurfaceName=\"SPACE 6\" did not find a matching radiant or solar enclosure name."])
        EXPECT_TRUE(compare_err_stream(error_string, True))
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[0].Name, "PERIMETER ZONES")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[1].Name, "Enclosure 2")
        EXPECT_EQ(self.state.dataViewFactor.EnclRadInfo[2].Name, "Space 3")

struct HeatBalanceIntRadExchange_ViewFactorAngleLimitTest(TestFixture):
    def TestBody(self):
        var N: Int
        var A: Array1D[Float64]
        var F: Array2D[Float64]
        var ZoneNum: Int
        N = 9
        A = Array1D[Float64](N)
        F = Array2D[Float64](N, N)
        for i in range(N):
            for j in range(N):
                F[i, j] = 0.0
        for i in range(N):
            A[i] = 1.0
        ZoneNum = 1
        self.state.dataHeatBal.Zone = Array1D[Zone](ZoneNum)
        self.state.dataHeatBal.Zone[ZoneNum - 1].Name = "Test"
        self.state.dataViewFactor.EnclSolInfo = Array1D[EnclSolInfo](ZoneNum)
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Name = self.state.dataHeatBal.Zone[ZoneNum - 1].Name
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].spaceNums.append(ZoneNum)
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth = Array1D[Float64](N)
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt = Array1D[Float64](N)
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr = Array1D[Int](N)
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[0] = 1
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[1] = 2
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[2] = 3
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[3] = 4
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[4] = 5
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[5] = 6
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[6] = 7
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[7] = 8
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr[8] = 9
        self.state.dataSurface.Surface = Array1D[Surface](N)
        self.state.dataSurface.Surface[0].Class = DataSurfaces.SurfaceClass.Wall
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[0] = 0
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[0] = 90
        self.state.dataSurface.Surface[1].Class = DataSurfaces.SurfaceClass.Wall
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[1] = 90
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[1] = 180
        self.state.dataSurface.Surface[2].Class = DataSurfaces.SurfaceClass.Floor
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[2] = 0
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[2] = 180
        self.state.dataSurface.Surface[3].Class = DataSurfaces.SurfaceClass.Roof
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[3] = 0
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[3] = 0
        self.state.dataSurface.Surface[4].Class = DataSurfaces.SurfaceClass.Floor
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[4] = 0
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[4] = 270
        self.state.dataSurface.Surface[5].Class = DataSurfaces.SurfaceClass.Wall
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[5] = 358
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[5] = 90
        self.state.dataSurface.Surface[6].Class = DataSurfaces.SurfaceClass.Roof
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[6] = 5
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[6] = 0
        self.state.dataSurface.Surface[7].Class = DataSurfaces.SurfaceClass.Roof
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[7] = 90
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[7] = 0
        self.state.dataSurface.Surface[8].Class = DataSurfaces.SurfaceClass.IntMass
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth[8] = 0
        self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt[8] = 0
        CalcApproximateViewFactors(self.state,
                                   N,
                                   A,
                                   self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Azimuth,
                                   self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].Tilt,
                                   F,
                                   self.state.dataViewFactor.EnclSolInfo[ZoneNum - 1].SurfacePtr)
        EXPECT_EQ(F[0, 0], 0.0)
        EXPECT_EQ(F[1, 1], 0.0)
        EXPECT_EQ(F[2, 2], 0.0)
        EXPECT_EQ(F[3, 3], 0.0)
        EXPECT_EQ(F[4, 4], 0.0)
        EXPECT_EQ(F[5, 5], 0.0)
        EXPECT_EQ(F[6, 6], 0.0)
        EXPECT_EQ(F[7, 7], 0.0)
        EXPECT_EQ(F[8, 8], 0.0)
        EXPECT_EQ(F[2, 4], 0.0)
        EXPECT_EQ(F[4, 2], 0.0)
        EXPECT_GT(F[8, 0], 0.0)
        EXPECT_GT(F[8, 1], 0.0)
        EXPECT_GT(F[8, 2], 0.0)
        EXPECT_GT(F[8, 3], 0.0)
        EXPECT_GT(F[8, 4], 0.0)
        EXPECT_GT(F[8, 5], 0.0)
        EXPECT_GT(F[8, 6], 0.0)
        EXPECT_GT(F[8, 7], 0.0)
        EXPECT_GT(F[0, 8], 0.0)
        EXPECT_GT(F[1, 8], 0.0)
        EXPECT_GT(F[2, 8], 0.0)
        EXPECT_GT(F[3, 8], 0.0)
        EXPECT_GT(F[4, 8], 0.0)
        EXPECT_GT(F[5, 8], 0.0)
        EXPECT_GT(F[6, 8], 0.0)
        EXPECT_GT(F[7, 8], 0.0)
        EXPECT_GT(F[2, 0], 0.0)
        EXPECT_GT(F[2, 1], 0.0)
        EXPECT_GT(F[2, 3], 0.0)
        EXPECT_GT(F[2, 5], 0.0)
        EXPECT_GT(F[2, 6], 0.0)
        EXPECT_GT(F[2, 7], 0.0)
        EXPECT_GT(F[2, 8], 0.0)
        EXPECT_GT(F[0, 2], 0.0)
        EXPECT_GT(F[1, 2], 0.0)
        EXPECT_GT(F[3, 2], 0.0)
        EXPECT_GT(F[5, 2], 0.0)
        EXPECT_GT(F[6, 2], 0.0)
        EXPECT_GT(F[7, 2], 0.0)
        EXPECT_GT(F[8, 2], 0.0)
        EXPECT_GT(F[4, 0], 0.0)
        EXPECT_GT(F[4, 1], 0.0)
        EXPECT_GT(F[4, 3], 0.0)
        EXPECT_GT(F[4, 5], 0.0)
        EXPECT_GT(F[4, 6], 0.0)
        EXPECT_GT(F[4, 7], 0.0)
        EXPECT_GT(F[4, 8], 0.0)
        EXPECT_GT(F[0, 4], 0.0)
        EXPECT_GT(F[1, 4], 0.0)
        EXPECT_GT(F[3, 4], 0.0)
        EXPECT_GT(F[5, 4], 0.0)
        EXPECT_GT(F[6, 4], 0.0)
        EXPECT_GT(F[7, 4], 0.0)
        EXPECT_GT(F[8, 4], 0.0)
        EXPECT_GT(F[3, 2], 0.0)
        EXPECT_GT(F[3, 4], 0.0)
        EXPECT_GT(F[2, 3], 0.0)
        EXPECT_GT(F[4, 3], 0.0)
        EXPECT_GT(F[6, 2], 0.0)
        EXPECT_GT(F[6, 4], 0.0)
        EXPECT_GT(F[2, 6], 0.0)
        EXPECT_GT(F[4, 6], 0.0)
        EXPECT_GT(F[0, 1], 0.0)
        EXPECT_GT(F[1, 0], 0.0)
        EXPECT_GT(F[1, 5], 0.0)
        EXPECT_GT(F[5, 1], 0.0)
        EXPECT_GT(F[0, 3], 0.0)
        EXPECT_GT(F[1, 3], 0.0)
        EXPECT_GT(F[5, 3], 0.0)
        EXPECT_GT(F[3, 0], 0.0)
        EXPECT_GT(F[3, 1], 0.0)
        EXPECT_GT(F[3, 5], 0.0)
        EXPECT_GT(F[0, 6], 0.0)
        EXPECT_GT(F[1, 6], 0.0)
        EXPECT_GT(F[5, 6], 0.0)
        EXPECT_GT(F[6, 0], 0.0)
        EXPECT_GT(F[6, 1], 0.0)
        EXPECT_GT(F[6, 5], 0.0)
        EXPECT_GT(F[0, 7], 0.0)
        EXPECT_GT(F[1, 7], 0.0)
        EXPECT_GT(F[5, 7], 0.0)
        EXPECT_GT(F[7, 0], 0.0)
        EXPECT_GT(F[7, 1], 0.0)
        EXPECT_GT(F[7, 5], 0.0)
        EXPECT_EQ(F[0, 5], 0.0)
        EXPECT_EQ(F[5, 0], 0.0)
        EXPECT_EQ(F[3, 6], 0.0)
        EXPECT_EQ(F[6, 3], 0.0)
        EXPECT_GT(F[3, 7], 0.0)
        EXPECT_GT(F[7, 3], 0.0)
        EXPECT_GT(F[6, 7], 0.0)
        EXPECT_GT(F[7, 6], 0.0)
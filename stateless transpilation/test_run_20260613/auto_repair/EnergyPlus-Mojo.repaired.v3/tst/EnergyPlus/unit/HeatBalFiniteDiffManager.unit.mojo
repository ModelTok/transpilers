from gtest import gtest, Test, Expect, EXPECT_EQ, EXPECT_NEAR, EXPECT_ANY_THROW, EXPECT_FALSE, EXPECT_TRUE, EXPECT_LT, EXPECT_GT
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataMoistureBalance import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.HeatBalFiniteDiffManager import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Material import *
from EnergyPlus.PhaseChangeModeling.HysteresisModel import *
from .Fixtures.EnergyPlusFixture import *
from EnergyPlus.DataHeatBalSurface import MinSurfaceTempLimit, MaxSurfaceTempLimit
class EnergyPlusFixture:

def HeatBalFiniteDiffManager_CalcNodeHeatFluxTest(state: __magic__):
    var SurfaceFD = state.dataHeatBalFiniteDiffMgr.SurfaceFD
    alias numNodes: Int = 4
    alias allowedTolerance: Float64 = 0.0001
    var nodeNum: Int = 0
    SurfaceFD.allocate(1)
    alias SurfNum: Int = 1
    var surfFD = SurfaceFD[SurfNum - 1]
    surfFD.QDreport.allocate(numNodes + 1)
    surfFD.TDpriortimestep.allocate(numNodes + 1)
    surfFD.TDT.allocate(numNodes + 1)
    surfFD.CpDelXRhoS1.allocate(numNodes + 1)
    surfFD.CpDelXRhoS2.allocate(numNodes + 1)
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux.allocate(1)
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux.allocate(1)
    state.dataGlobal.TimeStepZoneSec = 600.0
    var expectedResult1: Float64 = 0.0
    var expectedResult2: Float64 = 0.0
    var expectedResult3: Float64 = 0.0
    var expectedResult4: Float64 = 0.0
    var expectedResult5: Float64 = 0.0
    var expectedResultO: Float64 = 1.0
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1] = 100.0
    nodeNum = 1
    surfFD.TDpriortimestep[nodeNum - 1] = 20.0
    surfFD.TDT[nodeNum - 1] = 20.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult1 = state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1]
    nodeNum = 2
    surfFD.TDpriortimestep[nodeNum - 1] = 22.0
    surfFD.TDT[nodeNum - 1] = 22.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult2 = state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1]
    nodeNum = 3
    surfFD.TDpriortimestep[nodeNum - 1] = 23.0
    surfFD.TDT[nodeNum - 1] = 23.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult3 = state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1]
    nodeNum = 4
    surfFD.TDpriortimestep[nodeNum - 1] = 26.0
    surfFD.TDT[nodeNum - 1] = 26.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult4 = state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1]
    nodeNum = 5
    surfFD.TDpriortimestep[nodeNum - 1] = 27.0
    surfFD.TDT[nodeNum - 1] = 27.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult5 = state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1]
    state.dataEnvrn.IsRain = False
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1] = 77.0
    expectedResultO = 77.0
    CalcNodeHeatFlux(state, SurfNum, numNodes)
    EXPECT_NEAR(surfFD.QDreport[1 - 1], expectedResult1, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[2 - 1], expectedResult2, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[3 - 1], expectedResult3, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[4 - 1], expectedResult4, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[5 - 1], expectedResult5, allowedTolerance)
    EXPECT_NEAR(state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1], expectedResultO, allowedTolerance)
    state.dataEnvrn.IsRain = True
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1] = 77.0
    expectedResultO = -state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1]
    CalcNodeHeatFlux(state, SurfNum, numNodes)
    EXPECT_NEAR(surfFD.QDreport[1 - 1], expectedResult1, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[2 - 1], expectedResult2, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[3 - 1], expectedResult3, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[4 - 1], expectedResult4, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[5 - 1], expectedResult5, allowedTolerance)
    EXPECT_NEAR(state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1], expectedResultO, allowedTolerance)
    surfFD.QDreport = 0.0
    expectedResult1 = 0.0
    expectedResult2 = 0.0
    expectedResult3 = 0.0
    expectedResult4 = 0.0
    expectedResult5 = 0.0
    state.dataGlobal.TimeStepZoneSec = 600.0
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1] = -200.0
    nodeNum = 5
    surfFD.TDpriortimestep[nodeNum - 1] = 27.5
    surfFD.TDT[nodeNum - 1] = 27.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 0.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 0.0
    expectedResult5 = state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[SurfNum - 1]
    nodeNum = 4
    surfFD.TDpriortimestep[nodeNum - 1] = 26.0
    surfFD.TDT[nodeNum - 1] = 26.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 0.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult4 = expectedResult5
    nodeNum = 3
    surfFD.TDpriortimestep[nodeNum - 1] = 23.0
    surfFD.TDT[nodeNum - 1] = 23.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult3 = expectedResult4
    nodeNum = 2
    surfFD.TDpriortimestep[nodeNum - 1] = 22.2
    surfFD.TDT[nodeNum - 1] = 22.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult2 = expectedResult3 + (surfFD.TDT[nodeNum - 1] - surfFD.TDpriortimestep[nodeNum - 1]) * surfFD.CpDelXRhoS2[nodeNum - 1] / state.dataGlobal.TimeStepZoneSec
    nodeNum = 1
    surfFD.TDpriortimestep[nodeNum - 1] = 20.1
    surfFD.TDT[nodeNum - 1] = 20.0
    surfFD.CpDelXRhoS1[nodeNum - 1] = 1000.0
    surfFD.CpDelXRhoS2[nodeNum - 1] = 2000.0
    expectedResult1 = expectedResult2 + (surfFD.TDT[nodeNum] - surfFD.TDpriortimestep[nodeNum]) * surfFD.CpDelXRhoS1[nodeNum] / state.dataGlobal.TimeStepZoneSec
    expectedResult1 = expectedResult1 + (surfFD.TDT[nodeNum - 1] - surfFD.TDpriortimestep[nodeNum - 1]) * surfFD.CpDelXRhoS2[nodeNum - 1] / state.dataGlobal.TimeStepZoneSec
    state.dataEnvrn.IsRain = False
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1] = 123.0
    expectedResultO = 123.0
    CalcNodeHeatFlux(state, SurfNum, numNodes)
    EXPECT_NEAR(surfFD.QDreport[1 - 1], expectedResult1, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[2 - 1], expectedResult2, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[3 - 1], expectedResult3, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[4 - 1], expectedResult4, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[5 - 1], expectedResult5, allowedTolerance)
    EXPECT_NEAR(state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1], expectedResultO, allowedTolerance)
    state.dataEnvrn.IsRain = True
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1] = 123.0
    expectedResultO = -expectedResult1
    CalcNodeHeatFlux(state, SurfNum, numNodes)
    EXPECT_NEAR(surfFD.QDreport[1 - 1], expectedResult1, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[2 - 1], expectedResult2, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[3 - 1], expectedResult3, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[4 - 1], expectedResult4, allowedTolerance)
    EXPECT_NEAR(surfFD.QDreport[5 - 1], expectedResult5, allowedTolerance)
    EXPECT_NEAR(state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[SurfNum - 1], expectedResultO, allowedTolerance)

def HeatBalFiniteDiffManager_adjustPropertiesForPhaseChange(state: __magic__):
    var s_mat = state.dataMaterial
    var idf_objects = delimited_string(["  MaterialProperty:PhaseChangeHysteresis,",
                                       "    PCMNAME,   !- Name",
                                       "    10000,                   !- Latent Heat during the Entire Phase Change Process {J/kg}",
                                       "    1.5,                     !- Liquid State Thermal Conductivity {W/m-K}",
                                       "    2200,                    !- Liquid State Density {kg/m3}",
                                       "    2000,                    !- Liquid State Specific Heat {J/kg-K}",
                                       "    1,                       !- High Temperature Difference of Melting Curve {deltaC}",
                                       "    20,                      !- Peak Melting Temperature {C}",
                                       "    1,                       !- Low Temperature Difference of Melting Curve {deltaC}",
                                       "    1.8,                     !- Solid State Thermal Conductivity {W/m-K}",
                                       "    2300,                    !- Solid State Density {kg/m3}",
                                       "    2000,                    !- Solid State Specific Heat {J/kg-K}",
                                       "    1,                       !- High Temperature Difference of Freezing Curve {deltaC}",
                                       "    23,                      !- Peak Freezing Temperature {C}",
                                       "    1;                       !- Low Temperature Difference of Freezing Curve {deltaC}"])
    ASSERT_TRUE(process_idf(idf_objects, False))
    alias surfaceIndex: Int = 1
    alias finiteDiffLayerIndex: Int = 1
    var SurfaceFD = state.dataHeatBalFiniteDiffMgr.SurfaceFD
    SurfaceFD.allocate(1)
    SurfaceFD[surfaceIndex - 1].PhaseChangeTemperatureReverse.allocate(1)
    SurfaceFD[surfaceIndex - 1].PhaseChangeTemperatureReverse[finiteDiffLayerIndex - 1] = 20.0
    SurfaceFD[surfaceIndex - 1].PhaseChangeState.allocate(1)
    SurfaceFD[surfaceIndex - 1].PhaseChangeState[finiteDiffLayerIndex - 1] = Material.Phase.Liquid
    SurfaceFD[surfaceIndex - 1].PhaseChangeStateOld.allocate(1)
    SurfaceFD[surfaceIndex - 1].PhaseChangeStateOld[finiteDiffLayerIndex - 1] = Material.Phase.Melting
    SurfaceFD[surfaceIndex - 1].PhaseChangeStateRep.allocate(1)
    SurfaceFD[surfaceIndex - 1].PhaseChangeStateRep[finiteDiffLayerIndex - 1] = Material.phaseInts[Int(Material.Phase.Liquid)]
    SurfaceFD[surfaceIndex - 1].PhaseChangeStateOldRep.allocate(1)
    SurfaceFD[surfaceIndex - 1].PhaseChangeStateOldRep[finiteDiffLayerIndex - 1] = Material.phaseInts[Int(Material.Phase.Melting)]
    var mat = Material.MaterialBase()
    mat.Name = "PCMNAME"
    mat.group = Material.Group.Regular
    s_mat.materials.push_back(mat)
    mat.Num = s_mat.materials.isize()
    s_mat.materialMap.insert_or_assign(mat.Name, mat.Num)
    var ErrorsFound: Bool
    Material.GetHysteresisData(state, ErrorsFound)
    var matPC = __type_of__cast[Material.MaterialPhaseChange](s_mat.materials[Material.GetMaterialNum(state, "PCMNAME") - 1])
    var newSpecificHeat: Float64
    var newDensity: Float64
    var newThermalConductivity: Float64
    adjustPropertiesForPhaseChange(state, finiteDiffLayerIndex, surfaceIndex, matPC, 20.0, 20.1, newSpecificHeat, newDensity, newThermalConductivity)
    EXPECT_NEAR(10187.3, newSpecificHeat, 0.1)
    EXPECT_NEAR(2250, newDensity, 0.1)
    EXPECT_NEAR(1.65, newThermalConductivity, 0.1)
    SurfaceFD.deallocate()

def HeatBalFiniteDiffManager_findAnySurfacesUsingConstructionAndCondFDTest(state: __magic__):
    var ErrorsFound: Bool = False
    var idf_objects = delimited_string([
        "Material:AirGap,",
        "   F05 Ceiling air space resistance, !- Name",
        "   0.18;                    !- Thermal Resistance{ m2 - K / W }",
        "Material,",
        "   Reg Mat F05 Ceiling air space resistance, !- Name",
        "   VerySmooth, !- Roughness",
        "   0.36, !- Thickness{ m }",
        "   2.00, !- Conductivity{ W / m - K }",
        "   1.23, !- Density{ kg / m3 }",
        "   1000.0, !- Specific Heat{ J / kg - K }",
        "   0.9, !- Thermal Absorptance",
        "   0.7, !- Solar Absorptance",
        "   0.7; !- Visible Absorptance",
        "Material,",
        "   F16 Acoustic tile, !- Name",
        "   MediumSmooth, !- Roughness",
        "   0.0191, !- Thickness{ m }",
        "   0.06, !- Conductivity{ W / m - K }",
        "   368, !- Density{ kg / m3 }",
        "   590.000000000002, !- Specific Heat{ J / kg - K }",
        "   0.9, !- Thermal Absorptance",
        "   0.3, !- Solar Absorptance",
        "   0.3;                     !- Visible Absorptance",
        "Material,",
        "   M11 100mm lightweight concrete, !- Name",
        "   MediumRough, !- Roughness",
        "   0.1016, !- Thickness{ m }",
        "   0.53, !- Conductivity{ W / m - K }",
        "   1280, !- Density{ kg / m3 }",
        "   840.000000000002, !- Specific Heat{ J / kg - K }",
        "   0.9, !- Thermal Absorptance",
        "   0.5, !- Solar Absorptance",
        "   0.5;                     !- Visible Absorptance",
        "Construction,",
        "   Interior Floor, !- Name",
        "   F16 Acoustic tile, !- Outside Layer",
        "   F05 Ceiling air space resistance, !- Layer 2",
        "   M11 100mm lightweight concrete;  !- Layer 3",
        "Construction,",
        "   Interior Floor All Reg Mats,  !- Name",
        "   F16 Acoustic tile, !- Outside Layer",
        "   Reg Mat F05 Ceiling air space resistance, !- Layer 2",
        "   M11 100mm lightweight concrete;  !- Layer 3",
        "Output:Constructions,",
        "Constructions;",
        "Output:Constructions,",
        "Materials;",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    ErrorsFound = False
    Material.GetMaterialData(state, ErrorsFound)
    EXPECT_FALSE(ErrorsFound)
    ErrorsFound = False
    HeatBalanceManager.GetConstructData(state, ErrorsFound)
    EXPECT_FALSE(ErrorsFound)
    state.dataConstruction.Construct[1 - 1].IsUsed = True
    state.dataConstruction.Construct[2 - 1].IsUsed = True
    var thisData = state.dataSurface
    thisData.TotSurfaces = 2
    thisData.Surface.allocate(thisData.TotSurfaces)
    thisData.Surface[1 - 1].Construction = 1
    thisData.Surface[2 - 1].Construction = 2
    thisData.Surface[1 - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CondFD
    thisData.Surface[2 - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CondFD
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux.allocate(thisData.TotSurfaces)
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux.allocate(thisData.TotSurfaces)
    state.dataGlobal.TimeStepZoneSec = 600.0
    state.dataGlobal.TimeStepsInHour = 6
    var error_string = delimited_string(["   ** Severe  ** InitialInitHeatBalFiniteDiff: Found Material that is too thin and/or too highly conductive, material name = Reg Mat F05 Ceiling air space resistance",
                                        "   **   ~~~   ** High conductivity Material layers are not well supported by Conduction Finite Difference, material conductivity = 2.00000 [W/m-K]",
                                        "   **   ~~~   ** Material thermal diffusivity = 0.00162602 [m2/s]",
                                        "   **   ~~~   ** Material with this thermal diffusivity should have thickness > 1.71080 [m]",
                                        "   **  Fatal  ** Preceding conditions cause termination.",
                                        "   ...Summary of Errors that led to program termination:",
                                        "   ..... Reference severe error count=1",
                                        "   ..... Last severe error=InitialInitHeatBalFiniteDiff: Found Material that is too thin and/or too highly conductive, material name = Reg Mat F05 Ceiling air space resistance"])
    EXPECT_ANY_THROW(InitialInitHeatBalFiniteDiff(state))
    compare_err_stream(error_string, True)
    thisData.Surface[2 - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
    EXPECT_TRUE(EnergyPlus.HeatBalFiniteDiffManager.findAnySurfacesUsingConstructionAndCondFD(state, 1))
    EXPECT_FALSE(EnergyPlus.HeatBalFiniteDiffManager.findAnySurfacesUsingConstructionAndCondFD(state, 2))

def HeatBalFiniteDiffManager_CheckFDNodeTempLimitsTest(state: __magic__):
    var surfNum: Int
    var nodeNum: Int
    var nodeTemp: Float64
    var expectedAnswer: Float64
    var thisData = state.dataSurface
    var thisSurf = thisData.Surface
    var thisSurfFD = state.dataHeatBalFiniteDiffMgr.SurfaceFD
    thisData.TotSurfaces = 2
    thisSurf.allocate(thisData.TotSurfaces)
    thisSurfFD.allocate(thisData.TotSurfaces)
    thisSurf[1 - 1].Name = "CONDFD SURFACE 1"
    thisSurf[2 - 1].Name = "CONDFD SURFACE 2"
    thisSurfFD[1 - 1].indexNodeMinTempLimit = 0
    thisSurfFD[1 - 1].indexNodeMaxTempLimit = 0
    thisSurfFD[2 - 1].indexNodeMinTempLimit = 0
    thisSurfFD[2 - 1].indexNodeMaxTempLimit = 0
    surfNum = 1
    nodeNum = 1
    nodeTemp = 1.23
    expectedAnswer = nodeTemp
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMinTempLimit, 0)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMaxTempLimit, 0)
    surfNum = 2
    nodeNum = 2
    nodeTemp = 4.56
    expectedAnswer = nodeTemp
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMinTempLimit, 0)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMaxTempLimit, 0)
    surfNum = 1
    nodeNum = 3
    nodeTemp = -3000.0
    expectedAnswer = DataHeatBalSurface.MinSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMinTempLimit, 1)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMaxTempLimit, 0)
    var error_string_21 = delimited_string(["   ** Severe  ** Node temperature (low) out of bounds [-3000.00] for surface=CONDFD SURFACE 1, node=3",
                                           "   **   ~~~   **  Environment=, at Simulation time= 00:00 - 00:00",
                                           "   **   ~~~   ** Value has been reset to the lower limit value of -100.00."])
    compare_err_stream(error_string_21, True)
    surfNum = 2
    nodeNum = 4
    nodeTemp = -4000.0
    expectedAnswer = DataHeatBalSurface.MinSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMinTempLimit, 2)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMaxTempLimit, 0)
    var error_string_22 = delimited_string(["   ** Severe  ** Node temperature (low) out of bounds [-4000.00] for surface=CONDFD SURFACE 2, node=4",
                                           "   **   ~~~   **  Environment=, at Simulation time= 00:00 - 00:00",
                                           "   **   ~~~   ** Value has been reset to the lower limit value of -100.00."])
    compare_err_stream(error_string_22, True)
    surfNum = 1
    nodeNum = 5
    nodeTemp = -3000.0
    expectedAnswer = DataHeatBalSurface.MinSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMinTempLimit, 1)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMaxTempLimit, 0)
    surfNum = 2
    nodeNum = 6
    nodeTemp = -4000.0
    expectedAnswer = DataHeatBalSurface.MinSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMinTempLimit, 2)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMaxTempLimit, 0)
    surfNum = 1
    nodeNum = 7
    nodeTemp = 3000.0
    expectedAnswer = state.dataHeatBalSurf.MaxSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMinTempLimit, 1)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMaxTempLimit, 3)
    var error_string_41 = delimited_string(["   ** Severe  ** Node temperature (high) out of bounds [3000.00] for surface=CONDFD SURFACE 1, node=7",
                                           "   **   ~~~   **  Environment=, at Simulation time= 00:00 - 00:00",
                                           "   **   ~~~   ** Value has been reset to the upper limit value of 200.00."])
    compare_err_stream(error_string_41, True)
    surfNum = 2
    nodeNum = 8
    nodeTemp = 4000.0
    expectedAnswer = state.dataHeatBalSurf.MaxSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMinTempLimit, 2)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMaxTempLimit, 4)
    var error_string_42 = delimited_string(["   ** Severe  ** Node temperature (high) out of bounds [4000.00] for surface=CONDFD SURFACE 2, node=8",
                                           "   **   ~~~   **  Environment=, at Simulation time= 00:00 - 00:00",
                                           "   **   ~~~   ** Value has been reset to the upper limit value of 200.00."])
    compare_err_stream(error_string_42, True)
    surfNum = 1
    nodeNum = 9
    nodeTemp = 3000.0
    expectedAnswer = state.dataHeatBalSurf.MaxSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMinTempLimit, 1)
    EXPECT_EQ(thisSurfFD[1 - 1].indexNodeMaxTempLimit, 3)
    surfNum = 2
    nodeNum = 10
    nodeTemp = 4000.0
    expectedAnswer = state.dataHeatBalSurf.MaxSurfaceTempLimit
    EnergyPlus.HeatBalFiniteDiffManager.CheckFDNodeTempLimits(state, surfNum, nodeNum, nodeTemp)
    EXPECT_EQ(nodeTemp, expectedAnswer)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMinTempLimit, 2)
    EXPECT_EQ(thisSurfFD[2 - 1].indexNodeMaxTempLimit, 4)

def HeatBalFiniteDiffManager_setSizeMaxPropertiesTest(state: __magic__):
    var idf_objects = delimited_string([
        "MaterialProperty:VariableThermalConductivity,",
        "    PCMPlasterBoard , !- Name",
        "    0,    !- Temperature 1 {C}",
        "    4.2,  !- Thermal Conductivity 1 {W/m-K}",
        "    22,   !- Temperature 2 {C}",
        "    4.2,  !- Thermal Conductivity 2 {W/m-K}",
        "    22.1, !- Temperature 3 {C}",
        "    2.5,  !- Thermal Conductivity 3 {W/m-K}",
        "    100,  !- Temperature 4 {C}",
        "    2.5;  !- Thermal Conductivity 4 {W/m-K}",
        "MaterialProperty:PhaseChange,",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD , !- Name",
        "    0.0,    !- Temperature coefficient ,thermal conductivity(W/m K2)",
        "    -20.,   !- Temperature 1, C",
        "    0.01,   !- Enthalpy 1 at –20C, (J/kg)",
        "    20.,    !- Temperature 2, C",
        "    33400,  !- Enthalpy 2, (J/kg)",
        "    20.5,   !- temperature 3, C",
        "    70000,  !- Enthalpy 3, (J/kg)",
        "    100.,   !- Temperature 4, C",
        "    137000; !- Enthalpy 4, (J/kg)",
        "MaterialProperty:VariableThermalConductivity,",
        "    PCMPlasterBoard 2, !- Name",
        "    0,    !- Temperature 1 {C}",
        "    4.2,  !- Thermal Conductivity 1 {W/m-K}",
        "    22,   !- Temperature 2 {C}",
        "    4.2,  !- Thermal Conductivity 2 {W/m-K}",
        "    22.1, !- Temperature 3 {C}",
        "    2.5,  !- Thermal Conductivity 3 {W/m-K}",
        "    100,  !- Temperature 4 {C}",
        "    2.5,  !- Thermal Conductivity 4 {W/m-K}",
        "    0,    !- Temperature 5 {C}",
        "    4.2,  !- Thermal Conductivity 5 {W/m-K}",
        "    22,   !- Temperature 6 {C}",
        "    4.2,  !- Thermal Conductivity 6 {W/m-K}",
        "    22.1, !- Temperature 7 {C}",
        "    2.5,  !- Thermal Conductivity 7 {W/m-K}",
        "    100,  !- Temperature 8 {C}",
        "    2.5,  !- Thermal Conductivity 8 {W/m-K}",
        "    0,    !- Temperature 9 {C}",
        "    4.2,  !- Thermal Conductivity 9 {W/m-K}",
        "    22,   !- Temperature 10 {C}",
        "    4.2,  !- Thermal Conductivity 10 {W/m-K}",
        "    0,    !- Temperature 11 {C}",
        "    4.2,  !- Thermal Conductivity 11 {W/m-K}",
        "    22,   !- Temperature 12 {C}",
        "    4.2,  !- Thermal Conductivity 12 {W/m-K}",
        "    22.1, !- Temperature 13 {C}",
        "    2.5,  !- Thermal Conductivity 13 {W/m-K}",
        "    100,  !- Temperature 14 {C}",
        "    2.5,  !- Thermal Conductivity 14 {W/m-K}",
        "    0,    !- Temperature 15 {C}",
        "    4.2,  !- Thermal Conductivity 15 {W/m-K}",
        "    22,   !- Temperature 16 {C}",
        "    4.2,  !- Thermal Conductivity 16 {W/m-K}",
        "    22.1, !- Temperature 17 {C}",
        "    2.5,  !- Thermal Conductivity 17 {W/m-K}",
        "    100,  !- Temperature 18 {C}",
        "    2.5,  !- Thermal Conductivity 18 {W/m-K}",
        "    0,    !- Temperature 19 {C}",
        "    4.2,  !- Thermal Conductivity 19 {W/m-K}",
        "    22,   !- Temperature 20 {C}",
        "    4.2,  !- Thermal Conductivity 20 {W/m-K}",
        "    0,    !- Temperature 21 {C}",
        "    4.2,  !- Thermal Conductivity 21 {W/m-K}",
        "    22,   !- Temperature 22 {C}",
        "    4.2,  !- Thermal Conductivity 22 {W/m-K}",
        "    22.1, !- Temperature 23 {C}",
        "    2.5,  !- Thermal Conductivity 23 {W/m-K}",
        "    100,  !- Temperature 24 {C}",
        "    2.5,  !- Thermal Conductivity 24 {W/m-K}",
        "    0,    !- Temperature 25 {C}",
        "    4.2,  !- Thermal Conductivity 25 {W/m-K}",
        "    22,   !- Temperature 26 {C}",
        "    4.2,  !- Thermal Conductivity 26 {W/m-K}",
        "    22.1, !- Temperature 27 {C}",
        "    2.5,  !- Thermal Conductivity 27 {W/m-K}",
        "    100,  !- Temperature 28 {C}",
        "    2.5,  !- Thermal Conductivity 28 {W/m-K}",
        "    0,    !- Temperature 29 {C}",
        "    4.2,  !- Thermal Conductivity 29 {W/m-K}",
        "    22,   !- Temperature 30 {C}",
        "    4.2,  !- Thermal Conductivity 30 {W/m-K}",
        "    0,    !- Temperature 31 {C}",
        "    4.2,  !- Thermal Conductivity 31 {W/m-K}",
        "    22,   !- Temperature 32 {C}",
        "    4.2,  !- Thermal Conductivity 32 {W/m-K}",
        "    22.1, !- Temperature 33 {C}",
        "    2.5,  !- Thermal Conductivity 33 {W/m-K}",
        "    100,  !- Temperature 34 {C}",
        "    2.5,  !- Thermal Conductivity 34 {W/m-K}",
        "    0,    !- Temperature 35 {C}",
        "    4.2,  !- Thermal Conductivity 35 {W/m-K}",
        "    22,   !- Temperature 36 {C}",
        "    4.2,  !- Thermal Conductivity 36 {W/m-K}",
        "    22.1, !- Temperature 37 {C}",
        "    2.5,  !- Thermal Conductivity 37 {W/m-K}",
        "    100,  !- Temperature 38 {C}",
        "    2.5,  !- Thermal Conductivity 38 {W/m-K}",
        "    0,    !- Temperature 39 {C}",
        "    4.2,  !- Thermal Conductivity 39 {W/m-K}",
        "    22,   !- Temperature 40 {C}",
        "    4.2,  !- Thermal Conductivity 40 {W/m-K}",
        "    0,    !- Temperature 41 {C}",
        "    4.2,  !- Thermal Conductivity 41 {W/m-K}",
        "    22,   !- Temperature 42 {C}",
        "    4.2,  !- Thermal Conductivity 42 {W/m-K}",
        "    22.1, !- Temperature 43 {C}",
        "    2.5,  !- Thermal Conductivity 43 {W/m-K}",
        "    100,  !- Temperature 44 {C}",
        "    2.5,  !- Thermal Conductivity 44 {W/m-K}",
        "    0,    !- Temperature 45 {C}",
        "    4.2,  !- Thermal Conductivity 45 {W/m-K}",
        "    22,   !- Temperature 46 {C}",
        "    4.2,  !- Thermal Conductivity 46 {W/m-K}",
        "    22.1, !- Temperature 47 {C}",
        "    2.5,  !- Thermal Conductivity 47 {W/m-K}",
        "    100,  !- Temperature 48 {C}",
        "    2.5,  !- Thermal Conductivity 48 {W/m-K}",
        "    0,    !- Temperature 49 {C}",
        "    4.2,  !- Thermal Conductivity 49 {W/m-K}",
        "    22,   !- Temperature 50 {C}",
        "    4.2;  !- Thermal Conductivity 10 {W/m-K}",
        "MaterialProperty:VariableThermalConductivity,",
        "    PCMPlasterBoard3, !- Name",
        "    0,    !- Temperature 1 {C}",
        "    7.11, !- Thermal Conductivity 1 {W/m-K}",
        "    100,  !- Temperature 2 {C}",
        "    2.3;  !- Thermal Conductivity 2 {W/m-K}",
        "MaterialProperty:PhaseChange,",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD c, !- Name",
        "    0.0,    !- Temperature coefficient ,thermal conductivity(W/m K2)",
        "    -20.,   !- Temperature 1, C",
        "    0.01,   !- Enthalpy 1 at –20C, (J/kg)",
        "    20.,    !- Temperature 2, C",
        "    33400,  !- Enthalpy 2, (J/kg)",
        "    20.5,   !- Temperature 3, C",
        "    70000,  !- Enthalpy 3, (J/kg)",
        "    100.,   !- Temperature 4, C",
        "    137000, !- Enthalpy 4, (J/kg)",
        "    -20.,   !- Temperature 5, C",
        "    0.01,   !- Enthalpy 5 at –20C, (J/kg)",
        "    20.,    !- Temperature 6, C",
        "    33400,  !- Enthalpy 6, (J/kg)",
        "    20.5,   !- Temperature 7, C",
        "    70000,  !- Enthalpy 7, (J/kg)",
        "    100.,   !- Temperature 8, C",
        "    137000, !- Enthalpy 8, (J/kg)",
        "    -20.,   !- Temperature 9, C",
        "    0.01,   !- Enthalpy 9 at –20C, (J/kg)",
        "    20.,    !- Temperature 10, C",
        "    33400,  !- Enthalpy 10, (J/kg)",
        "    -20.,   !- Temperature 11, C",
        "    0.01,   !- Enthalpy 11 at –20C, (J/kg)",
        "    20.,    !- Temperature 12, C",
        "    33400,  !- Enthalpy 12, (J/kg)",
        "    20.5,   !- Temperature 13, C",
        "    70000,  !- Enthalpy 13, (J/kg)",
        "    100.,   !- Temperature 14, C",
        "    137000, !- Enthalpy 14, (J/kg)",
        "    -20.,   !- Temperature 15, C",
        "    0.01,   !- Enthalpy 15 at –20C, (J/kg)",
        "    20.,    !- Temperature 16, C",
        "    33400,  !- Enthalpy 16, (J/kg)",
        "    20.5,   !- Temperature 17, C",
        "    70000,  !- Enthalpy 17, (J/kg)",
        "    100.,   !- Temperature 18, C",
        "    137000, !- Enthalpy 18, (J/kg)",
        "    -20.,   !- Temperature 19, C",
        "    0.01,   !- Enthalpy 19 at –20C, (J/kg)",
        "    20.,    !- Temperature 20, C",
        "    33400,  !- Enthalpy 20, (J/kg)",
        "    -20.,   !- Temperature 21, C",
        "    0.01,   !- Enthalpy 21 at –20C, (J/kg)",
        "    20.,    !- Temperature 22, C",
        "    33400,  !- Enthalpy 22, (J/kg)",
        "    20.5,   !- Temperature 23, C",
        "    70000,  !- Enthalpy 23, (J/kg)",
        "    100.,   !- Temperature 24, C",
        "    137000, !- Enthalpy 24, (J/kg)",
        "    -20.,   !- Temperature 25, C",
        "    0.01,   !- Enthalpy 25 at –20C, (J/kg)",
        "    20.,    !- Temperature 26, C",
        "    33400,  !- Enthalpy 26, (J/kg)",
        "    20.5,   !- Temperature 27, C",
        "    70000,  !- Enthalpy 27, (J/kg)",
        "    100.,   !- Temperature 28, C",
        "    137000, !- Enthalpy 28, (J/kg)",
        "    -20.,   !- Temperature 29, C",
        "    0.01,   !- Enthalpy 29 at –20C, (J/kg)",
        "    20.,    !- Temperature 30, C",
        "    33400,  !- Enthalpy 30, (J/kg)",
        "    -20.,   !- Temperature 31, C",
        "    0.01,   !- Enthalpy 31 at –20C, (J/kg)",
        "    20.,    !- Temperature 32, C",
        "    33400,  !- Enthalpy 32, (J/kg)",
        "    20.5,   !- Temperature 33, C",
        "    70000,  !- Enthalpy 33, (J/kg)",
        "    100.,   !- Temperature 34, C",
        "    137000, !- Enthalpy 34, (J/kg)",
        "    -20.,   !- Temperature 35, C",
        "    0.01,   !- Enthalpy 35 at –20C, (J/kg)",
        "    20.,    !- Temperature 36, C",
        "    33400,  !- Enthalpy 36, (J/kg)",
        "    20.5,   !- Temperature 37, C",
        "    70000,  !- Enthalpy 37, (J/kg)",
        "    100.,   !- Temperature 38, C",
        "    137000, !- Enthalpy 38, (J/kg)",
        "    -20.,   !- Temperature 39, C",
        "    0.01,   !- Enthalpy 39 at –20C, (J/kg)",
        "    20.,    !- Temperature 40, C",
        "    33400,  !- Enthalpy 40, (J/kg)",
        "    -20.,   !- Temperature 41, C",
        "    0.01,   !- Enthalpy 41 at –20C, (J/kg)",
        "    20.,    !- Temperature 42, C",
        "    33400,  !- Enthalpy 42, (J/kg)",
        "    20.5,   !- Temperature 43, C",
        "    70000,  !- Enthalpy 43, (J/kg)",
        "    100.,   !- Temperature 44, C",
        "    137000, !- Enthalpy 44, (J/kg)",
        "    -20.,   !- Temperature 45, C",
        "    0.01,   !- Enthalpy 45 at –20C, (J/kg)",
        "    20.,    !- Temperature 46, C",
        "    33400,  !- Enthalpy 46, (J/kg)",
        "    20.5,   !- Temperature 47, C",
        "    70000,  !- Enthalpy 47, (J/kg)",
        "    100.,   !- Temperature 48, C",
        "    137000, !- Enthalpy 48, (J/kg)",
        "    -20.,   !- Temperature 49, C",
        "    0.01,   !- Enthalpy 49 at –20C, (J/kg)",
        "    20.,    !- Temperature 50, C",
        "    33400;  !- Enthalpy 50, (J/kg)",
        "MaterialProperty:PhaseChange,",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD b, !- Name",
        "    1.2,    !- Temperature coefficient ,thermal conductivity(W/m K2)",
        "    -20.,   !- Temperature 1, C",
        "    0.001,  !- Enthalpy 1 at –20C, (J/kg)",
        "    100.0,  !- Temperature 2, C",
        "    233400; !- Enthalpy 2, (J/kg)",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    var functionAnswer: Int = 0
    var expectedAnswer: Int = 101
    functionAnswer = EnergyPlus.HeatBalFiniteDiffManager.setSizeMaxProperties(state)
    EXPECT_EQ(functionAnswer, expectedAnswer)

def HeatBalFiniteDiffManager_EnetActuatorOverride(state: __magic__):
    alias SurfNum: Int = 1
    alias TotNodes: Int = 3
    alias TotLayers: Int = 1
    state.dataSurface.TotSurfaces = 1
    state.dataSurface.Surface.allocate(1)
    var surf = state.dataSurface.Surface[SurfNum - 1]
    surf.Name = "ZN001:ROOF001"
    surf.HeatTransSurf = True
    surf.HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CondFD
    surf.ExtBoundCond = DataSurfaces.ExternalEnvironment
    surf.Construction = 1
    surf.Area = 10.0
    surf.Class = DataSurfaces.SurfaceClass.Roof
    state.dataHeatBal.TotConstructs = 1
    state.dataConstruction.Construct.allocate(1)
    var constr = state.dataConstruction.Construct[1 - 1]
    constr.TotLayers = TotLayers
    constr.LayerPoint.allocate(TotLayers)
    constr.LayerPoint[1 - 1] = 1
    var mat = Material.MaterialBase()
    mat.Name = "C5 - 4 IN HW CONCRETE"
    mat.group = Material.Group.Regular
    mat.Roughness = Material.SurfaceRoughness.MediumRough
    mat.Thickness = 0.1016
    mat.Conductivity = 1.311
    mat.Density = 2240.0
    mat.SpecHeat = 836.8
    mat.AbsorpThermal = 0.9
    mat.AbsorpSolar = 0.85
    mat.AbsorpVisible = 0.85
    mat.ROnly = False
    mat.hasPCM = False
    state.dataMaterial.materials.push_back(mat)
    mat.Num = state.dataMaterial.materials.isize()
    var s_hbfd = state.dataHeatBalFiniteDiffMgr
    s_hbfd.CondFDSchemeType = CondFDScheme.FullyImplicitFirstOrder
    s_hbfd.ConstructFD.allocate(1)
    s_hbfd.ConstructFD[1 - 1].TotNodes = TotNodes
    s_hbfd.ConstructFD[1 - 1].DelX.allocate(TotLayers)
    s_hbfd.ConstructFD[1 - 1].DelX[1 - 1] = 0.0254
    s_hbfd.ConstructFD[1 - 1].NodeNumPoint.allocate(TotLayers)
    s_hbfd.ConstructFD[1 - 1].NodeNumPoint[1 - 1] = TotNodes
    s_hbfd.MaterialFD.allocate(1)
    s_hbfd.MaterialFD[1 - 1].tk1 = 0.0
    s_hbfd.MaterialFD[1 - 1].numTempEnth = 0
    s_hbfd.MaterialFD[1 - 1].numTempCond = 0
    s_hbfd.MaterialFD[1 - 1].TempCond.allocate(2, 3)
    s_hbfd.MaterialFD[1 - 1].TempCond = -1.0
    s_hbfd.MaterialFD[1 - 1].TempEnth.allocate(2, 3)
    s_hbfd.MaterialFD[1 - 1].TempEnth = -1.0
    s_hbfd.SurfaceFD.allocate(1)
    var surfFD = s_hbfd.SurfaceFD[SurfNum - 1]
    var numNodes = TotNodes + 1
    surfFD.T.allocate(numNodes)
    surfFD.TOld.allocate(numNodes)
    surfFD.TT.allocate(numNodes)
    surfFD.Rhov.allocate(numNodes)
    surfFD.RhovOld.allocate(numNodes)
    surfFD.RhoT.allocate(numNodes)
    surfFD.TD.allocate(numNodes)
    surfFD.TDT.allocate(numNodes)
    surfFD.TDTLast.allocate(numNodes)
    surfFD.TDOld.allocate(numNodes)
    surfFD.TDreport.allocate(numNodes)
    surfFD.RH.allocate(numNodes)
    surfFD.RHreport.allocate(numNodes)
    surfFD.EnthOld.allocate(numNodes)
    surfFD.EnthNew.allocate(numNodes)
    surfFD.EnthLast.allocate(numNodes)
    surfFD.QDreport.allocate(numNodes)
    surfFD.CpDelXRhoS1.allocate(numNodes)
    surfFD.CpDelXRhoS2.allocate(numNodes)
    surfFD.TDpriortimestep.allocate(numNodes)
    surfFD.PhaseChangeState.allocate(numNodes)
    surfFD.PhaseChangeStateOld.allocate(numNodes)
    surfFD.PhaseChangeStateOldOld.allocate(numNodes)
    surfFD.PhaseChangeStateRep.allocate(numNodes)
    surfFD.PhaseChangeStateOldRep.allocate(numNodes)
    surfFD.PhaseChangeStateOldOldRep.allocate(numNodes)
    surfFD.PhaseChangeTemperatureReverse.allocate(numNodes)
    surfFD.condMaterialActuators.allocate(TotLayers)
    surfFD.specHeatMaterialActuators.allocate(TotLayers)
    surfFD.condNodeReport.allocate(numNodes)
    surfFD.specHeatNodeReport.allocate(numNodes)
    surfFD.heatSourceFluxMaterialActuators.allocate(1)
    surfFD.heatSourceInternalFluxLayerReport.allocate(1)
    surfFD.heatSourceInternalFluxEnergyLayerReport.allocate(1)
    surfFD.heatSourceEMSFluxLayerReport.allocate(1)
    surfFD.heatSourceEMSFluxEnergyLayerReport.allocate(1)
    surfFD.T = 20.0
    surfFD.TOld = 20.0
    surfFD.TT = 20.0
    surfFD.Rhov = 0.0
    surfFD.RhovOld = 0.0
    surfFD.RhoT = 0.0
    surfFD.TD = 20.0
    surfFD.TDT = 20.0
    surfFD.TDTLast = 20.0
    surfFD.TDOld = 20.0
    surfFD.TDreport = 20.0
    surfFD.RH = 0.0
    surfFD.RHreport = 0.0
    surfFD.EnthOld = 100.0
    surfFD.EnthNew = 100.0
    surfFD.EnthLast = 100.0
    surfFD.QDreport = 0.0
    surfFD.CpDelXRhoS1 = 0.0
    surfFD.CpDelXRhoS2 = 0.0
    surfFD.TDpriortimestep = 20.0
    surfFD.PhaseChangeState = Material.Phase.Transition
    surfFD.PhaseChangeStateOld = Material.Phase.Transition
    surfFD.PhaseChangeStateOldOld = Material.Phase.Transition
    surfFD.PhaseChangeTemperatureReverse = 50.0
    surfFD.condNodeReport = 0.0
    surfFD.specHeatNodeReport = 0.0
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux.allocate(1)
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux.allocate(1)
    state.dataHeatBalSurf.SurfQdotRadOutRepPerArea.allocate(1)
    state.dataHeatBalSurf.SurfQdotRadOutRep.allocate(1)
    state.dataHeatBalSurf.SurfQRadOutReport.allocate(1)
    state.dataHeatBalSurf.SurfOpaqQRadSWOutAbs.allocate(1)
    state.dataHeatBalSurf.SurfQRadSWOutMvIns.allocate(1)
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQdotRadOutRep[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQRadOutReport[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfOpaqQRadSWOutAbs[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQRadSWOutMvIns[1 - 1] = 0.0
    state.dataMstBal.TempOutsideAirFD.allocate(1)
    state.dataMstBal.RhoVaporAirOut.allocate(1)
    state.dataMstBal.HConvExtFD.allocate(1)
    state.dataMstBal.HSkyFD.allocate(1)
    state.dataMstBal.HGrndFD.allocate(1)
    state.dataMstBal.HAirFD.allocate(1)
    state.dataMstBal.HSurrFD.allocate(1)
    alias Toa: Float64 = 10.0
    alias Tsky: Float64 = -20.0
    state.dataMstBal.TempOutsideAirFD[1 - 1] = Toa
    state.dataMstBal.RhoVaporAirOut[1 - 1] = 0.005
    state.dataMstBal.HConvExtFD[1 - 1] = 10.0
    state.dataMstBal.HSkyFD[1 - 1] = 5.0
    state.dataMstBal.HGrndFD[1 - 1] = 3.0
    state.dataMstBal.HAirFD[1 - 1] = 1.0
    state.dataMstBal.HSurrFD[1 - 1] = 0.0
    state.dataEnvrn.SkyTemp = Tsky
    state.dataEnvrn.IsRain = False
    state.dataGlobal.TimeStepZoneSec = 600.0
    surf.UseSurfPropertyGndSurfTemp = False
    surf.SurfHasSurroundingSurfProperty = False
    s_hbfd.QHeatOutFlux.allocate(1)
    s_hbfd.QHeatOutFlux[1 - 1] = 0.0
    alias Delt: Int = 600
    alias nodeIdx: Int = 1
    alias Lay: Int = 1
    alias HMovInsul: Float64 = 0.0
    var T_arr = Array1D[Float64](numNodes, 20.0)
    var TT_arr = Array1D[Float64](numNodes, 20.0)
    var Rhov_arr = Array1D[Float64](numNodes, 0.0)
    var RhoT_arr = Array1D[Float64](numNodes, 0.0)
    var RH_arr = Array1D[Float64](numNodes, 0.0)
    var TD_arr = Array1D[Float64](numNodes, 20.0)
    var TDT_arr = Array1D[Float64](numNodes, 20.0)
    var EnthOld_arr = Array1D[Float64](numNodes, 100.0)
    var EnthNew_arr = Array1D[Float64](numNodes, 100.0)
    surfFD.enetActuator.isActuated = False
    surfFD.enetActuator.actuatedValue = 0.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_baseline = TDT_arr[nodeIdx - 1]
    var QRad_baseline = state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1]
    var CondFlux_baseline = state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[1 - 1]
    EXPECT_EQ(surfFD.enetActuatorReport, 0.0)
    EXPECT_LT(QRad_baseline, 0.0)
    surfFD.enetActuator.isActuated = True
    surfFD.enetActuator.actuatedValue = 0.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_enet0 = TDT_arr[nodeIdx - 1]
    var QRad_enet0 = state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1]
    var CondFlux_enet0 = state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[1 - 1]
    EXPECT_EQ(surfFD.enetActuatorReport, 0.0)
    EXPECT_GT(TDT_enet0, TDT_baseline)
    EXPECT_GT(QRad_enet0, QRad_baseline)
    EXPECT_LT(CondFlux_enet0, CondFlux_baseline)
    surfFD.enetActuator.isActuated = True
    surfFD.enetActuator.actuatedValue = -200.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_enetNeg200 = TDT_arr[nodeIdx - 1]
    var QRad_enetNeg200 = state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1]
    var CondFlux_enetNeg200 = state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[1 - 1]
    EXPECT_EQ(surfFD.enetActuatorReport, -200.0)
    EXPECT_LT(TDT_enetNeg200, TDT_baseline)
    surfFD.enetActuator.isActuated = True
    surfFD.enetActuator.actuatedValue = 200.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_enetPos200 = TDT_arr[nodeIdx - 1]
    var QRad_enetPos200 = state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1]
    var CondFlux_enetPos200 = state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[1 - 1]
    EXPECT_EQ(surfFD.enetActuatorReport, 200.0)
    EXPECT_GT(QRad_enetPos200, 0.0)
    EXPECT_LT(TDT_enetNeg200, TDT_baseline)
    EXPECT_LT(TDT_baseline, TDT_enet0)
    EXPECT_LT(TDT_enet0, TDT_enetPos200)
    EXPECT_LT(QRad_enetNeg200, QRad_baseline)
    EXPECT_LT(QRad_baseline, QRad_enet0)
    EXPECT_LT(QRad_enet0, QRad_enetPos200)
    EXPECT_GT(CondFlux_enetNeg200, CondFlux_baseline)
    EXPECT_GT(CondFlux_baseline, CondFlux_enet0)
    EXPECT_GT(CondFlux_enet0, CondFlux_enetPos200)
    surfFD.enetActuator.isActuated = False
    surfFD.enetActuator.actuatedValue = 200.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    EXPECT_NEAR(TDT_arr[nodeIdx - 1], TDT_baseline, 1e-10)
    EXPECT_NEAR(state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1], QRad_baseline, 1e-10)
    EXPECT_NEAR(state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[1 - 1], CondFlux_baseline, 1e-10)
    EXPECT_EQ(surfFD.enetActuatorReport, 0.0)

def HeatBalFiniteDiffManager_EnetActuatorOverride_CrankNicolson(state: __magic__):
    alias SurfNum: Int = 1
    alias TotNodes: Int = 3
    alias TotLayers: Int = 1
    state.dataSurface.TotSurfaces = 1
    state.dataSurface.Surface.allocate(1)
    var surf = state.dataSurface.Surface[SurfNum - 1]
    surf.Name = "ZN001:ROOF001"
    surf.HeatTransSurf = True
    surf.HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CondFD
    surf.ExtBoundCond = DataSurfaces.ExternalEnvironment
    surf.Construction = 1
    surf.Area = 10.0
    surf.Class = DataSurfaces.SurfaceClass.Roof
    state.dataHeatBal.TotConstructs = 1
    state.dataConstruction.Construct.allocate(1)
    var constr = state.dataConstruction.Construct[1 - 1]
    constr.TotLayers = TotLayers
    constr.LayerPoint.allocate(TotLayers)
    constr.LayerPoint[1 - 1] = 1
    var mat = Material.MaterialBase()
    mat.Name = "C5 - 4 IN HW CONCRETE"
    mat.group = Material.Group.Regular
    mat.Roughness = Material.SurfaceRoughness.MediumRough
    mat.Thickness = 0.1016
    mat.Conductivity = 1.311
    mat.Density = 2240.0
    mat.SpecHeat = 836.8
    mat.AbsorpThermal = 0.9
    mat.AbsorpSolar = 0.85
    mat.AbsorpVisible = 0.85
    mat.ROnly = False
    mat.hasPCM = False
    state.dataMaterial.materials.push_back(mat)
    mat.Num = state.dataMaterial.materials.isize()
    var s_hbfd = state.dataHeatBalFiniteDiffMgr
    s_hbfd.CondFDSchemeType = CondFDScheme.CrankNicholsonSecondOrder
    s_hbfd.ConstructFD.allocate(1)
    s_hbfd.ConstructFD[1 - 1].TotNodes = TotNodes
    s_hbfd.ConstructFD[1 - 1].DelX.allocate(TotLayers)
    s_hbfd.ConstructFD[1 - 1].DelX[1 - 1] = 0.0254
    s_hbfd.ConstructFD[1 - 1].NodeNumPoint.allocate(TotLayers)
    s_hbfd.ConstructFD[1 - 1].NodeNumPoint[1 - 1] = TotNodes
    s_hbfd.MaterialFD.allocate(1)
    s_hbfd.MaterialFD[1 - 1].tk1 = 0.0
    s_hbfd.MaterialFD[1 - 1].numTempEnth = 0
    s_hbfd.MaterialFD[1 - 1].numTempCond = 0
    s_hbfd.MaterialFD[1 - 1].TempCond.allocate(2, 3)
    s_hbfd.MaterialFD[1 - 1].TempCond = -1.0
    s_hbfd.MaterialFD[1 - 1].TempEnth.allocate(2, 3)
    s_hbfd.MaterialFD[1 - 1].TempEnth = -1.0
    s_hbfd.SurfaceFD.allocate(1)
    var surfFD = s_hbfd.SurfaceFD[SurfNum - 1]
    var numNodes = TotNodes + 1
    surfFD.T.allocate(numNodes)
    surfFD.TOld.allocate(numNodes)
    surfFD.TT.allocate(numNodes)
    surfFD.Rhov.allocate(numNodes)
    surfFD.RhovOld.allocate(numNodes)
    surfFD.RhoT.allocate(numNodes)
    surfFD.TD.allocate(numNodes)
    surfFD.TDT.allocate(numNodes)
    surfFD.TDTLast.allocate(numNodes)
    surfFD.TDOld.allocate(numNodes)
    surfFD.TDreport.allocate(numNodes)
    surfFD.RH.allocate(numNodes)
    surfFD.RHreport.allocate(numNodes)
    surfFD.EnthOld.allocate(numNodes)
    surfFD.EnthNew.allocate(numNodes)
    surfFD.EnthLast.allocate(numNodes)
    surfFD.QDreport.allocate(numNodes)
    surfFD.CpDelXRhoS1.allocate(numNodes)
    surfFD.CpDelXRhoS2.allocate(numNodes)
    surfFD.TDpriortimestep.allocate(numNodes)
    surfFD.PhaseChangeState.allocate(numNodes)
    surfFD.PhaseChangeStateOld.allocate(numNodes)
    surfFD.PhaseChangeStateOldOld.allocate(numNodes)
    surfFD.PhaseChangeStateRep.allocate(numNodes)
    surfFD.PhaseChangeStateOldRep.allocate(numNodes)
    surfFD.PhaseChangeStateOldOldRep.allocate(numNodes)
    surfFD.PhaseChangeTemperatureReverse.allocate(numNodes)
    surfFD.condMaterialActuators.allocate(TotLayers)
    surfFD.specHeatMaterialActuators.allocate(TotLayers)
    surfFD.condNodeReport.allocate(numNodes)
    surfFD.specHeatNodeReport.allocate(numNodes)
    surfFD.heatSourceFluxMaterialActuators.allocate(1)
    surfFD.heatSourceInternalFluxLayerReport.allocate(1)
    surfFD.heatSourceInternalFluxEnergyLayerReport.allocate(1)
    surfFD.heatSourceEMSFluxLayerReport.allocate(1)
    surfFD.heatSourceEMSFluxEnergyLayerReport.allocate(1)
    surfFD.T = 20.0
    surfFD.TOld = 20.0
    surfFD.TT = 20.0
    surfFD.Rhov = 0.0
    surfFD.RhovOld = 0.0
    surfFD.RhoT = 0.0
    surfFD.TD = 20.0
    surfFD.TDT = 20.0
    surfFD.TDTLast = 20.0
    surfFD.TDOld = 20.0
    surfFD.TDreport = 20.0
    surfFD.RH = 0.0
    surfFD.RHreport = 0.0
    surfFD.EnthOld = 100.0
    surfFD.EnthNew = 100.0
    surfFD.EnthLast = 100.0
    surfFD.QDreport = 0.0
    surfFD.CpDelXRhoS1 = 0.0
    surfFD.CpDelXRhoS2 = 0.0
    surfFD.TDpriortimestep = 20.0
    surfFD.PhaseChangeState = Material.Phase.Transition
    surfFD.PhaseChangeStateOld = Material.Phase.Transition
    surfFD.PhaseChangeStateOldOld = Material.Phase.Transition
    surfFD.PhaseChangeTemperatureReverse = 50.0
    surfFD.condNodeReport = 0.0
    surfFD.specHeatNodeReport = 0.0
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux.allocate(1)
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux.allocate(1)
    state.dataHeatBalSurf.SurfQdotRadOutRepPerArea.allocate(1)
    state.dataHeatBalSurf.SurfQdotRadOutRep.allocate(1)
    state.dataHeatBalSurf.SurfQRadOutReport.allocate(1)
    state.dataHeatBalSurf.SurfOpaqQRadSWOutAbs.allocate(1)
    state.dataHeatBalSurf.SurfQRadSWOutMvIns.allocate(1)
    state.dataHeatBalSurf.SurfOpaqInsFaceCondFlux[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfOpaqOutFaceCondFlux[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQdotRadOutRep[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQRadOutReport[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfOpaqQRadSWOutAbs[1 - 1] = 0.0
    state.dataHeatBalSurf.SurfQRadSWOutMvIns[1 - 1] = 0.0
    state.dataMstBal.TempOutsideAirFD.allocate(1)
    state.dataMstBal.RhoVaporAirOut.allocate(1)
    state.dataMstBal.HConvExtFD.allocate(1)
    state.dataMstBal.HSkyFD.allocate(1)
    state.dataMstBal.HGrndFD.allocate(1)
    state.dataMstBal.HAirFD.allocate(1)
    state.dataMstBal.HSurrFD.allocate(1)
    alias Toa: Float64 = 10.0
    alias Tsky: Float64 = -20.0
    state.dataMstBal.TempOutsideAirFD[1 - 1] = Toa
    state.dataMstBal.RhoVaporAirOut[1 - 1] = 0.005
    state.dataMstBal.HConvExtFD[1 - 1] = 10.0
    state.dataMstBal.HSkyFD[1 - 1] = 5.0
    state.dataMstBal.HGrndFD[1 - 1] = 3.0
    state.dataMstBal.HAirFD[1 - 1] = 1.0
    state.dataMstBal.HSurrFD[1 - 1] = 0.0
    state.dataEnvrn.SkyTemp = Tsky
    state.dataEnvrn.IsRain = False
    state.dataGlobal.TimeStepZoneSec = 600.0
    surf.UseSurfPropertyGndSurfTemp = False
    surf.SurfHasSurroundingSurfProperty = False
    s_hbfd.QHeatOutFlux.allocate(1)
    s_hbfd.QHeatOutFlux[1 - 1] = 0.0
    alias Delt: Int = 600
    alias nodeIdx: Int = 1
    alias Lay: Int = 1
    alias HMovInsul: Float64 = 0.0
    var numNodesArr = numNodes
    var T_arr = Array1D[Float64](numNodesArr, 20.0)
    var TT_arr = Array1D[Float64](numNodesArr, 20.0)
    var Rhov_arr = Array1D[Float64](numNodesArr, 0.0)
    var RhoT_arr = Array1D[Float64](numNodesArr, 0.0)
    var RH_arr = Array1D[Float64](numNodesArr, 0.0)
    var TD_arr = Array1D[Float64](numNodesArr, 20.0)
    var TDT_arr = Array1D[Float64](numNodesArr, 20.0)
    var EnthOld_arr = Array1D[Float64](numNodesArr, 100.0)
    var EnthNew_arr = Array1D[Float64](numNodesArr, 100.0)
    surfFD.enetActuator.isActuated = False
    surfFD.enetActuator.actuatedValue = 0.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_baseline = TDT_arr[nodeIdx - 1]
    var QRad_baseline = state.dataHeatBalSurf.SurfQdotRadOutRepPerArea[1 - 1]
    EXPECT_LT(QRad_baseline, 0.0)
    surfFD.enetActuator.isActuated = True
    surfFD.enetActuator.actuatedValue = 0.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_enet0 = TDT_arr[nodeIdx - 1]
    surfFD.enetActuator.isActuated = True
    surfFD.enetActuator.actuatedValue = -200.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_enetNeg200 = TDT_arr[nodeIdx - 1]
    surfFD.enetActuator.isActuated = True
    surfFD.enetActuator.actuatedValue = 200.0
    TDT_arr = 20.0
    ExteriorBCEqns(state,
                   Delt,
                   nodeIdx,
                   Lay,
                   SurfNum,
                   T_arr,
                   TT_arr,
                   Rhov_arr,
                   RhoT_arr,
                   RH_arr,
                   TD_arr,
                   TDT_arr,
                   EnthOld_arr,
                   EnthNew_arr,
                   TotNodes,
                   HMovInsul)
    var TDT_enetPos200 = TDT_arr[nodeIdx - 1]
    EXPECT_LT(TDT_enetNeg200, TDT_baseline)
    EXPECT_LT(TDT_baseline, TDT_enet0)
    EXPECT_LT(TDT_enet0, TDT_enetPos200)

@register_test_suite("EnergyPlusFixture")
def register_tests():
    register_test(HeatBalFiniteDiffManager_CalcNodeHeatFluxTest)
    register_test(HeatBalFiniteDiffManager_adjustPropertiesForPhaseChange)
    register_test(HeatBalFiniteDiffManager_findAnySurfacesUsingConstructionAndCondFDTest)
    register_test(HeatBalFiniteDiffManager_CheckFDNodeTempLimitsTest)
    register_test(HeatBalFiniteDiffManager_setSizeMaxPropertiesTest)
    register_test(HeatBalFiniteDiffManager_EnetActuatorOverride)
    register_test(HeatBalFiniteDiffManager_EnetActuatorOverride_CrankNicolson)
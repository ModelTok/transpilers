from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Tuple
import math

class TestTypeEnum(IntEnum):
    INVALID = -1
    INLET = 0
    AVERAGE = 1
    OUTLET = 2
    NUM = 3

testTypesUC = ["INLET", "AVERAGE", "OUTLET"]

@dataclass
class ParametersData:
    Name: str = ""
    Area: float = 0.0
    TestMassFlowRate: float = 0.0
    TestType: TestTypeEnum = TestTypeEnum.INLET
    eff0: float = 0.0
    eff1: float = 0.0
    eff2: float = 0.0
    iam1: float = 0.0
    iam2: float = 0.0
    Volume: float = 0.0
    SideHeight: float = 0.0
    ThermalMass: float = 0.0
    ULossSide: float = 0.0
    ULossBottom: float = 0.0
    AspectRatio: float = 0.0
    NumOfCovers: int = 0
    CoverSpacing: float = 0.0
    RefractiveIndex: List[float] = field(default_factory=lambda: [0.0, 0.0])
    ExtCoefTimesThickness: List[float] = field(default_factory=lambda: [0.0, 0.0])
    EmissOfCover: List[float] = field(default_factory=lambda: [0.0, 0.0])
    EmissOfAbsPlate: float = 0.0
    AbsorOfAbsPlate: float = 0.0

    def IAM(self, state, IncidentAngle: float) -> float:
        CutoffAngle = 60.0 * state.Constant_DegToRad
        if abs(IncidentAngle) > CutoffAngle:
            return 0.0
        
        s = (1.0 / math.cos(IncidentAngle)) - 1.0
        IAM_val = 1.0 + self.iam1 * s + self.iam2 * s * s
        IAM_val = max(IAM_val, 0.0)
        
        if IAM_val > 10.0:
            state.ShowSevereError(
                f"IAM Function: SolarCollectorPerformance:FlatPlate = {self.Name}:  "
                f"Incident Angle Modifier is out of bounds due to bad coefficients."
            )
            state.ShowContinueError(f"Coefficient 2 of Incident Angle Modifier = {self.iam1}")
            state.ShowContinueError(f"Coefficient 3 of Incident Angle Modifier = {self.iam2}")
            state.ShowContinueError(f"Calculated Incident Angle Modifier = {IAM_val}")
            state.ShowContinueError("Expected Incident Angle Modifier should be approximately 1.5 or less.")
            state.ShowFatalError("Errors in SolarCollectorPerformance:FlatPlate input.")
        
        return IAM_val

@dataclass
class CollectorData:
    Name: str = ""
    BCType: str = ""
    OSCMName: str = ""
    VentCavIndex: int = 0
    Type: int = -1  # PlantEquipmentType
    plantLoc_loop_index: int = 0
    Init: bool = True
    InitSizing: bool = True
    Parameters: int = 0
    Surface: int = 0
    InletNode: int = 0
    InletTemp: float = 0.0
    OutletNode: int = 0
    OutletTemp: float = 0.0
    MassFlowRate: float = 0.0
    MassFlowRateMax: float = 0.0
    VolFlowRateMax: float = 0.0
    ErrIndex: int = 0
    IterErrIndex: int = 0
    IncidentAngleModifier: float = 0.0
    Efficiency: float = 0.0
    Power: float = 0.0
    HeatGain: float = 0.0
    HeatLoss: float = 0.0
    Energy: float = 0.0
    HeatRate: float = 0.0
    HeatEnergy: float = 0.0
    StoredHeatRate: float = 0.0
    StoredHeatEnergy: float = 0.0
    HeatGainRate: float = 0.0
    SkinHeatLossRate: float = 0.0
    CollHeatLossEnergy: float = 0.0
    TauAlpha: float = 0.0
    UTopLoss: float = 0.0
    TempOfWater: float = 0.0
    TempOfAbsPlate: float = 0.0
    TempOfInnerCover: float = 0.0
    TempOfOuterCover: float = 0.0
    TauAlphaSkyDiffuse: float = 0.0
    TauAlphaGndDiffuse: float = 0.0
    TauAlphaBeam: float = 0.0
    CoversAbsSkyDiffuse: List[float] = field(default_factory=lambda: [0.0, 0.0])
    CoversAbsGndDiffuse: List[float] = field(default_factory=lambda: [0.0, 0.0])
    CoverAbs: List[float] = field(default_factory=lambda: [0.0, 0.0])
    TimeElapsed: float = 0.0
    UbLoss: float = 0.0
    UsLoss: float = 0.0
    AreaRatio: float = 0.0
    RefDiffInnerCover: float = 0.0
    SavedTempOfWater: float = 0.0
    SavedTempOfAbsPlate: float = 0.0
    SavedTempOfInnerCover: float = 0.0
    SavedTempOfOuterCover: float = 0.0
    SavedTempCollectorOSCM: float = 0.0
    Length: float = 0.0
    TiltR2V: float = 0.0
    Tilt: float = 0.0
    CosTilt: float = 0.0
    SinTilt: float = 0.0
    SideArea: float = 0.0
    Area: float = 0.0
    Volume: float = 0.0
    OSCM_ON: bool = False
    InitICS: bool = False
    SetLoopIndexFlag: bool = True
    SetDiffRadFlag: bool = True

def GetSolarCollectorInput(state):
    ErrorsFound = False
    MaxNumbers = 0
    MaxAlphas = 0
    
    CurrentModuleParamObject = "SolarCollectorPerformance:FlatPlate"
    NumOfFlatPlateParam = state.inputProcessor_getNumObjectsFound(CurrentModuleParamObject)
    NumFields, NumAlphas, NumNumbers = state.inputProcessor_getObjectDefMaxArgs(CurrentModuleParamObject)
    MaxNumbers = max(MaxNumbers, NumNumbers)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    
    CurrentModuleObject = "SolarCollector:FlatPlate:Water"
    NumFlatPlateUnits = state.inputProcessor_getNumObjectsFound(CurrentModuleObject)
    NumFields, NumAlphas, NumNumbers = state.inputProcessor_getObjectDefMaxArgs(CurrentModuleObject)
    MaxNumbers = max(MaxNumbers, NumNumbers)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    
    CurrentModuleParamObject = "SolarCollectorPerformance:IntegralCollectorStorage"
    NumOfICSParam = state.inputProcessor_getNumObjectsFound(CurrentModuleParamObject)
    NumFields, NumAlphas, NumNumbers = state.inputProcessor_getObjectDefMaxArgs(CurrentModuleParamObject)
    MaxNumbers = max(MaxNumbers, NumNumbers)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    
    CurrentModuleObject = "SolarCollector:IntegralCollectorStorage"
    NumOfICSUnits = state.inputProcessor_getNumObjectsFound(CurrentModuleObject)
    NumFields, NumAlphas, NumNumbers = state.inputProcessor_getObjectDefMaxArgs(CurrentModuleObject)
    MaxNumbers = max(MaxNumbers, NumNumbers)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    
    state.dataSolarCollectors_NumOfCollectors = NumFlatPlateUnits + NumOfICSUnits
    state.dataSolarCollectors_NumOfParameters = NumOfFlatPlateParam + NumOfICSParam
    
    if state.dataSolarCollectors_NumOfParameters > 0:
        state.dataSolarCollectors_Parameters = [ParametersData() for _ in range(state.dataSolarCollectors_NumOfParameters)]
        
        CurrentModuleParamObject = "SolarCollectorPerformance:FlatPlate"
        for FlatPlateParamNum in range(NumOfFlatPlateParam):
            ParametersNum = FlatPlateParamNum
            cAlphaArgs, rNumericArgs, NumAlphas, NumNumbers, lNumericFieldBlanks = state.inputProcessor_getObjectItem(
                CurrentModuleParamObject, ParametersNum
            )
            
            state.GlobalNames_VerifyUniqueInterObjectName(
                state.dataSolarCollectors_UniqueParametersNames,
                cAlphaArgs[0],
                CurrentModuleParamObject,
                ErrorsFound
            )
            state.dataSolarCollectors_Parameters[ParametersNum].Name = cAlphaArgs[0]
            state.dataSolarCollectors_Parameters[ParametersNum].Area = rNumericArgs[0]
            
            if rNumericArgs[1] > 0.0:
                state.dataSolarCollectors_Parameters[ParametersNum].TestMassFlowRate = (
                    rNumericArgs[1] * state.Psychrometrics_RhoH2O(state.Constant_InitConvTemp)
                )
            else:
                state.ShowSevereError(
                    f"{CurrentModuleParamObject} = {cAlphaArgs[0]}:  flow rate must be greater than zero"
                )
                ErrorsFound = True
            
            key = cAlphaArgs[2]
            try:
                state.dataSolarCollectors_Parameters[ParametersNum].TestType = TestTypeEnum[key]
            except KeyError:
                state.dataSolarCollectors_Parameters[ParametersNum].TestType = TestTypeEnum.INVALID
                state.ShowSevereError(
                    f"{CurrentModuleParamObject} = {cAlphaArgs[0]}: {key} is not supported"
                )
                ErrorsFound = True
            
            state.dataSolarCollectors_Parameters[ParametersNum].eff0 = rNumericArgs[2]
            state.dataSolarCollectors_Parameters[ParametersNum].eff1 = rNumericArgs[3]
            
            if NumNumbers > 4:
                state.dataSolarCollectors_Parameters[ParametersNum].eff2 = rNumericArgs[4]
            else:
                state.dataSolarCollectors_Parameters[ParametersNum].eff2 = 0.0
            
            if NumNumbers > 5:
                state.dataSolarCollectors_Parameters[ParametersNum].iam1 = rNumericArgs[5]
            else:
                state.dataSolarCollectors_Parameters[ParametersNum].iam1 = 0.0
            
            if NumNumbers > 6:
                state.dataSolarCollectors_Parameters[ParametersNum].iam2 = rNumericArgs[6]
            else:
                state.dataSolarCollectors_Parameters[ParametersNum].iam2 = 0.0
        
        if ErrorsFound:
            state.ShowFatalError(f"Errors in {CurrentModuleParamObject} input.")
    
    if state.dataSolarCollectors_NumOfCollectors > 0:
        state.dataSolarCollectors_Collector = [CollectorData() for _ in range(state.dataSolarCollectors_NumOfCollectors)]
        
        CurrentModuleObject = "SolarCollector:FlatPlate:Water"
        for FlatPlateUnitsNum in range(NumFlatPlateUnits):
            CollectorNum = FlatPlateUnitsNum
            cAlphaArgs, rNumericArgs, NumAlphas, NumNumbers, _ = state.inputProcessor_getObjectItem(
                CurrentModuleObject, CollectorNum
            )
            
            state.GlobalNames_VerifyUniqueInterObjectName(
                state.dataSolarCollectors_UniqueCollectorNames,
                cAlphaArgs[0],
                CurrentModuleObject,
                ErrorsFound
            )
            state.dataSolarCollectors_Collector[CollectorNum].Name = cAlphaArgs[0]
            state.dataSolarCollectors_Collector[CollectorNum].Type = 1  # SolarCollectorFlatPlate
            
            ParametersNum = state.Util_FindItemInList(cAlphaArgs[1], state.dataSolarCollectors_Parameters)
            if ParametersNum == -1:
                state.ShowSevereError(
                    f"{CurrentModuleObject} = {cAlphaArgs[0]}: parameters object {cAlphaArgs[1]} not found."
                )
                ErrorsFound = True
            else:
                state.dataSolarCollectors_Collector[CollectorNum].Parameters = ParametersNum
            
            SurfNum = state.Util_FindItemInList(cAlphaArgs[2], state.dataSurface_Surface)
            if SurfNum == -1:
                state.ShowSevereError(
                    f"{CurrentModuleObject} = {cAlphaArgs[0]}: Surface {cAlphaArgs[2]} not found."
                )
                ErrorsFound = True
            else:
                state.dataSolarCollectors_Collector[CollectorNum].Surface = SurfNum
            
            state.dataSolarCollectors_Collector[CollectorNum].InletNode = state.Node_GetOnlySingleNode(
                cAlphaArgs[3], ErrorsFound
            )
            state.dataSolarCollectors_Collector[CollectorNum].OutletNode = state.Node_GetOnlySingleNode(
                cAlphaArgs[4], ErrorsFound
            )
            
            if NumNumbers > 0:
                state.dataSolarCollectors_Collector[CollectorNum].VolFlowRateMax = rNumericArgs[0]
            else:
                state.dataSolarCollectors_Collector[CollectorNum].VolFlowRateMax = 0.0
                state.dataSolarCollectors_Collector[CollectorNum].MassFlowRateMax = 999999.9
        
        CurrentModuleParamObject = "SolarCollectorPerformance:IntegralCollectorStorage"
        for ICSParamNum in range(NumOfICSParam):
            ParametersNum = ICSParamNum + NumOfFlatPlateParam
            cAlphaArgs, rNumericArgs, NumAlphas, NumNumbers, lNumericFieldBlanks = state.inputProcessor_getObjectItem(
                CurrentModuleParamObject, ICSParamNum
            )
            
            state.GlobalNames_VerifyUniqueInterObjectName(
                state.dataSolarCollectors_UniqueParametersNames,
                cAlphaArgs[0],
                CurrentModuleParamObject,
                ErrorsFound
            )
            state.dataSolarCollectors_Parameters[ParametersNum].Name = cAlphaArgs[0]
            state.dataSolarCollectors_Parameters[ParametersNum].Area = rNumericArgs[0]
            
            if rNumericArgs[0] <= 0.0:
                state.ShowSevereError(
                    f"{CurrentModuleParamObject} = {cAlphaArgs[0]}: Illegal Area = {rNumericArgs[0]}"
                )
                ErrorsFound = True
            
            state.dataSolarCollectors_Parameters[ParametersNum].Volume = rNumericArgs[1]
            if rNumericArgs[1] <= 0.0:
                state.ShowSevereError(
                    f"{CurrentModuleParamObject} = {cAlphaArgs[0]}: Illegal Volume = {rNumericArgs[1]}"
                )
                ErrorsFound = True
            
            state.dataSolarCollectors_Parameters[ParametersNum].ULossBottom = rNumericArgs[2]
            state.dataSolarCollectors_Parameters[ParametersNum].ULossSide = rNumericArgs[3]
            state.dataSolarCollectors_Parameters[ParametersNum].AspectRatio = rNumericArgs[4]
            state.dataSolarCollectors_Parameters[ParametersNum].SideHeight = rNumericArgs[5]
            state.dataSolarCollectors_Parameters[ParametersNum].ThermalMass = rNumericArgs[6]
            state.dataSolarCollectors_Parameters[ParametersNum].NumOfCovers = int(rNumericArgs[7])
            state.dataSolarCollectors_Parameters[ParametersNum].CoverSpacing = rNumericArgs[8]
            
            if state.dataSolarCollectors_Parameters[ParametersNum].NumOfCovers == 2:
                state.dataSolarCollectors_Parameters[ParametersNum].RefractiveIndex[0] = rNumericArgs[9]
                state.dataSolarCollectors_Parameters[ParametersNum].ExtCoefTimesThickness[0] = rNumericArgs[10]
                state.dataSolarCollectors_Parameters[ParametersNum].EmissOfCover[0] = rNumericArgs[11]
                
                if not lNumericFieldBlanks[12] or not lNumericFieldBlanks[13] or not lNumericFieldBlanks[14]:
                    state.dataSolarCollectors_Parameters[ParametersNum].RefractiveIndex[1] = rNumericArgs[12]
                    state.dataSolarCollectors_Parameters[ParametersNum].ExtCoefTimesThickness[1] = rNumericArgs[13]
                    state.dataSolarCollectors_Parameters[ParametersNum].EmissOfCover[1] = rNumericArgs[14]
                else:
                    state.ShowSevereError(
                        f"{CurrentModuleParamObject} = {cAlphaArgs[0]}: Illegal input for inner cover optical properties"
                    )
                    ErrorsFound = True
            elif state.dataSolarCollectors_Parameters[ParametersNum].NumOfCovers == 1:
                state.dataSolarCollectors_Parameters[ParametersNum].RefractiveIndex[0] = rNumericArgs[9]
                state.dataSolarCollectors_Parameters[ParametersNum].ExtCoefTimesThickness[0] = rNumericArgs[10]
                state.dataSolarCollectors_Parameters[ParametersNum].EmissOfCover[0] = rNumericArgs[11]
            else:
                state.ShowSevereError(
                    f"{CurrentModuleParamObject} = {cAlphaArgs[0]}: Illegal NumOfCovers = {rNumericArgs[7]}"
                )
                ErrorsFound = True
            
            state.dataSolarCollectors_Parameters[ParametersNum].AbsorOfAbsPlate = rNumericArgs[15]
            state.dataSolarCollectors_Parameters[ParametersNum].EmissOfAbsPlate = rNumericArgs[16]
        
        if ErrorsFound:
            state.ShowFatalError(f"Errors in {CurrentModuleParamObject} input.")
        
        CurrentModuleObject = "SolarCollector:IntegralCollectorStorage"
        for ICSUnitsNum in range(NumOfICSUnits):
            CollectorNum = ICSUnitsNum + NumFlatPlateUnits
            cAlphaArgs, rNumericArgs, NumAlphas, NumNumbers, lNumericFieldBlanks = state.inputProcessor_getObjectItem(
                CurrentModuleObject, ICSUnitsNum
            )
            
            state.GlobalNames_VerifyUniqueInterObjectName(
                state.dataSolarCollectors_UniqueCollectorNames,
                cAlphaArgs[0],
                CurrentModuleObject,
                ErrorsFound
            )
            state.dataSolarCollectors_Collector[CollectorNum].Name = cAlphaArgs[0]
            state.dataSolarCollectors_Collector[CollectorNum].Type = 2  # SolarCollectorICS
            state.dataSolarCollectors_Collector[CollectorNum].InitICS = True
            
            ParametersNum = state.Util_FindItemInList(cAlphaArgs[1], state.dataSolarCollectors_Parameters)
            if ParametersNum == -1:
                state.ShowSevereError(
                    f"{CurrentModuleObject} = {cAlphaArgs[0]}: parameters object {cAlphaArgs[1]} not found."
                )
                ErrorsFound = True
            else:
                state.dataSolarCollectors_Collector[CollectorNum].Parameters = ParametersNum
                
                Perimeter = 2.0 * math.sqrt(state.dataSolarCollectors_Parameters[ParametersNum].Area) * (
                    math.sqrt(state.dataSolarCollectors_Parameters[ParametersNum].AspectRatio) +
                    1.0 / math.sqrt(state.dataSolarCollectors_Parameters[ParametersNum].AspectRatio)
                )
                state.dataSolarCollectors_Collector[CollectorNum].Length = math.sqrt(
                    state.dataSolarCollectors_Parameters[ParametersNum].Area /
                    state.dataSolarCollectors_Parameters[ParametersNum].AspectRatio
                )
                
                state.dataSolarCollectors_Collector[CollectorNum].Area = state.dataSolarCollectors_Parameters[ParametersNum].Area
                state.dataSolarCollectors_Collector[CollectorNum].Volume = state.dataSolarCollectors_Parameters[ParametersNum].Volume
                state.dataSolarCollectors_Collector[CollectorNum].SideArea = (
                    Perimeter * state.dataSolarCollectors_Parameters[ParametersNum].SideHeight
                )
                state.dataSolarCollectors_Collector[CollectorNum].AreaRatio = (
                    state.dataSolarCollectors_Collector[CollectorNum].SideArea /
                    state.dataSolarCollectors_Collector[CollectorNum].Area
                )
            
            SurfNum = state.Util_FindItemInList(cAlphaArgs[2], state.dataSurface_Surface)
            if SurfNum == -1:
                state.ShowSevereError(
                    f"{CurrentModuleObject} = {cAlphaArgs[0]}: Surface {cAlphaArgs[2]} not found."
                )
                ErrorsFound = True
            else:
                state.dataSolarCollectors_Collector[CollectorNum].Surface = SurfNum
            
            state.dataSolarCollectors_Collector[CollectorNum].BCType = cAlphaArgs[3]
            if state.Util_SameString(cAlphaArgs[3], "AmbientAir"):
                state.dataSolarCollectors_Collector[CollectorNum].OSCMName = ""
            elif state.Util_SameString(cAlphaArgs[3], "OtherSideConditionsModel"):
                state.dataSolarCollectors_Collector[CollectorNum].OSCMName = cAlphaArgs[4]
                state.dataSolarCollectors_Collector[CollectorNum].OSCM_ON = True
            else:
                state.ShowSevereError(
                    f"Invalid BCType = {cAlphaArgs[3]} in {CurrentModuleObject} = {cAlphaArgs[0]}"
                )
                ErrorsFound = True
            
            if state.dataSolarCollectors_Collector[CollectorNum].OSCM_ON:
                VentCavIndex = 0
                GetExtVentedCavityIndex(state, SurfNum, VentCavIndex)
                state.dataSolarCollectors_Collector[CollectorNum].VentCavIndex = VentCavIndex
            
            state.dataSolarCollectors_Collector[CollectorNum].InletNode = state.Node_GetOnlySingleNode(
                cAlphaArgs[5], ErrorsFound
            )
            state.dataSolarCollectors_Collector[CollectorNum].OutletNode = state.Node_GetOnlySingleNode(
                cAlphaArgs[6], ErrorsFound
            )
            
            if NumNumbers > 0:
                state.dataSolarCollectors_Collector[CollectorNum].VolFlowRateMax = rNumericArgs[0]
            else:
                state.dataSolarCollectors_Collector[CollectorNum].VolFlowRateMax = 0.0
                state.dataSolarCollectors_Collector[CollectorNum].MassFlowRateMax = 999999.9
        
        if ErrorsFound:
            state.ShowFatalError(f"Errors in {CurrentModuleObject} input.")

def GetExtVentedCavityIndex(state, SurfacePtr: int, VentCavIndex: list) -> None:
    if SurfacePtr == 0:
        state.ShowFatalError("Invalid surface passed to GetExtVentedCavityIndex")
    
    Found = False
    for thisCav in range(state.dataSurface_TotExtVentCav):
        for ThisSurf in range(state.dataHeatBal_ExtVentedCavity[thisCav].NumSurfs):
            if SurfacePtr == state.dataHeatBal_ExtVentedCavity[thisCav].SurfPtrs[ThisSurf]:
                Found = True
                VentCavIndex[0] = thisCav
                break
        if Found:
            break
    
    if not Found:
        state.ShowFatalError(
            f"Did not find surface in Exterior Vented Cavity description in GetExtVentedCavityIndex"
        )

def setupOutputVars(state, collector: CollectorData):
    if collector.Type == 1:  # SolarCollectorFlatPlate
        state.SetupOutputVariable(
            "Solar Collector Incident Angle Modifier",
            collector, "IncidentAngleModifier", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Efficiency",
            collector, "Efficiency", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Heat Transfer Rate",
            collector, "Power", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Heat Gain Rate",
            collector, "HeatGain", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Heat Loss Rate",
            collector, "HeatLoss", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Heat Transfer Energy",
            collector, "Energy", collector.Name
        )
    elif collector.Type == 2:  # SolarCollectorICS
        state.SetupOutputVariable(
            "Solar Collector Transmittance Absorptance Product",
            collector, "TauAlpha", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Overall Top Heat Loss Coefficient",
            collector, "UTopLoss", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Absorber Plate Temperature",
            collector, "TempOfAbsPlate", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Storage Water Temperature",
            collector, "TempOfWater", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Thermal Efficiency",
            collector, "Efficiency", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Storage Heat Transfer Rate",
            collector, "StoredHeatRate", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Storage Heat Transfer Energy",
            collector, "StoredHeatEnergy", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Skin Heat Transfer Rate",
            collector, "SkinHeatLossRate", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Skin Heat Transfer Energy",
            collector, "CollHeatLossEnergy", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Heat Transfer Rate",
            collector, "HeatRate", collector.Name
        )
        state.SetupOutputVariable(
            "Solar Collector Heat Transfer Energy",
            collector, "HeatEnergy", collector.Name
        )

def initialize(state, collector: CollectorData):
    BigNumber = 9999.9
    
    if not state.dataGlobal_SysSizingCalc and collector.InitSizing:
        state.PlantUtilities_RegisterPlantCompDesignFlow(collector.InletNode, collector.VolFlowRateMax)
        collector.InitSizing = False
    
    if state.dataGlobal_BeginEnvrnFlag and collector.Init:
        if collector.VolFlowRateMax > 0:
            rho = state.plantLoc_loop_glycol_getDensity(state.Constant_InitConvTemp)
            collector.MassFlowRateMax = collector.VolFlowRateMax * rho
        else:
            collector.MassFlowRateMax = BigNumber
        
        state.PlantUtilities_InitComponentNodes(0.0, collector.MassFlowRateMax, collector.InletNode, collector.OutletNode)
        collector.Init = False
        
        if collector.InitICS:
            collector.TempOfWater = 20.0
            collector.SavedTempOfWater = collector.TempOfWater
            collector.SavedTempOfAbsPlate = collector.TempOfWater
            collector.TempOfAbsPlate = collector.TempOfWater
            collector.TempOfInnerCover = collector.TempOfWater
            collector.TempOfOuterCover = collector.TempOfWater
            collector.SavedTempOfInnerCover = collector.TempOfWater
            collector.SavedTempOfOuterCover = collector.TempOfWater
            collector.SavedTempCollectorOSCM = collector.TempOfWater
    
    if not state.dataGlobal_BeginEnvrnFlag:
        collector.Init = True
    
    if collector.SetDiffRadFlag and collector.InitICS:
        SurfNum = collector.Surface
        ParamNum = collector.Parameters
        
        collector.Tilt = state.dataSurface_Surface[SurfNum].Tilt
        collector.TiltR2V = abs(90.0 - collector.Tilt)
        collector.CosTilt = math.cos(collector.Tilt * state.Constant_DegToRad)
        collector.SinTilt = math.sin(1.8 * collector.Tilt * state.Constant_DegToRad)
        
        Theta = 60.0 * state.Constant_DegToRad
        TransSys, RefSys, AbsCover1, AbsCover2, RefSysDiffuse = CalcTransRefAbsOfCover(
            state, collector, Theta, True
        )
        collector.RefDiffInnerCover = RefSysDiffuse
        
        Theta = 0.0
        TransSys, RefSys, AbsCover1, AbsCover2, _ = CalcTransRefAbsOfCover(
            state, collector, Theta, False
        )
        
        Theta = (59.68 - 0.1388 * collector.Tilt + 0.001497 * collector.Tilt * collector.Tilt) * state.Constant_DegToRad
        TransSys, RefSys, AbsCover1, AbsCover2, _ = CalcTransRefAbsOfCover(
            state, collector, Theta, False
        )
        collector.TauAlphaSkyDiffuse = (
            TransSys * state.dataSolarCollectors_Parameters[ParamNum].AbsorOfAbsPlate /
            (1.0 - (1.0 - state.dataSolarCollectors_Parameters[ParamNum].AbsorOfAbsPlate) * collector.RefDiffInnerCover)
        )
        collector.CoversAbsSkyDiffuse[0] = AbsCover1
        collector.CoversAbsSkyDiffuse[1] = AbsCover2
        
        Theta = (90.0 - 0.5788 * collector.Tilt + 0.002693 * collector.Tilt * collector.Tilt) * state.Constant_DegToRad
        TransSys, RefSys, AbsCover1, AbsCover2, _ = CalcTransRefAbsOfCover(
            state, collector, Theta, False
        )
        collector.TauAlphaGndDiffuse = (
            TransSys * state.dataSolarCollectors_Parameters[ParamNum].AbsorOfAbsPlate /
            (1.0 - (1.0 - state.dataSolarCollectors_Parameters[ParamNum].AbsorOfAbsPlate) * collector.RefDiffInnerCover)
        )
        collector.CoversAbsGndDiffuse[0] = AbsCover1
        collector.CoversAbsGndDiffuse[1] = AbsCover2
        
        collector.SetDiffRadFlag = False
    
    collector.InletTemp = state.dataLoopNodes_Node[collector.InletNode].Temp
    collector.MassFlowRate = collector.MassFlowRateMax
    
    state.PlantUtilities_SetComponentFlowRate(
        collector.MassFlowRate, collector.InletNode, collector.OutletNode
    )
    
    if collector.InitICS:
        timeElapsed = (
            state.dataGlobal_HourOfDay + state.dataGlobal_TimeStep * state.dataGlobal_TimeStepZone +
            state.dataHVACGlobal_SysTimeElapsed
        )
        
        if collector.TimeElapsed != timeElapsed:
            collector.SavedTempOfWater = collector.TempOfWater
            collector.SavedTempOfAbsPlate = collector.TempOfAbsPlate
            collector.SavedTempOfInnerCover = collector.TempOfInnerCover
            collector.SavedTempOfOuterCover = collector.TempOfOuterCover
            if collector.OSCM_ON:
                collector.SavedTempCollectorOSCM = state.dataHeatBal_ExtVentedCavity[collector.VentCavIndex].Tbaffle
            collector.TimeElapsed = timeElapsed

def simulate(state, collector: CollectorData):
    initialize(state, collector)
    
    if collector.Type == 1:  # SolarCollectorFlatPlate
        CalcSolarCollector(state, collector)
    elif collector.Type == 2:  # SolarCollectorICS
        CalcICSSolarCollector(state, collector)
    
    update(state, collector)
    report(state, collector)

def CalcSolarCollector(state, collector: CollectorData):
    efficiency = 0.0
    
    SurfNum = collector.Surface
    ParamNum = collector.Parameters
    
    if state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] > 0.0:
        ThetaBeam = math.acos(state.dataHeatBal_SurfCosIncidenceAngle[SurfNum])
        tilt = state.dataSurface_Surface[SurfNum].Tilt
        
        ThetaSky = (59.68 - 0.1388 * tilt + 0.001497 * tilt * tilt) * state.Constant_DegToRad
        ThetaGnd = (90.0 - 0.5788 * tilt + 0.002693 * tilt * tilt) * state.Constant_DegToRad
        
        incidentAngleModifier = (
            (state.dataHeatBal_SurfQRadSWOutIncidentBeam[SurfNum] * state.dataSolarCollectors_Parameters[ParamNum].IAM(state, ThetaBeam) +
             state.dataHeatBal_SurfQRadSWOutIncidentSkyDiffuse[SurfNum] * state.dataSolarCollectors_Parameters[ParamNum].IAM(state, ThetaSky) +
             state.dataHeatBal_SurfQRadSWOutIncidentGndDiffuse[SurfNum] * state.dataSolarCollectors_Parameters[ParamNum].IAM(state, ThetaGnd)) /
            state.dataHeatBal_SurfQRadSWOutIncident[SurfNum]
        )
    else:
        incidentAngleModifier = 0.0
    
    inletTemp = collector.InletTemp
    massFlowRate = collector.MassFlowRate
    Cp = state.plantLoc_loop_glycol_getSpecificHeat(state, inletTemp)
    area = state.dataSurface_Surface[SurfNum].Area
    
    mCpA = massFlowRate * Cp / area
    mCpATest = (
        state.dataSolarCollectors_Parameters[ParamNum].TestMassFlowRate * Cp /
        state.dataSolarCollectors_Parameters[ParamNum].Area
    )
    
    Iteration = 1
    outletTemp = 0.0
    OutletTempPrev = 999.9
    Q = 0.0
    
    while abs(outletTemp - OutletTempPrev) > state.dataHeatBal_TempConvergTol:
        OutletTempPrev = outletTemp
        
        TestTypeMod = 0.0
        FRULpTest = 0.0
        
        if state.dataSolarCollectors_Parameters[ParamNum].TestType == TestTypeEnum.INLET:
            FRULpTest = (
                state.dataSolarCollectors_Parameters[ParamNum].eff1 +
                state.dataSolarCollectors_Parameters[ParamNum].eff2 * (inletTemp - state.dataSurface_SurfOutDryBulbTemp[SurfNum])
            )
            TestTypeMod = 1.0
        elif state.dataSolarCollectors_Parameters[ParamNum].TestType == TestTypeEnum.AVERAGE:
            FRULpTest = (
                state.dataSolarCollectors_Parameters[ParamNum].eff1 +
                state.dataSolarCollectors_Parameters[ParamNum].eff2 *
                ((inletTemp + outletTemp) * 0.5 - state.dataSurface_SurfOutDryBulbTemp[SurfNum])
            )
            TestTypeMod = 1.0 / (1.0 - FRULpTest / (2.0 * mCpATest))
        elif state.dataSolarCollectors_Parameters[ParamNum].TestType == TestTypeEnum.OUTLET:
            FRULpTest = (
                state.dataSolarCollectors_Parameters[ParamNum].eff1 +
                state.dataSolarCollectors_Parameters[ParamNum].eff2 * (outletTemp - state.dataSurface_SurfOutDryBulbTemp[SurfNum])
            )
            TestTypeMod = 1.0 / (1.0 - FRULpTest / mCpATest)
        
        FRTAN = state.dataSolarCollectors_Parameters[ParamNum].eff0 * TestTypeMod
        FRUL = state.dataSolarCollectors_Parameters[ParamNum].eff1 * TestTypeMod
        FRULT = state.dataSolarCollectors_Parameters[ParamNum].eff2 * TestTypeMod
        FRULpTest *= TestTypeMod
        
        if massFlowRate > 0.0:
            FlowMod = 0.0
            
            if (1.0 + FRULpTest / mCpATest) > 0.0:
                FpULTest = -mCpATest * math.log(1.0 + FRULpTest / mCpATest)
            else:
                FpULTest = FRULpTest
            
            if (-FpULTest / mCpA) < 700.0:
                FlowMod = mCpA * (1.0 - math.exp(-FpULTest / mCpA))
            
            if (-FpULTest / mCpATest) < 700.0:
                FlowMod /= (mCpATest * (1.0 - math.exp(-FpULTest / mCpATest)))
            
            Q = (
                (FRTAN * incidentAngleModifier * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] +
                 FRULpTest * (inletTemp - state.dataSurface_SurfOutDryBulbTemp[SurfNum])) *
                area * FlowMod
            )
            
            outletTemp = inletTemp + Q / (massFlowRate * Cp)
            
            if outletTemp < -100:
                outletTemp = -100.0
                Q = massFlowRate * Cp * (outletTemp - inletTemp)
            if outletTemp > 200:
                outletTemp = 200.0
                Q = massFlowRate * Cp * (outletTemp - inletTemp)
            
            if state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] > 0.0:
                efficiency = Q / (state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] * area)
            else:
                efficiency = 0.0
        else:
            Q = 0.0
            efficiency = 0.0
            
            A = -FRULT
            B = -FRUL + 2.0 * FRULT * state.dataSurface_SurfOutDryBulbTemp[SurfNum]
            C = (
                -FRULT * state.dataSurface_SurfOutDryBulbTemp[SurfNum] * state.dataSurface_SurfOutDryBulbTemp[SurfNum] +
                FRUL * state.dataSurface_SurfOutDryBulbTemp[SurfNum] -
                FRTAN * incidentAngleModifier * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum]
            )
            qEquation = B * B - 4.0 * A * C
            
            if qEquation < 0.0:
                if collector.ErrIndex == 0:
                    state.ShowSevereMessage(
                        f"CalcSolarCollector: {collector.Name}, possible bad input coefficients."
                    )
                    state.ShowContinueError(
                        "...coefficients cause negative quadratic equation part in calculating temperature of stagnant fluid."
                    )
                    state.ShowContinueError("...examine input coefficients for accuracy. Calculation will be treated as linear.")
                state.ShowRecurringSevereErrorAtEnd(
                    f"CalcSolarCollector: {collector.Name}, coefficient error continues.",
                    collector.ErrIndex, qEquation, qEquation
                )
            
            if FRULT == 0.0 or qEquation < 0.0:
                outletTemp = (
                    state.dataSurface_SurfOutDryBulbTemp[SurfNum] -
                    FRTAN * incidentAngleModifier * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] / FRUL
                )
            else:
                outletTemp = (-B + math.sqrt(qEquation)) / (2.0 * A)
        
        if state.dataSolarCollectors_Parameters[ParamNum].TestType == TestTypeEnum.INLET:
            break
        
        if Iteration > 100:
            if collector.IterErrIndex == 0:
                state.ShowWarningMessage(
                    f"CalcSolarCollector: {collector.Name}: Solution did not converge."
                )
            state.ShowRecurringWarningErrorAtEnd(
                f"CalcSolarCollector: {collector.Name}, solution not converge error continues.",
                collector.IterErrIndex
            )
            break
        
        Iteration += 1
    
    collector.IncidentAngleModifier = incidentAngleModifier
    collector.Power = Q
    collector.HeatGain = max(Q, 0.0)
    collector.HeatLoss = min(Q, 0.0)
    collector.OutletTemp = outletTemp
    collector.Efficiency = efficiency

def CalcTransRefAbsOfCover(state, collector: CollectorData, IncidentAngle: float, DiffRefFlag: bool = False) -> Tuple:
    ParamNum = collector.Parameters
    
    TransPerp = [1.0, 1.0]
    TransPara = [1.0, 1.0]
    ReflPerp = [0.0, 0.0]
    ReflPara = [0.0, 0.0]
    AbsorPerp = [0.0, 0.0]
    AbsorPara = [0.0, 0.0]
    TransAbsOnly = [1.0, 1.0]
    
    AirRefIndex = 1.0003
    sin_IncAngle = math.sin(IncidentAngle)
    
    for nCover in range(state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers):
        CoverRefrIndex = state.dataSolarCollectors_Parameters[ParamNum].RefractiveIndex[nCover]
        RefrAngle = math.asin(sin_IncAngle * AirRefIndex / CoverRefrIndex)
        
        TransAbsOnly[nCover] = math.exp(
            -state.dataSolarCollectors_Parameters[ParamNum].ExtCoefTimesThickness[nCover] / math.cos(RefrAngle)
        )
        
        if IncidentAngle == 0.0:
            ParaRad = pow(
                (CoverRefrIndex - AirRefIndex) / (CoverRefrIndex + AirRefIndex), 2
            )
            PerpRad = pow(
                (CoverRefrIndex - AirRefIndex) / (CoverRefrIndex + AirRefIndex), 2
            )
        else:
            ParaRad = pow(
                math.tan(RefrAngle - IncidentAngle) / math.tan(RefrAngle + IncidentAngle), 2
            )
            PerpRad = pow(
                math.sin(RefrAngle - IncidentAngle) / math.sin(RefrAngle + IncidentAngle), 2
            )
        
        TransPerp[nCover] = (
            TransAbsOnly[nCover] * ((1.0 - PerpRad) / (1.0 + PerpRad)) *
            ((1.0 - PerpRad * PerpRad) / (1.0 - PerpRad * PerpRad * TransAbsOnly[nCover] * TransAbsOnly[nCover]))
        )
        TransPara[nCover] = (
            TransAbsOnly[nCover] * ((1.0 - ParaRad) / (1.0 + ParaRad)) *
            ((1.0 - ParaRad * ParaRad) / (1.0 - ParaRad * ParaRad * TransAbsOnly[nCover] * TransAbsOnly[nCover]))
        )
        
        ReflPerp[nCover] = (
            PerpRad + (pow(1.0 - PerpRad, 2) * pow(TransAbsOnly[nCover], 2) * PerpRad) /
            (1.0 - pow(PerpRad * TransAbsOnly[nCover], 2))
        )
        ReflPara[nCover] = (
            ParaRad + (pow(1.0 - ParaRad, 2) * pow(TransAbsOnly[nCover], 2) * ParaRad) /
            (1.0 - pow(ParaRad * TransAbsOnly[nCover], 2))
        )
        
        AbsorPerp[nCover] = 1.0 - TransPerp[nCover] - ReflPerp[nCover]
        AbsorPara[nCover] = 1.0 - TransPara[nCover] - ReflPara[nCover]
    
    AbsCover1 = 0.5 * (AbsorPerp[0] + AbsorPara[0])
    AbsCover2 = 0.0
    if state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers == 2:
        AbsCover2 = 0.5 * (AbsorPerp[1] + AbsorPara[1])
    
    TransSys = 0.5 * (
        TransPerp[0] * TransPerp[1] / (1.0 - ReflPerp[0] * ReflPerp[1]) +
        TransPara[0] * TransPara[1] / (1.0 - ReflPara[0] * ReflPara[1])
    ) if state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers == 2 else TransPerp[0]
    
    ReflSys = 0.5 * (
        ReflPerp[0] + TransSys * ReflPerp[1] * TransPerp[0] / TransPerp[1] +
        ReflPara[0] + TransSys * ReflPara[1] * TransPara[0] / TransPara[1]
    ) if state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers == 2 else ReflPerp[0]
    
    RefSysDiffuse = 0.0
    if DiffRefFlag:
        TransSysDiff = 0.5 * (
            TransPerp[1] * TransPerp[0] / (1.0 - ReflPerp[1] * ReflPerp[0]) +
            TransPara[1] * TransPara[0] / (1.0 - ReflPara[1] * ReflPara[0])
        ) if state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers == 2 else TransPerp[0]
        
        RefSysDiffuse = 0.5 * (
            ReflPerp[1] + TransSysDiff * ReflPerp[0] * TransPerp[1] / TransPerp[0] +
            ReflPara[1] + TransSysDiff * ReflPara[0] * TransPara[1] / TransPara[0]
        ) if state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers == 2 else ReflPerp[0]
    
    return TransSys, ReflSys, AbsCover1, AbsCover2, RefSysDiffuse

def CalcICSSolarCollector(state, collector: CollectorData):
    SurfNum = collector.Surface
    ParamNum = collector.Parameters
    SecInTimeStep = state.dataHVACGlobal_TimeStepSysSec
    TempWater = collector.SavedTempOfWater
    TempAbsPlate = collector.SavedTempOfAbsPlate
    TempOutdoorAir = state.dataSurface_SurfOutDryBulbTemp[SurfNum]
    
    if collector.OSCM_ON:
        TempOSCM = collector.SavedTempCollectorOSCM
    else:
        TempOSCM = TempOutdoorAir
    
    ThetaBeam = math.acos(state.dataHeatBal_SurfCosIncidenceAngle[SurfNum])
    CalcTransAbsorProduct(state, collector, ThetaBeam)
    
    inletTemp = collector.InletTemp
    massFlowRate = collector.MassFlowRate
    Cpw = state.plantLoc_loop_glycol_getSpecificHeat(state, inletTemp)
    Rhow = state.plantLoc_loop_glycol_getDensity(state, inletTemp)
    
    CalcHeatTransCoeffAndCoverTemp(state, collector)
    
    hConvCoefA2W = CalcConvCoeffAbsPlateAndWater(state, TempAbsPlate, TempWater, collector.Length, collector.TiltR2V)
    TempWaterOld = TempWater
    TempAbsPlateOld = TempAbsPlate
    
    area = state.dataSolarCollectors_Parameters[ParamNum].Area
    
    if state.dataSolarCollectors_Parameters[ParamNum].ThermalMass > 0.0:
        AbsPlateMassFlag = True
        ap = state.dataSolarCollectors_Parameters[ParamNum].ThermalMass * area
        a1 = -area * (hConvCoefA2W + collector.UTopLoss) / ap
        a2 = area * hConvCoefA2W / ap
        a3 = area * (
            collector.TauAlpha * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] +
            collector.UTopLoss * TempOutdoorAir
        ) / ap
    else:
        AbsPlateMassFlag = False
        a1 = -area * (hConvCoefA2W + collector.UTopLoss)
        a2 = area * hConvCoefA2W
        a3 = area * (
            collector.TauAlpha * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] +
            collector.UTopLoss * TempOutdoorAir
        )
    
    aw = state.dataSolarCollectors_Parameters[ParamNum].Volume * Rhow * Cpw
    b1 = area * hConvCoefA2W / aw
    b2 = -(area * (hConvCoefA2W + collector.UbLoss + collector.UsLoss) + massFlowRate * Cpw) / aw
    b3 = (
        area * (collector.UbLoss * TempOSCM + collector.UsLoss * TempOutdoorAir) +
        massFlowRate * Cpw * inletTemp
    ) / aw
    
    TempAbsPlate, TempWater = ICSCollectorAnalyticalSolution(
        state, SecInTimeStep, a1, a2, a3, b1, b2, b3,
        TempAbsPlateOld, TempWaterOld, AbsPlateMassFlag
    )
    
    collector.SkinHeatLossRate = area * (
        collector.UTopLoss * (TempOutdoorAir - TempAbsPlate) +
        collector.UsLoss * (TempOutdoorAir - TempWater) +
        collector.UbLoss * (TempOSCM - TempWater)
    )
    collector.StoredHeatRate = aw * (TempWater - TempWaterOld) / SecInTimeStep
    
    QHeatRate = massFlowRate * Cpw * (TempWater - inletTemp)
    collector.HeatRate = QHeatRate
    collector.HeatGainRate = max(0.0, QHeatRate)
    
    outletTemp = TempWater
    collector.OutletTemp = outletTemp
    collector.TempOfWater = TempWater
    collector.TempOfAbsPlate = TempAbsPlate
    
    efficiency = 0.0
    if state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] > 0.0:
        efficiency = (
            (collector.HeatGainRate + collector.StoredHeatRate) /
            (state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] * area)
        )
        if efficiency < 0.0:
            efficiency = 0.0
    collector.Efficiency = efficiency

def ICSCollectorAnalyticalSolution(state, SecInTimeStep: float, a1: float, a2: float, a3: float,
                                    b1: float, b2: float, b3: float,
                                    TempAbsPlateOld: float, TempWaterOld: float,
                                    AbsorberPlateHasMass: bool) -> Tuple[float, float]:
    if AbsorberPlateHasMass:
        a = 1.0
        b = -(a1 + b2)
        c = a1 * b2 - a2 * b1
        BSquareM4TimesATimesC = b * b - 4.0 * a * c
        
        if BSquareM4TimesATimesC > 0.0:
            lamda1 = (-b + math.sqrt(BSquareM4TimesATimesC)) / (2.0 * a)
            lamda2 = (-b - math.sqrt(BSquareM4TimesATimesC)) / (2.0 * a)
            
            ConstOfTpSln = (-a3 * b2 + b3 * a2) / c
            ConstOfTwSln = (-a1 * b3 + b1 * a3) / c
            
            r1 = (lamda1 - a1) / a2
            r2 = (lamda2 - a1) / a2
            
            ConstantC2 = (TempWaterOld + r1 * ConstOfTpSln - r1 * TempAbsPlateOld - ConstOfTwSln) / (r2 - r1)
            ConstantC1 = (TempAbsPlateOld - ConstOfTpSln - ConstantC2)
            
            TempAbsPlate = (
                ConstantC1 * math.exp(lamda1 * SecInTimeStep) +
                ConstantC2 * math.exp(lamda2 * SecInTimeStep) + ConstOfTpSln
            )
            TempWater = (
                r1 * ConstantC1 * math.exp(lamda1 * SecInTimeStep) +
                r2 * ConstantC2 * math.exp(lamda2 * SecInTimeStep) + ConstOfTwSln
            )
        else:
            state.ShowSevereError(
                "ICSCollectorAnalyticalSolution: Unanticipated differential equation coefficient"
            )
            state.ShowFatalError("Program terminates due to above conditions.")
    else:
        b = b2 - b1 * (a2 / a1)
        c = b3 - b1 * (a3 / a1)
        TempWater = (TempWaterOld + c / b) * math.exp(b * SecInTimeStep) - c / b
        TempAbsPlate = -(a2 * TempWater + a3) / a1
    
    return TempAbsPlate, TempWater

def CalcTransAbsorProduct(state, collector: CollectorData, IncidAngle: float):
    SurfNum = collector.Surface
    ParamNum = collector.Parameters
    
    collector.CoverAbs[0] = 0.0
    collector.CoverAbs[1] = 0.0
    
    if state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] > 0.0:
        TransSys, ReflSys, AbsCover1, AbsCover2, _ = CalcTransRefAbsOfCover(
            state, collector, IncidAngle, False
        )
        
        TuaAlphaBeam = (
            TransSys * state.dataSolarCollectors_Parameters[ParamNum].AbsorOfAbsPlate /
            (1.0 - (1.0 - state.dataSolarCollectors_Parameters[ParamNum].AbsorOfAbsPlate) * collector.RefDiffInnerCover)
        )
        
        collector.TauAlphaBeam = max(0.0, TuaAlphaBeam)
        
        CoversAbsBeam = [AbsCover1, AbsCover2]
        
        TuaAlpha = (
            (state.dataHeatBal_SurfQRadSWOutIncidentBeam[SurfNum] * collector.TauAlphaBeam +
             state.dataHeatBal_SurfQRadSWOutIncidentSkyDiffuse[SurfNum] * collector.TauAlphaSkyDiffuse +
             state.dataHeatBal_SurfQRadSWOutIncidentGndDiffuse[SurfNum] * collector.TauAlphaGndDiffuse) /
            state.dataHeatBal_SurfQRadSWOutIncident[SurfNum]
        )
        
        if state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers == 1:
            collector.CoverAbs[0] = (
                (state.dataHeatBal_SurfQRadSWOutIncidentBeam[SurfNum] * CoversAbsBeam[0] +
                 state.dataHeatBal_SurfQRadSWOutIncidentSkyDiffuse[SurfNum] * collector.CoversAbsSkyDiffuse[0] +
                 state.dataHeatBal_SurfQRadSWOutIncidentGndDiffuse[SurfNum] * collector.CoversAbsGndDiffuse[0]) /
                state.dataHeatBal_SurfQRadSWOutIncident[SurfNum]
            )
        elif state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers == 2:
            for Num in range(state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers):
                collector.CoverAbs[Num] = (
                    (state.dataHeatBal_SurfQRadSWOutIncidentBeam[SurfNum] * CoversAbsBeam[Num] +
                     state.dataHeatBal_SurfQRadSWOutIncidentSkyDiffuse[SurfNum] * collector.CoversAbsSkyDiffuse[Num] +
                     state.dataHeatBal_SurfQRadSWOutIncidentGndDiffuse[SurfNum] * collector.CoversAbsGndDiffuse[Num]) /
                    state.dataHeatBal_SurfQRadSWOutIncident[SurfNum]
                )
    else:
        TuaAlpha = 0.0
    
    collector.TauAlpha = TuaAlpha

def CalcConvCoeffBetweenPlates(TempSurf1: float, TempSurf2: float, AirGap: float, CosTilt: float, SinTilt: float) -> float:
    gravity = 9.806
    
    Temps = [-23.15, 6.85, 16.85, 24.85, 26.85, 36.85, 46.85, 56.85, 66.85, 76.85, 126.85]
    Mu = [0.0000161, 0.0000175, 0.000018, 0.0000184, 0.0000185, 0.000019, 0.0000194, 0.0000199, 0.0000203, 0.0000208, 0.0000229]
    Conductivity = [0.0223, 0.0246, 0.0253, 0.0259, 0.0261, 0.0268, 0.0275, 0.0283, 0.0290, 0.0297, 0.0331]
    Pr = [0.724, 0.717, 0.714, 0.712, 0.712, 0.711, 0.71, 0.708, 0.707, 0.706, 0.703]
    Density = [1.413, 1.271, 1.224, 1.186, 1.177, 1.143, 1.110, 1.076, 1.043, 1.009, 0.883]
    
    DeltaT = abs(TempSurf1 - TempSurf2)
    Tref = 0.5 * (TempSurf1 + TempSurf2)
    
    Index = 0
    while Index < len(Temps):
        if Tref < Temps[Index]:
            break
        Index += 1
    
    if Index == 0:
        VisDOfAir = Mu[0]
        CondOfAir = Conductivity[0]
        PrOfAir = Pr[0]
        DensOfAir = Density[0]
    elif Index >= len(Temps):
        Index = len(Temps) - 1
        VisDOfAir = Mu[Index]
        CondOfAir = Conductivity[Index]
        PrOfAir = Pr[Index]
        DensOfAir = Density[Index]
    else:
        InterpFrac = (Tref - Temps[Index - 1]) / (Temps[Index] - Temps[Index - 1])
        VisDOfAir = Mu[Index - 1] + InterpFrac * (Mu[Index] - Mu[Index - 1])
        CondOfAir = Conductivity[Index - 1] + InterpFrac * (Conductivity[Index] - Conductivity[Index - 1])
        PrOfAir = Pr[Index - 1] + InterpFrac * (Pr[Index] - Pr[Index - 1])
        DensOfAir = Density[Index - 1] + InterpFrac * (Density[Index] - Density[Index - 1])
    
    Kelvin = 273.15
    VolExpAir = 1.0 / (Tref + Kelvin)
    
    RaNum = gravity * DensOfAir * DensOfAir * VolExpAir * PrOfAir * DeltaT * (AirGap ** 3) / (VisDOfAir ** 2)
    RaNumCosTilt = RaNum * CosTilt
    
    if RaNum == 0.0:
        NuL = 0.0
    else:
        if RaNumCosTilt > 1708.0:
            NuL = 1.44 * (1.0 - 1708.0 * (SinTilt ** 1.6) / (RaNum * CosTilt)) * (1.0 - 1708.0 / RaNumCosTilt)
        else:
            NuL = 0.0
    
    if RaNumCosTilt > 5830.0:
        NuL += pow(RaNumCosTilt / 5830.0 - 1.0, 1.0 / 3.0)
    
    NuL += 1.0
    hConvCoef = NuL * CondOfAir / AirGap
    
    return hConvCoef

def CalcConvCoeffAbsPlateAndWater(state, TAbsorber: float, TWater: float, Lc: float, TiltR2V: float) -> float:
    gravity = 9.806
    
    DeltaT = abs(TAbsorber - TWater)
    TReference = TAbsorber - 0.25 * (TAbsorber - TWater)
    
    water = state.Fluid_GetWater()
    WaterSpecHeat = water.getSpecificHeat(state, max(TReference, 0.0))
    CondOfWater = water.getConductivity(state, max(TReference, 0.0))
    VisOfWater = water.getViscosity(state, max(TReference, 0.0))
    DensOfWater = water.getDensity(state, max(TReference, 0.0))
    PrOfWater = VisOfWater * WaterSpecHeat / CondOfWater
    
    TReference = TWater - 0.25 * (TWater - TAbsorber)
    VolExpWater = -(
        water.getDensity(state, max(TReference, 10.0) + 5.0) -
        water.getDensity(state, max(TReference, 10.0) - 5.0)
    ) / (10.0 * DensOfWater)
    
    GrNum = gravity * VolExpWater * DensOfWater * DensOfWater * PrOfWater * DeltaT * (Lc ** 3) / (VisOfWater ** 2)
    CosTilt = math.cos(TiltR2V * state.Constant_DegToRad)
    
    if TAbsorber > TWater:
        if abs(TiltR2V - 90.0) < 1.0:
            RaNum = GrNum * PrOfWater
            if RaNum <= 1708.0:
                NuL = 1.0
            else:
                NuL = 0.58 * pow(RaNum, 0.20)
        else:
            RaNum = GrNum * PrOfWater * CosTilt
            if RaNum <= 1708.0:
                NuL = 1.0
            else:
                NuL = 0.56 * pow(RaNum, 0.25)
    else:
        RaNum = GrNum * PrOfWater
        if RaNum > 5.0e8:
            NuL = 0.13 * pow(RaNum, 1.0 / 3.0)
        else:
            NuL = 0.16 * pow(RaNum, 1.0 / 3.0)
            if RaNum <= 1708.0:
                NuL = 1.0
    
    hConvA2W = NuL * CondOfWater / Lc
    
    return hConvA2W

def CalcHeatTransCoeffAndCoverTemp(state, collector: CollectorData):
    tempnom = 0.0
    tempdenom = 0.0
    hRadCoefC2Sky = 0.0
    hRadCoefC2Gnd = 0.0
    hConvCoefA2C = 0.0
    hConvCoefC2C = 0.0
    hConvCoefC2O = 0.0
    hRadCoefA2C = 0.0
    hRadCoefC2C = 0.0
    hRadCoefC2O = 0.0
    
    ParamNum = collector.Parameters
    NumCovers = state.dataSolarCollectors_Parameters[ParamNum].NumOfCovers
    SurfNum = collector.Surface
    
    TempAbsPlate = collector.SavedTempOfAbsPlate
    TempInnerCover = collector.SavedTempOfInnerCover
    TempOuterCover = collector.SavedTempOfOuterCover
    TempOutdoorAir = state.dataSurface_SurfOutDryBulbTemp[SurfNum]
    
    EmissOfAbsPlate = state.dataSolarCollectors_Parameters[ParamNum].EmissOfAbsPlate
    EmissOfOuterCover = state.dataSolarCollectors_Parameters[ParamNum].EmissOfCover[0]
    EmissOfInnerCover = state.dataSolarCollectors_Parameters[ParamNum].EmissOfCover[1] if NumCovers == 2 else 0.0
    AirGapDepth = state.dataSolarCollectors_Parameters[ParamNum].CoverSpacing
    
    Kelvin = 273.15
    StefanBoltzmann = 5.670374419e-8
    
    if NumCovers == 1:
        tempnom = (
            StefanBoltzmann * ((TempAbsPlate + Kelvin) + (TempOuterCover + Kelvin)) *
            ((TempAbsPlate + Kelvin) ** 2 + (TempOuterCover + Kelvin) ** 2)
        )
        tempdenom = 1.0 / EmissOfAbsPlate + 1.0 / EmissOfOuterCover - 1.0
        hRadCoefA2C = tempnom / tempdenom
        hRadCoefC2C = 0.0
        hConvCoefC2C = 0.0
        hConvCoefA2C = CalcConvCoeffBetweenPlates(
            TempAbsPlate, TempOuterCover, AirGapDepth, collector.CosTilt, collector.SinTilt
        )
    elif NumCovers == 2:
        for CoverNum in range(NumCovers):
            if CoverNum == 0:
                tempnom = (
                    StefanBoltzmann * ((TempAbsPlate + Kelvin) + (TempInnerCover + Kelvin)) *
                    ((TempAbsPlate + Kelvin) ** 2 + (TempInnerCover + Kelvin) ** 2)
                )
                tempdenom = 1.0 / EmissOfAbsPlate + 1.0 / EmissOfInnerCover - 1.0
                hRadCoefA2C = tempnom / tempdenom
                hConvCoefA2C = CalcConvCoeffBetweenPlates(
                    TempAbsPlate, TempInnerCover, AirGapDepth, collector.CosTilt, collector.SinTilt
                )
            else:
                tempnom = (
                    StefanBoltzmann * ((TempInnerCover + Kelvin) + (TempOuterCover + Kelvin)) *
                    ((TempInnerCover + Kelvin) ** 2 + (TempOuterCover + Kelvin) ** 2)
                )
                tempdenom = 1.0 / EmissOfInnerCover + 1.0 / EmissOfOuterCover - 1.0
                hRadCoefC2C = tempnom / tempdenom
                hConvCoefC2C = CalcConvCoeffBetweenPlates(
                    TempInnerCover, TempOuterCover, AirGapDepth, collector.CosTilt, collector.SinTilt
                )
    
    hConvCoefC2O = 2.8 + 3.0 * state.dataSurface_SurfOutWindSpeed[SurfNum]
    
    tempnom = (
        state.dataSurface_Surface[SurfNum].ViewFactorSky * EmissOfOuterCover * StefanBoltzmann *
        ((TempOuterCover + Kelvin) + state.dataEnvrn_SkyTempKelvin) *
        ((TempOuterCover + Kelvin) ** 2 + state.dataEnvrn_SkyTempKelvin ** 2)
    )
    tempdenom = (TempOuterCover - TempOutdoorAir) / (TempOuterCover - state.dataEnvrn_SkyTemp)
    if tempdenom < 0.0:
        hRadCoefC2Sky = tempnom
    elif tempdenom == 0.0:
        hRadCoefC2Sky = 0.0
    else:
        hRadCoefC2Sky = tempnom / tempdenom
    
    tempnom = (
        state.dataSurface_Surface[SurfNum].ViewFactorGround * EmissOfOuterCover * StefanBoltzmann *
        ((TempOuterCover + Kelvin) + state.dataEnvrn_GroundTempKelvin) *
        ((TempOuterCover + Kelvin) ** 2 + state.dataEnvrn_GroundTempKelvin ** 2)
    )
    tempdenom = (TempOuterCover - TempOutdoorAir) / (TempOuterCover - state.dataEnvrn_GroundTemp)
    if tempdenom < 0.0:
        hRadCoefC2Gnd = tempnom
    elif tempdenom == 0.0:
        hRadCoefC2Gnd = 0.0
    else:
        hRadCoefC2Gnd = tempnom / tempdenom
    
    hRadCoefC2O = hRadCoefC2Sky + hRadCoefC2Gnd
    
    if NumCovers == 1:
        collector.UTopLoss = 1.0 / (1.0 / (hRadCoefA2C + hConvCoefA2C) + 1.0 / (hRadCoefC2O + hConvCoefC2O))
    else:
        collector.UTopLoss = 1.0 / (
            1.0 / (hRadCoefA2C + hConvCoefA2C) + 1.0 / (hRadCoefC2C + hConvCoefC2C) + 1.0 / (hRadCoefC2O + hConvCoefC2O)
        )
    
    hRadConvOut = 5.7 + 3.8 * state.dataSurface_SurfOutWindSpeed[SurfNum]
    collector.UsLoss = 1.0 / (
        1.0 / (state.dataSolarCollectors_Parameters[ParamNum].ULossSide * collector.AreaRatio) +
        1.0 / (hRadConvOut * collector.AreaRatio)
    )
    
    if collector.OSCM_ON:
        collector.UbLoss = state.dataSolarCollectors_Parameters[ParamNum].ULossBottom
    else:
        collector.UbLoss = 1.0 / (
            1.0 / state.dataSolarCollectors_Parameters[ParamNum].ULossBottom + 1.0 / hRadConvOut
        )
    
    if NumCovers == 1:
        tempnom = (
            collector.CoverAbs[0] * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] +
            TempOutdoorAir * (hConvCoefC2O + hRadCoefC2O) +
            TempAbsPlate * (hConvCoefA2C + hRadCoefA2C)
        )
        tempdenom = (hConvCoefC2O + hRadCoefC2O) + (hConvCoefA2C + hRadCoefA2C)
        TempOuterCover = tempnom / tempdenom
    elif NumCovers == 2:
        for Num in range(NumCovers):
            if Num == 0:
                tempnom = (
                    collector.CoverAbs[Num] * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] +
                    TempOutdoorAir * (hConvCoefC2O + hRadCoefC2O) +
                    TempInnerCover * (hConvCoefC2C + hRadCoefC2C)
                )
                tempdenom = (hConvCoefC2O + hRadCoefC2O) + (hConvCoefC2C + hRadCoefC2C)
                TempOuterCover = tempnom / tempdenom
            else:
                tempnom = (
                    collector.CoverAbs[Num] * state.dataHeatBal_SurfQRadSWOutIncident[SurfNum] +
                    TempAbsPlate * (hConvCoefA2C + hRadCoefA2C) +
                    TempOuterCover * (hConvCoefC2C + hRadCoefC2C)
                )
                tempdenom = hConvCoefC2C + hRadCoefC2C + hConvCoefA2C + hRadCoefA2C
                TempInnerCover = tempnom / tempdenom
    
    collector.TempOfInnerCover = TempInnerCover
    collector.TempOfOuterCover = TempOuterCover

def update(state, collector: CollectorData):
    state.PlantUtilities_SafeCopyPlantNode(collector.InletNode, collector.OutletNode)
    state.dataLoopNodes_Node[collector.OutletNode].Temp = collector.OutletTemp
    Cp = state.plantLoc_loop_glycol_getSpecificHeat(state, collector.OutletTemp)
    state.dataLoopNodes_Node[collector.OutletNode].Enthalpy = Cp * state.dataLoopNodes_Node[collector.OutletNode].Temp

def report(state, collector: CollectorData):
    TimeStepInSecond = state.dataHVACGlobal_TimeStepSysSec
    
    collector.Energy = collector.Power * TimeStepInSecond
    collector.HeatEnergy = collector.HeatRate * TimeStepInSecond
    collector.CollHeatLossEnergy = collector.SkinHeatLossRate * TimeStepInSecond
    collector.StoredHeatEnergy = collector.StoredHeatRate * TimeStepInSecond

@dataclass
class SolarCollectorsData:
    NumOfCollectors: int = 0
    NumOfParameters: int = 0
    GetInputFlag: bool = True
    Parameters: List[ParametersData] = field(default_factory=list)
    Collector: List[CollectorData] = field(default_factory=list)
    UniqueParametersNames: dict = field(default_factory=dict)
    UniqueCollectorNames: dict = field(default_factory=dict)

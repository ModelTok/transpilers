from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List
import math

class CondenserType(IntEnum):
    Invalid = -1
    WaterCooled = 0
    SmartMixing = 1
    Num = 2

class CondenserModeTemperature(IntEnum):
    Invalid = -1
    EnteringCondenser = 0
    LeavingCondenser = 1
    Num = 2

@dataclass
class CGSHPNodeData:
    Temp: float = 0.0
    TempMin: float = 0.0
    TempSetPoint: float = 0.0
    MassFlowRate: float = 0.0
    MassFlowRateMin: float = 0.0
    MassFlowRateMax: float = 0.0
    MassFlowRateMinAvail: float = 0.0
    MassFlowRateMaxAvail: float = 0.0
    MassFlowRateSetPoint: float = 0.0
    MassFlowRateRequest: float = 0.0

@dataclass
class WrapperComponentSpecs:
    WrapperPerformanceObjectType: str = ""
    WrapperComponentName: str = ""
    WrapperPerformanceObjectIndex: int = 0
    WrapperIdenticalObjectNum: int = 0
    chSched: Optional[object] = None

@dataclass
class CHReportVars:
    CurrentMode: int = 0
    ChillerPartLoadRatio: float = 0.0
    ChillerCyclingRatio: float = 0.0
    ChillerFalseLoad: float = 0.0
    ChillerFalseLoadRate: float = 0.0
    CoolingPower: float = 0.0
    HeatingPower: float = 0.0
    QEvap: float = 0.0
    QCond: float = 0.0
    CoolingEnergy: float = 0.0
    HeatingEnergy: float = 0.0
    EvapEnergy: float = 0.0
    CondEnergy: float = 0.0
    CondInletTemp: float = 0.0
    EvapInletTemp: float = 0.0
    CondOutletTemp: float = 0.0
    EvapOutletTemp: float = 0.0
    Evapmdot: float = 0.0
    Condmdot: float = 0.0
    ActualCOP: float = 0.0
    ChillerCapFT: float = 0.0
    ChillerEIRFT: float = 0.0
    ChillerEIRFPLR: float = 0.0
    CondenserFanPowerUse: float = 0.0
    CondenserFanEnergy: float = 0.0
    ChillerPartLoadRatioSimul: float = 0.0
    ChillerCyclingRatioSimul: float = 0.0
    ChillerFalseLoadSimul: float = 0.0
    ChillerFalseLoadRateSimul: float = 0.0
    CoolingPowerSimul: float = 0.0
    QEvapSimul: float = 0.0
    QCondSimul: float = 0.0
    CoolingEnergySimul: float = 0.0
    EvapEnergySimul: float = 0.0
    CondEnergySimul: float = 0.0
    EvapInletTempSimul: float = 0.0
    EvapOutletTempSimul: float = 0.0
    EvapmdotSimul: float = 0.0
    CondInletTempSimul: float = 0.0
    CondOutletTempSimul: float = 0.0
    CondmdotSimul: float = 0.0
    ChillerCapFTSimul: float = 0.0
    ChillerEIRFTSimul: float = 0.0
    ChillerEIRFPLRSimul: float = 0.0

@dataclass
class ChillerHeaterSpecs:
    Name: str = ""
    CondModeCooling: CondenserModeTemperature = CondenserModeTemperature.Invalid
    CondModeHeating: CondenserModeTemperature = CondenserModeTemperature.Invalid
    CondMode: CondenserModeTemperature = CondenserModeTemperature.Invalid
    ConstantFlow: bool = False
    VariableFlow: bool = False
    CoolSetPointSetToLoop: bool = False
    HeatSetPointSetToLoop: bool = False
    CoolSetPointErrDone: bool = False
    HeatSetPointErrDone: bool = False
    PossibleSubcooling: bool = False
    ChillerHeaterNum: int = 1
    condenserType: CondenserType = CondenserType.Invalid
    ChillerCapFTCoolingIDX: int = 0
    ChillerEIRFTCoolingIDX: int = 0
    ChillerEIRFPLRCoolingIDX: int = 0
    ChillerCapFTHeatingIDX: int = 0
    ChillerEIRFTHeatingIDX: int = 0
    ChillerEIRFPLRHeatingIDX: int = 0
    ChillerCapFTIDX: int = 0
    ChillerEIRFTIDX: int = 0
    ChillerEIRFPLRIDX: int = 0
    EvapInletNodeNum: int = 0
    EvapOutletNodeNum: int = 0
    CondInletNodeNum: int = 0
    CondOutletNodeNum: int = 0
    ChillerCapFTError: int = 0
    ChillerCapFTErrorIndex: int = 0
    ChillerEIRFTError: int = 0
    ChillerEIRFTErrorIndex: int = 0
    ChillerEIRFPLRError: int = 0
    ChillerEIRFPLRErrorIndex: int = 0
    ChillerEIRRefTempErrorIndex: int = 0
    DeltaTErrCount: int = 0
    DeltaTErrCountIndex: int = 0
    CondMassFlowIndex: int = 0
    RefCapCooling: float = 0.0
    RefCapCoolingWasAutoSized: bool = False
    RefCOPCooling: float = 0.0
    TempRefEvapOutCooling: float = 0.0
    TempRefCondInCooling: float = 0.0
    TempRefCondOutCooling: float = 0.0
    MaxPartLoadRatCooling: float = 0.0
    OptPartLoadRatCooling: float = 0.0
    MinPartLoadRatCooling: float = 0.0
    ClgHtgToCoolingCapRatio: float = 0.0
    ClgHtgtoCogPowerRatio: float = 0.0
    RefCapClgHtg: float = 0.0
    RefCOPClgHtg: float = 0.0
    RefPowerClgHtg: float = 0.0
    TempRefEvapOutClgHtg: float = 0.0
    TempRefCondInClgHtg: float = 0.0
    TempRefCondOutClgHtg: float = 0.0
    TempLowLimitEvapOut: float = 0.0
    MaxPartLoadRatClgHtg: float = 0.0
    OptPartLoadRatClgHtg: float = 0.0
    MinPartLoadRatClgHtg: float = 0.0
    EvapInletNode: CGSHPNodeData = field(default_factory=CGSHPNodeData)
    EvapOutletNode: CGSHPNodeData = field(default_factory=CGSHPNodeData)
    CondInletNode: CGSHPNodeData = field(default_factory=CGSHPNodeData)
    CondOutletNode: CGSHPNodeData = field(default_factory=CGSHPNodeData)
    EvapVolFlowRate: float = 0.0
    EvapVolFlowRateWasAutoSized: bool = False
    tmpEvapVolFlowRate: float = 0.0
    CondVolFlowRate: float = 0.0
    CondVolFlowRateWasAutoSized: bool = False
    tmpCondVolFlowRate: float = 0.0
    CondMassFlowRateMax: float = 0.0
    EvapMassFlowRateMax: float = 0.0
    Evapmdot: float = 0.0
    Condmdot: float = 0.0
    DesignHotWaterVolFlowRate: float = 0.0
    OpenMotorEff: float = 0.0
    SizFac: float = 0.0
    RefCap: float = 0.0
    RefCOP: float = 0.0
    TempRefEvapOut: float = 0.0
    TempRefCondIn: float = 0.0
    TempRefCondOut: float = 0.0
    OptPartLoadRat: float = 0.0
    ChillerEIRFPLRMin: float = 0.0
    ChillerEIRFPLRMax: float = 0.0
    Report: CHReportVars = field(default_factory=CHReportVars)

@dataclass
class WrapperReportVars:
    Power: float = 0.0
    QCHW: float = 0.0
    QHW: float = 0.0
    QGLHE: float = 0.0
    TotElecCooling: float = 0.0
    TotElecHeating: float = 0.0
    CoolingEnergy: float = 0.0
    HeatingEnergy: float = 0.0
    GLHEEnergy: float = 0.0
    TotElecCoolingPwr: float = 0.0
    TotElecHeatingPwr: float = 0.0
    CoolingRate: float = 0.0
    HeatingRate: float = 0.0
    GLHERate: float = 0.0
    CHWInletTemp: float = 0.0
    HWInletTemp: float = 0.0
    GLHEInletTemp: float = 0.0
    CHWOutletTemp: float = 0.0
    HWOutletTemp: float = 0.0
    GLHEOutletTemp: float = 0.0
    CHWmdot: float = 0.0
    HWmdot: float = 0.0
    GLHEmdot: float = 0.0
    TotElecCoolingSimul: float = 0.0
    CoolingEnergySimul: float = 0.0
    TotElecCoolingPwrSimul: float = 0.0
    CoolingRateSimul: float = 0.0
    CHWInletTempSimul: float = 0.0
    GLHEInletTempSimul: float = 0.0
    CHWOutletTempSimul: float = 0.0
    GLHEOutletTempSimul: float = 0.0
    CHWmdotSimul: float = 0.0
    GLHEmdotSimul: float = 0.0

@dataclass
class WrapperSpecs:
    Name: str = ""
    VariableFlowCH: bool = False
    ancillaryPowerSched: Optional[object] = None
    chSched: Optional[object] = None
    ControlMode: CondenserType = CondenserType.Invalid
    CHWInletNodeNum: int = 0
    CHWOutletNodeNum: int = 0
    HWInletNodeNum: int = 0
    HWOutletNodeNum: int = 0
    GLHEInletNodeNum: int = 0
    GLHEOutletNodeNum: int = 0
    NumOfComp: int = 0
    CHWMassFlowRate: float = 0.0
    HWMassFlowRate: float = 0.0
    GLHEMassFlowRate: float = 0.0
    CHWMassFlowRateMax: float = 0.0
    HWMassFlowRateMax: float = 0.0
    GLHEMassFlowRateMax: float = 0.0
    WrapperCoolingLoad: float = 0.0
    WrapperHeatingLoad: float = 0.0
    AncillaryPower: float = 0.0
    WrapperComp: List[WrapperComponentSpecs] = field(default_factory=list)
    ChillerHeater: List[ChillerHeaterSpecs] = field(default_factory=list)
    CoolSetPointErrDone: bool = False
    HeatSetPointErrDone: bool = False
    CoolSetPointSetToLoop: bool = False
    HeatSetPointSetToLoop: bool = False
    ChillerHeaterNums: int = 0
    CWPlantLoc: object = None
    HWPlantLoc: object = None
    GLHEPlantLoc: object = None
    CHWMassFlowIndex: int = 0
    HWMassFlowIndex: int = 0
    GLHEMassFlowIndex: int = 0
    SizingFactor: float = 1.0
    CHWVolFlowRate: float = 0.0
    HWVolFlowRate: float = 0.0
    GLHEVolFlowRate: float = 0.0
    MyWrapperFlag: bool = True
    MyWrapperEnvrnFlag: bool = True
    SimulClgDominant: bool = False
    SimulHtgDominant: bool = False
    Report: WrapperReportVars = field(default_factory=WrapperReportVars)
    setupOutputVarsFlag: bool = True
    mySizesReported: bool = False

@dataclass
class PlantCentralGSHPData:
    getWrapperInputFlag: bool = True
    numWrappers: int = 0
    numChillerHeaters: int = 0
    ChillerCapFT: float = 0.0
    ChillerEIRFT: float = 0.0
    ChillerEIRFPLR: float = 0.0
    ChillerPartLoadRatio: float = 0.0
    ChillerCyclingRatio: float = 0.0
    ChillerFalseLoadRate: float = 0.0
    Wrapper: List[WrapperSpecs] = field(default_factory=list)
    ChillerHeater: List[ChillerHeaterSpecs] = field(default_factory=list)

def wrapper_factory(state: 'EnergyPlusData', objectName: str) -> Optional[WrapperSpecs]:
    if state.dataPlantCentralGSHP.getWrapperInputFlag:
        get_wrapper_input(state)
        state.dataPlantCentralGSHP.getWrapperInputFlag = False
    
    for thisWrapper in state.dataPlantCentralGSHP.Wrapper:
        if thisWrapper.Name == objectName:
            return thisWrapper
    
    raise RuntimeError(f"LocalPlantCentralGSHPFactory: Error getting inputs for object named: {objectName}")

def wrapper_on_init_loop_equip(wrapper: WrapperSpecs, state: 'EnergyPlusData', calledFromLocation: object) -> None:
    wrapper_initialize(wrapper, state, 0.0, calledFromLocation.loopNum)
    wrapper_size_wrapper(wrapper, state)

def wrapper_get_design_capacities(wrapper: WrapperSpecs, state: 'EnergyPlusData', calledFromLocation: object) -> tuple:
    MinLoad = 0.0
    MaxLoad = 0.0
    OptLoad = 0.0
    
    if calledFromLocation.loopNum == wrapper.CWPlantLoc.loopNum:
        if wrapper.ControlMode == CondenserType.SmartMixing:
            for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
                chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
                MaxLoad += chillerHeater.RefCapCooling * chillerHeater.MaxPartLoadRatCooling
                OptLoad += chillerHeater.RefCapCooling * chillerHeater.OptPartLoadRatCooling
                MinLoad += chillerHeater.RefCapCooling * chillerHeater.MinPartLoadRatCooling
    elif calledFromLocation.loopNum == wrapper.HWPlantLoc.loopNum:
        if wrapper.ControlMode == CondenserType.SmartMixing:
            for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
                chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
                MaxLoad += chillerHeater.RefCapClgHtg * chillerHeater.MaxPartLoadRatClgHtg
                OptLoad += chillerHeater.RefCapClgHtg * chillerHeater.OptPartLoadRatClgHtg
                MinLoad += chillerHeater.RefCapClgHtg * chillerHeater.MinPartLoadRatClgHtg
    
    return MinLoad, MaxLoad, OptLoad

def wrapper_get_sizing_factor(wrapper: WrapperSpecs) -> float:
    return 1.0

def wrapper_simulate(wrapper: WrapperSpecs, state: 'EnergyPlusData', calledFromLocation: object, 
                    FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
    if calledFromLocation.loopNum != wrapper.GLHEPlantLoc.loopNum:
        wrapper_initialize(wrapper, state, CurLoad, calledFromLocation.loopNum)
        wrapper_calc_wrapper_model(wrapper, state, CurLoad, calledFromLocation.loopNum)
    elif calledFromLocation.loopNum == wrapper.GLHEPlantLoc.loopNum:
        # Placeholder for UpdateChillerComponentCondenserSide call
        wrapper.SimulClgDominant = False
        wrapper.SimulHtgDominant = False
        if wrapper.WrapperCoolingLoad > 0 and wrapper.WrapperHeatingLoad > 0:
            SimulLoadRatio = wrapper.WrapperCoolingLoad / wrapper.WrapperHeatingLoad
            if SimulLoadRatio > wrapper.ChillerHeater[0].ClgHtgToCoolingCapRatio:
                wrapper.SimulClgDominant = True
                wrapper.SimulHtgDominant = False
            else:
                wrapper.SimulHtgDominant = True
                wrapper.SimulClgDominant = False

def get_wrapper_input(state: 'EnergyPlusData') -> None:
    routineName = "GetWrapperInput"
    ErrorsFound = False
    
    # Placeholder for actual input processing
    state.dataPlantCentralGSHP.numWrappers = 0
    state.dataPlantCentralGSHP.Wrapper = []

def get_chiller_heater_input(state: 'EnergyPlusData') -> None:
    routineName = "GetChillerHeaterInput"
    CHErrorsFound = False
    
    # Placeholder for actual input processing
    state.dataPlantCentralGSHP.numChillerHeaters = 0
    state.dataPlantCentralGSHP.ChillerHeater = []

def wrapper_setup_output_vars(wrapper: WrapperSpecs, state: 'EnergyPlusData') -> None:
    pass

def wrapper_initialize(wrapper: WrapperSpecs, state: 'EnergyPlusData', MyLoad: float, LoopNum: int) -> None:
    if wrapper.setupOutputVarsFlag:
        wrapper_setup_output_vars(wrapper, state)
        wrapper.setupOutputVarsFlag = False
    
    if wrapper.MyWrapperFlag:
        wrapper.MyWrapperFlag = False
    
    if wrapper.MyWrapperEnvrnFlag:
        if wrapper.ControlMode == CondenserType.SmartMixing:
            wrapper.CHWVolFlowRate = 0.0
            wrapper.HWVolFlowRate = 0.0
            wrapper.GLHEVolFlowRate = 0.0
            
            for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
                chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
                wrapper.CHWVolFlowRate += chillerHeater.EvapVolFlowRate
                wrapper.HWVolFlowRate += chillerHeater.DesignHotWaterVolFlowRate
                wrapper.GLHEVolFlowRate += chillerHeater.CondVolFlowRate
            
            wrapper.CHWMassFlowRateMax = wrapper.CHWVolFlowRate
            wrapper.HWMassFlowRateMax = wrapper.HWVolFlowRate
            wrapper.GLHEMassFlowRateMax = wrapper.GLHEVolFlowRate
            
            for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
                chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
                chillerHeater.EvapInletNode.MassFlowRateMin = 0.0
                chillerHeater.EvapInletNode.MassFlowRateMinAvail = 0.0
                chillerHeater.EvapInletNode.MassFlowRateMax = chillerHeater.EvapVolFlowRate
                chillerHeater.EvapInletNode.MassFlowRateMaxAvail = chillerHeater.EvapVolFlowRate
                chillerHeater.EvapInletNode.MassFlowRate = 0.0
                chillerHeater.CondInletNode.MassFlowRateMin = 0.0
                chillerHeater.CondInletNode.MassFlowRateMinAvail = 0.0
                chillerHeater.CondInletNode.MassFlowRateMax = chillerHeater.EvapVolFlowRate
                chillerHeater.CondInletNode.MassFlowRateMaxAvail = chillerHeater.EvapVolFlowRate
                chillerHeater.CondInletNode.MassFlowRate = 0.0
                chillerHeater.CondInletNode.MassFlowRateRequest = 0.0
        
        wrapper.MyWrapperEnvrnFlag = False
    
    mdotCHW = 0.0
    mdotHW = 0.0
    mdotGLHE = 0.0
    
    if LoopNum == wrapper.CWPlantLoc.loopNum:
        if MyLoad < -1.0:
            mdotCHW = 1.0
        else:
            mdotCHW = 0.0
        if wrapper.WrapperHeatingLoad > 1.0:
            mdotHW = 1.0
        else:
            mdotHW = 0.0
        if (MyLoad < -1.0) or (wrapper.WrapperHeatingLoad > 1.0):
            mdotGLHE = 1.0
        else:
            mdotGLHE = 0.0
    elif LoopNum == wrapper.HWPlantLoc.loopNum:
        if MyLoad > 1.0:
            mdotHW = 1.0
        else:
            mdotHW = 0.0
        if wrapper.WrapperCoolingLoad > 1.0:
            mdotCHW = 1.0
        else:
            mdotCHW = 0.0
        if (MyLoad > 1.0) or (wrapper.WrapperCoolingLoad > 1.0):
            mdotGLHE = 1.0
        else:
            mdotGLHE = 0.0
    elif LoopNum == wrapper.GLHEPlantLoc.loopNum:
        if wrapper.WrapperCoolingLoad > 1.0:
            mdotCHW = 1.0
        else:
            mdotCHW = 0.0
        if wrapper.WrapperHeatingLoad > 1.0:
            mdotHW = 1.0
        else:
            mdotHW = 0.0
        if (wrapper.WrapperHeatingLoad > 1.0) or (wrapper.WrapperCoolingLoad > 1.0):
            mdotGLHE = 1.0
        else:
            mdotGLHE = 0.0

def wrapper_size_wrapper(wrapper: WrapperSpecs, state: 'EnergyPlusData') -> None:
    if wrapper.ControlMode == CondenserType.SmartMixing:
        for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
            ErrorsFound = False
            chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
            
            tmpNomCap = chillerHeater.RefCapCooling
            tmpEvapVolFlowRate = chillerHeater.EvapVolFlowRate
            tmpCondVolFlowRate = chillerHeater.CondVolFlowRate

def wrapper_calc_wrapper_model(wrapper: WrapperSpecs, state: 'EnergyPlusData', MyLoad: float, LoopNum: int) -> None:
    CurHeatingLoad = 0.0
    CHWOutletTemp = 0.0
    CHWOutletMassFlowRate = 0.0
    HWOutletTemp = 0.0
    GLHEOutletTemp = 0.0
    GLHEOutletMassFlowRate = 0.0
    WrapperElecPowerCool = 0.0
    WrapperElecPowerHeat = 0.0
    WrapperCoolRate = 0.0
    WrapperHeatRate = 0.0
    WrapperGLHERate = 0.0
    WrapperElecEnergyCool = 0.0
    WrapperElecEnergyHeat = 0.0
    WrapperCoolEnergy = 0.0
    WrapperHeatEnergy = 0.0
    WrapperGLHEEnergy = 0.0
    
    CHWInletMassFlowRate = 0.0
    HWInletMassFlowRate = 0.0
    GLHEInletMassFlowRate = 0.0
    CHWInletTemp = 0.0
    HWInletTemp = 0.0
    GLHEInletTemp = 0.0
    CurCoolingLoad = 0.0
    
    if LoopNum == wrapper.CWPlantLoc.loopNum:
        CHWInletMassFlowRate = 1.0
        HWInletMassFlowRate = 1.0
        GLHEInletMassFlowRate = 1.0
        wrapper.WrapperCoolingLoad = abs(MyLoad)
        CurCoolingLoad = wrapper.WrapperCoolingLoad
        
        if wrapper.ControlMode == CondenserType.SmartMixing:
            if CurCoolingLoad > 0.0 and CHWInletMassFlowRate > 0.0 and GLHEInletMassFlowRate > 0:
                wrapper_calc_chiller_model(wrapper, state)
                wrapper_update_chiller_records(wrapper, state)
                
                CHWOutletTemp = 0.0
                GLHEOutletTemp = 0.0
                CHWOutletMassFlowRate = 0.0
                GLHEOutletMassFlowRate = 0.0
                
                for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
                    chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
                    CHWOutletMassFlowRate += chillerHeater.Report.Evapmdot
                    CHWOutletTemp += chillerHeater.Report.EvapOutletTemp * (chillerHeater.Report.Evapmdot / CHWInletMassFlowRate) if CHWInletMassFlowRate > 0 else 0
                    WrapperElecPowerCool += chillerHeater.Report.CoolingPower
                    WrapperCoolRate += chillerHeater.Report.QEvap
                    WrapperElecEnergyCool += chillerHeater.Report.CoolingEnergy
                    WrapperCoolEnergy += chillerHeater.Report.EvapEnergy
                    
                    if GLHEInletMassFlowRate > 0.0:
                        GLHEOutletMassFlowRate += chillerHeater.Report.Condmdot
                        if GLHEOutletMassFlowRate > GLHEInletMassFlowRate:
                            GLHEOutletMassFlowRate = GLHEInletMassFlowRate
                        GLHEOutletTemp += chillerHeater.Report.CondOutletTemp * (chillerHeater.Report.Condmdot / GLHEInletMassFlowRate)
                        WrapperGLHERate += chillerHeater.Report.QCond
                        WrapperGLHEEnergy += chillerHeater.Report.CondEnergy

def wrapper_calc_chiller_model(wrapper: WrapperSpecs, state: 'EnergyPlusData') -> None:
    pass

def wrapper_calc_chiller_heater_model(wrapper: WrapperSpecs, state: 'EnergyPlusData') -> None:
    pass

def wrapper_adjust_chiller_heater_cond_flow_temp(wrapper: WrapperSpecs, state: 'EnergyPlusData',
                                                 QCondenser: float, CondMassFlowRate: float,
                                                 CondOutletTemp: float, CondInletTemp: float,
                                                 CondDeltaTemp: float) -> tuple:
    return QCondenser, CondMassFlowRate, CondOutletTemp

def wrapper_adjust_chiller_heater_evap_flow_temp(wrapper: WrapperSpecs, state: 'EnergyPlusData',
                                                 qEvaporator: float, evapMassFlowRate: float,
                                                 evapOutletTemp: float, evapInletTemp: float) -> tuple:
    return evapMassFlowRate, evapOutletTemp

def wrapper_set_chiller_heater_cond_temp(wrapper: WrapperSpecs, state: 'EnergyPlusData',
                                         numChillerHeater: int, condEnteringTemp: float,
                                         condLeavingTemp: float) -> float:
    chillerHeater = wrapper.ChillerHeater[numChillerHeater - 1]
    if chillerHeater.CondMode == CondenserModeTemperature.EnteringCondenser:
        return condEnteringTemp
    else:
        return condLeavingTemp

def wrapper_calc_chiller_cap_ft(wrapper: WrapperSpecs, state: 'EnergyPlusData',
                               numChillerHeater: int, evapOutletTemp: float,
                               condTemp: float) -> float:
    return 1.0

def wrapper_check_evap_outlet_temp(wrapper: WrapperSpecs, state: 'EnergyPlusData',
                                   numChillerHeater: int, evapOutletTemp: float,
                                   lowTempLimitEout: float, evapInletTemp: float,
                                   qEvaporator: float, evapMassFlowRate: float,
                                   Cp: float) -> tuple:
    return evapOutletTemp, qEvaporator

def wrapper_calc_plr_and_cycling_ratio(wrapper: WrapperSpecs, state: 'EnergyPlusData',
                                       availChillerCap: float, actualPartLoadRatio: float,
                                       minPartLoadRatio: float, maxPartLoadRatio: float,
                                       qEvaporator: float, frac: float) -> tuple:
    return actualPartLoadRatio, frac

def wrapper_update_chiller_records(wrapper: WrapperSpecs, state: 'EnergyPlusData') -> None:
    SecInTimeStep = 1.0
    
    for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
        chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
        chillerHeater.Report.ChillerFalseLoad = chillerHeater.Report.ChillerFalseLoadRate * SecInTimeStep
        chillerHeater.Report.CoolingEnergy = chillerHeater.Report.CoolingPower * SecInTimeStep
        chillerHeater.Report.HeatingEnergy = chillerHeater.Report.HeatingPower * SecInTimeStep
        chillerHeater.Report.EvapEnergy = chillerHeater.Report.QEvap * SecInTimeStep
        chillerHeater.Report.CondEnergy = chillerHeater.Report.QCond * SecInTimeStep
        
        if wrapper.SimulClgDominant or wrapper.SimulHtgDominant:
            chillerHeater.Report.ChillerFalseLoadSimul = chillerHeater.Report.ChillerFalseLoad
            chillerHeater.Report.CoolingEnergySimul = chillerHeater.Report.CoolingEnergy
            chillerHeater.Report.EvapEnergySimul = chillerHeater.Report.EvapEnergy
            chillerHeater.Report.CondEnergySimul = chillerHeater.Report.CondEnergy

def wrapper_update_chiller_heater_records(wrapper: WrapperSpecs, state: 'EnergyPlusData') -> None:
    SecInTimeStep = 1.0
    
    for NumChillerHeater in range(1, wrapper.ChillerHeaterNums + 1):
        chillerHeater = wrapper.ChillerHeater[NumChillerHeater - 1]
        chillerHeater.Report.ChillerFalseLoad = chillerHeater.Report.ChillerFalseLoadRate * SecInTimeStep
        chillerHeater.Report.CoolingEnergy = chillerHeater.Report.CoolingPower * SecInTimeStep
        chillerHeater.Report.HeatingEnergy = chillerHeater.Report.HeatingPower * SecInTimeStep
        chillerHeater.Report.EvapEnergy = chillerHeater.Report.QEvap * SecInTimeStep
        chillerHeater.Report.CondEnergy = chillerHeater.Report.QCond * SecInTimeStep

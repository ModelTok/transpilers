from memory import memset_zero
from math import fabs, min as math_min, max as math_max

alias CondenserTypeInvalid = -1
alias CondenserTypeWaterCooled = 0
alias CondenserTypeSmartMixing = 1
alias CondenserTypeNum = 2

alias CondenserModeTemperatureInvalid = -1
alias CondenserModeTemperatureEnteringCondenser = 0
alias CondenserModeTemperatureLeavingCondenser = 1
alias CondenserModeTemperatureNum = 2

struct CGSHPNodeData:
    var Temp: Float64
    var TempMin: Float64
    var TempSetPoint: Float64
    var MassFlowRate: Float64
    var MassFlowRateMin: Float64
    var MassFlowRateMax: Float64
    var MassFlowRateMinAvail: Float64
    var MassFlowRateMaxAvail: Float64
    var MassFlowRateSetPoint: Float64
    var MassFlowRateRequest: Float64
    
    fn __init__(inout self):
        self.Temp = 0.0
        self.TempMin = 0.0
        self.TempSetPoint = 0.0
        self.MassFlowRate = 0.0
        self.MassFlowRateMin = 0.0
        self.MassFlowRateMax = 0.0
        self.MassFlowRateMinAvail = 0.0
        self.MassFlowRateMaxAvail = 0.0
        self.MassFlowRateSetPoint = 0.0
        self.MassFlowRateRequest = 0.0

struct WrapperComponentSpecs:
    var WrapperPerformanceObjectType: String
    var WrapperComponentName: String
    var WrapperPerformanceObjectIndex: Int32
    var WrapperIdenticalObjectNum: Int32
    var chSched: DTypePointer[DType.uint8]
    
    fn __init__(inout self):
        self.WrapperPerformanceObjectType = ""
        self.WrapperComponentName = ""
        self.WrapperPerformanceObjectIndex = 0
        self.WrapperIdenticalObjectNum = 0
        self.chSched = DTypePointer[DType.uint8]()

struct CHReportVars:
    var CurrentMode: Int32
    var ChillerPartLoadRatio: Float64
    var ChillerCyclingRatio: Float64
    var ChillerFalseLoad: Float64
    var ChillerFalseLoadRate: Float64
    var CoolingPower: Float64
    var HeatingPower: Float64
    var QEvap: Float64
    var QCond: Float64
    var CoolingEnergy: Float64
    var HeatingEnergy: Float64
    var EvapEnergy: Float64
    var CondEnergy: Float64
    var CondInletTemp: Float64
    var EvapInletTemp: Float64
    var CondOutletTemp: Float64
    var EvapOutletTemp: Float64
    var Evapmdot: Float64
    var Condmdot: Float64
    var ActualCOP: Float64
    var ChillerCapFT: Float64
    var ChillerEIRFT: Float64
    var ChillerEIRFPLR: Float64
    var CondenserFanPowerUse: Float64
    var CondenserFanEnergy: Float64
    var ChillerPartLoadRatioSimul: Float64
    var ChillerCyclingRatioSimul: Float64
    var ChillerFalseLoadSimul: Float64
    var ChillerFalseLoadRateSimul: Float64
    var CoolingPowerSimul: Float64
    var QEvapSimul: Float64
    var QCondSimul: Float64
    var CoolingEnergySimul: Float64
    var EvapEnergySimul: Float64
    var CondEnergySimul: Float64
    var EvapInletTempSimul: Float64
    var EvapOutletTempSimul: Float64
    var EvapmdotSimul: Float64
    var CondInletTempSimul: Float64
    var CondOutletTempSimul: Float64
    var CondmdotSimul: Float64
    var ChillerCapFTSimul: Float64
    var ChillerEIRFTSimul: Float64
    var ChillerEIRFPLRSimul: Float64
    
    fn __init__(inout self):
        self.CurrentMode = 0
        self.ChillerPartLoadRatio = 0.0
        self.ChillerCyclingRatio = 0.0
        self.ChillerFalseLoad = 0.0
        self.ChillerFalseLoadRate = 0.0
        self.CoolingPower = 0.0
        self.HeatingPower = 0.0
        self.QEvap = 0.0
        self.QCond = 0.0
        self.CoolingEnergy = 0.0
        self.HeatingEnergy = 0.0
        self.EvapEnergy = 0.0
        self.CondEnergy = 0.0
        self.CondInletTemp = 0.0
        self.EvapInletTemp = 0.0
        self.CondOutletTemp = 0.0
        self.EvapOutletTemp = 0.0
        self.Evapmdot = 0.0
        self.Condmdot = 0.0
        self.ActualCOP = 0.0
        self.ChillerCapFT = 0.0
        self.ChillerEIRFT = 0.0
        self.ChillerEIRFPLR = 0.0
        self.CondenserFanPowerUse = 0.0
        self.CondenserFanEnergy = 0.0
        self.ChillerPartLoadRatioSimul = 0.0
        self.ChillerCyclingRatioSimul = 0.0
        self.ChillerFalseLoadSimul = 0.0
        self.ChillerFalseLoadRateSimul = 0.0
        self.CoolingPowerSimul = 0.0
        self.QEvapSimul = 0.0
        self.QCondSimul = 0.0
        self.CoolingEnergySimul = 0.0
        self.EvapEnergySimul = 0.0
        self.CondEnergySimul = 0.0
        self.EvapInletTempSimul = 0.0
        self.EvapOutletTempSimul = 0.0
        self.EvapmdotSimul = 0.0
        self.CondInletTempSimul = 0.0
        self.CondOutletTempSimul = 0.0
        self.CondmdotSimul = 0.0
        self.ChillerCapFTSimul = 0.0
        self.ChillerEIRFTSimul = 0.0
        self.ChillerEIRFPLRSimul = 0.0

struct ChillerHeaterSpecs:
    var Name: String
    var CondModeCooling: Int32
    var CondModeHeating: Int32
    var CondMode: Int32
    var ConstantFlow: Bool
    var VariableFlow: Bool
    var CoolSetPointSetToLoop: Bool
    var HeatSetPointSetToLoop: Bool
    var CoolSetPointErrDone: Bool
    var HeatSetPointErrDone: Bool
    var PossibleSubcooling: Bool
    var ChillerHeaterNum: Int32
    var condenserType: Int32
    var ChillerCapFTCoolingIDX: Int32
    var ChillerEIRFTCoolingIDX: Int32
    var ChillerEIRFPLRCoolingIDX: Int32
    var ChillerCapFTHeatingIDX: Int32
    var ChillerEIRFTHeatingIDX: Int32
    var ChillerEIRFPLRHeatingIDX: Int32
    var ChillerCapFTIDX: Int32
    var ChillerEIRFTIDX: Int32
    var ChillerEIRFPLRIDX: Int32
    var EvapInletNodeNum: Int32
    var EvapOutletNodeNum: Int32
    var CondInletNodeNum: Int32
    var CondOutletNodeNum: Int32
    var ChillerCapFTError: Int32
    var ChillerCapFTErrorIndex: Int32
    var ChillerEIRFTError: Int32
    var ChillerEIRFTErrorIndex: Int32
    var ChillerEIRFPLRError: Int32
    var ChillerEIRFPLRErrorIndex: Int32
    var ChillerEIRRefTempErrorIndex: Int32
    var DeltaTErrCount: Int32
    var DeltaTErrCountIndex: Int32
    var CondMassFlowIndex: Int32
    var RefCapCooling: Float64
    var RefCapCoolingWasAutoSized: Bool
    var RefCOPCooling: Float64
    var TempRefEvapOutCooling: Float64
    var TempRefCondInCooling: Float64
    var TempRefCondOutCooling: Float64
    var MaxPartLoadRatCooling: Float64
    var OptPartLoadRatCooling: Float64
    var MinPartLoadRatCooling: Float64
    var ClgHtgToCoolingCapRatio: Float64
    var ClgHtgtoCogPowerRatio: Float64
    var RefCapClgHtg: Float64
    var RefCOPClgHtg: Float64
    var RefPowerClgHtg: Float64
    var TempRefEvapOutClgHtg: Float64
    var TempRefCondInClgHtg: Float64
    var TempRefCondOutClgHtg: Float64
    var TempLowLimitEvapOut: Float64
    var MaxPartLoadRatClgHtg: Float64
    var OptPartLoadRatClgHtg: Float64
    var MinPartLoadRatClgHtg: Float64
    var EvapInletNode: CGSHPNodeData
    var EvapOutletNode: CGSHPNodeData
    var CondInletNode: CGSHPNodeData
    var CondOutletNode: CGSHPNodeData
    var EvapVolFlowRate: Float64
    var EvapVolFlowRateWasAutoSized: Bool
    var tmpEvapVolFlowRate: Float64
    var CondVolFlowRate: Float64
    var CondVolFlowRateWasAutoSized: Bool
    var tmpCondVolFlowRate: Float64
    var CondMassFlowRateMax: Float64
    var EvapMassFlowRateMax: Float64
    var Evapmdot: Float64
    var Condmdot: Float64
    var DesignHotWaterVolFlowRate: Float64
    var OpenMotorEff: Float64
    var SizFac: Float64
    var RefCap: Float64
    var RefCOP: Float64
    var TempRefEvapOut: Float64
    var TempRefCondIn: Float64
    var TempRefCondOut: Float64
    var OptPartLoadRat: Float64
    var ChillerEIRFPLRMin: Float64
    var ChillerEIRFPLRMax: Float64
    var Report: CHReportVars
    
    fn __init__(inout self):
        self.Name = ""
        self.CondModeCooling = CondenserModeTemperatureInvalid
        self.CondModeHeating = CondenserModeTemperatureInvalid
        self.CondMode = CondenserModeTemperatureInvalid
        self.ConstantFlow = False
        self.VariableFlow = False
        self.CoolSetPointSetToLoop = False
        self.HeatSetPointSetToLoop = False
        self.CoolSetPointErrDone = False
        self.HeatSetPointErrDone = False
        self.PossibleSubcooling = False
        self.ChillerHeaterNum = 1
        self.condenserType = CondenserTypeInvalid
        self.ChillerCapFTCoolingIDX = 0
        self.ChillerEIRFTCoolingIDX = 0
        self.ChillerEIRFPLRCoolingIDX = 0
        self.ChillerCapFTHeatingIDX = 0
        self.ChillerEIRFTHeatingIDX = 0
        self.ChillerEIRFPLRHeatingIDX = 0
        self.ChillerCapFTIDX = 0
        self.ChillerEIRFTIDX = 0
        self.ChillerEIRFPLRIDX = 0
        self.EvapInletNodeNum = 0
        self.EvapOutletNodeNum = 0
        self.CondInletNodeNum = 0
        self.CondOutletNodeNum = 0
        self.ChillerCapFTError = 0
        self.ChillerCapFTErrorIndex = 0
        self.ChillerEIRFTError = 0
        self.ChillerEIRFTErrorIndex = 0
        self.ChillerEIRFPLRError = 0
        self.ChillerEIRFPLRErrorIndex = 0
        self.ChillerEIRRefTempErrorIndex = 0
        self.DeltaTErrCount = 0
        self.DeltaTErrCountIndex = 0
        self.CondMassFlowIndex = 0
        self.RefCapCooling = 0.0
        self.RefCapCoolingWasAutoSized = False
        self.RefCOPCooling = 0.0
        self.TempRefEvapOutCooling = 0.0
        self.TempRefCondInCooling = 0.0
        self.TempRefCondOutCooling = 0.0
        self.MaxPartLoadRatCooling = 0.0
        self.OptPartLoadRatCooling = 0.0
        self.MinPartLoadRatCooling = 0.0
        self.ClgHtgToCoolingCapRatio = 0.0
        self.ClgHtgtoCogPowerRatio = 0.0
        self.RefCapClgHtg = 0.0
        self.RefCOPClgHtg = 0.0
        self.RefPowerClgHtg = 0.0
        self.TempRefEvapOutClgHtg = 0.0
        self.TempRefCondInClgHtg = 0.0
        self.TempRefCondOutClgHtg = 0.0
        self.TempLowLimitEvapOut = 0.0
        self.MaxPartLoadRatClgHtg = 0.0
        self.OptPartLoadRatClgHtg = 0.0
        self.MinPartLoadRatClgHtg = 0.0
        self.EvapInletNode = CGSHPNodeData()
        self.EvapOutletNode = CGSHPNodeData()
        self.CondInletNode = CGSHPNodeData()
        self.CondOutletNode = CGSHPNodeData()
        self.EvapVolFlowRate = 0.0
        self.EvapVolFlowRateWasAutoSized = False
        self.tmpEvapVolFlowRate = 0.0
        self.CondVolFlowRate = 0.0
        self.CondVolFlowRateWasAutoSized = False
        self.tmpCondVolFlowRate = 0.0
        self.CondMassFlowRateMax = 0.0
        self.EvapMassFlowRateMax = 0.0
        self.Evapmdot = 0.0
        self.Condmdot = 0.0
        self.DesignHotWaterVolFlowRate = 0.0
        self.OpenMotorEff = 0.0
        self.SizFac = 0.0
        self.RefCap = 0.0
        self.RefCOP = 0.0
        self.TempRefEvapOut = 0.0
        self.TempRefCondIn = 0.0
        self.TempRefCondOut = 0.0
        self.OptPartLoadRat = 0.0
        self.ChillerEIRFPLRMin = 0.0
        self.ChillerEIRFPLRMax = 0.0
        self.Report = CHReportVars()

struct WrapperReportVars:
    var Power: Float64
    var QCHW: Float64
    var QHW: Float64
    var QGLHE: Float64
    var TotElecCooling: Float64
    var TotElecHeating: Float64
    var CoolingEnergy: Float64
    var HeatingEnergy: Float64
    var GLHEEnergy: Float64
    var TotElecCoolingPwr: Float64
    var TotElecHeatingPwr: Float64
    var CoolingRate: Float64
    var HeatingRate: Float64
    var GLHERate: Float64
    var CHWInletTemp: Float64
    var HWInletTemp: Float64
    var GLHEInletTemp: Float64
    var CHWOutletTemp: Float64
    var HWOutletTemp: Float64
    var GLHEOutletTemp: Float64
    var CHWmdot: Float64
    var HWmdot: Float64
    var GLHEmdot: Float64
    var TotElecCoolingSimul: Float64
    var CoolingEnergySimul: Float64
    var TotElecCoolingPwrSimul: Float64
    var CoolingRateSimul: Float64
    var CHWInletTempSimul: Float64
    var GLHEInletTempSimul: Float64
    var CHWOutletTempSimul: Float64
    var GLHEOutletTempSimul: Float64
    var CHWmdotSimul: Float64
    var GLHEmdotSimul: Float64
    
    fn __init__(inout self):
        self.Power = 0.0
        self.QCHW = 0.0
        self.QHW = 0.0
        self.QGLHE = 0.0
        self.TotElecCooling = 0.0
        self.TotElecHeating = 0.0
        self.CoolingEnergy = 0.0
        self.HeatingEnergy = 0.0
        self.GLHEEnergy = 0.0
        self.TotElecCoolingPwr = 0.0
        self.TotElecHeatingPwr = 0.0
        self.CoolingRate = 0.0
        self.HeatingRate = 0.0
        self.GLHERate = 0.0
        self.CHWInletTemp = 0.0
        self.HWInletTemp = 0.0
        self.GLHEInletTemp = 0.0
        self.CHWOutletTemp = 0.0
        self.HWOutletTemp = 0.0
        self.GLHEOutletTemp = 0.0
        self.CHWmdot = 0.0
        self.HWmdot = 0.0
        self.GLHEmdot = 0.0
        self.TotElecCoolingSimul = 0.0
        self.CoolingEnergySimul = 0.0
        self.TotElecCoolingPwrSimul = 0.0
        self.CoolingRateSimul = 0.0
        self.CHWInletTempSimul = 0.0
        self.GLHEInletTempSimul = 0.0
        self.CHWOutletTempSimul = 0.0
        self.GLHEOutletTempSimul = 0.0
        self.CHWmdotSimul = 0.0
        self.GLHEmdotSimul = 0.0

struct WrapperSpecs:
    var Name: String
    var VariableFlowCH: Bool
    var ancillaryPowerSched: DTypePointer[DType.uint8]
    var chSched: DTypePointer[DType.uint8]
    var ControlMode: Int32
    var CHWInletNodeNum: Int32
    var CHWOutletNodeNum: Int32
    var HWInletNodeNum: Int32
    var HWOutletNodeNum: Int32
    var GLHEInletNodeNum: Int32
    var GLHEOutletNodeNum: Int32
    var NumOfComp: Int32
    var CHWMassFlowRate: Float64
    var HWMassFlowRate: Float64
    var GLHEMassFlowRate: Float64
    var CHWMassFlowRateMax: Float64
    var HWMassFlowRateMax: Float64
    var GLHEMassFlowRateMax: Float64
    var WrapperCoolingLoad: Float64
    var WrapperHeatingLoad: Float64
    var AncillaryPower: Float64
    var ChillerHeaterNums: Int32
    var CoolSetPointErrDone: Bool
    var HeatSetPointErrDone: Bool
    var CoolSetPointSetToLoop: Bool
    var HeatSetPointSetToLoop: Bool
    var SizingFactor: Float64
    var CHWVolFlowRate: Float64
    var HWVolFlowRate: Float64
    var GLHEVolFlowRate: Float64
    var MyWrapperFlag: Bool
    var MyWrapperEnvrnFlag: Bool
    var SimulClgDominant: Bool
    var SimulHtgDominant: Bool
    var Report: WrapperReportVars
    var setupOutputVarsFlag: Bool
    var mySizesReported: Bool
    
    fn __init__(inout self):
        self.Name = ""
        self.VariableFlowCH = False
        self.ancillaryPowerSched = DTypePointer[DType.uint8]()
        self.chSched = DTypePointer[DType.uint8]()
        self.ControlMode = CondenserTypeInvalid
        self.CHWInletNodeNum = 0
        self.CHWOutletNodeNum = 0
        self.HWInletNodeNum = 0
        self.HWOutletNodeNum = 0
        self.GLHEInletNodeNum = 0
        self.GLHEOutletNodeNum = 0
        self.NumOfComp = 0
        self.CHWMassFlowRate = 0.0
        self.HWMassFlowRate = 0.0
        self.GLHEMassFlowRate = 0.0
        self.CHWMassFlowRateMax = 0.0
        self.HWMassFlowRateMax = 0.0
        self.GLHEMassFlowRateMax = 0.0
        self.WrapperCoolingLoad = 0.0
        self.WrapperHeatingLoad = 0.0
        self.AncillaryPower = 0.0
        self.ChillerHeaterNums = 0
        self.CoolSetPointErrDone = False
        self.HeatSetPointErrDone = False
        self.CoolSetPointSetToLoop = False
        self.HeatSetPointSetToLoop = False
        self.SizingFactor = 1.0
        self.CHWVolFlowRate = 0.0
        self.HWVolFlowRate = 0.0
        self.GLHEVolFlowRate = 0.0
        self.MyWrapperFlag = True
        self.MyWrapperEnvrnFlag = True
        self.SimulClgDominant = False
        self.SimulHtgDominant = False
        self.Report = WrapperReportVars()
        self.setupOutputVarsFlag = True
        self.mySizesReported = False

struct PlantCentralGSHPData:
    var getWrapperInputFlag: Bool
    var numWrappers: Int32
    var numChillerHeaters: Int32
    var ChillerCapFT: Float64
    var ChillerEIRFT: Float64
    var ChillerEIRFPLR: Float64
    var ChillerPartLoadRatio: Float64
    var ChillerCyclingRatio: Float64
    var ChillerFalseLoadRate: Float64
    
    fn __init__(inout self):
        self.getWrapperInputFlag = True
        self.numWrappers = 0
        self.numChillerHeaters = 0
        self.ChillerCapFT = 0.0
        self.ChillerEIRFT = 0.0
        self.ChillerEIRFPLR = 0.0
        self.ChillerPartLoadRatio = 0.0
        self.ChillerCyclingRatio = 0.0
        self.ChillerFalseLoadRate = 0.0

fn wrapper_factory(state_ptr: DTypePointer[DType.uint8], objectName: StringRef) -> DTypePointer[DType.uint8]:
    return DTypePointer[DType.uint8]()

fn wrapper_on_init_loop_equip(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8], calledFromLocation_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_get_design_capacities(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8], calledFromLocation_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_get_sizing_factor(wrapper_ptr: DTypePointer[DType.uint8]) -> Float64:
    return 1.0

fn wrapper_simulate(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8], calledFromLocation_ptr: DTypePointer[DType.uint8],
                   FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> None:
    pass

fn get_wrapper_input(state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn get_chiller_heater_input(state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_setup_output_vars(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_initialize(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8], MyLoad: Float64, LoopNum: Int32) -> None:
    pass

fn wrapper_size_wrapper(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_calc_wrapper_model(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8], MyLoad: Float64, LoopNum: Int32) -> None:
    pass

fn wrapper_calc_chiller_model(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_calc_chiller_heater_model(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_adjust_chiller_heater_cond_flow_temp(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8],
                                                QCondenser: Float64, CondMassFlowRate: Float64,
                                                CondOutletTemp: Float64, CondInletTemp: Float64,
                                                CondDeltaTemp: Float64) -> None:
    pass

fn wrapper_adjust_chiller_heater_evap_flow_temp(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8],
                                                qEvaporator: Float64, evapMassFlowRate: Float64,
                                                evapOutletTemp: Float64, evapInletTemp: Float64) -> None:
    pass

fn wrapper_set_chiller_heater_cond_temp(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8],
                                        numChillerHeater: Int32, condEnteringTemp: Float64,
                                        condLeavingTemp: Float64) -> Float64:
    return condEnteringTemp

fn wrapper_calc_chiller_cap_ft(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8],
                              numChillerHeater: Int32, evapOutletTemp: Float64,
                              condTemp: Float64) -> Float64:
    return 1.0

fn wrapper_check_evap_outlet_temp(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8],
                                  numChillerHeater: Int32, evapOutletTemp: Float64,
                                  lowTempLimitEout: Float64, evapInletTemp: Float64,
                                  qEvaporator: Float64, evapMassFlowRate: Float64,
                                  Cp: Float64) -> None:
    pass

fn wrapper_calc_plr_and_cycling_ratio(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8],
                                      availChillerCap: Float64, actualPartLoadRatio: Float64,
                                      minPartLoadRatio: Float64, maxPartLoadRatio: Float64,
                                      qEvaporator: Float64, frac: Float64) -> None:
    pass

fn wrapper_update_chiller_records(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_update_chiller_heater_records(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_one_time_init_new(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

fn wrapper_one_time_init(wrapper_ptr: DTypePointer[DType.uint8], state_ptr: DTypePointer[DType.uint8]) -> None:
    pass

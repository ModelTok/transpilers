# EXTERNAL DEPS (to wire in glue):
# - BaseGlobalStruct: from EnergyPlus/Data/BaseData.hh (base struct/trait)
# - EnergyPlusData: from EnergyPlus/EnergyPlus.hh (state object)


alias CtrlVarTypeInvalid = -1
alias CtrlVarTypeTemp = 0
alias CtrlVarTypeMaxTemp = 1
alias CtrlVarTypeMinTemp = 2
alias CtrlVarTypeHumRat = 3
alias CtrlVarTypeMaxHumRat = 4
alias CtrlVarTypeMinHumRat = 5
alias CtrlVarTypeMassFlowRate = 6
alias CtrlVarTypeMaxMassFlowRate = 7
alias CtrlVarTypeMinMassFlowRate = 8
alias CtrlVarTypeNum = 9


alias SmallHumRatDiff = 1.0e-7
alias SmallTempDiff = 1.0e-5
alias SmallMassFlow = 0.001
alias VerySmallMassFlow = 1.0e-30
alias SmallLoad = 1.0
alias TempControlTol = 0.1
alias SmallAirVolFlow = 0.001
alias SmallWaterVolFlow = 1.0e-9
alias BlankNumeric = -99999.0
alias RetTempMax = 60.0
alias RetTempMin = -30.0
alias DesCoilHWInletTempMin = 46.0

alias NumOfSizingTypes = 35

alias CoolingAirflowSizing = 1
alias CoolingWaterDesWaterInletTempSizing = 6
alias HeatingAirflowSizing = 14
alias SystemAirflowSizing = 16
alias CoolingCapacitySizing = 17
alias HeatingCapacitySizing = 18
alias SystemCapacitySizing = 21
alias AutoCalculateSizing = 25


alias SetptTypeInvalid = -1
alias SetptTypeUncontrolled = 0
alias SetptTypeSingleHeat = 1
alias SetptTypeSingleCool = 2
alias SetptTypeSingleHeatCool = 3
alias SetptTypeDualHeatCool = 4
alias SetptTypeNum = 5


alias AirDuctTypeInvalid = -1
alias AirDuctTypeMain = 0
alias AirDuctTypeCooling = 1
alias AirDuctTypeHeating = 2
alias AirDuctTypeOther = 3
alias AirDuctTypeRAB = 4
alias AirDuctTypeNum = 5

alias Cooling = 2
alias Heating = 3


alias FanTypeInvalid = -1
alias FanTypeConstant = 0
alias FanTypeVAV = 1
alias FanTypeOnOff = 2
alias FanTypeExhaust = 3
alias FanTypeComponentModel = 4
alias FanTypeSystemModel = 5
alias FanTypeNum = 6


alias FanOpInvalid = -1
alias FanOpCycling = 0
alias FanOpContinuous = 1
alias FanOpNum = 2


alias FanPlaceInvalid = -1
alias FanPlaceBlowThru = 0
alias FanPlaceDrawThru = 1
alias FanPlaceNum = 2

alias BypassWhenWithinEconomizerLimits = 0
alias BypassWhenOAFlowGreaterThanMinimum = 1


alias EconomizerStagingTypeInvalid = -1
alias EconomizerStagingTypeEconomizerFirst = 0
alias EconomizerStagingTypeInterlockedWithMechanicalCooling = 1
alias EconomizerStagingTypeNum = 2


alias UnitarySysTypeInvalid = -1
alias UnitarySysTypeFurnace_HeatOnly = 0
alias UnitarySysTypeFurnace_HeatCool = 1
alias UnitarySysTypeUnitary_HeatOnly = 2
alias UnitarySysTypeUnitary_HeatCool = 3
alias UnitarySysTypeUnitary_HeatPump_AirToAir = 4
alias UnitarySysTypeUnitary_HeatPump_WaterToAir = 5
alias UnitarySysTypeUnitary_AnyCoilType = 6
alias UnitarySysTypeNum = 7


alias CoilTypeInvalid = -1
alias CoilTypeCoolingDXSingleSpeed = 0
alias CoilTypeHeatingDXSingleSpeed = 1
alias CoilTypeCoolingDXTwoSpeed = 2
alias CoilTypeCoolingDXHXAssisted = 3
alias CoilTypeCoolingDXTwoStageWHumControl = 4
alias CoilTypeWaterHeatingDXPumped = 5
alias CoilTypeWaterHeatingDXWrapped = 6
alias CoilTypeCoolingDXMultiSpeed = 7
alias CoilTypeHeatingDXMultiSpeed = 8
alias CoilTypeHeatingGasOrOtherFuel = 9
alias CoilTypeHeatingGasMultiStage = 10
alias CoilTypeHeatingElectric = 11
alias CoilTypeHeatingElectricMultiStage = 12
alias CoilTypeHeatingDesuperheater = 13
alias CoilTypeCoolingWater = 14
alias CoilTypeCoolingWaterDetailed = 15
alias CoilTypeHeatingWater = 16
alias CoilTypeHeatingSteam = 17
alias CoilTypeCoolingWaterHXAssisted = 18
alias CoilTypeCoolingWAHP = 19
alias CoilTypeHeatingWAHP = 20
alias CoilTypeCoolingWAHPSimple = 21
alias CoilTypeHeatingWAHPSimple = 22
alias CoilTypeCoolingVRF = 23
alias CoilTypeHeatingVRF = 24
alias CoilTypeUserDefined = 25
alias CoilTypeCoolingDXPackagedThermalStorage = 26
alias CoilTypeCoolingWAHPVariableSpeedEquationFit = 27
alias CoilTypeHeatingWAHPVariableSpeedEquationFit = 28
alias CoilTypeCoolingDXVariableSpeed = 29
alias CoilTypeHeatingDXVariableSpeed = 30
alias CoilTypeWaterHeatingAWHPVariableSpeed = 31
alias CoilTypeCoolingVRFFluidTCtrl = 32
alias CoilTypeHeatingVRFFluidTCtrl = 33
alias CoilTypeCoolingDX = 34
alias CoilTypeDXSubcoolReheat = 35
alias CoilTypeCoolingDXCurveFit = 36
alias CoilTypeNum = 37


alias CoilModeInvalid = -1
alias CoilModeNormal = 0
alias CoilModeEnhanced = 1
alias CoilModeSubcoolReheat = 2
alias CoilModeNum = 3


alias HeatReclaimTypeInvalid = -1
alias HeatReclaimTypeRefrigeratedCaseCompressorRack = 0
alias HeatReclaimTypeRefrigeratedCaseCondenserAirCooled = 1
alias HeatReclaimTypeRefrigeratedCaseCondenserEvaporativeCooled = 2
alias HeatReclaimTypeRefrigeratedCaseCondenserWaterCooled = 3
alias HeatReclaimTypeCoilCoolDXSingleSpeed = 4
alias HeatReclaimTypeCoilCoolDXTwoSpeed = 5
alias HeatReclaimTypeCoilCoolDXMultiSpeed = 6
alias HeatReclaimTypeCoilCoolDXMultiMode = 7
alias HeatReclaimTypeCoilCoolDXVariableSpeed = 8
alias HeatReclaimTypeCoilCoolDX = 9
alias HeatReclaimTypeCoilCoolWAHPEquationFit = 10
alias HeatReclaimTypeCoilCoolWAHPVariableSpeedEquationFit = 11
alias HeatReclaimTypeNum = 12


alias WaterFlowInvalid = -1
alias WaterFlowCycling = 0
alias WaterFlowConstant = 1
alias WaterFlowConstantOnDemand = 2
alias WaterFlowNum = 3

alias CoilPerfDX_CoolBypassEmpirical = 100

alias MaxRatedVolFlowPerRatedTotCap1 = 0.00006041
alias MinRatedVolFlowPerRatedTotCap1 = 0.00004027
alias MaxHeatVolFlowPerRatedTotCap1 = 0.00008056
alias MaxCoolVolFlowPerRatedTotCap1 = 0.00006713
alias MinOperVolFlowPerRatedTotCap1 = 0.00002684

alias MaxRatedVolFlowPerRatedTotCap2 = 0.00003355
alias MinRatedVolFlowPerRatedTotCap2 = 0.00001677
alias MaxHeatVolFlowPerRatedTotCap2 = 0.00004026
alias MaxCoolVolFlowPerRatedTotCap2 = 0.00004026
alias MinOperVolFlowPerRatedTotCap2 = 0.00001342


alias DXCoilTypeInvalid = -1
alias DXCoilTypeRegular = 0
alias DXCoilTypeDOAS = 1
alias DXCoilTypeNum = 2


alias HXTypeInvalid = -1
alias HXTypeAirToAir_FlatPlate = 0
alias HXTypeAirToAir_SensAndLatent = 1
alias HXTypeDesiccant_Balanced = 2
alias HXTypeNum = 3


alias MixerTypeInvalid = -1
alias MixerTypeInletSide = 0
alias MixerTypeSupplySide = 1
alias MixerTypeNum = 2


alias OATTypeInvalid = -1
alias OATTypeWetBulb = 0
alias OATTypeDryBulb = 1
alias OATTypeNum = 2

alias OscillateMagnitude = 0.15

alias MaxSpeedLevels = 10


struct ComponentSetPtData:
    var EquipmentType: String
    var EquipmentName: String
    var NodeNumIn: Int32
    var NodeNumOut: Int32
    var EquipDemand: Float64
    var DesignFlowRate: Float64
    var HeatOrCool: String
    var OpType: Int32

    fn __init__(inout self):
        self.EquipmentType = String()
        self.EquipmentName = String()
        self.NodeNumIn = 0
        self.NodeNumOut = 0
        self.EquipDemand = 0.0
        self.DesignFlowRate = 0.0
        self.HeatOrCool = String()
        self.OpType = 0


alias CompressorOpInvalid = -1
alias CompressorOpOff = 0
alias CompressorOpOn = 1
alias CompressorOpNum = 2


fn _make_fan_type_names() -> List[String]:
    var result = List[String]()
    result.append("Fan:ConstantVolume")
    result.append("Fan:VariableVolume")
    result.append("Fan:OnOff")
    result.append("Fan:ZoneExhaust")
    result.append("Fan:ComponentModel")
    result.append("Fan:SystemModel")
    return result


fn _make_fan_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("FAN:CONSTANTVOLUME")
    result.append("FAN:VARIABLEVOLUME")
    result.append("FAN:ONOFF")
    result.append("FAN:ZONEEXHAUST")
    result.append("FAN:COMPONENTMODEL")
    result.append("FAN:SYSTEMMODEL")
    return result


fn _make_unitary_sys_type_names() -> List[String]:
    var result = List[String]()
    result.append("AirLoopHVAC:Unitary:Furnace:HeatOnly")
    result.append("AirLoopHVAC:Unitary:Furnace:HeatCool")
    result.append("AirLoopHVAC:UnitaryHeatOnly")
    result.append("AirLoopHVAC:UnitaryHeatCool")
    result.append("AirLoopHVAC:UnitaryHeatPump:AirToAir")
    result.append("AirLoopHVAC:UnitaryHeatPump:WaterToAir")
    result.append("AirLoopHVAC:UnitarySystem")
    return result


fn _make_unitary_sys_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("AIRLOOPHVAC:UNITARY:FURNACE:HEATONLY")
    result.append("AIRLOOPHVAC:UNITARY:FURNACE:HEATCOOL")
    result.append("AIRLOOPHVAC:UNITARYHEATONLY")
    result.append("AIRLOOPHVAC:UNITARYHEATCOOL")
    result.append("AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR")
    result.append("AIRLOOPHVAC:UNITARYHEATPUMP:WATERTOAIR")
    result.append("AIRLOOPHVAC:UNITARYSYSTEM")
    return result


fn _make_coil_type_names() -> List[String]:
    var result = List[String]()
    result.append("Coil:Cooling:DX:SingleSpeed")
    result.append("Coil:Heating:DX:SingleSpeed")
    result.append("Coil:Cooling:DX:TwoSpeed")
    result.append("CoilSystem:Cooling:DX:HeatExchangerAssisted")
    result.append("Coil:Cooling:DX:TwoStageWithHumidityControlMode")
    result.append("Coil:WaterHeating:AirToWaterHeatPump:Pumped")
    result.append("Coil:WaterHeating:AirToWaterHeatPump:Wrapped")
    result.append("Coil:Cooling:DX:MultiSpeed")
    result.append("Coil:Heating:DX:MultiSpeed")
    result.append("Coil:Heating:Fuel")
    result.append("Coil:Heating:Gas:MultiStage")
    result.append("Coil:Heating:Electric")
    result.append("Coil:Heating:Electric:MultiStage")
    result.append("Coil:Heating:Desuperheater")
    result.append("Coil:Cooling:Water")
    result.append("Coil:Cooling:Water:DetailedGeometry")
    result.append("Coil:Heating:Water")
    result.append("Coil:Heating:Steam")
    result.append("CoilSystem:Cooling:Water:HeatExchangerAssisted")
    result.append("Coil:Cooling:WaterToAirHeatPump:ParameterEstimation")
    result.append("Coil:Heating:WaterToAirHeatPump:ParameterEstimation")
    result.append("Coil:Cooling:WaterToAirHeatPump:EquationFit")
    result.append("Coil:Heating:WaterToAirHeatPump:EquationFit")
    result.append("Coil:Cooling:DX:VariableRefrigerantFlow")
    result.append("Coil:Heating:DX:VariableRefrigerantFlow")
    result.append("Coil:UserDefined")
    result.append("Coil:Cooling:DX:SingleSpeed:ThermalStorage")
    result.append("Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit")
    result.append("Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit")
    result.append("Coil:Cooling:DX:VariableSpeed")
    result.append("Coil:Heating:DX:VariableSpeed")
    result.append("Coil:WaterHeating:AirToWaterHeatPump:VariableSpeed")
    result.append("Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl")
    result.append("Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl")
    result.append("Coil:Cooling:DX")
    result.append("Coil:Cooling:DX:SubcoolReheat")
    result.append("Coil:Cooling:DX:CurveFit:Speed")
    return result


fn _make_coil_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("COIL:COOLING:DX:SINGLESPEED")
    result.append("COIL:HEATING:DX:SINGLESPEED")
    result.append("COIL:COOLING:DX:TWOSPEED")
    result.append("COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED")
    result.append("COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE")
    result.append("COIL:WATERHEATING:AIRTOWATERHEATPUMP:PUMPED")
    result.append("COIL:WATERHEATING:AIRTOWATERHEATPUMP:WRAPPED")
    result.append("COIL:COOLING:DX:MULTISPEED")
    result.append("COIL:HEATING:DX:MULTISPEED")
    result.append("COIL:HEATING:FUEL")
    result.append("COIL:HEATING:GAS:MULTISTAGE")
    result.append("COIL:HEATING:ELECTRIC")
    result.append("COIL:HEATING:ELECTRIC:MULTISTAGE")
    result.append("COIL:HEATING:DESUPERHEATER")
    result.append("COIL:COOLING:WATER")
    result.append("COIL:COOLING:WATER:DETAILEDGEOMETRY")
    result.append("COIL:HEATING:WATER")
    result.append("COIL:HEATING:STEAM")
    result.append("COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED")
    result.append("COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION")
    result.append("COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION")
    result.append("COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT")
    result.append("COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT")
    result.append("COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW")
    result.append("COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW")
    result.append("COIL:USERDEFINED")
    result.append("COIL:COOLING:DX:SINGLESPEED:THERMALSTORAGE")
    result.append("COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT")
    result.append("COIL:HEATING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT")
    result.append("COIL:COOLING:DX:VARIABLESPEED")
    result.append("COIL:HEATING:DX:VARIABLESPEED")
    result.append("COIL:WATERHEATING:AIRTOWATERHEATPUMP:VARIABLESPEED")
    result.append("COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL")
    result.append("COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL")
    result.append("COIL:COOLING:DX")
    result.append("COIL:COOLING:DX:SUBCOOLREHEAT")
    result.append("COIL:COOLING:DX:CURVEFIT:SPEED")
    return result


fn _make_coil_type_is_cooling() -> List[Bool]:
    var result = List[Bool]()
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(True)
    return result


fn _make_coil_type_is_heating() -> List[Bool]:
    var result = List[Bool]()
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(True)
    result.append(True)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    return result


fn _make_coil_type_is_heat_pump() -> List[Bool]:
    var result = List[Bool]()
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(True)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    result.append(False)
    return result


fn _make_water_flow_names() -> List[String]:
    var result = List[String]()
    result.append("Cycling")
    result.append("Constant")
    result.append("ConstantOnDemand")
    return result


fn _make_water_flow_names_uc() -> List[String]:
    var result = List[String]()
    result.append("CYCLING")
    result.append("CONSTANT")
    result.append("CONSTANTONDEMAND")
    return result


fn _make_heat_reclaim_type_names() -> List[String]:
    var result = List[String]()
    result.append("Refrigeration:CompressorRack")
    result.append("Refrigeration:Condenser:AirCooled")
    result.append("Refrigeration:Condenser:EvaporativeCooled")
    result.append("Refrigeration:Condenser:WaterCooled")
    result.append("Coil:Cooling:DX:SingleSpeed")
    result.append("Coil:Cooling:DX:TwoSpeed")
    result.append("Coil:Cooling:DX:MultiSpeed")
    result.append("Coil:Cooling:DX:TwoStageWithHumidityControlMode")
    result.append("Coil:Cooling:DX:VariableSpeed")
    result.append("Coil:Cooling:DX")
    result.append("Coil:Cooling:WaterToAirHeatPump:EquationFit")
    result.append("Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit")
    return result


fn _make_heat_reclaim_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("REFRIGERATION:COMPRESSORRACK")
    result.append("REFRIGERATION:CONDENSER:AIRCOOLED")
    result.append("REFRIGERATION:CONDENSER:EVAPORATIVECOOLED")
    result.append("REFRIGERATION:CONDENSER:WATERCOOLED")
    result.append("COIL:COOLING:DX:SINGLESPEED")
    result.append("COIL:COOLING:DX:TWOSPEED")
    result.append("COIL:COOLING:DX:MULTISPEED")
    result.append("COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE")
    result.append("COIL:COOLING:DX:VARIABLESPEED")
    result.append("COIL:COOLING:DX")
    result.append("COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT")
    result.append("COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT")
    return result


fn _make_setpt_type_names() -> List[String]:
    var result = List[String]()
    result.append("Uncontrolled")
    result.append("SingleHeating")
    result.append("SingleCooling")
    result.append("SingleHeatCool")
    result.append("DualSetPointWithDeadBand")
    return result


fn _make_air_duct_type_names() -> List[String]:
    var result = List[String]()
    result.append("Main")
    result.append("Cooling")
    result.append("Heating")
    result.append("Other")
    result.append("Return Air Bypass")
    return result


fn _make_fan_place_names_uc() -> List[String]:
    var result = List[String]()
    result.append("BLOWTHROUGH")
    result.append("DRAWTHROUGH")
    return result


fn _make_economizer_staging_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("ECONOMIZERFIRST")
    result.append("INTERLOCKEDWITHMECHANICALCOOLING")
    return result


fn _make_economizer_staging_type_names() -> List[String]:
    var result = List[String]()
    result.append("EconomizerFirst")
    result.append("InterlockedWithMechanicalCooling")
    return result


fn _make_hx_type_names() -> List[String]:
    var result = List[String]()
    result.append("HeatExchanger:AirToAir:FlatPlate")
    result.append("HeatExchanger:AirToAir:SensibleAndLatent")
    result.append("HeatExchanger:Desiccant:BalancedFlow")
    return result


fn _make_hx_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("HEATEXCHANGER:AIRTOAIR:FLATPLATE")
    result.append("HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT")
    result.append("HEATEXCHANGER:DESICCANT:BALANCEDFLOW")
    return result


fn _make_mixer_type_names() -> List[String]:
    var result = List[String]()
    result.append("AirTerminal:SingleDuct:InletSideMixer")
    result.append("AirTerminal:SingleDuct:SupplySideMixer")
    return result


fn _make_mixer_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("AIRTERMINAL:SINGLEDUCT:INLETSIDEMIXER")
    result.append("AIRTERMINAL:SINGLEDUCT:SUPPLYSIDEMIXER")
    return result


fn _make_mixer_type_loc_names() -> List[String]:
    var result = List[String]()
    result.append("InletSide")
    result.append("SupplySide")
    return result


fn _make_mixer_type_loc_names_uc() -> List[String]:
    var result = List[String]()
    result.append("INLETSIDE")
    result.append("SUPPLYSIDE")
    return result


fn _make_oat_type_names() -> List[String]:
    var result = List[String]()
    result.append("WetBulbTemperature")
    result.append("DryBulbTemperature")
    return result


fn _make_oat_type_names_uc() -> List[String]:
    var result = List[String]()
    result.append("WETBULBTEMPERATURE")
    result.append("DRYBULBTEMPERATURE")
    return result


struct HVACGlobalsData:
    var CompSetPtEquip: List[ComponentSetPtData]

    var MSHPMassFlowRateLow: Float64
    var MSHPMassFlowRateHigh: Float64
    var MSHPWasteHeat: Float64
    var PreviousTimeStep: Float64
    var ShortenTimeStepSysRoomAir: Bool
    var MSUSEconoSpeedNum: Float64

    var deviationFromSetPtThresholdHtg: Float64
    var deviationFromSetPtThresholdClg: Float64

    var SimAirLoopsFlag: Bool
    var SimElecCircuitsFlag: Bool
    var SimPlantLoopsFlag: Bool
    var SimZoneEquipmentFlag: Bool
    var SimNonZoneEquipmentFlag: Bool
    var ZoneMassBalanceHVACReSim: Bool
    var MinAirLoopIterationsAfterFirst: Int32

    var DXCT: Int32
    var FirstTimeStepSysFlag: Bool

    var TimeStepSys: Float64
    var TimeStepSysSec: Float64
    var SysTimeElapsed: Float64
    var FracTimeStepZone: Float64
    var ShortenTimeStepSys: Bool
    var NumOfSysTimeSteps: Int32
    var NumOfSysTimeStepsLastZoneTimeStep: Int32
    var LimitNumSysSteps: Int32

    var UseZoneTimeStepHistory: Bool
    var NumPlantLoops: Int32
    var NumCondLoops: Int32
    var NumElecCircuits: Int32
    var NumGasMeters: Int32
    var NumPrimaryAirSys: Int32
    var OnOffFanPartLoadFraction: Float64
    var DXCoilTotalCapacity: Float64
    var DXElecCoolingPower: Float64
    var DXElecHeatingPower: Float64
    var ElecHeatingCoilPower: Float64
    var SuppHeatingCoilPower: Float64
    var AirToAirHXElecPower: Float64
    var DefrostElecPower: Float64

    var UnbalExhMassFlow: Float64
    var BalancedExhMassFlow: Float64
    var PlenumInducedMassFlow: Float64
    var TurnFansOn: Bool
    var TurnFansOff: Bool
    var SetPointErrorFlag: Bool
    var DoSetPointTest: Bool
    var NightVentOn: Bool

    var NumTempContComps: Int32
    var HPWHInletDBTemp: Float64
    var HPWHInletWBTemp: Float64
    var HPWHCrankcaseDBTemp: Float64
    var AirLoopInit: Bool
    var AirLoopsSimOnce: Bool
    var GetAirPathDataDone: Bool
    var StandardRatingsMyOneTimeFlag: Bool
    var StandardRatingsMyCoolOneTimeFlag: Bool
    var StandardRatingsMyCoolOneTimeFlag2: Bool
    var StandardRatingsMyCoolOneTimeFlag3: Bool
    var StandardRatingsMyHeatOneTimeFlag: Bool
    var StandardRatingsMyHeatOneTimeFlag2: Bool

    fn __init__(inout self):
        self.CompSetPtEquip = List[ComponentSetPtData]()
        self.MSHPMassFlowRateLow = 0.0
        self.MSHPMassFlowRateHigh = 0.0
        self.MSHPWasteHeat = 0.0
        self.PreviousTimeStep = 0.0
        self.ShortenTimeStepSysRoomAir = False
        self.MSUSEconoSpeedNum = 0.0
        self.deviationFromSetPtThresholdHtg = -0.2
        self.deviationFromSetPtThresholdClg = 0.2
        self.SimAirLoopsFlag = False
        self.SimElecCircuitsFlag = False
        self.SimPlantLoopsFlag = False
        self.SimZoneEquipmentFlag = False
        self.SimNonZoneEquipmentFlag = False
        self.ZoneMassBalanceHVACReSim = False
        self.MinAirLoopIterationsAfterFirst = 1
        self.DXCT = DXCoilTypeRegular
        self.FirstTimeStepSysFlag = False
        self.TimeStepSys = 0.0
        self.TimeStepSysSec = 0.0
        self.SysTimeElapsed = 0.0
        self.FracTimeStepZone = 0.0
        self.ShortenTimeStepSys = False
        self.NumOfSysTimeSteps = 1
        self.NumOfSysTimeStepsLastZoneTimeStep = 1
        self.LimitNumSysSteps = 0
        self.UseZoneTimeStepHistory = True
        self.NumPlantLoops = 0
        self.NumCondLoops = 0
        self.NumElecCircuits = 0
        self.NumGasMeters = 0
        self.NumPrimaryAirSys = 0
        self.OnOffFanPartLoadFraction = 1.0
        self.DXCoilTotalCapacity = 0.0
        self.DXElecCoolingPower = 0.0
        self.DXElecHeatingPower = 0.0
        self.ElecHeatingCoilPower = 0.0
        self.SuppHeatingCoilPower = 0.0
        self.AirToAirHXElecPower = 0.0
        self.DefrostElecPower = 0.0
        self.UnbalExhMassFlow = 0.0
        self.BalancedExhMassFlow = 0.0
        self.PlenumInducedMassFlow = 0.0
        self.TurnFansOn = False
        self.TurnFansOff = False
        self.SetPointErrorFlag = False
        self.DoSetPointTest = False
        self.NightVentOn = False
        self.NumTempContComps = 0
        self.HPWHInletDBTemp = 0.0
        self.HPWHInletWBTemp = 0.0
        self.HPWHCrankcaseDBTemp = 0.0
        self.AirLoopInit = False
        self.AirLoopsSimOnce = False
        self.GetAirPathDataDone = False
        self.StandardRatingsMyOneTimeFlag = True
        self.StandardRatingsMyCoolOneTimeFlag = True
        self.StandardRatingsMyCoolOneTimeFlag2 = True
        self.StandardRatingsMyCoolOneTimeFlag3 = True
        self.StandardRatingsMyHeatOneTimeFlag = True
        self.StandardRatingsMyHeatOneTimeFlag2 = True

    fn init_constant_state(inout self, state: object) -> None:
        pass

    fn init_state(inout self, state: object) -> None:
        pass

    fn clear_state(inout self) -> None:
        self = HVACGlobalsData()

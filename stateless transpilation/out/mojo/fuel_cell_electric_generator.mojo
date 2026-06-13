# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state parameter)
# - DataGenerators module (enums: CurveMode, SkinLoss, AirSupRateMode, RecoverMode, ConstituentMode,
#   WaterTempMode, InverterEfficiencyMode, ExhaustGasHX, LossDestination, ElectricalStorage;
#   constants: RinKJperMolpK, ImBalanceTol, MinProductGasTemp, MaxProductGasTemp, InitHRTemp)
# - Curve module (GetCurve, CurveValue functions, Curve struct)
# - Node module (GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream)
# - PlantUtilities (UpdateComponentHeatRecoverySide, SetComponentFlowRate, InitComponentNodes, SafeCopyPlantNode, RegisterPlantCompDesignFlow)
# - ScheduleManager (GetSchedule function)
# - Util/UtilityRoutines (FindItemInList, SameString, FindItem, makeUPPER)
# - General (SolveRoot function)
# - OutputProcessor (SetupOutputVariable, SetupZoneInternalGain, TimeStepType, StoreType, Group, EndUseCat)
# - Constant module (Units, eResource, Kelvin, rSecsInHour, rHoursInDay)
# - DataHeatBalance (IntGainType)
# - DataPlant (PlantEquipmentType, PlantLocation)
# - GeneratorFuelSupply (GetGeneratorFuelSupplyInput, SetupFuelConstituentData)
# - PlantComponent base trait
# - ShowFatalError, ShowSevereError, ShowSevereInvalidKey, ShowSevereEmptyField, ShowSevereItemNotFound,
#   ShowWarningError, ShowContinueError, ShowRecurringWarningErrorAtEnd (error/warning functions)

from math import pow as math_pow


@value
struct GasID:
    var value: Int32
    
    @staticmethod
    fn Invalid() -> Int32:
        return -1
    
    @staticmethod
    fn CarbonDioxide() -> Int32:
        return 1
    
    @staticmethod
    fn Nitrogen() -> Int32:
        return 2
    
    @staticmethod
    fn Oxygen() -> Int32:
        return 3
    
    @staticmethod
    fn Water() -> Int32:
        return 4
    
    @staticmethod
    fn Argon() -> Int32:
        return 5
    
    @staticmethod
    fn Num() -> Int32:
        return 6


struct FCPowerModuleStruct:
    var Name: String
    var EffMode: Int32
    var EffCurve: Optional[OpaquePointer]
    var NomEff: Float64
    var NomPel: Float64
    var NumCyclesAtStart: Int32
    var NumCycles: Int32
    var CyclingDegradRat: Float64
    var NumRunHours: Float64
    var OperateDegradRat: Float64
    var ThreshRunHours: Float64
    var UpTranLimit: Float64
    var DownTranLimit: Float64
    var StartUpTime: Float64
    var StartUpFuel: Float64
    var StartUpElectConsum: Float64
    var StartUpElectProd: Float64
    var ShutDownTime: Float64
    var ShutDownFuel: Float64
    var ShutDownElectConsum: Float64
    var ANC0: Float64
    var ANC1: Float64
    var SkinLossMode: Int32
    var ZoneName: String
    var ZoneID: Int32
    var RadiativeFract: Float64
    var QdotSkin: Float64
    var UAskin: Float64
    var SkinLossCurve: Optional[OpaquePointer]
    var WaterSupplyCurve: Optional[OpaquePointer]
    var NdotDilutionAir: Float64
    var StackHeatLossToDilution: Float64
    var DilutionInletNodeName: String
    var DilutionInletNode: Int32
    var DilutionExhaustNodeName: String
    var DilutionExhaustNode: Int32
    var PelMin: Float64
    var PelMax: Float64
    var Pel: Float64
    var PelLastTimeStep: Float64
    var Eel: Float64
    var QdotStackCool: Float64
    var FractionalDayofLastStartUp: Float64
    var FractionalDayofLastShutDown: Float64
    var HasBeenOn: Bool
    var DuringShutDown: Bool
    var DuringStartUp: Bool
    var NdotFuel: Float64
    var TotFuelInEnthalpy: Float64
    var NdotProdGas: Float64
    var ConstitMolalFract: InlineArray[Float64, 15]
    var GasLibID: InlineArray[Int32, 15]
    var TprodGasLeavingFCPM: Float64
    var NdotAir: Float64
    var TotAirInEnthalpy: Float64
    var NdotLiqwater: Float64
    var TwaterInlet: Float64
    var WaterInEnthalpy: Float64
    var DilutionAirInEnthalpy: Float64
    var DilutionAirOutEnthalpy: Float64
    var PelancillariesAC: Float64
    var TotProdGasEnthalpy: Float64
    var WaterOutEnthalpy: Float64
    var SeqSubstitIter: Int32
    var RegulaFalsiIter: Int32
    
    fn __init__(inout self):
        self.Name = ""
        self.EffMode = 0
        self.EffCurve = None
        self.NomEff = 0.0
        self.NomPel = 0.0
        self.NumCyclesAtStart = 0
        self.NumCycles = 0
        self.CyclingDegradRat = 0.0
        self.NumRunHours = 0.0
        self.OperateDegradRat = 0.0
        self.ThreshRunHours = 0.0
        self.UpTranLimit = 0.0
        self.DownTranLimit = 0.0
        self.StartUpTime = 0.0
        self.StartUpFuel = 0.0
        self.StartUpElectConsum = 0.0
        self.StartUpElectProd = 0.0
        self.ShutDownTime = 0.0
        self.ShutDownFuel = 0.0
        self.ShutDownElectConsum = 0.0
        self.ANC0 = 0.0
        self.ANC1 = 0.0
        self.SkinLossMode = 0
        self.ZoneName = ""
        self.ZoneID = 0
        self.RadiativeFract = 0.0
        self.QdotSkin = 0.0
        self.UAskin = 0.0
        self.SkinLossCurve = None
        self.WaterSupplyCurve = None
        self.NdotDilutionAir = 0.0
        self.StackHeatLossToDilution = 0.0
        self.DilutionInletNodeName = ""
        self.DilutionInletNode = 0
        self.DilutionExhaustNodeName = ""
        self.DilutionExhaustNode = 0
        self.PelMin = 0.0
        self.PelMax = 0.0
        self.Pel = 0.0
        self.PelLastTimeStep = 0.0
        self.Eel = 0.0
        self.QdotStackCool = 0.0
        self.FractionalDayofLastStartUp = 0.0
        self.FractionalDayofLastShutDown = 0.0
        self.HasBeenOn = True
        self.DuringShutDown = False
        self.DuringStartUp = False
        self.NdotFuel = 0.0
        self.TotFuelInEnthalpy = 0.0
        self.NdotProdGas = 0.0
        self.ConstitMolalFract = InlineArray[Float64, 15](fill=0.0)
        self.GasLibID = InlineArray[Int32, 15](fill=GasID.Invalid())
        self.TprodGasLeavingFCPM = 0.0
        self.NdotAir = 0.0
        self.TotAirInEnthalpy = 0.0
        self.NdotLiqwater = 0.0
        self.TwaterInlet = 0.0
        self.WaterInEnthalpy = 0.0
        self.DilutionAirInEnthalpy = 0.0
        self.DilutionAirOutEnthalpy = 0.0
        self.PelancillariesAC = 0.0
        self.TotProdGasEnthalpy = 0.0
        self.WaterOutEnthalpy = 0.0
        self.SeqSubstitIter = 0
        self.RegulaFalsiIter = 0


struct FCAirSupplyDataStruct:
    var Name: String
    var NodeName: String
    var SupNodeNum: Int32
    var BlowerPowerCurve: Optional[OpaquePointer]
    var BlowerHeatLossFactor: Float64
    var AirSupRateMode: Int32
    var Stoics: Float64
    var AirFuncPelCurve: Optional[OpaquePointer]
    var AirTempCoeff: Float64
    var AirFuncNdotCurve: Optional[OpaquePointer]
    var IntakeRecoveryMode: Int32
    var ConstituentMode: Int32
    var NumConstituents: Int32
    var ConstitName: InlineArray[String, 15]
    var ConstitMolalFract: InlineArray[Float64, 15]
    var GasLibID: InlineArray[Int32, 15]
    var O2fraction: Float64
    var TairIntoBlower: Float64
    var TairIntoFCPM: Float64
    var PairCompEl: Float64
    var QskinLoss: Float64
    var QintakeRecovery: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.NodeName = ""
        self.SupNodeNum = 0
        self.BlowerPowerCurve = None
        self.BlowerHeatLossFactor = 0.0
        self.AirSupRateMode = 0
        self.Stoics = 0.0
        self.AirFuncPelCurve = None
        self.AirTempCoeff = 0.0
        self.AirFuncNdotCurve = None
        self.IntakeRecoveryMode = 0
        self.ConstituentMode = 0
        self.NumConstituents = 0
        self.ConstitName = InlineArray[String, 15](fill="")
        self.ConstitMolalFract = InlineArray[Float64, 15](fill=0.0)
        self.GasLibID = InlineArray[Int32, 15](fill=GasID.Invalid())
        self.O2fraction = 0.0
        self.TairIntoBlower = 0.0
        self.TairIntoFCPM = 0.0
        self.PairCompEl = 0.0
        self.QskinLoss = 0.0
        self.QintakeRecovery = 0.0


struct FCWaterSupplyDataStruct:
    var Name: String
    var waterTempMode: Int32
    var NodeName: String
    var NodeNum: Int32
    var sched: Optional[OpaquePointer]
    var WaterSupRateCurve: Optional[OpaquePointer]
    var PmpPowerCurve: Optional[OpaquePointer]
    var PmpPowerLossFactor: Float64
    var IsModeled: Bool
    var TwaterIntoCompress: Float64
    var TwaterIntoFCPM: Float64
    var PwaterCompEl: Float64
    var QskinLoss: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.waterTempMode = 0
        self.NodeName = ""
        self.NodeNum = 0
        self.sched = None
        self.WaterSupRateCurve = None
        self.PmpPowerCurve = None
        self.PmpPowerLossFactor = 0.0
        self.IsModeled = True
        self.TwaterIntoCompress = 0.0
        self.TwaterIntoFCPM = 0.0
        self.PwaterCompEl = 0.0
        self.QskinLoss = 0.0


struct FCAuxilHeatDataStruct:
    var Name: String
    var ZoneName: String
    var ZoneID: Int32
    var UASkin: Float64
    var ExcessAirRAT: Float64
    var ANC0: Float64
    var ANC1: Float64
    var SkinLossDestination: Int32
    var MaxPowerW: Float64
    var MinPowerW: Float64
    var MaxPowerkmolperSec: Float64
    var MinPowerkmolperSec: Float64
    var NumConstituents: Int32
    var TauxMix: Float64
    var NdotAuxMix: Float64
    var ConstitMolalFract: InlineArray[Float64, 15]
    var GasLibID: InlineArray[Int32, 15]
    var QskinLoss: Float64
    var QairIntake: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.ZoneName = ""
        self.ZoneID = 0
        self.UASkin = 0.0
        self.ExcessAirRAT = 0.0
        self.ANC0 = 0.0
        self.ANC1 = 0.0
        self.SkinLossDestination = 0
        self.MaxPowerW = 0.0
        self.MinPowerW = 0.0
        self.MaxPowerkmolperSec = 0.0
        self.MinPowerkmolperSec = 0.0
        self.NumConstituents = 0
        self.TauxMix = 0.0
        self.NdotAuxMix = 0.0
        self.ConstitMolalFract = InlineArray[Float64, 15](fill=0.0)
        self.GasLibID = InlineArray[Int32, 15](fill=GasID.Invalid())
        self.QskinLoss = 0.0
        self.QairIntake = 0.0


struct FCExhaustHXDataStruct:
    var Name: String
    var WaterInNodeName: String
    var WaterInNode: Int32
    var WaterOutNodeName: String
    var WaterOutNode: Int32
    var WaterVolumeFlowMax: Float64
    var ExhaustOutNodeName: String
    var ExhaustOutNode: Int32
    var HXmodelMode: Int32
    var HXEffect: Float64
    var hxs0: Float64
    var hxs1: Float64
    var hxs2: Float64
    var hxs3: Float64
    var hxs4: Float64
    var h0gas: Float64
    var NdotGasRef: Float64
    var nCoeff: Float64
    var AreaGas: Float64
    var h0Water: Float64
    var NdotWaterRef: Float64
    var mCoeff: Float64
    var AreaWater: Float64
    var Fadjust: Float64
    var l1Coeff: Float64
    var l2Coeff: Float64
    var CondensationThresholdTemp: Float64
    var qHX: Float64
    var THXexh: Float64
    var WaterMassFlowRateDesign: Float64
    var WaterMassFlowRate: Float64
    var WaterInletTemp: Float64
    var WaterVaporFractExh: Float64
    var CondensateRate: Float64
    var ConstitMolalFract: InlineArray[Float64, 15]
    var GasLibID: InlineArray[Int32, 15]
    var NdotHXleaving: Float64
    var WaterOutletTemp: Float64
    var WaterOutletEnthalpy: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.WaterInNodeName = ""
        self.WaterInNode = 0
        self.WaterOutNodeName = ""
        self.WaterOutNode = 0
        self.WaterVolumeFlowMax = 0.0
        self.ExhaustOutNodeName = ""
        self.ExhaustOutNode = 0
        self.HXmodelMode = 0
        self.HXEffect = 0.0
        self.hxs0 = 0.0
        self.hxs1 = 0.0
        self.hxs2 = 0.0
        self.hxs3 = 0.0
        self.hxs4 = 0.0
        self.h0gas = 0.0
        self.NdotGasRef = 0.0
        self.nCoeff = 0.0
        self.AreaGas = 0.0
        self.h0Water = 0.0
        self.NdotWaterRef = 0.0
        self.mCoeff = 0.0
        self.AreaWater = 0.0
        self.Fadjust = 0.0
        self.l1Coeff = 0.0
        self.l2Coeff = 0.0
        self.CondensationThresholdTemp = 0.0
        self.qHX = 0.0
        self.THXexh = 0.0
        self.WaterMassFlowRateDesign = 0.0
        self.WaterMassFlowRate = 0.0
        self.WaterInletTemp = 0.0
        self.WaterVaporFractExh = 0.0
        self.CondensateRate = 0.0
        self.ConstitMolalFract = InlineArray[Float64, 15](fill=0.0)
        self.GasLibID = InlineArray[Int32, 15](fill=GasID.Invalid())
        self.NdotHXleaving = 0.0
        self.WaterOutletTemp = 0.0
        self.WaterOutletEnthalpy = 0.0


struct BatteryDichargeDataStruct:
    var Name: String
    var NumInSeries: Float64
    var NumInParallel: Float64
    var NominalVoltage: Float64
    var LowVoltsDischarged: Float64
    var NumTablePairs: Int32
    var k: Float64
    var c: Float64
    var qmax: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.NumInSeries = 0.0
        self.NumInParallel = 0.0
        self.NominalVoltage = 0.0
        self.LowVoltsDischarged = 0.0
        self.NumTablePairs = 0
        self.k = 0.0
        self.c = 0.0
        self.qmax = 0.0


struct FCElecStorageDataStruct:
    var Name: String
    var StorageModelMode: Int32
    var StartingEnergyStored: Float64
    var EnergeticEfficCharge: Float64
    var EnergeticEfficDischarge: Float64
    var MaxPowerDraw: Float64
    var MaxPowerStore: Float64
    var NominalVoltage: Float64
    var NominalEnergyCapacity: Float64
    var ThisTimeStepStateOfCharge: Float64
    var LastTimeStepStateOfCharge: Float64
    var PelNeedFromStorage: Float64
    var IdesiredDischargeCurrent: Float64
    var PelFromStorage: Float64
    var IfromStorage: Float64
    var PelIntoStorage: Float64
    var QairIntake: Float64
    var Battery: BatteryDichargeDataStruct
    
    fn __init__(inout self):
        self.Name = ""
        self.StorageModelMode = 0
        self.StartingEnergyStored = 0.0
        self.EnergeticEfficCharge = 0.0
        self.EnergeticEfficDischarge = 0.0
        self.MaxPowerDraw = 0.0
        self.MaxPowerStore = 0.0
        self.NominalVoltage = 0.0
        self.NominalEnergyCapacity = 0.0
        self.ThisTimeStepStateOfCharge = 0.0
        self.LastTimeStepStateOfCharge = 0.0
        self.PelNeedFromStorage = 0.0
        self.IdesiredDischargeCurrent = 0.0
        self.PelFromStorage = 0.0
        self.IfromStorage = 0.0
        self.PelIntoStorage = 0.0
        self.QairIntake = 0.0
        self.Battery = BatteryDichargeDataStruct()


struct FCInverterDataStruct:
    var Name: String
    var EffMode: Int32
    var ConstEff: Float64
    var EffQuadraticCurve: Optional[OpaquePointer]
    var PCUlosses: Float64
    var QairIntake: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.EffMode = 0
        self.ConstEff = 0.0
        self.EffQuadraticCurve = None
        self.PCUlosses = 0.0
        self.QairIntake = 0.0


struct FCReportDataStruct:
    var ACPowerGen: Float64
    var ACEnergyGen: Float64
    var QdotExhaust: Float64
    var TotalHeatEnergyRec: Float64
    var ExhaustEnergyRec: Float64
    var FuelEnergyLHV: Float64
    var FuelEnergyUseRateLHV: Float64
    var FuelEnergyHHV: Float64
    var FuelEnergyUseRateHHV: Float64
    var FuelRateMdot: Float64
    var HeatRecInletTemp: Float64
    var HeatRecOutletTemp: Float64
    var HeatRecMdot: Float64
    var TairInlet: Float64
    var TairIntoFCPM: Float64
    var NdotAir: Float64
    var TotAirInEnthalpy: Float64
    var BlowerPower: Float64
    var BlowerEnergy: Float64
    var BlowerSkinLoss: Float64
    var TfuelInlet: Float64
    var TfuelIntoFCPM: Float64
    var NdotFuel: Float64
    var TotFuelInEnthalpy: Float64
    var FuelCompressPower: Float64
    var FuelCompressEnergy: Float64
    var FuelCompressSkinLoss: Float64
    var TwaterInlet: Float64
    var TwaterIntoFCPM: Float64
    var NdotWater: Float64
    var WaterPumpPower: Float64
    var WaterPumpEnergy: Float64
    var WaterIntoFCPMEnthalpy: Float64
    var TprodGas: Float64
    var EnthalProdGas: Float64
    var NdotProdGas: Float64
    var NdotProdAr: Float64
    var NdotProdCO2: Float64
    var NdotProdH2O: Float64
    var NdotProdN2: Float64
    var NdotProdO2: Float64
    var qHX: Float64
    var HXenergy: Float64
    var THXexh: Float64
    var WaterVaporFractExh: Float64
    var CondensateRate: Float64
    var SeqSubstIterations: Int32
    var RegulaFalsiIterations: Int32
    var ACancillariesPower: Float64
    var ACancillariesEnergy: Float64
    var PCUlosses: Float64
    var DCPowerGen: Float64
    var DCPowerEff: Float64
    var ElectEnergyinStorage: Float64
    var StoredPower: Float64
    var StoredEnergy: Float64
    var DrawnPower: Float64
    var DrawnEnergy: Float64
    var SkinLossPower: Float64
    var SkinLossEnergy: Float64
    var SkinLossConvect: Float64
    var SkinLossRadiat: Float64
    var ElectEfficiency: Float64
    var ThermalEfficiency: Float64
    var OverallEfficiency: Float64
    var ExergyEfficiency: Float64
    var NumCycles: Int32
    var FCPMSkinLoss: Float64
    
    fn __init__(inout self):
        self.ACPowerGen = 0.0
        self.ACEnergyGen = 0.0
        self.QdotExhaust = 0.0
        self.TotalHeatEnergyRec = 0.0
        self.ExhaustEnergyRec = 0.0
        self.FuelEnergyLHV = 0.0
        self.FuelEnergyUseRateLHV = 0.0
        self.FuelEnergyHHV = 0.0
        self.FuelEnergyUseRateHHV = 0.0
        self.FuelRateMdot = 0.0
        self.HeatRecInletTemp = 0.0
        self.HeatRecOutletTemp = 0.0
        self.HeatRecMdot = 0.0
        self.TairInlet = 0.0
        self.TairIntoFCPM = 0.0
        self.NdotAir = 0.0
        self.TotAirInEnthalpy = 0.0
        self.BlowerPower = 0.0
        self.BlowerEnergy = 0.0
        self.BlowerSkinLoss = 0.0
        self.TfuelInlet = 0.0
        self.TfuelIntoFCPM = 0.0
        self.NdotFuel = 0.0
        self.TotFuelInEnthalpy = 0.0
        self.FuelCompressPower = 0.0
        self.FuelCompressEnergy = 0.0
        self.FuelCompressSkinLoss = 0.0
        self.TwaterInlet = 0.0
        self.TwaterIntoFCPM = 0.0
        self.NdotWater = 0.0
        self.WaterPumpPower = 0.0
        self.WaterPumpEnergy = 0.0
        self.WaterIntoFCPMEnthalpy = 0.0
        self.TprodGas = 0.0
        self.EnthalProdGas = 0.0
        self.NdotProdGas = 0.0
        self.NdotProdAr = 0.0
        self.NdotProdCO2 = 0.0
        self.NdotProdH2O = 0.0
        self.NdotProdN2 = 0.0
        self.NdotProdO2 = 0.0
        self.qHX = 0.0
        self.HXenergy = 0.0
        self.THXexh = 0.0
        self.WaterVaporFractExh = 0.0
        self.CondensateRate = 0.0
        self.SeqSubstIterations = 0
        self.RegulaFalsiIterations = 0
        self.ACancillariesPower = 0.0
        self.ACancillariesEnergy = 0.0
        self.PCUlosses = 0.0
        self.DCPowerGen = 0.0
        self.DCPowerEff = 0.0
        self.ElectEnergyinStorage = 0.0
        self.StoredPower = 0.0
        self.StoredEnergy = 0.0
        self.DrawnPower = 0.0
        self.DrawnEnergy = 0.0
        self.SkinLossPower = 0.0
        self.SkinLossEnergy = 0.0
        self.SkinLossConvect = 0.0
        self.SkinLossRadiat = 0.0
        self.ElectEfficiency = 0.0
        self.ThermalEfficiency = 0.0
        self.OverallEfficiency = 0.0
        self.ExergyEfficiency = 0.0
        self.NumCycles = 0
        self.FCPMSkinLoss = 0.0


struct FCStackCoolerDataStruct:
    var Name: String
    var WaterInNodeName: String
    var WaterInNode: Int32
    var WaterOutNodeName: String
    var WaterOutNode: Int32
    var TstackNom: Float64
    var TstackActual: Float64
    var r0: Float64
    var r1: Float64
    var r2: Float64
    var r3: Float64
    var MdotStackCoolant: Float64
    var UAs_cool: Float64
    var Fs_cogen: Float64
    var As_cogen: Float64
    var MdotCogenNom: Float64
    var hCogenNom: Float64
    var ns: Float64
    var PstackPumpEl: Float64
    var PmpPowerLossFactor: Float64
    var f0: Float64
    var f1: Float64
    var f2: Float64
    var StackCoolerPresent: Bool
    var qs_cool: Float64
    var qs_air: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.WaterInNodeName = ""
        self.WaterInNode = 0
        self.WaterOutNodeName = ""
        self.WaterOutNode = 0
        self.TstackNom = 0.0
        self.TstackActual = 0.0
        self.r0 = 0.0
        self.r1 = 0.0
        self.r2 = 0.0
        self.r3 = 0.0
        self.MdotStackCoolant = 0.0
        self.UAs_cool = 0.0
        self.Fs_cogen = 0.0
        self.As_cogen = 0.0
        self.MdotCogenNom = 0.0
        self.hCogenNom = 0.0
        self.ns = 0.0
        self.PstackPumpEl = 0.0
        self.PmpPowerLossFactor = 0.0
        self.f0 = 0.0
        self.f1 = 0.0
        self.f2 = 0.0
        self.StackCoolerPresent = False
        self.qs_cool = 0.0
        self.qs_air = 0.0


struct FCDataStruct:
    var Type: Int32
    var Name: String
    var NameFCPM: String
    var FCPM: FCPowerModuleStruct
    var NameFCAirSup: String
    var AirSup: FCAirSupplyDataStruct
    var NameFCFuelSup: String
    var FuelSupNum: Int32
    var NameFCWaterSup: String
    var WaterSup: FCWaterSupplyDataStruct
    var NameFCAuxilHeat: String
    var AuxilHeat: FCAuxilHeatDataStruct
    var NameExhaustHX: String
    var ExhaustHX: FCExhaustHXDataStruct
    var NameElecStorage: String
    var ElecStorage: FCElecStorageDataStruct
    var NameInverter: String
    var Inverter: FCInverterDataStruct
    var NameStackCooler: String
    var StackCooler: FCStackCoolerDataStruct
    var CWPlantLoc: Optional[OpaquePointer]
    var Report: FCReportDataStruct
    var ACPowerGen: Float64
    var QconvZone: Float64
    var QradZone: Float64
    var DynamicsControlID: Int32
    var TimeElapsed: Float64
    var MyEnvrnFlag_Init: Bool
    var MyWarmupFlag_Init: Bool
    var MyPlantScanFlag_Init: Bool
    var SolverErr_Type1_Iter: Int32
    var SolverErr_Type1_IterIndex: Int32
    var SolverErr_Type2_Iter: Int32
    var SolverErr_Type2_IterIndex: Int32
    
    fn __init__(inout self):
        self.Type = 0
        self.Name = ""
        self.NameFCPM = ""
        self.FCPM = FCPowerModuleStruct()
        self.NameFCAirSup = ""
        self.AirSup = FCAirSupplyDataStruct()
        self.NameFCFuelSup = ""
        self.FuelSupNum = 0
        self.NameFCWaterSup = ""
        self.WaterSup = FCWaterSupplyDataStruct()
        self.NameFCAuxilHeat = ""
        self.AuxilHeat = FCAuxilHeatDataStruct()
        self.NameExhaustHX = ""
        self.ExhaustHX = FCExhaustHXDataStruct()
        self.NameElecStorage = ""
        self.ElecStorage = FCElecStorageDataStruct()
        self.NameInverter = ""
        self.Inverter = FCInverterDataStruct()
        self.NameStackCooler = ""
        self.StackCooler = FCStackCoolerDataStruct()
        self.CWPlantLoc = None
        self.Report = FCReportDataStruct()
        self.ACPowerGen = 0.0
        self.QconvZone = 0.0
        self.QradZone = 0.0
        self.DynamicsControlID = 0
        self.TimeElapsed = 0.0
        self.MyEnvrnFlag_Init = True
        self.MyWarmupFlag_Init = False
        self.MyPlantScanFlag_Init = True
        self.SolverErr_Type1_Iter = 0
        self.SolverErr_Type1_IterIndex = 0
        self.SolverErr_Type2_Iter = 0
        self.SolverErr_Type2_IterIndex = 0


struct FuelCellElectricGeneratorData:
    var NumFuelCellGenerators: Int32
    var getFuelCellInputFlag: Bool
    var MyEnvrnFlag: Bool
    
    fn __init__(inout self):
        self.NumFuelCellGenerators = 0
        self.getFuelCellInputFlag = True
        self.MyEnvrnFlag = True


let CURVE_MODE_NAMES_UC = ("NORMALIZED", "ANNEX42")
let SKIN_LOSS_NAMES_UC = ("CONSTANTRATE", "UAFORPROCESSGASTEMPERATURE", "QUADRATIC FUNCTION OF FUEL RATE")
let AIR_SUP_RATE_MODE_NAMES_UC = ("QUADRATIC FUNCTION OF FUEL RATE", "AIRRATIOBYSTOICS", "QUADRATICFUNCTIONOFELECTRICPOWER")
let RECOVER_MODE_NAMES = ("NoRecovery", "RecoverBurnerInverterStorage", "RecoverAuxiliaryBurner",
                          "RecoverInverterandStorage", "RecoverInverter", "RecoverElectricalStorage")
let RECOVER_MODE_NAMES_UC = ("NORECOVERY", "RECOVERBURNERINVERTERSTORAGE", "RECOVERAUXILIARYBURNER",
                             "RECOVERINVERTERANDSTORAGE", "RECOVERINVERTER", "RECOVERELECTRICALSTORAGE")
let CONSTITUENT_MODE_NAMES = ("AmbientAir", "UserDefinedConstituents")
let CONSTITUENT_MODE_NAMES_UC = ("AMBIENTAIR", "USERDEFINEDCONSTITUENTS")
let WATER_TEMP_MODE_NAMES = ("MainsWaterTemperature", "TemperatureFromAirNode", "TemperatureFromWaterNode", "TemperatureFromSchedule")
let WATER_TEMP_MODE_NAMES_UC = ("MAINSWATERTEMPERATURE", "TEMPERATUREFROMAIRNODE", "TEMPERATUREFROMWATERNODE", "TEMPERATUREFROMSCHEDULE")
let INVERTER_EFFICIENCY_MODE_NAMES = ("Constant", "Quadratic")
let INVERTER_EFFICIENCY_MODE_NAMES_UC = ("CONSTANT", "QUADRATIC")
let EXHAUST_GAS_HX_NAMES = ("FixedEffectiveness", "EmpiricalUAeff", "FundementalUAeff", "Condensing")
let EXHAUST_GAS_HX_NAMES_UC = ("FIXEDEFFECTIVENESS", "EMPIRICALUAEFF", "FUNDEMENTALUAEFF", "CONDENSING")
let LOSS_DESTINATION_NAMES = ("SurroundingZone", "AirInletForFuelCell")
let LOSS_DESTINATION_NAMES_UC = ("SURROUNDINGZONE", "AIRINLETFORFUELCELL")


fn figure_fuel_cell_zone_gains(state: OpaquePointer) -> None:
    pass

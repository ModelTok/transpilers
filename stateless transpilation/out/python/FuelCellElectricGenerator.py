# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state parameter)
# - DataGenerators module (enums: CurveMode, SkinLoss, AirSupRateMode, RecoverMode, ConstituentMode, 
#   WaterTempMode, InverterEfficiencyMode, ExhaustGasHX, LossDestination, ElectricalStorage; 
#   constants: RinKJperMolpK, ImBalanceTol, MinProductGasTemp, MaxProductGasTemp, InitHRTemp)
# - Curve module (GetCurve, CurveValue functions, Curve class)
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
# - PlantComponent base class
# - ShowFatalError, ShowSevereError, ShowSevereInvalidKey, ShowSevereEmptyField, ShowSevereItemNotFound, 
#   ShowWarningError, ShowContinueError, ShowRecurringWarningErrorAtEnd (error/warning functions)

from typing import Any, Protocol, Callable, List, Tuple, Optional
from enum import IntEnum
import math


class GasID(IntEnum):
    Invalid = -1
    CarbonDioxide = 1
    Nitrogen = 2
    Oxygen = 3
    Water = 4
    Argon = 5
    Num = 6


class FCPowerModuleStruct:
    def __init__(self):
        self.Name: str = ""
        self.EffMode: int = 0
        self.EffCurve: Optional[Any] = None
        self.NomEff: float = 0.0
        self.NomPel: float = 0.0
        self.NumCyclesAtStart: int = 0
        self.NumCycles: int = 0
        self.CyclingDegradRat: float = 0.0
        self.NumRunHours: float = 0.0
        self.OperateDegradRat: float = 0.0
        self.ThreshRunHours: float = 0.0
        self.UpTranLimit: float = 0.0
        self.DownTranLimit: float = 0.0
        self.StartUpTime: float = 0.0
        self.StartUpFuel: float = 0.0
        self.StartUpElectConsum: float = 0.0
        self.StartUpElectProd: float = 0.0
        self.ShutDownTime: float = 0.0
        self.ShutDownFuel: float = 0.0
        self.ShutDownElectConsum: float = 0.0
        self.ANC0: float = 0.0
        self.ANC1: float = 0.0
        self.SkinLossMode: int = 0
        self.ZoneName: str = ""
        self.ZoneID: int = 0
        self.RadiativeFract: float = 0.0
        self.QdotSkin: float = 0.0
        self.UAskin: float = 0.0
        self.SkinLossCurve: Optional[Any] = None
        self.WaterSupplyCurve: Optional[Any] = None
        self.NdotDilutionAir: float = 0.0
        self.StackHeatLossToDilution: float = 0.0
        self.DilutionInletNodeName: str = ""
        self.DilutionInletNode: int = 0
        self.DilutionExhaustNodeName: str = ""
        self.DilutionExhaustNode: int = 0
        self.PelMin: float = 0.0
        self.PelMax: float = 0.0
        self.Pel: float = 0.0
        self.PelLastTimeStep: float = 0.0
        self.Eel: float = 0.0
        self.QdotStackCool: float = 0.0
        self.FractionalDayofLastStartUp: float = 0.0
        self.FractionalDayofLastShutDown: float = 0.0
        self.HasBeenOn: bool = True
        self.DuringShutDown: bool = False
        self.DuringStartUp: bool = False
        self.NdotFuel: float = 0.0
        self.TotFuelInEnthalpy: float = 0.0
        self.NdotProdGas: float = 0.0
        self.ConstitMolalFract: List[float] = [0.0] * 15
        self.GasLibID: List[int] = [int(GasID.Invalid)] * 15
        self.TprodGasLeavingFCPM: float = 0.0
        self.NdotAir: float = 0.0
        self.TotAirInEnthalpy: float = 0.0
        self.NdotLiqwater: float = 0.0
        self.TwaterInlet: float = 0.0
        self.WaterInEnthalpy: float = 0.0
        self.DilutionAirInEnthalpy: float = 0.0
        self.DilutionAirOutEnthalpy: float = 0.0
        self.PelancillariesAC: float = 0.0
        self.TotProdGasEnthalpy: float = 0.0
        self.WaterOutEnthalpy: float = 0.0
        self.SeqSubstitIter: int = 0
        self.RegulaFalsiIter: int = 0


class FCAirSupplyDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.NodeName: str = ""
        self.SupNodeNum: int = 0
        self.BlowerPowerCurve: Optional[Any] = None
        self.BlowerHeatLossFactor: float = 0.0
        self.AirSupRateMode: int = 0
        self.Stoics: float = 0.0
        self.AirFuncPelCurve: Optional[Any] = None
        self.AirTempCoeff: float = 0.0
        self.AirFuncNdotCurve: Optional[Any] = None
        self.IntakeRecoveryMode: int = 0
        self.ConstituentMode: int = 0
        self.NumConstituents: int = 0
        self.ConstitName: List[str] = [""] * 15
        self.ConstitMolalFract: List[float] = [0.0] * 15
        self.GasLibID: List[int] = [int(GasID.Invalid)] * 15
        self.O2fraction: float = 0.0
        self.TairIntoBlower: float = 0.0
        self.TairIntoFCPM: float = 0.0
        self.PairCompEl: float = 0.0
        self.QskinLoss: float = 0.0
        self.QintakeRecovery: float = 0.0


class FCWaterSupplyDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.waterTempMode: int = 0
        self.NodeName: str = ""
        self.NodeNum: int = 0
        self.sched: Optional[Any] = None
        self.WaterSupRateCurve: Optional[Any] = None
        self.PmpPowerCurve: Optional[Any] = None
        self.PmpPowerLossFactor: float = 0.0
        self.IsModeled: bool = True
        self.TwaterIntoCompress: float = 0.0
        self.TwaterIntoFCPM: float = 0.0
        self.PwaterCompEl: float = 0.0
        self.QskinLoss: float = 0.0


class FCAuxilHeatDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.ZoneName: str = ""
        self.ZoneID: int = 0
        self.UASkin: float = 0.0
        self.ExcessAirRAT: float = 0.0
        self.ANC0: float = 0.0
        self.ANC1: float = 0.0
        self.SkinLossDestination: int = 0
        self.MaxPowerW: float = 0.0
        self.MinPowerW: float = 0.0
        self.MaxPowerkmolperSec: float = 0.0
        self.MinPowerkmolperSec: float = 0.0
        self.NumConstituents: int = 0
        self.TauxMix: float = 0.0
        self.NdotAuxMix: float = 0.0
        self.ConstitMolalFract: List[float] = [0.0] * 15
        self.GasLibID: List[int] = [int(GasID.Invalid)] * 15
        self.QskinLoss: float = 0.0
        self.QairIntake: float = 0.0


class FCExhaustHXDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.WaterInNodeName: str = ""
        self.WaterInNode: int = 0
        self.WaterOutNodeName: str = ""
        self.WaterOutNode: int = 0
        self.WaterVolumeFlowMax: float = 0.0
        self.ExhaustOutNodeName: str = ""
        self.ExhaustOutNode: int = 0
        self.HXmodelMode: int = 0
        self.HXEffect: float = 0.0
        self.hxs0: float = 0.0
        self.hxs1: float = 0.0
        self.hxs2: float = 0.0
        self.hxs3: float = 0.0
        self.hxs4: float = 0.0
        self.h0gas: float = 0.0
        self.NdotGasRef: float = 0.0
        self.nCoeff: float = 0.0
        self.AreaGas: float = 0.0
        self.h0Water: float = 0.0
        self.NdotWaterRef: float = 0.0
        self.mCoeff: float = 0.0
        self.AreaWater: float = 0.0
        self.Fadjust: float = 0.0
        self.l1Coeff: float = 0.0
        self.l2Coeff: float = 0.0
        self.CondensationThresholdTemp: float = 0.0
        self.qHX: float = 0.0
        self.THXexh: float = 0.0
        self.WaterMassFlowRateDesign: float = 0.0
        self.WaterMassFlowRate: float = 0.0
        self.WaterInletTemp: float = 0.0
        self.WaterVaporFractExh: float = 0.0
        self.CondensateRate: float = 0.0
        self.ConstitMolalFract: List[float] = [0.0] * 15
        self.GasLibID: List[int] = [int(GasID.Invalid)] * 15
        self.NdotHXleaving: float = 0.0
        self.WaterOutletTemp: float = 0.0
        self.WaterOutletEnthalpy: float = 0.0


class BatteryDichargeDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.NumInSeries: float = 0.0
        self.NumInParallel: float = 0.0
        self.NominalVoltage: float = 0.0
        self.LowVoltsDischarged: float = 0.0
        self.NumTablePairs: int = 0
        self.DischargeCurrent: List[float] = []
        self.DischargeTime: List[float] = []
        self.k: float = 0.0
        self.c: float = 0.0
        self.qmax: float = 0.0


class FCElecStorageDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.StorageModelMode: int = 0
        self.StartingEnergyStored: float = 0.0
        self.EnergeticEfficCharge: float = 0.0
        self.EnergeticEfficDischarge: float = 0.0
        self.MaxPowerDraw: float = 0.0
        self.MaxPowerStore: float = 0.0
        self.NominalVoltage: float = 0.0
        self.NominalEnergyCapacity: float = 0.0
        self.ThisTimeStepStateOfCharge: float = 0.0
        self.LastTimeStepStateOfCharge: float = 0.0
        self.PelNeedFromStorage: float = 0.0
        self.IdesiredDischargeCurrent: float = 0.0
        self.PelFromStorage: float = 0.0
        self.IfromStorage: float = 0.0
        self.PelIntoStorage: float = 0.0
        self.QairIntake: float = 0.0
        self.Battery: BatteryDichargeDataStruct = BatteryDichargeDataStruct()


class FCInverterDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.EffMode: int = 0
        self.ConstEff: float = 0.0
        self.EffQuadraticCurve: Optional[Any] = None
        self.PCUlosses: float = 0.0
        self.QairIntake: float = 0.0


class FCReportDataStruct:
    def __init__(self):
        self.ACPowerGen: float = 0.0
        self.ACEnergyGen: float = 0.0
        self.QdotExhaust: float = 0.0
        self.TotalHeatEnergyRec: float = 0.0
        self.ExhaustEnergyRec: float = 0.0
        self.FuelEnergyLHV: float = 0.0
        self.FuelEnergyUseRateLHV: float = 0.0
        self.FuelEnergyHHV: float = 0.0
        self.FuelEnergyUseRateHHV: float = 0.0
        self.FuelRateMdot: float = 0.0
        self.HeatRecInletTemp: float = 0.0
        self.HeatRecOutletTemp: float = 0.0
        self.HeatRecMdot: float = 0.0
        self.TairInlet: float = 0.0
        self.TairIntoFCPM: float = 0.0
        self.NdotAir: float = 0.0
        self.TotAirInEnthalpy: float = 0.0
        self.BlowerPower: float = 0.0
        self.BlowerEnergy: float = 0.0
        self.BlowerSkinLoss: float = 0.0
        self.TfuelInlet: float = 0.0
        self.TfuelIntoFCPM: float = 0.0
        self.NdotFuel: float = 0.0
        self.TotFuelInEnthalpy: float = 0.0
        self.FuelCompressPower: float = 0.0
        self.FuelCompressEnergy: float = 0.0
        self.FuelCompressSkinLoss: float = 0.0
        self.TwaterInlet: float = 0.0
        self.TwaterIntoFCPM: float = 0.0
        self.NdotWater: float = 0.0
        self.WaterPumpPower: float = 0.0
        self.WaterPumpEnergy: float = 0.0
        self.WaterIntoFCPMEnthalpy: float = 0.0
        self.TprodGas: float = 0.0
        self.EnthalProdGas: float = 0.0
        self.NdotProdGas: float = 0.0
        self.NdotProdAr: float = 0.0
        self.NdotProdCO2: float = 0.0
        self.NdotProdH2O: float = 0.0
        self.NdotProdN2: float = 0.0
        self.NdotProdO2: float = 0.0
        self.qHX: float = 0.0
        self.HXenergy: float = 0.0
        self.THXexh: float = 0.0
        self.WaterVaporFractExh: float = 0.0
        self.CondensateRate: float = 0.0
        self.SeqSubstIterations: int = 0
        self.RegulaFalsiIterations: int = 0
        self.ACancillariesPower: float = 0.0
        self.ACancillariesEnergy: float = 0.0
        self.PCUlosses: float = 0.0
        self.DCPowerGen: float = 0.0
        self.DCPowerEff: float = 0.0
        self.ElectEnergyinStorage: float = 0.0
        self.StoredPower: float = 0.0
        self.StoredEnergy: float = 0.0
        self.DrawnPower: float = 0.0
        self.DrawnEnergy: float = 0.0
        self.SkinLossPower: float = 0.0
        self.SkinLossEnergy: float = 0.0
        self.SkinLossConvect: float = 0.0
        self.SkinLossRadiat: float = 0.0
        self.ElectEfficiency: float = 0.0
        self.ThermalEfficiency: float = 0.0
        self.OverallEfficiency: float = 0.0
        self.ExergyEfficiency: float = 0.0
        self.NumCycles: int = 0
        self.FCPMSkinLoss: float = 0.0


class FCStackCoolerDataStruct:
    def __init__(self):
        self.Name: str = ""
        self.WaterInNodeName: str = ""
        self.WaterInNode: int = 0
        self.WaterOutNodeName: str = ""
        self.WaterOutNode: int = 0
        self.TstackNom: float = 0.0
        self.TstackActual: float = 0.0
        self.r0: float = 0.0
        self.r1: float = 0.0
        self.r2: float = 0.0
        self.r3: float = 0.0
        self.MdotStackCoolant: float = 0.0
        self.UAs_cool: float = 0.0
        self.Fs_cogen: float = 0.0
        self.As_cogen: float = 0.0
        self.MdotCogenNom: float = 0.0
        self.hCogenNom: float = 0.0
        self.ns: float = 0.0
        self.PstackPumpEl: float = 0.0
        self.PmpPowerLossFactor: float = 0.0
        self.f0: float = 0.0
        self.f1: float = 0.0
        self.f2: float = 0.0
        self.StackCoolerPresent: bool = False
        self.qs_cool: float = 0.0
        self.qs_air: float = 0.0


class FCDataStruct:
    def __init__(self):
        self.Type: int = 0
        self.Name: str = ""
        self.NameFCPM: str = ""
        self.FCPM: FCPowerModuleStruct = FCPowerModuleStruct()
        self.NameFCAirSup: str = ""
        self.AirSup: FCAirSupplyDataStruct = FCAirSupplyDataStruct()
        self.NameFCFuelSup: str = ""
        self.FuelSupNum: int = 0
        self.NameFCWaterSup: str = ""
        self.WaterSup: FCWaterSupplyDataStruct = FCWaterSupplyDataStruct()
        self.NameFCAuxilHeat: str = ""
        self.AuxilHeat: FCAuxilHeatDataStruct = FCAuxilHeatDataStruct()
        self.NameExhaustHX: str = ""
        self.ExhaustHX: FCExhaustHXDataStruct = FCExhaustHXDataStruct()
        self.NameElecStorage: str = ""
        self.ElecStorage: FCElecStorageDataStruct = FCElecStorageDataStruct()
        self.NameInverter: str = ""
        self.Inverter: FCInverterDataStruct = FCInverterDataStruct()
        self.NameStackCooler: str = ""
        self.StackCooler: FCStackCoolerDataStruct = FCStackCoolerDataStruct()
        self.CWPlantLoc: Optional[Any] = None
        self.Report: FCReportDataStruct = FCReportDataStruct()
        self.ACPowerGen: float = 0.0
        self.QconvZone: float = 0.0
        self.QradZone: float = 0.0
        self.DynamicsControlID: int = 0
        self.TimeElapsed: float = 0.0
        self.MyEnvrnFlag_Init: bool = True
        self.MyWarmupFlag_Init: bool = False
        self.MyPlantScanFlag_Init: bool = True
        self.SolverErr_Type1_Iter: int = 0
        self.SolverErr_Type1_IterIndex: int = 0
        self.SolverErr_Type2_Iter: int = 0
        self.SolverErr_Type2_IterIndex: int = 0

    def factory(self, state: Any, object_name: str) -> "FCDataStruct":
        if state.dataFuelCellElectGen.getFuelCellInputFlag:
            get_fuel_cell_input(state)
            state.dataFuelCellElectGen.getFuelCellInputFlag = False
        
        for fc in state.dataFuelCellElectGen.FuelCell:
            if fc.Name == object_name:
                return fc
        
        raise RuntimeError(f"LocalFuelCellGenFactory: Error getting inputs for object named: {object_name}")

    def factory_exhaust(self, state: Any, object_name: str) -> "FCDataStruct":
        if state.dataFuelCellElectGen.getFuelCellInputFlag:
            get_fuel_cell_input(state)
            state.dataFuelCellElectGen.getFuelCellInputFlag = False
        
        for fc in state.dataFuelCellElectGen.FuelCell:
            if fc.NameExhaustHX.upper() == object_name.upper():
                return fc
        
        raise RuntimeError(f"LocalFuelCellGenFactory: Error getting inputs for object named: {object_name}")


class FuelCellElectricGeneratorData:
    def __init__(self):
        self.NumFuelCellGenerators: int = 0
        self.getFuelCellInputFlag: bool = True
        self.MyEnvrnFlag: bool = True
        self.FuelCell: List[FCDataStruct] = []


CURVE_MODE_NAMES_UC = ("NORMALIZED", "ANNEX42")
SKIN_LOSS_NAMES_UC = ("CONSTANTRATE", "UAFORPROCESSGASTEMPERATURE", "QUADRATIC FUNCTION OF FUEL RATE")
AIR_SUP_RATE_MODE_NAMES_UC = ("QUADRATIC FUNCTION OF FUEL RATE", "AIRRATIOBYSTOICS", "QUADRATICFUNCTIONOFELECTRICPOWER")
RECOVER_MODE_NAMES = ("NoRecovery", "RecoverBurnerInverterStorage", "RecoverAuxiliaryBurner", 
                      "RecoverInverterandStorage", "RecoverInverter", "RecoverElectricalStorage")
RECOVER_MODE_NAMES_UC = ("NORECOVERY", "RECOVERBURNERINVERTERSTORAGE", "RECOVERAUXILIARYBURNER",
                         "RECOVERINVERTERANDSTORAGE", "RECOVERINVERTER", "RECOVERELECTRICALSTORAGE")
CONSTITUENT_MODE_NAMES = ("AmbientAir", "UserDefinedConstituents")
CONSTITUENT_MODE_NAMES_UC = ("AMBIENTAIR", "USERDEFINEDCONSTITUENTS")
WATER_TEMP_MODE_NAMES = ("MainsWaterTemperature", "TemperatureFromAirNode", "TemperatureFromWaterNode", "TemperatureFromSchedule")
WATER_TEMP_MODE_NAMES_UC = ("MAINSWATERTEMPERATURE", "TEMPERATUREFROMAIRNODE", "TEMPERATUREFROMWATERNODE", "TEMPERATUREFROMSCHEDULE")
INVERTER_EFFICIENCY_MODE_NAMES = ("Constant", "Quadratic")
INVERTER_EFFICIENCY_MODE_NAMES_UC = ("CONSTANT", "QUADRATIC")
EXHAUST_GAS_HX_NAMES = ("FixedEffectiveness", "EmpiricalUAeff", "FundementalUAeff", "Condensing")
EXHAUST_GAS_HX_NAMES_UC = ("FIXEDEFFECTIVENESS", "EMPIRICALUAEFF", "FUNDEMENTALUAEFF", "CONDENSING")
LOSS_DESTINATION_NAMES = ("SurroundingZone", "AirInletForFuelCell")
LOSS_DESTINATION_NAMES_UC = ("SURROUNDINGZONE", "AIRINLETFORFUELCELL")


def get_fuel_cell_input(state: Any) -> None:
    s_ipsc = state.dataIPShortCut
    s_ipsc.cCurrentModuleObject = "Generator:FuelCell"
    state.dataFuelCellElectGen.NumFuelCellGenerators = \
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, s_ipsc.cCurrentModuleObject)
    
    if state.dataFuelCellElectGen.NumFuelCellGenerators <= 0:
        raise RuntimeError(f"No {s_ipsc.cCurrentModuleObject} equipment specified in input file")
    
    state.dataFuelCellElectGen.FuelCell = [FCDataStruct() for _ in range(state.dataFuelCellElectGen.NumFuelCellGenerators)]
    
    AlphArray = [""] * 25
    NumArray = [0.0] * 200
    
    for GeneratorNum in range(state.dataFuelCellElectGen.NumFuelCellGenerators):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, s_ipsc.cCurrentModuleObject, GeneratorNum + 1, AlphArray, 25, NumArray, 200, None,
            None, None, s_ipsc.cAlphaFieldNames, s_ipsc.cNumericFieldNames)
        
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].Name = AlphArray[0]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameFCPM = AlphArray[1]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameFCAirSup = AlphArray[2]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameFCFuelSup = AlphArray[3]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameFCWaterSup = AlphArray[4]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameFCAuxilHeat = AlphArray[5]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameExhaustHX = AlphArray[6]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameElecStorage = AlphArray[7]
        state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameInverter = AlphArray[8]
        if len(AlphArray) > 9:
            state.dataFuelCellElectGen.FuelCell[GeneratorNum].NameStackCooler = AlphArray[9]


def figure_fuel_cell_zone_gains(state: Any) -> None:
    if state.dataFuelCellElectGen.NumFuelCellGenerators == 0:
        return
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataFuelCellElectGen.MyEnvrnFlag:
        for fuel_supply in state.dataGenerator.FuelSupply:
            fuel_supply.QskinLoss = 0.0
        state.dataFuelCellElectGen.MyEnvrnFlag = False
        
        for cell in state.dataFuelCellElectGen.FuelCell:
            cell.FCPM.HasBeenOn = False
            cell.AirSup.PairCompEl = 0.0
            cell.QconvZone = 0.0
            cell.QradZone = 0.0
            cell.AirSup.QskinLoss = 0.0
            cell.WaterSup.QskinLoss = 0.0
            cell.AuxilHeat.QskinLoss = 0.0
            cell.Report.SkinLossConvect = 0.0
            cell.Report.SkinLossRadiat = 0.0
            cell.AuxilHeat.QairIntake = 0.0
            cell.ElecStorage.QairIntake = 0.0
            cell.Inverter.QairIntake = 0.0
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataFuelCellElectGen.MyEnvrnFlag = True
    
    for FCnum in range(state.dataFuelCellElectGen.NumFuelCellGenerators):
        thisFC = state.dataFuelCellElectGen.FuelCell[FCnum]
        TotalZoneHeatGain = (thisFC.AirSup.QskinLoss + 
                            state.dataGenerator.FuelSupply[thisFC.FuelSupNum].QskinLoss +
                            thisFC.WaterSup.QskinLoss + thisFC.AuxilHeat.QskinLoss +
                            thisFC.FCPM.QdotSkin)
        
        thisFC.QconvZone = TotalZoneHeatGain * (1 - thisFC.FCPM.RadiativeFract)
        thisFC.Report.SkinLossConvect = thisFC.QconvZone
        thisFC.QradZone = TotalZoneHeatGain * thisFC.FCPM.RadiativeFract
        thisFC.Report.SkinLossRadiat = thisFC.QradZone

from BaseData import BaseGlobalStruct
from ...IOFiles import IOFiles
from ...DataAirLoopData import DataAirLoopData
from ...AirLoopHVACDOASData import AirLoopHVACDOASData
from ...AirSystemsData import AirSystemsData
from ...AirflowNetwork import Solver as AirflowNetworkSolver
from ...BSDFWindowData import BSDFWindowData
from ...BaseSizerWithFanHeatInputsData import BaseSizerWithFanHeatInputsData
from ...BaseSizerWithScalableInputsData import BaseSizerWithScalableInputsData
from ...BaseboardElectricData import BaseboardElectricData
from ...BaseboardRadiatorData import BaseboardRadiatorData
from ...BoilerSteamData import BoilerSteamData
from ...BoilersData import BoilersData
from ...BranchInputManagerData import BranchInputManagerData
from ...BranchNodeConnectionsData import BranchNodeConnectionsData
from ...CTElectricGeneratorData import CTElectricGeneratorData
from ...ChilledCeilingPanelSimpleData import ChilledCeilingPanelSimpleData
from ...ChillerAbsorberData import ChillerAbsorberData
from ...ChillerElectricEIRData import ChillerElectricEIRData
from ...ChillerExhaustAbsorptionData import ChillerExhaustAbsorptionData
from ...ChillerGasAbsorptionData import ChillerGasAbsorptionData
from ...ChillerIndirectAbsoprtionData import ChillerIndirectAbsoprtionData
from ...ChillerReformulatedEIRData import ChillerReformulatedEIRData
from ...ChillerElectricASHRAE205Data import ChillerElectricASHRAE205Data
from ...CoilCoolingDXData import CoilCoolingDXData
from ...CondenserLoopTowersData import CondenserLoopTowersData
from ...ConstructionData import ConstructionData
from ...ContaminantBalanceData import ContaminantBalanceData
from ...ConvectionCoefficientsData import ConvectionCoefficientsData
from ...ConvergParamsData import ConvergParamsData
from ...CoolTowerData import CoolTowerData
from ...CostEstimateManagerData import CostEstimateManagerData
from ...CrossVentMgrData import CrossVentMgrData
from ...CurveManagerData import CurveManagerData
from ...DXCoilsData import DXCoilsData
from ...DXFEarClippingData import DXFEarClippingData
from ...DataBranchAirLoopPlantData import DataBranchAirLoopPlantData
from ...DataDaylightingDevicesData import DataDaylightingDevicesData
from ...DataGlobal import DataGlobal
from ...DataInputProcessing import DataInputProcessing
from ...DataPlantData import DataPlantData
from ...DataStringGlobalsData import DataStringGlobalsData
from ...DataTimingsData import DataTimingsData
from ...DataWaterData import DataWaterData
from ...DataZoneControlsData import DataZoneControlsData
from ...DataZoneEnergyDemandsData import DataZoneEnergyDemandsData
from ...DataZoneEquipmentData import DataZoneEquipmentData
from ...DaylightingDevicesData import DaylightingDevicesData
from ...DaylightingData import DaylightingData
from ...DefineEquipData import DefineEquipData
from ...DemandManagerData import DemandManagerData
from ...DesiccantDehumidifiersData import DesiccantDehumidifiersData
from ...DisplacementVentMgrData import DisplacementVentMgrData
from ...DualDuctData import DualDuctData
from ...DuctLossData import DuctLossData
from ...EIRFuelFiredHeatPumpsData import EIRFuelFiredHeatPumpsData
from ...EIRPlantLoopHeatPumpsData import EIRPlantLoopHeatPumpsData
from ...HeatPumpAirToWatersData import HeatPumpAirToWatersData
from ...EMSManagerData import EMSManagerData
from ...EarthTubeData import EarthTubeData
from ...EcoRoofManagerData import EcoRoofManagerData
from ...EconomicLifeCycleCostData import EconomicLifeCycleCostData
from ...EconomicTariffData import EconomicTariffData
from ...ElectPwrSvcMgrData import ElectPwrSvcMgrData
from ...ElectricBaseboardRadiatorData import ElectricBaseboardRadiatorData
from ...EnvironmentData import EnvironmentData
from ...ErrorTrackingData import ErrorTrackingData
from ...EvaporativeCoolersData import EvaporativeCoolersData
from ...EvaporativeFluidCoolersData import EvaporativeFluidCoolersData
from ...ExteriorEnergyUseData import ExteriorEnergyUseData
from ...ExternalInterfaceData import ExternalInterfaceData
from ...FanCoilUnitsData import FanCoilUnitsData
from ...FansData import FansData
from ...FaultsManagerData import FaultsManagerData
from ...FluidCoolersData import FluidCoolersData
from ...FluidData import FluidData
from ...FourPipeBeamData import FourPipeBeamData
from ...FuelCellElectricGeneratorData import FuelCellElectricGeneratorData
from ...FurnacesData import FurnacesData
from ...GeneralData import GeneralData
from ...GeneralRoutinesData import GeneralRoutinesData
from ...GeneratorFuelSupplyData import GeneratorFuelSupplyData
from ...GeneratorsData import GeneratorsData
from ...GlobalNamesData import GlobalNamesData
from ...GroundHeatExchangerData import GroundHeatExchangerData
from ...GroundTemperatureManagerData import GroundTemperatureManagerData
from ...HVACControllersData import HVACControllersData
from ...HVACCooledBeamData import HVACCooledBeamData
from ...HVACCtrlData import HVACCtrlData
from ...HVACDXHeatPumpSystemData import HVACDXHeatPumpSystemData
from ...HVACDuctData import HVACDuctData
from ...HVACGlobalsData import HVACGlobalsData
from ...HVACHXAssistedCoolingCoilData import HVACHXAssistedCoolingCoilData
from ...HVACInterfaceManagerData import HVACInterfaceManagerData
from ...HVACManagerData import HVACManagerData
from ...HVACMultiSpeedHeatPumpData import HVACMultiSpeedHeatPumpData
from ...HVACSingleDuctInducData import HVACSingleDuctInducData
from ...HVACSizingSimMgrData import HVACSizingSimMgrData
from ...HVACStandAloneERVData import HVACStandAloneERVData
from ...HVACUnitaryBypassVAVData import HVACUnitaryBypassVAVData
from ...HVACVarRefFlowData import HVACVarRefFlowData
from ...HWBaseboardRadiatorData import HWBaseboardRadiatorData
from ...HeatBalFanSysData import HeatBalFanSysData
from ...HeatBalFiniteDiffMgr import HeatBalFiniteDiffMgr
from ...HeatBalHAMTMgrData import HeatBalHAMTMgrData
from ...HeatBalInternalHeatGainsData import HeatBalInternalHeatGainsData
from ...HeatBalSurfData import HeatBalSurfData
from ...HeatBalSurfMgr import HeatBalSurfMgr
from ...HeatBalanceAirMgrData import HeatBalanceAirMgrData
from ...HeatBalanceData import HeatBalanceData
from ...HeatBalanceIntRadExchgData import HeatBalanceIntRadExchgData
from ...HeatBalanceMgrData import HeatBalanceMgrData
from ...HeatPumpWaterToWaterCOOLINGData import HeatPumpWaterToWaterCOOLINGData
from ...HeatPumpWaterToWaterHEATINGData import HeatPumpWaterToWaterHEATINGData
from ...HeatPumpWaterToWaterSimpleData import HeatPumpWaterToWaterSimpleData
from ...HeatRecoveryData import HeatRecoveryData
from ...HeatingCoilsData import HeatingCoilsData
from ...HighTempRadiantSystemData import HighTempRadiantSystemData
from ...HumidifiersData import HumidifiersData
from ...HybridModelData import HybridModelData
from ...HybridUnitaryAirConditionersData import HybridUnitaryAirConditionersData
from ...HysteresisPhaseChangeData import HysteresisPhaseChangeData
from ...ICEngineElectricGeneratorData import ICEngineElectricGeneratorData
from ...IPShortCutsData import IPShortCutsData
from ...IceThermalStorageData import IceThermalStorageData
from ...IndoorGreenData import IndoorGreenData
from ...IntegratedHeatPumpGlobalData import IntegratedHeatPumpGlobalData
from ...InternalHeatGainsData import InternalHeatGainsData
from ...LoopNodeData import LoopNodeData
from ...LowTempRadiantSystemData import LowTempRadiantSystemData
from ...MaterialData import MaterialData
from ...MatrixDataManagerData import MatrixDataManagerData
from ...MicroCHPElectricGeneratorData import MicroCHPElectricGeneratorData
from ...MicroturbineElectricGeneratorData import MicroturbineElectricGeneratorData
from ...MixedAirData import MixedAirData
from ...MixerComponentData import MixerComponentData
from ...MoistureBalanceData import MoistureBalanceData
from ...MoistureBalanceEMPDData import MoistureBalanceEMPDData
from ...MoistureBalanceEMPDManagerData import MoistureBalanceEMPDManagerData
from ...MundtSimMgrData import MundtSimMgrData
from ...NodeInputManagerData import NodeInputManagerData
from ...OutAirNodeManagerData import OutAirNodeManagerData
from ...OutdoorAirUnitData import OutdoorAirUnitData
from ...OutputProcessorData import OutputProcessorData
from ...OutputReportPredefinedData import OutputReportPredefinedData
from ...OutputReportTabularAnnualData import OutputReportTabularAnnualData
from ...OutputReportTabularData import OutputReportTabularData
from ...OutputReportsData import OutputReportsData
from ...OutputsData import OutputsData
from ...OutsideEnergySourcesData import OutsideEnergySourcesData
from ...PackagedThermalStorageCoilData import PackagedThermalStorageCoilData
from ...PhotovoltaicStateData import PhotovoltaicStateData
from ...PhotovoltaicThermalCollectorsData import PhotovoltaicThermalCollectorsData
from ...PhotovoltaicsData import PhotovoltaicsData
from ...PipeHeatTransferData import PipeHeatTransferData
from ...PipesData import PipesData
from ...PlantCentralGSHPData import PlantCentralGSHPData
from ...PlantChillersData import PlantChillersData
from ...PlantCompTempSrcData import PlantCompTempSrcData
from ...PlantCondLoopOperationData import PlantCondLoopOperationData
from ...PlantHeatExchangerFluidToFluidData import PlantHeatExchangerFluidToFluidData
from ...PlantLoadProfileData import PlantLoadProfileData
from ...PlantMgrData import PlantMgrData
from ...PlantPipingSysMgrData import PlantPipingSysMgrData
from ...PlantPressureSysData import PlantPressureSysData
from ...PlantUtilitiesData import PlantUtilitiesData
from ...PlantValvesData import PlantValvesData
from ...PluginManagerData import PluginManagerData
from ...PollutionData import PollutionData
from ...PondGroundHeatExchangerData import PondGroundHeatExchangerData
from ...PoweredInductionUnitsData import PoweredInductionUnitsData
from ...PsychrometricsData import PsychrometricsData
from ...PsychrometricCacheData import PsychrometricCacheData
from ...PumpsData import PumpsData
from ...PurchasedAirManagerData import PurchasedAirManagerData
from ...RefrigeratedCaseData import RefrigeratedCaseData
from ...ReportCoilSelectionData import ReportCoilSelectionData
from ...ReportFlagData import ReportFlagData
from ...ResultsFrameworkData import ResultsFrameworkData
from ...ReturnAirPathMgr import ReturnAirPathMgr
from ...ExhaustAirSystemMgr import ExhaustAirSystemMgr
from ...ExhaustControlSystemMgr import ExhaustControlSystemMgr
from ...RoomAirModelAirflowNetworkData import RoomAirModelAirflowNetworkData
from ...RoomAirModelData import RoomAirModelData
from ...RoomAirModelUserTempPatternData import RoomAirModelUserTempPatternData
from ...RootFindingData import RootFindingData
from ...RuntimeLanguageData import RuntimeLanguageData
from ...RuntimeLanguageProcessorData import RuntimeLanguageProcessorData
from ...SQLiteProceduresData import SQLiteProceduresData
from ...ScheduleManagerData import ScheduleManagerData
from ...SetPointManagerData import SetPointManagerData
from ...ShadowCombData import ShadowCombData
from ...SimAirServingZonesData import SimAirServingZonesData
from ...SimulationManagerData import SimulationManagerData
from ...SingleDuctData import SingleDuctData
from ...SizingData import SizingData
from ...SizingManagerData import SizingManagerData
from ...SolarCollectorsData import SolarCollectorsData
from ...SolarReflectionManagerData import SolarReflectionManagerData
from ...SolarShadingData import SolarShadingData
from ...SplitterComponentData import SplitterComponentData
from ...SteamBaseboardRadiatorData import SteamBaseboardRadiatorData
from ...SteamCoilsData import SteamCoilsData
from ...SurfaceColorData import SurfaceColorData
from ...SurfaceGeometryData import SurfaceGeometryData
from ...SurfaceGroundHeatExchangersData import SurfaceGroundHeatExchangersData
from ...SurfaceListsData import SurfaceListsData
from ...SurfacesData import SurfacesData
from ...SwimmingPoolsData import SwimmingPoolsData
from ...SystemAirFlowSizerData import SystemAirFlowSizerData
from ...SystemAvailabilityManagerData import SystemAvailabilityManagerData
from ...SystemReportsData import SystemReportsData
from ...SystemVarsData import SystemVarsData
from ...TARCOGCommonData import TARCOGCommonData
from ...TARCOGOutputData import TARCOGOutputData
from ...ThermalChimneysData import ThermalChimneysData
from ...ThermalComfortsData import ThermalComfortsData
from ...ThermalISO15099CalcData import ThermalISO15099CalcData
from ...TARCOGGasses90Data import TARCOGGasses90Data
from ...TARCOGMainData import TARCOGMainData
from ...TarcogShadingData import TarcogShadingData
from ...TranspiredCollectorData import TranspiredCollectorData
from ...UFADManagerData import UFADManagerData
from ...UnitHeatersData import UnitHeatersData
from ...UnitVentilatorsData import UnitVentilatorsData
from ...UnitarySystemsData import UnitarySystemsData
from ...UserDefinedComponentsData import UserDefinedComponentsData
from ...UtilityRoutinesData import UtilityRoutinesData
from ...VariableSpeedCoilsData import VariableSpeedCoilsData
from ...VectorsData import VectorsData
from ...VentilatedSlabData import VentilatedSlabData
from ...ViewFactorInfoData import ViewFactorInfoData
from ...WaterCoilsData import WaterCoilsData
from ...WaterManagerData import WaterManagerData
from ...WaterThermalTanksData import WaterThermalTanksData
from ...WaterToAirHeatPumpData import WaterToAirHeatPumpData
from ...WaterToAirHeatPumpSimpleData import WaterToAirHeatPumpSimpleData
from ...WaterUseData import WaterUseData
from ...WeatherManagerData import WeatherManagerData
from ...WindTurbineData import WindTurbineData
from ...WindowACData import WindowACData
from ...WindowComplexManagerData import WindowComplexManagerData
from ...WindowEquivLayerData import WindowEquivLayerData
from ...WindowEquivalentLayerData import WindowEquivalentLayerData
from ...WindowManagerData import WindowManagerData
from ...WindowManagerExteriorData import WindowManagerExteriorData
from ...ZoneAirLoopEquipmentManagerData import ZoneAirLoopEquipmentManagerData
from ...ZoneContaminantPredictorCorrectorData import ZoneContaminantPredictorCorrectorData
from ...ZoneDehumidifierData import ZoneDehumidifierData
from ...ZoneEquipmentManagerData import ZoneEquipmentManagerData
from ...ZonePlenumData import ZonePlenumData
from ...ZoneTempPredictorCorrectorData import ZoneTempPredictorCorrectorData
from mojo.owning import Owned
struct EnergyPlusData(BaseGlobalStruct):
    var ready: Bool = True
    var files: IOFiles
    var dataAirLoopHVACDOAS: Owned[AirLoopHVACDOASData]
    var dataAirSystemsData: Owned[AirSystemsData]
    var afn: Owned[AirflowNetworkSolver]
    var dataBSDFWindow: Owned[BSDFWindowData]
    var dataBaseSizerFanHeatInputs: Owned[BaseSizerWithFanHeatInputsData]
    var dataBaseSizerScalableInputs: Owned[BaseSizerWithScalableInputsData]
    var dataBaseboardElectric: Owned[BaseboardElectricData]
    var dataBaseboardRadiator: Owned[BaseboardRadiatorData]
    var dataBoilerSteam: Owned[BoilerSteamData]
    var dataBoilers: Owned[BoilersData]
    var dataBranchInputManager: Owned[BranchInputManagerData]
    var dataBranchNodeConnections: Owned[BranchNodeConnectionsData]
    var dataCTElectricGenerator: Owned[CTElectricGeneratorData]
    var dataChilledCeilingPanelSimple: Owned[ChilledCeilingPanelSimpleData]
    var dataChillerAbsorber: Owned[ChillerAbsorberData]
    var dataChillerElectricEIR: Owned[ChillerElectricEIRData]
    var dataChillerExhaustAbsorption: Owned[ChillerExhaustAbsorptionData]
    var dataChillerGasAbsorption: Owned[ChillerGasAbsorptionData]
    var dataChillerIndirectAbsorption: Owned[ChillerIndirectAbsoprtionData]
    var dataChillerReformulatedEIR: Owned[ChillerReformulatedEIRData]
    var dataChillerElectricASHRAE205: Owned[ChillerElectricASHRAE205Data]
    var dataCoilCoolingDX: Owned[CoilCoolingDXData]
    var dataCondenserLoopTowers: Owned[CondenserLoopTowersData]
    var dataConstruction: Owned[ConstructionData]
    var dataContaminantBalance: Owned[ContaminantBalanceData]
    var dataConvect: Owned[ConvectionCoefficientsData]
    var dataConvergeParams: Owned[ConvergParamsData]
    var dataCoolTower: Owned[CoolTowerData]
    var dataCostEstimateManager: Owned[CostEstimateManagerData]
    var dataCrossVentMgr: Owned[CrossVentMgrData]
    var dataCurveManager: Owned[CurveManagerData]
    var dataDXCoils: Owned[DXCoilsData]
    var dataDXFEarClipping: Owned[DXFEarClippingData]
    var dataAirLoop: Owned[DataAirLoopData]
    var dataBranchAirLoopPlant: Owned[DataBranchAirLoopPlantData]
    var dataDaylightingDevicesData: Owned[DataDaylightingDevicesData]
    var dataGlobal: Owned[DataGlobal]
    var dataInputProcessing: Owned[DataInputProcessing]
    var dataPlnt: Owned[DataPlantData]
    var dataStrGlobals: Owned[DataStringGlobalsData]
    var dataTimingsData: Owned[DataTimingsData]
    var dataWaterData: Owned[DataWaterData]
    var dataZoneCtrls: Owned[DataZoneControlsData]
    var dataZoneEnergyDemand: Owned[DataZoneEnergyDemandsData]
    var dataZoneEquip: Owned[DataZoneEquipmentData]
    var dataDaylightingDevices: Owned[DaylightingDevicesData]
    var dataDayltg: Owned[DaylightingData]
    var dataDefineEquipment: Owned[DefineEquipData]
    var dataDemandManager: Owned[DemandManagerData]
    var dataDesiccantDehumidifiers: Owned[DesiccantDehumidifiersData]
    var dataDispVentMgr: Owned[DisplacementVentMgrData]
    var dataDualDuct: Owned[DualDuctData]
    var dataDuctLoss: Owned[DuctLossData]
    var dataEIRFuelFiredHeatPump: Owned[EIRFuelFiredHeatPumpsData]
    var dataEIRPlantLoopHeatPump: Owned[EIRPlantLoopHeatPumpsData]
    var dataHeatPumpAirToWater: Owned[HeatPumpAirToWatersData]
    var dataEMSMgr: Owned[EMSManagerData]
    var dataEarthTube: Owned[EarthTubeData]
    var dataEcoRoofMgr: Owned[EcoRoofManagerData]
    var dataEconLifeCycleCost: Owned[EconomicLifeCycleCostData]
    var dataEconTariff: Owned[EconomicTariffData]
    var dataElectPwrSvcMgr: Owned[ElectPwrSvcMgrData]
    var dataElectBaseboardRad: Owned[ElectricBaseboardRadiatorData]
    var dataEnvrn: Owned[EnvironmentData]
    var dataErrTracking: Owned[ErrorTrackingData]
    var dataEvapCoolers: Owned[EvaporativeCoolersData]
    var dataEvapFluidCoolers: Owned[EvaporativeFluidCoolersData]
    var dataExteriorEnergyUse: Owned[ExteriorEnergyUseData]
    var dataExternalInterface: Owned[ExternalInterfaceData]
    var dataFanCoilUnits: Owned[FanCoilUnitsData]
    var dataFans: Owned[FansData]
    var dataFaultsMgr: Owned[FaultsManagerData]
    var dataFluidCoolers: Owned[FluidCoolersData]
    var dataFluid: Owned[FluidData]
    var dataFourPipeBeam: Owned[FourPipeBeamData]
    var dataFuelCellElectGen: Owned[FuelCellElectricGeneratorData]
    var dataFurnaces: Owned[FurnacesData]
    var dataGeneral: Owned[GeneralData]
    var dataGeneralRoutines: Owned[GeneralRoutinesData]
    var dataGeneratorFuelSupply: Owned[GeneratorFuelSupplyData]
    var dataGenerator: Owned[GeneratorsData]
    var dataGlobalNames: Owned[GlobalNamesData]
    var dataGroundHeatExchanger: Owned[GroundHeatExchangerData]
    var dataGrndTempModelMgr: Owned[GroundTemperatureManagerData]
    var dataHVACControllers: Owned[HVACControllersData]
    var dataHVACCooledBeam: Owned[HVACCooledBeamData]
    var dataHVACCtrl: Owned[HVACCtrlData]
    var dataHVACDXHeatPumpSys: Owned[HVACDXHeatPumpSystemData]
    var dataHVACDuct: Owned[HVACDuctData]
    var dataHVACGlobal: Owned[HVACGlobalsData]
    var dataHVACAssistedCC: Owned[HVACHXAssistedCoolingCoilData]
    var dataHVACInterfaceMgr: Owned[HVACInterfaceManagerData]
    var dataHVACMgr: Owned[HVACManagerData]
    var dataHVACMultiSpdHP: Owned[HVACMultiSpeedHeatPumpData]
    var dataHVACSingleDuctInduc: Owned[HVACSingleDuctInducData]
    var dataHVACSizingSimMgr: Owned[HVACSizingSimMgrData]
    var dataHVACStandAloneERV: Owned[HVACStandAloneERVData]
    var dataHVACUnitaryBypassVAV: Owned[HVACUnitaryBypassVAVData]
    var dataHVACVarRefFlow: Owned[HVACVarRefFlowData]
    var dataHWBaseboardRad: Owned[HWBaseboardRadiatorData]
    var dataHeatBalFanSys: Owned[HeatBalFanSysData]
    var dataHeatBalFiniteDiffMgr: Owned[HeatBalFiniteDiffMgr]
    var dataHeatBalHAMTMgr: Owned[HeatBalHAMTMgrData]
    var dataHeatBalIntHeatGains: Owned[HeatBalInternalHeatGainsData]
    var dataHeatBalSurf: Owned[HeatBalSurfData]
    var dataHeatBalSurfMgr: Owned[HeatBalSurfMgr]
    var dataHeatBalAirMgr: Owned[HeatBalanceAirMgrData]
    var dataHeatBal: Owned[HeatBalanceData]
    var dataHeatBalIntRadExchg: Owned[HeatBalanceIntRadExchgData]
    var dataHeatBalMgr: Owned[HeatBalanceMgrData]
    var dataHPWaterToWaterClg: Owned[HeatPumpWaterToWaterCOOLINGData]
    var dataHPWaterToWaterHtg: Owned[HeatPumpWaterToWaterHEATINGData]
    var dataHPWaterToWaterSimple: Owned[HeatPumpWaterToWaterSimpleData]
    var dataHeatRecovery: Owned[HeatRecoveryData]
    var dataHeatingCoils: Owned[HeatingCoilsData]
    var dataHighTempRadSys: Owned[HighTempRadiantSystemData]
    var dataHumidifiers: Owned[HumidifiersData]
    var dataHybridModel: Owned[HybridModelData]
    var dataHybridUnitaryAC: Owned[HybridUnitaryAirConditionersData]
    var dataHysteresisPhaseChange: Owned[HysteresisPhaseChangeData]
    var dataICEngElectGen: Owned[ICEngineElectricGeneratorData]
    var dataIPShortCut: Owned[IPShortCutsData]
    var dataIceThermalStorage: Owned[IceThermalStorageData]
    var dataIndoorGreen: Owned[IndoorGreenData]
    var dataIntegratedHP: Owned[IntegratedHeatPumpGlobalData]
    var dataInternalHeatGains: Owned[InternalHeatGainsData]
    var dataLoopNodes: Owned[LoopNodeData]
    var dataLowTempRadSys: Owned[LowTempRadiantSystemData]
    var dataMaterial: Owned[MaterialData]
    var dataMatrixDataManager: Owned[MatrixDataManagerData]
    var dataCHPElectGen: Owned[MicroCHPElectricGeneratorData]
    var dataMircoturbElectGen: Owned[MicroturbineElectricGeneratorData]
    var dataMixedAir: Owned[MixedAirData]
    var dataMixerComponent: Owned[MixerComponentData]
    var dataMstBal: Owned[MoistureBalanceData]
    var dataMstBalEMPD: Owned[MoistureBalanceEMPDData]
    var dataMoistureBalEMPD: Owned[MoistureBalanceEMPDManagerData]
    var dataMundtSimMgr: Owned[MundtSimMgrData]
    var dataNodeInputMgr: Owned[NodeInputManagerData]
    var dataOutAirNodeMgr: Owned[OutAirNodeManagerData]
    var dataOutdoorAirUnit: Owned[OutdoorAirUnitData]
    var dataOutputProcessor: Owned[OutputProcessorData]
    var dataOutRptPredefined: Owned[OutputReportPredefinedData]
    var dataOutputReportTabularAnnual: Owned[OutputReportTabularAnnualData]
    var dataOutRptTab: Owned[OutputReportTabularData]
    var dataOutputReports: Owned[OutputReportsData]
    var dataOutput: Owned[OutputsData]
    var dataOutsideEnergySrcs: Owned[OutsideEnergySourcesData]
    var dataPackagedThermalStorageCoil: Owned[PackagedThermalStorageCoilData]
    var dataPhotovoltaicState: Owned[PhotovoltaicStateData]
    var dataPhotovoltaicThermalCollector: Owned[PhotovoltaicThermalCollectorsData]
    var dataPhotovoltaic: Owned[PhotovoltaicsData]
    var dataPipeHT: Owned[PipeHeatTransferData]
    var dataPipes: Owned[PipesData]
    var dataPlantCentralGSHP: Owned[PlantCentralGSHPData]
    var dataPlantChillers: Owned[PlantChillersData]
    var dataPlantCompTempSrc: Owned[PlantCompTempSrcData]
    var dataPlantCondLoopOp: Owned[PlantCondLoopOperationData]
    var dataPlantHXFluidToFluid: Owned[PlantHeatExchangerFluidToFluidData]
    var dataPlantLoadProfile: Owned[PlantLoadProfileData]
    var dataPlantMgr: Owned[PlantMgrData]
    var dataPlantPipingSysMgr: Owned[PlantPipingSysMgrData]
    var dataPlantPressureSys: Owned[PlantPressureSysData]
    var dataPlantUtilities: Owned[PlantUtilitiesData]
    var dataPlantValves: Owned[PlantValvesData]
    var dataPluginManager: Owned[PluginManagerData]
    var dataPollution: Owned[PollutionData]
    var dataPondGHE: Owned[PondGroundHeatExchangerData]
    var dataPowerInductionUnits: Owned[PoweredInductionUnitsData]
    var dataPsychrometrics: Owned[PsychrometricsData]
    var dataPsychCache: Owned[PsychrometricCacheData]
    var dataPumps: Owned[PumpsData]
    var dataPurchasedAirMgr: Owned[PurchasedAirManagerData]
    var dataRefrigCase: Owned[RefrigeratedCaseData]
    var dataRptCoilSelection: Owned[ReportCoilSelectionData]
    var dataReportFlag: Owned[ReportFlagData]
    var dataResultsFramework: Owned[ResultsFrameworkData]
    var dataRetAirPathMrg: Owned[ReturnAirPathMgr]
    var dataExhAirSystemMrg: Owned[ExhaustAirSystemMgr]
    var dataExhCtrlSystemMrg: Owned[ExhaustControlSystemMgr]
    var dataRoomAirflowNetModel: Owned[RoomAirModelAirflowNetworkData]
    var dataRoomAir: Owned[RoomAirModelData]
    var dataRoomAirModelTempPattern: Owned[RoomAirModelUserTempPatternData]
    var dataRootFinder: Owned[RootFindingData]
    var dataRuntimeLang: Owned[RuntimeLanguageData]
    var dataRuntimeLangProcessor: Owned[RuntimeLanguageProcessorData]
    var dataSQLiteProcedures: Owned[SQLiteProceduresData]
    var dataSched: Owned[ScheduleManagerData]
    var dataSetPointManager: Owned[SetPointManagerData]
    var dataShadowComb: Owned[ShadowCombData]
    var dataSimAirServingZones: Owned[SimAirServingZonesData]
    var dataSimulationManager: Owned[SimulationManagerData]
    var dataSingleDuct: Owned[SingleDuctData]
    var dataSize: Owned[SizingData]
    var dataSizingManager: Owned[SizingManagerData]
    var dataSolarCollectors: Owned[SolarCollectorsData]
    var dataSolarReflectionManager: Owned[SolarReflectionManagerData]
    var dataSolarShading: Owned[SolarShadingData]
    var dataSplitterComponent: Owned[SplitterComponentData]
    var dataSteamBaseboardRadiator: Owned[SteamBaseboardRadiatorData]
    var dataSteamCoils: Owned[SteamCoilsData]
    var dataSurfColor: Owned[SurfaceColorData]
    var dataSurfaceGeometry: Owned[SurfaceGeometryData]
    var dataSurfaceGroundHeatExchangers: Owned[SurfaceGroundHeatExchangersData]
    var dataSurfLists: Owned[SurfaceListsData]
    var dataSurface: Owned[SurfacesData]
    var dataSwimmingPools: Owned[SwimmingPoolsData]
    var dataSysAirFlowSizer: Owned[SystemAirFlowSizerData]
    var dataAvail: Owned[SystemAvailabilityManagerData]
    var dataSysRpts: Owned[SystemReportsData]
    var dataSysVars: Owned[SystemVarsData]
    var dataTARCOGCommon: Owned[TARCOGCommonData]
    var dataTARCOGOutputs: Owned[TARCOGOutputData]
    var dataThermalChimneys: Owned[ThermalChimneysData]
    var dataThermalComforts: Owned[ThermalComfortsData]
    var dataThermalISO15099Calc: Owned[ThermalISO15099CalcData]
    var dataTARCOGGasses90: Owned[TARCOGGasses90Data]
    var dataTARCOGMain: Owned[TARCOGMainData]
    var dataTarcogShading: Owned[TarcogShadingData]
    var dataTranspiredCollector: Owned[TranspiredCollectorData]
    var dataUFADManager: Owned[UFADManagerData]
    var dataUnitHeaters: Owned[UnitHeatersData]
    var dataUnitVentilators: Owned[UnitVentilatorsData]
    var dataUnitarySystems: Owned[UnitarySystemsData]
    var dataUserDefinedComponents: Owned[UserDefinedComponentsData]
    var dataUtilityRoutines: Owned[UtilityRoutinesData]
    var dataVariableSpeedCoils: Owned[VariableSpeedCoilsData]
    var dataVectors: Owned[VectorsData]
    var dataVentilatedSlab: Owned[VentilatedSlabData]
    var dataViewFactor: Owned[ViewFactorInfoData]
    var dataWaterCoils: Owned[WaterCoilsData]
    var dataWaterManager: Owned[WaterManagerData]
    var dataWaterThermalTanks: Owned[WaterThermalTanksData]
    var dataWaterToAirHeatPump: Owned[WaterToAirHeatPumpData]
    var dataWaterToAirHeatPumpSimple: Owned[WaterToAirHeatPumpSimpleData]
    var dataWaterUse: Owned[WaterUseData]
    var dataWeather: Owned[WeatherManagerData]
    var dataWindTurbine: Owned[WindTurbineData]
    var dataWindowAC: Owned[WindowACData]
    var dataWindowComplexManager: Owned[WindowComplexManagerData]
    var dataWindowEquivLayer: Owned[WindowEquivLayerData]
    var dataWindowEquivalentLayer: Owned[WindowEquivalentLayerData]
    var dataWindowManager: Owned[WindowManagerData]
    var dataWindowManagerExterior: Owned[WindowManagerExteriorData]
    var dataZoneAirLoopEquipmentManager: Owned[ZoneAirLoopEquipmentManagerData]
    var dataZoneContaminantPredictorCorrector: Owned[ZoneContaminantPredictorCorrectorData]
    var dataZoneDehumidifier: Owned[ZoneDehumidifierData]
    var dataZoneEquipmentManager: Owned[ZoneEquipmentManagerData]
    var dataZonePlenum: Owned[ZonePlenumData]
    var dataZoneTempPredictorCorrector: Owned[ZoneTempPredictorCorrectorData]
    var init_state_called: Bool = False
    var init_constant_state_called: Bool = False
    def __init__(inout self):
        self.dataAirLoop = Owned[DataAirLoopData](DataAirLoopData())
        self.dataAirLoopHVACDOAS = Owned[AirLoopHVACDOASData](AirLoopHVACDOASData())
        self.dataAirSystemsData = Owned[AirSystemsData](AirSystemsData())
        self.afn = Owned[AirflowNetworkSolver](AirflowNetworkSolver(self))
        self.dataBSDFWindow = Owned[BSDFWindowData](BSDFWindowData())
        self.dataBaseSizerFanHeatInputs = Owned[BaseSizerWithFanHeatInputsData](BaseSizerWithFanHeatInputsData())
        self.dataBaseSizerScalableInputs = Owned[BaseSizerWithScalableInputsData](BaseSizerWithScalableInputsData())
        self.dataBaseboardElectric = Owned[BaseboardElectricData](BaseboardElectricData())
        self.dataBaseboardRadiator = Owned[BaseboardRadiatorData](BaseboardRadiatorData())
        self.dataBoilerSteam = Owned[BoilerSteamData](BoilerSteamData())
        self.dataBoilers = Owned[BoilersData](BoilersData())
        self.dataBranchAirLoopPlant = Owned[DataBranchAirLoopPlantData](DataBranchAirLoopPlantData())
        self.dataBranchInputManager = Owned[BranchInputManagerData](BranchInputManagerData())
        self.dataBranchNodeConnections = Owned[BranchNodeConnectionsData](BranchNodeConnectionsData())
        self.dataCHPElectGen = Owned[MicroCHPElectricGeneratorData](MicroCHPElectricGeneratorData())
        self.dataCTElectricGenerator = Owned[CTElectricGeneratorData](CTElectricGeneratorData())
        self.dataChilledCeilingPanelSimple = Owned[ChilledCeilingPanelSimpleData](ChilledCeilingPanelSimpleData())
        self.dataChillerAbsorber = Owned[ChillerAbsorberData](ChillerAbsorberData())
        self.dataChillerElectricEIR = Owned[ChillerElectricEIRData](ChillerElectricEIRData())
        self.dataChillerExhaustAbsorption = Owned[ChillerExhaustAbsorptionData](ChillerExhaustAbsorptionData())
        self.dataChillerGasAbsorption = Owned[ChillerGasAbsorptionData](ChillerGasAbsorptionData())
        self.dataChillerIndirectAbsorption = Owned[ChillerIndirectAbsoprtionData](ChillerIndirectAbsoprtionData())
        self.dataChillerReformulatedEIR = Owned[ChillerReformulatedEIRData](ChillerReformulatedEIRData())
        self.dataChillerElectricASHRAE205 = Owned[ChillerElectricASHRAE205Data](ChillerElectricASHRAE205Data())
        self.dataCoilCoolingDX = Owned[CoilCoolingDXData](CoilCoolingDXData())
        self.dataCondenserLoopTowers = Owned[CondenserLoopTowersData](CondenserLoopTowersData())
        self.dataConstruction = Owned[ConstructionData](ConstructionData())
        self.dataContaminantBalance = Owned[ContaminantBalanceData](ContaminantBalanceData())
        self.dataConvect = Owned[ConvectionCoefficientsData](ConvectionCoefficientsData())
        self.dataConvergeParams = Owned[ConvergParamsData](ConvergParamsData())
        self.dataCoolTower = Owned[CoolTowerData](CoolTowerData())
        self.dataCostEstimateManager = Owned[CostEstimateManagerData](CostEstimateManagerData())
        self.dataCrossVentMgr = Owned[CrossVentMgrData](CrossVentMgrData())
        self.dataCurveManager = Owned[CurveManagerData](CurveManagerData())
        self.dataDXCoils = Owned[DXCoilsData](DXCoilsData())
        self.dataDXFEarClipping = Owned[DXFEarClippingData](DXFEarClippingData())
        self.dataDaylightingDevices = Owned[DaylightingDevicesData](DaylightingDevicesData())
        self.dataDaylightingDevicesData = Owned[DataDaylightingDevicesData](DataDaylightingDevicesData())
        self.dataDayltg = Owned[DaylightingData](DaylightingData())
        self.dataDefineEquipment = Owned[DefineEquipData](DefineEquipData())
        self.dataDemandManager = Owned[DemandManagerData](DemandManagerData())
        self.dataDesiccantDehumidifiers = Owned[DesiccantDehumidifiersData](DesiccantDehumidifiersData())
        self.dataDispVentMgr = Owned[DisplacementVentMgrData](DisplacementVentMgrData())
        self.dataDualDuct = Owned[DualDuctData](DualDuctData())
        self.dataDuctLoss = Owned[DuctLossData](DuctLossData())
        self.dataEIRFuelFiredHeatPump = Owned[EIRFuelFiredHeatPumpsData](EIRFuelFiredHeatPumpsData())
        self.dataEIRPlantLoopHeatPump = Owned[EIRPlantLoopHeatPumpsData](EIRPlantLoopHeatPumpsData())
        self.dataHeatPumpAirToWater = Owned[HeatPumpAirToWatersData](HeatPumpAirToWatersData())
        self.dataEMSMgr = Owned[EMSManagerData](EMSManagerData())
        self.dataEarthTube = Owned[EarthTubeData](EarthTubeData())
        self.dataEcoRoofMgr = Owned[EcoRoofManagerData](EcoRoofManagerData())
        self.dataEconLifeCycleCost = Owned[EconomicLifeCycleCostData](EconomicLifeCycleCostData())
        self.dataEconTariff = Owned[EconomicTariffData](EconomicTariffData())
        self.dataElectBaseboardRad = Owned[ElectricBaseboardRadiatorData](ElectricBaseboardRadiatorData())
        self.dataElectPwrSvcMgr = Owned[ElectPwrSvcMgrData](ElectPwrSvcMgrData())
        self.dataEnvrn = Owned[EnvironmentData](EnvironmentData())
        self.dataErrTracking = Owned[ErrorTrackingData](ErrorTrackingData())
        self.dataEvapCoolers = Owned[EvaporativeCoolersData](EvaporativeCoolersData())
        self.dataEvapFluidCoolers = Owned[EvaporativeFluidCoolersData](EvaporativeFluidCoolersData())
        self.dataExteriorEnergyUse = Owned[ExteriorEnergyUseData](ExteriorEnergyUseData())
        self.dataExternalInterface = Owned[ExternalInterfaceData](ExternalInterfaceData())
        self.dataFanCoilUnits = Owned[FanCoilUnitsData](FanCoilUnitsData())
        self.dataFans = Owned[FansData](FansData())
        self.dataFaultsMgr = Owned[FaultsManagerData](FaultsManagerData())
        self.dataFluidCoolers = Owned[FluidCoolersData](FluidCoolersData())
        self.dataFluid = Owned[FluidData](FluidData())
        self.dataFourPipeBeam = Owned[FourPipeBeamData](FourPipeBeamData())
        self.dataFuelCellElectGen = Owned[FuelCellElectricGeneratorData](FuelCellElectricGeneratorData())
        self.dataFurnaces = Owned[FurnacesData](FurnacesData())
        self.dataGeneral = Owned[GeneralData](GeneralData())
        self.dataGeneralRoutines = Owned[GeneralRoutinesData](GeneralRoutinesData())
        self.dataGenerator = Owned[GeneratorsData](GeneratorsData())
        self.dataGeneratorFuelSupply = Owned[GeneratorFuelSupplyData](GeneratorFuelSupplyData())
        self.dataGlobal = Owned[DataGlobal](DataGlobal())
        self.dataGlobalNames = Owned[GlobalNamesData](GlobalNamesData())
        self.dataGrndTempModelMgr = Owned[GroundTemperatureManagerData](GroundTemperatureManagerData())
        self.dataGroundHeatExchanger = Owned[GroundHeatExchangerData](GroundHeatExchangerData())
        self.dataHPWaterToWaterClg = Owned[HeatPumpWaterToWaterCOOLINGData](HeatPumpWaterToWaterCOOLINGData())
        self.dataHPWaterToWaterHtg = Owned[HeatPumpWaterToWaterHEATINGData](HeatPumpWaterToWaterHEATINGData())
        self.dataHPWaterToWaterSimple = Owned[HeatPumpWaterToWaterSimpleData](HeatPumpWaterToWaterSimpleData())
        self.dataHVACAssistedCC = Owned[HVACHXAssistedCoolingCoilData](HVACHXAssistedCoolingCoilData())
        self.dataHVACControllers = Owned[HVACControllersData](HVACControllersData())
        self.dataHVACCooledBeam = Owned[HVACCooledBeamData](HVACCooledBeamData())
        self.dataHVACCtrl = Owned[HVACCtrlData](HVACCtrlData())
        self.dataHVACDXHeatPumpSys = Owned[HVACDXHeatPumpSystemData](HVACDXHeatPumpSystemData())
        self.dataHVACDuct = Owned[HVACDuctData](HVACDuctData())
        self.dataHVACGlobal = Owned[HVACGlobalsData](HVACGlobalsData())
        self.dataHVACInterfaceMgr = Owned[HVACInterfaceManagerData](HVACInterfaceManagerData())
        self.dataHVACMgr = Owned[HVACManagerData](HVACManagerData())
        self.dataHVACMultiSpdHP = Owned[HVACMultiSpeedHeatPumpData](HVACMultiSpeedHeatPumpData())
        self.dataHVACSingleDuctInduc = Owned[HVACSingleDuctInducData](HVACSingleDuctInducData())
        self.dataHVACSizingSimMgr = Owned[HVACSizingSimMgrData](HVACSizingSimMgrData())
        self.dataHVACStandAloneERV = Owned[HVACStandAloneERVData](HVACStandAloneERVData())
        self.dataHVACUnitaryBypassVAV = Owned[HVACUnitaryBypassVAVData](HVACUnitaryBypassVAVData())
        self.dataHVACVarRefFlow = Owned[HVACVarRefFlowData](HVACVarRefFlowData())
        self.dataHWBaseboardRad = Owned[HWBaseboardRadiatorData](HWBaseboardRadiatorData())
        self.dataHeatBal = Owned[HeatBalanceData](HeatBalanceData())
        self.dataHeatBalAirMgr = Owned[HeatBalanceAirMgrData](HeatBalanceAirMgrData())
        self.dataHeatBalFanSys = Owned[HeatBalFanSysData](HeatBalFanSysData())
        self.dataHeatBalFiniteDiffMgr = Owned[HeatBalFiniteDiffMgr](HeatBalFiniteDiffMgr())
        self.dataHeatBalHAMTMgr = Owned[HeatBalHAMTMgrData](HeatBalHAMTMgrData())
        self.dataHeatBalIntHeatGains = Owned[HeatBalInternalHeatGainsData](HeatBalInternalHeatGainsData())
        self.dataHeatBalIntRadExchg = Owned[HeatBalanceIntRadExchgData](HeatBalanceIntRadExchgData())
        self.dataHeatBalMgr = Owned[HeatBalanceMgrData](HeatBalanceMgrData())
        self.dataHeatBalSurf = Owned[HeatBalSurfData](HeatBalSurfData())
        self.dataHeatBalSurfMgr = Owned[HeatBalSurfMgr](HeatBalSurfMgr())
        self.dataHeatRecovery = Owned[HeatRecoveryData](HeatRecoveryData())
        self.dataHeatingCoils = Owned[HeatingCoilsData](HeatingCoilsData())
        self.dataHighTempRadSys = Owned[HighTempRadiantSystemData](HighTempRadiantSystemData())
        self.dataHumidifiers = Owned[HumidifiersData](HumidifiersData())
        self.dataHybridModel = Owned[HybridModelData](HybridModelData())
        self.dataHybridUnitaryAC = Owned[HybridUnitaryAirConditionersData](HybridUnitaryAirConditionersData())
        self.dataHysteresisPhaseChange = Owned[HysteresisPhaseChangeData](HysteresisPhaseChangeData())
        self.dataICEngElectGen = Owned[ICEngineElectricGeneratorData](ICEngineElectricGeneratorData())
        self.dataIPShortCut = Owned[IPShortCutsData](IPShortCutsData())
        self.dataIceThermalStorage = Owned[IceThermalStorageData](IceThermalStorageData())
        self.dataIndoorGreen = Owned[IndoorGreenData](IndoorGreenData())
        self.dataInputProcessing = Owned[DataInputProcessing](DataInputProcessing())
        self.dataIntegratedHP = Owned[IntegratedHeatPumpGlobalData](IntegratedHeatPumpGlobalData())
        self.dataInternalHeatGains = Owned[InternalHeatGainsData](InternalHeatGainsData())
        self.dataLoopNodes = Owned[LoopNodeData](LoopNodeData())
        self.dataLowTempRadSys = Owned[LowTempRadiantSystemData](LowTempRadiantSystemData())
        self.dataMaterial = Owned[MaterialData](MaterialData())
        self.dataMatrixDataManager = Owned[MatrixDataManagerData](MatrixDataManagerData())
        self.dataMircoturbElectGen = Owned[MicroturbineElectricGeneratorData](MicroturbineElectricGeneratorData())
        self.dataMixedAir = Owned[MixedAirData](MixedAirData())
        self.dataMixerComponent = Owned[MixerComponentData](MixerComponentData())
        self.dataMoistureBalEMPD = Owned[MoistureBalanceEMPDManagerData](MoistureBalanceEMPDManagerData())
        self.dataMstBal = Owned[MoistureBalanceData](MoistureBalanceData())
        self.dataMstBalEMPD = Owned[MoistureBalanceEMPDData](MoistureBalanceEMPDData())
        self.dataMundtSimMgr = Owned[MundtSimMgrData](MundtSimMgrData())
        self.dataNodeInputMgr = Owned[NodeInputManagerData](NodeInputManagerData())
        self.dataOutAirNodeMgr = Owned[OutAirNodeManagerData](OutAirNodeManagerData())
        self.dataOutRptPredefined = Owned[OutputReportPredefinedData](OutputReportPredefinedData())
        self.dataOutRptTab = Owned[OutputReportTabularData](OutputReportTabularData())
        self.dataOutdoorAirUnit = Owned[OutdoorAirUnitData](OutdoorAirUnitData())
        self.dataOutput = Owned[OutputsData](OutputsData())
        self.dataOutputProcessor = Owned[OutputProcessorData](OutputProcessorData())
        self.dataOutputReportTabularAnnual = Owned[OutputReportTabularAnnualData](OutputReportTabularAnnualData())
        self.dataOutputReports = Owned[OutputReportsData](OutputReportsData())
        self.dataOutsideEnergySrcs = Owned[OutsideEnergySourcesData](OutsideEnergySourcesData())
        self.dataPackagedThermalStorageCoil = Owned[PackagedThermalStorageCoilData](PackagedThermalStorageCoilData())
        self.dataPhotovoltaic = Owned[PhotovoltaicsData](PhotovoltaicsData())
        self.dataPhotovoltaicState = Owned[PhotovoltaicStateData](PhotovoltaicStateData())
        self.dataPhotovoltaicThermalCollector = Owned[PhotovoltaicThermalCollectorsData](PhotovoltaicThermalCollectorsData())
        self.dataPipeHT = Owned[PipeHeatTransferData](PipeHeatTransferData())
        self.dataPipes = Owned[PipesData](PipesData())
        self.dataPlantCentralGSHP = Owned[PlantCentralGSHPData](PlantCentralGSHPData())
        self.dataPlantChillers = Owned[PlantChillersData](PlantChillersData())
        self.dataPlantCompTempSrc = Owned[PlantCompTempSrcData](PlantCompTempSrcData())
        self.dataPlantCondLoopOp = Owned[PlantCondLoopOperationData](PlantCondLoopOperationData())
        self.dataPlantHXFluidToFluid = Owned[PlantHeatExchangerFluidToFluidData](PlantHeatExchangerFluidToFluidData())
        self.dataPlantLoadProfile = Owned[PlantLoadProfileData](PlantLoadProfileData())
        self.dataPlantMgr = Owned[PlantMgrData](PlantMgrData())
        self.dataPlantPipingSysMgr = Owned[PlantPipingSysMgrData](PlantPipingSysMgrData())
        self.dataPlantPressureSys = Owned[PlantPressureSysData](PlantPressureSysData())
        self.dataPlantUtilities = Owned[PlantUtilitiesData](PlantUtilitiesData())
        self.dataPlantValves = Owned[PlantValvesData](PlantValvesData())
        self.dataPlnt = Owned[DataPlantData](DataPlantData())
        self.dataPluginManager = Owned[PluginManagerData](PluginManagerData())
        self.dataPollution = Owned[PollutionData](PollutionData())
        self.dataPondGHE = Owned[PondGroundHeatExchangerData](PondGroundHeatExchangerData())
        self.dataPowerInductionUnits = Owned[PoweredInductionUnitsData](PoweredInductionUnitsData())
        self.dataPsychrometrics = Owned[PsychrometricsData](PsychrometricsData())
        self.dataPsychCache = Owned[PsychrometricCacheData](PsychrometricCacheData())
        self.dataPumps = Owned[PumpsData](PumpsData())
        self.dataPurchasedAirMgr = Owned[PurchasedAirManagerData](PurchasedAirManagerData())
        self.dataRefrigCase = Owned[RefrigeratedCaseData](RefrigeratedCaseData())
        self.dataReportFlag = Owned[ReportFlagData](ReportFlagData())
        self.dataResultsFramework = Owned[ResultsFrameworkData](ResultsFrameworkData())
        self.dataRetAirPathMrg = Owned[ReturnAirPathMgr](ReturnAirPathMgr())
        self.dataExhAirSystemMrg = Owned[ExhaustAirSystemMgr](ExhaustAirSystemMgr())
        self.dataExhCtrlSystemMrg = Owned[ExhaustControlSystemMgr](ExhaustControlSystemMgr())
        self.dataRoomAir = Owned[RoomAirModelData](RoomAirModelData())
        self.dataRoomAirModelTempPattern = Owned[RoomAirModelUserTempPatternData](RoomAirModelUserTempPatternData())
        self.dataRoomAirflowNetModel = Owned[RoomAirModelAirflowNetworkData](RoomAirModelAirflowNetworkData())
        self.dataRootFinder = Owned[RootFindingData](RootFindingData())
        self.dataRptCoilSelection = Owned[ReportCoilSelectionData](ReportCoilSelectionData())
        self.dataRuntimeLang = Owned[RuntimeLanguageData](RuntimeLanguageData())
        self.dataRuntimeLangProcessor = Owned[RuntimeLanguageProcessorData](RuntimeLanguageProcessorData())
        self.dataSQLiteProcedures = Owned[SQLiteProceduresData](SQLiteProceduresData())
        self.dataSched = Owned[ScheduleManagerData](ScheduleManagerData())
        self.dataSetPointManager = Owned[SetPointManagerData](SetPointManagerData())
        self.dataShadowComb = Owned[ShadowCombData](ShadowCombData())
        self.dataSimAirServingZones = Owned[SimAirServingZonesData](SimAirServingZonesData())
        self.dataSimulationManager = Owned[SimulationManagerData](SimulationManagerData())
        self.dataSingleDuct = Owned[SingleDuctData](SingleDuctData())
        self.dataSize = Owned[SizingData](SizingData())
        self.dataSizingManager = Owned[SizingManagerData](SizingManagerData())
        self.dataSolarCollectors = Owned[SolarCollectorsData](SolarCollectorsData())
        self.dataSolarReflectionManager = Owned[SolarReflectionManagerData](SolarReflectionManagerData())
        self.dataSolarShading = Owned[SolarShadingData](SolarShadingData())
        self.dataSplitterComponent = Owned[SplitterComponentData](SplitterComponentData())
        self.dataSteamBaseboardRadiator = Owned[SteamBaseboardRadiatorData](SteamBaseboardRadiatorData())
        self.dataSteamCoils = Owned[SteamCoilsData](SteamCoilsData())
        self.dataStrGlobals = Owned[DataStringGlobalsData](DataStringGlobalsData())
        self.dataSurfColor = Owned[SurfaceColorData](SurfaceColorData())
        self.dataSurfLists = Owned[SurfaceListsData](SurfaceListsData())
        self.dataSurface = Owned[SurfacesData](SurfacesData())
        self.dataSurfaceGeometry = Owned[SurfaceGeometryData](SurfaceGeometryData())
        self.dataSurfaceGroundHeatExchangers = Owned[SurfaceGroundHeatExchangersData](SurfaceGroundHeatExchangersData())
        self.dataSwimmingPools = Owned[SwimmingPoolsData](SwimmingPoolsData())
        self.dataSysAirFlowSizer = Owned[SystemAirFlowSizerData](SystemAirFlowSizerData())
        self.dataSysRpts = Owned[SystemReportsData](SystemReportsData())
        self.dataSysVars = Owned[SystemVarsData](SystemVarsData())
        self.dataAvail = Owned[SystemAvailabilityManagerData](SystemAvailabilityManagerData())
        self.dataTARCOGCommon = Owned[TARCOGCommonData](TARCOGCommonData())
        self.dataTARCOGOutputs = Owned[TARCOGOutputData](TARCOGOutputData())
        self.dataThermalChimneys = Owned[ThermalChimneysData](ThermalChimneysData())
        self.dataThermalComforts = Owned[ThermalComfortsData](ThermalComfortsData())
        self.dataThermalISO15099Calc = Owned[ThermalISO15099CalcData](ThermalISO15099CalcData())
        self.dataTARCOGGasses90 = Owned[TARCOGGasses90Data](TARCOGGasses90Data())
        self.dataTARCOGMain = Owned[TARCOGMainData](TARCOGMainData())
        self.dataTarcogShading = Owned[TarcogShadingData](TarcogShadingData())
        self.dataTimingsData = Owned[DataTimingsData](DataTimingsData())
        self.dataTranspiredCollector = Owned[TranspiredCollectorData](TranspiredCollectorData())
        self.dataUFADManager = Owned[UFADManagerData](UFADManagerData())
        self.dataUnitHeaters = Owned[UnitHeatersData](UnitHeatersData())
        self.dataUnitVentilators = Owned[UnitVentilatorsData](UnitVentilatorsData())
        self.dataUnitarySystems = Owned[UnitarySystemsData](UnitarySystemsData())
        self.dataUserDefinedComponents = Owned[UserDefinedComponentsData](UserDefinedComponentsData())
        self.dataUtilityRoutines = Owned[UtilityRoutinesData](UtilityRoutinesData())
        self.dataVariableSpeedCoils = Owned[VariableSpeedCoilsData](VariableSpeedCoilsData())
        self.dataVectors = Owned[VectorsData](VectorsData())
        self.dataVentilatedSlab = Owned[VentilatedSlabData](VentilatedSlabData())
        self.dataViewFactor = Owned[ViewFactorInfoData](ViewFactorInfoData())
        self.dataWaterCoils = Owned[WaterCoilsData](WaterCoilsData())
        self.dataWaterData = Owned[DataWaterData](DataWaterData())
        self.dataWaterManager = Owned[WaterManagerData](WaterManagerData())
        self.dataWaterThermalTanks = Owned[WaterThermalTanksData](WaterThermalTanksData())
        self.dataWaterToAirHeatPump = Owned[WaterToAirHeatPumpData](WaterToAirHeatPumpData())
        self.dataWaterToAirHeatPumpSimple = Owned[WaterToAirHeatPumpSimpleData](WaterToAirHeatPumpSimpleData())
        self.dataWaterUse = Owned[WaterUseData](WaterUseData())
        self.dataWeather = Owned[WeatherManagerData](WeatherManagerData())
        self.dataWindTurbine = Owned[WindTurbineData](WindTurbineData())
        self.dataWindowAC = Owned[WindowACData](WindowACData())
        self.dataWindowComplexManager = Owned[WindowComplexManagerData](WindowComplexManagerData())
        self.dataWindowEquivLayer = Owned[WindowEquivLayerData](WindowEquivLayerData())
        self.dataWindowEquivalentLayer = Owned[WindowEquivalentLayerData](WindowEquivalentLayerData())
        self.dataWindowManager = Owned[WindowManagerData](WindowManagerData())
        self.dataWindowManagerExterior = Owned[WindowManagerExteriorData](WindowManagerExteriorData())
        self.dataZoneAirLoopEquipmentManager = Owned[ZoneAirLoopEquipmentManagerData](ZoneAirLoopEquipmentManagerData())
        self.dataZoneContaminantPredictorCorrector = Owned[ZoneContaminantPredictorCorrectorData](ZoneContaminantPredictorCorrectorData())
        self.dataZoneCtrls = Owned[DataZoneControlsData](DataZoneControlsData())
        self.dataZoneDehumidifier = Owned[ZoneDehumidifierData](ZoneDehumidifierData())
        self.dataZoneEnergyDemand = Owned[DataZoneEnergyDemandsData](DataZoneEnergyDemandsData())
        self.dataZoneEquip = Owned[DataZoneEquipmentData](DataZoneEquipmentData())
        self.dataZoneEquipmentManager = Owned[ZoneEquipmentManagerData](ZoneEquipmentManagerData())
        self.dataZonePlenum = Owned[ZonePlenumData](ZonePlenumData())
        self.dataZoneTempPredictorCorrector = Owned[ZoneTempPredictorCorrectorData](ZoneTempPredictorCorrectorData())
    def __del__(owned self):

    def clear_state(inout self):
        self.ready = True
        self.init_state_called = False
        self.init_constant_state_called = False
        self.dataAirLoop.clear_state()
        self.dataAirLoopHVACDOAS.clear_state()
        self.dataAirSystemsData.clear_state()
        self.afn.clear_state()
        self.dataBSDFWindow.clear_state()
        self.dataBaseSizerFanHeatInputs.clear_state()
        self.dataBaseSizerScalableInputs.clear_state()
        self.dataBaseboardElectric.clear_state()
        self.dataBaseboardRadiator.clear_state()
        self.dataBoilerSteam.clear_state()
        self.dataBoilers.clear_state()
        self.dataBranchAirLoopPlant.clear_state()
        self.dataBranchInputManager.clear_state()
        self.dataBranchNodeConnections.clear_state()
        self.dataCHPElectGen.clear_state()
        self.dataCTElectricGenerator.clear_state()
        self.dataChilledCeilingPanelSimple.clear_state()
        self.dataChillerAbsorber.clear_state()
        self.dataChillerElectricEIR.clear_state()
        self.dataChillerExhaustAbsorption.clear_state()
        self.dataChillerGasAbsorption.clear_state()
        self.dataChillerIndirectAbsorption.clear_state()
        self.dataChillerReformulatedEIR.clear_state()
        self.dataChillerElectricASHRAE205.clear_state()
        self.dataCoilCoolingDX.clear_state()
        self.dataCondenserLoopTowers.clear_state()
        self.dataConstruction.clear_state()
        self.dataContaminantBalance.clear_state()
        self.dataConvect.clear_state()
        self.dataConvergeParams.clear_state()
        self.dataCoolTower.clear_state()
        self.dataCostEstimateManager.clear_state()
        self.dataCrossVentMgr.clear_state()
        self.dataCurveManager.clear_state()
        self.dataDXCoils.clear_state()
        self.dataDXFEarClipping.clear_state()
        self.dataDaylightingDevices.clear_state()
        self.dataDaylightingDevicesData.clear_state()
        self.dataDayltg.clear_state()
        self.dataDefineEquipment.clear_state()
        self.dataDemandManager.clear_state()
        self.dataDesiccantDehumidifiers.clear_state()
        self.dataDispVentMgr.clear_state()
        self.dataDualDuct.clear_state()
        self.dataDuctLoss.clear_state()
        self.dataEIRFuelFiredHeatPump.clear_state()
        self.dataEIRPlantLoopHeatPump.clear_state()
        self.dataHeatPumpAirToWater.clear_state()
        self.dataEMSMgr.clear_state()
        self.dataEarthTube.clear_state()
        self.dataEcoRoofMgr.clear_state()
        self.dataEconLifeCycleCost.clear_state()
        self.dataEconTariff.clear_state()
        self.dataElectBaseboardRad.clear_state()
        self.dataElectPwrSvcMgr.clear_state()
        self.dataEnvrn.clear_state()
        self.dataErrTracking.clear_state()
        self.dataEvapCoolers.clear_state()
        self.dataEvapFluidCoolers.clear_state()
        self.dataExteriorEnergyUse.clear_state()
        self.dataExternalInterface.clear_state()
        self.dataFanCoilUnits.clear_state()
        self.dataFans.clear_state()
        self.dataFaultsMgr.clear_state()
        self.dataFluidCoolers.clear_state()
        self.dataFluid.clear_state()
        self.dataFourPipeBeam.clear_state()
        self.dataFuelCellElectGen.clear_state()
        self.dataFurnaces.clear_state()
        self.dataGeneral.clear_state()
        self.dataGeneralRoutines.clear_state()
        self.dataGenerator.clear_state()
        self.dataGeneratorFuelSupply.clear_state()
        self.dataGlobal.clear_state()
        self.dataGlobalNames.clear_state()
        self.dataGrndTempModelMgr.clear_state()
        self.dataGroundHeatExchanger.clear_state()
        self.dataHPWaterToWaterClg.clear_state()
        self.dataHPWaterToWaterHtg.clear_state()
        self.dataHPWaterToWaterSimple.clear_state()
        self.dataHVACAssistedCC.clear_state()
        self.dataHVACControllers.clear_state()
        self.dataHVACCooledBeam.clear_state()
        self.dataHVACCtrl.clear_state()
        self.dataHVACDXHeatPumpSys.clear_state()
        self.dataHVACDuct.clear_state()
        self.dataHVACGlobal.clear_state()
        self.dataHVACInterfaceMgr.clear_state()
        self.dataHVACMgr.clear_state()
        self.dataHVACMultiSpdHP.clear_state()
        self.dataHVACSingleDuctInduc.clear_state()
        self.dataHVACSizingSimMgr.clear_state()
        self.dataHVACStandAloneERV.clear_state()
        self.dataHVACUnitaryBypassVAV.clear_state()
        self.dataHVACVarRefFlow.clear_state()
        self.dataHWBaseboardRad.clear_state()
        self.dataHeatBal.clear_state()
        self.dataHeatBalAirMgr.clear_state()
        self.dataHeatBalFanSys.clear_state()
        self.dataHeatBalFiniteDiffMgr.clear_state()
        self.dataHeatBalHAMTMgr.clear_state()
        self.dataHeatBalIntHeatGains.clear_state()
        self.dataHeatBalIntRadExchg.clear_state()
        self.dataHeatBalMgr.clear_state()
        self.dataHeatBalSurf.clear_state()
        self.dataHeatBalSurfMgr.clear_state()
        self.dataHeatRecovery.clear_state()
        self.dataHeatingCoils.clear_state()
        self.dataHighTempRadSys.clear_state()
        self.dataHumidifiers.clear_state()
        self.dataHybridModel.clear_state()
        self.dataHybridUnitaryAC.clear_state()
        self.dataHysteresisPhaseChange.clear_state()
        self.dataICEngElectGen.clear_state()
        self.dataIPShortCut.clear_state()
        self.dataIceThermalStorage.clear_state()
        self.dataIndoorGreen.clear_state()
        self.dataInputProcessing.clear_state()
        self.dataIntegratedHP.clear_state()
        self.dataInternalHeatGains.clear_state()
        self.dataLoopNodes.clear_state()
        self.dataLowTempRadSys.clear_state()
        self.dataMaterial.clear_state()
        self.dataMatrixDataManager.clear_state()
        self.dataMircoturbElectGen.clear_state()
        self.dataMixedAir.clear_state()
        self.dataMixerComponent.clear_state()
        self.dataMoistureBalEMPD.clear_state()
        self.dataMstBal.clear_state()
        self.dataMstBalEMPD.clear_state()
        self.dataMundtSimMgr.clear_state()
        self.dataNodeInputMgr.clear_state()
        self.dataOutAirNodeMgr.clear_state()
        self.dataOutRptPredefined.clear_state()
        self.dataOutRptTab.clear_state()
        self.dataOutdoorAirUnit.clear_state()
        self.dataOutput.clear_state()
        self.dataOutputProcessor.clear_state()
        self.dataOutputReportTabularAnnual.clear_state()
        self.dataOutputReports.clear_state()
        self.dataOutsideEnergySrcs.clear_state()
        self.dataPackagedThermalStorageCoil.clear_state()
        self.dataPhotovoltaic.clear_state()
        self.dataPhotovoltaicState.clear_state()
        self.dataPhotovoltaicThermalCollector.clear_state()
        self.dataPipeHT.clear_state()
        self.dataPipes.clear_state()
        self.dataPlantCentralGSHP.clear_state()
        self.dataPlantChillers.clear_state()
        self.dataPlantCompTempSrc.clear_state()
        self.dataPlantCondLoopOp.clear_state()
        self.dataPlantHXFluidToFluid.clear_state()
        self.dataPlantLoadProfile.clear_state()
        self.dataPlantMgr.clear_state()
        self.dataPlantPipingSysMgr.clear_state()
        self.dataPlantPressureSys.clear_state()
        self.dataPlantUtilities.clear_state()
        self.dataPlantValves.clear_state()
        self.dataPlnt.clear_state()
        self.dataPluginManager.clear_state()
        self.dataPollution.clear_state()
        self.dataPondGHE.clear_state()
        self.dataPowerInductionUnits.clear_state()
        self.dataPsychrometrics.clear_state()
        self.dataPsychCache.clear_state()
        self.dataPumps.clear_state()
        self.dataPurchasedAirMgr.clear_state()
        self.dataRefrigCase.clear_state()
        self.dataReportFlag.clear_state()
        self.dataResultsFramework.clear_state()
        self.dataRetAirPathMrg.clear_state()
        self.dataExhAirSystemMrg.clear_state()
        self.dataExhCtrlSystemMrg.clear_state()
        self.dataRoomAir.clear_state()
        self.dataRoomAirModelTempPattern.clear_state()
        self.dataRoomAirflowNetModel.clear_state()
        self.dataRootFinder.clear_state()
        self.dataRptCoilSelection.clear_state()
        self.dataRuntimeLang.clear_state()
        self.dataRuntimeLangProcessor.clear_state()
        self.dataSQLiteProcedures.clear_state()
        self.dataSched.clear_state()
        self.dataSetPointManager.clear_state()
        self.dataShadowComb.clear_state()
        self.dataSimAirServingZones.clear_state()
        self.dataSimulationManager.clear_state()
        self.dataSingleDuct.clear_state()
        self.dataSize.clear_state()
        self.dataSizingManager.clear_state()
        self.dataSolarCollectors.clear_state()
        self.dataSolarReflectionManager.clear_state()
        self.dataSolarShading.clear_state()
        self.dataSplitterComponent.clear_state()
        self.dataSteamBaseboardRadiator.clear_state()
        self.dataSteamCoils.clear_state()
        self.dataStrGlobals.clear_state()
        self.dataSurfColor.clear_state()
        self.dataSurfLists.clear_state()
        self.dataSurface.clear_state()
        self.dataSurfaceGeometry.clear_state()
        self.dataSurfaceGroundHeatExchangers.clear_state()
        self.dataSwimmingPools.clear_state()
        self.dataSysAirFlowSizer.clear_state()
        self.dataSysRpts.clear_state()
        self.dataSysVars.clear_state()
        self.dataAvail.clear_state()
        self.dataTARCOGCommon.clear_state()
        self.dataTARCOGOutputs.clear_state()
        self.dataThermalChimneys.clear_state()
        self.dataThermalComforts.clear_state()
        self.dataThermalISO15099Calc.clear_state()
        self.dataTARCOGGasses90.clear_state()
        self.dataTARCOGMain.clear_state()
        self.dataTarcogShading.clear_state()
        self.dataTimingsData.clear_state()
        self.dataTranspiredCollector.clear_state()
        self.dataUFADManager.clear_state()
        self.dataUnitHeaters.clear_state()
        self.dataUnitVentilators.clear_state()
        self.dataUnitarySystems.clear_state()
        self.dataUserDefinedComponents.clear_state()
        self.dataUtilityRoutines.clear_state()
        self.dataVariableSpeedCoils.clear_state()
        self.dataVectors.clear_state()
        self.dataVentilatedSlab.clear_state()
        self.dataViewFactor.clear_state()
        self.dataWaterCoils.clear_state()
        self.dataWaterData.clear_state()
        self.dataWaterManager.clear_state()
        self.dataWaterThermalTanks.clear_state()
        self.dataWaterToAirHeatPump.clear_state()
        self.dataWaterToAirHeatPumpSimple.clear_state()
        self.dataWaterUse.clear_state()
        self.dataWeather.clear_state()
        self.dataWindTurbine.clear_state()
        self.dataWindowAC.clear_state()
        self.dataWindowComplexManager.clear_state()
        self.dataWindowEquivLayer.clear_state()
        self.dataWindowEquivalentLayer.clear_state()
        self.dataWindowManager.clear_state()
        self.dataWindowManagerExterior.clear_state()
        self.dataZoneAirLoopEquipmentManager.clear_state()
        self.dataZoneContaminantPredictorCorrector.clear_state()
        self.dataZoneCtrls.clear_state()
        self.dataZoneDehumidifier.clear_state()
        self.dataZoneEnergyDemand.clear_state()
        self.dataZoneEquip.clear_state()
        self.dataZoneEquipmentManager.clear_state()
        self.dataZonePlenum.clear_state()
        self.dataZoneTempPredictorCorrector.clear_state()
        self.files.debug.close()
        self.files.err_stream.reset()
        self.files.eso.close()
        self.files.mtr.close()
        self.files.mtr.close()
        self.files.shade.close()
        self.files.ssz.close()
        self.files.psz.close()
        self.files.zsz.close()
        self.files.spsz.close()
    def init_constant_state(inout self, inout state: EnergyPlusData):
        if self.init_constant_state_called:
            return
        self.init_constant_state_called = True
        self.dataSimulationManager.init_constant_state(state)
        self.dataEMSMgr.init_constant_state(state)
        self.dataPsychrometrics.init_constant_state(state)
        self.dataFluid.init_constant_state(state)
        self.dataSched.init_constant_state(state)
        self.dataCurveManager.init_constant_state(state)
        self.dataAirLoop.init_constant_state(state)
        self.dataAirLoopHVACDOAS.init_constant_state(state)
        self.dataAirSystemsData.init_constant_state(state)
        self.afn.init_constant_state(state)
        self.dataBSDFWindow.init_constant_state(state)
        self.dataBaseSizerFanHeatInputs.init_constant_state(state)
        self.dataBaseSizerScalableInputs.init_constant_state(state)
        self.dataBaseboardElectric.init_constant_state(state)
        self.dataBaseboardRadiator.init_constant_state(state)
        self.dataBoilerSteam.init_constant_state(state)
        self.dataBoilers.init_constant_state(state)
        self.dataBranchAirLoopPlant.init_constant_state(state)
        self.dataBranchInputManager.init_constant_state(state)
        self.dataBranchNodeConnections.init_constant_state(state)
        self.dataCHPElectGen.init_constant_state(state)
        self.dataCTElectricGenerator.init_constant_state(state)
        self.dataChilledCeilingPanelSimple.init_constant_state(state)
        self.dataChillerAbsorber.init_constant_state(state)
        self.dataChillerElectricEIR.init_constant_state(state)
        self.dataChillerExhaustAbsorption.init_constant_state(state)
        self.dataChillerGasAbsorption.init_constant_state(state)
        self.dataChillerIndirectAbsorption.init_constant_state(state)
        self.dataChillerReformulatedEIR.init_constant_state(state)
        self.dataChillerElectricASHRAE205.init_constant_state(state)
        self.dataCoilCoolingDX.init_constant_state(state)
        self.dataCondenserLoopTowers.init_constant_state(state)
        self.dataConstruction.init_constant_state(state)
        self.dataContaminantBalance.init_constant_state(state)
        self.dataConvect.init_constant_state(state)
        self.dataConvergeParams.init_constant_state(state)
        self.dataCoolTower.init_constant_state(state)
        self.dataCostEstimateManager.init_constant_state(state)
        self.dataCrossVentMgr.init_constant_state(state)
        self.dataDXCoils.init_constant_state(state)
        self.dataDXFEarClipping.init_constant_state(state)
        self.dataDaylightingDevices.init_constant_state(state)
        self.dataDaylightingDevicesData.init_constant_state(state)
        self.dataDayltg.init_constant_state(state)
        self.dataDefineEquipment.init_constant_state(state)
        self.dataDemandManager.init_constant_state(state)
        self.dataDesiccantDehumidifiers.init_constant_state(state)
        self.dataDispVentMgr.init_constant_state(state)
        self.dataDualDuct.init_constant_state(state)
        self.dataEIRFuelFiredHeatPump.init_constant_state(state)
        self.dataEIRPlantLoopHeatPump.init_constant_state(state)
        self.dataHeatPumpAirToWater.init_constant_state(state)
        self.dataEarthTube.init_constant_state(state)
        self.dataEcoRoofMgr.init_constant_state(state)
        self.dataEconLifeCycleCost.init_constant_state(state)
        self.dataEconTariff.init_constant_state(state)
        self.dataElectBaseboardRad.init_constant_state(state)
        self.dataElectPwrSvcMgr.init_constant_state(state)
        self.dataEnvrn.init_constant_state(state)
        self.dataErrTracking.init_constant_state(state)
        self.dataEvapCoolers.init_constant_state(state)
        self.dataEvapFluidCoolers.init_constant_state(state)
        self.dataExteriorEnergyUse.init_constant_state(state)
        self.dataExternalInterface.init_constant_state(state)
        self.dataFanCoilUnits.init_constant_state(state)
        self.dataFans.init_constant_state(state)
        self.dataFaultsMgr.init_constant_state(state)
        self.dataFluidCoolers.init_constant_state(state)
        self.dataFourPipeBeam.init_constant_state(state)
        self.dataFuelCellElectGen.init_constant_state(state)
        self.dataFurnaces.init_constant_state(state)
        self.dataGeneral.init_constant_state(state)
        self.dataGeneralRoutines.init_constant_state(state)
        self.dataGenerator.init_constant_state(state)
        self.dataGeneratorFuelSupply.init_constant_state(state)
        self.dataGlobal.init_constant_state(state)
        self.dataGlobalNames.init_constant_state(state)
        self.dataGrndTempModelMgr.init_constant_state(state)
        self.dataGroundHeatExchanger.init_constant_state(state)
        self.dataHPWaterToWaterClg.init_constant_state(state)
        self.dataHPWaterToWaterHtg.init_constant_state(state)
        self.dataHPWaterToWaterSimple.init_constant_state(state)
        self.dataHVACAssistedCC.init_constant_state(state)
        self.dataHVACControllers.init_constant_state(state)
        self.dataHVACCooledBeam.init_constant_state(state)
        self.dataHVACCtrl.init_constant_state(state)
        self.dataHVACDXHeatPumpSys.init_constant_state(state)
        self.dataHVACDuct.init_constant_state(state)
        self.dataHVACGlobal.init_constant_state(state)
        self.dataHVACInterfaceMgr.init_constant_state(state)
        self.dataHVACMgr.init_constant_state(state)
        self.dataHVACMultiSpdHP.init_constant_state(state)
        self.dataHVACSingleDuctInduc.init_constant_state(state)
        self.dataHVACSizingSimMgr.init_constant_state(state)
        self.dataHVACStandAloneERV.init_constant_state(state)
        self.dataHVACUnitaryBypassVAV.init_constant_state(state)
        self.dataHVACVarRefFlow.init_constant_state(state)
        self.dataHWBaseboardRad.init_constant_state(state)
        self.dataHeatBal.init_constant_state(state)
        self.dataHeatBalAirMgr.init_constant_state(state)
        self.dataHeatBalFanSys.init_constant_state(state)
        self.dataHeatBalFiniteDiffMgr.init_constant_state(state)
        self.dataHeatBalHAMTMgr.init_constant_state(state)
        self.dataHeatBalIntHeatGains.init_constant_state(state)
        self.dataHeatBalIntRadExchg.init_constant_state(state)
        self.dataHeatBalMgr.init_constant_state(state)
        self.dataHeatBalSurf.init_constant_state(state)
        self.dataHeatBalSurfMgr.init_constant_state(state)
        self.dataHeatRecovery.init_constant_state(state)
        self.dataHeatingCoils.init_constant_state(state)
        self.dataHighTempRadSys.init_constant_state(state)
        self.dataHumidifiers.init_constant_state(state)
        self.dataHybridModel.init_constant_state(state)
        self.dataHybridUnitaryAC.init_constant_state(state)
        self.dataHysteresisPhaseChange.init_constant_state(state)
        self.dataICEngElectGen.init_constant_state(state)
        self.dataIPShortCut.init_constant_state(state)
        self.dataIceThermalStorage.init_constant_state(state)
        self.dataIndoorGreen.init_constant_state(state)
        self.dataInputProcessing.init_constant_state(state)
        self.dataIntegratedHP.init_constant_state(state)
        self.dataInternalHeatGains.init_constant_state(state)
        self.dataLoopNodes.init_constant_state(state)
        self.dataLowTempRadSys.init_constant_state(state)
        self.dataMaterial.init_constant_state(state)
        self.dataMatrixDataManager.init_constant_state(state)
        self.dataMircoturbElectGen.init_constant_state(state)
        self.dataMixedAir.init_constant_state(state)
        self.dataMixerComponent.init_constant_state(state)
        self.dataMoistureBalEMPD.init_constant_state(state)
        self.dataMstBal.init_constant_state(state)
        self.dataMstBalEMPD.init_constant_state(state)
        self.dataMundtSimMgr.init_constant_state(state)
        self.dataNodeInputMgr.init_constant_state(state)
        self.dataOutAirNodeMgr.init_constant_state(state)
        self.dataOutRptPredefined.init_constant_state(state)
        self.dataOutRptTab.init_constant_state(state)
        self.dataOutdoorAirUnit.init_constant_state(state)
        self.dataOutput.init_constant_state(state)
        self.dataOutputProcessor.init_constant_state(state)
        self.dataOutputReportTabularAnnual.init_constant_state(state)
        self.dataOutputReports.init_constant_state(state)
        self.dataOutsideEnergySrcs.init_constant_state(state)
        self.dataPackagedThermalStorageCoil.init_constant_state(state)
        self.dataPhotovoltaic.init_constant_state(state)
        self.dataPhotovoltaicState.init_constant_state(state)
        self.dataPhotovoltaicThermalCollector.init_constant_state(state)
        self.dataPipeHT.init_constant_state(state)
        self.dataPipes.init_constant_state(state)
        self.dataPlantCentralGSHP.init_constant_state(state)
        self.dataPlantChillers.init_constant_state(state)
        self.dataPlantCompTempSrc.init_constant_state(state)
        self.dataPlantCondLoopOp.init_constant_state(state)
        self.dataPlantHXFluidToFluid.init_constant_state(state)
        self.dataPlantLoadProfile.init_constant_state(state)
        self.dataPlantMgr.init_constant_state(state)
        self.dataPlantPipingSysMgr.init_constant_state(state)
        self.dataPlantPressureSys.init_constant_state(state)
        self.dataPlantUtilities.init_constant_state(state)
        self.dataPlantValves.init_constant_state(state)
        self.dataPlnt.init_constant_state(state)
        self.dataPluginManager.init_constant_state(state)
        self.dataPollution.init_constant_state(state)
        self.dataPondGHE.init_constant_state(state)
        self.dataPowerInductionUnits.init_constant_state(state)
        self.dataPsychCache.init_constant_state(state)
        self.dataPumps.init_constant_state(state)
        self.dataPurchasedAirMgr.init_constant_state(state)
        self.dataRefrigCase.init_constant_state(state)
        self.dataReportFlag.init_constant_state(state)
        self.dataResultsFramework.init_constant_state(state)
        self.dataRetAirPathMrg.init_constant_state(state)
        self.dataExhAirSystemMrg.init_constant_state(state)
        self.dataExhCtrlSystemMrg.init_constant_state(state)
        self.dataRoomAir.init_constant_state(state)
        self.dataRoomAirModelTempPattern.init_constant_state(state)
        self.dataRoomAirflowNetModel.init_constant_state(state)
        self.dataRootFinder.init_constant_state(state)
        self.dataRptCoilSelection.init_constant_state(state)
        self.dataRuntimeLang.init_constant_state(state)
        self.dataRuntimeLangProcessor.init_constant_state(state)
        self.dataSQLiteProcedures.init_constant_state(state)
        self.dataSetPointManager.init_constant_state(state)
        self.dataShadowComb.init_constant_state(state)
        self.dataSimAirServingZones.init_constant_state(state)
        self.dataSingleDuct.init_constant_state(state)
        self.dataSize.init_constant_state(state)
        self.dataSizingManager.init_constant_state(state)
        self.dataSolarCollectors.init_constant_state(state)
        self.dataSolarReflectionManager.init_constant_state(state)
        self.dataSolarShading.init_constant_state(state)
        self.dataSplitterComponent.init_constant_state(state)
        self.dataSteamBaseboardRadiator.init_constant_state(state)
        self.dataSteamCoils.init_constant_state(state)
        self.dataStrGlobals.init_constant_state(state)
        self.dataSurfColor.init_constant_state(state)
        self.dataSurfLists.init_constant_state(state)
        self.dataSurface.init_constant_state(state)
        self.dataSurfaceGeometry.init_constant_state(state)
        self.dataSurfaceGroundHeatExchangers.init_constant_state(state)
        self.dataSwimmingPools.init_constant_state(state)
        self.dataSysAirFlowSizer.init_constant_state(state)
        self.dataSysRpts.init_constant_state(state)
        self.dataSysVars.init_constant_state(state)
        self.dataAvail.init_constant_state(state)
        self.dataTARCOGCommon.init_constant_state(state)
        self.dataTARCOGOutputs.init_constant_state(state)
        self.dataThermalChimneys.init_constant_state(state)
        self.dataThermalComforts.init_constant_state(state)
        self.dataThermalISO15099Calc.init_constant_state(state)
        self.dataTARCOGGasses90.init_constant_state(state)
        self.dataTARCOGMain.init_constant_state(state)
        self.dataTarcogShading.init_constant_state(state)
        self.dataTimingsData.init_constant_state(state)
        self.dataTranspiredCollector.init_constant_state(state)
        self.dataUFADManager.init_constant_state(state)
        self.dataUnitHeaters.init_constant_state(state)
        self.dataUnitVentilators.init_constant_state(state)
        self.dataUnitarySystems.init_constant_state(state)
        self.dataUserDefinedComponents.init_constant_state(state)
        self.dataUtilityRoutines.init_constant_state(state)
        self.dataVariableSpeedCoils.init_constant_state(state)
        self.dataVectors.init_constant_state(state)
        self.dataVentilatedSlab.init_constant_state(state)
        self.dataViewFactor.init_constant_state(state)
        self.dataWaterCoils.init_constant_state(state)
        self.dataWaterData.init_constant_state(state)
        self.dataWaterManager.init_constant_state(state)
        self.dataWaterThermalTanks.init_constant_state(state)
        self.dataWaterToAirHeatPump.init_constant_state(state)
        self.dataWaterToAirHeatPumpSimple.init_constant_state(state)
        self.dataWaterUse.init_constant_state(state)
        self.dataWeather.init_constant_state(state)
        self.dataWindTurbine.init_constant_state(state)
        self.dataWindowAC.init_constant_state(state)
        self.dataWindowComplexManager.init_constant_state(state)
        self.dataWindowEquivLayer.init_constant_state(state)
        self.dataWindowEquivalentLayer.init_constant_state(state)
        self.dataWindowManager.init_constant_state(state)
        self.dataWindowManagerExterior.init_constant_state(state)
        self.dataZoneAirLoopEquipmentManager.init_constant_state(state)
        self.dataZoneContaminantPredictorCorrector.init_constant_state(state)
        self.dataZoneCtrls.init_constant_state(state)
        self.dataZoneDehumidifier.init_constant_state(state)
        self.dataZoneEnergyDemand.init_constant_state(state)
        self.dataZoneEquip.init_constant_state(state)
        self.dataZoneEquipmentManager.init_constant_state(state)
        self.dataZonePlenum.init_constant_state(state)
        self.dataZoneTempPredictorCorrector.init_constant_state(state)
    def init_state(inout self, inout state: EnergyPlusData):
        if self.init_state_called:
            return
        self.init_state_called = True
        self.dataSimulationManager.init_state(state)
        self.dataEMSMgr.init_state(state)
        self.dataPsychrometrics.init_state(state)
        self.dataFluid.init_state(state)
        self.dataSched.init_state(state)
        self.dataCurveManager.init_state(state)
        self.dataAirLoop.init_state(state)
        self.dataAirLoopHVACDOAS.init_state(state)
        self.dataAirSystemsData.init_state(state)
        self.afn.init_state(state)
        self.dataBSDFWindow.init_state(state)
        self.dataBaseSizerFanHeatInputs.init_state(state)
        self.dataBaseSizerScalableInputs.init_state(state)
        self.dataBaseboardElectric.init_state(state)
        self.dataBaseboardRadiator.init_state(state)
        self.dataBoilerSteam.init_state(state)
        self.dataBoilers.init_state(state)
        self.dataBranchAirLoopPlant.init_state(state)
        self.dataBranchInputManager.init_state(state)
        self.dataBranchNodeConnections.init_state(state)
        self.dataCHPElectGen.init_state(state)
        self.dataCTElectricGenerator.init_state(state)
        self.dataChilledCeilingPanelSimple.init_state(state)
        self.dataChillerAbsorber.init_state(state)
        self.dataChillerElectricEIR.init_state(state)
        self.dataChillerExhaustAbsorption.init_state(state)
        self.dataChillerGasAbsorption.init_state(state)
        self.dataChillerIndirectAbsorption.init_state(state)
        self.dataChillerReformulatedEIR.init_state(state)
        self.dataChillerElectricASHRAE205.init_state(state)
        self.dataCoilCoolingDX.init_state(state)
        self.dataCondenserLoopTowers.init_state(state)
        self.dataConstruction.init_state(state)
        self.dataContaminantBalance.init_state(state)
        self.dataConvect.init_state(state)
        self.dataConvergeParams.init_state(state)
        self.dataCoolTower.init_state(state)
        self.dataCostEstimateManager.init_state(state)
        self.dataCrossVentMgr.init_state(state)
        self.dataDXCoils.init_state(state)
        self.dataDXFEarClipping.init_state(state)
        self.dataDaylightingDevices.init_state(state)
        self.dataDaylightingDevicesData.init_state(state)
        self.dataDayltg.init_state(state)
        self.dataDefineEquipment.init_state(state)
        self.dataDemandManager.init_state(state)
        self.dataDesiccantDehumidifiers.init_state(state)
        self.dataDispVentMgr.init_state(state)
        self.dataDualDuct.init_state(state)
        self.dataEIRFuelFiredHeatPump.init_state(state)
        self.dataEIRPlantLoopHeatPump.init_state(state)
        self.dataHeatPumpAirToWater.init_state(state)
        self.dataEarthTube.init_state(state)
        self.dataEcoRoofMgr.init_state(state)
        self.dataEconLifeCycleCost.init_state(state)
        self.dataEconTariff.init_state(state)
        self.dataElectBaseboardRad.init_state(state)
        self.dataElectPwrSvcMgr.init_state(state)
        self.dataEnvrn.init_state(state)
        self.dataErrTracking.init_state(state)
        self.dataEvapCoolers.init_state(state)
        self.dataEvapFluidCoolers.init_state(state)
        self.dataExteriorEnergyUse.init_state(state)
        self.dataExternalInterface.init_state(state)
        self.dataFanCoilUnits.init_state(state)
        self.dataFans.init_state(state)
        self.dataFaultsMgr.init_state(state)
        self.dataFluidCoolers.init_state(state)
        self.dataFourPipeBeam.init_state(state)
        self.dataFuelCellElectGen.init_state(state)
        self.dataFurnaces.init_state(state)
        self.dataGeneral.init_state(state)
        self.dataGeneralRoutines.init_state(state)
        self.dataGenerator.init_state(state)
        self.dataGeneratorFuelSupply.init_state(state)
        self.dataGlobal.init_state(state)
        self.dataGlobalNames.init_state(state)
        self.dataGrndTempModelMgr.init_state(state)
        self.dataGroundHeatExchanger.init_state(state)
        self.dataHPWaterToWaterClg.init_state(state)
        self.dataHPWaterToWaterHtg.init_state(state)
        self.dataHPWaterToWaterSimple.init_state(state)
        self.dataHVACAssistedCC.init_state(state)
        self.dataHVACControllers.init_state(state)
        self.dataHVACCooledBeam.init_state(state)
        self.dataHVACCtrl.init_state(state)
        self.dataHVACDXHeatPumpSys.init_state(state)
        self.dataHVACDuct.init_state(state)
        self.dataHVACGlobal.init_state(state)
        self.dataHVACInterfaceMgr.init_state(state)
        self.dataHVACMgr.init_state(state)
        self.dataHVACMultiSpdHP.init_state(state)
        self.dataHVACSingleDuctInduc.init_state(state)
        self.dataHVACSizingSimMgr.init_state(state)
        self.dataHVACStandAloneERV.init_state(state)
        self.dataHVACUnitaryBypassVAV.init_state(state)
        self.dataHVACVarRefFlow.init_state(state)
        self.dataHWBaseboardRad.init_state(state)
        self.dataHeatBal.init_state(state)
        self.dataHeatBalAirMgr.init_state(state)
        self.dataHeatBalFanSys.init_state(state)
        self.dataHeatBalFiniteDiffMgr.init_state(state)
        self.dataHeatBalHAMTMgr.init_state(state)
        self.dataHeatBalIntHeatGains.init_state(state)
        self.dataHeatBalIntRadExchg.init_state(state)
        self.dataHeatBalMgr.init_state(state)
        self.dataHeatBalSurf.init_state(state)
        self.dataHeatBalSurfMgr.init_state(state)
        self.dataHeatRecovery.init_state(state)
        self.dataHeatingCoils.init_state(state)
        self.dataHighTempRadSys.init_state(state)
        self.dataHumidifiers.init_state(state)
        self.dataHybridModel.init_state(state)
        self.dataHybridUnitaryAC.init_state(state)
        self.dataHysteresisPhaseChange.init_state(state)
        self.dataICEngElectGen.init_state(state)
        self.dataIPShortCut.init_state(state)
        self.dataIceThermalStorage.init_state(state)
        self.dataIndoorGreen.init_state(state)
        self.dataInputProcessing.init_state(state)
        self.dataIntegratedHP.init_state(state)
        self.dataInternalHeatGains.init_state(state)
        self.dataLoopNodes.init_state(state)
        self.dataLowTempRadSys.init_state(state)
        self.dataMaterial.init_state(state)
        self.dataMatrixDataManager.init_state(state)
        self.dataMircoturbElectGen.init_state(state)
        self.dataMixedAir.init_state(state)
        self.dataMixerComponent.init_state(state)
        self.dataMoistureBalEMPD.init_state(state)
        self.dataMstBal.init_state(state)
        self.dataMstBalEMPD.init_state(state)
        self.dataMundtSimMgr.init_state(state)
        self.dataNodeInputMgr.init_state(state)
        self.dataOutAirNodeMgr.init_state(state)
        self.dataOutRptPredefined.init_state(state)
        self.dataOutRptTab.init_state(state)
        self.dataOutdoorAirUnit.init_state(state)
        self.dataOutput.init_state(state)
        self.dataOutputProcessor.init_state(state)
        self.dataOutputReportTabularAnnual.init_state(state)
        self.dataOutputReports.init_state(state)
        self.dataOutsideEnergySrcs.init_state(state)
        self.dataPackagedThermalStorageCoil.init_state(state)
        self.dataPhotovoltaic.init_state(state)
        self.dataPhotovoltaicState.init_state(state)
        self.dataPhotovoltaicThermalCollector.init_state(state)
        self.dataPipeHT.init_state(state)
        self.dataPipes.init_state(state)
        self.dataPlantCentralGSHP.init_state(state)
        self.dataPlantChillers.init_state(state)
        self.dataPlantCompTempSrc.init_state(state)
        self.dataPlantCondLoopOp.init_state(state)
        self.dataPlantHXFluidToFluid.init_state(state)
        self.dataPlantLoadProfile.init_state(state)
        self.dataPlantMgr.init_state(state)
        self.dataPlantPipingSysMgr.init_state(state)
        self.dataPlantPressureSys.init_state(state)
        self.dataPlantUtilities.init_state(state)
        self.dataPlantValves.init_state(state)
        self.dataPlnt.init_state(state)
        self.dataPluginManager.init_state(state)
        self.dataPollution.init_state(state)
        self.dataPondGHE.init_state(state)
        self.dataPowerInductionUnits.init_state(state)
        self.dataPsychCache.init_state(state)
        self.dataPumps.init_state(state)
        self.dataPurchasedAirMgr.init_state(state)
        self.dataRefrigCase.init_state(state)
        self.dataReportFlag.init_state(state)
        self.dataResultsFramework.init_state(state)
        self.dataRetAirPathMrg.init_state(state)
        self.dataExhAirSystemMrg.init_state(state)
        self.dataExhCtrlSystemMrg.init_state(state)
        self.dataRoomAir.init_state(state)
        self.dataRoomAirModelTempPattern.init_state(state)
        self.dataRoomAirflowNetModel.init_state(state)
        self.dataRootFinder.init_state(state)
        self.dataRptCoilSelection.init_state(state)
        self.dataRuntimeLang.init_state(state)
        self.dataRuntimeLangProcessor.init_state(state)
        self.dataSQLiteProcedures.init_state(state)
        self.dataSetPointManager.init_state(state)
        self.dataShadowComb.init_state(state)
        self.dataSimAirServingZones.init_state(state)
        self.dataSingleDuct.init_state(state)
        self.dataSize.init_state(state)
        self.dataSizingManager.init_state(state)
        self.dataSolarCollectors.init_state(state)
        self.dataSolarReflectionManager.init_state(state)
        self.dataSolarShading.init_state(state)
        self.dataSplitterComponent.init_state(state)
        self.dataSteamBaseboardRadiator.init_state(state)
        self.dataSteamCoils.init_state(state)
        self.dataStrGlobals.init_state(state)
        self.dataSurfColor.init_state(state)
        self.dataSurfLists.init_state(state)
        self.dataSurface.init_state(state)
        self.dataSurfaceGeometry.init_state(state)
        self.dataSurfaceGroundHeatExchangers.init_state(state)
        self.dataSwimmingPools.init_state(state)
        self.dataSysAirFlowSizer.init_state(state)
        self.dataSysRpts.init_state(state)
        self.dataSysVars.init_state(state)
        self.dataAvail.init_state(state)
        self.dataTARCOGCommon.init_state(state)
        self.dataTARCOGOutputs.init_state(state)
        self.dataThermalChimneys.init_state(state)
        self.dataThermalComforts.init_state(state)
        self.dataThermalISO15099Calc.init_state(state)
        self.dataTARCOGGasses90.init_state(state)
        self.dataTARCOGMain.init_state(state)
        self.dataTarcogShading.init_state(state)
        self.dataTimingsData.init_state(state)
        self.dataTranspiredCollector.init_state(state)
        self.dataUFADManager.init_state(state)
        self.dataUnitHeaters.init_state(state)
        self.dataUnitVentilators.init_state(state)
        self.dataUnitarySystems.init_state(state)
        self.dataUserDefinedComponents.init_state(state)
        self.dataUtilityRoutines.init_state(state)
        self.dataVariableSpeedCoils.init_state(state)
        self.dataVectors.init_state(state)
        self.dataVentilatedSlab.init_state(state)
        self.dataViewFactor.init_state(state)
        self.dataWaterCoils.init_state(state)
        self.dataWaterData.init_state(state)
        self.dataWaterManager.init_state(state)
        self.dataWaterThermalTanks.init_state(state)
        self.dataWaterToAirHeatPump.init_state(state)
        self.dataWaterToAirHeatPumpSimple.init_state(state)
        self.dataWaterUse.init_state(state)
        self.dataWeather.init_state(state)
        self.dataWindTurbine.init_state(state)
        self.dataWindowAC.init_state(state)
        self.dataWindowComplexManager.init_state(state)
        self.dataWindowEquivLayer.init_state(state)
        self.dataWindowEquivalentLayer.init_state(state)
        self.dataWindowManager.init_state(state)
        self.dataWindowManagerExterior.init_state(state)
        self.dataZoneAirLoopEquipmentManager.init_state(state)
        self.dataZoneContaminantPredictorCorrector.init_state(state)
        self.dataZoneCtrls.init_state(state)
        self.dataZoneDehumidifier.init_state(state)
        self.dataZoneEnergyDemand.init_state(state)
        self.dataZoneEquip.init_state(state)
        self.dataZoneEquipmentManager.init_state(state)
        self.dataZonePlenum.init_state(state)
        self.dataZoneTempPredictorCorrector.init_state(state)
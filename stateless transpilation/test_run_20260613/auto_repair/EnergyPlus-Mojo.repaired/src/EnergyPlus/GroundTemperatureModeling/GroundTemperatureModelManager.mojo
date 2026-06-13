from BaseGroundTemperatureModel import BaseGroundTempsModel, ModelType
from FiniteDifferenceGroundTemperatureModel import FiniteDiffGroundTempsModel
from KusudaAchenbachGroundTemperatureModel import KusudaGroundTempsModel
from SiteBuildingSurfaceGroundTemperatures import SiteBuildingSurfaceGroundTemps
from SiteDeepGroundTemperatures import SiteDeepGroundTemps
from SiteFCFactorMethodGroundTemperatures import SiteFCFactorMethodGroundTemps
from SiteShallowGroundTemperatures import SiteShallowGroundTemps
from XingGroundTemperatureModel import XingGroundTempsModel
from EnergyPlusData import EnergyPlusData
from <vector> import vector

@value
struct EnergyPlus::GroundTemp:

    @staticmethod
    def GetGroundTempModelAndInit(state: EnergyPlusData, modelType: ModelType, name: String) -> BaseGroundTempsModel:
        for gtm in state.dataGrndTempModelMgr.groundTempModels:
            if modelType == gtm.modelType and name == gtm.Name:
                return gtm
        match modelType:
            case ModelType.Kusuda:
                return KusudaGroundTempsModel.KusudaGTMFactory(state, name)
            case ModelType.FiniteDiff:
                return FiniteDiffGroundTempsModel.FiniteDiffGTMFactory(state, name)
            case ModelType.SiteBuildingSurface:
                return SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory(state, name)
            case ModelType.SiteShallow:
                return SiteShallowGroundTemps.ShallowGTMFactory(state, name)
            case ModelType.SiteDeep:
                return SiteDeepGroundTemps.DeepGTMFactory(state, name)
            case ModelType.SiteFCFactorMethod:
                return SiteFCFactorMethodGroundTemps.FCFactorGTMFactory(state, name)
            case ModelType.Xing:
                return XingGroundTempsModel.XingGTMFactory(state, name)
            case _:
                assert False, "Unknown model type"
                return None
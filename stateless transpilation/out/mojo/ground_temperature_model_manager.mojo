# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container
# - ModelType: enum for ground temperature model types
# - BaseGroundTempsModel: base struct for models
# - GroundTempModelManager: container for models (dataGrndTempModelMgr member)
# - KusudaGroundTempsModel.KusudaGTMFactory: factory from GroundTemperatureModeling.KusudaAchenbachGroundTemperatureModel
# - FiniteDiffGroundTempsModel.FiniteDiffGTMFactory: factory from GroundTemperatureModeling.FiniteDifferenceGroundTemperatureModel
# - SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory: factory from GroundTemperatureModeling.SiteBuildingSurfaceGroundTemperatures
# - SiteShallowGroundTemps.ShallowGTMFactory: factory from GroundTemperatureModeling.SiteShallowGroundTemperatures
# - SiteDeepGroundTemps.DeepGTMFactory: factory from GroundTemperatureModeling.SiteDeepGroundTemperatures
# - SiteFCFactorMethodGroundTemps.FCFactorGTMFactory: factory from GroundTemperatureModeling.SiteFCFactorMethodGroundTemperatures
# - XingGroundTempsModel.XingGTMFactory: factory from GroundTemperatureModeling.XingGroundTemperatureModel

from memory import UnsafePointer
from collections import List


enum ModelType:
    Kusuda = 0
    FiniteDiff = 1
    SiteBuildingSurface = 2
    SiteShallow = 3
    SiteDeep = 4
    SiteFCFactorMethod = 5
    Xing = 6


struct BaseGroundTempsModel:
    var modelType: ModelType
    var Name: String


struct GroundTempModelManager:
    var groundTempModels: List[UnsafePointer[BaseGroundTempsModel]]


struct EnergyPlusData:
    var dataGrndTempModelMgr: UnsafePointer[GroundTempModelManager]


struct KusudaGroundTempsModel:
    @staticmethod
    fn KusudaGTMFactory(state: EnergyPlusData, name: String) -> UnsafePointer[BaseGroundTempsModel]:
        assert False, "Not implemented"
        return UnsafePointer[BaseGroundTempsModel]()


struct FiniteDiffGroundTempsModel:
    @staticmethod
    fn FiniteDiffGTMFactory(state: EnergyPlusData, name: String) -> UnsafePointer[BaseGroundTempsModel]:
        assert False, "Not implemented"
        return UnsafePointer[BaseGroundTempsModel]()


struct SiteBuildingSurfaceGroundTemps:
    @staticmethod
    fn BuildingSurfaceGTMFactory(state: EnergyPlusData, name: String) -> UnsafePointer[BaseGroundTempsModel]:
        assert False, "Not implemented"
        return UnsafePointer[BaseGroundTempsModel]()


struct SiteShallowGroundTemps:
    @staticmethod
    fn ShallowGTMFactory(state: EnergyPlusData, name: String) -> UnsafePointer[BaseGroundTempsModel]:
        assert False, "Not implemented"
        return UnsafePointer[BaseGroundTempsModel]()


struct SiteDeepGroundTemps:
    @staticmethod
    fn DeepGTMFactory(state: EnergyPlusData, name: String) -> UnsafePointer[BaseGroundTempsModel]:
        assert False, "Not implemented"
        return UnsafePointer[BaseGroundTempsModel]()


struct SiteFCFactorMethodGroundTemps:
    @staticmethod
    fn FCFactorGTMFactory(state: EnergyPlusData, name: String) -> UnsafePointer[BaseGroundTempsModel]:
        assert False, "Not implemented"
        return UnsafePointer[BaseGroundTempsModel]()


struct XingGroundTempsModel:
    @staticmethod
    fn XingGTMFactory(state: EnergyPlusData, name: String) -> UnsafePointer[BaseGroundTempsModel]:
        assert False, "Not implemented"
        return UnsafePointer[BaseGroundTempsModel]()


fn GetGroundTempModelAndInit(
    state: EnergyPlusData,
    modelType: ModelType,
    name: String
) -> UnsafePointer[BaseGroundTempsModel]:
    for gtm in state.dataGrndTempModelMgr[].groundTempModels:
        if modelType == gtm[].modelType and name == gtm[].Name:
            return gtm

    if modelType == ModelType.Kusuda:
        return KusudaGroundTempsModel.KusudaGTMFactory(state, name)
    elif modelType == ModelType.FiniteDiff:
        return FiniteDiffGroundTempsModel.FiniteDiffGTMFactory(state, name)
    elif modelType == ModelType.SiteBuildingSurface:
        return SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory(state, name)
    elif modelType == ModelType.SiteShallow:
        return SiteShallowGroundTemps.ShallowGTMFactory(state, name)
    elif modelType == ModelType.SiteDeep:
        return SiteDeepGroundTemps.DeepGTMFactory(state, name)
    elif modelType == ModelType.SiteFCFactorMethod:
        return SiteFCFactorMethodGroundTemps.FCFactorGTMFactory(state, name)
    elif modelType == ModelType.Xing:
        return XingGroundTempsModel.XingGTMFactory(state, name)
    else:
        assert False
        return UnsafePointer[BaseGroundTempsModel]()

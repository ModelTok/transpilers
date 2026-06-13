# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (from EnergyPlus.Data.EnergyPlusData)
# - ModelType: enum for ground temperature model types
# - BaseGroundTempsModel: base class for models
# - GroundTempModelManager: container for models (dataGrndTempModelMgr member)
# - KusudaGroundTempsModel.KusudaGTMFactory: factory from GroundTemperatureModeling.KusudaAchenbachGroundTemperatureModel
# - FiniteDiffGroundTempsModel.FiniteDiffGTMFactory: factory from GroundTemperatureModeling.FiniteDifferenceGroundTemperatureModel
# - SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory: factory from GroundTemperatureModeling.SiteBuildingSurfaceGroundTemperatures
# - SiteShallowGroundTemps.ShallowGTMFactory: factory from GroundTemperatureModeling.SiteShallowGroundTemperatures
# - SiteDeepGroundTemps.DeepGTMFactory: factory from GroundTemperatureModeling.SiteDeepGroundTemperatures
# - SiteFCFactorMethodGroundTemps.FCFactorGTMFactory: factory from GroundTemperatureModeling.SiteFCFactorMethodGroundTemperatures
# - XingGroundTempsModel.XingGTMFactory: factory from GroundTemperatureModeling.XingGroundTemperatureModel

from enum import Enum
from typing import Optional, Protocol, List


class ModelType(Enum):
    Kusuda = 0
    FiniteDiff = 1
    SiteBuildingSurface = 2
    SiteShallow = 3
    SiteDeep = 4
    SiteFCFactorMethod = 5
    Xing = 6


class BaseGroundTempsModel:
    def __init__(self):
        self.modelType: Optional[ModelType] = None
        self.Name: str = ""


class GroundTempModelManager(Protocol):
    groundTempModels: List[BaseGroundTempsModel]


class EnergyPlusDataState(Protocol):
    dataGrndTempModelMgr: GroundTempModelManager


class KusudaGroundTempsModel:
    @staticmethod
    def KusudaGTMFactory(state: EnergyPlusDataState, name: str) -> Optional[BaseGroundTempsModel]:
        raise NotImplementedError()


class FiniteDiffGroundTempsModel:
    @staticmethod
    def FiniteDiffGTMFactory(state: EnergyPlusDataState, name: str) -> Optional[BaseGroundTempsModel]:
        raise NotImplementedError()


class SiteBuildingSurfaceGroundTemps:
    @staticmethod
    def BuildingSurfaceGTMFactory(state: EnergyPlusDataState, name: str) -> Optional[BaseGroundTempsModel]:
        raise NotImplementedError()


class SiteShallowGroundTemps:
    @staticmethod
    def ShallowGTMFactory(state: EnergyPlusDataState, name: str) -> Optional[BaseGroundTempsModel]:
        raise NotImplementedError()


class SiteDeepGroundTemps:
    @staticmethod
    def DeepGTMFactory(state: EnergyPlusDataState, name: str) -> Optional[BaseGroundTempsModel]:
        raise NotImplementedError()


class SiteFCFactorMethodGroundTemps:
    @staticmethod
    def FCFactorGTMFactory(state: EnergyPlusDataState, name: str) -> Optional[BaseGroundTempsModel]:
        raise NotImplementedError()


class XingGroundTempsModel:
    @staticmethod
    def XingGTMFactory(state: EnergyPlusDataState, name: str) -> Optional[BaseGroundTempsModel]:
        raise NotImplementedError()


def GetGroundTempModelAndInit(
    state: EnergyPlusDataState,
    modelType: ModelType,
    name: str
) -> Optional[BaseGroundTempsModel]:
    for gtm in state.dataGrndTempModelMgr.groundTempModels:
        if modelType == gtm.modelType and name == gtm.Name:
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
        return None

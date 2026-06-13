# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.
#
# NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
# U.S. Government consequently retains certain rights. As such, the U.S. Government has been
# granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
# worldwide license in the Software to reproduce, distribute copies to the public, prepare
# derivative works, and perform publicly and display publicly, and to permit others to do so.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice, this list of
#     conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice, this list of
#     conditions and the following disclaimer in the documentation and/or other materials
#     provided with the distribution.
#
# (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
#     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
#     used to endorse or promote products derived from this software without specific prior
#     written permission.
#
# (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
#     without changes from the version obtained under this License, or (ii) Licensee makes a
#     reference solely to the software portion of its product, Licensee must refer to the
#     software as "EnergyPlus version X" software, where "X" is the version number Licensee
#     obtained under this License and may not use a different name for the software. Except as
#     specifically required in this Section (4), Licensee shall not use in a company name, a
#     product name, in advertising, publicity, or other promotional activities any name, trade
#     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
#     similar designation, without the U.S. Department of Energy's prior written consent.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

from enum import Enum
from typing import Any, Dict, List, Optional, Protocol

# EXTERNAL DEPS (to wire in glue):
#   EnergyPlusData (from EnergyPlus/Data/EnergyPlusData.hh) -> EnergyPlusDataProtocol
#   ModelType (from EnergyPlus/GroundTemperatureModelManager.hh) -> ModelType (defined below)
#   BaseGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/BaseGroundTemperatureModel.hh) -> BaseGroundTempsModel (defined below)
#   KusudaGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/KusudaAchenbachGroundTemperatureModel.hh) -> stub
#   FiniteDiffGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/FiniteDifferenceGroundTemperatureModel.hh) -> stub
#   SiteBuildingSurfaceGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteBuildingSurfaceGroundTemperatures.hh) -> stub
#   SiteShallowGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteShallowGroundTemperatures.hh) -> stub
#   SiteDeepGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteDeepGroundTemperatures.hh) -> stub
#   SiteFCFactorMethodGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteFCFactorMethodGroundTemperatures.hh) -> stub
#   XingGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/XingGroundTemperatureModel.hh) -> stub

class ModelType(Enum):
    Kusuda = 1
    FiniteDiff = 2
    SiteBuildingSurface = 3
    SiteShallow = 4
    SiteDeep = 5
    SiteFCFactorMethod = 6
    Xing = 7

class EnergyPlusDataProtocol(Protocol):
    groundTempModels: List['BaseGroundTempsModel']

class BaseGroundTempsModel:
    def __init__(self) -> None:
        self.modelType: ModelType = ModelType.Kusuda
        self.Name: str = ""

# Stub factory classes (to be implemented elsewhere)
class KusudaGroundTempsModel(BaseGroundTempsModel):
    @staticmethod
    def KusudaGTMFactory(state: EnergyPlusDataProtocol, name: str) -> 'KusudaGroundTempsModel':
        instance = KusudaGroundTempsModel()
        instance.modelType = ModelType.Kusuda
        instance.Name = name
        state.groundTempModels.append(instance)
        return instance

class FiniteDiffGroundTempsModel(BaseGroundTempsModel):
    @staticmethod
    def FiniteDiffGTMFactory(state: EnergyPlusDataProtocol, name: str) -> 'FiniteDiffGroundTempsModel':
        instance = FiniteDiffGroundTempsModel()
        instance.modelType = ModelType.FiniteDiff
        instance.Name = name
        state.groundTempModels.append(instance)
        return instance

class SiteBuildingSurfaceGroundTemps(BaseGroundTempsModel):
    @staticmethod
    def BuildingSurfaceGTMFactory(state: EnergyPlusDataProtocol, name: str) -> 'SiteBuildingSurfaceGroundTemps':
        instance = SiteBuildingSurfaceGroundTemps()
        instance.modelType = ModelType.SiteBuildingSurface
        instance.Name = name
        state.groundTempModels.append(instance)
        return instance

class SiteShallowGroundTemps(BaseGroundTempsModel):
    @staticmethod
    def ShallowGTMFactory(state: EnergyPlusDataProtocol, name: str) -> 'SiteShallowGroundTemps':
        instance = SiteShallowGroundTemps()
        instance.modelType = ModelType.SiteShallow
        instance.Name = name
        state.groundTempModels.append(instance)
        return instance

class SiteDeepGroundTemps(BaseGroundTempsModel):
    @staticmethod
    def DeepGTMFactory(state: EnergyPlusDataProtocol, name: str) -> 'SiteDeepGroundTemps':
        instance = SiteDeepGroundTemps()
        instance.modelType = ModelType.SiteDeep
        instance.Name = name
        state.groundTempModels.append(instance)
        return instance

class SiteFCFactorMethodGroundTemps(BaseGroundTempsModel):
    @staticmethod
    def FCFactorGTMFactory(state: EnergyPlusDataProtocol, name: str) -> 'SiteFCFactorMethodGroundTemps':
        instance = SiteFCFactorMethodGroundTemps()
        instance.modelType = ModelType.SiteFCFactorMethod
        instance.Name = name
        state.groundTempModels.append(instance)
        return instance

class XingGroundTempsModel(BaseGroundTempsModel):
    @staticmethod
    def XingGTMFactory(state: EnergyPlusDataProtocol, name: str) -> 'XingGroundTempsModel':
        instance = XingGroundTempsModel()
        instance.modelType = ModelType.Xing
        instance.Name = name
        state.groundTempModels.append(instance)
        return instance

def GetGroundTempModelAndInit(state: EnergyPlusDataProtocol, modelType: ModelType, name: str) -> Optional[BaseGroundTempsModel]:
    # Check if this instance of this model has already been retrieved
    for gtm in state.groundTempModels:
        # Check if the type and name match
        if modelType == gtm.modelType and name == gtm.Name:
            return gtm

    # If not found, create new instance of the model
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
        assert False, "Unexpected ModelType in GetGroundTempModelAndInit"
        return None

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

# EXTERNAL DEPS (to wire in glue):
#   EnergyPlusData (from EnergyPlus/Data/EnergyPlusData.hh) -> EnergyPlusData trait below
#   ModelType (from EnergyPlus/GroundTemperatureModelManager.hh) -> ModelType enum below
#   BaseGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/BaseGroundTemperatureModel.hh) -> BaseGroundTempsModel struct below
#   KusudaGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/KusudaAchenbachGroundTemperatureModel.hh) -> stub
#   FiniteDiffGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/FiniteDifferenceGroundTemperatureModel.hh) -> stub
#   SiteBuildingSurfaceGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteBuildingSurfaceGroundTemperatures.hh) -> stub
#   SiteShallowGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteShallowGroundTemperatures.hh) -> stub
#   SiteDeepGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteDeepGroundTemperatures.hh) -> stub
#   SiteFCFactorMethodGroundTemps (from EnergyPlus/GroundTemperatureModeling/SiteFCFactorMethodGroundTemperatures.hh) -> stub
#   XingGroundTempsModel (from EnergyPlus/GroundTemperatureModeling/XingGroundTemperatureModel.hh) -> stub

from collections import InlinedVector

@value
struct ModelType:
    var value: Int
    alias Kusuda = Self(1)
    alias FiniteDiff = Self(2)
    alias SiteBuildingSurface = Self(3)
    alias SiteShallow = Self(4)
    alias SiteDeep = Self(5)
    alias SiteFCFactorMethod = Self(6)
    alias Xing = Self(7)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

struct BaseGroundTempsModel:
    var modelType: ModelType
    var Name: String

    fn __init__(inout self):
        self.modelType = ModelType.Kusuda
        self.Name = ""

trait EnergyPlusData:
    var groundTempModels: InlinedVector[BaseGroundTempsModel, 100]

# Stub factory structs (to be implemented elsewhere)
struct KusudaGroundTempsModel(BaseGroundTempsModel):
    @staticmethod
    fn KusudaGTMFactory[_E: EnergyPlusData](state: _E, name: String) -> KusudaGroundTempsModel:
        var instance = KusudaGroundTempsModel()
        instance.modelType = ModelType.Kusuda
        instance.Name = name
        state.groundTempModels.append(instance^)
        return instance^

struct FiniteDiffGroundTempsModel(BaseGroundTempsModel):
    @staticmethod
    fn FiniteDiffGTMFactory[_E: EnergyPlusData](state: _E, name: String) -> FiniteDiffGroundTempsModel:
        var instance = FiniteDiffGroundTempsModel()
        instance.modelType = ModelType.FiniteDiff
        instance.Name = name
        state.groundTempModels.append(instance^)
        return instance^

struct SiteBuildingSurfaceGroundTemps(BaseGroundTempsModel):
    @staticmethod
    fn BuildingSurfaceGTMFactory[_E: EnergyPlusData](state: _E, name: String) -> SiteBuildingSurfaceGroundTemps:
        var instance = SiteBuildingSurfaceGroundTemps()
        instance.modelType = ModelType.SiteBuildingSurface
        instance.Name = name
        state.groundTempModels.append(instance^)
        return instance^

struct SiteShallowGroundTemps(BaseGroundTempsModel):
    @staticmethod
    fn ShallowGTMFactory[_E: EnergyPlusData](state: _E, name: String) -> SiteShallowGroundTemps:
        var instance = SiteShallowGroundTemps()
        instance.modelType = ModelType.SiteShallow
        instance.Name = name
        state.groundTempModels.append(instance^)
        return instance^

struct SiteDeepGroundTemps(BaseGroundTempsModel):
    @staticmethod
    fn DeepGTMFactory[_E: EnergyPlusData](state: _E, name: String) -> SiteDeepGroundTemps:
        var instance = SiteDeepGroundTemps()
        instance.modelType = ModelType.SiteDeep
        instance.Name = name
        state.groundTempModels.append(instance^)
        return instance^

struct SiteFCFactorMethodGroundTemps(BaseGroundTempsModel):
    @staticmethod
    fn FCFactorGTMFactory[_E: EnergyPlusData](state: _E, name: String) -> SiteFCFactorMethodGroundTemps:
        var instance = SiteFCFactorMethodGroundTemps()
        instance.modelType = ModelType.SiteFCFactorMethod
        instance.Name = name
        state.groundTempModels.append(instance^)
        return instance^

struct XingGroundTempsModel(BaseGroundTempsModel):
    @staticmethod
    fn XingGTMFactory[_E: EnergyPlusData](state: _E, name: String) -> XingGroundTempsModel:
        var instance = XingGroundTempsModel()
        instance.modelType = ModelType.Xing
        instance.Name = name
        state.groundTempModels.append(instance^)
        return instance^

fn GetGroundTempModelAndInit[_E: EnergyPlusData](state: _E, modelType: ModelType, name: String) -> Optional[BaseGroundTempsModel]:
    # Check if this instance of this model has already been retrieved
    for i in range(len(state.groundTempModels)):
        let gtm = state.groundTempModels[i]
        # Check if the type and name match
        if modelType == gtm.modelType and name == gtm.Name:
            return gtm

    # If not found, create new instance of the model
    if modelType == ModelType.Kusuda:
        return KusudaGroundTempsModel.KusudaGTMFactory[_E](state, name)
    elif modelType == ModelType.FiniteDiff:
        return FiniteDiffGroundTempsModel.FiniteDiffGTMFactory[_E](state, name)
    elif modelType == ModelType.SiteBuildingSurface:
        return SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory[_E](state, name)
    elif modelType == ModelType.SiteShallow:
        return SiteShallowGroundTemps.ShallowGTMFactory[_E](state, name)
    elif modelType == ModelType.SiteDeep:
        return SiteDeepGroundTemps.DeepGTMFactory[_E](state, name)
    elif modelType == ModelType.SiteFCFactorMethod:
        return SiteFCFactorMethodGroundTemps.FCFactorGTMFactory[_E](state, name)
    elif modelType == ModelType.Xing:
        return XingGroundTempsModel.XingGTMFactory[_E](state, name)
    else:
        assert(False, "Unexpected ModelType in GetGroundTempModelAndInit")
        return None

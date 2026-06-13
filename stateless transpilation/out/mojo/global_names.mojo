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
# - EnergyPlusData: main state object (from EnergyPlus.Data.EnergyPlusData)
# - BaseGlobalStruct: base struct for global data (from EnergyPlus.Data.BaseData)
# - ShowSevereError(state: EnergyPlusData, msg: String) -> None (from EnergyPlus.UtilityRoutines)
# - ShowContinueError(state: EnergyPlusData, msg: String) -> None (from EnergyPlus.UtilityRoutines)
# - Util.makeUPPER(s: String) -> String (from EnergyPlus.UtilityRoutines)

struct ComponentNameData:
    var CompType: String
    var CompName: String
    
    fn __init__(inout self):
        self.CompType = String()
        self.CompName = String()

struct GlobalNamesData:
    var NumChillers: Int32
    var NumBoilers: Int32
    var NumBaseboards: Int32
    var NumCoils: Int32
    var CurMaxChillers: Int32
    var CurMaxCoils: Int32
    var numAirDistUnits: Int32
    var ChillerNames: Dict[String, String]
    var BoilerNames: Dict[String, String]
    var BaseboardNames: Dict[String, String]
    var CoilNames: Dict[String, String]
    var aDUNames: Dict[String, String]
    
    fn __init__(inout self):
        self.NumChillers = 0
        self.NumBoilers = 0
        self.NumBaseboards = 0
        self.NumCoils = 0
        self.CurMaxChillers = 0
        self.CurMaxCoils = 0
        self.numAirDistUnits = 0
        self.ChillerNames = Dict[String, String]()
        self.BoilerNames = Dict[String, String]()
        self.BaseboardNames = Dict[String, String]()
        self.CoilNames = Dict[String, String]()
        self.aDUNames = Dict[String, String]()
    
    fn init_constant_state(inout self, state: EnergyPlusData):
        pass
    
    fn init_state(inout self, state: EnergyPlusData):
        pass
    
    fn clear_state(inout self):
        self.NumChillers = 0
        self.NumBoilers = 0
        self.NumBaseboards = 0
        self.NumCoils = 0
        self.CurMaxChillers = 0
        self.CurMaxCoils = 0
        self.numAirDistUnits = 0
        self.ChillerNames.clear()
        self.BoilerNames.clear()
        self.BaseboardNames.clear()
        self.CoilNames.clear()
        self.aDUNames.clear()

fn IntraObjUniquenessCheck(state: EnergyPlusData, NameToVerify: String,
                          CurrentModuleObject: String, FieldName: String,
                          inout UniqueStrings: Dict[String, Int32],
                          inout ErrorsFound: Bool):
    if not NameToVerify:
        ShowSevereError(state, f"E+ object type {CurrentModuleObject} cannot have a blank {FieldName} field")
        ErrorsFound = True
        return
    
    if NameToVerify not in UniqueStrings:
        UniqueStrings[NameToVerify] = 1
    else:
        ErrorsFound = True
        ShowSevereError(state, f"{CurrentModuleObject} has a duplicate field {NameToVerify}")

fn VerifyUniqueInterObjectName(state: EnergyPlusData, inout names: Dict[String, String],
                              object_name: String, object_type: String,
                              field_name: String, inout ErrorsFound: Bool) -> Bool:
    if not object_name:
        ShowSevereError(state, f"E+ object type {object_name} cannot have blank {field_name} field")
        ErrorsFound = True
        return True
    
    if object_name in names:
        ErrorsFound = True
        ShowSevereError(state, f"{object_name} with object type {object_type} duplicates a name in object type {names[object_name]}")
        return True
    else:
        names[object_name] = object_type
    
    return False

fn VerifyUniqueInterObjectName(state: EnergyPlusData, inout names: Dict[String, String],
                              object_name: String, object_type: String,
                              inout ErrorsFound: Bool) -> Bool:
    if not object_name:
        ShowSevereError(state, f"E+ object type {object_name} has a blank field")
        ErrorsFound = True
        return True
    
    if object_name in names:
        ErrorsFound = True
        ShowSevereError(state, f"{object_name} with object type {object_type} duplicates a name in object type {names[object_name]}")
        return True
    else:
        names[object_name] = object_type
    
    return False

fn VerifyUniqueChillerName(state: EnergyPlusData, TypeToVerify: String, NameToVerify: String,
                          inout ErrorsFound: Bool, StringToDisplay: String):
    var iter_result = state.dataGlobalNames.ChillerNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Chiller Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Chiller Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.ChillerNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumChillers = len(state.dataGlobalNames.ChillerNames)

fn VerifyUniqueBaseboardName(state: EnergyPlusData, TypeToVerify: String, NameToVerify: String,
                            inout ErrorsFound: Bool, StringToDisplay: String):
    var iter_result = state.dataGlobalNames.BaseboardNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Baseboard Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Baseboard Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.BaseboardNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumBaseboards = len(state.dataGlobalNames.BaseboardNames)

fn VerifyUniqueBoilerName(state: EnergyPlusData, TypeToVerify: String, NameToVerify: String,
                         inout ErrorsFound: Bool, StringToDisplay: String):
    var iter_result = state.dataGlobalNames.BoilerNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Boiler Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Boiler Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.BoilerNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumBoilers = len(state.dataGlobalNames.BoilerNames)

fn VerifyUniqueCoilName(state: EnergyPlusData, TypeToVerify: String, inout NameToVerify: String,
                       inout ErrorsFound: Bool, StringToDisplay: String):
    if not NameToVerify:
        ShowSevereError(state, f"\"{TypeToVerify}\" cannot have a blank field")
        ErrorsFound = True
        NameToVerify = "xxxxx"
        return
    
    var iter_result = state.dataGlobalNames.CoilNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Coil Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Coil Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.CoilNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumCoils = len(state.dataGlobalNames.CoilNames)

fn VerifyUniqueADUName(state: EnergyPlusData, TypeToVerify: String, NameToVerify: String,
                      inout ErrorsFound: Bool, StringToDisplay: String):
    var iter_result = state.dataGlobalNames.aDUNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, ADU Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Air Distribution Unit Type=\"{TypeToVerify}\".")
        ErrorsFound = True
    else:
        state.dataGlobalNames.aDUNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.numAirDistUnits = len(state.dataGlobalNames.aDUNames)

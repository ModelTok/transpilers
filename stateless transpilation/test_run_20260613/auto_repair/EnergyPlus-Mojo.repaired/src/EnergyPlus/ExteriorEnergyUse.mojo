// EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
// The Regents of the University of California, through Lawrence Berkeley National Laboratory
// (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
// National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
// contributors. All rights reserved.
//
// NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
// U.S. Government consequently retains certain rights. As such, the U.S. Government has been
// granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
// worldwide license in the Software to reproduce, distribute copies to the public, prepare
// derivative works, and perform publicly and display publicly, and to permit others to do so.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted
// provided that the following conditions are met:
//
// (1) Redistributions of source code must retain the above copyright notice, this list of
//     conditions and the following disclaimer.
//
// (2) Redistributions in binary form must reproduce the above copyright notice, this list of
//     conditions and the following disclaimer in the documentation and/or other materials
//     provided with the distribution.
//
// (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
//     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
//     used to endorse or promote products derived from this software without specific prior
//     written permission.
//
// (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
//     without changes from the version obtained under this License, or (ii) Licensee makes a
//     reference solely to the software portion of its product, Licensee must refer to the
//     software as "EnergyPlus version X" software, where "X" is the version number Licensee
//     obtained under this License and may not use a different name for the software. Except as
//     specifically required in this Section (4), Licensee shall not use in a company name, a
//     product name, in advertising, publicity, or other promotional activities any name, trade
//     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
//     similar designation, without the U.S. Department of Energy's prior written consent.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataGlobalConstants import *
from EMSManager import *
from ExteriorEnergyUse import ExteriorLightUsage, ExteriorEquipmentUsage, LightControlType, ManageExteriorEnergyUse, GetExteriorEnergyUseInput, ReportExteriorEnergyUse
from GlobalNames import *
from InputProcessing.InputProcessor import *
from OutputProcessor import *
from OutputReportPredefined import *
from ScheduleManager import *
from UtilityRoutines import *

@value
struct ExteriorEnergyUse:

def ManageExteriorEnergyUse(inout state: EnergyPlusData):
    # LINE: "//     PURPOSE: Manage the Exterior Energy Use"
    # LINE: "//     METHODOLOGY: Get the exterior energy use input and report"
    # LINE: "//     REFERENCES: "
    # LINE: "//     na"
    # LINE: "//"
    # LINE: "    // na"

    if state.dataExteriorEnergyUse.GetExteriorEnergyInputFlag:
        ExteriorEnergyUse.GetExteriorEnergyUseInput(state)
        state.dataExteriorEnergyUse.GetExteriorEnergyInputFlag = False

    ExteriorEnergyUse.ReportExteriorEnergyUse(state)

def GetExteriorEnergyUseInput(inout state: EnergyPlusData):
    # LINE: "//     PURPOSE: Get the exterior energy use input from the input file"
    # LINE: "//     METHODOLOGY: Get the exterior lights and exterior equipment objects"
    # LINE: "//     REFERENCES: "
    # LINE: "//     na"
    # LINE: "//"
    # LINE: "    // na"

    using OutputReportPredefined

    var routineName: StringLiteral = "GetExteriorEnergyUseInput"

    var ErrorsFound: Bool = False
    var EndUseSubcategoryName: String
    var inputProcessor: unique_ptr[InputProcessor] = state.dataInputProcessing.inputProcessor.get()

    state.dataExteriorEnergyUse.NumExteriorLights = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Exterior:Lights")
    state.dataExteriorEnergyUse.ExteriorLights.allocate(state.dataExteriorEnergyUse.NumExteriorLights)

    var NumFuelEq: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Exterior:FuelEquipment")
    var NumWtrEq: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Exterior:WaterEquipment")
    state.dataExteriorEnergyUse.ExteriorEquipment.allocate(NumFuelEq + NumWtrEq)
    state.dataExteriorEnergyUse.UniqueExteriorEquipNames.reserve(NumFuelEq + NumWtrEq)

    state.dataExteriorEnergyUse.GetExteriorEnergyInputFlag = False
    state.dataExteriorEnergyUse.NumExteriorEqs = 0

    # LINE: "    // Get Exterior Lights"
    var cCurrentModuleObject: String = "Exterior:Lights"
    var ref exteriorLightsSchemaProps = inputProcessor.getObjectSchemaProps(state, cCurrentModuleObject)
    var ref exteriorLightsObjects = inputProcessor.epJSON.find(cCurrentModuleObject)
    if exteriorLightsObjects != inputProcessor.epJSON.end():
        var Item: Int = 1
        for ref lightInstance in exteriorLightsObjects.value().items():
            var ref lightFields = lightInstance.value()
            var lightName: String = Util.makeUPPER(lightInstance.key())
            var scheduleName: String = inputProcessor.getAlphaFieldValue(lightFields, exteriorLightsSchemaProps, "schedule_name")
            var controlOption: String
            if lightFields.contains("control_option"):
                controlOption = inputProcessor.getAlphaFieldValue(lightFields, exteriorLightsSchemaProps, "control_option")
            else:
                controlOption = string()

            inputProcessor.markObjectAsUsed(cCurrentModuleObject, lightInstance.key())

            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, lightName)

            state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name = lightName

            if scheduleName.empty():
                ShowSevereEmptyField(state, eoh, "schedule_name")
                ErrorsFound = True
            elif (state.dataExteriorEnergyUse.ExteriorLights[Item - 1].sched = Sched.GetSchedule(state, scheduleName)) is None:
                ShowSevereItemNotFound(state, eoh, "schedule_name", scheduleName)
                ErrorsFound = True
            elif int SchMin = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].sched.getMinVal(state); SchMin < 0.0:
                ShowSevereCustom(state, eoh, std.format("{} = {} minimum is [{}]. Values must be >= 0.0.".format("schedule_name", scheduleName, SchMin)))
                ErrorsFound = True

            if controlOption.empty():
                state.dataExteriorEnergyUse.ExteriorLights[Item - 1].ControlMode = LightControlType.ScheduleOnly
            elif Util.SameString(controlOption, "ScheduleNameOnly"):
                state.dataExteriorEnergyUse.ExteriorLights[Item - 1].ControlMode = LightControlType.ScheduleOnly
            elif Util.SameString(controlOption, "AstronomicalClock"):
                state.dataExteriorEnergyUse.ExteriorLights[Item - 1].ControlMode = LightControlType.AstroClockOverride
            else:
                ShowSevereInvalidKey(state, eoh, "control_option", controlOption)

            if lightFields.find("end_use_subcategory") != lightFields.end():
                EndUseSubcategoryName = inputProcessor.getAlphaFieldValue(lightFields, exteriorLightsSchemaProps, "end_use_subcategory")
            else:
                EndUseSubcategoryName = "General"

            state.dataExteriorEnergyUse.ExteriorLights[Item - 1].DesignLevel = inputProcessor.getRealFieldValue(lightFields, exteriorLightsSchemaProps, "design_level")
            if state.dataGlobal.AnyEnergyManagementSystemInModel:
                SetupEMSActuator(state, "ExteriorLights", state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name, "Electricity Rate", "W", state.dataExteriorEnergyUse.ExteriorLights[Item - 1].PowerActuatorOn, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].PowerActuatorValue)

            SetupOutputVariable(state, "Exterior Lights Electricity Rate", Constant.Units.W, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name)

            SetupOutputVariable(state, "Exterior Lights Electricity Energy", Constant.Units.J, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name, Constant.eResource.Electricity, OutputProcessor.Group.Invalid, OutputProcessor.EndUseCat.ExteriorLights, EndUseSubcategoryName)

            PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtPower, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].DesignLevel)
            state.dataExteriorEnergyUse.sumDesignLevel += state.dataExteriorEnergyUse.ExteriorLights[Item - 1].DesignLevel
            if state.dataExteriorEnergyUse.ExteriorLights[Item - 1].ControlMode == LightControlType.AstroClockOverride:
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtClock, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name, "AstronomicalClock")
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtSchd, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name, "-")
            else:
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtClock, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name, "Schedule")
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtSchd, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Name, state.dataExteriorEnergyUse.ExteriorLights[Item - 1].sched.Name)
            Item += 1

    PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtPower, "Exterior Lighting Total", state.dataExteriorEnergyUse.sumDesignLevel)

    # LINE: "    // Get Exterior Fuel Equipment"

    cCurrentModuleObject = "Exterior:FuelEquipment"
    var ref exteriorFuelSchemaProps = inputProcessor.getObjectSchemaProps(state, cCurrentModuleObject)
    var ref exteriorFuelObjects = inputProcessor.epJSON.find(cCurrentModuleObject)
    if exteriorFuelObjects != inputProcessor.epJSON.end():
        for ref fuelEquipInstance in exteriorFuelObjects.value().items():
            var ref fuelEquipFields = fuelEquipInstance.value()
            var equipName: String = Util.makeUPPER(fuelEquipInstance.key())
            var fuelUseType: String = inputProcessor.getAlphaFieldValue(fuelEquipFields, exteriorFuelSchemaProps, "fuel_use_type")
            var scheduleName: String = inputProcessor.getAlphaFieldValue(fuelEquipFields, exteriorFuelSchemaProps, "schedule_name")

            inputProcessor.markObjectAsUsed(cCurrentModuleObject, fuelEquipInstance.key())
            GlobalNames.VerifyUniqueInterObjectName(state, state.dataExteriorEnergyUse.UniqueExteriorEquipNames, equipName, cCurrentModuleObject, "Name", ErrorsFound)

            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, equipName)

            state.dataExteriorEnergyUse.NumExteriorEqs += 1

            var ref exteriorEquip = state.dataExteriorEnergyUse.ExteriorEquipment[state.dataExteriorEnergyUse.NumExteriorEqs - 1]
            exteriorEquip.Name = equipName

            if fuelEquipFields.find("end_use_subcategory") != fuelEquipFields.end():
                EndUseSubcategoryName = inputProcessor.getAlphaFieldValue(fuelEquipFields, exteriorFuelSchemaProps, "end_use_subcategory")
            else:
                EndUseSubcategoryName = "General"

            if fuelUseType.empty():
                ShowSevereEmptyField(state, eoh, "fuel_use_type")
                ErrorsFound = True
            elif (exteriorEquip.FuelType = (Constant.eFuel)(getEnumValue(Constant.eFuelNamesUC, fuelUseType))) == Constant.eFuel.Invalid:
                ShowSevereInvalidKey(state, eoh, "fuel_use_type", fuelUseType)
                ErrorsFound = True
            elif exteriorEquip.FuelType != Constant.eFuel.Water:
                SetupOutputVariable(state, "Exterior Equipment Fuel Rate", Constant.Units.W, exteriorEquip.Power, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, exteriorEquip.Name)
                SetupOutputVariable(state, std.format("Exterior Equipment {} Energy".format(Constant.eFuelNames[int(exteriorEquip.FuelType)])), Constant.Units.J, exteriorEquip.CurrentUse, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, exteriorEquip.Name, Constant.eFuel2eResource[int(exteriorEquip.FuelType)], OutputProcessor.Group.Invalid, OutputProcessor.EndUseCat.ExteriorEquipment, EndUseSubcategoryName)
            else:
                SetupOutputVariable(state, "Exterior Equipment Water Volume Flow Rate", Constant.Units.m3_s, exteriorEquip.Power, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, exteriorEquip.Name)
                SetupOutputVariable(state, std.format("Exterior Equipment {} Volume".format(Constant.eFuelNames[int(exteriorEquip.FuelType)])), Constant.Units.m3, exteriorEquip.CurrentUse, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, exteriorEquip.Name, Constant.eFuel2eResource[int(exteriorEquip.FuelType)], OutputProcessor.Group.Invalid, OutputProcessor.EndUseCat.ExteriorEquipment, EndUseSubcategoryName)

            if scheduleName.empty():
                ShowSevereEmptyField(state, eoh, "schedule_name")
                ErrorsFound = True
            elif (exteriorEquip.sched = Sched.GetSchedule(state, scheduleName)) is None:
                ShowSevereItemNotFound(state, eoh, "schedule_name", scheduleName)
                ErrorsFound = True
            elif int SchMin = exteriorEquip.sched.getMinVal(state); SchMin < 0.0:
                ShowSevereCustom(state, eoh, std.format("{} = {} minimum is [{}]. Values must be >= 0.0.".format("schedule_name", scheduleName, SchMin)))
                ErrorsFound = True
            exteriorEquip.DesignLevel = inputProcessor.getRealFieldValue(fuelEquipFields, exteriorFuelSchemaProps, "design_level")

    # LINE: "    // Get Exterior Water Equipment"

    cCurrentModuleObject = "Exterior:WaterEquipment"
    var ref exteriorWaterSchemaProps = inputProcessor.getObjectSchemaProps(state, cCurrentModuleObject)
    var ref exteriorWaterObjects = inputProcessor.epJSON.find(cCurrentModuleObject)
    if exteriorWaterObjects != inputProcessor.epJSON.end():
        for ref waterEquipInstance in exteriorWaterObjects.value().items():
            var ref waterEquipFields = waterEquipInstance.value()
            var equipName: String = Util.makeUPPER(waterEquipInstance.key())
            var scheduleName: String = inputProcessor.getAlphaFieldValue(waterEquipFields, exteriorWaterSchemaProps, "schedule_name")

            inputProcessor.markObjectAsUsed(cCurrentModuleObject, waterEquipInstance.key())

            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, equipName)

            GlobalNames.VerifyUniqueInterObjectName(state, state.dataExteriorEnergyUse.UniqueExteriorEquipNames, equipName, cCurrentModuleObject, "Name", ErrorsFound)

            state.dataExteriorEnergyUse.NumExteriorEqs += 1

            var ref exteriorEquip = state.dataExteriorEnergyUse.ExteriorEquipment[state.dataExteriorEnergyUse.NumExteriorEqs - 1]
            exteriorEquip.Name = equipName
            exteriorEquip.FuelType = Constant.eFuel.Water

            if scheduleName.empty():
                ShowSevereEmptyField(state, eoh, "schedule_name")
                ErrorsFound = True
            elif (exteriorEquip.sched = Sched.GetSchedule(state, scheduleName)) is None:
                ShowSevereItemNotFound(state, eoh, "schedule_name", scheduleName)
                ErrorsFound = True
            elif int SchMin = exteriorEquip.sched.getMinVal(state); SchMin < 0.0:
                ShowSevereCustom(state, eoh, std.format("{} = {} minimum is [{}]. Values must be >= 0.0.".format("schedule_name", scheduleName, SchMin)))
                ErrorsFound = True

            if waterEquipFields.find("end_use_subcategory") != waterEquipFields.end():
                EndUseSubcategoryName = inputProcessor.getAlphaFieldValue(waterEquipFields, exteriorWaterSchemaProps, "end_use_subcategory")
            else:
                EndUseSubcategoryName = "General"

            exteriorEquip.DesignLevel = inputProcessor.getRealFieldValue(waterEquipFields, exteriorWaterSchemaProps, "design_level")

            SetupOutputVariable(state, "Exterior Equipment Water Volume Flow Rate", Constant.Units.m3_s, exteriorEquip.Power, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, exteriorEquip.Name)

            SetupOutputVariable(state, "Exterior Equipment Water Volume", Constant.Units.m3, exteriorEquip.CurrentUse, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, exteriorEquip.Name, Constant.eResource.Water, OutputProcessor.Group.Invalid, OutputProcessor.EndUseCat.ExteriorEquipment, EndUseSubcategoryName)
            SetupOutputVariable(state, "Exterior Equipment Mains Water Volume", Constant.Units.m3, exteriorEquip.CurrentUse, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Sum, exteriorEquip.Name, Constant.eResource.MainsWater, OutputProcessor.Group.Invalid, OutputProcessor.EndUseCat.ExteriorEquipment, EndUseSubcategoryName)

    if ErrorsFound:
        ShowFatalError(state, std.format("{}Errors found in input.  Program terminates.".format(routineName)))

def ReportExteriorEnergyUse(inout state: EnergyPlusData):
    # LINE: "//     PURPOSE: Report the exterior energy use"
    # LINE: "//     METHODOLOGY: Calculates and reports the exterior energy use"
    # LINE: "//     REFERENCES: "
    # LINE: "//     na"
    # LINE: "//"
    # LINE: "    // na"

    for Item in range(1, state.dataExteriorEnergyUse.NumExteriorLights + 1):
        var lightItem = state.dataExteriorEnergyUse.ExteriorLights[Item - 1]
        match lightItem.ControlMode:
            case LightControlType.ScheduleOnly:
                state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].DesignLevel * state.dataExteriorEnergyUse.ExteriorLights[Item - 1].sched.getCurrentVal()
                state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power * state.dataGlobal.TimeStepZoneSec
            case LightControlType.AstroClockOverride:
                if state.dataEnvrn.SunIsUp:
                    state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power = 0.0
                    state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse = 0.0
                else:
                    state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].DesignLevel * state.dataExteriorEnergyUse.ExteriorLights[Item - 1].sched.getCurrentVal()
                    state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power * state.dataGlobal.TimeStepZoneSec
            case _:
                # LINE: "                // Should never come here"

        # LINE: "        // Apply Demand Limiting if appropriate"
        if state.dataExteriorEnergyUse.ExteriorLights[Item - 1].ManageDemand and (state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power > state.dataExteriorEnergyUse.ExteriorLights[Item - 1].DemandLimit):
            state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].DemandLimit
            state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power * state.dataGlobal.TimeStepZoneSec

        # LINE: "        // EMS Override"
        if state.dataExteriorEnergyUse.ExteriorLights[Item - 1].PowerActuatorOn:
            state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].PowerActuatorValue

        state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse = state.dataExteriorEnergyUse.ExteriorLights[Item - 1].Power * state.dataGlobal.TimeStepZoneSec

        # LINE: "        // Update sums"
        if not state.dataGlobal.WarmupFlag:
            # LINE: "            // Only report on the weather period run (i.e., annual run) and not when warmup"
            if state.dataGlobal.DoOutputReporting and (state.dataGlobal.KindOfSim == Constant.KindOfSim.RunPeriodWeather):
                # LINE: "                // Accumulate the sum of energy for each exterior light"
                state.dataExteriorEnergyUse.ExteriorLights[Item - 1].SumConsumption += state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse
                # LINE: "                // Accumulate the sum of time for when energy use is above a threshold."
                if state.dataExteriorEnergyUse.ExteriorLights[Item - 1].CurrentUse > 0.01:
                    state.dataExteriorEnergyUse.ExteriorLights[Item - 1].SumTimeNotZeroCons += state.dataGlobal.TimeStepZone

    for Item in range(1, state.dataExteriorEnergyUse.NumExteriorEqs + 1):
        state.dataExteriorEnergyUse.ExteriorEquipment[Item - 1].Power = state.dataExteriorEnergyUse.ExteriorEquipment[Item - 1].DesignLevel * state.dataExteriorEnergyUse.ExteriorEquipment[Item - 1].sched.getCurrentVal()
        state.dataExteriorEnergyUse.ExteriorEquipment[Item - 1].CurrentUse = state.dataExteriorEnergyUse.ExteriorEquipment[Item - 1].Power * state.dataGlobal.TimeStepZoneSec
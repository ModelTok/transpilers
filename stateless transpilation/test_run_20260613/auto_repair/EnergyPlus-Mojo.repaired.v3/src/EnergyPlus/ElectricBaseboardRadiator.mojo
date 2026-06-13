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

from .Data.BaseData import BaseGlobalStruct
from .DataGlobals import *
from .EnergyPlus import *
from .Autosizing.HeatingCapacitySizing import HeatingCapacitySizer
from .Data.EnergyPlusData import EnergyPlusData
from DataHVACGlobals import *
from .DataHeatBalFanSys import *
from .DataHeatBalSurface import *
from DataHeatBalance import *
from .DataLoopNode import *
from DataSizing import *
from DataSurfaces import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from GeneralRoutines import *
from GlobalNames import *
from HeatBalanceIntRadExchange import *
from HeatBalanceSurfaceManager import *
from .InputProcessing.InputProcessor import *
from OutputProcessor import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *

# Forward declarations
struct EnergyPlusData;

namespace ElectricBaseboardRadiator:

    struct ElecBaseboardParams:
        # Members
        var EquipName: String
        var EquipType: Int = 0
        var Schedule: String
        var SurfaceName: List[String]
        var SurfacePtr: List[Int]
        var ZonePtr: Int = 0
        var availSched: Optional[Sched.Schedule] = None # Assuming availability schedule
        var TotSurfToDistrib: Int = 0
        var NominalCapacity: Float64 = 0.0
        var BaseboardEfficiency: Float64 = 0.0
        var AirInletTemp: Float64 = 0.0
        var AirInletHumRat: Float64 = 0.0
        var AirOutletTemp: Float64 = 0.0
        var ElecUseLoad: Float64 = 0.0
        var ElecUseRate: Float64 = 0.0
        var FracRadiant: Float64 = 0.0
        var FracConvect: Float64 = 0.0
        var FracDistribPerson: Float64 = 0.0
        var TotPower: Float64 = 0.0
        var Power: Float64 = 0.0
        var ConvPower: Float64 = 0.0
        var RadPower: Float64 = 0.0
        var TotEnergy: Float64 = 0.0
        var Energy: Float64 = 0.0
        var ConvEnergy: Float64 = 0.0
        var RadEnergy: Float64 = 0.0
        var FracDistribToSurf: List[Float64]
        var HeatingCapMethod: Int = 0           # - Method for electric baseboard heating capacity scalable sizing calculation
        var ScaledHeatingCapacity: Float64 = 0.0 # - scaled maximum heating capacity {W} or scalable variable for sizing in {-}, or {W/m2}
        var MySizeFlag: Bool = True
        var MyEnvrnFlag: Bool = True
        var CheckEquipName: Bool = True
        var ZeroBBSourceSumHATsurf: Float64 = 0.0 # used in baseboard energy balance
        # Record keeping variables used to calculate QBBRadSrcAvg locally
        var QBBElecRadSource: Float64 = 0.0   # Need to keep the last value in case we are still iterating
        var QBBElecRadSrcAvg: Float64 = 0.0   # Need to keep the last value in case we are still iterating
        var LastSysTimeElapsed: Float64 = 0.0 # Need to keep the last value in case we are still iterating
        var LastTimeStepSys: Float64 = 0.0    # Need to keep the last value in case we are still iterating
        var LastQBBElecRadSrc: Float64 = 0.0  # Need to keep the last value in case we are still iterating

    struct ElecBaseboardNumericFieldData:
        # Members
        var FieldNames: List[String]

        # Default Constructor
        def __init__(inout self):

    def SimElecBaseboard(
        inout state: EnergyPlusData, EquipName: String, ZoneNum: Int, FirstHVACIteration: Bool, inout PowerMet: Float64, inout CompIndex: Int):

        # Using/Aliasing
        # Locals
        var BaseboardNum: Int
        var NumElecBaseboards: Int = state.dataElectBaseboardRad.NumElecBaseboards

        if state.dataElectBaseboardRad.GetInputFlag:
            GetElectricBaseboardInput(state)
            state.dataElectBaseboardRad.GetInputFlag = False

        # Get unit index
        if CompIndex == 0:
            BaseboardNum = Util.FindItemInList(EquipName, state.dataElectBaseboardRad.ElecBaseboard, ElecBaseboardParams.EquipName)
            if BaseboardNum == 0:
                ShowFatalError(state, "SimElectricBaseboard: Unit not found=" + EquipName)
            CompIndex = BaseboardNum
        else:
            BaseboardNum = CompIndex
            if BaseboardNum > NumElecBaseboards or BaseboardNum < 1:
                ShowFatalError(state,
                               String.format("SimElectricBaseboard:  Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}",
                                           BaseboardNum,
                                           NumElecBaseboards,
                                           EquipName))
            if state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].CheckEquipName:
                if EquipName != state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].EquipName:
                    ShowFatalError(state,
                                   String.format("SimElectricBaseboard: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}",
                                               BaseboardNum,
                                               EquipName,
                                               state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].EquipName))
                state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].CheckEquipName = False

        InitElectricBaseboard(state, BaseboardNum, ControlledZoneNum, FirstHVACIteration)
        CalcElectricBaseboard(state, BaseboardNum, ControlledZoneNum)

        PowerMet = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].TotPower

        UpdateElectricBaseboard(state, BaseboardNum)
        ReportElectricBaseboard(state, BaseboardNum)

    def GetElectricBaseboardInput(inout state: EnergyPlusData):

        # Using/Aliasing
        # Locals
        static var RoutineName: String = "GetElectricBaseboardInput: "
        static var routineName: String = "GetElectricBaseboardInput"

        var MaxFraction: Float64 = 1.0
        var MinFraction: Float64 = 0.0
        var MinDistribSurfaces: Int = 1
        var iHeatDesignCapacityNumericNum: Int = 1
        var iHeatCapacityPerFloorAreaNumericNum: Int = 2
        var iHeatFracOfAutosizedCapacityNumericNum: Int = 3

        var ErrorsFound: Bool = False

        var cCurrentModuleObject: String = state.dataElectBaseboardRad.cCMO_BBRadiator_Electric

        var NumElecBaseboards: Int = state.dataElectBaseboardRad.NumElecBaseboards = \
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)

        var ElecBaseboardNumericFields = state.dataElectBaseboardRad.ElecBaseboardNumericFields

        state.dataElectBaseboardRad.ElecBaseboard = List[ElecBaseboardParams](repeating=ElecBaseboardParams(), count=NumElecBaseboards)
        ElecBaseboardNumericFields = List[ElecBaseboardNumericFieldData](repeating=ElecBaseboardNumericFieldData(), count=NumElecBaseboards)
        var inputProcessor = state.dataInputProcessing.inputProcessor
        var elecBaseboardSchemaProps = inputProcessor.getObjectSchemaProps(state, cCurrentModuleObject)
        var elecBaseboardObjects = inputProcessor.epJSON.find(cCurrentModuleObject)
        static var numericFieldNames: List[String] = ["Heating Design Capacity",
                                                      "Heating Design Capacity Per Floor Area",
                                                      "Fraction of Autosized Heating Design Capacity",
                                                      "Efficiency",
                                                      "Fraction Radiant",
                                                      "Fraction of Radiant Energy Incident on People"]
        static var availabilityScheduleFieldName: String = "Availability Schedule Name"
        static var heatingDesignCapacityMethodFieldName: String = "Heating Design Capacity Method"
        static var radiantSurfaceFractionFieldName: String = "Fraction of Radiant Energy to Surface"
        var surfaceFractionSchemaProps = elecBaseboardSchemaProps["surface_fractions"]["items"]["properties"]

        if elecBaseboardObjects != inputProcessor.epJSON.end():
            var BaseboardNum: Int = 0
            for elecBaseboardInstance in elecBaseboardObjects.value().items():
                var elecBaseboardFields = elecBaseboardInstance.value()
                var elecBaseboardName = Util.makeUPPER(elecBaseboardInstance.key())
                var availabilityScheduleName = \
                    inputProcessor.getAlphaFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "availability_schedule_name")
                var heatingDesignCapacityMethod = \
                    inputProcessor.getAlphaFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity_method")
                var surfaceFractionsField = elecBaseboardFields.find("surface_fractions")

                inputProcessor.markObjectAsUsed(cCurrentModuleObject, elecBaseboardInstance.key())

                BaseboardNum += 1
                var elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

                var numSurfaceFractions: Int = 0
                if surfaceFractionsField != elecBaseboardFields.end():
                    numSurfaceFractions = surfaceFractionsField.size()

                var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, elecBaseboardName)

                ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames = List[String](repeating="", count=6 + numSurfaceFractions)
                for fieldNum in range(1, 7):
                    ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[fieldNum - 1] = numericFieldNames[fieldNum - 1]
                for fieldNum in range(1, numSurfaceFractions + 1):
                    ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[fieldNum + 5] = radiantSurfaceFractionFieldName

                GlobalNames.VerifyUniqueBaseboardName(state, cCurrentModuleObject, elecBaseboardName, ErrorsFound, cCurrentModuleObject + " Name")

                elecBaseboard.EquipName = elecBaseboardName
                elecBaseboard.Schedule = availabilityScheduleName
                if availabilityScheduleName == "":
                    elecBaseboard.availSched = Sched.GetScheduleAlwaysOn(state)
                elif (elecBaseboard.availSched = Sched.GetSchedule(state, availabilityScheduleName)) == None:
                    ShowSevereItemNotFound(state, eoh, availabilityScheduleFieldName, availabilityScheduleName)
                    ErrorsFound = True

                if Util.SameString(heatingDesignCapacityMethod, "HeatingDesignCapacity"):
                    elecBaseboard.HeatingCapMethod = DataSizing.HeatingDesignCapacity
                    var heatingDesignCapacityField = elecBaseboardFields.find("heating_design_capacity")
                    if heatingDesignCapacityField != elecBaseboardFields.end():
                        elecBaseboard.ScaledHeatingCapacity = \
                            inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity")
                        if elecBaseboard.ScaledHeatingCapacity < 0.0 and elecBaseboard.ScaledHeatingCapacity != DataSizing.AutoSize:
                            ShowSevereError(state, String.format("{} = {}", cCurrentModuleObject, elecBaseboard.EquipName))
                            ShowContinueError(state,
                                              String.format("Illegal {} = {:#G}",
                                                          numericFieldNames[iHeatDesignCapacityNumericNum - 1],
                                                          elecBaseboard.ScaledHeatingCapacity))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, String.format("{} = {}", cCurrentModuleObject, elecBaseboard.EquipName))
                        ShowContinueError(state, String.format("Input for {} = {}", heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                        ShowContinueError(state, String.format("Blank field not allowed for {}", numericFieldNames[iHeatDesignCapacityNumericNum - 1]))
                        ErrorsFound = True
                elif Util.SameString(heatingDesignCapacityMethod, "CapacityPerFloorArea"):
                    elecBaseboard.HeatingCapMethod = DataSizing.CapacityPerFloorArea
                    var heatingDesignCapacityPerFloorAreaField = elecBaseboardFields.find("heating_design_capacity_per_floor_area")
                    if heatingDesignCapacityPerFloorAreaField != elecBaseboardFields.end():
                        elecBaseboard.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(
                            elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity_per_floor_area")
                        if elecBaseboard.ScaledHeatingCapacity <= 0.0:
                            ShowSevereError(state, String.format("{} = {}", cCurrentModuleObject, elecBaseboard.EquipName))
                            ShowContinueError(state,
                                              String.format("Input for {} = {}", heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                            ShowContinueError(state,
                                              String.format("Illegal {} = {:#G}",
                                                          numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1],
                                                          elecBaseboard.ScaledHeatingCapacity))
                            ErrorsFound = True
                        elif elecBaseboard.ScaledHeatingCapacity == DataSizing.AutoSize:
                            ShowSevereError(state, String.format("{} = {}", cCurrentModuleObject, elecBaseboard.EquipName))
                            ShowContinueError(state,
                                              String.format("Input for {} = {}", heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                            ShowContinueError(state,
                                              String.format("Illegal {} = Autosize", numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, String.format("{} = {}", cCurrentModuleObject, elecBaseboard.EquipName))
                        ShowContinueError(state, String.format("Input for {} = {}", heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                        ShowContinueError(state,
                                          String.format("Blank field not allowed for {}", numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]))
                        ErrorsFound = True
                elif Util.SameString(heatingDesignCapacityMethod, "FractionOfAutosizedHeatingCapacity"):
                    elecBaseboard.HeatingCapMethod = DataSizing.FractionOfAutosizedHeatingCapacity
                    var fractionOfAutosizedCapacityField = elecBaseboardFields.find("fraction_of_autosized_heating_design_capacity")
                    if fractionOfAutosizedCapacityField != elecBaseboardFields.end():
                        elecBaseboard.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(
                            elecBaseboardFields, elecBaseboardSchemaProps, "fraction_of_autosized_heating_design_capacity")
                        if elecBaseboard.ScaledHeatingCapacity < 0.0:
                            ShowSevereError(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                            ShowContinueError(state,
                                              String.format("Illegal {} = {:#G}",
                                                          numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1],
                                                          elecBaseboard.ScaledHeatingCapacity))
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                        ShowContinueError(state, String.format("Input for {} = {}", heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                        ShowContinueError(
                            state, String.format("Blank field not allowed for {}", numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1]))
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                    ShowContinueError(state, String.format("Illegal {} = {}", heatingDesignCapacityMethodFieldName, heatingDesignCapacityMethod))
                    ErrorsFound = True

                elecBaseboard.BaseboardEfficiency = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "efficiency")
                elecBaseboard.FracRadiant = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "fraction_radiant")
                if elecBaseboard.FracRadiant < MinFraction:
                    ShowWarningError(state,
                                     String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " +
                                         String(numericFieldNames[4]) + " was lower than the allowable minimum.")
                    ShowContinueError(state, String.format("...reset to minimum value=[{:.2f}].", MinFraction))
                    elecBaseboard.FracRadiant = MinFraction
                if elecBaseboard.FracRadiant > MaxFraction:
                    ShowWarningError(state,
                                     String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " +
                                         String(numericFieldNames[4]) + " was higher than the allowable maximum.")
                    ShowContinueError(state, String.format("...reset to maximum value=[{:.2f}].", MaxFraction))
                    elecBaseboard.FracRadiant = MaxFraction

                # Calculate convective fraction
                if elecBaseboard.FracRadiant > MaxFraction:
                    ShowWarningError(state,
                                     String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName +
                                         "\", Fraction Radiant was higher than the allowable maximum.")
                    elecBaseboard.FracRadiant = MaxFraction
                    elecBaseboard.FracConvect = 0.0
                else:
                    elecBaseboard.FracConvect = 1.0 - elecBaseboard.FracRadiant

                elecBaseboard.FracDistribPerson = \
                    inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "fraction_of_radiant_energy_incident_on_people")
                if elecBaseboard.FracDistribPerson < MinFraction:
                    ShowWarningError(state,
                                     String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " +
                                         String(numericFieldNames[5]) + " was lower than the allowable minimum.")
                    ShowContinueError(state, String.format("...reset to minimum value=[{:.2f}].", MinFraction))
                    elecBaseboard.FracDistribPerson = MinFraction
                if elecBaseboard.FracDistribPerson > MaxFraction:
                    ShowWarningError(state,
                                     String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " +
                                         String(numericFieldNames[5]) + " was higher than the allowable maximum.")
                    ShowContinueError(state, String.format("...reset to maximum value=[{:.2f}].", MaxFraction))
                    elecBaseboard.FracDistribPerson = MaxFraction

                elecBaseboard.TotSurfToDistrib = numSurfaceFractions

                if (elecBaseboard.TotSurfToDistrib < MinDistribSurfaces) and (elecBaseboard.FracRadiant > MinFraction):
                    ShowSevereError(state,
                                    String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName +
                                        "\", the number of surface/radiant fraction groups entered was less than the allowable minimum.")
                    ShowContinueError(state, String.format("...the minimum that must be entered=[{}].", MinDistribSurfaces))
                    ErrorsFound = True
                    elecBaseboard.TotSurfToDistrib = 0

                elecBaseboard.SurfaceName = List[String](repeating="", count=elecBaseboard.TotSurfToDistrib)
                elecBaseboard.SurfacePtr = List[Int](repeating=0, count=elecBaseboard.TotSurfToDistrib)
                elecBaseboard.FracDistribToSurf = List[Float64](repeating=0.0, count=elecBaseboard.TotSurfToDistrib)

                elecBaseboard.ZonePtr = DataZoneEquipment.GetZoneEquipControlledZoneNum(
                    state, DataZoneEquipment.ZoneEquipType.BaseboardElectric, elecBaseboard.EquipName)

                var AllFracsSummed: Float64 = elecBaseboard.FracDistribPerson
                for SurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
                    var surfaceFraction = (*surfaceFractionsField)[SurfNum - 1]
                    elecBaseboard.SurfaceName[SurfNum - 1] = \
                        inputProcessor.getAlphaFieldValue(surfaceFraction, surfaceFractionSchemaProps, "surface_name")
                    elecBaseboard.SurfacePtr[SurfNum - 1] = HeatBalanceIntRadExchange.GetRadiantSystemSurface(
                        state, cCurrentModuleObject, elecBaseboard.EquipName, elecBaseboard.ZonePtr, elecBaseboard.SurfaceName[SurfNum - 1], ErrorsFound)
                    elecBaseboard.FracDistribToSurf[SurfNum - 1] = \
                        inputProcessor.getRealFieldValue(surfaceFraction, surfaceFractionSchemaProps, "fraction_of_radiant_energy_to_surface")
                    if elecBaseboard.FracDistribToSurf[SurfNum - 1] > MaxFraction:
                        ShowWarningError(state,
                                         String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " +
                                             String(radiantSurfaceFractionFieldName) + " was greater than the allowable maximum.")
                        ShowContinueError(state, String.format("...reset to maximum value=[{:.2f}].", MaxFraction))
                        elecBaseboard.FracDistribToSurf[SurfNum - 1] = MaxFraction
                    if elecBaseboard.FracDistribToSurf[SurfNum - 1] < MinFraction:
                        ShowWarningError(state,
                                         String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " +
                                             String(radiantSurfaceFractionFieldName) + " was less than the allowable minimum.")
                        ShowContinueError(state, String.format("...reset to minimum value=[{:.2f}].", MinFraction))
                        elecBaseboard.FracDistribToSurf[SurfNum - 1] = MinFraction
                    if elecBaseboard.SurfacePtr[SurfNum - 1] != 0:
                        state.dataSurface.surfIntConv[elecBaseboard.SurfacePtr[SurfNum - 1]].getsRadiantHeat = True
                        state.dataSurface.allGetsRadiantHeatSurfaceList.append(elecBaseboard.SurfacePtr[SurfNum - 1])

                    AllFracsSummed += elecBaseboard.FracDistribToSurf[SurfNum - 1]

                if AllFracsSummed > (MaxFraction + 0.01):
                    ShowSevereError(state,
                                    String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName +
                                        "\", Summed radiant fractions for people + surface groups > 1.0")
                    ErrorsFound = True
                if (AllFracsSummed < (MaxFraction - 0.01)) and \
                    (elecBaseboard.FracRadiant > MinFraction):
                    ShowWarningError(state,
                                     String(RoutineName) + cCurrentModuleObject + "=\"" + elecBaseboardName +
                                         "\", Summed radiant fractions for people + surface groups < 1.0")
                    ShowContinueError(state, "The rest of the radiant energy delivered by the baseboard heater will be lost")

        if ErrorsFound:
            ShowFatalError(state, String(RoutineName) + cCurrentModuleObject + "Errors found getting input. Program terminates.")

        for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
            # Setup output variables
            SetupOutputVariable(state,
                                "Baseboard Total Heating Rate",
                                Constant.Units.W,
                                elecBaseboard.TotPower,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                elecBaseboard.EquipName)

            SetupOutputVariable(state,
                                "Baseboard Convective Heating Rate",
                                Constant.Units.W,
                                elecBaseboard.ConvPower,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                elecBaseboard.EquipName)
            SetupOutputVariable(state,
                                "Baseboard Radiant Heating Rate",
                                Constant.Units.W,
                                elecBaseboard.RadPower,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                elecBaseboard.EquipName)

            SetupOutputVariable(state,
                                "Baseboard Electricity Energy",
                                Constant.Units.J,
                                elecBaseboard.ElecUseLoad,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                elecBaseboard.EquipName,
                                Constant.eResource.Electricity,
                                OutputProcessor.Group.HVAC,
                                OutputProcessor.EndUseCat.Heating)
            SetupOutputVariable(state,
                                "Baseboard Electricity Rate",
                                Constant.Units.W,
                                elecBaseboard.ElecUseRate,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                elecBaseboard.EquipName)
            SetupOutputVariable(state,
                                "Baseboard Total Heating Energy",
                                Constant.Units.J,
                                elecBaseboard.TotEnergy,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                elecBaseboard.EquipName,
                                Constant.eResource.EnergyTransfer,
                                OutputProcessor.Group.HVAC,
                                OutputProcessor.EndUseCat.Baseboard)

            SetupOutputVariable(state,
                                "Baseboard Convective Heating Energy",
                                Constant.Units.J,
                                elecBaseboard.ConvEnergy,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                elecBaseboard.EquipName)
            SetupOutputVariable(state,
                                "Baseboard Radiant Heating Energy",
                                Constant.Units.J,
                                elecBaseboard.RadEnergy,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                elecBaseboard.EquipName)

    def InitElectricBaseboard(inout state: EnergyPlusData, BaseboardNum: Int, ControlledZoneNum: Int, FirstHVACIteration: Bool):

        # Using/Aliasing
        # Locals

        var elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

        if not state.dataGlobal.SysSizingCalc and elecBaseboard.MySizeFlag:
            # Size the baseboard
            SizeElectricBaseboard(state, BaseboardNum)
            elecBaseboard.MySizeFlag = False

        # Check the environment flag
        if state.dataGlobal.BeginEnvrnFlag and elecBaseboard.MyEnvrnFlag:
            # Initialize environment variables
            elecBaseboard.ZeroBBSourceSumHATsurf = 0.0
            elecBaseboard.QBBElecRadSource = 0.0
            elecBaseboard.QBBElecRadSrcAvg = 0.0
            elecBaseboard.LastQBBElecRadSrc = 0.0
            elecBaseboard.LastSysTimeElapsed = 0.0
            elecBaseboard.LastTimeStepSys = 0.0

            elecBaseboard.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            elecBaseboard.MyEnvrnFlag = True

        if state.dataGlobal.BeginTimeStepFlag and FirstHVACIteration:
            elecBaseboard.ZeroBBSourceSumHATsurf = state.dataHeatBal.Zone[ControlledZoneNum - 1].sumHATsurf(state)
            elecBaseboard.QBBElecRadSrcAvg = 0.0
            elecBaseboard.LastQBBElecRadSrc = 0.0
            elecBaseboard.LastSysTimeElapsed = 0.0
            elecBaseboard.LastTimeStepSys = 0.0

        # Get the zone inlet conditions
        var ZoneNode: Int = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1].ZoneNode
        elecBaseboard.AirInletTemp = state.dataLoopNodes.Node[ZoneNode - 1].Temp
        elecBaseboard.AirInletHumRat = state.dataLoopNodes.Node[ZoneNode - 1].HumRat

        # Zero out the variables
        elecBaseboard.TotPower = 0.0
        elecBaseboard.Power = 0.0
        elecBaseboard.ConvPower = 0.0
        elecBaseboard.RadPower = 0.0
        elecBaseboard.TotEnergy = 0.0
        elecBaseboard.Energy = 0.0
        elecBaseboard.ConvEnergy = 0.0
        elecBaseboard.RadEnergy = 0.0
        elecBaseboard.ElecUseLoad = 0.0
        elecBaseboard.ElecUseRate = 0.0

    def SizeElectricBaseboard(inout state: EnergyPlusData, BaseboardNum: Int):

        # Using/Aliasing
        # Locals

        static var RoutineName: String = "SizeElectricBaseboard"

        var TempSize: Float64

        if state.dataSize.CurZoneEqNum > 0:
            var zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1]
            var elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]
            state.dataSize.DataScalableCapSizingON = False

            var CompType: String = state.dataElectBaseboardRad.cCMO_BBRadiator_Electric
            var CompName: String = elecBaseboard.EquipName
            state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
            state.dataSize.DataZoneNumber = elecBaseboard.ZonePtr
            var SizingMethod: Int = HVAC.HeatingCapacitySizing
            var FieldNum: Int = 1
            var SizingString: String = String.format("{} [W]", state.dataElectBaseboardRad.ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[FieldNum - 1])
            var CapSizingMethod: Int = elecBaseboard.HeatingCapMethod
            zoneEqSizing.SizingMethod[SizingMethod - 1] = CapSizingMethod
            if CapSizingMethod == DataSizing.HeatingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or \
                CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                var PrintFlag: Bool = True
                if CapSizingMethod == DataSizing.HeatingDesignCapacity:
                    if elecBaseboard.ScaledHeatingCapacity == DataSizing.AutoSize:
                        CheckZoneSizing(state, CompType, CompName)
                        zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad
                    else:
                        zoneEqSizing.DesHeatingLoad = elecBaseboard.ScaledHeatingCapacity
                    zoneEqSizing.HeatingCapacity = True
                    TempSize = elecBaseboard.ScaledHeatingCapacity
                elif CapSizingMethod == DataSizing.CapacityPerFloorArea:
                    if state.dataSize.ZoneSizingRunDone:
                        zoneEqSizing.HeatingCapacity = True
                        zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad
                    TempSize = elecBaseboard.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber - 1].FloorArea
                    state.dataSize.DataScalableCapSizingON = True
                elif CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
                    CheckZoneSizing(state, CompType, CompName)
                    zoneEqSizing.HeatingCapacity = True
                    state.dataSize.DataFracOfAutosizedHeatingCapacity = elecBaseboard.ScaledHeatingCapacity
                    zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad
                    var FracOfAutoSzCap: Float64 = DataSizing.AutoSize
                    var ErrorsFound: Bool = False
                    var sizerHeatingCapacity = HeatingCapacitySizer()
                    sizerHeatingCapacity.overrideSizingString(SizingString)
                    sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                    FracOfAutoSzCap = sizerHeatingCapacity.size(state, FracOfAutoSzCap, ErrorsFound)
                    TempSize = FracOfAutoSzCap
                    state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                    state.dataSize.DataScalableCapSizingON = True
                else:
                    TempSize = elecBaseboard.ScaledHeatingCapacity
                var errorsFound: Bool = False
                var sizerHeatingCapacity = HeatingCapacitySizer()
                sizerHeatingCapacity.overrideSizingString(SizingString)
                sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                elecBaseboard.NominalCapacity = sizerHeatingCapacity.size(state, TempSize, errorsFound)
                state.dataSize.DataScalableCapSizingON = False

    def CalcElectricBaseboard(inout state: EnergyPlusData, BaseboardNum: Int, ControlledZoneNum: Int):

        # Using/Aliasing
        # Locals

        var SimpConvAirFlowSpeed: Float64 = 0.5

        var QBBCap: Float64
        var RadHeat: Float64
        var LoadMet: Float64
        var elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

        var ZoneNum: Int = elecBaseboard.ZonePtr
        var QZnReq: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToHeatSP
        var AirInletTemp: Float64 = elecBaseboard.AirInletTemp
        var AirOutletTemp: Float64 = AirInletTemp
        var CpAir: Float64 = Psychrometrics.PsyCpAirFnW(elecBaseboard.AirInletHumRat)
        var AirMassFlowRate: Float64 = SimpConvAirFlowSpeed
        var CapacitanceAir: Float64 = CpAir * AirMassFlowRate

        var Effic: Float64 = elecBaseboard.BaseboardEfficiency

        if QZnReq > HVAC.SmallLoad and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum - 1] and \
            elecBaseboard.availSched.getCurrentVal() > 0.0:

            # Determine the baseboard capacity
            if QZnReq > elecBaseboard.NominalCapacity:
                QBBCap = elecBaseboard.NominalCapacity
            else:
                QBBCap = QZnReq
            RadHeat = QBBCap * elecBaseboard.FracRadiant
            elecBaseboard.QBBElecRadSource = RadHeat

            if elecBaseboard.FracRadiant > 0.0:
                # Distribute radiant gains
                DistributeBBElecRadGains(state)
                # Calculate heat balances
                HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
                HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
                # Calculate load met
                LoadMet = (state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state) - elecBaseboard.ZeroBBSourceSumHATsurf) + \
                          (QBBCap * elecBaseboard.FracConvect) + (RadHeat * elecBaseboard.FracDistribPerson)

                if LoadMet < 0.0:
                    # Recalculate with zero source
                    elecBaseboard.QBBElecRadSource = 0.0
                    DistributeBBElecRadGains(state)
                    HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
                    HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
                    var TempZeroBBSourceSumHATsurf: Float64 = state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state)
                    # Restore source
                    elecBaseboard.QBBElecRadSource = RadHeat
                    DistributeBBElecRadGains(state)
                    HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
                    HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
                    # Recalculate load
                    LoadMet = (state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state) - TempZeroBBSourceSumHATsurf) + \
                              (QBBCap * elecBaseboard.FracConvect) + (RadHeat * elecBaseboard.FracDistribPerson)
                    if LoadMet < 0.0:
                        # Turn off
                        UpdateElectricBaseboardOff(
                            LoadMet, QBBCap, RadHeat, elecBaseboard.QBBElecRadSource, elecBaseboard.ElecUseRate, AirOutletTemp, AirInletTemp)
                    else:
                        # Turn on
                        UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
                else:
                    # Turn on
                    UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)

            else:
                # No radiant fraction
                LoadMet = QBBCap
                UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)

        else:
            # Turn off
            UpdateElectricBaseboardOff(
                LoadMet, QBBCap, RadHeat, elecBaseboard.QBBElecRadSource, elecBaseboard.ElecUseRate, AirOutletTemp, AirInletTemp)

        # Set output variables
        elecBaseboard.AirOutletTemp = AirOutletTemp
        elecBaseboard.Power = QBBCap
        elecBaseboard.TotPower = LoadMet
        elecBaseboard.RadPower = RadHeat
        elecBaseboard.ConvPower = QBBCap - RadHeat

    def UpdateElectricBaseboardOff(inout LoadMet: Float64,
                                  inout QBBCap: Float64,
                                  inout RadHeat: Float64,
                                  inout QBBElecRadSrc: Float64,
                                  inout ElecUseRate: Float64,
                                  inout AirOutletTemp: Float64,
                                  AirInletTemp: Float64):

        # Using/Aliasing
        # Locals

        QBBCap = 0.0
        LoadMet = 0.0
        RadHeat = 0.0
        AirOutletTemp = AirInletTemp
        QBBElecRadSrc = 0.0
        ElecUseRate = 0.0

    def UpdateElectricBaseboardOn(inout AirOutletTemp: Float64,
                                 inout ElecUseRate: Float64,
                                 AirInletTemp: Float64,
                                 QBBCap: Float64,
                                 CapacitanceAir: Float64,
                                 Effic: Float64):

        # Using/Aliasing
        # Locals

        AirOutletTemp = AirInletTemp + QBBCap / CapacitanceAir
        # Calculate electric use rate
        ElecUseRate = QBBCap / Effic

    def UpdateElectricBaseboard(inout state: EnergyPlusData, BaseboardNum: Int):

        # Using/Aliasing
        # Locals

        var SysTimeElapsed: Float64 = state.dataHVACGlobal.SysTimeElapsed
        var TimeStepSys: Float64 = state.dataHVACGlobal.TimeStepSys
        var elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

        # Update the average radiant source
        if elecBaseboard.LastSysTimeElapsed == SysTimeElapsed:
            elecBaseboard.QBBElecRadSrcAvg -= elecBaseboard.LastQBBElecRadSrc * elecBaseboard.LastTimeStepSys / state.dataGlobal.TimeStepZone
        # Add current contribution
        elecBaseboard.QBBElecRadSrcAvg += elecBaseboard.QBBElecRadSource * TimeStepSys / state.dataGlobal.TimeStepZone

        elecBaseboard.LastQBBElecRadSrc = elecBaseboard.QBBElecRadSource
        elecBaseboard.LastSysTimeElapsed = SysTimeElapsed
        elecBaseboard.LastTimeStepSys = TimeStepSys

    def UpdateBBElecRadSourceValAvg(inout state: EnergyPlusData, inout ElecBaseboardSysOn: Bool):

        # Using/Aliasing
        # Locals

        ElecBaseboardSysOn = False

        # If no baseboards, return
        if state.dataElectBaseboardRad.NumElecBaseboards == 0:
            return

        # Loop through all baseboards
        for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
            elecBaseboard.QBBElecRadSource = elecBaseboard.QBBElecRadSrcAvg
            if elecBaseboard.QBBElecRadSrcAvg != 0.0:
                ElecBaseboardSysOn = True

        # Distribute gains
        DistributeBBElecRadGains(state)

    def DistributeBBElecRadGains(inout state: EnergyPlusData):

        # Using/Aliasing
        # Locals

        var SmallestArea: Float64 = 0.001

        # Initialize all surfaces to zero
        for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
            for radSurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
                var surfNum: Int = elecBaseboard.SurfacePtr[radSurfNum - 1]
                state.dataHeatBalFanSys.surfQRadFromHVAC[surfNum - 1].ElecBaseboard = 0.0
        state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson = List[Float64](repeating=0.0, count=len(state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson))

        for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
            if elecBaseboard.ZonePtr > 0:
                var ZoneNum: Int = elecBaseboard.ZonePtr
                state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson[ZoneNum - 1] += elecBaseboard.QBBElecRadSource * elecBaseboard.FracDistribPerson

                for RadSurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
                    var SurfNum: Int = elecBaseboard.SurfacePtr[RadSurfNum - 1]
                    if state.dataSurface.Surface[SurfNum - 1].Area > SmallestArea:
                        var ThisSurfIntensity: Float64 = \
                            (elecBaseboard.QBBElecRadSource * elecBaseboard.FracDistribToSurf[RadSurfNum - 1] / state.dataSurface.Surface[SurfNum - 1].Area)
                        state.dataHeatBalFanSys.surfQRadFromHVAC[SurfNum - 1].ElecBaseboard += ThisSurfIntensity
                        if ThisSurfIntensity > DataHeatBalFanSys.MaxRadHeatFlux:
                            ShowSevereError(state, "DistributeBBElecRadGains:  excessive thermal radiation heat flux intensity detected")
                            ShowContinueError(state, "Surface = " + state.dataSurface.Surface[SurfNum - 1].Name)
                            ShowContinueError(state, String.format("Surface area = {:#G} [m2]", state.dataSurface.Surface[SurfNum - 1].Area))
                            ShowContinueError(state,
                                              "Occurs in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric + " = " + elecBaseboard.EquipName)
                            ShowContinueError(state, String.format("Radiation intensity = {:#G} [W/m2]", ThisSurfIntensity))
                            ShowContinueError(
                                state, "Assign a larger surface area or more surfaces in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric)
                            ShowFatalError(state, "DistributeBBElecRadGains:  excessive thermal radiation heat flux intensity detected")
                    else:
                        ShowSevereError(state, "DistributeBBElecRadGains:  surface not large enough to receive thermal radiation heat flux")
                        ShowContinueError(state, "Surface = " + state.dataSurface.Surface[SurfNum - 1].Name)
                        ShowContinueError(state, String.format("Surface area = {:#G} [m2]", state.dataSurface.Surface[SurfNum - 1].Area))
                        ShowContinueError(state,
                                          "Occurs in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric + " = " + elecBaseboard.EquipName)
                        ShowContinueError(
                            state, "Assign a larger surface area or more surfaces in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric)
                        ShowFatalError(state, "DistributeBBElecRadGains:  surface not large enough to receive thermal radiation heat flux")

    def ReportElectricBaseboard(inout state: EnergyPlusData, BaseboardNum: Int):

        # Using/Aliasing
        # Locals

        var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
        var elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]
        elecBaseboard.ElecUseLoad = elecBaseboard.ElecUseRate * TimeStepSysSec
        elecBaseboard.TotEnergy = elecBaseboard.TotPower * TimeStepSysSec
        elecBaseboard.Energy = elecBaseboard.Power * TimeStepSysSec
        elecBaseboard.ConvEnergy = elecBaseboard.ConvPower * TimeStepSysSec
        elecBaseboard.RadEnergy = elecBaseboard.RadPower * TimeStepSysSec

struct ElectricBaseboardRadiatorData(BaseGlobalStruct):
    var cCMO_BBRadiator_Electric: String = "ZoneHVAC:Baseboard:RadiantConvective:Electric"

    # Object Data
    var NumElecBaseboards: Int = 0
    var ElecBaseboard: List[ElectricBaseboardRadiator.ElecBaseboardParams]
    var ElecBaseboardNumericFields: List[ElectricBaseboardRadiator.ElecBaseboardNumericFieldData]
    var GetInputFlag: Bool = True # One time get input flag

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumElecBaseboards = 0
        self.GetInputFlag = True
        self.ElecBaseboard = List[ElectricBaseboardRadiator.ElecBaseboardParams]()
        self.ElecBaseboardNumericFields = List[ElectricBaseboardRadiator.ElecBaseboardNumericFieldData]()
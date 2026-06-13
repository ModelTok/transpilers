from dataclasses import dataclass, field
from typing import List, Optional, Protocol

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - state parameter object
# - state.dataElectBaseboardRad: ElectricBaseboardRadiatorData
# - state.dataInputProcessing.inputProcessor: input processor
# - state.dataGlobal: global flags and timestep data
# - state.dataZoneEquipment: zone equipment functions
# - state.dataHeatBal: zone heat balance data
# - state.dataLoopNodes: loop node data
# - state.dataZoneEnergyDemand: zone energy demand
# - state.dataHVACGlobal: HVAC global data
# - state.dataSurface: surface data
# - state.dataHeatBalFanSys: heat balance fan system
# - state.dataSize: sizing data
# Util.FindItemInList, Util.SameString, Util.makeUPPER
# Sched.GetScheduleAlwaysOn, Sched.GetSchedule, Sched.Schedule
# ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowSevereItemNotFound
# Psychrometrics.PsyCpAirFnW
# HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf, CalcHeatBalanceInsideSurf
# HeatBalanceIntRadExchange.GetRadiantSystemSurface
# GlobalNames.VerifyUniqueBaseboardName
# OutputProcessor.SetupOutputVariable, OutputProcessor.TimeStepType, OutputProcessor.StoreType, OutputProcessor.Group, OutputProcessor.EndUseCat
# DataSizing: HeatingDesignCapacity, CapacityPerFloorArea, FractionOfAutosizedHeatingCapacity, AutoSize
# HVAC.SmallLoad, HVAC.HeatingCapacitySizing
# HeatingCapacitySizer
# DataHeatBalFanSys.MaxRadHeatFlux
# Constant: Units, eResource, etc.


@dataclass
class ElecBaseboardParams:
    EquipName: str = ""
    EquipType: int = 0
    Schedule: str = ""
    SurfaceName: List[str] = field(default_factory=list)
    SurfacePtr: List[int] = field(default_factory=list)
    ZonePtr: int = 0
    availSched: Optional[object] = None
    TotSurfToDistrib: int = 0
    NominalCapacity: float = 0.0
    BaseboardEfficiency: float = 0.0
    AirInletTemp: float = 0.0
    AirInletHumRat: float = 0.0
    AirOutletTemp: float = 0.0
    ElecUseLoad: float = 0.0
    ElecUseRate: float = 0.0
    FracRadiant: float = 0.0
    FracConvect: float = 0.0
    FracDistribPerson: float = 0.0
    TotPower: float = 0.0
    Power: float = 0.0
    ConvPower: float = 0.0
    RadPower: float = 0.0
    TotEnergy: float = 0.0
    Energy: float = 0.0
    ConvEnergy: float = 0.0
    RadEnergy: float = 0.0
    FracDistribToSurf: List[float] = field(default_factory=list)
    HeatingCapMethod: int = 0
    ScaledHeatingCapacity: float = 0.0
    MySizeFlag: bool = True
    MyEnvrnFlag: bool = True
    CheckEquipName: bool = True
    ZeroBBSourceSumHATsurf: float = 0.0
    QBBElecRadSource: float = 0.0
    QBBElecRadSrcAvg: float = 0.0
    LastSysTimeElapsed: float = 0.0
    LastTimeStepSys: float = 0.0
    LastQBBElecRadSrc: float = 0.0


@dataclass
class ElecBaseboardNumericFieldData:
    FieldNames: List[str] = field(default_factory=list)


def SimElecBaseboard(state, EquipName: str, ControlledZoneNum: int, FirstHVACIteration: bool, PowerMet: dict, CompIndex: dict):
    NumElecBaseboards = state.dataElectBaseboardRad.NumElecBaseboards

    if state.dataElectBaseboardRad.GetInputFlag:
        GetElectricBaseboardInput(state)
        state.dataElectBaseboardRad.GetInputFlag = False

    if CompIndex["value"] == 0:
        BaseboardNum = Util.FindItemInList(EquipName, state.dataElectBaseboardRad.ElecBaseboard, "EquipName")
        if BaseboardNum == 0:
            ShowFatalError(state, "SimElectricBaseboard: Unit not found=" + EquipName)
        CompIndex["value"] = BaseboardNum
    else:
        BaseboardNum = CompIndex["value"]
        if BaseboardNum > NumElecBaseboards or BaseboardNum < 1:
            ShowFatalError(state, f"SimElectricBaseboard:  Invalid CompIndex passed={BaseboardNum}, Number of Units={NumElecBaseboards}, Entered Unit name={EquipName}")
        if state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].CheckEquipName:
            if EquipName != state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].EquipName:
                ShowFatalError(state, f"SimElectricBaseboard: Invalid CompIndex passed={BaseboardNum}, Unit name={EquipName}, stored Unit Name for that index={state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].EquipName}")
            state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].CheckEquipName = False

    InitElectricBaseboard(state, BaseboardNum, ControlledZoneNum, FirstHVACIteration)
    CalcElectricBaseboard(state, BaseboardNum, ControlledZoneNum)

    PowerMet["value"] = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].TotPower

    UpdateElectricBaseboard(state, BaseboardNum)
    ReportElectricBaseboard(state, BaseboardNum)


def GetElectricBaseboardInput(state):
    RoutineName = "GetElectricBaseboardInput: "
    routineName = "GetElectricBaseboardInput"
    MaxFraction = 1.0
    MinFraction = 0.0
    MinDistribSurfaces = 1
    iHeatDesignCapacityNumericNum = 1
    iHeatCapacityPerFloorAreaNumericNum = 2
    iHeatFracOfAutosizedCapacityNumericNum = 3

    ErrorsFound = False
    cCurrentModuleObject = state.dataElectBaseboardRad.cCMO_BBRadiator_Electric

    NumElecBaseboards = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataElectBaseboardRad.NumElecBaseboards = NumElecBaseboards

    ElecBaseboardNumericFields = [ElecBaseboardNumericFieldData() for _ in range(NumElecBaseboards)]
    state.dataElectBaseboardRad.ElecBaseboard = [ElecBaseboardParams() for _ in range(NumElecBaseboards)]
    state.dataElectBaseboardRad.ElecBaseboardNumericFields = ElecBaseboardNumericFields

    inputProcessor = state.dataInputProcessing.inputProcessor
    elecBaseboardSchemaProps = inputProcessor.getObjectSchemaProps(state, cCurrentModuleObject)
    elecBaseboardObjects = inputProcessor.epJSON.get(cCurrentModuleObject)

    numericFieldNames = ["Heating Design Capacity", "Heating Design Capacity Per Floor Area", "Fraction of Autosized Heating Design Capacity",
                         "Efficiency", "Fraction Radiant", "Fraction of Radiant Energy Incident on People"]
    availabilityScheduleFieldName = "Availability Schedule Name"
    heatingDesignCapacityMethodFieldName = "Heating Design Capacity Method"
    radiantSurfaceFractionFieldName = "Fraction of Radiant Energy to Surface"

    if elecBaseboardObjects is not None:
        BaseboardNum = 0
        for elecBaseboardInstance_key, elecBaseboardFields in elecBaseboardObjects.items():
            elecBaseboardName = Util.makeUPPER(elecBaseboardInstance_key)
            availabilityScheduleName = inputProcessor.getAlphaFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "availability_schedule_name")
            heatingDesignCapacityMethod = inputProcessor.getAlphaFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity_method")
            surfaceFractionsField = elecBaseboardFields.get("surface_fractions")

            inputProcessor.markObjectAsUsed(cCurrentModuleObject, elecBaseboardInstance_key)

            BaseboardNum += 1
            elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

            numSurfaceFractions = 0
            if surfaceFractionsField is not None:
                numSurfaceFractions = len(surfaceFractionsField)

            eoh_routineName = routineName
            eoh_cCurrentModuleObject = cCurrentModuleObject
            eoh_elecBaseboardName = elecBaseboardName

            ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames = [""] * (6 + numSurfaceFractions)
            for fieldNum in range(1, 7):
                ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[fieldNum - 1] = numericFieldNames[fieldNum - 1]
            for fieldNum in range(1, numSurfaceFractions + 1):
                ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[fieldNum + 5] = radiantSurfaceFractionFieldName

            GlobalNames.VerifyUniqueBaseboardName(state, cCurrentModuleObject, elecBaseboardName, ErrorsFound, cCurrentModuleObject + " Name")

            elecBaseboard.EquipName = elecBaseboardName
            elecBaseboard.Schedule = availabilityScheduleName
            if not availabilityScheduleName:
                elecBaseboard.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                elecBaseboard.availSched = Sched.GetSchedule(state, availabilityScheduleName)
                if elecBaseboard.availSched is None:
                    ShowSevereItemNotFound(state, eoh_routineName, eoh_cCurrentModuleObject, eoh_elecBaseboardName, availabilityScheduleFieldName, availabilityScheduleName)
                    ErrorsFound = True

            if Util.SameString(heatingDesignCapacityMethod, "HeatingDesignCapacity"):
                elecBaseboard.HeatingCapMethod = DataSizing.HeatingDesignCapacity
                heatingDesignCapacityField = elecBaseboardFields.get("heating_design_capacity")
                if heatingDesignCapacityField is not None:
                    elecBaseboard.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity")
                    if elecBaseboard.ScaledHeatingCapacity < 0.0 and elecBaseboard.ScaledHeatingCapacity != DataSizing.AutoSize:
                        ShowSevereError(state, f"{cCurrentModuleObject} = {elecBaseboard.EquipName}")
                        ShowContinueError(state, f"Illegal {numericFieldNames[iHeatDesignCapacityNumericNum - 1]} = {elecBaseboard.ScaledHeatingCapacity:.G}")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, f"{cCurrentModuleObject} = {elecBaseboard.EquipName}")
                    ShowContinueError(state, f"Input for {heatingDesignCapacityMethodFieldName} = {heatingDesignCapacityMethod}")
                    ShowContinueError(state, f"Blank field not allowed for {numericFieldNames[iHeatDesignCapacityNumericNum - 1]}")
                    ErrorsFound = True
            elif Util.SameString(heatingDesignCapacityMethod, "CapacityPerFloorArea"):
                elecBaseboard.HeatingCapMethod = DataSizing.CapacityPerFloorArea
                heatingDesignCapacityPerFloorAreaField = elecBaseboardFields.get("heating_design_capacity_per_floor_area")
                if heatingDesignCapacityPerFloorAreaField is not None:
                    elecBaseboard.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity_per_floor_area")
                    if elecBaseboard.ScaledHeatingCapacity <= 0.0:
                        ShowSevereError(state, f"{cCurrentModuleObject} = {elecBaseboard.EquipName}")
                        ShowContinueError(state, f"Input for {heatingDesignCapacityMethodFieldName} = {heatingDesignCapacityMethod}")
                        ShowContinueError(state, f"Illegal {numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]} = {elecBaseboard.ScaledHeatingCapacity:.G}")
                        ErrorsFound = True
                    elif elecBaseboard.ScaledHeatingCapacity == DataSizing.AutoSize:
                        ShowSevereError(state, f"{cCurrentModuleObject} = {elecBaseboard.EquipName}")
                        ShowContinueError(state, f"Input for {heatingDesignCapacityMethodFieldName} = {heatingDesignCapacityMethod}")
                        ShowContinueError(state, f"Illegal {numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]} = Autosize")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, f"{cCurrentModuleObject} = {elecBaseboard.EquipName}")
                    ShowContinueError(state, f"Input for {heatingDesignCapacityMethodFieldName} = {heatingDesignCapacityMethod}")
                    ShowContinueError(state, f"Blank field not allowed for {numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1]}")
                    ErrorsFound = True
            elif Util.SameString(heatingDesignCapacityMethod, "FractionOfAutosizedHeatingCapacity"):
                elecBaseboard.HeatingCapMethod = DataSizing.FractionOfAutosizedHeatingCapacity
                fractionOfAutosizedCapacityField = elecBaseboardFields.get("fraction_of_autosized_heating_design_capacity")
                if fractionOfAutosizedCapacityField is not None:
                    elecBaseboard.ScaledHeatingCapacity = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "fraction_of_autosized_heating_design_capacity")
                    if elecBaseboard.ScaledHeatingCapacity < 0.0:
                        ShowSevereError(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                        ShowContinueError(state, f"Illegal {numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1]} = {elecBaseboard.ScaledHeatingCapacity:.G}")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                    ShowContinueError(state, f"Input for {heatingDesignCapacityMethodFieldName} = {heatingDesignCapacityMethod}")
                    ShowContinueError(state, f"Blank field not allowed for {numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1]}")
                    ErrorsFound = True
            else:
                ShowSevereError(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                ShowContinueError(state, f"Illegal {heatingDesignCapacityMethodFieldName} = {heatingDesignCapacityMethod}")
                ErrorsFound = True

            elecBaseboard.BaseboardEfficiency = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "efficiency")
            elecBaseboard.FracRadiant = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "fraction_radiant")
            if elecBaseboard.FracRadiant < MinFraction:
                ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[4] + " was lower than the allowable minimum.")
                ShowContinueError(state, f"...reset to minimum value=[{MinFraction:.2f}].")
                elecBaseboard.FracRadiant = MinFraction
            if elecBaseboard.FracRadiant > MaxFraction:
                ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[4] + " was higher than the allowable maximum.")
                ShowContinueError(state, f"...reset to maximum value=[{MaxFraction:.2f}].")
                elecBaseboard.FracRadiant = MaxFraction

            if elecBaseboard.FracRadiant > MaxFraction:
                ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", Fraction Radiant was higher than the allowable maximum.")
                elecBaseboard.FracRadiant = MaxFraction
                elecBaseboard.FracConvect = 0.0
            else:
                elecBaseboard.FracConvect = 1.0 - elecBaseboard.FracRadiant

            elecBaseboard.FracDistribPerson = inputProcessor.getRealFieldValue(elecBaseboardFields, elecBaseboardSchemaProps, "fraction_of_radiant_energy_incident_on_people")
            if elecBaseboard.FracDistribPerson < MinFraction:
                ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[5] + " was lower than the allowable minimum.")
                ShowContinueError(state, f"...reset to minimum value=[{MinFraction:.2f}].")
                elecBaseboard.FracDistribPerson = MinFraction
            if elecBaseboard.FracDistribPerson > MaxFraction:
                ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[5] + " was higher than the allowable maximum.")
                ShowContinueError(state, f"...reset to maximum value=[{MaxFraction:.2f}].")
                elecBaseboard.FracDistribPerson = MaxFraction

            elecBaseboard.TotSurfToDistrib = numSurfaceFractions

            if (elecBaseboard.TotSurfToDistrib < MinDistribSurfaces) and (elecBaseboard.FracRadiant > MinFraction):
                ShowSevereError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", the number of surface/radiant fraction groups entered was less than the allowable minimum.")
                ShowContinueError(state, f"...the minimum that must be entered=[{MinDistribSurfaces}].")
                ErrorsFound = True
                elecBaseboard.TotSurfToDistrib = 0

            elecBaseboard.SurfaceName = [""] * elecBaseboard.TotSurfToDistrib
            elecBaseboard.SurfacePtr = [0] * elecBaseboard.TotSurfToDistrib
            elecBaseboard.FracDistribToSurf = [0.0] * elecBaseboard.TotSurfToDistrib

            elecBaseboard.ZonePtr = DataZoneEquipment.GetZoneEquipControlledZoneNum(
                state, DataZoneEquipment.ZoneEquipType.BaseboardElectric, elecBaseboard.EquipName)

            AllFracsSummed = elecBaseboard.FracDistribPerson
            if surfaceFractionsField is not None:
                for SurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
                    surfaceFraction = surfaceFractionsField[SurfNum - 1]
                    elecBaseboard.SurfaceName[SurfNum - 1] = inputProcessor.getAlphaFieldValue(surfaceFraction, elecBaseboardSchemaProps.get("surface_fractions", {}).get("items", {}).get("properties", {}), "surface_name")
                    elecBaseboard.SurfacePtr[SurfNum - 1] = HeatBalanceIntRadExchange.GetRadiantSystemSurface(
                        state, cCurrentModuleObject, elecBaseboard.EquipName, elecBaseboard.ZonePtr, elecBaseboard.SurfaceName[SurfNum - 1], ErrorsFound)
                    elecBaseboard.FracDistribToSurf[SurfNum - 1] = inputProcessor.getRealFieldValue(surfaceFraction, elecBaseboardSchemaProps.get("surface_fractions", {}).get("items", {}).get("properties", {}), "fraction_of_radiant_energy_to_surface")
                    if elecBaseboard.FracDistribToSurf[SurfNum - 1] > MaxFraction:
                        ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + radiantSurfaceFractionFieldName + " was greater than the allowable maximum.")
                        ShowContinueError(state, f"...reset to maximum value=[{MaxFraction:.2f}].")
                        elecBaseboard.FracDistribToSurf[SurfNum - 1] = MaxFraction
                    if elecBaseboard.FracDistribToSurf[SurfNum - 1] < MinFraction:
                        ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + radiantSurfaceFractionFieldName + " was less than the allowable minimum.")
                        ShowContinueError(state, f"...reset to minimum value=[{MinFraction:.2f}].")
                        elecBaseboard.FracDistribToSurf[SurfNum - 1] = MinFraction
                    if elecBaseboard.SurfacePtr[SurfNum - 1] != 0:
                        state.dataSurface.surfIntConv[elecBaseboard.SurfacePtr[SurfNum - 1]].getsRadiantHeat = True
                        state.dataSurface.allGetsRadiantHeatSurfaceList.append(elecBaseboard.SurfacePtr[SurfNum - 1])

                    AllFracsSummed += elecBaseboard.FracDistribToSurf[SurfNum - 1]

            if AllFracsSummed > (MaxFraction + 0.01):
                ShowSevereError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", Summed radiant fractions for people + surface groups > 1.0")
                ErrorsFound = True
            if (AllFracsSummed < (MaxFraction - 0.01)) and (elecBaseboard.FracRadiant > MinFraction):
                ShowWarningError(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", Summed radiant fractions for people + surface groups < 1.0")
                ShowContinueError(state, "The rest of the radiant energy delivered by the baseboard heater will be lost")

    if ErrorsFound:
        ShowFatalError(state, RoutineName + cCurrentModuleObject + "Errors found getting input. Program terminates.")

    for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
        SetupOutputVariable(state, "Baseboard Total Heating Rate", Constant.Units.W, elecBaseboard.TotPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, elecBaseboard.EquipName)
        SetupOutputVariable(state, "Baseboard Convective Heating Rate", Constant.Units.W, elecBaseboard.ConvPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, elecBaseboard.EquipName)
        SetupOutputVariable(state, "Baseboard Radiant Heating Rate", Constant.Units.W, elecBaseboard.RadPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, elecBaseboard.EquipName)
        SetupOutputVariable(state, "Baseboard Electricity Energy", Constant.Units.J, elecBaseboard.ElecUseLoad, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, elecBaseboard.EquipName, Constant.eResource.Electricity, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Heating)
        SetupOutputVariable(state, "Baseboard Electricity Rate", Constant.Units.W, elecBaseboard.ElecUseRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, elecBaseboard.EquipName)
        SetupOutputVariable(state, "Baseboard Total Heating Energy", Constant.Units.J, elecBaseboard.TotEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, elecBaseboard.EquipName, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Baseboard)
        SetupOutputVariable(state, "Baseboard Convective Heating Energy", Constant.Units.J, elecBaseboard.ConvEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, elecBaseboard.EquipName)
        SetupOutputVariable(state, "Baseboard Radiant Heating Energy", Constant.Units.J, elecBaseboard.RadEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, elecBaseboard.EquipName)


def InitElectricBaseboard(state, BaseboardNum: int, ControlledZoneNum: int, FirstHVACIteration: bool):
    elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

    if not state.dataGlobal.SysSizingCalc and elecBaseboard.MySizeFlag:
        SizeElectricBaseboard(state, BaseboardNum)
        elecBaseboard.MySizeFlag = False

    if state.dataGlobal.BeginEnvrnFlag and elecBaseboard.MyEnvrnFlag:
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
        elecBaseboard.ZeroBBSourceSumHATsurf = state.dataHeatBal.Zone[ControlledZoneNum].sumHATsurf(state)
        elecBaseboard.QBBElecRadSrcAvg = 0.0
        elecBaseboard.LastQBBElecRadSrc = 0.0
        elecBaseboard.LastSysTimeElapsed = 0.0
        elecBaseboard.LastTimeStepSys = 0.0

    ZoneNode = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].ZoneNode
    elecBaseboard.AirInletTemp = state.dataLoopNodes.Node[ZoneNode].Temp
    elecBaseboard.AirInletHumRat = state.dataLoopNodes.Node[ZoneNode].HumRat

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


def SizeElectricBaseboard(state, BaseboardNum: int):
    RoutineName = "SizeElectricBaseboard"
    TempSize = 0.0

    if state.dataSize.CurZoneEqNum > 0:
        zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1]
        elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]
        state.dataSize.DataScalableCapSizingON = False

        CompType = state.dataElectBaseboardRad.cCMO_BBRadiator_Electric
        CompName = elecBaseboard.EquipName
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = elecBaseboard.ZonePtr
        SizingMethod = HVAC.HeatingCapacitySizing
        FieldNum = 1
        SizingString = f"{state.dataElectBaseboardRad.ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[FieldNum - 1]} [W]"
        CapSizingMethod = elecBaseboard.HeatingCapMethod
        zoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod

        if CapSizingMethod == DataSizing.HeatingDesignCapacity or CapSizingMethod == DataSizing.CapacityPerFloorArea or CapSizingMethod == DataSizing.FractionOfAutosizedHeatingCapacity:
            PrintFlag = True
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
                FracOfAutoSzCap = DataSizing.AutoSize
                ErrorsFound = False
                sizerHeatingCapacity = HeatingCapacitySizer()
                sizerHeatingCapacity.overrideSizingString(SizingString)
                sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
                FracOfAutoSzCap = sizerHeatingCapacity.size(state, FracOfAutoSzCap, ErrorsFound)
                TempSize = FracOfAutoSzCap
                state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                state.dataSize.DataScalableCapSizingON = True
            else:
                TempSize = elecBaseboard.ScaledHeatingCapacity

            errorsFound = False
            sizerHeatingCapacity = HeatingCapacitySizer()
            sizerHeatingCapacity.overrideSizingString(SizingString)
            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            elecBaseboard.NominalCapacity = sizerHeatingCapacity.size(state, TempSize, errorsFound)
            state.dataSize.DataScalableCapSizingON = False


def CalcElectricBaseboard(state, BaseboardNum: int, ControlledZoneNum: int):
    SimpConvAirFlowSpeed = 0.5

    elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

    ZoneNum = elecBaseboard.ZonePtr
    QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToHeatSP
    AirInletTemp = elecBaseboard.AirInletTemp
    AirOutletTemp = AirInletTemp
    CpAir = Psychrometrics.PsyCpAirFnW(elecBaseboard.AirInletHumRat)
    AirMassFlowRate = SimpConvAirFlowSpeed
    CapacitanceAir = CpAir * AirMassFlowRate

    Effic = elecBaseboard.BaseboardEfficiency

    LoadMet = 0.0
    QBBCap = 0.0
    RadHeat = 0.0

    if QZnReq > HVAC.SmallLoad and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum - 1] and elecBaseboard.availSched.getCurrentVal() > 0.0:
        if QZnReq > elecBaseboard.NominalCapacity:
            QBBCap = elecBaseboard.NominalCapacity
        else:
            QBBCap = QZnReq

        RadHeat = QBBCap * elecBaseboard.FracRadiant
        elecBaseboard.QBBElecRadSource = RadHeat

        if elecBaseboard.FracRadiant > 0.0:
            DistributeBBElecRadGains(state)
            HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
            HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)

            LoadMet = (state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state) - elecBaseboard.ZeroBBSourceSumHATsurf) + \
                      (QBBCap * elecBaseboard.FracConvect) + (RadHeat * elecBaseboard.FracDistribPerson)

            if LoadMet < 0.0:
                elecBaseboard.QBBElecRadSource = 0.0
                DistributeBBElecRadGains(state)
                HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
                HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)
                TempZeroBBSourceSumHATsurf = state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state)

                elecBaseboard.QBBElecRadSource = RadHeat
                DistributeBBElecRadGains(state)
                HeatBalanceSurfaceManager.CalcHeatBalanceOutsideSurf(state, ZoneNum)
                HeatBalanceSurfaceManager.CalcHeatBalanceInsideSurf(state, ZoneNum)

                LoadMet = (state.dataHeatBal.Zone[ZoneNum - 1].sumHATsurf(state) - TempZeroBBSourceSumHATsurf) + \
                          (QBBCap * elecBaseboard.FracConvect) + (RadHeat * elecBaseboard.FracDistribPerson)

                if LoadMet < 0.0:
                    UpdateElectricBaseboardOff(LoadMet, QBBCap, RadHeat, elecBaseboard.QBBElecRadSource, elecBaseboard.ElecUseRate, AirOutletTemp, AirInletTemp)
                else:
                    UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
            else:
                UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
        else:
            LoadMet = QBBCap
            UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
    else:
        UpdateElectricBaseboardOff(LoadMet, QBBCap, RadHeat, elecBaseboard.QBBElecRadSource, elecBaseboard.ElecUseRate, AirOutletTemp, AirInletTemp)

    elecBaseboard.AirOutletTemp = AirOutletTemp
    elecBaseboard.Power = QBBCap
    elecBaseboard.TotPower = LoadMet
    elecBaseboard.RadPower = RadHeat
    elecBaseboard.ConvPower = QBBCap - RadHeat


def UpdateElectricBaseboardOff(LoadMet: dict, QBBCap: dict, RadHeat: dict, QBBElecRadSrc: dict, ElecUseRate: dict, AirOutletTemp: dict, AirInletTemp: float):
    QBBCap["value"] = 0.0
    LoadMet["value"] = 0.0
    RadHeat["value"] = 0.0
    AirOutletTemp["value"] = AirInletTemp
    QBBElecRadSrc["value"] = 0.0
    ElecUseRate["value"] = 0.0


def UpdateElectricBaseboardOn(AirOutletTemp: dict, ElecUseRate: dict, AirInletTemp: float, QBBCap: float, CapacitanceAir: float, Effic: float):
    AirOutletTemp["value"] = AirInletTemp + QBBCap / CapacitanceAir
    ElecUseRate["value"] = QBBCap / Effic


def UpdateElectricBaseboard(state, BaseboardNum: int):
    SysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
    TimeStepSys = state.dataHVACGlobal.TimeStepSys
    elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]

    if elecBaseboard.LastSysTimeElapsed == SysTimeElapsed:
        elecBaseboard.QBBElecRadSrcAvg -= elecBaseboard.LastQBBElecRadSrc * elecBaseboard.LastTimeStepSys / state.dataGlobal.TimeStepZone

    elecBaseboard.QBBElecRadSrcAvg += elecBaseboard.QBBElecRadSource * TimeStepSys / state.dataGlobal.TimeStepZone

    elecBaseboard.LastQBBElecRadSrc = elecBaseboard.QBBElecRadSource
    elecBaseboard.LastSysTimeElapsed = SysTimeElapsed
    elecBaseboard.LastTimeStepSys = TimeStepSys


def UpdateBBElecRadSourceValAvg(state, ElecBaseboardSysOn: dict):
    ElecBaseboardSysOn["value"] = False

    if state.dataElectBaseboardRad.NumElecBaseboards == 0:
        return

    for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
        elecBaseboard.QBBElecRadSource = elecBaseboard.QBBElecRadSrcAvg
        if elecBaseboard.QBBElecRadSrcAvg != 0.0:
            ElecBaseboardSysOn["value"] = True

    DistributeBBElecRadGains(state)


def DistributeBBElecRadGains(state):
    SmallestArea = 0.001

    for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
        for radSurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
            surfNum = elecBaseboard.SurfacePtr[radSurfNum - 1]
            state.dataHeatBalFanSys.surfQRadFromHVAC[surfNum - 1].ElecBaseboard = 0.0

    state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson = [0.0] * len(state.dataHeatBal.Zone)

    for elecBaseboard in state.dataElectBaseboardRad.ElecBaseboard:
        if elecBaseboard.ZonePtr > 0:
            ZoneNum = elecBaseboard.ZonePtr
            state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson[ZoneNum - 1] += elecBaseboard.QBBElecRadSource * elecBaseboard.FracDistribPerson

            for RadSurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
                SurfNum = elecBaseboard.SurfacePtr[RadSurfNum - 1]
                if state.dataSurface.Surface[SurfNum - 1].Area > SmallestArea:
                    ThisSurfIntensity = (elecBaseboard.QBBElecRadSource * elecBaseboard.FracDistribToSurf[RadSurfNum - 1] / state.dataSurface.Surface[SurfNum - 1].Area)
                    state.dataHeatBalFanSys.surfQRadFromHVAC[SurfNum - 1].ElecBaseboard += ThisSurfIntensity
                    if ThisSurfIntensity > DataHeatBalFanSys.MaxRadHeatFlux:
                        ShowSevereError(state, "DistributeBBElecRadGains:  excessive thermal radiation heat flux intensity detected")
                        ShowContinueError(state, "Surface = " + state.dataSurface.Surface[SurfNum - 1].Name)
                        ShowContinueError(state, f"Surface area = {state.dataSurface.Surface[SurfNum - 1].Area:.G} [m2]")
                        ShowContinueError(state, "Occurs in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric + " = " + elecBaseboard.EquipName)
                        ShowContinueError(state, f"Radiation intensity = {ThisSurfIntensity:.G} [W/m2]")
                        ShowContinueError(state, "Assign a larger surface area or more surfaces in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric)
                        ShowFatalError(state, "DistributeBBElecRadGains:  excessive thermal radiation heat flux intensity detected")
                else:
                    ShowSevereError(state, "DistributeBBElecRadGains:  surface not large enough to receive thermal radiation heat flux")
                    ShowContinueError(state, "Surface = " + state.dataSurface.Surface[SurfNum - 1].Name)
                    ShowContinueError(state, f"Surface area = {state.dataSurface.Surface[SurfNum - 1].Area:.G} [m2]")
                    ShowContinueError(state, "Occurs in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric + " = " + elecBaseboard.EquipName)
                    ShowContinueError(state, "Assign a larger surface area or more surfaces in " + state.dataElectBaseboardRad.cCMO_BBRadiator_Electric)
                    ShowFatalError(state, "DistributeBBElecRadGains:  surface not large enough to receive thermal radiation heat flux")


def ReportElectricBaseboard(state, BaseboardNum: int):
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    elecBaseboard = state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1]
    elecBaseboard.ElecUseLoad = elecBaseboard.ElecUseRate * TimeStepSysSec
    elecBaseboard.TotEnergy = elecBaseboard.TotPower * TimeStepSysSec
    elecBaseboard.Energy = elecBaseboard.Power * TimeStepSysSec
    elecBaseboard.ConvEnergy = elecBaseboard.ConvPower * TimeStepSysSec
    elecBaseboard.RadEnergy = elecBaseboard.RadPower * TimeStepSysSec

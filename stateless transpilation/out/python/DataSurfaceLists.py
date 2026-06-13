from dataclasses import dataclass, field
from typing import List, Protocol, Any, Optional

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object type (passed as parameter)
# - state.dataSurfLists: SurfaceListsData with SurfList, SlabList, NumOfSurfaceLists, NumOfSurfListVentSlab, SurfaceListInputsFilled
# - state.dataSurface: Surface container with Surface list, SurfIsRadSurfOrVentSlabOrPool array
# - state.dataInputProcessing: InputProcessing container with inputProcessor
# - state.dataHeatBal: HeatBalance container with Zone list
# - state.dataGlobal: GlobalData container with DisplayExtraWarnings flag
# - Util.makeUPPER(s: str) -> str: convert string to uppercase
# - Util.FindItemInList(name: str, list: List, size: Optional[int]) -> int: find item by name (1-based or 0 if not found)
# - ShowSevereError(state, message: str) -> None
# - ShowWarningError(state, message: str) -> None
# - ShowContinueError(state, message: str) -> None
# - ShowFatalError(state, message: str) -> None


@dataclass
class SurfaceListData:
    Name: str = ""
    NumOfSurfaces: int = 0
    SurfName: List[str] = field(default_factory=list)
    SurfPtr: List[int] = field(default_factory=list)
    SurfFlowFrac: List[float] = field(default_factory=list)


@dataclass
class SlabListData:
    Name: str = ""
    NumOfSurfaces: int = 0
    SurfName: List[str] = field(default_factory=list)
    SurfPtr: List[int] = field(default_factory=list)
    ZoneName: List[str] = field(default_factory=list)
    ZonePtr: List[int] = field(default_factory=list)
    CoreDiameter: List[float] = field(default_factory=list)
    CoreLength: List[float] = field(default_factory=list)
    CoreNumbers: List[float] = field(default_factory=list)
    SlabInNodeName: List[str] = field(default_factory=list)
    SlabOutNodeName: List[str] = field(default_factory=list)


class SurfaceListsData:
    def __init__(self):
        self.NumOfSurfaceLists: int = 0
        self.NumOfSurfListVentSlab: int = 0
        self.SurfaceListInputsFilled: bool = False
        self.SurfList: List[SurfaceListData] = []
        self.SlabList: List[SlabListData] = []

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        self.NumOfSurfaceLists = 0
        self.NumOfSurfListVentSlab = 0
        self.SurfaceListInputsFilled = False
        self.SurfList = []
        self.SlabList = []


def GetSurfaceListsInputs(state):
    CurrentModuleObject1 = "ZoneHVAC:LowTemperatureRadiant:SurfaceGroup"
    CurrentModuleObject2 = "ZoneHVAC:VentilatedSlab:SlabGroup"
    FlowFractionTolerance = 0.0001
    SurfListMinFlowFrac = 0.001

    SurfList = state.dataSurfLists.SurfList
    SlabList = state.dataSurfLists.SlabList

    ErrorsFound = False

    inputProcessor = state.dataInputProcessing.inputProcessor

    NumOfSurfaceLists = inputProcessor.getNumObjectsFound(state, CurrentModuleObject1)
    NumOfSurfListVentSlab = inputProcessor.getNumObjectsFound(state, CurrentModuleObject2)

    state.dataSurfLists.NumOfSurfaceLists = NumOfSurfaceLists
    state.dataSurfLists.NumOfSurfListVentSlab = NumOfSurfListVentSlab

    SurfList.clear()
    for _ in range(NumOfSurfaceLists):
        SurfList.append(SurfaceListData())

    SlabList.clear()
    for _ in range(NumOfSurfListVentSlab):
        SlabList.append(SlabListData())

    if NumOfSurfaceLists > 0:
        surfaceGroupSchemaProps = inputProcessor.getObjectSchemaProps(state, CurrentModuleObject1)
        surfaceFractionSchemaProps = surfaceGroupSchemaProps["surface_fractions"]["items"]["properties"]
        surfaceGroupObjects = inputProcessor.epJSON.get(CurrentModuleObject1)
        surfaceNameFieldName = "Surface Name"

        if surfaceGroupObjects is not None:
            Item = 0
            for surfaceGroupName, surfaceGroupFields in surfaceGroupObjects.items():
                surfaceFractionsField = surfaceGroupFields.get("surface_fractions")

                inputProcessor.markObjectAsUsed(CurrentModuleObject1, surfaceGroupName)

                Item += 1
                SurfList[Item - 1].Name = Util.makeUPPER(surfaceGroupName)
                SurfList[Item - 1].NumOfSurfaces = len(surfaceFractionsField) if surfaceFractionsField else 0

                NameConflict = Util.FindItemInList(SurfList[Item - 1].Name, state.dataSurface.Surface)
                if NameConflict > 0:
                    ShowSevereError(
                        state,
                        f"{CurrentModuleObject1} = {SurfList[Item - 1].Name} has the same name as a surface; this is not allowed."
                    )
                    ErrorsFound = True

                if SurfList[Item - 1].NumOfSurfaces < 1:
                    ShowSevereError(
                        state,
                        f"{CurrentModuleObject1} = {SurfList[Item - 1].Name} does not have any surfaces listed."
                    )
                    ErrorsFound = True
                else:
                    SurfList[Item - 1].SurfName = [None] * SurfList[Item - 1].NumOfSurfaces
                    SurfList[Item - 1].SurfPtr = [0] * SurfList[Item - 1].NumOfSurfaces
                    SurfList[Item - 1].SurfFlowFrac = [0.0] * SurfList[Item - 1].NumOfSurfaces

                SumOfAllFractions = 0.0
                showSameZoneWarning = True
                ZoneForSurface = 0

                for SurfNum in range(SurfList[Item - 1].NumOfSurfaces):
                    surfaceFraction = surfaceFractionsField[SurfNum]
                    SurfList[Item - 1].SurfName[SurfNum] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(surfaceFraction, surfaceFractionSchemaProps, "surface_name")
                    )
                    SurfList[Item - 1].SurfPtr[SurfNum] = Util.FindItemInList(
                        SurfList[Item - 1].SurfName[SurfNum], state.dataSurface.Surface
                    )

                    if SurfList[Item - 1].SurfPtr[SurfNum] == 0:
                        ShowSevereError(
                            state,
                            f"{surfaceNameFieldName} in {CurrentModuleObject1} statement not found = {SurfList[Item - 1].SurfName[SurfNum]}"
                        )
                        ErrorsFound = True
                    else:
                        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[SurfList[Item - 1].SurfPtr[SurfNum]] = True
                        if SurfNum == 0:
                            ZoneForSurface = state.dataSurface.Surface[SurfList[Item - 1].SurfPtr[SurfNum]].Zone
                        if SurfNum > 0:
                            if ZoneForSurface != state.dataSurface.Surface[SurfList[Item - 1].SurfPtr[SurfNum]].Zone and showSameZoneWarning:
                                ShowWarningError(
                                    state,
                                    f"Not all surfaces in same zone for {CurrentModuleObject1} = {SurfList[Item - 1].Name}"
                                )
                                if not state.dataGlobal.DisplayExtraWarnings:
                                    ShowContinueError(
                                        state,
                                        "If this is intentionally a radiant system with surfaces in more than one thermal zone,"
                                    )
                                    ShowContinueError(
                                        state,
                                        "then ignore this warning message.  Use Output:Diagnostics,DisplayExtraWarnings for more details."
                                    )
                                showSameZoneWarning = False

                    SurfList[Item - 1].SurfFlowFrac[SurfNum] = inputProcessor.getRealFieldValue(
                        surfaceFraction, surfaceFractionSchemaProps, "flow_fraction_for_surface"
                    )

                    if SurfList[Item - 1].SurfFlowFrac[SurfNum] < SurfListMinFlowFrac:
                        ShowSevereError(
                            state,
                            f"The Flow Fraction for Surface {SurfList[Item - 1].SurfName[SurfNum]} in Surface Group {SurfList[Item - 1].Name} is too low"
                        )
                        ShowContinueError(
                            state,
                            f"Flow fraction of {SurfList[Item - 1].SurfFlowFrac[SurfNum]:.6f} is less than minimum criteria = {SurfListMinFlowFrac:.6f}"
                        )
                        ShowContinueError(
                            state,
                            "Zero or extremely low flow fractions are not allowed. Remove this surface from the surface group or combine small surfaces together."
                        )
                        ErrorsFound = True

                    SumOfAllFractions += SurfList[Item - 1].SurfFlowFrac[SurfNum]

                if abs(SumOfAllFractions - 1.0) > FlowFractionTolerance:
                    ShowSevereError(
                        state,
                        f"{CurrentModuleObject1} flow fractions do not add up to unity for {SurfList[Item - 1].Name}"
                    )
                    ErrorsFound = True

        if ErrorsFound:
            ShowSevereError(state, f"{CurrentModuleObject1} errors found getting input. Program will terminate.")

    if NumOfSurfListVentSlab > 0:
        slabGroupSchemaProps = inputProcessor.getObjectSchemaProps(state, CurrentModuleObject2)
        slabGroupDataSchemaProps = slabGroupSchemaProps["data"]["items"]["properties"]
        slabGroupObjects = inputProcessor.epJSON.get(CurrentModuleObject2)
        zoneNameFieldName = "Zone Name"
        slabSurfaceNameFieldName = "Surface Name"

        if slabGroupObjects is not None:
            Item = 0
            for slabGroupName, slabGroupFields in slabGroupObjects.items():
                slabGroupDataField = slabGroupFields.get("data")

                inputProcessor.markObjectAsUsed(CurrentModuleObject2, slabGroupName)

                Item += 1
                SlabList[Item - 1].Name = Util.makeUPPER(slabGroupName)
                SlabList[Item - 1].NumOfSurfaces = len(slabGroupDataField) if slabGroupDataField else 0

                NameConflict = Util.FindItemInList(SlabList[Item - 1].Name, state.dataSurface.Surface)
                if NameConflict > 0:
                    ShowSevereError(
                        state,
                        f"{CurrentModuleObject2} = {SlabList[Item - 1].Name} has the same name as a slab; this is not allowed."
                    )
                    ErrorsFound = True

                if SlabList[Item - 1].NumOfSurfaces < 1:
                    ShowSevereError(
                        state,
                        f"{CurrentModuleObject2} = {SlabList[Item - 1].Name} does not have any slabs listed."
                    )
                    ErrorsFound = True
                else:
                    SlabList[Item - 1].ZoneName = [None] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].ZonePtr = [0] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].SurfName = [None] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].SurfPtr = [0] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].CoreDiameter = [0.0] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].CoreLength = [0.0] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].CoreNumbers = [0.0] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].SlabInNodeName = [None] * SlabList[Item - 1].NumOfSurfaces
                    SlabList[Item - 1].SlabOutNodeName = [None] * SlabList[Item - 1].NumOfSurfaces

                for SurfNum in range(SlabList[Item - 1].NumOfSurfaces):
                    slabGroupData = slabGroupDataField[SurfNum]

                    SlabList[Item - 1].ZoneName[SurfNum] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "zone_name")
                    )
                    SlabList[Item - 1].ZonePtr[SurfNum] = Util.FindItemInList(
                        SlabList[Item - 1].ZoneName[SurfNum], state.dataHeatBal.Zone
                    )

                    if SlabList[Item - 1].ZonePtr[SurfNum] == 0:
                        ShowSevereError(
                            state,
                            f"{zoneNameFieldName} in {CurrentModuleObject2} Zone not found = {SlabList[Item - 1].ZoneName[SurfNum]}"
                        )
                        ErrorsFound = True

                    SlabList[Item - 1].SurfName[SurfNum] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "surface_name")
                    )
                    SlabList[Item - 1].SurfPtr[SurfNum] = Util.FindItemInList(
                        SlabList[Item - 1].SurfName[SurfNum], state.dataSurface.Surface
                    )

                    if SlabList[Item - 1].SurfPtr[SurfNum] == 0:
                        ShowSevereError(
                            state,
                            f"{slabSurfaceNameFieldName} in {CurrentModuleObject2} statement not found = {SlabList[Item - 1].SurfName[SurfNum]}"
                        )
                        ErrorsFound = True

                    for SrfList in range(NumOfSurfaceLists):
                        NameConflict = Util.FindItemInList(
                            SlabList[Item - 1].SurfName[SurfNum],
                            SurfList[SrfList].SurfName,
                            SurfList[SrfList].NumOfSurfaces
                        )
                        if NameConflict > 0:
                            ShowSevereError(
                                state,
                                f"{CurrentModuleObject2}=\"{SlabList[Item - 1].Name}\", invalid surface specified."
                            )
                            ShowContinueError(
                                state,
                                f"Surface=\"{SlabList[Item - 1].SurfName[SurfNum]}\" is also on a Surface List."
                            )
                            ShowContinueError(
                                state,
                                f"{CurrentModuleObject1}=\"{SurfList[SrfList].Name}\" has this surface also."
                            )
                            ShowContinueError(
                                state,
                                "A surface cannot be on both lists. The models cannot operate correctly."
                            )
                            ErrorsFound = True

                    state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[SlabList[Item - 1].SurfPtr[SurfNum]] = True

                    SlabList[Item - 1].CoreDiameter[SurfNum] = inputProcessor.getRealFieldValue(
                        slabGroupData, slabGroupDataSchemaProps, "core_diameter_for_surface"
                    )
                    SlabList[Item - 1].CoreLength[SurfNum] = inputProcessor.getRealFieldValue(
                        slabGroupData, slabGroupDataSchemaProps, "core_length_for_surface"
                    )
                    SlabList[Item - 1].CoreNumbers[SurfNum] = inputProcessor.getRealFieldValue(
                        slabGroupData, slabGroupDataSchemaProps, "core_numbers_for_surface"
                    )
                    SlabList[Item - 1].SlabInNodeName[SurfNum] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "slab_inlet_node_name_for_surface")
                    )
                    SlabList[Item - 1].SlabOutNodeName[SurfNum] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "slab_outlet_node_name_for_surface")
                    )

        if ErrorsFound:
            ShowSevereError(state, f"{CurrentModuleObject2} errors found getting input. Program will terminate.")

    if ErrorsFound:
        ShowFatalError(state, "GetSurfaceListsInputs: Program terminates due to preceding conditions.")


def GetNumberOfSurfaceLists(state) -> int:
    if not state.dataSurfLists.SurfaceListInputsFilled:
        GetSurfaceListsInputs(state)
        state.dataSurfLists.SurfaceListInputsFilled = True

    return state.dataSurfLists.NumOfSurfaceLists


def GetNumberOfSurfListVentSlab(state) -> int:
    if not state.dataSurfLists.SurfaceListInputsFilled:
        GetSurfaceListsInputs(state)
        state.dataSurfLists.SurfaceListInputsFilled = True

    NumberOfSurfListVentSlab = state.dataSurfLists.NumOfSurfListVentSlab

    return NumberOfSurfListVentSlab

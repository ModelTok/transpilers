from collections import InlineArray
from memory import memset_zero


struct SurfaceListData:
    var Name: String
    var NumOfSurfaces: Int
    var SurfName: DynamicVector[String]
    var SurfPtr: DynamicVector[Int]
    var SurfFlowFrac: DynamicVector[Float64]

    fn __init__(inout self):
        self.Name = String()
        self.NumOfSurfaces = 0
        self.SurfName = DynamicVector[String]()
        self.SurfPtr = DynamicVector[Int]()
        self.SurfFlowFrac = DynamicVector[Float64]()


struct SlabListData:
    var Name: String
    var NumOfSurfaces: Int
    var SurfName: DynamicVector[String]
    var SurfPtr: DynamicVector[Int]
    var ZoneName: DynamicVector[String]
    var ZonePtr: DynamicVector[Int]
    var CoreDiameter: DynamicVector[Float64]
    var CoreLength: DynamicVector[Float64]
    var CoreNumbers: DynamicVector[Float64]
    var SlabInNodeName: DynamicVector[String]
    var SlabOutNodeName: DynamicVector[String]

    fn __init__(inout self):
        self.Name = String()
        self.NumOfSurfaces = 0
        self.SurfName = DynamicVector[String]()
        self.SurfPtr = DynamicVector[Int]()
        self.ZoneName = DynamicVector[String]()
        self.ZonePtr = DynamicVector[Int]()
        self.CoreDiameter = DynamicVector[Float64]()
        self.CoreLength = DynamicVector[Float64]()
        self.CoreNumbers = DynamicVector[Float64]()
        self.SlabInNodeName = DynamicVector[String]()
        self.SlabOutNodeName = DynamicVector[String]()


struct SurfaceListsData:
    var NumOfSurfaceLists: Int
    var NumOfSurfListVentSlab: Int
    var SurfaceListInputsFilled: Bool
    var SurfList: DynamicVector[SurfaceListData]
    var SlabList: DynamicVector[SlabListData]

    fn __init__(inout self):
        self.NumOfSurfaceLists = 0
        self.NumOfSurfListVentSlab = 0
        self.SurfaceListInputsFilled = False
        self.SurfList = DynamicVector[SurfaceListData]()
        self.SlabList = DynamicVector[SlabListData]()

    fn init_constant_state(inout self, state):
        pass

    fn init_state(inout self, state):
        pass

    fn clear_state(inout self):
        self.NumOfSurfaceLists = 0
        self.NumOfSurfListVentSlab = 0
        self.SurfaceListInputsFilled = False
        self.SurfList = DynamicVector[SurfaceListData]()
        self.SlabList = DynamicVector[SlabListData]()


fn GetSurfaceListsInputs(state) -> None:
    alias CurrentModuleObject1 = "ZoneHVAC:LowTemperatureRadiant:SurfaceGroup"
    alias CurrentModuleObject2 = "ZoneHVAC:VentilatedSlab:SlabGroup"
    alias FlowFractionTolerance = 0.0001
    alias SurfListMinFlowFrac = 0.001

    var SurfList = state.dataSurfLists.SurfList
    var SlabList = state.dataSurfLists.SlabList

    var ErrorsFound = False

    var inputProcessor = state.dataInputProcessing.inputProcessor

    var NumOfSurfaceLists = inputProcessor.getNumObjectsFound(state, CurrentModuleObject1)
    var NumOfSurfListVentSlab = inputProcessor.getNumObjectsFound(state, CurrentModuleObject2)

    state.dataSurfLists.NumOfSurfaceLists = NumOfSurfaceLists
    state.dataSurfLists.NumOfSurfListVentSlab = NumOfSurfListVentSlab

    for _ in range(NumOfSurfaceLists):
        SurfList.push_back(SurfaceListData())

    for _ in range(NumOfSurfListVentSlab):
        SlabList.push_back(SlabListData())

    if NumOfSurfaceLists > 0:
        var surfaceGroupSchemaProps = inputProcessor.getObjectSchemaProps(state, CurrentModuleObject1)
        var surfaceFractionSchemaProps = surfaceGroupSchemaProps["surface_fractions"]["items"]["properties"]
        var surfaceGroupObjects = inputProcessor.epJSON.get(CurrentModuleObject1)
        alias surfaceNameFieldName = "Surface Name"

        if surfaceGroupObjects is not None:
            var Item = 0
            for surfaceGroupName, surfaceGroupFields in surfaceGroupObjects.items():
                var surfaceFractionsField = surfaceGroupFields.get("surface_fractions")

                inputProcessor.markObjectAsUsed(CurrentModuleObject1, surfaceGroupName)

                Item += 1
                SurfList[Item - 1].Name = Util.makeUPPER(surfaceGroupName)
                SurfList[Item - 1].NumOfSurfaces = len(surfaceFractionsField) if surfaceFractionsField else 0

                var NameConflict = Util.FindItemInList(SurfList[Item - 1].Name, state.dataSurface.Surface)
                if NameConflict > 0:
                    ShowSevereError(
                        state,
                        CurrentModuleObject1 + " = " + SurfList[Item - 1].Name + " has the same name as a surface; this is not allowed."
                    )
                    ErrorsFound = True

                if SurfList[Item - 1].NumOfSurfaces < 1:
                    ShowSevereError(
                        state,
                        CurrentModuleObject1 + " = " + SurfList[Item - 1].Name + " does not have any surfaces listed."
                    )
                    ErrorsFound = True
                else:
                    for _ in range(SurfList[Item - 1].NumOfSurfaces):
                        SurfList[Item - 1].SurfName.push_back(String())
                        SurfList[Item - 1].SurfPtr.push_back(0)
                        SurfList[Item - 1].SurfFlowFrac.push_back(0.0)

                var SumOfAllFractions = 0.0
                var showSameZoneWarning = True
                var ZoneForSurface = 0

                for SurfNum in range(SurfList[Item - 1].NumOfSurfaces):
                    var surfaceFraction = surfaceFractionsField[SurfNum]
                    SurfList[Item - 1].SurfName[SurfNum] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(surfaceFraction, surfaceFractionSchemaProps, "surface_name")
                    )
                    SurfList[Item - 1].SurfPtr[SurfNum] = Util.FindItemInList(
                        SurfList[Item - 1].SurfName[SurfNum], state.dataSurface.Surface
                    )

                    if SurfList[Item - 1].SurfPtr[SurfNum] == 0:
                        ShowSevereError(
                            state,
                            surfaceNameFieldName + " in " + CurrentModuleObject1 + " statement not found = " + SurfList[Item - 1].SurfName[SurfNum]
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
                                    "Not all surfaces in same zone for " + CurrentModuleObject1 + " = " + SurfList[Item - 1].Name
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
                            "The Flow Fraction for Surface " + SurfList[Item - 1].SurfName[SurfNum] + " in Surface Group " + SurfList[Item - 1].Name + " is too low"
                        )
                        ShowContinueError(
                            state,
                            "Flow fraction of " + str(SurfList[Item - 1].SurfFlowFrac[SurfNum]) + " is less than minimum criteria = " + str(SurfListMinFlowFrac)
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
                        CurrentModuleObject1 + " flow fractions do not add up to unity for " + SurfList[Item - 1].Name
                    )
                    ErrorsFound = True

        if ErrorsFound:
            ShowSevereError(state, CurrentModuleObject1 + " errors found getting input. Program will terminate.")

    if NumOfSurfListVentSlab > 0:
        var slabGroupSchemaProps = inputProcessor.getObjectSchemaProps(state, CurrentModuleObject2)
        var slabGroupDataSchemaProps = slabGroupSchemaProps["data"]["items"]["properties"]
        var slabGroupObjects = inputProcessor.epJSON.get(CurrentModuleObject2)
        alias zoneNameFieldName = "Zone Name"
        alias slabSurfaceNameFieldName = "Surface Name"

        if slabGroupObjects is not None:
            var Item = 0
            for slabGroupName, slabGroupFields in slabGroupObjects.items():
                var slabGroupDataField = slabGroupFields.get("data")

                inputProcessor.markObjectAsUsed(CurrentModuleObject2, slabGroupName)

                Item += 1
                SlabList[Item - 1].Name = Util.makeUPPER(slabGroupName)
                SlabList[Item - 1].NumOfSurfaces = len(slabGroupDataField) if slabGroupDataField else 0

                var NameConflict = Util.FindItemInList(SlabList[Item - 1].Name, state.dataSurface.Surface)
                if NameConflict > 0:
                    ShowSevereError(
                        state,
                        CurrentModuleObject2 + " = " + SlabList[Item - 1].Name + " has the same name as a slab; this is not allowed."
                    )
                    ErrorsFound = True

                if SlabList[Item - 1].NumOfSurfaces < 1:
                    ShowSevereError(
                        state,
                        CurrentModuleObject2 + " = " + SlabList[Item - 1].Name + " does not have any slabs listed."
                    )
                    ErrorsFound = True
                else:
                    for _ in range(SlabList[Item - 1].NumOfSurfaces):
                        SlabList[Item - 1].ZoneName.push_back(String())
                        SlabList[Item - 1].ZonePtr.push_back(0)
                        SlabList[Item - 1].SurfName.push_back(String())
                        SlabList[Item - 1].SurfPtr.push_back(0)
                        SlabList[Item - 1].CoreDiameter.push_back(0.0)
                        SlabList[Item - 1].CoreLength.push_back(0.0)
                        SlabList[Item - 1].CoreNumbers.push_back(0.0)
                        SlabList[Item - 1].SlabInNodeName.push_back(String())
                        SlabList[Item - 1].SlabOutNodeName.push_back(String())

                for SurfNum in range(SlabList[Item - 1].NumOfSurfaces):
                    var slabGroupData = slabGroupDataField[SurfNum]

                    SlabList[Item - 1].ZoneName[SurfNum] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "zone_name")
                    )
                    SlabList[Item - 1].ZonePtr[SurfNum] = Util.FindItemInList(
                        SlabList[Item - 1].ZoneName[SurfNum], state.dataHeatBal.Zone
                    )

                    if SlabList[Item - 1].ZonePtr[SurfNum] == 0:
                        ShowSevereError(
                            state,
                            zoneNameFieldName + " in " + CurrentModuleObject2 + " Zone not found = " + SlabList[Item - 1].ZoneName[SurfNum]
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
                            slabSurfaceNameFieldName + " in " + CurrentModuleObject2 + " statement not found = " + SlabList[Item - 1].SurfName[SurfNum]
                        )
                        ErrorsFound = True

                    for SrfList in range(NumOfSurfaceLists):
                        var NameConflict2 = Util.FindItemInList(
                            SlabList[Item - 1].SurfName[SurfNum],
                            SurfList[SrfList].SurfName,
                            SurfList[SrfList].NumOfSurfaces
                        )
                        if NameConflict2 > 0:
                            ShowSevereError(
                                state,
                                CurrentModuleObject2 + "=\"" + SlabList[Item - 1].Name + "\", invalid surface specified."
                            )
                            ShowContinueError(
                                state,
                                "Surface=\"" + SlabList[Item - 1].SurfName[SurfNum] + "\" is also on a Surface List."
                            )
                            ShowContinueError(
                                state,
                                CurrentModuleObject1 + "=\"" + SurfList[SrfList].Name + "\" has this surface also."
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
            ShowSevereError(state, CurrentModuleObject2 + " errors found getting input. Program will terminate.")

    if ErrorsFound:
        ShowFatalError(state, "GetSurfaceListsInputs: Program terminates due to preceding conditions.")


fn GetNumberOfSurfaceLists(state) -> Int:
    if not state.dataSurfLists.SurfaceListInputsFilled:
        GetSurfaceListsInputs(state)
        state.dataSurfLists.SurfaceListInputsFilled = True

    return state.dataSurfLists.NumOfSurfaceLists


fn GetNumberOfSurfListVentSlab(state) -> Int:
    if not state.dataSurfLists.SurfaceListInputsFilled:
        GetSurfaceListsInputs(state)
        state.dataSurfLists.SurfaceListInputsFilled = True

    var NumberOfSurfListVentSlab = state.dataSurfLists.NumOfSurfListVentSlab

    return NumberOfSurfListVentSlab

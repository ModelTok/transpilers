from .Data.EnergyPlusData import EnergyPlusData
from DataHeatBalance import Zone
from DataSurfaces import Surface, SurfIsRadSurfOrVentSlabOrPool
from General import ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError
from .InputProcessing.InputProcessor import InputProcessor
from UtilityRoutines import Util
from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.DataGlobals import DisplayExtraWarnings
struct SurfaceListData:
    var Name: String
    var NumOfSurfaces: Int
    var SurfName: List[String]
    var SurfPtr: List[Int]
    var SurfFlowFrac: List[Float64]
    def __init__(inout self):
        self.Name = String("")
        self.NumOfSurfaces = 0
        self.SurfName = List[String]()
        self.SurfPtr = List[Int]()
        self.SurfFlowFrac = List[Float64]()
struct SlabListData:
    var Name: String
    var NumOfSurfaces: Int
    var SurfName: List[String]
    var SurfPtr: List[Int]
    var ZoneName: List[String]
    var ZonePtr: List[Int]
    var CoreDiameter: List[Float64]
    var CoreLength: List[Float64]
    var CoreNumbers: List[Float64]
    var SlabInNodeName: List[String]
    var SlabOutNodeName: List[String]
    def __init__(inout self):
        self.Name = String("")
        self.NumOfSurfaces = 0
        self.SurfName = List[String]()
        self.SurfPtr = List[Int]()
        self.ZoneName = List[String]()
        self.ZonePtr = List[Int]()
        self.CoreDiameter = List[Float64]()
        self.CoreLength = List[Float64]()
        self.CoreNumbers = List[Float64]()
        self.SlabInNodeName = List[String]()
        self.SlabOutNodeName = List[String]()
struct SurfaceListsData(BaseGlobalStruct):
    var NumOfSurfaceLists: Int = 0
    var NumOfSurfListVentSlab: Int = 0
    var SurfaceListInputsFilled: Bool = False
    var SurfList: List[SurfaceListData]
    var SlabList: List[SlabListData]
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumOfSurfaceLists = 0
        self.NumOfSurfListVentSlab = 0
        self.SurfaceListInputsFilled = False
        self.SurfList = List[SurfaceListData]()
        self.SlabList = List[SlabListData]()
def GetSurfaceListsInputs(inout state: EnergyPlusData):
    const CurrentModuleObject1: StringLiteral = "ZoneHVAC:LowTemperatureRadiant:SurfaceGroup"
    const CurrentModuleObject2: StringLiteral = "ZoneHVAC:VentilatedSlab:SlabGroup"
    const FlowFractionTolerance: Float64 = 0.0001
    const SurfListMinFlowFrac: Float64 = 0.001
    var NameConflict: Int
    var SumOfAllFractions: Float64
    var ErrorsFound: Bool
    var SurfList = state.dataSurfLists.SurfList
    var SlabList = state.dataSurfLists.SlabList
    ErrorsFound = False
    var inputProcessor = state.dataInputProcessing.inputProcessor.get()
    var NumOfSurfaceLists = state.dataSurfLists.NumOfSurfaceLists = inputProcessor.getNumObjectsFound(state, CurrentModuleObject1)
    var NumOfSurfListVentSlab = state.dataSurfLists.NumOfSurfListVentSlab = inputProcessor.getNumObjectsFound(state, CurrentModuleObject2)
    SurfList.allocate(NumOfSurfaceLists)
    SlabList.allocate(NumOfSurfListVentSlab)
    if NumOfSurfaceLists > 0:
        var surfaceGroupSchemaProps = inputProcessor.getObjectSchemaProps(state, String(CurrentModuleObject1))
        var surfaceFractionSchemaProps = surfaceGroupSchemaProps["surface_fractions"]["items"]["properties"]
        var surfaceGroupObjects = inputProcessor.epJSON.find(String(CurrentModuleObject1))
        const surfaceNameFieldName: StringLiteral = "Surface Name"
        if surfaceGroupObjects != inputProcessor.epJSON.end():
            var Item = 0
            for let surfaceGroupInstance in surfaceGroupObjects.value().items():
                var surfaceGroupFields = surfaceGroupInstance.value()
                var surfaceGroupName = Util.makeUPPER(surfaceGroupInstance.key())
                var surfaceFractionsField = surfaceGroupFields.find("surface_fractions")
                inputProcessor.markObjectAsUsed(String(CurrentModuleObject1), surfaceGroupInstance.key())
                Item += 1
                SurfList[Item - 1].Name = surfaceGroupName
                if surfaceFractionsField != surfaceGroupFields.end():
                    SurfList[Item - 1].NumOfSurfaces = surfaceFractionsField.size()
                else:
                    SurfList[Item - 1].NumOfSurfaces = 0
                NameConflict = Util.FindItemInList(SurfList[Item - 1].Name, state.dataSurface.Surface)
                if NameConflict > 0:
                    ShowSevereError(state, "{} = " + SurfList[Item - 1].Name + " has the same name as a surface; this is not allowed.".format(CurrentModuleObject1))
                    ErrorsFound = True
                if SurfList[Item - 1].NumOfSurfaces < 1:
                    ShowSevereError(state, "{} = " + SurfList[Item - 1].Name + " does not have any surfaces listed.".format(CurrentModuleObject1))
                    ErrorsFound = True
                else:
                    SurfList[Item - 1].SurfName.allocate(SurfList[Item - 1].NumOfSurfaces)
                    SurfList[Item - 1].SurfPtr.allocate(SurfList[Item - 1].NumOfSurfaces)
                    SurfList[Item - 1].SurfFlowFrac.allocate(SurfList[Item - 1].NumOfSurfaces)
                SumOfAllFractions = 0.0
                var showSameZoneWarning: Bool = True
                var ZoneForSurface: Int = 0
                for SurfNum in range(1, SurfList[Item - 1].NumOfSurfaces + 1):
                    var surfaceFraction = surfaceFractionsField[SurfNum - 1]
                    SurfList[Item - 1].SurfName[SurfNum - 1] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(surfaceFraction, surfaceFractionSchemaProps, "surface_name"))
                    SurfList[Item - 1].SurfPtr[SurfNum - 1] = Util.FindItemInList(
                        SurfList[Item - 1].SurfName[SurfNum - 1], state.dataSurface.Surface)
                    if SurfList[Item - 1].SurfPtr[SurfNum - 1] == 0:
                        ShowSevereError(
                            state,
                            "{} in {} statement not found = {}".format(surfaceNameFieldName, CurrentModuleObject1, SurfList[Item - 1].SurfName[SurfNum - 1])
                        )
                        ErrorsFound = True
                    else:
                        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[SurfList[Item - 1].SurfPtr[SurfNum - 1] - 1] = True
                        if SurfNum == 1:
                            ZoneForSurface = state.dataSurface.Surface[SurfList[Item - 1].SurfPtr[SurfNum - 1] - 1].Zone
                        if SurfNum > 1:
                            if ZoneForSurface != state.dataSurface.Surface[SurfList[Item - 1].SurfPtr[SurfNum - 1] - 1].Zone and showSameZoneWarning:
                                ShowWarningError(state,
                                    "Not all surfaces in same zone for {} = {}".format(CurrentModuleObject1, SurfList[Item - 1].Name))
                                if not state.dataGlobal.DisplayExtraWarnings:
                                    ShowContinueError(state,
                                        "If this is intentionally a radiant system with surfaces in more than one thermal zone,")
                                    ShowContinueError(state,
                                        "then ignore this warning message.  Use Output:Diagnostics,DisplayExtraWarnings for more details.")
                                showSameZoneWarning = False
                    SurfList[Item - 1].SurfFlowFrac[SurfNum - 1] = inputProcessor.getRealFieldValue(
                        surfaceFraction, surfaceFractionSchemaProps, "flow_fraction_for_surface")
                    if SurfList[Item - 1].SurfFlowFrac[SurfNum - 1] < SurfListMinFlowFrac:
                        ShowSevereError(state,
                            "The Flow Fraction for Surface {} in Surface Group {} is too low".format(
                                SurfList[Item - 1].SurfName[SurfNum - 1], SurfList[Item - 1].Name))
                        ShowContinueError(state,
                            "Flow fraction of {:.6f} is less than minimum criteria = {:.6f}".format(
                                SurfList[Item - 1].SurfFlowFrac[SurfNum - 1], SurfListMinFlowFrac))
                        ShowContinueError(state,
                            "Zero or extremely low flow fractions are not allowed. Remove this surface from the surface group or combine small surfaces together.")
                        ErrorsFound = True
                    SumOfAllFractions += SurfList[Item - 1].SurfFlowFrac[SurfNum - 1]
                if abs(SumOfAllFractions - 1.0) > FlowFractionTolerance:
                    ShowSevereError(state,
                        "{} flow fractions do not add up to unity for ".format(CurrentModuleObject1) + SurfList[Item - 1].Name)
                    ErrorsFound = True
        if ErrorsFound:
            ShowSevereError(state, "{} errors found getting input. Program will terminate.".format(CurrentModuleObject1))
    if NumOfSurfListVentSlab > 0:
        var slabGroupSchemaProps = inputProcessor.getObjectSchemaProps(state, String(CurrentModuleObject2))
        var slabGroupDataSchemaProps = slabGroupSchemaProps["data"]["items"]["properties"]
        var slabGroupObjects = inputProcessor.epJSON.find(String(CurrentModuleObject2))
        const zoneNameFieldName: StringLiteral = "Zone Name"
        const slabSurfaceNameFieldName: StringLiteral = "Surface Name"
        if slabGroupObjects != inputProcessor.epJSON.end():
            var Item = 0
            for let slabGroupInstance in slabGroupObjects.value().items():
                var slabGroupFields = slabGroupInstance.value()
                var slabGroupName = Util.makeUPPER(slabGroupInstance.key())
                var slabGroupDataField = slabGroupFields.find("data")
                inputProcessor.markObjectAsUsed(String(CurrentModuleObject2), slabGroupInstance.key())
                Item += 1
                SlabList[Item - 1].Name = slabGroupName
                if slabGroupDataField != slabGroupFields.end():
                    SlabList[Item - 1].NumOfSurfaces = slabGroupDataField.size()
                else:
                    SlabList[Item - 1].NumOfSurfaces = 0
                NameConflict = Util.FindItemInList(SlabList[Item - 1].Name, state.dataSurface.Surface)
                if NameConflict > 0:
                    ShowSevereError(state,
                        "{} = " + SlabList[Item - 1].Name + " has the same name as a slab; this is not allowed.".format(CurrentModuleObject2))
                    ErrorsFound = True
                if SlabList[Item - 1].NumOfSurfaces < 1:
                    ShowSevereError(state,
                        "{} = " + SlabList[Item - 1].Name + " does not have any slabs listed.".format(CurrentModuleObject2))
                    ErrorsFound = True
                else:
                    SlabList[Item - 1].ZoneName.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].ZonePtr.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].SurfName.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].SurfPtr.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].CoreDiameter.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].CoreLength.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].CoreNumbers.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].SlabInNodeName.allocate(SlabList[Item - 1].NumOfSurfaces)
                    SlabList[Item - 1].SlabOutNodeName.allocate(SlabList[Item - 1].NumOfSurfaces)
                for SurfNum in range(1, SlabList[Item - 1].NumOfSurfaces + 1):
                    var slabGroupData = slabGroupDataField[SurfNum - 1]
                    SlabList[Item - 1].ZoneName[SurfNum - 1] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "zone_name"))
                    SlabList[Item - 1].ZonePtr[SurfNum - 1] = Util.FindItemInList(
                        SlabList[Item - 1].ZoneName[SurfNum - 1], state.dataHeatBal.Zone)
                    if SlabList[Item - 1].ZonePtr[SurfNum - 1] == 0:
                        ShowSevereError(state,
                            "{} in {} Zone not found = {}".format(zoneNameFieldName, CurrentModuleObject2, SlabList[Item - 1].ZoneName[SurfNum - 1]))
                        ErrorsFound = True
                    SlabList[Item - 1].SurfName[SurfNum - 1] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "surface_name"))
                    SlabList[Item - 1].SurfPtr[SurfNum - 1] = Util.FindItemInList(
                        SlabList[Item - 1].SurfName[SurfNum - 1], state.dataSurface.Surface)
                    if SlabList[Item - 1].SurfPtr[SurfNum - 1] == 0:
                        ShowSevereError(state,
                            "{} in {} statement not found = {}".format(
                                slabSurfaceNameFieldName, CurrentModuleObject2, SlabList[Item - 1].SurfName[SurfNum - 1]))
                        ErrorsFound = True
                    for SrfList in range(1, NumOfSurfaceLists + 1):
                        NameConflict = Util.FindItemInList(
                            SlabList[Item - 1].SurfName[SurfNum - 1],
                            SurfList[SrfList - 1].SurfName,
                            SurfList[SrfList - 1].NumOfSurfaces)
                        if NameConflict > 0:
                            ShowSevereError(state,
                                "{}=\"".format(CurrentModuleObject2) + SlabList[Item - 1].Name + "\", invalid surface specified.")
                            ShowContinueError(state,
                                "Surface=\"{}\" is also on a Surface List.".format(SlabList[Item - 1].SurfName[SurfNum - 1]))
                            ShowContinueError(state,
                                "{}=\"".format(CurrentModuleObject1) + SurfList[SrfList - 1].Name + "\" has this surface also.")
                            ShowContinueError(state,
                                "A surface cannot be on both lists. The models cannot operate correctly.")
                            ErrorsFound = True
                    state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[SlabList[Item - 1].SurfPtr[SurfNum - 1] - 1] = True
                    SlabList[Item - 1].CoreDiameter[SurfNum - 1] = inputProcessor.getRealFieldValue(
                        slabGroupData, slabGroupDataSchemaProps, "core_diameter_for_surface")
                    SlabList[Item - 1].CoreLength[SurfNum - 1] = inputProcessor.getRealFieldValue(
                        slabGroupData, slabGroupDataSchemaProps, "core_length_for_surface")
                    SlabList[Item - 1].CoreNumbers[SurfNum - 1] = inputProcessor.getRealFieldValue(
                        slabGroupData, slabGroupDataSchemaProps, "core_numbers_for_surface")
                    SlabList[Item - 1].SlabInNodeName[SurfNum - 1] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "slab_inlet_node_name_for_surface"))
                    SlabList[Item - 1].SlabOutNodeName[SurfNum - 1] = Util.makeUPPER(
                        inputProcessor.getAlphaFieldValue(slabGroupData, slabGroupDataSchemaProps, "slab_outlet_node_name_for_surface"))
        if ErrorsFound:
            ShowSevereError(state, "{} errors found getting input. Program will terminate.".format(CurrentModuleObject2))
    if ErrorsFound:
        ShowFatalError(state, "GetSurfaceListsInputs: Program terminates due to preceding conditions.")
def GetNumberOfSurfaceLists(inout state: EnergyPlusData) -> Int:
    if not state.dataSurfLists.SurfaceListInputsFilled:
        GetSurfaceListsInputs(state)
        state.dataSurfLists.SurfaceListInputsFilled = True
    return state.dataSurfLists.NumOfSurfaceLists
def GetNumberOfSurfListVentSlab(inout state: EnergyPlusData) -> Int:
    var NumberOfSurfListVentSlab: Int
    if not state.dataSurfLists.SurfaceListInputsFilled:
        GetSurfaceListsInputs(state)
        state.dataSurfLists.SurfaceListInputsFilled = True
    NumberOfSurfListVentSlab = state.dataSurfLists.NumOfSurfListVentSlab
    return NumberOfSurfListVentSlab
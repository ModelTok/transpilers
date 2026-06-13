from .Data.EnergyPlusData import EnergyPlusData
from DataSurfaceColors import DataSurfaceColors, SurfaceColorData, ColorNo
from .InputProcessing.InputProcessor import InputProcessor
from UtilityRoutines import UtilityRoutines
def MatchAndSetColorTextString(
    state: EnergyPlusData,
    String: String,
    SetValue: Int,
    ColorType: StringLiteral
) -> Bool:
    alias colorkeys = StaticTuple[
        "TEXT",
        "WALLS",
        "WINDOWS",
        "GLASSDOORS",
        "DOORS",
        "ROOFS",
        "FLOORS",
        "DETACHEDBUILDINGSHADES",
        "DETACHEDFIXEDSHADES",
        "ATTACHEDBUILDINGSHADES",
        "PHOTOVOLTAICS",
        "TUBULARDAYLIGHTDOMES",
        "TUBULARDAYLIGHTDIFFUSERS",
        "DAYLIGHTREFERENCEPOINT1",
        "DAYLIGHTREFERENCEPOINT2",
    ]
    if ColorType != "DXF":
        return False
    var foundIdx = getEnumValue(colorkeys, UtilityRoutines.makeUPPER(String))
    if foundIdx == -1:
        return False
    state.dataSurfColor.DXFcolorno[foundIdx] = SetValue
    return True
def SetUpSchemeColors(state: EnergyPlusData, SchemeName: String, ColorType: StringLiteral):
    alias CurrentModuleObject = "OutputControl:SurfaceColorScheme"
    state.dataSurfColor.DXFcolorno = DataSurfaceColors.defaultcolorno
    var inputProcessor = state.dataInputProcessing.inputProcessor.get()
    var surfaceColorSchemes = inputProcessor.epJSON.find(String(CurrentModuleObject))
    if surfaceColorSchemes != inputProcessor.epJSON.end():
        var matchedScheme = surfaceColorSchemes.value().end()
        for it in range(surfaceColorSchemes.value().begin(), surfaceColorSchemes.value().end()):
            if UtilityRoutines.SameString(it.key(), SchemeName):
                matchedScheme = it
                break
        if matchedScheme != surfaceColorSchemes.value().end():
            var schemeFields = matchedScheme.value()
            inputProcessor.markObjectAsUsed(String(CurrentModuleObject), matchedScheme.key())
            var numargs = 1
            while True:
                var drawingElementKey = "drawing_element_{}_type".format(numargs)
                var colorKey = "color_for_drawing_element_{}".format(numargs)
                var drawingElementIt = schemeFields.find(drawingElementKey)
                var colorIt = schemeFields.find(colorKey)
                if drawingElementIt == schemeFields.end() and colorIt == schemeFields.end():
                    break
                var drawingElementFieldName = "Drawing Element {} Type".format(numargs)
                var colorFieldName = "Color for Drawing Element {}".format(numargs)
                var drawingElement = ""
                if drawingElementIt != schemeFields.end():
                    drawingElement = drawingElementIt.get()[]
                else:
                    drawingElement = ""
                if colorIt == schemeFields.end():
                    if not drawingElement.empty():
                        ShowWarningError(
                            state,
                            "SetUpSchemeColors: {}={}, {}={}, {} was blank.  Default color retained.".format(
                                "Name",
                                SchemeName,
                                drawingElementFieldName,
                                drawingElement,
                                colorFieldName
                            )
                        )
                    numargs += 1
                    continue
                var numptr = colorIt.get()[]
                if not MatchAndSetColorTextString(state, drawingElement, numptr, ColorType):
                    ShowWarningError(
                        state,
                        "SetUpSchemeColors: {}={}, {}={}, is invalid.  No color set.".format(
                            "Name",
                            SchemeName,
                            drawingElementFieldName,
                            drawingElement
                        )
                    )
                numargs += 1
        else:
            ShowWarningError(
                state,
                "SetUpSchemeColors: Name={} not on input file. Default colors will be used.".format(SchemeName)
            )
    else:
        ShowWarningError(
            state,
            "SetUpSchemeColors: Name={} not on input file. Default colors will be used.".format(SchemeName)
        )
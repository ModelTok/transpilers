from .. import DataSurfaceColors
from .. import EnergyPlusData
from ...Fixtures import EnergyPlusFixture

struct EnergyPlusFixture:
    var state: EnergyPlusData

def TestMatchAndSetColorTextString():
    var testStr: String = "Text"
    var setVal: Int = 1
    var colorSet: Bool = DataSurfaceColors.MatchAndSetColorTextString(state, testStr, setVal, "DXF")
    assert(colorSet == True)
    assert(state.dataSurfColor.DXFcolorno[0] == setVal)
    testStr = "DaylightReferencePoint2"
    setVal = 3
    colorSet = DataSurfaceColors.MatchAndSetColorTextString(state, testStr, setVal, "DXF")
    assert(colorSet == True)
    assert(state.dataSurfColor.DXFcolorno[14] == setVal)
    testStr = "Invalid"
    setVal = 3
    colorSet = DataSurfaceColors.MatchAndSetColorTextString(state, testStr, setVal, "DXF")
    assert(colorSet == False)

def TestSetupColorSchemes():
    var idf_object: String = "OutputControl:SurfaceColorScheme, highlight PV, Photovoltaics, 2;"
    assert(process_idf(idf_object, False) == True)
    DataSurfaceColors.SetUpSchemeColors(state, "HIGHLIGHT PV", "DXF")
    assert(state.dataSurfColor.DXFcolorno[10] == 2)  # TODO: Should take off DXF argument to these functions, and these magic numbers should go
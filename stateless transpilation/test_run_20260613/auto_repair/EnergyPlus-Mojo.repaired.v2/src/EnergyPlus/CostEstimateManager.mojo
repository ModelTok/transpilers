# Mojo translation of CostEstimateManager.cc and CostEstimateManager.hh
# Faithful 1:1 translation, no refactoring.

from .Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.Data.HeatBalance import Zone
from EnergyPlus.Data.IPShortCuts import cCurrentModuleObject, cAlphaArgs, rNumericArgs
from Photovoltaics import PVarray, PVModel, PVModelSimple
from EnergyPlus.Data.Surfaces import Surface
from EnergyPlus.Data.Daylighting import ZoneDaylight, totRefPts
from Construction import Construct
from DXCoils import DXCoil, NumDXCoils
from HeatingCoils import HeatingCoil, NumHeatingCoils
from PlantChillers import ElectricChiller
from .Coils.CoilCoolingDX import coilCoolingDXs
from EnergyPlus.Data import BaseGlobalStruct
from .InputProcessing.InputProcessor import getNumObjectsFound, getObjectItem, getEnumValue
from UtilityRoutines import FindItem, ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError
from .Coils.CoilCoolingDX import CoilCoolingDX as CoilCoolingDX_t  # to avoid name clash
from EnergyPlus import HVAC  # For CoilType

from math import sum as math_sum  # for built-in sum? We'll use our own loops
import algorithm  # for find_if

# Enum ParentObject
enum ParentObject:
    Invalid = -1
    General
    Construction
    CoilDX
    CoilCoolingDX
    CoilCoolingDXSingleSpeed
    CoilHeatingFuel
    ChillerElectric
    DaylightingControls
    ShadingZoneDetailed
    Lights
    GeneratorPhotovoltaic
    Num

# Constant array of uppercase parent object names
var ParentObjectNamesUC: List[String] = [
    "GENERAL",
    "CONSTRUCTION",
    "COIL:DX",
    "COIL:COOLING:DX",
    "COIL:COOLING:DX:SINGLESPEED",
    "COIL:HEATING:FUEL",
    "CHILLER:ELECTRIC",
    "DAYLIGHTING:CONTROLS",
    "SHADING:ZONE:DETAILED",
    "LIGHTS",
    "GENERATOR:PHOTOVOLTAIC",
]

# Struct CostLineItemStruct
struct CostLineItemStruct:
    var LineName: String = String()  # object name (needed ?)
    var ParentObjType: ParentObject = ParentObject.Invalid # parent reference to IDD object type
    var ParentObjName: String = String()  # parent instance in IDF
    var ParentObjIDinList: Int = 1
    var PerSquareMeter: Float64 = 0.0  # cost per square meter
    var PerEach: Float64 = 0.0         # cost per each
    var PerKiloWattCap: Float64 = 0.0  # cost per kW of nominal capacity
    var PerKWCapPerCOP: Float64 = 0.0  # cost per kW of nominal capacity per COP
    var PerCubicMeter: Float64 = 0.0   # cost per cubic meter
    var PerCubMeterPerSec: Float64 = 0.0  # cost per cubic meter per second
    var PerUAinWattperDelK: Float64 = 0.0  # cost per (UA) in Watt/deltaK
    var LineNumber: Int = -1  # number of line item in detail list
    var Qty: Float64 = 0.0    # quantity in calculations (can be input)
    var Units: String = String()  # Reported units
    var ValuePer: Float64 = 0.0   # Cost used in final calculation
    var LineSubTotal: Float64 = 0.0  # line item total  Qty * ValuePer

# Struct CostAdjustmentStruct
struct CostAdjustmentStruct:
    var LineItemTot: Float64
    var MiscCostperSqMeter: Float64
    var DesignFeeFrac: Float64
    var ContractorFeeFrac: Float64
    var ContingencyFrac: Float64
    var BondCostFrac: Float64
    var CommissioningFrac: Float64
    var RegionalModifier: Float64
    var GrandTotal: Float64

    # Default constructor
    def __init__(inout self):
        self.LineItemTot = 0.0
        self.MiscCostperSqMeter = 0.0
        self.DesignFeeFrac = 0.0
        self.ContractorFeeFrac = 0.0
        self.ContingencyFrac = 0.0
        self.BondCostFrac = 0.0
        self.CommissioningFrac = 0.0
        self.RegionalModifier = 1.0
        self.GrandTotal = 0.0

    # Parameterized constructor
    def __init__(inout self,
                LineItemTot: Float64 = 0.0,
                MiscCostperSqMeter: Float64 = 0.0,
                DesignFeeFrac: Float64 = 0.0,
                ContractorFeeFrac: Float64 = 0.0,
                ContingencyFrac: Float64 = 0.0,
                BondCostFrac: Float64 = 0.0,
                CommissioningFrac: Float64 = 0.0,
                RegionalModifier: Float64 = 1.0,
                GrandTotal: Float64 = 0.0):
        self.LineItemTot = LineItemTot
        self.MiscCostperSqMeter = MiscCostperSqMeter
        self.DesignFeeFrac = DesignFeeFrac
        self.ContractorFeeFrac = ContractorFeeFrac
        self.ContingencyFrac = ContingencyFrac
        self.BondCostFrac = BondCostFrac
        self.CommissioningFrac = CommissioningFrac
        self.RegionalModifier = RegionalModifier
        self.GrandTotal = GrandTotal

# Struct monetaryUnitType
struct monetaryUnitType:
    var code: String = String()  # ISO code for currency such as USD or EUR
    var txt: String = String()   # text representation of the currency
    var html: String = String()  # representation for HTML file - contains unicode references

# Struct CostEstimateManagerData (inherits BaseGlobalStruct)
struct CostEstimateManagerData(BaseGlobalStruct):
    var GetCostInput: Bool = True
    var DoCostEstimate: Bool = False  # set to true if any cost estimating needed
    var selectedMonetaryUnit: Int = 0
    var CostLineItem: List[CostLineItemStruct] = List[CostLineItemStruct]()
    var CurntBldg: CostAdjustmentStruct = CostAdjustmentStruct(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
    var RefrncBldg: CostAdjustmentStruct = CostAdjustmentStruct(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
    var monetaryUnit: List[monetaryUnitType] = List[monetaryUnitType]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        # Re-initialize to default (placement new-like)
        self = CostEstimateManagerData()

# Functions in namespace CostEstimateManager (top-level)

def SimCostEstimate(state: EnergyPlusData):
    if state.dataCostEstimateManager.GetCostInput:
        GetCostEstimateInput(state)
        state.dataCostEstimateManager.GetCostInput = False
    if state.dataGlobal.KickOffSimulation:
        return
    if state.dataCostEstimateManager.DoCostEstimate:
        CalcCostEstimate(state)

def GetCostEstimateInput(state: EnergyPlusData):
    var Item: Int  # Item to be "gotten"
    var NumCostAdjust: Int
    var NumRefAdjust: Int
    var NumAlphas: Int  # Number of Alphas for each GetObjectItem call
    var NumNumbers: Int  # Number of Numbers for each GetObjectItem call
    var IOStatus: Int  # Used in GetObjectItem
    var ErrorsFound: Bool = False  # Set to true if errors in input, fatal at end of routine
    var NumLineItems: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ComponentCost:LineItem")
    if NumLineItems == 0:
        state.dataCostEstimateManager.DoCostEstimate = False
        return
    state.dataCostEstimateManager.DoCostEstimate = True
    # Check if CostLineItem list is empty; if yes, allocate with size NumLineItems
    if state.dataCostEstimateManager.CostLineItem.__len__() == 0:
        state.dataCostEstimateManager.CostLineItem = List[CostLineItemStruct](repeat=CostLineItemStruct(), count=NumLineItems)
    var cCurrentModuleObject: String = "ComponentCost:LineItem"
    for Item in range(1, NumLineItems+1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 cCurrentModuleObject,
                                                                 Item,
                                                                 state.dataIPShortCut.cAlphaArgs,
                                                                 NumAlphas,
                                                                 state.dataIPShortCut.rNumericArgs,
                                                                 NumNumbers,
                                                                 IOStatus)
        # 1-based to 0-based index
        state.dataCostEstimateManager.CostLineItem[Item-1].LineName = state.dataIPShortCut.cAlphaArgs[1-1]  # first alpha
        state.dataCostEstimateManager.CostLineItem[Item-1].ParentObjType = getEnumValue(ParentObjectNamesUC, state.dataIPShortCut.cAlphaArgs[3-1])
        state.dataCostEstimateManager.CostLineItem[Item-1].ParentObjName = state.dataIPShortCut.cAlphaArgs[4-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].PerEach = state.dataIPShortCut.rNumericArgs[1-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].PerSquareMeter = state.dataIPShortCut.rNumericArgs[2-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].PerKiloWattCap = state.dataIPShortCut.rNumericArgs[3-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].PerKWCapPerCOP = state.dataIPShortCut.rNumericArgs[4-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].PerCubicMeter = state.dataIPShortCut.rNumericArgs[5-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].PerCubMeterPerSec = state.dataIPShortCut.rNumericArgs[6-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].PerUAinWattperDelK = state.dataIPShortCut.rNumericArgs[7-1]
        state.dataCostEstimateManager.CostLineItem[Item-1].Qty = state.dataIPShortCut.rNumericArgs[8-1]
    cCurrentModuleObject = "ComponentCost:Adjustments"
    NumCostAdjust = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if NumCostAdjust == 1:
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 cCurrentModuleObject,
                                                                 1,
                                                                 state.dataIPShortCut.cAlphaArgs,
                                                                 NumAlphas,
                                                                 state.dataIPShortCut.rNumericArgs,
                                                                 NumNumbers,
                                                                 IOStatus)
        state.dataCostEstimateManager.CurntBldg.MiscCostperSqMeter = state.dataIPShortCut.rNumericArgs[1-1]
        state.dataCostEstimateManager.CurntBldg.DesignFeeFrac = state.dataIPShortCut.rNumericArgs[2-1]
        state.dataCostEstimateManager.CurntBldg.ContractorFeeFrac = state.dataIPShortCut.rNumericArgs[3-1]
        state.dataCostEstimateManager.CurntBldg.ContingencyFrac = state.dataIPShortCut.rNumericArgs[4-1]
        state.dataCostEstimateManager.CurntBldg.BondCostFrac = state.dataIPShortCut.rNumericArgs[5-1]
        state.dataCostEstimateManager.CurntBldg.CommissioningFrac = state.dataIPShortCut.rNumericArgs[6-1]
        state.dataCostEstimateManager.CurntBldg.RegionalModifier = state.dataIPShortCut.rNumericArgs[7-1]
    elif NumCostAdjust > 1:
        ShowSevereError(state, f"{cCurrentModuleObject}: Only one instance of this object is allowed.")
        ErrorsFound = True
    cCurrentModuleObject = "ComponentCost:Reference"
    NumRefAdjust = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if NumRefAdjust == 1:
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 cCurrentModuleObject,
                                                                 1,
                                                                 state.dataIPShortCut.cAlphaArgs,
                                                                 NumAlphas,
                                                                 state.dataIPShortCut.rNumericArgs,
                                                                 NumNumbers,
                                                                 IOStatus)
        state.dataCostEstimateManager.RefrncBldg.LineItemTot = state.dataIPShortCut.rNumericArgs[1-1]
        state.dataCostEstimateManager.RefrncBldg.MiscCostperSqMeter = state.dataIPShortCut.rNumericArgs[2-1]
        state.dataCostEstimateManager.RefrncBldg.DesignFeeFrac = state.dataIPShortCut.rNumericArgs[3-1]
        state.dataCostEstimateManager.RefrncBldg.ContractorFeeFrac = state.dataIPShortCut.rNumericArgs[4-1]
        state.dataCostEstimateManager.RefrncBldg.ContingencyFrac = state.dataIPShortCut.rNumericArgs[5-1]
        state.dataCostEstimateManager.RefrncBldg.BondCostFrac = state.dataIPShortCut.rNumericArgs[6-1]
        state.dataCostEstimateManager.RefrncBldg.CommissioningFrac = state.dataIPShortCut.rNumericArgs[7-1]
        state.dataCostEstimateManager.RefrncBldg.RegionalModifier = state.dataIPShortCut.rNumericArgs[8-1]
    elif NumRefAdjust > 1:
        ShowSevereError(state, f"{cCurrentModuleObject} : Only one instance of this object is allowed.")
        ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing cost estimate input")
    CheckCostEstimateInput(state, ErrorsFound)
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing cost estimate input")

def CheckCostEstimateInput(state: EnergyPlusData, inout ErrorsFound: Bool):
    var Item: Int  # do-loop counter for line items
    var ThisConstructID: Int  # hold result of FindItem searching for Construct name
    var ThisSurfID: Int  # hold result from findItem
    var ThisZoneID: Int  # hold result from findItem
    var ThisConstructStr: String
    var Zone = state.dataHeatBal.Zone
    var thisCoil: Int  # index of named coil in its derived type
    var thisChil: Int
    var thisPV: Int
    for Item in range(1, state.dataCostEstimateManager.CostLineItem.__len__()+1):
        state.dataCostEstimateManager.CostLineItem[Item-1].LineNumber = Item
        var itemObj = state.dataCostEstimateManager.CostLineItem[Item-1]
        switch itemObj.ParentObjType:
            case ParentObject.General:

            case ParentObject.Construction:
                if itemObj.PerSquareMeter == 0:
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\" Construction object needs non-zero construction costs per square meter")
                    ErrorsFound = True
                ThisConstructStr = itemObj.ParentObjName
                ThisConstructID = FindItem(ThisConstructStr, state.dataConstruction.Construct)
                if ThisConstructID == 0:
                    ShowWarningError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\" Construction=\"{itemObj.ParentObjName}\", no surfaces have the Construction specified")
                    ShowContinueError(state, "No costs will be calculated for this Construction.")
                    continue
            case ParentObject.CoilDX:
                fallthrough
            case ParentObject.CoilCoolingDX:
                fallthrough
            case ParentObject.CoilCoolingDXSingleSpeed:
                # Too many pricing checks
                if (itemObj.PerKiloWattCap > 0.0) and (itemObj.PerEach > 0.0):
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", {ParentObjectNamesUC[itemObj.ParentObjType.__int__()]}, too many pricing methods specified")
                    ErrorsFound = True
                if (itemObj.PerKiloWattCap > 0.0) and (itemObj.PerKWCapPerCOP > 0.0):
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", {ParentObjectNamesUC[itemObj.ParentObjType.__int__()]}, too many pricing methods specified")
                    ErrorsFound = True
                if (itemObj.PerEach > 0.0) and (itemObj.PerKWCapPerCOP > 0.0):
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", {ParentObjectNamesUC[itemObj.ParentObjType.__int__()]}, too many pricing methods specified")
                    ErrorsFound = True
                if itemObj.ParentObjName == "*":
                    pass # wildcard
                elif itemObj.ParentObjName == "":
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", {ParentObjectNamesUC[itemObj.ParentObjType.__int__()]}, too many pricing methods specified")
                    ErrorsFound = True
                else:
                    var coilFound: Bool = False
                    var parentObjName = itemObj.ParentObjName
                    if (itemObj.ParentObjType == ParentObject.CoilDX) or (itemObj.ParentObjType == ParentObject.CoilCoolingDXSingleSpeed):
                        if FindItem(parentObjName, state.dataDXCoils.DXCoil) > 0:
                            coilFound = True
                    elif itemObj.ParentObjType == ParentObject.CoilCoolingDX:
                        if CoilCoolingDX_t.factory(state, parentObjName) != -1:
                            coilFound = True
                    if not coilFound:
                        ShowWarningError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", {ParentObjectNamesUC[itemObj.ParentObjType.__int__()]}, invalid coil specified")
                        ShowContinueError(state, f"Coil Specified=\"{itemObj.ParentObjName}\", calculations will not be completed for this item.")
            case ParentObject.CoilHeatingFuel:
                if (itemObj.PerKiloWattCap > 0.0) and (itemObj.PerEach > 0.0):
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Coil:Heating:Fuel, too many pricing methods specified")
                    ErrorsFound = True
                if (itemObj.PerKiloWattCap > 0.0) and (itemObj.PerKWCapPerCOP > 0.0):
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Coil:Heating:Fuel, too many pricing methods specified")
                    ErrorsFound = True
                if (itemObj.PerEach > 0.0) and (itemObj.PerKWCapPerCOP > 0.0):
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Coil:Heating:Fuel, too many pricing methods specified")
                    ErrorsFound = True
                if itemObj.ParentObjName == "*":

                elif itemObj.ParentObjName == "":
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Coil:Heating:Fuel, need to specify a Reference Object Name")
                    ErrorsFound = True
                else:
                    thisCoil = FindItem(itemObj.ParentObjName, state.dataHeatingCoils.HeatingCoil)
                    if thisCoil == 0:
                        ShowWarningError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Coil:Heating:Fuel, invalid coil specified")
                        ShowContinueError(state, f"Coil Specified=\"{itemObj.ParentObjName}\", calculations will not be completed for this item.")
            case ParentObject.ChillerElectric:
                if itemObj.ParentObjName == "":
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Chiller:Electric, need to specify a Reference Object Name")
                    ErrorsFound = True
                thisChil = 0
                var chillNum: Int = 0
                for ch in state.dataPlantChillers.ElectricChiller:
                    chillNum += 1
                    if itemObj.ParentObjName == ch.Name:
                        thisChil = chillNum
                if thisChil == 0:
                    ShowWarningError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Chiller:Electric, invalid chiller specified.")
                    ShowContinueError(state, f"Chiller Specified=\"{itemObj.ParentObjName}\", calculations will not be completed for this item.")
            case ParentObject.DaylightingControls:
                if itemObj.ParentObjName == "*":

                elif itemObj.ParentObjName == "":
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Daylighting:Controls, need to specify a Reference Object Name")
                    ErrorsFound = True
                else:
                    ThisZoneID = FindItem(itemObj.ParentObjName, Zone)
                    if ThisZoneID > 0:
                        state.dataCostEstimateManager.CostLineItem[Item-1].Qty = state.dataDayltg.ZoneDaylight[ThisZoneID-1].totRefPts
                    else:
                        ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Daylighting:Controls, need to specify a valid zone name")
                        ShowContinueError(state, f"Zone specified=\"{itemObj.ParentObjName}\".")
                        ErrorsFound = True
            case ParentObject.ShadingZoneDetailed:
                if not itemObj.ParentObjName == "":
                    ThisSurfID = FindItem(itemObj.ParentObjName, state.dataSurface.Surface)
                    if ThisSurfID > 0:
                        ThisZoneID = FindItem(state.dataSurface.Surface[ThisSurfID-1].ZoneName, Zone)
                        if ThisZoneID == 0:
                            ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Shading:Zone:Detailed, need to specify a valid zone name")
                            ShowContinueError(state, f"Zone specified=\"{state.dataSurface.Surface[ThisSurfID-1].ZoneName}\".")
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Shading:Zone:Detailed, need to specify a valid surface name")
                        ShowContinueError(state, f"Surface specified=\"{itemObj.ParentObjName}\".")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Shading:Zone:Detailed, specify a Reference Object Name")
                    ErrorsFound = True
            case ParentObject.Lights:
                if (itemObj.PerKiloWattCap > 0.0) and (itemObj.PerEach > 0.0):
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Lights, too many pricing methods specified")
                    ErrorsFound = True
                if itemObj.PerKiloWattCap != 0.0:
                    if not itemObj.ParentObjName == "":
                        ThisZoneID = FindItem(itemObj.ParentObjName, Zone)
                        if ThisZoneID == 0:
                            ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Lights, need to specify a valid zone name")
                            ShowContinueError(state, f"Zone specified=\"{itemObj.ParentObjName}\".")
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Lights, need to specify a Reference Object Name")
                        ErrorsFound = True
            case ParentObject.GeneratorPhotovoltaic:
                if itemObj.PerKiloWattCap != 0.0:
                    if not itemObj.ParentObjName == "":
                        thisPV = FindItem(itemObj.ParentObjName, state.dataPhotovoltaic.PVarray)
                        if thisPV > 0:
                            if state.dataPhotovoltaic.PVarray[thisPV-1].PVModelType != PVModelSimple:
                                ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Generator:Photovoltaic, only available for model type PhotovoltaicPerformance:Simple")
                                ErrorsFound = True
                        else:
                            ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Generator:Photovoltaic, need to specify a valid PV array")
                            ShowContinueError(state, f"PV Array specified=\"{itemObj.ParentObjName}\".")
                            ErrorsFound = True
                    else:
                        ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Generator:Photovoltaic, need to specify a Reference Object Name")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", Generator:Photovoltaic, need to specify a per-kilowatt cost ")
                    ErrorsFound = True
            case _:
                ShowWarningError(state, f"ComponentCost:LineItem: \"{itemObj.LineName}\", invalid cost item -- not included in cost estimate.")
                ShowContinueError(state, f"... invalid object type={ParentObjectNamesUC[itemObj.ParentObjType.__int__()]}")
        # end switch

def CalcCostEstimate(state: EnergyPlusData):
    var Item: Int  # do-loop counter for line items
    var ThisConstructID: Int  # hold result of FindItem searching for Construct name
    var ThisSurfID: Int  # hold result from findItem
    var ThisZoneID: Int  # hold result from findItem
    var Zone = state.dataHeatBal.Zone
    var ThisConstructStr: String
    # We'll emulate Array1D_bool and Array1D<Real64> using lists
    var uniqueSurfMask: List[Bool] = List[Bool]()
    var SurfMultipleARR: List[Float64] = List[Float64]()
    var surf: Int  # do-loop counter for checking for surfaces for uniqueness
    var thisCoil: Int  # index of named coil in its derived type
    var WildcardObjNames: Bool
    var thisChil: Int
    var thisPV: Int
    var Multipliers: Float64
    for Item in range(1, state.dataCostEstimateManager.CostLineItem.__len__()+1):
        state.dataCostEstimateManager.CostLineItem[Item-1].LineNumber = Item
        var itemObj = state.dataCostEstimateManager.CostLineItem[Item-1]
        switch itemObj.ParentObjType:
            case ParentObject.General:
                itemObj.Units = "Ea."
                itemObj.ValuePer = itemObj.PerEach
                itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.Construction:
                ThisConstructStr = itemObj.ParentObjName
                ThisConstructID = FindItem(ThisConstructStr, state.dataConstruction.Construct)
                # Initialize uniqueSurfMask and SurfMultipleARR
                uniqueSurfMask = List[Bool](repeat=True, count=state.dataSurface.TotSurfaces)
                SurfMultipleARR = List[Float64](repeat=1.0, count=state.dataSurface.TotSurfaces)
                for surf in range(1, state.dataSurface.TotSurfaces+1):
                    if state.dataSurface.Surface[surf-1].ExtBoundCond >= 1:
                        if state.dataSurface.Surface[surf-1].ExtBoundCond < surf:
                            uniqueSurfMask[surf-1] = False
                    if state.dataSurface.Surface[surf-1].Construction == 0:
                        uniqueSurfMask[surf-1] = False
                    if state.dataSurface.Surface[surf-1].Zone > 0:
                        SurfMultipleARR[surf-1] = Zone[state.dataSurface.Surface[surf-1].Zone-1].Multiplier * Zone[state.dataSurface.Surface[surf-1].Zone-1].ListMultiplier
                var Qty: Float64 = 0.0
                for i in range(1, state.dataSurface.TotSurfaces+1):
                    var s = state.dataSurface.Surface[i-1]
                    if uniqueSurfMask[i-1] and (s.Construction == ThisConstructID):
                        Qty += s.Area * SurfMultipleARR[i-1]
                itemObj.Qty = Qty
                itemObj.Units = "m2"
                itemObj.ValuePer = itemObj.PerSquareMeter
                itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                # deallocate simulated by clearing lists
                uniqueSurfMask = List[Bool]()
                SurfMultipleARR = List[Float64]()
            case ParentObject.CoilDX:
                fallthrough
            case ParentObject.CoilCoolingDXSingleSpeed:
                WildcardObjNames = False
                thisCoil = 0
                if itemObj.ParentObjName == "*":
                    WildcardObjNames = True
                elif not itemObj.ParentObjName == "":
                    thisCoil = FindItem(itemObj.ParentObjName, state.dataDXCoils.DXCoil)
                if itemObj.PerKiloWattCap > 0.0:
                    if WildcardObjNames:
                        var Qty: Float64 = 0.0
                        for e in state.dataDXCoils.DXCoil:
                            Qty += e.RatedTotCap[1-1]  # first element (1-based)
                        itemObj.Qty = Qty / 1000.0
                        itemObj.Units = "kW (tot cool cap.)"
                        itemObj.ValuePer = itemObj.PerKiloWattCap
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    if thisCoil > 0:
                        itemObj.Qty = state.dataDXCoils.DXCoil[thisCoil-1].RatedTotCap[1-1] / 1000.0
                        itemObj.Units = "kW (tot cool cap.)"
                        itemObj.ValuePer = itemObj.PerKiloWattCap
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                if itemObj.PerEach > 0.0:
                    if WildcardObjNames:
                        itemObj.Qty = Float64(state.dataDXCoils.NumDXCoils)
                    if thisCoil > 0:
                        itemObj.Qty = 1.0
                    itemObj.ValuePer = itemObj.PerEach
                    itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    itemObj.Units = "Ea."
                if itemObj.PerKWCapPerCOP > 0.0:
                    if WildcardObjNames:
                        var Qty: Float64 = 0.0
                        for e in state.dataDXCoils.DXCoil:
                            var maxSpeed = e.RatedCOP.__len__()
                            Qty += e.RatedCOP[maxSpeed-1] * e.RatedTotCap[maxSpeed-1]
                        itemObj.Qty = Qty / 1000.0
                        itemObj.Units = "kW*COP (total, rated) "
                        itemObj.ValuePer = itemObj.PerKWCapPerCOP
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    if thisCoil > 0:
                        var maxSpeed = state.dataDXCoils.DXCoil[thisCoil-1].RatedCOP.__len__()
                        itemObj.Qty = state.dataDXCoils.DXCoil[thisCoil-1].RatedCOP[maxSpeed-1] * state.dataDXCoils.DXCoil[thisCoil-1].RatedTotCap[maxSpeed-1] / 1000.0
                        itemObj.Units = "kW*COP (total, rated) "
                        itemObj.ValuePer = itemObj.PerKWCapPerCOP
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.CoilCoolingDX:
                WildcardObjNames = False
                var parentObjName = itemObj.ParentObjName
                var coilFound: Bool = False
                if parentObjName == "*":
                    WildcardObjNames = True
                elif not itemObj.ParentObjName == "":
                    var v = state.dataCoilCoolingDX.coilCoolingDXs
                    # Use find_if
                    var it = algorithm.find_if(v, def (coil: CoilCoolingDX_t) -> Bool:
                        return coil.name == parentObjName
                    )
                    if it != v.__end__():
                        thisCoil = algorithm.distance(v.__begin__(), it)
                        coilFound = True
                if itemObj.PerKiloWattCap > 0.0:
                    if WildcardObjNames:
                        var Qty: Float64 = 0.0
                        for e in state.dataCoilCoolingDX.coilCoolingDXs:
                            Qty += e.performance.ratedGrossTotalCap()
                        itemObj.Qty = Qty / 1000.0
                        itemObj.Units = "kW (tot cool cap.)"
                        itemObj.ValuePer = itemObj.PerKiloWattCap
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    if coilFound:
                        itemObj.Qty = state.dataCoilCoolingDX.coilCoolingDXs[thisCoil].performance.ratedGrossTotalCap() / 1000.0
                        itemObj.Units = "kW (tot cool cap.)"
                        itemObj.ValuePer = itemObj.PerKiloWattCap
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                if itemObj.PerEach > 0.0:
                    if WildcardObjNames:
                        itemObj.Qty = Float64(state.dataCoilCoolingDX.coilCoolingDXs.__len__())
                    if coilFound:
                        itemObj.Qty = 1.0
                    itemObj.ValuePer = itemObj.PerEach
                    itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    itemObj.Units = "Ea."
                if itemObj.PerKWCapPerCOP > 0.0:
                    if WildcardObjNames:
                        var Qty: Float64 = 0.0
                        for e in state.dataCoilCoolingDX.coilCoolingDXs:
                            var COP = e.performance.grossRatedCoolingCOPAtMaxSpeed(state)
                            Qty += COP * e.performance.ratedGrossTotalCap()
                        itemObj.Qty = Qty / 1000.0
                        itemObj.Units = "kW*COP (total, rated) "
                        itemObj.ValuePer = itemObj.PerKWCapPerCOP
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    if coilFound:
                        var COP = state.dataCoilCoolingDX.coilCoolingDXs[thisCoil].performance.grossRatedCoolingCOPAtMaxSpeed(state)
                        itemObj.Qty = COP * state.dataCoilCoolingDX.coilCoolingDXs[thisCoil].performance.ratedGrossTotalCap() / 1000.0
                        itemObj.Units = "kW*COP (total, rated) "
                        itemObj.ValuePer = itemObj.PerKWCapPerCOP
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.CoilHeatingFuel:
                WildcardObjNames = False
                thisCoil = 0
                if itemObj.ParentObjName == "*":
                    WildcardObjNames = True
                elif not itemObj.ParentObjName == "":
                    thisCoil = FindItem(itemObj.ParentObjName, state.dataHeatingCoils.HeatingCoil)
                if itemObj.PerKiloWattCap > 0.0:
                    if WildcardObjNames:
                        var Qty: Float64 = 0.0
                        for e in state.dataHeatingCoils.HeatingCoil:
                            if e.coilType == HVAC.CoilType.HeatingDXSingleSpeed:
                                Qty += e.NominalCapacity
                        itemObj.Qty = Qty / 1000.0
                        itemObj.Units = "kW (tot heat cap.)"
                        itemObj.ValuePer = itemObj.PerKiloWattCap
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    if thisCoil > 0:
                        itemObj.Qty = state.dataHeatingCoils.HeatingCoil[thisCoil-1].NominalCapacity / 1000.0
                        itemObj.Units = "kW (tot heat cap.)"
                        itemObj.ValuePer = itemObj.PerKiloWattCap
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                if itemObj.PerEach > 0.0:
                    if WildcardObjNames:
                        itemObj.Qty = Float64(state.dataHeatingCoils.NumHeatingCoils)
                    if thisCoil > 0:
                        itemObj.Qty = 1.0
                    itemObj.ValuePer = itemObj.PerEach
                    itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    itemObj.Units = "Ea."
                if itemObj.PerKWCapPerCOP > 0.0:
                    if WildcardObjNames:
                        var Qty: Float64 = 0.0
                        for e in state.dataHeatingCoils.HeatingCoil:
                            if e.coilType == HVAC.CoilType.HeatingDXSingleSpeed:
                                Qty += e.Efficiency * e.NominalCapacity
                        itemObj.Qty = Qty / 1000.0
                        itemObj.Units = "kW*Eff (total, rated) "
                        itemObj.ValuePer = itemObj.PerKWCapPerCOP
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                    if thisCoil > 0:
                        itemObj.Qty = state.dataHeatingCoils.HeatingCoil[thisCoil-1].Efficiency * state.dataHeatingCoils.HeatingCoil[thisCoil-1].NominalCapacity / 1000.0
                        itemObj.Units = "kW*Eff (total, rated) "
                        itemObj.ValuePer = itemObj.PerKWCapPerCOP
                        itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.ChillerElectric:
                thisChil = 0
                var chillNum: Int = 0
                for ch in state.dataPlantChillers.ElectricChiller:
                    chillNum += 1
                    if itemObj.ParentObjName == ch.Name:
                        thisChil = chillNum
                if (thisChil > 0) and (itemObj.PerKiloWattCap > 0.0):
                    itemObj.Qty = state.dataPlantChillers.ElectricChiller[thisChil-1].NomCap / 1000.0
                    itemObj.Units = "kW (tot cool cap.)"
                    itemObj.ValuePer = itemObj.PerKiloWattCap
                    itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                if (thisChil > 0) and (itemObj.PerKWCapPerCOP > 0.0):
                    itemObj.Qty = state.dataPlantChillers.ElectricChiller[thisChil-1].COP * state.dataPlantChillers.ElectricChiller[thisChil-1].NomCap / 1000.0
                    itemObj.Units = "kW*COP (total, rated) "
                    itemObj.ValuePer = itemObj.PerKWCapPerCOP
                    itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                if (thisChil > 0) and (itemObj.PerEach > 0.0):
                    itemObj.Qty = 1.0
                    itemObj.Units = "Ea."
                    itemObj.ValuePer = itemObj.PerEach
                    itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.DaylightingControls:
                if itemObj.ParentObjName == "*":
                    # sum totRefPts over all ZoneDaylight
                    var total: Float64 = 0.0
                    for zd in state.dataDayltg.ZoneDaylight:
                        total += zd.totRefPts
                    itemObj.Qty = total
                elif not itemObj.ParentObjName == "":
                    ThisZoneID = FindItem(itemObj.ParentObjName, Zone)
                    if ThisZoneID > 0:
                        itemObj.Qty = state.dataDayltg.ZoneDaylight[ThisZoneID-1].totRefPts
                itemObj.Units = "Ea."
                itemObj.ValuePer = itemObj.PerEach
                itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.ShadingZoneDetailed:
                if not itemObj.ParentObjName == "":
                    ThisSurfID = FindItem(itemObj.ParentObjName, state.dataSurface.Surface)
                    if ThisSurfID > 0:
                        ThisZoneID = FindItem(state.dataSurface.Surface[ThisSurfID-1].ZoneName, Zone)
                        if ThisZoneID > 0:
                            itemObj.Qty = state.dataSurface.Surface[ThisSurfID-1].Area * Zone[ThisZoneID-1].Multiplier * Zone[ThisZoneID-1].ListMultiplier
                            itemObj.Units = "m2"
                            itemObj.ValuePer = itemObj.PerSquareMeter
                            itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.Lights:
                if itemObj.PerEach != 0.0:
                    itemObj.Qty = 1.0
                    itemObj.Units = "Ea."
                    itemObj.ValuePer = itemObj.PerEach
                    itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
                if itemObj.PerKiloWattCap != 0.0:
                    if not itemObj.ParentObjName == "":
                        ThisZoneID = FindItem(itemObj.ParentObjName, Zone)
                        if ThisZoneID > 0:
                            var Qty: Float64 = 0.0
                            for e in state.dataHeatBal.Lights:
                                if e.ZonePtr == ThisZoneID:
                                    Qty += e.DesignLevel
                            itemObj.Qty = (Zone[ThisZoneID-1].Multiplier * Zone[ThisZoneID-1].ListMultiplier / 1000.0) * Qty
                            itemObj.Units = "kW"
                            itemObj.ValuePer = itemObj.PerKiloWattCap
                            itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case ParentObject.GeneratorPhotovoltaic:
                if itemObj.PerKiloWattCap != 0.0:
                    if not itemObj.ParentObjName == "":
                        thisPV = FindItem(itemObj.ParentObjName, state.dataPhotovoltaic.PVarray)
                        if thisPV > 0:
                            ThisZoneID = FindItem(state.dataSurface.Surface[state.dataPhotovoltaic.PVarray[thisPV-1].SurfacePtr-1].ZoneName, Zone)
                            if ThisZoneID == 0:
                                Multipliers = 1.0
                            else:
                                Multipliers = Zone[ThisZoneID-1].Multiplier * Zone[ThisZoneID-1].ListMultiplier
                            if state.dataPhotovoltaic.PVarray[thisPV-1].PVModelType == PVModelSimple:
                                itemObj.Qty = 1000.0 * state.dataPhotovoltaic.PVarray[thisPV-1].SimplePVModule.AreaCol * state.dataPhotovoltaic.PVarray[thisPV-1].SimplePVModule.PVEfficiency * Multipliers / 1000.0
                            itemObj.Units = "kW (rated)"
                            itemObj.ValuePer = itemObj.PerKiloWattCap
                            itemObj.LineSubTotal = itemObj.Qty * itemObj.ValuePer
            case _:

        # end switch
    # Compute CurntBldg.LineItemTot as sum of LineSubTotal
    var totalLineSubTotal: Float64 = 0.0
    for cl in state.dataCostEstimateManager.CostLineItem:
        totalLineSubTotal += cl.LineSubTotal
    state.dataCostEstimateManager.CurntBldg.LineItemTot = totalLineSubTotal
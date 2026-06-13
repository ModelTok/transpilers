from math import sum as math_sum

@value
struct ParentObject:
    var value: Int32
    
    alias Invalid = -1
    alias General = 0
    alias Construction = 1
    alias CoilDX = 2
    alias CoilCoolingDX = 3
    alias CoilCoolingDXSingleSpeed = 4
    alias CoilHeatingFuel = 5
    alias ChillerElectric = 6
    alias DaylightingControls = 7
    alias ShadingZoneDetailed = 8
    alias Lights = 9
    alias GeneratorPhotovoltaic = 10
    alias Num = 11

fn get_parent_object_names_uc() -> List[String]:
    var names = List[String]()
    names.append("GENERAL")
    names.append("CONSTRUCTION")
    names.append("COIL:DX")
    names.append("COIL:COOLING:DX")
    names.append("COIL:COOLING:DX:SINGLESPEED")
    names.append("COIL:HEATING:FUEL")
    names.append("CHILLER:ELECTRIC")
    names.append("DAYLIGHTING:CONTROLS")
    names.append("SHADING:ZONE:DETAILED")
    names.append("LIGHTS")
    names.append("GENERATOR:PHOTOVOLTAIC")
    return names

@value
struct CostLineItemStruct:
    var LineName: String
    var ParentObjType: Int32
    var ParentObjName: String
    var ParentObjIDinList: Int32
    var PerSquareMeter: Float64
    var PerEach: Float64
    var PerKiloWattCap: Float64
    var PerKWCapPerCOP: Float64
    var PerCubicMeter: Float64
    var PerCubMeterPerSec: Float64
    var PerUAinWattperDelK: Float64
    var LineNumber: Int32
    var Qty: Float64
    var Units: String
    var ValuePer: Float64
    var LineSubTotal: Float64
    
    fn __init__(inout self):
        self.LineName = ""
        self.ParentObjType = -1
        self.ParentObjName = ""
        self.ParentObjIDinList = 1
        self.PerSquareMeter = 0.0
        self.PerEach = 0.0
        self.PerKiloWattCap = 0.0
        self.PerKWCapPerCOP = 0.0
        self.PerCubicMeter = 0.0
        self.PerCubMeterPerSec = 0.0
        self.PerUAinWattperDelK = 0.0
        self.LineNumber = -1
        self.Qty = 0.0
        self.Units = ""
        self.ValuePer = 0.0
        self.LineSubTotal = 0.0

@value
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
    
    fn __init__(inout self):
        self.LineItemTot = 0.0
        self.MiscCostperSqMeter = 0.0
        self.DesignFeeFrac = 0.0
        self.ContractorFeeFrac = 0.0
        self.ContingencyFrac = 0.0
        self.BondCostFrac = 0.0
        self.CommissioningFrac = 0.0
        self.RegionalModifier = 1.0
        self.GrandTotal = 0.0
    
    fn __init__(inout self, 
                 LineItemTot: Float64,
                 MiscCostperSqMeter: Float64,
                 DesignFeeFrac: Float64,
                 ContractorFeeFrac: Float64,
                 ContingencyFrac: Float64,
                 BondCostFrac: Float64,
                 CommissioningFrac: Float64,
                 RegionalModifier: Float64,
                 GrandTotal: Float64):
        self.LineItemTot = LineItemTot
        self.MiscCostperSqMeter = MiscCostperSqMeter
        self.DesignFeeFrac = DesignFeeFrac
        self.ContractorFeeFrac = ContractorFeeFrac
        self.ContingencyFrac = ContingencyFrac
        self.BondCostFrac = BondCostFrac
        self.CommissioningFrac = CommissioningFrac
        self.RegionalModifier = RegionalModifier
        self.GrandTotal = GrandTotal

@value
struct MonetaryUnitType:
    var code: String
    var txt: String
    var html: String
    
    fn __init__(inout self):
        self.code = ""
        self.txt = ""
        self.html = ""

@value
struct CostEstimateManagerData:
    var GetCostInput: Bool
    var DoCostEstimate: Bool
    var selectedMonetaryUnit: Int32
    var CostLineItem: List[CostLineItemStruct]
    var CurntBldg: CostAdjustmentStruct
    var RefrncBldg: CostAdjustmentStruct
    var monetaryUnit: List[MonetaryUnitType]
    
    fn __init__(inout self):
        self.GetCostInput = True
        self.DoCostEstimate = False
        self.selectedMonetaryUnit = 0
        self.CostLineItem = List[CostLineItemStruct]()
        self.CurntBldg = CostAdjustmentStruct(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        self.RefrncBldg = CostAdjustmentStruct(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
        self.monetaryUnit = List[MonetaryUnitType]()

fn sim_cost_estimate(inout state: Any) -> None:
    if state.dataCostEstimateManager.GetCostInput:
        get_cost_estimate_input(state)
        state.dataCostEstimateManager.GetCostInput = False
    
    if state.dataGlobal.KickOffSimulation:
        return
    
    if state.dataCostEstimateManager.DoCostEstimate:
        calc_cost_estimate(state)

fn get_cost_estimate_input(inout state: Any) -> None:
    var NumLineItems = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ComponentCost:LineItem")
    
    if NumLineItems == 0:
        state.dataCostEstimateManager.DoCostEstimate = False
        return
    
    state.dataCostEstimateManager.DoCostEstimate = True
    
    if state.dataCostEstimateManager.CostLineItem.size() == 0:
        for _ in range(NumLineItems):
            state.dataCostEstimateManager.CostLineItem.append(CostLineItemStruct())
    
    var cCurrentModuleObject = "ComponentCost:LineItem"
    
    for Item in range(1, NumLineItems + 1):
        var NumAlphas: Int32 = 0
        var NumNumbers: Int32 = 0
        var IOStatus: Int32 = 0
        
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            Item,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNumbers,
            IOStatus
        )
        
        var idx = Item - 1
        state.dataCostEstimateManager.CostLineItem[idx].LineName = state.dataIPShortCut.cAlphaArgs[0]
        state.dataCostEstimateManager.CostLineItem[idx].ParentObjType = get_enum_value(state.dataIPShortCut.cAlphaArgs[2])
        state.dataCostEstimateManager.CostLineItem[idx].ParentObjName = state.dataIPShortCut.cAlphaArgs[3]
        state.dataCostEstimateManager.CostLineItem[idx].PerEach = state.dataIPShortCut.rNumericArgs[0]
        state.dataCostEstimateManager.CostLineItem[idx].PerSquareMeter = state.dataIPShortCut.rNumericArgs[1]
        state.dataCostEstimateManager.CostLineItem[idx].PerKiloWattCap = state.dataIPShortCut.rNumericArgs[2]
        state.dataCostEstimateManager.CostLineItem[idx].PerKWCapPerCOP = state.dataIPShortCut.rNumericArgs[3]
        state.dataCostEstimateManager.CostLineItem[idx].PerCubicMeter = state.dataIPShortCut.rNumericArgs[4]
        state.dataCostEstimateManager.CostLineItem[idx].PerCubMeterPerSec = state.dataIPShortCut.rNumericArgs[5]
        state.dataCostEstimateManager.CostLineItem[idx].PerUAinWattperDelK = state.dataIPShortCut.rNumericArgs[6]
        state.dataCostEstimateManager.CostLineItem[idx].Qty = state.dataIPShortCut.rNumericArgs[7]
    
    cCurrentModuleObject = "ComponentCost:Adjustments"
    var NumCostAdjust = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    var ErrorsFound: Bool = False
    
    if NumCostAdjust == 1:
        var NumAlphas: Int32 = 0
        var NumNumbers: Int32 = 0
        var IOStatus: Int32 = 0
        
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            1,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNumbers,
            IOStatus
        )
        
        state.dataCostEstimateManager.CurntBldg.MiscCostperSqMeter = state.dataIPShortCut.rNumericArgs[0]
        state.dataCostEstimateManager.CurntBldg.DesignFeeFrac = state.dataIPShortCut.rNumericArgs[1]
        state.dataCostEstimateManager.CurntBldg.ContractorFeeFrac = state.dataIPShortCut.rNumericArgs[2]
        state.dataCostEstimateManager.CurntBldg.ContingencyFrac = state.dataIPShortCut.rNumericArgs[3]
        state.dataCostEstimateManager.CurntBldg.BondCostFrac = state.dataIPShortCut.rNumericArgs[4]
        state.dataCostEstimateManager.CurntBldg.CommissioningFrac = state.dataIPShortCut.rNumericArgs[5]
        state.dataCostEstimateManager.CurntBldg.RegionalModifier = state.dataIPShortCut.rNumericArgs[6]
    elif NumCostAdjust > 1:
        ShowSevereError(state, cCurrentModuleObject + ": Only one instance of this object is allowed.")
        ErrorsFound = True
    
    cCurrentModuleObject = "ComponentCost:Reference"
    var NumRefAdjust = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    
    if NumRefAdjust == 1:
        var NumAlphas: Int32 = 0
        var NumNumbers: Int32 = 0
        var IOStatus: Int32 = 0
        
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            1,
            state.dataIPShortCut.cAlphaArgs,
            NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            NumNumbers,
            IOStatus
        )
        
        state.dataCostEstimateManager.RefrncBldg.LineItemTot = state.dataIPShortCut.rNumericArgs[0]
        state.dataCostEstimateManager.RefrncBldg.MiscCostperSqMeter = state.dataIPShortCut.rNumericArgs[1]
        state.dataCostEstimateManager.RefrncBldg.DesignFeeFrac = state.dataIPShortCut.rNumericArgs[2]
        state.dataCostEstimateManager.RefrncBldg.ContractorFeeFrac = state.dataIPShortCut.rNumericArgs[3]
        state.dataCostEstimateManager.RefrncBldg.ContingencyFrac = state.dataIPShortCut.rNumericArgs[4]
        state.dataCostEstimateManager.RefrncBldg.BondCostFrac = state.dataIPShortCut.rNumericArgs[5]
        state.dataCostEstimateManager.RefrncBldg.CommissioningFrac = state.dataIPShortCut.rNumericArgs[6]
        state.dataCostEstimateManager.RefrncBldg.RegionalModifier = state.dataIPShortCut.rNumericArgs[7]
    elif NumRefAdjust > 1:
        ShowSevereError(state, cCurrentModuleObject + " : Only one instance of this object is allowed.")
        ErrorsFound = True
    
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing cost estimate input")
    
    check_cost_estimate_input(state, ErrorsFound)
    
    if ErrorsFound:
        ShowFatalError(state, "Errors found in processing cost estimate input")

fn check_cost_estimate_input(inout state: Any, inout ErrorsFound: Bool) -> None:
    var Zone = state.dataHeatBal.Zone
    
    for Item in range(len(state.dataCostEstimateManager.CostLineItem)):
        state.dataCostEstimateManager.CostLineItem[Item].LineNumber = Int32(Item) + 1
        
        var parent_type = state.dataCostEstimateManager.CostLineItem[Item].ParentObjType
        
        if parent_type == ParentObject.General:
            pass
        elif parent_type == ParentObject.Construction:
            if state.dataCostEstimateManager.CostLineItem[Item].PerSquareMeter == 0:
                ShowSevereError(state, "ComponentCost:LineItem: \"" + state.dataCostEstimateManager.CostLineItem[Item].LineName + "\" Construction object needs non-zero construction costs per square meter")
                ErrorsFound = True
            
            var ThisConstructStr = state.dataCostEstimateManager.CostLineItem[Item].ParentObjName
            var ThisConstructID = FindItem(ThisConstructStr, state.dataConstruction.Construct)
            
            if ThisConstructID == 0:
                ShowWarningError(state, "ComponentCost:LineItem: \"" + state.dataCostEstimateManager.CostLineItem[Item].LineName + "\" Construction=\"" + state.dataCostEstimateManager.CostLineItem[Item].ParentObjName + "\", no surfaces have the Construction specified")
                ShowContinueError(state, "No costs will be calculated for this Construction.")
                continue
        elif parent_type == ParentObject.CoilDX or parent_type == ParentObject.CoilCoolingDXSingleSpeed or parent_type == ParentObject.CoilCoolingDX:
            pass
        elif parent_type == ParentObject.CoilHeatingFuel:
            pass
        elif parent_type == ParentObject.ChillerElectric:
            if not state.dataCostEstimateManager.CostLineItem[Item].ParentObjName:
                ShowSevereError(state, "ComponentCost:LineItem: \"" + state.dataCostEstimateManager.CostLineItem[Item].LineName + "\", Chiller:Electric, need to specify a Reference Object Name")
                ErrorsFound = True
        elif parent_type == ParentObject.DaylightingControls:
            pass
        elif parent_type == ParentObject.ShadingZoneDetailed:
            pass
        elif parent_type == ParentObject.Lights:
            pass
        elif parent_type == ParentObject.GeneratorPhotovoltaic:
            pass

fn calc_cost_estimate(inout state: Any) -> None:
    var Zone = state.dataHeatBal.Zone
    
    for Item in range(len(state.dataCostEstimateManager.CostLineItem)):
        state.dataCostEstimateManager.CostLineItem[Item].LineNumber = Int32(Item) + 1
        
        var parent_type = state.dataCostEstimateManager.CostLineItem[Item].ParentObjType
        
        if parent_type == ParentObject.General:
            state.dataCostEstimateManager.CostLineItem[Item].Units = "Ea."
            state.dataCostEstimateManager.CostLineItem[Item].ValuePer = state.dataCostEstimateManager.CostLineItem[Item].PerEach
            state.dataCostEstimateManager.CostLineItem[Item].LineSubTotal = (state.dataCostEstimateManager.CostLineItem[Item].Qty * 
                                                                            state.dataCostEstimateManager.CostLineItem[Item].ValuePer)
    
    var total: Float64 = 0.0
    for item in state.dataCostEstimateManager.CostLineItem:
        total += item.LineSubTotal
    
    state.dataCostEstimateManager.CurntBldg.LineItemTot = total

fn get_enum_value(target_name: String) -> Int32:
    var names = get_parent_object_names_uc()
    for i in range(len(names)):
        if names[i] == target_name:
            return Int32(i)
    return -1

fn FindItem(name: String, list_obj: Any) -> Int32:
    return 0

fn ShowSevereError(inout state: Any, msg: String) -> None:
    pass

fn ShowWarningError(inout state: Any, msg: String) -> None:
    pass

fn ShowContinueError(inout state: Any, msg: String) -> None:
    pass

fn ShowFatalError(inout state: Any, msg: String) -> None:
    pass

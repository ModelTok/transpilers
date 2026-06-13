# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from collections.deque import Deque

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus.Data.EnergyPlusData (state container with dataPlnt)
# - PlantLocation: from EnergyPlus.Plant.PlantLocation (struct with loopNum, loopSideNum, branchNum, compNum)
# - PlantComponent: from EnergyPlus.Plant.PlantComponent (base class with oneTimeInitFlag and methods)
# - PlantEquipmentType: from EnergyPlus.Plant.Enums (enum with Num, Invalid)
# - CtrlType: from EnergyPlus.Plant.Enums (enum: Invalid, HeatingOp, CoolingOp, DualOp)
# - OpScheme: from EnergyPlus.Plant.Enums (enum with Invalid)
# - HowMet: from EnergyPlus.Plant.Enums (enum with Invalid)
# - FreeCoolControlMode: from EnergyPlus.Plant.Enums (enum with Invalid)
# - LoopFlowStatus: from EnergyPlus.Plant.Enums (enum with Invalid)
# - DataBranchAirLoopPlant.ControlType: enum with Invalid
# - OpSchemePtrData: from EnergyPlus.Plant.EquipAndOperations


struct EnergyPlusData:
    pass


struct PlantLocation:
    var loopNum: Int
    var loopSideNum: Int
    var branchNum: Int
    var compNum: Int


struct PlantComponent:
    var oneTimeInitFlag: Bool

    fn onInitLoopEquip(inout self, state: inout EnergyPlusData, location: PlantLocation) -> None: ...
    fn getDesignCapacities(inout self, state: inout EnergyPlusData, location: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64) -> None: ...
    fn getDesignTemperatures(inout self, TempDesCondIn: Float64, TempDesEvapOut: Float64) -> None: ...
    fn getSizingFactor(inout self, SizFac: Float64) -> None: ...
    fn simulate(inout self, state: inout EnergyPlusData, location: PlantLocation, FirstHVACIteration: Bool, MyLoad: Float64, ON: Bool) -> None: ...
    fn oneTimeInit_new(inout self, state: inout EnergyPlusData) -> None: ...
    fn getDynamicMaxCapacity(self, state: inout EnergyPlusData) -> Float64: ...


struct OpSchemePtrData:
    pass


alias PlantEquipmentType = Int
alias CtrlType = Int
alias OpScheme = Int
alias HowMet = Int
alias FreeCoolControlMode = Int
alias LoopFlowStatus = Int
alias ControlType = Int


@always_inline
fn _build_plant_equipment_type_is_pump() -> InlineArray[Bool, 105]:
    var arr = InlineArray[Bool, 105](fill=False)
    arr[34] = True
    arr[35] = True
    arr[36] = True
    arr[37] = True
    arr[38] = True
    return arr


@always_inline
fn _build_plant_equipment_ctrl_type() -> InlineArray[CtrlType, 105]:
    var arr = InlineArray[CtrlType, 105](fill=0)
    arr[0] = 0
    arr[1] = 0
    arr[2] = 1
    arr[3] = 1
    arr[4] = 1
    arr[5] = 1
    arr[6] = 2
    arr[7] = 1
    arr[8] = 1
    arr[9] = 1
    arr[10] = 1
    arr[11] = 1
    arr[12] = 1
    arr[13] = 1
    arr[14] = 1
    arr[15] = 0
    arr[16] = 0
    arr[17] = 1
    arr[18] = 0
    arr[19] = 1
    arr[20] = 0
    arr[21] = -1
    arr[22] = -1
    arr[23] = -1
    arr[24] = -1
    arr[25] = -1
    arr[26] = 1
    arr[27] = 0
    arr[28] = 1
    arr[29] = 1
    arr[30] = 0
    arr[31] = -1
    arr[32] = 0
    arr[33] = 0
    arr[34] = -1
    arr[35] = -1
    arr[36] = -1
    arr[37] = -1
    arr[38] = -1
    arr[39] = -1
    arr[40] = -1
    arr[41] = -1
    arr[42] = -1
    arr[43] = -1
    arr[44] = 0
    arr[45] = 2
    arr[46] = 2
    arr[47] = 2
    arr[48] = 2
    arr[49] = 0
    arr[50] = 0
    arr[51] = 0
    arr[52] = 0
    arr[53] = 0
    arr[54] = 1
    arr[55] = 1
    arr[56] = 1
    arr[57] = 1
    arr[58] = 1
    arr[59] = 1
    arr[60] = 0
    arr[61] = 0
    arr[62] = -1
    arr[63] = -1
    arr[64] = -1
    arr[65] = -1
    arr[66] = -1
    arr[67] = -1
    arr[68] = -1
    arr[69] = -1
    arr[70] = -1
    arr[71] = -1
    arr[72] = 0
    arr[73] = -1
    arr[74] = -1
    arr[75] = 2
    arr[76] = -1
    arr[77] = 0
    arr[78] = -1
    arr[79] = -1
    arr[80] = 2
    arr[81] = -1
    arr[82] = -1
    arr[83] = -1
    arr[84] = -1
    arr[85] = 2
    arr[86] = 2
    arr[87] = 2
    arr[88] = 2
    arr[89] = -1
    arr[90] = 0
    arr[91] = 1
    arr[92] = -1
    arr[93] = 2
    arr[94] = 0
    arr[95] = -1
    arr[96] = -1
    arr[97] = 1
    arr[98] = 0
    arr[99] = 1
    arr[100] = 0
    arr[101] = 1
    arr[102] = 2
    arr[103] = 0
    return arr


alias PLANT_EQUIPMENT_TYPE_IS_PUMP = _build_plant_equipment_type_is_pump()
alias PLANT_EQUIPMENT_CTRL_TYPE = _build_plant_equipment_ctrl_type()


struct CompData:
    var TypeOf: String
    var Type: Int
    var Name: String
    var CompNum: Int
    var FlowCtrl: Int
    var FlowPriority: Int
    var ON: Bool
    var Available: Bool
    var NodeNameIn: String
    var NodeNameOut: String
    var NodeNumIn: Int
    var NodeNumOut: Int
    var MyLoad: Float64
    var MaxLoad: Float64
    var MinLoad: Float64
    var OptLoad: Float64
    var SizFac: Float64
    var CurOpSchemeType: Int
    var NumOpSchemes: Int
    var CurCompLevelOpNum: Int
    var OpScheme: Deque[OpSchemePtrData]
    var EquipDemand: Float64
    var EMSLoadOverrideOn: Bool
    var EMSLoadOverrideValue: Float64
    var HowLoadServed: Int
    var MinOutletTemp: Float64
    var MaxOutletTemp: Float64
    var FreeCoolCntrlShutDown: Bool
    var FreeCoolCntrlMinCntrlTemp: Float64
    var FreeCoolCntrlMode: Int
    var FreeCoolCntrlNodeNum: Int
    var IndexInLoopSidePumps: Int
    var TempDesCondIn: Float64
    var TempDesEvapOut: Float64
    var compPtr: Pointer[PlantComponent]
    var location: PlantLocation

    fn __init__(inout self) -> None:
        self.TypeOf = ""
        self.Type = -1
        self.Name = ""
        self.CompNum = 0
        self.FlowCtrl = -1
        self.FlowPriority = -1
        self.ON = False
        self.Available = False
        self.NodeNameIn = ""
        self.NodeNameOut = ""
        self.NodeNumIn = 0
        self.NodeNumOut = 0
        self.MyLoad = 0.0
        self.MaxLoad = 0.0
        self.MinLoad = 0.0
        self.OptLoad = 0.0
        self.SizFac = 0.0
        self.CurOpSchemeType = -1
        self.NumOpSchemes = 0
        self.CurCompLevelOpNum = 0
        self.OpScheme = Deque[OpSchemePtrData]()
        self.EquipDemand = 0.0
        self.EMSLoadOverrideOn = False
        self.EMSLoadOverrideValue = 0.0
        self.HowLoadServed = -1
        self.MinOutletTemp = 0.0
        self.MaxOutletTemp = 0.0
        self.FreeCoolCntrlShutDown = False
        self.FreeCoolCntrlMinCntrlTemp = 0.0
        self.FreeCoolCntrlMode = -1
        self.FreeCoolCntrlNodeNum = 0
        self.IndexInLoopSidePumps = 0
        self.TempDesCondIn = 0.0
        self.TempDesEvapOut = 0.0
        self.compPtr = Pointer[PlantComponent]()
        self.location = PlantLocation(loopNum=0, loopSideNum=0, branchNum=0, compNum=0)

    fn initLoopEquip(inout self, state: inout EnergyPlusData, GetCompSizFac: Bool) -> None:
        self.compPtr[].onInitLoopEquip(state, self.location)
        self.compPtr[].getDesignCapacities(state, self.location, self.MaxLoad, self.MinLoad, self.OptLoad)
        self.compPtr[].getDesignTemperatures(self.TempDesCondIn, self.TempDesEvapOut)

        if GetCompSizFac:
            self.compPtr[].getSizingFactor(self.SizFac)

    fn simulate(inout self, state: inout EnergyPlusData, FirstHVACIteration: Bool) -> None:
        self.compPtr[].simulate(state, self.location, FirstHVACIteration, self.MyLoad, self.ON)

    fn oneTimeInit(self, state: inout EnergyPlusData) -> None:
        if self.compPtr[].oneTimeInitFlag:
            self.compPtr[].oneTimeInit_new(state)
            self.compPtr[].oneTimeInitFlag = False

    @staticmethod
    fn getPlantComponent(state: inout EnergyPlusData, plantLoc: PlantLocation) -> Pointer[CompData]:
        return UnsafePointer.address_of(state.dataPlnt.PlantLoop[plantLoc.loopNum].LoopSide[plantLoc.loopSideNum].Branch[plantLoc.branchNum].Comp[plantLoc.compNum])

    fn getDynamicMaxCapacity(self, state: inout EnergyPlusData) -> Float64:
        if not self.compPtr:
            return self.MaxLoad
        var possibleLoad = self.compPtr[].getDynamicMaxCapacity(state)
        return self.MaxLoad if possibleLoad == 0 else possibleLoad

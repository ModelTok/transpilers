from Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, compare_err_stream, delimited_string
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DemandManager import GetDemandManagerInput, GetDemandManagerListInput, ManagerLimit, ManagerSelection, DemandMgrData
from EnergyPlus.ExteriorEnergyUse import ExteriorEnergyUse
from EnergyPlus.MixedAir import MixedAir
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.UtilityRoutines import Util

def DemandManagerGetInput():
    var idf_objects: String = delimited_string(
        [
            "DemandManager:Ventilation,",
            " Ventilation Manager,",
            " ,",
            " FIXEDRATE,",
            " 60,",
            " 0.2,",
            " ,",
            " ,",
            " ALL,",
            " ,",
            " OA CONTROLLER 1;"
        ]
    )
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    state.dataMixedAir.NumOAControllers = 1
    state.dataMixedAir.OAController.allocate(state.dataMixedAir.NumOAControllers)
    state.dataMixedAir.OAController[0].Name = "OA CONTROLLER 1"
    GetDemandManagerInput(state)
    var DemandMgr = state.dataDemandManager.DemandMgr
    expect_eq(Sched.SchedNum_AlwaysOn, DemandMgr[0].availSched.Num)
    expect_enum_eq(ManagerLimit.Fixed, DemandMgr[0].LimitControl)
    expect_double_eq(60.0, DemandMgr[0].LimitDuration)
    expect_double_eq(0.2, DemandMgr[0].FixedRate)
    expect_enum_eq(ManagerSelection.All, DemandMgr[0].SelectionControl)
    expect_eq(1, DemandMgr[0].NumOfLoads)

def DemandManagerAssignmentListGetInputTest():
    var idf_objects: String = delimited_string(
        [
            "  DemandManagerAssignmentList,",
            "    Demand Manager,          !- Name",
            "    Electricity:Facility,    !- Meter Name",
            "    Limit Schedule,          !- Demand Limit Schedule Name",
            "    1.0,                     !- Demand Limit Safety Fraction",
            "    ,                        !- Billing Period Schedule Name",
            "    ,                        !- Peak Period Schedule Name",
            "    15,                      !- Demand Window Length {minutes}",
            "    SEQUENTIAL,              !- Demand Manager Priority",
            "    DemandManager:ExteriorLights,  !- DemandManager 1 Object Type",
            "    Ext Lights Manager 1;    !- DemandManager 1 Name",
            "  Schedule:Compact,",
            "    Limit Schedule,          !- Name",
            "    Any Number,              !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    FOR: AllDays,            !- Field 2",
            "    Until: 8:00,9999999,     !- Field 3",
            "    Until: 20:00,10000,      !- Field 5",
            "    Until: 24:00,9999999;    !- Field 7",
            "  DemandManager:ExteriorLights,",
            "    Ext Lights Manager,      !- Name",
            "    ,                        !- Availability Schedule Name",
            "    FIXED,                   !- Limit Control",
            "    60,                      !- Minimum Limit Duration {minutes}",
            "    0.0,                     !- Maximum Limit Fraction",
            "    ,                        !- Limit Step Change",
            "    ALL,                     !- Selection Control",
            "    ,                        !- Rotation Duration {minutes}",
            "    Exterior Lights;         !- Exterior Lights 1 Name",
            "  Exterior:Lights,",
            "    Exterior Lights,         !- Name",
            "    ON,                      !- Schedule Name",
            "    1000,                    !- Design Level {W}",
            "    ScheduleNameOnly;        !- Control Option",
            "  Schedule:Constant,",
            "    ON,                      !- Name",
            "    Fraction,                !- Schedule Type Limits Name",
            "    1;                       !- TimeStep Value",
            "  ScheduleTypeLimits,",
            "    Fraction,                !- Name",
            "    0.0,                     !- Lower Limit Value",
            "    1.0,                     !- Upper Limit Value",
            "    CONTINUOUS;              !- Numeric Type",
            "  ScheduleTypeLimits,",
            "    Any Number;              !- Name",
        ]
    )
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    ExteriorEnergyUse.GetExteriorEnergyUseInput(state)
    GetDemandManagerInput(state)
    var dMgrIndex: Int = 0
    var DemandMgr = state.dataDemandManager.DemandMgr
    dMgrIndex = Util.FindItemInList("EXT LIGHTS MANAGER", DemandMgr)
    var lightsDmndMgr = state.dataDemandManager.DemandMgr[dMgrIndex]
    expect_eq("EXT LIGHTS MANAGER", lightsDmndMgr.Name)
    var expected_error: String = delimited_string(
        [
            "   ** Severe  ** DemandManagerAssignmentList = \"DEMAND MANAGER\" invalid DemandManager Name = \"EXT LIGHTS MANAGER 1\" not found.",
            "   **  Fatal  ** Errors found in processing input for DemandManagerAssignmentList.",
            "   ...Summary of Errors that led to program termination:",
            "   ..... Reference severe error count=1",
            "   ..... Last severe error=DemandManagerAssignmentList = \"DEMAND MANAGER\" invalid DemandManager Name = \"EXT LIGHTS MANAGER 1\" not found.",
        ]
    )
    expect_any_throw(GetDemandManagerListInput(state))
    expect_true(compare_err_stream(expected_error, True))
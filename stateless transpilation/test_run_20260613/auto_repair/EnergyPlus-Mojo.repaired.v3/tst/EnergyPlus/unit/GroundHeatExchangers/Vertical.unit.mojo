typealias Real64 = Float64
typealias int = Int

from EnergyPlus.DataGlobalConstants import Constant
from EnergyPlus.DataSystemVariables import DataSystemVariables
from EnergyPlus.GroundHeatExchangers.ResponseFactors import GLHEResponseFactors
from EnergyPlus.GroundHeatExchangers.State import GroundHeatExchangerState
from EnergyPlus.GroundHeatExchangers.Vertical import GLHEVert
from EnergyPlus.Plant.PlantManager import PlantManager

struct EnergyPlusFixture:
    var state: GroundHeatExchangerState  # Assume type exists

    def __init__(inout self):
        # Initialize state as needed
        self.state = GroundHeatExchangerState()

    def process_idf(inout self, idf_objects: String) -> Bool:
        # Placeholder – actual implementation would parse IDF
        # Return true for now
        return True

# Helper assertions
def expect_double_eq(actual: Real64, expected: Real64):
    assert(actual == expected, "Expected: " + str(expected) + " but got: " + str(actual))

def expect_near(actual: Real64, expected: Real64, tolerance: Real64):
    assert(abs(actual - expected) <= tolerance, "Expected " + str(expected) + " but got " + str(actual) + " within tolerance " + str(tolerance))

def assert_true(condition: Bool, msg: String = ""):
    assert(condition, msg)

@test
def GroundHeatExchangerTest_System_GetGFunc():
    var fixture = EnergyPlusFixture()
    var thisGLHE: GLHEVert
    var thisGFunc: Real64
    var time: Real64
    var NPairs: int = 2
    var thisRF = Pointer[GLHEResponseFactors].init(GLHEResponseFactors())
    thisGLHE.myRespFactors = thisRF
    thisGLHE.myRespFactors.GFNC = DynamicVector[Real64](NPairs)
    thisGLHE.myRespFactors.LNTTS.push_back(0.0)
    thisGLHE.myRespFactors.LNTTS.push_back(5.0)
    thisGLHE.myRespFactors.GFNC[0] = 0.0
    thisGLHE.myRespFactors.GFNC[1] = 5.0
    time = pow(2.7182818284590452353602874, 2.5)
    thisGLHE.bhLength = 1.0
    thisGLHE.bhRadius = 1.0
    thisGLHE.myRespFactors.gRefRatio = 1.0
    thisGFunc = thisGLHE.getGFunc(time)
    expect_double_eq(2.5, thisGFunc)
    thisGLHE.myRespFactors.gRefRatio = 2.0
    thisGFunc = thisGLHE.getGFunc(time)
    expect_near(2.5 + 0.6931, thisGFunc, 0.0001)

@test
def GHE_InterpTest2():
    var fixture = EnergyPlusFixture()
    var thisRF = Pointer[GLHEResponseFactors].init(GLHEResponseFactors())
    thisRF.GFNC = DynamicVector[Real64](8)
    thisRF.LNTTS = DynamicVector[Real64]{-15.2202, -15.083, -14.9459, -14.8087, -14.6716, -14.5344, -14.3973, -14.2601}
    thisRF.GFNC = {-2.55692, -2.48389, -2.40819, -2.32936, -2.24715, -2.16138, -2.07195, -1.97882}
    var thisGHE: GLHEVert
    thisGHE.myRespFactors = thisRF
    var tolerance: Real64 = 1e-6
    expect_near(thisGHE.interpGFunc(-15.220200), -2.556920, tolerance)
    expect_near(thisGHE.interpGFunc(-15.187093), -2.539298, tolerance)
    expect_near(thisGHE.interpGFunc(-15.153986), -2.521675, tolerance)
    expect_near(thisGHE.interpGFunc(-15.120879), -2.504053, tolerance)
    expect_near(thisGHE.interpGFunc(-15.087772), -2.486430, tolerance)
    expect_near(thisGHE.interpGFunc(-15.054666), -2.468245, tolerance)
    expect_near(thisGHE.interpGFunc(-15.021559), -2.449965, tolerance)
    expect_near(thisGHE.interpGFunc(-14.988452), -2.431685, tolerance)
    expect_near(thisGHE.interpGFunc(-14.955345), -2.413405, tolerance)
    expect_near(thisGHE.interpGFunc(-14.922238), -2.394595, tolerance)
    expect_near(thisGHE.interpGFunc(-14.889131), -2.375573, tolerance)
    expect_near(thisGHE.interpGFunc(-14.856024), -2.356551, tolerance)
    expect_near(thisGHE.interpGFunc(-14.822917), -2.337529, tolerance)
    expect_near(thisGHE.interpGFunc(-14.789810), -2.318033, tolerance)
    expect_near(thisGHE.interpGFunc(-14.756703), -2.298181, tolerance)
    expect_near(thisGHE.interpGFunc(-14.723597), -2.278329, tolerance)
    expect_near(thisGHE.interpGFunc(-14.690490), -2.258477, tolerance)
    expect_near(thisGHE.interpGFunc(-14.657383), -2.238262, tolerance)
    expect_near(thisGHE.interpGFunc(-14.624276), -2.217566, tolerance)
    expect_near(thisGHE.interpGFunc(-14.591169), -2.196869, tolerance)
    expect_near(thisGHE.interpGFunc(-14.558062), -2.176172, tolerance)
    expect_near(thisGHE.interpGFunc(-14.524955), -2.155219, tolerance)
    expect_near(thisGHE.interpGFunc(-14.491848), -2.133624, tolerance)
    expect_near(thisGHE.interpGFunc(-14.458741), -2.112028, tolerance)
    expect_near(thisGHE.interpGFunc(-14.425634), -2.090433, tolerance)
    expect_near(thisGHE.interpGFunc(-14.392528), -2.068711, tolerance)
    expect_near(thisGHE.interpGFunc(-14.359421), -2.046238, tolerance)
    expect_near(thisGHE.interpGFunc(-14.326314), -2.023765, tolerance)
    expect_near(thisGHE.interpGFunc(-14.293207), -2.001293, tolerance)
    expect_near(thisGHE.interpGFunc(-14.260100), -1.978820, tolerance)

@test
def GroundHeatExchangerTest_System_calcGFunction_UBHWT():
    let idf_objects: String = delimited_string({"Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
                          "    KATemps,                 !- Name",
                          "    1.8,                     !- Soil Thermal Conductivity {W/m-K}",
                          "    920,                     !- Soil Density {kg/m3}",
                          "    2200,                    !- Soil Specific Heat {J/kg-K}",
                          "    15.5,                    !- Average Soil Surface Temperature {C}",
                          "    3.2,                     !- Average Amplitude of Surface Temperature {deltaC}",
                          "    8;                       !- Phase Shift of Minimum Surface Temperature {days}",
                          "GroundHeatExchanger:Vertical:Properties,",
                          "    GHE-1 Props,        !- Name",
                          "    1,                  !- Depth of Top of Borehole {m}",
                          "    100,                !- Borehole Length {m}",
                          "    0.109982,           !- Borehole Diameter {m}",
                          "    0.744,              !- Grout Thermal Conductivity {W/m-K}",
                          "    3.90E+06,           !- Grout Thermal Heat Capacity {J/m3-K}",
                          "    0.389,              !- Pipe Thermal Conductivity {W/m-K}",
                          "    1.77E+06,           !- Pipe Thermal Heat Capacity {J/m3-K}",
                          "    0.0267,             !- Pipe Outer Diameter {m}",
                          "    0.00243,            !- Pipe Thickness {m}",
                          "    0.04556;            !- U-Tube Distance {m}",
                          "GroundHeatExchanger:Vertical:Single,",
                          "    GHE-1,              !- Name",
                          "    GHE-1 Props,        !- GHE Properties",
                          "    0,                  !- X Location {m}",
                          "    0;                  !- Y Location {m}",
                          "GroundHeatExchanger:Vertical:Single,",
                          "    GHE-2,              !- Name",
                          "    GHE-1 Props,        !- GHE Properties",
                          "    5.0,                !- X Location {m}",
                          "    0;                  !- Y Location {m}",
                          "GroundHeatExchanger:Vertical:Single,",
                          "    GHE-3,              !- Name",
                          "    GHE-1 Props,        !- GHE Properties",
                          "    0,                  !- X Location {m}",
                          "    5.0;                !- Y Location {m}",
                          "GroundHeatExchanger:Vertical:Single,",
                          "    GHE-4,              !- Name",
                          "    GHE-1 Props,        !- GHE Properties",
                          "    5.0,                !- X Location {m}",
                          "    5.0;                !- Y Location {m}",
                          "GroundHeatExchanger:System,",
                          "    Vertical GHE 1x4 Std,  !- Name",
                          "    GHLE Inlet,         !- Inlet Node Name",
                          "    GHLE Outlet,        !- Outlet Node Name",
                          "    0.00075708,         !- Design Flow Rate {m3/s}",
                          "    Site:GroundTemperature:Undisturbed:KusudaAchenbach,  !- Undisturbed Ground Temperature Model Type",
                          "    KATemps,            !- Undisturbed Ground Temperature Model Name",
                          "    2.423,              !- Ground Thermal Conductivity {W/m-K}",
                          "    2.343E+06,          !- Ground Thermal Heat Capacity {J/m3-K}",
                          "    ,                   !- Response Factors Object Name",
                          "    UBHWTCalc,          !- g-Function Calculation Method",
                          "    ,                   !- GHE Vertical Sizing Object Type",
                          "    ,                   !- GHE Vertical Sizing Object Name",
                          "    ,                   !- GHE Array Object Name",
                          "    GHE-1,              !- GHE Borehole Definition 1",
                          "    GHE-2,              !- GHE Borehole Definition 2",
                          "    GHE-3,              !- GHE Borehole Definition 3",
                          "    GHE-4;              !- GHE Borehole Definition 4",
                          "Branch,",
                          "    Main Floor Cooling Condenser Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Coil:Cooling:WaterToAirHeatPump:EquationFit,  !- Component 1 Object Type",
                          "    Main Floor WAHP Cooling Coil,  !- Component 1 Name",
                          "    Main Floor WAHP Cooling Water Inlet Node,  !- Component 1 Inlet Node Name",
                          "    Main Floor WAHP Cooling Water Outlet Node;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Main Floor Heating Condenser Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Coil:Heating:WaterToAirHeatPump:EquationFit,  !- Component 1 Object Type",
                          "    Main Floor WAHP Heating Coil,  !- Component 1 Name",
                          "    Main Floor WAHP Heating Water Inlet Node,  !- Component 1 Inlet Node Name",
                          "    Main Floor WAHP Heating Water Outlet Node;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    GHE-Vert Branch,         !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    GroundHeatExchanger:System,  !- Component 1 Object Type",
                          "    Vertical GHE 1x4 Std,    !- Component 1 Name",
                          "    GHLE Inlet,         !- Component 1 Inlet Node Name",
                          "    GHLE Outlet;        !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Supply Inlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pump:ConstantSpeed,      !- Component 1 Object Type",
                          "    Ground Loop Supply Pump, !- Component 1 Name",
                          "    Ground Loop Supply Inlet,!- Component 1 Inlet Node Name",
                          "    Ground Loop Pump Outlet; !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Supply Outlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Supply Outlet Pipe,  !- Component 1 Name",
                          "    Ground Loop Supply Outlet Pipe Inlet,  !- Component 1 Inlet Node Name",
                          "    Ground Loop Supply Outlet;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Demand Inlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Demand Inlet Pipe,  !- Component 1 Name",
                          "    Ground Loop Demand Inlet,!- Component 1 Inlet Node Name",
                          "    Ground Loop Demand Inlet Pipe Outlet;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Demand Bypass Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Demand Side Bypass Pipe,  !- Component 1 Name",
                          "    Ground Loop Demand Bypass Inlet,  !- Component 1 Inlet Node Name",
                          "    Ground Loop Demand Bypass Outlet;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Demand Outlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Demand Outlet Pipe,  !- Component 1 Name",
                          "    Ground Loop Demand Outlet Pipe Inlet,  !- Component 1 Inlet Node Name",
                          "    Ground Loop Demand Outlet;  !- Component 1 Outlet Node Name",
                          "BranchList,",
                          "    Ground Loop Supply Side Branches,  !- Name",
                          "    Ground Loop Supply Inlet Branch,  !- Branch 1 Name",
                          "    GHE-Vert Branch,         !- Branch 2 Name",
                          "    Ground Loop Supply Outlet Branch;  !- Branch 3 Name",
                          "BranchList,",
                          "    Ground Loop Demand Side Branches,  !- Name",
                          "    Ground Loop Demand Inlet Branch,  !- Branch 1 Name",
                          "    Main Floor Cooling Condenser Branch,  !- Branch 2 Name",
                          "    Main Floor Heating Condenser Branch,  !- Branch 3 Name",
                          "    Ground Loop Demand Bypass Branch,  !- Branch 4 Name",
                          "    Ground Loop Demand Outlet Branch;  !- Branch 5 Name",
                          "Connector:Splitter,",
                          "    Ground Loop Supply Splitter,  !- Name",
                          "    Ground Loop Supply Inlet Branch,  !- Inlet Branch Name",
                          "    GHE-Vert Branch;         !- Outlet Branch 1 Name",
                          "Connector:Splitter,",
                          "    Ground Loop Demand Splitter,  !- Name",
                          "    Ground Loop Demand Inlet Branch,  !- Inlet Branch Name",
                          "    Ground Loop Demand Bypass Branch,  !- Outlet Branch 1 Name",
                          "    Main Floor Cooling Condenser Branch,  !- Outlet Branch 2 Name",
                          "    Main Floor Heating Condenser Branch;  !- Outlet Branch 3 Name",
                          "Connector:Mixer,",
                          "    Ground Loop Supply Mixer,!- Name",
                          "    Ground Loop Supply Outlet Branch,  !- Outlet Branch Name",
                          "    GHE-Vert Branch;         !- Inlet Branch 1 Name",
                          "Connector:Mixer,",
                          "    Ground Loop Demand Mixer,!- Name",
                          "    Ground Loop Demand Outlet Branch,  !- Outlet Branch Name",
                          "    Ground Loop Demand Bypass Branch,  !- Inlet Branch 1 Name",
                          "    Main Floor Cooling Condenser Branch,  !- Inlet Branch 2 Name",
                          "    Main Floor Heating Condenser Branch;  !- Inlet Branch 3 Name",
                          "ConnectorList,",
                          "    Ground Loop Supply Side Connectors,  !- Name",
                          "    Connector:Splitter,      !- Connector 1 Object Type",
                          "    Ground Loop Supply Splitter,  !- Connector 1 Name",
                          "    Connector:Mixer,         !- Connector 2 Object Type",
                          "    Ground Loop Supply Mixer;!- Connector 2 Name",
                          "ConnectorList,",
                          "    Ground Loop Demand Side Connectors,  !- Name",
                          "    Connector:Splitter,      !- Connector 1 Object Type",
                          "    Ground Loop Demand Splitter,  !- Connector 1 Name",
                          "    Connector:Mixer,         !- Connector 2 Object Type",
                          "    Ground Loop Demand Mixer;!- Connector 2 Name",
                          "NodeList,",
                          "    Ground Loop Supply Setpoint Nodes,  !- Name",
                          "    GHLE Outlet,                        !- Node 1 Name",
                          "    Ground Loop Supply Outlet;  !- Node 2 Name",
                          "OutdoorAir:Node,",
                          "    Main Floor WAHP Outside Air Inlet,  !- Name",
                          "    -1;                      !- Height Above Ground {m}",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Supply Outlet Pipe,  !- Name",
                          "    Ground Loop Supply Outlet Pipe Inlet,  !- Inlet Node Name",
                          "    Ground Loop Supply Outlet;  !- Outlet Node Name",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Demand Inlet Pipe,  !- Name",
                          "    Ground Loop Demand Inlet,!- Inlet Node Name",
                          "    Ground Loop Demand Inlet Pipe Outlet;  !- Outlet Node Name",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Demand Side Bypass Pipe,  !- Name",
                          "    Ground Loop Demand Bypass Inlet,  !- Inlet Node Name",
                          "    Ground Loop Demand Bypass Outlet;  !- Outlet Node Name",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Demand Outlet Pipe,  !- Name",
                          "    Ground Loop Demand Outlet Pipe Inlet,  !- Inlet Node Name",
                          "    Ground Loop Demand Outlet;  !- Outlet Node Name",
                          "Pump:ConstantSpeed,",
                          "    Ground Loop Supply Pump, !- Name",
                          "    Ground Loop Supply Inlet,!- Inlet Node Name",
                          "    Ground Loop Pump Outlet, !- Outlet Node Name",
                          "    autosize,                !- Design Flow Rate {m3/s}",
                          "    179352,                  !- Design Pump Head {Pa}",
                          "    autosize,                !- Design Power Consumption {W}",
                          "    0.9,                     !- Motor Efficiency",
                          "    0,                       !- Fraction of Motor Inefficiencies to Fluid Stream",
                          "    Intermittent;            !- Pump Control Type",
                          "PlantLoop,",
                          "    Ground Loop Water Loop,  !- Name",
                          "    Water,                      !- Fluid Type",
                          "    ,                           !- User Defined Fluid Type",
                          "    Only Water Loop Operation,  !- Plant Equipment Operation Scheme Name",
                          "    Ground Loop Supply Outlet,  !- Loop Temperature Setpoint Node Name",
                          "    100,                     !- Maximum Loop Temperature {C}",
                          "    10,                      !- Minimum Loop Temperature {C}",
                          "    autosize,                !- Maximum Loop Flow Rate {m3/s}",
                          "    0,                       !- Minimum Loop Flow Rate {m3/s}",
                          "    autosize,                !- Plant Loop Volume {m3}",
                          "    Ground Loop Supply Inlet,!- Plant Side Inlet Node Name",
                          "    Ground Loop Supply Outlet,  !- Plant Side Outlet Node Name",
                          "    Ground Loop Supply Side Branches,  !- Plant Side Branch List Name",
                          "    Ground Loop Supply Side Connectors,  !- Plant Side Connector List Name",
                          "    Ground Loop Demand Inlet,!- Demand Side Inlet Node Name",
                          "    Ground Loop Demand Outlet,  !- Demand Side Outlet Node Name",
                          "    Ground Loop Demand Side Branches,  !- Demand Side Branch List Name",
                          "    Ground Loop Demand Side Connectors,  !- Demand Side Connector List Name",
                          "    SequentialLoad,          !- Load Distribution Scheme",
                          "    ,                        !- Availability Manager List Name",
                          "    DualSetPointDeadband;    !- Plant Loop Demand Calculation Scheme",
                          "PlantEquipmentList,",
                          "    Only Water Loop All Cooling Equipment,  !- Name",
                          "    GroundHeatExchanger:System,  !- Equipment 1 Object Type",
                          "    Vertical GHE 1x4 Std;    !- Equipment 1 Name",
                          "PlantEquipmentOperation:CoolingLoad,",
                          "    Only Water Loop Cool Operation All Hours,  !- Name",
                          "    0,                       !- Load Range 1 Lower Limit {W}",
                          "    1000000000000000,        !- Load Range 1 Upper Limit {W}",
                          "    Only Water Loop All Cooling Equipment;  !- Range 1 Equipment List Name",
                          "PlantEquipmentOperationSchemes,",
                          "    Only Water Loop Operation,  !- Name",
                          "    PlantEquipmentOperation:CoolingLoad,  !- Control Scheme 1 Object Type",
                          "    Only Water Loop Cool Operation All Hours,  !- Control Scheme 1 Name",
                          "    HVACTemplate-Always 1;   !- Control Scheme 1 Schedule Name",
                          "SetpointManager:Scheduled:DualSetpoint,",
                          "    Ground Loop Temp Manager,!- Name",
                          "    Temperature,             !- Control Variable",
                          "    HVACTemplate-Always 34,  !- High Setpoint Schedule Name",
                          "    HVACTemplate-Always 20,  !- Low Setpoint Schedule Name",
                          "    Ground Loop Supply Setpoint Nodes;  !- Setpoint Node or NodeList Name",
                          "Schedule:Compact,",
                          "    HVACTemplate-Always 4,   !- Name",
                          "    HVACTemplate Any Number, !- Schedule Type Limits Name",
                          "    Through: 12/31,          !- Field 1",
                          "    For: AllDays,            !- Field 2",
                          "    Until: 24:00,4;          !- Field 3",
                          "Schedule:Compact,",
                          "    HVACTemplate-Always 34,  !- Name",
                          "    HVACTemplate Any Number, !- Schedule Type Limits Name",
                          "    Through: 12/31,          !- Field 1",
                          "    For: AllDays,            !- Field 2",
                          "    Until: 24:00,34;         !- Field 3",
                          "Schedule:Compact,",
                          "    HVACTemplate-Always 20,  !- Name",
                          "    HVACTemplate Any Number, !- Schedule Type Limits Name",
                          "    Through: 12/31,          !- Field 1",
                          "    For: AllDays,            !- Field 2",
                          "    Until: 24:00,20;         !- Field 3"})
    assert_true(fixture.process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    PlantManager.GetPlantLoopData(fixture.state)
    PlantManager.GetPlantInput(fixture.state)
    PlantManager.SetupInitialPlantCallingOrder(fixture.state)
    PlantManager.SetupBranchControlTypes(fixture.state)
    var thisGLHE = fixture.state.dataGroundHeatExchanger.verticalGLHE[0]
    thisGLHE.plantLoc.loopNum = 1
    fixture.state.dataLoopNodes.Node(thisGLHE.inletNodeNum).Temp = 20
    thisGLHE.designFlow = 0.00075708
    var rho: Real64 = 998.207
    thisGLHE.designMassFlow = thisGLHE.designFlow * rho
    thisGLHE.myRespFactors.maxSimYears = 1
    if not Constant.python_cli_enabled:

    else:
        thisGLHE.calcGFunctions(fixture.state)
        let tolerance: Real64 = 0.1
        expect_near(thisGLHE.interpGFunc(-11.939864), 0.37, tolerance)
        expect_near(thisGLHE.interpGFunc(-11.802269), 0.48, tolerance)
        expect_near(thisGLHE.interpGFunc(-11.664675), 0.59, tolerance)
        expect_near(thisGLHE.interpGFunc(-11.52708), 0.69, tolerance)
        expect_near(thisGLHE.interpGFunc(-11.389486), 0.79, tolerance)
        expect_near(thisGLHE.interpGFunc(-11.251891), 0.89, tolerance)
        expect_near(thisGLHE.interpGFunc(-11.114296), 0.99, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.976702), 1.09, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.839107), 1.18, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.701513), 1.27, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.563918), 1.36, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.426324), 1.44, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.288729), 1.53, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.151135), 1.61, tolerance)
        expect_near(thisGLHE.interpGFunc(-10.01354), 1.69, tolerance)
        expect_near(thisGLHE.interpGFunc(-9.875946), 1.77, tolerance)
        expect_near(thisGLHE.interpGFunc(-9.738351), 1.85, tolerance)
        expect_near(thisGLHE.interpGFunc(-9.600756), 1.93, tolerance)
        expect_near(thisGLHE.interpGFunc(-9.463162), 2.00, tolerance)
        expect_near(thisGLHE.interpGFunc(-9.325567), 2.08, tolerance)
        expect_near(thisGLHE.interpGFunc(-9.187973), 2.15, tolerance)
        expect_near(thisGLHE.interpGFunc(-9.050378), 2.23, tolerance)
        expect_near(thisGLHE.interpGFunc(-8.912784), 2.30, tolerance)
        expect_near(thisGLHE.interpGFunc(-8.775189), 2.37, tolerance)
        expect_near(thisGLHE.interpGFunc(-8.637595), 2.45, tolerance)
        expect_near(thisGLHE.interpGFunc(-8.5), 2.53, tolerance)
        expect_near(thisGLHE.interpGFunc(-7.8), 2.90, tolerance)
        expect_near(thisGLHE.interpGFunc(-7.2), 3.17, tolerance)
        expect_near(thisGLHE.interpGFunc(-6.5), 3.52, tolerance)
        expect_near(thisGLHE.interpGFunc(-5.9), 3.85, tolerance)
        expect_near(thisGLHE.interpGFunc(-5.2), 4.37, tolerance)
        expect_near(thisGLHE.interpGFunc(-4.5), 5.11, tolerance)
        expect_near(thisGLHE.interpGFunc(-3.963), 5.82, tolerance)

@test
def GHE_InterpTest1():
    var fixture = EnergyPlusFixture()
    var thisRF = Pointer[GLHEResponseFactors].init(GLHEResponseFactors())
    thisRF.GFNC = DynamicVector[Real64](11)
    thisRF.LNTTS = DynamicVector[Real64]{-5.0, -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0}
    thisRF.GFNC = {0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0}
    var thisGHE: GLHEVert
    thisGHE.myRespFactors = thisRF
    var tolerance: Real64 = 0.01
    expect_near(thisGHE.interpGFunc(-10.0), -2.50, tolerance)
    expect_near(thisGHE.interpGFunc(-9.5), -2.25, tolerance)
    expect_near(thisGHE.interpGFunc(-9.0), -2.00, tolerance)
    expect_near(thisGHE.interpGFunc(-8.5), -1.75, tolerance)
    expect_near(thisGHE.interpGFunc(-8.0), -1.50, tolerance)
    expect_near(thisGHE.interpGFunc(-7.5), -1.25, tolerance)
    expect_near(thisGHE.interpGFunc(-7.0), -1.00, tolerance)
    expect_near(thisGHE.interpGFunc(-6.5), -0.75, tolerance)
    expect_near(thisGHE.interpGFunc(-6.0), -0.50, tolerance)
    expect_near(thisGHE.interpGFunc(-5.5), -0.25, tolerance)
    expect_near(thisGHE.interpGFunc(-5.0), 0.00, tolerance)
    expect_near(thisGHE.interpGFunc(-4.5), 0.25, tolerance)
    expect_near(thisGHE.interpGFunc(-4.0), 0.50, tolerance)
    expect_near(thisGHE.interpGFunc(-3.5), 0.75, tolerance)
    expect_near(thisGHE.interpGFunc(-3.0), 1.00, tolerance)
    expect_near(thisGHE.interpGFunc(-2.5), 1.25, tolerance)
    expect_near(thisGHE.interpGFunc(-2.0), 1.50, tolerance)
    expect_near(thisGHE.interpGFunc(-1.5), 1.75, tolerance)
    expect_near(thisGHE.interpGFunc(-1.0), 2.00, tolerance)
    expect_near(thisGHE.interpGFunc(-0.5), 2.25, tolerance)
    expect_near(thisGHE.interpGFunc(0.0), 2.50, tolerance)
    expect_near(thisGHE.interpGFunc(0.5), 2.75, tolerance)
    expect_near(thisGHE.interpGFunc(1.0), 3.00, tolerance)
    expect_near(thisGHE.interpGFunc(1.5), 3.25, tolerance)
    expect_near(thisGHE.interpGFunc(2.0), 3.50, tolerance)
    expect_near(thisGHE.interpGFunc(2.5), 3.75, tolerance)
    expect_near(thisGHE.interpGFunc(3.0), 4.00, tolerance)
    expect_near(thisGHE.interpGFunc(3.5), 4.25, tolerance)
    expect_near(thisGHE.interpGFunc(4.0), 4.50, tolerance)
    expect_near(thisGHE.interpGFunc(4.5), 4.75, tolerance)
    expect_near(thisGHE.interpGFunc(5.0), 5.00, tolerance)
    expect_near(thisGHE.interpGFunc(5.5), 5.25, tolerance)
    expect_near(thisGHE.interpGFunc(6.0), 5.50, tolerance)
    expect_near(thisGHE.interpGFunc(6.5), 5.75, tolerance)
    expect_near(thisGHE.interpGFunc(7.0), 6.00, tolerance)
    expect_near(thisGHE.interpGFunc(7.5), 6.25, tolerance)
    expect_near(thisGHE.interpGFunc(8.0), 6.50, tolerance)
    expect_near(thisGHE.interpGFunc(8.5), 6.75, tolerance)
    expect_near(thisGHE.interpGFunc(9.0), 7.00, tolerance)
    expect_near(thisGHE.interpGFunc(9.5), 7.25, tolerance)
    expect_near(thisGHE.interpGFunc(10.0), 7.50, tolerance)

@test
def GroundHeatExchangerTest_System_calc_pipe_conduction_resistance():
    let idf_objects: String = delimited_string({"Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
                          "    KATemps,                 !- Name",
                          "    1.8,                     !- Soil Thermal Conductivity {W/m-K}",
                          "    920,                     !- Soil Density {kg/m3}",
                          "    2200,                    !- Soil Specific Heat {J/kg-K}",
                          "    15.5,                    !- Average Soil Surface Temperature {C}",
                          "    3.2,                     !- Average Amplitude of Surface Temperature {deltaC}",
                          "    8;                       !- Phase Shift of Minimum Surface Temperature {days}",
                          "GroundHeatExchanger:Vertical:Properties,",
                          "    GHE-1 Props,        !- Name",
                          "    1,                  !- Depth of Top of Borehole {m}",
                          "    100,                !- Borehole Length {m}",
                          "    0.109982,           !- Borehole Diameter {m}",
                          "    0.744,              !- Grout Thermal Conductivity {W/m-K}",
                          "    3.90E+06,           !- Grout Thermal Heat Capacity {J/m3-K}",
                          "    0.389,              !- Pipe Thermal Conductivity {W/m-K}",
                          "    1.77E+06,           !- Pipe Thermal Heat Capacity {J/m3-K}",
                          "    0.0267,             !- Pipe Outer Diameter {m}",
                          "    0.00243,            !- Pipe Thickness {m}",
                          "    0.04556;            !- U-Tube Distance {m}",
                          "GroundHeatExchanger:Vertical:Array,",
                          "    GHE-Array,          !- Name",
                          "    GHE-1 Props,        !- GHE Properties",
                          "    2,                  !- Number of Boreholes in X Direction",
                          "    2,                  !- Number of Boreholes in Y Direction",
                          "    2;                  !- Borehole Spacing {m}",
                          "GroundHeatExchanger:System,",
                          "    Vertical GHE 1x4 Std,  !- Name",
                          "    GHLE Inlet,         !- Inlet Node Name",
                          "    GHLE Outlet,        !- Outlet Node Name",
                          "    0.0007571,          !- Design Flow Rate {m3/s}",
                          "    Site:GroundTemperature:Undisturbed:KusudaAchenbach,  !- Undisturbed Ground Temperature Model Type",
                          "    KATemps,            !- Undisturbed Ground Temperature Model Name",
                          "    2.423,              !- Ground Thermal Conductivity {W/m-K}",
                          "    2.343E+06,          !- Ground Thermal Heat Capacity {J/m3-K}",
                          "    ,                   !- Response Factors Object Name",
                          "    UHFCalc,            !- g-Function Calculation Method",
                          "    ,                   !- GHE Vertical Sizing Object Type",
                          "    ,                   !- GHE Vertical Sizing Object Name",
                          "    GHE-Array;          !- GHE Array Object Name"})
    assert_true(fixture.process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    GetGroundHeatExchangerInput(fixture.state)
    var thisGLHE = fixture.state.dataGroundHeatExchanger.verticalGLHE[0]
    let tolerance: Real64 = 0.00001
    expect_near(thisGLHE.calcPipeConductionResistance(), 0.082204, tolerance)

@test
def GroundHeatExchangerTest_System_friction_factor():
    let idf_objects: String = delimited_string({"Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
                          "    KATemps,                 !- Name",
                          "    1.8,                     !- Soil Thermal Conductivity {W/m-K}",
                          "    920,                     !- Soil Density {kg/m3}",
                          "    2200,                    !- Soil Specific Heat {J/kg-K}",
                          "    15.5,                    !- Average Soil Surface Temperature {C}",
                          "    3.2,                     !- Average Amplitude of Surface Temperature {deltaC}",
                          "    8;                       !- Phase Shift of Minimum Surface Temperature {days}",
                          "GroundHeatExchanger:Vertical:Properties,",
                          "    GHE-1 Props,        !- Name",
                          "    1,                  !- Depth of Top of Borehole {m}",
                          "    100,                !- Borehole Length {m}",
                          "    0.109982,           !- Borehole Diameter {m}",
                          "    0.744,              !- Grout Thermal Conductivity {W/m-K}",
                          "    3.90E+06,           !- Grout Thermal Heat Capacity {J/m3-K}",
                          "    0.389,              !- Pipe Thermal Conductivity {W/m-K}",
                          "    1.77E+06,           !- Pipe Thermal Heat Capacity {J/m3-K}",
                          "    0.0267,             !- Pipe Outer Diameter {m}",
                          "    0.00243,            !- Pipe Thickness {m}",
                          "    0.04556;            !- U-Tube Distance {m}",
                          "GroundHeatExchanger:Vertical:Array,",
                          "    GHE-Array,          !- Name",
                          "    GHE-1 Props,        !- GHE Properties",
                          "    2,                  !- Number of Boreholes in X Direction",
                          "    2,                  !- Number of Boreholes in Y Direction",
                          "    2;                  !- Borehole Spacing {m}",
                          "GroundHeatExchanger:System,",
                          "    Vertical GHE 1x4 Std,  !- Name",
                          "    GHLE Inlet,         !- Inlet Node Name",
                          "    GHLE Outlet,        !- Outlet Node Name",
                          "    0.0007571,          !- Design Flow Rate {m3/s}",
                          "    Site:GroundTemperature:Undisturbed:KusudaAchenbach,  !- Undisturbed Ground Temperature Model Type",
                          "    KATemps,            !- Undisturbed Ground Temperature Model Name",
                          "    2.423,              !- Ground Thermal Conductivity {W/m-K}",
                          "    2.343E+06,          !- Ground Thermal Heat Capacity {J/m3-K}",
                          "    ,                   !- Response Factors Object Name",
                          "    UHFCalc,            !- g-Function Calculation Method",
                          "    ,                   !- GHE Vertical Sizing Object Type",
                          "    ,                   !- GHE Vertical Sizing Object Name",
                          "    GHE-Array;          !- GHE Array Object Name"})
    assert_true(fixture.process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    GetGroundHeatExchangerInput(fixture.state)
    var thisGLHE = fixture.state.dataGroundHeatExchanger.verticalGLHE[0]
    var reynoldsNum: Real64
    let tolerance: Real64 = 0.000001
    reynoldsNum = 100
    expect_near(thisGLHE.frictionFactor(reynoldsNum), 64.0 / reynoldsNum, tolerance)
    reynoldsNum = 1000
    expect_near(thisGLHE.frictionFactor(reynoldsNum), 64.0 / reynoldsNum, tolerance)
    reynoldsNum = 1400
    expect_near(thisGLHE.frictionFactor(reynoldsNum), 64.0 / reynoldsNum, tolerance)
    reynoldsNum = 2000
    expect_near(thisGLHE.frictionFactor(reynoldsNum), 0.034003503, tolerance)
    reynoldsNum = 3000
    expect_near(thisGLHE.frictionFactor(reynoldsNum), 0.033446219, tolerance)
    reynoldsNum = 4000
    expect_near(thisGLHE.frictionFactor(reynoldsNum), 0.03895358, tolerance)
    reynoldsNum = 5000
    expect_near(thisGLHE.frictionFactor(reynoldsNum), pow(0.79 * log(reynoldsNum) - 1.64, -2.0), tolerance)
    reynoldsNum = 15000
    expect_near(thisGLHE.frictionFactor(reynoldsNum), pow(0.79 * log(reynoldsNum) - 1.64, -2.0), tolerance)
    reynoldsNum = 25000
    expect_near(thisGLHE.frictionFactor(reynoldsNum), pow(0.79 * log(reynoldsNum) - 1.64, -2.0), tolerance)

@test
def GroundHeatExchangerTest_System_calc_pipe_convection_resistance():
    let idf_objects: String = delimited_string({"Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
                          "    KATemps,                 !- Name",
                          "    1.8,                     !- Soil Thermal Conductivity {W/m-K}",
                          "    920,                     !- Soil Density {kg/m3}",
                          "    2200,                    !- Soil Specific Heat {J/kg-K}",
                          "    15.5,                    !- Average Soil Surface Temperature {C}",
                          "    3.2,                     !- Average Amplitude of Surface Temperature {deltaC}",
                          "    8;                       !- Phase Shift of Minimum Surface Temperature {days}",
                          "GroundHeatExchanger:Vertical:Properties,",
                          "    GHE-1 Props,        !- Name",
                          "    1,                  !- Depth of Top of Borehole {m}",
                          "    100,                !- Borehole Length {m}",
                          "    0.109982,           !- Borehole Diameter {m}",
                          "    0.744,              !- Grout Thermal Conductivity {W/m-K}",
                          "    3.90E+06,           !- Grout Thermal Heat Capacity {J/m3-K}",
                          "    0.389,              !- Pipe Thermal Conductivity {W/m-K}",
                          "    1.77E+06,           !- Pipe Thermal Heat Capacity {J/m3-K}",
                          "    0.0267,             !- Pipe Outer Diameter {m}",
                          "    0.00243,            !- Pipe Thickness {m}",
                          "    0.04556;            !- U-Tube Distance {m}",
                          "GroundHeatExchanger:Vertical:Array,",
                          "    GHE-Array,          !- Name",
                          "    GHE-1 Props,        !- GHE Properties",
                          "    2,                  !- Number of Boreholes in X Direction",
                          "    2,                  !- Number of Boreholes in Y Direction",
                          "    2;                  !- Borehole Spacing {m}",
                          "GroundHeatExchanger:System,",
                          "    Vertical GHE 1x4 Std,  !- Name",
                          "    GHLE Inlet,         !- Inlet Node Name",
                          "    GHLE Outlet,        !- Outlet Node Name",
                          "    0.0007571,          !- Design Flow Rate {m3/s}",
                          "    Site:GroundTemperature:Undisturbed:KusudaAchenbach,  !- Undisturbed Ground Temperature Model Type",
                          "    KATemps,            !- Undisturbed Ground Temperature Model Name",
                          "    2.423,              !- Ground Thermal Conductivity {W/m-K}",
                          "    2.343E+06,          !- Ground Thermal Heat Capacity {J/m3-K}",
                          "    ,                   !- Response Factors Object Name",
                          "    UHFCalc,            !- g-Function Calculation Method",
                          "    ,                   !- GHE Vertical Sizing Object Type",
                          "    ,                   !- GHE Vertical Sizing Object Name",
                          "    GHE-Array;          !- GHE Array Object Name",
                          "Branch,",
                          "    Main Floor Cooling Condenser Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Coil:Cooling:WaterToAirHeatPump:EquationFit,  !- Component 1 Object Type",
                          "    Main Floor WAHP Cooling Coil,  !- Component 1 Name",
                          "    Main Floor WAHP Cooling Water Inlet Node,  !- Component 1 Inlet Node Name",
                          "    Main Floor WAHP Cooling Water Outlet Node;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Main Floor Heating Condenser Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Coil:Heating:WaterToAirHeatPump:EquationFit,  !- Component 1 Object Type",
                          "    Main Floor WAHP Heating Coil,  !- Component 1 Name",
                          "    Main Floor WAHP Heating Water Inlet Node,  !- Component 1 Inlet Node Name",
                          "    Main Floor WAHP Heating Water Outlet Node;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    GHE-Vert Branch,         !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    GroundHeatExchanger:System,  !- Component 1 Object Type",
                          "    Vertical GHE 1x4 Std,    !- Component 1 Name",
                          "    GHLE Inlet,         !- Component 1 Inlet Node Name",
                          "    GHLE Outlet;        !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Supply Inlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pump:ConstantSpeed,      !- Component 1 Object Type",
                          "    Ground Loop Supply Pump, !- Component 1 Name",
                          "    Ground Loop Supply Inlet,!- Component 1 Inlet Node Name",
                          "    Ground Loop Pump Outlet; !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Supply Outlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Supply Outlet Pipe,  !- Component 1 Name",
                          "    Ground Loop Supply Outlet Pipe Inlet,  !- Component 1 Inlet Node Name",
                          "    Ground Loop Supply Outlet;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Demand Inlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Demand Inlet Pipe,  !- Component 1 Name",
                          "    Ground Loop Demand Inlet,!- Component 1 Inlet Node Name",
                          "    Ground Loop Demand Inlet Pipe Outlet;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Demand Bypass Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Demand Side Bypass Pipe,  !- Component 1 Name",
                          "    Ground Loop Demand Bypass Inlet,  !- Component 1 Inlet Node Name",
                          "    Ground Loop Demand Bypass Outlet;  !- Component 1 Outlet Node Name",
                          "Branch,",
                          "    Ground Loop Demand Outlet Branch,  !- Name",
                          "    ,                        !- Pressure Drop Curve Name",
                          "    Pipe:Adiabatic,          !- Component 1 Object Type",
                          "    Ground Loop Demand Outlet Pipe,  !- Component 1 Name",
                          "    Ground Loop Demand Outlet Pipe Inlet,  !- Component 1 Inlet Node Name",
                          "    Ground Loop Demand Outlet;  !- Component 1 Outlet Node Name",
                          "BranchList,",
                          "    Ground Loop Supply Side Branches,  !- Name",
                          "    Ground Loop Supply Inlet Branch,  !- Branch 1 Name",
                          "    GHE-Vert Branch,         !- Branch 2 Name",
                          "    Ground Loop Supply Outlet Branch;  !- Branch 3 Name",
                          "BranchList,",
                          "    Ground Loop Demand Side Branches,  !- Name",
                          "    Ground Loop Demand Inlet Branch,  !- Branch 1 Name",
                          "    Main Floor Cooling Condenser Branch,  !- Branch 2 Name",
                          "    Main Floor Heating Condenser Branch,  !- Branch 3 Name",
                          "    Ground Loop Demand Bypass Branch,  !- Branch 4 Name",
                          "    Ground Loop Demand Outlet Branch;  !- Branch 5 Name",
                          "Connector:Splitter,",
                          "    Ground Loop Supply Splitter,  !- Name",
                          "    Ground Loop Supply Inlet Branch,  !- Inlet Branch Name",
                          "    GHE-Vert Branch;         !- Outlet Branch 1 Name",
                          "Connector:Splitter,",
                          "    Ground Loop Demand Splitter,  !- Name",
                          "    Ground Loop Demand Inlet Branch,  !- Inlet Branch Name",
                          "    Ground Loop Demand Bypass Branch,  !- Outlet Branch 1 Name",
                          "    Main Floor Cooling Condenser Branch,  !- Outlet Branch 2 Name",
                          "    Main Floor Heating Condenser Branch;  !- Outlet Branch 3 Name",
                          "Connector:Mixer,",
                          "    Ground Loop Supply Mixer,!- Name",
                          "    Ground Loop Supply Outlet Branch,  !- Outlet Branch Name",
                          "    GHE-Vert Branch;         !- Inlet Branch 1 Name",
                          "Connector:Mixer,",
                          "    Ground Loop Demand Mixer,!- Name",
                          "    Ground Loop Demand Outlet Branch,  !- Outlet Branch Name",
                          "    Ground Loop Demand Bypass Branch,  !- Inlet Branch 1 Name",
                          "    Main Floor Cooling Condenser Branch,  !- Inlet Branch 2 Name",
                          "    Main Floor Heating Condenser Branch;  !- Inlet Branch 3 Name",
                          "ConnectorList,",
                          "    Ground Loop Supply Side Connectors,  !- Name",
                          "    Connector:Splitter,      !- Connector 1 Object Type",
                          "    Ground Loop Supply Splitter,  !- Connector 1 Name",
                          "    Connector:Mixer,         !- Connector 2 Object Type",
                          "    Ground Loop Supply Mixer;!- Connector 2 Name",
                          "ConnectorList,",
                          "    Ground Loop Demand Side Connectors,  !- Name",
                          "    Connector:Splitter,      !- Connector 1 Object Type",
                          "    Ground Loop Demand Splitter,  !- Connector 1 Name",
                          "    Connector:Mixer,         !- Connector 2 Object Type",
                          "    Ground Loop Demand Mixer;!- Connector 2 Name",
                          "NodeList,",
                          "    Ground Loop Supply Setpoint Nodes,  !- Name",
                          "    GHLE Outlet,                        !- Node 1 Name",
                          "    Ground Loop Supply Outlet;  !- Node 2 Name",
                          "OutdoorAir:Node,",
                          "    Main Floor WAHP Outside Air Inlet,  !- Name",
                          "    -1;                      !- Height Above Ground {m}",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Supply Outlet Pipe,  !- Name",
                          "    Ground Loop Supply Outlet Pipe Inlet,  !- Inlet Node Name",
                          "    Ground Loop Supply Outlet;  !- Outlet Node Name",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Demand Inlet Pipe,  !- Name",
                          "    Ground Loop Demand Inlet,!- Inlet Node Name",
                          "    Ground Loop Demand Inlet Pipe Outlet;  !- Outlet Node Name",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Demand Side Bypass Pipe,  !- Name",
                          "    Ground Loop Demand Bypass Inlet,  !- Inlet Node Name",
                          "    Ground Loop Demand Bypass Outlet;  !- Outlet Node Name",
                          "Pipe:Adiabatic,",
                          "    Ground Loop Demand Outlet Pipe,  !- Name",
                          "    Ground Loop Demand Outlet Pipe Inlet,  !- Inlet Node Name",
                          "    Ground Loop Demand Outlet;  !- Outlet Node Name",
                          "Pump:ConstantSpeed,",
                          "    Ground Loop Supply Pump, !- Name",
                          "    Ground Loop Supply Inlet,!- Inlet Node Name",
                          "    Ground Loop Pump Outlet, !- Outlet Node Name",
                          "    autosize,                !- Design Flow Rate {m3/s}",
                          "    179352,                  !- Design Pump Head {Pa}",
                          "    autosize,                !- Design Power Consumption {W}",
                          "    0.9,                     !- Motor Efficiency",
                          "    0,                       !- Fraction of Motor Inefficiencies to Fluid Stream",
                          "    Intermittent;            !- Pump Control Type",
                          "PlantLoop,",
                          "    Ground Loop Water Loop,  !- Name",
                          "    Water,                      !- Fluid Type",
                          "    ,                           !- User Defined Fluid Type",
                          "    Only Water Loop Operation,  !- Plant Equipment Operation Scheme Name",
                          "    Ground Loop Supply Outlet,  !- Loop Temperature Setpoint Node Name",
                          "    100,                     !- Maximum Loop Temperature {C}",
                          "    10,                      !- Minimum Loop Temperature {C}",
                          "    autosize,                !- Maximum Loop Flow Rate {m3/s}",
                          "    0,                       !- Minimum Loop Flow Rate {m3/s}",
                          "    autosize,                !- Plant Loop Volume {m3}",
                          "    Ground Loop Supply In
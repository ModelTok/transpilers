from lib_wind_obos_cable_vessel import cable, cableFamily, vessel
from memory import Pointer
from utils import String
from vector import DynamicVector

@value
struct cable:
    var cost: Float64
    var area: Float64
    var mass: Float64
    var voltage: Float64
    var currRating: Float64
    var turbInterfaceCost: Float64
    var subsInterfaceCost: Float64

    def __init__(inout self):
        self.cost = 0.0
        self.area = 0.0
        self.mass = 0.0
        self.voltage = 0.0
        self.currRating = 0.0
        self.turbInterfaceCost = 0.0
        self.subsInterfaceCost = 0.0

    def __init__(inout self, obj: cable):
        self.cost = obj.cost
        self.area = obj.area
        self.mass = obj.mass
        self.voltage = obj.voltage
        self.currRating = obj.currRating
        self.turbInterfaceCost = obj.turbInterfaceCost
        self.subsInterfaceCost = obj.subsInterfaceCost

@value
struct cableFamily:
    var cables: DynamicVector[cable]
    var voltage: Float64
    var initializeFlag: Bool

    def __init__(inout self):
        self.voltage = 0.0
        self.initializeFlag = False

    def __init__(inout self, obj: cableFamily):
        self.voltage = obj.voltage
        self.cables = DynamicVector[cable]()
        self.cables.resize(len(obj.cables))
        for k in range(len(self.cables)):
            self.cables[k] = cable(obj.cables[k])
        self.initializeFlag = True

    def initialize_cables(inout self, ncable: Int):
        self.cables.resize(ncable)
        for k in range(ncable):
            self.cables[k] = cable()
        self.initializeFlag = True

    def check_size(inout self, nval: Int):
        var msg: String = "Size mismatch: " + str(len(self.cables)) + " vs " + str(nval)
        if not self.initializeFlag:
            self.initialize_cables(nval)
        elif len(self.cables) != nval:
            raise Error(msg)

    def set_voltage(inout self, inVolt: Float64):
        self.voltage = inVolt
        if self.initializeFlag:
            for k in range(len(self.cables)):
                self.cables[k].voltage = inVolt

    def set_all_cost(inout self, inVal: DynamicVector[Float64]):
        self.check_size(len(inVal))
        for k in range(len(self.cables)):
            self.cables[k].cost = inVal[k]

    def set_all_area(inout self, inVal: DynamicVector[Float64]):
        self.check_size(len(inVal))
        for k in range(len(self.cables)):
            self.cables[k].area = inVal[k]

    def set_all_mass(inout self, inVal: DynamicVector[Float64]):
        self.check_size(len(inVal))
        for k in range(len(self.cables)):
            self.cables[k].mass = inVal[k]

    def set_all_current_rating(inout self, inVal: DynamicVector[Float64]):
        self.check_size(len(inVal))
        for k in range(len(self.cables)):
            self.cables[k].currRating = inVal[k]

    def set_all_turbine_interface_cost(inout self, inVal: DynamicVector[Float64]):
        self.check_size(len(inVal))
        for k in range(len(self.cables)):
            self.cables[k].turbInterfaceCost = inVal[k]

    def set_all_substation_interface_cost(inout self, inVal: DynamicVector[Float64]):
        self.check_size(len(inVal))
        for k in range(len(self.cables)):
            self.cables[k].subsInterfaceCost = inVal[k]

enum VesselType:
    LEG_STABILIZED_CRANE = 1
    MID_HEIGHT_MID_SIZED_JACKUP = 2
    MID_HEIGHT_LARGE_SIZED_JACKUP = 3
    HIGH_HEIGHT_MID_SIZED_JACKUP = 4
    HIGH_HEIGHT_LARGE_SIZED_JACKUP = 5
    SHEAR_LEG_CRANE = 6
    DERRICK_CRANE = 7
    SEMISUBMERSIBLE_CRANE = 8
    HEAVY_LIFT_CARGO = 9
    SMALL_AHST = 10
    MEDIUM_AHST = 11
    LARGE_AHST = 12
    MEDIUM_ARRAY_CABLE_LAY_BARGE = 13
    LARGE_ARRAY_CABLE_LAY_BARGE = 14
    MEDIUM_ARRAY_CABLE_LAY = 15
    LARGE_ARRAY_CABLE_LAY = 16
    MEDIUM_EXPORT_CABLE_LAY_BARGE = 17
    LARGE_EXPORT_CABLE_LAY_BARGE = 18
    MEDIUM_EXPORT_CABLE_LAY = 19
    LARGE_EXPORT_CABLE_LAY = 20
    MEDIUM_JACKUP_BARGE = 21
    LARGE_JACKUP_BARGE = 22
    MEDIUM_JACKUP_BARGE_WITH_CRANE = 23
    LARGE_JACKUP_BARGE_WITH_CRANE = 24
    SMALL_BARGE = 25
    MEDIUM_BARGE = 26
    LARGE_BARGE = 27
    SEA_GOING_SUPPORT_TUG = 28
    HOTEL = 29
    MOTHER_SHIP = 30
    PERSONNEL_TRANSPORT = 31
    DIVE_SUPPORT = 32
    GUARD = 33
    SEMISUBMERSIBLE_CARGO_BARGE = 34
    BACKHOE_DREDGER = 36
    GRAB_OR_CLAMSHELL_DREDGER = 37
    FALL_PIPE_OR_TRAILING_SUCTION_DREDGER = 38
    SIDE_ROCK_DUMPER = 39
    BALLASTING = 40
    BALLAST_HOPPER = 41
    ENVIRONMENTAL_SURVEY = 42
    GEOPHYSICAL_SURVEY = 43
    GEOTECHNICAL_SURVEY = 44

@value
struct vessel:
    var identifier: Float64
    var length: Float64
    var breadth: Float64
    var draft: Float64
    var operational_depth: Float64
    var leg_length: Float64
    var jackup_speed: Float64
    var deck_space: Float64
    var payload: Float64
    var lift_capacity: Float64
    var lift_height: Float64
    var transit_speed: Float64
    var max_wind_speed: Float64
    var max_wave_height: Float64
    var day_rate: Float64
    var mobilization_time: Float64
    var number_of_vessels: Float64
    var accomodation: Float64
    var crew: Float64
    var passengers: Float64
    var bollard_pull: Float64
    var tow_speed: Float64
    var carousel_weight: Float64
    var spud_depth: Float64
    var dredge_depth: Float64
    var bucket_size: Float64
    var grabber_size: Float64
    var hopper_size: Float64

    def __init__(inout self):
        self.identifier = 0.0
        self.length = 0.0
        self.breadth = 0.0
        self.draft = 0.0
        self.operational_depth = 0.0
        self.leg_length = 0.0
        self.jackup_speed = 0.0
        self.deck_space = 0.0
        self.payload = 0.0
        self.lift_capacity = 0.0
        self.lift_height = 0.0
        self.transit_speed = 0.0
        self.max_wind_speed = 0.0
        self.max_wave_height = 0.0
        self.day_rate = 0.0
        self.mobilization_time = 0.0
        self.number_of_vessels = 0.0
        self.accomodation = 0.0
        self.crew = 0.0
        self.passengers = 0.0
        self.bollard_pull = 0.0
        self.tow_speed = 0.0
        self.carousel_weight = 0.0
        self.spud_depth = 0.0
        self.dredge_depth = 0.0
        self.bucket_size = 0.0
        self.grabber_size = 0.0
        self.hopper_size = 0.0

    def __init__(inout self, obj: vessel):
        self.identifier = obj.identifier
        self.length = obj.length
        self.breadth = obj.breadth
        self.draft = obj.draft
        self.operational_depth = obj.operational_depth
        self.leg_length = obj.leg_length
        self.jackup_speed = obj.jackup_speed
        self.deck_space = obj.deck_space
        self.payload = obj.payload
        self.lift_capacity = obj.lift_capacity
        self.lift_height = obj.lift_height
        self.transit_speed = obj.transit_speed
        self.max_wind_speed = obj.max_wind_speed
        self.max_wave_height = obj.max_wave_height
        self.day_rate = obj.day_rate
        self.mobilization_time = obj.mobilization_time
        self.number_of_vessels = obj.number_of_vessels
        self.accomodation = obj.accomodation
        self.crew = obj.crew
        self.passengers = obj.passengers
        self.bollard_pull = obj.bollard_pull
        self.tow_speed = obj.tow_speed
        self.carousel_weight = obj.carousel_weight
        self.spud_depth = obj.spud_depth
        self.dredge_depth = obj.dredge_depth
        self.bucket_size = obj.bucket_size
        self.grabber_size = obj.grabber_size
        self.hopper_size = obj.hopper_size

    def get_rate(self) -> Float64:
        return (self.day_rate * self.number_of_vessels)

    def get_mobilization_cost(self) -> Float64:
        return (self.get_rate() * self.mobilization_time)
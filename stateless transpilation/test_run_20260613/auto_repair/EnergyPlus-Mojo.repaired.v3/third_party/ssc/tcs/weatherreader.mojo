# This is a faithful 1:1 translation of third_party/ssc/tcs/weatherreader.cpp to Mojo.
# No refactoring has been applied.

# #define _TCSTYPEINTERFACE_
from tcstype import *  # assume tcstype.h translates to tcstype.mojo
from shared.lib_weatherfile import *  # weatherfile, weather_header, weather_record
from shared.lib_irradproc import *   # solarpos, incidence, perez

# #ifndef M_PI
# #define M_PI 3.14159265358979323
# #endif
alias M_PI = 3.14159265358979323

enum WeatherReaderEnum:
    P_FILENAME = 0
    P_TRACKMODE = 1
    P_TILT = 2
    P_AZIMUTH = 3
    O_YEAR = 4
    O_MONTH = 5
    O_DAY = 6
    O_HOUR = 7
    O_MINUTE = 8
    O_GLOBAL = 9
    O_BEAM = 10
    O_DIFFUSE = 11
    O_TDRY = 12
    O_TWET = 13
    O_TDEW = 14
    O_WSPD = 15
    O_WDIR = 16
    O_RHUM = 17
    O_PRES = 18
    O_SNOW = 19
    O_ALBEDO = 20
    O_POA = 21
    O_SOLAZI = 22
    O_SOLZEN = 23
    O_LAT = 24
    O_LON = 25
    O_TZ = 26
    O_SHIFT = 27
    O_ELEV = 28
    D_POABEAM = 29
    D_POADIFF = 30
    D_POAGND = 31
    N_MAX = 32

struct tcsvarinfo:
    var direction: Int
    var datatype: Int
    var index: Int
    var name: String
    var label: String
    var units: String
    var group: String
    var meta: String
    var defaultvalue: String

var weatherreader_variables: StaticArray[tcsvarinfo, N_MAX] = [
    tcsvarinfo(TCS_PARAM, TCS_STRING, P_FILENAME, "file_name", "Weather file name on local computer", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TRACKMODE,"track_mode", "Tracking mode for surface", "0..2", "Proc", "0=fixed,1=1axis,2=2axis", "0"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TILT, "tilt", "Tilt angle of surface/axis", "deg", "Proc", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_AZIMUTH, "azimuth", "Azimuth angle of surface/axis", "deg", "Proc", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_YEAR, "year", "Year", "yr", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_MONTH, "month", "Month", "mn", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DAY, "day", "Day", "dy", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_HOUR, "hour", "Hour", "hr", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_MINUTE, "minute", "Minute", "mi", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_GLOBAL, "global", "Global horizontal irradiance", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_BEAM, "beam", "Beam normal irradiance", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DIFFUSE, "diff", "Diffuse horizontal irradiance", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TDRY, "tdry", "Dry bulb temperature", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TWET, "twet", "Wet bulb temperature", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TDEW, "tdew", "Dew point temperature", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_WSPD, "wspd", "Wind speed", "m/s", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_WDIR, "wdir", "Wind direction", "deg", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_RHUM, "rhum", "Relative humidity", "%", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_PRES, "pres", "Pressure", "mbar", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SNOW, "snow", "Snow cover", "cm", "Meteo", "valid (0,150)", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ALBEDO, "albedo", "Ground albedo", "0..1", "Meteo", "valid (0,1)", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_POA, "poa", "Plane-of-array total incident irradiance", "W/m2", "Irrad", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLAZI, "solazi", "Solar Azimuth", "deg", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLZEN, "solzen", "Solar Zenith", "deg", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_LAT, "lat", "Latitude", "DDD", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_LON, "lon", "Longitude", "DDD", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TZ, "tz", "Timezone", "DDD", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SHIFT, "shift", "shift in longitude from local standard meridian", "deg", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ELEV, "elev", "Site elevation", "m", "Meteo", "", ""),
    tcsvarinfo(TCS_DEBUG, TCS_NUMBER, D_POABEAM, "poa_beam", "Plane-of-array beam irradiance", "W/m2", "Irrad", "", ""),
    tcsvarinfo(TCS_DEBUG, TCS_NUMBER, D_POADIFF, "poa_diff", "Plane-of-array diffuse irradiance", "W/m2", "Irrad", "", ""),
    tcsvarinfo(TCS_DEBUG, TCS_NUMBER, D_POAGND, "poa_gnd", "Plane-of-array ground irradiance", "W/m2", "Irrad", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, "", "", "", "", "", "")
]

class weatherreader(tcstypeinterface):
    var m_wfile: weatherfile
    var m_hdr: weather_header
    var m_rec: weather_record
    var m_first: Bool  #flag to indicate whether this is the first call

    def __init__(self, cxt: tcscontext, ti: tcstypeinfo):
        super().__init__(cxt, ti)

    def __dealloc__(self):
        # implicit destructor call in Mojo, nothing special needed

    def init(self) -> Int:
        var file: String = self.value_str(P_FILENAME)
        if not self.m_wfile.open(file):
            self.message(TCS_ERROR, String.format("could not open %s for reading", file))
            return -1
        self.m_wfile.header(&self.m_hdr)
        self.m_first = True  #True the first time call() is accessed
        return 0  # success

    def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
        if ncall == 0:  # only read data values once per timestep
            var nread: Int = 1
            if self.m_first:
                nread = Int(time / step)
                self.m_first = False
            for i in range(nread):  #for all calls except the first, nread=1
                if not self.m_wfile.read(&self.m_rec):
                    self.message(TCS_ERROR, String.format("failed to read from weather file %s at time %lg", self.m_wfile.filename(), time))
                    return -1  # error code

        var trackmode: Int = Int(self.value(P_TRACKMODE))
        if trackmode < 0 or trackmode > 2:
            self.message(TCS_ERROR, String.format("invalid tracking mode specified %d [0..2]", trackmode))
            return -1

        var tilt: Float64 = self.value(P_TILT)
        var azimuth: Float64 = self.value(P_AZIMUTH)

        var sunn: StaticArray[Float64, 9]
        var angle: StaticArray[Float64, 5]
        var poa: StaticArray[Float64, 3]
        var diffc: StaticArray[Float64, 3]

        poa[0] = 0.0
        poa[1] = 0.0
        poa[2] = 0.0
        angle[0] = 0.0
        angle[1] = 0.0
        angle[2] = 0.0
        angle[3] = 0.0
        angle[4] = 0.0
        diffc[0] = 0.0
        diffc[1] = 0.0
        diffc[2] = 0.0

        solarpos(self.m_rec.year, self.m_rec.month, self.m_rec.day, self.m_rec.hour, self.m_rec.minute,
                 self.m_hdr.lat, self.m_hdr.lon, self.m_hdr.tz, sunn)

        if sunn[2] > 0.0087:
            # sun elevation > 0.5 degrees
            incidence(trackmode, tilt, azimuth, 45.0, sunn[1], sunn[0], 0, 0, angle)
            perez(sunn[8], self.m_rec.dn, self.m_rec.df, 0.2, angle[0], angle[1], sunn[1], poa, diffc)

        self.value(O_YEAR, self.m_rec.year)
        self.value(O_MONTH, self.m_rec.month)
        self.value(O_DAY, self.m_rec.day)
        self.value(O_HOUR, self.m_rec.hour)
        self.value(O_MINUTE, self.m_rec.minute)
        self.value(O_GLOBAL, self.m_rec.gh)
        self.value(O_BEAM, self.m_rec.dn)
        self.value(O_DIFFUSE, self.m_rec.df)
        self.value(O_TDRY, self.m_rec.tdry)
        self.value(O_TWET, self.m_rec.twet)
        self.value(O_TDEW, self.m_rec.tdew)
        self.value(O_WSPD, self.m_rec.wspd)
        self.value(O_WDIR, self.m_rec.wdir)
        self.value(O_RHUM, self.m_rec.rhum)
        self.value(O_PRES, self.m_rec.pres)
        self.value(O_SNOW, self.m_rec.snow)
        self.value(O_ALBEDO, self.m_rec.alb)
        self.value(O_POA, poa[0] + poa[1] + poa[2])
        self.value(O_SOLAZI, sunn[0] * 180 / M_PI)
        self.value(O_SOLZEN, sunn[1] * 180 / M_PI)
        self.value(O_LAT, self.m_hdr.lat)
        self.value(O_LON, self.m_hdr.lon)
        self.value(O_TZ, self.m_hdr.tz)
        self.value(O_SHIFT, (self.m_hdr.lon - self.m_hdr.tz * 15.0))
        self.value(O_ELEV, self.m_hdr.elev)
        self.value(D_POABEAM, poa[0])
        self.value(D_POADIFF, poa[1])
        self.value(D_POAGND, poa[2])

        return 0  # success

# TCS_IMPLEMENT_TYPE( weatherreader, "Standard Weather File format reader", "Aron Dobos", 1, weatherreader_variables, NULL, 0 )
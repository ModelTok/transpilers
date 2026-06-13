from TypeDefs import Real64
from python import time

struct DurationType:
    var ms: Int

    def __init__(inout self, ms: Int = 0):
        self.ms = ms

    def count(self) -> Int:
        return self.ms

    def __add__(self, other: DurationType) -> DurationType:
        return DurationType(self.ms + other.ms)

alias TimePointType = Int

def now() -> TimePointType:
    return Int(time.time() * 1000.0)

struct Timer:
    var m_start: TimePointType
    var m_end: TimePointType
    var m_duration: DurationType

    def __init__(inout self):
        self.m_start = 0
        self.m_end = 0
        self.m_duration = DurationType(0)

    def duration(self) -> DurationType:
        // #ifndef NDEBUG
        if self.m_end == 0:
            raise Exception("Timer was not stopped")
        // #endif
        return self.m_duration

    def tick(inout self):
        self.m_end = 0
        self.m_start = now()

    def tock(inout self):
        // #ifndef NDEBUG
        if self.m_start == 0:
            raise Exception("Timer was not started")
        // #endif
        self.m_end = now()
        self.m_duration = self.m_duration + DurationType(self.m_end - self.m_start)

    def formatAsHourMinSecs(self) -> String:
        var count = self.duration().count()
        var Hours = count // 3600000
        count -= Hours * 3600000
        var Minutes = count // 60000
        count -= Minutes * 60000
        var Seconds = count / 1000.0
        if Seconds < 0.0:
            Seconds = 0.0
        return f"{Hours:02d}hr {Minutes:02d}min {Seconds:5.2f}sec"

    def elapsedSeconds(self) -> Real64:
        return self.duration().count() / 1000.0
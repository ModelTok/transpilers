from time import perf_counter

alias Real64 = Float64

struct Timer:
    """A restartable Timer (stopwatch) with formatting convenience functions"""
    
    var m_start: Float64
    var m_end: Float64
    var m_duration: Float64
    
    fn __init__(inout self):
        self.m_start = -1.0
        self.m_end = -1.0
        self.m_duration = 0.0
    
    fn tick(inout self):
        """Reset start to now, end to none"""
        self.m_end = -1.0
        self.m_start = perf_counter() * 1000.0
    
    fn tock(inout self):
        """Capture end time, add to duration"""
        if self.m_start < 0.0:
            raise Error("Timer was not started")
        self.m_end = perf_counter() * 1000.0
        self.m_duration += self.m_end - self.m_start
    
    fn duration(self) -> Float64:
        """Returns duration in milliseconds"""
        if self.m_end < 0.0:
            raise Error("Timer was not stopped")
        return self.m_duration
    
    fn format_as_hour_min_secs(self) -> String:
        """Format duration as HHhr MMmin SS.SSsec"""
        var count = int(self.duration())
        
        var hours = count // 3600000
        count -= hours * 3600000
        
        var minutes = count // 60000
        count -= minutes * 60000
        var seconds = count / 1000.0
        
        if seconds < 0.0:
            seconds = 0.0
        
        var h_str = String(hours) if hours >= 10 else "0" + String(hours)
        var m_str = String(minutes) if minutes >= 10 else "0" + String(minutes)
        
        return h_str + "hr " + m_str + "min " + _format_seconds(seconds) + "sec"
    
    fn elapsed_seconds(self) -> Real64:
        return self.duration() / 1000.0

fn _format_seconds(seconds: Float64) -> String:
    var multiplier: Float64 = 100.0
    var rounded = int(seconds * multiplier) / multiplier
    var s = String(rounded)
    if s.find(".") == -1:
        s += ".00"
    return s

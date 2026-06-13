import time
from typing import Optional

Real64 = float

class Timer:
    """A restartable Timer (stopwatch) with formatting convenience functions"""
    
    def __init__(self):
        self.m_start: Optional[float] = None
        self.m_end: Optional[float] = None
        self.m_duration: float = 0.0
    
    def tick(self) -> None:
        """Reset start to now, end to none"""
        self.m_end = None
        self.m_start = time.time() * 1000.0
    
    def tock(self) -> None:
        """Capture end time, add to duration"""
        if self.m_start is None:
            raise RuntimeError("Timer was not started")
        self.m_end = time.time() * 1000.0
        self.m_duration += self.m_end - self.m_start
    
    def duration(self) -> float:
        """Returns duration in milliseconds"""
        if self.m_end is None:
            raise RuntimeError("Timer was not stopped")
        return self.m_duration
    
    def format_as_hour_min_secs(self) -> str:
        """Format duration as HHhr MMmin SS.SSsec"""
        count = int(self.duration())
        
        hours = count // 3600000
        count -= hours * 3600000
        
        minutes = count // 60000
        count -= minutes * 60000
        seconds = count / 1000.0
        
        if seconds < 0.0:
            seconds = 0.0
        
        return f"{hours:02d}hr {minutes:02d}min {seconds:5.2f}sec"
    
    def elapsed_seconds(self) -> Real64:
        return self.duration() / 1000.0

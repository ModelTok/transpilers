# EXTERNAL DEPS (to wire in glue):
# - IIGUSystem: trait from IGUConfigurations
# - System: enum from IGUConfigurations
# - Environment: enum from IGUConfigurations

enum System:
    NONE = 0


enum Environment:
    NONE = 0


trait IIGUSystem:
    fn getUValue(self) -> Float64:
        ...
    
    fn getSHGC(self, t_TotSol: Float64) -> Float64:
        ...
    
    fn getH(self, system: System, environment: Environment) -> Float64:
        ...
    
    fn setWidth(inout self, width: Float64) -> None:
        ...
    
    fn setHeight(inout self, height: Float64) -> None:
        ...
    
    fn setTilt(inout self, tilt: Float64) -> None:
        ...
    
    fn setWidthAndHeight(inout self, width: Float64, height: Float64) -> None:
        ...
    
    fn setInteriorAndExteriorSurfacesHeight(inout self, height: Float64) -> None:
        ...


struct SimpleIGU(IIGUSystem):
    var m_UValue: Float64
    var m_SHGC: Float64
    var m_H: Float64
    
    fn __init__(inout self, uValue: Float64, shgc: Float64, h: Float64):
        self.m_UValue = uValue
        self.m_SHGC = shgc
        self.m_H = h
    
    fn getUValue(self) -> Float64:
        return self.m_UValue
    
    fn getSHGC(self, t_TotSol: Float64) -> Float64:
        return self.m_SHGC
    
    fn getH(self, system: System, environment: Environment) -> Float64:
        return self.m_H
    
    fn setWidth(inout self, width: Float64) -> None:
        pass
    
    fn setHeight(inout self, height: Float64) -> None:
        pass
    
    fn setTilt(inout self, tilt: Float64) -> None:
        pass
    
    fn setWidthAndHeight(inout self, width: Float64, height: Float64) -> None:
        pass
    
    fn setInteriorAndExteriorSurfacesHeight(inout self, height: Float64) -> None:
        pass

from memory import pointer
from math import abs, cos, sin, pow, max
from WCEGases import *
from WCECommon import *

@value
struct CNusseltNumberStrategy:
    def pos(self, t_Value: Float64) -> Float64:
        return (t_Value + abs(t_Value)) / 2

    def calculate(self, t_Tilt: Float64, t_Ra: Float64, t_Asp: Float64) -> Float64:
        return 0

@value
struct CNusseltNumber0To60(CNusseltNumberStrategy):
    def calculate(self, t_Tilt: Float64, t_Ra: Float64, t_Asp: Float64) -> Float64:
        var subNu1 = 1 - 1708 / (t_Ra * cos(t_Tilt))
        subNu1 = self.pos(subNu1)
        const subNu2 = 1 - (1708 * pow(sin(1.8 * t_Tilt), 1.6)) / (t_Ra * cos(t_Tilt))
        var subNu3 = pow(t_Ra * cos(t_Tilt) / 5830, 1 / 3.0) - 1
        subNu3 = self.pos(subNu3)
        const gnu = 1 + 1.44 * subNu1 * subNu2 + subNu3
        return gnu

@value
struct CNusseltNumber60(CNusseltNumberStrategy):
    def calculate(self, t_Tilt: Float64, t_Ra: Float64, t_Asp: Float64) -> Float64:
        var G = 0.5 / pow(1 + pow(t_Ra / 3160, 20.6), 0.1)
        const Nu1 = pow(1 + pow(0.0936 * pow(t_Ra, 0.314) / (1 + G), 7), 0.1428571)
        const Nu2 = (0.104 + 0.175 / t_Asp) * pow(t_Ra, 0.283)
        const gnu = max(Nu1, Nu2)
        return gnu

@value
struct CNusseltNumber60To90(CNusseltNumberStrategy):
    def calculate(self, t_Tilt: Float64, t_Ra: Float64, t_Asp: Float64) -> Float64:
        const nusselt60 = CNusseltNumber60()
        const Nu60 = nusselt60.calculate(t_Tilt, t_Ra, t_Asp)
        const nusselt90 = CNusseltNumber90()
        const Nu90 = nusselt90.calculate(t_Tilt, t_Ra, t_Asp)
        const gnu = ((Nu90 - Nu60) / (90.0 - 60.0)) * (t_Tilt * 180 / WCE_PI - 60.0) + Nu60
        return gnu

@value
struct CNusseltNumber90(CNusseltNumberStrategy):
    def calculate(self, t_Tilt: Float64, t_Ra: Float64, t_Asp: Float64) -> Float64:
        var Nu1 = 0.0
        var Nu2 = 0.242 * pow(t_Ra / t_Asp, 0.272)
        if t_Ra > 5e4:
            Nu1 = 0.0673838 * pow(t_Ra, 1 / 3.0)
        elif (t_Ra > 1e4) and (t_Ra < 5e4):
            Nu1 = 0.028154 * pow(t_Ra, 0.4134)
        elif t_Ra < 1e4:
            Nu1 = 1 + 1.7596678e-10 * pow(t_Ra, 2.2984755)
        var gnu = max(Nu1, Nu2)
        return gnu

@value
struct CNusseltNumber90to180(CNusseltNumberStrategy):
    def calculate(self, t_Tilt: Float64, t_Ra: Float64, t_Asp: Float64) -> Float64:
        const nusselt90 = CNusseltNumber90()
        const Nu90 = nusselt90.calculate(t_Tilt, t_Ra, t_Asp)
        const gnu = 1 + (Nu90 - 1) * sin(t_Tilt)
        return gnu

@value
struct CNusseltNumber:
    def calculate(self, t_Tilt: Float64, t_Ra: Float64, t_Asp: Float64) -> Float64:
        const tiltRadians = t_Tilt * WCE_PI / 180
        var nusseltNumber: CNusseltNumberStrategy
        if t_Tilt >= 0 and t_Tilt < 60:
            nusseltNumber = CNusseltNumber0To60()
        elif t_Tilt == 60:
            nusseltNumber = CNusseltNumber60()
        elif t_Tilt > 60 and t_Tilt < 90:
            nusseltNumber = CNusseltNumber60To90()
        elif t_Tilt == 90:
            nusseltNumber = CNusseltNumber90()
        elif t_Tilt > 90 and t_Tilt <= 180:
            nusseltNumber = CNusseltNumber90to180()
        else:
            raise Error("Window tilt angle is out of range.")
        return nusseltNumber.calculate(tiltRadians, t_Ra, t_Asp)
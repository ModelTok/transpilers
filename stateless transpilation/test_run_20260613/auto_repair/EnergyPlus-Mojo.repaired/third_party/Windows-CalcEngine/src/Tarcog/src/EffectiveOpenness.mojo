from WCECommon import ConstantsData

struct ShadeOpenness:
    var Ah: Float64
    var Dl: Float64
    var Dr: Float64
    var Dtop: Float64
    var Dbot: Float64

    def __init__(self, ah: Float64, dl: Float64, dr: Float64, dtop: Float64, dbot: Float64):
        self.Ah = ah
        self.Dl = dl
        self.Dr = dr
        self.Dtop = dtop
        self.Dbot = dbot

struct EffectiveOpenness:
    var Ah: Float64
    var Al: Float64
    var Ar: Float64
    var Atop: Float64
    var Abot: Float64
    var FrontPorosity: Float64

    def __init__(self, ah: Float64, al: Float64, ar: Float64, atop: Float64, abot: Float64, frontPorosity: Float64):
        self.Ah = ah
        self.Al = al
        self.Ar = ar
        self.Atop = atop
        self.Abot = abot
        self.FrontPorosity = frontPorosity

    def isClosed(self) -> Bool:
        return self.Ah == 0.0 and self.Al == 0.0 and self.Ar == 0.0 and self.Atop == 0.0 and self.Abot == 0.0 and self.FrontPorosity == 0.0

struct Coefficients:
    var C1: Float64
    var C2: Float64
    var C3: Float64
    var C4: Float64

    def __init__(self, c1: Float64, c2: Float64, c3: Float64, c4: Float64):
        self.C1 = c1
        self.C2 = c2
        self.C3 = c3
        self.C4 = c4

struct EffectiveLayer:
    var m_Width: Float64
    var m_Height: Float64
    var m_Thickness: Float64
    var m_ShadeOpenness: ShadeOpenness
    var coefficients: Coefficients

    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness, coefficients: Coefficients = Coefficients(0.0, 0.0, 0.0, 0.0)):
        self.m_Width = width
        self.m_Height = height
        self.m_Thickness = thickness
        self.m_ShadeOpenness = ShadeOpenness(openness.Ah * width * height, openness.Dl, openness.Dr, openness.Dtop, openness.Dbot)
        self.coefficients = coefficients

    def getEffectiveOpenness(self) -> EffectiveOpenness:
        # unimplemented()

    def effectiveThickness(self) -> Float64:
        # unimplemented()

struct EffectiveVenetian(EffectiveLayer):
    var m_SlatAngleRad: Float64
    var m_SlatWidth: Float64

    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness, slatAngle: Float64, slatWidth: Float64, coefficients: Coefficients):
        EffectiveLayer.__init__(self, width, height, thickness, openness, coefficients)
        self.m_SlatAngleRad = slatAngle * 2.0 * ConstantsData.WCE_PI / 360.0
        self.m_SlatWidth = slatWidth

    def getEffectiveOpenness(self) -> EffectiveOpenness:
        let area = self.m_Width * self.m_Height
        let Ah_eff = area * self.coefficients.C1 * pow(self.m_ShadeOpenness.Ah / area * pow(cos(self.m_SlatAngleRad), self.coefficients.C2), self.coefficients.C3)
        return EffectiveOpenness(Ah_eff, 0, 0, self.m_ShadeOpenness.Dtop * self.m_Width, self.m_ShadeOpenness.Dbot * self.m_Width, self.m_ShadeOpenness.Ah)

    def effectiveThickness(self) -> Float64:
        return self.coefficients.C4 * (self.m_SlatWidth * cos(self.m_SlatAngleRad) + self.m_Thickness * sin(self.m_SlatAngleRad))

struct EffectiveHorizontalVenetian(EffectiveVenetian):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness, slatAngle: Float64, slatWidth: Float64):
        EffectiveVenetian.__init__(self, width, height, thickness, openness, slatAngle, slatWidth, Coefficients(0.016, -0.63, 0.53, 0.043))

struct EffectiveVerticalVenentian(EffectiveVenetian):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness, slatAngle: Float64, slatWidth: Float64):
        EffectiveVenetian.__init__(self, width, height, thickness, openness, slatAngle, slatWidth, Coefficients(0.041, 0.0, 0.27, 0.012))

struct EffectiveLayerType1(EffectiveLayer):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness):
        EffectiveLayer.__init__(self, width, height, thickness, openness, Coefficients(0.078, 1.2, 1.0, 1.0))

    def getEffectiveOpenness(self) -> EffectiveOpenness:
        let area = self.m_Width * self.m_Height
        let Ah_eff = area * self.coefficients.C1 * pow(self.m_ShadeOpenness.Ah / area, self.coefficients.C2)
        let Al_eff = self.m_ShadeOpenness.Dl * self.m_Height * self.coefficients.C3
        let Ar_eff = self.m_ShadeOpenness.Dr * self.m_Height * self.coefficients.C3
        let Atop_eff = self.m_ShadeOpenness.Dtop * self.m_Width * self.coefficients.C4
        let Abop_eff = self.m_ShadeOpenness.Dbot * self.m_Width * self.coefficients.C4
        return EffectiveOpenness(Ah_eff, Al_eff, Ar_eff, Atop_eff, Abop_eff, self.m_ShadeOpenness.Ah)

    def effectiveThickness(self) -> Float64:
        return self.m_Thickness

struct EffectiveLayerPerforated(EffectiveLayerType1):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness):
        EffectiveLayerType1.__init__(self, width, height, thickness, openness)

struct EffectiveLayerDiffuse(EffectiveLayerType1):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness):
        EffectiveLayerType1.__init__(self, width, height, thickness, openness)

struct EffectiveLayerWoven(EffectiveLayerType1):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness):
        EffectiveLayerType1.__init__(self, width, height, thickness, openness)

struct EffectiveLayerBSDF(EffectiveLayerType1):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness):
        EffectiveLayerType1.__init__(self, width, height, thickness, openness)

struct EffectiveLayerOther(EffectiveLayer):
    def __init__(self, width: Float64, height: Float64, thickness: Float64, openness: ShadeOpenness):
        EffectiveLayer.__init__(self, width, height, thickness, openness)

    def getEffectiveOpenness(self) -> EffectiveOpenness:
        return EffectiveOpenness(self.m_ShadeOpenness.Ah, self.m_ShadeOpenness.Dl * self.m_Height, self.m_ShadeOpenness.Dr * self.m_Height, self.m_ShadeOpenness.Dtop * self.m_Width, self.m_ShadeOpenness.Dbot * self.m_Width, self.m_ShadeOpenness.Ah)

    def effectiveThickness(self) -> Float64:
        return self.m_Thickness
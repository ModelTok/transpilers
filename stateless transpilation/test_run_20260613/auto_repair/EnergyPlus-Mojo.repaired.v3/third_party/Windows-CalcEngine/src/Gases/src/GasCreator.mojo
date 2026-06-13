from GasData import CGasData

enum GasDef:
    Air
    Argon
    Krypton
    Xenon

class Gas:
    @staticmethod
    def intance() -> ref Gas:
        static var instant = Gas()
        return instant

    def get(self, gasDef: GasDef) -> CGasData:
        return self.m_Gas[gasDef]

    def __init__(self):
        self.m_Gas = {
            GasDef.Air: CGasData(
                "Air",
                28.97,
                1.4,
                (1.002737e+03, 1.2324e-02, 0.0),
                (2.8733e-03, 7.76e-05, 0.0),
                (3.7233e-06, 4.94e-08, 0.0)
            ),
            GasDef.Argon: CGasData(
                "Argon",
                39.948,
                1.67,
                (5.21929e+02, 0.0, 0.0),
                (2.2848e-03, 5.1486e-05, 0.0),
                (3.3786e-06, 6.4514e-08, 0.0)
            ),
            GasDef.Krypton: CGasData(
                "Krypton",
                83.8,
                1.68,
                (2.4809e+02, 0.0, 0.0),
                (9.443e-04, 2.8260e-5, 0.0),
                (2.213e-6, 7.777e-8, 0.0)
            ),
            GasDef.Xenon: CGasData(
                "Xenon",
                131.3,
                1.66,
                (1.5834e+02, 0.0, 0.0),
                (4.538e-04, 1.723e-05, 0.0),
                (1.069e-6, 7.414e-8, 0.0)
            )
        }

    var m_Gas: Dict[GasDef, CGasData]
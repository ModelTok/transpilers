from Eigen.EulerAngles import EulerSystem, EulerAngles, EulerAnglesZYZd
from Eigen.Geometry import AngleAxisd, Quaterniond, Vector3d
from iostream import std
alias EULER_Z = 1
alias EULER_Y = 2
alias EULER_X = 3

def main():
    alias MyArmySystem = EulerSystem[-EULER_Z, EULER_Y, EULER_X]
    alias MyArmyAngles = EulerAngles[float64, MyArmySystem]
    var vehicleAngles = MyArmyAngles(
        3.14/*PI*/ / 2, /* heading to east, notice that this angle is counter-clockwise */
        -0.3, /* going down from a mountain */
        0.1) /* slightly rolled to the right */
    var planeAngles = EulerAnglesZYZd(0.78474, 0.5271, -0.513794)
    var planeAnglesInMyArmyAngles = MyArmyAngles.FromRotation[True, False, False](planeAngles)
    std.cout << "vehicle angles(MyArmy):     " << vehicleAngles << std.endl
    std.cout << "plane angles(ZYZ):        " << planeAngles << std.endl
    std.cout << "plane angles(MyArmy):     " << planeAnglesInMyArmyAngles << std.endl
    std.cout << "==========================================================\n"
    std.cout << "rotating plane now!\n"
    std.cout << "==========================================================\n"
    var planeRotated = AngleAxisd(-0.342, Vector3d.UnitY()) * planeAngles
    planeAngles = planeRotated
    planeAnglesInMyArmyAngles = MyArmyAngles.FromRotation[True, False, False](planeRotated)
    std.cout << "new plane angles(ZYZ):     " << planeAngles << std.endl
    std.cout << "new plane angles(MyArmy): " << planeAnglesInMyArmyAngles << std.endl
    return 0
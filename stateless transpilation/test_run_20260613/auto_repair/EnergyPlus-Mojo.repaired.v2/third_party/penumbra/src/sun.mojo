/* Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from math import cos, sin, sqrt

alias vec3 = InlineArray[Float32, 3]
alias mat4x4 = InlineArray[InlineArray[Float32, 4], 4]
alias mat4x4_ptr = Pointer[InlineArray[Float32, 4]]

def mat4x4_look_at(inout m: mat4x4, eye: vec3, center: vec3, up: vec3):
    # Standard row-major look-at matrix
    var fwdX = center[0] - eye[0]
    var fwdY = center[1] - eye[1]
    var fwdZ = center[2] - eye[2]
    var fwdLen = sqrt(fwdX*fwdX + fwdY*fwdY + fwdZ*fwdZ)
    fwdX /= fwdLen; fwdY /= fwdLen; fwdZ /= fwdLen

    # side = cross(fwd, up)
    var sideX = fwdY*up[2] - fwdZ*up[1]
    var sideY = fwdZ*up[0] - fwdX*up[2]
    var sideZ = fwdX*up[1] - fwdY*up[0]
    var sideLen = sqrt(sideX*sideX + sideY*sideY + sideZ*sideZ)
    sideX /= sideLen; sideY /= sideLen; sideZ /= sideLen

    # new up = cross(side, fwd)
    var upX = sideY*fwdZ - sideZ*fwdY
    var upY = sideZ*fwdX - sideX*fwdZ
    var upZ = sideX*fwdY - sideY*fwdX

    # dot products
    var dotSE = sideX*eye[0] + sideY*eye[1] + sideZ*eye[2]
    var dotUE = upX*eye[0] + upY*eye[1] + upZ*eye[2]
    var dotFE = fwdX*eye[0] + fwdY*eye[1] + fwdZ*eye[2]

    m[0][0] = sideX; m[0][1] = sideY; m[0][2] = sideZ; m[0][3] = 0.0
    m[1][0] = upX;   m[1][1] = upY;   m[1][2] = upZ;   m[1][3] = 0.0
    m[2][0] = -fwdX; m[2][1] = -fwdY; m[2][2] = -fwdZ; m[2][3] = 0.0
    m[3][0] = -dotSE; m[3][1] = -dotUE; m[3][2] = dotFE; m[3][3] = 1.0

struct Sun:
    var view: mat4x4
    var azimuth: Float32
    var altitude: Float32

    def __init__(out self):
        self.azimuth = 0.0
        self.altitude = 0.0
        self.view = mat4x4()

    def set_azimuth(inout self, azimuth_in: Float32):
        self.azimuth = azimuth_in

    def set_altitude(inout self, altitude_in: Float32):
        self.altitude = altitude_in

    def set_view(inout self, azimuth_in: Float32, altitude_in: Float32):
        self.set_azimuth(azimuth_in)
        self.set_altitude(altitude_in)
        self.set_view()

    def get_view(inout self) -> mat4x4_ptr:
        return Pointer[InlineArray[Float32, 4]](address_of(self.view[0]))

    def get_azimuth(self) -> Float32:
        return self.azimuth

    def get_altitude(self) -> Float32:
        return self.altitude

    def set_view(inout self):
        var cosAlt: Float32 = cos(self.altitude)
        var eye: vec3 = vec3(cosAlt * sin(self.azimuth), cosAlt * cos(self.azimuth), sin(self.altitude))
        var center: vec3 = vec3(0.0, 0.0, 0.0)
        var up: vec3 = vec3(0.0, 0.0, 1.0)
        mat4x4_look_at(self.view, eye, center, up)
#!/usr/bin/env python3
"""Fill mojo_source for the two Emmel bundles (entry first, verified callee after)."""
import json
import sys

CALLEE = """\
def CalcWindSurfaceTheta(WindDir: Float64, SurfAzimuth: Float64) -> Float64:
    var windDir: Float64 = WindDir - 360.0 * Float64(Int(WindDir / 360.0))
    var surfAzi: Float64 = SurfAzimuth - 360.0 * Float64(Int(SurfAzimuth / 360.0))
    var theta: Float64 = abs(windDir - surfAzi)
    if theta > 180.0:
        return Float64(abs(Int(theta - 360.0)))
    return theta"""

VERT = """\
from math import pow

def CalcEmmelVertical(WindAt10m: Float64, WindDir: Float64, SurfAzimuth: Float64) -> Float64:
    var Theta: Float64 = CalcWindSurfaceTheta(WindDir, SurfAzimuth)
    if Theta <= 22.5:
        return 5.15 * pow(WindAt10m, 0.81)
    if Theta <= 67.5:
        return 3.34 * pow(WindAt10m, 0.84)
    if Theta <= 112.5:
        return 4.78 * pow(WindAt10m, 0.71)
    if Theta <= 157.5:
        return 4.05 * pow(WindAt10m, 0.77)
    return 3.54 * pow(WindAt10m, 0.76)

""" + CALLEE

ROOF = """\
from math import pow

def CalcEmmelRoof(WindAt10m: Float64, WindDir: Float64, LongAxisOutwardAzimuth: Float64) -> Float64:
    var Theta: Float64 = CalcWindSurfaceTheta(WindDir, LongAxisOutwardAzimuth)
    if Theta <= 22.5:
        return 5.11 * pow(WindAt10m, 0.78)
    if Theta <= 67.5:
        return 4.60 * pow(WindAt10m, 0.79)
    if Theta <= 112.5:
        return 3.67 * pow(WindAt10m, 0.85)
    if Theta <= 157.5:
        return 4.60 * pow(WindAt10m, 0.79)
    return 5.11 * pow(WindAt10m, 0.78)

""" + CALLEE

MOJO = {"CalcEmmelVertical": VERT, "CalcEmmelRoof": ROOF}

with open(sys.argv[2], "w") as f:
    for l in open(sys.argv[1]):
        if not l.strip():
            continue
        r = json.loads(l)
        r["mojo_source"] = MOJO[r["function_name"]]
        f.write(json.dumps(r, ensure_ascii=False) + "\n")
print("ok")

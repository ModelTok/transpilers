#!/usr/bin/env python3
"""Write round3 debug records (fixed fmod-emulation Mojo for CalcWindSurfaceTheta)."""
import json
import sys

# std::fmod via truncated-division emulation (exact for |a/b| within the
# sampled domain); unqualified C++ `abs(double)` resolves to int abs -> the
# faithful Mojo truncates through Int the same way.
WIND_MOJO = """\
def CalcWindSurfaceTheta(WindDir: Float64, SurfAzimuth: Float64) -> Float64:
    var windDir: Float64 = WindDir - 360.0 * Float64(Int(WindDir / 360.0))
    var surfAzi: Float64 = SurfAzimuth - 360.0 * Float64(Int(SurfAzimuth / 360.0))
    var theta: Float64 = abs(windDir - surfAzi)
    if theta > 180.0:
        return Float64(abs(Int(theta - 360.0)))
    return theta"""

rows = {json.loads(l)["function_name"]: json.loads(l)
        for l in open(sys.argv[1]) if l.strip()}
with open(sys.argv[2], "w") as f:
    r = rows["CalcWindSurfaceTheta"]
    r["mojo_source"] = WIND_MOJO
    f.write(json.dumps(r, ensure_ascii=False) + "\n")
    f.write(json.dumps(rows["OutdoorDryBulbGrad"], ensure_ascii=False) + "\n")
print("ok")

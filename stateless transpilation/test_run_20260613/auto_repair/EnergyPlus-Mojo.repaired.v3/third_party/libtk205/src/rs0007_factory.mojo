from RSInstanceBase import RSInstanceBase
from rs0007 import RS0007
from tk205 import load_json, SchemVer
from ASHRAE205 import ASHRAE205
from Courierr import Courierr

struct RS0007Factory:
    def create_instance(RS_instance_file: StringRef, logger: Pointer[Courierr]) -> Pointer[RSInstanceBase]:
        var p_rs = Pointer[RS0007].init(RS0007())
        var j = load_json(RS_instance_file)
        var schema_version = j["metadata"]["schema_version"]
        if SchemVer(schema_version) > SchemVer(RS0007.schema_version):
            p_rs = Pointer[RS0007]()
            var msg = "Schema version " + schema_version + " is not supported."
            (*logger).error(msg)
        elif j["metadata"]["schema"] == "RS0007":
            if ASHRAE205.logger == None:
                ASHRAE205.logger = logger
            RS0007.logger = logger
            (*p_rs).initialize(j)
        else:
            p_rs = Pointer[RS0007]()
            var msg = String(RS_instance_file) + " is not a valid instance of RS0007; returning None."
            (*logger).error(msg)
        return p_rs.unsafe_cast[Pointer[RSInstanceBase]]()
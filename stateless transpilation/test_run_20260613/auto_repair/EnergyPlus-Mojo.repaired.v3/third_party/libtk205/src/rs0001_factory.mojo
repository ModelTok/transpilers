from rs0001 import RS0001, RSInstanceBase
from ashrae205 import ASHRAE205
from courierr import Courierr
from tk205 import load_json, SchemVer
from std.pointer import SharedPtr

struct RS0001Factory:
    def create_instance(self, RS_instance_file: String, logger: SharedPtr[Courierr]) -> SharedPtr[RSInstanceBase]:
        var p_rs = SharedPtr[RS0001](RS0001())
        var j = load_json(RS_instance_file)
        var schema_version = j["metadata"]["schema_version"] as String
        if SchemVer(schema_version) > SchemVer(RS0001.Schema.schema_version):
            p_rs = None
            logger.error("Schema version " + schema_version + " is not supported.")
        elif j["metadata"]["schema"] == "RS0001":
            if ASHRAE205.logger == None:
                ASHRAE205.logger = logger
            RS0001.logger = logger
            p_rs.initialize(j)
        else:
            p_rs = None
            logger.error(RS_instance_file + " is not a valid instance of RS0001; returning None.")
        return p_rs
from rs0004 import RS0004
from courierr import Courierr
from tk205 import load_json, SchemVer
from ashrae205 import ASHRAE205
from rs_instance_base import RSInstanceBase
from memory import Arc

struct RS0004Factory:
    def create_instance(self, RS_instance_file: String, logger: Arc[Courierr]) -> Arc[RSInstanceBase]:
        var p_rs: Arc[RS0004] = Arc(RS0004())
        var j = load_json(RS_instance_file)
        var schema_version: String = j["metadata"]["schema_version"]
        if SchemVer(schema_version) > SchemVer(String(RS0004.Schema.schema_version)):
            p_rs = Arc[RS0004]()
            var oss: String = "Schema version " + schema_version + " is not supported."
            logger.error(oss)
        elif j["metadata"]["schema"] == "RS0004":
            if ASHRAE205.logger == None:
                ASHRAE205.logger = logger
            RS0004.logger = logger
            p_rs.initialize(j)
        else:
            p_rs = Arc[RS0004]()
            var oss: String = RS_instance_file + " is not a valid instance of RS0004; returning None."
            logger.error(oss)
        return p_rs as Arc[RSInstanceBase]
from rs0002 import RS0002, RSInstanceBase, Schema, SchemVer
from courierr import Courierr
from tk205 import load_json
from ashrae205 import ASHRAE205

struct RS0002Factory:
    def create_instance(self, RS_instance_file: String, logger: Courierr) -> Optional[RSInstanceBase]:
        var p_rs: Optional[RS0002] = Some(RS0002())
        var j = load_json(RS_instance_file)
        var schema_version = j["metadata"]["schema_version"] as String
        if SchemVer(schema_version) > SchemVer(String(Schema.schema_version)):
            p_rs = None
            var oss = String("Schema version " + schema_version + " is not supported.")
            logger.error(oss)
        elif j["metadata"]["schema"] == "RS0002":
            if ASHRAE205.logger == None:
                ASHRAE205.logger = logger
            RS0002.logger = logger
            if p_rs:
                p_rs.value().initialize(j)
        else:
            p_rs = None
            var oss = String(RS_instance_file + " is not a valid instance of RS0002; returning None.")
            logger.error(oss)
        return p_rs
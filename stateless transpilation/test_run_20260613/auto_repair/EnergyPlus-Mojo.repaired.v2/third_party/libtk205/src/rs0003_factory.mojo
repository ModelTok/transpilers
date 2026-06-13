from tk205 import load_json, SchemVer
from rs0003 import rs0003_ns
from ashrae205 import ashrae205_ns
from courierr import Courierr
from rs0003_factory import RSInstanceBase

struct RS0003Factory:
    def create_instance(self, RS_instance_file: String, logger: Arc[Courierr]) -> Arc[RSInstanceBase]:
        var p_rs = Arc(rs0003_ns.RS0003())
        var j = load_json(RS_instance_file)
        var schema_version: String = j["metadata"]["schema_version"]
        if SchemVer(schema_version) > SchemVer(rs0003_ns.Schema.schema_version):
            p_rs = None
            var oss: String = "Schema version " + schema_version + " is not supported."
            logger.error(oss)
        elif j["metadata"]["schema"] == "RS0003":
            if ashrae205_ns.ASHRAE205.logger == None:
                ashrae205_ns.ASHRAE205.logger = logger
            rs0003_ns.RS0003.logger = logger
            p_rs.initialize(j)
        else:
            p_rs = None
            var oss: String = RS_instance_file + " is not a valid instance of RS0003; returning None."
            logger.error(oss)
        return p_rs
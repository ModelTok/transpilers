from rs0006_factory import RS0006Factory
from rs0006 import RS0006
from memory import shared_ptr
from courierr.courierr import Courierr
from tk205 import RSInstanceBase, load_json, SchemVer
from rs0006_ns import RS0006 as rs0006_ns_RS0006
from rs0006_ns.Schema import Schema as rs0006_ns_Schema
from ashrae205_ns.ASHRAE205 import ASHRAE205 as ashrae205_ns_ASHRAE205
from stdlib import String, ostringstream

def RS0006Factory.create_instance(self, RS_instance_file: String, logger: shared_ptr[Courierr]) -> shared_ptr[RSInstanceBase]:
    var p_rs = shared_ptr[rs0006_ns_RS0006](rs0006_ns_RS0006())
    var j = load_json(RS_instance_file)
    var schema_version: String = j["metadata"]["schema_version"]
    if SchemVer(schema_version) > SchemVer(String(rs0006_ns_Schema.schema_version)):
        p_rs = shared_ptr[rs0006_ns_RS0006]()
        var oss = ostringstream()
        oss << "Schema version " << schema_version << " is not supported."
        logger.error(oss.str())
    elif j["metadata"]["schema"] == "RS0006":
        if ashrae205_ns_ASHRAE205.logger == None:
            ashrae205_ns_ASHRAE205.logger = logger
        rs0006_ns_RS0006.logger = logger
        p_rs.initialize(j)
    else:
        p_rs = shared_ptr[rs0006_ns_RS0006]()
        var oss = ostringstream()
        oss << RS_instance_file << " is not a valid instance of RS0006; returning None."
        logger.error(oss.str())
    return p_rs
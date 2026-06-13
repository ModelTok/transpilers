from rs0005_factory import RS0005Factory
from rs0005 import RS0005
import memory
from courierr.courierr import Courierr
struct RS0005Factory:
    def create_instance(self, RS_instance_file: Pointer[UInt8], logger: SharedPointer[Courierr] = None) -> SharedPointer[RSInstanceBase]:
        var p_rs = SharedPointer[rs0005_ns.RS0005]()
        var j = tk205.load_json(RS_instance_file)
        var schema_version: String = j["metadata"]["schema_version"]
        if SchemVer(schema_version) > SchemVer(String(rs0005_ns.Schema.schema_version)):
            p_rs = None
            var oss: String
            oss += "Schema version " + schema_version + " is not supported."
            logger.error(oss)
        elif j["metadata"]["schema"] == "RS0005":
            if ashrae205_ns.ASHRAE205.logger.is_null():
                ashrae205_ns.ASHRAE205.logger = logger
            rs0005_ns.RS0005.logger = logger
            p_rs.initialize(j)
        else:
            p_rs = None
            var oss: String
            oss += RS_instance_file + " is not a valid instance of RS0005; returning None."
            logger.error(oss)
        return p_rs
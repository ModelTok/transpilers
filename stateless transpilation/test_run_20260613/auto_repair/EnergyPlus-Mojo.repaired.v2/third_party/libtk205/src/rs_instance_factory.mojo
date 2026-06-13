from rs_instance_base import RSInstanceBase
from courierr import Courierr

var _rs_factory_map: Dict[String, Pointer[RSInstanceFactory]] = Dict[String, Pointer[RSInstanceFactory]]()

def get_RS_factory_map() -> &Dict[String, Pointer[RSInstanceFactory]]:
    return _rs_factory_map

struct RSInstanceFactory:
    @staticmethod
    def register_factory(RS_ID: String, factory: Pointer[RSInstanceFactory]) -> Bool:
        get_RS_factory_map()[RS_ID] = factory
        return True

    @staticmethod
    def create(RS_ID: String, RS_instance_file: String, logger: Pointer[Courierr]) -> Pointer[RSInstanceBase]:
        var factory = get_RS_factory_map().get(RS_ID, Pointer[RSInstanceFactory]())
        if factory == Pointer[RSInstanceFactory]():
            return Pointer[RSInstanceBase]()
        else:
            return factory.create_instance(RS_instance_file, logger)

    def create_instance(self, RS_instance_file: String, logger: Pointer[Courierr]) -> Pointer[RSInstanceBase]:
        return Pointer[RSInstanceBase]()
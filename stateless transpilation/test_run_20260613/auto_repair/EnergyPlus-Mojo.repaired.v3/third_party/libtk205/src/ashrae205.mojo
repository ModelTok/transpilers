from ashrae205 import SchemaType, Version, UUID, Timestamp, LiquidConstituent, ConcentrationType
from loadobject_205 import a205_json_get
from Courierr import Courierr
from json import JSON

struct Schema:
    static var schema_title: StringLiteral = "ASHRAE 205"
    static var schema_version: StringLiteral = "1.0.0"
    static var schema_description: StringLiteral = "Base schema for ASHRAE 205 representations"

struct ASHRAE205:
    static var logger: Pointer[Courierr] = Pointer[Courierr]()

struct Metadata:
    var data_model: String
    var data_model_is_set: Bool
    var schema: SchemaType
    var schema_is_set: Bool
    var schema_version: Version
    var schema_version_is_set: Bool
    var id: UUID
    var id_is_set: Bool
    var description: String
    var description_is_set: Bool
    var data_timestamp: Timestamp
    var data_timestamp_is_set: Bool
    var data_version: Int
    var data_version_is_set: Bool
    var data_source: String
    var data_source_is_set: Bool
    var disclaimer: String
    var disclaimer_is_set: Bool
    var notes: String
    var notes_is_set: Bool

    static var data_model_units: StringLiteral = ""
    static var schema_units: StringLiteral = ""
    static var schema_version_units: StringLiteral = ""
    static var id_units: StringLiteral = ""
    static var description_units: StringLiteral = ""
    static var data_timestamp_units: StringLiteral = ""
    static var data_version_units: StringLiteral = ""
    static var data_source_units: StringLiteral = ""
    static var disclaimer_units: StringLiteral = ""
    static var notes_units: StringLiteral = ""
    static var data_model_description: StringLiteral = "Data model name"
    static var schema_description: StringLiteral = "Schema name or identifier"
    static var schema_version_description: StringLiteral = "The version of the schema the data complies with"
    static var id_description: StringLiteral = "Unique equipment identifier"
    static var description_description: StringLiteral = "Description of data (suitable for display)"
    static var data_timestamp_description: StringLiteral = "Date of publication"
    static var data_version_description: StringLiteral = "Integer version identifier for the data in the representation"
    static var data_source_description: StringLiteral = "Source(s) of the data"
    static var disclaimer_description: StringLiteral = "Characterization of accuracy, limitations, and applicability of this data"
    static var notes_description: StringLiteral = "Additional Information"
    static var data_model_name: StringLiteral = "data_model"
    static var schema_name: StringLiteral = "schema"
    static var schema_version_name: StringLiteral = "schema_version"
    static var id_name: StringLiteral = "id"
    static var description_name: StringLiteral = "description"
    static var data_timestamp_name: StringLiteral = "data_timestamp"
    static var data_version_name: StringLiteral = "data_version"
    static var data_source_name: StringLiteral = "data_source"
    static var disclaimer_name: StringLiteral = "disclaimer"
    static var notes_name: StringLiteral = "notes"

struct LiquidComponent:
    var liquid_constituent: LiquidConstituent
    var liquid_constituent_is_set: Bool
    var concentration: Float64
    var concentration_is_set: Bool

    static var liquid_constituent_units: StringLiteral = ""
    static var concentration_units: StringLiteral = ""
    static var liquid_constituent_description: StringLiteral = "Substance of this component of the mixture"
    static var concentration_description: StringLiteral = "Concentration of this component of the mixture"
    static var liquid_constituent_name: StringLiteral = "liquid_constituent"
    static var concentration_name: StringLiteral = "concentration"

struct LiquidMixture:
    var liquid_components: List[LiquidComponent]
    var liquid_components_is_set: Bool
    var concentration_type: ConcentrationType
    var concentration_type_is_set: Bool

    static var liquid_components_units: StringLiteral = ""
    static var concentration_type_units: StringLiteral = ""
    static var liquid_components_description: StringLiteral = "An array of all liquid components within the liquid mixture"
    static var concentration_type_description: StringLiteral = "Defines whether concentration is defined on a volume or mass basis"
    static var liquid_components_name: StringLiteral = "liquid_components"
    static var concentration_type_name: StringLiteral = "concentration_type"

def from_json(j: JSON, x: inout Metadata):
    a205_json_get[String](j, ASHRAE205.logger[], "data_model", x.data_model, x.data_model_is_set, True)
    a205_json_get[SchemaType](j, ASHRAE205.logger[], "schema", x.schema, x.schema_is_set, True)
    a205_json_get[Version](j, ASHRAE205.logger[], "schema_version", x.schema_version, x.schema_version_is_set, True)
    a205_json_get[UUID](j, ASHRAE205.logger[], "id", x.id, x.id_is_set, True)
    a205_json_get[String](j, ASHRAE205.logger[], "description", x.description, x.description_is_set, True)
    a205_json_get[Timestamp](j, ASHRAE205.logger[], "data_timestamp", x.data_timestamp, x.data_timestamp_is_set, True)
    a205_json_get[Int](j, ASHRAE205.logger[], "data_version", x.data_version, x.data_version_is_set, True)
    a205_json_get[String](j, ASHRAE205.logger[], "data_source", x.data_source, x.data_source_is_set, False)
    a205_json_get[String](j, ASHRAE205.logger[], "disclaimer", x.disclaimer, x.disclaimer_is_set, False)
    a205_json_get[String](j, ASHRAE205.logger[], "notes", x.notes, x.notes_is_set, False)

def from_json(j: JSON, x: inout LiquidComponent):
    a205_json_get[LiquidConstituent](j, ASHRAE205.logger[], "liquid_constituent", x.liquid_constituent, x.liquid_constituent_is_set, True)
    a205_json_get[Float64](j, ASHRAE205.logger[], "concentration", x.concentration, x.concentration_is_set, False)

def from_json(j: JSON, x: inout LiquidMixture):
    a205_json_get[List[LiquidComponent]](j, ASHRAE205.logger[], "liquid_components", x.liquid_components, x.liquid_components_is_set, True)
    a205_json_get[ConcentrationType](j, ASHRAE205.logger[], "concentration_type", x.concentration_type, x.concentration_type_is_set, True)
from memory import unique_ptr
from string import String
from vector import Vector
from json import JSON
from re2 import RE2
from valijson.adapters.nlohmann_json_adapter import NlohmannJsonAdapter
from valijson.schema import Schema
from valijson.schema_parser import SchemaParser
from valijson.utils.nlohmann_json_utils import *
from valijson.validator import ValidatorT, ValidationResults

struct Validation:
    var schema: JSON*
    var errors_: Vector[String]
    var warnings_: Vector[String]

    def __init__(inout self, parsed_schema: JSON*):
        self.schema = parsed_schema

    def hasErrors(self) -> Bool:
        return not self.errors_.empty()

    def errors(self) -> Vector[String]:
        return self.errors_

    def warnings(self) -> Vector[String]:
        return self.warnings_

struct RE2RegexpEngine:
    var regex_ptr: unique_ptr[RE2]

    def __init__(inout self, pattern: String):
        self.regex_ptr = unique_ptr[RE2](RE2(pattern))

    @staticmethod
    def search(s: String, r: RE2RegexpEngine) -> Bool:
        return RE2.PartialMatch(s, *r.regex_ptr)

def validation_schema(schema: JSON*) -> Schema:
    alias last_schema = schema
    # assert(last_schema == schema)
    var retval = unique_ptr[Schema]()
    # static initialization via lambda
    var vs = unique_ptr[Schema](Schema())
    var parser = SchemaParser()
    var schema_doc = NlohmannJsonAdapter(*schema)
    parser.populateSchema(schema_doc, *vs)
    retval = unique_ptr[Schema](vs.release())
    return *retval

def validate(self: Validation, parsed_input: JSON) -> Bool:
    alias nameError = "Object contains a property that could not be validated using 'properties' or 'additionalProperties' constraints: ''."
    alias otherError = "Object contains a property that could not be validated using 'properties' or 'additionalProperties' constraints"
    var validator = ValidatorT[RE2RegexpEngine]()
    var doc = NlohmannJsonAdapter(parsed_input)
    var results = ValidationResults()
    if not validator.validate(validation_schema(self.schema), doc, &results):
        var error = ValidationResults.Error()
        var max_context: UInt = 0
        while results.popError(error):
            if error.context.size() >= max_context:
                max_context = error.context.size()
                var context = String()
                for it in error.context:
                    context += it
                self.errors_.emplace_back(context + " - " + error.description)
                if max_context == 2:
                    if error.description == nameError:
                        self.errors_.emplace_back(context + " - Object name is required and cannot be blank or whitespace")
                    elif error.description.find(otherError) != -1:
                        self.errors_.emplace_back(context + " - Object name is required and cannot be blank or whitespace, and must be UTF-8 encoded")
        return False
    return True
# EXTERNAL DEPS (to wire in glue):
# - nlohmann::json (JSON library): JSON parsing and representation
# - re2::RE2 (Regex engine): Regular expression compilation and matching
# - valijson (JSON Schema validation): Schema validator with pluggable regex engine support

from memory import UnsafePointer
from collections import List, InlineArray
import re

alias json = object

struct ValidationError:
    var context: List[String]
    var description: String

struct ValidationResults:
    fn popError(inout self, inout error: ValidationError) -> Bool:
        return False

struct ValjsonSchema:
    pass

struct SchemaAdapter:
    pass

struct SchemaParser:
    fn populateSchema(self, adapter: SchemaAdapter, inout schema: ValjsonSchema) -> None:
        pass

struct Validator:
    fn validate(self, schema: ValjsonSchema, doc: SchemaAdapter, inout results: ValidationResults) -> Bool:
        return False

struct RE2RegexpEngine:
    var regex_ptr: object
    
    fn __init__(inout self, pattern: String):
        self.regex_ptr = re.compile(pattern)
    
    @staticmethod
    fn search(s: String, r: RE2RegexpEngine) -> Bool:
        let match = re.search(s, r.regex_ptr)
        return match is not None

struct Validation:
    var schema: object
    var errors_: List[String]
    var warnings_: List[String]
    
    fn __init__(inout self, parsed_schema: object):
        self.schema = parsed_schema
        self.errors_ = List[String]()
        self.warnings_ = List[String]()
    
    fn validate(inout self, parsed_input: object) -> Bool:
        let name_error = "Object contains a property that could not be validated using 'properties' or 'additionalProperties' constraints: ''."
        let other_error = "Object contains a property that could not be validated using 'properties' or 'additionalProperties' constraints"
        
        var validator = Validator()
        var doc = SchemaAdapter()
        var results = ValidationResults()
        
        if not validator.validate(validation_schema(self.schema), doc, results):
            var error = ValidationError()
            error.context = List[String]()
            error.description = ""
            var max_context = 0
            
            while results.popError(error):
                if len(error.context) >= max_context:
                    max_context = len(error.context)
                    var context = String()
                    for i in range(len(error.context)):
                        context += error.context[i]
                    
                    self.errors_.append(context + " - " + error.description)
                    if max_context == 2:
                        if error.description == name_error:
                            self.errors_.append(context + " - Object name is required and cannot be blank or whitespace")
                        elif other_error in error.description:
                            self.errors_.append(context + " - Object name is required and cannot be blank or whitespace, and must be UTF-8 encoded")
            return False
        return True
    
    fn hasErrors(self) -> Bool:
        return len(self.errors_) > 0
    
    fn errors(self) -> List[String]:
        return self.errors_
    
    fn warnings(self) -> List[String]:
        return self.warnings_

var _validation_schema_cache: object = object()
var _last_schema: object = object()

fn validation_schema(schema: object) -> ValjsonSchema:
    if _last_schema is not object() and _last_schema is not schema:
        debug_assert(False, "Schema pointer changed")
    
    _last_schema = schema
    
    var vs = ValjsonSchema()
    var parser = SchemaParser()
    var schema_doc = SchemaAdapter()
    parser.populateSchema(schema_doc, vs)
    _validation_schema_cache = vs
    
    return vs

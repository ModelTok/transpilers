# EXTERNAL DEPS (to wire in glue):
# - nlohmann::json (JSON library): JSON parsing and representation
# - re2::RE2 (Regex engine): Regular expression compilation and matching
# - valijson (JSON Schema validation): Schema validator with pluggable regex engine support

from typing import Protocol, Optional, List, Any
from dataclasses import dataclass, field
import re as stdlib_re

json = Any

class ValidationError(Protocol):
    context: List[str]
    description: str

class ValidationResults(Protocol):
    def popError(self, error: ValidationError) -> bool: ...

class ValjsonSchema(Protocol):
    pass

class SchemaAdapter(Protocol):
    pass

class SchemaParser(Protocol):
    def populateSchema(self, adapter: SchemaAdapter, schema: ValjsonSchema) -> None: ...

class Validator(Protocol):
    def validate(self, schema: ValjsonSchema, doc: SchemaAdapter, results: ValidationResults) -> bool: ...

class RE2RegexpEngine:
    def __init__(self, pattern: str) -> None:
        self.regex_ptr = stdlib_re.compile(pattern)
    
    @staticmethod
    def search(s: str, r: 'RE2RegexpEngine') -> bool:
        return r.regex_ptr.search(s) is not None

@dataclass
class Validation:
    schema: Optional[json] = None
    errors_: List[str] = field(default_factory=list)
    warnings_: List[str] = field(default_factory=list)
    
    def __init__(self, parsed_schema: Optional[json]) -> None:
        self.schema = parsed_schema
        self.errors_ = []
        self.warnings_ = []
    
    def validate(self, parsed_input: json) -> bool:
        name_error = "Object contains a property that could not be validated using 'properties' or 'additionalProperties' constraints: ''."
        other_error = "Object contains a property that could not be validated using 'properties' or 'additionalProperties' constraints"
        
        validator: Validator
        doc: SchemaAdapter
        results: ValidationResults
        
        if not validator.validate(validation_schema(self.schema), doc, results):
            error: ValidationError
            max_context = 0
            while results.popError(error):
                if len(error.context) >= max_context:
                    max_context = len(error.context)
                    context = ''.join(error.context)
                    self.errors_.append(context + " - " + error.description)
                    if max_context == 2:
                        if error.description == name_error:
                            self.errors_.append(context + " - Object name is required and cannot be blank or whitespace")
                        elif other_error in error.description:
                            self.errors_.append(context + " - Object name is required and cannot be blank or whitespace, and must be UTF-8 encoded")
            return False
        return True
    
    def hasErrors(self) -> bool:
        return len(self.errors_) > 0
    
    def errors(self) -> List[str]:
        return self.errors_
    
    def warnings(self) -> List[str]:
        return self.warnings_

_validation_schema_cache: Optional[ValjsonSchema] = None
_last_schema: Optional[json] = None

def validation_schema(schema: Optional[json]) -> ValjsonSchema:
    global _validation_schema_cache, _last_schema
    
    if _last_schema is not None and _last_schema is not schema:
        assert False, "Schema pointer changed"
    
    _last_schema = schema
    
    if _validation_schema_cache is None:
        vs: ValjsonSchema
        parser: SchemaParser
        schema_doc: SchemaAdapter
        parser.populateSchema(schema_doc, vs)
        _validation_schema_cache = vs
    
    return _validation_schema_cache

from python import Python
Python.import_module("sys")
Python.import_module("os")
Python.import_module("json")
Python.import_module("cbor2")
from python import sys as _sys
from python import os as _os
from python import json as _json
from python import cbor2 as _cbor2
const header = """
namespace EnergyPlus {
namespace EmbeddedEpJSONSchema {
"""
const footer = """
    const gsl::span<const uint8_t> embeddedEpJSONSchema()
    {
        return gsl::span<const uint8_t>(embeddedSchema);
    }
    const string_view embeddedEpJSONSchemaView()
    {
        static const string str(embeddedSchema.begin(), embeddedSchema.end());
        return str;
    }
} // namespace EmbeddedEpJSONSchema
} // namespace EnergyPlus
"""
def main() raises:
    var argv = _sys.argv
    if len(argv) != 3:
        _sys.stderr.write("usage: ./generate_embeddable_schema path/to/Energy+.schema.epJSON path/to/EmbeddedEpJSONSchema.cc\n")
        return 1
    _sys.stderr.write("Generating the **embedded** epJSON schema\n")
    var schema_stream = open(argv[1], "r")
    var input_json = _json.load(schema_stream)
    schema_stream.close()
    var v_cbor = list(_cbor2.dumps(input_json))
    var out_file_path = argv[2]
    var out_file_dir = _os.path.dirname(out_file_path)
    if not _os.path.isdir(out_file_dir):
        _sys.stderr.write("Output Directory does not exist: {}\n".format(out_file_dir))
        _os.makedirs(out_file_dir, exist_ok=True)
    var outfile = open(argv[2], "w")
    outfile.write(header)
    outfile.write("    static array< uint8_t, {} > embeddedSchema = {{{{\n".format(len(v_cbor)))
    for i, byte in enumerate(v_cbor):
        outfile.write("{:#04x},".format(byte))
        if i % 40 == 0 and i != 0:
            outfile.write("\n")
    outfile.write("}}}};\n")
    outfile.write(footer)
    outfile.close()
    return 0
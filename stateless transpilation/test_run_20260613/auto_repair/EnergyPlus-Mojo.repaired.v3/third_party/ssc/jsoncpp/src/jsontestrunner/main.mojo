/* This executable is used for testing parser/writer using real JSON files.
 */
from algorithm import sort
from cstdio import printf, fprintf, fopen, fclose, fseek, ftell, fread, FILE, SEEK_END, SEEK_SET
from io import StringRef
from json import Json as Json
from memory import unique_ptr
from sstream import OStringStream
from string import String
from sys import int as Int, size_t as SizeT
from utils import jsoncpp_snprintf

struct Options:
    var path: String
    var features: Json.Features
    var parseOnly: Bool
    typealias writeFuncType = def (Json.Value) -> String
    var write: writeFuncType

def normalizeFloatingPointStr(value: Float64) -> String:
    var buffer = Array[UInt8](32)
    jsoncpp_snprintf(buffer.data, buffer.size, "%.16g", value)
    buffer[buffer.size - 1] = 0
    var s = String(buffer.data)
    var index = s.find_last_of("eE")
    if index != String.npos:
        var hasSign: SizeT = (s[index + 1] == '+' or s[index + 1] == '-') ? 1 : 0
        var exponentStartIndex: SizeT = index + 1 + hasSign
        var normalized = s.substr(0, exponentStartIndex)
        var indexDigit = s.find_first_not_of('0', exponentStartIndex)
        var exponent = "0"
        if indexDigit != String.npos:
            exponent = s.substr(indexDigit)
        return normalized + exponent
    return s

def readInputTestFile(path: StringRef) -> String:
    var file = fopen(path.data, "rb")
    if not file:
        return ""
    fseek(file, 0, SEEK_END)
    var size = ftell(file)
    var usize = size as SizeT
    fseek(file, 0, SEEK_SET)
    var buffer = Array[UInt8](size + 1)
    buffer[size] = 0
    var text = String()
    if fread(buffer.data, 1, usize, file) == usize:
        text = String(buffer.data)
    fclose(file)
    return text

def printValueTree(fout: FILE*, value: Json.Value, path: String = "."):
    if value.hasComment(Json.commentBefore):
        fprintf(fout, "%s\n", value.getComment(Json.commentBefore).c_str())
    var type = value.type()
    if type == Json.nullValue:
        fprintf(fout, "%s=null\n", path.c_str())
    elif type == Json.intValue:
        fprintf(fout, "%s=%s\n", path.c_str(), Json.valueToString(value.asLargestInt()).c_str())
    elif type == Json.uintValue:
        fprintf(fout, "%s=%s\n", path.c_str(), Json.valueToString(value.asLargestUInt()).c_str())
    elif type == Json.realValue:
        fprintf(fout, "%s=%s\n", path.c_str(), normalizeFloatingPointStr(value.asDouble()).c_str())
    elif type == Json.stringValue:
        fprintf(fout, "%s=\"%s\"\n", path.c_str(), value.asString().c_str())
    elif type == Json.booleanValue:
        fprintf(fout, "%s=%s\n", path.c_str(), value.asBool() ? "true" : "false")
    elif type == Json.arrayValue:
        fprintf(fout, "%s=[]\n", path.c_str())
        var size = value.size()
        for index in range(size):
            var buffer = Array[UInt8](16)
            jsoncpp_snprintf(buffer.data, buffer.size, "[%u]", index)
            printValueTree(fout, value[index], path + String(buffer.data))
    elif type == Json.objectValue:
        fprintf(fout, "%s={}\n", path.c_str())
        var members = value.getMemberNames()
        sort(members.begin(), members.end())
        var suffix = (*(path.end() - 1) == '.') ? "" : "."
        for name in members:
            printValueTree(fout, value[name], path + suffix + name)
    if value.hasComment(Json.commentAfter):
        fprintf(fout, "%s\n", value.getComment(Json.commentAfter).c_str())

def parseAndSaveValueTree(input: String, actual: String, kind: String, features: Json.Features, parseOnly: Bool, root: Json.Value, use_legacy: Bool) -> Int:
    if not use_legacy:
        var builder = Json.CharReaderBuilder()
        builder.settings_["allowComments"] = features.allowComments_
        builder.settings_["strictRoot"] = features.strictRoot_
        builder.settings_["allowDroppedNullPlaceholders"] = features.allowDroppedNullPlaceholders_
        builder.settings_["allowNumericKeys"] = features.allowNumericKeys_
        var reader = unique_ptr[Json.CharReader](builder.newCharReader())
        var errors = String()
        var parsingSuccessful = reader.get().parse(input.data(), input.data() + input.size(), root, &errors)
        if not parsingSuccessful:
            std.cerr << "Failed to parse " << kind << " file: " << std.endl << errors << std.endl
            return 1
    else:
        var reader = Json.Reader(features)
        var parsingSuccessful = reader.parse(input.data(), input.data() + input.size(), *root)
        if not parsingSuccessful:
            std.cerr << "Failed to parse " << kind << " file: " << std.endl << reader.getFormatedErrorMessages() << std.endl
            return 1
    if not parseOnly:
        var factual = fopen(actual.c_str(), "wt")
        if not factual:
            std.cerr << "Failed to create '" << kind << "' actual file." << std.endl
            return 2
        printValueTree(factual, *root)
        fclose(factual)
    return 0

def useStyledWriter(root: Json.Value) -> String:
    var writer = Json.StyledWriter()
    return writer.write(root)

def useStyledStreamWriter(root: Json.Value) -> String:
    var writer = Json.StyledStreamWriter()
    var sout = OStringStream()
    writer.write(sout, root)
    return sout.str()

def useBuiltStyledStreamWriter(root: Json.Value) -> String:
    var builder = Json.StreamWriterBuilder()
    return Json.writeString(builder, root)

def rewriteValueTree(rewritePath: String, root: Json.Value, write: Options.writeFuncType, rewrite: String) -> Int:
    *rewrite = write(root)
    var fout = fopen(rewritePath.c_str(), "wt")
    if not fout:
        std.cerr << "Failed to create rewrite file: " << rewritePath << std.endl
        return 2
    fprintf(fout, "%s\n", rewrite.c_str())
    fclose(fout)
    return 0

def removeSuffix(path: String, extension: String) -> String:
    if extension.length() >= path.length():
        return String("")
    var suffix = path.substr(path.length() - extension.length())
    if suffix != extension:
        return String("")
    return path.substr(0, path.length() - extension.length())

def printConfig():
    #if defined(JSON_NO_INT64)
        std.cout << "JSON_NO_INT64=1" << std.endl
    #else
        std.cout << "JSON_NO_INT64=0" << std.endl
    #endif

def printUsage(argv: StringRef) -> Int:
    std.cout << "Usage: " << argv[0] << " [--strict] input-json-file" << std.endl
    return 3

def parseCommandLine(argc: Int, argv: StringRef, opts: Options) -> Int:
    opts.parseOnly = False
    opts.write = &useStyledWriter
    if argc < 2:
        return printUsage(argv)
    var index = 1
    if String(argv[index]) == "--json-checker":
        opts.features = Json.Features.strictMode()
        opts.parseOnly = True
        index += 1
    if String(argv[index]) == "--json-config":
        printConfig()
        return 3
    if String(argv[index]) == "--json-writer":
        index += 1
        var writerName = String(argv[index])
        index += 1
        if writerName == "StyledWriter":
            opts.write = &useStyledWriter
        elif writerName == "StyledStreamWriter":
            opts.write = &useStyledStreamWriter
        elif writerName == "BuiltStyledStreamWriter":
            opts.write = &useBuiltStyledStreamWriter
        else:
            std.cerr << "Unknown '--json-writer' " << writerName << std.endl
            return 4
    if index == argc or index + 1 < argc:
        return printUsage(argv)
    opts.path = argv[index]
    return 0

def runTest(opts: Options, use_legacy: Bool) -> Int:
    var exitCode = 0
    var input = readInputTestFile(opts.path.c_str())
    if input.empty():
        std.cerr << "Invalid input file: " << opts.path << std.endl
        return 3
    var basePath = removeSuffix(opts.path, ".json")
    if not opts.parseOnly and basePath.empty():
        std.cerr << "Bad input path '" << opts.path << "'. Must end with '.expected'" << std.endl
        return 3
    var actualPath = basePath + ".actual"
    var rewritePath = basePath + ".rewrite"
    var rewriteActualPath = basePath + ".actual-rewrite"
    var root = Json.Value()
    exitCode = parseAndSaveValueTree(input, actualPath, "input", opts.features, opts.parseOnly, &root, use_legacy)
    if exitCode or opts.parseOnly:
        return exitCode
    var rewrite = String()
    exitCode = rewriteValueTree(rewritePath, root, opts.write, &rewrite)
    if exitCode:
        return exitCode
    var rewriteRoot = Json.Value()
    exitCode = parseAndSaveValueTree(rewrite, rewriteActualPath, "rewrite", opts.features, opts.parseOnly, &rewriteRoot, use_legacy)
    return exitCode

def main(argc: Int, argv: StringRef) -> Int:
    var opts = Options()
    try:
        var exitCode = parseCommandLine(argc, argv, &opts)
        if exitCode != 0:
            std.cerr << "Failed to parse command-line." << std.endl
            return exitCode
        var modern_return_code = runTest(opts, False)
        if modern_return_code:
            return modern_return_code
        var filename = opts.path.substr(opts.path.find_last_of("\\/") + 1)
        var should_run_legacy = (filename.rfind("legacy_", 0) == 0)
        if should_run_legacy:
            return runTest(opts, True)
    except e as std.exception:
        std.cerr << "Unhandled exception:" << std.endl << e.what() << std.endl
        return 1
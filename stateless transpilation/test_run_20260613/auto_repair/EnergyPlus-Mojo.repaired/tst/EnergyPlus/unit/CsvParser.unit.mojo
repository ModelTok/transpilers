from Fixtures.InputProcessorFixture import InputProcessorFixture
from EnergyPlus.InputProcessing.CsvParser import CsvParser
from testing import *
from python import object as PythonObject  # for json interop if needed, but we'll define a simple JSON type

struct JSON:
    var data: PythonObject

    def __init__(self, data: PythonObject):
        self.data = data

    def __getattr__(self, name: String) raises -> PythonObject:
        return self.data.__getattr__(name)  # not used

    def __getitem__(self, index: Int) raises -> PythonObject:
        return self.data.__getitem__(index)

    def __getitem__(self, key: String) raises -> PythonObject:
        return self.data.__getitem__(key)

    def get(self, index: Int, default: PythonObject = None) -> PythonObject:
        try:
            return self.data.__getitem__(index)
        except:
            return default

    def get(self, key: String, default: PythonObject = None) -> PythonObject:
        try:
            return self.data.__getitem__(key)
        except:
            return default

    def at(self, index: Int) raises -> Self:
        return JSON(self.data.__getitem__(index))

    def get_as_vector_real64(self) raises -> List[Float64]:
        vec = List[Float64]()
        for i in range(len(self.data)):
            vec.append(float(self.data.__getitem__(i)))
        return vec

    def get_as_vector_real64_or_throw(self) raises -> List[Float64]:
        return self.get_as_vector_real64()

    def type(self) -> String:
        return str(type(self.data))

    def is_null(self) -> Bool:
        return self.data is None

    def null_value() -> Self:
        return JSON(PythonObject(None))

def format_errors_or_warnings(errors: List[Tuple[String, Bool]], is_error: Bool = True) -> String:
    base = "** Severe  **" if is_error else "** Warning **"
    var errs = String("")
    for error, isContinued in errors:
        var prefix = "**   ~~~   **" if isContinued else base
        errs += format("{}{}\n", prefix, error)
    return errs

def CsvParser_ProperlyFormed(using fix: InputProcessorFixture) raises:
    var csv = StringLiteral("Hour,Value1,Value2\n0,0.1,0.01\n1,0.2,0.02\n")
    var csvParser = CsvParser()
    var result: JSON = csvParser.decode(csv, ',', 1)
    assert(not csvParser.hasErrors(), format_errors_or_warnings(csvParser.errors()))
    assert(csvParser.errors().size() == 0)
    assert(not csvParser.hasWarnings(), format_errors_or_warnings(csvParser.warnings(), False))
    assert(csvParser.warnings().size() == 0)
    var header = result["header"]
    assert(header[0] == "Hour")
    assert(header[1] == "Value1")
    assert(header[2] == "Value2")
    var values = result["values"]
    assert(len(values) == 3)
    do:
        var col = values[0]
        assert(col.size() == 2)
        assert(col[0] == 0.0)
        assert(col[1] == 1.0)
    do:
        var col = values[1]
        assert(col.size() == 2)
        assert(col[0] == 0.1)
        assert(col[1] == 0.2)
    do:
        var col = values[2]
        assert(col.size() == 2)
        assert(col[0] == 0.01)
        assert(col[1] == 0.02)
    try:
        var _ = values.at(0).get_as_vector_real64()
    except:
        assert(False)
    try:
        var _ = values.at(1).get_as_vector_real64()
    except:
        assert(False)
    try:
        var _ = values.at(2).get_as_vector_real64()
    except:
        assert(False)

def CsvParser_WrongNumberOfValues(using fix: InputProcessorFixture) raises:
    var csv = StringLiteral("Hour,Value1,Value2\n0,0.1,0.01\n1,0.02\n")
    var csvParser = CsvParser()
    var result: JSON = csvParser.decode(csv, ',', 1)
    assert(csvParser.hasErrors())
    assert(csvParser.errors().size() == 2)
    do:
        var first = csvParser.errors().front()
        assert(first[0] == "CsvParser - Line 3 - Expected 3 columns, got 2. Error in following line.")
        assert(not first[1])
    do:
        var last = csvParser.errors().back()
        assert(last[0] == "1,0.02")
        assert(last[1])
    var header = result["header"]
    assert(header[0] == "Hour")
    assert(header[1] == "Value1")
    assert(header[2] == "Value2")
    var values = result["values"]
    assert(len(values) == 3)

def CsvParser_NullValue(using fix: InputProcessorFixture) raises:
    var csv = StringLiteral("Hour,Value1,Value2\n0,0.1,0.01\n1,,0.02\n")
    var csvParser = CsvParser()
    var result: JSON = csvParser.decode(csv, ',', 1)
    assert(not csvParser.hasErrors(), format_errors_or_warnings(csvParser.errors()))
    assert(csvParser.errors().size() == 0)
    assert(csvParser.hasWarnings())
    assert(csvParser.warnings().size() == 2)
    do:
        var first = csvParser.warnings().front()
        assert(first[0] == "CsvParser - Line 3 Column 2 - Blank value found, setting to null. Error in following line.")
        assert(not first[1])
    do:
        var last = csvParser.warnings().back()
        assert(last[0] == "1,,0.02")
        assert(last[1])
    var header = result["header"]
    assert(header[0] == "Hour")
    assert(header[1] == "Value1")
    assert(header[2] == "Value2")
    var values = result["values"]
    assert(len(values) == 3)
    do:
        var col = values[0]
        assert(col.size() == 2)
        assert(col[0] == 0.0)
        assert(col[1] == 1.0)
    do:
        var col = values[1]
        assert(col.size() == 2)
        assert(col[0] == 0.1)
        assert(col[1].is_null())
    do:
        var col = values[2]
        assert(col.size() == 2)
        assert(col[0] == 0.01)
        assert(col[1] == 0.02)
    try:
        var _ = values.at(0).get_as_vector_real64()
    except:
        assert(False)
    try:
        var _ = values.at(1).get_as_vector_real64()
        assert(False)
    except JSON.TypeError:

    try:
        var _ = values.at(2).get_as_vector_real64()
    except:
        assert(False)

def CsvParser_ExtraColumns(using fix: InputProcessorFixture) raises:
    var csv = StringLiteral("Hour,Value1,Value2\n0,0.1,0.01\n1,0.2,0.02,0.33\n")
    var csvParser = CsvParser()
    var result: JSON = csvParser.decode(csv, ',', 1)
    assert(not csvParser.hasErrors(), format_errors_or_warnings(csvParser.errors()))
    assert(csvParser.errors().size() == 0)
    assert(csvParser.hasWarnings())
    assert(csvParser.warnings().size() == 2)
    do:
        var first = csvParser.warnings().front()
        assert(first[0] == "CsvParser - Line 3 - Expected 3 columns, got 4. Ignored extra columns. Error in following line.")
        assert(not first[1])
    do:
        var last = csvParser.warnings().back()
        assert(last[0] == "1,0.2,0.02,0.33")
        assert(last[1])
    var header = result["header"]
    assert(header[0] == "Hour")
    assert(header[1] == "Value1")
    assert(header[2] == "Value2")
    var values = result["values"]
    assert(len(values) == 3)
    do:
        var col = values[0]
        assert(col.size() == 2)
        assert(col[0] == 0.0)
        assert(col[1] == 1.0)
    do:
        var col = values[1]
        assert(col.size() == 2)
        assert(col[0] == 0.1)
        assert(col[1] == 0.2)
    do:
        var col = values[2]
        assert(col.size() == 2)
        assert(col[0] == 0.01)
        assert(col[1] == 0.02)
    try:
        var _ = values.at(0).get_as_vector_real64()
    except:
        assert(False)
    try:
        var _ = values.at(1).get_as_vector_real64()
    except:
        assert(False)
    try:
        var _ = values.at(2).get_as_vector_real64()
    except:
        assert(False)
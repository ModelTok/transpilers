from testing import *
from Fixtures.IdfParserFixture import IdfParserFixture
from DataStringGlobals import DataStringGlobals
from IdfParser import IdfParser, parse_idf, parse_object, eat_whitespace, eat_comment, parse_string, parse_value, look_ahead, next_token
from Fixtures.IdfParserFixture import delimited_string

def test_decode():
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "  Building,\n"
        "    Ref Bldg Medium Office New2004_v1.3_5.0,  !- Name\n"
        "    0.0000,                  !- North Axis {deg}\n"
        "    City,                    !- Terrain\n"
        "    0.0400,                  !- Loads Convergence Tolerance Value\n"
        "    0.2000,                  !- Temperature Convergence Tolerance Value {deltaC}\n"
        "    FullInteriorAndExterior, !- Solar Distribution\n"
        "    25,                      !- Maximum Number of Warmup Days\n"
        "    6;  \n"
    )
    var output = IdfParser.decode(test_object)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Building", "Ref Bldg Medium Office New2004_v1.3_5.0", "0.0000", "City", "0.0400", "0.2000", "FullInteriorAndExterior", "25", "6")
        ),
        output
    )

def test_decode_success():
    var success: Bool = True
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "  Building,\n"
        "    Ref Bldg Medium Office New2004_v1.3_5.0,  !- Name\n"
        "    0.0000,                  !- North Axis {deg}\n"
        "    City,                    !- Terrain\n"
        "    0.0400,                  !- Loads Convergence Tolerance Value\n"
        "    0.2000,                  !- Temperature Convergence Tolerance Value {deltaC}\n"
        "    FullInteriorAndExterior, !- Solar Distribution\n"
        "    25,                      !- Maximum Number of Warmup Days\n"
        "    6;  \n"
    )
    var output = IdfParser.decode(test_object, success)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Building", "Ref Bldg Medium Office New2004_v1.3_5.0", "0.0000", "City", "0.0400", "0.2000", "FullInteriorAndExterior", "25", "6")
        ),
        output
    )
    assert_true(success)

def test_decode_success_2():
    var success: Bool = True
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "  Building,\n"
        "    Ref Bldg Medium Office New2004_v1.3_5.0,  !- Name\n"
        "    0.0000,                  !- North Axis {deg}\n"
        "    ,                        !- Terrain\n"
        "    0.0400,                  !- Loads Convergence Tolerance Value\n"
        "    0.2000,                  !- Temperature Convergence Tolerance Value {deltaC}\n"
        "    ,                        !- Solar Distribution\n"
        "    25,                      !- Maximum Number of Warmup Days\n"
        "    6;  \n"
    )
    var output = IdfParser.decode(test_object, success)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Building", "Ref Bldg Medium Office New2004_v1.3_5.0", "0.0000", "", "0.0400", "0.2000", "", "25", "6")
        ),
        output
    )
    assert_true(success)

def test_decode_success_3():
    var success: Bool = True
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "  Building,\n"
        "    Ref Bldg Medium Office New2004_v1.3_5.0,  !- Name\n"
        "    0.0000,                  !- North Axis {deg}\n"
        "    ,                        !- Terrain\n"
        "    0.0400,                  !- Loads Convergence Tolerance Value\n"
        "    0.2000,                  !- Temperature Convergence Tolerance Value {deltaC}\n"
        "    ,                        !- Solar Distribution\n"
        "    25,                      !- Maximum Number of Warmup Days\n"
        "    ;  \n"
    )
    var output = IdfParser.decode(test_object, success)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Building", "Ref Bldg Medium Office New2004_v1.3_5.0", "0.0000", "", "0.0400", "0.2000", "", "25", "")
        ),
        output
    )
    assert_true(success)

def test_decode_success_4():
    var success: Bool = True
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "Schedule:Constant,OnSch,,1.0;\n"
        "Schedule:Constant,Aula people sched,,0.0;\n"
    )
    var output = IdfParser.decode(test_object, success)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Schedule:Constant", "OnSch", "", "1.0"),
            List[String]("Schedule:Constant", "Aula people sched", "", "0.0")
        ),
        output
    )
    assert_true(success)

def test_decode_encode():
    var success: Bool = True
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "Schedule:Constant,OnSch,,1.0;\n"
        "Schedule:Constant,Aula people sched,,0.0;\n"
    )
    var output = IdfParser.decode(test_object, success)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Schedule:Constant", "OnSch", "", "1.0"),
            List[String]("Schedule:Constant", "Aula people sched", "", "0.0")
        ),
        output
    )
    assert_true(success)
    var encoded_string = IdfParser.encode(output)
    assert_equal(test_object, encoded_string)

def test_decode_encode_2():
    var success: Bool = True
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "Schedule:Constant,OnSch,,;\n"
        "Schedule:Constant,Aula people sched,,;\n"
    )
    var output = IdfParser.decode(test_object, success)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Schedule:Constant", "OnSch", "", ""),
            List[String]("Schedule:Constant", "Aula people sched", "", "")
        ),
        output
    )
    assert_true(success)
    var encoded_string = IdfParser.encode(output)
    assert_equal(test_object, encoded_string)

def test_parse_idf():
    var index: Int = 0
    var success: Bool = True
    var test_object: String = delimited_string(
        "Version," + DataStringGlobals.MatchVersion + ";\n"
        "  Building,\n"
        "    Ref Bldg Medium Office New2004_v1.3_5.0,  !- Name\n"
        "    0.0000,                  !- North Axis {deg}\n"
        "    City,                    !- Terrain\n"
        "    0.0400,                  !- Loads Convergence Tolerance Value\n"
        "    0.2000,                  !- Temperature Convergence Tolerance Value {deltaC}\n"
        "    FullInteriorAndExterior, !- Solar Distribution\n"
        "    25,                      !- Maximum Number of Warmup Days\n"
        "    6;\n"
    )
    var output = parse_idf(test_object, index, success)
    assert_equal(
        List[List[String]](
            List[String]("Version", DataStringGlobals.MatchVersion),
            List[String]("Building", "Ref Bldg Medium Office New2004_v1.3_5.0", "0.0000", "City", "0.0400", "0.2000", "FullInteriorAndExterior", "25", "6")
        ),
        output
    )
    assert_equal(test_object.size() - 1, index)
    assert_true(success)

def test_parse_object():
    var index: Int = 0
    var success: Bool = True
    var test_object: String = delimited_string(
        "  Building,\n"
        "    Ref Bldg Medium Office New2004_v1.3_5.0,  !- Name\n"
        "    0.0000,                  !- North Axis {deg}\n"
        "    City,                    !- Terrain\n"
        "    0.0400,                  !- Loads Convergence Tolerance Value\n"
        "    0.2000,                  !- Temperature Convergence Tolerance Value {deltaC}\n"
        "    FullInteriorAndExterior, !- Solar Distribution\n"
        "    25,                      !- Maximum Number of Warmup Days\n"
        "    6;\n"
    )
    var output_vector = parse_object(test_object, index, success)
    assert_equal(
        List[String]("Building", "Ref Bldg Medium Office New2004_v1.3_5.0", "0.0000", "City", "0.0400", "0.2000", "FullInteriorAndExterior", "25", "6"),
        output_vector
    )
    assert_equal(test_object.size() - 1, index)
    assert_true(success)

def test_eat_whitespace():
    var index: Int = 0
    eat_whitespace("    test", index)
    assert_equal(4, index)
    index = 0
    eat_whitespace("t   test", index)
    assert_equal(0, index)

def test_eat_comment():
    var index: Int = 0
    eat_comment("!- North Axis {deg}\n", index)
    assert_equal(20, index)
    index = 0
    eat_comment("                    !- Terrain\n", index)
    assert_equal(31, index)
    index = 0
    eat_comment("  !- Name\n    0.0000", index)
    assert_equal(10, index)
    index = 0
    eat_comment("  !- Name\n\r    0.0000", index)
    assert_equal(10, index)

def test_parse_string():
    var index: Int = 0
    var success: Bool = True
    var output_string: String
    output_string = parse_string("test_string", index, success)
    assert_equal("test_string", output_string)
    assert_equal(11, index)
    assert_true(success)
    index = 0
    success = True
    output_string = parse_string("test string", index, success)
    assert_equal("test string", output_string)
    assert_equal(11, index)
    assert_true(success)
    index = 0
    success = True
    output_string = parse_string("-1234.1234", index, success)
    assert_equal("-1234.1234", output_string)
    assert_equal(10, index)
    assert_true(success)
    index = 0
    success = True
    output_string = parse_string("\\b\\t/\\\\\\\";", index, success)
    assert_equal("\b\t/\\\"", output_string)
    assert_equal(9, index)
    assert_true(success)
    index = 0
    success = True
    output_string = parse_string("test \\n string", index, success)
    assert_equal("", output_string)
    assert_equal(7, index)
    assert_false(success)
    index = 0
    success = True
    output_string = parse_string("! this is a comment \\n", index, success)
    assert_equal("", output_string)
    assert_equal(0, index)
    assert_true(success)

def test_parse_value():
    var index: Int = 0
    var success: Bool = True
    var output_string: String
    output_string = parse_value("test_string", index, success)
    assert_equal("test_string", output_string)
    assert_equal(11, index)
    assert_true(success)
    index = 0
    success = True
    output_string = parse_value(", test_string", index, success)
    assert_equal("", output_string)
    assert_equal(0, index)
    assert_false(success)
    index = 0
    success = True
    output_string = parse_value("test \\n string", index, success)
    assert_equal("", output_string)
    assert_equal(7, index)
    assert_false(success)
    index = 0
    success = True
    output_string = parse_value("; test_string", index, success)
    assert_equal("", output_string)
    assert_equal(0, index)
    assert_false(success)
    index = 0
    success = True
    output_string = parse_value("! test_string", index, success)
    assert_equal("", output_string)
    assert_equal(0, index)
    assert_false(success)

def test_look_ahead():
    var test_input: String = "B , ! t ; `"
    var index: Int = 0
    var token: IdfParser.Token = look_ahead(test_input, index)
    assert_equal(0, index)
    assert_equal(IdfParser.Token.STRING, token)
    index = 2
    token = look_ahead(test_input, index)
    assert_equal(2, index)
    assert_equal(IdfParser.Token.COMMA, token)
    index = 3
    token = look_ahead(test_input, index)
    assert_equal(3, index)
    assert_equal(IdfParser.Token.EXCLAMATION, token)
    index = 5
    token = look_ahead(test_input, index)
    assert_equal(5, index)
    assert_equal(IdfParser.Token.STRING, token)
    index = 7
    token = look_ahead(test_input, index)
    assert_equal(7, index)
    assert_equal(IdfParser.Token.SEMICOLON, token)
    index = 9
    token = look_ahead(test_input, index)
    assert_equal(9, index)
    assert_equal(IdfParser.Token.NONE, token)
    index = test_input.size()
    token = look_ahead(test_input, index)
    assert_equal(test_input.size(), index)
    assert_equal(IdfParser.Token.END, token)

def test_next_token():
    var index: Int = 0
    var test_input: String = "B , ! t ; `"
    var token: IdfParser.Token = next_token(test_input, index)
    assert_equal(1, index)
    assert_equal(IdfParser.Token.STRING, token)
    token = next_token(test_input, index)
    assert_equal(3, index)
    assert_equal(IdfParser.Token.COMMA, token)
    token = next_token(test_input, index)
    assert_equal(5, index)
    assert_equal(IdfParser.Token.EXCLAMATION, token)
    token = next_token(test_input, index)
    assert_equal(7, index)
    assert_equal(IdfParser.Token.STRING, token)
    token = next_token(test_input, index)
    assert_equal(9, index)
    assert_equal(IdfParser.Token.SEMICOLON, token)
    token = next_token(test_input, index)
    assert_equal(10, index)
    assert_equal(IdfParser.Token.NONE, token)
    index = test_input.size()
    token = next_token(test_input, index)
    assert_equal(test_input.size(), index)
    assert_equal(IdfParser.Token.END, token)
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, state, process_idf, delimited_string, match_err_stream, compare_err_stream
from EnergyPlus.IOFiles import format
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor

@test
def OutputFiles_Expected_Formatting_Tests():
    assert EnergyPlus.format("{:#11.{}F}", 123.456, 0) == "        123."
    assert EnergyPlus.format("{:#12.{}F}", 0.85505055394102414, 3) == "       0.855"
    assert EnergyPlus.format("{:#12.{}F}", 18229.761511696095, 2) == "    18229.76"
    assert EnergyPlus.format("{:12}", 4) == "           4"
    assert EnergyPlus.format("{:.4R}", 8.4138E-02) == "8.4138E-002"
    assert EnergyPlus.format("{:.4R}", 8.41385E-02) == "8.4139E-002"
    assert EnergyPlus.format("{:.4R}", 0.1518) == "0.1518"
    assert EnergyPlus.format("{:.4R}", 0.15185) == "0.1519"
    assert EnergyPlus.format("{:.2R}", 42.7350) == "42.74"
    assert EnergyPlus.format("{:.2R}", 42.73499999999999232614) == "42.74"
    assert EnergyPlus.format("{:.2R}", 42.734) == "42.73"
    assert EnergyPlus.format("{:.10R}", 0.14227301774935188772) == "0.1422730177"
    assert EnergyPlus.format("{:.10R}", 9.90178849143378697617E-02) == "9.9017884914E-002"
    assert EnergyPlus.format("{:.10R}", 0.15991370194912388203) == "0.1599137019"
    assert EnergyPlus.format("{:.3R}", 4.71499999999999974687E-02) == "4.715E-002"
    assert EnergyPlus.format("{:.3R}", 2.58370321661460875667E-04) == "2.584E-004"
    assert EnergyPlus.format("{:.3R}", 2.35749999999999978670E-03) == "2.358E-003"
    assert EnergyPlus.format("{:.3R}", 0.37915258851937216900) == "0.379"
    assert EnergyPlus.format("{:.3R}", 0.10589999999999999414) == "0.106"
    assert EnergyPlus.format("{:.3R}", 1.09763681592039800961E-03) == "1.098E-003"
    assert EnergyPlus.format("{:.3R}", 9.62727272727272737063E-03) == "9.627E-003"
    assert EnergyPlus.format("{:.3R}", 1.59349720571666519930) == "1.593"
    assert EnergyPlus.format("{:.10R}", 0.11686688704901793123) == "0.1168668870"
    assert EnergyPlus.format("{:.10R}", 0.14602401770121714586) == "0.1460240177"
    assert EnergyPlus.format("{:.10R}", 9.12850042469573067808E-016) == "9.1285004247E-016"
    assert EnergyPlus.format("{:.10R}", 1.60782525664980535959E-015) == "1.6078252566E-015"
    assert EnergyPlus.format("{:.10R}", 0.10797418337603230387) == "0.1079741834"
    assert EnergyPlus.format("{:.10R}", 0.14820485805540076218) == "0.1482048581"
    assert EnergyPlus.format("{:.10R}", 3.08684514533120978041E-002) == "3.0868451453E-002"
    assert EnergyPlus.format("{:.3R}", 7.63142731775999418747E-003) == "7.631E-003"
    assert EnergyPlus.format("{:.3R}", 1.28349999999999948505E-004) == "1.283E-004"
    assert EnergyPlus.format("{:.3R}", 2.56700000000000005430E-004) == "2.567E-004"
    assert EnergyPlus.format("{:.3R}", 0.15159450340364988286) == "0.152"
    assert EnergyPlus.format("{:.3R}", 2.14633893312000043063E-002) == "2.146E-002"
    assert EnergyPlus.format("{:.3R}", 8.55666666666666278192E-005) == "8.557E-005"
    assert EnergyPlus.format("{:.3R}", 6.41749999999999878051E-005) == "6.418E-005"
    assert EnergyPlus.format("{:.3R}", 0.10106298657208269420) == "0.101"
    assert EnergyPlus.format("{:.3R}", 5.72357048832000323002E-003) == "5.724E-003"
    assert EnergyPlus.format("{:.3R}", 8.55666666666666142667E-005) == "8.557E-005"
    assert EnergyPlus.format("{:.3R}", 6.41749999999999742525E-005) == "6.417E-005"
    assert EnergyPlus.format("{:.3R}", 0.10106298987671752387) == "0.101"
    assert EnergyPlus.format("{:.3R}", 7.86990942144000400760E-003) == "7.870E-003"
    assert EnergyPlus.format("{:.3R}", 8.55666666666666007142E-005) == "8.557E-005"
    assert EnergyPlus.format("{:.3R}", 6.41749999999999607000E-005) == "6.417E-005"
    assert EnergyPlus.format("{:.3R}", 0.10106298537039738739) == "0.101"
    assert EnergyPlus.format("{:.3R}", 2.14633893312000077758E-002) == "2.146E-002"
    assert EnergyPlus.format("{:.3R}", 8.55666666666666413717E-005) == "8.557E-005"
    assert EnergyPlus.format("{:.3R}", 0.10106298657208269420) == "0.101"
    assert EnergyPlus.format("{:.8R}", 3299120.2346041048876941) == "3299120.23460410"
    assert EnergyPlus.format("{:.5R}", 8678.2915949994276161) == "8678.29159"
    assert EnergyPlus.format("{:.5R}", 1000000000000000.00000) == "1000000000000000."
    assert EnergyPlus.format("{:.5R}", 2070.8390649997299988) == "2070.83906"
    assert EnergyPlus.format("{:.2R}", 166.60499927514288743) == "166.60"
    assert EnergyPlus.format("{:.5R}", 245.90393499959708379) == "245.90393"
    assert EnergyPlus.format("{:.3R}", 0.16149998966664602662) == "0.161"
    assert EnergyPlus.format("{:.3R}", 23.989999896666461154) == "23.990"
    assert EnergyPlus.format("{:.2R}", 42.734999999999985221) == "42.74"
    assert EnergyPlus.format("{:.3R}", 14391.882499999999709) == "14391.883"
    assert EnergyPlus.format("{:.2R}", -3.04999999999999760192) == "-3.05"
    assert EnergyPlus.format("{:.2R}", -2.28500000000000058620) == "-2.29"
    assert EnergyPlus.format("{:.2R}", -6.09999999999999609201) == "-6.10"
    assert EnergyPlus.format("{:.2R}", -4.57000017199999675199) == "-4.57"
    assert EnergyPlus.format("{:.2R}", -0.0) == "0.00"

@test
def OutputControlFiles():
    var idf_objects: String = delimited_string([
        "OutputControl:Files,",
        "  No,                      !- Output CSV",
        "  No,                      !- Output MTR",
        "  No,                      !- Output ESO",
        "  No,                      !- Output EIO",
        "  No,                      !- Output Tabular",
        "  Yes,                     !- Output SQLite",
        "  Yes,                     !- Output JSON",
        "  No,                      !- Output AUDIT",
        "  Yes,                     !- Output Zone Sizing",
        "  Yes,                     !- Output System Sizing",
        "  Yes,                     !- Output DXF",
        "  No,                      !- Output BND",
        "  No,                      !- Output RDD",
        "  No,                      !- Output MDD",
        "  No,                      !- Output MTD",
        "  Yes,                     !- Output END",
        "  No,                      !- Output SHD",
        "  Yes,                     !- Output DFS",
        "  Yes,                     !- Output GLHE",
        "  Yes,                     !- Output DelightIn",
        "  Yes,                     !- Output DelightELdmp",
        "  Yes,                     !- Output DelightDFdmp",
        "  Yes,                     !- Output EDD",
        "  Yes,                     !- Output DBG",
        "  Yes,                     !- Output PerfLog",
        "  Yes,                     !- Output SLN",
        "  Yes,                     !- Output SCI",
        "  Yes,                     !- Output WRL",
        "  Yes,                     !- Output Screen",
        "  Yes,                     !- Output ExtShd",
        "  Yes;                     !- Output Tarcog",
    ])
    assert_true(process_idf(idf_objects))
    state.files.outputControl.getInput(state)
    state.dataGlobal.DisplayUnusedObjects = True
    state.dataInputProcessing.inputProcessor.reportOrphanRecordObjects(state)
    assert_false(match_err_stream("OutputControl:Files"))
    var expected_error: String = delimited_string([
        "   ** Warning ** The following lines are \"Unused Objects\".  These objects are in the input",
        "   **   ~~~   **  file but are never obtained by the simulation and therefore are NOT used.",
        "   **   ~~~   **  Only the first unused named object of an object class is shown.  Use Output:Diagnostics,DisplayAllWarnings; to see all.",
        "   **   ~~~   **  See InputOutputReference document for more details.",
        "   ************* Object=Building=Bldg",
        "   **   ~~~   ** Object=GlobalGeometryRules",
        "   **   ~~~   ** Object=Timestep",
        "   **   ~~~   ** Object=Version",
    ])
    compare_err_stream(expected_error)

@test
def OutputControlFiles_GetInput():
    var idf_objects_fmt: String = \
        "OutputControl:Files,\n" + \
        "  {csv},              !- Output CSV\n" + \
        "  {mtr},              !- Output MTR\n" + \
        "  {eso},              !- Output ESO\n" + \
        "  {eio},              !- Output EIO\n" + \
        "  {tabular},          !- Output Tabular\n" + \
        "  {sqlite},           !- Output SQLite\n" + \
        "  {json},             !- Output JSON\n" + \
        "  {audit},            !- Output AUDIT\n" + \
        "  {spsz},             !- Output Space Sizing\n" + \
        "  {zsz},              !- Output Zone Sizing\n" + \
        "  {ssz},              !- Output System Sizing\n" + \
        "  {dxf},              !- Output DXF\n" + \
        "  {bnd},              !- Output BND\n" + \
        "  {rdd},              !- Output RDD\n" + \
        "  {mdd},              !- Output MDD\n" + \
        "  {mtd},              !- Output MTD\n" + \
        "  {end},              !- Output END\n" + \
        "  {shd},              !- Output SHD\n" + \
        "  {dfs},              !- Output DFS\n" + \
        "  {glhe},             !- Output GLHE\n" + \
        "  {delightin},        !- Output DelightIn\n" + \
        "  {delighteldmp},     !- Output DelightELdmp\n" + \
        "  {delightdfdmp},     !- Output DelightDFdmp\n" + \
        "  {edd},              !- Output EDD\n" + \
        "  {dbg},              !- Output DBG\n" + \
        "  {perflog},          !- Output PerfLog\n" + \
        "  {sln},              !- Output SLN\n" + \
        "  {sci},              !- Output SCI\n" + \
        "  {wrl},              !- Output WRL\n" + \
        "  {screen},           !- Output Screen\n" + \
        "  {extshd},           !- Output ExtShd\n" + \
        "  {tarcog};           !- Output Tarcog\n"

    def boolToString(b: Bool) -> String:
        return "Yes" if b else "No"

    for i in range(32):
        var csv: Bool = (i == 0)
        var mtr: Bool = (i == 1)
        var eso: Bool = (i == 2)
        var eio: Bool = (i == 3)
        var tabular: Bool = (i == 4)
        var sqlite: Bool = (i == 5)
        var json: Bool = (i == 6)
        var audit: Bool = (i == 7)
        var spsz: Bool = (i == 8)
        var zsz: Bool = (i == 9)
        var ssz: Bool = (i == 10)
        var dxf: Bool = (i == 11)
        var bnd: Bool = (i == 12)
        var rdd: Bool = (i == 13)
        var mdd: Bool = (i == 14)
        var mtd: Bool = (i == 15)
        var end: Bool = (i == 16)
        var shd: Bool = (i == 17)
        var dfs: Bool = (i == 18)
        var glhe: Bool = (i == 19)
        var delightin: Bool = (i == 20)
        var delighteldmp: Bool = (i == 21)
        var delightdfdmp: Bool = (i == 22)
        var edd: Bool = (i == 23)
        var dbg: Bool = (i == 24)
        var perflog: Bool = (i == 25)
        var sln: Bool = (i == 26)
        var sci: Bool = (i == 27)
        var wrl: Bool = (i == 28)
        var screen: Bool = (i == 29)
        var extshd: Bool = (i == 30)
        var tarcog: Bool = (i == 31)

        # Build the formatted string manually to avoid extra dependency
        var idf_objects: String = (idf_objects_fmt
            .replace("{csv}", boolToString(csv))
            .replace("{mtr}", boolToString(mtr))
            .replace("{eso}", boolToString(eso))
            .replace("{eio}", boolToString(eio))
            .replace("{tabular}", boolToString(tabular))
            .replace("{sqlite}", boolToString(sqlite))
            .replace("{json}", boolToString(json))
            .replace("{audit}", boolToString(audit))
            .replace("{spsz}", boolToString(spsz))
            .replace("{zsz}", boolToString(zsz))
            .replace("{ssz}", boolToString(ssz))
            .replace("{dxf}", boolToString(dxf))
            .replace("{bnd}", boolToString(bnd))
            .replace("{rdd}", boolToString(rdd))
            .replace("{mdd}", boolToString(mdd))
            .replace("{mtd}", boolToString(mtd))
            .replace("{end}", boolToString(end))
            .replace("{shd}", boolToString(shd))
            .replace("{dfs}", boolToString(dfs))
            .replace("{glhe}", boolToString(glhe))
            .replace("{delightin}", boolToString(delightin))
            .replace("{delighteldmp}", boolToString(delighteldmp))
            .replace("{delightdfdmp}", boolToString(delightdfdmp))
            .replace("{edd}", boolToString(edd))
            .replace("{dbg}", boolToString(dbg))
            .replace("{perflog}", boolToString(perflog))
            .replace("{sln}", boolToString(sln))
            .replace("{sci}", boolToString(sci))
            .replace("{wrl}", boolToString(wrl))
            .replace("{screen}", boolToString(screen))
            .replace("{extshd}", boolToString(extshd))
            .replace("{tarcog}", boolToString(tarcog))
        )

        assert_true(process_idf(idf_objects))
        state.files.outputControl.getInput(state)
        assert csv == state.files.outputControl.csv
        assert mtr == state.files.outputControl.mtr
        assert eso == state.files.outputControl.eso
        assert eio == state.files.outputControl.eio
        assert tabular == state.files.outputControl.tabular
        assert sqlite == state.files.outputControl.sqlite
        assert json == state.files.outputControl.json
        assert audit == state.files.outputControl.audit
        assert spsz == state.files.outputControl.spsz
        assert zsz == state.files.outputControl.zsz
        assert ssz == state.files.outputControl.ssz
        assert dxf == state.files.outputControl.dxf
        assert bnd == state.files.outputControl.bnd
        assert rdd == state.files.outputControl.rdd
        assert mdd == state.files.outputControl.mdd
        assert mtd == state.files.outputControl.mtd
        assert end == state.files.outputControl.end
        assert shd == state.files.outputControl.shd
        assert dfs == state.files.outputControl.dfs
        assert delightin == state.files.outputControl.delightin
        assert delighteldmp == state.files.outputControl.delighteldmp
        assert delightdfdmp == state.files.outputControl.delightdfdmp
        assert edd == state.files.outputControl.edd
        assert dbg == state.files.outputControl.dbg
        assert perflog == state.files.outputControl.perflog
        assert sln == state.files.outputControl.sln
        assert sci == state.files.outputControl.sci
        assert wrl == state.files.outputControl.wrl
        assert screen == state.files.outputControl.screen
        assert extshd == state.files.outputControl.extshd
        assert tarcog == state.files.outputControl.tarcog

        # Reset fields to false for next iteration (since state is reused)
        state.files.outputControl.csv = False
        state.files.outputControl.mtr = False
        state.files.outputControl.eso = False
        state.files.outputControl.eio = False
        state.files.outputControl.tabular = False
        state.files.outputControl.sqlite = False
        state.files.outputControl.json = False
        state.files.outputControl.audit = False
        state.files.outputControl.spsz = False
        state.files.outputControl.zsz = False
        state.files.outputControl.ssz = False
        state.files.outputControl.dxf = False
        state.files.outputControl.bnd = False
        state.files.outputControl.rdd = False
        state.files.outputControl.mdd = False
        state.files.outputControl.mtd = False
        state.files.outputControl.end = False
        state.files.outputControl.shd = False
        state.files.outputControl.dfs = False
        state.files.outputControl.delightin = False
        state.files.outputControl.delighteldmp = False
        state.files.outputControl.delightdfdmp = False
        state.files.outputControl.edd = False
        state.files.outputControl.dbg = False
        state.files.outputControl.perflog = False
        state.files.outputControl.sln = False
        state.files.outputControl.sci = False
        state.files.outputControl.wrl = False
        state.files.outputControl.screen = False
        state.files.outputControl.extshd = False
        state.files.outputControl.tarcog = False
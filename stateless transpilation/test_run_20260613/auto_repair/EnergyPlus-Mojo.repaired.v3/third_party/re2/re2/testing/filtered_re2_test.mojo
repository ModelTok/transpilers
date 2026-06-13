from util.test import *
from util.logging import *
from ..filtered_re2 import FilteredRE2
from ..re2 import RE2

struct FilterTestVars:
    var atoms: List[String]
    var atom_indices: List[Int]
    var matches: List[Int]
    var opts: RE2.Options
    var f: FilteredRE2

    def __init__(inout self):
        self.atoms = List[String]()
        self.atom_indices = List[Int]()
        self.matches = List[Int]()
        self.opts = RE2.Options()
        self.f = FilteredRE2()

    def __init__(inout self, min_atom_len: Int):
        self.atoms = List[String]()
        self.atom_indices = List[Int]()
        self.matches = List[Int]()
        self.opts = RE2.Options()
        self.f = FilteredRE2(min_atom_len)


def TestFilteredRE2Test_EmptyTest():
    var v = FilterTestVars()
    v.f.Compile(&v.atoms)
    EXPECT_EQ(0, len(v.atoms))
    v.f.AllMatches("foo", v.atom_indices, &v.matches)
    EXPECT_EQ(0, len(v.matches))


def TestFilteredRE2Test_SmallOrTest():
    var v = FilterTestVars(4)  # override the minimum atom length
    var id: Int
    v.f.Add("(foo|bar)", v.opts, &id)
    v.f.Compile(&v.atoms)
    EXPECT_EQ(0, len(v.atoms))
    v.f.AllMatches("lemurs bar", v.atom_indices, &v.matches)
    EXPECT_EQ(1, len(v.matches))
    EXPECT_EQ(id, v.matches[0])


def TestFilteredRE2Test_SmallLatinTest():
    var v = FilterTestVars()
    var id: Int
    v.opts.set_encoding(RE2.Options.EncodingLatin1())
    v.f.Add("\xde\xadQ\xbe\xef", v.opts, &id)
    v.f.Compile(&v.atoms)
    EXPECT_EQ(1, len(v.atoms))
    EXPECT_EQ(v.atoms[0], "\xde\xadq\xbe\xef")
    v.atom_indices.push_back(0)
    v.f.AllMatches("foo\xde\xadQ\xbe\xeflemur", v.atom_indices, &v.matches)
    EXPECT_EQ(1, len(v.matches))
    EXPECT_EQ(id, v.matches[0])


struct AtomTest:
    var testname: String
    var regexps: List[String]
    var atoms: List[String]

    def __init__(inout self, testname: String, regexps: List[String], atoms: List[String]):
        self.testname = testname
        self.regexps = regexps
        self.atoms = atoms


var atom_tests: List[AtomTest] = List[AtomTest](
    AtomTest(
        "CheckEmptyPattern",
        List[String](""),
        List[String]()
    ),
    AtomTest(
        "AllAtomsGtMinLengthFound",
        List[String]("(abc123|def456|ghi789).*mnop[x-z]+", "abc..yyy..zz", "mnmnpp[a-z]+PPP"),
        List[String]("abc123", "def456", "ghi789", "mnop", "abc", "yyy", "mnmnpp", "ppp")
    ),
    AtomTest(
        "SubstrAtomRemovesSuperStrInOr",
        List[String]("(abc123|abc|ghi789|abc1234).*[x-z]+", "abcd..yyy..yyyzzz", "mnmnpp[a-z]+PPP"),
        List[String]("abc", "ghi789", "abcd", "yyy", "yyyzzz", "mnmnpp", "ppp")
    ),
    AtomTest(
        "CharClassExpansion",
        List[String]("m[a-c][d-f]n.*[x-z]+", "[x-y]bcde[ab]"),
        List[String]("madn", "maen", "mafn", "mbdn", "mben", "mbfn", "mcdn", "mcen", "mcfn", "xbcdea", "xbcdeb", "ybcdea", "ybcdeb")
    ),
    AtomTest(
        "UnicodeLower",
        List[String]("(?i)ΔδΠϖπΣςσ", "ΛΜΝΟΠ", "ψρστυ"),
        List[String]("δδπππσσσ", "λμνοπ", "ψρστυ")
    )
)


def AddRegexpsAndCompile(regexps: List[String], n: Int, inout v: FilterTestVars):
    for i in range(n):
        var id: Int
        v.f.Add(regexps[i], v.opts, &id)
    v.f.Compile(&v.atoms)


def CheckExpectedAtoms(atoms: List[String], n: Int, testname: String, inout v: FilterTestVars) -> Bool:
    var expected = List[String]()
    for i in range(n):
        expected.append(atoms[i])
    var pass = len(expected) == len(v.atoms)
    v.atoms.sort()
    expected.sort()
    for i in range(n):
        if pass:
            pass = pass and expected[i] == v.atoms[i]
    if not pass:
        LOG(ERROR, "Failed ", testname)
        LOG(ERROR, "Expected #atoms = ", len(expected))
        for i in range(len(expected)):
            LOG(ERROR, expected[i])
        LOG(ERROR, "Found #atoms = ", len(v.atoms))
        for i in range(len(v.atoms)):
            LOG(ERROR, v.atoms[i])
    return pass


def TestFilteredRE2Test_AtomTests():
    var nfail = 0
    for i in range(len(atom_tests)):
        var v = FilterTestVars()
        var t = atom_tests[i]
        var nregexp: Int
        var natom: Int
        nregexp = 0
        while nregexp < len(t.regexps):
            if t.regexps[nregexp] == "":
                break
            nregexp += 1
        natom = 0
        while natom < len(t.atoms):
            if t.atoms[natom] == "":
                break
            natom += 1
        AddRegexpsAndCompile(t.regexps, nregexp, &v)
        if not CheckExpectedAtoms(t.atoms, natom, t.testname, &v):
            nfail += 1
    EXPECT_EQ(0, nfail)


def FindAtomIndices(atoms: List[String], matched_atoms: List[String], atom_indices: List[Int]):
    atom_indices.clear()
    for i in range(len(matched_atoms)):
        for j in range(len(atoms)):
            if matched_atoms[i] == atoms[j]:
                atom_indices.append(j)
                break


def TestFilteredRE2Test_MatchEmptyPattern():
    var v = FilterTestVars()
    var t = atom_tests[0]
    EXPECT_EQ("CheckEmptyPattern", String(t.testname))
    var nregexp: Int
    nregexp = 0
    while nregexp < len(t.regexps):
        if t.regexps[nregexp] == "":
            break
        nregexp += 1
    AddRegexpsAndCompile(t.regexps, nregexp, &v)
    var text = "0123"
    var atom_ids = List[Int]()
    var matching_regexps = List[Int]()
    EXPECT_EQ(0, v.f.FirstMatch(text, atom_ids))


def TestFilteredRE2Test_MatchTests():
    var v = FilterTestVars()
    var t = atom_tests[2]
    EXPECT_EQ("SubstrAtomRemovesSuperStrInOr", String(t.testname))
    var nregexp: Int
    nregexp = 0
    while nregexp < len(t.regexps):
        if t.regexps[nregexp] == "":
            break
        nregexp += 1
    AddRegexpsAndCompile(t.regexps, nregexp, &v)
    var text = "abc121212xyz"
    var atom_ids = List[Int]()
    var atoms = List[String]()
    atoms.append("abc")
    FindAtomIndices(v.atoms, atoms, &atom_ids)
    var matching_regexps = List[Int]()
    v.f.AllMatches(text, atom_ids, &matching_regexps)
    EXPECT_EQ(1, len(matching_regexps))
    text = "abc12312yyyzzz"
    atoms.clear()
    atoms.append("abc")
    atoms.append("yyy")
    atoms.append("yyyzzz")
    FindAtomIndices(v.atoms, atoms, &atom_ids)
    v.f.AllMatches(text, atom_ids, &matching_regexps)
    EXPECT_EQ(1, len(matching_regexps))
    text = "abcd12yyy32yyyzzz"
    atoms.clear()
    atoms.append("abc")
    atoms.append("abcd")
    atoms.append("yyy")
    atoms.append("yyyzzz")
    FindAtomIndices(v.atoms, atoms, &atom_ids)
    LOG(INFO, "S: ", len(atom_ids))
    for i in range(len(atom_ids)):
        LOG(INFO, "i: ", i, " : ", atom_ids[i])
    v.f.AllMatches(text, atom_ids, &matching_regexps)
    EXPECT_EQ(2, len(matching_regexps))


def TestFilteredRE2Test_EmptyStringInStringSetBug():
    var v = FilterTestVars(0)  # override the minimum atom length
    var regexps = List[String]("-R.+(|ADD=;AA){12}}")
    var atoms = List[String]("", "-r", "add=;aa", "}")
    AddRegexpsAndCompile(regexps, len(regexps), &v)
    EXPECT_TRUE(CheckExpectedAtoms(atoms, len(atoms), "EmptyStringInStringSetBug", &v))


def TestFilteredRE2Test_MoveSemantics():
    var v1 = FilterTestVars()
    var id: Int
    v1.f.Add("foo\\d+", v1.opts, &id)
    EXPECT_EQ(0, id)
    v1.f.Compile(&v1.atoms)
    EXPECT_EQ(1, len(v1.atoms))
    EXPECT_EQ("foo", v1.atoms[0])
    v1.f.AllMatches("abc foo1 xyz", List[Int](0), &v1.matches)
    EXPECT_EQ(1, len(v1.matches))
    EXPECT_EQ(0, v1.matches[0])
    v1.f.AllMatches("abc bar2 xyz", List[Int](0), &v1.matches)
    EXPECT_EQ(0, len(v1.matches))
    var v2 = FilterTestVars()
    v2.f = v1.f
    v2.f.AllMatches("abc foo1 xyz", List[Int](0), &v2.matches)
    EXPECT_EQ(1, len(v2.matches))
    EXPECT_EQ(0, v2.matches[0])
    v2.f.AllMatches("abc bar2 xyz", List[Int](0), &v2.matches)
    EXPECT_EQ(0, len(v2.matches))
    v1.f.Add("bar\\d+", v1.opts, &id)
    EXPECT_EQ(0, id)
    v1.f.Compile(&v1.atoms)
    EXPECT_EQ(1, len(v1.atoms))
    EXPECT_EQ("bar", v1.atoms[0])
    v1.f.AllMatches("abc foo1 xyz", List[Int](0), &v1.matches)
    EXPECT_EQ(0, len(v1.matches))
    v1.f.AllMatches("abc bar2 xyz", List[Int](0), &v1.matches)
    EXPECT_EQ(1, len(v1.matches))
    EXPECT_EQ(0, v1.matches[0])
    v1.f = v2.f
    v1.f.AllMatches("abc foo1 xyz", List[Int](0), &v1.matches)
    EXPECT_EQ(1, len(v1.matches))
    EXPECT_EQ(0, v1.matches[0])
    v1.f.AllMatches("abc bar2 xyz", List[Int](0), &v1.matches)
    EXPECT_EQ(0, len(v1.matches))
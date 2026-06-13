from  import RE2, StringPiece
from prefilter import Prefilter
from prefilter_tree import PrefilterTree
from util.util import *
from util.logging import log_error, log_dfatal

@value
struct FilteredRE2:
    var re2_vec_: List[Pointer[RE2]]
    var compiled_: Bool
    var prefilter_tree_: Pointer[PrefilterTree]

    def __init__(inout self):
        """FilteredRE2() : compiled_(false), prefilter_tree_(new PrefilterTree())"""
        self.compiled_ = False
        self.prefilter_tree_ = Pointer[PrefilterTree].new(PrefilterTree())
        self.re2_vec_ = List[Pointer[RE2]]()

    def __init__(inout self, min_atom_len: Int):
        """FilteredRE2(int min_atom_len) : compiled_(false), prefilter_tree_(new PrefilterTree(min_atom_len))"""
        self.compiled_ = False
        self.prefilter_tree_ = Pointer[PrefilterTree].new(PrefilterTree(min_atom_len))
        self.re2_vec_ = List[Pointer[RE2]]()

    def __del__(inout self):
        """FilteredRE2::~FilteredRE2()"""
        for i in range(len(self.re2_vec_)):
            delete self.re2_vec_[i]
        delete self.prefilter_tree_

    def __init__(inout self, owned other: Self):
        """FilteredRE2::FilteredRE2(FilteredRE2&& other)"""
        self.re2_vec_ = other.re2_vec_[:]  # shallow copy of pointers; ownership transferred
        self.compiled_ = other.compiled_
        self.prefilter_tree_ = other.prefilter_tree_
        other.re2_vec_.clear()
        other.re2_vec_.resize(0)  # shrink_to_fit equivalent
        other.compiled_ = False
        other.prefilter_tree_ = Pointer[PrefilterTree].new(PrefilterTree())

    def __move_assign__(inout self, owned other: Self):
        """FilteredRE2& FilteredRE2::operator=(FilteredRE2&& other)"""
        self.__del__()
        # (void) new (this) FilteredRE2(move(other));
        self.__init__(owned other)

    def Add(inout self, pattern: borrowed StringPiece, options: borrowed RE2.Options, inout id: Int) -> RE2.ErrorCode:
        """RE2::ErrorCode FilteredRE2::Add(StringPiece& pattern , const RE2::Options& options, int* id)"""
        var re: Pointer[RE2] = Pointer[RE2].new(RE2(pattern, options))
        var code: RE2.ErrorCode = re[].error_code()
        if not re[].ok():
            if options.log_errors():
                log_error("Couldn't compile regular expression, skipping: ", pattern, " due to error ", re[].error())
            delete re
        else:
            id = Int(len(self.re2_vec_))
            self.re2_vec_.append(re)
        return code

    def Compile(inout self, atoms: inout List[String]):
        """void FilteredRE2::Compile(vector<string>* atoms)"""
        if self.compiled_:
            log_error("Compile called already.")
            return
        if len(self.re2_vec_) == 0:
            log_error("Compile called before Add.")
            return
        for i in range(len(self.re2_vec_)):
            var prefilter: Pointer[Prefilter] = Prefilter.FromRE2(self.re2_vec_[i])
            self.prefilter_tree_[].Add(prefilter)
        atoms.clear()
        self.prefilter_tree_[].Compile(atoms)
        self.compiled_ = True

    def SlowFirstMatch(self, text: borrowed StringPiece) -> Int:
        """int FilteredRE2::SlowFirstMatch(StringPiece& text ) const"""
        for i in range(len(self.re2_vec_)):
            if RE2.PartialMatch(text, self.re2_vec_[i][]):
                return Int(i)
        return -1

    def FirstMatch(self, text: borrowed StringPiece, atoms: borrowed List[Int]) -> Int:
        """int FilteredRE2::FirstMatch(StringPiece& text , const vector<int>& atoms) const"""
        if not self.compiled_:
            log_dfatal("FirstMatch called before Compile.")
            return -1
        var regexps: List[Int] = List[Int]()
        self.prefilter_tree_[].RegexpsGivenStrings(atoms, &regexps)
        for i in range(len(regexps)):
            if RE2.PartialMatch(text, self.re2_vec_[regexps[i]][:]):
                return regexps[i]
        return -1

    def AllMatches(self, text: borrowed StringPiece, atoms: borrowed List[Int], matching_regexps: inout List[Int]) -> Bool:
        """bool FilteredRE2::AllMatches(StringPiece& text , const vector<int>& atoms, vector<int>* matching_regexps) const"""
        matching_regexps.clear()
        var regexps: List[Int] = List[Int]()
        self.prefilter_tree_[].RegexpsGivenStrings(atoms, &regexps)
        for i in range(len(regexps)):
            if RE2.PartialMatch(text, self.re2_vec_[regexps[i]][:]):
                matching_regexps.append(regexps[i])
        return not matching_regexps.is_empty()

    def AllPotentials(self, atoms: borrowed List[Int], potential_regexps: inout List[Int]) -> None:
        """void FilteredRE2::AllPotentials(const vector<int>& atoms, vector<int>* potential_regexps) const"""
        self.prefilter_tree_[].RegexpsGivenStrings(atoms, &potential_regexps)

    def RegexpsGivenStrings(self, matched_atoms: borrowed List[Int], passed_regexps: inout List[Int]):
        """void FilteredRE2::RegexpsGivenStrings(const vector<int>& matched_atoms, vector<int>* passed_regexps)"""
        self.prefilter_tree_[].RegexpsGivenStrings(matched_atoms, &passed_regexps)

    def PrintPrefilter(self, regexpid: Int):
        """void FilteredRE2::PrintPrefilter(int regexpid)"""
        self.prefilter_tree_[].PrintPrefilter(regexpid)

    def NumRegexps(self) -> Int:
        """int NumRegexps() const { return static_cast<int>(re2_vec_.size()); }"""
        return Int(len(self.re2_vec_))

    def GetRE2(self, regexpid: Int) -> ref RE2:
        """const RE2& GetRE2(int regexpid) const { return *re2_vec_[regexpid]; }"""
        return self.re2_vec_[regexpid][]
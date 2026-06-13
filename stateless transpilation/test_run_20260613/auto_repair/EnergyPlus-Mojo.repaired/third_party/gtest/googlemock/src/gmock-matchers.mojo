# File: gmock-matchers.mojo
# Faithful translation from C++ (gmock-matchers.cc)

from random import randint  # for Randomize

def FormatMatcherDescription(negation: Bool, matcher_name: String, param_values: List[String]) -> String:
    var result: String = ConvertIdentifierNameToWords(matcher_name)
    if param_values.size >= 1:
        result += " " + JoinAsTuple(param_values)
    return "not (" + result + ")" if negation else result

struct MaxBipartiteMatchState:
    var graph_: MatchMatrix
    var left_: List[UInt]
    var right_: List[UInt]

    def __init__(inout self: Self, graph: MatchMatrix):
        self.graph_ = graph
        self.left_ = List[UInt](size=graph.LhsSize(), fill=UInt.max)
        self.right_ = List[UInt](size=graph.RhsSize(), fill=UInt.max)

    def Compute(inout self: Self) -> ElementMatcherPairs:
        var seen: List[Int8] = List[Int8]()
        for ilhs in range(self.graph_.LhsSize()):
            check(self.left_[ilhs] == UInt.max) or abort("ilhs: " + str(ilhs) + ", left_[ilhs]: " + str(self.left_[ilhs]))
            seen = List[Int8](size=self.graph_.RhsSize(), fill=0)
            self.TryAugment(ilhs, inout seen)
        var result: ElementMatcherPairs = ElementMatcherPairs()
        for ilhs in range(self.left_.size):
            var irhs: UInt = self.left_[ilhs]
            if irhs == UInt.max:
                continue
            result.push_back(ElementMatcherPair(ilhs, irhs))
        return result

    def TryAugment(inout self: Self, ilhs: UInt, inout seen: List[Int8]) -> Bool:
        for irhs in range(self.graph_.RhsSize()):
            if seen[irhs]:
                continue
            if not self.graph_.HasEdge(ilhs, irhs):
                continue
            seen[irhs] = 1
            if self.right_[irhs] == UInt.max or self.TryAugment(self.right_[irhs], inout seen):
                self.left_[ilhs] = irhs
                self.right_[irhs] = ilhs
                return True
        return False

def FindMaxBipartiteMatching(g: MatchMatrix) -> ElementMatcherPairs:
    return MaxBipartiteMatchState(g).Compute()

def LogElementMatcherPairVec(pairs: ElementMatcherPairs, inout stream: String):
    var os: String = stream  # using string as output stream
    os += "{"
    var sep: String = ""
    for it in pairs:
        os += sep + "\n  ("
        os += "element #" + str(it.first) + ", "
        os += "matcher #" + str(it.second) + ")"
        sep = ","
    os += "\n}"
    stream = os  # assign back

impl MatchMatrix:
    def NextGraph(inout self: Self) -> Bool:
        for ilhs in range(self.LhsSize()):
            for irhs in range(self.RhsSize()):
                var b: Int8 = self.matched_[self.SpaceIndex(ilhs, irhs)]
                if not b:
                    self.matched_[self.SpaceIndex(ilhs, irhs)] = 1
                    return True
                self.matched_[self.SpaceIndex(ilhs, irhs)] = 0
        return False

    def Randomize(inout self: Self):
        for ilhs in range(self.LhsSize()):
            for irhs in range(self.RhsSize()):
                var b: Int8 = self.matched_[self.SpaceIndex(ilhs, irhs)]
                b = Int8(randint(0, 1))  # NOLINT

    def DebugString(inout self: Self) -> String:
        var ss: String = ""
        var sep: String = ""
        for i in range(self.LhsSize()):
            ss += sep
            for j in range(self.RhsSize()):
                ss += str(Int8(self.HasEdge(i, j)))
            sep = ";"
        return ss

    def SpaceIndex(self: Self, ilhs: UInt, irhs: UInt) -> UInt:
        return ilhs * self.RhsSize() + irhs

impl UnorderedElementsAreMatcherImplBase:
    def DescribeToImpl(inout self: Self, inout os: String):
        if self.match_flags() == UnorderedMatcherRequire.ExactMatch:
            if self.matcher_describers_.empty():
                os += "is empty"
                return
            if self.matcher_describers_.size() == 1:
                os += "has " + Elements(1) + " and that element "
                self.matcher_describers_[0].DescribeTo(inout os)
                return
            os += "has " + Elements(self.matcher_describers_.size()) + " and there exists some permutation of elements such that:\n"
        elif self.match_flags() == UnorderedMatcherRequire.Superset:
            os += "a surjection from elements to requirements exists such that:\n"
        elif self.match_flags() == UnorderedMatcherRequire.Subset:
            os += "an injection from elements to requirements exists such that:\n"
        var sep: String = ""
        for i in range(self.matcher_describers_.size()):
            os += sep
            if self.match_flags() == UnorderedMatcherRequire.ExactMatch:
                os += " - element #" + str(i) + " "
            else:
                os += " - an element "
            self.matcher_describers_[i].DescribeTo(inout os)
            if self.match_flags() == UnorderedMatcherRequire.ExactMatch:
                sep = ", and\n"
            else:
                sep = "\n"

    def DescribeNegationToImpl(inout self: Self, inout os: String):
        if self.match_flags() == UnorderedMatcherRequire.ExactMatch:
            if self.matcher_describers_.empty():
                os += "isn't empty"
                return
            if self.matcher_describers_.size() == 1:
                os += "doesn't have " + Elements(1) + ", or has " + Elements(1) + " that "
                self.matcher_describers_[0].DescribeNegationTo(inout os)
                return
            os += "doesn't have " + Elements(self.matcher_describers_.size()) + ", or there exists no permutation of elements such that:\n"
        elif self.match_flags() == UnorderedMatcherRequire.Superset:
            os += "no surjection from elements to requirements exists such that:\n"
        elif self.match_flags() == UnorderedMatcherRequire.Subset:
            os += "no injection from elements to requirements exists such that:\n"
        var sep: String = ""
        for i in range(self.matcher_describers_.size()):
            os += sep
            if self.match_flags() == UnorderedMatcherRequire.ExactMatch:
                os += " - element #" + str(i) + " "
            else:
                os += " - an element "
            self.matcher_describers_[i].DescribeTo(inout os)
            if self.match_flags() == UnorderedMatcherRequire.ExactMatch:
                sep = ", and\n"
            else:
                sep = "\n"

    def VerifyMatchMatrix(inout self: Self, element_printouts: List[String], matrix: MatchMatrix, inout listener: MatchResultListener) -> Bool:
        var result: Bool = True
        var element_matched: List[Int8] = List[Int8](size=matrix.LhsSize(), fill=0)
        var matcher_matched: List[Int8] = List[Int8](size=matrix.RhsSize(), fill=0)
        for ilhs in range(matrix.LhsSize()):
            for irhs in range(matrix.RhsSize()):
                var matched: Int8 = Int8(matrix.HasEdge(ilhs, irhs))
                element_matched[ilhs] |= matched
                matcher_matched[irhs] |= matched
        if self.match_flags() & UnorderedMatcherRequire.Superset:
            var sep: String = "where the following matchers don't match any elements:\n"
            for mi in range(matcher_matched.size):
                if matcher_matched[mi]:
                    continue
                result = False
                if listener.IsInterested():
                    listener.stream()[] += sep + "matcher #" + str(mi) + ": "
                    self.matcher_describers_[mi].DescribeTo(listener.stream())
                    sep = ",\n"
        if self.match_flags() & UnorderedMatcherRequire.Subset:
            var sep: String = "where the following elements don't match any matchers:\n"
            var outer_sep: String = ""
            if not result:
                outer_sep = "\nand "
            for ei in range(element_matched.size):
                if element_matched[ei]:
                    continue
                result = False
                if listener.IsInterested():
                    listener.stream()[] += outer_sep + sep + "element #" + str(ei) + ": " + element_printouts[ei]
                    sep = ",\n"
                    outer_sep = ""
        return result

    def FindPairing(inout self: Self, matrix: MatchMatrix, inout listener: MatchResultListener) -> Bool:
        var matches: ElementMatcherPairs = FindMaxBipartiteMatching(matrix)
        var max_flow: UInt = matches.size()
        if (self.match_flags() & UnorderedMatcherRequire.Superset) and max_flow < matrix.RhsSize():
            if listener.IsInterested():
                listener.stream()[] += "where no permutation of the elements can satisfy all matchers, and the closest match is " + str(max_flow) + " of " + str(matrix.RhsSize()) + " matchers with the pairings:\n"
                LogElementMatcherPairVec(matches, inout listener.stream()[])
            return False
        if (self.match_flags() & UnorderedMatcherRequire.Subset) and max_flow < matrix.LhsSize():
            if listener.IsInterested():
                listener.stream()[] += "where not all elements can be matched, and the closest match is " + str(max_flow) + " of " + str(matrix.RhsSize()) + " matchers with the pairings:\n"
                LogElementMatcherPairVec(matches, inout listener.stream()[])
            return False
        if matches.size() > 1:
            if listener.IsInterested():
                var sep: String = "where:\n"
                for mi in range(matches.size()):
                    listener.stream()[] += sep + " - element #" + str(matches[mi].first) + " is matched by matcher #" + str(matches[mi].second)
                    sep = ",\n"
        return True
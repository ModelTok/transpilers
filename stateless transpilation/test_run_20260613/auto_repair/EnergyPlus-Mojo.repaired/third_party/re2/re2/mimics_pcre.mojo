from util.util import *
from util.logging import *
from re2.regexp import *
from re2.walker-inl import *

@value
struct PCREWalker(RegexpWalkerBool):
    var parent: PCREWalker

    def __init__(inout self):

    def PostVisit(inout self, re: Regexp, parent_arg: Bool, pre_arg: Bool, child_args: Pointer[Bool], nchild_args: Int) -> Bool:
        for i in range(nchild_args):
            if not child_args[i]:
                return False
        var op = re.op()
        if op == kRegexpStar or op == kRegexpPlus or op == kRegexpQuest:
            if CanBeEmptyString(re.sub()[0]):
                return False
        elif op == kRegexpRepeat:
            if re.max() == -1 and CanBeEmptyString(re.sub()[0]):
                return False
        elif op == kRegexpLiteral:
            if re.rune() == '\v':
                return False
        elif op == kRegexpEndText or op == kRegexpEmptyMatch:
            if re.parse_flags() & Regexp.WasDollar:
                return False
        elif op == kRegexpBeginLine:
            return False
        return True

    def ShortVisit(inout self, re: Regexp, a: Bool) -> Bool:
        #ifndef FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
        LOG(DFATAL, "PCREWalker::ShortVisit called")
        #endif
        return a

@value
struct EmptyStringWalker(RegexpWalkerBool):
    var parent: EmptyStringWalker

    def __init__(inout self):

    def PostVisit(inout self, re: Regexp, parent_arg: Bool, pre_arg: Bool, child_args: Pointer[Bool], nchild_args: Int) -> Bool:
        var op = re.op()
        if op == kRegexpNoMatch or op == kRegexpLiteral or op == kRegexpAnyChar or op == kRegexpAnyByte or op == kRegexpCharClass or op == kRegexpLiteralString:
            return False
        elif op == kRegexpEmptyMatch or op == kRegexpBeginLine or op == kRegexpEndLine or op == kRegexpNoWordBoundary or op == kRegexpWordBoundary or op == kRegexpBeginText or op == kRegexpEndText or op == kRegexpStar or op == kRegexpQuest or op == kRegexpHaveMatch:
            return True
        elif op == kRegexpConcat:
            for i in range(nchild_args):
                if not child_args[i]:
                    return False
            return True
        elif op == kRegexpAlternate:
            for i in range(nchild_args):
                if child_args[i]:
                    return True
            return False
        elif op == kRegexpPlus or op == kRegexpCapture:
            return child_args[0]
        elif op == kRegexpRepeat:
            return child_args[0] or re.min() == 0
        return False

    def ShortVisit(inout self, re: Regexp, a: Bool) -> Bool:
        #ifndef FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
        LOG(DFATAL, "EmptyStringWalker::ShortVisit called")
        #endif
        return a

def CanBeEmptyString(re: Regexp) -> Bool:
    var w = EmptyStringWalker()
    return w.Walk(re, True)

def MimicsPCRE(self: Regexp) -> Bool:
    var w = PCREWalker()
    return w.Walk(self, True)
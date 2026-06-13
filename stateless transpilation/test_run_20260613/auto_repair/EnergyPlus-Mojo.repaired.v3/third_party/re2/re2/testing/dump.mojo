from util.strutil import StringPrintf
from util.utf import Rune, runetochar, UTFmax
from util.logging import LOG, DFATAL
from util.test import TempDir, CHECK
from ..regexp import *

static let kOpcodeNames = List[String](
    "bad",
    "no",
    "emp",
    "lit",
    "str",
    "cat",
    "alt",
    "star",
    "plus",
    "que",
    "rep",
    "cap",
    "dot",
    "byte",
    "bol",
    "eol",
    "wb",   # kRegexpWordBoundary
    "nwb",  # kRegexpNoWordBoundary
    "bot",
    "eot",
    "cc",
    "match",
)

static def DumpRegexpAppending(re: Regexp, inout s: String):
    if re.op() < 0 or re.op() >= len(kOpcodeNames):
        s += StringPrintf("op%d", re.op())
    else:
        if re.op() in (kRegexpStar, kRegexpPlus, kRegexpQuest, kRegexpRepeat):
            if re.parse_flags() & Regexp.NonGreedy:
                s.append("n")
        s.append(kOpcodeNames[re.op()])
        if re.op() == kRegexpLiteral and (re.parse_flags() & Regexp.FoldCase):
            let r: Rune = re.rune()
            if 'a'.ord() <= r and r <= 'z'.ord():
                s.append("fold")
        if re.op() == kRegexpLiteralString and (re.parse_flags() & Regexp.FoldCase):
            for i in range(re.nrunes()):
                let r: Rune = re.runes()[i]
                if 'a'.ord() <= r and r <= 'z'.ord():
                    s.append("fold")
                    break
    s.append("{")
    if re.op() == kRegexpEndText:
        if not (re.parse_flags() & Regexp.WasDollar):
            s.append("\\z")
    elif re.op() == kRegexpLiteral:
        let r: Rune = re.rune()
        var buf = Array[UInt8, UTFmax+1]()
        let n = runetochar(buf, r)
        s.append(String(buf[:n]))
    elif re.op() == kRegexpLiteralString:
        for i in range(re.nrunes()):
            let r: Rune = re.runes()[i]
            var buf = Array[UInt8, UTFmax+1]()
            let n = runetochar(buf, r)
            s.append(String(buf[:n]))
    elif re.op() == kRegexpConcat or re.op() == kRegexpAlternate:
        for i in range(re.nsub()):
            DumpRegexpAppending(re.sub()[i], s)
    elif re.op() in (kRegexpStar, kRegexpPlus, kRegexpQuest):
        DumpRegexpAppending(re.sub()[0], s)
    elif re.op() == kRegexpCapture:
        if re.cap() == 0:
            LOG(DFATAL, "kRegexpCapture cap() == 0")
        if re.name():
            s.append(*re.name())
            s.append(":")
        DumpRegexpAppending(re.sub()[0], s)
    elif re.op() == kRegexpRepeat:
        s.append(StringPrintf("%d,%d ", re.min(), re.max()))
        DumpRegexpAppending(re.sub()[0], s)
    elif re.op() == kRegexpCharClass:
        var sep = ""
        for rr in re.cc():
            let lo = rr.lo
            let hi = rr.hi
            s.append(sep)
            if lo == hi:
                s.append(StringPrintf("%#x", lo))
            else:
                s.append(StringPrintf("%#x-%#x", lo, hi))
            sep = " "
    s.append("}")

impl Regexp:
    def Dump(self) -> String:
        CHECK(not TempDir().empty())
        var s = String()
        DumpRegexpAppending(self, s)
        return s
from util.util import arraysize, CEscape, StringPrintf, Rune, chartorune
from util.test import *
from util.logging import LOG, FATAL
from util.strutil import *
from util.utf import *
from ..stringpiece import StringPiece
from regexp_generator import RegexpGenerator, Explode, Split

import random
import stdlib

@value
struct RegexpGenerator:
    var maxatoms_: Int
    var maxops_: Int
    var atoms_: List[String]
    var ops_: List[String]
    var rng_: stdlib.random.Random

    def __init__(inout self, maxatoms: Int, maxops: Int, atoms: List[String], ops: List[String]):
        self.maxatoms_ = maxatoms
        self.maxops_ = maxops
        self.atoms_ = atoms
        self.ops_ = ops
        if len(self.atoms_) == 0:
            self.maxatoms_ = 0
        if len(self.ops_) == 0:
            self.maxops_ = 0
        self.rng_ = stdlib.random.Random()

    def __del__(owned self):

    def Generate(inout self):
        var postfix = List[String]()
        self.GeneratePostfix(&postfix, 0, 0, 0)

    def GenerateRandom(inout self, seed: Int32, n: Int):
        self.rng_.seed(seed)
        for i in range(n):
            var postfix = List[String]()
            self.GenerateRandomPostfix(&postfix, 0, 0, 0)

    def HandleRegexp(self, regexp: String): ...

    @staticmethod
    def EgrepOps() -> List[String]:
        var ops = List[String]("%s%s", "%s|%s", "%s*", "%s+", "%s?", "%s\\C*")
        return ops

    def CountArgs(s: String) -> Int:
        var p = s.c_str()
        var n = 0
        while True:
            var found = p.find("%s")
            if found == -1:
                break
            p = p[found + 2:]
            n += 1
        return n

    def GeneratePostfix(inout self, post: Pointer[List[String]], nstk: Int, ops: Int, atoms: Int):
        if nstk == 1:
            self.RunPostfix(post[])
        if ops + nstk - 1 > self.maxops_:
            return
        if atoms < self.maxatoms_:
            for i in range(len(self.atoms_)):
                post[].append(self.atoms_[i])
                self.GeneratePostfix(post, nstk + 1, ops, atoms + 1)
                post[].pop_back()
        if ops < self.maxops_:
            for i in range(len(self.ops_)):
                var fmt = self.ops_[i]
                var nargs = self.CountArgs(fmt)
                if nargs <= nstk:
                    post[].append(fmt)
                    self.GeneratePostfix(post, nstk - nargs + 1, ops + 1, atoms)
                    post[].pop_back()

    def GenerateRandomPostfix(inout self, post: Pointer[List[String]], nstk: Int, ops: Int, atoms: Int) -> Bool:
        var random_stop = stdlib.random.uniform_int(0, self.maxatoms_ - atoms)
        var random_bit = stdlib.random.uniform_int(0, 1)
        var random_ops_index = stdlib.random.uniform_int(0, len(self.ops_) - 1)
        var random_atoms_index = stdlib.random.uniform_int(0, len(self.atoms_) - 1)
        while True:
            if nstk == 1 and random_stop(self.rng_) == 0:
                self.RunPostfix(post[])
                return True
            if ops + nstk - 1 > self.maxops_:
                return False
            if ops < self.maxops_ and random_bit(self.rng_) == 0:
                var fmt = self.ops_[random_ops_index(self.rng_)]
                var nargs = self.CountArgs(fmt)
                if nargs <= nstk:
                    post[].append(fmt)
                    var ret = self.GenerateRandomPostfix(post, nstk - nargs + 1, ops + 1, atoms)
                    post[].pop_back()
                    if ret:
                        return True
            if atoms < self.maxatoms_ and random_bit(self.rng_) == 0:
                post[].append(self.atoms_[random_atoms_index(self.rng_)])
                var ret = self.GenerateRandomPostfix(post, nstk + 1, ops, atoms + 1)
                post[].pop_back()
                if ret:
                    return True

    def RunPostfix(self, post: List[String]):
        var regexps = List[String]()
        for i in range(len(post)):
            var nargs = self.CountArgs(post[i])
            if nargs == 0:
                regexps.append(post[i])
            elif nargs == 1:
                var a = regexps.top()
                regexps.pop()
                regexps.append("(?:" + StringPrintf(post[i].c_str(), a.c_str()) + ")")
            elif nargs == 2:
                var b = regexps.top()
                regexps.pop()
                var a = regexps.top()
                regexps.pop()
                regexps.append("(?:" + StringPrintf(post[i].c_str(), a.c_str(), b.c_str()) + ")")
            else:
                LOG(FATAL) << "Bad operator: " << post[i]
        if len(regexps) != 1:
            printf("Bad regexp program:\n")
            for i in range(len(post)):
                printf("  %s\n", CEscape(post[i]).c_str())
            printf("Stack after running program:\n")
            while len(regexps) > 0:
                printf("  %s\n", CEscape(regexps.top()).c_str())
                regexps.pop()
            LOG(FATAL) << "Bad regexp program."
        self.HandleRegexp(regexps.top())
        self.HandleRegexp("^(?:" + regexps.top() + ")$")
        self.HandleRegexp("^(?:" + regexps.top() + ")")
        self.HandleRegexp("(?:" + regexps.top() + ")$")

def Explode(s: StringPiece) -> List[String]:
    var v = List[String]()
    var q = s.data()
    while q < s.data() + s.size():
        var p = q
        var r: Rune
        q += chartorune(&r, q)
        v.append(String(p, q - p))
    return v

def Split(sep: StringPiece, s: StringPiece) -> List[String]:
    var v = List[String]()
    if sep.empty():
        return Explode(s)
    var p = s.data()
    var q = s.data()
    while q + sep.size() <= s.data() + s.size():
        if StringPiece(q, sep.size()) == sep:
            v.append(String(p, q - p))
            p = q + sep.size()
            q = p - 1
            continue
        q += 1
    if p < s.data() + s.size():
        v.append(String(p, s.data() + s.size() - p))
    return v
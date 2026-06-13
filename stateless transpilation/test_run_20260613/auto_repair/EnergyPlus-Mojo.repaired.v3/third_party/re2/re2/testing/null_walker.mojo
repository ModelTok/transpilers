from util.test import *
from util.logging import *
from ..regexp import Regexp
from re2.walker-inl import Walker

# Simulate preprocessor macro for fuzzing mode
let FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION = False

class NullWalker(Regexp.Walker[Bool]):
    def __init__(inout self):

    def PostVisit(inout self, re: Regexp, parent_arg: Bool, pre_arg: Bool,
                 child_args: Pointer[Bool], nchild_args: Int) -> Bool:
        return False

    def ShortVisit(inout self, re: Regexp, a: Bool) -> Bool:
        if not FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION:
            LOG(DFATAL)[]("NullWalker::ShortVisit called")
        return a

    # Deleted copy constructor and assignment operator
    def __copy__(inout self, other: NullWalker) = deleted
    def __assign__(inout self, other: NullWalker) -> Self = deleted

def Regexp.NullWalk(mut self):
    let w = NullWalker()
    w.Walk(self, False)
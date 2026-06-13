from gtest import *
from test.googletest-param-test-test import *
from testing import Values
from testing.internal import ParamGenerator

var extern_gen: ParamGenerator[Int] = Values(33)
INSTANTIATE_TEST_SUITE_P(MultiplesOf33,
                         ExternalInstantiationTest,
                         Values(33, 66))
INSTANTIATE_TEST_SUITE_P(Sequence2,
                         InstantiationInMultipleTranslationUnitsTest,
                         Values(42*3, 42*4, 42*5))
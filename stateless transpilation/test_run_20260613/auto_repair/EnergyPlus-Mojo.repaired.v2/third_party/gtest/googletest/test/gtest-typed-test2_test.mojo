from test.gtest-typed-test_test import *
from gtest.gtest import *
from memory.vector import Vector

INSTANTIATE_TYPED_TEST_SUITE_P(Vector, ContainerTest,
                               testing.Types[Vector[Int]])
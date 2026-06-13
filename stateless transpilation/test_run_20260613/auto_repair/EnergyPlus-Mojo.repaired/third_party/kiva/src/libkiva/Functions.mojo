/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
# ifndef Functions_CPP
# define Functions_CPP
from Functions import *
from math import fabs
from memory import Pointer
from utils import Vector
alias Double = Float64
alias Int = Int32
alias Size = Int
alias LIBKIVA_EXPORT = True

def isLessThan(first: Double, second: Double, epsilon: Double = EPSILON) -> Bool:
  if first - second < -epsilon:
    return True
  else:
    return False

def isLessOrEqual(first: Double, second: Double, epsilon: Double = EPSILON) -> Bool:
  if first - second < epsilon:
    return True
  else:
    return False

def isEqual(first: Double, second: Double, epsilon: Double = EPSILON) -> Bool:
  if fabs(first - second) < epsilon:
    return True
  else:
    return False

def isGreaterThan(first: Double, second: Double, epsilon: Double = EPSILON) -> Bool:
  if first - second > epsilon:
    return True
  else:
    return False

def isGreaterOrEqual(first: Double, second: Double, epsilon: Double = EPSILON) -> Bool:
  if first - second > -epsilon:
    return True
  else:
    return False

def isOdd(N: Int) -> Bool: return (N % 2 != 0)

def isEven(N: Int) -> Bool: return (N % 2 == 0)

def solveTDM(a1: Vector[Double], a2: Vector[Double], a3: Vector[Double], b: Vector[Double], x: Vector[Double]):
  var N: Size = b.size
  var i_max: Size = N - 1
  var i: Size
  var a1_: Pointer[Double] = a1.data
  var a2_: Pointer[Double] = a2.data
  var a3_: Pointer[Double] = a3.data
  var b_: Pointer[Double] = b.data
  var x_: Pointer[Double] = x.data
  a3_[0] /= a2_[0]
  b_[0] /= a2_[0]
  for i in range(1, N):
    a3_[i] /= a2_[i] - a1_[i] * a3_[i - 1]
    b_[i] = (b_[i] - a1_[i] * b_[i - 1]) / (a2_[i] - a1_[i] * a3_[i - 1])
  x_[i_max] = b_[i_max]
  for i in range(i_max, 0, -1):
    x_[i] = b_[i] - a3_[i] * x_[i + 1]
# endif
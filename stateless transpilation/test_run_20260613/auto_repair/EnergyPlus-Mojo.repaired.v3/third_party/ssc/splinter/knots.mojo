/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from algorithm import is_sorted, count
from knots import *

namespace SPLINTER:

    def isKnotVectorRegular(knots: std.vector[Float64], degree: UInt) -> Bool:
        if len(knots) < 2 * (degree + 1):
            return False
        if not is_sorted(knots.begin(), knots.end()):
            return False
        for it in range(knots.begin(), knots.end()):
            if count(knots.begin(), knots.end(), *it) > degree + 1:
                return False
        return True

    def isKnotVectorClamped(knots: std.vector[Float64], degree: UInt) -> Bool:
        if count(knots.begin(), knots.begin() + degree + 1, knots.front()) != degree + 1:
            return False
        if count(knots.end() - degree - 1, knots.end(), knots.back()) != degree + 1:
            return False
        return True

    def isKnotVectorRefinement(knots: std.vector[Float64], refinedKnots: std.vector[Float64]) -> Bool:
        if len(refinedKnots) < len(knots):
            return False
        for it in range(knots.begin(), knots.end()):
            var m_tau: Int = count(knots.begin(), knots.end(), *it)
            var m_t: Int = count(refinedKnots.begin(), refinedKnots.end(), *it)
            if m_t < m_tau:
                return False
        if knots.front() != refinedKnots.front():
            return False
        if knots.back() != refinedKnots.back():
            return False
        return True
/*
 * This file is part of the SPLINTER library.
 * Copyright (C) 2012 Bjarne Grimstad (bjarne.grimstad@gmail.com).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
from definitions import SparseMatrix, SparseVector, DenseVector
from python import Python

let np = Python.import_module("numpy")
let sp = Python.import_module("scipy.sparse")

# Helper: convert SparseVector to a 2D sparse matrix (row vector)
def _sparse_vector_to_matrix(vec: SparseVector) -> SparseMatrix:
    # Assume vec is a 1D sparse vector (csc_matrix with shape (1, n) or (n, 1))
    # We'll treat it as a row vector (1, n)
    return sp.csc_matrix(vec.reshape(1, -1))

# Helper: convert DenseVector to a 2D array (row vector)
def _dense_vector_to_matrix(vec: DenseVector) -> DenseVector:
    return vec.reshape(1, -1)

# Kronecker product for SparseMatrix (using scipy.sparse.kron)
def kroneckerProduct(A: SparseMatrix, B: SparseMatrix) -> SparseMatrix:
    return sp.kron(A, B, format="csc")

# Kronecker product for SparseVector (treat as 1xN matrices)
def kroneckerProduct(A: SparseVector, B: SparseVector) -> SparseVector:
    let A_mat = _sparse_vector_to_matrix(A)
    let B_mat = _sparse_vector_to_matrix(B)
    let result = sp.kron(A_mat, B_mat, format="csc")
    # Flatten back to 1D sparse vector (row vector)
    return result.reshape(-1)

# Kronecker product for DenseVector (using numpy.kron)
def kroneckerProduct(A: DenseVector, B: DenseVector) -> DenseVector:
    return np.kron(A, B)

# Custom Kronecker product (optimized version)
def myKroneckerProduct(A: SparseMatrix, B: SparseMatrix) -> SparseMatrix:
    let AB = sp.csc_matrix((A.shape[0] * B.shape[0], A.shape[1] * B.shape[1]))
    let nnzA = np.zeros(A.shape[1], dtype=np.int32)
    let nnzB = np.zeros(B.shape[1], dtype=np.int32)
    let nnzAB = np.zeros(AB.shape[1], dtype=np.int32)

    # Count non-zeros per column in A
    for jA in range(A.shape[1]):
        let col_start = A.indptr[jA]
        let col_end = A.indptr[jA + 1]
        nnzA[jA] = col_end - col_start

    # Count non-zeros per column in B
    for jB in range(B.shape[1]):
        let col_start = B.indptr[jB]
        let col_end = B.indptr[jB + 1]
        nnzB[jB] = col_end - col_start

    # Compute nnz per column for AB
    let innz = 0
    for i in range(nnzA.size):
        for j in range(nnzB.size):
            nnzAB[innz] = nnzA[i] * nnzB[j]
            innz += 1

    # Reserve space (not directly needed in scipy, but we'll build COO)
    let tolerance = np.finfo(np.float64).eps

    # Build lists for COO format
    var rows = List[Int]()
    var cols = List[Int]()
    var vals = List[Float64]()

    for jA in range(A.shape[1]):
        let col_start_A = A.indptr[jA]
        let col_end_A = A.indptr[jA + 1]
        for idxA in range(col_start_A, col_end_A):
            let rowA = A.indices[idxA]
            let valA = A.data[idxA]
            if abs(valA) > tolerance:
                let jrow = rowA * B.shape[0]
                let jcol = jA * B.shape[1]
                for jB in range(B.shape[1]):
                    let col_start_B = B.indptr[jB]
                    let col_end_B = B.indptr[jB + 1]
                    for idxB in range(col_start_B, col_end_B):
                        let rowB = B.indices[idxB]
                        let valB = B.data[idxB]
                        let product = valA * valB
                        if abs(product) > tolerance:
                            let row = jrow + rowB
                            let col = jcol + jB
                            rows.append(row)
                            cols.append(col)
                            vals.append(product)

    # Build sparse matrix from COO
    let AB_final = sp.csc_matrix((vals, (rows, cols)), shape=AB.shape)
    return AB_final

def kroneckerProductVectors(vectors: List[SparseVector]) -> SparseVector:
    var temp1 = sp.csc_matrix((1, 1))
    temp1[0, 0] = 1.0
    var temp2 = temp1.copy()
    var counter = 0
    for vec in vectors:
        if counter % 2 == 0:
            temp1 = kroneckerProduct(temp2, vec)
        else:
            temp2 = kroneckerProduct(temp1, vec)
        counter += 1
    if counter % 2 == 0:
        return temp2
    return temp1

def kroneckerProductVectors(vectors: List[DenseVector]) -> DenseVector:
    var temp1 = np.array([1.0])
    var temp2 = temp1.copy()
    var counter = 0
    for vec in vectors:
        if counter % 2 == 0:
            temp1 = kroneckerProduct(temp2, vec)
        else:
            temp2 = kroneckerProduct(temp1, vec)
        counter += 1
    if counter % 2 == 0:
        return temp2
    return temp1

def kroneckerProductMatrices(matrices: List[SparseMatrix]) -> SparseMatrix:
    var temp1 = sp.csc_matrix((1, 1))
    temp1[0, 0] = 1.0
    var temp2 = temp1.copy()
    var counter = 0
    for mat in matrices:
        if counter % 2 == 0:
            temp1 = kroneckerProduct(temp2, mat)
        else:
            temp2 = kroneckerProduct(temp1, mat)
        counter += 1
    if counter % 2 == 0:
        return temp2
    return temp1
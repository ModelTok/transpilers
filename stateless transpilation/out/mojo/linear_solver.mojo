# EXTERNAL DEPS (to wire in glue):
# from fenestration_common import SquareMatrix

from math import fmod, floor

struct CLinearSolver:
    @staticmethod
    def solve_system(matrix_a: SquareMatrix, vector_b: List[float]) -> List[float]:
        if matrix_a.size() != len(vector_b):
            raise RuntimeError("Matrix and vector for system of linear equations are not same size.")

        index = matrix_a.make_upper_triangular()

        size = matrix_a.size()
        ii = -1
        for i in range(size):
            ll = index[i]
            sum_val = vector_b[ll]
            vector_b[ll] = vector_b[i]
            if ii != -1:
                for j in range(ii, i):
                    sum_val -= matrix_a(i, j) * vector_b[j]
            else:
                if sum_val != 0.0:
                    ii = i
            vector_b[i] = sum_val

        for i in range(size - 1, -1, -1):
            sum_val = vector_b[i]
            for j in range(i + 1, size):
                sum_val -= matrix_a(i, j) * vector_b[j]
            vector_b[i] = sum_val / matrix_a(i, i)

        return vector_b

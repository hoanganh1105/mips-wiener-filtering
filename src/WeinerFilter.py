import numpy as np
class Filter:
    def __init__(self, input_file: str, desired_file: str, M_: int):
        self.input_file = input_file
        self.desired_file = desired_file
        self.M = M_

    def readfile(self, filepath):
        with open(filepath, "r") as f:
            content = f.read()
        b = content.split()
        a = [int(x) for x in b]
        return a
    # return a list of autocorrelation
    def autoCorrelation(self, x: list):
        N = len(x)
        res = []
        for k in range(self.M):
            s = 0.0
            for i in range(N - k):
                s += x[i] * x[i+k]
            res.append(s / N)
        return res
    # return a list of crossCorrelation
    def crossCorrelation(self, x: list, d: list):
        N = len(x)
        res = []
        for k in range(self.M):
            s = 0.0
            for i in range(N - k):
                s += d[i] * x[i+k]
            res.append(s / N)
        return res

    # build R matrix
    def build_Rh_matrix(self, x: list):
        a = self.autoCorrelation(x)
        matrix = np.zeros((self.M, self.M))
        for i in range(self.M):
            for j in range(self.M):
                matrix[i][j] = a[abs(i-j)]
        return matrix

    # build gamma vector
    def build_gamma_vector(self, x: list, d: list):
        g = self.crossCorrelation(x, d)
        gamma = np.array(g).reshape(-1,1)  # vector cột
        return gamma

    # solve for h_opt
    def solve_hopf(self, matrix, gamma):
        try:
            h_opt = np.linalg.solve(matrix, gamma)
            return h_opt
        except np.linalg.LinAlgError:
            print("Matrix not invertible!")
            return None

    def apply_filter(self, h_opt, x):
        N = len(x)
        output = np.zeros(N)
        for n in range(N):
            for i in range(self.M):
                if n >= i:
                    output[n] += h_opt[i] * x[n - i]
        return output
    







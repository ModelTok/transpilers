from typing import *
from energyplus import *

class CScatteringSurface(CBase):
    def __init__(self, T_dir_dir: Float64, R_dir_dir: Float64, T_dir_dif: Float64, R_dir_dif: Float64, T_dif_dif: Float64, R_dif_dif: Float64):
        self.T_dir_dir = T_dir_dir
        self.R_dir_dir = R_dir_dir
        self.T_dir_dif = T_dir_dif
        self.R_dir_dif = R_dir_dif
        self.T_dif_dif = T_dif_dif
        self.R_dif_dif = R_dif_dif

    def getAbsorptance(self, which: Int) -> Float64:
        if which == 0:
            return self.T_dir_dir
        if which == 1:
            return self.R_dir_dir
        if which == 2:
            return self.T_dir_dif
        if which == 3:
            return self.R_dir_dif
        return self.T_dif_dif

@export
def ScatteringSurface1(self: CScatteringSurface) -> None:
    A_dir: Float64 = self.getAbsorptance(0)
    A_dif: Float64 = self.getAbsorptance(1)
    print(A_dir, A_dif)

@export
def ScatteringSurface2(self: CScatteringSurface) -> None:
    pass

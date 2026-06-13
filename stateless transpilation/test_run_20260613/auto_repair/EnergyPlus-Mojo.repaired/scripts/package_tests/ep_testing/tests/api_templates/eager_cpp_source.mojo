from EnergyPlus.api.state import EnergyPlusState, Glycol, Real64, stateNew
from EnergyPlus.api.func import initializeFunctionalAPI, glycolNew, glycolSpecificHeat, glycolDelete

def main():
    var state: EnergyPlusState = stateNew()
    initializeFunctionalAPI(state)
    var glycol: Glycol = None
    glycol = glycolNew(state, "WatEr")
    for temp in range(5, 35, 10):
        var thisTemp: Real64 = Float64(temp)
        var specificHeat: Real64 = glycolSpecificHeat(state, glycol, thisTemp)
        print("Cp = {:8.3f}".format(specificHeat))
    glycolDelete(state, glycol)
    print("Hello, world!")
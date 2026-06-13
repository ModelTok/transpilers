// EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
// The Regents of the University of California, through Lawrence Berkeley National Laboratory
// (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
// National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
// contributors. All rights reserved.
//
// NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
// U.S. Government consequently retains certain rights. As such, the U.S. Government has been
// granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
// worldwide license in the Software to reproduce, distribute copies to the public, prepare
// derivative works, and perform publicly and display publicly, and to permit others to do so.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted
// provided that the following conditions are met:
//
// (1) Redistributions of source code must retain the above copyright notice, this list of
//     conditions and the following disclaimer.
//
// (2) Redistributions in binary form must reproduce the above copyright notice, this list of
//     conditions and the following disclaimer in the documentation and/or other materials
//     provided with the distribution.
//
// (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
//     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
//     used to endorse or promote products derived from this software without specific prior
//     written permission.
//
// (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
//     without changes from the version obtained under this License, or (ii) Licensee makes a
//     reference solely to the software portion of its product, Licensee must refer to the
//     software as "EnergyPlus version X" software, where "X" is the version number Licensee
//     obtained under this License and may not use a different name for the software. Except as
//     specifically required in this Section (4), Licensee shall not use in a company name, a
//     product name, in advertising, publicity, or other promotional activities any name, trade
//     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
//     similar designation, without the U.S. Department of Energy's prior written consent.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

// C++ Headers
// #include <format> // Not needed in Mojo

// EnergyPlus Headers
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from BoreholeArray import GLHEVertArray
from ResponseFactors import GLHEResponseFactors
from .State import State
from UtilityRoutines import ShowFatalError, ShowSevereError, makeUPPER
from Properties import GLHEVertProps
from BoreholeSingle import GLHEVertSingle, MyCartesian

def GLHEResponseFactors.__init__(inout self, state: EnergyPlusData, objName: String, j: JSON)
    for existingObj in state.dataGroundHeatExchanger.vertPropsVector:
        if objName == existingObj.name:
            ShowFatalError(state, "Invalid input for {} object: Duplicate name found: {}".format(moduleName, existingObj.name))
    self.name = objName
    self.props = GLHEVertProps.GetVertProps(
        state,
        makeUPPER(
            j["ghe_vertical_properties_object_name"].get[String]()))
    self.numBoreholes = j["number_of_boreholes"].get[Int]()
    self.gRefRatio = j["g_function_reference_ratio"].get[Float64]()
    self.maxSimYears = state.dataEnvrn.MaxNumberSimYears
    let vars = j.at("g_functions")
    for var in vars:
        self.LNTTS.append(var.at("g_function_ln_t_ts_value").get[Float64]())
        self.GFNC.append(var.at("g_function_g_value").get[Float64]())
    self.numGFuncPairs = len(self.LNTTS)

def GetResponseFactor(state: EnergyPlusData, objectName: String) -> GLHEResponseFactors
    let thisObj = state.dataGroundHeatExchanger.responseFactorsVector.find_if(
        fn(myObj: GLHEResponseFactors) -> Bool:
            return myObj.name == objectName
    )
    if thisObj != state.dataGroundHeatExchanger.responseFactorsVector.end():
        return *thisObj
    ShowSevereError(state, "Object=GroundHeatExchanger:ResponseFactors, Name={} - not found.".format(objectName))
    ShowFatalError(state, "Preceding errors cause program termination")

def BuildAndGetResponseFactorObjectFromArray(state: EnergyPlusData, arrayObjectPtr: GLHEVertArray) -> GLHEResponseFactors
    let thisRF = GLHEResponseFactors()
    thisRF.name = arrayObjectPtr.name
    thisRF.props = arrayObjectPtr.props
    var xLoc: Float64 = 0
    var bhCounter: Int = 0
    for xBH in range(1, arrayObjectPtr.numBHinXDirection + 1):
        var yLoc: Float64 = 0
        for yBH in range(1, arrayObjectPtr.numBHinYDirection + 1):
            bhCounter += 1
            let thisBH = GLHEVertSingle()
            thisBH.name = "{} BH {} loc: ({}, {})".format(thisRF.name, bhCounter, xLoc, yLoc)
            thisBH.props = GLHEVertProps.GetVertProps(state, arrayObjectPtr.props.name)
            thisBH.xLoc = xLoc
            thisBH.yLoc = yLoc
            thisRF.myBorholes.append(thisBH)
            state.dataGroundHeatExchanger.singleBoreholesVector.append(thisBH)
            yLoc += arrayObjectPtr.bhSpacing
            thisRF.numBoreholes += 1
        xLoc += arrayObjectPtr.bhSpacing
    thisRF.SetupBHPointsForResponseFactorsObject()
    state.dataGroundHeatExchanger.responseFactorsVector.append(thisRF)
    return thisRF

def BuildAndGetResponseFactorsObjectFromSingleBHs(state: EnergyPlusData, singleBHsForRFVect: List[GLHEVertSingle]) -> GLHEResponseFactors
    let thisRF = GLHEResponseFactors()
    thisRF.name = "Response Factor Object Auto Generated No: {}".format(state.dataGroundHeatExchanger.numAutoGeneratedResponseFactors + 1)

    // Make new props object which has the mean values of the other props objects referenced by the individual BH objects
    let thisProps = GLHEVertProps()
    thisProps.name = "Response Factor Auto Generated Mean Props No: {}".format(state.dataGroundHeatExchanger.numAutoGeneratedResponseFactors + 1)
    for thisBH in singleBHsForRFVect:
        thisProps.bhDiameter += thisBH.props.bhDiameter
        thisProps.bhLength += thisBH.props.bhLength
        thisProps.bhTopDepth += thisBH.props.bhTopDepth
        thisProps.bhUTubeDist += thisBH.props.bhUTubeDist
        thisProps.grout.cp += thisBH.props.grout.cp
        thisProps.grout.diffusivity += thisBH.props.grout.diffusivity
        thisProps.grout.k += thisBH.props.grout.k
        thisProps.grout.rho += thisBH.props.grout.rho
        thisProps.grout.rhoCp += thisBH.props.grout.rhoCp
        thisProps.pipe.cp += thisBH.props.pipe.cp
        thisProps.pipe.diffusivity += thisBH.props.pipe.diffusivity
        thisProps.pipe.k += thisBH.props.pipe.k
        thisProps.pipe.rho += thisBH.props.pipe.rho
        thisProps.pipe.rhoCp += thisBH.props.pipe.rhoCp
        thisProps.pipe.outDia += thisBH.props.pipe.outDia
        thisProps.pipe.thickness += thisBH.props.pipe.thickness
        thisProps.pipe.innerDia += (thisBH.props.pipe.outDia - 2 * thisBH.props.pipe.thickness)
        thisRF.myBorholes.append(thisBH)
    let numBH = len(singleBHsForRFVect)
    thisProps.bhDiameter /= numBH
    thisProps.bhLength /= numBH
    thisProps.bhTopDepth /= numBH
    thisProps.bhUTubeDist /= numBH
    thisProps.grout.cp /= numBH
    thisProps.grout.diffusivity /= numBH
    thisProps.grout.k /= numBH
    thisProps.grout.rho /= numBH
    thisProps.grout.rhoCp /= numBH
    thisProps.pipe.cp /= numBH
    thisProps.pipe.diffusivity /= numBH
    thisProps.pipe.k /= numBH
    thisProps.pipe.rho /= numBH
    thisProps.pipe.rhoCp /= numBH
    thisProps.pipe.outDia /= numBH
    thisProps.pipe.thickness /= numBH
    thisProps.pipe.innerDia /= numBH
    thisRF.props = thisProps
    thisRF.numBoreholes = len(thisRF.myBorholes)
    state.dataGroundHeatExchanger.vertPropsVector.append(thisProps)
    thisRF.SetupBHPointsForResponseFactorsObject()
    state.dataGroundHeatExchanger.responseFactorsVector.append(thisRF)
    state.dataGroundHeatExchanger.numAutoGeneratedResponseFactors += 1
    return thisRF

def GLHEResponseFactors.SetupBHPointsForResponseFactorsObject(self)
    for thisBH in self.myBorholes:
        let numPanels_i: Int = 50
        let numPanels_ii: Int = 50
        let numPanels_j: Int = 560
        thisBH.dl_i = thisBH.props.bhLength / numPanels_i
        for i in range(0, numPanels_i + 1):
            let newPoint = MyCartesian()
            newPoint.x = thisBH.xLoc
            newPoint.y = thisBH.yLoc
            newPoint.z = thisBH.props.bhTopDepth + (i * thisBH.dl_i)
            thisBH.pointLocations_i.append(newPoint)
        thisBH.dl_ii = thisBH.props.bhLength / numPanels_ii
        for i in range(0, numPanels_ii + 1):
            let newPoint = MyCartesian()
            newPoint.x = thisBH.xLoc + (thisBH.props.bhDiameter / 2.0) / sqrt(2.0)
            newPoint.y = thisBH.yLoc + (thisBH.props.bhDiameter / 2.0) / (-sqrt(2.0))
            newPoint.z = thisBH.props.bhTopDepth + (i * thisBH.dl_ii)
            thisBH.pointLocations_ii.append(newPoint)
        thisBH.dl_j = thisBH.props.bhLength / numPanels_j
        for i in range(0, numPanels_j + 1):
            let newPoint = MyCartesian()
            newPoint.x = thisBH.xLoc
            newPoint.y = thisBH.yLoc
            newPoint.z = thisBH.props.bhTopDepth + (i * thisBH.dl_j)
            thisBH.pointLocations_j.append(newPoint)
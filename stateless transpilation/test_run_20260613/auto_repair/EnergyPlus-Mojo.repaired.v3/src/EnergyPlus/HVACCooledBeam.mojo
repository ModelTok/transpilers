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
from math import pow, sqrt, abs

// ObjexxFCL Headers
from ObjexxFCL.Array.functions import *
from ObjexxFCL.Fmath import *

// EnergyPlus Headers
from .Autosizing.Base import *
from BranchNodeConnections import *
from .Data.EnergyPlusData import *
from .DataContaminantBalance import *
from .DataDefineEquip import *
from DataEnvironment import *
from DataHVACGlobals import *
from .DataLoopNode import *
from DataSizing import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from FluidProperties import *
from General import *
from GeneralRoutines import *
from HVACCooledBeam import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from OutputReportPredefined import *
from .Plant.DataPlant import *
from PlantUtilities import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from WaterCoils import *

namespace EnergyPlus:

    namespace HVACCooledBeam:

        // Module containing routines dealing with cooled beam units

        // MODULE INFORMATION:
        //       AUTHOR         Fred Buhl
        //       DATE WRITTEN   February 2, 2008
        //       MODIFIED       na
        //       RE-ENGINEERED  na

        // PURPOSE OF THIS MODULE:
        // To encapsulate the data and algorithms needed to simulate cooled beam units

        // METHODOLOGY EMPLOYED:
        // Cooled beam units are treated as terminal units. There is a fixed amount of supply air delivered
        // either directly through a diffuser or through the cooled beam units. Thermodynamically the
        // situation is similar to 4 pipe induction terminal units. The detailed methodology follows the
        // method in DOE-2.1E.

        // Using/Aliasing
        using HVAC.SmallAirVolFlow
        using HVAC.SmallLoad
        using HVAC.SmallMassFlow
        using HVAC.SmallWaterVolFlow
        using Psychrometrics.PsyCpAirFnW
        using Psychrometrics.PsyHFnTdbW
        using Psychrometrics.PsyRhoAirFnPbTdbW

        def SimCoolBeam(state: EnergyPlusData,
                       CompName: StringLiteral,     // name of the cooled beam unit
                       FirstHVACIteration: Bool, // TRUE if first HVAC iteration in time step
                       ZoneNum: Int,             // index of zone served by the unit
                       ZoneNodeNum: Int,         // zone node number of zone served by the unit
                       CompIndex: Int,                // which cooled beam unit in data structure
                       NonAirSysOutput: Float64        // convective cooling by the beam system [W]
        ):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   Feb 3, 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // Manages the simulation of a cooled beam unit.
            // Called from SimZoneAirLoopEquipment in module ZoneAirLoopEquipmentManager.

            // SUBROUTINE LOCAL VARIABLE DECLARATIONS:
            var CBNum: Int // index of cooled beam unit being simulated

            // First time SimIndUnit is called, get the input for all the cooled beam units
            if state.dataHVACCooledBeam.GetInputFlag:
                GetCoolBeams(state)
                state.dataHVACCooledBeam.GetInputFlag = False

            // Get the  unit index
            if CompIndex == 0:
                CBNum = Util.FindItemInList(CompName, state.dataHVACCooledBeam.CoolBeam)
                if CBNum == 0:
                    ShowFatalError(state, "SimCoolBeam: Cool Beam Unit not found=" + CompName)
                CompIndex = CBNum
            else:
                CBNum = CompIndex
                if CBNum > state.dataHVACCooledBeam.NumCB or CBNum < 1:
                    ShowFatalError(state,
                                   "SimCoolBeam: Invalid CompIndex passed=" + CompIndex + ", Number of Cool Beam Units=" + state.dataHVACCooledBeam.NumCB + ", System name=" + CompName)
                if state.dataHVACCooledBeam.CheckEquipName[CBNum]:
                    if CompName != state.dataHVACCooledBeam.CoolBeam[CBNum].Name:
                        ShowFatalError(
                            state,
                            "SimCoolBeam: Invalid CompIndex passed=" + CompIndex + ", Cool Beam Unit name=" + CompName + ", stored Cool Beam Unit for that index=" + state.dataHVACCooledBeam.CoolBeam[CBNum].Name)
                    state.dataHVACCooledBeam.CheckEquipName[CBNum] = False
            if CBNum == 0:
                ShowFatalError(state, "Cool Beam Unit not found = " + CompName)

            state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[state.dataHVACCooledBeam.CoolBeam[CBNum].ADUNum].TermUnitSizingNum
            // initialize the unit
            InitCoolBeam(state, CBNum, FirstHVACIteration)

            ControlCoolBeam(state, CBNum, ZoneNum, ZoneNodeNum, FirstHVACIteration, NonAirSysOutput)

            // Update the current unit's outlet nodes. No update needed
            UpdateCoolBeam(state, CBNum)

            // Fill the report variables. There are no report variables
            ReportCoolBeam(state, CBNum)

        def GetCoolBeams(state: EnergyPlusData):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   Feb 3, 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // Obtains input data for cool beam units and stores it in the
            // cool beam unit data structures

            // METHODOLOGY EMPLOYED:
            // Uses "Get" routines to read in data.

            // Using/Aliasing
            using Node.GetOnlySingleNode
            using Node.TestCompSet
            using DataSizing.*
            using WaterCoils.GetCoilWaterInletNode

            // SUBROUTINE PARAMETER DEFINITIONS:
            var RoutineName: StringLiteral = "GetCoolBeams " // include trailing blank space
            var routineName: StringLiteral = "GetCoolBeams"

            var CBIndex: Int                     // loop index
            var CurrentModuleObject: String // for ease in getting objects
            var Alphas: Array1D_string           // Alpha input items for object
            var cAlphaFields: Array1D_string     // Alpha field names
            var cNumericFields: Array1D_string   // Numeric field names
            var Numbers: Array1D_Float64         // Numeric input items for object
            var lAlphaBlanks: Array1D_bool       // Logical array, alpha field input BLANK = .TRUE.
            var lNumericBlanks: Array1D_bool     // Logical array, numeric field input BLANK = .TRUE.
            var NumAlphas: Int = 0                // Number of Alphas for each GetObjectItem call
            var NumNumbers: Int = 0               // Number of Numbers for each GetObjectItem call
            var TotalArgs: Int = 0                // Total number of alpha and numeric arguments (max) for a
            //  certain object in the input file
            var IOStatus: Int            // Used in GetObjectItem
            var ErrorsFound: Bool = False // Set to true if errors in input, fatal at end of routine
            var CtrlZone: Int            // controlled zome do loop index
            var SupAirIn: Int            // controlled zone supply air inlet index
            var AirNodeFound: Bool
            var ADUNum: Int

            var CoolBeam = state.dataHVACCooledBeam.CoolBeam
            var CheckEquipName = state.dataHVACCooledBeam.CheckEquipName

            // find the number of cooled beam units
            CurrentModuleObject = "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
            // Update Num in state and make local convenience copy
            var NumCB: Int = state.dataHVACCooledBeam.NumCB = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
            // allocate the data structures
            CoolBeam.allocate(NumCB)
            CheckEquipName.dimension(NumCB, True)

            state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, TotalArgs, NumAlphas, NumNumbers)
            NumAlphas = 7
            NumNumbers = 16
            TotalArgs = 23

            Alphas.allocate(NumAlphas)
            cAlphaFields.allocate(NumAlphas)
            cNumericFields.allocate(NumNumbers)
            Numbers.dimension(NumNumbers, 0.0)
            lAlphaBlanks.dimension(NumAlphas, True)
            lNumericBlanks.dimension(NumNumbers, True)

            // loop over cooled beam units; get and load the input data
            for CBIndex in range(1, NumCB + 1):

                state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                         CurrentModuleObject,
                                                                         CBIndex,
                                                                         Alphas,
                                                                         NumAlphas,
                                                                         Numbers,
                                                                         NumNumbers,
                                                                         IOStatus,
                                                                         lNumericBlanks,
                                                                         lAlphaBlanks,
                                                                         cAlphaFields,
                                                                         cNumericFields)

                var eoh: ErrorObjectHeader = ErrorObjectHeader{routineName, CurrentModuleObject, Alphas[1]}
                var CBNum: Int = CBIndex

                CoolBeam[CBNum].Name = Alphas[1]
                CoolBeam[CBNum].UnitType = CurrentModuleObject
                CoolBeam[CBNum].UnitType_Num = 1
                CoolBeam[CBNum].CBTypeString = Alphas[3]
                if Util.SameString(CoolBeam[CBNum].CBTypeString, "Passive"):
                    CoolBeam[CBNum].CBType = CooledBeamType.Passive
                elif Util.SameString(CoolBeam[CBNum].CBTypeString, "Active"):
                    CoolBeam[CBNum].CBType = CooledBeamType.Active
                else:
                    ShowSevereError(state, "Illegal " + cAlphaFields[3] + " = " + CoolBeam[CBNum].CBTypeString + ".")
                    ShowContinueError(state, "Occurs in " + CurrentModuleObject + " = " + CoolBeam[CBNum].Name)
                    ErrorsFound = True

                if lAlphaBlanks[2]:
                    CoolBeam[CBNum].availSched = Sched.GetScheduleAlwaysOn(state)
                elif (CoolBeam[CBNum].availSched = Sched.GetSchedule(state, Alphas[2])) == None: // convert schedule name to pointer
                    ShowSevereItemNotFound(state, eoh, cAlphaFields[2], Alphas[2])
                    ErrorsFound = True
                CoolBeam[CBNum].AirInNode = GetOnlySingleNode(state,
                                                              Alphas[4],
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeCooledBeam,
                                                              Alphas[1],
                                                              Node.FluidType.Air,
                                                              Node.ConnectionType.Inlet,
                                                              Node.CompFluidStream.Primary,
                                                              Node.ObjectIsNotParent,
                                                              cAlphaFields[4])
                CoolBeam[CBNum].AirOutNode = GetOnlySingleNode(state,
                                                               Alphas[5],
                                                               ErrorsFound,
                                                               Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeCooledBeam,
                                                               Alphas[1],
                                                               Node.FluidType.Air,
                                                               Node.ConnectionType.Outlet,
                                                               Node.CompFluidStream.Primary,
                                                               Node.ObjectIsNotParent,
                                                               cAlphaFields[5])
                CoolBeam[CBNum].CWInNode = GetOnlySingleNode(state,
                                                             Alphas[6],
                                                             ErrorsFound,
                                                             Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeCooledBeam,
                                                             Alphas[1],
                                                             Node.FluidType.Water,
                                                             Node.ConnectionType.Inlet,
                                                             Node.CompFluidStream.Secondary,
                                                             Node.ObjectIsNotParent,
                                                             cAlphaFields[6])
                CoolBeam[CBNum].CWOutNode = GetOnlySingleNode(state,
                                                              Alphas[7],
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeCooledBeam,
                                                              Alphas[1],
                                                              Node.FluidType.Water,
                                                              Node.ConnectionType.Outlet,
                                                              Node.CompFluidStream.Secondary,
                                                              Node.ObjectIsNotParent,
                                                              cAlphaFields[7])
                CoolBeam[CBNum].MaxAirVolFlow = Numbers[1]
                CoolBeam[CBNum].MaxCoolWaterVolFlow = Numbers[2]
                CoolBeam[CBNum].NumBeams = Numbers[3]
                CoolBeam[CBNum].BeamLength = Numbers[4]
                CoolBeam[CBNum].DesInletWaterTemp = Numbers[5]
                CoolBeam[CBNum].DesOutletWaterTemp = Numbers[6]
                CoolBeam[CBNum].CoilArea = Numbers[7]
                CoolBeam[CBNum].a = Numbers[8]
                CoolBeam[CBNum].n1 = Numbers[9]
                CoolBeam[CBNum].n2 = Numbers[10]
                CoolBeam[CBNum].n3 = Numbers[11]
                CoolBeam[CBNum].a0 = Numbers[12]
                CoolBeam[CBNum].K1 = Numbers[13]
                CoolBeam[CBNum].n = Numbers[14]
                CoolBeam[CBNum].Kin = Numbers[15]
                CoolBeam[CBNum].InDiam = Numbers[16]

                // Register component set data
                TestCompSet(state,
                            CurrentModuleObject,
                            CoolBeam[CBNum].Name,
                            state.dataLoopNodes.NodeID[CoolBeam[CBNum].AirInNode],
                            state.dataLoopNodes.NodeID[CoolBeam[CBNum].AirOutNode],
                            "Air Nodes")
                TestCompSet(state,
                            CurrentModuleObject,
                            CoolBeam[CBNum].Name,
                            state.dataLoopNodes.NodeID[CoolBeam[CBNum].CWInNode],
                            state.dataLoopNodes.NodeID[CoolBeam[CBNum].CWOutNode],
                            "Water Nodes")

                // Setup the Cooled Beam reporting variables
                // CurrentModuleObject = "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
                SetupOutputVariable(state,
                                    "Zone Air Terminal Beam Sensible Cooling Energy",
                                    Constant.Units.J,
                                    CoolBeam[CBNum].BeamCoolingEnergy,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Sum,
                                    CoolBeam[CBNum].Name,
                                    Constant.eResource.EnergyTransfer,
                                    OutputProcessor.Group.HVAC,
                                    OutputProcessor.EndUseCat.CoolingCoils)
                SetupOutputVariable(state,
                                    "Zone Air Terminal Beam Chilled Water Energy",
                                    Constant.Units.J,
                                    CoolBeam[CBNum].BeamCoolingEnergy,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Sum,
                                    CoolBeam[CBNum].Name,
                                    Constant.eResource.PlantLoopCoolingDemand,
                                    OutputProcessor.Group.HVAC,
                                    OutputProcessor.EndUseCat.CoolingCoils)
                SetupOutputVariable(state,
                                    "Zone Air Terminal Beam Sensible Cooling Rate",
                                    Constant.Units.W,
                                    CoolBeam[CBNum].BeamCoolingRate,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Average,
                                    CoolBeam[CBNum].Name)
                SetupOutputVariable(state,
                                    "Zone Air Terminal Supply Air Sensible Cooling Energy",
                                    Constant.Units.J,
                                    CoolBeam[CBNum].SupAirCoolingEnergy,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Sum,
                                    CoolBeam[CBNum].Name)
                SetupOutputVariable(state,
                                    "Zone Air Terminal Supply Air Sensible Cooling Rate",
                                    Constant.Units.W,
                                    CoolBeam[CBNum].SupAirCoolingRate,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Average,
                                    CoolBeam[CBNum].Name)
                SetupOutputVariable(state,
                                    "Zone Air Terminal Supply Air Sensible Heating Energy",
                                    Constant.Units.J,
                                    CoolBeam[CBNum].SupAirHeatingEnergy,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Sum,
                                    CoolBeam[CBNum].Name)
                SetupOutputVariable(state,
                                    "Zone Air Terminal Supply Air Sensible Heating Rate",
                                    Constant.Units.W,
                                    CoolBeam[CBNum].SupAirHeatingRate,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Average,
                                    CoolBeam[CBNum].Name)

                SetupOutputVariable(state,
                                    "Zone Air Terminal Outdoor Air Volume Flow Rate",
                                    Constant.Units.m3_s,
                                    CoolBeam[CBNum].OutdoorAirFlowRate,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Average,
                                    CoolBeam[CBNum].Name)

                for ADUNum in range(1, state.dataDefineEquipment.AirDistUnit.size() + 1):
                    if CoolBeam[CBNum].AirOutNode == state.dataDefineEquipment.AirDistUnit[ADUNum].OutletNodeNum:
                        CoolBeam[CBNum].ADUNum = ADUNum
                        state.dataDefineEquipment.AirDistUnit[ADUNum].InletNodeNum = CoolBeam[CBNum].AirInNode
                // one assumes if there isn't one assigned, it's an error?
                if CoolBeam[CBNum].ADUNum == 0:
                    ShowSevereError(
                        state,
                        RoutineName + "No matching Air Distribution Unit, for Unit = [" + CurrentModuleObject + "," + CoolBeam[CBNum].Name + "].")
                    ShowContinueError(state, "...should have outlet node=" + state.dataLoopNodes.NodeID[CoolBeam[CBNum].AirOutNode])
                    ErrorsFound = True
                else:

                    // Fill the Zone Equipment data with the supply air inlet node number of this unit.
                    AirNodeFound = False
                    for CtrlZone in range(1, state.dataGlobal.NumOfZones + 1):
                        if not state.dataZoneEquip.ZoneEquipConfig[CtrlZone].IsControlled:
                            continue
                        for SupAirIn in range(1, state.dataZoneEquip.ZoneEquipConfig[CtrlZone].NumInletNodes + 1):
                            if CoolBeam[CBNum].AirOutNode == state.dataZoneEquip.ZoneEquipConfig[CtrlZone].InletNode[SupAirIn]:
                                state.dataZoneEquip.ZoneEquipConfig[CtrlZone].AirDistUnitCool[SupAirIn].InNode = CoolBeam[CBNum].AirInNode
                                state.dataZoneEquip.ZoneEquipConfig[CtrlZone].AirDistUnitCool[SupAirIn].OutNode = CoolBeam[CBNum].AirOutNode
                                state.dataDefineEquipment.AirDistUnit[CoolBeam[CBNum].ADUNum].TermUnitSizingNum = state.dataZoneEquip.ZoneEquipConfig[CtrlZone].AirDistUnitCool[SupAirIn].TermUnitSizingIndex
                                state.dataDefineEquipment.AirDistUnit[CoolBeam[CBNum].ADUNum].ZoneEqNum = CtrlZone
                                CoolBeam[CBNum].CtrlZoneNum = CtrlZone
                                CoolBeam[CBNum].ctrlZoneInNodeIndex = SupAirIn
                                AirNodeFound = True
                                break
                if not AirNodeFound:
                    ShowSevereError(state, "The outlet air node from the " + CurrentModuleObject + " = " + CoolBeam[CBNum].Name)
                    ShowContinueError(state, "did not have a matching Zone Equipment Inlet Node, Node =" + Alphas[5])
                    ErrorsFound = True

            Alphas.deallocate()
            cAlphaFields.deallocate()
            cNumericFields.deallocate()
            Numbers.deallocate()
            lAlphaBlanks.deallocate()
            lNumericBlanks.deallocate()

            if ErrorsFound:
                ShowFatalError(state, RoutineName + "Errors found in getting input. Preceding conditions cause termination.")

        def InitCoolBeam(state: EnergyPlusData,
                        CBNum: Int,              // number of the current cooled beam unit being simulated
                        FirstHVACIteration: Bool // TRUE if first air loop solution this HVAC step
        ):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   February 6, 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // This subroutine is for initialization of the cooled beam units

            // METHODOLOGY EMPLOYED:
            // Uses the status flags to trigger initializations.

            // Using/Aliasing
            using DataZoneEquipment.CheckZoneEquipmentList
            using PlantUtilities.InitComponentNodes
            using PlantUtilities.ScanPlantLoopsForObject
            using PlantUtilities.SetComponentFlowRate

            // SUBROUTINE PARAMETER DEFINITIONS:
            var RoutineName: StringLiteral = "InitCoolBeam"

            // SUBROUTINE LOCAL VARIABLE DECLARATIONS:
            var InAirNode: Int    // supply air inlet node number
            var OutAirNode: Int   // unit air outlet node
            var InWaterNode: Int  // unit inlet chilled water node
            var OutWaterNode: Int // unit outlet chilled water node
            var RhoAir: Float64    // air density at outside pressure and standard temperature and humidity
            var rho: Float64       // local fluid density

            var coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum]
            var ZoneEquipmentListChecked = state.dataHVACCooledBeam.ZoneEquipmentListChecked
            var NumCB: Int = state.dataHVACCooledBeam.NumCB

            if coolBeam.PlantLoopScanFlag and allocated(state.dataPlnt.PlantLoop):
                var errFlag: Bool = False
                ScanPlantLoopsForObject(
                    state, coolBeam.Name, DataPlant.PlantEquipmentType.CooledBeamAirTerminal, coolBeam.CWPlantLoc, errFlag, _, _, _, _, _)
                if errFlag:
                    ShowFatalError(state, "InitCoolBeam: Program terminated for previous conditions.")
                coolBeam.PlantLoopScanFlag = False

            if not ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
                var CurrentModuleObject: String = "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
                ZoneEquipmentListChecked = True
                // Check to see if there is a Air Distribution Unit on the Zone Equipment List
                for Loop in range(1, NumCB + 1):
                    if coolBeam.ADUNum == 0:
                        continue
                    if CheckZoneEquipmentList(state, "ZONEHVAC:AIRDISTRIBUTIONUNIT", state.dataDefineEquipment.AirDistUnit[coolBeam.ADUNum].Name):
                        continue
                    ShowSevereError(state,
                                    "InitCoolBeam: ADU=[Air Distribution Unit," + state.dataDefineEquipment.AirDistUnit[coolBeam.ADUNum].Name + "] is not on any ZoneHVAC:EquipmentList.")
                    ShowContinueError(state, "...Unit=[" + CurrentModuleObject + "," + coolBeam.Name + "] will not be simulated.")

            if not state.dataGlobal.SysSizingCalc and coolBeam.MySizeFlag and not coolBeam.PlantLoopScanFlag:

                SizeCoolBeam(state, CBNum)

                InWaterNode = coolBeam.CWInNode
                OutWaterNode = coolBeam.CWOutNode
                rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                coolBeam.MaxCoolWaterMassFlow = rho * coolBeam.MaxCoolWaterVolFlow
                InitComponentNodes(state, 0.0, coolBeam.MaxCoolWaterMassFlow, InWaterNode, OutWaterNode)
                coolBeam.MySizeFlag = False

            // Do the Begin Environment initializations
            if state.dataGlobal.BeginEnvrnFlag and coolBeam.MyEnvrnFlag:
                RhoAir = state.dataEnvrn.StdRhoAir
                InAirNode = coolBeam.AirInNode
                OutAirNode = coolBeam.AirOutNode
                // set the mass flow rates from the input volume flow rates
                coolBeam.MaxAirMassFlow = RhoAir * coolBeam.MaxAirVolFlow
                state.dataLoopNodes.Node[InAirNode].MassFlowRateMax = coolBeam.MaxAirMassFlow
                state.dataLoopNodes.Node[OutAirNode].MassFlowRateMax = coolBeam.MaxAirMassFlow
                state.dataLoopNodes.Node[InAirNode].MassFlowRateMin = 0.0
                state.dataLoopNodes.Node[OutAirNode].MassFlowRateMin = 0.0

                InWaterNode = coolBeam.CWInNode
                OutWaterNode = coolBeam.CWOutNode
                InitComponentNodes(state, 0.0, coolBeam.MaxCoolWaterMassFlow, InWaterNode, OutWaterNode)

                if coolBeam.AirLoopNum == 0: // fill air loop index
                    if coolBeam.CtrlZoneNum > 0 and coolBeam.ctrlZoneInNodeIndex > 0:
                        coolBeam.AirLoopNum = state.dataZoneEquip.ZoneEquipConfig[coolBeam.CtrlZoneNum].InletNodeAirLoopNum[coolBeam.ctrlZoneInNodeIndex]
                        state.dataDefineEquipment.AirDistUnit[coolBeam.ADUNum].AirLoopNum = coolBeam.AirLoopNum

                coolBeam.MyEnvrnFlag = False
            // end one time inits

            if not state.dataGlobal.BeginEnvrnFlag:
                coolBeam.MyEnvrnFlag = True

            InAirNode = coolBeam.AirInNode
            OutAirNode = coolBeam.AirOutNode

            // Do the start of HVAC time step initializations
            if FirstHVACIteration:
                // check for upstream zero flow. If nonzero and schedule ON, set primary flow to max
                if coolBeam.availSched.getCurrentVal() > 0.0 and state.dataLoopNodes.Node[InAirNode].MassFlowRate > 0.0:
                    state.dataLoopNodes.Node[InAirNode].MassFlowRate = coolBeam.MaxAirMassFlow
                else:
                    state.dataLoopNodes.Node[InAirNode].MassFlowRate = 0.0
                // reset the max and min avail flows
                if coolBeam.availSched.getCurrentVal() > 0.0 and state.dataLoopNodes.Node[InAirNode].MassFlowRateMaxAvail > 0.0:
                    state.dataLoopNodes.Node[InAirNode].MassFlowRateMaxAvail = coolBeam.MaxAirMassFlow
                    state.dataLoopNodes.Node[InAirNode].MassFlowRateMinAvail = coolBeam.MaxAirMassFlow
                else:
                    state.dataLoopNodes.Node[InAirNode].MassFlowRateMaxAvail = 0.0
                    state.dataLoopNodes.Node[InAirNode].MassFlowRateMinAvail = 0.0

            // do these initializations every time step
            InWaterNode = coolBeam.CWInNode
            coolBeam.TWIn = state.dataLoopNodes.Node[InWaterNode].Temp
            coolBeam.SupAirCoolingRate = 0.0
            coolBeam.SupAirHeatingRate = 0.0

        def SizeCoolBeam(state: EnergyPlusData, CBNum: Int):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   February 10, 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // This subroutine is for sizing cooled beam units for which flow rates have not been
            // specified in the input

            // METHODOLOGY EMPLOYED:
            // Accesses zone sizing array for air flow rates and zone and plant sizing arrays to
            // calculate coil water flow rates.

            // Using/Aliasing
            using DataSizing.*
            using PlantUtilities.MyPlantSizingIndex
            using PlantUtilities.RegisterPlantCompDesignFlow

            // SUBROUTINE LOCAL VARIABLE DECLARATIONS:
            var RoutineName: StringLiteral = "SizeCoolBeam"
            var PltSizCoolNum: Int = 0          // index of plant sizing object for the cooling loop
            var NumBeams: Int = 0               // number of beams in the zone
            var DesCoilLoad: Float64 = 0.0       // total cooling capacity of the beams in the zone [W]
            var DesLoadPerBeam: Float64 = 0.0    // cooling capacity per individual beam [W]
            var DesAirVolFlow: Float64 = 0.0     // design total supply air flow rate [m3/s]
            var DesAirFlowPerBeam: Float64 = 0.0 // design supply air volumetric flow per beam [m3/s]
            var RhoAir: Float64 = 0.0
            var CpAir: Float64 = 0.0
            var WaterVel: Float64 = 0.0            // design water velocity in beam
            var IndAirFlowPerBeamL: Float64 = 0.0  // induced volumetric air flow rate per beam length [m3/s-m]
            var DT: Float64 = 0.0                  // air - water delta T [C]
            var LengthX: Float64 = 0.0             // test value for beam length [m]
            var Length: Float64 = 0.0              // beam length [m]
            var ConvFlow: Float64 = 0.0            // convective and induced air mass flow rate across beam per beam plan area [kg/s-m2]
            var K: Float64 = 0.0                   // coil (beam) heat transfer coefficient [W/m2-K]
            var WaterVolFlowPerBeam: Float64 = 0.0 // Cooling water volumetric flow per beam [m3]
            var ErrorsFound: Bool
            var rho: Float64 // local fluid density
            var Cp: Float64  // local fluid specific heat

            PltSizCoolNum = 0
            DesAirVolFlow = 0.0
            CpAir = 0.0
            RhoAir = state.dataEnvrn.StdRhoAir
            ErrorsFound = False

            var coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum]

            // find the appropriate Plant Sizing object
            if coolBeam.MaxAirVolFlow == AutoSize or coolBeam.BeamLength == AutoSize:
                PltSizCoolNum = MyPlantSizingIndex(state, "cooled beam unit", coolBeam.Name, coolBeam.CWInNode, coolBeam.CWOutNode, ErrorsFound)

            if coolBeam.Kin == Constant.AutoCalculate:
                if coolBeam.CBType == CooledBeamType.Passive:
                    coolBeam.Kin = 0.0
                else:
                    coolBeam.Kin = 2.0
                BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Coefficient of Induction Kin", coolBeam.Kin)

            if coolBeam.MaxAirVolFlow == AutoSize:

                if state.dataSize.CurTermUnitSizingNum > 0:

                    CheckZoneSizing(state, coolBeam.UnitType, coolBeam.Name)
                    coolBeam.MaxAirVolFlow = max(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolVolFlow,
                                                 state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatVolFlow)
                    if coolBeam.MaxAirVolFlow < SmallAirVolFlow:
                        coolBeam.MaxAirVolFlow = 0.0
                    BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Supply Air Flow Rate [m3/s]", coolBeam.MaxAirVolFlow)

            if coolBeam.MaxCoolWaterVolFlow == AutoSize:

                if (state.dataSize.CurZoneEqNum > 0) and (state.dataSize.CurTermUnitSizingNum > 0):

                    CheckZoneSizing(state, coolBeam.UnitType, coolBeam.Name)

                    if PltSizCoolNum > 0:

                        if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolMassFlow >= SmallAirVolFlow:
                            DesAirVolFlow = coolBeam.MaxAirVolFlow
                            CpAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].CoolDesHumRat)
                            // the design cooling coil load is the zone load minus whatever the central system does. Note that
                            // DesCoolCoilInTempTU is really the primary air inlet temperature for the unit.
                            if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak > 0.0:
                                DesCoilLoad = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].NonAirSysDesCoolLoad - CpAir * RhoAir * DesAirVolFlow * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU)
                            else:
                                DesCoilLoad = CpAir * RhoAir * DesAirVolFlow * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneSizThermSetPtHi)

                            rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)

                            Cp = coolBeam.CWPlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, RoutineName)

                            coolBeam.MaxCoolWaterVolFlow = DesCoilLoad / ((coolBeam.DesOutletWaterTemp - coolBeam.DesInletWaterTemp) * Cp * rho)
                            coolBeam.MaxCoolWaterVolFlow = max(coolBeam.MaxCoolWaterVolFlow, 0.0)
                            if coolBeam.MaxCoolWaterVolFlow < SmallWaterVolFlow:
                                coolBeam.MaxCoolWaterVolFlow = 0.0
                        else:
                            coolBeam.MaxCoolWaterVolFlow = 0.0

                        BaseSizer.reportSizerOutput(
                            state, coolBeam.UnitType, coolBeam.Name, "Maximum Total Chilled Water Flow Rate [m3/s]", coolBeam.MaxCoolWaterVolFlow)
                    else:
                        ShowSevereError(state, "Autosizing of water flow requires a cooling loop Sizing:Plant object")
                        ShowContinueError(state, "Occurs in" + coolBeam.UnitType + " Object=" + coolBeam.Name)
                        ErrorsFound = True

            BaseSizer.calcCoilWaterFlowRates(state,
                                              coolBeam.Name,
                                              coolBeam.UnitType,
                                              coolBeam.MaxCoolWaterVolFlow,
                                              coolBeam.CWPlantLoc.loopNum,
                                              state.dataSize.CurZoneEqNum,
                                              state.dataSize.CurSysNum,
                                              state.dataSize.CurOASysNum,
                                              state.dataSize.FinalZoneSizing,
                                              state.dataSize.FinalSysSizing)

            if coolBeam.NumBeams == AutoSize:
                rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)

                NumBeams = int(coolBeam.MaxCoolWaterVolFlow * rho / NomMassFlowPerBeam) + 1
                coolBeam.NumBeams = Float64(NumBeams)
                BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Number of Beams", coolBeam.NumBeams)

            if coolBeam.BeamLength == AutoSize:

                if state.dataSize.CurTermUnitSizingNum > 0:

                    CheckZoneSizing(state, coolBeam.UnitType, coolBeam.Name)

                    if PltSizCoolNum > 0:
                        rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, RoutineName)
                        Cp = coolBeam.CWPlantLoc.loop.glycol.getSpecificHeat(state, Constant.CWInitConvTemp, RoutineName)
                        DesCoilLoad = coolBeam.MaxCoolWaterVolFlow * (coolBeam.DesOutletWaterTemp - coolBeam.DesInletWaterTemp) * Cp * rho
                        if DesCoilLoad > 0.0:
                            DesLoadPerBeam = DesCoilLoad / NumBeams
                            DesAirFlowPerBeam = coolBeam.MaxAirVolFlow / NumBeams
                            WaterVolFlowPerBeam = coolBeam.MaxCoolWaterVolFlow / NumBeams
                            WaterVel = WaterVolFlowPerBeam / (Constant.Pi * pow_2(coolBeam.InDiam) / 4.0)
                            if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak > 0.0:
                                DT = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak - 0.5 * (coolBeam.DesInletWaterTemp + coolBeam.DesOutletWaterTemp)
                                if DT <= 0.0:
                                    DT = 7.8
                            else:
                                DT = 7.8
                            LengthX = 1.0
                            for Iter in range(1, 101):
                                IndAirFlowPerBeamL = coolBeam.K1 * pow(DT, coolBeam.n) + coolBeam.Kin * DesAirFlowPerBeam / LengthX
                                ConvFlow = (IndAirFlowPerBeamL / coolBeam.a0) * RhoAir
                                if WaterVel > MinWaterVel:
                                    K = coolBeam.a * pow(DT, coolBeam.n1) * pow(ConvFlow, coolBeam.n2) * pow(WaterVel, coolBeam.n3)
                                else:
                                    K = coolBeam.a * pow(DT, coolBeam.n1) * pow(ConvFlow, coolBeam.n2) * pow(MinWaterVel, coolBeam.n3) * (WaterVel / MinWaterVel)
                                Length = DesLoadPerBeam / (K * coolBeam.CoilArea * DT)
                                if coolBeam.Kin <= 0.0:
                                    break
                                // Check for convergence
                                if abs(Length - LengthX) > 0.01:
                                    // New guess for length
                                    LengthX += 0.5 * (Length - LengthX)
                                else:
                                    break // convergence achieved
                        else:
                            Length = 0.0
                        coolBeam.BeamLength = Length
                        coolBeam.BeamLength = max(coolBeam.BeamLength, 1.0)
                        BaseSizer.reportSizerOutput(state, coolBeam.UnitType, coolBeam.Name, "Beam Length [m]", coolBeam.BeamLength)
                    else:
                        ShowSevereError(state, "Autosizing of cooled beam length requires a cooling loop Sizing:Plant object")
                        ShowContinueError(state, "Occurs in" + coolBeam.UnitType + " Object=" + coolBeam.Name)
                        ErrorsFound = True

            // save the design water volumetric flow rate for use by the water loop sizing algorithms
            if coolBeam.MaxCoolWaterVolFlow > 0.0:
                RegisterPlantCompDesignFlow(state, coolBeam.CWInNode, coolBeam.MaxCoolWaterVolFlow)

            if ErrorsFound:
                ShowFatalError(state, "Preceding cooled beam sizing errors cause program termination")

        def ControlCoolBeam(state: EnergyPlusData,
                           CBNum: Int,                                // number of the current unit being simulated
                           ZoneNum: Int,                              // number of zone being served
                           ZoneNodeNum: Int,                          // zone node number
                           FirstHVACIteration: Bool, // TRUE if 1st HVAC simulation of system timestep
                           NonAirSysOutput: Float64                         // convective cooling by the beam system [W]
        ):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   Feb 12, 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // Simulate a cooled beam unit;

            // METHODOLOGY EMPLOYED:
            // (1) From the zone load and the Supply air inlet conditions calculate the beam load
            // (2) If there is a beam load, vary the water flow rate to match the beam load

            // REFERENCES:
            // na

            // Using/Aliasing
            using DataZoneEnergyDemands.*
            using PlantUtilities.SetComponentFlowRate

            // Locals
            // SUBROUTINE ARGUMENT DEFINITIONS:

            // SUBROUTINE PARAMETER DEFINITIONS:
            // na

            // INTERFACE BLOCK SPECIFICATIONS:
            // na

            // DERIVED TYPE DEFINITIONS:
            // na

            // SUBROUTINE LOCAL VARIABLE DECLARATIONS:
            var QZnReq: Float64                // heating or cooling needed by zone [Watts]
            var QToHeatSetPt: Float64          // [W]  remaining load to heating setpoint
            var QToCoolSetPt: Float64          // [W]  remaining load to cooling setpoint
            var QMin: Float64 = 0.0             // cooled beam output at minimum water flow [W]
            var QMax: Float64 = 0.0             // cooled beam output at maximum water flow [W]
            var QSup: Float64 = 0.0             // heating or cooling by supply air [W]
            var PowerMet: Float64 = 0.0         // power supplied
            var CWFlow: Float64 = 0.0           // cold water flow [kg/s]
            var AirMassFlow: Float64 = 0.0      // air mass flow rate for the cooled beam system [kg/s]
            var MaxColdWaterFlow: Float64 = 0.0 // max water mass flow rate for the cooled beam system [kg/s]
            var MinColdWaterFlow: Float64 = 0.0 // min water mass flow rate for the cooled beam system [kg/s]
            var CpAirZn: Float64 = 0.0          // specific heat of air at zone conditions [J/kg-C]
            var CpAirSys: Float64 = 0.0         // specific heat of air at supply air conditions [J/kg-C]
            var TWOut: Float64 = 0.0            // outlet water tamperature [C]
            var ControlNode: Int              // the water inlet node
            var InAirNode: Int                // the air inlet node
            var UnitOn: Bool                  // TRUE if unit is on
            var ErrTolerance: Float64
            var coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum]

            UnitOn = True
            PowerMet = 0.0
            InAirNode = coolBeam.AirInNode
            ControlNode = coolBeam.CWInNode
            AirMassFlow = state.dataLoopNodes.Node[InAirNode].MassFlowRateMaxAvail
            QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputRequired
            QToHeatSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
            QToCoolSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP
            CpAirZn = PsyCpAirFnW(state.dataLoopNodes.Node[ZoneNodeNum].HumRat)
            CpAirSys = PsyCpAirFnW(state.dataLoopNodes.Node[InAirNode].HumRat)
            MaxColdWaterFlow = coolBeam.MaxCoolWaterMassFlow
            SetComponentFlowRate(state, MaxColdWaterFlow, coolBeam.CWInNode, coolBeam.CWOutNode, coolBeam.CWPlantLoc)
            MinColdWaterFlow = 0.0
            SetComponentFlowRate(state, MinColdWaterFlow, coolBeam.CWInNode, coolBeam.CWOutNode, coolBeam.CWPlantLoc)

            if coolBeam.availSched.getCurrentVal() <= 0.0:
                UnitOn = False
            if MaxColdWaterFlow <= SmallMassFlow:
                UnitOn = False

            // Set the unit's air inlet nodes mass flow rates
            state.dataLoopNodes.Node[InAirNode].MassFlowRate = AirMassFlow
            // set the air volumetric flow rate per beam
            coolBeam.BeamFlow = state.dataLoopNodes.Node[InAirNode].MassFlowRate / (state.dataEnvrn.StdRhoAir * coolBeam.NumBeams)
            // fire the unit at min water flow
            CalcCoolBeam(state, CBNum, ZoneNodeNum, MinColdWaterFlow, QMin, TWOut)
            // cooling by supply air
            QSup = AirMassFlow * (CpAirSys * state.dataLoopNodes.Node[InAirNode].Temp - CpAirZn * state.dataLoopNodes.Node[ZoneNodeNum].Temp)
            // load on the beams is QToCoolSetPt-QSup
            if UnitOn:
                if (QToCoolSetPt - QSup) < -SmallLoad:
                    // There is a cooling demand on the cooled beam system.
                    // First, see if the system can meet the load
                    CalcCoolBeam(state, CBNum, ZoneNodeNum, MaxColdWaterFlow, QMax, TWOut)
                    if (QMax < QToCoolSetPt - QSup - SmallLoad) and (QMax != QMin):
                        // The cooled beam system can meet the demand.
                        // Set up the iterative calculation of chilled water flow rate
                        ErrTolerance = 0.01
                        var f = fn(state: EnergyPlusData, CBNum: Int, ZoneNodeNum: Int, QToCoolSetPt: Float64, QSup: Float64, QMin: Float64, QMax: Float64, CWFlow: Float64) -> Float64:
                            var par3: Float64 = QToCoolSetPt - QSup
                            var UnitOutput: Float64 = 0.0
                            var TWOut: Float64 = 0.0
                            CalcCoolBeam(state, CBNum, ZoneNodeNum, CWFlow, UnitOutput, TWOut)
                            return (par3 - UnitOutput) / (QMax - QMin)
                        var SolFlag: Int = 0
                        General.SolveRoot(state, ErrTolerance, 50, SolFlag, CWFlow, f, MinColdWaterFlow, MaxColdWaterFlow)
                        if SolFlag == -1:
                            ShowWarningError(state, "Cold water control failed in cooled beam unit " + coolBeam.Name)
                            ShowContinueError(state, "  Iteration limit exceeded in calculating cold water mass flow rate")
                        elif SolFlag == -2:
                            ShowWarningError(state, "Cold water control failed in cooled beam unit " + coolBeam.Name)
                            ShowContinueError(state, "  Bad cold water flow limits")
                    else:
                        // unit maxed out
                        CWFlow = MaxColdWaterFlow
                else:
                    // unit has no load
                    CWFlow = MinColdWaterFlow
            else:
                // unit Off
                CWFlow = MinColdWaterFlow
            // Get the cooling output at the chosen water flow rate
            CalcCoolBeam(state, CBNum, ZoneNodeNum, CWFlow, PowerMet, TWOut)
            coolBeam.BeamCoolingRate = -PowerMet
            if QSup < 0.0:
                coolBeam.SupAirCoolingRate = abs(QSup)
            else:
                coolBeam.SupAirHeatingRate = QSup
            coolBeam.CoolWaterMassFlow = state.dataLoopNodes.Node[ControlNode].MassFlowRate
            coolBeam.TWOut = TWOut
            coolBeam.EnthWaterOut = state.dataLoopNodes.Node[ControlNode].Enthalpy + coolBeam.BeamCoolingRate
            //  Node(ControlNode)%MassFlowRate = CWFlow
            NonAirSysOutput = PowerMet

        def CalcCoolBeam(state: EnergyPlusData,
                        CBNum: Int,     // Unit index
                        ZoneNode: Int,  // zone node number
                        CWFlow: Float64, // cold water flow [kg/s]
                        LoadMet: Float64,     // load met by unit [W]
                        TWOut: Float64        // chilled water outlet temperature [C]
        ):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   Feb 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // Simulate a cooled beam given the chilled water flow rate

            // METHODOLOGY EMPLOYED:
            // Uses the cooled beam equations; iteratively varies water outlet  temperature
            // until air-side and water-side cooling outputs match.

            // REFERENCES:
            // na

            // Using/Aliasing
            using PlantUtilities.SetComponentFlowRate

            // Locals
            // SUBROUTINE ARGUMENT DEFINITIONS:

            // SUBROUTINE PARAMETER DEFINITIONS:
            var RoutineName: StringLiteral = "CalcCoolBeam"

            // INTERFACE BLOCK SPECIFICATIONS
            // na

            // DERIVED TYPE DEFINITIONS
            // na

            // SUBROUTINE LOCAL VARIABLE DECLARATIONS:
            var Iter: Int = 0                // TWOut iteration index
            var TWIn: Float64 = 0.0           // Inlet water temperature [C]
            var ZTemp: Float64 = 0.0          // zone air temperature [C]
            var WaterCoolPower: Float64 = 0.0 // cooling power from water side [W]
            var DT: Float64 = 0.0             // approximate air - water delta T [C]
            var IndFlow: Float64 = 0.0        // induced air flow rate per beam length [m3/s-m]
            var CoilFlow: Float64 = 0.0       // mass air flow rate of air passing through "coil" [kg/m2-s]
            var WaterVel: Float64 = 0.0       // water velocity [m/s]
            var K: Float64 = 0.0              // coil heat transfer coefficient [W/m2-K]
            var AirCoolPower: Float64 = 0.0   // cooling power from the air side [W]
            var Diff: Float64                // difference between water side cooling power and air side cooling power [W]
            var CWFlowPerBeam: Float64 = 0.0  // water mass flow rate per beam
            var Coeff: Float64 = 0.0          // iteration parameter
            var Delta: Float64 = 0.0
            var mdot: Float64 = 0.0
            var Cp: Float64  // local fluid specific heat
            var rho: Float64 // local fluid density

            // test CWFlow against plant
            mdot = CWFlow
            var coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum]

            SetComponentFlowRate(state, mdot, coolBeam.CWInNode, coolBeam.CWOutNode, coolBeam.CWPlantLoc)

            CWFlowPerBeam = mdot / coolBeam.NumBeams
            TWIn = coolBeam.TWIn

            Cp = coolBeam.CWPlantLoc.loop.glycol.getSpecificHeat(state, TWIn, RoutineName)

            rho = coolBeam.CWPlantLoc.loop.glycol.getDensity(state, TWIn, RoutineName)

            TWOut = TWIn + 2.0
            ZTemp = state.dataLoopNodes.Node[ZoneNode].Temp
            if mdot <= 0.0 or TWIn <= 0.0:
                LoadMet = 0.0
                TWOut = TWIn
                return
            for Iter in range(1, 201):
                if Iter > 50 and Iter < 100:
                    Coeff = 0.1 * Coeff2
                elif Iter > 100:
                    Coeff = 0.01 * Coeff2
                else:
                    Coeff = Coeff2

                WaterCoolPower = CWFlowPerBeam * Cp * (TWOut - TWIn)
                DT = max(ZTemp - 0.5 * (TWIn + TWOut), 0.0)
                IndFlow = coolBeam.K1 * pow(DT, coolBeam.n) + coolBeam.Kin * coolBeam.BeamFlow / coolBeam.BeamLength
                CoilFlow = (IndFlow / coolBeam.a0) * state.dataEnvrn.StdRhoAir
                WaterVel = CWFlowPerBeam / (rho * Constant.Pi * pow_2(coolBeam.InDiam) / 4.0)
                if WaterVel > MinWaterVel:
                    K = coolBeam.a * pow(DT, coolBeam.n1) * pow(CoilFlow, coolBeam.n2) * pow(WaterVel, coolBeam.n3)
                else:
                    K = coolBeam.a * pow(DT, coolBeam.n1) * pow(CoilFlow, coolBeam.n2) * pow(MinWaterVel, coolBeam.n3) * (WaterVel / MinWaterVel)
                AirCoolPower = K * coolBeam.CoilArea * DT * coolBeam.BeamLength
                Diff = WaterCoolPower - AirCoolPower
                Delta = TWOut * (abs(Diff) / Coeff)
                if abs(Diff) > 0.1:
                    if Diff < 0.0:
                        TWOut += Delta      // increase TWout
                        if TWOut > ZTemp: // check that water outlet temperature is less than zone temperature
                            WaterCoolPower = 0.0
                            TWOut = ZTemp
                            break
                    else:
                        TWOut -= Delta // Decrease TWout
                        if TWOut < TWIn:
                            TWOut = TWIn
                else:
                    // water and air side outputs have converged
                    break
            LoadMet = -WaterCoolPower * coolBeam.NumBeams

        def UpdateCoolBeam(state: EnergyPlusData, CBNum: Int):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   Feb 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // This subroutine updates the cooled beam unit outlet nodes

            // METHODOLOGY EMPLOYED:
            // Data is moved from the cooled beam unit data structure to the unit outlet nodes.

            // SUBROUTINE LOCAL VARIABLE DECLARATIONS:
            var coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum]
            var airInletNode = state.dataLoopNodes.Node[coolBeam.AirInNode]
            var airOutletNode = state.dataLoopNodes.Node[coolBeam.AirOutNode]

            // Set the outlet air nodes of the unit; note that all quantities are unchanged
            airOutletNode.MassFlowRate = airInletNode.MassFlowRate
            airOutletNode.Temp = airInletNode.Temp
            airOutletNode.HumRat = airInletNode.HumRat
            airOutletNode.Enthalpy = airInletNode.Enthalpy

            // Set the outlet water nodes for the unit
            PlantUtilities.SafeCopyPlantNode(state, coolBeam.CWInNode, coolBeam.CWOutNode)

            state.dataLoopNodes.Node[coolBeam.CWOutNode].Temp = coolBeam.TWOut
            state.dataLoopNodes.Node[coolBeam.CWOutNode].Enthalpy = coolBeam.EnthWaterOut

            // Set the air outlet nodes for properties that just pass through & not used
            airOutletNode.Quality = airInletNode.Quality
            airOutletNode.Press = airInletNode.Press
            airOutletNode.MassFlowRateMin = airInletNode.MassFlowRateMin
            airOutletNode.MassFlowRateMax = airInletNode.MassFlowRateMax
            airOutletNode.MassFlowRateMinAvail = airInletNode.MassFlowRateMinAvail
            airOutletNode.MassFlowRateMaxAvail = airInletNode.MassFlowRateMaxAvail

            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                airOutletNode.CO2 = airInletNode.CO2

            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                airOutletNode.GenContam = airInletNode.GenContam

        def ReportCoolBeam(state: EnergyPlusData, CBNum: Int):

            // SUBROUTINE INFORMATION:
            //       AUTHOR         Fred Buhl
            //       DATE WRITTEN   Feb 2009
            //       MODIFIED       na
            //       RE-ENGINEERED  na

            // PURPOSE OF THIS SUBROUTINE:
            // This subroutine updates the report variable for the cooled beam units

            // METHODOLOGY EMPLOYED:
            // NA

            // REFERENCES:
            // na

            // USE STATEMENTS:

            // Locals
            // SUBROUTINE ARGUMENT DEFINITIONS:

            // SUBROUTINE PARAMETER DEFINITIONS:
            // na

            // INTERFACE BLOCK SPECIFICATIONS
            // na

            // DERIVED TYPE DEFINITIONS
            // na

            // SUBROUTINE LOCAL VARIABLE DECLARATIONS:

            var ReportingConstant: Float64
            var coolBeam = state.dataHVACCooledBeam.CoolBeam[CBNum]

            ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
            // report the WaterCoil energy from this component
            coolBeam.BeamCoolingEnergy = coolBeam.BeamCoolingRate * ReportingConstant
            coolBeam.SupAirCoolingEnergy = coolBeam.SupAirCoolingRate * ReportingConstant
            coolBeam.SupAirHeatingEnergy = coolBeam.SupAirHeatingRate * ReportingConstant

            // set zone OA volume flow rate report variable
            coolBeam.CalcOutdoorAirVolumeFlowRate(state)

        def CoolBeamData.CalcOutdoorAirVolumeFlowRate(self, state: EnergyPlusData):
            // calculates zone outdoor air volume flow rate using the supply air flow rate and OA fraction
            if self.AirLoopNum > 0:
                self.OutdoorAirFlowRate = (state.dataLoopNodes.Node[self.AirOutNode].MassFlowRate / state.dataEnvrn.StdRhoAir) * state.dataAirLoop.AirLoopFlow[self.AirLoopNum].OAFrac
            else:
                self.OutdoorAirFlowRate = 0.0

        def CoolBeamData.reportTerminalUnit(self, state: EnergyPlusData):
            // populate the predefined equipment summary report related to air terminals
            var orp = state.dataOutRptPredefined
            var adu = state.dataDefineEquipment.AirDistUnit[self.ADUNum]
            if not state.dataSize.TermUnitFinalZoneSizing.empty():
                var sizing = state.dataSize.TermUnitFinalZoneSizing[adu.TermUnitSizingNum]
                OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermMinFlow, adu.Name, sizing.DesCoolVolFlowMin)
                OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermMinOutdoorFlow, adu.Name, sizing.MinOA)
                OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermSupCoolingSP, adu.Name, sizing.CoolDesTemp)
                OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermSupHeatingSP, adu.Name, sizing.HeatDesTemp)
                OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermHeatingCap, adu.Name, sizing.DesHeatLoad)
                OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermCoolingCap, adu.Name, sizing.DesCoolLoad)
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermTypeInp, adu.Name, self.UnitType)
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermPrimFlow, adu.Name, self.MaxAirVolFlow)
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermSecdFlow, adu.Name, "n/a")
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermMinFlowSch, adu.Name, "n/a")
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermMaxFlowReh, adu.Name, "n/a")
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermMinOAflowSch, adu.Name, "n/a")
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermHeatCoilType, adu.Name, "n/a")
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermCoolCoilType, adu.Name, self.CBTypeString)
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermFanType, adu.Name, "n/a")
            OutputReportPredefined.PreDefTableEntry(state, orp.pdchAirTermFanName, adu.Name, "n/a")

    // end namespace HVACCooledBeam

// end namespace EnergyPlus
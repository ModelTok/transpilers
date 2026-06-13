from Data.BaseData import BaseGlobalStruct
from Data.EnergyPlusData import EnergyPlusData
from DataHeatBalance import *
from EnergyPlus import *
from InputProcessing.InputProcessor import *
from Material import MaterialBase, Group, Phase, phaseInts
from UtilityRoutines import *

@value
struct MaterialPhaseChange(MaterialBase):
    var enthalpyM: Float64 = 0.0
    var enthalpyF: Float64 = 0.0
    var totalLatentHeat: Float64 = 0.0
    var specificHeatLiquid: Float64 = 0.0
    var deltaTempMeltingHigh: Float64 = 0.0
    var peakTempMelting: Float64 = 0.0
    var deltaTempMeltingLow: Float64 = 0.0
    var specificHeatSolid: Float64 = 0.0
    var deltaTempFreezingHigh: Float64 = 0.0
    var peakTempFreezing: Float64 = 0.0
    var deltaTempFreezingLow: Float64 = 0.0
    var fullySolidThermalConductivity: Float64 = 0.0
    var fullyLiquidThermalConductivity: Float64 = 0.0
    var fullySolidDensity: Float64 = 0.0
    var fullyLiquidDensity: Float64 = 0.0
    var phaseChangeTransition: Bool = False
    var enthOld: Float64 = 0.0
    var enthNew: Float64 = 0.0
    var enthRev: Float64 = 0.0
    var CpOld: Float64 = 0.0
    var specHeatTransition: Float64 = 0.0

    def getEnthalpy(self, T: Float64, Tc: Float64, tau1: Float64, tau2: Float64) -> Float64:
        var eta1: Float64 = (self.totalLatentHeat / 2) * exp(-2 * abs(T - Tc) / tau1)
        var eta2: Float64 = (self.totalLatentHeat / 2) * exp(-2 * abs(T - Tc) / tau2)
        if T <= Tc:
            return (self.specificHeatSolid * T) + eta1
        return (self.specificHeatSolid * Tc) + self.totalLatentHeat + self.specificHeatLiquid * (T - Tc) - eta2

    def getCurrentSpecificHeat(
        self,
        prevTempTD: Float64,
        updatedTempTDT: Float64,
        phaseChangeTempReverse: Float64,
        prevPhaseChangeState: Phase,
        phaseChangeState: Pointer[Phase]
    ) -> Float64:
        var TempLowPCM: Float64 = self.peakTempMelting - self.deltaTempMeltingLow
        var TempHighPCM: Float64 = self.peakTempMelting + self.deltaTempMeltingHigh
        var Tc: Float64
        var Tau1: Float64
        var Tau2: Float64
        var TempLowPCF: Float64 = self.peakTempFreezing - self.deltaTempFreezingLow
        var TempHighPCF: Float64 = self.peakTempFreezing + self.deltaTempFreezingHigh
        var Cp: Float64
        var phaseChangeDeltaT: Float64 = prevTempTD - updatedTempTDT
        if phaseChangeDeltaT <= 0:
            Tc = self.peakTempMelting
            Tau1 = self.deltaTempMeltingLow
            Tau2 = self.deltaTempMeltingHigh
            if updatedTempTDT < TempLowPCM:
                phaseChangeState[] = Phase.Crystallized
            elif updatedTempTDT <= TempHighPCM:
                phaseChangeState[] = Phase.Melting
                if prevPhaseChangeState == Phase.Freezing or prevPhaseChangeState == Phase.Transition:
                    phaseChangeState[] = Phase.Transition
            else:
                phaseChangeState[] = Phase.Liquid
        else:
            Tc = self.peakTempFreezing
            Tau1 = self.deltaTempFreezingLow
            Tau2 = self.deltaTempFreezingHigh
            if updatedTempTDT < TempLowPCF:
                phaseChangeState[] = Phase.Crystallized
            elif updatedTempTDT <= TempHighPCF:
                phaseChangeState[] = Phase.Freezing
                if prevPhaseChangeState == Phase.Melting or prevPhaseChangeState == Phase.Transition:
                    phaseChangeState[] = Phase.Transition
            else:
                phaseChangeState[] = Phase.Liquid
        if prevPhaseChangeState == Phase.Transition and phaseChangeState[] == Phase.Crystallized:
            self.phaseChangeTransition = True
        elif prevPhaseChangeState == Phase.Transition and phaseChangeState[] == Phase.Freezing:
            self.phaseChangeTransition = True
        elif prevPhaseChangeState == Phase.Freezing and phaseChangeState[] == Phase.Transition:
            self.phaseChangeTransition = True
        elif prevPhaseChangeState == Phase.Crystallized and phaseChangeState[] == Phase.Transition:
            self.phaseChangeTransition = True
        else:
            self.phaseChangeTransition = False
        if not self.phaseChangeTransition:
            self.enthOld = self.getEnthalpy(prevTempTD, Tc, Tau1, Tau2)
            self.enthNew = self.getEnthalpy(updatedTempTDT, Tc, Tau1, Tau2)
        else:
            if prevPhaseChangeState == Phase.Freezing and phaseChangeState[] == Phase.Transition:
                self.enthRev = self.getEnthalpy(phaseChangeTempReverse, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthOld - (self.specHeatTransition * prevTempTD))
                self.enthalpyM = self.getEnthalpy(updatedTempTDT, self.peakTempMelting, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
                self.enthalpyF = self.getEnthalpy(updatedTempTDT, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                if self.enthNew < self.enthRev and self.enthNew >= self.enthalpyF and updatedTempTDT <= prevTempTD:
                    phaseChangeState[] = Phase.Freezing
                    self.enthNew = self.getEnthalpy(updatedTempTDT, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                elif (self.enthNew < self.enthalpyF) and (self.enthNew > self.enthalpyM):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthOld - (self.specHeatTransition * prevTempTD))
                elif (self.enthNew < self.enthalpyF) and (updatedTempTDT > phaseChangeTempReverse):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
                elif (self.enthNew <= self.enthalpyM) and (updatedTempTDT <= phaseChangeTempReverse):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
            elif prevPhaseChangeState == Phase.Transition and phaseChangeState[] == Phase.Transition:
                if updatedTempTDT < phaseChangeTempReverse:
                    Tc = self.peakTempMelting
                    Tau1 = self.deltaTempMeltingLow
                    Tau2 = self.deltaTempMeltingHigh
                elif updatedTempTDT > phaseChangeTempReverse:
                    Tc = self.peakTempFreezing
                    Tau1 = self.deltaTempFreezingLow
                    Tau2 = self.deltaTempFreezingHigh
                self.enthRev = self.getEnthalpy(phaseChangeTempReverse, Tc, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
                self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthOld - (self.specHeatTransition * prevTempTD))
                self.enthalpyM = self.getEnthalpy(updatedTempTDT, self.peakTempMelting, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
                self.enthalpyF = self.getEnthalpy(updatedTempTDT, self.peakTempMelting, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
                if (updatedTempTDT < phaseChangeTempReverse) and (self.enthNew > self.enthalpyF):
                    phaseChangeState[] = Phase.Freezing
                    self.enthNew = self.getEnthalpy(updatedTempTDT, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                elif (self.enthNew < self.enthalpyF) and (self.enthNew > self.enthalpyM) and (updatedTempTDT < prevTempTD or updatedTempTDT > prevTempTD):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
                elif self.enthNew <= self.enthalpyM and updatedTempTDT >= prevTempTD and self.enthNew > self.enthOld:
                    phaseChangeState[] = Phase.Melting
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
            elif prevPhaseChangeState == Phase.Transition and phaseChangeState[] == Phase.Crystallized:
                self.enthRev = self.getEnthalpy(phaseChangeTempReverse, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
                self.enthalpyM = self.getEnthalpy(updatedTempTDT, self.peakTempMelting, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
                self.enthalpyF = self.getEnthalpy(updatedTempTDT, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                if (self.enthNew < self.enthalpyF) and (self.enthNew > self.enthalpyM):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
                elif self.enthNew <= self.enthalpyM and updatedTempTDT >= prevTempTD:
                    phaseChangeState[] = Phase.Melting
                    self.enthNew = self.getEnthalpy(updatedTempTDT, self.peakTempMelting, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
            elif prevPhaseChangeState == Phase.Melting and phaseChangeState[] == Phase.Transition:
                self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthOld - (self.specHeatTransition * prevTempTD))
                self.enthalpyM = self.getEnthalpy(updatedTempTDT, self.peakTempMelting, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
                self.enthalpyF = self.getEnthalpy(updatedTempTDT, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                if (self.enthNew < self.enthOld) and (updatedTempTDT < prevTempTD):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthOld - (self.specHeatTransition * prevTempTD))
                elif (self.enthNew < self.enthalpyF) and (self.enthNew > self.enthalpyM) and (updatedTempTDT < prevTempTD):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
                elif (self.enthNew >= self.enthalpyF) and (updatedTempTDT <= phaseChangeTempReverse):
                    phaseChangeState[] = Phase.Transition
                    self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
            elif prevPhaseChangeState == Phase.Transition and phaseChangeState[] == Phase.Freezing:
                self.enthalpyM = self.getEnthalpy(updatedTempTDT, self.peakTempMelting, self.deltaTempMeltingLow, self.deltaTempMeltingHigh)
                self.enthalpyF = self.getEnthalpy(updatedTempTDT, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                self.enthRev = self.getEnthalpy(phaseChangeTempReverse, self.peakTempFreezing, self.deltaTempFreezingLow, self.deltaTempFreezingHigh)
                self.enthNew = (self.specHeatTransition * updatedTempTDT) + (self.enthRev - (self.specHeatTransition * phaseChangeTempReverse))
        if not self.phaseChangeTransition:
            if self.enthNew == self.enthOld:
                Cp = self.CpOld
            else:
                Cp = self.specHeat(prevTempTD, updatedTempTDT, Tc, Tau1, Tau2, self.enthOld, self.enthNew)
        else:
            Cp = self.specHeatTransition
        self.CpOld = Cp
        return Cp

    def specHeat(self, temperaturePrev: Float64, temperatureCurrent: Float64, criticalTemperature: Float64, tau1: Float64, tau2: Float64, EnthalpyOld: Float64, EnthalpyNew: Float64) -> Float64:
        var T: Float64 = temperatureCurrent
        if T < criticalTemperature:
            var DEta1: Float64 = -(self.totalLatentHeat * (T - criticalTemperature) * exp(-2 * abs(T - criticalTemperature) / tau1)) / (tau1 * abs(T - criticalTemperature))
            var Cp1: Float64 = self.specificHeatSolid
            return (Cp1 + DEta1)
        if T == criticalTemperature:
            return (EnthalpyNew - EnthalpyOld) / (temperatureCurrent - temperaturePrev)
        var DEta2: Float64 = (self.totalLatentHeat * (T - criticalTemperature) * exp(-2 * abs(T - criticalTemperature) / tau2)) / (tau2 * abs(T - criticalTemperature))
        var Cp2: Float64 = self.specificHeatLiquid
        return Cp2 + DEta2

    def getConductivity(self, T: Float64) -> Float64:
        if T < self.peakTempMelting:
            return self.fullySolidThermalConductivity
        if T > self.peakTempFreezing:
            return self.fullyLiquidThermalConductivity
        return (self.fullySolidThermalConductivity + self.fullyLiquidThermalConductivity) / 2.0

    def getDensity(self, T: Float64) -> Float64:
        if T < self.peakTempMelting:
            return self.fullySolidDensity
        if T > self.peakTempFreezing:
            return self.fullyLiquidDensity
        return (self.fullySolidDensity + self.fullyLiquidDensity) / 2.0

def GetHysteresisData(state: EnergyPlusData, ErrorsFound: Bool):
    var routineName: StringLiteral = "GetHysteresisData"
    var s_ip = state.dataInputProcessing.inputProcessor
    var s_mat = state.dataMaterial
    var currentModuleObject: StringLiteral = "MaterialProperty:PhaseChangeHysteresis"
    var hysteresisSchemaProps = s_ip.getObjectSchemaProps(state, currentModuleObject)
    var hysteresisObjects = s_ip.epJSON.find(currentModuleObject)
    var nameFieldName: StringLiteral = "Name"
    if hysteresisObjects == s_ip.epJSON.end():
        return
    for hysteresisInstance in hysteresisObjects.value().items():
        var hysteresisFields = hysteresisInstance.value()
        var materialName = Util.makeUPPER(hysteresisInstance.key())
        s_ip.markObjectAsUsed(currentModuleObject, hysteresisInstance.key())
        var eoh = ErrorObjectHeader(routineName, currentModuleObject, materialName)
        if materialName.empty():
            ShowSevereEmptyField(state, eoh, nameFieldName, materialName)
            ErrorsFound = True
            continue
        var matNum = GetMaterialNum(state, materialName)
        if matNum == 0:
            ShowSevereItemNotFound(state, eoh, nameFieldName, materialName)
            ErrorsFound = True
            continue
        var mat = s_mat.materials(matNum)
        if mat.group != Group.Regular:
            ShowSevereCustom(state, eoh, format("Material {} is not a Regular material.", mat.Name))
            ErrorsFound = True
            continue
        if mat.hasPCM:
            ShowSevereCustom(state, eoh, format("Material {} already has {} properties defined.", mat.Name, currentModuleObject))
            ErrorsFound = True
            continue
        if mat.hasEMPD:
            ShowSevereCustom(state, eoh, format("Material {} already has EMPD properties defined.", mat.Name))
            ErrorsFound = True
            continue
        if mat.hasHAMT:
            ShowSevereCustom(state, eoh, format("Material {} already has HAMT properties defined.", mat.Name))
            ErrorsFound = True
            continue
        var matPC = MaterialPhaseChange()
        matPC.MaterialBase.__assign__(mat[])
        s_mat.materials(matNum) = matPC
        matPC.totalLatentHeat = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "latent_heat_during_the_entire_phase_change_process")
        matPC.fullyLiquidThermalConductivity = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "liquid_state_thermal_conductivity")
        matPC.fullyLiquidDensity = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "liquid_state_density")
        matPC.specificHeatLiquid = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "liquid_state_specific_heat")
        matPC.deltaTempMeltingHigh = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "high_temperature_difference_of_melting_curve")
        matPC.peakTempMelting = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "peak_melting_temperature")
        matPC.deltaTempMeltingLow = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "low_temperature_difference_of_melting_curve")
        matPC.fullySolidThermalConductivity = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "solid_state_thermal_conductivity")
        matPC.fullySolidDensity = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "solid_state_density")
        matPC.specificHeatSolid = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "solid_state_specific_heat")
        matPC.deltaTempFreezingHigh = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "high_temperature_difference_of_freezing_curve")
        matPC.peakTempFreezing = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "peak_freezing_temperature")
        matPC.deltaTempFreezingLow = s_ip.getRealFieldValue(hysteresisFields, hysteresisSchemaProps, "low_temperature_difference_of_freezing_curve")
        matPC.specHeatTransition = (matPC.specificHeatSolid + matPC.specificHeatLiquid) / 2.0
        matPC.CpOld = matPC.specificHeatSolid
        matPC.hasPCM = True

@value
struct HysteresisPhaseChangeData(BaseGlobalStruct):
    var getHysteresisModels: Bool = True

    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(self):
        self.getHysteresisModels = True
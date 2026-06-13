from GasProperties import GasProperties
from GasCreator import Gas, GasDef
from GasData import CGasData
from GasItem import CGasItem
from GasSetting import CGasSettings, DefaultPressure
from Math import pow, sqrt
from List import List
from Tuple import Tuple
from Error import Error

module Gases:

    struct CGas:
        var m_GasItem: List[CGasItem]
        var m_SimpleProperties: GasProperties
        var m_Properties: GasProperties
        var m_DefaultGas: Bool
        var m_Pressure: Float64

        def __init__(mut self):
            self.m_Pressure = DefaultPressure
            var Air = CGasItem()
            self.m_GasItem.append(Air)
            self.m_DefaultGas = True

        def __init__(mut self, gases: List[Tuple[Float64, CGasData]]):
            self.m_Pressure = DefaultPressure
            self.addGasItems(gases)

        def __init__(mut self, gases: List[Tuple[Float64, GasDef]]):
            self.m_Pressure = DefaultPressure
            self.addGasItems(gases)

        def __init__(mut self, t_Gas: CGas):
            self.m_GasItem = t_Gas.m_GasItem
            self.m_SimpleProperties = t_Gas.m_SimpleProperties
            self.m_Properties = t_Gas.m_Properties
            self.m_DefaultGas = t_Gas.m_DefaultGas
            self.m_Pressure = t_Gas.m_Pressure
            self.m_GasItem.clear()
            for item in t_Gas.m_GasItem:
                self.m_GasItem.append(item)

        def addGasItem(mut self, percent: Float64, t_GasData: CGasData):
            var item = CGasItem(percent, t_GasData)
            if self.m_DefaultGas:
                self.m_GasItem.clear()
                self.m_DefaultGas = False
            self.m_GasItem.append(item)

        def addGasItems(mut self, gases: List[Tuple[Float64, CGasData]]):
            if self.m_DefaultGas:
                self.m_GasItem.clear()
                self.m_DefaultGas = False
            for item in gases:
                self.m_GasItem.append(CGasItem(item[0], item[1]))

        def addGasItems(mut self, gases: List[Tuple[Float64, GasDef]]):
            if self.m_DefaultGas:
                self.m_GasItem.clear()
                self.m_DefaultGas = False
            for item in gases:
                self.m_GasItem.append(CGasItem(item[0], Gas.intance().get(item[1])))

        def addGasItem(mut self, percent: Float64, def_: GasDef):
            self.addGasItem(percent, Gas.intance().get(def_))

        def totalPercent(mut self) -> Float64:
            var totalPercent = 0.0
            for it in self.m_GasItem:
                totalPercent += it.getFraction()
            return totalPercent

        def setTemperatureAndPressure(mut self, t_Temperature: Float64, t_Pressure: Float64):
            self.m_Pressure = t_Pressure
            for item in self.m_GasItem:
                item.setTemperature(t_Temperature)
                item.setPressure(t_Pressure)

        def getSimpleGasProperties(mut self) -> &GasProperties:
            self.m_SimpleProperties = *(self.m_GasItem[0].getFractionalGasProperties())
            var it = 1
            while it < len(self.m_GasItem):
                self.m_SimpleProperties += *(self.m_GasItem[it].getFractionalGasProperties())
                it += 1
            return self.m_SimpleProperties

        def getGasProperties(mut self) -> &GasProperties:
            var aSettings = CGasSettings.instance()
            if aSettings.getVacuumPressure() < self.m_Pressure:
                return self.getStandardPressureGasProperties()
            else:
                return self.getVacuumPressureGasProperties()

        def getStandardPressureGasProperties(mut self) -> &GasProperties:
            var simpleProperties = self.getSimpleGasProperties()
            var miItem: List[List[Float64]] = List[List[Float64]]()
            var lambdaPrimItem: List[List[Float64]] = List[List[Float64]]()
            var lambdaSecondItem: List[List[Float64]] = List[List[Float64]]()
            var gasSize = len(self.m_GasItem)
            var counter = 0
            miItem.resize(gasSize)
            lambdaPrimItem.resize(gasSize)
            lambdaSecondItem.resize(gasSize)
            for primaryIt in self.m_GasItem:
                for secondaryIt in self.m_GasItem:
                    if primaryIt != secondaryIt:
                        miItem[counter].append(self.viscDenomTwoGases(primaryIt, secondaryIt))
                        lambdaPrimItem[counter].append(self.lambdaPrimDenomTwoGases(primaryIt, secondaryIt))
                        lambdaSecondItem[counter].append(self.lambdaSecondDenomTwoGases(primaryIt, secondaryIt))
                    else:
                        miItem[counter].append(0.0)
                        lambdaPrimItem[counter].append(0.0)
                        lambdaSecondItem[counter].append(0.0)
                counter += 1
            var miMix = 0.0
            var lambdaPrimMix = 0.0
            var lambdaSecondMix = 0.0
            var cpMix = 0.0
            counter = 0
            for it in self.m_GasItem:
                var itGasProperties = it.getGasProperties()
                var lambdaPrim = (*itGasProperties).getLambdaPrim()
                var lambdaSecond = (*itGasProperties).getLambdaSecond()
                var sumMix = 1.0
                for i in range(gasSize):
                    sumMix += miItem[counter][i]
                miMix += (*itGasProperties).m_Viscosity / sumMix
                sumMix = 1.0
                for i in range(gasSize):
                    sumMix += lambdaPrimItem[counter][i]
                lambdaPrimMix += lambdaPrim / sumMix
                sumMix = 1.0
                for i in range(gasSize):
                    sumMix += lambdaSecondItem[counter][i]
                lambdaSecondMix += lambdaSecond / sumMix
                cpMix += (*itGasProperties).m_SpecificHeat * it.getFraction() * (*itGasProperties).m_MolecularWeight
                counter += 1
            self.m_Properties.m_ThermalConductivity = lambdaPrimMix + lambdaSecondMix
            self.m_Properties.m_Viscosity = miMix
            self.m_Properties.m_SpecificHeat = cpMix / simpleProperties.m_MolecularWeight
            self.m_Properties.m_Density = simpleProperties.m_Density
            self.m_Properties.m_MolecularWeight = simpleProperties.m_MolecularWeight
            self.m_Properties.calculateAlphaAndPrandl()
            return self.m_Properties

        def getVacuumPressureGasProperties(mut self) -> &GasProperties:
            return self.getSimpleGasProperties()

        def viscTwoGases(mut self, t_Gas1Properties: GasProperties, t_Gas2Properties: GasProperties) -> Float64:
            if t_Gas1Properties.m_Viscosity == 0.0 or t_Gas2Properties.m_Viscosity == 0.0:
                raise Error("Viscosity of the gas component in Gases is equal to zero.")
            if t_Gas1Properties.m_MolecularWeight == 0.0 or t_Gas2Properties.m_MolecularWeight == 0.0:
                raise Error("Molecular weight of the gas component in Gases is equal to zero.")
            var uFraction = t_Gas1Properties.m_Viscosity / t_Gas2Properties.m_Viscosity
            var weightFraction = t_Gas1Properties.m_MolecularWeight / t_Gas2Properties.m_MolecularWeight
            var nominator = pow((1.0 + pow(uFraction, 0.5) * pow(1.0 / weightFraction, 0.25)), 2.0)
            var denominator = 2.0 * sqrt(2.0) * pow(1.0 + weightFraction, 0.5)
            if denominator == 0.0:
                raise Error("Dynamic viscosity coefficient is gas mixture is calculated to be zero.")
            return nominator / denominator

        def viscDenomTwoGases(mut self, t_GasItem1: CGasItem, t_GasItem2: CGasItem) -> Float64:
            var phiValue = self.viscTwoGases(*(t_GasItem1.getGasProperties()), *(t_GasItem2.getGasProperties()))
            if t_GasItem1.getFraction() == 0.0 or t_GasItem2.getFraction() == 0.0:
                raise Error("Fraction of gas component in gas mixture is set to be equal to zero.")
            return (t_GasItem2.getFraction() / t_GasItem1.getFraction()) * phiValue

        def lambdaPrimTwoGases(mut self, t_Gas1Properties: GasProperties, t_Gas2Properties: GasProperties) -> Float64:
            if t_Gas1Properties.m_MolecularWeight == 0.0 or t_Gas2Properties.m_MolecularWeight == 0.0:
                raise Error("Molecular weight of the gas component in Gases is equal to zero.")
            var item1 = self.lambdaSecondTwoGases(t_Gas1Properties, t_Gas2Properties)
            var item2 = 1.0 + 2.41 * ((t_Gas1Properties.m_MolecularWeight - t_Gas2Properties.m_MolecularWeight) * (t_Gas1Properties.m_MolecularWeight - 0.142 * t_Gas2Properties.m_MolecularWeight) / pow((t_Gas1Properties.m_MolecularWeight + t_Gas2Properties.m_MolecularWeight), 2.0))
            return item1 * item2

        def lambdaSecondTwoGases(mut self, t_Gas1Properties: GasProperties, t_Gas2Properties: GasProperties) -> Float64:
            if t_Gas1Properties.getLambdaPrim() == 0.0 or t_Gas2Properties.getLambdaPrim() == 0.0:
                raise Error("Primary thermal conductivity (lambda prim) of the gas component in Gases is equal to zero.")
            if t_Gas1Properties.m_MolecularWeight == 0.0 or t_Gas2Properties.m_MolecularWeight == 0.0:
                raise Error("Molecular weight of the gas component in Gases is equal to zero.")
            var tFraction = t_Gas1Properties.getLambdaPrim() / t_Gas2Properties.getLambdaPrim()
            var weightFraction = t_Gas1Properties.m_MolecularWeight / t_Gas2Properties.m_MolecularWeight
            var nominator = pow((1.0 + pow(tFraction, 0.5) * pow(weightFraction, 0.25)), 2.0)
            var denominator = 2.0 * sqrt(2.0) * pow((1.0 + weightFraction), 0.5)
            if denominator == 0.0:
                raise Error("Thermal conductivity coefficient in gas mixture is calculated to be zero.")
            return nominator / denominator

        def lambdaPrimDenomTwoGases(mut self, t_GasItem1: CGasItem, t_GasItem2: CGasItem) -> Float64:
            var phiValue = self.lambdaPrimTwoGases(*(t_GasItem1.getGasProperties()), *(t_GasItem2.getGasProperties()))
            if t_GasItem1.getFraction() == 0.0 or t_GasItem2.getFraction() == 0.0:
                raise Error("Fraction of gas component in gas mixture is set to be equal to zero.")
            return (t_GasItem2.getFraction() / t_GasItem1.getFraction()) * phiValue

        def lambdaSecondDenomTwoGases(mut self, t_GasItem1: CGasItem, t_GasItem2: CGasItem) -> Float64:
            var phiValue = self.lambdaSecondTwoGases(*(t_GasItem1.getGasProperties()), *(t_GasItem2.getGasProperties()))
            if t_GasItem1.getFraction() == 0.0 or t_GasItem2.getFraction() == 0.0:
                raise Error("Fraction of gas component in gas mixture is set to be equal to zero.")
            return (t_GasItem2.getFraction() / t_GasItem1.getFraction()) * phiValue

        def __copyinit__(mut self, t_Gas: CGas):
            self.m_GasItem.clear()
            for item in t_Gas.m_GasItem:
                self.m_GasItem.append(item)
            self.m_SimpleProperties = t_Gas.m_SimpleProperties
            self.m_Properties = t_Gas.m_Properties
            self.m_DefaultGas = t_Gas.m_DefaultGas
            self.m_Pressure = t_Gas.m_Pressure

        def __eq__(self, rhs: CGas) -> Bool:
            return self.m_GasItem == rhs.m_GasItem and self.m_SimpleProperties == rhs.m_SimpleProperties and self.m_Properties == rhs.m_Properties and self.m_DefaultGas == rhs.m_DefaultGas and self.m_Pressure == rhs.m_Pressure

        def __ne__(self, rhs: CGas) -> Bool:
            return not (rhs == self)
/**
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from lib_wind_obos_cable_vessel import cableFamily, vessel
from math import *
from builtins import *

# constants
let M_PI: Float64 = 3.14159265358979323846264338327
let GRAVITY: Float64 = 9.80633

# enums
let MONOPILE: Int = 0
let JACKET: Int = 1
let SPAR: Int = 2
let SEMISUBMERSIBLE: Int = 3

let DRAGEMBEDMENT: Int = 0
let SUCTIONPILE: Int = 1

let INDIVIDUAL: Int = 0
let BUNNYEARS: Int = 1
let ROTORASSEMBLED: Int = 2

let ONEPIECE: Int = 0
let TWOPIECE: Int = 1

let PRIMARYVESSEL: Int = 0
let FEEDERBARGE: Int = 1

struct wobos:
    # public members
    var turbCapEx: Float64
    var nTurb: Float64
    var rotorD: Float64
    var turbR: Float64
    var hubH: Float64
    var waterD: Float64
    var distShore: Float64
    var distPort: Float64
    var distPtoA: Float64
    var distAtoS: Float64
    var substructure: Int
    var anchor: Int
    var turbInstallMethod: Int
    var towerInstallMethod: Int
    var installStrategy: Int
    var cableOptimizer: Bool
    var moorLines: Float64
    var buryDepth: Float64
    var arrayY: Float64
    var arrayX: Float64
    var substructCont: Float64
    var turbCont: Float64
    var elecCont: Float64
    var interConVolt: Float64
    var distInterCon: Float64
    var scrapVal: Float64
    var number_install_seasons: Float64
    var projLife: Float64
    var inspectClear: Float64
    var plantComm: Float64
    var procurement_contingency: Float64
    var install_contingency: Float64
    var construction_insurance: Float64
    var capital_cost_year_0: Float64
    var capital_cost_year_1: Float64
    var capital_cost_year_2: Float64
    var capital_cost_year_3: Float64
    var capital_cost_year_4: Float64
    var capital_cost_year_5: Float64
    var tax_rate: Float64
    var interest_during_construction: Float64
    var mpileCR: Float64
    var mtransCR: Float64
    var mpileD: Float64
    var mpileL: Float64
    var jlatticeCR: Float64
    var jtransCR: Float64
    var jpileCR: Float64
    var jlatticeA: Float64
    var jpileL: Float64
    var jpileD: Float64
    var spStifColCR: Float64
    var spTapColCR: Float64
    var ballCR: Float64
    var deaFixLeng: Float64
    var ssStifColCR: Float64
    var ssTrussCR: Float64
    var ssHeaveCR: Float64
    var sSteelCR: Float64
    var moorDia: Float64
    var moorCR: Float64
    var mpEmbedL: Float64
    var scourMat: Float64
    var pwrFac: Float64
    var buryFac: Float64
    var arrVoltage: Float64
    var arrCab1Size: Float64
    var arrCab1Mass: Float64
    var cab1CurrRating: Float64
    var cab1CR: Float64
    var cab1TurbInterCR: Float64
    var arrCab2Size: Float64
    var arrCab2Mass: Float64
    var cab2CurrRating: Float64
    var cab2CR: Float64
    var cab2TurbInterCR: Float64
    var cab2SubsInterCR: Float64
    var catLengFac: Float64
    var exCabFac: Float64
    var subsTopFab: Float64
    var subsTopDes: Float64
    var topAssemblyFac: Float64
    var subsJackCR: Float64
    var subsPileCR: Float64
    var dynCabFac: Float64
    var shuntCR: Float64
    var highVoltSG: Float64
    var medVoltSG: Float64
    var backUpGen: Float64
    var workSpace: Float64
    var otherAncillary: Float64
    var mptCR: Float64
    var expVoltage: Float64
    var expCabSize: Float64
    var expCabMass: Float64
    var expCabCR: Float64
    var expCurrRating: Float64
    var expSubsInterCR: Float64
    var moorTimeFac: Float64
    var moorLoadout: Float64
    var moorSurvey: Float64
    var prepAA: Float64
    var prepSpar: Float64
    var upendSpar: Float64
    var prepSemi: Float64
    var turbFasten: Float64
    var boltTower: Float64
    var boltNacelle1: Float64
    var boltNacelle2: Float64
    var boltNacelle3: Float64
    var boltBlade1: Float64
    var boltBlade2: Float64
    var boltRotor: Float64
    var vesselPosTurb: Float64
    var vesselPosJack: Float64
    var vesselPosMono: Float64
    var subsVessPos: Float64
    var monoFasten: Float64
    var jackFasten: Float64
    var prepGripperMono: Float64
    var prepGripperJack: Float64
    var placePiles: Float64
    var prepHamMono: Float64
    var removeHamMono: Float64
    var prepHamJack: Float64
    var removeHamJack: Float64
    var placeJack: Float64
    var levJack: Float64
    var placeTemplate: Float64
    var hamRate: Float64
    var placeMP: Float64
    var instScour: Float64
    var placeTP: Float64
    var groutTP: Float64
    var tpCover: Float64
    var prepTow: Float64
    var spMoorCon: Float64
    var ssMoorCon: Float64
    var spMoorCheck: Float64
    var ssMoorCheck: Float64
    var ssBall: Float64
    var surfLayRate: Float64
    var cabPullIn: Float64
    var cabTerm: Float64
    var cabLoadout: Float64
    var buryRate: Float64
    var subsPullIn: Float64
    var shorePullIn: Float64
    var landConstruct: Float64
    var expCabLoad: Float64
    var subsLoad: Float64
    var placeTop: Float64
    var pileSpreadDR: Float64
    var pileSpreadMob: Float64
    var groutSpreadDR: Float64
    var groutSpreadMob: Float64
    var seaSpreadDR: Float64
    var seaSpreadMob: Float64
    var compRacks: Float64
    var cabSurveyCR: Float64
    var cabDrillDist: Float64
    var cabDrillCR: Float64
    var mpvRentalDR: Float64
    var diveTeamDR: Float64
    var winchDR: Float64
    var civilWork: Float64
    var elecWork: Float64
    var nCrane600: Float64
    var nCrane1000: Float64
    var crane600DR: Float64
    var crane1000DR: Float64
    var craneMobDemob: Float64
    var entranceExitRate: Float64
    var dockRate: Float64
    var wharfRate: Float64
    var laydownCR: Float64
    var estEnMFac: Float64
    var preFEEDStudy: Float64
    var feedStudy: Float64
    var stateLease: Float64
    var outConShelfLease: Float64
    var saPlan: Float64
    var conOpPlan: Float64
    var nepaEisMet: Float64
    var physResStudyMet: Float64
    var bioResStudyMet: Float64
    var socEconStudyMet: Float64
    var navStudyMet: Float64
    var nepaEisProj: Float64
    var physResStudyProj: Float64
    var bioResStudyProj: Float64
    var socEconStudyProj: Float64
    var navStudyProj: Float64
    var coastZoneManAct: Float64
    var rivsnHarbsAct: Float64
    var cleanWatAct402: Float64
    var cleanWatAct404: Float64
    var faaPlan: Float64
    var endSpecAct: Float64
    var marMamProtAct: Float64
    var migBirdAct: Float64
    var natHisPresAct: Float64
    var addLocPerm: Float64
    var metTowCR: Float64
    var decomDiscRate: Float64
    var arrCables: List[cableFamily]
    var expCables: List[cableFamily]
    var turbInstVessel: vessel
    var turbFeederBarge: vessel
    var subInstVessel: vessel
    var subFeederBarge: vessel
    var scourProtVessel: vessel
    var arrCabInstVessel: vessel
    var expCabInstVessel: vessel
    var substaInstVessel: vessel
    var turbSupportVessels: List[vessel]
    var subSupportVessels: List[vessel]
    var elecTugs: List[vessel]
    var elecSupportVessels: List[vessel]
    var arrayTemplates: Dict[Int, cableFamily]
    var vesselTemplates: Dict[String, vessel]
    var hubD: Float64
    var bladeL: Float64
    var chord: Float64
    var nacelleW: Float64
    var nacelleL: Float64
    var rnaM: Float64
    var towerD: Float64
    var towerM: Float64
    var subTotM: Float64
    var subTotCost: Float64
    var moorCost: Float64
    var systAngle: Float64
    var freeCabLeng: Float64
    var fixCabLeng: Float64
    var nExpCab: Float64
    var expCabLeng: Float64
    var expCabCost: Float64
    var nSubstation: Float64
    var cab1Leng: Float64
    var cab2Leng: Float64
    var arrCab1Cost: Float64
    var arrCab2Cost: Float64
    var subsSubM: Float64
    var subsPileM: Float64
    var subsTopM: Float64
    var totElecCost: Float64
    var moorTime: Float64
    var floatPrepTime: Float64
    var turbDeckArea: Float64
    var nTurbPerTrip: Float64
    var turbInstTime: Float64
    var subDeckArea: Float64
    var nSubPerTrip: Float64
    var subInstTime: Float64
    var arrInstTime: Float64
    var expInstTime: Float64
    var subsInstTime: Float64
    var totInstTime: Float64
    var cabSurvey: Float64
    var array_cable_install_cost: Float64
    var export_cable_install_cost: Float64
    var substation_install_cost: Float64
    var turbine_install_cost: Float64
    var substructure_install_cost: Float64
    var electrical_install_cost: Float64
    var mob_demob_cost: Float64
    var totPnSCost: Float64
    var totDevCost: Float64
    var bos_capex: Float64
    var construction_insurance_cost: Float64
    var total_contingency_cost: Float64
    var construction_finance_cost: Float64
    var construction_finance_factor: Float64
    var soft_costs: Float64
    var totAnICost: Float64
    var totEnMCost: Float64
    var commissioning: Float64
    var decomCost: Float64
    var total_bos_cost: Float64

    # private members
    var str2substructure: Dict[String, Int]
    var str2anchor: Dict[String, Int]
    var str2turbInstallMethod: Dict[String, Int]
    var str2towerInstallMethod: Dict[String, Int]
    var str2installStrategy: Dict[String, Int]
    var variable_percentage: Set[String]
    var mapVars: Dict[String, Float64]

    # constructor
    def __init__(inout self):
        self.set_templates()
        /*
        wobos_default = wind_obos_defaults();
        for (int i=0; i<wobos_default.variables.size(); i++) {
          string keyStr = wobos_default.variables[i].name;
          string valStr = wobos_default.variables[i].valueStr;
          if ( (keyStr == "anchor") || (keyStr == "turbInstallMethod") || (keyStr == "substructure") ||
               (keyStr == "towerInstallMethod") || (keyStr == "installStrategy") ||
               (keyStr == "cableOptimizer") || (keyStr == "arrayCables") || (keyStr == "exportCables") ) {
            set_map_variable(keyStr, valStr);
          }
          else if (mapVars.find(keyStr) == mapVars.end()) {
            cout << "CANNOT FIND: " << keyStr << " = " << valStr << endl;
          }
          else if (wobos_default.variables[i].isDouble()) {
            set_map_variable(keyStr, wobos_default.variables[i].value);
          }
          else {
            cout << "CANNOT SET: " << keyStr << " = " << valStr << endl;
          }
        }
        map2variables();
        */

    # public methods
    def isFixed(self) -> Bool:
        return (self.substructure == MONOPILE) or (self.substructure == JACKET)

    def isFloating(self) -> Bool:
        return (self.substructure == SPAR) or (self.substructure == SEMISUBMERSIBLE)

    def set_vessel_defaults(inout self):
        self.scourProtVessel = vessel()
        self.elecSupportVessels = List[vessel](vesselTemplates["PERSONNEL_TRANSPORT"], vesselTemplates["GUARD"])
        self.turbFeederBarge = vesselTemplates["LARGE_JACKUP_BARGE"]
        self.subFeederBarge = vesselTemplates["LARGE_JACKUP_BARGE"]
        self.arrCabInstVessel = vesselTemplates["LARGE_ARRAY_CABLE_LAY"]
        self.expCabInstVessel = vesselTemplates["LARGE_EXPORT_CABLE_LAY"]
        if self.isFixed():
            self.turbInstVessel = vesselTemplates["HIGH_HEIGHT_LARGE_SIZED_JACKUP"]
            self.subInstVessel = vesselTemplates["HIGH_HEIGHT_LARGE_SIZED_JACKUP"]
            self.substaInstVessel = vesselTemplates["SEMISUBMERSIBLE_CRANE"]
            self.turbSupportVessels = List[vessel](vesselTemplates["PERSONNEL_TRANSPORT"], vesselTemplates["GUARD"])
            self.subSupportVessels = List[vessel](vesselTemplates["PERSONNEL_TRANSPORT"], vesselTemplates["GUARD"])
            self.elecTugs = List[vessel](vesselTemplates["LARGE_AHST"])
            if self.substructure == MONOPILE:
                self.scourProtVessel = vesselTemplates["SIDE_ROCK_DUMPER"]
        elif self.substructure == SPAR:
            self.turbInstVessel = vesselTemplates["LARGE_AHST"]
            self.subInstVessel = vesselTemplates["MEDIUM_AHST"]
            self.substaInstVessel = vesselTemplates["LARGE_AHST"]
            self.turbSupportVessels = List[vessel](vesselTemplates["MEDIUM_AHST"], vesselTemplates["MEDIUM_JACKUP_BARGE"],
                                            vesselTemplates["SEA_GOING_SUPPORT_TUG"], vesselTemplates["PERSONNEL_TRANSPORT"],
                                            vesselTemplates["GUARD"], vesselTemplates["BALLASTING"], vesselTemplates["BALLAST_HOPPER"])
            self.subSupportVessels = List[vessel](vesselTemplates["MEDIUM_JACKUP_BARGE"], vesselTemplates["SEA_GOING_SUPPORT_TUG"],
                                            vesselTemplates["PERSONNEL_TRANSPORT"], vesselTemplates["GUARD"],
                                            vesselTemplates["BALLASTING"], vesselTemplates["BALLAST_HOPPER"])
            self.elecTugs = List[vessel](vesselTemplates["LARGE_AHST"], vesselTemplates["SEA_GOING_SUPPORT_TUG"])
        elif self.substructure == SEMISUBMERSIBLE:
            self.turbInstVessel = vesselTemplates["MEDIUM_AHST"]
            self.subInstVessel = vesselTemplates["MEDIUM_AHST"]
            self.substaInstVessel = vesselTemplates["LARGE_AHST"]
            self.turbSupportVessels = List[vessel](vesselTemplates["SEA_GOING_SUPPORT_TUG"], vesselTemplates["GUARD"])
            self.subSupportVessels = List[vessel](vesselTemplates["SEA_GOING_SUPPORT_TUG"], vesselTemplates["GUARD"])
            self.elecTugs = List[vessel](vesselTemplates["LARGE_AHST"], vesselTemplates["SEA_GOING_SUPPORT_TUG"])

    def map2variables(inout self):
        self.substructure = int(self.mapVars["substructure"])
        self.anchor = int(self.mapVars["anchor"])
        self.turbInstallMethod = int(self.mapVars["turbInstallMethod"])
        self.towerInstallMethod = int(self.mapVars["towerInstallMethod"])
        self.installStrategy = int(self.mapVars["installStrategy"])
        self.cableOptimizer = (self.mapVars["cableOptimizer"] == 0.0) ? False : True
        self.set_vessel_defaults()
        self.turbCapEx = self.mapVars["turbCapEx"]
        self.nTurb = self.mapVars["nTurb"]
        self.rotorD = self.mapVars["rotorD"]
        self.turbR = self.mapVars["turbR"]
        self.hubH = self.mapVars["hubH"]
        self.waterD = self.mapVars["waterD"]
        self.distShore = self.mapVars["distShore"]
        self.distPort = self.mapVars["distPort"]
        self.distPtoA = self.mapVars["distPtoA"]
        self.distAtoS = self.mapVars["distAtoS"]
        self.moorLines = self.mapVars["moorLines"]
        self.buryDepth = self.mapVars["buryDepth"]
        self.arrayY = self.mapVars["arrayY"]
        self.arrayX = self.mapVars["arrayX"]
        self.substructCont = self.mapVars["substructCont"]
        self.turbCont = self.mapVars["turbCont"]
        self.elecCont = self.mapVars["elecCont"]
        self.interConVolt = self.mapVars["interConVolt"]
        self.distInterCon = self.mapVars["distInterCon"]
        self.scrapVal = self.mapVars["scrapVal"]
        self.number_install_seasons = self.mapVars["number_install_seasons"]
        self.projLife = self.mapVars["projLife"]
        self.inspectClear = self.mapVars["inspectClear"]
        self.plantComm = self.mapVars["plantComm"]
        self.procurement_contingency = self.mapVars["procurement_contingency"]
        self.install_contingency = self.mapVars["install_contingency"]
        self.construction_insurance = self.mapVars["construction_insurance"]
        self.capital_cost_year_0 = self.mapVars["capital_cost_year_0"]
        self.capital_cost_year_1 = self.mapVars["capital_cost_year_1"]
        self.capital_cost_year_2 = self.mapVars["capital_cost_year_2"]
        self.capital_cost_year_3 = self.mapVars["capital_cost_year_3"]
        self.capital_cost_year_4 = self.mapVars["capital_cost_year_4"]
        self.capital_cost_year_5 = self.mapVars["capital_cost_year_5"]
        self.tax_rate = self.mapVars["tax_rate"]
        self.interest_during_construction = self.mapVars["interest_during_construction"]
        self.mpileCR = self.mapVars["mpileCR"]
        self.mtransCR = self.mapVars["mtransCR"]
        self.mpileD = self.mapVars["mpileD"]
        self.mpileL = self.mapVars["mpileL"]
        self.jlatticeCR = self.mapVars["jlatticeCR"]
        self.jtransCR = self.mapVars["jtransCR"]
        self.jpileCR = self.mapVars["jpileCR"]
        self.jlatticeA = self.mapVars["jlatticeA"]
        self.jpileL = self.mapVars["jpileL"]
        self.jpileD = self.mapVars["jpileD"]
        self.spStifColCR = self.mapVars["spStifColCR"]
        self.spTapColCR = self.mapVars["spTapColCR"]
        self.ballCR = self.mapVars["ballCR"]
        self.deaFixLeng = self.mapVars["deaFixLeng"]
        self.ssStifColCR = self.mapVars["ssStifColCR"]
        self.ssTrussCR = self.mapVars["ssTrussCR"]
        self.ssHeaveCR = self.mapVars["ssHeaveCR"]
        self.sSteelCR = self.mapVars["sSteelCR"]
        self.moorDia = self.mapVars["moorDia"]
        self.moorCR = self.mapVars["moorCR"]
        self.mpEmbedL = self.mapVars["mpEmbedL"]
        self.scourMat = self.mapVars["scourMat"]
        self.pwrFac = self.mapVars["pwrFac"]
        self.buryFac = self.mapVars["buryFac"]
        self.arrVoltage = self.mapVars["arrVoltage"]
        self.arrCab1Size = self.mapVars["arrCab1Size"]
        self.arrCab1Mass = self.mapVars["arrCab1Mass"]
        self.cab1CurrRating = self.mapVars["cab1CurrRating"]
        self.cab1CR = self.mapVars["cab1CR"]
        self.cab1TurbInterCR = self.mapVars["cab1TurbInterCR"]
        self.arrCab2Size = self.mapVars["arrCab2Size"]
        self.arrCab2Mass = self.mapVars["arrCab2Mass"]
        self.cab2CurrRating = self.mapVars["cab2CurrRating"]
        self.cab2CR = self.mapVars["cab2CR"]
        self.cab2TurbInterCR = self.mapVars["cab2TurbInterCR"]
        self.cab2SubsInterCR = self.mapVars["cab2SubsInterCR"]
        self.catLengFac = self.mapVars["catLengFac"]
        self.exCabFac = self.mapVars["exCabFac"]
        self.subsTopFab = self.mapVars["subsTopFab"]
        self.subsTopDes = self.mapVars["subsTopDes"]
        self.topAssemblyFac = self.mapVars["topAssemblyFac"]
        self.subsJackCR = self.mapVars["subsJackCR"]
        self.subsPileCR = self.mapVars["subsPileCR"]
        self.dynCabFac = self.mapVars["dynCabFac"]
        self.shuntCR = self.mapVars["shuntCR"]
        self.highVoltSG = self.mapVars["highVoltSG"]
        self.medVoltSG = self.mapVars["medVoltSG"]
        self.backUpGen = self.mapVars["backUpGen"]
        self.workSpace = self.mapVars["workSpace"]
        self.otherAncillary = self.mapVars["otherAncillary"]
        self.mptCR = self.mapVars["mptCR"]
        self.expVoltage = self.mapVars["expVoltage"]
        self.expCabSize = self.mapVars["expCabSize"]
        self.expCabMass = self.mapVars["expCabMass"]
        self.expCabCR = self.mapVars["expCabCR"]
        self.expCurrRating = self.mapVars["expCurrRating"]
        self.expSubsInterCR = self.mapVars["expSubsInterCR"]
        self.moorTimeFac = self.mapVars["moorTimeFac"]
        self.moorLoadout = self.mapVars["moorLoadout"]
        self.moorSurvey = self.mapVars["moorSurvey"]
        self.prepAA = self.mapVars["prepAA"]
        self.prepSpar = self.mapVars["prepSpar"]
        self.upendSpar = self.mapVars["upendSpar"]
        self.prepSemi = self.mapVars["prepSemi"]
        self.turbFasten = self.mapVars["turbFasten"]
        self.boltTower = self.mapVars["boltTower"]
        self.boltNacelle1 = self.mapVars["boltNacelle1"]
        self.boltNacelle2 = self.mapVars["boltNacelle2"]
        self.boltNacelle3 = self.mapVars["boltNacelle3"]
        self.boltBlade1 = self.mapVars["boltBlade1"]
        self.boltBlade2 = self.mapVars["boltBlade2"]
        self.boltRotor = self.mapVars["boltRotor"]
        self.vesselPosTurb = self.mapVars["vesselPosTurb"]
        self.vesselPosJack = self.mapVars["vesselPosJack"]
        self.vesselPosMono = self.mapVars["vesselPosMono"]
        self.subsVessPos = self.mapVars["subsVessPos"]
        self.monoFasten = self.mapVars["monoFasten"]
        self.jackFasten = self.mapVars["jackFasten"]
        self.prepGripperMono = self.mapVars["prepGripperMono"]
        self.prepGripperJack = self.mapVars["prepGripperJack"]
        self.placePiles = self.mapVars["placePiles"]
        self.prepHamMono = self.mapVars["prepHamMono"]
        self.removeHamMono = self.mapVars["removeHamMono"]
        self.prepHamJack = self.mapVars["prepHamJack"]
        self.removeHamJack = self.mapVars["removeHamJack"]
        self.placeJack = self.mapVars["placeJack"]
        self.levJack = self.mapVars["levJack"]
        self.placeTemplate = self.mapVars["placeTemplate"]
        self.hamRate = self.mapVars["hamRate"]
        self.placeMP = self.mapVars["placeMP"]
        self.instScour = self.mapVars["instScour"]
        self.placeTP = self.mapVars["placeTP"]
        self.groutTP = self.mapVars["groutTP"]
        self.tpCover = self.mapVars["tpCover"]
        self.prepTow = self.mapVars["prepTow"]
        self.spMoorCon = self.mapVars["spMoorCon"]
        self.ssMoorCon = self.mapVars["ssMoorCon"]
        self.spMoorCheck = self.mapVars["spMoorCheck"]
        self.ssMoorCheck = self.mapVars["ssMoorCheck"]
        self.ssBall = self.mapVars["ssBall"]
        self.surfLayRate = self.mapVars["surfLayRate"]
        self.cabPullIn = self.mapVars["cabPullIn"]
        self.cabTerm = self.mapVars["cabTerm"]
        self.cabLoadout = self.mapVars["cabLoadout"]
        self.buryRate = self.mapVars["buryRate"]
        self.subsPullIn = self.mapVars["subsPullIn"]
        self.shorePullIn = self.mapVars["shorePullIn"]
        self.landConstruct = self.mapVars["landConstruct"]
        self.expCabLoad = self.mapVars["expCabLoad"]
        self.subsLoad = self.mapVars["subsLoad"]
        self.placeTop = self.mapVars["placeTop"]
        self.pileSpreadDR = self.mapVars["pileSpreadDR"]
        self.pileSpreadMob = self.mapVars["pileSpreadMob"]
        self.groutSpreadDR = self.mapVars["groutSpreadDR"]
        self.groutSpreadMob = self.mapVars["groutSpreadMob"]
        self.seaSpreadDR = self.mapVars["seaSpreadDR"]
        self.seaSpreadMob = self.mapVars["seaSpreadMob"]
        self.compRacks = self.mapVars["compRacks"]
        self.cabSurveyCR = self.mapVars["cabSurveyCR"]
        self.cabDrillDist = self.mapVars["cabDrillDist"]
        self.cabDrillCR = self.mapVars["cabDrillCR"]
        self.mpvRentalDR = self.mapVars["mpvRentalDR"]
        self.diveTeamDR = self.mapVars["diveTeamDR"]
        self.winchDR = self.mapVars["winchDR"]
        self.civilWork = self.mapVars["civilWork"]
        self.elecWork = self.mapVars["elecWork"]
        self.nCrane600 = self.mapVars["nCrane600"]
        self.nCrane1000 = self.mapVars["nCrane1000"]
        self.crane600DR = self.mapVars["crane600DR"]
        self.crane1000DR = self.mapVars["crane1000DR"]
        self.craneMobDemob = self.mapVars["craneMobDemob"]
        self.entranceExitRate = self.mapVars["entranceExitRate"]
        self.dockRate = self.mapVars["dockRate"]
        self.wharfRate = self.mapVars["wharfRate"]
        self.laydownCR = self.mapVars["laydownCR"]
        self.estEnMFac = self.mapVars["estEnMFac"]
        self.preFEEDStudy = self.mapVars["preFEEDStudy"]
        self.feedStudy = self.mapVars["feedStudy"]
        self.stateLease = self.mapVars["stateLease"]
        self.outConShelfLease = self.mapVars["outConShelfLease"]
        self.saPlan = self.mapVars["saPlan"]
        self.conOpPlan = self.mapVars["conOpPlan"]
        self.nepaEisMet = self.mapVars["nepaEisMet"]
        self.physResStudyMet = self.mapVars["physResStudyMet"]
        self.bioResStudyMet = self.mapVars["bioResStudyMet"]
        self.socEconStudyMet = self.mapVars["socEconStudyMet"]
        self.navStudyMet = self.mapVars["navStudyMet"]
        self.nepaEisProj = self.mapVars["nepaEisProj"]
        self.physResStudyProj = self.mapVars["physResStudyProj"]
        self.bioResStudyProj = self.mapVars["bioResStudyProj"]
        self.socEconStudyProj = self.mapVars["socEconStudyProj"]
        self.navStudyProj = self.mapVars["navStudyProj"]
        self.coastZoneManAct = self.mapVars["coastZoneManAct"]
        self.rivsnHarbsAct = self.mapVars["rivsnHarbsAct"]
        self.cleanWatAct402 = self.mapVars["cleanWatAct402"]
        self.cleanWatAct404 = self.mapVars["cleanWatAct404"]
        self.faaPlan = self.mapVars["faaPlan"]
        self.endSpecAct = self.mapVars["endSpecAct"]
        self.marMamProtAct = self.mapVars["marMamProtAct"]
        self.migBirdAct = self.mapVars["migBirdAct"]
        self.natHisPresAct = self.mapVars["natHisPresAct"]
        self.addLocPerm = self.mapVars["addLocPerm"]
        self.metTowCR = self.mapVars["metTowCR"]
        self.decomDiscRate = self.mapVars["decomDiscRate"]
        self.hubD = self.mapVars["hubD"]
        self.bladeL = self.mapVars["bladeL"]
        self.chord = self.mapVars["chord"]
        self.nacelleW = self.mapVars["nacelleW"]
        self.nacelleL = self.mapVars["nacelleL"]
        self.rnaM = self.mapVars["rnaM"]
        self.towerD = self.mapVars["towerD"]
        self.towerM = self.mapVars["towerM"]
        self.subTotM = self.mapVars["subTotM"]
        self.subTotCost = self.mapVars["subTotCost"]
        self.moorCost = self.mapVars["moorCost"]
        self.systAngle = self.mapVars["systAngle"]
        self.freeCabLeng = self.mapVars["freeCabLeng"]
        self.fixCabLeng = self.mapVars["fixCabLeng"]
        self.nExpCab = self.mapVars["nExpCab"]
        self.expCabLeng = self.mapVars["expCabLeng"]
        self.expCabCost = self.mapVars["expCabCost"]
        self.nSubstation = self.mapVars["nSubstation"]
        self.cab1Leng = self.mapVars["cab1Leng"]
        self.cab2Leng = self.mapVars["cab2Leng"]
        self.arrCab1Cost = self.mapVars["arrCab1Cost"]
        self.arrCab2Cost = self.mapVars["arrCab2Cost"]
        self.subsSubM = self.mapVars["subsSubM"]
        self.subsPileM = self.mapVars["subsPileM"]
        self.subsTopM = self.mapVars["subsTopM"]
        self.totElecCost = self.mapVars["totElecCost"]
        self.moorTime = self.mapVars["moorTime"]
        self.floatPrepTime = self.mapVars["floatPrepTime"]
        self.turbDeckArea = self.mapVars["turbDeckArea"]
        self.nTurbPerTrip = self.mapVars["nTurbPerTrip"]
        self.turbInstTime = self.mapVars["turbInstTime"]
        self.subDeckArea = self.mapVars["subDeckArea"]
        self.nSubPerTrip = self.mapVars["nSubPerTrip"]
        self.subInstTime = self.mapVars["subInstTime"]
        self.arrInstTime = self.mapVars["arrInstTime"]
        self.expInstTime = self.mapVars["expInstTime"]
        self.subsInstTime = self.mapVars["subsInstTime"]
        self.totInstTime = self.mapVars["totInstTime"]
        self.cabSurvey = self.mapVars["cabSurvey"]
        self.array_cable_install_cost = self.mapVars["array_cable_install_cost"]
        self.export_cable_install_cost = self.mapVars["export_cable_install_cost"]
        self.substation_install_cost = self.mapVars["substation_install_cost"]
        self.turbine_install_cost = self.mapVars["turbine_install_cost"]
        self.substructure_install_cost = self.mapVars["substructure_install_cost"]
        self.electrical_install_cost = self.mapVars["electrical_install_cost"]
        self.mob_demob_cost = self.mapVars["mob_demob_cost"]
        self.totPnSCost = self.mapVars["totPnSCost"]
        self.totDevCost = self.mapVars["totDevCost"]
        self.bos_capex = self.mapVars["bos_capex"]
        self.construction_insurance_cost = self.mapVars["construction_insurance_cost"]
        self.total_contingency_cost = self.mapVars["total_contingency_cost"]
        self.construction_finance_cost = self.mapVars["construction_finance_cost"]
        self.construction_finance_factor = self.mapVars["construction_finance_factor"]
        self.soft_costs = self.mapVars["soft_costs"]
        self.totAnICost = self.mapVars["totAnICost"]
        self.totEnMCost = self.mapVars["totEnMCost"]
        self.commissioning = self.mapVars["commissioning"]
        self.decomCost = self.mapVars["decomCost"]
        self.total_bos_cost = self.mapVars["total_bos_cost"]

    def variables2map(inout self):
        self.mapVars["substructure"] = Float64(self.substructure)
        self.mapVars["anchor"] = Float64(self.anchor)
        self.mapVars["turbInstallMethod"] = Float64(self.turbInstallMethod)
        self.mapVars["towerInstallMethod"] = Float64(self.towerInstallMethod)
        self.mapVars["installStrategy"] = Float64(self.installStrategy)
        self.mapVars["cableOptimizer"] = 1.0 if self.cableOptimizer else 0.0
        self.mapVars["turbCapEx"] = self.turbCapEx
        self.mapVars["nTurb"] = self.nTurb
        self.mapVars["rotorD"] = self.rotorD
        self.mapVars["turbR"] = self.turbR
        self.mapVars["hubH"] = self.hubH
        self.mapVars["waterD"] = self.waterD
        self.mapVars["distShore"] = self.distShore
        self.mapVars["distPort"] = self.distPort
        self.mapVars["distPtoA"] = self.distPtoA
        self.mapVars["distAtoS"] = self.distAtoS
        self.mapVars["moorLines"] = self.moorLines
        self.mapVars["buryDepth"] = self.buryDepth
        self.mapVars["arrayY"] = self.arrayY
        self.mapVars["arrayX"] = self.arrayX
        self.mapVars["substructCont"] = self.substructCont
        self.mapVars["turbCont"] = self.turbCont
        self.mapVars["elecCont"] = self.elecCont
        self.mapVars["interConVolt"] = self.interConVolt
        self.mapVars["distInterCon"] = self.distInterCon
        self.mapVars["scrapVal"] = self.scrapVal
        self.mapVars["number_install_seasons"] = self.number_install_seasons
        self.mapVars["projLife"] = self.projLife
        self.mapVars["inspectClear"] = self.inspectClear
        self.mapVars["plantComm"] = self.plantComm
        self.mapVars["procurement_contingency"] = self.procurement_contingency
        self.mapVars["install_contingency"] = self.install_contingency
        self.mapVars["construction_insurance"] = self.construction_insurance
        self.mapVars["capital_cost_year_0"] = self.capital_cost_year_0
        self.mapVars["capital_cost_year_1"] = self.capital_cost_year_1
        self.mapVars["capital_cost_year_2"] = self.capital_cost_year_2
        self.mapVars["capital_cost_year_3"] = self.capital_cost_year_3
        self.mapVars["capital_cost_year_4"] = self.capital_cost_year_4
        self.mapVars["capital_cost_year_5"] = self.capital_cost_year_5
        self.mapVars["tax_rate"] = self.tax_rate
        self.mapVars["interest_during_construction"] = self.interest_during_construction
        self.mapVars["mpileCR"] = self.mpileCR
        self.mapVars["mtransCR"] = self.mtransCR
        self.mapVars["mpileD"] = self.mpileD
        self.mapVars["mpileL"] = self.mpileL
        self.mapVars["jlatticeCR"] = self.jlatticeCR
        self.mapVars["jtransCR"] = self.jtransCR
        self.mapVars["jpileCR"] = self.jpileCR
        self.mapVars["jlatticeA"] = self.jlatticeA
        self.mapVars["jpileL"] = self.jpileL
        self.mapVars["jpileD"] = self.jpileD
        self.mapVars["spStifColCR"] = self.spStifColCR
        self.mapVars["spTapColCR"] = self.spTapColCR
        self.mapVars["ballCR"] = self.ballCR
        self.mapVars["deaFixLeng"] = self.deaFixLeng
        self.mapVars["ssStifColCR"] = self.ssStifColCR
        self.mapVars["ssTrussCR"] = self.ssTrussCR
        self.mapVars["ssHeaveCR"] = self.ssHeaveCR
        self.mapVars["sSteelCR"] = self.sSteelCR
        self.mapVars["moorDia"] = self.moorDia
        self.mapVars["moorCR"] = self.moorCR
        self.mapVars["mpEmbedL"] = self.mpEmbedL
        self.mapVars["scourMat"] = self.scourMat
        self.mapVars["pwrFac"] = self.pwrFac
        self.mapVars["buryFac"] = self.buryFac
        self.mapVars["arrVoltage"] = self.arrVoltage
        self.mapVars["arrCab1Size"] = self.arrCab1Size
        self.mapVars["arrCab1Mass"] = self.arrCab1Mass
        self.mapVars["cab1CurrRating"] = self.cab1CurrRating
        self.mapVars["cab1CR"] = self.cab1CR
        self.mapVars["cab1TurbInterCR"] = self.cab1TurbInterCR
        self.mapVars["arrCab2Size"] = self.arrCab2Size
        self.mapVars["arrCab2Mass"] = self.arrCab2Mass
        self.mapVars["cab2CurrRating"] = self.cab2CurrRating
        self.mapVars["cab2CR"] = self.cab2CR
        self.mapVars["cab2TurbInterCR"] = self.cab2TurbInterCR
        self.mapVars["cab2SubsInterCR"] = self.cab2SubsInterCR
        self.mapVars["catLengFac"] = self.catLengFac
        self.mapVars["exCabFac"] = self.exCabFac
        self.mapVars["subsTopFab"] = self.subsTopFab
        self.mapVars["subsTopDes"] = self.subsTopDes
        self.mapVars["topAssemblyFac"] = self.topAssemblyFac
        self.mapVars["subsJackCR"] = self.subsJackCR
        self.mapVars["subsPileCR"] = self.subsPileCR
        self.mapVars["dynCabFac"] = self.dynCabFac
        self.mapVars["shuntCR"] = self.shuntCR
        self.mapVars["highVoltSG"] = self.highVoltSG
        self.mapVars["medVoltSG"] = self.medVoltSG
        self.mapVars["backUpGen"] = self.backUpGen
        self.mapVars["workSpace"] = self.workSpace
        self.mapVars["otherAncillary"] = self.otherAncillary
        self.mapVars["mptCR"] = self.mptCR
        self.mapVars["expVoltage"] = self.expVoltage
        self.mapVars["expCabSize"] = self.expCabSize
        self.mapVars["expCabMass"] = self.expCabMass
        self.mapVars["expCabCR"] = self.expCabCR
        self.mapVars["expCurrRating"] = self.expCurrRating
        self.mapVars["expSubsInterCR"] = self.expSubsInterCR
        self.mapVars["moorTimeFac"] = self.moorTimeFac
        self.mapVars["moorLoadout"] = self.moorLoadout
        self.mapVars["moorSurvey"] = self.moorSurvey
        self.mapVars["prepAA"] = self.prepAA
        self.mapVars["prepSpar"] = self.prepSpar
        self.mapVars["upendSpar"] = self.upendSpar
        self.mapVars["prepSemi"] = self.prepSemi
        self.mapVars["turbFasten"] = self.turbFasten
        self.mapVars["boltTower"] = self.boltTower
        self.mapVars["boltNacelle1"] = self.boltNacelle1
        self.mapVars["boltNacelle2"] = self.boltNacelle2
        self.mapVars["boltNacelle3"] = self.boltNacelle3
        self.mapVars["boltBlade1"] = self.boltBlade1
        self.mapVars["boltBlade2"] = self.boltBlade2
        self.mapVars["boltRotor"] = self.boltRotor
        self.mapVars["vesselPosTurb"] = self.vesselPosTurb
        self.mapVars["vesselPosJack"] = self.vesselPosJack
        self.mapVars["vesselPosMono"] = self.vesselPosMono
        self.mapVars["subsVessPos"] = self.subsVessPos
        self.mapVars["monoFasten"] = self.monoFasten
        self.mapVars["jackFasten"] = self.jackFasten
        self.mapVars["prepGripperMono"] = self.prepGripperMono
        self.mapVars["prepGripperJack"] = self.prepGripperJack
        self.mapVars["placePiles"] = self.placePiles
        self.mapVars["prepHamMono"] = self.prepHamMono
        self.mapVars["removeHamMono"] = self.removeHamMono
        self.mapVars["prepHamJack"] = self.prepHamJack
        self.mapVars["removeHamJack"] = self.removeHamJack
        self.mapVars["placeJack"] = self.placeJack
        self.mapVars["levJack"] = self.levJack
        self.mapVars["placeTemplate"] = self.placeTemplate
        self.mapVars["hamRate"] = self.hamRate
        self.mapVars["placeMP"] = self.placeMP
        self.mapVars["instScour"] = self.instScour
        self.mapVars["placeTP"] = self.placeTP
        self.mapVars["groutTP"] = self.groutTP
        self.mapVars["tpCover"] = self.tpCover
        self.mapVars["prepTow"] = self.prepTow
        self.mapVars["spMoorCon"] = self.spMoorCon
        self.mapVars["ssMoorCon"] = self.ssMoorCon
        self.mapVars["spMoorCheck"] = self.spMoorCheck
        self.mapVars["ssMoorCheck"] = self.ssMoorCheck
        self.mapVars["ssBall"] = self.ssBall
        self.mapVars["surfLayRate"] = self.surfLayRate
        self.mapVars["cabPullIn"] = self.cabPullIn
        self.mapVars["cabTerm"] = self.cabTerm
        self.mapVars["cabLoadout"] = self.cabLoadout
        self.mapVars["buryRate"] = self.buryRate
        self.mapVars["subsPullIn"] = self.subsPullIn
        self.mapVars["shorePullIn"] = self.shorePullIn
        self.mapVars["landConstruct"] = self.landConstruct
        self.mapVars["expCabLoad"] = self.expCabLoad
        self.mapVars["subsLoad"] = self.subsLoad
        self.mapVars["placeTop"] = self.placeTop
        self.mapVars["pileSpreadDR"] = self.pileSpreadDR
        self.mapVars["pileSpreadMob"] = self.pileSpreadMob
        self.mapVars["groutSpreadDR"] = self.groutSpreadDR
        self.mapVars["groutSpreadMob"] = self.groutSpreadMob
        self.mapVars["seaSpreadDR"] = self.seaSpreadDR
        self.mapVars["seaSpreadMob"] = self.seaSpreadMob
        self.mapVars["compRacks"] = self.compRacks
        self.mapVars["cabSurveyCR"] = self.cabSurveyCR
        self.mapVars["cabDrillDist"] = self.cabDrillDist
        self.mapVars["cabDrillCR"] = self.cabDrillCR
        self.mapVars["mpvRentalDR"] = self.mpvRentalDR
        self.mapVars["diveTeamDR"] = self.diveTeamDR
        self.mapVars["winchDR"] = self.winchDR
        self.mapVars["civilWork"] = self.civilWork
        self.mapVars["elecWork"] = self.elecWork
        self.mapVars["nCrane600"] = self.nCrane600
        self.mapVars["nCrane1000"] = self.nCrane1000
        self.mapVars["crane600DR"] = self.crane600DR
        self.mapVars["crane1000DR"] = self.crane1000DR
        self.mapVars["craneMobDemob"] = self.craneMobDemob
        self.mapVars["entranceExitRate"] = self.entranceExitRate
        self.mapVars["dockRate"] = self.dockRate
        self.mapVars["wharfRate"] = self.wharfRate
        self.mapVars["laydownCR"] = self.laydownCR
        self.mapVars["estEnMFac"] = self.estEnMFac
        self.mapVars["preFEEDStudy"] = self.preFEEDStudy
        self.mapVars["feedStudy"] = self.feedStudy
        self.mapVars["stateLease"] = self.stateLease
        self.mapVars["outConShelfLease"] = self.outConShelfLease
        self.mapVars["saPlan"] = self.saPlan
        self.mapVars["conOpPlan"] = self.conOpPlan
        self.mapVars["nepaEisMet"] = self.nepaEisMet
        self.mapVars["physResStudyMet"] = self.physResStudyMet
        self.mapVars["bioResStudyMet"] = self.bioResStudyMet
        self.mapVars["socEconStudyMet"] = self.socEconStudyMet
        self.mapVars["navStudyMet"] = self.navStudyMet
        self.mapVars["nepaEisProj"] = self.nepaEisProj
        self.mapVars["physResStudyProj"] = self.physResStudyProj
        self.mapVars["bioResStudyProj"] = self.bioResStudyProj
        self.mapVars["socEconStudyProj"] = self.socEconStudyProj
        self.mapVars["navStudyProj"] = self.navStudyProj
        self.mapVars["coastZoneManAct"] = self.coastZoneManAct
        self.mapVars["rivsnHarbsAct"] = self.rivsnHarbsAct
        self.mapVars["cleanWatAct402"] = self.cleanWatAct402
        self.mapVars["cleanWatAct404"] = self.cleanWatAct404
        self.mapVars["faaPlan"] = self.faaPlan
        self.mapVars["endSpecAct"] = self.endSpecAct
        self.mapVars["marMamProtAct"] = self.marMamProtAct
        self.mapVars["migBirdAct"] = self.migBirdAct
        self.mapVars["natHisPresAct"] = self.natHisPresAct
        self.mapVars["addLocPerm"] = self.addLocPerm
        self.mapVars["metTowCR"] = self.metTowCR
        self.mapVars["decomDiscRate"] = self.decomDiscRate
        self.mapVars["hubD"] = self.hubD
        self.mapVars["bladeL"] = self.bladeL
        self.mapVars["chord"] = self.chord
        self.mapVars["nacelleW"] = self.nacelleW
        self.mapVars["nacelleL"] = self.nacelleL
        self.mapVars["rnaM"] = self.rnaM
        self.mapVars["towerD"] = self.towerD
        self.mapVars["towerM"] = self.towerM
        self.mapVars["subTotM"] = self.subTotM
        self.mapVars["subTotCost"] = self.subTotCost
        self.mapVars["moorCost"] = self.moorCost
        self.mapVars["systAngle"] = self.systAngle
        self.mapVars["freeCabLeng"] = self.freeCabLeng
        self.mapVars["fixCabLeng"] = self.fixCabLeng
        self.mapVars["nExpCab"] = self.nExpCab
        self.mapVars["expCabLeng"] = self.expCabLeng
        self.mapVars["expCabCost"] = self.expCabCost
        self.mapVars["nSubstation"] = self.nSubstation
        self.mapVars["cab1Leng"] = self.cab1Leng
        self.mapVars["cab2Leng"] = self.cab2Leng
        self.mapVars["arrCab1Cost"] = self.arrCab1Cost
        self.mapVars["arrCab2Cost"] = self.arrCab2Cost
        self.mapVars["subsSubM"] = self.subsSubM
        self.mapVars["subsPileM"] = self.subsPileM
        self.mapVars["subsTopM"] = self.subsTopM
        self.mapVars["totElecCost"] = self.totElecCost
        self.mapVars["moorTime"] = self.moorTime
        self.mapVars["floatPrepTime"] = self.floatPrepTime
        self.mapVars["turbDeckArea"] = self.turbDeckArea
        self.mapVars["nTurbPerTrip"] = self.nTurbPerTrip
        self.mapVars["turbInstTime"] = self.turbInstTime
        self.mapVars["subDeckArea"] = self.subDeckArea
        self.mapVars["nSubPerTrip"] = self.nSubPerTrip
        self.mapVars["subInstTime"] = self.subInstTime
        self.mapVars["arrInstTime"] = self.arrInstTime
        self.mapVars["expInstTime"] = self.expInstTime
        self.mapVars["subsInstTime"] = self.subsInstTime
        self.mapVars["totInstTime"] = self.totInstTime
        self.mapVars["cabSurvey"] = self.cabSurvey
        self.mapVars["array_cable_install_cost"] = self.array_cable_install_cost
        self.mapVars["export_cable_install_cost"] = self.export_cable_install_cost
        self.mapVars["substation_install_cost"] = self.substation_install_cost
        self.mapVars["turbine_install_cost"] = self.turbine_install_cost
        self.mapVars["substructure_install_cost"] = self.substructure_install_cost
        self.mapVars["electrical_install_cost"] = self.electrical_install_cost
        self.mapVars["mob_demob_cost"] = self.mob_demob_cost
        self.mapVars["totPnSCost"] = self.totPnSCost
        self.mapVars["totDevCost"] = self.totDevCost
        self.mapVars["bos_capex"] = self.bos_capex
        self.mapVars["construction_insurance_cost"] = self.construction_insurance_cost
        self.mapVars["total_contingency_cost"] = self.total_contingency_cost
        self.mapVars["construction_finance_cost"] = self.construction_finance_cost
        self.mapVars["construction_finance_factor"] = self.construction_finance_factor
        self.mapVars["soft_costs"] = self.soft_costs
        self.mapVars["totAnICost"] = self.totAnICost
        self.mapVars["totEnMCost"] = self.totEnMCost
        self.mapVars["commissioning"] = self.commissioning
        self.mapVars["decomCost"] = self.decomCost
        self.mapVars["total_bos_cost"] = self.total_bos_cost

    def set_map_variable(inout self, keyStr: String, valStr: String):
        if keyStr == "substructure":
            self.substructure = self.str2substructure[valStr]
            self.mapVars[keyStr] = Float64(self.substructure)
            self.set_vessel_defaults()
        elif keyStr == "anchor":
            self.anchor = self.str2anchor[valStr]
            self.mapVars[keyStr] = Float64(self.anchor)
        elif keyStr == "turbInstallMethod":
            self.turbInstallMethod = self.str2turbInstallMethod[valStr]
            self.mapVars[keyStr] = Float64(self.turbInstallMethod)
        elif keyStr == "towerInstallMethod":
            self.towerInstallMethod = self.str2towerInstallMethod[valStr]
            self.mapVars[keyStr] = Float64(self.towerInstallMethod)
        elif keyStr == "installStrategy":
            self.installStrategy = self.str2installStrategy[valStr]
            self.mapVars[keyStr] = Float64(self.installStrategy)
        elif keyStr == "cableOptimizer":
            self.cableOptimizer = (valStr == "FALSE") or (valStr == "0") ? False : True
            self.mapVars[keyStr] = 1.0 if self.cableOptimizer else 0.0
        elif (keyStr == "arrayCables") or (keyStr == "exportCables"):
            var cableVoltages: List[Int] = List[Int]()
            # Simulate stringstream parsing: split by spaces
            var parts = valStr.split(" ")
            for p in parts:
                if len(p) > 0:
                    cableVoltages.append(int(p))
            if keyStr == "arrayCables":
                self.arrCables = self.set_cables(cableVoltages)
            else:
                self.expCables = self.set_cables(cableVoltages)

    def set_map_variable(inout self, keyStr: String, val: Float64):
        if (val > 1.0) and (self.variable_percentage.contains(keyStr)):
            val *= 1e-2
        self.mapVars[keyStr] = val

    def set_map_variable(inout self, key: String, val: Float64):
        self.set_map_variable(key, val)

    def get_map_variable(self, key: String) -> Float64:
        return self.mapVars[key]

    # private methods (called internally)
    def set_templates(inout self):
        var arrayCable33kV = cableFamily()
        arrayCable33kV.set_all_area(List[Float64](95.0,   120.0,  150.0,  185.0,  240.0,  300.0,  400.0,  500.0,  630.0,  800.0,  1000.0))
        arrayCable33kV.set_all_mass(List[Float64](20.384, 21.854, 23.912, 25.676, 28.910, 32.242, 37.142, 42.336, 48.706, 57.428, 66.738))
        arrayCable33kV.set_all_cost(List[Float64](185.889, 202.788, 208.421, 236.586, 270.384, 315.448, 360.512, 422.475, 478.805, 585.832, 698.492))
        arrayCable33kV.set_all_current_rating(List[Float64](300.0,  340.0,  375.0,  420.0,  480.0,  530.0,  590.0,  655.0,  715.0,  775.0,  825.0))
        arrayCable33kV.set_all_turbine_interface_cost(List[Float64](8410., 8615., 8861., 9149., 9600., 10092., 10913., 11733., 12800., 14195., 15836.))
        arrayCable33kV.set_all_substation_interface_cost(List[Float64](19610., 19815., 20062., 20349., 20800., 21292., 22113., 22933., 24000., 25395., 27036.))
        arrayCable33kV.set_voltage(33.0)
        self.arrayTemplates.insert(33, arrayCable33kV)

        var arrayCable66kV = cableFamily()
        arrayCable66kV.set_all_area(List[Float64](95.0,   120.0,  150.0,  185.0,  240.0,  300.0,  400.0,  500.0,  630.0,  800.0,  1000.0))
        arrayCable66kV.set_all_mass(List[Float64](21.6, 23.8, 25.7, 28.0, 31.
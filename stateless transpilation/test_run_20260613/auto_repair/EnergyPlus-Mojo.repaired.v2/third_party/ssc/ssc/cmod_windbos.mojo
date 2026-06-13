"""
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
"""
from core import *

var _cm_vtab_windbos: StaticArray[var_info] = StaticArray[
/*   VARTYPE           DATATYPE         NAME                              LABEL                                                      UNITS     META                      GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	var_info(SSC_INPUT,        SSC_NUMBER,      "machine_rating",                "Machine Rating",                                          "kW",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "rotor_diameter",                "Rotor Diameter",                                          "m",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "hub_height",                    "Hub Height",                                              "m",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "number_of_turbines",            "Number of Turbines",                                      "",       "",                      "wind_bos",      "*",                       "INTEGER",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "interconnect_voltage",          "Interconnect Voltage",                                    "kV",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "distance_to_interconnect",      "Distance to Interconnect",                                "miles",  "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "site_terrain",                  "Site Terrain",                                            "",       "",                      "wind_bos",      "*",                       "INTEGER",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "turbine_layout",                "Turbine Layout",                                          "",       "",                      "wind_bos",      "*",                       "INTEGER",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "soil_condition",                "Soil Condition",                                          "",       "",                      "wind_bos",      "*",                       "INTEGER",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "construction_time",             "Construction Time",                                       "months", "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "om_building_size",              "O&M Building Size",                                       "ft^2",   "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "quantity_test_met_towers",      "Quantity of Temporary Meteorological Towers for Testing", "",       "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "quantity_permanent_met_towers", "Quantity of Permanent Meteorological Towers for Testing", "",       "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "weather_delay_days",            "Wind / Weather delay days",                               "",       "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "crane_breakdowns",              "Crane breakdowns",                                        "",       "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "access_road_entrances",         "Access road entrances",                                   "",       "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "turbine_capital_cost",          "Turbine Capital Cost",                                    "$/kW",   "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "tower_top_mass",                "Tower Top Mass",                                          "Tonnes", "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "delivery_assist_required",      "Delivery Assist Required",                                "y/n",    "",                      "wind_bos",      "*",                       "INTEGER",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "pad_mount_transformer_required","Pad mount Transformer required",                          "y/n",    "",                      "wind_bos",      "*",                       "INTEGER",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "new_switchyard_required",       "New Switchyard Required",                                 "y/n",    "",                      "wind_bos",      "*",                       "INTEGER",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "rock_trenching_required",       "Rock trenching required",                                 "%",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "mv_thermal_backfill",           "MV thermal backfill",                                     "mi",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "mv_overhead_collector",         "MV overhead collector",                                   "mi",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "performance_bond",              "Performance bond",                                        "%",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "contingency",                   "Contingency",                                             "%",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "warranty_management",           "Warranty management",                                     "%",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "sales_and_use_tax",             "Sales and Use Tax",                                       "%",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "overhead",                      "Overhead",                                                "%",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "profit_margin",                 "Profit Margin",                                           "%",      "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "development_fee",               "Development Fee",                                         "$M",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "turbine_transportation",        "Turbine Transportation",                                  "mi",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "project_total_budgeted_cost",   "Project Total Budgeted Cost",                             "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "transportation_cost",           "Transportation Cost",                                     "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "insurance_cost",                "Insurance Cost",                                          "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "engineering_cost",              "Engineering Cost",                                        "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "power_performance_cost",        "Power Performance Cost",                                  "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "site_compound_security_cost",   "Site Compound & Security Cost",                           "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "building_cost",                 "Building Cost",                                           "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "transmission_cost",             "Transmission Cost",                                       "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "markup_cost",                   "Markup Cost",                                             "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "development_cost",              "Development Cost",                                        "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "access_roads_cost",             "Access Roads Cost",                                       "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "foundation_cost",               "Foundation Cost",                                         "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "erection_cost",                 "Turbine Erection Cost",                                   "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "electrical_materials_cost",     "MV Electrical Materials Cost",                            "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "electrical_installation_cost",  "MV Electrical Installation Cost",                         "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "substation_cost",               "Substation Cost",                                         "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "project_mgmt_cost",             "Project Management Cost",                                 "$s",     "",                      "wind_bos",      "*",                       "",                              "" ),
	var_info_invalid
]

class cm_windbos(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_windbos)

    enum SiteTerrain:
        FLAT_TO_ROLLING = 0
        RIDGE_TOP = 1
        MOUNTAINOUS = 2

    enum TurbineLayout:
        SIMPLE = 0
        COMPLEX = 1

    enum SoilCondition:
        STANDARD = 0
        BOUYANT = 1

    def round_bos(self, number: Float64) -> Int:
        return (Int(number + 0.5) if number >= 0 else Int(number - 0.5))

    def farmSize(self, rating: Float64, nTurb: Int) -> Float64:
        return rating * nTurb / 1000.0

    def transportationCost(self, tcc: Float64, rating: Float64, nTurb: Int, hubHt: Float64, transportDist: Float64) -> Float64:
        var cost: Float64 = tcc * rating * nTurb
        if rating < 2500 and hubHt < 100:
            cost += 1349 * pow(transportDist, 0.746) * nTurb
        else:
            cost += 1867 * pow(transportDist, 0.726) * nTurb
        self.assign("transportation_cost", var_data(ssc_number_t(cost)))
        return cost

    def engineeringCost(self, nTurb: Int, farmSize: Float64) -> Float64:
        var cost: Float64 = 7188.5 * nTurb
        cost += self.round_bos(3.4893 * log(nTurb) - 7.3049) * 16800
        var multiplier: Float64 = 2.0
        if farmSize < 200:
            multiplier = 1.0
        cost += multiplier * 161675
        cost += 4000
        self.assign("engineering_cost", var_data(ssc_number_t(cost)))
        return cost

    def powerPerformanceCost(self, hubHt: Float64, permanent: Float64, temporary: Float64) -> Float64:
        var multiplier1: Float64 = 290000
        var multiplier2: Float64 = 116800
        if hubHt < 90:
            multiplier1 = 232600
            multiplier2 = 92600
        var cost: Float64 = 200000 + permanent * multiplier1 + temporary * multiplier2
        self.assign("power_performance_cost", var_data(ssc_number_t(cost)))
        return cost

    def accessRoadsCost(self, terrain: SiteTerrain, layout: TurbineLayout, nTurb: Int, diameter: Float64, constructionTime: Int, accessRoadEntrances: Int) -> Float64:
        var factor1: Float64 = 0.0
        var factor2: Float64 = 0.0
        if layout == self.TurbineLayout.SIMPLE:
            if terrain == self.SiteTerrain.FLAT_TO_ROLLING:
                factor1 = 49962.5
                factor2 = 24.8
            elif terrain == self.SiteTerrain.RIDGE_TOP:
                factor1 = 59822.0
                factor2 = 26.8
            elif terrain == self.SiteTerrain.MOUNTAINOUS:
                factor1 = 66324.0
                factor2 = 26.8
        elif layout == self.TurbineLayout.COMPLEX:
            if terrain == self.SiteTerrain.FLAT_TO_ROLLING:
                factor1 = 62653.6
                factor2 = 30.9
            elif terrain == self.SiteTerrain.RIDGE_TOP:
                factor1 = 74213.3
                factor2 = 33.0
            elif terrain == self.SiteTerrain.MOUNTAINOUS:
                factor1 = 82901.1
                factor2 = 33.0
        var cost: Float64 = (nTurb * factor1 + nTurb * diameter * factor2
            + constructionTime * 55500
            + accessRoadEntrances * 3800) * 1.05
        self.assign("access_roads_cost", var_data(ssc_number_t(cost)))
        return cost

    def siteCompoundCost(self, accessRoadEntrances: Int, constructionTime: Int, farmSize: Float64) -> Float64:
        var cost: Float64 = 9825.0 * accessRoadEntrances + 29850.0 * constructionTime
        var multiplier: Float64
        if farmSize > 100:
            multiplier = 10.0
        elif farmSize > 30:
            multiplier = 5.0
        else:
            multiplier = 3.0
        cost += multiplier * 30000
        if farmSize > 30:
            cost += 90000
        cost += farmSize * 60 + 62400
        self.assign("site_compound_security_cost", var_data(ssc_number_t(cost)))
        return cost

    def buildingCost(self, buildingSize: Float64) -> Float64:
        var cost: Float64 = buildingSize * 125 + 176125
        self.assign("building_cost", var_data(ssc_number_t(cost)))
        return cost

    def foundationCost(self, rating: Float64, diameter: Float64, topMass: Float64, hubHt: Float64, soil: SoilCondition, nTurb: Int) -> Float64:
        var cost: Float64 = rating * diameter * topMass / 1000.0 \
            + 163421.5 * pow(nTurb, -0.1458) + (hubHt - 80) * 500
        if soil == self.SoilCondition.BOUYANT:
            cost += 20000
        cost *= nTurb
        self.assign("foundation_cost", var_data(ssc_number_t(cost)))
        return cost

    def erectionCost(self, rating: Float64, hubHt: Float64, nTurb: Int, weatherDelayDays: Int, craneBreakdowns: Int, deliveryAssistRequired: Int) -> Float64:
        var cost: Float64 = (37 * rating + 27000 * pow(nTurb, -0.42145) + (hubHt - 80) * 500) * nTurb
        if deliveryAssistRequired:
            cost += 60000 * nTurb
        cost += 20000 * weatherDelayDays + 35000 * craneBreakdowns + 181 * nTurb + 1834
        self.assign("erection_cost", var_data(ssc_number_t(cost)))
        return cost

    def electricalMaterialsCost(self, terrain: SiteTerrain, layout: TurbineLayout, farmSize: Float64, diameter: Float64, nTurb: Int, padMountTransformer: Int, thermalBackfill: Float64) -> Float64:
        var factor1: Float64 = 0.0
        var factor2: Float64 = 0.0
        var factor3: Float64 = 0.0
        if layout == self.TurbineLayout.SIMPLE:
            if terrain == self.SiteTerrain.FLAT_TO_ROLLING:
                factor1 = 66733.4
                factor2 = 27088.4
                factor3 = 545.4
            elif terrain == self.SiteTerrain.RIDGE_TOP:
                factor1 = 67519.4
                factor2 = 27874.4
                factor3 = 590.8
            elif terrain == self.SiteTerrain.MOUNTAINOUS:
                factor1 = 68305.4
                factor2 = 28660.4
                factor3 = 590.8
        elif layout == self.TurbineLayout.COMPLEX:
            if terrain == self.SiteTerrain.FLAT_TO_ROLLING:
                factor1 = 67519.4
                factor2 = 27874.4
                factor3 = 681.7
            elif terrain == self.SiteTerrain.RIDGE_TOP:
                factor1 = 68305.4
                factor2 = 28660.4
                factor3 = 727.2
            elif terrain == self.SiteTerrain.MOUNTAINOUS:
                factor1 = 69484.4
                factor2 = 29839.4
                factor3 = 727.2
        var cost: Float64
        if padMountTransformer:
            cost = nTurb * factor1
        else:
            cost = nTurb * factor2
        cost += floor(farmSize / 25.0) * 35375 + floor(farmSize / 100.0) * 50000 \
            + diameter * nTurb * factor3 + thermalBackfill * 5 + 41945
        self.assign("electrical_materials_cost", var_data(ssc_number_t(cost)))
        return cost

    def electricalInstallationCost(self, terrain: SiteTerrain, layout: TurbineLayout, farmSize: Float64, diameter: Float64, nTurb: Int, rockTrenchingLength: Float64, overheadCollector: Float64) -> Float64:
        var factor1: Float64 = 0.0
        var factor2: Float64 = 0.0
        var factor3: Float64 = 0.0
        if layout == self.TurbineLayout.SIMPLE:
            if terrain == self.SiteTerrain.FLAT_TO_ROLLING:
                factor1 = 7059.3
                factor2 = 352.4
                factor3 = 297.0
            elif terrain == self.SiteTerrain.RIDGE_TOP:
                factor1 = 7683.5
                factor2 = 564.3
                factor3 = 483.0
            elif terrain == self.SiteTerrain.MOUNTAINOUS:
                factor1 = 8305.0
                factor2 = 682.6
                factor3 = 579.0
        elif layout == self.TurbineLayout.COMPLEX:
            if terrain == self.SiteTerrain.FLAT_TO_ROLLING:
                factor1 = 7683.5
                factor2 = 564.9
                factor3 = 446.0
            elif terrain == self.SiteTerrain.RIDGE_TOP:
                factor1 = 8305.0
                factor2 = 866.8
                factor3 = 713.0
            elif terrain == self.SiteTerrain.MOUNTAINOUS:
                factor1 = 9240.0
                factor2 = 972.8
                factor3 = 792.0
        var cost: Float64 = Int(farmSize / 25.0) * 14985
        if farmSize > 200:
            cost += 300000
        else:
            cost += 155000
        cost += nTurb * (factor1 + diameter * (factor2 + factor3 * rockTrenchingLength / 100.0)) \
            + overheadCollector * 200000 + 10000
        self.assign("electrical_installation_cost", var_data(ssc_number_t(cost)))
        return cost

    def substationCost(self, voltage: Float64, farmSize: Float64) -> Float64:
        var cost: Float64 = 11652 * (voltage + farmSize) + 11795 * pow(farmSize, 0.3549) + 1526800
        self.assign("substation_cost", var_data(ssc_number_t(cost)))
        return cost

    def transmissionCost(self, voltage: Float64, distInter: Float64, newSwitchyardRequired: Int) -> Float64:
        var cost: Float64 = (1176 * voltage + 218257) * pow(distInter, 0.8937)
        if newSwitchyardRequired:
            cost += 18115 * voltage + 165944
        self.assign("transmission_cost", var_data(ssc_number_t(cost)))
        return cost

    def projectMgmtCost(self, constructionTime: Int) -> Float64:
        var cost: Float64
        if constructionTime < 28:
            cost = (53.333 * constructionTime * constructionTime - 3442 * constructionTime \
                + 209542) * (constructionTime + 2)
        else:
            cost = (constructionTime + 2) * 155000
        self.assign("project_mgmt_cost", var_data(ssc_number_t(cost)))
        return cost

    def developmentCost(self, developmentFee: Float64) -> Float64:
        var cost: Float64 = developmentFee * 1000000
        self.assign("development_cost", var_data(ssc_number_t(cost)))
        return cost

    def insuranceMultiplierAndCost(self, cost: Float64, tcc: Float64, farmSize: Float64, foundationCost: Float64, performanceBond: Int) -> Float64:
        var ins: Float64
        var pb_rate: Float64 = 0
        if performanceBond:
            pb_rate = 10.0
        ins = cost / 1000 * (3.5 + 0.7 + 0.4 + 1.0 + pb_rate) \
            + (tcc * farmSize) * (0.7 + 0.4 + 1.0 + pb_rate) \
            + 0.02 * foundationCost \
            + 20000
        self.assign("insurance_cost", var_data(ssc_number_t(ins)))
        return ins

    def markupMultiplierAndCost(self, cost: Float64, contingency: Float64, warranty: Float64, useTax: Float64, overhead: Float64, profitMargin: Float64) -> Float64:
        var markup: Float64
        markup = cost * (contingency + warranty + useTax + overhead + profitMargin) / 100.0
        self.assign("markup_cost", var_data(ssc_number_t(markup)))
        return markup

    def totalCost(self, rating: Float64, diameter: Float64, hubHt: Float64,
        nTurb: Int, voltage: Float64, distInter: Float64,
        terrain: SiteTerrain, layout: TurbineLayout, soil: SoilCondition,
        farmSize: Float64, tcc: Float64, topMass: Float64,
        constructionTime: Int, buildingSize: Float64, temporary: Float64,
        permanent: Float64, weatherDelayDays: Int, craneBreakdowns: Int,
        accessRoadEntrances: Int,
        deliveryAssistRequired: Int, padMountTransformer: Int,
        newSwitchyardRequired: Int, rockTrenchingLength: Float64,
        thermalBackfill: Float64, overheadCollector: Float64,
        performanceBond: Int, contingency: Float64, warranty: Float64,
        useTax: Float64, overhead: Float64, profitMargin: Float64,
        developmentFee: Float64, transportDist: Float64) -> Float64:
        var cost: Float64 = 0.0
        cost += self.engineeringCost(nTurb, farmSize)
        cost += self.powerPerformanceCost(hubHt, permanent, temporary)
        cost += self.siteCompoundCost(accessRoadEntrances, constructionTime, farmSize)
        cost += self.buildingCost(buildingSize)
        cost += self.transmissionCost(voltage, distInter, newSwitchyardRequired)
        cost += self.developmentCost(developmentFee)
        cost += self.accessRoadsCost(terrain, layout, nTurb, diameter, constructionTime, accessRoadEntrances)
        var foundCost: Float64 = self.foundationCost(rating, diameter, topMass, hubHt, soil, nTurb)
        cost += foundCost
        cost += self.erectionCost(rating, hubHt, nTurb, weatherDelayDays, craneBreakdowns, deliveryAssistRequired)
        cost += self.electricalMaterialsCost(terrain, layout, farmSize, diameter, nTurb, padMountTransformer, thermalBackfill)
        cost += self.electricalInstallationCost(terrain, layout, farmSize, diameter, nTurb, rockTrenchingLength, overheadCollector)
        cost += self.substationCost(voltage, farmSize)
        cost += self.projectMgmtCost(constructionTime)
        var ins: Float64 = self.insuranceMultiplierAndCost(cost, tcc, farmSize, foundCost, performanceBond)
        var markup: Float64 = self.markupMultiplierAndCost(cost, contingency, warranty, useTax, overhead, profitMargin)
        cost += ins + markup
        cost += self.transportationCost(tcc, rating, nTurb, hubHt, transportDist)
        return cost

    def exec(self):
        var rating: Float64 = Float64(self.as_number("machine_rating"))
        var diameter: Float64 = Float64(self.as_number("rotor_diameter"))
        var hubHt: Float64 = Float64(self.as_number("hub_height"))
        var nTurb: Int = self.as_integer("number_of_turbines")
        var voltage: Float64 = Float64(self.as_number("interconnect_voltage"))
        var distInter: Float64 = Float64(self.as_number("distance_to_interconnect"))
        var terrain: SiteTerrain = SiteTerrain(self.as_integer("site_terrain"))
        var layout: TurbineLayout = TurbineLayout(self.as_integer("turbine_layout"))
        var soil: SoilCondition = SoilCondition(self.as_integer("soil_condition"))
        var farmSize: Float64 = cm_windbos.farmSize(self, rating, nTurb)
        var constructionTime: Int = Int(self.as_number("construction_time"))
        var buildingSize: Float64 = Float64(self.as_number("om_building_size"))
        var temporary: Float64 = Float64(self.as_number("quantity_test_met_towers"))
        var permanent: Float64 = Float64(self.as_number("quantity_permanent_met_towers"))
        var weatherDelayDays: Int = Int(self.as_number("weather_delay_days"))
        var craneBreakdowns: Int = Int(self.as_number("crane_breakdowns"))
        var accessRoadEntrances: Int = Int(self.as_number("access_road_entrances"))
        var tcc: Float64 = Float64(self.as_number("turbine_capital_cost"))
        var topMass: Float64 = Float64(self.as_number("tower_top_mass"))
        var deliveryAssistRequired: Int = self.as_integer("delivery_assist_required")
        var padMountTransformer: Int = self.as_integer("pad_mount_transformer_required")
        var newSwitchyardRequired: Int = self.as_integer("new_switchyard_required")
        var rockTrenchingLength: Float64 = Float64(self.as_number("rock_trenching_required"))
        var thermalBackfill: Float64 = Float64(self.as_number("mv_thermal_backfill"))
        var overheadCollector: Float64 = Float64(self.as_number("mv_overhead_collector"))
        var performanceBond: Float64 = Float64(self.as_number("performance_bond"))
        var contingency: Float64 = Float64(self.as_number("contingency"))
        var warranty: Float64 = Float64(self.as_number("warranty_management"))
        var useTax: Float64 = Float64(self.as_number("sales_and_use_tax"))
        var overhead: Float64 = Float64(self.as_number("overhead"))
        var profitMargin: Float64 = Float64(self.as_number("profit_margin"))
        var developmentFee: Float64 = Float64(self.as_number("development_fee"))
        var transportDist: Float64 = Float64(self.as_number("turbine_transportation"))
        var output: ssc_number_t = ssc_number_t(self.totalCost(rating, diameter, hubHt, nTurb, voltage, distInter, terrain, layout, soil,
            farmSize, tcc, topMass, constructionTime, buildingSize, temporary, permanent, weatherDelayDays, craneBreakdowns, accessRoadEntrances,
            deliveryAssistRequired, padMountTransformer, newSwitchyardRequired, rockTrenchingLength, thermalBackfill, overheadCollector,
            Int(performanceBond), contingency, warranty, useTax, overhead, profitMargin, developmentFee, transportDist))
        self.assign("project_total_budgeted_cost", var_data(output))

DEFINE_MODULE_ENTRY(windbos, "Wind Balance of System cost model", 1)
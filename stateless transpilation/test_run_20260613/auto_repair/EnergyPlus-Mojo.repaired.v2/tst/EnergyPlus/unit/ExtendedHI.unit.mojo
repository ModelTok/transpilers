from testing import assert_approx_eq, assert_equal, test
from math import sqrt, abs
from List import List
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.ExtendedHeatIndex import ExtendedHI, EqvarName, pvstar, Le, Qv, Zs, Ra, Ra_bar, Ra_un, find_eqvar_name_and_value, find_T, heatindex
from EnergyPlus.IceThermalStorage import IceThermalStorage

struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def __moveinit__(inout self, owned existing: Self):
        self.state = existing.state ^

@test
def extendedHI_pvstar() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 1e-8
    var T_values = List[Float64](200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350, 360, 370)
    var result = List[Float64](0.16315953, 0.70457376, 2.66392126, 8.97272134, 27.31539419, 76.07472151, 195.83100376, 470.03352248, 991.92542226, 1920.68015554, 3538.94082369, 6235.88791594, 10554.04916628, 17222.31477378, 27187.71571487, 41643.76611223, 62053.26405691, 90163.72448627)
    for i in range(len(T_values)):
        assert_approx_eq(pvstar(T_values[i]), result[i], tol)

@test
def extendedHI_Le() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 1e-2
    var T_values = List[Float64](200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350, 360, 370)
    var result = List[Float64](2663805.16, 2641405.16, 2619005.16, 2596605.16, 2574205.16, 2551805.16, 2529405.16, 2507005.16, 2484605.16, 2462205.16, 2439805.16, 2417405.16, 2395005.16, 2372605.16, 2350205.16, 2327805.16, 2305405.16, 2283005.16)
    for i in range(len(T_values)):
        assert_approx_eq(Le(T_values[i]), result[i], tol)

@test
def extendedHI_Qv() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 1e-8
    var T_values = List[Float64](200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350, 360, 370)
    var P_values = List[Float64](1, 10, 100, 1000, 10000)
    var result = List[List[Float64]](
        List[Float64](49.94618971, 49.91176799, 49.56755081, 46.12537897, 11.70366056),
        List[Float64](47.35664275, 47.32222103, 46.97800385, 43.53583201, 9.1141136),
        List[Float64](44.76709579, 44.73267407, 44.38845689, 40.94628505, 6.52456664),
        List[Float64](42.17754883, 42.14312711, 41.79890993, 38.35673809, 3.93501968),
        List[Float64](39.58800187, 39.55358015, 39.20936297, 35.76719113, 1.34547272),
        List[Float64](36.99845491, 36.96403319, 36.61981601, 33.17764417, -1.24407424),
        List[Float64](34.40890795, 34.37448623, 34.03026905, 30.58809721, -3.8336212),
        List[Float64](31.81936099, 31.78493927, 31.44072209, 27.99855025, -6.42316816),
        List[Float64](29.22981403, 29.19539231, 28.85117513, 25.40900329, -9.01271512),
        List[Float64](26.64026707, 26.60584535, 26.26162817, 22.81945633, -11.60226208),
        List[Float64](24.05072011, 24.01629839, 23.67208121, 20.22990937, -14.19180904),
        List[Float64](21.46117315, 21.42675143, 21.08253425, 17.64036241, -16.781356),
        List[Float64](18.87162619, 18.83720447, 18.49298729, 15.05081545, -19.37090296),
        List[Float64](16.28207923, 16.24765751, 15.90344033, 12.46126849, -21.96044992),
        List[Float64](13.69253227, 13.65811055, 13.31389337, 9.87172153, -24.54999688),
        List[Float64](11.10298531, 11.06856359, 10.72434641, 7.28217457, -27.13954384),
        List[Float64](8.51343835, 8.47901663, 8.13479945, 4.69262761, -29.7290908),
        List[Float64](5.92389139, 5.88946967, 5.54525249, 2.10308065, -32.31863776),
    )
    for i in range(len(T_values)):
        for j in range(len(P_values)):
            assert_approx_eq(Qv(T_values[i], P_values[j]), result[i][j], tol)

@test
def extendedHI_Zs() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 1e-8
    var Rs_values = List[Float64](0.0387, 0.5, 1, 1.2)
    var result = List[Float64](52.1, 18750000.0, 600000000.0, 1492991999.9999998)
    for i in range(len(Rs_values)):
        assert_approx_eq(Zs(Rs_values[i]), result[i], tol)

@test
def extendedHI_Ra() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 1e-8
    var Ts_values = List[Float64](240, 260, 280, 300, 320, 340, 360)
    var Ta_values = List[Float64](240, 260, 280, 300, 320, 340, 360)
    var result = List[List[Float64]](
        List[Float64](0.05003743, 0.04919687, 0.04829495, 0.04733483, 0.04632048, 0.04525658, 0.04414843),
        List[Float64](0.04919687, 0.04834035, 0.0474255, 0.04645568, 0.045435, 0.0443682, 0.04326057),
        List[Float64](0.04829495, 0.0474255, 0.04650092, 0.04552473, 0.04450111, 0.04343485, 0.04233118),
        List[Float64](0.04733483, 0.04645568, 0.04552473, 0.0445456, 0.04352252, 0.04246025, 0.04136396),
        List[Float64](0.04632048, 0.045435, 0.04450111, 0.04352252, 0.04250345, 0.0414486, 0.04036303),
        List[Float64](0.04525658, 0.0443682, 0.04343485, 0.04246025, 0.0414486, 0.04040451, 0.03933288),
        List[Float64](0.04414843, 0.04326057, 0.04233118, 0.04136396, 0.04036303, 0.03933288, 0.03827822),
    )
    for i in range(len(Ts_values)):
        for j in range(len(Ta_values)):
            assert_approx_eq(Ra(Ts_values[i], Ta_values[j]), result[i][j], tol)

@test
def extendedHI_Ra_bar() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 1e-8
    var Tf_values = List[Float64](240, 260, 280, 300, 320, 340, 360)
    var Ta_values = List[Float64](240, 260, 280, 300, 320, 340, 360)
    var result = List[List[Float64]](
        List[Float64](0.07141547, 0.06983279, 0.06815365, 0.0663875, 0.06454507, 0.06263806, 0.06067882),
        List[Float64](0.06983279, 0.06823771, 0.06655337, 0.06478927, 0.06295607, 0.06106521, 0.05912865),
        List[Float64](0.06815365, 0.06655337, 0.06487109, 0.06311629, 0.06129941, 0.05943158, 0.0575243),
        List[Float64](0.0663875, 0.06478927, 0.06311629, 0.06137788, 0.05958421, 0.05774599, 0.05587418),
        List[Float64](0.06454507, 0.06295607, 0.06129941, 0.05958421, 0.05782026, 0.05601779, 0.05418719),
        List[Float64](0.06263806, 0.06106521, 0.05943158, 0.05774599, 0.05601779, 0.05425668, 0.05247244),
        List[Float64](0.06067882, 0.05912865, 0.0575243, 0.05587418, 0.05418719, 0.05247244, 0.0507391),
    )
    for i in range(len(Tf_values)):
        for j in range(len(Ta_values)):
            assert_approx_eq(Ra_bar(Tf_values[i], Ta_values[j]), result[i][j], tol)

@test
def extendedHI_Ra_un() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 1e-8
    var Tf_values = List[Float64](240, 260, 280, 300, 320, 340, 360)
    var Ta_values = List[Float64](240, 260, 280, 300, 320, 340, 360)
    var result = List[List[Float64]](
        List[Float64](0.06787493, 0.06642598, 0.06488609, 0.06326346, 0.06156753, 0.05980867, 0.05799795),
        List[Float64](0.06642598, 0.06496324, 0.06341598, 0.0617925, 0.06010222, 0.05835534, 0.05656263),
        List[Float64](0.06488609, 0.06341598, 0.06186786, 0.06025007, 0.0585719, 0.0568433, 0.05507465),
        List[Float64](0.06326346, 0.0617925, 0.06025007, 0.05864444, 0.05698468, 0.05528041, 0.05354159),
        List[Float64](0.06156753, 0.06010222, 0.0585719, 0.05698468, 0.05534934, 0.05367512, 0.0519715),
        List[Float64](0.05980867, 0.05835534, 0.0568433, 0.05528041, 0.05367512, 0.05203623, 0.0503727),
        List[Float64](0.05799795, 0.05656263, 0.05507465, 0.05354159, 0.0519715, 0.0503727, 0.0487536),
    )
    for i in range(len(Tf_values)):
        for j in range(len(Ta_values)):
            assert_approx_eq(Ra_un(Tf_values[i], Ta_values[j]), result[i][j], tol)

@test
def extendedHI_find_eqvar() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 0.001
    var Ta_values = List[Float64](240, 260, 280, 300, 320, 340, 360)
    var RH_values = List[Float64](0, 0.2, 0.4, 0.6, 0.8, 1.0)
    var result_0: List[List[EqvarName]] = List[List[EqvarName]](
        List[EqvarName](EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf),
        List[EqvarName](EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf),
        List[EqvarName](EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf, EqvarName.Rf),
        List[EqvarName](EqvarName.Rf, EqvarName.Rs, EqvarName.Rs, EqvarName.Rs, EqvarName.Rs, EqvarName.Rs),
        List[EqvarName](EqvarName.Rs, EqvarName.Rs, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt),
        List[EqvarName](EqvarName.Rs, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt),
        List[EqvarName](EqvarName.Rs, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt, EqvarName.DTcdt),
    )
    var result_1 = List[List[Float64]](
        List[Float64](33.043, 32.696, 32.355, 32.022, 31.695, 31.374),
        List[Float64](1.56, 1.546, 1.532, 1.519, 1.505, 1.491),
        List[Float64](0.442, 0.423, 0.404, 0.386, 0.369, 0.352),
        List[Float64](0.011, 0.038, 0.037, 0.035, 0.034, 0.031),
        List[Float64](0.027, 0.023, 0.0, 0.003, 0.006, 0.009),
        List[Float64](0.021, 0.005, 0.012, 0.02, 0.027, 0.035),
        List[Float64](0.001, 0.017, 0.034, 0.051, 0.068, 0.085),
    )
    var eqvar_name = EqvarName.Invalid
    var eqvar_value: Float64 = 0.0
    for i in range(len(Ta_values)):
        for j in range(len(RH_values)):
            eqvar_value = find_eqvar_name_and_value(state, Ta_values[i], RH_values[j], eqvar_name)
            assert_equal(eqvar_name, result_0[i][j])
            assert_approx_eq(eqvar_value, result_1[i][j], tol)

@test
def extendedHI_find_T() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var tol = 0.05
    state.dataRootFinder.rootAlgo = RootAlgo.Bisection
    var Rf_values = List[Float64](30, 32, 34, 36, 38)
    var result_0_rf = List[Float64](240.08, 239.97, 239.89, 239.81, 239.74)
    for i in range(len(Rf_values)):
        assert_approx_eq(find_T(state, EqvarName.Rf, Rf_values[i]), result_0_rf[i], tol)
    var Rs_values = List[Float64](0.01, 0.02, 0.03)
    var result_0_rs = List[Float64](337.87, 329.76, 307.48)
    for i in range(len(Rs_values)):
        assert_approx_eq(find_T(state, EqvarName.Rs, Rs_values[i]), result_0_rs[i], tol)
    var phi_values = List[Float64](0.86, 0.88, 0.90, 0.92, 0.94, 0.96)
    var result_0_phi = List[Float64](228.69, 216.00, 199.00, 175.19, 139.71, 82.05)
    for i in range(len(phi_values)):
        assert_approx_eq(find_T(state, EqvarName.Phi, phi_values[i]), result_0_phi[i], tol)
    var dTcdt_values = List[Float64](0.01, 0.03, 0.05, 0.07, 0.09)
    var result_0_dTcdt = List[Float64](412.53, 512.36, 584.55, 641.20, 688.04)
    for i in range(len(dTcdt_values)):
        assert_approx_eq(find_T(state, EqvarName.DTcdt, dTcdt_values[i]), result_0_dTcdt[i], tol)

@test
def extendedHI_heatindex() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    state.dataRootFinder.rootAlgo = RootAlgo.Bisection
    var HI_values = List[List[Float64]](
        List[Float64](199.9994, 199.9997, 200.0),
        List[Float64](209.9976, 209.9988, 210.0),
        List[Float64](219.9916, 219.9958, 220.0),
        List[Float64](229.974, 229.987, 230.0),
        List[Float64](239.9254, 239.9627, 240.0),
        List[Float64](249.7677, 249.8837, 250.0),
        List[Float64](259.3736, 259.6864, 260.0),
        List[Float64](268.5454, 269.2746, 270.0),
        List[Float64](277.2234, 278.6369, 280.0),
        List[Float64](285.7511, 288.2814, 290.7861),
        List[Float64](297.5738, 300.2923, 305.3947),
        List[Float64](305.555, 318.6226, 359.9063),
        List[Float64](313.0299, 359.0539, 407.5345),
        List[Float64](320.5089, 398.576, 464.9949),
        List[Float64](328.0358, 445.8599, 530.5525),
        List[Float64](333.2806, 500.0422, 601.9518),
        List[Float64](343.6313, 559.664, 677.2462),
        List[Float64](354.1826, 623.196, 755.0833),
    )
    var T_values = List[Float64](200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340, 350, 360, 370)
    var RH_values = List[Float64](0, 0.5, 1)
    var tol = 0.1
    for i in range(len(T_values)):
        for j in range(len(RH_values)):
            var HI = HI_values[i][j]
            assert_approx_eq(heatindex(state, T_values[i], RH_values[j]), HI, tol)

def calcHI(ZoneTF: Float64, ZoneRH: Float64) -> Float64:
    var HI: Float64
    var c1: Float64 = -42.379
    var c2: Float64 = 2.04901523
    var c3: Float64 = 10.14333127
    var c4: Float64 = -.22475541
    var c5: Float64 = -.00683783
    var c6: Float64 = -.05481717
    var c7: Float64 = .00122874
    var c8: Float64 = .00085282
    var c9: Float64 = -.00000199
    if ZoneTF < 80:
        HI = 0.5 * (ZoneTF + 61.0 + (ZoneTF - 68.0) * 1.2 + (ZoneRH * 0.094))
    else:
        HI = c1 + c2 * ZoneTF + c3 * ZoneRH + c4 * ZoneTF * ZoneRH + c5 * ZoneTF * ZoneTF + c6 * ZoneRH * ZoneRH + c7 * ZoneTF * ZoneTF * ZoneRH + c8 * ZoneTF * ZoneRH * ZoneRH + c9 * ZoneTF * ZoneTF * ZoneRH * ZoneRH
        if ZoneRH < 13 and ZoneTF < 112:
            HI -= (13 - ZoneRH) / 4 * sqrt((17 - abs(ZoneTF - 95)) / 17)
        elif ZoneRH > 85 and ZoneTF < 87:
            HI += (ZoneRH - 85) / 10 * (87 - ZoneTF) / 5
    HI = (HI - 32.0) * (5.0 / 9.0)
    return HI

@test
def extendedHI_heatindex_compare() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var HI_values = List[List[Float64]](
        List[Float64](299.50263955106493, 299.776740099187, 300.0697403535014, 300.3840374486754, 300.7224627089454, 301.0883855406428, 301.48585129820276, 301.91976206202526, 302.39612058678176, 302.9223619942786, 303.50781721121166, 304.164366737823, 304.90738965163473),
        List[Float64](300.7371586287627, 301.08082855993416, 301.45165138470475, 301.85347046062816, 302.29090810229536, 302.7695771184517, 303.2963640097296, 303.8798186200438, 304.5306942932075, 305.2627171872882, 306.0937017010292, 307.0472131000133, 308.15511379914824),
        List[Float64](302.02736771141645, 302.4561810697196, 302.92349559196737, 303.4353941195877, 303.9993409969611, 304.62460199545603, 305.322829571669, 306.10889266303275, 307.00207884714473, 308.027883155155, 309.2207373859128, 313.0628398671979, 321.5848247316899),
        List[Float64](303.3841495186789, 303.9170689758612, 304.50409744807985, 305.1547874516109, 305.88112467259634, 306.69836198852863, 307.62622559734154, 308.69069155014586, 309.9266883142991, 311.38231908960734, 318.54246110946406, 328.0043066147482, 333.3393972698832),
        List[Float64](304.8199354641838, 305.48032203514595, 306.21634121227544, 307.0429394330131, 307.97934497182723, 309.05072723689955, 310.29069143289234, 311.7451353772776, 313.95530016103294, 323.83440227771644, 332.4701096833451, 334.90678639907856, 337.31894975469913),
        List[Float64](306.3492841011612, 307.16624582593795, 308.0886627669679, 309.13992447021883, 310.35097800020594, 311.7636495939223, 313.43586634553503, 317.6494802389061, 328.3628307696199, 333.74059265770484, 336.3222867687, 338.8761290133698, 341.4020377426641),
        List[Float64](307.98957814869937, 308.99980285495985, 310.15708861581516, 311.49815879471134, 313.0731694836868, 314.95241500844713, 320.7787010347238, 331.8317274673609, 334.83416476810817, 337.5699159357464, 340.2740648871986, 342.94652084296104, 345.6054543473874),
        List[Float64](309.7619108116487, 311.0122043680167, 312.46811247605365, 314.187658362207, 316.2529625179013, 323.0801825976232, 332.79726637585554, 335.7326857879525, 338.63242015999276, 341.4963439834537, 344.32435625989456, 347.16610411327565, 349.9882094984059),
        List[Float64](311.6922567837173, 313.2431093422929, 315.0828601612011, 317.30399334745016, 324.3992667720886, 333.3013983833371, 336.4164381631417, 339.4910959439585, 342.5252268166514, 345.53482289920794, 348.55059671303025, 351.53749776567565, 354.49586372385966),
        List[Float64](313.81305196962785, 315.74373047973495, 318.0832217884017, 324.6363173221471, 333.556578377611, 336.86389599752147, 340.12557708716486, 343.3414515358163, 346.5464459863142, 349.74051965837134, 352.90212786378106, 356.0316775160027, 359.1295787363197),
        List[Float64](316.1653665843187, 318.58128181367647, 323.6855917231878, 333.5378166526789, 337.0514521509176, 340.51358119759243, 343.9240011043148, 347.3324049610528, 350.715991469624, 354.063080122869, 357.3741601619986, 360.6497245162609, 363.89026874647243),
        List[Float64](318.80192411888856, 321.8453275115462, 333.2175307610305, 336.9530971109634, 340.63061076856684, 344.2498254548991, 347.8701384467422, 351.4554844770464, 354.99980266642524, 358.5036799122463, 361.96770739537897, 365.39247917797184, 368.7785908780643),
        List[Float64](321.79129250056576, 332.5651462195674, 336.5400431206217, 340.4496004333487, 344.2935131903505, 348.13508995372104, 351.9356167348451, 355.6900213044719, 359.3990061376826, 363.0632788382354, 366.6835501792957, 370.2605324515025, 373.7949378686608),
        List[Float64](329.9497329717269, 335.7802855706541, 339.9405041738646, 344.0269053383963, 348.1004405542626, 352.130907458195, 356.1095161383855, 360.03710570017574, 363.9145213572192, 367.74261204962386, 371.5222280813032, 375.2542191799148, 378.9394325375906),
        List[Float64](334.63809705979656, 339.06981446722057, 343.41864144138526, 347.7367934017093, 352.013488568773, 356.2318584616878, 360.3929031532607, 364.49763041891856, 368.54705243284116, 372.5421826945967, 376.48403349361615, 380.3736132776248, 384.2119247702067),
        List[Float64](337.80000485421624, 342.43363185960334, 347.0118012771127, 351.55276412755484, 356.0280998123926, 360.438997685269, 364.78665706905304, 369.07228278025286, 373.2970810952247, 377.4622562734294, 381.56900731119094, 385.6185252717114, 389.61199074954493),
    )
    var T_values = List[Float64]()
    for i in range(16):
        T_values.append(80.0 + 2.0 * i)
    var RH_values = List[Float64]()
    for i in range(13):
        RH_values.append(40.0 + 5.0 * i)
    var extended: Float64
    for i in range(len(T_values)):
        for j in range(len(RH_values)):
            extended = heatindex(state, IceThermalStorage.TempIPtoSI(T_values[i]) + 273.15, RH_values[j] / 100.0)
            assert_approx_eq(HI_values[i][j], extended, 0.1)
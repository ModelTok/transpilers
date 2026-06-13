from gtest import Test, TestFixture, AssertTrue, ExpectEq, ExpectNe, ExpectEnumEq, CompareErrStream
from EnergyPlus.CurveManager import Curve
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.Material import Material
from EnergyPlus.ScheduleManager import ScheduleManager
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string, compare_err_stream

@fixture
class EnergyPlusFixture:

@TestFixture
class GetMaterialDataReadVarAbsorptance(EnergyPlusFixture):
    def run(self):
        var idf_objects: String = delimited_string([
            "MaterialProperty:VariableAbsorptance,",
            "variableThermal_wall_1,  !- Name",
            "WALL_1,                  !- Reference Material Name",
            "SurfaceTemperature,      !- Control Signal",
            "THERMAL_ABSORPTANCE_TABLE, !- Thermal Absorptance Function Name",
            ",                        !- Thermal Absorptance Schedule Name",
            "SOLAR_ABSORPTANCE_CURVE, !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
            "MaterialProperty:VariableAbsorptance,",
            "variableSolar_wall_2,    !- Name",
            "WALL_2,                  !- Reference Material Name",
            "SurfaceReceivedSolarRadiation,      !- Control Signal",
            ",                        !- Thermal Absorptance Function Name",
            ",                        !- Thermal Absorptance Schedule Name",
            "SOLAR_ABSORPTANCE_CURVE, !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
            "MaterialProperty:VariableAbsorptance,",
            "variableBoth_wall_3,     !- Name",
            "WALL_3,                  !- Reference Material Name",
            "Scheduled,               !- Control Signal",
            ",                        !- Thermal Absorptance Function Name",
            "ABS_SCH,                 !- Thermal Absorptance Schedule Name",
            ",                        !- Solar Absorptance Function Name",
            "ABS_SCH;                 !- Solar Absorptance Schedule Name",
            "ScheduleTypeLimits,",
            "  Fraction,                 !- Name",
            "  0,                        !- Lower Limit Value",
            "  1,                        !- Upper Limit Value",
            "  Continuous,               !- Numeric Type",
            "  Dimensionless;            !- Unit Type",
            "Schedule:Constant,",
            "    ABS_SCH,                    !- Name",
            "    Fraction,                   !- Schedule Type Limits Name",
            "    0.9;                        !- Hourly Value",
        ])
        AssertTrue(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
        state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
        state.init_state(state)
        var s_mat = state.dataMaterial
        var mat1 = Material.MaterialBase()
        mat1.Name = "WALL_1"
        mat1.group = Material.Group.Regular
        s_mat.materials.append(mat1)
        mat1.Num = s_mat.materials.size()
        s_mat.materialMap.insert_or_assign(mat1.Name, mat1.Num)
        var mat2 = Material.MaterialBase()
        mat2.Name = "WALL_2"
        mat2.group = Material.Group.Regular
        s_mat.materials.append(mat2)
        mat2.Num = s_mat.materials.size()
        s_mat.materialMap.insert_or_assign(mat2.Name, mat2.Num)
        var mat3 = Material.MaterialBase()
        mat3.Name = "WALL_3"
        mat3.group = Material.Group.Regular
        s_mat.materials.append(mat3)
        mat3.Num = s_mat.materials.size()
        s_mat.materialMap.insert_or_assign(mat3.Name, mat3.Num)
        var curve1 = Curve.AddCurve(state, "THERMAL_ABSORPTANCE_TABLE")
        var curve2 = Curve.AddCurve(state, "SOLAR_ABSORPTANCE_CURVE")
        var errors_found: Bool = False
        Material.GetVariableAbsorptanceInput(state, errors_found)
        ExpectEnumEq(mat1.absorpVarCtrlSignal, Material.VariableAbsCtrlSignal.SurfaceTemperature)
        ExpectEq(mat1.absorpThermalVarCurve.Num, 1)
        ExpectEq(mat1.absorpSolarVarCurve.Num, 2)
        ExpectEnumEq(mat2.absorpVarCtrlSignal, Material.VariableAbsCtrlSignal.SurfaceReceivedSolarRadiation)
        ExpectEq(mat2.absorpSolarVarCurve.Num, 2)
        ExpectEnumEq(mat3.absorpVarCtrlSignal, Material.VariableAbsCtrlSignal.Scheduled)
        ExpectNe(mat3.absorpThermalVarSched, None)
        ExpectNe(mat3.absorpSolarVarSched, None)
        var idf_objects_bad_inputs: String = delimited_string([
            "MaterialProperty:VariableAbsorptance,",
            "variableThermal_wall_1,  !- Name",
            "WALL_1,                  !- Reference Material Name",
            "SurfaceTemperature,      !- Control Signal",
            ",                        !- Thermal Absorptance Function Name",
            ",                        !- Thermal Absorptance Schedule Name",
            ",                        !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
        ])
        AssertTrue(process_idf(idf_objects_bad_inputs))
        Material.GetVariableAbsorptanceInput(state, errors_found)
        compare_err_stream("   ** Severe  ** MaterialProperty:VariableAbsorptance: Non-schedule control signal is chosen but both thermal and solar "
                           "absorptance table or "
                           "curve are undefined, for object VARIABLETHERMAL_WALL_1\n")
        idf_objects_bad_inputs = delimited_string([
            "MaterialProperty:VariableAbsorptance,",
            "variableThermal_wall_1,  !- Name",
            "WALL_1,                  !- Reference Material Name",
            "Scheduled,               !- Control Signal",
            ",                        !- Thermal Absorptance Function Name",
            ",                        !- Thermal Absorptance Schedule Name",
            ",                        !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
        ])
        AssertTrue(process_idf(idf_objects_bad_inputs))
        Material.GetVariableAbsorptanceInput(state, errors_found)
        compare_err_stream("   ** Severe  ** MaterialProperty:VariableAbsorptance: Control signal \"Scheduled\" is chosen but both thermal and solar "
                           "absorptance schedules are undefined, for object "
                           "VARIABLETHERMAL_WALL_1\n",
                           True)
        idf_objects_bad_inputs = delimited_string([
            "MaterialProperty:VariableAbsorptance,",
            "variableThermal_wall_1,  !- Name",
            "WALL_1,                  !- Reference Material Name",
            "SurfaceTemperature,      !- Control Signal",
            ",                        !- Thermal Absorptance Function Name",
            "ABS_SCH,                 !- Thermal Absorptance Schedule Name",
            "SOLAR_ABSORPTANCE_CURVE, !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
        ])
        AssertTrue(process_idf(idf_objects_bad_inputs))
        Material.GetVariableAbsorptanceInput(state, errors_found)
        compare_err_stream("   ** Warning ** MaterialProperty:VariableAbsorptance: Non-schedule control signal is chosen. Thermal or solar absorptance "
                           "schedule name is going to be "
                           "ignored, for object VARIABLETHERMAL_WALL_1\n",
                           True)
        idf_objects_bad_inputs = delimited_string([
            "MaterialProperty:VariableAbsorptance,",
            "variableThermal_wall_1,  !- Name",
            "WALL_1,                  !- Reference Material Name",
            "Scheduled,      !- Control Signal",
            ",                        !- Thermal Absorptance Function Name",
            "ABS_SCH,                 !- Thermal Absorptance Schedule Name",
            "SOLAR_ABSORPTANCE_CURVE, !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
        ])
        AssertTrue(process_idf(idf_objects_bad_inputs))
        Material.GetVariableAbsorptanceInput(state, errors_found)
        compare_err_stream("   ** Warning ** MaterialProperty:VariableAbsorptance: Control signal \"Scheduled\" is chosen. Thermal or solar absorptance "
                           "function name is going to be "
                           "ignored, for object VARIABLETHERMAL_WALL_1\n",
                           True)
        idf_objects_bad_inputs = delimited_string([
            "MaterialProperty:VariableAbsorptance,",
            "variableThermal_wall_1,  !- Name",
            "WALL_0,                  !- Reference Material Name",
            "SurfaceTemperature,      !- Control Signal",
            "THERMAL_ABSORPTANCE_TABLE, !- Thermal Absorptance Function Name",
            ",                        !- Thermal Absorptance Schedule Name",
            "SOLAR_ABSORPTANCE_CURVE, !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
        ])
        AssertTrue(process_idf(idf_objects_bad_inputs))
        Material.GetVariableAbsorptanceInput(state, errors_found)
        compare_err_stream("   ** Severe  ** GetVariableAbsorptanceInput: MaterialProperty:VariableAbsorptance = VARIABLETHERMAL_WALL_1\n   **   ~~~   "
                           "** Reference Material Name = WALL_0, item not found.\n",
                           True)
        idf_objects_bad_inputs = delimited_string([
            "MaterialProperty:VariableAbsorptance,",
            "variableThermal_wall_1,  !- Name",
            "WALL_1,                  !- Reference Material Name",
            "SurfaceTemperature,      !- Control Signal",
            "THERMAL_ABSORPTANCE_TABLE, !- Thermal Absorptance Function Name",
            ",                        !- Thermal Absorptance Schedule Name",
            "SOLAR_ABSORPTANCE_CURVE, !- Solar Absorptance Function Name",
            ";                        !- Solar Absorptance Schedule Name",
        ])
        AssertTrue(process_idf(idf_objects_bad_inputs))
        mat1.group = Material.Group.Glass
        Material.GetVariableAbsorptanceInput(state, errors_found)
        compare_err_stream("   ** Severe  ** MaterialProperty:VariableAbsorptance: Reference Material is not appropriate type for Thermal/Solar "
                           "Absorptance properties, material=WALL_1, must have regular properties (Thermal/Solar Absorptance)\n",
                           True)
from utils.string import String
from utils.vector import DynamicVector
from memory.unsafe import Pointer
import math

# EXTERNAL DEPS (to wire in glue):
# - IDFRecord: struct with Name, NumAlphas, NumNumbers, Alphas, Numbers, CommtS, CommtE
# - ObjectDefData: struct with ObjectDef names array, NumObjectDefs
# - IDFData: struct with IDFRecords vector, Comments vector, NumIDFRecords
# - FieldData: struct with Alphas, Numbers, InArgs, OutArgs, TempArgs arrays
# - NewFieldData: struct with NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits arrays
# - ReportVarData: struct with OldRepVarName, NewRepVarName, NewRepVarCaution arrays
# - CautionTracking: struct with OTMVarCaution, CMtrVarCaution, CMtrDVarCaution arrays
# - GlobalFlags: struct with FirstTime, ProcessingIMFFile, FatalError, MakingPretty, FullFileName, etc.
# - Callbacks: struct with function pointers for GetNewUnitNumber, GetObjectDefInIDD, etc.

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var commt_s: Int
    var commt_e: Int

struct ObjectDefData:
    var obj_names: DynamicVector[String]
    var num_object_defs: Int

struct IDFData:
    var idf_records: DynamicVector[IDFRecord]
    var comments: DynamicVector[String]
    var num_idf_records: Int
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int

struct FieldData:
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var in_args: DynamicVector[String]
    var out_args: DynamicVector[String]
    var temp_args: DynamicVector[String]
    var aor_n: DynamicVector[Bool]
    var req_fld: DynamicVector[Bool]
    var fld_names: DynamicVector[String]
    var fld_defaults: DynamicVector[String]
    var fld_units: DynamicVector[String]
    var num_alphas: Int
    var num_numbers: Int
    var num_args: Int
    var obj_min_flds: Int
    var cur_comment: Int

struct NewFieldData:
    var nw_aor_n: DynamicVector[Bool]
    var nw_req_fld: DynamicVector[Bool]
    var nw_fld_names: DynamicVector[String]
    var nw_fld_defaults: DynamicVector[String]
    var nw_fld_units: DynamicVector[String]
    var nw_num_args: Int
    var nw_obj_min_flds: Int

struct ReportVarData:
    var num_rep_var_names: Int
    var old_rep_var_name: DynamicVector[String]
    var new_rep_var_name: DynamicVector[String]
    var new_rep_var_caution: DynamicVector[String]

struct CautionTracking:
    var otm_var_caution: DynamicVector[Bool]
    var cmtr_var_caution: DynamicVector[Bool]
    var cmtr_d_var_caution: DynamicVector[Bool]

struct GlobalFlags:
    var first_time: Bool
    var processing_imf_file: Bool
    var fatal_error: Bool
    var making_pretty: Bool
    var full_file_name: String
    var file_name_path: String
    var file_ok: Bool
    var auditf: String
    var program_path: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var version_num: Float64
    var s_version_num: String
    var ver_string: String
    var prog_name_conversion: String

fn set_this_version_variables(inout flags: GlobalFlags) -> None:
    flags.ver_string = String("Conversion 9.4 => 9.5")
    flags.version_num = 9.5
    flags.s_version_num = String("9.5")
    flags.idd_file_name_with_path = flags.program_path + String("V9-4-0-Energy+.idd")
    flags.new_idd_file_name_with_path = flags.program_path + String("V9-5-0-Energy+.idd")
    flags.rep_var_file_name_with_path = flags.program_path + String("Report Variables 9-4-0 to 9-5-0.csv")

@export
fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout idf_data: IDFData,
    inout obj_def_data: ObjectDefData,
    inout field_data: FieldData,
    inout new_field_data: NewFieldData,
    inout report_var_data: ReportVarData,
    inout caution_tracking: CautionTracking,
    inout not_in_new: DynamicVector[String],
    inout flags: GlobalFlags
) -> None:
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = String(" ")
    end_of_file = False
    var ios: Int = 0

    while still_working:
        var exit_because_bad_file: Bool = False
        while not end_of_file:
            var full_file_name: String = String("")
            if ask_for_input:
                print(String("Enter input file name, with path"))
                # Note: actual input would go here
            else:
                if not arg_file:
                    # Read from file in_lfn
                    full_file_name = String("")
                    ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = String("")
                    ios = 1

                if full_file_name.data[0] == ord("!"):
                    full_file_name = String("")
                    continue

            var units_arg: String = String("")
            if ios != 0:
                full_file_name = String("")
            # full_file_name = ADJUSTL(full_file_name)

            if full_file_name != String(""):
                var dot_pos: Int = full_file_name.rfind(String("."))
                var file_name_path: String = String("")
                if dot_pos >= 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:]
                else:
                    file_name_path = full_file_name
                    print(String(" assuming file extension of .idf"))
                    full_file_name = full_file_name + String(".idf")
                    local_file_extension = String("idf")

                var dif_lfn: Int = 0  # GetNewUnitNumber()
                var file_ok: Bool = False
                # Check if file exists
                # file_ok = os.path.exists(full_file_name)

                if not file_ok:
                    print(String("File not found=") + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break

                if local_file_extension == String("idf") or local_file_extension == String("imf"):
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False

                    var out_file_name: String = String("")
                    if diff_only:
                        out_file_name = file_name_path + String(".") + local_file_extension + String("dif")
                    else:
                        out_file_name = file_name_path + String(".") + local_file_extension + String("new")

                    if local_file_extension == String("imf"):
                        flags.processing_imf_file = True
                    else:
                        flags.processing_imf_file = False

                    # ProcessInput(flags.idd_file_name_with_path, flags.new_idd_file_name_with_path, full_file_name, idf_data, flags)

                    if flags.fatal_error:
                        exit_because_bad_file = True
                        break

                    # Clear arrays
                    for i in range(len(field_data.alphas)):
                        field_data.alphas[i] = String("")
                    for i in range(len(field_data.numbers)):
                        field_data.numbers[i] = 0.0
                    for i in range(len(field_data.in_args)):
                        field_data.in_args[i] = String("")
                    for i in range(len(field_data.out_args)):
                        field_data.out_args[i] = String("")

                    var delete_this_record: DynamicVector[Bool] = DynamicVector[Bool]()
                    for _ in range(idf_data.num_idf_records):
                        delete_this_record.push_back(False)

                    no_version = True
                    for num in range(idf_data.num_idf_records):
                        # if MakeUPPERCase(idf_data.idf_records[num].name) != 'VERSION': continue
                        # no_version = False
                        # break
                        pass

                    var wwhp_eq_ft_cool_index: Int = 0
                    var wwhp_eq_ft_heat_index: Int = 0
                    var wahp_eq_ft_cool_index: Int = 0
                    var wahp_eq_ft_heat_index: Int = 0

                    for num in range(idf_data.num_idf_records):
                        if delete_this_record[num]:
                            continue

                        var object_name: String = idf_data.idf_records[num].name
                        var no_diff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        var cur_args: Int = 0

                        if not flags.making_pretty:
                            var upper_name: String = object_name
                            # upper_name = MakeUPPERCase(upper_name)

                            if upper_name == String("VERSION"):
                                # GetNewObjectDefInIDD(object_name, new_field_data, flags)
                                field_data.out_args[0] = flags.s_version_num
                                no_diff = False

                            elif upper_name == String("CONSTRUCTION:AIRBOUNDARY"):
                                no_diff = False
                                field_data.out_args[0] = field_data.in_args[0]
                                for i in range(cur_args - 2):
                                    field_data.out_args[i + 1] = field_data.in_args[i + 3]
                                cur_args = cur_args - 2

                            elif upper_name == String("COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT"):
                                no_diff = False
                                for i in range(10):
                                    field_data.out_args[i] = field_data.in_args[i]
                                for i in range(cur_args - 13):
                                    field_data.out_args[i + 13] = field_data.in_args[i + 26]
                                wahp_eq_ft_cool_index += 1
                                cur_args = cur_args - 13
                                written = True

                            elif upper_name == String("COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT"):
                                no_diff = False
                                for i in range(9):
                                    field_data.out_args[i] = field_data.in_args[i]
                                wahp_eq_ft_heat_index += 1
                                cur_args = cur_args - 8
                                written = True

                            elif upper_name == String("CONSTRUCTION:INTERNALSOURCE"):
                                written = True

                            elif upper_name == String("HEATPUMP:WATERTOWATER:EQUATIONFIT:COOLING"):
                                no_diff = False
                                for i in range(9):
                                    field_data.out_args[i] = field_data.in_args[i]
                                for i in range(cur_args - 8):
                                    field_data.out_args[i + 11] = field_data.in_args[i + 19]
                                wwhp_eq_ft_cool_index += 1
                                cur_args = cur_args - 8
                                written = True

                            elif upper_name == String("HEATPUMP:WATERTOWATER:EQUATIONFIT:HEATING"):
                                no_diff = False
                                for i in range(9):
                                    field_data.out_args[i] = field_data.in_args[i]
                                for i in range(cur_args - 8):
                                    field_data.out_args[i + 11] = field_data.in_args[i + 19]
                                wwhp_eq_ft_heat_index += 1
                                cur_args = cur_args - 8
                                written = True

                            elif upper_name == String("ZONEAIRMASSFLOWCONSERVATION"):
                                no_diff = False
                                for i in range(cur_args):
                                    field_data.out_args[i] = field_data.in_args[i]
                                if field_data.out_args[0] == String("YES") or field_data.out_args[0] == String("Yes") or field_data.out_args[0] == String("yes"):
                                    field_data.out_args[0] = String("AdjustMixingOnly")
                                if field_data.out_args[0] == String("NO") or field_data.out_args[0] == String("No") or field_data.out_args[0] == String("no"):
                                    field_data.out_args[0] = String("None")

                            elif upper_name == String("ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW"):
                                field_data.out_args[0] = field_data.in_args[0]
                                field_data.out_args[1] = field_data.in_args[0] + String(" Design Object")
                                for i in range(3):
                                    field_data.out_args[i + 2] = field_data.in_args[i + 1]
                                field_data.out_args[5] = field_data.in_args[7]
                                field_data.out_args[6] = field_data.in_args[12]
                                for i in range(3):
                                    field_data.out_args[i + 7] = field_data.in_args[i + 15]
                                field_data.out_args[10] = field_data.in_args[21]
                                for i in range(3):
                                    field_data.out_args[i + 11] = field_data.in_args[i + 24]
                                for i in range(2):
                                    field_data.out_args[i + 14] = field_data.in_args[i + 31]
                                cur_args = 16
                                no_diff = False

                            elif upper_name == String("ZONEHVAC:LOWTEMPERATURERADIANT:CONSTANTFLOW"):
                                field_data.out_args[0] = field_data.in_args[0]
                                field_data.out_args[1] = field_data.in_args[0] + String(" Design Object")
                                for i in range(3):
                                    field_data.out_args[i + 2] = field_data.in_args[i + 1]
                                field_data.out_args[5] = field_data.in_args[7]
                                for i in range(4):
                                    field_data.out_args[i + 6] = field_data.in_args[i + 11]
                                for i in range(12):
                                    field_data.out_args[i + 10] = field_data.in_args[i + 17]
                                for i in range(2):
                                    field_data.out_args[i + 22] = field_data.in_args[i + 31]
                                cur_args = 24
                                no_diff = False

                            elif upper_name == String("ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER"):
                                field_data.out_args[0] = field_data.in_args[0]
                                field_data.out_args[1] = field_data.in_args[0] + String(" Design Object")
                                for i in range(5):
                                    field_data.out_args[i + 2] = field_data.in_args[i + 1]
                                field_data.out_args[7] = field_data.in_args[7]
                                field_data.out_args[8] = field_data.in_args[10]
                                if cur_args > 14:
                                    for i in range(cur_args - 14):
                                        field_data.out_args[i + 9] = field_data.in_args[i + 14]
                                    cur_args = cur_args - 5
                                else:
                                    cur_args = 9
                                no_diff = False

                            elif upper_name == String("ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM"):
                                field_data.out_args[0] = field_data.in_args[0]
                                field_data.out_args[1] = field_data.in_args[0] + String(" Design Object")
                                for i in range(3):
                                    field_data.out_args[i + 2] = field_data.in_args[i + 1]
                                field_data.out_args[5] = field_data.in_args[5]
                                for i in range(2):
                                    field_data.out_args[i + 6] = field_data.in_args[i + 8]
                                if cur_args > 13:
                                    for i in range(cur_args - 13):
                                        field_data.out_args[i + 8] = field_data.in_args[i + 13]
                                    cur_args = cur_args - 5
                                else:
                                    cur_args = 8
                                no_diff = False

                            elif upper_name == String("OUTPUT:VARIABLE"):
                                no_diff = True
                                if field_data.out_args[0] == String(""):
                                    field_data.out_args[0] = String("*")
                                    no_diff = False

                            elif upper_name == String("OUTPUT:TABLE:MONTHLY"):
                                no_diff = True

                            elif upper_name == String("METER:CUSTOM") or upper_name == String("METER:CUSTOMDECREMENT"):
                                no_diff = True

                            else:
                                # Default case
                                for i in range(cur_args):
                                    field_data.out_args[i] = field_data.in_args[i]
                                no_diff = True

                        else:
                            # Making pretty
                            for i in range(cur_args):
                                field_data.out_args[i] = field_data.in_args[i]

                        if diff_min_fields and no_diff:
                            for i in range(cur_args):
                                field_data.out_args[i] = field_data.in_args[i]
                            no_diff = False
                            for arg in range(cur_args, new_field_data.nw_obj_min_flds):
                                field_data.out_args[arg] = new_field_data.nw_fld_defaults[arg]
                            cur_args = max(new_field_data.nw_obj_min_flds, cur_args)

                        if no_diff and diff_only:
                            continue

                        if not written:
                            # CheckSpecialObjects
                            pass

                        if not written:
                            # WriteOutIDFLines
                            pass

                    # End of record loop

            else:
                end_of_file = True

        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False

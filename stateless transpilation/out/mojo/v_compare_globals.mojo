# EXTERNAL DEPS (to wire in glue):
# - MAX_NAME_LENGTH: from DataGlobals module

alias MAX_NAME_LENGTH = 32
alias SIZEOFAPPNAME = 100

alias MISMATCH_UNITS = 8
alias DIFF_NUM_PARAMS = 1
alias MISMATCH_FIELDS = 4
alias MISMATCH_ARGS = 2

fn _get_diff_index() -> InlineArray[Int32, 8]:
    return InlineArray[Int32, 8](
        DIFF_NUM_PARAMS,
        MISMATCH_ARGS,
        MISMATCH_FIELDS,
        MISMATCH_UNITS,
        MISMATCH_FIELDS + MISMATCH_UNITS,
        DIFF_NUM_PARAMS + MISMATCH_FIELDS,
        DIFF_NUM_PARAMS + MISMATCH_UNITS,
        DIFF_NUM_PARAMS + MISMATCH_UNITS + MISMATCH_FIELDS
    )

fn _get_diff_description() -> InlineArray[StringLiteral, 9]:
    return InlineArray[StringLiteral, 9](
        "<unknown>                          ",
        "Diff # Fields                      ",
        "Arg Type (A-N) Mismatch            ",
        "Field Name Change                  ",
        "Units Change                       ",
        "Units Chg+Field Name Chg           ",
        "#Fields+Field Name Chg             ",
        "#Fields+Units Change               ",
        "#Fields+Field Name Chg+Units Change"
    )

struct ObjectStatus:
    var name: String
    var same: Bool
    var status_flag: Int32
    var old_index: Int32
    var new_index: Int32
    var units_matched: Bool
    var field_name_match: DynamicVector[Bool]
    var units_match: DynamicVector[String]
    
    fn __init__(inout self):
        self.name = " "
        self.same = True
        self.status_flag = 0
        self.old_index = 0
        self.new_index = 0
        self.units_matched = False
        self.field_name_match = DynamicVector[Bool]()
        self.units_match = DynamicVector[String]()

struct VCompareGlobalState:
    var gh_instance: Int32
    var gh_module: Int32
    var ghwnd_main: Int32
    var gh_menu: Int32
    
    var full_file_name: String
    var file_name_path: String
    var full_file_name_length: Int32
    var file_name_path_length: Int32
    var file_error_message: String
    var file_ok: Bool
    var cur_work_dir: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var with_units: Bool
    var leave_blank: Bool
    var auditf: Int32
    var version_num: Float32
    
    var obj_status: DynamicVector[ObjectStatus]
    var num_obj_stats: Int32
    var not_in_new: DynamicVector[String]
    var not_in_old: DynamicVector[String]
    var obs_object: DynamicVector[String]
    var obs_obj_rep_name: DynamicVector[String]
    var num_obs_objs: Int32
    var n_new: Int32
    var n_old: Int32
    var num_dif: Int32
    var fld_names: DynamicVector[String]
    var fld_defaults: DynamicVector[String]
    var fld_units: DynamicVector[String]
    var obj_min_flds: Int32
    var a_or_n: DynamicVector[Bool]
    var req_fld: DynamicVector[Bool]
    var num_args: Int32
    var nw_fld_names: DynamicVector[String]
    var nw_fld_defaults: DynamicVector[String]
    var nw_fld_units: DynamicVector[String]
    var nw_obj_min_flds: Int32
    var nw_a_or_n: DynamicVector[Bool]
    var nw_req_fld: DynamicVector[Bool]
    var nw_num_args: Int32
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[String]
    var num_alphas: Int32
    var num_numbers: Int32
    var out_args: DynamicVector[String]
    var match_arg: DynamicVector[Int32]
    var in_args: DynamicVector[String]
    var temp_args: DynamicVector[String]
    
    var old_rep_var_name: DynamicVector[String]
    var new_rep_var_name: DynamicVector[String]
    var new_rep_var_caution: DynamicVector[String]
    var out_var_caution: DynamicVector[Bool]
    var mtr_var_caution: DynamicVector[Bool]
    var time_bin_var_caution: DynamicVector[Bool]
    var otm_var_caution: DynamicVector[Bool]
    var num_rep_var_names: Int32
    
    var making_pretty: Bool
    var object_found_counts: DynamicVector[Int32]
    var object_found_file: DynamicVector[String]
    var report_names: DynamicVector[String]
    var report_names_counts: DynamicVector[Int32]
    var report_name_file: DynamicVector[String]
    var tmp_report_names: DynamicVector[String]
    var tmp_report_names_counts: DynamicVector[Int32]
    var num_report_names: Int32
    var max_report_names: Int32
    
    var input_file_path: String
    var use_input_file_path: Bool
    var processing_imf_file: Bool
    
    var old_object_names: DynamicVector[String]
    var new_object_names: DynamicVector[String]
    var num_renamed_objects: Int32
    
    fn __init__(inout self):
        self.gh_instance = 0
        self.gh_module = 0
        self.ghwnd_main = 0
        self.gh_menu = 0
        
        self.full_file_name = ""
        self.file_name_path = ""
        self.full_file_name_length = 0
        self.file_name_path_length = 0
        self.file_error_message = ""
        self.file_ok = False
        self.cur_work_dir = ""
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.with_units = False
        self.leave_blank = False
        self.auditf = 0
        self.version_num = 0.0
        
        self.obj_status = DynamicVector[ObjectStatus]()
        self.num_obj_stats = 0
        self.not_in_new = DynamicVector[String]()
        self.not_in_old = DynamicVector[String]()
        self.obs_object = DynamicVector[String]()
        self.obs_obj_rep_name = DynamicVector[String]()
        self.num_obs_objs = 0
        self.n_new = 0
        self.n_old = 0
        self.num_dif = 0
        self.fld_names = DynamicVector[String]()
        self.fld_defaults = DynamicVector[String]()
        self.fld_units = DynamicVector[String]()
        self.obj_min_flds = 0
        self.a_or_n = DynamicVector[Bool]()
        self.req_fld = DynamicVector[Bool]()
        self.num_args = 0
        self.nw_fld_names = DynamicVector[String]()
        self.nw_fld_defaults = DynamicVector[String]()
        self.nw_fld_units = DynamicVector[String]()
        self.nw_obj_min_flds = 0
        self.nw_a_or_n = DynamicVector[Bool]()
        self.nw_req_fld = DynamicVector[Bool]()
        self.nw_num_args = 0
        self.alphas = DynamicVector[String]()
        self.numbers = DynamicVector[String]()
        self.num_alphas = 0
        self.num_numbers = 0
        self.out_args = DynamicVector[String]()
        self.match_arg = DynamicVector[Int32]()
        self.in_args = DynamicVector[String]()
        self.temp_args = DynamicVector[String]()
        
        self.old_rep_var_name = DynamicVector[String]()
        self.new_rep_var_name = DynamicVector[String]()
        self.new_rep_var_caution = DynamicVector[String]()
        self.out_var_caution = DynamicVector[Bool]()
        self.mtr_var_caution = DynamicVector[Bool]()
        self.time_bin_var_caution = DynamicVector[Bool]()
        self.otm_var_caution = DynamicVector[Bool]()
        self.num_rep_var_names = 0
        
        self.making_pretty = False
        self.object_found_counts = DynamicVector[Int32]()
        self.object_found_file = DynamicVector[String]()
        self.report_names = DynamicVector[String]()
        self.report_names_counts = DynamicVector[Int32]()
        self.report_name_file = DynamicVector[String]()
        self.tmp_report_names = DynamicVector[String]()
        self.tmp_report_names_counts = DynamicVector[Int32]()
        self.num_report_names = 0
        self.max_report_names = 0
        
        self.input_file_path = ""
        self.use_input_file_path = False
        self.processing_imf_file = False
        
        self.old_object_names = DynamicVector[String]()
        self.new_object_names = DynamicVector[String]()
        self.num_renamed_objects = 0

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
from sscdev import SCFrame, SCApp, app_frame, app_config, applog
from dataview import DataView
from scripting import EditorWindow
from dllinvoke import sscdll_isloaded, sscdll_load, sscdll_unload, sscdll_error, ssc_module_t, ssc_data_t, ssc_module_create, ssc_module_free, ssc_module_var_info, ssc_module_entry, ssc_entry_t, ssc_entry_name, ssc_info_t, ssc_info_var_type, ssc_info_data_type, ssc_info_name, ssc_info_label, ssc_info_units, ssc_info_meta, ssc_info_group, ssc_info_required, ssc_info_constraints, ssc_data_create, ssc_data_clear, ssc_data_set_string, ssc_data_set_number, ssc_data_set_array, ssc_data_set_matrix, ssc_data_set_table, ssc_data_first, ssc_data_query, ssc_data_get_string, ssc_data_get_number, ssc_data_get_array, ssc_data_get_matrix, ssc_data_get_table, ssc_data_next, ssc_data_free, ssc_module_exec_with_handler, ssc_version, ssc_build_info, ssc_number_t, ssc_bool_t, ssc_handler_t, SSC_INPUT, SSC_OUTPUT, SSC_INOUT, SSC_STRING, SSC_NUMBER, SSC_ARRAY, SSC_MATRIX, SSC_TABLE, SSC_LOG, SSC_NOTICE, SSC_WARNING, SSC_ERROR, SSC_UPDATE
from var_table import var_table, var_data
from wx import *
from wx.wfstream import *
from wx.datstrm import *
from wx.imaglist import *
from wx.dynlib import *
from wx.config import *
from wx.scrolbar import *
from wx.print import *
from wx.printdlg import *
from wx.accel import *
from wx.image import *
from wx.fs_zip import *
from wx.html.htmlwin import *
from wx.snglinst import *
from wx.progdlg import *
from wx.busyinfo import *
from wx.dir import *
from wx.stdpaths import *
from wx.generic.helpext import *
from wx.clipbrd import *
from wx.splitter import *
from wx.statline import *
from wx.filepicker import *
from wx.grid import *
from wx.notebook import *
from wex.lkscript import *
from wex.metro import *
from wex.extgrid import *

# ifdef _MSC_VER
# 	ifdef _WIN64
# 	define PLAT_BITS 64
# 	else
# 	define PLAT_BITS 32
# 	endif
# else
# define PLAT_BITS 64
# endif

alias PLAT_BITS = 64

# /* exported application global variables */
var app_frame: SCFrame = None
var app_config: wxConfig = None

def applog(s: wxString):
	if app_frame:
		app_frame.Log(s)

# /* ************************************************************
#    ************ SC Application (set up handlers/config) ******
#    ************************************************************ */

# IMPLEMENT_APP(SCApp)

def SCApp.OnInit() -> bool:
	# ifdef __WXMSW__
	#     typedef BOOL (WINAPI *SetProcessDPIAware_t)(void); 
	#     wxDynamicLibrary dllUser32(wxT("user32.dll")); 
	#     SetProcessDPIAware_t pfnSetProcessDPIAware = 
	#         (SetProcessDPIAware_t)dllUser32.RawGetSymbol(wxT("SetProcessDPIAware")); 
	#     if ( pfnSetProcessDPIAware ) 
	#         pfnSetProcessDPIAware(); 
	# endif
	SetAppName("SDKtool")
	if argc > 0:
		wxSetWorkingDirectory(wxPathOnly(argv[0]))
	app_config = wxConfig("ssc-sdk-tool", "WXAPPS")
	wxInitAllImageHandlers()
	wxFileSystem.AddHandler(wxZipFSHandler())
	app_frame = SCFrame()
	SetTopWindow(app_frame)
	app_frame.Show()
	if argc > 1:
		if argv[1].Right(3).Lower() == ".lk":
			app_frame.LoadScript(argv[1])
		else:
			app_frame.LoadBdat(argv[1])
	var first_load = True
	var fl_key = "first_load"
	app_config.Read(fl_key, &first_load, True)
	if first_load:
		app_config.Write(fl_key, False)
		app_frame.SetPosition(wxPoint(10, 10))
		app_frame.SetClientSize(700, 600)
		var dll_path: wxString
		app_config.Read(wxString.Format("DllPath{}", PLAT_BITS), &dll_path)
		if not wxFileExists(dll_path):
			if wxYES == wxMessageBox("The SSC dynamic library is not loaded.  "
				"Would you like to select the proper library?\n\n"
				"Your selection will be saved for the next time you run SSC SDKtool.",
				"Notice - first load", wxYES_NO, app_frame):
				app_frame.ChooseDynamicLibrary()
	return True

def SCApp.OnExit() -> int:
	if app_config:
		del app_config
	return 0

enum ID_LOAD_UNLOAD_DLL = wxID_HIGHEST + 1248
enum ID_CHOOSE_DLL = wxID_HIGHEST + 1249
enum ID_LOAD_BDAT = wxID_HIGHEST + 1250
enum ID_SAVE_BDAT = wxID_HIGHEST + 1251
enum ID_CopyToClipboardCM = wxID_HIGHEST + 1252
enum ID_listCM = wxID_HIGHEST + 1253
enum ID_gridCM = wxID_HIGHEST + 1254

# BEGIN_EVENT_TABLE(SCFrame, wxFrame)
# 	EVT_BUTTON(ID_LOAD_BDAT, SCFrame::OnCommand)
# 	EVT_BUTTON(ID_SAVE_BDAT, SCFrame::OnCommand)
# 	EVT_BUTTON( wxID_EXECUTE, SCFrame::OnCommand )
# 	EVT_BUTTON( ID_LOAD_UNLOAD_DLL,       SCFrame::OnCommand )
# 	EVT_BUTTON( ID_CHOOSE_DLL,            SCFrame::OnCommand )
# 	EVT_LISTBOX(ID_listCM, SCFrame::OnCMListSelect )
# 	EVT_BUTTON(ID_CopyToClipboardCM, SCFrame::OnCopyToClipboard )
# 	EVT_CLOSE( SCFrame::OnCloseFrame )
# END_EVENT_TABLE()

def SCFrame.__init__(self):
	wxFrame.__init__(self, None, wxID_ANY, wxString.Format("SSC SDKtool ({} bit)", PLAT_BITS), wxDefaultPosition, wxSize(800, 600))
	self.m_varTable = var_table()
	# ifdef __WXMSW__
	# 	SetIcon( wxIcon("appicon") );
	# endif
	self.m_statusLabel = wxStaticText(self, wxID_ANY, "Ready")
	self.m_progressBar = wxGauge(self, wxID_ANY, 100)
	self.m_progressBar.Hide()
	var split_win = wxSplitterWindow(self, wxID_ANY,
		wxPoint(0, 0), wxSize(800, 700), wxSP_LIVE_UPDATE | wxBORDER_NONE)
	self.m_notebook = wxMetroNotebook(split_win, wxID_ANY)
	var cm_browser = wxPanel(self.m_notebook)
	self.m_currentCM = wxChoice(cm_browser, wxID_ANY)
	self.m_listCM = wxListBox(cm_browser, ID_listCM)
	self.m_gridCM = wxExtGridCtrl(cm_browser, wxID_ANY)
	self.m_gridCM.CreateGrid(2, 2)
	self.m_gridCM.EnableEditing(False)
	self.m_gridCM.DisableDragCell()
	self.m_gridCM.DisableDragColSize()
	self.m_gridCM.DisableDragRowSize()
	self.m_gridCM.DisableDragColMove()
	self.m_gridCM.DisableDragGridSize()
	self.m_gridCM.SetRowLabelSize(23)
	self.m_gridCM.SetColLabelSize(23)
	self.m_gridCM.EnableDragColSize()
	var szh_run = wxBoxSizer(wxHORIZONTAL)
	szh_run.Add(self.m_currentCM, 1, wxALL | wxEXPAND, 3)
	szh_run.Add(wxButton(cm_browser, wxID_EXECUTE, "Run", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxALIGN_CENTER_VERTICAL, 3)
	var szleft = wxBoxSizer(wxVERTICAL)
	szleft.Add(wxStaticText(cm_browser, wxID_ANY, " Available modules:"), 0, wxALL | wxEXPAND, 1)
	szleft.Add(self.m_listCM, 1, wxALL | wxEXPAND, 3)
	szleft.Add(wxButton(cm_browser, ID_CopyToClipboardCM, "Copy table to clipboard...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 3)
	szleft.Add(wxStaticLine(cm_browser, wxID_ANY), 0, wxALL | wxEXPAND, 2)
	szleft.Add(szh_run, 0, wxALL | wxEXPAND, 3)
	var szcenter = wxBoxSizer(wxHORIZONTAL)
	szcenter.Add(szleft, 1, wxALL | wxEXPAND, 0)
	szcenter.Add(self.m_gridCM, 5, wxALL | wxEXPAND, 0)
	var szmaintools = wxBoxSizer(wxHORIZONTAL)
	szmaintools.Add(wxButton(cm_browser, ID_LOAD_UNLOAD_DLL, "Load/unload library", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
	szmaintools.Add(wxButton(cm_browser, ID_CHOOSE_DLL, "Choose SSC library...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
	szmaintools.Add(wxButton(cm_browser, ID_LOAD_BDAT, "Load data file...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
	szmaintools.Add(wxButton(cm_browser, ID_SAVE_BDAT, "Save data file...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
	szmaintools.AddStretchSpacer()
	var szvertmain = wxBoxSizer(wxVERTICAL)
	szvertmain.Add(szmaintools, 0, wxALL | wxEXPAND, 2)
	szvertmain.Add(szcenter, 1, wxALL | wxEXPAND, 0)
	cm_browser.SetSizer(szvertmain)
	self.m_dataView = DataView(self.m_notebook)
	self.m_dataView.SetDataObject(self.m_varTable)
	self.m_scriptWindow = EditorWindow(self.m_notebook)
	self.m_notebook.AddPage(cm_browser, "Module Browser", True)
	self.m_notebook.AddPage(self.m_dataView, "Data Container", False)
	self.m_notebook.AddPage(self.m_scriptWindow, "Script Editor", False)
	self.m_txtOutput = wxTextCtrl(split_win, wxID_ANY, wxEmptyString, wxDefaultPosition, wxDefaultSize,
		wxTE_READONLY | wxTE_MULTILINE | wxHSCROLL | wxTE_DONTWRAP | wxBORDER_NONE)
	self.m_txtOutput.SetFont(wxFont(10, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, False, "consolas"))
	self.m_txtOutput.SetForegroundColour(*wxBLUE)
	split_win.SplitHorizontally(self.m_notebook, self.m_txtOutput, -180)
	split_win.SetSashGravity(1)
	var sz_stat = wxBoxSizer(wxHORIZONTAL)
	sz_stat.Add(self.m_progressBar, 1, wxALL | wxEXPAND, 3)
	sz_stat.Add(self.m_statusLabel, 5, wxALL | wxEXPAND, 3)
	var sz_main = wxBoxSizer(wxVERTICAL)
	sz_main.Add(split_win, 1, wxALL | wxEXPAND, 0)
	sz_main.Add(sz_stat, 0, wxALL | wxEXPAND, 0)
	SetSizer(sz_main)
	app_config.Read("CurrentDirectory", &self.m_currentAppDir)
	var b_maximize = False
	var f_x, f_y, f_width, f_height: int
	app_config.Read("FrameX", &f_x, -1)
	app_config.Read("FrameY", &f_y, -1)
	app_config.Read("FrameWidth", &f_width, -1)
	app_config.Read("FrameHeight", &f_height, -1)
	app_config.Read("FrameMaximized", &b_maximize, False)
	if b_maximize:
		self.Maximize()
	else:
		if f_width > 100 and f_height > 100:
			self.SetClientSize(f_width, f_height)
		if f_x > 0 and f_y > 0:
			self.SetPosition(wxPoint(f_x, f_y))
	UpdateUI()
	var dll_path: wxString
	app_config.Read(wxString.Format("DllPath{}", PLAT_BITS), &dll_path)
	if wxFileExists(dll_path):
		self.m_dllPath = dll_path
		LoadUnloadLibrary()
	var entries = wxAcceleratorEntry[10]()
	entries[0].Set(wxACCEL_CMD, 's', wxID_SAVE)
	entries[1].Set(wxACCEL_CMD, 'o', wxID_OPEN)
	entries[2].Set(wxACCEL_NORMAL, WXK_F5, wxID_EXECUTE)
	var acceltab = wxAcceleratorTable(3, entries)
	SetAcceleratorTable(acceltab)

def SCFrame.UpdateIsStopFlagSet(self) -> bool:
	return self.m_scriptWindow.GetEditor().IsStopFlagSet()

def SCFrame.__del__(self):
	del self.m_varTable

def SCFrame.SetProgress(self, percent: int, msg: wxString):
	self.m_progressBar.SetValue(percent)

def SCFrame.UpdateUI(self):
	var status: wxString
	if sscdll_isloaded():
		var ver = 0
		var build = "no info"
		try:
			ver = ssc_version()
			build = ssc_build_info()
		except sscdll_error as e:
			status = wxString(e.text.c_str()) + " "
			ver = -999
		status += self.m_dllPath + " Version " + wxString.Format("{}, {}", ver, build)
	else:
		status = "SSC dynamic library not loaded."
	self.m_statusLabel.SetLabel(status)

def SCFrame.OnCloseFrame(self, evt: wxCloseEvent):
	if evt.CanVeto() and not CloseDocument():
		evt.Veto()
		return
	# /* save window position */
	var b_maximize = self.IsMaximized()
	var f_x, f_y, f_width, f_height: int
	self.GetPosition(&f_x, &f_y)
	self.GetClientSize(&f_width, &f_height)
	app_config.Write("FrameX", f_x)
	app_config.Write("FrameY", f_y)
	app_config.Write("FrameWidth", f_width)
	app_config.Write("FrameHeight", f_height)
	app_config.Write("FrameMaximized", b_maximize)
	app_config.Write("CurrentDirectory", self.m_currentAppDir)
	app_config.Write(wxString.Format("DllPath{}", PLAT_BITS), self.m_dllPath)
	sscdll_unload() # make sure dll is unloaded;
	Destroy()

def SCFrame.SaveBdat(self):
	var dlg = wxFileDialog(self, "Save SDKtool State", wxPathOnly(self.m_lastFile),
		self.m_lastFile, "Binary Data File (*.bdat)|*.bdat", wxFD_SAVE)
	var ret = dlg.ShowModal()
	self.m_lastFile = dlg.GetPath()
	if ret != wxID_OK:
		return
	if not WriteBdatToDisk(self.m_lastFile):
		wxMessageBox("Error writing:\n\n" + self.m_lastFile)

def SCFrame.CloseDocument(self) -> bool:
	return self.m_scriptWindow.CloseDoc()

def SCFrame.LoadUnloadLibrary(self):
	if not sscdll_isloaded():
		if not sscdll_load(self.m_dllPath.c_str()):
			wxMessageBox("Error loading " + self.m_dllPath + "\n\nCheck path, architecture (32/64 bit), and version.")
			self.m_dllPath.Empty()
		else:
			self.m_currentAppDir = wxPathOnly(self.m_dllPath)
	else:
		sscdll_unload()
	UpdateCMForm()
	LoadCMs()
	UpdateUI()

def SCFrame.ChooseDynamicLibrary(self):
	var fd = wxFileDialog(self, "Choose SSC dynamic library", wxPathOnly(self.m_dllPath), self.m_dllPath,
		# ifdef __WXMSW__
		# 	"Dynamic Link Libraries (*.dll)|*.dll"
		# endif
		# ifdef __WXOSX__
		# 	"Dynamic Libraries (*.dylib)|*.dylib"
		# endif
		# ifdef __WXGTK__
		# 	"Shared Libraries (*.so)|*.so"
		# endif
		"Shared Libraries (*.so)|*.so"
		, wxFD_OPEN)
	if fd.ShowModal() != wxID_OK:
		return
	var file = fd.GetPath()
	self.m_dllPath = file
	self.m_currentAppDir = wxPathOnly(file)
	sscdll_unload()
	LoadUnloadLibrary()

def SCFrame.OnCommand(self, evt: wxCommandEvent):
	match evt.GetId():
		case wxID_EXECUTE:
			if self.m_notebook.GetSelection() == 0:
				app_frame.ClearLog()
				app_frame.Start()
			else:
				self.m_scriptWindow.Exec()
		case ID_LOAD_BDAT:
			LoadBdat()
		case ID_SAVE_BDAT:
			SaveBdat()
		case ID_LOAD_UNLOAD_DLL:
			LoadUnloadLibrary()
		case ID_CHOOSE_DLL:
			ChooseDynamicLibrary()

def SCFrame.WriteVarTable(self, o: wxDataOutputStream, vt: var_table):
	o.Write16(0xae) # start identifier, versioner
	o.Write32(vt.size())
	var key = vt.first()
	while key != 0:
		o.WriteString(key)
		var v = vt.lookup(key)
		o.Write8(v.type)
		match v.type:
			case SSC_STRING:
				o.WriteString(wxString(v.str.c_str()))
			case SSC_NUMBER:
				o.WriteDouble(v.num)
			case SSC_ARRAY:
				o.Write32(v.num.length())
				for i in range(v.num.length()):
					o.WriteDouble(v.num[i])
			case SSC_MATRIX:
				o.Write32(v.num.nrows())
				o.Write32(v.num.ncols())
				for r in range(v.num.nrows()):
					for c in range(v.num.ncols()):
						o.WriteDouble(v.num.at(r, c))
			case SSC_TABLE:
				WriteVarTable(o, v.table)
		key = vt.next()
	o.Write16(0xae) # end identifier

def SCFrame.ReadVarTable(self, o: wxDataInputStream, vt: var_table, clear_first: bool) -> bool:
	if clear_first:
		vt.clear()
	var code = o.Read16()
	var size = o.Read32()
	var len, nrows, ncols: size_t
	for nn in range(size):
		var vv = var_data()
		var key = o.ReadString()
		vv.type = o.Read8()
		match vv.type:
			case SSC_STRING:
				vv.str = o.ReadString().c_str()
			case SSC_NUMBER:
				vv.num = o.ReadDouble()
			case SSC_ARRAY:
				len = o.Read32()
				vv.num.resize(len)
				for i in range(len):
					vv.num[i] = o.ReadDouble()
			case SSC_MATRIX:
				nrows = o.Read32()
				ncols = o.Read32()
				vv.num.resize(nrows, ncols)
				for r in range(nrows):
					for c in range(ncols):
						vv.num.at(r, c) = o.ReadDouble()
			case SSC_TABLE:
				if not ReadVarTable(o, vv.table, True):
					return False
		vt.assign(key.ToStdString(), vv)
	return o.Read16() == code

def SCFrame.LoadScript(self, fn: wxString) -> bool:
	if fn.IsEmpty():
		var dlg = wxFileDialog(self, "Load lk script",
			wxPathOnly(self.m_lastFile),
			self.m_lastFile,
			"Script file (*.lk)|*.lk",
			wxFD_OPEN)
		if dlg.ShowModal() == wxID_OK:
			self.m_lastFile = dlg.GetPath()
			def = self.m_lastFile
		else:
			return False
	var ret = self.m_scriptWindow.Load(fn)
	self.m_notebook.SetSelection(2)
	return ret

def SCFrame.LoadBdat(self, fn: wxString) -> bool:
	if fn.IsEmpty():
		var dlg = wxFileDialog(self, "Load SDKtool State",
			wxPathOnly(self.m_lastFile),
			self.m_lastFile,
			"Binary Data File (*.bdat)|*.bdat",
			wxFD_OPEN)
		if dlg.ShowModal() == wxID_OK:
			self.m_lastFile = dlg.GetPath()
			def = self.m_lastFile
		else:
			return False
	var busy = wxBusyInfo("Loading: " + fn)
	var fp = wxFileInputStream(fn)
	if not fp.Ok():
		return False
	var in_ = wxDataInputStream(fp)
	self.m_varTable.clear()
	UpdateUI()
	self.m_dataView.UpdateView()
	var code = in_.Read16() # start header code, versioner
	var cm = in_.ReadString()
	SetCurrentCM(cm)
	var sel_vars = wxArrayString()
	var cwl = List[int]()
	var nn = in_.Read32()
	for i in range(nn):
		sel_vars.Add(in_.ReadString())
	nn = in_.Read32()
	for i in range(nn):
		cwl.append(in_.Read32())
	var vtok = ReadVarTable(in_, *self.m_varTable, True)
	self.m_dataView.UpdateView()
	self.m_dataView.SetSelections(sel_vars)
	self.m_dataView.UpdateView()
	self.m_dataView.SetColumnWidths(cwl)
	UpdateUI()
	return vtok and in_.Read16() == code

def SCFrame.WriteBdatToDisk(self, fn: wxString) -> bool:
	var busy = wxBusyInfo("Writing: " + fn)
	var fp = wxFileOutputStream(fn)
	if not fp.Ok():
		return False
	var o = wxDataOutputStream(fp)
	o.Write16(0xe3)
	var cm = GetCurrentCM()
	o.WriteString(cm)
	var selvars = self.m_dataView.GetSelections()
	o.Write32(selvars.Count())
	for i in range(selvars.Count()):
		o.WriteString(selvars[i])
	var cwl = self.m_dataView.GetColumnWidths()
	o.Write32(cwl.size())
	for i in range(cwl.size()):
		o.Write32(cwl[i])
	WriteVarTable(o, *self.m_varTable)
	o.Write16(0xe3)
	UpdateUI()
	return True

def SCFrame.Log(self, text: wxString, wnl: bool = True):
	if wnl:
		self.m_txtOutput.AppendText(text + "\n")
	else:
		self.m_txtOutput.AppendText(text)

def SCFrame.ClearLog(self):
	self.m_txtOutput.Clear()

# /*
# class default_sync_proc : public util::sync_piped_process
# {
# private:
# 	ssc_handler_t m_handler;
# public:
# 	default_sync_proc( ssc_handler_t ph ) : m_handler(ph) {  }
# 	void on_stdout(const string &line_text)
# 	{
# 		::ssc_module_extproc_output( m_handler, line_text.c_str() );
# 	}
# };
# */

def my_handler(p_mod: ssc_module_t, p_handler: ssc_handler_t, action: int,
	f0: float, f1: float, s0: str, s1: str, user_data: object) -> ssc_bool_t:
	if action == SSC_LOG:
		var msg: wxString
		match int(f0):
			case SSC_NOTICE:
				msg << "Notice: " << s0 << " time " << f1
			case SSC_WARNING:
				msg << "Warning: " << s0 << " time " << f1
			case SSC_ERROR:
				msg << "Error: " << s0 << " time " << f1
			case _:
				msg << "Log notice uninterpretable: " << f0 << " time " << f1
		app_frame.Log(msg)
		return 1
	elif action == SSC_UPDATE:
		app_frame.SetProgress(int(f0), s0)
		wxGetApp().Yield(True)
		return not app_frame.UpdateIsStopFlagSet()
	# /*
	# else if (action == SSC_EXECUTE)
	# {
	# 	default_sync_proc exe( p_handler );
	# 	return exe.spawn( s0, s1 ) == 0;
	# }
	# */
	else:
		return 0

def SCFrame.Copy(p_mod: ssc_module_t, p_data: ssc_data_t, vt: var_table, clear_first: bool):
	if clear_first:
		ssc_data_clear(p_data)
	var pidx = 0
	var p_inf = ssc_module_var_info(p_mod, pidx)
	while p_inf is not None:
		var var_type = ssc_info_var_type(p_inf)   # SSC_INPUT, SSC_OUTPUT, SSC_INOUT
		var name = ssc_info_name(p_inf) # assumed to be non-null
		var reqd = wxString(ssc_info_required(p_inf))
		if var_type == SSC_INPUT or var_type == SSC_INOUT:
			var v = vt.lookup(name)
			if v is not None:
				match v.type:
					case SSC_STRING:
						ssc_data_set_string(p_data, name, v.str.c_str())
					case SSC_NUMBER:
						ssc_data_set_number(p_data, name, v.num)
						var nm = wxString(name)
					case SSC_ARRAY:
						ssc_data_set_array(p_data, name, v.num.data(), v.num.length())
					case SSC_MATRIX:
						ssc_data_set_matrix(p_data, name, v.num.data(), v.num.nrows(), v.num.ncols())
					case SSC_TABLE:
						ssc_data_set_table(p_data, name, &v.table)
		pidx += 1
		p_inf = ssc_module_var_info(p_mod, pidx)

def SCFrame.Copy(vt: var_table, p_data: ssc_data_t, clear_first: bool):
	if clear_first:
		vt.clear()
	var name = ssc_data_first(p_data)
	while name is not None:
		var type = ssc_data_query(p_data, name)
		match type:
			case SSC_STRING:
				var s = ssc_data_get_string(p_data, name)
				if s is not None:
					vt.assign(name, var_data(str(s)))
			case SSC_NUMBER:
				var val: ssc_number_t = 0.0
				if ssc_data_get_number(p_data, name, &val):
					vt.assign(name, var_data(val))
				var nm = wxString(name)
			case SSC_ARRAY:
				var len: int = 0
				var pvals = ssc_data_get_array(p_data, name, &len)
				if pvals is not None:
					vt.assign(name, var_data(pvals, len))
			case SSC_MATRIX:
				var nrows: int = 0
				var ncols: int = 0
				var pmat = ssc_data_get_matrix(p_data, name, &nrows, &ncols)
				if pmat is not None:
					vt.assign(name, var_data(pmat, nrows, ncols))
			case SSC_TABLE:
				var table = ssc_data_get_table(p_data, name)
				var src = table as var_table
				var x = var_data()
				x.type = SSC_TABLE
				x.table = *src # deep copy
				vt.assign(name, x)
		name = ssc_data_next(p_data)

def SCFrame.Start(self) -> List[bool]:
	var ok = List[bool]()
	self.m_progressBar.Show()
	Layout()
	wxGetApp().Yield()
	var cm = GetCurrentCM()
	if cm.IsEmpty():
		wxMessageBox("No compute modules selected for simulation.\n\nSelect one or more on the Module Browser tab.")
		return ok
	try:
		var p_mod = ssc_module_create(cm.c_str())
		if p_mod != 0:
			var p_data = ssc_data_create()
			Copy(p_mod, p_data, self.m_varTable, True)
			var sw = wxStopWatch()
			sw.Start()
			if not ssc_module_exec_with_handler(p_mod, p_data,
				my_handler, 0):
				Log("EXEC_FAIL: " + cm)
				ok.append(False)
			else:
				ok.append(True)
			ssc_module_free(p_mod)
			Copy(self.m_varTable, p_data, False)
			ssc_data_free(p_data)
		else:
			Log("CREATE_FAIL: " + cm)
		self.m_dataView.UpdateView()
	except sscdll_error as e:
		wxMessageBox("Library error: " + wxString(e.func.c_str()) + ": " + wxString(e.text.c_str()))
	self.m_progressBar.Hide()
	Layout()
	return ok

def SCFrame.GetAvailableCMs(self) -> wxArrayString:
	var list = wxArrayString()
	try:
		var idx = 0
		var p_entry = ssc_module_entry(idx)
		while p_entry is not None:
			list.Add(ssc_entry_name(p_entry))
			idx += 1
			p_entry = ssc_module_entry(idx)
	except sscdll_error:

	return list

def SCFrame.LoadCMs(self):
	self.m_listCM.Clear()
	self.m_gridCM.ClearGrid()
	var l = GetAvailableCMs()
	for i in range(l.Count()):
		self.m_listCM.Append(l[i])

def SCFrame.OnCopyToClipboard(self, evt: wxCommandEvent):
	var info = wxBusyInfo("Copying data to clipboard...")
	self.m_gridCM.Copy(True)
	wxMilliSleep(350)

def SCFrame.OnCMListSelect(self, evt: wxCommandEvent):
	try:
		var cm_name = self.m_listCM.GetStringSelection()
		var p_mod = ssc_module_create(cm_name.c_str())
		if p_mod == 0:
			wxMessageBox("Could not create a module of type: " + cm_name)
			return
		var vartab = List[wxArrayString]()
		var idx = 0
		var p_inf = ssc_module_var_info(p_mod, idx)
		while p_inf is not None:
			var var_type = ssc_info_var_type(p_inf)   # SSC_INPUT, SSC_OUTPUT, SSC_INOUT
			var data_type = ssc_info_data_type(p_inf) # SSC_STRING, SSC_NUMBER, SSC_ARRAY, SSC_MATRIX
			var row = wxArrayString()
			match var_type:
				case SSC_INPUT:
					row.Add("SSC_INPUT")
				case SSC_OUTPUT:
					row.Add("SSC_OUTPUT")
				case SSC_INOUT:
					row.Add("SSC_INOUT")
				case _:
					row.Add("<unknown>")
			match data_type:
				case SSC_STRING:
					row.Add("SSC_STRING")
				case SSC_NUMBER:
					row.Add("SSC_NUMBER")
				case SSC_ARRAY:
					row.Add("SSC_ARRAY")
				case SSC_MATRIX:
					row.Add("SSC_MATRIX")
				case SSC_TABLE:
					row.Add("SSC_TABLE")
				case _:
					row.Add("<unknown>")
			row.Add(ssc_info_name(p_inf))
			row.Add(ssc_info_label(p_inf))
			row.Add(ssc_info_units(p_inf))
			row.Add(ssc_info_meta(p_inf))
			row.Add(ssc_info_group(p_inf))
			row.Add(ssc_info_required(p_inf))
			row.Add(ssc_info_constraints(p_inf))
			vartab.append(row)
			idx += 1
			p_inf = ssc_module_var_info(p_mod, idx)
		var nrows = vartab.size()
		var ncols = 9
		self.m_gridCM.Freeze()
		self.m_gridCM.ResizeGrid(nrows, ncols)
		self.m_gridCM.SetColLabelValue(0, "TYPE")
		self.m_gridCM.SetColLabelValue(1, "DATA")
		self.m_gridCM.SetColLabelValue(2, "NAME")
		self.m_gridCM.SetColLabelValue(3, "LABEL")
		self.m_gridCM.SetColLabelValue(4, "UNITS")
		self.m_gridCM.SetColLabelValue(5, "META")
		self.m_gridCM.SetColLabelValue(6, "GROUP")
		self.m_gridCM.SetColLabelValue(7, "REQUIRE")
		self.m_gridCM.SetColLabelValue(8, "CONSTRAINT")
		for r in range(nrows):
			for c in range(ncols):
				self.m_gridCM.SetCellValue(r, c, vartab[r][c])
		self.m_gridCM.AutoSizeColumns(False)
		self.m_gridCM.Thaw()
		ssc_module_free(p_mod)
	except sscdll_error as e:
		wxMessageBox("Dynamic library error: " + wxString(e.func.c_str()) + ": " + wxString(e.text.c_str()))

def SCFrame.UpdateCMForm(self):
	var sel = self.m_listCM.GetStringSelection()
	var run = self.m_currentCM.GetStringSelection()
	var list = GetAvailableCMs()
	self.m_listCM.Clear()
	self.m_listCM.Append(list)
	self.m_currentCM.Clear()
	self.m_currentCM.Append(list)
	if list.Index(sel) != wxNOT_FOUND:
		self.m_listCM.SetStringSelection(sel)
	if list.Index(run) != wxNOT_FOUND:
		self.m_currentCM.SetStringSelection(run)
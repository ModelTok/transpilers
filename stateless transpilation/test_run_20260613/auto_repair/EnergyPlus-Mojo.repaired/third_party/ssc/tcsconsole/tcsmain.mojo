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
INCLUDING, BUT NOT LIMITED TO, THE WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from tcskernel import tcskernel, tcsvalue, tcsvarinfo, tcstypeprovider, TCS_NUMBER, TCS_STRING, TCS_ARRAY, TCS_MATRIX, TCS_INVALID, TCS_MATRIX_INDEX
from tcslayout import tcLayoutCtrl
from tcsscript import tcScriptEditor
from tcsmain import tcFrame, tcKernel, ResultsTable, tcVisualEditor, tcApp, tcNotebook, tcsDVDataSet, Log, ClearLog, ID_SIMULATE, ID_GRID, ID_VARSELECTOR, ID_DVPLOT, ID_STARTTIME, ID_ENDTIME, ID_TIMESTEP, ID_MAXITER

def ClearLog():
    tcFrame.Instance().ClearLog()

def Log(text: String):
    tcFrame.Instance().Log(text)

def Log(fmt: String, *args...):
    var buf: StaticString[2048]
    var ap: va_list
    va_start(ap, fmt)
    #if defined(_MSC_VER)||defined(_WIN32)
    _vsnprintf(buf.data(), 2046, fmt.data(), ap)
    #else
    vsnprintf(buf.data(), 2046, fmt.data(), ap)
    #endif
    va_end(ap)
    tcFrame.Instance().Log(String(buf))

@value
struct tcKernel:
    var m_storeArrMatData: Bool
    var m_progressDialog: wxProgressDialog
    var m_frame: tcFrame
    var m_results: List[dataset]
    var m_start: Float64
    var m_end: Float64
    var m_step: Float64
    var m_dataIndex: Int
    var m_watch: wxStopWatch

    def __init__(inout self, frm: tcFrame, prov: tcstypeprovider):
        self.m_storeArrMatData = False
        self.m_frame = frm
        self.m_start = 0.0
        self.m_end = 0.0
        self.m_step = 0.0
        self.m_results = List[dataset]()
        self.m_dataIndex = 0
        self.m_watch = wxStopWatch()

    def __del__(owned self):

    def log(inout self, s: String):
        self.m_frame.Log(wxString(s))

    def converged(inout self, time: Float64) -> Bool:
        if self.m_step != 0.0 and self.m_progressDialog != 0:
            var istep: Int = (time - self.m_start) / self.m_step
            var nstep: Int = (self.m_end - self.m_start) / self.m_step
            var nnsteps: Int = nstep / 200
            if nnsteps == 0:
                nnsteps = 1
            if istep % nnsteps == 0:
                var percent: Float64 = 100.0 * (Float64(istep) / Float64(nstep))
                var elapsed: Float64 = self.m_watch.Time() * 0.001
                if not self.m_progressDialog.Update(Int(percent), wxString.Format("%.1lf %% complete, %.2lf seconds elapsed, hour %.1lf", percent, elapsed, time / 3600.0)):
                    return False
        var buf: String = ""
        var ibuf: StaticString[128]
        var j: Int
        var k: Int
        for i in range(len(self.m_results)):
            var v: tcsvalue = self.m_results[i].u.values[self.m_results[i].idx]
            if self.m_results[i].type == TCS_NUMBER:
                self.m_results[i].values[self.m_dataIndex].dval = v.data.value
            elif self.m_results[i].type == TCS_STRING:
                self.m_results[i].values[self.m_dataIndex].sval = v.data.cstr
            elif self.m_results[i].type == TCS_ARRAY:
                if self.m_storeArrMatData:
                    buf = "[ "
                    for j in range(v.data.array.length):
                        mysnprintf(ibuf.data(), 126, "%lg%c", v.data.array.values[j], ',' if j < v.data.array.length - 1 else ' ')
                        buf += String(ibuf)
                    buf += "]"
                    self.m_results[i].values[self.m_dataIndex].sval = buf
            elif self.m_results[i].type == TCS_MATRIX:
                if self.m_storeArrMatData:
                    mysnprintf(ibuf.data(), 126, "{ %dx%d ", v.data.matrix.nrows, v.data.matrix.ncols)
                    buf = String(ibuf)
                    for j in range(v.data.matrix.nrows):
                        buf += " ["
                        for k in range(v.data.matrix.ncols):
                            mysnprintf(ibuf.data(), 126, "%lg%c", TCS_MATRIX_INDEX(&v, j, k), ',' if k < v.data.matrix.ncols - 1 else ' ')
                            buf += String(ibuf)
                        buf += "]"
                    buf += " }"
                    self.m_results[i].values[self.m_dataIndex].sval = buf
        self.m_dataIndex += 1
        return True

    def simulate(inout self, start: Float64, end: Float64, step: Float64, pd: wxProgressDialog, time_sec: Pointer[Float64]) -> Int:
        var info: wxBusyInfo = wxBusyInfo("preparing simulation data vectors...")
        self.m_progressDialog = pd
        self.m_start = start
        self.m_end = end
        self.m_step = step
        self.m_dataIndex = 0
        if end <= start or step <= 0:
            del info
            return -77
        var nsteps: Int = (end - start) / step + 1
        var ndatasets: Int = 0
        for i in range(len(self.m_units)):
            var vars: Pointer[tcsvarinfo] = self.m_units[i].type.variables
            var idx: Int = 0
            while vars[idx].var_type != TCS_INVALID:
                idx += 1
                ndatasets += 1
        if ndatasets < 1:
            del info
            return -88
        self.m_results.resize(ndatasets)
        var idataset: Int = 0
        for i in range(len(self.m_units)):
            var vars: Pointer[tcsvarinfo] = self.m_units[i].type.variables
            var idx: Int = 0
            while vars[idx].var_type != TCS_INVALID:
                var d: dataset = self.m_results[idataset]
                idataset += 1
                var buf: StaticString[32]
                sprintf(buf.data(), "%d", i)
                d.u = &self.m_units[i]
                d.uidx = i
                d.idx = idx
                d.group = "Unit " + String(buf) + " (" + String(self.m_units[i].type.name) + ")"
                d.name = vars[idx].name
                d.units = vars[idx].units
                d.type = vars[idx].data_type
                d.values.resize(nsteps, dataitem(0.0))
                idx += 1
        del info
        wxGetApp().Yield(True)
        self.m_watch.Start()
        var code: Int = tcskernel.simulate(self, start, end, step)
        if time_sec:
            time_sec[] = Float64(self.m_watch.Time()) * 0.001
        return code

    def get_results(inout self, idx: Int) -> Pointer[dataset]:
        if idx >= len(self.m_results):
            return Pointer[dataset]()
        else:
            return Pointer[dataset](addressof(self.m_results[idx]))

@value
struct dataitem:
    var sval: String
    var dval: Float64

    def __init__(inout self, s: String):
        self.sval = s
        self.dval = 0.0

    def __init__(inout self, s: String):
        self.sval = s
        self.dval = 0.0

    def __init__(inout self, d: Float64):
        self.sval = ""
        self.dval = d

@value
struct dataset:
    var u: Pointer[unit]
    var uidx: Int
    var idx: Int
    var name: String
    var units: String
    var group: String
    var type: Int
    var values: List[dataitem]

@value
struct ResultsTable:
    var m_results: List[Pointer[tcKernel.dataset]]

    def __init__(inout self):
        self.m_results = List[Pointer[tcKernel.dataset]]()

    def AddResult(inout self, d: Pointer[tcKernel.dataset]):
        self.m_results.append(d)

    def GetNumberRows(inout self) -> Int:
        var nr: Int = 0
        for i in range(len(self.m_results)):
            if len(self.m_results[i].values) > nr:
                nr = len(self.m_results[i].values)
        return nr

    def GetNumberCols(inout self) -> Int:
        return len(self.m_results)

    def IsEmptyCell(inout self, row: Int, col: Int) -> Bool:
        return False

    def SetValue(inout self, row: Int, col: Int, value: String):

    def GetValue(inout self, row: Int, col: Int) -> String:
        if col < 0 or col >= len(self.m_results) or row < 0 or row >= len(self.m_results[col].values):
            return String()
        var it: tcKernel.dataitem = self.m_results[col].values[row]
        if self.m_results[col].type == TCS_NUMBER:
            return String.Format("%lf", it.dval)
        else:
            return String(it.sval)

    def GetColLabelValue(inout self, col: Int) -> String:
        if col < 0 or col >= len(self.m_results):
            return String()
        return String(self.m_results[col].group + "\n" + self.m_results[col].name + "\n(" + self.m_results[col].units + ")")

    def ReleasePointers(inout self):
        self.m_results.clear()

@value
struct tcFrame:
    var m_plot: wxDVPlotCtrl
    var m_grid: wxExtGridCtrl
    var m_textOut: wxTextCtrl
    var m_varSelector: wxCheckListBox
    var m_visualEditor: tcVisualEditor
    var m_scriptEditor: tcScriptEditor
    var m_notebook: wxMetroNotebook
    var m_kernel: tcKernel
    var m_provider: tcstypeprovider

    def __init__(inout self):
        self.m_plot = wxDVPlotCtrl()
        self.m_grid = wxExtGridCtrl()
        self.m_textOut = wxTextCtrl()
        self.m_varSelector = wxCheckListBox()
        self.m_visualEditor = tcVisualEditor()
        self.m_scriptEditor = tcScriptEditor()
        self.m_notebook = wxMetroNotebook()
        self.m_kernel = tcKernel()
        self.m_provider = tcstypeprovider()
        __g_tcframe = self
        SetTitle("TCS Console (" STR_BITS " bit)")
        #ifdef __WXMSW__
        SetIcon(wxIcon("appicon"))
        #endif
        var split: wxSplitterWindow = wxSplitterWindow(self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxSP_LIVE_UPDATE | wxSP_3DSASH)
        self.m_notebook = wxMetroNotebook(split, wxID_ANY)
        self.m_visualEditor = tcVisualEditor(self.m_notebook)
        self.m_notebook.AddPage(self.m_visualEditor, "Visual Editor")
        self.m_scriptEditor = tcScriptEditor(self.m_notebook)
        self.m_notebook.AddPage(self.m_scriptEditor, "Script Editor")
        self.m_plot = wxDVPlotCtrl(self.m_notebook, ID_DVPLOT)
        self.m_notebook.AddPage(self.m_plot, "Timeseries Graphs")
        var gpanel: wxPanel = wxPanel(self.m_notebook)
        self.m_varSelector = wxCheckListBox(gpanel, ID_VARSELECTOR)
        self.m_grid = wxExtGridCtrl(gpanel, ID_GRID)
        self.m_grid.DisableDragColMove()
        self.m_grid.SetRowLabelSize(-1)
        self.m_grid.SetColLabelSize(69)
        self.m_grid.SetDefaultCellAlignment(wxALIGN_LEFT, wxALIGN_CENTER)
        self.m_grid.SetRowLabelAlignment(wxALIGN_LEFT, wxALIGN_CENTER)
        var gpanel_sizer: wxBoxSizer = wxBoxSizer(wxHORIZONTAL)
        gpanel_sizer.Add(self.m_varSelector, 0, wxALL | wxEXPAND, 0)
        gpanel_sizer.Add(self.m_grid, 1, wxALL | wxEXPAND, 0)
        gpanel.SetSizer(gpanel_sizer)
        self.m_notebook.AddPage(gpanel, "Data Tables")
        self.m_textOut = wxTextCtrl(split, wxID_ANY, String(), wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE | wxTE_READONLY)
        var szmain: wxBoxSizer = wxBoxSizer(wxVERTICAL)
        szmain.Add(split, 1, wxALL | wxEXPAND, 0)
        SetSizer(szmain)
        Layout()
        split.SplitHorizontally(self.m_notebook, self.m_textOut, -200)
        split.SetSashGravity(0.9)
        split.SetMinimumPaneSize(100)
        Log("Current folder: " + wxGetCwd() + "\n\n")
        self.m_provider.add_search_path(".")
        self.m_provider.add_search_path("..")
        self.m_provider.add_search_path("../..")
        self.m_provider.add_search_path("../../..")
        self.m_provider.add_search_path("../../../..")
        self.m_provider.add_search_path(String(wxGetCwd()))
        self.m_kernel = tcKernel(self, &self.m_provider)
        var list: List[tcstypeprovider.typedata] = self.m_provider.types()
        for i in range(len(list)):
            self.m_visualEditor.GetLayout().AddType(wxString(list[i].type), list[i].info, wxString(list[i].dyn.path) if list[i].dyn else wxString())
        self.m_visualEditor.GetLayout().CreatePopupMenu()
        self.m_visualEditor.UpdateTypes()
        var sel: Int
        var file: String
        var cfg: wxConfig
        if cfg.Read("visual", &file) and not file.IsEmpty() and wxFileExists(file):
            self.m_visualEditor.LoadFile(file)
        if cfg.Read("script", &file) and not file.IsEmpty() and wxFileExists(file):
            self.m_scriptEditor.Load(file)
            wxSetWorkingDirectory(wxPathOnly(file))
        if cfg.Read("tabsel", &sel) and sel >= 0 and sel < self.m_notebook.GetPageCount():
            self.m_notebook.SetSelection(sel)

    def __del__(owned self):
        del self.m_kernel

    def GetTypeProvider(inout self) -> Pointer[tcstypeprovider]:
        return Pointer[tcstypeprovider](addressof(self.m_provider))

    def GetKernel(inout self) -> Pointer[tcKernel]:
        return Pointer[tcKernel](addressof(self.m_kernel))

    def Simulate(inout self, start: Float64, end: Float64, step: Float64, iter: Int, store_arrmat: Bool, proceed_anyway: Bool) -> Int:
        var view: wxDVPlotCtrlSettings = wxDVPlotCtrlSettings(self.m_plot.GetPerspective())
        self.m_plot.RemoveAllDataSets()
        Log(wxString.Format("*** simulating [%.2lf --> %.2lf] step %.2lf maxiter %d ***\n", start, end, step, iter))
        self.m_kernel.set_max_iterations(iter, proceed_anyway)
        self.m_kernel.set_store_array_matrix_data(store_arrmat)
        var progdlg: wxProgressDialog = wxProgressDialog("Simulation", "In progress...", 100, self, wxPD_CAN_ABORT | wxPD_AUTO_HIDE)
        progdlg.SetClientSize(400, 130)
        var pt: wxPoint = GetPosition()
        pt.x += 20
        pt.y += 20
        progdlg.SetPosition(pt)
        progdlg.Show()
        var time: Float64 = 0.0
        var code: Int = self.m_kernel.simulate(start, end, step, &progdlg, &time)
        Log(wxString.Format("\n*** simulator kernel finished in %.3lf sec with code %d ***\n\n", time, code))
        var info2: wxBusyInfo = wxBusyInfo("updating plots and data tables, please wait...")
        var selections: wxArrayString = wxArrayString()
        for i in range(self.m_varSelector.GetCount()):
            if self.m_varSelector.IsChecked(i):
                selections.Add(self.m_varSelector.GetString(i))
        var colsizes: List[Int] = List[Int]()
        for i in range(self.m_grid.GetNumberCols()):
            colsizes.append(self.m_grid.GetColSize(i))
        self.m_varSelector.Freeze()
        self.m_varSelector.Clear()
        self.m_plot.Freeze()
        var idx: Int = 0
        while True:
            var d: Pointer[tcKernel.dataset] = self.m_kernel.get_results(idx)
            if d:
                if d.type == TCS_NUMBER and len(d.values) > 0:
                    var dvset: tcsDVDataSet = tcsDVDataSet(d, start, step)
                    dvset.SetGroupName(d.group)
                    self.m_plot.AddDataSet(dvset)
                var text: String = wxString(d.group) + ":  " + wxString(d.name) + " (" + wxString(d.units) + ")"
                idx = self.m_varSelector.Append(text)
                if selections.Index(text) >= 0:
                    self.m_varSelector.Check(idx, True)
                idx += 1
            else:
                break
        self.m_plot.Thaw()
        self.m_varSelector.Thaw()
        self.m_varSelector.GetParent().Layout()
        self.m_plot.SetPerspective(view)
        UpdateGrid()
        for i in range(min(self.m_grid.GetNumberCols(), len(colsizes))):
            self.m_grid.SetColSize(i, colsizes[i])
        return code

    def AddVariableToDataTable(inout self, varname: String):
        var ndx: Int = -1
        for i in range(self.m_varSelector.GetCount()):
            if self.m_varSelector.GetString(i).Lower().Find(varname.Lower()) > -1:
                ndx = i
                if not self.m_varSelector.IsChecked(ndx):
                    self.m_varSelector.Check(ndx)
        if ndx > -1:
            UpdateGrid()

    def ClearDataTableSelections(inout self):
        for i in range(self.m_varSelector.GetCount()):
            if self.m_varSelector.IsChecked(i):
                self.m_varSelector.Check(i, False)
        UpdateGrid()

    def Log(inout self, text: String):
        self.m_textOut.AppendText(text)

    def ClearLog(inout self):
        self.m_textOut.Clear()

    def OnSelectVar(inout self, evt: wxCommandEvent):
        UpdateGrid()

    def OnCloseFrame(inout self, evt: wxCloseEvent):
        var cfg: wxConfig
        cfg.Write("script", self.m_scriptEditor.GetFileName())
        cfg.Write("visual", self.m_visualEditor.GetFileName())
        cfg.Write("tabsel", self.m_notebook.GetSelection())
        if (self.m_visualEditor.IsModified() and wxNO == wxMessageBox("There are modifications in the visual editor.  Quit anyways?", "Query", wxYES_NO)) or not self.m_scriptEditor.CloseDoc():
            evt.Veto()
            return
        Destroy()

    def GetTypes(inout self) -> wxArrayString:
        var list: wxArrayString = wxArrayString()
        var types: List[tcstypeprovider.typedata] = self.m_provider.types()
        for i in range(len(types)):
            list.Add(types[i].type)
        return list

    def ShowTypeDataDialog(inout self, type: String):
        var types: List[tcstypeprovider.typedata] = self.m_provider.types()
        var i: Int
        for i in range(len(types)):
            if wxString(types[i].type) == type:
                break
        if i == len(types):
            wxMessageBox("type " + type + " not loaded.  cannot show information.")
            return
        var frame: wxFrame = wxFrame(self, wxID_ANY, "Information for: " + type, wxDefaultPosition, wxSize(600, 500), wxFRAME_FLOAT_ON_PARENT | wxFRAME_NO_TASKBAR | wxCAPTION | wxRESIZE_BORDER | wxCLOSE_BOX | wxMAXIMIZE_BOX | wxSYSTEM_MENU)
        tcLayoutCtrl.CreateUnitDataGrid(frame, types[i].info)
        frame.Show()

    def GetVisualEditor(inout self) -> Pointer[tcVisualEditor]:
        return Pointer[tcVisualEditor](addressof(self.m_visualEditor))

    def GetScriptEditor(inout self) -> Pointer[tcScriptEditor]:
        return Pointer[tcScriptEditor](addressof(self.m_scriptEditor))

    def UpdateGrid(inout self):
        var rt: ResultsTable = ResultsTable()
        var idx: Int = 0
        while True:
            var d: Pointer[tcKernel.dataset] = self.m_kernel.get_results(idx)
            if d:
                if self.m_varSelector.IsChecked(idx):
                    rt.AddResult(d)
                idx += 1
            else:
                break
        self.m_grid.SetTable(&rt, True)
        self.m_grid.Refresh()

    def Instance() -> Pointer[tcFrame]:
        return __g_tcframe

@value
struct tcVisualEditor:
    var m_startTime: wxNumericCtrl
    var m_endTime: wxNumericCtrl
    var m_timeStep: wxNumericCtrl
    var m_maxIter: wxNumericCtrl
    var m_layout: tcLayoutCtrl
    var m_fileName: String
    var m_statusLabel: wxStaticText
    var m_typeChoice: wxComboBox
    var m_storeArrMat: wxCheckBox
    var m_proceedAnyway: wxCheckBox

    def __init__(inout self, parent: wxWindow):
        self.m_startTime = wxNumericCtrl(self, ID_STARTTIME, 0)
        self.m_startTime.SetFormat(2, False, String(), " hr")
        self.m_endTime = wxNumericCtrl(self, ID_ENDTIME, 0)
        self.m_endTime.SetFormat(2, False, String(), " hr")
        self.m_timeStep = wxNumericCtrl(self, ID_TIMESTEP, 0)
        self.m_timeStep.SetFormat(2, False, String(), " hr")
        self.m_maxIter = wxNumericCtrl(self, ID_MAXITER, 100, wxNUMERIC_INTEGER)
        self.m_maxIter.SetFormat(-1, False, String(), " iter")
        self.m_storeArrMat = wxCheckBox(self, wxID_ANY, "Store array/matrix data from simulation")
        self.m_storeArrMat.SetValue(False)
        self.m_proceedAnyway = wxCheckBox(self, wxID_ANY, "Proceed even if max iterations reached")
        self.m_proceedAnyway.SetValue(True)
        self.m_startTime.SetValue(1)
        self.m_endTime.SetValue(8760)
        self.m_timeStep.SetValue(1)
        var choices: wxArrayString = wxArrayString()
        self.m_typeChoice = wxComboBox(self, wxID_PROPERTIES, String(), wxDefaultPosition, wxDefaultSize, choices, wxCB_READONLY)
        self.m_statusLabel = wxStaticText(self, wxID_ANY, String())
        var sztools: wxBoxSizer = wxBoxSizer(wxHORIZONTAL)
        sztools.Add(wxButton(self, wxID_NEW, "New", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        sztools.Add(wxButton(self, wxID_OPEN, "Open", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        sztools.Add(wxButton(self, wxID_SAVE, "Save", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        sztools.Add(wxButton(self, wxID_SAVEAS, "Save as", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        sztools.Add(wxButton(self, wxID_FORWARD, "Simulate", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        sztools.Add(wxButton(self, wxID_APPLY, "Script", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        sztools.Add(self.m_statusLabel, 0, wxALL | wxALIGN_CENTER_VERTICAL, 2)
        var szsetup: wxBoxSizer = wxBoxSizer(wxHORIZONTAL)
        szsetup.Add(wxStaticText(self, wxID_ANY, "   Start:"), 0, wxALL | wxALIGN_CENTER_VERTICAL, 2)
        szsetup.Add(self.m_startTime, 0, wxALL | wxEXPAND, 2)
        szsetup.Add(wxStaticText(self, wxID_ANY, "   End:"), 0, wxALL | wxALIGN_CENTER_VERTICAL, 2)
        szsetup.Add(self.m_endTime, 0, wxALL | wxEXPAND, 2)
        szsetup.Add(wxStaticText(self, wxID_ANY, "   Step:"), 0, wxALL | wxALIGN_CENTER_VERTICAL, 2)
        szsetup.Add(self.m_timeStep, 0, wxALL | wxEXPAND, 2)
        szsetup.Add(wxStaticText(self, wxID_ANY, "   Max iter:"), 0, wxALL | wxALIGN_CENTER_VERTICAL, 2)
        szsetup.Add(self.m_maxIter, 0, wxALL | wxEXPAND, 2)
        szsetup.Add(wxStaticText(self, wxID_ANY, "   Types:"), 0, wxALL | wxALIGN_CENTER_VERTICAL, 2)
        szsetup.Add(self.m_typeChoice, 0, wxALL | wxEXPAND, 2)
        var szopts: wxBoxSizer = wxBoxSizer(wxHORIZONTAL)
        szopts.Add(self.m_storeArrMat, 0, wxALL | wxEXPAND, 2)
        szopts.Add(self.m_proceedAnyway, 0, wxALL | wxEXPAND, 2)
        self.m_layout = tcLayoutCtrl(self, wxID_ANY)
        var szmain: wxBoxSizer = wxBoxSizer(wxVERTICAL)
        szmain.Add(sztools, 0, wxALL | wxEXPAND, 2)
        szmain.Add(szsetup, 0, wxALL | wxEXPAND, 2)
        szmain.Add(szopts, 0, wxALL | wxEXPAND, 2)
        szmain.Add(wxStaticLine(self), 0, wxALL | wxEXPAND, 0)
        szmain.Add(self.m_layout, 1, wxALL | wxEXPAND, 0)
        SetSizer(szmain)

    def OnAction(inout self, evt: wxCommandEvent):
        if evt.GetId() == wxID_OPEN:
            var dlg: wxFileDialog = wxFileDialog(self, "Open File", wxPathOnly(self.m_fileName), self.m_fileName, "TCS Files (*.tcs)|*.tcs", wxFD_OPEN)
            if dlg.ShowModal() != wxID_OK:
                return
            LoadFile(dlg.GetPath())
        elif evt.GetId() == wxID_NEW:
            if self.m_layout.IsModified() and wxNO == wxMessageBox("The system has been changed.  Erase anyways?", "Query", wxYES_NO):
                return
            self.m_layout.Clear()
            self.m_layout.Refresh()
            self.m_layout.SetModified(False)
            self.m_fileName = ""
            self.m_statusLabel.SetLabel(String())
        elif evt.GetId() == wxID_SAVE:
            var file: String = self.m_fileName
            if file.IsEmpty():
                var dlg: wxFileDialog = wxFileDialog(self, "Save File", wxPathOnly(self.m_fileName), self.m_fileName, "TCS Files (*.tcs)|*.tcs", wxFD_SAVE | wxFD_OVERWRITE_PROMPT)
                if dlg.ShowModal() != wxID_OK:
                    return
                file = dlg.GetPath()
            WriteToDisk(file)
        elif evt.GetId() == wxID_SAVEAS:
            var dlg: wxFileDialog = wxFileDialog(self, "Save File", wxPathOnly(self.m_fileName), self.m_fileName, "TCS Files (*.tcs)|*.tcs", wxFD_SAVE | wxFD_OVERWRITE_PROMPT)
            if dlg.ShowModal() != wxID_OK:
                return
            WriteToDisk(dlg.GetPath())
        elif evt.GetId() == wxID_FORWARD:
            if not self.m_fileName.IsEmpty():
                var fos: wxFFileOutputStream = wxFFileOutputStream(self.m_fileName + "~")
                if fos.IsOk():
                    self.m_layout.Write(fos)
            ClearLog()
            var kern: Pointer[tcKernel] = tcFrame.Instance().GetKernel()
            if not self.m_layout.LoadSystemInKernel(kern):
                wxMessageBox("Error loading system into kernel:\n\n" + self.m_layout.GetError())
                return
            var nl: String = kern.netlist()
            Log(nl)
            tcFrame.Instance().Simulate(self.m_startTime.AsDouble() * 3600.0, self.m_endTime.AsDouble() * 3600.0, self.m_timeStep.AsDouble() * 3600.0, self.m_maxIter.AsInteger(), self.m_storeArrMat.GetValue(), self.m_proceedAnyway.GetValue())
        elif evt.GetId() == wxID_APPLY:
            if wxTheClipboard.Open():
                wxTheClipboard.SetData(wxTextDataObject(self.m_layout.GetLKScript()))
                wxTheClipboard.Close()
                var info: wxBusyInfo = wxBusyInfo("Script code representing the system was copied to the clipboard.  You may paste it into the editor.")
                wxMilliSleep(1000)
        elif evt.GetId() == wxID_PROPERTIES:
            tcFrame.Instance().ShowTypeDataDialog(self.m_typeChoice.GetStringSelection())

    def UpdateTypes(inout self):
        self.m_typeChoice.Clear()
        self.m_typeChoice.Append(tcFrame.Instance().GetTypes())

    def GetFileName(inout self) -> String:
        return self.m_fileName

    def GetLayout(inout self) -> Pointer[tcLayoutCtrl]:
        return Pointer[tcLayoutCtrl](addressof(self.m_layout))

    def WriteToDisk(inout self, file: String) -> Bool:
        var fos: wxFFileOutputStream = wxFFileOutputStream(file)
        if not fos.IsOk():
            wxMessageBox("Could not open file for writing:\n\n" + file)
            return False
        if not self.m_layout.Write(fos):
            wxMessageBox("Error writing: " + self.m_layout.GetError())
            return False
        else:
            tcFrame.Instance().Log("Visual editor wrote to disk: " + file + " (" + wxNow() + ")\n")
            self.m_fileName = file
            self.m_layout.SetModified(False)
            self.m_statusLabel.SetLabel(self.m_fileName)
            return True

    def LoadFile(inout self, file: String) -> Bool:
        var fis: wxFFileInputStream = wxFFileInputStream(file)
        if not fis.IsOk():
            wxMessageBox("Could not open file for reading:\n\n" + file)
            return False
        var info: wxBusyInfo = wxBusyInfo("Loading data file...")
        wxYield()
        if not self.m_layout.Read(fis):
            wxMessageBox("Error reading: " + self.m_layout.GetError())
            return False
        else:
            self.m_fileName = file
            self.m_statusLabel.SetLabel(self.m_fileName)
            self.m_layout.SetModified(False)
            return True

    def IsModified(inout self) -> Bool:
        return self.m_layout.IsModified()

@value
struct tcApp:
    def OnInit(inout self) -> Bool:
        wxInitAllImageHandlers()
        SetAppName("TCS Console")
        SetVendorName("NREL")
        var f: tcFrame = tcFrame()
        f.Show()
        f.SetClientSize(1000, 700)
        SetTopWindow(f)
        return True

@value
struct tcNotebook:
    def __init__(inout self, parent: wxWindow, id: Int):
        self = wxAuiNotebook(parent, id, wxDefaultPosition, wxDefaultSize, wxAUI_NB_TOP | wxAUI_NB_SCROLL_BUTTONS | wxAUI_NB_TAB_MOVE | wxAUI_NB_TAB_SPLIT | wxAUI_NB_WINDOWLIST_BUTTON | wxBORDER_NONE)
        self.m_mgr.GetArtProvider().SetMetric(wxAUI_DOCKART_PANE_BORDER_SIZE, 0)

@value
struct tcsDVDataSet:
    var m_start: Float64
    var m_step: Float64
    var m_pData: Pointer[tcKernel.dataset]

    def __init__(inout self, d: Pointer[tcKernel.dataset], start: Float64, step: Float64):
        self.m_pData = d
        self.m_start = start
        self.m_step = step

    def At(inout self, i: Int) -> wxRealPoint:
        if self.m_pData.type == TCS_NUMBER and i < len(self.m_pData.values):
            return wxRealPoint((self.m_start + Float64(i) * self.m_step) / 3600.0, self.m_pData.values[i].dval)
        else:
            return wxRealPoint((self.m_start + Float64(i) * self.m_step) / 3600.0, 0.0)

    def Length(inout self) -> Int:
        return len(self.m_pData.values)

    def GetTimeStep(inout self) -> Float64:
        return self.m_step / 3600.0

    def GetSeriesTitle(inout self) -> String:
        return String(self.m_pData.name)

    def GetUnits(inout self) -> String:
        return String(self.m_pData.units)

    def GetOffset(inout self) -> Float64:
        return self.m_start

var __g_tcframe: Pointer[tcFrame] = Pointer[tcFrame]()

#ifdef _MSC_VER
def mysnprintf(buffer: Pointer[UInt8], count: Int, format: String, *args...) -> Int:
    return _snprintf(buffer, count, format, *args)
#else
def mysnprintf(buffer: Pointer[UInt8], count: Int, format: String, *args...) -> Int:
    return snprintf(buffer, count, format, *args)
#endif

# ifdef _WIN64
var STR_BITS: String = "64"
# elif _WIN32
var STR_BITS: String = "32"
# elif __APPLE__
var STR_BITS: String = "64"
# elif __linux
# if defined(__LP64__) || defined(_LP64)
var STR_BITS: String = "64"
# else
var STR_BITS: String = "32"
# endif
# else
# error "could not determine platform architecture"
# endif

enum ID_SIMULATE: Int = 2324
enum ID_GRID: Int = 2325
enum ID_VARSELECTOR: Int = 2326
enum ID_DVPLOT: Int = 2327
enum ID_STARTTIME: Int = 2328
enum ID_ENDTIME: Int = 2329
enum ID_TIMESTEP: Int = 2330
enum ID_MAXITER: Int = 2331

# Event table macros are not directly translatable; event handling is done via method overrides in Mojo.
# The following is a placeholder for the event table logic.
# BEGIN_EVENT_TABLE(tcFrame, wxFrame)
# EVT_CHECKLISTBOX(ID_VARSELECTOR, tcFrame.OnSelectVar)
# EVT_CLOSE(tcFrame.OnCloseFrame)
# END_EVENT_TABLE()

# BEGIN_EVENT_TABLE(tcVisualEditor, wxPanel)
# EVT_BUTTON(wxID_NEW, tcVisualEditor.OnAction)
# EVT_BUTTON(wxID_OPEN, tcVisualEditor.OnAction)
# EVT_BUTTON(wxID_SAVE, tcVisualEditor.OnAction)
# EVT_BUTTON(wxID_SAVEAS, tcVisualEditor.OnAction)
# EVT_BUTTON(wxID_FORWARD, tcVisualEditor.OnAction)
# EVT_BUTTON(wxID_APPLY, tcVisualEditor.OnAction)
# EVT_COMBOBOX(wxID_PROPERTIES, tcVisualEditor.OnAction)
# END_EVENT_TABLE()

# IMPLEMENT_APP(tcApp)
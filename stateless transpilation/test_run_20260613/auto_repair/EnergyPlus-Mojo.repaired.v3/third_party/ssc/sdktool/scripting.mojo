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
from from <wx.wx.h> import ""
from from <wx.imaglist.h> import ""
from from <wx.splitter.h> import ""
from from <wx.filename.h> import ""
from from <wx.statline.h> import ""
from from <wx.html.htmlwin.h> import ""
from from <wx.tokenzr.h> import ""
from from <wx.busyinfo.h> import ""
from from <wx.stc.stc.h> import ""
from from <wex.lkscript.h> import ""
from from <wex.dview.dvplotctrl.h> import ""
from from <wex.dview.dvtimeseriesdataset.h> import ""
from from <lk.lex.h> import ""
from from <lk.parse.h> import ""
from from <lk.eval.h> import ""
from from <lk.invoke.h> import ""
from from <lk.stdlib.h> import ""
from "from "sscdev.h"" import ""
from "from "dataview.h"" import ""
from "from "scripting.h"" import ""

def Output(text: wxString) -> None:
    app_frame.Log(text, False)

def Output(fmt: str, *args: ...) -> None:
    var buf: StaticArray[Int8, 2048]
    var ap: va_list
    va_start(ap, fmt)
    #if defined(_MSC_VER)||defined(_WIN32)
    _vsnprintf(buf, 2046, fmt, ap)
    #else
    vsnprintf(buf, 2046, fmt, ap)
    #endif
    va_end(ap)
    Output(wxString(buf))

def ClearOutput() -> None:
    app_frame.ClearLog()

def sscvar_to_lkvar(out: lk.vardata_t, vv: var_data) -> bool:
    if not vv:
        return False
    if vv.type == SSC_NUMBER:
        out.assign(vv.num)
    elif vv.type == SSC_STRING:
        out.assign(vv.str)
    elif vv.type == SSC_ARRAY:
        out.empty_vector()
        out.vec().reserve(vv.num.length())
        for i in range(vv.num.length()):
            out.vec_append(vv.num[i])
    elif vv.type == SSC_MATRIX:
        out.empty_vector()
        out.vec().reserve(vv.num.nrows())
        for i in range(vv.num.nrows()):
            out.vec().push_back(lk.vardata_t())
            out.vec()[i].empty_vector()
            out.vec()[i].vec().reserve(vv.num.ncols())
            for j in range(vv.num.ncols()):
                out.vec()[i].vec_append(vv.num.at(i, j))
    elif vv.type == SSC_TABLE:
        out.empty_hash()
        var key: str = vv.table.first()
        while key != "":
            var x: var_data = vv.table.lookup(key)
            var xvd: lk.vardata_t = out.hash_item(lk_string(key))
            sscvar_to_lkvar(xvd, x)
            key = vv.table.next()
    return True

def lkvar_to_sscvar(vv: var_data, val: lk.vardata_t) -> bool:
    if not vv:
        return False
    if val.type() == lk.vardata_t.NUMBER:
        vv.type = SSC_NUMBER
        vv.num = val.as_number()
    elif val.type() == lk.vardata_t.STRING:
        vv.type = SSC_STRING
        vv.str = std.string(val.as_string())
    elif val.type() == lk.vardata_t.VECTOR:
        var dim1: size_t = val.length()
        var dim2: size_t = 0
        for i in range(val.length()):
            var row: lk.vardata_t = val.index(i)
            if row.type() == lk.vardata_t.VECTOR and row.length() > dim2:
                dim2 = row.length()
        if dim2 == 0 and dim1 > 0:
            vv.type = SSC_ARRAY
            vv.num.resize(dim1)
            for i in range(dim1):
                vv.num[i] = val.index(i).as_number()
        elif dim1 > 0 and dim2 > 0:
            vv.type = SSC_MATRIX
            vv.num.resize(dim1, dim2)
            for i in range(dim1):
                for j in range(dim2):
                    var x: Float64 = 0.0
                    if val.index(i).type() == lk.vardata_t.VECTOR and j < val.index(i).length():
                        x = val.index(i).index(j).as_number()
                    vv.num.at(i, j) = x
    elif val.type() == lk.vardata_t.HASH:
        vv.type = SSC_TABLE
        vv.table.clear()
        var hash: lk.varhash_t = val.hash()
        for it in hash.items():
            var item: var_data = vv.table.assign(it[0], var_data())
            lkvar_to_sscvar(item, it[1])
    return True

def fcall_var(cxt: lk.invoke_t) -> None:
    LK_DOC2("var", "Sets or gets a variable value in the SSC data set.",
        "Set a variable value.", "(string:name, variant:value):none",
        "Get a variable value", "(string:name):variant")
    var vt: var_table = app_frame.GetVarTable()
    var name: wxString = cxt.arg(0).as_string()
    if cxt.arg_count() == 1:
        var vv: var_data = vt.lookup(name.ToStdString())
        if vv:
            sscvar_to_lkvar(cxt.result(), vv)
    elif cxt.arg_count() == 2:
        var val: lk.vardata_t = cxt.arg(1).deref()
        var vv: var_data = vt.assign(name.ToStdString(), var_data())
        if vv:
            lkvar_to_sscvar(vv, val)
            app_frame.GetDataView().UpdateView()

def fcall_clear(cxt: lk.invoke_t) -> None:
    LK_DOC("clear", "Deletes variables from the SSC data set.  If no variable name(s) are specified, all are deleted.", "([string or array:variable name(s) to delete]):none")
    if cxt.arg_count() > 0:
        if cxt.arg(0).type() == lk.vardata_t.VECTOR:
            var len: size_t = cxt.arg(0).length()
            for i in range(len):
                app_frame.GetVarTable().unassign(cxt.arg(0).index(i).as_string())
        else:
            app_frame.GetVarTable().unassign(cxt.arg(0).as_string())
    else:
        app_frame.GetVarTable().clear()
    app_frame.GetDataView().UpdateView()

def fcall_save(cxt: lk.invoke_t) -> None:
    LK_DOC("save", "Save the current variable data set to disk in the SSCdev binary data (*.bdat) format.", "(string:filename):boolean")
    cxt.result().assign(app_frame.WriteBdatToDisk(cxt.arg(0).as_string()))

def fcall_load(cxt: lk.invoke_t) -> None:
    LK_DOC("load", "Load a variable data set from an SSCdev binary data (*.bdat) file.", "(string:filename):boolean")
    cxt.result().assign(app_frame.LoadBdat(cxt.arg(0).as_string()))

def fcall_run(cxt: lk.invoke_t) -> None:
    LK_DOC("run",
        "Starts the computation sequence defined.  If no parameter is given, it runs the currently defined list of compute modules. "
        "Passing a comma-separated list of compute module names changes the list.",
        "([string:compute modules list]):array of booleans")
    if cxt.arg_count() > 0:
        app_frame.SetCurrentCM(cxt.arg(0).as_string())
    var ok: std.vector[bool] = app_frame.Start()
    cxt.result().empty_vector()
    for i in range(ok.size()):
        cxt.result().vec_append(1 if ok[i] else 0)

def fcall_tsview(cxt: lk.invoke_t) -> None:
    LK_DOC("tsview", "Show a timeseries viewer for the variables given in the comma-separated list, or plots the name-data pairs sent as arguments.  Variable must have 8760 values.", "(string:comma-separated variable name list -or- string:name1, array:values1,...):none")
    var frm: wxFrame = wxFrame(app_frame, -1, "Timeseries Viewer", wxDefaultPosition, wxSize(900, 600))
    var dv: wxDVPlotCtrl = wxDVPlotCtrl(frm)
    var vt: var_table = app_frame.GetVarTable()
    var iadded: Int = 0
    var da: std.vector[Float64] = std.vector[Float64](8760)
    if cxt.arg_count() == 1:
        var selections: wxArrayString = wxStringTokenize(cxt.arg(0).as_string(), ",")
        for i in range(selections.Count()):
            var v: var_data = vt.lookup(selections[i])
            if v != None and v.type == SSC_ARRAY and v.num.length() == 8760:
                for k in range(8760):
                    da[k] = v.num[k]
                dv.AddDataSet(wxDVArrayDataSet(selections[i], da))
                iadded += 1
    else:
        for i in range(1, cxt.arg_count(), 2):
            var name: wxString = cxt.arg(i - 1).as_string()
            var units: wxString = ""
            var lpos: size_t = name.Find('(')
            var rpos: size_t = name.Find(')')
            if lpos != wxString.npos and rpos != wxString.npos and rpos > lpos:
                units = name.Mid(lpos + 1, rpos - lpos - 1)
                name.Truncate(lpos)
                name.Trim()
            if cxt.arg(i).type() == lk.vardata_t.VECTOR and cxt.arg(i).length() == 8760:
                for k in range(8760):
                    da[k] = cxt.arg(i).index(k).as_number()
                dv.AddDataSet(wxDVArrayDataSet(name, units, 1.0, da))
                iadded += 1
    if iadded == 0:
        frm.Destroy()
        cxt.result().assign(0.0)
    else:
        dv.SelectDataOnBlankTabs()
        frm.Show()
        cxt.result().assign(iadded)

def fcall_freeze(cxt: lk.invoke_t) -> None:
    LK_DOC("freeze", "Freeze the data view for improved processing speed", "(none):none")
    app_frame.GetDataView().Freeze()

def fcall_thaw(cxt: lk.invoke_t) -> None:
    LK_DOC("thaw", "Thaw the data view for to restore interactivity", "(none):none")
    app_frame.GetDataView().Thaw()

def ssc_funcs() -> lk.fcall_t*:
    var vec: StaticArray[lk.fcall_t, 9] = lk.fcall_t*(
        fcall_var,
        fcall_clear,
        fcall_run,
        fcall_save,
        fcall_load,
        fcall_tsview,
        fcall_freeze,
        fcall_thaw,
        0
    )
    return vec.data()

enum ID_CODEEDITOR: Int = wxID_HIGHEST + 1
enum ID_RUN: Int = wxID_HIGHEST + 2
enum ID_HELP: Int = wxID_HIGHEST + 3

class MyScriptCtrl(wxLKScriptCtrl):
    def __init__(self, parent: wxWindow, id: Int = wxID_ANY):
        super().__init__(parent, id, wxDefaultPosition, wxDefaultSize, wxLK_STDLIB_ALL | wxLK_STDLIB_SOUT)

    def OnOutput(self, tt: wxString) -> None:
        Output(tt)

    def OnSyntaxCheck(self, num: Int, err: wxString) -> None:
        ClearOutput()
        Output(err)

class EditorWindow(wxPanel):
    var m_editor: wxLKScriptCtrl
    var m_statusLabel: wxStaticText
    var m_fileName: wxString
    var m_stopButton: wxButton
    var m_lastFindStr: wxString

    def __init__(self, parent: wxWindow):
        super().__init__(parent)
        var szdoc: wxBoxSizer = wxBoxSizer(wxHORIZONTAL)
        szdoc.Add(wxButton(self, wxID_NEW, "New", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        szdoc.Add(wxButton(self, wxID_OPEN, "Open", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        szdoc.Add(wxButton(self, wxID_SAVE, "Save", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        szdoc.Add(wxButton(self, wxID_SAVEAS, "Save as", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        szdoc.Add(wxButton(self, wxID_FIND, "Find", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        szdoc.Add(wxButton(self, wxID_FORWARD, "Find next", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        szdoc.Add(wxButton(self, ID_HELP, "Help", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        szdoc.Add(wxButton(self, ID_RUN, "Run", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
        self.m_stopButton = wxButton(self, wxID_STOP, "Stop", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT)
        szdoc.Add(self.m_stopButton, 0, wxALL | wxEXPAND, 2)
        szdoc.AddStretchSpacer()
        self.m_stopButton.SetForegroundColour(wxRED)
        self.m_stopButton.Hide()
        self.m_editor = MyScriptCtrl(self, ID_CODEEDITOR)
        self.m_editor.RegisterLibrary(ssc_funcs(), "SSC Functions", self)
        var szedit: wxBoxSizer = wxBoxSizer(wxVERTICAL)
        szedit.Add(szdoc, 0, wxALL | wxEXPAND, 2)
        szedit.Add(self.m_editor, 1, wxALL | wxEXPAND, 0)
        self.m_statusLabel = wxStaticText(self, wxID_ANY, wxEmptyString)
        szedit.Add(self.m_statusLabel, 0, wxALL | wxEXPAND, 0)
        self.SetSizer(szedit)
        self.m_editor.SetFocus()

    def __del__(self):

    def GetFileName(self) -> wxString:
        return self.m_fileName

    def GetEditor(self) -> wxLKScriptCtrl:
        return self.m_editor

    def OnCommand(self, evt: wxCommandEvent) -> None:
        if evt.GetId() == wxID_NEW:
            self.CloseDoc()
        elif evt.GetId() == wxID_OPEN:
            self.Open()
        elif evt.GetId() == wxID_SAVE:
            self.Save()
        elif evt.GetId() == wxID_SAVEAS:
            self.SaveAs()
        elif evt.GetId() == wxID_UNDO:
            self.m_editor.Undo()
        elif evt.GetId() == wxID_REDO:
            self.m_editor.Redo()
        elif evt.GetId() == wxID_CUT:
            self.m_editor.Cut()
        elif evt.GetId() == wxID_COPY:
            self.m_editor.Copy()
        elif evt.GetId() == wxID_PASTE:
            self.m_editor.Paste()
        elif evt.GetId() == wxID_SELECTALL:
            self.m_editor.SelectAll()
        elif evt.GetId() == wxID_FIND:
            self.m_editor.ShowFindReplaceDialog()
        elif evt.GetId() == wxID_FORWARD:
            self.m_editor.FindNext()
        elif evt.GetId() == ID_HELP:
            self.m_editor.ShowHelpDialog(self)
        elif evt.GetId() == ID_RUN:
            self.Exec()
        elif evt.GetId() == wxID_STOP:
            self.m_editor.Stop()
            self.m_stopButton.Hide()
            self.Layout()

    def Open(self) -> None:
        self.CloseDoc()
        var dlg: wxFileDialog = wxFileDialog(self, "Open", wxEmptyString, wxEmptyString,
                                             "LK Script Files (*.lk)|*.lk",
                                             wxFD_OPEN | wxFD_FILE_MUST_EXIST | wxFD_CHANGE_DIR)
        if dlg.ShowModal() == wxID_OK:
            if not self.Load(dlg.GetPath()):
                wxMessageBox("Could not load file:\n\n" + dlg.GetPath())

    def Save(self) -> bool:
        if self.m_fileName.IsEmpty():
            return self.SaveAs()
        else:
            return self.Write(self.m_fileName)

    def SaveAs(self) -> bool:
        var dlg: wxFileDialog = wxFileDialog(self, "Save as...",
                                              wxPathOnly(self.m_fileName),
                                              wxFileNameFromPath(self.m_fileName),
                                              "LK Script Files (*.lk)|*.lk", wxFD_SAVE | wxFD_OVERWRITE_PROMPT)
        if dlg.ShowModal() == wxID_OK:
            return self.Write(dlg.GetPath())
        else:
            return False

    def CloseDoc(self) -> bool:
        if self.m_editor.IsScriptRunning():
            if wxMessageBox("A script is running. Cancel it?", "Query", wxYES_NO) == wxYES:
                self.m_editor.Stop()
            return False
        if self.m_editor.GetModify():
            self.Raise()
            var id: wxString = "untitled" if self.m_fileName.IsEmpty() else self.m_fileName
            var result: Int = wxMessageBox("Script modified. Save it?\n\n" + id, "Query", wxYES_NO | wxCANCEL)
            if result == wxCANCEL or (result == wxYES and not self.Save()):
                return False
        self.m_editor.SetText(wxEmptyString)
        self.m_editor.EmptyUndoBuffer()
        self.m_editor.SetSavePoint()
        self.m_fileName.Clear()
        self.m_statusLabel.SetLabel(self.m_fileName)
        return True

    def Write(self, file: wxString) -> bool:
        var info: wxBusyInfo = wxBusyInfo("Saving script file...")
        wxMilliSleep(120)
        if (self.m_editor as wxStyledTextCtrl).SaveFile(file):
            self.m_fileName = file
            self.m_statusLabel.SetLabel(self.m_fileName)
            return True
        else:
            return False

    def Load(self, file: wxString) -> bool:
        var fp: FILE* = fopen(file, "r")
        if fp:
            var str: wxString
            var buf: StaticArray[Int8, 1024]
            while fgets(buf, 1023, fp) != None:
                str += wxString(buf)
            fclose(fp)
            self.m_editor.SetText(str)
            self.m_editor.EmptyUndoBuffer()
            self.m_editor.SetSavePoint()
            self.m_fileName = file
            self.m_statusLabel.SetLabel(self.m_fileName)
            return True
        else:
            return False

    def Exec(self) -> None:
        ClearOutput()
        self.m_stopButton.Show()
        self.Layout()
        wxGetApp().Yield(True)
        wxLKSetToplevelParentForPlots(app_frame)
        wxLKSetPlotTarget(None)
        var work_dir: wxString
        if not self.m_fileName.IsEmpty():
            work_dir = wxPathOnly(self.m_fileName)
        self.m_editor.SetWorkDir(work_dir)
        self.m_editor.Execute()
        if self.m_stopButton.IsShown():
            self.m_stopButton.Hide()
            self.Layout()

# Event table
EVT_BUTTON(wxID_NEW, EditorWindow.OnCommand)
EVT_BUTTON(wxID_OPEN, EditorWindow.OnCommand)
EVT_BUTTON(wxID_SAVE, EditorWindow.OnCommand)
EVT_BUTTON(wxID_SAVEAS, EditorWindow.OnCommand)
EVT_BUTTON(wxID_HELP, EditorWindow.OnCommand)
EVT_BUTTON(wxID_FIND, EditorWindow.OnCommand)
EVT_BUTTON(wxID_FORWARD, EditorWindow.OnCommand)
EVT_BUTTON(ID_RUN, EditorWindow.OnCommand)
EVT_BUTTON(wxID_STOP, EditorWindow.OnCommand)
EVT_BUTTON(ID_RUN, EditorWindow.OnCommand)
EVT_BUTTON(ID_HELP, EditorWindow.OnCommand)
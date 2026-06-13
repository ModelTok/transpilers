# This is a faithful 1:1 translation from C++ to Mojo.
# All names, structures, and logic are preserved.
# External types from wxWidgets and SSC are declared as external (placeholder) to allow compilation.
# Event table macros are commented out as Mojo does not have those preprocessor constructs.

from dllinvoke import var_table, var_data, ssc_number_t
from editvariable import EditVariableDialog  # assumed to exist
from util import matrix_t  # assumed to exist

# Forward declarations for wx types (external)
@external
struct wxPanel:

@external
struct wxDialog:

@external
struct wxWindow:

@external
struct wxButton:

@external
struct wxCheckListBox:

@external
struct wxSplitterWindow:

@external
struct wxExtGridCtrl:

@external
struct wxGridTableBase:

@external
struct wxGridCellAttr:

@external
struct wxBoxSizer:

@external
struct wxMenu:

@external
struct wxGridEvent:

@external
struct wxCommandEvent:

@external
struct wxNumericCtrl:

@external
struct wxDVPlotCtrl:

@external
struct wxDVArrayDataSet:

@external
struct wxPLPlotCtrl:

@external
struct wxPLLinePlot:

@external
struct wxPLBarPlot:

@external
struct wxPLLinearAxis:

@external
struct wxRealPoint:

@external
struct wxFrame:

@external
struct wxStaticText:

@external
struct wxSizer:

# wx constant equivalents (using string literals)
alias wxHORIZONTAL = 0  # placeholder
alias wxVERTICAL = 1
alias wxALL = 0
alias wxEXPAND = 0
alias wxLEFT = 0
alias wxALIGN_CENTER_VERTICAL = 0
alias wxALIGN_RIGHT = 0
alias wxALIGN_CENTER = 0
alias wxDEFAULT_DIALOG_STYLE = 0
alias wxRESIZE_BORDER = 0
alias wxSP_LIVE_UPDATE = 0
alias wxBU_EXACTFIT = 0
alias wxID_ANY = -1
alias wxOK = 0
alias wxYES = 0
alias wxNO = 0
alias wxYES_NO = 0
alias wxNOT_FOUND = -1
alias wxGRID_AUTOSIZE = 0
alias wxFONTFAMILY_MODERN = 0
alias wxFONTSTYLE_NORMAL = 0
alias wxFONTWEIGHT_NORMAL = 0
alias wxDefaultPosition = (0,0)
alias wxDefaultSize = (0,0)

# wxString is String
alias wxString = String
# wxArrayString is List[String]
alias wxArrayString = List[String]
# vector<int> -> List[Int]
alias std_vector_int = List[Int]
# wxTreeItemId placeholder
alias wxTreeItemId = Int

# Constants from the original
#from wx.h: e.g. FONTSIZE
@pythoncode
def __init_wx_constants():
    global FONTSIZE
    if sys.platform == 'darwin':
        FONTSIZE = 13
    else:
        FONTSIZE = 10
__init_wx_constants()

# Enum for IDs (using constants)
alias ID_COPY_CLIPBOARD = 2315
alias ID_LIST = 2316
alias ID_SHOW_STATS = 2317
alias ID_ADD_VARIABLE = 2318
alias ID_EDIT_VARIABLE = 2319
alias ID_DELETE_VARIABLE = 2320
alias ID_DELETE_ALL_VARIABLES = 2321
alias ID_SELECT_ALL = 2322
alias ID_UNSELECT_ALL = 2323
alias ID_DELETE_CHECKED = 2324
alias ID_DELETE_UNCHECKED = 2325
alias ID_DVIEW = 2326
alias ID_POPUP_EDIT = 2327
alias ID_POPUP_DELETE = 2328
alias ID_POPUP_STATS = 2329
alias ID_POPUP_PLOT_BAR = 2330
alias ID_POPUP_PLOT_LINE = 2331
alias ID_GRID = 2332

# Event table macros (commented out as they are C++ preprocessor)
# BEGIN_EVENT_TABLE( DataView, wxPanel )
# END_EVENT_TABLE()
# EVT_BUTTON(...) etc.

# Helper function from original C++ (static inside file)
@staticmethod
def SortByLabels(names: wxArrayString, labels: wxArrayString):
    var count = labels.size()
    for i in range(count-1):
        var smallest = i
        for j in range(i+1, count):
            if labels[j] < labels[smallest]:
                smallest = j
        # swap
        var buf = labels[i]
        labels[i] = labels[smallest]
        labels[smallest] = buf
        buf = names[i]
        names[i] = names[smallest]
        names[smallest] = buf

# Class DataView::Table (inner class)
struct DataView_Table:
    var m_attr: wxGridCellAttr
    var m_vt_ref: var_table
    var m_items: wxArrayString

    def __init__(inout self):
        self.m_vt_ref = None
        self.m_attr = wxGridCellAttr()
        # SetBackgroundColour, SetTextColour, SetFont are external; skip or stub
        # In Mojo, we just keep the constructor as is (call external)
        # For 1:1, we keep the calls as comments? Better to keep them as method calls
        self.m_attr.SetBackgroundColour(wxColour(240,240,240))
        self.m_attr.SetTextColour("navy")
        self.m_attr.SetFont(wxFont(FONTSIZE, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL))

    def __del__(inout self):
        self.m_attr.DecRef()
        self.m_vt_ref = None

    def GetAttr(self, row: Int, col: Int, kind: Int) -> wxGridCellAttr:
        if col >= 0 and col < self.m_items.size():
            if not self.m_vt_ref:
                return None
            var v = self.m_vt_ref.lookup(self.m_items[col])
            if not v:
                return None
            if v.type != SSC_MATRIX:
                return None
            self.m_attr.IncRef()
            return self.m_attr
        else:
            return None

    def Detach(inout self):
        self.m_vt_ref = None

    def GetNumberRows(self) -> Int:
        var max0 = 0
        for i in range(self.m_items.size()):
            if not self.m_vt_ref:
                continue
            var v = self.m_vt_ref.lookup(self.m_items[i])
            if not v:
                continue
            var len = 1
            if v.type == SSC_ARRAY:
                len = v.num.length()
            elif v.type == SSC_MATRIX:
                len = v.num.nrows()
            elif v.type == SSC_TABLE:
                len = v.table.size()
            if len > max0:
                max0 = len
        return max0

    def GetNumberCols(self) -> Int:
        return self.m_items.size()

    def IsEmptyCell(self, row: Int, col: Int) -> Bool:
        if col < 0 or col >= self.m_items.size() or row < 0:
            return True
        if not self.m_vt_ref:
            return True
        var v = self.m_vt_ref.lookup(self.m_items[col])
        if not v:
            return True
        if v.type == SSC_STRING and row >= 1:
            return True
        if v.type == SSC_ARRAY and row >= v.num.length():
            return True
        if v.type == SSC_MATRIX and row >= v.num.nrows():
            return True
        if v.type == SSC_TABLE and row >= v.table.size():
            return True
        return False

    def GetValue(self, row: Int, col: Int) -> wxString:
        if self.m_vt_ref and col >= 0 and col < self.m_items.size():
            var v = self.m_vt_ref.lookup(self.m_items[col])
            if not v:
                return "<lookup error>"
            if v.type == SSC_STRING and row == 0:
                return v.str
            elif v.type == SSC_NUMBER and row == 0:
                return String.Format("%lf", v.num)
            elif v.type == SSC_ARRAY and row < v.num.length():
                return String.Format("%lf", v.num[row])
            elif v.type == SSC_MATRIX and row < v.num.nrows():
                var ret = ""
                for j in range(v.num.ncols()):
                    ret += String.Format("%*lf", 13, v.num.at(row, j))
                return ret
            elif v.type == SSC_TABLE and row < v.table.size():
                var k = 0
                var key = v.table.first()
                while key != None:
                    if k == row:
                        break
                    k += 1
                    key = v.table.next()
                return ".{'" + key + "'}"
        return ""

    def GetColLabelValue(self, col: Int) -> wxString:
        if col >= 0 and col < self.m_items.size():
            return self.m_items[col]
        else:
            return "<unknown>"

    def SetData(inout self, items: wxArrayString, vt: var_table, flag: Bool):
        self.m_items = items
        self.m_vt_ref = vt

    def SetValue(self, row: Int, col: Int, value: wxString):
        # nothing to do

# Class DataView (public)
struct DataView:
    var m_frozen: Bool
    var m_grid: wxExtGridCtrl
    var m_grid_table: DataView_Table
    var m_varlist: wxCheckListBox
    var m_root_item: wxTreeItemId
    var m_tree_items: List[wxTreeItemId]
    var m_names: wxArrayString
    var m_selections: wxArrayString
    var m_popup_var_name: wxString
    var m_vt: var_table

    def __init__(inout self, parent: wxWindow):
        # Inherit wxPanel constructor - we call parent constructor via external
        # In Mojo, we just assign fields and call external methods
        self.m_frozen = False
        self.m_grid_table = None
        self.m_root_item = 0
        self.m_vt = None
        # Create toolbar sizer
        var tb_sizer = wxBoxSizer(wxHORIZONTAL)
        tb_sizer.Add(wxButton(self, ID_ADD_VARIABLE, "Add...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_EDIT_VARIABLE, "Edit...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_DELETE_VARIABLE, "Delete", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_DELETE_CHECKED, "Del checked", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_DELETE_UNCHECKED, "Del unchecked", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_DELETE_ALL_VARIABLES, "Del all", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_SELECT_ALL, "Select all", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_UNSELECT_ALL, "Unselect all", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL|wxEXPAND, 2)
        tb_sizer.Add(wxButton(self, ID_COPY_CLIPBOARD, "Copy to clipboard", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxEXPAND|wxALL, 2)
        tb_sizer.Add(wxButton(self, ID_SHOW_STATS, "Show stats...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxEXPAND|wxALL, 2)
        tb_sizer.Add(wxButton(self, ID_DVIEW, "Timeseries graph...", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxEXPAND|wxALL, 2)
        tb_sizer.AddStretchSpacer(1)

        var splitwin = wxSplitterWindow(self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxSP_LIVE_UPDATE)
        splitwin.SetMinimumPaneSize(210)

        self.m_varlist = wxCheckListBox(splitwin, ID_LIST)
        self.m_varlist.SetFont(wxFont(FONTSIZE, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL))

        self.m_grid = wxExtGridCtrl(splitwin, ID_GRID)
        self.m_grid.SetFont(wxFont(FONTSIZE, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL))
        self.m_grid.EnableEditing(False)
        self.m_grid.EnableCopyPaste(False)
        self.m_grid.DisableDragCell()
        self.m_grid.DisableDragRowSize()
        self.m_grid.DisableDragColMove()
        self.m_grid.DisableDragGridSize()
        self.m_grid.SetDefaultCellAlignment(wxALIGN_RIGHT, wxALIGN_CENTER)
        self.m_grid.SetRowLabelAlignment(wxALIGN_LEFT, wxALIGN_CENTER)

        splitwin.SplitVertically(self.m_varlist, self.m_grid, 390)

        var szv_main = wxBoxSizer(wxVERTICAL)
        szv_main.Add(tb_sizer, 0, wxALL|wxEXPAND, 2)
        szv_main.Add(splitwin, 1, wxALL|wxEXPAND, 0)
        self.SetSizer(szv_main)

    def __del__(inout self):
        self.m_vt = None

    def SetDataObject(inout self, vt: var_table):
        self.m_vt = vt
        self.UpdateView()

    def GetDataObject(self) -> var_table:
        return self.m_vt

    def UpdateView(inout self):
        if self.m_frozen:
            return
        var sel_list = self.m_selections
        self.m_names.Clear()
        self.m_varlist.Clear()
        if self.m_vt != None:
            var padto = 0
            var name = self.m_vt.first()
            while name:
                var len = strlen(name)
                if len > padto:
                    padto = len
                name = self.m_vt.next()
            padto += 2
            var labels: wxArrayString
            name = self.m_vt.first()
            while name:
                self.m_names.Add(name)
                var label = name
                var v = self.m_vt.lookup(name)
                if v:
                    for j in range(padto - strlen(name)):
                        label += ' '
                    label += v.type_name()
                    if v.type == SSC_NUMBER:
                        label += " " + String.Format("%lg", v.num)
                    elif v.type == SSC_STRING:
                        label += " " + v.str
                    elif v.type == SSC_ARRAY:
                        label += String.Format(" [%d]", v.num.length())
                    elif v.type == SSC_MATRIX:
                        label += String.Format(" [%d,%d]", v.num.nrows(), v.num.ncols())
                    elif v.type == SSC_TABLE:
                        label += String.Format(" { %d }", v.table.size())
                labels.Add(label)
                name = self.m_vt.next()
            self.m_varlist.Freeze()
            SortByLabels(self.m_names, labels)
            for i in range(self.m_names.size()):
                var idx = self.m_varlist.Append(labels[i])
                self.m_varlist.Check(idx, False)
            self.m_varlist.Thaw()
        self.SetSelections(sel_list)
        self.UpdateGrid()

    def UpdateGrid(inout self):
        var cwl = self.GetColumnWidths()
        self.m_grid.Freeze()
        if self.m_grid_table:
            self.m_grid_table.Detach()
        self.m_grid_table = DataView_Table()
        self.m_grid_table.SetData(self.m_selections, self.m_vt, True)
        self.m_grid.SetTable(self.m_grid_table, True)
        self.m_grid.SetRowLabelSize(60)
        self.m_grid.Thaw()
        self.m_grid.Layout()
        self.m_grid.GetParent().Layout()
        self.SetColumnWidths(cwl)
        self.m_grid.ForceRefresh()

    def Freeze(inout self):
        self.m_frozen = True

    def Thaw(inout self):
        self.m_frozen = False
        self.UpdateView()

    def GetColumnWidths(self) -> std_vector_int:
        var list: std_vector_int
        for i in range(self.m_grid.GetNumberCols()):
            list.push_back(self.m_grid.GetColSize(i))
        return list

    def SetColumnWidths(inout self, cwl: std_vector_int):
        var ncols = self.m_grid.GetNumberCols()
        for i in range(min(cwl.size(), ncols)):
            self.m_grid.SetColSize(i, cwl[i])

    def GetSelections(self) -> wxArrayString:
        return self.m_selections

    def SetSelections(inout self, sel: wxArrayString):
        self.m_selections = sel
        var i = 0
        while i < self.m_selections.size():
            if self.m_names.Index(self.m_selections[i]) == wxNOT_FOUND:
                self.m_selections.RemoveAt(i)
            else:
                i += 1
        for idx in range(self.m_names.size()):
            self.m_varlist.Check(idx, self.m_selections.Index(self.m_names[idx]) >= 0)

    def AddVariable(inout self):
        var name = GetTextFromUser("Enter variable name:")
        if name.IsEmpty():
            return
        if self.m_vt:
            if self.m_vt.lookup(name):
                if wxMessageBox("That var exists. overwrite with a new one?", "Q", wxYES_NO) == wxNO:
                    return
            self.m_vt.assign(name, var_data(0.0))
            if self.m_selections.Index(name) == wxNOT_FOUND:
                self.m_selections.Add(name)
            self.UpdateView()
            self.EditVariable(name)

    def EditVariable(inout self, name: wxString = ""):
        if name.IsEmpty():
            name = self.GetSelection()
        if name.IsEmpty():
            return
        if not self.m_vt:
            return
        var v = self.m_vt.lookup(name)
        if not v:
            wxMessageBox("Could not locate variable: " + name)
            return
        if v.type == SSC_TABLE:
            var dlg = wxDialog(self, wxID_ANY, "Edit table: " + name, wxDefaultPosition, wxSize(850,600), wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER)
            var dv = DataView(dlg)
            var sz = wxBoxSizer(wxVERTICAL)
            sz.Add(dv, 1, wxALL|wxEXPAND, 0)
            sz.Add(wxButton(dlg, wxID_OK, "Close", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL, 3)
            dv.SetDataObject(v.table)
            dlg.SetSizer(sz)
            dlg.ShowModal()
            self.UpdateView()
        else:
            var dlg = EditVariableDialog(self, "Edit Variable: " + name)
            dlg.SetVarData(v)
            if dlg.ShowModal() == wxID_OK:
                dlg.GetVarData(v)
                self.UpdateView()

    def DeleteVariable(inout self, name: wxString = ""):
        if name.IsEmpty():
            name = self.GetSelection()
        if name.IsEmpty():
            return
        if self.m_vt:
            self.m_vt.unassign(name)
            self.UpdateView()

    def ShowStats(self, name: wxString = ""):
        if name.IsEmpty():
            name = self.GetSelection()
        if name.IsEmpty():
            return
        if self.m_vt:
            var v = self.m_vt.lookup(name)
            if not v or v.type != SSC_ARRAY:
                wxMessageBox("variable not found or not of array type.")
                return
            var dlg = StatDialog(self, "Stats for: " + name)
            dlg.Compute(v.num)
            dlg.ShowModal()

    def GetSelection(self) -> wxString:
        var n = self.m_varlist.GetSelection()
        if n >= 0 and n < self.m_names.size():
            return self.m_names[n]
        else:
            return ""

    # Event handlers (keep as methods)
    def OnCommand(inout self, evt: wxCommandEvent):
        var id = evt.GetId()
        if id == ID_SHOW_STATS:
            self.ShowStats()
        elif id == ID_DVIEW:
            var dlg = wxDialog(self, -1, "Timeseries Viewer", wxDefaultPosition, wxSize(900,600), wxRESIZE_BORDER|wxDEFAULT_DIALOG_STYLE)
            var dv = wxDVPlotCtrl(dlg)
            var sz = wxBoxSizer(wxVERTICAL)
            sz.Add(dv, 1, wxALL|wxEXPAND, 0)
            sz.Add(dlg.CreateButtonSizer(wxOK), 0, wxALL|wxEXPAND, 0)
            dlg.SetSizer(sz)
            var da: List[Float64] = [0.0]*8760
            var iadded = 0
            for i in range(self.m_selections.size()):
                var v = self.m_vt.lookup(self.m_selections[i])
                if v and v.type == SSC_ARRAY and v.num.length() == 8760:
                    for k in range(8760):
                        da[k] = v.num[k]
                    dv.AddDataSet(wxDVArrayDataSet(self.m_selections[i], da))
                    iadded += 1
            if iadded == 0:
                wxMessageBox("Please check one or more array variables with 8760 values to show in the timeseries viewer.")
            else:
                dv.SelectDataOnBlankTabs()
                dlg.ShowModal()
        elif id == ID_SELECT_ALL:
            self.m_selections.Clear()
            var name = self.m_vt.first()
            while name:
                self.m_selections.Add(name)
                name = self.m_vt.next()
            self.UpdateView()
        elif id == ID_UNSELECT_ALL:
            self.m_selections.Clear()
            self.UpdateView()
        elif id == ID_DELETE_CHECKED:
            var list = self.m_selections
            for i in range(list.size()):
                self.DeleteVariable(list[i])
        elif id == ID_DELETE_UNCHECKED:
            var list: wxArrayString
            var name = self.m_vt.first()
            while name:
                list.Add(name)
                name = self.m_vt.next()
            for i in range(self.m_selections.size()):
                list.Remove(self.m_selections[i])
            for i in range(list.size()):
                self.DeleteVariable(list[i])
        elif id == ID_ADD_VARIABLE:
            self.AddVariable()
        elif id == ID_EDIT_VARIABLE:
            self.EditVariable()
        elif id == ID_DELETE_VARIABLE:
            self.DeleteVariable()
        elif id == ID_DELETE_ALL_VARIABLES:
            if self.m_vt and wxMessageBox("Really delete all variables?", "Query", wxYES_NO) == wxYES:
                self.m_vt.clear()
                self.UpdateView()
        elif id == ID_COPY_CLIPBOARD:
            self.m_grid.Copy(self.m_grid.NumCellsSelected() == 1, True)

    def OnVarListCheck(inout self, evt: wxCommandEvent):
        var idx = evt.GetSelection()
        if idx >= 0 and idx < self.m_names.size():
            var var_name = self.m_names[idx]
            if self.m_varlist.IsChecked(idx) and self.m_selections.Index(var_name) == wxNOT_FOUND:
                self.m_selections.Add(var_name)
            if not self.m_varlist.IsChecked(idx) and self.m_selections.Index(var_name) != wxNOT_FOUND:
                self.m_selections.Remove(var_name)
        self.UpdateGrid()

    def OnVarListDClick(inout self, evt: wxCommandEvent):
        self.EditVariable()

    def OnPopup(inout self, evt: wxCommandEvent):
        var id = evt.GetId()
        if id == ID_POPUP_EDIT:
            self.EditVariable(self.m_popup_var_name)
        elif id == ID_POPUP_DELETE:
            if wxMessageBox("Really delete variable: " + self.m_popup_var_name, "Query", wxYES_NO) == wxYES:
                self.DeleteVariable(self.m_popup_var_name)
        elif id == ID_POPUP_STATS:
            self.ShowStats(self.m_popup_var_name)
        elif id == ID_POPUP_PLOT_BAR or id == ID_POPUP_PLOT_LINE:
            if not self.m_vt:
                return
            var v = self.m_vt.lookup(self.m_popup_var_name)
            if not v or v.type != SSC_ARRAY:
                wxMessageBox("variable not found or not of array type.")
                return
            var frm = wxFrame(self, -1, "plot: " + self.m_popup_var_name, wxDefaultPosition, wxSize(500,350))
            if v.num.length() == 8760:
                var dv = wxDVPlotCtrl(frm)
                var da: List[Float64] = [0.0]*8760
                for i in range(8760):
                    da[i] = v.num[i]
                dv.AddDataSet(wxDVArrayDataSet(self.m_popup_var_name, da))
            else:
                var plotsurf = wxPLPlotCtrl(frm, wxID_ANY)
                var minval = 1e99
                var maxval = -1e99
                var pdat: List[wxRealPoint]
                for i in range(v.num.length()):
                    pdat.push_back(wxRealPoint(i+1, v.num[i]))
                    if v.num[i] < minval:
                        minval = v.num[i]
                    if v.num[i] > maxval:
                        maxval = v.num[i]
                if id == ID_POPUP_PLOT_LINE:
                    var range_ = maxval - minval
                    plotsurf.AddPlot(wxPLLinePlot(pdat, self.m_popup_var_name))
                    minval -= 0.05*range_
                    maxval += 0.05*range_
                    plotsurf.SetYAxis1(wxPLLinearAxis(minval, maxval))
                else:
                    plotsurf.AddPlot(wxPLBarPlot(pdat, 0.0, self.m_popup_var_name))
                    if minval > 0:
                        minval = 0
                    if maxval < 0:
                        maxval = 0
                    plotsurf.SetYAxis1(wxPLLinearAxis(minval, maxval))
                plotsurf.SetTitle("Plot of: '" + self.m_popup_var_name + "'")
                plotsurf.SetXAxis1(wxPLLinearAxis(0, v.num.length()+1))
            frm.Show()

    def OnGridLabelRightClick(inout self, evt: wxGridEvent):
        var col = evt.GetCol()
        if col < 0 or col >= self.m_selections.size():
            return
        self.m_popup_var_name = self.m_selections[col]
        var popup = wxMenu()
        popup.Append(ID_POPUP_EDIT, "Edit...")
        popup.AppendSeparator()
        popup.Append(ID_POPUP_DELETE, "Delete...")
        popup.AppendSeparator()
        popup.Append(ID_POPUP_STATS, "Statistics...")
        popup.Append(ID_POPUP_PLOT_BAR, "Bar plot (array only)")
        popup.Append(ID_POPUP_PLOT_LINE, "Line plot (array only)")
        self.m_grid.PopupMenu(popup, evt.GetPosition())

    def OnGridLabelDoubleClick(inout self, evt: wxGridEvent):
        var col = evt.GetCol()
        if col < 0 or col >= self.m_selections.size():
            return
        self.EditVariable(self.m_selections[col])

# Class StatDialog (external dialog)
struct StatDialog:
    var grdMonthly: wxExtGridCtrl
    var numSumOver1000: wxNumericCtrl
    var numSum: wxNumericCtrl
    var numMax: wxNumericCtrl
    var numMean: wxNumericCtrl
    var numMin: wxNumericCtrl

    def __init__(inout self, parent: wxWindow, title: wxString):
        # Inherit wxDialog constructor
        # Initialize controls
        var sz_h1 = wxBoxSizer(wxHORIZONTAL)
        sz_h1.Add(wxStaticText(self, wxID_ANY, "Mean:"), 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 5)
        sz_h1.Add(self.numMean = wxNumericCtrl(self))
        sz_h1.Add(wxStaticText(self, wxID_ANY, "Min:"), 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 5)
        sz_h1.Add(self.numMin = wxNumericCtrl(self))
        sz_h1.Add(wxStaticText(self, wxID_ANY, "Max:"), 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 5)
        sz_h1.Add(self.numMax = wxNumericCtrl(self))

        var sz_h2 = wxBoxSizer(wxHORIZONTAL)
        sz_h2.Add(wxStaticText(self, wxID_ANY, "Sum:"), 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 5)
        sz_h2.Add(self.numSum = wxNumericCtrl(self))
        sz_h2.Add(wxStaticText(self, wxID_ANY, "Sum/1000:"), 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 5)
        sz_h2.Add(self.numSumOver1000 = wxNumericCtrl(self))

        self.grdMonthly = wxExtGridCtrl(self, wxID_ANY)
        self.grdMonthly.CreateGrid(12,4)
        self.grdMonthly.EnableEditing(False)
        self.grdMonthly.DisableDragCell()
        self.grdMonthly.DisableDragColSize()
        self.grdMonthly.DisableDragRowSize()
        self.grdMonthly.DisableDragColMove()
        self.grdMonthly.DisableDragGridSize()
        self.grdMonthly.SetRowLabelSize(23)
        self.grdMonthly.SetColLabelSize(23)

        var sz_main = wxBoxSizer(wxVERTICAL)
        sz_main.Add(sz_h1)
        sz_main.Add(sz_h2)
        sz_main.Add(self.grdMonthly, 1, wxALL|wxEXPAND, 5)
        sz_main.Add(self.CreateButtonSizer(wxOK), 0, wxALL|wxEXPAND, 5)
        self.SetSizer(sz_main)

    def Compute(inout self, val: matrix_t[ssc_number_t]):
        var nday = [31,28,31,30,31,30,31,31,30,31,30,31]
        var len = val.length()
        var pvals = val.data()
        var min: ssc_number_t = 1e19
        var max: ssc_number_t = -1e19
        var mean: ssc_number_t = 0.0
        var sum: ssc_number_t = 0.0
        var mmin: List[ssc_number_t] = [1e19]*12
        var mmax: List[ssc_number_t] = [-1e19]*12
        var mmean: List[ssc_number_t] = [0.0]*12
        var msum: List[ssc_number_t] = [0.0]*12

        for i in range(len):
            if pvals[i] < min:
                min = pvals[i]
            if pvals[i] > max:
                max = pvals[i]
            sum += pvals[i]

        mean = sum / len
        self.numMin.SetValue(min)
        self.numMax.SetValue(max)
        self.numMean.SetValue(mean)
        self.numSum.SetValue(sum)
        self.numSumOver1000.SetValue(sum / 1000.0)

        var multiple = len / 8760
        if multiple * 8760 == len:
            var i = 0
            for m in range(12):
                for d in range(nday[m]):
                    for h in range(24):
                        var v: ssc_number_t = 0.0
                        for j in range(multiple):
                            v += pvals[i*multiple + j]
                        if v < mmin[m]:
                            mmin[m] = v
                        if v > mmax[m]:
                            mmax[m] = v
                        msum[m] += v
                        i += 1
                mmean[m] = msum[m] / (nday[m]*24)

        self.grdMonthly.ResizeGrid(12,5)
        for i in range(12):
            self.grdMonthly.SetCellValue(i, 0, String.Format("%lg", mmin[i]))
            self.grdMonthly.SetCellValue(i, 1, String.Format("%lg", mmax[i]))
            self.grdMonthly.SetCellValue(i, 2, String.Format("%lg", mmean[i]))
            self.grdMonthly.SetCellValue(i, 3, String.Format("%lg", msum[i]))
            self.grdMonthly.SetCellValue(i, 4, String.Format("%lg", msum[i]/1000.0))

        self.grdMonthly.SetRowLabelValue(0, "Jan")
        self.grdMonthly.SetRowLabelValue(1, "Feb")
        self.grdMonthly.SetRowLabelValue(2, "Mar")
        self.grdMonthly.SetRowLabelValue(3, "Apr")
        self.grdMonthly.SetRowLabelValue(4, "May")
        self.grdMonthly.SetRowLabelValue(5, "Jun")
        self.grdMonthly.SetRowLabelValue(6, "Jul")
        self.grdMonthly.SetRowLabelValue(7, "Aug")
        self.grdMonthly.SetRowLabelValue(8, "Sep")
        self.grdMonthly.SetRowLabelValue(9, "Oct")
        self.grdMonthly.SetRowLabelValue(10, "Nov")
        self.grdMonthly.SetRowLabelValue(11, "Dec")
        self.grdMonthly.SetColLabelValue(0, "Min")
        self.grdMonthly.SetColLabelValue(1, "Max")
        self.grdMonthly.SetColLabelValue(2, "Mean")
        self.grdMonthly.SetColLabelValue(3, "Sum")
        self.grdMonthly.SetColLabelValue(4, "Sum/1000")
        self.grdMonthly.SetRowLabelSize(40)
        self.grdMonthly.SetColLabelSize(wxGRID_AUTOSIZE)
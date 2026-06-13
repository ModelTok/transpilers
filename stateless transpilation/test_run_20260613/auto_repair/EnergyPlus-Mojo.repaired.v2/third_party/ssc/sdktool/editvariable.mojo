#/**
#BSD-3-Clause
#Copyright 2019 Alliance for Sustainable Energy, LLC
#Redistribution and use in source and binary forms, with or without modification, are permitted provided 
#that the following conditions are met :
#1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
#and the following disclaimer.
#2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
#and the following disclaimer in the documentation and/or other materials provided with the distribution.
#3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
#or promote products derived from this software without specific prior written permission.
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
#INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
#ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
#DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
#OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
#OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#*/
from wx.wx import *
from wx.grid import *
from dllinvoke import *
from wx.statline import *
from wex.numeric import *
from wex.extgrid import *
from editvariable import *

# enum {  ID_TYPE_STRING=wxID_HIGHEST+333,
# 		ID_TYPE_NUMBER,
# 		ID_TYPE_ARRAY,
# 		ID_TYPE_MATRIX,
# 		ID_FOCUS_STRING,
# 		ID_FOCUS_NUMBER,
# 		ID_numCols,
# 		ID_rbgVarType,
# 		ID_grdArrMat,
# 		ID_btnCancel,
# 		ID_btnAccept,
# 		ID_btnChooseFile,
# 		ID_txtValue,
# 		ID_numValue,
# 		ID_numRows }

const ID_TYPE_STRING = wxID_HIGHEST + 333
const ID_TYPE_NUMBER = ID_TYPE_STRING + 1
const ID_TYPE_ARRAY = ID_TYPE_NUMBER + 1
const ID_TYPE_MATRIX = ID_TYPE_ARRAY + 1
const ID_FOCUS_STRING = ID_TYPE_MATRIX + 1
const ID_FOCUS_NUMBER = ID_FOCUS_STRING + 1
const ID_numCols = ID_FOCUS_NUMBER + 1
const ID_rbgVarType = ID_numCols + 1
const ID_grdArrMat = ID_rbgVarType + 1
const ID_btnCancel = ID_grdArrMat + 1
const ID_btnAccept = ID_btnCancel + 1
const ID_btnChooseFile = ID_btnAccept + 1
const ID_txtValue = ID_btnChooseFile + 1
const ID_numValue = ID_txtValue + 1
const ID_numRows = ID_numValue + 1

#BEGIN_EVENT_TABLE( EditVariableDialog, wxDialog )
#	EVT_MENU( ID_TYPE_STRING, EditVariableDialog::OnShortcut )
#	EVT_MENU( ID_TYPE_NUMBER, EditVariableDialog::OnShortcut )
#	EVT_MENU( ID_TYPE_ARRAY, EditVariableDialog::OnShortcut )
#	EVT_MENU( ID_TYPE_MATRIX, EditVariableDialog::OnShortcut )
#	EVT_MENU( ID_FOCUS_STRING, EditVariableDialog::OnShortcut )
#	EVT_MENU( ID_FOCUS_NUMBER, EditVariableDialog::OnShortcut )
#	EVT_NUMERIC( ID_numRows, EditVariableDialog::OnRowsColsChange )
#	EVT_NUMERIC( ID_numCols, EditVariableDialog::OnRowsColsChange )
#	EVT_TEXT( ID_txtValue, EditVariableDialog::OnTextChange )
#	EVT_BUTTON( ID_btnChooseFile, EditVariableDialog::OnChooseFile )
#	EVT_NUMERIC( ID_numValue, EditVariableDialog::OnNumChange )
#	EVT_GRID_CMD_CELL_CHANGED( ID_grdArrMat, EditVariableDialog::OnGridCellChange )
#	EVT_RADIOBOX( ID_rbgVarType, EditVariableDialog::OnTypeChange )
#END_EVENT_TABLE()

class EditVariableDialog(wxDialog):
    def __init__(self, parent: wxWindow, title: wxString):
        super().__init__(parent, wxID_ANY, title, wxDefaultPosition, wxSize(800,600), 
            wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER)
        self.numRows = wxNumericCtrl(self, ID_numRows, 3, wxNUMERIC_INTEGER)
        self.numCols = wxNumericCtrl(self, ID_numCols, 4, wxNUMERIC_INTEGER)
        self.numValue = wxNumericCtrl(self, ID_numValue)
        self.txtValue = wxTextCtrl(self, ID_txtValue)
        self.btnChooseFile = wxButton(self, ID_btnChooseFile, "file..", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT)
        type_choices = wxArrayString()
        type_choices.Add("SSC_STRING")
        type_choices.Add("SSC_NUMBER")
        type_choices.Add("SSC_ARRAY")
        type_choices.Add("SSC_MATRIX")
        type_choices.Add("SSC_TABLE")
        self.rbgVarType = wxRadioBox(self, ID_rbgVarType, "Data type", wxDefaultPosition, wxDefaultSize, type_choices)
        self.grdArrMat = wxExtGridCtrl(self, ID_grdArrMat)
        self.grdArrMat.CreateGrid(2,2)
        self.grdArrMat.EnableEditing(true)
        self.grdArrMat.DisableDragCell()
        self.grdArrMat.DisableDragColSize()
        self.grdArrMat.DisableDragRowSize()
        self.grdArrMat.DisableDragColMove()
        self.grdArrMat.DisableDragGridSize()
        self.grdArrMat.SetRowLabelSize(23)
        self.grdArrMat.SetColLabelSize(23)
        sz_htop = wxBoxSizer(wxHORIZONTAL)
        sz_htop.Add(wxStaticText(self, wxID_ANY, "Numeric value:"), 0, wxALL | wxEXPAND | wxALIGN_CENTER_VERTICAL, 2)
        sz_htop.Add(self.numValue, 0, wxALL | wxEXPAND, 2)
        sz_htop.Add(wxStaticText(self, wxID_ANY, "String value:"), 0, wxALL | wxEXPAND | wxALIGN_CENTER_VERTICAL, 2)
        sz_htop.Add(self.txtValue, 0, wxALL | wxEXPAND, 2)
        sz_htop.Add(self.btnChooseFile)
        sz_htop.Add(wxStaticText(self, wxID_ANY, "# rows:"), 0, wxALL | wxEXPAND | wxALIGN_CENTER_VERTICAL, 2)
        sz_htop.Add(self.numRows, 0, wxALL | wxEXPAND, 2)
        sz_htop.Add(wxStaticText(self, wxID_ANY, "# cols:"), 0, wxALL | wxEXPAND | wxALIGN_CENTER_VERTICAL, 2)
        sz_htop.Add(self.numCols, 0, wxALL | wxEXPAND, 2)
        sz_main = wxBoxSizer(wxVERTICAL)
        sz_main.Add(self.rbgVarType, 0, wxALL | wxEXPAND, 10)
        sz_main.Add(sz_htop, 0, wxALL | wxEXPAND, 10)
        sz_main.Add(self.grdArrMat, 1, wxEXPAND | wxALL, 10)
        sz_main.Add(wxStaticText(self, wxID_ANY, "Shortcuts: F1=SSC_STRING, F2=SSC_NUMBER, F3=SSC_ARRAY, F4=SSC_MATRIX,\n"
            "F5=Change string value, F6=Change number value, F10=Accept changes, Esc=Cancel dialog"), 0, wxALL | wxEXPAND, 10)
        sz_main.Add(wxStaticLine(self, wxID_ANY), 0, wxALL | wxEXPAND, 3)
        sz_main.Add(self.CreateButtonSizer(wxOK | wxCANCEL), 0, wxALL | wxEXPAND, 10)
        self.SetSizer(sz_main)
        entries = [wxAcceleratorEntry() for _ in range(7)]
        entries[0].Set(wxACCEL_NORMAL, WXK_F1, ID_TYPE_STRING)
        entries[1].Set(wxACCEL_NORMAL, WXK_F2, ID_TYPE_NUMBER)
        entries[2].Set(wxACCEL_NORMAL, WXK_F3, ID_TYPE_ARRAY)
        entries[3].Set(wxACCEL_NORMAL, WXK_F4, ID_TYPE_MATRIX)
        entries[4].Set(wxACCEL_NORMAL, WXK_F5, ID_FOCUS_STRING)
        entries[5].Set(wxACCEL_NORMAL, WXK_F6, ID_FOCUS_NUMBER)
        entries[6].Set(wxACCEL_NORMAL, WXK_F10, wxID_OK)
        acceltab = wxAcceleratorTable(7, entries)
        self.SetAcceleratorTable(acceltab)

    def SetVarData(self, data: var_data):
        self.m_var = data
        self.UpdateForm()

    def GetVarData(self, data: var_data):
        data = self.m_var

    def UpdateForm(self):
        self.rbgVarType.SetSelection(self.m_var.type - 1)
        if self.m_var.type == SSC_STRING:
            self.txtValue.ChangeValue(self.m_var.str)
        if self.m_var.type == SSC_NUMBER:
            self.numValue.SetValue(self.m_var.num)
        if self.m_var.type == SSC_ARRAY:
            self.grdArrMat.Freeze()
            self.grdArrMat.ResizeGrid(self.m_var.num.length(), 1)
            self.numRows.SetValue(self.m_var.num.length())
            self.numCols.SetValue(1)
            i = 0
            while i < self.m_var.num.length():
                self.grdArrMat.SetCellValue(i, 0, wxString.Format("%lg", double(self.m_var.num[i])))
                i += 1
            self.grdArrMat.Thaw()
        if self.m_var.type == SSC_MATRIX:
            self.grdArrMat.Freeze()
            self.grdArrMat.ResizeGrid(self.m_var.num.nrows(), self.m_var.num.ncols())
            self.numRows.SetValue(self.m_var.num.nrows())
            self.numCols.SetValue(self.m_var.num.ncols())
            r = 0
            while r < self.m_var.num.nrows():
                c = 0
                while c < self.m_var.num.ncols():
                    self.grdArrMat.SetCellValue(r, c, wxString.Format("%lg", double(self.m_var.num.at(r, c))))
                    c += 1
                r += 1
            self.grdArrMat.Thaw()
        self.txtValue.Enable(self.m_var.type == SSC_STRING)
        self.numValue.Enable(self.m_var.type == SSC_NUMBER)
        self.grdArrMat.Enable(self.m_var.type == SSC_ARRAY or self.m_var.type == SSC_MATRIX)
        self.numRows.Enable(self.m_var.type == SSC_ARRAY or self.m_var.type == SSC_MATRIX)
        self.numCols.Enable(self.m_var.type == SSC_MATRIX)
        if self.m_var.type == SSC_NUMBER:
            self.numValue.SelectAll()
            self.numValue.SetFocus()

    def OnTypeChange(self, evt: wxCommandEvent):
        self.m_var.type = self.rbgVarType.GetSelection() + 1
        self.UpdateForm()

    def OnShortcut(self, evt: wxCommandEvent):
        if evt.GetId() == ID_TYPE_STRING:
            self.m_var.type = SSC_STRING
            self.UpdateForm()
        elif evt.GetId() == ID_TYPE_NUMBER:
            self.m_var.type = SSC_NUMBER
            self.UpdateForm()
        elif evt.GetId() == ID_TYPE_ARRAY:
            self.m_var.type = SSC_ARRAY
            self.UpdateForm()
        elif evt.GetId() == ID_TYPE_MATRIX:
            self.m_var.type = SSC_MATRIX
            self.UpdateForm()
        elif evt.GetId() == ID_FOCUS_STRING:
            self.txtValue.SetFocus()
            self.txtValue.SelectAll()
        elif evt.GetId() == ID_FOCUS_NUMBER:
            self.numValue.SetFocus()
            self.numValue.SelectAll()

    def OnTextChange(self, evt: wxCommandEvent):
        self.m_var.str = self.txtValue.GetValue()

    def OnNumChange(self, evt: wxCommandEvent):
        self.m_var.num = double(self.numValue.AsDouble())

    def OnGridCellChange(self, evt: wxGridEvent):
        r = evt.GetRow()
        c = evt.GetCol()
        if r < 0 or c < 0:
            return
        val = wxAtof(self.grdArrMat.GetCellValue(r, c))
        if self.m_var.type == SSC_MATRIX:
            if r < int(self.m_var.num.nrows()) and c < int(self.m_var.num.ncols()):
                self.m_var.num.at(r, c) = val
        elif self.m_var.type == SSC_ARRAY:
            if r < int(self.m_var.num.length()):
                self.m_var.num[r] = val
        self.grdArrMat.SetCellValue(r, c, wxString.Format("%lg", val))

    def OnChooseFile(self, evt: wxCommandEvent):
        fd = wxFileDialog(self, "Choose a file")
        if fd.ShowModal() == wxID_OK:
            file = fd.GetPath()
            file.Replace("\\", "/")
            self.txtValue.ChangeValue(file)
            self.m_var.str = file

    def OnRowsColsChange(self, evt: wxCommandEvent):
        nr = size_t(self.numRows.AsInteger())
        nc = size_t(self.numCols.AsInteger())
        if self.m_var.type == SSC_ARRAY:
            old = util.matrix_t[ssc_number_t]()
            old.copy(self.m_var.num)
            self.m_var.num.resize_fill(nr, 0.0)
            i = 0
            while i < self.m_var.num.length():
                self.m_var.num[i] = old[i] if i < old.length() else 0.0
                i += 1
        else:
            old = util.matrix_t[ssc_number_t]()
            old.copy(self.m_var.num)
            self.m_var.num.resize_fill(nr, nc, 0.0)
            r = 0
            while r < nr:
                c = 0
                while c < nc:
                    self.m_var.num.at(r, c) = old.at(r, c) if r < old.nrows() and c < old.ncols() else 0.0
                    c += 1
                r += 1
        self.UpdateForm()
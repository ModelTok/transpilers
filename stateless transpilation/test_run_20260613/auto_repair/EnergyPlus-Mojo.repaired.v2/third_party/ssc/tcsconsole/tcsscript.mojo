# /**
# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met :
# 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# */

from tcslayout import *
from tcsmain import *
from wex.lkscript import *
from wex.utils import *

def fcall_clear(cxt: lk.invoke_t):
	# LK_DOC("clear", "Clear all units and connections.", "(none):string")
	tcFrame.Instance().GetKernel().clear_units()

def fcall_add_unit(cxt: lk.invoke_t):
	# LK_DOC("add_unit", "Add a unit to the simulator.", "(string:type name, [string:description]):integer")	
	var name = cxt.arg(0).as_string()
	var desc = ""
	if cxt.arg_count() > 1:
		desc = cxt.arg(1).as_string()
	var unit = tcFrame.Instance().GetKernel().add_unit(str(name), str(desc))
	cxt.result().assign(unit)

def fcall_set_value(cxt: lk.invoke_t):
	# LK_DOC("set_value", "Set a variable value for a unit.  Values can be a number, string, array, or 2D array.", "(integer:unit, string:variable name, any:value):void" )
	var u = cxt.arg(0).as_integer()
	var var_ = cxt.arg(1).as_string()
	var kern = tcFrame.Instance().GetKernel()
	var val = cxt.arg(2).deref()
	if val.type() == lk.vardata_t.NUMBER:
		kern.set_unit_value(u, str(var_), val.as_number())
	elif val.type() == lk.vardata_t.STRING:
		kern.set_unit_value(u, str(var_), str(val.as_string()))
	elif val.type() == lk.vardata_t.VECTOR:
		var dim1 = val.length()
		var dim2 = 0
		for i in range(val.length()):
			var row = val.index(i)
			if row.type() == lk.vardata_t.VECTOR and row.length() > dim2:
				dim2 = row.length()
		if dim2 == 0 and dim1 > 0:
			var p = DoublePointer(dim1)
			for i in range(dim1):
				p[i] = val.index(i).as_number()
			kern.set_unit_value(u, str(var_), p, dim1)
			del p
		elif dim1 > 0 and dim2 > 0:
			var p = DoublePointer(dim1 * dim2)
			for i in range(dim1):
				for j in range(dim2):
					var x = 0.0
					if val.index(i).type() == lk.vardata_t.VECTOR and j < val.index(i).length():
						x = val.index(i).index(j).as_number()
					p[dim2 * i + j] = x
			kern.set_unit_value(u, str(var_), p, dim1, dim2)
			del p

def fcall_get_result(cxt: lk.invoke_t):
	# LK_DOC("get_result", "Obtain the values of for a particular variable at all timesteps after a simulation.", "(integer:unit, string:variable name):array")
	var unit = cxt.arg(0).as_integer()
	var var_ = str(cxt.arg(1).as_string())
	var kern = tcFrame.Instance().GetKernel()
	var ds = tcKernel.dataset()
	var idx = 0
	ds = kern.get_results(idx)
	while ds:
		if ds.uidx == unit and str(ds.name) == var_:
			cxt.result().empty_vector()
			cxt.result().vec().reserve(len(ds.values))
			if ds.type == TCS_NUMBER:
				for j in range(len(ds.values)):
					cxt.result().vec_append(ds.values[j].dval)
			else:
				for j in range(len(ds.values)):
					cxt.result().vec_append(lk_string(ds.values[j].sval))
			return
		idx += 1
		ds = kern.get_results(idx)

def fcall_connect(cxt: lk.invoke_t):
	# LK_DOC("connect", "Make a connection from an output to an input.", "(integer:unit1, string:output name, integer:unit2, string:input name, [number:ftol=0.1], [number:arridx=-1]):boolean" )
	var u1 = cxt.arg(0).as_integer()
	var out_ = cxt.arg(1).as_string()
	var u2 = cxt.arg(2).as_integer()
	var in_ = cxt.arg(3).as_string()
	var ftol = 0.1
	var arridx = -1
	if cxt.arg_count() > 4:
		ftol = cxt.arg(4).as_number()
	if cxt.arg_count() > 5:
		arridx = cxt.arg(5).as_integer()
	var ok = tcFrame.Instance().GetKernel().connect(u1, str(out_), u2, str(in_), ftol, arridx)
	cxt.result().assign(ok)

def fcall_simulate(cxt: lk.invoke_t):
	# LK_DOC("simulate", "Run a simulation in the given time range specified in hours.", "(number:start, number:end, number:step, [number:maxiter=100], [boolean:store array,matrix data vars], [boolean:proceed even if max iter reached]):number")
	var start = cxt.arg(0).as_number() * 3600.0
	var end = cxt.arg(1).as_number() * 3600.0
	var step = cxt.arg(2).as_number() * 3600.0
	var maxiter = 100
	var store_arrmat = False
	var proceed_anyway = True
	if cxt.arg_count() > 3:
		maxiter = cxt.arg(3).as_integer()
	if cxt.arg_count() > 4:
		store_arrmat = cxt.arg(4).as_boolean()
	if cxt.arg_count() > 5:
		proceed_anyway = cxt.arg(5).as_boolean()
	var code = tcFrame.Instance().Simulate(start, end, step, maxiter, store_arrmat, proceed_anyway)
	cxt.result().assign(code)

def fcall_netlist(cxt: lk.invoke_t):
	# LK_DOC("netlist", "Generate a netlist description of the current configuration.", "(void):string")
	cxt.result().assign(tcFrame.Instance().GetKernel().netlist())

def fcall_open_visual(cxt: lk.invoke_t):
	# LK_DOC("open_visual", "Open a .tcs file in the visual editor.  Does not check for existing modifications before overwriting the visual editors current contents.", "(string:file name):boolean")
	cxt.result().assign(tcFrame.Instance().GetVisualEditor().LoadFile(str(cxt.arg(0).as_string())))

def fcall_load_visual(cxt: lk.invoke_t):
	# LK_DOC("load_visual", "Loads the current system in the visual editor into the kernel.", "(none):boolean")
	cxt.result().assign(tcFrame.Instance().GetVisualEditor().GetLayout().LoadSystemInKernel(tcFrame.Instance().GetKernel()))

def fcall_timevec(cxt: lk.invoke_t):
	# LK_DOC("timevec", "Returns a time vector array specified by the parameters.", "(real:start, real:stop, real:step):array")
	var start = cxt.arg(0).as_number()
	var end = cxt.arg(1).as_number()
	var step = 1.0
	if cxt.arg_count() > 2:
		step = cxt.arg(2).as_number()
	if step <= 0:
		return
	if end <= start:
		return
	cxt.result().empty_vector()
	var time = start
	while time <= end:
		cxt.result().vec_append(time)
		time += step

def fcall_datatablevariable(cxt: lk.invoke_t):
	# LK_DOC("datatablevariable", "Add specified variable name to the data table.", "(string:varname):void")
	if cxt.arg_count() > 0:
		tcFrame.Instance().AddVariableToDataTable(cxt.arg(0).as_string())

def fcall_cleardatatableselections(cxt: lk.invoke_t):
	# LK_DOC("cleardatatableselections", "Clear the selected variables in the data table.", "(string:varname):void")
	tcFrame.Instance().ClearDataTableSelections()

# from wx.thread import *

class ThreadProgressDialog(wxDialog):
	var m_canceled: Bool
	var m_progbars: List[wxGauge]
	var m_percents: List[wxTextCtrl]
	var m_log: wxTextCtrl

	def IsCanceled(self) -> Bool:
		return self.m_canceled

	def Log(self, text: wxString):
		self.m_log.AppendText(text + "\n")

	def LogList(self, list: wxArrayString):
		for i in range(list.Count()):
			self.Log(list[i])

	def Update(self, ThreadNum: Int, percent: Float32):
		if ThreadNum >= 0 and ThreadNum < len(self.m_progbars):
			self.m_progbars[ThreadNum].SetValue(Int(percent))
			self.m_percents[ThreadNum].SetValue(wxString.Format("%.1f %%", percent))

	def __init__(self, parent: wxWindow, nthreads: Int):
		wxDialog.__init__(self, parent, wxID_ANY, wxString("Thread Progress"), wxDefaultPosition, wxSize(700, 600), wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER)
		self.m_canceled = False
		var btnCancel = wxButton(self, wxID_CANCEL, "Cancel", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT)
		var szv = wxBoxSizer(wxVERTICAL)
		for i in range(nthreads):
			var sizer = wxBoxSizer(wxHORIZONTAL)
			sizer.Add(wxStaticText(self, wxID_ANY, wxString.Format("thread %d", i)), 0, wxALL | wxALIGN_CENTER_VERTICAL, 3)
			var gauge = wxGauge(self, wxID_ANY, 100)
			var text = wxTextCtrl(self, wxID_ANY, wxEmptyString, wxDefaultPosition, wxDefaultSize, wxTE_READONLY)
			sizer.Add(gauge, 1, wxALL | wxEXPAND, 3)
			sizer.Add(text, 0, wxALL | wxEXPAND, 3)
			self.m_progbars.append(gauge)
			self.m_percents.append(text)
			szv.Add(sizer, 0, wxEXPAND | wxALL, 5)
		szv.Add(wxStaticLine(self), 0, wxEXPAND | wxALL, 4)
		self.m_log = wxTextCtrl(self, wxID_ANY, wxEmptyString, wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE)
		szv.Add(self.m_log, 1, wxALL | wxEXPAND, 3)
		var szh = wxBoxSizer(wxHORIZONTAL)
		szh.AddStretchSpacer()
		szh.Add(btnCancel, 0, wxALIGN_CENTER_VERTICAL | wxALL, 2)
		szv.Add(szh, 0, wxEXPAND | wxALL, 4)
		self.SetSizer(szv)

	def OnCancel(self, evt: wxCommandEvent):
		self.m_canceled = True

	def OnDialogClose(self, evt: wxCloseEvent):
		self.m_canceled = True

class ThreadedKernel(wxThread, tcskernel):
	var m_threadId: Int
	var m_start: Float64
	var m_end: Float64
	var m_step: Float64
	var m_proceedAnyways: Bool
	var m_maxIter: Int
	var m_simResult: Int
	var m_ok: Bool
	var m_runLock: wxMutex
	var m_cancelLock: wxMutex
	var m_percentLock: wxMutex
	var m_logLock: wxMutex
	var m_running: Bool
	var m_canceled: Bool
	var m_percent: Float32
	var m_messages: wxArrayString

	def __init__(self, setup: tcskernel, prov: tcstypeprovider, thread_id: Int, start: Float64, end: Float64, step: Float64, proceed: Bool, maxiter: Int):
		wxThread.__init__(self, wxTHREAD_JOINABLE)
		tcskernel.__init__(self, prov)
		self.m_threadId = thread_id
		self.m_start = start
		self.m_end = end
		self.m_step = step
		self.m_proceedAnyways = proceed
		self.m_maxIter = maxiter
		self.m_simResult = 0
		self.m_canceled = False
		self.m_percent = 0.0
		self.m_running = False
		self.m_ok = False
		if self.copy(setup) == 0:
			self.m_ok = True

	def __del__(self):

	def GetPercent(self) -> Float32:
		return self.m_percent

	def GetId(self) -> Int:
		return self.m_threadId

	def Cancel(self):
		var _lock = wxMutexLocker(self.m_cancelLock)
		self.m_canceled = True

	def log(self, text: String):
		var _lock = wxMutexLocker(self.m_logLock)
		self.m_messages.Add(wxString.Format("thread %d: ", self.m_threadId) + wxString(text))

	def converged(self, time: Float64) -> Bool:
		if self.m_step != 0.0:
			var istep = Int((time - self.m_start) / self.m_step)
			var nstep = Int((self.m_end - self.m_start) / self.m_step)
			var nnsteps = nstep // 400
			if nnsteps == 0:
				nnsteps = 1
			if istep % nnsteps == 0:
				var _lock = wxMutexLocker(self.m_percentLock)
				self.m_percent = Float32(100.0 * (Float64(istep) / Float64(nstep)))
		return not self.m_canceled

	def GetNewMessages(self) -> wxArrayString:
		var _lock = wxMutexLocker(self.m_logLock)
		var list = self.m_messages
		self.m_messages.Clear()
		return list

	def IsOk(self) -> Bool:
		return self.m_ok

	def IsRunning(self) -> Bool:
		var _lock = wxMutexLocker(self.m_runLock)
		return self.m_running

	def Entry(self) -> Pointer[None]:
		if not self.m_ok:
			return None
		self.m_canceled = False
		self.m_running = True
		self.set_max_iterations(self.m_maxIter, self.m_proceedAnyways)
		self.m_simResult = self.simulate(self.m_start, self.m_end, self.m_step)
		self.m_running = False
		return None

def fcall_parallel(cxt: lk.invoke_t):
	# LK_DOC("parallel", "Runs parallel simulations as defined by a parametric table.", "(array:parametric tables, string:outputs desired, number:start, number:end, number:step, [number:maxiter=100], [boolean:store array,matrix data vars], [boolean:proceed even if max iter reached], [number:maxcpus]):array")
	var start = cxt.arg(2).as_number() * 3600.0
	var end = cxt.arg(3).as_number() * 3600.0
	var step = cxt.arg(4).as_number() * 3600.0
	var maxiter = 100
	var store_arrmat = False
	var proceed_anyway = True
	var nthread = -1
	if cxt.arg_count() > 5:
		maxiter = cxt.arg(5).as_integer()
	if cxt.arg_count() > 6:
		store_arrmat = cxt.arg(6).as_boolean()
	if cxt.arg_count() > 7:
		proceed_anyway = cxt.arg(7).as_boolean()
	if cxt.arg_count() > 8:
		nthread = cxt.arg(8).as_integer()
	if nthread < 1:
		nthread = wxThread.GetCPUCount()
	var tpd = ThreadProgressDialog(tcFrame.Instance(), nthread)
	tpd.Show()
	var sw = wxStopWatch()
	var threads = List[ThreadedKernel]()
	for i in range(nthread):
		var t = ThreadedKernel(tcFrame.Instance().GetKernel(), tcFrame.Instance().GetTypeProvider(), i, start, end, step, store_arrmat, proceed_anyway, maxiter)
		threads.append(t)
		t.Create()
	var parlist = cxt.arg(0)
	if parlist.type() == lk.vardata_t.VECTOR:
		for i in range(min(parlist.length(), nthread)):
			var vallist = parlist.index(i).deref()
			if vallist.type() == lk.vardata_t.VECTOR:
				for j in range(vallist.length()):
					var tab = vallist.index(j).deref()
					var unit = tab.lookup("unit")
					var var_ = tab.lookup("variable")
					var val = tab.lookup("value")
					if unit and var_ and val:
						var uid = unit.as_integer()
						var varid = var_.as_string()
						if val.type() == lk.vardata_t.NUMBER:
							threads[i].set_unit_value(uid, str(varid), val.as_number())
							tcFrame.Instance().Log(wxString.Format("thread %d unit %d variable '%s' = %f\n", i, uid, str(varid), val.as_number()))
						elif val.type() == lk.vardata_t.STRING:
							threads[i].set_unit_value(uid, str(varid), str(val.as_string()))
							tcFrame.Instance().Log(wxString.Format("thread %d unit %d variable '%s' = '%s'\n", i, uid, str(varid), str(val.as_string())))
					else:
						tcFrame.Instance().Log(wxString.Format("par %d list %d: did not find 'unit' 'variable' and 'value' fields\n", i, j))
			else:
				tcFrame.Instance().Log(wxString.Format("par %d: each parametric structure must be an array of tables\n", i))
	else:
		tcFrame.Instance().Log("invalid parametric run structure\n")
	tcFrame.Instance().Log(wxString.Format("thread creation time: %d ms\n", sw.Time()))
	sw.Start()
	for i in range(nthread):
		threads[i].Run()
	tcFrame.Instance().Log(wxString.Format("thread start time: %d ms\n", sw.Time()))
	sw.Start()
	while True:
		var num_finished = 0
		for i in range(len(threads)):
			if not threads[i].IsRunning():
				num_finished += 1
		if num_finished == len(threads):
			break
		for i in range(len(threads)):
			var per = threads[i].GetPercent()
			tpd.Update(i, per)
			var msgs = threads[i].GetNewMessages()
			tpd.LogList(msgs)
		wxGetApp().Yield()
		if tpd.IsCanceled():
			for i in range(len(threads)):
				threads[i].Cancel()
		wxMilliSleep(100)
	for i in range(len(threads)):
		threads[i].Wait()
	tcFrame.Instance().Log(wxString.Format("thread total run time: %d ms\n", sw.Time()))
	for i in range(len(threads)):
		del threads[i]
	threads.clear()

def tcs_funcs() -> lk.fcall_t:
	var vec = List[lk.fcall_t]()
	vec.append(fcall_clear)
	vec.append(fcall_add_unit)
	vec.append(fcall_set_value)
	vec.append(fcall_connect)
	vec.append(fcall_simulate)
	vec.append(fcall_parallel)
	vec.append(fcall_netlist)
	vec.append(fcall_get_result)
	vec.append(fcall_open_visual)
	vec.append(fcall_load_visual)
	vec.append(fcall_timevec)
	vec.append(fcall_datatablevariable)
	vec.append(fcall_cleardatatableselections)
	vec.append(0)
	return vec

var ID_FIND_NEXT = wxID_HIGHEST + 124

# BEGIN_EVENT_TABLE( tcScriptEditor, wxPanel )
# 	EVT_BUTTON( wxID_NEW, tcScriptEditor::OnAction )
# 	EVT_BUTTON( wxID_OPEN, tcScriptEditor::OnAction )
# 	EVT_BUTTON( wxID_SAVE, tcScriptEditor::OnAction )
# 	EVT_BUTTON( wxID_SAVEAS, tcScriptEditor::OnAction )
# 	EVT_BUTTON( wxID_FIND, tcScriptEditor::OnAction )
# 	EVT_BUTTON( wxID_FORWARD, tcScriptEditor::OnAction )
# 	EVT_BUTTON( wxID_HELP, tcScriptEditor::OnHelp )
# 	EVT_BUTTON( ID_FIND_NEXT, tcScriptEditor::OnAction )
# END_EVENT_TABLE()

class MyScriptCtrl(wxLKScriptCtrl):
	def __init__(self, parent: wxWindow, id: Int = wxID_ANY):
		wxLKScriptCtrl.__init__(self, parent, id, wxDefaultPosition, wxDefaultSize, wxLK_STDLIB_ALL | wxLK_STDLIB_SOUT)

	def OnEval(self) -> Bool:
		wxGetApp().Yield(True)
		return True

	def OnOutput(self, tt: wxString):
		self.Log(tt)

class tcScriptEditor(wxPanel):
	var m_editor: MyScriptCtrl
	var m_fileName: wxString
	var m_statusLabel: wxStaticText
	var m_stopButton: wxButton

	def __init__(self, p: wxWindow):
		wxPanel.__init__(self, p, wxID_ANY, wxDefaultPosition, wxDefaultSize)
		var sztools = wxBoxSizer(wxHORIZONTAL)
		sztools.Add(wxButton(self, wxID_NEW, "New", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		sztools.Add(wxButton(self, wxID_OPEN, "Open", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		sztools.Add(wxButton(self, wxID_SAVE, "Save", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		sztools.Add(wxButton(self, wxID_SAVEAS, "Save as", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		sztools.Add(wxButton(self, wxID_FORWARD, "Run", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		self.m_stopButton = wxButton(self, wxID_STOP, "Stop", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT)
		self.m_stopButton.SetForegroundColour(*wxRED)
		sztools.Add(self.m_stopButton, 0, wxALL | wxEXPAND, 2)
		self.m_stopButton.Show(False)
		sztools.Add(wxButton(self, wxID_FIND, "Find", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		sztools.Add(wxButton(self, ID_FIND_NEXT, "Find next", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		sztools.Add(wxButton(self, wxID_HELP, "Help", wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT), 0, wxALL | wxEXPAND, 2)
		self.m_statusLabel = wxStaticText(self, wxID_ANY, wxEmptyString)
		sztools.Add(self.m_statusLabel, 0, wxALL | wxALIGN_CENTER_VERTICAL, 2)
		self.m_editor = MyScriptCtrl(self, wxID_ANY)
		self.m_editor.RegisterLibrary(tcs_funcs(), "TCS Functions", self)
		var szmain = wxBoxSizer(wxVERTICAL)
		szmain.Add(sztools, 0, wxALL | wxEXPAND, 2)
		szmain.Add(wxStaticLine(self), 0, wxALL | wxEXPAND, 0)
		szmain.Add(self.m_editor, 1, wxALL | wxEXPAND)
		self.SetSizer(szmain)

	def IsModified(self) -> Bool:
		return self.m_editor.GetModify()

	def Save(self) -> Bool:
		if self.m_fileName.IsEmpty():
			return self.SaveAs()
		else:
			return self.Write(self.m_fileName)

	def SaveAs(self) -> Bool:
		var dlg = wxFileDialog(self, "Save as...", wxPathOnly(self.m_fileName), wxFileNameFromPath(self.m_fileName), "LK Script Files (*.lk)|*.lk", wxFD_SAVE | wxFD_OVERWRITE_PROMPT)
		if dlg.ShowModal() == wxID_OK:
			return self.Write(dlg.GetPath())
		else:
			return False

	def OnHelp(self, evt: wxCommandEvent):
		self.m_editor.ShowHelpDialog(self)

	def CloseDoc(self) -> Bool:
		if self.m_editor.GetModify():
			var result = wxMessageBox("Script modified. Save it?", "Query", wxYES_NO | wxCANCEL)
			if result == wxCANCEL or (result == wxYES and not self.Save()):
				return False
		self.m_editor.SetText("")
		self.m_editor.EmptyUndoBuffer()
		self.m_editor.SetSavePoint()
		self.m_fileName = ""
		self.m_statusLabel.SetLabel(wxEmptyString)
		return True

	def Write(self, file: wxString) -> Bool:
		if wxStyledTextCtrl(self.m_editor).SaveFile(file):
			self.m_fileName = file
			self.m_statusLabel.SetLabel(self.m_fileName)
			return True
		else:
			return False

	def Load(self, file: wxString) -> Bool:
		var fp = fopen(str(file), "r")
		if fp:
			var str_ = ""
			var buf = " " * 1023
			while fgets(buf, 1023, fp):
				str_ += str(buf)
			fclose(fp)
			self.m_editor.SetText(str_)
			self.m_editor.EmptyUndoBuffer()
			self.m_editor.SetSavePoint()
			self.m_statusLabel.SetLabel(file)
			self.m_fileName = file
			return True
		else:
			return False

	def OnAction(self, evt: wxCommandEvent):
		if evt.GetId() == wxID_OPEN:
			var dlg = wxFileDialog(self, "Open", wxEmptyString, wxEmptyString, "LK Script Files (*.lk)|*.lk", wxFD_OPEN | wxFD_FILE_MUST_EXIST | wxFD_CHANGE_DIR)
			if dlg.ShowModal() == wxID_OK:
				if not self.Load(dlg.GetPath()):
					wxMessageBox("Could not load file:\n\n" + dlg.GetPath())
		elif evt.GetId() == wxID_SAVE:
			self.Save()
		elif evt.GetId() == wxID_SAVEAS:
			self.SaveAs()
		elif evt.GetId() == wxID_NEW:
			self.CloseDoc()
		elif evt.GetId() == wxID_FIND:
			self.m_editor.ShowFindReplaceDialog()
		elif evt.GetId() == ID_FIND_NEXT:
			self.m_editor.FindNext()
		elif evt.GetId() == wxID_FORWARD:
			self.Exec()
		elif evt.GetId() == wxID_STOP:
			self.m_editor.Stop()
		else:

	def Exec(self):
		if not self.m_fileName.IsEmpty():
			wxStyledTextCtrl(self.m_editor).SaveFile(self.m_fileName + "~")
		self.ClearLog()
		self.Log("Start: " + wxNow() + "\n")
		self.m_stopButton.Show()
		self.Layout()
		wxGetApp().Yield(True)
		self.m_editor.Execute()
		if self.m_stopButton.IsShown():
			self.m_stopButton.Hide()
			self.Layout()
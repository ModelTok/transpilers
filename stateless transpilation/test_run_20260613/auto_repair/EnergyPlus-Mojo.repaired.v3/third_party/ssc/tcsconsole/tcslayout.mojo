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
from wx import *
from tcskernel import *
from wx.valtext import *
from wx.dcbuffer import *
from wx.grid import *
from wx.imaglist import *
from wx.gdicmn import *
from wx.paper import *
from wx.tokenzr import *
from wx.datstrm import *
from wx.busyinfo import *
from wx.wfstream import *
from wx.clipbrd import *
from tcslayout import *

alias ID_popup_first = 0
alias ID_CREATE = 2134
alias ID_CREATE_LAST = 3215
alias ID_MOVE_UP = 2134 + 1
alias ID_MOVE_DOWN = 2134 + 2
alias ID_DELETE_UNIT = 2134 + 3
alias ID_DELETE_CONNECTION = 2134 + 4
alias ID_DELETE_ALL_CONNECTIONS = 2134 + 5
alias ID_ADD_WAYPOINT = 2134 + 6
alias ID_DELETE_WAYPOINT = 2134 + 7
alias ID_EDIT_CONNECTION = 2134 + 8
alias ID_EDIT_UNIT = 2134 + 9
alias ID_COPY_VIEW = 2134 + 10
alias ID_popup_last = 2134 + 11

# BEGIN_EVENT_TABLE(tcLayoutCtrl, wxWindow)
# 	EVT_MENU_RANGE( ID_popup_first, ID_popup_last, tcLayoutCtrl::OnPopup )
# 	EVT_PAINT(tcLayoutCtrl::OnPaint)
# 	EVT_SIZE(tcLayoutCtrl::OnSize)
# 	EVT_LEFT_DOWN( tcLayoutCtrl::OnLeftDown )
# 	EVT_LEFT_DCLICK( tcLayoutCtrl::OnLeftDouble )
# 	EVT_LEFT_UP( tcLayoutCtrl::OnLeftUp )
# 	EVT_RIGHT_DOWN( tcLayoutCtrl::OnRightDown )
# 	EVT_MOTION( tcLayoutCtrl::OnMouseMove )
# 	EVT_CHAR( tcLayoutCtrl::OnChar )
# END_EVENT_TABLE()

@value
struct tcLayoutCtrl:
    var m_units: List[tcUnit] = List[tcUnit]()
    var m_conns: List[tcConn] = List[tcConn]()
    var m_types: List[tcType] = List[tcType]()
    var m_offsetX: Int = 0
    var m_offsetY: Int = 0
    var m_snapSpacing: Int = 10
    var m_mouseLastX: Int = 0
    var m_mouseLastY: Int = 0
    var m_popupX: Int = 0
    var m_popupY: Int = 0
    var m_statusHeight: Int = 20
    var m_modified: Bool = False
    var m_currentUnit: tcUnit? = None
    var m_currentUnitIndex: Int = -1
    var m_currentConnPt: tcConnPt? = None
    var m_currentConn: tcConn? = None
    var m_currentWaypointConn: tcConn? = None
    var m_currentWaypointIndex: Int = -1
    var m_moveModeErase: Bool = False
    var m_movingUnit: tcUnit? = None
    var m_origX: Int = 0
    var m_origY: Int = 0
    var m_diffX: Int = 0
    var m_diffY: Int = 0
    var m_lastLineX: Int = 0
    var m_lastLineY: Int = 0
    var m_lineModeErase: Bool = False
    var m_movingWaypointConn: tcConn? = None
    var m_movingWaypointIndex: Int = -1
    var m_moveWaypointErase: Bool = False
    var m_moveWaypointLastXY: wxPoint = wxPoint(0,0)
    var m_error: String = ""
    var m_popupMenu: wxMenu? = None
    var m_statusText: wxTextCtrl? = None
    var m_overlay: wxOverlay = wxOverlay()

    def __init__(inout self, parent: wxWindow, id: Int, pos: wxPoint = wxDefaultPosition, size: wxSize = wxDefaultSize):
        wxWindow.__init__(self, parent, id, pos, size, wxWANTS_CHARS|wxCLIP_CHILDREN)
        self.SetBackgroundStyle(wxBG_STYLE_CUSTOM)
        self.m_statusText = wxTextCtrl(this, wxID_ANY, "ready", wxPoint(0,0), wxSize(size.GetWidth(), 23), wxBORDER_NONE|wxTE_READONLY)
        self.m_statusText.SetBackgroundColour(*wxWHITE)
        self.m_statusText.SetForegroundColour(*wxBLUE)
        var fontSize: Int = 10
        #ifdef __WXMAC__
        #	fontSize = 12
        #endif
        self.m_statusText.SetFont(wxFont(fontSize, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, False, "Consolas"))
        self.m_modified = False
        self.m_snapSpacing = 10
        self.m_mouseLastX = 0
        self.m_mouseLastY = 0
        self.m_popupX = 0
        self.m_popupY = 0
        self.m_popupMenu = None
        self.m_offsetX = 0
        self.m_offsetY = 0
        self.m_currentUnit = None
        self.m_currentUnitIndex = -1
        self.m_currentConnPt = None
        self.m_currentConn = None
        self.m_currentWaypointConn = None
        self.m_currentWaypointIndex = -1
        self.m_movingUnit = None
        self.m_moveModeErase = False
        self.m_origX = 0
        self.m_origY = 0
        self.m_diffX = 0
        self.m_diffY = 0
        self.m_lineModeErase = False
        self.m_lastLineX = 0
        self.m_lastLineY = 0
        self.m_movingWaypointConn = None
        self.m_movingWaypointIndex = -1
        self.m_moveWaypointErase = False
        self.m_moveWaypointLastXY = wxPoint(0,0)
        self.m_statusHeight = 20
        self.CreatePopupMenu()
        self.SetCursor(wxCursor(wxCURSOR_ARROW))

    def __del__(owned self):
        self.Clear()

    def AddType(inout self, name: String, ti: tcstypeinfo, meta: String = ""):
        for i in range(len(self.m_types)):
            if self.m_types[i].name == name:
                return
        self.m_types.append(tcType(name, ti, meta))

    def Clear(inout self):
        for i in range(len(self.m_units)):
            del self.m_units[i]
        self.m_units.clear()
        for i in range(len(self.m_conns)):
            del self.m_conns[i]
        self.m_conns.clear()
        self.Modify()

    def CreatePopupMenu(inout self):
        if self.m_popupMenu is not None:
            del self.m_popupMenu
        self.m_popupMenu = wxMenu()
        for i in range(len(self.m_types)):
            self.m_popupMenu.Append(ID_CREATE + i, "Create " + self.m_types[i].name)
        if len(self.m_types) > 1:
            self.m_popupMenu.AppendSeparator()
        self.m_popupMenu.Append(ID_DELETE_UNIT, "Delete unit")
        self.m_popupMenu.Append(ID_DELETE_CONNECTION, "Delete connection")
        self.m_popupMenu.Append(ID_DELETE_ALL_CONNECTIONS, "Delete all connections at this point")
        self.m_popupMenu.Append(ID_ADD_WAYPOINT, "Add waypoint nearby")
        self.m_popupMenu.Append(ID_DELETE_WAYPOINT, "Delete waypoint")
        self.m_popupMenu.AppendSeparator()
        self.m_popupMenu.Append(ID_EDIT_CONNECTION, "Edit connection...")
        self.m_popupMenu.Append(ID_EDIT_UNIT, "Edit unit values...")
        self.m_popupMenu.Append(ID_MOVE_UP, "Move up (order)")
        self.m_popupMenu.Append(ID_MOVE_DOWN, "Move down (order)")
        self.m_popupMenu.AppendSeparator()
        self.m_popupMenu.Append(ID_COPY_VIEW, "Copy view to clipboard (image)")

    def Read(inout self, is_: wxInputStream) -> Bool:
        var units: List[tcUnit] = List[tcUnit]()
        var conns: List[tcConn] = List[tcConn]()
        if not is_.IsOk():
            return False
        var in_: wxDataInputStream = wxDataInputStream(is_)
        var code: UInt16 = in_.Read16()
        if code != 0xab:
            self.m_error = "invalid start code, 0xab required"
            return False
        var ver: UInt8 = in_.Read8()
        if ver < 1:
            self.m_error = "invalid data format version"
            return False
        var nunits: Int = in_.Read32()
        for i in range(nunits):
            var type: String = in_.ReadString()
            var ti: tcstypeinfo? = self.FindType(type)
            if ti is None:
                for k in range(len(units)):
                    del units[k]
                self.m_error = "unit " + str(i) + " could not find referenced type: " + type
                return False
            var u: tcUnit = tcUnit()
            u.type = ti
            u.x = in_.Read32() - 10000
            u.y = in_.Read32() - 10000
            var nvals: Int = in_.Read32()
            for j in range(nvals):
                var p: SPair = SPair()
                p.key = in_.ReadString()
                p.value = in_.ReadString()
                u.values.append(p)
            u.description = in_.ReadString()
            self.SizeNewUnit(u)
            units.append(u)
        var nconn: Int = in_.Read32()
        for i in range(nconn):
            var ustart: Int = in_.Read32()
            var uend: Int = in_.Read32()
            var startidx: Int = in_.Read32()
            var endidx: Int = in_.Read32()
            var tol: Float64 = in_.ReadDouble()
            var index: Int = in_.Read32() - 1
            var nway: Int = in_.Read32()
            var way: List[wxPoint] = List[wxPoint]()
            for j in range(nway):
                var p: wxPoint = wxPoint()
                p.x = in_.Read32() - 10000
                p.y = in_.Read32() - 10000
                way.append(p)
            var p1: tcConnPt? = None
            var p2: tcConnPt? = None
            if (ustart < len(units) and uend < len(units) and 
                (p1 := self.FindConnPt(units[ustart], startidx)) is not None and 
                (p2 := self.FindConnPt(units[uend], endidx)) is not None):
                var c: tcConn = tcConn()
                c.start = units[ustart]
                c.end = units[uend]
                c.start_pt = p1
                c.end_pt = p2
                c.ftol = tol
                c.index = index
                c.waypoints = way
                conns.append(c)
            else:
                for k in range(len(units)):
                    del units[k]
                for k in range(len(conns)):
                    del conns[k]
                self.m_error = "failed to instantiate connection [" + str(ustart) + ":" + str(startidx) + "] to [" + str(uend) + ":" + str(endidx) + "], check type definitions or versions"
                return False
        if in_.Read16() != 0xab:
            for k in range(len(units)):
                del units[k]
            self.m_error = "did not encounter end-of-data marker 0xab"
            return False
        self.Clear()
        self.m_units = units
        self.m_conns = conns
        self.m_currentUnit = None
        self.m_currentConn = None
        self.m_currentConnPt = None
        self.m_currentUnitIndex = -1
        self.Refresh()
        self.UpdateStatus()
        self.m_modified = False
        return True

    def FindConnPt(self, u: tcUnit, varindex: Int) -> tcConnPt?:
        for i in range(len(u.rdr.inputs)):
            if u.rdr.inputs[i].idx == varindex:
                return u.rdr.inputs[i]
        for i in range(len(u.rdr.outputs)):
            if u.rdr.outputs[i].idx == varindex:
                return u.rdr.outputs[i]
        return None

    def FindType(self, name: String) -> tcstypeinfo?:
        for i in range(len(self.m_types)):
            if self.m_types[i].name == name:
                return self.m_types[i].type
        return None

    def Write(self, os: wxOutputStream) -> Bool:
        if not os.IsOk():
            return False
        var out: wxDataOutputStream = wxDataOutputStream(os)
        out.Write16(0xab)
        out.Write8(1)
        out.Write32(len(self.m_units))
        for i in range(len(self.m_units)):
            out.WriteString(self.m_units[i].type.name)
            out.Write32(self.m_units[i].x + 10000)
            out.Write32(self.m_units[i].y + 10000)
            out.Write32(len(self.m_units[i].values))
            for j in range(len(self.m_units[i].values)):
                out.WriteString(self.m_units[i].values[j].key)
                out.WriteString(self.m_units[i].values[j].value)
            out.WriteString(self.m_units[i].description)
        out.Write32(len(self.m_conns))
        for i in range(len(self.m_conns)):
            out.Write32(self.UnitIndex(self.m_conns[i].start))
            out.Write32(self.UnitIndex(self.m_conns[i].end))
            out.Write32(self.m_conns[i].start_pt.idx)
            out.Write32(self.m_conns[i].end_pt.idx)
            out.WriteDouble(self.m_conns[i].ftol)
            out.Write32(self.m_conns[i].index + 1)
            out.Write32(len(self.m_conns[i].waypoints))
            for j in range(len(self.m_conns[i].waypoints)):
                out.Write32(self.m_conns[i].waypoints[j].x + 10000)
                out.Write32(self.m_conns[i].waypoints[j].y + 10000)
        out.Write16(0xab)
        return True

    def UnitIndex(self, u: tcUnit) -> Int:
        for i in range(len(self.m_units)):
            if self.m_units[i] == u:
                return i
        return -1

    def SetModified(inout self, b: Bool):
        self.m_modified = b

    def IsModified(self) -> Bool:
        return self.m_modified

    def OnSize(inout self, evt: wxSizeEvent):
        self.m_statusText.SetSize(0, 0, self.GetClientSize().GetWidth(), 23)

    def extend(x: Int, y: Int, inout minx: Int, inout maxx: Int, inout miny: Int, inout maxy: Int):
        if x < minx:
            minx = x
        if x > maxx:
            maxx = x
        if y < miny:
            miny = y
        if y > maxy:
            maxy = y

    def GetViewExtent(self, inout minx: Int, inout maxx: Int, inout miny: Int, inout maxy: Int):
        minx = 1000000000
        maxx = -1000000000
        miny = 1000000000
        maxy = -1000000000
        for i in range(len(self.m_units)):
            self.extend(self.m_units[i].x, self.m_units[i].y, minx, maxx, miny, maxy)
            self.extend(self.m_units[i].x + self.m_units[i].rdr.width, self.m_units[i].y + self.m_units[i].rdr.height, minx, maxx, miny, maxy)
        for i in range(len(self.m_conns)):
            for j in range(len(self.m_conns[i].waypoints)):
                self.extend(self.m_conns[i].waypoints[j].x, self.m_conns[i].waypoints[j].y, minx, maxx, miny, maxy)

    def GetBitmap(self) -> wxBitmap:
        var minx: Int = 0
        var maxx: Int = 0
        var miny: Int = 0
        var maxy: Int = 0
        self.GetViewExtent(minx, maxx, miny, maxy)
        var width: Int = maxx - minx
        var height: Int = maxy - miny
        if width <= 0 or height <= 0:
            return wxNullBitmap
        var ox: Int = self.m_offsetX
        var oy: Int = self.m_offsetY
        self.m_offsetX = -minx
        self.m_offsetY = -miny
        var bmp: wxBitmap = wxBitmap(width + 20, height + 20)
        var dc: wxMemoryDC = wxMemoryDC(bmp)
        dc.SetDeviceOrigin(10, 10)
        var sz: wxSize = wxSize(width, height)
        self.Draw(dc, sz, False, False)
        self.m_offsetX = ox
        self.m_offsetY = oy
        return bmp

    def Draw(self, dc: wxDC, client: wxSize, with_status: Bool = True, with_back_grid: Bool = True):
        var windowRect: wxRect = wxRect(wxPoint(0, 0), client)
        dc.SetBackground(*wxWHITE_BRUSH)
        dc.Clear()
        dc.SetFont(*wxNORMAL_FONT)
        if with_back_grid:
            dc.SetPen(wxPen(*wxLIGHT_GREY, 1))
            if self.m_snapSpacing > 0:
                for i in range(0, windowRect.width, self.m_snapSpacing):
                    for j in range(0, windowRect.height, self.m_snapSpacing):
                        dc.DrawPoint(i, j)
        for i in range(len(self.m_units)):
            dc.SetPen(wxPen(*wxBLACK, 1))
            dc.SetBrush(wxBrush(*wxWHITE))
            dc.SetTextForeground(*wxBLACK)
            var r: wxRect = wxRect(self.m_units[i].x + self.m_offsetX, self.m_units[i].y + self.m_offsetY, self.m_units[i].rdr.width, self.m_units[i].rdr.height)
            dc.SetClippingRegion(r)
            dc.DrawRectangle(r)
            dc.SetTextForeground(*wxBLACK)
            dc.DrawText("Unit " + str(i), r.x + 2, r.y + 2)
            dc.SetTextForeground(*wxLIGHT_GREY)
            dc.DrawText("'" + String(self.m_units[i].type.name) + "'", r.x + 2, dc.GetCharHeight() + r.y + 2)
            dc.SetTextForeground("magenta")
            dc.DrawText(self.m_units[i].description, r.x + 2, dc.GetCharHeight() * 2 + r.y + 4)
            if self.m_units[i].type.visual is not None and self.m_units[i].type.visual.pixmap is not None:
                var xpm: wxBitmap = wxBitmap(self.m_units[i].type.visual.pixmap)
                if xpm.IsOk():
                    dc.DrawBitmap(xpm, r.x + r.width - xpm.GetWidth() - 2, r.y + 2, True)
            dc.SetBrush(wxBrush(*wxBLACK))
            dc.SetPen(wxPen(*wxBLACK, 1))
            for j in range(len(self.m_units[i].rdr.inputs)):
                var cp: tcConnPt = self.m_units[i].rdr.inputs[j]
                if self.IsAssignedInputValue(cp):
                    dc.SetTextForeground(wxColour(0, 100, 0))
                else:
                    dc.SetTextForeground(wxColour(220, 0, 0))
                var t: String = cp.ti.name
                var dval: Float64 = 0.0
                if cp.ti.data_type == TCS_NUMBER and self.GetNumericValue(self.m_units[i], cp.ti.name, dval):
                    t += " (" + str(dval) + ")"
                dc.DrawText(t, r.x + 5, r.y + cp.pt.y - dc.GetCharHeight() / 2)
                dc.DrawRectangle(r.x + 1, r.y + cp.pt.y, 3, 3)
            dc.SetTextForeground(wxColour(0, 0, 100))
            for j in range(len(self.m_units[i].rdr.outputs)):
                var cp: tcConnPt = self.m_units[i].rdr.outputs[j]
                dc.DrawText(cp.ti.name, r.x + r.width - dc.GetTextExtent(cp.ti.name).GetWidth() - 5, r.y + cp.pt.y - dc.GetCharHeight() / 2)
                dc.DrawRectangle(r.x + r.width - 4, r.y + cp.pt.y, 3, 3)
            dc.DestroyClippingRegion()
        dc.SetBrush(wxBrush(*wxBLACK))
        for i in range(len(self.m_conns)):
            if strcmp(self.m_conns[i].start_pt.ti.units, self.m_conns[i].end_pt.ti.units) != 0:
                dc.SetPen(wxPen("orange", 2))
            else:
                dc.SetPen(wxPen(*wxBLACK, 2))
            var curpt: wxPoint = wxPoint(self.m_conns[i].start.x + self.m_conns[i].start_pt.pt.x + self.m_offsetX, self.m_conns[i].start.y + self.m_conns[i].start_pt.pt.y + self.m_offsetY)
            for j in range(len(self.m_conns[i].waypoints)):
                var waypt: wxPoint = wxPoint(self.m_conns[i].waypoints[j].x + self.m_offsetX, self.m_conns[i].waypoints[j].y + self.m_offsetY)
                dc.DrawLine(curpt, waypt)
                curpt = waypt
            var endpt: wxPoint = wxPoint(self.m_conns[i].end.x + self.m_conns[i].end_pt.pt.x + self.m_offsetX, self.m_conns[i].end.y + self.m_conns[i].end_pt.pt.y + self.m_offsetY)
            endpt.x -= 9
            dc.DrawLine(curpt, endpt)
            dc.SetPen(wxPen(*wxBLACK, 2))
            var tri: List[wxPoint] = List[wxPoint]()
            tri.append(wxPoint(endpt.x + 9, endpt.y))
            tri.append(wxPoint(endpt.x, endpt.y - 4))
            tri.append(wxPoint(endpt.x, endpt.y + 4))
            dc.DrawPolygon(3, tri)
        if with_status:
            dc.SetPen(wxPen(*wxWHITE, 1))
            dc.SetBrush(wxBrush(*wxWHITE))
            dc.DrawRectangle(0, 0, windowRect.width, self.m_statusHeight)
            dc.SetTextForeground(*wxBLACK)
            dc.DrawText(self.GetStatusText(), 2, 2)

    def OnPaint(self, evt: wxPaintEvent):
        var dc: wxAutoBufferedPaintDC = wxAutoBufferedPaintDC(self)
        var sz: wxSize = self.GetClientSize()
        self.Draw(dc, sz, True, True)

    def CanFinishConnection(self) -> Bool:
        var already_connected: Bool = False
        for i in range(len(self.m_conns)):
            if self.m_conns[i].end_pt == self.m_currentConnPt:
                already_connected = True
        if (self.m_currentConnPt is not None and self.m_currentConnPt != self.m_currentConn.start_pt and
            self.m_currentUnit is not None and self.m_currentConnPt is not None and
            self.m_currentConnPt.isinput and not already_connected):
            return True
        return False

    def OnLeftDown(inout self, evt: wxMouseEvent):
        self.SetFocus()
        if self.m_currentConn is not None:
            if self.CanFinishConnection():
                self.m_currentConn.end = self.m_currentUnit
                self.m_currentConn.end_pt = self.m_currentConnPt
                self.m_conns.append(self.m_currentConn)
                self.m_currentConn = None
                self.Modify()
                self.Refresh()
                self.UpdateStatus()
                #ifdef TC_USE_OVERLAY
                #	var dc: wxClientDC = wxClientDC(self)
                #	var overlaydc: wxDCOverlay = wxDCOverlay(self.m_overlay, dc)
                #	overlaydc.Clear()
                #	self.m_overlay.Reset()
                #endif
            else:
                var x: Int = evt.GetX() - self.m_offsetX
                var y: Int = evt.GetY() - self.m_offsetY
                self.Snap(x, y)
                self.m_currentConn.waypoints.append(wxPoint(x, y))
                self.Modify()
                self.m_lastLineX = -1000
                self.m_lastLineY = -1000
                self.m_lineModeErase = False
        elif self.m_currentUnit is not None and self.m_currentConnPt is None:
            self.m_origX = evt.GetX()
            self.m_origY = evt.GetY()
            self.ClientToScreen(self.m_origX, self.m_origY)
            self.m_diffX = 0
            self.m_diffY = 0
            self.m_moveModeErase = False
            self.m_movingUnit = self.m_currentUnit
        elif (self.m_currentConnPt is not None and self.m_currentConn is None and
              self.m_currentUnit is not None and not self.m_currentConnPt.isinput):
            self.m_currentConn = tcConn()
            self.m_currentConn.start = self.m_currentUnit
            self.m_currentConn.start_pt = self.m_currentConnPt
            self.m_lastLineX = 0
            self.m_lastLineY = 0
            self.m_lineModeErase = False
        elif (self.m_movingWaypointConn is None and
              self.m_currentWaypointConn is not None and
              self.m_currentWaypointIndex >= 0):
            self.m_movingWaypointConn = self.m_currentWaypointConn
            self.m_movingWaypointIndex = self.m_currentWaypointIndex
            self.m_moveWaypointErase = False
        else:
            self.m_movingUnit = None

    def OnLeftDouble(self, evt: wxMouseEvent):
        if self.m_currentUnit is not None:
            self.EditUnit(self.m_currentUnit)

    def OnLeftUp(inout self, evt: wxMouseEvent):
        if self.m_movingUnit is not None:
            self.m_movingUnit.x += self.m_diffX
            self.m_movingUnit.y += self.m_diffY
            self.Snap(self.m_movingUnit.x, self.m_movingUnit.y)
            self.m_movingUnit = None
            #ifdef TC_USE_OVERLAY
            #	var dc: wxClientDC = wxClientDC(self)
            #	var overlaydc: wxDCOverlay = wxDCOverlay(self.m_overlay, dc)
            #	overlaydc.Clear()
            #	self.m_overlay.Reset()
            #endif
            self.Modify()
            self.Refresh()
            self.UpdateStatus()
        elif self.m_movingWaypointConn is not None:
            var x: Int = evt.GetX() - self.m_offsetX
            var y: Int = evt.GetY() - self.m_offsetY
            self.Snap(x, y)
            self.m_movingWaypointConn.waypoints[self.m_movingWaypointIndex] = wxPoint(x, y)
            self.m_movingWaypointConn = None
            self.m_movingWaypointIndex = -1
            self.m_moveWaypointErase = False
            #ifdef TC_USE_OVERLAY
            #	var dc: wxClientDC = wxClientDC(self)
            #	var overlaydc: wxDCOverlay = wxDCOverlay(self.m_overlay, dc)
            #	overlaydc.Clear()
            #	self.m_overlay.Reset()
            #endif
            self.Modify()
            self.Refresh()
            self.UpdateStatus()

    def OnRightDown(inout self, evt: wxMouseEvent):
        self.SetFocus()
        self.m_popupX = evt.GetX()
        self.m_popupY = evt.GetY()
        self.m_popupMenu.Enable(ID_DELETE_UNIT, self.m_currentUnit is not None)
        self.m_popupMenu.Enable(ID_EDIT_CONNECTION, self.m_currentWaypointConn is not None or (self.m_currentConnPt is not None and self.m_currentConnPt.isinput))
        self.m_popupMenu.Enable(ID_DELETE_ALL_CONNECTIONS, self.m_currentConnPt is not None and self.m_currentConn is None)
        self.m_popupMenu.Enable(ID_DELETE_CONNECTION, self.m_currentWaypointConn is not None)
        self.m_popupMenu.Enable(ID_ADD_WAYPOINT, self.m_currentWaypointConn is not None and self.m_currentWaypointIndex >= 0)
        self.m_popupMenu.Enable(ID_DELETE_WAYPOINT, self.m_currentWaypointConn is not None and self.m_currentWaypointIndex >= 0)
        self.m_popupMenu.Enable(ID_EDIT_UNIT, self.m_currentUnit is not None)
        self.m_popupMenu.Enable(ID_MOVE_UP, self.m_currentUnit is not None)
        self.m_popupMenu.Enable(ID_MOVE_DOWN, self.m_currentUnit is not None)
        self.PopupMenu(self.m_popupMenu, self.m_popupX, self.m_popupY)

    def DrawWaypointMoveOutline(self):
        var dc: wxClientDC = wxClientDC(self)
        #ifdef TC_USE_OVERLAY
        #	var overlaydc: wxDCOverlay = wxDCOverlay(self.m_overlay, dc)
        #	overlaydc.Clear()
        #else
        #	dc.SetLogicalFunction(wxINVERT)
        #endif
        dc.SetPen(wxPen(*wxBLACK, 1, wxPENSTYLE_DOT))
        var cr: wxSize = self.GetClientSize()
        var x: Int = self.m_moveWaypointLastXY.x + self.m_offsetX
        var y: Int = self.m_moveWaypointLastXY.y + self.m_offsetY
        dc.DrawLine(0, y, cr.x, y)
        dc.DrawLine(x, 0, x, cr.y)
        dc.DrawCircle(self.m_moveWaypointLastXY.x + self.m_offsetX, self.m_moveWaypointLastXY.y + self.m_offsetY, 5)

    def DrawMoveOutline(self):
        if self.m_movingUnit is not None:
            var dc: wxClientDC = wxClientDC(self)
            #ifdef TC_USE_OVERLAY
            #	var overlaydc: wxDCOverlay = wxDCOverlay(self.m_overlay, dc)
            #	overlaydc.Clear()
            #	dc.SetPen(wxColour(100, 100, 100))
            #	dc.SetBrush(wxColour(150, 150, 150, 150))
            #else
            #	dc.SetLogicalFunction(wxINVERT)
            #	dc.SetPen(wxPen(*wxBLACK, 3))
            #	dc.SetBrush(*wxTRANSPARENT_BRUSH)
            #endif
            var x: Int = self.m_movingUnit.x + self.m_offsetX
            var y: Int = self.m_movingUnit.y + self.m_offsetY
            x += self.m_diffX
            y += self.m_diffY
            self.Snap(x, y)
            dc.DrawRectangle(x, y, self.m_movingUnit.rdr.width, self.m_movingUnit.rdr.height)

    def DrawSegmentOutline(self, pt: wxPoint):
        var dc: wxClientDC = wxClientDC(self)
        #ifdef TC_USE_OVERLAY
        #	var overlaydc: wxDCOverlay = wxDCOverlay(self.m_overlay, dc)
        #	overlaydc.Clear()
        #else
        #	dc.SetLogicalFunction(wxINVERT)
        #endif
        dc.SetPen(wxPen(*wxBLACK, 2))
        dc.DrawLine(pt, wxPoint(self.m_lastLineX, self.m_lastLineY))
        #ifdef TC_USE_OVERLAY
        #	if self.m_currentConn is None:
        #		return
        #	var p1: wxPoint = wxPoint(self.m_offsetX + self.m_currentConn.start.x + self.m_currentConn.start_pt.pt.x, self.m_offsetY + self.m_currentConn.start.y + self.m_currentConn.start_pt.pt.y)
        #	for j in range(len(self.m_currentConn.waypoints)):
        #		var p0: wxPoint = p1
        #		p1 = self.m_currentConn.waypoints[j]
        #		p1.x += self.m_offsetX
        #		p1.y += self.m_offsetY
        #		dc.DrawLine(p0, p1)
        #endif

    def OnMouseMove(inout self, evt: wxMouseEvent):
        if self.m_movingUnit is not None:
            #ifndef TC_USE_OVERLAY
            #	if self.m_moveModeErase:
            #		self.DrawMoveOutline()
            #endif
            var xroot: Int = evt.GetX()
            var yroot: Int = evt.GetY()
            self.ClientToScreen(xroot, yroot)
            self.m_diffX = xroot - self.m_origX
            self.m_diffY = yroot - self.m_origY
            self.DrawMoveOutline()
            self.m_moveModeErase = True
            self.UpdateStatus()
            return
        if self.m_movingWaypointConn is not None:
            #ifndef TC_USE_OVERLAY
            #	if self.m_moveWaypointErase:
            #		self.DrawWaypointMoveOutline()
            #endif
            self.m_moveWaypointLastXY.x = evt.GetX() - self.m_offsetX
            self.m_moveWaypointLastXY.y = evt.GetY() - self.m_offsetY
            self.Snap(self.m_moveWaypointLastXY.x, self.m_moveWaypointLastXY.y)
            self.DrawWaypointMoveOutline()
            self.m_moveWaypointErase = True
        if self.m_currentConn is not None:
            var pt: wxPoint = wxPoint(self.m_currentConn.start.x + self.m_currentConn.start_pt.pt.x, self.m_currentConn.start.y + self.m_currentConn.start_pt.pt.y)
            for j in range(len(self.m_currentConn.waypoints)):
                pt = self.m_currentConn.waypoints[j]
            pt.x += self.m_offsetX
            pt.y += self.m_offsetY
            #ifndef TC_USE_OVERLAY
            #	if self.m_lineModeErase:
            #		self.DrawSegmentOutline(pt)
            #endif
            self.m_lastLineX = evt.GetX()
            self.m_lastLineY = evt.GetY()
            self.Snap(self.m_lastLineX, self.m_lastLineY)
            self.DrawSegmentOutline(pt)
            self.m_lineModeErase = True
        var mx: Int = evt.GetX()
        var my: Int = evt.GetY()
        self.m_currentUnit = self.LocateUnit(mx, my)
        self.m_currentUnitIndex = -1
        if self.m_currentUnit is not None:
            for i in range(len(self.m_units)):
                if self.m_currentUnit == self.m_units[i]:
                    self.m_currentUnitIndex = i
            self.m_currentConnPt = self.LocateConnection(mx, my)
        else:
            self.m_currentConnPt = None
            self.FindWayPoint(mx, my, self.m_currentWaypointConn, self.m_currentWaypointIndex)
        if (self.m_currentConnPt is not None and self.m_currentConn is None) or (self.m_currentConnPt is not None and self.m_currentConn is not None and self.CanFinishConnection()):
            self.SetCursor(wxCursor(wxCURSOR_BULLSEYE))
        elif self.m_currentConn is not None:
            self.SetCursor(wxCursor(wxCURSOR_CROSS))
        elif self.m_currentWaypointConn is not None:
            self.SetCursor(wxCursor(wxCURSOR_PENCIL))
        else:
            self.SetCursor(wxCursor(wxCURSOR_ARROW))
        self.m_mouseLastX = mx
        self.m_mouseLastY = my
        self.UpdateStatus()

    def UpdateStatus(self):
        self.m_statusText.ChangeValue(self.GetStatusText())

    def OnChar(self, evt: wxKeyEvent):
        if evt.GetKeyCode() == WXK_LEFT:
            self.m_offsetX += self.m_snapSpacing * 5
            self.m_lastLineX += self.m_snapSpacing * 5
            self.Refresh()
        elif evt.GetKeyCode() == WXK_RIGHT:
            self.m_offsetX -= self.m_snapSpacing * 5
            self.m_lastLineX -= self.m_snapSpacing * 5
            self.Refresh()
        elif evt.GetKeyCode() == WXK_UP:
            self.m_offsetY += self.m_snapSpacing * 5
            self.m_lastLineY += self.m_snapSpacing * 5
            self.Refresh()
        elif evt.GetKeyCode() == WXK_DOWN:
            self.m_offsetY -= self.m_snapSpacing * 5
            self.m_lastLineY -= self.m_snapSpacing * 5
            self.Refresh()
        elif evt.GetKeyCode() == WXK_ESCAPE:
            self.EscapeAction()
        self.UpdateStatus()

    def EscapeAction(inout self):
        if self.m_movingUnit is not None:
            self.m_movingUnit = None
            self.Refresh()
        if self.m_currentConn is not None:
            del self.m_currentConn
            self.m_currentConn = None
            self.Refresh()
        if self.m_movingWaypointConn is not None:
            self.m_movingWaypointConn = None
            self.m_movingWaypointIndex = -1

    def SizeNewUnit(self, u: tcUnit):
        var dc: wxClientDC = wxClientDC(self)
        dc.SetFont(*wxNORMAL_FONT)
        var ii: Int = 0
        var oo: Int = 0
        var wi: Int = 0
        var wo: Int = 0
        var connh: Int = self.m_snapSpacing * 2
        var ystart: Int = connh * 4
        if u.type.visual is None or u.type.visual.conn_left is None:
            var idx: Int = 0
            while u.type.variables[idx].var_type != TCS_INVALID:
                var size: Int = dc.GetTextExtent(u.type.variables[idx].name).GetWidth()
                if u.type.variables[idx].var_type == TCS_INPUT:
                    u.rdr.inputs.append(tcConnPt(u.type.variables[idx], u, idx, wxPoint(0, ystart + ii * connh), True))
                    ii += 1
                    if size > wi:
                        wi = size
                idx += 1
        elif u.type.visual is not None and u.type.visual.conn_left is not None:
            var in_: List[String] = wxStringTokenize(u.type.visual.conn_left, ",")
            for i in range(len(in_)):
                var variable: String = in_[i]
                var idx: Int = 0
                while u.type.variables[idx].var_type != TCS_INVALID:
                    if u.type.variables[idx].name == in_[i] and (u.type.variables[idx].var_type == TCS_INPUT or u.type.variables[idx].var_type == TCS_PARAM):
                        var size: Int = dc.GetTextExtent(in_[i]).GetWidth()
                        u.rdr.inputs.append(tcConnPt(u.type.variables[idx], u, idx, wxPoint(0, ystart + ii * connh), True))
                        ii += 1
                        if size > wi:
                            wi = size
                        break
                    idx += 1
        if u.type.visual is None or u.type.visual.conn_right is None:
            var idx: Int = 0
            while u.type.variables[idx].var_type != TCS_INVALID:
                var size: Int = dc.GetTextExtent(u.type.variables[idx].name).GetWidth()
                if u.type.variables[idx].var_type == TCS_OUTPUT:
                    u.rdr.outputs.append(tcConnPt(u.type.variables[idx], u, idx, wxPoint(0, ystart + oo * connh), False))
                    oo += 1
                    if size > wo:
                        wo = size
                idx += 1
        elif u.type.visual is not None and u.type.visual.conn_right is not None:
            var out: List[String] = wxStringTokenize(u.type.visual.conn_right, ",")
            for i in range(len(out)):
                var variable: String = out[i]
                var idx: Int = 0
                while u.type.variables[idx].var_type != TCS_INVALID:
                    if u.type.variables[idx].name == out[i] and (u.type.variables[idx].var_type == TCS_OUTPUT or u.type.variables[idx].var_type == TCS_DEBUG):
                        var size: Int = dc.GetTextExtent(out[i]).GetWidth()
                        u.rdr.outputs.append(tcConnPt(u.type.variables[idx], u, idx, wxPoint(0, ystart + oo * connh), False))
                        oo += 1
                        if size > wo:
                            wo = size
                        break
                    idx += 1
        u.rdr.width = self.Snap(wi + wo + 100)
        u.rdr.height = self.Snap((ii if ii > oo else oo) * connh + ystart)
        if u.type.visual is not None and u.type.visual.min_width > 0:
            var units: Int = u.type.visual.min_width * self.m_snapSpacing
            if u.rdr.width < units:
                u.rdr.width = self.Snap(units)
        for i in range(len(u.rdr.outputs)):
            u.rdr.outputs[i].pt.x = u.rdr.width

    def OnPopup(inout self, evt: wxCommandEvent):
        var u: tcUnit? = self.LocateUnit(self.m_popupX, self.m_popupY)
        if evt.GetId() >= ID_CREATE and evt.GetId() < ID_CREATE_LAST:
            var t: tcType = self.m_types[evt.GetId() - ID_CREATE]
            var x: Int = self.m_popupX
            var y: Int = self.m_popupY
            self.Snap(x, y)
            u = tcUnit()
            u.type = t.type
            u.x = x - self.m_offsetX
            u.y = y - self.m_offsetY
            u.description = "no description"
            self.SizeNewUnit(u)
            self.m_units.append(u)
            self.Modify()
            self.Refresh()
            self.UpdateStatus()
        elif evt.GetId() == ID_DELETE_UNIT and u is not None:
            var it: Int = -1
            for i in range(len(self.m_units)):
                if self.m_units[i] == u:
                    it = i
                    break
            if it != -1:
                var i: Int = 0
                while i < len(self.m_conns):
                    if self.m_conns[i].start == u or self.m_conns[i].end == u:
                        if self.m_currentConn == self.m_conns[i]:
                            self.m_currentConn = None
                        del self.m_conns[i]
                        self.m_conns.erase(i)
                    else:
                        i += 1
                self.m_currentUnit = None
                self.m_currentUnitIndex = -1
                self.m_currentConnPt = None
                del u
                self.m_units.erase(it)
                self.Modify()
                self.Refresh()
                self.UpdateStatus()
        elif evt.GetId() == ID_ADD_WAYPOINT and self.m_currentWaypointConn is not None and self.m_currentWaypointIndex >= 0:
            var x: Int = self.m_mouseLastX - self.m_offsetX
            var y: Int = self.m_mouseLastY - self.m_offsetY
            self.Snap(x, y)
            x -= self.m_snapSpacing * 2
            y -= self.m_snapSpacing * 2
            self.m_currentWaypointConn.waypoints.insert(self.m_currentWaypointIndex, wxPoint(x, y))
            self.Modify()
            self.Refresh()
            self.UpdateStatus()
        elif evt.GetId() == ID_DELETE_WAYPOINT and self.m_currentWaypointConn is not None and self.m_currentWaypointIndex >= 0:
            self.m_currentWaypointConn.waypoints.erase(self.m_currentWaypointIndex)
            self.m_currentWaypointConn = None
            self.m_currentWaypointIndex = -1
            self.Modify()
            self.Refresh()
            self.UpdateStatus()
        elif evt.GetId() == ID_DELETE_CONNECTION and self.m_currentWaypointConn is not None:
            var it: Int = -1
            for i in range(len(self.m_conns)):
                if self.m_conns[i] == self.m_currentWaypointConn:
                    it = i
                    break
            if it != -1:
                del self.m_conns[it]
                self.m_conns.erase(it)
                self.m_currentWaypointConn = None
                self.m_currentWaypointIndex = -1
                self.m_currentConn = None
                self.m_currentConnPt = None
                self.Modify()
                self.Refresh()
                self.UpdateStatus()
        elif evt.GetId() == ID_EDIT_CONNECTION and (self.m_currentWaypointConn is not None or (self.m_currentConnPt is not None and self.m_currentConnPt.isinput)):
            var cp: tcConn? = None
            if self.m_currentWaypointConn is not None:
                cp = self.m_currentWaypointConn
            else:
                cp = self.FindConnFromPt(self.m_currentConnPt)
            if cp is None:
                wxMessageBox("Could not find connection to edit")
                return
            var title: String = "Connection " + str(self.UnitIndex(cp.start)) + "." + cp.start_pt.ti.name + " --> " + str(self.UnitIndex(cp.end)) + "." + cp.end_pt.ti.name
            var dlg: wxDialog = wxDialog(self, wxID_ANY, title, wxDefaultPosition, wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER)
            var tol: wxTextCtrl = wxTextCtrl(dlg, wxID_ANY, str(cp.ftol))
            var index: wxTextCtrl = wxTextCtrl(dlg, wxID_ANY, str(cp.index))
            var grid: wxGridSizer = wxGridSizer(2, 3, 3)
            grid.Add(wxStaticText(dlg, wxID_ANY, "Tolerance (+:%, -:absolute)"))
            grid.Add(tol)
            grid.Add(wxStaticText(dlg, wxID_ANY, "Array index (for array->number connections)"))
            grid.Add(index)
            var szmain: wxBoxSizer = wxBoxSizer(wxVERTICAL)
            szmain.Add(grid, 1, wxALL | wxEXPAND, 5)
            szmain.Add(dlg.CreateButtonSizer(wxOK | wxCANCEL), 0, wxALL | wxEXPAND, 10)
            dlg.SetSizerAndFit(szmain)
            if dlg.ShowModal() == wxID_OK:
                cp.ftol = atof(tol.GetValue().c_str())
                cp.index = atoi(index.GetValue().c_str())
        elif evt.GetId() == ID_DELETE_ALL_CONNECTIONS and self.m_currentConnPt is not None and self.m_currentConn is None:
            var ndel: Int = 0
            var idx: Int = 0
            while idx < len(self.m_conns):
                if self.m_conns[idx].start_pt == self.m_currentConnPt or self.m_conns[idx].end_pt == self.m_currentConnPt:
                    ndel += 1
                    del self.m_conns[idx]
                    self.m_conns.erase(idx)
                else:
                    idx += 1
            if ndel > 0:
                self.m_currentConn = None
                self.m_currentConnPt = None
                self.Modify()
                self.Refresh()
                self.UpdateStatus()
        elif (evt.GetId() == ID_MOVE_UP or evt.GetId() == ID_MOVE_DOWN) and u is not None:
            var i: Int = 0
            for i in range(len(self.m_units)):
                if u == self.m_units[i]:
                    break
            if evt.GetId() == ID_MOVE_UP and i > 0 and i < len(self.m_units):
                var temp: tcUnit = self.m_units[i - 1]
                self.m_units[i - 1] = u
                self.m_units[i] = temp
                self.Modify()
                self.Refresh()
                self.UpdateStatus()
            elif evt.GetId() == ID_MOVE_DOWN and i < len(self.m_units) - 1:
                var temp: tcUnit = self.m_units[i + 1]
                self.m_units[i + 1] = u
                self.m_units[i] = temp
                self.Modify()
                self.Refresh()
                self.UpdateStatus()
        elif evt.GetId() == ID_COPY_VIEW:
            if wxTheClipboard.Open():
                wxTheClipboard.SetData(wxBitmapDataObject(self.GetBitmap()))
                wxTheClipboard.Close()
        elif evt.GetId() == ID_EDIT_UNIT and self.m_currentUnit is not None:
            self.EditUnit(self.m_currentUnit)

    def LocateUnit(self, x: Int, y: Int) -> tcUnit?:
        x -= self.m_offsetX
        y -= self.m_offsetY
        for i in range(len(self.m_units)):
            if x >= self.m_units[i].x and y >= self.m_units[i].y and x <= self.m_units[i].x + self.m_units[i].rdr.width and y <= self.m_units[i].y + self.m_units[i].rdr.height:
                return self.m_units[i]
        return None

    def LocateConnection(self, x: Int, y: Int) -> tcConnPt?:
        var u: tcUnit? = self.LocateUnit(x, y)
        if u is None:
            return None
        x -= self.m_offsetX
        y -= self.m_offsetY
        if x <= u.x + self.m_snapSpacing:
            for i in range(len(u.rdr.inputs)):
                if abs(u.y + u.rdr.inputs[i].pt.y - y) <= self.m_snapSpacing:
                    return u.rdr.inputs[i]
        elif x >= u.x + u.rdr.width - self.m_snapSpacing:
            for i in range(len(u.rdr.outputs)):
                if abs(u.y + u.rdr.outputs[i].pt.y - y) <= self.m_snapSpacing:
                    return u.rdr.outputs[i]
        return None

    def FindWayPoint(self, mx: Int, my: Int, inout conn: tcConn?, inout wpidx: Int) -> Bool:
        var x: Int = mx - self.m_offsetX
        var y: Int = my - self.m_offsetY
        for i in range(len(self.m_conns)):
            for j in range(len(self.m_conns[i].waypoints)):
                var wp: wxPoint = self.m_conns[i].waypoints[j]
                if self.Distance(x, y, wp.x, wp.y) < 5.0:
                    conn = self.m_conns[i]
                    wpidx = j
                    return True
        conn = None
        wpidx = -1
        return False

    def Distance(self, x1: Int, y1: Int, x2: Int, y2: Int) -> Float32:
        return sqrt(Float64((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)))

    def Snap(self, x: Int, y: Int):
        x = self.Snap(x)
        y = self.Snap(y)

    def Snap(self, v: Int) -> Int:
        var multiples: Int = v // self.m_snapSpacing
        var dist1: Float32 = abs(Float32(self.m_snapSpacing * multiples - v))
        var dist2: Float32 = abs(Float32(self.m_snapSpacing * (multiples + 1) - v))
        if dist1 < dist2:
            return self.m_snapSpacing * multiples
        else:
            return self.m_snapSpacing * (multiples + 1)

    def GetStatusText(self) -> String:
        var x: Int = self.m_mouseLastX - self.m_offsetX
        var y: Int = self.m_mouseLastY - self.m_offsetY
        self.Snap(x, y)
        var status: String = "{" + str(x) + " " + str(y) + " " + str(self.m_offsetX) + " " + str(self.m_offsetY) + "}"
        if self.m_currentUnit is not None:
            status += "  Unit " + str(self.m_currentUnitIndex) + " '" + self.m_currentUnit.type.name + "' "
        if self.m_currentConnPt is not None:
            var datatype: String = "string"
            if self.m_currentConnPt.ti.data_type == TCS_STRING:
                datatype = "<string>"
            elif self.m_currentConnPt.ti.data_type == TCS_NUMBER:
                datatype = "<number>"
            elif self.m_currentConnPt.ti.data_type == TCS_ARRAY:
                datatype = "<array>"
            elif self.m_currentConnPt.ti.data_type == TCS_MATRIX:
                datatype = "<matrix>"
            else:
                datatype = "<invalid>"
            status += "  [ " + str(self.m_currentConnPt.idx) + ": " + self.m_currentConnPt.ti.name + "  (" + self.m_currentConnPt.ti.units + ")  " + datatype + "  " + self.m_currentConnPt.ti.label + " ]"
        if self.m_currentConn is not None:
            if self.CanFinishConnection():
                status += "  finish connection here?"
            else:
                status += "    connecting"
        elif self.m_movingUnit is not None:
            status += "    moving unit"
        elif self.m_movingWaypointConn is not None:
            status += "    moving waypoint"
        else:
            status += "    ready"
        return status

    @staticmethod
    def CreateUnitDataGrid(parent: wxWindow, type: tcstypeinfo) -> wxGrid:
        var grid: wxGrid = wxGrid(parent, wxID_ANY)
        var vl: List[tcsvarinfo] = type.variables
        var idx: Int = 0
        while vl[idx].var_type != TCS_INVALID:
            idx += 1
        grid.CreateGrid(idx, 7)
        grid.SetColLabelValue(0, "Type")
        grid.SetColLabelValue(1, "Data")
        grid.SetColLabelValue(2, "Name")
        grid.SetColLabelValue(3, "Label")
        grid.SetColLabelValue(4, "Units")
        grid.SetColLabelValue(5, "Group")
        grid.SetColLabelValue(6, "Meta")
        idx = 0
        while vl[idx].var_type != TCS_INVALID:
            var rowc: wxColour = wxColour(225, 255, 255)
            var stype: String = "input"
            if vl[idx].var_type == TCS_OUTPUT:
                stype = "output"
                rowc = wxColour(255, 225, 255)
            elif vl[idx].var_type == TCS_DEBUG:
                stype = "debug"
                rowc = wxColour(225, 225, 255)
            elif vl[idx].var_type == TCS_PARAM:
                stype = "param"
                rowc = wxColour(255, 255, 225)
            var sdata: String = "number"
            if vl[idx].data_type == TCS_STRING:
                sdata = "string"
            elif vl[idx].data_type == TCS_ARRAY:
                sdata = "array"
            elif vl[idx].data_type == TCS_MATRIX:
                sdata = "matrix"
            grid.SetCellValue(idx, 0, stype)
            grid.SetCellValue(idx, 1, sdata)
            grid.SetCellValue(idx, 2, vl[idx].name)
            grid.SetCellValue(idx, 3, vl[idx].label)
            grid.SetCellValue(idx, 4, vl[idx].units)
            grid.SetCellValue(idx, 5, vl[idx].group)
            grid.SetCellValue(idx, 6, vl[idx].meta)
            for j in range(7):
                grid.SetCellBackgroundColour(idx, j, rowc)
            idx += 1
        grid.AutoSizeColumns(False)
        return grid

    def EditUnit(self, u: tcUnit):
        var dlg: wxDialog = wxDialog(self, wxID_ANY, "Edit Properties of unit " + str(self.UnitIndex(u)), wxDefaultPosition, wxDefaultSize, wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER)
        var str_: String = ""
        for i in range(len(u.values)):
            str_ += u.values[i].key + "=" + u.values[i].value + "\n"
        var type_text: wxStaticText = wxStaticText(dlg, wxID_ANY, "Unit " + str(self.UnitIndex(u)) + " Type " + u.type.name)
        var font: wxFont = *wxNORMAL_FONT
        font.SetWeight(wxFONTWEIGHT_BOLD)
        type_text.SetFont(font)
        var desc: wxTextCtrl = wxTextCtrl(dlg, wxID_ANY, u.description)
        var vals: wxTextCtrl = wxTextCtrl(dlg, wxID_ANY, str_, wxDefaultPosition, wxSize(600, 300), wxTE_MULTILINE | wxTE_DONTWRAP)
        var grid: wxGrid = self.CreateUnitDataGrid(dlg, u.type)
        grid.SetInitialSize(wxSize(250, 150))
        var fontSize: Int = 12
        #ifdef __WXMAC__
        #	fontSize = 14
        #endif
        vals.SetFont(wxFont(fontSize, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, False, "Consolas"))
        var szmain: wxBoxSizer = wxBoxSizer(wxVERTICAL)
        szmain.Add(type_text, 0, wxALL | wxEXPAND, 5)
        szmain.Add(desc, 0, wxALL | wxEXPAND, 5)
        szmain.Add(vals, 2, wxALL | wxEXPAND, 5)
        szmain.Add(grid, 1, wxALL | wxEXPAND, 5)
        szmain.Add(dlg.CreateButtonSizer(wxOK | wxCANCEL), 0, wxALL | wxEXPAND, 10)
        dlg.SetSizerAndFit(szmain)
        dlg.CenterOnScreen()
        vals.SetFocus()
        if dlg.ShowModal() == wxID_OK:
            u.description = desc.GetValue()
            u.values.clear()
            var lines: List[String] = wxStringTokenize(vals.GetValue(), "\n")
            for i in range(len(lines)):
                var eqpos: Int = lines[i].find("=")
                if eqpos > 0:
                    var p: SPair = SPair()
                    p.key = lines[i][:eqpos]
                    p.value = lines[i][eqpos + 1:]
                    u.values.append(p)
            self.Refresh()
            self.UpdateStatus()

    def IsAssignedInputValue(self, pt: tcConnPt) -> Bool:
        for i in range(len(self.m_conns)):
            if self.m_conns[i].end_pt == pt:
                return True
        for i in range(len(pt.unit.values)):
            if pt.unit.values[i].key == pt.ti.name:
                return True
        return False

    def GetNumericValue(self, u: tcUnit, name: String, inout val: Float64) -> Bool:
        for i in range(len(u.values)):
            if u.values[i].key == name:
                val = u.values[i].value.ToDouble()
                return True
        return False

    def GetNetlist(self) -> String:
        var buf: String = ""
        for i in range(len(self.m_units)):
            buf += "unit " + str(i) + " " + self.m_units[i].type.name + " '" + self.m_units[i].description + "'\n"
            for j in range(len(self.m_units[i].values)):
                buf += "\t" + self.m_units[i].values[j].key + "=" + self.m_units[i].values[j].value + "\n"
        for i in range(len(self.m_conns)):
            var u1: Int = self.UnitIndex(self.m_conns[i].start)
            var u2: Int = self.UnitIndex(self.m_conns[i].end)
            buf += str(u1) + ":" + str(self.m_conns[i].start_pt.idx) + " " + self.m_conns[i].start_pt.ti.name + " --> " + str(u2) + ":" + str(self.m_conns[i].end_pt.idx) + " " + self.m_conns[i].end_pt.ti.name + "\n"
        return buf

    def GetLKScript(self) -> String:
        var buf: String = "setup_system = define() {\n\tclear( );\n"
        for i in range(len(self.m_units)):
            buf += "\n\t u" + str(i) + " = add_unit( \"" + self.m_units[i].type.name + "\", \"" + self.m_units[i].description + "\" );\n"
            for j in range(len(self.m_units[i].values)):
                var key: String = self.m_units[i].values[j].key
                var val: String = self.m_units[i].values[j].value
                var data_type: Int = TCS_INVALID
                var vl: List[tcsvarinfo] = self.m_units[i].type.variables
                var idx: Int = 0
                while vl[idx].var_type != TCS_INVALID:
                    if vl[idx].name == key:
                        data_type = vl[idx].data_type
                        break
                    idx += 1
                if data_type == TCS_INVALID:
                    continue
                var tv: tcsvalue = tcsvalue()
                tv.type = TCS_INVALID
                if tcskernel.parse_unit_value(tv, data_type, val):
                    if data_type == TCS_NUMBER:
                        buf += "\tset_value( u" + str(i) + ", \"" + key + "\", " + str(tv.data.value) + " );\n"
                    elif data_type == TCS_STRING:
                        buf += "\tset_value( u" + str(i) + ", \"" + key + "\", \"" + str(tv.data.cstr) + "\" );\n"
                    elif data_type == TCS_ARRAY:
                        buf += "\tset_value( u" + str(i) + ", \"" + key + "\", [ "
                        for idx in range(tv.data.array.length):
                            buf += str(tv.data.array.values[idx])
                            if idx < tv.data.array.length - 1:
                                buf += ", "
                        buf += "] );\n"
                    elif data_type == TCS_MATRIX:
                        buf += "\tset_value( u" + str(i) + ", \"" + key + "\", [ "
                        for idx in range(tv.data.matrix.nrows):
                            buf += "["
                            for col in range(tv.data.matrix.ncols):
                                buf += str(TCS_MATRIX_INDEX(tv, idx, col))
                                if col < tv.data.matrix.ncols - 1:
                                    buf += ", "
                            buf += "]"
                            if idx < tv.data.matrix.nrows - 1:
                                buf += ", "
                        buf += "] );\n"
        buf += "\n"
        for i in range(len(self.m_conns)):
            var u1: Int = self.UnitIndex(self.m_conns[i].start)
            var u2: Int = self.UnitIndex(self.m_conns[i].end)
            buf += "\tconnect( u" + str(u1) + ", \"" + self.m_conns[i].start_pt.ti.name + "\", u" + str(u2) + ", \"" + self.m_conns[i].end_pt.ti.name + "\", " + str(self.m_conns[i].ftol) + ", " + str(self.m_conns[i].index) + " );\n"
        buf += "};\n"
        return buf

    def LoadSystemInKernel(self, kern: tcskernel) -> Bool:
        kern.clear_units()
        for i in range(len(self.m_units)):
            var u: Int = kern.add_unit(self.m_units[i].type.name, self.m_units[i].description.c_str())
            for j in range(len(self.m_units[i].values)):
                var key: String = self.m_units[i].values[j].key
                var val: String = self.m_units[i].values[j].value
                if not kern.parse_unit_value(u, key, val):
                    self.m_error = "failed to parse value on unit " + str(u) + ", " + key + "=" + val
                    return False
        for i in range(len(self.m_conns)):
            var u1: Int = self.UnitIndex(self.m_conns[i].start)
            var u2: Int = self.UnitIndex(self.m_conns[i].end)
            if not kern.connect(u1, self.m_conns[i].start_pt.idx, u2, self.m_conns[i].end_pt.idx, self.m_conns[i].ftol, self.m_conns[i].index):
                self.m_error = "failed to connect [" + str(u1) + ":" + str(self.m_conns[i].start_pt.idx) + "] --> [" + str(u2) + ":" + str(self.m_conns[i].end_pt.idx) + "]  (tol " + str(self.m_conns[i].ftol) + ", idx " + str(self.m_conns[i].index) + ")"
                return False
        return True

    def FindConnFromPt(self, pt: tcConnPt) -> tcConn?:
        var u: tcUnit = pt.unit
        for i in range(len(self.m_conns)):
            if self.m_conns[i].end == u and self.m_conns[i].end_pt == pt:
                return self.m_conns[i]
        return None

@value
struct tcType:
    var name: String
    var type: tcstypeinfo
    var meta: String

    def __init__(inout self, n: String, t: tcstypeinfo, m: String):
        self.name = n
        self.type = t
        self.meta = m

@value
struct tcConnPt:
    var ti: tcsvarinfo
    var unit: tcUnit
    var idx: Int
    var pt: wxPoint
    var isinput: Bool

    def __init__(inout self, t: tcsvarinfo, u: tcUnit, vi: Int, p: wxPoint, inp: Bool):
        self.ti = t
        self.unit = u
        self.idx = vi
        self.pt = p
        self.isinput = inp

@value
struct SPair:
    var key: String
    var value: String

@value
struct tcUnit:
    var type: tcstypeinfo
    var x: Int = 20
    var y: Int = 20
    var description: String = ""
    var values: List[SPair] = List[SPair]()
    var rdr: RDR = RDR()

    struct RDR:
        var width: Int = 100
        var height: Int = 100
        var inputs: List[tcConnPt] = List[tcConnPt]()
        var outputs: List[tcConnPt] = List[tcConnPt]()

    def __init__(inout self):
        self.type = None
        self.x = 20
        self.y = 20
        self.rdr.width = 100
        self.rdr.height = 100

@value
struct tcConn:
    var start: tcUnit
    var end: tcUnit
    var start_pt: tcConnPt
    var end_pt: tcConnPt
    var ftol: Float64 = 0.1
    var index: Int = -1
    var waypoints: List[wxPoint] = List[wxPoint]()

    def __init__(inout self):
        self.start = None
        self.end = None
        self.start_pt = None
        self.end_pt = None
        self.ftol = 0.1
        self.index = -1
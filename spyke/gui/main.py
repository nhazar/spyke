"""Main spyke window"""

from __future__ import division

__authors__ = 'Martin Spacek, Reza Lotun'

import wx
import wx.html
import wx.py
import cPickle
import os
import sys
import time
import datetime
import gzip
from copy import copy

import spyke
from spyke import core, surf, detect
from spyke.gui.sort import SortSession, Detection
from spyke.core import toiter, MU, intround
from spyke.gui.plot import ChartPanel, LFPPanel, SpikePanel
import wxglade_gui

DEFSPIKETW = 1000 # spike frame temporal window width (us)
DEFCHARTTW = 50000 # chart frame temporal window width (us)
DEFLFPTW = 1000000 # lfp frame temporal window width (us)

SPIKEFRAMEPIXPERCHAN = 80 # horizontally
SPIKEFRAMEHEIGHT = 700
CHARTFRAMESIZE = (900, SPIKEFRAMEHEIGHT)
LFPFRAMESIZE = (250, SPIKEFRAMEHEIGHT)
SORTFRAMESIZE = (400, 600)
PYSHELLSIZE = (CHARTFRAMESIZE[0], CHARTFRAMESIZE[1]/2)

FRAMEUPDATEORDER = ['spike', 'lfp', 'chart'] # chart goes last cuz it's slowest

class SpykeFrame(wxglade_gui.SpykeFrame):
    """spyke's main frame, inherits gui layout code auto-generated by wxGlade"""

    DEFAULTDIR = '/data/ptc15'
    FRAMETYPE2ID = {'spike': wx.ID_SPIKEWIN,
                    'chart': wx.ID_CHARTWIN,
                    'lfp': wx.ID_LFPWIN,
                    'sort': wx.ID_SORTWIN,
                    'pyshell': wx.ID_PYSHELL}
    REFTYPE2ID = {'tref': wx.ID_TREF,
                  'vref': wx.ID_VREF,
                  'caret': wx.ID_CARET}

    def __init__(self, *args, **kwargs):
        wxglade_gui.SpykeFrame.__init__(self, *args, **kwargs)
        self.SetPosition(wx.Point(x=0, y=0)) # upper left corner
        self.dpos = {} # positions of data frames relative to main spyke frame
        self.srff = None # Surf File object
        self.srffname = '' # used for setting title caption
        self.sortfname = '' # used for setting title caption
        self.frames = {} # holds spike, chart, lfp, sort, and pyshell frames
        self.spiketw = DEFSPIKETW # spike frame temporal window width (us)
        self.charttw = DEFCHARTTW # chart frame temporal window width (us)
        self.lfptw = DEFLFPTW # lfp frame temporal window width (us)
        self.t = None # current time position in recording (us)

        self.hpstream = None
        self.lpstream = None

        self.Bind(wx.EVT_CLOSE, self.OnExit)
        self.Bind(wx.EVT_MOVE, self.OnMove)

        self.slider.Bind(wx.EVT_SLIDER, self.OnSlider)

        #self.Bind(wx.EVT_KEY_DOWN, self.OnKeyDown)

        columnlabels = ['ID', 'nevents', 'class', 'thresh', 'trange', 'slock', 'tlock', 'datetime']
        for coli, label in enumerate(columnlabels):
            self.detection_list.InsertColumn(coli, label)
        for coli in range(len(columnlabels)): # this needs to be in a separate loop it seems
            self.detection_list.SetColumnWidth(coli, wx.LIST_AUTOSIZE_USEHEADER)

        self.set_detect_pane_limits()

        self.file_combo_box_units_label.SetLabel(MU+'s') # can't seem to set mu symbol from within wxGlade
        self.fixedthresh_units_label.SetLabel(MU+'V')
        self.range_units_label.SetLabel(MU+'s')
        self.blocksize_units_label.SetLabel(MU+'s')
        self.spatial_units_label.SetLabel(MU+'m')
        self.temporal_units_label.SetLabel(MU+'s')

        # disable most widgets until a .srf file is opened
        self.EnableWidgets(False)
        self.EnableSave(False) # disable Save until there's something to Save

        # TODO: load recent file history and add it to menu (see wxGlade code that uses wx.FileHistory)

        #fname = '/home/mspacek/Desktop/Work/spyke/data/large_data.srf'
        fname = self.DEFAULTDIR + '/87 - track 7c spontaneous craziness.srf'
        #self.OpenSurfFile(fname) # have this here just to make testing faster

    def set_detect_pane_limits(self):
        self.fixedthresh_spin_ctrl.SetRange(-sys.maxint, sys.maxint)
        self.fixedthresh_spin_ctrl.SetValue(detect.Detector.DEFFIXEDTHRESH)
        self.noisemult_spin_ctrl.SetValue(detect.Detector.DEFNOISEMULT)
        #self.noise_method_choice.SetSelection(0)
        self.nevents_spin_ctrl.SetRange(0, sys.maxint)
        self.blocksize_combo_box.SetValue(str(detect.Detector.DEFBLOCKSIZE))
        self.slock_spin_ctrl.SetRange(0, sys.maxint)
        self.tlock_spin_ctrl.SetRange(0, sys.maxint)
        self.slock_spin_ctrl.SetValue(detect.Detector.DEFSLOCK)
        self.tlock_spin_ctrl.SetValue(detect.Detector.DEFTLOCK)

    def OnNew(self, event):
        self.CreateNewSession()

    def OnOpen(self, event):
        dlg = wx.FileDialog(self, message="Open surf or sort file",
                            defaultDir=self.DEFAULTDIR, defaultFile='',
                            wildcard="All files (*.*)|*.*|Surf files (*.srf)|*.srf|Sort files (*.sort)|*.sort",
                            style=wx.OPEN)
        if dlg.ShowModal() == wx.ID_OK:
            fname = dlg.GetPath()
            self.OpenFile(fname)
        dlg.Destroy()

    def OnSave(self, event):
        if not self.sortfname:
            self.OnSaveAs(event)
        else:
            self.SaveSortFile(self.sortfname) # save to existing sort fname

    def OnSaveAs(self, event):
        """Save sort session to new .sort file"""
        dlg = wx.FileDialog(self, message="Save sort session as",
                            defaultDir=self.DEFAULTDIR, defaultFile='',
                            wildcard="Sort files (*.sort)|*.sort|All files (*.*)|*.*",
                            style=wx.SAVE | wx.OVERWRITE_PROMPT)
        if dlg.ShowModal() == wx.ID_OK:
            fname = dlg.GetPath()
            self.SaveSortFile(fname)
        dlg.Destroy()

    def OnClose(self, event):
        # TODO: add confirmation dialog if sort session not saved
        self.CloseSurfFile()

    def OnExit(self, event):
        # TODO: add confirmation dialog if sort session not saved
        self.CloseSurfFile()
        self.Destroy()

    def OnAbout(self, event):
        dlg = SpykeAbout(self)
        dlg.ShowModal()
        dlg.Destroy()

    def OnSpike(self, event):
        """Spike window toggle menu/button event"""
        self.ToggleFrame('spike')

    def OnChart(self, event):
        """Chart window toggle menu/button event"""
        self.ToggleFrame('chart')

    def OnLFP(self, event):
        """LFP window toggle menu/button event"""
        self.ToggleFrame('lfp')

    def OnSort(self, event):
        """Sort window toggle menu/button event"""
        self.ToggleFrame('sort')

    def OnPyShell(self, event):
        """PyShell window toggle menu/button event"""
        self.ToggleFrame('pyshell')

    def OnTref(self, event):
        """Time reference toggle menu event"""
        self.ToggleRef('tref')

    def OnVref(self, event):
        """Voltage reference toggle menu event"""
        self.ToggleRef('vref')

    def OnCaret(self, event):
        """Caret toggle menu event"""
        self.ToggleRef('caret')

    def OnMove(self, event):
        """Move frame, and all dataframes as well, like docked windows"""
        for frametype, frame in self.frames.items():
            frame.Move(self.GetPosition() + self.dpos[frametype])
        #event.Skip() # apparently this isn't needed for a move event,
        # I guess the OS moves the frame no matter what you do with the event

    def OnFileComboBox(self, event):
        """Change file position using combo box control,
        convert start, now, and end to appropriate vals"""
        # TODO: I set a value manually, but the OS overrides the value
        # after this handler finishes handling the event. Eg, I want 'start'
        # to be replaced with the actual self.t0 timestamp, which it is, but is then
        # immediately replaced back to 'start' by the OS. Don't know how to
        # prevent its propagation to the OS. ComboBoxEvent is a COMMAND event
        t = self.file_combo_box.GetValue()
        try:
            t = self.str2t[t]
        except KeyError:
            # convert to float first so you can use exp notation as shorthand
            t = float(t)
        self.seek(t)

    def OnSlider(self, event):
        """Strange: keyboard press or page on mouse click when slider in focus generates
        two slider events, and hence two plot events - mouse drag only generates one slider event"""
        self.seek(self.slider.GetValue())
        #print time.time(), 'OnSlider()'
        #event.Skip() # doesn't seem to be necessary

    def OnSearch(self, event):
        """Detect pane Search button click"""
        self.session.detector = self.get_detector()
        events = self.session.detector.search()
        detection = Detection(self.session, self.session.detector, id=self._detid,
                              datetime=datetime.datetime.now(),
                              events=events) # generate a new Detection run
        if detection not in self.session.detections: # suppress Detection runs with an identical set of .events (see __eq__)
            self.session.detections.append(detection)
            self.append_detection_list_ctrl(detection)
            self.EnableSave(True)
            print '%r' % detection.events

    def append_detection_list_ctrl(self, detection):
        """Appends Detection run to the detection list control"""
        row = [str(detection.id),
               str(detection.events.shape[1]),
               detection.detector.algorithm + detection.detector.threshmethod,
               str(detection.detector.fixedthresh or detection.det.noisemult),
               str(detection.detector.trange),
               str(detection.detector.slock),
               str(detection.detector.tlock),
               str(detection.datetime).rpartition('.')[0] ]
        self.detection_list.Append(row)
        for coli in range(len(row)):
            self.detection_list.SetColumnWidth(coli, wx.LIST_AUTOSIZE_USEHEADER) # resize columns to fit
        self._detid += 1 # inc for next unique Detection run
        self.total_nevents_label.SetLabel(str(self.get_total_nevents()))

    def get_total_nevents(self):
        """Get total nevents across all detection runs"""
        nevents = 0
        for det in self.session.detections:
            nevents += det.events.shape[1]
        return nevents

    def OnKeyDown(self, event):
        """Handle key presses
        TODO: might be able to clean this up by having a handler for wx.EVT_NAVIGATION_KEY
        """
        key = event.GetKeyCode()
        #print 'key: %r' % key
        in_widget = event.GetEventObject().ClassName in ['wxComboBox', 'wxSpinCtrl', 'wxSlider']
        in_file_combo_box = event.GetEventObject() == self.file_combo_box
        if not event.ControlDown():
            if key == wx.WXK_LEFT and not in_widget or key == wx.WXK_DOWN and in_file_combo_box:
                    self.seek(self.t - self.hpstream.tres)
            elif key == wx.WXK_RIGHT and not in_widget or key == wx.WXK_UP and in_file_combo_box:
                    self.seek(self.t + self.hpstream.tres)
            elif key == wx.WXK_PRIOR: # PGUP
                self.seek(self.t - self.spiketw)
            elif key == wx.WXK_NEXT: # PGDN
                self.seek(self.t + self.spiketw)
            elif key == wx.WXK_F2: # search for previous event
                self.findevent(which='previous')
            elif key == wx.WXK_F3: # search for next event
                self.findevent(which='next')
        else: # CTRL is down
            if key == wx.WXK_PRIOR: # PGUP
                self.seek(self.t - self.charttw)
            elif key == wx.WXK_NEXT: # PGDN
                self.seek(self.t + self.charttw)
        # when key event comes from file_combo_box, reserve down/up for seeking through file
        if in_widget and not in_file_combo_box or in_file_combo_box and key not in [wx.WXK_DOWN, wx.WXK_UP]:
            event.Skip() # pass event on to OS to handle cursor movement

    def OpenFile(self, fname):
        """Open either .srf or .sort file"""
        ext = os.path.splitext(fname)[1]
        if ext == '.srf':
            self.OpenSurfFile(fname)
        elif ext == '.sort':
            self.OpenSortFile(fname)
        else:
            wx.MessageBox("%s is not a .srf or .sort file" % fname,
                          caption="Error", style=wx.OK|wx.ICON_EXCLAMATION)
            return

    def OpenSurfFile(self, fname):
        """Open a .srf file, and update display accordingly"""
        self.CloseSurfFile() # in case a .srf file and frames are already open
        self.srff = surf.File(fname)
        # TODO: parsing progress dialog
        self.srff.parse()
        self.srffname = self.srff.name # update
        self.SetTitle(os.path.basename(self.srffname)) # update the caption

        self.hpstream = core.Stream(self.srff.highpassrecords) # highpass record (spike) stream
        self.lpstream = core.Stream(self.srff.lowpassmultichanrecords) # lowpassmultichan record (LFP) stream
        self.chans_enabled = copy(self.hpstream.layout.chanlist) # property
        self.t = intround(self.hpstream.t0 + self.spiketw/2) # set current time position in recording (us)

        self.OpenFrame('spike')
        self.OpenFrame('chart')
        self.OpenFrame('lfp')
        #self.OpenFrame('sort')
        #self.OpenFrame('pyshell')
        self.ShowRef('tref')
        self.ShowRef('vref')
        self.ShowRef('caret')

        # self has focus, but isn't in foreground after opening data frames
        #self.Raise() # doesn't seem to bring self to foreground
        #wx.GetApp().SetTopWindow(self) # neither does this

        self.str2t = {'start': self.hpstream.t0,
                      'now': self.t,
                      'end': self.hpstream.tend}

        self.range = (self.hpstream.t0, self.hpstream.tend) # us
        self.file_combo_box.SetValue(str(self.t))
        self.file_min_label.SetLabel(str(self.hpstream.t0))
        self.file_max_label.SetLabel(str(self.hpstream.tend))
        self.slider.SetRange(self.range[0], self.range[1])
        self.slider.SetValue(self.t)
        self.slider.SetLineSize(self.hpstream.tres) # us, TODO: this should be based on level of interpolation
        self.slider.SetPageSize(self.spiketw) # us

        self.CreateNewSession() # create a new SortSession

        self.EnableWidgets(True)
        #self.detection_list.SetToolTip(wx.ToolTip('hello world'))

    def CreateNewSession(self):
        """Create a new SortSession and bind it to .self"""
        self.DeleteSession()
        self.session = SortSession(detector=self.get_detector(),
                                   srffname=self.srff.name)

    def DeleteSession(self):
        """Delete any existing SortSession"""
        try:
            # TODO: check if it's saved (if not, prompt to save)
            print 'deleting existing session and entries in detection list control'
            del self.session
        except AttributeError:
            pass
        self.detection_list.DeleteAllItems()
        self._detid = 0 # reset current Detection run ID
        self.total_nevents_label.SetLabel(str(0))

    def get_chans_enabled(self):
        return [ chan for chan, enable in self._chans_enabled.items() if enable ]

    def set_chans_enabled(self, chans, enable=True):
        """Updates enable flag of all chans in .chans_enabled dict"""
        if chans == None: # None means all chans
            chans = copy(self.hpstream.layout.chanlist)
        chans = toiter(chans) # need not be contiguous
        try:
            self._chans_enabled
        except AttributeError:
            self._chans_enabled = {}
        for chan in chans:
            self._chans_enabled[chan] = enable
        try:
            self.frames['spike'].panel.enable_chans(chans, enable)
            self.frames['chart'].panel.enable_chans(chans, enable)
        except KeyError:
            pass

    chans_enabled = property(get_chans_enabled, set_chans_enabled)

    def CloseSurfFile(self):
        """Destroy data and sort frames, clean up, close .srf file"""
        # need to specifically get a list of keys, not an iterator,
        # since self.frames dict changes size during iteration
        for frametype in self.frames.keys():
            if frametype != 'pyshell': # leave pyshell frame alone
                self.CloseFrame(frametype) # deletes from dict
        self.hpstream = None
        self.lpstream = None
        self.chans_enabled = []
        self.t = None
        self.spiketw = DEFSPIKETW # reset
        self.charttw = DEFCHARTTW
        self.lfptw = DEFLFPTW
        self.SetTitle('spyke') # update caption
        self.EnableWidgets(False)
        try:
            self.srff.close()
        except AttributeError: # self.srff is already None, no .close() method
            pass
        self.srff = None
        self.srffname = ''
        self.CloseSortFile()

    def CloseSortFile(self):
        self.DeleteSession()
        self.EnableSave(False)
        self.sortfname = '' # forces a SaveAs on next Save event

    def OpenSortFile(self, fname):
        """Open a sort session from a .sort file"""
        #try:
        self.DeleteSession() # delete any existing SortSession
        f = gzip.open(fname, 'rb')
        self.session = cPickle.load(f)
        f.close()
        if self.hpstream != None:
            self.session.set_streams(self.hpstream) # restore missing stream object to session
        else: # no .srf file is open, no stream exists
            self.notebook.Show(True) # so we can do stuff with the SortSession
        for detection in self.session.detections:
            self.append_detection_list_ctrl(detection)
        self.sortfname = fname # bind it now that it's been successfully loaded
        self.SetTitle(os.path.basename(self.srffname) + ' | ' + os.path.basename(self.sortfname))
        self.update_detect_pane(self.session.detector)
        self.EnableSave(False)
        print 'done opening sort file'
        #except cPickle.UnpicklingError:
        #    wx.MessageBox("Couldn't open %s as a sort file" % fname,
        #                  caption="Error", style=wx.OK|wx.ICON_EXCLAMATION)

    def SaveSortFile(self, fname):
        """Save sort session to a .sort file"""
        #try:
        if not os.path.splitext(fname)[1]: # if it doesn't have an extension
            fname = fname + '.sort'
        pf = gzip.open(fname, 'wb') # compress pickle with gzip, can also control compression level
        p = cPickle.Pickler(pf, protocol=-1) # make a Pickler, use most efficient (least human readable) protocol
        self.session.set_streams(None) # remove all stream objects from session before pickling
        p.dump(self.session)
        pf.close()
        self.session.set_streams(self.hpstream) # restore stream object to session
        self.sortfname = fname # bind it now that it's been successfully saved
        self.SetTitle(os.path.basename(self.srffname) + ' | ' + os.path.basename(self.sortfname))
        self.EnableSave(False)
        print 'done saving sort file'
        #except TypeError:
        #    wx.MessageBox("Couldn't save %s as a sort file" % fname,
        #                  caption="Error", style=wx.OK|wx.ICON_EXCLAMATION)

    def EnableSave(self, enable):
        """Enable/disable Save menu item and toolbar button"""
        self.menubar.Enable(wx.ID_SAVE, enable)
        self.toolbar.EnableTool(wx.ID_SAVE, enable) # Save button

    def OpenFrame(self, frametype):
        """Create and bind a frame, show it, plot its data if applicable"""
        if frametype not in self.frames: # check it doesn't already exist
            if frametype == 'spike':
                ncols = self.hpstream.probe.ncols
                x = self.GetPosition()[0]
                y = self.GetPosition()[1] + self.GetSize()[1]
                frame = SpikeFrame(parent=self, stream=self.hpstream,
                                   tw=self.spiketw,
                                   pos=wx.Point(x, y), size=(ncols*SPIKEFRAMEPIXPERCHAN, SPIKEFRAMEHEIGHT))
            elif frametype == 'chart':
                x = self.GetPosition()[0] + self.frames['spike'].GetSize()[0]
                y = self.GetPosition()[1] + self.GetSize()[1]
                frame = ChartFrame(parent=self, stream=self.hpstream,
                                   tw=self.charttw, cw=self.spiketw,
                                   pos=wx.Point(x, y), size=CHARTFRAMESIZE)
            elif frametype == 'lfp':
                x = self.GetPosition()[0] + self.frames['spike'].GetSize()[0] + self.frames['chart'].GetSize()[0]
                y = self.GetPosition()[1] + self.GetSize()[1]
                frame = LFPFrame(parent=self, stream=self.lpstream,
                                 tw=self.lfptw, cw=self.charttw,
                                 pos=wx.Point(x, y), size=LFPFRAMESIZE)
            elif frametype == 'sort':
                x = self.GetPosition()[0] + self.GetSize()[0]
                y = self.GetPosition()[1]
                frame = SortFrame(parent=self, stream=self.hpstream,
                                  pos=wx.Point(x, y), size=SORTFRAMESIZE)
            elif frametype == 'pyshell':
                try:
                    ncols = self.hpstream.probe.ncols
                except AttributeError:
                    ncols = 2 # assume 2 columns
                x = self.GetPosition()[0] + ncols*SPIKEFRAMEPIXPERCHAN
                y = self.GetPosition()[1] + self.GetSize()[1] + SPIKEFRAMEHEIGHT - PYSHELLSIZE[1]
                frame = PyShellFrame(parent=self, pos=wx.Point(x, y), size=PYSHELLSIZE)
            self.frames[frametype] = frame
            self.dpos[frametype] = frame.GetPosition() - self.GetPosition()
        self.ShowFrame(frametype)

    def ShowFrame(self, frametype, enable=True):
        """Show/hide a frame, force menu and toolbar states to correspond"""
        self.frames[frametype].Show(enable)
        id = self.FRAMETYPE2ID[frametype]
        self.menubar.Check(id, enable)
        self.toolbar.ToggleTool(id, enable)
        if enable and frametype not in ['sort', 'pyshell']:
            self.plot(frametype) # update only the newly shown data frame's data, in case self.t changed since it was last visible

    def HideFrame(self, frametype):
        self.ShowFrame(frametype, False)

    def ToggleFrame(self, frametype):
        """Toggle visibility of a data frame"""
        try:
            frame = self.frames[frametype]
            self.ShowFrame(frametype, not frame.IsShown()) # toggle it
        except KeyError: # frame hasn't been opened yet
            self.OpenFrame(frametype)

    def CloseFrame(self, frametype):
        """Hide frame, remove it from frames dict, destroy it"""
        self.HideFrame(frametype)
        frame = self.frames.pop(frametype)
        frame.Destroy()

    def ShowRef(self, ref, enable=True):
        """Show/hide a tref, vref, or the caret. Force menu states to correspond"""
        self.menubar.Check(self.REFTYPE2ID[ref], enable)
        for frametype, frame in self.frames.items():
            if frametype not in ['sort', 'pyshell']:
                frame.panel.show_ref(ref, enable=enable)

    def ToggleRef(self, ref):
        """Toggle visibility of a tref, vref, or the caret"""
        enable = self.frames.items()[0] # pick a random frame
        self.ShowRef(ref, self.menubar.IsChecked(self.REFTYPE2ID[ref])) # maybe not safe, but seems to work

    def EnableWidgets(self, enable):
        """Enable/disable all widgets that require an open .srf file"""
        self.menubar.Enable(wx.ID_NEW, enable)
        self.menubar.Enable(wx.ID_SPIKEWIN, enable)
        self.menubar.Enable(wx.ID_CHARTWIN, enable)
        self.menubar.Enable(wx.ID_LFPWIN, enable)
        #self.menubar.Enable(wx.ID_SORTWIN, enable) # sort win doesn't need an open .srf file
        #self.menubar.Enable(wx.ID_PYSHELL, enable) # pyshell doesn't need an open .srf file
        self.menubar.Enable(wx.ID_TREF, enable)
        self.menubar.Enable(wx.ID_VREF, enable)
        self.menubar.Enable(wx.ID_CARET, enable)
        self.menubar.Enable(wx.ID_CARET, enable)
        self.toolbar.EnableTool(wx.ID_NEW, enable)
        self.toolbar.EnableTool(wx.ID_SPIKEWIN, enable)
        self.toolbar.EnableTool(wx.ID_CHARTWIN, enable)
        self.toolbar.EnableTool(wx.ID_LFPWIN, enable)
        #self.toolbar.EnableTool(wx.ID_SORTWIN, enable) # sort win doesn't need an open .srf file
        #self.toolbar.EnableTool(wx.ID_PYSHELL, enable) # pyshell doesn't need an open .srf file
        self.file_control_panel.Show(enable)
        self.notebook.Show(enable)
        self.file_min_label.Show(enable)
        self.file_max_label.Show(enable)

    def get_detector(self):
        """Create a Detector object based on attribs from GUI"""
        detectorClass = self.get_detectorclass()
        det = detectorClass(stream=self.hpstream)
        self.update_detector(det)
        return det

    def update_detector(self, det):
        """Update detector object attribs from GUI"""
        det.chans = self.chans_enabled # property
        det.fixedthresh = self.fixedthresh_spin_ctrl.GetValue()
        det.noisemult = self.noisemult_spin_ctrl.GetValue()
        #det.noisewindow = self.noisewindow_spin_ctrl # not in the gui yet
        det.trange = self.get_detectortrange()
        det.maxnevents = self.nevents_spin_ctrl.GetValue() or det.DEFMAXNEVENTS # if 0, use default
        det.blocksize = int(self.blocksize_combo_box.GetValue())
        det.slock = self.slock_spin_ctrl.GetValue()
        det.tlock = self.tlock_spin_ctrl.GetValue()

    def update_detect_pane(self, det):
        """Update detect pane with detector attribs"""
        self.set_detectorclass(det)
        self.chans_enabled = det.chans
        self.fixedthresh_spin_ctrl.SetValue(det.fixedthresh)
        self.noisemult_spin_ctrl.SetValue(det.noisemult)
        #self.noisewindow_spin_ctrl.SetValue(det.noisewindow) # not in the gui yet
        self.range_start_combo_box.SetValue(str(det.trange[0]))
        self.range_end_combo_box.SetValue(str(det.trange[1]))
        if det.maxnevents == det.DEFMAXNEVENTS:
            self.nevents_spin_ctrl.SetValue(0) # if default, use 0
        else:
            self.nevents_spin_ctrl.SetValue(det.maxnevents)
        self.blocksize_combo_box.SetValue(str(det.blocksize))
        self.slock_spin_ctrl.SetValue(det.slock)
        self.tlock_spin_ctrl.SetValue(det.tlock)

    def get_detectorclass(self):
        """Figure out which Detector class to use based on algorithm and
        threshmethod radio selections"""
        algorithm = self.algorithm_radio_box.GetStringSelection()
        if self.fixedthresh_radio_btn.GetValue():
            threshmethod = 'FixedThresh'
        elif self.dynamicthresh_radio_btn.GetValue():
            threshmethod = 'DynamicThresh'
        else:
            raise ValueError
        classstr = algorithm + threshmethod
        return eval('detect.'+classstr)

    def set_detectorclass(self, det):
        """Update algorithm and threshmethod radio buttons to match current Detector"""
        self.algorithm_radio_box.SetStringSelection(det.algorithm)
        meth2radiobtn = {'FixedThresh': self.fixedthresh_radio_btn,
                         'DynamicThresh': self.dynamicthresh_radio_btn}
        meth2radiobtn[det.threshmethod].SetValue(True) # enable the appropriate radio button

    def get_detectortrange(self):
        """Get detector time range from combo boxes, and convert
        start, now, and end to appropriate vals"""
        tstart = self.range_start_combo_box.GetValue()
        tend = self.range_end_combo_box.GetValue()
        try:
            tstart = self.str2t[tstart]
        except KeyError:
            tstart = int(float(tstart)) # convert to float first so you can use exp notation as shorthand
        try:
            tend = self.str2t[tend]
        except KeyError:
            tend = int(float(tend))
        return tstart, tend

    def findevent(self, which='next'):
        """Find next or previous event, depending on which direction"""
        det = self.session.detector
        self.update_detector(det)
        det.maxnevents = 1 # override whatever was in nevents spin edit
        det.blocksize = 100000 # smaller blocksize, since we're only looking for 1 event
        if which == 'next':
            det.trange = (self.t+1, self.hpstream.tend)
        elif which == 'previous':
            det.trange = (self.t-1, self.hpstream.t0)
        else:
            raise ValueError, which
        event = det.search() # don't bother saving it, don't update total_nevents_label
        wx.SafeYield(win=self, onlyIfNeeded=True) # allow controls to update
        try: # if an event was found
            t = event[0, 0]
            self.seek(t) # seek to it
            print '%r' % event
        except IndexError: # if not, do nothing
            pass

    def seek(self, offset=0):
        """Seek to position in surf file. offset is time in us"""
        self.oldt = self.t
        self.t = offset
        self.t = intround(self.t / self.hpstream.tres) * self.hpstream.tres # round to nearest (possibly interpolated) sample
        self.t = min(max(self.t, self.range[0]), self.range[1]) # constrain to within .range
        self.str2t['now'] = self.t # update
        # only plot if t has actually changed, though this doesn't seem to improve
        # performance, maybe mpl is already doing something like this?
        if self.t != self.oldt:
            # update controls first so they don't lag
            self.file_combo_box.SetValue(str(self.t)) # update file combo box
            self.slider.SetValue(self.t) # update slider
            wx.SafeYield(win=self, onlyIfNeeded=True) # allow controls to update
            self.plot()
    '''
    def step(self, direction):
        """Step one timepoint left or right"""
        self.seek(self.t + direction*self.hpstream.tres)

    def page(self, direction):
        """Page left or right"""
        self.seek(self.t + direction*self.hpstream.tres)
    '''
    def tell(self):
        """Return current position in surf file"""
        return self.t

    def plot(self, frametypes=None):
        """Update the contents of all the data frames, or just specific ones.
        Center each data frame on self.t, don't left justify"""
        if frametypes == None: # update all visible frames
            frametypes = self.frames.keys()
        else: # update only specific frames, if visible
            frametypes = toiter(frametypes)
        frametypes = [ frametype for frametype in FRAMEUPDATEORDER if frametype in frametypes ] # reorder
        frames = [ self.frames[frametype] for frametype in frametypes ] # get frames in order
        for frametype, frame in zip(frametypes, frames):
            if frame.IsShown(): # for performance, only update if frame is shown
                if frametype == 'spike':
                    wave = self.hpstream[self.t-self.spiketw/2 : self.t+self.spiketw/2]
                elif frametype == 'chart':
                    wave = self.hpstream[self.t-self.charttw/2 : self.t+self.charttw/2]
                elif frametype == 'lfp':
                    wave = self.lpstream[self.t-self.lfptw/2 : self.t+self.lfptw/2]
                frame.panel.plot(wave, tref=self.t) # plot it


class DataFrame(wx.MiniFrame):
    """Base data frame to hold a custom spyke panel widget.
    Copied and modified from auto-generated wxglade_gui.py code"""

    # no actual maximize button, but allows caption double-click to maximize
    # need SYSTEM_MENU to make close box appear in a TOOL_WINDOW, at least on win32
    STYLE = wx.CAPTION|wx.CLOSE_BOX|wx.MAXIMIZE_BOX|wx.SYSTEM_MENU|wx.RESIZE_BORDER|wx.FRAME_TOOL_WINDOW

    def __init__(self, *args, **kwds):
        kwds["style"] = self.STYLE
        wx.MiniFrame.__init__(self, *args, **kwds)

    def set_properties(self):
        self.SetTitle("data window")
        self.SetSize((160, 24))

    def do_layout(self):
        dataframe_sizer = wx.BoxSizer(wx.HORIZONTAL)
        dataframe_sizer.Add(self.panel, 1, wx.EXPAND, 0)
        self.SetSizer(dataframe_sizer)
        self.Layout()

    def OnClose(self, event):
        frametype = self.__class__.__name__.lower().replace('frame', '') # remove 'Frame' from class name
        self.Parent.HideFrame(frametype)


class SpikeFrame(DataFrame):
    """Frame to hold the custom spike panel widget"""
    def __init__(self, parent=None, stream=None, tw=None, cw=None, *args, **kwds):
        DataFrame.__init__(self, parent, *args, **kwds)
        self.panel = SpikePanel(self, -1, stream=stream, tw=tw, cw=cw)

        self.Bind(wx.EVT_CLOSE, self.OnClose)

        self.set_properties()
        self.do_layout()

    def set_properties(self):
        self.SetTitle("spike window")


class ChartFrame(DataFrame):
    """Frame to hold the custom chart panel widget"""
    def __init__(self, parent=None, stream=None, tw=None, cw=None, *args, **kwds):
        DataFrame.__init__(self, parent, *args, **kwds)
        self.panel = ChartPanel(self, -1, stream=stream, tw=tw, cw=cw)

        self.Bind(wx.EVT_CLOSE, self.OnClose)

        self.set_properties()
        self.do_layout()

    def set_properties(self):
        self.SetTitle("chart window")


class LFPFrame(DataFrame):
    """Frame to hold the custom LFP panel widget"""
    def __init__(self, parent=None, stream=None, tw=None, cw=None, *args, **kwds):
        DataFrame.__init__(self, parent, *args, **kwds)
        self.panel = LFPPanel(self, -1, stream=stream, tw=tw, cw=cw)

        self.Bind(wx.EVT_CLOSE, self.OnClose)

        self.set_properties()
        self.do_layout()

    def set_properties(self):
        self.SetTitle("LFP window")


class SortFrame(wxglade_gui.SortFrame):
    """Sort frame"""
    def __init__(self, parent=None, stream=None, *args, **kwds):
        wxglade_gui.SortFrame.__init__(self, parent, *args, **kwds)
        #self.panel = SortPanel(self, -1, stream=stream, tw=tw)

        columnlabels = ['ID', 'chan', 'time']
        for coli, label in enumerate(columnlabels):
            self.list.InsertColumn(coli, label)

        self.Bind(wx.EVT_CLOSE, self.OnClose)

    def OnClose(self, event):
        frametype = self.__class__.__name__.lower().replace('frame', '') # remove 'Frame' from class name
        self.Parent.HideFrame(frametype)


class PyShellFrame(wx.py.shell.ShellFrame):
    """PyShell frame"""
    def __init__(self, *args, **kwargs):
        cfgdir = wx.StandardPaths.Get().GetUserDataDir() # '/home/mspacek/Application Data/pyshell'
        if not os.path.exists(cfgdir):
            os.mkdir(cfgdir)
        cfgfname = 'minimal_config' # 'config' is the default that wx installs, I think
        fname = os.path.join(cfgdir, cfgfname)
        config = wx.FileConfig(localFilename=fname) # get config fom file
        config.SetRecordDefaults(True)
        title = 'spyke PyShell'
        kwargs.update(dict(config=config, dataDir=cfgdir, title=title))
        wx.py.shell.ShellFrame.__init__(self, *args, **kwargs)
        self.shell.run('self = app.spykeframe') # convenience

        self.Bind(wx.EVT_CLOSE, self.OnClose)

    def OnClose(self, event):
        frametype = self.__class__.__name__.lower().replace('frame', '') # remove 'Frame' from class name
        self.Parent.HideFrame(frametype)


class SpykeAbout(wx.Dialog):
    text = '''
        <html>
        <body bgcolor="#D4D0C8">
        <center><table bgcolor="#000000" width="100%" cellspacing="0"
        cellpadding="0" border="0">
        <tr>
            <td align="center"><h1><font color="#00FF00">spyke</font></h1></td>
        </tr>
        </table>
        </center>
        <p><b>spyke</b> is a tool for neuronal spike sorting.
        </p>

        <p>Copyright &copy; 2008 Martin Spacek, Reza Lotun</p>
        </body>
        </html>'''

    def __init__(self, parent):
        wx.Dialog.__init__(self, parent, -1, 'About spyke', size=(350, 250))

        html = wx.html.HtmlWindow(self)
        html.SetPage(self.text)
        button = wx.Button(self, wx.ID_OK, "OK")

        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(html, 1, wx.EXPAND|wx.ALL, 5)
        sizer.Add(button, 0, wx.ALIGN_CENTER|wx.ALL, 5)

        self.SetSizer(sizer)
        self.Layout()


class SpykeApp(wx.App):
    def OnInit(self, splash=False):
        if splash:
            bmp = wx.Image("res/splash.png").ConvertToBitmap()
            wx.SplashScreen(bmp, wx.SPLASH_CENTRE_ON_SCREEN | wx.SPLASH_TIMEOUT, 1000, None, -1)
            wx.Yield()
        self.spykeframe = SpykeFrame(None)
        self.spykeframe.Show()
        self.SetTopWindow(self.spykeframe)
        #self.sortframe = wxglade_gui.SortFrame(None)
        #self.sortframe.Show()

        # key presses aren't CommandEvents, and don't propagate up the window hierarchy, but
        # if left unhandled, are tested one final time here in the wx.App. Catch unhandled keypresses
        # here and call appropriate methods in the main spyke frame
        #self.Bind(wx.EVT_KEY_DOWN, self.spykeframe.OnKeyDown)

        return True


if __name__ == '__main__':
    app = SpykeApp(redirect=False) # output to stderr and stdout
    app.MainLoop()

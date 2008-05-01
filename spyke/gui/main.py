"""Main spyke window"""

import wx
import wx.html
import cPickle
import os

import spyke
from spyke import core, surf, probes
import plot
import wxglade_gui


class SpykeFrame(wxglade_gui.SpykeFrame):
    """spyke's main frame, inherits gui layout code auto-generated by wxGlade"""

    DEFAULTDIR = '/data/ptc15'

    def __init__(self, *args, **kwargs):
        wxglade_gui.SpykeFrame.__init__(self, *args, **kwargs)
        self.surffname = ""
        self.sortfname = ""

        self.Bind(wx.EVT_CLOSE, self.OnExit)

        # TODO: load recent file history and add it to menu (see wxGlade code that uses wx.FileHistory)

    def OnNew(self, event):
        # TODO: what should actually go here? just check if an existing collection exists,
        # check if it's saved (if not, prompt to save), and then del it and init a new one?
        pass

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
            self.SaveFile(self.sortfname) # save to existing sort fname

    def OnSaveAs(self, event):
        """Save collection to new .sort file"""
        dlg = wx.FileDialog(self, message="Save collection as",
                            defaultDir=self.DEFAULTDIR, defaultFile='',
                            wildcard="Sort files (*.sort)|*.sort|All files (*.*)|*.*",
                            style=wx.SAVE | wx.OVERWRITE_PROMPT)
        if dlg.ShowModal() == wx.ID_OK:
            fname = dlg.GetPath()
            self.SaveFile(fname)
        dlg.Destroy()

    def OnExit(self, event):
        # TODO: add confirmation dialog if collection not saved
        try:
            self.spikeframe.Destroy()
        except:
            pass
        try:
            self.surff.close()
        except AttributeError:
            pass
        self.Destroy()

    def OnAbout(self, event):
        dlg = SpykeAbout(self)
        dlg.ShowModal()
        dlg.Destroy()

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
        self.surff = surf.File(fname)
        # TODO: parsing progress dialog
        self.surff.parse()
        self.surffname = fname # bind it now that it's been successfully opened and parsed
        self.SetTitle(self.Title + ' - ' + self.surffname)
        self.stream = core.Stream(self.surff.highpassrecords)
        self.layoutrecord = self.surff.layoutrecords[0]
        probename = self.layoutrecord.electrode_name
        probename = probename.replace('\xb5', 'u') # replace 'micro' symbol with 'u'
        self.probe = eval('probes.' + probename)() # yucky

        # TODO: open spike, chart and LFP windows, depress their toggle buttons

        self.spikeframe = SpikeFrame(self.probe, None)
        self.spikeframe.Show(True)
        waveform = self.stream[0:1000] # first ms of data
        self.spikeframe.spikepanel.plot(waveform) # plot it

        #chartframe = wx.Frame(None)
        #lfpframe = wx.Frame(None)
        #self.spikepanel = plot.SpikePanel(spikeframe, self.probe.SiteLoc)
        #self.chartpanel = plot.ChartPanel(chartframe, self.probe.SiteLoc)
        #self.lfppanel = plot.ChartPanel(lfpframe, self.probe.SiteLoc)



        # showing a hidden widget causes drawing problems and requires minimize+maximize to fix
        #self.file_control_panel.Show(True)
        #self.notebook.Show(True) # ditto
        #self.Refresh() # doesn't seem to help

        self.file_control_panel.Enable(True)
        self.notebook.Enable(True)

    def seek(self, pos):
        """Seek to position in surf file"""
        # TODO: update spike window
        # TODO: update chart window
        # TODO: update LFP window
        # TODO: update slider
        self.pos = pos # bind it

    def tell(self):
        """Return current position in surf file"""
        return self.pos

    def OpenSortFile(self, fname):
        # TODO: do something with data (data is the collection object????)
        try:
            f = file(fname, 'rb')
            data = cPickle.load(f)
            f.close()
            self.sortfname = fname # bind it now that it's been successfully loaded
            self.SetTitle(self.Title + ' - ' + self.sortfname)
        except cPickle.UnpicklingError:
            wx.MessageBox("Couldn't open %s as a sort file" % fname,
                          caption="Error", style=wx.OK|wx.ICON_EXCLAMATION)

    def SaveFile(self, fname):
        """Save collection to existing .sort file"""
        if not os.path.splitext(fname)[1]:
            fname = fname + '.sort'
        f = file(fname, 'wb')
        cPickle.dump(self.collection, f)
        f.close()
        self.sortfname = fname # bind it now that it's been successfully saved
        self.SetTitle(self.Title + ' - ' + self.sortfname)


class SpikeFrame(wxglade_gui.SpikeFrame):
    """Frame to hold the custom spike panel widget.
    Copied and modified from auto-generated wxglade_gui.py code.
    Only thing really inherited is __set_properties()"""
    def __init__(self, probe, *args, **kwds):
        # begin wxGlade: SpikeFrame.__init__
        kwds["style"] = wx.DEFAULT_FRAME_STYLE
        wx.Frame.__init__(self, *args, **kwds)
        self.spikepanel = plot.SpikePanel(self, -1, layout=probe.SiteLoc)

        self.__set_properties()
        self.__do_layout()
        # end wxGlade

    def __do_layout(self):
        # begin wxGlade: SpikeFrame.__do_layout
        spikeframe_sizer = wx.BoxSizer(wx.HORIZONTAL)
        spikeframe_sizer.Add(self.spikepanel, 1, wx.EXPAND, 0) # added by mspacek
        self.SetSizer(spikeframe_sizer)
        self.Layout()
        # end wxGlade


class SpykeAbout(wx.Dialog):
    text = '''
        <html>
        <body bgcolor="#ACAA60">
        <center><table bgcolor="#455481" width="100%" cellspacing="0"
        cellpadding="0" border="1">
        <tr>
            <td align="center"><h1>spyke</h1></td>
        </tr>
        </table>
        </center>
        <p><b>spyke</b> is a tool for neuronal spike sorting.
        </p>

        <p>Copyright &copy; 2008 Reza Lotun, Martin Spacek</p>
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

        frame = SpykeFrame(None)
        frame.Show(True)
        self.SetTopWindow(frame)
        return True


if __name__ == '__main__':
    app = SpykeApp(False)
    app.MainLoop()

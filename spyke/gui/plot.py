"""plotting gui elements"""

from __future__ import division

__author__ = 'Reza Lotun'

import itertools
from copy import copy
import random
import numpy
import wx

from matplotlib import rcParams
rcParams['lines.linestyle'] = '-'
rcParams['lines.marker'] = ''

from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg
from matplotlib.figure import Figure
from matplotlib.lines import Line2D

from spyke import surf
from spyke.gui.events import *

DEFAULTCOLOUR = "#00FF00" # garish green
DEFAULTLINEWIDTH = 1


class PlottedItem(object):
    """A visually distinct object on our plot. These are usually spikes
    TODO: what's the point of this. Probably safe to remove..."""
    def __init__(self, spike):
        # defaults
        self.colour = DEFAULTCOLOUR
        self.channels = []


class AxesWrapper(object):
    """A wrapper around an axes that delegates access to attributes to an
    actual axes object. Really meant to make axes hashable"""
    def __init__(self, axes):
        self._spyke_axes = axes

    def __getattr__(self, name):
        """Delegate access of attribs to wrapped axes"""
        return getattr(self._spyke_axes, name)

    def __hash__(self):
        """Base the hash function on the position rect"""
        return hash(str(self.get_position(original=True)))

    def __eq__(self, other):
        return hash(self) == hash(other)


class SpykeLine(Line2D):
    """Line2D's that can be compared to each other for equality"""
    def __init__(self, *args, **kwargs):
        Line2D.__init__(self, *args, **kwargs)
        self.colour = 'none'
        self.chan_mask = True # is this channel-as-line displayed?

    def __hash__(self):
        """Hash the string representation of the y data"""
        return hash(self.colour + str(self._y))

    def __eq__(self, other):
        return hash(self) == hash(other)


class SingleAxesPlotPanel(FigureCanvasWxAgg):
    """Single axes plot panel. Base class for specific types of plot panels"""
    def __init__(self, parent, id=-1, layout=None):
        FigureCanvasWxAgg.__init__(self, parent, id, Figure())
        self._plot_setup = False
        self.layout = layout # layout with y coord origin at top
        self.pos = {} # position of lines
        self.channels = {} # plot y-data for each channel
        self.nchans = len(layout)
        self.set_params()
        self.my_ylim = None
        self.my_xlim = None

        # for plotting with mpl, convert all y coords to have origin at bottom, not top
        bottomlayout = copy(self.layout)
        ys = [y for x, y in bottomlayout.values()]
        maxy = max(ys)
        for key, (x, y) in bottomlayout.items():
            y = maxy - y
            bottomlayout[key] = (x, y) # update
        self.bottomlayout = bottomlayout

    def set_plot_layout(self, layout):
        """Override in subclasses"""
        pass

    def set_params(self):
        """Set extra parameters"""
        self.figure.set_facecolor('black')
        self.SetBackgroundColour(wx.BLACK)
        self.colours = [DEFAULTCOLOUR] * self.nchans
        self.linewidth = DEFAULTLINEWIDTH

    def init_plot(self, wave, colour=DEFAULTCOLOUR):
        """Create the single axes and its lines"""
        pos = [0, 0, 1, 1]
        self.my_ax = self.figure.add_axes(pos,
                                          axisbg='b',
                                          frameon=False,
                                          alpha=1.)

        # set layouts of the plot on the screen
        self.set_plot_layout(wave)

        self.my_ax._visible = False
        self.my_ax.set_xticks([])
        self.my_ax.set_yticks([])

        # shift x vals to be offset from 0
        self.static_x_vals = wave.ts - wave.ts[0]

        self.displayed_lines = {}
        self.my_ax._autoscaleon = False
        for chan, spacing in self.pos.iteritems():
            x_off, y_off = spacing
            line = SpykeLine(self.static_x_vals + x_off,
                             wave.data[chan] + y_off,
                             linewidth=self.linewidth,
                             color=self.colours[chan],
                             antialiased=True)
            line.colour = colour
            self.displayed_lines[chan] = line
            self.my_ax.add_line(line)

            self.channels[chan] = line

        self.my_ax._visible = True
        # redraw the display
        self.draw(True)

    def plot(self, waveforms):
        """Plot waveforms"""
        # check if we've set up our axes yet
        if not self._plot_setup: # TODO: does this really need to be checked on every single plot call?
            self.init_plot(waveforms)
            self._plot_setup = True

        # update plots with new data
        for chan in self.displayed_lines:
            x_off, y_off = self.pos[chan]
            self.displayed_lines[chan].set_ydata(waveforms.data[chan] + y_off)
            self.displayed_lines[chan]._visible = True
        self.my_ax._visible = True
        self.draw(True)


class ChartPanel(SingleAxesPlotPanel):
    """Chart panel. Presents all channels layed out vertically"""

    def set_params(self):
        SingleAxesPlotPanel.set_params(self)
        colgen = itertools.cycle(iter(['b', 'g', 'm', 'c', 'y', 'r', 'w']))
        self.colours = []
        for chan in xrange(self.nchans):
            self.colours.append(colgen.next())

    def set_plot_layout(self, wave):
        # the first channel starts at the top
        self.my_ax.set_ylim(-50, 54*100 - 50)
        self.my_ax.set_xlim(wave.ts[0], wave.ts[-1])
        for chan, coords in self.bottomlayout.iteritems():
            self.pos[chan] = (0, chan * 100)


class SpikePanel(SingleAxesPlotPanel):
    """Spike panel. Presents a narrow temporal window of all channels layed out according
    to self.layout"""

    def set_params(self):
        SingleAxesPlotPanel.set_params(self)
        self.colours = [DEFAULTCOLOUR] * self.nchans


    def set_plot_layout(self, wave):
        """Map from polytrode layout given as (x, y) coordinates
        into position information for the spike plots, which are stored
        as a list of four values [l, b, w, h].

        To illustrate this, consider
        loc_i = (x, y) are the coordinates for the polytrode on channel i.
        We want to map these coordinates to the unit square.

           (0,1)                          (1,1)
              +------------------------------+
              |        +--(w)--+
              |<-(l)-> |       |
              |        |  x,y (h)
              |        |       |
              |        +-------+
              |            ^
              |            | (b)
              |            v
              +------------------------------+
             (0,0)                          (0,1)

        NOTE that unlike indicated above, actual .layout coords are:
            x: distance from center of polytrode
            y: distance down from top of polytrode border (slightly above top site)

        So, y locations need to be swapped vertically before being used - use .bottomlayout"""

        # project coordinates onto x and y axes respectively
        xs = [x for x, y in self.bottomlayout.values()]
        ys = [y for x, y in self.bottomlayout.values()]

        # get limits on coordinates
        xmin, xmax = min(xs), max(xs)
        ymin, ymax = min(ys), max(ys)

        # TODO: base this on heuristics eventually
        # define the width and height of the bounding boxes
        colwidth = wave.ts[-1] - wave.ts[0] - 100 # slight overlap

        uniquexs = list(set(xs))
        ncols = len(uniquexs)

        #        x           x           x
        #  -------------- ----------  -----------
        # each x should be the center of the columns
        # each column should be min(wave.ts) - max(wave.ts)
        shifted = wave.ts - numpy.asarray([min(wave.ts)] * len(wave.ts))
        self.my_xlim = (min(shifted), ncols*colwidth)
        self.my_ax.set_xlim(self.my_xlim)


        x_offsets = {}
        for i, x in enumerate(sorted(uniquexs)):
            x_offsets[x] = i * colwidth
        # For each coordinate, with the given bounding boxes defined above
        # center these boxes on the coordinates, and adjust to produce
        # percentages
        y_rows = list(set(ys))
        num_rows = len(y_rows)
        row_height = 100
        y_offsets = {}
        self.my_ax.set_ylim(-100, num_rows*row_height)
        self.my_ylim = (-100, num_rows*row_height)
        for i, y in enumerate(sorted(y_rows)):
            y_offsets[y] = i * row_height

        self.pos = {}
        for chan, coords in self.bottomlayout.iteritems():
            x, y = coords

            x_off = x_offsets[x]
            y_off = y_offsets[y]
            self.pos[chan] = (x_off, y_off)


class SortPanel(SpikePanel):
    """Sort panel. Presents a narrow temporal window of all channels
    layed out according to self.layout. Also allows overplotting and some
    user interaction"""
    def __init__(self, *args, **kwargs):
        SpikePanel.__init__(self, *args, **kwargs)
        self.spikes = {}  # (spike, colour) -> [[SpykeLine], plotted]
        #self.x_vals = None
        self._initialized = False
        self.layers = {'g' : 0.5,
                       'y' :   1,
                       'r' : 0.7 }

        self.all_chans = self.nchans * [True]

    def set_params(self):
        SingleAxesPlotPanel.set_params(self)
        self.colours = ['y'] * self.nchans

    def _notVisible(self, spike, colour):
        lines, curr_visible = self.spikes[(spike, colour)]
        for line in lines:
            line._visible = False
        self.spikes[(spike, colour)][1] = False

    def _Visible(self, spike, colour, channels):
        lines, curr_visible = self.spikes[(spike, colour)]
        for line, chan in zip(lines, channels):
            line.chan_mask = chan
            line._visible = line.chan_mask
            line.zorder = self.layers[colour]
        self.spikes[(spike, colour)][1] = True

    def add(self, spike, colour, top=False, channels=None):
        """(Over)plot a given spike"""
        colours = [colour] * self.nchans

        # initialize
        if not self._initialized:

            self.init_plot(spike, colour)

            lines = []
            for num, channel in self.channels.iteritems():
                #x_off, y_off = self.pos[channel]
                channel._visible = channels[num]
                channel.chan_mask = channels[num]
                lines.append(channel)

            self.spikes[(spike, colour)] = [lines, True]
            self._initialized = True

        elif (spike, colour) in self.spikes:
            self.my_ax._visible = False
            self._Visible(spike, colour, channels)
            self.my_ax._visible = True

        elif (spike, colour) not in self.spikes:

            if channels is None:
                channels = self.all_chans

            self.my_ax._visible = False
            lines = []
            for chan in self.channels:
                x_off, y_off = self.pos[chan]
                line = SpykeLine(self.static_x_vals + x_off,
                                 spike.data[chan] + y_off,
                                 linewidth=self.linewidth,
                                 color=colours[chan],
                                 antialiased=False)
                line._visible = False
                line.colour = colour
                line._visible = channels[chan]
                lines.append(line)
                line.zorder = self.layers[colour]
                self.my_ax.add_line(line)
            self.spikes[(spike, colour)] = [lines, True]
            self.my_ax._visible = True
        self.draw(True)

    def remove(self, spike, colour):
        """Remove the selected spike from the plot display"""
        #self._toggleVisible(spike, colour)
        self.my_ax._visible = False
        self._notVisible(spike, colour)
        #if colour in ('y'):
        #    lines, _ = self.spikes.pop((spike, colour))
        #    for line in lines:
        #        self.my_ax.lines.remove(line)
        self.my_ax._visible = True
        self.draw(True)


class ClickableSortPanel(SortPanel):
    def __init__(self, *args, **kwargs):
        SortPanel.__init__(self, *args, **kwargs)
        self.Bind(wx.EVT_LEFT_DCLICK, self.onDoubleClick, self)
        #self.Bind(wx.EVT_LEFT_DOWN, self.onClick, self)
        self.mpl_connect('button_press_event', self.onLeftDown)

        self.created = False

    def _createMaps(self):
        self.xoff = sorted(list(set([x for x, y in self.pos.itervalues()])))
        self.yoff = sorted(list(set([y for x, y in self.pos.itervalues()])))

        self.numcols = len(self.xoff)
        self.numrows = len(self.yoff)

        dist = lambda tup: (tup[1] - tup[0])
        self.x_width = dist(self.my_xlim) // self.numcols
        self.y_height = dist(self.my_ylim) // self.numrows

        self.intvalToChan = {}
        for chan, offsets in self.pos.iteritems():
            x_off, y_off = offsets
            x_intval = x_off // self.x_width
            y_intval = y_off // self.y_height
            self.intvalToChan[(x_intval, y_intval)] = chan

    def _sendEvent(self, channels):
        event = ClickedChannelEvent(myEVT_CLICKED_CHANNEL, self.GetId())
        event.selected_channels = channels
        self.GetEventHandler().ProcessEvent(event)

    def onDoubleClick(self, evt):
        channels = [True] * len(self.channels)
        self._sendEvent(channels)

    def pointToChannel(self, x, y):
        """Given a coordinate in the axes, find out what channel
        we're clicking on"""
        if not self.created:
            self._createMaps()
            self.created = True
        key = (int(x) // self.x_width, int(y) // self.y_height)
        if key in self.intvalToChan:
            return self.intvalToChan[key]
        return None

    def onLeftDown(self, event):
        # event.inaxes
        channel = self.pointToChannel(event.xdata, event.ydata)
        if channel is not None:
            channels = [False] * len(self.channels)
            channels[channel] = True
            self._sendEvent(channels)


class MultiAxesPlotPanel(FigureCanvasWxAgg):
    """Multiple axes plot panel. Base class for specific types of plot panels
    Uses multiple matplotlib axes, which is slow"""
    def __init__(self, frame, layout):
        FigureCanvasWxAgg.__init__(self, frame, -1, Figure())
        self._plot_setup = False

        self.pos = {} # position of plots
        self.channels = {} # plot y-data for each channel
        self.axes = {} # axes for each channel, chan -> axes
        self.axesToChan = {} # axes -> chan

        self.nchans = len(layout)

        # set layouts of the plot on the screen
        self.set_plot_layout(layout)
        self.set_params()

    def set_params(self):
        """ Set extra parameters. """
        self.figure.set_facecolor('black')
        self.SetBackgroundColour(wx.BLACK)
        self.yrange = (-260, 260)
        self.colours = [DEFAULTCOLOUR] * self.nchans

    def set_plot_layout(self, layout):
        """ Override in subclasses. """
        pass

    def init_plot(self, wave, colour=DEFAULTCOLOUR):
        """ Set up axes """
        # self.pos is a map from channel -> [l, b, w, h] positions for plots
        for chan, sp in self.pos.iteritems():
            a = self.figure.add_axes(sp, axisbg='b', frameon=False, alpha=1.)

            colours = [colour] * self.nchans
            # create an instance of a searchable line
            line = SpykeLine(wave.ts,
                             wave.data[chan],
                             linewidth=self.linewidth,
                             color=colours[chan],
                             antialiased=False)
            line.colour = colour

            # add line, initialize properties
            a._visible = False
            a.add_line(line)
            a.autoscale_view()
            a.set_ylim(self.yrange)
            a.grid(True)
            a.set_xticks([])
            a.set_yticks([])
            a._visible = True

            self.axes[chan] = a
            self.channels[chan] = a.get_lines()[0]

            # maintain reverse mapping of axes -> channels
            self.axesToChan[AxesWrapper(a)] = chan

        # redraw the disply
        self.draw(True)

    def plot(self, waveforms):
        """ Plot waveforms """
        # check if we've set up our axes yet
        if not self._plot_setup:
            self.init_plot(waveforms)
            self._plot_setup = True

        # update plots with new data
        for chan in self.channels:
            self.channels[chan].set_ydata(waveforms.data[chan])
            self.axes[chan].set_ylim(self.yrange)
        self.draw(True)


class MultiAxesChartPanel(MultiAxesPlotPanel):
    """Multi axes chart panel. Presents all channels layed out vertically. Slow"""

    def set_params(self):
        MultiAxesPlotPanel.set_params(self)
        colgen = itertools.cycle(iter(['b', 'g', 'm', 'c', 'y', 'r', 'w']))
        self.colours = []
        for chan in xrange(self.nchans):
            self.colours.append(colgen.next())

    def set_plot_layout(self, layout):
        """Chart panel plots are laid out vertically:

           (0,1)                                  (1,1)
              +-------------------------------------+
              |             ^
              |             | vMargin
              |             v
              |         +----------------...
              |         |
              |<------->|        center 1             =
              | vMargin |                              |
              |         +----------------...           | alpha
              |         |                              |
              |         +---- ..............overlap    |
              |         |        center 2             =
              .
              |
              +
           (0,0)
        """
        num = self.nchans

        # project coordinates onto x and y axes repsectively
        xcoords = [x for x, y in layout.itervalues()]
        ycoords = [y for x, y in layout.itervalues()]

        # get limits on coordinates
        xmin, xmax = min(xcoords), max(xcoords)
        ymin, ymax = min(ycoords), max(ycoords)

        # XXX: some magic numbers that should be tweaked as desired
        hMargin = 0.05
        vMargin = 0.03

        box_height = 0.1

        # total amout of vertical buffer space (that is, vertical margins)
        vBuf = 2 * vMargin + box_height / 2 # XXX - heuristic/hack
        alpha = (1 - vBuf) / (num - 1)      # distance between centers
        width = 1 - 2 * hMargin

        # the first channel starts at the top
        center = 1 - vMargin - box_height / 4
        for chan, coords in layout.iteritems():
            bot = center - box_height / 2
            self.pos[chan] = [hMargin, bot, width, box_height]
            center -= alpha


class MultiAxesSpikePanel(MultiAxesPlotPanel):
    """Multiple axes spike panel. Presents a narrow temporal window of all channels
    layed out according to self.layout. Slow"""

    def set_params(self):
        MultiAxesPlotPanel.set_params(self)
        self.colours = [DEFAULTCOLOUR] * self.nchans

    def set_plot_layout(self, layout):
        """Map from polytrode locations given as (x, y) coordinates
        into position information for the spike plots, which are stored
        as a list of four values [l, b, w, h]. To illustrate this, consider
        loc_i = (x, y) are the coordinates for the polytrode on channel i.
        We want to map these coordinates to the unit square.
           (0,1)                          (1,1)
              +------------------------------+
              |        +--(w)--+
              |<-(l)-> |       |
              |        |  x,y (h)
              |        |       |
              |        +-------+
              |            ^
              |            | (b)
              |            v
              +------------------------------+
             (0,0)                          (0,1)
        """
        # project coordinates onto x and y axes repsectively
        xcoords = [x for x, y in layout.itervalues()]
        ycoords = [y for x, y in layout.itervalues()]

        # get limits on coordinates
        xmin, xmax = min(xcoords), max(xcoords)
        ymin, ymax = min(ycoords), max(ycoords)

        # base this on heuristics eventually XXX
        # define the width and height of the bounding boxes
        bh = 130
        bw = 75

        # Each plot chan is contained within a bounding box which
        # will necessarily overlap (necassarily because we want the plots
        # to overplot each other to maximize screen usage and to help
        # us indicate the firing of events. Bounding boxes will be centered
        # at the coordinates passed in the layout. Here we want to calculate
        # the lengths of this bounding box *relative to the layout coordinate
        # system*
        bound_xmin = xmin - bw / 2.
        bound_xmax = xmax + bw / 2.
        bound_ymin = ymin - bh / 2.
        bound_ymax = ymax + bh / 2.

        bound_width = bound_xmax - bound_xmin
        bound_height = bound_ymax - bound_ymin

        # For each coordinate, with the given bounding boxes defined above
        # center these boxes on the coordinates, and adjust to produce
        # percentages
        self.pos = {}
        for chan, coords in layout.iteritems():
            x, y = coords
            l = abs(bound_xmin - (x - bw / 2.)) / bound_width
            b = abs(bound_ymin - (y - bh / 2.)) / bound_height
            w = bw / bound_width
            h = bh / bound_height
            self.pos[chan] = [l, b, w, h]


class MultiAxesSortPanel(MultiAxesSpikePanel):
    """Multiple axes sort panel. Presents a narrow temporal window of all channels
    layed out according to self.layout. Also allows overplotting and some
    user interaction. Slow"""
    def __init__(self, *args, **kwargs):
        MultiAxesSpikePanel.__init__(self, *args, **kwargs)
        self.spikes = {}  # (spike, colour) -> [[SpykeLine], visible]
        self.x_vals = None
        self._initialized = False
        self.layers = {'g' : 0.5,
                       'y' :   1,
                       'r' : 0.7 }

    def set_params(self):
        MultiAxesPlotPanel.set_params(self)
        self.colours = [DEFAULTCOLOUR] * self.nchans

    def _toggleVisible(self, spike, colour, top=None):
        lines, curr_visible = self.spikes[(spike, colour)]
        curr_visible = not curr_visible

        for line in lines:
            line._visible = curr_visible
            line.zorder = self.self.layers[colour]

        self.spikes[(spike, colour)][1] = curr_visible

    def _toggleChannels(self, spike, colour, channels):
        lines, curr_visible = self.spikes[(spike, colour)]
        for line, isVisible in zip(lines, channels):
            line._visible = isVisible
            line.zorder = self.top

    def add(self, spike, colour, top=False, channels=None):
        """ (Over)plot a given spike. """
        colours = [colour] * self.nchans

        if not channels:
            channels = self.nchans * [True]

        # initialize
        if not self._initialized:

            self.init_plot(spike, colour)

            # always plot w.r.t. these x points
            self.x_vals = spike.ts

            lines = []
            for num, channel in self.channels.iteritems():
                lines.append(channel)
            self.spikes[(spike, colour)] = [lines, True]
            self._initialized = True

        elif (spike, colour) in self.spikes:
            self._toggleVisible(spike, colour, top)
            self._toggleChannels(spike, colour, channels)

        elif (spike, colour) not in self.spikes:
            lines = []
            for chan, axes in self.axes.iteritems():
                line = SpykeLine(self.x_vals,
                                 spike.data[chan],
                                 linewidth=self.linewidth,
                                 color=colours[chan],
                                 antialiased=False)
                line._visible = False
                line.colour = colour
                axes.add_line(line)
                axes.autoscale_view()
                axes.set_ylim(self.yrange)
                line._visible = True
                lines.append(line)
            self.spikes[(spike, colour)] = [lines, True]

        self.draw(True)

    def remove(self, spike, colour):
        """Remove the selected spike from the plot display"""
        self._toggleVisible(spike, colour)
        self.draw(True)



######## Tests #########



class Opener(object):
    """Opens and parses the first available file in filenames"""
    FILENAMES = ['/data/ptc15/87 - track 7c spontaneous craziness.srf',
                 '/Documents and Settings/Reza Lotun/Desktop/Surfdata/87 - track 7c spontaneous craziness.srf',
                 '/media/windows/Documents and Settings/Reza ' \
                            'Lotun/Desktop/Surfdata/' \
                            '87 - track 7c spontaneous craziness.srf',
                 '/home/rlotun/data_spyke/'\
                            '87 - track 7c spontaneous craziness.srf',
                 '/data/87 - track 7c spontaneous craziness.srf',
                 '/Users/rlotun/work/spyke/data/smallSurf',
                 '/home/rlotun/spyke/data/smallSurf',
                ]

    def __init__(self):

        import spyke.detect
        import os

        for filename in self.FILENAMES:
            try:
                stat = os.stat(filename)
                break
            except:
                continue

        surf_file = surf.File(filename)
        self.surf_file = surf_file
        surf_file.parse()
        self.dstream = spyke.core.Stream(surf_file.highpassrecords)
        layout_name = surf_file.layoutrecords[0].electrode_name
        layout_name = layout_name.replace('\xb5', 'u') # replace 'micro' symbol with 'u'
        import spyke.probes
        self.layout = eval('spyke.probes.' + layout_name)() # yucky, UNTESTED
        self.curr = self.dstream.records[0].TimeStamp


class TestWindows(wx.App):
    def __init__(self, *args, **kwargs):
        kwargs['redirect'] = False
        wx.App.__init__(self, *args, **kwargs)

    def OnInit(self):
        op = Opener()
        self.events = panel = TestEventWin(None, -1, 'Data', op, size=(200,900))
        self.sort = panel3 = TestSortWin(None, -1, 'Events', op, size=(200,900))
        self.chart = panel4 = TestChartWin(None, -1, 'Chart', op, size=(500,600))
        self.SetTopWindow(self.events)
        self.events.Show(True)
        self.sort.Show(True)
        self.chart.Show(True)
        return True


class PlayWin(wx.Frame):
    def __init__(self, parent, id, title, op, **kwds):
        wx.Frame.__init__(self, parent, id, title, **kwds)
        self.stream = op.dstream
        self.layout = op.layout
        self.incr = 1000        # 1 ms
        self.timer = wx.Timer(self)
        self.Bind(wx.EVT_TIMER, self.onTimerEvent, self.timer)

    def onTimerEvent(self, evt):
        pass

    def onEraseBackground(self, evt):
        """Prevent redraw flicker"""
        pass


class TestSortWin(PlayWin):
    """Reference implementation of a test Sort Window. An SpikePanel
    is simply embedded in a wx Frame, and a passed in data file is played"""
    def __init__(self, parent, id, title, op, **kwds):
        PlayWin.__init__(self, parent, id, title, op, **kwds)

        self.incr = 1000
        simp = spyke.detect.SimpleThreshold(self.stream,
                                            self.stream.records[0].TimeStamp)

        self.event_iter = iter(simp)

        #self.plotPanel = MultiAxesSortPanel(self, self.layout.SiteLoc) # slow
        self.plotPanel = SortPanel(self, self.layout.SiteLoc) # fast

        self.borderAxes = None

        self.timer.Start(200)

    def onTimerEvent(self, evt):
        waveforms = self.event_iter.next()
        self.plotPanel.plot(waveforms)


class TestSpikeWin(PlayWin):
    def __init__(self, parent, id, title, op, **kwds):
        PlayWin.__init__(self, parent, id, title, op, **kwds)

        #self.plotPanel = MultiAxesSpikePanel(self, self.layout.SiteLoc) # slow
        self.plotPanel = SpikePanel(self, self.layout.SiteLoc) # fast

        self.data = None
        self.points = []
        self.selectionPoints = []
        self.borderAxes = None
        self.curr = op.curr
        self.timer.Start(200)

    def onTimerEvent(self, evt):
        waveforms = self.stream[self.curr:self.curr+self.incr]
        self.curr += self.incr
        self.plotPanel.plot(waveforms)


class TestChartWin(PlayWin):
    def __init__(self, parent, id, title, op, **kwds):
        PlayWin.__init__(self, parent, id, title, op, **kwds)

        #self.plotPanel = MultiAxesChartPanel(self, self.layout.SiteLoc) # slow
        self.plotPanel = ChartPanel(self, self.layout.SiteLoc)

        self.data = None
        self.points = []
        self.selectionPoints = []
        self.borderAxes = None
        self.curr = op.curr
        self.incr = 5000
        self.timer.Start(100)

    def onTimerEvent(self, evt):
        waveforms = self.stream[self.curr:self.curr+self.incr]
        self.curr += self.incr
        self.plotPanel.plot(waveforms)


if __name__ == '__main__':
    app = TestWindows()
    app.MainLoop()
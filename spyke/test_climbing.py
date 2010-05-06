import numpy as np
import pyximport
pyximport.install(setup_args={'include_dirs':[np.get_include()]})

from climbing import climb # .pyx file

from pylab import figure, gca, scatter, show
import scipy.io
import wx
import time


def makefigure():
    f = figure()
    f.subplots_adjust(0, 0, 1, 1)
    f.canvas.SetBackgroundColour(wx.BLACK)
    f.set_facecolor('black')
    f.set_edgecolor('black')
    a = gca()
    a.set_axis_bgcolor('black')
    return f


RED = '#FF0000'
ORANGE = '#FF7F00'
YELLOW = '#FFFF00'
GREEN = '#00FF00'
CYAN = '#00FFFF'
LIGHTBLUE = '#007FFF'
BLUE = '#0000FF'
VIOLET = '#7F00FF'
MAGENTA = '#FF00FF'
WHITE = '#FFFFFF'
BROWN = '#AF5050'
GREY = '#555555' # reserve as junk cluster colour

COLOURS = np.asarray([RED, ORANGE, YELLOW, GREEN, CYAN, LIGHTBLUE, VIOLET, MAGENTA, WHITE, BROWN])

'''
data = scipy.io.loadmat('/data/ptc18/tr1/14-tr1-mseq32_40ms_7deg/14_full.mat')
data = data['data']
data = np.float32(data)
'''
data = np.load('/data/ptc18/tr1/14-tr1-mseq32_40ms_7deg/14_full_x0_y0_t_Vpp.npy')
data = data[:, :3] # limit npoints and ndims
nd = data.shape[1]
xstd = data[:, 0].std()
# normalize x and y by xstd
for dim in data.T[:2]: # iter over columns:
    dim -= dim.mean()
    dim /= xstd
# normalize all other dims by their std
for dim in data.T[2:]: # iter over columns:
    dim -= dim.mean()
    dim /= dim.std()

t0 = time.clock()
clusteris, clusters = climb(data, sigma=0.4, alpha=1.0)
print('climb took %.3f sec' % (time.clock()-t0))

nclusters = len(clusters)

ncolours = len(COLOURS)
samplecolours = COLOURS[clusteris % ncolours]
clustercolours = COLOURS[np.arange(nclusters) % ncolours]
#colours[clusteris == -1] = GREY # unclassified points

# plot x vs y
f = makefigure()
scatter(data[:, 0], data[:, 1], s=1, c=samplecolours, edgecolors='none')
scatter(clusters[:, 0], clusters[:, 1], c=clustercolours)

# plot t vs y
f = makefigure()
scatter(data[:, 2], data[:, 1], s=1, c=samplecolours, edgecolors='none')
scatter(clusters[:, 2], clusters[:, 1], c=clustercolours)

show()
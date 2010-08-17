"""Spike parameter extraction"""

from __future__ import division

__authors__ = ['Martin Spacek']

import time
import multiprocessing as mp

import numpy as np
np.seterr(under='warn') # don't halt on underflow during gaussian_fit
from scipy.optimize import leastsq
from scipy.interpolate import UnivariateSpline
import pywt
import scipy.stats

import pylab as pl

from spyke.core import g, g2


DEFSX = 50 # default spatial decay along x axis, in um
DEFSY = 50


def callspike2XY(args):
    spike, wavedata = args
    ext = mp.current_process().extractor
    det = mp.current_process().detector
    return ext.spike2XY(spike, wavedata, det)

def initializer(extractor, detector):
    #stream.srff.open() # reopen the .srf file which was closed for pickling, engage file lock
    #detector.sort.stream = stream
    #detector.sort.stream.srff = srff # restore .srff that was deleted from stream on pickling
    mp.current_process().extractor = extractor
    mp.current_process().detector = detector


class SpatialLeastSquares(object):
    """Least squares Levenberg-Marquardt spatial gaussian fit of decay across chans"""
    def __init__(self, debug=False):
        self.A = None
        self.sx = DEFSX
        self.sy = DEFSY
        self.x0 = None
        self.y0 = None
        # TODO: mess with fixed sx and sy to find most clusterable vals, test on
        # 3 column data too
        self.debug = debug

    def calc_x0y0(self, x, y, V):
        t0 = time.clock()
        try: result = leastsq(self.cost_x0y0, self.p0, args=(x, y, V), full_output=True, ftol=1e-3)
                         #Dfun=None, full_output=True, col_deriv=False,
                         #maxfev=50, xtol=0.0001,
                         #diag=None)
        except Exception as err:
            print(err)
            import pdb; pdb.set_trace()
        self.p, self.cov_p, self.infodict, self.mesg, self.ier = result
        self.x0, self.y0 = self.p
        if self.debug:
            print('iters took %.3f sec' % (time.clock()-t0))
            print('p0 = %r' % self.p0)
            print('p = %r' % self.p)
            print('%d iterations' % self.infodict['nfev'])
            print('mesg=%r, ier=%r' % (self.mesg, self.ier))

    def calc_s(self, x, y, V):
        t0 = time.clock()
        try: result = leastsq(self.cost_s, self.p0, args=(x, y, V), full_output=True, ftol=1e-3)
                         #Dfun=None, full_output=True, col_deriv=False,
                         #maxfev=50, xtol=0.0001,
                         #diag=None)
        except Exception as err:
            print(err)
            import pdb; pdb.set_trace()
        self.p, self.cov_p, self.infodict, self.mesg, self.ier = result
        s, = abs(self.p) # keep sigma +ve
        self.sx, self.sy = s, s
        if self.debug:
            print('iters took %.3f sec' % (time.clock()-t0))
            print('p0 = %r' % self.p0)
            print('p = %r' % self.p)
            print('%d iterations' % self.infodict['nfev'])
            print('mesg=%r, ier=%r' % (self.mesg, self.ier))

    def calc_sxsy(self, x, y, V):
        t0 = time.clock()
        try: result = leastsq(self.cost_sxsy, self.p0, args=(x, y, V), full_output=True, ftol=1e-3)
                         #Dfun=None, full_output=True, col_deriv=False,
                         #maxfev=50, xtol=0.0001,
                         #diag=None)
        except Exception as err:
            print(err)
            import pdb; pdb.set_trace()
        self.p, self.cov_p, self.infodict, self.mesg, self.ier = result
        self.sx, self.sy = abs(self.p) # keep sigmas +ve
        if self.debug:
            print('iters took %.3f sec' % (time.clock()-t0))
            print('p0 = %r' % self.p0)
            print('p = %r' % self.p)
            print('%d iterations' % self.infodict['nfev'])
            print('mesg=%r, ier=%r' % (self.mesg, self.ier))

    def cost_x0y0(self, p, x, y, V):
        """Distance of each point to the model function"""
        return self.model_x0y0(p, x, y) - V

    def cost_s(self, p, x, y, V):
        """Distance of each point to the model function"""
        return self.model_s(p, x, y) - V

    def cost_sxsy(self, p, x, y, V):
        """Distance of each point to the model function"""
        return self.model_sxsy(p, x, y) - V

    def model_x0y0(self, p, x, y):
        """2D elliptical Gaussian, with x0 and y0 free"""
        x0, y0 = p
        return self.A * g2(x0, y0, self.sx, self.sy, x, y)

    def model_s(self, p, x, y):
        """2D elliptical Gaussian, with s (sx == sy) free"""
        s, = p
        return self.A * g2(self.x0, self.y0, s, s, x, y)

    def model_sxsy(self, p, x, y):
        """2D elliptical Gaussian, with sx and sy free"""
        sx, sy = p
        return self.A * g2(self.x0, self.y0, sx, sy, x, y)

    def staticmodel(self, x, y):
        return self.A * g2(self.x0, self.y0, self.sx, self.sy, x, y)

    def plot(self, x, y, w, spike):
        from mpl_toolkits.mplot3d import Axes3D
        from matplotlib import cm
        f = pl.figure()
        a = Axes3D(f)
        model = self.staticmodel(x, y)
        a.scatter(x, y, w, c='k') # actual
        a.scatter(x, y, model, c='r') # modelled
        #X, Y = np.meshgrid(x, y)
        #a.plot_surface(X, Y, self.staticmodel(X, Y), color=(0.2, 0.2, 0.2, 0.5))
        X = np.arange(x.min(), x.max(), 5)
        Y = np.arange(y.min(), y.max(), 5)
        X, Y = np.meshgrid(X, Y)
        a.plot_surface(X, Y, self.staticmodel(X, Y), rstride=1, cstride=1, cmap=cm.jet)
        a.set_xlabel('x')
        a.set_ylabel('y')
        a.set_zlabel('V')
        err = np.sum(np.square(model - w))
        a.set_title('sum squared error: %.1f' % err)
        f.canvas.Parent.SetTitle('spike %d' % spike['id'])


class TemporalLeastSquares(object):
    """Least squares Levenberg-Marquardt temporal 2 gaussian fit of
    spike shape on a single channel"""
    def __init__(self, debug=False):
        #self.V0 = None
        #self.V1 = None
        self.t0 = None
        self.t1 = None
        self.debug = debug

    def calc(self, ts, V):
        t0 = time.clock()
        try: result = leastsq(self.cost, self.p0, args=(ts, V), full_output=True, ftol=1e-3)
                         #Dfun=None, full_output=True, col_deriv=False,
                         #maxfev=50, xtol=0.0001,
                         #diag=None)
        except Exception as err:
            print(err)
            import pdb; pdb.set_trace()
        self.p, self.cov_p, self.infodict, self.mesg, self.ier = result
        if self.debug:
            print('iters took %.3f sec' % (time.clock()-t0))
            print('p0 = %r' % self.p0)
            print('p = %r' % self.p)
            print('%d iterations' % self.infodict['nfev'])
            print('mesg=%r, ier=%r' % (self.mesg, self.ier))

    def model(self, p, ts):
        """Temporal sum of Gaussians"""
        #try:
        V0, V1, s0, s1, Voff = p
        return V0*g(self.t0, s0, ts) + V1*g(self.t1, s1, ts) + Voff
        #except Exception as err:
        #    print(err)
        #    import pdb; pdb.set_trace()

    def cost(self, p, ts, V):
        """Distance of each point to the model function"""
        return self.model(p, ts) - V


class Extractor(object):
    """Spike extractor base class"""
    #DEFXYMETHOD = 'spatial mean'
    def __init__(self, sort, XYmethod):
        """Takes a parent Sort session and sets various parameters"""
        self.debug = False
        self.sort = sort
        self.XYmethod = XYmethod # or DEFXYMETHOD
        self.choose_XY_fun()
        self.sls = SpatialLeastSquares(self.debug)
        self.tls = TemporalLeastSquares(self.debug)
        #self.ksis = [41, 11, 39, 40, 20] # best wave coeffs according kstest of wavedec of full ptc18.14 sort, using Haar wavelets

    def choose_XY_fun(self):
        if self.XYmethod.lower() == 'gaussian fit':
            self.weights2spatial = self.weights2gaussian
        elif self.XYmethod.lower() == 'spatial mean':
            self.weights2spatial = self.weights2spatialmean
        elif self.XYmethod.lower() == 'splines 1d fit':
            self.weights2spatial = self.weights2splines
        else:
            raise ValueError("Unknown XY parameter extraction method %r" % self.XYmethod)

    def __getstate__(self):
        d = self.__dict__.copy() # copy it cuz we'll be making changes
        del d['weights2spatial'] # can't pickle an instance method, not sure why it even bothers trying
        return d

    def __setstate__(self, d):
        self.__dict__ = d
        self.choose_XY_fun() # restore instance method
    '''
    def extract_ICA(self):
        """This is just roughed in for now, had it in the extract_all_XY
        spike loop before"""
        ICs = np.matrix(np.load('ptc15.87.2000_waveform_ICs.npy'))
        invICs = ICs.I # not a square matrix, think it must do pseudoinverse

        for sid in xrange(nspikes):
            maxchanwavedata = wavedata[maxchani]
            # TODO: maybe normalize amplitude of spike to match that of the ICs (maybe keep everything normalized to 1). That way, You're really just looking at spike shape, and not allowing amplitude to add to the variability. Amplitude can remain a clusterable parameter via Vp or Vpp.
            weights = maxchanwavedata * invICs # weights of ICs for this spike's maxchan waveform
            spikes['IC0'][sid] = weights[0, 0]
            spikes['IC1'][sid] = weights[0, 1]
    '''
    def extract_all_wcs(self, wavelet='haar'):
        """Extract wavelet coefficients from all spikes, store them as spike attribs"""
        # TODO: add multiprocessing
        nkeep = 5 # num of top wavelet coeffs to keep
        sort = self.sort
        spikes = sort.spikes # struct array
        wavedata = sort.wavedata
        nspikes = len(spikes)
        #ncoeffs = 53 # TODO: this only applies for V of length 50, stop hardcoding
        #ncoeffs = len(self.ksis)
        nt = wavedata.shape[2]
        ncoeffs = len(np.concatenate(pywt.wavedec(wavedata[0, 0], wavelet)))
        wcs = np.zeros((nspikes, ncoeffs))
        t0 = time.time()
        for spike, wd in zip(spikes, wavedata):
            nchans = spike['nchans']
            chans = spike['chans'][:nchans]
            maxchan = spike['chan']
            maxchani = int(np.where(chans == maxchan)[0])
            #chanis = det.chans.searchsorted(chans) # det.chans are always sorted
            #wd = wd[:nchans] # unnecessary?
            V = wd[maxchani]
            wcs[spike['id']] = np.concatenate(pywt.wavedec(V, wavelet)) # flat array of wavelet coeffs
            #wcs[spike['id']] = np.concatenate(pywt.wavedec(V, wavelet))[self.ksis]
            #wcs[spike['id']] = self.wavedata2wcs(wd, maxchani)
        ks = np.zeros(ncoeffs)
        p = np.zeros(ncoeffs)
        for i in range(ncoeffs):
            ks[i], p[i] = scipy.stats.kstest(wcs[:, i], 'norm')
        ksis = ks.argsort()[::-1] # ks indices sorted from biggest to smallest ks values
        # assign as params in spikes struct array
        for coeffi in range(nkeep): # assign first nkeep
            spikes['w%d' % coeffi] = wcs[:, ksis[coeffi]]
        print("Extracting wavelet coefficients from all %d spikes took %.3f sec" %
             (nspikes, time.time()-t0))
        return wcs, ks, ksis, p

    def extract_all_wcs_by_maxchan(self, wavelet='haar'):
        """Extract wavelet coefficients from all spikes, store them as spike attribs.
        Find optimum coeffs for each chan, then average across all chans to find
        globally optimum coeffs"""
        # TODO: add multiprocessing
        nkeep = 5 # num of top wavelet coeffs to keep
        sort = self.sort
        spikes = sort.spikes # struct array
        wavedata = sort.wavedata
        nspikes = len(spikes)
        #ncoeffs = 53 # TODO: this only applies for V of length 50, stop hardcoding
        #ncoeffs = len(self.ksis)
        nt = wavedata.shape[2]
        ncoeffs = len(np.concatenate(pywt.wavedec(wavedata[0, 0], wavelet)))

        wcs = {}
        maxchans = np.unique(spikes['chan'])
        nmaxchans = len(maxchans)
        for maxchan in maxchans:
            wcs[maxchan] = [] # init dict of lists, indexed by spike maxchan
        flatwcs = np.zeros((nspikes, ncoeffs))

        t0 = time.time()
        for spike, wd in zip(spikes, wavedata):
            nchans = spike['nchans']
            chans = spike['chans'][:nchans]
            maxchan = spike['chan']
            maxchani = int(np.where(chans == maxchan)[0])
            #chanis = det.chans.searchsorted(chans) # det.chans are always sorted
            #wd = wd[:nchans] # unnecessary?
            V = wd[maxchani]
            coeffs = np.concatenate(pywt.wavedec(V, wavelet)) # flat array of wavelet coeffs
            wcs[maxchan].append(coeffs)
            flatwcs[spike['id']] = coeffs
        ks = np.zeros((nmaxchans, ncoeffs))
        p = np.zeros((nmaxchans, ncoeffs))
        for maxchani, maxchan in enumerate(maxchans):
            wcs[maxchan] = np.asarray(wcs[maxchan])
            for i in range(ncoeffs):
                ks[maxchani, i], p[maxchani, i] = scipy.stats.kstest(wcs[maxchan][:, i], 'norm')
        # TODO: weight the KS value from each maxchan according to the nspikes for that maxchan!!!!!
        ks = ks.mean(axis=0)
        p = p.mean(axis=0)
        ksis = ks.argsort()[::-1] # ks indices sorted from biggest to smallest ks values
        # assign as params in spikes struct array
        for coeffi in range(nkeep): # assign first nkeep
            spikes['w%d' % coeffi] = flatwcs[:, ksis[coeffi]]
        print("Extracting wavelet coefficients from all %d spikes took %.3f sec" %
             (nspikes, time.time()-t0))
        return wcs, flatwcs, ks, ksis, p
    '''
    def wavedata2wcs(self, wavedata, maxchani, wavelet):
        """Return wavelet coeffs specified by self.ksis, given wavedata
        with a maxchani"""
        V = wavedata[maxchani]
        return np.concatenate(pywt.wavedec(V, wavelet))[self.ksis]
    '''
    def extract_all_temporal(self):
        """Extract temporal parameters by modelling maxchan spike shape
        as sum of 2 Gaussians"""
        sort = self.sort
        AD2uV = sort.converter.AD2uV
        spikes = sort.spikes # struct array
        nspikes = len(spikes)
        if nspikes == 0:
            raise RuntimeError("No spikes to extract temporal parameters from")
        try:
            wavedata = sort.wavedata
        except AttributeError:
            raise RuntimeError("Sort has no saved wavedata in memory to extract parameters from")
        print("Extracting temporal parameters from spikes")
        tstart = time.time()
        '''
        if not self.debug: # use multiprocessing
            assert len(sort.detections) == 1
            det = sort.detector
            ncpus = min(mp.cpu_count(), 4) # 1 per core, max of 4, ie don't allow 8 "cores"
            pool = mp.Pool(ncpus, initializer, (self, det)) # sends pickled copies to each process
            args = zip(spikeslist, wavedata)
            results = pool.map(callspike2XY, args) # using chunksize=1 is a bit slower
            print('done with pool.map()')
            pool.close()
            # results is a list of (x0, y0) tuples, and needs to be unzipped
            spikes['x0'], spikes['y0'] = zip(*results)
        else:
            # give each process a detector, then pass one spike record and one waveform to
            # each this assumes all spikes come from the same detector with the same
            # siteloc and chans, which is safe to assume anyway
            initializer(self, sort.detector)

            for spike, wd in zip(spikes, wavedata):
                x0, y0 = callspike2XY((spike, wd))
                spike['x0'] = x0
                spike['y0'] = y0
        '''
        for spike in spikes:
            V0, V1, s0, s1, Voff = self.spike2temporal(spike)
            spike['s0'], spike['s1'] = abs(s0), abs(s1)
            #spike['mVpp'] = AD2uV(V1 - V0)
            #spike['mV0'], spike['mV1'] = AD2uV([V0, V1])
            #spike['mdphase'] = t1 - t0

        print("Extracting temporal parameters from all %d spikes took %.3f sec" %
             (nspikes, time.time()-tstart))

    def spike2temporal(self, spike, plot=False):
        """Extract temporal Gaussian params from spike record"""
        nchans = spike['nchans']
        chans = spike['chans'][:nchans]
        maxchan = spike['chan']
        maxchani = int(np.where(chans == maxchan)[0])
        sid = spike['id']
        V = self.sort.wavedata[sid, maxchani]
        # get timestamps relative to start of waveform
        ts = np.arange(0, spike['tend'] - spike['t0'], self.sort.tres)
        t0, t1 = ts[[spike['phaset0i'], spike['phaset1i']]]
        V0, V1 = spike['V0'], spike['V1']
        tls = self.tls
        tls.t0, tls.t1 = t0, t1
        #tls.V0, tls.V1 = V0, V1
        s0, s1 = 60, 60
        Voff = 0
        #tls.V = V
        #tls.ts = ts
        tls.p0 = V0, V1, s0, s1, Voff
        tls.calc(ts, V)
        if plot:
            f = pl.figure()
            pl.plot(V)
            pl.plot(tls.model(tls.p, ts))
            f.canvas.Parent.SetTitle('spike %d' % sid)
        return tls.p

    def spike2xyw(self, spike):
        """Return x and y coords of spike's chans, plus the weights of its signal
        at those coords, and A and p0 initial values from the data"""
        nchans = spike['nchans']
        chans = spike['chans'][:nchans]
        maxchan = spike['chan']
        maxchani = int(np.where(chans == maxchan)[0])
        det = self.sort.detector
        chanis = det.chans.searchsorted(chans) # det.chans are always sorted
        sid = spike['id']
        wavedata = self.sort.wavedata[sid, :nchans] # chans in wavedata are sorted
        phasetis = spike['phaset0i'], spike['phaset1i']
        aligni = spike['aligni']
        x = det.siteloc[chanis, 0] # 1D array (row)
        y = det.siteloc[chanis, 1]

        w = self.get_Vpp_weights(wavedata, maxchani, phasetis, aligni)
        A = w[maxchani]
        x0, y0 = self.weights2spatialmean(w, x, y, maxchani)
        # or, init with just the coordinates of the max weight, doesn't save time
        #x0, y0 = x[maxchani], y[maxchani]
        #p0 = np.array([x0, y0])
        #p0 = np.array([x[maxchani], y[maxchani]])
        return x, y, w, A, x0, y0

    def spike2spatial(self, spike):
        """A convenient way of plotting spatial fits, one spike at a time.
        Fits location first, followed by spread, using a global constant intial guess for spread"""
        x, y, w, A, x0, y0 = self.spike2xyw(spike)
        sls = self.sls
        sls.A, sls.x0, sls.y0, sls.sx, sls.sy = A, x0, y0, DEFSX, DEFSY
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.p0 = np.array([x0, y0])
        sls.calc_x0y0(x, y, w) # x0 and y0 free
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.p0 = np.array([sls.sx, sls.sy])
        sls.calc_sxsy(x, y, w) # sx and sy free
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.plot(x, y, w, spike)

    def spike2spatial2(self, spike):
        """A convenient way of plotting spatial fits, one spike at a time.
        Fits spread first, followed by location, using spatialmean as intial guess for location"""
        x, y, w, A, x0, y0 = self.spike2xyw(spike)
        sls = self.sls
        sls.A, sls.x0, sls.y0, sls.sx, sls.sy = A, x0, y0, DEFSX, DEFSY
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.p0 = np.array([sls.sx, sls.sy])
        sls.calc_sxsy(x, y, w) # sx and sy free
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.p0 = np.array([sls.x0, sls.y0])
        sls.calc_x0y0(x, y, w) # x0 and y0 free
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.plot(x, y, w, spike)

    def spike2spatial3(self, spike):
        """A convenient way of plotting spatial fits, one spike at a time.
        Fits spread first using just a single sigma, followed by location,
        using spatialmean as intial guess for location"""
        x, y, w, A, x0, y0 = self.spike2xyw(spike)
        sls = self.sls
        sls.A, sls.x0, sls.y0, sls.sx, sls.sy = A, x0, y0, DEFSX, DEFSX
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.p0 = np.array([sls.sx])
        sls.calc_s(x, y, w) # s free (sx == sy)
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.p0 = np.array([sls.x0, sls.y0])
        sls.calc_x0y0(x, y, w) # x0 and y0 free
        print('A:%.1f, x0:%.1f, y0:%.1f, sx:%.1f, sy:%.1f' % (sls.A, sls.x0, sls.y0, sls.sx, sls.sy))
        sls.plot(x, y, w, spike)

    def extract_all_XY(self):
        """Extract XY parameters from all spikes, store them as spike attribs"""
        sort = self.sort
        spikes = sort.spikes # struct array
        # hack to get around numpy bug, see http://projects.scipy.org/numpy/ticket/1415:
        spikeslist = map(np.asarray, spikes)
        nspikes = len(spikes)
        if nspikes == 0:
            raise RuntimeError("No spikes to extract XY parameters from")
        try:
            wavedata = sort.wavedata
        except AttributeError:
            raise RuntimeError("Sort has no saved wavedata in memory to extract parameters from")
        print("Extracting XY parameters from spikes")
        t0 = time.time()
        if not self.debug: # use multiprocessing
            assert len(sort.detections) == 1
            det = sort.detector
            ncpus = min(mp.cpu_count(), 4) # 1 per core, max of 4, ie don't allow 8 "cores"
            pool = mp.Pool(ncpus, initializer, (self, det)) # sends pickled copies to each process
            args = zip(spikeslist, wavedata)
            results = pool.map(callspike2XY, args) # using chunksize=1 is a bit slower
            print('done with pool.map()')
            pool.close()
            # results is a list of (x0, y0, sx, sy) tuples, and needs to be unzipped
            spikes['x0'], spikes['y0'], spikes['sx'], spikes['sy'] = zip(*results)
        else:
            # give each process a detector, then pass one spike record and one waveform to
            # each this assumes all spikes come from the same detector with the same
            # siteloc and chans, which is safe to assume anyway
            initializer(self, sort.detector)
            for spike, wd in zip(spikes, wavedata):
                x0, y0 = callspike2XY((spike, wd))
                spike['x0'] = x0
                spike['y0'] = y0
        print("Extracting XY parameters from all %d spikes using %r took %.3f sec" %
             (nspikes, self.XYmethod.lower(), time.time()-t0))

    def spike2XY(self, spike, wavedata, det):
        if self.debug or spike['id'] % 1000 == 0:
            print('%s: spike id: %d' % (mp.current_process().name, spike['id']))
        nchans = spike['nchans']
        chans = spike['chans'][:nchans]
        maxchan = spike['chan']
        maxchani = int(np.where(chans == maxchan)[0])
        chanis = det.chans.searchsorted(chans) # det.chans are always sorted
        wavedata = wavedata[:nchans]
        ''' # comment out ICA stuff
        maxchanwavedata = wavedata[maxchani]
        weights = maxchanwavedata * invICs # weights of ICs for this spike's maxchan waveform
        spikes['IC1'][sid] = weights[0, 0]
        spikes['IC2'][sid] = weights[0, 1]
        '''
        phasetis = spike['phaset0i'], spike['phaset1i']
        aligni = spike['aligni']
        x = det.siteloc[chanis, 0] # 1D array (row)
        y = det.siteloc[chanis, 1]
        # just x and y params for now
        return self.wavedata2spatial(wavedata, maxchani, phasetis, aligni, x, y)

    def wavedata2spatial(self, wavedata, maxchani, phasetis, aligni, x, y):
        """Convert wavedata to per-channel weights. Vpp weights seem more clusterable
        than Vp weights.
        TODO: consider using some feature other than Vp or Vpp, like a wavelet,
        for extracting weights across chans
        """
        weights = self.get_Vpp_weights(wavedata, maxchani, phasetis, aligni)
        #weights = self.get_Vp_weights(wavedata, maxchani, phasetis, aligni)
        return self.weights2spatial(weights, x, y, maxchani)

    def get_Vp_weights(self, wavedata, maxchani, phasetis, aligni):
        """Using just Vp instead of Vpp doesn't seem to improve clusterability"""
        dti = max((phasetis[1]-phasetis[0]) // 2, 1) # varies from spike to spike
        phaseti = phasetis[aligni]
        V = wavedata[maxchani, phaseti]
        window = wavedata[:, max(phaseti-dti,0):phaseti+dti]
        if V < 0:
            weights = np.float32(window.min(axis=1))
            weights = np.fmin(weights, 0) # clip any +ve values to 0
        else: # V >= 0
            weights = np.float32(window.max(axis=1))
            weights = np.fmax(weights, 0) # clip any -ve values to 0
        return weights

    def get_Vpp_weights(self, wavedata, maxchani, phasetis, aligni=None):
        """NOTE: you get better clustering if you allow phasetis to
        vary at least slightly for each chan, since they're never simultaneous across
        chans, and sometimes they're very delayed or advanced in time
        NOTE: sometimes neighbouring chans have inverted polarity, see ptc15.87.50880, 68840"""

        # find peaks on each chan around phasetis, assign weights by Vpp.
        # Dividing dti by 2 seems safer, since not looking for other phase, just
        # looking for same phase maybe slightly shifted. Check clusterability
        # and if this reduces cluster pollution from double-triggered spikes.
        # Catch is that some cells have spikes that really are shifted by as
        # much as dphase
        #dti = self.sort.detector.dti // 2 # constant

        # TODO: seach for peaks within dti, not just max/min value on each chan.
        # If you don't find a peak within the window for a given chan, then default to using the
        # timepoint from the maxchan

        # TODO: use the same per-channel amplitude weighted slope measure to return weights for each chan

        phasetis = np.int32(phasetis) # prevent over/underflow of uint8
        dti = max((phasetis[1]-phasetis[0]), 1) # varies from spike to spike
        V0, V1 = wavedata[maxchani, phasetis]
        window0 = wavedata[:, max(phasetis[0]-dti,0):phasetis[0]+dti]
        window1 = wavedata[:, max(phasetis[1]-dti,0):phasetis[1]+dti]
        if V0 < V1: # 1st phase is a min on maxchan, 2nd phase is a max
            #weights = np.float32(window0.min(axis=1))
            V0s = np.float32(window0.min(axis=1))
            V1s = np.float32(window1.max(axis=1))
            weights = V1s - V0s
        else: # 1st phase is a max on maxchan, 2nd phase is a min
            #weights = np.float32(window0.max(axis=1))
            V0s = np.float32(window0.max(axis=1))
            V1s = np.float32(window1.min(axis=1))
            weights = V0s - V1s
        return weights

    def weights2spatialmean(self, w, x, y, maxchani):
        """Return weighted spatial mean of chans in spike according to their
        Vpp at the same timepoints as on the max chan, to use as rough
        spatial origin of spike. x and y are spatial coords of chans in wavedata"""
        if len(w) == 1: # only one chan, return its coords
            return int(x), int(y)

        # convert to float before normalization, take abs of all weights
        # taking abs doesn't seem to affect clusterability
        w = np.abs(w)
        w /= w.sum() # normalized
        # alternative approach: replace -ve weights with 0
        #w = np.float32(np.where(w >= 0, w, 0))
        #try: w /= w.sum() # normalized
        #except FloatingPointError: pass # weird all -ve weights spike, replaced with 0s
        x0 = (w * x).sum()
        y0 = (w * y).sum()
        return x0, y0

    def weights2splines(self, w, x, y, maxchani):
        if len(w) == 1: # only one chan, return its coords
            return int(x), int(y)

        xi = x.argsort()
        w, x, y = w[xi], x[xi], y[xi] # sort points by x values
        ux = np.unique(x)
        yw = np.empty(len(ux)) # these end up being the max interpolated weight values in each column
        y0s = np.empty(len(ux))
        xis = x.searchsorted(ux) # start indices of coords with identical x values
        # iterate over columns:
        import pdb; pdb.set_trace()
        for coli, starti in enumerate(xis):
            try:
                endi = xis[coli+1]
            except IndexError:
                endi = len(x)
            yc, wc = y[starti:endi], w[starti:endi] # y and w values for this column
            if len(yc) < 3: # not enough chans in this column to interpolate vertically, just find the max?
                assert len(yc) > 0
                yi = yc.argmax()
                yw[coli] = wc[yi]
                y0s[coli] = yc[yi]
            else:
                #k = min(max(3, len(yc)-2), 5)
                k = min(3, len(yc)-1)
                yi = yc.argsort() # UnivariateSpline requires monotonically ascending coordinates
                try:
                    us = UnivariateSpline(yc[yi], wc[yi], k=k)
                except UserWarning:
                    import pdb; pdb.set_trace()
                except:
                    import pdb; pdb.set_trace()
                yc2 = np.arange(yc.min(), yc.max(), 1) # span whole y range in steps of 1um
                wc2 = us(yc2)
                # if w[maxchani] > 0: # this is always the case - see get_weights
                wi = wc2.argmax()
                #else: # look for a min:
                #    wi = wc2.argmin()
                yw[coli] = wc2[wi]
                y0s[coli] = yc2[wi]
        # do normal full spatial mean for x values
        xw = np.abs(w)
        xw /= xw.sum() # normalized
        x0 = (xw * x).sum()
        # do column-wise spatial mean for y values
        yw = np.abs(yw)
        yw /= yw.sum() # normalized
        y0 = (yw * y0s).sum()
        return x0, y0

    def weights2gaussian(self, w, x, y, maxchani):
        """Return spatial location and spread using a 2D Gaussian model,
        with location initialized using spatial mean, and spread initialized
        with constant global values. Spread and location are fit sequentially, in that
        order, because there isn't enough data from a single spike to fit them both
        simultaneously and expect to get reasonable results. Otherwise, LM ends up using the
        tail of the 2D distrib to get min sum squared error"""
        if len(w) == 1: # only one chan, return its coords and the default sigmas
            return int(x), int(y), DEFSX, DEFSY

        sls = self.sls
        x0, y0 = self.weights2spatialmean(w, x, y, maxchani)
        sls.A, sls.x0, sls.y0, sls.sx, sls.sy = w[maxchani], x0, y0, DEFSX, DEFSY
        '''
        # fit sx and sy first, since DEFSX and DEFSY are not spike-specific estimates
        sls.p0 = np.array([sls.sx, sls.sy])
        sls.calc_sxsy(x, y, w) # sx and sy free
        '''
        sls.p0 = np.array([sls.sx])
        sls.calc_s(x, y, w) # s free (sx == sy)

        # now that we have viable estimates for sx and sy, fix them and fit x0 and y0
        sls.p0 = np.array([x0, y0])
        sls.calc_x0y0(x, y, w) # x0 and y0 free

        return sls.x0, sls.y0, sls.sx, sls.sy

"""
prr_analysis.py

Python port of the MATLAB PRR toolkit (prrAutocorr.m, prrWelch.m,
prrTwoScale.m), for pulse-train periodicity analysis of bioduck-type calls.

Terminology (informal, pending Aimee's naming):
    pulse - a single downsweep, the basic repeated element
    unit  - a sub-train: a run of pulses repeating at the pulse rate
    call  - the full sequence (e.g. a whole recording/encounter)

Implements two estimators plus a two-scale wrapper:
    envelope_extract  - square + lowpass + decimate (shared preprocessing)
    check_tonal       - Patris et al. 2019 tonal/non-tonal integer-ratio test
    prr_autocorr      - repetition rate via envelope autocorrelation
    prr_welch         - repetition rate via envelope Welch PSD peak-pick
    prr_two_scale     - runs both estimators at both pulse and unit scales

See prr_welch/prr_autocorr docstrings for the full rationale. Summary: ACF
and Welch peak-picking are not interchangeable, and neither is uniformly
"the reliable one". Validated on the 176 s test file 2716_CallType_1A.wav:
    pulse scale: ACF correct (2.632 Hz); Welch locked onto the 2nd
                 harmonic (~5.47 Hz)
    unit scale:  Welch correct (0.3125 Hz, period 3.20 s, matching Dreo et
                 al. 2025's published AMW ICI range of 2.7-3.3 s); ACF's
                 tallest genuine local max was a harmonic at 6.60 s, the
                 true period was masked by a broad non-periodic decay
                 trend and never registers as a local maximum at all
This pattern (ACF right for pulse scale, Welch right for unit scale) is
validated on exactly one file. Do not assume it generalizes without
checking on more recordings/species.
"""

from dataclasses import dataclass, field
import numpy as np
from scipy.signal import butter, filtfilt, welch, find_peaks


def envelope_extract(x, sample_rate, cutoff_hz, output_rate):
    """Square-law envelope with lowpass smoothing and decimation.

    Parameters
    ----------
    x : array_like
        Bandpassed signal.
    sample_rate : float
        Sample rate of x, Hz.
    cutoff_hz : float
        Lowpass cutoff frequency for the envelope, Hz.
    output_rate : float
        Target sample rate for the decimated envelope, Hz.

    Returns
    -------
    env : ndarray
        Envelope, decimated to (approximately) output_rate.
    env_rate : float
        Actual sample rate of env.
    """
    x = np.asarray(x, dtype=float)
    sq = x ** 2
    b, a = butter(5, cutoff_hz / (sample_rate / 2), btype='low')
    sq_smooth = filtfilt(b, a, sq)

    dec_factor = round(sample_rate / output_rate)
    env = sq_smooth[::dec_factor]
    env_rate = sample_rate / dec_factor
    return env, env_rate


def check_tonal(peak_freqs, delta_f, tolerance=0.1):
    """Test whether peak frequencies are integer multiples of delta_f.

    Patris et al. 2019, Sec. II A tonal/non-tonal classification. Heuristic
    threshold, not a statistical test; tune tolerance against known-tonal
    data before trusting it near marginal SNR.

    Returns
    -------
    is_tonal : bool
    ratios : ndarray
    residuals : ndarray
        abs(ratios - round(ratios))
    """
    peak_freqs = np.asarray(peak_freqs, dtype=float)
    ratios = peak_freqs / delta_f
    residuals = np.abs(ratios - np.round(ratios))
    is_tonal = bool(np.all(residuals < tolerance))
    return is_tonal, ratios, residuals


def prr_autocorr(wav, sample_rate, bp_filt, output_rate, env_cutoff_hz,
                  search_band_hz, check_tonal_flag=True, peak_prominence=0.02):
    """Estimate repetition rate via envelope autocorrelation.

    Patris et al. 2019 base this on autocorrelation, and their stated
    procedure (Sec. II C.1, step 5) is to take the FIRST maximum of the
    autocorrelation function. In testing against a real bioduck recording,
    literal first-peak selection proved fragile: a weak local bump well
    before the true dominant peak (e.g. lag 0.19 s, ACF~0.10, next to the
    true period at lag 0.38 s, ACF~0.68) got selected instead of the real
    period, because it technically qualifies as "first". This function
    therefore selects the TALLEST genuine local maximum (scipy.signal.
    find_peaks, not a raw global max) within search_band_hz, a deliberate
    deviation from the paper's literal wording. This still avoids the
    boundary-artifact failure mode a plain global max is prone to (see
    below), while being far more robust to secondary structure than
    "first peak" on real, non-idealized recordings.

    Why not a plain global max, either: within the search band, the
    single highest point can land on the boundary closest to lag 0, if
    that boundary falls inside the broad decay tail of the zero-lag
    correlation hump rather than on a real periodic peak. This is not a
    corner case: it is exactly what happened on the bioduck unit scale
    before this fix, returning a spurious exact-1.0 Hz "peak" that was
    just the search band's edge, not a period at all.

    Even with proper local-peak detection restricted to the tallest
    candidate, a genuine periodic ripple can still be too small to
    register as a local max at all if it's superposed on a decay trend
    that hasn't settled yet (observed on the bioduck unit scale: the true
    ~3.24 s period, confirmed by Welch PSD, doesn't show as a local max in
    the ACF at all; the tallest detectable local max is at 6.60 s, a
    further-out ripple). This is a genuine limit of the method on that
    signal, not something peak-selection logic alone can fix -- see
    prr_welch and prr_two_scale, and always sanity-check prrMax against
    the acf plot rather than trusting the number alone.

    Parameters
    ----------
    wav : array_like
        Acoustic signal, single channel.
    sample_rate : float
        Sample rate of wav, Hz.
    bp_filt : array_like
        FIR bandpass coefficients (e.g. from scipy.signal.firwin),
        applied via lfilter.
    output_rate : float
        Decimated envelope sample rate, Hz.
    env_cutoff_hz : float
        Lowpass cutoff for envelope smoothing, Hz.
    search_band_hz : tuple(float, float)
        (min_hz, max_hz) range of candidate rates to search.
    check_tonal_flag : bool
        If False, skip the diagnostic tonality check and return
        is_tonal = None (useful for the unit scale, where the check
        is not meaningful; see module docstring).
    peak_prominence : float
        Minimum prominence (in normalized ACF units, [-1, 1] scale) for
        a candidate peak to count as genuine rather than noise or decay-
        slope curvature. Default 0.02 was adequate for the validated
        test file; retune for lower-SNR recordings.

    Returns
    -------
    prr_max : float
        Estimated repetition rate, Hz.
    is_tonal : bool or None
        Diagnostic tonality flag, or None if too few spectral peaks were
        found (or check_tonal_flag was False).
    acf : ndarray
        Autocorrelation function of the envelope, positive lags only.
    lags : ndarray
        Lag axis for acf, seconds.
    """
    from scipy.signal import lfilter

    wav = np.asarray(wav, dtype=float)
    wav = wav - wav.mean()   # match project convention (x = x - mean(x));
                              # also avoids result depending on whether the
                              # caller happened to do this already -- a real
                              # source of run-to-run inconsistency found
                              # during validation, when two unit-scale ACF
                              # candidate peaks were close enough in height
                              # for DC handling alone to flip which "wins"
    x = lfilter(bp_filt, 1, wav)
    env, env_rate = envelope_extract(x, sample_rate, env_cutoff_hz, output_rate)
    env = env - env.mean()

    acf_full = np.correlate(env, env, mode='full')
    acf = acf_full[len(acf_full) // 2:]
    acf = acf / acf[0]
    lags = np.arange(len(acf)) / env_rate

    min_lag = 1 / search_band_hz[1]
    max_lag = 1 / search_band_hz[0]
    search_ix = (lags >= min_lag) & (lags <= max_lag)
    if not np.any(search_ix):
        raise ValueError(
            f'No lags fall within search_band_hz {search_band_hz}. '
            'Check output_rate and search_band_hz.')

    acf_search = acf[search_ix]
    lags_search = lags[search_ix]

    pk, _ = find_peaks(acf_search, prominence=peak_prominence)
    if len(pk) == 0:
        raise ValueError(
            'No genuine local maximum found within search_band_hz '
            f'{search_band_hz} (peak_prominence={peak_prominence}). '
            'The signal may not be periodic in this band, or '
            'peak_prominence may need lowering.')
    tallest_pk = pk[np.argmax(acf_search[pk])]
    prr_max = 1 / lags_search[tallest_pk]

    is_tonal = None
    if check_tonal_flag:
        nfft_diag = int(2 ** np.ceil(np.log2(len(x))))
        X = np.abs(np.fft.fft(x, nfft_diag))
        f_diag = np.arange(nfft_diag) * (sample_rate / nfft_diag)
        half_n = nfft_diag // 2

        min_dist = max(1, round(0.5 * prr_max * nfft_diag / sample_rate))
        pk, _ = find_peaks(X[:half_n], distance=min_dist,
                            height=0.1 * X[:half_n].max())
        peak_freqs = f_diag[pk]
        if len(peak_freqs) >= 2:
            is_tonal, _, _ = check_tonal(peak_freqs, prr_max, tolerance=0.1)

    return prr_max, is_tonal, acf, lags


def prr_welch(wav, sample_rate, bp_filt, output_rate, env_cutoff_hz,
              search_band_hz, nperseg=256, noverlap=None):
    """Estimate repetition rate via Welch PSD peak-pick on the envelope.

    Generalizes prr.m (Klink 2008 tEST) with an explicit search band,
    sharing the envelope step with prr_autocorr for direct comparability.
    Can lock onto a harmonic instead of the true rate if the envelope
    shape concentrates more spectral power there (see module docstring).

    Parameters mirror prr_autocorr; nperseg/noverlap are the Welch
    segment length and overlap (samples), default nperseg=256,
    noverlap=nperseg//2.

    Returns
    -------
    prr_max : float
        Estimated repetition rate, Hz (strongest bin in search_band_hz).
    prr_power : ndarray
        Welch PSD of the envelope, full band.
    f : ndarray
        Frequency axis for prr_power, Hz.
    """
    from scipy.signal import lfilter

    if noverlap is None:
        noverlap = nperseg // 2

    wav = np.asarray(wav, dtype=float)
    wav = wav - wav.mean()   # see prr_autocorr for why this matters
    x = lfilter(bp_filt, 1, wav)
    env, env_rate = envelope_extract(x, sample_rate, env_cutoff_hz, output_rate)
    env = env - env.mean()

    f, prr_power = welch(env, fs=env_rate, nperseg=min(nperseg, len(env)),
                          noverlap=min(noverlap, len(env) - 1))

    ix = np.where((f >= search_band_hz[0]) & (f <= search_band_hz[1]))[0]
    if len(ix) == 0:
        raise ValueError(
            f'No frequency bins fall within search_band_hz {search_band_hz}. '
            'Check nperseg/env_rate resolution.')
    max_ix = ix[np.argmax(prr_power[ix])]
    prr_max = f[max_ix]

    return prr_max, prr_power, f


def cepstrum_via_spectrogram(wav, sample_rate, f_min, f_max, new_fs,
                              fft_size, overlap_frac=0.75,
                              detrend_qlo_frac=0.1, detrend_qhi_frac=0.9,
                              medfilt_kernel=5):
    """Real spectrogram-based cepstrum, matching cepstroBSM.m's algorithm:
    bandpass -> Hilbert baseband shift -> resample -> STFT -> average
    magnitude spectra across all time frames -> log-power cepstrum ->
    detrend (median filter then linear fit over the inner quefrency
    range, subtracted -- matching cepstroDreo.m's own detrend step).

    CORRECTED after initial testing wrongly concluded broadband pulses
    (bioduck downsweeps) don't produce detectable cepstral comb structure.
    That conclusion was wrong and came from two bugs in an earlier version
    of this function, not a real limitation of the method -- confirmed by
    testing against both a synthetic broadband chirp-train (comb clearly
    visible) and the real bioduck file (see below):

    1. Insufficient detrending. There's a much coarser (~20-25 Hz period)
       ripple in the spectrum from each individual pulse's own spectral
       shape (Fresnel-type ripple from the downsweep's sweep duration),
       unrelated to inter-pulse timing. A naive linear-only detrend over
       the inner quefrency range doesn't remove this; it dominated the
       first version's blind peak search. The median-filter-then-polyfit
       detrend here (matching cepstroDreo.m exactly) removes it properly.
    2. Blind global-max search across the whole quefrency range, instead
       of Dreo et al.'s actual design: compute peak-vs-valley contrast
       within a PRE-SPECIFIED candidate window (their Pqmin/Pqmax), never
       a blind search. The coarse artifact above wins a blind search by
       default; it does not survive a properly windowed comparison.

    With both fixed, on 2716_CallType_1A.wav: the pulse-scale period shows
    a genuine local peak at quefrency 0.382 s, matching prr_autocorr's
    0.379-0.380 s. The unit-scale period is much less clean even with
    these fixes -- current best explanation is that the unit-scale
    periodicity is itself weaker/less regular in this recording (ACF/Welch
    already show much lower correlation and broader peaks there than at
    the pulse scale) and there are far fewer independent cycles to average
    over 176 s (~50 unit-scale vs ~460 pulse-scale), not a broadband-chirp
    limitation. Not fully resolved; a formal p2vr-style detection
    statistic (Dreo et al.'s peak^3/valley^3 formula) was tried and came
    out numerically unstable at the parameters used here (near-zero peak
    and valley means, unreliable once cubed) -- needs recalibration before
    trusting a p2vr number from this function, treat the returned
    cepstrum/quefrency as a diagnostic plot, not a calibrated statistic.

    Parameters
    ----------
    wav : array_like
    sample_rate : float
    f_min, f_max : float
        Bandpass edges, Hz.
    new_fs : float
        Resample rate after baseband shift, Hz (>= 2*(f_max-f_min) to
        avoid aliasing the shifted band).
    fft_size : int
        STFT window length, samples at new_fs. Sets max quefrency =
        (fft_size/2)/new_fs.
    overlap_frac : float
        STFT segment overlap fraction, default 0.75.
    detrend_qlo_frac, detrend_qhi_frac : float
        Fraction of the quefrency range (0 to Nyquist-quefrency) used for
        the detrend fit, default 0.1-0.9 matching cepstroDreo.m.
    medfilt_kernel : int
        Median filter kernel size applied before the linear detrend fit,
        default 5 matching cepstroDreo.m. This step is what makes the
        detrend robust to the coarse per-pulse-shape artifact described
        above; skipping it (as the first, buggy version of this function
        did) reintroduces the false-negative result.

    Returns
    -------
    cep : ndarray
        Detrended log-power cepstrum, first half only.
    quefrency : ndarray
        Quefrency axis for cep, seconds.
    """
    from scipy.signal import filtfilt, hilbert, resample, stft, medfilt

    wav = np.asarray(wav, dtype=float)
    wav = wav - wav.mean()
    nyq = sample_rate / 2
    bp = firwin_local(f_min, min(f_max, nyq * 0.999), sample_rate)
    x_filt = filtfilt(bp, 1, wav)

    t = np.arange(len(x_filt)) / sample_rate
    x_bb = np.real(hilbert(x_filt) * np.exp(-1j * 2 * np.pi * f_min * t))

    n_out = int(round(len(x_bb) * new_fs / sample_rate))
    xds = resample(x_bb, n_out)

    noverlap = int(overlap_frac * fft_size)
    f, tt, S = stft(xds, fs=new_fs, nperseg=fft_size, noverlap=noverlap,
                     boundary=None)
    mag_mean = np.mean(np.abs(S), axis=1)

    log_power = np.log(mag_mean ** 2 + np.finfo(float).eps)
    full = np.concatenate([log_power, log_power[-2:0:-1]])
    cep_full = np.real(np.fft.ifft(full))
    n_q = fft_size // 2 + 1
    cep = cep_full[:n_q]
    quefrency = np.arange(n_q) / new_fs

    qlo = int(detrend_qlo_frac * n_q)
    qhi = int(detrend_qhi_frac * n_q)
    ix = np.arange(qlo, qhi)
    cep_smooth = medfilt(cep[ix], medfilt_kernel)
    p = np.polyfit(quefrency[ix], cep_smooth, 1)
    trend = np.polyval(p, quefrency)
    cep_detrended = cep - trend

    return cep_detrended, quefrency


def firwin_local(f_lo, f_hi, fs, numtaps=101):
    """Small local helper so cepstrum_via_spectrogram doesn't require the
    caller to have already built a filter (unlike prr_autocorr/prr_welch,
    which take bp_filt as an argument for reuse across calls)."""
    from scipy.signal import firwin
    return firwin(numtaps, [f_lo, f_hi], pass_zero=False, fs=fs)


@dataclass
class ScaleResult:
    acf_rate: float
    acf_is_tonal: object
    acf: np.ndarray
    acf_lags: np.ndarray
    welch_rate: float
    welch_power: np.ndarray
    welch_f: np.ndarray
    agree: bool


DEFAULT_PULSE_CFG = dict(output_rate=200, env_cutoff_hz=20,
                          search_band_hz=(1, 10), nperseg=512, noverlap=256)
DEFAULT_UNIT_CFG = dict(output_rate=10, env_cutoff_hz=0.5,
                         search_band_hz=(0.05, 1), nperseg=512, noverlap=256)


def prr_two_scale(wav, sample_rate, bp_filt, pulse_cfg=None, unit_cfg=None):
    """Estimate both pulse-rate and unit-rate periodicity in one call.

    Runs both prr_autocorr and prr_welch at both the pulse (fast) and
    unit (slow) scales, rather than picking one method per scale. See
    module docstring for why: on the validated test file, ACF was correct
    at the pulse scale and wrong at the unit scale, Welch the reverse.

    Note on acf_is_tonal: meaningful at the pulse scale (audio-band
    spectral peaks ARE the pulse harmonic comb). Not meaningful at the
    unit scale (audio-band peaks are so far above the unit rate that the
    integer-ratio test is close to trivially satisfied) -- returned for
    completeness only, disabled by default via check_tonal_flag=False
    for the unit scale.

    Parameters
    ----------
    wav : array_like
    sample_rate : float
    bp_filt : array_like
        FIR bandpass spanning the full species band, e.g.
        scipy.signal.firwin(101, [50, 250], pass_zero=False, fs=sample_rate)
    pulse_cfg, unit_cfg : dict, optional
        Override defaults (DEFAULT_PULSE_CFG / DEFAULT_UNIT_CFG), validated
        on 2716_CallType_1A.wav. Retune env_cutoff_hz / search_band_hz for
        other species or call types.

    Returns
    -------
    pulse, unit : ScaleResult
    """
    pulse_cfg = dict(DEFAULT_PULSE_CFG) if pulse_cfg is None else pulse_cfg
    unit_cfg = dict(DEFAULT_UNIT_CFG) if unit_cfg is None else unit_cfg

    def one_scale(cfg, check_tonal_flag):
        acf_rate, acf_is_tonal, acf, acf_lags = prr_autocorr(
            wav, sample_rate, bp_filt, cfg['output_rate'],
            cfg['env_cutoff_hz'], cfg['search_band_hz'],
            check_tonal_flag=check_tonal_flag)

        welch_rate, welch_power, welch_f = prr_welch(
            wav, sample_rate, bp_filt, cfg['output_rate'],
            cfg['env_cutoff_hz'], cfg['search_band_hz'],
            nperseg=cfg['nperseg'], noverlap=cfg['noverlap'])

        ratio = acf_rate / welch_rate
        nearest_int = max(1, round(ratio))
        nearest_int_inv = max(1, round(1 / ratio))
        agree = (abs(ratio / nearest_int - 1) < 0.1 or
                 abs((1 / ratio) / nearest_int_inv - 1) < 0.1)

        return ScaleResult(acf_rate, acf_is_tonal, acf, acf_lags,
                            welch_rate, welch_power, welch_f, agree)

    pulse = one_scale(pulse_cfg, check_tonal_flag=True)
    unit = one_scale(unit_cfg, check_tonal_flag=False)
    return pulse, unit

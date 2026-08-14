"""
demo_two_scale_bioduck.py

Pulse-rate and unit-rate estimation on a real bioduck recording, using
prr_two_scale from prr_analysis.py.

Terminology: pulse (single downsweep) -> unit (sub-train of pulses) ->
call (the full sequence).

Validated result on 2716_CallType_1A.wav (176 s):
    pulse rate: ACF 2.632 Hz, Welch 5.469 Hz (2:1 harmonic, ACF correct)
    unit rate:  ACF 12.80 s (~4x harmonic), Welch 3.20 s (Welch correct,
                matches Dreo et al. 2025's published AMW ICI range of
                2.7-3.3 s)

Usage:
    python demo_two_scale_bioduck.py /path/to/2716_CallType_1A.wav
"""

import sys
import numpy as np
import soundfile as sf
from scipy.signal import firwin
from prr_analysis import prr_two_scale, cepstrum_via_spectrogram


def main(wav_path):
    wav, fs = sf.read(wav_path)
    wav = wav - wav.mean()

    bp = firwin(101, [50, 250], pass_zero=False, fs=fs)

    pulse, unit = prr_two_scale(wav, fs, bp)

    print('PULSE scale:')
    print(f'  ACF rate:   {pulse.acf_rate:.3f} Hz  (period {1/pulse.acf_rate:.3f} s)  '
          f'isTonal={pulse.acf_is_tonal}')
    print(f'  Welch rate: {pulse.welch_rate:.3f} Hz')
    print(f'  agree:      {pulse.agree}')
    print()
    print('UNIT scale:')
    print(f'  ACF rate:   {unit.acf_rate:.4f} Hz  ({1/unit.acf_rate:.2f} s)')
    print(f'  Welch rate: {unit.welch_rate:.4f} Hz  ({1/unit.welch_rate:.2f} s)')
    print(f'  agree:      {unit.agree}')

    # Cepstrum via the real spectrogram-based method (matching
    # cepstroBSM.m), WITH the median-filter+polyfit detrend that turned out
    # to be essential (see cepstrum_via_spectrogram docstring -- an earlier
    # version without proper detrending falsely showed no comb structure).
    # Search window is intentionally NARROW and centered on the already-
    # known ACF/Welch period (Dreo et al.'s actual design: confirm a
    # candidate period via peak-vs-valley contrast in a pre-specified
    # window, never a blind search across the whole quefrency range -- a
    # blind search lets an unrelated, taller peak near low quefrency win,
    # as an earlier version of this script did).
    cepP, qP = cepstrum_via_spectrogram(wav, fs, 50, 250, 400, 1024, 0.75)
    cepU, qU = cepstrum_via_spectrogram(wav, fs, 50, 250, 400, 8000, 0.75)
    pulse_period = 1 / pulse.acf_rate
    unit_period = 1 / unit.welch_rate
    idxP = (qP > 0.8*pulse_period) & (qP < 1.2*pulse_period)
    idxU = (qU > 0.7*unit_period) & (qU < 1.3*unit_period)
    peakP_q = qP[idxP][np.argmax(cepP[idxP])]
    peakU_q = qU[idxU][np.argmax(cepU[idxU])]
    print()
    print('CEPSTRUM (spectrogram-based, cepstroBSM.m-style, detrended,')
    print('          searched in a narrow window around the known period):')
    print(f'  pulse-band peak in [{0.8*pulse_period:.3f},{1.2*pulse_period:.3f}]s: '
          f'{peakP_q:.3f} s  (ACF/Welch period: {pulse_period:.3f} s -- matches)')
    print(f'  unit-band peak in [{0.7*unit_period:.2f},{1.3*unit_period:.2f}]s:   '
          f'{peakU_q:.3f} s  (Welch period: {unit_period:.2f} s)')

    # Wider display range for the plots so the reader can see the search
    # window in context, not just the winning point.
    idxP_plot = (qP > 0.05) & (qP < 1.2)
    idxU_plot = (qU > 0.3) & (qU < 10.0)

    try:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt

        fig, axs = plt.subplots(2, 3, figsize=(16, 7))

        axs[0, 0].plot(pulse.acf_lags, pulse.acf)
        axs[0, 0].axvline(1/pulse.acf_rate, color='r', ls='--',
                           label=f'{pulse.acf_rate:.3f} Hz (ACF)')
        axs[0, 0].set_xlim(0, 1)
        axs[0, 0].set_xlabel('lag (s)'); axs[0, 0].set_ylabel('autocorrelation')
        axs[0, 0].set_title('Pulse scale: ACF'); axs[0, 0].legend(fontsize=8)

        axs[0, 1].plot(pulse.welch_f, pulse.welch_power)
        axs[0, 1].axvline(pulse.welch_rate, color='b', ls='--',
                           label=f'{pulse.welch_rate:.3f} Hz (Welch)')
        axs[0, 1].axvline(pulse.acf_rate, color='r', ls=':',
                           label=f'{pulse.acf_rate:.3f} Hz (ACF, for reference)')
        axs[0, 1].set_xlim(0, 12)
        axs[0, 1].set_xlabel('Hz'); axs[0, 1].set_ylabel('PSD')
        axs[0, 1].set_title('Pulse scale: Welch PSD'); axs[0, 1].legend(fontsize=8)

        axs[0, 2].plot(qP[idxP_plot], cepP[idxP_plot])
        axs[0, 2].axvspan(0.8*pulse_period, 1.2*pulse_period, color='g', alpha=0.15,
                           label='search window')
        axs[0, 2].axvline(pulse_period, color='r', ls=':', label='ACF period')
        axs[0, 2].set_xlabel('quefrency (s)'); axs[0, 2].set_ylabel('detrended cepstrum')
        axs[0, 2].set_title('Pulse scale: cepstrum (detrended)'); axs[0, 2].legend(fontsize=8)

        axs[1, 0].plot(unit.acf_lags, unit.acf)
        axs[1, 0].axvline(1/unit.welch_rate, color='b', ls='--',
                           label=f'{1/unit.welch_rate:.2f} s (Welch)')
        axs[1, 0].axvline(1/unit.acf_rate, color='r', ls='--',
                           label=f'{1/unit.acf_rate:.2f} s (ACF)')
        axs[1, 0].set_xlim(0, 20)
        axs[1, 0].set_xlabel('lag (s)'); axs[1, 0].set_ylabel('autocorrelation')
        axs[1, 0].set_title('Unit scale: ACF'); axs[1, 0].legend(fontsize=8)

        axs[1, 1].plot(unit.welch_f, unit.welch_power)
        axs[1, 1].axvline(unit.welch_rate, color='b', ls='--',
                           label=f'{unit.welch_rate:.3f} Hz (Welch)')
        axs[1, 1].axvline(unit.acf_rate, color='r', ls=':',
                           label=f'{unit.acf_rate:.3f} Hz (ACF, for reference)')
        axs[1, 1].set_xlim(0, 1)
        axs[1, 1].set_xlabel('Hz'); axs[1, 1].set_ylabel('PSD')
        axs[1, 1].set_title('Unit scale: Welch PSD'); axs[1, 1].legend(fontsize=8)

        axs[1, 2].plot(qU[idxU_plot], cepU[idxU_plot])
        axs[1, 2].axvspan(0.7*unit_period, 1.3*unit_period, color='g', alpha=0.15,
                           label='search window')
        axs[1, 2].axvline(unit_period, color='b', ls=':', label='Welch period')
        axs[1, 2].set_xlabel('quefrency (s)'); axs[1, 2].set_ylabel('detrended cepstrum')
        axs[1, 2].set_title('Unit scale: cepstrum (detrended)'); axs[1, 2].legend(fontsize=8)

        fig.suptitle('Bioduck pulse-rate vs unit-rate: ACF, Welch, cepstrum compared\n'
                      '(cepstrum: pulse-scale peak matches ACF/Welch; unit-scale still unclear)',
                      fontsize=10)
        plt.tight_layout()
        outpath = 'two_scale_demo.png'
        plt.savefig(outpath, dpi=130)
        print(f'\nSaved plot to {outpath}')
    except ImportError:
        pass

    return pulse, unit


if __name__ == '__main__':
    wav_path = sys.argv[1] if len(sys.argv) > 1 else '2716_CallType_1A.wav'
    main(wav_path)

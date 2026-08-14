% TEST_PRRMETHODS  Compare prr.m (Klink 2008, Welch PSD peak-pick) against
% prrAutocorr.m (Patris et al. 2019, envelope autocorrelation) on synthetic
% pulse trains with known ground-truth PRR.
%
% Requires on path: prr.m, prrAutocorr.m, envelopeExtract.m, checkTonal.m,
% synthPulseTrain.m

clear; clc;

sampleRate  = 48000;
f0          = 31.7;
durationSec = 4;
prrHz       = 6;
snrDb       = 20;

filterBand = [5 200];
bpFilt = fir1(8, filterBand/(sampleRate/2), 'bandpass');

outputRate   = 1000;
nfft         = 256;
noverlap     = 128;
envCutoffHz  = 10;
searchBandHz = [2 20];

fprintf('%-8s %-9s %-10s %-9s %-10s %-9s %-8s\n', ...
    'model', 'truePRR', 'prr.m', 'err%', 'prrAcf', 'err%', 'isTonal');

for model = {'A', 'B'}
    m = model{1};
    [wav, fs, truePrr] = synthPulseTrain(prrHz, f0, durationSec, sampleRate, m, 0.02, snrDb);

    [prrWelch, ~, ~] = prr(wav, fs, bpFilt, outputRate, nfft, noverlap);
    errWelch = 100*(prrWelch - truePrr)/truePrr;

    [prrAcf, isTonal] = prrAutocorr(wav, fs, bpFilt, outputRate, envCutoffHz, searchBandHz);
    errAcf = 100*(prrAcf - truePrr)/truePrr;

    fprintf('%-8s %-9.3f %-10.3f %-9.2f %-10.3f %-9.2f %-8d\n', ...
        m, truePrr, prrWelch, errWelch, prrAcf, errAcf, isTonal);
end

% Expected: Model A (tonal) should show low error for both methods, with
% prrAutocorr typically more precise and isTonal = 1. Model B (non-tonal)
% tests that the tonality flag correctly comes back 0, and is a reminder
% that PRR estimates on non-tonal signals are not guaranteed unbiased by
% either method here.

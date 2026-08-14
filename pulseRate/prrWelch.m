function [prrMax, prrPower, f] = prrWelch(wav, sampleRate, bpFilt, outputRate, envCutoffHz, searchBandHz, nfft, noverlap)
% PRRWELCH  Estimate repetition rate via Welch PSD peak-pick on the envelope.
%
% Same envelope pipeline as prrAutocorr.m (see envelopeExtract.m), but
% locates the rate as the strongest bin in the envelope's Welch power
% spectrum within searchBandHz. This generalizes prr.m's approach (Klink
% 2008 tEST) with an explicit search band, sharing the envelope step with
% prrAutocorr.m so the two methods are directly comparable on the same
% preprocessed signal.
%
% IMPORTANT: Welch peak-picking and autocorrelation are NOT reliably
% interchangeable. Each has a distinct, opposite failure mode, both
% observed on the same 176 s bioduck test file (2716_CallType_1A.wav):
%
%   - Welch (this function) can lock onto a harmonic instead of the true
%     rate, if the pulse/unit envelope shape concentrates more spectral
%     power there than at the fundamental. On the bioduck PULSE scale,
%     Welch found ~5.3 Hz (the 2nd harmonic); the true rate, confirmed by
%     autocorrelation and by the harmonic comb structure, was 2.64 Hz.
%
%   - Autocorrelation (prrAutocorr.m) can miss the true rate if it's
%     superposed on a broad, non-periodic decay/correlation-length trend
%     that dominates the ACF at short lags, masking the real periodic
%     bump. On the bioduck UNIT scale, the ACF's first local max was at
%     6.6 s (itself a harmonic); Welch correctly found 3.24 s, matching
%     Dreo et al. 2025's published AMW ICI range of 2.7-3.3 s.
%
% Run both (see prrTwoScale.m) and compare rather than trusting either
% method alone. This pattern (ACF right for pulse scale, Welch right for
% unit scale) is validated on exactly one file; do not assume it
% generalizes without checking.
%
% Inputs
%   wav          acoustic signal, single channel
%   sampleRate   sample rate of wav, Hz
%   bpFilt       FIR bandpass coefficients (as from fir1), applied via filter()
%   outputRate   decimated envelope sample rate, Hz
%   envCutoffHz  lowpass cutoff for envelope smoothing, Hz
%   searchBandHz [minHz maxHz], range of candidate rates to search
%   nfft         Welch FFT length (default 256)
%   noverlap     Welch segment overlap in samples (default floor(nfft/2))
%
% Outputs
%   prrMax    estimated repetition rate, Hz (strongest bin in searchBandHz)
%   prrPower  Welch PSD of the envelope, full band
%   f         frequency axis for prrPower, Hz

if nargin < 7 || isempty(nfft),     nfft = 256;              end
if nargin < 8 || isempty(noverlap), noverlap = floor(nfft/2); end

showPlot = nargout == 0;

% Mean-remove the raw waveform first; see prrAutocorr.m for why this
% matters beyond following project convention.
wav = double(wav(:));
wav = wav - mean(wav);

x = filter(bpFilt, 1, wav);
[env, envRate] = envelopeExtract(x, sampleRate, envCutoffHz, outputRate);
env = env - mean(env);

[prrPower, f] = pwelch(env, nfft, noverlap, nfft, envRate);

ixNum = find(f >= searchBandHz(1) & f <= searchBandHz(2));
if isempty(ixNum)
    error('prrWelch:emptySearchRange', ...
        'No frequency bins fall within searchBandHz [%g %g]. Check nfft/envRate resolution.', ...
        searchBandHz(1), searchBandHz(2));
end
[~, localMaxIx] = max(prrPower(ixNum));
maxIx = ixNum(localMaxIx);
prrMax = f(maxIx);

if showPlot
    plot(f, prrPower); hold on;
    plot(prrMax, prrPower(maxIx), 'ro');
    xlabel('Hz'); ylabel('PSD');
    xlim([0, min(f(end), searchBandHz(2)*5)]);
    title(sprintf('prrMax = %.3f Hz', prrMax));
    drawnow;
end

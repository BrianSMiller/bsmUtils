function [prrMax, isTonal, acf, lags] = prrAutocorr(wav, sampleRate, bpFilt, outputRate, envCutoffHz, searchBandHz)
% PRRAUTOCORR  Estimate pulse repetition rate via envelope autocorrelation.
%
% Implements the method of:
%   Patris, J., Malige, F., Glotin, H., Asch, M., and Buchan, S.J. (2019).
%   "A standardized method of classifying pulsed sounds and its application
%   to pulse rate measurement of blue whale southeast Pacific song units,"
%   J. Acoust. Soc. Am. 146(4), 2145-2154.
%
% Companion to prr.m (Klink 2008 tEST, Welch PSD peak-pick). Instead of
% picking the peak of the envelope's power spectrum, this finds PRR from
% the first non-zero peak of the envelope's autocorrelation function.
% Patris et al. report this is substantially more precise than FFT
% peak-difference methods for short signals (~1.5% vs ~8% relative
% uncertainty in their test case), because autocorrelation resolution
% isn't limited by FFT bin width (1/Tsignal).
%
% Tonality (Patris et al. Sec. II A) is computed as a diagnostic, not a
% gate: it tells you whether autocorrelation is theoretically unbiased for
% this signal, but prrMax is still returned either way. Treat prrMax as
% potentially biased when isTonal is false or NaN.
%
% NOTE: Patris et al. describe a further refinement for tonal signals,
% "summed autocorrelation" of the raw (unenvelope) signal (citing Wise et
% al. 1976), which they report as their most precise method (~0.3% error
% in their test case). The paper does not give the algorithm in enough
% detail to reimplement faithfully, so it is NOT included here. This
% function implements only the envelope-autocorrelation method, which the
% paper itself validates as a solid middle ground (~1.5% error).
%
% Example - synthetic tonal pulse train, fpulse = 6 Hz
%     [wav, fs] = synthPulseTrain(6, 31.7, 4, 48000, 'A');
%     bpFilt = fir1(8, [5 200]/(fs/2), 'bandpass');
%     [prrMax, isTonal] = prrAutocorr(wav, fs, bpFilt, 1000, 10, [2 20]);
%
% Inputs
%   wav          acoustic signal, single channel
%   sampleRate   sample rate of wav, Hz
%   bpFilt       FIR bandpass coefficients (as from fir1), applied via filter()
%   outputRate   decimated envelope sample rate, Hz (as in prr.m)
%   envCutoffHz  lowpass cutoff for envelope smoothing, Hz (Patris et al. used 10 Hz)
%   searchBandHz [minHz maxHz], range of candidate PRR values to search
%
% Outputs
%   prrMax   estimated pulse repetition rate, Hz
%   isTonal  diagnostic tonality flag from checkTonal.m; NaN if too few
%            spectral peaks were found to test
%   acf      autocorrelation function of the envelope, positive lags only
%   lags     lag axis for acf, in seconds

showPlot = nargout == 0;

x = filter(bpFilt, 1, wav);

[env, envRate] = envelopeExtract(x, sampleRate, envCutoffHz, outputRate);
env = env - mean(env);

[acfFull, lagSamples] = xcorr(env, 'coeff');
posIx = lagSamples >= 0;
acf = acfFull(posIx);
lags = lagSamples(posIx) / envRate;

minLag = 1 / searchBandHz(2);
maxLag = 1 / searchBandHz(1);
searchIx = lags >= minLag & lags <= maxLag;

if ~any(searchIx)
    error('prrAutocorr:emptySearchRange', ...
        'No lags fall within searchBandHz [%g %g]. Check outputRate and searchBandHz.', ...
        searchBandHz(1), searchBandHz(2));
end

acfSearch = acf(searchIx);
lagsSearch = lags(searchIx);
[~, peakIx] = max(acfSearch);
prrMax = 1 / lagsSearch(peakIx);

% Diagnostic tonality check: FFT peaks of the bandpassed signal vs prrMax
nfftDiag = 2^nextpow2(length(x));
X = abs(fft(x, nfftDiag));
fDiag = (0:nfftDiag-1) * (sampleRate/nfftDiag);
halfN = floor(nfftDiag/2);

minPeakDistSamples = max(1, round(0.5 * prrMax * nfftDiag / sampleRate));
[~, pkLocs] = findpeaks(X(1:halfN), 'MinPeakDistance', minPeakDistSamples, ...
    'MinPeakHeight', 0.1*max(X(1:halfN)));
peakFreqs = fDiag(pkLocs);

if numel(peakFreqs) >= 2
    isTonal = checkTonal(peakFreqs, prrMax, 0.1);
else
    isTonal = NaN;
    warning('prrAutocorr:tonalCheckSkipped', ...
        'Fewer than 2 spectral peaks found for tonality check; isTonal set to NaN.');
end

if showPlot
    subplot(2,1,1);
    plot((0:length(env)-1)/envRate, env);
    xlabel('time (s)'); ylabel('envelope (mean-removed)');
    subplot(2,1,2);
    plot(lags, acf); hold on;
    plot(lagsSearch(peakIx), acfSearch(peakIx), 'ro');
    xlabel('lag (s)'); ylabel('autocorrelation');
    title(sprintf('prrMax = %.3f Hz, isTonal = %d', prrMax, isTonal));
    drawnow;
end

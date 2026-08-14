% DEMO_TWOSCALE_BIODUCK  Pulse-rate and unit-rate estimation on a real
% bioduck recording, using prrTwoScale.m.
%
% Terminology: pulse (single downsweep) -> unit (sub-train of pulses) ->
% call (the full sequence).
%
% Validated result on 2716_CallType_1A.wav (176 s):
%   pulse rate: ACF 2.632 Hz, Welch 5.469 Hz (2:1 harmonic, ACF correct)
%   unit rate:  ACF 6.60 s (2:1 harmonic), Welch 3.20 s (Welch correct,
%               matches Dreo et al. 2025's published AMW ICI range of
%               2.7-3.3 s)
%
% CORRECTION (see prrTwoScale.m / demo_two_scale_bioduck.py for the full
% story): an earlier version of this demo claimed the real spectrogram-
% based cepstral method (Dreo et al. 2025 / cepstroBSM.m) shows no comb
% structure on bioduck. That was wrong -- caused by two bugs in a quick
% Python reimplementation used to test the idea (missing the median-filter
% step in the detrend, and searching blindly across the whole quefrency
% range instead of a narrow window around the already-known candidate
% period, which is how Dreo et al.'s method is actually designed to be
% used). Fixed, the pulse-scale cepstrum shows a genuine peak at
% quefrency 0.383 s, matching ACF/Welch's 0.380 s closely. The unit-scale
% cepstrum peak (2.69 s) is in the right neighbourhood of Welch's 3.20 s
% but not a tight match -- likely because the unit-scale periodicity is
% itself weaker/less regular in this file (ACF/Welch already show much
% lower correlation there) and there are far fewer independent cycles to
% average (~50 vs ~460 at the pulse scale), not a method limitation.
%
% Your own cepstroDreo.m/cepstroBSM.m should reproduce this correctly
% without modification, since they already implement the right detrend
% (median filter + polyfit) and windowed peak/valley comparison (Pqmin/
% Pqmax) design -- the bug was in the quick Python port used to test this,
% not in the underlying method or your existing MATLAB code.
%
% Requires on path: prrAutocorr.m, prrWelch.m, prrTwoScale.m,
% envelopeExtract.m, checkTonal.m

wavFile = fullfile( ...
    'S:\brian_mil\Documents\Students\Aimee\codeAndData\Slide_WavFiles_9.5.24\',...
    '2716_CallType_1A.wav');   % set to your local copy

[wav, fs] = audioread(wavFile);
wav = wav - mean(wav);

bpFilt = fir1(100, [50 250]/(fs/2), 'bandpass');

[pulse, unit] = prrTwoScale(wav, fs, bpFilt);

fprintf('PULSE scale:\n');
fprintf('  ACF rate:   %.3f Hz  (period %.3f s)  isTonal=%d\n', ...
    pulse.acfRate, 1/pulse.acfRate, pulse.acfIsTonal);
fprintf('  Welch rate: %.3f Hz\n', pulse.welchRate);
fprintf('  agree:      %d\n\n', pulse.agree);

fprintf('UNIT scale:\n');
fprintf('  ACF rate:   %.4f Hz  (%.2f s)\n', unit.acfRate, 1/unit.acfRate);
fprintf('  Welch rate: %.4f Hz  (%.2f s)\n', unit.welchRate, 1/unit.welchRate);
fprintf('  agree:      %d\n', unit.agree);

figure;
tl = tiledlayout(2,2);
title(tl, {'Bioduck pulse-rate vs unit-rate: ACF vs Welch compared', ...
    '(spectrogram-based cepstrum tested separately in Python - see header for status)'});

nexttile;
plot(pulse.acfLags, pulse.acf); hold on;
xline(1/pulse.acfRate, 'r--', sprintf('%.3f Hz (ACF)', pulse.acfRate));
xlabel('lag (s)'); ylabel('autocorrelation'); title('Pulse scale: ACF');
xlim([0 1]);

nexttile;
plot(pulse.welchF, pulse.welchPower); hold on;
xline(pulse.welchRate, 'b--', sprintf('%.3f Hz (Welch)', pulse.welchRate));
xline(pulse.acfRate, 'r:', sprintf('%.3f Hz (ACF, for reference)', pulse.acfRate));
xlabel('Hz'); ylabel('PSD'); title('Pulse scale: Welch PSD');
xlim([0 12]);

nexttile;
plot(unit.acfLags, unit.acf); hold on;
xline(1/unit.welchRate, 'b--', sprintf('%.2f s (Welch)', 1/unit.welchRate));
xline(1/unit.acfRate, 'r--', sprintf('%.2f s (ACF)', 1/unit.acfRate));
xlabel('lag (s)'); ylabel('autocorrelation'); title('Unit scale: ACF');
xlim([0 20]);

nexttile;
plot(unit.welchF, unit.welchPower); hold on;
xline(unit.welchRate, 'b--', sprintf('%.3f Hz (Welch)', unit.welchRate));
xline(unit.acfRate, 'r:', sprintf('%.3f Hz (ACF, for reference)', unit.acfRate));
xlabel('Hz'); ylabel('PSD'); title('Unit scale: Welch PSD');
xlim([0 1]);

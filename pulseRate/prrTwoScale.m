function [pulse, unit] = prrTwoScale(wav, sampleRate, bpFilt, pulseCfg, unitCfg)
% PRRTWOSCALE  Estimate both pulse-rate and unit-rate periodicity in one call.
%
% Terminology (informal, pending Aimee's naming):
%   pulse - a single downsweep, the basic repeated element
%   unit  - a sub-train: a run of pulses repeating at the pulse rate
%   call  - the full sequence (e.g. a whole recording/encounter)
%
% Pulses within a unit repeat at a fast, sharply regular rate. Units
% repeat at a much slower, less regular rate. Validated on
% 2716_CallType_1A.wav (176 s): pulse rate 2.632 Hz, unit rate 0.3125 Hz
% (period 3.20 s), the latter matching Dreo et al. 2025's published AMW
% ICI range of 2.7-3.3 s.
%
% IMPORTANT: this function does NOT pick a single "best" method per scale.
% prrAutocorr.m (ACF) and prrWelch.m (Welch PSD) have distinct, opposite
% failure modes (see prrWelch.m header). On the validated file:
%   pulse scale: ACF was correct (2.64 Hz), Welch locked onto the 2nd
%                harmonic (5.3-5.5 Hz)
%   unit scale:  Welch was correct (0.3125 Hz / 3.20 s); the ACF's true
%                period doesn't even register as a local maximum, it's
%                too small relative to the still-decaying zero-lag
%                correlation hump. The ACF's tallest genuine local max is
%                a further-out ripple, at 6.60 s (agree=true correctly
%                flags this as a 2:1 harmonic relationship, not a match
%                on the fundamental)
% Both estimates are returned at both scales so disagreement is visible
% rather than hidden. Treat cases where agree == false as needing a look
% at the acf/welchPower plots before trusting either number. Note that
% agree == true can mean "the two methods landed on the same harmonic of
% a shared underlying rate" rather than "both found the fundamental" -
% check which harmonic makes physical sense (see prrWelch.m header).
%
% NOTE on pulse.acfIsTonal / unit.acfIsTonal: this diagnostic (from
% prrAutocorr.m / checkTonal.m) compares spectral peaks of the raw
% bandpassed audio against the candidate rate. That comparison is
% meaningful at the pulse scale, where the audio-band peaks ARE the pulse
% harmonic comb. At the unit scale, audio-band peaks (tens to hundreds of
% Hz) are so much higher than the candidate unit rate (< 1 Hz) that the
% integer-ratio test is close to trivially satisfied. Treat
% unit.acfIsTonal as not meaningful; it is returned for completeness only.
%
% Inputs
%   wav        acoustic signal, single channel
%   sampleRate sample rate of wav, Hz
%   bpFilt     FIR bandpass coefficients spanning the full species band
%              (e.g. fir1(8, [50 250]/(sampleRate/2), 'bandpass'))
%   pulseCfg   struct: outputRate, envCutoffHz, searchBandHz, nfft, noverlap
%              for the fast (pulse) scale. Defaults validated on
%              2716_CallType_1A.wav; retune envCutoffHz/searchBandHz for
%              other species or call types.
%   unitCfg    struct with same fields for the slow (unit) scale.
%
% Outputs
%   pulse, unit   structs, each with fields:
%       acfRate      rate from prrAutocorr.m, Hz
%       acfIsTonal   tonality diagnostic from prrAutocorr.m (see NOTE above)
%       acf, acfLags autocorrelation function and lag axis
%       welchRate    rate from prrWelch.m, Hz
%       welchPower, welchF   Welch PSD and frequency axis
%       agree        true if acfRate and welchRate are within 10% of each
%                     other, or of a small-integer ratio of each other
%
% Example
%     bpFilt = fir1(8, [50 250]/(sampleRate/2), 'bandpass');
%     [pulse, unit] = prrTwoScale(wav, sampleRate, bpFilt);
%     fprintf('pulse: ACF=%.3f Hz  Welch=%.3f Hz  agree=%d  isTonal=%d\n', ...
%         pulse.acfRate, pulse.welchRate, pulse.agree, pulse.acfIsTonal);
%     fprintf('unit:  ACF=%.2f s   Welch=%.2f s   agree=%d\n', ...
%         1/unit.acfRate, 1/unit.welchRate, unit.agree);

if nargin < 4 || isempty(pulseCfg)
    pulseCfg = struct('outputRate', 200, 'envCutoffHz', 20, ...
        'searchBandHz', [1 10], 'nfft', 512, 'noverlap', 256);
end
if nargin < 5 || isempty(unitCfg)
    unitCfg = struct('outputRate', 10, 'envCutoffHz', 0.5, ...
        'searchBandHz', [0.05 1], 'nfft', 512, 'noverlap', 256);
end

pulse = oneScale(wav, sampleRate, bpFilt, pulseCfg);
unit  = oneScale(wav, sampleRate, bpFilt, unitCfg);

function out = oneScale(wav, sampleRate, bpFilt, cfg)

[out.acfRate, out.acfIsTonal, out.acf, out.acfLags] = prrAutocorr( ...
    wav, sampleRate, bpFilt, cfg.outputRate, cfg.envCutoffHz, cfg.searchBandHz);

[out.welchRate, out.welchPower, out.welchF] = prrWelch( ...
    wav, sampleRate, bpFilt, cfg.outputRate, cfg.envCutoffHz, cfg.searchBandHz, ...
    cfg.nfft, cfg.noverlap);

ratio = out.acfRate / out.welchRate;
nearestInt = max(1, round(ratio));
out.agree = abs(ratio/nearestInt - 1) < 0.1 || abs((1/ratio)/round(1/ratio) - 1) < 0.1;

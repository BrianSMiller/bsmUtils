function [wav, sampleRate, truePrr] = synthPulseTrain(prrHz, f0Hz, durationSec, sampleRate, model, sigmaSec, snrDb)
% SYNTHPULSETRAIN  Synthetic pulsed signal with known pulse repetition rate.
%
% Generates one of the two pulsed-sound models from Patris et al. 2019
% Sec. II B, for testing PRR estimators against ground truth.
%
%   Model A (tonal): sum of identical Gaussian-windowed tone bursts, each
%   referenced to its own local time, repeated at period 1/prrHz:
%       s(t) = sum_n gauss(t - n*Tpulse) .* sin(2*pi*f0*(t - n*Tpulse))
%   Spectral peaks fall at integer multiples of prrHz (paper eq. 3).
%
%   Model B (non-tonal): a single continuous tone at f0Hz, amplitude
%   modulated by a train of Gaussian envelopes at period 1/prrHz:
%       s(t) = sin(2*pi*f0*t) .* sum_n gauss(t - n*Tpulse)
%   Spectral peaks are at f0Hz +/- n*prrHz, not integer multiples of prrHz
%   in general (paper eq. 7).
%
% Inputs
%   prrHz        true pulse repetition rate, Hz
%   f0Hz         carrier / pulse tone frequency, Hz
%   durationSec  signal duration, seconds
%   sampleRate   sample rate, Hz
%   model        'A' (default) or 'B'
%   sigmaSec     Gaussian pulse/envelope width parameter, seconds (default 0.02)
%   snrDb        white noise added at this SNR, dB (default Inf, no noise)
%
% Outputs
%   wav        synthetic signal, column vector, peak-normalized to +/-1
%              before noise is added
%   sampleRate returned unchanged, for convenience in test scripts
%   truePrr    returned unchanged (equals prrHz), for convenience in test scripts
%
% Example
%     [wav, fs, truePrr] = synthPulseTrain(6, 31.7, 4, 48000, 'A');
%     [wavNT, ~, ~]      = synthPulseTrain(6, 31.7, 4, 48000, 'B');

if nargin < 5 || isempty(model),    model = 'A';    end
if nargin < 6 || isempty(sigmaSec), sigmaSec = 0.02; end
if nargin < 7 || isempty(snrDb),    snrDb = Inf;     end

t = (0:1/sampleRate:durationSec)';
Tpulse = 1/prrHz;
pulseTimes = 0:Tpulse:durationSec;

switch upper(model)
    case 'A'
        wav = zeros(size(t));
        for k = 1:numel(pulseTimes)
            tLocal = t - pulseTimes(k);
            wav = wav + exp(-tLocal.^2/(2*sigmaSec^2)) .* sin(2*pi*f0Hz*tLocal);
        end
    case 'B'
        env = zeros(size(t));
        for k = 1:numel(pulseTimes)
            env = env + exp(-(t-pulseTimes(k)).^2/(2*sigmaSec^2));
        end
        wav = env .* sin(2*pi*f0Hz*t);
    otherwise
        error('synthPulseTrain:badModel', 'model must be ''A'' or ''B''.');
end

wav = wav / max(abs(wav));

if isfinite(snrDb)
    sigPower = mean(wav.^2);
    noisePower = sigPower / (10^(snrDb/10));
    wav = wav + sqrt(noisePower) * randn(size(wav));
end

truePrr = prrHz;

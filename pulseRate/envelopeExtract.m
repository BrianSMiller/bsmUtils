function [env, envRate] = envelopeExtract(x, sampleRate, cutoffHz, outputRate)
% ENVELOPEEXTRACT  Square-law envelope with lowpass smoothing and decimation.
%
% Implements the envelope detection step of Patris et al. 2019 (Sec. III C):
% square the signal, lowpass filter to smooth, then decimate.
%
% Inputs
%   x          bandpassed signal, row or column vector
%   sampleRate sample rate of x, Hz
%   cutoffHz   lowpass cutoff frequency for the envelope, Hz
%              (Patris et al. used a 5th-order Butterworth at 10 Hz)
%   outputRate target sample rate for the decimated envelope, Hz
%
% Outputs
%   env        envelope, decimated to outputRate, column vector
%   envRate    actual sample rate of env (may differ slightly from
%              outputRate if sampleRate/outputRate is not an integer)

x = x(:)';
sq = x.^2;

[b, a] = butter(5, cutoffHz / (sampleRate/2), 'low');
sqSmooth = filtfilt(b, a, sq);

decimFactor = round(sampleRate / outputRate);
env = sqSmooth(1:decimFactor:end);
envRate = sampleRate / decimFactor;

env = env(:);

function [isTonal, ratios, residuals] = checkTonal(peakFreqs, deltaF, tolerance)
% CHECKTONAL  Test whether peak frequencies are integer multiples of deltaF.
%
% Implements the tonal/non-tonal classification of Patris et al. 2019,
% Sec. II A: a pulsed sound is tonal if fi = ki*deltaF for integers ki.
% If tonal, the autocorrelation function is an unbiased PRR estimator
% (their Sec. II B/C). If not tonal, autocorrelation of the raw signal is
% biased, though autocorrelation of the envelope still works.
%
% This is a heuristic threshold, not a statistical test. Default tolerance
% is unvalidated against your data; tune it against known-tonal recordings
% before trusting isTonal on marginal-SNR detections.
%
% Inputs
%   peakFreqs  vector of measured spectral peak frequencies, Hz
%   deltaF     candidate pulse rate (band interval), Hz
%   tolerance  max allowed deviation from nearest integer, as a fraction
%              of one integer step (default 0.1)
%
% Outputs
%   isTonal    true if all peaks are within tolerance of an integer multiple
%   ratios     peakFreqs / deltaF
%   residuals  |ratios - round(ratios)|, deviation from nearest integer

if nargin < 3 || isempty(tolerance)
    tolerance = 0.1;
end

ratios = peakFreqs(:) / deltaF;
residuals = abs(ratios - round(ratios));
isTonal = all(residuals < tolerance);

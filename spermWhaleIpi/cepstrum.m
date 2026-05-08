function [cep, q] = cepstrum(timeSig, sampleRate)
% Compute the cepstrum, cep, of a time domain signal, and its associated
% quefrency (time) vector;

if nargin < 2;
    sampleRate = 1;
end

cep = [];
if isnan(timeSig) | ~isfinite(timeSig);
    return;
end
n = length(timeSig);
numUniquePts = ceil((n+1)/2);
cep = abs(ifft(log(abs(fft(timeSig)))));
cep = cep(1:numUniquePts,:);

q = (0:numUniquePts-1)/sampleRate;  
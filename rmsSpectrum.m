function [rmsLevel, specDev] = rmsSpectrum(magSpectrum,bins,freqBands);
% rmsLevel = rmsSpectrum(magSpectrum,bins,freqBands);
% Compute the rms level in dB re 1 (unit) over a particular bandwidth
% (freqBands). The inputs to this function are the magnitude of the
% spectrum (magSpectrum), a a vector the same size as magSpectrum where
% each value represents the centre of the respective frequency bin of the
% spectrum (bins), and (freqBands), an <N x 2> array where each row
% corresponds to a low and high frequency of a band to be included in the
% RMS level calculation.
% specVar is the variance of the magnitude spectrum;
binIx = zeros(size(bins));
for j = 1:size(freqBands,1)
    binIx = bins >= freqBands(j,1) & bins <= freqBands(j,2) | binIx;
end

% Levels are RMS using parsevals theorem - see signalEnergyInBand.m
% Levels are in linear units here: take 20*log10(rmsLevel) to convert to dB
magSpectrumSquared = (magSpectrum(binIx)/2).^2;
rmsLevel = sqrt(2*sum(magSpectrumSquared)); 
specDev = sqrt(2*var(magSpectrum));
% 
% plot(bins,magSpectrum)
% hold on;
% plot(xlim,rmsLevel*[1 1],'k');
% plot(xlim,repmat(rmsLevel - specDev, 2),'r--')
% xlim(freqBands)


% function [filteredSig, lowCut, highCut, freqs, kernel] = 
%           brickwall(signal, sampleRate, lowFreq, highFreq, dB, show);
% Brickwall bandpass digital filter using FFT to do filtering in frequency domain
%
% --Input arguments--
% SIGNAL:      Column vector containing time domain signal to be filtered. 
%              If SIGNAL is a matrix, the brick wall will be applied to each
%              column
% SAMPLERATE:  scalar containing the sampling rate for the time domain signal.
% LOWFREQ:     scalar specifying the lower corner frequency (Hz) of the filter 
% HIGHFREQ:    scalar specifying the upper corner frequency (Hz) of the filter.
% DB:          Scalar specifying the attenuation factor in dB. 20 means that 
%              the passband is one order of magnitude above the stop band.
%
% --Output arguments--
% FILTEREDSIG: The filtered time domain signal
% LOWCUT:      The actual corner of the high pass filter. 
% HIGHCUT:     The actual corner of the low pass filter
% FREQS:       Vector containing the frequencies that correspond to the fft
%              bins.
%
% --Note--
% LOWCUT and HIGHCUT may be slightly different than the requested LOWFREQ and
% HIGHFREQ due to the discrete nature of FFT frequency bins, which is based
% on the SAMPLERATE and the number of samples in the SIGNAL.
% B.S. Miller 2006-03-08 brianseth@gmail.com
function [filteredSig, lowCut, highCut, freqs] = brickwall(signal, sampleRate, lowFreq, highFreq, dB, show);

% Input error checking
if nargin < 6
    show = 0;
end
if nargin < 5
    dB = inf;   % If attenuation is not specified, then make it infinite!
end
if nargin < 4
    disp('Error: Four input arguments are required.');
    disp('[filteredSig, lowCut, highCut, freqs] = brickwall(signal, sampleRate, lowFreq, highFreq)');
end
dim = size(signal);
if dim(1) == 1 & isvector(signal); signal = signal'; end % Convert signal to a column vector
if ~isscalar(sampleRate) | ~isreal(sampleRate)
    disp('sampleRate must be a real scalar');
end
n = length(signal);

% Pad signal to be a power of 2-1
z = 2^nextpow2(n)-n-1;
if z < 0
    signal = signal(1:end+z);
    n = length(signal);
else
    signal  = [signal; zeros(z,size(signal,2))];
end
nSample = length(signal);

nFreqs = floor(nSample/2);
freqs = [-nFreqs:nFreqs]' * (sampleRate/nSample); % Create vector containing positive and negative frequencies

[val, iLow] = min(abs(freqs-lowFreq));
[val, iHigh] = min(abs(freqs-highFreq));
lowCut = freqs(iLow);   % Actual low frequency cutoff (Hz)
highCut = freqs(iHigh); % Actual high frequency cutoff (Hz)
if lowCut < highCut;
    passband = 10^(-dB/20) + ((abs(freqs) >= lowCut) & (abs(freqs) <= highCut)); % Frequencies in this range will be passed
else
    passband = 10^(-dB/20) + ~((abs(freqs) >= highCut) & (abs(freqs) <= lowCut)); % Frequencies in this range will be passed
end

% If the signal is a matrix, then make a matrix containing the passband in each column.
if dim(2) > 1;
    for count = 1:dim(2);
        passband(:,count) = passband(:,1);
    end
end

fftSig = fft(signal);
fftSig = fftshift(fftSig);
try
    fftFiltered = fftSig .* passband;
catch
    keyboard;
end
filteredSig = ifftshift(fftFiltered);
filteredSig = ifft(filteredSig,'symmetric');
filteredSig = filteredSig(1:n,:);
signal = signal(1:n,:);

% % If no output is specified, then plot the results
if nargout == 0 | show == 1;
    figure;
    for count = 1:dim(2);
        subplot(2,dim(2),count);
        plot(freqs,abs(fftSig(:,count)/nSample),freqs,passband(:,count),freqs,abs(fftFiltered(:,count)/nSample));
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        title(['Spectrum channel ' num2str(count)]);
        legend('Unfiltered','Brickwall filter','Filtered');
        subplot(2,dim(2),count+dim(2));
        % plot([1:nSample],signal(:,count),[1:nSample],filteredSig(:,count));
        plot([1:n],signal(:,count),[1:n],filteredSig(:,count));
        xlabel('Sample number');
        ylabel('Amplitude');
        title(['Waveforms channel ' num2str(count)]);
        legend('Original Signal',['Filtered Signal']);
        pause(0.5);
    end
end
freqs = ifftshift(freqs);
% if nargout == 5
%     kernel = ifft(ifftshift(passband));
% end
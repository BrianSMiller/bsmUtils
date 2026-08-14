function [prrMax, prrPower, f] = prr(wav, sampleRate, bpFilt, outputRate, nfft, noverlap)
% Calculate Pulse Repetition Rate for acoustic data via the tEST method from:
%     Klink, H. 2008. “Automated passive acoustic detection, localization and
%     identification of leopard seals: From hydro-acoustic technology to leopard
%     seal ecology,” Reports on Polar and Marine Research. Alfred Wegener
%     Institute for Polar and Marine Research, Bremerhaven, Vol. 582, p. 154
%
% Example - crabeater
%     wavFile = fullfile('S:\presentations\0_CuratedSounds\Crabeater seal',...
%         'Crabeater seal low and high moans - Brian Miller - Australian Antarctic Division - Casey 2014-10-29_16h.wav');
% 
%     [wav sampleRate] = audioread(wavFile);
%     filterBand = [200 2000];
%     bpFilt = fir1(8,filterBand/sampleRate,'bandpass');
%     outputRate = 1000;
%     nfft = 256;
%     noverlap = 128;
%     prr(wav, sampleRate, bpFilt, outputRate, nfft, noverlap)

% Example - Antarctic minke
%     wavFile = 'S:\brian_mil\Documents\Students\Aimee\codeAndData\Slide_WavFiles_9.5.24\2716_CallType_1A.wav';
%     [wav sampleRate] = audioread(wavFile);
%     filterBand = [50 200];
%     bpFilt = fir1(8,filterBand/sampleRate,'bandpass');
%     outputRate = 100;
%     nfft = 128;
%     noverlap = 64;
%     prr(wav, sampleRate, bpFilt, outputRate, nfft, noverlap)

showPlot = true;
if nargout == 0 
    showPlot = true;
end

t = (0:length(wav)-1)/sampleRate;


% x = filtfilt(bpFiltsampleRate,1,wav);
x = filter(bpFilt,1,wav);
% 
tStep = 1/outputRate; % in seconds
tStepDatenum = tStep * 86400;
newTimes = t(1):tStep:t(end); 
envelope = timeMax(abs(x'), t, newTimes, tStepDatenum);

% envelope = max(reshape([x; zeros(12-rem(length(x),12),1)],[],12),[],2);
[prrPower, f] = pwelch(envelope-mean(envelope),nfft,noverlap,nfft,outputRate);

freqBand = [0 floor(outputRate/2)];
ix = f>freqBand(1) & f <= freqBand(2); 
prrPower(~ix) = nan(size(find(~ix)));
[~, maxIx] = max(prrPower);
prrMax = f(maxIx);

if showPlot 
    subplot(2,1,1);
    plot(t,x, newTimes, envelope)   
    xlabel('time (s)');
    ylabel('wav amplitude');
    subplot(2,1,2);
    plot(f,prrPower); 
    hold on; 
    plot(prrMax,prrPower(maxIx),'ro');
    xlabel('Pulse Repetition Rate (Hz)');
    ylabel('PRR Power');
    drawnow;
end

% function output = timeMax(signal, signalTime, timeVector, timeWindow, quant)
% Compute the max of values in a time series within timeWindow seconds 
%
% This function is intended for use with signals that have been irregularly
% sampled in time. For regularly sampled signals see movAvg.
% 
% timeVector is a 1xN array containing matlab DATENUMS, while TIMEWINDOW is
% the duration of the moving average 'box' in SECONDS.
%
% modified on 2009-01-14 to ignore NaNs in the signal vector
function output = timeMax(signal, signalTime, timeVector, timeWindow)
len = length(timeVector);
output = nan(size(timeVector));

for count = 1:len
    t = timeVector(count);
    ix = find((abs(t-signalTime)*86400 <= timeWindow) & ~isnan(signal));
    if ~isempty(ix)
        output(count) = max(signal(ix));
    end
end
output = output(:);
% function output = timeQuantile(signal, signalTime, timeVector, timeWindow, quant)
% Compute the quantile of values in a time series within timeWindow seconds 
%
% This function is intended for use with signals that have been irregularly
% sampled in time. For regularly sampled signals see movAvg.
% 
% timeVector is a 1xN array containing matlab DATENUMS, while TIMEWINDOW is
% the duration of the moving average 'box' in SECONDS.
%
% modified on 2009-01-14 to ignore NaNs in the signal vector
function output = timeQuantile(signal, signalTime, timeVector, timeWindow, quant)
len = length(timeVector);
output = nan(size(timeVector));

for count = 1:len
    t = timeVector(count);
    ix = find((abs(t-signalTime)*86400 <= timeWindow) & ~isnan(signal));
    if ~isempty(ix)
        output(count) = prctile(signal(ix),quant);
    end
end
output = output(:);
% function output = movAvg(signal,window)
% Compute the moving average for a SIGNAL using WINDOW number of samples
% for the size of the average.  Moving average is a type of low pass
% digital filter. Note: The last WINDOW points cannot be averaged properly.
function output = movAvg(signal,window)
len = length(signal);
output = zeros(window,len+window);

for count = 1:window % Create shifted copies of the signal to be summed
    output(count,count:len+count-1) = signal;
end
output = mean(output);
output = output(window:len+window-1);
output(end-window+1:end) = ones(1,window) .* output(end-window);
output = output(:);
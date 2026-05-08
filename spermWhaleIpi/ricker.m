function [wavelet, t] = ricker(f, duration, dt)
% RICKER_WAVELET Generate a Ricker wavelet (Mexican hat wavelet)
%
% Inputs:
%   f        - Central frequency in Hz
%   duration - Total duration of the wavelet in seconds
%   dt       - Sampling interval in seconds (optional, default: 0.001)
%
% Outputs:
%   wavelet  - The Ricker wavelet amplitude values
%   t        - Time vector
%
% Example:
%   [w, t] = ricker_wavelet(25, 0.2, 0.001);
%   plot(t, w);
%   xlabel('Time (s)'); ylabel('Amplitude');
%   title('Ricker Wavelet');
if nargin == 0
    plotExamples
end


% Set default sampling interval if not provided
if nargin < 3
    dt = 0.001; % 1 ms default sampling
end

% Create time vector centered at zero
t = -duration/2:dt:duration/2;

% Calculate the Ricker wavelet
% The formula: A(t) = (1 - 2π²f²t²) * exp(-π²f²t²)
pf2t2 = (pi * f * t).^2;
wavelet = (1 - 2*pf2t2) .* exp(-pf2t2);

% Normalize to unit amplitude
wavelet = wavelet / max(abs(wavelet));

if nargout == 0
    plot(t, wavelet, 'LineWidth', 1.5);
    grid on;
    xlabel('Time (s)');
    ylabel('Amplitude');
    title(sprintf('f = %g Hz, duration = %f s',1/dt, duration));
end
end

function plotExamples()
% Example usage and visualization
% Generate wavelets with different parameters
figure;

% Example 1: Short duration, high frequency
subplot(2,2,1);
[w1, t1] = ricker(50, 0.1);
plot(t1, w1, 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('f = 50 Hz, duration = 0.1 s');

% Example 2: Medium duration, medium frequency
subplot(2,2,2);
[w2, t2] = ricker(25, 0.2);
plot(t2, w2, 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('f = 25 Hz, duration = 0.2 s');

% Example 3: Long duration, low frequency
subplot(2,2,3);
[w3, t3] = ricker(10, 0.5);
plot(t3, w3, 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('Amplitude');
title('f = 10 Hz, duration = 0.5 s');

% Example 4: Frequency spectrum
subplot(2,2,4);
[w4, t4] = ricker(25, 0.2);
N = length(w4);
freq = (-N/2:N/2-1)/(N*(t4(2)-t4(1)));
spectrum = abs(fftshift(fft(w4)));
plot(freq, spectrum, 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Frequency Spectrum (f = 25 Hz)');
xlim([0 100]);

sgtitle('Ricker Wavelet Examples');
end
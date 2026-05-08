function [click, t] = sperm_whale_click(peak_freq, duration, dt, click_type)
% SPERM_WHALE_CLICK Generate realistic sperm whale click sounds
%
% Inputs:
%   peak_freq  - Peak frequency in kHz (typical range: 2-30 kHz)
%   duration   - Total duration in milliseconds (typical: 0.1-1 ms)
%   dt         - Sampling interval in seconds (optional, default: 1e-6 for 1 MHz)
%   click_type - 'usual' (default) or 'creak' for foraging
%
% Outputs:
%   click - The click waveform
%   t     - Time vector in milliseconds
%
% Example:
%   [click, t] = sperm_whale_click(15, 0.5, 1e-6, 'usual');
%   plot(t, click);

if nargin == 0
    showExamplePlots
    return;
end

% Set defaults
if nargin < 3, dt = 1e-6; end  % 1 MHz sampling
if nargin < 4, click_type = 'usual'; end

% Convert duration to seconds
duration_s = duration * 1e-3;

% Create time vector (not centered - clicks are asymmetric)
t_s = 0:dt:duration_s;
t = t_s * 1e3;  % Convert to ms for output

% Convert frequency to Hz
f = peak_freq * 1e3;

% Generate asymmetric click based on type
switch click_type
    case 'usual'
        % Regular echolocation click: sharp rise, exponential decay
        % Multiple frequency components with damping
        env = exp(-t_s * 8000);  % Fast exponential decay

        % Multi-component signal (sperm whale clicks have harmonics)
        carrier1 = sin(2*pi*f*t_s);
        carrier2 = 0.5*sin(2*pi*f*1.5*t_s);  % Harmonic
        carrier3 = 0.3*sin(2*pi*f*2*t_s);    % Second harmonic

        click = env .* (carrier1 + carrier2 + carrier3);

        % Add sharp initial transient (characteristic of whale clicks)
        initial_spike = exp(-t_s * 50000) .* sin(2*pi*f*3*t_s);
        click = click + 0.4*initial_spike;

    case 'creak'
        % Foraging creak: shorter, simpler clicks
        env = exp(-t_s * 15000);  % Even faster decay
        carrier = sin(2*pi*f*t_s);
        click = env .* carrier;
end

% Normalize
click = click / max(abs(click));
end

function showExamplePlots
% Example usage and visualization
figure('Position', [100 100 1200 800]);

% Example 1: Typical echolocation click (15 kHz)
subplot(3,3,1);
[c1, t1] = sperm_whale_click(15, 0.5, 1e-6, 'usual');
plot(t1, c1, 'LineWidth', 1);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Echolocation Click (15 kHz, 0.5 ms)');

% Example 2: Lower frequency click (5 kHz)
subplot(3,3,2);
[c2, t2] = sperm_whale_click(5, 0.8, 1e-6, 'usual');
plot(t2, c2, 'LineWidth', 1);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Lower Frequency Click (5 kHz, 0.8 ms)');

% Example 3: High frequency click (25 kHz)
subplot(3,3,3);
[c3, t3] = sperm_whale_click(25, 0.3, 1e-6, 'usual');
plot(t3, c3, 'LineWidth', 1);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('High Frequency Click (25 kHz, 0.3 ms)');

% Example 4: Foraging creak
subplot(3,3,4);
[c4, t4] = sperm_whale_click(10, 0.2, 1e-6, 'creak');
plot(t4, c4, 'LineWidth', 1);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Foraging Creak (10 kHz, 0.2 ms)');

% Example 5: Frequency spectrum of typical click
subplot(3,3,5);
[c5, t5] = sperm_whale_click(15, 0.5, 1e-6, 'usual');
Fs = 1e6;  % Sampling frequency
N = length(c5);
freq = (0:N-1)*(Fs/N)/1000;  % Convert to kHz
spectrum = abs(fft(c5));
plot(freq(1:floor(N/2)), spectrum(1:floor(N/2)), 'LineWidth', 1.5);
grid on;
xlabel('Frequency (kHz)');
ylabel('Magnitude');
title('Spectrum of 15 kHz Click');
xlim([0 50]);

% Example 6: Click sequence (like actual whale behavior)
subplot(3,3,6);
click_train = zeros(1, 50000);
[single_click, ~] = sperm_whale_click(15, 0.5, 1e-6, 'usual');
% Add clicks at ~0.5 second intervals
positions = [1, 10000, 20000, 30000, 40000];
for i = 1:length(positions)
    pos = positions(i);
    click_train(pos:pos+length(single_click)-1) = single_click;
end
t_train = (0:length(click_train)-1) * 1e-6 * 1e3;
plot(t_train, click_train, 'LineWidth', 0.5);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Click Train (Search Pattern)');

% Example 7: Creak sequence (rapid clicks during prey capture)
subplot(3,3,7);
creak_train = zeros(1, 5000);
[creak_click, ~] = sperm_whale_click(10, 0.2, 1e-6, 'creak');
% Rapid clicks (~20 ms intervals)
creak_positions = 1:500:4500;
for i = 1:length(creak_positions)
    pos = creak_positions(i);
    creak_train(pos:pos+length(creak_click)-1) = creak_click;
end
t_creak = (0:length(creak_train)-1) * 1e-6 * 1e3;
plot(t_creak, creak_train, 'LineWidth', 0.5);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Creak Sequence (Foraging)');

% Example 8: Spectrogram of click
subplot(3,3,8);
[c8, ~] = sperm_whale_click(15, 0.5, 1e-6, 'usual');
spectrogram(c8, 128, 120, 256, 1e6, 'yaxis');
ylim([0 50]);
title('Spectrogram of Click');
colorbar off;

% Example 9: Waveform comparison
subplot(3,3,9);
[usual, t_usual] = sperm_whale_click(15, 0.5, 1e-6, 'usual');
[creak, t_creak] = sperm_whale_click(15, 0.2, 1e-6, 'creak');
plot(t_usual, usual, 'LineWidth', 1.5, 'DisplayName', 'Usual Click');
hold on;
plot(t_creak, creak, 'LineWidth', 1.5, 'DisplayName', 'Creak');
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
title('Click Type Comparison');
legend('Location', 'best');

sgtitle('Sperm Whale Click Synthesis');

% Display info
fprintf('Sperm Whale Click Parameters:\n');
fprintf('- Typical frequency range: 2-30 kHz\n');
fprintf('- Click duration: 0.1-1 ms\n');
fprintf('- Inter-click interval: 0.5-2 seconds (search)\n');
fprintf('- Creak rate: 10-200 clicks/second (foraging)\n');
end
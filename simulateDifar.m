function [simSig omni sinChan cosChan t] = simulateDifar(duration, sampleRate, theta, magneticDeviation, simFreq)
% simSig = simulateDifar(duration, sampleRate, theta, magneticDeviation)
% Create a simulated difar signal. The signal has a deviation from magnetic
% north equal to magneticDeviation, and the emitted signal appears to be
% coming from direction theta with respect to the reference axis. The
% duration of the signal is specified in seconds.
% 
% Example: a nine second long 28 Hz tone at 45 degrees
% duration = 9;         % seconds
% simFreq  = 28;        % Hz
% magneticDeviation = 0;% radians
% theta  = 45 * pi/180; % radians
% sampleRate = 48000;    % Hz
% [simSig omni ew ns] = simulateDifar(duration, sampleRate, theta, magneticDeviation, simFreq);
%
% Ported to Matlab by B.S. Miller from Greenridge Science DIFAR_demux.cpp

t = [0:duration * sampleRate - 1]/sampleRate;

fPilot = 7500.0;
w75 = 2.0 * pi * fPilot;	% simulated 7.5 kHz pilot freq, rad/sec
A = 0.2;					% simulated pilot amplitude, V

% emitter is at an angle (magneticDeviation + theta) w/ respect to mag north

phase = mod(w75 * t, 2.0*pi);       % simulated input signal phase, rad
ti75 = sin(phase);                 % simulated 7.5 kHz pilot, V
ti15 = sin(2.0*phase + pi);        % 'phase' of 15 kHz tone w.r.t. the 7.5 kHz tone is arbitrary

signalType = 'chirp';
switch signalType
    case 'tone'
        % fake acoustic data is a single CW tone @ simFreq Hz
        s = 1.0 * sin(2.0 * pi * simFreq * t); 
    case 'chirp'
        s = chirp(t,simFreq,t(end),100,'logarithmic');
end
% theta = pi/6.0;               % angle of emitter w/ respect to +reference axis, rad (measured CW)
% magneticDeviation = 0.0;                    % angle from mag north to +reference axis, rad (measured CW)

omni = s;                       % simulated 'omni' signal, V
cosChan = s * -cos(theta);      % cosine information channel (item d of 3.6.4.6.3 in MIL-S-81487D)
sinChan = s *  sin(theta);      % sine information channel (item e of 3.6.4.6.3 in MIL-S-81487D)

ns = cosChan .*  cos(2.0*phase + magneticDeviation);   % simulated 'north-south' modulated signal, V
ew = sinChan .* -sin(2.0*phase + magneticDeviation);   % simulated 'east-west' modulated signal, V

noise = 0 * A * 0.01 * randn(size(t));
simSig = A * (ti75 + ti15 + omni + ew + ns + noise)'; % simulated composite multiplexed Difar signal, V




function [mag, phase, freqs, p] = fftMagPhase(fftData,sampleRate);
% [mag phase freqs p] = fftMagPhase(fftData,sampleRate);
% Plot the magnitude and phase as subplots as a function of frequency (Hz).
% Calculates frequency bins, and only plots the positive bins.
%
% %assume you have an N length sinusoidal of the form
% 
% x[n] = A sin(wn)
% 
% and find a spectrum coefficient of magnitude A*N/2 (provided
% the frquency w is an integer fraction of the sampling frequency
% w = m/N, m < N/2).
% 
% First the factor 1/2. The spectrum of a real-valued signal is
% conjugate symmetric, meaning one real-valed sinusoidal is
% represented as two complex-valued sinusoidals according
% to Eulers formula,
% 
% A*sin(x) = A*(exp(jx)-exp(-jx))/j2.
% 
% These two complex-valued sinusoidals have magnitde
% A/2, so if you plot only the range [0,fs/2] you need to
% scale by a factor 2 to recover A.
% 
% Second, the factor N. The DFT is a set of vector products
% between the input signal x and N complex elements of
% unit magnitude:
% 
% X[k] = sum_n=0^N-1 A*exp(j*2*pi*k*n/N)*exp(-j*2*pi*k*n/N)
%       = N*A
% 
% To recover A, one needs to divide by N.
N = length(fftData);
posBins = 1:N/2;
freqs = (posBins-1) * sampleRate/N;
fftData = fftData(posBins,:)/N;
% Multiply by 2 because we're dealing with real signals and only showing
% the positive frequency bins of the spectrum. For real signals, the DFT
% will split the magnitude of the spectrum evenly across both positive and
% negative frequencies.
mag   = 2*abs(fftData);
phase = angle(fftData)*180/pi;
% 
% p(1) = subplot(211);
% plot(freqs,mag,'.-')
% p(2) = subplot(212);
% plot(freqs,phase,'.-');
% linkaxes(p,'x');
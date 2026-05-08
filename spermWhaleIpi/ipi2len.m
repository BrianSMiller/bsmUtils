% function len = ipi2len(ipi)
% Calculate the length of a sperm whale based on the measured inter-pulse interval
% Using the second order equation from Rhinelander and Dawson JASA 2004.
% ipi: Inter-pulse interval in milliseconds
% growcott: Length of whale using equation from Growcott et al 2011
% gordon: Length of whale using equation from Gordon 1991
% rhinelander: Length of whale using equation from Rhinelander & Dawson2004
% NB: All lengths are in metres
function [growcott, gordon, rhinelander, dickson] = ipi2len(ipi)
if nargin < 1 
    ipi = 3:0.1:9;
end
% Rhinelander & Dawson
rhinelander = 0.251 .* ipi.^2 - 2.189 .* ipi + 17.120;
gordon =  4.833 + 1.453 .* ipi - 0.001 .* ipi.^2;
growcott = 1.258 .* ipi + 5.736;
dickson = 0.9016 * ipi + 8.593;

if nargin < 1
    plot(ipi, [gordon; rhinelander; growcott; dickson],'linewidth',2)
    legend({'Gordon 1991'; 'Rhinelander 2001'; 'Growcott 2011'; 'Dickson 2021'},'location','southeast'); grid
    xlabel('IPI (ms)'); ylabel('Total length (m)');
end
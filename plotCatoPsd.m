function hCato = plotCatoPsd(showWind,showTraffic,showRain,showBio)
dataFolder = 's:\data\Cato1995\';

if nargin < 4; showBio = false; end
if nargin < 3; showRain = false; end
if nargin < 2; showTraffic = false; end
if nargin < 1; showWind = false; end

holding = ishold;
hCato = [];
i = 1;

catoLow = readtable(fullfile(dataFolder,'Usual lowest ocean noise.csv'),...
    'ReadVariableNames',false);
catoLow.Properties.VariableNames = {'frequency_Hz','spectrumLevel_dB'};
hCato(i) = plot(catoLow.frequency_Hz,catoLow.spectrumLevel_dB,'-',...
    'lineWidth',1,'Color',0.5*[1 1 1],'DisplayName','Usual quiet ocean');
hold on;
i = i+1;

if showWind
cato30kt = readtable(fullfile(dataFolder,'30 knots.csv'), ...
    'ReadVariableNames',false);
cato30kt.Properties.VariableNames = {'frequency_Hz','spectrumLevel_dB'};
hCato(i) = plot(cato30kt.frequency_Hz,cato30kt.spectrumLevel_dB, '-',...
    'lineWidth',2,'Color',0.5*[1 1 1],'DisplayName','30 knot winds');
i = i+1;
end

if showTraffic
catoDeep = readtable(fullfile(dataFolder,'Remote deep traffic.csv'), ...
    'ReadVariableNames',false);
catoDeep.Properties.VariableNames = {'frequency_Hz','spectrumLevel_dB'};
hCato(i) = plot(catoDeep.frequency_Hz,catoDeep.spectrumLevel_dB, '-.',...
    'lineWidth',1,'Color',0.5*[1 1 1],'DisplayName','Traffic (Remote deep)');
i = i+1;

catoInd = readtable(fullfile(dataFolder,'Indian Ocean Traffic.csv'), ...
    'ReadVariableNames',false);
catoInd.Properties.VariableNames = {'frequency_Hz','spectrumLevel_dB'};
hCato(i) = plot(catoInd.frequency_Hz,catoInd.spectrumLevel_dB, '--',...
    'lineWidth',1,'Color',0.5*[1 1 1],'DisplayName','Traffic (Indian Ocean)');
i = i+1;
end

if showRain
catoRain = readtable(fullfile(dataFolder,'Heavy rain.csv'), ...
    'ReadVariableNames',false);
catoRain.Properties.VariableNames = {'frequency_Hz','spectrumLevel_dB'};
hCato(i) = plot(catoRain.frequency_Hz,catoRain.spectrumLevel_dB,'-.', ...
    'lineWidth',2,'Color',0.5*[1 1 1],'DisplayName','Heavy rain');
i = i+1;
end
if showBio
catoChorus = readtable('s:\data\Cato1995\Animal chorus max.csv', ...
    'ReadVariableNames',false);
catoChorus.Properties.VariableNames = {'frequency_Hz','spectrumLevel_dB'};
hCato(i) = plot(catoChorus.frequency_Hz,catoChorus.spectrumLevel_dB,'--',...
    'lineWidth',2,'Color',0.5*[1 1 1],'DisplayName','Animal chorus');
i = i+1;

catoEvening = readtable(fullfile(dataFolder,'Evening chorus.csv'), ...
    'ReadVariableNames',false);
catoEvening.Properties.VariableNames = {'frequency_Hz','spectrumLevel_dB'};
hCato(i) = plot(catoEvening.frequency_Hz,catoEvening.spectrumLevel_dB, ...
    'lineWidth',2,'Color',0.5*[1 1 1],'lineStyle','--', ...
    'DisplayName','Evening chorus');
end

hLeg2 = legend(hCato,'location','southwest');
hLeg2.Title.String='Archetypal Australian noise spectral densities (Cato 1997)';
hLeg2.Location="southoutside";
hLeg2.NumColumns=3;

if holding
    hold on;
else
    hold off;
end
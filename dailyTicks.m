function dailyTicks(ax)
if nargin < 1
    ax = gca;
end
% Add some minor tick marks for each day
dv = xlim;
% ticks = floor(dv(1)):1:ceil(dv(2));
ticks = dateshift(dv(1),'start','day'):1:dateshift(dv(2),'end','day');
yScaler = get(ax,'tickLength');
switch get(gca,'yscale')
    case 'log';
        yLim = ylim;
        y = 0.1 * yLim(1);    
    otherwise % use linear scale
        y = diff(ylim)*yScaler(1)*2;
end
yLim = ylim;
held = ishold;
hold on;
hMinorTickBottom = plot([ticks; ticks], [zeros(size(ticks)); ones(size(ticks)).*y]+yLim(1),'k');
hMinorTickTop = plot([ticks; ticks], [zeros(size(ticks)); -ones(size(ticks)).*y]+yLim(2),'k');

% Return to previous hold state
if held==0
    hold off;
end
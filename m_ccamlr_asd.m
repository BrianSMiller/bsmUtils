function [handles, hText] = m_ccamlr_asd(lonLim, latLim)
% handles = m_ccamlr_asd(lonLim, latLim)
% Plot CCAMLR boundaries for [larger] Areas, Subareas, Divisions
if nargin < 1
    lonLim = [0 360];
end
if nargin < 2
    latLim = [-90 90];
end
handles = [];
persistent b;
color = [1, 0.6471 ,0];

%% CCAMLR Boundaries
if isempty(b)
    b = m_shaperead('c:\analysis\m_map\ccamlr\asd-shapefile-WGS84');
end
held = ishold;
hold on;
for i = 1:length(b.ncst); 
    % convert negative longitudes to between 180 and 360
    lon = lonWestTo360(b.ncst{i}(:,1));
    lat = b.ncst{i}(:,2);
    txt = b.dbf.LongLabel{i};
    % Skip if bounding box is off the map
    if lonWestTo360(b.mbr(i,1)) <= lonLim(1) || lonWestTo360(b.mbr(i,3)) <= lonLim(1) ||...
       lonWestTo360(b.mbr(i,1)) >= lonLim(2) || lonWestTo360(b.mbr(i,3)) >= lonLim(2) ||...
       b.mbr(i,2) <= latLim(1) || b.mbr(i,2) >= latLim(2)
        continue;
    end
    handles(i) = m_plot(lon, lat,'clip','on');
    hText(i) = m_text(mean(lonWestTo360(lon)),mean(lat)+2,...
        ['  ' txt],'color',color,'horiz','center',...
        'verticalAlign','baseline');
%     m_hatch(lon,lat,'single');
    set(handles(i),'color',color);
end
if ~held
hold('off');
end
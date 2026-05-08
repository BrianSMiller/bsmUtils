function handles = m_ccamlr_ssru(lonLim, latLim)
% handles = m_ccamlr_ssru(lonLim, latLim)
% Plot CCAMLR boundaries for Small Scale Research Units (SSRU)
if nargin < 1
    lonLim = [-180 400];
end
if nargin < 2
    latLim = [-90 90];
end
persistent b;

%% CCAMLR Boundaries
if isempty(b)
    b = m_shaperead('c:\analysis\m_map\ccamlr\ssru-shapefile-WGS84');
end
for i = 1:length(b.ncst); 
    % convert negative longitudes to between 180 and 360
    lon = lonWestTo360(b.ncst{i}(:,1));
    lat = b.ncst{i}(:,2);
    % Skip if bounding box is off the map
    if lonWestTo360(b.mbr(i,1)) < lonLim(1) || lonWestTo360(b.mbr(i,3)) < lonLim(1) ||...
       lonWestTo360(b.mbr(i,1)) > lonLim(2) || lonWestTo360(b.mbr(i,3)) > lonLim(2)
        continue;
    end
    handles(i) = m_plot(lon, lat,'clip','off');
    set(handles(i),'color',[1, 0.6471 ,0]);
end
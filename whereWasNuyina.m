function underwayData = whereWasNuyina(oldestDate,youngestDate)
% Where was Nuyina?
% Get Voyage data on Nuyina's location from AADC and plot it on a map.
addpath('c:\analysis\m_map\');
addpath('c:\analysis\longTermRecorders\')

if nargin < 2
    youngestDate = now;
end
if nargin < 1
    oldestDate = youngestDate - 7;
end
if oldestDate > youngestDate
    temp = youngestDate;
    youngestDate=oldestDate;
    oldestDate=temp;
end


% New API endpoint
baseUrl = 'https://data.aad.gov.au/voyagedata/api/underwaymerger/';
voyageId = 'latest'; % Update this for different voyages
dataType = ''; % or 'meteorology', 'oceanography', etc.
url = [baseUrl, voyageId];

% Fetch the data as JSON
options = weboptions('ContentType', 'json', 'Timeout', 30);
try
    data = webread(url, options);
catch ME
    error('Failed to fetch data: %s', ME.message);
end

% Convert the numbered struct fields to arrays
fieldNames = fieldnames(data);
numRecords = length(fieldNames);

% Preallocate arrays
latitude = zeros(numRecords, 1);
longitude = zeros(numRecords, 1);
date_time = cell(numRecords, 1);

% Extract data from numbered fields
% Note: MATLAB converts 'latitude-[deg]' to 'latitude__deg_'
for i = 1:numRecords
    record = data.(fieldNames{i});
    latitude(i) = record.latitude__deg_;
    longitude(i) = record.longitude__deg_;
    date_time{i} = record.date_time;
end

% Create table
underwayData = table(latitude, longitude, date_time, 'VariableNames', {'latitude', 'longitude', 'date_time'});

% Convert datetime strings to MATLAB datetime objects
% Format appears to be: "2025-09-14 02:00"
underwayData.datetime = datetime(underwayData.date_time, 'InputFormat', 'yyyy-MM-dd HH:mm');

% Filter by date range
mask = underwayData.datetime >= datetime(oldestDate, 'ConvertFrom', 'datenum') & ...
       underwayData.datetime < datetime(youngestDate, 'ConvertFrom', 'datenum');
underwayData = underwayData(mask, :);

% Filter bad GPS points
underwayData(underwayData.latitude==0,:)=[];

if isempty(underwayData)
    error('No data available for the specified date range');
end

[~, ix] = max(underwayData.datetime);

lat(1) = min(underwayData.latitude-1);
lat(2) = max(underwayData.latitude+1);
lon(1) = min(underwayData.longitude-1);
lon(2) = max(underwayData.longitude+1);

lat = [-70 -40];
lon = [60 180];

c = loadRecorderMetaData('casey');
k = loadRecorderMetaData('kerguelen');

[dates, times, ticks, datef, timef] = getTrackParams(oldestDate,youngestDate);

m_proj('utm','lat',lat,'lon',lon);
m_gshhs_i('patch','linecolor',0.3*[1 1 1]);
hold on;

% Convert datetime to datenum for m_track
datenum_track = datenum(underwayData.datetime);

m_track(underwayData.longitude, underwayData.latitude, datenum_track, ...
    'Color','r','linewidth',1,'orien','upright','ticks',ticks, ...
    'dateformat',datef,'timeformat',timef,'times',times,'dates',dates);
m_grid;

% Plot current position
m_plot(underwayData.longitude(ix), underwayData.latitude(ix), 'ko', ...
    'markerFaceColor','r','markerSize',8);

latest = sprintf('Latest:\n%s', datestr(underwayData.datetime(ix),'mmm dd\nHH:MM'));
m_text(underwayData.longitude(ix), underwayData.latitude(ix), latest, ...
    'horizontalAlign','center','verticalAlign','bottom', ...
    'color','k','margin',15);

m_plot(c(end).longitude, c(end).latitude, 'ks', 'markerFaceColor','b')
m_plot(k(end).longitude, k(end).latitude, 'ks', 'markerFaceColor','b')

title(sprintf('Voyage track %s to %s', datestr(oldestDate,31), datestr(youngestDate,31)))

end

function [dates, times, ticks, datef, timef] = getTrackParams(oldestDate,youngestDate)
dates = 60*24;  % minutes
times = 60*12;  % minutes
ticks = 60*1;   % minutes
datef = 'mmm dd';
timef = 'HH:MM';

if  youngestDate-oldestDate > 7
    times = 60*24;  % minutes
    dates = 60*24;  % minutes
    ticks = 60*6;   % minutes
    datef = 'mmm dd';
    timef = '';
end

if  youngestDate-oldestDate > 30
    times = 60*24*2;    % minutes
    dates = 60*24*2;    % minutes
    ticks = 60*12;      % minutes
    datef = 'mmm dd';
    timef = '';
end

if  youngestDate-oldestDate > 60
    times = 60*24*7;   % minutes
    dates = 60*24*7;   % minutes
    ticks = 60*24;   % minutes
    datef = 'mmm dd';
    timef = '';
end
end
% function underwayData = whereIsNuyina(oldestDate,youngestDate)
% % Where is Nuyina?
% % Get underway data on Nuyina's location from AADC and plot it on a map.
% addpath('c:\analysis\m_map\');
% addpath('c:\analysis\longTermRecorders\')
% if nargin < 2
%     youngestDate = now;
% end
% if nargin < 1
%     oldestDate = youngestDate - 7;
% end
% if oldestDate > youngestDate
%     temp = youngestDate;
%     youngestDate=oldestDate;
%     oldestDate=temp;
% end
% % 
% % % testUrl = 'https://data.aad.gov.au/geoserver/underway/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=underway%3Anuyina_underway_2023&outputFormat=csv&SORTBY=datetime%20ASC&cql_filter=datetime%20GTE%202023-12-24T00:00:00Z%20AND%20datetime%20LT%202023-12-25T00:00:00Z';
% % baseUrl = 'https://data.aad.gov.au/geoserver/underway/ows?service=WFS&version=1.0.0&';
% % queryStr = 'request=GetFeature&typeName=underway%3Anuyina_underway_2023&outputFormat=csv&SORTBY=datetime%20ASC&';
% % dateForm = 'yyyy-mm-ddTHH:MM:SSZ';
% % dateQuery = sprintf('cql_filter=datetime%%20GTE%%20%s%%20AND%%20datetime%%20LT%%20%s', ...
% %     datestr(oldestDate,dateForm),datestr(youngestDate,dateForm));
% % New API endpoint pattern
% baseUrl = 'https://data.aad.gov.au/voyagedata/api/underwaymerger/';
% voyageId = '202526VT1'; % Update this for different voyages
% dataType = 'navigation'; % or 'meteorology', 'oceanography', etc.
% 
% url = [baseUrl, voyageId, '/', dataType];
% 
% % Fetch the data
% options = weboptions('ContentType', 'json');
% data = webread(url, options);
% 
% 
% % websave('nuyina.csv',[baseUrl,queryStr,dateQuery]);
% % d = readtable("nuyina.csv");
% % underwayData = webread([baseUrl,queryStr,dateQuery]);
% underwayData(find(underwayData.latitude==0),:)=[];
% [~, ix] = max(underwayData.datetime);
% lat(1) = min(underwayData.latitude-1);
% lat(2) = max(underwayData.latitude+1);
% lon(1) = min(underwayData.longitude-1);
% lon(2) = max(underwayData.longitude+1);
% lat = [-70 -40];
% lon = [60 180];
% 
% c = loadRecorderMetaData('casey');
% k = loadRecorderMetaData('kerguelen');
% 
% 
% [dates, times, ticks, datef, timef] = getTrackParams(oldestDate,youngestDate);
% 
% 
% m_proj('utm','lat',lat,'lon',lon);
% m_gshhs_i('patch','linecolor',0.3*[1 1 1]);
% hold on;
% m_track(underwayData.longitude,underwayData.latitude,datenum(underwayData.datetime), ...
%     'Color','r','linewidth',1,'orien','upright','ticks',ticks, ...
%     'dateformat',datef,'timeformat',timef,'times',times,'dates',dates);
% m_grid;
% 
% % Filter bad GPS points.
% 
% 
% m_plot(underwayData.longitude(ix),underwayData.latitude(ix),'ko', ...
%     'markerFaceColor','r','markerSize',8);
% latest = sprintf('Latest:\n%s',datestr(datetime,'mmm dd\nHH:MM'));
% m_text(underwayData.longitude(ix),underwayData.latitude(ix),latest, ...
%     'horizontalAlign','center','verticalAlign','bottom', ...
%     'color','k','margin',15);
% m_plot(c(end).longitude,c(end).latitude,'ks','markerFaceColor','b')
% m_plot(k(end).longitude,k(end).latitude,'ks','markerFaceColor','b')
% title(sprintf('Voyage track %s to %s',datestr(oldestDate,31),datestr(youngestDate,31)))
% 
% function [dates, times, ticks, datef, timef] = getTrackParams(oldestDate,youngestDate)
% 
% dates = 60*24;  % minutes
% times = 60*12;  % minutes
% ticks = 60*1;   % minutes
% datef = 'mmm dd';
% timef = 'HH:MM';
% 
% if  youngestDate-oldestDate > 7
%     times = 60*24;  % minutes
%     dates = 60*24;  % minutes
%     ticks = 60*6;   % minutes
%     datef = 'mmm dd';
%     timef = '';
% 
% end
% if  youngestDate-oldestDate > 30
%     times = 60*24*2;    % minutes
%     dates = 60*24*2;    % minutes
%     ticks = 60*12;      % minutes
%     datef = 'mmm dd';
%     timef = '';
% end
% 
% if  youngestDate-oldestDate > 60
%     times = 60*24*7;   % minutes
%     dates = 60*24*7;   % minutes
%     ticks = 60*24;   % minutes
%     datef = 'mmm dd';
%     timef = '';
% end
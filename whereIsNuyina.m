function underwayData = whereIsNuyina(oldestDate,youngestDate)
% Where is Nuyina?
% Get underway data on Nuyina's location from AADC and plot it on a map.
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

% New API endpoints
baseUrl = 'https://data.aad.gov.au/voyagedata/api/underwaymerger/';

% Try latest endpoint first (current voyage)
latestUrl = [baseUrl, 'latest'];
options = weboptions('ContentType', 'json', 'Timeout', 30);

try
    disp('Fetching latest voyage data...');
    data = webread(latestUrl, options);
    isLatestFormat = true;
catch ME
    % If latest fails, try archived voyage format
    disp('Latest endpoint failed, trying archived voyage...');
    voyageId = '202526VT1'; % Update this for specific archived voyages
    archivedUrl = [baseUrl, voyageId, '/navigation'];
    try
        data = webread(archivedUrl, options);
        isLatestFormat = false;
    catch ME2
        error('Failed to fetch data from both endpoints: %s', ME2.message);
    end
end

% Parse data based on format
if isLatestFormat
    % Latest format: array of objects with _time field
    numRecords = length(data);
    
    % Preallocate arrays
    latitude = zeros(numRecords, 1);
    longitude = zeros(numRecords, 1);
    timestamps = zeros(numRecords, 1);
    
    % Extract data
    for i = 1:numRecords
        record = data(i);
        latitude(i) = record.latitude__deg_;
        longitude(i) = record.longitude__deg_;
        timestamps(i) = record.x_time; % Unix timestamp
    end
    
    % Convert Unix timestamps to MATLAB datetime
    datetimes = datetime(timestamps, 'ConvertFrom', 'posixtime');
    
else
    % Archived voyage format: numbered struct fields with date_time strings
    fieldNames = fieldnames(data);
    numRecords = length(fieldNames);
    
    % Preallocate arrays
    latitude = zeros(numRecords, 1);
    longitude = zeros(numRecords, 1);
    date_time = cell(numRecords, 1);
    
    % Extract data from numbered fields
    for i = 1:numRecords
        record = data.(fieldNames{i});
        latitude(i) = record.latitude__deg_;
        longitude(i) = record.longitude__deg_;
        date_time{i} = record.date_time;
    end
    
    % Convert datetime strings to MATLAB datetime objects
    datetimes = datetime(date_time, 'InputFormat', 'yyyy-MM-dd HH:mm');
end

% Create table
underwayData = table(latitude, longitude, datetimes, ...
    'VariableNames', {'latitude', 'longitude', 'datetime'});

% Filter by date range
mask = underwayData.datetime >= datetime(oldestDate, 'ConvertFrom', 'datenum') & ...
       underwayData.datetime < datetime(youngestDate, 'ConvertFrom', 'datenum');
underwayData = underwayData(mask, :);

% Filter bad GPS points
underwayData(underwayData.latitude==0,:)=[];

if isempty(underwayData)
    warning('No data available for the specified date range');
    return;
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
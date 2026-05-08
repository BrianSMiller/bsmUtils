function [depth, lon, lat, d] = bathyLine(lon1,lat1,lon2,lat2,interval)
% depth = bathyLine(lon1,lat1,lon2,lat2,interval)
% Extract bathymetry along great circle path between two points. Interval
% is specified in km. Requires m_map and etopo2 database.
% 
% lon1 = 142.0850; % Location of 1st sighting (good whale)
% lat1 = -62.2198;
% lon2 = 158.3568; % Location of 1st sonobuoy that detected ABW
% lat2 = -51.4077;

distance = m_idist(lon1,lat1,lon2,lat2)/1e3; % distance in km;
numPoints = round(distance/interval)+1;
[d lon lat] = m_geodesic(lon1,lat1,lon2,lat2,numPoints); % km spacing
depth = nan(size(d));
for i = 1:length(d);  
    [elev , ~, ~] = m_etopo2([lon(i) lon(i) lat(i) lat(i)]); 
    depth(i) = mean(mean(elev));
end

%% Write bathymetry file that can be used by software in the 
% Ocean Acoustics Library 
if 0;
    fid = fopen('test.bty','w');
    fprintf(fid,'''C''\n'); % Curvilinear fit
    fprintf(fid,'%g\n',length(z)); % Number of observations
    fprintf(fid,'%4.1f %4.1f\n',[d(:)/1e3 z(:)]')
    fclose(fid);
end
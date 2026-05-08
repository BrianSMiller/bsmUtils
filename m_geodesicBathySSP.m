function [depth lon lat z ssp] = m_geodesicBathySSP(lon1,lat1,lon2,lat2,interval)
% depth = bathyLine(lon1,lat1,lon2,lat2,interval)
% Extract bathymetry along great circle path between two points. Interval
% is specified in km. Requires m_map and etopo2 database.
% 
if nargin == 0;
    lon1 = 142.0850; % Location of 1st sighting (good whale)
    lat1 = -62.2198;
    lon2 = 158.3568; % Location of 1st sonobuoy that detected ABW
    lat2 = -51.4077;
    interval = 10;
end
distance = m_idist(lon1,lat1,lon2,lat2)/1e3; % distance in km;
numPoints = floor(distance/interval);
[d lon lat] = m_geodesic(lon1,lat1,lon2,lat2,numPoints); % km spacing
depth = nan(size(d));
[ssp z] = getlev(lat,lon,'c');
for i = 1:length(d); 
%     [elev longit latit] = m_etopo2([lon(i) lon(i) lat(i) lat(i)]); 
    [elev, ~, ~,] = readetopo1(lon(i), lat(i), lon(i), lat(i)); 
    depth(i) = mean(mean(elev));
%     ix = find(-z < depth(i));
%     ssp(ix,i) = nan(size(ix));
end

%% Plot results
if 1
    figure;
%     hSurf = pcolor(d./1e3,-z,ssp);
    [hContour c] = contourf(d./1e3,-z,ssp,[1400:1:1520]);
%     clabel(hContour,c);
%     set(hSurf,'linestyle','none');
    set(c,'lineStyle','none');
    [sspMin depthIx] = min(ssp);
    hold on;
%     plot(d./1e3,-z(depthIx),'ko');
    yLim = ylim;
    yLim(1) = min(yLim(1),min(depth));
    fill([d(1); d; d(end); d(1)]/1e3,[yLim(1) depth' yLim(1) yLim(1)],'k')
    xlabel('range (km)');
    ylabel('depth (m)');
    hCb = colorbar;
    ylabel(hCb,'Sound Speed (m/s)');
end

if 1
    figure;
    [hContour c] = contourf(lat,-z,ssp,[1400:1:1520]);
    set(c,'lineStyle','none');
    [sspMin depthIx] = min(ssp);
    hold on;
    yLim = ylim;
    yLim(1) = min(yLim(1),min(depth));
    fill([lat(1); lat; lat(end); lat(1)],[yLim(1) depth' yLim(1) yLim(1)],'k')
    xlabel('Latitude');
    ylabel('depth (m)');
    hCb = colorbar;
    ylabel(hCb,'Sound Speed (m/s)');
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
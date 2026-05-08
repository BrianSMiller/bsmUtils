function [eta, distance_km, duration_h, course_diff, speed_kt, nuyina] = nuyinaDistToMooring(site)
addpath('c:\analysis\stats\CircStat\')
m = loadRecorderMetaData(site);
nuyina = whereIsNuyina(now-7,now);
lat = [m.latitude];
lon = [m.longitude];
[dist_m, az] = m_idist(nuyina.longitude(end),nuyina.latitude(end),lon,lat);
distance_km = dist_m/1e3;
speed_kt = nuyina.platform_speed_wrt_ground(end);
duration_h = distance_km/nuyina.platform_speed_wrt_ground(end)/1.854;
course_diff = circ_dist(az*pi/180,nuyina.platform_course_true(end)*pi/180)*180/pi;
eta = max(nuyina.datetime)+hours(duration_h);
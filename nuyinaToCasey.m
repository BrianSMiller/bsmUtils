function nuyinaDistToMooring(site)
m = loadRecorderMetaData(site)
nuyina = whereIsNuyina(now,now-1);
m_idist(nuyina.longitude(end),nuyina.latitude(end),mean([m.longitude]),mean([m.latitude]))/nuyina.platform_speed_wrt_ground(end)/1.854/1e3
function lon = lonWestTo360(lon)
% Convert negative longitudes (West longitudes) from [-180,0] to [180,360]
ix = find(lon < 0);
lon(ix) = lon(ix) + 360;

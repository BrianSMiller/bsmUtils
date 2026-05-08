function lon = lon360ToWest(lon)
% Convert negative longitudes (West longitudes) from [-180,0] to [180,360]
ix = find(lon >180);
lon(ix) = -360+lon(ix);

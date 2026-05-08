function season = dt2season(dt)
% Convert a datetime to a season as per months:
% 12, 1, 2 summer 
% 3,  4, 5 autumn
% 6,  7, 8 winter
% 9, 10, 11 spring
seasons = {'summer','summer',...
    'autumn','autumn','autumn',...
    'winter','winter','winter',...
    'spring','spring','spring',...
    'summer'};

season = seasons(month(dt));
if all(size(season') == size(dt))
    season = season';
end
season = categorical(season,{'summer','autumn','winter','spring','year'},...
    'Ordinal',true);
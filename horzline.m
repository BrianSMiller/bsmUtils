function h = horzline(x,linespec,varargin)
% h = horzline(x);
% Plot a horizontal line at (y-intercept) position x.
% Return line handle (h).
%
% DEPRECATED: yline() is a MATLAB built-in since R2018b and is a better
% alternative. Consider replacing calls to horzline with yline.
warning('horzline:deprecated', ...
    'horzline is deprecated. Use yline() instead (available since R2018b).');
h = [];
if nargin < 2
    linespec = '-';
end
if nargin < 3
    varargin = {};
end
hs = ishold;
lim = get(gca,'xlim');
hold on;
for i = 1:length(x)
    if isnumeric(linespec)
        h(i) = plot(lim, x(i)*[1 1],'color',linespec);
    else
        h(i) = plot(lim, x(i)*[1 1],linespec);
    end
    for j = 1:length(varargin)/2
        set(h(i),varargin{j},varargin{j+1})
    end
end
if ~hs; hold off; end 


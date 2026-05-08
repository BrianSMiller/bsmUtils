function h = horzline(x,linespec,varargin)
% h = horzline(x);
% Plot a horizontal line at (y-intercept) position x;
% Return line handle (h);
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


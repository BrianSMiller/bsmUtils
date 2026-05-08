function h = vertline(x,linespec,varargin)
% h = vertline(x);
% Plot a vertical line at position x;
% Return line handle (h);
h = [];
if nargin < 2
    linespec = 'b-';
end
if nargin < 3
    varargin = {};
end
hs = ishold;
ylim = get(gca,'ylim');
hold on;
for i = 1:length(x)
    if isnumeric(linespec)
        h(i) = plot(repmat(x(i),1,2),ylim,'color',linespec);
    else
        h(i) = plot(repmat(x(i),1,2),ylim,linespec);
    end
    for j = 1:length(varargin)/2
        set(h(i),varargin{j},varargin{j+1})
    end
end
if ~hs; hold off; end 


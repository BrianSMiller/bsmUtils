function h = plotSquare(width, height, color, varargin)
l = width(1);
r = width(2);
b = height(1);
t = height(2);
h = fill([l, r, r, l],...
          [b, b, t, t], 0);
    set(h,'edgecolor',color,varargin{:})

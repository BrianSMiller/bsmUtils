function h = plotBox(width, height, color, varargin)
l = width(1);
r = width(2);
b = height(1);
t = height(2);
h = plot([l, r, r, l, l],...
          [b, b, t, t, b]);
    set(h,'color',color,varargin{:})

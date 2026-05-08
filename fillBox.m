function h = plotBox(width, height, varargin)
l = width(1);
r = width(2);
b = height(1);
t = height(2);
ps = polyshape([l, r, r, l],...
          [b, b, t, t]);
h = plot(ps)
%     set(h,'color',color,varargin{:})

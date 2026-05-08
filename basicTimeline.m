% h = basicTimeline(x,y,label);
function h = basicTimeline(x,y,label);
if nargin < 2
    overlap = 1;
    if overlap
        y =ones(size(x,1),1);
    else
        y = 0.01*[1:size(x,1)]; 
        y = y(:);
    end
end

y = repmat(y,1,2);
h = plot(x',y','linewidth',100);
% set(h,'color',0.5 * [1 1 1]);
if nargin == 3
    text(x(:,1),y(:,1),label);
end
datetick('x');
function out = structFilter(in,ix);
% out = structFilter(in,ix);
% Filter a structure where each field contains vectors of the same length
% Indicies, ix, will be removed from each field
out = in;
fn = fieldnames(out);
remove = intersect(ix,1:length(out.(fn{1})));
for i =1:length(fn);
    out.(fn{i})(remove) = [];
end 
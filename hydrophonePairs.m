function [pair] = hydrophonePairs(n)
% Function returns all possible hydrophone pairings given n hydrophones
% Pairs are returned in each row, with each column containing a hydrophone
% numberered 1-n.
ch = 1:n;
com = 1; 
pair = [];
for i = 1:length(ch)-1; 
    for j = i+1:length(ch); 
        pair(com,1) = ch(i);
        pair(com,2) = ch(j);
        com=com+1;
    end;
end;
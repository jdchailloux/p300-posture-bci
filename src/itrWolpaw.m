function itr = itrWolpaw(n, p, t)
% ITRWOLPAW  Information transfer rate (bits/min) according to Wolpaw et al. (2002).
%   n: number of selectable items; p: accuracy in [0,1]; t: time per selection (s).
%   Returns 0 when p is below chance level (1/n).

if p < 1/n
    itr = 0;
elseif p == 1
    itr = log2(n) * 60 / t;
else
    itr = (log2(n) + p*log2(p) + (1-p)*log2((1-p)/(n-1))) * 60 / t;
end
end

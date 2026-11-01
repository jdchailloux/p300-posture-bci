function [isCorrect, detectionTime] = onlineSelections(rec)
% ONLINESELECTIONS  Outcome and detection time of each online selection.
%   A selection trial starts with marker 101-109 (cued item = code - 100) and
%   ends with the BCI decision 1001-1009 (selected item = code - 1000). The
%   detection time is measured from the start marker to the decision marker.

mk = rec.marker;
idx = find(mk ~= 0);
isCorrect = false(0, 1);
detectionTime = zeros(0, 1);
startIdx = NaN;
startCode = NaN;
for k = idx'
    if mk(k) >= 101 && mk(k) <= 109
        startIdx = k;
        startCode = mk(k);
    elseif mk(k) >= 1001 && mk(k) <= 1009 && ~isnan(startIdx)
        isCorrect(end+1, 1) = startCode - 100 == mk(k) - 1000; %#ok<AGROW>
        detectionTime(end+1, 1) = (k - startIdx + 1) / rec.fs; %#ok<AGROW>
    end
end
end

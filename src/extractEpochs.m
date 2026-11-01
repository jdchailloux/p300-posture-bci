function [epochs, isTarget] = extractEpochs(rec, tPre, tPost, chans)
% EXTRACTEPOCHS  Flash-locked epochs of a training recording.
%   [epochs, isTarget] = extractEpochs(rec, 0.2, 0.8, 1:8) returns epochs
%   (samples x channels x flashes) from -tPre to tPost seconds (sample of the
%   flash included at index round(tPre*fs)+1) and a logical vector that is
%   true for flashes of the cued item. A stimulation phase starts with marker
%   101-109 (cued item = code - 100) and ends with marker 200.

mk = rec.marker;
pre = round(tPre * rec.fs);
post = round(tPost * rec.fs);
starts = find(mk >= 101 & mk <= 109);
stops = find(mk == 200);

epochs = zeros(pre + post, numel(chans), 0);
isTarget = false(0, 1);
for r = 1:numel(starts)
    cue = mk(starts(r)) - 100;
    stop = stops(find(stops > starts(r), 1));
    flashes = starts(r) + find(mk(starts(r)+1:stop-1) >= 1 & mk(starts(r)+1:stop-1) <= 9);
    for i = flashes'
        if i - pre < 1 || i + post - 1 > numel(mk), continue, end
        epochs(:, :, end+1) = rec.eeg(i-pre:i+post-1, chans); %#ok<AGROW>
        isTarget(end+1, 1) = mk(i) == cue; %#ok<AGROW>
    end
end
end

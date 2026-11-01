function rec = loadRecording(cfg, sub, posture, run)
% LOADRECORDING  Reads one recording of the public CSV dataset.
%   rec = loadRecording(cfg, "sub-01", "SIT", "training") returns a struct with
%   fields eeg (samples x 8, microvolts), marker (samples x 1), labels, fs.

file = fullfile(cfg.datasetDir, sub, sub + "_task-p300_acq-" + lower(posture) + "_run-" + run + "_eeg.csv");
opts = detectImportOptions(file);
opts = setvartype(opts, "double");
T = readtable(file, opts);
rec.labels = string(T.Properties.VariableNames(2:9));
rec.eeg    = T{:, 2:9};
rec.marker = T.marker;
rec.fs     = cfg.fs;
end

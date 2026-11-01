% export_dataset.m
% Converts the posture-study recordings from the proprietary BrainTec .ebr
% format to open, documented CSV files for public deposition (e.g., Zenodo).
% Provided for transparency only: it requires the original (non-public) .ebr
% files and the BrainTec reader readBinaryEbrFile.m; codeDir and dataDir point
% to the authors' local folders.
%
% - Participants are renamed sub-XX following the numbering of the paper.
% - The absolute TIMESTAMP channel of the .ebr files (date and time of the
%   session) is removed; time is given in seconds from the start of the file.
% - Participant 2 (folder S5): only the offline training files are exported
%   (the Oz electrode failed and the online SIT file is a copy of another
%   participant's file).
% - notas.txt and the photographs are NOT exported (they identify participants).
%
% Output: ../dataset_export/

scriptDir = fileparts(mfilename("fullpath"));
codeDir = "<folder containing readBinaryEbrFile.m>";       % authors' local BrainTec code
dataDir = "<folder with the original .ebr recordings>";    % non-public raw data
outDir  = fullfile(scriptDir, "..", "dataset_export");
addpath(codeDir)  % readBinaryEbrFile.m

% Paper participant number, source folder, posture order, online data available
P = table((1:10)', ["S4" "S5" "S6" "S7" "S8" "S9" "S10" "S12" "S13" "S14"]', ...
    ["SUP-SIT" "SUP-SIT" "SIT-SUP" "SIT-SUP" "SUP-SIT" "SUP-SIT" "SUP-SIT" "SUP-SIT" "SIT-SUP" "SIT-SUP"]', ...
    [true false true true true true true true true true]', ...
    VariableNames=["Number" "Folder" "PostureOrder" "Online"]);

chanNames = ["Fz" "Cz" "P3" "Pz" "P4" "PO7" "PO8" "Oz"];
fs = 256;
if ~isfolder(outDir), mkdir(outDir); end

for i = 1:height(P)
    sub = sprintf("sub-%02d", P.Number(i));
    subDir = fullfile(outDir, sub);
    if ~isfolder(subDir), mkdir(subDir); end
    phases = "training";
    if P.Online(i), phases = ["training" "online"]; end
    for phase = phases
        for posture = ["SIT" "SUP"]
            src = "Training 5 - "; if phase == "online", src = "Online 5 - "; end
            eeg = readBinaryEbrFile(char(fullfile(dataDir, P.Folder(i), "Sesion01", src + posture + ".ebr")));
            assert(isequal(string(eeg.channels(1:8))', chanNames), "Unexpected channel order")
            assert(eeg.sampRate == fs, "Unexpected sampling rate")
            d = squeeze(eeg.data);                    % samples x 10 (8 EEG, TIMESTAMP, MARK)
            n = size(d, 1);
            t = (0:n-1)' / fs;
            base = sub + "_task-p300_acq-" + lower(posture) + "_run-" + phase;

            % Continuous EEG (microvolts, 4 decimals: the .ebr samples are
            % single precision, so no information is lost) + marker column
            fid = fopen(fullfile(subDir, base + "_eeg.csv"), "w");
            fprintf(fid, "%s\n", strjoin(["time_s" chanNames "marker"], ","));
            fprintf(fid, "%.8f" + join(repmat(",%.4f", 1, 8), "") + ",%d\n", [t d(:, 1:8) d(:, 10)]');
            fclose(fid);

            % Events
            idx = find(d(:, 10) ~= 0);
            code = d(idx, 10);
            E = table(t(idx), idx - 1, code, describe(code), ...
                VariableNames=["onset_s" "sample" "code" "description"]);
            writetable(E, fullfile(subDir, base + "_events.csv"));
            fprintf("%s: %d samples, %d events\n", base, n, numel(idx));
        end
    end
end

% participants.csv
participants = table(compose("sub-%02d", P.Number), P.PostureOrder, P.Online, ...
    ["" "Oz electrode failed; online files not provided" "" "" "" "" "" "" "" ""]', ...
    VariableNames=["participant_id" "posture_order" "online_files" "notes"]);
writetable(participants, fullfile(outDir, "participants.csv"));

% channels.csv
channels = table([chanNames "marker"]', [repmat("EEG", 1, 8) "TRIGGER"]', [repmat("uV", 1, 8) "n/a"]', ...
    VariableNames=["name" "type" "units"]);
writetable(channels, fullfile(outDir, "channels.csv"));

function desc = describe(code)
    desc = strings(size(code));
    for k = 1:numel(code)
        c = code(k);
        if c >= 1 && c <= 9
            desc(k) = sprintf("flash of item %d", c);
        elseif c >= 101 && c <= 109
            desc(k) = sprintf("start of stimulation phase; cued target = item %d", c - 100);
        elseif c == 200
            desc(k) = "end of stimulation phase; start of rest phase";
        elseif c == 201
            desc(k) = "start of fixation phase";
        elseif c == 202
            desc(k) = "start of target presentation phase";
        elseif c == 203
            desc(k) = "start of preparation phase";
        elseif c >= 1001 && c <= 1009
            desc(k) = sprintf("online selection by the BCI: item %d", c - 1000);
        else
            desc(k) = "unknown";
        end
    end
end

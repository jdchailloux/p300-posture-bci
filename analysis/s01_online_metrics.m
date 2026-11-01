% S01_ONLINE_METRICS  Online accuracy, detection time and ITR (Table 2, Table S3).
% Output: output/online_metrics.csv

cfg = config();
rows = {};
for sub = cfg.validSubs
    for posture = cfg.postures
        rec = loadRecording(cfg, sub, posture, "online");
        [ok, dt] = onlineSelections(rec);
        acc = mean(ok);
        rows(end+1, :) = {sub, posture, numel(ok), acc, mean(dt(ok)), mean(dt), ...
            itrWolpaw(cfg.nItems, acc, mean(dt(ok))), itrWolpaw(cfg.nItems, acc, mean(dt))}; %#ok<SAGROW>
    end
end
T = cell2table(rows, VariableNames=["Participant" "Posture" "nTrials" "ACC" ...
    "DT_correct_s" "DT_all_s" "ITR_correct_bpm" "ITR_all_bpm"]);
if ~isfolder(cfg.outputDir), mkdir(cfg.outputDir); end
writetable(T, fullfile(cfg.outputDir, "online_metrics.csv"));

fprintf("\nOnline metrics (n = %d), mean +/- SD, paired Wilcoxon signed-rank test\n", numel(cfg.validSubs));
for v = ["ACC" "DT_correct_s" "ITR_correct_bpm" "DT_all_s" "ITR_all_bpm"]
    a = T.(v)(T.Posture == "SIT"); b = T.(v)(T.Posture == "SUP");
    fprintf("%-16s SIT %7.3f +/- %6.3f   SUP %7.3f +/- %6.3f   p = %.3f\n", ...
        v, mean(a), std(a), mean(b), std(b), signrank(a, b));
end

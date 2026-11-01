% S02_OFFLINE_CROSS_VALIDATION  Five-fold cross-validation accuracy (Table 1, Table S2).
% Pipeline (Mendoza-Montoya, 2018): epochs -0.2..1.0 s; rejection by amplitude
% (peak-to-peak > 200 uV or SD > 50 uV); FIR band-pass 4-14 Hz; trimming to
% 0..0.8 s; decimation by 4; CCA spatial filter (3 filters) and shrinkage LDA
% trained on the training folds; stratified 5-fold CV; balanced accuracy.
% Output: output/offline_cv.csv

cfg = config();
f = classification();
nFolds = 5;
nFilters = 3;
decim = 4;
bpf = designfilt("bandpassfir", FilterOrder=64, CutoffFrequency1=4, CutoffFrequency2=14, SampleRate=cfg.fs);

rows = {};
for sub = cfg.allSubs
    chans = 1:8;
    if ismember(sub, cfg.badOzSubs), chans = 1:7; end
    for posture = cfg.postures
        rec = loadRecording(cfg, sub, posture, "training");
        [epochs, labels] = extractEpochs(rec, 0.2, 1.0, chans);
        nRaw = numel(labels);

        [badAmp, highBeta] = f.reject(epochs, cfg.fs);
        epochs = epochs(:, :, ~badAmp);
        labels = labels(~badAmp);

        for k = 1:size(epochs, 3)
            epochs(:, :, k) = filtfilt(bpf, epochs(:, :, k));
        end
        t = (0:size(epochs, 1) - 1) / cfg.fs - 0.2;
        first = find(t >= 0, 1);
        X = epochs(first:decim:first + floor(0.8*cfg.fs) - 1, :, :);   % 51 samples (0-0.8 s)

        rng(1)   % reproducible folds
        cvp = cvpartition(labels, KFold=nFolds);
        accT = zeros(nFolds, 1); accN = zeros(nFolds, 1);
        for k = 1:nFolds
            tr = training(cvp, k); te = test(cvp, k);
            W = f.ccaFilter(X(:, :, tr & labels), nFilters);
            [w, b] = f.shrinkLDA(f.features(X(:, :, tr), W), labels(tr));
            pred = f.features(X(:, :, te), W) * w > b;
            accT(k) = mean(pred(labels(te)));
            accN(k) = mean(~pred(~labels(te)));
        end
        rows(end+1, :) = {sub, posture, nRaw, numel(labels), sum(labels), 100*mean(highBeta), ...
            (mean(accT) + mean(accN))/2, mean(accT), mean(accN)}; %#ok<SAGROW>
        fprintf("%s %s: global %.3f\n", sub, posture, rows{end, 7});
    end
end
T = cell2table(rows, VariableNames=["Participant" "Posture" "EpochsRaw" "EpochsKept" ...
    "TargetKept" "HighBetaPct" "Global" "Target" "NonTarget"]);
if ~isfolder(cfg.outputDir), mkdir(cfg.outputDir); end
writetable(T, fullfile(cfg.outputDir, "offline_cv.csv"));

fprintf("\nOffline cross-validation (n = %d), mean +/- SD, paired Wilcoxon signed-rank test\n", numel(cfg.allSubs));
for v = ["Global" "Target" "NonTarget" "HighBetaPct"]
    a = T.(v)(T.Posture == "SIT"); b = T.(v)(T.Posture == "SUP");
    fprintf("%-12s SIT %.3f +/- %.3f   SUP %.3f +/- %.3f   p = %.3f\n", v, mean(a), std(a), mean(b), std(b), signrank(a, b));
end

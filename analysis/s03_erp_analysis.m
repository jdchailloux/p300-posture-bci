% S03_ERP_ANALYSIS  ERP analysis of the nine valid participants (Figures 3-6, S1; Table S1).
% Pre-processing (FieldTrip): epochs -0.2..0.8 s, demean, linear detrend,
% line-noise DFT filter, 4-14 Hz band-pass, z-score artifact rejection (cut-off 12).
% Grand averages = mean of subject-level ERPs. Significance of each grand-average
% target ERP vs. its pre-stimulus baseline: kernel density estimate (alpha = 0.05).
% SIT vs SUP: paired Wilcoxon signed-rank test per channel and sample, with
% Benjamini-Hochberg FDR across post-stimulus channel-samples.
% Outputs: output/erp_trial_counts.csv, output/erp_subject_level.mat, output/figures/*.pdf

cfg = config();
if ~exist("ft_defaults", "file")
    if strlength(cfg.fieldtripDir) == 0
        error("FieldTrip not found: add it to the MATLAB path or set cfg.fieldtripDir in config.m")
    end
    addpath(cfg.fieldtripDir)
end
ft_defaults
global ft_default %#ok<GVMIS>
ft_default.feedback = 'no';

subjects = cfg.validSubs;
postures = cfg.postures;
alpha = 0.05;
nSub = numel(subjects);
figDir = fullfile(cfg.outputDir, "figures");
resDir = cfg.outputDir;
if ~isfolder(figDir), mkdir(figDir); end

%% Pre-processing and subject-level ERPs
erpT = [];   % subject x posture x channel x time (target)
erpN = [];   % idem (non-target)
counts = table();
for s = 1:nSub
    for p = 1:2
        rec = loadRecording(cfg, subjects(s), postures(p), "training");
        [epochs, isTarget] = extractEpochs(rec, 0.2, 0.8, 1:8);
        [clean1, n1] = preprocess(epochs(:, :, isTarget), rec);
        [clean0, n0] = preprocess(epochs(:, :, ~isTarget), rec);
        erpT(s, p, :, :) = mean(clean1, 3); %#ok<SAGROW>
        erpN(s, p, :, :) = mean(clean0, 3); %#ok<SAGROW>
        counts = [counts; table(subjects(s), postures(p), n1, size(clean1, 3), n0, size(clean0, 3), ...
            VariableNames=["Participant" "Posture" "TargetRaw" "TargetClean" "NonTargetRaw" "NonTargetClean"])]; %#ok<AGROW>
        fprintf("%s %s: %d/%d target and %d/%d non-target epochs kept\n", subjects(s), postures(p), ...
            size(clean1, 3), n1, size(clean0, 3), n0);
    end
end
time = linspace(-0.2, 0.8, size(epochs, 1));
labels = rec.labels;
nChan = numel(labels);
writetable(counts, fullfile(resDir, "erp_trial_counts.csv"));
save(fullfile(resDir, "erp_subject_level.mat"), "erpT", "erpN", "time", "labels", "subjects", "postures")

%% Grand averages and KDE significance (baseline -0.2..0 s)
gaT = squeeze(mean(erpT, 1));   % posture x channel x time
gaN = squeeze(mean(erpN, 1));
isBase = time >= -0.2 & time <= 0;
sigMask = zeros(2, nChan, numel(time));   % +1 positive, -1 negative
thr = zeros(2, nChan, 2);
for p = 1:2
    for c = 1:nChan
        x = squeeze(gaT(p, c, :))';
        base = x(isBase);
        thr(p, c, :) = ksdensity(base, [alpha/2 1-alpha/2], Function="icdf");
        cdfx = ksdensity(base, x, Function="cdf");
        sigMask(p, c, :) = (cdfx > 1 - alpha/2) - (cdfx < alpha/2);
    end
end

%% SIT vs SUP: paired signed-rank across participants, per channel and sample
pDiff = ones(nChan, numel(time));
for c = 1:nChan
    for t = 1:numel(time)
        pDiff(c, t) = signrank(erpT(:, 1, c, t), erpT(:, 2, c, t));
    end
end
post = time >= 0;
pPost = pDiff(:, post);
qPost = fdr_bh(pPost(:));
fprintf("SIT vs SUP: %d of %d post-stimulus channel-samples with p < %.2f; %d survive FDR (q < %.2f)\n", ...
    nnz(pPost < alpha), numel(pPost), alpha, nnz(qPost < alpha), alpha);
for c = 1:nChan
    idx = find(pDiff(c, :) < alpha & post);
    fprintf("%-4s significant (p<.05) post-stimulus samples: %s\n", labels(c), segments(time(idx)));
end
for p = 1:2
    for c = 1:nChan
        idx = find(squeeze(sigMask(p, c, :))' ~= 0 & post);
        fprintf("%s %-4s KDE-significant: %s\n", postures(p), labels(c), segments(time(idx)));
    end
end

%% Figures
colT = [0 0.447 0.741];
colN = [0.850 0.325 0.098];
colPos = [0.466 0.674 0.188];
colNeg = [0.850 0.325 0.098];
yl = ceil(max(abs([gaT(:); gaN(:)])) * 1.15 * 2) / 2;

% Figure 3: target vs non-target grand averages, 8 channels, per posture
for p = 1:2
    fig = figure(Color="w", Units="centimeters", Position=[2 2 18 11]);
    % 4x3 layout: Fz, Cz in the centre column; P3 Pz P4; PO7 Oz PO8; legend top right
    tl = tiledlayout(fig, 4, 3, TileSpacing="compact", Padding="compact");
    slotMap = dictionary(["Fz" "Cz" "P3" "Pz" "P4" "PO7" "Oz" "PO8"], [2 5 7 8 9 10 11 12]);
    for c = 1:nChan
        ax = nexttile(tl, slotMap(labels(c)));
        hold(ax, "on")
        x = squeeze(gaT(p, c, :))';
        shadeSig(ax, time, x, squeeze(sigMask(p, c, :))', squeeze(thr(p, c, :)), colPos, colNeg)
        plot(ax, time, squeeze(gaN(p, c, :)), Color=colN, LineWidth=1)
        plot(ax, time, x, Color=colT, LineWidth=1.3)
        styleAxes(ax, time, yl, labels(c))
        if labels(c) == "PO7"
            xlabel(ax, "Time (s)"), ylabel(ax, "\muV")
        end
    end
    axL = nexttile(tl, 3);
    hold(axL, "on")
    h = [plot(axL, nan, nan, Color=colT, LineWidth=1.3), plot(axL, nan, nan, Color=colN), ...
        patch(axL, nan, nan, colPos, EdgeColor="none"), patch(axL, nan, nan, colNeg, EdgeColor="none")];
    legend(axL, h, ["Target" "Non-target" "p > 0.975" "p < 0.025"], Location="north", Box="off");
    axis(axL, "off")
    title(axL, postures(p) + " (n = 9)", FontSize=9)
    exportgraphics(fig, fullfile(figDir, postures(p) + "_topo_9subs.pdf"), ContentType="vector");
    close(fig)
end

% Figure 4: map of KDE-significant deflections (channel x time), per posture
for p = 1:2
    fig = figure(Color="w", Units="centimeters", Position=[2 2 9 7]);
    ax = axes(fig);
    imagesc(ax, time, 1:nChan, squeeze(sigMask(p, :, :)))
    colormap(ax, [colNeg; 1 1 1; colPos]); clim(ax, [-1 1])
    xline(ax, 0, ":k", LineWidth=1.2)
    ax.YTick = 1:nChan; ax.YTickLabel = labels; ax.FontSize = 9;
    xlabel(ax, "Time (s)"), ylabel(ax, "Channel")
    title(ax, postures(p) + ": significant positive (green) / negative (orange) deflections", FontWeight="normal", FontSize=8)
    exportgraphics(fig, fullfile(figDir, "Sig_" + postures(p) + "_9subs.pdf"), ContentType="vector");
    close(fig)
end

% Figure 5: target ERP at PO8 with KDE thresholds, per posture
c8 = find(labels == "PO8");
for p = 1:2
    fig = figure(Color="w", Units="centimeters", Position=[2 2 9 7]);
    ax = axes(fig); hold(ax, "on")
    x = squeeze(gaT(p, c8, :))';
    shadeSig(ax, time, x, squeeze(sigMask(p, c8, :))', squeeze(thr(p, c8, :)), colPos, colNeg)
    yline(ax, thr(p, c8, 1), ":", Color=colNeg); yline(ax, thr(p, c8, 2), ":", Color=colPos)
    plot(ax, time, x, Color=colT, LineWidth=1.5)
    styleAxes(ax, time, yl, "PO8 - " + postures(p))
    xlabel(ax, "Time (s)"), ylabel(ax, "Amplitude (\muV)")
    exportgraphics(fig, fullfile(figDir, postures(p) + "_PO8_9subs.pdf"), ContentType="vector");
    close(fig)
end

% Figure 6a / S1: SIT vs SUP target ERPs with paired-test significance, per channel
for c = 1:nChan
    fig = figure(Color="w", Units="centimeters", Position=[2 2 9 7]);
    ax = axes(fig);
    plotSitVsSup(ax, time, squeeze(erpT(:, 1, c, :)), squeeze(erpT(:, 2, c, :)), pDiff(c, :), alpha, yl, labels(c))
    exportgraphics(fig, fullfile(figDir, "SIT_SUP_comparison_" + labels(c) + "_9subs.pdf"), ContentType="vector");
    close(fig)
end
fig = figure(Color="w", Units="centimeters", Position=[2 2 18 20]);
tl = tiledlayout(fig, 4, 2, TileSpacing="compact", Padding="compact");
for c = find(labels ~= "PO8")
    plotSitVsSup(nexttile(tl), time, squeeze(erpT(:, 1, c, :)), squeeze(erpT(:, 2, c, :)), pDiff(c, :), alpha, yl, labels(c))
end
exportgraphics(fig, fullfile(figDir, "FigS1_SIT_SUP_comparison_7channels_9subs.pdf"), ContentType="vector");
close(fig)

% Figure 6b: map of samples with significant SIT vs SUP differences
fig = figure(Color="w", Units="centimeters", Position=[2 2 9 7]);
ax = axes(fig);
imagesc(ax, time, 1:nChan, double(pDiff < alpha))
colormap(ax, [1 1 1; 0 0 0])
xline(ax, 0, ":k", LineWidth=1.2)
ax.YTick = 1:nChan; ax.YTickLabel = labels; ax.FontSize = 9;
xlabel(ax, "Time (s)"), ylabel(ax, "Channel")
title(ax, "SIT vs SUP: paired Wilcoxon signed-rank, p < 0.05", FontWeight="normal", FontSize=8)
exportgraphics(fig, fullfile(figDir, "SIT_SUP_signif_diff_9subs.pdf"), ContentType="vector");
close(fig)

%% Peak amplitudes at PO8 (subject level) for the text
win = [0.13 0.20; 0.20 0.27; 0.27 0.34];    % positive, negative, positive components
for w = 1:size(win, 1)
    idx = time >= win(w, 1) & time <= win(w, 2);
    amp = squeeze(mean(erpT(:, :, c8, idx), 4));   % subject x posture (mean amplitude)
    fprintf("PO8 %.0f-%.0f ms: SIT %.2f +/- %.2f, SUP %.2f +/- %.2f uV, signrank p = %.3f\n", ...
        1000*win(w, :), mean(amp(:, 1)), std(amp(:, 1)), mean(amp(:, 2)), std(amp(:, 2)), signrank(amp(:, 1), amp(:, 2)));
end

%% Local functions
function shadeSig(ax, t, x, mask, thr, colPos, colNeg)
    up = x; up(mask <= 0) = NaN;
    dn = x; dn(mask >= 0) = NaN;
    fillBetween(ax, t, up, thr(2), colPos)
    fillBetween(ax, t, dn, thr(1), colNeg)
end

function fillBetween(ax, t, x, level, col)
    valid = ~isnan(x);
    edges = diff([0 valid 0]);
    starts = find(edges == 1); stops = find(edges == -1) - 1;
    for k = 1:numel(starts)
        r = starts(k):stops(k);
        patch(ax, [t(r) fliplr(t(r))], [x(r) level*ones(1, numel(r))], col, EdgeColor="none", FaceAlpha=0.8)
    end
end

function styleAxes(ax, t, yl, ttl)
    xlim(ax, [t(1) t(end)]); ylim(ax, [-yl yl])
    xline(ax, 0, "k"); yline(ax, 0, "k")
    grid(ax, "on"); box(ax, "on"); ax.FontSize = 8;
    title(ax, ttl, FontWeight="bold", FontSize=9)
end

function plotSitVsSup(ax, t, sit, sup, p, alpha, yl, ttl)
    hold(ax, "on")
    sig = p < alpha & t >= 0;
    edges = diff([0 sig 0]);
    starts = find(edges == 1); stops = find(edges == -1) - 1;
    for k = 1:numel(starts)
        patch(ax, t([starts(k) stops(k) stops(k) starts(k)]), [-yl -yl yl yl], [1 0.6 1], EdgeColor="none", FaceAlpha=0.6)
    end
    h1 = plot(ax, t, mean(sit, 1), Color=[0 0.447 0.741], LineWidth=1.5);
    h2 = plot(ax, t, mean(sup, 1), Color=[0.850 0.325 0.098], LineWidth=1.5);
    styleAxes(ax, t, yl, ttl)
    xlabel(ax, "Time (s)"), ylabel(ax, "\muV")
    legend(ax, [h1 h2], ["SIT" "SUP"], Location="northeast", Box="off", FontSize=7)
end

function q = fdr_bh(p)
    % Benjamini-Hochberg adjusted p-values
    [ps, order] = sort(p(:));
    m = numel(ps);
    qs = min(1, cummin(ps .* m ./ (1:m)', "reverse"));
    q = zeros(size(p)); q(order) = qs;
end

function s = segments(t)
    % Compact description of contiguous significant intervals (ms)
    if isempty(t), s = "none"; return, end
    ms = round(1000*t);
    br = [0 find(diff(ms) > 5) numel(ms)];
    parts = strings(1, numel(br) - 1);
    for k = 1:numel(br) - 1
        parts(k) = sprintf("%d-%d", ms(br(k)+1), ms(br(k+1)));
    end
    s = strjoin(parts, ", ");
end

function [clean, nRaw] = preprocess(epochs, rec)
    % FieldTrip pre-processing and z-score artifact rejection of one epoch set
    % (samples x channels x epochs). Returns the clean epochs as channels x samples x epochs.
    nRaw = size(epochs, 3);
    data = [];
    data.label = cellstr(rec.labels(:));
    data.fsample = rec.fs;
    data.trial = squeeze(num2cell(permute(epochs, [2 1 3]), [1 2]))';
    data.time = repmat({linspace(-0.2, 0.8, size(epochs, 1))}, 1, nRaw);
    data = ft_preprocessing([], data);

    c = [];
    c.demean = 'yes';
    c.detrend = 'yes';
    c.dftfilter = 'yes';
    c.bpfilter = 'yes';
    c.bpfreq = [4 14];
    data = ft_preprocessing(c, data);

    c = [];
    c.artfctdef.zvalue.channel = 'EEG';
    c.artfctdef.zvalue.cutoff = 12;
    c.artfctdef.zvalue.trlpadding = 0;
    c.artfctdef.zvalue.artpadding = 0;
    c.artfctdef.zvalue.fltpadding = 0;
    c.artfctdef.zvalue.cumulative = 'yes';
    c.artfctdef.zvalue.medianfilter = 'yes';
    c.artfctdef.zvalue.medianfiltord = 9;
    c.artfctdef.zvalue.absdiff = 'yes';
    c.artfctdef.zvalue.interactive = 'no';
    c.continuous = 'no';
    out = ft_artifact_zvalue(c, data);
    trl = out.artfctdef.zvalue.trl;
    art = out.artfctdef.zvalue.artifact;
    bad = false(nRaw, 1);
    for k = 1:nRaw
        bad(k) = any(art(:, 2) > trl(k, 1) & art(:, 1) <= trl(k, 2));
    end
    clean = cat(3, data.trial{~bad});   % channels x samples x epochs
end

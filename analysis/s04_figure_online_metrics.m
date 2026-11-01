% S04_FIGURE_ONLINE_METRICS  Figure 7: paired online metrics in SIT and SUP.
% Requires output/online_metrics.csv (s01_online_metrics.m).
% Output: output/figures/online_metrics_SIT_vs_SUP.pdf

cfg = config();
T = readtable(fullfile(cfg.outputDir, "online_metrics.csv"), TextType="string");
pick = @(posture, var) arrayfun(@(s) T.(var)(T.Participant == s & T.Posture == posture), cfg.validSubs);
metrics = {100*pick("SIT", "ACC"),     100*pick("SUP", "ACC"),     "Accuracy (%)",       "(a)"
           pick("SIT", "DT_correct_s"), pick("SUP", "DT_correct_s"), "Detection time (s)", "(b)"
           pick("SIT", "ITR_correct_bpm"), pick("SUP", "ITR_correct_bpm"), "ITR (bits/min)", "(c)"};

figDir = fullfile(cfg.outputDir, "figures");
if ~isfolder(figDir), mkdir(figDir); end
fig = figure(Color="w", Units="centimeters", Position=[2 2 18 6.5]);
tl = tiledlayout(fig, 1, 3, TileSpacing="compact", Padding="compact");
for k = 1:size(metrics, 1)
    sit = metrics{k, 1}; sup = metrics{k, 2};
    p = signrank(sit, sup);
    ax = nexttile(tl); hold(ax, "on")
    boxchart(ax, ones(size(sit)), sit, BoxFaceColor=[0 0.447 0.741], MarkerStyle="none", BoxWidth=0.45);
    boxchart(ax, 2*ones(size(sup)), sup, BoxFaceColor=[0.850 0.325 0.098], MarkerStyle="none", BoxWidth=0.45);
    plot(ax, [1 2], [sit; sup], "-", Color=[0.6 0.6 0.6], LineWidth=0.6);
    scatter(ax, ones(size(sit)), sit, 14, "k", "filled");
    scatter(ax, 2*ones(size(sup)), sup, 14, "k", "filled");
    yl = [min([sit sup]) max([sit sup])]; span = diff(yl); yTop = yl(2) + 0.08*span;
    plot(ax, [1 1 2 2], [yTop-0.03*span yTop yTop yTop-0.03*span], "k-", LineWidth=0.8);
    lbl = "n.s."; if p <= 0.01, lbl = "**"; elseif p <= 0.05, lbl = "*"; end
    text(ax, 1.5, yTop + 0.04*span, sprintf("%s (p = %.3f)", lbl, p), HorizontalAlignment="center", ...
        VerticalAlignment="bottom", FontSize=8);
    ax.XTick = [1 2]; ax.XTickLabel = ["SIT" "SUP"]; ax.XLim = [0.5 2.5];
    ax.YLim = [yl(1) - 0.08*span, yl(2) + 0.25*span]; ax.FontSize = 9; ax.Box = "on";
    ylabel(ax, metrics{k, 3}); title(ax, metrics{k, 4}, FontWeight="normal"); grid(ax, "on")
end
exportgraphics(fig, fullfile(figDir, "online_metrics_SIT_vs_SUP.pdf"), ContentType="vector");
close(fig)

% RUN_ALL  Reproduces all results and figures of the article from the public dataset.
% Edit config.m first (dataset and FieldTrip paths). Runtime: about 15-20 min.

root = fileparts(mfilename("fullpath"));
addpath(root, fullfile(root, "src"), fullfile(root, "analysis"))

s01_online_metrics            % Table 2, Table S3
s02_offline_cross_validation  % Table 1, Table S2
s03_erp_analysis              % Figures 3-6, Figure S1, Table S1
s04_figure_online_metrics     % Figure 7

function cfg = config()
% CONFIG  Paths and study constants shared by all analysis scripts.
%   Edit the three paths below before running run_all.m.

% Folder of the public dataset (unzipped P300_posture_dataset.zip from Zenodo)
cfg.datasetDir   = fullfile(fileparts(mfilename("fullpath")), "..", "dataset_export");
% Folder where results (CSV) and figures (PDF) are written
cfg.outputDir    = fullfile(fileparts(mfilename("fullpath")), "output");
% FieldTrip installation (https://www.fieldtriptoolbox.org), used by the ERP analysis.
% Leave empty if FieldTrip is already on the MATLAB path.
cfg.fieldtripDir = "";

% Study constants
cfg.fs        = 256;                                   % sampling rate (Hz)
cfg.nItems    = 5;                                     % selectable items
cfg.channels  = ["Fz" "Cz" "P3" "Pz" "P4" "PO7" "PO8" "Oz"];
cfg.postures  = ["SIT" "SUP"];
cfg.allSubs   = compose("sub-%02d", 1:10);             % offline cross-validation (Table 1)
cfg.validSubs = compose("sub-%02d", [1 3:10]);         % online and ERP analyses (sub-02: Oz failure)
cfg.badOzSubs = "sub-02";                              % analysed without Oz
end

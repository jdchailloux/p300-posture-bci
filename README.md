# p300-posture-bci

Analysis code for the article:

> Chailloux Peguero, J.D.; Mendoza-Montoya, O.; Antelis, J.M.; Fabregas, E.; Farias, G.; Velastin, S.A. **Effect of Sitting and Supine Postures on Visual Event-Related Potentials and the Online Performance of a P300-Based Brain–Computer Interface.** *Sensors* (under review).

The study asks whether a P300-based brain–computer interface (BCI) works equally well when the user is sitting or lying supine. This question matters for people with amyotrophic lateral sclerosis (ALS), who become bedridden as the disease progresses. Ten healthy participants used a five-item visual P300 BCI in both postures. The code in this repository reproduces every table and figure of the article from the public EEG dataset.

## Requirements
- MATLAB with the Signal Processing and Statistics and Machine Learning toolboxes (tested with R2026a; R2023a or later recommended).
- [FieldTrip](https://www.fieldtriptoolbox.org), used for ERP pre-processing.
- The public dataset *P300-BCI EEG dataset: sitting vs. supine posture* (Zenodo, DOI: [10.5281/zenodo.23787196](https://doi.org/10.5281/zenodo.23787196)). Unzip it in any folder.

## Quick start
1. Clone the repository:
   ```
   git clone https://github.com/jdchailloux/p300-posture-bci.git
   ```
2. Edit `config.m`: set `datasetDir` to the unzipped dataset, and `fieldtripDir` to your FieldTrip installation (or add FieldTrip to the MATLAB path).
3. In MATLAB, run `run_all`. It takes about 15–20 min.

Results (CSV) and figures (PDF) are written to `output/`.

## What each script reproduces
| Script | Output | Article |
|---|---|---|
| `analysis/s01_online_metrics.m` | `online_metrics.csv` | Table 2, Table S3 |
| `analysis/s02_offline_cross_validation.m` | `offline_cv.csv` | Table 1, Table S2 |
| `analysis/s03_erp_analysis.m` | `erp_trial_counts.csv`, ERP figures | Figures 3–6, Figure S1, Table S1 |
| `analysis/s04_figure_online_metrics.m` | `online_metrics_SIT_vs_SUP.pdf` | Figure 7 |

## Methods implemented
- **Online metrics:** accuracy, detection time (from the trial-start marker to the BCI decision, over correct selections), and ITR (Wolpaw et al., 2002).
- **Offline classification:** follows Mendoza-Montoya (2018).
  - Amplitude-based epoch rejection.
  - FIR band-pass filter, 4–14 Hz.
  - CCA spatial filter with three components.
  - LDA with Ledoit–Wolf shrinkage.
  - Stratified five-fold cross-validation, reporting balanced accuracy.
- **ERP analysis:**
  - Pre-processing in FieldTrip: demean, detrend, 4–14 Hz band-pass, and z-score artifact rejection.
  - Subject-level grand averages.
  - Significance of each grand-average ERP against its pre-stimulus baseline, estimated with a kernel density estimator.
  - Comparison of the two postures with a paired Wilcoxon signed-rank test, corrected with Benjamini–Hochberg FDR.
- **Statistics:** two-sided Wilcoxon signed-rank tests for paired samples.

## Repository structure
```
config.m        paths and study constants
run_all.m       runs the whole analysis
src/            functions: data loading, epoching, online metrics, ITR, classification
analysis/       one script per table or figure group
tools/          export_dataset.m: conversion of the original BrainTec .ebr files to the public CSV format
```

## Note on the online analysis
An earlier version of the online analysis script did not reset the trial counter between the two postures. As a result, the detection time in the sitting posture was underestimated. `src/onlineSelections.m` computes each recording independently, and the article reports the corrected values.

## Citation
If you use this code, please cite the article and the dataset (see `CITATION.cff`).

## License
The code is released under the MIT License (see `LICENSE`). The dataset is distributed separately under CC BY 4.0.

## Contact
Juan David Chailloux Peguero (jdavid.chailloux@tec.mx). Corresponding author: Sergio A. Velastin (sergio.velastin@ieee.org).

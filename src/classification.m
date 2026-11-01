function out = classification()
% CLASSIFICATION  Single-trial P300 classification functions (CCA spatial
% filter + shrinkage LDA), following Mendoza-Montoya (2018).
%   f = classification(); then use f.reject, f.ccaFilter, f.features, f.shrinkLDA.
out.reject    = @rejectEpochs;
out.ccaFilter = @ccaFilter;
out.features  = @features;
out.shrinkLDA = @shrinkLDA;
end

function [badAmp, highBeta] = rejectEpochs(epochs, fs)
% badAmp: peak-to-peak > 200 uV or SD > 50 uV in any electrode (used for rejection).
% highBeta: P(20-40 Hz)/P(4-40 Hz) > 0.5 in any electrode (reported as an index
% of high-frequency contamination; not used for rejection).
n = size(epochs, 3);
badAmp = false(n, 1);
highBeta = false(n, 1);
for k = 1:n
    x = epochs(:, :, k);
    badAmp(k) = any(max(x) - min(x) > 200 | std(x) > 50);
    highBeta(k) = any(bandpower(x, fs, [20 40]) ./ bandpower(x, fs, [4 40]) > 0.5);
end
end

function W = ccaFilter(Xt, nFilters)
% CCA between the target epochs and their replicated average (Nd x Ne x Nt input)
[Nd, Ne, Nt] = size(Xt);
P = reshape(permute(Xt, [1 3 2]), Nd*Nt, Ne);
Q = repmat(mean(Xt, 3), Nt, 1);
A = canoncorr(P, Q);
W = A(:, 1:min(nFilters, Ne));
end

function F = features(X, W)
% Concatenated spatially filtered samples of each epoch
n = size(X, 3);
F = zeros(n, size(X, 1) * size(W, 2));
for k = 1:n
    Y = X(:, :, k) * W;
    F(k, :) = Y(:)';
end
end

function [w, b] = shrinkLDA(F, y)
% LDA with Ledoit-Wolf shrinkage covariance and equal class priors
mu1 = mean(F(y, :)); mu0 = mean(F(~y, :));
Z = [F(y, :) - mu1; F(~y, :) - mu0];
[n, d] = size(Z);
S = (Z' * Z) / n;
nu = trace(S) / d;
Z2 = Z.^2;
num = sum(sum((Z2' * Z2) / n - S.^2)) / n;
den = sum(sum((S - nu*eye(d)).^2));
lambda = max(0, min(1, num / den));
C = (1 - lambda) * S + lambda * nu * eye(d);
w = C \ (mu1 - mu0)';
b = w' * (mu1 + mu0)' / 2;
end

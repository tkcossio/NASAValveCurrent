function [ LOF, lrd ] = calculateLOF( X, k)
%Author: TKCossio
%Description: Function to calculate the Local Outlier Factor (LOF) for a data set.
%LOF is defined in 'LOF: Identifying Density-Based Local Outliers' and is
%used for outlier/anomaly detection.
%Inputs:
%1. X: MxN matrix of data, comprised of M observations of N variables [MxN]
%2. k: Algorithm parameter specifying number of points to
%consider for kNN
%Outputs:
%1. LOF: Local outlier factor.  A value (0, Inf) that designates whether a
%value is 'normal' or 'anomalous'.  Values ~1 are considered normal,
%although the exact threshold for anomalous values should be based on
%observation of the data.

%Calculate k-NN
[idx_kNN, dist_kNN] = knnsearch(X, X, 'k', k+1);
idx_kNN = idx_kNN(:,2:end);
dist_kNN = dist_kNN(:,2:end);

%Calculate distance matrix
distanceMatrix = squareform(pdist(X));

%Define reachability-distance between observations A & B
reachdist = zeros(size(X,1), size(X,1));

for idx_obs1 = 1:size(X,1);
    for idx_obs2 = 1:size(X,1);
        reachdist(idx_obs2, idx_obs1) = max([dist_kNN(idx_obs1,end), distanceMatrix(idx_obs1, idx_obs2)]);
    end
end

%Define local reachability density of observation A
lrd = zeros(size(X,1), 1);
for idx_obs = 1:size(X,1);
    runningSum = 0;
    for idx_k = 1:k;
        runningSum = runningSum + reachdist(idx_obs, idx_kNN(idx_obs,idx_k));
    end
    
    lrd(idx_obs) = 1 ./ (runningSum ./ k);
end

%Calculate LOF
LOF = zeros(size(X,1), 1);
for idx_obs = 1:size(X,1);
    runningSum = 0;
    for idx_k = 1:k;
        runningSum = runningSum + lrd(idx_kNN(idx_obs,idx_k)) / lrd(idx_obs);
    end
    LOF(idx_obs) = runningSum ./ k;
end
   
end
%Script to apply the Local Outlier Factor (LOF) algorithm.
%This functionality has now been incorporated into the dataObjectHandler
%class.
%This code is now out-of-date.
X = score(:, 1:2);
p = nchoosek(1:4,2);

k = 1;
newData = [];

N_newsamples = 10;

for idx = 1:size(p,1);
    s = SMOTEgenerator(X(p(idx,1), :)', X(p(idx,2), :)');
    
    for idx_s = 1:N_newsamples;
        newData(k,:) = s.getNewSample();
        k = k + 1;
    end
end
   
Xaug = [newData; X];

kval = 10;

[LOF, lrd] = calculateLOF(Xaug, kval);

figure(1), clf(1), plot(1:64, LOF(1:64), '.b', 'MarkerSize', 16), hold on, plot(65:72, LOF(65:end), '.r', 'MarkerSize', 16)

figure(2), clf(2), 
scatter(Xaug(1:64,1), Xaug(1:64,2), 2*LOF(1:64), 'filled');
hold on
scatter(Xaug(65:end,1), Xaug(65:end,2), 2*LOF(65:end), 'filled');

%%

X = score(:, 1:2);

[LOF, lrd] = calculateLOF(X, 3);

figure(2), clf(2)
scatter(X(1:4,1), X(1:4,2), 100 ./ lrd(1:4), 'k', 'filled')
hold on
scatter(X(5:end,1), X(5:end,2), 100 ./ lrd(5:end), 'r', 'filled')
xlabel('PCA Feature 1')
ylabel('PCA Feature 2')
title('PCA Feature Space. Size is proportional to 1/{local reachability density}.')
legend('Normal', 'Anomaly', 'Location', 'Best')
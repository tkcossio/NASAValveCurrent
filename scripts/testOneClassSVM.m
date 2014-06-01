%Script to demonstrate one-class SVM for anomaly detection.
%This functionality has been integrated into the dataObjectHandler class.
%This script is now out-of-date.

dataForm = 'PCA';

%Define normal v. anomaly indices
normalIdx = [1 2 3 4];
anomalyIdx = [5:12];

%Get data matrices
dataMatrix = dataHandler.getDataMatrix();
[coeff, score] = princomp(dataMatrix, 'econ');

switch dataForm
    case 'PCA'
        dataSet = score(:,1:2);
    otherwise
        dataSet = dataMatrix;
end

%% For training, augment normal samples using SMOTE

%Generate new samples by SMOTE
N_new_samples = 100;
ref_combos = nchoosek(normalIdx, 2);

trainingSuperset = zeros(size(ref_combos,1)*N_new_samples, size(dataSet,2));
source1 = zeros(size(ref_combos,1)*N_new_samples, 1);
source2 = source1;

k = 1;

for idx_combo = 1:1:size(ref_combos,1);
    s = SMOTEgenerator(dataSet(ref_combos(idx_combo,1),:)', dataSet(ref_combos(idx_combo,2),:)');
    
    for idx_sample = 1:N_new_samples;
        source1(k) = ref_combos(idx_combo,1);
        source2(k) = ref_combos(idx_combo,2);
        trainingSuperset(k,:) = s.getNewSample();
        k = k + 1;
    end
end

clear k s idx_combo ref_combos N_new_samples idx_ds

%% Initialize SVM & search for nu, g parameters
clear SVMobj;
SVMobj = oneClassSVMObject();
SVMobj.coarseSearchForParms(trainingSuperset);

%% Evaluate performance using LOO for 'normal' data
decVals = zeros(size(dataSet,1),1);
for IDX_UNDERTEST = normalIdx;
    
    %Define training set (leave-one-out)
    trainingSet = trainingSuperset(~ismember(source1, IDX_UNDERTEST) & ~ismember(source2, IDX_UNDERTEST), :);
    
    %Train model
    SVMobj.trainModel(trainingSet);
    
    %Define testing set 
    testingSet = dataSet(IDX_UNDERTEST,:);
    
    %Test model    
    decVals(IDX_UNDERTEST) = SVMobj.testModel(testingSet);
end

%% Evaluate performance using fully-trained classifier for 'anomaly' data
IDX_UNDERTEST = anomalyIdx;

%Training set should be entire set
trainingSet = trainingSuperset;

%Train model
SVMobj.trainModel(trainingSet);

%Define testing set
testingSet = dataSet(IDX_UNDERTEST,:);

%Test model
decVals(IDX_UNDERTEST) = SVMobj.testModel(testingSet);

%% Summarize results
figure(81), clf(81)
plot(normalIdx, decVals(normalIdx), 'kx', 'MarkerSize', 16)
hold on
plot(anomalyIdx, decVals(anomalyIdx), 'rx', 'MarkerSize', 16)
xlabel('Series #')
ylabel('1C-SVM score')
title('Plot of 1C-SVM Output, PCA Features')

%Generate ROC curve
[Pfa,Pd,AUC,AUClg,~] = ROC_Curve(decVals(normalIdx),decVals(anomalyIdx));

%% Generate a bunch of synthetic samples to test
base = dataMatrix(repmat(1:4, 1,10),:);
base = base + randn(size(base)) .* 0.01;

switch dataForm
    case 'PCA'
        baseproj = (bsxfun(@minus, base, mean(dataMatrix))) * coeff(:,1:2);
    otherwise
        baseproj = base;
end

decBase = SVMobj.testModel(baseproj);
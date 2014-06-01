%% Analysis of NASA Shuttle Valve Current Data (TEK)
%Data is courtesy of Ferrell, B & Santuro, S. (2005). NASA Shuttle Valve Data. http://www.cs.fit.edu/~pkc/nasa/data/
clearvars
close all
clc

%TEK data set (main)
shuttledata_dir = 'C:\Users\cossitk1\Documents\MATLAB\TCpersonal\data\NASAshuttleValve\Waveform Data\COL 1 Time COL 2 Current';

%Alternate data set (secondary)
%shuttledata_dir = 'C:\Users\cossitk1\Documents\MATLAB\TCpersonal\data\NASAshuttleValve\Waveform Data\Voltage Test 1\';

dataHandler = dataObjectHandler(shuttledata_dir);

if (dataHandler.ds_vector(1).N_samples > 1000)
    dataHandler.downsampleAllSeries(20);
end

%% Pre-processing
figure(101), clf(101), hold on

vc_ds = varycolor(dataHandler.N_dataSeries);
for idx_ds = 1:dataHandler.N_dataSeries;
    %Contribute to plot
    plot(dataHandler.ds_vector(idx_ds).TimeVector, dataHandler.ds_vector(idx_ds).DataVector, 'Color', vc_ds(idx_ds,:))        
end

title('NASA Valve Current Dataset')
xlabel('Time [s]')
ylabel('Current [a.u.]')
axis tight

%Clean up data.
dataHandler.removeOutliersAllSeries();
dataHandler.smoothAllSeries();
dataHandler.robuststandardizeAllSeries();

%% Identify salient features in a reference data set.
dataHandler.setReferenceValue(1);
dataHandler.detectSalientFeaturesInReference(NaN);

%% Match salient features from reference waveform
dataHandler.alignSeriesToReference();

%% Visualize how far we've come...
normalIdx = [1 2 3 4];
anomalyIdx = [5:12];

figure(102), clf(102)
subplot(211), hold on
for idx_ds = normalIdx;
    %Contribute to plot
    plot(dataHandler.ds_vector(idx_ds).TimeVector, dataHandler.ds_vector(idx_ds).DataVector, 'Color', vc_ds(idx_ds,:))
end
axis tight
ylabel('Valve Current')
title('"Normal" time series, post-alignment')

subplot(212), hold on
for idx_ds = 1:dataHandler.N_dataSeries;
    plot(dataHandler.ds_vector(idx_ds).TimeVector, dataHandler.ds_vector(idx_ds).DataVector, 'Color', vc_ds(idx_ds,:))
end
axis tight
xlabel('Time [a.u.]')
ylabel('Valve Current')
title('All time series, post-alignment')

figure(103), clf(103), hold on
subplot(211), hold on
for idx_ds = normalIdx
   plot(dataHandler.ds_vector(dataHandler.idx_reference).DataVector, dataHandler.ds_vector(idx_ds).DataVector, '.', 'Color', vc_ds(idx_ds, :))
end
axis tight
ylabel('Test Data')
title('"Normal" scatter v. Reference')

subplot(212), hold on
for idx_ds = 1:dataHandler.N_dataSeries;
   plot(dataHandler.ds_vector(dataHandler.idx_reference).DataVector, dataHandler.ds_vector(idx_ds).DataVector, '.', 'Color', vc_ds(idx_ds, :))
end
xlabel('Reference Data')
ylabel('Test data')
title('All scatter v. Reference')
axis tight

%% Run one-class SVM
decVals = dataHandler.runOneClassSVM('PCA');

figure(31), clf(31)
plot(decVals, '.k', 'MarkerSize', 16)
xlabel('Series #')
ylabel('Decision value')
title('One-class SVM output, PCA Features')

%% Perform dynamic time warping for each vector
%TODO: Fix this
DTW_mat = zeros(numel(ds_vector));

for idx_ds1 = 1:numel(ds_vector);
    for idx_ds2 = 1:numel(ds_vector);
        [DTW_mat(idx_ds1, idx_ds2),D,k,w,rw,tw]=dtw(ds_vector(idx_ds1).DataVector,ds_vector(idx_ds2).DataVector,0);
    end
end
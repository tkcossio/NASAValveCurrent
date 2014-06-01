classdef dataObjectHandler < handle
    %Class to store and operate on an array of 'dataObject's.
    
    properties (SetAccess = protected)
        ds_vector
        handlevector_mainplot;
        handlevector_secondaryplot;
        idx_reference = [];
        N_dataSeries = 0;
        textDescription = '';
        data_dir = '';
        temporalFeatureList;
        plotcolors
        normalIdx
        anomalyIdx        
    end
    
    methods
        function obj = dataObjectHandler(data_dir)
            
            file_list = dir(fullfile(data_dir, '*.csv'));
            
            if (isempty(file_list))
                file_list = dir(fullfile(data_dir, '*.txt'));
                
                if (isempty(file_list))
                    warning('No data files found!')
                    return;
                end
            end
            
            [~,order_file] = sort({file_list.name});
            file_list = file_list(order_file);
            
            for idx_file = 1:numel(file_list);
                ds_vector(idx_file) = dataObject(fullfile(data_dir, file_list(idx_file).name));
            end
            
            obj.ds_vector = ds_vector;
            obj.N_dataSeries = numel(ds_vector);
            obj.data_dir = data_dir;
            obj.textDescription = sprintf('%i files found.', obj.N_dataSeries);
            obj.handlevector_mainplot = NaN(obj.N_dataSeries,1);
            obj.handlevector_secondaryplot = [];
            obj.plotcolors = varycolor(obj.N_dataSeries);
            
            %Generate truth labels.
            if (strcmpi(obj.ds_vector(1).Description(1:3), 'TEK'))
                normal_files = {'TEK00000', 'TEK00001', 'TEK00002', 'TEK00003'};
            end
            
            obj.normalIdx = find(ismember({obj.ds_vector(:).Description}, normal_files));
            obj.anomalyIdx = setdiff(1:obj.N_dataSeries, obj.normalIdx);
            
        end
        
        function dataMatrix = getDataMatrix(obj)
            dataMatrix = zeros(numel(obj.ds_vector), obj.ds_vector(1).N_samples);
            for idx_ds = 1:numel(obj.ds_vector);
                dataMatrix(idx_ds,:) = obj.ds_vector(idx_ds).DataVector;
            end
        end
        
        function setReferenceValue(obj, reference_value)
            obj.idx_reference = reference_value;
        end
        
        function setReference(obj, h_reference)
            
            if (~isempty(obj.idx_reference))
                set(obj.handlevector_mainplot(obj.idx_reference), 'LineWidth', 1)
            end
            
            obj.idx_reference = find(obj.handlevector_mainplot == h_reference);
            set(obj.handlevector_mainplot(obj.idx_reference), 'LineWidth', 4.5);
            
        end
        
        function plotSeries(obj, h_target)
            
            % Define the context menu items and install their callbacks
            hcmenu = uicontextmenu;
            uimenu(hcmenu,'Label','Set reference','Callback',@setReferenceHandle);
            
            hold(h_target, 'on')
            for idx_ds = 1:obj.N_dataSeries;
                
                if (ishandle(obj.handlevector_mainplot(idx_ds)))
                    set(obj.handlevector_mainplot(idx_ds), 'XData', obj.ds_vector(idx_ds).TimeVector, 'YData', obj.ds_vector(idx_ds).DataVector);
                else
                    new_h = plot(h_target, obj.ds_vector(idx_ds).TimeVector,...
                        obj.ds_vector(idx_ds).DataVector, 'Color', obj.plotcolors(idx_ds,:), 'LineWidth', 1.5);
                    set(new_h, 'uicontextmenu', hcmenu);
                    obj.handlevector_mainplot(idx_ds) = new_h;
                end
            end
            hold(h_target, 'off')
            
        end
        
        function downsampleAllSeries(obj, downsample_factor)
            for idx_ds = 1:obj.N_dataSeries;
                obj.ds_vector(idx_ds).downsampleData(downsample_factor);
            end
        end
        
        function removeOutliersAllSeries(obj)
            for idx_ds = 1:obj.N_dataSeries;
                obj.ds_vector(idx_ds).cleanOutliers();
            end
        end
        
        function smoothAllSeries(obj)
            for idx_ds = 1:obj.N_dataSeries;
                obj.ds_vector(idx_ds).smoothSeries();
            end
        end
        
        function standardizeAllSeries(obj)
            for idx_ds = 1:obj.N_dataSeries;
                obj.ds_vector(idx_ds).standardize();
            end
        end
        
        function robuststandardizeAllSeries(obj)
            for idx_ds = 1:obj.N_dataSeries;
                obj.ds_vector(idx_ds).robuststandardize();
            end
        end
        
        function resetAllSeries(obj)
            for idx_ds = 1:obj.N_dataSeries;
                obj.ds_vector(idx_ds).resetData();
            end
        end
        
        function detectSalientFeaturesInReference(obj, h_target)
            [obj.temporalFeatureList, scale_resp] = obj.ds_vector(obj.idx_reference).detectSalientFeatures();
            
            t_vec = obj.ds_vector(obj.idx_reference).TimeVector;
            y_vec = obj.ds_vector(obj.idx_reference).DataVector;
            
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            if (ishandle(h_target))
                h_vec = [];
                hold(h_target, 'on')
                h_vec = imagesc(t_vec, linspace(0,1,size(scale_resp,2)), scale_resp, 'Parent', h_target);
                colormap(h_target, 'gray')
                caxis(h_target, quantile(scale_resp(:), [0.10, 0.90]))
                
                h_vec(end+1) = plot(h_target, t_vec, y_vec, 'r');
                
                vc_feat = varycolor(numel(obj.temporalFeatureList));
                
                for idx_feature = 1:numel(obj.temporalFeatureList);
                    
                    y=get(h_target,'ylim');
                    h_vec(end+1) = plot(h_target, t_vec([obj.temporalFeatureList(idx_feature).time_start obj.temporalFeatureList(idx_feature).time_start]),y,'--', 'Color', vc_feat(idx_feature,:));
                    h_vec(end+1) = plot(h_target, t_vec([obj.temporalFeatureList(idx_feature).time_stop obj.temporalFeatureList(idx_feature).time_stop]),y,'--', 'Color', vc_feat(idx_feature,:));
                    
                end
                
                xlabel(h_target, 'Time [a.u.]')
                ylabel(h_target, 'Valve Current [a.u.]')
                xlim(h_target, [min(t_vec) max(t_vec)])
                ylim(h_target, [0 1])
                
                hold(h_target, 'off')
                
                obj.handlevector_secondaryplot = h_vec;
            end
        end
        
        function alignSeriesToReference(obj)
            for idx_comp = setdiff(1:numel(obj.ds_vector), obj.idx_reference);
                [featureStartTimeList, featureStopTimeList] = obj.ds_vector(idx_comp).matchSalientFeatureList(obj.temporalFeatureList);
                
                %Align time series data
                obj.ds_vector(idx_comp).alignTimeSeries(featureStartTimeList, featureStopTimeList, obj.temporalFeatureList, obj.ds_vector(obj.idx_reference));
            end
        end
        
        function drawScatter(obj, h_targetplot, h_targettext)
            
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            h_vec = [];
            stringOut = sprintf('Correlation Coefficients:\n');
            
            hold(h_targetplot, 'on')
            
            for idx_ds = setdiff(1:obj.N_dataSeries, obj.idx_reference)
                h_vec(end+1) = plot(h_targetplot, obj.ds_vector(obj.idx_reference).DataVector, obj.ds_vector(idx_ds).DataVector, '.', 'Color', obj.plotcolors(idx_ds, :));
                
                cc = corrcoef(obj.ds_vector(obj.idx_reference).DataVector, obj.ds_vector(idx_ds).DataVector);
                
                stringOut = [stringOut sprintf('Series %i: %0.3f\n', idx_ds, cc(2,1))];
                
            end
            
            xlabel(h_targetplot, 'Reference Data')
            ylabel(h_targetplot, 'Test data')
            
            xlim(h_targetplot, [min(obj.ds_vector(obj.idx_reference).DataVector) max(obj.ds_vector(obj.idx_reference).DataVector)])
            ylim(h_targetplot, [min(obj.ds_vector(obj.idx_reference).DataVector) max(obj.ds_vector(obj.idx_reference).DataVector)])
            
            hold(h_targetplot, 'off')
            
            obj.handlevector_secondaryplot = h_vec;
            
            set(h_targettext, 'String', stringOut)
        end
        
        function d_knn1 = runKNN(obj, dataFormat, h_targetplot, h_targettext)
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            %Grab data
            switch dataFormat
                case 'PCA'
                    [~,score] = princomp(obj.getDataMatrix());
                    dataSet = score(:,1:2);
                otherwise
                    dataSet = obj.getDataMatrix();
            end
            
            stringOut = sprintf('kNN Results:\n');
            for idx_ds = 1:obj.N_dataSeries;
                trainIdx = setdiff(obj.normalIdx, idx_ds);
                [match,d_knn1(idx_ds)] = knnsearch(dataSet(trainIdx,:), dataSet(idx_ds,:), 'k', 1);
                stringOut = [stringOut sprintf('Series %i: Closest match=%i\n', idx_ds, match)];
            end
            
            hold(h_targetplot, 'on')
            h_vec = scatter(h_targetplot, 1:obj.N_dataSeries, log10(d_knn1), 64, obj.plotcolors, 'filled');
            
            xlabel(h_targetplot, 'Series #')
            ylabel(h_targetplot, 'log10(Distance to 1-NN)')
            xlim(h_targetplot, [1 obj.N_dataSeries])
            ylim(h_targetplot, [min(log10(d_knn1)) max(log10(d_knn1))])            
            
            hold(h_targetplot, 'off')
            
            obj.handlevector_secondaryplot = h_vec;
            
            set(h_targettext, 'String', stringOut)
            
        end
        
        function runPCA_All(obj, h_targetplot, h_targettext)
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            %Gather data
            dataMatrix = obj.getDataMatrix();
            
            [~,score] = princomp(dataMatrix, 'econ');
            h_vec = [];
            
            hold(h_targetplot, 'on')
            
            stringOut = sprintf('Closest Match in PCA space:\n');
            
            for idx_ds = 1:obj.N_dataSeries;
                h_vec(end+1) = plot(h_targetplot, score(idx_ds,1), score(idx_ds,2), '.', 'MarkerSize', 32, 'Color', obj.plotcolors(idx_ds,:));
                [match, ~] = knnsearch(score(setdiff(1:obj.N_dataSeries,idx_ds), 1:2), score(idx_ds,1:2), 'k', 1);
                stringOut = [stringOut sprintf('Series %i: PCA NN=%i\n', idx_ds, match)];
           end
            
            xlabel(h_targetplot, 'PCA #1')
            ylabel(h_targetplot, 'PCA #2')
            
            xlim(h_targetplot, [min(score(:,1)) max(score(:,1))])
            ylim(h_targetplot, [min(score(:,2)) max(score(:,2))])
            
            hold(h_targetplot, 'off')
            
            obj.handlevector_secondaryplot = h_vec;
            
            set(h_targettext, 'String', stringOut)
            
        end
        
        function runPCA_Ref(obj, h_targetplot, h_targettext)
            
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            %Gather data
            dataMatrix = obj.getDataMatrix();
            
            for idx_this = 1:obj.N_dataSeries;
                %Generate SMOTE data set
                N_new_samples = 10;
                ref_combos = nchoosek(setdiff(obj.normalIdx, idx_this), 2);
                
                dvnew = zeros(size(ref_combos,1)*N_new_samples, obj.ds_vector(1).N_samples);
                k = 1;
                
                for idx_combo = 1:1:size(ref_combos,1);
                    s = SMOTEgenerator(obj.ds_vector(ref_combos(idx_combo,1)).DataVector, obj.ds_vector(ref_combos(idx_combo,2)).DataVector);
                    
                    for idx_sample = 1:N_new_samples;
                        dvnew(k,:) = s.getNewSample();
                        k = k + 1;
                    end
                end
                
                ref_mean = mean(dvnew);
                
                %Calculate principal components
                [coeff, score] = princomp(dvnew, 'econ');
                
                %Now project all vectors into subspace defined by first N components.
                N_components = 3;
                dataMatrixProj = (bsxfun(@minus, dataMatrix(idx_this,:), ref_mean)) * coeff(:,1:N_components);
                
                %Calculate recovered vectors
                recoveredData = dataMatrixProj * coeff(:,1:N_components)';
                recoveredData = bsxfun(@plus, recoveredData, ref_mean);
                
                %Calculate error between original time series & subspace-projection
                PCA_sum_residual(idx_this) = sum((recoveredData - dataMatrix(idx_this,:)).^2, 2);
                
            end
            
            h_vec = [];
            
            hold(h_targetplot, 'on')
            
            h_vec = scatter(h_targetplot, 1:numel(PCA_sum_residual), log10(PCA_sum_residual), 64, obj.plotcolors, 'filled');
            xlabel(h_targetplot, 'Sample #')
            ylabel(h_targetplot, 'log10(error in subspace projection)')
            
            xlim(h_targetplot, [1 numel(PCA_sum_residual)])
            ylim(h_targetplot, [min(log10(PCA_sum_residual)) max(log10(PCA_sum_residual))])
            
            hold(h_targetplot, 'off')
            
            obj.handlevector_secondaryplot = h_vec;
            
            stringOut = sprintf('Plot shows error in re-construction of each time series using first %i principal components.  Projections were calculated using SMOTE-augmented ''normal'' data.', N_components);
            set(h_targettext, 'String', stringOut)
            
        end

        function calculateSeriesPSDs(obj, h_targetplot)
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            h_vec = [];
            
            T_s = obj.ds_vector(1).TimeVector(2) - obj.ds_vector(1).TimeVector(1);
            
            hold(h_targetplot, 'on')
            
            ylimits = [Inf -Inf];
            for idx_ds = 1:obj.N_dataSeries;
                [Pxx, f] = pwelch(obj.ds_vector(idx_ds).DataVector, [], [], [], 1/T_s);
                h_vec(end+1) = plot(h_targetplot, log10(f), log10(Pxx), 'Color', obj.plotcolors(idx_ds,:));
                ylimits(1) = min([ylimits(1); log10(Pxx)]);
                ylimits(2) = max([ylimits(2); log10(Pxx)]);
            end
            
            xlabel(h_targetplot, 'log10(f) [Hz]')
            ylabel(h_targetplot, 'log10(PSD) [dB/Hz]')
            
            hold(h_targetplot, 'off')
            
            xlim(h_targetplot, [min(log10(f)) max(log10(f))])
            ylim(h_targetplot, ylimits)
            
            obj.handlevector_secondaryplot = h_vec;
            
        end
        
        function calculateSeriesAutocorr(obj, h_targetplot)
            
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            h_vec = [];
            
            hold(h_targetplot, 'on')
            
            ylimits = [Inf -Inf];
            for idx_ds = 1:obj.N_dataSeries;
                v = xcov(obj.ds_vector(idx_ds).DataVector, 'coeff');
                h_vec(end+1) = plot(h_targetplot, v, 'Color', obj.plotcolors(idx_ds,:));
            end
            
            xlabel(h_targetplot, 'Time [a.u.]')
            ylabel(h_targetplot, 'Autocorr')
            
            hold(h_targetplot, 'off')
            
            xlim(h_targetplot, [1 numel(v)])
            ylim(h_targetplot, [-1 1])
            
            obj.handlevector_secondaryplot = h_vec;
            
        end
        
        function decVals = runOneClassSVM(obj, dataFormat, h_targetplot, h_targettext)
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
          
            %Grab data
            switch dataFormat
                case 'PCA'
                    [~,score] = princomp(obj.getDataMatrix());
                    dataSet = score(:,1:2);
                otherwise
                    dataSet = obj.getDataMatrix();
            end
            
            %For training, augment normal samples using SMOTE
            N_new_samples = 100;
            ref_combos = nchoosek(obj.normalIdx, 2);
            
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
            
            %Initialize SVM & search for nu, g parameters
            SVMobj = oneClassSVMObject();
            SVMobj.coarseSearchForParms(trainingSuperset);
            
            %% Evaluate performance using LOO for 'normal' data
            decVals = zeros(size(dataSet,1),1);
            for IDX_UNDERTEST = obj.normalIdx;
                
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
            IDX_UNDERTEST = obj.anomalyIdx;
            
            %Training set should be entire set
            trainingSet = trainingSuperset;
            
            %Train model
            SVMobj.trainModel(trainingSet);
            
            %Define testing set
            testingSet = dataSet(IDX_UNDERTEST,:);
            
            %Test model
            decVals(IDX_UNDERTEST) = SVMobj.testModel(testingSet);
            
            %% Summarize results
            if (exist('h_targetplot', 'var') && ishandle(h_targetplot))
                hold(h_targetplot, 'on')
                h_vec = scatter(h_targetplot, 1:obj.N_dataSeries, decVals, 64, obj.plotcolors, 'filled');
                xlabel(h_targetplot, 'Series #')
                ylabel(h_targetplot, '1C-SVM score')
                xlim(h_targetplot, [1 obj.N_dataSeries])
                ylim(h_targetplot, [min(decVals) max(decVals)]);            
                hold(h_targetplot, 'off')
                obj.handlevector_secondaryplot = h_vec;
            end
            
            if (exist('h_targettext', 'var') && ishandle(h_targettext))
                stringOut = 'Decision values for 1Class-SVM.';
                set(h_targettext, 'String', stringOut)
            end

        end
        
        function lrd = applyLOFPCA(obj, h_targetplot, h_targettext)
            if (~isempty(obj.handlevector_secondaryplot))
                for handle_to_delete = obj.handlevector_secondaryplot
                    if (ishandle(handle_to_delete))
                        delete(handle_to_delete)
                    end
                end
            end
            
            %Gather data
            [~,score] = princomp(obj.getDataMatrix(), 'econ');
            
            %Run LOF
            [~, lrd] = calculateLOF(score(:,1:2), 3);

            if (exist('h_targetplot', 'var') && ishandle(h_targetplot))
                
                hold(h_targetplot, 'on')
                h_vec = scatter(h_targetplot, score(:,1), score(:,2), 100 ./ lrd, obj.plotcolors, 'filled');
                
                xlabel(h_targetplot, 'PCA #1')
                ylabel(h_targetplot, 'PCA #2')
                
                xlim(h_targetplot, [min(score(:,1)) max(score(:,1))])
                ylim(h_targetplot, [min(score(:,2)) max(score(:,2))])
                
                hold(h_targetplot, 'off')
                
                obj.handlevector_secondaryplot = h_vec;
                
            end
            
            if (exist('h_targettext', 'var') && ishandle(h_targettext))
                stringOut = sprintf('Scatter plot of PCA feature #1 v. PCA feature #2.  Size of points is proportional to the inverse of the local reachability density.');
                set(h_targettext, 'String', stringOut)
            end
        end
        
        function delete(obj)
            for idx_ds = 1:obj.N_dataSeries;
                handle_subset = obj.handlevector_mainplot(idx_ds);
                
                if (ishandle(handle_subset))
                    delete(handle_subset);
                end
                
            end
            
            for idx_h = 1:numel(obj.handlevector_secondaryplot);
                
                if (ishandle(obj.handlevector_secondaryplot(idx_h)))
                    delete(obj.handlevector_secondaryplot(idx_h));
                end
                
            end
            
        end
        
    end
end

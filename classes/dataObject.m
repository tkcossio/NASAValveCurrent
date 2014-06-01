classdef dataObject < handle
    %Data object class for handling NASA Valve Current time series.
    
    properties (SetAccess = protected)
        Description = '';
        SourceFile = '';
        TimeVector;
        DataVector;
        N_samples = 0;
    end %Protected properties
    
    methods
        
        function obj = dataObject(input_file)
            [~,obj.Description, file_ext] = fileparts(input_file);
            obj.SourceFile = input_file;
            
            switch lower(file_ext)
                case '.csv'
                    temp = csvread(input_file);
                    obj.TimeVector = temp(:,1);
                    obj.DataVector = temp(:,2);
                case '.txt'
                    temp = load(input_file);
                    obj.TimeVector = 1:numel(temp(:,2));
                    obj.DataVector = temp(:,2);
            end
            
            obj.N_samples = numel(obj.DataVector);
            
        end
        
        function resetData(obj)
            [~,~, file_ext] = fileparts(obj.SourceFile);
            
            switch lower(file_ext)
                case '.csv'
                    temp = csvread(obj.SourceFile);
                    obj.TimeVector = temp(:,1);
                    obj.DataVector = temp(:,2);
                case '.txt'
                    temp = load(obj.SourceFile);
                    obj.TimeVector = 1:numel(temp(:,2));
                    obj.DataVector = temp(:,2);
            end
            
            obj.N_samples = numel(obj.DataVector);
        end
        
        function downsampleData(obj, N_factor)
            tvec_ds = reshape(obj.TimeVector, N_factor, [])';
            dvec_ds = reshape(obj.DataVector, N_factor, [])';
            obj.DataVector = mean(dvec_ds, 2);
            obj.TimeVector = mean(tvec_ds, 2);
            obj.N_samples = numel(obj.DataVector);            
        end
        
        function standardize(obj)
            obj.DataVector = (obj.DataVector - mean(obj.DataVector)) ./ std(obj.DataVector);
        end
        
        function cleanOutliers(obj)
            obj.DataVector = medfilt1(obj.DataVector, 5);
        end
        
        function smoothSeries(obj)
            obj.DataVector = conv(obj.DataVector, [0.5 0.5], 'same');
        end
        
        function robuststandardize(obj)
            %TODO: This doesn't work very well... improve.
            obj.DataVector = (obj.DataVector - min(obj.DataVector));
            obj.DataVector = obj.DataVector ./ max(obj.DataVector);
        end
        
        function [temporalFeatureList, scale_resp] = detectSalientFeatures(obj)
            %Define temporal scales to search over.
            win_size = round(linspace(.01.*obj.N_samples, .05.*obj.N_samples, 10)) .* 2;
            
            scale_resp = zeros(numel(win_size), numel(obj.DataVector));
            
            %Apply multi-scale 2nd derivative filter to find salient
            %temporal features in the signal.
            for idx_size = 1:1:numel(win_size);
                current_scale = win_size(idx_size);
                
                %Haar wavelet approach:
                %H = zeros(current_scale, 1);
                %H((current_scale/2 + 1):end) = 1;
                %H = H - mean(H);
                %scale_resp(idx_size,:) = conv(obj.DataVector, H, 'same');
                
                %Laplacian of Gaussian approach
                %TODO: Replace this with an actual function rather than
                %ImageProcessingToolbox nonsense.
                H = fspecial('log', current_scale, current_scale/10);
                H = -H(current_scale/2+1,:);
                H = H - mean(H);
                scale_resp(idx_size,:) = (current_scale/10) .* conv(obj.DataVector, H, 'same');
            end
            
            %We care about both position and negative responses, so square
            %detector response.
            scale_resp = scale_resp.^2;
            
            %Clean up response by removing quenching zero-padding regions
            scale_resp(:,1:max(win_size)/2) = median(scale_resp(:));
            scale_resp(:,end-(max(win_size)/2):end) = median(scale_resp(:));
            
%             figure(21), clf(21)
%             subplot(211)
%             plot(obj.DataVector, 'k')
%             subplot(212)
%             imagesc(scale_resp)
%             caxis(quantile(scale_resp(:), [0.10 0.90]))
%             
            %Now extract salient features from scale-time space
            %Quick & dirty
            test_quantile = 0.90;
            
            while (1)
                scaletime_mask = scale_resp > quantile(scale_resp(:), test_quantile);
                
                %More elegant way using k-means.
                %cleanresp = (scale_resp);
                %cleanresp(cleanresp < median(cleanresp(:))) = NaN;
                %[kmidx, kmce] = kmeans(log10(cleanresp(:)), 2);
                %[kmce, idx] = sort(kmce);
                %km_matrix = reshape(kmidx, size(cleanresp));
                %scaletime_mask = (km_matrix == idx(end));
                
                bwcc = bwconncomp(scaletime_mask);
                obj_size = cellfun(@(x)(numel(x)), bwcc.PixelIdxList);
                
                %Salient features should be fairly robust and exist across a span of
                %scales/times.
                obj_test = obj_size > 50;
                bwcc.NumObjects = numel(find(obj_test));
                bwcc.PixelIdxList = bwcc.PixelIdxList(obj_test);
                
                if (bwcc.NumObjects > 8)
                    test_quantile = mean([test_quantile 1]);
                    continue
                else
                    break;
                end
            end
            
            stats = regionprops(bwcc, scale_resp, 'WeightedCentroid');
            time_feature = round(arrayfun(@(x)(x.WeightedCentroid(1)), stats));
            scale_idx = round(arrayfun(@(x)(x.WeightedCentroid(2)), stats));
            scale_feature = win_size(scale_idx)';
            clear stats
            
            %Merge overlapping features
            feature_start = time_feature - scale_feature;
            feature_stop = time_feature + scale_feature;
            
            [feature_start, idx] = sort(feature_start);
            feature_stop = feature_stop(idx);
            
            new_feature_start = feature_start(1);
            new_feature_stop = feature_stop(1);
            
            for idx_feature = 2:numel(time_feature);
                %Feature is beyond span in new feature list, so add a new entry.
                if (feature_start(idx_feature) >= new_feature_stop(end))
                    new_feature_start(end+1) = feature_start(idx_feature);
                    new_feature_stop(end+1) = feature_stop(idx_feature);
                else
                    %Feature starts before end of current span.  Either it is completely
                    %subsumed by existing feature or spans beyond.
                    new_feature_stop(end) = max(feature_stop(idx_feature), new_feature_stop(end));
                end
            end
            
            %Overlay the selected regions
            vc_salientfeatures = varycolor(numel(new_feature_start));
            
%             for idx_feature = 1:numel(new_feature_start);
%                 figure(21), subplot(211)
%                 h1 = vline(new_feature_start(idx_feature));
%                 h2 = vline(new_feature_stop(idx_feature));
%                 set(h1, 'Color', vc_salientfeatures(idx_feature,:));
%                 set(h2, 'Color', vc_salientfeatures(idx_feature,:));
%             end
            
            temporalFeatureList = struct('time_start', num2cell(new_feature_start), 'time_stop', num2cell(new_feature_stop));
            
            for idx_feature = 1:numel(new_feature_start);
                temporalFeatureList(idx_feature).signal = obj.DataVector(new_feature_start(idx_feature):new_feature_stop(idx_feature));
            end
        end
        
        function [featureStartTime, featureStopTime] = matchSalientFeature(obj, temporalFeature, startingSearchTime)
            
            %Visualization of process
            %figure(31), clf(31)
            %subplot(211)
            %plot(temporalFeature.signal, 'k'), hold on
            %plot(obj.DataVector, 'b')
            
            sliding_corr = [];
            MSE_corr = [];
            
            win_length = numel(temporalFeature.signal);
            
            for idx_t = startingSearchTime:1:numel(obj.TimeVector)-win_length+1;
                cc_test = corrcoef(temporalFeature.signal, obj.DataVector(idx_t:idx_t+win_length-1));
                if isnan(cc_test(2,1))
                    sliding_corr(idx_t-startingSearchTime+1) = 0;
                else
                    sliding_corr(idx_t-startingSearchTime+1) = cc_test(2,1);
                end
                MSE_corr(idx_t-startingSearchTime+1) = sum((temporalFeature.signal - obj.DataVector(idx_t:idx_t+win_length-1)).^2);
            end
            
            %subplot(212)
            %plot(startingSearchTime:numel(obj.TimeVector)-win_length+1, zscore(sliding_corr), 'k'), hold on
            %plot(startingSearchTime:numel(obj.TimeVector)-win_length+1, -zscore(MSE_corr), 'r')
            %xlim([0 obj.N_samples])
            
            [~,lag_MSE] = min(MSE_corr);
            [~,lag_slidingcorr] = max(sliding_corr);
            
            %subplot(211)
            %plot(lag_MSE+startingSearchTime-1:lag_MSE+win_length+startingSearchTime-1, obj.DataVector(lag_MSE+startingSearchTime-1:lag_MSE+win_length+startingSearchTime-1), 'Color', [0 1 1])
            
            featureStartTime = lag_MSE + startingSearchTime - 1;
            featureStopTime = featureStartTime + win_length - 1;
        end
        
        function [featureStartTimeList, featureStopTimeList] = matchSalientFeatureList(obj, temporalFeatureList)
            %Develop list for start/stop of each salient feature in this
            %time series.
            featureStartTimeList = zeros(1,numel(temporalFeatureList));
            featureStopTimeList = zeros(1,numel(temporalFeatureList));
            
            next_start_time = 1;
            for idx_feature = 1:numel(temporalFeatureList);
                [featureStartTimeList(idx_feature), featureStopTimeList(idx_feature)] = obj.matchSalientFeature(temporalFeatureList(idx_feature), next_start_time);
                next_start_time = featureStopTimeList(idx_feature);
            end
        end
        
        function alignTimeSeries(obj, featureStartTimeList, featureStopTimeList, temporalFeatureList, ref_obj)
            newSignal = zeros(ref_obj.N_samples, 1);
            
            for idx_feature = 1:numel(temporalFeatureList);
                %Calculate bounds of signal between salient features
                if (idx_feature == 1)
                    start_ref_time = 1;
                    start_comp_time = 1;
                else
                    start_ref_time = temporalFeatureList(idx_feature-1).time_stop + 1;
                    start_comp_time = featureStopTimeList(idx_feature-1) + 1;
                end
                
                stop_ref_time = temporalFeatureList(idx_feature).time_start - 1;
                stop_comp_time = featureStartTimeList(idx_feature) - 1;
                
                %Grab signal that needs to be re-sampled
                if (start_comp_time < stop_comp_time)
                    segmentCOMP = obj.DataVector(start_comp_time:stop_comp_time);
                    
                    %Perform re-sampling
                    segmentRS = resample(segmentCOMP, stop_ref_time-start_ref_time+1, stop_comp_time-start_comp_time+1);
                    
                    %Insert re-sampled signal
                    newSignal(start_ref_time:stop_ref_time) = segmentRS;
                    
                else
                    newSignal(start_ref_time:stop_ref_time) = newSignal(max([start_ref_time-1, 1]));
                end
                
                %Insert matching salient feature extracted from test signal
                N_featureduration = featureStopTimeList(idx_feature) - featureStartTimeList(idx_feature) + 1;
                newSignal(stop_ref_time+1:stop_ref_time+N_featureduration) = obj.DataVector(featureStartTimeList(idx_feature):featureStopTimeList(idx_feature));
            end
            
            %Bring in rest of signal
            start_ref_time = temporalFeatureList(end).time_stop + 1;
            stop_ref_time = ref_obj.N_samples;
            
            start_comp_time = featureStopTimeList(end)+1;
            stop_comp_time = obj.N_samples;
            
            if (start_comp_time < stop_comp_time)
                newSignal(start_ref_time:end) = resample(obj.DataVector(start_comp_time:end), (stop_ref_time-start_ref_time+1), (stop_comp_time - start_comp_time+1));
            end
            
            %figure(41), clf(41)
            %plot(ref_obj.DataVector, 'k'), hold on
            %plot(obj.DataVector, 'b')
            %plot(newSignal, 'r')
            
            obj.DataVector = newSignal;
            obj.N_samples = numel(newSignal);
            
        end
        
    end
    
end
classdef oneClassSVMObject < handle
    %Wrapper class for LIBSVM one-class SVM
    
    properties (SetAccess = protected)
        g_argmax = [];
        nu_argmax = [];
        model
        libsvm_options = '';
        min_vector = [];
        max_vector = [];
    end
    
    methods
        function obj = oneClassSVMObject()
            obj.libsvm_options = ['-s 2 -t 2'];
        end
        
        function coarseSearchForParms(obj, trainingSet)
            g_span = logspace(-7,-2,5);
            nu_span = logspace(-5,0,5);
            
            [obj.g_argmax, obj.nu_argmax] = obj.searchForParms(trainingSet, g_span, nu_span);
            
        end
        
        function refineSearchParms(obj, trainingSet)
           if (isempty(obj.g_argmax) || isempty(obj.g_argmax))
               [obj.g_argmax, obj.nu_argmax] = obj.coarseSearchForParms(trainingSet);
           end
           
           g_span = logspace(log10(obj.g_argmax)-1, log10(obj.g_argmax)+1, 5);
           nu_span = logspace(log10(obj.nu_argmax)-1, log10(obj.nu_argmax)+1, 5);
           
           [obj.g_argmax, obj.nu_argmax] = obj.searchForParms(trainingSet, g_span, nu_span);
           
        end
        
        function [g_argmax, nu_argmax] = searchForParms(obj, trainingSet, g_span, nu_span)
            %Make features more robust by adding Gaussian white noise.
            trainingSet = trainingSet + randn(size(trainingSet)) .* 0.01;
            
            %Randomly permute
            trainingSet = trainingSet(randperm(size(trainingSet,1)), :);
            
            %Normalize training set & store normalization parameters.
            min_vector = min(trainingSet,[],1);
            trainingSet = bsxfun(@minus, trainingSet, min_vector);
            max_vector = max(trainingSet, [], 1);
            max_vector(max_vector <= 0) = median(max_vector);
            trainingSet = bsxfun(@rdivide, trainingSet, max_vector);
            
            cv_matrix = zeros(numel(nu_span), numel(g_span));
            for idx_nu = 1:numel(nu_span);
                for idx_g = 1:numel(g_span);
                    libsvm_str = [obj.libsvm_options ' -n ' num2str(nu_span(idx_nu)) ' -g ' num2str(g_span(idx_g)) ' -v 10'];
                    cv_matrix(idx_nu,idx_g) = svmtrain(ones(size(trainingSet,1),1), trainingSet, libsvm_str);
                end
            end
            
            [~,ij] = max2(cv_matrix);
            nu_argmax = nu_span(ij(1));
            g_argmax = g_span(ij(2));            
        end
                    
        function trainModel(obj, trainingSet)
            
            %Make training set more robust by adding Gaussian white noise
            trainingSet = trainingSet + randn(size(trainingSet)) .* 0.01;
            
            %Normalize training set & store normalization parameters.
            obj.min_vector = min(trainingSet,[],1);
            trainingSet = bsxfun(@minus, trainingSet, obj.min_vector);
            obj.max_vector = max(trainingSet, [], 1);
            obj.max_vector(obj.max_vector <= 0) = median(obj.max_vector);
            trainingSet = bsxfun(@rdivide, trainingSet, obj.max_vector);
            
            %Train model based on selected nu, g
            libsvm_train_str = [obj.libsvm_options ' -n ' num2str(obj.nu_argmax) ' -g ' num2str(obj.g_argmax)];
            obj.model = svmtrain(ones(size(trainingSet,1),1), trainingSet, libsvm_train_str);
            
        end
        
        function decisionValues = testModel(obj, testingSet)
                    
            %Normalize testing set
            testingSet = bsxfun(@minus, testingSet, obj.min_vector);
            testingSet = bsxfun(@rdivide, testingSet, obj.max_vector);
            
            [~,~,decisionValues] = svmpredict(zeros(size(testingSet,1),1), testingSet, obj.model);
            
        end
    end
    
end


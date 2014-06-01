classdef SMOTEgenerator
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=protected)
        data1 = [];
        data2 = [];
        N = 0;
    end
    
    methods
        function obj = SMOTEgenerator(vector1, vector2)
            if (numel(vector1) ~= numel(vector2))
                error('Input vectors need to be same length!')
            end
            obj.data1 = vector1;
            obj.data2 = vector2;            
            obj.N = numel(vector1);
        end
        
        function vectorNew = getNewSample(obj)
            diff_vector = obj.data1 - obj.data2;
            rnd_vector = rand(obj.N,1);
            vectorNew = obj.data2 + rnd_vector .* diff_vector;
        end
        
    end
    
end


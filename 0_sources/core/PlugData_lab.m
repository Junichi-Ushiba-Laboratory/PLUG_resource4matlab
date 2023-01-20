%{
plugデータの解析実施
2022/2/10より

%}
classdef PlugData < PlugData_core
    properties
    end
    properties(Access=private)
    end

    methods
        function obj=PlugData(storageDir,hardWare,dataName,logger)
            obj=obj@PlugData_core(storageDir,hardWare,logger)
            
            % load data.
            obj.import(dataName);
        end
    end
    methods(Static)
    end
end
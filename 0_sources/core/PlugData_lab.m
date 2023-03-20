%{
plugデータの解析実施
2022/2/10より

%}
classdef PlugData_lab < PlugData_core
    properties
    end
    properties(Access=private)
    end

    methods
        function obj=PlugData_lab(storageDir,hardWare,dataName,logger)
            obj=obj@PlugData_core(storageDir,hardWare,logger)
            
            obj.col=obj.channelIndices(logger,hardWare);
            if obj.logger=="PLUG_logger"
                obj.shift.eeg=obj.col.eeg_time;
                obj.shift.imp=obj.col.imp_time;
                obj.shift.acc=obj.col.acc_time;
                obj.loadOffset=3;
            elseif obj.logger=="PLUG_logger2"
                obj.shift.eeg=obj.col.eeg_time;
                obj.shift.imp=obj.col.imp_time;
                obj.shift.acc=obj.col.acc_time;
                obj.shift.ofst=obj.col.ofst_time;
                obj.loadOffset=3;
            end
            % load data.
            obj.import(dataName);
        end
    end
    methods(Static)
        function index=channelIndices(logger,hardWare)
            % hardwareに合わせて、元データの列番号を返す
            %
            index=struct();
            if hardWare=="PLUG0"
                index.eeg_flag=1;
                index.eeg_time=2;
                index.eeg_F3=3;
                index.eeg_F4=4;
                index.eeg_C3=5;
                index.eeg_C4=6;
                index.eeg_O1=7;
                index.eeg_O2=8;
                index.eeg_T3=9;
                index.eeg_T4=10;
                index.imp_flag=11;
                index.imp_time=12;
                index.imp_F3=13;
                index.imp_F4=14;
                index.imp_C3=15;
                index.imp_C4=16;
                index.imp_O1=17;
                index.imp_O2=18;
                index.imp_T3=19;
                index.imp_T4=20;
                index.acc_flag=21;
                index.acc_time=22;
                index.acc_1=23;
                index.acc_2=24;
                index.acc_3=25;
                index.ofst_flag=26;
                index.ofst_time=27;
                index.ofst_F3=28;
                index.ofst_F4=29;
                index.ofst_C3=30;
                index.ofst_C4=31;
                index.ofst_O1=32;
                index.ofst_O2=33;
                index.ofst_T3=34;
                index.ofst_T4=35;
            elseif hardWare=="PLUG"
                index.eeg_flag=1;
                index.eeg_time=2;
                index.eeg_Cz=3;index.eeg_NC1=4;
                index.eeg_C3=5;index.eeg_NC2=6;index.eeg_NC3=7;index.eeg_NC4=8;
                index.eeg_C4=9;index.eeg_NC5=10;
                index.imp_flag=11;
                index.imp_time=12;
                index.imp_Cz=13;index.imp_NC1=14;
                index.imp_C4=15;index.imp_NC2=16;index.imp_NC3=17;index.imp_NC4=18;
                index.imp_C3=19;index.imp_NC5=20;
                index.acc_flag=21;
                index.acc_time=22;
                index.acc_1=23;
                index.acc_2=24;
                index.acc_3=25;
                index.ofst_flag=26;
                index.ofst_time=27;
                index.ofst_Cz=28;index.ofst_NC1=29;
                index.ofst_C4=30;index.ofst_NC2=31;index.ofst_NC3=32;index.ofst_NC4=33;
                index.ofst_C3=34;index.ofst_NC5=35;
            end
        end
    end
end
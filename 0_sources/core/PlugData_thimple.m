%{
plugデータの解析_thimpleLogger用。
2022/11/12より

usage:
 data=PlugData_thimple("testData/","dataFromThimpleLogger.csv")
%}
classdef PlugData_thimple < PlugData_core
    properties
        labels
    end
    properties(SetAccess=private,GetAccess=public)
        labelsID=struct()
    end

    methods
        function obj=PlugData_thimple(storageDir)
            obj=obj@PlugData_core(storageDir,"PLUG","thimple_logger")
            obj.col=obj.channelIndices();
            obj.shift.eeg=obj.col.eeg_time;
            
            obj.shift.imp=obj.col.imp_Cz;
            obj.shift.acc=obj.col.acc_1;
            obj.shift.ofst=obj.col.ofst_Cz;
            obj.loadOffset=2;
            
        end
        function import(obj,dataName)
            % dataName must ends with .csv
            obj.dataName=dataName;
            obj.dataPath=fullfile(obj.storageDir,obj.dataName);
            obj.origin=readmatrix(obj.dataPath);
            obj.reformFlag();

            obj.strip_eeg();
            obj.strip_imp();
            obj.strip_ofst();
            obj.strip_acc();
            obj.get_dins();
        end
        function  obj=reformFlag(obj)
            % flagが文字列データで格納されてしまうせいで他のインポート系関数が異常を起こす。
            % その調整用に、新規にflag列を作成し、originに格納することで対応する。
            flags=readmatrix(obj.dataPath,"Range","C:C","OutputType","string");
            flags=flags(2:end);
            obj.labels=flags;
            flagVal=unique(flags);
            for i=1:length(flagVal)
                indice=flags==flagVal(i);
                flags(indice)=i;
                obj.labelsID.(flagVal(i))=i;
            end
            obj.origin(:,3)=flags;
        end
        function [id2label,label2id]=get_labelID(obj)
            % 基本的にはlabelIDにはid順に格納されているはずだが、別の開発による処理で順番が崩されない保証はない。
            label2id=obj.labelsID;
            id2label=struct();
            labelStrs=string(fields(obj.labelsID));
            for i = 1:length(labelStrs)
                tmpId=obj.labelsID.(labelStrs(i));
                id2label.("id_"+string(tmpId))=labelStrs(i);
            end
        end

    end
    methods(Static)
        function time=export_time(wave,fs,timeCh,logger)
            if logger~="thimple_logger"
                error("logger must be thimple_logger")
            end
            stt=2;
            time=0:1:length(rmmissing(wave(stt:end,timeCh)))-1;
            time=time/fs;
            flagCh=timeCh-1;
        end
        function index=channelIndices()
            % hardwareに合わせて、元データの列番号を返す
            % 
            index=struct();
            index.eeg_flag=3;
            index.eeg_time=1;
            index.eeg_Cz=4;index.eeg_NC1=5;
            index.eeg_C3=6;index.eeg_NC2=7;index.eeg_NC3=8;index.eeg_NC4=9;
            index.eeg_C4=10;index.eeg_NC5=11;
            index.imp_flag=3;
            index.imp_time=1;
            index.imp_Cz=12;index.imp_NC1=13;
            index.imp_C4=14;index.imp_NC2=15;index.imp_NC3=16;index.imp_NC4=17;
            index.imp_C3=18;index.imp_NC5=19;
            index.acc_flag=3;
            index.acc_time=1;
            index.acc_1=20;
            index.acc_2=21;
            index.acc_3=22;
            index.ofst_flag=3;
            index.ofst_time=1;
            index.ofst_Cz=23;index.ofst_NC1=24;
            index.ofst_C4=25;index.ofst_NC2=26;index.ofst_NC3=27;index.ofst_NC4=28;
            index.ofst_C3=29;index.ofst_NC5=30;
        end
    end
end
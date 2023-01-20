%{
plugデータの取り扱いクラス。
インポートと再整形。1session1インスタンス
基本解析関数を含む
2021/11/13より
2021/12/10 : チャンネル部分の整備
% logger_verごとの条件分岐を消して、継承により対応したい。
%}
classdef PlugData_core < handle
    properties
        fs=struct()
        chNames=[]
        storageDir
        dataName
        dataPath
        origin
        eeg=struct()
        imp=struct()
        acc=struct()
        ofst=struct()
        hardWare
        logger
        col=struct()
        shift=struct()
        loadOffset=3    % ヘッダ部分の削除
        DEBUG=false
    end
    properties(Access=private)
    end

    methods
        function obj=PlugData_core(storageDir,hardWare,logger)
            
            addpath("common");

            storageDir=strip(storageDir,"right","/");
            storageDir=strip(storageDir,"right","¥");
            obj.storageDir=strip(storageDir,"right","\");
            obj.fs.eeg=200;
            obj.fs.imp=obj.fs.eeg/4;
            obj.fs.acc=obj.fs.eeg/2;
            obj.fs.ofst=obj.fs.eeg/4;
            obj.hardWare=hardWare;
            obj.logger=logger;

            obj.col=PlugData_core.channelIndices(logger,hardWare);
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

        end
        function import(obj,dataName)
            % dataName must ends with .csv
            obj.dataName=dataName;
            obj.dataPath=fullfile(obj.storageDir,obj.dataName);
            obj.origin=readmatrix(obj.dataPath);
            obj.strip_eeg();
            if obj.logger=="PLUG_logger"
                obj.strip_imp();
            elseif obj.logger=="PLUG_logger2"
                obj.strip_imp();
                obj.strip_ofst();
            end
            obj.strip_acc();
            obj.get_dins();
        end
        function strip_eeg(obj)
            % 時間データの抜き出しと整列
            ind=obj.shift.eeg;
            stt=obj.loadOffset;
            obj.eeg.time=obj.export_time(obj.origin,obj.fs.eeg,ind,obj.logger);

            obj.eeg.flag=obj.origin(stt:end,obj.col.eeg_flag);

            if obj.hardWare=="PLUG0"
                obj.eeg.raw.C3=rmmissing(obj.origin(stt:end,obj.col.eeg_C3));
                obj.eeg.raw.F3=rmmissing(obj.origin(stt:end,obj.col.eeg_F3));
                obj.eeg.raw.T3=rmmissing(obj.origin(stt:end,obj.col.eeg_T3));
                obj.eeg.raw.O1=rmmissing(obj.origin(stt:end,obj.col.eeg_O1));
                obj.eeg.raw.O2=rmmissing(obj.origin(stt:end,obj.col.eeg_O2));
                obj.eeg.raw.C4=rmmissing(obj.origin(stt:end,obj.col.eeg_C4));
                obj.eeg.raw.F4=rmmissing(obj.origin(stt:end,obj.col.eeg_F4));
                obj.eeg.raw.T4=rmmissing(obj.origin(stt:end,obj.col.eeg_T4));
            else
                obj.eeg.raw.C3=rmmissing(obj.origin(stt:end,obj.col.eeg_C3));
                obj.eeg.raw.C4=rmmissing(obj.origin(stt:end,obj.col.eeg_C4));
                obj.eeg.raw.Cz=rmmissing(obj.origin(stt:end,obj.col.eeg_Cz));
                obj.eeg.raw.C3CzRef=obj.eeg.raw.C3-obj.eeg.raw.Cz;
                obj.eeg.raw.C4CzRef=obj.eeg.raw.C4-obj.eeg.raw.Cz;
            end
        end

        function strip_ofst(obj)
            % 時間データの抜き出しと整列
            ind=obj.shift.ofst;
            stt=obj.loadOffset;
            obj.ofst.time=obj.export_time(obj.origin,obj.fs.ofst,ind,obj.logger);
            obj.ofst.flag=rmmissing(obj.origin(stt:end,obj.col.ofst_flag));
            if obj.hardWare=="PLUG0"
                obj.ofst.raw.C3=rmmissing(obj.origin(stt:end,obj.col.ofst_C3));
                obj.ofst.raw.F3=rmmissing(obj.origin(stt:end,obj.col.ofst_F3));
                obj.ofst.raw.T3=rmmissing(obj.origin(stt:end,obj.col.ofst_T3));
                obj.ofst.raw.O1=rmmissing(obj.origin(stt:end,obj.col.ofst_O1));
                obj.ofst.raw.O2=rmmissing(obj.origin(stt:end,obj.col.ofst_O2));
                obj.ofst.raw.C4=rmmissing(obj.origin(stt:end,obj.col.ofst_C4));
                obj.ofst.raw.F4=rmmissing(obj.origin(stt:end,obj.col.ofst_F4));
                obj.ofst.raw.T4=rmmissing(obj.origin(stt:end,obj.col.ofst_T4));
            else
                obj.ofst.raw.C3=rmmissing(obj.origin(stt:end,obj.col.ofst_C3));
                obj.ofst.raw.C4=rmmissing(obj.origin(stt:end,obj.col.ofst_C4));
                [obj.ofst.raw.Cz,ind]=rmmissing(obj.origin(stt:end,obj.col.ofst_Cz));
                obj.ofst.raw.C3CzRef=obj.ofst.raw.C3-obj.ofst.raw.Cz;
                obj.ofst.raw.C4CzRef=obj.ofst.raw.C4-obj.ofst.raw.Cz;
                if length(ind)==length(obj.ofst.flag)
                    obj.ofst.flag=obj.ofst.flag(~ind);
                end
            end
        end

        function strip_imp(obj)
            % 時間データの抜き出しと整列
            ind=obj.shift.imp;
            stt=obj.loadOffset;
            obj.imp.time=obj.export_time(obj.origin,obj.fs.imp,ind,obj.logger);
            obj.imp.flag=rmmissing(obj.origin(stt:end,obj.col.imp_flag));
            if obj.hardWare=="PLUG0"
                obj.imp.raw.C3=rmmissing(obj.origin(stt:end,obj.col.imp_C3));
                obj.imp.raw.T3=rmmissing(obj.origin(stt:end,obj.col.imp_T3));
                obj.imp.raw.F3=rmmissing(obj.origin(stt:end,obj.col.imp_F3));
                obj.imp.raw.O1=rmmissing(obj.origin(stt:end,obj.col.imp_O1));
                obj.imp.raw.O2=rmmissing(obj.origin(stt:end,obj.col.imp_O2));
                obj.imp.raw.C4=rmmissing(obj.origin(stt:end,obj.col.imp_C4));
                obj.imp.raw.F4=rmmissing(obj.origin(stt:end,obj.col.imp_F4));
                obj.imp.raw.T4=rmmissing(obj.origin(stt:end,obj.col.imp_T4));
            else
                obj.imp.raw.C3=rmmissing(obj.origin(stt:end,obj.col.imp_C3));
                obj.imp.raw.C4=rmmissing(obj.origin(stt:end,obj.col.imp_C4));
                [obj.imp.raw.Cz,ind]=rmmissing(obj.origin(stt:end,obj.col.imp_Cz));
                if length(ind)==length(obj.imp.flag)
                    obj.imp.flag=obj.imp.flag(~ind);
                end
            end
        end
        function strip_acc(obj)
            % 時間データの抜き出しと整列
            stt=obj.loadOffset;
            ind=obj.shift.acc;
                obj.acc.time=obj.export_time(obj.origin,obj.fs.acc,ind,obj.logger);
                obj.acc.flag=rmmissing(obj.origin(stt:end,obj.col.acc_flag));
                obj.acc.raw.x=rmmissing(obj.origin(stt:end,ind));
                obj.acc.raw.y=rmmissing(obj.origin(stt:end,ind+1));
                [obj.acc.raw.z,ind]=rmmissing(obj.origin(stt:end,ind+2));
                obj.acc.raw.norm=sqrt(obj.acc.raw.x.^2+obj.acc.raw.y.^2+obj.acc.raw.z.^2);
                if obj.hardWare=="PLUG0"
                    obj.acc.raw.left=obj.acc.raw.x;
                    obj.acc.raw.top=obj.acc.raw.y;
                    obj.acc.raw.front=-obj.acc.raw.z;
                else
                    obj.acc.raw.left=obj.acc.raw.z;
                    obj.acc.raw.top=obj.acc.raw.x;
                    obj.acc.raw.front=-obj.acc.raw.y;
                    if length(ind)==length(obj.acc.flag)
                        obj.acc.flag=obj.acc.flag(~ind);
                    end
                end
        end
        %% 基本解析用関数
        function obj=filt_eeg(obj)
            % ss
            %
            %
            obj.eeg.filterd=struct();
            channels=string(fields(obj.eeg.raw));
            for chi=1:length(channels)
                ch=channels(chi);
                obj.eeg.filterd.(ch)=preset_filter(obj.eeg.raw.(ch),obj.fs.eeg,false);
            end
        end
        function obj=rem_offset_eeg(obj)
            % 作って使ってみたがあまり意味がない。
            %
            method="noneasy";
            if obj.logger=="PLUG_logger"
                disp("rem_offset_eeg() : invalid");
            else
                channels=string(fields(obj.eeg.raw));
                for chi=1:length(channels)
                    ch=channels(chi);
                    if method=="easy"
                        offset=obj.ofst.raw.(ch);
                        %offset=interp1(obj.ofst.time.',offset,obj.eeg.time.',"linear",offset(1));
                        offset=interp1(obj.ofst.time.',offset,obj.eeg.time.',"nearest",offset(1));
                        %offset=interp1(obj.ofst.time.',offset,obj.eeg.time.',"spline");

                        offset=movmean(offset,5);
                        % 最後の引数は外挿
                        obj.eeg.raw.(ch)=obj.eeg.raw.(ch)-offset;
                    else
                        jiteisu=0.1; % sec 
                        windowLen_eeg=obj.fs.eeg*jiteisu;   %200*0.1 0.1秒分のサンプル数
                        windowLen_ofst=obj.fs.ofst*jiteisu;
                        offset=obj.ofst.raw.(ch);   % 波形
                        filterd=obj.eeg.raw.(ch);   % 波形
                        figure(1);

                        for ind =windowLen_eeg:length(filterd)
                            % eegを時系列に走査する
                            ind_ofst=round(ind*obj.fs.ofst/obj.fs.eeg); % 同じ時間にindex変換
                            ofs=mean(offset(ind_ofst-windowLen_ofst+1:ind_ofst));
                            filterd(ind)=filterd(ind)-ofs;

                            if obj.DEBUG
                                plot([max(ind-2000,1):ind+100]/200,filterd(max(ind-2000,1):ind+100));
                                hold on
                                plot([max(ind-2000,1):ind+100]/200,obj.eeg.raw.(ch)(max(ind-2000,1):ind+100));
                                plot([max(ind_ofst-500,1):ind_ofst+25]/50,obj.ofst.raw.(ch)(max(ind_ofst-500,1):ind_ofst+25));
                                hold off
                                pause(0.01);
                            end
                        end
                        % 最後の引数は外挿
                        obj.eeg.raw.(ch)=filterd;
                    end
                end
            end
        end
        function obj=filt_eeg_alpha(obj)
            % 狭帯域フィルタ
            % 設定はpreset_filter参照
            obj.eeg.filterd=struct();
            channels=string(fields(obj.eeg.raw));
            for chi=1:length(channels)
                ch=channels(chi);
                obj.eeg.filterd.(ch)=preset_filter(obj.eeg.raw.(ch),obj.fs.eeg,true);
            end
        end
        function obj=filt_eeg_small(obj)
            % filter ハムノイズと線形トレンドのみ
            %
            obj.eeg.filterd=struct();
            channels=string(fields(obj.eeg.raw));
            for chi=1:length(channels)
                ch=channels(chi);
                wav=obj.eeg.raw.(ch)-mean(obj.eeg.raw.(ch));
                obj.eeg.filterd.(ch)=preset_filter_hum(wav,obj.fs.eeg);
                %obj.eeg.filterd.(ch)=wav;
            end
        end
        function obj=fft_eeg(obj,target)
            % psdを各時間窓で格納
            % tf-mapを保持しているということだ。
            % 0秒以降のデータのみ。
            if target==""
                target="raw";
            end
            obj.eeg.(target).spctl=struct();
            channels=string(fields(obj.eeg.(target)));
            winSize=obj.fs.eeg;

            obj.eeg.(target).spctl.windowSize=winSize;
            obj.eeg.(target).spctl.stride=round(0.1*winSize);
            obj.eeg.(target).spctl.windowSize=winSize;
            h=hanning(winSize);
            for chi=1:length(channels)
                ch=channels(chi);
                if ch=="spctl"
                    break
                end
                origWave=obj.eeg.(target).(ch)(obj.eeg.time>=0); % この実装が本当に良いのだろうか...
                fullLen=length(origWave);
                winNum=1+(fullLen-winSize)/(obj.eeg.(target).spctl.stride);
                tmp_psd=[];
                for ind=1:winNum
                    head=((ind-1)*obj.eeg.(target).spctl.stride)+1;
                    foot=head+winSize-1;
                    segment=origWave(head:foot);
                    %segment=origWave(head:foot)-mean(origWave(head:foot));
                    segment=segment.*h;
                    segment=fft(segment);
                    tmp_psd=[tmp_psd,(abs(segment(1:fix(end/2))).^2)/(obj.fs.eeg*obj.fs.eeg)];
                end
                obj.eeg.(target).spctl.(ch).indiv=tmp_psd;
                obj.eeg.(target).spctl.(ch).mean=mean(tmp_psd,2);
            end
            times=(0:winNum-1)*(obj.eeg.(target).spctl.stride/obj.fs.eeg);
            obj.eeg.(target).spctl.time=times;
        end
        function obj=set_flag(obj,leftTime,rightTime,flag)
            % change flag information
            % eeg
            leftInd=find(obj.eeg.time>=leftTime,1,"first");
            rightInd=find(obj.eeg.time<=rightTime,1,"last");
            obj.eeg.flag(leftInd:rightInd)=flag;
            obj.eeg.time=obj.export_time(obj.origin,obj.fs.eeg,obj.shift.eeg,obj.logger);
            % imp
            leftInd=find(obj.imp.time>=leftTime,1,"first");
            rightInd=find(obj.imp.time<=rightTime,1,"last");
            obj.imp.flag(leftInd:rightInd)=flag;
            obj.imp.time=obj.export_time(obj.origin,obj.fs.imp,obj.shift.imp,obj.logger);
            % acc
            leftInd=find(obj.acc.time>=leftTime,1,"first");
            rightInd=find(obj.acc.time<=rightTime,1,"last");
            obj.acc.flag(leftInd:rightInd)=flag;
            obj.acc.time=obj.export_time(obj.origin,obj.fs.acc,obj.shift.acc,obj.logger);
            % ofst
            leftInd=find(obj.ofst.time>=leftTime,1,"first");
            rightInd=find(obj.ofst.time<=rightTime,1,"last");
            obj.ofst.flag(leftInd:rightInd)=flag;
            obj.ofst.time=obj.export_time(obj.origin,obj.fs.ofst,obj.shift.ofst,obj.logger);
        end
        function obj=get_dins(obj)
            % change flag information
            obj.eeg.dins=flag2din(obj.eeg.flag);
            obj.imp.dins=flag2din(obj.imp.flag);
            obj.acc.dins=flag2din(obj.acc.flag);
            obj.ofst.dins=flag2din(obj.ofst.flag);
        end
    end
    methods(Static)
        function time=export_time(wave,fs,timeCh,logger)
            stt=3;
            time=0:1:length(rmmissing(wave(stt:end,timeCh)))-1;
            time=time/fs;
            flagCh=timeCh-1;
            time=time-min(time(wave(stt:end,flagCh)>0));
        end
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
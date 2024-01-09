%{
plugデータの取り扱いクラス。
インポートと再整形。1session1インスタンス
基本解析関数を含む
2021/11/13より
2021/12/10 : チャンネル部分の整備
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
        metrics=struct() % mf_devの仕事のコア
        hardWare
        logger
        col=struct()
        shift=struct()
        loadOffset=3    % csv内ヘッダの削除
        DEBUG=false
    end
    properties(Access=private)
    end

    methods
        function obj=PlugData_core(storageDir,hardWare,logger)
            pgmPath=which("PlugData_core");
            [~,pgmPath,~]=fileparts(pgmPath); 
            % このファイルがあるパスの取得
            addpath(pgmPath+"../common");

            storageDir=strip(storageDir,"right","/");
            storageDir=strip(storageDir,"right","¥");
            obj.storageDir=strip(storageDir,"right","\");
            obj.fs.eeg=200;
            obj.fs.imp=obj.fs.eeg/4;
            obj.fs.acc=obj.fs.eeg/2;
            obj.fs.ofst=obj.fs.eeg/4;
            obj.hardWare=hardWare;
            obj.logger=logger;

            obj.metrics.multi=struct(); % mf_devの仕事のコア
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
            obj.eeg.time=obj.export_time(obj.origin,obj.fs.eeg,ind);

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
            obj.ofst.time=obj.export_time(obj.origin,obj.fs.ofst,ind);
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
            obj.imp.time=obj.export_time(obj.origin,obj.fs.imp,ind);
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
                obj.acc.time=obj.export_time(obj.origin,obj.fs.acc,ind);
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
        function epoching(obj,center,leftSec,rightSec)
            % input:
            %   center : flag(int) 
            %   leftSec : 
            %   rightSec : 
            % メトリクスベースのepochingはMetricsMasterの方に実装されている。
            % 計算処理をPlugDataに持たせるか、MetricsMasterに持たせるか、悩み中。
            for modal=["eeg","imp","acc","ofst"]
                leftSample=leftSec*obj.fs.(modal);
                rightSample=rightSec*obj.fs.(modal);
                obj.(modal).epoched=struct();
                obj.(modal).epoched.time=[-leftSample/obj.fs.(modal) : 1/obj.fs.(modal) : rightSample/obj.fs.(modal)];%1*x配列
                obj.(modal).epoched.raw=struct();
                channels=string(fields(obj.(modal).raw));
                for channel=channels.'
                    obj.(modal).epoched.raw.(channel)=[];
                    if modal=="eeg"
                        obj.(modal).epoched.filterd.(channel)=[];
                    end
                end
                masterDin=obj.(modal).dins;
                for index =1:size(masterDin,2)
                    din=masterDin(1,index);
                    if din==center
                        zeroIndex=masterDin(2,index);
                        leftIndex=zeroIndex-leftSample;
                        rightIndex=zeroIndex+rightSample;
                        for channel=channels.'
                            obj.(modal).epoched.raw.(channel)=[obj.(modal).epoched.raw.(channel),obj.(modal).raw.(channel)(leftIndex:rightIndex)];%多次元配列trial数*x
                            if modal=="eeg"
                                obj.(modal).epoched.filterd.(channel)=[obj.(modal).epoched.filterd.(channel),obj.(modal).filterd.(channel)(leftIndex:rightIndex)];
                            end
                        end

                        obj.(modal).epoched.flag=obj.(modal).flag(leftIndex:rightIndex);%1*x配列
                        obj.(modal).epoched.dins=intersect(find(masterDin(2,:)>leftIndex),find(masterDin(2,:)<rightIndex));
                    end
                end
            end

        end
        %% 基本解析用関数
        function obj=filt_eeg_default(obj)
            % ここでプリセットしているが、バンドパスとハムとは分けた方がいい。
            %
            mtrName="EEGfilt_dflt";

            obj.eeg.filterd=struct();
            channels=string(fields(obj.eeg.raw));
            obj.metrics.(mtrName)=MetricsMaster("[rawEEG]","PlugData_core"); % filterd EEG格納場所
            filterdEEG=struct();
            for chi=1:length(channels)
                ch=channels(chi);
                obj.eeg.filterd.(ch)=preset_filter(obj.eeg.raw.(ch),obj.fs.eeg,false);
                % for backward compatile
                [filterdEEG.(ch),filtInfo]=obj.preset_filter(obj.eeg.raw.(ch),obj.fs.eeg,false);
                % 
            end
            obj.metrics.(mtrName).set(filterdEEG,filtInfo);
            obj.metrics.(mtrName).axyz.time=obj.eeg.time;
            obj.metrics.(mtrName).flag=obj.eeg.flag;
            obj.metrics.(mtrName).dins=obj.eeg.dins;
            obj.metrics.(mtrName).info.fs=obj.fs.eeg;
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
        function obj=filt_hum(obj,targetMetrics)
            % filter ハムノイズと直流成分の除去
            % 
            arguments
                obj
                targetMetrics (1,:) string = ["originalEEG"]
            end
            if targetMetrics(1)=="originalEEG"
                baseWav=obj.eeg.raw;
                obj.metrics.("EEGfilt_hum")=MetricsMaster("[rawEEG]",string(mfilename)); % filterd EEG格納場所
                channels=string(fields(obj.eeg.raw));
            else
                baseMet=MetricsMaster.parse(obj.metrics,targetMetrics);
                baseMet.make("filt_hum",string(mfilename));
                baseWav=baseMet.in;
                channels=baseMet.components;
            end
            filterdEEG=struct();
            for chi=1:length(channels)
                ch=channels(chi);
                wav=baseWav.(ch)-mean(baseWav.(ch));
                [filterdEEG.(ch),filtInfo]=obj.preset_filter(wav,obj.fs.eeg,false,"BandPassSw",false);
            end
            if targetMetrics(1)=="originalEEG"
                obj.metrics.EEGfilt_hum.set(filterdEEG,filtInfo);
                obj.metrics.EEGfilt_hum.axyz.time=obj.eeg.time;
                obj.metrics.EEGfilt_hum.flag=obj.eeg.flag;
                obj.metrics.EEGfilt_hum.dins=obj.eeg.dins;
                obj.metrics.EEGfilt_hum.info.fs=obj.fs.eeg;
            else
                baseMet.no.("filt_hum").set(filterdEEG,filtInfo);
                baseMet.no.("filt_hum").axyz.time=obj.eeg.time;
                baseMet.no.("filt_hum").flag=obj.eeg.flag;
                baseMet.no.("filt_hum").dins=obj.eeg.dins;
                baseMet.no.("filt_hum").info.fs=baseMet.info.fs;
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
        function obj=fft_metrics(obj,origin,options)
            % psdを各時間窓で格納
            % tf-mapを保持しているということだ。
            % 0秒以降のデータのみ。
            % input:
            %   origin (str): Defaults to "EEGfilt_dflt".
            % optional:
            %   MultiFlag (bool) : parse origin based on obj.metrics.multi field.
            %                      Defaults to false.
            arguments
                obj
                origin (1,:) string = "EEGfilt_dflt"
                options.MultiFlag (1,1) logical = false
            end
            if options.MultiFlag
                tango=MetricsMaster.parse(obj.metrics.multi,origin);
            else
                tango=MetricsMaster.parse(obj.metrics,origin);
            end

            metric1="spctl";
            metric2="timeMean";

            tango.make(metric1,string(mfilename)+"_l360");
            channels=tango.components;
            flag=tango.flag;
            fs=tango.info.fs;
            winSize=fs;
            stride=round(0.1*winSize);


            h=hanning(winSize);

            tmp_spctls=struct();
            tmp_meanSpctls=struct();
            for chi=1:length(channels)
                ch=channels(chi); % ここの例外も減ってハッピー
                origWave=tango.in.(ch)(tango.axyz.time>=0); % この実装が本当に良いのだろうか...
                fullLen=length(origWave);
                winNum=1+(fullLen-winSize)/stride;
                tmp_psd=[];
                tmp_flag=[];
                for ind=1:winNum
                    head=((ind-1)*stride)+1;
                    foot=head+winSize-1;
                    segment=origWave(head:foot);
                    %segment=origWave(head:foot)-mean(origWave(head:foot));
                    segment=segment.*h;
                    segment=fft(segment);
                    tmp_psd=[tmp_psd,(abs(segment(1:fix(end/2))).^2)/(fs*fs)];
                    centerIndex=round((head+foot)/2);
                    tmp_flag=[tmp_flag,flag(centerIndex)];
                end
                tmp_spctls.(ch)=tmp_psd;
                tmp_meanSpctls.(ch)=mean(tmp_psd,2);
            end           
            tango.no.(metric1).set(tmp_spctls,"spectle");
            tango.no.(metric1).info.windowSize=winSize;
            tango.no.(metric1).info.stride=stride;
            times=(0:winNum-1)*(stride/fs); % flagの場所と食い違っているので、オフセットした方がいいかも。fs/2で。
            tango.no.(metric1).axyz.time=times;
            tango.no.(metric1).axyz.freq=(1:fix(fs/2))-1;
            tango.no.(metric1).dimLabel=["freq","time"];
            tango.no.(metric1).flag=tmp_flag;
            tango.no.(metric1).flag2din();
            tango.no.(metric1).make(metric2,"PlugData_core_l336");
            tango.no.(metric1).no.(metric2).set(tmp_meanSpctls,"timeMean");
            tango.no.(metric1).no.(metric2).axyz.freq=1:fix(fs/2);
            tango.no.(metric1).no.(metric2).dimLabel=["freq","-"];
        end
        function obj=set_flag(obj,leftTime,rightTime,flag)
            % change flag information
            % eeg
            leftInd=find(obj.eeg.time>=leftTime,1,"first");
            rightInd=find(obj.eeg.time<=rightTime,1,"last");
            obj.eeg.flag(leftInd:rightInd)=flag;
            obj.eeg.time=obj.export_time(obj.origin,obj.fs.eeg,obj.shift.eeg);
            % imp
            leftInd=find(obj.imp.time>=leftTime,1,"first");
            rightInd=find(obj.imp.time<=rightTime,1,"last");
            obj.imp.flag(leftInd:rightInd)=flag;
            obj.imp.time=obj.export_time(obj.origin,obj.fs.imp,obj.shift.imp);
            % acc
            leftInd=find(obj.acc.time>=leftTime,1,"first");
            rightInd=find(obj.acc.time<=rightTime,1,"last");
            obj.acc.flag(leftInd:rightInd)=flag;
            obj.acc.time=obj.export_time(obj.origin,obj.fs.acc,obj.shift.acc);
            % ofst
            leftInd=find(obj.ofst.time>=leftTime,1,"first");
            rightInd=find(obj.ofst.time<=rightTime,1,"last");
            obj.ofst.flag(leftInd:rightInd)=flag;
            obj.ofst.time=obj.export_time(obj.origin,obj.fs.ofst,obj.shift.ofst);
        end
        function obj=get_dins(obj)
            % change flag information
            obj.eeg.dins=flag2din(obj.eeg.flag);
            obj.imp.dins=flag2din(obj.imp.flag);
            obj.acc.dins=flag2din(obj.acc.flag);
            obj.ofst.dins=flag2din(obj.ofst.flag);
        end

        function obj=epoch_filtEEG(obj,center,leftSec,rightSec,options)
            % epoching based on flag information
            % epoching処理だけを外に出して、それを使う形にした方がいい。
            % 汎用epochingがMetricsMasterの中にあるので、それを頼る形で修正したい。
            % input:
            %   center : flag(int) 
            %   leftSec : int
            %   rightSec : int
            %   title(optional) : string
            arguments
                obj
                center (1,1) int
                leftSec (1,1) int
                rightSec (1,1) int
                options.Title (1,1) string = "epcA"
            end
            title=options.Title;
            logCode="epoch_c"+string(center)+"_l"+string(leftSec)+"s_r"+string(rightSec)+"s";
            orig="EEGfilt_dflt";
            % このorigについて、filt以外を受け入れるとともに、
            % noとか予約フィールド名前を除去する条件文を追加
            origMET=obj.metrics.(orig); 
            tmpEpoched=struct(); % 結果を一時的に格納
            tmpFlag=[];
            tmpDins=[];

            fsHere=origMET.info.fs;
            leftSample=leftSec*fsHere;
            rightSample=rightSec*fsHere;
            channels=obj.metrics.(orig).components;
            for ch=channels.' % とりあえず空配列の作成
                tmpEpoched.(ch)=[];
            end
            masterDin=origMET.dins;
            for index =1:size(masterDin,2)
                din=masterDin(1,index);
                if din==center
                    zeroIndex=masterDin(2,index);
                    leftIndex=zeroIndex-leftSample;
                    rightIndex=zeroIndex+rightSample;
                    for ch=channels.'
                        tmpEpoched.(ch)=[tmpEpoched.(ch),origMET.in.(ch)(leftIndex:rightIndex)];
                    end

                    tmpFlag=[tmpFlag,origMET.flag(leftIndex:rightIndex)];
                    tmpDins=[tmpDins,intersect(find(masterDin(2,:)>leftIndex),find(masterDin(2,:)<rightIndex))];
                end
            end
            % 結果の格納
            obj.metrics.(orig).make(title,"PlugData_core:epoch_filtEEG"); % 出力プロパティの制作
            origMET.no.(title).axyz.time=[-leftSample/fsHere : 1/fsHere : rightSample/fsHere];%1*x配列
            origMET.no.(title).axyz.trial=1:size(tmpFlag,2);
            origMET.no.(title).dimLabel=["time","trial"];
            origMET.no.(title).set(tmpEpoched,logCode);
            origMET.no.(title).flag=tmpFlag;
            origMET.no.(title).dins=tmpDins;
            origMET.no.(title).info.fs=origMET.info.fs;
        end
    end
    methods(Static)
        function time=export_time(wave,fs,timeCh)
            stt=3;
            time=0:1:length(rmmissing(wave(stt:end,timeCh)))-1;
            time=time/fs;
            flagCh=timeCh-1;
            time=time-min(time(wave(stt:end,flagCh)>0));
        end
        function index=channelIndices()
            % hardwareに合わせて、元データの列番号を返す
            % ひとまずラボ版ロガーに合わせてデフォルトを設定しておく
            index=struct();
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
        function [filterd,filtReport]=preset_filter(wav,fs,alphaFlag,options)
            % 50notchと3-70bandpassをかける。
            % MEtricsMasterの中に移植してあげるべきだろうか...
            % 引数:
            %   wav : 波形データ。
            %   fs  : サンプリング周波数
            %   alphaFlag : trueとすると8~13のバンドパスもかかる。
            arguments
                wav double
                fs (1,1) double = 200
                alphaFlag (1,1) logical = false
                options.DrawFlag (1,1) logical = false % デバッグ用
                options.Freq (2,1) double=[3,70]
                options.bandPassSw (1,1) logical = true
            end
            filtReport="";

            %% notch
            StFreq=48;
            EnFreq=52;
            stopWn = [StFreq EnFreq]/(fs/2);
            [paramB,paramA] = butter(3,stopWn,'stop');
            filterd = filtfilt(paramB, paramA,wav);

            if options.DrawFlag
                figure();
                subplot(4,1,1); plot(wav);
                subplot(4,1,2); plot(filterd);
            end
            filtReport=filtReport...
                +MetricsMaster.gen_filtCode_btws(true,StFreq,EnFreq,3,true);
            %% bandpass
            if options.bandPassSw
                StFreq=options.Freq(1);
                EnFreq=options.Freq(2);
                Wn=[StFreq EnFreq]/(fs/2);
                [paramB,paramA] = butter(3,Wn,'bandpass');
                filterd = filtfilt(paramB, paramA,filterd);
                if options.DrawFlag
                    subplot(4,1,3); plot(filterd);
                end
                filtReport=filtReport...
                    +MetricsMaster.gen_filtCode_btws(false,StFreq,EnFreq,3,true);
            end

            if alphaFlag

                StFreq=8;
                EnFreq=13;
                Wn=[StFreq EnFreq]/(fs/2);
                [paramB,paramA] = butter(3,Wn,'bandpass');
                filterd = filtfilt(paramB, paramA,filterd);
                if drawFlag
                    subplot(4,1,4); plot(filterd);
                end
                filtReport=filtReport...
                    +MetricsMaster.gen_filtCode_btws(false,StFreq,EnFreq,3,true);
            end

        end
    end
end
%{
plugデータの解析実施
2022/8/18より
middleware判定値を含めたもの
個人解析かつ単一ブロック解析用。middleware実験であることを前提とする。
%}
classdef MyAnalysis_ASSR < PlugData_thimple
    properties
        cutoffSeconds=10;
        blockLabel="LABEL" % 保持しているブロックデータの名前。
        target="raw"
        saveDir=""
        offset=1
        filtMode="wide"
        middleware=struct()
        info=struct()
        taskInfo=struct()
    end
    properties(Access=private)
    end

    methods
        function obj=MyAnalysis_ASSR(storageDir,dataName)
            obj@PlugData_thimple(storageDir,"soundV1")
            % 親クラスの定義呼び出し。
            obj.import(dataName);
            obj.load_soundData();
            obj.filt_eeg_default();
            obj.filt_eeg_wide();
            obj.filt_hum(["soundData"]);
            obj.fft_metrics();
            obj.fft_metrics(["EEGfilt_wide"]);
            obj.fft_metrics(["soundData","filt_hum"]);
        end
        function obj=load_soundData(obj)
            obj.metrics.soundData=MetricsMaster("[rawSound]",string(mfilename));
            tmp=struct();
            tmp.auIn=obj.origin(:,11);
            axyz=struct("time",obj.eeg.time); 
            flag=obj.eeg.flag;
            units=struct("time","s", "Z","¥muV");
            dimLabel=["time"];
            tmpInfo=struct("fs",obj.fs.eeg);
            obj.metrics.soundData.set_instance("extract_sound",tmp,axyz,flag,units,dimLabel,tmpInfo)
        end
        function flag=search_flaginEEG(obj,time)
            eegFlag=obj.eeg.flag;
            eegTime=obj.eeg.time;
            flag=[];
            for t =time.'
                [~,ind]=min(abs(eegTime-t));
                flag=[flag,eegFlag(ind)];
            end
        end

        function obj=filt_eeg_wide(obj)
            % ここでプリセットしているが、バンドパスとハムとは分けた方がいい。
            %
            mtrName="EEGfilt_wide";

            obj.eeg.filterd=struct();
            channels=string(fields(obj.eeg.raw));
            obj.metrics.(mtrName)=MetricsMaster("[rawEEG]",string(mfilename)); % filterd EEG格納場所
            filterdEEG=struct();
            for chi=1:length(channels)
                ch=channels(chi);
                [filterdEEG.(ch),filtInfo]=obj.preset_filter(obj.eeg.raw.(ch),obj.fs.eeg,"Freq",[3,99]);
            end
            obj.metrics.(mtrName).set(filterdEEG,filtInfo);
            obj.metrics.(mtrName).axyz.time=obj.eeg.time;
            obj.metrics.(mtrName).flag=obj.eeg.flag;
            obj.metrics.(mtrName).dins=obj.eeg.dins;
            obj.metrics.(mtrName).info.fs=obj.fs.eeg;
        end

        function overView(obj,figN,visMetrics,options)
            % description:
            %   モンタージュをちゃんと取ったもので出し直し
            % input:
            %   figN : int
            %       描画するfigure番号 Defaults tov 1.
            %   drawRange : 1x2 double
            arguments
                obj
                figN (1,1) double = 1 
                visMetrics (1,1) string = "EEGfilt_dflt"
                options.DrawRangeX (1,2) double = [1,1]
                options.DrawRangeY (1,2) double = [-1,1]*1e-5
            end
            drRx=options.DrawRangeX;
            drRy=options.DrawRangeY;
            f=figure(figN);
            f.Position=[10,10,1000,800];
            time=obj.origin(:,1);

            axCzC3=subplot(3,1,1);
            wave=-obj.metrics.(visMetrics).in.C3CzRef;
            plot(time,wave-mean(wave));
            title("Cz-C3");

            axCzC4=subplot(3,1,2);
            wave=obj.metrics.(visMetrics).in.Cz-(obj.metrics.(visMetrics).in.C3+obj.metrics.(visMetrics).in.C4)./2;
            plot(time,wave-mean(wave));
            title("Cz-(C4+C3)");

            axSound=subplot(3,1,3);
            wave=obj.metrics.soundData.no.filt_hum.in.auIn;
            plot(time,wave-mean(wave));
            title("sound");

            linkaxes([axCzC3,axCzC4],"y");
            linkaxes([axCzC3,axCzC4,axSound],"x");
            figout(figN,obj.saveDir,"overView_all");
            
            if drRx(1)~=drRx(2)
                xlim(drRx);
                axCzC3.YLim=drRy;
                axCzC4.YLim=drRy;
                figout(figN,obj.saveDir,"overView_spot");
            end
        end
        function overView_origin(obj,figN)
            % description:
            %
            % input:
            %   figN : int
            %       描画するfigure番号
            %   も
            f=figure(figN);
            f.Position=[10,10,1000,800];
            time=obj.origin(:,1);
            axs=struct();
            for i=1:8
                axs.("ch"+string(i))=subplot(4,2,i);
                wave=obj.origin(:,3+i);
                plot(time,wave-mean(wave));
                title("ch"+string(i))
            end
            linkaxes([axs.ch1,axs.ch2,axs.ch3,axs.ch4,axs.ch5,axs.ch6,axs.ch7,axs.ch8],"xy");
            %xlim([0,60]);
            figout(figN,obj.saveDir,"overView_origWave");
        end
        function tfView(obj,figN,channel)
            arguments
                obj
                figN (1,1) int64 = 1
                channel (1,1) string = "C3CzRef"
            end
            tango=MetricsMaster.parse(obj.metrics,["EEGfilt_wide","spctl"]);
            drRng=[5,95];

            figure(double(figN));
            psd=tango.in.(channel);
            f=CreateTimeFrequencyMap(log10(psd(drRng(1):drRng(2),:)),drRng,0.9,1);
            c = colorbar;
            c.Label.String = 'log-Power [μV^2]';
            figout(figN,obj.saveDir,"tf");
        end
        function tfView_state(obj,figN,state,ch)
            % ステートごとのtf描画
            % 
            % 
            stride=obj.eeg.epoched.spctl.stride;
            obj.offset=floor(obj.cutoffSeconds*200/stride);
            offset=obj.offset;
            drRng=[5,95];

            figure(figN)
            psd=obj.eeg.(obj.target).spctl.(obj.channel).indiv;
            f=CreateTimeFrequencyMap(log10(psd(drRng(1):drRng(2),offset:end)),drRng,0.9,1);
            c = colorbar;
            c.Label.String = 'log-Power [μV^2]';
            figout(figN,obj.saveDir,"tf_"+obj.blockLabel);
        end
        function indivPsdView(obj,figN)
            stride=obj.eeg.(obj.target).spctl.stride;
            obj.offset=floor(obj.cutoffSeconds*200/stride);
            offset=obj.offset;

            figure(figN);
            indiv_psds=obj.eeg.(obj.target).spctl.(obj.channel).indiv;
            mean_psds=mean(indiv_psds(:,offset:end),2);
            semilogy(0:99,indiv_psds);
            hold on;
            semilogy(0:99,mean_psds,"r","LineWidth",3);
            grid on;
            xlabel("frequency [Hz]");
            ylabel("psd [\muV/Hz]");
            %ylim([1e-30,1e-10]);
            figout(figN,obj.saveDir,"psds_"+obj.blockLabel);
        end
    end
    methods(Static)
        function [indValue,metaInd]=getFromDin(searchDin, dinMatrix)

            metaInd=find(dinMatrix(1,:)==searchDin);
            indValue=dinMatrix(2,metaInd);
        end
    end
end
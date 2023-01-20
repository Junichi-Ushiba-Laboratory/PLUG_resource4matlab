%{
PlugDataに解析用関数を付加。
このレベルから実験タスク設定を反映させる想定
2022/2/10より

%}
classdef PlugAnalysis < PlugData_thimple
    properties
        cutoffSeconds=10;
        label="LABEL"
        target="raw"
        saveDir=""
        channel="C3"
        offset=1
        filtMode="wide"
    end
    properties(Access=private)
    end

    methods
        function obj=PlugAnalysis(storageDir,dataName)
            addpath("core")
            obj=obj@PlugData_thimple(storageDir)
            % load data.
            obj.import(dataName);
        end
        %% 実行セット
        function obj=execute(obj,label,figNoffset,target)
            obj.target=target;
            obj.saveDir="fig_psd_PLG_"+obj.target;
            obj.label=label;
            % preprocessing
            if obj.filtMode=="alpha"
                obj=obj.filt_eeg_alpha();
            else
                obj=obj.filt_eeg();
            end
            % visualize overview
            if contains(label,"blink")
                obj.epoching(3,2,3);
                obj.epochView(1+figNoffset);
            else
                obj.overView(1+figNoffset);
            end
            obj.multiChView(1+figNoffset);
            % psd算出
            obj=obj.fft_eeg(obj.target);
            % visualize t-fMap
            obj.tfView(2+figNoffset)
            % visualize indiv psds
            obj.indivPsdView(3+figNoffset)
        end
        function obj=execute_forBlinkTemplete(obj,label,figNoffset,target)
            obj.target=target;
            %obj.saveDir="fig_blinkTemplete_"+obj.target;
            obj.label=label;
            % preprocessing
            obj=obj.filt_eeg("preset");
            % visualize overview
            obj.epoching(2,2,2.2);
            obj.epochView(1+figNoffset);
            obj.overView(1+figNoffset);
            obj.multiChView(1+figNoffset);
            % psd算出
            obj=obj.fft_eeg(obj.target);
        end
        %% 解析関数_追加
        %% 描画関数
        function overView(obj,figN)
            onset=find(obj.eeg.flag==0,1,"last");
            figure(figN);
            ax1=subplot(2,1,1);
            wave=obj.eeg.(obj.target).(obj.channel)(onset:end);
            time=obj.eeg.time(onset:end)-obj.cutoffSeconds;

            plot(time,wave-mean(wave));
            %ylim([-1.5e-4,1e-4]);
            ax2=subplot(2,1,2);
            plot(time,obj.eeg.flag(onset:end));
            subplot(2,1,1);
            linkaxes([ax1,ax2],"x");
            %xlim([0,60]);
            figout(figN,obj.saveDir,"overView_"+obj.label);
        end
        function multiChView(obj,figN)
            onset=find(obj.eeg.flag(1:end/2)==3,1,"last");
            figure(figN);
            time=obj.eeg.time(onset:end)-obj.cutoffSeconds;
            axes=[];
            if obj.hardWare=="PLUG0"
                channels=["C3","C4","F3","F4","T3","T4"];
                for count=1:6
                    ax_tmp=subplot(4,2,count);
                    axes=[axes,ax_tmp];
                    wave=obj.eeg.(obj.target).(channels(count))(onset:end);
                    plot(time,wave-mean(wave));
                    ylabel(channels(count));
                    grid on;
                end
                grid on;
                %ylim([-1.5e-4,1e-4]);
                ax4=subplot(4,2,7);
                plot(time,obj.eeg.flag(onset:end));
                ax8=subplot(4,2,8);
                plot(time,obj.eeg.flag(onset:end));
                axes=[axes,ax4,ax8];
                subplot(4,2,1);
                linkaxes(axes,"x");
            else
                channels=["C3","C4","Cz"];
                for count=1:3
                    ax_tmp=subplot(3,2,count);
                    axes=[axes,ax_tmp];
                    wave=obj.eeg.(obj.target).(channels(count))(onset:end);
                    plot(time,wave-mean(wave));
                    ylabel(channels(count));
                    grid on;
                end
                grid on;
                %ylim([-1.5e-4,1e-4]);
                ax4=subplot(3,2,5);
                plot(time,obj.eeg.flag(onset:end));
                ax8=subplot(3,2,6);
                plot(time,obj.eeg.flag(onset:end));
                axes=[axes,ax4,ax8];
                subplot(3,2,1);
                linkaxes(axes,"x");
            end
            %xlim([0,60]);
            figout(figN,obj.saveDir,"multiView_"+obj.label);
        end
        function epochView(obj,figN)
            figure(figN);
            ax1=subplot(2,1,1);
            wave=obj.eeg.epoched.(obj.target).("C3")+obj.eeg.epoched.(obj.target).("C4")/2;
            time=obj.eeg.epoched.time;

            plot(time,wave-mean(wave));
            %ylim([-1.5e-4,1e-4]);
            ax2=subplot(2,1,2);
            plot(time,obj.eeg.epoched.flag);
            subplot(2,1,1);
            linkaxes([ax1,ax2],"x");
            %xlim([0,60]);
            figout(figN,obj.saveDir,"epochView_"+obj.label);
        end
        function tfView(obj,figN)
            stride=obj.eeg.(obj.target).spctl.stride;
            obj.offset=max(floor(obj.cutoffSeconds*200/stride),1);
            offset=obj.offset;
            drRng=[5,95];

            figure(figN)
            psd=obj.eeg.(obj.target).spctl.(obj.channel).indiv;
            f=CreateTimeFrequencyMap(log10(psd(drRng(1):drRng(2),offset:end)),drRng,0.9,1);
            c = colorbar;
            c.Label.String = 'log-Power [μV^2]';
            figout(figN,obj.saveDir,"tf_"+obj.label);
        end
        function indivPsdView(obj,figN)
            stride=obj.eeg.(obj.target).spctl.stride;
            obj.offset=max(floor(obj.cutoffSeconds*200/stride),1);
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
            figout(figN,obj.saveDir,"psds_"+obj.label);
        end

    end
    methods(Static)
    end
end
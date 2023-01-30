%{
PlugDataに解析用関数を付加。
このレベルから実験タスク設定を反映させる想定

多様なノイズを含んだデータセットを用いる想定
これらの波形を並列描画するスクリプトとして作成する
%}
classdef MyAnalysis_4BA < PlugData_thimple
    properties
        target="filterd"
        saveDir=""
        channel="C3"
        offset=1
    end
    properties(Access=private)
    end

    methods
        function obj=MyAnalysis_4BA(storageDir,dataName)
             
            obj=obj@PlugData_thimple(storageDir)
            % load data.
            obj.import(dataName);
        end
        %% 実行セット
        function obj=execute_preprocess(obj)
            % preprocessing
            obj.filt_eeg();
            % 全体fft
            obj.fft_eeg(obj.target);
        end
        function obj=execute_epochedView(obj,varargin)
            figNoffset=1;
            if nargin>=2
                for i=2:nargin
                    if varargin(i)=="target"
                        obj.target=varargin(i+1);
                    elseif varargin(i)=="figNoffset"
                        figNoffset=varargin(i+1);
                    end
                end
            end
            obj.saveDir="figs_"+obj.target;
            [idlabel,~]=obj.get_labelID();

            % visualize overview
            taskN=length(fields(obj.labelsID));
            for i=1:taskN
                task=idlabel.("id_"+string(i));
                obj.epoching(i,0,3);
                obj.epochView(figNoffset);
                sgtitle(task);
                figout(figNoffset,obj.saveDir,"epochedView_"+task,"nosync");
                figNoffset=figNoffset+1;
            end
            % visualize t-fMap
            for i=1:taskN
                task=idlabel.("id_"+string(i));
                % psd算出
                obj.epoching(i,0,3);
                obj.fft_epochedEeg(obj.target);
                obj.tfView(figNoffset,"C3");
                figout(figNoffset,obj.saveDir,"tf_"+task+"_C3");
                figNoffset=figNoffset+1;

                obj.tfView(figNoffset,"C4");
                figout(figNoffset,obj.saveDir,"tf_"+task+"_C4");
                figNoffset=figNoffset+1;

                obj.tfView(figNoffset,"Cz");
                figout(figNoffset,obj.saveDir,"tf_"+task+"_Cz");
                figNoffset=figNoffset+1;
            end

            % visualize indiv psds
            % obj.indivPsdView(figNoffset)
            
            obj.PsdView_tasks(figNoffset,"C3");
            obj.PsdView_tasks(figNoffset+1,"C4");
            obj.PsdView_tasks(figNoffset+2,"Cz");
            obj.PsdView_tasks(figNoffset+3,"C3CzRef");
            obj.PsdView_tasks(figNoffset+4,"C4CzRef");
        end
        
        %% 解析関数_追加
        function ERDs=get_ERD(obj)
            % code here
        end
        %% 描画関数
        function f=epochView(obj,figN)
            f=figure(figN);
            time=obj.eeg.epoched.time;

            ax1=subplot(3,1,1);
            wave=obj.eeg.epoched.(obj.target).("C3");
            plot(time,wave-mean(wave));
            ylabel(obj.target+" EEG in C3");
            ax2=subplot(3,1,2);
            wave=obj.eeg.epoched.(obj.target).("C4");
            plot(time,wave-mean(wave));
            ylabel(obj.target+" EEG in C4");
            ax3=subplot(3,1,3);
            wave=obj.eeg.epoched.(obj.target).("Cz");
            plot(time,wave-mean(wave));
            ylabel(obj.target+" EEG in Cz");

            subplot(3,1,1);
            linkaxes([ax1,ax2,ax3],"x");
        end
        function f=tfView(obj,figN,ch)
            f=figure(figN);
            drRng=[5,45];

            psd=obj.eeg.epoched.(obj.target).spctl.(ch).mean;
            CreateTimeFrequencyMap(log10(psd(drRng(1):drRng(2),obj.offset:end)),drRng,0.9,1);
            c = colorbar();
            c.Label.String = 'log-Power [μV^2]';
            c.Limits=[-17,-11];
        end
        function f=PsdView_tasks(obj,figN,ch)
            % 1ちゃんねるについて、タスク間での平均PSDの比較
            f=figure(figN);
            legends=[];
            for i=1:length(fields(obj.labelsID))
                [idlabel,~]=obj.get_labelID();
                task=idlabel.("id_"+string(i));
                % psd算出
                obj.epoching(i,0,3);
                obj.fft_epochedEeg(obj.target);
                obj.PsdView_single(figN,ch);
                hold on;
                legends=[legends,task];
            end
            legend(legends);
            figout(figN,obj.saveDir,"psds_"+ch);
        end
        function f=PsdView_single(obj,figN,ch)
            % 1ちゃんねるについて、タスク間での平均PSDの比較
            f=figure(figN);
            indiv_psds=obj.eeg.epoched.(obj.target).spctl.(ch).indiv;
            mean_psds=squeeze(mean(indiv_psds(:,:,:),[2,3]));
            %semilogy(0:99,indiv_psds);
            %hold on;
            semilogy(0:99,mean_psds,"LineWidth",2);
            grid on;
            xlabel("frequency [Hz]");
            ylabel("psd [\muV/Hz]");
            %ylim([1e-30,1e-10]);
        end

    end
    methods(Static)
    end
end
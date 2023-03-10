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
        function obj=loc_execute_preprocess(obj)
            % preprocessing
            obj.filt_eeg();
            % 全体fft
            obj.fft_eeg(obj.target);
        end
        function obj=loc_execute_epochedView(obj,varargin)
            figNum=1;
            if nargin>=2
                for i=2:nargin
                    if varargin(i)=="target"
                        obj.target=varargin(i+1);
                    elseif varargin(i)=="figNoffset"
                        figNum=varargin(i+1);
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
                obj.loc_epochView(figNum);
                task=strrep(task,"_","\_");
                sgtitle(task);
                figout(figNum,obj.saveDir,"epochedView_"+task,"nosync");
                figNum=figNum+1;
            end
            % visualize t-fMap
            for i=1:taskN
                task=idlabel.("id_"+string(i));
                % psd算出
                obj.epoching(i,0,3);
                obj.fft_epochedEeg(obj.target);
                obj.loc_tfView(figNum,"C3");
                figout(figNum,obj.saveDir,"tf_"+task+"_C3");
                figNum=figNum+1;

                obj.loc_tfView(figNum,"C4");
                figout(figNum,obj.saveDir,"tf_"+task+"_C4");
                figNum=figNum+1;

                obj.loc_tfView(figNum,"Cz");
                figout(figNum,obj.saveDir,"tf_"+task+"_Cz");
                figNum=figNum+1;
            end

            % visualize indiv psds
            % obj.indivPsdView(figNoffset)
            
            obj.loc_PsdView_tasks(figNum,"C3");
            obj.loc_PsdView_tasks(figNum+1,"C4");
            obj.loc_PsdView_tasks(figNum+2,"Cz");
            obj.loc_PsdView_tasks(figNum+3,"C3CzRef");
            obj.loc_PsdView_tasks(figNum+4,"C4CzRef");
        end
        
        %% 解析関数_追加
        function ERDs=loc_get_ERD(obj)
            % code here
        end
        %% 描画関数
        function f=loc_epochView(obj,figN)
            % エポッキング後の波形を重ね書きする。
            f=figure(figN);
            time=obj.eeg.epoched.time;

            ax1=subplot(3,1,1);
            wave=obj.eeg.epoched.(obj.target).("C3")*1e6; %V to uV
            plot(time,wave-mean(wave));
            ylabel(obj.target+" EEG\_C3[\muV]");
            ax2=subplot(3,1,2);
            wave=obj.eeg.epoched.(obj.target).("C4")*1e6;
            plot(time,wave-mean(wave));
            ylabel(obj.target+" EEG\_C4[\muV]");
            ax3=subplot(3,1,3);
            wave=obj.eeg.epoched.(obj.target).("Cz")*1e6;
            plot(time,wave-mean(wave));
            ylabel(obj.target+" EEG\_Cz[\muV]");
            xlabel("time [s]");
            subplot(3,1,1);
            linkaxes([ax1,ax2,ax3],"xy");
            ylim([-70,70]);
        end
        function f=loc_tfView(obj,figN,ch)
            f=figure(figN);
            drRng=[5,45];

            psd=obj.eeg.epoched.(obj.target).spctl.(ch).mean;
            CreateTimeFrequencyMap(log10(psd(drRng(1):drRng(2),obj.offset:end)),drRng,0.9,1);
            c = colorbar();
            c.Label.String = 'log-Power [μV^2]';
            c.Limits=[-17,-11];
        end
        function f=loc_PsdView_tasks(obj,figN,ch)
            % 1チャンネルについて、タスク間での平均PSDの比較
            f=figure(figN);
            legends=[];
            for i=1:length(fields(obj.labelsID))
                [idlabel,~]=obj.get_labelID();
                task=idlabel.("id_"+string(i));
                % psd算出
                obj.epoching(i,0,3);
                obj.fft_epochedEeg(obj.target);
                obj.loc_PsdView_single(figN,ch);
                hold on;
                task=strrep(task,"_","\_");
                legends=[legends,task];
            end
            legend(legends);
            figout(figN,obj.saveDir,"psds_"+ch);
        end
        function f=loc_PsdView_single(obj,figN,ch)
            % 1チャンネルに着目して、PSD描出。epochingが済んでいて、描出したいepochが決まっている前提
            f=figure(figN);
            indiv_psds=obj.eeg.epoched.(obj.target).spctl.(ch).indiv;
            mean_psds=squeeze(mean(indiv_psds(:,:,:),[2,3]));
            %semilogy(0:99,indiv_psds);
            %hold on;
            semilogy(0:99,mean_psds,"LineWidth",2);
            grid on;
            xlabel("frequency [Hz]");
            ylabel("psd [\muV^2/Hz]");
            %ylim([1e-30,1e-10]);
        end

    end
    methods(Static)
    end
end

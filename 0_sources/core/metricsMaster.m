%{
メトリクスは、一緒に情報として持っていおきたいものがいくつかある。
ので、混乱を防ぐために、ここで形を一般化して定義しておく。
PLUGに依存。
実験系には依存しない。
従って、本来はcore,もしくはcommonに入れ込みたい。
実行スクリプトはこれを継承してもいいかもしれない。ただ可読性が下がるので基本は継承せずに使えばいいんじゃないか。
メトリクスをだす、という機能はどれも一致しているはずだ。
PLUGに依存しない部分を抜き出して後で抽象クラスを作ってもいいかもな。
%}
classdef MetricsMaster < handle
    properties
        axyz = struct() % 時間情報格納配列。1*x。これは必ずしも時間が入らないので、構造体と軸ラベルの配列にした方がいいかもしれん。
        dimLabel = [] % 各次元の情報。string
        flag = [] % flag情報の格納配列。時間と同じ次元,長さを保つこと
        dins = [] % din情報。
        log = [""] % inが経験しているfilt情報
        info = struct();
        units = struct();
    end
    properties(SetAccess=protected,GetAccess=public)
        in = struct(); %指標格納配列。
        components = [""] % containerのfields。chなど。setにより自動で登録される。
        genDate = "" %これを出力した日付
        generator = "" % これを出力したファイルの名前
        no = struct();% 派生するメトリクスの置き場所。これはpublicの方がいい?
    end

    methods
        function obj=MetricsMaster(parent,generatorName)
            %{
            description : 
                インスタンスの作成。日付とスクリプト名は確定しているはずなので、ここで定義してしまう。
            input :
                parent (list of str): 親メトリクスのログ。1*x list of string
                generatorName (str): スクリプト名。mfilenameの出力を渡しておけばいい。
            %}
            arguments
                parent (1,:) string
                generatorName (1,1) string
            end
            obj.genDate=string(datetime("today","Format",'yyyyMMdd'));
            obj.generator=generatorName;
            obj.log=parent;
            obj.axyz.time=[]; % とりあえずtimeは作っておく。消してもいい。
            obj.dimLabel=["time"]; % デフォルト。変えていい。
        end
        function obj=make(obj,metricsName,generatorName)
            % 子メトリクスの作成。いらんかも。
            obj.no.(metricsName)=MetricsMaster(obj.log,generatorName);
            %obj.no.(metricsName).log=[obj.log,""];
        end
        function multi=make_multi(obj,parentNames,generatorName)
            % 2メトリクスを統合する場合
            % 
            % 
            log2add="[combined";
            for parent=parentNames
                log2add="-"+parent;
            end
            log2add=log2add+"]";
            multi=MetricsMaster(log2add,generatorName);
        end
        function obj=check_fields(obj)
            %{
            description : 
                プロパティが埋まっていることを確認して、warningを出したい。
            input :
            %}
            % TODO
        end
        function obj=flag2din(obj)
            % flagとdinを保護して、片方をセットしたらもう片方も更新されるようにしたいわね。
            obj.dins=flag2din(obj.flag);
        end
        function obj=set(obj,setStruct,logString)
            % inプロパティへのデータ定義用関数
            % コンポーネント単位でのsetも欲しい。
            % input:
            %   setStruct : 格納したいメトリクス。must be a struct   
            %   log
            arguments
                obj
                setStruct (1,1) struct
                logString (1,:) string
            end
            obj.components=string(fields(setStruct));
            obj.in=setStruct;
            obj.genDate=string(datetime("today","Format",'yyyyMMdd'));
            obj.log(end)=logString;
            % TODO:孫メトリクスへの更新情報追加
            % もし孫メトリクスがあるなら
            % infoに注意書きを追加。
        end
        function set_instance(obj, name, data, axyz, flag, ...
                              units, dimLabel, info, ...
                              parent)
            %{
            必要なものを一通り揃えるための関数。定義されていないものは親をコピーする。
            
            Args:
                name (str): この処理の名前。ログにする。
                data (dict): 各値はnumpy.ndarray型でなければならない。
                axyz (dict): 1次元リストをvalueとして、dataの各軸のラベルをキーとする。
                flag (list): _description_
                units (List, optional): _description_. Defaults to [].
                dimLabel (List, optional): _description_. Defaults to [].
                info (dict, optional): _description_. Defaults to {}.
                parent (list, optional): 親インスタンスを指定する。Defaults to [].
    
            Returns:
                None
            %}
            arguments
                obj
                name (1,1) string
                data (1,1) struct
                axyz (1,1) struct
                flag (1,:) int64
                units (1,1) struct = struct()
                dimLabel (1,:) string = []
                info (1,1) struct = struct()
                parent (1,1) = missing
            end
            if ~ismissing(parent) % 親が指定されている場合の処理
                disp('parent given: copying parameters.');
                % 親インスタンスのプロパティを現在のインスタンスにコピー
                obj.units = parent.units;
                obj.dimLabel = parent.dimLabel;
                obj.info = parent.info;

                % オプション引数で上書き
                if ~isempty(units)
                    obj.units = units;
                end
                if ~isempty(dimLabel)
                    obj.dimLabel = dimLabel;
                end
                if ~isempty(fields(info))
                    obj.info = info;
                end
            else
                disp('parent undefined: setting required parameters.');
                % オプション引数が未設定の場合はエラーを出力
                if isempty(units)
                    error('Units must be provided.');
                end
                if isempty(dimLabel)
                    error('DimLabel must be provided.');
                end
                if isempty(fields(info))
                    error('Info must be provided.');
                end
                % 必須引数を子インスタンスに代入
                obj.units = units;
                obj.dimLabel = dimLabel;
                obj.info = info;
            end

            % その他のプロパティの設定
            obj.flag = flag;
            obj.axyz = axyz;

            % dimLabelの中から、axyzに存在しないものを削除
            labelsToRemove = ~ismember(obj.dimLabel, fieldnames(axyz));
            obj.dimLabel(labelsToRemove) = [];

            % その他の初期化処理（必要に応じて）
            obj.set(data, name);  % このメソッドのMATLAB版を別途定義する必要があります。
            obj.flag2din();  % このメソッドのMATLAB版を別途定義する必要があります。
        end

        function obj=vis_default(obj,figN,varargin)
            % dimlabelsにtimeが存在する時に限る。
            % subplotにしてもいいかもしれん。
            % 第二引数(optional)として、描画するインデックスを指定できる。
            % TODO : ax指定に変更
            if ~isfield(obj.axyz,"time")
                error("metricsMaster.vis_default:must have time dimension");
            end
            if nargin==2
                index=1;
            else
                index=int(varargin(1));
            end
            figure(figN);
            compos=obj.components.';
            timeDim=find(obj.dimLabel=="time");
            for cmp=compos
                visData=shiftdim(obj.in.(cmp),timeDim-1);
                plot(obj.axyz.time,visData(:,index));
                hold on;
            end
            legs=compos;
            ax=gca();
            legs=obj.back_fill(ax,obj.dins,obj.axyz.time,legs);
            legend(legs);
        end
        function obj=mean_inComponent(obj,comp_t)
            % 平均の取得
            arguments
                obj
                comp_t (1,1) string 
            end
            metName="mean_"+comp_t;
            obj.make(metName,string(mfilename));
            output=struct();
            dims = find(obj.dimLabel==comp_t);
            for comp=obj.components.'
                output.(comp)=mean(obj.in.(comp),dims,"omitnan");
            end
            obj.no.mean.set(output,"mean");
            obj.no.mean.dimLabel=[""];
        end
        function obj=ste_eachComponent(obj)
            % 標準誤差の取得
            obj.make("ste",string(mfilename));
            output=struct();
            for comp=obj.components.'
                output.(comp)=std(obj.in.(comp),0,"all")/sum(size(obj.in.(comp)),"omitnan");
            end
            obj.no.ste.set(output,"mean");
            obj.no.ste.dimLabel=[""];
        end
        function obj=median_eachComponent(obj)
            % 全体中央値の取得。
            obj.make("median",string(mfilename));
            output=struct();
            for comp=obj.components.'
                obj.no.median.in.(comp)=median(obj.in.(comp),"all","omitnan");
            end
            obj.no.median.set(output,"median");
            obj.no.median.dimLabel=[""];
        end
        function obj=movmean(obj,width)
            % 移動平均の取得。時間方向。
            if ~isfield(obj.axyz,"time")
                error("metricsMaster.movmean:must have time dimension");
            end
            obj.make("movmean",string(mfilename));
            timeDim=find(obj.dimLabel=="time");
            output=struct();
            for comp=obj.components.' % これ格納のタイミングで次元変えた方がいい。
                output.(comp)=movmean(obj.in.(comp),width,timeDim,"omitnan");
            end
            obj.no.movmean.set(output,"movmean_"+string(width));
            obj.no.movmean.dimLabel=obj.dimLabel;
            obj.no.movmean.axyz=obj.axyz;
            obj.no.movmean.flag=obj.flag;
            obj.no.movmean.dins=obj.dins;
        end
        function obj=epoching(obj,center,leftSec,rightSec,title)
            % 汎用的なエポッキング。時間方向のデータを含んでいることを前提とする。
            %     
            % input:
            %   center : flag(int) 
            %   leftSec : int
            %   rightSec : int
            %   title : epoch_hogeになる。なるべく短かく(string)
            %
            % TODO : 多次元配列への対応。
            % TODO : epochedであれば、trial分を考慮したdrawinigが欲しい。
            if ~isfield(obj.axyz,"time")
                error("metricsMaster.epoching : data mast have time dimension")
            end
            if startsWith(title,"epc_")
               title=erase(title,"epc_");
            end

            tmpEpoched=struct(); % 結果を一時的に格納
            tmpFlag=[];
            tmpDins=[];
            tmpT0=[];

            fsHere=obj.info.fs;
            leftSample=leftSec*fsHere;
            rightSample=rightSec*fsHere;
            channels=obj.components;
            master=obj.in;
            % time次元の取得
            for ch=channels.' % とりあえず空配列の作成
                tmpEpoched.(ch)=[];
                master.(ch)=shiftdim(master.(ch), find(obj.dimLabel=="time")-1);
                % 時間方向が1次元目に来るように変換
            end
            masterDin=obj.dins;
            masterFlag=shiftdim(obj.flag, find(obj.dimLabel=="time")-1);

            for index =1:size(masterDin,2)
                din=masterDin(1,index);
                if din==center
                    zeroIndex=masterDin(2,index);
                    leftIndex=zeroIndex-leftSample;
                    rightIndex=zeroIndex+rightSample;
                    if leftIndex<=0
                        for ch=channels.'
                            addList=cat(1, zeros(-leftIndex+1,1), master.(ch)(1:rightIndex,1));
                            tmpEpoched.(ch)=cat(2, tmpEpoched.(ch), addList);
                        end
                        addList=ones(-leftIndex+1,1)*masterFlag(1);
                        addList=cat(1, addList, masterFlag(1:rightIndex,1));
                        tmpFlag=cat(2, tmpFlag, addList);
                    elseif rightIndex>length(obj.in.(ch))
                        short=rightIndex-length(obj.in.(ch));
                        for ch=channels.'
                            addList=cat(1, master.(ch)(leftIndex:end,1), zeros(short,1));
                            tmpEpoched.(ch)=cat(2, tmpEpoched.(ch), addList);
                        end
                        addList=ones(short,1)*masterFlag(end);
                        addList=cat(1, masterFlag(leftIndex:end), addList);
                        tmpFlag=cat(2, tmpFlag,addList);
                    else
                        for ch=channels.'
                            addList=master.(ch)(leftIndex:rightIndex,1);
                            tmpEpoched.(ch)=cat(2, tmpEpoched.(ch), addList);
                        end
                        tmpFlag=cat(2, tmpFlag, masterFlag(leftIndex:rightIndex,1));
                    end
                    tmpT0=[tmpT0,obj.axyz.time(zeroIndex)];
                    tmpDins={tmpDins;intersect(find(masterDin(2,:)>leftIndex),find(masterDin(2,:)<rightIndex))};
                    % もしかしたらこの辺でエラーが起きるかもしれない。
                    % dinのサイズに保証がない。これを避けるとしたらcell配列の利用か
                end
            end
            % 結果の格納
            metName="epc_"+title;
            logCode="epoch_"+string(center)+"l"+string(leftSec)+"r"+string(rightSec);
            obj.make(metName,"metricsMaster.epoching()"); % 出力プロパティの制作
            obj.no.(metName).axyz.time=[-leftSample/fsHere : 1/fsHere : rightSample/fsHere];%1*x配列
            obj.no.(metName).axyz.trial=1:size(tmpFlag,2);
            obj.no.(metName).dimLabel=["time","trial"]; % todo ; 多次元対応
            obj.no.(metName).set(tmpEpoched,logCode);
            obj.no.(metName).flag=tmpFlag;
            obj.no.(metName).dins=tmpDins;
            obj.no.(metName).info.fs=obj.info.fs;
            obj.no.(metName).info.startTimes=tmpT0;
        end
    end
    methods(Static)
        function legends=back_fill(ax,din,timeData,legends)
            clrs=[  [0 0.4470 0.7410];...
                    [0.8500 0.3250 0.0980];...
                    [0.9290 0.6940 0.1250];...
                    [0.4940 0.1840 0.5560];...
                    [0.4660 0.6740 0.1880];...
                    [0.6350 0.0780 0.1840]];
            ax;
            hold on;
            Y=[ax.YLim,flip(ax.YLim)];
            for ind =1:length(din)
                X=[din(2,ind)+din(3,ind)-1,din(2,ind)+din(3,ind)-1,din(2,ind),din(2,ind)];
                X=timeData(X);
                if din(1,ind)>0
                    tmpcolor=clrs(min(din(1,ind),6),:);
                    fill(X,Y,tmpcolor,'FaceAlpha',0.1,'EdgeColor','none');
                    legends=[legends,""];
                end
            end

        end
        function filtCode=gen_filtCode_btws(isStop,stFreq,enFreq,ord,isFltflt)
            % バターワースフィルタを前提として、フィルター記録用コードを書き出す。
            % input:
            %   isStop  : (bool)stop filterならtrue,passフィルタならfalse
            %   stFreq  : (numel) 低い方の周波数。数字じゃないもの入れれば0になる。
            %   enFreq  : (numel) 高い方の周波数。数字じゃないもの入れれば無限になる。
            %   ord     : (ord) フィルタ次数
            %   isFltflt: (bool) filtfiltならtrue。lfiltとrfiltは未実装。
            if isFltflt
                dir="W"; % 両側
            else
                dir="S"; % 片側
            end
            if isStop
                filtCode="-stpBt"+string(ord)+dir+"-"; % ストップフィルタ
            else
                filtCode="-pasBt"+string(ord)+dir+"-"; % パスフィルタ
            end

            if isnumeric(stFreq)&& isnumeric(enFreq)
                filtCode=string(stFreq)+filtCode+string(enFreq)+":";
            elseif isnumeric(stFreq)
                filtCode=string(stFreq)+filtCode+"inf:";
            else
                filtCode="0"+filtCode+string(enFreq)+":";
            end
        end
        function object = parse(metricBase, findMetric)
            % 指定した文字列に到達するまでパースして返す。
            % input:
            %   metricsBase (struct): metricsを格納している親struct。
            %   findMetric (list of string): メトリクスに至るまでのパスを。 
            arguments
                metricBase struct
                findMetric (1,:) string
            end

            % 初期化
            object = metricBase;
            % findMetricの各要素を辿ってtangoに代入
            for i = 1:length(findMetric)
                if i == 1
                    object = object.(findMetric{i});
                else
                    object = object.no.(findMetric{i});
                end
            end
        end
    end
end
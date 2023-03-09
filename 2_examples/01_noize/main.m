%{
exmple実行ファイル

テストケースとして以下を想定
タスク
- foot_imagery
- bite
- rest_eyes_closure
- blink
- right_hand_imagery
- left_hand_imagery
- rest_eyes_open
上記をランダムに3 [s]ごと
30回づつ

トライアル数
総計210

%}
close all
clearvars;
numOfTrial=30;
label="rightHand";

dataDir="../../1_testData/01_noize/";
dataName="BraintechAcademy_protc_NNC_30_202301280752.csv";

addpath("../../0_sources/core");%PlugData_thimpleまでのパスを記載
data=MyAnalysis_4BA(dataDir,dataName);

data.execute_preprocess();
data.execute_epochedView();


%{

%}

close all
clearvars

targetSession="B1";
cols=defaultColorGenerator();

dataDir="../../1_testData/06_ASSR"; % file path to your directory
dataName=struct();
dataName.A5="test07_5.csv"; % file name
dataName.B1="test08_1.csv"; % file name
dataName.B2="test08_2.csv"; % file name
dataName.B3="test08_3.csv"; % file name
dataName.B4="test08_4.csv"; % file name
dataName.B5="test08_5.csv"; % file name

durs=struct(); %%%%% 実験タイムコースのメモ %%%%%
durs.A5.fourty=[240,240+70]*10;% 07_5
durs.A5.eighty=[130,130+70]*10;
durs.A5.rest=[20,20+70]*10;
durs.B1.EO1=[10,10+40]*10; % 08_1
durs.B1.EC1=[70,70+40]*10;
durs.B1.EO2=[140,140+40]*10;
durs.B1.EC2=[210,210+40]*10;
% 08_2
durs.B2.EO1=[15,15+50]*10; 
durs.B2.EC1=[75,75+50]*10;
durs.B2.EO2=[140,140+50]*10;
durs.B2.EC2=[220,220+30]*10; 
% 08_3
durs.B3.restA=[5,5+50]*10;
durs.B3.SAM4=[70,70+50]*10;
durs.B3.restB=[125,125+50]*10; 
durs.B3.SAM8A=[195,195+50]*10;
durs.B3.restC=[250,250+50]*10;
durs.B3.SAM8B=[310,310+50]*10; 
% 08_4
durs.B4.eighty=[130,130+50]*10;
% TODO: write here.

% 08_5
durs.B5.tone=[15,15+50]*10;
durs.B5.rest=[100,100+50]*10;

addpath("../../0_sources/common"); % path to utils 
addpath("../../0_sources/core"); % path to myanalysis

data=MyAnalysis_ASSR(dataDir,dataName.(targetSession));
%data.overView();
data.saveDir="./figs/"+targetSession;
vis="EEGfilt_wide";
data.overView_origin(1);

%% モンタージュ修正
switch targetSession
    case "A5"
        data.overView(2,vis);
    case "B1"
        data.overView(2,vis);
    case "B2"
        data.overView(2,vis);
    case "B3"
        data.overView(2,vis);
    case "B5"
        data.overView(2,vis,"DrawRangeX",[40,41]);
end

%% 各エポックでpsd描画
motherPsd_eeg=data.metrics.(vis).no.spctl.in.C3CzRef;
motherPsd_sound=data.metrics.soundData.no.filt_hum.no.spctl.in.auIn;

switch targetSession
    case "A5"
        restPsd=motherPsd_eeg(:,durs.A5.rest(1):durs.A5.rest(2));
        fourPsd=motherPsd_eeg(:,durs.A5.fourty(1):durs.A5.fourty(2));
        eightPsd=motherPsd_eeg(:,durs.A5.eighty(1):durs.A5.eighty(2));
        xs=data.metrics.(vis).no.spctl.axyz.freq;
        f=figure(3);
        semilogy(xs,mean(restPsd,2,"omitnan"));
        hold on
        semilogy(xs,mean(eightPsd,2,"omitnan"));
        semilogy(xs,mean(fourPsd,2,"omitnan"));
        legend(["rest","eighty","fourty"]);

        restPsd=motherPsd_sound(:,durs.A5.rest(1):durs.A5.rest(2));
        fourPsd=motherPsd_sound(:,durs.A5.fourty(1):durs.A5.fourty(2));
        eightPsd=motherPsd_sound(:,durs.A5.eighty(1):durs.A5.eighty(2));
        f=figure(4);
        semilogy(xs,mean(restPsd,2,"omitnan"));
        hold on
        semilogy(xs,mean(eightPsd,2,"omitnan"));
        semilogy(xs,mean(fourPsd,2,"omitnan"));
        legend(["rest","eighty","fourty"]);
        titleset("sound_psd");

    case "B1"
        tmp=durs.B1;
        eoAPsd=motherPsd_eeg(:,tmp.EO1(1):tmp.EO1(2));
        ecAPsd=motherPsd_eeg(:,tmp.EC1(1):tmp.EC1(2));
        eoBPsd=motherPsd_eeg(:,tmp.EO2(1):tmp.EO2(2));
        ecBPsd=motherPsd_eeg(:,tmp.EC2(1):tmp.EC2(2));
        xs=data.metrics.(vis).no.spctl.axyz.freq;
        f=figure(3);
        semilogy(xs,mean(eoAPsd,2,"omitnan"),"Color",cols(1,:));
        hold on
        semilogy(xs,mean(eoBPsd,2,"omitnan"),"Color",cols(1,:));
        semilogy(xs,mean(ecAPsd,2,"omitnan"),"Color",cols(2,:));
        semilogy(xs,mean(ecBPsd,2,"omitnan"),"Color",cols(2,:));
        legend(["eo","eo","ec","ec"]);

    case "B3"
        %restA,SAM4,restB,SAM8A,restC,SAM8B
        tmp=durs.B3;
        restAPsd=motherPsd_eeg(:,tmp.restA(1):tmp.restA(2));
        restBPsd=motherPsd_eeg(:,tmp.restB(1):tmp.restB(2));
        restCPsd=motherPsd_eeg(:,tmp.restC(1):tmp.restC(2));
        SAM4Psd=motherPsd_eeg(:,tmp.SAM4(1):tmp.SAM4(2));
        SAM8APsd=motherPsd_eeg(:,tmp.SAM8A(1):tmp.SAM8A(2));
        SAM8BPsd=motherPsd_eeg(:,tmp.SAM8B(1):tmp.SAM8B(2));
        xs=data.metrics.(vis).no.spctl.axyz.freq;
        f=figure(3);
        semilogy(xs,mean(restAPsd,2,"omitnan"),"Color",cols(1,:));
        hold on
        semilogy(xs,mean(restBPsd,2,"omitnan"),"Color",cols(1,:));
        semilogy(xs,mean(restCPsd,2,"omitnan"),"Color",cols(1,:));
        semilogy(xs,mean(SAM4Psd,2,"omitnan"),"Color",cols(2,:));
        semilogy(xs,mean(SAM8APsd,2,"omitnan"),"Color",cols(3,:));
        semilogy(xs,mean(SAM8BPsd,2,"omitnan"),"Color",cols(3,:));
        legend(["rest","rest","rest","SAM4","SAM8","SAM8"]);
        
        
        restPsd=motherPsd_sound(:,tmp.restA(1):tmp.restA(2));
        sam4Psd=motherPsd_sound(:,tmp.SAM4(1):tmp.SAM4(2));
        sam8Psd=motherPsd_sound(:,tmp.SAM8A(1):tmp.SAM8A(2));
        f=figure(4);
        semilogy(xs,mean(restPsd,2,"omitnan"));
        hold on
        semilogy(xs,mean(sam4Psd,2,"omitnan"));
        semilogy(xs,mean(sam8Psd,2,"omitnan"));
        legend(["rest","eighty","fourty"]);
        titleset("sound_psd");

    case "B5"
        %tone, rest
        tmp=durs.B5;
        restPsd=motherPsd_eeg(:,tmp.rest(1):tmp.rest(2));
        tonePsd=motherPsd_eeg(:,tmp.tone(1):tmp.tone(2));
        xs=data.metrics.(vis).no.spctl.axyz.freq;
        f=figure(3);
        semilogy(xs,mean(restPsd,2,"omitnan"),"Color",cols(1,:));
        hold on
        semilogy(xs,mean(tonePsd,2,"omitnan"),"Color",cols(2,:));
        legend(["rest","tone"]);
        
        
        restPsd=motherPsd_sound(:,tmp.rest(1):tmp.rest(2));
        tonePsd=motherPsd_sound(:,tmp.tone(1):tmp.tone(2));
        f=figure(4);
        semilogy(xs,mean(restPsd,2,"omitnan"));
        hold on
        semilogy(xs,mean(tonePsd,2,"omitnan"));
        legend(["rest","tone"]);
        titleset("sound_psd");
end

data.tfView(5);

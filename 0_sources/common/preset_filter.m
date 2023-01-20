function filterd=preset_filter(wav,fs,alphaFlag)
% 50notchと3-40bandpassをかける。
% 引数:
%   wav : 波形データ。
%   fs  : サンプリング周波数
%   alphaFlag : trueとすると8~13のバンドパスもかかる。

drawFlag=false;
if drawFlag
    figure();
end
%% notch
StFreq=48;
EnFreq=52;
stopWn = [StFreq EnFreq]/(fs/2);
[paramB,paramA] = butter(3,stopWn,'stop');
filterd = filtfilt(paramB, paramA,wav);

if drawFlag
    subplot(4,1,1);
    plot(wav);
    subplot(4,1,2);
    plot(filterd);
end
%% bandpass

StFreq=3;
EnFreq=35;
Wn=[StFreq EnFreq]/(fs/2);
[paramB,paramA] = butter(3,Wn,'bandpass');
filterd = filtfilt(paramB, paramA,filterd);
if drawFlag
    subplot(4,1,3);
    plot(filterd);
end

if alphaFlag

    StFreq=8;
    EnFreq=13;
    Wn=[StFreq EnFreq]/(fs/2);
    [paramB,paramA] = butter(3,Wn,'bandpass');
    filterd = filtfilt(paramB, paramA,filterd);
    if drawFlag
        subplot(4,1,4);
        plot(filterd);
    end
end

end
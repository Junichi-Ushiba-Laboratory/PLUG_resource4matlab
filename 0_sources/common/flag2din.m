function dins=flag2din(flagList)
% 時系列で格納されたflag情報をdin形式にする
% e.g.
%   [1,1,1,1,1,1,1,1,2,2,2,2,2,2,1,1,1,1,2,2,2,3,3,3,3]
%   → 1     2     1     2     3 (ラベル行)
%     1     9    15    19    22 (インデックス行)
%     8     6     4     3     4 (データ数行)
%
    dins=[];
    memory=flagList(1);
    startIndex=1;
    for i = 2:length(flagList)
        flag=flagList(i);
        if i>=length(flagList)
            dins=[dins,[memory;startIndex;i-startIndex+1]];
        elseif memory==flag
        else
            dins=[dins,[memory;startIndex;i-startIndex]];
            startIndex=i;
        end
        memory=flag;
    end
end
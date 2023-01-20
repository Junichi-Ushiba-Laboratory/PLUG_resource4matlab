function []=figout(figN,DirName,figtitle,varargin)
% ディレクトリを移動して画像保存するやつ。引数はfigureNum,DirName,図タイトル
% 普通に使うと、titleset事自動で行う。
% 第4引数に"nosync"を渡すと自動タイトルセットが切れる。
%
%
    if exist(DirName,'dir')==0
        mkdir(DirName);
    end
    finger=strcat('-f',num2str(figN));
    
    inside=strrep(figtitle,"_","\_");
    figtitle=erase(figtitle,".");
    figtitle=strrep(figtitle,"\_","_");
    
    if nargin>3 
        if not(strcmpi(varargin{1},"nosync"))
            titleset(inside);
        end
    else
    titleset(inside);
    end
    
    print(finger,figtitle,'-dpng');
    
    movefile(strcat(figtitle,'.png'),DirName);
end

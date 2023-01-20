function []=figout(figN,DirName,figtitle,varargin)
% �f�B���N�g�����ړ����ĉ摜�ۑ������B������figureNum,DirName,�}�^�C�g��
% ���ʂɎg���ƁAtitleset�������ōs���B
% ��4������"nosync"��n���Ǝ����^�C�g���Z�b�g���؂��B
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

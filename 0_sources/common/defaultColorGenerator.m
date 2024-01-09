function cols=defaultColorGenerator(varargin)
% color generator
% parameter:
% 
cl1=[0 0.4470 0.7410];
cl2=[0.8500 0.3250 0.0980];
cl3=[0.9290 0.6940 0.1250];
cl4=[0.4940 0.1840 0.5560];
cl5=[0.4660 0.6740 0.1880];
cl6=[0.3010 0.7450 0.9330];
cl7=[0.6350 0.0780 0.1840];
cl8=[1 0 0];
cl9=[0 1 0];
cl10=[0 0 1];
cl11=[0 1 1];
cl12=[1 0 1];
cl13=[1 1 0];
cl14=[0 0 0];
colBASE=[cl1;cl2;cl3*0.6;cl4;cl5;cl6;cl7;cl8;cl9;cl10;cl11;cl12;cl13;cl14];
%colBASE=[cl1;cl2;cl4;cl5;cl6;cl7;cl8;cl9;cl10;cl11;cl12;cl13;cl14];

if nargin==0
    cols=colBASE;
else
    cols=[];
    sizer=varargin{1};
    i=1;
    while i>sizer
        cols=[cols;colBASE(i,:)];
        i=i+1;
    end
end

end
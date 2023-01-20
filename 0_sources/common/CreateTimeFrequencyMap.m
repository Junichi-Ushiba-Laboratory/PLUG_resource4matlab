%% Info
% Input => inputSignal: <Array of double>(freq, time), freqRange: [min: number, max: number], num_overlap: number, mode: number(0=>ERSP, 1=>Power), [customArgument => dataName: string]
% Output => outputFigure: Figure

%% Main
function [outputFigure] = CreateTimeFrequencyMap(inputSignal, freqRange, num_overlap, mode, varargin)
% SetParameter
% feed DoF for 6th parameter, and mask with p-value
[inputHeight, inputWidth] = size(inputSignal);

xaxis= 0:(1-num_overlap):inputWidth*(1-num_overlap);

if nargin == 4
    varargin{1} = 'time-frequency map';   % default data name
end

% Create time-frequency map
if mode == 0 % ERSP Display
    outputFigure = imagesc(xaxis, freqRange, inputSignal);
    title(varargin{1});
    xlabel('time [s]','FontSize',30);
    ylabel('frequency [Hz]','FontSize',30);
    ylim(freqRange);
    xlim([0 xaxis(end)]);
    caxis([-3 3]);
    set(gca,'FontSize',20);
    axis xy;
    colormap('jet');
    c = colorbar;
    c.Label.String = 'ERSP [dB]';
elseif mode == 1 % Power Display
    outputFigure = imagesc(xaxis, freqRange, inputSignal);
    title(varargin{1});
    xlabel('time [s]','FontSize',30);
    ylabel('frequency [Hz]','FontSize',30);
    ylim(freqRange);
    xlim([0 xaxis(end)]);
    set(gca,'FontSize',20);
    axis xy;    
    colormap('jet');
    colorbar;
    c = colorbar;
    c.Label.String = 'Power [ƒÊV^2]';
elseif mode == 2 % t-Val Display
    outputFigure = imagesc(xaxis, freqRange, inputSignal);
    title(varargin{1});
    xlabel('time [s]','FontSize',30);
    ylabel('frequency [Hz]','FontSize',30);
    ylim(freqRange);
    xlim([0 xaxis(end)]);
    set(gca,'FontSize',20);
    axis xy;    
    colormap('jet');
    colorbar;
    c = colorbar;
    c.Label.String = 't-Value [-]';
    if nargin>5
        alpha=0.2*ones(size(inputSignal));
        alpha((1-tcdf(abs(inputSignal),varargin{2}-1))<0.05)=1;
        alpha(:,1:varargin{2}-1)=0.2;
        outputFigure.AlphaData=alpha;
    end
end

end

%% End of the Script
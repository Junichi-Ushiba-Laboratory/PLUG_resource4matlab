%{

%}


dataDir="../******"; % file path to your directory
dataName="*******.csv"; % file name
addpath("../0_sources/common"); % path to utils 
addpath("../0_sources/core"); % path to myanalysis

data=MyAnalysis(dataDir,dataName);
data.overView();
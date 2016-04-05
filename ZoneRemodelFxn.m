function [remodel] = ZoneRemodelFxn(filename,outputname)
%ZONE REMODEL FXN
%ZoneRemodelFxn('filename','outputname')
%
%ZoneRemodelFxn takes a raw ethovision data file as an excel and reorders
%the data so that the Arms are in order from 1-8, which is important for
%any future analysis using Frequency or Duration codes.

if nargin < 1
    error('No filename entered. Please enter location of input excel file');
elseif nargin < 2
    error('No valid output name entered. Please enter name of output excel file');
end

%Load in excel file
[num txt raw] = xlsread(filename);

%Storage/output
remodel = {};

%Find first column with the numeric data
[row FirstNumCol] = find(strcmp(raw, 'In zone'), 1);

%Add the information columns (Animal num, Trial num, Notes, etc) from the raw excel into the remodel
remodel = raw(:,1:FirstNumCol-1);

%% Zones
%Arena, Center-point
%Arm #, Center-point
%Arm#-Mid, Center-point
%Arm#-Plat, Center-point

Zones = raw(:,FirstNumCol:size(raw,2));

ArenaIndex = strfind(Zones(2,:), 'Arena'); %Finds Index storing any information about the entire Arena as a zone
ArenaIndex = find(~cellfun(@isempty, ArenaIndex));

%Add Arena data to the new output file before any Arms data
remodel = [remodel Zones(:,ArenaIndex)];

%% Go through each arm
LargeRemodel = {};
MidRemodel = {};
PlatRemodel = {};

for arm = 1:8
    %Define arm targets
    Large = sprintf('Arm %d', arm);
    Mid = sprintf('Arm%d-Mid', arm);
    Plat = sprintf('Arm%d-Plat', arm);
    
    %Find arm targets
    LargeIndex = strfind(Zones(2,:), Large);
    LargeIndex = find(~cellfun(@isempty, LargeIndex));
    
    MidIndex = strfind(Zones(2,:), Mid);
    MidIndex = find(~cellfun(@isempty, MidIndex));
    
    PlatIndex = strfind(Zones(2,:), Plat);
    PlatIndex = find(~cellfun(@isempty, PlatIndex));
    
    %Add current arm column into each Zone's remodeled array
    LargeRemodel = [LargeRemodel Zones(:,LargeIndex)];
    MidRemodel = [MidRemodel Zones(:,MidIndex)];
    PlatRemodel = [PlatRemodel Zones(:,PlatIndex)];
end

%Add each remodeled Zone data to the final output in order of Large-zone,
%Mid-zone, Platform-zone
remodel = [remodel LargeRemodel MidRemodel PlatRemodel];

%% Change original numerical data in cells to write into excel as a string
%xlswrite will change any number, even if it is of type string in matlab,
%to a number in excel. We want to preserve the data. Thus we will check in
%txt for locations that is a number
%The target columns are:
%Animal
%Cage
%Platform
%Starting
%Trial
%Previous

[row AnimalCol] = find(strcmp(remodel,'Animal'));
[row CageCol] = find(strcmp(remodel,'Cage'));
[row PlatformCol] = find(strcmp(remodel,'Platform'));
[row StartingCol] = find(strcmp(remodel,'Starting'));
[row TrialCol] = find(strcmp(remodel,'Trial'));
[row PrevCol] = find(strcmp(remodel,'Previous'));

%Find first Trial row
FirstRow = find(strcmp(remodel,'Trial     1')); %Ethovision outputs with 5 spaces between Trial and 1
LastRow = size(remodel,1);

if ~isempty(AnimalCol)
    remodel(FirstRow:LastRow,AnimalCol) = strcat('''',remodel(FirstRow:LastRow,AnimalCol));
end
if ~isempty(CageCol)
    remodel(FirstRow:LastRow,CageCol) = strcat('''',remodel(FirstRow:LastRow,CageCol));
end
if ~isempty(PlatformCol)
    remodel(FirstRow:LastRow,PlatformCol) = strcat('''',remodel(FirstRow:LastRow,PlatformCol));
end
if ~isempty(StartingCol)
    remodel(FirstRow:LastRow,StartingCol) = strcat('''',remodel(FirstRow:LastRow,StartingCol));
end
if ~isempty(TrialCol)
    remodel(FirstRow:LastRow,TrialCol) = strcat('''',remodel(FirstRow:LastRow,TrialCol));
end
if ~isempty(PrevCol)
    remodel(FirstRow:LastRow,PrevCol) = strcat('''',remodel(FirstRow:LastRow,PrevCol));
end

%% Write out remodeled sheet
xlswrite(outputname, remodel);
end
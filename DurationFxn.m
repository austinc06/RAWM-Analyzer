%This function takes in the target excel file with SORTED data (arms are in
%order) and outputs duration spent in each arm into excel sheet with
%outputname

function [DurData] = DurationFxn(filename, outputname, center, reversal)

%% Check that both filename and outputname are input
if nargin < 1
    error('No filename entered. Please enter location of input excel file');
elseif nargin < 2
    error('No valid output name entered. Please enter name of output excel file');
elseif nargin < 3
    reversal = 0;
end

%% load in excel file, create duration array
[AllDur txt raw] = xlsread(filename);

%AllDur is for number values only. From duration excel file, this gives you
%195 rows (each trial) with 8 numbers (8 arms, in order from Arm1 to Arm8).

%txt output is for text only values. It outputs a CELL array.

%raw outputs everything into matlab.

DurData = {}; %We'll store the final compiled data here.

%% Compile Animal Number List
%First find which column the animal values are stored
[row AnimalCol] = find(strcmp(txt, 'Animal')); %row is trash variable
AnimalNum = txt(:,AnimalCol);

%Ethovision excel file has a bunch of empty cells on top. Let's remove all
%the empty cells.
AnimalNum = AnimalNum(~cellfun('isempty',AnimalNum));

%Now let's remove teh Animal heading on the column.
AnimalNum = AnimalNum(2:size(AnimalNum,1));

%Now let's identify the actual unique Animal numbers
[usorted uIndex uarray] = unique(AnimalNum,'first'); %auto-sorts values too
uIndex = sort(uIndex); %sort out indices in ascending order
AnimalNum = AnimalNum(uIndex); %Ordered list of unique Animal Numbers in correct order

%Result: Sorted list of Unique Animal Numbers in the excel file.

%% Pull out the notes column
[row NotesCol] = find(strcmp(txt, 'Notes'));
Notes = txt(:,NotesCol);

%% Go through each animal and obtain Duration for each trial
while ~isempty(AnimalNum)
    CurrentAnimal = AnimalNum(1)
    
    if size(AnimalNum,1) > 1
        AnimalNum = AnimalNum(2:size(AnimalNum,1));
    else
        AnimalNum = {};;
    end
    
    match = strcmp(txt(:,AnimalCol),CurrentAnimal);
    
    NumMatch = match(5:size(match,1),:); %chops off top 4 rows, which is just the headings in excel   
    
    %% Get the duration data for animal of interest
    AOIdur = AllDur(NumMatch,:);
    %each row in AOIdur is each trial. Each column is the arm (in order)
    
    %Let's replace all the NaN with 0
    AOIdur(isnan(AOIdur)) = 0; %Finds all the indices where AOIdur value is NaN and replaces it with 0.
    
    %We also need the start arm positions for the animal in excel
    [row StartCol] = find(strcmp(txt, 'Starting'));
    temp = txt(5:size(txt,1),StartCol);
    StartArms = cellfun(@str2num, temp(NumMatch));
    
    %We will also take the target armposition for the animal in excel
    [row TargetCol] = find(strcmp(txt, 'Platform'));
    temp = txt(5:size(txt,1),TargetCol);
    TargetArm = cellfun(@str2num, temp(NumMatch));
    TargetArm = TargetArm(1);
    
    %We will also note the previous arm if this is the reversal day
    if reversal == 1
        [row PrevCol] = find(strcmp(txt, 'Previous'));
        temp = txt(5:size(txt,1), PrevCol);
        PrevArm = cellfun(@str2num, temp(NumMatch));
        PrevArm = PrevArm(1);
    end
    
    %% Convert Data to percentage time spent
    %Go through row by row and convert total durations into percentage time
    Trial = 1; %start at trial 1
    
    AOIperc = AOIdur;
    
    while Trial <= size(AOIdur,1)
        TotalTime = sum(AOIperc(Trial,:)); %Find Total Time
        AOIperc(Trial,:) = AOIperc(Trial,:)/TotalTime * 100; %Convert to percent
        
        Trial = Trial+1; %Go to next trial
    end
    
    %% Modifying in case of lost trials
    
    %If videotracking failed or a trial wasn't counted, you won't actually
    %have 15 trials. Let's just add an extra row of "missing" for each
    %trial missing
    %Also convert all numerical data to cell data for structure
    %organization later
    if size(AOIdur,1) >= 15
        AOIdur = num2cell(AOIdur);
        AOIperc = num2cell(AOIperc);
    else
        while size(AOIdur,1) < 15
            AOIdur = [num2cell(AOIdur); repmat({'missing'},1,size(AOIdur,2))];
            AOIperc = [num2cell(AOIperc); repmat({'missing'},1,size(AOIperc,2))];
        end
    end
    
    
    %% Organize the data
    AOIDurData = {};
    AOIDurData = {'Trial1';'Trial2';'Trial3';'Trial4';'Trial5';'Trial6';'Trial7';'Trial8';'Trial9';'Trial10';'Trial11';'Trial12';'Trial13';'Trial14';'Trial15'};
    AOIDurData = [repmat(CurrentAnimal,size(AOIDurData,1),1) AOIDurData AOIdur];
    
    AOIDurData = [{'Animal' '' 'Arm1' 'Arm2' 'Arm3' 'Arm4' 'Arm5' 'Arm6' 'Arm7' 'Arm8'}; AOIDurData];
    
    %For each animal, let's add a quick marker to the heading so we know
    %which arm is the Target
    AOIDurData(1,TargetArm+2) = { ['Target ' cell2mat(AOIDurData(1,TargetArm+2))] };
    
    if reversal == 1
        AOIDurData(1,PrevArm+2) = { ['Previous ' cell2mat(AOIDurData(1,PrevArm+2))] };
    end
    
    %Tag on the notes from the animal
    AOINotes = Notes(match);
    AOIDurData = [AOIDurData [{'Notes'}; AOINotes]];
    
    %For bookkeeping, let's add an empty row [] after each animal
    AOIDurData = [AOIDurData; cell(1,size(AOIDurData,2))];
    
    AOIPercData = AOIDurData;
    AOIPercData(2:16,3:10) = AOIperc;
    
    %Combine both AOIDurData and AOIPercData with empty column between the
    %two
    combined = [AOIDurData cell(size(AOIDurData,1),1) AOIPercData];
    %Add heading for duration and percentage above animal column
    temp = cell(1,size(combined,2));
    temp(1) = {'Total Duration'};
    temp(13) = {'Percent of Total Time'};
    combined = [temp;combined];
    
    %Now add that to the main array with an empty column between total
    %duration and percentage time
    DurData = [DurData ; combined];
    
    %% Save to excel
    xlswrite(outputname, AOIDurData, char(CurrentAnimal));
    xlswrite(outputname, AOIPercData, char(CurrentAnimal), 'M1');
end

xlswrite(outputname, DurData, 'All');
end
function [DurData] = DurationFxn(filename, outputname, center, reversal)
%DURATION FXN
%DurationFxn('filename','outputname',center,reversal)
%
%The function takes in the ordered excel file containing the duration an
%animal spent in each Arm. Note that the excel file containing duration
%must include and ONLY include: Arms1-8 and Center.
%
%The data should not include the Arena duration.


%% Check that both filename and outputname are input
if nargin < 1
    error('No filename entered. Please enter location of input excel file');
elseif nargin < 2
    error('No valid output name entered. Please enter name of output excel file');
elseif nargin < 3
    center = input('Do you want to include duration spent in Center? 1 = yes, 0 = no:\n');
    reversal = 0;
elseif nargin < 4
    reversal = 0;
end

%% load in excel file, create duration array
[AllDur txt raw] = xlsread(filename);

DurData = {}; %We'll store the final compiled data here.

%% Compile Animal Number List
%Find column with the Animal Numbers
[row AnimalCol] = find(strcmp(txt, 'Animal')); %row is trash variable
AnimalNum = txt(:,AnimalCol);

%Remove all the empty cells in the header rows
AnimalNum = AnimalNum(~cellfun('isempty',AnimalNum));

%Remove the Animal heading on the column so only numbers remain
AnimalNum = AnimalNum(2:size(AnimalNum,1));

%Identify the actual unique Animal numbers
[usorted uIndex uarray] = unique(AnimalNum,'first'); %auto-sorts values too
uIndex = sort(uIndex); %sort out indices in ascending order
AnimalNum = AnimalNum(uIndex); %Ordered list of unique Animal Numbers in correct order

%Result: Sorted list of Unique Animal Numbers from the excel file.

%% Obtain the notes column
[row NotesCol] = find(strcmp(txt, 'Notes'));
Notes = txt(:,NotesCol);

%% Go through each animal and obtain Duration for each trial
while ~isempty(AnimalNum)
    %Get current Animal Number and remove it from the Animal Number list
    
    CurrentAnimal = AnimalNum(1)
    
    if size(AnimalNum,1) > 1
        AnimalNum = AnimalNum(2:size(AnimalNum,1));
    else
        AnimalNum = {};;
    end
    
    match = strcmp(txt(:,AnimalCol),CurrentAnimal); %Find relevant indices for the animal of interest
    
    NumMatch = match(5:size(match,1),:); %chops off top 4 rows, which is just the headings in excel   
    
    %% Get the duration data for animal of interest
    AOIdur = AllDur(NumMatch,:);
    %each row in AOIdur is each trial. Each column is an arm
    
    %If we do not wish to analyze the duration including the center zone,
    %remove the column representing duration in center (last column)
    if center == 0
        AOIdur = AOIdur(:,1:size(AOIdur,2)-1);
    end
    
    %Duration data will include Not-a-Number's if an animal does not spend
    %time in the corresponding zone. Convert all NaNs to 0s
    AOIdur(isnan(AOIdur)) = 0;
    
    %Obtain Start Location for the trial
    [row StartCol] = find(strcmp(txt, 'Starting'));
    temp = txt(5:size(txt,1),StartCol);
    StartArms = cellfun(@str2num, temp(NumMatch));
    
    %Obtain Target Arm for the trial
    [row TargetCol] = find(strcmp(txt, 'Platform'));
    temp = txt(5:size(txt,1),TargetCol);
    TargetArm = cellfun(@str2num, temp(NumMatch));
    TargetArm = TargetArm(1);
    
    %Obtain Previous Arm if the day is a reversal day
    if reversal == 1
        [row PrevCol] = find(strcmp(txt, 'Previous'));
        temp = txt(5:size(txt,1), PrevCol);
        PrevArm = cellfun(@str2num, temp(NumMatch));
        PrevArm = PrevArm(1);
    end
    
    %% Convert Data to Percentage of Total Time spent in each zone
    Trial = 1; %start at trial 1
    
    %Set up a new array the same size as the absolute duration array
    AOIperc = AOIdur;
    
    while Trial <= size(AOIdur,1)
        TotalTime = sum(AOIperc(Trial,:)); %Find Total Time for the trial
        AOIperc(Trial,:) = AOIperc(Trial,:)/TotalTime * 100; %Convert to percent
        
        Trial = Trial+1; %Go to next trial
    end    
    
    %% Organize the data
    %% Absolute Duration Data
    %Final output array:
    AOIDurData = {};
    
    i = 1;
    %Add to output array the number of trials relevant for the animal
    while i <= size(AOIdur,1)
        trial = sprintf('Trial%d',i);
        AOIDurData = [AOIDurData ; {trial}];
        i = i+1;
    end
    
    %Add Animal Number and Duration Data to output array
    AOIDurData = [repmat(CurrentAnimal,size(AOIDurData,1),1) AOIDurData num2cell(AOIdur)];
    
    %Label the Zones accordingly
    if center
        AOIDurData = [{'Animal' '' 'Arm1' 'Arm2' 'Arm3' 'Arm4' 'Arm5' 'Arm6' 'Arm7' 'Arm8' 'Center'}; AOIDurData];
    else
        AOIDurData = [{'Animal' '' 'Arm1' 'Arm2' 'Arm3' 'Arm4' 'Arm5' 'Arm6' 'Arm7' 'Arm8'}; AOIDurData];
    end
    
    %Add additional label for Target Arm
    AOIDurData(1,TargetArm+2) = { ['Target ' cell2mat(AOIDurData(1,TargetArm+2))] };
    
    %Add additional label for Previous Arm if reversal
    if reversal == 1
        AOIDurData(1,PrevArm+2) = { ['Previous ' cell2mat(AOIDurData(1,PrevArm+2))] };
    end
    
    %Add the notes for the animal
    AOINotes = Notes(match);
    AOIDurData = [AOIDurData [{'Notes'}; AOINotes]];
    
    %Add an empty row [] after each animal
    AOIDurData = [AOIDurData; cell(1,size(AOIDurData,2))];
    
    %% Percentage Total Time Duration Data
    AOIPercData = AOIDurData;
    
    %AOIPercData is essentially the same as AOIDurData. Convert absolute
    %durations to calculated percentage durations.
    AOIPercData(2:1+size(AOIperc,1),3:2+size(AOIperc,2)) = num2cell(AOIperc);
    
    %% Compile all data
    %Combine both AOIDurData and AOIPercData with empty column between the
    %two
    combined = [AOIDurData cell(size(AOIDurData,1),1) AOIPercData];
    
    %Add heading for duration and percentage above animal column
    temp = cell(1,size(combined,2));
    temp(1) = {'Total Duration'};
    temp(size(AOIDurData,2)+2) = {'Percent of Total Time'};
    combined = [temp;combined];
    
    %Add data for animal onto compilation array for all animals
    DurData = [DurData ; combined];
    
    %% Save Current Animal data to excel
    xlswrite(outputname, AOIDurData, char(CurrentAnimal));
    xlswrite(outputname, AOIPercData, char(CurrentAnimal), 'M1');
end

xlswrite(outputname, DurData, 'All');
end
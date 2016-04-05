function [] = GenErrorsFxn(filename,outputname,zone,probe)
%GENERRORSFXN
%GenErrorsFxn(filename, outputname, zone)
%
%Outputs Errors in each Arm in each Trial for each Animal. Accepts an
%ORDERED ethovision frequency file with: Arena, Large Zones 1-8, Mid Zones
%1-8, Platform Zones 1-8 for a total of 25 columns.
%
%To use, input strings of the filename of ordered ethovision file and
%desired output name. The zone parameter determines what Zone is being
%analyzed: 1 = Large Zones, 2 = Mid Zones, 3 = Platform Zones.

%% Check that both filename and outputname are present, check if user already input desired zone
if nargin < 1
    error('No filename entered. Please enter location of input excel file');
elseif nargin < 2
    error('No valid output name entered. Please enter name of output excel file');
elseif nargin < 3 || (zone ~= 1 && zone ~= 2 && zone ~= 3)
    disp('Analyzing General Errors')
    zone = input('Enter Desired Zone: 1 = Large/General, 2 = Mid, 3 = Platform:\n');
end

if nargin < 4 || (probe ~= 0 && probe ~= 1)
    probe = input('Is this a probe day? 1 = Yes, 2 = No');
elseif probe == 1
    disp('Probe Day')
elseif probe == 0
    disp('No Probe')
end

%% Load in excel file, create frequency array
[Freq txt raw] = xlsread(filename); %Freq are all numerical values, txt are all non-numerical values

FreqData = {}; %Store final data here
AllErrors = {};
AllBlockErrors = {};

%% Compile Animal Number List
%First find which column the animal values are stored
[row AnimalCol] = find(strcmp(txt, 'Animal')); %We only need the column
AnimalNum = txt(:,AnimalCol); %AnimalNum is the column in excel containing all Animal Numbers for each Trial

%Ethovision excel file has a bunch of empty cells on top. Remove all
%the empty cells.
AnimalNum = AnimalNum(~cellfun('isempty',AnimalNum));

%Remove the Animal heading on the column.
AnimalNum = AnimalNum(2:size(AnimalNum,1));

%Identify the actual unique Animal numbers
[usorted uIndex uarray] = unique(AnimalNum,'first'); %auto-sorts values too
uIndex = sort(uIndex); %sort out indices in ascending order
AnimalNum = AnimalNum(uIndex); %Ordered list of unique Animal Numbers in correct order

%Result: Sorted list of Unique Animal Numbers in the excel file.

%We need a save spot for later for the excel sheet with the data for all the animals
AllRow = 1;

%% Compile Notes list
%Similar to Animal column, let's pull out the column containing all the
%notes in the excel file
[row NotesCol] = find(strcmp(txt, 'Notes'));
Notes = txt(:,NotesCol);

%% Obtain Errors for each Animal
while ~isempty(AnimalNum)
    %% Pull out first Animal and relevant indices for each trial
    CurrentAnimal = AnimalNum(1)
    
    %Removes the CurrentAnimal from the AnimalNum list.
    if size(AnimalNum,1) > 1
        AnimalNum = AnimalNum(2:size(AnimalNum,1));
    else
        AnimalNum = {};
    end
    
    match = strcmp(txt(:,AnimalCol),CurrentAnimal); %Gives us the relevant indices for this animal
    
    NumMatch = match(5:size(match,1),:); %chops off top 4 rows, which is just the headings in excel
    %NumMatch will be used to find all the data from the Freq array we have
    %from excel earlier. This will help pull all the data for just this
    %animal.
    
    %% Get the Notes for animal of interest
    AOINotes = Notes(match);
    
    %% Get the frequency data for Animal of Interest (AOI)
    AOIfreq = Freq(NumMatch,:);
    %each row in AOIfreq is each trial. Each column is the arm (in order)
    %from large zone, medium zone, and platform zone
    
    %Sometimes the ZoneRemodelFxn will have output a strange column that
    %does not consist of numbers but xlsread puts it in the Freq array. We
    %need to check that the number of columns in AOIfreq is 25: Arena,
    %Large 1-8, Mid 1-8, Platform 1-8
    
    %If the NaN (not a number) column is present, remove it. Otherwise
    %error out and require the correct ethovision output file.
    if size(AOIfreq,2) > 25 & isnan(AOIfreq(1))
        AOIfreq = AOIfreq(:,2:size(AOIfreq,2));;
    elseif size(AOIfreq,2) < 25
        error('Make sure ethovision output includes Arena, Arms 1-8, Mid Arms 1-8, Platform Arms 1-8 for a total of 25 numerical columns');
    end
    
    %% Take data for the Arm zones of relevance only
    if zone == 1
        %Take only the large zones
        AOIfreq = AOIfreq(:,2:9);
    elseif zone == 2
        %Take only the mid zones
        AOIfreq = AOIfreq(:,10:17);
    elseif zone == 3
        %Take only the platform zones
        AOIfreq = AOIfreq(:,18:25);
    else
        error('Zone value not 1, 2, or 3')
    end
    
    
    %% Find relevant parameters: StartArms, TargetArms and set up Output for Errors
    %We also need the start arm positions for the animal in excel
    [row StartCol] = find(strcmp(txt, 'Starting'));
    temp = txt(5:size(txt,1),StartCol);
    StartArms = temp(NumMatch);
    
    %We will also take the target armposition for the animal in excel
    [row TargetCol] = find(strcmp(txt, 'Platform'));
    temp = txt(5:size(txt,1),TargetCol);
    TargetArms = temp(NumMatch);
    
    Trial = 1;
    SaveRow = 1; %Row on excel sheet to save the data
    
    %Set up array to store cumulative data
    AllFreq = {};
    
    %Set up array to store cumulative adjacent data
    PrevFreq = {};
    AdjFreq = {};
    NonAdjFreq = {};
    
    BlockErr = []; %This will be used to average block errors
    
    %% Find Errors for each Trial
    while Trial <= size(AOIfreq,1)
        
        %Take relevant data for this trial
        ArmFreq = AOIfreq(Trial,:)';
        StartArm = StartArms(Trial);
        TargetArm = TargetArms(Trial);
        
        %Account for the fact that the starting arm automatically counts
        %as 1 frequency the zone.
        StartArm = str2double(StartArm); %identifies start arm
        ArmFreq(StartArm,:) = ArmFreq(StartArm,:)-1; %Subtracts 1 from the start arm error
        
        %Find Target Arm. Every entry into the target arm is NOT an error.
        TargetArm = str2double(TargetArm);
        ArmFreq(TargetArm,:) = 0; %Changes target arm frequency to 0 (no error)
        
        %Sum up total number of errors and check that Total is not negative
        %May occur if start position is not the platform zone of the arm
        %and the function is calculating platform error.
        if sum(ArmFreq,1) < 0
            Total = 0;
        else
            Total = sum(ArmFreq,1);
        end
        
        %Add the Total error into the Block and add the trial error onto
        %the array storing errors for this trial
        BlockErr = [Total BlockErr];
        ArmFreq = [ArmFreq; Total];
        
        
        %         %% Identify adjacent arms
        %         if TargetArm == 1
        %             Adj1 = 8;
        %             Adj2 = 2;
        %         elseif TargetArm == 8
        %             Adj1 = 7;
        %             Adj2 = 1;
        %         else
        %             Adj1 = TargetArm - 1;
        %             Adj2 = TargetArm + 1;
        %         end
        %
        %         %Now let's get the adjacent only errors
        %         AdjErrors = ArmFreq(:,Adj1) + ArmFreq(:,Adj2);
        %
        %% Organize the data
        %Let's add a column that tells us which arm is start and end
        ArmInfo = cell(size(ArmFreq,1),1);
        ArmInfo(TargetArm) = {'Target'};
        ArmInfo(StartArm) = {'Start'};
        
        %Add labels for each Arm (row)
        FreqData = {'Arm1'; 'Arm2'; 'Arm3'; 'Arm4'; 'Arm5'; 'Arm6'; 'Arm7'; 'Arm8'; 'Total'};
        FreqData = [FreqData num2cell(ArmFreq) ArmInfo];
        
        %Add headings (column)
        FreqData = [{'Arm#' 'Total Errors in Arm' 'Start/Target'}; FreqData];
        
        %Add the animal column
        FreqData = [['Animal' ; repmat(CurrentAnimal, size(FreqData,1)-1 ,1)] FreqData];
        
        %Add the trial number
        FreqData = [['Trial' num2str(Trial)] cell(1, size(FreqData,2)-1); FreqData];
        
        %Add the Notes column
        FreqData = [FreqData [{'Notes'};repmat(AOINotes(Trial), size(FreqData,1)-1,1)]];
        
        %Write trial data to the output file
        SaveSpot = ['A' num2str(SaveRow)];
        xlswrite(outputname, FreqData, char(CurrentAnimal), SaveSpot);
        
        %% Compile data for All sheet
        %Find what row stores the total errors for the trial
        TotalRow = find(strcmp(FreqData(:,2),'Total'));
        
        %If the trial is a multiple of 3, then calculate averaged error for
        %the block. Otherwise leave an empty cell.
        if mod(Trial,3) == 0
            Block = num2cell(mean(BlockErr));
            BlockErr = [];
        else
            Block = {''};
        end
        
        %Store the Error count for this trial into the AllFreq Array to
        %compile across every trial for the animal
        AllFreq = [AllFreq; ['Trial' num2str(Trial)] FreqData(TotalRow,1:size(FreqData,2)-1) Block FreqData(TotalRow,size(FreqData,2)) ];
        
        %         %Adjacent
        %         AdjRow = find(strcmp(FreqData(:,2),'Adjacent Errors'));
        %         AdjFreq = [AdjFreq; ['Trial' num2str(Trial)] FreqData(AdjRow,:)];
        %
        %         %Non-Adjacent
        %         NonAdjRow = find(strcmp(FreqData(:,2),'Non-Adjacent Errors'));
        %         NonAdjFreq = [NonAdjFreq; ['Trial' num2str(Trial)] FreqData(NonAdjRow,:)];
        
        %Go to next Trial
        Trial = Trial+1;
        SaveRow = SaveRow + size(FreqData,1) +1;
    end
    
    %% All trials analyzed; finish organizing data for compiled AllFreq array
    %Add heading to All-Data arrays
    AllFreq = [{'Trial #'} {'Animal'} {''} {'Total Errors in Arm'} {''} {'Block Error'} {'Notes'}; AllFreq];
    %     AdjFreq = [{'Trial #'} {'Animal'} {''} {'Errors after Center'} {'Total Errors in Arm'} {'Shallow Error'} {'Mid Error'} {'Platform Error'} {''} {'Notes'}; AdjFreq];
    %     NonAdjFreq = [{'Trial #'} {'Animal'} {''} {'Errors after Center'} {'Total Errors in Arm'} {'Shallow Error'} {'Mid Error'} {'Platform Error'} {''} {'Notes'}; NonAdjFreq];
    
    
    %Compile Errors so everything is accessible in one sheet
    AllErrors = [AllErrors [AllFreq(2,2) ; AllFreq(2:size(AllFreq,1),4)] ];
    
    %Compile Blocks so everything is accessible in one sheet
    BlockInfo = [AllFreq(2,2) ; AllFreq(2:size(AllFreq,1), 6)];
    %Remove 0's
    Block0 = strcmp({''},BlockInfo);
    Block0 = Block0==0;
    BlockInfo = BlockInfo(Block0);
    
    AllBlockErrors = [AllBlockErrors BlockInfo];
    
    %Write the data into the output file
    AllSpot = ['A' num2str(AllRow)];
    %     AdjSpot = ['L' num2str(AllRow)];
    %     NonAdjSpot = ['W' num2str(AllRow)];
    
    xlswrite(outputname, AllFreq, 'All', AllSpot);
    %     xlswrite(outputname, AdjFreq, 'Categorized', AdjSpot);
    %     xlswrite(outputname, NonAdjFreq, 'Categorized', NonAdjSpot);
    
    AllRow = AllRow + size(AllFreq,1) + 1;
end

%% Organize datas for AllErrors and AllBlockErrors

if probe == 0
    headings = [{'Animal #'}; {'Trial 1'}; {'Trial 2'}; {'Trial 3'}; {'Trial 4'}; {'Trial 5'}; {'Trial 6'}; {'Trial 7'}; {'Trial 8'}; {'Trial 9'}; {'Trial 10'}; {'Trial 11'}; {'Trial 12'}; {'Trial 13'}; {'Trial 14'}; {'Trial 15'}];
elseif probe == 1
    headings = [{'Animal #'}; {'Trial 1'}; {'Trial 2'}; {'Trial 3'}];
end
AllErrors = [headings AllErrors];

if probe == 0
    headings = [{'Animal #'}; {'Block 1'}; {'Block 2'}; {'Block 3'}; {'Block 4'}; {'Block 5'}];
elseif probe == 1
    headings = [{'Animal #'}; {'Block 1'}];
end
AllBlockErrors = [headings AllBlockErrors];

xlswrite(outputname, AllErrors, 'AllErrors');
xlswrite(outputname, AllBlockErrors, 'AllBlocks');

end
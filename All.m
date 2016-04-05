function [] = All(filelist)
%All function takes a list of filenames without the file extension and runs
%each file through remodel and error analysis function for Large, Mid, and
%Platform errors.

disp('All function will not properly analyze Probe days. Analyze Probe days separately with GenErrorsFxn');

while ~isempty(filelist)
    CurrentFile = cell2mat(filelist(1))
    
    if size(filelist,2) > 1
        filelist = filelist(2:size(filelist,2));
    else
        filelist = {};
    end
    
    Raw = sprintf('%s.xlsx',CurrentFile);
    Re = sprintf('%s_Re.xlsx',CurrentFile);
    Large = sprintf('%s_L.xlsx',CurrentFile);
    Mid = sprintf('%s_M.xlsx',CurrentFile);
    Plat = sprintf('%s_P.xlsx',CurrentFile);
    
    ZoneRemodelFxn(Raw,Re);
    
    GenErrorsFxn(Re, Large, 1,0);
    GenErrorsFxn(Re, Mid, 2,0);
    GenErrorsFxn(Re, Plat, 3,0);
end

end


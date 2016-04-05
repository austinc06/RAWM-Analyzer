function [] = AllErrors( filename, renamed, outputnameL, outputnameM, outputnameP )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

ZoneRemodelFxn(filename, renamed);

GenErrorsFxn(renamed, outputnameL, 1);
GenErrorsFxn(renamed, outputnameM, 2);
GenErrorsFxn(renamed, outputnameP, 3);

end


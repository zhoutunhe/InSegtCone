function [img,filepath] = load_amira(filepath,filename)
if ~exist('filepath','dir') && isempty(filepath)
    [filename,filepath] = uigetfile('','Select data file');
    
end

[Header,img] = LoadData_Amira(fullfile(filepath,filename));
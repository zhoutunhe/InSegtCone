function [img,filefolder] = load_tif_sequence(filefolder)
if isempty(filefolder) && ~exist(filefolder,'dir')
    filefolder = uigetdir('','Select data folder');
    % files: 1xN cell, names
end

files = dir(fullfile(filefolder,'/*.tif*'));
nImages = length(files);
fprintf('start loading images    ')
for k = 1 : nImages
   % k
    filename = fullfile(filefolder,files(k).name);    
    files(k).data = imread(filename);
    progmeter(k/nImages); 
end
progmeter done

%convert into matrix
filetemp = struct2cell(files);
filetemp2 = cell2mat(filetemp(7,:));
img = reshape(filetemp2,[size(filetemp{7,1}),size(filetemp,2)]);
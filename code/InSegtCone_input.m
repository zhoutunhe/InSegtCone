% this file defines the necessary parameters to change
close all; clc;

%% Files and Folders:

% - Add code paths - %
% define the folder to save the result
saveDir = 'D:\code\InSegtCone\results\';
% define the file prefix in the file name to be saved
savefileprefix = 'bee';

% microCT data file
datafile = 'D:\code\InSegtCone\data\60185_AM_F.nii.gz';
% label file
labelfile = 'D:\code\InSegtCone\data\60185_AM_F_manLabel.nii.gz';
dataBitDepth = 8; %8 or 16 bit data?

%label value
maskLabelValue = 3; %cone label
lensLabelValue = 7; % lens surface label

% subregion division
NumSectionX = 3; %divide into 3 parts in X direction (PCA space) for fitting
NumSectionY = 2; %divide into 3 parts in y direction (PCA space) for fitting

% parameters for unfolding

% these two can keep the same unless need to be changed
fittingmethod = 'poly55';   %fitting method poly55 is the highest for matlab fit function
density = 1;    %sampling rate

% the size of the data to unfold
% need to check the following size is ok, sometimes up and down is
% different after PCA transform. Test one and see if it is OK.
lensUnfoldRangeSub = 20; % How far to sample below the lens
lensUnfoldRangeUp  = 65; % How far to sample above the lens



% parameters for training
slicenumber = ones(1,NumSectionX*NumSectionY)*90; % choose a slice number for training
%slicenumber = [88 90 94 96 92 88]; % can decide manually by picking a good slice
%startslice = 88;   If not defined, all the slices will be processed.
%endslice  = 209;
trainType = 1; % 4 ways of initialting the training: 
% 0. no prior labelling. train from scratching
% 1. the other subregions use the last trained subregion as initial guess, except the first
% one;
% 2. Use the saved training label png. Need to be exactly the same slice.
% Suitable for re-run the program to improve manual labelling
% 3. Use the saved dictionary.
 
%% run the segmentation
P1_unfolding_lens
P2_training

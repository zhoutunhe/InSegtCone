clear 
close all

addpath functions

% VERSION 1: WITHOUT CORRECTION
% for batch processing dictionary is reused, and manual labeling might need
% correction, so easiest is to build dictionary outside the gui to be able
% to use it later
im = double(imread('/Users/abd/Documents/Projects/particleSize/data/tif/3big_004_crop.png'))/255;
im = imresize(im,.25);

dictopt.method = 'euclidean';
dictopt.patch_size = 7;
dictopt.branching_factor = 5;
dictopt.number_layers = 6;
dictopt.number_training_patches = 20000;
dictopt.normalization = true;

dictionary = build_dictionary(im,dictopt);

% IMPORTANT:
% once inside gui export dict_labels to workspace (E)
image_texture_gui(im,dictionary,2)
%%
dictionary = update_dictionary(dictionary,gui_dictprob);
%%
figure
%     I = double(imread('/Users/abd/Documents/Projects/particleSize/data/tif/1big_008_crop_small.png'))/255;
%     I = imresize(I,.25);
I = im;
[~,Q] = process_image(I,dictionary);

[~,segIm] = max(Q,[],3);
subplot(121)
imagesc(Q(:,:,2),[0,1]), axis image, drawnow
subplot(122)
imagesc(segIm), axis image, drawnow
%%
I = double(imresize(V(:,:,500),1))/(2^16);
tic
Q = process_image(I,dictionary);
toc
[~,segIm] = max(Q,[],3);
subplot(121)
imagesc(Q(:,:,2),[0,1]), axis image, title(100), drawnow
subplot(122)
imagesc(segIm), axis image, drawnow

%%

[img, n]=bwlabel(segIm==2);
figure,imagesc(img)


%%

figure, imagesc(dictionary.dictprob)

%%


% VERSION 2: WITH (OR WITHOUT) CORRECTION
% TODO: freezeing (F) and correcting
% mappings = compute_mappings(im,dictionary);
% image_texture_gui(im,mappings,2)


%%

tmp = dictionary.dictprob;
msq = dictionary.options.patch_size^2;
figure,imagesc(tmp(1:msq,:)+tmp(msq+1:end,:)==0)


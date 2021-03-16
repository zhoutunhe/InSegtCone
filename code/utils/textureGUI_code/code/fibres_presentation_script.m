clear 
close all
addpath functions

%% % glass fibres
glass = imread('../data/glass.png'); 
dictopt.patch_size = 9;
dictopt.branching_factor = 5;
dictopt.number_layers = 4;
dictopt.number_training_patches = 30000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
image_texture_gui(glass,dictopt,2)


%% glass fibers with saved labelings
glass = imread('../data/glass.png'); 
labels = imread('../data/glass_labels.png');
dictopt.patch_size = 9;
dictopt.branching_factor = 5;
dictopt.number_layers = 4;
dictopt.number_training_patches = 30000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
image_texture_gui(glass,dictopt,2,labels)

%% glas as batch processing
% for batch processing, it is important that all images are double and [0,1]
% gui will do this automatically, so new images should be in the same format

% settings
glass = double(imread('../data/glass.png'))/255; 
labels = imread('../data/glass_labels.png');
dictopt.patch_size = 9;
dictopt.branching_factor = 5;
dictopt.number_layers = 4;
dictopt.number_training_patches = 30000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
dictionary = build_dictionary(glass,dictopt); % dictionary

% IMPORTANT: 
image_texture_gui(glass,dictionary,2,labels) %% <- EXPORT (E) to workplace 
dictionary = update_dictionary(dictionary,gui_dictprob); % update with results exported from gui
%%
glass_bigger = double(imread('../data/glass0864_cut.png'))/255; % new image
[segmentation, probabilities] = process_image(glass_bigger,dictionary);
figure, a1 = subplot(131); imagesc(glass_bigger), title('bigger'), axis image
a2 = subplot(132); imagesc(probabilities(:,:,2)), title('probabilities'), axis image
a3 = subplot(133); imagesc(segmentation), title('segmentation'), axis image
linkaxes([a1;a2;a3])

%%
glass_biggest = double(imread('../data/glass0864.png'))/255; % new image
[segmentation, probabilities] = process_image(glass_biggest,dictionary);
figure, a1 = subplot(131); imagesc(glass_biggest), title('biggest'), axis image
a2 = subplot(132); imagesc(probabilities(:,:,2)), title('probabilities'), axis image
a3 = subplot(133); imagesc(segmentation), title('segmentation'), axis image
linkaxes([a1;a2;a3])




%% % carbon fibres
carbon = imread('../data/carbon.png');
dictopt.patch_size = 9;
dictopt.branching_factor = 5;
dictopt.number_layers = 4;
dictopt.number_training_patches = 30000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
image_texture_gui(carbon,dictopt,2)



%% carbon fibers with saved labelings
carbon = imread('../data/carbon.png'); 
labels = imread('../data/carbon_labels.png');
dictopt.patch_size = 9;
dictopt.branching_factor = 5;
dictopt.number_layers = 4;
dictopt.number_training_patches = 30000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
image_texture_gui(carbon,dictopt,2,labels)

%% carbon fibre as batch processing
% for batch processing, it is important that all images are double and [0,1]
% gui will do this automatically, so new images should be in the same format

% settings
carbon = double(imread('../data/carbon.png'))/255; 
labels = imread('../data/carbon_labels.png');
dictopt.patch_size = 9;
dictopt.branching_factor = 5;
dictopt.number_layers = 4;
dictopt.number_training_patches = 30000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
dictionary = build_dictionary(carbon,dictopt); % dictionary

% IMPORTANT: 
image_texture_gui(carbon,dictionary,2,labels) %% <- EXPORT (E) to workplace 
dictionary = update_dictionary(dictionary,gui_dictprob); % update with results exported from gui
%%
carbon_bigger = double(imread('../data/carbon0103.png'))/255; % new image
carbon_bigger = carbon_bigger(201:800,201:800);
[segmentation, probabilities] = process_image(carbon_bigger,dictionary);
figure, a1 = subplot(131); imagesc(carbon_bigger), title('bigger'), axis image
a2 = subplot(132); imagesc(probabilities(:,:,2)), title('probabilities'), axis image
a3 = subplot(133); imagesc(segmentation), title('segmentation'), axis image
linkaxes([a1;a2;a3])

%%
carbon_biggest = double(imread('../data/carbon0918.png'))/255; % new image
[segmentation, probabilities] = process_image(carbon_biggest,dictionary);
figure, a1 = subplot(131); imagesc(carbon_biggest), title('biggest'), axis image
a2 = subplot(132); imagesc(probabilities(:,:,2)), title('probabilities'), axis image
a3 = subplot(133); imagesc(segmentation), title('segmentation'), axis image
linkaxes([a1;a2;a3])




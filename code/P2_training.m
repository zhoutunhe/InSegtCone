%
% ---- COMPOUND/INSECT EYES ---- %
% Sep 2020
%
% Part 2:
% Texture GUI-Based Crystalline Cone Segmentation
% Need to manuelly select good slice for training
% Decide training from scracth for each slice (0),
% or train from scratch for the first slice only while the rest use the last dictionary as a start (1),
% or use old training pictures (2), or
% use old dictionaries from other data (3)

%% Files and Folders:

% - Add code paths - %

% - Data files - %

trainTime = zeros(NumSectionX*NumSectionY,1);


%%  % for IdxSection = -1
for IdxSection = 1:NumSectionX*NumSectionY
    fprintf(['Now train subregion No.' num2str(IdxSection)])
    tic
    
    
    niiDataUnfoldFile = [dataFolder savefileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfoldVolume.nii.gz']; %Unfolded image
    niiLblUnfoldFile  = [dataFolder savefileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfoldLabels.nii.gz']; %Unfolded labels
    
    
    % - Load Unfolded Data - %
    niiData = load_nii(niiDataUnfoldFile);
    niiLbl = load_nii(niiLblUnfoldFile);
    
    % Labels:
    %   Lbl 1: Retina bottom interface
    %   Lbl 3: Crystalline cone layer
    %   Lbl 7: Lens, interface (exterior)
    %   Lbl 9: Retina top layer (interface w/ CC)
    
    % - Assign header information - %
    uOrigin = [0 0 0];
    uSpace = [1 1 1];
    uDim = size(niiData.img);
    
    
    
    %% - Training: Texture/Pattern Segmentation Model - %%
    
    % Training of the model is done on a single selected slice
    % A GUI is employed to give direct feedback
    
    
    
    % Train/Retrain Dictionary
    disp('Performing dictionary training');
    
    %% - Select slice - %
    sliceSelect = slicenumber(IdxSection); % Pick slice from navigation in unfolded volume
    
    % Initial processing:
    im = niiData.img(:,:,sliceSelect);
    im(isnan(im)) = 0; % Replace NaNs with 0
    im = im./255; %floats should be scaled to range [0-1]
    %     im = im./max(im(:)); %floats should be scaled to range [0-1]
    if trainType == 1   %the other slices use the last slice as initial guess
        if IdxSection~=1
            dictionary_old = dictionary;
            feat_model_old = feat_model;
            feat_param_old = feat_param;
        end
    end
    % ----------------------FEATURE DESCRIPTION Training ----------%
    % Set feature parameters:
    % 1: Patch size (for PCA feature computing).
    % -- Must be uneven positive integer
    feat_param.patch_size = 11; % match relatively well with the diameter of the cones in the slice
    
    % 2: No. of patches (for PCA feature computing of the covariance matrix
    % -- Must be positive integer
    feat_param.n_patch = 50000;
    
    % 3: Number of principal components to keep.
    % - If the value is between 0 and 1, it will take the number of
    % principal components corresponding to that fraction of the variance.
    feat_param.n_keep = 10;
    
    % 4: Which types of derivatives to include. If the value is 0, the feature
    % will be excluded. First element is 0th order, second is 1st order and
    % thrid element is 2nd order. Ex. feat_param.feat_type = [0 1 0] will only
    % compute the 1st order derivative.
    feat_param.feat_type = [1, 1, 1];
    
    % 5: Image down scaling factor (for faster computation).
    % Note that the effective patch size changes relative to this parameter.
    feat_param.scale_factor = 1;
    
    % Computing:
    [feat_im, feat_model] = get_PCA_features(im, feat_param); % Compute the features.
    % ------------------DICTIONARY training ----------------------%
    % Set segmentation method parameters
    dictopt.method = 'euclidean';
    dictopt.patch_size = 15; % approx the same size with patch size. Can keep the parameters the same if use the same resolution.
    dictopt.branching_factor = 5;
    dictopt.number_layers = 5;
    dictopt.number_training_patches = 50000;
    dictionary = build_feat_dictionary(feat_im,dictopt);
    
    noClass = 2; % number of label-classes
    
    if trainType == 0
        [seg_im, P, D] = image_texture_gui(im,dictionary,noClass); %no prior labelling
    elseif trainType == 1
        if IdxSection == 1
            % -------------------- %
            % Label and train dictionary:
            [seg_im, P, D] = image_texture_gui(im,dictionary,noClass); %no prior labelling
            %comment out if want to reuse the labelling
        else
            
            % Using existing label image:
            % uncomment if we want to reuse the label
            %     label_im = imread('training\settings_labels_indexed.png');
            % label_im = imread('cutEye\s1_labels.png')/255+1;
            % label_im = squeeze(lblVol(:,:,86))+1;
            %     [seg_im, P, D] = image_texture_gui(im,dictionary,noClass,label_im);
            feat_im_test = get_PCA_feat_from_model(im, feat_model_old, feat_param_old);
            [seg_test, ~] = get_feat_probability(feat_im_test, dictionary_old);
            
            % Store output of class 2:
            im_start = seg_test == 2; %Change if cone center has different label
            [seg_im, P, D] = image_texture_gui(im,dictionary,noClass,(im_start+1));
        end
    elseif trainType == 2
        [FILENAME,FILEPATH] = uigetfile('.png', 'Select the saved training label png');
        label_im = imread(fullfile(FILEPATH,FILENAME));
        [seg_im, P, D] = image_texture_gui(im,dictionary,noClass,label_im);
    elseif trainType == 3
        dictionary_new = dictionary;
        feat_model_new = feat_model;
        feat_param_new = feat_param;
        [FILENAME,FILEPATH] = uigetfile('.mat', 'Select the saved training dictionary *.mat');
        if ~contains(FILENAME,'dictionary')
            sprintf('wrong file, open the dictionary file')
            [FILENAME,FILEPATH] = uigetfile('.mat', 'Select the saved training dictionary *.mat');
        end
        
        load(fullfile(FILEPATH,FILENAME))
        dictionary_old = dictionary;
        feat_model_old = feat_model;
        feat_param_old = feat_param;
        dictionary= dictionary_new ;
        feat_model= feat_model_new ;
        feat_param = feat_param_new ;
        feat_im_test = get_PCA_feat_from_model(im, feat_model_old, feat_param_old);
        [seg_test, ~] = get_feat_probability(feat_im_test, dictionary_old);
        
        % Store output of class 2:
        im_start = seg_test == 2; %Change if cone center has different label
        [seg_im, P, D] = image_texture_gui(im,dictionary,noClass,(im_start+1));
    end
    % --------------------- %
    
    % Update dictionary:
    dictionary = set_label_dict_prob(dictionary, D);
    
    % Export:
    dictFileName = [dataFolder savefileprefix '_' num2str(IdxSection) '_dictionary.mat'];
    save(dictFileName,'dictionary','dictopt','feat_model','feat_param','-v7.3');
    
    
    
    trainTime(IdxSection) = toc
    
    
end
%%
writematrix(trainTime,[dataFolder 'trainingTime.csv'])
fprintf('Finished training! Continueing to Part 3 segmentation...\n')
%%
P3_segment
P4_cones


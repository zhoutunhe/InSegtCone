%
% ---- COMPOUND/INSECT EYES ---- %
% March 2020
%
% Tutorial 2:
% Texture GUI-Based Crystalline Cone Segmentation

%clear all; close all; clc;

%% Files and Folders:

% - Add code paths - %
   
  tic; 
% for IdxSection = 3
pool = parpool(2);
for IdxSection = 1:NumSectionX*NumSectionY

    disp('Using pre-trained dictionary')
    dictFileName = [dataFolder datafileprefix '_' num2str(IdxSection) '_dictionary.mat'];
    load(dictFileName);
    
    niiDataUnfoldFile = [dataFolder datafileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfoldVolume.nii.gz']; %Unfolded image
    niiLblUnfoldFile  = [dataFolder datafileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfoldLabels.nii.gz']; %Unfolded labels
    
    
    % - Load Unfolded Data - %
    niiData = load_nii([niiDataUnfoldFile]);
    niiLbl = load_nii([niiLblUnfoldFile]);
    
    
    
    % - Assign header information - %
    uOrigin = [0 0 0];
    uSpace = [1 1 1];
    uDim = size(niiData.img);
    
    % - Get mask of crystal cone layer - %
    coneLayerMask = niiLbl.img == maskLabelValue;
    
    
    % - Application of trained model - %%
    
    % The trained model is applied to all slices of the volume
    
    disp(['Processing slices ' num2str(IdxSection)])
    lblVol = zeros(uDim); % response volume
    if ~exist('startslice','var')
        startslice = 1;
    end
    if ~exist('endslice','var')
        endslice = uDim(3);
    end
    
    
    parfor i=startslice:endslice
        
        % Get and process slice:
        % Get and process slice:
        im_test = niiData.img(:,:,i);
        im_test(isnan(im_test)) = 0; % Replace NaNs with 0
        %     im_test = im_test./max(im_test(:)); % Scale data to range [0 1]
        im_test = im_test./255; % Scale data to range [0 1]
        
        % Apply model:
        feat_im_test = get_PCA_feat_from_model(im_test, feat_model, feat_param);
        [seg_test, ~] = get_feat_probability(feat_im_test, dictionary);
        
        % Store output of class 2:
        lblVol(:,:,i) = seg_test == 2; %Change if cone center has different label
    end
    
    % Remove labels outside of the cone layer
    lblVol(~coneLayerMask) = 0;
    
    % Export:
    textureConesNii = make_nii(uint8(lblVol),uSpace,uOrigin,2);
    save_nii(textureConesNii,[dataFolder datafileprefix '_' num2str(IdxSection) '_textureCone_class_unfold.nii.gz']);
    

    
    %% Post-processing:
    coneCC = bwconncomp(lblVol,26); %Connected Component Analysis %connect the neighbors. 3D with 26.
    % coneCC = bwconncomp(lblVol,8);
    %should I use 26 if I have changed density?
    cSz = cellfun(@numel,coneCC.PixelIdxList);
    
    % Size rejection:
    % minSz = 50; % Volumes smaller than [unit: voxels] are discarded
    minSz = 20; %76=20*1.25^3/0.8^3
    keepIdx = cSz > minSz;
    coneCC.PixelIdxList = coneCC.PixelIdxList(keepIdx);
    coneCC.NumObjects = sum(keepIdx);
    
    % Data-type assignment:
    if sum(keepIdx) <= 2^8-1
        dType = 'uint8';
        niiType = 2;
    elseif sum(keepIdx) > 2^8-1 && sum(keepIdx) <= 2^16-1
        dType = 'uint16';
        niiType = 512;
    elseif sum(keepIdx) > 2^16-1
        dType = 'single';
        niiType = 16;
    end
    % uDim = size(lblVol)
    % Assign unique labels to cones in volume:
    coneVol = zeros(uDim,dType);
    for i = 1:coneCC.NumObjects
        coneVol(coneCC.PixelIdxList{i}) = i;
    end
    
    % Export:
    lblConesNii = make_nii(coneVol,uSpace,uOrigin,niiType);
    save_nii(lblConesNii,[dataFolder datafileprefix '_' num2str(IdxSection) '_minSz' num2str(minSz) '_textureCones_labelled_unfold.nii.gz']);
    
    
    fprintf('Cone labelled %d\n', IdxSection)
    t = toc
    fprintf('%f s left\n', t/IdxSection*(NumSectionX*NumSectionY-IdxSection))
end

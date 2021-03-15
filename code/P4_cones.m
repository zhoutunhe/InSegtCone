%
% ---- COMPOUND/INSECT EYES ---- %
% March 2020
%
% Part 4: back transform 
% Crystalline Cones in original data + optional: layered segmentation

clc;

%% Files and Folders:

% - Add code paths - %

% - Data files - %

% Data Headers:

imgSpace = [1 1 1];
imgOrg = [0 0 0];
% assign some basic header information to variables for easy referencing
pcaMappingFile = [saveDir fileprefix '_pca_map.mat'];
load(pcaMappingFile)

for IdxSection = 1:NumSectionX*NumSectionY
    tic
    mappingFile = [dataFolder datafileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfold_map.mat']; %Unfold mapping
    load(mappingFile); %variables: mappingVec, surfPolyPts, surfPolyDir
    % - Unfolded data - %

    coneFile = [dataFolder datafileprefix '_' num2str(IdxSection) '_minSz' num2str(minSz) '_textureCones_labelled_unfold.nii.gz'];
    niiCone = load_nii([coneFile]);
    
    
    % Data Headers:
    uOrigin = [0 0 0];
    uSpace = [1 1 1];
    uDim = size(niiCone.img);
    
    
    %% Transformation of segmented cones to original coordinates %%
    
    % Number of cones:
    coneLbl = unique(niiCone.img(:));
    coneLbl = coneLbl(2:end); %discard zero
    nCones = length(coneLbl);
    
    %% ---- THIS SECTION: DUE TO SUBREGION DATASET ---- %
    % % Modify 'mu':
    % %origin full dataset: [0,0,0];
    % %image dimesions full dataset: [1920 989 688]
    % % muShift = imgOrg ./ imgSpace;
    % % mu = mu-muShift;
    % % ----------------------------------------------- %
    %
    coneLblVol = zeros(imgDim,'uint16');
    for i = 1:length(coneLbl)
        
        % Get voxel location in unfolded space
        [r,c,s] = ind2sub(uDim,find(niiCone.img == coneLbl(i)));
        spokeId = sub2ind(uDim(1:2),r,c);
        
        % Calculate location of labelled voxels in original PCA space:
        tmp = interp1(mappingVec,s);
        coneLblPCA1 = surfPolyPts(spokeId,:) + tmp.*surfPolyDir(spokeId,:);
        
        % Transform to original space:
         
        coneLblPCA = coneLblPCA1 * Up' + mup; %from the 2nd project to the 1st pca space
        coneLblOrg = coneLblPCA * U' + mu;
        coneLblOrg = round(coneLblOrg); % Force points into the image-grid coordinates; good for overlay images
        
        % Deal with potential cases of points outside of image-grid domain.
        %     % don't need for full eye.
        %             coneLblOrg(coneLblOrg < [1 1 1]) = 1;
        coneLblOrg(coneLblOrg(:,1) > imgDim(1),1) = imgDim(1);
        coneLblOrg(coneLblOrg(:,2) > imgDim(2),2) = imgDim(2);
        coneLblOrg(coneLblOrg(:,3) > imgDim(3),3) = imgDim(3);
        %
        % Assign labels to voxels:
        coneLblIdx = sub2ind(imgDim,coneLblOrg(:,1),coneLblOrg(:,2),coneLblOrg(:,3));
        coneLblVol(coneLblIdx) = coneLbl(i);
        
    end
    
    % Apply morphology:
    coneLblVol = imclose(coneLblVol,strel('sphere',1));
    
    % Sanity Check:
    niiConeOrg = make_nii(coneLblVol,imgSpace,imgOrg,512);
    save_nii(niiConeOrg,[dataFolder datafileprefix '_' num2str(IdxSection) '_textureCones_labelled.nii.gz']);

    for ii = 1:size(coneLblVol,3)
        subfolder = [dataFolder 'coneLable' num2str(IdxSection)];
        if ~exist(subfolder,'dir')
            mkdir(subfolder)
        end
        imwrite(squeeze(coneLblVol(:,:,ii)),sprintf('%s/%03d.tif',subfolder,ii),'TIFF')

    end
    
    disp(['Cones mapped back for subregion No.' IdxSection])
end
 
%
% ---- COMPOUND/INSECT EYES ---- %
% June 2020
%
% Part 1:
% Unfolding of compound eye


if ~exist(dataFolder,'dir')
    mkdir(dataFolder)
end

% - Data files - %
% load image data
niiData = load_nii(datafile);
% read in the lables
niiLbl = load_nii(labelfile);


%% Find the lens surface from manual input

imgDim = size(niiData.img);
[rL,cL,sL] = ind2sub(imgDim,lensSurfIdx); %Voxel coordinates

% Display / Sanity Check:
subSet = 107;
figure(111);
plot3(rL(1:subSet:end),cL(1:subSet:end),sL(1:subSet:end), 'r.');
xlabel('x'),ylabel('y'),zlabel('z')
axis image;
box on;
legend('Lens')


%% PCA Transformation:
% Geting data into a proper coordinate system / space.

% Principal Component Analysis (PCA) is a method for estimating the
% smallest bounding box of a set of points!

% ---- THIS SECTION: WHEN RUNNING ON NEW/FULL DATASET ---- %
% PCA code:
%
% Built-in PCA (centered is default)
[U,~,L,~,l,mu] = pca([rL,cL,sL]);

%
figure(111);
hold on
% Display PCA coordinate system(on previous figure):
plot3(mu(1),mu(2),mu(3), 'kx','MarkerSize',8);
plot3([mu(1) mu(1)+2*l(1)*U(1,1)],[mu(2) mu(2)+2*l(1)*U(2,1)],[mu(3) mu(3)+2*l(1)*U(3,1)], 'r-','LineWidth',2);
plot3([mu(1) mu(1)+2*l(2)*U(1,2)],[mu(2) mu(2)+2*l(2)*U(2,2)],[mu(3) mu(3)+2*l(2)*U(3,2)], 'g-','LineWidth',2);
plot3([mu(1) mu(1)+2*l(3)*U(1,3)],[mu(2) mu(2)+2*l(3)*U(2,3)],[mu(3) mu(3)+2*l(3)*U(3,3)], 'b-','LineWidth',2);


% Projection into PCA space:

% Reproject surface points into new coordinate system:
surfLensPts = ([rL,cL,sL]-mu) * U; %forward projection/transformation

figure(112);
plot3(surfLensPts(1:subSet:end,1),surfLensPts(1:subSet:end,2),surfLensPts(1:subSet:end,3),'r.');
axis image
xlabel('x_{PCA}'),ylabel('y_{PCA}'),zlabel('z_{PCA}')
box on;
legend('Lens')

% Note on projections:
% Forward transformation of a pointset p = (x,y,z) [Nx3], is done as:
% - pT = (p-mu) * U
% to obtain the transformed pointset pT = (xPCA,yPCA,zPCA)
%
% Now suppose a new set of points, qT = (xPCA,yPCA,zPCA), is defined
% in the PCA space, and the positions in the original coordinate
% system q = (x,y,z) should be obtained. Then do the inverse operation:
% - q = qT * U' + mu
pcaMappingFile = [saveDir savefileprefix '_pca_map.mat'];
save(pcaMappingFile,'U','L','l','mu','surfLensPts');


%% Surface Fitting (in PCA space):
% divide in transverse: x direction in pca space
minx = min(surfLensPts(:,1));
stepx = (max(surfLensPts(:,1))-minx)/NumSectionX;
% divide laterally: y direction in pca space
miny = min(surfLensPts(:,2));
stepy = (max(surfLensPts(:,2))-miny)/NumSectionY;

maskx = zeros(length(surfLensPts),NumSectionX*NumSectionY);

margin = 20;

ii = 0;
for xi = 1:NumSectionX
    for yi = 1:NumSectionY
        ii = ii+1;
        maskx(:,ii) = ((minx+stepx*(xi-1))<=surfLensPts(:,1))&...
            (surfLensPts(:,1)<=(minx+stepx*xi+margin))&((miny+stepy*(yi-1))...
            <=surfLensPts(:,2))&(surfLensPts(:,2)<=(miny+stepy*yi+margin));
    end
end
maskx = logical(maskx);
save([saveDir savefileprefix '_mask.mat'],'maskx')




%% fitting loop
fittingError = zeros(NumSectionX*NumSectionY,5);
for IdxSection = 1:NumSectionX*NumSectionY
    surfLensPtsPartial = surfLensPts(maskx(:,IdxSection),:);
    % % % plot showcase
    % subSet = 107;
    % figure,
    % plot3(surfLensPtsPartial(1:subSet:end,1),surfLensPtsPartial(1:subSet:end,2),surfLensPtsPartial(1:subSet:end,3),'r.');
    % axis image
    % xlabel('x_{PCA}'),ylabel('y_{PCA}'),zlabel('z_{PCA}')
    % box on;
    % legend('Partial lens')
    
    % second pca transform to orient the subregion for better fitting
    % Built-in PCA (centered is default)
    [Up,~,Lp,~,lp,mup] = pca(surfLensPtsPartial);
    surfLensPtsPartialPCA = (surfLensPtsPartial-mup) * Up; %forward projection/transformation
    
    % figure(114);
    % plot3(surfLensPtsPartialPCA(1:subSet:end,1),...
    %     surfLensPtsPartialPCA(1:subSet:end,2),surfLensPtsPartialPCA(1:subSet:end,3),'r.');
    % axis image
    % xlabel('x_{PCA}'),ylabel('y_{PCA}'),zlabel('z_{PCA}')
    % box on;
    % legend('Lens')
    tic
    [surfPoly,G,O] = fit(surfLensPtsPartialPCA(:,1:2),surfLensPtsPartialPCA(:,3),fittingmethod);
    toc
    % Re-make grid with desired point density:
    [xGrid,yGrid] = meshgrid(min(surfLensPtsPartialPCA(:,1)):density:...
        max(surfLensPtsPartialPCA(:,1)),min(surfLensPtsPartialPCA(:,2)):...
        density:max(surfLensPtsPartialPCA(:,2)));
    nP = length(xGrid(:));
    % Get surface points:
    surfVal = feval(surfPoly,xGrid(:),yGrid(:));
    surfPolyPts = [xGrid(:), yGrid(:), surfVal];
    
    figure(200+IdxSection);clf;
    plot3(surfLensPtsPartialPCA(1:subSet:end,1),surfLensPtsPartialPCA(1:subSet:end,2),surfLensPtsPartialPCA(1:subSet:end,3),'r.')
    axis image;
    hold on;
    box on;
    hS = surf(xGrid,yGrid,reshape(surfVal,size(xGrid)),'EdgeColor','none');
    material dull
    camlight
    title(['section ' num2str(IdxSection)])
    
    % Directions of sampling vectors:
    
    dirType = 'poly';
    if strcmp(dirType,'poly')
        % Use surface normals as direction guidance:
        
        % Get normals from polynomial surface: (may not be the best)
        [Nx,Ny,Nz] = surfnorm(xGrid,yGrid,reshape(surfVal,size(xGrid)));
        surfPolyDir = [Nx(:),Ny(:),Nz(:)];
        
        % Handle support region:
        surfPolyDir(~acptIdx,:) = 0;
    end
    
    % % Display:
    % figure;
    % surf(xGrid,yGrid,reshape(surfVal,size(xGrid)),repmat(supGridColor,[1 1 3]),'EdgeColor','none');
    % axis image
    % hold on;
    % plot3(0,0,0,'kx')
    % material dull
    % camlight
    % box on;
    % for i = 1:250:length(surfPolyPts)
    %     if acptIdx(i)
    %     plot3(  [surfPolyPts(i,1) surfPolyPts(i,1)-50*surfPolyDir(i,1)], ...
    %             [surfPolyPts(i,2) surfPolyPts(i,2)-50*surfPolyDir(i,2)], ...
    %             [surfPolyPts(i,3) surfPolyPts(i,3)-50*surfPolyDir(i,3)], 'r');
    %     end
    % end
    %
    
    % - Data Unfolding - %
    % Set-up sampling vectors
    coefficientValues = coeffvalues(surfPoly);
    
    if coefficientValues(4)>0
        sampRangeSub = lensUnfoldRangeSub; % How far to sample into the eye
        sampRangeUp  = lensUnfoldRangeUp; % How far to sample out from the eye
    else
        sampRangeSub = lensUnfoldRangeUp; % How far to sample into the eye
        sampRangeUp  = lensUnfoldRangeSub; % How far to sample out from the eye
    end
    
    sampDist = 0.5;
    tic
    % Preparation:
    Fdata = griddedInterpolant(single(niiData.img),'cubic','none'); % Currently working in voxel coordinates
    Flbl  = griddedInterpolant(single(niiLbl.img),'nearest','none');
    mappingVec = [-sampRangeSub:sampDist:sampRangeUp];
    nSamp = length(mappingVec);
    
    % Initialize and loop through layers of the sampling vectors:
    reformData = zeros(size(xGrid,1), size(yGrid,2),nSamp,'single');
    reformLbl = zeros(size(xGrid,1), size(yGrid,2),nSamp,'uint8');
    for i = 1:nSamp
        qPts = surfPolyPts + mappingVec(i)*surfPolyDir;
        qPts0 = qPts * Up' + mup;  %from the 2nd project to the 1st pca space
        qPtsOrg = qPts0 * U' + mu; %Projection to original space:
        
        reformData(:,:,i) = reshape(Fdata(qPtsOrg),size(xGrid));
        reformLbl(:,:,i) = reshape(uint8(Flbl(qPtsOrg)),size(xGrid));
    end
    toc
    
    %Export mapping:
    unfoldMappingFile = [saveDir savefileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfold_map.mat'];
    save(unfoldMappingFile,'mappingVec','surfPolyPts','surfPolyDir',...
        'surfPoly','G','O','Up','Lp','lp','mup','Up');
    
    % Export as nifty-volume:
    reformNii = make_nii(reformData,[1 1 1],[0 0 0],16);
    save_nii(reformNii,[saveDir savefileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfoldVolume.nii.gz']);
    
    reformLblNii = make_nii(reformLbl,[1 1 1],[0 0 0],2);
    save_nii(reformLblNii,[saveDir savefileprefix '_' num2str(IdxSection) '_' fittingmethod '_unfoldLabels.nii.gz']);
    
    residualMat = cell2mat(struct2cell(G));
    fittingError(IdxSection,:) = residualMat';
    fprintf('Data unfolded %d\n', IdxSection)
end
writematrix(fittingError,[saveDir savefileprefix 'fittingError.csv'])


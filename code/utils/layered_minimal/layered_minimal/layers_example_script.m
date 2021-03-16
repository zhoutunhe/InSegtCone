clear, close all

addpath GraphCut functions

lw = 2;
line_colors = [0 1 0; 1 0 0; 0 1 1; 1 0 1];

I = imresize(imread('test_data/layers.png'),[400,140]);
cost_dark = permute(I,[2,3,1]);
cost_bright = permute(255-I,[2,3,1]);

%%
dim = size(I);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, axis off
title('input image'), drawnow
%%
s = grid_cut(cost_dark,[],400);
figure
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),s,'Color',[255 255 0]/255,'LineWidth',lw)
title({'one dark line','smoothness constrained by 400'}), drawnow
%%
s = grid_cut(cost_dark,[],50);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),s,'r','LineWidth',lw)
title({'one dark line','smoothness constrained by 50'}), drawnow
%%
s = grid_cut(cost_dark,[],2);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),s,'r','LineWidth',lw)
title({'one dark line','smoothness constrained by 2'}), drawnow
%%
s = grid_cut(cost_dark,[],1);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),s,'r','LineWidth',lw)
title({'one dark line','smoothness constrained by 1'}), drawnow
%%
s = grid_cut(cat(4,cost_dark,cost_dark),[],[2;2],[],[5,400]);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'two dark lines','smoothness constrained by 2','overlap in interval [5 400]'}), drawnow
%%
s = grid_cut(cat(4,cost_dark,cost_dark),[],[1;2],[],[5,400]);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'two dark lines','smoothness constrained by 1 and 2','overlap in interval [5 400]'}), drawnow
%%
s = grid_cut(cat(4,cost_dark,cost_dark),[],[2;2],[],[15,400]);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'two dark lines','smoothness constrained by 2','overlap in interval [15 400]'}), drawnow
%%
s = grid_cut(cat(4,cost_dark,cost_dark),[],[2;2],[],[30,40]);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'two dark lines','smoothness constrained by 2','overlap in interval [30 40]'}), drawnow
%%
s = grid_cut(cost_bright,[],1);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'one bright line','smoothness constrained by 1'}), drawnow
%%
s = grid_cut(cat(4,cost_dark,cost_bright),[],[2;1],[],[0,60]);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'a dark and a bright line','smoothness constrained by 2 and 1','overlap in interval [0 60]'}), drawnow
%%
s = grid_cut(cat(4,cost_dark,cost_dark,cost_dark,cost_dark),[],[2;2;2;2],[],[40,100;20,100;20,150]);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'four dark lines','smoothness constrained by 2','different overlap constraints'}), drawnow
%%
% 9 regions, 8 surfaces, 7 overlap constrains
s = grid_cut([],cat(4,cost_bright,cost_dark,cost_bright,cost_dark,cost_bright,cost_dark,cost_bright,cost_dark,cost_bright),...
    [2;2;2;2;2;2;3;3],[],[5,15; 30,90; 5,10; 20,30; 5,20; 5,130; 5,20]);
figure, set(gca, 'ColorOrder', line_colors, 'NextPlot', 'replacechildren')
imagesc(I), axis image ij, colormap gray, hold on, axis off
plot(1:dim(2),permute(s,[1,3,2]),'LineWidth',lw)
title({'nine regions of alternating brightness','smoothness constrained by 2 or 3','different overlap constraints'}), drawnow


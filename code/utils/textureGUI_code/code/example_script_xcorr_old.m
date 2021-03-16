clear 
close all

addpath functions
im = double(imread('bag.png'))/255; 

%% dictionary parameters
M = 9; % patch size
L = 5; % maximum number of layers
n_train = 30000; % number of training patches
b = 5; % branching factor
normalization = true;

%% build km-tree
tic
tree = build_km_tree_xcorr(im, M, b, n_train, L);
toc

%% search km-tree
tic
A = search_km_tree_xcorr(im, tree, b);
toc

%% build biadjacency matrix
tic
B = biadjacency_matrix(A,M);
toc

[rc,nm] = size(B);
texture.T1 = sparse(1:nm,1:nm,1./(sum(B,1)+eps),nm,nm)*B';
texture.T2 = sparse(1:rc,1:rc,1./(sum(B,2)+eps),rc,rc)*B;


image_texture_gui(im,texture,2)


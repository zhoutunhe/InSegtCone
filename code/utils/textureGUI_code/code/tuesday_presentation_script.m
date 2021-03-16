clear
close all
addpath functions
%%
im = imread('../data/134052.jpg'); % leopard
dictopt.patch_size = 7;
dictopt.branching_factor = 3;
dictopt.number_layers = 5;
dictopt.number_training_patches = 5000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
image_texture_gui(im,dictopt,2)

%%
im = imread('bag.png'); % two textures
dictopt.patch_size = 15;
dictopt.branching_factor = 3;
dictopt.number_layers = 4;
dictopt.number_training_patches = 1000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
image_texture_gui(im,dictopt,2)

%%
im = imread('../data/raden15.png'); % randen 5 textures
dictopt.patch_size = 15;
dictopt.branching_factor = 3;
dictopt.number_layers = 4;
dictopt.number_training_patches = 2000;
dictopt.normalization = false;
dictopt.method = 'euclidean';
image_texture_gui(im,dictopt,5)

















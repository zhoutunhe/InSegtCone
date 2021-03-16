function dictionary = build_dictionary(image,dictionary_options)

image = normalize_image(image);
dictionary.options = dictionary_options;

if isfield(dictionary_options,'method')
    method = dictionary_options.method;
else
    method = 'euclidean';    
end

if isfield(dictionary_options,'normalization')
    normalization = dictionary_options.normalization;
else
    normalization = 'false';    
end

switch method
    case 'euclidean'
        dictionary.tree = build_km_tree(image,...
            dictionary_options.patch_size,...
            dictionary_options.branching_factor,...
            dictionary_options.number_training_patches,...
            dictionary_options.number_layers,...
            normalization);
    case 'nxcorr'
        dictionary.tree = build_km_tree_xcorr(image,...
            dictionary_options.patch_size,...
            dictionary_options.branching_factor,...
            dictionary_options.number_training_patches,...
            dictionary_options.number_layers);
    otherwise
        error('Unknown dictionary method.')
        
end

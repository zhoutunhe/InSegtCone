function image_texture_gui(image,dict,nr_labels,LABELING)
%IMAGE_TEXTURE_GUI   Interactive texture segmentation of the image
% IMAGE_TEXTURE_GUI(IMAGE,DICTOP,NR_LABELS,LABELING)
% Called without imput arguments starts in a demo mode. Input:
%   IMAGE, may be rgb or grayscale, 0-to-1 or uint8
%   DICT, may be either:
%       - dictopt struct containing dictinary parameters,
%       - dictionary struct containing the dictionary,
%       - mappings struct containing the transformation matrices,
%       - empty, so default options are loaded
%   NR_LABELS, number of labels, defaults to 2.
%   LABELING, initial labeling given as a matrix of the size
%       nr_pixels-by-nr_labels
%
% Keyboard controls:
%   L, shift+L and numerical values change label
%   T, shift+T, uparrow and downarros change pen thickness
%   W and shift+W change show option
%   M and shift+M change method
%   O and shift+O change overwrite option
%   R and shift+R change regularize option
%   C and shift+C change colormap
%   S saves a project
%
% Author: vand@dtu.dk, 2015
%
% TODO:
%   - when LABELING given, update segmentation upon startup
%   - when zooming, make sure mouse overlay circle not displayed (frozen)
%   - option for changing OPACITY

%%%%%%%%%% DEFAULTS %%%%%%%%%%
if nargin<1 % default example image
    image = imread('bag.png');
    dict.method = 'euclidian';
    dict.patch_size = 15;
    dict.branching_factor = 2;
    dict.number_layers = 5;
    dict.number_training_patches = 1000;
    dict.normalization = false;
    nr_labels = 2;
else
    if nargin<2 || isempty(dict)% default dictionary
        dict.method = 'euclidian';
        dict.patch_size = 3;
        dict.branching_factor = 2;
        dict.number_layers = 5;
        dict.number_training_patches = 1000;
        dict.normalization = false;
    end
    if nargin<3 || isempty(nr_labels) % defalult number of labels
        nr_labels = 2;
    else
        nr_labels = double(nr_labels); % for colormaps to work properly
    end
end

[r,c,~] = size(image);
if nargin<4 || isempty(LABELING) % default, unlabeled initial labeling
    LABELING = zeros(r*c,nr_labels);
end

%%%%%%%%%% PROBABILITY COMPUTING METHODS %%%%%%%%%%

method_options = {...
    @(labeling)distributed(labeling),...
    @(labeling)distributed_two_step(labeling),...
    @(labeling)distributed_area_weighted(labeling),...
    @(labeling)distributed_optimally_weighted(labeling),...
    @(labeling)normalized(labeling),...
    @(labeling)normalized_two_step(labeling),...
    @(labeling)marked(labeling),...
    @(labeling)diffusion(labeling),...
    @(labeling)diffusion_two_step(labeling),...
    };

%%%%%%%%%% SETTINGS %%%%%%%%%%

% method
METHOD_INDEX = 1; % initial method is the first on the list
METHOD = method_options{METHOD_INDEX};
METHOD_NAME = method_name_str;

% labels
LABEL = 1; % initial label is 1

% thickness
thickness_options = [1 2 3 4 5 10 20 30 40 50 100 -1]; % last option (value -1) is 'fill'
thickness_options_string = num2cell(thickness_options);
thickness_options_string{end} = 'fill';
THICKNESS_INDEX = 5; % initial pencil thickness is the fifth option
RADIUS = thickness2radius(thickness_options(THICKNESS_INDEX)); % pencil radius

% show
show_options(1:2) = {'segmentation','overlay'};
show_options((1:nr_labels)+2) = num2cell([repmat('probability ',[nr_labels,1]),num2str((1:nr_labels)')],2);
SHOW_INDEX = 1;

% overwrite
overwrite_options = {'no','yes'};
OVERWRITE = false; % initialy no overwrite

% regularization
regularize_options = [0 1 2 3 4 5 10 15 20 25 30 50];
REGULARIZE_INDEX = 1; % initialy no regularization

% colormap
colormap_options = {@(x)[0.5,0.5,0.5;cool(x)], @(x)[0.5,0.5,0.5;spring(x)],...
    @(x)[0.5,0.5,0.5;parula(x)]}; % gray color for unlabeled
COLORMAP_INDEX = 1; % current colormap
COLORS = colormap_options{COLORMAP_INDEX}(nr_labels); % visualization colors for label overlay

% other settings
color_weight = 0.4; % color weight for label overlay
nr_circle_pts = 16; % number of points defining a circular pencil

%%%%%%%%%% INITIALIZATION AND LAYOUT %%%%%%%%%%

[image,image_rgb,image_gray] = normalize_image(image); % impose 0-to-1 rgb
LABELING_OVERLAY = image_rgb; % image overlaid labeling
SEGMENTATION_OVERLAY = 0.5+zeros(r,c,3); % segmentation, optionally overlay

fmar = [0.2 0.2]; % discance from screen edge to figure (x and y)
amar = [0.05 0.05]; % margin around axes, relative to figure
my = 0.8:0.05:0.9; % menu items y position
mh = 0.03; % menu items height
cw = (0.4-0.3)/(nr_labels+1); % colorcube width
cx = 0.3:cw:0.4; % colorcubes x position

fig = figure('Units','Normalized','Position',[fmar,1-2*fmar],...
    'Pointer','watch','KeyPressFcn',@key_press,'InvertHardCopy', 'off',...
    'Name','Texture segmentation GUI');
% clean_toolbar

labeling_axes = axes('Units','Normalized','Position',[0,0,0.5,0.8]+[amar,-2*amar]);
imagesc(LABELING_OVERLAY), axis image off, hold on
segmentation_axes = axes('Units','Normalized','Position',[0.5,0,0.5,0.8]+[amar,-2*amar]);
imagesc(SEGMENTATION_OVERLAY,[0,nr_labels]), axis image off, hold on

uicontrol('String','Label [L] : ','Style','text','HorizontalAlignment','right',...
    'Units','Normalized','Position',[0,my(3),0.25,mh]);
labels_text = uicontrol('String',num2str(LABEL),...
    'BackgroundColor',COLORS(LABEL+1,:),...
    'Style','text','HorizontalAlignment','left',...
    'Units','Normalized','Position',[0.25,my(3),0.03,mh]);
label_pointer = cell(nr_labels+1,1);
label_colorcubes = cell(nr_labels+1,1);
label_char = repmat(' ',[1,nr_labels+1]);
label_char(LABEL+1)='|';
for k = 1:nr_labels+1
    label_colorcubes{k} = uicontrol('String',' ','Style','text',...
        'BackgroundColor',COLORS(k,:),...
        'Units','Normalized','Position',[cx(k),my(3),cw,mh/2]);
    label_pointer{k} = uicontrol('String',label_char(k),'Style','text',...
        'HorizontalAlignment','center',...
        'Units','Normalized','Position',[cx(k),my(3)+mh/2,cw,mh/2]);
end

uicontrol('String','Thickness [T] : ','Style','text','HorizontalAlignment','right',...
    'Units','Normalized','Position',[0,my(2),0.25,mh]);
thickness_text = uicontrol('String',thickness_options_string(THICKNESS_INDEX),...
    'Style','text','HorizontalAlignment','left',...
    'Units','Normalized','Position',[0.25,my(2),0.25,mh]);

uicontrol('String','Show [W] :','Style','text','HorizontalAlignment','right',...
    'Units','Normalized','Position',[0,my(1),0.25,mh]);
show_text = uicontrol('String',show_options{SHOW_INDEX},...
    'Style','text','HorizontalAlignment','left',...
    'Units','Normalized','Position',[0.25,my(1),0.25,mh]);

uicontrol('String','Method [M] : ','Style','text','HorizontalAlignment','right',...
    'Units','Normalized','Position',[0.5,my(3),0.25,mh]);
method_text = uicontrol('String',METHOD_NAME,...
    'Style','text','HorizontalAlignment','left',...
    'Units','Normalized','Position',[0.75,my(3),0.25,mh]);

uicontrol('String','Overwrite [O] : ','Style','text','HorizontalAlignment','right',...
    'Units','Normalized','Position',[0.5,my(2),0.25,mh]);
overlay_text = uicontrol('String',overwrite_options(OVERWRITE+1),...
    'Style','text','HorizontalAlignment','left',...
    'Units','Normalized','Position',[0.75,my(2),0.25,mh]);

uicontrol('String','Regularize [R] : ','Style','text','HorizontalAlignment','right',...
    'Units','Normalized','Position',[0.5,my(1),0.25,mh]);
regularize_text = uicontrol('String',regularize_options(REGULARIZE_INDEX),...
    'Style','text','HorizontalAlignment','left',...
    'Units','Normalized','Position',[0.75,my(1),0.25,mh]);

drawnow % pointer shows busy system

LIMITS = [1,c-0.5,1,r+0.5]; % to capture zoom
zoom_handle = zoom(fig);
pan_handle = pan(fig);
set(zoom_handle,'ActionPostCallback',@adjust_limits,...
    'ActionPreCallback',@force_keep_key_press);
set(pan_handle,'ActionPostCallback',@adjust_limits,...
    'ActionPreCallback',@force_keep_key_press);

%%%%%%%%%% TEXTURE REPRESENTATION %%%%%%%%%%
% initiolization: building a texture representation of the image
% parsing dictopt input: either dictionary_options, dictionary or mappings
if isfield(dict,'patch_size') % dictionary options given
    dictionary = build_dictionary(image,dict);
    mappings = compute_mappings(image,dictionary);
    T1 = mappings.T1;
    T2 = mappings.T2;
elseif isfield(dict,'tree')% dictinary given
    mappings = compute_mappings(image,dict);
    T1 = mappings.T1;
    T2 = mappings.T2;
elseif isfield(dict,'T1')% mapping given
    T1 = dict.T1;
    T2 = dict.T2;
else
    error('Could not parse dictionary input.')
end

PROBABILITY = METHOD(LABELING);
labeling_overwrite
regularize
compute_overlays

% ready to draw
set(fig,'Pointer','arrow','WindowButtonDownFcn',@start_draw,...
    'WindowButtonMotionFcn',@pointer_motion);
XO = []; % current drawing point
uiwait % waits with assigning output until a figure is closed

%%%%%%%%%% CALLBACK FUNCTIONS %%%%%%%%%%
    function key_press(~,object)
        % keyboard commands
        key = object.Key;
        numkey = str2double(key);
        if ~isempty(numkey) && numkey<=nr_labels;
            label_char(LABEL+1)=' ';
            LABEL = numkey;
            set(labels_text,'String',num2str(LABEL),...
                'BackgroundColor',COLORS(LABEL+1,:));
            label_char(LABEL+1)='|';
            for kk = 1:nr_labels+1
                set(label_pointer{kk},'String',label_char(kk));
            end
        else
            switch key
                case 'l'
                    label_char(LABEL+1)=' ';
                    LABEL = move_once(LABEL+1,nr_labels+1,...
                        any(strcmp(object.Modifier,'shift')))-1;
                    set(labels_text,'String',num2str(LABEL),...
                        'BackgroundColor',COLORS(LABEL+1,:));
                    label_char(LABEL+1)='|';
                    for kk = 1:nr_labels+1
                        set(label_pointer{kk},'String',label_char(kk));
                    end
                case 'uparrow'
                    THICKNESS_INDEX = move_once(THICKNESS_INDEX,...
                        numel(thickness_options),false);
                    RADIUS = thickness2radius(thickness_options(THICKNESS_INDEX));
                    set(thickness_text,'String',...
                        thickness_options_string(THICKNESS_INDEX));
                    show_overlays(get_pixel);
                case 'downarrow'
                    THICKNESS_INDEX = move_once(THICKNESS_INDEX,...
                        numel(thickness_options),true);
                    RADIUS = thickness2radius(thickness_options(THICKNESS_INDEX));
                    set(thickness_text,'String',...
                        thickness_options_string(THICKNESS_INDEX));
                    show_overlays(get_pixel);
                case 't'
                    THICKNESS_INDEX = move_once(THICKNESS_INDEX,...
                        numel(thickness_options),any(strcmp(object.Modifier,'shift')));
                    RADIUS = thickness2radius(thickness_options(THICKNESS_INDEX));
                    set(thickness_text,'String',...
                        thickness_options_string(THICKNESS_INDEX));
                    show_overlays(get_pixel);
                case 'w'
                    SHOW_INDEX = move_once(SHOW_INDEX,numel(show_options),...
                        any(strcmp(object.Modifier,'shift')));
                    set(show_text,'String',show_options{SHOW_INDEX})
                    compute_overlays
                    show_overlays(get_pixel);
                case 'c'
                    COLORMAP_INDEX = move_once(COLORMAP_INDEX,...
                        length(colormap_options),...
                        any(strcmp(object.Modifier,'shift')));
                    COLORS = colormap_options{COLORMAP_INDEX}(nr_labels);
                    set(labels_text,'BackgroundColor',COLORS(LABEL+1,:));
                    for kk = 1:nr_labels+1
                        set(label_colorcubes{kk},'BackgroundColor',COLORS(kk,:))
                    end
                    compute_overlays
                    show_overlays(get_pixel);
                case 'm'
                    METHOD_INDEX = move_once(METHOD_INDEX,...
                        length(method_options),...
                        any(strcmp(object.Modifier,'shift')));
                    METHOD = method_options{METHOD_INDEX};
                    METHOD_NAME = method_name_str;
                    set(method_text,'String',METHOD_NAME)
                    PROBABILITY = METHOD(LABELING);
                    labeling_overwrite
                    regularize
                    compute_overlays
                    show_overlays(get_pixel);
                case 'o'
                    OVERWRITE = ~OVERWRITE;
                    set(overlay_text,'String',overwrite_options{OVERWRITE+1})
                    PROBABILITY = METHOD(LABELING);
                    labeling_overwrite
                    regularize
                    compute_overlays
                    show_overlays(get_pixel);
                case 'r'
                    REGULARIZE_INDEX = move_once(REGULARIZE_INDEX,...
                        numel(regularize_options),...
                        any(strcmp(object.Modifier,'shift')));
                    set(regularize_text,'String',...
                        regularize_options(REGULARIZE_INDEX))
                    PROBABILITY = METHOD(LABELING);
                    labeling_overwrite
                    regularize
                    compute_overlays
                    show_overlays(get_pixel);
                case 's'
                    save_project
                case 'e'
                    export_LS
                case 'f'
                    freeze_LS
                case 'q'
                    close(fig)
            end
        end
    end

    function adjust_limits(~,~)
        % response to zooming and panning
        LIMITS([1,2]) = get(labeling_axes,'XLim');
        LIMITS([3,4]) = get(labeling_axes,'YLim');
    end

    function force_keep_key_press(~,~)
        % a hack to maintain my key_press while in zoom and pan mode
        % http://undocumentedmatlab.com/blog/enabling-user-callbacks-during-zoom-pan
        hManager = uigetmodemanager(fig);
        [hManager.WindowListenerHandles.Enabled] = deal(false);
        set(fig, 'KeyPressFcn', @key_press);
    end

    function start_draw(~,~)
        % click in the image
        x = get_pixel;
        if is_inside(x)
            if RADIUS>0 % thickness>0
                XO = x;
                M = disc(XO,RADIUS,nr_circle_pts,[r,c]);
                set(fig,'WindowButtonMotionFcn',@drag_and_draw,...
                    'WindowButtonUpFcn',@end_draw)
            else % fill
                M = fill(x);
            end
            update(M);
        end
    end

    function drag_and_draw(~,~)
        % drag after clicking in the image
        x = get_pixel;
        M = stadium(XO,x,RADIUS,nr_circle_pts,[r,c]);
        update(M);
        XO = x;
    end

    function end_draw(~,~)
        % release click after clicking in the image
        M = stadium(XO,get_pixel,RADIUS,nr_circle_pts,[r,c]);
        update(M);
        XO = [];
        set(fig,'WindowButtonMotionFcn',@pointer_motion,...
            'WindowButtonUpFcn','')
    end

    function pointer_motion(~,~)
        % move around without clicking
        if strcmp(zoom_handle.Enable,'off') && ...
                strcmp(pan_handle.Enable,'off') % not zooming or panning
            x = get_pixel;
            if is_inside(x)
                set(fig,'Pointer','crosshair')
            else
                set(fig,'Pointer','arrow')
            end
            show_overlays(x);
        end
    end

%%%%%%%%%% HELPING FUNCTIONS %%%%%%%%%%

    function [L,S] = membership2indexed
        % computes labeling and segmentation as indexed r-by-c images
        % from membership r*c-by-nr_labels representation
        [maxlab,L] = max(LABELING,[],2);
        L(maxlab==0) = 0;
        L = uint8(reshape(L,[r,c]));
        [maxprob,S] = max(PROBABILITY,[],2);
        S(sum(PROBABILITY==maxprob(:,ones(nr_labels,1)),2)>1) = 0;
        S = uint8(reshape(S,[r,c]));
    end

    function save_project
        % saves mat file with user labelings, probabilities and settings
        % saves images as separate files
        % TODO questionable whether dicopt should be saved when it's T1 T2
        % TODO consider whether saving images should be separate function
        [file,path] = uiputfile('segmentation.mat','Save project as');
        if ~isequal(file,0) && ~isequal(path,0)
            matfile = fullfile(path,file);
            roothname = matfile(1:find(matfile=='.',1,'last')-1);
            current_settings.method = METHOD_NAME;
            current_settings.show = show_options{SHOW_INDEX};
            current_settings.overwrite = OVERWRITE;
            current_settings.regularize = regularize_options(REGULARIZE_INDEX);
            save(matfile,'LABELING','PROBABILITY',...
                'dictopt','nr_labels','current_settings')
            % writing labeling and segmentation as overlay (shown rgb)
            imwrite(LABELING_OVERLAY,[roothname,'_labeling_rgb.png'])
            imwrite(SEGMENTATION_OVERLAY,[roothname,'_segmentation_rgb.png'])
            [L,S] = membership2indexed;
            imwrite(L,COLORS,[roothname,'_labeling_indexed.png'])
            imwrite(S,COLORS,[roothname,'_segmentation_indexed.png'])
        end
    end

    function export_LS
        % saves variables to workspace
        % TODO, consider using:
        % export2wsdlg({'Labeling','Segmentation'},{'gui_L','gui_S'},{L,S})
        button = questdlg({'Exporting variables to the base workspace',...
            'might overwrite existing variables'},...
            'Exporting variables','OK','Cancel','OK');
        if strcmp(button,'OK')
            [L,S] = membership2indexed;
            assignin('base','gui_L',L)
            assignin('base','gui_S',S)
        end
    end

    function freeze_LS
        % feezes, closes and opens segmentation_correction_gui
        button = questdlg({'Freezing segmentation will close texture segmentation gui',...
            'and open segmentation correction gui.'},...
            'Freezing segmentation','OK','Cancel','OK');
        if strcmp(button,'OK')
            [L,S] = membership2indexed;
            close(fig)
            segmentation_correction_gui(image_rgb,S,nr_labels,L);
        end
    end

    function a = is_inside(x)
        % check if x is inside image limits
        a = inpolygon(x(1),x(2),LIMITS([1,2,2,1]),LIMITS([3,3,4,4]));
    end

    function p = get_pixel
        % get cursor position
        p = get(labeling_axes,'CurrentPoint');
        p = round(p(1,[1,2]));
    end

    function show_overlays(x)
        % overlay a circular region where the pointer is and show
        shown_left = LABELING_OVERLAY;
        shown_right = SEGMENTATION_OVERLAY;
        if RADIUS>0 % thickness>0
            P = repmat(disc(x,RADIUS,nr_circle_pts,[r,c]),[1,1,3]);
            shown_left(P(:)) = 0.5+0.5*LABELING_OVERLAY(P(:));
            shown_right(P(:)) = 0.5+0.5*SEGMENTATION_OVERLAY(P(:));
        end
        % we have to imagesc(shown) to remove overlay if needed
        axes(labeling_axes), cla, imagesc(shown_left)
        axes(segmentation_axes), cla, imagesc(shown_right)
    end

    function update(M)
        % change the state of the segmentation by updating LABELING with a
        % mask M, and updating PROBABILITY
        labcol = zeros(1,nr_labels);
        if LABEL>0 % not unlabeling
            labcol(LABEL) = 1;
        end
        LABELING(M(:),:) = repmat(labcol,[sum(M(:)),1]);
        PROBABILITY = METHOD(LABELING); % PROBABILITY computed
        labeling_overwrite
        regularize
        compute_overlays % computing overlay images
        show_overlays(get_pixel); % showing overlay and pointer
    end

    function compute_overlays
        % TODO a lot of this does not need to be recalculated
        % computes overlays but not pointer overalay
        LABELING_OVERLAY = reshape(LABELING*COLORS(2:end,:),size(image_rgb)).*...
            (color_weight+(1-color_weight)*image_gray);
        unlabeled = repmat(~any(LABELING,2),[3,1]); % pixels not labeled
        LABELING_OVERLAY(unlabeled) = image_rgb(unlabeled);
        
        if SHOW_INDEX<3 % showing segmentation or overlay
            maxprob = max(PROBABILITY,[],2);
            maxprobloc = PROBABILITY == maxprob(:,ones(nr_labels,1));
            uncertain = sum(maxprobloc,2)>1; % pixels with max probability at two or more classes
            maxprobloc(uncertain,:) = 0;
            if SHOW_INDEX==1 % segmentation
                SEGMENTATION_OVERLAY = reshape([uncertain,maxprobloc]*COLORS,size(image_rgb));
            else % SHOW_INDEX==2 overlay
                SEGMENTATION_OVERLAY = reshape([uncertain,maxprobloc]*COLORS,...
                    size(image_rgb)).*(color_weight+(1-color_weight)*image_gray);
            end
        else % 'probability x'
            pw = SHOW_INDEX-2; % probability to show
            minpw = min(PROBABILITY(:,pw));
            maxpw = max(PROBABILITY(:,pw));
            % TODO scaling should be better, relative to 1/nr_labels
            SEGMENTATION_OVERLAY = reshape((PROBABILITY(:,pw)-minpw)/(maxpw-minpw)*[1,1,1],size(image_rgb));
        end
    end

% TODO disc shold be saved as a list of index shifts with respect to
% the central pixel, and change only when thickness changes
    function M = disc(x,r,N,dim)
        % disc shaped mask in the image
        angles = (0:2*pi/N:2*pi*(1-1/N));
        X = x(1)+r*cos(angles);
        Y = x(2)+r*sin(angles);
        M = poly2mask(X,Y,dim(1),dim(2));
    end

    function M = stadium(x1,x2,r,N,dim)
        % stadium shaped mask in the image
        angles = (0:2*pi/N:pi)-atan2(x1(1)-x2(1),x1(2)-x2(2));
        X = [x1(1)+r*cos(angles), x2(1)+r*cos(angles+pi)];
        Y = [x1(2)+r*sin(angles), x2(2)+r*sin(angles+pi)];
        M = poly2mask(X,Y,dim(1),dim(2));
    end

    function M = fill(x)
        [maxL,labL] = max(LABELING,[],2);
        label_image = reshape(maxL.*labL,[r,c]);
        M = bwselect(label_image==label_image(x(2),x(1)),x(1),x(2),4);
    end

    function [I,I_rgb,I_gray] = normalize_image(I)
        % initialization: normalize image
        if isa(I,'uint8')
            I = double(I)/255;
        end
        if isa(I,'uint16')
            I = double(I)/65535;
        end
        if size(I,3)==3 % rgb image
            I_gray = repmat(rgb2gray(I),[1 1 3]);
            I_rgb = I;
        else % assuming grayscale image
            I_gray = repmat(I,[1,1,3]);
            I_rgb = I_gray;
        end
    end

    function name = method_name_str
        method_str = func2str(METHOD);
        s1 = find(method_str==')',1,'first')+1;
        s2 = find(method_str=='(',1,'last')-1;
        name = method_str(s1:s2);
    end

    function n = move_once(n,total,reverse)
        % moves option index once, respecting total number of options
        if ~reverse
            n = mod(n,total)+1;
        else
            n = mod(n+total-2,total)+1;
        end
    end

    function labeling_overwrite
        % labeled areas get assigned probability 1
        if OVERWRITE
            labeled = any(LABELING,2);
            PROBABILITY(labeled,:) = LABELING(labeled,:); % overwritting labeled
        end
    end

    function regularize
        sigma = regularize_options(REGULARIZE_INDEX);
        if sigma>0
            filter = fspecial('gaussian',[2*ceil(sigma)+1,1],sigma);
            PROBABILITY = reshape(PROBABILITY,[r,c,nr_labels]);
            PROBABILITY = imfilter(PROBABILITY,filter,'replicate');
            PROBABILITY = imfilter(PROBABILITY,filter','replicate');
            PROBABILITY = reshape(PROBABILITY,[r*c,nr_labels]);
        end
    end

    function r = thickness2radius(t)
        r = t/2+0.4;
    end

    function clean_toolbar
        set(fig,'MenuBar','none','Toolbar','figure');
        toolbar = findall(fig,'Type','uitoolbar');
        all_tools = allchild(toolbar);
        % removing tools
        for i=1:numel(all_tools)
            if isempty(strfind(all_tools(i).Tag,'Pan'))&&...
                    isempty(strfind(all_tools(i).Tag,'Zoom'))&&...
                    isempty(strfind(all_tools(i).Tag,'SaveFigure'))&&...
                    isempty(strfind(all_tools(i).Tag,'PrintFigure'))&&...
                    isempty(strfind(all_tools(i).Tag,'DataCursor'))
                delete(all_tools(i)) % keeping only Pan, Zoom, Save and Print
            end
        end
        % adding a tool
        [icon,~,alpha] = imread('linkzoomsicon.png');
        icon = double(icon)/255;
        icon(alpha==0)=NaN;
        link_zooms = uitoggletool(toolbar,'CData',icon,...
            'TooltipString','Link Zooms','Tag','LinkZoom',...
            'OnCallback',linkzooms,'OffCallback',linkzooms);
        % changing the order of tools
        all_tools = allchild(toolbar);
        set(toolbar,'children',all_tools([3,2,1,4:end]));        
    end


%%%%%%%%%% LABELINGS TO PROBABILITIES METHODS %%%%%%%%%%

    function probabilities = distributed(labelings)
        % unlabeled pixels have label weights DISTRIBUTED equally
        % unlabeled pixels get 1/nr_labels probability for all classes
        labelings(~any(labelings,2),:) = 1/nr_labels; % distributing
        probabilities = T2*(T1*labelings); % computing probabilities
    end

    function probabilities = distributed_area_weighted(labelings)
        % DISTRIBUTED with area weighting of probabilities
        labelings(~any(labelings,2),:) = 1/nr_labels; % distributing
        areas = sum(labelings,1); % areas
        probabilities = T2*(T1*labelings)*diag(1./areas); % probabilities area weighted
        probabilities = probabilities./repmat(sum(probabilities,2),[1,size(probabilities,2)]); % normalized
        probabilities(isnan(probabilities)) = 0; % handling division by 0
    end

    function probabilities = distributed_two_step(labelings)
        % DISTRIBUTED tresholded and repeated
        labelings(~any(labelings,2),:) = 1/nr_labels; % distributing
        probabilities = T2*(T1*labelings); % probabilities
        maxprob = max(probabilities,[],2); % finding max probabilities
        maxprobloc = probabilities == maxprob(:,ones(nr_labels,1)); % label with max
        uncertain = sum(maxprobloc,2)>1; % pixels with max probability at two or more classes
        maxprobloc(uncertain,:) = 0; % zero at uncertain
        labelings = maxprobloc; % new labeling is where max prob was
        labelings(~any(labelings,2),:) = 1/nr_labels; % distributing at uncertain
        probabilities = T2*(T1*labelings);
    end

    function probabilities = distributed_optimally_weighted(labelings)
        % TODO, ASSURE ELEMENTS OF WEIGHTS ARE POSITIVE, use lsqnonneg
        labelings(~any(labelings,2),:) = 1/nr_labels; % distributing
        probabilities = T2*(T1*labelings); % computing probabilities
        weights = probabilities(any(labelings,2),:)\labelings(any(labelings,2),:);
        probabilities = probabilities*weights; % weighting
        % assuring all probabilities are positive
        probabilities = probabilities - repmat(min(min(probabilities,0),[],2),[1,size(probabilities,2)]);
        % normalizing probabilities so that they sum to 1
        probabilities = probabilities./repmat(sum(probabilities,2),[1,size(probabilities,2)]);
        probabilities(isnan(probabilities)) = 0;
    end

    function probabilities = normalized(labelings)
        probabilities = T2*(T1*labelings); % computing probabilities
        % normalizing probabilities so that they sum to 1
        probabilities = probabilities./repmat(sum(probabilities,2),[1,size(probabilities,2)]);
        probabilities(isnan(probabilities)) = 0;
    end

    function probabilities = normalized_two_step(labelings)
        probabilities = T2*(T1*labelings); % computing probabilities
        % normalizing probabilities so that they sum to 1
        probabilities = probabilities./repmat(sum(probabilities,2),[1,size(probabilities,2)]);
        probabilities(isnan(probabilities)) = 0;
        for i = 1:3
            probabilities(any(labelings,2),:) = labelings(any(labelings,2),:);
            probabilities = T2*(T1*probabilities); % computing probabilities
        end
    end

    function probabilities = diffusion(labelings)
        % DISTRIBUTED tresholded and repeated
        labelings_distributed = labelings;
        known_labels = any(labelings,2);
        labelings_distributed(~known_labels,:) = 1/nr_labels; % distributing
        probabilities = T2*(T1*labelings_distributed); % probabilities
        for i = 1:3
            probabilities(known_labels,:) = labelings(known_labels,:);
            probabilities = T2*(T1*probabilities);
        end
    end

    function probabilities = marked(labelings)
        % DISTRIBUTED tresholded and repeated
        labelings_distributed = labelings;
        known_labels = any(labelings,2);
        %         labelings_distributed(~known_labels,:) = 1/nr_labels; % distributing
        probabilities = T2*(T1*labelings_distributed); % probabilities
        for i = 1:3
            probabilities(known_labels,:) = labelings(known_labels,:);
            probabilities = T2*(T1*probabilities);
        end
    end

    function probabilities = diffusion_two_step(labelings)
        % DISTRIBUTED tresholded and repeated
        labelings_distributed = labelings;
        known_labels = any(labelings,2);
        labelings_distributed(~known_labels,:) = 1/nr_labels; % distributing
        probabilities = T2*(T1*labelings_distributed); % probabilities
        for i = 1:3
            probabilities(known_labels,:) = labelings(known_labels,:);
            probabilities = T2*(T1*probabilities);
        end
        for i = 1:3
            maxprob = max(probabilities,[],2); % finding max probabilities
            maxprobloc = probabilities == maxprob(:,ones(nr_labels,1)); % label with max
            uncertain = sum(maxprobloc,2)>1; % pixels with max probability at two or more classes
            maxprobloc(uncertain,:) = 0; % zero at uncertain
            labelings = maxprobloc; % new labeling is where max prob was
            labelings(~any(labelings,2),:) = 1/nr_labels; % distributing at uncertain
            probabilities = T2*(T1*labelings);
        end
    end

end

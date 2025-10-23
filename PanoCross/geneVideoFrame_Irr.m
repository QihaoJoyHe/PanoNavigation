% Pano stimuli preparation
% Save stimuli parameters to mat file
% Generate frames and save for each pano
% Irregular condition
%
% By Qihao He, May 2025
clear; 
clc;

CurPath = pwd;

%% Load pano parameters
IrrParameters = readtable('IrregularPanoParameters.xlsx');
panoNum = 60;

%% Generate IrrPanoList
for p = 1:panoNum
    % Pano num
    IrrPano(p).num = IrrParameters.Num(p);
    % Pano file name
    IrrPano(p).name = IrrParameters.PanoName(p);

    % Decide vx_start, by NorthRotation
    % Always face the North at the begining
    if IrrParameters.NorthRotation(p) <= 45 || IrrParameters.NorthRotation(p) >315
        IrrPano(p).start = -pi;
    elseif IrrParameters.NorthRotation(p) > 45 && IrrParameters.NorthRotation(p) <=135
        IrrPano(p).start = -pi/2;
    elseif IrrParameters.NorthRotation(p) > 135 && IrrParameters.NorthRotation(p) <=225
        IrrPano(p).start = 0;
    else
        IrrPano(p).start = pi/2;
    end
end

% Save CrossPano
save(fullfile(CurPath, 'IrrPanoList.mat'), 'IrrPano');

%% Generate IrrPracList, 这里也需要调整
for p = 1:2
    % Pano num
    IrrPrac(p).num = p;
    % Pano file name
    IrrPrac(p).name = IrrParameters.PanoName(p + panoNum);

    % Decide vx_start, by NorthRotation
    % Always face the North at the begining
    if IrrParameters.NorthRotation(p + panoNum) <= 45 || IrrParameters.NorthRotation(p + panoNum) >315
        IrrPrac(p).start = -pi;
    elseif IrrParameters.NorthRotation(p + panoNum) > 45 && IrrParameters.NorthRotation(p + panoNum) <=135
        IrrPrac(p).start = -pi/2;
    elseif IrrParameters.NorthRotation(p + panoNum) > 135 && IrrParameters.NorthRotation(p + panoNum) <=225
        IrrPrac(p).start = 0;
    else
        IrrPrac(p).start = pi/2;
    end
end

% Save CrossPano
save(fullfile(CurPath, 'IrrPracList.mat'), 'IrrPrac');


%% Generate each frame and save, fov = 45
% Load CrossPanoList
load IrrPanoList.mat;

% Path
PATH_pano = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/panoramaSet/Irregular';
PATH_video = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/video';  % 这里需要改
duration_half = 6;
duration_fade = 2;
fr = 30;
fov = pi/4; % 45 degree
imgSize = 800;

% Read pano and separate
for i = 31:60
    img_pano = imread(fullfile(PATH_pano, sprintf('p%d.jpg', i)));
    img_pano = im2double(img_pano);  % 归一化到 [0,1]
    
    % Start angle
    vx_start = IrrPano(i).start;
    
    % Total frame
    frame_cnt = fr * duration_half * 2;
    
    % Generate each frame and save
    tic
    for frame = 1:frame_cnt
        vx = vx_start + 2 * pi / frame_cnt * frame;
        img_sep = separatePano(img_pano, fov, vx, 0, imgSize);
        img_frame = img_sep.img;
        rect = centerCropWindow2d(size(img_frame), [800, 800]);
        img_frame = imcrop(img_frame, rect);
        
        % save
        img_filename = fullfile(PATH_video, sprintf('p%d_%d.jpg', i, frame));
        imwrite(img_frame, img_filename);
    end
    toc
end

%% Generate practice frame
% Load IrrPracList
load IrrPracList.mat;

% Path
PATH_pano = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/panoramaSet/Irregular';
PATH_video = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/video';
duration_half = 6;
duration_fade = 2;
fr = 30;
fov = pi/4; % 45 degree
imgSize = 800;

% Read pano and separate
for i = 1:2
    img_pano = imread(fullfile(PATH_pano, sprintf('prac%d.jpg', i)));
    img_pano = im2double(img_pano);  % 归一化到 [0,1]
    
    % Start angle
    vx_start = IrrPrac(i).start;
    
    % Total frame
    frame_cnt = fr * duration_half * 2;
    
    % Generate each frame and save
    tic
    for frame = 1:frame_cnt
        vx = vx_start + 2 * pi / frame_cnt * frame;
        img_sep = separatePano(img_pano, fov, vx, 0, imgSize);
        img_frame = img_sep.img;
        rect = centerCropWindow2d(size(img_frame), [800, 800]);
        img_frame = imcrop(img_frame, rect);
        
        % save
        img_filename = fullfile(PATH_video, sprintf('prac%d_%d.jpg', i, frame));
        imwrite(img_frame, img_filename);
    end
    toc
end



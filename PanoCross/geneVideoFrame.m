% Pano stimuli preparation
% Save stimuli parameters to mat file
% Generate frames and save for each pano
%
% By Qihao He, March 2025
clear; 
clc;

CurPath = pwd;

%% Load pano parameters
CrossParameters = readtable('CrossPanoParameters.xlsx');
panoNum = 60;

%% Generate CrossPanoList
for p = 1:panoNum
    % Pano num
    CrossPano(p).num = CrossParameters.Num(p);
    % Pano file name
    CrossPano(p).name = CrossParameters.PanoName(p);

    % Decide vx_start, by NorthRotation
    % Always face the North at the begining
    if CrossParameters.NorthRotation(p) <= 45 || CrossParameters.NorthRotation(p) >315
        CrossPano(p).start = -pi;
    elseif CrossParameters.NorthRotation(p) > 45 && CrossParameters.NorthRotation(p) <=135
        CrossPano(p).start = -pi/2;
    elseif CrossParameters.NorthRotation(p) > 135 && CrossParameters.NorthRotation(p) <=225
        CrossPano(p).start = 0;
    else
        CrossPano(p).start = pi/2;
    end
end

% Save CrossPano
save(fullfile(CurPath, 'CrossPanoList.mat'), 'CrossPano');

%% Generate CrossPracList
for p = 1:2
    % Pano num
    CrossPrac(p).num = p;
    % Pano file name
    CrossPrac(p).name = CrossParameters.PanoName(p + panoNum);

    % Decide vx_start, by NorthRotation
    % Always face the North at the begining
    if CrossParameters.NorthRotation(p + panoNum) <= 45 || CrossParameters.NorthRotation(p + panoNum) >315
        CrossPrac(p).start = -pi;
    elseif CrossParameters.NorthRotation(p + panoNum) > 45 && CrossParameters.NorthRotation(p + panoNum) <=135
        CrossPrac(p).start = -pi/2;
    elseif CrossParameters.NorthRotation(p + panoNum) > 135 && CrossParameters.NorthRotation(p + panoNum) <=225
        CrossPrac(p).start = 0;
    else
        CrossPrac(p).start = pi/2;
    end
end

% Save CrossPano
save(fullfile(CurPath, 'CrossPracList.mat'), 'CrossPrac');


%% Generate each frame and save, fov = 45
% Load CrossPanoList
load CrossPanoList.mat;

% Path
PATH_pano = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/panoramaSet/Cross';
PATH_video = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/video';
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
    vx_start = CrossPano(i).start;
    
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
        
        % 生成文件名并保存
        img_filename = fullfile(PATH_video, sprintf('p%d_%d.jpg', i, frame));
        imwrite(img_frame, img_filename);
    end
    toc
end

%% Generate practice frame
% Load CrossPracList
load CrossPracList.mat;

% Path
PATH_pano = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/panoramaSet/Cross';
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
    vx_start = CrossPrac(i).start;
    
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
        
        % 生成文件名并保存
        img_filename = fullfile(PATH_video, sprintf('prac%d_%d.jpg', i, frame));
        imwrite(img_frame, img_filename);
    end
    toc
end



% Stimuli List Creating
% Save all panorama in a mat file
% 
% By Qihao He, 2025 March

clear all
clc;

CodePath = '/Users/Shared/D/1PKU北大_______/LiLab/PanoExp';


% 初始化结构体数组（这里先创建 1 张图片的信息）
exp_pano(1).house = 'test_house';  % 房屋标识，可自定义
exp_pano(1).room = 'test_room';    % 房间标识，可自定义
exp_pano(1).north = 0;             % 设定初始朝向，可随机或手动设定
exp_pano(1).dir_move = 1;          % 设定旋转方向（1 = 正向, -1 = 反向）

save(fullfile(CodePath, 'exp_pano.mat'), 'exp_pano');

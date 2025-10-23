% Instructions Preparation

clear all
clc;

CodePath = pwd;
cd /Users/Shared/D/1PKU北大_______/LiLab/PanoExp_v2/instructions

% Instruction Images Location
Instruction.Start = imread('Start.PNG');
Instruction.Prac = imread('Prac.PNG');
Instruction.Test = imread('Test.PNG');
Instruction.Rest = imread('Rest.PNG');
Instruction.End = imread('End.PNG');

% Save mat
save(fullfile(CodePath, 'Instructions.mat'),'Instruction');


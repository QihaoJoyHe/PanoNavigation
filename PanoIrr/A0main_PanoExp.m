% Pano exp, Irregular condition
% Phase1: learning, free exploration, 60s timeLimit, record keyPress
% Phase2: test, record responseAngle, give feedback
% 20 panos for each participant, 40min
% ImgSize = 1080, fov = 45, vDist = 48.5 (cm)
% 
% By Qihao He, 2025 May

%% Experiment
sca;
clear;
clc;

% Preparation
currPath = pwd;
esc = 0;

% Get demography data
subinfo = getSubInfo();
Seriesnum = str2num(subinfo{1});

% Create results saving folder
ResultSavingPath = [currPath,'/ResultsSummary/',num2str(Seriesnum),'_IrrPanoResults'];
mkdir(ResultSavingPath);

% Exp run parameters
global trialnum totalnum blank snapshot feedback
trials = 20;  % 20
blocks = 1;
trialnum = trials * blocks; 
totalnum = 60;
resttrialnum = 5;  % 5
pracnum = 2;  % 2
blank = 0.5; 
snapshot = 2.5;
feedback = 2;

% Fixation cross parameters, pixel
global fixCrossDimPix lineWidthPix
fixCrossDimPix = 70;
lineWidthPix = 10;

% Movie parameters
global frameNum fps duration timeLimit
frameNum = 360;
fps = 30;
duration = frameNum / fps;
timeLimit = 60;  % 60

% Response keys
KbName('UnifyKeyNames');
global Leftkey Rightkey Esckey Triggerkey
Leftkey = KbName('LeftArrow'); 
Rightkey = KbName('RightArrow'); 
Esckey=KbName('escape');
Triggerkey = KbName('space'); 
RestrictKeysForKbCheck([Leftkey Rightkey Esckey Triggerkey]);

% Load full stimuli list
load('IrrPanoList.mat', 'IrrPano');
% Load practice
load('IrrPracList.mat', 'IrrPrac');

% Sample 20 stimuli and generate random order for each participant
test_seq = randperm(totalnum, trialnum);

% Load all instructions
load('Instructions.mat', 'Instruction');

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);


try
    AssertOpenGL;
    InitializeMatlabOpenGL; % OpenGL for image rendering
    Screen('Preference', 'SkipSyncTests', 1);

    ListenChar(2);

    % Get the screen numbers
    screens = Screen('Screens');
    screenNumber = max(screens);

    global black white red
    % Define color
    black = [0 0 0];
    white = [256 256 256];
    red = [256 0 0];

    % Open window
    % [w, Rect] = PsychImaging('OpenWindow', screenNumber, black, [0 0 1500 900]); % test
    [w, Rect] = PsychImaging('OpenWindow', screenNumber, black);

    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xc, yc] = RectCenter(Rect);
    [ResX, ResY] = Screen('WindowSize',w);
    [width, height]=Screen('DisplaySize', w); % physical size (mm)
    Screen('TextSize', w, 30);  % Set text size
    global slack
    flipIntv = Screen('GetFlipInterval',w);% flip rate
    slack = flipIntv / 2; % for precise timing

    % Stimuli size parameters
    global fov centeredRect
    fov = 45; % visual angle, degree
    ImgSize = 1080; % pixel
    ImgRect = [0 0 ImgSize ImgSize];
    centeredRect = CenterRectOnPointd(ImgRect, xc, yc);

    % Compass parameters
    global compassRadius compassX compassY pointerLength pointerWidth
    compassRadius = min(ResX, ResY) * 0.05; % Radius
    compassX = ResX * 0.1; 
    compassY = ResY * 0.1; 
    pointerLength = compassRadius * 0.8; 
    pointerWidth = compassRadius * 0.2; 


    % Instruction
    % Make textures in advance
    exp_start = Screen('MakeTexture',w,Instruction.Start);
    exp_prac = Screen('MakeTexture',w,Instruction.Prac);
    exp_test = Screen('MakeTexture',w,Instruction.Test);
    exp_rest = Screen('MakeTexture',w,Instruction.Rest);
    exp_end = Screen('MakeTexture',w,Instruction.End);

    % Start instructions
    esc = ShowInstructionsPress(w, ResX, ResY, exp_start, esc);

    % Practice
    if mod(Seriesnum, 2) == 0
        pracAlign = [-44, 0];
    else
        pracAlign = [0, -44];
    end

    % Prac instructions
    esc = ShowInstructionsPress(w, ResX, ResY, exp_prac, esc);

    % Prac data
    pracPressData = struct('subNum', [], 'panoNum', [], 'sequence', [], 'align', [], 'frameIndex', [], 'keyPressed', [], 'timeStamp', []);
    pracResult(pracnum) = struct('subNum', [], 'panoNum', [], 'sequence', [], 'align', [], 'testFrameIdx', [], 'responseAngle', [], 'RT', [], 'angleDiff', []);

    % Prac loop
    for prac = 1:pracnum
        align = pracAlign(prac);
        [pracPressData, pracResult, esc] = panoPrac_v2(w, xc, yc, prac, align, pracPressData, pracResult, Seriesnum, esc);

        if esc == 1
            break;
        end
    end

    % Exp instruction
    esc = ShowInstructionsPress(w, ResX, ResY, exp_test, esc);

    % Record keyPress during learning
    keyPressData = struct('subNum', [], 'panoNum', [], 'sequence', [], 'align', [], 'frameIndex', [], 'keyPressed', [], 'timeStamp', []);

    % Record test response
    testResult(trialnum) = struct('subNum', [], 'panoNum', [], 'sequence', [], 'align', [], 'testFrameIdx', [], 'responseAngle', [], 'RT', [], 'angleDiff', []);

    % Run exp loop
    for i = 1:trialnum
        if esc == 1
            break;
        end

        % Align
        angleMin = IrrPano(test_seq(i)).halfAngle1;
        angleMax = IrrPano(test_seq(i)).halfAngle2;
        align = randi([angleMin, angleMax]);  % [angleMin, angleMax] randomly selected

        % Preload each frame for 1 pano
        textures = nan(frameNum, 1);
        % Show blank
        Screen('FillRect', w, 0);
        Screen('Flip', w);
        for f = 1:(frameNum / 2)
            imgPath = sprintf('video/p%d_%d.jpg', test_seq(i), mod(align + f - 1, 360) + 1);  
            img = imread(imgPath);
            textures(f) = Screen('MakeTexture', w, img);
        end
        % Show fixation
        fixation(w, xc, yc, fixCrossDimPix, lineWidthPix, white);
        tStart = GetSecs;
        for f = (frameNum / 2 + 1):frameNum
            imgPath = sprintf('video/p%d_%d.jpg', test_seq(i), mod(align + f - 1, 360) + 1);  
            img = imread(imgPath);
            textures(f) = Screen('MakeTexture', w, img);
        end
        tEnd = GetSecs - tStart;

        % Learning phase
        [keyPressData, esc] = panoLearn(w, keyPressData, textures, test_seq(i), align, Seriesnum, i, esc);

        if esc == 1
            break;
        end

        % Show blank
        Screen('FillRect', w, 0);
        Screen('Flip', w);
        WaitSecs(blank);

        % Show fixation
        FixationTime = 0.8 + rand * 0.4; % 0.8-1.2s
        fixation(w, xc, yc, fixCrossDimPix, lineWidthPix, white);
        WaitSecs(FixationTime);

        % Test phase
        [testResult, esc] = panoTest_v2(w, xc, yc, testResult, test_seq(i), align, Seriesnum, i, esc);

        if esc == 1
            break;
        end

        % Rest
        if mod(i, resttrialnum) == 0 && i < trialnum
            esc = ShowInstructionsPress(w, ResX, ResY, exp_rest, esc);

            if esc == 1
                break;
            end
        end
    end



    % Save keyPressData
    % save mat
    save([ResultSavingPath,'/keyPressData_',num2str(Seriesnum),'_',subinfo{2},'_Gender1m2f_',num2str(subinfo{3}),'_Age_',num2str(subinfo{4}),'_',datestr(datetime('now'),30),'.mat'],'keyPressData');
    % save txt
    fileInitial = fullfile(ResultSavingPath,['/keyPressData_',num2str(Seriesnum),'_',subinfo{2},'_Gender1m2f_',num2str(subinfo{3}),'_Age_',num2str(subinfo{4}),'_',datestr(datetime('now'),30),'.txt']);
    writetable(struct2table(keyPressData),fileInitial);

    % Save test response
    % save mat
    save([ResultSavingPath,'/testResult_',num2str(Seriesnum),'_',subinfo{2},'_Gender1m2f_',num2str(subinfo{3}),'_Age_',num2str(subinfo{4}),'_',datestr(datetime('now'),30),'.mat'],'testResult');
    % save txt
    fileInitial = fullfile(ResultSavingPath,['/testResult_',num2str(Seriesnum),'_',subinfo{2},'_Gender1m2f_',num2str(subinfo{3}),'_Age_',num2str(subinfo{4}),'_',datestr(datetime('now'),30),'.txt']);
    writetable(struct2table(testResult),fileInitial);

    % Pre-analysis
    % exclude empty
    angleDiffValues = arrayfun(@(x) x.angleDiff, testResult, 'UniformOutput', false);
    angleDiffValues = cell2mat(angleDiffValues(~cellfun(@isempty, angleDiffValues))); 
    deviation = mean(abs(angleDiffValues));

    % End
    if esc == 0
        ShowInstructionsPress(w, ResX, ResY, exp_end, esc);
    end

    sca;
    ListenChar(0);

catch
    sca;
    Liste  nChar(0);
    psychrethrow(psychlasterror);

end




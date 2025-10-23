% Pano exp
% Pano learning demo, timeLimit of 20s
% Rightkey: CW; Leftkey: CCW
% by Qihao He, March 2025

clear; 
clc; 

% response keys
KbName('UnifyKeyNames');
global Leftkey Rightkey Esckey Triggerkey
Leftkey = KbName('LeftArrow'); 
Rightkey = KbName('RightArrow'); 
Esckey=KbName('escape');
Triggerkey = KbName('space'); 
RestrictKeysForKbCheck([Leftkey Rightkey Esckey Triggerkey]);

esc = 0;

try
    AssertOpenGL;
    InitializeMatlabOpenGL; % OpenGL for image rendering
    Screen('Preference', 'SkipSyncTests', 1);
%     HideCursor;

    ListenChar(2);

    % Get the screen numbers
    screens = Screen('Screens');
    screenNumber = max(screens);

    global white black
    % Define black and white
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);

    % Open window
    [w, Rect] = PsychImaging('OpenWindow', screenNumber, black, [200 200 1050 850]); % test
%     [w, Rect] = PsychImaging('OpenWindow', screenNumber, black);

    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xc, yc] = RectCenter(Rect);
    [ResX, ResY] = Screen('WindowSize',w);
    [width, height]=Screen('DisplaySize', w); % 物理大小mm
    global flipIntv
    flipIntv = Screen('GetFlipInterval',w);% 刷屏时间
    slack = flipIntv / 2; % for precise timing

    frameNum = 480;
    fps = 60;
    duration = frameNum / fps;
    timeStep = 1 / fps;
    timeLimit = 20;

    % Path
    videoPath = [pwd, '/video/pano_test.mp4'];

    % Open movie
    movie = Screen('OpenMovie', w, videoPath);
    Screen('PlayMovie', movie, 0); 

    currTime = 0; % 从第一帧, 0s开始

    % initial time of vertical retraces
    vbl = Screen('Flip', w);

    t0 = GetSecs;
    % KbCheck
    while GetSecs - t0 <= timeLimit
        % Check the key
        [keyIsDown, ~, keyCode] = KbCheck;
        
        if keyIsDown && keyCode(Esckey) 
            break;
        end

        if keyIsDown
            if keyCode(Leftkey) % CCW
                currTime = currTime - timeStep; % 倒退一帧
                if currTime <= 0  % 如果到第一帧，循环到最后一帧
                    currTime = duration - timeStep; % 不能直接到duration, 会索引不到
                end

            elseif keyCode(Rightkey)  % CW
                currTime = currTime + timeStep; % 前进一帧
                if currTime >= duration  % 如果到最后一帧，循环回第一帧
                    currTime = 0;
                end
            end
        end

        % Set time
        Screen('SetMovieTimeIndex', movie, currTime);

        % Get image
        tex = Screen('GetMovieImage', w, movie);
        if tex > 0
            Screen('DrawTexture', w, tex, [], []);
            vbl = Screen('Flip', w, vbl + (1 / fps) - slack); % 控制时间
            Screen('Close', tex);
        end
    end

    % Close
    Screen('CloseMovie', movie);
%     ShowCursor;
    sca;
    ListenChar(0);


catch

    ShowCursor;
    sca;
    ListenChar(0);
    psychrethrow(psychlasterror);

end

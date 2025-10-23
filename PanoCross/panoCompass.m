% Pano exp demo
% Phase1: learning, free exploration, 20s timeLimit, with compass
% Rightkey: CW; Leftkey: CCW
% Phase2: test, record responseAngle & RT (north = 0, east = 90, south = 180, etc)
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

    global white black gray red
    % Define black and white
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    gray = [180 180 180];
    red = [256 0 0];

    % Open window
    [w, Rect] = PsychImaging('OpenWindow', screenNumber, black, [0 0 1200 900]); % test
%     [w, Rect] = PsychImaging('OpenWindow', screenNumber, black);

    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [xc, yc] = RectCenter(Rect);
    [ResX, ResY] = Screen('WindowSize',w);
    [width, height]=Screen('DisplaySize', w); % physical size (mm)
    Screen('TextSize', w, 30);  % Set text size
    global flipIntv
    flipIntv = Screen('GetFlipInterval',w);% flip rate
    slack = flipIntv / 2; % for precise timing

    % Compass
    compassRadius = min(ResX, ResY) * 0.05; % Radius
    compassX = ResX * 0.15; 
    compassY = ResY * 0.15; 
    pointerLength = compassRadius * 0.8; 
    pointerWidth = compassRadius * 0.2; 

    % Movie parameters
    frameNum = 480;
    fps = 30;
    duration = frameNum / fps;
    timeStep = 1 / fps;
    timeLimit = 20;

    % Path
    videoPath = [pwd, '/video/pano_test.mp4'];

    % Open movie
    movie = Screen('OpenMovie', w, videoPath);
    Screen('PlayMovie', movie, 0); 

    currTime = 0; % from 1st frame, 0s (time)

    % initial time of vertical retraces
    vbl = Screen('Flip', w);

    t0 = GetSecs;
    % KbCheck
    while GetSecs - t0 <= timeLimit
        % Check the key
        [keyIsDown, ~, keyCode] = KbCheck;
        
        if keyIsDown && keyCode(Esckey)
            esc = 1;
            break;
        end

        if keyIsDown
            if keyCode(Leftkey) % CCW
                currTime = currTime - timeStep; % backwards 1 frame
                if currTime <= 0  % 1st frame, return to last
                    currTime = duration - timeStep; % avoid blank
                end

            elseif keyCode(Rightkey)  % CW
                currTime = currTime + timeStep; % forward
                if currTime >= duration  % last, return to 1st
                    currTime = 0;
                end
            end
        end

        % Set time
        Screen('SetMovieTimeIndex', movie, currTime);

        % 计算指南针角度
        compassAngle = -currTime / duration * 360; % North

        % Get image
        tex = Screen('GetMovieImage', w, movie);
        if tex > 0
            % Draw movie
            Screen('DrawTexture', w, tex, [], []);

            % Draw compass
            % Oval
            Screen('FillOval', w, gray, ...
                [compassX - compassRadius, compassY - compassRadius, ...
                 compassX + compassRadius, compassY + compassRadius]);
            Screen('FrameOval', w, white, ...
                [compassX - compassRadius, compassY - compassRadius, ...
                 compassX + compassRadius, compassY + compassRadius], compassRadius * 0.07);

            % 计算菱形四个顶点
            % 顶点顺序, [顶点, 左底点, 右底点]
            pointerVerticesRed = [  0, -pointerLength;  % North
                                   -pointerWidth, 0;    % 左底
                                    pointerWidth, 0];   % 右底
            pointerVerticesWhite = [ 0, pointerLength;  % South
                                    -pointerWidth, 0; 
                                     pointerWidth, 0];

            % Rotate
            theta = deg2rad(compassAngle);
            R = [cos(theta), -sin(theta); sin(theta), cos(theta)];

            % 旋转顶点
            rotatedVerticesRed = (R * pointerVerticesRed')';
            rotatedVerticesWhite = (R * pointerVerticesWhite')';

            % 转换坐标
            pointerXRed = rotatedVerticesRed(:,1) + compassX;
            pointerYRed = rotatedVerticesRed(:,2) + compassY;
            pointerXWhite = rotatedVerticesWhite(:,1) + compassX;
            pointerYWhite = rotatedVerticesWhite(:,2) + compassY;

            % Draw compass
            Screen('FillPoly', w, red, [pointerXRed, pointerYRed]); % Red, North
            Screen('FillPoly', w, white, [pointerXWhite, pointerYWhite]); % White, South

            % Flip
            vbl = Screen('Flip', w, vbl + (1 / fps) - slack);
            Screen('Close', tex);
        end
    end

    % Close
    Screen('CloseMovie', movie);

    if esc == 1
        sca;
        ListenChar(0);
        return;
    end

    % Blank
    Screen('FillRect', w, 0);
    Screen('Flip', w);
    WaitSecs(0.5);

    % Show fixation
    FixationTime = 0.8 + rand * 0.4; % 0.8-1.2s
    fixCrossDimPix = 70;
    lineWidthPix = 10;
    fixation(w, xc, yc, fixCrossDimPix, lineWidthPix, white, FixationTime);

    % Test phase: Display scene snapshot
    img = imread([pwd, '/scene/scene_test.jpg']);
    tex = Screen('MakeTexture', w, img);
    Screen('DrawTexture', w, tex);
    vbl = Screen('Flip', w);
    Screen('Flip', w, vbl + 1.5 - slack);
    Screen('Close', tex);
    
    % Circular response interface
    circleRadius = 250; % 大圆半径
    innerRadius = 200;  % 小圆半径（形成圆环）
    circleRectOuter = [xc - circleRadius, yc - circleRadius, xc + circleRadius, yc + circleRadius];
    circleRectInner = [xc - innerRadius, yc - innerRadius, xc + innerRadius, yc + innerRadius];
    
    responseAngle = NaN;
    confirmed = 0;
    
    tStart = GetSecs;
    while confirmed == 0
        % 画大圆和小圆（圆环）
        Screen('FillOval', w, white, circleRectOuter);  % 大白色圆
        Screen('FillOval', w, black, circleRectInner);  % 小黑色圆
    
        % 画直角坐标系箭头
        arrowLength = 300; % 箭头长度
        arrowThickness = 8; % 箭头粗细
        arrowColor = white;

        % 显示被试的选择（如果已经点击）
        if ~isnan(responseAngle)
            % 画红色扇形（从圆环中截取）
            Screen('FillArc', w, red, circleRectOuter, responseAngle - 45, 90);  % 外圆的红色扇形
            Screen('FillArc', w, black, circleRectInner, responseAngle - 45, 90);  % 内圆的黑色扇形（遮挡部分）
    
            % 计算点击点坐标（扇形中心）
            clickX = xc + cosd(responseAngle) * circleRadius;
            clickY = yc - sind(responseAngle) * circleRadius; % Y轴反转
        end
    
        % 上箭头 (北)
        Screen('DrawLine', w, arrowColor, xc, yc - arrowLength, xc, yc + arrowThickness, arrowThickness);
        DrawFormattedText(w, 'N', xc, yc - arrowLength - 30, white);
    
        % 下箭头 (南)
        Screen('DrawLine', w, arrowColor, xc, yc + arrowLength, xc, yc - arrowThickness, arrowThickness);
        DrawFormattedText(w, 'S', xc, yc + arrowLength + 30, white);
    
        % 左箭头 (西)
        Screen('DrawLine', w, arrowColor, xc - arrowLength, yc, xc + arrowThickness, yc, arrowThickness);
        DrawFormattedText(w, 'W', xc - arrowLength - 30, yc, white);
    
        % 右箭头 (东)
        Screen('DrawLine', w, arrowColor, xc + arrowLength, yc, xc - arrowThickness, yc, arrowThickness);
        DrawFormattedText(w, 'E', xc + arrowLength + 30, yc, white);
      
        Screen('Flip', w);
    
        % Get mouse
        [mouseX, mouseY, buttons] = GetMouse;
    
        if any(buttons)  % 如果鼠标点击
            dx = mouseX - xc;
            dy = yc - mouseY;
            distanceSq = dx^2 + dy^2; % compute squeared distance
    
            % Limit click range
            if distanceSq >= innerRadius^2 && distanceSq <= circleRadius^2
                % 计算角度，0°对应北方，顺时针增加
                responseAngle = mod(atan2d(dy, dx), 360); % dy, dx 计算相对于X轴的角度
    
                % 这将使0°对应屏幕上方（正北），顺时针递增
                responseAngle = mod(90 - responseAngle, 360); % 90°是正北方
            end
        end
    
        % 检测空格键以确认选择
        [keyIsDown, ~, keyCode] = KbCheck;

        if keyIsDown && keyCode(Esckey)
            break;
        end

        if keyIsDown && keyCode(Triggerkey)
            RT = GetSecs - tStart;
            confirmed = 1;
        end
    end


%     ShowCursor;
    sca;
    ListenChar(0);


catch
%     ShowCursor;
    sca;
    ListenChar(0);
    psychrethrow(psychlasterror);

end

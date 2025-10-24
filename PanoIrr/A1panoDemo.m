% Pano exp demo
% Phase1: learning, free exploration, 30s timeLimit, with compass
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
    frameNum = 360;
    fps = 30;
    duration = frameNum / fps;
    % timeStep = 1 / fps;
    timeLimit = 30;

    % Center the rectangle on the centre of the screen using fractional pixel
    global centeredRect
    ImgSize = 800;
    ImgRect = [0 0 ImgSize ImgSize];
    centeredRect = CenterRectOnPointd(ImgRect, xc, yc);

    % Show fixation
    FixationTime = 0.8 + rand * 0.4; % 0.8-1.2s
    fixCrossDimPix = 70;
    lineWidthPix = 10;
    fixation(w, xc, yc, fixCrossDimPix, lineWidthPix, white);

    % % Path
    % videoPath = [pwd, '/video/pano_test.mp4'];
    % 
    % % Open movie
    % movie = Screen('OpenMovie', w, videoPath);
    % Screen('PlayMovie', movie, 1); 
    % 
    % % Preload each frame
    % textures = nan(frameNum, 1); 
    % for f = 1:frameNum
    %     tex = Screen('GetMovieImage', w, movie);
    %     if tex > 0
    %         textures(f) = tex;
    %     end
    % end
    % Screen('CloseMovie', movie); 

    tStart = GetSecs;
    % Preload each frame
    textures = nan(frameNum, 1);
    for f = 1:frameNum
        imgPath = sprintf('video/p1_%d.jpg', f);
        img = imread(imgPath);
        textures(f) = Screen('MakeTexture', w, img);
    end
    tEnd = GetSecs - tStart;

    % Record keyPress during learning
    responseData = struct('frameIndex', [], 'keyPressed', [], 'timeStamp', []);

    % Initialize
    vbl = Screen('Flip', w);  % time of vertical retraces
    currFrame = 1; 
    compass = 1; % KeyIsDown, turn to 0
    t0 = GetSecs;

    % KbCheck
    while GetSecs - t0 <= timeLimit
        % Check the key
        [keyIsDown, secs, keyCode] = KbCheck;
        
        if keyIsDown && keyCode(Esckey)
            esc = 1;
            break;
        end

        if keyIsDown
            compass = 0;
            if keyCode(Leftkey)  % CCW
                currFrame = mod(currFrame - 2, frameNum) + 1; 
                responseData(end+1) = struct('frameIndex', currFrame, 'keyPressed', 'Left', 'timeStamp', secs - t0);
            
            elseif keyCode(Rightkey)  % CW
                currFrame = mod(currFrame, frameNum) + 1; 
                responseData(end+1) = struct('frameIndex', currFrame, 'keyPressed', 'Right', 'timeStamp', secs - t0);
            end
        end

        % Compass angle
        compassAngle = 0; % North


        % Draw movie
        Screen('DrawTexture', w, textures(currFrame), [], centeredRect);

        % Draw compass
        if compass == 1
            % Oval
            Screen('FillOval', w, gray, ...
                [compassX - compassRadius, compassY - compassRadius, ...
                 compassX + compassRadius, compassY + compassRadius]);
            Screen('FrameOval', w, white, ...
                [compassX - compassRadius, compassY - compassRadius, ...
                 compassX + compassRadius, compassY + compassRadius], compassRadius * 0.07);

            % Compass pointer
            pointerVerticesRed = [  0, -pointerLength;  
                                   -pointerWidth, 0;    
                                    pointerWidth, 0];   
            pointerVerticesWhite = [ 0, pointerLength;  
                                    -pointerWidth, 0; 
                                     pointerWidth, 0];
    
            pointerXRed = pointerVerticesRed(:,1) + compassX;
            pointerYRed = pointerVerticesRed(:,2) + compassY;
            pointerXWhite = pointerVerticesWhite(:,1) + compassX;
            pointerYWhite = pointerVerticesWhite(:,2) + compassY;
    
            Screen('FillPoly', w, red, [pointerXRed, pointerYRed]); % N
            Screen('FillPoly', w, white, [pointerXWhite, pointerYWhite]); % S
        end

        % Flip
        vbl = Screen('Flip', w, vbl + (1 / fps) - slack);

    end

    if esc == 1
        sca;
        ListenChar(0);
        return;
    end

    % Close textures
    for f = 1:frameNum
        if textures(f) > 0
            Screen('Close', textures(f));
        end
    end

    % Blank
    Screen('FillRect', w, 0);
    Screen('Flip', w);
    WaitSecs(0.5);

    % Show fixation
    FixationTime = 0.8 + rand * 0.4; % 0.8-1.2s
    % fixCrossDimPix = 70;
    % lineWidthPix = 10;
    fixation(w, xc, yc, fixCrossDimPix, lineWidthPix, white);
    WaitSecs(FixationTime);

    % Test phase: Display scene snapshot
    f = randi([45,315]);  % exclude overlap
    imgPath = sprintf('video/p1_%d.jpg', f);
    img = imread(imgPath);
    tex = Screen('MakeTexture', w, img);
    Screen('DrawTexture', w, tex, [], centeredRect);
    vbl = Screen('Flip', w);
    Screen('Flip', w, vbl + 2 - slack);
    Screen('Close', tex);
    
    % Circular response interface
    circleRadius = 250; % Big
    innerRadius = 200;  % Small
    circleRectOuter = [xc - circleRadius, yc - circleRadius, xc + circleRadius, yc + circleRadius];
    circleRectInner = [xc - innerRadius, yc - innerRadius, xc + innerRadius, yc + innerRadius];
    
    responseAngle = NaN;
    confirmed = 0;
    
    tStart = GetSecs;
    while confirmed == 0
        % Draw circle
        Screen('FillOval', w, white, circleRectOuter);  
        Screen('FillOval', w, black, circleRectInner);  
    
        % Draw axis
        arrowLength = 300; 
        arrowThickness = 8; 
        arrowColor = white;

        % Show the red range
        if ~isnan(responseAngle)
            % Red range
            Screen('FillArc', w, red, circleRectOuter, responseAngle - 22.5, 45);  
            Screen('FillArc', w, black, circleRectInner, responseAngle - 22.5, 45);  
    
            % Compute click coord
            clickX = xc + cosd(responseAngle) * circleRadius;
            clickY = yc - sind(responseAngle) * circleRadius; 
        end
    
        % Arrow N
        Screen('DrawLine', w, arrowColor, xc, yc - arrowLength, xc, yc + arrowThickness, arrowThickness);
        DrawFormattedText(w, 'N', xc, yc - arrowLength - 30, white);
    
        % S
        Screen('DrawLine', w, arrowColor, xc, yc + arrowLength, xc, yc - arrowThickness, arrowThickness);
        DrawFormattedText(w, 'S', xc, yc + arrowLength + 30, white);
    
        % W
        Screen('DrawLine', w, arrowColor, xc - arrowLength, yc, xc + arrowThickness, yc, arrowThickness);
        DrawFormattedText(w, 'W', xc - arrowLength - 30, yc, white);
    
        % E
        Screen('DrawLine', w, arrowColor, xc + arrowLength, yc, xc - arrowThickness, yc, arrowThickness);
        DrawFormattedText(w, 'E', xc + arrowLength + 30, yc, white);
      
        Screen('Flip', w);
    
        % Get mouse
        [mouseX, mouseY, buttons] = GetMouse;
    
        if any(buttons)  % Click
            dx = mouseX - xc;
            dy = yc - mouseY;
            distanceSq = dx^2 + dy^2; % compute squeared distance
    
            % Limit click range
            if distanceSq >= innerRadius^2 && distanceSq <= circleRadius^2
                % N = 0, CW increase
                responseAngle = mod(atan2d(dy, dx), 360); % dy, dx angle for X axis
                % Rotate
                responseAngle = mod(90 - responseAngle, 360); 
            end
        end
    
        % Check key
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(Esckey)
            break;
        end

        if keyIsDown && keyCode(Triggerkey)
            RT = GetSecs - tStart;
            confirmed = 1;
        end
    end


    sca;
    ListenChar(0);


catch
    sca;
    ListenChar(0);
    psychrethrow(psychlasterror);

end

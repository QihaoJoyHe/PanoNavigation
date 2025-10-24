% Pano test phase
% by Qihao He, April 2025

function [testResult, esc] = panoTest(w, xc, yc, testResult, panoNum, align, Seriesnum, i, esc)

global trialnum snapshot feedback Triggerkey Esckey slack fov centeredRect black white red compassRadius compassX compassY pointerLength pointerWidth

% Test phase: Display scene snapshot
% exclude overlap
testFrameIdx = randi([46,315]);  
imgPath = sprintf('video/p%d_%d.jpg', panoNum, mod((testFrameIdx + align - 1), 360) + 1);
img = imread(imgPath);
tex = Screen('MakeTexture', w, img);
Screen('DrawTexture', w, tex, [], centeredRect);
vbl = Screen('Flip', w);
Screen('Flip', w, vbl + snapshot - slack);
Screen('Close', tex);

% Circular response interface
circleRadius = 250; % Big
innerRadius = 200;  % Small
circleRectOuter = [xc - circleRadius, yc - circleRadius, xc + circleRadius, yc + circleRadius];
circleRectInner = [xc - innerRadius, yc - innerRadius, xc + innerRadius, yc + innerRadius];

responseAngle = NaN;
button = 0;
confirmed = 0;

tStart = GetSecs;
while confirmed == 0
    % Draw circle
    Screen('FillOval', w, white, circleRectOuter);  
    Screen('FillOval', w, black, circleRectInner);  

    % Show the red range
    if ~isnan(responseAngle)
        % Red range
        Screen('FillArc', w, red, circleRectOuter, responseAngle - fov/2, fov);  
        Screen('FillArc', w, black, circleRectInner, responseAngle - fov/2, fov);  
    end

    % Draw compass
    % Oval
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
  
    Screen('Flip', w);

    % Get mouse
    [mouseX, mouseY, buttons] = GetMouse;

    if any(buttons)  % Click
        dx = mouseX - xc;
        dy = yc - mouseY;
        distanceSq = dx^2 + dy^2; % compute squeared distance
        button = 1;

        % Limit click range
        if distanceSq >= innerRadius^2 && distanceSq <= circleRadius^2
            % N = 0, CW increase
            responseAngle = mod(atan2d(dy, dx), 360); % dy, dx angle for X axis
            % Rotate
            responseAngle = mod(90 - responseAngle, 360); 
        end
    end

    if button == 1
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
end

% Record results
angleDiff = responseAngle - testFrameIdx + 1;
if angleDiff > 180
    angleDiff = angleDiff - 360;
elseif angleDiff <= -180
    angleDiff = angleDiff + 360;
end
testResult(i) = struct('subNum', Seriesnum, 'panoNum', panoNum, 'sequence', i, 'align', align, 'testFrameIdx', testFrameIdx, 'responseAngle', responseAngle, 'RT', RT, 'angleDiff', angleDiff);

% Feedback angleDiff
Screen('FillRect', w, 0);
DrawFormattedText(w, ['Difference: ', num2str(angleDiff)], 'center', yc-40, white); 
if i < trialnum
    DrawFormattedText(w, ['Next trial: ', num2str(i + 1)], 'center', yc + 40, white); % next block
end
Screen('Flip', w);
WaitSecs(feedback);

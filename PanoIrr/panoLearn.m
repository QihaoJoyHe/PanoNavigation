% Pano learning phase
% 
% panoNum = test_seq(i)
% by Qihao He, March 2025

function [keyPressData, esc] = panoLearn(w, keyPressData, textures, panoNum, align, Seriesnum, i, esc)

global timeLimit frameNum fps Leftkey Rightkey Esckey slack centeredRect white red compassRadius compassX compassY pointerLength pointerWidth

% Initialize
vbl = Screen('Flip', w);  % time of vertical retraces
currFrame = 1; 
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
        if keyCode(Leftkey)  % CCW
            currFrame = mod(currFrame - 2, frameNum) + 1; 
            keyPressData(end+1) = struct('subNum', Seriesnum, 'panoNum', panoNum, 'sequence', i, 'align', align, 'frameIndex', currFrame, 'keyPressed', 'Left', 'timeStamp', secs - t0);
        
        elseif keyCode(Rightkey)  % CW
            currFrame = mod(currFrame, frameNum) + 1; 
            keyPressData(end+1) = struct('subNum', Seriesnum, 'panoNum', panoNum, 'sequence', i, 'align', align, 'frameIndex', currFrame, 'keyPressed', 'Right', 'timeStamp', secs - t0);
        end
    end

    % Draw movie
    Screen('DrawTexture', w, textures(currFrame), [], centeredRect);

    % Draw compass
    compassAngle = 360 - currFrame + 1;

    if currFrame >= 316 || currFrame <= 45
        % Oval
        Screen('FrameOval', w, white, ...
            [compassX - compassRadius, compassY - compassRadius, ...
             compassX + compassRadius, compassY + compassRadius], compassRadius * 0.07);

        % Compass pointer
        pointerVerticesRed = [ 0, -pointerLength;  
                               -pointerWidth, 0;    
                                pointerWidth, 0];   
        pointerVerticesWhite = [ 0, pointerLength;  
                                -pointerWidth, 0; 
                                 pointerWidth, 0];

        % Rotate
        theta = deg2rad(compassAngle);
        R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
        rotatedVerticesRed = (R * pointerVerticesRed')';
        rotatedVerticesWhite = (R * pointerVerticesWhite')';

        pointerXRed = rotatedVerticesRed(:,1) + compassX;
        pointerYRed = rotatedVerticesRed(:,2) + compassY;
        pointerXWhite = rotatedVerticesWhite(:,1) + compassX;
        pointerYWhite = rotatedVerticesWhite(:,2) + compassY;

        Screen('FillPoly', w, red, [pointerXRed, pointerYRed]); % N
        Screen('FillPoly', w, white, [pointerXWhite, pointerYWhite]); % S
    end

    % Flip
    vbl = Screen('Flip', w, vbl + (1 / fps) - slack);

end


% Close textures
for f = 1:frameNum
    if textures(f) > 0
        Screen('Close', textures(f));
    end
end


function vDist = computeViewingDistance(screenHeight, screenResHeight, ImgSize, theta)
    pixelSize = screenHeight / screenResHeight;
    ImgPhysicalSize = ImgSize * pixelSize;
    
    % Compute viewing distance (cm)
    vDist = (ImgPhysicalSize / 2) / tand(theta / 2);
end
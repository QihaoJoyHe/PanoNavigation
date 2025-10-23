function fixation(w, xc, yc, len, width, color)
    Screen('FillRect',w,color,CenterRectOnPointd([0,0,len,width],xc,yc));
    Screen('FillRect',w,color,CenterRectOnPointd([0,0,width,len],xc,yc));
    Screen('Flip', w);
end
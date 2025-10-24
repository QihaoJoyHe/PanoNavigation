function esc = ShowInstructionsPress(w, ResX, ResY, Instructions, esc)

global Triggerkey Esckey

baseRect = [0, 0, ResX, ResY];

while true
    Screen('DrawTexture', w, Instructions,[],baseRect);
    Screen('Flip',w);

    [keyisdown, ~, keycode] = KbCheck;
    if keyisdown && keycode(Esckey)
        esc = 1;
        break
    elseif keyisdown && keycode(Triggerkey)
        break
    end
end
KbReleaseWait;

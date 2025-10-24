function subinfo = getSubInfo()
% Demography Information Collection

prompt = {'Seriesnum','FullName','Gender[1 = m, 2 = f]','Age','Handeness[1 = left, 2 = right]'};
title = 'Demography information'; % The title of the dialog box
definput = {'9999','QHHe','2','20','2'}; % Default input value(s)
subinfo = inputdlg(prompt, title, [1, 50], definput);
end
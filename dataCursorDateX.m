function dataCursorDateX(hFig)
% Set the data cursor to show the date
dcm_obj = datacursormode(hFig);
set(dcm_obj,'enable','on')
set(dcm_obj,'UpdateFcn',{@datestrDataCursorCallback})
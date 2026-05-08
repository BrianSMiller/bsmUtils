function fullFileName = saveAsEps(figureHandle, filename)
% pngFile = saveAsPng(figureHandle, filename)
% Save a figure as a png file, trimming the whitespace from the border
% NB: trimming whitespace requires the program ImageMagick installed on the
% matlab path.

% If only 1 input argument, assume it is a file name and use current figure
if nargin < 2 
    filename = figureHandle;
    figureHandle = gcf;
end
[filePath, fileName, ~] = fileparts(filename);
if (isempty(filePath))
    filePath = pwd;
end

fullFileName = [filePath filesep fileName '.eps'];
exportgraphics(figureHandle,fullFileName, ...
    'BackgroundColor','none','ContentType','vector')
% print(figureHandle, fullFileName,'-depsc','-loose','-noui');
% eval(['!magick convert "' fullFileName '" -trim "' fullFileName '"']);

end


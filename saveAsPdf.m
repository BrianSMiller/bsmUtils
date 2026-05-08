function fullFileName = saveAsPng(figureHandle, filename)
% pngFile = saveAsPng(figureHandle, filename)
% Save a figure as a png file, trimming the whitespace from the border
% NB: trimming whitespace requires the program ImageMagick installed on the
% matlab path.

% If only 1 input argument, assume it is a file name and use current figure
if nargin < 2 
    filename = figureHandle;
    figureHandle = gcf;
end
[filePath fileName ext] = fileparts(filename);
if (isempty(filePath))
    filePath = pwd;
end

% Set paper size to figure extents, rather than default A4
pos = get(figureHandle,'position');
set(figureHandle,'PaperSize',[pos(3) pos(4)]);

fullFileName = [filePath filesep fileName '.pdf'];
print(figureHandle, fullFileName,'-dpdf','-r300','-noui');
% eval(['!convert "' fullFileName '" -trim "' fullFileName '"']);
end


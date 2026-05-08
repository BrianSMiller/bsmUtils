function animateSpectrogram(saveFile, wavFile, win, noverlap, nfft, ...
    timeRange, freqRange, powerRange, powerAdjust, subtitleFile)
% animateSpectrogram(saveFile,wavFile,win,noverlap,nfft,timeRange,freqRange)
% Create a scrolling spectrogram and save as a video file. 
% Requires ffmpeg in the windows path in order to merge audio with animation.
% saveFile is the full path and name of the video file
% wavFile contains the audio data used to generate the spectrogram
% win, noverlap, nfft - see documentation in spectrogram.m
% timeRange - the extents (in seconds) of the time axis of the spectrogram
% freqRange - the extents (in Hz) of the frequency axis of the spectrogram
addpath('c:\analysis\colormaps\Colormaps-from-MatPlotLib2.0\');
addpath('c:\analysis\colormaps\BrewerMap\');
if isempty(saveFile);
    saveFile = 'aniSpec.avi';
end
% [w fs] = wavread(wavFile);
[w fs] = audioread(wavFile);
if nargin < 3
    win = fs; % Spectrogram window size in samples
end
if nargin < 4
    noverlap = floor(win*(1-1/32)); % Overlapping samples between spectrogram slices
end
if nargin < 5
    nfft = win;    % Number of samples in a spectrogram slice
end
if nargin < 6
    timeRange = [-30 30];
end
if nargin < 7
    freqRange = [0 24000];
end
if nargin < 8
    powerRange = 140;
end
if nargin < 9
    powerAdjust = [0 0];
end
if nargin < 10
    subtitleFile = '';
else
    subtitleFile = ['-vf subtitles="' subtitleFile '"'];
end
duration = length(w)/fs;
w = w-mean(w); % remove DC offset
[S F T] = spectrogram(w,win,noverlap,nfft,fs);
P = 20*log10(abs(S).^2);
imagesc(T,F/1e3,P);
set(gca,'ydir','normal');

c = caxis;
c = [c(2)-powerRange c(2)];
c = c + powerAdjust;
caxis(c);

% cmap = [vivid([0 0.8],'c'); 0 1 0; 1 1 1;];
% cmap = vivid([0 0.8],'c');
% cmap = fire(128);
% cmap = viridis;
% cmap = jet(128);
% cmap = flipud(brewermap(128,'spectral'));
% cmap = crameri('batlow');
% cmap = flipud(brewermap(128,'PuBuGn'));
cmap = plasma(256);
colormap(cmap);
[foo ix] = min(abs(T-diff(timeRange)));
xMax = ix;
yMax = diff(freqRange);
yMax = 1080;
aspectRatio = 16/9;
% aspectRatio = 4/3;
set(gcf,'position',[100 100 yMax*aspectRatio yMax],'color','k','renderer','zbuffer');
set(gca,'position',[0.00 0.00 1 1],'units','pixels');
get(gca,'position');
ylim(freqRange/1e3);
xlim(timeRange);
% h = vertline(mean(xlim),'w');
grid off;
frameRate = 30;
frameTimes = 0:(1/frameRate):duration;
% frameRate = length(T)/duration
set(gca,'color','k','tickdir','in','xcolor','w','ycolor','w',...
    'xTick',[])
set(gcf,'inverthardcopy','off','paperpositionmode','auto');
% print('-dpng','-r0',[saveFile '.png']);
ylabel('Frequency (kHz)');
xlabel('Time (s)');
%%
colIndex = [0 1 0; cmap];
annotation('line',[0.5 0.5],[0 1],'color','w');

% hold on;
% plotBox([1.8 5],[0.15 2.8],'r','faceColor','none','lineWidth',3);
% text(2,3.2,sprintf('Crabeater seal\nlow moan'),'fontSize',20,...
%     'color',[0.9 0.1 0.1], 'fontWeight','bold');
% 
% plotBox([10 14],[0.7 3],'r','faceColor','none','lineWidth',3);
% text(10,3.5,sprintf('Crabeater seal\nhigh moan'),'fontSize',20,...
%     'color',[0.9 0.1 0.1], 'fontWeight','bold');
try
    mov = VideoWriter('temp.mp4','mpeg-4');
    mov.set('FrameRate',frameRate,'Quality',100);
%     mov = VideoWriter('temp.mj2','Archival');
%     mov = VideoWriter('temp.avi','Uncompressed AVI');
%     mov.set('FrameRate',frameRate,'Quality',100);
    open(mov);
%     mov = avifile('temp.avi','fps',frameRate,'keyframe',2,'colormap',colIndex,'quality',100,'compression','none');
    count = 0;
    for i = frameTimes;
        xlim(i+timeRange);
%         delete(h);
%         h = vertline(mean(xlim),'w');
        drawnow;
        F = getframe(gca);
%         mov = addframe(mov,F);
        writeVideo(mov,F);
    end
catch
    lasterr
    close(mov);

    return;
end
close(mov);
cmd = ['!ffmpeg -i temp.mp4 -i "' wavFile '" ' subtitleFile ' -ar 44100 "' saveFile '"'];
% cmd = ['!ffmpeg -i temp.mp4 -i "' wavFile '" ' subtitleFile ' -ar 44100 -vcodec libx265 "' saveFile '"'];
% cmd = ['!ffmpeg -i temp.mj2 -i "' wavFile '" ' subtitleFile ' -ar 48000 "' saveFile '"'];
% cmd = ['!ffmpeg -i temp.avi -i "' wavFile '" ' subtitleFile ' -ar 48000 -vcodec libx264 -preset slow "' saveFile '"'];
eval(cmd);

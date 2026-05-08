% Simulate a sperm whale click and estimate cepstrum

% Recording parameters
% sampleRate = 48000; % Hz;
tNow = datestr(now,'yyyymmdd_HHMMSS');
for sampleRate = [48e3, 96e3]
    signalLength = 0.25;% total duration of 1 signal including click
    numClicks = 40;    % total number of signals
    clickNoiseRatio= 10; % Amplitude of click relative to noise
    timeLims = [1 20];  % time limits for plotting (ms)

    % Parameters for simulated click
    clickStartTime = 0.001; % seconds in signal click begins
    clickAmplitude = 0.5;  % between [-1,1]
    clickDuration = 0.0002; % s
    clickFreq = 8e3;       % centre frequency

    % IPI parameters
%     ipi = 0.006; % 6 ms IPI
    for ipi = 6e-3: 0.2e-3 :7e-3
        echoLevel = 0.25;

        [click, tc] = ricker(clickFreq, clickDuration, 1/sampleRate);
        clicks = repmat(clickAmplitude * click',1,numClicks);
        nClickSamp = length(click);

        % Simulate some white noise;
        noiseLevel = clickAmplitude/clickNoiseRatio;
        x = (-noiseLevel/2)+(noiseLevel)*rand(signalLength*sampleRate,numClicks);

        % Normally distributed click amplitudes between 0.05 and 1;
        % clickAmplitdue = noiseLevel*2+(1-noiseLevel*2)*rand(1,numClicks);
        t = (0:(length(x)-1))/sampleRate;

        clickStartSample = round(clickStartTime*sampleRate);
        clickIx = clickStartSample:(clickStartSample+nClickSamp-1);
        x(clickIx,:) = clicks + x(clickIx,:);

        % Sample number of first and second echo
        ipiSample1 = clickStartSample + round(ipi * sampleRate);
        ipiIx1 = ipiSample1:(ipiSample1+nClickSamp-1);
        x(ipiIx1,:) = echoLevel .* clicks + x(ipiIx1,:);

        ipiSample2 = clickStartSample + round(2 * ipi * sampleRate);
        ipiIx2 = ipiSample2:(ipiSample2+nClickSamp-1);
        x(ipiIx2,:) = echoLevel.^2 .* clicks + x(ipiIx2,:);

        [c, q] = cepstrum(x,sampleRate);
        cep = mean(c,2);

        tl = tiledlayout('flow');
        nexttile();
        plot(t*1e3,x)
        xlabel('Time (ms)');
        ylabel('Amplitude');
        xlim(timeLims);

        nexttile();
        imagesc(numClicks,t*1e3,10*log10(x.^2));
        xlabel("Click number");
        ylabel('Time (ms)')
        ylim(timeLims);


        nexttile();
        plot(q*1e3,cep)
        xlim(timeLims);
        % legend('1+waveform','Cepstrum');
        hold off;

        nexttile()
        imagesc(1:numClicks,q*1e3,20*log10(c))
        ylim(timeLims);

        saveFile = sprintf('%s_test_sampRate%2gkHz_numClicks%2g_IPI%01.2fms_SNR%2gdB.wav', ...
            tNow, ...
            sampleRate/1e3, ...
            numClicks, ...
            ipi*1e3, ...
            clickNoiseRatio);
        audiowrite(saveFile,x(:),sampleRate)
    end
end
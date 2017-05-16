function [] = SARProcessing(matFile)
% function [] = SARProcessing(matFile)
% 
% Produces a synthetic aperture image of the cantenna
% recording. This processing assumes the data was 
% collected by switching the radar on/off at several
% positions. See inside the function for more
% parameters.
%
%    matFile = the filename of the .MAT file to process
%
% MIT PEP 2016 Laptop Radar Course
% (c) 2016 Massachusetts Institute of Technology

% the following line avoids a stylistic warning from Matlab
%#ok<*UNRCH>

% ---- setup constants and parameters ----
c = 299e6; % (m/s) speed of light
Tp = 20e-3; % (s) pulse length
delta_x = -1*(1/12)*0.3048; % (m) 1 inch antenna spacing
numPad = 64; % number of samples to pad for bandlimited interpolation & shifting
ovsFac = 16; % oversampling factor applied when interpolating the trigger signal
ovsRng = 2; % oversampling factor applied when interpolating the range data
sceneSizeX = 140; % (m) scene extent in x-dimension (cross-range)
fStart = 2400e6; % (Hz) LFM start frequency
fStop = 2480e6; % (Hz) LFM stop frequency
fc = mean([fStart fStop]);
nPulseCancel = 2; % number of pulses to use for canceller 
maxRange = 100; % (m) maximum range to display
angleLimit_deg = 45; % angular limit of the SAR image to form (each side)
useSpatialTaper = false; % use a "spatial taper" to reduce angle sidelobes?
% ----- end constants and parameters -----

fprintf('Using %g MHz bandwidth\n', (fStop-fStart)*1e-6);
fprintf('Loading *.mat file...\n');

if ~exist('matFile','var')
    matFile = 'SAR_example.mat';
end

% load data
a = load(matFile);
s = a.data;
Fs = 48000;

% derived parameters
Np = round(Tp * Fs); % # of samples per pulse
BW = fStop - fStart; % (Hz) transmit bandwidth
delta_r = c/(2*BW); % (m) range resolution
imgX = linspace(-sceneSizeX/2,sceneSizeX/2,641).'; % (m) image pixels in x-dim
sceneSizeY = sceneSizeX * 3/4; % so the result looks good on a 640 x 480 grid
imgY = linspace(0,sceneSizeY,481).'; % (m) image pixels in y-dim

% parse data
% parseData is sample x pulse, where each pulse is the average of all
% pulses taken at a single position in the synthetic aperture
fprintf('Parsing the recording...\n');  
[parseData,numPulses]=parse_matFile(s,Np);

% compute aperture, range, & cross-range dimensions
Xa = ((1:(numPulses-1)).' - (numPulses-2)/2) * delta_x; % (m) cross range position of radar on aperture L
Ya = 0*Xa; % (m) range position of radar, assumes aperture is along a straight line
Za = 0*Xa; % (m) altitude position of radar, assumes aperture is at 0 m elevation relative to the scene

% make figure for output display
hFig = figure;
hAx = axes;
myImg = zeros(numel(imgY),numel(imgX));
hImg = imagesc(imgX,imgY,nan*myImg,'Parent',hAx);
colormap(hAx,jet(256));
colorbar;
xlabel('X (meters)');
ylabel('Y (meters)');
set(hAx,'YDir','normal');

% pre-compute some windows and other vectors 
dataRange = (0:ovsFac*Np-1).' * (delta_r/ovsFac); % ranges of each bin (m)
rangeScale = dataRange.^(3/2); % scale factor applied to the data as a fn of range
rngWin = hann_window(Np); % the window applied to reduce range sidelobes
slowWin = ones(numPulses-1,1); % the window applied to the slow-time (cross-range) data
if useSpatialTaper
    slowWin = hann_window(numBreaks-1); % user requested a hann window
end
carrierPhase = exp( -1j * (4*pi*fc/c * delta_r) * (0:Np-1).' ); % the (residual) carrier phase of each range bin
if angleLimit_deg < 90
    for xIdx = 1:numel(imgX)
        % determine which pixels are outside the angle limit of the image
        clipPixels = (abs(imgY) < abs(imgX(xIdx)*tan(pi/2 - angleLimit_deg*(pi/180))));
        % set these out-of-bounds pixels to "unknown"
        myImg(clipPixels,xIdx) = nan;
    end
end

% Form SAR image
for i = 1:numPulses-1
    
    % get pulse data
    tmpRP = parseData(:,i);

    % compute the range profile from the mixer output
    tmpRP = ifft(tmpRP .* (rngWin*slowWin(i))); % apply fast & slow-time windows, then ifft
    tmpRP = fft_interp(tmpRP .* carrierPhase, ovsFac) .* rangeScale; % baseband (remove carrier phase), interpolate up, and scale signal vs range
    
    % compute the first difference in range (used for linear interpolation)
    diffRP = diff([tmpRP; 0],1);
    
    % incorporate this position into the image via backprojection
    for xIdx = 1:numel(imgX)
        % compute the range to each image pixel & the matched filter terms
        rangeVec = sqrt(((imgX(xIdx) - Xa(i))^2 + Za(i)^2) + (imgY - Ya(i)).^2);
        matchVec = exp( 1j * (4*pi*fc/c) * rangeVec );
        
        % compute integer and fractional range indices to each image pixel (for linear interpolation)
        rangeInds = rangeVec * (ovsFac / delta_r) + 1;
        rangeLo = floor(rangeInds);
        rangeFrac = rangeInds - rangeLo;
        
        % perform linear interpolation and apply the matched filter terms
        %    (this is just the backprojection integral)
        myImg(:,xIdx) = myImg(:,xIdx) + (tmpRP(rangeLo) + diffRP(rangeLo).*rangeFrac) .* matchVec;
    end
    
    % update the user display 
    img_dB = 20*log10(abs(myImg));
    set(hImg,'CData',img_dB);
    set(hFig,'Name',sprintf('%6.2f%% complete',100*i/(numPulses-1)));
    caxis(hAx,max(img_dB(:)) + [-40 0]);
    drawnow;
end

function [w] = hann_window(N)
% create a hann (cosine squared) window
w = .5 + .5*cos(2*pi*((1:N).'/(N+1) - .5));

% Parses the digital data by looking for "start of pulse" and "end of
% pulse" flags.  Converts the digital data to voltages.
function [parseData,numPulses] = parse_matFile(x,Np)
flag_pulseStart=5000;
scale_factor=3.3/2^12;
numPulses=sum(x(:)==flag_pulseStart);
startInds = find(x==flag_pulseStart); % Indices of pulse starts in x
pCtr = 1;
gCtr = 1;
for i = 1:length(startInds)-1
    pulsesInGroup(:,pCtr) = x(startInds(i)+1:startInds(i)+Np).';
    if(startInds(i+1)-startInds(i)>2000)
        parseData(:,gCtr) = mean(pulsesInGroup,2);
        gCtr = gCtr + 1;
        pCtr = 1;
        clear pulsesInGroup;
    end
    pCtr = pCtr + 1;
end
numPulses = size(parseData,2);
parseData=(parseData*scale_factor)-3.3/2; % convert digital data to voltages (3.3V/12-bits) centered about 0V

function [y] = fft_interp(x,M)
% perform approximate bandlimited interpolation of x by a factor of M
L = 4;
winInds = (-L*M : L*M).'/M * pi;

% get the ideal antialiasing filter's impulse response of length 2*M + 1 
winInds(L*M + 1) = 1;
myWin = sin(winInds) ./ winInds;
myWin(L*M + 1) = 1;

% use the window method; apply a hann window
myWin = myWin .* hann_window(2*L*M + 1);

% insert zeros in data and apply antialias filter via FFT
nFFT = numel(x) * M;
if isreal(x)
    y = ifft( fft(myWin,nFFT) .* repmat(fft(x),[M 1]), 'symmetric');
else
    y = ifft( fft(myWin,nFFT) .* repmat(fft(x),[M 1]) );
end
y = y([L*M+1:end 1:L*M]);


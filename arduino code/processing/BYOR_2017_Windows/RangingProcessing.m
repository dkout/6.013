function [] = RangingProcessing(matFile)

% Produces an RTI (range x time intensity) image of the
% cantenna recording. Also applies a simple two-pulse
% canceller to filter out clutter and CFAR normalization
% to improve visual detection. See inside the function
% for additional parameters.
%
%    matFile = the filename of the .mat file to process
%
% MIT IAP 2016 Laptop Radar Course
% (c) 2016 Massachusetts Institute of Technology

% ---- setup constants and parameters ----
c = 299e6; % (m/s) speed of light
Tp = 20e-3; % (s) pulse length
Fs = 48000; % (Hz) sample rate
ovsRng = 2; % oversampling factor applied when interpolating the range data
fStart = 2400e6; % (Hz) LFM start frequency
fStop = 2480e6; % (Hz) LFM stop frequency
nPulseCancel = 2; % number of pulses to use for canceller
maxRange = 100; % (m) maximum range to display

% ----- end constants and parameters -----

fprintf('Using %g MHz bandwidth\n', (fStop-fStart)*1e-6);
fprintf('Loading *.mat file...\n');

if ~exist('matFile','var')
    matFile = 'WalkingBackAndForth.mat';
end

% load data
a = load(matFile);
s = a.data;

% derived parameters
Np = round(Tp * Fs); % # of samples per pulse
BW = fStop - fStart; % (Hz) transmit bandwidth
delta_r = c/(2*BW); % (m) range resolution

% parse data to format
fprintf('Parsing the recording...\n');
[parseData,numPulses] = parse_matFile(s,Np);

% compute range axis
Nrange = floor(ovsRng*Np/2); % number of output range samples
dataRange = (0:Nrange-1).' * (delta_r/ovsRng); % ranges of each bin (m)
dataRange = dataRange(dataRange <= maxRange); % apply range limits
Nrange_keep = numel(dataRange); % number of range bins to keep
rngWin = hann_window(Np); % the window applied to reduce range sidelobes

% process pulses into a data matrix
fprintf('Found %d pulses\n',numPulses);
fprintf('Processing pulse data...\n');
for pIdx=2:numPulses  % skip first pulse, likely a partial one
    
    % read pulse
    tmp = parseData(:,pIdx);
    
    % FFT to convert frequencies to ranges
    tmp = fft(tmp((1:Np)) .* rngWin, 2*Nrange);
    
    % insert into range data matrix
    sif(:,pIdx) = tmp(1:Nrange_keep);
    
end
sif=sif.';

% display the RTI
figure;
imagesc(dataRange,(0:numPulses-1)*Tp*2,20*log10(abs(sif)));
ylabel('Time (s)');
xlabel('Range (m)');
title('RTI without clutter rejection');
colormap(jet(256));
colorbar;

% apply the N-pulse canceller
mti_filter = -ones(nPulseCancel,1)/nPulseCancel;
midIdx = round((nPulseCancel+1)/2);
mti_filter(midIdx) = mti_filter(midIdx) + 1;
sif = convn(sif,mti_filter,'same');

% display the MTI results
figure;
imagesc(dataRange,(1:numPulses)*Tp*2,20*log10(abs(sif)));
ylabel('Time (s)');
xlabel('Range (m)');
title('RTI with MTI clutter rejection');
colormap(jet(256));
colorbar;

% apply the median CFAR normalization
sif_dB = 20*log10(abs(sif));
sif_dB = sif_dB - repmat(median(sif_dB,1),[size(sif,1) 1]); % over time
sif_dB = sif_dB - repmat(median(sif_dB,2),[1 size(sif,2)]); % over range

% plot the CFAR normalized results
figure;
imagesc(dataRange,(1:numPulses)*Tp*2,sif_dB);
ylabel('Time (s)');
xlabel('Range (m)');
title('RTI with MTI+CFAR');
colormap(jet(256));
caxis([0 40]-3);
colorbar;

function [w] = hann_window(N)
% create a hann (cosine squared) window
w = .5 + .5*cos(2*pi*((1:N).'/(N+1) - .5));

% Parses the digital data by looking for "start of pulse" and "end of
% pulse" flags.  Converts the digital data to voltages.
function [parseData,numPulses]=parse_matFile(x,Np)
flag_pulseStart=5000;
scale_factor=3.3/2^12;
numPulses=sum(x(:)==flag_pulseStart);
parseData=zeros(Np,numPulses); 
inds = find(x==flag_pulseStart);
inds = inds(1:end-1);
ctr = 1;
for z = inds
    parseData(:,ctr) = x(z:z+Np-1);
    ctr = ctr + 1;
end
parseData=(parseData*scale_factor)-3.3/2; % convert digital data to voltages (3.3V/12-bits) centered about 0V




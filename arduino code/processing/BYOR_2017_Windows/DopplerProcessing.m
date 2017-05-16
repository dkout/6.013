function [] = DopplerProcessing(matFile)
% function [] = DopplerProcessing(matFile)
% 
% Produces a DTI (Doppler x time intensity) image of the
% cantenna recording. Assumes the data is collected with
% the radar in a continuous wave (CW) mode. See inside
% the function for more parameters.
%
%    matFile = the filename of the .MAT file to process
%    
% MIT PEP 2016 Laptop Radar Course
% (c) 2016 Massachusetts Institute of Technologys

% ---- setup constants and parameters ----
c = 299e6; % (m/s) speed of light
cpi = 0.50; % (s) coherent processing interval 
fc = 2440e6; % (Hz) Center frequency (chirp is OFF)
maxSpeed = 30; % (m/s) maximum speed to display
overlapFactor = 8; % (unitless) number of overlapped pulse windows (1 for no overlap)
ovsDop = 4; % (unitless) oversample factor for Doppler axis
% ----- end constants and parameters -----

% use a default filename if none is given
if ~exist('matFile','var')
    matFile = 'CarsAndMailTruck12Nov2016.mat';
end

% load the measured data and convert to voltages
a=load(matFile);
s=a.data;  % matFile is one row of digital values
scale_factor=3.3/2^12; % convert digital data to voltages(3.3V/12-bits)
x=((s*scale_factor)-3.3/2)'; % center data about zero for calculations


% derived parameters
Fs=960/0.0384;  % Fs = sampling frequency: 960 samples per 38.4 msec (960 known from Arduino code, and 38.4msec as measured from oscilloscope)
N = round(cpi*Fs); % number of samples per pulse

% grab an integer number of overlapped frames
M = floor(numel(x) / N * overlapFactor) - (overlapFactor) + 1;

% compute axes parameters for the plot
% note: the Doppler data is oversampled by ovsDop
delta_f = (0:ovsDop*N/2-1).' / (ovsDop*N) * Fs; % Doppler freq. (Hz)
lambda = c / fc; % wavelength (m)
speed = delta_f * lambda / 2; % Doppler -> speed
time = (1:M) * cpi / overlapFactor;  % collection time (sec)


% limit the speed axis to a reasonable range
speed = speed(speed <= maxSpeed);
nSpeed = numel(speed);

% compute a Doppler window
dopWin = hann_window(N);


% compute the Doppler vs. time plot
fprintf('Processing...\n');


dti = zeros(nSpeed, M);  % pre-allocate array

for mIdx = 1:M
    xInds = (1:N).' + (mIdx-1)*floor(N/overlapFactor); % compute indices
    tmp = double(x(xInds));
    tmp = tmp - mean(tmp); % remove DC component if it exists
    tmp = tmp .* dopWin; % apply Doppler window
    tmp = fft(tmp, ovsDop*N); % compute oversampled Doppler spectrum
    dti(:,mIdx) = 20*log10( abs(tmp(1:nSpeed)) ); % grab result in dB
end


dti = dti.';

fprintf('Processing complete.\n');

% make Doppler vs. time plot
figure;
imagesc(speed,time,dti);
colormap(jet(256));
caxis(max(dti(:)) + [-60 0]); % show 60 dB dynamic range
colorbar;
xlabel('Speed (m/sec)');
ylabel('Time (sec)');

% ---- standard DSP helper functions below ----

function [w] = hann_window(N)
% create a hann (cosine squared) window
w = .5 + .5*cos(2*pi*((0:N-1).'/(N-1) - .5));

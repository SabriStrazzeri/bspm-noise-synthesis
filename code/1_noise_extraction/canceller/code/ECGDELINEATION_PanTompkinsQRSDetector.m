function [qrs, ecgm, thSignal, thNoise, spki, npki] = ECGDELINEATION_PanTompkinsQRSDetector(ecg, fs, qrsPrev, thSignalPrev, thNoisePrev, spkiPrev, npkiPrev)
% Custom made version of the Pan-Tompkins algorithm for QRS detection.
%
% Inputs:   - ecg:   ECG signal
%           - fs:    sampling frequency (Hz)
%           - qrsPrev: positions of the QRS already detected in the ecg
%                   signal segment under analysis (only for on-line
%                   detection)
%           - thSignalPrev: signal threshold employed for the previous
%                   detections (only for on-line detection)
%           - thNoisePrev: noise threshold employed for the previous
%                   detections (only for on-line detection)
%           - spkiPrev: signal level employed for the previous
%                   detections (only for on-line detection)
%           - npkiPrev: noise level employed for the previous
%                   detections (only for on-line detection)
%
% Outputs:  - qrs:   array with the position of the QRS complex
%           - ecgm:  pulse-like signal employed for QRS detection
%           - thSignal: last signal threshold employed for QRS detection
%           - thNoise:  last noise threshold employed for QRS detection
%           - spki: last signal level employed for QRS detection 
%           - npki: last noise level employed for QRS detection 
%
% Created by Javier Milagro (javier.milagro@corify.es)
% Last modified: 11/08/2022 Javier Milagro (javier.milagro@corify.es)
% -------------------------------------------------------------------------

%% Parameter initialization

if nargin < 3
    qrsPrev = [];
    thSignalPrev = [];
    thNoisePrev = [];
    spkiPrev = [];
    npkiPrev = [];
end

if nargin < 4
    thSignalPrev = [];
    thNoisePrev = [];
    spkiPrev = [];
    npkiPrev = [];
end

if nargin < 5
    thNoisePrev = [];
    spkiPrev = [];
    npkiPrev = [];
end

if nargin < 6
    spkiPrev = [];
    npkiPrev = [];
end

if nargin < 7
    npkiPrev = [];
end

% Initialize design parameters
[filter_order, fc, movmean_window, qrs_window_search, th_init_time, min_RR_interval,...
 RR_missed_limit, Twave_time_threshold, Twave_slope_threshold, do_plot] = ECGDELINEATION_PanTompkinsSetup([]);
% do_plot = 1;

% Window search is divided by 2 to search in -qrs_window_search : qrs_window_search
qrs_window_search = floor(qrs_window_search * fs) / 2;

% Band-pass filter definition
[B, A] = butter(filter_order, 2 * fc / fs);


%% ECG pre-processing
% Signal averaging (for using the average lead in later calculations in case that multiple leads are passed as input)
maxAmplitude = max(abs(ecg), [], 2);
ecg_avg = ecg./repmat(maxAmplitude, 1, size(ecg, 2));

% Normalized mean lead
ecg_avg = nanmean(abs(ecg_avg), 1);

ecgf = filtfilt(B, A, ecg'); % band-pass filtering
ecgd = diff(ecgf);             % derivative
ecgs = ecgd .^ 2;           % square

ecgm = movmean(ecgs, floor(movmean_window * fs), 1);  % smoothing to eliminate high-frequencies

% Signal averaging
maxAmplitude = max(abs(ecgm), [], 1);
Y = ecgm./repmat(maxAmplitude, size(ecgm, 1), 1);

% Normalized mean lead
Y = nanmean(abs(Y), 2);
Y = Y/max(Y);
ecgm = Y;


% Detect if it is ventricular tachycardia
% If the autocorrelation function is periodic with a period lower than the
% established Twave_time_threshold, probably it is VT. Additionally, low
% variance of autocorrelation peaks is allowed for avoiding confusion with
% other arrhtyhmias
corrFunction =  xcorr(ecgm);
[~, corrFunctionPeaks] = findpeaks(corrFunction);
if (mean(diff(corrFunctionPeaks)) < (Twave_time_threshold * fs)) && (std(diff(corrFunctionPeaks)) < (0.1 * fs))
    % In this case, the rhythm is considered to be VT, so that the allowed
    % time difference between adjacent beats is adjusted
    Twave_time_threshold = 0.2;
end

% Find all the peaks in the smoothed signal (peaks can not be closer than min_RR_interval seconds)
[peaks, peak_locs] = findpeaks(Y, 'MinPeakDistance', floor(min_RR_interval * fs));


if ~isempty(qrsPrev)
    peaks(peak_locs <= qrsPrev(end)) = [];
    peak_locs(peak_locs <= qrsPrev(end)) = [];
end


%% QRS detection

% Initialization
qrs = [qrsPrev; nan(size(peaks))];      % detected QRS complexes
% qrs_candidates = nan(size(peaks));    % candidates for being QRS compelxes
search_back_peaks = [nan(size(qrsPrev)); nan(size(peaks))];   % candidates for being QRS complexes
                                                              % in case a QRS is not detected for
                                                              % a long period
peaks = [nan(size(qrsPrev)); peaks];
peak_locs = [nan(size(qrsPrev)); peak_locs];
                                                              
% Signal and noise thresholds
thSignal = zeros(size(peaks));
thNoise = zeros(size(peaks));
% Signal and noise levels
spki = zeros(size(peaks));
npki = zeros(size(peaks));

% First values obtained from the begining of the signal (or from the
% previous iteration, if available
if ~isempty(qrsPrev)
    normFactor = max(Y(qrsPrev(end)+0.1*fs:end)); % +100ms to ensure that a previous QRS is not selected
else
    normFactor = 1;
end

if ~isempty(thSignalPrev)
    thSignal(length(qrsPrev) + 1) = thSignalPrev*normFactor;
else
    if (th_init_time * fs) > length(ecgm)
        thSignal(1) = 0.33 * max(ecgm);
    else
        thSignal(1) = 0.33 * max(ecgm(1 : th_init_time * fs));
        % th_signal(1) = nanmean(ecgm(1 : th_init_time * fs));
    end
end

if ~isempty(thNoisePrev)
    thNoise(length(qrsPrev) + 1) = thNoisePrev*normFactor;
else
    thNoise(1) = 0.5 * thSignal(1);
end

% Signal and noise levels
if ~isempty(spkiPrev)
    spki(length(qrsPrev) + 1) = spkiPrev*normFactor;
else
    spki(1) = thSignal(1);    % signal level
end
if ~isempty(npkiPrev)
    npki(length(qrsPrev) + 1) = npkiPrev*normFactor;
else
    npki(1) = thNoise(1);    % noise level
end

% Flag used to detect signal polarity from the first beat. Afterwards it is
% set to 0
% isfirst = 1;

% Iterate on all the detected peaks
for i = (length(qrsPrev) + 1):length(qrs)

    % Define search window around peak
    kini = peak_locs(i) - qrs_window_search;    % search window onset
    kend = peak_locs(i) + qrs_window_search;    % search window offset

    % Avoid detecting again the first peak if it is already detected
    if ~isempty(qrsPrev)
        if (peak_locs(i) - qrsPrev(end)) < 0.05*fs % 50 ms, i.e., belonging to the same QRS
            thSignal(i + 1) = thSignal(i);
            thNoise(i + 1) = thNoise(i);
            spki(i + 1) = spki(i);
            npki(i + 1) = npki(i);
            continue;
        end
    end
    
    % Avoid selecting negative indexes
    if kini < 1
        kini = 1;
    end

    % Avoid selecting out-of-bounds indexes
    if kend > size(ecgm,1)
        kend = size(ecgm,1);
    end
    
    % Detect QRS candidates and update thresholds
    if i <= length(qrs)-1
%         [th_signal(i + 1), th_noise(i + 1), spki(i + 1), npki(i + 1), qrs_candidates(i), search_back_peaks(i)] = detect_and_update(ecgm, kini, kend, th_signal(i), th_noise(i), spki(i), npki(i));
        [thSignal(i + 1), thNoise(i + 1), spki(i + 1), npki(i + 1), qrs(i), search_back_peaks(i)] = ECGDELINEATION_detectAndUpdate(ecgm, qrs, peak_locs(i), thSignal(i), thNoise(i), spki(i), npki(i));
    else
        % If it is the last peak, do not update the thresholds
%         [~, ~, ~, ~, qrs_candidates(i), search_back_peaks(i)] = detect_and_update(ecgm, kini, kend, th_signal(i), th_noise(i), spki(i), npki(i));
        [~, ~, ~, ~, qrs(i), search_back_peaks(i)] = ECGDELINEATION_detectAndUpdate(ecgm, qrs, peak_locs(i), thSignal(i), thNoise(i), spki(i), npki(i));
    end
    
%     % If a QRS candidate was found
%     if ~isnan(qrs_candidates(i))
%         
%         if isfirst
%             % If it is the first beat, check polarity of the signal.
%             % Polarity of ECGs with negative R waves is changed to positive
%             % so that the algorithm works fine in either case.
%             polarity = Rwave_polarity(ecg(kini : kend), fs);
%             ecg = ecg * polarity;
%             isfirst = 0;  % This was the first beat
%         end
%         
%         % Detect the QRS as the position of the maximum within the search
%         % interval
%         [~, qrs(i)] = max(ecg(kini : kend));
%         qrs(i) = kini + qrs(i) -1;
%     end
    
    % Protection against peaky T waves
    if (i > 1) && ((qrs(i) - qrs(i - 1)) <= Twave_time_threshold * fs)
        % In case there are two close QRS, the second one might be a peaky
        % T wave which was wrongly detected. In order to chech if it is a T
        % wave or a real QRS the upslope and downslopes of both detected
        % waves are compared
        upslope_current = mean(diff((ecg_avg(max([1, (qrs(i) - 0.05 * fs)]) : qrs(i)))));
        upslope_previous = mean(diff((ecg_avg(max([1, (qrs(i - 1) - 0.05 * fs)]) : qrs(i - 1)))));
        downslope_current = mean(diff((ecg_avg(qrs(i) : min([(qrs(i) + 0.05 * fs), length(ecgf)])))));
        downslope_previous = mean(diff((ecg_avg(qrs(i - 1) : min([(qrs(i - 1) + 0.05 * fs), length(ecgf)])))));
        
        if (upslope_current < (Twave_slope_threshold * upslope_previous)) || (downslope_current > (Twave_slope_threshold * downslope_previous))
            % If the slopes of the second wave differs by more than
            % T_wave_slope_threshold from the first wave, it is considered
            % as a T wave and the QRS mark is removed
            qrs(i) = nan;
        end
    end
    
    % Search-back algorithm: in case that a QRS complex is not detected for
    % a long period, the candidate peaks stored in search_back_peaks are
    % revisited
    
    if ~isnan(qrs(i)) % Only a QRS was detected the RR interval is computed 
                      % to decide whether there is a missing beat (within 
                      % search_back())
        [qrs(1 : i), ~, ~] = ECGDELINEATION_searchBack(ecg_avg, qrs(1 : i), search_back_peaks, RR_missed_limit, qrs_window_search); 
    end
    
end

qrs(isnan(qrs)) = [];
qrs = int32(qrs);

%% Graphical representation
if do_plot
    figure
    plot(ecgm)
    hold on
    plot(peak_locs,thSignal,'g--')
    plot(peak_locs,thNoise,'m--')
    plot(peak_locs, spki, 'g:')
    plot(peak_locs, npki, 'm:')
    plot(qrs,ecgm(qrs),'k*')
    hold off
    axis tight
    xlabel('Time (s)')
    legend({'ECGm','Signal threshold','Noise threshold','Signal level','Noise level','QRS locations'})
end

%% Return
qrs(1:length(qrsPrev)) = [];

% Readjust thresholds
% if ~isempty(qrs)
%     maxAmpNew = max(Y(qrs(1):end));
% else
%     maxAmpNew = 1;
% end

% thSignal = thSignal(end)/maxAmpNew;
% thNoise = thNoise(end)/maxAmpNew;
% spki = spki(end)/maxAmpNew;
% npki = npki(end)/maxAmpNew;
thSignal = thSignal(end);
thNoise = thNoise(end);
spki = spki(end);
npki = npki(end);

end
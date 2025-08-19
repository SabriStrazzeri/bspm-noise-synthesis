function [th_signal, th_noise, signal_level, noise_level, qrs_peak, search_back_peak] = ECGDELINEATION_detectAndUpdate(ecgm, qrs, peak_loc, th_signal, th_noise, signal_level, noise_level)

% detect_and_update() detects QRS candidates and updates the signal and
% noise thresholds and levels, according to the Pan-Tompkins algorithm.
% Inputs:   - ecgm: smoothed signal  resulting from the pre-processing of
%                   the input ECG in Pan-Tompkins algorithm
%           - qrs: # sample corresponding to the detected QRS
%           - peak_loc: # sample corresponding to the peak under evaluation
%           - th_signal: signal threshold at the analized peak
%           - th_noise:  noise threshold at the analized peak
%           - signal_level: signal level at the analized peak
%           - noise: signal level at the analized peak
%
% Outputs:  - th_signal: updated signal threshold
%           - th_noise:  updated noise threshold
%           - signal_level: updated signal level
%           - noise: signal updated noise level
%           - qrs_peak: candidate for being a QRS complex. If NaN, no QRS
%                       candidate was found.
%           - search_back_peak: candidate for being a QRS complex in case
%                               no QRS complex is found for a long period.
%                               If NaN, no such a peak was found.
%
%
% Created by Javier Milagro (jmilagroserrano@gmail.com)
% Last modified: 11/05/2020

%% Initialization
alpha = 0.25;   % learning averaging for updating the thresholds
beta = 0.125;   % weight of the exponential averaging  for updating signal 
                % and noise levels

qrs_peak = NaN;          % QRS candidate   
search_back_peak = NaN;  % QRS candidate in case QRS not detected for a long period

%% Peak detection
% Detect the maximum of the smoothed signal in the search window
% [current_peak, current_peak_loc] = max(ecgm(kini:kend));
peak = ecgm(peak_loc);

%% Decide whether the detected peak is a valid QRS candidate or not
% If the maximum is larger than the signal threshold (and than a third of 
% the mean amplitude of previous QRS), the peak is QRS candidate
qrs(isnan(qrs)) = [];
if ~isempty(qrs)
    amplitudeAver = mean(ecgm(int32(qrs(max(1, length(qrs) - 8) : max(1, length(qrs)-1)))));
else
    amplitudeAver = 0;
end

if (peak >= th_signal) && (peak > amplitudeAver/3)

    % The maximum is a candidate QRS complex
%     qrs_peak = kini + peak_loc - 1; % Candidate QRS complex location
    qrs_peak = peak_loc; % Candidate QRS complex location
    % Update signal level
    signal_level = (beta * peak) + (1 - beta) * signal_level;

% If the maximum is lower than the signal threshold but larger than the
% noise threshold, it is a search-back peak
elseif (peak < th_signal) && (peak >= th_noise)

    % The detected maximum might be revisited if a missing beat is
    % detected
%     search_back_peak = kini + peak_loc -1;
    search_back_peak = peak_loc;
    % Update signal level
    signal_level = 0.25 * peak + 0.75 * signal_level;
    % Update noise level
    noise_level = (beta * peak) + (1 - beta) * noise_level;

end

%% Update signal and noise thresholds
th_signal = noise_level + alpha * (1.25*signal_level - 0.5*noise_level); 
%In the original algorithm, th_signal = noise_level + alpha * (signal_level - noise_level) (adaptated for flutter)
th_noise = 0.25 * th_signal;

end

function [filter_order, fc, movmean_window, qrs_window_search, th_init_time, min_RR_interval, RR_missed_limit, Twave_time_threshold, Twave_slope_threshold, do_plot] = ECGDELINEATION_PanTompkinsSetup(Setup)

% pan_tompkins_parameters_setup() loads all the design parameters for QRS
% detection, as indicated in Setup. If any of the parameters is not defined
% in Setup, it will be initialized with a default value. The description of
% each parameter is provided below, together with their default values.
% 
% 
% Created by Javier Milagro (jmilagroserrano@gmail.com)
% Last modified: 12/05/2020
% Last modified: 08/02/2022, Marta Martínez (marta.martinez@corify.es)

% Define filter order for band-pass filtering
if ~isfield(Setup, 'filter_order')
    filter_order = 3;   % Default
else
   filter_order = Setup.filter_order;
end

% Define cut-off frequencies of the band-pass filter (in Hz)
if ~isfield(Setup, 'fc')
   fc = [5 15];   % Default
else
   fc = Setup.fc;
   if length(fc) ~= 2
        warning('Two cut-off frequencies must be specified, cut-off frequencies set to default.')
        fc = [5 15];   % Default
    end
end

% Define moving-average window size (in seconds)
if ~isfield(Setup, 'movmean_window')
   movmean_window = 0.1;   % Default
else
   movmean_window = Setup.movmean_window;
end

% Define the length of the window around detected peaks in which R peaks 
% are searched (in seconds)
if ~isfield(Setup, 'qrs_window_search')
   qrs_window_search = 0.15;   % Default
else
   qrs_window_search = Setup.qrs_window_search;
end

% Define the time used at the begining of the signal for initializing the
% signal and noise thresholds (in seconds)
if ~isfield(Setup, 'th_init_time')
   th_init_time = 2;   % Default
else
   th_init_time = Setup.th_init_time;
end

% Define the minimum time between consecutive R peaks (in seconds)
if ~isfield(Setup, 'min_RR_interval')
   min_RR_interval = 0.1;   % Default
else
   min_RR_interval = Setup.min_RR_interval;
end

% Define the percentage of allowed variation in the RR above which a search
% for missing beats is triggered
if ~isfield(Setup, 'RR_missed_limit')
   RR_missed_limit = 1.66;   % Default
else
   RR_missed_limit = Setup.RR_missed_limit;
end

% Define a time threshold for evaluating if the detected QRS is a wrongly 
% detected T wave (in seconds)
if ~isfield(Setup, 'Twave_time_threshold')
   Twave_time_threshold = 0.36;   % Default
else
   Twave_time_threshold = Setup.Twave_time_threshold;
end

% Define the percentaje that the slopes of two consecutive waves should
% exceed in order to consider the second one as a QRS and not as a peaky T
% wave
if ~isfield(Setup, 'Twave_slope_threshold')
   Twave_slope_threshold = 0.5;   % Default
else
   Twave_slope_threshold = Setup.Twave_slope_threshold;
end

% Display detections if set to 1
if ~isfield(Setup, 'do_plot')
   do_plot = 0;   % Default
else
   do_plot = Setup.do_plot;
end

end
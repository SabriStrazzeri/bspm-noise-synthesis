function [qrs_peaks, search_back_peaks, search_back_qrs_idx, updated] = ECGDELINEATION_searchBack(ecg, qrs_peaks, search_back_peaks, RR_missed_limit, qrs_window_search)

% search_back() looks for the existence of missing beats and, in case there
% are, the peaks stored in search_back_peaks are evaluated as possible QRS 
% candidates. This is a recursive algorithm than calls himself until no
% missing beats are detected.
% Inputs:   - ecg: input ECG signal
%           - qrs_peaks: vector whose i-th value corresponds to the
%                        position of the i-th QRS complex. In case that the
%                        peak in the i-th position was not a QRS, its value
%                        should be NaN
%           - search_back: vector whose i-th value corresponds to the
%                          position of the i-th search_back peak. In case 
%                          that the peak in the i-th position was not a 
%                          search_back peak, its values hould be NaN
%           - RR_missed_limit: percentage of allowed variation in the RR 
%                              above which the search for missing beats is 
%                              triggered
%
% Outputs:  - qrs_peaks:   QRS position vector updated with the new 
%                          detected peaks
%           - search_back: updated vector of search_back peaks, in which 
%                          the position of those peaks detected as QRS were
%                          set to NaN
%           - search_back_qrs_idx: index of the new QRS detection
%           - updated:     returns 1 if a new QRS was detected and 0
%                          otherwise
%
%
% Created by Javier Milagro (jmilagroserrano@gmail.com)
% Last modified: 11/05/2020

%% Initialization
search_back_qrs = nan;      % new QRS position
search_back_qrs_idx = nan;  % new QRS index
updated = 0;                % not new QRS detected

% Auxiliar vector contianing only QRS positions (without NaNs)
qrs_peaks_aux = qrs_peaks;
qrs_peaks_aux(isnan(qrs_peaks_aux)) = [];

% Mean RR calculated over the last 8 beats (or less if not 8 beats available)
RRaver = mean(diff(qrs_peaks_aux(max(1, length(qrs_peaks_aux) - 8) : max(1, length(qrs_peaks_aux)-1))));

amplitudeAver = mean(ecg(int32(qrs_peaks_aux(max(1, length(qrs_peaks_aux) - 8) : max(1, length(qrs_peaks_aux)-1)))));

% If there is more than 1 beat
if length(qrs_peaks_aux) > 1
    
    % If the last RR interval differs from the mean RR in more than
    % RR_missed_limit times, then there is a missing QRS
    if (qrs_peaks_aux(end) - qrs_peaks_aux(end - 1)) > (RR_missed_limit * RRaver)
        
        % The QRS candidates are all the peaks stored in search_back_peaks
        % that lay between the last two detected beats
        qrs_candidates = search_back_peaks((search_back_peaks > qrs_peaks_aux(end - 1)) & (search_back_peaks < qrs_peaks_aux(end)));
        
        if ~isempty(qrs_candidates)
            
            % The QRS candidate with maximum amplitude is detected as a new
            % QRS complex
            [amplitude, idx] = max(ecg(qrs_candidates));
            
            if amplitude > amplitudeAver/3 % Only evaluate peaks whose amplitude is greater than a third of the mean amplitude of the previous beats
                [~, search_back_qrs] = max(ecg(max([1, qrs_candidates(idx) - qrs_window_search]) : min([qrs_candidates(idx) + qrs_window_search, length(ecg)])));
                search_back_qrs = search_back_qrs + max([1, qrs_candidates(idx) - qrs_window_search]) -1;
                search_back_qrs_idx = find(search_back_peaks == qrs_candidates(idx));
            end
        end
    end
end

% If a new QRS was found, update the qrs_peaks and search_back_peaks
% vectors, and set updated to 1
if ~isnan(search_back_qrs)
    qrs_peaks(search_back_qrs_idx) = search_back_qrs;
    search_back_peaks(search_back_qrs_idx) = nan;
    updated = 1;
end

% If a new QRS is detected, the process is repeated comparing the RR 
% interval of the new QRS with the previous and the following one, in order
% to check for the existence of more missing QRS
while updated
    [qrs_peaks(1 : search_back_qrs_idx), search_back_peaks, search_back_qrs_idx, updated_prev] = ECGDELINEATION_searchBack(ecg, qrs_peaks(1 : search_back_qrs_idx), search_back_peaks, RR_missed_limit, qrs_window_search);
    [qrs_peaks, search_back_peaks, search_back_qrs_idx, updated_next] = ECGDELINEATION_searchBack(ecg, qrs_peaks, search_back_peaks, RR_missed_limit, qrs_window_search);
    updated = (updated_prev | updated_next); % If no new missing beats, exit the loop
end

end
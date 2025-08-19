function [nonValids, validCase, noise_new, spike_detected] = discriminate_signals(dataName, noise, leadStatus, correlation, pae_norm, nonValids, counter)
%discriminate_signals: discards signals based on metrics values.
%
%Inputs:
% - dataName: name of data file.
% - correlation: estimated correlation values.
% - pae_norm: estimated peak to peak amplitude difference values.
% - nonValids: array cell with non-valid signals.
% - counter: number of the file in its respective folder.
%
%Outputs:
% - nonValids: updated array cell with non-valid signals.
% - validCase: flag for valid cases (0 if it is not valid, 1 if it is
% valid).
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

% Valid case flag is true initially
validCase = true;

% Spike detected flag
spike_detected = false;


%% Spike detection in the noise signal

% Calculates the variance of the amplitude of the obtained noise signal
threshold = mean(var(noise)) + 3*std(var(noise));

% Detect spikes in the noise signal
spikes = find(var(noise) > threshold);
if ~isempty(spikes)
    % If spikes are detected, remove them from the signal
    spike_detected = true;
    [noise_new, ~, ~, ~] = ECGPREPROCESSING_removePacingSpikes_v1_2(noise', 1000, leadStatus, [], 15, 15);
else
    % If no spikes are detected, keep the original signal
    noise_new = noise;
end


%% Determines threshold for the metrics and selects non-valid cases

% Calculates the average values of the evaluated metrics
correlation = mean(correlation(2:end)); pae_norm = mean(pae_norm(2:end));

% Sets the threshold for the metrics
if correlation < 0.75 || correlation > 1 || pae_norm < 0 || pae_norm > 0.05
    nonValids = [nonValids; string(counter), string(dataName), 'Metrics'];
    validCase = false;
end


end
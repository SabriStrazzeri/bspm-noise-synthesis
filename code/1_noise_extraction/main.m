% main.m
%
% Principal script for the evaluation of the noise extraction algorithm
%
%Last edited: 23/07/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

warning off; % Disable all warnings

% DB directory
cd('..\..\data\');
files = dir('*.mat');

% Initialization of variables
nonValids = []; figuresList = {}; correlacion = {}; pae = {}; rmse_values = {}; pae_norm = {}; metrics = {'correlacion', 'pae', 'rmse_values', 'pae_norm'};

% Parameters
debug = 1; 
fs = 1000; % Sampling frequency
NE = 128; % Number of leads
research = 1; 

for i = 1:length(files)

    % Load signal
    data = files(i).name;
    [ECGsignal, leadStatus, torso_og, validCase] = preprocessing(data);

    if validCase % Case without preprocessing issues
        try
            % Cancel the complete cardiac activity (PQRST)
            [entryPointFailed, ~, atrialActivity, atrialActivityOn, atrialActivityOff, QRS, leadStatus, ~, ~, ECGavgOnset, ECGavgOffset, beatOn, beatOff] = ENTRYPOINT_CancelQRST_ssm(debug, ECGsignal, leadStatus,  torso_og, fs,  NE, research);
            if isnan(ECGavgOnset) || isnan(ECGavgOffset) % Delineation error: the canceller returns NaNs
                [validCase, nonValids, figuresList] = detect_delineation_error(i, nonValids, figuresList, 'Delineation', data);
            end
            % Normalize the signal 
            [ECGsignal, atrialActivity] = normalization(ECGsignal, atrialActivity); 
        catch ME % If Pon or Toff are NaNs
            [validCase, nonValids, figuresList] = detect_delineation_error(i, nonValids, figuresList, 'Delineation', data);
        end
    else % Error encountered during preprocessing
        [validCase, nonValids, figuresList] = detect_delineation_error(i, nonValids, figuresList, 'Preprocess', data);
    end

    if ~validCase % if the case is not valid (errors presented during execution)
        segmentRange = linspace(1, 5, 5)'; % Definition of the range of evaluated segments
        % Assign empty values to metrics
        for j = 1:length(metrics)
            eval([metrics{j}, '{end+1} = [segmentRange, zeros(length(segmentRange), 1), zeros(length(segmentRange), 1), zeros(length(segmentRange), 1)];']);
        end
        disp('-----------------------------------')
        disp(['Case ', num2str(i), ' completed.']);
        disp('-----------------------------------')
        continue;
    else % Valid case, proceed with the evaluation of metrics
        % Add zero padding to noise signal (the canceller return a signal with a shorter length than the ECG signal)
        [selectedECG, selectedAA, selectedAA_zeros] = convert_to_selected(ECGsignal, atrialActivity, atrialActivityOn, atrialActivityOff, leadStatus);

        % Define the start and stop points for the metrics evaluation
        start = double(beatOn) + ECGavgOnset; stop = double(beatOn) + ECGavgOffset;

        % Calculate metrics for non-PQRST segments
        [correlacion_noPQRST, PAE_noPQRST, RMSE_noPQRST, PAEnorm_noPQRST, noValido, validCase] = metrics_evaluation(selectedECG, selectedAA_zeros, start, stop, 0, data, true);

        if validCase % If there were not errors during the calculation of metrics in the non-PQRST segments, calculate the metrics for the PQRST segments
            [correlacion_PQRST, PAE_PQRST, RMSE_PQRST, PAEnorm_PQRST, ~, ~] = metrics_evaluation(selectedECG, selectedAA_zeros, start, stop, 1, data, true);

            % Represent the results: plot delineation of PQRST segments (optional)
            figFolder = '..\Figures\';
            [name, figuresList] = plot_delimited_signals(selectedECG, selectedAA, start, stop, data, figuresList, figFolder);

        else  % If the delination failed because it is overlapping segments
            % Assign the metrics of non-PQRST segments to PQRST segments
            correlacion_PQRST = correlacion_noPQRST; PAE_PQRST = PAE_noPQRST; PAEnorm_PQRST = PAEnorm_noPQRST; RMSE_PQRST = RMSE_noPQRST;
            % Discard the case
            [validCase, nonValids, figuresList] = detect_delineation_error(i, nonValids, figuresList, 'Overlap', data); 
        end

        % Define the range of segments for the metrics
        maxLong = max(cellfun(@length, {correlacion_noPQRST,  PAE_noPQRST, RMSE_noPQRST, PAEnorm_noPQRST}));
        segmentRange = linspace(1, maxLong, maxLong)';

        % Assign the metrics to the corresponding variables
        nonPQRST_values = {correlacion_noPQRST, PAE_noPQRST, RMSE_noPQRST, PAEnorm_noPQRST};
        PQRST_values = {correlacion_PQRST, PAE_PQRST, RMSE_PQRST, PAEnorm_PQRST};
        for j = 1:length(metrics)
            idx = length(eval(metrics{j})) + 1;
            eval([metrics{j}, '{', num2str(idx), '} = [segmentRange, nonPQRST_values{j}, PQRST_values{j}];']);
        end
    end

    if validCase % If the case is valid, proceed with the discrimination of cases
        % Discard cases based on metrics values and the presence of spikes
        [nonValids, validCase, atrialActivity_new, spike_detected] = discriminate_signals(data, atrialActivity, leadStatus , correlacion_noPQRST, PAE_noPQRST, nonValids, i);
        if spike_detected 
            [~, selectedAA, selectedAA_zeros] = convert_to_selected(ECGsignal, atrialActivity_new, atrialActivityOn, atrialActivityOff, leadStatus);
        end
    end

    if validCase % If the case is valid, proceed with the visualization and saving of results
        % Plot a representation of the original BSPM signal and the extracted noise with an established axis (optional)
        visualize_ssm(selectedECG, selectedAA, data, figFolder) 

        % Save data  
        newdataFolder = '..\..\noise_signals\';
        cd(newdataFolder);
        signal.noise = [zeros(128, atrialActivityOn), atrialActivity_new, zeros(128, length(ECGsignal)-atrialActivityOff-1)];
        signal.ECG = ECGsignal;
        signal.leadStatus = leadStatus;
        signal.torso = torso_og;
        save(name + '.mat', "signal");
    else % If the case is not valid, discard it
        disp('Metrics outside the specified thresholds were detected'); disp('Discarded case.');
    end
    
    disp('-----------------------------------')
    disp(['Case ', num2str(i), ' completed.']);
    disp(string(data))
    disp('-----------------------------------')

end


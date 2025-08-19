function [correlation, pae, rmseVal, pae_norm, nonValid, validCase] = metrics_evaluation(ECG, processedECG, start, stop, partType, dataName, validCase)
%metrics_evaluation: calculates multiple metrics to determine whether the
%cancelling process is being done correctly or not.
%
%Inputs:
% - ECG: nL (number of valid leads) x D (duration of ECG) matrix corresponding to
% the ECG signal.
% - processedECG: nL (number of valid leads) x D (duration of ECG) matrix corresponding to
% the cancelled ECG signal.
% - start: array with the beginning of every PQRST wave in the ECG signal.
% - stop: array with the end of every PQRST wave in the ECG signal.
% - partType: type of selected signal part (0 for non-PQRST sections, and 1
% for PQRST sections).
% - dataName: name of data file.
% - validCase: flag for valid cases (0 if it is not valid, 1 if it is
% valid).
%
%Outputs:
% - correlation: array cells with the correlation values between the
% original and cancelled ECG signal for each type of section.
% - pae: not-normalized peak to peak amplitude difference between the
% original and cancelled ECG signal for each type of section.
% - rmseVal: Root Mean Squared Error (RMSE) between the original and 
% cancelled ECG signal for each type of section.
% - pae_norm: normalized peak to peak amplitude difference between the
% original and cancelled ECG signal for each type of section.
% - nonValid: non-valid cases (will be lately added to an array cell with
% other non-valid cases). 
% - validCase: flag for valid cases (0 if it is not valid, 1 if it is
% valid).
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

%% Variables initialization

nonValid = {};
correlation = zeros(1, length(start)-1)';
pae = zeros(1, length(start)-1)';
rmseVal = zeros(1, length(start)-1)';
pae_norm = zeros(1, length(start)-1)';
start = [start; 0]; stop = [1; stop];


%% Metrics calculation

for i = 1:length(start)-1
    if partType == 0 % non-PQRST part
        ECG_2 = ECG(stop(i):start(i), :);
        processedECG_2 = processedECG(stop(i):start(i), :);
    else % PQRST part
        ECG_2 = ECG(start(i):stop(i+1), :);
        processedECG_2 = processedECG(start(i):stop(i+1), :);
    end

    ECG_2 = ECG_2'; processedECG_2 = processedECG_2'; 

    % Evaluate if the signal is valid or not
    if (isempty(ECG_2) && isempty(processedECG_2)) || validCase == false
        nonValid{end+1} = dataName;
        validCase = false;
        break; % If it is not valid, the case is discarded
    end

    % Estimate the correlation between the original and cancelled signal
    correlacionElectrodos = zeros(1, size(ECG_2, 1));
    for j = 1:size(ECG_2, 1)
        correlacionElectrodos(j) = corr(ECG_2(j, :)', processedECG_2(j, :)');
    end
    correlation(i) = round(mean(correlacionElectrodos), 2); 

    if validCase 
        % Estimate the peak to peak amplitude difference between the 
        % original and cancelled signal
        p2p_ECG_2 = max(ECG_2, [], 2) - min(ECG_2, [], 2); 
        p2p_processedECG_2 = max(processedECG_2, [], 2) - min(processedECG_2, [], 2); 
        paeElectrodos = abs(p2p_ECG_2 - p2p_processedECG_2); 
        pae(i) = round(mean(paeElectrodos), 2);

        % Estimate the normalized peak to peak amplitude difference between
        % the original and cancelled signal
        pae_norm(i) = round(mean(paeElectrodos ./ p2p_ECG_2), 2);

        % Estimate the RMSE between the  original and cancelled signal
        rmseElectrodos = zeros(1, size(ECG_2, 1));
        for j = 1:size(ECG_2, 1)
            rmseElectrodos(j) = rmse(processedECG_2(j, :)', ECG_2(j, :)');
        end
        rmseVal(i) = round(mean(rmseElectrodos), 2);
    end
end


end
function [ECG, leadStatus, torso, validCase] = preprocessing(dataName)
%preprocessing: loads, process, and normalizes signal.
%
%Inputs:
% - dataName: name of data file.
%
%Outputs:
% - ECG: nL (number of valid leads) x D (duration of ECG) matrix corresponding to
% the ECG signal.
% - leadStatus: 1 x nL array with valid (1) and not valid (-1 or 0) leads.
% - torso:
% - validCase: flag for valid cases (0 if it is not valid, 1 if it is
% valid).
%
%Last edited: 30/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

%% Variables initialization

validCase = true; % Flag for valid cases
ECG_exists = false; % Flag for ECG signal

disp('-----------------------------------')
disp('Signal preprocessing started.')
disp('-----------------------------------')


%% Select lead status and body surface

leadStatus = load(dataName).globalVariables.leadStatus;
torso = load(dataName).geometries.torso.envelope;


%% Select BSPM signal

% Single Beat Analysis
if ~isempty(load(dataName).segment.bspm.singleBeatAnalysis) 
    if ~isempty(load(dataName).segment.bspm.singleBeatAnalysis.voltage)
        ECG = load(dataName).segment.bspm.singleBeatAnalysis.voltage;
        if length(ECG) < 10000
            ECG_exists = false;
        else
            ECG_exists = true;
        end
    end
end

% Average Beat Analysis
if ECG_exists == false && ~isempty(load(dataName).segment.bspm.averageBeatAnalysis) 
    if ~isempty(load(dataName).segment.bspm.averageBeatAnalysis.voltage)
        ECG = load(dataName).segment.bspm.averageBeatAnalysis.voltage;

        if length(ECG) < 10000
            ECG_exists = false;
        else
            ECG_exists = true;
        end
    end
end

% Filtered Raw Voltage
try
    if ECG_exists == false && ~isempty(load(dataName).segment.bspm.rawVoltage.filteredVoltage) 
        ECG = load(dataName).segment.bspm.rawVoltage.filteredVoltage;
        ECG_exists = true;
    end
catch er
    ECG_exists = true;
end

% Irregular Rhythm Analysis gets discarded
if ECG_exists == false 
    validCase = false;
    disp('An irregular rhythm has been detected.')
    disp('Discarded case.')
end

% Select signals that last more than 5 seconds
if validCase && length(ECG) < 10000  % Verify if the filtered raw version of the signal exists
    if isfield(load(dataName), 'segment') && ...
            isfield(load(dataName).segment, 'bspm') && ...
            isfield(load(dataName).segment.bspm, 'rawVoltage') && ...
            isfield(load(dataName).segment.bspm, 'filteredVoltage')
        if ~isempty(load(dataName).segment.bspm.rawVoltage.filteredVoltage)
            ECG = load(dataName).segment.bspm.rawVoltage.filteredVoltage;
        end
    else % If it does not exist, then the case is discarded
        validCase = false;
        disp('A signal with less than 5 seconds has been detected.')
        disp('Discarded case.')
    end
end

% Detect amplitude change based on used amplifier
if max(ECG(:)) >= 1000 && validCase
    ECG = ECG./1000;
    disp('A signal with amplitude greater than 1000 has been detected.')
    disp('Corrected amplitude.')
end

% Delete additional leads (> 128) or discard cases with less leads (< 128)
N_leads = size(ECG); N_leads = N_leads(1);
if N_leads> 128
    ECG = ECG(1:128, :);
    disp('A signal with more than 128 leads has been detected.')
    disp('Last leads deleted.')
elseif N_leads < 128
    validCase = false;
    disp('A signal with less than 128 leads has been detected.')
    disp('Discarded case.')
end

% Manage longer signals
if length(ECG) > 10000
    ECG = ECG(:, 1:10000); % Select first 10000 samples
    disp('A signal with more than 10000 samples has been detected.')
    disp('Corrected signal length.')
end


end
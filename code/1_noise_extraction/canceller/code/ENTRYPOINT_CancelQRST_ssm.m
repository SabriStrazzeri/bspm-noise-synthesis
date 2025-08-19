function [entryPointFailed, msg, atrialActivity, atrialActivityOn, atrialActivityOff, QRS, leadStatus, intervalOnset, intervalOffset, ECGavgOnset, ECGavgOffset, beatOn, beatOff] = ENTRYPOINT_CancelQRST_ssm(debug, ECG, leadStatus,  Torso, fs,  NE, research)
%ENTRYPOINT_CancelQRST: interface function for QRST cancellation.
%
%Inputs:
% - debug: 1 for debug mode (save data for offline analysis), 0 otherwise
% - ECG: ECG signals [nL x nS], with nL: amount of leads, nS: amount of
%        recorded samples.
% - leadStatus: nL length array with values 1 for electrodes properly
%               recorded and 0 for electrodes with poor contact at the
%               recording.
% - fs: sampling frequency (in Hz)
% - NE: number of electrodes
% - research: 1 for research mode, 0 otherwise
%
%Outputs:
% - entryPointFailed: 0 if ok, 1 if failed
% - msg: messages resulting from failures or notifications
% - atrialActivity: extracted atrial activity signals
% - atrialActivityOn: onset of atrial activity
% - atrialActivityoff: offset of atrial activity
% - QRS: samples at which QRS complexes are detected
% - leadStatus: nL length array with values 1 for electrodes properly
%               recorded and 0 for electrodes with poor contact at the
%               recording.
%
%Last edited: 25/04/2022, Javier Milagro (javier.milagro@corify.es)
%-------------------------------------------------------------------------

disp('-----------------------------------')
disp('ENTRYPOINT_CancelQRST started.')
disp('-----------------------------------')

%% Inputs inspection
if (nargin < 5) || isempty(fs)
    fs = 1000;
end

if (nargin < 6) || isempty(NE)
    NE = 128;
end

if (nargin < 7) || isempty(research)
    research = 0;
end


%% Configuration
entryPointFailed = 0;
msg = '';
intervalLength = 10; % Only consider 10 seconds for QRS cancellation
QRS = [];

% try

%% Input data parsing
fs = double(fs);
ECG = double(ECG(1 : NE, :));


%% Detect disconected leads in case they are not correctly labeled
isDisconnected = ECGPREPROCESSING_findDisconnectedLeads(ECG);
leadStatus(isDisconnected) = -1;


%% Divide signals in segments

% Initialization of parameters
n_time = size(ECG,2); % Time sample
tam_ventana = 10000; % Window size
solape = 3000; % Overlap size

indices_ini = 1;
indices_final = 10000;

% Create index for the windows of analysis
while indices_final(end) <= n_time
    indices_ini = [indices_ini, indices_final(end) - solape + 1];
    indices_final = [indices_final, indices_ini(end) + tam_ventana - 1];
end

% If the last index is largest than the number of time sample, this
% index is replace with the number of time sample
if indices_final(end) >= n_time
    indices_final(end) = n_time;
end

% If the length of the last window analysis is shorter than 5000, it
% is eliminated and the samples added to the third-to-last window.
if (indices_final(end) - indices_ini(end)) < 6000 %%correction by ines acording to fda report
    indices_final(end-1) = indices_final(end);
    indices_final(end) = [];
    indices_ini(end) = [];
end


%% QRS detection

QRS = ECGDELINEATION_detectQRS(ECG, fs, leadStatus, 'pan-tompkins');


%% Atrial activity extraction

atrialActivityOn_mod = zeros(size(indices_ini,2), 1);
atrialActivityOff_mod = zeros(size(indices_ini,2), 1);
atrialActivity = [];

for i = 1:size(indices_ini,2)

    ECG_analysis = ECG(:, indices_ini(i):indices_final(i));

    % QRS corresponding to the analysis signal
    QRS_analysis = QRS(QRS >= indices_ini(i) & QRS <= indices_final(i));
    QRS_analysis = QRS_analysis - indices_ini(i) + 1;

    % Atrial activity extraction
    [atrialActivity_analysis, atrialActivityOn_analysis, atrialActivityOff_analysis, ~, beatOn, beatOff,ECGavgOnset, ECGavgOffset, ~] = ATRIALACTIVITY_main_ssm(ECG_analysis, fs, QRS_analysis, leadStatus, Torso);

    % atrialActivity onset and offset respect to the whole signal
    atrialActivityOn_mod(i) =  atrialActivityOn_analysis + indices_ini(i)-1;
    atrialActivityOff_mod(i) =  atrialActivityOff_analysis + indices_ini(i)-1;

    % Create concatenate atrial activity
    if i == 1
        atrialActivity = atrialActivity_analysis;
    else
        onset = (atrialActivityOff_mod(i-1) - indices_ini(i) + 1) - atrialActivityOn_analysis + 1;
        offset = atrialActivityOff_analysis - atrialActivityOn_analysis;
        atrialActivity = [atrialActivity, atrialActivity_analysis(:, onset:offset)];
    end

end

atrialActivityOn = atrialActivityOn_mod(1);
atrialActivityOff = atrialActivityOff_mod(end);

% Return only QRS position corresponding to returned cancelled signal
QRS = QRS(QRS >= atrialActivityOn & QRS <= atrialActivityOff);
QRS = QRS - atrialActivityOn + 1;
intervalOnset =0;intervalOffset=0;

end
function [atrialActivity, atrialActivityIni, atrialActivityEnd, QRS, nComponents, ECGavgOnset, ECGavgOffset, BeatTime] = CANCELQRST_main_ssm(ECG, fs, leadStatus, QRS, ECGavg, avgRpos)
%CANCELQRST_main: Cancels the QRST components of an ECG signal.
%
%Inputs:
%  - ECG: ECG signals [nL x nS], where nL: number of leads; nS: number of samples
%  - fs: sampling frequency (in Hz)
%  - leadStatus: nL length array indicating lead status (1: good signal 
%               quality, 0: bad signal quality, -1: disconnected).
%  - QRS: R position (QRSdetect)- QRS: samples at which QRS complexes are detected
%  - ECGavg: averaged QRST signals
%  - avgRpos: position of average R wave
%
%Outputs:
%  - atrialActivity: extracted atrial activity signals
%  - atrialActivityIni: onset of atrial activity
%  - atrialActivityIni: offset of atrial activity
%  - QRS: QRS positions corresponding to the returned atrialActivity
%         interval
%  - nComponents: number of cancelled QRST components
%
%Last edited: 25/04/2022, Javier Milagro (javier.milagro@corify.es) 
%-------------------------------------------------------------------------

%% Check inputs

if (nargin < 3) || isempty(leadStatus)
    leadStatus = ones(size(ECG, 1), 1);
end

% If not provided, detect QRS positions
if (nargin < 4) || isempty(QRS)
    QRS = ECGDELINEATION_detectQRS(ECG, fs, leadStatus);
end

% If not provided, compute average QRST
if (nargin < 6) || isempty(ECGavg) || isempty(avgRpos)
    [ECGavg, avgRpos] = ECGDELINEATION_templateMatchingQRSAvg(QRS, ECG, fs);
end


%% QRST cancellation
if size(ECG, 2) < 10*fs 
    warning('The ECG segment to which QRST cancellation is to be applied might be too short for further DF or drivers analysis  (10 s recommended).')
end

[~,ind_max] = max(vertcat(ECGavg.nbeats));
ECGavg_best = ECGavg(ind_max).BSPM;
% Detect QRS onset and T wave offset

% [QRSon, ~, Toff] = ECGDELINEATION_delineateAverageQRS(ECGavg_best(leadStatus == 1, :), fs, 0);

[ECGavgOnset, ~, ~, ~, ~, ECGavgOffset, ~, ~, ~, ~, ~, ~, ~, BeatTime] = ECGDELINEATION_delineateECG(ECGavg_best, fs, leadStatus, avgRpos);

% Detect template QRS onset and T offset
% ECGavgOnset = max(round(prctile(nonzeros(QRSon),10)), round(fs.*0.04));
% ECGavgOffset = round(prctile(nonzeros(Toff), 90));

% ECGavgOffset = round(median(nonzeros(Toff)));


QRSTlength = size(ECGavg_best, 2);

% Onset and offset of the segment to be analized 
onset = max(1, (avgRpos - ECGavgOnset));
offset = min((ECGavgOffset - avgRpos), QRSTlength);

% Obtain atrial activity by cancelling QRST complexes
[atrialActivity, atrialActivityIni, nComponents] = CANCELQRST_applyCancellation_ssm(ECG, fs, QRS, onset, offset, leadStatus);
atrialActivityEnd = atrialActivityIni+size(atrialActivity,2)-1;

% Return only QRS position corresponding to returned cancelled signal
QRS = QRS((QRS >= atrialActivityIni) & (QRS <= atrialActivityEnd));
QRS = QRS - atrialActivityIni + 1;

end 

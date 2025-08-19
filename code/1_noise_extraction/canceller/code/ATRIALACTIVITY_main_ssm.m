function [atrialActivity, atrialActivityIni, atrialActivityEnd, QRS,  beatOn, beatOff,ECGavgOnset, ECGavgOffset, BeatTime] = ATRIALACTIVITY_main_ssm(ECG, fs, QRS, leadStatus, Torso)
%ATRIALACTIVITY_main: function to extract atrial activity from an ECG
%signal.
%
%Inputs
% - ECG: ECG signals [nL x nS], with nL: amount of leads, nS: amount of recorded samples  
% - fs: sampling frequency (Hz)
% - QRS: samples at which QRS complexes are detected
% - leadStatus: nL length array with values 1 for electrodes properly recorded and 0 for electrodes with poor contact at the recording
% - Torso: torso geometry
%Outputs
% - atrialActivity: extracted atrial activity signals
% - atrialActivityIni: onset of atrial activity
% - atrialActivityEnd: offset of atrial activity
% - QRS: QRS positions corresponding to the returned atrialActivity
%        interval

%Last edited: 25/04/2022, Javier Milagro (javier.milagro@corify.es) 
%-------------------------------------------------------------------------
% Last edited: 04/06/2024 Rubén Molero (ruben.molero@corifycare.es)

[eigenProjections] = ECGDELINEATION_eigenProjectionsTorso(Torso) ;

eigenMap = eigenProjections(:,Torso.bspmCoord(leadStatus>0))*ECG(leadStatus>0,:);

% Obtain template-matching QRS average
%[ECGavg, posRprom] = ECGDELINEATION_templateMatchingQRSAvg_FA(QRS, ECG, eigenMap, fs, leadStatus);
[ECGavg, posRprom, ~, ~, beatOn, beatOff] = ECGDELINEATION_templateMatchingPQRSTAvg_FA_ssm(QRS, ECG, eigenMap, fs, leadStatus);

% Call function to extract atrial activity from QRST cancellation
[atrialActivity, atrialActivityIni, atrialActivityEnd, QRS, ~, ECGavgOnset, ECGavgOffset, BeatTime] = CANCELQRST_main_ssm(ECG, fs, leadStatus, QRS, ECGavg, posRprom);

end
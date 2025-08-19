function [selectedECG, selectedAA, selectedAA_zeros] = convert_to_selected(ECG, atrialActivity, atrialActivityOn, atrialActivityOff, leadStatus)
%convert_to_selected: selects valid data from signals and adds necessary
%padding.
%
%Inputs:
% - ECG: nL (number of leads) x D (duration of ECG) matrix corresponding to
% the ECG signal.
% - atrialActivity: nL (number of leads) x D (duration of ECG) matrix corresponding to
% the cancelled ECG signal.
% - atrialActivityOn: beginning of the cancelled ECG signal.
% - atrialActivityOff: end of the cancelled ECG signal.
% - leadStatus: 1 x nL array with valid (1) and not valid (-1 or 0) leads.
%
%Outputs:
% - selectedECG: processed ECG signal.
% - selectedAA: processed cancelled ECG signal.
% - selectedAA_zeros: processed cancelled ECG signal with zeros padding.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

% Selects good leads in ECG signal
selectedECG = ECG(leadStatus==1, :)';

% Selects good leads in atrial activity signal for graphic representation
selectedAA = [NaN(128, atrialActivityOn), atrialActivity, NaN(128, length(ECG)-atrialActivityOff-1)];
selectedAA = selectedAA(leadStatus == 1, :)';

% Adapts atrial activity signal with zeros for metrics calculation
selectedAA_zeros = [zeros(128, atrialActivityOn), atrialActivity, zeros(128, length(ECG)-atrialActivityOff-1)];
selectedAA_zeros = selectedAA_zeros(leadStatus == 1, :)';


end

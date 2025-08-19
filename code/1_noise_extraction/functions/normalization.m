function [normECG, normCancelledECG] = normalization(ECG, cancelledECG)
%normalization: normalizes data.
%
%Inputs:
% - ECG: ECG signal.
% - cancelledECG: cancelled signal.
%
%Outputs:
% - normData: normalized signal.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

% Normalization of the ECG signal and the cancelled signal
normECG = double(ECG./(max(max(abs(ECG)))));
normCancelledECG = double(cancelledECG./(max(max(abs(ECG)))));

disp('Normalization completed successfully.');


end

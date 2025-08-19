function [isDisconnected, ECG] = ECGPREPROCESSING_findDisconnectedLeads(ECGraw)
%ECGPREPROCESSING_findDisconnectedLeads: Find which leads of an ECG signal  
%are disconnected.
%
%Inputs:
%
%   - ECGraw: raw ECG signals [nL x nS], where nL: number of leads; nS: number of samples
%
%Outputs:
%
%   - isDisconnected: nL length vector with 1 indicating a disconnected lead,
%                   and 0 otherwise
%   - ECG: input ECG, but with rows correcponding to disconnected leads set
%          to 0.
%
%Last edited: 17/05/2021, Javier Milagro (javier.milagro@corify.es) 
%-------------------------------------------------------------------------

% Index of disconnected leads
isDisconnected = (abs(nanmean(diff(ECGraw, 1, 2), 2)) == 0);

% Set disconnected leads to 0
nDisconnected = sum(isDisconnected);
ECG = ECGraw;
ECG(isDisconnected, :) = zeros(nDisconnected, size(ECGraw, 2));


end
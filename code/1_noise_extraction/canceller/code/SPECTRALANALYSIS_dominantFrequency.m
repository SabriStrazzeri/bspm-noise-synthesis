function [DF, Pxx, Fxx] = SPECTRALANALYSIS_dominantFrequency(ECGi, fs, lowerFreqLimit, upperFreqLimit)
%SPECTRALANALYSIS_dominantFrequency: Find the dominant frequency of an ECGi signal.
%
%Inputs:
%
%   - ECGi: result of the inverse problem in the vertices of the atria [nL x nS], 
%         where nL: number of leads; nS: number of samples.
%   - fs: sampling frequency in Hz.
%   - lowerFreqLimit: lower limit of the range within which the dominant
%                   frequency will be looked for.
%   - upperFreqLimit: upper limit of the range within which the dominant
%                   frequency will be looked for.
%
%Outputs:
%
%   - DF: Dominant Frequency in each atria vertex
%   - Pxx: power spectral density of the input signals obtained using the
%          Welch's periodogram methos
%   - Fxx: vector of the frequencies (in Hz) at which Pxx is estimated
%
%
%Last edited: 19/01/2021, Javier Milagro (javier.milagro@corify.es) 
%--------------------------------------------------------------------------

%% Set default frequency limits if not specified as inputs
if (nargin < 3) || isempty(lowerFreqLimit)
    lowerFreqLimit = 4;
end

if (nargin < 4) || isempty(upperFreqLimit)
    upperFreqLimit = 12;
end

%% Variable initialization
nL = size(ECGi, 1); % number of signals
DF = NaN(nL, 1);    % dominant frequency array

%% Compute spectra of the signals
[Pxx, Fxx] = SPECTRALANALYSIS_computeSpectra(ECGi', fs);

%% Find dominant frequency in each signal

% Define search range
range = ((Fxx >= lowerFreqLimit) & (Fxx <= upperFreqLimit));

auxPxx = Pxx(range, :);
auxFxx = Fxx(range);

% Select the dominant frequency of each signal as that with the largest
% spectral amplitude
for i = 1 : nL

    [peaksAmplitude, peaksFrequency] = findpeaks(auxPxx(:, i), auxFxx);
    
    if ~isempty(peaksAmplitude)
        [~, index] = max(peaksAmplitude);
        DF(i) = peaksFrequency(index);
    else
        [~, index] = max(auxPxx(:, i));
        DF(i) = auxFxx(index);
    end
    
end

end


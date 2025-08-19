function [alignedBeats, maxCovLag] = ECGDELINEATION_beatAlignment(beatMatrix, fs, maxLag, extendDisplacedBeats, signal, beatsOnset, beatsOffset, QRS, splineCorrection)
% ECGDELINEATION_beatAlignment align the input beats based on their
% covariance.
% 
% Inputs:
%
% - beatMatrix: matrix containing one beat per column
% - fs: sampling frequency (in Hz)
% - maxLag: maximum allowed misalignment to be corrected (in seconds, 0.05
%           seconds by default)
% - extendDisplacedBeats: if 1, complete missing samples due to displacement 
%                        with samples from the original signal so that all 
%                        the beats have the same number of samples. If 0,
%                         beat length is compelted with NaNs-
% - signal: original signal from which the beats in beatMatrix were
%           extracted. Only required when extendDisplacedBeats = 1.
% - beatsOnset: onset of all the beats in beatMatrix (in samples). 
% - beatsOffset: offset of all the beats in beatMatrix (in samples). Only 
%                required when extendDisplacedBeats = 1.
% - splineCorrection: 1 if cubic spline correction is to be applied to
%                     each beat, 0 (default) otherwise.
%
% Outputs:
%
% - alignedBeats: matrix containing one beat per column. Beats are aligned.
% - maxCovLag: corrected misalignment for each beat in alignedBeats (in samples).
%
% Last edited: 15/09/2021 Javier Milagro (javier.milagro@corify.es)
% -------------------------------------------------------------------------

if nargin < 3 || isempty(maxLag)
    maxLag = 0.05*fs;       % maximum misalignment that can be corrected (50 ms by default)
else
    maxLag = maxLag*fs;
end

if (nargin < 4)
    extendDisplacedBeats = 0; 
    signal = []; 
    beatsOnset = []; 
    beatsOffset = [];
    QRS = [];
end

if (extendDisplacedBeats == 1) && (nargin < 7)
    extendDisplacedBeats = 0; 
    signal = []; 
    beatsOnset = []; 
    beatsOffset = [];
    QRS = [];
    warning('Not enough input arguments to extend displaced beats, extendDisplacedBeats was changed to 0.');
end

if nargin < 8
    QRS = [];
end

if nargin < 9
    splineCorrection = 0;
end

nBeats = size(beatMatrix, 2);

%% Correct misalignment between beats
% Calculate covariance matrix and find the lag of each beat, within a limit
[covMatrix, lags] = xcov(beatMatrix, maxLag);
covMatrix = covMatrix(:, 1 : nBeats);
[~, maxCovLagIdx] = max(abs(covMatrix), [], 1);
maxCovLag = lags(maxCovLagIdx);
maxCovLag(maxCovLag == maxLag) = 0;

% Align all the beats (add nans to fill beat length when shifted
alignedBeats = zeros(size(beatMatrix));
alignedBeats(:, 1) = beatMatrix(:, 1);

for i = 2 : nBeats
    
    if extendDisplacedBeats
        
        if (beatsOffset(i) - maxCovLag(i) > length(signal)) || ((beatsOnset(i) - maxCovLag(i)) < 1)
            % Discard this beat
            alignedBeats(:,i) = nan(size(beatMatrix, 1), 1);
        else
            % Align beats and extend signal in the sides
            beat = signal((beatsOnset(i) : beatsOffset(i)) - maxCovLag(i));

            if ~isempty(QRS) && splineCorrection
                offsetCorrection = ECGDELINEATION_offsetCorrection(beat, QRS(i) - beatsOnset(i) - maxCovLag(i), fs);
            else
                offsetCorrection = 0;
            end
            
            alignedBeats(:,i) = beat - offsetCorrection;
%             alignedBeats(:,i) = signal((beatsOnset(i) : beatsOffset(i)) - maxCovLag(i));

        end
       
    else
        
        % Align beats and fill with NaNs
        alignedBeats(:,i) = circshift(beatMatrix(:, i), maxCovLag(i));
        
        if maxCovLag(i) < 0
            alignedBeats(end - abs(maxCovLag(i)) + 1 : end, i) = nan(abs(maxCovLag(i)), 1);
        else
            alignedBeats(1 : maxCovLag(i), i) = nan(maxCovLag(i), 1); 
        end
        
    end
    
end

alignedBeats(:, sum(isnan(alignedBeats), 1) == size(alignedBeats, 1)) = [];

end
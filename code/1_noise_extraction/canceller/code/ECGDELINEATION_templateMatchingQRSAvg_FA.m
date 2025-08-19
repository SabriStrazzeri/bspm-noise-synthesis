function [ECGavg, avgRLocation, nUSedBeats, templateMatchingThreshold] = ECGDELINEATION_templateMatchingQRSAvg_FA(QRS, ECG, eigenMap, fs, leadStatus, splineCorrection)
%ECGDELINEATION_templateMatchingQRSAvg: Template-matching average of a an 
%ECG signal. Template-matching is based on the morphological similarity of 
%using Laplacian Eigenmaps and clustering. Only those beats whose 
% cross-correlation surpases a predefined threshold are averaged. 
%If there are more than 3 clusters in 20 beats, the correlation theshold 
%is decreased a 20%.
%
%Inputs:
%   - QRS: position of R waves
%   - ECG: ECG signals [nL x nS], where nL: number of leads; nS: number of 
%          samples
%   - eigenMap: Laplacian Eigenmaps 
%   - fs: sampling frequency in Hz
%   - leadStatus: nL length array with values 1 for electrodes properly 
%                 recorded and 0 for electrodes with poor contact at the 
%                 recording.
%   - splineCorrection: 1 if cubic spline correction is to be applied to
%                       each beat, 0 (default) otherwise.
%
%Outputs:
%   - ECGavg: average QRS matrix of size [nL x nSQRS], where nL: number of 
%       leads; nSQRS: number of samples of the QRS complex.
%   - avgRLocation: position of the R wave in the average QRS.
%   - nUsedBeats: number of beats used for the average QRS calculated for
%       each lead.
%   - templateMatchingThreshold: final correlation threshold calculated for
%       each lead.
%
% Last edited: 15/09/2021, Javier Milagro (javier.milagro@corify.es) 
% 27/02/2024, Ismael Hernández
% 23/10/24, Branch from regular version, Ines Llorente, update for loop,
% control number of clusters, change qrs onset to be 0.2 better for FA
% -------------------------------------------------------------------------

% Check inputs
if (nargin < 5) || isempty(leadStatus)
    leadStatus = ones(size(ECG, 1), 1);
end

if (nargin < 6) || isempty(splineCorrection)
    splineCorrection = 0;
end

% Initialize initial guest of maximum clusters 
%% change respect to current version Nclusters = 15;
% Initialize correlation threshold
corrTh = 0.9;
% Initialize amplitude threshold
ampTh = 0.33;

% Percentajes of mean RR applied to the PR and RT intervals
%PRpercentage = 0.4;
PRpercentage = 0.2; %%change to 0.2 percent, les qrs to fa
RTpercentage = 0.6;

% Computation of mean RR, PR and RT intervals
meanRR = mean(diff(QRS));
PonRinterval = floor(PRpercentage*meanRR);
RToffinterval = ceil(RTpercentage*meanRR);

% Not consider those beats very close to the borders
QRS((QRS - PonRinterval) < 1) = [];
QRS((QRS + RToffinterval) > size(ECG, 2)) = [];

% Define beat onset and offset
beatOn = QRS - PonRinterval;
beatOff = QRS + RToffinterval;

% Initialize some required variables
nLeads = size(ECG, 1);
nBeats = length(QRS);
beatLength = PonRinterval + RToffinterval + 1;  
nUSedBeats = zeros(nLeads, 1);
templateMatchingThreshold = zeros(nLeads, 1);

% Create a beat matrix with all the beats to be considered
beatMatrix = zeros(nBeats, beatLength);
w_filt = round(0.1*meanRR); w_filt = w_filt + (1-mod(w_filt,2));


Nclusters = min([nBeats, 15]);

for i = 1 : nBeats

    beat = ECG(:, beatOn(i) : beatOff(i)); 

    beat_filt = sgolayfilt(beat, 4, w_filt,[], 2);
    beat_diff = abs(diff(beat_filt,1,2));
    ind_bw = beat_diff<(0.02*max(beat_diff,[],2)); 
    mask_bw = double([ind_bw(:,1) ind_bw]);
    mask_bw = double(any(mask_bw,2));
    beat = beat - median(beat.* mask_bw,2,'omitnan'); 

    beat3D(i, :, :) = permute(beat,[3 2 1]); 

    beatBETA = eigenMap(5, beatOn(i) : beatOff(i));
    beatMatrix(i, :) = beatBETA;

end

    % Align beats
    beatMatrix = ECGDELINEATION_beatAlignment(beatMatrix', fs, 0.05, 1, eigenMap(5, :), beatOn, beatOff, QRS, splineCorrection);
    beatMatrix = beatMatrix';

    S = mdwtcluster(beatMatrix,'maxclust',Nclusters);
    IdxCLU = S.IdxCLU;

    % Compute labels between mean of clusters by correlation
    for iicluster = 1:Nclusters

        Avg_cluster(iicluster,:) = mean(beatMatrix(IdxCLU(:,1)==iicluster,:), 1);
    end
    [~,~,label_Clusters] = unique(corrcoef(Avg_cluster')>=corrTh ,'rows');

    % Compute average beat per label
    for iilabels = 1:max(label_Clusters)

        indx_LAB = ismember(IdxCLU(:,1),find(label_Clusters==iilabels));

        BSPM = squeeze(mean(beat3D(indx_LAB,:,:), 1))';

        ECGavg(iilabels).BSPM = BSPM;
        ECGavg(iilabels).nbeats = sum(indx_LAB);
    end

    if size(ECGavg,2) > 3*(nBeats/20)
        ECGavg = [];

        [~,~,label_Clusters] = unique(corrcoef(Avg_cluster')>=corrTh-0.2 ,'rows');
    
        % Compute average beat per label
        for iilabels = 1:max(label_Clusters)
    
            indx_LAB = ismember(IdxCLU(:,1),find(label_Clusters==iilabels));
    
            BSPM = squeeze(mean(beat3D(indx_LAB,:,:), 1))';
    
            ECGavg(iilabels).BSPM = BSPM;
            ECGavg(iilabels).nbeats = sum(indx_LAB);
        end
    end
   
% Location of the average R wave
avgRLocation = PonRinterval;

end
function [atrialActivity, atrialActivityIni, nComponents, DF, CE] = CANCELQRST_applyCancellation_ssm(ECG, fs, QRS, onset, offset, leadStatus)

%% Initialize variables
nLeads = size(ECG, 1);
CE = zeros(1, nLeads);  
DF = zeros(1, nLeads);  
nComponents = zeros(1, nLeads);
atrialActivity = nan(size(ECG));

% % High pass filter
% [B1, A1] = butter(5, 2.5/(fs/2), 'high');

% % Low pass filter
% [B2, A2] = butter(5, 30/(fs/2));

% Maximum number of components to cancel
nMaxComponents = 4;
auxCE = zeros(nMaxComponents, 1);

% Weights applied to decide the optimum number of components to cancel
weightsCE = logspace(0, -0.05, nMaxComponents)';


%% CANCEL QRST

% Number of beats
nBeats = length(QRS);

% For each lead
for k = 1:nLeads  
    
    % Only apply cancellation to good quality leads, otherwise a vector of
    % zeros is returnes
    if leadStatus(k) > 0
        
        % Create beat matrix containg all the beats in a lead 
        % First and last beats are not included for protection
        if (QRS(2) - onset) < 1
            firstBeat = 2;
        else
            firstBeat = 1;
        end
        
        if (QRS(end - 1) + offset) > size(ECG, 2)
            lastBeat = nBeats - 3;
        else
            lastBeat = nBeats - 2;
        end    
               
        beatMatrix = zeros(lastBeat - firstBeat + 1, onset + offset + 1);
        
        for i = firstBeat : lastBeat
            beatMatrix(i, :) = ECG(k, QRS(i+1) - onset : QRS(i+1) + offset);
        end 

        % Align beats in beatMatrix
        [beatMatrix, shift] = ECGDELINEATION_beatAlignment(beatMatrix', fs, 0.05, 1, ECG(k, :), QRS(firstBeat + 1 : lastBeat + 1) - onset, QRS(firstBeat + 1 : lastBeat + 1) + offset);
        beatMatrix = beatMatrix';

        % Obtain principal components
        [whitesig, ~, DWM] = CANCELQRST_independentComponentAnalysis(beatMatrix, 'only', 'white');
                         
        % Cancel principal components
        [AA, atrialActivityIni, ~, ~,~] = CANCELQRST_principalComponentsCancellation(ECG(k, :), QRS, onset + shift, offset - shift, firstBeat, lastBeat, beatMatrix, whitesig, DWM, nMaxComponents);
         
        % Filter atrialActivity
        % AA = filtfilt(B1, A1, AA');
        % AA = filtfilt(B2, A2, AA)';
        AA = AA - mean(AA, 2);

        % Select optimum number of components to cancel based on spectral analysis
        for i = 1: size(AA, 1)
            [auxDF(i), Pxx, Fxx] = SPECTRALANALYSIS_dominantFrequency(AA(i, :), fs);
            auxCE(i) = SPECTRALANALYSIS_calculateRelativePowerInDF(Pxx, Fxx, auxDF(i));
        end
        
%         [~, nComponents(k)]= max(auxCE.*weightsCE);
        nComponents(k) = 4;

        %%%%%%%%%%%%%%%%%%%%%%%%
%         tAA = atrialActivityIni:size(AA,2)+atrialActivityIni-1;
%         figure
%         subplot(2,2,1)
%         color = {'r','r','r','r'};
%         color{nComponents(k)} = 'g';
%         plot(ECG(k, :)), hold on, plot(tAA, AA(1,:), color{1}, 'Linewidth', 1), hold off
%         title(['# comp. = 1, CE = ' num2str(auxCE(1)) ', CEadj = ' num2str(auxCE(1)*weightsCE(1))])
%         subplot(2,2,2)
%         plot(ECG(k, :)), hold on, plot(tAA,AA(2,:), color{2}, 'Linewidth', 1), hold off
%         title(['# comp. = 2, CE = ' num2str(auxCE(2)) ', CEadj = ' num2str(auxCE(2)*weightsCE(2))])
%         subplot(2,2,3)
%         plot(ECG(k, :)), hold on, plot(tAA,AA(3,:), color{3}, 'Linewidth', 1), hold off
%         title(['# comp. = 3, CE = ' num2str(auxCE(3)) ', CEadj = ' num2str(auxCE(3)*weightsCE(3))])
%         subplot(2,2,4)
%         plot(ECG(k, :)), hold on, plot(tAA,AA(4,:), color{4}, 'Linewidth', 1), hold off
%         title(['# comp. = 4, CE = ' num2str(auxCE(4)) ', CEadj = ' num2str(auxCE(4)*weightsCE(4))])
        %%%%%%%%%%%%%%%%%%%%%%%%

        DF(k) = auxDF(nComponents(k));
        CE(k) = auxCE(nComponents(k));
        atrialActivity(k, 1:size(AA, 2)) = AA(nComponents(k), :);
               
    else     
        atrialActivity(k, :) = zeros(1, size(ECG, 2));
    end
end

atrialActivity(:, sum(isnan(atrialActivity), 1) > 0) = [];

end

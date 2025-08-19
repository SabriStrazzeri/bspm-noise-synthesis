function [atrialActivity, atrialActivityIni, nComponents, DF, CE] = CANCELQRST_principalComponentsCancellation(ECG, QRS, onset, offset, firstBeat, lastBeat, beatMatrix, whitesig, DWM, nMaxComponents )

%% Initialize variables
DF = zeros(nMaxComponents, 1);
CE = zeros(nMaxComponents, 1);
nComponents = [];
nCol = size(DWM, 2);

atrialActivityIni = QRS(firstBeat) + offset(1);
atrialActivityEnd = QRS(lastBeat+2) - onset(1);
atrialActivity = zeros(nMaxComponents, atrialActivityEnd - atrialActivityIni + 1);

originalECG = ECG;

% For each number of components
for nc = 1:nMaxComponents    

    % Preserve only nc components
    auxDWM = DWM(:, max([1, (nCol - nc + 1)]) : nCol);
    auxwhitesig = whitesig(max([1, (nCol - nc + 1)]) : nCol, :);

    % Estimate the QRST as the combiantion of the selected components
    QRST = auxDWM*auxwhitesig;
    
    % Atrial activity is obtained by susbtracting QRST from each beat
    AA = beatMatrix - QRST;

    % Map atrial activity to its adequate time location
    ECG = originalECG;
    
    for i = firstBeat : lastBeat
        
        % Calculate offset of initial and final sample
        initialOffset = ECG(QRS(i+1)-onset(i))-AA(i,1);
        finalOffset = ECG(QRS(i+1)+offset(i))-AA(i,end);
        
        % Compute and apply offset correctiom
        offsetCorrection = linspace(initialOffset, finalOffset, size(AA, 2));
        ECG(QRS(i+1) - onset(i) : QRS(i+1) + offset(i)) = AA(i, :) + offsetCorrection;
        
    end
    
    atrialActivity(nc, :) = ECG(atrialActivityIni : atrialActivityEnd);
        
end

end

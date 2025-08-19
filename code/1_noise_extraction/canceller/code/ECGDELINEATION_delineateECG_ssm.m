function [Pon, Poff, QRSon, QRSoff, Ton, Toff, QRS, Ptime, QRStime, Ttime, PQtime, STtime, QTtime, beatTime] = ECGDELINEATION_delineateECG_ssm(ECG, fs, leadStatus, QRS, rhythmType, onlyLargestRR)
%ECGDELINEATION_delineateAverageQRS: Delineates an ECG signal, detecting 
%the onset and offset of the main waves.
%
%Inputs:
%   ECG: ECG signals [nL x nS], where nL: number of leads; nS: number of 
%       samples
%   fs: sampling frequency in Hz
%   leadStatus: nL length array indicating lead status (1: good signal 
%               quality, 0: bad signal quality, -1: disconnected)
%   QRS: position of QRS complexes
%   rhythmType:scalar value which indicates the rhyhtm Type of the episode
%              0 -> AF
%              1 -> SR
%   onlyLargestRR: if 1, only delineation for the beat corresponding to the
%                  largest RR is returned. 0 by default.
%
%Outputs:
%   Pon: onset of the P wave.
%   Poff: onffet of the P wave.
%   QRSon: onset of the QRS complex.
%   QRSoff: offset of the QRS complex.
%   Ton: onset of the T wave.
%   Toff: offset of the T wave.
%   Ptime: duration of the P wave. 
%   QRStime: duration of the QRS complex.
%   Ttime: duration of the T wave.
%   PQintTime: duration of the PQ interval.
%   STintTime: duration of the ST interval.
%   QTintTime: duration of the QT interval.
%   BeatTime: duration of the beat.
%
%
% Last edited: 03/11/2021, Marta Martínez (marta.martinez@corify.es) 
% Last edited: 04/10/2022, Javier Milagro (javier.milagro@corify.es) 
%-------------------------------------------------------------------------

% If input QRS is missing, call function ECGDELINEATION_detectQRS
if (nargin < 4)
    QRS = ECGDELINEATION_detectQRS(ECG, fs, leadStatus, 'pan-tompkins');
end 

% If input rhythmType is missing, assumed Sinusal Rhythm
if (nargin < 5)
    rhythmType = 'SR'; 
end 

% By default return delineation of all beats
if (nargin < 6)
    onlyLargestRR = 0; 
end 

% Definition of the percentiles
percSup = 70; 
percInf = 30;

% Memory preallocation
nBeats = length(QRS);
Pon = NaN(1, nBeats);
Poff = NaN(1, nBeats);
Ton = NaN(1, nBeats);
Toff = NaN(1, nBeats);
QRSon = NaN(1, nBeats);
QRSoff = NaN(1, nBeats);

% Initial padding needed
C = ECGDELINEATION_constants(fs);
iniPad = C.l5;
endPad = C.d5;

ECG = ECG(leadStatus == 1, :);

ECG = [repmat(ECG(:, 1), 1, iniPad) ECG repmat(ECG(:, end), 1, endPad)];
QRSaux = QRS + iniPad;

parfor i = 1:size(ECG, 1)
    try
        position = ECGDELINEATION_WTdelineation(ECG(i, :)', double(QRSaux), fs);
        Pon(i, :) = position.Pon - iniPad;
        Poff(i, :) = position.Poff - iniPad;
        Toff(i, :) = position.Toff - iniPad;
        Ton(i, :) = position.Ton - iniPad;
        QRSon(i, :) = position.QRSon - iniPad;
        QRSoff(i, :) = position.QRSoff - iniPad;
    catch
        Pon(i, :) = NaN;
        Poff(i, :) = NaN;
        Toff(i, :) = NaN;
        Ton(i, :) = NaN;
        QRSon(i, :) = NaN;
        QRSoff(i, :) = NaN;
    end
end

Pon = floor(prctile(Pon, percInf, 1)); 
Poff = ceil(prctile(Poff, percSup, 1)); 
QRSon = floor(prctile(QRSon, percInf, 1)); 
QRSoff = ceil(prctile(QRSoff, percSup, 1));
Ton = floor(prctile(Ton, percInf, 1));
Toff = ceil(prctile(Toff, percSup, 1));

% Waves/interval durations 
Ptime = (Poff - Pon)/fs; 
QRStime = (QRSoff - QRSon)/fs; 
Ttime = (Toff - Ton)/fs; 
PQtime = (QRSon - Pon)/fs; 
STtime = (Ton - QRSoff)/fs;
QTtime = (Toff - QRSon)/fs;
beatTime = (Toff - Pon)/fs; 

% If signal is AF
if strcmp(rhythmType, 'AF')
    Pon = NaN(1, nBeats); 
    Poff = NaN(1, nBeats); 

    Ptime =  NaN(1, nBeats); 
    PQtime =  NaN(1, nBeats);
    
    beatTime = (Toff - QRSon)/fs; 
end 

% If only delineation of the beat with largest RR is to be returned
if onlyLargestRR
    
    % Find index of beat with largest preceding RR
    [~, beatIdx] = max(diff(QRS));
    beatIdx = beatIdx + 1;
    
    % Protection in case selected beat is last beat
    if (beatIdx == length(QRS)) && ((QRS(beatIdx) + 300) > size(ECG, 2))
        
        % Select second largest RR interval
        [~, beatIdx] = max(diff(QRS(1:end-1)));
        beatIdx = beatIdx + 1;
        
    end
    
    Pon = Pon(beatIdx);
    Poff = Poff(beatIdx);
    QRSon = QRSon(beatIdx);
    QRSoff = QRSoff(beatIdx);
    Ton = Ton(beatIdx);
    Toff = Toff(beatIdx);
    QRS = QRS(beatIdx);
    Ptime = Ptime(beatIdx);
    QRStime = QRStime(beatIdx);
    Ttime = Ttime(beatIdx);
    PQtime = PQtime(beatIdx);
    STtime = STtime(beatIdx);
    QTtime = QTtime(beatIdx);
    beatTime = beatTime(beatIdx);
    
end

end
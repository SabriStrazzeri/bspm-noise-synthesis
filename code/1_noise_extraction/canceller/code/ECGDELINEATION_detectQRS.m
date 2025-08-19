function [QRS, ecgm, thSignal, thNoise, spki, npki] = ECGDELINEATION_detectQRS(ECG, fs, leadStatus, detectorType, qrsPrev, thSignalPrev, thNoisePrev, spkiPrev, npkiPrev)
%ECGDELINEATION_detectQRS: QRS detector.
%
%Inputs:
%     - ECG: ECG signals [nL x nS], where nL: number of leads; nS: number of samples
%     - fs: sampling frequency in Hz
%     - leadStatus: nL length array indicating lead status (1: good signal 
%                   quality, 0: bad signal quality, -1: disconnected).
%     - detectorType: select the QRS detector approach to be used from
%                    'tiralineas' (default) or 'pan-tompkins'. On-line
%                    detection is only available with 'pan-tompkins'.
%     - qrsPrev: positions of the QRS already detected in the ecg
%                signal segment under analysis (only for on-line
%                detection)
%     - thSignalPrev: signal threshold employed for the previous
%                     detections (only for on-line detection)
%     - thNoisePrev: noise threshold employed for the previous
%                    detections (only for on-line detection)
%     - spkiPrev: signal level employed for the previous
%                 detections (only for on-line detection)
%     - npkiPrev: noise level employed for the previous
%                 detections (only for on-line detection)
%
%Outputs:
%     - QRS: position of QRS complexes
%     - ecgm: pulse-like signal employed for QRS detection (only for 
%             'pan-tompkins')
%     - thSignal: last signal threshold employed for QRS detection (only
%                 for 'pan-tompkins')
%     - thNoise: last noise threshold employed for QRS detection (only
%                for 'pan-tompkins')
%     - spki: last signal level employed for QRS detection (only
%             for 'pan-tompkins')
%     - npki: last noise level employed for QRS detection (only
%             for 'pan-tompkins')
%
%Last edited: 26/04/2021, Javier Milagro (javier.milagro@corify.es) 
%Last modified: 01/02/2022, Marta Martínez (marta.martinez@corify.es) 
%-------------------------------------------------------------------------

bradycardiaTh = 0.4; % if < 30bpm, reuturn empty QRS vector

if (nargin >= 3) && (~isempty(leadStatus))
    ECG = ECG(leadStatus > 0, :);
end

if (nargin < 4)
    detectorType = 'pan-tompkins';
end

if strcmp(detectorType, 'pan-tompkins')
    if nargin < 5
        qrsPrev = [];
        thSignalPrev = [];
        thNoisePrev = [];
        spkiPrev = [];
        npkiPrev = [];
    end

    if nargin < 6
        thSignalPrev = [];
        thNoisePrev = [];
        spkiPrev = [];
        npkiPrev = [];
    end

    if nargin < 7
        thNoisePrev = [];
        spkiPrev = [];
        npkiPrev = [];
    end

    if nargin < 8
        spkiPrev = [];
        npkiPrev = [];
    end

    if nargin < 9
        npkiPrev = [];
    end
end

switch detectorType
    
    case 'tiralineas'
        
        try
            QRS = ECGDELINEATION_tiralineasQRSDetector(ECG, fs);
        catch
            QRS = [];
        end
        
        ecgm = [];
        thSignal = [];
        thNoise = [];
        spki = [];
        npki = [];
        
    case 'pan-tompkins'
        
        try
            [QRS, ecgm, thSignal, thNoise, spki, npki] = ECGDELINEATION_PanTompkinsQRSDetector(ECG, fs, qrsPrev, thSignalPrev, thNoisePrev, spkiPrev, npkiPrev);
        catch
            QRS = [];
        end
        
    otherwise
        error('Wrong detector type indicated.')
end

% If the number of detected beats is not physiological, return empty vector
if length(QRS) < (size(ECG, 2)/fs)*bradycardiaTh
    QRS = [];
end

end

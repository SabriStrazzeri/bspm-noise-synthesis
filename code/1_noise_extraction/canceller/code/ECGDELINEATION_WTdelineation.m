function position = ECGDELINEATION_WTdelineation(ECG, QRS, fs)
% Single lead delineation based on wavelet transform

% Inputs:
%   - ECG: ECG signal (single lead) to be delienated
%   - QRS: position of QRS complexes
%   - fs: sampling frequency in Hz
%
% Outputs:
%	- position: struct vector with the detected points locations in samples
%            .Pon: P wave onset
%              .P: P wave peak
%           .Poff: P wave end
%          .QRSon: QRS complex onset
%              .Q: Q wave peak (in multilead, according to QRSonset best fitted lead)
%      .R_inQRSon: R wave peak in QRSonset best fitted lead (multilead only)
%              .R: R wave peak (median mark in multilead approach)
%            .qrs: QRS complex fiducial mark
%     .R_inQRSoff: R wave peak in QRSend best fitted lead (multilead only)
%         .Rprima: R' wave peak (in multilead, according to QRSend best fitted lead)
%              .S: S wave peak (in multilead, according to QRSend best fitted lead)
%         .QRSoff: QRS complex end
%            .Ton: T wave onset
%              .T: first T wave peak (median mark in multilead approach)
%         .Tprima: second T wave peak (in multilead, according to Tend best fitted lead)
%           .Toff: T wave end
%          .Ttipo: T wave morphology (1:5 corresponding respectively to normal, inverted, upwards only, downwards only, biphasc pos-neg, biphasc neg-pos)
%         .Tscale: scale used for T wave detection
%        .Ttipoon: T wave morphology, according to Tonset best fitted lead (multilead only)
%       .Ttipooff: T wave morphology, according to Tend best fitted lead (multilead only)

%% Variable initialization
% Load constants
C = ECGDELINEATION_constants(fs);

q1 = C.q1;
q2 = C.q2;
q3 = C.q3;
q4 = C.q4;
q5 = C.q5;
l1 = C.l1;
l2 = C.l2;
l3 = C.l3;
l4 = C.l4;
l5 = C.l5;
d1 = C.d1;
d2 = C.d2;
d3 = C.d3;
d4 = C.d4;
d5 = C.d5;

% Number of samples for the WT (corresponding to 2^16 samples at fs = 250)
nSampWT = round(2^16/250*fs); 

% Signal length
nSampSig = length(ECG);
t = [1 nSampSig];

if (nargin < 2) || isempty(QRS)
    detectQRS = 1; % If no QRS marks are provided, detect QRS
    maxlength = round((t(2) - t(1))/fs*3); % Estimated max number of beats
else
    detectQRS = 0;
    maxlength = length(QRS);
end

% Initialize position struct, which contains all the delineation marks
nanvec = nan(1,maxlength);
position = struct('Pon', nanvec, 'P', nanvec, 'Poff', nanvec, ...
                  'Pprima', nanvec, 'Pscale', nanvec, 'Ptipo', nanvec,...
                  'QRSon', nanvec, 'Q', nanvec, 'R', nanvec, 'Rprima', nanvec, ...
                  'S', nanvec, 'QRSoff', nanvec, 'qrs', zeros(1, maxlength), ...
                  'R_inQRSoff', nanvec, 'R_inQRSon', nanvec, ...
                  'Ton', nanvec, 'T', nanvec, 'Tprima', nanvec, 'Toff', nanvec, 'Ttipo', nanvec, ...
                  'Tscale', nanvec, 'Ttipoon', nanvec, 'Ttipooff', nanvec, 'contadorToff', nanvec, ...
                  'QRSonsetcriteria', nanvec, 'QRSoffcriteria', nanvec, ...
                  'QRSpa', nanvec, 'QRSpp', nanvec, ...
                  'QRSmainpos', nanvec, 'QRSmaininv', nanvec);


% Batch processing initialization
% Segment overlap (in case signal needs to be processed in batches)
begoverlap = l5 + 2*fs;    % l5 + 2 secs to ensure that the last/first beat
                           % are completely within the batch
endoverlap = d5;

samp = 1;           % Initial sample
inisamp = t(1);     % Initial time
endsamp = t(1) - 1; % Final time

ultimo_anot = 1;    % Last annotation
ultimo_anottyp = 0; % Last annotation type

while ((endsamp + 1) < t(2))
    
    %% Determine segment to process
    firstnewsamp = samp(end);
    endsamp = min(inisamp + nSampWT - 1, t(2));
    
    % Signal segment
    sig = ECG(inisamp - t(1) + 1 : min(endsamp - t(1) + 1, size(ECG, 1)));
    sig = sig(:);

    %% Wavelet transform  
    wt = zeros(length(sig), 5);
    wt(:,1) = filter(q1, 1, sig);
    wt(:,2) = filter(q2, 1, sig);
    wt(:,3) = filter(q3, 1, sig);
    wt(:,4) = filter(q4, 1, sig);
    wt(:,5) = filter(q5, 1, sig);
    
    % Remove "incorrect" samples
    % First l5 - 1 samples are not correctly filtered (border effect)
    % Last d5 samples are discarded in order to alineate all the filtered 
    % signals, taking into acount the filter delays.
    wt = wt(l5 : end, 1 : 5);            
    samp = (inisamp + l5 -1) : endsamp - d5;
    
    % Synchronize filtered signals at different scales
    w1 = zeros(size(wt, 1) - d5, 5);
    w1(:,5) = wt(d5 + 1 : end, 5);
    w1(:,4) = wt(d4 + 1 : end + d4 - d5, 4);
    w1(:,3) = wt(d3 + 1 : end + d3 - d5, 3);
    w1(:,2) = wt(d2 + 1 : end + d2 - d5, 2);
    w1(:,1) = wt(d1 + 1 : end + d1 - d5, 1);
    
    % Piece of signal processed in this iteration
    sig = sig(l5 : end - d5, :); 
    
    clear wt
    
    %% Beat detection        
    if detectQRS   % If QRS position is not provided, it is calculated

        QRS = ECGDELINEATION_detectQRS(sig(:)', fs, 1, 'pan-tompkins');
        QRS = QRS + samp(1) - 1;
        
    end 

    % Only consider detections within the analyzed batch
    first = max(firstnewsamp - fs, samp(1) - 1 + ceil(fs*0.050));
    sel = find(QRS >= first & QRS <= samp(end));
    position.qrs(1 : length(QRS)) = QRS(:)';
    timeqrs = [];
    timeqrs(1, sel) = position.qrs(sel) - samp(1) + 1;
    time = timeqrs(1, sel);
    indexes = 1 : length(timeqrs(1, :));
    
    % Set analysis interval to that comprised between first and last QRS
    % detections
    if ~isempty(sel)
        intervalo = [sel(1) sel(end)];
    else
        intervalo = [];
    end

    intervalo1 = intervalo;
    time1 = time;

    if ~isempty(time) 
        
        %%  QRS delineation
        QRSon = indexes(:, intervalo(1) : intervalo(end));
        qrspiconsetall = nan(3, intervalo(end) - intervalo(1) + 1);
        
        if ~isempty(intervalo)
            
            [position, qrspiconset1] = ECGDELINEATION_qrswavef(samp, time, position, w1, intervalo, fs);
            qrspiconsetall(1, (~isnan(indexes(1, intervalo(1) : intervalo(end))) & (QRSon(1, :) >= intervalo(1) & QRSon(1, :) <= intervalo(2)))) = qrspiconset1(QRSon(1, ~isnan(QRSon(1, :)) & (QRSon(1, :) >= intervalo(1) & QRSon(1, :) <= intervalo(2))) - intervalo(1) + 1);
            
        end

        auxqrspiconset = min(qrspiconsetall);
        aux = find(isnan(auxqrspiconset));
        
        if ~isempty(aux)  % one beat is from the former interval
            intervalo(end) = intervalo(end) - aux(end); 
        end

        % Protection with respect to ultimo_anot
        while position.QRSon(intervalo(1)) < ultimo_anot
            if ultimo_anottyp == 10 % Toff
                if (position.qrs(intervalo(1)) - position.QRSon(intervalo(1))) < (position.Toff(intervalo(1) - 1) - position.T(intervalo(1) - 1))
                    position.Toff(intervalo(1) - 1) = NaN;
                    if isnan(position.Tprima(intervalo(1) - 1))
                        ultimo_anot = position.T(intervalo(1) - 1);
                        ultimo_anottyp = 8;
                    else
                        ultimo_anot = position.Tprima(intervalo(1) - 1);
                        ultimo_anottyp = 9;
                    end
                else
                    position.QRSon(intervalo(1)) = NaN;
                end
            elseif (ultimo_anottyp == 9) || (ultimo_anottyp == 8) || (ultimo_anottyp == 5) % Tprima | Tpeak | qrs
                position.QRSon(intervalo(1)) = NaN;
            else  % ultimo_anottyp == 6 % QRSoff
                if (position.qrs(intervalo(1)) - position.QRSon(intervalo(1))) < (position.QRSoff(intervalo(1) - 1) - position.qrs(intervalo(1) - 1))
                    position.qrsoff(intervalo(1) - 1) = NaN;
                    ultimo_anot = position.qrs(intervalo(1) - 1);
                    ultimo_anottyp = 5;
                else
                    position.QRSon(intervalo(1)) = NaN;
                end
            end
        end
        
        %% T wave delineation
        position = ECGDELINEATION_twavef(samp, time1, position, w1, intervalo1, fs); 
        
        % Condition position struct
        position.QRSon(position.R <= (position.QRSon + 1)) = NaN;
        position.QRSoff(position.QRSoff >= (position.Ton - 1)) = NaN;
        position.QRSoff(position.QRSoff >= (position.T - 1)) = NaN;
        position.QRSoff(position.QRSoff <= (position.qrs + 1)) = NaN;
        position.QRSoff(position.R >= (position.QRSoff - 1)) = NaN;
        position.Toff(position.Toff <= (position.T + 1)) = NaN;
        position.Ton(position.Ton >= (position.T - 1)) = NaN;
        ii = 1 : sum(position.qrs > 0);
        position.QRSoff(position.QRSoff(ii(1 : end - 1)) >= (position.R(ii(2 : end)))) = NaN;
        position.QRSoff(position.QRSoff(ii(1 : end - 1)) >= (position.qrs(ii(2 : end)))) = NaN;
        position.Toff(position.Toff(ii(1 : end - 1)) >= position.qrs(ii(2 : end))) = NaN;

        %% P wave delineation
        position = ECGDELINEATION_pwavef(samp, time, position, w1, intervalo, ultimo_anot, fs);
        
        % Set adequate position struct size
        position.Pon((length(position.Pon) + 1) : length(position.qrs)) = NaN; 
        position.P((length(position.P) + 1) : length(position.qrs)) = NaN; 
        position.Poff((length(position.Poff) + 1) : length(position.qrs)) = NaN; 
        position.Poff((length(position.Poff) + 1) : length(position.qrs)) = NaN; 

        
        %% Last annotated position
        if intervalo(2) > 0

            if ~isnan(position.Toff(min(intervalo(2), length(position.Toff))))
                ultimo_anot = position.Toff(min(intervalo(2), length(position.Toff)));
                ultimo_anottyp = 10;
            elseif ~isnan(position.Tprima(min(intervalo(2), length(position.Tprima))))
                ultimo_anot = position.Tprima(min(intervalo(2), length(position.Tprima)));
                ultimo_anottyp = 9;
            elseif ~isnan(position.T(min(intervalo(2), length(position.T))))
                ultimo_anot = position.T(min(intervalo(2), length(position.T)));
                ultimo_anottyp = 8;
            elseif ~isnan(position.QRSoff(min(intervalo(2), length(position.QRSoff))))
                ultimo_anot = position.QRSoff(min(intervalo(2), length(position.QRSoff)));
                ultimo_anottyp = 6;
            else
                ultimo_anot = ceil(position.qrs(min(intervalo(2), length(position.qrs))));
                ultimo_anottyp = 5;
            end

        end
    end 
    
    inisamp = endsamp + 2 - endoverlap - begoverlap;
    
end

%% Condition position struct before return
position.Pon((length(position.Pon) + 1) : length(position.qrs)) = NaN;
position.P((length(position.P) + 1) : length(position.qrs)) = NaN;
position.Pprima((length(position.Pprima) + 1) : length(position.qrs)) = NaN;
position.Poff((length(position.Poff) + 1) : length(position.qrs)) = NaN;
position.Ton((length(position.Ton) + 1) : length(position.qrs)) = NaN;
position.T((length(position.T) + 1) : length(position.qrs)) = NaN;
position.Tprima((length(position.Tprima) + 1) : length(position.qrs)) = NaN;
position.Toff((length(position.Toff) + 1) : length(position.qrs)) = NaN;
position.Ttipo((length(position.Ttipo) + 1) : length(position.qrs)) = NaN;
position.Tscale((length(position.Tscale) + 1) : length(position.qrs)) = NaN;
position.Pon(position.Pon >= (position.qrs)) = NaN;
position.P(position.P >= (position.qrs)) = NaN;
position.Pprima(position.Pprima >= (position.qrs)) = NaN;
position.Poff(position.Poff >= (position.qrs)) = NaN;
position.Pon(position.Pon >= (position.QRSon)) = NaN;
position.P(position.P >= (position.QRSon)) = NaN;
position.Pprima(position.Pprima >= (position.QRSon)) = NaN;
position.Poff(position.Poff >= (position.QRSon)) = NaN;
position.Pon(position.Pon >= (position.P)) = NaN;
position.Poff(position.Poff <= (position.P)) = NaN;
position.Ton(position.Ton >= (position.T)) = NaN;
position.Toff(position.Toff <= (position.T)) = NaN;

% Remove void annotations at the end
strf = fieldnames(position); 
aux = find(position.qrs == 0 | isnan(position.qrs));

for j = 1:length(strf)
    eval(['aux_l=aux(aux<=size(position.' strf{j} ',2));'])
    eval(['position.' strf{j} '(aux_l) = [];']);
end

% Determine R wave polarity
if ~isempty(position.QRSmainpos) && ~isempty(position.QRSmaininv)
    a = length(find(position.QRSmainpos == position.qrs));
    b = length(find(position.QRSmaininv == position.qrs));
    if a >= b
        position.qrs_hrv = '+';
    else
        position.qrs_hrv = '-';
    end
end

end
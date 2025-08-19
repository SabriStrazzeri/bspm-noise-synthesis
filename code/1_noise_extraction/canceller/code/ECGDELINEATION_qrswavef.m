function [position, qrspiconset, qrspicoffset] = ECGDELINEATION_qrswavef(samp, time, position, w, intervalo, fs)
% QRS wave delineation. This function identifies Q, R and S waves and QRS
% morphology.
%
% Inputs:
%   - samp: samples included in the current excerpt (borders excluded)
%   - time:  QRS times in inedexes refering the interval included in the current excerpt (borders excluded)
%   - position: struct vector with the detected points
%   - w: matrix with WT scales 1 to 5
%   - intervalo: numeration of the beats processed in this segment
%   - fs: sampling frequency (in Hz)
%
% Outputs:
%   - position: updated position struct with P wave delineation marks
%   - qrspiconset: first relevant slope associated to each QRS complex (WT extrema)
%   - qrspicoffset: last relevant slope associated to each QRS complex (WT extrema)

%% Import constants
C = ECGDELINEATION_constants(fs);

QRS_window = C.QRSwindow;
QRSon_window = C.QRSon_window; 
QRSoff_window = C.QRSoff_window; 
QRS_wtol_paa = C.QRS_wtol_paa;
QRS_wtol_za = C.QRS_wtol_za;
QRS_wtol_pantza = C.QRS_wtol_pantza;
QRS_wtol_pantza_crack = QRS_wtol_pantza;
QRS_wtol_zaa = QRS_wtol_pantza;
QRS_wtol_pantzaa = QRS_wtol_pantza;

QRS_wtol_ppp = C.QRS_wtol_ppp;
QRS_wtol_zp = C.QRS_wtol_zp;
QRS_wtol_ppostzp = C.QRS_wtol_ppostzp;
QRS_wtol_ppostzp_crack = QRS_window;
QRS_wtol_zpp = QRS_wtol_zp;
QRS_wtol_ppostzpp = QRS_wtol_ppostzp;

farza = C.farza;
farzaa = C.farzaa;
farzp = C.farzp;
farzpp = C.farzpp;

firstwaverestriction = C.firstwaverestriction;	
Qwaverestriction = C.Qwaverestriction;
Rwaverestriction = C.Rwaverestriction;
Rprimarestriction1 = C.Rprimarestriction1;
Rprimarestriction2 = C.Rprimarestriction1;	
Srestriction1 = C.Srestriction1;	
Srestriction2 = C.Srestriction2;

QRSth = C.QRSth; 
QRSth_1p = C.QRSth_1p;    
QRSth_2p = C.QRSth_2p;
QRSth_1a = C.QRSth_1a;   
QRSth_2a = C.QRSth_2a;

KRon = C.KRon;
KRoff = C.KRoff;
KQ = C.KQ;
KS = C.KS;

%% Initialization of auxiliary variables
% Structure for the present segment of the signal (sig) times referred to
% begining of the present segment.
pos = struct('Pon', [], 'P', [], 'Poff', [], ... 
             'QRSon', [], 'Q', [], 'R', [], 'Fiducial', [], 'qrs', [], 'Rprima', [], 'S', [], 'QRSoff', [], ...
             'Ton', [], 'T', [], 'Tprima', [], 'Toff', [], 'Ttipo', [], 'QRSpa', [], 'QRSpp', []);

qrspiconset = [];
qrspicoffset = [];
WT_extrema = NaN*ones(6, length(time));
WT_zc = NaN*ones(5, length(time));
pos_extrema = NaN*ones(6, length(time));

%% QRST delineation
for i = 1 : length(time) % For each beat
    
    % Marks initialization
    qrs = time(i);
    R =[];
    Q = [];
    S = [];
    Rprima = [];
    za = [];
    zaa = [];
    zp = [];
    zpp = [];
    
    %% Determine peaks and zeros
    % Compute maximum derivative
    dermax = max(abs(w(max(qrs-round(QRS_window*fs), 1) : min(size(w, 1), qrs + round(QRS_window*fs)), 2)));
    
    % First peak before detected qrs position at scale 2
    pa = ECGDELINEATION_picant(w(max(qrs - round(QRS_window*fs), 1) : qrs, 2), qrs);
    % First peak after detected qrs position at scale 2
    pp = ECGDELINEATION_picpost(w(qrs : min(size(w, 1), qrs + round(QRS_window*fs)), 2), qrs);
    
    % Amplitudes of pa and pp at scale 2
    apa = w(pa, 2);  
    app = w(pp, 2);
    
    % If there is a crack at scale 1 but not at scale 2, it is possible that pa and pp have the same sign
    if sign(apa) == sign(app) 
        
        % If there is the next QRS_window*fs ms some modulus maximum of the contrary sign of app
        paux = ECGDELINEATION_modmax(w(pp + 1 : min(pp + round(QRS_window*fs), size(w, 1)), 2), 2, 0, -sign(app));
        
        if paux
            pp2 = pp + paux(1);
        else
            pp2 = []; 
        end
        
        % If there is the next QRS_wtol_paa*fs ms some modulus maximum of the contrary sign of apa
        paux = ECGDELINEATION_modmax(flipud(w(max(1, pa - round(QRS_wtol_paa*fs)) : pa - 1, 2)), 2, 0, -sign(apa));
        
        if paux
            pa2 = pp - paux(1);
        else
            pa2 = [];
        end
        
        % Peak selection
        if isempty(pp2)
            
            if ~isempty(pa2)
                pa = pa2;
                apa = w(pa2, 2);
            end
            
        else
            
            if isempty(pa2)
                pp = pp2; 
                app = w(pp2, 2);
            else
                % Take the peak with greater absolute value 
                if abs(w(pp2, 2)) > abs(w(pa2, 2))
                    pp = pp2;
                    app = w(pp2, 2);
                else
                    pa = pa2;
                    apa = w(pa2, 2);
                end
            end
            
        end
        
    end
    
    % Next peaks before pa and after pp
    paa = ECGDELINEATION_modmax(flipud(w(max(1, pa - round(QRS_wtol_paa*fs)) : pa - 1, 2)), 2, QRSth*dermax, sign(w(pa, 2)));
    ppp = ECGDELINEATION_modmax(w(pp + 1 : fix(min(pp + round(QRS_wtol_ppp*fs), size(w, 1))), 2), 2, QRSth*dermax, sign(w(pp, 2)));
    
    % Protection against R-waves with cracks
    if ~isempty(paa)
        paa = pa - paa(end);
        pa = paa; 
        apa = max(w(paa, 2), apa);
    end
    
    if ~isempty(ppp)
        ppp = pp + ppp(end);
        pp = ppp; 
        app = max(app, w(ppp, 2));
    end
    
    % Depending of the signs of apa and app it can be known if the detected qrs position
    % corresponds to a positive or a negative wave.
    if (apa > 0) & (app < 0)  % QRS is positive (qRs, Rsr, rsR)
        
        ind = ECGDELINEATION_zerocross(flipud(w(max(1, pa - round(QRS_wtol_za*fs)) : pa - 1, 1)));
        za = pa - ind;  % Previous zero
        
        % Search for the first negative peak before za (and thus, before the positive peak pa)
        if ~isempty(za)
            
            paux = ECGDELINEATION_modmax(flipud(w(max(1, za - round(QRS_wtol_pantza*fs)) : za, 2)), 2, 0, -1);
            
            if paux
                pantza = za - paux(1) + 1;  % Peak anterior to za
            else
                pantza = [];
            end
            
            apantza = w(pantza, 2); % Amplitude of the peak anterior to za at scale 2
            
            %  Protection against waves with cracks: if there is another peak of the 
            %  same sign as pantza just before it, take it as the position of the peak, 
            %  and as amplitude, the maximum of the two.
            paux = ECGDELINEATION_modmax(flipud(w(max(1, pantza - round(QRS_wtol_pantza_crack*fs)) : pantza - 1, 2)), 2, QRSth_2a*dermax, sign(w(pantza, 2)));
            
            if ~isempty(paux)
                paux = pantza - paux(end);
                pantza = paux;
                apantza = sign(w(paux, 2))*max(abs(apantza), abs(w(paux, 2)));
            end
            
            % If apantza is a little peak, forget it and za
            if (apantza > 0) | (abs(apantza) < QRSth_1a*dermax) 
                za = [];
            elseif isempty(pantza)
                za = [];
            end
            
            % If we are interested in the zero crossing za
            if ~isempty(za) 
                
                % Search for the zero crossign before za (zaa)
                ind = ECGDELINEATION_zerocross(flipud(w(max(1, pantza - round(QRS_wtol_zaa*fs)) : pantza - 1,1))); 
                zaa = pantza - ind;    
               	
                if ~isempty(zaa)
                    
                    paux = ECGDELINEATION_modmax(flipud(w(max(1, zaa - round(QRS_wtol_pantzaa*fs)) : zaa,2)), 2, 0, +1); % Search positive peak before "zaa"
                    
                    if paux
                        pantzaa = zaa - paux(1) + 1; % Peak anterior to zaa
                    else
                        pantzaa = [];
                    end
                    
                    apantzaa = w(pantzaa, 2); % Amplitude of the peak anterior to zaa at scale 2
                    
                    % If apantzaa is a little peak, forget it and zaa
                    if (apantzaa < 0) | (abs(apantzaa) < QRSth_2a*dermax)
                        zaa = [];
                    elseif isempty(pantzaa)
                        zaa = [];
                    end        
                end
            end
        end
        
        % Search for the first zero after pp
        ind = ECGDELINEATION_zerocross(w(pp + 1 : min(size(w, 1), pp + round(QRS_wtol_zp*fs)), 1));
        zp = pp + ind;
        
        % Search peak after zp (ppostzp)
        if ~isempty(zp)
            
            paux = ECGDELINEATION_modmax(w(zp : min(size(w, 1), zp + round(QRS_wtol_ppostzp*fs)), 2), 2, 0, +1);
            
            if paux
                ppostzp = zp + paux(1) - 1; % Peak poseterior to zp
            else
                ppostzp = [];
            end
            
            appostzp = w(ppostzp, 2); % Amplitude of peak poseterior to zp at scale 2
                    
            %  Protection against waves with cracks: if there is another peak of the 
            %  same sign as ppostzp just after it, take it as the position of the peak, 
            %  and as amplitude, the maximum of the two.
            paux = ECGDELINEATION_modmax(w(ppostzp + 1 : min(size(w, 1), ppostzp + round(QRS_wtol_ppostzp_crack*fs)), 2), 2, QRSth_2p*dermax, sign(w(ppostzp, 2)));
            
            if ~isempty(paux)
                paux = ppostzp + paux(end);
                ppostzp = paux;
                appostzp = sign(w(paux,2))* max(abs(appostzp), abs(w(paux,2)));
            end
            
            % If appostzp is a little peak, forget it and zp
            if (appostzp < 0) | (abs(appostzp) < QRSth_1p*dermax)
                zp = [];
            elseif isempty(ppostzp)
                zp = [];
            end
            
            % Else, search zero crossing after it
            if ~isempty(zp)
                
                ind = ECGDELINEATION_zerocross(w(ppostzp + 1 : min(size(w, 1), ppostzp + round(QRS_wtol_zpp*fs)), 1));
                zpp = ppostzp + ind;
                
                % And next peak after zero crossing
                if ~isempty(zpp)       
                    
                    paux = ECGDELINEATION_modmax(w(zpp : min(size(w, 1), zpp + round(QRS_wtol_ppostzpp*fs)), 2), 2, 0, -1);
                    
                    if paux
                        ppostzpp = zpp + paux(1) - 1; % Peak poseterior to zpp 
                    else
                        ppostzpp = [];
                    end
                    
                    appostzpp = w(ppostzpp, 2); % Amplitude of peak poseterior to zpp at scale 2
                    
                    % If appostzpp is a little peak, forget it and zpp
                    if (appostzpp > 0) | (abs(appostzpp) < QRSth_2p*dermax)
                        zpp = [];
                    elseif isempty(ppostzpp)
                        zpp = [];
                    end
                end
            end
        end
        
        if ~isempty(za)
            % If first zero in the wavelet before qrs is too far from QRS, forget it
            if isempty(zaa) && ((qrs - za) > round(farza*fs))
                za = [];   
            end
        
            % If zaa is too far from za, forget it
            if ~isempty(zaa) && ((za - zaa) > round(farzaa*fs))
                zaa = [];     
            end
        end
        
        if ~isempty(zp)
            % If zp is too far from qrs, forget it
            if isempty(zpp) && ((zp - qrs) > round(farzp*fs))
                zp = [];
            end

            % If zpp is too far from zpp forget it
            if ~isempty(zpp) && ((zpp - zp) > round(farzpp*fs))
                zpp = [];
            end
        end
        
        % Wave label asignation
        if isempty(za)  % No waves before qrs (which is positive)
            
            % RSR' or RS or R
            R = qrs;
            S = zp;
            Rprima = zpp;  
            
        elseif isempty(zp) % If some wave before qrs but not waves after
            
            if ~isempty(zaa) % If there are two waves before qrs
                
                % RSR'
                R = zaa;
                S = za;
                Rprima = qrs; 
                
            else % If only one wave before qrs
                
                % QR
                Q = za;
                R = qrs;            
                
            end
            
        else % If there are waves before and after qrs
            
            if ~isempty(zpp) && ~isempty(zaa)  % If there are two waves before and two waves after
                if abs(apantzaa) > abs(appostzpp) % Forget the smaller of the two extreme waves
                    zpp = []; 
                else
                    zaa = [];
                end
            end
            
            % Now there are no more than 4 possible waves
            if ~isempty(zpp) && (isempty(zaa))  % If we have one wave before and two after
                
                if abs(appostzpp) > abs(apantza) % If the second after is bigger than the one before
                    
                    % RSR'
                    R = qrs;
                    S = zp;
                    Rprima = zpp;
                    
                else  % If the one before is bigger than the second after
                    
                    % QRS
                    Q = za;
                    R = qrs;
                    S = zp;
                    
                end
                
            elseif ~isempty(zaa) && isempty(zpp) % If there are two waves before and one after
                
                if abs(apantzaa) > abs(appostzp)
                    
                    %  RSR'
                    R = zaa;
                    S = za;
                    Rprima = qrs;
                    
                else
                    
                    %  QRS
                    Q = za;
                    R = qrs;
                    S = zp; 
                    
                end
                
            elseif (za ~= qrs) && (zp ~= qrs) % If there is one wave before and one after qrs
                
                % QRS
                Q = za;
                R = qrs;
                S = zp;
                
            else
                
                if za == qrs % Strange case R==Q???
                  
                  if apantza < 0
                      
                     Q = za;
                     R = zp;
                     
                  else
                      
                     R = za;
                     S = zp;
                     
                  end
                  
                else
                    
                    if appostzp < 0
                        
                        R = qrs;
                        S = zp;
                        
                    else
                        
                        Q = qrs;
                        R = zp;
                        
                    end
                    
                end
            end
            
        end
        
    else  % QRS is negative (Qrs, qrS, QS)
        
        ind = ECGDELINEATION_zerocross(flipud(w(max(1, pa - round(QRS_wtol_za*fs)) : pa - 1, 1)));
        za = pa - ind; % Previous zero
        
        if ~isempty(za)
            paux = ECGDELINEATION_modmax(flipud(w(max(1, za - round(QRS_wtol_pantza*fs)) : za, 2)), 2, 0, +1);
            
            if paux
                pantza = za - paux(1) + 1; % Peak anterior to za
            else
                pantza = [];
            end
            
            apantza = w(pantza, 2); % Amplitude of peak anterior to za at scale 2
            
            %  Protection against waves with cracks
            paux = ECGDELINEATION_modmax(flipud(w(max(1 ,pantza - round(QRS_wtol_pantza_crack*fs)) : pantza - 1, 2)), 2, QRSth_2a*dermax, sign(w(pantza, 2)));
            
            if ~isempty(paux)
                paux = pantza - paux(end);
                pantza = paux;
                apantza = sign(w(paux, 2))*max(abs(apantza), abs(w(paux, 2)));
            end
            
            % If apantza is a little peak, forget it and zpp
            if (apantza < 0) | (abs(apantza) < QRSth_1a*dermax)
                za = [];
            elseif isempty(pantza)
                za = [];
            end
            
            % Search for the zero crossign before za (zaa)
            if ~isempty(za)
                
                ind = ECGDELINEATION_zerocross(flipud(w(max(1, pantza - round(QRS_wtol_zaa*fs)) : pantza - 1, 1)));
                zaa = pantza - ind;
                
                if ~isempty(zaa)
                    
                    paux = ECGDELINEATION_modmax(flipud(w(max(1, zaa - round(QRS_wtol_pantzaa*fs)) : zaa, 2)), 2, 0, -1);
                    
                    if paux
                        pantzaa = zaa - paux(1) + 1; % Peak anterior to zaa
                    else
                        pantzaa = [];
                    end
                    
                    apantzaa = w(pantzaa, 2); % Amplitude of peak anterior to zaa at scale 2
                    
                    % If apantzaa is a little peak, forget it and zpp
                    if (apantzaa > 0) | (abs(apantzaa) < QRSth_2a*dermax)
                        zaa = [];
                    elseif isempty(pantzaa)
                        zaa = [];
                    end
                end
            end
        end
        
        % Search for the first zero after pp
        ind = ECGDELINEATION_zerocross(w(pp + 1 : min(size(w, 1), pp + round(QRS_wtol_zp*fs)), 2));
        
        if ~isempty(pp) && ~isempty(ind)
            zp = pp + ind;
        end
        
        % Search for the first peak after zp (ppostzp)
        if ~isempty(zp)
            
            paux = ECGDELINEATION_modmax(w(zp : min(size(w, 1), zp + round(QRS_wtol_ppostzp*fs)), 2), 2, 0, -1);
            
            if paux
                ppostzp = zp + paux(1) - 1; % Peak posterior to zp
            else
                ppostzp = [];
            end
            
            appostzp = w(ppostzp, 2); % Amplitude of peak posterior to zp at scale 2
            
            % Protection against waves with cracks
            paux = ECGDELINEATION_modmax(w(ppostzp + 1 : min(size(w, 1), ppostzp + round(QRS_wtol_ppostzp_crack*fs)), 2), 2, QRSth_2p*dermax, sign(w(ppostzp, 2)));  % estamos a ir longe de mais na busca falta protec�ao para que nao entre no batimento seguinte!
            
            if ~isempty(paux)
                paux = ppostzp + paux(end);
                ppostzp = paux;
                appostzp = sign(w(paux, 2))*max(abs(appostzp), abs(w(paux,2)));
            end
            
            % If appostzp is a little peak, forget it and zpp
            if (appostzp > 0) | (abs(appostzp) < QRSth_1p*dermax)
                zp = [];
            elseif isempty(ppostzp)
                zp = [];
            end
            
            % Search for the first zero after ppostzp
            if ~isempty(zp)
                
                ind = ECGDELINEATION_zerocross(w(ppostzp + 1 : min(size(w, 1), ppostzp + round(QRS_wtol_zpp*fs)), 2));
                zpp = ppostzp + ind;
                
                if ~isempty(zpp)
                    
                    paux = ECGDELINEATION_modmax(w(zpp : min(size(w, 1), zpp + round(QRS_wtol_ppostzpp*fs)), 2), 2, 0, +1);
                    
                    if paux
                        ppostzpp = zpp + paux(1) - 1;
                    else
                        ppostzpp = []; % Peak posterior to zpp
                    end
                    
                    appostzpp = w(ppostzpp, 2); % Amplitude of peak posterior to zpp at scale 2
                    
                    % If appostzpp is a little peak, forget it and zpp
                    if (appostzpp < 0) | (abs(appostzpp) < QRSth_2p*dermax)
                        zpp = [];
                    elseif isempty(ppostzpp)
                        zpp = [];
                    end
                end
            end
        end
        
        if ~isempty(za)
            % If za is too far from qrs, forget it
            if isempty(zaa) && ((qrs - za) > farza*fs) 
                za = [];   % Si 1� onda m
            end

            % If zaa is too far from za, forget it
            if ~isempty(zaa) && ((za - zaa) > farzaa*fs)
                zaa = [];
            end
        end
        
        if ~isempty(zp)
            % If zp is too far from qrs, forget it
            if isempty(zpp) && ((zp - qrs) > farzp*fs)
                zp = [];
            end

            % If zpp is too far from zp, forget it
            if ~isempty(zpp) && ((zpp - zp) > farzpp*fs)
                zpp = [];
            end
        end
        
        % Wave label asignation
        if isempty(za) % If no waves before qrs
            
            % (Q)RS
            Q = qrs;
            R = zp;
            S = zpp;      
            
            if (isempty(zp) && isempty(zpp))  % If no waves before nor after
                
                % QS complex
                Q = [];
                S = qrs;
                
            end 
            
        elseif isempty(zp) % If some wave before, but not after
           
            % QR(S) or R(S)
            Q = zaa;
            R = za;
            S = qrs;        
            
        else % If some wave before and some wave after
            
            if ~isempty(zpp) && ~isempty(zaa) % If two waves before and two after
                
                if abs(apantzaa) > abs(appostzpp) % Forget the smallest of the extreme waves
                    zpp = []; 
                else
                    zaa = [];
                end
                
            end
            
            % Now there are not more than 4 possible waves
            if ~isempty(zpp) % If 1 wave before and two after
                
                if abs(appostzpp) > abs(apantza)  % If the second after greater than the wave before
                    
                    % (Q)RS
                    Q = qrs;
                    R = zp;
                    S = zpp;
                    
                else % If the wave before qrs greater than the secon wave after qrs
                    
                    % R(S)R'
                    R = za;                         
                    S = qrs;
                    Rprima = zp;
                    
                end
                
            elseif ~isempty(zaa) % If 2 waves before and one after
                
                if abs(apantzaa) > abs(appostzp)
                    
                    % QR(S)
                    Q = zaa;
                    R = za;
                    S = qrs;
                    
                else
                    
                    % R(S)R'
                    R = za;
                    S = qrs;
                    Rprima = zp; 
                    
                end
                
            else  % If 1 before and one after qrs
                
                % R(S)R'
                R = za;
                S = qrs;
                Rprima = zp; 
                
            end
            
        end
        
    end 
    
    % Constants used for onset and offset detection
    Konset = KQ; 
    Koffset = KS;
    
    % Identify the first wave in the complex
    if ~isempty(Q)
        
        firstwave = Q;
        
    elseif ~isempty(R)
        
        firstwave = R; 
        Konset = KRon;
        
    else
        
        firstwave = S;
        Konset = KRon;
        
    end
    
    % Identify the last wave in the complex
    if ~isempty(Rprima)
        
        lastwave = Rprima;
        Koffset = KRoff;
        
    elseif ~isempty(S)
        
        lastwave = S;
        
    else
        
        lastwave = R;
        Koffset = KRoff;
        
    end
    
    % The point of departure for detecting the onset and offset of QRS is a peak in the wavelet transform
    % Now we identify which peak shall be used for onset and for offset of QRS
    if firstwave == qrs
        piconset = pa;  
    elseif firstwave == za
        piconset = pantza;
    elseif firstwave == zaa
        piconset = pantzaa;
    else
        error('Imposible Condition')
    end
    
    if lastwave == qrs
        picoffset = pp;
    elseif lastwave == zp
        picoffset = ppostzp;
    elseif lastwave == zpp
        picoffset = ppostzpp;
    else
        error('Imposible Condition')
    end
    
    % Application of derivative criteria: onset of QRS
    % Search onset by means of a threshold in the wavelet related to the amplitude of the wavelet at the peak
    qrson = ECGDELINEATION_searchon (piconset, w(max(1, piconset - round(QRSon_window*fs)) : piconset, 2), Konset);
    
    % Protection of onsets too far from qrs
    % If qrs onset more than 120 ms before R wave, there is no Q wave.
    if ~isempty(Q)
        if (firstwave == Q) && (Q ~= qrs)
            if ((qrs - qrson) >= firstwaverestriction*fs) || ((Q - qrson) >= Qwaverestriction*fs)

                firstwave = R; 

                if firstwave == qrs
                    piconset = pa;  
                elseif firstwave == za
                    piconset = pantza;
                elseif firstwave == zaa
                    piconset = pantzaa;    
                end

                % New search
                qrson = ECGDELINEATION_searchon (piconset, w(max(1, piconset - round(QRSon_window*fs)) : piconset, 2), KRon);
                Q = [];

            end
        end
    end
    
    % If first wave is R and qrs onset more than firstwaverestriction w before qrs, there is no R wave.
    if ~isempty(R)
        if (firstwave == R) && (lastwave ~= R) && (qrs ~= R)
            if ((qrs - qrson) > firstwaverestriction*fs) || ((R -qrson) >= Rwaverestriction*fs)

                % Check qrs morphology
                if isempty(Rprima)

                    % QS complex (S wave only)
                    firstwave = S;
                    R = [];

                else

                    % SRprima -> QR complex
                    R = Rprima;
                    Q = S;
                    S = [];
                    Rprima = [];
                    firstwave = Q;

                end

                if firstwave == qrs
                    piconset = pa;  
                elseif firstwave == za
                    piconset = pantza;
                elseif firstwave == zaa
                    piconset = pantzaa;    
                end

                qrson = ECGDELINEATION_searchon (piconset, w(max(1, piconset - round(QRSon_window*fs)) : piconset,2), KS);

            end
        end
    end
    
    % Application of derivative criteria: offset of QRS
    qrsoff = ECGDELINEATION_searchoff (picoffset, w(picoffset:min(size(w, 1), picoffset+round(QRSoff_window*fs)), 2), Koffset);
    
    % Protection of offsets too far from qrs
    % If Rprima offset more than 120 ms after S wave, there is no Rprima wave.
    if ~isempty(Rprima)
        if (lastwave == Rprima) && (Rprima ~= qrs)
            if ((qrsoff - qrs) > Rprimarestriction1*fs) || ((qrsoff - Rprima) > Rprimarestriction2*fs)

                lastwave = S;

                if lastwave == qrs
                    picoffset = pp;
                elseif lastwave == zp
                    picoffset = ppostzp;
                elseif lastwave == zpp
                    picoffset = ppostzpp;
                end

                qrsoff = ECGDELINEATION_searchoff (picoffset, w(picoffset : min(size(w, 1), picoffset + round(QRSoff_window*fs)), 2), Koffset);
                Rprima = [];

            end
        end
    end
    
    % If S offset more than 200 ms after R wave, there is no S wave.
    if ~isempty(S)
        if (lastwave == S) && (firstwave ~= S) && (S ~= qrs)
            
            if ~isempty(qrsoff)
            
                if ((qrsoff - qrs) > Srestriction1*fs) || ((qrsoff - S) > Srestriction2*fs)

                    lastwave = R;

                    if lastwave == qrs
                        picoffset = pp;
                    elseif lastwave == zp
                        picoffset = ppostzp;
                    elseif lastwave == zpp
                        picoffset = ppostzpp;
                    end

                    qrsoff = ECGDELINEATION_searchoff(picoffset, w(picoffset : min(size(w, 1), picoffset + round(QRSoff_window*fs)), 2), KRoff);
                    S = [];

                end
                
            end
        end
    end
    
    if isempty(piconset)
        piconset = NaN;
    end
    
    if isempty(picoffset)
        picoffset = NaN;
    end
    
    qrspiconset = [qrspiconset piconset];
    qrspicoffset = [qrspicoffset picoffset];
    
    % Main positive and negative wave
    if exist('apantzaa', 'var') 
        if ~isempty(apantzaa) 
            WT_extrema(1, i) = apantzaa;
            pos_extrema(1, i) = pantzaa;
        end
    end
    
    if exist('apantza', 'var')
        if ~isempty(apantza)
            WT_extrema(2, i) = apantza;
            pos_extrema(2, i) = pantza;
        end
    end
    
    if exist('apa', 'var')
        if ~isempty(apa)
            WT_extrema(3, i) = apa;
            pos_extrema(3, i) = pa;
        end
    end
    
    if exist('app', 'var')
        if ~isempty(app)
            WT_extrema(4, i) = app;
            pos_extrema(4, i) = pp;
        end
    end
    
    if exist('appostzp', 'var')
        if~isempty(appostzp)
            WT_extrema(5, i) = appostzp;
            pos_extrema(5, i) = ppostzp;
        end
    end
    
    if exist('appostzpp', 'var')
        if ~isempty(appostzpp)
            WT_extrema(6, i) = appostzpp;
            pos_extrema(6, i) = ppostzpp;
        end
    end
    
    if exist('zaa', 'var')
        if ~isempty(zaa)
            WT_zc(1, i) = zaa;
        end
    end
    
    if exist('za', 'var')
        if ~isempty(za)
            WT_zc(2, i) = za;
        end
    end
    
    if exist('qrs', 'var')
        if ~isempty(qrs)
            WT_zc(3, i) = qrs;
        end
    end
    
    if exist('zp', 'var')
        if ~isempty(zp)
            WT_zc(4, i) = zp;
        end
    end
    
    if exist('zpp', 'var')
        if ~isempty(zpp)
            WT_zc(5, i) = zpp;
        end
    end
    
    aux = [];
    if ~isempty(R)
        aux = find(WT_zc(:, i) == R, 1);
    end
    
    if ~isempty(Q)
        aux = [aux find(WT_zc(:, i) == Q, 1)];
    end
    
    if ~isempty(S)
        aux = [aux find(WT_zc(:, i) == S, 1)];
    end
    
    if ~isempty(Rprima)
        aux = [aux find(WT_zc(:, i) == Rprima, 1) aux];
    end
    
    auxaux = NaN(5, 1);
    auxaux(aux) = WT_zc(aux, i);
    WT_zc(:, i) = auxaux;
    
    A = find(~isnan(WT_zc(:, i)));
    auxaux = WT_extrema(A, i) - WT_extrema(A + 1, i);
    [~, iM] = max(auxaux);
    [~, im] = min(auxaux);
    pos.QRSmainpos(i) = WT_zc(A(iM), i);
    pos.QRSmaininv(i) = WT_zc(A(im), i);
    
    % Maximum slope locations for main wave
    if ~isempty(pa)
        pos.QRSpa(i) = pa;
    else
        pos.QRSpa(i) = NaN;
    end
    
    if ~isempty(pp)        
        pos.QRSpp(i) = pp;
    else
        pos.QRSpp(i) = NaN;
    end
    
    % Filling the structure with nans in case marks were not detected
    if isempty(qrson)
        qrson = NaN;
    end
    
    if isempty(qrsoff)
        qrsoff = NaN;
    end
    
    if isempty(R)
        R = NaN;
    end
    
    if isempty(S)
        S = NaN;
    end
    
    if isempty(Q)
        Q = NaN;
    end
    
    if isempty(Rprima)
        Rprima = NaN;
    end
    
    pos.QRSon(i) = qrson;
    pos.Q(i) = Q;
    pos.R(i) = R;
    pos.S(i) = S;
    pos.Rprima(i) = Rprima;
    pos.QRSoff(i) = qrsoff;
    pos.qrs(i) = qrs;  
        
end

%% Return
if ~isempty(intervalo)
    position.QRSon(intervalo(1) : intervalo(2)) = pos.QRSon + samp(1) - 1;
    position.Q(intervalo(1) : intervalo(2)) = pos.Q + samp(1) - 1;
    position.R(intervalo(1) : intervalo(2)) = pos.R + samp(1) - 1;
    position.S(intervalo(1) : intervalo(2)) = pos.S + samp(1) - 1;
    position.Rprima(intervalo(1) : intervalo(2)) = pos.Rprima + samp(1) - 1;
    position.QRSoff(intervalo(1) : intervalo(2)) = pos.QRSoff + samp(1) - 1;
    position.QRSmainpos(intervalo(1) : intervalo(2)) = pos.QRSmainpos + samp(1) - 1; 
    position.QRSmaininv(intervalo(1) : intervalo(2)) = pos.QRSmaininv + samp(1) - 1; 
    position.QRSpa(intervalo(1) : intervalo(2)) = pos.QRSpa + samp(1) - 1;
    position.QRSpp(intervalo(1) : intervalo(2)) = pos.QRSpp + samp(1) - 1;
end

end

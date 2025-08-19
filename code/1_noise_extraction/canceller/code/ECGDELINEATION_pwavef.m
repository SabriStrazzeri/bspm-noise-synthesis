function position = ECGDELINEATION_pwavef(samp, time, position, w, intervalo, ultimo_anot, fs)
% P wave delineation. This function also detects P wave morphology among
% normal, inverted, biphasic +- and biphasic -+
%
% Inputs:
%   - samp: samples included in the current excerpt (borders excluded)
%   - time:  QRS times in inedexes refering the interval included in the current excerpt (borders excluded)
%   - position: struct vector with the detected points
%   - w: matrix with WT scales 1 to 5
%   - intervalo: numeration of the beats processed in this segment
%   - ultimo_anot: last annotation
%   - fs: sampling frequency (in Hz)
%
% Outputs:
%   - position: updated position struct with P wave delineation marks

%% Import constants
C = ECGDELINEATION_constants(fs);

th_Pdetection = C.th_Pdetection; 
signalTh = C.signalTh;
KPon = C.KPon;
KPoff = C.KPoff;
PwindowStart = C.PwindowStart;
PwindowEnd = C.PwindowEnd;
Pbound = C.Pbound;
PminWindow = C.PminWindow;

%% Initialization of auxiliary variables
picon_all = [];
picoff_all = [];
changes = [1 2 4 5]; % 3 look for peak on scale 3 instead of scale n

if ~isempty(intervalo)
    for i = 1 : length(unique(intervalo(1) : intervalo(end)))
        
        % Reset interim variables
        maxapos = [];
        minapos = [];
        minppos = [];
        maxppos = [];
        P = [];
        picon = [];
        picoff = [];
        Pon = [];
        Poff = [];
        Pprima = [];
        
        %% Identify QRS onset   
        if ~isnan(position.QRSon(i + intervalo(1) - 1)) && ((position.QRSon(i + intervalo(1) - 1) - samp(1) + 1) < time(i))
            qrson = position.QRSon(i + intervalo(1) - 1) - samp(1) + 1;
        else
            qrson = time(i) - round(PwindowEnd * fs);
        end

        %% Define P window (protection to begin after Toff)
        inivent = round(PwindowStart * fs); % Window onset
        if (i - 1 + intervalo(1) - 1) > 1 
            if ~isnan(position.Toff(i - 1 + intervalo(1) - 1))        % If there is Toff mark
                inivent = min(inivent, qrson - (position.Toff(i - 1 + intervalo(1) - 1) - samp(1) + 1));
            elseif ~isnan(position.T(i - 1 + intervalo(1) - 1))       % If only T mark available   
                inivent = min(inivent, qrson - (position.T(i - 1 + intervalo(1) - 1) - samp(1) + 1));       
            elseif ~isnan(position.QRSoff(i - 1 + intervalo(1) - 1))  % If only QRSoff mark available                   
                inivent = min(inivent, qrson - (position.QRSoff(i - 1 + intervalo(1) - 1) - samp(1) + 1));  
            else                                                      % If only QRS mark available
                inivent = min(inivent, round(qrson - (position.qrs(i - 1 + intervalo(1) - 1) - samp(1) + 1)));   
            end
        end
        
        finvent = round(PwindowEnd * fs); % Window offset
        ultimo_anot = ultimo_anot - samp(1) + 1;
        
        % Last anotation of the previous segment can overlap with the present one
        if (i == 1) && (ultimo_anot >= 1)   % Protection in case it is the first beat
            begwin = round(max([1, qrson - inivent + 1, ultimo_anot + 1]));
        else
            begwin = round(max(1, qrson - inivent + 1));
        end
        
        endwin =  round(max(1, qrson - finvent + 1)); 
        
        %% Determine if there is P wave
        if (endwin - begwin) >= (PminWindow * fs) % If window length is larger than threshold
            n = 4;    % Scale 4 selected as first option
            [hay_onda, absmax, absmin, maxpos, minpos] = isthereP(n, w, begwin, endwin, i, intervalo, time, th_Pdetection, fs);

            if ~hay_onda   % If there is no wave in scale 4, check scale 5 
                n = 5;
                [hay_onda, absmax, absmin, maxpos, minpos] = isthereP(n, w, begwin, endwin, i, intervalo, time, th_Pdetection, fs);
            end
            
        else % If window length is shorter than threshold, there is no P wave
            hay_onda = 0;
        end
        
        %% Decide wave morphology and wave onset, offset and peak (on scale n)
        if hay_onda && ((sum(changes == 2) == 1) || (n == 4))

            if sum(changes == 3) == 1
                m = 3; % Zero crossings in the m scale
            else
                m = n; % Zero crossings in the m=n scale
            end
            
            if sum(changes == 1) == 1 % Look for other significant extreme points (biphasic P waves)
                
                if absmax > absmin % Look for a minimum in opposite side to absmin
                    
                    if maxpos < minpos % Look for a minimum before maxpos
                       
                        minapos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : maxpos, n), 2, 0, -1); % Minimum of minima
                        [minaim, ind] = min(w(minapos, n));
                        minapos = minapos(ind);
                        
                        if abs(minaim) < signalTh*absmax % Non-significant
                            minapos = [];
                        end
                        
                    else % Look for a minimum after maxpos
                        
                        minppos = maxpos + ECGDELINEATION_modmax(w(maxpos + 1 : endwin, n), 2, 0, -1); % Minimum of minima
                        [minpim, ind] = min(w(minppos, n));
                        minppos = minppos(ind);
                        
                        if abs(minpim) < signalTh*absmax % non significant
                            minppos = [];
                        end
                        
                    end
                    
                else % Look for a maximum in opposite side to absmax
                    
                    if minpos < maxpos % Look for a maximum before minpos
                        
                        maxapos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : minpos, n), 2, 0, 1); % Maximum of maxima
                        [maxaim, ind] = max(w(maxapos, n));
                        maxapos = maxapos(ind);
                        
                        if abs(maxaim) < signalTh*absmin % Non-significant
                            maxapos = [];
                        end
                        
                    else % Look for a maximum after minpos
                        
                        maxppos = minpos + ECGDELINEATION_modmax(w(minpos + 1 : endwin, n), 2, 0, 1); % Maximum of maxima
                        [maxpim, ind] = max(w(maxppos, n));
                        maxppos = maxppos(ind);
                        
                        if abs(maxpim) < signalTh*absmin  % Non-significant
                            maxppos = [];
                        end
                        
                    end
                end
            end
            
            if isempty(maxapos) && isempty(minapos) && isempty(maxppos) && isempty(minppos) 
                if maxpos < minpos % Normal P wave
                    
                    Ptipo = 1;
                    
                    if (minpos - maxpos) > 2
                        
                        ind = ECGDELINEATION_zerocross(w(maxpos : minpos, m));    % First zero crossing after maxpos
                        
                        if isempty(ind) && sum(changes == 5) == 1 % Look in the n scale
                            ind = ECGDELINEATION_zerocross(w(maxpos : minpos, n));
                        end
                        
                        P = maxpos + ind -1;
                        
                        % For detecting onset and offset
                        picon = maxpos;                       
                        picoff = minpos;
                        
                    end
                    
                else  % Inverted P wave
                    
                    Ptipo = 0;
                    
                    if (maxpos - minpos) > 2
                        
                        ind = ECGDELINEATION_zerocross(w(minpos : maxpos, m));      % First zero crossing after minpos
                        
                        if isempty(ind) && (sum(changes == 5) == 1) % Look in the n scale
                            ind = ECGDELINEATION_zerocross(w(minpos : maxpos, n));
                        end
                        
                        P = minpos + ind -1;
                        
                        % For detecting onset and offset
                        picon = minpos; 
                        picoff = maxpos;
                   
                    end
                end
                
            elseif ~isempty(maxapos) || ~isempty(maxppos) % Biphasic (+ -) P wave 
                
                Ptipo = 4;
                extra = sort([minpos maxpos maxapos maxppos]);
                
                if (extra(2) - extra(1)) > 2
                    
                    ind = ECGDELINEATION_zerocross(w(extra(1) : extra(2), m));   % First zero crossing after picon
                    
                    if isempty(ind) && sum(changes == 5) == 1    % Look in the n scale
                        ind = ECGDELINEATION_zerocross(w(extra(1) : extra(2), n));
                    end
                    
                    P = extra(1) + ind -1;
                    
                    % For detecting onset and offset
                    picon = extra(1); 
                    
                end
                
                if (extra(3) - extra(2)) > 2
                    
                    ind = ECGDELINEATION_zerocross(w(extra(2) : extra(3), m));   % First zero crossing after extra
                    
                    if isempty(ind) && (sum(changes == 5) == 1) % Look in the n scale
                        ind = ECGDELINEATION_zerocross(w(extra(2) : extra(3), n));
                    end
                    
                    Pprima = extra(2) + ind -1;
                    
                    % For detecting onset and offset
                    picoff = extra(3);
                    
                end
                
            elseif ~isempty(minapos) || ~isempty(minppos) % Biphasic (- +) P wave 
                
                Ptipo = 5;
                extra = sort([minpos maxpos minapos minppos]);   % For detecting onset, offset and intermediate extreme
                
                if (extra(2) - extra(1)) > 2
                    ind = ECGDELINEATION_zerocross(w(extra(1) : extra(2), m));   % First zero crossing after picon
                    
                    if isempty(ind) && (sum(changes == 5) == 1)  % Look in the n scale
                        ind = ECGDELINEATION_zerocross(w(extra(1) : extra(2), n));
                    end
                    
                    P = extra(1) + ind -1;
                    
                    % For detecting onset and offset
                    picon = extra(1);
                    
                end
                
                if (extra(3) - extra(2)) > 2
                    
                    ind = ECGDELINEATION_zerocross(w(extra(2) : extra(3), m));   % First zero crossing after extra
                    
                    if isempty(ind) && (sum(changes == 5) == 1)  % Look in the n scale
                        ind = ECGDELINEATION_zerocross(w(extra(2) : extra(3), n));
                    end
                    
                    Pprima = extra(2) + ind - 1;
                    
                    % For detecting onset and offset
                    picoff = extra(3);
                    
                end
                
            else
                Ptipo = NaN;
            end
            
            % P wave onset and offset detection
            if ~isempty(picon)
                Pon = ECGDELINEATION_searchon (picon, w(max(begwin, picon - round(Pbound * fs)) : picon, n), KPon);
            end
            
            if ~isempty(picoff)
                Poff = ECGDELINEATION_searchoff(picoff, w(picoff : min(picoff + round(Pbound * fs), endwin), n), KPoff);
            end
            
            if isempty(P) && (sum(changes == 4) == 1)
                Pon = [];
                Poff = [];
                P = [];
            end
            
            if isempty(Pon) || isempty(Poff)
                Pon = [];
                Poff = [];
                P = [];
            end
            
        end
        
        maxpos = []; 
        minpos = [];
            
        % Filling the structure with nans in case marks were not detected
        if isempty(Pon)
            Pon = NaN;
        end
        
        if isempty(Poff)
            Poff = NaN;
        end
        
        if isempty(P)
            Ptipo = NaN;
            P = NaN;
            n = NaN;
        end
        
        if isempty(Pprima)
            Pprima = NaN;
        end
        
        if isempty(picoff)
            picoff = NaN;
        end
        
        if isempty(picon)
            picon = NaN;
        end
        
        picon_all = [picon_all picon];
        picoff_all = [picoff_all picoff];
        
        %% Add marks to position structure
        pos.Pon(i) = Pon;
        pos.Poff(i) = Poff;
        pos.P(i) = P;
        pos.Pprima(i) = Pprima;
        pos.Pscale(i) = n;
        pos.Ptipo(i) = Ptipo;
        
    end

    %% Return
    if exist('pos', 'var')
        position.Pon(intervalo(1) : intervalo(2)) = pos.Pon + samp(1) - 1;
        position.Poff(intervalo(1) : intervalo(2))=  pos.Poff + samp(1) - 1;
        position.P(intervalo(1) : intervalo(2)) = pos.P + samp(1) - 1;
        position.Pprima(intervalo(1) : intervalo(2)) = pos.Pprima + samp(1) - 1;
        position.Pscale(intervalo(1) : intervalo(2)) = pos.Pscale;
        position.Ptipo(intervalo(1) : intervalo(2)) = pos.Ptipo;
        
    else % If no P wave was detected, fill struct with nans
        position.Pon(intervalo(1) : intervalo(2)) = NaN;
        position.Poff(intervalo(1) : intervalo(2)) =  NaN;
        position.P(intervalo(1) : intervalo(2)) = NaN;
        position.Pprima(intervalo(1) : intervalo(2)) = NaN;
        position.Pscale(intervalo(1) : intervalo(2)) = NaN;
        position.Ptipo(intervalo(1) : intervalo(2))= NaN;
    end
    
end

end

function [hay_onda, absmax, absmin, maxpos, minpos] = isthereP(n, w, begwin, endwin, i, intervalo, time, th_Pdetection, fs)

%% Find extreme points and decide if there is wave is the scale n
maxpos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : endwin, n), 2, 0, +1);
minpos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : endwin, n), 2, 0, -1);
[maxim, ind] = max(w(maxpos, n));
maxpos = maxpos(ind);
[minim, ind] = min(w(minpos, n));
minpos = minpos(ind);

% If no local maxima and minima, take first or last sample
if isempty(maxpos)
    if (w(begwin, n) >= w(endwin, n)) && (w(begwin, n) > 0 )
        maxpos = begwin; 
        maxim = w(maxpos, n);
    elseif (w(endwin, n) >= w(begwin, n)) && (w(endwin, n) > 0)
        maxpos = endwin;
        maxim = w(maxpos, n);
    end
end

if isempty(minpos)
    if (w(begwin, n) <= w(endwin, n)) && (w(begwin, n) < 0) 
        minpos = begwin;
        minim = w(minpos, n);
    elseif (w(endwin, n) <= w(begwin, n)) && (w(endwin,n) < 0)
        minpos = endwin;
        minim = w(minpos, n);
    end
end

absmax = abs(maxim);
absmin = abs(minim);

% Calculate Vrms for the beat at scale n
if  (intervalo(1) ~= intervalo(2)) || (length(intervalo) ~= 2) || (length(time) == 1 && intervalo(i) ~= 1)
    if i ~= 1  % First beat
        vrms = sqrt(mean(w(time(i - 1) : time(i), n).^2)); 
    else       % Other ones 
        vrms = sqrt(mean(w(1 : time(i), n)).^2); 
    end
else
    if intervalo(i) ~= 1  % First beat
        vrms = sqrt(mean(w(time(1) : time(2), n).^2));
    else       % Other ones
        vrms = sqrt(mean(w(1 : time(1), n)).^2);
    end
end

% Decide if there is P wave
hay_onda = (abs(maxpos - minpos) < 0.11*fs) & ((absmax > th_Pdetection*vrms) & (absmin > th_Pdetection*vrms));
if isempty(hay_onda)
    hay_onda = 0; % If maxima too small or too separated, there is no P wave
end

end

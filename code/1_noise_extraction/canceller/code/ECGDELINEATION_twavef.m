function position = ECGDELINEATION_twavef(samp, time, position, w, intervalo, fs)
% T wave delineation. This function also identifies T wave morphology
%
%Input Parameters:
%   samp: samples included in the current excerpt (borders excluded)
%   time:  QRS times in inedexes refering the interval included in the current excerpt (borders excluded)
%   position: struct vector with the detected points
%   w: matrix with WT scales 1 to 5
%   intervalo: numeration of the beats processed in this segment
%
% Outputs:
%   - position: updated position struct with T wave delineation marks

%% Import constants
C = ECGDELINEATION_constants(fs);

KTon = C.KTon;
KToff = C.KToff;
umbraldetT = C.umbraldetT;
umbralsig = C.umbralsig;
rrant_mintol = C.rrant_mintol;
rrant_maxtol = C.rrant_maxtol;
rrant_average = C.rrant_average;
inivent_tol = C.inivent_tol;
inivent_tol_S = C.inivent_tol_S;
finvent_tol = C.finvent_tol;
finvent_max = C.finvent_max;
scale = C.scale;
scale2 = C.scale2;
scalezerocros = C.scalezerocros;
scalezerocros2 = C.scalezerocros2;
min_vent = C.min_vent;
Tmax_Tmin_time_min = C.Tmax_Tmin_time_min;
Tmax_Tmin_bifasic = C.Tmax_Tmin_bifasic;
T_bound_tol = C.T_bound_tol;


%% Initialization of auxiliary variables
if length(time) > 1
    rrant = time(2) - time(1);
else
    aux = find(position.qrs ~= 0);
    if length(aux) > 1
        rrant = diff(position.qrs(aux(end-1):aux(end)));
    else
        rrant = fs;
    end
end

% for the case in which the first RR is very wrong 
if rrant < rrant_mintol*fs || rrant > rrant_maxtol*fs
    rrant = rrant_mintol * fs;
end

windows = NaN*ones(length(time), 3);
endwinT = NaN*ones(length(time), 1);

for i = 1 : length(time)   % For each beat
    
    T = []; 
    Tprima = []; 
    Ton = []; 
    Toff = []; 
    tipoT = [];
    
    %% Compute mean RR interval
    if i > 1
        if (rrant_maxtol*rrant > (time(i) - time(i-1))) && (time(i) - time(i-1) > rrant_mintol*rrant)
            rrmed = rrant_average(1)*rrant + rrant_average(2)*(time(i) - time(i-1)); % Exponentially averaged RR new value
        else
            rrmed = rrant;  % Exponentially averaged RR old value
        end
    else                  % Only for the first in each segment of the ECG
        rrmed = rrant;
    end
    
    rrant = rrmed;        % For next segment
    
    %% Define T window
    % Window onset
    inivent = round(inivent_tol*fs);   % Begining of window
    
    % If there is S mark, set indow onset after it
    if ~isempty(position.S(i + intervalo(1) - 1))
        inivent = max(inivent, position.S(i + intervalo(1) - 1) - samp(1) + 1 - time(i) + round(inivent_tol_S*fs));
    end
    
    % Window offset
    if (rrmed <= fs) && (i ~= length(time)) && (rrant_maxtol*rrant > (time(i+1) - time(i))) && (time(i+1) - time(i) > rrant_mintol*rrant)
        finvent = round(finvent_max*fs);
    else
        finvent = round(rrmed*finvent_max);
    end
    
    % Protection for window end
    if i ~= length(time)  % For last beat in the segment
        finvent = min(finvent, time(i+1) - time(i) - min(round((time(i+1) - time(i))*0.4), round(finvent_tol*fs)));
    elseif i ~= 1
        finvent = min(finvent, time(i) - time(i-1) - round(finvent_tol*fs));
    elseif length(aux) > 1
        finvent = min(finvent, diff(position.qrs(aux(end - 1) : aux(end))) - round(finvent_tol*fs));
    end
    
    % Protection for window onset
    if isempty(position.QRSoff(i + intervalo(1) - 1))
        begwin = min(inivent + time(i), length(w));
    else
        % If QRSoff is bad anoated it can miss T wave
        begwin = min(max(inivent + time(i), position.QRSoff(i + intervalo(1) - 1) - samp(1) + 1 + 1), length(w));
    end
    
    endwin = max(1, min(finvent + time(i), length(w))); 
    windows(i, :) = [i begwin endwin];
    endwinT(i) = endwin;
    
    %% Determine positive maxima and negative minima in the window
    maxpos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : endwin, scale), 2, 0, +1);
    minpos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : endwin, scale), 2, 0, -1);
    [maxim, ind] = max(w(maxpos, scale));   % The biggest of the positive
    maxpos = maxpos(ind);
    [minim, ind] = min(w(minpos, scale));   % The biggest of the negative
    minpos = minpos(ind);
    
    % If no local positive maximum
    if isempty(maxpos)              
        % The maximum will be the first or the last sample
        if (w(begwin, scale) >= w(endwin, scale)) && (w(begwin, scale) > 0)
            maxpos = begwin; 
            maxim = w(maxpos, scale);
        elseif (w(endwin, scale) >= w(begwin, scale)) && (w(endwin, scale) > 0)
            maxpos = endwin; maxim = w(maxpos,scale);
        end
    end
    
    % If no local negative minimum
    if isempty(minpos)               
        % The minimum will be the first or the last sample
        if (w(begwin, scale) <= w(endwin, scale)) && (w(begwin, scale) < 0)
            minpos = begwin; 
            minim = w(minpos, scale);
        elseif (w(endwin,scale) <= w(begwin, scale)) && (w(endwin, scale) < 0)
            minpos = endwin; 
            minim = w(minpos, scale);
        end
    end
    
    absmax = abs(maxim);
    absmin = abs(minim);
    
    %% Determine if there is T wave
    if i < length(time)
        vrms = sqrt(mean(w(time(i) : time(i+1), scale).^2));
    else % If last beat of the segment
        vrms = sqrt(mean(w(time(i) : end, scale).^2));
    end
    
    hay_onda = ((absmax > umbraldetT*vrms) | (absmin > umbraldetT*vrms));
    
    % If Vrms is lower than threshold, there is no T wave
    if isempty(hay_onda)
        hay_onda = 0;
    end
    
    % If window length is shorter than threshold, there is no T wave
    if ((endwin - begwin) < min_vent*fs) || isnan(hay_onda)
        hay_onda = 0;
    end
    
    %% If there is T wave
    if hay_onda 
        
        [Ton, Toff, T, Tprima, tipoT] = delineateT(w, begwin, endwin, maxpos, minpos, scale, scalezerocros, scale, umbralsig, absmax, absmin, Tmax_Tmin_time_min, Tmax_Tmin_bifasic, T_bound_tol, KTon, KToff, fs, 0);
    
    else % Try with scale 5   
              
        %% Determine positive maxima and negative minima in the window
        maxpos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : endwin, scale2), 2, 0, +1);
        minpos = begwin + ECGDELINEATION_modmax(w(begwin + 1 : endwin, scale2), 2, 0, -1);        
        [maxim, ind] = max(w(maxpos,scale2));   % The biggest of the positive
        maxpos = maxpos(ind);
        [minim, ind] = min(w(minpos,scale2));   % The biggest of the negative
        minpos = minpos(ind);
        
        % If no local positive maximum
        if isempty(maxpos)               % If no local positive maximum
            % The maximum will be the first or the last sample
            if (w(begwin, scale2) >= w(endwin, scale2)) && (w(begwin, scale2) > 0)
                maxpos = begwin; maxim = w(maxpos,scale2);
            elseif (w(endwin, scale2) >= w(begwin, scale2)) && (w(endwin, scale2) > 0)
                maxpos = endwin; 
                maxim = w(maxpos, scale2);
            end
        end
        
        % If no local negative minimum
        if isempty(minpos)
            % The minimum will be the first or the last sample
            if (w(begwin, scale2) <= w(endwin, scale2)) && (w(begwin, scale2) < 0)
                minpos = begwin; 
                minim = w(minpos, scale2);
            elseif (w(endwin, scale2) <= w(begwin, scale2)) && (w(endwin, scale2) < 0)
                minpos = endwin; 
                minim = w(minpos, scale2);
            end
        end
        
        absmax = abs(maxim);
        absmin = abs(minim);
        
        %% Determine if there is T wave
        if i < length(time)
            vrms = sqrt(mean(w(time(i) : time(i+1), scale2).^2));
        else % If last beat of the segment
            vrms = sqrt(mean(w(time(i) : end, scale2).^2));
        end
        
        hay_ondascale2 = ((absmax > umbraldetT*vrms) | (absmin > umbraldetT*vrms));
        
        % If Vrms is lower than threshold, there is no T wave
        if isempty(hay_ondascale2)
            hay_ondascale2 = 0;
        end

        % If window length is shorter than threshold, there is no T wave
        if (endwin - begwin) < (min_vent*fs)
            hay_ondascale2 = 0;
        end
        
        if hay_ondascale2
            
            [Ton, Toff, T, Tprima, tipoT] = delineateT(w, begwin, endwin, maxpos, minpos, scale2, scalezerocros, scalezerocros2, umbralsig, absmax, absmin, Tmax_Tmin_time_min, Tmax_Tmin_bifasic, T_bound_tol, KTon, KToff, fs, 1);
            
        end
    end
    
    % Filling the structure with nans in case marks were not detected
    if isempty(Ton)
        Ton = NaN; 
    end
    
    if isempty(Toff)
        Toff = NaN;  
    end
    
    if isempty(T)
        T = NaN; 
    end
    
    if isempty(Tprima)
        Tprima = NaN;
    end
    
    if isempty(tipoT)
        tipoT = NaN;
    end
    
    pos.Tscale(i) = scale;
    pos.Ton(i) = Ton;
    pos.Toff(i) = Toff;
    pos.T(i) = T;
    pos.Tprima(i) = Tprima;
    pos.Ttipo(i) = tipoT;
 

end

%% Return
position.Tscale(intervalo(1) : intervalo(2)) = pos.Tscale;
position.Ton(intervalo(1) : intervalo(2)) = pos.Ton + samp(1) - 1;
position.Toff(intervalo(1) : intervalo(2))= pos.Toff + samp(1) - 1;
position.T(intervalo(1) : intervalo(2)) = pos.T + samp(1) - 1;
position.Tprima(intervalo(1) : intervalo(2)) = pos.Tprima + samp(1) - 1;
position.Ttipo(intervalo(1) : intervalo(2)) = pos.Ttipo;

end

function [Ton, Toff, T, Tprima, tipoT] = delineateT(w, begwin, endwin, maxpos, minpos, scale, scalezerocros, scalezerocros2, umbralsig, absmax, absmin, Tmax_Tmin_time_min, Tmax_Tmin_bifasic, T_bound_tol, KTon, KToff, fs, checkScale2)

T = []; 
Tprima = []; 
Ton = []; 
Toff = []; 
tipoT = [];
picon = [];
picoff = [];

if absmax >= absmin   % If the greatest modulus maximum is the maximum
            
    % Search for two minima nearest to maxpos, one before and one after
    % Position of the negative minimum before the maximum
    minapos = max(ECGDELINEATION_modmax(w(begwin + 1 : maxpos - 1, scale), 2, 0, -1));
    minapos = begwin + minapos; 

    % If no local minimum before the maximum, take the first sample
    if isempty(minapos) && (maxpos ~= begwin) && (w(begwin, scale) < 0)
        minapos = begwin;
    end

    % Position of the positive maximum after the minimum
    minppos = min(ECGDELINEATION_modmax(w(maxpos + 1 : endwin, scale), 2, 0, -1));
    minppos = maxpos + minppos; 

    if isempty(minppos) && (maxpos ~= endwin) && (w(endwin, scale) < 0)
        minppos = endwin;        % If no local minimum after the maximum, take the last sample
    end

    mina = abs(w(minapos, scale));     % Amplitude of minimum before maximum
    minp = abs(w(minppos, scale));     % Amplitude of minimum after maximum

    % If mina is not high enough or is too far away from maxpos, ignore it
    if ~isempty(mina)
        if (mina < umbralsig*absmax) || ((maxpos - minapos) > Tmax_Tmin_time_min*fs)
            mina = [];
        end
    end
    
    % If minp is not high enough or is too far away from maxpos, ignore it
    if ~isempty(minp)
        if (minp < umbralsig*absmax) || ((minppos - maxpos) > Tmax_Tmin_time_min*fs) 
            minp = [];
        end
    end

    % Additional mina and minp verifications
    if ~isempty(mina) && ~isempty(minp)
        if ~isnan(mina) && ~isnan(minp) 
            if (mina >= minp) && (minp < umbralsig*absmax*Tmax_Tmin_bifasic)
                minp = [];
            elseif (minp > mina) && (mina < umbralsig*absmax*Tmax_Tmin_bifasic)
                mina = [];
            end
        end
    end

    % Test which modulus maxima are significative and find zero crossings
    if isempty(mina)

        if isempty(minp)

            tipoT = 2; % Only upwards T wave

            if (maxpos - minapos) > 2

                ind = ECGDELINEATION_zerocross(flipud(w(minapos : maxpos, scalezerocros))); 
                
                if checkScale2
                    if isempty(ind)
                        ind = ECGDELINEATION_zerocross(flipud(w(minapos : maxpos, scale)));
                    end
                end
                
                T = maxpos - ind + 1;   % Zero crossing = T wave position
                picoff = maxpos;        % Wavelet peak to detect offset

            elseif isempty(minapos)  % If there is no minimum, there is no zero crossing
                T = ECGDELINEATION_picant(w(begwin : maxpos, scale), maxpos);  % Take the minimum at scale scale

                if ~isempty(T) 
                    picoff = maxpos;
                else
                    picoff = []; % If there is no peak in scale scale, there is no T
                end

            end
            
        else  % If minp exists (is significative) but mina does not

            tipoT = 0; % Normal T wave

            if (minppos - maxpos) > 2

                ind = ECGDELINEATION_zerocross(w(maxpos : minppos, scalezerocros));  

                if isempty(ind)
                    ind = ECGDELINEATION_zerocross(w(maxpos : minppos, scalezerocros2));
                end 

                T = maxpos + ind -1;
                picon = maxpos;		% For determining onset and offset
                picoff = minppos;

            end
        end
        
    else
        
        if isempty(minp)  % If mina exists (is significative) but minp does not

            tipoT = 1;  % Inverted T wave

            if (maxpos - minapos) >2 

                ind = ECGDELINEATION_zerocross(w(minapos : maxpos, scalezerocros));  % Wavelet zero crossing is T wave peak 

                if isempty(ind)
                    ind = ECGDELINEATION_zerocross(w(minapos : maxpos, scalezerocros2));  % Wavelet zero crossing is T wave peak
                end 

                T = minapos + ind -1;
                picon = minapos;
                picoff = maxpos;

            end
            
        else  % If both mina and minp are significative (biphasic wave).

            tipoT = 5;	% Biphasic -+ T wave

            if (maxpos - minapos) > 2  

                ind = ECGDELINEATION_zerocross(flipud(w(minapos : maxpos, scalezerocros))); % Scale scalezroscros

                if isempty(ind)
                    ind = ECGDELINEATION_zerocross(flipud(w(minapos : maxpos, scalezerocros2))); % Scale scale     
                end

                T = maxpos - ind + 1;
                picon = minapos;

            end

            if (minppos - maxpos) > 2

                ind = ECGDELINEATION_zerocross(flipud(w(maxpos : minppos, scalezerocros))); 

                if isempty(ind)
                    ind = ECGDELINEATION_zerocross(flipud(w(maxpos : minppos, scalezerocros2))); 
                end

                Tprima = minppos - ind +1;
                picoff = minppos;

            end
        end
    end
    
else  % If the greatest modulus maximum is the minimum
    
    % Search two maxima, one before and one after the minimum
    maxapos = max(ECGDELINEATION_modmax(w(begwin + 1 : minpos - 1, scale), 2, 0, 1));
    maxapos = begwin + maxapos;
    
    if isempty(maxapos) && (minpos ~= begwin) && (w(begwin, scale) > 0)
        maxapos = begwin;
    end
    
    maxppos = min(ECGDELINEATION_modmax(w(minpos + 1 : endwin, scale), 2, 0, 1));
    maxppos = minpos + maxppos;
    
    if isempty(maxppos) && (minpos ~= endwin) && (w(endwin, scale) > 0)
        maxppos = endwin;
    end
    
    maxa = abs(w(maxapos, scale));
    maxp = abs(w(maxppos, scale));
    
    % If maxa is not high enough or is too far away from minpos, ignore it
    if ~isempty(maxa)
        if (maxa < umbralsig*absmin) || ((minpos - maxapos) > Tmax_Tmin_time_min*fs)
            maxa = [];
        end
    end
    
    % If maxp is not high enough or is too far away from minpos, ignore it
    if ~isempty(maxp)
        if (maxp < umbralsig*absmin) || ((maxppos - minpos) > Tmax_Tmin_time_min*fs)
            maxp = [];
        end
    end
    
    % Additional maxa and maxp verifications
    if ~isempty(maxa) && ~isempty(maxp)
        if ~isnan(maxa) && ~isnan(maxp)
            if (maxa >= maxp) && (maxp < umbralsig*absmin*Tmax_Tmin_bifasic)
                maxp = [];
            elseif (maxp > maxa) && (maxa < umbralsig*absmin*Tmax_Tmin_bifasic)
                maxa = [];
            end
        end
    end
    
    % Test which modulus maxima are significative and find zero crossings
    if isempty(maxa)
        
        if isempty(maxp)
            
            tipoT = 3; % only downwards T wave
            
            if (minpos - maxapos) > 2 
                
                ind = ECGDELINEATION_zerocross(flipud(w(maxapos : minpos, scalezerocros))); % Scale scalezroscros
                
                if isempty(ind) 
                    ind = ECGDELINEATION_zerocross(flipud(w(maxapos : minpos, scalezerocros2))); % Scale scale
                end
                
                T = minpos - ind +1;
                picoff = minpos;
                
            elseif isempty(maxapos)  % If there were no maximum, there is no zero crossing.
                
                T = ECGDELINEATION_picant(w(begwin : minpos, scale), minpos);
                
                if ~isempty(T) 
                    picoff = minpos;
                else
                    picoff = []; % If there is no peak in scale scale, there is no T
                end
                
            end
            
        else  % If maxp is signficative, but there is not maxa
            
            tipoT = 1;  % Inverted T wave
            
            if (maxppos - minpos) > 2
                
                ind = ECGDELINEATION_zerocross(w(minpos : maxppos, scalezerocros));  
                
                if isempty(ind) 
                    ind = ECGDELINEATION_zerocross(w(minpos : maxppos, scalezerocros2));  
                end
                
                T = minpos + ind -1;
                picon = minpos;	% For calculating onset and offset
                picoff = maxppos;
                
            end
        end
        
    else
        
        if isempty(maxp) % If maxa is significative, but ther is not maxp
            
            tipoT = 0; % Normal T wave
            
            if (minpos - maxapos) > 2
                
                ind = ECGDELINEATION_zerocross(w(maxapos : minpos, scalezerocros));
                
                if isempty(ind)
                    ind = ECGDELINEATION_zerocross(w(maxapos : minpos, scalezerocros2));
                end
                
                T = maxapos + ind -1;
                picon = maxapos;
                picoff = minpos;
                
            end
            
        else % If both maxa and maxp are significative (biphasic wave).
            
            tipoT = 4;	% Biphasic +- T wave
            
            if (minpos - maxapos) > 2
                
                ind = ECGDELINEATION_zerocross(flipud(w(maxapos : minpos, scalezerocros)));
                
                if isempty(ind)
                    ind = ECGDELINEATION_zerocross(flipud(w(maxapos : minpos, scalezerocros2)));
                end 
                
                T = minpos - ind + 1;
                picon = maxapos;
                
            end

            if (maxppos - minpos) > 2
                
                ind = ECGDELINEATION_zerocross(flipud(w(minpos : maxppos, scalezerocros))); 
                
                if isempty(ind)
                    ind = ECGDELINEATION_zerocross(flipud(w(minpos : maxppos, scalezerocros2))); 
                end  

                Tprima = maxppos - ind + 1;
                picoff = maxppos;
                
            end
        end
    end
end

% T wave onset and offset detection           
if ~isempty(picon)
    Ton = ECGDELINEATION_searchon(picon, w(max(begwin, picon - round(T_bound_tol*fs)) : picon, scale), KTon);
end

if ~isempty(picoff)
    Toff = ECGDELINEATION_searchoff(picoff, w(picoff : min([size(w, 1) picoff + round(T_bound_tol*fs)]), scale), KToff);
    if Toff > endwin
        Toff = endwin;
    end
end

end

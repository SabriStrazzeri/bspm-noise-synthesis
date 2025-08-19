function spikes = ECGPREPROCESSING_detectPacingSpikes_v1_2(ECG, fs, leadStatus, fpa, medfilt_N, G, wsize)
%ECGPREPROCESSING_detectPacingSpikes_v1_2: detect pacemaker pulses using
%Herleikson's algorithm
%
%Inputs:
%  - ECG: ECG signals [nL x nS], where nL: number of leads; nS: number of 
%       samples. ECG with powerline interference removed. 
%  - fs: sampling frequency in Hz.
%  - leadStatus: nL length array indicating lead status (1: good signal 
%             quality, 0: bad signal quality, -1: disconnected).
%  - torso: struct containing .vertices and .faces (not needed in this 
%             method, can be [])
%  - fpa: high-pass filter cut-off frequency to filter the QRS complexes.
%             Recommended to be at least 70 Hz.
%  - medfilt_N: median filter order.
%  - G: adaptative threshold gain (mean + G*std)
%  - wsize: adaptative threshold window size
%
%Outputs:
%  - spikes: position of the spikes to remove. 
%
% This method filters the QRS complexes and resume signal with PCA
% components 1 and 2. The result of applying a median filter is subtracted
% from the components 1 and 2, and the absolute of the signal is calculated. 
% The mean + G*std of a sliding window with 50% overlap is used to detect
% the spikes. Detections in components 1 and 2 are considered spikes. 
%
%Last edited: 28/10/2024, Marta Martínez (marta.martinez@corify.es) 
%-------------------------------------------------------------------------

if nargin < 3 && isempty(fs)
    fs = 1000; 
end 

% High-pass filter
[B,A] = butter(10,fpa/(fs/2),'high'); 
F = filtfilt(B,A,ECG')';                % eliminates the signal corresponding to the QRST complexes

F_ok = F(leadStatus == 1,:);

% Apply PCA to the leads with good signal quality
[coeff, score, ~] = pca(F_ok');  % PCA expects rows as observations, so we transpose

%% Spikes for PCA 1
% Use the first principal component as the reference signal
pca_signal = score(:,1)';  % Transpose to match the original signal shape 

Fmedfilt = medfilt1(pca_signal, medfilt_N);
Fspikes = pca_signal - Fmedfilt; 
Fspikes = abs(Fspikes); 

% Sliding window approach with 50% overlap
step_size = floor(wsize / 2);  % 50% overlap
num_windows = floor((length(Fspikes) - wsize) / step_size);

% Initialize empty arrays for threshold and spikes
all_spikes = [];
Thr = zeros(1, length(Fspikes));

% Loop through each sliding window
for win_idx = 1:num_windows
    % Define window range
    win_start = (win_idx - 1) * step_size + 1;
    win_end = win_start + wsize - 1;
    
    % Extract the segment within the current window
    window_segment = Fspikes(win_start:win_end);
    
    % Calculate mean and standard deviation within the window
    win_mean = mean(window_segment);
    win_std = std(window_segment);
    
    % Define the threshold as mean + k * std (with k = G)
    threshold = win_mean + G * win_std;
    
    % Store the threshold across this window
    Thr(win_start:win_end) = threshold;
    
    % Find candidates where Fspikes exceeds the threshold
    window_candidates = find(Fspikes(win_start:win_end) > threshold) + win_start - 1;
    
    % Append to the spikes list
    all_spikes = [all_spikes, window_candidates];
end

% Remove duplicate spikes (if any)
all_spikes = unique(sort(all_spikes));

% Tolerancia en muestras (20 ms en tiempo, convertir a muestras)
tolerance = 20;  % Asumimos que fs es la frecuencia de muestreo en Hz
final_spikes = [];

% Filtrar espigas duplicadas o cercanas
i = 1;
while i <= length(all_spikes)
    % Comparamos la espiga actual con las siguientes dentro del rango de tolerancia
    close_spikes = all_spikes(abs(all_spikes - all_spikes(i)) <= tolerance);
    
    % Si hay espigas cercanas, seleccionamos el promedio
    if length(close_spikes) > 1
        final_spike = round(mean(close_spikes));
        i = i + length(close_spikes);  % Saltar las espigas cercanas
    else
        final_spike = all_spikes(i);
        i = i + 1;
    end
    
    % Añadir la espiga seleccionada al array final
    final_spikes = [final_spikes, final_spike];
end

% Resultado final con las espigas filtradas
spikes1 = final_spikes;

%% Spikes for PCA 2
% Use the first principal component as the reference signal
pca_signal = score(:,2)';  % Transpose to match the original signal shape 

Fmedfilt = medfilt1(pca_signal, 20);
Fspikes = pca_signal - Fmedfilt; 
Fspikes = abs(Fspikes); 

% Sliding window approach with 50% overlap
step_size = floor(wsize / 2);  % 50% overlap
num_windows = floor((length(Fspikes) - wsize) / step_size);

% Initialize empty arrays for threshold and spikes
all_spikes = [];
Thr = zeros(1, length(Fspikes));

% Loop through each sliding window
for win_idx = 1:num_windows
    % Define window range
    win_start = (win_idx - 1) * step_size + 1;
    win_end = win_start + wsize - 1;
    
    % Extract the segment within the current window
    window_segment = Fspikes(win_start:win_end);
    
    % Calculate mean and standard deviation within the window
    win_mean = mean(window_segment);
    win_std = std(window_segment);
    
    % Define the threshold as mean + k * std (with k = G)
    threshold = win_mean + G * win_std;
    
    % Store the threshold across this window
    Thr(win_start:win_end) = threshold;
    
    % Find candidates where Fspikes exceeds the threshold
    window_candidates = find(Fspikes(win_start:win_end) > threshold) + win_start - 1;
    
    % Append to the spikes list
    all_spikes = [all_spikes, window_candidates];
end

% Remove duplicate spikes (if any)
all_spikes = unique(sort(all_spikes));

% Tolerancia en muestras (20 ms en tiempo, convertir a muestras)
tolerance = 20;  % Asumimos que fs es la frecuencia de muestreo en Hz
final_spikes = [];

% Filtrar espigas duplicadas o cercanas
i = 1;
while i <= length(all_spikes)
    % Comparamos la espiga actual con las siguientes dentro del rango de tolerancia
    close_spikes = all_spikes(abs(all_spikes - all_spikes(i)) <= tolerance);
    
    % Si hay espigas cercanas, seleccionamos el promedio
    if length(close_spikes) > 1
        final_spike = round(mean(close_spikes));
        i = i + length(close_spikes);  % Saltar las espigas cercanas
    else
        final_spike = all_spikes(i);
        i = i + 1;
    end
    
    % Añadir la espiga seleccionada al array final
    final_spikes = [final_spikes, final_spike];
end

% Resultado final con las espigas filtradas
spikes2 = final_spikes;

%% Unir los dos conjuntos de spikes (spikes1 y spikes2)
all_spikes = [spikes1, spikes2];

% Ordenar las espigas por posición
all_spikes = sort(all_spikes);

% Inicializar array para las espigas finales
final_spikes = [];

% Tolerancia en muestras (20 ms en tiempo, convertir a muestras)
tolerance = 20;  % Asumimos que fs es la frecuencia de muestreo en Hz

% Filtrar espigas duplicadas o cercanas
i = 1;
while i <= length(all_spikes)
    % Comparamos la espiga actual con las siguientes dentro del rango de tolerancia
    close_spikes = all_spikes(abs(all_spikes - all_spikes(i)) <= tolerance);
    
    % Si hay espigas cercanas, seleccionamos el promedio
    if length(close_spikes) > 1
        final_spike = round(mean(close_spikes));
        i = i + length(close_spikes);  % Saltar las espigas cercanas
    else
        final_spike = all_spikes(i);
        i = i + 1;
    end
    
    % Añadir la espiga seleccionada al array final
    final_spikes = [final_spikes, final_spike];
end

% Resultado final con las espigas filtradas
spikes = final_spikes;

end
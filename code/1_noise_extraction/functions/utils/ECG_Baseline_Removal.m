function [corrected_signal, estimated_baseline] = ECG_Baseline_Removal(input_signal, sample_rate, window_size_sec, overlap_fraction)
%ECG_BASELINE_REMOVAL Elimina la línea base de señales ECG mediante filtrado adaptativo
%
% Esta función implementa un método de eliminación de línea base para señales de ECG
% basado en la estimación de la línea base mediante ventanas de mediana deslizantes
% con interpolación entre los puntos calculados.
%
% Entradas:
%   input_signal     - Matriz de señales de entrada [muestras x canales]
%   sample_rate      - Frecuencia de muestreo en Hz
%   window_size_sec  - Tamaño de la ventana en segundos
%   overlap_fraction - Fracción de solapamiento entre ventanas consecutivas (0-1)
%                      0 = sin solapamiento, 1 = máximo solapamiento (muestra a muestra)
%
% Salidas:
%   corrected_signal   - Señal con la línea base eliminada
%   estimated_baseline - Estimación de la línea base extraída
    
    % Obtener propiedades de la señal
    [num_samples, num_channels] = size(input_signal);
    
    % Preasignar matrices para resultados
    estimated_baseline = zeros(size(input_signal));
    corrected_signal = zeros(size(input_signal));
    
    % Convertir el tamaño de ventana de segundos a muestras
    window_size_samples = round(window_size_sec * sample_rate);
    
    % Asegurar que el tamaño de ventana sea un número impar (necesario para cálculos de mediana centrados)
    window_size_samples = window_size_samples + 1 - mod(window_size_samples, 2);
    window_half_size = (window_size_samples - 1) / 2;
    
    % Determinar los centros de las ventanas según el solapamiento
    if overlap_fraction >= 0 && overlap_fraction < 1
        % Calcular el número de ventanas necesarias para cubrir toda la señal
        num_windows = floor((num_samples - window_size_samples * overlap_fraction) / ...
                            (window_size_samples * (1 - overlap_fraction)));
        
        % Calcular los centros de cada ventana
        window_centers = round(window_size_samples * (1 - overlap_fraction) * (0:1:num_windows-1))' + ...
                         window_half_size + 1;
    elseif overlap_fraction == 1
        % Caso especial: solapamiento total (análisis muestra a muestra)
        window_centers = (1:num_samples)';
        num_windows = length(window_centers);
    else
        error('El solapamiento debe ser un número entre 0 y 1');
    end
    
    % Procesar cada canal individualmente
    for channel = 1:num_channels
        % Preasignar vector para los puntos de línea base
        baseline_points = zeros(size(window_centers));
        
        % Calcular la mediana para cada ventana
        for i = 1:num_windows
            % Determinar los límites de la ventana actual (con protección de bordes)
            left_boundary = max(window_centers(i) - window_half_size, 1);
            right_boundary = min(window_centers(i) + window_half_size, num_samples);
            
            % Calcular la mediana local (representa el nivel de línea base en este punto)
            baseline_points(i) = median(input_signal(left_boundary:right_boundary, channel));
        end
    
        % Interpolar para obtener una estimación suave de la línea base para todas las muestras
        estimated_baseline(:, channel) = pchip(window_centers, baseline_points, 1:1:num_samples)';
        
        % Obtener la señal corregida restando la línea base estimada
        corrected_signal(:, channel) = input_signal(:, channel) - estimated_baseline(:, channel);
        
        % Corrección adicional para eliminar cualquier offset constante residual
        [corrected_signal(:, channel), dc_offset] = Isoline_Correction(corrected_signal(:, channel));
        
        % Actualizar la línea base estimada para incluir el offset DC
        estimated_baseline(:, channel) = estimated_baseline(:, channel) + dc_offset;
    end

end